// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract TaxEntity {
    struct Tax {
        string name;
        string lineOfWork;
        uint256 amount;
        uint256 monthlyExpiration;
        uint256 monthlyInterest;
        bool active;
    }

    mapping(string => Tax) taxes;
    Tax[] taxList;
    mapping(address => Tax) lastTaxPayed;
    mapping(address => mapping(string => uint256)) citizenDebt;
    address private owner;
    address private ownerContract;
    address[] approvedCitizens;

    constructor() public {
        owner = msg.sender;
        ownerContract = msg.sender;
    }

    modifier isOwner() {
        require(
            msg.sender == owner,
            "Solo el owner de este contrato puede realizar esta operacion."
        );
        _;
    }

    function changeOwnerContract(address newOwner) public isOwner {
        ownerContract = newOwner;
    }

    function changeOwner(address newOwner) public isOwner {
        owner = newOwner;
    }

    modifier isOwnerContract() {
        require(
            msg.sender == ownerContract,
            "Solo el Estado puede realizar esta operacion."
        );
        _;
    }

    function getCurrentTaxes()
        public
        view
        isOwnerContract
        returns (Tax[] memory)
    {
        return taxList;
    }

    function addTax(
        string memory name,
        string memory lineOfWork,
        uint256 amount,
        uint256 monthlyExpiration,
        uint256 monthlyInterest
    ) public isOwnerContract {
        Tax memory tax = Tax({
            name: name,
            lineOfWork: lineOfWork,
            amount: amount,
            monthlyExpiration: monthlyExpiration,
            monthlyInterest: monthlyInterest,
            active: true
        });
        taxList.push(tax);
        taxes[name];
        addTaxToApprovedCitizens(tax);
    }

    function addApprovedCitizen(address citizen) public isOwnerContract {
        approvedCitizens.push(citizen);
    }

    function addTaxToApprovedCitizens(Tax memory tax) private {
        for (uint256 i = 0; i < approvedCitizens.length; i++) {
            citizenDebt[approvedCitizens[i]][tax.name] = tax.amount;
        }
    }

    modifier costs(string memory tax) {
        require(
            msg.value >= citizenDebt[msg.sender][tax],
            "No ha enviado suficiente Ether para pagar el impuesto."
        );

        _;
        if (msg.value > taxes[tax].amount)
            payable(msg.sender).transfer(
                msg.value - citizenDebt[msg.sender][tax]
            );
    }

    // Sender can only pay its own tax.
    // If sender sent too much money, he is refunded.
    // If sender sent too little, he is allowed to pay what he sent.
    // When tax is payed, the last tax payed for the sender is marked as it
    function payTax(string memory tax) public payable costs(tax) {
        citizenDebt[msg.sender][tax] = 0;
        lastTaxPayed[msg.sender] = taxes[tax];
    }

    function howMuch(string memory tax) public view returns (uint256) {
        return citizenDebt[msg.sender][tax];
    }
}
