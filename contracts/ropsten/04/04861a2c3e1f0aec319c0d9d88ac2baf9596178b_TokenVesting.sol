pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: contracts/TokenVesting.sol

contract TokenVesting is Ownable {
  using SafeMath for uint;

  ERC20 public token;
  address public receiver;
  uint256 public startTime;
  uint256 public cliff;
  uint256 public totalPeriods;
  uint256 public timePerPeriod;
  uint256 public totalTokens;
  uint256 public tokensClaimed;

  event VestingFunded(uint256 totalTokens);
  event TokensClaimed(uint256 tokensClaimed);
  event VestingKilled();

  constructor(
    address _token,
    address _receiver,
    uint256 _startTime,
    uint256 _cliff,
    uint256 _totalPeriods,
    uint256 _timePerPeriod
  ) public {
    token = ERC20(_token);
    receiver = _receiver;
    startTime = _startTime;
    cliff = _cliff;
    totalPeriods = _totalPeriods;
    timePerPeriod = _timePerPeriod;
  }

  function fundVesting(uint256 _totalTokens) public onlyOwner {
    require(totalTokens == 0, "Vesting already funded");
    require(_totalTokens > 0);
    require(token.allowance(owner, address(this)) == _totalTokens);
    totalTokens = _totalTokens;
    token.transferFrom(owner, address(this), totalTokens);
    emit VestingFunded(_totalTokens);
  }

  function claimTokens() public {
    require(totalTokens > 0, "Vesting has not been funded yet");
    require(msg.sender == receiver, "Only receiver can claim tokens");
    require(now > startTime.add(cliff), "Vesting hasnt started yet");

    uint256 tokensToClaim = availableTokens();
    token.transfer(receiver, tokensToClaim);
    tokensClaimed = tokensClaimed.add(tokensToClaim);

    emit TokensClaimed(tokensToClaim);
  }

  function killVesting() public onlyOwner {
    token.transfer(owner, totalTokens.sub(tokensClaimed));
    tokensClaimed = totalTokens;
    emit VestingKilled();
  }

  function availableTokens() public view returns(uint256) {
    uint256 timePassed = now.sub(startTime.add(cliff));
    return totalTokens
      .div(totalPeriods)
      .mul(timePassed.div(timePerPeriod))
      .sub(tokensClaimed);
  }

}