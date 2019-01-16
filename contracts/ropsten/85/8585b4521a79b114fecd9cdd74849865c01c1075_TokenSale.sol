pragma solidity 0.4.24;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

// File: contracts/tokensale.sol

contract TokenSale is Pausable {

  // Flag indicating if contract was finalized
  bool public isFinalized = false;

  // Flag indicating if contract was started
  bool public isStarted = false;

  // Event that is emited once contract was finalized
  event Finalized();

  // Event that is emited once contract was started
  event Started();

  // Event that is emited once invested
  event Invested(address purchaser, address beneficiary, uint256 amount);

  modifier whenStarted() {
    require(isStarted);
    _;
  }

  modifier whenNotFinalized() {
    require(!isFinalized);
    _;
  }

  constructor() public  {
  }

  // Method for starting token sale
  function start() public onlyOwner {
    require(!isStarted);
    require(!isFinalized);
    emit Started();
    isStarted = true;
  }

  // Method for pausing token sale
  function pause() public onlyOwner whenStarted whenNotFinalized whenNotPaused {
    super.pause();
  }

  // Method for unpausing token sale
  function unpause() public onlyOwner whenStarted whenNotFinalized whenPaused {
    super.unpause();
  }

  // Method for finalizing token sale
  function finalize() public onlyOwner {
    require(isStarted);
    require(!isFinalized);
    emit Finalized();
    isFinalized = true;
  }

  function () external payable {
    invest(msg.sender);
  }

  // Method handling investment and forwarding ethereum to owners wallet
  function invest(address _beneficiary)
    public
    whenStarted
    whenNotPaused
    whenNotFinalized
    payable {

    uint256 _weiAmount = msg.value;
    require(_beneficiary != address(0));
    require(_weiAmount != 0);

    emit Invested(msg.sender, _beneficiary, _weiAmount);

    owner.transfer(_weiAmount);
  }
}