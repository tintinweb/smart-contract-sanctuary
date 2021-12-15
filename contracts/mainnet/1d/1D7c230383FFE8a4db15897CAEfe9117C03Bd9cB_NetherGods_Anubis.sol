pragma solidity ^0.8.7;

import './ERC721Enumerable.sol';
import './Ownable.sol';

/**
 * NETHERGODS
 * WELCOME TO THE NETHER
 * ANUBIS WILL BE YOUR GUIDE
 */

contract NetherGods_Anubis is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public _baseTokenURI;
  uint256 public _totalSupply;

  bool public _active = false;
  bool public _presaleActive = false;

  uint256 public _price = 0.04 ether;
  uint256 public _presale_price = 0.03 ether;

  uint256 public constant _MINT_LIMIT = 20;
  uint256 public constant _PRESALE_MINT_LIMIT = 5;
  uint256 public constant _SUPPLY = 9999;
  uint256 public constant _PRESALE_SUPPLY = 2000;

  mapping(address => bool) private _whitelist;
  mapping(address => uint256) private _mints;

  address public _v = 0x7567123904C5F698aa985188C0090FFc28117eD0;

  constructor() ERC721("NetherGods_Anubis", "Anubis") {}

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

  function setPresalePrice(uint256 price) public onlyOwner {
    _presale_price = price;
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

  function getMints(address owner) public view returns (uint256){
    require(owner != address(0), "Null denied");

    return _mints[owner];
  }

  function ownerMint(uint256 _amount) public payable onlyOwner {
    require( _totalSupply + _amount <= _SUPPLY, "Supply denied");

    for(uint256 i; i < _amount; i++){
      _safeMint( msg.sender, _totalSupply + 1 + i );
    }
    _totalSupply += _amount;
  }

  function mint(uint256 _amount) public payable {
    require( _active, "Not active");
    require( _amount <= _MINT_LIMIT, "Amount denied");
    require( _totalSupply + _amount <= _SUPPLY, "Supply denied");
    require(msg.value == _price * _amount, "Incorrect ether amount");

    for(uint256 i; i < _amount; i++){
      _safeMint( msg.sender, _totalSupply + 1 + i );
      _mints[msg.sender] += 1;
    }
    _totalSupply += _amount;
  }

  function presale(uint256 _amount) public payable {
    require( _presaleActive, "Not active");
    require( _whitelist[msg.sender], "Address denied");
    require( _amount + _mints[msg.sender] <= _PRESALE_MINT_LIMIT, "Amount denied");
    require( _totalSupply + _amount <= _PRESALE_SUPPLY, "Supply denied");
    require(msg.value == _presale_price * _amount, "Incorrect ether amount");

    for(uint256 i; i < _amount; i++){
      _safeMint( msg.sender, _totalSupply + 1 + i );
      _mints[msg.sender] += 1;
    }
    _totalSupply += _amount;
  }

  function withdraw() public payable onlyOwner {
    uint256 _p = address(this).balance;

    require(payable(_v).send(_p));
  }

  function send(address[] memory _wallets) public onlyOwner{
      require(_totalSupply + _wallets.length <= _SUPPLY, "not enough tokens left");
      for(uint i; i < _wallets.length; i++)
          _safeMint(_wallets[i], _totalSupply + 1 + i);
      _totalSupply += _wallets.length;
  }
}