// SPDX-License-Identifier: GPL-3.0
pragma solidity ^ 0.6.12;

import "./BokkyPooBahsDateTimeLibrary.sol";

interface IGatekeeper { function isTradingOpen() external view returns(bool); }

abstract contract Context
{
	function _msgSender() internal view virtual returns(address payable) { return msg.sender; }

	function _msgData() internal view virtual returns(bytes memory)
	{
		this; // silence state mutability warning without generating bytecode - see
			  // https://github.com/ethereum/solidity/issues/2691
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
contract Ownable is Context
{
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/**
	 * @dev Initializes the contract setting the deployer as the initial owner.
	 */
	constructor() internal
	{
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}

	/**
	 * @dev Returns the address of the current owner.
	 */
	function owner() public view returns(address) { return _owner; }

	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyOwner()
	{
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
	function renounceOwnership() public onlyOwner
	{
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}

	/**
	 * @dev Transfers ownership of the contract to a new account (`newOwner`).
	 * Can only be called by the current owner.
	 */
	function transferOwnership(address newOwner) public onlyOwner { _transferOwnership(newOwner); }

	/**
	 * @dev Transfers ownership of the contract to a new account (`newOwner`).
	 */
	function _transferOwnership(address newOwner) internal
	{
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

contract Leo is Ownable, IGatekeeper
{
	int constant EARLY_OFFSET = 14;
	int constant LATE_OFFSET = -12;

	int public _utcOffset = -4;
	uint public _openingHour = 9;
	uint public _openingMinute = 30;
	uint public _closingHour = 16;
	uint public _closingMin = 0;

	constructor() public {}

	function isTradingOpen() public view override returns(bool)
	{
		uint256 blockTime = block.timestamp;
		return isTradingOpenAt(blockTime);
	}

	function isTradingOpenAt(uint256 timestamp) public view returns(bool)
	{
		uint256 localTimeStamp = applyOffset(timestamp);


		if (BokkyPooBahsDateTimeLibrary.isWeekEnd(localTimeStamp))
		{
			return false;
		}

		uint now_hour;
		uint now_minute;

		(, , , now_hour, now_minute, ) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(localTimeStamp);

		return isOpeningHour(now_hour, now_minute);
	}

	function applyOffset(uint256 timestamp) internal view returns(uint256)
	{
		uint localTimeStamp;
		if (_utcOffset >= 0)
		{
			localTimeStamp = BokkyPooBahsDateTimeLibrary.addHours(timestamp, uint(_utcOffset));
		}
		else
		{
			localTimeStamp = BokkyPooBahsDateTimeLibrary.subHours(timestamp, uint(-_utcOffset));
		}
		return localTimeStamp;
	}


	function isOpeningHour(uint hour, uint minute) internal view returns(bool)
	{
		if ((hour < _openingHour) || (hour >= _closingHour))
		{
			return false;
		}

		if ((hour == _openingHour) && (minute < _openingMinute))
		{
			return false;
		}
		return true;
	}

	function setUTCOffset(int utcOffset) public onlyOwner()
	{
		require(utcOffset > EARLY_OFFSET, "Invalid UCT offset");
		require(utcOffset < LATE_OFFSET, "Invalid UCT offset");
		_utcOffset = utcOffset;
	}
}