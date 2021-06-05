/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

/**
 *Submitted for verification at Etherscan.io on 2020-05-15
*/

pragma solidity ^0.4.20;

contract Token {

    function totalSupply() constant returns (uint256 supply) {}
    
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    function transfer(address _to, uint256 _value) returns (bool success) {}

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    function approve(address _spender, uint256 _value) returns (bool success) {}

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


contract StandardToken is Token {


    function transfer(address _to, uint256 _value) returns (bool success) {

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

contract HAZARDToken is StandardToken {


    function () {

        //if ether is sent to this address, send it back.

        throw;

    }


    /* Public variables of the token */


    /*

    NOTE:

    The following variables are OPTIONAL vanities. One does not have to include them.

    They allow one to customise the token contract & in no way influences the core functionality.

    Some wallets/interfaces might not even bother to look at this information.

    */

    string public name;                   //fancy name: eg Simon Bucks

    uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It's like comparing 1 wei to 1 ether.

    string public symbol;                 //An identifier: eg SBX

    string public version = 'H1.0';       //human 0.1 standard. Just an arbitrary versioning scheme.



    function HAZARDToken(

        ) {

        balances[msg.sender] = 100000000000000;              // Give the creator all initial tokens (100000 for example)

        totalSupply = 100000000000000;                        // Update total supply (100000 for example)

        name = "BitcoinETH";                                   // Set the name for display purposes

        decimals = 8;                            // Amount of decimals for display purposes

        symbol = "HAZARD";                               // Set the symbol for display purposes

    }


    /* Approves and then calls the receiving contract */

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {

        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);


        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.

        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)

        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.

        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }

        return true;

    }

}