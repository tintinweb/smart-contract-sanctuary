/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
contract SendToSor{
    bool public paused;
    address public owner;
    constructor() public {
        owner = msg.sender;
    }
    function sendMoneyToSorMtw() public payable{
        require(!paused,"Contract is paused");
        address payable _owner = payable(owner);
        _owner.transfer(msg.value);
    }
    function sendMoneyToSorBw() public payable{
        require(!paused,"Contract is paused");
        address payable _sorBw = payable(0xf1438FE3A3C1C8AD149cB4034DEb7F2f1c67F2EB);
        _sorBw.transfer(msg.value);
    }
    function setPaused(bool _paused)public{
        require(msg.sender==owner,"Can't use this function");
        paused = _paused;
    }
}