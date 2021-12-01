/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

pragma solidity ^0.4.11;

/// @title 委托投票
contract InfoFeed {
    // 这里声明了一个新的复合类型用于稍后的变量
    // 它用来表示一个选民
    function info() payable returns (uint ret) { // 如果这里有payable，说明该函数外部调用的时候必须发送ether和gas
        return msg.value;
    }
}


///  委托投票
contract Consumer {

    function deposit() payable returns (uint){
        return msg.value;
    }

    function left() constant returns (uint){
        return this.balance;
    }

    function callFeed(address addr) returns (uint) {
        return InfoFeed(addr).info.value(1).gas(8000)();
    }
}