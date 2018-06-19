/**
 * Created by DiceyBit.com Team on 8/25/17.
 * 
 * @title DiceyBit preICO solidity contract
 * @author DiceyBit Team
 * @description ERC20 Standard Token
 * 
 * Copyright &#169; 2017 DiceyBit.com
 */

pragma solidity ^0.4.11;

contract Token {
    string public standard = &#39;Token 0.1.8 diceybit.com&#39;;
    string public name = &#39;DICEYBIT.COM&#39;;
    string public symbol = &#39;dСBT&#39;;
    uint8 public decimals = 0;
    uint256 public totalSupply = 100000000;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowed;

    function Token() {
        balanceOf[msg.sender] = totalSupply;
    }

    // @brief Send coins
    // @param _to recipient of coins
    // @param _value amount of coins for send
    function transfer(address _to, uint256 _value) {
        require(_value > 0 && balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        Transfer(msg.sender, _to, _value);
    }

    // @brief Send coins
    // @param _from source of coins
    // @param _to recipient of coins
    // @param _value amount of coins for send
    function transferFrom(address _from, address _to, uint256 _value) {
        require(_value > 0 && balanceOf[_from] >= _value && allowed[_from][msg.sender] >= _value);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowed[_from][msg.sender] -= _value;

        Transfer(_from, _to, _value);
    }

    // @brief Allow another contract to spend some tokens in your behalf
    // @param _spender another contract address
    // @param _value amount of approved tokens
    function approve(address _spender, uint256 _value) {
        allowed[msg.sender][_spender] = _value;
    }

    // @brief Get allowed amount of tokens
    // @param _owner owner of allowance
    // @param _spender spender contract
    // @return the rest of allowed tokens
    function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // @brief Shows balance of specified address
    // @param _who tokens owner
    // @return the rest of tokens
    function getBalanceOf(address _who) returns(uint256 amount) {
        return balanceOf[_who];
    }
}