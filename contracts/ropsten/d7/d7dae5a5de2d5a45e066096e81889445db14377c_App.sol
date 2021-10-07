/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.7.6;
pragma abicoder v2;

contract App {
    mapping(address => uint256) public balance;

    event EVENT(address indexed staker0, address indexed staker1, uint256 amount0, uint256 amount1);

    struct Amounts {
        uint256 amount0;
        uint256 amount1;
    }
    
    struct Stakers {
        address staker0;
        address staker1;
    }

    function act(address staker0, uint256 amount) external {
        emit EVENT(staker0, address(this), amount, amount * 2);
    }

    function onEventEmitted(bytes calldata _indexed, bytes calldata _data) external {
        Stakers memory stakers = abi.decode(_indexed, (Stakers));
        Amounts memory amounts = abi.decode(_data, (Amounts));
        balance[stakers.staker0] += amounts.amount0;
        balance[stakers.staker1] += amounts.amount1;
    }
}