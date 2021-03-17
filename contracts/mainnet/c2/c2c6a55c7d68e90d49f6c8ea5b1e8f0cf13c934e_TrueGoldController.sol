/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

/*
    .'''''''''''..     ..''''''''''''''''..       ..'''''''''''''''..
    .;;;;;;;;;;;'.   .';;;;;;;;;;;;;;;;;;,.     .,;;;;;;;;;;;;;;;;;,.
    .;;;;;;;;;;,.   .,;;;;;;;;;;;;;;;;;;;,.    .,;;;;;;;;;;;;;;;;;;,.
    .;;;;;;;;;,.   .,;;;;;;;;;;;;;;;;;;;;,.   .;;;;;;;;;;;;;;;;;;;;,.
    ';;;;;;;;'.  .';;;;;;;;;;;;;;;;;;;;;;,. .';;;;;;;;;;;;;;;;;;;;;,.
    ';;;;;,..   .';;;;;;;;;;;;;;;;;;;;;;;,..';;;;;;;;;;;;;;;;;;;;;;,.
    ......     .';;;;;;;;;;;;;,'''''''''''.,;;;;;;;;;;;;;,'''''''''..
              .,;;;;;;;;;;;;;.           .,;;;;;;;;;;;;;.
             .,;;;;;;;;;;;;,.           .,;;;;;;;;;;;;,.
            .,;;;;;;;;;;;;,.           .,;;;;;;;;;;;;,.
           .,;;;;;;;;;;;;,.           .;;;;;;;;;;;;;,.     .....
          .;;;;;;;;;;;;;'.         ..';;;;;;;;;;;;;'.    .',;;;;,'.
        .';;;;;;;;;;;;;'.         .';;;;;;;;;;;;;;'.   .';;;;;;;;;;.
       .';;;;;;;;;;;;;'.         .';;;;;;;;;;;;;;'.    .;;;;;;;;;;;,.
      .,;;;;;;;;;;;;;'...........,;;;;;;;;;;;;;;.      .;;;;;;;;;;;,.
     .,;;;;;;;;;;;;,..,;;;;;;;;;;;;;;;;;;;;;;;,.       ..;;;;;;;;;,.
    .,;;;;;;;;;;;;,. .,;;;;;;;;;;;;;;;;;;;;;;,.          .',;;;,,..
   .,;;;;;;;;;;;;,.  .,;;;;;;;;;;;;;;;;;;;;;,.              ....
    ..',;;;;;;;;,.   .,;;;;;;;;;;;;;;;;;;;;,.
       ..',;;;;'.    .,;;;;;;;;;;;;;;;;;;;'.
          ...'..     .';;;;;;;;;;;;;;,,,'.
                       ...............
*/

// https://github.com/trusttoken/smart-contracts
// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.6.0;

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
     * // importANT: Beware that changing an allowance with this method brings the risk
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

// Dependency file: @openzeppelin/contracts/math/SafeMath.sol

// pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// Dependency file: contracts/true-gold/interface/IOwnable.sol

// pragma solidity 0.6.10;

interface IOwnable {
    function transferOwnership(address newOwner) external;
}

// Dependency file: contracts/proxy/OwnedUpgradeabilityProxy.sol

// solhint-disable const-name-snakecase
// pragma solidity 0.6.10;

/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy {
    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event ProxyOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Event to show ownership transfer is pending
     * @param currentOwner representing the address of the current owner
     * @param pendingOwner representing the address of the pending owner
     */
    event NewPendingOwner(address currentOwner, address pendingOwner);

    // Storage position of the owner and pendingOwner of the contract
    bytes32 private constant proxyOwnerPosition = 0x6279e8199720cf3557ecd8b58d667c8edc486bd1cf3ad59ea9ebdfcae0d0dfac; //keccak256("trueUSD.proxy.owner");
    bytes32 private constant pendingProxyOwnerPosition = 0x8ddbac328deee8d986ec3a7b933a196f96986cb4ee030d86cc56431c728b83f4; //keccak256("trueUSD.pending.proxy.owner");

    /**
     * @dev the constructor sets the original owner of the contract to the sender account.
     */
    constructor() public {
        _setUpgradeabilityOwner(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner(), "only Proxy Owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the pending owner.
     */
    modifier onlyPendingProxyOwner() {
        require(msg.sender == pendingProxyOwner(), "only pending Proxy Owner");
        _;
    }

    /**
     * @dev Tells the address of the owner
     * @return owner the address of the owner
     */
    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }

    /**
     * @dev Tells the address of the owner
     * @return pendingOwner the address of the pending owner
     */
    function pendingProxyOwner() public view returns (address pendingOwner) {
        bytes32 position = pendingProxyOwnerPosition;
        assembly {
            pendingOwner := sload(position)
        }
    }

    /**
     * @dev Sets the address of the owner
     */
    function _setUpgradeabilityOwner(address newProxyOwner) internal {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, newProxyOwner)
        }
    }

    /**
     * @dev Sets the address of the owner
     */
    function _setPendingUpgradeabilityOwner(address newPendingProxyOwner) internal {
        bytes32 position = pendingProxyOwnerPosition;
        assembly {
            sstore(position, newPendingProxyOwner)
        }
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     *changes the pending owner to newOwner. But doesn't actually transfer
     * @param newOwner The address to transfer ownership to.
     */
    function transferProxyOwnership(address newOwner) external onlyProxyOwner {
        require(newOwner != address(0));
        _setPendingUpgradeabilityOwner(newOwner);
        emit NewPendingOwner(proxyOwner(), newOwner);
    }

    /**
     * @dev Allows the pendingOwner to claim ownership of the proxy
     */
    function claimProxyOwnership() external onlyPendingProxyOwner {
        emit ProxyOwnershipTransferred(proxyOwner(), pendingProxyOwner());
        _setUpgradeabilityOwner(pendingProxyOwner());
        _setPendingUpgradeabilityOwner(address(0));
    }

    /**
     * @dev Allows the proxy owner to upgrade the current version of the proxy.
     * @param implementation representing the address of the new implementation to be set.
     */
    function upgradeTo(address implementation) public virtual onlyProxyOwner {
        address currentImplementation;
        bytes32 position = implementationPosition;
        assembly {
            currentImplementation := sload(position)
        }
        require(currentImplementation != implementation);
        assembly {
            sstore(position, implementation)
        }
        emit Upgraded(implementation);
    }

    /**
     * @dev This event will be emitted every time the implementation gets upgraded
     * @param implementation representing the address of the upgraded implementation
     */
    event Upgraded(address indexed implementation);

    // Storage position of the address of the current implementation
    bytes32 private constant implementationPosition = 0x6e41e0fbe643dfdb6043698bf865aada82dc46b953f754a3468eaa272a362dc7; //keccak256("trueUSD.proxy.implementation");

    function implementation() public view returns (address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }

    /**
     * @dev Fallback functions allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    fallback() external payable {
        proxyCall();
    }

    receive() external payable {
        proxyCall();
    }

    function proxyCall() internal {
        bytes32 position = implementationPosition;

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, returndatasize(), calldatasize())
            let result := delegatecall(gas(), sload(position), ptr, calldatasize(), returndatasize(), returndatasize())
            returndatacopy(ptr, 0, returndatasize())

            switch result
                case 0 {
                    revert(ptr, returndatasize())
                }
                default {
                    return(ptr, returndatasize())
                }
        }
    }
}

// Dependency file: contracts/registry/interface/IRegistryClone.sol

// pragma solidity 0.6.10;

interface IRegistryClone {
    function syncAttributeValue(
        address _who,
        bytes32 _attribute,
        uint256 _value
    ) external;
}

// Dependency file: contracts/registry/Registry.sol

// pragma solidity 0.6.10;

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import {IRegistryClone as RegistryClone} from "contracts/registry/interface/IRegistryClone.sol";

contract Registry {
    struct AttributeData {
        uint256 value;
        bytes32 notes;
        address adminAddr;
        uint256 timestamp;
    }

    // never remove any storage variables
    address public owner;
    address public pendingOwner;
    bool initialized;

    // Stores arbitrary attributes for users. An example use case is an IERC20
    // token that requires its users to go through a KYC/AML check - in this case
    // a validator can set an account's "hasPassedKYC/AML" attribute to 1 to indicate
    // that account can use the token. This mapping stores that value (1, in the
    // example) as well as which validator last set the value and at what time,
    // so that e.g. the check can be renewed at appropriate intervals.
    mapping(address => mapping(bytes32 => AttributeData)) attributes;
    // The logic governing who is allowed to set what attributes is abstracted as
    // this accessManager, so that it may be replaced by the owner as needed
    bytes32 constant WRITE_PERMISSION = keccak256("canWriteTo-");
    mapping(bytes32 => IRegistryClone[]) subscribers;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SetAttribute(address indexed who, bytes32 attribute, uint256 value, bytes32 notes, address indexed adminAddr);
    event SetManager(address indexed oldManager, address indexed newManager);
    event StartSubscription(bytes32 indexed attribute, IRegistryClone indexed subscriber);
    event StopSubscription(bytes32 indexed attribute, IRegistryClone indexed subscriber);

    // Allows a write if either a) the writer is that Registry's owner, or
    // b) the writer is writing to attribute foo and that writer already has
    // the canWriteTo-foo attribute set (in that same Registry)
    function confirmWrite(bytes32 _attribute, address _admin) internal view returns (bool) {
        return (_admin == owner || hasAttribute(_admin, keccak256(abi.encodePacked(WRITE_PERMISSION ^ _attribute))));
    }

    // Writes are allowed only if the accessManager approves
    function setAttribute(
        address _who,
        bytes32 _attribute,
        uint256 _value,
        bytes32 _notes
    ) public {
        require(confirmWrite(_attribute, msg.sender));
        attributes[_who][_attribute] = AttributeData(_value, _notes, msg.sender, block.timestamp);
        emit SetAttribute(_who, _attribute, _value, _notes, msg.sender);

        IRegistryClone[] storage targets = subscribers[_attribute];
        uint256 index = targets.length;
        while (index-- > 0) {
            targets[index].syncAttributeValue(_who, _attribute, _value);
        }
    }

    function subscribe(bytes32 _attribute, IRegistryClone _syncer) external onlyOwner {
        subscribers[_attribute].push(_syncer);
        emit StartSubscription(_attribute, _syncer);
    }

    function unsubscribe(bytes32 _attribute, uint256 _index) external onlyOwner {
        uint256 length = subscribers[_attribute].length;
        require(_index < length);
        emit StopSubscription(_attribute, subscribers[_attribute][_index]);
        subscribers[_attribute][_index] = subscribers[_attribute][length - 1];
        subscribers[_attribute].pop();
    }

    function subscriberCount(bytes32 _attribute) public view returns (uint256) {
        return subscribers[_attribute].length;
    }

    function setAttributeValue(
        address _who,
        bytes32 _attribute,
        uint256 _value
    ) public {
        require(confirmWrite(_attribute, msg.sender));
        attributes[_who][_attribute] = AttributeData(_value, "", msg.sender, block.timestamp);
        emit SetAttribute(_who, _attribute, _value, "", msg.sender);
        IRegistryClone[] storage targets = subscribers[_attribute];
        uint256 index = targets.length;
        while (index-- > 0) {
            targets[index].syncAttributeValue(_who, _attribute, _value);
        }
    }

    // Returns true if the uint256 value stored for this attribute is non-zero
    function hasAttribute(address _who, bytes32 _attribute) public view returns (bool) {
        return attributes[_who][_attribute].value != 0;
    }

    // Returns the exact value of the attribute, as well as its metadata
    function getAttribute(address _who, bytes32 _attribute)
        public
        view
        returns (
            uint256,
            bytes32,
            address,
            uint256
        )
    {
        AttributeData memory data = attributes[_who][_attribute];
        return (data.value, data.notes, data.adminAddr, data.timestamp);
    }

    function getAttributeValue(address _who, bytes32 _attribute) public view returns (uint256) {
        return attributes[_who][_attribute].value;
    }

    function getAttributeAdminAddr(address _who, bytes32 _attribute) public view returns (address) {
        return attributes[_who][_attribute].adminAddr;
    }

    function getAttributeTimestamp(address _who, bytes32 _attribute) public view returns (uint256) {
        return attributes[_who][_attribute].timestamp;
    }

    function syncAttribute(
        bytes32 _attribute,
        uint256 _startIndex,
        address[] calldata _addresses
    ) external {
        IRegistryClone[] storage targets = subscribers[_attribute];
        uint256 index = targets.length;
        while (index-- > _startIndex) {
            IRegistryClone target = targets[index];
            for (uint256 i = _addresses.length; i-- > 0; ) {
                address who = _addresses[i];
                target.syncAttributeValue(who, _attribute, attributes[who][_attribute].value);
            }
        }
    }

    function reclaimEther(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    function reclaimToken(IERC20 token, address _to) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(_to, balance);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

// Dependency file: contracts/true-gold/common/ProxyStorage.sol

// pragma solidity 0.6.10;

contract ProxyStorage {
    // Initializable.sol
    bool _initialized;
    bool _initializing;

    // Ownable.sol
    address _owner;

    // ERC20.sol
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    uint256 _totalSupply;

    // TrueMintableBurnable.sol
    uint256 _minBurnAmount;
    uint256 _maxBurnAmount;

    /* Additionally, we have several keccak-based storage locations.
     * If you add more keccak-based storage mappings, such as mappings, you must document them here.
     * If the length of the keccak input is the same as an existing mapping, it is possible there could be a preimage collision.
     * A preimage collision can be used to attack the contract by treating one storage location as another,
     * which would always be a critical issue.
     * Carefully examine future keccak-based storage to ensure there can be no preimage collisions.
     *******************************************************************************************************
     ** length     input                                                         usage
     *******************************************************************************************************
     ** 20         "trueGold.proxy.owner"                                        Proxy Owner
     ** 28         "trueGold.pending.proxy.owner"                                Pending Proxy Owner
     ** 29         "trueGold.proxy.implementation"                               Proxy Implementation
     ** 64         uint256(address),uint256(1)                                   _balances
     ** 64         uint256(address),keccak256(uint256(address),uint256(2))       _allowances
     **/
}

// Dependency file: contracts/true-gold/common/Initializable.sol

// pragma solidity 0.6.10;

// import "contracts/true-gold/common/ProxyStorage.sol";

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
contract Initializable is ProxyStorage {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    // bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    // bool private _initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(_initializing || isConstructor() || !_initialized, "Contract instance has already been initialized");

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
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }
}

// Dependency file: contracts/true-gold/common/Ownable.sol

// pragma solidity 0.6.10;

// import "contracts/true-gold/interface/IOwnable.sol";

// import "contracts/true-gold/common/ProxyStorage.sol";
// import "contracts/true-gold/common/Initializable.sol";

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
contract Ownable is ProxyStorage, Initializable, IOwnable {
    // address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __Ownable_init_unchained() internal initializer {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Dependency file: contracts/true-gold/Reclaimable.sol

// pragma solidity 0.6.10;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import "contracts/true-gold/common/Ownable.sol";
// import "contracts/true-gold/common/ProxyStorage.sol";
// import "contracts/true-gold/interface/IOwnable.sol";

contract Reclaimable is Ownable {
    function reclaimEther(address payable to) public onlyOwner {
        to.transfer(address(this).balance);
    }

    function reclaimToken(IERC20 token, address to) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(to, balance);
    }

    function reclaimContract(IOwnable ownable) public onlyOwner {
        ownable.transferOwnership(_owner);
    }
}

// Dependency file: @openzeppelin/contracts/utils/Address.sol

// pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [// importANT]
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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
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
     * // importANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

// Dependency file: contracts/true-gold/common/ERC20.sol

// pragma solidity 0.6.10;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/utils/Address.sol";

// import "contracts/true-gold/common/ProxyStorage.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
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
abstract contract ERC20 is ProxyStorage, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    // mapping (address => uint256) private _balances;
    // mapping (address => mapping (address => uint256)) private _allowances;
    // uint256 private _totalSupply;

    /**
     * @dev Returns the name of the token.
     */
    function name() public virtual pure returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public virtual pure returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public virtual pure returns (uint8);

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
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
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public virtual override view returns (uint256) {
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
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
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
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

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
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

// Dependency file: contracts/true-gold/common/ERC20Burnable.sol

// pragma solidity 0.6.10;

// import "contracts/true-gold/common/ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, msg.sender).sub(amount, "ERC20Burnable: burn amount exceeds allowance");

        _approve(account, msg.sender, decreasedAllowance);
        _burn(account, amount);
    }
}

// Dependency file: contracts/true-gold/TrueMintableBurnable.sol

// pragma solidity 0.6.10;

// import "contracts/true-gold/common/ERC20Burnable.sol";
// import "contracts/true-gold/common/Initializable.sol";
// import "contracts/true-gold/common/Ownable.sol";
// import "contracts/true-gold/common/ProxyStorage.sol";

abstract contract TrueMintableBurnable is ProxyStorage, Initializable, Ownable, ERC20Burnable {
    uint256 constant REDEMPTION_ADDRESS_COUNT = 0x100000;

    event Mint(address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event SetBurnBounds(uint256 newMin, uint256 newMax);

    // solhint-disable-next-line func-name-mixedcase
    function __TrueMintableBurnable_init_unchained(uint256 minBurnAmount, uint256 maxBurnAmount) internal initializer {
        setBurnBounds(minBurnAmount, maxBurnAmount);
    }

    function burnMin() public view returns (uint256) {
        return _minBurnAmount;
    }

    function burnMax() public view returns (uint256) {
        return _maxBurnAmount;
    }

    // Change the minimum and maximum amount that can be burned at once. Burning may be disabled by setting both to 0
    // (this will not be done under normal operation, but we can't add checks to disallow it without losing a lot of
    // flexibility since burning could also be as good as disabled by setting the minimum extremely high, and we don't
    // want to lock in any particular cap for the minimum)
    function setBurnBounds(uint256 minAmount, uint256 maxAmount) public virtual onlyOwner {
        require(minAmount <= maxAmount, "TrueMintableBurnable: min is greater then max");
        _minBurnAmount = minAmount;
        _maxBurnAmount = maxAmount;
        emit SetBurnBounds(minAmount, maxAmount);
    }

    function mint(address account, uint256 amount) public virtual onlyOwner {
        require(uint256(account) > REDEMPTION_ADDRESS_COUNT, "TrueMintableBurnable: mint to a redemption or zero address");
        _mint(account, amount);
        emit Mint(account, amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(super.transfer(recipient, amount));
        if (uint256(recipient) <= REDEMPTION_ADDRESS_COUNT) {
            _burn(recipient, amount);
        }
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(super.transferFrom(sender, recipient, amount));
        if (uint256(recipient) <= REDEMPTION_ADDRESS_COUNT) {
            _burn(recipient, amount);
        }
        return true;
    }

    function _burn(address account, uint256 amount) internal virtual override {
        require(amount >= _minBurnAmount, "TrueMintableBurnable: burn amount below min bound");
        require(amount <= _maxBurnAmount, "TrueMintableBurnable: burn amount exceeds max bound");
        super._burn(account, amount);
        emit Burn(account, amount);
    }
}

// Dependency file: contracts/true-gold/TrueGold.sol

// pragma solidity 0.6.10;

// import "contracts/true-gold/common/Initializable.sol";
// import "contracts/true-gold/common/Ownable.sol";

// import "contracts/true-gold/Reclaimable.sol";
// import "contracts/true-gold/TrueMintableBurnable.sol";

contract TrueGold is Initializable, Ownable, TrueMintableBurnable, Reclaimable {
    using SafeMath for uint256;

    uint8 private constant DECIMALS = 6;
    uint256 private constant BURN_AMOUNT_MULTIPLIER = 12_500_000;

    function initialize(uint256 minBurnAmount, uint256 maxBurnAmount) public initializer {
        __Ownable_init_unchained();
        __TrueMintableBurnable_init_unchained(minBurnAmount, maxBurnAmount);
    }

    function decimals() public override pure returns (uint8) {
        return DECIMALS;
    }

    function name() public override pure returns (string memory) {
        return "TrueGold";
    }

    function symbol() public override pure returns (string memory) {
        return "TGLD";
    }

    function setBurnBounds(uint256 minAmount, uint256 maxAmount) public override onlyOwner {
        require(minAmount.mod(BURN_AMOUNT_MULTIPLIER) == 0, "TrueGold: min amount is not a multiple of 12,500,000");
        require(maxAmount.mod(BURN_AMOUNT_MULTIPLIER) == 0, "TrueGold: max amount is not a multiple of 12,500,000");
        super.setBurnBounds(minAmount, maxAmount);
    }

    function _burn(address account, uint256 amount) internal virtual override {
        require(amount.mod(BURN_AMOUNT_MULTIPLIER) == 0, "TrueGold: burn amount is not a multiple of 12,500,000");
        super._burn(account, amount);
    }
}

pragma solidity 0.6.10;

contract TrueGoldController {
    using SafeMath for uint256;

    struct MintOperation {
        address to;
        uint256 value;
        uint256 requestedBlock;
        uint256 numberOfApproval;
        bool paused;
        mapping(address => bool) approved;
    }

    address payable public owner;
    address payable public pendingOwner;

    bool public initialized;

    uint256 public instantMintThreshold;
    uint256 public ratifiedMintThreshold;
    uint256 public multiSigMintThreshold;

    uint256 public instantMintLimit;
    uint256 public ratifiedMintLimit;
    uint256 public multiSigMintLimit;

    uint256 public instantMintPool;
    uint256 public ratifiedMintPool;
    uint256 public multiSigMintPool;
    address[2] public ratifiedPoolRefillApprovals;

    uint8 public constant RATIFY_MINT_SIGS = 1;
    uint8 public constant MULTISIG_MINT_SIGS = 3;

    bool public mintPaused;
    uint256 public mintReqInvalidBeforeThisBlock;
    address public mintKey;
    MintOperation[] public mintOperations;

    TrueGold public token;
    Registry public registry;
    address public fastPause;

    bytes32 public constant IS_MINT_PAUSER = "isTGLDMintPauser";
    bytes32 public constant IS_MINT_RATIFIER = "isTGLDMintRatifier";

    address public constant PAUSED_IMPLEMENTATION = 0x3c8984DCE8f68FCDEEEafD9E0eca3598562eD291;

    modifier onlyFastPauseOrOwner() {
        require(msg.sender == fastPause || msg.sender == owner, "must be pauser or owner");
        _;
    }

    modifier onlyMintKeyOrOwner() {
        require(msg.sender == mintKey || msg.sender == owner, "must be mintKey or owner");
        _;
    }

    modifier onlyMintPauserOrOwner() {
        require(registry.hasAttribute(msg.sender, IS_MINT_PAUSER) || msg.sender == owner, "must be pauser or owner");
        _;
    }

    modifier onlyMintRatifierOrOwner() {
        require(registry.hasAttribute(msg.sender, IS_MINT_RATIFIER) || msg.sender == owner, "must be ratifier or owner");
        _;
    }

    modifier mintNotPaused() {
        if (msg.sender != owner) {
            require(!mintPaused, "minting is paused");
        }
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event NewOwnerPending(address indexed currentOwner, address indexed pendingOwner);
    event SetRegistry(address indexed registry);
    event TransferChild(address indexed child, address indexed newOwner);
    event ReclaimContract(address indexed other);
    event SetToken(TrueGold newContract);

    event RequestMint(address indexed to, uint256 indexed value, uint256 opIndex, address mintKey);
    event FinalizeMint(address indexed to, uint256 indexed value, uint256 opIndex, address mintKey);
    event InstantMint(address indexed to, uint256 indexed value, address indexed mintKey);

    event TransferMintKey(address indexed previousMintKey, address indexed newMintKey);
    event MintRatified(uint256 indexed opIndex, address indexed ratifier);
    event RevokeMint(uint256 opIndex);
    event AllMintsPaused(bool status);
    event MintPaused(uint256 opIndex, bool status);
    event FastPauseSet(address _newFastPause);

    event MintThresholdChanged(uint256 instant, uint256 ratified, uint256 multiSig);
    event MintLimitsChanged(uint256 instant, uint256 ratified, uint256 multiSig);
    event InstantPoolRefilled();
    event RatifyPoolRefilled();
    event MultiSigPoolRefilled();

    function initialize() external {
        require(!initialized, "already initialized");
        owner = msg.sender;
        initialized = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }

    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "only Pending Owner");
        _;
    }

    function transferOwnership(address payable newOwner) external onlyOwner {
        pendingOwner = newOwner;
        emit NewOwnerPending(address(owner), address(pendingOwner));
    }

    function claimOwnership() external onlyPendingOwner {
        emit OwnershipTransferred(address(owner), address(pendingOwner));
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    function transferTokenProxyOwnership(address _newOwner) external onlyOwner {
        OwnedUpgradeabilityProxy(address(uint160(address(token)))).transferProxyOwnership(_newOwner);
    }

    function claimTokenProxyOwnership() external onlyOwner {
        OwnedUpgradeabilityProxy(address(uint160(address(token)))).claimProxyOwnership();
    }

    function upgradeTokenProxyImplTo(address _implementation) external onlyOwner {
        OwnedUpgradeabilityProxy(address(uint160(address(token)))).upgradeTo(_implementation);
    }

    function setMintThresholds(
        uint256 _instant,
        uint256 _ratified,
        uint256 _multiSig
    ) external onlyOwner {
        require(_instant <= _ratified && _ratified <= _multiSig);
        instantMintThreshold = _instant;
        ratifiedMintThreshold = _ratified;
        multiSigMintThreshold = _multiSig;
        emit MintThresholdChanged(_instant, _ratified, _multiSig);
    }

    function setMintLimits(
        uint256 _instant,
        uint256 _ratified,
        uint256 _multiSig
    ) external onlyOwner {
        require(_instant <= _ratified && _ratified <= _multiSig);
        instantMintLimit = _instant;
        if (instantMintPool > instantMintLimit) {
            instantMintPool = instantMintLimit;
        }
        ratifiedMintLimit = _ratified;
        if (ratifiedMintPool > ratifiedMintLimit) {
            ratifiedMintPool = ratifiedMintLimit;
        }
        multiSigMintLimit = _multiSig;
        if (multiSigMintPool > multiSigMintLimit) {
            multiSigMintPool = multiSigMintLimit;
        }
        emit MintLimitsChanged(_instant, _ratified, _multiSig);
    }

    function refillInstantMintPool() external onlyMintRatifierOrOwner {
        ratifiedMintPool = ratifiedMintPool.sub(instantMintLimit.sub(instantMintPool));
        instantMintPool = instantMintLimit;
        emit InstantPoolRefilled();
    }

    function refillRatifiedMintPool() external onlyMintRatifierOrOwner {
        if (msg.sender != owner) {
            address[2] memory refillApprovals = ratifiedPoolRefillApprovals;
            require(msg.sender != refillApprovals[0] && msg.sender != refillApprovals[1]);
            if (refillApprovals[0] == address(0)) {
                ratifiedPoolRefillApprovals[0] = msg.sender;
                return;
            }
            if (refillApprovals[1] == address(0)) {
                ratifiedPoolRefillApprovals[1] = msg.sender;
                return;
            }
        }
        delete ratifiedPoolRefillApprovals;
        multiSigMintPool = multiSigMintPool.sub(ratifiedMintLimit.sub(ratifiedMintPool));
        ratifiedMintPool = ratifiedMintLimit;
        emit RatifyPoolRefilled();
    }

    function refillMultiSigMintPool() external onlyOwner {
        multiSigMintPool = multiSigMintLimit;
        emit MultiSigPoolRefilled();
    }

    function requestMint(address _to, uint256 _value) external mintNotPaused onlyMintKeyOrOwner {
        MintOperation memory op = MintOperation(_to, _value, block.number, 0, false);
        emit RequestMint(_to, _value, mintOperations.length, msg.sender);
        mintOperations.push(op);
    }

    function instantMint(address _to, uint256 _value) external mintNotPaused onlyMintKeyOrOwner {
        require(_value <= instantMintThreshold, "over the instant mint threshold");
        require(_value <= instantMintPool, "instant mint pool is dry");
        instantMintPool = instantMintPool.sub(_value);
        emit InstantMint(_to, _value, msg.sender);
        token.mint(_to, _value);
    }

    function ratifyMint(
        uint256 _index,
        address _to,
        uint256 _value
    ) external mintNotPaused onlyMintRatifierOrOwner {
        MintOperation memory op = mintOperations[_index];
        require(op.to == _to, "to address does not match");
        require(op.value == _value, "amount does not match");
        require(!mintOperations[_index].approved[msg.sender], "already approved");
        mintOperations[_index].approved[msg.sender] = true;
        mintOperations[_index].numberOfApproval = mintOperations[_index].numberOfApproval.add(1);
        emit MintRatified(_index, msg.sender);
        if (hasEnoughApproval(mintOperations[_index].numberOfApproval, _value)) {
            finalizeMint(_index);
        }
    }

    function finalizeMint(uint256 _index) public mintNotPaused {
        MintOperation memory op = mintOperations[_index];
        address to = op.to;
        uint256 value = op.value;
        if (msg.sender != owner) {
            require(canFinalize(_index));
            _subtractFromMintPool(value);
        }
        delete mintOperations[_index];
        token.mint(to, value);
        emit FinalizeMint(to, value, _index, msg.sender);
    }

    function _subtractFromMintPool(uint256 _value) internal {
        if (_value <= ratifiedMintPool && _value <= ratifiedMintThreshold) {
            ratifiedMintPool = ratifiedMintPool.sub(_value);
        } else {
            multiSigMintPool = multiSigMintPool.sub(_value);
        }
    }

    function hasEnoughApproval(uint256 _numberOfApproval, uint256 _value) public view returns (bool) {
        if (_value <= ratifiedMintPool && _value <= ratifiedMintThreshold) {
            if (_numberOfApproval >= RATIFY_MINT_SIGS) {
                return true;
            }
        }
        if (_value <= multiSigMintPool && _value <= multiSigMintThreshold) {
            if (_numberOfApproval >= MULTISIG_MINT_SIGS) {
                return true;
            }
        }
        if (msg.sender == owner) {
            return true;
        }
        return false;
    }

    function canFinalize(uint256 _index) public view returns (bool) {
        MintOperation memory op = mintOperations[_index];
        require(op.requestedBlock > mintReqInvalidBeforeThisBlock, "this mint is invalid");
        require(!op.paused, "this mint is paused");
        require(hasEnoughApproval(op.numberOfApproval, op.value), "not enough approvals");
        return true;
    }

    function revokeMint(uint256 _index) external onlyMintKeyOrOwner {
        delete mintOperations[_index];
        emit RevokeMint(_index);
    }

    function mintOperationCount() public view returns (uint256) {
        return mintOperations.length;
    }

    function transferMintKey(address _newMintKey) external onlyOwner {
        require(_newMintKey != address(0), "new mint key cannot be 0x0");
        emit TransferMintKey(mintKey, _newMintKey);
        mintKey = _newMintKey;
    }

    function invalidateAllPendingMints() external onlyOwner {
        mintReqInvalidBeforeThisBlock = block.number;
    }

    function pauseMints() external onlyMintPauserOrOwner {
        mintPaused = true;
        emit AllMintsPaused(true);
    }

    function unpauseMints() external onlyOwner {
        mintPaused = false;
        emit AllMintsPaused(false);
    }

    function pauseMint(uint256 _opIndex) external onlyMintPauserOrOwner {
        mintOperations[_opIndex].paused = true;
        emit MintPaused(_opIndex, true);
    }

    function unpauseMint(uint256 _opIndex) external onlyOwner {
        mintOperations[_opIndex].paused = false;
        emit MintPaused(_opIndex, false);
    }

    function setToken(TrueGold _newContract) external onlyOwner {
        token = _newContract;
        emit SetToken(_newContract);
    }

    function setRegistry(Registry _registry) external onlyOwner {
        registry = _registry;
        emit SetRegistry(address(registry));
    }

    function transferChild(IOwnable _child, address _newOwner) external onlyOwner {
        _child.transferOwnership(_newOwner);
        emit TransferChild(address(_child), _newOwner);
    }

    function requestReclaimContract(IOwnable _other) public onlyOwner {
        token.reclaimContract(_other);
        emit ReclaimContract(address(_other));
    }

    function requestReclaimEther() external onlyOwner {
        token.reclaimEther(owner);
    }

    function requestReclaimToken(IERC20 _token) external onlyOwner {
        token.reclaimToken(_token, owner);
    }

    function setFastPause(address _newFastPause) external onlyOwner {
        fastPause = _newFastPause;
        emit FastPauseSet(address(_newFastPause));
    }

    function pauseToken() external virtual onlyFastPauseOrOwner {
        OwnedUpgradeabilityProxy(address(uint160(address(token)))).upgradeTo(PAUSED_IMPLEMENTATION);
    }

    function setBurnBounds(uint256 _min, uint256 _max) external onlyOwner {
        token.setBurnBounds(_min, _max);
    }

    function reclaimEther(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    function reclaimToken(IERC20 _token, address _to) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        _token.transfer(_to, balance);
    }
}