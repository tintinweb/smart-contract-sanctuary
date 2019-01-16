pragma solidity ^0.4.25;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

library WadMath {
  uint constant WAD = 10 ** 18;

  function wmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
  }

  function wdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
  }
}

/**
 * @title Owned
 */

 contract Owned {

  address public _owner;
  address public _ownerCandidate;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender
   * account.
   */

  constructor() public {
    _owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */

  modifier onlyOwner {
    require(msg.sender == _owner);
    _;
  }

  /**
   * @dev Offer transferring ownership of the contract to a candidate. The ownership is not transferred
      until the candidate has accepted it.
   * @param candidate The address to transfer ownership to.
   */
  function transferOwnership(address candidate) public onlyOwner {
    _ownerCandidate = candidate;
  }

  /**
   * @dev Accept ownership of the contract. The control of the contract is transferred to the candidate. 
   */

  function acceptOwnership() public {
    require(msg.sender == _ownerCandidate);
    emit OwnershipTransferred(_owner, _ownerCandidate);
    _owner = _ownerCandidate;
    _ownerCandidate = address(0);
  }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Owned {
  event Paused(address account);
  event Unpaused(address account);

  bool _paused;

  constructor() internal {
    _paused = false;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(_paused);
    _;
  }

  /**
   * @dev Return whether the contract is paused.
   */
  function paused() public view returns (bool) {
    return _paused;
  }

  /**
   * @dev Called by the pauser to pause methods protected by the whenPaused modifier.
   */
  function pause() public onlyOwner whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

  /**
   * @dev Called by the pauser to unpause.
   */
  function unpause() public onlyOwner whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}

/**
 * @title Standard ERC20 token implementation.
 */
contract ERC20 is Pausable {
  using SafeMath for uint;

  string _name;
  string _symbol;
  uint8 _decimals = 18;

  uint _totalSupply;

  mapping (address => uint) _balanceOf;
  mapping (address => mapping (address => uint)) _allowance;

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);

  constructor(string name, string symbol) public {
    _totalSupply = 0;
    _name = name;
    _symbol = symbol;
  }

  /**
   * @dev Get the name of the token.
   */

  function name() public view returns (string) {
    return _name;
  }

  /**
   * @dev Get the symbol of the token.
   */

  function symbol() public view returns (string) {
    return _symbol;
  }

  /**
   * @dev Get the number of decimals used by the token.
   */

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Get the total amount of tokens ever minted, excluding those which were transferred to address 0x0.
   */

  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(_balanceOf[address(0)]);
  }

  /**
   * @dev Get the balance of the specified address.
   * @param owner The address to query the balance of.
   * @return The amount owned by the passed address.
   */

  function balanceOf(address owner) public view returns (uint256 balance) {
    return _balanceOf[owner];
  }

  /**
   * @dev Get the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return The amount of tokens still available for the spender.
   */

  function allowance(address owner, address spender) public view returns (uint256 remaining) {
    return _allowance[owner][spender];
  }

  /**
   * @dev Internal function that executes a transfer from one address to antoher address.
   * @param to The address to transfer to.
   * @param value The amount to be transferred.
   */

  function _transfer(address from, address to, uint value) internal {
    require(_balanceOf[from] >= value);
    _balanceOf[from] = _balanceOf[from].sub(value);
    _balanceOf[to] = _balanceOf[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
   * @dev Transfer tokens to a specified address.
   * @param to The address to transfer to.
   * @param value The amount to be transferred.
   */
 
  function transfer(address to, uint value) public whenNotPaused returns (bool success) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another. The transfer must have been approved.
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value The amount of tokens to be transferred
   */

  function transferFrom(address from, address to, uint value) public whenNotPaused returns (bool success) {
    require(value <= _allowance[from][msg.sender]);
    _allowance[from][msg.sender] = _allowance[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */

  function approve(address spender, uint value) public whenNotPaused returns (bool success) {
    _allowance[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }
}

/**
 * @title TweetCoin
 * @dev An ERC20 token extended with the ability to purchase tokens using ETH. Tokens are
           minted when purchasing.
 */
contract TweetCoin is ERC20 {
  using SafeMath for uint;
  using WadMath for uint;

  /**
   * @dev Inherit from ERC20, Owned and Pausable.
   */

  constructor() ERC20("TweetCoin", "TWC") Owned() Pausable() public {}

  /**
   * @dev Logs a Purchase transaction.
   *
   * @param from The address of the account that supplied the ETH
   * @param to The address of the account where the tokens were transferred
   * @param eth The amount of ETH that was converted to tokens
   * @param value The amount of tokens that were purchased
   */

  event Purchase(address indexed from, address indexed to, uint eth, uint value);

  /**
   * @dev The token multiplier is a decreasing function of the total amount of sold tokens:
   
      y = 1 + 1/(x/500ether + 1)
   
     where x is the _totalSupply and y is the multiplier.
   
   * @return The current token multiplier as a wad (uint representing an 18 decimal fixed point).
   */

  function tokenMultiplier() public view returns (uint tokens) {
    return SafeMath.add(1 ether, WadMath.wdiv(1 ether, (_totalSupply.wdiv(500 ether)).add(1 ether)));
  }

  /**
   * @dev Purchase tokens for a recepient. Allows to purchase for someone else (e.g. a contract).
   *
   * @param recepient The address of the recepient (can be a smart contract).
   */

  function buy(address recepient) payable public whenNotPaused returns (uint amount) {
    amount = tokenMultiplier().wmul(msg.value);
    _balanceOf[recepient] = _balanceOf[recepient].add(amount);
    _totalSupply = _totalSupply.add(amount);
    emit Purchase(msg.sender, recepient, msg.value, amount);

    // ERC20: minting SHOULD emit the Transfer() event from 0x0
    emit Transfer(0x0, recepient, amount);

    return amount;
  }

  /**
   * @dev Purchase tokens for oneself by simply transferring ETH to the contract.
   */

  function () payable public {
    buy(msg.sender);
  }

  /**
   * @dev Logs a withdrawal transaction.
   *
   * @param recepient The address of the recepient of the withdrawn ETH
   * @param amount The amount of ETH that was withdrawn
   */

  event Withdrawal(address indexed recepient, uint amount);

  /**
   * @dev Withdraw the ETH that was received when purchasing tokens.
   *
   * @param recepient The address of the recepient where the ETH will be transferred.
   * @param amount The amount of ETH to withdraw.
   */

  function withdraw(address recepient, uint amount) public onlyOwner {
    require(amount <= address(this).balance);
    recepient.transfer(amount);
    emit Withdrawal(recepient, amount);
  }

}