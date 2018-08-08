pragma solidity ^0.4.18;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

// File: contracts/Timelock.sol

/**
 * @title TokenTimelock
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme with a cliff, gradual release period, and implied residue.
 *
 * Withdraws by an address can be paused by the owner.
 */
contract Timelock is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  /*
   * @dev ERC20 token that is being timelocked
   */
  ERC20Basic public token;

  /**
   * @dev timestamp at which the timelock schedule begins
   */
  uint256 public startTime;

  /**
   * @dev number of seconds from startTime to cliff
   */
  uint256 public cliffDuration;

  /**
   * @dev a percentage that becomes available at the cliff, expressed as a number between 0 and 100
   */
  uint256 public cliffReleasePercentage;

  /**
   * @dev number of seconds from cliff to residue, over this period tokens become avialable gradually
   */
  uint256 public slopeDuration;

  /**
   * @dev a percentage that becomes avilable over the gradual release period expressed as a number between 0 and 100
   */
  uint256 public slopeReleasePercentage;

  /**
   * @dev boolean indicating if owner has finished allocation.
   */
  bool public allocationFinished;

  /**
   * @dev variable to keep track of cliff time.
   */
  uint256 public cliffTime;

  /**
   * @dev variable to keep track of when the timelock ends.
   */
  uint256 public timelockEndTime;

  /**
   * @dev mapping to keep track of what amount of tokens have been allocated to what address.
   */
  mapping (address => uint256) public allocatedTokens;

  /**
   * @dev mapping to keep track of what amount of tokens have been withdrawn by what address.
   */
  mapping (address => uint256) public withdrawnTokens;

  /**
   * @dev mapping to keep track of if withdrawls are paused for a given address.
   */
  mapping (address => bool) public withdrawalPaused;

  /**
   * @dev constructor
   * @param _token address of ERC20 token that is being timelocked.
   * @param _startTime timestamp indicating when the unlocking of tokens start.
   * @param _cliffDuration number of seconds before any tokens are unlocked.
   * @param _cliffReleasePercent percentage of tokens that become available at the cliff time.
   * @param _slopeDuration number of seconds for gradual release of Tokens.
   * @param _slopeReleasePercentage percentage of tokens that are released gradually.
   */
  function Timelock(ERC20Basic _token, uint256 _startTime, uint256 _cliffDuration, uint256 _cliffReleasePercent, uint256 _slopeDuration, uint256 _slopeReleasePercentage) public {

    // sanity checks
    require(_cliffReleasePercent.add(_slopeReleasePercentage) <= 100);
    require(_startTime > now);
    require(_token != address(0));

    // defaults
    allocationFinished = false;

    // storing constructor params
    token = _token;
    startTime = _startTime;
    cliffDuration = _cliffDuration;
    cliffReleasePercentage = _cliffReleasePercent;
    slopeDuration = _slopeDuration;
    slopeReleasePercentage = _slopeReleasePercentage;

    // derived variables
    cliffTime = startTime.add(cliffDuration);
    timelockEndTime = cliffTime.add(slopeDuration);
  }

  /**
   * @dev helper method that allows owner to allocate tokens to an address.
   * @param _address beneficiary receiving the tokens.
   * @param _amount number of tokens being received by beneficiary.
   * @return boolean indicating function success.
   */
  function allocateTokens(address _address, uint256 _amount) onlyOwner external returns (bool) {
    require(!allocationFinished);

    allocatedTokens[_address] = _amount;
    return true;
  }

  /**
   * @dev helper method that allows owner to mark allocation as done.
   * @return boolean indicating function success.
   */
  function finishAllocation() onlyOwner external returns (bool) {
    allocationFinished = true;

    return true;
  }

  /**
   * @dev helper method that allows owner to pause withdrawls for any address.
   * @return boolean indicating function success.
   */
  function pauseWithdrawal(address _address) onlyOwner external returns (bool) {
    withdrawalPaused[_address] = true;
    return true;
  }

  /**
   * @dev helper method that allows owner to unpause withdrawls for any address.
   * @return boolean indicating function success.
   */
  function unpauseWithdrawal(address _address) onlyOwner external returns (bool) {
    withdrawalPaused[_address] = false;
    return true;
  }

  /**
   * @dev helper method that allows anyone to check amount that is available for withdrawl by a given address.
   * @param _address for which the user needs to check available amount for withdrawl.
   * @return uint256 number indicating the number of tokens available for withdrawl.
   */
  function availableForWithdrawal(address _address) public view returns (uint256) {
    if (now < cliffTime) {
      return 0;
    } else if (now < timelockEndTime) {
      uint256 cliffTokens = (cliffReleasePercentage.mul(allocatedTokens[_address])).div(100);
      uint256 slopeTokens = (allocatedTokens[_address].mul(slopeReleasePercentage)).div(100);
      uint256 timeAtSlope = now.sub(cliffTime);
      uint256 slopeTokensByNow = (slopeTokens.mul(timeAtSlope)).div(slopeDuration);

      return (cliffTokens.add(slopeTokensByNow)).sub(withdrawnTokens[_address]);
    } else {
      return allocatedTokens[_address].sub(withdrawnTokens[_address]);
    }
  }

  /**
   * @dev helper method that allows a beneficiary to withdraw tokens that have vested for their address.
   * @return boolean indicating function success.
   */
  function withdraw() external returns (bool) {
    require(!withdrawalPaused[msg.sender]);

    uint256 availableTokens = availableForWithdrawal(msg.sender);
    require (availableTokens > 0);
    withdrawnTokens[msg.sender] = withdrawnTokens[msg.sender].add(availableTokens);
    token.safeTransfer(msg.sender, availableTokens);
    return true;
  }

}