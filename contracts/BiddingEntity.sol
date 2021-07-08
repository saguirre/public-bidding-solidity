// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./TaxEntity.sol";
import "./RegulatoryEntity.sol";
import "./CivilRegistry.sol";
import "./Construction.sol";
import "./Proposal.sol";
import "./ConstructionFactory.sol";

contract BiddingEntity {
    enum Period {
        AcceptingProposals,
        ProposalVoting,
        Closed
    }

    Period public period;

    uint256 private proposalCount;

    uint256 private budgetedProposalsCount;
    uint256 private votePercentage;

    uint256 public votingPeriodStart;
    uint256 public votingPeriodLength = 15 days;

    TaxEntity taxEntity;
    RegulatoryEntity regulatoryEntity;
    CivilRegistry civilRegistry;
    ConstructionFactory constructionFactory;
    address owner;
    mapping(address => Citizen) public voters;

    Proposal[] public proposalList;
    mapping(address => Proposal) public proposals;
    Proposal[] private approvedProposals;

    constructor(
        address regulatoryEntityAddress,
        address civilRegistryAddress,
        address taxEntityAddress,
        address constructionFactoryAddress
    ) {
        regulatoryEntity = RegulatoryEntity(regulatoryEntityAddress);
        taxEntity = TaxEntity(taxEntityAddress);
        civilRegistry = CivilRegistry(civilRegistryAddress);
        constructionFactory = ConstructionFactory(constructionFactoryAddress);
        period = Period.AcceptingProposals;
    }

    modifier onlyAt(Period _period) {
        require(
            period == _period,
            "No se puede realizar esa accion en esta etapa"
        );
        _;
    }

    modifier userApproved() {
        require(
            civilRegistry.checkIfCitizenIsApproved(msg.sender),
            "El usuario no esta aprobado para votar"
        );
        _;
    }

    modifier hasNoDebt() {
        require(
            taxEntity.getTotalCitizenDebt(msg.sender) == 0,
            "Usuario no tiene todos sus impuestos pagos"
        );
        _;
    }

    modifier hasNotVoted() {
        require(
            !civilRegistry.citizenHasVoted(msg.sender),
            "El usuario ya voto en este periodo"
        );
        _;
    }

    modifier isOwner {
        require(
            msg.sender == address(regulatoryEntity),
            "Esta funcion solo puede ser llamada por el dueno del contrato"
        );
        _;
    }

    function changeVotingPeriodLength(uint256 _votingPeriodLength)
        public
        isOwner
    {
        votingPeriodLength = _votingPeriodLength;
    }

    function nextPeriod() public isOwner {
        if (period == Period.AcceptingProposals) {
            require(
                proposalCount >= 3,
                "No se han enviado suficientes propuestas"
            );
            require(
                budgetedProposalsCount >= 3,
                "No se han presupuestado suficientes propuestas"
            );
            proposalCount = 0;
            budgetedProposalsCount = 0;
            votingPeriodStart = block.timestamp;
        }

        if (period == Period.ProposalVoting) {
            require(
                civilRegistry.getVotingPercentage() >= 80,
                "No ha votado suficiente gente"
            );
            require(
                block.timestamp >= votingPeriodStart + votingPeriodLength,
                "No han pasado los dias suficientes"
            );

            closeOutVotingPeriod();
        }
        period = Period(uint256(period) + 1);
    }

    function restartCycle() public onlyAt(Period.Closed) {
        period = Period.AcceptingProposals;
    }

    function closeOutVotingPeriod() private onlyAt(Period.ProposalVoting) {
        uint256 budgetVoteValue = regulatoryEntity.voteBudgetValue();

        for (uint256 i = 0; i < proposalList.length; i++) {
            uint256 coveredBudget = proposalList[i].voteCount() *
                budgetVoteValue;
            if (coveredBudget == proposalList[i].budget()) {
                approvedProposals.push(proposalList[i]);
                // Create Construction
                address newConstruction = constructionFactory
                .createConstruction(proposalList[i]);
                regulatoryEntity.fundConstruction(
                    proposalList[i].budget(),
                    newConstruction
                );
            }
        }
        // De esta forma se descartan las propuestas no aprobadas
        proposalList = approvedProposals;
    }

    function assignBudgetToProposal(address proposalAddress, uint256 budget)
        public
        isOwner
    {
        Proposal proposal = proposals[proposalAddress];
        proposal.setBudget(budget);
        for (uint256 i = 0; i < proposalList.length; i++) {
            if (address(proposalList[i]) == proposalAddress) {
                proposalList[i].setBudget(budget);
            }
        }
    }

    function approveProviderPayment(
        address constructionAddress,
        address provider
    ) public isOwner {
        Construction construction = constructionFactory.getConstruction(
            constructionAddress
        );
        construction.approveProviderPayment(provider);
    }

    function getConstructionProviders(address constructionAddress)
        public
        view
        isOwner
        returns (address[] memory)
    {
        Construction construction = constructionFactory.getConstruction(
            constructionAddress
        );
        return construction.getDesignatedProviders();
    }

    function receiveProposal(
        string memory name,
        string memory lineOfWork,
        string memory description
    ) public userApproved hasNoDebt onlyAt(Period.AcceptingProposals) {
        Proposal proposal = new Proposal(
            name,
            lineOfWork,
            description,
            address(this)
        );
        proposalList.push(proposal);
        proposals[address(proposal)] = proposal;
    }

    function vote(address proposal)
        public
        userApproved
        hasNotVoted
        onlyAt(Period.ProposalVoting)
    {
        regulatoryEntity.approveCitizenVote(msg.sender);
        proposals[proposal].vote();
    }
}
