// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./libraries/AddressPagination.sol";

/// @title Firestarter WhiteList Contract
/// @author Michael, Daniel Lee
/// @notice You can use this contract to manage whitelisted users
/// @dev All function calls are currently implemented without side effects
contract Whitelist is Initializable, OwnableUpgradeable {
    using AddressPagination for address[];

    struct UserData {
        // User wallet address
        address wallet;
        // Flag for KYC status
        bool isKycPassed;
        // Max allocation for this user in public presale
        uint256 publicMaxAlloc;
        // Flag if this user is allowed to participate in private presale
        bool allowedPrivateSale;
        // Max allocation for this user in private presale
        uint256 privateMaxAlloc;
    }

    /// @notice Maximum input array length(used in `addToWhitelist`, `removeFromWhitelist`)
    uint256 public constant MAX_ARRAY_LENGTH = 50;

    /// @notice Count of users participating in whitelisting
    uint256 public totalUsers;

    /// @dev White List
    mapping(address => UserData) private whitelistedUsers;

    // Users list
    address[] internal userlist;
    mapping(address => uint256) internal indexOf;
    mapping(address => bool) internal inserted;

    /// @notice An event emitted when a user is added or removed. True: Added, False: Removed
    event AddedOrRemoved(bool added, address indexed user, uint256 timestamp);

    function initialize() external initializer {
        __Ownable_init();
    }

    /**
     * @notice Return the number of users
     */
    function usersCount() external view returns (uint256) {
        return userlist.length;
    }

    /**
     * @notice Return the list of users
     */
    function getUsers(uint256 page, uint256 limit) external view returns (address[] memory) {
        return userlist.paginate(page, limit);
    }

    /**
     * @notice Add users to white list
     * @dev Only owner can do this operation
     * @param users List of user data
     */
    function addToWhitelist(UserData[] memory users) external onlyOwner {
        require(
            users.length <= MAX_ARRAY_LENGTH,
            "addToWhitelist: users length shouldn't exceed MAX_ARRAY_LENGTH"
        );

        for (uint256 i = 0; i < users.length; i++) {
            UserData memory user = users[i];
            whitelistedUsers[user.wallet] = user;

            if (inserted[user.wallet] == false) {
                inserted[user.wallet] = true;
                indexOf[user.wallet] = userlist.length;
                userlist.push(user.wallet);
            }

            emit AddedOrRemoved(true, user.wallet, block.timestamp);
        }
        totalUsers = userlist.length;
    }

    /**
     * @notice Remove from white lsit
     * @dev Only owner can do this operation
     * @param addrs addresses to be removed
     */
    function removeFromWhitelist(address[] memory addrs) external onlyOwner {
        require(
            addrs.length <= MAX_ARRAY_LENGTH,
            "removeFromWhitelist: users length shouldn't exceed MAX_ARRAY_LENGTH"
        );

        for (uint256 i = 0; i < addrs.length; i++) {
            // Ignore for non-existing users
            if (whitelistedUsers[addrs[i]].wallet != address(0)) {
                delete whitelistedUsers[addrs[i]];
                emit AddedOrRemoved(false, addrs[i], block.timestamp);
            }
            if (inserted[addrs[i]] == true) {
                delete inserted[addrs[i]];

                uint256 index = indexOf[addrs[i]];
                uint256 lastIndex = userlist.length - 1;
                address lastUser = userlist[lastIndex];

                indexOf[lastUser] = index;
                delete indexOf[addrs[i]];

                userlist[index] = lastUser;
                userlist.pop();
            }
        }
        totalUsers = userlist.length;
    }

    /**
     * @notice Return whitelisted user info
     * @param _user user wallet address
     * @return user wallet, kyc status, max allocation
     */
    function getUser(address _user)
        external
        view
        returns (
            address,
            bool,
            uint256,
            bool,
            uint256
        )
    {
        return (
            whitelistedUsers[_user].wallet,
            whitelistedUsers[_user].isKycPassed,
            whitelistedUsers[_user].publicMaxAlloc,
            whitelistedUsers[_user].allowedPrivateSale,
            whitelistedUsers[_user].privateMaxAlloc
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

library AddressPagination {
    function paginate(
        address[] memory array,
        uint256 page,
        uint256 limit
    ) internal pure returns (address[] memory result) {
        result = new address[](limit);
        for (uint256 i = 0; i < limit; i++) {
            if (page * limit + i >= array.length) {
                result[i] = address(0);
            } else {
                result[i] = array[page * limit + i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}