// SPDX-License-Identifier: MIT

// Contract by pr0xy.io

pragma solidity ^0.8.7;

import './ERC721Enumerable.sol';
import './Ownable.sol';

contract MadRabbitsRiotClub is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public _baseTokenURI;

  bool public _active = false;
  bool public _bulkActive = false;
  bool public _presaleActive = false;

  uint256 public _gifts = 300;
  uint256 public _price = 0.065 ether;
  uint256 public _presaleMintLimit = 1;
  uint256 public constant _MINT_LIMIT = 10;

  uint256 public constant _SUPPLY = 7500;
  uint256 public constant _MAIN_SALE_SUPPLY = 6400;
  uint256 public constant _PRESALE_SUPPLY = 2500;

  mapping(address => bool) private _whitelist;
  mapping(address => uint256) private _claimed;
  mapping(address => uint256) private _bulklist;

  address public _v1 = 0x9704e7f9445509c740CAafB4c6cD62cEa03c3fa5;
  address public _v2 = 0x060B103D088e3f5C8381c20Cf2c5e675dda28D59;
  address public _v3 = 0x5453D123EDdC36f2C05E1FCcBD0AA9fAC579BC2A;
  address public _v4 = 0x5404980C4e40310073f4c959E91bA94c4C47Ca03;
  address public _v5 = 0x01a5Ade4eB79999a941D887Ace9B2710c2578c5F;
  address public _v6 = 0x17842c31D82C05FA5baD798A44B496B470265777;
  address public _v7 = 0x8353cAcfcfFA3F7111CBcdE6e49f720e14fda06e;
  address public _v8 = 0xec7146921ee4aB15375BC01673e6d9Dd4375Eff8;
  address public _v9 = 0x1EdC92cF7447A8FeCa279ea48d60D05100F03694;

  constructor() ERC721("MadRabbitsRiotClub", "MRRC") {}

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setActive(bool active) public onlyOwner {
    _active = active;
  }

  function setBulkActive(bool bulkActive) public onlyOwner {
    _bulkActive = bulkActive;
  }

  function setPresaleActive(bool presaleActive) public onlyOwner {
    _presaleActive = presaleActive;
  }

  function setPresaleMintLimit(uint256 presaleMintLimit) public onlyOwner {
    _presaleMintLimit = presaleMintLimit;
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

  function addToWhitelist(address[] calldata addresses) public onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      _whitelist[addresses[i]] = true;
      _claimed[addresses[i]] = _claimed[addresses[i]] > 0 ? _claimed[addresses[i]] : 0;
    }
  }

  function removeFromWhitelist(address[] calldata addresses) public onlyOwner {
     for (uint256 i = 0; i < addresses.length; i++) {
       _whitelist[addresses[i]] = false;
     }
   }

  function isWhitelisted(address owner) public view returns (bool) {
    return _whitelist[owner];
  }

  function getPresaleMints(address owner) public view returns (uint256){
    return _claimed[owner];
  }

  function gift(address _to, uint256 _amount) public onlyOwner {
    uint256 supply = totalSupply();
    require(_amount <= _gifts, "Gift reserve exceeded with provided amount.");

    for(uint256 i; i < _amount; i++){
      _safeMint( _to, supply + i );
    }
    _gifts -= _amount;
  }

  function getBulkAmount(address owner) public view returns (uint256){
    return _bulklist[owner];
  }

  function setBulkAmount(address owner, uint256 _amount) public onlyOwner {
    _bulklist[owner] = _amount;
  }

  function bulk(uint256 _amount) public payable {
    uint256 supply = totalSupply();
    uint256 available = _bulklist[msg.sender];

    require( _bulkActive, "Not active");
    require( _amount <= available, "Amount denied");
    require( msg.value >= _price * _amount, "Insufficient ether");
    require( supply + _amount <= _SUPPLY - _gifts, "Supply denied");

    for(uint256 i; i < _amount; i++){
      _safeMint( msg.sender, supply + i );
      _bulklist[msg.sender] -= 1;
    }
  }

  function mint(uint256 _amount) public payable {
    uint256 supply = totalSupply();

    require( _active, "Not active");
    require( _amount <= _MINT_LIMIT, "Amount denied");
    require( msg.value >= _price * _amount, "Insufficient ether");
    require( supply + _amount <= _MAIN_SALE_SUPPLY, "Supply denied");

    for(uint256 i; i < _amount; i++){
      _safeMint( msg.sender, supply + i );
    }
  }

  function presale(uint256 _amount) public payable {
    uint256 supply = totalSupply();

    require( _presaleActive, "Not active");
    require( _whitelist[msg.sender], 'Address denied');
    require( _amount + _claimed[msg.sender] <= _presaleMintLimit, "Amount denied");
    require( msg.value >= _price * _amount, "Insufficient ether");
    require( supply + _amount <= _PRESALE_SUPPLY, "Supply denied");

    for(uint256 i; i < _amount; i++){
      _safeMint( msg.sender, supply + i );
      _claimed[msg.sender] += 1;
    }
  }

  function withdraw() public payable onlyOwner {
    uint256 _p1 = address(this).balance * 57 / 200;
    uint256 _p2 = address(this).balance * 3 / 20;
    uint256 _p3 = address(this).balance * 19 / 100;
    uint256 _p4 = address(this).balance * 3 / 20;
    uint256 _p5 = address(this).balance * 4 / 50;
    uint256 _p6 = address(this).balance / 25;
    uint256 _p7 = address(this).balance / 25;
    uint256 _p8 = address(this).balance / 25;
    uint256 _p9 = address(this).balance / 40;

    require(payable(_v1).send(_p1));
    require(payable(_v2).send(_p2));
    require(payable(_v3).send(_p3));
    require(payable(_v4).send(_p4));
    require(payable(_v5).send(_p5));
    require(payable(_v6).send(_p6));
    require(payable(_v7).send(_p7));
    require(payable(_v8).send(_p8));
    require(payable(_v9).send(_p9));
  }
}