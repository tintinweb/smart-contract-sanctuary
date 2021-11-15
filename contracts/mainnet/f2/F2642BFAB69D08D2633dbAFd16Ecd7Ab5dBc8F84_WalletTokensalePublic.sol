// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "openzeppelin-solidity/contracts/access/AccessControl.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/cryptography/ECDSA.sol";
import {vcUSDPool} from "contracts/Pool/vcUSDPool.sol";

contract WalletTokensalePublic is AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SERVICE_ROLE = keccak256("SERVICE_ROLE");

    uint256 public constant AMOUNT_USD = 500000000;

    uint256 public totalAmount;
    uint256 public totalSold;

    uint256 public maxAmountToBuy;

    /// @dev address of main token
    address public govTokenAddress;
    address public USDTAddress;
    uint256 public factor = 10**12;
    uint256 public USDTReceived;
    uint256 public USDTClaimed;

    /// @dev for example: 100000 = 0.01 USD
    uint256 public rate;
    uint256 public ratesPrecision = 10**7;

    address public vcUSDPoolAddress;

    uint256 currentLockNumber = 0;
    /// @dev true = swap unlocked, false = swap locked
    bool public swapUnlocked = true;

    /// @dev true = claim unlocked, false = locked
    bool public claimUnlocked = false;
    /// @dev struct of lock tokens
    struct Lock {
        uint256 unlockDate;
        uint256 percent;
    }
    /// @dev array of locks tokens
    Lock[] public locks;

    struct UserInfo {
        uint256 amount;
        uint256 claimed;
    }

    mapping(address => UserInfo) public users;

    mapping(bytes32 => bool) hashes;
    uint256 public swapsCount;

    event TokenExchanged(
        address indexed spender,
        uint256 usdAmount,
        uint256 daovcAmount,
        uint256 time,
        string userId
    );
    event TokenExchangedFiat(
        address indexed spender,
        uint256 amount,
        uint256 daovcAmount,
        uint256 time
    );
    event TokensClaimed(
        address indexed claimer,
        uint256 amountClaimed,
        uint256 time
    );

    event RoundStateChanged(bool state, uint256 time);

    modifier roundUnlocked() {
        require(swapUnlocked, "Round is locked!");
        _;
    }

    modifier claimUnlockedModifier() {
        require(claimUnlocked, "Round is locked!");
        _;
    }

    /**
     * @dev Constructor of Wallet
     * @param _govTokenAddress address of main token
     * @param _USDTAddress address of USDT token
     * @param _rate rate value
     * @param _totalAmount total amount of tokens
     * @param _maxAmountToBuy max amount ot buy in usdt
     * @param _vcUSDPoolAddress vc usd pool address
     * @param _usdtReceived initial value of received usdt
     * @param _usdtClaimed initial value of claimed usdt
     */
    constructor(
        address _govTokenAddress,
        address _USDTAddress,
        uint256 _rate,
        uint256 _totalAmount,
        uint256 _maxAmountToBuy,
        address _vcUSDPoolAddress,
        uint256 _usdtReceived,
        uint256 _usdtClaimed
    ) public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);

        govTokenAddress = _govTokenAddress;
        USDTAddress = _USDTAddress;
        rate = _rate;
        totalAmount = _totalAmount;
        maxAmountToBuy = _maxAmountToBuy;
        vcUSDPoolAddress = _vcUSDPoolAddress;
        USDTClaimed = _usdtClaimed;
        USDTReceived = _usdtReceived;
    }

    /**
     * @dev set round state
     * @param _state state of round
     */
    function setRoundState(bool _state) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        swapUnlocked = _state;
        emit RoundStateChanged(_state, block.timestamp);
    }

    /**
     * @dev add the token to Lock pull
     * @param _unlockDate date of token unlock
     * @param _percent percent of unlocked token
     */
    function addLock(uint256[] memory _unlockDate, uint256[] memory _percent)
        external
    {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(
            _unlockDate.length == _percent.length,
            "unlockDate array and percent arrays must have same values"
        );

        for (uint256 i = 0; i < _unlockDate.length; i++) {
            locks.push(
                Lock({percent: _percent[i], unlockDate: _unlockDate[i]})
            );
        }
    }

    /**
     * @dev swap usdt to daoVC gov token
     * @param hashedMessage hash of transaction data
     * @param _sequence transaction number
     * @param _v v of hash signature
     * @param _r r of hash signature
     * @param _s s of hash signature
     */
    function swap(
        bytes32 hashedMessage,
        string memory _userId,
        uint256 _sequence,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external roundUnlocked {
        address service = ECDSA.recover(hashedMessage, _v, _r, _s);
        require(hasRole(SERVICE_ROLE, service), "Signed not by a service");

        bytes32 message = ECDSA.toEthSignedMessageHash(
            keccak256(abi.encodePacked(_userId, _sequence))
        );

        require(hashedMessage == message, "Incorrect hashed message");
        require(
            !hashes[message],
            "Sequence amount already claimed or dublicated"
        );
        hashes[message] = true;
        swapsCount++;

        UserInfo storage user = users[msg.sender];

        uint256 amountInGov = AMOUNT_USD.mul(factor).mul(ratesPrecision).div(
            rate
        );
        require(
            user.amount.add(amountInGov) <= maxAmountToBuy,
            "You cannot swap more tokens"
        );

        require(
            totalSold.add(amountInGov) <= totalAmount,
            "All tokens was sold"
        );

        ERC20(USDTAddress).safeTransferFrom(
            msg.sender,
            address(this),
            AMOUNT_USD
        );

        USDTReceived = USDTReceived.add(AMOUNT_USD);
        user.amount = user.amount.add(amountInGov);
        totalSold = totalSold.add(amountInGov);

        emit TokenExchanged(
            msg.sender,
            AMOUNT_USD,
            amountInGov,
            block.timestamp,
            _userId
        );
    }

    /**
     * @dev swap fiat to daoVC gov token
     * @param _user  user's address
     */
    function swapBackend(address _user) external roundUnlocked {
        require(
            hasRole(SERVICE_ROLE, msg.sender),
            "Caller does not have the service role"
        );
        UserInfo storage user = users[_user];

        uint256 amountInGov = AMOUNT_USD.mul(factor).mul(ratesPrecision).div(
            rate
        );
        require(
            user.amount.add(amountInGov) <= maxAmountToBuy,
            "You cannot swap more tokens"
        );

        require(
            totalSold.add(amountInGov) <= totalAmount,
            "All tokens was sold"
        );

        swapsCount++;
        USDTReceived = USDTReceived.add(AMOUNT_USD);
        user.amount = user.amount.add(amountInGov);
        totalSold = totalSold.add(amountInGov);
        emit TokenExchangedFiat(_user, AMOUNT_USD, amountInGov, block.timestamp);
    }

    /**
     * @dev user claim's his availeble tokens
     */
    function claim() external nonReentrant claimUnlockedModifier {
        UserInfo storage user = users[msg.sender];
        require(user.amount > 0, "Nothing to claim");
        uint256 newLock = currentLockNumber;
        if (newLock <= locks.length - 2) {
            while (block.timestamp >= locks[newLock + 1].unlockDate) {
                newLock = newLock + 1;
                if (newLock == locks.length - 1) {
                    break;
                }
            }
            currentLockNumber = newLock;
        }

        uint256 availableAmount = calcAvailableAmount(msg.sender);

        require(availableAmount > 0, "There are not available tokens to claim");
        user.claimed = user.claimed.add(availableAmount);
        ERC20(govTokenAddress).safeTransfer(msg.sender, availableAmount);
        emit TokensClaimed(msg.sender, availableAmount, block.timestamp);
    }

    /**
     * @dev send USDT to vc usd pool
     */
    function sendUsdtToPool(uint256 _amount) external {
        require(
            hasRole(SERVICE_ROLE, msg.sender),
            "Caller does not have the service role"
        );

        ERC20(USDTAddress).safeTransfer(vcUSDPoolAddress, _amount);
        USDTClaimed = USDTClaimed.add(_amount);

        vcUSDPool(vcUSDPoolAddress).sellVcUsdBackend(_amount);
    }

    /**
     * @dev Caluclate available amount of tokens for user
     *  @param _user - address of user
     */
    function calcAvailableAmount(address _user)
        private
        view
        returns (uint256 availableToken)
    {
        UserInfo storage user = users[_user];

        availableToken = (
            user.amount.mul(locks[currentLockNumber].percent).div(100)
        );

        if (availableToken >= user.claimed) {
            availableToken = availableToken.sub(user.claimed);
        } else {
            availableToken = 0;
        }

        return availableToken;
    }

    /**
     * @dev get user info
     * @param _user address of user
     */
    function getUserInfo(address _user)
        external
        view
        returns (
            uint256 amount_,
            uint256 available_,
            uint256 claimed_,
            uint256 currentLockTime_
        )
    {
        UserInfo storage user = users[_user];

        uint256 newLock = currentLockNumber;
        if (newLock <= locks.length - 2) {
            while (block.timestamp >= locks[newLock + 1].unlockDate) {
                newLock = newLock + 1;
                if (newLock == locks.length - 1) {
                    break;
                }
            }
        }
        amount_ = user.amount;
        claimed_ = user.claimed;
        available_ = (user.amount.mul(locks[newLock].percent).div(100));

        if (available_ >= user.claimed) {
            available_ = available_.sub(user.claimed);
        } else {
            available_ = 0;
        }

        if (newLock == locks.length - 1) {
            currentLockTime_ = locks[newLock].unlockDate;
        } else {
            currentLockTime_ = locks[newLock + 1].unlockDate;
        }

        return (amount_, available_, claimed_, currentLockTime_);
    }

    /**
     * @dev get state of round
     */
    function getRoundState() external view returns (bool) {
        return swapUnlocked;
    }

    /**
     * @dev remove tokens from pool
     * @param _recepient address of recipient
     * @param _amount amount of tokens
     * @param tokenAddress address of token
     */
    function removeToken(
        address _recepient,
        uint256 _amount,
        address tokenAddress
    ) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");

        ERC20(tokenAddress).safeTransfer(_recepient, _amount);
    }

    /**
     * @dev update lock data
     * @param _index index of lock data
     * @param _percent percent value
     * @param _unlockDate date of unlock
     */
    function updateLock(
        uint256 _index,
        uint256 _percent,
        uint256 _unlockDate
    ) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        locks[_index].percent = _percent;
        locks[_index].unlockDate = _unlockDate;
    }

    /**
     * @dev update user info
     * @param _user address of user
     * @param _amount amount of tokens
     * @param _claimed amount of claimed tokens
     */
    function updateUserInfo(
        address _user,
        uint256 _amount,
        uint256 _claimed
    ) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        UserInfo storage user = users[_user];
        user.amount = _amount;
        user.claimed = _claimed;
    }

    /**
     * @dev set address of token
     * @param _govTokenAddress address of gov token
     */
    function updateTokenAddress(address _govTokenAddress) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        govTokenAddress = _govTokenAddress;
    }

    /** @dev claim usdt from this contract
     *  @param _usdtReceiver address, who gets USDT tokens
     */
    function claimUSDT(address _usdtReceiver) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(USDTReceived > 0, "Not enough USDT to claim");
        ERC20(USDTAddress).safeTransfer(
            _usdtReceiver,
            USDTReceived.sub(USDTClaimed)
        );
        USDTClaimed = USDTClaimed.add(USDTReceived.sub(USDTClaimed));
    }

    /**
     * @dev
     */
    function getInfoAboutUsdt()
        external
        view
        returns (uint256 USDTReceived_, uint256 USDTClaimed_)
    {
        USDTReceived_ = USDTReceived;
        USDTClaimed_ = USDTClaimed;
        return (USDTReceived_, USDTClaimed_);
    }

    /**
     * @dev returns current rate for contract
     */
    function getRate() external view returns (uint256) {
        return rate;
    }

    /**
     * @dev update rates
     * @param _rate rate, for example: 400000 = 0.04$
     */
    function updateRate(uint256 _rate) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        rate = _rate;
    }

    /**
     * @dev update vc usd pool address
     * @param _vcUSDPoolAddress address of vc usd pool
     */
    function updateVcUsdPoolAddress(address _vcUSDPoolAddress) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        vcUSDPoolAddress = _vcUSDPoolAddress;
    }

    /**
     * @dev update maximum amount to buy
     * @param _maxAmountToBuy maximum amount value
     */
    function updateMaximum(uint256 _maxAmountToBuy) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        maxAmountToBuy = _maxAmountToBuy;
    }

    /**
     * @dev update current lock number
     * @param _newCurrentLock new lock number
     */
    function updateCurrentLockNumber(uint256 _newCurrentLock) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        currentLockNumber = _newCurrentLock;
    }

    /**
     * @dev add users with info
     * @param _users users addresses array
     * @param _amounts amounts array
     * @param _claimed claimed amount array
     */
    function migrateUsers(
        address[] memory _users,
        uint256[] memory _amounts,
        uint256[] memory _claimed
    ) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(
            _users.length == _amounts.length,
            "Array users and amounts must be the same length"
        );
        require(
            _users.length == _claimed.length,
            "Array users and claimed must be the same length"
        );

        for (uint256 i = 0; i < _users.length; i++) {
            UserInfo storage user = users[_users[i]];
            user.amount = _amounts[i];
            user.claimed = _claimed[i];
        }
    }

    /**
     * @dev set state of claim
     * @param _state state of claim
     */
    function setClaimState(bool _state) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        claimUnlocked = _state;
    }

    /**
     * @dev set total amount of reward tokens
     * @param _totalAmount total amount value
     */
    function updateTotalAmount(uint256 _totalAmount) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        totalAmount = _totalAmount;
    }

    /**
     * @dev set total sold
     * @param _totalSold total sold amount
     */
    function updateTotalSold(uint256 _totalSold) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        totalSold = _totalSold;
    }

    /**
     * @dev set factor
     * @param _factor factor value
     */
    function updateFactor(uint256 _factor) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        factor = _factor;
    }

    /**
     * @dev set value of received USDT
     * @param _usdtReceived received USDT amount
     */
    function updateUSDTReceived(uint256 _usdtReceived) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        USDTReceived = _usdtReceived;
    }

    /**
     * @dev set value of claimed USDT
     * @param _usdtClaimed claimed USDT amount
     */
    function updateUSDTClaimed(uint256 _usdtClaimed) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        USDTClaimed = _usdtClaimed;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "openzeppelin-solidity/contracts/access/AccessControl.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "contracts/tokens/vcUSD.sol";
import {WalletTokensalePrivate} from "contracts/Wallets/WalletTokensalePrivate.sol";



contract vcUSDPool is AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SERVICE_ROLE = keccak256("SERVICE_ROLE");

    bool public saleUnlocked = true;
    bool public claimUnlocked = true;
    mapping(bytes32 => bool) hashes;

    address public vcUSDAddress;
    address public USDTAddress;
    address public service_backend;
    address public privateAddress;

    event vcUSDBuy(address indexed user, uint256 amount, uint256 time);
    event vcUSDSell(address indexed user, uint256 amount, uint256 time);
    event RefferalsClaimed(address indexed user, uint256 amount, uint256 time);

    constructor(
        address _USDTAddress,
        address _vcUSDAddress,
        address _service_backend
    ) public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);

        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(SERVICE_ROLE, ADMIN_ROLE);

        vcUSDAddress = _vcUSDAddress;
        USDTAddress = _USDTAddress;
        service_backend = _service_backend;
        _setupRole(SERVICE_ROLE, service_backend);
    }

    modifier refferalClaimUnlocked() {
        require(claimUnlocked, "Claim is locked");
        _;
    }

    modifier salesUnlocked() {
        require(saleUnlocked, "Sales is locked!");
        _;
    }

    function airdrop(address[] calldata _addresses, uint256[] calldata _amounts)
        external
    {
        require(hasRole(SERVICE_ROLE, msg.sender), "Caller is not an service");
        require(
            _addresses.length == _amounts.length,
            "Arrays must have the same length"
        );

        for (uint256 i = 0; i < _addresses.length; i++) {
            vcUSDToken(vcUSDAddress).mint(_addresses[i], _amounts[i]);
        }
    }

    function buyVcUSDBackend(uint256 _amount, address _recepient) external {
        require(hasRole(SERVICE_ROLE, msg.sender), "Caller is not an service");
        require(_amount > 0, "Amount must be above zero!");

        vcUSDToken(vcUSDAddress).burn(service_backend, _amount);

        ERC20(USDTAddress).safeTransfer(_recepient, _amount);

        emit vcUSDBuy(_recepient, _amount, block.timestamp);
    }

    function sellVcUsdBackend(uint256 _amount) external {
        require(hasRole(SERVICE_ROLE, msg.sender), "Caller is not an service");
        require(_amount > 0, "Amount must be above zero!");

        vcUSDToken(vcUSDAddress).mint(service_backend, _amount);

        emit vcUSDSell(service_backend, _amount, block.timestamp);
    }

    function buyVcUSD(uint256 _amount) external salesUnlocked nonReentrant {
        require(_amount > 0, "Amount must be above zero!");

        vcUSDToken(vcUSDAddress).burn(msg.sender, _amount);

        ERC20(USDTAddress).safeTransfer(msg.sender, _amount);

        emit vcUSDBuy(msg.sender, _amount, block.timestamp);
    }

    function sellVcUsd(uint256 _amount) external salesUnlocked nonReentrant {
        require(_amount > 0, "Amount must be above zero!");

        ERC20(USDTAddress).safeTransferFrom(msg.sender, address(this), _amount);

        vcUSDToken(vcUSDAddress).mint(msg.sender, _amount);

        emit vcUSDSell(msg.sender, _amount, block.timestamp);
    }

    function updateServiceAddress(address _service_backend) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");

        service_backend = _service_backend;
    }

    function updateSalesState(bool _state) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        saleUnlocked = _state;
    }

    function updateVcUSDAddress(address _vcUSDAddress) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        vcUSDAddress = _vcUSDAddress;
    }

    function claim(
        bytes32 hashedMessage,
        uint256 _amount,
        uint256 _sequence,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        address _from
    ) external nonReentrant  refferalClaimUnlocked  {
        address service = recover(hashedMessage, _v, _r, _s);
        require(hasRole(SERVICE_ROLE, service), "Signed not by a service");
        
        
        //TO-DO _form to msg.sender
        bytes32 message = keccak256(
            abi.encodePacked(msg.sender, _amount, _sequence)
        );

        message = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", message)
        );

        // return (message, service);
        
        require(hashedMessage == message, "Incorrect hashed message");

        require(
            !hashes[message],
            "Sequence amount already claimed or dublicated."
        );

        hashes[message] = true;

        WalletTokensalePrivate(_from).removeToken(
            msg.sender,
            _amount,
            USDTAddress
        );

        emit RefferalsClaimed(msg.sender, _amount, block.timestamp);

        
    }
    

    function removeToken(
        address _recepient,
        uint256 _amount,
        address tokenAddress
    ) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        
        ERC20(tokenAddress).safeTransfer(_recepient, _amount);
    }

    function updateClaimState(bool _state) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        claimUnlocked = _state;
    }


    function recover(
        bytes32 hashedMsg,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");
        address signer = ecrecover(hashedMsg, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");
        return signer;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
pragma solidity ^0.6.12;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/access/AccessControl.sol";

contract vcUSDToken is ERC20, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public ERC20(_name, _symbol) {
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        // Sets `DEFAULT_ADMIN_ROLE` as ``ADMIN_ROLE``'s admin role.
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setupDecimals(_decimals);
    }

    function mint(address to, uint256 amount) external {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not an minter");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not an burner");
        _burn(from, amount);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override(ERC20) {
        ERC20._beforeTokenTransfer(_from, _to, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "openzeppelin-solidity/contracts/access/AccessControl.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

import {vcUSDPool} from "contracts/Pool/vcUSDPool.sol";

contract WalletTokensalePrivate is AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    uint256 public totalAmount;
    uint256 public totalSold;

    uint256 public minAmountToBuy;
    uint256 public maxAmountToBuy;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SERVICE_ROLE = keccak256("SERVICE_ROLE");
    // address of main token
    address public govTokenAddress;
    address public USDTAddress;
    uint256 public factor = 10**12;
    uint256 public USDTReceived;
    uint256 public USDTClaimed;

    // for example: 100000 = 0.01 USD
    uint256 public rate;
    uint256 public ratesPrecision = 10**7;

    address public vcUSDPoolAddress;

    uint256 currentLockNumber = 0;
    // true = swap unlocked, false = swap locked
    bool public swapUnlocked = true;

    //true = claim unlocked, false = locked
    bool public claimUnlocked = false;
    // struct of lock tokens
    struct Lock {
        uint256 unlockDate;
        uint256 percent;
    }
    // array of locks tokens
    Lock[] public locks;

    struct UserInfo {
        uint256 amount;
        uint256 claimed;
    }

    mapping(address => UserInfo) public users;
    event TokenExchangedFromUsdt(
        address indexed spender,
        uint256 usdtAmount,
        uint256 daovcAmount,
        string userId,
        uint256 time
    );
    event TokensClaimed(
        address indexed claimer,
        uint256 amountClaimed,
        uint256 time
    );
    event TokenExchangedFromFiat(
        address indexed spender,
        uint256 amount,
        uint256 daovcAmount,
        uint256 time
    );
    event RoundStateChanged(bool state, uint256 time);

    modifier roundUnlocked() {
        require(swapUnlocked, "Round is locked!");
        _;
    }

    modifier claimUnlockedModifier() {
        require(claimUnlocked, "Round is locked!");
        _;
    }

    /**
     * @dev Constructor of Wallet.
     *
     */
    constructor(
        address _govTokenAddress,
        address _USDTAddress,
        uint256 _rate,
        uint256 _totalAmount,
        uint256 _minAmountToBuy,
        uint256 _maxAmountToBuy,
        address _vcUSDPoolAddress,
        uint256 _usdtReceived,
        uint256 _usdtClaimed
    ) public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);

        govTokenAddress = _govTokenAddress;
        USDTAddress = _USDTAddress;
        rate = _rate;
        totalAmount = _totalAmount;
        minAmountToBuy = _minAmountToBuy;
        maxAmountToBuy = _maxAmountToBuy;
        vcUSDPoolAddress = _vcUSDPoolAddress;
        USDTClaimed = _usdtClaimed;
        USDTReceived = _usdtReceived;
    }

    function setRoundState(bool _state) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        swapUnlocked = _state;
        emit RoundStateChanged(_state, block.timestamp);
    }

    /**
     * @dev add the token to Lock pull
     *
     * Parameters:
     *
     * - `_unlockDate` - date of token unlock
     * - `_amount` - token amount
     */
    function addLock(uint256[] memory _unlockDate, uint256[] memory _percent)
        external
    {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(
            _unlockDate.length == 10,
            "unlockDate array must have 10 values!"
        );
        require(_percent.length == 10, "percent array must have 10 values!");

        for (uint256 i = 0; i < _unlockDate.length; i++) {
            locks.push(
                Lock({percent: _percent[i], unlockDate: _unlockDate[i]})
            );
        }
    }

    /** @notice swap usdt to daoVC gov token
     *
     * Parameters:
     *
     *  @param _amountInUsdt - amount in usdt
     */
    function swap(uint256 _amountInUsdt, string memory _userId)
        external
        roundUnlocked
    {
        UserInfo storage user = users[msg.sender];

        uint256 amountInGov = _amountInUsdt.mul(factor).mul(ratesPrecision).div(
            rate
        );
        require(
            _amountInUsdt >= minAmountToBuy &&
                user.amount.add(amountInGov) <= maxAmountToBuy,
            "Amount must must be within the permitted range!"
        );

        require(
            totalSold.add(amountInGov) <= totalAmount,
            "All tokens was sold!"
        );

        ERC20(USDTAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _amountInUsdt
        );

        USDTReceived = USDTReceived.add(_amountInUsdt);
        user.amount = user.amount.add(amountInGov);
        totalSold = totalSold.add(amountInGov);

        emit TokenExchangedFromUsdt(
            msg.sender,
            _amountInUsdt,
            amountInGov,
            _userId,
            block.timestamp
        );
    }

    /** @notice swap fiat to daoVC gov token
     *
     * Parameters:
     *
     *  @param _user - user's address
     *  @param _amountInUsdt - amount in usd
     */
    function swapBackend(address _user, uint256 _amountInUsdt)
        external
        roundUnlocked
    {
        require(
            hasRole(SERVICE_ROLE, msg.sender),
            "Caller does not have the service role."
        );
        UserInfo storage user = users[_user];

        uint256 amountInGov = _amountInUsdt.mul(factor).mul(ratesPrecision).div(
            rate
        );
        require(
            _amountInUsdt >= minAmountToBuy &&
                user.amount.add(amountInGov) <= maxAmountToBuy,
            "Amount must must be within the permitted range!"
        );

        require(
            totalSold.add(amountInGov) <= totalAmount,
            "All tokens was sold!"
        );

        USDTReceived = USDTReceived.add(_amountInUsdt);
        user.amount = user.amount.add(amountInGov);
        totalSold = totalSold.add(amountInGov);
        emit TokenExchangedFromFiat(
            _user,
            _amountInUsdt,
            amountInGov,
            block.timestamp
        );
    }

    /** @notice user claim's his availeble tokens
     *
     */
    function claim() external nonReentrant claimUnlockedModifier {
        UserInfo storage user = users[msg.sender];
        require(user.amount > 0, "Nothing to claim");
        uint256 newLock = currentLockNumber;
        if (newLock <= locks.length - 2) {
            while (block.timestamp >= locks[newLock + 1].unlockDate) {
                newLock = newLock + 1;
                if (newLock == 9) {
                    break;
                }
            }
            currentLockNumber = newLock;
        }

        uint256 availableAmount = calcAvailableAmount(msg.sender);

        require(availableAmount > 0, "There are not available tokens to claim");
        user.claimed = user.claimed.add(availableAmount);
        ERC20(govTokenAddress).safeTransfer(msg.sender, availableAmount);
        emit TokensClaimed(msg.sender, availableAmount, block.timestamp);
    }

    function sendUsdtToPool(uint256 _amount) external {
        require(
            hasRole(SERVICE_ROLE, msg.sender),
            "Caller does not have the service role."
        );

        ERC20(USDTAddress).safeTransfer(vcUSDPoolAddress, _amount);
        USDTClaimed = USDTClaimed.add(_amount);

        vcUSDPool(vcUSDPoolAddress).sellVcUsdBackend(_amount);
    }

    /** @notice caluclate availeble amount of tokens for user
     *
     * Parameters:
     *
     *  @param _user - address of user
     */
    function calcAvailableAmount(address _user)
        private
        view
        returns (uint256 availableToken)
    {
        UserInfo storage user = users[_user];

        availableToken = (
            user.amount.mul(locks[currentLockNumber].percent).div(100)
        );

        if (availableToken >= user.claimed) {
            availableToken = availableToken.sub(user.claimed);
        } else {
            availableToken = 0;
        }

        return availableToken;
    }

    function getUserInfo(address _user)
        external
        view
        returns (
            uint256 amount_,
            uint256 available_,
            uint256 claimed_,
            uint256 currentLockTime_
        )
    {
        UserInfo storage user = users[_user];

        uint256 newLock = currentLockNumber;
        if (newLock <= locks.length - 2) {
            while (block.timestamp >= locks[newLock + 1].unlockDate) {
                newLock = newLock + 1;
                if (newLock == 9) {
                    break;
                }
            }
        }
        amount_ = user.amount;
        claimed_ = user.claimed;
        available_ = (user.amount.mul(locks[newLock].percent).div(100));

        if (available_ >= user.claimed) {
            available_ = available_.sub(user.claimed);
        } else {
            available_ = 0;
        }

        if (newLock == locks.length - 1) {
            currentLockTime_ = locks[newLock].unlockDate;
        } else {
            currentLockTime_ = locks[newLock + 1].unlockDate;
        }

        return (amount_, available_, claimed_, currentLockTime_);
    }

    function getRoundState() external view returns (bool) {
        return swapUnlocked;
    }

    function removeToken(
        address _recepient,
        uint256 _amount,
        address tokenAddress
    ) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(
            _amount <= ERC20(tokenAddress).balanceOf(address(this)),
            "Amount must be <= balanceOf(this contract)."
        );
        ERC20(tokenAddress).safeTransfer(_recepient, _amount);
    }

    function updateLock(
        uint256 _index,
        uint256 _percent,
        uint256 _unlockDate
    ) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        locks[_index].percent = _percent;
        locks[_index].unlockDate = _unlockDate;
    }

    function updateUserInfo(
        address _user,
        uint256 _amount,
        uint256 _claimed
    ) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        UserInfo storage user = users[_user];
        user.amount = _amount;
        user.claimed = _claimed;
    }

    function updateTokenAddress(address _govTokenAddress) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        govTokenAddress = _govTokenAddress;
    }

    /** @dev claim usdt from this contract
     *
     * Parameters:
     *
     *  - `usdtReceiver` - address, who gets USDT tokens
     */
    function claimUSDT(address _usdtReceiver) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(USDTReceived > 0, "Not enough USDT to claim");
        ERC20(USDTAddress).safeTransfer(
            _usdtReceiver,
            USDTReceived.sub(USDTClaimed)
        );
        USDTClaimed = USDTClaimed.add(USDTReceived.sub(USDTClaimed));
    }

    function getInfoAboutUsdt()
        external
        view
        returns (uint256 USDTReceived_, uint256 USDTClaimed_)
    {
        USDTReceived_ = USDTReceived;
        USDTClaimed_ = USDTClaimed;
        return (USDTReceived_, USDTClaimed_);
    }

    /** @dev returns current rate for contract
     *
     */
    function getRate() external view returns (uint256) {
        return rate;
    }

    /** @dev update rates
     *
     * Parameters:
     *
     *  - `_rate` - rate, for example: 400000 = 0.04$
     */
    function updateRate(uint256 _rate) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        rate = _rate;
    }

    function updateVcUsdPoolAddress(address _vcUSDPoolAddress) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        vcUSDPoolAddress = _vcUSDPoolAddress;
    }

    // amount in usdt
    function updateMinimum(uint256 _minAmountToBuy) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        minAmountToBuy = _minAmountToBuy;
    }

    //amount in gov token
    function updateMaximum(uint256 _maxAmountToBuy) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        maxAmountToBuy = _maxAmountToBuy;
    }

    function updateCurrentLockNumber(uint256 _newCurrentLock) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        currentLockNumber = _newCurrentLock;
    }

    function migrateUsers(
        address[] memory _users,
        uint256[] memory _amounts,
        uint256[] memory _claimed
    ) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(
            _users.length == _amounts.length,
            "Array users and amounts must be the same length!"
        );
        require(
            _users.length == _claimed.length,
            "Array users and claimed must be the same length!"
        );

        for (uint256 i = 0; i < _users.length; i++) {
            UserInfo storage user = users[_users[i]];
            user.amount = _amounts[i];
            user.claimed = _claimed[i];
        }
    }

    function setClaimState(bool _state) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        claimUnlocked = _state;
    }

    function updateTotalAmount(uint256 _totalAmount) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        totalAmount = _totalAmount;
    }

    function updateTotalSold(uint256 _totalSold) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        totalSold = _totalSold;
    }

    function updateFactor(uint256 _factor) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        factor = _factor;
    }

    function updateUSDTReceived(uint256 _usdtReceived) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        USDTReceived = _usdtReceived;
    }

    function updateUSDTClaimed(uint256 _usdtClaimed) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        USDTClaimed = _usdtClaimed;
    }
}

