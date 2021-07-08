// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./CivilRegistry.sol";
import "./TaxEntity.sol";

contract RegulatoryEntity {
    address private owner;
    TaxEntity private taxEntityContract;
    CivilRegistry private civilRegistryContract;
    mapping(address => bool) private authorizedUsers;
    uint256 public voteBudgetValue = 1 ether;
    uint256 public creationTime = block.timestamp;

    constructor() {
        owner = msg.sender;
    }

    function setCivilRegistry(address civilRegistryAddress)
        public
        onlyBy(owner)
    {
        civilRegistryContract = CivilRegistry(civilRegistryAddress);
    }

    function setTaxEntity(address taxEntityAddress) public onlyBy(owner) {
        taxEntityContract = TaxEntity(taxEntityAddress);
    }

    modifier onlyBy(address _account) {
        require(msg.sender == _account, "Unauthorized");
        _;
    }

    function changeOwner(address _newOwner) public onlyBy(owner) {
        owner = _newOwner;
    }

    modifier isAuthorized() {
        require(authorizedUsers[msg.sender], "Unauthorized");
        _;
    }

    function approveCitizenVote(address citizen) public {
        civilRegistryContract.approveCitizenVote(citizen);
    }

    function addAuthorizedUser(address user) public onlyBy(owner) {
        authorizedUsers[user] = true;
    }

    function approveRegisteredCitizen(address citizen) public isAuthorized {
        civilRegistryContract.approveCitizen(citizen);
        taxEntityContract.addApprovedCitizen(citizen);
    }

    function fundConstruction(uint256 amount, address construction)
        public
    {
        taxEntityContract.fundConstruction(amount, construction);
    }
}
