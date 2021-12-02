//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ZHKToken {
    string public constant name = "Zakharchuk Network";
    string public constant symbol = "ZHK";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 0;
    mapping(address => uint256) balances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        if (
            balances[msg.sender] < _value ||
            balances[_to] + _value > balances[_to]
        ) {
            return false;
        }

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        if (
            balances[_from] < _value || balances[_to] + _value > balances[_to]
        ) {
            return false;
        }

        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    // function approve(address _spender, uint256 _value)
    //     public
    //     pure
    //     returns (bool success)
    // {
    //     return false;
    // }

    // function allowance(address _owner, address _spender)
    //     public
    //     pure
    //     returns (uint256 remaining)
    // {
    //     return 0;
    // }

    function mint(address _to, uint256 _value) public {
        assert(
            totalSupply + _value >= totalSupply &&
                balances[_to] + _value >= balances[_to]
        );
        balances[_to] += _value;
        totalSupply += _value;
    }
}