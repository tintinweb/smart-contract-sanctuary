// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract AshesOfLight is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public notRevealedUri;
  uint256 public cost = 0.08 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmount = 20;
  uint256 public nftPerAddressLimit = 1;
  uint256 public rewardAmountTotal = 50;
  uint256 public rewardsMinted = 0;
  bool public paused = true;
  bool public revealed = true;
  bool public onlyWhitelisted = true;
  address[] public whitelistedAddresses;
  address[] public rewardAddresses;
  mapping(address => uint256) public addressMintedBalance;
  address public ms;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri,
    address _msAddress
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    setMS(_msAddress);
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
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    require(supply + _mintAmount <= maxSupply - rewardAmountTotal, "max NFT limit exceeded");

    if (msg.sender != owner()) {
        if(onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "user is not whitelisted");
        }
        require(msg.value >= cost * _mintAmount, "insufficient funds");
        
        for (uint256 i = 1; i <= _mintAmount; i++) {
        addressMintedBalance[msg.sender]++;
          _safeMint(msg.sender, supply + i);
        }
    }
    if (msg.sender == owner()) {
      for (uint256 i = 1; i <= _mintAmount; i++) {
        addressMintedBalance[msg.sender]++;
        _safeMint(msg.sender, supply + i);
      }
    }
  }
  
  function claimReward() public payable {
      uint256 rewardAmount = 1;
      require(!paused, "the contract is paused");
        require(
            hasReward(msg.sender),
            "No rewards to claim for your account"
        );
        uint256 supply = totalSupply();
        require(supply + rewardAmount <= maxSupply - rewardAmountTotal, "max NFT limit exceeded");

        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(
            ownerMintedCount + rewardAmount <= nftPerAddressLimit,
            "max NFT per address exceeded"
        );
        for (uint256 i = 1; i <= rewardAmount; i++) {
            addressMintedBalance[msg.sender]++;
            rewardsMinted++;
            rewardAmountTotal--;
            _safeMint(msg.sender, supply + i);
        }
  }
  
  function mintTo(address _to, uint256 _mintAmount) public payable onlyOwner {
        uint256 supply = totalSupply();
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(supply + _mintAmount <= maxSupply - rewardAmountTotal);
    
        for (uint256 i = 1; i <= _mintAmount; i++) {
          _safeMint(_to, supply + i);
        }
      }
  
  function isWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }
  
    function hasReward(address _user) public view returns (bool) {
        for (uint256 i = 0; i < rewardAddresses.length; i++) {
            if (rewardAddresses[i] == _user) {
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
        return notRevealedUri;
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

  function setMS(address _newMS) public onlyOwner {
    ms = _newMS;
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
  
    function rewardUsers(address[] calldata _users) public onlyOwner {
        delete rewardAddresses;
        rewardAddresses = _users;
    }
 
  function withdraw() public payable onlyOwner {
      
    (bool hs, ) = payable(ms).call{value: address(this).balance * 10 / 100}("");
    require(hs);

    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}