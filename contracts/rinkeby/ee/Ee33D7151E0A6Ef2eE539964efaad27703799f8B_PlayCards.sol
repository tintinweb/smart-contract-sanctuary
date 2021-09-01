// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract PlayCards is ERC721, Ownable {

    string private _baseTokenURI;
    uint256 public _totalSupply;


    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        uint256 totalSupply
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _totalSupply = totalSupply;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }


    function _beforeTokenTransfer(uint256 tokenId) internal virtual override {
        require(tokenId < _totalSupply, "there are only 54 play cards!");
    }

    function mint(address to, uint256 tokenId) public onlyOwner{
        _safeMint(to, tokenId);
    }

    function mintBatch(address[] memory to ,uint256[] memory tokenId) public onlyOwner {
        uint256 n = to.length;
        for (uint256 i = 0; i < n; i++) {
            _safeMint(to[i], tokenId[i]);
        }
    }
}