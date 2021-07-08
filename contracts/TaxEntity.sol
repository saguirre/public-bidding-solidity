// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./Tax.sol";
import "./Citizen.sol";

contract TaxEntity {
    struct ConstructionBudget {
        address construction;
        uint256 amount;
    }

    // Tax address => Tax. All registered taxes
    mapping(address => Tax) taxes;
    // List of taxes
    Tax[] taxList;
    mapping(address => Tax) lastTaxPayed;
    mapping(address => mapping(address => uint256)) citizenDebt;
    mapping(address => Tax[]) citizenTaxes;
    mapping(address => uint256) totalCitizenDebt;
    address private owner;
    address private ownerContract;
    Queue constructionQueue;
    address[] approvedCitizens;
    uint256 previousMonth = block.timestamp;
    uint256 monthLength = 30;

    constructor(address regulatoryEntityAddress) {
        owner = msg.sender;
        ownerContract = regulatoryEntityAddress;
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

    function chargeInterest() public isOwner isNextMonth {
        for (uint256 i = 0; i < approvedCitizens.length; i++) {
            for (uint256 j = 0; j < taxList.length; j++) {
                if (
                    citizenDebt[approvedCitizens[i]][address(taxList[j])] != 0
                ) {
                    uint256 interest = (taxList[j].amount() *
                        taxList[j].monthlyInterest()) / 100;
                    citizenDebt[approvedCitizens[i]][
                        address(taxList[j])
                    ] += interest;
                }
            }
        }
    }

    function chargeExpiredTaxes() public isOwner {
        for (uint256 i = 0; i < taxList.length; i++) {
            if (taxExpired(taxList[i])) {
                for (uint256 j = 0; j < approvedCitizens.length; j++) {
                    citizenDebt[approvedCitizens[j]][
                        address(taxList[i])
                    ] += taxList[i].amount();
                }
                taxList[i].advanceMonthlyExpiration();
            }
        }
    }

    function taxExpired(Tax tax) private view returns (bool) {
        return tax.monthlyExpiration() < block.timestamp;
    }

    function changeMonthLength(uint256 _monthLength) public isOwner {
        monthLength = _monthLength;
    }

    modifier isNextMonth() {
        require(
            ((block.timestamp - previousMonth) / 60 / 60 / 24) >= monthLength,
            "Solo se puede cobrar interes una vez pasado al siguiente mes"
        );
        _;
        previousMonth = block.timestamp;
    }

    function getCitizenDebtForTax(address citizenAddress, address taxAddress)
        public
        view
        returns (uint256)
    {
        return citizenDebt[citizenAddress][taxAddress];
    }

    function getTotalCitizenDebt(address citizen)
        public
        view
        returns (uint256)
    {
        return totalCitizenDebt[citizen];
    }

    function addTax(
        string memory name,
        string memory lineOfWork,
        uint256 amount,
        uint256 monthlyExpiration,
        uint256 monthlyInterest
    ) public isOwnerContract {
        Tax tax = new Tax();
        tax.setValues(
            name,
            lineOfWork,
            amount,
            monthlyExpiration,
            monthlyInterest,
            address(this)
        );
        taxList.push(tax);
        taxes[address(tax)];
        addTaxToApprovedCitizens(tax);
    }

    // Agrego un ciudadano a mi lista de addresses.
    // Agrego a la deuda de ese ciudadano cada cantidad de cada tax que existen.
    function addApprovedCitizen(address citizen) public isOwnerContract {
        approvedCitizens.push(citizen);
        for (uint256 i = 0; i < taxList.length; i++) {
            citizenDebt[citizen][address(taxList[i])] = taxList[i].amount();
        }
    }

    function addTaxToApprovedCitizens(Tax tax) private {
        for (uint256 i = 0; i < approvedCitizens.length; i++) {
            citizenDebt[approvedCitizens[i]][address(tax)] = tax.amount();
        }
    }

    function fundConstruction(uint256 amount, address construction)
        public
        isOwnerContract
    {
        if (amount > address(this).balance) {
            constructionQueue.enqueue(construction, amount);
        } else {
            payable(construction).transfer(amount);
        }
    }

    modifier costs(Tax tax) {
        require(
            msg.value >= citizenDebt[msg.sender][address(tax)],
            "No ha enviado suficiente Ether para pagar el impuesto."
        );

        _;
        handleConstructionQueueFunding();
        if (msg.value > citizenDebt[msg.sender][address(tax)])
            payable(msg.sender).transfer(
                msg.value - citizenDebt[msg.sender][address(tax)]
            );
    }

    function handleConstructionQueueFunding() private {
        if (!constructionQueue.isEmpty()) {

                Queue.ConstructionBudget memory constructionToFund
             = constructionQueue.viewFirst();
            if (address(this).balance >= constructionToFund.amount) {
                payable(constructionToFund.construction).transfer(
                    constructionToFund.amount
                );
                constructionQueue.dequeue();
            }
        }
    }

    // Sender can only pay its own tax.
    // If sender sent too much money, he is refunded.
    // If sender sent too little, he is not allowed to pay what he sent.
    // When tax is payed, the last tax payed for the sender is marked as it
    function payTax(Tax tax) public payable costs(tax) {
        citizenDebt[msg.sender][address(tax)] = 0;
        lastTaxPayed[msg.sender] = taxes[address(tax)];
    }

    function howMuch(address taxAddress) public view returns (uint256) {
        return citizenDebt[msg.sender][taxAddress];
    }
}

contract Queue {
    struct ConstructionBudget {
        address construction;
        uint256 amount;
    }

    mapping(uint256 => ConstructionBudget) queue;
    uint256 first = 1;
    uint256 last = 0;

    function isEmpty() public view returns (bool) {
        return last < first;
    }

    function enqueue(address construction, uint256 amount) public {
        last += 1;
        queue[last] = ConstructionBudget({
            construction: construction,
            amount: amount
        });
    }

    function viewFirst()
        public
        view
        returns (ConstructionBudget memory construction)
    {
        require(last >= first);
        return queue[first];
    }

    function dequeue() public returns (ConstructionBudget memory construction) {
        require(last >= first); // non-empty queue

        construction = queue[first];

        delete queue[first];
        first += 1;
    }
}
