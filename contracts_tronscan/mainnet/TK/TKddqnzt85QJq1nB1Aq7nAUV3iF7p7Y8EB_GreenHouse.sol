//SourceUnit: CNR.sol


// File: contracts/SafeMath.sol

pragma solidity 0.6.0;


/// @dev Math operations with safety checks that revert on error
library SafeMath {
    /// @dev Multiplies two numbers, reverts on overflow.
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'MUL_ERROR');

        return c;
    }

    /// @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'DIVIDING_ERROR');
        uint256 c = a / b;
        return c;
    }

    /// @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'SUB_ERROR');
        uint256 c = a - b;
        return c;
    }

    /// @dev Adds two numbers, reverts on overflow.
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'ADD_ERROR');
        return c;
    }
}

interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

//SourceUnit: GreenHouse.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;

import "./StakeStorage.sol";

contract GreenHouse is StakeStorage {
    using SafeMath for uint256;

    struct FeeBreakdownINFO {
        uint256 _totalSpend;
        uint256 _toDistribte;
        uint256 _totalStaked;
        uint256 _reward;
        uint256 _tenPercent;
        uint256 _devReward;
        uint256 _fivePercent;
    }

    uint256 public constant HUNDRED_PERCENT = 10 ** 30; // 10^30

    event TotalStaked(uint256 amount);
    event Staked(address who, uint256 amount);
    event Unstaked(address who, uint256 amount);
    
    address public partner;
    address[] public team;

    mapping(address => uint256) public rewards;

    uint256 public monthlyPool;
    uint256 public monthlyPoolTimer;
    mapping(address => uint256) public monthlyPoolRewards;
    mapping(address => uint256) public referralPoolRewards;

    ITRC20 public rise;
    
    constructor(ITRC20 _rise, address[] memory _team, address _partner) public {
        require (_team.length > 0, "The team can't be empty");

        rise = _rise;
        team = _team;
        partner = _partner;
    }

    function updateMonthlyPool() private {
        if (block.timestamp > monthlyPoolTimer) {
            monthlyPoolTimer = block.timestamp.add(2592000); // update for 30 days
            
            // 50% of the MR pool is distributed to all users staked
            uint256 _toDistribte = monthlyPool.mul(uint256(10 ** 29).mul(5)).div(HUNDRED_PERCENT);
            uint256 _totalStaked = StakeStorage.getTotalStaked();
            uint256 _totalSpend;
            uint256 _calculatedValue;

            Stake[] memory stakes = StakeStorage.getStakeList();

            for (uint256 i = 0; i < stakes.length; ++i) {
                _calculatedValue = _toDistribte.mul(stakes[i].amount).div(_totalStaked);
                monthlyPoolRewards[stakes[i].user] = monthlyPoolRewards[stakes[i].user].add(_calculatedValue);
                _totalSpend = _totalSpend.add(_calculatedValue);
            }

            monthlyPool = monthlyPool.sub(_totalSpend);
        }
    }

    function feeBreakdown(uint256 _fee, address _referral) private returns (uint256) {
        FeeBreakdownINFO memory f;

        // 70% of fee distributed to all users staked
        f._toDistribte = _fee.mul(uint256(10 ** 29).mul(7)).div(HUNDRED_PERCENT);
        Stake[] memory _stakes = StakeStorage.getStakeList();

        f._totalStaked = StakeStorage.getTotalStaked();

        for (uint256 i = 0; i < _stakes.length; ++i) {
            f._reward = f._toDistribte.mul(_stakes[i].amount).div(f._totalStaked);
            rewards[_stakes[i].user] = rewards[_stakes[i].user].add(f._reward);
            f._totalSpend = f._totalSpend.add(f._reward);
        }

        // 10% of fee - Bonus Reward Pool
        f._tenPercent = _fee.mul(10 ** 29).div(HUNDRED_PERCENT);
        bonusPool = bonusPool.add(f._tenPercent);
        f._totalSpend = f._totalSpend.add(f._tenPercent);

        // 10% of fee - Platform Fee
        f._devReward = f._tenPercent.div(team.length);

        for (uint256 i = 0; i < team.length; ++i) {
            rewards[team[i]] = rewards[team[i]].add(f._devReward);
            f._totalSpend = f._totalSpend.add(f._devReward);
        }

        // 5% of fee - Referral Fee (Goes to the Monthly Reward Pool if no referral used)
        f._fivePercent = _fee.mul(uint256(10 ** 28).mul(5)).div(HUNDRED_PERCENT);

        if (_referral == address(0)) {
            monthlyPool = monthlyPool.add(f._fivePercent);
        } else {
            // 100 CNR
            if (getUserStake(_referral) >= 10000000000) {
                referralPoolRewards[_referral] = referralPoolRewards[_referral].add(f._fivePercent);
            } else {
                monthlyPool = monthlyPool.add(f._fivePercent);
            }
        }

        f._totalSpend = f._totalSpend.add(f._fivePercent);

        updateMonthlyPool();

        // 5% of fee - Partner Wallet
        rewards[partner] = rewards[partner].add(f._fivePercent);
        f._totalSpend = f._totalSpend.add(f._fivePercent);

        return f._totalSpend;
    }

    function getReward() public {
        updateLeaderboard();
        updateMonthlyPool();

        uint256 toSend = rewards[msg.sender].add(monthlyPoolRewards[msg.sender]).add(bonusPoolReward[msg.sender]).add(referralPoolRewards[msg.sender]);

        rewards[msg.sender] = 0;
        monthlyPoolRewards[msg.sender] = 0;
        bonusPoolReward[msg.sender] = 0;
        referralPoolRewards[msg.sender] = 0;

        if (toSend > 0) {
            rise.transfer(msg.sender, toSend);
        }
    }

    function stake(uint256 _amount, address _referral) external {
        require (_referral != msg.sender, "Referral equals msg.sender");
        require (_amount > 0, "Can't stake zero tokens");

        uint256 _fee = _amount.div(10); // fee is 10%
        uint256 _totalSpend = feeBreakdown(_fee, _referral);
        uint256 _userAmount = _amount.sub(_totalSpend); // user amount after 10% fee + unspent fee output

        rise.transferFrom(msg.sender, address(this), _amount);
        StakeStorage.addStake(msg.sender, _userAmount);
        StakeStorage.setLeader(msg.sender, _amount);
        emit Staked(msg.sender, _userAmount);
        emit TotalStaked(getTotalStaked());
    }

    function unstake(uint256 _amount) external {
        StakeStorage.subStake(msg.sender, _amount);
        updateLeaderboard();

        uint256 _fee = _amount.div(10);
        uint256 _totalSpend = feeBreakdown(_fee, address(0));
        uint256 _userAmount = _amount.sub(_totalSpend); // user amount after 10% fee + unspent fee output

        rise.transfer(msg.sender, _userAmount);
        emit Unstaked(msg.sender, _userAmount);
        emit TotalStaked(getTotalStaked());
    }

    function reinvest(address _referral) external {   
        updateLeaderboard();     
        uint256 _toReinvest = rewards[msg.sender].add(monthlyPoolRewards[msg.sender]).add(bonusPoolReward[msg.sender]).add(referralPoolRewards[msg.sender]);
        
        rewards[msg.sender] = 0;
        monthlyPoolRewards[msg.sender] = 0;
        bonusPoolReward[msg.sender] = 0;
        referralPoolRewards[msg.sender] = 0;

        if (_toReinvest > 0) {
            uint256 _fee = _toReinvest.div(10); //_toReinvest fee
            uint256 _totalSpend = feeBreakdown(_fee, _referral);
            uint256 _userAmount = _toReinvest.sub(_totalSpend);
            StakeStorage.addStake(msg.sender, _userAmount);

            emit Staked(msg.sender, _userAmount);
            emit TotalStaked(getTotalStaked());
        }
    }
}


//SourceUnit: StakeStorage.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;

import "./CNR.sol";

contract StakeStorage {
    using SafeMath for uint256;

    struct Stake {
        address user;
        uint256 amount;
    }

    uint256 private totalStaked;

    mapping(address => uint256) private map; // index
    Stake[] internal list;

    struct Leader {
        address user;
        uint256 amount;
    }

    uint256 public poolTimer;
    uint256 internal bonusPool;

    mapping(address => uint256) internal bonusPoolReward;
    Leader[] private leaders;

    function updateLeaderboard() internal {
        if (block.timestamp > poolTimer) {
            // set new timer
            poolTimer = block.timestamp.add(21600); // 21600 is 6h

            if (bonusPool > 0) {
                // 40% of Bonus Pool is distributed to the top 10 on the leaderboard
                uint256 _toDistribute = bonusPool.mul(uint256(10 ** 29).mul(4)).div(10 ** 30);
                uint256 _totalSpend;

                if (leaders.length > 0) {
                    uint256 _leadersDistribute = _toDistribute.div(leaders.length);
                    
                    for (uint256 i = 0; i < leaders.length; ++i) {
                        bonusPoolReward[leaders[i].user] = bonusPoolReward[leaders[i].user].add(_leadersDistribute);
                        _totalSpend = _totalSpend.add(_leadersDistribute);
                    }
                }

                // 40% of Bonus Pool is distributed to all users Staking
                if (totalStaked > 0) {
                    uint256 _calculatedValue;
                    uint256 _totalStaked = totalStaked;

                    for (uint256 i = 0; i < list.length; ++i) {
                        _calculatedValue = _toDistribute.mul(list[i].amount).div(_totalStaked);
                        bonusPoolReward[list[i].user] = bonusPoolReward[list[i].user].add(_calculatedValue);
                        _totalSpend = _totalSpend.add(_calculatedValue);
                    }
                }

                // 20% of Bonus Pool is carried forward into a new round
                bonusPool = bonusPool.sub(_totalSpend);
            }
        }
    }

    function setLeader(address _addr, uint256 _amount) internal {
        updateLeaderboard();

        // 1000 CNR
        if (_amount < 100000000000) {
            return;
        }

        poolTimer = poolTimer.add(900); // 15 mins
        // pool timer shouldn't exceed 6 hours
        if (poolTimer > block.timestamp.add(21600)) {
            poolTimer = block.timestamp.add(21600);
        }

        leaders.push(Leader(_addr, _amount));

        Leader memory temp;

        // add new item in head of list
        for (uint256 i = leaders.length - 1; i > 0; --i) {
            temp = leaders[i - 1];
            leaders[i - 1] = leaders[i];
            leaders[i] = temp;
        }

        if (leaders.length > 10) {            
            leaders.pop();
        }
    }

    function addStake(address _addr, uint256 _amount) internal {
        totalStaked = totalStaked.add(_amount);

        uint256 _id = map[_addr];

        if (_id != 0) {
            _id = _id.sub(1);
            list[_id].amount = list[_id].amount.add(_amount);
            
            return;
        }

        list.push(Stake(_addr, _amount));
        map[_addr] = list.length;
    }

    function subStake(address _addr, uint256 _amount) internal {
        totalStaked = totalStaked.sub(_amount);

        uint256 _id = map[_addr];
        
        require (_id != 0 && _id <= list.length, "NotExistInList");

        _id = _id.sub(1);
        list[_id].amount = list[_id].amount.sub(_amount);
        
        if (list[_id].amount == 0) {
            uint256 lastListID = list.length.sub(1);
            map[list[lastListID].user] = _id.add(1);
            list[_id] = list[lastListID];

            list.pop();
            delete map[_addr];
        }
    }

    function getStakeList() public view returns(Stake[] memory) {
        return list;
    }

    function getTotalPlayers() public view returns(uint256) {
        return list.length;
    }

    function getUserStake(address _addr) public view returns(uint256) {
        uint256 _id = map[_addr];
        if (_id == 0) return 0;
        return list[_id - 1].amount;
    }

    function getIndex(address _addr) public view returns(uint256) {
        return map[_addr];
    }

    function getLeaders() public view returns(Leader[] memory) {
        return leaders;
    }

    function getLeader(uint256 _id) public view returns(address, uint256) {
        require(_id < leaders.length, "IdTooBig");
        return (leaders[_id].user, leaders[_id].amount);
    }

    function getBonusPoolReward(address _addr) public view returns(uint256) {
        return bonusPoolReward[_addr];
    }

    function getBonusPool() public view returns(uint256) {
        return bonusPool;
    }

    function getTotalStaked() public view returns(uint256) {
        return totalStaked;
    }
}