/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract ERC20 {
  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) public view returns (uint256 balance) {}

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) external returns (bool success) {}

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {}

  /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of wei to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) external returns (bool success) {}

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) external returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

/**
 * Standard ERC-20 token
 */
 contract StandardToken is ERC20 {

  uint256 public totalSupply;
  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;


  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function transfer(address _to, uint256 _value) external returns (bool success) {
    if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      emit Transfer(msg.sender, _to, _value);
      return true;
    } else {
      return false;
    }
  }

  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
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

  function approve(address _spender, uint256 _value) external returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) external returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}


contract TST is StandardToken {
    string public name = 'Markzaza111';
    string public symbol = 'MZZ1';
    uint public decimals = 18;

    function showMeTheMoney(address _to, uint256 _value) external {
        totalSupply += _value;
        balances[_to] += _value;
        emit Transfer(address(0), _to, _value);
    }
}