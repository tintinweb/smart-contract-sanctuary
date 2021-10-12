/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PrivateMessaging{
    
    struct Profile{
        
        address Account;
        string Name;
        uint256 Age;
        uint256 NumberOfLikes;
        uint256 NumberOfMessagesSent;
        uint256 NumberOfMessagesReceived;
        
    }
    
    mapping(address => Profile) Accounts;
    
    mapping(address => mapping(address => string)) private messages;
    
    mapping(address => mapping(address => bool)) LikesLimiter;
    
    
    mapping(address => mapping(bytes32 => string)) private Keys;
    
    string[] private PublicChat;
    
    function CreateProfile(string memory name, uint256 age) public {
        
        Accounts[msg.sender].Name = name;
        Accounts[msg.sender].Age = age;
        Accounts[msg.sender].Account = msg.sender;
        
    }
    
    function ViewProfile(address account) public view returns(address , string memory, uint256 , uint256 ,uint256 ,uint256){
        
        address AccountOf = Accounts[account].Account;
        string memory Name = Accounts[account].Name;
        uint256 Age = Accounts[account].Age;
        uint256 NumberOfLikesRecevied = Accounts[account].NumberOfLikes;
        uint256 NumberOfMessagesSent = Accounts[account].NumberOfMessagesSent;
        uint256 NumberOfMessagesReceived = Accounts[account].NumberOfMessagesReceived;
        return(AccountOf,Name,Age,NumberOfLikesRecevied,NumberOfMessagesSent,NumberOfMessagesReceived);
      
        
    }
    
    function SendText(string memory Text,address To) public  returns(bool){
        
        messages[msg.sender][To] = Text;
        Accounts[msg.sender].NumberOfMessagesSent += 1;
        Accounts[To].NumberOfMessagesReceived += 1;
        return(true);
    }
    
    function ReadText(address From) public view returns(string memory){
        
        return(messages[From][msg.sender]);
        
    }
    
    function LikeText(address From) public {
        
        uint256 TextLength = bytes(messages[From][msg.sender]).length;
        require(TextLength >= 1,"No messages found");
        require(!LikesLimiter[msg.sender][From],"Already Liked");
        Accounts[From].NumberOfLikes += 1;
        LikesLimiter[msg.sender][From] = true;
    }
    

    function SendAPublicText(string memory text) public {
        
        PublicChat.push(text);
        
    }
    
    function ReadPublicChat() public view returns(string memory){
        
        return(PublicChat[PublicChat.length - 1]);
        
    } 
    
    function ReadPublicChatWithIndex(uint256 index) public view returns(string memory){
        
        require(PublicChat.length - 1 >= index,"Out of index message");
        return(PublicChat[index]);
    }
    

    function WriteEncryptedText(string memory Text, uint256 Passward) public returns(bool){
        bytes32 encodedbytes = keccak256(abi.encodePacked(Passward));
        Keys[msg.sender][encodedbytes] = Text;
        return(true);
        
    }
    
    function ReadEncryptedTextWithPassward(address from, uint256 Passward) public view returns(string memory){
        
        bytes32 EncodedPassward = keccak256(abi.encodePacked(Passward));
        return(Keys[from][EncodedPassward]);
        
    }
    
    function NumberOfLikesOfAccount(address account) public view returns(uint256){
        return(Accounts[account].NumberOfLikes);
    }
    
    function NumberOfMessagesSendByAccount(address account) public view returns(uint256){
        return(Accounts[account].NumberOfMessagesSent);
    }
    
    function NumberOfMessagesReceivedByAccount(address account) public view returns(uint256){
        return(Accounts[account].NumberOfMessagesReceived);
    }
}