/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

}

contract DECASDROP  {

   uint256 private lastTimeExecuted = block.timestamp;

   function toMint() public view returns (uint256) {
        uint256 toMintint = block.timestamp - lastTimeExecuted;
        return toMintint * 500000000000000000;
    }

    function run() external {
        IERC20(0x84734648774A8ba7ea8f2077D8cBc6c21210947C).transfer(msg.sender, toMint());
        lastTimeExecuted = block.timestamp;
    }

}