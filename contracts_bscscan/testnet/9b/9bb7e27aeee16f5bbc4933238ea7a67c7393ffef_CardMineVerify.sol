/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-07-13
*/

pragma solidity ^0.7.0;

// SPDX-License-Identifier: SimPL-2.0

abstract contract ContractOwner {
    address public contractOwner = msg.sender;

    modifier ContractOwnerOnly {
        require(msg.sender == contractOwner, "contract owner only");
        _;
    }
}


contract Manager is ContractOwner {
    mapping(string => address) public members;

    mapping(address => mapping(string => bool)) public userPermits;//地址是否有某个权限


    function setMember(string memory name, address member)
    external ContractOwnerOnly {

        members[name] = member;
    }

    function setUserPermit(address user, string memory permit,
        bool enable) external ContractOwnerOnly {

        userPermits[user][permit] = enable;
    }

    function getTimestamp() external view returns(uint256) {
        return block.timestamp;
    }
}

abstract contract Member is ContractOwner {
    //检查权限
    modifier CheckPermit(string memory permit) {
        require(manager.userPermits(msg.sender, permit),
            "no permit");
        _;
    }

    Manager public manager;

    function setManager(address addr) external ContractOwnerOnly {
        manager = Manager(addr);
    }
}

abstract contract MortgageBase is Member {
    uint256 public startTime;
    uint256 public totalDuration;
    uint256 public totalReward;

    int256 public mortgageMax = 10 ** 30;

    mapping(address => int256) public mortgageAmounts;
    mapping(address => int256) public mortgageAdjusts;

    int256 public totalAmount;
    int256 public totalAdjust;

    constructor(uint256 _startTime, uint256 _duration, uint256 _reward) {
        startTime = _startTime;
        totalDuration = _duration;
        totalReward = _reward;
    }

    function setMortgageMax(int256 max) external CheckPermit("Config") {
        mortgageMax = max;
    }

    function getMineInfo(address owner) external view
    returns(uint256, uint256, uint256, int256, int256, int256, int256) {

        return (startTime, totalDuration, totalReward,
        totalAmount, totalAdjust,
        mortgageAmounts[owner], mortgageAdjusts[owner]);
    }

    function _mortgage(address owner, int256 amount) internal {
        int256 newAmount = mortgageAmounts[owner] + amount;
        require(newAmount >= 0 && newAmount < mortgageMax, "invalid amount");

        uint256 _now = block.timestamp;

        if (_now > startTime && totalAmount != 0) {
            int256 reward;
            if (_now < startTime + totalDuration) {
                reward = int256(totalReward * (_now - startTime) / totalDuration)
                + totalAdjust;
            } else {
                reward = int256(totalReward) + totalAdjust;
            }

            int256 adjust = reward * amount / totalAmount;
            mortgageAdjusts[owner] += adjust;
            totalAdjust += adjust;
        }

        mortgageAmounts[owner] = newAmount;
        totalAmount += amount;
    }

    function calcReward(address owner) public view returns(int256) {
        uint256 _now = block.timestamp;
        if (_now <= startTime) {
            return 0;
        }

        int256 amount = mortgageAmounts[owner];//平均每个区块领取的钱
        int256 adjust = mortgageAdjusts[owner];//已领取收益

        if (amount == 0) {
            return -adjust;
        }

        int256 reward;

        if (_now < startTime + totalDuration) {
            reward = int256(totalReward * (_now - startTime) / totalDuration)
            + totalAdjust;
        } else {
            reward = int256(totalReward) + totalAdjust;
        }

        return reward * amount / totalAmount - adjust;
    }

    function _withdraw() internal returns(uint256) {
        int256 reward = calcReward(msg.sender);
        require(reward > 0, "no reward");

        mortgageAdjusts[msg.sender] += reward;
        return uint256(reward);
    }

    function stopMortgage() external CheckPermit("Admin") {
        uint256 _now = block.timestamp;
        require(_now < startTime + totalDuration, "mortgage over");

        uint256 tokenAmount;

        if (_now < startTime) {
            tokenAmount = totalReward;
            totalReward = 0;
            totalDuration = 1;
        } else {
            uint256 reward = totalReward * (_now - startTime) / totalDuration;
            tokenAmount = totalReward - reward;
            totalReward = reward;
            totalDuration = _now - startTime;
        }

        IERC20(manager.members("token")).transfer(
            manager.members("cashier"), tokenAmount);
    }
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function totalSupply() external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);

    function approve(address spender, uint256 value) external returns(bool);
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
}


contract CardMineVerify is MortgageBase {
    constructor(uint256 _startTime, uint256 _duration, uint256 _reward)
    MortgageBase(_startTime, _duration, _reward) {
    }

    function updateFight(address owner, int256 fight) external {
        
        int256 amount = fight - mortgageAmounts[owner];
        _mortgage(owner, amount);
    }

    function withdraw() external {
        uint256 reward = _withdraw();

        // not check result to save gas
        IERC20(manager.members("token")).transfer(msg.sender, reward);
    }
}