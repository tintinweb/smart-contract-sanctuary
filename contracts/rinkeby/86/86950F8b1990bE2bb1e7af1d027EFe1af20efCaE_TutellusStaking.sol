// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./utils/AccessControlProxyPausable.sol";
import "./interfaces/ITutellusERC20.sol";
import "./interfaces/ITutellusRewardsVault.sol";

contract TutellusStaking is AccessControlProxyPausable {

    address public token;
    address public vault;

    bool public autoreward;

    uint256 public balance;
    uint256 public minFee;
    uint256 public maxFee;
    uint256 public accRewardsPerShare;
    uint256 private _released;

    uint public lastUpdate;
    uint public feeInterval;
    uint public stakers;

    struct UserInfo {
      uint256 amount;
      uint256 rewardDebt;
      uint256 notClaimed;
      uint endInterval;
      uint256 minFee;
      uint256 maxFee;
      uint256 feeInterval;
    }

    mapping(address=>UserInfo) private _userInfo;

    event Claim(address account);
    event Deposit(address account, uint256 amount);
    event Withdraw(address account, uint256 amount, uint256 burned);
    event Rewards(address account, uint256 amount);

    event SyncBalance(address account, uint256 amount);
    event ToggleAutoreward(bool autoreward);
    event Update(uint256 balance, uint256 accRewardsPerShare, uint lastUpdate, uint stakers);
    event UpdateUserInfo(address account, uint256 amount, uint256 rewardDebt, uint256 notClaimed, uint endInterval);
    event SetFees(uint256 minFee, uint256 maxFee);
    event SetFeeInterval(uint feeInterval);
    event Migrate(address from, address to, address account, uint256 amount, bytes response);

    function _update() internal {
      if (block.number <= lastUpdate) {
        return;
      }
      ITutellusRewardsVault rewardsInterface = ITutellusRewardsVault(vault);
      uint256 released = rewardsInterface.releasedId(address(this)) - _released;
      _released += released;
      if(balance > 0) {
        accRewardsPerShare += (released * 1e18 / balance);
      }
      lastUpdate = block.number;
    }

    // Sets maximum and minimum fees
    function setFees(uint256 minFee_, uint256 maxFee_) public onlyRole(DEFAULT_ADMIN_ROLE) {
      require(minFee_ <= maxFee_, "TutellusStaking: mininum fee must be greater or equal than maximum fee");
      require(minFee_ <= 1e20 && maxFee_ <= 1e20, "TutellusStaking: fees must be less than 100e18");
      minFee = minFee_;
      maxFee = maxFee_;
      emit SetFees(minFee, maxFee);
    }

    // Sets fee interval (blocks) for staking
    function setFeeInterval(uint feeInterval_) public onlyRole(DEFAULT_ADMIN_ROLE) {
      feeInterval = feeInterval_;
      emit SetFeeInterval(feeInterval);
    }

    // Updates rewards for an account
    function _updateRewards(address account) internal {
      UserInfo storage user = _userInfo[account];
      uint256 diff = accRewardsPerShare - user.rewardDebt;
      user.notClaimed = diff * user.amount / 1e18;
      user.rewardDebt = accRewardsPerShare;
    }

    // Deposits tokens for staking
    function depositFrom(address account, uint256 amount) public whenNotPaused {
      require(amount > 0, "TutellusStaking: amount must be over zero");

      UserInfo storage user = _userInfo[account];

      _update();
      _updateRewards(account);

      if(user.amount == 0) {
        stakers += 1;
      }

      user.endInterval = block.number + feeInterval;
      user.minFee = minFee;
      user.maxFee = maxFee;
      user.feeInterval = feeInterval;
      user.amount += amount;
      balance += amount;

      ITutellusERC20 tokenInterface = ITutellusERC20(token);

      require(tokenInterface.balanceOf(account) >= amount, "TutellusStaking: user has not enough balance");
      require(tokenInterface.allowance(account, address(this)) >= amount, "TutellusStaking: amount exceeds allowance");

      if(autoreward) {
        _reward(account);
      }

      require(tokenInterface.transferFrom(account, address(this), amount), "TutellusStaking: deposit transfer failed");

      emit Update(balance, accRewardsPerShare, lastUpdate, stakers);
      emit UpdateUserInfo(account, user.amount, user.rewardDebt, user.notClaimed, user.endInterval);
      emit Deposit(account, amount);
    }

    // Withdraws tokens from staking
    function withdraw(uint256 amount) public whenNotPaused returns (uint256) {
      require(amount > 0, "TutellusStaking: amount must be over zero");

      address account = msg.sender;
      UserInfo storage user = _userInfo[account];

      require(amount <= user.amount, "TutellusStaking: user has not enough staking balance");

      _update();
      _updateRewards(account);

      user.rewardDebt = accRewardsPerShare;
      user.amount -= amount;
      balance -= amount;

      if(user.amount == 0) {
        stakers -= 1;
      }

      ITutellusERC20 tokenInterface = ITutellusERC20(token);

      uint256 burned = amount * getFee(account) / 1e20;
      amount -= burned;

      if(autoreward) {
        _reward(account);
      }
      if(burned > 0){
        tokenInterface.burn(burned);
      }
      require(tokenInterface.transfer(account, amount), "TutellusStaking: withdraw transfer failed");

      emit Update(balance, accRewardsPerShare, lastUpdate, stakers);
      emit UpdateUserInfo(account, user.amount, user.rewardDebt, user.notClaimed, user.endInterval);
      emit Withdraw(account, amount, burned);
      return amount;
    }

    // Claims rewards
    function claim() public whenNotPaused {
      address account = msg.sender;
      UserInfo storage user = _userInfo[account];

      _update();
      _updateRewards(account);

      require(user.notClaimed > 0, "TutellusStaking: nothing to claim");

      _reward(account);

      emit Update(balance, accRewardsPerShare, lastUpdate, stakers);
      emit UpdateUserInfo(account, user.amount, user.rewardDebt, user.notClaimed, user.endInterval);
      emit Claim(account);
    }

    // Toggles autoreward
    function toggleAutoreward() public onlyRole(DEFAULT_ADMIN_ROLE) {
      autoreward = !autoreward;
      emit ToggleAutoreward(autoreward);
    }

    function _reward(address account) internal {
      ITutellusRewardsVault rewardsInterface = ITutellusRewardsVault(vault);
      uint256 amount = _userInfo[account].notClaimed;
      if(amount > 0) {
        _userInfo[account].notClaimed = 0;
        rewardsInterface.distributeTokens(account, amount);
        emit Rewards(account, amount);
      }
    }

    // Gets current fee for a user
    function getFee(address account) public view returns(uint256) {
      UserInfo memory user = _userInfo[account];
      uint256 fee = block.number < user.endInterval ? user.feeInterval > 0 ? user.maxFee * (user.endInterval - block.number) / user.feeInterval : user.minFee : user.minFee;
      return fee > user.minFee ? fee : user.minFee;
    }

    // Gets blocks until endInverval
    function getBlocksLeft(address account) public view returns (uint) {
      if(block.number > _userInfo[account].endInterval) {
        return 0;
      } else {
        return _userInfo[account].endInterval - block.number;
      }
    }

    // Gets user pending rewards
    function pendingRewards(address user_) public view returns(uint256) {
        UserInfo memory user = _userInfo[user_];
        uint256 rewards = user.notClaimed;
        if(balance > 0){
          ITutellusRewardsVault rewardsInterface = ITutellusRewardsVault(vault);
          uint256 released = rewardsInterface.releasedId(address(this)) - _released;
          uint256 total = (released * 1e18 / balance);
          rewards += (accRewardsPerShare - user.rewardDebt + total) * user.amount / 1e18;
        }
        return rewards;
    }

    constructor (address token_, address rolemanager, address vault_, uint256 minFee_, uint256 maxFee_, uint feeInterval_) {
      __TutellusStaking_init(token_, rolemanager, vault_, minFee_, maxFee_, feeInterval_);
    }

    function __TutellusStaking_init(address token_, address rolemanager, address vault_, uint256 minFee_, uint256 maxFee_, uint feeInterval_) internal initializer {
      __AccessControlProxyPausable_init(rolemanager);
      __TutellusStaking_init_unchained(token_, vault_, minFee_, maxFee_, feeInterval_);
    }

    function __TutellusStaking_init_unchained(address token_, address vault_, uint256 minFee_, uint256 maxFee_, uint feeInterval_) internal initializer {
      token = token_;
      vault = vault_;
      setFees(minFee_, maxFee_);
      setFeeInterval(feeInterval_);
      autoreward = true;
      lastUpdate = block.number;
    }

        // Gets token gap
    function getTokenGap() public view returns (uint256) {
      ITutellusERC20 tokenInterface = ITutellusERC20(token);
      uint256 tokenBalance = tokenInterface.balanceOf(address(this));
      return tokenBalance - balance;
    }

        // Synchronizes balance, transfering the gap to an external account
    function syncBalance(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
      ITutellusERC20 tokenInterface = ITutellusERC20(token);
      uint256 gap = getTokenGap();
      require(gap > 0, "TutellusStaking: there is no gap");
      tokenInterface.transfer(account, gap);
      emit SyncBalance(account, gap);
    }

        // Gets user staking balance
    function getUserBalance(address user_) public view returns(uint256){
      UserInfo memory user = _userInfo[user_];
      return user.amount;
    }

    function migrate(address to) public returns (bytes memory){
      address account = msg.sender;
      uint256 amount = withdraw(_userInfo[account].amount);
      (bool success, bytes memory response) = to.call(
            abi.encodeWithSignature("depositFrom(address,uint256)", account, amount)
        );
      require(success, 'TutellusStaking: migration failed');
      emit Migrate(address(this), to, account, amount, response);
      return response;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

abstract contract AccessControlProxyPausable is PausableUpgradeable {

    address private _manager;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    modifier onlyRole(bytes32 role) {
        address account = msg.sender;
        require(hasRole(role, account), string(
                    abi.encodePacked(
                        "AccessControlProxyPausable: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                ));
        _;
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        IAccessControlUpgradeable manager = IAccessControlUpgradeable(_manager);
        return manager.hasRole(role, account);
    }

    function __AccessControlProxyPausable_init(address manager) internal initializer {
        __Pausable_init();
        __AccessControlProxyPausable_init_unchained(manager);
    }

    function __AccessControlProxyPausable_init_unchained(address manager) internal initializer {
        _manager = manager;
    }

    function pause() public onlyRole(PAUSER_ROLE){
        _pause();
    }
    
    function unpause() public onlyRole(PAUSER_ROLE){
        _unpause();
    }

    function updateManager(address manager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _manager = manager;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ITutellusERC20 {

    /**
     * @dev Returns the amount of tokens burned.
     */
    function burned() external view returns (uint256);
    
    /**
     * @dev Mints `amount` tokens to `account`.
     */
    function mint(address account, uint256 amount) external;

    /**
     * @dev Burns `amount` tokens.
     */
    function burn(uint256 amount) external;

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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ITutellusRewardsVault {

    function add(address account, uint256[] memory allocation) external;

    function updateAllocation(uint256[] memory allocation) external;

    function released() external view returns (uint256);

    function availableId(address account) external view returns (uint256);

    function releasedRange(uint from, uint to) external view returns (uint256);

    function releasedId(address account) external view returns (uint256);

    function distributeTokens(address account, uint256 amount) external;

    function info(address account) external view;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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