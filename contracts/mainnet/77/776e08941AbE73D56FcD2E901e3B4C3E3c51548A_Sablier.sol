pragma solidity =0.7.6;

import "../openzeppelin/utils/Pausable.sol";
import "../openzeppelin/access/Ownable.sol";
import "../openzeppelin/token/ERC20/IERC20.sol";
import "../openzeppelin/utils/ReentrancyGuard.sol";

import "./compound/Exponential.sol";
import "./interfaces/IERC1620.sol";
import "./Types.sol";

/**
 * @title Sablier's Money Streaming
 * @author Sablier
 */
contract Sablier is IERC1620, Exponential, ReentrancyGuard {
	/*** Storage Properties ***/

	/**
	 * @dev The amount of interest has been accrued per token address.
	 */
	mapping(address => uint256) private earnings;

	/**
	 * @notice The percentage fee charged by the contract on the accrued interest.
	 */
	Exp public fee;

	/**
	 * @notice Counter for new stream ids.
	 */
	uint256 public nextStreamId;

	/**
	 * @dev The stream objects identifiable by their unsigned integer ids.
	 */
	mapping(uint256 => Types.Stream) private streams;

	/*** Modifiers ***/

	/**
	 * @dev Throws if the caller is not the sender of the recipient of the stream.
	 */
	modifier onlySenderOrRecipient(uint256 streamId) {
		require(
			msg.sender == streams[streamId].sender ||
				msg.sender == streams[streamId].recipient,
			"caller is not the sender or the recipient of the stream"
		);
		_;
	}

	/**
	 * @dev Throws if the provided id does not point to a valid stream.
	 */
	modifier streamExists(uint256 streamId) {
		require(streams[streamId].isEntity, "stream does not exist");
		_;
	}

	/*** Contract Logic Starts Here */

	constructor() public {
		nextStreamId = 1;
	}

	/*** View Functions ***/
	function isEntity(uint256 streamId) external view returns (bool) {
		return streams[streamId].isEntity;
	}

	/**
	 * @dev Returns the compounding stream with all its properties.
	 * @dev Throws if the id does not point to a valid stream.
	 * @param streamId The id of the stream to query.
	 * @dev The stream object.
	 */
	function getStream(uint256 streamId)
		external
		view
		override
		streamExists(streamId)
		returns (
			address sender,
			address recipient,
			uint256 deposit,
			address tokenAddress,
			uint256 startTime,
			uint256 stopTime,
			uint256 remainingBalance,
			uint256 ratePerSecond
		)
	{
		sender = streams[streamId].sender;
		recipient = streams[streamId].recipient;
		deposit = streams[streamId].deposit;
		tokenAddress = streams[streamId].tokenAddress;
		startTime = streams[streamId].startTime;
		stopTime = streams[streamId].stopTime;
		remainingBalance = streams[streamId].remainingBalance;
		ratePerSecond = streams[streamId].ratePerSecond;
	}

	/**
	 * @dev Returns either the delta in seconds between `block.timestamp` and `startTime` or
	 *  between `stopTime` and `startTime, whichever is smaller. If `block.timestamp` is before
	 *  `startTime`, it returns 0.
	 * @dev Throws if the id does not point to a valid stream.
	 * @param streamId The id of the stream for which to query the delta.
	 * @dev The time delta in seconds.
	 */
	function deltaOf(uint256 streamId)
		public
		view
		streamExists(streamId)
		returns (uint256 delta)
	{
		Types.Stream memory stream = streams[streamId];
		if (block.timestamp <= stream.startTime) return 0;
		if (block.timestamp < stream.stopTime)
			return block.timestamp - stream.startTime;
		return stream.stopTime - stream.startTime;
	}

	struct BalanceOfLocalVars {
		MathError mathErr;
		uint256 recipientBalance;
		uint256 withdrawalAmount;
		uint256 senderBalance;
	}

	/**
	 * @dev Returns the available funds for the given stream id and address.
	 * @dev Throws if the id does not point to a valid stream.
	 * @param streamId The id of the stream for which to query the balance.
	 * @param who The address for which to query the balance.
	 * @dev @balance uint256 The total funds allocated to `who` as uint256.
	 */
	function balanceOf(uint256 streamId, address who)
		public
		view
		override
		streamExists(streamId)
		returns (uint256 balance)
	{
		Types.Stream memory stream = streams[streamId];
		BalanceOfLocalVars memory vars;

		uint256 delta = deltaOf(streamId);
		(vars.mathErr, vars.recipientBalance) = mulUInt(
			delta,
			stream.ratePerSecond
		);
		require(
			vars.mathErr == MathError.NO_ERROR,
			"recipient balance calculation error"
		);

		/*
		 * If the stream `balance` does not equal `deposit`, it means there have been withdrawals.
		 * We have to subtract the total amount withdrawn from the amount of money that has been
		 * streamed until now.
		 */
		if (stream.deposit > stream.remainingBalance) {
			(vars.mathErr, vars.withdrawalAmount) = subUInt(
				stream.deposit,
				stream.remainingBalance
			);
			assert(vars.mathErr == MathError.NO_ERROR);
			(vars.mathErr, vars.recipientBalance) = subUInt(
				vars.recipientBalance,
				vars.withdrawalAmount
			);
			/* `withdrawalAmount` cannot and should not be bigger than `recipientBalance`. */
			assert(vars.mathErr == MathError.NO_ERROR);
		}

		if (who == stream.recipient) return vars.recipientBalance;
		if (who == stream.sender) {
			(vars.mathErr, vars.senderBalance) = subUInt(
				stream.remainingBalance,
				vars.recipientBalance
			);
			/* `recipientBalance` cannot and should not be bigger than `remainingBalance`. */
			assert(vars.mathErr == MathError.NO_ERROR);
			return vars.senderBalance;
		}
		return 0;
	}

	/*** Public Effects & Interactions Functions ***/

	struct CreateStreamLocalVars {
		MathError mathErr;
		uint256 duration;
		uint256 ratePerSecond;
	}

	/**
	 * @notice Creates a new stream funded by `msg.sender` and paid towards `recipient`.
	 * @dev Throws if paused.
	 *  Throws if the recipient is the zero address, the contract itself or the caller.
	 *  Throws if the deposit is 0.
	 *  Throws if the start time is before `block.timestamp`.
	 *  Throws if the stop time is before the start time.
	 *  Throws if the duration calculation has a math error.
	 *  Throws if the deposit is smaller than the duration.
	 *  Throws if the deposit is not a multiple of the duration.
	 *  Throws if the rate calculation has a math error.
	 *  Throws if the next stream id calculation has a math error.
	 *  Throws if the contract is not allowed to transfer enough tokens.
	 *  Throws if there is a token transfer failure.
	 * @param recipient The address towards which the money is streamed.
	 * @param deposit The amount of money to be streamed.
	 * @param tokenAddress The ERC20 token to use as streaming currency.
	 * @param startTime The unix timestamp for when the stream starts.
	 * @param stopTime The unix timestamp for when the stream stops.
	 * @return The uint256 id of the newly created stream.
	 */
	function createStream(
		address recipient,
		uint256 deposit,
		address tokenAddress,
		uint256 startTime,
		uint256 stopTime
	) public override returns (uint256) {
		require(recipient != address(0x00), "stream to the zero address");
		require(recipient != address(this), "stream to the contract itself");
		require(recipient != msg.sender, "stream to the caller");
		require(deposit > 0, "deposit is zero");
		require(
			startTime >= block.timestamp,
			"start time before block.timestamp"
		);
		require(stopTime > startTime, "stop time before the start time");

		CreateStreamLocalVars memory vars;
		(vars.mathErr, vars.duration) = subUInt(stopTime, startTime);
		/* `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know `stopTime` is higher than `startTime`. */
		assert(vars.mathErr == MathError.NO_ERROR);

		/* Without this, the rate per second would be zero. */
		require(deposit >= vars.duration, "deposit smaller than time delta");

		require(
			deposit % vars.duration == 0,
			"deposit not multiple of time delta"
		);

		(vars.mathErr, vars.ratePerSecond) = divUInt(deposit, vars.duration);
		/* `divUInt` can only return MathError.DIVISION_BY_ZERO but we know `duration` is not zero. */
		assert(vars.mathErr == MathError.NO_ERROR);

		/* Create and store the stream object. */
		uint256 streamId = nextStreamId;
		streams[streamId] = Types.Stream({
			remainingBalance: deposit,
			deposit: deposit,
			isEntity: true,
			ratePerSecond: vars.ratePerSecond,
			recipient: recipient,
			sender: msg.sender,
			startTime: startTime,
			stopTime: stopTime,
			tokenAddress: tokenAddress
		});

		/* Increment the next stream id. */
		(vars.mathErr, nextStreamId) = addUInt(nextStreamId, uint256(1));
		require(
			vars.mathErr == MathError.NO_ERROR,
			"next stream id calculation error"
		);

		require(
			IERC20(tokenAddress).transferFrom(
				msg.sender,
				address(this),
				deposit
			),
			"token transfer failure"
		);
		emit CreateStream(
			streamId,
			msg.sender,
			recipient,
			deposit,
			tokenAddress,
			startTime,
			stopTime
		);
		return streamId;
	}

	struct WithdrawFromStreamLocalVars {
		MathError mathErr;
	}

	/**
	 * @notice Withdraws from the contract to the recipient's account.
	 * @dev Throws if the id does not point to a valid stream.
	 *  Throws if the caller is not the sender or the recipient of the stream.
	 *  Throws if the amount exceeds the available balance.
	 *  Throws if there is a token transfer failure.
	 * @param streamId The id of the stream to withdraw tokens from.
	 * @param amount The amount of tokens to withdraw.
	 * @return bool true=success, otherwise false.
	 */
	function withdrawFromStream(uint256 streamId, uint256 amount)
		external
		override
		nonReentrant
		streamExists(streamId)
		onlySenderOrRecipient(streamId)
		returns (bool)
	{
		require(amount > 0, "amount is zero");
		Types.Stream memory stream = streams[streamId];
		WithdrawFromStreamLocalVars memory vars;

		uint256 balance = balanceOf(streamId, stream.recipient);
		require(balance >= amount, "amount exceeds the available balance");

		(vars.mathErr, streams[streamId].remainingBalance) = subUInt(
			stream.remainingBalance,
			amount
		);
		/**
		 * `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know that `remainingBalance` is at least
		 * as big as `amount`.
		 */
		assert(vars.mathErr == MathError.NO_ERROR);

		if (streams[streamId].remainingBalance == 0) delete streams[streamId];

		require(
			IERC20(stream.tokenAddress).transfer(stream.recipient, amount),
			"token transfer failure"
		);
		emit WithdrawFromStream(streamId, stream.recipient, amount);
		return true;
	}

	/**
	 * @notice Cancels the stream and transfers the tokens back on a pro rata basis.
	 * @dev Throws if the id does not point to a valid stream.
	 *  Throws if the caller is not the sender or the recipient of the stream.
	 *  Throws if there is a token transfer failure.
	 * @param streamId The id of the stream to cancel.
	 * @return bool true=success, otherwise false.
	 */
	function cancelStream(uint256 streamId)
		external
		override
		nonReentrant
		streamExists(streamId)
		onlySenderOrRecipient(streamId)
		returns (bool)
	{
		Types.Stream memory stream = streams[streamId];
		uint256 senderBalance = balanceOf(streamId, stream.sender);
		uint256 recipientBalance = balanceOf(streamId, stream.recipient);

		delete streams[streamId];

		IERC20 token = IERC20(stream.tokenAddress);
		if (recipientBalance > 0)
			require(
				token.transfer(stream.recipient, recipientBalance),
				"recipient token transfer failure"
			);
		if (senderBalance > 0)
			require(
				token.transfer(stream.sender, senderBalance),
				"sender token transfer failure"
			);

		emit CancelStream(
			streamId,
			stream.sender,
			stream.recipient,
			senderBalance,
			recipientBalance
		);
		return true;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);

	/**
	 * @dev Initializes the contract setting the deployer as the initial owner.
	 */
	constructor() {
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
		require(
			newOwner != address(0),
			"Ownable: new owner is the zero address"
		);
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity =0.7.6;

import "./CarefulMath.sol";

/**
 * @title Exponential module for storing fixed-decision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath {
	uint256 constant expScale = 1e18;
	uint256 constant halfExpScale = expScale / 2;
	uint256 constant mantissaOne = expScale;

	struct Exp {
		uint256 mantissa;
	}

	/**
	 * @dev Creates an exponential from numerator and denominator values.
	 *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
	 *            or if `denom` is zero.
	 */
	function getExp(uint256 num, uint256 denom)
		internal
		pure
		returns (MathError, Exp memory)
	{
		(MathError err0, uint256 scaledNumerator) = mulUInt(num, expScale);
		if (err0 != MathError.NO_ERROR) {
			return (err0, Exp({ mantissa: 0 }));
		}

		(MathError err1, uint256 rational) = divUInt(scaledNumerator, denom);
		if (err1 != MathError.NO_ERROR) {
			return (err1, Exp({ mantissa: 0 }));
		}

		return (MathError.NO_ERROR, Exp({ mantissa: rational }));
	}

	/**
	 * @dev Adds two exponentials, returning a new exponential.
	 */
	function addExp(Exp memory a, Exp memory b)
		internal
		pure
		returns (MathError, Exp memory)
	{
		(MathError error, uint256 result) = addUInt(a.mantissa, b.mantissa);

		return (error, Exp({ mantissa: result }));
	}

	/**
	 * @dev Subtracts two exponentials, returning a new exponential.
	 */
	function subExp(Exp memory a, Exp memory b)
		internal
		pure
		returns (MathError, Exp memory)
	{
		(MathError error, uint256 result) = subUInt(a.mantissa, b.mantissa);

		return (error, Exp({ mantissa: result }));
	}

	/**
	 * @dev Multiply an Exp by a scalar, returning a new Exp.
	 */
	function mulScalar(Exp memory a, uint256 scalar)
		internal
		pure
		returns (MathError, Exp memory)
	{
		(MathError err0, uint256 scaledMantissa) = mulUInt(a.mantissa, scalar);
		if (err0 != MathError.NO_ERROR) {
			return (err0, Exp({ mantissa: 0 }));
		}

		return (MathError.NO_ERROR, Exp({ mantissa: scaledMantissa }));
	}

	/**
	 * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
	 */
	function mulScalarTruncate(Exp memory a, uint256 scalar)
		internal
		pure
		returns (MathError, uint256)
	{
		(MathError err, Exp memory product) = mulScalar(a, scalar);
		if (err != MathError.NO_ERROR) {
			return (err, 0);
		}

		return (MathError.NO_ERROR, truncate(product));
	}

	/**
	 * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
	 */
	function mulScalarTruncateAddUInt(
		Exp memory a,
		uint256 scalar,
		uint256 addend
	) internal pure returns (MathError, uint256) {
		(MathError err, Exp memory product) = mulScalar(a, scalar);
		if (err != MathError.NO_ERROR) {
			return (err, 0);
		}

		return addUInt(truncate(product), addend);
	}

	/**
	 * @dev Divide an Exp by a scalar, returning a new Exp.
	 */
	function divScalar(Exp memory a, uint256 scalar)
		internal
		pure
		returns (MathError, Exp memory)
	{
		(MathError err0, uint256 descaledMantissa) =
			divUInt(a.mantissa, scalar);
		if (err0 != MathError.NO_ERROR) {
			return (err0, Exp({ mantissa: 0 }));
		}

		return (MathError.NO_ERROR, Exp({ mantissa: descaledMantissa }));
	}

	/**
	 * @dev Divide a scalar by an Exp, returning a new Exp.
	 */
	function divScalarByExp(uint256 scalar, Exp memory divisor)
		internal
		pure
		returns (MathError, Exp memory)
	{
		/*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
		(MathError err0, uint256 numerator) = mulUInt(expScale, scalar);
		if (err0 != MathError.NO_ERROR) {
			return (err0, Exp({ mantissa: 0 }));
		}
		return getExp(numerator, divisor.mantissa);
	}

	/**
	 * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
	 */
	function divScalarByExpTruncate(uint256 scalar, Exp memory divisor)
		internal
		pure
		returns (MathError, uint256)
	{
		(MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
		if (err != MathError.NO_ERROR) {
			return (err, 0);
		}

		return (MathError.NO_ERROR, truncate(fraction));
	}

	/**
	 * @dev Multiplies two exponentials, returning a new exponential.
	 */
	function mulExp(Exp memory a, Exp memory b)
		internal
		pure
		returns (MathError, Exp memory)
	{
		(MathError err0, uint256 doubleScaledProduct) =
			mulUInt(a.mantissa, b.mantissa);
		if (err0 != MathError.NO_ERROR) {
			return (err0, Exp({ mantissa: 0 }));
		}

		// We add half the scale before dividing so that we get rounding instead of truncation.
		//  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
		// Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
		(MathError err1, uint256 doubleScaledProductWithHalfScale) =
			addUInt(halfExpScale, doubleScaledProduct);
		if (err1 != MathError.NO_ERROR) {
			return (err1, Exp({ mantissa: 0 }));
		}

		(MathError err2, uint256 product) =
			divUInt(doubleScaledProductWithHalfScale, expScale);
		// The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
		assert(err2 == MathError.NO_ERROR);

		return (MathError.NO_ERROR, Exp({ mantissa: product }));
	}

	/**
	 * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
	 */
	function mulExp(uint256 a, uint256 b)
		internal
		pure
		returns (MathError, Exp memory)
	{
		return mulExp(Exp({ mantissa: a }), Exp({ mantissa: b }));
	}

	/**
	 * @dev Multiplies three exponentials, returning a new exponential.
	 */
	function mulExp3(
		Exp memory a,
		Exp memory b,
		Exp memory c
	) internal pure returns (MathError, Exp memory) {
		(MathError err, Exp memory ab) = mulExp(a, b);
		if (err != MathError.NO_ERROR) {
			return (err, ab);
		}
		return mulExp(ab, c);
	}

	/**
	 * @dev Divides two exponentials, returning a new exponential.
	 *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
	 *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
	 */
	function divExp(Exp memory a, Exp memory b)
		internal
		pure
		returns (MathError, Exp memory)
	{
		return getExp(a.mantissa, b.mantissa);
	}

	/**
	 * @dev Truncates the given exp to a whole number value.
	 *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
	 */
	function truncate(Exp memory exp) internal pure returns (uint256) {
		// Note: We are not using careful math here as we're performing a division that cannot fail
		return exp.mantissa / expScale;
	}

	/**
	 * @dev Checks if first Exp is less than second Exp.
	 */
	function lessThanExp(Exp memory left, Exp memory right)
		internal
		pure
		returns (bool)
	{
		return left.mantissa < right.mantissa; //TODO: Add some simple tests and this in another PR yo.
	}

	/**
	 * @dev Checks if left Exp <= right Exp.
	 */
	function lessThanOrEqualExp(Exp memory left, Exp memory right)
		internal
		pure
		returns (bool)
	{
		return left.mantissa <= right.mantissa;
	}

	/**
	 * @dev Checks if left Exp > right Exp.
	 */
	function greaterThanExp(Exp memory left, Exp memory right)
		internal
		pure
		returns (bool)
	{
		return left.mantissa > right.mantissa;
	}

	/**
	 * @dev returns true if Exp is exactly zero
	 */
	function isZeroExp(Exp memory value) internal pure returns (bool) {
		return value.mantissa == 0;
	}
}

pragma solidity =0.7.6;

/**
 * @title ERC-1620 Money Streaming Standard
 * @author Sablier
 * @dev See https://eips.ethereum.org/EIPS/eip-1620
 */
interface IERC1620 {
	/**
	 * @notice Emits when a stream is successfully created.
	 */
	event CreateStream(
		uint256 indexed streamId,
		address indexed sender,
		address indexed recipient,
		uint256 deposit,
		address tokenAddress,
		uint256 startTime,
		uint256 stopTime
	);

	/**
	 * @notice Emits when the recipient of a stream withdraws a portion or all their pro rata share of the stream.
	 */
	event WithdrawFromStream(
		uint256 indexed streamId,
		address indexed recipient,
		uint256 amount
	);

	/**
	 * @notice Emits when a stream is successfully cancelled and tokens are transferred back on a pro rata basis.
	 */
	event CancelStream(
		uint256 indexed streamId,
		address indexed sender,
		address indexed recipient,
		uint256 senderBalance,
		uint256 recipientBalance
	);

	function balanceOf(uint256 streamId, address who)
		external
		view
		returns (uint256 balance);

	function getStream(uint256 streamId)
		external
		view
		returns (
			address sender,
			address recipient,
			uint256 deposit,
			address token,
			uint256 startTime,
			uint256 stopTime,
			uint256 remainingBalance,
			uint256 ratePerSecond
		);

	function createStream(
		address recipient,
		uint256 deposit,
		address tokenAddress,
		uint256 startTime,
		uint256 stopTime
	) external returns (uint256 streamId);

	function withdrawFromStream(uint256 streamId, uint256 funds)
		external
		returns (bool);

	function cancelStream(uint256 streamId) external returns (bool);
}

pragma solidity =0.7.6;

/**
 * @title Sablier Types
 * @author Sablier
 */
library Types {
	struct Stream {
		uint256 deposit;
		uint256 ratePerSecond;
		uint256 remainingBalance;
		uint256 startTime;
		uint256 stopTime;
		address recipient;
		address sender;
		address tokenAddress;
		bool isEntity;
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

pragma solidity =0.7.6;

/**
 * @title Careful Math
 * @author Compound
 * @notice Derived from OpenZeppelin's SafeMath library
 *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */
contract CarefulMath {
	/**
	 * @dev Possible error codes that we can return
	 */
	enum MathError {
		NO_ERROR,
		DIVISION_BY_ZERO,
		INTEGER_OVERFLOW,
		INTEGER_UNDERFLOW
	}

	/**
	 * @dev Multiplies two numbers, returns an error on overflow.
	 */
	function mulUInt(uint256 a, uint256 b)
		internal
		pure
		returns (MathError, uint256)
	{
		if (a == 0) {
			return (MathError.NO_ERROR, 0);
		}

		uint256 c = a * b;

		if (c / a != b) {
			return (MathError.INTEGER_OVERFLOW, 0);
		} else {
			return (MathError.NO_ERROR, c);
		}
	}

	/**
	 * @dev Integer division of two numbers, truncating the quotient.
	 */
	function divUInt(uint256 a, uint256 b)
		internal
		pure
		returns (MathError, uint256)
	{
		if (b == 0) {
			return (MathError.DIVISION_BY_ZERO, 0);
		}

		return (MathError.NO_ERROR, a / b);
	}

	/**
	 * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
	 */
	function subUInt(uint256 a, uint256 b)
		internal
		pure
		returns (MathError, uint256)
	{
		if (b <= a) {
			return (MathError.NO_ERROR, a - b);
		} else {
			return (MathError.INTEGER_UNDERFLOW, 0);
		}
	}

	/**
	 * @dev Adds two numbers, returns an error on overflow.
	 */
	function addUInt(uint256 a, uint256 b)
		internal
		pure
		returns (MathError, uint256)
	{
		uint256 c = a + b;

		if (c >= a) {
			return (MathError.NO_ERROR, c);
		} else {
			return (MathError.INTEGER_OVERFLOW, 0);
		}
	}

	/**
	 * @dev add a and b and then subtract c
	 */
	function addThenSubUInt(
		uint256 a,
		uint256 b,
		uint256 c
	) internal pure returns (MathError, uint256) {
		(MathError err0, uint256 sum) = addUInt(a, b);

		if (err0 != MathError.NO_ERROR) {
			return (err0, 0);
		}

		return subUInt(sum, c);
	}
}

