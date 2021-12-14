/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

contract Variables  {
    //  state variables are stored on the blockchain
    string public text = "Hello";
    uint public num = 123;

    /*
        Constants are variables that cannot be modified
        Their value is hard coded and using constants can save gas cost.
    */
    address public constant MY_ADDRESS = 0x777788889999AaAAbBbbCcccddDdeeeEfFFfCcCc;    //  uppercase constant variables
    uint public constant MY_UINT = 123;

    //  Immutable
    address public immutable SENDER_ADDRESS;

    constructor()   {
        SENDER_ADDRESS = msg.sender;
    }

    function DoSth() public {
        //  local variables are not saved to the blockchain
        uint i = 456;

        //  some global variables
        uint timestamp = block.timestamp;   //  current block timestamp
        address sender = msg.sender;    //  address of the caller
    }
}