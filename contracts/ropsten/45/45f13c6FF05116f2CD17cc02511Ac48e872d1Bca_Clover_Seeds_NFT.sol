pragma solidity 0.8.11;

// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./SafeMath.sol";

contract Clover_Seeds_NFT is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    using SafeMath for uint256;
    
    uint256 private _cap = 333e3;

    mapping (address => bool) public minters;

    constructor() ERC721("Clover SEED$ NFT", "CSNFT") {}
    
    modifier onlyMinter() {
        require(minters[msg.sender], "Restricted to minters.");
        _;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addMinter(address account) public onlyOwner {
        minters[account] = true;
    }

    function removeMinter(address account) public onlyOwner {
        minters[account] = false;
    }

    function safeMint(address to, uint256 tokenId) public onlyMinter {
        require(totalSupply().add(tokenId) <= _cap);
        _safeMint(to, tokenId);
    }

    function set_cap(uint256 amount) public onlyOwner {
        _cap = amount;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    function addURI(uint256[] memory tokenId, string[] memory uri) public onlyOwner {
        require(tokenId.length == uri.length, "Please enter equal tokenId & uri length..");
        
        for (uint256 i = 0; i < tokenId.length; i++) {
            _setTokenURI(tokenId[i], uri[i]);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}