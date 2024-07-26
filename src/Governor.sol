// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Asset} from "./Asset.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IGovernor} from "./interfaces/IGovernor.sol";
import {IAuctioner} from "./interfaces/IAuctioner.sol";

/// @dev This contract only will be allowed to execute buyout function from Auctioner
/// @dev Make Auctioner owner -> so it can call execute here by Chainlink Keepers?
contract Governor is Ownable, IGovernor {
    /// @dev FUNCTION quorum = 51%

    struct ProposalCore {
        address asset;
        uint256 voteStart;
        uint256 voteEnd;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted; // useless
        ProposalState state;
    }

    /// @dev Variables
    uint256 private _totalProposals;

    /// @dev Mappings
    mapping(uint256 proposalId => ProposalCore) private _proposals;

    /// @dev Constructor
    constructor(address owner) Ownable(owner) {}

    /// @dev This function will be called by 'buyout()' fn from 'Auctioner.sol'
    function propose(address asset, string memory description) external onlyOwner {
        ProposalCore storage proposal = _proposals[_totalProposals];

        proposal.asset = asset;
        /// @dev To be confirmed -> how long will we give each proposal to live
        proposal.voteStart = block.timestamp;
        proposal.voteEnd = block.timestamp + 7 days;
        proposal.description = description;
        proposal.state = ProposalState.Active;

        emit Propose(_totalProposals, asset, proposal.voteStart, proposal.voteEnd, description);
        emit StateChange(_totalProposals, ProposalState.Active);

        _totalProposals += 1;
    }

    /// @dev Calling 'buyout' fn from Auctioner
    function execute(uint auctionId) external onlyOwner {
        IAuctioner(owner()).buyout(auctionId);
    }

    /// @dev Changes state of proposal to failed
    function cancel(uint proposalId) external onlyOwner {
        if (proposalId >= _totalProposals) revert Governor__ProposalDoesNotExist();
        ProposalCore storage proposal = _proposals[proposalId];

        proposal.state = ProposalState.Failed;
    }

    function castVote(uint proposalId, VoteType vote) external {
        if (proposalId >= _totalProposals) revert Governor__ProposalDoesNotExist();
        ProposalCore storage proposal = _proposals[proposalId];
        if (proposal.state != ProposalState.Active) revert Governor__ProposalNotActive();
        if (proposal.hasVoted[msg.sender] == true) revert Governor__AlreadyVoted();

        // Asset(proposal.asset).delegateVotes(msg.sender);
        // if (Asset(proposal.asset).getVotes(msg.sender) == 0) revert Governor__ZeroVotingPower();

        uint256 votes = Asset(proposal.asset).getPastVotes(msg.sender, proposal.voteStart);
        if (votes == 0) revert Governor__ZeroVotingPower();

        /// @dev This approach is very expensive -> try refactor to delegate votes only when tokens bought -> track mapping(address => bool)
        /// @dev In ERC721A check if address has already voted, if so do not transfer voting power, if not transfer voting power accordingly
        //uint[] memory tokenIds = Asset(proposal.asset).tokensOfOwner(msg.sender);
        // uint voteCount = Asset(proposal.asset).getVotes(msg.sender);

        // Mark all tokens as used for voting
        // for (uint i; i < voteCount; i++) {
        //     if (proposal.hasVoted[tokenIds[i]] == true) revert Governor__TokenAlreadyUsedForVoting(proposalId, tokenIds[i]);

        //     proposal.hasVoted[tokenIds[i]] = true;
        // }

        if (vote == VoteType.For) proposal.forVotes += votes;
        if (vote == VoteType.Against) proposal.againstVotes += votes;
        if (vote == VoteType.Abstain) proposal.abstainVotes += votes;

        proposal.hasVoted[msg.sender] = true;
    }

    // Minimum amount of users that voted for proposal to pass
    function quorumReached(uint256 proposalId) internal view returns (bool) {
        ProposalCore storage proposal = _proposals[proposalId];

        /// @dev total available votes (tokens minted so far per asset) <=
        return totalVotes(proposalId) <= proposal.forVotes + proposal.abstainVotes;
    }

    function voteSucceeded(uint256 proposalId) internal view returns (bool) {
        ProposalCore storage proposal = _proposals[proposalId];

        return proposal.forVotes > proposal.againstVotes;
    }

    /// @dev Getter
    function getVotes(address asset, address holder) external view returns (uint256) {
        return Asset(asset).getVotes(holder);
    }

    /// @dev Getter
    function votingPeriod(uint proposalId) external view returns (uint) {
        ProposalCore storage proposal = _proposals[proposalId];

        return (proposal.voteEnd < block.timestamp) ? 0 : (proposal.voteEnd - block.timestamp);
    }

    /// @dev Getter
    function proposalVotes(uint256 proposalId) public view returns (uint256 forVotes, uint256 againstVotes, uint256 abstainVotes) {
        ProposalCore storage proposal = _proposals[proposalId];

        return (proposal.forVotes, proposal.againstVotes, proposal.abstainVotes);
    }

    /// @dev Getter
    function totalVotes(uint256 proposalId) internal view returns (uint256) {
        ProposalCore storage proposal = _proposals[proposalId];

        return proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
    }
}
