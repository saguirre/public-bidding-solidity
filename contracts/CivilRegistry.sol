// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./SharedStructsLibrary.sol";

contract CivilRegistry {
    mapping(address => SharedStructs.Citizen) registeredCitizens;
    SharedStructs.Citizen[] approvedCitizens;
    uint256 creationDate = block.timestamp;
    address private owner;
    address private ownerContract;

    constructor() public {
        owner = msg.sender;
        ownerContract = msg.sender;
    }

    function registerCitizen(
        string memory ci,
        string memory name,
        string memory lastName,
        uint256 birthDate
    ) public {
        registeredCitizens[msg.sender] = SharedStructs.Citizen({
            ci: ci,
            name: name,
            lastName: lastName,
            birthDate: birthDate,
            citizenAddress: msg.sender,
            approved: false,
            voted: false
        });
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

    function getApprovedCitizens()
        public
        view
        returns (SharedStructs.Citizen[] memory)
    {
        return approvedCitizens;
    }

    function checkIfCitizenIsApproved(address citizen)
        public
        view
        returns (bool)
    {
        return registeredCitizens[citizen].approved;
    }

    function citizenHasVoted(address citizen) public view returns (bool) {
        return registeredCitizens[citizen].voted;
    }

    function approveCitizenVote(address citizen) public isOwner {
        require(registeredCitizens[citizen].approved, "El ciudadano no esta aprobado para votar");
        registeredCitizens[citizen].voted = true;
    }

    function approveCitizen(address citizen) public isOwner {
        registeredCitizens[citizen].approved = true;
        approvedCitizens.push(registeredCitizens[citizen]);
    }
}
