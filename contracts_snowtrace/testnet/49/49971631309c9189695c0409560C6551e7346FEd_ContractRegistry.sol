// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "Ownable.sol";
import "IContractRegistry.sol";


contract ContractRegistry is Ownable, IContractRegistry {

    mapping(string => address) private _nameToAddress;
    mapping(address => string) private _addressToName;

    modifier registeredName(string memory name) {
        require(
            bytes(name).length > 0,
            "ContractRegistry: contract name must not be empty"
        );
        require(
            _nameToAddress[name] != address(0),
            "ContractRegistry: contract name is not registered"
        );
        _;
    }

    modifier registeredAddress(address _address) {
        require(
            _address != address(0),
            "ContractRegistry: contract address is invalid"
        );
        require(
            bytes(_addressToName[_address]).length != 0,
            "ContractRegistry: contract address is not registered"
        );
        _;
    }

    modifier notRegisteredName(string memory name) {
        require(
            bytes(name).length > 0,
            "ContractRegistry: contract name must not be empty"
        );
        require(
            _nameToAddress[name] == address(0),
            "ContractRegistry: contract name is registered"
        );
        _;
    }

    modifier notRegisteredAddress(address _address) {
        require(
            _address != address(0),
            "ContractRegistry: contract address is invalid"
        );
        require(
            bytes(_addressToName[_address]).length == 0,
            "ContractRegistry: contract address is registered"
        );
        _;
    }

    constructor(address owner) {
        transferOwnership(owner);
    }

    function registerContract(
        string memory name, 
        address _address
    ) 
        external
        override onlyOwner notRegisteredName(name) notRegisteredAddress(_address)
    {
        _nameToAddress[name] = _address;
        _addressToName[_address] = name;

        emit RegisterContract(name, _address);
    }

    function removeContract(
        string memory name,
        address _address
    )
        external override onlyOwner registeredName(name) registeredAddress(_address)
    {
        delete _nameToAddress[name];
        delete _addressToName[_address];
        emit RemoveContract(name, _address);
    }

    function getContractAddress(
        string memory name
    ) 
        external override view returns(address) 
    {
        return _nameToAddress[name];
    }

    function getContractName(
        address _address
    )
        external override view returns(string memory name)
    {
        return _addressToName[_address];
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
pragma solidity 0.8.11;

interface  IContractRegistry {

    // Declare events
    event RegisterContract(string name, address indexed _address);
    event RemoveContract(string name, address indexed _address);

    // Declare Functions
    function registerContract(string memory name, address _address) external;
    function removeContract(string memory name, address _address) external;

    function getContractAddress(string memory name) external view returns (address);
    function getContractName(address _address) external view returns (string memory name);

}