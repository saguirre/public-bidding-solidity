// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Citizen {
    string public ci;
    string public name;
    string public lastName;
    uint256 public birthDate;
    address public owner;
    bool public approved;
    bool public voted;

    constructor() {
        owner = msg.sender;
    }

    function setValues(
        string memory _ci,
        string memory _name,
        string memory _lastName,
        uint256 _birthDate,
        address _owner
    ) public isOwner {
        ci = _ci;
        name = _name;
        lastName = _lastName;
        birthDate = _birthDate;
        owner = _owner;
        voted = false;
        approved = false;
    }

    modifier isOwner() {
        require(
            msg.sender == owner,
            "Esta funcion solo puede ser realizada por el dueno del contrato"
        );
        _;
    }

    function setApproval(bool isApproved) public isOwner {
        approved = isApproved;
    }

    function setVoted(bool hasVoted) public isOwner {
        voted = hasVoted;
    }
}
