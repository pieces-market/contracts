// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import "@ERC721A/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/governance/utils/Votes.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";

contract FractAsset is ERC721A, EIP712, Votes {
    // We are getting 'name' and 'symbol' from Auctioner.sol
    constructor(address initialOwner) ERC721A("MyToken", "MTK") EIP712("MyToken", "MTK") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https";
    }

    /// @dev See {ERC721-_afterTokenTransfer}. Adjusts votes when tokens are transferred.
    /// @dev Instead of {_afterTokenTransfer} that is used in ERC721, ERC721A uses {_afterTokenTransfers} (with an 's')
    ///  Emits a {IVotes-DelegateVotesChanged} event.
    function _afterTokenTransfers(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual override {
        _transferVotingUnits(from, to, batchSize);
        super._afterTokenTransfers(from, to, firstTokenId, batchSize);
    }

    /// @dev Returns the balance of `account`.
    /// WARNING: Overriding this function will likely result in incorrect vote tracking.
    function _getVotingUnits(address account) internal view virtual override returns (uint256) {
        return balanceOf(account);
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
