/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

pragma solidity ^0.5.17;

interface ILpStaking {
    function feeWithdraw(address to) external;
    function setFeeRate(uint256 _feeRate) external;
    function setEmergencyStop(bool _emergencyStop) external;
    function getAccumulateFee() external view returns (uint256);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IStakingRewardsWbtc {
    function notifyRewardAmount(uint256 reward, uint256 duration) external;
}


contract MarsLpStakingController {
    bool internal initialized;
    // 不需要owner，不需要operator的设置接口，私钥泄露了直接更新实现合约即可
    address public operator;
    address public wbtc;
    address public weth;
    address public marsStakingForWbtc;
    address public wbtc_weth_pair;
    address[] public lpStakings;
    mapping(address => address) stakingRewardToken;

    function initialize(address _operator) public {
        require(!initialized, "already initialized");
        initialized = true;
        operator = _operator;
        // mainnet
        wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
        weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        wbtc_weth_pair = 0xBb2b8038a1640196FbE3e38816F3e67Cba72D940;
        marsStakingForWbtc = 0x51a710218eC2ba2Ac459ee28ec37c6dF7fe18E11;
        // testnet
//        wbtc = 0x5F2D686E3141Cd1E16b0FE1e80f5CF8e128351aB;
//        weth = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
//        wbtc_weth_pair = 0x393244f2D96035c04aF658E0C7e70a3dd174e6B2;
//        marsStakingForWbtc = 0x0bEC73826299C21fD4F6D10E485C02A670aa6bb7;
    }

    function setLpStakingFeeRate(address staking, uint256 _feeRate) external onlyOperator {
        require(stakingRewardToken[staking] != address(0), "not added.");
        ILpStaking(staking).setFeeRate(_feeRate);
    }

    function addStakingAndRewardToken(address staking, address rewardToken) external onlyOperator {
        require(stakingRewardToken[staking] == address(0), "already added.");
        lpStakings.push(staking);
        stakingRewardToken[staking] = rewardToken;
    }

    // minimalWbtcPrice 为 btc / eth 价格. 当前价格下输入30即可
    function distributeReward(uint256 minimalWbtcPrice) external onlyOperator {
        uint256 totalWbtc = 0;
        for (uint256 i=0; i<lpStakings.length; i++) {
            address lpStaking = lpStakings[i];
            address rewardToken = stakingRewardToken[lpStaking];
            uint256 accumulateFee = ILpStaking(lpStaking).getAccumulateFee();
            if (rewardToken == wbtc) {
                ILpStaking(lpStaking).feeWithdraw(marsStakingForWbtc);
                totalWbtc += accumulateFee;
            } else {
                ILpStaking(lpStaking).feeWithdraw(address(this));
                IWETH(weth).deposit.value(accumulateFee)();
                assert(IWETH(weth).transfer(wbtc_weth_pair, accumulateFee));
                (uint256 wbtcReserve, uint256 wethReserve, ) = IUniswapV2Pair(wbtc_weth_pair).getReserves();
                uint256 amountOut = getAmountOut(accumulateFee, wethReserve, wbtcReserve);
                uint256 actualPrice = accumulateFee / 1e10 / amountOut;
                require(actualPrice > minimalWbtcPrice, "price move");
                IUniswapV2Pair(wbtc_weth_pair).swap(amountOut, 0, marsStakingForWbtc, new bytes(0));
                totalWbtc += amountOut;
            }
        }

        if (totalWbtc > 0) {
            IStakingRewardsWbtc(marsStakingForWbtc).notifyRewardAmount(totalWbtc, 864000);
        }
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        require(amountIn > 0, 'MarsStakingController: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'MarsStakingController: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function() payable external {
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "!operator");
        _;
    }
}