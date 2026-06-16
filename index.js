const express = require('express');
const app = express();
const PORT = 8080; // Dockerfile에 명시한 8080 포트와 맞춥니다.

app.get('/', (req, res) => {
  res.send('<h1>Success! Hello from GitHub Actions CI/CD Pipeline!</h1>');
});

app.get('/health', (req, res) => {
  // 나중에 ALB가 서버가 살아있는지 확인할 때 쓸 경로입니다.
  res.status(200).send('OK');
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});