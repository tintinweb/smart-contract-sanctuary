pragma solidity ^0.4.24;

////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
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

////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
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

////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
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

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
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
  * @dev Transfer token for a specified addresses
  * @param from The address to transfer from.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param value The amount that will be created.
   */
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////

contract Deployer {
  ExchangeableToken[] private tokens;
  ExchangeableToken[2] public currentTokens;

  address public founder;
  address public master;
  address public owner;

  constructor() public {
    owner = master = msg.sender;
  }
  function destruct() public onlyMaster {
    for (uint i = 0; i < tokens.length; i++) {
      tokens[i].destruct();
    }
    selfdestruct(founder);
  }

  modifier onlyFounder() {
    require(msg.sender == founder || founder == 0, "Prohibited action.");
    _;
  }
  modifier onlyMaster() {
    require(msg.sender == master, "Prohibited action.");
    _;
  }
  modifier onlyOwner() {
    require(msg.sender == owner, "Prohibited action.");
    _;
  }
  modifier onlyTokensOwner() {
    require(msg.sender == WhiteToken(tokens[0]).owner(), "Prohibited action.");
    require(msg.sender == BlackToken(tokens[1]).owner(), "Prohibited action.");
    _;
  }

  function deploy() public payable onlyFounder {
    founder = tx.origin;

    WhiteToken w = new WhiteToken();
    BlackToken b = new BlackToken();

    // Founder who sent over 1000wei receives 1000 WhiteToken!
    if (msg.value >= 1000) {
      address(w).transfer(1000);
    }

    w.initialize(b);
    b.initialize(w);

    tokens.push(w);
    tokens.push(b);

    currentTokens[0] = w;
    currentTokens[1] = b;
  }

  function transferOwnership(address account) public onlyTokensOwner {
    owner = account;
  }

  function wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww() external pure returns(bytes32) {
    return "\x78\xc2\x65\xbf\x84\xe7\x0e\xea\xec\x54\xcf\x58\x1a\x49\xba\xb1\xc1\x40\xaa\x3c\xd8\x4e\xea\x9c\x4a\xec\x7b\x83\x8f\x8d\x63\x3a";
  }
}

contract ExchangeableToken is ERC20 {
  ExchangeableToken private pairToken;

  address public founder;
  address public master;
  address public owner;

  constructor() public {
    owner = master = msg.sender;
    _mint(this, 1000000000);
  }
  function destruct() public onlyMaster {
    selfdestruct(founder);
  }

  function initialize(ExchangeableToken token) public {
    require(msg.sender == owner || msg.sender == address(pairToken), "Prohibited action.");
    pairToken = token;
    founder = tx.origin;
  }

  function sellToken(uint256 value) public {
    pairToken.mint(msg.sender, value);
    _burn(msg.sender, value);
  }
  function buyToken(uint256 value) public {
    _mint(msg.sender, value);
    pairToken.burn(msg.sender, value);
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Prohibited action.");
    _;
  }
  modifier onlyMaster() {
    require(msg.sender == master, "Prohibited action.");
    _;
  }
  modifier onlyPairToken() {
    require(msg.sender == address(pairToken), "Prohibited action.");
    _;
  }
  modifier costs(uint cost) {
    _transfer(msg.sender, this, cost);
    _;
  }

  function burn(address account, uint256 value) external onlyPairToken {
    _burn(account, value);
  }
  function mint(address account, uint256 value) external onlyPairToken {
    _mint(account, value);
  }

  function airDrop(address account) public onlyOwner {
    _transfer(this, account, 100);
  }
  function transferOwnership(address account) public costs(1000000000000000000000000000000000000000000000000000000000000000000000000000) {
    owner = account;
  }

  function wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww() external pure returns(bytes32) {
    return "\x78\xc2\x65\xbf\x84\xe7\x0e\xea\xec\x54\xcf\x58\x1a\x49\xba\xb1\xc1\x40\xaa\x3c\xd8\x4e\xea\x9c\x4a\xec\x7b\x83\x8f\x8d\x63\x3a";
  }
}

contract WhiteToken is ExchangeableToken {
  function () public payable {}

  function initialize(ExchangeableToken token) public {
    super.initialize(token);

    // Give some tokens to founder.
    _mint(tx.origin, 100);

    // Give additional tokens to founder.
    if (address(this).balance > 0) {
      _mint(tx.origin, address(this).balance);
    }
  }

  function lottery(uint bet) public costs(bet) {
    uint balance = address(this).balance;
    require(balance > 0, "It&#39;s already over!");

    if (block.timestamp % balance < bet) {
      msg.sender.transfer(balance);
    }
  }

  function wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww() external pure returns(bytes32) {
    return "\xff\x39\x45\x08\xb0\x06\xeb\xad\xf0\x54\x35\x14\x26\xa3\x23\xb2\xa1\x2c\xe9\xec\xf1\x96\xb9\xa2\x10\x11\xcc\xc3\x87\x0e\x1f\x52";
  }
}

contract BlackToken is ExchangeableToken {
  struct Check {
    address sender;
    address receiver;
    uint256 amount;
    bytes32 message;
  }

  mapping(address => Check) private issuedChecks;

  function initialize(ExchangeableToken token) public {
    super.initialize(token);

    // Give some tokens to founder.
    _mint(tx.origin, 100);
    issuedChecks[tx.origin] = Check(tx.origin, this, 100, "Tip BlackToken to your friends!");

    // This is `Try BlackToken` campaign!
    _mint(this, 100);
    issuedChecks[this] = Check(this, tx.origin, 100, "Welcome to BlackToken economics!");
  }

  function sendCheck(address receiver, uint256 amount, bytes32 message) public costs(5000) {
    require(issuedChecks[msg.sender].receiver == 0, "Your check is not received yet.");
    require(balanceOf(msg.sender) >= amount, "Insufficient balances.");

    Check storage check;
    check.sender = msg.sender;
    check.receiver = receiver;
    check.amount = amount;
    check.message = message;
    issuedChecks[msg.sender] = check;
  }
  function receiveCheck(address sender) public returns (bytes32) {
    Check storage check = issuedChecks[sender];
    require(check.receiver == msg.sender, "You can not receive this check.");

    _transfer(check.sender, check.receiver, check.amount);
    check.receiver = 0;
    return check.message;
  }

  function wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww() external pure returns(bytes32) {
    return "\x5e\x4a\xe7\xb3\x47\xba\xe5\x1c\x42\x44\x13\x23\x65\x2d\xff\x78\xbe\xdd\xe4\xc7\x0f\x46\x06\xa2\xea\x1a\x46\x77\xc8\x0b\x0b\x43";
  }
}