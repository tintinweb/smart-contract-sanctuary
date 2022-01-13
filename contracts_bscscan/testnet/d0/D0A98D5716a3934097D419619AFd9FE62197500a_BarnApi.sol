// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IBarn {
    function barn(uint256 tokenId) external view returns (uint16, uint80, address);
    function pack(uint256 tokenId, uint256 i) external view returns (uint16, uint80, address);
    function getWolfOwner(uint256 tokenId) external view returns (address);
    function packIndices(uint256 tokenId) external view returns (uint256);
    function totalWoolEarned() external view returns (uint256);
    function MAXIMUM_GLOBAL_WOOL() external view returns (uint256);
    function DAILY_WOOL_RATE() external view returns (uint256);
    function lastClaimTimestamp() external view returns (uint256);
    function WOOL_CLAIM_TAX_PERCENTAGE() external view returns (uint256);
    function woolPerAlpha() external view returns (uint256);
    function MAX_ALPHA() external view returns (uint8);
    function tokenOfOwnerByIndex(address user, uint256 i) external view returns (uint256);
    function balanceOf(address user) external view returns (uint256);

    function isSheep(uint256 tokenId) external view returns (bool sheep);
}

interface IWoolf {
    struct SheepWolf {
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
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address user) external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (SheepWolf memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function tokenOfOwnerByIndex(address user, uint256 i) external view returns (uint256);
}


contract BarnApi {
  IWoolf public woolf ;
  constructor(address woolf_){
    woolf= IWoolf(woolf_);
  }
  function getUserWoolfIds(address user) public view returns(uint256[] memory list) {
    uint256 num = woolf.balanceOf(user);
    list = new uint256[](num);
    for (uint256 i = 0; i < num; i++) {
      list[i] = woolf.tokenOfOwnerByIndex(user, i);
    }
  }

  function getWoolfInfo(uint256[] calldata ids) public view returns(IWoolf.SheepWolf[] memory list) {
    list = new IWoolf.SheepWolf[](ids.length);
    for (uint256 i = 0; i < ids.length; i++) {
      list[i] = woolf.getTokenTraits(ids[i]);
    }
  }

  function getWoolfURI(uint256[] calldata ids) public view returns(string[] memory list) {
    list = new string[](ids.length);
    for (uint256 i = 0; i < ids.length; i++) {
      list[i] = woolf.tokenURI(ids[i]);
    }
  }

  // function getUserBarnWoolfIds(IBarn barn, address user) public view returns(uint256[] memory list) {
  //   uint256 num = barn.balanceOf(user);
  //   list = new uint256[](num);
  //   for (uint256 i = 0; i < num; i++) {
  //     list[i] = barn.tokenOfOwnerByIndex(user, i);
  //   }
  // }
  function getUserIds(IBarn barn, address user) public view returns(string memory  sheepList,string memory wolfList) {
    uint256 num = woolf.balanceOf(address(barn));
    uint256[] memory list = new uint256[](num);
    for (uint256 i = 0; i < num; i++) {
      list[i] = woolf.tokenOfOwnerByIndex(address(barn), i);
      (address tokenOwner ,bool isSheep)=getTokenInfo(barn,list[i]);
        if(isSheep && tokenOwner==user){
          sheepList=strConcat(sheepList , ",");
          sheepList=strConcat(sheepList , toString(list[i]));
        }
         if(!isSheep && tokenOwner==user){
           wolfList=strConcat(wolfList , ",");
          wolfList=strConcat(wolfList , toString(list[i]));
        }
    }
  }
    function getTokenInfo(IBarn barn, uint256 tokenId) public view returns(address tokenOwner ,bool isSheep ) {
      isSheep =barn.isSheep(tokenId);
      if(isSheep){
	     (,, tokenOwner)=barn.barn(tokenId);
	    }else{
	     tokenOwner=barn.getWolfOwner(tokenId);
	    }
  }
   function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    function strConcat(string memory _a, string memory _b) internal pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length );
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++)bret[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
   }  
}