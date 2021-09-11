// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./Counters.sol";

contract EGGNFT is
    Context,
    Ownable,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable
{
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;
    uint256 private max = 10000;
    
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _tokenIdTracker.increment();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function contractURI() public view returns (string memory) {
        return "ipfs://Qmc8BDBo2XNKpbxPNBCqgmQcbjzNpNoxifVLyNvFMuXWhg";
    }
    
    function egg() public virtual {
        require(_tokenIdTracker.current() <= max);
        _mint(_msgSender(), _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}