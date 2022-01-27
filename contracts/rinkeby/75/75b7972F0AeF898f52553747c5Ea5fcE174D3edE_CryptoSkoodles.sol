// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract CryptoSkoodles is Ownable, ERC721Enumerable {
    // change addresses here
    address t1 = 0x1d74B71C4bCF687E5C03F6EEdB5c650785e7d03a;
    address t2 = 0x1d74B71C4bCF687E5C03F6EEdB5c650785e7d03a;

    string _baseTokenURI;
    uint256 private _price = 0.01 ether;

    constructor() ERC721("CryptoSkoodles", "CryptoSkoodles") {}

    function mint(uint256 num) public payable {
        uint256 supply = totalSupply();
        require(num < 11, "You can only mint 10 Skoodles at once.");
        require(supply + num < 100, "Maximum collection size exceeded.");
        require(msg.value >= _price * num, "Not enough");

        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _each = address(this).balance / 2;
        require(payable(t1).send(_each));
        require(payable(t2).send(_each));
    }
}