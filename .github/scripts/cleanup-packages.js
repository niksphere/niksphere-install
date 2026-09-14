const REGISTRY = 'ghcr.io';

async function getRegistryToken(owner, packageName, actor, token) {
  const auth = Buffer.from(`${actor}:${token}`).toString('base64');
  const response = await fetch(
    `https://${REGISTRY}/token?service=${REGISTRY}&scope=repository:${owner}/${packageName}:pull`,
    { headers: { Authorization: `Basic ${auth}` } }
  );

  if (!response.ok) {
    throw new Error(`Failed to obtain registry token for ${packageName}: HTTP ${response.status}`);
  }

  const data = await response.json();
  return data.token;
}

// Multi-arch images are published as a manifest list/OCI index that references
// per-platform manifests and buildx attestations. Those referenced manifests are
// stored as separate, untagged package versions and are not deleted automatically
// when the tagged parent version is removed, so they must be resolved and cleaned
// up explicitly to avoid leaving orphaned data behind.
async function getManifestChildDigests(owner, packageName, digest, registryToken, core) {
  const response = await fetch(`https://${REGISTRY}/v2/${owner}/${packageName}/manifests/${digest}`, {
    headers: {
      Authorization: `Bearer ${registryToken}`,
      Accept: [
        'application/vnd.oci.image.index.v1+json',
        'application/vnd.docker.distribution.manifest.list.v2+json',
        'application/vnd.oci.image.manifest.v1+json',
        'application/vnd.docker.distribution.manifest.v2+json'
      ].join(', ')
    }
  });

  if (!response.ok) {
    core.warning(`Could not fetch manifest ${digest} for ${packageName}: HTTP ${response.status}`);
    return [];
  }

  const manifest = await response.json();
  return (manifest.manifests || []).map((m) => m.digest);
}

module.exports = async ({ github, context, core }, dryRunInput) => {
  const org = context.repo.owner;
  const actor = context.actor;
  const token = process.env.GITHUB_TOKEN;
  const dryRun = dryRunInput === true || dryRunInput === 'true';
  const packageType = 'container';

  core.info(`Starting cleanup of old Insider package versions. Dry Run: ${dryRun}`);

  core.info('Fetching container packages...');
  const packages = await github.paginate(github.rest.packages.listPackagesForOrganization, {
    org,
    package_type: packageType,
    per_page: 100
  });

  core.info(`Fetched ${packages.length} container packages.`);

  const now = new Date();
  const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000;
  const getInsiderTag = (version) =>
    (version.metadata?.container?.tags || []).find((tag) => tag.endsWith('-channel.insider'));
  const getVersionDate = (v) => new Date(v.created_at);

  for (const pkg of packages) {
    const packageName = pkg.name;

    const versions = await github.paginate(github.rest.packages.getAllPackageVersionsForPackageOwnedByOrg, {
      org,
      package_type: packageType,
      package_name: packageName,
      per_page: 100
    });

    const insiderVersions = versions.filter((v) => getInsiderTag(v));
    if (insiderVersions.length === 0) {
      continue;
    }

    core.info(`\n--- Package: ${packageName} (${insiderVersions.length} Insider versions found) ---`);
    insiderVersions.sort((a, b) => getVersionDate(b) - getVersionDate(a));

    const latestVersion = insiderVersions[0];
    core.info(`Latest Insider Version (always kept): ${getInsiderTag(latestVersion)} (Published: ${getVersionDate(latestVersion).toISOString()})`);

    const candidates = insiderVersions.slice(1);
    for (const version of candidates) {
      const versionTag = getInsiderTag(version);
      const versionDate = getVersionDate(version);
      const ageMs = now - versionDate;
      const ageDays = (ageMs / (24 * 60 * 60 * 1000)).toFixed(1);
      const isOlderThan7Days = ageMs > SEVEN_DAYS_MS;

      if (!isOlderThan7Days) {
        core.info(`[KEEP] ${versionTag} - Age: ${ageDays} days (Published: ${versionDate.toISOString()}) - Under 7 days old`);
        continue;
      }

      core.info(`[DELETE CANDIDATE] ${versionTag} - Age: ${ageDays} days (Published: ${versionDate.toISOString()})`);

      let childVersions = [];
      try {
        const registryToken = await getRegistryToken(org, packageName, actor, token);
        const childDigests = await getManifestChildDigests(org, packageName, version.name, registryToken, core);
        childVersions = versions.filter(
          (v) => childDigests.includes(v.name) && (v.metadata?.container?.tags || []).length === 0
        );
      } catch (err) {
        core.warning(`Could not resolve referenced manifests for ${versionTag}: ${err.message}`);
      }

      if (dryRun) {
        core.info(`[DRY RUN] Would delete package version ${versionTag} and ${childVersions.length} referenced manifest(s).`);
        continue;
      }

      try {
        core.info(`Deleting package version ${versionTag} (ID: ${version.id})...`);
        await github.rest.packages.deletePackageVersionForOrg({
          org,
          package_type: packageType,
          package_name: packageName,
          package_version_id: version.id
        });
        core.info(`Deleted package version ${versionTag}.`);
      } catch (err) {
        core.error(`Failed to delete package version ${versionTag}: ${err.message}`);
        continue;
      }

      for (const childVersion of childVersions) {
        try {
          core.info(`Deleting referenced manifest ${childVersion.name} (ID: ${childVersion.id})...`);
          await github.rest.packages.deletePackageVersionForOrg({
            org,
            package_type: packageType,
            package_name: packageName,
            package_version_id: childVersion.id
          });
        } catch (err) {
          core.warning(`Could not delete referenced manifest ${childVersion.name}: ${err.message}`);
        }
      }
    }
  }
};
