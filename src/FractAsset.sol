// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import "@ERC721A/contracts/ERC721A.sol";
import "@ERC721A/contracts/extensions/ERC721ABurnable.sol";
import "@ERC721A/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/governance/utils/Votes.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";

/// @dev ERC404

/// @dev ERC721A version of Asset (NFT) contract with cheap multiple minting function
contract FractAsset is ERC721A, ERC721ABurnable, ERC721AQueryable, EIP712, Votes, Ownable {
    /// @dev ERROR!
    /// @dev Consider case when, tokenTransfer is peformed during voting (original owner already voted then transferred token)
    /// @dev check if buyer of token has vote also

    /// @dev Consider changing it into 'bytes32 private immutable'
    string private baseURI;

    // We are getting 'name' and 'symbol' from Auctioner.sol -> Owner of this contract is Auctioner.sol
    constructor(string memory name, string memory symbol, string memory uri, address owner) ERC721A(name, symbol) EIP712(name, symbol) Ownable(owner) {
        baseURI = uri;
    }

    // This will lead to Metadata, which will be unique for each token
    // There will be 'image' field in Metadata that will be same for all tokens per asset
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @dev Override tokenURI to keep 1 URI for all tokens

    // Multi-mint function to mint multiple tokens to a single user
    function safeBatchMint(address to, uint256 quantity) external onlyOwner {
        _safeMint(to, quantity);
        _delegate(to, to);
    }

    function burnFrom() external onlyOwner {
        uint256[] memory tokenIds = this.tokensOfOwner(msg.sender);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
        }
    }

    /// @dev WE NEED TO OVERRIDE BURN, DELEGATE etc.!!! (onlyOwner)
    ///
    ///

    /// @dev Delegate needs to be called to assign votes
    // function delegateVotes(address delegatee) external {
    //     _delegate(delegatee, delegatee);
    // }

    /// @dev See {ERC721-_afterTokenTransfer}. Adjusts votes when tokens are transferred.
    /// @dev Instead of {_afterTokenTransfer} that is used in ERC721, ERC721A uses {_afterTokenTransfers} (with an 's')
    /// @dev Emits a {IVotes-DelegateVotesChanged} event.
    /// @dev This function is corrupting burn
    // function _afterTokenTransfers(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual override {
    //     _transferVotingUnits(from, to, batchSize);
    //     _delegate(to, to);
    //     super._afterTokenTransfers(from, to, firstTokenId, batchSize);
    // }

    /// @dev Returns the balance of `account`.
    /// @dev WARNING: Overriding this function will likely result in incorrect vote tracking.
    function _getVotingUnits(address account) internal view virtual override returns (uint256) {
        return balanceOf(account);
    }

    /// @dev Check if we indeed need it
    /// @dev ERC721a Governance Token Interface Support
    /// @dev Implements the interface support check for ERC721a Governance Token
    /// @notice Checks if the contract implements an interface you query for, including ERC721A and Votes interfaces
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return True if the contract implements `interfaceId` or if `interfaceId` is the ERC-165 interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A) returns (bool) {
        return interfaceId == type(IVotes).interfaceId || super.supportsInterface(interfaceId);
    }
}
