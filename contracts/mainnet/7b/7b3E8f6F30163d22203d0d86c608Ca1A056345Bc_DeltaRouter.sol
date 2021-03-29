// SPDX-License-Identifier: UNLICENSED
// DELTA-BUG-BOUNTY
pragma solidity ^0.7.6;

import "../libs/SafeMath.sol";
import '../uniswapv2/libraries/UniswapV2Library.sol';
import "../../interfaces/IDeltaToken.sol";
import "../../interfaces/IRebasingLiquidityToken.sol";
import "../../interfaces/IDeepFarmingVault.sol";
import "../../interfaces/IWETH.sol";
import '../uniswapv2/libraries/Math.sol';

/**
 * @dev This contract be be whitelisted as noVesting since it can receive delta token
 * when swapping half of the eth when providing liquidity with eth only.
 */
contract DeltaRouter {
    using SafeMath for uint256;
    bool public disabled;

    address public immutable DELTA_WETH_UNISWAP_PAIR;
    IWETH constant public WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IDeltaToken public immutable DELTA_TOKEN;
    IDeepFarmingVault public immutable DEEP_FARMING_VAULT;
    IRebasingLiquidityToken public immutable REBASING_TOKEN;

    constructor(address _deltaToken, address _DELTA_WETH_UNISWAP_PAIR, address _DEEP_FARMING_VAULT, address _REBASING_TOKEN) {
        require(_deltaToken != address(0), "Invalid DELTA_TOKEN Address");
        require(_DELTA_WETH_UNISWAP_PAIR != address(0), "Invalid DeltaWethPair Address");
        require(_DEEP_FARMING_VAULT != address(0), "Invalid DeepFarmingVault Address");
        require(_REBASING_TOKEN != address(0), "Invalid RebasingToken Address");

        DELTA_TOKEN = IDeltaToken(_deltaToken);
        DELTA_WETH_UNISWAP_PAIR = _DELTA_WETH_UNISWAP_PAIR;
        DEEP_FARMING_VAULT = IDeepFarmingVault(_DEEP_FARMING_VAULT);
        REBASING_TOKEN = IRebasingLiquidityToken(_REBASING_TOKEN);

        IRebasingLiquidityToken(_REBASING_TOKEN).approve(address(_DEEP_FARMING_VAULT), uint(-1));
        IUniswapV2Pair(_DELTA_WETH_UNISWAP_PAIR).approve(address(_REBASING_TOKEN), uint(-1));
    }
    
    function deltaGovernance() public view returns (address) {
        return DELTA_TOKEN.governance();
    }

    function onlyMultisig() private view {
        require(msg.sender == deltaGovernance(), "!governance");
    }

    function refreshApproval() public {
        IUniswapV2Pair(DELTA_WETH_UNISWAP_PAIR).approve(address(REBASING_TOKEN), uint(-1));
        REBASING_TOKEN.approve(address(DEEP_FARMING_VAULT), uint(-1));
    }

    function disable() public {
        onlyMultisig();
        disabled = true;
    }

    function rescueTokens(address token) public {
        onlyMultisig();
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
    
    function rescueEth() public {
        onlyMultisig();
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success);
    }

    receive() external payable {
       revert("DeltaRouter: INVALID_OPERATION");
    }

    /// @notice Add liquidity using ETH only with a minimum lp amount to receive
    /// getRLPTokenPerEthUnit() can be used to estimate the number of
    /// lp take can be minted from an ETH amount
    function addLiquidityETHOnly(uint256 _minLpOut, bool _autoStake) public payable {
        require(!disabled, 'DeltaRouter: DISABLED');

        uint256 buyAmount = msg.value.div(2);
        require(buyAmount >= 5, "DeltaRouter: MINIMUM_LIQUIDITY_THRESHOLD_UNMET");
        WETH.deposit{value: msg.value}();

        (uint256 deltaReserve, uint256 wethReserve, ) = IUniswapV2Pair(DELTA_WETH_UNISWAP_PAIR).getReserves();
        uint256 outDelta = UniswapV2Library.getAmountOut(buyAmount, wethReserve, deltaReserve);
        // We swap for half the amount of delta
        WETH.transfer(DELTA_WETH_UNISWAP_PAIR, buyAmount);
        IUniswapV2Pair(DELTA_WETH_UNISWAP_PAIR).swap(outDelta, 0, address(this), "");
        
        // Now we will have too much delta because of slippage always so we quote for number of ETH instead
        // uint256 optimalDelta = UniswapV2Library.quote(buyAmount, wethReserve.add(buyAmount), deltaReserve.sub(outDelta)); //amountin reservein reserveother

        // Well, no. You bought DELTA above which means you will have slippage in the direction of having less DELTA relative to the
        // remaining ETH. So actually you need to get the number of ETH to match the (slightly smaller amount) DELTA
        // that you actually have now.
        uint256 optimalWETH = UniswapV2Library.quote(outDelta, deltaReserve.sub(outDelta), wethReserve.add(buyAmount));
        uint256 optimalDelta = outDelta;
        if(optimalWETH > buyAmount) {
            // Matching uses more ETH than we have.
            // This happens because DELTA price has increased enough that it's more than what was sacrificed to slippage
            optimalWETH = buyAmount;
            optimalDelta = UniswapV2Library.quote(buyAmount, wethReserve.add(buyAmount), deltaReserve.sub(outDelta));
        }

        // Feed the pair and refund the guy
        DELTA_TOKEN.transfer(DELTA_WETH_UNISWAP_PAIR, optimalDelta);
        WETH.transfer(DELTA_WETH_UNISWAP_PAIR, optimalWETH);
        {
            WETH.transfer(msg.sender, buyAmount - optimalWETH);
        }

        mintWrapAndStakeOrNot(_autoStake, _minLpOut);
    }

    function stakeRLP(uint256 amount) private {
        DEEP_FARMING_VAULT.depositFor(msg.sender, amount, 0);
    }

    function mintWrapAndStakeOrNot(bool _autoStake, uint256 minOut) private {
        uint256 mintedLP = IUniswapV2Pair(DELTA_WETH_UNISWAP_PAIR).mint(address(this));
        require(mintedLP >= minOut, "DeltaRouter: MINTED_LP_LOWER_THAN_EXPECTED");
        uint256 mintedRLP = REBASING_TOKEN.wrapWithReturn();
        if(_autoStake){
            stakeRLP(mintedRLP);
        } else {
            IERC20(address(REBASING_TOKEN)).transfer(msg.sender, mintedRLP);
        }
    }

    function addLiquidityBothSides(uint256 _maxDeltaAmount, uint256 _minLpOut, bool _autoStake) public payable {
        require(!disabled, 'DeltaRouter: DISABLED');
        
        WETH.deposit{value: msg.value}();
        (uint256 deltaReserve, uint256 wethReserve, ) = IUniswapV2Pair(DELTA_WETH_UNISWAP_PAIR).getReserves();
        uint256 optimalDelta = UniswapV2Library.quote(msg.value, wethReserve, deltaReserve); //amountin reservein reserveother
        require(_maxDeltaAmount >= optimalDelta, "DeltaRouter: OPTIMAL_QUOTE_EXCEEDS_MAX_DELTA_AMOUNT");
        // We have to transfer to here first because the pair cannot be a immature recieverS
        bool success = DELTA_TOKEN.transferFrom(msg.sender, address(this), optimalDelta);
        DELTA_TOKEN.transfer(DELTA_WETH_UNISWAP_PAIR, optimalDelta);
        require(success, "DeltaRouter: TRANSFER_FAILED");
        WETH.transfer(DELTA_WETH_UNISWAP_PAIR, msg.value);
        
        mintWrapAndStakeOrNot(_autoStake, _minLpOut);
    }

    function getOptimalDeltaAmountForEthAmount(uint256 _ethAmount) public view returns (uint256 optimalDeltaAmount) {
        (uint256 deltaReserve, uint256 wethReserve, ) = IUniswapV2Pair(DELTA_WETH_UNISWAP_PAIR).getReserves();
        optimalDeltaAmount = UniswapV2Library.quote(_ethAmount, wethReserve, deltaReserve);
    }

    function getOptimalEthAmountForDeltaAmount(uint256 _deltaAmount) public view returns (uint256 optimalEthAmount) {
        (uint256 deltaReserve, uint256 wethReserve, ) = IUniswapV2Pair(DELTA_WETH_UNISWAP_PAIR).getReserves();
        optimalEthAmount = UniswapV2Library.quote(_deltaAmount, deltaReserve, wethReserve);
    }

    function getRLPTokenPerEthUnit(uint256 _ethAmount) public view returns (uint256 liquidity) {
        (uint256 deltaReserve, uint256 reserveWeth, ) = IUniswapV2Pair(DELTA_WETH_UNISWAP_PAIR).getReserves();
        uint256 halfEthAmount = _ethAmount.div(2);
        uint256 outDelta = UniswapV2Library.getAmountOut(halfEthAmount, reserveWeth, deltaReserve);
        uint256 totalSupply = IUniswapV2Pair(DELTA_WETH_UNISWAP_PAIR).totalSupply();
    

        uint256 optimalDeltaAmount = UniswapV2Library.quote(halfEthAmount, reserveWeth, deltaReserve);
        uint256 optimalWETHAmount = halfEthAmount;

        if (optimalDeltaAmount > outDelta) {
            optimalWETHAmount = UniswapV2Library.quote(outDelta, deltaReserve, reserveWeth);
            optimalDeltaAmount = outDelta;
        }
        
        deltaReserve -= optimalDeltaAmount;
        reserveWeth += optimalWETHAmount;

        uint256 rlpPerLP = IRebasingLiquidityToken(REBASING_TOKEN).rlpPerLP();
        liquidity = Math.min(optimalDeltaAmount.mul(totalSupply) / deltaReserve, optimalWETHAmount.mul(totalSupply) / reserveWeth).mul(rlpPerLP).div(1e18);
    }

    function getRLPTokenPerBothSideUnits(uint256 _deltaAmount, uint256 _ethAmount) public view returns (uint256 liquidity) {
        (uint256 deltaReserve, uint256 reserveWeth, ) = IUniswapV2Pair(DELTA_WETH_UNISWAP_PAIR).getReserves();
        uint256 totalSupply = IUniswapV2Pair(DELTA_WETH_UNISWAP_PAIR).totalSupply();

        uint256 optimalDeltaAmount = UniswapV2Library.quote(_ethAmount, reserveWeth, deltaReserve);
        uint256 optimalWETHAmount = _ethAmount;

        if (optimalDeltaAmount > _deltaAmount) {
            optimalWETHAmount = UniswapV2Library.quote(_deltaAmount, deltaReserve, reserveWeth);
            optimalDeltaAmount = _deltaAmount;
        }

        uint256 rlpPerLP = IRebasingLiquidityToken(REBASING_TOKEN).rlpPerLP();
        liquidity = Math.min(optimalDeltaAmount.mul(totalSupply) / deltaReserve, optimalWETHAmount.mul(totalSupply) / reserveWeth).mul(rlpPerLP).div(1e18);
    }
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

pragma solidity ^0.7.6;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMathUniswap for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(IUniswapV2Factory(factory).getPair(tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.6;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 

import "../common/OVLTokenTypes.sol";

interface IDeltaToken is IERC20 {
    function vestingTransactions(address, uint256) external view returns (VestingTransaction memory);
    function getUserInfo(address) external view returns (UserInformationLite memory);
    function getMatureBalance(address, uint256) external view returns (uint256);
    function liquidityRebasingPermitted() external view returns (bool);
    function lpTokensInPair() external view returns (uint256);
    function governance() external view returns (address);
    function performLiquidityRebasing() external;
    function distributor() external view returns (address);
    function totalsForWallet(address ) external view returns (WalletTotals memory totals);
    function adjustBalanceOfNoVestingAccount(address, uint256,bool) external;
    function userInformation(address user) external view returns (UserInformation memory);

}

pragma experimental ABIEncoderV2;
pragma solidity ^0.7.6;
import "./IERC20Upgradeable.sol";
interface IRebasingLiquidityToken is IERC20Upgradeable {
    function tokenCaller() external;
    function reserveCaller(uint256,uint256) external;
    function wrapWithReturn() external returns (uint256);
    function wrap() external;
    function rlpPerLP() external view returns (uint256);
}

pragma abicoder v2;

struct RecycleInfo {
    uint256 booster;
    uint256 farmedDelta;
    uint256 farmedETH;
    uint256 recycledDelta;
    uint256 recycledETH;
}



interface IDeepFarmingVault {
    function addPermanentCredits(address,uint256) external;
    function addNewRewards(uint256 amountDELTA, uint256 amountWETH) external;
    function adminRescueTokens(address token, uint256 amount) external;
    function setCompundBurn(bool shouldBurn) external;
    function compound(address person) external;
    function exit() external;
    function withdrawRLP(uint256 amount) external;
    function realFarmedOfPerson(address person) external view returns (RecycleInfo memory);
    function deposit(uint256 numberRLP, uint256 numberDELTA) external;
    function depositFor(address person, uint256 numberRLP, uint256 numberDELTA) external;
    function depositWithBurn(uint256 numberDELTA) external;
    function depositForWithBurn(address person, uint256 numberDELTA) external;
}

pragma solidity >=0.6.0 <0.8.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint256);
}

pragma solidity ^0.7.6;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity ^0.7.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUniswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
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

// SPDX-License-Identifier: UNLICENSED
// DELTA-BUG-BOUNTY

pragma solidity ^0.7.6;

struct VestingTransaction {
    uint256 amount;
    uint256 fullVestingTimestamp;
}

struct WalletTotals {
    uint256 mature;
    uint256 immature;
    uint256 total;
}

struct UserInformation {
    // This is going to be read from only [0]
    uint256 mostMatureTxIndex;
    uint256 lastInTxIndex;
    uint256 maturedBalance;
    uint256 maxBalance;
    bool fullSenderWhitelisted;
    // Note that recieving immature balances doesnt mean they recieve them fully vested just that senders can do it
    bool immatureReceiverWhitelisted;
    bool noVestingWhitelisted;
}

struct UserInformationLite {
    uint256 maturedBalance;
    uint256 maxBalance;
    uint256 mostMatureTxIndex;
    uint256 lastInTxIndex;
}

struct VestingTransactionDetailed {
    uint256 amount;
    uint256 fullVestingTimestamp;
    // uint256 percentVestedE4;
    uint256 mature;
    uint256 immature;
}


uint256 constant QTY_EPOCHS = 7;

uint256 constant SECONDS_PER_EPOCH = 172800; // About 2days

uint256 constant FULL_EPOCH_TIME = SECONDS_PER_EPOCH * QTY_EPOCHS;

// Precision Multiplier -- this many zeros (23) seems to get all the precision needed for all 18 decimals to be only off by a max of 1 unit
uint256 constant PM = 1e23;

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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