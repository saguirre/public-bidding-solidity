// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract CivilRegistry {
    struct Citizen {
        string ci;
        string name;
        string lastName;
        uint256 birthDate;
        address citizenAddress;
        bool voted;
        bool approved;
    }

    mapping(address => Citizen) registeredCitizens;
    Citizen[] approvedCitizens;
    uint256 creationDate = block.timestamp;
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    function registerCitizen(
        string memory ci,
        string memory name,
        string memory lastName,
        uint256 birthDate
    ) public {
        Citizen memory newCitizen = Citizen({
            ci: ci,
            name: name,
            lastName: lastName,
            birthDate: birthDate,
            voted: false,
            citizenAddress: msg.sender,
            approved: false
        });
        registeredCitizens[msg.sender] = newCitizen;
    }

    function getApprovedCitizens() public view returns (Citizen[] memory) {
        return approvedCitizens;
    }

    modifier onlyBy(address _account) {
        require(msg.sender == _account, "Unauthorized");

        _;
    }

    function approveCitizen(address citizen) public onlyBy(address(owner)) {
        registeredCitizens[citizen].approved = true;
        approvedCitizens.push(registeredCitizens[citizen]);
    }
}
