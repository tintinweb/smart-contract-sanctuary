// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
import "../../Dependencies/OwnableUpgradeable.sol";
import "../../Dependencies/CheckContract.sol";
import "../../Dependencies/SafeMath.sol";
import "../../Interfaces/ILQTYToken.sol";
import "../Dependencies/AdminUpgradeable.sol";

contract Airdrop is AdminUpgradeable, CheckContract {
    using SafeMath for uint256;

    ILQTYToken public lqtyToken;

    uint256 internal constant DECIMAL_PRECISION = 1e18;

    struct AirdropInfo {
        // airdrop create init to zero, when join the airdrop will change to the join time
        uint256 joinTime;
        // airdrop create init to the current time, when user join airdrop will change to the join time
        uint256 lastClaimTime;
        uint256 claimedAmount;

        uint256 airdropDuration;
        uint256 claimDuration;
        uint256 joinDeadline;
        uint256 totalAmount;
    }

    mapping (address => AirdropInfo) public userAirdropInfos;

    // Events

    event LQTYTokenAddressChanged(address _lqtyTokenAddress);
    event AirdropCreated(address[] _users, uint256 _airdropDuration, uint256 _claimDuration, uint256 _joinDeadline, uint256 _amount);
    event Airdropped(address indexed _user, uint256 _amount);
    event AirdropInvited(address indexed _user, uint256 _airdropDuration, uint256 _claimDuration, uint256 _joinDeadline, uint256 _amount);
    event AirdropStarted(address indexed _user);
    event AirdropWithdraw(address indexed _user, uint256 _amount);

    // Functions

    function initialize() public initializer {
        __Ownable_init();
    }

    function setParams(address _lqtyTokenAddress, address _adminAddress) external onlyOwner {
        require(address(lqtyToken) == address(0), "lqtyToken address has been set");

        checkContract(_lqtyTokenAddress);
        lqtyToken = ILQTYToken(_lqtyTokenAddress);
        setAdmin(_adminAddress);

        emit LQTYTokenAddressChanged(_lqtyTokenAddress);
    }

    function withdraw(address _user) public onlyOwnerOrAdmin {
        uint256 _amount = lqtyToken.balanceOf(address(this));
        require(_amount > 0, "withdraw amount must be positive");
        lqtyToken.transfer(_user, _amount);
        emit AirdropWithdraw(_user, _amount);
    }

    function createAirdrop(address[] memory _users, uint256 _airdropDuration, uint256 _claimDuration, uint256 _joinDeadline, uint256 _amount) public onlyOwnerOrAdmin {
        require(address(lqtyToken) != address(0), "lqtyToken has not been set");
        require(_users.length > 0, "user addresses can't be empty");
        _requireConfigValid(_airdropDuration, _claimDuration, _joinDeadline, _amount);

        uint256 _totalAmount = _amount * DECIMAL_PRECISION;
        for (uint _index = 0; _index < _users.length; _index++) {
            require(!isOwnerOrAdmin(_users[_index]), "can't be owner or admin");

            AirdropInfo storage _airdropInfo = userAirdropInfos[_users[_index]];
            require(_airdropInfo.joinTime == 0 || block.timestamp > _getClaimDeadline(_airdropInfo), "user has processing airdrop");

            _airdropInfo.airdropDuration = _airdropDuration;
            _airdropInfo.claimDuration = _claimDuration;
            _airdropInfo.joinDeadline = _joinDeadline;
            _airdropInfo.totalAmount = _totalAmount;
            // reset to zero value
            _airdropInfo.claimedAmount = 0;
            _airdropInfo.lastClaimTime = block.timestamp;
            _airdropInfo.joinTime = 0;

            emit AirdropInvited(_users[_index], _airdropDuration, _claimDuration, _joinDeadline, _totalAmount);
        }

        emit AirdropCreated(_users, _airdropDuration, _claimDuration, _joinDeadline, _totalAmount);
    }

    function _getClaimDeadline(AirdropInfo memory _airdropInfo) internal pure returns (uint256) {
        return _airdropInfo.joinTime.add(_airdropInfo.airdropDuration).add(_airdropInfo.claimDuration);
    }

    function join() public {
        AirdropInfo storage _airdropInfo = userAirdropInfos[msg.sender];
        uint256 _currentTime = block.timestamp;

        require(_airdropInfo.joinTime == 0 && _currentTime < _airdropInfo.joinDeadline, "can't join the airdrop");

        _airdropInfo.joinTime = _currentTime;
        _airdropInfo.lastClaimTime = _currentTime;

        emit AirdropStarted(msg.sender);
    }

    function claimableAmount() public view returns (uint256) {
        return _claimableAmount(userAirdropInfos[msg.sender], block.timestamp);
    }

    function claim() public {
        AirdropInfo storage _airdropInfo = userAirdropInfos[msg.sender];
        uint256 _currentTime = block.timestamp;

        uint256 _amount = _claimableAmount(_airdropInfo, _currentTime);

        require(_amount > 0, "no amount to claim");

        lqtyToken.transfer(msg.sender, _amount);

        _airdropInfo.lastClaimTime = _currentTime;
        _airdropInfo.claimedAmount = _airdropInfo.claimedAmount.add(_amount);

        emit Airdropped(msg.sender, _amount);
    }

    function _claimableAmount(AirdropInfo memory _airdropInfo, uint256 _currentTime) internal pure returns (uint256) {
        if (_airdropInfo.joinTime == 0 || _currentTime > _getClaimDeadline(_airdropInfo)) {
            return 0;
        }

        uint256 _airdropEndTime = _airdropInfo.joinTime.add(_airdropInfo.airdropDuration);

        uint256 _amount;
        if (_currentTime >= _airdropEndTime) {
            _amount = _airdropInfo.totalAmount.sub(_airdropInfo.claimedAmount);
        } else {
            _amount = (_airdropInfo.totalAmount).div(_airdropInfo.airdropDuration).mul(_currentTime - _airdropInfo.lastClaimTime);
        }

        return _amount;
    }

    function _requireConfigValid(uint256 _airdropDuration, uint256 _claimDuration, uint256 _joinDeadline, uint256 _amount) internal view {
        require(_airdropDuration> 0, "airdrop duration must be positive");
        require(_claimDuration > 0, "claim duration must be positive");
        require(_joinDeadline > block.timestamp, "deadline can't be before now");
        require(_amount > 0, "amount must be positive");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "./ContextUpgradeable.sol";
import "./Initializable.sol";
/**
 * Based on OpenZeppelin's Ownable contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v3.3.0/contracts/access/OwnableUpgradeable.sol
 *
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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;


contract CheckContract {
    /**
     * Check that the account is an already deployed non-destroyed contract.
     * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L12
     */
    function checkContract(address _account) internal view {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(_account) }
        require(size > 0, "Account code size cannot be zero");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

/**
 * Based on OpenZeppelin's SafeMath:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
 *
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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "../Dependencies/IERC20.sol";
import "../Dependencies/IERC2612.sol";

interface ILQTYToken is IERC20, IERC2612 { 
   
    // --- Events ---
    
    event CommunityIssuanceAddressSet(address _communityIssuanceAddress);
    event LQTYStakingAddressSet(address _lqtyStakingAddress);
    event LockupContractFactoryAddressSet(address _lockupContractFactoryAddress);

    // --- Functions ---
    
    function sendToLQTYStaking(address _sender, uint256 _amount) external;

    function getDeploymentStartTime() external view returns (uint256);

    function getLpRewardsEntitlement() external view returns (uint256);

    function getCommunityIssuanceEntitlement() external view returns (uint256);

    function getLockupPeriod() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "../../Dependencies/OwnableUpgradeable.sol";

abstract contract AdminUpgradeable is OwnableUpgradeable {

    address public adminAddress;

    event AdminAddressChanged(address indexed _adminAddress);

    modifier onlyOwnerOrAdmin() {
        require(isOwnerOrAdmin(msg.sender), "not allowed");
        _;
    }

    /**
     * @dev set admin address
     * callable by owner
     */
    function setAdmin(address _adminAddress) public onlyOwner {
        require(_adminAddress != address(0), "Cannot be zero address");
        adminAddress = _adminAddress;

        emit AdminAddressChanged(_adminAddress);
    }

    function isOwnerOrAdmin(address _user) internal view returns (bool) {
        return _user == adminAddress || _user == owner();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
import "./Initializable.sol";

/*
 * Based on OpenZeppelin's ContextUpgradeable contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v3.3.0/contracts/GSN/ContextUpgradeable.sol
 *
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity 0.6.11;


/**
 * Based on OpenZeppelin's Initializable contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v3.3.0/contracts/proxy/Initializable.sol
 *
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
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

pragma solidity 0.6.11;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 * 
 * Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 amount, 
                    uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    
    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     *
     * `owner` can limit the time a Permit is valid for by setting `deadline` to 
     * a value in the near future. The deadline argument can be set to uint(-1) to 
     * create Permits that effectively never expire.
     */
    function nonces(address owner) external view returns (uint256);
    
    function version() external view returns (string memory);
    function permitTypeHash() external view returns (bytes32);
    function domainSeparator() external view returns (bytes32);
}

