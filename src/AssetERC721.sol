// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Consecutive.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @dev ERC404

/// @dev Standard ERC721 version of Asset (NFT) with votes
contract AssetERC721 is ERC721, ERC721Consecutive, ERC721Enumerable, ERC721Burnable, EIP712, ERC721Votes, Ownable {
    // We are getting 'name' and 'symbol' from Auctioner.sol
    constructor(address initialOwner) ERC721("MyToken", "MTK") Ownable(initialOwner) EIP712("MyToken", "1") {}

    // We are getting uri from Auctioner.sol
    function _baseURI() internal pure override returns (string memory) {
        return "https";
    }

    function safeMint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId);
    }

    function mintConsecutive(address to, uint96 quantity) external onlyOwner {
        _mintConsecutive(to, quantity);

        /// @dev This approach is terrible as we would need to transfer ownership of many tokens anyway
    }

    /// @notice The following functions are overrides required by Solidity

    function _ownerOf(uint256 tokenId) internal view virtual override(ERC721, ERC721Consecutive) returns (address) {
        return super._ownerOf(tokenId);
    }

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Consecutive, ERC721Enumerable, ERC721Votes) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable, ERC721Votes) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
