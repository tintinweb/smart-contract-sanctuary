// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "DataTypesInterface.sol";
import "Ownable.sol";

contract PersonalData is Ownable {
    address public userAddress;
    address public serviceAddress;
    address public dataTypesAddress;
    DataTypesInterface public dataTypes;
    string public serviceName;
    uint256 public requestCounter;
    uint256 public dataTypesCounter;

    enum STATE {
        OPEN,
        CLOSE
    }

    struct DataTypesUsed {
        string dataType;
        STATE state;
    }
    mapping(uint256 => DataTypesUsed) public dataTypesUsed;

    constructor(
        address _serviceAddress,
        address _userAddress,
        address _dataTypesAddress,
        string memory _serviceName
    ) {
        serviceAddress = _serviceAddress;
        userAddress = _userAddress;
        dataTypesAddress = _dataTypesAddress;
        dataTypes = DataTypesInterface(dataTypesAddress);
        serviceName = _serviceName;
    }

    /*
     * Service meta modififcations
     */

    function updateServiceName(string memory _serviceName) public {
        serviceName = _serviceName;
    }

    function transferServiceOwnership(address _serviceAddress) public {
        serviceAddress = _serviceAddress;
    }

    /*
     * Adding new data types used is using
     */

    function checkDataTypeExistence(string memory _dt)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < dataTypes.retrieveDataTypes().length; i++) {
            if (
                keccak256(bytes(_dt)) ==
                keccak256(bytes(dataTypes.retrieveDataTypes()[i]))
            ) {
                return true;
            }
        }
        return false;
    }

    function checkDataTypeUsed(string memory _dt) private view returns (bool) {
        for (uint256 i = 0; i < dataTypesCounter; i++) {
            if (
                keccak256(bytes(_dt)) ==
                keccak256(bytes(dataTypesUsed[i].dataType))
            ) {
                return false;
            }
        }
        return true;
    }

    function addDataType(string memory _dt) public {
        require(checkDataTypeExistence(_dt), "Data Type is not permitted.");
        //require(checkDataTypeUsed(_dt), "Data Type is already used.");
        DataTypesUsed memory newDataTypesUsed = DataTypesUsed(_dt, STATE.CLOSE);
        dataTypesUsed[dataTypesCounter] = newDataTypesUsed;
    }

    function retrieveDataTypes() public view returns (string[] memory) {
        return dataTypes.retrieveDataTypes();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface DataTypesInterface {
    function setDataTypes(uint256) external;
    function retrieveDataTypes() external view returns (string[] memory);
}

// SPDX-License-Identifier: MIT

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