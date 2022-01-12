/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface EdenNetwork {
    function stakeFor(address recipient, uint128 amount) external;
}

contract Poker {
    address constant EDEN_NETWORK = 0x9E3382cA57F4404AC7Bf435475EAe37e87D1c453;
    address constant EDEN_TOKEN = 0x1559FA1b8F28238FD5D76D9f434ad86FD20D1559;

    address owner;

    constructor() {
        owner = msg.sender;
        IERC20(EDEN_TOKEN).approve(EDEN_NETWORK, type(uint256).max);
    }

    function poke(address[] calldata addresses) public {
        require(msg.sender == owner);
        for (uint i = 0 ; i < addresses.length ; ++i) {
            EdenNetwork(EDEN_NETWORK).stakeFor(addresses[i], 1 ether);
        }
    }

    function rescue(address _token) public {
        require(msg.sender == owner);
        IERC20 token = IERC20(_token);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}