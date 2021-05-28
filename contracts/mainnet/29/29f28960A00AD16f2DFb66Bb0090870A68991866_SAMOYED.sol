/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

pragma solidity ^0.4.4;

contract Token {

    /// @return :Returns the circulation of the token
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner :Query the token balance of Ethereum address
    /// @return The balance 
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice msg.sender (transaction sender) send_ Value (a certain number of tokens) to_ To (recipient)
    /// @param _to :Recipient's address
    /// @param _value Number of tokens sent
    /// @return Is it successful
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice Sender sent_ Value (a certain number of tokens) to_ To (recipient) 
    /// @param _from :Sender Address
    /// @param _to :Recipient's address
    /// @param _value : Number sent
    /// @return : Is it successful
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice :The publisher approves a certain number of tokens to be sent from one address
    /// @param _spender : Address to send token
    /// @param _value : Number of tokens sent
    /// @return  : Is it successful
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner : Address with token
    /// @param _spender : The address where the token can be sent
    /// @return The number of tokens that are also allowed to be sent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    /// Send token event
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    ///Approval event
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //The default token circulation cannot exceed (2 ^ 256 - 1)
        //If you don't set the circulation and have more tokens over time, you need to make sure 
        //that you don't exceed the maximum, use the following if statement
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //The same as above, if you want to make sure the circulation does not exceed the maximum
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

contract SAMOYED is StandardToken {

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
    string public name;                    //Token Name: SAMOYED
    uint8 public decimals;                //Decimal place
    string public symbol;                 //identification
    string public version = 'H0.1';       //Version number

    function SAMOYED(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) {
        balances[msg.sender] = _initialAmount;               //The contract publisher's balance is the number of issues
        totalSupply = _initialAmount;                        //Circulation
        name = _tokenName;                                  //Token name
        decimals = _decimalUnits;                           // Token decimal
        symbol = _tokenSymbol;                              //Token identification
    }

    /*Approval and then call the receiving contract. */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //Call the receiveapprovalcall method that you want to notify the contract. This method does not need to be included in the contract.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //Assume that this can succeed, otherwise you should call vanilla approve.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}