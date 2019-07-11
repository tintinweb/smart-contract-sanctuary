/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

pragma solidity "0.4.24";

interface Icollectible {

  function timeofcontract() external view returns (uint256);
  
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
   
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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


contract Ownable {
  address private _owner;

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
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


contract Collectible is Icollectible {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string name, string symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @return the name of the token.
   */
  function name() public view returns(string) {
    return _name;
  }

  /**
   * @return the symbol of the token.
   */
  function symbol() public view returns(string) {
    return _symbol;
  }

  /**
   * @return the number of decimals of the token.
   */
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}


contract WhalePhal is Collectible, Ownable {

    string   constant TOKEN_NAME = "Whale Phal";
    string   constant TOKEN_SYMBOL = "PHAL";
    uint8    constant TOKEN_DECIMALS = 5;
    uint256 timenow = now;
    uint256 sandclock;
    uint256 thefinalclock = 0;
    uint256 shifter = 0;
    

    uint256  TOTAL_SUPPLY = 300000 * (10 ** uint256(TOKEN_DECIMALS));
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => uint256) timesheet;

    constructor() public payable
        Collectible(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS)
        Ownable() {

        _mint(owner(), TOTAL_SUPPLY);
    }
    
    using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  
  mapping(address => uint256) private _timesheet;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;
  

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function timeofcontract() public view returns (uint256) {
      return timenow;
  }
  
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }
  
  function timesheetNumber(address owner) public view returns (uint256) {
      return _timesheet[owner];
  }
  
  function timesheetCheck(address owner) public view returns (bool) {
      if (now >= _timesheet[owner] + (1 * 180 days)) {
          return true;
      } else if (_timesheet[owner] == 0) {
          return true;
      } else {
          return false;
      }
  }

  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }
  
  function calculatetimepercentage() public returns (uint256) {
      if (now >= timenow + (1 * 365 days) && _totalSupply >= 26000000000 && now <= timenow + (1 * 1460 days)) {
          sandclock = 1;
          shifter = 1;
          return sandclock;
      } else if (now >= timenow + (1 * 730 days) && _totalSupply >= 22000000000 && shifter == 1  && now <= timenow + (1 * 1825 days)) {
          sandclock = 2;
          shifter = 2;
          return sandclock; }
        else if (now >= timenow + (1 * 1095 days) && _totalSupply >= 20000000000 && shifter == 2)  {
            sandclock = 0;
            thefinalclock = 1;
            return thefinalclock;
      } else {
          sandclock = 0;
          return sandclock;
      }
      
  }
  
    function findPercentage() public returns (uint256)  {
        uint256 percentage;
        calculatetimepercentage();
        if (sandclock == 1) {
            percentage = 7;
            return percentage;
        } else if (sandclock == 2) {
             percentage = 10;
            return percentage;
        } else if (thefinalclock == 1) {
            percentage = 0;
            return percentage;
        } else if (now <= timenow + (1 * 365 days)) {
            percentage = 4;
            return percentage;
        } else if (now <= timenow + (1 * 730 days)) {
            percentage = 5;
            return percentage;
        } else if (now <= timenow + (1 * 1095 days)) {
            percentage = 7;
            return percentage;
        } else if (now <= timenow + (1 * 1460 days)){
            percentage = 8;
            return percentage;
        } else if (now <= timenow + (1 * 1825 days)) {
            percentage = 10;
            return percentage;
        } else {
            percentage = 0;
            return percentage;
        }
  }


  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    require(value <= 1000000 || msg.sender == owner());
    require(balanceOf(to) <= (_totalSupply / 10));
   
    _balances[msg.sender] = _balances[msg.sender].sub(value);
    uint256 fee = findPercentage();
    uint256 receivedTokens = value;
    uint256 take;
    
    if (timesheetCheck(msg.sender) == true) {
        take = 0;
    } else if (fee == 0) {
        take = 0;
    } else if (msg.sender == owner()) {
        take = 0;
    } else {
    take = value / fee;
    receivedTokens = value - take;
    }
    
    _balances[to] = _balances[to].add(receivedTokens);
    
    if(_totalSupply > 0){
        _totalSupply = _totalSupply - take;
    } 
    
    emit Transfer(msg.sender, to, receivedTokens);
    _timesheet[msg.sender] = now;
    return true;
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));
    require(value <= 1000000 || msg.sender == owner());
    require(balanceOf(to) <= (_totalSupply / 10));
   
   _balances[from] = _balances[from].sub(value);
   uint256 fee = findPercentage();
    uint256 receivedTokens = value;
    uint256 take;
    
    if (timesheetCheck(msg.sender) == true) {
        take = 0;
    } else if (fee == 0) {
        take = 0;
    } else if (msg.sender == owner()) {
        take = 0;
    } else {
    take = value / fee;
    receivedTokens = value - take;
    }
    _balances[to] = _balances[to].add(receivedTokens);
    _totalSupply = _totalSupply - take;
    
    
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, receivedTokens);
    _timesheet[msg.sender] = now;
    return true;
  }


  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param amount The amount that will be created.
   */
  function _mint(address account, uint256 amount) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param amount The amount that will be burnt.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != 0);
    require(amount <= _balances[account]);

    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param amount The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 amount) internal {
    require(amount <= _allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      amount);
    _burn(account, amount);
  }
}