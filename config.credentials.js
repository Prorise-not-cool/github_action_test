// config.credentials.js
// 这是一个模拟的硬编码密钥场景
const awsConfig = {
    region: "us-east-1",
    // GitHub 的测试用伪造 Token，会被识别为真实风险
    accessToken: "ghp_123456789012345678901234567890123456" 
}

console.log("Connecting to AWS...", awsConfig);