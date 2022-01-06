/**
 *Submitted for verification at polygonscan.com on 2022-01-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ImageStorage {

    // This variable stores the contracts own address and is set upon creation.
    string private _imgbase64;
    
    constructor() {
    }

    function getImage() public view returns (string memory) {
        return _imgbase64;
    }

    function setImage(string memory img) public {
        if (bytes(_imgbase64).length != 0) { 
            revert(); 
        }
       _imgbase64 = img;
    } 
}