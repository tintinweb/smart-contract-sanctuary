/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

struct MintParams {
    address token0;
    address token1;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    uint128 amount;
    uint256 amount0Max;
    uint256 amount1Max;
    address recipient;
    uint256 deadline;
}

contract Test {
    
    MintParams public params;

    function setParams(MintParams calldata _params) external {
        params = _params;
    }
}