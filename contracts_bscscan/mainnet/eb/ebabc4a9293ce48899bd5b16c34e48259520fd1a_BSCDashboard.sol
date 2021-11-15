// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/SafeMath.sol";
import "../libraries/SafeDecimal.sol";
import "../interfaces/IMasterChef.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IDashboard.sol";
import "../interfaces/IPinecone.sol";
import "../helpers/ERC20.sol";
import "../interfaces/IPancakeFactory.sol";
import "../interfaces/IAlpaca.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IPineconeToken.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BSCDashboard is OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeDecimal for uint256;

    IPriceCalculator public priceCalculator;
    IAlpacaCalculator public alpacaCalculator;
    IWexCalculator public wexCalculator;
    IPineconeFarm public pineconeFarm;

    IMasterChef private constant cakeMaster = IMasterChef(0x73feaa1eE314F8c655E354234017bE2193C9E24E);
    IPancakeFactory private constant factory = IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);

    uint256 private constant BLOCK_PER_DAY = 28800;
    uint256 private constant BLOCK_PER_YEAR = 10512000;
    uint256 private constant UNIT = 1e18;

    address private constant CAKE_BNB = 0x0eD7e52944161450477ee417DE9Cd3a859b14fD0;
    address private constant BUSD_BNB = 0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16;
    IERC20 private constant WBNB = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IERC20 private constant CAKE = IERC20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    IERC20 private constant BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

    IMdexCalculator public mdexCalculator;
    IRabbitCalculator public rabbitCalculator;

    function initialize() external initializer {
        __Ownable_init();
    }

    function setPineconeFarm(address addr) external onlyOwner {
        pineconeFarm = IPineconeFarm(addr);
    }

    function setPriceCalculator(address addr) external onlyOwner {
        priceCalculator = IPriceCalculator(addr);
    }

    function setAlpacaCalculator(address addr) external onlyOwner {
        alpacaCalculator = IAlpacaCalculator(addr);
    }

    function setWexCalculator(address addr) external onlyOwner {
        wexCalculator = IWexCalculator(addr);
    }

    function setMdexCalculator(address addr) external onlyOwner {
        mdexCalculator = IMdexCalculator(addr);
    }

    function setRabbitCalculator(address addr) external onlyOwner {
        rabbitCalculator = IRabbitCalculator(addr);
    }

    function cakePerYearOfPool(uint256 pid) public view returns(uint256) {
        (, uint256 allocPoint,,) = cakeMaster.poolInfo(pid);
        return cakeMaster.cakePerBlock().mul(BLOCK_PER_YEAR).mul(allocPoint).div(cakeMaster.totalAllocPoint());
    }

    function cakePerDayOfPool(uint256 pid) public view returns(uint256) {
        (, uint256 allocPoint,,) = cakeMaster.poolInfo(pid);
        return cakeMaster.cakePerBlock().mul(BLOCK_PER_DAY).mul(allocPoint).div(cakeMaster.totalAllocPoint());
    }

    function tokenPriceInBNB(address token)  public view returns(uint256) {
        address pair = factory.getPair(token, address(WBNB));
        uint256 decimal = uint256(ERC20(token).decimals());

        return WBNB.balanceOf(pair).mul(10**decimal).div(IERC20(token).balanceOf(pair));
    }

    function cakePriceInBNB() public view returns(uint256) {
        return WBNB.balanceOf(CAKE_BNB).mul(UNIT).div(CAKE.balanceOf(CAKE_BNB));
    }

    function bnbPriceInUSD() public view returns(uint256) {
        return BUSD.balanceOf(BUSD_BNB).mul(UNIT).div(WBNB.balanceOf(BUSD_BNB));
    }

    function tvl(address flip, uint256 amount) public view returns (uint256) {
        if (flip == address(CAKE)) {
            return cakePriceInBNB().mul(bnbPriceInUSD()).mul(amount).div(1e36);
        }
        address _token0 = IPancakePair(flip).token0();
        address _token1 = IPancakePair(flip).token1();
        if (_token0 == address(WBNB) || _token1 == address(WBNB)) {
            uint256 bnb = WBNB.balanceOf(address(flip)).mul(amount).div(IERC20(flip).totalSupply());
            uint256 price = bnbPriceInUSD();
            return bnb.mul(price).div(UNIT).mul(2);
        }
        uint256 balanceToken0 = IERC20(_token0).balanceOf(flip);
        uint256 price = tokenPriceInBNB(_token0);
        return balanceToken0.mul(price).div(UNIT).mul(bnbPriceInUSD()).div(UNIT).mul(2);
    }

    function cakePoolDailyApr(uint256 pid) public view returns(uint256) {
        (address token,,,) = cakeMaster.poolInfo(pid);
        uint256 poolSize = tvl(token, IERC20(token).balanceOf(address(cakeMaster))).mul(UNIT).div(bnbPriceInUSD());
        return cakePriceInBNB().mul(cakePerDayOfPool(pid)).div(poolSize);
    }

    function compoundAPYOfCakePool(uint256 pid) public view returns(uint256) {
        uint256 __apr = cakePoolDailyApr(pid);
        return compundApy(__apr);
    }

    function compundApy(uint256 dApr) public pure returns(uint256) {
        uint256 compoundTimes = 365;
        uint256 unitAPY = UNIT + dApr;
        uint256 result = UNIT;
        for(uint256 i=0; i<compoundTimes; i++) {
            result = (result * unitAPY) / UNIT;
        }
        return result - UNIT;
    }

    function vaultAlpacaApyOfWex(address vault, uint256 pid) public view returns(uint256 totalApy, uint256 vaultApy, uint256 alpacaCompoundingApy) {
        (uint256 vaultApr, uint256 alpacaApr) = alpacaCalculator.vaultApr(vault, pid);
        uint256 base_daily_apr = alpacaApr/ 365;
        uint256 wex_daily_apr = wexCalculator.wexPoolDailyApr();
        uint256 wex_apy = compundApy(wex_daily_apr);
        alpacaCompoundingApy = base_daily_apr.mul(wex_apy).div(wex_daily_apr);
        vaultApy = vaultApr;
        totalApy = vaultApy.add(alpacaCompoundingApy);
    }

    function vaultCakeApyOfWex(uint256 cakePid) public view returns(uint256) {
        uint256 base_daily_apr = cakePoolDailyApr(cakePid);
        uint256 wex_daily_apr = wexCalculator.wexPoolDailyApr();
        uint256 wex_apy = compundApy(wex_daily_apr);
        wex_apy = base_daily_apr.mul(wex_apy).div(wex_daily_apr);
        return wex_apy;
    }

    function vaultRabbitApyOfMdex(address token, uint256 pid) public view returns(uint256 totalApy, uint256 vaultApy, uint256 rabbitCompoundingApy) {
        (uint256 vaultApr, uint256 rabbitApr) = rabbitCalculator.vaultApr(token, pid);
        uint256 base_daily_apr = rabbitApr/ 365;
        uint256 mdex_daily_apr = mdexCalculator.mdexPoolDailyApr();
        uint256 mdex_apy = compundApy(mdex_daily_apr);
        rabbitCompoundingApy = base_daily_apr.mul(mdex_apy).div(mdex_daily_apr);
        vaultApy = vaultApr;
        totalApy = vaultApy.add(rabbitCompoundingApy);
    }

    function vaultCakeApyOfMdex(uint256 cakePid) public view returns(uint256) {
        uint256 base_daily_apr = cakePoolDailyApr(cakePid);
        uint256 mdx_daily_apr = mdexCalculator.mdexPoolDailyApr();
        uint256 mdx_apy = compundApy(mdx_daily_apr);
        mdx_apy = base_daily_apr.mul(mdx_apy).div(mdx_daily_apr);
        return mdx_apy;
    }

    function apyOfPool(
        uint256 pid,
        uint256 cakePid
    ) 
        public view 
        returns(
            uint256 earned0Apy, 
            uint256 earned1Apy
        ) 
    {
        (address want, address strat) = pineconeFarm.poolInfoOf(pid);
        if (strat == address(0)) {
            return (0,0);
        }
        earned0Apy = 0;
        earned1Apy = 0;
        StakeType _type = IPineconeStrategy(strat).stakeType();
        uint256 earnedPctApy = earnedApy(pid);
        uint256 fee = IPineconeStrategy(strat).performanceFee(UNIT);
        if(_type == StakeType.Alpaca_Wex) {
            address farmAddress = IPineconeStrategy(strat).stratAddress();
            uint256 farmPid = IPineconeStrategy(strat).farmPid();
            (uint256 _apy,,) = vaultAlpacaApyOfWex(farmAddress, farmPid);
            uint256 alpaca_apy = _apy.mul(UNIT - fee).div(UNIT);
            uint256 toPctAmount = pctToTokenAmount(want);
            uint256 pct_apy =  _apy.mul(fee).div(UNIT);
            pct_apy = pct_apy.mul(toPctAmount).div(UNIT);
            earned0Apy = alpaca_apy;
            earned1Apy = pct_apy.add(earnedPctApy);
        }
        else if (_type == StakeType.Cake_Wex) {
            uint256 _apy = vaultCakeApyOfWex(cakePid);
            uint256 cake_apy = _apy.mul(UNIT - fee).div(UNIT);
            uint256 toPctAmount = pctToTokenAmount(address(CAKE));
            uint256 pct_apy =  _apy.mul(fee).div(UNIT);
            pct_apy = pct_apy.mul(toPctAmount).div(UNIT);
            earned0Apy = cake_apy;
            earned1Apy = pct_apy.add(earnedPctApy);
        } else if (_type == StakeType.Rabbit_Mdex) {
            address token  = IPineconeStrategy(strat).stakingToken();
            uint256 farmPid = IPineconeStrategy(strat).farmPid();
            (uint256 _apy,,) = vaultRabbitApyOfMdex(token, farmPid);
            uint256 rabbit_apy = _apy.mul(UNIT - fee).div(UNIT);
            uint256 toPctAmount = pctToTokenAmount(want);
            uint256 pct_apy =  _apy.mul(fee).div(UNIT);
            pct_apy = pct_apy.mul(toPctAmount).div(UNIT);
            earned0Apy = rabbit_apy;
            earned1Apy = pct_apy.add(earnedPctApy);
        } else if (_type == StakeType.Cake_Mdex) {
            uint256 _apy = vaultCakeApyOfMdex(cakePid);
            uint256 cake_apy = _apy.mul(UNIT - fee).div(UNIT);
            uint256 toPctAmount = pctToTokenAmount(address(CAKE));
            uint256 pct_apy =  _apy.mul(fee).div(UNIT);
            pct_apy = pct_apy.mul(toPctAmount).div(UNIT);
            earned0Apy = cake_apy;
            earned1Apy = pct_apy.add(earnedPctApy);
        } else if (_type == StakeType.PCTPair) {
            earned0Apy = 0;
            earned1Apy = earnedPctApy;
        }
    }

    function earnedApy(uint256 pid) public view returns(uint256) {
        uint256 pctAmt = pineconeFarm.dailyEarnedAmount(pid);
        pctAmt = pctAmt.mul(365);
        uint256 pool_tvl = tvlOfPool(pid);
        uint256 earnedPctValue = pctAmt.mul(priceCalculator.priceOfPct()).div(UNIT);
        uint256 earnedPctApy = 0;
        if (pool_tvl > 0) {
            earnedPctApy = earnedPctValue.mul(UNIT).div(pool_tvl);
        }

        return earnedPctApy;
    }

    function tvlOfPool(uint256 pid) public view returns(uint256 priceInUsd) {
        (, address strat) = pineconeFarm.poolInfoOf(pid);
        if (strat == address(0)) {
            return 0;
        }
        return IPineconeStrategy(strat).tvl();
    }

    function pctToTokenAmount(address token) public view returns(uint256) {
        uint256 bnbAmount = UNIT;
        uint256 tokenPrice = priceCalculator.priceOfToken(token);
        if (token != address(WBNB)) {
            uint256 bnbPrice = priceCalculator.priceOfBNB();
            bnbAmount = tokenPrice.mul(UNIT).div(bnbPrice);
        }

        uint256 pctAmount = pineconeFarm.amountPctToMint(bnbAmount);
        uint256 pctPrice = priceCalculator.priceOfPct();
        uint256 toAmount = pctAmount.mul(pctPrice).div(tokenPrice);
        return toAmount;
    }

    function userInfoOfPool(
        uint256 pid, 
        address user) 
        public view 
        returns(
            uint256 depositAmt, 
            uint256 depositedAt, 
            uint256 balance,
            uint256 earned0Amt,
            uint256 earned1Amt,
            uint256 withdrawableAmt
        )
    {
        (depositedAt, depositAmt, balance, earned0Amt, earned1Amt, withdrawableAmt) = pineconeFarm.userInfoOfPool(pid, user);
    }

    function pctFeeOfUser(address user) public view returns(
        uint256 buyFee,
        uint256 sellFee,
        uint256 txFee
    ) {
        address pct = priceCalculator.pctToken();
        bool ret = IPineconeToken(pct).isExcludedFromFee(user);
        if (ret == true) {
            return (0,0,0);
        }

        ret = IPineconeToken(pct).isPresaleUser(user);
        if (ret == true) {
            return (0,5,0);
        }

        return (5,10,10);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "./SafeMath.sol";


library SafeDecimal {
    using SafeMath for uint256;

    uint8 public constant decimals = 18;
    uint256 public constant UNIT = 10 ** uint256(decimals);

    function unit() external pure returns (uint256) {
        return UNIT;
    }

    function multiply(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.mul(y).div(UNIT);
    }

    // https://mpark.github.io/programming/2014/08/18/exponentiation-by-squaring/
    function power(uint256 x, uint256 n) internal pure returns (uint256) {
        uint256 result = UNIT;
        while (n > 0) {
            if (n % 2 != 0) {
                result = multiply(result, x);
            }
            x = multiply(x, x);
            n /= 2;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IMasterChef {
    function cakePerBlock() view external returns(uint256);
    function totalAllocPoint() view external returns(uint256);

    function poolInfo(uint256 _pid) view external returns(address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accCakePerShare);
    function userInfo(uint256 _pid, address _account) view external returns(uint256 amount, uint256 rewardDebt);
    function poolLength() view external returns(uint256);

    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;

    function enterStaking(uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;

    function pendingCake(uint256 _pid, address _user) view external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPriceCalculator {
    function getAmountsOut(uint256 amount, address[] memory path) external view returns (uint256);
    function pricesInUSD(address[] memory assets) external view returns (uint256[] memory);
    function valueOfAsset(address asset, uint256 amount) external view returns (uint256 valueInBNB, uint256 valueInUSD);
    function priceOfBNB() external view returns (uint256);
    function priceOfCake() external view returns (uint256);
    function priceOfPct() external view returns (uint256);
    function priceOfToken(address token) external view returns(uint256);
    function pctToken() external view returns(address);
}

interface IAlpacaCalculator {
    function balanceOf(address vault, uint256 pid, address account) external view returns(uint256);
    function balanceOfib(address vault, uint256 pid, address account) external view returns(uint256);
    function vaultApr(address vault, uint256 pid) external view returns(uint256 _apr, uint256 _alpacaApr);
    function ibTokenCalculation(address vault, uint256 amount) external view returns(uint256);
}

interface IWexCalculator {
    function wexPoolDailyApr() external view returns(uint256);
}

interface IMdexCalculator {
    function mdexPoolDailyApr() external view returns(uint256);
}

interface IRabbitCalculator {
    function balanceOf(address token, uint256 pid, address account) external view returns(uint256);
    function balanceOfib(uint256 pid, address account) external view returns(uint256);
    function vaultApr(address token, uint256 pid) external view returns(uint256 _apr, uint256 _rabbitApr);
    function ibToken(address token) external view returns(address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

enum StakeType {
    None,
    Alpaca_Wex,
    Cake_Wex,
    RewardsCake_Wex,
    PCTPair,
    Rabbit_Mdex,
    Cake_Mdex,
    RewardsCake_Mdex
}

interface IPineconeFarm {
    function add(uint256 _allocPCTPoint, address _want, bool _withUpdate, address _strat) external returns(uint256);
    function set(uint256 _pid, uint256 _allocPCTPoint, bool _withUpdate) external;
    function setMinter(address _minter, bool _canMint) external;
    function mintForProfit(address _to, uint256 _cakeProfit, bool _updatePCTRewards) external returns(uint256);
    function stakeRewardsTo(address _to, uint256 _amount) external;
    function setCakeRewardsPid(uint256 _cakeRewardsPid) external;
    function setPctPerBlock(uint256 _PCTPerBlock, uint256 _startBlock) external;
    function amountPctToMint(uint256 _bnbProfit) external view returns (uint256);
    function inCaseTokensGetStuck(address _token, uint256 _amount) external;
    function dailyEarnedAmount(uint256 _pid) external view returns(uint256);
    function pineconeStratAddress(uint256 _pid) external view returns(address);
    function poolInfoOf(uint256 _pid) external view returns(address want, address strat);
    function userInfoOfPool(uint256 _pid, address _user) external view 
        returns(
            uint256 depositedAt, 
            uint256 depositAmt,
            uint256 balanceValue,
            uint256 earned0Amt,
            uint256 earned1Amt,
            uint256 withdrawbaleAmt
        ); 
    function claimBNB() external;
}

interface IPineconeStrategy {
    function earn() external;
    function farm() external;
    function pause() external;
    function unpause() external;
    function sharesTotal() external view returns (uint256);
    function sharesOf(address _user) external view returns(uint256);
    function withdrawableBalanceOf(address _user) external view returns(uint256);
    function deposit(uint256 _wantAmt, address _user) external returns(uint256);
    function depositForPresale(uint256 _wantAmt, address _user) external returns(uint256);
    function withdraw(uint256 _wantAmt, address _user) external returns(uint256, uint256);
    function withdrawAll(address _user) external returns(uint256, uint256, uint256);
    function claim(address _user) external returns(uint256, uint256);
    function claimBNB(uint256 shares, address _user) external returns(uint256);
    function pendingBNB(uint256 _shares, address _user) external view returns(uint256);
    function stakeType() external view returns(StakeType);
    function earned0Address() external view returns(address);
    function earned1Address() external view returns(address);
    function performanceFee(uint256 _profit) external view returns(uint256);
    function stratAddress() external view returns(address);
    function tvl() external view returns(uint256 priceInUsd);
    function farmPid() external view returns(uint256);
    function userInfoOf(address _user, uint256 _addPct) external view 
        returns(
            uint256 depositedAt, 
            uint256 depositAmt,
            uint256 balanceValue,
            uint256 earned0Amt,
            uint256 earned1Amt,
            uint256 withdrawbaleAmt
        ); 
    function inCaseTokensGetStuck(address _token, uint256 _amount) external;
    function stakingToken() external view returns(address);
    function setWithdrawFeeFactor(uint256 _withdrawFeeFactor) external;
}

interface IOwner {
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Context.sol";
import "../libraries/SafeMath.sol";
import "../interfaces/IERC20.sol";

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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
    constructor(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
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
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
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

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _setupDecimals(uint8 decimals_) internal {
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVault {

  /// @dev Return the total ERC20 entitled to the token holders. Be careful of unaccrued interests.
  function totalToken() external view returns (uint256);

  /// @dev Add more ERC20 to the bank. Hope to get some good returns.
  function deposit(uint256 amountToken) external payable;

  /// @dev Withdraw ERC20 from the bank by burning the share tokens.
  function withdraw(uint256 share) external;

  /// @dev Request funds from user through Vault
  function requestFunds(address targetedToken, uint amount) external;

  function vaultDebtVal() external view returns(uint256);

  function config() external view returns(IVaultConfig);

  function token() external view returns(address);
}

interface IVaultConfig {
  /// @dev Return minimum BaseToken debt size per position.
  function minDebtSize() external view returns (uint256);

  /// @dev Return the interest rate per second, using 1e18 as denom.
  function getInterestRate(uint256 debt, uint256 floating) external view returns (uint256);

  /// @dev Return the address of wrapped native token.
  function getWrappedNativeAddr() external view returns (address);

  /// @dev Return the address of wNative relayer.
  function getWNativeRelayer() external view returns (address);

  /// @dev Return the address of fair launch contract.
  function getFairLaunchAddr() external view returns (address);

  /// @dev Return the bps rate for reserve pool.
  function getReservePoolBps() external view returns (uint256);

  /// @dev Return the bps rate for Avada Kill caster.
  function getKillBps() external view returns (uint256);

  /// @dev Return whether the given address is a worker.
  function isWorker(address worker) external view returns (bool);

  /// @dev Return whether the given worker accepts more debt. Revert on non-worker.
  function acceptDebt(address worker) external view returns (bool);

  /// @dev Return the work factor for the worker + BaseToken debt, using 1e4 as denom. Revert on non-worker.
  function workFactor(address worker, uint256 debt) external view returns (uint256);

  /// @dev Return the kill factor for the worker + BaseToken debt, using 1e4 as denom. Revert on non-worker.
  function killFactor(address worker, uint256 debt) external view returns (uint256);
}

interface IFairLaunch {
    function pendingAlpaca(uint256 _pid, address _user) external view returns (uint256);
    function deposit(address _for, uint256 _pid, uint256 _amount) external;
    function withdraw(address _for, uint256 _pid, uint256 _amount) external;
    function withdrawAll(address _for, uint256 _pid) external;
    function harvest(uint256 _pid) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IPineconeToken {
    function mint(address _to, uint256 _amount) external;
    function mintAvailable() external view returns(bool);
    function pctPair() external view returns(address);
    function isMinter(address _addr) external view returns(bool);
    function addPresaleUser(address _account) external;
    function maxTxAmount() external view returns(uint256);
    function isExcludedFromFee(address _account) external view returns(bool);
    function isPresaleUser(address _account) external view returns(bool);
}

interface IPineconeTokenCallee {
    function transferCallee(address from, address to) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

