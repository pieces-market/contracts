// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import "@ERC721A/contracts/ERC721A.sol";
import "@ERC721A/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/governance/utils/Votes.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";

contract FractAsset is ERC721A, ERC721ABurnable, EIP712, Votes {
    /// @dev ERROR!
    /// @dev Consider case when, tokenTransfer is peformed during voting (original owner already voted then transferred token)
    /// @dev check if buyer of token has vote also

    // We are getting 'name' and 'symbol' from Auctioner.sol
    constructor(address initialOwner) ERC721A("MyToken", "MTK") EIP712("MyToken", "MTK") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https";
    }

    /// @dev Override tokenURI to keep 1 URI for all tokens

    // Multi-mint function to mint multiple tokens to a single user
    function safeBatchMint(address to, uint256 quantity) external {
        _safeMint(to, quantity);
        _delegate(to, to);
    }

    /// @dev Delegate needs to be called to assign votes
    // function delegateVotes(address delegatee) external {
    //     _delegate(delegatee, delegatee);
    // }

    /// @dev See {ERC721-_afterTokenTransfer}. Adjusts votes when tokens are transferred.
    /// @dev Instead of {_afterTokenTransfer} that is used in ERC721, ERC721A uses {_afterTokenTransfers} (with an 's')
    /// @dev Emits a {IVotes-DelegateVotesChanged} event.
    function _afterTokenTransfers(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual override {
        _transferVotingUnits(from, to, batchSize);
        _delegate(to, to);
        super._afterTokenTransfers(from, to, firstTokenId, batchSize);
    }

    /// @dev Returns the balance of `account`.
    /// @dev WARNING: Overriding this function will likely result in incorrect vote tracking.
    function _getVotingUnits(address account) internal view virtual override returns (uint256) {
        return balanceOf(account);
    }

    /// @dev Check if we indeed need it
    /*
     * @dev ERC721a Governance Token Interface Support
     * @dev Implements the interface support check for ERC721a Governance Token
     * @notice Checks if the contract implements an interface you query for, including ERC721A and Votes interfaces
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return True if the contract implements `interfaceId` or if `interfaceId` is the ERC-165 interface
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A) returns (bool) {
        return interfaceId == type(IVotes).interfaceId || super.supportsInterface(interfaceId);
    }
}

/// @dev ERC721 VERSION

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Votes.sol";

// contract FractAsset is ERC721, ERC721Enumerable, ERC721Burnable, Ownable, EIP712, ERC721Votes {
//     // We are getting 'name' and 'symbol' from Auctioner.sol
//     constructor(address initialOwner) ERC721("MyToken", "MTK") Ownable(initialOwner) EIP712("MyToken", "1") {}

//     // We are getting uri from Auctioner.sol
//     function _baseURI() internal pure override returns (string memory) {
//         return "https";
//     }

//     function safeMint(address to, uint256 tokenId) external onlyOwner {
//         _safeMint(to, tokenId);
//     }

//     // The following functions are overrides required by Solidity.

//     function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable, ERC721Votes) returns (address) {
//         return super._update(to, tokenId, auth);
//     }

//     function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable, ERC721Votes) {
//         super._increaseBalance(account, value);
//     }

//     function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
//         return super.supportsInterface(interfaceId);
//     }
// }
