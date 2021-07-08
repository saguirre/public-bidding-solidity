// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Tax {
    string public name;
    string public lineOfWork;
    uint256 public amount;
    uint256 public monthlyExpiration;
    uint256 public monthlyInterest;
    bool public active;
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function setValues(
        string memory _name,
        string memory _lineOfWork,
        uint256 _amount,
        uint256 _monthlyExpiration,
        uint256 _monthlyInterest,
        address _owner
    ) public isOwner {
        name = _name;
        lineOfWork = _lineOfWork;
        amount = _amount;
        monthlyExpiration = _monthlyExpiration;
        monthlyInterest = _monthlyInterest;
        owner = _owner;
        active = true;
    }

    modifier isOwner() {
        require(
            msg.sender == owner,
            "Esta funcion solo puede ser realizada por el dueno del contrato"
        );
        _;
    }

    function advanceMonthlyExpiration() public isOwner {
        monthlyExpiration += 30 days;
    }
}
