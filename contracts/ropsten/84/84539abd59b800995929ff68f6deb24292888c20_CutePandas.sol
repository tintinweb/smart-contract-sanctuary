// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC721Enumerable.sol';
import './Ownable.sol';


contract CutePandas is ERC721Enumerable, Ownable {

    string _baseTokenURI;
    uint256 private _reserved = 499;
    uint256 private _price = 0.033 ether;
    bool public _paused = true;

    // withdraw addresses
    address t1 = 0x7a6DAAE2255491c56D82c44e522cBaC4b601985F; // yuri
    address t2 = 0x12D30e16c37a63584453BaaBA8F7f48a7Ba3CEb8; // frank
    address t3 = 0x2a3959Af34bC0E87D62a26582164Ff24A56Deffe; // eric
    address t4 = 0x1458d4598E689A37FCc3F7319ee982e31f0d924d; // cmty

    // Cute Pandas are so cute they can use the Cool Cats code ^^
    // 9999 cute pandas in total
    constructor(string memory baseURI) ERC721("Cute Panda Club", "CUTEPANDAS")  {
        setBaseURI(baseURI);
    }

    function adopt(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( !_paused,                              "Sale paused" );
        require( num < 11,                              "You can adopt a maximum of 10 Pandas" );
        require( supply + num < 10000 - _reserved,      "Exceeds maximum Panda supply" );
        require( msg.value >= _price * num,             "Ether sent is not correct" );

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
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

    // Just in case Eth does some crazy stuff
    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= _reserved, "Exceeds reserved Panda supply" );

        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }

        _reserved -= _amount;
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _each = address(this).balance / 4;
        require(payable(t1).send(_each));
        require(payable(t2).send(_each));
        require(payable(t3).send(_each));
        require(payable(t4).send(_each));
    }
}