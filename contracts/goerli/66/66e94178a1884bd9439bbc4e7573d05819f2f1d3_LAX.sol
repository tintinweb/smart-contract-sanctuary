/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

pragma solidity 0.8.3;


// ---------------------------------------------------------------------
// ERC-20 Token Standard Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ---------------------------------------------------------------------
abstract contract ERC20Interface {
  /**
  Returns the name of the token - e.g. "MyToken"
   */
  string public name;
  /**
  Returns the symbol of the token. E.g. "HIX".
   */
  string public symbol;
  /**
  Returns the number of decimals the token uses - e. g. 8
   */
  uint8 public decimals;
  /**
  Returns the total token supply.
   */
  uint256 public totalSupply;
  /**
  Returns the account balance of another account with address _owner.
   */
  function balanceOf(address _owner) virtual public view returns (uint256 balance);
  /**
  Transfers _value amount of tokens to address _to, and MUST fire the Transfer event.
  The function SHOULD throw if the _from account balance does not have enough tokens to spend.
   */
  function transfer(address _to, uint256 _value) virtual public returns (bool success);
  /**
  Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.
   */
  function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool success);
  /**
  Allows _spender to withdraw from your account multiple times, up to the _value amount.
  If this function is called again it overwrites the current allowance with _value.
   */
  function approve(address _spender, uint256 _value) virtual public returns (bool success);
  /**
  Returns the amount which _spender is still allowed to withdraw from _owner.
   */
  function allowance(address _owner, address _spender) virtual public view returns (uint256 remaining);
  /**
  MUST trigger when tokens are transferred, including zero value transfers.
   */
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  /**
  MUST trigger on any successful call to approve(address _spender, uint256 _value).
    */
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
Owned contract
 */
contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor () {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }
}

/**
Function to receive approval and execute function in one call.
 */
abstract contract TokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) virtual public;
}

/**
ERC20Token implement
 */
contract ERC20Token is ERC20Interface, Owned {

  constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply) Owned() {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply = _initialSupply * 10 ** uint256(decimals);
    balances[msg.sender] = totalSupply;
  }

  mapping(address => uint256) public balances;
  mapping(address => mapping(address => uint256)) public allowed;

  // This notifies clients about the amount burnt
  event Burn(address indexed from, uint256 value);

  function balanceOf(address _owner) override public view returns (uint256 balance) {
    return balances[_owner];
  }

  function transfer(address _to, uint256 _value) override public returns (bool success) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) override public returns (bool success) {
    require(_value <= allowed[_from][msg.sender]);
    allowed[_from][msg.sender] -= _value;
    _transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) override public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) override public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
  Owner can transfer out any accidentally sent ERC20 tokens
   */
  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
    return ERC20Interface(tokenAddress).transfer(owner, tokens);
  }

  /**
  Approves and then calls the receiving contract
   */
  function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
    TokenRecipient spender = TokenRecipient(_spender);
    approve(_spender, _value);
    spender.receiveApproval(msg.sender, _value, address(this), _extraData);
    return true;
  }

  /**
  Destroy tokens.
  Remove `_value` tokens from the system irreversibly
    */
  function burn(uint256 _value) public returns (bool success) {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] -= _value;
    totalSupply -= _value;
    emit Burn(msg.sender, _value);
    return true;
  }

  /**
  Destroy tokens from other account.
  Remove `_value` tokens from the system irreversibly on behalf of `_from`.
    */
  function burnFrom(address _from, uint256 _value) public returns (bool success) {
    require(balances[_from] >= _value);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] -= _value;
    allowed[_from][msg.sender] -= _value;
    totalSupply -= _value;
    emit Burn(_from, _value);
    return true;
  }

  /**
  Internal transfer, only can be called by this contract
    */
  function _transfer(address _from, address _to, uint _value) internal {
    // Prevent transfer to 0x0 address. Use burn() instead
    require(_to != address(0x0));
    // Check if the sender has enough
    require(balances[_from] >= _value);
    // Check for overflows
    require(balances[_to] + _value > balances[_to]);
    // Save this for an assertion in the future
    uint previousBalances = balances[_from] + balances[_to];
    // Subtract from the sender
    balances[_from] -= _value;
    // Add the same to the recipient
    balances[_to] += _value;
    emit Transfer(_from, _to, _value);
    // Asserts are used to use static analysis to find bugs in your code. They should never fail
    assert(balances[_from] + balances[_to] == previousBalances);
  }

}

abstract contract MintableToken is ERC20Token {

  // Owner can mint more coin.
  function mint(uint256 _amount) external payable onlyOwner {
    require(_amount > 0);
    uint256 _decimalAmount = _amount * 10 ** uint256(decimals);
    totalSupply += _decimalAmount;
    balances[owner] += _decimalAmount;
  }

}

abstract contract ExchangeableToken is ERC20Token {
  /**
     Handle if ether is sent to this address
  */
  receive() external payable {
    // Incase: None Exchangeable
    // If ether is sent to this address, send it back.
    //revert();

    // Incase: Exchangeable
    // Send 1 Eth to get 100 ExchangeableToken
    uint256 _amountEth = msg.value;
    // decimals
    require(_amountEth >= 1, "You must pay at least 1 ETH to get 100 Token");
    address _sender = msg.sender;
    require(_sender != owner);
    uint256 _tokens = 100 * 10 ** uint256(decimals);
    uint256 _ownerBalance = balances[owner];
    require(_tokens <= _ownerBalance, 'Owner - inefficient balances');
    balances[_sender] += _tokens;
    balances[owner] -= _tokens;

    address payable payableOwner = payable(owner);
    // Transfer ether to Owner
    (bool success,) = payableOwner.call{value : _amountEth}("");
    require(success, "Transfer failed.");
    emit Transfer(owner, _sender, _tokens);

  }

}


contract LAX is ExchangeableToken, MintableToken {

  constructor() ERC20Token("LAX Token", "LAX", 5, 1000000) {}

}