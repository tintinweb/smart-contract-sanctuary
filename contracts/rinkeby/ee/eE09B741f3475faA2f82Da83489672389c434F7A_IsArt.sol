/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 < 0.9.0;

contract IsArt {

    bool isArt = false; // boolean, can be true or false
    
    // sets the contract to be art or not art
    function changeStatus() public {
        if(isArt == true) {
            isArt = false;
        } else {
            isArt = true;
        }
    }
    
    // allows us to see the status of the contract as art or not
    function viewStatus() public view returns (string memory){
        if(isArt) {
            return "This contract is art";
        } else {
            return "This contract is not art";
        }
    }
}