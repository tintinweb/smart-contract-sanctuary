// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.6.10;

import "Ownable.sol";
import "AddressStorage.sol";

/**
 * @title AddressRepository
 * @notice Stores addresses of deployed contracts
 * @author Platinum Forked
 */
contract AddressRepository is Ownable, AddressStorage {
    // Repositories & services
    bytes32 private constant POOL_REPOSITORY = "POOL_REPOSITORY";
    bytes32 private constant POSITION_REPOSITORY = "POSITION_REPOSITORY";
    bytes32 private constant PRICE_REPOSITORY = "PRICE_REPOSITORY";

    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempString = bytes(source);
        require(tempString.length != 0, "Empty string");

        assembly {
            result := mload(add(source, 32))
        }
    }

    function getPoolRepository() public view returns (address) {
        return getAddress(POOL_REPOSITORY);
    }

    function setPoolRepository(address _address) public onlyOwner {
        _setAddress(POOL_REPOSITORY, _address);
    }

    function getPositionRepository() public view returns (address) {
        return getAddress(POSITION_REPOSITORY);
    }

    function setPositionRepository(address _address) public onlyOwner {
        _setAddress(POSITION_REPOSITORY, _address);
    }

    function getPriceRepository() public view returns (address) {
        return getAddress(PRICE_REPOSITORY);
    }

    function setPriceRepository(address _address) public onlyOwner {
        _setAddress(PRICE_REPOSITORY, _address);
    }

    function getRouter(string memory _router) public view returns (address) {
        bytes32 router = stringToBytes32(_router);
        return getAddress(router);
    }

    function setRouter(address _address, string memory _router) public onlyOwner {
        bytes32 router = stringToBytes32(_router);
        _setAddress(router, _address);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.6.10;

contract AddressStorage {
    mapping(bytes32 => address) private _addresses;

    function getAddress(bytes32 key) public view returns (address) {
        address result = _addresses[key];
        require(result != address(0), "AddressStorage: Address not found");
        return result;
    }

    function _setAddress(bytes32 key, address value) internal {
        _addresses[key] = value;
    }

}