pragma solidity ^0.4.23;

contract Token {

  /// @return total amount of tokens
  function totalSupply() view public returns (uint256 supply) {}

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) view public returns (uint256 balance) {}

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) public returns (bool success) {}

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}

  /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of wei to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) public returns (bool success) {}

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) view public returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}


contract StandardToken is Token {

  function transfer(address _to, uint256 _value) public returns (bool success) {
    if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      emit Transfer(msg.sender, _to, _value);
      return true;
    } else { 
      return false;
      }
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
      balances[_to] += _value;
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      emit Transfer(_from, _to, _value);
      return true;
    } else {
      return false;
      }
  }

  function balanceOf(address _owner) view public returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  uint256 public totalSupply;
}


contract WORLD1Coin is StandardToken {

  /* Public variables of the token */

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  string public name;                   
  uint8 public decimals;                
  string public symbol;                 
  string public version = "H1.0";  
  address public owner;
  bool public tokenIsLocked;
  mapping (address => uint256) lockedUntil;

  constructor() public {
    owner = 0x04c63DC704b7F564870961dd2286F75bCb3A98E2;
    totalSupply = 300000000 * 1000000000000000000;
    balances[owner] = totalSupply;                 
    name = "Worldcoin1";                                // Token Name
    decimals = 18;                                      // Amount of decimals for display purposes
    symbol = "WRLD1";                                    // Token Symbol
  }

  /* Approves and then calls the receiving contract */
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);

    if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) {
      revert();
      }
    return true;
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    if (msg.sender == owner || !tokenIsLocked) {
      return super.transfer(_to, _value);
    } else {
      revert();
    }
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    if (msg.sender == owner || !tokenIsLocked) {
      return super.transferFrom(_from, _to, _value);
    } else {
      revert();
    }
  }
  
  function killContract() onlyOwner public {
    selfdestruct(owner);
  }

  function lockTransfers() onlyOwner public {
    tokenIsLocked = true;
  }

}