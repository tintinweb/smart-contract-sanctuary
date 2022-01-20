/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.11;



// File: mysolidity.sol

contract myCont{
    uint256 favouriteNumber;
    function store(uint256 _number)public {
        favouriteNumber=_number;
    }

    function retrieve() public view  returns(uint256){
        return favouriteNumber;
    }
}