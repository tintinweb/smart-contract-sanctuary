// SPDX-License-Identifier: MIT

// Contract by pr0xy.io

pragma solidity ^0.8.7;

import './ERC721Enumerable.sol';
import './Ownable.sol';

contract AmbitiousAnts is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public _baseTokenURI;

  bool public _active = false;
  bool public _presaleActive = false;

  uint256 public _price = 0.06 ether;

  uint256 public constant _MINT_LIMIT = 15;
  uint256 public constant _PRESALE_MINT_LIMIT = 2;
  uint256 public constant _SUPPLY = 9999;
  uint256 public constant _PRESALE_SUPPLY = 3000;

  mapping(address => bool) private _whitelist;
  mapping(address => uint256) private _mints;
  mapping(address => uint256) private _freeMints;

  address public _v1 = 0x022B6A2d339BaCcE5A0212557BFeEa77Ca52d4DC;
  address public _v2 = 0x5404980C4e40310073f4c959E91bA94c4C47Ca03;

  constructor() ERC721("AmbitiousAnts", "ANTS") {}

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

  function addToWhitelist(address[] calldata addresses) public onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Null denied");

      _whitelist[addresses[i]] = true;
      _mints[addresses[i]] = _mints[addresses[i]] > 0 ? _mints[addresses[i]] : 0;
    }
  }

  function removeFromWhitelist(address[] calldata addresses) public onlyOwner {
     for (uint256 i = 0; i < addresses.length; i++) {
       require(addresses[i] != address(0), "Null denied");

       _whitelist[addresses[i]] = false;
     }
  }

  function isWhitelisted(address owner) public view returns (bool) {
    require(owner != address(0), "Null denied");

    return _whitelist[owner];
  }

  function getPresaleMints(address owner) public view returns (uint256){
    require(owner != address(0), "Null denied");

    return _mints[owner];
  }

  function getFreeMints(address owner) public view returns (uint256){
    require(owner != address(0), "Null denied");

    return _freeMints[owner];
  }

  function setFreeMints(address owner, uint256 _amount) public onlyOwner {
    require(owner != address(0), "Null denied");

    _freeMints[owner] = _amount;
  }

  function mint(uint256 _amount) public payable {
    uint256 supply = totalSupply();

    require( _active, "Not active");
    require( _amount <= _MINT_LIMIT, "Amount denied");
    require( msg.value >= _price * _amount, "Insufficient ether");
    require( supply + _amount <= _SUPPLY, "Supply denied");

    for(uint256 i; i < _amount; i++){
      _safeMint( msg.sender, supply + i );
    }
  }

  function presale(uint256 _amount) public payable {
    uint256 supply = totalSupply();
    uint256 freeMints = _freeMints[msg.sender];

    require( _presaleActive, "Not active");
    require( _whitelist[msg.sender], 'Address denied');
    require( _amount + _mints[msg.sender] <= _PRESALE_MINT_LIMIT, "Amount denied");
    require( msg.value >= _price * _amount, "Insufficient ether");
    require( supply + _amount + freeMints <= _PRESALE_SUPPLY, "Supply denied");

    for(uint256 i; i < _amount; i++){
      _safeMint( msg.sender, supply + i );
      _mints[msg.sender] += 1;
    }

    if(freeMints > 0){
      supply = totalSupply();

      for(uint256 i; i < freeMints; i++){
        _safeMint( msg.sender, supply + i );
        _freeMints[msg.sender] -= 1;
      }
    }
  }

  function withdraw() public payable onlyOwner {
    uint256 _p1 = address(this).balance * 7 / 10;
    uint256 _p2 = address(this).balance * 3 / 10;

    require(payable(_v1).send(_p1));
    require(payable(_v2).send(_p2));
  }
}