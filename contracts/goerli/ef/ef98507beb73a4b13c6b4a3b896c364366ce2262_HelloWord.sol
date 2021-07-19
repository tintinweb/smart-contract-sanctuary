/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract HelloWord{
    
    string public word;
    address owner;
    
    constructor(string memory _word) {
        word = _word;
        owner = msg.sender;
    }
    
    function  setWord(string calldata _newWord) public payable {
        require(msg.value == 1 wei);
        word = _newWord;
    }
    
    function checkBalance()public view returns(uint256) {
       return address(this).balance;
    }
    
    function getFounds()public onlyOwner {
        //owner.transfer(address(this).balance);
        
        payable(owner).transfer(address(this).balance);
    }
    
    modifier onlyOwner(){
        if(msg.sender != owner){
              revert();  
        }else
        {
            _;
        }
    }
    }