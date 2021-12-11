/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

pragma solidity ^0.4.26;


// Math operations with safety checks that throw on error
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Math error");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Math error");
        return a - b;
    }
}


// Abstract contract for the full ERC 20 Token standard
contract ERC20 {
    function balanceOf(address _address) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// ETM Token contract
contract ETM is ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) public {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply * 10**18;
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address _address) public view returns (uint256) {
        return balances[_address];
    }

    function _transfer(address _from, address _to, uint256 _value) private {
        if (_to == address(0))
            totalSupply = SafeMath.sub(totalSupply, _value); // burn
        balances[_from] = SafeMath.sub(balances[_from], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _amount) public returns (bool) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        _transfer(_from, _to, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
}