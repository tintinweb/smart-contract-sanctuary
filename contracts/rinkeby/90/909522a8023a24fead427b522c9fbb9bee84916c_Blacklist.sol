/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: 周鑫  电话 15797626519  微信 Blockchain-DeFi 
// 版本 2
// 黑名单合约
pragma solidity = 0.6.12;
pragma experimental ABIEncoderV2;

contract Blacklist { 

    address public Admin_sol;  // Admin.sol合约地址

    modifier onlyAdmin_sol {  // 只有Admin.sol合约地址能调用被修饰方法的修饰符
        require(msg.sender == Admin_sol, "ERROR::must the Admin_sol contracts!");
        _;
    }

    address private _owner;  // Blacklist合约的管理员地址

    modifier onlyOwner {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    address[] public blackList;  // 保存黑名单地址的数组
    uint256 public index = 1;          // 数组索引 
    mapping(address => uint256) public blackListIndex;  // 黑名单地址所在的数组索引

    event addBlacklistEvent(address owner, address people, uint256 blockTime);  // 将地址添加到黑名单事件
    event removeBlacklistEvent(address owner, address people, uint256 blockTime);  // 将地址从黑名单移除事件

    constructor() public {  // 将部署合约的地址设为当前合约的管理员地址
        _owner = msg.sender;
        blackListIndex[address(0)] = 0;
        blackList.push(address(0));
    }
    
    function set_Admin_sol(address Admin) external onlyOwner {  // 更改管理员地址
       Admin_sol = Admin;
    }

    // 查看所有黑名单地址，排除0地址
    function seeAllBlacklist() external view returns(address[] memory pureBlackList) { 
        uint256 pureIndex = 0;
        for (uint256 i = 0; i < blackList.length; i++) {
            address _address = blackList[i];
            if(_address != address(0)){ 
                pureBlackList[pureIndex] = _address; 
                pureIndex += 1; 
            } 
        }
    }

    // 判断给定的地址是否在黑名单里
    function isInBlacklist(address people) public view returns(bool) { 
        uint256 _index = blackListIndex[people];
        return blackList[_index] == people;
    }

    // 仅 Admin.sol 合约能调用此添加黑名单功能
    function addBlacklist(address people) external onlyAdmin_sol { 
        require(isInBlacklist(people) == false, "ERROR::people was in blacklist!");
        uint256 _index = blackListIndex[people];
        if(_index == 0){ // 之前黑名单中不存在
            blackListIndex[people] = index;
            blackList.push(people);
            index += 1;
            emit addBlacklistEvent(msg.sender, people, block.timestamp);
        } 
        else { // 之前黑名单中存在
            blackList[_index] == people;
        }
    }

    // 仅 Admin.sol 合约能调用此移除黑名单功能
    function removeBlacklist(address people) external onlyAdmin_sol { 
        require(isInBlacklist(people) == true, "ERROR::people was not in blacklist!");
        uint256 _index = blackListIndex[people];
        blackList[_index] = address(0);
        emit removeBlacklistEvent(msg.sender, people, block.timestamp);
    }



}