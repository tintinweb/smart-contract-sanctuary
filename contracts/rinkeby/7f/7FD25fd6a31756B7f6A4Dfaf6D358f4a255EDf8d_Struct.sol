/**
 *Submitted for verification at Etherscan.io on 2021-07-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// File: Struct.sol

contract Struct{

    struct Hat{
        uint colour;
        uint colourId;
        bool redeemed;
    }

    mapping(uint=>Hat) public hats;
    uint tokenCounter;
    constructor(){
        tokenCounter=0;
    }

    function setStruct() public {

        hats[tokenCounter].colour=1;
        hats[tokenCounter].colourId=2;
        hats[tokenCounter].redeemed=true;


        tokenCounter++;
    }


}