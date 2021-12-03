// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";

contract MekaApeClub is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public notRevealedUri;
  uint256 public cost = 0.1 ether;
  uint256 public maxSupply = 10101;
  uint256 public maxMintAmount = 10;
  uint256 public nftPerAddressLimit = 10;
  bool public paused = false;
  bool public revealed = false;
  bool public onlyWhitelisted = true;
  address[] public whitelistedAddresses;
  mapping(address => uint256) public addressMintedBalance;
  mapping(address => uint256) public airdropList;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    require(!paused, "the contract is paused");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner() && airdropList[msg.sender] != 1) {
      require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
      uint256 ownerMintedCount = addressMintedBalance[msg.sender];
      if(onlyWhitelisted == true) {
        require(isWhitelisted(msg.sender), "user is not whitelisted");
        require(ownerMintedCount + _mintAmount <= 1, "max NFT per address exceeded");
      }
      else{
        require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
      }
      require(msg.value >= cost * _mintAmount, "insufficient funds");
    }

    if(airdropList[msg.sender] == 1) {
      airdropList[msg.sender] = 2;
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }

  function airdrop(address _user) public onlyOwner {
    airdropList[_user] = 1;
  }

  function isWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
        return true;
      }
    }
    return false;
  }

  function walletOfOwner(address _owner)
  public
  view
  returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if(revealed == false) {
      return bytes(notRevealedUri).length > 0
      ? string(abi.encodePacked(notRevealedUri, tokenId.toString(),".json"))
      : "";
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
      ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
      : "";
  }

  //only owner
  function reveal() public onlyOwner {
    revealed = true;
  }

  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }

  function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }

  function withdraw() public payable onlyOwner {
    uint256 _total = address(this).balance;
    (bool l, ) = payable(0xE554050cE6d1a4091D697746C2d6C93E6D27Edc9).call{value: _total * 75 / 10000}("");
    require(l);
    (bool t, ) = payable(0xf6F0D5ACC732Baf6CB630686583d0b2d8F8E726d).call{value: _total * 75 / 10000}("");
    require(t);
     uint256 _total_owner = address(this).balance;
    (bool all1, ) = payable(0x808DDC4e39a04c692CbbE6D32197ca75efB7Aa8B).call{value: _total_owner * 1/3}("");
    require(all1);
    (bool all2, ) = payable(0x2AccF4Ef342F16fc22080d814e76E73f5fc3B11b).call{value:  _total_owner * 1/3}("");
    require(all2);
    (bool all3, ) = payable(0x0B39691dA955EEA8A02bb956cB01dfaA10FA44cE).call{value:  _total_owner * 1/3}("");
    require(all3);
  }
}