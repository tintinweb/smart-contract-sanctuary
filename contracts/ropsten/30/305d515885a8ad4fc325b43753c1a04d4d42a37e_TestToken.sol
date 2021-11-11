/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

contract TestToken {
    address owner;
    string public name = "Test Token";
    string public symbol = "TEST";
    uint256 public totalSupply;
    uint256 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    constructor(uint256 _initialSupply) public {
        owner = address(msg.sender);
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        // self-destruct - no burning
        if (_to == owner) {
            balanceOf[msg.sender] -= _value;
            balanceOf[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        uint256 tokensToBurn = (_value * 2) / 100;
        require(balanceOf[msg.sender] >= _value + tokensToBurn);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        // 2% of what ? --------> 2% of tokensBought or 2% of totalTokens ?
        // 2% from whom ? --------> 2% of msg.sender or 2% of _to or 2% of address(this) ?
        // for now, 2% of tokens transferred, and from msg.sender
        // note- must supply crowd-sale with tokens at start- so it can transfer to others
        burn(msg.sender, tokensToBurn);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(address account, uint256 amount) internal {
        require(amount != 0);
        require(amount <= balanceOf[account]);
        totalSupply -= amount;
        balanceOf[account] -= amount;
        emit Transfer(account, address(0x0), amount);
    }
}