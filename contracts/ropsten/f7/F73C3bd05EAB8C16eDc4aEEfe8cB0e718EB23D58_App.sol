/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.7.6;
pragma abicoder v2;

contract App {
    mapping(address => uint) public balance;
    
    event Transfer(address indexed staker, int amount);
    event NI_Transfer(address, int);
    
    struct CallbackData {
        address staker;
        uint amount;
    }
    
    function act(address staker, int amount) external {
        emit Transfer(staker, amount);
        emit NI_Transfer(staker, amount);
    }
    
    function CallBackBytes(bytes calldata _data) external {
        CallbackData memory data = abi.decode(_data, (CallbackData));
        address staker = data.staker;
        uint amount = data.amount;
        balance[staker] += amount;
    }
    
    function CallBackParas(address staker, uint amount) external{
        balance[staker] += amount;
    }
}