//SourceUnit: Albetrage.sol

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// TRC20 Token
// Symbol      : ATE
// Name        : ALBETRAGE
// Total supply: 5000000000
// Decimals    : 8
// (c) by Albetrage ltd 2020. The MIT Licence.
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract TRC20Interface {

  string public name;

  string public symbol;

  uint8 public decimals;
 
  uint256 public totalSupply;

  function balanceOf(address _owner) public view returns (uint256 balance);

  function transfer(address _to, uint256 _value) public returns (bool success);

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

  function approve(address _spender, uint256 _value) public returns (bool success);

  function allowance(address _owner, address _spender) public view returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor () public {
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

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
// ----------------------------------------------------------------------------
contract TokenRecipient { 
  function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public; 
}

// ----------------------------------------------------------------------------
// TRC-20 Token implementation
// ----------------------------------------------------------------------------
contract Token is TRC20Interface, Owned {

  mapping (address => uint256) _balances;
  mapping (address => mapping (address => uint256)) _allowed;
  
  // This will notify users about the amount of token burnt
  event Burn(address indexed from, uint256 value);
  
// ------------------------------------------------------------------------
// Get the token balance for account tokenOwner
// ------------------------------------------------------------------------
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return _balances[_owner];
  }

// ------------------------------------------------------------------------
// Transfer the balance from token owner's account to another account
// - Owner's account must have sufficient balance to transfer
// ------------------------------------------------------------------------
  function transfer(address _to, uint256 _value) public returns (bool success) {
    _transfer(msg.sender, _to, _value);
    return true;
  }
// ------------------------------------------------------------------------
// The calling account must already have sufficient tokens approve(...)-d
// for spending from the from account and
// - From account must have sufficient balance to transfer
// - Spender must have sufficient allowance to transfer
// ------------------------------------------------------------------------
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value <= _allowed[_from][msg.sender]); 
    _allowed[_from][msg.sender] -= _value;
    _transfer(_from, _to, _value);
    return true;
  }

// ------------------------------------------------------------------------
// Token owner can approve for spender to transferFrom(...) tokens
// from the token owner's account
// ------------------------------------------------------------------------
  function approve(address _spender, uint256 _value) public returns (bool success) {
    _allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

// ------------------------------------------------------------------------
// Returns the amount of tokens approved by the owner that can be
// transferred to the spender's account
// ------------------------------------------------------------------------
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return _allowed[_owner][_spender];
  }

// ------------------------------------------------------------------------
// to transfer out any accidentally sent TRC20 tokens
// ------------------------------------------------------------------------
  function transferAnyTRC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
    return TRC20Interface(tokenAddress).transfer(owner, tokens);
  }

// ------------------------------------------------------------------------
// Token owner can approve for spender to transferFrom(...) tokens
// from the token owner's account. The spender contract function
// receiveApproval(...) is then executed
// ------------------------------------------------------------------------
  function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
    TokenRecipient spender = TokenRecipient(_spender);
    approve(_spender, _value);
    spender.receiveApproval(msg.sender, _value, address(this), _extraData);
    return true;
  }

// ------------------------------------------------------------------------
//  Burn tokens.
// ------------------------------------------------------------------------
  function burn(uint256 _value) public returns (bool success) {
    require(_balances[msg.sender] >= _value);
    _balances[msg.sender] -= _value;
    totalSupply -= _value;
    emit Burn(msg.sender, _value);
    return true;
  }

// ------------------------------------------------------------------------
//  Burn tokens from other account.
// ------------------------------------------------------------------------

  function burnFrom(address _from, uint256 _value) public returns (bool success) {
    require(_balances[_from] >= _value);
    require(_value <= _allowed[_from][msg.sender]);
    _balances[_from] -= _value;
    _allowed[_from][msg.sender] -= _value;
    totalSupply -= _value;
    emit Burn(_from, _value);
    return true;
  }

// ----------------------------------------------------------------------------
// Safe maths, can only be called by this contract
// ----------------------------------------------------------------------------

  function _transfer(address _from, address _to, uint _value) internal {
    // Prevent transfer to any 0x0 address. Use burn() instead
    require(_to != address(0x0));
    // Check if the sender has enough
    require(_balances[_from] >= _value);
    // Check for overflows
    require(_balances[_to] + _value > _balances[_to]);
    // Save this for an assertion in the future
    uint previousBalances = _balances[_from] + _balances[_to];
    // Subtract from the sender
    _balances[_from] -= _value;
    // Add the same to the recipient
    _balances[_to] += _value;
    emit Transfer(_from, _to, _value);
  // Asserts are used to use static analysis to find bugs in your code. They should never fail
    assert(_balances[_from] + _balances[_to] == previousBalances);
  }

}

contract ATEToken is Token {

  constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply = _initialSupply * 10 ** uint256(decimals);
    _balances[msg.sender] = totalSupply;
  }

// ------------------------------------------------------------------------
// Don't accept ETH
// ------------------------------------------------------------------------
  function () external payable {
    revert();
  }

}

contract Albetrage is ATEToken {

  constructor() ATEToken("Albetrage", "ATE", 8, 5000000000) public {}

}