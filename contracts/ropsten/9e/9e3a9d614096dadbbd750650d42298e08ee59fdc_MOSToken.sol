pragma solidity 0.4.14;
  
  contract ERC20 {
    /// @return total amount of tokens
    function totalSupply() constant returns (uint supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint _value) returns (bool success) {}
    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract MOSToken is ERC20{
    uint public totalSupply = 21*10**27;
    uint8 constant public decimals = 18;
    string constant public name = "MOSToken";
    string constant public symbol = "MOST";
    mapping(address=>uint) balances;
    
    function MOSToken() {
        balances[msg.sender] = totalSupply;
        Transfer(address(0), msg.sender, totalSupply);
    }
    
    
    function transfer(address _to, uint _value) returns (bool){
        if(balances[msg.sender]>_value&&balances[_to]+_value>balances[_to]){
            balances[_to]+=_value;
            Transfer(msg.sender,_to,_value);
            return true;
        }else{
            return false;
        }
    }
    
}