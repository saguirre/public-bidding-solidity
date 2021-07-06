// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./RegulatoryEntity.sol";
import "./Proposal.sol";

contract ConstructionFactory {
    
    mapping(address => Construction) constructions;
    RegulatoryEntity regulatoryEntity;

    constructor(address regulatoryEntityAddress) {
        regulatoryEntity = RegulatoryEntity(regulatoryEntityAddress);
    }

    function createConstruction(Proposal proposal) public returns (address constructionAddress) {
        Construction construction = new Construction(
            proposal.name(),
            proposal.lineOfWork(),
            proposal.description(),
            proposal.budget(),
            address(regulatoryEntity),
            proposal.owner()
        );
        constructions[address(construction)] = construction;
        return address(construction);
    }

    function getConstruction(address constructionAddress) public view returns (Construction construction) {
        return constructions[constructionAddress];
    }
}
