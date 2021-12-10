pragma solidity ^0.8.0;

//SPDX-License-Identifier: UNLICENSED

interface ApeF {
    //...(other functions)
    function ownerOf(uint256 tokenId) external view returns (address owner);
    //...(other functions)
}




contract Rentals {


  //Renting

  mapping (string => address) RentOwner;
  mapping (string => address) Renter;
  mapping (string => bool) RentKey;
  mapping (string => uint256) RentAssetID;
  mapping(string => uint256) RentalCost;
  mapping (string => uint256) RentalLength;
  mapping (string => uint256) RentalEndDate;
  mapping (uint256 => address) AssetAgreement;
  mapping (string => bool) isRented;




address ref;

address _owner;

constructor(){

_owner = msg.sender;

}



function Setparent(address add) public payable{

require(msg.sender == _owner, "Must be owner");

ref = add;

}

function CreateRentalAgreement(string calldata Key, uint256 assetID, uint256 termlength, uint256 cost)public payable{

require(RentKey[Key] != true, "Rental Key already in use"); //prevent duplicate keys
//require(ownerOf(assetID) == msg.sender, "Invalid Asset"); // check asset ownership


//require(ref.call(abi.encode("ownerOf(uint256)"), assetID) == msg.sender, "Invalid Asset");

require(ApeF(ref).ownerOf(assetID) == msg.sender, "Invalid Asset" );

require(ApeF(ref).ownerOf(assetID) != AssetAgreement[assetID], "Asset Already has an agreement" );


//(bool success, bytes memory returnData) = address(ref).call(abi.encodeWithSignature("ownerOf(uint256)", assetID));
//require(r != AssetAgreement[assetID], "Invalid Asset");

//require(AssetAgreement[assetID] != ownerOf(assetID), "Asset Already has an agreement"); // check only one agreement exist for owner


AssetAgreement[assetID] = msg.sender;
RentKey[Key] = true;
RentAssetID[Key] = assetID;
RentalLength[Key] = termlength;
RentOwner[Key] = msg.sender;
RentalCost[Key] = cost;
isRented[Key] = false;

}



function RentAsset(string calldata key) public payable{

require(msg.value >= RentalCost[key], "Insufficient amount sent");
require(isRented[key] == false, "Already being rented");
//require(ownerOf(RentAssetID[key]) == RentOwner[key], "Invalid owner");
//require(ref.call(bytes4(keccak256("ownerOf(uint256)")), RentAssetID[key]) == RentOwner[key], "Invalid owner");

require(ApeF(ref).ownerOf(RentAssetID[key]) == RentOwner[key], "Invalid owner" );


Renter[key] = msg.sender;
isRented[key] = true;
RentalEndDate[key] = block.timestamp + RentalLength[key];

}



function EndRental(string memory key) public payable{

require(msg.sender == RentOwner[key], "Must be owner");
require(isRented[key] == true, "Asset is not being rented");
require(block.timestamp >= RentalEndDate[key], "Rental term has not ended");

isRented[key] = false;



}
}