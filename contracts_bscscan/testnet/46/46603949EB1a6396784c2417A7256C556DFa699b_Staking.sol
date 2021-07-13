// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IToken.sol";
import "./interfaces/IDistributionVault.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract Staking is ContextUpgradeable, AccessControlUpgradeable, PausableUpgradeable{
    bytes32 private constant _PAUSER_ROLE = keccak256("PAUSER_ROLE");

    IDistributionVault public vault;
    IToken public token;
    uint public endBlock;

    // Info of each level
    struct LevelInfo{
        address[] stakers;
        uint256 divider;
        uint256 accRewardsPerStaker;
        uint256 lastUpdateBlock;
        uint256 min;
    }

    // Info of each user
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    uint256 public levels; // Number of levels

    mapping(address=>UserInfo) private _userInfo; // Users info mapping
    mapping(uint256=>LevelInfo) private _levelInfo; // Levels info mapping

    uint256 public rewardPerBlock; // Reward per block

    event Deposit(address account, uint256 amount, uint256 level);
    event Withdraw(address account, uint256 amount, uint256 level);
    event Rewards(address account, uint256 rewards);

    //////////////////////
    //INTERNAL FUNCTIONS//
    //////////////////////

    // Initializes a level
    function _initLevel(uint256 lid, uint256 divider, uint256 min) internal{
        require(_levelInfo[lid].stakers.length == 0, "Staking: still stakers on this level");
        address[] memory _stakers;
        _levelInfo[lid] = LevelInfo(_stakers,divider,0,block.number,min);
    }

    // Updates a level
    function _updateLevel(uint256 lid) internal{

        LevelInfo storage level = _levelInfo[lid];

        if (block.number <= level.lastUpdateBlock) {
            return;
        }

        uint256 blocks = _blocks(lid);
        uint256 levelReward = (blocks*rewardPerBlock*level.divider)/100;

        if(level.stakers.length > 0){
            level.accRewardsPerStaker = level.accRewardsPerStaker + (levelReward/level.stakers.length);
        }

        level.lastUpdateBlock += blocks;
    }

    // Gets level from the amount in staking (_value)
    function _level(uint256 value) internal view returns(uint256){
        for(uint256 i=levels-1;i>0;i--){
            if(_levelInfo[i].min <= value){
                return i;
           }
        }
        return 0;
    }

    // Gets blocks from last update to the current block
    function _blocks(uint256 lid) internal view returns(uint256){
      if (block.number < endBlock){
        return block.number - _levelInfo[lid].lastUpdateBlock;
      }else{
        return endBlock - _levelInfo[lid].lastUpdateBlock;
      }
    }

    // Gets position of a user in the level stakers array
    function _stakerPos(address user, uint256 lid) internal view returns (bool,uint256){
        LevelInfo storage level = _levelInfo[lid];

        for(uint256 i = 0;i<level.stakers.length;i++){
            if(level.stakers[i] == user){
                return(true, i);
            }
        }
        return(false,0);
    }

    // Removes a user from the level stakers array
    function _removeStaker(address user, uint256 lid) internal{
        (bool inArray,uint256 pos) = _stakerPos(user, lid);

        if(inArray){
            _levelInfo[lid].stakers[pos] = _levelInfo[lid].stakers[_levelInfo[lid].stakers.length-1];
            _levelInfo[lid].stakers.pop();
        }
    }

    // Checks if uint256 array is sorted
    function _isSorted(uint256[] memory array) internal pure returns(bool){
        for(uint256 i=1; i<array.length;i++){
            if(array[i]<array[i-1]){
                return false;
            }
        }
        return true;
    }

    //////////////////////
    //EXTERNAL FUNCTIONS//
    //////////////////////

    // Changes divider of a level
    function changeDivider(uint lid, uint256 divider) external onlyRole(DEFAULT_ADMIN_ROLE){
        require(divider<=100, "Staking: divider cannot be greater than 100");
        _levelInfo[lid].divider = divider;
    }

    // User claims rewards
    function claim() external whenNotPaused {
        UserInfo storage user = _userInfo[_msgSender()];
        uint256 lid = _level(user.amount);

        _updateLevel(lid);

        uint256 rewards = _levelInfo[lid].accRewardsPerStaker - user.rewardDebt;
        require(rewards>0, "Staking: there is nothing to claim");

        user.rewardDebt = _levelInfo[lid].accRewardsPerStaker;
        vault.distributeTokens(_msgSender(), rewards);
        emit Rewards(_msgSender(), rewards);
    }

    // User deposits tokens
    function deposit(uint256 amount) external whenNotPaused {
        require(block.number < endBlock, "Staking: cannot deposit because ending block is reached");
        require(amount > 0, "Staking: amount must be over zero");
        require(token.balanceOf(_msgSender())>= amount, "Staking: user has not enough balance");
        require(token.allowance(_msgSender(), address(this))>= amount, "Staking: amount is bigger than allowance");
        UserInfo storage user = _userInfo[_msgSender()];

        uint256 lid = _level(user.amount);
        _updateLevel(lid);
        uint256 rewards = _levelInfo[lid].accRewardsPerStaker - user.rewardDebt;
        _removeStaker(_msgSender(), lid);
        user.amount += amount;
        lid = _level(user.amount);
        _updateLevel(lid);
        _levelInfo[lid].stakers.push(_msgSender());
        user.rewardDebt = _levelInfo[lid].accRewardsPerStaker;

        if(rewards > 0){
            vault.distributeTokens(_msgSender(), rewards);
            emit Rewards(_msgSender(), rewards);
        }

        require(token.transferFrom(_msgSender(),address(this), amount), "Staking: Transfer failed");
        emit Deposit(_msgSender(), user.amount, lid);
    }

    // User withdraws tokens
    function withdraw(uint256 amount) public whenNotPaused {
        require(amount > 0, "Staking: amount must be over zero");
        UserInfo storage user = _userInfo[_msgSender()];
        uint256 lid = _level(user.amount);
        require(amount <= user.amount,"Staking: amount is bigger than user staking balance");

        _updateLevel(lid);
        uint256 rewards = _levelInfo[lid].accRewardsPerStaker - user.rewardDebt;
        _removeStaker(_msgSender(), lid);
        user.amount -= amount;
        lid = _level(user.amount);
        _updateLevel(lid);
        _levelInfo[lid].stakers.push(_msgSender());
        user.rewardDebt = _levelInfo[lid].accRewardsPerStaker;

        if(rewards > 0){
            vault.distributeTokens(_msgSender(), rewards);
            emit Rewards(_msgSender(), rewards);
        }

        require(token.transfer(_msgSender(), amount), "Staking: Transfer failed");
        emit Withdraw(_msgSender(), user.amount, lid);
    }
    // User withdraw all tokens
    function withdrawAll() public {
      withdraw(getUserBalance(msg.sender));
    }
    // Gets user pending rewards
    function pendingRewards(address user_) public view returns(uint256) {
        UserInfo memory user = _userInfo[user_];
        if(user.amount < _levelInfo[1].min){
            return 0;
        }
        uint256 lid = _level(user.amount);
        LevelInfo storage level = _levelInfo[lid];

        uint256 levelReward = (_blocks(lid)*rewardPerBlock*level.divider)/100;

        return level.accRewardsPerStaker + (levelReward/level.stakers.length) - user.rewardDebt;
    }
    // Gets total supplied tokens
    function totalSupply() public view returns(uint256){
      return token.balanceOf(address(this));
    }
    // Gets user staking balance
    function getUserBalance(address user_) public view returns(uint256){
        UserInfo memory user = _userInfo[user_];
        return user.amount;
    }

    // Gets user level
    function getUserLevel(address user_) public view returns(uint256){
        UserInfo memory user = _userInfo[user_];
        return _level(user.amount);
    }

    // Gets total stakers
    function getTotalStakers() public view returns(uint256){
      uint256 total = 0;
      for(uint256 i=0;i<levels;i++){
        total += _levelInfo[i].stakers.length;
      }
      return total;
    }

    // Gets amount staked by level
    function getLevelBalance(uint256 lid) public view returns (uint256){
      uint256 balance = 0;
      LevelInfo memory level = _levelInfo[lid];

      for(uint256 i = 0; i < level.stakers.length;i++){
        balance += getUserBalance(level.stakers[i]);
      }
      return balance;
    }

    // Gets number of stakers by level
    function getLevelStakers(uint256 lid) public view returns (uint256){
      return _levelInfo[lid].stakers.length;
    }

    function getLevelInfo(uint lid) public view returns(LevelInfo memory){
      return _levelInfo[lid];
    }

    function grantPauserRole(address pauserAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
      grantRole(_PAUSER_ROLE, pauserAddress);
    }

    function pause() public {
      require(hasRole(_PAUSER_ROLE, _msgSender()), "Staking: must have pauser role to pause");
      _pause();
    }

    function unpause() public {
      require(hasRole(_PAUSER_ROLE, _msgSender()), "Staking: must have pauser role to unpause");
      _unpause();
    }

    function initialize(IDistributionVault vault_, uint256[] memory divider, uint256[] memory min) public {
      __Staking_init(vault_, divider, min);
    }

    function __Staking_init(IDistributionVault vault_, uint256[] memory divider, uint256[] memory min) internal initializer {
      __Context_init_unchained();
      __AccessControl_init_unchained();
      __Pausable_init_unchained();
      __Staking_init_unchained(vault_, divider, min);
    }

    // Initialize staking contract
    function __Staking_init_unchained(IDistributionVault vault_, uint256[] memory divider, uint256[] memory min) internal initializer {
        require(divider.length == min.length, "Staking: arrays must be the same length");
        require(divider.length > 0, "Staking: arrays could not be empty");
        require(_isSorted(min), "Staking: level minimum amounts array must be sorted");
        require(vault_.isStakeholder(address(this)), "Staking: this address is not a valid vault stakeholder");

        vault = vault_;
        token = vault.token();
        rewardPerBlock = vault.releasePerBlock(address(this));
        endBlock = vault.endBlock(address(this));

        _initLevel(0, 0, 0);

        for(uint256 i=1;i<divider.length+1;i++){
            _initLevel(i, divider[i-1], min[i-1]);
        }
        levels = divider.length + 1;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(_PAUSER_ROLE, _msgSender());
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IToken {
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


    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function hasRole(bytes32 role, address account) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./IToken.sol";

interface IDistributionVault {
    function token() external view returns(IToken);
    function distributeTokens(address addr_, uint256 amount_) external;
    function claim() external;
    function allocated(address addr_) external view returns(uint256);
    function released(address addr_) external view returns(uint256);
    function distributed(address addr_) external view returns(uint256);
    function releasePerBlock(address addr_) external view returns(uint256);
    function startBlock(address addr_) external view returns(uint);
    function endBlock(address addr_) external view returns(uint);
    function lastUpdate(address addr_) external view returns(uint);
    function available(address addr_) external view returns(uint256);
    function isStakeholder(address addr_) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                StringsUpgradeable.toHexString(uint160(account), 20),
                " is missing role ",
                StringsUpgradeable.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
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
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}