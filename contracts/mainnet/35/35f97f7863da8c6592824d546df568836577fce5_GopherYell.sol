// SPDX-License-Identifier: MIT

// Contract by pr0xy.io

pragma solidity ^0.8.7;

import './ERC721Enumerable.sol';
import './Ownable.sol';

contract GopherYell is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public _baseTokenURI;

  bool public _active = false;
  bool public _presaleActive = false;

  uint256 public _price = 0.04 ether;

  uint256 public constant _MINT_LIMIT = 20;
  uint256 public constant _PRESALE_MINT_LIMIT = 10;
  uint256 public constant _SUPPLY = 8888;

  mapping(address => uint256) private _mints;

  address public _v1 = 0xB6940b05101CF385053c7DfE626E23c1F8e6e2A2;
  address public _v2 = 0x5404980C4e40310073f4c959E91bA94c4C47Ca03;

  constructor() ERC721("GopherYell", "GOPHERS") {}

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setActive(bool active) public onlyOwner {
    _active = active;
  }

  function setPresaleActive(bool presaleActive) public onlyOwner {
    _presaleActive = presaleActive;
  }

  function setPrice(uint256 price) public onlyOwner {
    _price = price;
  }

  function getTokensByWallet(address _owner) public view returns(uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokensId = new uint256[](tokenCount);

    for(uint256 i; i < tokenCount; i++){
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }

    return tokensId;
  }

  function getPresaleMints(address owner) public view returns (uint256){
    require(owner != address(0), "Null denied");

    return _mints[owner];
  }

  function gift(address _to, uint256 _amount) public onlyOwner {
    uint256 supply = totalSupply();
    require( supply + _amount <= _SUPPLY, "Supply denied");

    for(uint256 i; i < _amount; i++){
      _safeMint( _to, supply + i );
    }
  }

  function mint(uint256 _amount) public payable {
    uint256 supply = totalSupply();

    require( _active, "Not active");
    require( _amount <= _MINT_LIMIT, "Amount denied");
    require( msg.value >= _price * _amount, "Insufficient ether");
    require( supply + _amount <= 8810, "Supply denied");

    for(uint256 i; i < _amount; i++){
      _safeMint( msg.sender, supply + i );
    }
  }

  function presale(uint256 _amount) public payable {
    uint256 supply = totalSupply();

    require( _presaleActive, "Not active");
    require( _amount + _mints[msg.sender] <= _PRESALE_MINT_LIMIT, "Amount denied");
    require( msg.value >= _price * _amount, "Insufficient ether");
    require( supply + _amount <= 8810, "Supply denied");

    for(uint256 i; i < _amount; i++){
      _safeMint( msg.sender, supply + i );
      _mints[msg.sender] += 1;
    }
  }

  function withdraw() public payable onlyOwner {
    uint256 _p1 = address(this).balance * 59 / 80;
    uint256 _p2 = address(this).balance * 21 / 80;

    require(payable(_v1).send(_p1));
    require(payable(_v2).send(_p2));
  }
}