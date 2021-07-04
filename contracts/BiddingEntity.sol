// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./TaxEntity.sol";
import "./RegulatoryEntity.sol";
import "./CivilRegistry.sol";
import "./SharedStructsLibrary.sol";
import "./Construction.sol";

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

    TaxEntity taxEntity;
    RegulatoryEntity regulatoryEntity;
    CivilRegistry civilRegistry;
    mapping(address => SharedStructs.Citizen) public voters;

    SharedStructs.Proposal[] public proposals;
    SharedStructs.Proposal[] private approvedProposals;

    constructor(
        address regulatoryEntityAddress,
        address civilRegistryAddress,
        address taxEntityAddress
    ) {
        regulatoryEntity = RegulatoryEntity(regulatoryEntityAddress);
        taxEntity = TaxEntity(taxEntityAddress);
        civilRegistry = CivilRegistry(civilRegistryAddress);
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
            taxEntity.getCitizenDebt(msg.sender) == 0,
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

    function nextPeriod() internal {
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
            require(votePercentage >= 80, "No ha votado suficiente gente");
            require(
                block.timestamp >= votingPeriodStart + 15 days,
                "No han pasado los dias suficientes"
            );

            closeOutVotingPeriod();
        }
        period = Period(uint256(period) + 1);
    }

    function closeOutVotingPeriod() private onlyAt(Period.ProposalVoting) {
        uint256 budgetVoteValue = regulatoryEntity.voteBudgetValue();

        for (uint256 i = 0; i < proposals.length; i++) {
            uint256 coveredBudget = proposals[i].voteCount * budgetVoteValue;
            if (coveredBudget == proposals[i].budget) {
                approvedProposals.push(proposals[i]);
                // Create Obra
            }
        }
        // De esta forma se descartan las propuestas no aprobadas
        proposals = approvedProposals;
    }

    function receiveProposal(
        string memory name,
        string memory lineOfWork,
        string memory description,
        uint256 voteCount
    ) public userApproved hasNoDebt onlyAt(Period.AcceptingProposals) {
        proposals.push(
            SharedStructs.Proposal({
                name: name,
                lineOfWork: lineOfWork,
                description: description,
                budget: 0,
                voteCount: 0
            })
        );
    }

    function vote(uint256 proposal)
        public
        userApproved
        hasNoDebt
        hasNotVoted
        onlyAt(Period.ProposalVoting)
    {
        regulatoryEntity.approveCitizenVote(msg.sender);
        proposals[proposal].voteCount += 1;
    }

    Construction[] public constructions;
    uint256 disabledCount;

    event ChildCreated(address childAddress, uint256 data);

    function createChild(uint256 data) external {
        Construction child = new Construction(data, constructions.length);
        constructions.push(child);
        emit ChildCreated(address(child), data);
    }

    function getChildren()
        external
        view
        returns (Construction[] memory _constructions)
    {
        _constructions = new Construction[](
            constructions.length - disabledCount
        );
        uint256 count;
        for (uint256 i = 0; i < constructions.length; i++) {
            if (constructions[i].isEnabled()) {
                _constructions[count] = constructions[i];
                count++;
            }
        }
    }

    function disable(Construction child) external {
        constructions[child.index()].disable();
        disabledCount++;
    }
}
