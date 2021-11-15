// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./lib/IMO.sol";


contract IMOv2 is Initializable, OwnableUpgradeable, IMO{
    using SafeMath for uint256;
    uint256 private constant _LOCK = 1;
    uint256 public _migrationLock;

    modifier isMigrateable(){
        require(_migrationLock != _LOCK, "Lock IMOv1 migration.");
        _;
    }

    function initialize(
        IERC20 _stakeToken,
        IERC20 _stakeWrapToken,
        IStableSwap _stableSwapAddress,
        IIMOFactory _factoryAddress,
        uint256 _depositFee,
        uint256 _depositWrapFee,
        uint256 _withdrawFee,
        uint256 _withdrawWrapFee,
        uint256 _penaltyFee
    ) public initializer{
        __Ownable_init();
        __IMO_init_unchained(
            _stakeToken,
            _stakeWrapToken,
            _stableSwapAddress,
            _factoryAddress,
            _depositFee,
            _depositWrapFee,
            _withdrawFee,
            _withdrawWrapFee,
            _penaltyFee
        );
    }

    function lockMigration() public onlyOwner{
        _migrationLock = _LOCK;
    }

    function migrateDepositV1(
        address[] memory _users, 
        uint256[] memory _amount,
        uint256[] memory _amountWrap,
        uint256 _unlockTimestamp
    ) public onlyOwner isMigrateable{
        require(_users.length == _amount.length, "Invalid array length.");
        require(_users.length == _amountWrap.length, "Invalid array length.");
        for(uint256 i=0;i<_users.length;i++){
            // Deducted old data first (Incase migrated something wrong)
            totalStakeAmount = totalStakeAmount.sub(userStaking[_users[i]].amount);
            totalStakeWrapAmount = totalStakeWrapAmount.sub(userStaking[_users[i]].amountWrap);
            userStaking[_users[i]].amount = _amount[i];
            userStaking[_users[i]].amountWrap = _amountWrap[i];
            userStaking[_users[i]].amountLock = _amount[i].add(_amountWrap[i]);
            userStaking[_users[i]].unlockTimestamp = _unlockTimestamp;
            // Readd staking amount
            totalStakeAmount = totalStakeAmount.add(_amount[i]);
            totalStakeWrapAmount = totalStakeWrapAmount.add(_amountWrap[i]);
            // Check if already added to list
            if(userStaking[_users[i]].participated == 0){
                userStaking[_users[i]].participated = _PARTICIPATED;
                participants.push(_users[i]);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./interfaces/IIMOFactory.sol";
import "./interfaces/IIMOClonable.sol";
import "./interfaces/IIMO.sol";

import "./interfaces/IStableMMP.sol";
import "./interfaces/IStableSwap.sol";

abstract contract IMO is IIMO, Initializable, OwnableUpgradeable, PausableUpgradeable{
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeERC20 for IERC20;

    uint32 internal constant _NOT_PARTICIPATED = 0;
    uint32 internal constant _PARTICIPATED = 1;

    struct UserStaking{
        mapping(uint256 => uint256) amountFund;
        uint256 amount;
        uint256 amountWrap;
        uint256 amountLock;
        uint256 unlockTimestamp;
        // In penalty after deposit for timestamp;
        uint256 penaltyTimestamp; 
        uint32 tierLock;
        uint32 participated;
    }

    mapping(address => UserStaking) public userStaking;
    mapping(uint256 => IIMOFactory) public factory;

    address[] public participants;
    uint256[] public requireTier;

    IERC20 public stakeToken;
    IERC20 public stakeWrapToken;
    IStableSwap public stableSwap;

    uint256 public factoryVersion;
    uint256 public totalStakeAmount;
    uint256 public totalStakeWrapAmount;
    uint256 public penaltyTime = 7 days;

    // 1e6 means 100%, while 1e3 = 1%
    uint256 public depositFee;
    uint256 public depositWrapFee;
    uint256 public withdrawFee;
    uint256 public withdrawWrapFee;
    uint256 public penaltyFee;

    uint256 public totalWrapFeeAmount;
    uint256 public totalFeeAmount;

    /**************************************************************
     *  NOTE: Initialization
     **************************************************************/

    function __IMO_init(
        IERC20 _stakeToken, 
        IERC20 _stakeWrapToken,
        IStableSwap _stableSwapAddress,
        IIMOFactory _factoryAddress,
        uint256 _depositFee,
        uint256 _depositWrapFee,
        uint256 _withdrawFee,
        uint256 _withdrawWrapFee,
        uint256 _penaltyFee
    ) internal initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __IMO_init_unchained(
            _stakeToken, 
            _stakeWrapToken,
            _stableSwapAddress,
            _factoryAddress,
            _depositFee,
            _depositWrapFee,
            _withdrawFee,
            _withdrawWrapFee,
            _penaltyFee
        );
    }

    function __IMO_init_unchained(
        IERC20 _stakeToken, 
        IERC20 _stakeWrapToken,
        IStableSwap _stableSwapAddress,
        IIMOFactory _factoryAddress,
        uint256 _depositFee,
        uint256 _depositWrapFee,
        uint256 _withdrawFee,
        uint256 _withdrawWrapFee,
        uint256 _penaltyFee
    ) internal initializer{
        factoryVersion = _factoryAddress.VERSION();
        factory[factoryVersion] = _factoryAddress;
        penaltyTime = 7 * 24*60*60;// 7 days
        requireTier.push(9 * (10**23));
        requireTier.push(45 * (10**22));
        requireTier.push(9 * (10**22));
        requireTier.push(9 * (10**21));
        requireTier.push(9 * (10**20));
        stakeToken = _stakeToken;
        stakeWrapToken = _stakeWrapToken;
        stableSwap = _stableSwapAddress;
        depositFee = _depositFee;
        depositWrapFee = _depositWrapFee;
        withdrawFee = _withdrawFee;
        withdrawWrapFee = _withdrawWrapFee;
        penaltyFee = _penaltyFee;
    }

    /**************************************************************
     *  NOTE: Contract parameter-setters
     **************************************************************/

    function setStakeToken(IERC20 token) public onlyOwner whenPaused{
        stakeToken = token;
    }

    function setStakeWrapToken(IERC20 token) public onlyOwner whenPaused{
        stakeWrapToken = token;
    }

    function setDepositFee(uint256 fee) public onlyOwner whenPaused{
        depositFee = fee;
    }

    function setDepositWrapFee(uint256 fee) public onlyOwner whenPaused{
        depositWrapFee = fee;
    }

    function setWithdrawFee(uint256 fee) public onlyOwner whenPaused{
        withdrawFee = fee;
    }

    function setWithdrawWrapFee(uint256 fee) public onlyOwner whenPaused{
        withdrawWrapFee = fee;
    }

    function setPenaltyTime(uint256 time) public onlyOwner whenPaused{
        penaltyTime = time;
    }

    function setStableSwap(IStableSwap swap) public onlyOwner whenPaused{
        stableSwap = swap;
    }

    function setPause() public onlyOwner{
        _pause();
    }

    function setUnpause() public onlyOwner{
        _unpause();
    }

    /**************************************************************
     *  NOTE: Contract parameter-getter
     **************************************************************/

    function getUserLock(address _user) public view returns(uint256, uint256){
        return (userStaking[_user].amountLock, userStaking[_user].unlockTimestamp);
    }

    function getUserLockAmount(address _user) public view returns(uint256){
        return userStaking[_user].amountLock;
    }

    function getUserUnlockTimestamp(address _user) public view returns(uint256){
        return userStaking[_user].unlockTimestamp;
    }

    function totalDeposit(address _user) public view returns(uint256){
        return (userStaking[_user].amount).add(userStaking[_user].amountWrap);
    }

    function participantsLength() public view returns(uint256){
        return participants.length;
    }

    function totalValueLock()public view returns(uint256){
        return totalStakeAmount.add(totalStakeWrapAmount);
    }

    /**************************************************************
     *  NOTE: IMO Management
     **************************************************************/

    function getImo(uint256 imoIndex) public view returns(IIMOClonable){
        require(imoIndex < factory[factoryVersion].imoAddressesLength(), "imo index overflow.");
        return IIMOClonable(factory[factoryVersion].imoAddresses(imoIndex));
    }

    function getImoFactory() public view returns(IIMOFactory){
        return factory[factoryVersion];
    }

    function getImoWithVersion(uint256 version, uint256 imoIndex) public view returns(IIMOClonable){
        require(imoIndex < factory[version].imoAddressesLength(), "imo index overflow.");
        return IIMOClonable(factory[version].imoAddresses(imoIndex));
    }

    function getImoFactoryWithVersion(uint256 version) public view returns(IIMOFactory){
        return factory[version];
    }

    function setImoFactory(IIMOFactory _factory) public onlyOwner whenPaused{
        uint256 version = _factory.VERSION();
        factory[version] = _factory;
    }

    function setImoFactoryVersion(uint256 version) public onlyOwner whenPaused{
        factoryVersion = version;
    }

    function createImo(
        IERC20 _offerToken,
        IERC20 _fundToken,
        uint256 _startCommitTimestamp,
        uint256 _endCommitTimestamp,
        uint256 _claimTimestamp,
        uint256 _withdrawTimestamp,
        uint256 _raiseAmount,
        uint256 _offerAmount,
        uint256[] memory _hardCap
    ) public onlyOwner returns(address, uint256){
        address imo = factory[factoryVersion].createIMO(
            _offerToken,
            _fundToken,
            _startCommitTimestamp,
            _endCommitTimestamp,
            _claimTimestamp,
            _withdrawTimestamp,
            _raiseAmount,
            _offerAmount,
            _hardCap
        );
        uint256 length = factory[factoryVersion].imoAddressesLength();
        return (imo, length - 1);
    }

    /**************************************************************
     *  NOTE: User Tier Management 
     **************************************************************/

    function _getTier(uint256 amount) private view returns(uint32){
        for(uint32 i=0;i<requireTier.length;i++){
            if(amount >= requireTier[i]){
                return i + 1;
            }
        }
        return 0;
    }

    function setRequireTier(uint256[] memory _requireTier) public onlyOwner whenPaused{
        require(_requireTier.length == 5, "Invalid array length.");
        for(uint32 i=0;i<_requireTier.length;i++){
            if(requireTier.length < (i+1))
                requireTier.push(_requireTier[i]);
            else
                requireTier[i] = _requireTier[i];
        }
    }

    function getTier(address _user) public view override returns(uint32){
        uint256 totalAmount = totalDeposit(_user);
        return _getTier(totalAmount);
    }

    function getTierLockAmount(uint32 tier) public view override returns(uint256){
        require(tier >= 0 && tier <= 5, "Tier must be between 0-5.");
        if(tier == 0) return 0;
        return requireTier[tier-1];
    }

    /**************************************************************
     *  NOTE: Compute Fee for deposit and withdraw
     **************************************************************/

    function _getDepositFee(uint256 _amount) private view returns(uint256){
        if(depositFee == 0)return 0;
        return _amount.mul(depositFee).div(1e6);
    }

    function _getDepositWrapFee(uint256 _amount) private view returns(uint256){
        if(depositWrapFee == 0)return 0;
        return _amount.mul(depositWrapFee).div(1e6);
    }

    function _getWithdrawFee(uint256 _amount) private view returns(uint256){
        if(withdrawFee == 0)return 0;
        return _amount.mul(withdrawFee).div(1e6);
    }

    function _getWithdrawWrapFee(uint256 _amount) private view returns(uint256){
        if(withdrawWrapFee == 0)return 0;
        return _amount.mul(withdrawWrapFee).div(1e6);
    }

    function _getEarlyWithdrawFee(uint256 _amount) private view returns(uint256){
        if(penaltyFee == 0)return 0;
        return _amount.mul(penaltyFee).div(1e6);
    }

    /**************************************************************
     *  NOTE: Withdraw Lock 
     **************************************************************/

    function getAvailableWithdraw(address _user) public view returns(uint256){
        if(userStaking[_user].unlockTimestamp < block.timestamp)
            return userStaking[_user].amount;
        if(userStaking[_user].amountLock > userStaking[_user].amount)
            return 0;
        return userStaking[_user].amount
        .sub(userStaking[_user].amountLock);
    }

    function getAvailableWithdrawWrap(address _user) public view returns(uint256){
        if(userStaking[_user].unlockTimestamp < block.timestamp ||
            getAvailableWithdraw(_user) > 0)
            return userStaking[_user].amountWrap;
        return userStaking[_user].amount
        .add(userStaking[_user].amountWrap)
        .sub(userStaking[_user].amountLock);
    }

    /**************************************************************
     *  NOTE: Main Features for staking: Deposit, Withdraw
     **************************************************************/

    function deposit(uint256 _amount) public whenNotPaused{
        require(_amount > 0, "Amount must be > 0.");

        stakeToken.safeTransferFrom(msg.sender, address(this), _amount);

        // Deduct tax from MMP
        _amount = _amount.mul(9).div(10);

        uint256 _fee = _getDepositFee(_amount);
        uint256 _amountAfterFee = _amount.sub(_fee);

        if(userStaking[msg.sender].participated == _NOT_PARTICIPATED){
            userStaking[msg.sender].participated = _PARTICIPATED;
            participants.push(address(msg.sender));
        }
        userStaking[msg.sender].amount = userStaking[msg.sender].amount.add(_amountAfterFee);
        // Set penalty time after deposit
        userStaking[msg.sender].penaltyTimestamp = block.timestamp.add(penaltyTime);
        totalStakeAmount = totalStakeAmount.add(_amountAfterFee);
        totalFeeAmount = totalFeeAmount.add(_fee);
        emit Deposit(msg.sender, stakeToken, _amountAfterFee, _fee);
    }

    function depositWrap(uint256 _amount) public whenNotPaused{
        require(_amount > 0, "Amount must be > 0.");

        stakeWrapToken.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 _fee = _getDepositFee(_amount);
        uint256 _amountAfterFee = _amount.sub(_fee);

        if(userStaking[msg.sender].participated == _NOT_PARTICIPATED){
            userStaking[msg.sender].participated = _PARTICIPATED;
            participants.push(address(msg.sender));
        }
        userStaking[msg.sender].amountWrap = userStaking[msg.sender].amountWrap.add(_amountAfterFee);
        // Set penalty time after deposit
        userStaking[msg.sender].penaltyTimestamp = block.timestamp.add(penaltyTime);
        totalStakeWrapAmount = totalStakeWrapAmount.add(_amountAfterFee);
        totalWrapFeeAmount = totalWrapFeeAmount.add(_fee);
        emit Deposit(msg.sender, stakeWrapToken, _amountAfterFee, _fee);
    }

    function withdraw(uint256 _amount) public whenNotPaused{
        require(_amount > 0, "Amount must be > 0.");
        require(userStaking[msg.sender].amount >= _amount, "Insufficient deposited amount to be withdrawn.");
        require(getAvailableWithdraw(msg.sender) >= _amount, "Withdraw amount exceed available, Please check if any is locked.");
        uint256 _fee = _getWithdrawFee(_amount);
        if(block.timestamp < userStaking[msg.sender].penaltyTimestamp){
            _fee = _fee.add(_getEarlyWithdrawFee(_amount));
        }
        uint256 _amountAfterFee = _amount.sub(_fee);
        stakeToken.safeTransfer(msg.sender, _amountAfterFee);
        userStaking[msg.sender].amount = userStaking[msg.sender].amount.sub(_amount);
        totalStakeAmount = totalStakeAmount.sub(_amount);
        totalFeeAmount = totalFeeAmount.add(_fee);
        emit Withdraw(msg.sender, stakeToken, _amountAfterFee, _fee);
    }

    function withdrawWrap(uint256 _amount) public whenNotPaused{
        require(_amount > 0, "Amount must be > 0.");
        require(userStaking[msg.sender].amountWrap >= _amount, "Insufficient deposited amount to be withdrawn.");
        require(getAvailableWithdrawWrap(msg.sender) >= _amount, "Withdraw amount exceed available, Please check if any is locked.");
        uint256 _fee = _getWithdrawWrapFee(_amount);
        if(block.timestamp < userStaking[msg.sender].penaltyTimestamp){
            _fee = _fee.add(_getEarlyWithdrawFee(_amount));
        }
        uint256 _amountAfterFee = _amount.sub(_fee);
        stakeWrapToken.safeTransfer(msg.sender, _amountAfterFee);
        userStaking[msg.sender].amountWrap = userStaking[msg.sender].amountWrap.sub(_amount);
        totalStakeWrapAmount = totalStakeWrapAmount.sub(_amount);
        totalWrapFeeAmount = totalWrapFeeAmount.add(_fee);
        emit Withdraw(msg.sender, stakeWrapToken, _amountAfterFee, _fee);
    }

    /**************************************************************
     *  NOTE: IMO Wrapper: Commit, Claim
     **************************************************************/

    function commit(uint256 imoIndex, uint256 amount) public whenNotPaused{
        require(imoIndex < factory[factoryVersion].imoAddressesLength(), "IMO not found.");
        uint32 tier = getTier(msg.sender);
        require(tier > 0 && tier <= 5, "Require tier 1 - 5, to participate in IMO");
        IIMOClonable imo = getImo(imoIndex);
        imo.commit(msg.sender, amount);
        uint256 amountLock = getTierLockAmount(tier);
        uint256 unlockTimestamp = imo.withdrawTimestamp();
        // Clear penalty if committed
        userStaking[msg.sender].penaltyTimestamp = 0;
        // Update lockAmount, use max lockAmount
        if(amountLock > userStaking[msg.sender].amountLock)userStaking[msg.sender].amountLock = amountLock;
        if(tier > userStaking[msg.sender].tierLock)userStaking[msg.sender].tierLock = tier;
        // Update unlockTimestamp use max unlockTimestamp
        if(unlockTimestamp > userStaking[msg.sender].unlockTimestamp)userStaking[msg.sender].unlockTimestamp = unlockTimestamp;
        emit Commit(msg.sender, imoIndex, imo.fundToken(), amount, tier);
    }

    function commitFromBUSD(uint256 imoIndex, uint256 amount) public whenNotPaused{
        require(address(stableSwap) != address(0), "Swap contract is not set.");
        // Doing swap BUSD to mmUSD, before doing normal commit
        (uint256 stableFee,) = stableSwap.getMintFee(amount);
        uint256 mmUSDAmount = amount.sub(stableFee);
        stableSwap.mintFromOnlyStable(amount);
        commit(imoIndex, mmUSDAmount);
    }

    function claim(uint256 imoIndex) public whenNotPaused{
        require(totalDeposit(msg.sender) > 0, "Not partipated.");
        IIMOClonable imo = getImo(imoIndex);
        (uint256 offerAmount, uint256 refundAmount) = imo.claim(msg.sender);
        emit Claim(msg.sender, imoIndex, imo.offerToken(), offerAmount, imo.fundToken(), refundAmount, imo.getCommitUserTier(msg.sender));
    }

    /**************************************************************
     *  NOTE: Token Management in contracts
     **************************************************************/

    function ownerWithdraw(IERC20 token, uint256 amount) public onlyOwner{
        token.safeTransfer(msg.sender, amount);
        emit OwnerWithdraw(msg.sender, token, amount);
    }
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
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IIMO.sol";

interface IIMOFactory{
    function VERSION() external view returns(uint256);
    function imoAddresses(uint256 index) external view returns(address);
    function getImplementation() external view returns(address);
    function imoAddressesLength() external view returns(uint256);
    function createIMO(
            IERC20 _offerToken,
            IERC20 _fundToken,
            uint256 _startCommitTimestamp,
            uint256 _endCommitTimestamp,
            uint256 _claimTimestamp,
            uint256 _withdrawTimestamp,
            uint256 _raiseAmount,
            uint256 _offerAmount,
            uint256[] memory _hardCap
        ) external returns(address);
    event IMOCreated(address imoAddress);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./IIMO.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IIMOClonable{
    struct UserCommit{
        uint256 commitAmount;
        uint32 claimed;
        uint32 tier;
    }
    function offerToken() external view returns(IERC20);
    function fundToken() external view returns(IERC20);
    function startCommitTimestamp() external view returns(uint256);
    function endCommitTimestamp() external view returns(uint256);
    function claimTimestamp() external view returns(uint256);
    function withdrawTimestamp() external view returns(uint256);
    function raiseAmount() external view returns(uint256);
    function offerAmount() external view returns(uint256);
    function totalFund() external view returns(uint256);
    function hardCap(uint256 index) external view returns(uint256);

    function getHardcapByTier(uint32 tier) external view returns(uint256);
    function getUserAllocation(address _user) external view returns(uint256);
    function getOfferAmount(address _user) external view returns(uint256);
    function getRefundAmount(address _user) external view returns(uint256);

    function getParticipantLength() external view returns(uint256);
    function getCommitLimit(address _user) external view returns(uint256);
    function getCommitUserTier(address _user) external view returns(uint32);
    
    function commit(address _user, uint256 amount) external returns(uint256);
    function claim(address _user) external returns(uint256, uint256);

    event Commit(address indexed user, IERC20 token, uint256 amount, uint32 userTier);
    event Claim(address indexed user, IERC20 offerToken, uint256 amount, IERC20 fundToken, uint256 refundAmount, uint32 userTier);
    event OwnerWithdraw(address owner, IERC20 token, uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IIMO{
    function getTier(address _user) external view returns(uint32);
    function getTierLockAmount(uint32 tier) external view returns(uint256);

    event Deposit(address indexed user, IERC20 token, uint256 amountStake, uint256 amountFee);
    event Commit(address indexed user, uint256 imoIndex, IERC20 token, uint256 amount, uint32 tier);
    event Claim(address indexed user, uint256 imoIndex, IERC20 offerToken, uint256 offerAmount, IERC20 refundToken, uint256 refundAmount, uint32 tier);
    event Withdraw(address indexed user, IERC20 token, uint256 amountWithdraw, uint256 amountFee);
    event OwnerWithdraw(address owner, IERC20 token, uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IStableMMP {
    function balanceOf(address account) external view returns (uint256);
    function mint(address _address, uint256 _amount) external;
    function burnFrom(address account, uint256 amount) external;
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IStableMMP.sol";

interface IStableSwap{
    function mintFromOnlyStable(uint256 amount) external;
    function getMintFee(uint256 amount) external view returns(uint256 stableFee, uint256 fee);
    function FeeToken() external view returns(IERC20);
    function StableToken() external view returns(IERC20);
    function mmUSD() external view returns(IStableMMP);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

