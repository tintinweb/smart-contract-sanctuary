pragma solidity ^0.5.2;

contract BooToken {
    // ERC20 comaptibility for liquidity tokens
    bytes32 public name;
    bytes32 public symbol;
    uint256 public decimals;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
    
    constructor() public {
        name = "The Boo Token";
        symbol = "&#128123;";
        decimals = 18;
    }
    
    function transfer(address _to, uint256 _value) external returns (bool) {
        if (balances[msg.sender] < _value) {
            return false;
        }
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        require(balances[_to] >= _value);
        return true;
    }

    function mint(uint256 _value) external returns (bool) {
        balances[msg.sender] += _value;
        require(balances[msg.sender] >= _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        if (balances[_from] < _value || allowances[_from][_to] < _value) {
            return false;
        }
        allowances[_from][_to] -= _value;
        balances[_from] -= _value;
        balances[_to] += _value;
        require(balances[_to] >= _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        if (balances[msg.sender] < _value) {
            return false;
        }
        allowances[msg.sender][_spender] = _value;
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowances[_owner][_spender];
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }
}