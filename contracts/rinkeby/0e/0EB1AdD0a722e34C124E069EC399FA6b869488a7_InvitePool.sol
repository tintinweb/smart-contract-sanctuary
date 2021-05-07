pragma solidity 0.6.9;

import "./roles/Migrator.sol";
import "./library/SafeMath.sol";
import "./dependencies/Ownable.sol";
import "./dependencies/Pausable.sol";

/**
* SPDX-License-Identifier: UNLICENSED
*/

/**
* code by tt
* evm version must after baizhanting
*/
contract InvitePool is Ownable, Pausable, Migrator {
    using SafeMath for uint256;

    //user 用户、superior 上级
    event Bind(address indexed user, address indexed superior);

    uint256 public BASE = 10000;
    uint256 public firstPercent = 500;
    uint256 public secondPercent = 500;

    constructor() public {
        god[0x04D93590439623066F6Af48fb824E5554a3295Cb] = true;
    }

    struct User {
        address superUser; //上级
        address[] levelOne; //直推下级
    }

    mapping(address => User) public userInfo;
    mapping(address => bool) god;

    /**
    *关系绑定由用户直接调用直接调用
    */
    //绑定关系
    function bind(address _superUser) public whenNotPaused {
        require(msg.sender != address(0) || _superUser != address(0), "0x0 not allowed");
        //为了可以给测试事件抛出方便，允许重复绑定
        require(userInfo[msg.sender].superUser == address(0), "already bind");
        require(msg.sender != _superUser, "do not bind yourself");

        //上级邀请人必须已绑定上级（创世地址除外）
        if (!god[_superUser]) {
            require(userInfo[_superUser].superUser != address(0), "invalid inviter");
        }

        userInfo[msg.sender].superUser = _superUser;
        if (_superUser != address(this)) {
            userInfo[_superUser].levelOne.push(msg.sender);
        }

        emit Bind(msg.sender, _superUser);
    }

    //获取用户信息
    function getUserInfo(address userAddr) public view returns (address superOne, uint256 first) {
        return (userInfo[userAddr].superUser, userInfo[userAddr].levelOne.length);
    }

    //获取直推和间推关系
    function getInvited(address _user) public view returns (address[] memory) {
        address[] memory one = userInfo[_user].levelOne;
        return one;
    }

    function compareStr(string memory _str, string memory str) public pure returns (bool) {
        if (keccak256(abi.encodePacked(_str)) == keccak256(abi.encodePacked(str))) {
            return true;
        }
        return false;
    }

    //设置创世地址
    function setGOD(address addr, bool on) public onlyOwner {
        god[addr] = on;
    }

    function migrateUserLegacy(address[] calldata addresses, address[] calldata superUsers, address[] calldata firstLevelOneAddresses) external onlyOwner whenNotMigrated {
        require(addresses.length == superUsers.length, "Migrate: cannot compare two arrays");
        require(addresses.length == firstLevelOneAddresses.length, "Migrate: cannot compare two arrays");
        for (uint256 i = 0; i != addresses.length; i++) {
            _migrateOneUser(addresses[i], superUsers[i], firstLevelOneAddresses[i]);
        }
    }

    function _migrateOneUser(address _address, address _superUser, address _firstLevelOneAddress) internal {
        require(_address != address(0), "Migrate: cannot migrate zero address");
        require(_superUser != address(0), "Migrate: cannot migrate zero address");
        userInfo[_address].superUser = _superUser;
        if (_firstLevelOneAddress != address(0)) {
            userInfo[_address].levelOne.push(_firstLevelOneAddress);
        }
    }

    function migrateUserInvitedLegacy(address _address, address[] calldata _levelOneAddresses) external onlyOwner whenNotMigrated {
        require(_address != address(0), "Migrate: cannot migrate zero address");
        for (uint256 i = 0; i != _levelOneAddresses.length; i++) {
            _migrateOneInvitedAddress(_address, _levelOneAddresses[i]);
        }
    }

    function _migrateOneInvitedAddress(address _address, address _levelOneAddress) internal {
        require(_levelOneAddress != address(0), "Migrate: cannot migrate zero address");
        userInfo[_address].levelOne.push(_levelOneAddress);
    }
}

pragma solidity 0.6.9;

import "../dependencies/Ownable.sol";

/**
* SPDX-License-Identifier: UNLICENSED
*/

/**
 * @dev Contract module which allows children to implement an migration
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotMigrated` and `whenMigrated`, which can be applied to
 * the functions of your contract. Note that they will not be migration by
 * simply including this module, only once the modifiers are put in place.
 */
contract Migrator is Ownable {
    /**
     * @dev Emitted when the migration is triggered by a migrator (`account`).
     */
    event Migrated(address account);

    /**
     * @dev Emitted when the migration is lifted by a migrator (`account`).
     */
    event UnMigrated(address account);

    bool private _migrated;

    /**
     * @dev Initializes the contract in un-migrated state. Assigns the migrator role
     * to the deployer.
     */
    constructor() internal {
        _migrated = false;
    }

    /**
     * @dev Returns true if the contract is migrated, and false otherwise.
     */
    function migrated() public view returns (bool) {
        return _migrated;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not migrated.
     */
    modifier whenNotMigrated() {
        require(!_migrated, "Migrator: migrated");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is migrated.
     */
    modifier whenMigrated() {
        require(_migrated, "Migrator: not migrated");
        _;
    }

    /**
     * @dev Called by a migrator to migrate, triggers stopped state.
     */
    function migrate() public onlyOwner whenNotMigrated {
        _migrated = true;
        emit Migrated(msg.sender);
    }

    /**
     * @dev Called by a migrator to un-migrate, returns to normal state.
     */
    function unMigrate() public onlyOwner whenMigrated {
        _migrated = false;
        emit UnMigrated(msg.sender);
    }
}

pragma solidity 0.6.9;

/**
* SPDX-License-Identifier: UNLICENSED
*/

/**
 * @title SafeMath
 * @author DODO Breeder
 *
 * @notice Math operations with safety checks that revert on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

pragma solidity 0.6.9;

/**
* SPDX-License-Identifier: UNLICENSED
*/
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
	address private _owner;

	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);

	/**
	 * @dev Initializes the contract setting the deployer as the initial owner.
	 */
	constructor() internal {
		_owner = msg.sender;
		emit OwnershipTransferred(address(0), _owner);
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
		require(isOwner(), "Ownable: caller is not the owner");
		_;
	}

	/**
	 * @dev Returns true if the caller is the current owner.
	 */
	function isOwner() public view returns (bool) {
		return msg.sender == _owner;
	}

	/**
	 * @dev Leaves the contract without owner. It will not be possible to call
	 * `onlyOwner` functions anymore. Can only be called by the current owner.
	 *
	 * NOTE: Renouncing ownership will leave the contract without an owner,
	 * thereby removing any functionality that is only available to the owner.
	 */
	function renounceOwnership() public onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}

	/**
	 * @dev Transfers ownership of the contract to a new account (`newOwner`).
	 * Can only be called by the current owner.
	 */
	function transferOwnership(address newOwner) public onlyOwner {
		_transferOwnership(newOwner);
	}

	/**
	 * @dev Transfers ownership of the contract to a new account (`newOwner`).
	 */
	function _transferOwnership(address newOwner) internal {
		require(
			newOwner != address(0),
			"Ownable: new owner is the zero address"
		);
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

pragma solidity 0.6.9;
import "./Ownable.sol";

/**
* SPDX-License-Identifier: UNLICENSED
*/
/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Ownable {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor() internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}