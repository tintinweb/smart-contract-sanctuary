/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract DataStruct{

    address public creator;

    mapping(address => uint256) public balanceOf;

    event TestCall(address currentAddr,uint256 amount,uint256 createTime);

    modifier checkTime(){
        require(block.timestamp >= 0);
        _;
    }

    constructor(){
        creator = msg.sender;
    }

    function testCall(uint256 amount)
        public
        checkTime
    {
        balanceOf[msg.sender] = amount;
        emit TestCall(msg.sender, amount,block.timestamp);
    }

}