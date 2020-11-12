// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


// 
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

// 
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

// 
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

// 
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

// 
contract PublicSaleContract is Ownable {

	using SafeMath for uint256;

	event Whitelist(address indexed _address, bool _isStaking);
	event Deposit(uint256 _timestamp, address indexed _address);
	event Refund(uint256 _timestamp, address indexed _address);
	event TokenReleased(uint256 _timestamp, address indexed _address, uint256 _amount);

	// Token Contract
	IERC20 tokenContract = IERC20(0x03042482d64577A7bdb282260e2eA4c8a89C064B);
	uint256 public noStakeReleaseAmount = 166666.67 ether;
	uint256 public stakeReleaseFirstBatchAmount = 83333.33 ether;
	uint256 public stakeReleaseSecondBatchAmount = 87500 ether;

	// Receiving Address
	address payable receivingAddress = 0x6359EAdBB84C8f7683E26F392A1573Ab6a37B4b4;

	// Contract status
	ContractStatus public status;

	enum ContractStatus {
		INIT, 
		ACCEPT_DEPOSIT, 
		FIRST_BATCH_TOKEN_RELEASED, 
		SECOND_BATCH_TOKEN_RELEASED
	}


	// Whitelist
	mapping(address => WhitelistDetail) whitelist;

	struct WhitelistDetail {
        // Check if address is whitelisted
        bool isWhitelisted;

        // Check if address is staking
        bool isStaking;

        // Check if address has deposited
        bool hasDeposited;
    }

	// Total count of whitelisted address
	uint256 public whitelistCount = 0;

	// Addresses that deposited
	address[] depositAddresses;
	uint256 dIndex = 0;

	// Addresses for second batch release
	address[] secondBatchAddresses;
	uint256 sIndex = 0;

	// Total count of deposits
	uint256 public depositCount = 0;

	// Deposit ticket size
	uint256 public ticketSize = 2.85 ether;

	// Duration of stake
	uint256 constant stakeDuration = 30 days;

	// Time that staking starts
	uint256 public stakeStart;

	constructor() public {
		status = ContractStatus.INIT;
	}

	function updateReceivingAddress(address payable _address) public onlyOwner {
		receivingAddress = _address;
	}

	/**
     * @dev ContractStatus.INIT functions
     */

	function whitelistAddresses(address[] memory _addresses, bool[] memory _isStaking) public onlyOwner {
		require(status == ContractStatus.INIT);

		for (uint256 i = 0; i < _addresses.length; i++) {
			if (!whitelist[_addresses[i]].isWhitelisted) {
				whitelistCount = whitelistCount.add(1);
			}

			whitelist[_addresses[i]].isWhitelisted = true;
			whitelist[_addresses[i]].isStaking = _isStaking[i];

			emit Whitelist(_addresses[i], _isStaking[i]);
		}
	}

	function updateTicketSize(uint256 _amount) public onlyOwner {
		require(status == ContractStatus.INIT);

		ticketSize = _amount;
	}

	function acceptDeposit() public onlyOwner {
		require(status == ContractStatus.INIT);

		status = ContractStatus.ACCEPT_DEPOSIT;
	}

	/**
     * @dev ContractStatus.ACCEPT_DEPOSIT functions
     */

    receive() external payable {
		deposit();
	}

	function deposit() internal {
		require(status == ContractStatus.ACCEPT_DEPOSIT);
		require(whitelist[msg.sender].isWhitelisted && !whitelist[msg.sender].hasDeposited);
		require(msg.value >= ticketSize);

		msg.sender.transfer(msg.value.sub(ticketSize));
		whitelist[msg.sender].hasDeposited = true;
		depositAddresses.push(msg.sender);
		depositCount = depositCount.add(1);

		emit Deposit(block.timestamp, msg.sender);
	}

	function refund(address payable _address) public onlyOwner {
		require(whitelist[_address].hasDeposited);

		delete whitelist[_address];
		_address.transfer(ticketSize);
		depositCount = depositCount.sub(1);

		emit Refund(block.timestamp, _address);
	}

	function refundMultiple(address payable[] memory _addresses) public onlyOwner {
		for (uint256 i = 0; i < _addresses.length; i++) {
			if (whitelist[_addresses[i]].hasDeposited) {
				delete whitelist[_addresses[i]];
				_addresses[i].transfer(ticketSize);
				depositCount = depositCount.sub(1);

				emit Refund(block.timestamp, _addresses[i]);
			}
		}
	}

	function releaseFirstBatchTokens(uint256 _count) public onlyOwner {
		require(status == ContractStatus.ACCEPT_DEPOSIT);

		for (uint256 i = 0; i < _count; i++) {
			if (whitelist[depositAddresses[dIndex]].isWhitelisted) {
				if (whitelist[depositAddresses[dIndex]].isStaking) {
					// Is staking
					tokenContract.transfer(depositAddresses[dIndex], stakeReleaseFirstBatchAmount);
					secondBatchAddresses.push(depositAddresses[dIndex]);

					emit TokenReleased(block.timestamp, depositAddresses[dIndex], stakeReleaseFirstBatchAmount);
				} else {
					// Not staking
					tokenContract.transfer(depositAddresses[dIndex], noStakeReleaseAmount);

					emit TokenReleased(block.timestamp, depositAddresses[dIndex], noStakeReleaseAmount);
				}
			}

			dIndex = dIndex.add(1);

			if (dIndex == depositAddresses.length) {
				receivingAddress.transfer(address(this).balance);
				stakeStart = block.timestamp;
				status = ContractStatus.FIRST_BATCH_TOKEN_RELEASED;
				break;
			}
		}
	}

	/**
     * @dev ContractStatus.FIRST_BATCH_TOKEN_RELEASED functions
     */

    function releaseSecondBatchTokens(uint256 _count) public onlyOwner {
		require(status == ContractStatus.FIRST_BATCH_TOKEN_RELEASED);
		require(block.timestamp > (stakeStart + stakeDuration));

		for (uint256 i = 0; i < _count; i++) {
			tokenContract.transfer(secondBatchAddresses[sIndex], stakeReleaseSecondBatchAmount);
			emit TokenReleased(block.timestamp, secondBatchAddresses[sIndex], stakeReleaseSecondBatchAmount);

			sIndex = sIndex.add(1);

			if (sIndex == secondBatchAddresses.length) {
				status = ContractStatus.SECOND_BATCH_TOKEN_RELEASED;
				break;
			}
		}
	}

	/**
     * @dev ContractStatus.SECOND_BATCH_TOKEN_RELEASED functions
     */

	function withdrawTokens() public onlyOwner {
		require(status == ContractStatus.SECOND_BATCH_TOKEN_RELEASED);

		tokenContract.transfer(receivingAddress, tokenContract.balanceOf(address(this)));
	}

}