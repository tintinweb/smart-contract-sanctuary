/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

// Dependency file: contracts/zeppelin/math/SafeMath.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.7.0;

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


// Dependency file: contracts/zeppelin/upgradable/Initializable.sol


// pragma solidity ^0.7.0;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || !initialized, "Contract instance is already initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// Dependency file: contracts/zeppelin/GSN/Context.sol


// pragma solidity ^0.7.0;

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
abstract contract  Context {

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// Dependency file: contracts/zeppelin/upgradable/ownership/UpgradableOwnable.sol


// pragma solidity ^0.7.0;

// import "contracts/zeppelin/upgradable/Initializable.sol";

// import "contracts/zeppelin/GSN/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract UpgradableOwnable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}


// Dependency file: contracts/zeppelin/upgradable/ownership/UpgradableSecondary.sol


// pragma solidity ^0.7.0;

// import "contracts/zeppelin/upgradable/Initializable.sol";

// import "contracts/zeppelin/GSN/Context.sol";

/**
 * @dev A Secondary contract can only be used by its primary account (the one that created it).
 */
contract UpgradableSecondary is Initializable, Context {
    address private _primary;

    /**
     * @dev Emitted when the primary contract changes.
     */
    event PrimaryTransferred(
        address recipient
    );

    /**
     * @dev Sets the primary account to the one that is creating the Secondary contract.
     */
    function __Secondary_init(address sender) public initializer {
        _primary = sender;
        emit PrimaryTransferred(_primary);
    }

    /**
     * @dev Reverts if called from any account other than the primary.
     */
    modifier onlyPrimary() {
        require(_msgSender() == _primary, "Secondary: caller is not the primary account");
        _;
    }

    /**
     * @return the address of the primary.
     */
    function primary() public view returns (address) {
        return _primary;
    }

    /**
     * @dev Transfers contract to a new primary.
     * @param recipient The address of new primary.
     */
    function transferPrimary(address recipient) public onlyPrimary {
        require(recipient != address(0), "Secondary: new primary is the zero address");
        _primary = recipient;
        emit PrimaryTransferred(recipient);
    }

}

// Dependency file: contracts/interface/IAllowTokens.sol


// pragma solidity ^0.7.0;
interface IAllowTokens {

    struct Limits {
        uint256 min;
        uint256 max;
        uint256 daily;
        uint256 mediumAmount;
        uint256 largeAmount;
    }

    struct TokenInfo {
        bool allowed;
        uint256 typeId;
        uint256 spentToday;
        uint256 lastDay;
    }

    struct TypeInfo {
        string description;
        Limits limits;
    }

    struct TokensAndType {
        address token;
        uint256 typeId;
    }

    function version() external pure returns (string memory);

    function getInfoAndLimits(address token) external view returns (TokenInfo memory info, Limits memory limit);

    function calcMaxWithdraw(address token) external view returns (uint256 maxWithdraw);

    function getTypesLimits() external view returns(Limits[] memory limits);

    function getTypeDescriptionsLength() external view returns(uint256);

    function getTypeDescriptions() external view returns(string[] memory descriptions);

    function setToken(address token, uint256 typeId) external;

    function getConfirmations() external view returns (uint256 smallAmount, uint256 mediumAmount, uint256 largeAmount);

    function isTokenAllowed(address token) external view returns (bool);

    function updateTokenTransfer(address token, uint256 amount) external;
}

// Root file: contracts/AllowTokens/AllowTokens.sol


pragma solidity ^0.7.0;
pragma abicoder v2;

// import "contracts/zeppelin/math/SafeMath.sol";
// Upgradables
// import "contracts/zeppelin/upgradable/Initializable.sol";
// import "contracts/zeppelin/upgradable/ownership/UpgradableOwnable.sol";
// import "contracts/zeppelin/upgradable/ownership/UpgradableSecondary.sol";

// import "contracts/interface/IAllowTokens.sol";

contract AllowTokens is Initializable, UpgradableOwnable, UpgradableSecondary, IAllowTokens {
    using SafeMath for uint256;

    address constant private NULL_ADDRESS = address(0);
    uint256 constant public MAX_TYPES = 250;
    mapping (address => TokenInfo) public allowedTokens;
    mapping (uint256 => Limits) public typeLimits;
    uint256 public smallAmountConfirmations;
    uint256 public mediumAmountConfirmations;
    uint256 public largeAmountConfirmations;
    string[] public typeDescriptions;

    event SetToken(address indexed _tokenAddress, uint256 _typeId);
    event AllowedTokenRemoved(address indexed _tokenAddress);
    event TokenTypeAdded(uint256 indexed _typeId, string _typeDescription);
    event TypeLimitsChanged(uint256 indexed _typeId, Limits limits);
    event UpdateTokensTransfered(address indexed _tokenAddress, uint256 _lastDay, uint256 _spentToday);
    event ConfirmationsChanged(uint256 _smallAmountConfirmations, uint256 _mediumAmountConfirmations, uint256 _largeAmountConfirmations);


    modifier notNull(address _address) {
        require(_address != NULL_ADDRESS, "AllowTokens: Null Address");
        _;
    }

    function initialize(
        address _manager,
        address _primary,
        uint256 _smallAmountConfirmations,
        uint256 _mediumAmountConfirmations,
        uint256 _largeAmountConfirmations,
        TypeInfo[] memory typesInfo) public initializer {
        UpgradableOwnable.initialize(_manager);
        UpgradableSecondary.__Secondary_init(_primary);
        _setConfirmations(_smallAmountConfirmations, _mediumAmountConfirmations, _largeAmountConfirmations);
        for(uint i = 0; i < typesInfo.length; i = i + 1) {
            _addTokenType(typesInfo[i].description, typesInfo[i].limits);
        }
    }

    function version() override external pure returns (string memory) {
        return "v1";
    }

    function getInfoAndLimits(address token) override public view
    returns (TokenInfo memory info, Limits memory limit) {
        info = allowedTokens[token];
        limit = typeLimits[info.typeId];
        return (info, limit);
    }
    function calcMaxWithdraw(address token) override public view returns (uint256 maxWithdraw) {
        (TokenInfo memory info, Limits memory limits) = getInfoAndLimits(token);
        return _calcMaxWithdraw(info, limits);
    }

    function _calcMaxWithdraw(TokenInfo memory info, Limits memory limits) private view returns (uint256 maxWithdraw) {
        // solium-disable-next-line security/no-block-members
        if (block.timestamp > info.lastDay + 24 hours) { // solhint-disable-line not-rely-on-time
            info.spentToday = 0;
        }
        if (limits.daily <= info.spentToday)
            return 0;
        maxWithdraw = limits.daily - info.spentToday;
        if(maxWithdraw > limits.max)
            maxWithdraw = limits.max;
        return maxWithdraw;
    }

    // solium-disable-next-line max-len
    function updateTokenTransfer(address token, uint256 amount) override external onlyPrimary {
        (TokenInfo memory info, Limits memory limit) = getInfoAndLimits(token);
        require(isTokenAllowed(token), "AllowTokens: Not whitelisted");
        require(amount >= limit.min, "AllowTokens: Lower than limit");

        // solium-disable-next-line security/no-block-members
        if (block.timestamp > info.lastDay + 24 hours) { // solhint-disable-line not-rely-on-time
            // solium-disable-next-line security/no-block-members
            info.lastDay = block.timestamp; // solhint-disable-line not-rely-on-time
            info.spentToday = 0;
        }
        uint maxWithdraw = _calcMaxWithdraw(info, limit);
        require(amount <= maxWithdraw, "AllowTokens: Exceeded limit");
        info.spentToday = info.spentToday.add(amount);
        allowedTokens[token] = info;

        emit UpdateTokensTransfered(token, info.lastDay, info.spentToday);
    }

    function _addTokenType(string memory description, Limits memory limits) private returns(uint256 len) {
        require(bytes(description).length > 0, "AllowTokens: Empty description");
        len = typeDescriptions.length;
        require(len + 1 <= MAX_TYPES, "AllowTokens: Reached MAX_TYPES");
        typeDescriptions.push(description);
        _setTypeLimits(len, limits);
        emit TokenTypeAdded(len, description);
        return len;
    }

    function addTokenType(string calldata description, Limits calldata limits) external onlyOwner returns(uint256 len) {
        return _addTokenType(description, limits);
    }

    function _setTypeLimits(uint256 typeId, Limits memory limits) private {
        require(typeId < typeDescriptions.length, "AllowTokens: bigger than typeDescriptions");
        require(limits.max >= limits.min, "AllowTokens: maxTokens smaller than minTokens");
        require(limits.daily >= limits.max, "AllowTokens: dailyLimit smaller than maxTokens");
        require(limits.mediumAmount > limits.min, "AllowTokens: limits.mediumAmount smaller than min");
        require(limits.largeAmount > limits.mediumAmount, "AllowTokens: limits.largeAmount smaller than mediumAmount");
        typeLimits[typeId] = limits;
        emit TypeLimitsChanged(typeId, limits);
    }

    function setTypeLimits(uint256 typeId, Limits memory limits) public onlyOwner {
        _setTypeLimits(typeId, limits);
    }

    function getTypesLimits() external view override returns(Limits[] memory limits) {
        limits = new Limits[](typeDescriptions.length);
        for (uint256 i = 0; i < typeDescriptions.length; i++) {
            limits[i] = typeLimits[i];
        }
        return limits;
    }

    function getTypeDescriptionsLength() external view override returns(uint256) {
        return typeDescriptions.length;
    }

    function getTypeDescriptions() external view override returns(string[] memory descriptions) {
        descriptions = new string[](typeDescriptions.length);
        for (uint256 i = 0; i < typeDescriptions.length; i++) {
            descriptions[i] = typeDescriptions[i];
        }
        return descriptions;
    }

    function isTokenAllowed(address token) public view notNull(token) override returns (bool) {
        return allowedTokens[token].allowed;
    }

    function setToken(address token, uint256 typeId) override public notNull(token) {
        require(isOwner() || _msgSender() == primary(), "AllowTokens: unauthorized sender");
        require(typeId < typeDescriptions.length, "AllowTokens: typeId does not exist");
        TokenInfo memory info = allowedTokens[token];
        info.allowed = true;
        info.typeId = typeId;
        allowedTokens[token] = info;
        emit SetToken(token, typeId);
    }

    function setMultipleTokens(TokensAndType[] calldata tokensAndTypes) external onlyOwner {
        require(tokensAndTypes.length > 0, "AllowTokens: empty tokens");
        for(uint256 i = 0; i < tokensAndTypes.length; i = i + 1) {
            setToken(tokensAndTypes[i].token, tokensAndTypes[i].typeId);
        }
    }

    function removeAllowedToken(address token) external notNull(token) onlyOwner {
        TokenInfo memory info = allowedTokens[token];
        require(info.allowed, "AllowTokens: Not Allowed");
        info.allowed = false;
        allowedTokens[token] = info;
        emit AllowedTokenRemoved(token);
    }

    function setConfirmations(
        uint256 _smallAmountConfirmations,
        uint256 _mediumAmountConfirmations,
        uint256 _largeAmountConfirmations) external onlyOwner {
        _setConfirmations(_smallAmountConfirmations, _mediumAmountConfirmations, _largeAmountConfirmations);
    }

    function _setConfirmations(
        uint256 _smallAmountConfirmations,
        uint256 _mediumAmountConfirmations,
        uint256 _largeAmountConfirmations) private {
        require(_smallAmountConfirmations <= _mediumAmountConfirmations, "AllowTokens: small bigger than medium confirmations");
        require(_mediumAmountConfirmations <= _largeAmountConfirmations, "AllowTokens: medium bigger than large confirmations");
        smallAmountConfirmations = _smallAmountConfirmations;
        mediumAmountConfirmations = _mediumAmountConfirmations;
        largeAmountConfirmations = _largeAmountConfirmations;
        emit ConfirmationsChanged(_smallAmountConfirmations, _mediumAmountConfirmations, _largeAmountConfirmations);
    }

    function getConfirmations() external view override
    returns (uint256 smallAmount, uint256 mediumAmount, uint256 largeAmount) {
        return (smallAmountConfirmations, mediumAmountConfirmations, largeAmountConfirmations);
    }

}