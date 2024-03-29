const express = require('express');
const router = express.Router();

const citizenService = require('../services/citizen.service');
const taxService = require('../services/tax.service');
const biddingEntityService = require('../services/bidding_entity.service');
const constructionFactoryService = require('../services/construction_factory.service');
const constructionService = require('../services/construction.service');
const proposalService = require('../services/proposal.service');
const regulatoryEntityService = require('../services/regulatory_entity.service');
const taxEntityService = require('../services/tax_entity.service');
const civilRegistryService = require('../services/civil_registry.service');

router.get('/', (req, res) => {
    try {
        taxService.compile();
        citizenService.compile();
        proposalService.compile();
        civilRegistryService.compile();
        taxEntityService.compile();
        regulatoryEntityService.compile();
        constructionService.compile();
        constructionFactoryService.compile();
        biddingEntityService.compile();
        res.status(200).send('All contracts compiled');
    }
    catch (error) {
        console.log(error);
        res.status(500).send(new Error('Cannot compile contract.'));
    }
});

router.get('/deploy', async (req, res) => {
    try {
        await taxService.deploy();
        await citizenService.deploy();
        await proposalService.deploy();
        await regulatoryEntityService.deploy();
        await civilRegistryService.deploy();
        await taxEntityService.deploy();
        await constructionFactoryService.deploy();
        await constructionService.deploy();
        await biddingEntityService.deploy();
        res.status(200).send('All contracts deployed');
    }
    catch (error) {
        console.log(error);
        res.status(500).send(new Error('Cannot deploy contract.'));
    }
});


module.exports = router
