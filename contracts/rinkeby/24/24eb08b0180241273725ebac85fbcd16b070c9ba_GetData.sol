/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

// SPDX-License-Identifier: MIT

pragma solidity = 0.8.7;

contract GetData {
    
    string text;
    string even1="par";
    string even2="impar";
    int8 number;
    
    function readText()  public view returns(string memory) {
        
        return text;
        
    }
    
    function setText(string calldata _text) public {
        
        text = _text;
        
    }
    
    function setNumber(int8 _number) public {
        
        number = _number;
        
    }
    
    function EvenNumber() public view returns(string memory) {
        
        if (number%2==0) {
            
            return even1;
            
        }
        else {
            
            return even2;
            
        }
        
    }
    
    function send_ether(address payable _to) public payable {
        
        _to.transfer(msg.value);
        
    }
    
    function view_ether() public view returns (uint){
        
        return address(this).balance;
        
    }
    
    
    
}