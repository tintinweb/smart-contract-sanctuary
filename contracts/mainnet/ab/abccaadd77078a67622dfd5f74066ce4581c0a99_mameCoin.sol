/**
 * Reference Code
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/examples/SimpleToken.sol
 */

pragma solidity ^0.4.24;

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
 * @title ERC20
 * @dev Standard ERC20 token interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

/**
 * @title mameCoin
 * @dev see https://mamecoin.jp/
 */
contract mameCoin is ERC20, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping(address => mapping (address => uint256)) internal allowed;
  mapping(address => uint256) internal lockups;

  string public constant name = "mameCoin";
  string public constant symbol = "MAME";
  uint8 public constant decimals = 8;
  uint256 totalSupply_ = 25000000000 * (10 ** uint256(decimals));

  event Burn(address indexed to, uint256 amount);
  event Refund(address indexed to, uint256 amount);
  event Lockup(address indexed to, uint256 lockuptime);

  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  constructor() public {
    balances[msg.sender] = totalSupply_;
    emit Transfer(address(0), msg.sender, totalSupply_);
  }

  /**
   * @dev total number of tokens in existence
   */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
   * @dev Gets the balance of the specified address.
   * @param _owner The address to query the the balance of.
   * @return An uint256 representing the amount owned by the passed address.
   */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  /**
   * @dev transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _amount The amount to be transferred.
   */
  function transfer(address _to, uint256 _amount) public returns (bool) {
    require(_to != address(0));
    require(_amount <= balances[msg.sender]);
    require(block.timestamp > lockups[msg.sender]);
    require(block.timestamp > lockups[_to]);

    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(msg.sender, _to, _amount);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _amount uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
    require(_to != address(0));
    require(_amount <= balances[_from]);
    require(_amount <= allowed[_from][msg.sender]);
    require(block.timestamp > lockups[_from]);
    require(block.timestamp > lockups[_to]);

    balances[_from] = balances[_from].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    emit Transfer(_from, _to, _amount);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _amount The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _amount) public returns (bool) {
    allowed[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Burns a specific amount of tokens.
   * @param _to address The address which is burned.
   * @param _amount The amount of token to be burned.
   */
  function burn(address _to, uint256 _amount) public onlyOwner {
    require(_amount <= balances[_to]);
    require(block.timestamp > lockups[_to]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_to] = balances[_to].sub(_amount);
    totalSupply_ = totalSupply_.sub(_amount);
    emit Burn(_to, _amount);
    emit Transfer(_to, address(0), _amount);
  }

  /**
   * @dev Refund a specific amount of tokens.
   * @param _to The address that will receive the refunded tokens.
   * @param _amount The amount of tokens to refund.
   */
  function refund(address _to, uint256 _amount) public onlyOwner {
    require(block.timestamp > lockups[_to]);
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Refund(_to, _amount);
    emit Transfer(address(0), _to, _amount);
  }

  /**
   * @dev Gets the lockuptime of the specified address.
   * @param _owner The address to query the the lockup of.
   * @return An uint256 unixstime the lockuptime which is locked until that time.
   */
  function lockupOf(address _owner) public view returns (uint256) {
    return lockups[_owner];
  }

  /**
   * @dev Lockup a specific address until given time.
   * @param _to address The address which is locked.
   * @param _lockupTimeUntil The lockuptime which is locked until that time.
   */
  function lockup(address _to, uint256 _lockupTimeUntil) public onlyOwner {
    require(lockups[_to] < _lockupTimeUntil);
    lockups[_to] = _lockupTimeUntil;
    emit Lockup(_to, _lockupTimeUntil);
  }

  /**
   * @dev airdrop tokens for a specified addresses
   * @param _receivers The addresses to transfer to.
   * @param _amount The amount to be transferred.
   */
  function airdrop(address[] _receivers, uint256 _amount) public returns (bool) {
    require(block.timestamp > lockups[msg.sender]);
    require(_receivers.length > 0);
    require(_amount > 0);

    uint256 _total = 0;

    for (uint256 i = 0; i < _receivers.length; i++) {
      require(_receivers[i] != address(0));
      require(block.timestamp > lockups[_receivers[i]]);
      _total = _total.add(_amount);
    }

    require(_total <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_total);

    for (i = 0; i < _receivers.length; i++) {
      balances[_receivers[i]] = balances[_receivers[i]].add(_amount);
      emit Transfer(msg.sender, _receivers[i], _amount);
    }

    return true;
  }

  /**
   * @dev distribute tokens for a specified addresses
   * @param _receivers The addresses to transfer to.
   * @param _amounts The amounts to be transferred.
   */
  function distribute(address[] _receivers, uint256[] _amounts) public returns (bool) {
    require(block.timestamp > lockups[msg.sender]);
    require(_receivers.length > 0);
    require(_amounts.length > 0);
    require(_receivers.length == _amounts.length);

    uint256 _total = 0;

    for (uint256 i = 0; i < _receivers.length; i++) {
      require(_receivers[i] != address(0));
      require(block.timestamp > lockups[_receivers[i]]);
      require(_amounts[i] > 0);
      _total = _total.add(_amounts[i]);
    }

    require(_total <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_total);

    for (i = 0; i < _receivers.length; i++) {
      balances[_receivers[i]] = balances[_receivers[i]].add(_amounts[i]);
      emit Transfer(msg.sender, _receivers[i], _amounts[i]);
    }

    return true;
  }
}