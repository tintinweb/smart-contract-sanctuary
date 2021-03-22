// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

contract Selector {
    
    constructor() {}
    function calculateSelector() public pure returns (bytes4) {
        IERC20 i;
        return i.totalSupply.selector ^ i.balanceOf.selector ^ i.transfer.selector ^ i.allowance.selector ^ i.approve.selector ^ i.transferFrom.selector ^ i.burn.selector;
    }
}