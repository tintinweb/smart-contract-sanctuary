/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

///SPDX-License-Identifier: SPDX-License

pragma solidity 0.7.4;


contract ForTest {
    
    string text = "Hello!";
    
    function SetText(string memory _text) public{
        text = _text;
    }
    
    
    function GetText() public view returns(string memory){
        return text;
    } 
}