/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.6;



// Part: IJellyAccessControls

interface IJellyAccessControls {
    function hasAdminRole(address _address) external  view returns (bool);

}

// Part: IJellyRewards

interface IJellyRewards {

    function setPoolContract(address _addr, uint256 _pool) external;
    function setRewards( 
        uint256[] memory rewardPeriods, 
        uint256[] memory amounts
    ) external;
    function setBonus(
        address pool,
        uint256[] memory rewardPeriods,
        uint256[] memory amounts
    ) external;
    function updateRewards() external returns(bool);
    function totalRewards() external view returns (uint256 rewards);
    function poolRewards(address _pool, uint256 _from, uint256 _to) external view returns (uint256 rewards);
}

// Part: ITokenPool

interface ITokenPool {
    function stakedEthTotal() external  view returns (uint256);
    function stakedTokenTotal() external  view returns (uint256);
}

// File: BasicRewarder.sol

contract BasicRewarder is IJellyRewards {


    address public rewardsToken;
    IJellyAccessControls public accessControls;

    ITokenPool public tokenPool;
    address public vault;

    uint256 constant POINT_MULTIPLIER = 1e18;

    uint256 constant PERIOD_LENGTH = 14;
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_PERIOD = PERIOD_LENGTH * SECONDS_PER_DAY;

    mapping (uint256 => uint256) public periodRewardsPerSecond;
    mapping (address => mapping(uint256 => uint256)) public periodBonusPerSecond;

    uint256 public startTime;
    uint256 public lastRewardTime;
    uint256 public poolCount;
    mapping (uint256 => uint256) public tokenRewardsPaid;

    mapping (uint256 =>  mapping(address => uint256)) public periodWeightPoints;


    event Recovered(address indexed token, uint256 amount);

    constructor(
        address _rewardsToken,
        address _accessControls,
        address _tokenPool,
        uint256 _startTime,
        uint256 _lastRewardTime
    )
        public
    {
        rewardsToken = _rewardsToken;
        accessControls = IJellyAccessControls(_accessControls);
        tokenPool = ITokenPool(_tokenPool);
        startTime = _startTime;
        lastRewardTime = _lastRewardTime;
    }


    function setStartTime(
        uint256 _startTime,
        uint256 _lastRewardTime
    )
        external
    {
        require(
            accessControls.hasAdminRole(msg.sender),
            "setStartTime: Sender must be admin"
        );
        startTime = _startTime;
        lastRewardTime = _lastRewardTime;
    }

    function setPoolContract(address _addr, uint256 _poolId) external override {

    }


    function setVault(
        address _addr
    )
        external
    {
        require(
            accessControls.hasAdminRole(msg.sender),
            "setVault: Sender must be admin"
        );

        vault = _addr;
    }

    function setRewardsPaid(address _pool, uint256 _amount) external  {

    }


    function setRewards(
        uint256[] memory rewardPeriods,
        uint256[] memory amounts
    )
        external
        override
    {
        require(
            accessControls.hasAdminRole(msg.sender),
            "JellyRewards.setRewards: Sender must be admin"
        );
        uint256 numRewards = rewardPeriods.length;
        for (uint256 i = 0; i < numRewards; i++) {
            uint256 week = rewardPeriods[i];
            uint256 amount = amounts[i] * POINT_MULTIPLIER
                                        / SECONDS_PER_PERIOD
                                        / POINT_MULTIPLIER;
            periodRewardsPerSecond[week] = amount;
        }
    }

    function setBonus(
        address pool,
        uint256[] memory rewardPeriods,
        uint256[] memory amounts
    ) external override {
        require(
            accessControls.hasAdminRole(msg.sender),
            "JellyRewards.setBonus: Sender must be admin"
        );
        uint256 numRewards = rewardPeriods.length;
        for (uint256 i = 0; i < numRewards; i++) {
            uint256 week = rewardPeriods[i];
            uint256 amount = amounts[i] * POINT_MULTIPLIER
                                        / SECONDS_PER_PERIOD
                                        / POINT_MULTIPLIER;
            periodBonusPerSecond[pool][week] = amount;
        }
    }

    function updateRewards() 
        external
        override
        returns(bool)
    {
        if (block.timestamp <= lastRewardTime) {
            return false;
        }

        // GP: TODO Loop through all the pools
        uint256 m_net = tokenPool.stakedTokenTotal();

        uint256 net_total = m_net;
        if (net_total == 0 || block.timestamp <= startTime) {
            lastRewardTime = block.timestamp;
            return false;
        }

        _updateWeights();
    

        for (uint256 i = 0; i < poolCount; i++) {
            _updateTokenRewards(i);
        }

        lastRewardTime = block.timestamp;
        return true;
    }


    function totalRewards() external override view returns (uint256) {
        uint256 tokenRewardsCount = 0 ;

        for (uint256 i = 0; i < poolCount; i++) {
            tokenRewardsCount += tokenRewards(i, lastRewardTime, block.timestamp);
        }

        return tokenRewardsCount;     
    }


    function tokenRewards(uint256 _pool, uint256 _from, uint256 _to) public view returns (uint256 rewards) {
        if (_to <= startTime) {
            return 0;
        }
        if (_from < startTime) {
            _from = startTime;
        }
        uint256 fromWeek = diffDays(startTime, _from) / 7;
        uint256 toWeek = diffDays(startTime, _to) / 7;

       if (fromWeek == toWeek) {
            return _rewardsFromPoints(periodRewardsPerSecond[fromWeek],
                                    _to - _from,
                                    periodWeightPoints[fromWeek][address(tokenPool)]) + periodBonusPerSecond[address(tokenPool)][fromWeek] * (_to - _from);
        }
        uint256 initialRemander = startTime + (fromWeek+1) * (SECONDS_PER_PERIOD) - _from;
        rewards = _rewardsFromPoints(periodRewardsPerSecond[fromWeek],
                                    initialRemander,
                                    periodWeightPoints[fromWeek][address(tokenPool)])
                        + periodBonusPerSecond[address(tokenPool)][fromWeek] * initialRemander;

        for (uint256 i = fromWeek+1; i < toWeek; i++) {
            rewards = rewards + _rewardsFromPoints(periodRewardsPerSecond[i],
                                    SECONDS_PER_PERIOD,
                                    periodWeightPoints[i][address(tokenPool)]) + periodBonusPerSecond[address(tokenPool)][i] * SECONDS_PER_PERIOD;
        }
        uint256 finalRemander = _to - (toWeek * SECONDS_PER_PERIOD + startTime);
        rewards = rewards + (_rewardsFromPoints(periodRewardsPerSecond[toWeek],
                                    finalRemander,
                                    periodWeightPoints[toWeek][address(tokenPool)])
                          + (periodBonusPerSecond[address(tokenPool)][toWeek]) * finalRemander);
        return rewards;
    }

    function _updateTokenRewards(
        uint256 poolId
    ) 
        internal
        returns(uint256 rewards)
    {
        rewards = tokenRewards(poolId, lastRewardTime, block.timestamp);
        if ( rewards > 0 ) {
            tokenRewardsPaid[poolId] += rewards;

        }
    }

    function _updateWeights(
    ) 
        internal
    {
    }


    function _rewardsFromPoints(
        uint256 rate,
        uint256 duration, 
        uint256 weight
    ) 
        internal
        pure
        returns(uint256)
    {
        return rate * duration
             * weight
             / 1e18
             / POINT_MULTIPLIER;
    }

    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function poolRewards(address _pool, uint256 _from, uint256 _to) external override view returns (uint256 rewards) {}

    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount
    )
        external
    {
        require(
            accessControls.hasAdminRole(msg.sender),"BasicRewarder.recoverERC20: Sender must be admin"
        );
        require(
            tokenAddress != address(rewardsToken),
            "Cannot withdraw the rewards token"
        );
        emit Recovered(tokenAddress, tokenAmount);
    }


}