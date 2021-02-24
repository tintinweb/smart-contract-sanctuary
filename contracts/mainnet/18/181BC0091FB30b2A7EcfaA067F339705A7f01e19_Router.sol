pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./interfaces/IBalancerPool.sol";
import "./interfaces/IStakingManager.sol";
import "./templates/Initializable.sol";

/**
 * @title Router
 * @dev Liquidity management contract
 */
contract Router is Ownable, Initializable {
    using SafeMath for uint256;

    /**
     * @dev informs that EURxb router balance is empty
     */
    event EmptyEURxbBalance();

    address private _teamAddress;
    IStakingManager private _stakingManager;
    uint256 private _startTime;
    uint256 private _endTime;
    address private _tUSDT;
    address private _tUSDC;
    address private _tBUSD;
    address private _tDAI;
    IERC20 private _tEURxb;

    IUniswapV2Router02 private _uniswapRouter;

    bool _isClosedContract = false;

    mapping(address => address) private _pools;

    constructor(address teamAddress) public {
        _teamAddress = teamAddress;
    }

    /**
     * @dev setup uniswap router
     */
    function configure(
        address stakingManager,
        address uniswapRouter,
        address tUSDT,
        address tUSDC,
        address tBUSD,
        address tDAI,
        address tEURxb
    ) external initializer {
        // set uniswap router contract address
        _uniswapRouter = IUniswapV2Router02(uniswapRouter);
        // set staking manager contract address
        _stakingManager = IStakingManager(stakingManager);
        // set stablecoins contract addresses
        _tUSDT = tUSDT;
        _tUSDC = tUSDC;
        _tBUSD = tBUSD;
        _tDAI = tDAI;
        // set eurxb contract address
        _tEURxb = IERC20(tEURxb);
        // set stakingManager start/end times
        _startTime = _stakingManager.startTime();
        _endTime = _stakingManager.endTime();
        // set balancer pools and uniswap pairs addresses
        address[4] memory pools = _stakingManager.getPools();
        _pools[_tUSDT] = pools[0];
        _pools[_tUSDC] = pools[1];
        _pools[_tBUSD] = pools[2];
        _pools[_tDAI] = pools[3];
    }

    /**
     * @return are the tokens frozen
     */
    function isClosedContract() external view returns (bool) {
        return _isClosedContract;
    }

    /**
     * @return staking manager address
     */
    function stakingManager() external view returns (address) {
        return address(_stakingManager);
    }

    /**
     * @return uniswap router address
     */
    function uniswapRouter() external view returns (address) {
        return address(_uniswapRouter);
    }

    /**
     * @return EURxb address
     */
    function eurxb() external view returns (address) {
        return address(_tEURxb);
    }

    /**
     * @return start time
     */
    function startTime() external view returns (uint256) {
        return _startTime;
    }

    /**
     * @return end time
     */
    function endTime() external view returns (uint256) {
        return _endTime;
    }

    /**
     * @return stable coins pool addresses
     */
    function getPoolAddress(address token) external view returns (address) {
        return _pools[token];
    }

    /**
     * @return team address
     */
    function teamAddress() external view returns (address) {
        return _teamAddress;
    }

    /**
     * @dev set team address
     * @param team address
     */
    function setTeamAddress(address team) external onlyOwner {
        _teamAddress = team;
    }

    /**
     * @dev Close contract
     */
    function closeContract() external onlyOwner {
        require(_endTime < block.timestamp, "Time is not over");
        uint256 balance = _tEURxb.balanceOf(address(this));
        if (balance > 0) {
            _tEURxb.transfer(_teamAddress, balance);
        }
        _isClosedContract = true;
    }

    /**
     * @dev Adding liquidity
     * @param token address
     * @param amount number of tokens
     */
    function addLiquidity(address token, uint256 amount) external {
        require(block.timestamp >= _startTime, "The time has not come yet");
        require(!_isClosedContract, "Contract closed");
        if (token == _tUSDC || token == _tDAI) {
            _addLiquidityBalancer(_msgSender(), token, amount);
        } else if (token == _tUSDT || token == _tBUSD) {
            _addLiquidityUniswap(_msgSender(), token, amount);
        } else {
            revert("token is not supported");
        }
    }

    /**
     * @dev Adds liquidity for USDT-EURxb and BUSD-EURxb pairs
     * @param token address
     * @param amount number of tokens
     */
    function _addLiquidityUniswap(address sender, address token, uint256 amount) internal {
        address pairAddress = _pools[token];

        uint256 exchangeAmount = amount.div(2);

        (uint256 tokenRatio, uint256 eurRatio) = _getUniswapReservesRatio(token);

        uint256 amountEUR = exchangeAmount.mul(eurRatio).div(tokenRatio);
        uint256 balanceEUR = _tEURxb.balanceOf(address(this));

        require(balanceEUR >= 10 ** 18, 'EmptyEURxbBalance'); // balance great then 1 EURxb token

        // check if we don't have enough eurxb tokens
        if (balanceEUR <= amountEUR) {
            amountEUR = balanceEUR;
            // we can take only that much
            exchangeAmount = amountEUR.mul(tokenRatio).div(eurRatio);
            emit EmptyEURxbBalance();
        }

        TransferHelper.safeTransferFrom(token, sender, address(this), exchangeAmount.mul(2));

        // approve transfer tokens and eurxbs to uniswap pair
        TransferHelper.safeApprove(token, address(_uniswapRouter), exchangeAmount);
        TransferHelper.safeApprove(address(_tEURxb), address(_uniswapRouter), amountEUR);

        (, , uint256 liquidityAmount) = _uniswapRouter
        .addLiquidity(
            address(_tEURxb),
            token,
            amountEUR, // token B
            exchangeAmount, // token A
            0, // min A amount
            0, // min B amount
            address(this), // mint liquidity to router, not user
            block.timestamp + 10 minutes // deadline 10 minutes
        );

        uint256 routerTokenBalance = IERC20(token).balanceOf(address(this));
        TransferHelper.safeTransfer(token, _teamAddress, routerTokenBalance);

        // reward user with liquidity
        if (block.timestamp > _endTime) {
            TransferHelper.safeTransfer(pairAddress, sender, liquidityAmount);
        } else {
            TransferHelper.safeApprove(pairAddress, address(_stakingManager), liquidityAmount);
            _stakingManager.addStake(sender, pairAddress, liquidityAmount);
        }

        TransferHelper.safeApprove(token, address(_uniswapRouter), 0);
    }

    function _addLiquidityBalancer(address sender, address token, uint256 amount) internal {
        address poolAddress = _pools[token];
        IBalancerPool pool = IBalancerPool(poolAddress);
        uint256 totalSupply = pool.totalSupply();

        uint256 exchangeAmount = amount.div(2);

        (uint256 tokenRatio, uint256 eurRatio) = _getBalancerReservesRatio(token, pool);
        uint256 amountEUR = exchangeAmount.mul(eurRatio).div(tokenRatio);
        uint256 balanceEUR = _tEURxb.balanceOf(address(this));

        require(balanceEUR >= 10 ** 18, 'EmptyEURxbBalance'); // balance great then 1 EURxb token

        uint256 routerTokenBalance = IERC20(token).balanceOf(address(this));

        // check if we don't have enough eurxb tokens
        if (balanceEUR <= amountEUR) {
            amountEUR = balanceEUR;
            // we can take only that much
            exchangeAmount = amountEUR.mul(tokenRatio).div(eurRatio);
            emit EmptyEURxbBalance();
        }

        TransferHelper.safeTransferFrom(token, sender, address(this), exchangeAmount.mul(2));

        uint256 amountBPT;
        address addressEURxb = address(_tEURxb);

        { // to save stack space
            TransferHelper.safeApprove(token, poolAddress, exchangeAmount);
            TransferHelper.safeApprove(addressEURxb, poolAddress, amountEUR);

            uint256 balance = pool.getBalance(addressEURxb);
            amountBPT = totalSupply.mul(amountEUR).div(balance);
            amountBPT = amountBPT.mul(99).div(100);

            uint256[] memory data = new uint256[](2);
            data[0] = amountEUR;
            data[1] = exchangeAmount;
            pool.joinPool(amountBPT, data);
        }

        TransferHelper.safeTransfer(token, _teamAddress, exchangeAmount);

        routerTokenBalance = (IERC20(token).balanceOf(address(this))).sub(routerTokenBalance);
        TransferHelper.safeTransfer(token, msg.sender, routerTokenBalance);
        TransferHelper.safeTransfer(addressEURxb, msg.sender, routerTokenBalance.mul(eurRatio).div(tokenRatio));

        if (block.timestamp > _endTime) {
            TransferHelper.safeTransfer(poolAddress, sender, amountBPT);
        } else {
            TransferHelper.safeApprove(poolAddress, address(_stakingManager), amountBPT);
            _stakingManager.addStake(sender, poolAddress, amountBPT);
        }

        TransferHelper.safeApprove(token, poolAddress, 0);
    }

    /**
     * @dev returns uniswap pair reserves numbers or default numbers
     * used to get token/eurxb ratio
     */
    function _getUniswapReservesRatio(address token)
    internal
    returns (uint256 tokenRes, uint256 eurRes)
    {
        (uint112 res0, uint112 res1,) = IUniswapV2Pair(_pools[token]).getReserves();
        if (res0 == 0 || res1 == 0) {
            (tokenRes, eurRes) = (
                (10 ** uint256(_getTokenDecimals(token))).mul(27),
                (10 ** uint256(_getTokenDecimals(address(_tEURxb)))).mul(23)
            );
        } else {
            (address token0,) = _sortTokens(token, address(_tEURxb));
            (tokenRes, eurRes) = (token == token0) ? (res0, res1) : (res1, res0);
        }
    }

    /**
     * @dev returns balancer pair reserves numbers or default numbers
     * used to get token/eurxb ratio
     * guarantees, that returned numbers greater than zero
     */
    function _getBalancerReservesRatio(address token, IBalancerPool pool)
    internal
    returns (uint256, uint256)
    {
        uint256 balanceEurXB = pool.getBalance(address(_tEURxb));
        uint256 balanceToken = pool.getBalance(token);

        if (balanceEurXB == 0 || balanceToken == 0) {
            return (
                (10 ** uint256(_getTokenDecimals(token))).mul(27),
                (10 ** uint256(_getTokenDecimals(address(_tEURxb)))).mul(23)
            );
        }

        return (balanceToken, balanceEurXB);
    }

    /**
     * @dev sorts token addresses just like uniswap router does
     */
    function _sortTokens(address tokenA, address tokenB)
    internal pure
    returns (address token0, address token1)
    {
        require(tokenA != tokenB, "identical tokens");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'zero address');
    }

    function _getTokenDecimals(address token) internal returns (uint8) {
        // bytes4(keccak256(bytes('decimals()')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x313ce567));
        require(success &&
            (data.length == 0 ||
            abi.decode(data, (uint8)) > 0 ||
            abi.decode(data, (uint8)) < 100), "DECIMALS_NOT_FOUND");
        return abi.decode(data, (uint8));
    }
}

pragma solidity ^0.6.0;

/**
 * @title IBalancerPool
 * @dev Pool balancer interface
 */
interface IBalancerPool {
    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn)
        external;

    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external returns (uint256 poolAmountOut);

    function totalSupply() external view returns (uint256);

    function getBalance(address token) external view returns (uint256);

    function getDenormalizedWeight(address token)
        external
        view
        returns (uint256);

    function getTotalDenormalizedWeight() external view returns (uint256);

    function getSwapFee() external view returns (uint256);

    function calcPoolOutGivenSingleIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountOut);
}

pragma solidity ^0.6.0;

/**
 * @title IStakingManager
 * @dev Staking manager interface
 */
interface IStakingManager {
    function addStake(
        address user,
        address pool,
        uint256 amount
    ) external;

    function startTime() external view returns (uint256);

    function endTime() external view returns (uint256);

    function getPools() external view returns (address[4] memory);
}

pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/GSN/Context.sol";


/**
 * @title Initializable allows to create initializable contracts
 * so that only deployer can initialize contract and only once
 */
contract Initializable is Context {
    bool private _isContractInitialized;
    address private _deployer;

    constructor() public {
        _deployer = _msgSender();
    }

    modifier initializer {
        require(_msgSender() == _deployer, "user not allowed to initialize");
        require(!_isContractInitialized, "contract already initialized");
        _;
        _isContractInitialized = true;
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}