const express = require('express');
const axios = require('axios');
const cors = require('cors');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:5000';

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Insecure: Server-Side Request Forgery (SSRF)
app.get('/fetch', async (req, res) => {
    const url = req.query.url;
    try {
        const response = await axios.get(url);
        res.send(response.data);
    } catch (err) {
        res.status(500).send("Error fetching URL: " + err);
    }
});

// Insecure: Passing data to backend without validation
app.post('/api/data', async (req, res) => {
    try {
        const response = await axios.post(`${BACKEND_URL}/data`, req.body);
        res.json(response.data);
    } catch (err) {
        res.status(500).send("Error from backend");
    }
});

app.listen(80, () => {
    console.log("Insecure frontend running on port 80");
});
