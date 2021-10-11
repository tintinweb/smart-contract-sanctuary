/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PrivateMessaging{
    
    mapping(address => mapping(address => string)) private messages;
    
    mapping(address => mapping(bytes32 => string)) private Keys;
    
    string[] public PublicChat;
    
    
    function SendText(string memory Text,address To) public  returns(bool){
        
        messages[msg.sender][To] = Text;
        
        return(true);
    }
    
    function ReadText(address From) public view returns(string memory){
        
        return(messages[From][msg.sender]);
        
    }
    
    function SendAPublicText(string memory text) public {
        
        PublicChat.push(text);
        
    }
    
    function ReadPublicChat() public view returns(string memory){
        
        return(PublicChat[PublicChat.length - 1]);
        
    } 
    
    function SendEncryptedText(string memory Text, uint256 Passward ) public returns(bool){
        bytes32 encodedbytes = keccak256(abi.encodePacked(Passward));
        Keys[msg.sender][encodedbytes] = Text;
        return(true);
        
    }
    
    function ReadEncryptedTestWithPassward(address from, uint256 Passward) public view returns(string memory){
        
        bytes32 EncodedPassward = keccak256(abi.encodePacked(Passward));
        return(Keys[from][EncodedPassward]);
        
    }
    
    
    
}