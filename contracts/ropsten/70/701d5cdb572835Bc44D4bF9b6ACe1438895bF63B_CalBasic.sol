/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract CalBasic{
    uint _count;

    event Count(string method,uint count,address sender);

    function increase() public{
        _count++;
        emit Count("Increase",_count,msg.sender);
    }

    function decrease() public{
        _count--;
        emit Count("Decrease",_count,msg.sender);
    }

    function getCount() public view returns(uint count_){
        return _count;
    }
}