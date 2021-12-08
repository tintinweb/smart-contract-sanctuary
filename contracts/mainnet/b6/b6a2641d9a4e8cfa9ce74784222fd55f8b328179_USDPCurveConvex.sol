//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../utils/Constants.sol";
import "./BaseCurveConvex2.sol";

contract USDPCurveConvex is BaseCurveConvex2 {
    constructor()
        BaseCurveConvex2(
            Constants.CRV_USDP_ADDRESS,
            Constants.CRV_USDP_LP_ADDRESS,
            Constants.CVX_USDP_REWARDS_ADDRESS,
            Constants.CVX_USDP_PID,
            Constants.USDP_ADDRESS,
            Constants.CVX_USDP_EXTRA_ADDRESS,
            Constants.USDP_EXTRA_ADDRESS,
            Constants.USDP_EXTRA_PAIR_ADDRESS
        )
    {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Constants {
    bytes32 internal constant USDC_TICKER = "usdc";
    bytes32 internal constant USDT_TICKER = "usdt";
    bytes32 internal constant DAI_TICKER = "dai";
    bytes32 internal constant CRV_TICKER = "a3CRV";

    uint256 internal constant CVX_BUSD_PID = 3;
    uint256 internal constant CVX_SUSD_PID = 4;
    uint256 internal constant CVX_USDK_PID = 12;
    uint256 internal constant CVX_USDN_PID = 13;
    uint256 internal constant CVX_MUSD_PID = 14;
    uint256 internal constant CVX_RSV_PID = 15;
    uint256 internal constant CVX_DUSD_PID = 17;
    uint256 internal constant CVX_AAVE_PID = 24;
    uint256 internal constant CVX_USDP_PID = 28;
    uint256 internal constant CVX_IRONBANK_PID = 29;
    uint256 internal constant CVX_TUSD_PID = 31;
    uint256 internal constant CVX_FRAX_PID = 32;
    uint256 internal constant CVX_LUSD_PID = 33;
    uint256 internal constant CVX_BUSDV2_PID = 34;
    uint256 internal constant CVX_MIM_PID = 40;
    uint256 internal constant CVX_OUSD_PID = 56;
    uint256 internal constant TRADE_DEADLINE = 2000;

    address internal constant CVX_ADDRESS =
        0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address internal constant CRV_ADDRESS =
        0xD533a949740bb3306d119CC777fa900bA034cd52;
    address internal constant USDC_ADDRESS =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT_ADDRESS =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address internal constant DAI_ADDRESS =
        0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant TUSD_ADDRESS =
        0x0000000000085d4780B73119b644AE5ecd22b376;
    address internal constant SUSD_ADDRESS =
        0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    address internal constant BUSD_ADDRESS =
        0x4Fabb145d64652a948d72533023f6E7A623C7C53;
    address internal constant OUSD_ADDRESS =
        0x2A8e1E676Ec238d8A992307B495b45B3fEAa5e86;
    address internal constant MUSD_ADDRESS =
        0xe2f2a5C287993345a840Db3B0845fbC70f5935a5;
    address internal constant MIM_ADDRESS =
        0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3;
    address internal constant DUSD_ADDRESS =
        0x5BC25f649fc4e26069dDF4cF4010F9f706c23831;
    address internal constant LUSD_ADDRESS =
        0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
    address internal constant USDP_ADDRESS =
        0x1456688345527bE1f37E9e627DA0837D6f08C925;
    address internal constant USDN_ADDRESS =
        0x674C6Ad92Fd080e4004b2312b45f796a192D27a0;
    address internal constant USDK_ADDRESS =
        0x1c48f86ae57291F7686349F12601910BD8D470bb;
    address internal constant FRAX_ADDRESS =
        0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address internal constant RSV_ADDRESS =
        0x196f4727526eA7FB1e17b2071B3d8eAA38486988;
    address internal constant WETH_ADDRESS =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant SUSHI_ROUTER_ADDRESS =
        0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address internal constant SUSHI_CRV_WETH_ADDRESS =
        0x58Dc5a51fE44589BEb22E8CE67720B5BC5378009;
    address internal constant SUSHI_WETH_CVX_ADDRESS =
        0x05767d9EF41dC40689678fFca0608878fb3dE906;
    address internal constant SUSHI_WETH_USDT_ADDRESS =
        0x06da0fd433C1A5d7a4faa01111c044910A184553;
    address internal constant CVX_BOOSTER_ADDRESS =
         0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address internal constant CRV_3POOL_ADDRESS =
        0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address internal constant CRV_3POOL_LP_ADDRESS =
        0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address internal constant CRV_AAVE_ADDRESS =
        0xDeBF20617708857ebe4F679508E7b7863a8A8EeE;
    address internal constant CRV_AAVE_LP_ADDRESS =
        0xFd2a8fA60Abd58Efe3EeE34dd494cD491dC14900;
    address internal constant CVX_AAVE_REWARDS_ADDRESS =
        0xE82c1eB4BC6F92f85BF7EB6421ab3b882C3F5a7B;
    address internal constant CVX_AAVE_EXTRA_ADDRESS =
        0x0000000000000000000000000000000000000000;
    address internal constant AAVE_EXTRA_ADDRESS =
        0x0000000000000000000000000000000000000000;
    address internal constant AAVE_EXTRA_PAIR_ADDRESS =
        0x0000000000000000000000000000000000000000;
    address internal constant CRV_IRONBANK_ADDRESS =
        0x2dded6Da1BF5DBdF597C45fcFaa3194e53EcfeAF;
    address internal constant CRV_IRONBANK_LP_ADDRESS =
        0x5282a4eF67D9C33135340fB3289cc1711c13638C;
    address internal constant CVX_IRONBANK_REWARDS_ADDRESS =
        0x3E03fFF82F77073cc590b656D42FceB12E4910A8;
    address internal constant CRV_TUSD_ADDRESS =
        0xEcd5e75AFb02eFa118AF914515D6521aaBd189F1;
    address internal constant CRV_TUSD_LP_ADDRESS =
        0xEcd5e75AFb02eFa118AF914515D6521aaBd189F1;
    address internal constant CVX_TUSD_REWARDS_ADDRESS =
        0x308b48F037AAa75406426dACFACA864ebd88eDbA;
    address internal constant CRV_SUSD_ADDRESS =
        0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;
    address internal constant CRV_SUSD_LP_ADDRESS =
        0xC25a3A3b969415c80451098fa907EC722572917F;
    address internal constant CVX_SUSD_REWARDS_ADDRESS =
        0x22eE18aca7F3Ee920D01F25dA85840D12d98E8Ca;
    address internal constant CVX_SUSD_EXTRA_ADDRESS =
        0x81fCe3E10D12Da6c7266a1A169c4C96813435263;
    address internal constant SUSD_EXTRA_ADDRESS =
        0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
    address internal constant SUSD_EXTRA_PAIR_ADDRESS =
        0xA1d7b2d891e3A1f9ef4bBC5be20630C2FEB1c470;
    address internal constant CRV_USDK_ADDRESS =
        0x3E01dD8a5E1fb3481F0F589056b428Fc308AF0Fb;
    address internal constant CRV_USDK_LP_ADDRESS =
        0x97E2768e8E73511cA874545DC5Ff8067eB19B787;
    address internal constant CVX_USDK_REWARDS_ADDRESS =
        0xa50e9071aCaD20b31cd2bbe4dAa816882De82BBe;
    address internal constant CRV_USDP_ADDRESS =
        0x42d7025938bEc20B69cBae5A77421082407f053A;
    address internal constant CRV_USDP_LP_ADDRESS =
        0x7Eb40E450b9655f4B3cC4259BCC731c63ff55ae6;
    address internal constant CVX_USDP_REWARDS_ADDRESS =
        0x24DfFd1949F888F91A0c8341Fc98a3F280a782a8;
    address internal constant CVX_USDP_EXTRA_ADDRESS =
        0x5F91615268bE6b4aDD646b2560785B8F17dccBb4;
    address internal constant USDP_EXTRA_ADDRESS =
        0x92E187a03B6CD19CB6AF293ba17F2745Fd2357D5;
    address internal constant USDP_EXTRA_PAIR_ADDRESS =
        0x69aa90C6cD099BF383Bd9A0ac29E61BbCbF3b8D9;
    address internal constant CRV_BUSD_ADDRESS =
        0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27;
    address internal constant CRV_BUSD_LP_ADDRESS =
        0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B;
    address internal constant CVX_BUSD_REWARDS_ADDRESS =
        0x602c4cD53a715D8a7cf648540FAb0d3a2d546560;
    address internal constant CRV_BUSDV2_ADDRESS =
        0x4807862AA8b2bF68830e4C8dc86D0e9A998e085a;
    address internal constant CRV_BUSDV2_LP_ADDRESS =
        0x4807862AA8b2bF68830e4C8dc86D0e9A998e085a;
    address internal constant CVX_BUSDV2_REWARDS_ADDRESS =
        0xbD223812d360C9587921292D0644D18aDb6a2ad0;
    address internal constant CRV_OUSD_ADDRESS =
        0x87650D7bbfC3A9F10587d7778206671719d9910D;
    address internal constant CRV_OUSD_LP_ADDRESS =
        0x87650D7bbfC3A9F10587d7778206671719d9910D;
    address internal constant CRV_OUSD_EXTRA_ADDRESS =
        0x8A05801c1512F6018e450b0F69e9Ca7b985fCea3;
    address internal constant OUSD_EXTRA_ADDRESS =
        0x8207c1FfC5B6804F6024322CcF34F29c3541Ae26;
    address internal constant OUSD_EXTRA_PAIR_ADDRESS =
        0x72ea6Ca0D47b337f1EA44314d9d90E2A897eDaF5;
    address internal constant CVX_OUSD_REWARDS_ADDRESS =
        0x7D536a737C13561e0D2Decf1152a653B4e615158;
    address internal constant CRV_USDN_ADDRESS =
        0x0f9cb53Ebe405d49A0bbdBD291A65Ff571bC83e1;
    address internal constant CRV_USDN_LP_ADDRESS =
        0x4f3E8F405CF5aFC05D68142F3783bDfE13811522;
    address internal constant CVX_USDN_REWARDS_ADDRESS =
        0x4a2631d090e8b40bBDe245e687BF09e5e534A239;
    address internal constant CRV_LUSD_ADDRESS =
        0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA;
    address internal constant CRV_LUSD_LP_ADDRESS =
        0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA;
    address internal constant CVX_LUSD_REWARDS_ADDRESS =
        0x2ad92A7aE036a038ff02B96c88de868ddf3f8190;
    address internal constant CVX_LUSD_EXTRA_ADDRESS =
        0x0000000000000000000000000000000000000000;
    address internal constant LUSD_EXTRA_ADDRESS =
        0x0000000000000000000000000000000000000000;
    address internal constant LUSD_EXTRA_PAIR_ADDRESS =
        0x0000000000000000000000000000000000000000;
    address internal constant CRV_MUSD_ADDRESS =
        0x8474DdbE98F5aA3179B3B3F5942D724aFcdec9f6;
    address internal constant CRV_MUSD_LP_ADDRESS =
        0x1AEf73d49Dedc4b1778d0706583995958Dc862e6;
    address internal constant CVX_MUSD_REWARDS_ADDRESS =
        0xDBFa6187C79f4fE4Cda20609E75760C5AaE88e52;
    address internal constant CVX_MUSD_EXTRA_ADDRESS =
        0x93A5C724c4992FCBDA6b96F06fa15EB8B5c485b7;
    address internal constant MUSD_EXTRA_ADDRESS =
        0xa3BeD4E1c75D00fa6f4E5E6922DB7261B5E9AcD2;
    address internal constant MUSD_EXTRA_PAIR_ADDRESS =
        0x663242D053057f317A773D7c262B700616d0b9A0;
    address internal constant CRV_DUSD_ADDRESS =
        0x8038C01A0390a8c547446a0b2c18fc9aEFEcc10c;
    address internal constant CRV_DUSD_LP_ADDRESS =
        0x3a664Ab939FD8482048609f652f9a0B0677337B9;
    address internal constant CVX_DUSD_REWARDS_ADDRESS =
        0x1992b82A8cCFC8f89785129D6403b13925d6226E;
    address internal constant CVX_DUSD_EXTRA_ADDRESS =
        0x666F8eEE6FD6839853993977CC86a7A51425673C;
    address internal constant DUSD_EXTRA_ADDRESS =
        0x20c36f062a31865bED8a5B1e512D9a1A20AA333A;
    address internal constant DUSD_EXTRA_PAIR_ADDRESS =
        0x663242D053057f317A773D7c262B700616d0b9A0;
    address internal constant CRV_RSV_ADDRESS =
        0xC18cC39da8b11dA8c3541C598eE022258F9744da;
    address internal constant CRV_RSV_LP_ADDRESS =
        0xC2Ee6b0334C261ED60C72f6054450b61B8f18E35;
    address internal constant CVX_RSV_REWARDS_ADDRESS =
        0xedfCCF611D7c40F43e77a1340cE2C29EEEC27205;
    address internal constant CVX_RSV_EXTRA_ADDRESS =
        0x0000000000000000000000000000000000000000;
    address internal constant RSV_EXTRA_ADDRESS =
        0x0000000000000000000000000000000000000000;
    address internal constant RSV_EXTRA_PAIR_ADDRESS =
        0x0000000000000000000000000000000000000000;
    address internal constant CRV_FRAX_ADDRESS =
        0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;
    address internal constant CRV_FRAX_LP_ADDRESS =
        0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;
    address internal constant CVX_FRAX_REWARDS_ADDRESS =
        0xB900EF131301B307dB5eFcbed9DBb50A3e209B2e;
    address internal constant CVX_FRAX_EXTRA_ADDRESS =
        0x0000000000000000000000000000000000000000;
    address internal constant FRAX_EXTRA_ADDRESS =
        0x0000000000000000000000000000000000000000;
    address internal constant FRAX_EXTRA_PAIR_ADDRESS =
        0x0000000000000000000000000000000000000000;
    address internal constant CRV_MIM_ADDRESS =
        0x5a6A4D54456819380173272A5E8E9B9904BdF41B;
    address internal constant CRV_MIM_LP_ADDRESS =
        0x5a6A4D54456819380173272A5E8E9B9904BdF41B;
    address internal constant CVX_MIM_REWARDS_ADDRESS =
        0xFd5AbF66b003881b88567EB9Ed9c651F14Dc4771;
    address internal constant CVX_MIM_EXTRA_ADDRESS =
        0x69a92f1656cd2e193797546cFe2EaF32EACcf6f7;
    address internal constant MIM_EXTRA_ADDRESS =
        0x090185f2135308BaD17527004364eBcC2D37e5F6;
    address internal constant MIM_EXTRA_PAIR_ADDRESS =
        0xb5De0C3753b6E1B4dBA616Db82767F17513E6d4E;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


import "../utils/Constants.sol";
import "../interfaces/ICurvePool.sol";
import "../interfaces/ICurvePool2.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapRouter.sol";
import "../interfaces/IConvexBooster.sol";
import "../interfaces/IConvexMinter.sol";
import "../interfaces/IConvexRewards.sol";
import "../interfaces/IZunami.sol";

contract BaseCurveConvex2 is Context, Ownable {
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for IConvexMinter;

    uint256 private constant DENOMINATOR = 1e18;
    uint256 private constant USD_MULTIPLIER = 1e12;
    uint256 private constant DEPOSIT_DENOMINATOR = 10000; // 100%
    uint256 public minDepositAmount = 9975; // 100% = 10000

    uint256 private wManagementFee = 0;

    address[3] public tokens;
    uint256[3] public managementFees;

    ICurvePool public pool3;
    ICurvePool2 public pool;
    IERC20Metadata public pool3LP;
    IERC20Metadata public crv;
    IConvexMinter public cvx;
    IERC20Metadata public poolLP;
    IERC20Metadata public token;
    IUniswapRouter public router;
    IUniswapV2Pair public crvweth;
    IUniswapV2Pair public wethcvx;
    IUniswapV2Pair public wethusdt;
    IConvexBooster public booster;
    IConvexRewards public crvRewards;
    IERC20Metadata public extraToken;
    IUniswapV2Pair public extraPair;
    IConvexRewards public extraRewards;
    IZunami public zunami;
    uint256 public cvxPoolPID;

    event SellRewards(uint256 cvxBalance, uint256 crvBalance, uint256 extraBalance);

    constructor(
        address poolAddr,
        address poolLPAddr,
        address rewardsAddr,
        uint256 poolPID,
        address tokenAddr,
        address extraRewardsAddr,
        address extraTokenAddr,
        address extraTokenPairAddr
    ) {
        pool = ICurvePool2(poolAddr);
        pool3 = ICurvePool(Constants.CRV_3POOL_ADDRESS);
        poolLP = IERC20Metadata(poolLPAddr);
        pool3LP = IERC20Metadata(Constants.CRV_3POOL_LP_ADDRESS);
        crv = IERC20Metadata(Constants.CRV_ADDRESS);
        cvx = IConvexMinter(Constants.CVX_ADDRESS);
        crvweth = IUniswapV2Pair(Constants.SUSHI_CRV_WETH_ADDRESS);
        wethcvx = IUniswapV2Pair(Constants.SUSHI_WETH_CVX_ADDRESS);
        wethusdt = IUniswapV2Pair(Constants.SUSHI_WETH_USDT_ADDRESS);
        booster = IConvexBooster(Constants.CVX_BOOSTER_ADDRESS);
        crvRewards = IConvexRewards(rewardsAddr);
        router = IUniswapRouter(Constants.SUSHI_ROUTER_ADDRESS);
        cvxPoolPID = poolPID;
        token = IERC20Metadata(tokenAddr);
        extraToken = IERC20Metadata(extraTokenAddr);
        extraPair = IUniswapV2Pair(extraTokenPairAddr);
        extraRewards = IConvexRewards(extraRewardsAddr);
        tokens[0] = Constants.DAI_ADDRESS;
        tokens[1] = Constants.USDC_ADDRESS;
        tokens[2] = Constants.USDT_ADDRESS;
    }

    modifier onlyZunami() {
        require(
            _msgSender() == address(zunami),
            "CurvetokenConvex: must be called by Zunami contract"
        );
        _;
    }

    function setZunami(address zunamiAddr) external onlyOwner {
        zunami = IZunami(zunamiAddr);
    }

    function totalHoldings() public view virtual returns (uint256) {
        uint256 lpBalance = crvRewards.balanceOf(address(this));
        uint256 lpPrice = pool.get_virtual_price();
        (uint112 reserve0, uint112 reserve1,) = wethcvx.getReserves();
        uint256 cvxPrice = (reserve1 * DENOMINATOR) / reserve0;
        (reserve0, reserve1,) = crvweth.getReserves();
        uint256 crvPrice = (reserve0 * DENOMINATOR) / reserve1;
        (reserve0, reserve1,) = wethusdt.getReserves();
        uint256 ethPrice = (reserve1 * USD_MULTIPLIER * DENOMINATOR) / reserve0;
        crvPrice = (crvPrice * ethPrice) / DENOMINATOR;
        cvxPrice = (cvxPrice * ethPrice) / DENOMINATOR;
        uint256 sum = 0;
        if (address(extraPair) != address(0)) {
            uint256 extraTokenPrice = 0;
            (reserve0, reserve1,) = extraPair.getReserves();
            for (uint8 i = 0; i < 3; ++i) {
                if (extraPair.token0() == tokens[i]) {
                    if (i > 0) {
                        extraTokenPrice =
                        (reserve0 * USD_MULTIPLIER * DENOMINATOR) /
                        reserve1;
                    } else {
                        extraTokenPrice = (reserve0 * DENOMINATOR) / reserve1;
                    }
                }
                if (extraPair.token1() == tokens[i]) {
                    if (i > 0) {
                        extraTokenPrice =
                        (reserve1 * USD_MULTIPLIER * DENOMINATOR) /
                        reserve0;
                    } else {
                        extraTokenPrice = (reserve1 * DENOMINATOR) / reserve0;
                    }
                }
            }
            if (extraTokenPrice == 0) {
                if (extraPair.token0() == Constants.WETH_ADDRESS) {
                    extraTokenPrice =
                    (((reserve0 * DENOMINATOR) / reserve1) * ethPrice) /
                    DENOMINATOR;
                } else {
                    extraTokenPrice =
                    (((reserve1 * DENOMINATOR) / reserve0) * ethPrice) /
                    DENOMINATOR;
                }
            }
            sum +=
            (extraTokenPrice *
            (extraRewards.earned(address(this)) +
            extraToken.balanceOf(address(this)))) /
            DENOMINATOR;
        }
        uint256 decimalsMultiplier = 1;
        if (token.decimals() < 18) {
            decimalsMultiplier = 10 ** (18 - token.decimals());
        }
        sum += token.balanceOf(address(this)) * decimalsMultiplier;
        for (uint8 i = 0; i < 3; ++i) {
            decimalsMultiplier = 1;
            if (IERC20Metadata(tokens[i]).decimals() < 18) {
                decimalsMultiplier =
                10 ** (18 - IERC20Metadata(tokens[i]).decimals());
            }
            sum +=
            IERC20Metadata(tokens[i]).balanceOf(address(this)) *
            decimalsMultiplier;
        }
        return
        sum +
        (lpBalance *
        lpPrice +
        crvPrice *
        (crvRewards.earned(address(this)) +
        crv.balanceOf(address(this))) +
        cvxPrice *
        ((crvRewards.earned(address(this)) *
        (cvx.totalCliffs() -
        cvx.totalSupply() /
        cvx.reductionPerCliff())) /
        cvx.totalCliffs() +
        cvx.balanceOf(address(this)))) /
        DENOMINATOR;
    }

    function deposit(uint256[3] memory amounts) external virtual onlyZunami returns (bool){
        uint256[3] memory _amounts;
        for (uint8 i = 0; i < 3; ++i) {
            if (IERC20Metadata(tokens[i]).decimals() < 18) {
                _amounts[i] = amounts[i] * 10 ** (18 - IERC20Metadata(tokens[i]).decimals());
            } else {
                _amounts[i] = amounts[i];
            }
        }
        uint256 amountsMin = (_amounts[0] + _amounts[1] + _amounts[2]) * minDepositAmount / DEPOSIT_DENOMINATOR;
        uint256 lpPrice = pool3.get_virtual_price();
        uint256 depositedLp = pool3.calc_token_amount(amounts, true);
        if (depositedLp * lpPrice / 1e18 >= amountsMin) {
            for (uint8 i = 0; i < 3; ++i) {
                IERC20Metadata(tokens[i]).safeIncreaseAllowance(
                    address(pool3),
                    amounts[i]
                );
            }
            pool3.add_liquidity(amounts, 0);
            uint256[2] memory amounts2;
            amounts2[1] = pool3LP.balanceOf(address(this));
            pool3LP.safeIncreaseAllowance(address(pool), amounts2[1]);
            uint256 poolLPs = pool.add_liquidity(amounts2, 0);
            poolLP.safeApprove(address(booster), poolLPs);
            booster.depositAll(cvxPoolPID, true);
            return (true);
        } else {
            return (false);
        }
    }

    function withdraw(
        address depositor,
        uint256 lpShares,
        uint256[3] memory minAmounts
    ) external virtual onlyZunami returns (bool){
        uint256[2] memory minAmounts2;
        minAmounts2[1] = pool3.calc_token_amount(minAmounts, false);
        uint256 depositedShare = (crvRewards.balanceOf(address(this)) *
        lpShares) / zunami.totalSupply();

        if (depositedShare < pool.calc_token_amount(minAmounts2, false)) {
            return false;
        }

        crvRewards.withdrawAndUnwrap(depositedShare, true);
        sellCrvCvx();
        if (address(extraToken) != address(0)) {
            sellExtraToken();
        }

        uint256[] memory userBalances = new uint256[](3);
        uint256[] memory prevBalances = new uint256[](3);
        for (uint8 i = 0; i < 3; ++i) {
            prevBalances[i] = IERC20Metadata(tokens[i]).balanceOf(
                address(this)
            );
            userBalances[i] =
            (prevBalances[i] * lpShares) /
            zunami.totalSupply();
        }
        uint256 prevCrv3Balance = pool3LP.balanceOf(address(this));
        pool.remove_liquidity(depositedShare, minAmounts2);
        sellToken();
        uint256 crv3LiqAmount = pool3LP.balanceOf(address(this)) -
        prevCrv3Balance;
        pool3.remove_liquidity(crv3LiqAmount, minAmounts);
        uint256[3] memory liqAmounts;
        for (uint256 i = 0; i < 3; ++i) {
            liqAmounts[i] =
            IERC20Metadata(tokens[i]).balanceOf(address(this)) -
            prevBalances[i];
        }

        uint256 userDeposit = zunami.deposited(depositor);
        uint256 earned = 0;
        for (uint8 i = 0; i < 3; ++i) {
            uint256 decimalsMultiplier = 1;
            if (IERC20Metadata(tokens[i]).decimals() < 18) {
                decimalsMultiplier =
                10 ** (18 - IERC20Metadata(tokens[i]).decimals());
            }
            earned += (liqAmounts[i] + userBalances[i]) * decimalsMultiplier;
        }

        wManagementFee = zunami.calcManagementFee(
            (earned < userDeposit ? 0 : earned - userDeposit)
        );
        for (uint8 i = 0; i < 3; ++i) {
            uint256 managementFeePerAsset = (wManagementFee *
            (liqAmounts[i] + userBalances[i])) / earned;
            managementFees[i] += managementFeePerAsset;

            IERC20Metadata(tokens[i]).safeTransfer(
                depositor,
                liqAmounts[i] + userBalances[i] - managementFeePerAsset
        );
        }
        return true;
    }

    function claimManagementFees() external virtual onlyZunami {
        for (uint8 i = 0; i < 3; ++i) {
            uint256 managementFee = managementFees[i];
            managementFees[i] = 0;
            IERC20Metadata(tokens[i]).safeTransfer(owner(), managementFee);
        }
    }

    function sellCrvCvx() public virtual {
        uint256 cvxBalance = cvx.balanceOf(address(this));
        uint256 crvBalance = crv.balanceOf(address(this));
        if (cvxBalance == 0 || crvBalance == 0) {return;}
        cvx.safeApprove(address(router), cvxBalance);
        crv.safeApprove(address(router), crvBalance);

        address[] memory path = new address[](3);
        path[0] = Constants.CVX_ADDRESS;
        path[1] = Constants.WETH_ADDRESS;
        path[2] = Constants.USDT_ADDRESS;
        router.swapExactTokensForTokens(
            cvxBalance,
            0,
            path,
            address(this),
            block.timestamp + Constants.TRADE_DEADLINE
        );

        path[0] = Constants.CRV_ADDRESS;
        path[1] = Constants.WETH_ADDRESS;
        path[2] = Constants.USDT_ADDRESS;
        router.swapExactTokensForTokens(
            crvBalance,
            0,
            path,
            address(this),
            block.timestamp + Constants.TRADE_DEADLINE
        );
        emit SellRewards(cvxBalance, crvBalance, 0);
    }

    function sellToken() public virtual {
        uint256 sellBal = token.balanceOf(address(this));
        if (sellBal > 0) {
            token.safeApprove(address(pool), sellBal);
            pool.exchange_underlying(0, 3, sellBal, 0);
        }
    }

    function sellExtraToken() public virtual {
        uint256 extraBalance = extraToken.balanceOf(address(this));
        if (extraBalance == 0) {return;}
        extraToken.safeApprove(
            address(router),
            extraToken.balanceOf(address(this))
        );

        if (
            extraPair.token0() == Constants.WETH_ADDRESS ||
            extraPair.token1() == Constants.WETH_ADDRESS
        ) {
            address[] memory path = new address[](3);
            path[0] = address(extraToken);
            path[1] = Constants.WETH_ADDRESS;
            path[2] = Constants.USDT_ADDRESS;
            router.swapExactTokensForTokens(
                extraBalance,
                0,
                path,
                address(this),
                block.timestamp + Constants.TRADE_DEADLINE
            );
            return;
        }
        address[] memory path2 = new address[](2);
        path2[0] = address(extraToken);
        for (uint8 i = 0; i < 3; ++i) {
            if (
                extraPair.token0() == tokens[i] ||
                extraPair.token1() == tokens[i]
            ) {
                path2[1] = tokens[i];
            }
        }
        router.swapExactTokensForTokens(
            extraBalance,
            0,
            path2,
            address(this),
            block.timestamp + Constants.TRADE_DEADLINE
        );
        emit SellRewards(0, 0, extraBalance);
    }

    function withdrawAll() external virtual onlyZunami {
        crvRewards.withdrawAllAndUnwrap(true);
        sellCrvCvx();
        if (address(extraToken) != address(0)) {
            sellExtraToken();
        }

        uint256[2] memory minAmounts2;
        uint256[3] memory minAmounts;
        pool.remove_liquidity(poolLP.balanceOf(address(this)), minAmounts2);
        sellToken();
        pool3.remove_liquidity(pool3LP.balanceOf(address(this)), minAmounts);

        for (uint8 i = 0; i < 3; ++i) {
            IERC20Metadata(tokens[i]).safeTransfer(
                _msgSender(),
                IERC20Metadata(tokens[i]).balanceOf(address(this)) -
                managementFees[i]
            );
        }
    }

    function updateMinDepositAmount(uint256 _minDepositAmount) public onlyOwner {
        require(_minDepositAmount > 0 && _minDepositAmount <= 10000, "Wrong amount!");
        minDepositAmount = _minDepositAmount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICurvePool {
    function add_liquidity(uint256[3] memory amounts, uint256 minMintAmount)
        external;

    function remove_liquidity(uint256 burnAmount, uint256[3] memory minAmounts)
        external;

    function exchange(
        int128 i,
        int128 j,
        uint256 input,
        uint256 minOutput
    ) external;

    function calc_token_amount(uint256[3] memory amounts, bool isDeposit)
        external
        view
        returns (uint256);

    function get_virtual_price() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICurvePool2 {
    function add_liquidity(uint256[2] memory amounts, uint256 minMintAmount)
        external
        returns (uint256);

    function remove_liquidity(uint256 burnAmount, uint256[2] memory minAmounts)
        external
        returns (uint256[2] memory);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 input,
        uint256 minOutput
    ) external returns (uint256);

    function calc_token_amount(uint256[2] memory amounts, bool isDeposit)
        external
        view
        returns (uint256);

    function get_virtual_price() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112,
            uint112,
            uint32
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IConvexBooster {
    function depositAll(uint256 pid, bool stake) external returns (bool);

    function withdrawAll(uint256 pid) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function withdraw(uint256 pid, uint256 amount) external returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IConvexMinter is IERC20Metadata {
    function totalCliffs() external view returns (uint256);

    function reductionPerCliff() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IConvexRewards {
    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function withdrawAllAndUnwrap(bool claim) external;

    function withdrawAndUnwrap(uint256 amount, bool claim) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IZunami {
    function totalSupply() external returns (uint256);

    function totalDeposited() external returns (uint256);

    function deposited(address account) external returns (uint256);

    function totalHoldings() external returns (uint256);

    function calcManagementFee(uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}