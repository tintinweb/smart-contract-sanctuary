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

pragma solidity ^0.8.4;

//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Payment is Initializable, OwnableUpgradeable {
    BaseSettings settings;

    struct BaseSettings {
        address payable xooaAddress;
        uint16 xooaPrimaryTake;
        uint16 xooaSecondaryTake;
    }

    struct PlatformUser {
        address payable platformUser;
        uint16 xooaPrimaryTake; // 2.5% represented as 250
        uint16 xooaSecondaryTake;
        uint16 platformUserPrimaryTake;
        uint16 platformUserSecondaryTake;
    }

    event PlatformUserEvent(
        string appId,
        address platformUser,
        uint16 xooaPrimaryTake,
        uint16 xooaSecondaryTake,
        uint16 platformUserPrimaryTake,
        uint16 platformUserSecondaryTake
    );

    mapping(string => PlatformUser) appToUserMapping;

    event PaymentEvent(
        string transferId,
        address to,
        string appId,
        uint256 amount
    );

    function initialize() public initializer {
        OwnableUpgradeable.__Ownable_init();
        settings = BaseSettings(
            payable(0x72F1064Bb434C7799dBDB15d90a217ADcd42bc75),
            1000,
            500
        );
    }

    function updateXooaSettings(
        address payable _xooaAddress,
        uint16 _xooaPrimaryTake,
        uint16 _xooaSecondaryTake
    ) public virtual onlyOwner {
        require(_xooaAddress != address(0), "Xooa Address is required");
        require(_xooaPrimaryTake >= 999, "Primary should be greater than 1000");
        require(
            _xooaSecondaryTake > 499,
            "secondary should be greater than 500"
        );

        settings = BaseSettings(
            _xooaAddress,
            _xooaPrimaryTake,
            _xooaSecondaryTake
        );
    }

    function getBaseSettings()
        public
        view
        onlyOwner
        returns (BaseSettings memory)
    {
        return settings;
    }

    function updatePlatformUser(
        string memory _appId,
        address payable _platformUser,
        uint16 _xooaPrimaryTake, // 2.5% represented as 250
        uint16 _xooaSecondaryTake,
        uint16 _platformUserPrimaryTake,
        uint16 _platformUserSecondaryTake
    ) public virtual onlyOwner {
        require(_xooaPrimaryTake >= 250); // 250 => 2.5%
        require(_xooaSecondaryTake >= 250); // 250 => 2.5%

        appToUserMapping[_appId] = PlatformUser(
            _platformUser,
            _xooaPrimaryTake,
            _xooaSecondaryTake,
            _platformUserPrimaryTake,
            _platformUserSecondaryTake
        );

        emit PlatformUserEvent(
            _appId,
            _platformUser,
            _xooaPrimaryTake,
            _xooaSecondaryTake,
            _platformUserPrimaryTake,
            _platformUserSecondaryTake
        );
    }

    function getPlatformUserSettings(string memory _appId)
        public
        view
        onlyOwner
        returns (PlatformUser memory)
    {
        return appToUserMapping[_appId];
    }

    function pay(
        string memory transferId,
        string memory appId,
        bool isPrimary,
        address payable to,
        uint64 deadline,
        uint256 amount
    ) public payable virtual {
        require(msg.value >= amount, "msg.value should be greater than amount");

        require(block.timestamp < deadline, "Transaction Timeout");
        PlatformUser memory user = appToUserMapping[appId];

        uint256 platformUserTake = 0;
        uint256 originalAmount = msg.value - tx.gasprice;
        if (user.platformUser != address(0)) {
            // for platform user
            if (isPrimary) {
                platformUserTake =
                    (originalAmount * user.platformUserPrimaryTake) /
                    10000;
            } else {
                platformUserTake =
                    (originalAmount * user.platformUserSecondaryTake) /
                    10000;
            }
            user.platformUser.transfer(platformUserTake);
        }
        uint256 remainingAmount = originalAmount - platformUserTake;

        // xooa take
        uint256 xooaTakePer = 0;
        if (isPrimary) {
            xooaTakePer = user.xooaPrimaryTake != 0
                ? user.xooaPrimaryTake
                : settings.xooaPrimaryTake;
        } else {
            xooaTakePer = user.xooaSecondaryTake != 0
                ? user.xooaSecondaryTake
                : settings.xooaSecondaryTake;
        }

        uint256 sellerSaleTake = remainingAmount -
            ((remainingAmount * xooaTakePer) / 10000);

        // distribute ethers here only
        to.transfer(sellerSaleTake);

        uint256 xooaSaleTake = msg.value - platformUserTake - sellerSaleTake;
        settings.xooaAddress.transfer(xooaSaleTake);

        emit PaymentEvent(transferId, to, appId, msg.value);
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}