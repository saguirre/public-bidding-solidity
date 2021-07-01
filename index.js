const express = require('express');
const port = process.env.PORT || 3000;
const app = express();
require('dotenv').config();
const path = require('path');
const fs = require('fs');

const Web3 = require('web3');

const seedPhrase = process.env.SEED_PHRASE;
// const infuraProviderUrl = process.env.INFURA_PROVIDER_URL;
// console.log(seedPhrase)
// const HDWalletProvider = require("@truffle/hdwallet-provider");

const regulatoryEntityRoute = require('./routes/regulatory_entity.route');
const civilRegistryRoute = require('./routes/civil_registry.route');
const taxEntityRoute = require('./routes/tax_entity.route');
// const infuraProvider = new HDWalletProvider(seedPhrase, infuraProviderUrl, 0, 3);
const ganacheProvider = new Web3.providers.HttpProvider('http://127.0.0.1:7545');
web3 = new Web3(ganacheProvider);
// web3 = new Web3(infuraProvider);
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.get('/', function(req,res){ res.send('Welcome to your first wallet')});

app.use('/api/regulatory-entity', regulatoryEntityRoute);
app.use('/api/civil-registry', civilRegistryRoute);
app.use('/api/tax-entity', taxEntityRoute);

app.listen(port, () => console.log('Listening on port 3000'));