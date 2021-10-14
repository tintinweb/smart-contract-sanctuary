/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

contract HantamBerabisLA3 {
    string public name = "HantamBerabisLA3";
    string public symbol = "HTBL3";
    uint public decimals = 18;
    uint public mintCount;
    uint public totalSupply = 5050510101010101010101010 ; // 5.05 million 
    mapping (address => uint) public balanceOf;
    mapping (address => uint) public nonce;

    constructor() {
        balanceOf[msg.sender] = 50505101010101010101010 ; // 1% of totalSupply
    }

    function transfer(address _to, uint _value) public returns (bool success){
        require( balanceOf[msg.sender]>=_value && balanceOf[_to]+_value<=50510101010101010101010 );
        balanceOf[msg.sender] -= _value ;
        balanceOf[_to] += _value;       
        
        if( nonce[msg.sender]==0 && mintCount<1000000 && balanceOf[msg.sender]+_value<=50510101010101010101010 ){ // Minting: first 1000000 addresses will mint tokens on their first transaction provided that balance+mint <=1% of TotalSupply
            nonce[msg.sender]=1;
            mintCount++;
            balanceOf[msg.sender] += (10000000000000000000 - mintCount*10000000000000);
        }
        return true;
    }
}