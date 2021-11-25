/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

contract osaisenBOX {

    address public owner;
    uint[] osaisen;
    address[] sanpaisha;
    uint public sanpaisuu;

    function omairi() public payable {
        osaisen.push(msg.value);
        sanpaisha.push(msg.sender);
        sanpaisuu = sanpaisuu + 1;
    }

    function checkOsaisen(uint _num) public view returns(uint){
        return osaisen[_num];
    }

    function checksanpaisha(uint _num) public view returns(address){
        return sanpaisha[_num];
    }

    function checkRecentOsaisen() public view returns(uint){
        return osaisen[sanpaisuu-1];
    }

    function checkRecentSanpaisha() public view returns(address){
        return sanpaisha[sanpaisuu-1];
    }

    function withdraw() public {
        require(msg.sender == owner);
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    constructor()  {
        //aimisekiguchi
        owner = 0x24764C8d70510b894AA375395845deD011a836a4;
    } 
}