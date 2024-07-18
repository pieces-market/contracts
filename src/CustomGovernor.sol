// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {FractAsset} from "./FractAsset.sol";

/// @dev This contract only will be allowed to execute buyout function from Auctioner
/// @dev Make Auctioner owner -> so it can call execute here by Chainlink Keepers?
contract CustomGovernor is Ownable {
    /// @dev FUNCTION quorum = 51%

    error Governor__ProposalNotActive();
    error Governor__ProposalDoesNotExist();
    error Governor__TokenAlreadyUsedForVoting(uint proposalId, uint tokenId);

    event Propose(uint indexed id, address indexed asset, uint indexed deadline, string description);

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

    struct ProposalCore {
        address asset;
        uint256 timeLeft;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        mapping(uint => bool) hasVoted;
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
        proposal.timeLeft = block.timestamp + 1 days;
        proposal.description = description;
        proposal.state = ProposalState.Active;

        emit Propose(_totalProposals, asset, proposal.timeLeft, description);

        _totalProposals += 1;
    }

    function execute() external onlyOwner {}

    function cancel(uint proposalId) external onlyOwner {
        if (proposalId >= _totalProposals) revert Governor__ProposalDoesNotExist();
        ProposalCore storage proposal = _proposals[proposalId];

        proposal.state = ProposalState.Failed;
    }

    function delegate() external {}

    function castVote(uint proposalId, VoteType vote) external {
        if (proposalId >= _totalProposals) revert Governor__ProposalDoesNotExist();
        ProposalCore storage proposal = _proposals[proposalId];
        if (proposal.state != ProposalState.Active) revert Governor__ProposalNotActive();

        /// @dev This approach is very expensive -> try refactor to delegate votes only when tokens bought -> track mapping(address => bool)
        /// @dev In ERC721A check if address has already voted, if so do not transfer voting power, if not transfer voting power accordingly
        uint[] memory tokenIds = FractAsset(proposal.asset).tokensOfOwner(msg.sender);
        uint voteCount = tokenIds.length;

        // Mark all tokens as used for voting
        for (uint i; i < voteCount; i++) {
            if (proposal.hasVoted[tokenIds[i]] == true) revert Governor__TokenAlreadyUsedForVoting(proposalId, tokenIds[i]);

            proposal.hasVoted[tokenIds[i]] = true;
        }

        if (vote == VoteType.For) proposal.forVotes += voteCount;
        if (vote == VoteType.Against) proposal.againstVotes += voteCount;
        if (vote == VoteType.Abstain) proposal.abstainVotes += voteCount;
    }

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
    function getVotes() external {}

    /// @dev Getter
    function votingPeriod(uint proposalId) external view returns (uint) {
        ProposalCore storage proposal = _proposals[proposalId];

        return (proposal.timeLeft < block.timestamp) ? 0 : (proposal.timeLeft - block.timestamp);
    }

    /// @dev Getter
    function proposalData(uint256 proposalId) public view returns (uint256 forVotes, uint256 againstVotes, uint256 abstainVotes) {
        ProposalCore storage proposal = _proposals[proposalId];

        return (proposal.againstVotes, proposal.forVotes, proposal.abstainVotes);
    }

    /// @dev Getter
    function totalVotes(uint256 proposalId) internal view returns (uint256) {
        ProposalCore storage proposal = _proposals[proposalId];

        return proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
    }
}
