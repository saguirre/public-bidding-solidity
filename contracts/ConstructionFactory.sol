// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./Proposal.sol";
import "./Construction.sol";

contract ConstructionFactory {
    mapping(address => Construction) constructions;
    address regulatoryEntity;
    address taxEntity;

    constructor(address regulatoryEntityAddress, address taxEntityAddress) {
        regulatoryEntity = regulatoryEntityAddress;
        taxEntity = taxEntityAddress;
    }

    function createConstruction(Proposal proposal)
        public
        returns (address constructionAddress)
    {
        Construction construction = new Construction();
        construction.setValues(
            proposal.name(),
            proposal.lineOfWork(),
            proposal.description(),
            proposal.budget(),
            regulatoryEntity,
            taxEntity,
            proposal.owner()
        );
        constructions[address(construction)] = construction;
        return address(construction);
    }

    function getConstruction(address constructionAddress)
        public
        view
        returns (Construction construction)
    {
        return constructions[constructionAddress];
    }
}
