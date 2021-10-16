/**
 *Submitted for verification at Etherscan.io on 2021-10-16
*/

pragma solidity ^0.6.0;

contract Funding{//核心智能合约

    address public manager;
    string public projectName;
    uint public supportMoney;
    uint public goalMoney;
    uint public endTime;

    //Funding智能合约构造函数
    constructor(string memory _projectName, uint _supporMoney, uint _goalMoney, address _address) public{
        manager = _address;
        projectName = _projectName;
        supportMoney = _supporMoney;
        goalMoney = _goalMoney;
        endTime = now + 4 weeks;
    }
}