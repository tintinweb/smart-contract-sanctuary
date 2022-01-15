/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;


contract Storage {

    string public mymsg;

    function store(string memory newmymsg) public {
        mymsg = newmymsg;
    }


    function retrieve() public view returns (string memory){
        return mymsg;
    }
}