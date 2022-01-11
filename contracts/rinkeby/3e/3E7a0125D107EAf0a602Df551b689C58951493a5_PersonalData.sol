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
    uint256 public userRequestsCounter;
    uint256 public serviceRequestsCounter;
    string[] public dataTypesUsedList;

    enum STATE {
        OPEN,
        CLOSE
    }
    enum DATA_STATE {
        DELETED,
        INTACT
    }
    enum REQUEST_STATE {
        PENDING,
        SUCCESS,
        FAILURE
    }
    enum REQUEST_TYPE {
        DELETE,
        SHARE,
        CLOSE,
        OPEN
    }

    struct DataTypesUsed {
        string dataType;
        STATE state;
        DATA_STATE dataState;
        bool isValue;
    }

    struct Request {
        string dataType;
        REQUEST_STATE state;
        REQUEST_TYPE requestType;
        STATE stateRequestCreation;
        DATA_STATE dataStateRequestCreation;
    }

    mapping(string => DataTypesUsed) public dataTypesUsed;
    mapping(uint256 => Request) public userRequests;
    mapping(uint256 => Request) public serviceRequests;

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
        userRequestsCounter = 0;
        serviceRequestsCounter = 0;
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
    function addDataType(
        string memory _dt,
        STATE state,
        DATA_STATE dataState
    ) public {
        require(
            dataTypes.checkDataTypeExistence(_dt),
            "Data Type is not permitted."
        );
        require(!dataTypesUsed[_dt].isValue, "Data Type already in use.");
        DataTypesUsed memory newDataTypesUsed = DataTypesUsed(
            _dt,
            state,
            dataState,
            true
        );
        dataTypesUsed[_dt] = newDataTypesUsed;
        dataTypesUsedList.push(_dt);
    }

    /*
     * User making request from service
     */
    function checkUserRequestValidity(
        string memory _dt,
        REQUEST_TYPE requestType
    ) private view returns (bool) {
        if (
            dataTypesUsed[_dt].state == STATE.OPEN &&
            dataTypesUsed[_dt].dataState == DATA_STATE.DELETED
        ) {
            return false;
        }
        if (
            dataTypesUsed[_dt].state == STATE.CLOSE &&
            dataTypesUsed[_dt].dataState == DATA_STATE.DELETED
        ) {
            return false;
        }
        if (
            dataTypesUsed[_dt].state == STATE.OPEN &&
            dataTypesUsed[_dt].dataState == DATA_STATE.INTACT &&
            (requestType != REQUEST_TYPE.SHARE &&
                requestType != REQUEST_TYPE.CLOSE)
        ) {
            return false;
        }
        if (
            dataTypesUsed[_dt].state == STATE.CLOSE &&
            dataTypesUsed[_dt].dataState == DATA_STATE.INTACT &&
            (requestType != REQUEST_TYPE.SHARE &&
                requestType != REQUEST_TYPE.DELETE)
        ) {
            return false;
        }
        return true;
    }

    function createRequestFromUser(string memory _dt, REQUEST_TYPE requestType)
        public
    {
        require(
            dataTypes.checkDataTypeExistence(_dt),
            "Data Type is not permitted."
        );
        require(dataTypesUsed[_dt].isValue, "Data Type not in use.");
        require(checkUserRequestValidity(_dt, requestType), "Invalid request.");
        Request memory newRequest = Request(
            _dt,
            REQUEST_STATE.PENDING,
            requestType,
            dataTypesUsed[_dt].state,
            dataTypesUsed[_dt].dataState
        );
        userRequests[userRequestsCounter] = newRequest;
        userRequestsCounter += 1;
    }

    /*
     * Service making request from user
     */
    function checkServiceRequestValidity(
        string memory _dt,
        REQUEST_TYPE requestType
    ) private view returns (bool) {
        if (
            dataTypesUsed[_dt].state == STATE.OPEN &&
            dataTypesUsed[_dt].dataState == DATA_STATE.INTACT
        ) {
            return false;
        }
        if (
            dataTypesUsed[_dt].state == STATE.OPEN &&
            dataTypesUsed[_dt].dataState == DATA_STATE.DELETED
        ) {
            return false;
        }
        if (
            dataTypesUsed[_dt].state == STATE.CLOSE &&
            dataTypesUsed[_dt].dataState == DATA_STATE.INTACT &&
            requestType != REQUEST_TYPE.OPEN
        ) {
            return false;
        }
        if (
            dataTypesUsed[_dt].state == STATE.CLOSE &&
            dataTypesUsed[_dt].dataState == DATA_STATE.DELETED &&
            requestType != REQUEST_TYPE.OPEN
        ) {
            return false;
        }
        return true;
    }

    function createRequestFromService(
        string memory _dt,
        REQUEST_TYPE requestType
    ) public {
        require(!dataTypes.checkDataTypeExistence(_dt) && requestType != REQUEST_TYPE.OPEN, "Invalid request.");
        require(checkServiceRequestValidity(_dt, requestType), "Invalid request.");
        Request memory newRequest = Request(
            _dt,
            REQUEST_STATE.PENDING,
            requestType,
            dataTypesUsed[_dt].state,
            dataTypesUsed[_dt].dataState
        );
        serviceRequests[serviceRequestsCounter] = newRequest;
        serviceRequestsCounter += 1;
        
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface DataTypesInterface {
    function setDataTypes(uint256) external;

    function checkDataTypeExistence(string memory) external view returns (bool);
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