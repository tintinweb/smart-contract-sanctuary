/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.8.0;

contract GameReveal {
    address owner;
    bytes32 public hash;
    uint public cryptedSolution;
    uint public signedSolution;
    uint public publicKey;
    uint public exp;
    
    constructor(uint _publicKey, uint _exp) {
        owner = msg.sender;
        publicKey = _publicKey;
        exp = _exp;
    }
    
    function getHash(string memory _solution) pure public returns(bytes32) {
        return keccak256(abi.encode(_solution));
    }
    
    function getHash(string memory _solution, string memory _salt) pure public returns(bytes32) {
        return keccak256(abi.encodePacked(_solution, _salt));
    }
    
    /* Manager sets the hash, and the reward amount (payable) */
    function setHash(bytes32 _hash) payable external {
        require(owner == msg.sender);
        
        hash = _hash;
        //hash = keccak256(abi.encode(_solution));
    }
    
    function checkHash(string memory _solution) view private {
        require(hash == getHash(_solution));
    }
    
    function checkHash(string memory _solution, string memory _salt) view private {
        require(hash == getHash(_solution, _salt));
    }
    
    function setSignedSolution(uint _signedSolution) payable external {
        require(owner == msg.sender);
        
        signedSolution = _signedSolution;
    }
    function setCryptedSolution(uint _cryptedSolution) payable external {
        require(owner == msg.sender);
        
        cryptedSolution = _cryptedSolution;
    }
    
    function crypt3(uint message) view private returns(uint) {
        return mulmod(mulmod(message, message, publicKey), message, publicKey);
    }
    
    function crypt(uint message) view private returns(uint) {
        uint mm = mulmod(message, message, publicKey);
        for(uint e = 2; e <= exp; e++){
            mm = mulmod(mm, message, publicKey);
        }
        return mm;
    }
    function checkCrypt(string memory _solution) view private {
        require(cryptedSolution == crypt(uint256(getHash(_solution))));
    }
    
    function play(string memory _solution) payable external {
       // require: throws exception if condition not met (refund)
       checkCrypt(_solution);
       //checkHash(_solution);
       
       // send reward
       address payable player = payable(msg.sender);
       
       player.transfer(address(this).balance);
       //address(this).send(player);
   }
   
   function getRewardAmount() external view returns(uint) {
       return address(this).balance;
   }
}