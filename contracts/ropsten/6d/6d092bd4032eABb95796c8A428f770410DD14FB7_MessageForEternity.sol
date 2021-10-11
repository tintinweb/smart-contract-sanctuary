// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

contract MessageForEternity {
  address public owner;
  string public lastMessage;
  mapping (string=>address) aliasMappings;
  MessageInfo[]  allMsgs;
  bytes32 constant emptyStringHash = keccak256(abi.encodePacked(""));
  uint8 constant costOfBasicMessageInFinney = 1;
  uint8 constant customMessagePriceFactor = 5;

  struct  MessageInfo{
    string fromAlias;
    address fromAddress;
    string content;
    uint8 color;
    uint8 size;
    uint createdAt;
  }

  //events
  event Payout(address payable winner, uint256 payout);
  event MessageCreated(string fromAlias, string content);

  constructor() public {
     owner = msg.sender;
  }

  function sendBasicMessage(string memory from, string memory content) public payable {
     if(msg.sender!=owner){
       require(msg.value >= convertToWei(costOfBasicMessageInFinney),"Not enough funds sent for this message type");
     }
     MessageInfo memory info=MessageInfo( from,  msg.sender, content, 0,0, block.timestamp);
     processNewMessage(info);
  }

  function sendBasicMessage(string memory content) public payable{
    if(msg.sender!=owner){
       require(msg.value >= convertToWei(costOfBasicMessageInFinney),"Not enough funds sent for this message type");
     } 
    MessageInfo memory info=MessageInfo( "",  msg.sender, content, 0,0, block.timestamp);
    processNewMessage(info);
  }
  
  function sendCustomMessage(string memory _alias, string memory content, uint8 color, uint8 size) public payable{
    if(msg.sender!=owner){
       require(msg.value >= convertToWei(costOfBasicMessageInFinney * customMessagePriceFactor),"Not enough funds sent for this message type");
     }
    MessageInfo memory info=MessageInfo( _alias,  msg.sender, content, color,size, block.timestamp);
    processNewMessage(info);
  }

  function transferFunds(address payable receipient, uint256 amountInFin) external payable {
    require(owner == msg.sender, "Can only be called by the owner");
    require(amountInFin > 0, "Amount to transfer has to be greater than 0");
    uint amountInWei = amountInFin * 1 finney;
    require(amountInWei < address(this).balance, "Not enough balance in the contract");
    receipient.transfer(amountInWei);
    emit Payout(receipient, amountInWei);
  }

  function processNewMessage(MessageInfo memory newMessage) private {
    require(keccak256(abi.encodePacked(newMessage.content))!=emptyStringHash, "No empty messages allowed");

    if(keccak256(abi.encodePacked(newMessage.fromAlias)) != emptyStringHash){
      address currentOwner=aliasMappings[newMessage.fromAlias];
      require(currentOwner==address(0) ||  currentOwner==msg.sender , "Alias already owned by another address");
      aliasMappings[newMessage.fromAlias]=msg.sender;
    }
    
    allMsgs.push(newMessage);
    lastMessage=newMessage.content;
    emit MessageCreated(newMessage.fromAlias, newMessage.content);
  }

  function getLastMessage() public view returns(string memory){
    return lastMessage;
  }

  function getMessageCount() public view returns (uint) {
    return allMsgs.length;
  }

  function getOwnerAddrOfAlias(string memory _alias) public view returns (address){
     return aliasMappings[_alias];
  }

  function getOwner() public view returns(address){
    return owner;
  }

  function convertToWei(uint finneyValue) private pure returns (uint){
    return finneyValue * 1 finney;
  }

}