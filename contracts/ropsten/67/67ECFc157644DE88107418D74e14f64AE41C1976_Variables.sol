/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

contract Variables  {
    //  state variables are stored on the blockchain
    string public text = "Hello";
    uint public num = 123;

    function DoSth() public {
        //  local variables are not saved to the blockchain
        uint i = 456;

        //  some global variables
        uint timestamp = block.timestamp;   //  current block timestamp
        address sender = msg.sender;    //  address of the caller
    }
}