/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

// SPDX-License-Identifier: UNLICENSED 周鑫 技术合作微信号： Blockchain-DeFi 电话：15797626519
// 版本 1
// 模块名 黑名单模块
pragma solidity = 0.6.12;
pragma experimental ABIEncoderV2;

contract Blacklist { 

    struct BlacklistStruct { 
        address Business_or_bank;
        bool    isInBlacklist;
    }

    uint256 public index = 0;
    mapping(address => uint256) private BlacklistIndex;
    address[] private BlacklistArray;

    mapping(address => bool) private BlacklistMapping;

    mapping(address => bool) public CloudChainList;

    modifier onlyCloudChainList { 
        require(CloudChainList[msg.sender] == true, "ERROR::You are not the double contracts!");
        _;
    }

    event addBlacklistEvent(address owner, address Business_or_bank, uint256 blockTime);
    event removeBlacklistEvent(address owner, address Business_or_bank, uint256 blockTime);

    address private _owner;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor() public {
        _owner = msg.sender;
    }

    function addTrued(address Admin) external onlyOwner { 
        CloudChainList[Admin] = true;
    }

    function seeAllBlacklist() external view returns(BlacklistStruct[] memory) { 
        uint256 length = BlacklistArray.length;
        BlacklistStruct[] memory B = new BlacklistStruct[](length);
        for (uint256 i = 0; i < length; i++) {
            address _address = BlacklistArray[i];
            if(_address != address(0)){ 
                B[i].Business_or_bank = _address;  
                B[i].isInBlacklist    = BlacklistMapping[_address];  
            } 
        }
        return B;
    }

    function isInBlacklist(address Business_or_bank) external view returns(bool) { 
        return BlacklistMapping[Business_or_bank];
    }

    function addBlacklist(address Business_or_bank) external onlyCloudChainList { 
        require(BlacklistMapping[Business_or_bank] == false);
        BlacklistMapping[Business_or_bank] = true;
        BlacklistArray.push(Business_or_bank);
        emit addBlacklistEvent(msg.sender, Business_or_bank, block.timestamp);
        BlacklistIndex[Business_or_bank] = index;
        index += 1;
    }

    function removeBlacklist(address Business_or_bank) external onlyCloudChainList { 
        require(BlacklistMapping[Business_or_bank] == true);
        BlacklistMapping[Business_or_bank] = false;
        uint256 _index = BlacklistIndex[Business_or_bank];
        BlacklistArray[_index] = address(0);
        emit removeBlacklistEvent(msg.sender, Business_or_bank, block.timestamp);
    }



}