/**
 *Submitted for verification at Etherscan.io on 2021-01-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

// iRUNE Interface
interface iRUNE {
    function transferTo(address, uint) external returns (bool);
}

// Sushiswap Interface
interface iPair {
    function sync() external;
}

contract Incentives {

    address public RUNE = 0x3155BA85D5F96b2d030a4966AF206230e46849cb;

    event Deposited(address indexed pair, uint value);

    constructor() {}

    // Deposit and sync
    function depositIncentives(address pair, uint value) public {
        uint _value = value * 10**18;
        iRUNE(RUNE).transferTo(pair, _value);
        iPair(pair).sync();
        emit Deposited(pair, _value);
    }
}