module.exports = async ({ github, context, core }, dryRunInput) => {
  const owner = context.repo.owner;
  const repo = context.repo.repo;
  const dryRun = dryRunInput === true || dryRunInput === 'true';

  core.info(`Starting cleanup of old Insider releases. Dry Run: ${dryRun}`);

  // Fetch all releases from the repository
  core.info("Fetching releases...");
  const releases = await github.paginate(github.rest.repos.listReleases, {
    owner,
    repo,
    per_page: 100
  });

  core.info(`Fetched ${releases.length} releases.`);

  // Group releases by component
  const components = ['cli', 'engine', 'ide-vscode'];
  const groups = {
    cli: [],
    engine: [],
    'ide-vscode': []
  };

  for (const release of releases) {
    if (release.draft) {
      continue;
    }
    if (!release.prerelease) {
      continue;
    }

    const tag = release.tag_name || '';
    const parts = tag.split('/');
    if (parts.length >= 2) {
      const comp = parts[0];
      if (components.includes(comp)) {
        groups[comp].push(release);
      }
    }
  }

  const now = new Date();
  const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000;

  for (const comp of components) {
    const compReleases = groups[comp];
    core.info(`\n--- Component: ${comp} (${compReleases.length} Insider releases found) ---`);

    if (compReleases.length === 0) {
      continue;
    }

    // Sort releases by date descending (newest first)
    const getReleaseDate = (r) => new Date(r.published_at || r.created_at);
    compReleases.sort((a, b) => getReleaseDate(b) - getReleaseDate(a));

    const latestRelease = compReleases[0];
    core.info(`Latest Insider Release (always kept): ${latestRelease.tag_name} (Published: ${getReleaseDate(latestRelease).toISOString()})`);

    // The rest of the releases are candidates for deletion
    const candidates = compReleases.slice(1);
    for (const release of candidates) {
      const releaseDate = getReleaseDate(release);
      const ageMs = now - releaseDate;
      const ageDays = (ageMs / (24 * 60 * 60 * 1000)).toFixed(1);
      const isOlderThan7Days = ageMs > SEVEN_DAYS_MS;

      if (isOlderThan7Days) {
        core.info(`[DELETE CANDIDATE] ${release.tag_name} - Age: ${ageDays} days (Published: ${releaseDate.toISOString()})`);
        if (dryRun) {
          core.info(`[DRY RUN] Would delete release and tag: ${release.tag_name}`);
        } else {
          try {
            core.info(`Deleting release ${release.tag_name} (ID: ${release.id})...`);
            await github.rest.repos.deleteRelease({
              owner,
              repo,
              release_id: release.id
            });
            core.info(`Deleted release ${release.tag_name}.`);
          } catch (err) {
            core.error(`Failed to delete release ${release.tag_name}: ${err.message}`);
          }

          try {
            core.info(`Deleting tag reference: refs/tags/${release.tag_name}...`);
            await github.rest.git.deleteRef({
              owner,
              repo,
              ref: `tags/${release.tag_name}`
            });
            core.info(`Deleted tag reference: refs/tags/${release.tag_name}.`);
          } catch (err) {
            core.warning(`Could not delete tag reference refs/tags/${release.tag_name}: ${err.message}`);
          }
        }
      } else {
        core.info(`[KEEP] ${release.tag_name} - Age: ${ageDays} days (Published: ${releaseDate.toISOString()}) - Under 7 days old`);
      }
    }
  }
};
