/*
Factory

https://github.com/0chain/nft-dstorage-core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IFactoryModule.sol";

contract Factory is Ownable {
    // events
    event TokenCreated(address indexed owner, address token);
    event ModuleRegistered(address indexed module, bool status);

    // fields
    address[] public tokenList;
    mapping(address => bool) public tokenMapping;
    mapping(address => bool) public moduleRegistry;

    /**
     * @notice create a new dStorage NFT contract
     * @param module address of factory module
     * @param name token name
     * @param symbol token symbol
     * @param uri original base token uri
     * @param data additional encoded data
     * @return address of newly created token
     */
    function create(
        address module,
        string calldata name,
        string calldata symbol,
        string calldata uri,
        bytes calldata data
    ) external returns (address) {
        // verify module
        require(moduleRegistry[module], "Factory: module not registered");

        // create nft
        address token = IFactoryModule(module).createToken(
            name,
            symbol,
            uri,
            data
        );

        // ownership
        Ownable(token).transferOwnership(msg.sender);

        // accounting
        tokenList.push(token);
        tokenMapping[token] = true;

        // output
        emit TokenCreated(msg.sender, token);
        return token;
    }

    /**
     * @notice set the registry status of a factory module
     * @param module address of module
     * @param status updated registry status
     */
    function register(address module, bool status) external onlyOwner {
        require(module != address(0), "Factory: module address cannot be zero");
        moduleRegistry[module] = status;
        emit ModuleRegistered(module, status);
    }

    /**
     * @return total number of tokens created by the factory
     */
    function count() public view returns (uint256) {
        return tokenList.length;
    }
}

/*
IFactoryModule

https://github.com/0chain/nft-dstorage-core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.9;

/**
 * @title Factory module interface
 *
 * @notice this defines the interface for a module which creates a specific
 * version of the dStorage NFT contract
 */
interface IFactoryModule {
    /**
     * @notice create a new nft contract
     * @param name token name
     * @param symbol token symbol
     * @param uri original base token uri
     * @param data additional encoded data
     * @return address of newly created token
     */
    function createToken(
        string calldata name,
        string calldata symbol,
        string calldata uri,
        bytes calldata data
    ) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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