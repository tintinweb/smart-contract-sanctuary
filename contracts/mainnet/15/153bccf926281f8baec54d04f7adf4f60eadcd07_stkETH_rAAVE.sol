/**
 *Submitted for verification at Etherscan.io on 2021-02-07
*/

// SPDX-License-Identifier: GPL-3.0-only

// File: @openzeppelin/contracts/GSN/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol


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

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/ElasticERC20.sol

pragma solidity ^0.6.0;




/**
 * @dev This contract is based on the OpenZeppelin ERC20 implementation,
 * basically adding the elastic extensions.
 */
contract ElasticERC20 is Context, IERC20
{
	using SafeMath for uint256;

	uint8 constant UNSCALED_DECIMALS = 24;
	uint256 constant UNSCALED_FACTOR = 10 ** uint256(UNSCALED_DECIMALS);

	mapping (address => mapping (address => uint256)) private allowances_;

	mapping (address => uint256) private unscaledBalances_;
	uint256 private unscaledTotalSupply_;

	string private name_;
	string private symbol_;
	uint8 private decimals_;

	uint256 private scalingFactor_;

	constructor (string memory _name, string memory _symbol) public
	{
		name_ = _name;
		symbol_ = _symbol;
		_setupDecimals(18);
	}

	function name() public view returns (string memory _name)
	{
		return name_;
	}

	function symbol() public view returns (string memory _symbol)
	{
		return symbol_;
	}

	function decimals() public view returns (uint8 _decimals)
	{
		return decimals_;
	}

	function totalSupply() public view override returns (uint256 _supply)
	{
		return _scale(unscaledTotalSupply_, scalingFactor_);
	}

	function balanceOf(address _account) public view override returns (uint256 _balance)
	{
		return _scale(unscaledBalances_[_account], scalingFactor_);
	}

	function allowance(address _owner, address _spender) public view virtual override returns (uint256 _allowance)
	{
		return allowances_[_owner][_spender];
	}

	function approve(address _spender, uint256 _amount) public virtual override returns (bool _success)
	{
		_approve(_msgSender(), _spender, _amount);
		return true;
	}

	function increaseAllowance(address _spender, uint256 _addedValue) public virtual returns (bool _success)
	{
		_approve(_msgSender(), _spender, allowances_[_msgSender()][_spender].add(_addedValue));
		return true;
	}

	function decreaseAllowance(address _spender, uint256 _subtractedValue) public virtual returns (bool _success)
	{
		_approve(_msgSender(), _spender, allowances_[_msgSender()][_spender].sub(_subtractedValue, "ERC20: decreased allowance below zero"));
		return true;
	}

	function transfer(address _recipient, uint256 _amount) public virtual override returns (bool _success)
	{
		_transfer(_msgSender(), _recipient, _amount);
		return true;
	}

	function transferFrom(address _sender, address _recipient, uint256 _amount) public virtual override returns (bool _success)
	{
		_transfer(_sender, _recipient, _amount);
		_approve(_sender, _msgSender(), allowances_[_sender][_msgSender()].sub(_amount, "ERC20: transfer amount exceeds allowance"));
		return true;
	}

	function _approve(address _owner, address _spender, uint256 _amount) internal virtual
	{
		require(_owner != address(0), "ERC20: approve from the zero address");
		require(_spender != address(0), "ERC20: approve to the zero address");
		allowances_[_owner][_spender] = _amount;
		emit Approval(_owner, _spender, _amount);
	}

	function _transfer(address _sender, address _recipient, uint256 _amount) internal virtual
	{
		uint256 _unscaledAmount = _unscale(_amount, scalingFactor_);
		require(_sender != address(0), "ERC20: transfer from the zero address");
		require(_recipient != address(0), "ERC20: transfer to the zero address");
		_beforeTokenTransfer(_sender, _recipient, _amount);
		unscaledBalances_[_sender] = unscaledBalances_[_sender].sub(_unscaledAmount, "ERC20: transfer amount exceeds balance");
		unscaledBalances_[_recipient] = unscaledBalances_[_recipient].add(_unscaledAmount);
		emit Transfer(_sender, _recipient, _amount);
	}

	function _mint(address _account, uint256 _amount) internal virtual
	{
		uint256 _unscaledAmount = _unscale(_amount, scalingFactor_);
		require(_account != address(0), "ERC20: mint to the zero address");
		_beforeTokenTransfer(address(0), _account, _amount);
		unscaledTotalSupply_ = unscaledTotalSupply_.add(_unscaledAmount);
		uint256 _maxScalingFactor = _calcMaxScalingFactor(unscaledTotalSupply_);
		require(scalingFactor_ <= _maxScalingFactor, "unsupported scaling factor");
		unscaledBalances_[_account] = unscaledBalances_[_account].add(_unscaledAmount);
		emit Transfer(address(0), _account, _amount);
	}

	function _burn(address _account, uint256 _amount) internal virtual
	{
		uint256 _unscaledAmount = _unscale(_amount, scalingFactor_);
		require(_account != address(0), "ERC20: burn from the zero address");
		_beforeTokenTransfer(_account, address(0), _amount);
		unscaledBalances_[_account] = unscaledBalances_[_account].sub(_unscaledAmount, "ERC20: burn amount exceeds balance");
		unscaledTotalSupply_ = unscaledTotalSupply_.sub(_unscaledAmount);
		emit Transfer(_account, address(0), _amount);
	}

	function _setupDecimals(uint8 _decimals) internal
	{
		decimals_ = _decimals;
		scalingFactor_ = 10 ** uint256(_decimals);
	}

	function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal virtual { }

	function unscaledTotalSupply() public view returns (uint256 _supply)
	{
		return unscaledTotalSupply_;
	}

	function unscaledBalanceOf(address _account) public view returns (uint256 _balance)
	{
		return unscaledBalances_[_account];
	}

	function scalingFactor() public view returns (uint256 _scalingFactor)
	{
		return scalingFactor_;
	}

	function maxScalingFactor() public view returns (uint256 _maxScalingFactor)
	{
		return _calcMaxScalingFactor(unscaledTotalSupply_);
	}

	function _calcMaxScalingFactor(uint256 _unscaledTotalSupply) internal pure returns (uint256 _maxScalingFactor)
	{
		return uint256(-1).div(_unscaledTotalSupply);
	}

	function _scale(uint256 _unscaledAmount, uint256 _scalingFactor) internal pure returns (uint256 _amount)
	{
		return _unscaledAmount.mul(_scalingFactor).div(UNSCALED_FACTOR);
	}

	function _unscale(uint256 _amount, uint256 _scalingFactor) internal pure returns (uint256 _unscaledAmount)
	{
		return _amount.mul(UNSCALED_FACTOR).div(_scalingFactor);
	}

	function _setScalingFactor(uint256 _scalingFactor) internal
	{
		uint256 _maxScalingFactor = _calcMaxScalingFactor(unscaledTotalSupply_);
		require(0 < _scalingFactor && _scalingFactor <= _maxScalingFactor, "unsupported scaling factor");
		scalingFactor_ = _scalingFactor;
	}
}

// File: contracts/Executor.sol

pragma solidity ^0.6.0;

/**
 * @dev This library provides support for the dynamic execution of external
 * contract calls.
 */
library Executor
{
	struct Target {
		address to;
		bytes data;
	}

	function addTarget(Target[] storage _targets, address _to, bytes memory _data) internal
	{
		_targets.push(Target({ to: _to, data: _data }));
	}

	function removeTarget(Target[] storage _targets, uint256 _index) internal
	{
		require(_index < _targets.length, "invalid index");
		_targets[_index] = _targets[_targets.length - 1];
		_targets.pop();
	}

	function executeAll(Target[] storage _targets) internal
	{
		for (uint256 _i = 0; _i < _targets.length; _i++) {
			Target storage _target = _targets[_i];
			bool _success = _externalCall(_target.to, _target.data);
			require(_success, "call failed");
		}
	}

	function _externalCall(address _to, bytes memory _data) private returns (bool _success)
	{
		assembly {
			_success := call(gas(), _to, 0, add(_data, 0x20), mload(_data), 0, 0)
		}
	}
}

// File: contracts/GElastic.sol

pragma solidity ^0.6.0;

/**
 * @dev This interface exposes the base functionality of GElasticToken.
 */
interface GElastic
{
	// view functions
	function referenceToken() external view returns (address _referenceToken);
	function treasury() external view returns (address _treasury);
	function rebaseMinimumDeviation() external view returns (uint256 _rebaseMinimumDeviation);
	function rebaseDampeningFactor() external view returns (uint256 _rebaseDampeningFactor);
	function rebaseTreasuryMintPercent() external view returns (uint256 _rebaseTreasuryMintPercent);
	function rebaseTimingParameters() external view returns (uint256 _rebaseMinimumInterval, uint256 _rebaseWindowOffset, uint256 _rebaseWindowLength);
	function rebaseActive() external view returns (bool _rebaseActive);
	function rebaseAvailable() external view returns (bool _available);
	function lastRebaseTime() external view returns (uint256 _lastRebaseTime);
	function epoch() external view returns (uint256 _epoch);
	function lastExchangeRate() external view returns (uint256 _exchangeRate);
	function currentExchangeRate() external view returns (uint256 _exchangeRate);
	function pair() external view returns (address _pair);

	// open functions
	function rebase() external;

	// priviledged functions
	function activateOracle(address _pair) external;
	function activateRebase() external;
	function setTreasury(address _newTreasury) external;
	function setRebaseMinimumDeviation(uint256 _newRebaseMinimumDeviation) external;
	function setRebaseDampeningFactor(uint256 _newRebaseDampeningFactor) external;
	function setRebaseTreasuryMintPercent(uint256 _newRebaseTreasuryMintPercent) external;
	function setRebaseTimingParameters(uint256 _newRebaseMinimumInterval, uint256 _newRebaseWindowOffset, uint256 _newRebaseWindowLength) external;
	function addPostRebaseTarget(address _to, bytes memory _data) external;
	function removePostRebaseTarget(uint256 _index) external;

	// emitted events
	event Rebase(uint256 indexed _epoch, uint256 _oldScalingFactor, uint256 _newScalingFactor);
	event ChangeTreasury(address _oldTreasury, address _newTreasury);
	event ChangeRebaseMinimumDeviation(uint256 _oldRebaseMinimumDeviation, uint256 _newRebaseMinimumDeviation);
	event ChangeRebaseDampeningFactor(uint256 _oldRebaseDampeningFactor, uint256 _newRebaseDampeningFactor);
	event ChangeRebaseTreasuryMintPercent(uint256 _oldRebaseTreasuryMintPercent, uint256 _newRebaseTreasuryMintPercent);
	event ChangeRebaseTimingParameters(uint256 _oldRebaseMinimumInterval, uint256 _oldRebaseWindowOffset, uint256 _oldRebaseWindowLength, uint256 _newRebaseMinimumInterval, uint256 _newRebaseWindowOffset, uint256 _newRebaseWindowLength);
	event AddPostRebaseTarget(address indexed _to, bytes _data);
	event RemovePostRebaseTarget(address indexed _to, bytes _data);
}

// File: contracts/GElasticTokenManager.sol

pragma solidity ^0.6.0;


/**
 * @dev This library helps managing rebase parameters and calculations.
 */
library GElasticTokenManager
{
	using SafeMath for uint256;
	using GElasticTokenManager for GElasticTokenManager.Self;

	uint256 constant MAXIMUM_REBASE_TREASURY_MINT_PERCENT = 25e16; // 25%

	uint256 constant DEFAULT_REBASE_MINIMUM_INTERVAL = 24 hours;
	uint256 constant DEFAULT_REBASE_WINDOW_OFFSET = 17 hours; // 5PM UTC
	uint256 constant DEFAULT_REBASE_WINDOW_LENGTH = 1 hours;
	uint256 constant DEFAULT_REBASE_MINIMUM_DEVIATION = 5e16; // 5%
	uint256 constant DEFAULT_REBASE_DAMPENING_FACTOR = 10; // 10x to reach 100%
	uint256 constant DEFAULT_REBASE_TREASURY_MINT_PERCENT = 10e16; // 10%

	struct Self {
		address treasury;

		uint256 rebaseMinimumDeviation;
		uint256 rebaseDampeningFactor;
		uint256 rebaseTreasuryMintPercent;

		uint256 rebaseMinimumInterval;
		uint256 rebaseWindowOffset;
		uint256 rebaseWindowLength;

		bool rebaseActive;
		uint256 lastRebaseTime;
		uint256 epoch;
	}

	function init(Self storage _self, address _treasury) public
	{
		_self.treasury = _treasury;

		_self.rebaseMinimumDeviation = DEFAULT_REBASE_MINIMUM_DEVIATION;
		_self.rebaseDampeningFactor = DEFAULT_REBASE_DAMPENING_FACTOR;
		_self.rebaseTreasuryMintPercent = DEFAULT_REBASE_TREASURY_MINT_PERCENT;

		_self.rebaseMinimumInterval = DEFAULT_REBASE_MINIMUM_INTERVAL;
		_self.rebaseWindowOffset = DEFAULT_REBASE_WINDOW_OFFSET;
		_self.rebaseWindowLength = DEFAULT_REBASE_WINDOW_LENGTH;

		_self.rebaseActive = false;
		_self.lastRebaseTime = 0;
		_self.epoch = 0;
	}

	function activateRebase(Self storage _self) public
	{
		require(!_self.rebaseActive, "already active");
		_self.rebaseActive = true;
		_self.lastRebaseTime = now.sub(now.mod(_self.rebaseMinimumInterval)).add(_self.rebaseWindowOffset);
	}

	function setTreasury(Self storage _self, address _treasury) public
	{
		require(_treasury != address(0), "invalid treasury");
		_self.treasury = _treasury;
	}

	function setRebaseMinimumDeviation(Self storage _self, uint256 _rebaseMinimumDeviation) public
	{
		require(_rebaseMinimumDeviation > 0, "invalid minimum deviation");
		_self.rebaseMinimumDeviation = _rebaseMinimumDeviation;
	}

	function setRebaseDampeningFactor(Self storage _self, uint256 _rebaseDampeningFactor) public
	{
		require(_rebaseDampeningFactor > 0, "invalid dampening factor");
		_self.rebaseDampeningFactor = _rebaseDampeningFactor;
	}

	function setRebaseTreasuryMintPercent(Self storage _self, uint256 _rebaseTreasuryMintPercent) public
	{
		require(_rebaseTreasuryMintPercent <= MAXIMUM_REBASE_TREASURY_MINT_PERCENT, "invalid percent");
		_self.rebaseTreasuryMintPercent = _rebaseTreasuryMintPercent;
	}

	function setRebaseTimingParameters(Self storage _self, uint256 _rebaseMinimumInterval, uint256 _rebaseWindowOffset, uint256 _rebaseWindowLength) public
	{
		require(_rebaseMinimumInterval > 0, "invalid interval");
		require(_rebaseWindowOffset.add(_rebaseWindowLength) <= _rebaseMinimumInterval, "invalid window");
		_self.rebaseMinimumInterval = _rebaseMinimumInterval;
		_self.rebaseWindowOffset = _rebaseWindowOffset;
		_self.rebaseWindowLength = _rebaseWindowLength;
	}

	function rebaseAvailable(Self storage _self) public view returns (bool _available)
	{
		return _self._rebaseAvailable();
	}

	function rebase(Self storage _self, uint256 _exchangeRate, uint256 _totalSupply) public returns (uint256 _delta, bool _positive, uint256 _mintAmount)
	{
		require(_self._rebaseAvailable(), "not available");

		_self.lastRebaseTime = now.sub(now.mod(_self.rebaseMinimumInterval)).add(_self.rebaseWindowOffset);
		_self.epoch = _self.epoch.add(1);

		_positive = _exchangeRate > 1e18;

		uint256 _deviation = _positive ? _exchangeRate.sub(1e18) : uint256(1e18).sub(_exchangeRate);
		if (_deviation < _self.rebaseMinimumDeviation) {
			_deviation = 0;
			_positive = false;
		}

		_delta = _deviation.div(_self.rebaseDampeningFactor);

		_mintAmount = 0;
		if (_positive) {
			uint256 _mintPercent = _delta.mul(_self.rebaseTreasuryMintPercent).div(1e18);
			_delta = _delta.sub(_mintPercent);
			_mintAmount = _totalSupply.mul(_mintPercent).div(1e18);
		}

		return (_delta, _positive, _mintAmount);
	}

	function _rebaseAvailable(Self storage _self) internal view returns (bool _available)
	{
		if (!_self.rebaseActive) return false;
		if (now < _self.lastRebaseTime.add(_self.rebaseMinimumInterval)) return false;
		uint256 _offset = now.mod(_self.rebaseMinimumInterval);
		return _self.rebaseWindowOffset <= _offset && _offset < _self.rebaseWindowOffset.add(_self.rebaseWindowLength);
	}
}

// File: @uniswap/lib/contracts/libraries/FullMath.sol

pragma solidity >=0.4.0;

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
    function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);

        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;

        if (h == 0) return l / d;

        require(h < d, 'FullMath: FULLDIV_OVERFLOW');
        return fullDiv(l, h, d);
    }
}

// File: @uniswap/lib/contracts/libraries/Babylonian.sol


pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// File: @uniswap/lib/contracts/libraries/BitMath.sol

pragma solidity >=0.5.0;

library BitMath {
    // returns the 0 indexed position of the most significant bit of the input x
    // s.t. x >= 2**msb and x < 2**(msb+1)
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::mostSignificantBit: zero');

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    // returns the 0 indexed position of the least significant bit of the input x
    // s.t. (x & 2**lsb) != 0 and (x & (2**(lsb) - 1)) == 0)
    // i.e. the bit at the index is set and the mask of all lower bits is 0
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::leastSignificantBit: zero');

        r = 255;
        if (x & uint128(-1) > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & uint64(-1) > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & uint32(-1) > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & uint16(-1) > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & uint8(-1) > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
    }
}

// File: @uniswap/lib/contracts/libraries/FixedPoint.sol

pragma solidity >=0.4.0;




// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 public constant RESOLUTION = 112;
    uint256 public constant Q112 = 0x10000000000000000000000000000; // 2**112
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000; // 2**224
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, 'FixedPoint::mul: overflow');
        return uq144x112(z);
    }

    // multiply a UQ112x112 by an int and decode, returning an int
    // reverts on overflow
    function muli(uq112x112 memory self, int256 y) internal pure returns (int256) {
        uint256 z = FullMath.mulDiv(self._x, uint256(y < 0 ? -y : y), Q112);
        require(z < 2**255, 'FixedPoint::muli: overflow');
        return y < 0 ? -int256(z) : int256(z);
    }

    // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
    // lossy
    function muluq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        if (self._x == 0 || other._x == 0) {
            return uq112x112(0);
        }
        uint112 upper_self = uint112(self._x >> RESOLUTION); // * 2^0
        uint112 lower_self = uint112(self._x & LOWER_MASK); // * 2^-112
        uint112 upper_other = uint112(other._x >> RESOLUTION); // * 2^0
        uint112 lower_other = uint112(other._x & LOWER_MASK); // * 2^-112

        // partial products
        uint224 upper = uint224(upper_self) * upper_other; // * 2^0
        uint224 lower = uint224(lower_self) * lower_other; // * 2^-224
        uint224 uppers_lowero = uint224(upper_self) * lower_other; // * 2^-112
        uint224 uppero_lowers = uint224(upper_other) * lower_self; // * 2^-112

        // so the bit shift does not overflow
        require(upper <= uint112(-1), 'FixedPoint::muluq: upper overflow');

        // this cannot exceed 256 bits, all values are 224 bits
        uint256 sum = uint256(upper << RESOLUTION) + uppers_lowero + uppero_lowers + (lower >> RESOLUTION);

        // so the cast does not overflow
        require(sum <= uint224(-1), 'FixedPoint::muluq: sum overflow');

        return uq112x112(uint224(sum));
    }

    // divide a UQ112x112 by a UQ112x112, returning a UQ112x112
    function divuq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        require(other._x > 0, 'FixedPoint::divuq: division by zero');
        if (self._x == other._x) {
            return uq112x112(uint224(Q112));
        }
        if (self._x <= uint144(-1)) {
            uint256 value = (uint256(self._x) << RESOLUTION) / other._x;
            require(value <= uint224(-1), 'FixedPoint::divuq: overflow');
            return uq112x112(uint224(value));
        }

        uint256 result = FullMath.mulDiv(Q112, self._x, other._x);
        require(result <= uint224(-1), 'FixedPoint::divuq: overflow');
        return uq112x112(uint224(result));
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // can be lossy
    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }

    // take the reciprocal of a UQ112x112
    // reverts on overflow
    // lossy
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint::reciprocal: reciprocal of zero');
        require(self._x != 1, 'FixedPoint::reciprocal: overflow');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        if (self._x <= uint144(-1)) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2)));
    }
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

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

// File: @uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol

pragma solidity >=0.5.0;



// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

// File: contracts/interop/UniswapV2.sol

pragma solidity ^0.6.0;


/**
 * @dev Minimal set of declarations for Uniswap V2 interoperability.
 */
interface Factory
{
	function getPair(address _tokenA, address _tokenB) external view returns (address _pair);
	function createPair(address _tokenA, address _tokenB) external returns (address _pair);
}

interface PoolToken is IERC20
{
}

interface Pair is PoolToken
{
	function token0() external view returns (address _token0);
	function token1() external view returns (address _token1);
	function price0CumulativeLast() external view returns (uint256 _price0CumulativeLast);
	function price1CumulativeLast() external view returns (uint256 _price1CumulativeLast);
	function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
	function mint(address _to) external returns (uint256 _liquidity);
	function sync() external;
}

interface Router01
{
	function WETH() external pure returns (address _token);
	function addLiquidity(address _tokenA, address _tokenB, uint256 _amountADesired, uint256 _amountBDesired, uint256 _amountAMin, uint256 _amountBMin, address _to, uint256 _deadline) external returns (uint256 _amountA, uint256 _amountB, uint256 _liquidity);
	function removeLiquidity(address _tokenA, address _tokenB, uint256 _liquidity, uint256 _amountAMin, uint256 _amountBMin, address _to, uint256 _deadline) external returns (uint256 _amountA, uint256 _amountB);
	function swapExactTokensForTokens(uint256 _amountIn, uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external returns (uint256[] memory _amounts);
	function swapETHForExactTokens(uint256 _amountOut, address[] calldata _path, address _to, uint256 _deadline) external payable returns (uint256[] memory _amounts);
	function getAmountOut(uint256 _amountIn, uint256 _reserveIn, uint256 _reserveOut) external pure returns (uint256 _amountOut);
}

interface Router02 is Router01
{
}

// File: contracts/GPriceOracle.sol

pragma solidity ^0.6.0;




/**
 * @dev This library implements a TWAP oracle on Uniswap V2. Based on
 * https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/examples/ExampleOracleSimple.sol
 */
library GPriceOracle
{
	using FixedPoint for FixedPoint.uq112x112;
	using FixedPoint for FixedPoint.uq144x112;
	using GPriceOracle for GPriceOracle.Self;

	uint256 constant DEFAULT_MINIMUM_INTERVAL = 23 hours;

	struct Self {
		address pair;
		bool use0;

		uint256 minimumInterval;

		uint256 priceCumulativeLast;
		uint32 blockTimestampLast;
		FixedPoint.uq112x112 priceAverage;
	}

	function init(Self storage _self) public
	{
		_self.pair = address(0);

		_self.minimumInterval = DEFAULT_MINIMUM_INTERVAL;
	}

	function active(Self storage _self) public view returns (bool _isActive)
	{
		return _self._active();
	}

	function activate(Self storage _self, address _pair, bool _use0) public
	{
		require(!_self._active(), "already active");
		require(_pair != address(0), "invalid pair");

		_self.pair = _pair;
		_self.use0 = _use0;

		_self.priceCumulativeLast = _use0 ? Pair(_pair).price0CumulativeLast() : Pair(_pair).price1CumulativeLast();

		uint112 reserve0;
		uint112 reserve1;
		(reserve0, reserve1, _self.blockTimestampLast) = Pair(_pair).getReserves();
		require(reserve0 > 0 && reserve1 > 0, "no reserves"); // ensure that there's liquidity in the pair
	}

	function changeMinimumInterval(Self storage _self, uint256 _minimumInterval) public
	{
		require(_minimumInterval > 0, "invalid interval");
		_self.minimumInterval = _minimumInterval;
	}

	function consultLastPrice(Self storage _self, uint256 _amountIn) public view returns (uint256 _amountOut)
	{
		require(_self._active(), "not active");

		return _self.priceAverage.mul(_amountIn).decode144();
	}

	function consultCurrentPrice(Self storage _self, uint256 _amountIn) public view returns (uint256 _amountOut)
	{
		require(_self._active(), "not active");

		(,, FixedPoint.uq112x112 memory _priceAverage) = _self._estimatePrice(false);
		return _priceAverage.mul(_amountIn).decode144();
	}

	function updatePrice(Self storage _self) public
	{
		require(_self._active(), "not active");

		(_self.priceCumulativeLast, _self.blockTimestampLast, _self.priceAverage) = _self._estimatePrice(true);
	}

	function _active(Self storage _self) internal view returns (bool _isActive)
	{
		return _self.pair != address(0);
	}

	function _estimatePrice(Self storage _self, bool _enforceTimeElapsed) internal view returns (uint256 _priceCumulative, uint32 _blockTimestamp, FixedPoint.uq112x112 memory _priceAverage)
	{
		uint256 _price0Cumulative;
		uint256 _price1Cumulative;
		(_price0Cumulative, _price1Cumulative, _blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrices(_self.pair);
		_priceCumulative = _self.use0 ? _price0Cumulative : _price1Cumulative;

		uint32 _timeElapsed = _blockTimestamp - _self.blockTimestampLast; // overflow is desired

		// ensure that at least one full interval has passed since the last update
		if (_enforceTimeElapsed) {
			require(_timeElapsed >= _self.minimumInterval, "minimum interval not elapsed");
		}

		// overflow is desired, casting never truncates
		// cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
		_priceAverage = FixedPoint.uq112x112(uint224((_priceCumulative - _self.priceCumulativeLast) / _timeElapsed));
	}
}

// File: contracts/modules/Math.sol

pragma solidity ^0.6.0;

/**
 * @dev This library implements auxiliary math definitions.
 */
library Math
{
	function _min(uint256 _amount1, uint256 _amount2) internal pure returns (uint256 _minAmount)
	{
		return _amount1 < _amount2 ? _amount1 : _amount2;
	}

	function _max(uint256 _amount1, uint256 _amount2) internal pure returns (uint256 _maxAmount)
	{
		return _amount1 > _amount2 ? _amount1 : _amount2;
	}
}

// File: contracts/GElasticToken.sol

pragma solidity ^0.6.0;











/**
 * @notice This contract implements an ERC20 compatible elastic token that
 * rebases according to the TWAP of another token. Inspired by AMPL and YAM.
 */
contract GElasticToken is ElasticERC20, Ownable, ReentrancyGuard, GElastic
{
	using SafeMath for uint256;
	using GElasticTokenManager for GElasticTokenManager.Self;
	using GPriceOracle for GPriceOracle.Self;
	using Executor for Executor.Target[];

	address public immutable override referenceToken;

	GElasticTokenManager.Self etm;
	GPriceOracle.Self oracle;

	Executor.Target[] public targets;

	modifier onlyEOA()
	{
		require(tx.origin == _msgSender(), "not an externally owned account");
		_;
	}

	constructor (string memory _name, string memory _symbol, uint8 _decimals, address _referenceToken, uint256 _initialSupply)
		ElasticERC20(_name, _symbol) public
	{
		address _treasury = msg.sender;
		_setupDecimals(_decimals);
		assert(_referenceToken != address(0));
		referenceToken = _referenceToken;
		etm.init(_treasury);
		oracle.init();
		_mint(_treasury, _initialSupply);
	}

	function treasury() external view override returns (address _treasury)
	{
		return etm.treasury;
	}

	function rebaseMinimumDeviation() external view override returns (uint256 _rebaseMinimumDeviation)
	{
		return etm.rebaseMinimumDeviation;
	}

	function rebaseDampeningFactor() external view override returns (uint256 _rebaseDampeningFactor)
	{
		return etm.rebaseDampeningFactor;
	}

	function rebaseTreasuryMintPercent() external view override returns (uint256 _rebaseTreasuryMintPercent)
	{
		return etm.rebaseTreasuryMintPercent;
	}

	function rebaseTimingParameters() external view override returns (uint256 _rebaseMinimumInterval, uint256 _rebaseWindowOffset, uint256 _rebaseWindowLength)
	{
		return (etm.rebaseMinimumInterval, etm.rebaseWindowOffset, etm.rebaseWindowLength);
	}

	function rebaseAvailable() external view override returns (bool _rebaseAvailable)
	{
		return etm.rebaseAvailable();
	}

	function rebaseActive() external view override returns (bool _rebaseActive)
	{
		return etm.rebaseActive;
	}

	function lastRebaseTime() external view override returns (uint256 _lastRebaseTime)
	{
		return etm.lastRebaseTime;
	}

	function epoch() external view override returns (uint256 _epoch)
	{
		return etm.epoch;
	}

	function lastExchangeRate() external view override returns (uint256 _exchangeRate)
	{
		return oracle.consultLastPrice(10 ** uint256(decimals()));
	}

	function currentExchangeRate() external view override returns (uint256 _exchangeRate)
	{
		return oracle.consultCurrentPrice(10 ** uint256(decimals()));
	}

	function pair() external view override returns (address _pair)
	{
		return oracle.pair;
	}

	function rebase() external override onlyEOA nonReentrant
	{
		oracle.updatePrice();

		uint256 _exchangeRate = oracle.consultLastPrice(10 ** uint256(decimals()));

		uint256 _totalSupply = totalSupply();

		(uint256 _delta, bool _positive, uint256 _mintAmount) = etm.rebase(_exchangeRate, _totalSupply);

		_rebase(etm.epoch, _delta, _positive);

		if (_mintAmount > 0) {
			_mint(etm.treasury, _mintAmount);
		}

		// updates cached reserve balances wherever necessary
		Pair(oracle.pair).sync();
		targets.executeAll();
	}

	function activateOracle(address _pair) external override onlyOwner nonReentrant
	{
		address _token0 = Pair(_pair).token0();
		address _token1 = Pair(_pair).token1();
		require(_token0 == address(this) && _token1 == referenceToken || _token1 == address(this) && _token0 == referenceToken, "invalid pair");
		oracle.activate(_pair, _token0 == address(this));
	}

	function activateRebase() external override onlyOwner nonReentrant
	{
		require(oracle.active(), "not available");
		etm.activateRebase();
	}

	function setTreasury(address _newTreasury) external override onlyOwner nonReentrant
	{
		address _oldTreasury = etm.treasury;
		etm.setTreasury(_newTreasury);
		emit ChangeTreasury(_oldTreasury, _newTreasury);
	}

	function setRebaseMinimumDeviation(uint256 _newRebaseMinimumDeviation) external override onlyOwner nonReentrant
	{
		uint256 _oldRebaseMinimumDeviation = etm.rebaseMinimumDeviation;
		etm.setRebaseMinimumDeviation(_newRebaseMinimumDeviation);
		emit ChangeRebaseMinimumDeviation(_oldRebaseMinimumDeviation, _newRebaseMinimumDeviation);
	}

	function setRebaseDampeningFactor(uint256 _newRebaseDampeningFactor) external override onlyOwner nonReentrant
	{
		uint256 _oldRebaseDampeningFactor = etm.rebaseDampeningFactor;
		etm.setRebaseDampeningFactor(_newRebaseDampeningFactor);
		emit ChangeRebaseDampeningFactor(_oldRebaseDampeningFactor, _newRebaseDampeningFactor);
	}

	function setRebaseTreasuryMintPercent(uint256 _newRebaseTreasuryMintPercent) external override onlyOwner nonReentrant
	{
		uint256 _oldRebaseTreasuryMintPercent = etm.rebaseTreasuryMintPercent;
		etm.setRebaseTreasuryMintPercent(_newRebaseTreasuryMintPercent);
		emit ChangeRebaseTreasuryMintPercent(_oldRebaseTreasuryMintPercent, _newRebaseTreasuryMintPercent);
	}

	function setRebaseTimingParameters(uint256 _newRebaseMinimumInterval, uint256 _newRebaseWindowOffset, uint256 _newRebaseWindowLength) external override onlyOwner nonReentrant
	{
		uint256 _oldRebaseMinimumInterval = etm.rebaseMinimumInterval;
		uint256 _oldRebaseWindowOffset = etm.rebaseWindowOffset;
		uint256 _oldRebaseWindowLength = etm.rebaseWindowLength;
		etm.setRebaseTimingParameters(_newRebaseMinimumInterval, _newRebaseWindowOffset, _newRebaseWindowLength);
		oracle.changeMinimumInterval(_newRebaseMinimumInterval.sub(_newRebaseWindowLength));
		emit ChangeRebaseTimingParameters(_oldRebaseMinimumInterval, _oldRebaseWindowOffset, _oldRebaseWindowLength, _newRebaseMinimumInterval, _newRebaseWindowOffset, _newRebaseWindowLength);
	}

	function addPostRebaseTarget(address _to, bytes memory _data) external override onlyOwner nonReentrant
	{
		_addPostRebaseTarget(_to, _data);
	}

	function removePostRebaseTarget(uint256 _index) external override onlyOwner nonReentrant
	{
		_removePostRebaseTarget(_index);
	}

	function addBalancerPostRebaseTarget(address _pool) external onlyOwner nonReentrant
	{
		_addPostRebaseTarget(_pool, abi.encodeWithSignature("gulp(address)", address(this)));
	}

	function addUniswapV2PostRebaseTarget(address _pair) external onlyOwner nonReentrant
	{
		_addPostRebaseTarget(_pair, abi.encodeWithSignature("sync()"));
	}

	function _addPostRebaseTarget(address _to, bytes memory _data) internal
	{
		targets.addTarget(_to, _data);
		emit AddPostRebaseTarget(_to, _data);
	}

	function _removePostRebaseTarget(uint256 _index) internal
	{
		Executor.Target storage _target = targets[_index];
		address _to = _target.to;
		bytes memory _data = _target.data;
		targets.removeTarget(_index);
		emit RemovePostRebaseTarget(_to, _data);
	}

	function _rebase(uint256 _epoch, uint256 _delta, bool _positive) internal virtual
	{
		uint256 _oldScalingFactor = scalingFactor();
		uint256 _newScalingFactor;
		if (_delta == 0) {
			_newScalingFactor = _oldScalingFactor;
		} else {
			if (_positive) {
				_newScalingFactor = _oldScalingFactor.mul(uint256(1e18).add(_delta)).div(1e18);
			} else {
				_newScalingFactor = _oldScalingFactor.mul(uint256(1e18).sub(_delta)).div(1e18);
			}
		}
		if (_newScalingFactor > _oldScalingFactor) {
			_newScalingFactor = Math._min(_newScalingFactor, maxScalingFactor());
		}
		_setScalingFactor(_newScalingFactor);
		emit Rebase(_epoch, _oldScalingFactor, _newScalingFactor);
	}
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


pragma solidity >=0.6.0 <0.8.0;




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

// File: contracts/GLPMining.sol

pragma solidity ^0.6.0;

/**
 * @dev This interface exposes the base functionality of GLPMiningToken.
 */
interface GLPMining
{
	// view functions
	function reserveToken() external view returns (address _reserveToken);
	function rewardsToken() external view returns (address _rewardsToken);
	function treasury() external view returns (address _treasury);
	function performanceFee() external view returns (uint256 _performanceFee);
	function rewardRatePerWeek() external view returns (uint256 _rewardRatePerWeek);
	function calcSharesFromCost(uint256 _cost) external view returns (uint256 _shares);
	function calcCostFromShares(uint256 _shares) external view returns (uint256 _cost);
	function calcSharesFromTokenAmount(address _token, uint256 _amount) external view returns (uint256 _shares);
	function calcTokenAmountFromShares(address _token, uint256 _shares) external view returns (uint256 _amount);
	function totalReserve() external view returns (uint256 _totalReserve);
	function rewardInfo() external view returns (uint256 _lockedReward, uint256 _unlockedReward, uint256 _rewardPerBlock);
	function pendingFees() external view returns (uint256 _feeShares);

	// open functions
	function deposit(uint256 _cost) external;
	function withdraw(uint256 _shares) external;
	function depositToken(address _token, uint256 _amount, uint256 _minShares) external;
	function withdrawToken(address _token, uint256 _shares, uint256 _minAmount) external;
	function gulpRewards(uint256 _minCost) external;
	function gulpFees() external;

	// priviledged functions
	function setTreasury(address _treasury) external;
	function setPerformanceFee(uint256 _performanceFee) external;
	function setRewardRatePerWeek(uint256 _rewardRatePerWeek) external;

	// emitted events
	event ChangeTreasury(address _oldTreasury, address _newTreasury);
	event ChangePerformanceFee(uint256 _oldPerformanceFee, uint256 _newPerformanceFee);
	event ChangeRewardRatePerWeek(uint256 _oldRewardRatePerWeek, uint256 _newRewardRatePerWeek);
}

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


pragma solidity >=0.6.0 <0.8.0;




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

// File: contracts/modules/Transfers.sol

pragma solidity ^0.6.0;



/**
 * @dev This library abstracts ERC-20 operations in the context of the current
 * contract.
 */
library Transfers
{
	using SafeERC20 for IERC20;

	/**
	 * @dev Retrieves a given ERC-20 token balance for the current contract.
	 * @param _token An ERC-20 compatible token address.
	 * @return _balance The current contract balance of the given ERC-20 token.
	 */
	function _getBalance(address _token) internal view returns (uint256 _balance)
	{
		return IERC20(_token).balanceOf(address(this));
	}

	/**
	 * @dev Allows a spender to access a given ERC-20 balance for the current contract.
	 * @param _token An ERC-20 compatible token address.
	 * @param _to The spender address.
	 * @param _amount The exact spending allowance amount.
	 */
	function _approveFunds(address _token, address _to, uint256 _amount) internal
	{
		uint256 _allowance = IERC20(_token).allowance(address(this), _to);
		if (_allowance > _amount) {
			IERC20(_token).safeDecreaseAllowance(_to, _allowance - _amount);
		}
		else
		if (_allowance < _amount) {
			IERC20(_token).safeIncreaseAllowance(_to, _amount - _allowance);
		}
	}

	/**
	 * @dev Transfer a given ERC-20 token amount into the current contract.
	 * @param _token An ERC-20 compatible token address.
	 * @param _from The source address.
	 * @param _amount The amount to be transferred.
	 */
	function _pullFunds(address _token, address _from, uint256 _amount) internal
	{
		if (_amount == 0) return;
		IERC20(_token).safeTransferFrom(_from, address(this), _amount);
	}

	/**
	 * @dev Transfer a given ERC-20 token amount from the current contract.
	 * @param _token An ERC-20 compatible token address.
	 * @param _to The target address.
	 * @param _amount The amount to be transferred.
	 */
	function _pushFunds(address _token, address _to, uint256 _amount) internal
	{
		if (_amount == 0) return;
		IERC20(_token).safeTransfer(_to, _amount);
	}
}

// File: contracts/network/$.sol

pragma solidity ^0.6.0;

/**
 * @dev This library is provided for convenience. It is the single source for
 *      the current network and all related hardcoded contract addresses.
 */
library $
{
	address constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

	address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

	address constant UniswapV2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

	address constant UniswapV2_ROUTER02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
}

// File: contracts/modules/UniswapV2LiquidityPoolAbstraction.sol

pragma solidity ^0.6.0;







/**
 * @dev This library provides functionality to facilitate adding/removing
 * single-asset liquidity to/from a Uniswap V2 pool.
 */
library UniswapV2LiquidityPoolAbstraction
{
	using SafeMath for uint256;

	function _estimateJoinPool(address _pair, address _token, uint256 _amount) internal view returns (uint256 _shares)
	{
		if (_amount == 0) return 0;
		address _router = $.UniswapV2_ROUTER02;
		address _token0 = Pair(_pair).token0();
		(uint256 _reserve0, uint256 _reserve1,) = Pair(_pair).getReserves();
		uint256 _balance = _token == _token0 ? _reserve0 : _reserve1;
		uint256 _otherBalance = _token == _token0 ? _reserve1 : _reserve0;
		uint256 _totalSupply = Pair(_pair).totalSupply();
		uint256 _swapAmount = _calcSwapOutputFromInput(_balance, _amount);
		if (_swapAmount == 0) _swapAmount = _amount / 2;
		uint256 _leftAmount = _amount.sub(_swapAmount);
		uint256 _otherAmount = Router02(_router).getAmountOut(_swapAmount, _balance, _otherBalance);
		_shares = Math._min(_totalSupply.mul(_leftAmount) / _balance.add(_swapAmount), _totalSupply.mul(_otherAmount) / _otherBalance.sub(_otherAmount));
		return _shares;
	}

	function _estimateExitPool(address _pair, address _token, uint256 _shares) internal view returns (uint256 _amount)
	{
		if (_shares == 0) return 0;
		address _router = $.UniswapV2_ROUTER02;
		address _token0 = Pair(_pair).token0();
		(uint256 _reserve0, uint256 _reserve1,) = Pair(_pair).getReserves();
		uint256 _balance = _token == _token0 ? _reserve0 : _reserve1;
		uint256 _otherBalance = _token == _token0 ? _reserve1 : _reserve0;
		uint256 _totalSupply = Pair(_pair).totalSupply();
		uint256 _baseAmount = _balance.mul(_shares) / _totalSupply;
		uint256 _swapAmount = _otherBalance.mul(_shares) / _totalSupply;
		uint256 _additionalAmount = Router02(_router).getAmountOut(_swapAmount, _otherBalance.sub(_swapAmount), _balance.sub(_baseAmount));
		_amount = _baseAmount.add(_additionalAmount);
		return _amount;
	}

	function _joinPool(address _pair, address _token, uint256 _amount, uint256 _minShares) internal returns (uint256 _shares)
	{
		if (_amount == 0) return 0;
		address _router = $.UniswapV2_ROUTER02;
		address _token0 = Pair(_pair).token0();
		address _token1 = Pair(_pair).token1();
		address _otherToken = _token == _token0 ? _token1 : _token0;
		(uint256 _reserve0, uint256 _reserve1,) = Pair(_pair).getReserves();
		uint256 _swapAmount = _calcSwapOutputFromInput(_token == _token0 ? _reserve0 : _reserve1, _amount);
		if (_swapAmount == 0) _swapAmount = _amount / 2;
		uint256 _leftAmount = _amount.sub(_swapAmount);
		Transfers._approveFunds(_token, _router, _amount);
		address[] memory _path = new address[](2);
		_path[0] = _token;
		_path[1] = _otherToken;
		uint256 _otherAmount = Router02(_router).swapExactTokensForTokens(_swapAmount, 1, _path, address(this), uint256(-1))[1];
		Transfers._approveFunds(_otherToken, _router, _otherAmount);
		(,,_shares) = Router02(_router).addLiquidity(_token, _otherToken, _leftAmount, _otherAmount, 1, 1, address(this), uint256(-1));
		require(_shares >= _minShares, "high slippage");
		return _shares;
	}

	function _exitPool(address _pair, address _token, uint256 _shares, uint256 _minAmount) internal returns (uint256 _amount)
	{
		if (_shares == 0) return 0;
		address _router = $.UniswapV2_ROUTER02;
		address _token0 = Pair(_pair).token0();
		address _token1 = Pair(_pair).token1();
		address _otherToken = _token == _token0 ? _token1 : _token0;
		Transfers._approveFunds(_pair, _router, _shares);
		(uint256 _baseAmount, uint256 _swapAmount) = Router02(_router).removeLiquidity(_token, _otherToken, _shares, 1, 1, address(this), uint256(-1));
		Transfers._approveFunds(_otherToken, _router, _swapAmount);
		address[] memory _path = new address[](2);
		_path[0] = _otherToken;
		_path[1] = _token;
		uint256 _additionalAmount = Router02(_router).swapExactTokensForTokens(_swapAmount, 1, _path, address(this), uint256(-1))[1];
		_amount = _baseAmount.add(_additionalAmount);
	        require(_amount >= _minAmount, "high slippage");
		return _amount;
	}

	function _calcSwapOutputFromInput(uint256 _reserveAmount, uint256 _inputAmount) private pure returns (uint256)
	{
		return Babylonian.sqrt(_reserveAmount.mul(_inputAmount.mul(3988000).add(_reserveAmount.mul(3988009)))).sub(_reserveAmount.mul(1997)) / 1994;
	}
}

// File: contracts/GLPMiningToken.sol

pragma solidity ^0.6.0;







/**
 * @notice This contract implements liquidity mining for staking Uniswap V2
 * shares.
 */
contract GLPMiningToken is ERC20, Ownable, ReentrancyGuard, GLPMining
{
	uint256 constant MAXIMUM_PERFORMANCE_FEE = 50e16; // 50%

	uint256 constant BLOCKS_PER_WEEK = 7 days / uint256(13 seconds);
	uint256 constant DEFAULT_PERFORMANCE_FEE = 10e16; // 10%
	uint256 constant DEFAULT_REWARD_RATE_PER_WEEK = 10e16; // 10%

	address public immutable override reserveToken;
	address public immutable override rewardsToken;

	address public override treasury;

	uint256 public override performanceFee = DEFAULT_PERFORMANCE_FEE;
	uint256 public override rewardRatePerWeek = DEFAULT_REWARD_RATE_PER_WEEK;

	uint256 lastContractBlock = block.number;
	uint256 lastRewardPerBlock = 0;
	uint256 lastUnlockedReward = 0;
	uint256 lastLockedReward = 0;

	uint256 lastTotalSupply = 1;
	uint256 lastTotalReserve = 1;

	constructor (string memory _name, string memory _symbol, uint8 _decimals, address _reserveToken, address _rewardsToken)
		ERC20(_name, _symbol) public
	{
		address _treasury = msg.sender;
		_setupDecimals(_decimals);
		assert(_reserveToken != address(0));
		assert(_rewardsToken != address(0));
		assert(_reserveToken != _rewardsToken);
		reserveToken = _reserveToken;
		rewardsToken = _rewardsToken;
		treasury = _treasury;
		// just after creation it must transfer 1 wei from reserveToken
		// into this contract
		// this must be performed manually because we cannot approve
		// the spending by this contract before it exists
		// Transfers._pullFunds(_reserveToken, _from, 1);
		_mint(address(this), 1);
	}

	function calcSharesFromCost(uint256 _cost) public view override returns (uint256 _shares)
	{
		return _cost.mul(totalSupply()).div(totalReserve());
	}

	function calcCostFromShares(uint256 _shares) public view override returns (uint256 _cost)
	{
		return _shares.mul(totalReserve()).div(totalSupply());
	}

	function calcSharesFromTokenAmount(address _token, uint256 _amount) external view override returns (uint256 _shares)
	{
		uint256 _cost = UniswapV2LiquidityPoolAbstraction._estimateJoinPool(reserveToken, _token, _amount);
		return calcSharesFromCost(_cost);
	}

	function calcTokenAmountFromShares(address _token, uint256 _shares) external view override returns (uint256 _amount)
	{
		uint256 _cost = calcCostFromShares(_shares);
		return UniswapV2LiquidityPoolAbstraction._estimateExitPool(reserveToken, _token, _cost);
	}

	function totalReserve() public view override returns (uint256 _totalReserve)
	{
		return Transfers._getBalance(reserveToken);
	}

	function rewardInfo() external view override returns (uint256 _lockedReward, uint256 _unlockedReward, uint256 _rewardPerBlock)
	{
		(, _rewardPerBlock, _unlockedReward, _lockedReward) = _calcCurrentRewards();
		return (_lockedReward, _unlockedReward, _rewardPerBlock);
	}

	function pendingFees() external view override returns (uint256 _feeShares)
	{
		return _calcFees();
	}

	function deposit(uint256 _cost) external override nonReentrant
	{
		address _from = msg.sender;
		uint256 _shares = calcSharesFromCost(_cost);
		Transfers._pullFunds(reserveToken, _from, _cost);
		_mint(_from, _shares);
	}

	function withdraw(uint256 _shares) external override nonReentrant
	{
		address _from = msg.sender;
		uint256 _cost = calcCostFromShares(_shares);
		Transfers._pushFunds(reserveToken, _from, _cost);
		_burn(_from, _shares);
	}

	function depositToken(address _token, uint256 _amount, uint256 _minShares) external override nonReentrant
	{
		address _from = msg.sender;
		uint256 _minCost = calcCostFromShares(_minShares);
		Transfers._pullFunds(_token, _from, _amount);
		uint256 _cost = UniswapV2LiquidityPoolAbstraction._joinPool(reserveToken, _token, _amount, _minCost);
		uint256 _shares = _cost.mul(totalSupply()).div(totalReserve().sub(_cost));
		_mint(_from, _shares);
	}

	function withdrawToken(address _token, uint256 _shares, uint256 _minAmount) external override nonReentrant
	{
		address _from = msg.sender;
		uint256 _cost = calcCostFromShares(_shares);
		uint256 _amount = UniswapV2LiquidityPoolAbstraction._exitPool(reserveToken, _token, _cost, _minAmount);
		Transfers._pushFunds(_token, _from, _amount);
		_burn(_from, _shares);
	}

	function gulpRewards(uint256 _minCost) external override nonReentrant
	{
		_updateRewards();
		UniswapV2LiquidityPoolAbstraction._joinPool(reserveToken, rewardsToken, lastUnlockedReward, _minCost);
		lastUnlockedReward = 0;
	}

	function gulpFees() external override nonReentrant
	{
		uint256 _feeShares = _calcFees();
		if (_feeShares > 0) {
			lastTotalSupply = totalSupply();
			lastTotalReserve = totalReserve();
			_mint(treasury, _feeShares);
		}
	}

	function setTreasury(address _newTreasury) external override onlyOwner nonReentrant
	{
		require(_newTreasury != address(0), "invalid address");
		address _oldTreasury = treasury;
		treasury = _newTreasury;
		emit ChangeTreasury(_oldTreasury, _newTreasury);
	}

	function setPerformanceFee(uint256 _newPerformanceFee) external override onlyOwner nonReentrant
	{
		require(_newPerformanceFee <= MAXIMUM_PERFORMANCE_FEE, "invalid rate");
		uint256 _oldPerformanceFee = performanceFee;
		performanceFee = _newPerformanceFee;
		emit ChangePerformanceFee(_oldPerformanceFee, _newPerformanceFee);
	}

	function setRewardRatePerWeek(uint256 _newRewardRatePerWeek) external override onlyOwner nonReentrant
	{
		require(_newRewardRatePerWeek <= 1e18, "invalid rate");
		uint256 _oldRewardRatePerWeek = rewardRatePerWeek;
		rewardRatePerWeek = _newRewardRatePerWeek;
		emit ChangeRewardRatePerWeek(_oldRewardRatePerWeek, _newRewardRatePerWeek);
	}

	function _updateRewards() internal
	{
		(lastContractBlock, lastRewardPerBlock, lastUnlockedReward, lastLockedReward) = _calcCurrentRewards();
		uint256 _balanceReward = Transfers._getBalance(rewardsToken);
		uint256 _totalReward = lastLockedReward.add(lastUnlockedReward);
		if (_balanceReward > _totalReward) {
			uint256 _newLockedReward = _balanceReward.sub(_totalReward);
			uint256 _newRewardPerBlock = _calcRewardPerBlock(_newLockedReward);
			lastRewardPerBlock = lastRewardPerBlock.add(_newRewardPerBlock);
			lastLockedReward = lastLockedReward.add(_newLockedReward);
		}
		else
		if (_balanceReward < _totalReward) {
			uint256 _removedLockedReward = _totalReward.sub(_balanceReward);
			if (_removedLockedReward >= lastLockedReward) {
				_removedLockedReward = lastLockedReward;
			}
			uint256 _removedRewardPerBlock = _calcRewardPerBlock(_removedLockedReward);
			if (_removedLockedReward >= lastLockedReward) {
				_removedRewardPerBlock = lastRewardPerBlock;
			}
			lastRewardPerBlock = lastRewardPerBlock.sub(_removedRewardPerBlock);
			lastLockedReward = lastLockedReward.sub(_removedLockedReward);
			lastUnlockedReward = _balanceReward.sub(lastLockedReward);
		}
	}

	function _calcFees() internal view returns (uint256 _feeShares)
	{
		uint256 _oldTotalSupply = lastTotalSupply;
		uint256 _oldTotalReserve = lastTotalReserve;

		uint256 _newTotalSupply = totalSupply();
		uint256 _newTotalReserve = totalReserve();

		// calculates the profit using the following formula
		// ((P1 - P0) * S1 * f) / P1
		// where P1 = R1 / S1 and P0 = R0 / S0
		uint256 _positive = _oldTotalSupply.mul(_newTotalReserve);
		uint256 _negative = _newTotalSupply.mul(_oldTotalReserve);
		if (_positive > _negative) {
			uint256 _profitCost = _positive.sub(_negative).div(_oldTotalSupply);
			uint256 _feeCost = _profitCost.mul(performanceFee).div(1e18);
			return calcSharesFromCost(_feeCost);
		}

		return 0;
	}

	function _calcCurrentRewards() internal view returns (uint256 _currentContractBlock, uint256 _currentRewardPerBlock, uint256 _currentUnlockedReward, uint256 _currentLockedReward)
	{
		uint256 _contractBlock = lastContractBlock;
		uint256 _rewardPerBlock = lastRewardPerBlock;
		uint256 _unlockedReward = lastUnlockedReward;
		uint256 _lockedReward = lastLockedReward;
		if (_contractBlock < block.number) {
			uint256 _week = _contractBlock.div(BLOCKS_PER_WEEK);
			uint256 _offset = _contractBlock.mod(BLOCKS_PER_WEEK);

			_contractBlock = block.number;
			uint256 _currentWeek = _contractBlock.div(BLOCKS_PER_WEEK);
			uint256 _currentOffset = _contractBlock.mod(BLOCKS_PER_WEEK);

			while (_week < _currentWeek) {
				uint256 _blocks = BLOCKS_PER_WEEK.sub(_offset);
				uint256 _reward = _blocks.mul(_rewardPerBlock);
				_unlockedReward = _unlockedReward.add(_reward);
				_lockedReward = _lockedReward.sub(_reward);
				_rewardPerBlock = _calcRewardPerBlock(_lockedReward);
				_week++;
				_offset = 0;
			}

			uint256 _blocks = _currentOffset.sub(_offset);
			uint256 _reward = _blocks.mul(_rewardPerBlock);
			_unlockedReward = _unlockedReward.add(_reward);
			_lockedReward = _lockedReward.sub(_reward);
		}
		return (_contractBlock, _rewardPerBlock, _unlockedReward, _lockedReward);
	}

	function _calcRewardPerBlock(uint256 _lockedReward) internal view returns (uint256 _rewardPerBlock)
	{
		return _lockedReward.mul(rewardRatePerWeek).div(1e18).div(BLOCKS_PER_WEEK);
	}
}

// File: contracts/interop/WrappedEther.sol

pragma solidity ^0.6.0;


/**
 * @dev Minimal set of declarations for WETH interoperability.
 */
interface WETH is IERC20
{
	function deposit() external payable;
	function withdraw(uint256 _amount) external;
}

// File: contracts/modules/Wrapping.sol

pragma solidity ^0.6.0;



/**
 * @dev This library abstracts Wrapped Ether operations.
 */
library Wrapping
{
	/**
	 * @dev Sends some ETH to the Wrapped Ether contract in exchange for WETH.
	 * @param _amount The amount of ETH to be wrapped.
	 */
	function _wrap(uint256 _amount) internal
	{
		WETH($.WETH).deposit{value: _amount}();
	}

	/**
	 * @dev Receives some ETH from the Wrapped Ether contract in exchange for WETH.
	 *      Note that the contract using this library function must declare a
	 *      payable receive/fallback function.
	 * @param _amount The amount of ETH to be unwrapped.
	 */
	function _unwrap(uint256 _amount) internal
	{
		WETH($.WETH).withdraw(_amount);
	}
}

// File: contracts/GEtherBridge.sol

pragma solidity ^0.6.0;




contract GEtherBridge
{
	function deposit(address _stakeToken, uint256 _minShares) external payable
	{
		address _from = msg.sender;
		uint256 _amount = msg.value;
		address _token = $.WETH;
		Wrapping._wrap(_amount);
		Transfers._approveFunds(_token, _stakeToken, _amount);
		GLPMining(_stakeToken).depositToken(_token, _amount, _minShares);
		uint256 _shares = Transfers._getBalance(_stakeToken);
		Transfers._pushFunds(_stakeToken, _from, _shares);
	}

	function withdraw(address _stakeToken, uint256 _shares, uint256 _minAmount) external
	{
		address payable _from = msg.sender;
		address _token = $.WETH;
		Transfers._pullFunds(_stakeToken, _from, _shares);
		GLPMining(_stakeToken).withdrawToken(_token, _shares, _minAmount);
		uint256 _amount = Transfers._getBalance(_token);
		Wrapping._unwrap(_amount);
		_from.transfer(_amount);
	}

	receive() external payable {} // not to be used directly
}

// File: contracts/GTokens.sol

pragma solidity ^0.6.0;






/**
 * @notice Definition of rAAVE. It is an elastic supply token that uses AAVE
 * as reference token.
 */
contract rAAVE is GElasticToken
{
	constructor (uint256 _initialSupply)
		GElasticToken("rebase AAVE", "rAAVE", 18, $.AAVE, _initialSupply) public
	{
	}
}

/**
 * @notice Definition of stkAAVE/rAAVE. It provides mining or reward rAAVE when
 * providing liquidity to the AAVE/rAAVE pool.
 */
contract stkAAVE_rAAVE is GLPMiningToken
{
	constructor (address _AAVE_rAAVE, address _rAAVE)
		GLPMiningToken("staked AAVE/rAAVE", "stkAAVE/rAAVE", 18, _AAVE_rAAVE, _rAAVE) public
	{
	}
}

/**
 * @notice Definition of stkGRO/rAAVE. It provides mining or reward rAAVE when
 * providing liquidity to the GRO/rAAVE pool.
 */
contract stkGRO_rAAVE is GLPMiningToken
{
	constructor (address _GRO_rAAVE, address _rAAVE)
		GLPMiningToken("staked GRO/rAAVE", "stkGRO/rAAVE", 18, _GRO_rAAVE, _rAAVE) public
	{
	}
}

/**
 * @notice Definition of stkETH/rAAVE. It provides mining or reward rAAVE when
 * providing liquidity to the WETH/rAAVE pool.
 */
contract stkETH_rAAVE is GLPMiningToken
{
	constructor (address _ETH_rAAVE, address _rAAVE)
		GLPMiningToken("staked ETH/rAAVE", "stkETH/rAAVE", 18, _ETH_rAAVE, _rAAVE) public
	{
	}
}

// File: contracts/GTokenRegistry.sol

pragma solidity ^0.6.0;


/**
 * @notice This contract allows external agents to detect when new GTokens
 *         are deployed to the network.
 */
contract GTokenRegistry is Ownable
{
	/**
	 * @notice Registers a new gToken.
	 * @param _growthToken The address of the token being registered.
	 * @param _oldGrowthToken The address of the token implementation
	 *                        being replaced, for upgrades, or 0x0 0therwise.
	 */
	function registerNewToken(address _growthToken, address _oldGrowthToken) public onlyOwner
	{
		emit NewToken(_growthToken, _oldGrowthToken);
	}

	event NewToken(address indexed _growthToken, address indexed _oldGrowthToken);
}