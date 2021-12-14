// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../interfaces/IORT.sol";

contract StakingPool is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    //Model  Array for staking
    struct staking {
        address owner;
        uint256 balances;
        uint256 end_staking;
        uint256 duration;
        bool changeClaimed;
        uint256 check_claim;
    }

    //ERC20PresetMinterPauser variable
    IORT private rewardToken;
    //variables
    mapping(address => uint256) private duration;
    //variables
    mapping(address => uint256) private end_staking;
    //IERC20Upgradeable variable
    IERC20Upgradeable private stakeToken;
    address public admin;
    //variables
    uint256 private total_percent;
    uint256 private total_percent2;
    //new variables
    staking[] public tokens_staking;
    mapping(address => uint256[]) public userStake;

    event Invest(
        address indexed user,
        uint256 indexed lockId,
        uint256 endDate,
        uint256 duration,
        uint256 amountStaked,
        uint256 reward
    );
    event Withdraw(
        address indexed user,
        uint256 indexed lockId,
        uint256 amountWithdrawn
    );
    event Claim(
        address indexed user,
        uint256 indexed lockId,
        uint256 amountclaimed
    );

    //initialize function
    function initialize(IORT _rewardToken, IERC20Upgradeable _stakeToken)
        public
        initializer
    {
        admin = msg.sender;
        rewardToken = _rewardToken;
        stakeToken = _stakeToken;

        __Ownable_init();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();
    }

    //Only stakeOwner Modifyer
    modifier onlyStakeOwner(uint256 stakeId) {
        require(tokens_staking.length > stakeId, "STACK DOES_NOT_EXIST");
        require(
            tokens_staking[stakeId].owner == msg.sender,
            "STACKINGPOOL: UNAUTHORIZED USER"
        );
        _;
    }

    // ivesting function for staking
    function invest(uint256 end_date, uint256 qty_ort) external whenNotPaused {
        require(qty_ort > 0, "amount cannot be 0");
        //transfer token to this smart contract
        stakeToken.approve(address(this), qty_ort);
        stakeToken.safeTransferFrom(msg.sender, address(this), qty_ort);
        //save their staking duration for further use
        if (end_date == 3) {
            end_staking[msg.sender] = block.timestamp + 90 days;
            duration[msg.sender] = 3;
        } else if (end_date == 6) {
            end_staking[msg.sender] = block.timestamp + 180 days;
            duration[msg.sender] = 6;
        } else if (end_date == 12) {
            end_staking[msg.sender] = block.timestamp + 365 days;
            duration[msg.sender] = 12;
        } else if (end_date == 24) {
            end_staking[msg.sender] = block.timestamp + 730 days;
            duration[msg.sender] = 24;
        }
        //calculate reward tokens  for further use
        uint256 check_reward = _Check_reward(duration[msg.sender], qty_ort) /
            1 ether;
        //save values in array
        tokens_staking.push(
            staking(
                msg.sender,
                qty_ort,
                end_staking[msg.sender],
                duration[msg.sender],
                true,
                check_reward
            )
        );
        //save array index in map
        uint256 lockId = tokens_staking.length - 1;
        userStake[msg.sender].push(lockId);

        emit Invest(
            msg.sender,
            lockId,
            end_staking[msg.sender],
            duration[msg.sender],
            qty_ort,
            check_reward
        );
    }

    //get all stake ids  of user
    function getUserStaking(address user)
        external
        view
        returns (uint256[] memory)
    {
        return userStake[user];
    }

    //withdraw and claim at once
    function withdrawAndClaim(uint256 lockId)
        external
        nonReentrant
        whenNotPaused
        onlyStakeOwner(lockId)
    {
        _withdraw(lockId);
        _claim(lockId);
    }

    //withdraw function
    function withdraw_amount(uint256 lockId)
        external
        nonReentrant
        whenNotPaused
        onlyStakeOwner(lockId)
    {
        _withdraw(lockId);
    }

    function _withdraw(uint256 lockId) internal {
        require(tokens_staking[lockId].balances > 0, "not an investor");
        require(
            block.timestamp >= tokens_staking[lockId].end_staking,
            "too early"
        );
        //Change status of invester for reward
        uint256 invested_balance = 0;
        invested_balance = tokens_staking[lockId].balances;
        tokens_staking[lockId].changeClaimed = false;
        tokens_staking[lockId].balances = 0;
        tokens_staking[lockId].duration = 0;
        tokens_staking[lockId].end_staking = 0;
        //transfer back amount to user
        stakeToken.safeTransfer(msg.sender, invested_balance);

        emit Withdraw(msg.sender, lockId, invested_balance);
    }

    //Claim rewards
    function Claim_reward(uint256 lockId)
        external
        nonReentrant
        whenNotPaused
        onlyStakeOwner(lockId)
    {
        _claim(lockId);
    }

    function _claim(uint256 lockId) internal {
        require(tokens_staking[lockId].check_claim > 0, "No Reward Available");
        require(
            tokens_staking[lockId].changeClaimed == false,
            "Already claimed"
        );
        //change status of invested user
        tokens_staking[lockId].changeClaimed = true;
        uint256 claimed_amount = 0;
        claimed_amount = tokens_staking[lockId].check_claim;
        tokens_staking[lockId].check_claim = 0;
        //mint new ort token
        rewardToken.mint(msg.sender, claimed_amount);

        emit Claim(msg.sender, lockId, claimed_amount);
    }

    //Total percent function
    function _Percentage(uint256 _value, uint256 _percentage)
        internal
        pure
        returns (uint256)
    {
        uint256 basePercent = 100;
        uint256 Percent = (_value * _percentage) / basePercent;
        return Percent;
    }

    //Reward Calculation
    function _Check_reward(uint256 durations, uint256 balance)
        internal
        returns (uint256)
    {
        total_percent2 = balance / 1 ether;
        //if user stakes token for 3 months
        if (durations == 3) {
            if (total_percent2 >= 10000 && total_percent2 < 40000) {
                total_percent = _Percentage(balance, 750000000000000000);
            } else if (total_percent2 >= 40000 && total_percent2 < 60000) {
                total_percent = _Percentage(balance, 1500000000000000000);
            } else if (total_percent2 >= 60000 && total_percent2 < 80000) {
                total_percent = _Percentage(balance, 2250000000000000000);
            } else if (total_percent2 >= 80000 && total_percent2 < 100000) {
                total_percent = _Percentage(balance, 3000000000000000000);
            } else if (total_percent2 >= 100000) {
                total_percent = _Percentage(balance, 3750000000000000000);
            }
        } else if (durations == 6) {
            if (total_percent2 >= 10000 && total_percent2 < 40000) {
                total_percent = _Percentage(balance, 2000000000000000000);
            } else if (total_percent2 >= 40000 && total_percent2 < 60000) {
                total_percent = _Percentage(balance, 4000000000000000000);
            } else if (total_percent2 >= 60000 && total_percent2 < 80000) {
                total_percent = _Percentage(balance, 6000000000000000000);
            } else if (total_percent2 >= 80000 && total_percent2 < 100000) {
                total_percent = _Percentage(balance, 8000000000000000000);
            } else if (total_percent2 >= 100000) {
                total_percent = _Percentage(balance, 10000000000000000000);
            }
        } else if (durations == 12) {
            if (total_percent2 >= 10000 && total_percent2 < 40000) {
                total_percent = _Percentage(balance, 5000000000000000000);
            } else if (total_percent2 >= 40000 && total_percent2 < 60000) {
                total_percent = _Percentage(balance, 10000000000000000000);
            } else if (total_percent2 >= 60000 && total_percent2 < 80000) {
                total_percent = _Percentage(balance, 15000000000000000000);
            } else if (total_percent2 >= 80000 && total_percent2 < 100000) {
                total_percent = _Percentage(balance, 20000000000000000000);
            } else if (total_percent2 >= 100000) {
                total_percent = _Percentage(balance, 25000000000000000000);
            }
        } else if (durations == 24) {
            if (total_percent2 >= 10000 && total_percent2 < 40000) {
                total_percent = _Percentage(balance, 14000000000000000000);
            } else if (total_percent2 >= 40000 && total_percent2 < 60000) {
                total_percent = _Percentage(balance, 28000000000000000000);
            } else if (total_percent2 >= 60000 && total_percent2 < 80000) {
                total_percent = _Percentage(balance, 42000000000000000000);
            } else if (total_percent2 >= 80000 && total_percent2 < 100000) {
                total_percent = _Percentage(balance, 56000000000000000000);
            } else if (total_percent2 >= 100000) {
                total_percent = _Percentage(balance, 70000000000000000000);
            }
        }
        return total_percent;
    }

    //Emergency withdraw function
    function Withdraw_Emergency(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be non zero");
        stakeToken.safeTransfer(admin, amount);
    }

    //Emergency pause function
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./IBEP20.sol";
import "./crosschain/IAnyswapV4ERC20.sol";

interface IORT is IBEP20, IAnyswapV4ERC20 {
    function mint(uint256 amount) external returns (bool);
    function burn(uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IBEP20 is IERC20Metadata {
    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "../IERC2612.sol";
import "../IERC677.sol";

interface IAnyswapV4ERC20 is IERC2612, IERC677 {
    function underlying() external view returns(address);

    // configurable delay for timelock functions
    function delay() external view returns(uint256);

    // set of minters, can be this bridge or other bridges
    function isMinter(address minter) external view returns(bool);

    // primary controller of the token contract
    function vault() external view returns(address);

    function pendingMinter() external view returns(address);
    function delayMinter() external view returns(uint256);

    function pendingVault() external view returns(address);
    function delayVault() external view returns(uint256);

    event LogChangeVault(address indexed oldVault, address indexed newVault, uint256 indexed effectiveTime);
    event LogChangeMPCOwner(address indexed oldOwner, address indexed newOwner, uint256 indexed effectiveHeight);
    event LogSwapin(bytes32 indexed txhash, address indexed account, uint256 amount);
    event LogSwapout(address indexed account, address indexed bindaddr, uint256 amount);
    event LogAddAuth(address indexed auth, uint256 timestamp);

    function mpc() external view returns (address);
    function changeMPCOwner(address newVault) external returns (bool);

    function setVaultOnly(bool enabled) external;
    function initVault(address _vault) external;
    function setVault(address _vault) external;
    function applyVault() external;
    function changeVault(address newVault) external returns (bool);

    function setMinter(address _auth) external;
    function applyMinter() external;
    function revokeMinter(address _auth) external;
    function getAllMinters() external view returns (address[] memory);

    function mint(address to, uint256 amount) external returns (bool);
    function burn(address from, uint256 amount) external returns (bool);

    function Swapin(bytes32 txhash, address account, uint256 amount) external returns (bool);
    function Swapout(uint256 amount, address bindaddr) external returns (bool);

    function depositWithPermit(
        address target,
        uint256 value,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s, address to
    ) external returns (uint);
    function depositWithTransferPermit(
        address target,
        uint256 value,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s, 
        address to
    ) external returns (uint);
    
    function deposit() external returns (uint);
    function deposit(uint256 amount) external returns (uint);
    function deposit(uint256 amount, address to) external returns (uint);
    function depositVault(uint256 amount, address to) external returns (uint);

    function withdraw() external returns (uint);
    function withdraw(uint256 amount) external returns (uint);
    function withdraw(uint256 amount, address to) external returns (uint);
    function withdrawVault(address from, uint256 amount, address to) external returns (uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Sets `value` as allowance of `spender` account over `owner` account's token, 
     * given `owner` account's signed approval.
     * Emits {Approval} event.
     * Requirements:
     *   - `deadline` must be timestamp in future.
     *   - `v`, `r` and `s` must be valid `secp256k1` signature from `owner` account over 
     *      EIP712-formatted function arguments.
     *   - the signature must use `owner` account's current nonce (see {nonces}).
     *   - the signer cannot be zero address and must be `owner` account.
     * For more information on signature format, see 
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s
    ) external;
    
    /**
     * @dev Same as permit, but also performs a transfer
     */
    function transferWithPermit(
        address owner,
        address to,
        uint256 value,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

/**
 * @dev For more information on transferAndCall format, see https://github.com/ethereum/EIPs/issues/677
 */
interface IERC677 {
    /**
     * @dev Sets `value` as allowance of `spender` account over caller account's AnyswapV3ERC20 token,
     * after which a call is executed to an ERC677-compliant contract with the `data` parameter.
     * Emits {Approval} event.
     * Returns boolean value indicating whether operation succeeded.
     * For more information on approveAndCall format, see https://github.com/ethereum/EIPs/issues/677.
     */
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Moves `value` AnyswapV3ERC20 token from caller's account to account (`to`),
     * after which a call is executed to an ERC677-compliant contract with the `data` parameter.
     * A transfer to `address(0)` triggers an ETH withdraw matching the sent AnyswapV3ERC20 token in favor of caller.
     * Emits {Transfer} event.
     * Returns boolean value indicating whether operation succeeded.
     * Requirements:
     *   - caller account must have at least `value` AnyswapV3ERC20 token.
     * For more information on transferAndCall format, see https://github.com/ethereum/EIPs/issues/677.
     */
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);
}