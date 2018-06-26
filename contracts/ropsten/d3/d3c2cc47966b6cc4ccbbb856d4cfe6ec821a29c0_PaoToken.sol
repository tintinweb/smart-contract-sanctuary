pragma solidity ^0.4.18;

/* interface: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md */
interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);

  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
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
  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract Lockable is Ownable {
  uint256 public creationTime;
  bool public tokenTransferLocker;
  mapping(address => bool) lockaddress;

  event Locked(address lockaddress);
  event Unlocked(address lockaddress);
  event TokenTransferLocker(bool _setto);

  // if Token transfer
  modifier isTokenTransfer {
    // only contract holder can send token during locked period
    if(msg.sender != owner) {
      // if token transfer is not allow
      require(!tokenTransferLocker);
      if(lockaddress[msg.sender]){
        revert();
      }
    }
    _;
  }

  // This modifier check whether the contract should be in a locked
  // or unlocked state, then acts and updates accordingly if
  // necessary
  modifier checkLock {
    if (lockaddress[msg.sender]) {
      revert();
    }
    _;
  }

   constructor() public {
    creationTime = now;
    owner = msg.sender;
  }


  function isTokenTransferLocked()
  external
  view
  returns (bool)
  {
    return tokenTransferLocker;
  }

  function enableTokenTransfer()
  external
  onlyOwner
  {
    delete tokenTransferLocker;
    emit TokenTransferLocker(false);
  }

  function disableTokenTransfer()
  external
  onlyOwner
  {
    tokenTransferLocker = true;
    emit TokenTransferLocker(true);
  }
}

contract PaoToken is ERC20, Lockable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 totalSupply_ = 10000000000 * 1000000000000000000;
  string public name = &quot;PAO Token&quot;;
  uint8 public decimals = 18;
  string public symbol = &quot;PAO&quot;;

  // constructor
  constructor() public {
    balances[msg.sender] = totalSupply_;
  }

  function totalSupply() external view returns (uint256) {
    return totalSupply_;
  }

  function balanceOf(address _addr) external view returns (uint256) {
    return balances[_addr];
  }

  function allowance(address _from, address _spender) external view returns (uint256) {
    return allowed[_from][_spender];
  }

  function transfer(address _to, uint256 _value)
  isTokenTransfer
  external
  returns (bool success) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value)
  isTokenTransfer
  external
  returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint _value)
  isTokenTransfer
  external
  returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

}