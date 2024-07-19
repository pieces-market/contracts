// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

interface ICustomGovernor {
    error Governor__ProposalNotActive();
    error Governor__ProposalDoesNotExist();
    error Governor__TokenAlreadyUsedForVoting(uint proposalId, uint tokenId);

    enum ProposalState {
        Inactive,
        Active,
        Passed,
        Failed
    }

    enum VoteType {
        For,
        Against,
        Abstain
    }

    event Propose(uint indexed id, address indexed asset, uint indexed deadline, string description);
}
