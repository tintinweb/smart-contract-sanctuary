// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721.sol";

import "./Strings.sol"; 



 contract FlokiSteroid is ERC721 {

     string tokenName;
     string tokenAcronym;
     uint TOTAL_SUPPLY;
     uint MAX_PER_WALLET;
     string TOKEN_BASE_URI;
     Group[] groups;
     address payable mintFeeCollector;
     address[] delegates;


     constructor(string memory nameOfToken , string memory AcronymOfToken, address firstDelegate , address payable mintFeeCollectorAddress, uint totalSupply, uint maxWallet) ERC721(nameOfToken, AcronymOfToken){
         tokenName =  nameOfToken;
         tokenAcronym = AcronymOfToken;
         addNewGroup(0, "Trenfloki", 300, 0, 0.07 ether );
         addNewGroup(1, "Clenfloki", 600, 300, 0.05 ether );
         addNewGroup(2, "Zyzzfloki", 200, 900, 0.1 ether );
         addNewGroup(3, "Arnoldfloki", 200, 1100, 0.1 ether);
         addNewGroup(4, "DbolFloki", 600, 1300, 0.05 ether);
         addNewGroup(5, "OlympiaFloki", 100, 1900, 0.2 ether);
         delegates.push(firstDelegate);
         mintFeeCollector = mintFeeCollectorAddress;
         TOTAL_SUPPLY = totalSupply;
         MAX_PER_WALLET = maxWallet;
     }


    struct Group{
    uint totalMinted;
    uint groupId;
    uint totalSupply;
    uint startTokenId;
    string groupName;
    uint price;
}


function addNewGroup(uint groupId, string memory groupName, uint totalSupply, uint startTokenId, uint price ) private {
     Group memory newGroup = Group(0, groupId, totalSupply, startTokenId, groupName, price );
     groups.push(newGroup);
} 


function getGroup(uint groupId) public view  returns(Group memory){

 Group memory groupData =  groups[groupId];

 return groupData;

}

function setBaseTokenURI (string memory tokenBaseURI) public{

bool isDelegate =  false;

for (uint i=0; i < delegates.length; i++){

    if(delegates[i] == msg.sender){
        isDelegate = true;
    }
}

require(isDelegate == true, "Not Authorized for this");

     TOKEN_BASE_URI =  tokenBaseURI;

}



function getTokenGroup(uint tokenId) public view returns(uint){

    require(_exists(tokenId),  "Token Does not Exist");

    uint tokenGroup;
    for(uint i = 0; i < groups.length; i++){
        Group memory groupData = groups[i];
        uint groupStartToken = groupData.startTokenId;
        uint groupLastToken = groupStartToken + groupData.totalSupply;
        if(tokenId >= groupStartToken && tokenId < groupLastToken ){
            tokenGroup = i;
        }
    }

    return tokenGroup;
}


function addToDelegates(address newDelegate) public {
    bool isAddressAlreadyaDelegate =  false;
    bool isSenderADelegate =  false;
    for(uint32 i=0; i < delegates.length; i++){
        if(delegates[i] == newDelegate ){
            isAddressAlreadyaDelegate = true;
        }

        if(delegates[i] == msg.sender){
            isSenderADelegate =  true;
        }
    }

    require(isAddressAlreadyaDelegate == false, "Address is Already a Delegate");
    require(isSenderADelegate == true, "No Authorization");

    delegates.push(newDelegate);
}

function RemoveDelegate(address addressToRemove) public {
       bool isSenderADelegate =  false;
        bool isAddressAlreadyaDelegate =  false;
       for(uint32 i=0; i < delegates.length; i++){
           if(delegates[i] == addressToRemove ){
            isAddressAlreadyaDelegate = true;
        }
        if(delegates[i] == msg.sender){
            isSenderADelegate =  true;
        }
    }

    require(isSenderADelegate == true, "No Authorization");

    require(isAddressAlreadyaDelegate == true , "Address was never a Delegate");

    address[] memory newDelegateList =  new address[](delegates.length -1);
     
    uint delegateListIndexer = 0;
    for(uint i = 0; i < delegates.length; i++ ){
        
        if(delegates[i] != addressToRemove){
        newDelegateList[delegateListIndexer] = delegates[i];
        }
        delegateListIndexer++;
    }
    
    delegates = newDelegateList;
}


function ChangeMaxPerWallet(uint newMax) public {
    bool isSenderADelegate =  false;
    for(uint i=0; i < delegates.length; i++){


     if(delegates[i] == msg.sender){
            isSenderADelegate =  true;
        }
    }
    require(isSenderADelegate == true, "Not Authorized to do this" );

    MAX_PER_WALLET = newMax;  
}

function ChangeGroupPrice(uint newPrice, uint groupId) public {
    bool isSenderADelegate =  false;

    for(uint i=0; i < delegates.length; i++){


     if(delegates[i] == msg.sender){
            isSenderADelegate =  true;
        }
    }
    require(isSenderADelegate == true, "Not Authorized to do this" );
    require(groupId < groups.length, "Group does not exist");

    Group memory groupData = groups[groupId];

    groupData.price = newPrice;

    groups[groupId] = groupData;
}


function MintToken(uint groupId, uint quantity) public payable {
        Group memory groupData = getGroup(groupId);
        require(msg.value >= groupData.price * quantity , "Not Enough BNB Sent " );
        require(balanceOf(msg.sender) + quantity <= MAX_PER_WALLET, "Exceeded Wallet Balance" );
         require( groupId >= 0 && groupId < groups.length, "Sorry Wrong Group Id" );
         require((groupData.totalMinted + quantity) <= groupData.totalSupply, "Sorry You can't mint more than a Group's Supply");
         for(uint i= 0; i < quantity; i++) {
        _mint(msg.sender, groupData.startTokenId + groupData.totalMinted++);
         }  
         groups[groupId] = groupData;
         mintFeeCollector.transfer(msg.value);
     }

     function TransferMintFeeCollectorRight(address payable newMintFeeCollector) public  {
     require(mintFeeCollector == newMintFeeCollector, "You're not the current MintFee Collector");
        mintFeeCollector =  newMintFeeCollector;
 } 

 
 function tokenURI(uint tokenId) public view override returns( string memory ){
    require(_exists(tokenId), "Token does not exist");
    return string(abi.encodePacked(TOKEN_BASE_URI, Strings.toString(tokenId)));
  }


 }