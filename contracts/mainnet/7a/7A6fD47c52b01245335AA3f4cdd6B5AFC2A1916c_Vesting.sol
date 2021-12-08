// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMintableToken.sol";

struct VestingSchedule {
	uint256 amount;
	uint256 startDate;
	uint256 endDate;
}

contract Vesting is Ownable {
	bytes32 public immutable name; // A string that can be used to identify this vesting schedule to clients.
	IMintableToken public immutable token; // Token
	mapping(address => VestingSchedule[]) public schedule; // Vesting Schedule
	mapping(address => uint256) public previouslyClaimed; // Amounts users have claimed.

	constructor(address _token, bytes32 _name) {
		require(_token != address(0), 'Vesting: invalid token address');
		require(_name != 0, 'Vesting: invalid name');

		name = _name;
		token = IMintableToken(_token);
	}

	function addToSchedule(address[] memory addresses, VestingSchedule[] memory entries) external onlyOwner {
		require(entries.length > 0, 'Vesting: no entries');
		require(addresses.length == entries.length, 'Vesting: length mismatch');

		uint256 length = addresses.length; // Gas optimisation
		for (uint256 i = 0; i < length; i++) {
			address to = addresses[i];

			require(to != address(0), 'Vesting: to address must not be 0');

			schedule[to].push(entries[i]);

			emit ScheduleChanged(to, schedule[to]);
		}
	}

	event ScheduleChanged(address indexed to, VestingSchedule[] newSchedule);

	function scheduleLength(address to) public view returns (uint256) {
		return schedule[to].length;
	}

	function withdrawalAmount(address to) public view returns (uint256) {
		uint256 total; // Note: Not explicitly initialising to zero to save gas, default value of uint256 is 0.

		// Calculate the total amount the user is entitled to at this point.
		VestingSchedule[] memory entries = schedule[to];
		uint256 length = entries.length;
		for (uint256 i = 0; i < length; i++) {
			VestingSchedule memory entry = entries[i];

			if (entry.startDate <= block.timestamp) {
				if (entry.endDate <= block.timestamp) {
					total += entry.amount;
				} else {
					uint256 totalTime = entry.endDate - entry.startDate;
					uint256 currentTime = block.timestamp - entry.startDate;
					total += entry.amount * currentTime / totalTime;
				}
			}
		}

		uint256 claimed = previouslyClaimed[to];
		return claimed >= total ? 0 : total - claimed;
	}

	function withdraw() public {
		uint256 available = withdrawalAmount(msg.sender);

		require(available > 0, 'Vesting: no amount to withdraw');

		previouslyClaimed[msg.sender] += available;
		token.mint(msg.sender, available);
		emit Vested(msg.sender, available);
	}

	event Vested(address indexed who, uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @dev Interface for a token that will allow mints from a vesting contract
 */
interface IMintableToken {
	function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

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