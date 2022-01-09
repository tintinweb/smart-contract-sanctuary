/**
 *Submitted for verification at polygonscan.com on 2022-01-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easilly be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}
enum Tranche {
  JUNIOR,
  SENIOR
}

interface ILendingPool {
  function init(
    address _jCopToken,
    address _sCopToken,
    address _copraGlobal,
    address _copToken,
    address _loanNFT
  ) external;

  function registerLoan(bytes calldata _loan) external;

  function payLoan(uint256 _loanID, uint256 _amount) external;

  function disburseLoan(uint256 _loanID) external;

  function updateLoan(uint256 _loanID) external;

  function deposit(Tranche _tranche, uint256 _amount) external;

  function withdraw(Tranche _tranche, uint256 _amount) external;

  function getOriginator() external view returns (address);

  function updateSeniorObligation() external;

  function getLastUpdatedAt() external view returns (uint256);
}

interface ILendingPoolRegistry {
  function whitelistPool(
    address _lpAddress,
    string calldata _jCopName,
    string calldata _jCopSymbol,
    string calldata _sCopName,
    string calldata _sCopSymbol
  ) external;

  function closePool(address _lpAddress) external;

  function openPool(address _lpAddress) external;

  function registerPool(address _lpAddress) external;

  function isWhitelisted(address _lpAddress) external view returns (bool);

  function getNumWhitelistedPools() external view returns (uint256);

  function getPools() external view returns (address[] memory);

  function isRegisteredPool(address _lpAddress) external view returns (bool);
}

contract LendingPoolSeniorObligationUpdater is KeeperCompatibleInterface, Ownable {
  uint256 public maxPoolsToUpdate;
  uint256 public secondsUntilNextRetry;

  address public lendingPoolRegistryAddress;
  mapping(address => uint256) nextRetry;

  constructor(
    address _lendingPoolRegistryAddress,
    uint256 _maxPoolsToUpdate,
    uint256 _secondsUntilNextRetry
  ) {
    lendingPoolRegistryAddress = _lendingPoolRegistryAddress;
    maxPoolsToUpdate = _maxPoolsToUpdate;
    secondsUntilNextRetry = _secondsUntilNextRetry;
  }

  function setMaxPoolsToUpdate(uint256 _maxPoolsToUpdate) external onlyOwner {
    maxPoolsToUpdate = _maxPoolsToUpdate;
  }

  function setSecondsUntilNextRetry(uint256 _secondsUntilNextRetry) external onlyOwner {
    secondsUntilNextRetry = _secondsUntilNextRetry;
  }

  function checkUpkeep(
    bytes calldata /* checkData */
  ) external view override returns (bool upkeepNeeded, bytes memory performData) {
    ILendingPoolRegistry lendingPoolRegistry = (ILendingPoolRegistry(lendingPoolRegistryAddress));
    address[] memory poolAddresses = lendingPoolRegistry.getPools();
    address[] memory poolAddressesToUpdate = new address[](maxPoolsToUpdate);
    uint256 numPoolsToUpdate = 0;
    uint256 counter = 0;

    while (numPoolsToUpdate < maxPoolsToUpdate && counter < poolAddresses.length) {
      address poolAddress = poolAddresses[counter];
      uint256 lastTimeUpdated = (ILendingPool(poolAddress)).getLastUpdatedAt();
      if (block.timestamp >= lastTimeUpdated + 1 days && _isAfterRetryTime(poolAddress)) {
        poolAddressesToUpdate[numPoolsToUpdate] = poolAddress;
        numPoolsToUpdate += 1;
      }
      counter += 1;
    }

    upkeepNeeded = numPoolsToUpdate > 0;
    performData = abi.encode(poolAddressesToUpdate);
  }

  // Capped at 10
  function performUpkeep(bytes calldata performData) external override {
    address[] memory poolAddresses = abi.decode(performData, (address[]));
    for (uint256 i = 0; i < poolAddresses.length; i++) {
      if (poolAddresses[i] != address(0)) {
        try (ILendingPool(poolAddresses[i])).updateSeniorObligation() {} catch {
          nextRetry[poolAddresses[i]] = block.timestamp + secondsUntilNextRetry;
        }
      }
    }
  }

  function _isAfterRetryTime(address _pool) internal view returns (bool) {
    return block.timestamp >= nextRetry[_pool];
  }
}