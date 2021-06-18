/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// File: openzeppelin-solidity/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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
     * NOTE: Renouncing ownership will leave the contract without an owner,
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: opium-contracts/contracts/Interface/IOracleId.sol

pragma solidity 0.5.16;

/// @title Opium.Interface.IOracleId contract is an interface that every oracleId should implement
interface IOracleId {
    /// @notice Requests data from `oracleId` one time
    /// @param timestamp uint256 Timestamp at which data are needed
    function fetchData(uint256 timestamp) external payable;

    /// @notice Requests data from `oracleId` multiple times
    /// @param timestamp uint256 Timestamp at which data are needed for the first time
    /// @param period uint256 Period in seconds between multiple timestamps
    /// @param times uint256 How many timestamps are requested
    function recursivelyFetchData(uint256 timestamp, uint256 period, uint256 times) external payable;

    /// @notice Requests and returns price in ETH for one request. This function could be called as `view` function. Oraclize API for price calculations restricts making this function as view.
    /// @return fetchPrice uint256 Price of one data request in ETH
    function calculateFetchPrice() external returns (uint256 fetchPrice);

    // Event with oracleId metadata JSON string (for DIB.ONE derivative explorer)
    event MetadataSet(string metadata);
}

// File: contracts/oracles/dao/DaoOracleId.sol

pragma solidity 0.5.16;



interface IOracleAggregator {
  function __callback(uint256 timestamp, uint256 data) external;
  function hasData(address oracleId, uint256 timestamp) external view returns(bool result);
}

contract DaoOracleId is IOracleId, Ownable {
  event Provided(uint256 indexed timestamp, uint256 result);

  // Opium
  IOracleAggregator public oracleAggregator;

  // Cache
  uint256 latestResult;
  bool latestResultExist = false;

  constructor(IOracleAggregator _oracleAggregator) public {
    oracleAggregator = _oracleAggregator;

    /*
    {
      "author": "Opium.Team",
      "description": "Opium DAO Oracle",
      "asset": "any",
      "type": "dao",
      "source": "opiumteam",
      "logic": "none",
      "path": "none"
    }
    */
    emit MetadataSet("{\"author\":\"Opium.Team\",\"description\":\"Opium DAO Oracle\",\"asset\":\"any\",\"type\":\"dao\",\"source\":\"opiumteam\",\"logic\":\"none\",\"path\":\"none\"}");
  }

  /** OPIUM */
  function fetchData(uint256 _timestamp) external payable {
    _timestamp;
    revert("N.S"); // N.S = not supported
  }

  function recursivelyFetchData(uint256 _timestamp, uint256 _period, uint256 _times) external payable {
    _timestamp;
    _period;
    _times;
    revert("N.S"); // N.S = not supported
  }

  function calculateFetchPrice() external returns (uint256) {
    return 0;
  }
  
  function _callback(uint256 _timestamp, uint256 _result) public onlyOwner {
    require(
      !oracleAggregator.hasData(address(this), _timestamp) &&
      _timestamp < now,
      "N.A" // N.A = Only when no data and after timestamp allowed
    );

    oracleAggregator.__callback(_timestamp, _result);

    // Cache latest result
    latestResult = _result;
    if (!latestResultExist) {
      latestResultExist = true;
    }

    emit Provided(_timestamp, _result);
  }

  function getResult() public view returns (uint256) {
    require(latestResultExist, "N.R"); // N.R = No result
    return latestResult;
  } 
}