/**
 *Submitted for verification at polygonscan.com on 2021-10-29
*/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.9;

contract Books {
   mapping (address => mapping(uint256 => uint256)) private map;
   mapping(uint256 => uint256) private mapX;
   uint256 private id;
   
   function setMap(uint256 number) public {
       id++;
       mapX[id] = number;
       map[msg.sender][id] = number;
   }
   
   function getAccount(uint256 BookNumber) public view returns (bool) {
       if (getAccountInt(msg.sender, BookNumber) == true) {
           return true;
       } else {
           return false;
       }
       
   }
   
   function getAccountInt(address sender, uint256 BookNumber) internal view returns (bool) {
        if (map[sender][BookNumber] >= mapX[BookNumber]) {
            return true;
        } else {
            return false;
        }
    }
   
   function getMap2(address sender, uint256 number) public view returns (uint256) {
       
       return map[sender][number];
   }
}