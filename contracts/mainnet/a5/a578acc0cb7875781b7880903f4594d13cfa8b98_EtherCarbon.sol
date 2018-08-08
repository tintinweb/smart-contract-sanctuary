/**
 *  Ether Carbon Token, ERC20 compliant (see https://github.com/ethereum/EIPs/issues/20)
 *
 *  Code is based on multiple sources:
 *  https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/ERC20.sol
 *  https://github.com/ConsenSys/Tokens/blob/master/Token_Contracts/contracts/HumanStandardToken.sol
 */

pragma solidity ^0.4.13;


contract Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        require(_to != 0x00);
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
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
    address owner;
}



contract  EtherCarbon is StandardToken {

    
    /* Public variables of the token */
    string public name = " EtherCarbon";
    uint256 public decimals = 2;
    string public symbol = "ECN";
    
    event Mint(address indexed owner,uint amount);
    
    function EtherCarbon() {
        owner = 0x9362586f90abad2D25309033320C9Affc97AEb7D;
        /* Total supply is Five million (5,000,000)*/
        balances[0x9362586f90abad2D25309033320C9Affc97AEb7D] = 5000000 * 10**decimals;
        totalSupply = 5000000 * 10**decimals;
    }

    function mint(uint amount) onlyOwner returns(bool minted ){
        if (amount > 0){
            totalSupply += amount;
            balances[owner] += amount;
            Mint(msg.sender,amount);
            return true;
        }
        return false;
    }

    modifier onlyOwner() { 
        if (msg.sender != owner) revert(); 
        _; 
    }
    
    function setOwner(address _owner) onlyOwner{
        balances[_owner] = balances[owner];
        balances[owner] = 0;
        owner = _owner;
    }

}