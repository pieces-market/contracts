// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/governance/utils/IVotes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @dev Custom approach
abstract contract VotingPowerAggregator is IVotes, Ownable {
    IVotes[] public nftContracts;

    event NFTContractAdded(address indexed nftContract);
    event NFTContractRemoved(address indexed nftContract);

    constructor(IVotes[] memory _nftContracts) Ownable(msg.sender) {
        for (uint256 i = 0; i < _nftContracts.length; i++) {
            nftContracts.push(_nftContracts[i]);
        }
    }

    function addNFTContract(IVotes nftContract) external onlyOwner {
        nftContracts.push(nftContract);
        emit NFTContractAdded(address(nftContract));
    }

    function removeNFTContract(IVotes nftContract) external onlyOwner {
        for (uint256 i = 0; i < nftContracts.length; i++) {
            if (nftContracts[i] == nftContract) {
                nftContracts[i] = nftContracts[nftContracts.length - 1];
                nftContracts.pop();
                emit NFTContractRemoved(address(nftContract));
                return;
            }
        }
    }

    function getVotes(address account) external view override returns (uint256) {
        uint256 totalVotes = 0;
        for (uint256 i = 0; i < nftContracts.length; i++) {
            totalVotes += nftContracts[i].getVotes(account);
        }
        return totalVotes;
    }

    function delegate(address delegatee) external override {
        for (uint256 i = 0; i < nftContracts.length; i++) {
            nftContracts[i].delegate(delegatee);
        }
    }

    function getPastVotes(address account, uint256 blockNumber) external view override returns (uint256) {
        uint256 totalVotes = 0;
        for (uint256 i = 0; i < nftContracts.length; i++) {
            totalVotes += nftContracts[i].getPastVotes(account, blockNumber);
        }
        return totalVotes;
    }

    function getPastTotalSupply(uint256 blockNumber) external view override returns (uint256) {
        uint256 totalSupply = 0;
        for (uint256 i = 0; i < nftContracts.length; i++) {
            totalSupply += nftContracts[i].getPastTotalSupply(blockNumber);
        }
        return totalSupply;
    }
}
