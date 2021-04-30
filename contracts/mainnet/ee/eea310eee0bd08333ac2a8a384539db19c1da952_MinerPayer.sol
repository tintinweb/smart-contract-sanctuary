/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: gpl-3.0
pragma solidity >= 0.8.0 < 0.9.0;

contract MinerPayer {
    fallback () external {
        assert(false);
    }
    receive() payable external {
        assert(false);
    }
    
    function exec(address to, bytes calldata data) external payable {
        (bool success,) = to.call(data);
        require(success);
        block.coinbase.transfer(msg.value);
    }
}