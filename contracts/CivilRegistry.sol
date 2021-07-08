// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./Citizen.sol";

contract CivilRegistry {
    mapping(address => Citizen) registeredCitizens;
    Citizen[] approvedCitizens;
    uint256 creationDate = block.timestamp;
    address private owner;
    address private ownerContract;

    constructor(address regulatoryEntityAddress) {
        owner = msg.sender;
        ownerContract = regulatoryEntityAddress;
    }

    function registerCitizen(
        string memory ci,
        string memory name,
        string memory lastName,
        uint256 birthDate
    ) public {
        registeredCitizens[msg.sender] = new Citizen();
        registeredCitizens[msg.sender].setValues(
            ci,
            name,
            lastName,
            birthDate,
            address(this)
        );
    }

    modifier isOwner() {
        require(
            msg.sender == owner,
            "Solo el owner puede realizar esta operacion"
        );
        _;
    }

    function changeOwner(address newOwner) public isOwner {
        owner = newOwner;
    }

    function changeOwnerContract(address newOwner) public isOwner {
        ownerContract = newOwner;
    }

    function getApprovedCitizens() public view returns (Citizen[] memory) {
        return approvedCitizens;
    }

    function checkIfCitizenIsApproved(address citizen)
        public
        view
        returns (bool)
    {
        return registeredCitizens[citizen].approved();
    }

    function citizenHasVoted(address citizen) public view returns (bool) {
        return registeredCitizens[citizen].voted();
    }

    function getVotingPercentage() public view returns (uint256) {
        return (approvedCitizens.length * getCitizenAmountThatHasVoted()) / 100;
    }

    function getCitizenAmountThatHasVoted() public view returns (uint256) {
        uint256 votedAmount = 0;
        for (uint256 i = 0; i < approvedCitizens.length; i++) {
            if (approvedCitizens[i].voted()) {
                votedAmount += 1;
            }
        }

        return votedAmount;
    }

    modifier isOwnerContract() {
        require(
            msg.sender == ownerContract,
            "Esta accion solo puede ser realizada por el Estado"
        );
        _;
    }

    function approveCitizenVote(address citizen) public isOwnerContract {
        require(
            registeredCitizens[citizen].approved(),
            "El ciudadano no esta aprobado para votar"
        );
        registeredCitizens[citizen].setVoted(true);
    }

    function approveCitizen(address citizen) public isOwnerContract {
        registeredCitizens[citizen].setApproval(true);
        approvedCitizens.push(registeredCitizens[citizen]);
    }
}
