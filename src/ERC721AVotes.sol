// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import "@ERC721A/contracts/ERC721A.sol";
import "@openzeppelin/contracts/governance/utils/Votes.sol";

abstract contract ERC721AVotes is ERC721A, Votes {
    /// @dev See {ERC721A - _afterTokenTransfers}. Adjusts votes when tokens are transferred.
    /// @dev Emits a {IVotes-DelegateVotesChanged} event.
    ///
    /// @dev This function is corrupting burn
    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override {
        _transferVotingUnits(from, to, quantity);
        super._afterTokenTransfers(from, to, startTokenId, quantity);
    }

    /// @dev Returns the votes balance of `account`.
    function _getVotingUnits(address account) internal view virtual override returns (uint256) {
        return balanceOf(account);
    }
}
