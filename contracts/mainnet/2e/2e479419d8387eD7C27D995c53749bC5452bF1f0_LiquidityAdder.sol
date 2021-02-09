pragma solidity >=0.6.0 <0.8.0;
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

library Constants {
    address constant uniV2FactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    IUniswapV2Factory constant uniV2Factory = IUniswapV2Factory(uniV2FactoryAddress);

    address constant uniV2Router02Address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 constant uniV2Router02 = IUniswapV2Router02(uniV2Router02Address);

    uint32 constant Future2100 = 4102448400;

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
}

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

library SafeAmount {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount) internal returns (uint256)  {
        uint256 preBalance = IERC20(token).balanceOf(to);
        IERC20(token).transferFrom(from, to, amount);
        uint256 postBalance = IERC20(token).balanceOf(to);
        return postBalance.sub(preBalance);
    }
}

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Ferrum Staking interface
 */
interface IFestaked {
    
    event Staked(address indexed token, address indexed staker_, uint256 requestedAmount_, uint256 stakedAmount_);

    function stake (uint256 amount) external returns (bool);

    function stakeFor (address staker, uint256 amount) external returns (bool);

    function stakeOf(address account) external view returns (uint256);

    function getToken() external view returns (address);

    function stakedTotal() external view returns (uint256);

    function stakedBalance() external view returns (uint256);

    function stakingStarts() external view returns (uint256);

    function stakingEnds() external view returns (uint256);
}

pragma solidity >=0.6.0 <0.8.0;

interface IReshapableToken {
    function deposit(address token, uint256 amount) external returns(uint256);
}

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract SweepToOwner is Ownable {
    using SafeERC20 for IERC20;
    function sweepToOwner(address token) external onlyOwner() returns(bool) {
        IERC20(token).safeTransfer(owner(), IERC20(token).balanceOf(address(this)));
        return true;
    }
}

pragma solidity >=0.6.0 <0.8.0;

interface ISafetyLocker {
    function verifyTransfer(address source, address dest) external;
    function verifyUserAddress(address user, uint256 amount) external;
    function IsSafetyLocker() external pure returns(bool);
}

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

import "../../common/Constants.sol";
import "../../common/SafeAmount.sol";
import "./ISafetyLocker.sol";
import "../../staking/IFestaked.sol";
import "../reshape/SweepToOwner.sol";
import "../reshape/IReshapableToken.sol";
import "../safety/Locker.sol";

/**
 * A contract to safely add liquidity.
 */
contract LiquidityAdder is Ownable, SweepToOwner {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public targetToken;
    ISafetyLocker public antiBot;
    IWETH public WETH;
    uint256 public ethCap;
    uint256 public ethDeposited;

    constructor(address _targetToken, IWETH _weth) public {
        targetToken = IERC20(_targetToken);
        WETH = _weth;
        require(targetToken.totalSupply() != 0, "LA: Token has no supply.");
    }

    function setEthCap(uint256 cap) external onlyOwner {
        ethCap = cap;
    }

    function setSafetyLock(ISafetyLocker _antiBot) external onlyOwner {
        antiBot = _antiBot;
        if (address(antiBot) != address(0)) {
            require(
                ISafetyLocker(_antiBot).IsSafetyLocker(),
                "Bad safetyLocker"
            );
        }
    }

    function safeBuyWithETHAndAddLiqAndDepositAndStake(
        address _targetToken,
        address depositToken,
        IFestaked stake,
        bool shouldDeposit,
        bool shouldStake,
        uint256 deadline
    ) external payable {
        uint256 amountEth = msg.value;
        require(amountEth != 0, "No ETH was sent");
        require(shouldDeposit, "Temp: Deposit is mandatory");
        WETH.deposit{value: amountEth}();
        uint256 _ethDeposited = ethDeposited;
        uint256 _ethCap = ethCap;
        if (_ethCap != 0 && _ethDeposited.add(amountEth) > _ethCap) {
            uint256 newAmount = _ethCap.sub(_ethDeposited);
            IERC20(address(WETH)).transfer(msg.sender, amountEth.sub(newAmount));
            amountEth = newAmount;
        }
        ethDeposited = ethDeposited.add(amountEth); // Add the eth optimistically.
        _safeBuyAndAddLiqAndDepositAndStake(
            address(WETH),
            amountEth,
            _targetToken,
            depositToken,
            stake,
            shouldDeposit,
            shouldStake,
            msg.sender,
            deadline
        );
    }

    function _safeBuyAndAddLiqAndDepositAndStake(
        address sourceToken,
        uint256 sourceAmount,
        address _targetToken,
        address depositToken,
        IFestaked stake,
        bool shouldDeposit,
        bool shouldStake,
        address to,
        uint256 deadline
    ) internal {
        // First buy target tokens with a very large slippage allowed
        // Then add the bought token as liquidity.
        // If shouldDeposit, deposit those tokens.
        // If shouldStake, stake those tokens.
        // pass it all to the owner
        (uint256 sourceLeft, uint256 targetAmount) =
            _safeBuy(sourceToken, sourceAmount.div(2), _targetToken, deadline, to);
        uint256 liquidity = _addBoughtLiquidity(sourceToken, _targetToken, sourceLeft,
            targetAmount, deadline);
        address pool = Constants.uniV2Factory.getPair(
                _targetToken,
                sourceToken);
        require(pool != address(0), "Pool address is 0");
        require(IERC20(pool).balanceOf(address(this)) >= liquidity, "Not enough liquidity was generated");
        // _syncLiquiditySupply(pool);

        _safeDepositLiqAndStakeFor(pool, liquidity, depositToken, stake,
            shouldDeposit, shouldStake, to);
    }

    function _addBoughtLiquidity(address sourceToken, address _targetToken,
        uint256 sourceToAdd, uint256 targetAmount, uint256 deadline) internal returns (uint256) {

        (/*uint256 sourceUsed */, /*uint256 targetUsed */, uint256 liquidity) =
            Constants.uniV2Router02.addLiquidity(
                sourceToken,
                _targetToken,
                sourceToAdd,
                targetAmount,
                0,
                0,
                address(this),
                deadline
            );
        uint256 ethRefund = IERC20(sourceToken).balanceOf(address(this));
        if (ethRefund != 0) {
            IERC20(sourceToken).transfer(msg.sender, ethRefund);
        }
        return liquidity;
    }

    function _safeDepositLiqAndStakeFor (
        address pool, uint256 liquidity, address depositToken, IFestaked stake,
        bool shouldDeposit, bool shouldStake, address to) internal {
        if (shouldDeposit) {
            _safeDepositAndStakeFor(
                pool,
                liquidity,
                depositToken,
                stake,
                shouldStake,
                to
            );
        } else {
            IERC20(pool).safeTransfer(to, liquidity);
        }
    }

    /**
     * Make sure to approve liquidityAdder on your lp token
     */
    // function safeDepositAndStake(
    //     address lpToken,
    //     uint256 lpAmount,
    //     address depositToken,
    //     IFestaked stake,
    //     bool shouldStake
    // ) public {
    //     IERC20(lpToken).transferFrom(msg.sender, address(this), lpAmount);
    //     _safeDepositAndStakeFor(
    //         lpToken,
    //         lpAmount,
    //         depositToken,
    //         stake,
    //         shouldStake,
    //         msg.sender
    //     );
    // }

    function _safeDepositAndStakeFor(
        address lpToken,
        uint256 lpAmount,
        address depositToken,
        IFestaked stake,
        bool shouldStake,
        address to
    ) internal {
        // Deposit and get deposit tokens
        IERC20(lpToken).approve(depositToken, lpAmount);
        uint256 deposited = IReshapableToken(depositToken).deposit(lpToken, lpAmount);
        require(deposited != 0, "LA: Zero deposit");
        uint256 postLpBalance = IERC20(lpToken).balanceOf(address(this));
        if (postLpBalance != 0) {
            // Return undeposited lp.
            IERC20(lpToken).transfer(to, postLpBalance);
        }
        if (shouldStake) {
            IERC20(depositToken).approve(address(stake), deposited);
            stake.stakeFor(to, deposited); // We might not stake all.
            uint256 postDepositBalance = IERC20(depositToken).balanceOf(address(this));
            if (postDepositBalance != 0) {
                IERC20(depositToken).transfer(to, postDepositBalance);
            }
        } else {
            IERC20(depositToken).transfer(to, deposited);
        }
    }

    function _safeBuy(
        address sourceToken,
        uint256 sourceAmount,
        address _targetToken,
        uint256 deadline,
        address beneficiary
    ) internal returns (uint256, uint256) {
        address[] memory path = new address[](2);
        path[0] = sourceToken;
        path[1] = _targetToken;
        Constants.uniV2Router02.swapExactTokensForTokens(
                sourceAmount,
                0,
                path,
                address(this),
                deadline
            );
        antiBot.verifyUserAddress(beneficiary, sourceAmount);

        return (IERC20(sourceToken).balanceOf(address(this)), IERC20(_targetToken).balanceOf(address(this)));
    }

    function syncLiquiditySupply(address pool)
        external
        onlyOwner()
    {
        _syncLiquiditySupply(pool);
    }

    function _syncLiquiditySupply(address pool) internal {
        ILockerUser target = ILockerUser(address(targetToken));
        ILocker locker = target.locker();
        if (address(locker) != address(0)) {
            locker.syncLiquiditySupply(pool);
        }
    }

    /**
     * @dev to save gas call this once.
     */
    function approveMe(address token) external {
        IERC20(address(WETH)).approve(address(Constants.uniV2Router02), 2**128);
        IERC20(token).safeApprove(address(Constants.uniV2Router02), 2**128);
    }
}

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

library LockLib {

    enum LockType {
        None, NoBurnPool, NoIn, NoOut, NoTransaction,
        PenaltyOut, PenaltyIn, PenaltyInOrOut, Master, LiquidityAdder
    }

    struct TargetPolicy {
        LockType lockType;
        uint16 penaltyRateOver1000;
        bool isPermanent;
    }
}

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../common/Constants.sol";
import "./LockLib.sol";
import "./ISafetyLocker.sol";

interface ILocker {
    function syncLiquiditySupply(address pool) external;

    /**
     * @dev Fails if transaction is not allowed. Otherwise returns the penalty.
     * Returns a bool and a uint16, bool clarifying the penalty applied, and uint16 the penaltyOver1000
     */
    function lockOrGetPenalty(address source, address dest)
    external
    returns (bool, uint256);
}

interface ILockerUser {
    function locker() external view returns (ILocker);
}

/**
 * Owner can lock unlock temporarily, or make them permanent.
 * It can also add penalty to certain activities.
 * Addresses can be whitelisted or have different penalties.
 * This must be inherited by the token itself.
 */
contract Locker is ILocker, Ownable {
    // Putting all conditions in one mapping to prevent unnecessary lookup and save gas
    mapping (address=>LockLib.TargetPolicy) locked;
    mapping (address=>uint256) liquiditySupply;
    address public mustUpdate;
    address public safetyLocker;

    function allowPool(address token1, address token2)
    external onlyOwner() {
        address pool = Constants.uniV2Factory.getPair(token1, token2);
        if (pool == address(0)) {
            pool = Constants.uniV2Factory.createPair(token1, token2);
        }
        // Pool will not be opened to public yet.
        locked[pool].lockType = LockLib.LockType.NoTransaction;
        liquiditySupply[pool] = IERC20(pool).totalSupply();
    }

    function getLockType(address target) external view returns(LockLib.LockType, uint16, bool) {
        LockLib.TargetPolicy memory res = locked[target];
        return (res.lockType, res.penaltyRateOver1000, res.isPermanent);
    }

    function setSafetyLocker(address _safetyLocker) external onlyOwner() {
        safetyLocker = _safetyLocker;
        if (safetyLocker != address(0)) {
            require(ISafetyLocker(_safetyLocker).IsSafetyLocker(), "Bad safetyLocker");
        }
    }

    /**
     */
    function lockAddress(address target, LockLib.LockType lockType, uint16 penaltyRateOver1000, bool permanent)
    external
    onlyOwner()
    returns(bool) {
        require(target != address(0), "Locker: invalid target address");
        require(!locked[target].isPermanent, "Locker: address lock is permanent");

        locked[target].lockType = lockType;
        locked[target].penaltyRateOver1000 = penaltyRateOver1000;
        locked[target].isPermanent = permanent;
        return true;
    }

    function multiBlackList(address[] calldata addresses) external onlyOwner() {
        for(uint i=0; i < addresses.length; i++) {
            locked[addresses[i]].lockType = LockLib.LockType.NoTransaction;
        }
    }

    /**
     * @dev Fails if transaction is not allowed. Otherwise returns the penalty.
     * Returns a bool and a uint16, bool clarifying the penalty applied, and uint16 the penaltyOver1000
     */
    function lockOrGetPenalty(address source, address dest) external override
    returns (bool, uint256) {
        LockLib.TargetPolicy memory sourcePolicy = locked[source];
        LockLib.TargetPolicy memory destPolicy = locked[dest];
        address mustUpdateAddress = mustUpdate;
        bool overridePenalty = false;
        if (mustUpdateAddress != address(0)) {
            mustUpdate = address(0);
            uint256 newSupply = IERC20(mustUpdateAddress).totalSupply();
            if (newSupply > liquiditySupply[mustUpdateAddress]) {
                liquiditySupply[mustUpdateAddress] = newSupply;
            }
        }

        if (sourcePolicy.lockType == LockLib.LockType.Master || destPolicy.lockType == LockLib.LockType.Master) {
            // if one side is a pool, update the mustUpdateAddress
            if (destPolicy.lockType == LockLib.LockType.NoBurnPool) {
                mustUpdate = dest;
            }
            return (true, 0);
        }
        require(sourcePolicy.lockType != LockLib.LockType.NoOut &&
            sourcePolicy.lockType != LockLib.LockType.NoTransaction, "Locker: not allowed source");
        require(destPolicy.lockType != LockLib.LockType.NoIn &&
            destPolicy.lockType != LockLib.LockType.NoTransaction, "Locker: not allowed destination");
        if (destPolicy.lockType == LockLib.LockType.NoBurnPool) {
            mustUpdate = dest;
        }
        if (sourcePolicy.lockType == LockLib.LockType.NoBurnPool) {
            require (IERC20(source).totalSupply() >= liquiditySupply[source], "Cannot remove liquidity");            
        }
        uint256 sourcePenalty = 0;
        if (sourcePolicy.lockType == LockLib.LockType.PenaltyOut ||
            sourcePolicy.lockType == LockLib.LockType.PenaltyInOrOut) {
            sourcePenalty = sourcePolicy.penaltyRateOver1000;
            overridePenalty = true;
        }
        uint256 destPenalty = 0;
        if (destPolicy.lockType == LockLib.LockType.PenaltyIn ||
            destPolicy.lockType == LockLib.LockType.PenaltyInOrOut) {
            destPenalty = destPolicy.penaltyRateOver1000;
            overridePenalty = true;
        }
        if (safetyLocker != address(0)) {
            ISafetyLocker(safetyLocker).verifyTransfer(source, dest);
        }
        return (overridePenalty, Math.max(sourcePenalty, destPenalty));
    }

    function syncLiquiditySupply(address pool) override
    external {
        LockLib.LockType state = locked[pool].lockType;
        require(state != LockLib.LockType.None, "Locker: pool not defined");
        LockLib.LockType senderState = locked[msg.sender].lockType;
        require(senderState == LockLib.LockType.LiquidityAdder, "Locker: Only call from liquidity adder");
        _syncLiquiditySupply(pool);
    }

    function _syncLiquiditySupply(address pool) internal {
        liquiditySupply[pool] = IERC20(pool).totalSupply();
        if (mustUpdate == pool) {
            mustUpdate = address(0);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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
contract Ownable is Context {
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

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using Address for address;

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
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
     * Requirements
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
     * Requirements
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}