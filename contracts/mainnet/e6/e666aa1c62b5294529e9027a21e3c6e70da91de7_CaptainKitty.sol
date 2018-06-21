pragma solidity ^0.4.18;

/* ==================================================================== */
/* Copyright (c) 2018 The Priate Conquest Project.  All rights reserved.
/* 
/* https://www.pirateconquest.com One of the world&#39;s slg games of blockchain 
/*  
/* authors rainy@livestar.com/Jonny.Fu@livestar.com
/*                 
/* ==================================================================== */

contract KittyInterface {
  function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens);
  function ownerOf(uint256 _tokenId) external view returns (address owner);
  function balanceOf(address _owner) public view returns (uint256 count);
}

interface KittyTokenInterface {
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function setTokenPrice(uint256 _tokenId, uint256 _price) external;
  function CreateKittyToken(address _owner,uint256 _price, uint32 _kittyId) public;
}

contract CaptainKitty {
  address owner;
  //event 
  event CreateKitty(uint _count,address _owner);

  KittyInterface kittyContract;
  KittyTokenInterface kittyToken;
  /// @dev Trust contract
  mapping (address => bool) actionContracts;
  mapping (address => uint256) kittyToCount;
  mapping (address => bool) kittyGetOrNot;

  function CaptainKitty() public {
    owner = msg.sender;
  }  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  function setActionContract(address _actionAddr, bool _useful) public onlyOwner {
    actionContracts[_actionAddr] = _useful;
  }

  modifier onlyAccess() {
    require(actionContracts[msg.sender]);
    _;
  }

  function setKittyContractAddress(address _address) external onlyOwner {
    kittyContract = KittyInterface(_address);
  }

  function setKittyTokenAddress(address _address) external onlyOwner {
    kittyToken = KittyTokenInterface(_address);
  }

  function createKitties() external payable {
    uint256 kittycount = kittyContract.balanceOf(msg.sender);
    require(kittyGetOrNot[msg.sender] == false);
    if (kittycount>=99) {
      kittycount=99;
    }
    if (kittycount>0 && kittyToCount[msg.sender]==0) {
      kittyToCount[msg.sender] = kittycount;
      kittyGetOrNot[msg.sender] = true;
      for (uint i=0;i<kittycount;i++) {
        kittyToken.CreateKittyToken(msg.sender,0, 1);
      }
      //event
      CreateKitty(kittycount,msg.sender);
    }
  }

  function getKitties() external view returns(uint256 kittycnt,uint256 captaincnt,bool bGetOrNot) {
    kittycnt = kittyContract.balanceOf(msg.sender);
    captaincnt = kittyToCount[msg.sender];
    bGetOrNot = kittyGetOrNot[msg.sender];
  }

  function getKittyGetOrNot(address _addr) external view returns (bool) {
    return kittyGetOrNot[_addr];
  }

  function getKittyCount(address _addr) external view returns (uint256) {
    return kittyToCount[_addr];
  }

  function birthKitty() external onlyAccess payable {
  }
}