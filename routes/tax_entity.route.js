const express = require('express');
const router = express.Router();
const taxEntityService = require('../services/tax_entity.service');

router.get('/compile', function (req, res) {
    try {
        taxEntityService.compile();
        res.status(200).send('Contract compiled');
    }
    catch (error) {
        console.log(error);
        res.status(500).send(new Error('Cannot compile contract.'));
    }
});

router.get('/deploy', function (req, res) {
    try {
        taxEntityService.deploy();
        res.status(200).send('Contract deployed');
    }
    catch (error) {
        console.log(error);
        res.status(500).send(new Error('Cannot deploy contract.'));
    }
});

router.get('/getBalance', async function (req, res) {
    try {
        const contract = taxEntityService.getContract();
        let result = await contract.methods.getBalance().call();
        res.status(200).send('Balance:' + web3.utils.fromWei(result, 'ether') + ' ethers');
    } catch (error) {
        console.log(error);
        res.status(500).send(new Error(error));
    }
});

module.exports = router
