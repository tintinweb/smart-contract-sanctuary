/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0<0.9.0;

/*
ERC-20 token
*/
contract BhangraCoin {



    string public name = 'Bhangra Coin';
    string public symbol = 'BGRA';
    string public standard = 'Bhangra Coin v1.1';
    uint256 public totalSupply;
    uint8 public decimals;

    // @dev Records data of all the tokens transferred
    // @param _from Address that sends tokens
    // @param _to Address that receives tokens
    // @param _value the amount that _spender can spend on behalf of _owner
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    // @dev Records data of an Approval to spend the tokens on behalf of
    // @param _owner address that approves to pay on its behalf
    // @param _spender address to whom the approval is issued
    // @param _value the amount that _spender can spend on behalf of _owner

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );


    //@dev mapping array for keeping the balances of all the accounts
    mapping(address => uint256) public balanceOf;

    //@dev amping array that keeps the allowance that is still allowed to withdraw from _owner
    mapping(address => mapping(address => uint256)) public allowance;
    //@notice account A approved account B to send C tokens (amount C is actually left )


    constructor(uint256 _intialSupply, uint8 _intialDecimals)
    public
    {
        balanceOf[msg.sender] = _intialSupply;
        totalSupply = _intialSupply;
        decimals = _intialDecimals;
    }


    // @dev Transfers tokens from sender account to
    // @param _from Address that sends tokens
    // @param _to Address that receives tokens
    // @param _value the amount that _spender can spend on behalf of _owner
    function transfer(address _to, uint256 _value)
    public
    returns(bool success)
    {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender] - _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // @dev Allows _spender to withdraw from [msg.sender] account multiple times,
    // up to the _value amount.
    // @param _spender address to whom the approval is issued
    // @param _value the amount that _spender can spend on behalf of _owner
    // @notice If this function is called again it overwrites the current allowance
    // with _value.
    function approve(address _spender, uint256 _value)
    public
    returns(bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // @dev Transfers tokens on behalf of _form account to _to account. [msg.sender]
    // should have an allowance from _from account to transfer the number of tokens.
    // @param _from address tokens are transferred from
    // @param _to address tokens are transferred to
    // @parram _value the number of tokens transferred
    // @notice _from account should have enough tokens and allowance should be equal
    // or greater than the amount transferred
    function transferFrom(address _from, address _to, uint256 _value)
    public
    returns(bool success)
    {
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_from] = balanceOf[_from] - _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}