/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

pragma solidity ^0.4.24;
contract FundingFactory{//工厂
    //存储已经部署的智能合约的地址
    uint public numFundings = 0;
    mapping(uint => address) public addrfundings;
    function deploy(string memory _projectName, uint _supporMoney, uint _goalMoney)public{
        addrfundings[numFundings] = new Funding(_projectName, _supporMoney, _goalMoney, msg.sender);
        numFundings++;
    }
    function getAddr()public view returns(address){//拿到本次部署的智能合约地址
        return addrfundings[numFundings - 1];
    }
    // function re()public view returns(){
    //     return 
    // }
}

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