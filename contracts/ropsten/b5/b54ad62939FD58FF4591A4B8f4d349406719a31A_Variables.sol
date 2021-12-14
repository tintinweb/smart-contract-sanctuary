/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

contract Variables  {
    //  state variables are stored on the blockchain
    string public text = "Hello";
    uint public num;

    //  constant are stored on the blockchain
    address public constant MY_ADDRESS = 0x777788889999AaAAbBbbCcccddDdeeeEfFFfCcCc;    //  uppercase constant variables
    uint public constant MY_UINT = 123;

    //  Immutable
    address public immutable SENDER_ADDRESS;
    uint public immutable TIMESTAMP;

    constructor()   {
        SENDER_ADDRESS = msg.sender;    //  address of the caller
        TIMESTAMP = block.timestamp;    //  current block timestamp
    }

    //  need to send a transaction
    function set(uint _num) public  {
        num = _num;
    }

    //  without sending a transaction
    function get() public view returns(uint)    {
        return num;
    }
}