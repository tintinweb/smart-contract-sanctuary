pragma solidity ^0.4.4;

contract Kleyn {

    /// @return total Kleyn Coin amount of tokens
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance Kleyn Coin
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send  Kleyn Coin `_value` Kleyn Coin to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of Kleyn Coin to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` Kleyn Coin to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender , Kleyn Coin
    /// @param _to The address of the recipient , Kleyn Coin
    /// @param _value The amount of Kleyn Coin to be transferred  , Kleyn Coin
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` Kleyn Coin
    /// @param _spender The address of the account able to transfer the Kleyn Coin
    /// @param _value The amount of Kleyn Coin to be approved for transfer
    /// @return Whether the approval was successful or not for Kleyn Coin
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning Kleyn Coin
    /// @param _spender The address of the account able to transfer the Kleyn Coin
    /// @return Amount of remaining Kleyn Coin allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
   
}



contract KleynToken is Kleyn {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1). Kleyn Coin
        //If your Kleyn Coin leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead. Kleyn Coin
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}


//name Kleyn Coin 
contract KleynCoin is KleynToken {

    function () public {
        //if ether is sent to this address, send it back.
        throw;
            
    }

    /* Public variables of the Kleyn Coin */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the Kleyn Coin contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Kleyn Coin
    uint8 public decimals;                //How many decimals to show. 
    string public symbol;                 //An identifier: eg KLB
    string public version = &#39;H1.0&#39;;       //human 0.1 standard. Just an arbitrary versioning scheme.

//
// WE CHANGE THESE VALUES FOR OUR Kleyn Coin
//

//make sure this function name matches the contract name above. So if you&#39;re token is called TutorialToken, make sure the //contract name above is also TutorialToken instead of ERC20Token

    function KleynCoin(
        ) {
        balances[msg.sender] = 1000000000000000000000000000;               // Give the creator all initial Kleyn Coin (100000 for example)
        totalSupply = 1000000000000000000000000000;                        // Update total supply (100000 for example)
        name = "KleynCoin";                                   // Set the name for display purposes ,Kleyn Coin 
        decimals = 18;                            // Amount of decimals for display purposes
        symbol = "KLB";                               // Set the symbol for display purposes
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}