import * as qcdn from '@q/qcdn';

// Get file path from command line args
const filePath = process.argv[2];

if (!filePath) {
  console.error('Please provide a file path');
  process.exit(1);
}

try {
  const res = await qcdn.upload(filePath, {
    https: true,
    keepName: true,
  });

  // The result is an object where key is local path and value is remote URL
  // Example: { '/path/to/file.png': 'https://url...' }
  const remoteUrl = res[filePath];

  if (remoteUrl) {
    // Print with markers to make parsing reliable in Lua
    console.log(`###URL_START###${remoteUrl}###URL_END###`);
  } else {
    console.error('Upload failed or no URL returned');
    console.error(JSON.stringify(res));
    process.exit(1);
  }
} catch (error) {
  console.error(error);
  process.exit(1);
}
