/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

contract BorrowerProxy {
    address liquidityPool;

    constructor() {
        liquidityPool = msg.sender;
    }

    function lend(address _caller, bytes calldata _data) external payable  {
        require(msg.sender == liquidityPool, "BorrowerProxy: Caller is not the liquidity pool");
        (bool success,) = _caller.call{ value: msg.value }(_data);
        require(success, "BorrowerProxy: Borrower contract reverted during execution");
    }
}