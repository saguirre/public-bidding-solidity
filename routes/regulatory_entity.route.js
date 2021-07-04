const express = require('express');
const router = express.Router();
const regulatoryEntityService = require('../services/regulatory_entity.service');

router.get('/compile', function (req, res) {
    try {
        regulatoryEntityService.compile();
        res.status(200).send('Contract compiled');
    }
    catch (error) {
        console.log(error);
        res.status(500).send(new Error('Cannot compile contract.'));
    }
});

router.get('/deploy', function (req, res) {
    try {
        regulatoryEntityService.deploy();
        res.status(200).send('Contract deployed');
    }
    catch (error) {
        console.log(error);
        res.status(500).send(new Error('Cannot deploy contract.'));
    }
});

router.put('/set-civil-registry/:address', async (req, res) => {
    try {
        const contract = regulatoryEntityService.getContract();
        await contract.methods.setCivilRegistry(req.params.address).call({ from: '0x5FBDe0e4Fd96f036b217cAB59CEDC152e05fFc83' });
        res.status(200).send('Civil registry set');
    } catch (error) {
        console.log(error);
        res.status(500).send(new Error(error));
    }
});

router.put('/citizen/approve/:address', async (req, res) => {
    try {
        const contract = regulatoryEntityService.getContract();
        await contract.methods.approveRegisteredCitizen(req.params.address).call();
        res.status(200).send(`Citizen ${req.params.address} approved`);
    } catch (error) {
        console.log(error);
        res.status(500).send(new Error(error));
    }
});


module.exports = router
