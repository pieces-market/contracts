// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

interface IGovernor {
    error Governor__ProposalDoesNotExist();
    error Governor__ProposalNotActive();
    error Governor__AlreadyVoted();
    error Governor__ZeroVotingPower();
    error Governor__ExecuteFailed();

    enum ProposalState {
        INACTIVE,
        ACTIVE,
        SUCCEEDED,
        FAILED
    }

    enum VoteType {
        FOR,
        AGAINST
    }

    /// @notice Emitted when a new proposal is created
    /// @param id The id of the proposal
    /// @param auctionId The id of the auction that received offer
    /// @param asset Address of the asset linked to the proposal
    /// @param voteStart The timestamp when the proposal voting starts
    /// @param voteEnd The timestamp when the proposal voting ends
    /// @param description Description of the proposal
    /// @param proposalType Function to be called on execution expressed in bytes
    event Propose(uint indexed id, uint indexed auctionId, address indexed asset, uint voteStart, uint voteEnd, string description, uint proposalType);

    /// @notice Emitted when proposal has been executed or cancelled and removed from ongoing proposals array
    /// @param id The id of the proposal
    event ProcessProposal(uint indexed id);

    /// @notice Emitted when vote has been casted
    /// @param id The id of the proposal
    /// @param vote The type of vote cast
    /// @param votes The number of votes cast
    event CastVote(uint indexed id, VoteType indexed vote, uint indexed votes);

    /// @notice Emitted when the state of a proposal changes
    /// @param id The id of the proposal
    /// @param state The new state of the proposal
    event StateChange(uint indexed id, ProposalState indexed state);

    /// @notice Allows users to cast a vote on a proposal
    /// @param proposalId The id of the proposal
    /// @param vote Type of vote (For, Against)
    function castVote(uint proposalId, VoteType vote) external;
}
