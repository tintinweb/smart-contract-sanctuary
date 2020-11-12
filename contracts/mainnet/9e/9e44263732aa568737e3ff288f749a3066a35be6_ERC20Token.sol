pragma solidity ^0.4.20;

contract Token {


    /// @return total amount of tokens

    function totalSupply() constant returns (uint256 supply) {}


    /// @param _owner The address from which the balance will be retrieved

    /// @return The balance

    function balanceOf(address _owner) constant returns (uint256 balance) {}


    /// @notice send `_value` token to `_to` from `msg.sender`

    /// @param _to The address of the recipient

    /// @param _value The amount of token to be transferred

    /// @return Whether the transfer was successful or not

    function transfer(address _to, uint256 _value) returns (bool success) {}


    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`

    /// @param _from The address of the sender

    /// @param _to The address of the recipient

    /// @param _value The amount of token to be transferred

    /// @return Whether the transfer was successful or not

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}


    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens

    /// @param _spender The address of the account able to transfer the tokens

    /// @param _value The amount of wei to be approved for transfer

    /// @return Whether the approval was successful or not

    function approve(address _spender, uint256 _value) returns (bool success) {}


    /// @param _owner The address of the account owning tokens

    /// @param _spender The address of the account able to transfer the tokens

    /// @return Amount of remaining tokens allowed to spent

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}


    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


}


contract StandardToken is Token {


    function transfer(address _to, uint256 _value) returns (bool success) {

        //

        //

        //

        //

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


//name this contract whatever you'd like

contract ERC20Token is StandardToken {


    function () {

        //

        throw;

    }


    /* Public variables of the token */


    /*

    

    */

    string public name;                   

    uint8 public decimals;                

    string public symbol;                 

    string public version = 'H1.0';       


//

// CHANGE THESE VALUES FOR YOUR TOKEN

//


//make sure this function name matches the contract name above. So if you're token is called TutorialToken, make sure the //contract name above is also TutorialToken instead of ERC20Token


    function ERC20Token(

        ) {

        balances[msg.sender] = 100000000000000000;               

        totalSupply = 100000000000000000;                        

        name = "Poseidon Finance";                                   

        decimals = 8;                            

        symbol = "POSF";                               

    }


    /* Approves and then calls the receiving contract */

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {

        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);


        //

        //

        //

        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }

        return true;

    }

}