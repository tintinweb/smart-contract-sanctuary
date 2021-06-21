/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

// File: contracts/interface/IRegistry.sol

pragma solidity ^0.6.0;

interface IRegistry {
    function handlers(address) external view returns (bytes32);
    function callers(address) external view returns (bytes32);
    function bannedAgents(address) external view returns (uint256);
    function fHalt() external view returns (bool);
    function isValidHandler(address handler) external view returns (bool);
    function isValidCaller(address handler) external view returns (bool);
}

// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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
}

// File: contracts/Registry.sol

pragma solidity ^0.6.0;



/// @notice The registry database for Furucombo
contract Registry is IRegistry, Ownable {
    mapping(address => bytes32) public override handlers;
    mapping(address => bytes32) public override callers;
    mapping(address => uint256) public override bannedAgents;
    bool public override fHalt;

    bytes32 public constant DEPRECATED = bytes10(0x64657072656361746564);

    event Registered(address indexed registration, bytes32 info);
    event Unregistered(address indexed registration);
    event CallerRegistered(address indexed registration, bytes32 info);
    event CallerUnregistered(address indexed registration);
    event Banned(address indexed agent);
    event Unbanned(address indexed agent);
    event Halted();
    event Unhalted();

    modifier isNotHalted() {
        require(fHalt == false, "Halted");
        _;
    }

    modifier isHalted() {
        require(fHalt, "Not halted");
        _;
    }

    modifier isNotBanned(address agent) {
        require(bannedAgents[agent] == 0, "Banned");
        _;
    }

    modifier isBanned(address agent) {
        require(bannedAgents[agent] != 0, "Not banned");
        _;
    }

    /**
     * @notice Register a handler with a bytes32 information.
     * @param registration Handler address.
     * @param info Info string.
     */
    function register(address registration, bytes32 info) external onlyOwner {
        require(registration != address(0), "zero address");
        require(info != DEPRECATED, "unregistered info");
        require(handlers[registration] != DEPRECATED, "unregistered");
        handlers[registration] = info;
        emit Registered(registration, info);
    }

    /**
     * @notice Unregister a handler. The handler will be deprecated.
     * @param registration The handler to be unregistered.
     */
    function unregister(address registration) external onlyOwner {
        require(registration != address(0), "zero address");
        require(handlers[registration] != bytes32(0), "no registration");
        require(handlers[registration] != DEPRECATED, "unregistered");
        handlers[registration] = DEPRECATED;
        emit Unregistered(registration);
    }

    /**
     * @notice Register a caller with a bytes32 information.
     * @param registration Caller address.
     * @param info Info string.
     * @dev Dapps that triggers callback function should be registered.
     * In this case, registration is the Dapp address and the leading 20 bytes
     * of info is the handler address.
     */
    function registerCaller(address registration, bytes32 info)
        external
        onlyOwner
    {
        require(registration != address(0), "zero address");
        require(info != DEPRECATED, "unregistered info");
        require(callers[registration] != DEPRECATED, "unregistered");
        callers[registration] = info;
        emit CallerRegistered(registration, info);
    }

    /**
     * @notice Unregister a caller. The caller will be deprecated.
     * @param registration The caller to be unregistered.
     */
    function unregisterCaller(address registration) external onlyOwner {
        require(registration != address(0), "zero address");
        require(callers[registration] != bytes32(0), "no registration");
        require(callers[registration] != DEPRECATED, "unregistered");
        callers[registration] = DEPRECATED;
        emit CallerUnregistered(registration);
    }

    /**
     * @notice Ban agent from query
     *
     */
    function ban(address agent) external isNotBanned(agent) onlyOwner {
        bannedAgents[agent] = 1;
        emit Banned(agent);
    }

    /**
     * @notice Unban agent from query
     */
    function unban(address agent) external isBanned(agent) onlyOwner {
        bannedAgents[agent] = 0;
        emit Unbanned(agent);
    }

    /**
     * @notice Check if the handler is valid.
     * @param handler The handler to be verified.
     */
    function isValidHandler(address handler)
        external
        view
        override
        returns (bool)
    {
        return handlers[handler] != 0 && handlers[handler] != DEPRECATED;
    }

    /**
     * @notice Check if the caller is valid.
     * @param caller The caller to be verified.
     */
    function isValidCaller(address caller)
        external
        view
        override
        returns (bool)
    {
        return callers[caller] != 0 && callers[caller] != DEPRECATED;
    }

    function halt() external isNotHalted onlyOwner {
        fHalt = true;
        emit Halted();
    }

    function unhalt() external isHalted onlyOwner {
        fHalt = false;
        emit Unhalted();
    }
}