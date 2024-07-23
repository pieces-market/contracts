// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

interface IGovernor {
    error Governor__ProposalNotActive();
    error Governor__ProposalDoesNotExist();
    error Governor__TokenAlreadyUsedForVoting(uint proposalId, uint tokenId);
    error Governor__AlreadyVoted();
    error Governor__ZeroVotingPower();

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

    event StateChange(uint indexed id, ProposalState);
    event Propose(uint indexed id, address indexed asset, uint indexed deadline, string description);
}
