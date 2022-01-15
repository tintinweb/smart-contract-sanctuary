/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract mix {
    mapping(string => uint) private ammount;
    function deposite (string memory password) public payable{
        ammount[password] = msg.value ;
    }
    function check (string memory password) public view returns(string memory a){
        if (ammount[password] > 0) {
            a = "You have deposite";
        }
        else {
            a = "You didn't deposite";
        }
        return a;
    }
    function withdraw (string memory password)public payable returns(string memory b){
        if (ammount[password] > 0) {
            payable(msg.sender).transfer(ammount[password]);
            
        }
        else {
            b = "You didn't deposite";
        }
        return b;
       

    }
}