// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./PendleAaveMarket.sol";
import "../../interfaces/IPermissionsV2.sol";
import "./../abstract/PendleMarketFactoryBase.sol";

contract PendleAaveMarketFactory is PendleMarketFactoryBase {
    constructor(address _governanceManager, bytes32 _marketFactoryId)
        PendleMarketFactoryBase(_governanceManager, _marketFactoryId)
    {}

    function _createMarket(address _xyt, address _token) internal override returns (address) {
        address _governanceManager = address(IPermissionsV2(address(router)).governanceManager());
        return address(new PendleAaveMarket(_governanceManager, _xyt, _token));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "../../interfaces/IPendleAaveForge.sol";
import "../../libraries/MathLib.sol";
import "./../abstract/PendleMarketBase.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract PendleAaveMarket is PendleMarketBase {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // the normalisedIncome of the last time paramL got updated
    uint256 private globalLastNormalizedIncome;
    mapping(address => uint256) private userLastNormalizedIncome;

    constructor(
        address _governanceManager,
        address _xyt,
        address _token
    ) PendleMarketBase(_governanceManager, _xyt, _token) {}

    function _getReserveNormalizedIncome() internal view returns (uint256) {
        return IPendleAaveForge(forge).getReserveNormalizedIncome(underlyingAsset);
    }

    function _afterBootstrap() internal override {
        globalLastNormalizedIncome = _getReserveNormalizedIncome();
    }

    /// @inheritdoc PendleMarketBase
    function _updateDueInterests(address user) internal override {
        // before calc the interest for users, updateParamL
        _updateParamL();

        uint256 lastIncome = userLastNormalizedIncome[user];
        // why use globalLastNormalizedIncome? Because of the caching of paramL, we pretend that there is no source
        // of income externally (from Xyt, compound interest...), that's why we have to use globalLastNormalizedIncome
        // , which is the normalisedIncome from the last time paramL got updated (aka the last time we get external income)
        uint256 normIncomeNow = globalLastNormalizedIncome;
        uint256 principal = balanceOf(user);
        uint256 _paramL = paramL; // save value in memory to save gas

        if (lastIncome == 0) {
            userLastNormalizedIncome[user] = normIncomeNow;
            lastParamL[user] = _paramL;
            return;
        }

        /*
        this part can be thought of as follows:
            * the last time the user redeems interest, the value of a LP is lastParamL[user]
                and he has redeemed all the available interest out
            * the market has 2 sources of income: compound interest of the yieldTokens in the market right now
            AND external income (XYT interest, people transferring wrongly...)
            * now the value of param L is paramL. So there has been an increase of paramL - lastParamL[user]
                in value of a single LP. But in Aave, even if there are no external income, the value of a paramL
                can grow on its own
            * so since the last time the user has fully redeemed all the available interest, he shouldn't receive
            the compound interest sof the asset in the pool at the moment he last withdrew
            * so the value of 1 LP for him will be paramL - compound(lastParamL[user])
                = paramL -  lastParamL[user] * globalLastNormalizedIncome /userLastNormalizedIncome[user]
        */
        uint256 interestValuePerLP =
            _paramL.subMax0(lastParamL[user].mul(normIncomeNow).div(lastIncome));

        uint256 interestFromLp = principal.mul(interestValuePerLP).div(MULTIPLIER);

        dueInterests[user] = dueInterests[user].mul(normIncomeNow).div(lastIncome).add(
            interestFromLp
        );

        userLastNormalizedIncome[user] = normIncomeNow;
        lastParamL[user] = _paramL;
    }

    /// @inheritdoc PendleMarketBase
    function _getFirstTermAndParamR(uint256 currentNYield)
        internal
        override
        returns (uint256 firstTerm, uint256 paramR)
    {
        uint256 currentNormalizedIncome = _getReserveNormalizedIncome();
        // for Aave, the paramL can grow on its own (compound effect)
        firstTerm = paramL.mul(currentNormalizedIncome).div(globalLastNormalizedIncome);

        uint256 ix = lastNYield.mul(currentNormalizedIncome).div(globalLastNormalizedIncome);
        // paramR's meaning has been explained in the updateParamL function
        paramR = currentNYield.subMax0(ix);

        globalLastNormalizedIncome = currentNormalizedIncome;
    }

    /// @inheritdoc PendleMarketBase
    function _getIncomeIndexIncreaseRate() internal view override returns (uint256 increaseRate) {
        return _getReserveNormalizedIncome().rdiv(globalLastNormalizedIncome).sub(Math.RONE);
    }
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;
pragma abicoder v2;

import "../core/PendleGovernanceManager.sol";

interface IPermissionsV2 {
    function governanceManager() external returns (PendleGovernanceManager);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "../../interfaces/IPendleRouter.sol";
import "../../interfaces/IPendleData.sol";
import "../../interfaces/IPendleMarketFactory.sol";

abstract contract PendleMarketFactoryBase is IPendleMarketFactory {
    IPendleRouter public immutable override router;
    bytes32 public immutable override marketFactoryId;

    constructor(address _router, bytes32 _marketFactoryId) {
        require(address(_router) != address(0), "ZERO_ADDRESS");

        router = IPendleRouter(_router);
        marketFactoryId = _marketFactoryId;
    }

    modifier onlyRouter() {
        require(msg.sender == address(router), "ONLY_ROUTER");
        _;
    }

    function createMarket(address _xyt, address _token)
        external
        override
        onlyRouter
        returns (address market)
    {
        IPendleData data = router.data();

        market = _createMarket(_xyt, _token);
        data.addMarket(marketFactoryId, _xyt, _token, market);
    }

    function _createMarket(address _xyt, address _token) internal virtual returns (address);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;

import "./IPendleForge.sol";

interface IPendleAaveForge is IPendleForge {
    /**
    @dev directly get the normalizedIncome from Aave
    */
    function getReserveNormalizedIncome(address _underlyingAsset) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";

library Math {
    using SafeMath for uint256;

    uint256 internal constant BIG_NUMBER = (uint256(1) << uint256(200));
    uint256 internal constant PRECISION_BITS = 40;
    uint256 internal constant RONE = uint256(1) << PRECISION_BITS;
    uint256 internal constant PI = (314 * RONE) / 10**2;
    uint256 internal constant PI_PLUSONE = (414 * RONE) / 10**2;
    uint256 internal constant PRECISION_POW = 1e2;

    function checkMultOverflow(uint256 _x, uint256 _y) internal pure returns (bool) {
        if (_y == 0) return false;
        return (((_x * _y) / _y) != _x);
    }

    /**
    @notice find the integer part of log2(p/q)
        => find largest x s.t p >= q * 2^x
        => find largest x s.t 2^x <= p / q
     */
    function log2Int(uint256 _p, uint256 _q) internal pure returns (uint256) {
        uint256 res = 0;
        uint256 remain = _p / _q;
        while (remain > 0) {
            res++;
            remain /= 2;
        }
        return res - 1;
    }

    /**
    @notice log2 for a number that it in [1,2)
    @dev _x is FP, return a FP
    @dev function is from Kyber. Long modified the condition to be (_x >= one) && (_x < two)
    to avoid the case where x = 2 may lead to incorrect result
     */
    function log2ForSmallNumber(uint256 _x) internal pure returns (uint256) {
        uint256 res = 0;
        uint256 one = (uint256(1) << PRECISION_BITS);
        uint256 two = 2 * one;
        uint256 addition = one;

        require((_x >= one) && (_x < two), "MATH_ERROR");
        require(PRECISION_BITS < 125, "MATH_ERROR");

        for (uint256 i = PRECISION_BITS; i > 0; i--) {
            _x = (_x * _x) / one;
            addition = addition / 2;
            if (_x >= two) {
                _x = _x / 2;
                res += addition;
            }
        }

        return res;
    }

    /**
    @notice log2 of (p/q). returns result in FP form
    @dev function is from Kyber.
    @dev _p & _q is FP, return a FP
     */
    function logBase2(uint256 _p, uint256 _q) internal pure returns (uint256) {
        uint256 n = 0;

        if (_p > _q) {
            n = log2Int(_p, _q);
        }

        require(n * RONE <= BIG_NUMBER, "MATH_ERROR");
        require(!checkMultOverflow(_p, RONE), "MATH_ERROR");
        require(!checkMultOverflow(n, RONE), "MATH_ERROR");
        require(!checkMultOverflow(uint256(1) << n, _q), "MATH_ERROR");

        uint256 y = (_p * RONE) / (_q * (uint256(1) << n));
        uint256 log2Small = log2ForSmallNumber(y);

        assert(log2Small <= BIG_NUMBER);

        return n * RONE + log2Small;
    }

    /**
    @notice calculate ln(p/q). returned result >= 0
    @dev function is from Kyber.
    @dev _p & _q is FP, return a FP
    */
    function ln(uint256 p, uint256 q) internal pure returns (uint256) {
        uint256 ln2Numerator = 6931471805599453094172;
        uint256 ln2Denomerator = 10000000000000000000000;

        uint256 log2x = logBase2(p, q);

        require(!checkMultOverflow(ln2Numerator, log2x), "MATH_ERROR");

        return (ln2Numerator * log2x) / ln2Denomerator;
    }

    /**
    @notice extract the fractional part of a FP
    @dev value is a FP, return a FP
     */
    function fpart(uint256 value) internal pure returns (uint256) {
        return value % RONE;
    }

    /**
    @notice convert a FP to an Int
    @dev value is a FP, return an Int
     */
    function toInt(uint256 value) internal pure returns (uint256) {
        return value / RONE;
    }

    /**
    @notice convert an Int to a FP
    @dev value is an Int, return a FP
     */
    function toFP(uint256 value) internal pure returns (uint256) {
        return value * RONE;
    }

    /**
    @notice return e^exp in FP form
    @dev estimation by formula at http://pages.mtu.edu/~shene/COURSES/cs201/NOTES/chap04/exp.html
        the function is based on exp function of:
        https://github.com/NovakDistributed/macroverse/blob/master/contracts/RealMath.sol
    @dev the function is expected to converge quite fast, after about 20 iteration
    @dev exp is a FP, return a FP
     */
    function rpowe(uint256 exp) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 curTerm = RONE;

        for (uint256 n = 0; ; n++) {
            res += curTerm;
            curTerm = rmul(curTerm, rdiv(exp, toFP(n + 1)));
            if (curTerm == 0) {
                break;
            }
            if (n == 500) {
                /*
                testing shows that in the most extreme case, it will take 430 turns to converge.
                however, it's expected that the numbers will not exceed 2^120 in normal situation
                the most extreme case is rpow((1<<256)-1,(1<<40)-1) (equal to rpow((2^256-1)/2^40,0.99..9))
                */
                revert("RPOWE_SLOW_CONVERGE");
            }
        }

        return res;
    }

    /**
    @notice calculate base^exp with base and exp being FP int
    @dev to improve accuracy, base^exp = base^(int(exp)+frac(exp))
                                       = base^int(exp) * base^frac
    @dev base & exp are FP, return a FP
     */
    function rpow(uint256 base, uint256 exp) internal pure returns (uint256) {
        if (exp == 0) {
            // Anything to the 0 is 1
            return RONE;
        }
        if (base == 0) {
            // 0 to anything except 0 is 0
            return 0;
        }

        uint256 frac = fpart(exp); // get the fractional part
        uint256 whole = exp - frac;

        uint256 wholePow = rpowi(base, toInt(whole)); // whole is a FP, convert to Int
        uint256 fracPow;

        // instead of calculating base ^ frac, we will calculate e ^ (frac*ln(base))
        if (base < RONE) {
            /* since the base is smaller than 1.0, ln(base) < 0.
            Since 1 / (e^(frac*ln(1/base))) = e ^ (frac*ln(base)),
            we will calculate 1 / (e^(frac*ln(1/base))) instead.
            */
            uint256 newExp = rmul(frac, ln(rdiv(RONE, base), RONE));
            fracPow = rdiv(RONE, rpowe(newExp));
        } else {
            /* base is greater than 1, calculate normally */
            uint256 newExp = rmul(frac, ln(base, RONE));
            fracPow = rpowe(newExp);
        }
        return rmul(wholePow, fracPow);
    }

    /**
    @notice return base^exp with base in FP form and exp in Int
    @dev this function use a technique called: exponentiating by squaring
        complexity O(log(q))
    @dev function is from Kyber.
    @dev base is a FP, exp is an Int, return a FP
     */
    function rpowi(uint256 base, uint256 exp) internal pure returns (uint256) {
        uint256 res = exp % 2 != 0 ? base : RONE;

        for (exp /= 2; exp != 0; exp /= 2) {
            base = rmul(base, base);

            if (exp % 2 != 0) {
                res = rmul(res, base);
            }
        }
        return res;
    }

    /**
    @dev y is an Int, returns an Int
    @dev babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    @dev from Uniswap
     */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /**
    @notice divide 2 FP, return a FP
    @dev function is from Balancer.
    @dev x & y are FP, return a FP
     */
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return (y / 2).add(x.mul(RONE)).div(y);
    }

    /**
    @notice multiply 2 FP, return a FP
    @dev function is from Balancer.
    @dev x & y are FP, return a FP
     */
    function rmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return (RONE / 2).add(x.mul(y)).div(RONE);
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function subMax0(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a - b : 0;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "../../interfaces/IPendleData.sol";
import "../../interfaces/IPendleMarket.sol";
import "../../interfaces/IPendleForge.sol";
import "../../interfaces/IPendleMarketFactory.sol";
import "../../interfaces/IPendleYieldToken.sol";
import "../../interfaces/IPendlePausingManager.sol";
import "../../periphery/WithdrawableV2.sol";
import "../../tokens/PendleBaseToken.sol";
import "../../libraries/MarketMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
@dev HIGH LEVEL PRINCIPAL:
* So most of the functions in market is only callable by Router, except view/pure functions.
    If a function is non view/pure and is callable by anyone, it must be explicitly stated so
* Market will not do any yieldToken/baseToken transfer but instead will fill in the transfer array
    and router will do them instead. (This is to reduce the number of approval users need to do)
* mint, burn will be done directly with users
*/
abstract contract PendleMarketBase is IPendleMarket, PendleBaseToken, WithdrawableV2 {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public immutable override factoryId;
    address internal immutable forge;
    address public immutable override token;
    address public immutable override xyt;
    bool public bootstrapped;

    string private constant NAME = "Pendle Market";
    string private constant SYMBOL = "PENDLE-LPT";
    uint256 private constant MINIMUM_LIQUIDITY = 10**3;
    uint8 private constant DECIMALS = 18;
    uint256 private constant LN_PI_PLUSONE = 1562071538258; // this is equal to Math.ln(Math.PI_PLUSONE,Math.RONE)
    uint256 internal constant MULTIPLIER = 10**20;

    // variables for LP interests calc
    uint256 public paramL;
    uint256 public lastNYield;
    mapping(address => uint256) internal lastParamL;
    mapping(address => uint256) internal dueInterests;

    // paramK used for mintProtocolFee. ParamK = xytBal ^ xytWeight * tokenBal ^ tokenW
    uint256 public lastParamK;

    // the last block that we do curveShift
    uint256 public lastCurveShiftBlock;

    /*
    * The reserveData will consist of 3 variables: xytBalance, tokenBalance & xytWeight
    To save gas, we will pack these 3 variables into a single uint256 variable as follows:
        Bit 148 -> 255: xytBalance
        Bit 40 -> 147: tokenBalance
        Bit 0 -> 39: xytWeight
        tokenWeight = Math.RONE - xytWeight
    Refer to writeReserveData and readReserveData for more details
    */
    uint256 private reserveData;
    uint256 private lastRelativePrice = Math.RONE;

    uint256 private constant MASK_148_TO_255 = type(uint256).max ^ ((1 << 148) - 1);
    uint256 private constant MASK_40_TO_147 = ((1 << 148) - 1) ^ ((1 << 40) - 1);
    uint256 private constant MASK_0_TO_39 = ((1 << 40) - 1);
    uint256 private constant MAX_TOKEN_RESERVE_BALANCE = (1 << 108) - 1;

    /*
    * the lockStartTime is set at the bootstrap time of the market, and will not be changed for the entire market duration
    Once the market has been locked, only removeMarketLiquidityDual is allowed
    * Why lock the market? Because when the time is very close to the end of the market, the ratio of weights are either
    extremely big or small, which leads to high precision error
    */
    uint256 public lockStartTime;

    /* these variables are used often, so we get them once in the constructor
    and save gas for retrieving them afterwards */
    bytes32 private immutable forgeId;
    address internal immutable underlyingAsset;
    IERC20 private immutable underlyingYieldToken;
    IPendleData private immutable data;
    IPendlePausingManager private immutable pausingManager;
    uint256 private immutable xytStartTime;

    constructor(
        address _governanceManager,
        address _xyt,
        address _token
    )
        PendleBaseToken(
            address(IPendleYieldToken(_xyt).forge().router()),
            NAME,
            SYMBOL,
            DECIMALS,
            block.timestamp,
            IPendleYieldToken(_xyt).expiry()
        )
        PermissionsV2(_governanceManager)
    {
        require(_xyt != address(0), "ZERO_ADDRESS");
        require(_token != address(0), "ZERO_ADDRESS");
        require(_token != IPendleYieldToken(_xyt).underlyingYieldToken(), "INVALID_TOKEN_PAIR");

        IPendleForge _forge = IPendleYieldToken(_xyt).forge();

        forge = address(_forge);
        xyt = _xyt;
        token = _token;

        forgeId = _forge.forgeId();
        underlyingAsset = IPendleYieldToken(_xyt).underlyingAsset();
        underlyingYieldToken = IERC20(IPendleYieldToken(_xyt).underlyingYieldToken());
        data = _forge.data();
        pausingManager = _forge.data().pausingManager();
        xytStartTime = IPendleYieldToken(_xyt).start();
        factoryId = IPendleMarketFactory(msg.sender).marketFactoryId();

        address _router = address(_forge.router());
        IERC20(_xyt).safeApprove(_router, type(uint256).max);
        IERC20(_token).safeApprove(_router, type(uint256).max);
    }

    // INVARIANT: All write functions, except for ERC20's approve(), increaseAllowance(), decreaseAllowance()
    // must go through this check. This means that minting/burning/transferring of LP tokens is paused too.
    function checkNotPaused() internal {
        (bool paused, ) = pausingManager.checkMarketStatus(factoryId, address(this));
        require(!paused, "MARKET_PAUSED");
    }

    /// Refer to the docs for reserveData
    function readReserveData()
        internal
        view
        returns (
            uint256 xytBalance,
            uint256 tokenBalance,
            uint256 xytWeight,
            uint256 tokenWeight
        )
    {
        xytBalance = (reserveData & MASK_148_TO_255) >> 148;
        tokenBalance = (reserveData & MASK_40_TO_147) >> 40;
        xytWeight = reserveData & MASK_0_TO_39;
        tokenWeight = Math.RONE - xytWeight;
    }

    /// parse an asset address to tokenReserve
    /// _asset will only be either xyt or baseToken
    function parseTokenReserveData(address _asset)
        internal
        view
        returns (TokenReserve memory tokenReserve)
    {
        (uint256 xytBalance, uint256 tokenBalance, uint256 xytWeight, uint256 tokenWeight) =
            readReserveData();
        if (_asset == xyt) {
            tokenReserve = TokenReserve(xytWeight, xytBalance);
        } else {
            tokenReserve = TokenReserve(tokenWeight, tokenBalance);
        }
    }

    /// pass in a tokenReserve & the type of token (through _asset), update the reserveData
    function updateReserveData(TokenReserve memory tokenReserve, address _asset) internal {
        (uint256 xytBalance, uint256 tokenBalance, uint256 xytWeight, uint256 tokenWeight) =
            readReserveData();
        // Basically just update the weight & bal of the corresponding token & write the reserveData again
        if (_asset == xyt) {
            (xytWeight, xytBalance) = (tokenReserve.weight, tokenReserve.balance);
        } else {
            (tokenWeight, tokenBalance) = (tokenReserve.weight, tokenReserve.balance);
            xytWeight = Math.RONE.sub(tokenWeight);
        }
        writeReserveData(xytBalance, tokenBalance, xytWeight);
    }

    /// Refer to the docs for reserveData
    function writeReserveData(
        uint256 xytBalance,
        uint256 tokenBalance,
        uint256 xytWeight
    ) internal {
        require(0 < xytBalance && xytBalance <= MAX_TOKEN_RESERVE_BALANCE, "YT_BALANCE_ERROR");
        require(
            0 < tokenBalance && tokenBalance <= MAX_TOKEN_RESERVE_BALANCE,
            "TOKEN_BALANCE_ERROR"
        );
        reserveData = (xytBalance << 148) | (tokenBalance << 40) | xytWeight;
    }

    // Only the marketEmergencyHandler can call this function, when its in emergencyMode
    // this will allow a spender to spend the whole balance of the specified tokens
    // the spender should ideally be a contract with logic for users to withdraw out their funds.
    function setUpEmergencyMode(address spender) external override {
        (, bool emergencyMode) = pausingManager.checkMarketStatus(factoryId, address(this));
        require(emergencyMode, "NOT_EMERGENCY");
        (address marketEmergencyHandler, , ) = pausingManager.marketEmergencyHandler();
        require(msg.sender == marketEmergencyHandler, "NOT_EMERGENCY_HANDLER");
        IERC20(xyt).safeApprove(spender, type(uint256).max);
        IERC20(token).safeApprove(spender, type(uint256).max);
        IERC20(underlyingYieldToken).safeApprove(spender, type(uint256).max);
    }

    function bootstrap(
        address user,
        uint256 initialXytLiquidity,
        uint256 initialTokenLiquidity
    ) external override returns (PendingTransfer[2] memory transfers, uint256 exactOutLp) {
        require(msg.sender == address(router), "ONLY_ROUTER");
        checkNotPaused();
        require(!bootstrapped, "ALREADY_BOOTSTRAPPED");

        // market's lock params should be initialized at bootstrap time
        _initializeLock();

        // at the start of the market, xytWeight = tokenWeight = Math.RONE / 2
        // As such, we will write it into the reserveData
        writeReserveData(initialXytLiquidity, initialTokenLiquidity, Math.RONE / 2);
        _updateLastParamK(); // update paramK since this is the first time it's set

        emit Sync(initialXytLiquidity, Math.RONE / 2, initialTokenLiquidity);

        _afterBootstrap();
        // Taking inspiration from Uniswap, we will keep MINIMUM_LIQUIDITY in the market to make sure the market is always non-empty
        exactOutLp = Math.sqrt(initialXytLiquidity.mul(initialTokenLiquidity)).sub(
            MINIMUM_LIQUIDITY
        );

        // No one should possibly own a specific address like this 0x1
        // We mint to 0x1 instead of 0x0 because sending to 0x0 is not permitted
        _mint(address(0x1), MINIMUM_LIQUIDITY);
        _mint(user, exactOutLp);

        transfers[0].amount = initialXytLiquidity;
        transfers[0].isOut = false;
        transfers[1].amount = initialTokenLiquidity;
        transfers[1].isOut = false;

        lastCurveShiftBlock = block.number;
        bootstrapped = true;
    }

    /**
    * @notice Join the market by specifying the desired (and max) amount of xyts
    *    and tokens to put in.
    * @param _desiredXytAmount amount of XYTs user wants to contribute
    * @param _desiredTokenAmount amount of tokens user wants to contribute
    * @param _xytMinAmount min amount of XYTs user wants to be able to contribute
    * @param _tokenMinAmount min amount of tokens user wants to be able to contribute
    * @dev no curveShift to save gas because this function
              doesn't depend on weights of tokens
    * Note: the logic of this function is similar to that of Uniswap
    * Conditions:
        * checkAddRemoveSwapClaimAllowed(false) is true
    */
    function addMarketLiquidityDual(
        address user,
        uint256 _desiredXytAmount,
        uint256 _desiredTokenAmount,
        uint256 _xytMinAmount,
        uint256 _tokenMinAmount
    ) external override returns (PendingTransfer[2] memory transfers, uint256 lpOut) {
        checkAddRemoveSwapClaimAllowed(false);

        // mint protocol fees before k is changed by a non-swap event (add liquidity)
        _mintProtocolFees();

        (uint256 xytBalance, uint256 tokenBalance, uint256 xytWeight, ) = readReserveData();

        uint256 amountXytUsed;
        uint256 amountTokenUsed = _desiredXytAmount.mul(tokenBalance).div(xytBalance);
        if (amountTokenUsed <= _desiredTokenAmount) {
            // using _desiredXytAmount to determine the LP and add liquidity
            require(amountTokenUsed >= _tokenMinAmount, "INSUFFICIENT_TOKEN_AMOUNT");
            amountXytUsed = _desiredXytAmount;
            lpOut = _desiredXytAmount.mul(totalSupply()).div(xytBalance);
        } else {
            // using _desiredTokenAmount to determine the LP and add liquidity
            amountXytUsed = _desiredTokenAmount.mul(xytBalance).div(tokenBalance);
            require(amountXytUsed >= _xytMinAmount, "INSUFFICIENT_YT_AMOUNT");
            amountTokenUsed = _desiredTokenAmount;
            lpOut = _desiredTokenAmount.mul(totalSupply()).div(tokenBalance);
        }

        xytBalance = xytBalance.add(amountXytUsed);
        transfers[0].amount = amountXytUsed;
        transfers[0].isOut = false;

        tokenBalance = tokenBalance.add(amountTokenUsed);
        transfers[1].amount = amountTokenUsed;
        transfers[1].isOut = false;

        writeReserveData(xytBalance, tokenBalance, xytWeight);
        _updateLastParamK(); // update paramK since it has changed due to a non-swap event

        // Mint LP directly to the user
        _mint(user, lpOut);

        emit Sync(xytBalance, xytWeight, tokenBalance);
    }

    /**
     * @notice Join the market by deposit token (single) and get liquidity token
     *       need to specify the desired amount of contributed token (xyt or token)
     *       and minimum output liquidity token
     * @param _inToken address of token (xyt or token) user wants to contribute
     * @param _exactIn amount of tokens (xyt or token)  user wants to contribute
     * @param _minOutLp min amount of liquidity token user expect to receive
     * @dev curveShift needed since function operation relies on weights
     */
    function addMarketLiquiditySingle(
        address user,
        address _inToken,
        uint256 _exactIn,
        uint256 _minOutLp
    ) external override returns (PendingTransfer[2] memory transfers, uint256 exactOutLp) {
        checkAddRemoveSwapClaimAllowed(false);

        // mint protocol fees before k is changed by a non-swap event (add liquidity)
        _mintProtocolFees();
        _curveShift();

        /*
        * Note that in theory we could do another _mintProtocolFee in this function
            to take a portion of the swap fees for the implicit swap of this operation
        * However, we have decided to not charge the protocol fees on the swap fees for this
            operation.
        * The user will still pay the swap fees, just that all the swap fees in the implicit swap
            will all go back to the market (and shared among the LP holders)
        */
        TokenReserve memory inTokenReserve = parseTokenReserveData(_inToken);

        uint256 totalLp = totalSupply();

        // Calc out amount of LP token.
        exactOutLp = MarketMath._calcOutAmountLp(
            _exactIn,
            inTokenReserve,
            data.swapFee(),
            totalLp
        );
        require(exactOutLp >= _minOutLp, "HIGH_LP_OUT_LIMIT");

        // Update reserves and operate underlying LP and inToken.
        inTokenReserve.balance = inTokenReserve.balance.add(_exactIn);
        transfers[0].amount = _exactIn;
        transfers[0].isOut = false;

        // repack data
        updateReserveData(inTokenReserve, _inToken);
        _updateLastParamK(); // update paramK since it has changed not due to swap

        // Mint and push LP token.
        _mint(user, exactOutLp);

        (uint256 xytBalance, uint256 tokenBalance, uint256 xytWeight, ) = readReserveData(); // unpack data
        emit Sync(xytBalance, xytWeight, tokenBalance);
    }

    /**
     * @notice Exit the market by putting in the desired amount of LP tokens
     *         and getting back XYT and pair tokens.
     * @dev no curveShift to save gas because this function
                doesn't depend on weights of tokens
     * @dev this function will never be locked since we always let users withdraw
                their funds. That's why we skip time check in checkAddRemoveSwapClaimAllowed
     */
    function removeMarketLiquidityDual(
        address user,
        uint256 _inLp,
        uint256 _minOutXyt,
        uint256 _minOutToken
    ) external override returns (PendingTransfer[2] memory transfers) {
        checkAddRemoveSwapClaimAllowed(true);

        // mint protocol fees before k is changed by a non-swap event (remove liquidity)
        _mintProtocolFees();

        uint256 totalLp = totalSupply();

        (uint256 xytBalance, uint256 tokenBalance, uint256 xytWeight, ) = readReserveData(); // unpack data

        // Calc and withdraw xyt token.
        uint256 xytOut = _inLp.mul(xytBalance).div(totalLp);
        uint256 tokenOut = _inLp.mul(tokenBalance).div(totalLp);

        require(tokenOut >= _minOutToken, "INSUFFICIENT_TOKEN_OUT");
        require(xytOut >= _minOutXyt, "INSUFFICIENT_YT_OUT");

        xytBalance = xytBalance.sub(xytOut);
        tokenBalance = tokenBalance.sub(tokenOut);

        transfers[0].amount = xytOut;
        transfers[0].isOut = true;

        transfers[1].amount = tokenOut;
        transfers[1].isOut = true;

        writeReserveData(xytBalance, tokenBalance, xytWeight); // repack data
        _updateLastParamK(); // update paramK since it has changed due to a non-swap event

        _burn(user, _inLp);

        emit Sync(xytBalance, xytWeight, tokenBalance);
    }

    /**
     * @notice Exit the market by putting in the desired amount of LP tokens
     *      and getting back XYT or pair tokens.
     * @param _outToken address of the token that user wants to get back
     * @param _inLp the exact amount of liquidity token that user wants to put back
     * @param _minOutAmountToken the minimum of token that user wants to get back
     * @dev curveShift needed since function operation relies on weights
     */
    function removeMarketLiquiditySingle(
        address user,
        address _outToken,
        uint256 _inLp,
        uint256 _minOutAmountToken
    ) external override returns (PendingTransfer[2] memory transfers) {
        checkAddRemoveSwapClaimAllowed(false);

        // mint protocol fees before k is changed by a non-swap event (remove liquidity)
        _mintProtocolFees();
        _curveShift();

        /*
        * Note that in theory we should do another _mintProtocolFee in this function
            since this add single involves an implicit swap operation
        * The reason we don't do that is same as in addMarketLiquiditySingle
        */
        TokenReserve memory outTokenReserve = parseTokenReserveData(_outToken);

        uint256 swapFee = data.swapFee();
        uint256 totalLp = totalSupply();

        uint256 outAmountToken =
            MarketMath._calcOutAmountToken(outTokenReserve, totalLp, _inLp, swapFee);
        require(outAmountToken >= _minOutAmountToken, "INSUFFICIENT_TOKEN_OUT");

        outTokenReserve.balance = outTokenReserve.balance.sub(outAmountToken);
        transfers[0].amount = outAmountToken;
        transfers[0].isOut = true;

        updateReserveData(outTokenReserve, _outToken);
        _updateLastParamK(); // update paramK since it has changed by a non-swap event

        _burn(user, _inLp);

        (uint256 xytBalance, uint256 tokenBalance, uint256 xytWeight, ) = readReserveData(); // unpack data
        emit Sync(xytBalance, xytWeight, tokenBalance);
    }

    function swapExactIn(
        address inToken,
        uint256 inAmount,
        address outToken,
        uint256 minOutAmount
    ) external override returns (uint256 outAmount, PendingTransfer[2] memory transfers) {
        checkAddRemoveSwapClaimAllowed(false);

        // We only need to do _mintProtocolFees if there is a curveShift that follows
        if (checkNeedCurveShift()) {
            _mintProtocolFees();
            _curveShift();
            _updateLastParamK(); // update paramK since it has changed due to a non-swap event
        }

        TokenReserve memory inTokenReserve = parseTokenReserveData(inToken);
        TokenReserve memory outTokenReserve = parseTokenReserveData(outToken);

        // calc out amount of token to be swapped out
        outAmount = MarketMath._calcExactOut(
            inTokenReserve,
            outTokenReserve,
            inAmount,
            data.swapFee()
        );
        require(outAmount >= minOutAmount, "HIGH_OUT_LIMIT");

        inTokenReserve.balance = inTokenReserve.balance.add(inAmount);
        outTokenReserve.balance = outTokenReserve.balance.sub(outAmount);

        // repack data
        updateReserveData(inTokenReserve, inToken);
        updateReserveData(outTokenReserve, outToken);
        // no update paramK since it has changed but due to swap

        transfers[0].amount = inAmount;
        transfers[0].isOut = false;
        transfers[1].amount = outAmount;
        transfers[1].isOut = true;

        (uint256 xytBalance, uint256 tokenBalance, uint256 xytWeight, ) = readReserveData(); // unpack data
        emit Sync(xytBalance, xytWeight, tokenBalance);
    }

    function swapExactOut(
        address inToken,
        uint256 maxInAmount,
        address outToken,
        uint256 outAmount
    ) external override returns (uint256 inAmount, PendingTransfer[2] memory transfers) {
        checkAddRemoveSwapClaimAllowed(false);

        // We only need to do _mintProtocolFees if there is a curveShift that follows
        if (checkNeedCurveShift()) {
            _mintProtocolFees();
            _curveShift();
            _updateLastParamK(); // update paramK since it has changed due to a non-swap event
        }

        TokenReserve memory inTokenReserve = parseTokenReserveData(inToken);
        TokenReserve memory outTokenReserve = parseTokenReserveData(outToken);

        // Calc in amount.
        inAmount = MarketMath._calcExactIn(
            inTokenReserve,
            outTokenReserve,
            outAmount,
            data.swapFee()
        );
        require(inAmount <= maxInAmount, "LOW_IN_LIMIT");

        inTokenReserve.balance = inTokenReserve.balance.add(inAmount);
        outTokenReserve.balance = outTokenReserve.balance.sub(outAmount);

        // repack data
        updateReserveData(inTokenReserve, inToken);
        updateReserveData(outTokenReserve, outToken);
        // no update paramK since it has changed but due to swap

        transfers[0].amount = inAmount;
        transfers[0].isOut = false;
        transfers[1].amount = outAmount;
        transfers[1].isOut = true;

        (uint256 xytBalance, uint256 tokenBalance, uint256 xytWeight, ) = readReserveData(); // unpack data
        emit Sync(xytBalance, xytWeight, tokenBalance);
    }

    /**
     * @notice for user to claim their interest as holder of underlyingYield token
     * @param user user's address
     * @dev only can claim through router (included in checkAddRemoveSwapClaimAllowed)
     * We skip time check in checkAddRemoveSwapClaimAllowed because users can always claim interests
     * Since the Router has already had Reentrancy protection, we don't need one here
     */
    function redeemLpInterests(address user) external override returns (uint256 interests) {
        checkAddRemoveSwapClaimAllowed(true);
        interests = _beforeTransferDueInterests(user);
        _safeTransferYieldToken(user, interests);
    }

    /**
     * @notice get the most up-to-date reserveData of the market by doing a dry curveShift
     */
    function getReserves()
        external
        view
        override
        returns (
            uint256 xytBalance,
            uint256 xytWeight,
            uint256 tokenBalance,
            uint256 tokenWeight,
            uint256 currentBlock
        )
    {
        (xytBalance, tokenBalance, xytWeight, tokenWeight) = readReserveData();
        if (checkNeedCurveShift()) {
            (xytWeight, tokenWeight, ) = _updateWeightDry();
        }
        currentBlock = block.number;
    }

    /**
     * @notice update the weights of the market
     */
    function _updateWeight() internal {
        (uint256 xytBalance, uint256 tokenBalance, , ) = readReserveData(); // unpack data
        (uint256 xytWeightUpdated, , uint256 currentRelativePrice) = _updateWeightDry();
        writeReserveData(xytBalance, tokenBalance, xytWeightUpdated); // repack data

        lastRelativePrice = currentRelativePrice;
    }

    // do the weight update calculation but don't update the token reserve memory
    function _updateWeightDry()
        internal
        view
        returns (
            uint256 xytWeightUpdated,
            uint256 tokenWeightUpdated,
            uint256 currentRelativePrice
        )
    {
        // get current timestamp currentTime
        uint256 currentTime = block.timestamp;
        uint256 endTime = expiry;
        uint256 startTime = xytStartTime;
        uint256 duration = endTime - startTime;

        (, , uint256 xytWeight, uint256 tokenWeight) = readReserveData(); // unpack data

        uint256 timeLeft;
        if (endTime >= currentTime) {
            timeLeft = endTime - currentTime;
        } else {
            timeLeft = 0;
        }

        // get time_to_mature = (endTime - currentTime) / (endTime - startTime)
        uint256 timeToMature = Math.rdiv(timeLeft * Math.RONE, duration * Math.RONE);

        // get price for now = ln(3.14 * t + 1) / ln(4.14)
        currentRelativePrice = Math.rdiv(
            Math.ln(Math.rmul(Math.PI, timeToMature).add(Math.RONE), Math.RONE),
            LN_PI_PLUSONE
        );

        uint256 r = Math.rdiv(currentRelativePrice, lastRelativePrice);
        require(Math.RONE >= r, "MATH_ERROR");

        uint256 thetaNumerator = Math.rmul(Math.rmul(xytWeight, tokenWeight), Math.RONE.sub(r));
        uint256 thetaDenominator = Math.rmul(r, xytWeight).add(tokenWeight);

        // calc weight changes theta
        uint256 theta = Math.rdiv(thetaNumerator, thetaDenominator);

        xytWeightUpdated = xytWeight.sub(theta);
        tokenWeightUpdated = tokenWeight.add(theta);
    }

    /*
     To add/remove/swap/claim, the market must have been
     * bootstrapped
     * only Router can call it
     * if the function is not removeMarketLiquidityDual, then must check the market hasn't been locked yet
     */
    function checkAddRemoveSwapClaimAllowed(bool skipOpenCheck) internal {
        checkNotPaused();
        require(bootstrapped, "NOT_BOOTSTRAPPED");
        require(msg.sender == address(router), "ONLY_ROUTER");
        if (!skipOpenCheck) {
            require(block.timestamp < lockStartTime, "MARKET_LOCKED");
        }
    }

    //curve shift will be called before any calculation using weight
    //Note: there must be a _mintProtocolFees() before calling _curveShift()
    function _curveShift() internal {
        if (!checkNeedCurveShift()) return;
        _updateWeight();
        lastCurveShiftBlock = block.number;
    }

    /**
    @notice To be called before the dueInterest of any users is redeemed
    */
    function _beforeTransferDueInterests(address user) internal returns (uint256 amountOut) {
        _updateDueInterests(user);

        amountOut = dueInterests[user];
        dueInterests[user] = 0;

        // Use subMax0 to handle the extreme case of the market lacking a few wei of tokens to send out
        lastNYield = lastNYield.subMax0(amountOut);
    }

    /**
     * We will only updateParamL if the normalisedIncome / exchangeRate has increased more than a delta
     * This delta is expected to be very small
     */
    function checkNeedUpdateParamL() internal returns (bool) {
        return _getIncomeIndexIncreaseRate() > data.interestUpdateRateDeltaForMarket();
    }

    /**
     * We will only do curveShift() once every curveShiftBlockDelta blocks
     */
    function checkNeedCurveShift() internal view returns (bool) {
        return block.number > lastCurveShiftBlock.add(data.curveShiftBlockDelta());
    }

    /**
     * @notice use to updateParamL. Must only be called by _updateDueInterests
     * ParamL can be thought of as an always-increase incomeIndex for 1 LP
     Consideration:
     * Theoretically we have to updateParamL whenever the _updateDueInterests is called, since the external incomeIndex
        (normalisedIncome/exchangeRate) is always increasing, and there are always interests to be claimed
     * Yet, if we do so, the amount of interests to be claimed maybe negligible while the amount of gas spent is
        tremendous (100k~200k last time we checked) => Caching is actually beneficial to user
     * The users may lose some negligible amount of interest when they do removeLiquidity or transfer LP to others
        (to be exact, they will lose NO MORE THAN interestUpdateRateDeltaForMarket%). In exchange, they will save
        a lot of gas.
        * If we assume the yearly interest rate is 10%, and we would like to only update the market's interest every one hour,
          interestUpdateRateDeltaForMarket% = 1.10 ^ (1/ (365*24)) - 1 = 0.00108802167011 %
     * The correctness of caching can be thought of like this: We just pretend that there are only income once in a while,
     and when that income come, they will come in large amount, and we will distribute them fairly to all users
     */
    function _updateParamL() internal {
        if (!checkNeedUpdateParamL()) return;
        // redeem the interest from XYT
        router.redeemDueInterests(forgeId, underlyingAsset, expiry, address(this));

        uint256 currentNYield = underlyingYieldToken.balanceOf(address(this));
        (uint256 firstTerm, uint256 paramR) = _getFirstTermAndParamR(currentNYield);
        uint256 secondTerm;

        /*
        * paramR can be thought of as the amount of interest earned by the market
        (but excluding the compound effect). paramR is normally small & totalSupply is
        normally much larger so we need to multiply them with MULTIPLIER
        */
        if (totalSupply() != 0) secondTerm = paramR.mul(MULTIPLIER).div(totalSupply());

        // firstTerm & secondTerm are not the best names, but please refer to AMM specs
        // to understand the meaning of these 2 params
        paramL = firstTerm.add(secondTerm);
        lastNYield = currentNYield;
    }

    // before we send LPs, we need to update LP interests for both the to and from addresses
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);
        checkNotPaused();
        if (from != address(0)) _updateDueInterests(from);
        if (to != address(0)) _updateDueInterests(to);
    }

    /**
    @dev Must be the only way to transfer aToken/cToken out
    // Please refer to _safeTransfer of PendleForgeBase for the rationale of this function
    */
    function _safeTransferYieldToken(address _user, uint256 _amount) internal {
        if (_amount == 0) return;
        _amount = Math.min(_amount, underlyingYieldToken.balanceOf(address(this)));
        underlyingYieldToken.safeTransfer(_user, _amount);
    }

    /**
     * @notice _initialize the lock of the market. Must only be called in bootstrap
     */
    function _initializeLock() internal {
        uint256 duration = expiry.sub(xytStartTime); // market expiry = xyt expiry
        uint256 lockDuration = duration.mul(data.lockNumerator()).div(data.lockDenominator());
        lockStartTime = expiry.sub(lockDuration);
    }

    /**
    @notice _mint new LP for protocol fee. Mint them directly to the treasury
    @dev this function should be very similar to Uniswap
    */
    function _mintProtocolFees() internal {
        uint256 feeRatio = data.protocolSwapFee();
        uint256 _lastParamK = lastParamK;
        if (feeRatio > 0) {
            if (_lastParamK != 0) {
                uint256 k = _calcParamK();
                if (k > _lastParamK) {
                    uint256 numer = totalSupply().mul(k.sub(_lastParamK));
                    uint256 denom = Math.RONE.sub(feeRatio).mul(k).div(feeRatio).add(_lastParamK);
                    uint256 liquidity = numer / denom;
                    address treasury = data.treasury();
                    if (liquidity > 0) {
                        _mint(treasury, liquidity);
                    }
                }
            }
        } else if (_lastParamK != 0) {
            // if fee is turned off, we need to reset lastParamK as well
            lastParamK = 0;
        }
    }

    /**
    Equation for paramK: paramK = xytBal ^ xytWeight * tokenBal ^ tokenW
    * @dev must be called whenever the above equation changes but not due to a swapping action
    I.e: after add/remove/bootstrap liquidity or curveShift
    */
    function _updateLastParamK() internal {
        if (data.protocolSwapFee() == 0) return;
        lastParamK = _calcParamK();
    }

    /**
     * @notice calc the value of paramK. The formula for this can be referred in the AMM specs
     */
    function _calcParamK() internal view returns (uint256 paramK) {
        (uint256 xytBalance, uint256 tokenBalance, uint256 xytWeight, uint256 tokenWeight) =
            readReserveData();
        paramK = Math
            .rpow(xytBalance.toFP(), xytWeight)
            .rmul(Math.rpow(tokenBalance.toFP(), tokenWeight))
            .toInt();
    }

    function _allowedToWithdraw(address _token) internal view override returns (bool allowed) {
        allowed =
            _token != xyt &&
            _token != token &&
            _token != address(this) &&
            _token != address(underlyingYieldToken);
    }

    function _afterBootstrap() internal virtual;

    /**
    @notice update the LP interest for users (before their balances of LP changes)
    @dev This must be called before any transfer / mint/ burn action of LP
        (and this has been implemented in the beforeTokenTransfer of this contract)
    */
    function _updateDueInterests(address user) internal virtual;

    /// @notice Get params to update paramL. Must only be called by updateParamL
    function _getFirstTermAndParamR(uint256 currentNYield)
        internal
        virtual
        returns (uint256 firstTerm, uint256 paramR);

    /// @notice Get the increase rate of normalisedIncome / exchangeRate
    function _getIncomeIndexIncreaseRate() internal virtual returns (uint256 increaseRate);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;

import "./IPendleRouter.sol";
import "./IPendleRewardManager.sol";
import "./IPendleYieldContractDeployer.sol";

interface IPendleForge {
    /**
     * @dev Emitted when the Forge has minted the OT and XYT tokens.
     * @param forgeId The forgeId
     * @param underlyingAsset The address of the underlying yield token.
     * @param expiry The expiry of the XYT token
     * @param amountToTokenize The amount of yield bearing assets to tokenize
     * @param amountTokenMinted The amount of OT/XYT minted
     **/
    event MintYieldTokens(
        bytes32 forgeId,
        address indexed underlyingAsset,
        uint256 indexed expiry,
        uint256 amountToTokenize,
        uint256 amountTokenMinted,
        address indexed user
    );

    /**
     * @dev Emitted when the Forge has created new yield token contracts.
     * @param forgeId The forgeId
     * @param underlyingAsset The address of the underlying asset.
     * @param expiry The date in epoch time when the contract will expire.
     * @param ot The address of the ownership token.
     * @param xyt The address of the new future yield token.
     **/
    event NewYieldContracts(
        bytes32 forgeId,
        address indexed underlyingAsset,
        uint256 indexed expiry,
        address ot,
        address xyt,
        address yieldBearingAsset
    );

    /**
     * @dev Emitted when the Forge has redeemed the OT and XYT tokens.
     * @param forgeId The forgeId
     * @param underlyingAsset the address of the underlying asset
     * @param expiry The expiry of the XYT token
     * @param amountToRedeem The amount of OT to be redeemed.
     * @param redeemedAmount The amount of yield token received
     **/
    event RedeemYieldToken(
        bytes32 forgeId,
        address indexed underlyingAsset,
        uint256 indexed expiry,
        uint256 amountToRedeem,
        uint256 redeemedAmount,
        address indexed user
    );

    /**
     * @dev Emitted when interest claim is settled
     * @param forgeId The forgeId
     * @param underlyingAsset the address of the underlying asset
     * @param expiry The expiry of the XYT token
     * @param user Interest receiver Address
     * @param amount The amount of interest claimed
     **/
    event DueInterestsSettled(
        bytes32 forgeId,
        address indexed underlyingAsset,
        uint256 indexed expiry,
        uint256 amount,
        uint256 forgeFeeAmount,
        address indexed user
    );

    /**
     * @dev Emitted when forge fee is withdrawn
     * @param forgeId The forgeId
     * @param underlyingAsset the address of the underlying asset
     * @param expiry The expiry of the XYT token
     * @param amount The amount of interest claimed
     **/
    event ForgeFeeWithdrawn(
        bytes32 forgeId,
        address indexed underlyingAsset,
        uint256 indexed expiry,
        uint256 amount
    );

    function setUpEmergencyMode(
        address _underlyingAsset,
        uint256 _expiry,
        address spender
    ) external;

    function newYieldContracts(address underlyingAsset, uint256 expiry)
        external
        returns (address ot, address xyt);

    function redeemAfterExpiry(
        address user,
        address underlyingAsset,
        uint256 expiry
    ) external returns (uint256 redeemedAmount);

    function redeemDueInterests(
        address user,
        address underlyingAsset,
        uint256 expiry
    ) external returns (uint256 interests);

    function updateDueInterests(
        address underlyingAsset,
        uint256 expiry,
        address user
    ) external;

    function updatePendingRewards(
        address _underlyingAsset,
        uint256 _expiry,
        address _user
    ) external;

    function redeemUnderlying(
        address user,
        address underlyingAsset,
        uint256 expiry,
        uint256 amountToRedeem
    ) external returns (uint256 redeemedAmount);

    function mintOtAndXyt(
        address underlyingAsset,
        uint256 expiry,
        uint256 amountToTokenize,
        address to
    )
        external
        returns (
            address ot,
            address xyt,
            uint256 amountTokenMinted
        );

    function withdrawForgeFee(address underlyingAsset, uint256 expiry) external;

    function getYieldBearingToken(address underlyingAsset) external returns (address);

    /**
     * @notice Gets a reference to the PendleRouter contract.
     * @return Returns the router contract reference.
     **/
    function router() external view returns (IPendleRouter);

    function data() external view returns (IPendleData);

    function rewardManager() external view returns (IPendleRewardManager);

    function yieldContractDeployer() external view returns (IPendleYieldContractDeployer);

    function rewardToken() external view returns (IERC20);

    /**
     * @notice Gets the bytes32 ID of the forge.
     * @return Returns the forge and protocol identifier.
     **/
    function forgeId() external view returns (bytes32);

    function dueInterests(
        address _underlyingAsset,
        uint256 expiry,
        address _user
    ) external view returns (uint256);

    function yieldTokenHolders(address _underlyingAsset, uint256 _expiry)
        external
        view
        returns (address yieldTokenHolder);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;
pragma abicoder v2;

import "../interfaces/IWETH.sol";
import "./IPendleData.sol";
import "../libraries/PendleStructs.sol";
import "./IPendleMarketFactory.sol";

interface IPendleRouter {
    /**
     * @notice Emitted when a market for a future yield token and an ERC20 token is created.
     * @param marketFactoryId Forge identifier.
     * @param xyt The address of the tokenized future yield token as the base asset.
     * @param token The address of an ERC20 token as the quote asset.
     * @param market The address of the newly created market.
     **/
    event MarketCreated(
        bytes32 marketFactoryId,
        address indexed xyt,
        address indexed token,
        address indexed market
    );

    /**
     * @notice Emitted when a swap happens on the market.
     * @param trader The address of msg.sender.
     * @param inToken The input token.
     * @param outToken The output token.
     * @param exactIn The exact amount being traded.
     * @param exactOut The exact amount received.
     * @param market The market address.
     **/
    event SwapEvent(
        address indexed trader,
        address inToken,
        address outToken,
        uint256 exactIn,
        uint256 exactOut,
        address market
    );

    /**
     * @dev Emitted when user adds liquidity
     * @param sender The user who added liquidity.
     * @param token0Amount the amount of token0 (xyt) provided by user
     * @param token1Amount the amount of token1 provided by user
     * @param market The market address.
     * @param exactOutLp The exact LP minted
     */
    event Join(
        address indexed sender,
        uint256 token0Amount,
        uint256 token1Amount,
        address market,
        uint256 exactOutLp
    );

    /**
     * @dev Emitted when user removes liquidity
     * @param sender The user who removed liquidity.
     * @param token0Amount the amount of token0 (xyt) given to user
     * @param token1Amount the amount of token1 given to user
     * @param market The market address.
     * @param exactInLp The exact Lp to remove
     */
    event Exit(
        address indexed sender,
        uint256 token0Amount,
        uint256 token1Amount,
        address market,
        uint256 exactInLp
    );

    /**
     * @notice Gets a reference to the PendleData contract.
     * @return Returns the data contract reference.
     **/
    function data() external view returns (IPendleData);

    /**
     * @notice Gets a reference of the WETH9 token contract address.
     * @return WETH token reference.
     **/
    function weth() external view returns (IWETH);

    /***********
     *  FORGE  *
     ***********/

    function newYieldContracts(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external returns (address ot, address xyt);

    function redeemAfterExpiry(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external returns (uint256 redeemedAmount);

    function redeemDueInterests(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry,
        address user
    ) external returns (uint256 interests);

    function redeemUnderlying(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry,
        uint256 amountToRedeem
    ) external returns (uint256 redeemedAmount);

    function renewYield(
        bytes32 forgeId,
        uint256 oldExpiry,
        address underlyingAsset,
        uint256 newExpiry,
        uint256 renewalRate
    )
        external
        returns (
            uint256 redeemedAmount,
            uint256 amountRenewed,
            address ot,
            address xyt,
            uint256 amountTokenMinted
        );

    function tokenizeYield(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry,
        uint256 amountToTokenize,
        address to
    )
        external
        returns (
            address ot,
            address xyt,
            uint256 amountTokenMinted
        );

    /***********
     *  MARKET *
     ***********/

    function addMarketLiquidityDual(
        bytes32 _marketFactoryId,
        address _xyt,
        address _token,
        uint256 _desiredXytAmount,
        uint256 _desiredTokenAmount,
        uint256 _xytMinAmount,
        uint256 _tokenMinAmount
    )
        external
        payable
        returns (
            uint256 amountXytUsed,
            uint256 amountTokenUsed,
            uint256 lpOut
        );

    function addMarketLiquiditySingle(
        bytes32 marketFactoryId,
        address xyt,
        address token,
        bool forXyt,
        uint256 exactInAsset,
        uint256 minOutLp
    ) external payable returns (uint256 exactOutLp);

    function removeMarketLiquidityDual(
        bytes32 marketFactoryId,
        address xyt,
        address token,
        uint256 exactInLp,
        uint256 minOutXyt,
        uint256 minOutToken
    ) external returns (uint256 exactOutXyt, uint256 exactOutToken);

    function removeMarketLiquiditySingle(
        bytes32 marketFactoryId,
        address xyt,
        address token,
        bool forXyt,
        uint256 exactInLp,
        uint256 minOutAsset
    ) external returns (uint256 exactOutXyt, uint256 exactOutToken);

    /**
     * @notice Creates a market given a protocol ID, future yield token, and an ERC20 token.
     * @param marketFactoryId Market Factory identifier.
     * @param xyt Token address of the future yield token as base asset.
     * @param token Token address of an ERC20 token as quote asset.
     * @return market Returns the address of the newly created market.
     **/
    function createMarket(
        bytes32 marketFactoryId,
        address xyt,
        address token
    ) external returns (address market);

    function bootstrapMarket(
        bytes32 marketFactoryId,
        address xyt,
        address token,
        uint256 initialXytLiquidity,
        uint256 initialTokenLiquidity
    ) external payable;

    function swapExactIn(
        address tokenIn,
        address tokenOut,
        uint256 inTotalAmount,
        uint256 minOutTotalAmount,
        bytes32 marketFactoryId
    ) external payable returns (uint256 outTotalAmount);

    function swapExactOut(
        address tokenIn,
        address tokenOut,
        uint256 outTotalAmount,
        uint256 maxInTotalAmount,
        bytes32 marketFactoryId
    ) external payable returns (uint256 inTotalAmount);

    function redeemLpInterests(address market, address user) external returns (uint256 interests);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
pragma solidity 0.7.6;

interface IPendleRewardManager {
    event UpdateFrequencySet(address[], uint256[]);
    event SkippingRewardsSet(bool);

    event DueRewardsSettled(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry,
        uint256 amountOut,
        address user
    );

    function redeemRewards(
        address _underlyingAsset,
        uint256 _expiry,
        address _user
    ) external returns (uint256 dueRewards);

    function updatePendingRewards(
        address _underlyingAsset,
        uint256 _expiry,
        address _user
    ) external;

    function updateParamLManual(address _underlyingAsset, uint256 _expiry) external;

    function setUpdateFrequency(
        address[] calldata underlyingAssets,
        uint256[] calldata frequencies
    ) external;

    function setSkippingRewards(bool skippingRewards) external;

    function forgeId() external returns (bytes32);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
pragma solidity 0.7.6;

interface IPendleYieldContractDeployer {
    function forgeId() external returns (bytes32);

    function forgeOwnershipToken(
        address _underlyingAsset,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _expiry
    ) external returns (address ot);

    function forgeFutureYieldToken(
        address _underlyingAsset,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _expiry
    ) external returns (address xyt);

    function deployYieldTokenHolder(address yieldToken, uint256 expiry)
        external
        returns (address yieldTokenHolder);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;

import "./IPendleRouter.sol";
import "./IPendleYieldToken.sol";
import "./IPendlePausingManager.sol";
import "./IPendleMarket.sol";

interface IPendleData {
    /**
     * @notice Emitted when validity of a forge-factory pair is updated
     * @param _forgeId the forge id
     * @param _marketFactoryId the market factory id
     * @param _valid valid or not
     **/
    event ForgeFactoryValiditySet(bytes32 _forgeId, bytes32 _marketFactoryId, bool _valid);

    /**
     * @notice Emitted when Pendle and PendleFactory addresses have been updated.
     * @param treasury The address of the new treasury contract.
     **/
    event TreasurySet(address treasury);

    /**
     * @notice Emitted when LockParams is changed
     **/
    event LockParamsSet(uint256 lockNumerator, uint256 lockDenominator);

    /**
     * @notice Emitted when ExpiryDivisor is changed
     **/
    event ExpiryDivisorSet(uint256 expiryDivisor);

    /**
     * @notice Emitted when forge fee is changed
     **/
    event ForgeFeeSet(uint256 forgeFee);

    /**
     * @notice Emitted when interestUpdateRateDeltaForMarket is changed
     * @param interestUpdateRateDeltaForMarket new interestUpdateRateDeltaForMarket setting
     **/
    event InterestUpdateRateDeltaForMarketSet(uint256 interestUpdateRateDeltaForMarket);

    /**
     * @notice Emitted when market fees are changed
     * @param _swapFee new swapFee setting
     * @param _protocolSwapFee new protocolSwapFee setting
     **/
    event MarketFeesSet(uint256 _swapFee, uint256 _protocolSwapFee);

    /**
     * @notice Emitted when the curve shift block delta is changed
     * @param _blockDelta new block delta setting
     **/
    event CurveShiftBlockDeltaSet(uint256 _blockDelta);

    /**
     * @dev Emitted when new forge is added
     * @param marketFactoryId Human Readable Market Factory ID in Bytes
     * @param marketFactoryAddress The Market Factory Address
     */
    event NewMarketFactory(bytes32 indexed marketFactoryId, address indexed marketFactoryAddress);

    /**
     * @notice Set/update validity of a forge-factory pair
     * @param _forgeId the forge id
     * @param _marketFactoryId the market factory id
     * @param _valid valid or not
     **/
    function setForgeFactoryValidity(
        bytes32 _forgeId,
        bytes32 _marketFactoryId,
        bool _valid
    ) external;

    /**
     * @notice Sets the PendleTreasury contract addresses.
     * @param newTreasury Address of new treasury contract.
     **/
    function setTreasury(address newTreasury) external;

    /**
     * @notice Gets a reference to the PendleRouter contract.
     * @return Returns the router contract reference.
     **/
    function router() external view returns (IPendleRouter);

    /**
     * @notice Gets a reference to the PendleRouter contract.
     * @return Returns the router contract reference.
     **/
    function pausingManager() external view returns (IPendlePausingManager);

    /**
     * @notice Gets the treasury contract address where fees are being sent to.
     * @return Address of the treasury contract.
     **/
    function treasury() external view returns (address);

    /***********
     *  FORGE  *
     ***********/

    /**
     * @notice Emitted when a forge for a protocol is added.
     * @param forgeId Forge and protocol identifier.
     * @param forgeAddress The address of the added forge.
     **/
    event ForgeAdded(bytes32 indexed forgeId, address indexed forgeAddress);

    /**
     * @notice Adds a new forge for a protocol.
     * @param forgeId Forge and protocol identifier.
     * @param forgeAddress The address of the added forge.
     **/
    function addForge(bytes32 forgeId, address forgeAddress) external;

    /**
     * @notice Store new OT and XYT details.
     * @param forgeId Forge and protocol identifier.
     * @param ot The address of the new XYT.
     * @param xyt The address of the new XYT.
     * @param underlyingAsset Token address of the underlying asset.
     * @param expiry Yield contract expiry in epoch time.
     **/
    function storeTokens(
        bytes32 forgeId,
        address ot,
        address xyt,
        address underlyingAsset,
        uint256 expiry
    ) external;

    /**
     * @notice Set a new forge fee
     * @param _forgeFee new forge fee
     **/
    function setForgeFee(uint256 _forgeFee) external;

    /**
     * @notice Gets the OT and XYT tokens.
     * @param forgeId Forge and protocol identifier.
     * @param underlyingYieldToken Token address of the underlying yield token.
     * @param expiry Yield contract expiry in epoch time.
     * @return ot The OT token references.
     * @return xyt The XYT token references.
     **/
    function getPendleYieldTokens(
        bytes32 forgeId,
        address underlyingYieldToken,
        uint256 expiry
    ) external view returns (IPendleYieldToken ot, IPendleYieldToken xyt);

    /**
     * @notice Gets a forge given the identifier.
     * @param forgeId Forge and protocol identifier.
     * @return forgeAddress Returns the forge address.
     **/
    function getForgeAddress(bytes32 forgeId) external view returns (address forgeAddress);

    /**
     * @notice Checks if an XYT token is valid.
     * @param forgeId The forgeId of the forge.
     * @param underlyingAsset Token address of the underlying asset.
     * @param expiry Yield contract expiry in epoch time.
     * @return True if valid, false otherwise.
     **/
    function isValidXYT(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external view returns (bool);

    /**
     * @notice Checks if an OT token is valid.
     * @param forgeId The forgeId of the forge.
     * @param underlyingAsset Token address of the underlying asset.
     * @param expiry Yield contract expiry in epoch time.
     * @return True if valid, false otherwise.
     **/
    function isValidOT(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external view returns (bool);

    function validForgeFactoryPair(bytes32 _forgeId, bytes32 _marketFactoryId)
        external
        view
        returns (bool);

    /**
     * @notice Gets a reference to a specific OT.
     * @param forgeId Forge and protocol identifier.
     * @param underlyingYieldToken Token address of the underlying yield token.
     * @param expiry Yield contract expiry in epoch time.
     * @return ot Returns the reference to an OT.
     **/
    function otTokens(
        bytes32 forgeId,
        address underlyingYieldToken,
        uint256 expiry
    ) external view returns (IPendleYieldToken ot);

    /**
     * @notice Gets a reference to a specific XYT.
     * @param forgeId Forge and protocol identifier.
     * @param underlyingAsset Token address of the underlying asset
     * @param expiry Yield contract expiry in epoch time.
     * @return xyt Returns the reference to an XYT.
     **/
    function xytTokens(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external view returns (IPendleYieldToken xyt);

    /***********
     *  MARKET *
     ***********/

    event MarketPairAdded(address indexed market, address indexed xyt, address indexed token);

    function addMarketFactory(bytes32 marketFactoryId, address marketFactoryAddress) external;

    function isMarket(address _addr) external view returns (bool result);

    function isXyt(address _addr) external view returns (bool result);

    function addMarket(
        bytes32 marketFactoryId,
        address xyt,
        address token,
        address market
    ) external;

    function setMarketFees(uint256 _swapFee, uint256 _protocolSwapFee) external;

    function setInterestUpdateRateDeltaForMarket(uint256 _interestUpdateRateDeltaForMarket)
        external;

    function setLockParams(uint256 _lockNumerator, uint256 _lockDenominator) external;

    function setExpiryDivisor(uint256 _expiryDivisor) external;

    function setCurveShiftBlockDelta(uint256 _blockDelta) external;

    /**
     * @notice Displays the number of markets currently existing.
     * @return Returns markets length,
     **/
    function allMarketsLength() external view returns (uint256);

    function forgeFee() external view returns (uint256);

    function interestUpdateRateDeltaForMarket() external view returns (uint256);

    function expiryDivisor() external view returns (uint256);

    function lockNumerator() external view returns (uint256);

    function lockDenominator() external view returns (uint256);

    function swapFee() external view returns (uint256);

    function protocolSwapFee() external view returns (uint256);

    function curveShiftBlockDelta() external view returns (uint256);

    function getMarketByIndex(uint256 index) external view returns (address market);

    /**
     * @notice Gets a market given a future yield token and an ERC20 token.
     * @param xyt Token address of the future yield token as base asset.
     * @param token Token address of an ERC20 token as quote asset.
     * @return market Returns the market address.
     **/
    function getMarket(
        bytes32 marketFactoryId,
        address xyt,
        address token
    ) external view returns (address market);

    /**
     * @notice Gets a market factory given the identifier.
     * @param marketFactoryId MarketFactory identifier.
     * @return marketFactoryAddress Returns the factory address.
     **/
    function getMarketFactoryAddress(bytes32 marketFactoryId)
        external
        view
        returns (address marketFactoryAddress);

    function getMarketFromKey(
        address xyt,
        address token,
        bytes32 marketFactoryId
    ) external view returns (address market);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

struct TokenReserve {
    uint256 weight;
    uint256 balance;
}

struct PendingTransfer {
    uint256 amount;
    bool isOut;
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;

import "./IPendleRouter.sol";

interface IPendleMarketFactory {
    /**
     * @notice Creates a market given a protocol ID, future yield token, and an ERC20 token.
     * @param xyt Token address of the futuonlyCorere yield token as base asset.
     * @param token Token address of an ERC20 token as quote asset.
     * @return market Returns the address of the newly created market.
     **/
    function createMarket(address xyt, address token) external returns (address market);

    /**
     * @notice Gets a reference to the PendleRouter contract.
     * @return Returns the router contract reference.
     **/
    function router() external view returns (IPendleRouter);

    function marketFactoryId() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPendleBaseToken.sol";
import "./IPendleForge.sol";

interface IPendleYieldToken is IERC20, IPendleBaseToken {
    /**
     * @notice Emitted when burning OT or XYT tokens.
     * @param user The address performing the burn.
     * @param amount The amount to be burned.
     **/
    event Burn(address indexed user, uint256 amount);

    /**
     * @notice Emitted when minting OT or XYT tokens.
     * @param user The address performing the mint.
     * @param amount The amount to be minted.
     **/
    event Mint(address indexed user, uint256 amount);

    /**
     * @notice Burns OT or XYT tokens from user, reducing the total supply.
     * @param user The address performing the burn.
     * @param amount The amount to be burned.
     **/
    function burn(address user, uint256 amount) external;

    /**
     * @notice Mints new OT or XYT tokens for user, increasing the total supply.
     * @param user The address to send the minted tokens.
     * @param amount The amount to be minted.
     **/
    function mint(address user, uint256 amount) external;

    /**
     * @notice Gets the forge address of the PendleForge contract for this yield token.
     * @return Retuns the forge address.
     **/
    function forge() external view returns (IPendleForge);

    /**
     * @notice Returns the address of the underlying asset.
     * @return Returns the underlying asset address.
     **/
    function underlyingAsset() external view returns (address);

    /**
     * @notice Returns the address of the underlying yield token.
     * @return Returns the underlying yield token address.
     **/
    function underlyingYieldToken() external view returns (address);

    /**
     * @notice let the router approve itself to spend OT/XYT/LP from any wallet
     * @param user user to approve
     **/
    function approveRouter(address user) external;
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
pragma solidity 0.7.6;

interface IPendlePausingManager {
    event AddPausingAdmin(address admin);
    event RemovePausingAdmin(address admin);
    event PendingForgeEmergencyHandler(address _pendingForgeHandler);
    event PendingMarketEmergencyHandler(address _pendingMarketHandler);
    event PendingLiqMiningEmergencyHandler(address _pendingLiqMiningHandler);
    event ForgeEmergencyHandlerSet(address forgeEmergencyHandler);
    event MarketEmergencyHandlerSet(address marketEmergencyHandler);
    event LiqMiningEmergencyHandlerSet(address liqMiningEmergencyHandler);

    event PausingManagerLocked();
    event ForgeHandlerLocked();
    event MarketHandlerLocked();
    event LiqMiningHandlerLocked();

    event SetForgePaused(bytes32 forgeId, bool settingToPaused);
    event SetForgeAssetPaused(bytes32 forgeId, address underlyingAsset, bool settingToPaused);
    event SetForgeAssetExpiryPaused(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry,
        bool settingToPaused
    );

    event SetForgeLocked(bytes32 forgeId);
    event SetForgeAssetLocked(bytes32 forgeId, address underlyingAsset);
    event SetForgeAssetExpiryLocked(bytes32 forgeId, address underlyingAsset, uint256 expiry);

    event SetMarketFactoryPaused(bytes32 marketFactoryId, bool settingToPaused);
    event SetMarketPaused(bytes32 marketFactoryId, address market, bool settingToPaused);

    event SetMarketFactoryLocked(bytes32 marketFactoryId);
    event SetMarketLocked(bytes32 marketFactoryId, address market);

    event SetLiqMiningPaused(address liqMiningContract, bool settingToPaused);
    event SetLiqMiningLocked(address liqMiningContract);

    function forgeEmergencyHandler()
        external
        view
        returns (
            address handler,
            address pendingHandler,
            uint256 timelockDeadline
        );

    function marketEmergencyHandler()
        external
        view
        returns (
            address handler,
            address pendingHandler,
            uint256 timelockDeadline
        );

    function liqMiningEmergencyHandler()
        external
        view
        returns (
            address handler,
            address pendingHandler,
            uint256 timelockDeadline
        );

    function permLocked() external view returns (bool);

    function permForgeHandlerLocked() external view returns (bool);

    function permMarketHandlerLocked() external view returns (bool);

    function permLiqMiningHandlerLocked() external view returns (bool);

    function isPausingAdmin(address) external view returns (bool);

    function setPausingAdmin(address admin, bool isAdmin) external;

    function requestForgeHandlerChange(address _pendingForgeHandler) external;

    function requestMarketHandlerChange(address _pendingMarketHandler) external;

    function requestLiqMiningHandlerChange(address _pendingLiqMiningHandler) external;

    function applyForgeHandlerChange() external;

    function applyMarketHandlerChange() external;

    function applyLiqMiningHandlerChange() external;

    function lockPausingManagerPermanently() external;

    function lockForgeHandlerPermanently() external;

    function lockMarketHandlerPermanently() external;

    function lockLiqMiningHandlerPermanently() external;

    function setForgePaused(bytes32 forgeId, bool paused) external;

    function setForgeAssetPaused(
        bytes32 forgeId,
        address underlyingAsset,
        bool paused
    ) external;

    function setForgeAssetExpiryPaused(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry,
        bool paused
    ) external;

    function setForgeLocked(bytes32 forgeId) external;

    function setForgeAssetLocked(bytes32 forgeId, address underlyingAsset) external;

    function setForgeAssetExpiryLocked(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external;

    function checkYieldContractStatus(
        bytes32 forgeId,
        address underlyingAsset,
        uint256 expiry
    ) external returns (bool _paused, bool _locked);

    function setMarketFactoryPaused(bytes32 marketFactoryId, bool paused) external;

    function setMarketPaused(
        bytes32 marketFactoryId,
        address market,
        bool paused
    ) external;

    function setMarketFactoryLocked(bytes32 marketFactoryId) external;

    function setMarketLocked(bytes32 marketFactoryId, address market) external;

    function checkMarketStatus(bytes32 marketFactoryId, address market)
        external
        returns (bool _paused, bool _locked);

    function setLiqMiningPaused(address liqMiningContract, bool settingToPaused) external;

    function setLiqMiningLocked(address liqMiningContract) external;

    function checkLiqMiningStatus(address liqMiningContract)
        external
        returns (bool _paused, bool _locked);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;
pragma abicoder v2;

import "./IPendleRouter.sol";
import "./IPendleBaseToken.sol";
import "../libraries/PendleStructs.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPendleMarket is IERC20 {
    /**
     * @notice Emitted when reserves pool has been updated
     * @param reserve0 The XYT reserves.
     * @param weight0  The XYT weight
     * @param reserve1 The generic token reserves.
     * For the generic Token weight it can be inferred by (2^40) - weight0
     **/
    event Sync(uint256 reserve0, uint256 weight0, uint256 reserve1);

    function setUpEmergencyMode(address spender) external;

    function bootstrap(
        address user,
        uint256 initialXytLiquidity,
        uint256 initialTokenLiquidity
    ) external returns (PendingTransfer[2] memory transfers, uint256 exactOutLp);

    function addMarketLiquiditySingle(
        address user,
        address inToken,
        uint256 inAmount,
        uint256 minOutLp
    ) external returns (PendingTransfer[2] memory transfers, uint256 exactOutLp);

    function addMarketLiquidityDual(
        address user,
        uint256 _desiredXytAmount,
        uint256 _desiredTokenAmount,
        uint256 _xytMinAmount,
        uint256 _tokenMinAmount
    ) external returns (PendingTransfer[2] memory transfers, uint256 lpOut);

    function removeMarketLiquidityDual(
        address user,
        uint256 inLp,
        uint256 minOutXyt,
        uint256 minOutToken
    ) external returns (PendingTransfer[2] memory transfers);

    function removeMarketLiquiditySingle(
        address user,
        address outToken,
        uint256 exactInLp,
        uint256 minOutToken
    ) external returns (PendingTransfer[2] memory transfers);

    function swapExactIn(
        address inToken,
        uint256 inAmount,
        address outToken,
        uint256 minOutAmount
    ) external returns (uint256 outAmount, PendingTransfer[2] memory transfers);

    function swapExactOut(
        address inToken,
        uint256 maxInAmount,
        address outToken,
        uint256 outAmount
    ) external returns (uint256 inAmount, PendingTransfer[2] memory transfers);

    function redeemLpInterests(address user) external returns (uint256 interests);

    function getReserves()
        external
        view
        returns (
            uint256 xytBalance,
            uint256 xytWeight,
            uint256 tokenBalance,
            uint256 tokenWeight,
            uint256 currentBlock
        );

    function factoryId() external view returns (bytes32);

    function token() external view returns (address);

    function xyt() external view returns (address);
}

// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPendleBaseToken is IERC20 {
    /**
     * @notice Decreases the allowance granted to spender by the caller.
     * @param spender The address to reduce the allowance from.
     * @param subtractedValue The amount allowance to subtract.
     * @return Returns true if allowance has decreased, otherwise false.
     **/
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /**
     * @notice The yield contract start in epoch time.
     * @return Returns the yield start date.
     **/
    function start() external view returns (uint256);

    /**
     * @notice The yield contract expiry in epoch time.
     * @return Returns the yield expiry date.
     **/
    function expiry() external view returns (uint256);

    /**
     * @notice Increases the allowance granted to spender by the caller.
     * @param spender The address to increase the allowance from.
     * @param addedValue The amount allowance to add.
     * @return Returns true if allowance has increased, otherwise false
     **/
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @notice Returns the number of decimals the token uses.
     * @return Returns the token's decimals.
     **/
    function decimals() external view returns (uint8);

    /**
     * @notice Returns the name of the token.
     * @return Returns the token's name.
     **/
    function name() external view returns (string memory);

    /**
     * @notice Returns the symbol of the token.
     * @return Returns the token's symbol.
     **/
    function symbol() external view returns (string memory);

    /**
     * @notice approve using the owner's signature
     **/
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./PermissionsV2.sol";

abstract contract WithdrawableV2 is PermissionsV2 {
    using SafeERC20 for IERC20;

    event EtherWithdraw(uint256 amount, address sendTo);
    event TokenWithdraw(IERC20 token, uint256 amount, address sendTo);

    /**
     * @dev Allows governance to withdraw Ether in a Pendle contract
     *      in case of accidental ETH transfer into the contract.
     * @param amount The amount of Ether to withdraw.
     * @param sendTo The recipient address.
     */
    function withdrawEther(uint256 amount, address payable sendTo) external onlyGovernance {
        (bool success, ) = sendTo.call{value: amount}("");
        require(success, "WITHDRAW_FAILED");
        emit EtherWithdraw(amount, sendTo);
    }

    /**
     * @dev Allows governance to withdraw all IERC20 compatible tokens in a Pendle
     *      contract in case of accidental token transfer into the contract.
     * @param token IERC20 The address of the token contract.
     * @param amount The amount of IERC20 tokens to withdraw.
     * @param sendTo The recipient address.
     */
    function withdrawToken(
        IERC20 token,
        uint256 amount,
        address sendTo
    ) external onlyGovernance {
        require(_allowedToWithdraw(address(token)), "TOKEN_NOT_ALLOWED");
        token.safeTransfer(sendTo, amount);
        emit TokenWithdraw(token, amount, sendTo);
    }

    // must be overridden by the sub contracts, so we must consider explicitly
    // in each and every contract which tokens are allowed to be withdrawn
    function _allowedToWithdraw(address) internal view virtual returns (bool allowed);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "../interfaces/IPendleBaseToken.sol";
import "../interfaces/IPendleRouter.sol";

/**
 *   @title PendleBaseToken
 *   @dev The contract implements the standard ERC20 functions, plus some
 *        Pendle specific fields and functions, namely:
 *          - expiry
 *
 *        This abstract contract is inherited by PendleFutureYieldToken
 *        and PendleOwnershipToken contracts.
 **/
abstract contract PendleBaseToken is ERC20 {
    using SafeMath for uint256;

    uint256 public immutable start;
    uint256 public immutable expiry;
    IPendleRouter public immutable router;

    //// Start of EIP-2612 related part, exactly the same as UniswapV2ERC20.sol
    bytes32 public immutable DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    //// End of EIP-2612 related part

    constructor(
        address _router,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _start,
        uint256 _expiry
    ) ERC20(_name, _symbol) {
        _setupDecimals(_decimals);
        start = _start;
        expiry = _expiry;
        router = IPendleRouter(_router);

        //// Start of EIP-2612 related part, exactly the same as UniswapV2ERC20.sol, except for the noted parts below
        uint256 chainId;
        assembly {
            chainId := chainid() // chainid() is a function in assembly in this solidity version
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(_name)), // use our own _name here
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
        //// End of EIP-2612 related part
    }

    //// Start of EIP-2612 related part, exactly the same as UniswapV2ERC20.sol
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "PERMIT_EXPIRED");
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );
        address recoveredAddress = ECDSA.recover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }

    //// End of EIP-2612 related part

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal virtual override {
        require(to != address(this), "SEND_TO_TOKEN_CONTRACT");
        require(to != from, "SEND_TO_SELF");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./MathLib.sol";
import "./PendleStructs.sol";

library MarketMath {
    using SafeMath for uint256;

    /**
     * @notice calculate the exact amount of tokens that user need to put in the market
     *      in order to get back certain amount of the other token
     * @param inTokenReserve market reserve details of token that user wants to put in
     * @param outTokenReserve market reserve details of token that user wants to get back
     * @param exactOut exact amount of token that user wants to get back
     * @param swapFee swap fee ratio for swap
     * @dev The formula for this function can be referred in the AMM Specs
     */
    function _calcExactIn(
        TokenReserve memory inTokenReserve,
        TokenReserve memory outTokenReserve,
        uint256 exactOut,
        uint256 swapFee
    ) internal pure returns (uint256 exactIn) {
        uint256 weightRatio = Math.rdiv(outTokenReserve.weight, inTokenReserve.weight);
        uint256 diff = outTokenReserve.balance.sub(exactOut);
        uint256 y = Math.rdiv(outTokenReserve.balance, diff);
        uint256 foo = Math.rpow(y, weightRatio);

        foo = foo.sub(Math.RONE);
        exactIn = Math.RONE.sub(swapFee);
        exactIn = Math.rdiv(Math.rmul(inTokenReserve.balance, foo), exactIn);
    }

    /**
     * @notice calculate the exact amount of tokens that user can get back from the market
     *      if user put in certain amount of the other token
     * @param inTokenReserve market reserve details of token that user wants to put in
     * @param outTokenReserve market reserve details of token that user wants to get back
     * @param exactIn exact amount of token that user wants to put in
     * @param swapFee swap fee (percentage) for swap
     * @dev The formula for this function can be referred in the AMM Specs
     */
    function _calcExactOut(
        TokenReserve memory inTokenReserve,
        TokenReserve memory outTokenReserve,
        uint256 exactIn,
        uint256 swapFee
    ) internal pure returns (uint256 exactOut) {
        uint256 weightRatio = Math.rdiv(inTokenReserve.weight, outTokenReserve.weight);
        uint256 adjustedIn = Math.RONE.sub(swapFee);
        adjustedIn = Math.rmul(exactIn, adjustedIn);
        uint256 y = Math.rdiv(inTokenReserve.balance, inTokenReserve.balance.add(adjustedIn));
        uint256 foo = Math.rpow(y, weightRatio);
        uint256 bar = Math.RONE.sub(foo);

        exactOut = Math.rmul(outTokenReserve.balance, bar);
    }

    /**
     * @notice to calculate exact amount of lp token to be minted if single token liquidity is added to market
     * @param inAmount exact amount of the token that user wants to put in
     * @param inTokenReserve market reserve details of the token that user wants to put in
     * @param swapFee swap fee (percentage) for swap
     * @param totalSupplyLp current (before adding liquidity) lp supply
     * @dev swap fee applies here since add liquidity by single token is equivalent of a swap
     * @dev used when add liquidity by single token
     * @dev The formula for this function can be referred in the AMM Specs
     */
    function _calcOutAmountLp(
        uint256 inAmount,
        TokenReserve memory inTokenReserve,
        uint256 swapFee,
        uint256 totalSupplyLp
    ) internal pure returns (uint256 exactOutLp) {
        uint256 nWeight = inTokenReserve.weight;
        uint256 feePortion = Math.rmul(Math.RONE.sub(nWeight), swapFee);
        uint256 inAmountAfterFee = Math.rmul(inAmount, Math.RONE.sub(feePortion));

        uint256 inBalanceUpdated = inTokenReserve.balance.add(inAmountAfterFee);
        uint256 inTokenRatio = Math.rdiv(inBalanceUpdated, inTokenReserve.balance);

        uint256 lpTokenRatio = Math.rpow(inTokenRatio, nWeight);
        uint256 totalSupplyLpUpdated = Math.rmul(lpTokenRatio, totalSupplyLp);
        exactOutLp = totalSupplyLpUpdated.sub(totalSupplyLp);
        return exactOutLp;
    }

    /**
     * @notice to calculate exact amount of token that user can get back if
     *      single token liquidity is removed from market
     * @param outTokenReserve market reserve details of the token that user wants to get back
     * @param totalSupplyLp current (before adding liquidity) lp supply
     * @param inLp exact amount of the lp token (single liquidity to remove) that user wants to put in
     * @param swapFee swap fee (percentage) for swap
     * @dev swap fee applies here since add liquidity by single token is equivalent of a swap
     * @dev used when remove liquidity by single token
     * @dev The formula for this function can be referred in the AMM Specs
     */
    function _calcOutAmountToken(
        TokenReserve memory outTokenReserve,
        uint256 totalSupplyLp,
        uint256 inLp,
        uint256 swapFee
    ) internal pure returns (uint256 exactOutToken) {
        uint256 nWeight = outTokenReserve.weight;
        uint256 totalSupplyLpUpdated = totalSupplyLp.sub(inLp);
        uint256 lpRatio = Math.rdiv(totalSupplyLpUpdated, totalSupplyLp);

        uint256 outTokenRatio = Math.rpow(lpRatio, Math.rdiv(Math.RONE, nWeight));
        uint256 outTokenBalanceUpdated = Math.rmul(outTokenRatio, outTokenReserve.balance);

        uint256 outAmountTokenBeforeSwapFee = outTokenReserve.balance.sub(outTokenBalanceUpdated);

        uint256 feePortion = Math.rmul(Math.RONE.sub(nWeight), swapFee);
        exactOutToken = Math.rmul(outAmountTokenBeforeSwapFee, Math.RONE.sub(feePortion));
        return exactOutToken;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../core/PendleGovernanceManager.sol";
import "../interfaces/IPermissionsV2.sol";

abstract contract PermissionsV2 is IPermissionsV2 {
    PendleGovernanceManager public immutable override governanceManager;
    address internal initializer;

    constructor(address _governanceManager) {
        require(_governanceManager != address(0), "ZERO_ADDRESS");
        initializer = msg.sender;
        governanceManager = PendleGovernanceManager(_governanceManager);
    }

    modifier initialized() {
        require(initializer == address(0), "NOT_INITIALIZED");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == _governance(), "ONLY_GOVERNANCE");
        _;
    }

    function _governance() internal view returns (address) {
        return governanceManager.governance();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

contract PendleGovernanceManager {
    address public governance;
    address public pendingGovernance;

    event GovernanceClaimed(address newGovernance, address previousGovernance);

    event TransferGovernancePending(address pendingGovernance);

    constructor(address _governance) {
        require(_governance != address(0), "ZERO_ADDRESS");
        governance = _governance;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "ONLY_GOVERNANCE");
        _;
    }

    /**
     * @dev Allows the pendingGovernance address to finalize the change governance process.
     */
    function claimGovernance() external {
        require(pendingGovernance == msg.sender, "WRONG_GOVERNANCE");
        emit GovernanceClaimed(pendingGovernance, governance);
        governance = pendingGovernance;
        pendingGovernance = address(0);
    }

    /**
     * @dev Allows the current governance to set the pendingGovernance address.
     * @param _governance The address to transfer ownership to.
     */
    function transferGovernance(address _governance) external onlyGovernance {
        require(_governance != address(0), "ZERO_ADDRESS");
        pendingGovernance = _governance;

        emit TransferGovernancePending(pendingGovernance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}