// SPDX-License-Identifier: GPL-3.0
// Git https://github.com/pieces-market/contracts 

pragma solidity ^0.8.21;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";

//TODO: ensure we have just one offer in one time, or extend functionalitiy to make bidding possible

contract BuyoutGov is Governor, GovernorCountingSimple, GovernorVotes, GovernorVotesQuorumFraction {
    //quorum hardcoded for 50%
    constructor(IVotes _token) Governor("RefundOfferGov") GovernorVotesQuorumFraction(50) GovernorVotes(_token) {}

    function votingDelay() public pure override returns (uint256) {
        return 0; // NO DELAY!
    }

    function votingPeriod() public pure override returns (uint256) {
        return 7200; // 24h
    }

    function proposalThreshold() public pure override returns (uint256) {
        return 0;// run after finish
    }
}