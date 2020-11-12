// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;


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


interface IPowerKeeper {
    function usePower(address master) external returns (uint256);
    function power(address master) external view returns (uint256);
    function totalPower() external view returns (uint256);
    event PowerGained(address indexed master, uint256 amount);
    event PowerUsed(address indexed master, uint256 amount);
}

interface IMilker {
    function bandits(uint256 percent) external returns (uint256, uint256, uint256);
    function sheriffsVaultCommission() external returns (uint256);
    function sheriffsPotDistribution() external returns (uint256);
    function isWhitelisted(address holder) external view returns (bool);
    function getPeriod() external view returns (uint256);
}


contract StableV2 is Ownable, IPowerKeeper {
    using SafeMath for uint256;

    // Stakeshot contains snapshot of aggregated staking history.
    struct Stakeshot {
        uint256 block;  // number of block stakeshooted
        uint256 volume; // amount of tokens in the stable just after the "shoot" moment
        uint256 power;  // amount of currently accumulated power available at block with number `block`
    }

    // Contract allowed to spend collected power to create MILK.
    IMilker private _milker;

    // Staking ERC20 token of the stable (specified once at the contract constraction).
    IERC20 private _token;

    // Variables used to work properly with inflationary/deflationary tokens.
    uint256 private _maxUnits;
    uint256 private _tokensToPowerDelimiter;

    // Amount of tokens by holders and total amount of tokens in the stable.
    mapping(address => uint256) private _tokens;
    uint256 private _totalTokens;

    // Most actual stakeshots by holders.
    mapping(address => Stakeshot) private _stakeshots;

    // Total amount of power accumulated in the stable.
    uint256 private _totalPower;
    uint256 private _totalPowerBlock;


    // Staking/claiming events.
    event Staked(address indexed holder, uint256 tokens);
    event Claimed(address indexed holder, uint256 tokens);


    modifier onlyMilker() {
        require(address(_milker) == _msgSender(), "StableV2: caller is not the Milker contract");
        _;
    }


    constructor(address milker, address token, uint256 maxUnits, uint256 tokensToPowerDelimiter) public {
        require(address(milker) != address(0), "StableV2: Milker contract address cannot be empty");
        require(address(token) != address(0), "StableV2: ERC20 token contract address cannot be empty");
        require(tokensToPowerDelimiter > 0, "StableV2: delimiter used to convert between tokens and units cannot be zero");
        _milker = IMilker(milker);
        _token = IERC20(token);
        _maxUnits = maxUnits;
        _tokensToPowerDelimiter = tokensToPowerDelimiter;
        _totalPowerBlock = block.number;
    }

    function stake(uint256 tokens) external {
        address holder = msg.sender;
        require(address(_milker) != address(0), "StableV2: Milker contract is not set up");
        require(!_milker.isWhitelisted(holder), "StableV2: whitelisted holders cannot stake tokens");

        // Recalculate total power and power collected by the holder
        _update(holder);

        // Transfer provided tokens to the StableV2 contract
        bool ok = _token.transferFrom(holder, address(this), tokens);
        require(ok, "StableV2: unable to transfer tokens to the StableV2 contract");

        // Register staked tokens
        uint256 units = _maxUnits != 0 ? tokens.mul(_maxUnits.div(_token.totalSupply())) : tokens;
        _tokens[holder] = _tokens[holder].add(units);
        _totalTokens = _totalTokens.add(units);

        // Update stakeshot's volume
        _stakeshots[holder].volume = _tokens[holder];

        // Emit event to the logs so can be effectively used later
        emit Staked(holder, tokens);
    }

    function claim(uint256 tokens) external {
        address holder = msg.sender;
        require(address(_milker) != address(0), "StableV2: Milker contract is not set up");
        require(!_milker.isWhitelisted(holder), "StableV2: whitelisted holders cannot claim tokens");

        // Recalculate total power and power collected by the holder
        _update(holder);

        // Transfer requested tokens from the StableV2 contract
        bool ok = _token.transfer(holder, tokens);
        require(ok, "StableV2: unable to transfer tokens from the StableV2 contract");

        // Unregister claimed tokens
        uint256 units = _maxUnits != 0 ? tokens.mul(_maxUnits.div(_token.totalSupply())) : tokens;
        _tokens[holder] = _tokens[holder].sub(units);
        _totalTokens = _totalTokens.sub(units);

        // Update stakeshot's volume
        _stakeshots[holder].volume = _tokens[holder];

        // Emit event to the logs so can be effectively used later
        emit Claimed(holder, tokens);
    }

    function usePower(address holder) external override onlyMilker returns (uint256 powerUsed) {

        // Recalculate total power and power collected by the holder
        _update(holder);

        // Product MILK to the holder according to the accumulated power
        powerUsed = _stakeshots[holder].power;
        _stakeshots[holder].power = 0;
        _totalPower = _totalPower.sub(powerUsed);

        // Emit event to the logs so can be effectively used later
        emit PowerUsed(holder, powerUsed);
    }

    function milker() public view returns (address) {
        return address(_milker);
    }

    function token() public view returns (address) {
        return address(_token);
    }

    function tokens(address holder) public view returns (uint256) {
        uint256 unitsPerToken = _maxUnits != 0 ? _maxUnits.div(_token.totalSupply()) : 1;
        return _tokens[holder].div(unitsPerToken);
    }

    function totalTokens() public view returns (uint256) {
        uint256 unitsPerToken = _maxUnits != 0 ? _maxUnits.div(_token.totalSupply()) : 1;
        return _totalTokens.div(unitsPerToken);
    }

    function power(address holder) public view override returns (uint256) {
        Stakeshot storage s = _stakeshots[holder];
        uint256 duration = block.number.sub(s.block);
        if (s.block > 0 && duration > 0) {
            uint256 powerGained = s.volume.div(_tokensToPowerDelimiter).mul(duration);
            return s.power.add(powerGained);
        }
        return s.power;
    }

    function totalPower() public view override returns (uint256) {
        uint256 duration = block.number.sub(_totalPowerBlock);
        if (duration > 0) {
            uint256 powerGained = _totalTokens.div(_tokensToPowerDelimiter).mul(duration);
            return _totalPower.add(powerGained);
        }
        return _totalPower;
    }

    function stakeshot(address holder) public view returns (uint256, uint256, uint256) {
        uint256 unitsPerToken = _maxUnits != 0 ? _maxUnits.div(_token.totalSupply()) : 1;
        Stakeshot storage s = _stakeshots[holder];
        return (s.block, s.volume.div(unitsPerToken), s.power);
    }

    function _update(address holder) private {

        // Update the stakeshot
        Stakeshot storage s = _stakeshots[holder];
        uint256 duration = block.number.sub(s.block);
        if (s.block > 0 && duration > 0) {
            uint256 powerGained = s.volume.div(_tokensToPowerDelimiter).mul(duration);
            s.power = s.power.add(powerGained);
            emit PowerGained(holder, powerGained);
        }
        s.block = block.number;
        s.volume = _tokens[holder];

        // Update total power counter variables
        duration = block.number.sub(_totalPowerBlock);
        if (duration > 0) {
            uint256 powerGained = _totalTokens.div(_tokensToPowerDelimiter).mul(duration);
            _totalPower = _totalPower.add(powerGained);
            _totalPowerBlock = block.number;
        }
    }
}