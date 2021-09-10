/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: MIT

pragma solidity = 0.8.7;

contract GetData {
    
    string title; string title_2; string title_3;string text;
    int8 number;
    
    function setTitle1(string calldata _title) public {
        
        title = _title;
        
    }
    
    function readTitle1() public view returns(string memory) {
        
        return title;
        
    }
    
    function setTitle2(string calldata _title) public {
        
        title_2 = _title;
        
    }
    
    function readTitle2() public view returns(string memory) {
        
        return title_2;
        
    }
    
    function setTitle3(string calldata _title) public {
        
        title_3 = _title;
        
    }
    
    function readTitle3() public view returns(string memory) {
        
        return title_3;
        
    }
    
}