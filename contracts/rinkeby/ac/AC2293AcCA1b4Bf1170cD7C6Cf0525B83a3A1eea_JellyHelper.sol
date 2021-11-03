pragma solidity 0.8.6;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

interface ITokenPool {
    function poolRewards(address rewardToken)
        external
        view
        returns (uint64, uint256);

    function rewardsContract() external view returns (address);

    function poolToken() external view returns (address);

    function unclaimedRewards(address _user)
        external
        view
        returns (address[] memory, uint256[] memory);

    function stakedTokenTotal() external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);
}

interface IRewarder {
    function getRewardData(address rewardToken)
        external
        view
        returns (uint64 startTime, uint64 endTime);

    function rewardTokens(address pool)
        external
        view
        returns (address[] memory);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract JellyHelper {
    struct TokenInfo {
        address addr;
        string name;
        string symbol;
        uint256 decimals;
    }

    struct Pool {
        TokenInfo stakingToken;
        Reward[] rewards;
        uint256 stakedTokenTotal;
    }

    struct Reward {
        uint64 startTime;
        uint64 endTime;
        uint256 apy;
        TokenInfo rewardToken;
    }

    struct UserInfo {
        address user;
        UserPool[] pools;
    }

    struct UserPool {
        address pool;
        uint256 staked;
        UserReward[] rewards;
    }

    struct UserReward {
        address rewardToken;
        uint256 unclaimedRewards;
    }

    AggregatorV3Interface internal priceFeed;

    constructor() {
        priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        ); // rinkeby feed
    }

    function getTokenInfo(address _address)
        public
        view
        returns (TokenInfo memory)
    {
        TokenInfo memory info;
        IERC20 token = IERC20(_address);

        info.addr = _address;
        info.name = token.name();
        info.symbol = token.symbol();
        info.decimals = token.decimals();

        return info;
    }

    function getPoolInfo(address _pool) public view returns (Pool memory pool) {
        ITokenPool tokenPool = ITokenPool(_pool);
        address rewardsContract = tokenPool.rewardsContract();
        if (rewardsContract != address(0)) {
            IRewarder rewarder = IRewarder(rewardsContract);

            address[] memory rewardTokens = rewarder.rewardTokens(_pool);
            Reward[] memory rewards = new Reward[](rewardTokens.length);

            for (uint256 i = 0; i < rewardTokens.length; i++) {
                Reward memory reward;
                address token = rewardTokens[i];
                // (reward.startTime, reward.endTime) = rewarder.getRewardData(
                //     token
                // );
                reward.rewardToken = getTokenInfo(token);
                rewards[i] = reward;
            }
            pool.rewards = rewards;
            pool.stakedTokenTotal = tokenPool.stakedTokenTotal();
        }
        pool.stakingToken = getTokenInfo(tokenPool.poolToken());

        return pool;
    }

    function getPoolInfos(address[] memory _pools)
        public
        view
        returns (Pool[] memory)
    {
        Pool[] memory pools = new Pool[](_pools.length);
        for (uint256 i = 0; i < _pools.length; i++) {
            pools[i] = getPoolInfo(_pools[i]);
        }
        return pools;
    }

    function getUserInfo(address _user, address[] memory _pools)
        public
        view
        returns (UserInfo memory userInfo)
    {
        uint256 poolSize = _pools.length;
        UserPool[] memory userPools = new UserPool[](poolSize);
        for (uint256 i = 0; i < _pools.length; i++) {
            ITokenPool tokenPool = ITokenPool(_pools[i]);
            userPools[i].pool = _pools[i];
            userPools[i].staked = tokenPool.balanceOf(_user);

            address rewardsContract = tokenPool.rewardsContract();
            if (rewardsContract != address(0)) {
                (
                    address[] memory tokens,
                    uint256[] memory rewardAmounts
                ) = tokenPool.unclaimedRewards(_user);

                UserReward[] memory userRewards = new UserReward[](
                    tokens.length
                );

                for (uint256 j = 0; j < tokens.length; j++) {
                    // UserReward memory reward;
                    userRewards[j].rewardToken = tokens[j];
                    userRewards[j].unclaimedRewards = rewardAmounts[j];
                    // userRewards[j] = reward;
                }
                userPools[i].rewards = userRewards;
            }
        }
        userInfo.user = _user;
        userInfo.pools = userPools;
    }

    // function getApy() public view returns(uint256 apy) {
    //     // (,uint256 price,,,) = priceFeed.latestRoundData();

    // }

    // function getRewardInfo(address token) public view returns(uint64 startTime, uint64 endTime) {
    //     ITokenPool tokenPool = ITokenPool(_pool);
    //     address rewardsContract = tokenPool.rewardsContract();
    //     IRewarder rewarder = IRewarder(rewardsContract);

    //     (startTime, endTime) = rewarder.getRewardData(token);
    // }
}