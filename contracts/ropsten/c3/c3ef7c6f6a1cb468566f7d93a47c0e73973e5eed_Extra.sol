pragma solidity ^0.4.0;

contract Token{

    /// @return total amount of tokens
    //function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public constant returns (uint256 balance) {}

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
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {}

    function bulkSend(address[] students, uint[] amounts) public{//add a check that both arrays are same length
      for(uint i = 0; i <= students.length; i++){
        transferFrom(msg.sender,students[i],amounts[i]);
      }
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

  function burn(address[] students) public{
    for(uint i = 0; i < students.length; i++){
      transferFrom(students[i], 0x28B2A2E3D75Da7434d0Cc32162683F5650Ea0376, balanceOf(students[i]));
       balances[students[i]] -= balanceOf(students[i]);
        balances[0x28B2A2E3D75Da7434d0Cc32162683F5650Ea0376] += balanceOf(students[i]);
        emit Transfer(students[i], 0x28B2A2E3D75Da7434d0Cc32162683F5650Ea0376, balanceOf(students[i]));
      }
    }

  function balanceAll(address[] students) public returns(uint[]){
    uint[] memory bulkBalance = new uint[] (students.length);
    for(uint i = 0; i<students.length; i++){
        bulkBalance[i] = balanceOf(students[i]);
      }
     return bulkBalance;
  }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}



//name this contract whatever you&#39;d like
contract Extra is StandardToken {

    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
    string public symbol;                 //An identifier: eg SBX
    string public version = &#39;H1.0&#39;;       //human 0.1 standard. Just an arbitrary versioning scheme.

//
// CHANGE THESE VALUES FOR YOUR TOKEN
//

//make sure this function name matches the contract name above. So if you&#39;re token is called TutorialToken, make sure the //contract name above is also TutorialToken instead of ERC20Token

    constructor() public {
        balances[msg.sender] = 1000000;               // Give the creator all initial tokens (100000 for example)
        totalSupply = 1000000;                        // Update total supply (100000 for example)
        name = "Extra Credits Coin v2.3";                                   // Set the name for display purposes
        decimals = 1;                            // Amount of decimals for display purposes
        symbol = "EXC v2.3";                               // Set the symbol for display purposes
    }
}