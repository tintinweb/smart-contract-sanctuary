/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

pragma solidity ^0.6.0;
contract MooMoo {
    string  public name = "Kwame Coin";                      // Set the name for display purposes
    string  public symbol = "KWAME";                             // Set the symbol for display purposes
    uint256 public totalSupply_ = 2100000000000000000000000000;    // Give the creator all initial tokens (100000 for example)
    uint8   public decimals = 18;                               // Amount of decimals for display purposes

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    constructor() public {
        balances[msg.sender] = totalSupply_;
    }
    
    // @return total amount of tokens
    
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    
    // @param address_owner The address from which the balance will be retrieved
    // @return The balance
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    
    
    
    // @notice send `_value` token to `_to` from `msg.sender`
    // @param _to The address of the recipient
    // @param _value The amount of token to be transferred
    // @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    // @notice `msg.sender` approves `_addr` to spend `_value` tokens
    // @param _spender The address of the account able to transfer the tokens
    // @param _value The amount of wei to be approved for transfer
    // @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    // @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    // @param _from The address of the sender
    // @param _to The address of the recipient
    // @param _value The amount of token to be transferred
    // @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    // @param _owner The address of the account owning tokens
    // @param _spender The address of the account able to transfer the tokens
    // @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}