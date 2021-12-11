/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0 <0.9.0;

contract Titola{
    string text;

    function Escriure(string calldata _text) public{
        text = _text;
    }   

    function Llegir() public view returns(string memory){
        return text;
    }
}