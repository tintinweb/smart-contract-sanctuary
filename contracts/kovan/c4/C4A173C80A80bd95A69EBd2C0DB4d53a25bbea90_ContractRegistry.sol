// SPDX-License-Identifier: MIT

pragma solidity >=0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IContractRegistry.sol";

/// @title  ContractRegistry
/// @notice Address registry for all project contract addresses.
/// @dev    Addresses are registered as a mapping name --> address
contract ContractRegistry is Ownable, IContractRegistry {

    event LogRegistered(address indexed destination, bytes32 name);

    /// @notice registry name --> address map
    mapping(bytes32 => address) public registry;


    /// @notice Batch register of (name,address) pairs in the contract registry
    /// @dev    Called by the owner. The names and addresses needs to be of same length.
    /// @param  _names Array of names
    /// @param  _destinations Array of addresses for the contracts
    function importAddresses(bytes32[] calldata _names, address[] calldata _destinations) external onlyOwner {
        require(_names.length == _destinations.length, "ERR_INVALID_LENGTH");

        for (uint i = 0; i < _names.length; i++) {
            registry[_names[i]] = _destinations[i];
            emit LogRegistered(_destinations[i], _names[i]);
        }
    }

    /// @notice Gets a contract address by a given name
    /// @param  _bytes name in bytes
    /// @return contract address, address(0) if not found
    function getAddress(bytes32 _bytes) external override view returns (address) {
        return registry[_bytes];
    }

    /// @notice Gets a contract address by a given name
    /// @param  name name in bytes
    /// @return contract address, fails if not found
    function requireAndGetAddress(bytes32 name) public override view returns (address) {
        address _foundAddress = registry[name];
        require(_foundAddress != address(0), string(abi.encodePacked("Name not registered: ", name)));
        return _foundAddress;
    }

    /// @notice Gets a contract address by a given name as string
    /// @param  _name contract name
    /// @return contract address, address(0) if not found
    function getAddressByString(string memory _name) public view returns (address) {
        return registry[stringToBytes32(_name)];
    }


    /// @notice Converts string to bytes32
    /// @param  _string String to convert
    /// @return result bytes32
    function stringToBytes32(string memory _string) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(_string);

        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(_string, 32))
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.5;

interface IContractRegistry {

    function getAddress(bytes32 name) external view returns (address);

    function requireAndGetAddress(bytes32 name) external view returns (address);

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

