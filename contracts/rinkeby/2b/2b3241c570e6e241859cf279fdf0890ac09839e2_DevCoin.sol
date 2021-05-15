/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
// @title DevCoin $DEV
contract Token {

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    uint256 public totalSupply;

    modifier requiredAmount(uint256 _value) {
        require(_value > 0, "ValueError: Values greater than 0 is required");
        _;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /*
     * @notice send '_value' token to '_to' from 'msg.sender'
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(address _to, uint256 _value) public requiredAmount(_value) returns(bool) {

        if (balances[msg.sender] >= _value) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    /*
     * @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transferFrom(address _from, address _to, uint256 _value) public requiredAmount(_value) returns(bool){

        if (balances[_from] > _value && allowed[_from][msg.sender] > _value){
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else{
            return false;
        }
    }

    /*
     * @param _owner The address from which the balance will be retrieved
     * @return The balance
     */
    function userBalance(address _owner) public view returns(uint256) {
        return balances[_owner];
    }

    /*
     *  @notice `msg.sender` approves `_addr` to spend `_value` tokens
     *  @param _spender The address of the account able to transfer the tokens
     *  @param _value The amount of wei to be approved for transfer
     *  @return Whether the approval was successful or not
     */
    function approve(address _spender, uint256 _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /*
     *  @param _owner The address of the account owning tokens
     *  @param _spender The address of the account able to transfer the tokens
     *  @return Amount of remaining tokens allowed to spent
     */
    function allowance(address _owner, address _spender) public view returns(uint256) {
        return allowed[_owner][_spender];
    }

}

contract DevCoin is Token {

    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = "H1.0";

    constructor() {
        balances[msg.sender] = 100000;
        totalSupply = 1000000;
        name = "DevCoin";
        decimals = 0;
        symbol = "$DEV";
    }

    function approveAndCall(address _spender, uint256 _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

}