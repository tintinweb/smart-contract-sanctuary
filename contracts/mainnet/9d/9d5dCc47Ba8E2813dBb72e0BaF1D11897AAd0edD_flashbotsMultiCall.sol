/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// SPDX-License-Identifier: CC-BY-NC-SA-2.5

//@code0x2

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

contract flashbotsMultiCall {
    function multiCall(address[] memory targets, bytes[] memory data, uint256[] memory values, uint256 coinbaseBribe) public payable {
        require(targets.length == data.length && data.length == values.length, "Length mismatch");
        for(uint i = 0; i < targets.length; i++) {
            (bool status,) = targets[i].call{value:values[i]}(data[i]);
            require(status, "call failed");
        }
        block.coinbase.transfer(coinbaseBribe);
    }
    function coinbaseTransfer() public payable {
        block.coinbase.transfer(msg.value);
    }
    receive() external payable {}
    fallback() external {}
}

// this contract is deployed on MAINNET (0x1) at 0x9d5dCc47Ba8E2813dBb72e0BaF1D11897AAd0edD

// erc20 token rescue service (will rescue tokens from hacked address): DM code0x2#0202 on disc