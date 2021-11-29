// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IDoge {
    // struct to store each token's traits
    struct SheepDoge {
        bool isSheep;
        uint8 fur;
        uint8 head;
        uint8 ears;
        uint8 eyes;
        uint8 nose;
        uint8 mouth;
        uint8 neck;
        uint8 feet;
        uint8 alphaIndex;
    }
    function getTokenTraits(uint256 tokenId) external view returns (SheepDoge memory);
    function ownerOf(uint256 tokenId) external view returns(address);
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns(uint256);
    function tokenURI(uint256 tokenId) external view returns(string memory);
}

interface IBarn {
    // struct to store sheep staked
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }
    
    function balanceOf(address owner) external view returns(uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns(uint256);
    function tokenURI(uint256 tokenId) external view returns(string memory);
    
    function MAXIMUM_GLOBAL_WOOL() external view returns (uint256);
    function DAILY_WOOL_RATE() external view returns (uint256);
    function lastClaimTimestamp() external view returns (uint256);
    function totalWoolEarned() external view returns (uint256);
    function barn(uint256) external view returns (Stake memory);

    function MAX_ALPHA() external view returns (uint8);
    function woolPerAlpha() external view returns (uint256);
    function pack(uint256, uint256) external view returns (Stake memory);
    function packIndices(uint256) external view returns (uint256);
}

/**
 *  use with multicall, get all details
 *  submit on 2021-11-27
 */
contract DogeApi{
  struct Detail {
        uint256 tokenId;
        string tokenURI;
  }
  IBarn public barn;
  IDoge public doge;

  constructor(address _doge,address _barn) {
      doge = IDoge(_doge);
      barn = IBarn(_barn);
  }
  
  function unstakeIds(address owner) public view returns(uint256[] memory ids){
      uint256 amount = doge.balanceOf(owner);
      if(amount==0) {
        return ids;
      }
      ids = new uint256[](amount);
      for(uint i = 0; i < amount; i++){
          ids[i] = doge.tokenOfOwnerByIndex(owner, i);
      }
  }

  function stakedIds(address owner) public view returns(uint256[] memory doges, uint256[] memory sheeps){
      uint256 amount = barn.balanceOf(owner);
      if(amount==0) {
        return (doges, sheeps);
      }
      uint dogeCount;
      uint sheepCount;
      for(uint i = 0; i < amount; i++){
        if(isSheep(barn.tokenOfOwnerByIndex(owner, i))) 
          sheepCount++; 
        else 
          dogeCount++;
      }
      sheeps = new uint256[](sheepCount);
      doges = new uint256[](dogeCount);
      uint sheepIndex;
      uint dogeIndex;
      for(uint i = 0; i < amount; i++){
          uint256 _id = barn.tokenOfOwnerByIndex(owner, i);
          if(isSheep(_id)) {
            sheeps[sheepIndex] = _id;
            sheepIndex++;
          } else {
            doges[dogeIndex] = _id;
            dogeIndex++;
          }
      }
  }


  function unstakeURIs(address owner) public view returns(string[] memory tokenURIs){
      uint256 amount = doge.balanceOf(owner);
      if(amount==0) {
        return tokenURIs;
      }
      tokenURIs = new string[](amount);
      for(uint i = 0; i < amount; i++){
          uint256 _id = doge.tokenOfOwnerByIndex(owner, i);
          tokenURIs[i] = doge.tokenURI(_id);
      }
  }
  function stakedtokenURIs(address owner) public view returns(string[] memory tokenURIs){
      uint256 amount = barn.balanceOf(owner);
      if(amount==0) {
        return tokenURIs;
      }
      tokenURIs = new string[](amount);
      for(uint i = 0; i < amount; i++){
          uint256 _id = barn.tokenOfOwnerByIndex(owner, i);
          tokenURIs[i] = doge.tokenURI(_id);
      }
  }

  function unstakeDetails(address owner) public view returns(Detail[] memory details){
      uint256 amount = doge.balanceOf(owner);
      if(amount==0) {
        return details;
      }
      details = new Detail[](amount);
      for(uint i = 0; i < amount; i++){
          uint256 _id = doge.tokenOfOwnerByIndex(owner, i);
          details[i] = Detail({
              tokenId: _id,
              tokenURI: doge.tokenURI(_id)
          });
      }
  }

  function stakedDoges(address owner) public view returns(uint256[] memory ids){
      uint256 amount = barn.balanceOf(owner);
      if(amount==0) {
        return ids;
      }
      ids = new uint256[](amount);
      for(uint i = 0; i < amount; i++){
        uint256 _id = barn.tokenOfOwnerByIndex(owner, i);
        if(!isSheep(_id)) ids[i] = _id;
      }
  }

  function stakedSheeps(address owner) public view returns(uint256[] memory ids){
      uint256 amount = barn.balanceOf(owner);
      if(amount==0) {
        return ids;
      }
      ids = new uint256[](amount);
      for(uint i = 0; i < amount; i++){
        uint256 _id = barn.tokenOfOwnerByIndex(owner, i);
        if(isSheep(_id)) ids[i] = _id;
      }
  }

  
  
  function stakedDogeDetails(address owner) public view returns(Detail[] memory details){
      uint256 amount = barn.balanceOf(owner);
      if(amount==0) {
        return details;
      }
      details = new Detail[](amount);
      for(uint i = 0; i < amount; i++){
          uint256 _id = barn.tokenOfOwnerByIndex(owner, i);
          if (!isSheep(_id)){
              details[i] = Detail({
                  tokenId: _id,
                  tokenURI: doge.tokenURI(_id)
              });    
          }
      }
  }
  
  function stakedSheepDetails(address owner) public view returns(Detail[] memory details){
      uint256 amount = barn.balanceOf(owner);
      if(amount==0) {
        return details;
      }
      details = new Detail[](amount);

      for(uint i = 0; i < amount; i++){
          uint256 _id = barn.tokenOfOwnerByIndex(owner, i);
          if (isSheep(_id)){
              details[i] = Detail({
                  tokenId: _id,
                  tokenURI: doge.tokenURI(_id)
              });    
          }
      }
  }
  
  function getStakeDoge(uint256 tokenId) public view returns(IBarn.Stake memory s) {
        uint256 alpha = _alphaForDoge(tokenId);
        uint256 index = barn.packIndices(tokenId);
        s = barn.pack(alpha,index);
  }
  
  function _alphaForDoge(uint256 tokenId) public view returns (uint8) {
        IDoge.SheepDoge memory d = doge.getTokenTraits(tokenId);
        return barn.MAX_ALPHA() - d.alphaIndex;
    }

  function isSheep(uint256 tokenId) public view returns (bool) {
        IDoge.SheepDoge memory d = doge.getTokenTraits(tokenId);
        return d.isSheep;
    }
}