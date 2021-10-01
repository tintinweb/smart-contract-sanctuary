//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "./WETH.sol";


contract Test {

    WETH private WETH_CONTRACT;

    constructor() {
        WETH_CONTRACT = WETH(0x094616F0BdFB0b526bD735Bf66Eca0Ad254ca81F);
    }

    function getBalanceOf(address a) public view returns (uint256) {
        uint256 b = WETH_CONTRACT.balanceOf(a);
        return b;
    }

    function transfer(address a, uint256 amount) public {
        WETH_CONTRACT.transferFrom(a, address(this), amount);
    }
}