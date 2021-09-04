/**
 *Submitted for verification at BscScan.com on 2021-09-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;

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
    constructor () {
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
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: contracts/utils/BalanceAccounting.sol


pragma solidity ^0.8.2;



contract BalanceAccounting {
    using SafeMath for uint256;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _mint(address account, uint256 amount) internal virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        _balances[account] = _balances[account].sub(amount, "Burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
    }

    function _set(address account, uint256 amount) internal virtual returns(uint256 oldAmount) {
        oldAmount = _balances[account];
        if (oldAmount != amount) {
            _balances[account] = amount;
            _totalSupply = _totalSupply.add(amount).sub(oldAmount);
        }
    }
}

// File: contracts/pancake/interfaces/IPancakePair.sol

pragma solidity >=0.5.0;

interface IPancakePair {
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

// File: contracts/staking/WarpStaking.sol


pragma solidity ^0.8.2;






contract WarpStaking is Ownable, BalanceAccounting {
    using SafeMath for uint256;

    struct UserData {
        uint256 startTime; // Start time of first stake
        uint256 startBlock; // Start block of first stake
        uint256 lastStakeTime; // Last time staked
        uint256 lastStakeBlock; // Last block staked
        uint256 lastResetTime; // Last time harvested
        uint256 totalHarvested; // Total amount harvested in _rewardToken
        uint256 lastTimeHarvested; // Last time harvested
        uint256 lastBlockHarvested; // Last block harvested
        uint256 currentRewards; // Current rewards in _token (will be set when requesting with userData(_), don't use directly from _userDatas)
    }

    IERC20 private _token;
    IERC20 private _rewardToken;
    IPancakePair private _lp;
    uint256 private _tokenLpIndex;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 private _apr;
    uint256 private _rewardPerTokenPerSec; // Per ETH reward in WEI
    uint256 private _period;

    uint256 private _stoppedTimestamp;

    mapping(address => UserData) private _userDatas;

    constructor(
        IERC20 token_,
        IERC20 rewardToken_,
        IPancakePair lp_,
        string memory name_,
        string memory symbol_,
        uint256 apr_,
        uint256 period_
    ) {
        require(
            address(token_) == lp_.token0() || address(token_) == lp_.token1(),
            "Missing token in lp"
        );
        require(
            address(rewardToken_) == lp_.token0() ||
                address(rewardToken_) == lp_.token1(),
            "Missing reward token in lp"
        );

        _token = token_;
        _rewardToken = rewardToken_;
        _lp = lp_;
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        _apr = apr_;
        _period = period_;

        _tokenLpIndex = address(_token) != _lp.token0() ? 0 : 1;

        _rewardPerTokenPerSec = _apr
        .mul(10**_decimals)
        .div(100) // Percent (20% = 0.2)
        .div(365)
        .div(24)
        .div(60)
        .div(60);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function token() public view returns (address) {
        return address(_token);
    }

    function rewardToken() public view returns (address) {
        return address(_rewardToken);
    }

    function lp() public view returns (address) {
        return address(_lp);
    }

    function apr() public view returns (uint256) {
        return _apr;
    }

    function period() public view returns (uint256) {
        return _period;
    }

    function tokenPriceInRewardToken() public view returns (uint256) {
        (uint256 lpReserve0, uint256 lpReserve1, uint256 lpTimestamp) = _lp
        .getReserves();

        return
            (_tokenLpIndex == 0 ? lpReserve1 : lpReserve0).mul(10**18).div(
                _tokenLpIndex == 0 ? lpReserve0 : lpReserve1
            );
    }

    function rewardTokenPriceInToken() public view returns (uint256) {
        (uint256 lpReserve0, uint256 lpReserve1, uint256 lpTimestamp) = _lp
        .getReserves();

        return
            (_tokenLpIndex == 0 ? lpReserve0 : lpReserve1).mul(10**18).div(
                _tokenLpIndex == 0 ? lpReserve1 : lpReserve0
            );
    }

    function rewardPerTokenPerSec() public view returns (uint256) {
        return _rewardPerTokenPerSec;
    }

    function isStopped() public view returns (bool) {
        return _stoppedTimestamp > 0 && _stoppedTimestamp <= block.timestamp;
    }

    function userData(address account) public view returns (UserData memory) {
        UserData memory user = _userDatas[account];
        user.currentRewards = this.currentRewards(account);
        return user;
    }

    function totalHarvested(address account) public view returns (uint256) {
        return _userDatas[account].totalHarvested;
    }

    function currentRewards(address account) public view returns (uint256) {
        UserData memory user = _userDatas[account];

        if (user.lastResetTime == 0 && user.startTime == 0) {
            return 0;
        }

        uint256 elapsedTime = (
            isStopped() ? _stoppedTimestamp : block.timestamp
        )
        .sub((user.lastResetTime != 0 ? user.lastResetTime : user.startTime));

        if (elapsedTime <= 0) {
            return 0;
        }

        return
            _rewardPerTokenPerSec.mul(elapsedTime).mul(balanceOf(account)).div(
                10**_decimals
            );
    }

    function currentRewardsInRewardToken(address account)
        public
        view
        returns (uint256)
    {
        uint256 reward = this.currentRewards(account);
        if (reward <= 0) {
            return 0;
        }

        return reward.mul(rewardTokenPriceInToken()).div(10**18);
    }

    function stop(uint256 timestamp) external onlyOwner {
        require(timestamp > 0, "Empty timestamp is not allowed");
        _stoppedTimestamp = timestamp;
        emit Stopped(timestamp);
    }

    function resume() external onlyOwner {
        require(isStopped(), "Staking is not stopped");
        _stoppedTimestamp = 0;
        emit Resumed();
    }

    function stake(uint256 amount) public virtual {
        require(amount > 0, "Empty stake is not allowed");
        require(!isStopped(), "Staking is stopped");

        _harvest(msg.sender, msg.sender);

        _token.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);

        UserData storage user = _userDatas[msg.sender];
        if (user.startTime == 0) {
            user.startBlock = block.number;
            user.startTime = block.timestamp;
        }
        user.lastStakeTime = block.timestamp;
        user.lastStakeBlock = block.number;

        emit Transfer(address(0), msg.sender, amount);
    }

    function unstake(uint256 amount) public {
        require(amount > 0, "Empty unstake is not allowed");

        uint256 periodInSec = _period.mul(24).mul(60).mul(60);
        require(
            block.timestamp >
                _userDatas[msg.sender].lastStakeTime.add(periodInSec),
            "Staking period is not over"
        );

        _harvest(msg.sender, msg.sender);

        _burn(msg.sender, amount);
        _token.transfer(msg.sender, amount);

        emit Transfer(msg.sender, address(0), amount);
    }

    function forceUnstake(
        address account,
        uint256 amount,
        bool ignoreHarvest
    ) public onlyOwner {
        require(amount > 0, "Empty unstake is not allowed");

        if (!ignoreHarvest) {
            _harvest(account, account);
        }

        _burn(account, amount);
        _token.transfer(account, amount);
        emit Transfer(account, address(0), amount);
    }

    function harvest() external returns (uint256) {
        return _harvest(msg.sender, msg.sender);
    }

    function harvestAll(address[] memory stakers) public onlyOwner {
        for (uint256 i = 0; i < stakers.length; i++) {
            _harvest(stakers[i], stakers[i]);
        }
    }

    function _harvest(
        address account,
        address receiver /*, bool force*/
    ) internal virtual returns (uint256) {
        UserData storage user = _userDatas[account];

        uint256 rewards = this.currentRewardsInRewardToken(account);
        user.lastResetTime = block.timestamp;

        if (rewards <= 0) {
            return 0;
        }

        /*if (!force) {
            require(
                user.lastBlockHarvested.add(2) <= block.number,
                "Harvest only allowed every 2 block"
            );
        }*/

        _rewardToken.transfer(receiver, rewards);
        user.lastTimeHarvested = block.timestamp;
        user.lastBlockHarvested = block.number;
        user.totalHarvested = user.totalHarvested.add(rewards);

        emit Harvest(account, receiver, rewards);
        return rewards;
    }

    function rescueToken(
        IERC20 token,
        address to,
        uint256 amount
    ) external onlyOwner {
        token.transfer(to, amount);
    }

    function ownerHarvestAll(
        address to
    ) external onlyOwner {
        _token.transfer(to, _token.balanceOf(address(this)));
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Harvest(
        address indexed from,
        address indexed receiver,
        uint256 value
    );
    event Stopped(uint256 timestamp);
    event Resumed();
}