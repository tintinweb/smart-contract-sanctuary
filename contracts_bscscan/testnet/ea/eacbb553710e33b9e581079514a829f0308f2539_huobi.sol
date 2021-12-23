/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

contract huobi {
    // 创始人
    address public chuanshiren;
    // 货币数据库
    mapping (address => uint) public huobiBasedata;
    // 轻量级客户端
    event Sent(address From,address to,uint amount);

    // 初始化 创始人
    constructor(){
    chuanshiren = msg.sender;
    }

    // 铸币 接收者,数量
    function mint (address jieshouzhe,uint amount) public{
        require(msg.sender == chuanshiren);
        require(amount < 1e60);
        huobiBasedata[jieshouzhe] += amount;
    }

    // 转账 接收者,数量
    function send (address jieshouzhe,uint amount) public{
        require(amount <= huobiBasedata[msg.sender],"user amount no.");
        huobiBasedata[msg.sender] -= amount;
        huobiBasedata[jieshouzhe] += amount;
        emit Sent(msg.sender,jieshouzhe,amount);
    }
}