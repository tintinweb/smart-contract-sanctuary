// SPDX-License-Identifier: MIT
// File: contracts/RedCat.sol


pragma solidity ^0.8.9;


import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract RedCats is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    uint256 private _price = 1 ether;
    bool public _paused = true;

    address t1 = 0x4368c224665CC098A70FE4C1322218ae03511395;

    constructor(string memory baseURI) ERC721("Red Cata", "RCC")  {
        setBaseURI(baseURI);
    }

    function adopt(uint256 num) public payable {
        uint256 supply = totalSupply();
        require(!_paused, "Sale is not active");
        require(num < 21, "You can adopt a maximum of 20 Cats");
        require(supply + num < 10000, "Exceeds maximum Cats supply" );
        require(msg.value >= _price * num, "Ether sent is not correct" );

        for(uint256 i; i < num; i++){
            _safeMint(msg.sender, supply + i);
        }
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
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


    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(t1).send(address(this).balance));
    }
}