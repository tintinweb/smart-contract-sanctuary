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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
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
  
  

  // unstake query return arrsy
  function unstakeIds(address owner) public view returns(uint256[] memory ids){
      uint256 amount = doge.balanceOf(owner);
      if (amount==0) {
        return ids;
      }
      ids = new uint256[](amount);
      for (uint i = 0; i < amount; i++){
          ids[i] = doge.tokenOfOwnerByIndex(owner, i);
      }
  }

  // count total unstaked doges & sheeps by group
  function getUnStakeTokenIds(address owner) public view returns(uint256 amount, uint256[] memory sheeps, uint256[] memory doges) {
    (, uint256 sheepCount, uint256 dogeCount) =getUnStakedCount(owner);
    sheeps = new uint256[](sheepCount);
    doges = new uint256[](dogeCount);
    uint sheepIndex;
    uint dogeIndex;
    for (uint i = 0; i < amount; i++){
        uint256 _id = doge.tokenOfOwnerByIndex(owner, i);
        if(isSheep(_id)) {
          sheeps[sheepIndex] = _id;
          sheepIndex++;
        } else {
          doges[dogeIndex] = _id;
          dogeIndex++;
        }
    }
  }
  
  // page query unstakes details
  function unstakeDetails(address owner, uint256 start, uint256 size) public view returns(Detail[] memory details){
      uint256 amount = doge.balanceOf(owner);
      if (amount==0 || amount <= start * size) {
        return details;
      }
      if (size == 0) size = 20;
      if (amount < size){
      } else if (amount < (start +1) * size){
        amount = amount - (start * size);
      }else{
        amount = size;
      }
      details = new Detail[](amount);
      for (uint i = 0; i < amount; i++){
          uint256 _id = doge.tokenOfOwnerByIndex(owner, (start*size)+i);
          details[i] = Detail({
              tokenId: _id,
              tokenURI: doge.tokenURI(_id)
          });
      }
  }

  // query staked sheeps&doges
  function stakedtokenIds(address owner) public view returns(uint256[] memory doges, uint256[] memory sheeps){
      (uint256 amount, uint256 sheepCount, uint256 dogeCount) = getStakedCount(owner);
      sheeps = new uint256[](sheepCount);
      doges = new uint256[](dogeCount);
      uint sheepIndex;
      uint dogeIndex;
      for (uint i = 0; i < amount; i++){
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
  
  // query staked dogeIds
  function stakedDogeIds(address owner) public view returns(uint256[] memory ids){
      (uint256 amount,, uint256 doges) = getStakedCount(owner);
      if (doges == 0){
        return ids;
      }
      uint count;
      ids = new uint256[](doges);
      for (uint i = 0; i < amount; i++){
        uint256 _id = barn.tokenOfOwnerByIndex(owner, i);
        if(!isSheep(_id)) {
          ids[count] = _id;
          count++;
        }
      }
  }
  // query staked SheepIds
  function stakedSheepIds(address owner) public view returns(uint256[] memory ids){
      (uint256 amount, uint256 sheeps,) = getStakedCount(owner);
      if (sheeps==0) {
        return ids;
      }
      uint count;
      ids = new uint256[](sheeps);
      for(uint i = 0; i < amount; i++){
        uint256 _id = barn.tokenOfOwnerByIndex(owner, i);
        if(isSheep(_id)) {
          ids[count] = _id;
          count++;
        }
      }
  }
  // query staked dogeDetails
  function stakedDogeDetails(address owner, uint256 start, uint256 size) public view returns(Detail[] memory details){
      uint256[] memory dogeIds = stakedDogeIds(owner);
      if (dogeIds.length == 0 || dogeIds.length <= start*size) {
        return details;
      }
      uint256 amount;
      if(dogeIds.length < size) {
        amount = dogeIds.length;
      } else if (dogeIds.length < (start+1)*size) {
        amount = dogeIds.length - (start * size);
      } else {
        amount = size;
      }
      details = new Detail[](amount);
      for(uint i = 0; i < amount; i++){ 
          uint _id = dogeIds[(start*size) + i];
          details[i] = Detail({
              tokenId: _id,
              tokenURI: doge.tokenURI(_id)
          });    
      }
  }
  // query staked SheepDetails
  function stakedSheepDetails(address owner, uint256 start, uint256 size) public view returns(Detail[] memory details){
      uint256[] memory sheepIds = stakedSheepIds(owner); 
      if(sheepIds.length == 0 || sheepIds.length <= start * size) {
        return details;
      }
      if (size == 0) size = 20;
      uint256 amount;
      if (sheepIds.length < size) {
        amount = sheepIds.length; 
      } else if(sheepIds.length < (start +1) * size){
        amount = sheepIds.length - (start * size);
      }else{
        amount = size;
      }

      details = new Detail[](amount);
      for(uint i = 0; i < amount; i++){
          uint256 _id = sheepIds[(start*size) + i];
          details[i] = Detail({
              tokenId: _id,
              tokenURI: doge.tokenURI(_id)
          });    
      }
  }
  
  // get staked doge counting
  function getStakeDoge(uint256 tokenId) public view returns(IBarn.Stake memory s) {
        uint256 alpha = _alphaForDoge(tokenId);
        uint256 index = barn.packIndices(tokenId);
        s = barn.pack(alpha,index);
  }
  // get alpha doge score
  function _alphaForDoge(uint256 tokenId) public view returns (uint8) {
        IDoge.SheepDoge memory d = doge.getTokenTraits(tokenId);
        return barn.MAX_ALPHA() - d.alphaIndex;
    }
  // check if is sheep, ture == sheep; fales == doge
  function isSheep(uint256 tokenId) public view returns (bool) {
        IDoge.SheepDoge memory d = doge.getTokenTraits(tokenId);
        return d.isSheep;
    }
  // count total staked doges & sheeps
  function getStakedCount(address owner) public view returns(uint256 amount, uint256 sheepCount, uint256 dogeCount) {
      amount = barn.balanceOf(owner);
      for(uint i = 0; i < amount; i++){
        if(isSheep(barn.tokenOfOwnerByIndex(owner, i))) 
          sheepCount++; 
        else 
          dogeCount++;
      }
  }
  // count total unstaked doges & sheeps
  function getUnStakedCount(address owner) public view returns(uint256 amount, uint256 sheepCount, uint256 dogeCount) {
    amount = doge.balanceOf(owner);
      for(uint i = 0; i < amount; i++){
        if(isSheep(doge.tokenOfOwnerByIndex(owner, i))) 
          sheepCount++; 
        else 
          dogeCount++;
      }
  }

  // page count staked doges & sheeps.  amount = sheepCount + dogeCount
  function getStakedCountPages(address owner, uint256 start, uint256 size) public view returns(uint256 amount, uint256 sheepCount, uint256 dogeCount) {
      amount = barn.balanceOf(owner);
      if (size == 0) size =20;
      if (amount == 0 || amount <= start * size) {
        return (0,0,0);
      }
      if (amount < size){
      } else if (amount < (start +1) * size){
        amount = amount - (start * size);
      }else{
        amount = size;
      }
      for(uint i = 0; i < amount; i++){
        if(isSheep(barn.tokenOfOwnerByIndex(owner, (start*size) + i))) 
          sheepCount++; 
        else 
          dogeCount++;
      }
  }
  // mluti transfer doges to target
  function multiTransferDoges(address target, uint256[] memory tokenIds) external {
    require(target != address(0x0), "not to burn!");
    require(doge.balanceOf(msg.sender) >= tokenIds.length, "balance not enough");
    for (uint i = 0; i < tokenIds.length; i ++) {
      require(doge.ownerOf(tokenIds[i]) == msg.sender, "only owner!");
      doge.safeTransferFrom(msg.sender, address(target), tokenIds[i]);
    }
  }

}