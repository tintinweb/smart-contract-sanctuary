/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.7.4;



// Part: Gauge

interface Gauge {
    function deposit(uint amount, address receiver) external;
}

// Part: IERC20

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

// File: <stdin>.sol

contract GaugeDepositor {

    function depositForMany(
        IERC20 token,
        Gauge gauge,
        uint total,
        address[] calldata receivers,
        uint[] calldata amounts
    ) external {
        require(msg.sender == 0xF96dA4775776ea43c42795b116C7a6eCcd6e71b5);
        token.transferFrom(msg.sender, address(this), total);
        for (uint i; i < receivers.length; i++) {
            gauge.deposit(amounts[i], receivers[i]);
        }
    }

    function approveGauges(IERC20[] calldata tokens, address[] calldata gauges) external {
        require(msg.sender == 0xF96dA4775776ea43c42795b116C7a6eCcd6e71b5);
        for (uint i; i < tokens.length; i++) {
            tokens[i].approve(gauges[i], uint(-1));
        }
    }

}