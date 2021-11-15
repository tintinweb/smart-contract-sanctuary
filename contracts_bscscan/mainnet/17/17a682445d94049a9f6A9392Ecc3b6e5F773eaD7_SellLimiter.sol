// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


contract SellLimiter is OwnableUpgradeable {

    // Limiting of selling significant token amount in small period
    uint256 public sellLimitWindowDuration;
    uint256 public sellLimitInWindow;
    uint256 public sellBlockDuration;

    struct Sell {
        uint256 timestamp;
        uint256 amount;
    }
    mapping (address => Sell[]) private _windowSells;
    mapping (address => uint256) private _totalSoldInWindow;
    mapping (address => uint256) private _sellsBlockedAt;

    address public token;

    constructor() {}

    function initialize(address token_) public initializer {
        sellLimitWindowDuration = 24 * 60 * 60; // 1 day
        sellLimitInWindow = 10 ** 6 * (10**9);
        sellBlockDuration = 7 * 24 * 60 * 60; // 1 week

        __Ownable_init();
        token = token_;
    }

    function checkAndMoveWindow(address sender, uint256 amount) external {
        require(msg.sender == token, "Only token can move window");
        require(block.timestamp > _sellsBlockedAt[sender] + sellBlockDuration, "Transfer temporarily blocked");

        for (uint256 i = 0; i < _windowSells[sender].length; i++) {
            if (_windowSells[sender][i].timestamp + sellLimitWindowDuration < block.timestamp) {
                _totalSoldInWindow[sender] -= _windowSells[sender][i].amount;
                _windowSells[sender][i] = _windowSells[sender][_windowSells[sender].length - 1];
                _windowSells[sender].pop();
            }
        }
        _windowSells[sender].push(Sell(block.timestamp, amount));
        _totalSoldInWindow[sender] += amount;
        if (_totalSoldInWindow[sender] >= sellLimitInWindow) {
            _sellsBlockedAt[sender] = block.timestamp;
        }
    }

    // Restricted functions

    function updateWindowDuration(uint256 newDuration) external onlyOwner {
        sellLimitWindowDuration = newDuration;
    }

    function updateSellLimit(uint256 newLimit) external onlyOwner {
        sellLimitInWindow = newLimit;
    }

    function updateBlockDuraton(uint256 newDuration) external onlyOwner {
        sellBlockDuration = newDuration;
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

