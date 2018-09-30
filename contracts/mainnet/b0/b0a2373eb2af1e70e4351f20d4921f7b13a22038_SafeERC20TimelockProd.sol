pragma solidity ^0.4.24;

/** 
Do not transfer tokens to TimelockERC20 directly (via transfer method)! Tokens will be stuck permanently.
Use approvals and accept method.
**/

library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


contract IERC20{
  function allowance(address owner, address spender) external view returns (uint);
  function transferFrom(address from, address to, uint value) external returns (bool);
  function approve(address spender, uint value) external returns (bool);
  function totalSupply() external view returns (uint);
  function balanceOf(address who) external view returns (uint);
  function transfer(address to, uint value) external returns (bool);
  
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract ITimeMachine {
  function getTimestamp_() internal view returns (uint);
}


contract TimeMachineP is ITimeMachine {
  /**
  * @dev get current real timestamp
  * @return current real timestamp
  */
  function getTimestamp_() internal view returns(uint) {
    return block.timestamp;
  }
}


contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract SafeERC20Timelock is ITimeMachine, Ownable {
  using SafeMath for uint;

  event Lock(address indexed _from, address indexed _for, uint indexed timestamp, uint value);
  event Withdraw(address indexed _for, uint indexed timestamp, uint value);



  mapping (address => mapping(uint => uint)) public balance;
  IERC20 public token;
  uint public totalBalance;

  constructor (address _token) public {
    token = IERC20(_token);
  }

  function contractBalance_() internal view returns(uint) {
    return token.balanceOf(this);
  }

  /**
  * @dev accept token into timelock
  * @param _for address of future tokenholder
  * @param _timestamp lock timestamp
  * @return result of operation: true if success
  */
  function accept(address _for, uint _timestamp, uint _tvalue) public returns(bool){
    require(_for != address(0));
    require(_for != address(this));
    require(_timestamp > getTimestamp_());
    require(_tvalue > 0);
    uint _contractBalance = contractBalance_();
    uint _balance = balance[_for][_timestamp];
    uint _totalBalance = totalBalance;
    require(token.transferFrom(msg.sender, this, _tvalue));
    uint _value = contractBalance_().sub(_contractBalance);
    balance[_for][_timestamp] = _balance.add(_value);
    totalBalance = _totalBalance.add(_value);
    emit Lock(msg.sender, _for, _timestamp, _value);
    return true;
  }


  /**
  * @dev release timelock tokens
  * @param _for address of future tokenholder
  * @param _timestamp array of timestamps to unlock
  * @param _value array of amounts to unlock
  * @return result of operation: true if success
  */
  function release_(address _for, uint[] _timestamp, uint[] _value) internal returns(bool) {
    uint _len = _timestamp.length;
    require(_len == _value.length);
    uint _totalValue;
    uint _curValue;
    uint _curTimestamp;
    uint _subValue;
    uint _now = getTimestamp_();
    for (uint i = 0; i < _len; i++){
      _curTimestamp = _timestamp[i];
      _curValue = balance[_for][_curTimestamp];
      _subValue = _value[i];
      require(_curValue >= _subValue);
      require(_curTimestamp <= _now);
      balance[_for][_curTimestamp] = _curValue.sub(_subValue);
      _totalValue = _totalValue.add(_subValue);
      emit Withdraw(_for, _curTimestamp, _subValue);
    }
    totalBalance = totalBalance.sub(_totalValue);
    require(token.transfer(_for, _totalValue));
    return true;
  }


  /**
  * @dev release timelock tokens
  * @param _timestamp array of timestamps to unlock
  * @param _value array of amounts to unlock
  * @return result of operation: true if success
  */
  function release(uint[] _timestamp, uint[] _value) external returns(bool) {
    return release_(msg.sender, _timestamp, _value);
  }

  /**
  * @dev release timelock tokens by force
  * @param _for address of future tokenholder
  * @param _timestamp array of timestamps to unlock
  * @param _value array of amounts to unlock
  * @return result of operation: true if success
  */
  function releaseForce(address _for, uint[] _timestamp, uint[] _value) external returns(bool) {
    return release_(_for, _timestamp, _value);
  }

  /**
  * @dev Allow to use functions of other contract from this contract
  * @param _token address of ERC20 contract to call
  * @param _to address to transfer ERC20 tokens
  * @param _amount amount to transfer
  * @return result of operation, true if success
  */
  function saveLockedERC20Tokens(address _token, address _to, uint  _amount) onlyOwner external returns (bool) {
    require(IERC20(_token).transfer(_to, _amount));
    require(totalBalance <= contractBalance_());
    return true;
  }

  function () public payable {
    revert();
  }

}

contract SafeERC20TimelockProd is TimeMachineP, SafeERC20Timelock {
  constructor () public SafeERC20Timelock(0x45245bc59219eeaaf6cd3f382e078a461ff9de7b) {
  }
}