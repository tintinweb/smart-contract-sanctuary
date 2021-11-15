// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./lib/IMO.sol";

contract IMOv2 is Initializable, OwnableUpgradeable, IMO{
    uint256 private constant _LOCK = 1;
    uint256 public _migrationLock;

    modifier isMigrateable(){
        require(_migrationLock != _LOCK, "Lock IMOv1 migration.");
        _;
    }

    function initialize(
        IERC20 _stakeToken,
        IERC20 _stakeWrapToken,
        uint32 _depositFee,
        uint32 _depositWrapFee,
        uint32 _withdrawFee,
        uint32 _withdrawWrapFee,
        uint32 _penaltyFee
    ) public initializer{
        __Ownable_init();
        __IMO_init_unchained(
            _stakeToken,
            _stakeWrapToken,
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
        uint256[] memory _amountWrap
    ) public onlyOwner isMigrateable{
        require(_users.length == _amount.length, "Invalid array length.");
        require(_users.length == _amountWrap.length, "Invalid array length.");
        for(uint256 i=0;i<_users.length;i++){
            userStaking[_users[i]].amount = _amount[i];
            userStaking[_users[i]].amountWrap = _amountWrap[i];
            userStaking[_users[i]].participated = _PARTICIPATED;
            participants.push(_users[i]);
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
import "./IMOFactory.sol";
import "./IMOClonable.sol";
import "./IIMO.sol";


abstract contract IMO is IIMO, Initializable, OwnableUpgradeable{
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
    address[] public participants;
    uint256[] public requireTier;

    IMOFactory private _factory;
    IERC20 public stakeToken;
    IERC20 public stakeWrapToken;
    uint256 public totalStakeAmount;
    uint256 public totalStakeWrapAmount;
    uint256 public penaltyTime = 7 days;

    // 1e6 means 100%, while 1e3 = 1%
    uint32 public depositFee;
    uint32 public depositWrapFee;
    uint32 public withdrawFee;
    uint32 public withdrawWrapFee;
    uint32 public penaltyFee;

    /**************************************************************
     *  NOTE: Initialization
     **************************************************************/

    function __IMO_init(
        IERC20 _stakeToken, 
        IERC20 _stakeWrapToken,
        uint32 _depositFee,
        uint32 _depositWrapFee,
        uint32 _withdrawFee,
        uint32 _withdrawWrapFee,
        uint32 _penaltyFee
    ) internal initializer{
        __Ownable_init();
        __IMO_init_unchained(
            _stakeToken, 
            _stakeWrapToken,
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
        uint32 _depositFee,
        uint32 _depositWrapFee,
        uint32 _withdrawFee,
        uint32 _withdrawWrapFee,
        uint32 _penaltyFee
    ) internal initializer{
        _factory = new IMOFactory();
        penaltyTime = 7 days;
        requireTier[0] = 9 * 10**23;
        requireTier[1] = 45 * 10**22;
        requireTier[2] = 9 * 10**22;
        requireTier[3] = 9 * 10**21;
        requireTier[4] = 9 * 10**20;
        stakeToken = _stakeToken;
        stakeWrapToken = _stakeWrapToken;
        depositFee = _depositFee;
        depositWrapFee = _depositWrapFee;
        withdrawFee = _withdrawFee;
        withdrawWrapFee = _withdrawWrapFee;
        penaltyFee = _penaltyFee;
    }

    /**************************************************************
     *  NOTE: Contract parameter-setters
     **************************************************************/

    function setStakeToken(IERC20 token) public onlyOwner{
        stakeToken = token;
    }

    function setStakeWrapToken(IERC20 token) public onlyOwner{
        stakeWrapToken = token;
    }

    function setDepositFee(uint32 fee) public onlyOwner{
        depositFee = fee;
    }

    function setDepositWrapFee(uint32 fee) public onlyOwner{
        depositWrapFee = fee;
    }

    function setWithdrawFee(uint32 fee) public onlyOwner{
        withdrawFee = fee;
    }

    function setWithdrawWrapFee(uint32 fee) public onlyOwner{
        withdrawWrapFee = fee;
    }

    function setPenaltyTime(uint256 time) public onlyOwner{
        penaltyTime = time;
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

    /**************************************************************
     *  NOTE: IMO Management
     **************************************************************/

    function _getImo(uint256 imoIndex) private view returns(IMOClonable){
        require(imoIndex < _factory.imoAddressesLength(), "imo index overflow.");
        return IMOClonable(_factory.imoAddresses(imoIndex));
    }

    function getImoFactory() public view returns(address){
        return address(_factory);
    }

    function setImoFactory(address _factoryAddress) public onlyOwner returns(IMOFactory){
        _factory = IMOFactory(_factoryAddress);
        return _factory;
    }

    function resetImoFactory() public onlyOwner returns(IMOFactory){
        _factory = new IMOFactory();
        return _factory;
    }

    function newImo(
        IERC20 _offerToken,
        IERC20 _fundToken,
        uint256 _startCommitTimestamp,
        uint256 _endCommitTimestamp,
        uint256 _claimTimestamp,
        uint256 _withdrawTimestamp,
        uint256 _raiseAmount,
        uint256 _offerAmount
    ) public onlyOwner returns(address, uint256){
        address imo = _factory.createIMO(
            _offerToken,
            _fundToken,
            IIMO(this),
            address(owner()),
            _startCommitTimestamp,
            _endCommitTimestamp,
            _claimTimestamp,
            _withdrawTimestamp,
            _raiseAmount,
            _offerAmount
        );
        uint256 length = _factory.imoAddressesLength();
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

    function setRequireTier(uint256[] memory _requireTier) public onlyOwner{
        require(_requireTier.length == 5, "Invalid array length.");
        for(uint32 i=0;i<_requireTier.length;i++){
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
        return requireTier[tier];
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
     *  NOTE: Main Features for staking: Deposit, Withdraw
     **************************************************************/

    function deposit(uint256 _amount) public{
        require(_amount > 0, "Amount must be > 0.");
        uint256 _fee = _getDepositFee(_amount);
        uint256 _amountAfterFee = _amount.sub(_fee);
        stakeToken.safeTransferFrom(msg.sender, address(this), _amount);
        if(userStaking[msg.sender].participated == _NOT_PARTICIPATED){
            userStaking[msg.sender].participated = _PARTICIPATED;
            participants.push(address(msg.sender));
        }
        userStaking[msg.sender].amount = userStaking[msg.sender].amount.add(_amountAfterFee);
        // Set penalty time after deposit
        userStaking[msg.sender].penaltyTimestamp = block.timestamp.add(penaltyTime);
        totalStakeAmount = totalStakeAmount.add(_amountAfterFee);
        emit Deposit(msg.sender, stakeToken, _amountAfterFee, _fee);
    }

    function depositWrap(uint256 _amount) public{
        require(_amount > 0, "Amount must be > 0.");
        uint256 _fee = _getDepositWrapFee(_amount);
        uint256 _amountAfterFee = _amount.sub(_fee);
        stakeWrapToken.safeTransferFrom(msg.sender, address(this), _amount);
        if(userStaking[msg.sender].participated == _NOT_PARTICIPATED){
            userStaking[msg.sender].participated = _PARTICIPATED;
            participants.push(address(msg.sender));
        }
        userStaking[msg.sender].amountWrap = userStaking[msg.sender].amountWrap.add(_amountAfterFee);
        // Set penalty time after deposit
        userStaking[msg.sender].penaltyTimestamp = block.timestamp.add(penaltyTime);
        totalStakeWrapAmount = totalStakeWrapAmount.add(_amountAfterFee);
        emit Deposit(msg.sender, stakeWrapToken, _amountAfterFee, _fee);
    }

    // TODO: Add penalty when withdraw before penalty date.
    function withdraw(uint256 _amount) public{
        require(_amount > 0, "Amount must be > 0.");
        require(userStaking[msg.sender].amount >= _amount, "Insufficient deposited amount to be withdrawn.");
        uint256 _fee = _getWithdrawFee(_amount);
        if(block.timestamp < userStaking[msg.sender].penaltyTimestamp){
            _fee = _fee.add(_getEarlyWithdrawFee(_amount));
        }
        uint256 _amountAfterFee = _amount.sub(_fee);
        stakeToken.safeTransfer(msg.sender, _amountAfterFee);
        userStaking[msg.sender].amount = userStaking[msg.sender].amount.sub(_amount);
        totalStakeAmount = totalStakeAmount.sub(_amount);
        emit Withdraw(msg.sender, stakeToken, _amountAfterFee, _fee);
    }

    function withdrawWrap(uint256 _amount) public{
        require(_amount > 0, "Amount must be > 0.");
        require(userStaking[msg.sender].amountWrap >= _amount, "Insufficient deposited amount to be withdrawn.");
        uint256 _fee = _getWithdrawWrapFee(_amount);
        if(block.timestamp < userStaking[msg.sender].penaltyTimestamp){
            _fee = _fee.add(_getEarlyWithdrawFee(_amount));
        }
        uint256 _amountAfterFee = _amount.sub(_fee);
        stakeWrapToken.safeTransfer(msg.sender, _amountAfterFee);
        userStaking[msg.sender].amountWrap = userStaking[msg.sender].amountWrap.sub(_amount);
        totalStakeWrapAmount = totalStakeWrapAmount.sub(_amount);
        emit Withdraw(msg.sender, stakeWrapToken, _amountAfterFee, _fee);
    }

    /**************************************************************
     *  NOTE: IMO Wrapper: Commit, Claim
     **************************************************************/

    function commit(uint256 imoIndex, uint256 amount) public{
        uint32 tier = getTier(msg.sender);
        require(tier > 0 && tier <= 5, "Require tier 1 - 5, to participate in IMO");
        IMOClonable imo = _getImo(imoIndex);
        // This will be rejected from IMOClonable if not in commitable event.
        imo.commit(msg.sender, amount);
        // Calculate LockAmount
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

    function claim(uint256 imoIndex) public{
        require(totalDeposit(msg.sender) > 0, "Not partipated.");
        IMOClonable imo = _getImo(imoIndex);
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

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IIMO.sol";
import "./IMOClonable.sol";

contract IMOFactory is Ownable{
    address immutable implementation;
    address[] public imoAddresses;

    constructor(){
        implementation = address(new IMOClonable());
    }

    event IMOCreated(address imoAddress);

    function createIMO(
        IERC20 _offerToken,
        IERC20 _fundToken,
        IIMO _imo,
        address imoOwner, 
        uint256 _startCommitTimestamp,
        uint256 _endCommitTimestamp,
        uint256 _claimTimestamp,
        uint256 _withdrawTimestamp,
        uint256 _raiseAmount,
        uint256 _offerAmount
    ) external virtual onlyOwner returns(address){
        address clone = Clones.clone(implementation);        
        IMOClonable imo = IMOClonable(clone);
        imo.initialize(
            _offerToken,
            _fundToken,
            _imo,
            _startCommitTimestamp,
            _endCommitTimestamp,
            _claimTimestamp,
            _withdrawTimestamp,
            _raiseAmount,
            _offerAmount
        );
        imo.transferOwnership(imoOwner);
        imoAddresses.push(clone);
        emit IMOCreated(clone);
        return clone;
    }

    function imoAddressesLength() external view returns(uint256){
        return imoAddresses.length;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./IIMO.sol";

contract IMOClonable is Initializable, OwnableUpgradeable{
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeERC20 for IERC20;

    struct UserCommit{
        uint256 commitAmount;
        uint32 tier;
    }

    // User commit in this IMO
    mapping(address => UserCommit) public userCommit;
    // Hard cap on this IMO
    uint256[] public hardCap;
    // User committed on this IMO
    address[] public participants;

    IERC20 public offerToken;
    IERC20 public fundToken;
    IIMO public imo;

    uint256 public startCommitTimestamp;
    uint256 public endCommitTimestamp;
    uint256 public claimTimestamp;
    uint256 public withdrawTimestamp;

    uint256 public raiseAmount;
    uint256 public offerAmount;

    uint256 public totalFund;
    bool public deactivated;

    event Commit(address indexed user, IERC20 token, uint256 amount, uint32 userTier);
    event Claim(address indexed user, IERC20 offerToken, uint256 amount, IERC20 fundToken, uint256 refundAmount, uint32 userTier);
    event OwnerWithdraw(address owner, IERC20 token, uint256 amount);

    modifier onCommitEvent(){
        require(
            (block.timestamp >= startCommitTimestamp) &&
            (block.timestamp < endCommitTimestamp),
            "Not on commitable time."
        );
        _;
    }
    
    modifier onClaimEvent(){
        require(
            block.timestamp >= claimTimestamp,
            "Not on claimable time."
        );
        _;
    }

    modifier onlyIMO(){
        require(
            msg.sender == address(imo),
            "Not IMO Contract"
        );
        _;
    }

    /**************************************************************
     *  NOTE: Initialization
     **************************************************************/

    function initialize(
        IERC20 _offerToken,
        IERC20 _fundToken,
        IIMO _imo,
        uint256 _startCommitTimestamp,
        uint256 _endCommitTimestamp,
        uint256 _claimTimestamp,
        uint256 _withdrawTimestamp,
        uint256 _raiseAmount,
        uint256 _offerAmount
    ) public initializer{
        __Ownable_init();
        offerToken = _offerToken;
        fundToken = _fundToken;
        imo = _imo;
        startCommitTimestamp = _startCommitTimestamp;
        endCommitTimestamp = _endCommitTimestamp;
        claimTimestamp = _claimTimestamp;
        withdrawTimestamp = _withdrawTimestamp;
        raiseAmount = _raiseAmount;
        offerAmount = _offerAmount;
    }

    /**************************************************************
     *  NOTE: Setters 
     **************************************************************/

    function setOfferToken(IERC20 token) public onlyOwner{
        offerToken = token;
    }

    function setFundToken(IERC20 token) public onlyOwner{
        fundToken = token;
    }

    function setStartCommitTimestamp(uint256 time) public onlyOwner{
        startCommitTimestamp = time;
    }

    function setEndCommitTimestamp(uint256 time) public onlyOwner{
        endCommitTimestamp = time;
    }

    function setClaimTimestamp(uint256 time) public onlyOwner{
        claimTimestamp = time;
    }

    function setWithdrawTimestamp(uint256 time) public onlyOwner{
        withdrawTimestamp = time;
    }

    function setRaiseAmount(uint256 amount) public onlyOwner{
        raiseAmount = amount;
    }

    function setOfferAmount(uint256 amount) public onlyOwner{
        offerAmount = amount;
    }

    function setHardCap(uint256[] memory _hardCap) public onlyOwner{
        require(_hardCap.length == 5, "Invalid array length.");
        for(uint32 i=0;i<_hardCap.length;i++){
            hardCap[i] = _hardCap[i];
        }
    }

    // Tier can be 1 - 5
    function setHardCapByTier(uint256 _hardCap, uint32 tier) public onlyOwner{
        require((tier >= 1 && tier <= 5), "Tier must be 1-5.");
        hardCap[tier-1] = _hardCap;
    }

    /**************************************************************
     *  NOTE: Getters 
     **************************************************************/

    function getHardcapByTier(uint32 tier) public view returns(uint256){
        require((tier >= 0 && tier <= 5), "Tier must be 0-5.");
        if(tier == 0){
            return 0;
        }
        return hardCap[tier - 1];
    }
    
    // Allocation 100000 means 0.1(10%) whereas 1 means 0.000001(0.0001%)
    function getUserAllocation(address _user) public view returns(uint256){
        return userCommit[_user].commitAmount.mul(1e12).div(totalFund).div(1e6);
    }

    function getOfferAmount(address _user) public view returns(uint256){
        if(totalFund > raiseAmount){
            uint256 allocation = getUserAllocation(_user);
            return offerAmount.mul(allocation).div(1e6);
        }else{
            return userCommit[_user].commitAmount.mul(offerAmount).div(raiseAmount);
        }
    }

    function getRefundAmount(address _user) public view returns(uint256){
        if(totalFund <= raiseAmount){
            return 0;
        }
        uint256 allocation = getUserAllocation(_user);
        uint256 amount = raiseAmount.mul(allocation).div(1e6);
        return userCommit[_user].commitAmount.sub(amount);
    }

    function getParticipantLength() public view returns(uint256){
        return participants.length;
    }

    function getCommitLimit(address _user) public view returns(uint256){
        uint32 tier = imo.getTier(_user);
        return hardCap[tier-1].mul(raiseAmount).div(1e6);
    }

    function getCommitUserTier(address _user) public view returns(uint32){
        return userCommit[_user].tier;
    }


    /**************************************************************
     *  NOTE: Main features of IMO sub-contracts
     *          interface commit, claim for main IMO contract 
     **************************************************************/

    function commit(address _user, uint256 amount) external onCommitEvent onlyIMO returns(uint256){
        require(amount > 0, "amount must > 0");
        require(userCommit[_user].commitAmount + amount <= getCommitLimit(_user), "Exceed funding limit.");
        fundToken.safeTransferFrom(_user, address(imo), amount);
        userCommit[_user].commitAmount = userCommit[_user].commitAmount.add(amount);
        userCommit[_user].tier = imo.getTier(_user);
        totalFund = totalFund.add(amount);
        emit Commit(_user, fundToken, amount, userCommit[_user].tier);
        return amount;
    }

    function claim(address _user) external onClaimEvent onlyIMO returns(uint256, uint256){
        require(userCommit[_user].commitAmount > 0, "You haven't commit any funding or you have claimed.");
        uint256 _offerAmount = getOfferAmount(_user);
        uint256 _refundAmount = getRefundAmount(_user);
        offerToken.safeTransferFrom(address(imo), _user, _offerAmount);
        if(_refundAmount > 0){
            fundToken.safeTransferFrom(address(imo), _user, _refundAmount);
        }
        userCommit[_user].commitAmount = 0;
        emit Claim(_user, offerToken, _offerAmount, fundToken, _refundAmount, userCommit[_user].tier);
        return (_offerAmount, _refundAmount);
    }

    /**************************************************************
     *  NOTE: Owner Withdrawal 
     **************************************************************/
    // This contract shouldn't have any token stored 
    //      (Use main imo contract instead)
    //  But this one is an emergency withdraw
    function ownerWithdraw(IERC20 token, uint256 amount) public onlyOwner{
        token.safeTransfer(msg.sender, amount);
        emit OwnerWithdraw(msg.sender, token, amount);
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

