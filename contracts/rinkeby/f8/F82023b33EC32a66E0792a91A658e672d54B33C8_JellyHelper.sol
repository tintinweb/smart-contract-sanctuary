pragma solidity 0.8.6;

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
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256 rewardPoints,
            uint256 rewardsPerSecond
        );

    function rewardTokens(address pool)
        external
        view
        returns (address[] memory);

    function tokenPools() external view returns(address[] memory);
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

interface Pair {
    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function getReserves()
        external
        view
        returns (
            uint112,
            uint112,
            uint32
        );
}

interface PriceRouter {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function WETH() external view returns (address);
}

contract PricesHelper {
    address public primaryRouterAddress;
    address public primaryFactoryAddress;
    address public secondaryRouterAddress;
    address public secondaryFactoryAddress;
    address public wethAddress;
    address public usdcAddress;
    PriceRouter primaryRouter;
    PriceRouter secondaryRouter;

    address ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address zeroAddress = 0x0000000000000000000000000000000000000000;

    constructor(
        address _primaryRouterAddress,
        address _primaryFactoryAddress,
        address _secondaryRouterAddress,
        address _secondaryFactoryAddress,
        address _usdcAddress
    ) {
        primaryRouterAddress = _primaryRouterAddress;
        primaryFactoryAddress = _primaryFactoryAddress;
        secondaryRouterAddress = _secondaryRouterAddress;
        secondaryFactoryAddress = _secondaryFactoryAddress;
        usdcAddress = _usdcAddress;
        primaryRouter = PriceRouter(primaryRouterAddress);
        secondaryRouter = PriceRouter(secondaryRouterAddress);
        wethAddress = primaryRouter.WETH();
    }

    function getNormalizedValueUsdc(address tokenAddress, uint256 amount)
        external
        view
        returns (uint256)
    {
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenDecimals = token.decimals();

        uint256 usdcDecimals = 6;
        uint256 decimalsAdjustment;
        if (tokenDecimals >= usdcDecimals) {
            decimalsAdjustment = tokenDecimals - usdcDecimals;
        } else {
            decimalsAdjustment = usdcDecimals - tokenDecimals;
        }
        uint256 price = getPriceUsdc(tokenAddress);
        uint256 value;
        if (decimalsAdjustment > 0) {
            value =
                (amount * price * (10**decimalsAdjustment)) /
                10**(decimalsAdjustment + tokenDecimals);
        } else {
            value = (amount * price) / 10**usdcDecimals;
        }
        return value;
    }

    // Uniswap/Sushiswap
    function getPriceUsdc(address tokenAddress) public view returns (uint256) {
        if (isLpToken(tokenAddress)) {
            return getLpTokenPriceUsdc(tokenAddress);
        }
        return getPriceFromRouterUsdc(tokenAddress);
    }

    function getPriceUsdcForUnknownToken(address tokenAddress) public view returns (uint256) {
        if (isLpToken(tokenAddress)) {
            return getLpTokenPriceUsdc(tokenAddress);
        }
        return getPriceFromRouterForUnknownToken(tokenAddress, usdcAddress);
    }

    function getPriceFromRouter(address token0Address, address token1Address)
        public
        view
        returns (uint256)
    {
        // Convert ETH address (0xEeee...) to WETH
        if (token0Address == ethAddress) {
            token0Address = wethAddress;
        }
        if (token1Address == ethAddress) {
            token1Address = wethAddress;
        }

        address[] memory path;
        uint8 numberOfJumps;
        bool inputTokenIsWeth = token0Address == wethAddress ||
            token1Address == wethAddress;
        if (inputTokenIsWeth) {
            // path = [token0, weth] or [weth, token1]
            numberOfJumps = 1;
            path = new address[](numberOfJumps + 1);
            path[0] = token0Address;
            path[1] = token1Address;
        } else {
            // path = [token0, weth, token1]
            numberOfJumps = 2;
            path = new address[](numberOfJumps + 1);
            path[0] = token0Address;
            path[1] = wethAddress;
            path[2] = token1Address;
        }

        IERC20 token0 = IERC20(token0Address);
        uint256 amountIn = 10**uint256(token0.decimals());
        uint256[] memory amountsOut;

        bool fallbackRouterExists = secondaryRouterAddress != zeroAddress;
        if (fallbackRouterExists) {
            try primaryRouter.getAmountsOut(amountIn, path) returns (
                uint256[] memory _amountsOut
            ) {
                amountsOut = _amountsOut;
            } catch {
                amountsOut = secondaryRouter.getAmountsOut(amountIn, path);
            }
        } else {
            amountsOut = primaryRouter.getAmountsOut(amountIn, path);
        }

        // Return raw price (without fees)
        uint256 amountOut = amountsOut[amountsOut.length - 1];
        uint256 feeBips = 30; // .3% per swap
        amountOut = (amountOut * 10000) / (10000 - (feeBips * numberOfJumps));
        return amountOut;
    }

    function getPriceFromRouterForUnknownToken(
        address token0Address,
        address token1Address
    ) public view returns (uint256) {
        // Convert ETH address (0xEeee...) to WETH
        if (token0Address == ethAddress) {
            token0Address = wethAddress;
        }
        if (token1Address == ethAddress) {
            token1Address = wethAddress;
        }

        address[] memory path;
        uint8 numberOfJumps;
        bool inputTokenIsWeth = token0Address == wethAddress ||
            token1Address == wethAddress;
        if (inputTokenIsWeth) {
            // path = [token0, weth] or [weth, token1]
            numberOfJumps = 1;
            path = new address[](numberOfJumps + 1);
            path[0] = token0Address;
            path[1] = token1Address;
        } else {
            // path = [token0, weth, token1]
            numberOfJumps = 2;
            path = new address[](numberOfJumps + 1);
            path[0] = token0Address;
            path[1] = wethAddress;
            path[2] = token1Address;
        }

        IERC20 token0 = IERC20(token0Address);
        uint256 amountIn = 10**uint256(token0.decimals());
        uint256[] memory amountsOut;

        bool fallbackRouterExists = secondaryRouterAddress != zeroAddress;
        if (fallbackRouterExists) {
            try primaryRouter.getAmountsOut(amountIn, path) returns (
                uint256[] memory _amountsOut
            ) {
                amountsOut = _amountsOut;
            } catch {
                try secondaryRouter.getAmountsOut(amountIn, path) returns (
                    uint256[] memory _amountsOut
                ) {
                    amountsOut = _amountsOut;
                } catch {
                    return 0;
                }
            }
        } else {
            try primaryRouter.getAmountsOut(amountIn, path) returns (
                uint256[] memory _amountsOut
            ) {
                amountsOut = _amountsOut;
            } catch {
                return 0;
            }
        }

        // Return raw price (without fees)
        uint256 amountOut = amountsOut[amountsOut.length - 1];
        uint256 feeBips = 30; // .3% per swap
        amountOut = (amountOut * 10000) / (10000 - (feeBips * numberOfJumps));
        return amountOut;
    }

    function getPriceFromRouterUsdc(address tokenAddress)
        public
        view
        returns (uint256)
    {
        return getPriceFromRouter(tokenAddress, usdcAddress);
    }

    function isLpToken(address tokenAddress) public view returns (bool) {
        Pair lpToken = Pair(tokenAddress);
        try lpToken.factory() {
            return true;
        } catch {
            return false;
        }
    }

    function getRouterForLpToken(address tokenAddress)
        public
        view
        returns (PriceRouter)
    {
        Pair lpToken = Pair(tokenAddress);
        address factoryAddress = lpToken.factory();
        if (factoryAddress == primaryFactoryAddress) {
            return primaryRouter;
        } else if (factoryAddress == secondaryFactoryAddress) {
            return secondaryRouter;
        }
        revert();
    }

    function getLpTokenTotalLiquidityUsdc(address tokenAddress)
        public
        view
        returns (uint256)
    {
        Pair pair = Pair(tokenAddress);
        address token0Address = pair.token0();
        address token1Address = pair.token1();
        IERC20 token0 = IERC20(token0Address);
        IERC20 token1 = IERC20(token1Address);
        uint8 token0Decimals = token0.decimals();
        uint8 token1Decimals = token1.decimals();
        uint256 token0Price = getPriceUsdc(token0Address);
        uint256 token1Price = getPriceUsdc(token1Address);
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        uint256 totalLiquidity = ((reserve0 / 10**token0Decimals) *
            token0Price) + ((reserve1 / 10**token1Decimals) * token1Price);
        return totalLiquidity;
    }

    function getLpTokenPriceUsdc(address tokenAddress)
        public
        view
        returns (uint256)
    {
        Pair pair = Pair(tokenAddress);
        uint256 totalLiquidity = getLpTokenTotalLiquidityUsdc(tokenAddress);
        uint256 totalSupply = pair.totalSupply();
        uint8 pairDecimals = pair.decimals();
        uint256 pricePerLpTokenUsdc = (totalLiquidity * 10**pairDecimals) /
            totalSupply;
        return pricePerLpTokenUsdc;
    }
}

contract JellyHelper is PricesHelper {
    struct TokenInfo {
        address addr;
        string name;
        string symbol;
        uint256 decimals;
    }

    struct Pool {
        address poolAddress;
        uint256 stakedTokenTotal;
        uint256 stakingTokenPrice;
        TokenInfo stakingToken;
        TokenInfo token0;
        TokenInfo token1;
        bool isLpToken;
        Reward[] rewards;
    }

    struct Reward {
        uint256 startTime;
        uint256 endTime;
        uint256 rewardPoints;
        uint256 rewardsPerSecond;
        uint256 rewardTokenPrice;
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

    constructor(
        address _primaryRouterAddress,
        address _primaryFactoryAddress,
        address _secondaryRouterAddress,
        address _secondaryFactoryAddress,
        address _usdcAddress
    )
        PricesHelper(
            _primaryRouterAddress,
            _primaryFactoryAddress,
            _secondaryRouterAddress,
            _secondaryFactoryAddress,
            _usdcAddress
        )
    {}

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
                (
                    reward.startTime,
                    reward.endTime,
                    reward.rewardPoints,
                    reward.rewardsPerSecond
                ) = rewarder.getRewardData(token);
                reward.rewardTokenPrice = getPriceUsdcForUnknownToken(token);

                // try getPriceUsdc(token) returns (uint256 tokenPrice) {
                //     reward.rewardTokenPrice = tokenPrice;
                // } catch {
                //     reward.rewardTokenPrice = 0;
                // }

                rewards[i] = reward;
            }
            pool.rewards = rewards;
            pool.stakedTokenTotal = tokenPool.stakedTokenTotal();
        }
        pool.poolAddress = _pool;
        address stakingToken = tokenPool.poolToken();
        pool.stakingToken = getTokenInfo(stakingToken);
        if (isLpToken(stakingToken)) {
            pool.token0 = getTokenInfo(Pair(stakingToken).token0());
            pool.token1 = getTokenInfo(Pair(stakingToken).token1());
            pool.isLpToken = true;
        }

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

    // function getRewardInfo(address token) public view returns(uint64 startTime, uint64 endTime) {
    //     ITokenPool tokenPool = ITokenPool(_pool);
    //     address rewardsContract = tokenPool.rewardsContract();
    //     IRewarder rewarder = IRewarder(rewardsContract);

    //     (startTime, endTime) = rewarder.getRewardData(token);
    // }

    function getRewardInfo(address _reward) public view returns(address[] memory pools) {
        pools = IRewarder(_reward).tokenPools();
    }
}