// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./CivilRegistry.sol";
import "./TaxEntity.sol";
import "./BiddingEntity.sol";
import "./Construction.sol";

contract RegulatoryEntity {
    address private owner;
    TaxEntity private taxEntityContract;
    CivilRegistry private civilRegistryContract;
    BiddingEntity private biddingEntityContract;
    mapping(address => bool) private authorizedUsers;
    uint256 public voteBudgetValue = 1 ether;
    uint256 public creationTime = block.timestamp;

    constructor() public {
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

    function setBiddingEntity(address biddingEntityAddress)
        public
        onlyBy(owner)
    {
        biddingEntityContract = BiddingEntity(biddingEntityAddress);
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

    modifier isBiddingEntity() {
        require(
            msg.sender == address(biddingEntityContract),
            "Esta accion no puede ser realizada por esta direccion"
        );
        _;
    }

    function approveCitizenVote(address citizen) public isBiddingEntity {
        civilRegistryContract.approveCitizenVote(citizen);
    }

    function addAuthorizedUser(address user) public onlyBy(owner) {
        authorizedUsers[user] = true;
    }

    function approveRegisteredCitizen(address citizen) public isAuthorized {
        civilRegistryContract.approveCitizen(citizen); 
        taxEntityContract.addApprovedCitizen(citizen);
    }

    function fundConstruction(uint256 amount, address construction) public isBiddingEntity {
        taxEntityContract.fundConstruction(amount, construction);
    }

    function getConstructionProviders(address constructionAddress) public view returns (address[] memory)  {
        Construction construction = biddingEntityContract.getConstruction(constructionAddress);
        return construction.getDesignatedProviders();
    }

    function approveProviderPayment(address constructionAddress, address provider) public isBiddingEntity {
        Construction construction = biddingEntityContract.getConstruction(constructionAddress);
        construction.approveProviderPayment(provider);
    }
}
