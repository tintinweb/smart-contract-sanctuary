// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract DataBankIFA is OwnableUpgradeable, PausableUpgradeable {
    address public _arxToken;
    uint8 public _usageFee;
    uint256 public _lockDuration;

    mapping(address => Deposit[]) private _deposited;
    mapping(address => bool) private _isAutoDeposit;
    mapping(address => uint256) private _withdrawable;
    mapping(address => uint256) private _profit;
    address public _vault;

    struct Deposit {
        uint256 amount;
        uint256 unlockTime;
    }

    struct Balance {
        uint256 deposited;
        uint256 withdrawable;
        uint256 profit;
    }

    event Deposited(
        address indexed account,
        uint256 amount,
        uint256 unlockTime,
        Balance balance
    );

    event AutoDepositEnabled(address indexed account);

    event AutoDepositDisabled(address indexed account);

    event Withdrawn(address indexed account, uint256 amount, Balance balance);

    event OfferAccepted(
        address indexed seller,
        uint256 amount,
        uint256 offerId,
        Balance balance
    );

    event UsageFeeChanged(uint8 oldUsageFee, uint8 newUsageFee);

    event LockDurationChanged(uint256 oldLockDuration, uint256 newLockDuration);

    /**
     * @dev Initializer function.
     * @param arxToken The ARX token contract address.
     */
    function initialize(
        address arxToken,
        uint8 usageFee,
        uint256 lockDuration,
        address vault
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        _arxToken = arxToken;
        _usageFee = usageFee;
        _lockDuration = lockDuration;
        _vault = vault;
    }

    /**
     * @dev Deposit tokens.
     * @param amount The amount of tokens to be deposited.
     */
    function deposit(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");

        IERC20Upgradeable(_arxToken).transferFrom(
            _msgSender(),
            address(this),
            amount
        );
        uint256 unlockTime = block.timestamp + _lockDuration;
        _deposited[_msgSender()].push(Deposit(amount, unlockTime));

        emit Deposited(
            _msgSender(),
            amount,
            unlockTime,
            _balance(_msgSender())
        );
    }

    function enableAutoDeposit() external whenNotPaused {
        _makeWithdrawable(_msgSender());

        _isAutoDeposit[_msgSender()] = true;

        emit AutoDepositEnabled(_msgSender());
    }

    function disableAutoDeposit() external whenNotPaused {
        uint256 depositCount = _deposited[_msgSender()].length;

        for (uint256 i = 0; i < depositCount; i++) {
            if (_deposited[_msgSender()][i].unlockTime < block.timestamp) {
                uint256 periodCount = (block.timestamp -
                    _deposited[_msgSender()][i].unlockTime) /
                    _lockDuration +
                    1;

                _deposited[_msgSender()][i].unlockTime += (periodCount *
                    _lockDuration);
            }
        }

        _isAutoDeposit[_msgSender()] = false;

        emit AutoDepositDisabled(_msgSender());
    }

    function _makeWithdrawable(address user) private {
        uint256 withdrawable = 0;
        uint256 currentIndex = 0;
        uint256 depositCount = _deposited[user].length;

        for (uint256 i = 0; i < depositCount; i++) {
            if (_deposited[user][currentIndex].unlockTime <= block.timestamp) {
                withdrawable += _deposited[user][currentIndex].amount;
                _deposited[user][currentIndex] = _deposited[user][
                    _deposited[user].length - 1
                ];
                _deposited[user].pop();
            } else {
                currentIndex++;
            }
        }

        _withdrawable[user] += withdrawable;
    }

    /**
     * @dev Check and unlock expired deposits, then withdraw tokens.
     * @param amount The amount of tokens to be withdrawn.
     */
    function withdraw(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");

        // Skip if auto-deposit is enable
        if (!_isAutoDeposit[_msgSender()]) {
            _makeWithdrawable(_msgSender());
        }

        require(
            amount <= _withdrawable[_msgSender()] + _profit[_msgSender()],
            "Amount must not be greater than balance"
        );

        if (amount > _profit[_msgSender()]) {
            _withdrawable[_msgSender()] -= (amount - _profit[_msgSender()]);
            _profit[_msgSender()] = 0;
        } else {
            _profit[_msgSender()] = _profit[_msgSender()] - amount;
        }

        IERC20Upgradeable(_arxToken).transfer(_msgSender(), amount);

        emit Withdrawn(_msgSender(), amount, _balance(_msgSender()));
    }

    /**
     * @dev Accept an offer and pay for it as a buyer.
     * @param seller The seller address.
     * @param amount The amount of tokens to be paid.
     * @param offerId The order ID.
     */
    function acceptOffer(
        address seller,
        uint256 amount,
        uint256 offerId
    ) external whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");

        IERC20Upgradeable(_arxToken).transferFrom(
            _msgSender(),
            address(this),
            amount
        );
        IERC20Upgradeable(_arxToken).transferFrom(
            _msgSender(),
            _vault,
            (amount * _usageFee) / 100
        );

        _profit[seller] += amount;

        emit OfferAccepted(seller, amount, offerId, _balance(seller));
    }

    /**
     * @dev Calculate and return user balance information in the contract.
     * @param user The user address.
     * @return Balance The user balance information.
     */
    function _balance(address user) private view returns (Balance memory) {
        uint256 deposited = 0;
        uint256 withdrawable = 0;

        for (uint256 i = 0; i < _deposited[user].length; i++) {
            if (
                _deposited[user][i].unlockTime <= block.timestamp &&
                !_isAutoDeposit[user]
            ) {
                withdrawable += _deposited[user][i].amount;
            } else {
                deposited += _deposited[user][i].amount;
            }
        }

        return
            Balance(
                deposited,
                withdrawable + _withdrawable[user],
                _profit[user]
            );
    }

    /**
     * See {_balance}.
     * @return d The deposited amount.
     * @return w The withdrawble amount.
     * @return p The profit amount.
     * @return c The deposit count.
     * @return a Auto-deposit status.
     */
    function infoWallet(address user)
        external
        view
        returns (
            uint256 d,
            uint256 w,
            uint256 p,
            uint256 c,
            bool a
        )
    {
        Balance memory balance = _balance(user);

        return (
            balance.deposited,
            balance.withdrawable,
            balance.profit,
            _deposited[user].length,
            _isAutoDeposit[user]
        );
    }

    /**
     * TBA
     * @return a The deposited amount.
     * @return u The unlock time.
     */
    function infoDeposit(address user, uint256 index)
        external
        view
        returns (uint256 a, uint256 u)
    {
        return (
            _deposited[user][index].amount,
            _deposited[user][index].unlockTime
        );
    }

    /**
     * @dev Update the usage fee.
     * @param usageFee The new usage fee.
     */
    function setUsageFee(uint8 usageFee) external onlyOwner {
        emit UsageFeeChanged(_usageFee, usageFee);
        _usageFee = usageFee;
    }

    /**
     * @dev Update the lock duration.
     * @param lockDuration The new lock duration.
     */
    function setLockDuration(uint256 lockDuration) external onlyOwner {
        emit LockDurationChanged(_lockDuration, lockDuration);
        _lockDuration = lockDuration;
    }

    function setVault(address vault) external onlyOwner {
        _vault = vault;
    }

    /**
     * @dev Pause the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Transfer token from the contract.
     * @param token The token contract address.
     * @param amount The amount of tokens to be transferred.
     * @param to The token recipient.
     */
    function transferToken(
        address token,
        uint256 amount,
        address to
    ) public onlyOwner {
        IERC20Upgradeable(token).transfer(to, amount);
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

// SPDX-License-Identifier: MIT

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