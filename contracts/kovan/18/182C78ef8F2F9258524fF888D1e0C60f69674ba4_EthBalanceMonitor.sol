/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

// Sources flattened with hardhat v2.3.3 https://hardhat.org

// File contracts/interfaces/KeeperCompatibleInterface.sol



pragma solidity 0.8.4;

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
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );
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
  function performUpkeep(
    bytes calldata performData
  ) external;
}


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.8.0;

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
    constructor () {
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


// File @openzeppelin/contracts/security/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File contracts/upkeeps/EthBalanceMonitor.sol

pragma solidity 0.8.4;



contract EthBalanceMonitor is Ownable, Pausable, KeeperCompatibleInterface {

  event FundsAdded (
    uint256 newBalance
  );

  event TopUpSucceeded (
    address indexed recipient
  );

  event TopUpFailed (
    address indexed recipient
  );

  struct Config {
    uint256 minBalanceWei;
    uint256 minWaitPeriod;
    uint256 topUpAmountWei;
  }

  address public keeperRegistryAddress;
  address[] private s_watchList;
  Config private s_config;
  mapping (address=>bool) private activeAddresses;
  mapping (address=>uint256) internal lastTopUp;

  constructor(address _keeperRegistryAddress, uint256 _minBalanceWei, uint256 _minWaitPeriod, uint256 _topUpAmountWei) {
    keeperRegistryAddress = _keeperRegistryAddress;
    _setConfig(_minBalanceWei, _minWaitPeriod, _topUpAmountWei);
  }

  receive() external payable {
    emit FundsAdded(address(this).balance);
  }

  function withdraw(uint256 _amount, address payable _payee) external onlyOwner {
    _payee.transfer(_amount);
  }

  function setConfig(uint256 _minBalanceWei, uint256 _minWaitPeriod, uint256 _topUpAmountWei) external onlyOwner {
    _setConfig(_minBalanceWei, _minWaitPeriod, _topUpAmountWei);
  }

  function getConfig() public view returns(uint256 minBalanceWei, uint256 minWaitPeriod, uint256 topUpAmountWei) {
    Config memory config = s_config;
    return (config.minBalanceWei, config.minWaitPeriod, config.topUpAmountWei);
  }

  function setWatchList(address[] memory _watchList) external onlyOwner {
    address[] memory watchList = s_watchList;
    for (uint256 idx = 0; idx < watchList.length; idx++) {
      activeAddresses[watchList[idx]] = false;
    }
    for (uint256 idx = 0; idx < _watchList.length; idx++) {
      activeAddresses[_watchList[idx]] = true;
    }
    s_watchList = _watchList;
  }

  function getWatchList() public view returns(address[] memory) {
    return s_watchList;
  }

  function isActive(address _address) public view returns(bool) {
    return activeAddresses[_address];
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function checkUpkeep(bytes calldata _checkData) override view public
    returns (
      bool upkeepNeeded,
      bytes memory performData
    )
  {
    Config memory config = s_config;
    address[] memory watchList = s_watchList;
    address[] memory needsFunding = new address[](watchList.length);
    uint256 count = 0;
    for (uint256 idx = 0; idx < watchList.length; idx++) {
      if (watchList[idx].balance < config.minBalanceWei && lastTopUp[watchList[idx]] + config.minWaitPeriod <= block.number) {
        needsFunding[count] = watchList[idx];
        count++;
      }
    }
    if (count != watchList.length) {
      assembly {
        mstore(needsFunding, count)
      }
    }
    bool canPerform = count > 0 && address(this).balance >= count * config.topUpAmountWei;
    return (canPerform, abi.encode(needsFunding));
  }

  function performUpkeep(bytes calldata _performData) override external whenNotPaused() {
    require(msg.sender == keeperRegistryAddress, "only callable by keeper");
    address[] memory needsFunding = abi.decode(_performData, (address[]));
    Config memory config = s_config;
    if (address(this).balance < needsFunding.length * config.topUpAmountWei) {
      revert("not enough eth to fund all addresses");
    }
    for (uint256 idx = 0; idx < needsFunding.length; idx++) {
      if (activeAddresses[needsFunding[idx]] &&
        needsFunding[idx].balance < config.minBalanceWei &&
        lastTopUp[needsFunding[idx]] + config.minWaitPeriod <= block.number
      ) {
        bool success = payable(needsFunding[idx]).send(config.topUpAmountWei);
        if (success) {
          lastTopUp[needsFunding[idx]] = block.number;
          emit TopUpSucceeded(needsFunding[idx]);
        } else {
          emit TopUpFailed(needsFunding[idx]);
        }
      }
    }
  }

  function _setConfig(uint256 _minBalanceWei, uint256 _minWaitPeriod, uint256 _topUpAmountWei) internal {
    Config memory config = Config({
      minBalanceWei: _minBalanceWei,
      minWaitPeriod: _minWaitPeriod,
      topUpAmountWei: _topUpAmountWei
    });
    s_config = config;
  }
}