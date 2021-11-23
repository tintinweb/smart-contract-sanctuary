// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.0 <0.9.0;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract AswapAccess is Ownable, ReentrancyGuard {

	event Blocked(address indexed user);
	event Unblocked(address indexed user);
	event Allowed(address indexed user);
	event Disallowed(address indexed user);
	event AdminAdded(address indexed user);
	event AdminRemoved(address indexed user);

	struct PendingList {
		bool isWhitelist;
		address[] users;
		bool[] values;
		address[] approved;
		address[] denied;
		mapping(address => uint32) addressMap;
	}

	mapping(address => uint256) adminIndex;
	address[] private adminList;
	mapping(address => bool) blacklist;
  mapping(address => bool) whitelist;
	PendingList[] public pendingApprovals;

	uint256 public minAllowance;

  constructor() {
		adminList.push(address(this));
		minAllowance = 50;
  }

  modifier onlyAdmin() {
    require(adminIndex[_msgSender()] > 0, "only admin allowed");
    _;
  }

	function isAdmin(address user) public view returns (bool) {
		return adminIndex[user] > 0;
	}

	function updateMinAllowance(uint256 value) public nonReentrant onlyOwner {
		require(value <= 100, "Invalid minimum required allowance");
		minAllowance = value;
	}

	function updateAdmin(address user, bool flag) public virtual nonReentrant onlyOwner {
    require(user != address(0), "Invalid admin");
		if (flag) {
			if (adminIndex[user] == 0) {
				adminList.push(user);
				adminIndex[user] = adminList.length - 1;
				emit AdminAdded(user);
			}
		} else {
			if (adminIndex[user] > 0) {
				uint256 prevIndex = adminIndex[user];
				adminList[prevIndex] = adminList[adminList.length - 1];
				adminIndex[adminList[prevIndex]] = prevIndex;
				adminIndex[user] = 0;
				adminList.pop();
				emit AdminRemoved(user);
			}
		}
	}

	function getTotalAdmin() public view returns (uint) {
		return adminList.length - 1;
	}

	function getTotalAdminList() public view returns (address[] memory) {
		return adminList;
	}

	function getMinimumAllowance() public view returns (uint) {
		return (adminList.length - 1) * minAllowance / 100;
	}

	function getTotalPending() public view onlyAdmin returns (uint) {
		return pendingApprovals.length;
	}

	function getPendingApproval(uint256 index) public view onlyAdmin returns (bool, address[] memory, bool[] memory) {
		PendingList storage _currentApproval = pendingApprovals[index];
		return (_currentApproval.isWhitelist, _currentApproval.users, _currentApproval.values);
	}

	function processPendingApproval(uint256 index, bool allow) public nonReentrant onlyAdmin {
		require(index < pendingApprovals.length, "Wrong approval list index");
		PendingList storage _currentApproval = pendingApprovals[index];
		uint32 prevIndex = _currentApproval.addressMap[_msgSender()];
		if (prevIndex > 0) {
			bool prevFlag;
			if (_currentApproval.approved.length >= prevIndex) {
				if (_currentApproval.approved[prevIndex - 1] == _msgSender()) {
					prevFlag = true;
				}
			}
			if (allow) {
				if (!prevFlag) {
					if (_currentApproval.denied.length >= prevIndex) {
						_currentApproval.denied[prevIndex - 1] = _currentApproval.denied[_currentApproval.denied.length - 1];
						_currentApproval.addressMap[_currentApproval.denied[prevIndex - 1]] = prevIndex;
						_currentApproval.denied.pop();
					}
					_currentApproval.approved.push(_msgSender());
					_currentApproval.addressMap[_msgSender()] = uint32(_currentApproval.approved.length);
				}
			} else {
				if (prevFlag) {
					if (_currentApproval.approved.length >= prevIndex) {
						_currentApproval.approved[prevIndex - 1] = _currentApproval.approved[_currentApproval.approved.length - 1];
						_currentApproval.addressMap[_currentApproval.approved[prevIndex - 1]] = prevIndex;
						_currentApproval.approved.pop();
					}
					_currentApproval.denied.push(_msgSender());
					_currentApproval.addressMap[_msgSender()] = uint32(_currentApproval.denied.length);
				}
			}
		} else {
			if (allow) {
				_currentApproval.approved.push(_msgSender());
				_currentApproval.addressMap[_msgSender()] = uint32(_currentApproval.approved.length);
			} else {
				_currentApproval.denied.push(_msgSender());
				_currentApproval.addressMap[_msgSender()] = uint32(_currentApproval.denied.length);
			}
		}
		uint256 minimumRequirement = (adminList.length - 1) * minAllowance / 100;
		if (allow) {
			if (_currentApproval.approved.length >= minimumRequirement) {
				if (_currentApproval.isWhitelist) {
					for (uint256 listIndex = 0; listIndex < _currentApproval.users.length; listIndex++) {
						whitelist[_currentApproval.users[listIndex]] = _currentApproval.values[listIndex];
					}
				} else {
					for (uint256 listIndex = 0; listIndex < _currentApproval.users.length; listIndex++) {
						blacklist[_currentApproval.users[listIndex]] = _currentApproval.values[listIndex];
					}
				}
				_currentApproval = pendingApprovals[pendingApprovals.length - 1];
				pendingApprovals.pop();
			}
		} else {
			if (_currentApproval.denied.length >= minimumRequirement) {
				_currentApproval = pendingApprovals[pendingApprovals.length - 1];
				pendingApprovals.pop();
			}
		}
	}

	function updateBlacklist(address user, bool value) public virtual nonReentrant onlyOwner {
    pendingApprovals.push();
    PendingList storage _tempPending = pendingApprovals[pendingApprovals.length - 1];
		_tempPending.users = [user];
		_tempPending.values = [value];
		_tempPending.isWhitelist = false;
	}

	function batchUpdateBlacklist(address[] memory users, bool[] memory values) public virtual nonReentrant onlyOwner {
    require(users.length == values.length, "Input values are not matched each other.");

    pendingApprovals.push();
    PendingList storage _tempPending = pendingApprovals[pendingApprovals.length - 1];
		_tempPending.users = users;
		_tempPending.values = values;
		_tempPending.isWhitelist = false;
	}

	function isBlacklisted(address user) public view returns (bool) {
		return blacklist[user];
	}

	function updateWhitelist(address user, bool value) public virtual nonReentrant onlyOwner {
    pendingApprovals.push();
    PendingList storage _tempPending = pendingApprovals[pendingApprovals.length - 1];
		_tempPending.users = [user];
		_tempPending.values = [value];
		_tempPending.isWhitelist = true;
	}

	function batchUpdateWhitelist(address[] memory users, bool[] memory values) public virtual nonReentrant onlyOwner {
    require(users.length == values.length, "Input values are not matched each other.");

    pendingApprovals.push();
    PendingList storage _tempPending = pendingApprovals[pendingApprovals.length - 1];
		_tempPending.users = users;
		_tempPending.values = values;
		_tempPending.isWhitelist = true;
	}

	function isWhitelisted(address user) public view returns (bool) {
		return whitelist[user];
	}
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

pragma solidity ^0.8.0;

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

    constructor () {
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