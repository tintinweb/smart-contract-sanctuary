// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

/**
 * @title BeepNFT contract
 */
contract BeepNFT is ERC721, ERC721Enumerable, Ownable {

    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 6969;

    string private _baseTokenURI;
    bool public saleIsActive;

    constructor(string memory baseURI) ERC721("BeepNFT", "BEEP")  {
        saleIsActive = false;
        setBaseURI(baseURI);
    }

    function mint(uint256 num) public payable {
        uint256 supply = totalSupply();
        require(saleIsActive, "Sale is not active");
        require(num > 0, "Minting 0");
        require(num <= 9, "Max of 9 is allowed");
        require(supply + num <= MAX_TOKENS, "Passing max supply");
        require(msg.value >= 0, "Ether sent must be >= 0");

        for(uint256 i; i < num; i++){
            _safeMint(msg.sender, supply + i);
        }
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /*
    * @dev Reserve 10, owner only
    */
    function reserveTokens() public onlyOwner {
        uint256 supply = totalSupply();
        for (uint256 i = 0; i < 10; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    /*
    * @dev Reserve 1, owner only
    */
    function reserveToken() public onlyOwner {
        uint256 supply = totalSupply();
        _safeMint(msg.sender, supply);
    }

    /*
    * @dev Needed below function to resolve conflicting fns in ERC721 and ERC721Enumerable
    */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /*
    * @dev Needed below function to resolve conflicting fns in ERC721 and ERC721Enumerable
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
}