/**
 *Submitted for verification at Etherscan.io on 2021-01-29
*/

// SPDX-License-Identifier: Copyright 2020-2021 Mining Pay, All rights reserved.

pragma solidity 0.7.0;

// Mining Pay Version-1 (ETH)
contract MiningPayV1 {
    struct Member {
        bool join;
        string referrerCode;
        address[] referrers;
        uint256 balance;
        mapping (uint8 => bool) clears;
        mapping (uint8 => uint256) processes;
        mapping (uint8 => uint8) processUnits;
    }
    
    struct Pool {
        uint8 unit;
        uint256 price;
        address[] indexes;
    }
    
    event JoinRewardEvent (
        address indexed _member,
        address indexed _referrer,
        uint256 _amount,
        uint256 _time
    );
    
    event ExitPoolEvent (
        address indexed _member,
        uint8 _poolNumber,
        uint256 _index,
        uint256 _amount,
        uint256 _time
    );
    
    event ClearPoolEvent (
        address indexed _member,
        uint8 _poolNumber,
        uint256 _time
    );
    
    event PoolRewardEvent (
        address indexed _member,
        address indexed _referrer,
        uint8 _poolNumber,
        uint256 _index,
        uint256 _amount,
        uint256 _time
    );
    
    event WithdrawEvent (
        address indexed _member,
        uint256 _amount,
        uint256 _time
    );
    
    uint256 public balance = 0;
    address public developer = 0xC8B98bd9415cb58E07F2fcB6Fb38856D399E71Dc;
    uint256 public joinFee = 0.5 ether;
    mapping (uint8 => Pool) public pools;
    mapping (address => Member) public members;
    address[] public memberList;
    mapping (string => address) public referrerCodes;
    
    constructor() public {
        members[developer].join = true;
        memberList.push(developer);
    }
    
    function joinMember(string memory _referrerCode) public payable {
        require(members[msg.sender].join == false, 'Member exists.');
        require(referrerCodes[_referrerCode] != address(0), 'Referrer not exists.');
        require(msg.value == joinFee, 'Join fee is incorrect.');
        
        balance += joinFee;
        
        members[msg.sender].join = true;
        memberList.push(msg.sender);
        
        address _referrer = referrerCodes[_referrerCode];
        while (members[msg.sender].referrers.length < 100) {
            members[msg.sender].referrers.push(_referrer);
            if (members[_referrer].referrers.length == 0) {
                break;
            }
            _referrer = members[_referrer].referrers[0];
        }
        
        uint256 _remainingReward = joinFee;
        for (uint i = 0; i < members[msg.sender].referrers.length; i++) {
            uint256 _reward = joinFee / 1000;
            if (i == 0) {
                _reward = joinFee / 2;
            } else if (i == 1) {
                _reward = joinFee / 5;
            } else if (i == 2) {
                _reward = joinFee / 10;
            }
            members[members[msg.sender].referrers[i]].balance += _reward;
            _remainingReward -= _reward;
            emit JoinRewardEvent(msg.sender, members[msg.sender].referrers[i], _reward, block.timestamp);
        }
        
        members[developer].balance += _remainingReward;
        emit JoinRewardEvent(msg.sender, developer, _remainingReward, block.timestamp);
    }
    
    
    function createPool(uint8 _poolNumber, uint8 _unit, uint256 _price) public {
        require(msg.sender == developer, 'Only developer can operate.');
        require(pools[_poolNumber].indexes.length == 0, 'Already started pool.');
        
        pools[_poolNumber].unit = _unit;
        pools[_poolNumber].price = _price;
        
        members[developer].processes[_poolNumber] = 0;
        members[developer].processUnits[_poolNumber] = 0;
        pools[_poolNumber].indexes.push(developer);
    }
    
    function enterPool(uint8 _poolNumber) public payable {
        require(members[msg.sender].join, 'Member not exists.');
        require(msg.sender != developer, 'Developer cannot enter.');
        require(pools[_poolNumber].unit > 0 && pools[_poolNumber].price > 0, 'Unset pool.');
        require(members[msg.sender].processes[_poolNumber] == 0, 'Already progress pool.');
        require(msg.value == pools[_poolNumber].price * 11 / 10, 'Pool price is incorrect.');
        
        if (
            _poolNumber != 1 && 
            _poolNumber != 6
        ) {
            require(members[msg.sender].clears[_poolNumber - 1], 'Not meeting enter pool requirements.');
        }
        
        if (members[msg.sender].clears[_poolNumber]) {
            require(members[msg.sender].clears[_poolNumber + 1] || members[msg.sender].processes[_poolNumber + 1] != 0, 'Not meeting enter pool requirements.');
        }
        
        balance += pools[_poolNumber].price * 11 / 10;

        uint256 _poolIndex = pools[_poolNumber].indexes.length;
        members[msg.sender].processes[_poolNumber] = _poolIndex;
        members[msg.sender].processUnits[_poolNumber] = 0;
        pools[_poolNumber].indexes.push(msg.sender);
        
        uint256 _exitIndex = (_poolIndex - 1) / pools[_poolNumber].unit;
        address _exitMemberAddress = pools[_poolNumber].indexes[_exitIndex];
        members[_exitMemberAddress].balance += pools[_poolNumber].price * 9 / 10;
        members[_exitMemberAddress].processUnits[_poolNumber]++;
        emit ExitPoolEvent(_exitMemberAddress, _poolNumber, _poolIndex, pools[_poolNumber].price * 9 / 10, block.timestamp);
        
        if (members[_exitMemberAddress].processUnits[_poolNumber] == pools[_poolNumber].unit) {
            members[_exitMemberAddress].clears[_poolNumber] = true;
            members[_exitMemberAddress].processes[_poolNumber] = 0;
            members[_exitMemberAddress].processUnits[_poolNumber] = 0;
            emit ClearPoolEvent(_exitMemberAddress, _poolNumber, block.timestamp);
        }
        
        uint256 _remainingReward = pools[_poolNumber].price / 10;
        for (uint i = 0; i < members[msg.sender].referrers.length; i++) {
            if (i >= 10) {
                break;
            }
            uint256 _reward = pools[_poolNumber].price * 3 / 1000;
            if (i == 0) {
                _reward = pools[_poolNumber].price * 3 / 100;
            } else if (i == 1) {
                _reward = pools[_poolNumber].price * 2 / 100;
            } else if (i == 2) {
                _reward = pools[_poolNumber].price * 15 / 1000;
            }
            members[members[msg.sender].referrers[i]].balance += _reward;
            _remainingReward -= _reward;
            emit PoolRewardEvent(msg.sender, members[msg.sender].referrers[i], _poolNumber, _poolIndex, _reward, block.timestamp);
        }
        
        members[developer].balance += _remainingReward;
        emit PoolRewardEvent(msg.sender, developer, _poolNumber, _poolIndex, _remainingReward, block.timestamp);
        
        members[developer].balance += pools[_poolNumber].price / 10;
        emit PoolRewardEvent(msg.sender, developer, _poolNumber, _poolIndex, pools[_poolNumber].price / 10, block.timestamp);
    }
    
    function withdraw() public {
        require(members[msg.sender].balance > 0, 'Balance not exists.');
        
        msg.sender.transfer(members[msg.sender].balance);
        balance -= members[msg.sender].balance;
        emit WithdrawEvent(msg.sender, members[msg.sender].balance, block.timestamp);
        
        members[msg.sender].balance = 0;
    }
    
    function changeReferrerCode(string memory _code) public {
        require(members[msg.sender].join, 'Member not exists.');
        require(referrerCodes[_code] == address(0), 'Already code exists.');
        
        referrerCodes[members[msg.sender].referrerCode] = address(0);
        
        members[msg.sender].referrerCode = _code;
        referrerCodes[_code] = msg.sender;
    }
    
    function getMemberReferrers(address _memberAddress) public view returns (address[] memory) {
        return members[_memberAddress].referrers;
    }
    
    function getMemberClears(address _memberAddress, uint8 _poolNumber) public view returns (bool) {
        return members[_memberAddress].clears[_poolNumber];
    }
    
    function getMemberProcesses(address _memberAddress, uint8 _poolNumber) public view returns (uint256) {
        return members[_memberAddress].processes[_poolNumber];
    }
    
    function getPoolIndexes(uint8 _poolNumber) public view returns (address[] memory) {
        return pools[_poolNumber].indexes;
    }
    
    function getMemberList() public view returns (address[] memory) {
        return memberList;
    }
}