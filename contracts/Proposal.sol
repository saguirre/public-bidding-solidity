// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Proposal {
    string public name;
    string public lineOfWork;
    string public description;
    uint256 public voteCount;
    uint256 public budget;
    address public owner;
    address biddingContract;

    constructor(
        string memory _name,
        string memory _lineOfWork,
        string memory _description,
        address _owner
    ) {
        name = _name;
        lineOfWork = _lineOfWork;
        description = _description;
        owner = _owner;
        voteCount = 0;
        budget = 0;
        biddingContract = msg.sender;
    }

    modifier isBiddingEntity() {
        require(
            msg.sender == biddingContract,
            "Esta funcion solo puede ser realizada por el dueno del contrato"
        );
        _;
    }

    function setBudget(uint256 amount) public isBiddingEntity {
        budget = amount;
    }

    function vote() public isBiddingEntity {
        voteCount++;
    }
}
