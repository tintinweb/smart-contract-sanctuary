pragma solidity ^0.8.0;

//SPDX-License-Identifier: UNLICENSED

interface ApeR {
    //...(other functions)
    function ownerOf(uint256 tokenId) external view returns (address owner);
    //...(other functions)
}



contract Attachments{



address _owner;
  //attachments
  mapping(uint256 => bool) public isAttached; //asset to bool
  mapping(uint256 => uint256) public assetToApeID; //asset id to attached ape
  mapping(uint256 => uint256 [] ) public apeAttachments; //Log of ape attachments
  uint256 [] reset;

  address ref;







constructor(){


  _owner = msg.sender;

}




function getisAttached(uint256 id) public view returns(bool success){

return isAttached[id];


}


function getAttachements(uint256 id)public view returns(uint256[] memory list){

return apeAttachments[id];


}



  function setparent(address add) public {

require(_owner == msg.sender, "Must be owner");

ref = add;



  }


  function attachAsset(uint256 asset, uint256 ape)public{

    require(ApeR(ref).ownerOf(asset)==msg.sender, "Must be owner of asset");
    require(ApeR(ref).ownerOf(ape) == msg.sender, "Must be owner of Ape");

    isAttached[asset] = true;
    assetToApeID[asset] = ape;
    apeAttachments[ape].push(asset);



  }



  function removeAsset(uint256 asset, uint256 ape)public{

    require(ApeR(ref).ownerOf(asset)==msg.sender, "Must be owner of asset");
    require(ApeR(ref).ownerOf(ape) == msg.sender, "Must be owner of Ape");

    isAttached[asset] = false;
    assetToApeID[asset] = asset;
    uint256 [] storage temp = apeAttachments[ape];

    apeAttachments[ape] = reset;

    for(uint256 x=0; x<temp.length; x++){

if(temp[x] != asset){
      apeAttachments[ape].push(temp[x]);
}

    }




  }


}