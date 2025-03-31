// index.js
const express = require('express');
const app = express();
const PORT = 3000;

app.get('/', (req, res) => {
    res.send('Hello, World! Application deployed to EKS through CI/CD pipeline 🚀');
});

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
