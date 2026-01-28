import * as qcdn from '@q/qcdn';
import path from 'path';

// 从命令行参数获取文件路径
const filePath = process.argv[2];

if (!filePath) {
  console.error('Please provide a file path');
  process.exit(1);
}

// 检查文件名是否符合允许的字符集
// 允许的字符：字母、数字、下划线、短横线、斜杠、点
// 如果符合，保留原始文件名 (keepName: true)
// 否则让 qcdn 生成安全的文件名 (keepName: false)
const fileName = path.basename(filePath);
const allowedChars = /^[a-zA-Z0-9_\-\/\.]+$/;
const keepName = allowedChars.test(fileName);

try {
  const res = await qcdn.upload(filePath, {
    https: true,
    keepName: keepName,
  });

  // 返回结果是一个对象，key 是本地路径，value 是远程 URL
  // 例如: { '/path/to/file.png': 'https://url...' }
  const remoteUrl = res[filePath];

  if (remoteUrl) {
    // 使用标记符打印，便于在 Lua 中可靠地解析
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
