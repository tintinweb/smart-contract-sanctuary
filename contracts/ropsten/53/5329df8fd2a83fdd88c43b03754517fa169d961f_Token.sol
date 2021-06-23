/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;
/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

/**
 * ERC-20 Token Interface
 *
 * https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {

    /// @return supply total amount of tokens
    function totalSupply() virtual public view returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance The balance
    function balanceOf(address _owner) virtual public view returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) virtual public returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender, uint256 _value) virtual public returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) virtual public view returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

/**
 * Standard ERC-20 token
 */
contract StandardToken is ERC20 {
    uint256 circulation;
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function totalSupply() override public view returns (uint256 supply) {
        return circulation;
    }

    function balanceOf(address _address) override public view returns (uint256 balance) {
        return balances[_address];
    }

    function transfer(address _to, uint256 _value) override public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _value) override public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) override public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}


contract Token is StandardToken {
    address public god;
    string public constant name = 'USDC test';
    string public constant symbol = 'USDC';
    uint public constant decimals = 18;

    constructor() public {
        circulation = 0;
        god = msg.sender;
    }

    function mint(address _to, uint256 _value) public {
        circulation += _value;
        balances[_to] += _value;
        emit Transfer(address(0), _to, _value);
    }
}