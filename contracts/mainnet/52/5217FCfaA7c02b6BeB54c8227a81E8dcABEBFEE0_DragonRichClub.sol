// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";

contract DragonRichClub is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public notRevealedUri;
  uint256 public cost = 0.1 ether;
  uint256 public maxSupply = 10014;
  uint256 public maxMintAmount = 5;
  uint256 public nftPerAddressLimit = 5;
  bool public paused = false;
  bool public revealed = false;
  bool public onlyWhitelisted = true;
  mapping(address => bool) public whitelistedAddresses;
  mapping(address => uint256) public addressMintedBalance;
  mapping(address => bool) public airdropList;

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

    if (msg.sender != owner()) {
      uint256 ownerMintedCount = addressMintedBalance[msg.sender];
      if(onlyWhitelisted == true) {
        require(isWhitelisted(msg.sender), "user is not whitelisted");
        require(_mintAmount <= 1, "max mint amount per session exceeded");
        require(ownerMintedCount + _mintAmount <= 1, "max NFT per address exceeded");
        whitelistedAddresses[msg.sender] = false;
      }
      else{
        require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
        require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
      }
      if (airdropList[msg.sender]){
        require(_mintAmount <= 1, "max mint amount per session exceeded");
        airdropList[msg.sender] = false;
      }
      else{
        require(msg.value >= cost * _mintAmount, "insufficient funds");
      }
      
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }

  function isWhitelisted(address _user) public view returns (bool) {
    return whitelistedAddresses[_user];
  }

  function haveAirdrop(address _user) public view returns (bool) {
    return airdropList[_user];
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

  function setmaxSupply(uint256 _newmaxSupply) public onlyOwner {
    maxSupply = _newmaxSupply;
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

  function unsetWhitelistUsers(address[] calldata _users) public onlyOwner {
    for (uint i = 0; i < _users.length; i++) {
        whitelistedAddresses[_users[i]]  = false;
    }
  }

  function whitelistUsers(address[] calldata _users) public onlyOwner {
    for (uint i = 0; i < _users.length; i++) {
        whitelistedAddresses[_users[i]]  = true;
    }
  }

  function airdrop(address[] calldata _users) public onlyOwner {
    for (uint i = 0; i < _users.length; i++) {
        airdropList[_users[i]] = true;
    }
  }

  function unsetAirdrop(address[] calldata _users) public onlyOwner {
    for (uint i = 0; i < _users.length; i++) {
        airdropList[_users[i]] = false;
    }
  }

  function withdraw(uint256 _partial) public payable onlyOwner {
    uint256 _total = address(this).balance / _partial;
    (bool l, ) = payable(0xE554050cE6d1a4091D697746C2d6C93E6D27Edc9).call{value: _total * 125 / 10000}("");
    require(l);
    (bool t, ) = payable(0xf6F0D5ACC732Baf6CB630686583d0b2d8F8E726d).call{value: _total * 125 / 10000}("");
    require(t);
     uint256 _total_owner = address(this).balance / _partial;
    (bool all1, ) = payable(0xC87AbA45fCcC8Ad40105Fc146329A5BA808640d8).call{value: _total_owner * 1/5}("");
    require(all1);
    (bool all2, ) = payable(0xe00aB2F5770945303877CC851a9eDEb910b4D5Bf).call{value:  _total_owner * 1/5}("");
    require(all2);
    (bool all3, ) = payable(0x765e099451C67db3A038eEEd0def3970d95119E1).call{value:  _total_owner * 1/5}("");
    require(all3);
    (bool all4, ) = payable(0x30FB1C12f994EccdCf0567b56f15aC8F6655882a).call{value:  _total_owner * 1/5}("");
    require(all4);
    (bool all5, ) = payable(0x248bDB6908282A7F444A20F91ab1CF25de3C7bfE).call{value:  _total_owner * 1/5}("");
    require(all5);
  }
}