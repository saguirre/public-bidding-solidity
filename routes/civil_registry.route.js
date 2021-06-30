const express = require('express');
const router = express.Router();
const civilRegistryService = require('../services/civil_registry.service');

router.get('/compile', function (req, res) {
    try {
        civilRegistryService.compile();
        res.status(200).send('Contract compiled');
    }
    catch (error) {
        console.log(error);
        res.status(500).send(new Error('Cannot compile contract.'));
    }
});

router.get('/deploy', function (req, res) {
    try {
        civilRegistryService.deploy();
        res.status(200).send('Contract deployed');
    }
    catch (error) {
        console.log(error);
        res.status(500).send(new Error('Cannot deploy contract.'));
    }
});

router.get('/register', async function (req, res) {
    try {
        const contract = civilRegistryService.getContract();
        const ci = '48170514';
        const name = 'Santi';
        const lastName = 'Aguirre';
        const birthDate = 10071994;
        await contract.methods.registerCitizen(ci, name, lastName, birthDate).call();
        res.status(201).send('Citizen registered');
    } catch (error) {
        console.log(error);
        res.status(500).send(new Error(error));
    }
});

module.exports = router
