// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

/**
 *__/\\\______________/\\\_____/\\\\\\\\\_______/\\\\\\\\\______/\\\\\\\\\\\\\___
 * _\/\\\_____________\/\\\___/\\\\\\\\\\\\\___/\\\///////\\\___\/\\\/////////\\\_
 *  _\/\\\_____________\/\\\__/\\\/////////\\\_\/\\\_____\/\\\___\/\\\_______\/\\\_
 *   _\//\\\____/\\\____/\\\__\/\\\_______\/\\\_\/\\\\\\\\\\\/____\/\\\\\\\\\\\\\/__
 *    __\//\\\__/\\\\\__/\\\___\/\\\\\\\\\\\\\\\_\/\\\//////\\\____\/\\\/////////____
 *     ___\//\\\/\\\/\\\/\\\____\/\\\/////////\\\_\/\\\____\//\\\___\/\\\_____________
 *      ____\//\\\\\\//\\\\\_____\/\\\_______\/\\\_\/\\\_____\//\\\__\/\\\_____________
 *       _____\//\\\__\//\\\______\/\\\_______\/\\\_\/\\\______\//\\\_\/\\\_____________
 *        ______\///____\///_______\///________\///__\///________\///__\///______________
 **/

// @openzeppelin
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

// helpers
import './helpers/WarpBase.sol';

// Interfaces
import './interfaces/IStaking.sol';

contract StakingHelper is WarpBase {
    address public WARP;

    function initialize(address _WARP) public initializer {
        __WarpBase_init();

        require(_WARP != address(0));
        WARP = _WARP;
    }

    function stake(
        uint256 _amount,
        address _recipient,
        address _staking
    ) external whenNotPaused {
        IERC20(WARP).transferFrom(msg.sender, address(this), _amount);
        IERC20(WARP).approve(_staking, _amount);
        IStaking(_staking).stake(_amount, _recipient);
        // IStaking(_staking).claim(_recipient);
    }

    function stakeSender(uint256 _amount, address _staking) external whenNotPaused {
        IERC20(WARP).transferFrom(msg.sender, address(this), _amount);
        IERC20(WARP).approve(_staking, _amount);
        IStaking(_staking).stake(_amount, msg.sender);
        // IStaking(_staking).claim(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

contract WarpBase is Initializable {
    bool public paused;
    address public owner;
    mapping(address => bool) public pausers;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PauseChanged(address indexed by, bool indexed paused);

    /** ========  MODIFIERS ========  */

    /** @notice modifier for owner only calls */
    modifier onlyOwner() {
        require(owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    /** @notice pause toggler */
    modifier onlyPauseToggler() {
        require(owner == msg.sender || pausers[msg.sender], 'Ownable: caller is not the owner');
        _;
    }

    /** @notice modifier for pausing contracts */
    modifier whenNotPaused() {
        require(!paused || owner == msg.sender || pausers[msg.sender], 'Feature is paused');
        _;
    }

    /** ========  INITALIZE ========  */
    function __WarpBase_init() internal initializer {
        owner = msg.sender;
        paused = true;
    }

    /** ========  OWNERSHIP FUNCTIONS ========  */

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /** ===== PAUSER FUNCTIONS ========== */

    /** @dev allow owner to add or remove pausers */
    function setPauser(address _pauser, bool _allowed) external onlyOwner {
        pausers[_pauser] = _allowed;
    }

    /** @notice toggle pause on and off */
    function setPause(bool _paused) external onlyPauseToggler {
        paused = _paused;

        emit PauseChanged(msg.sender, _paused);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

interface IStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);

    function index() external view returns (uint256);

    function rebase() external;

    function getStakedAt(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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