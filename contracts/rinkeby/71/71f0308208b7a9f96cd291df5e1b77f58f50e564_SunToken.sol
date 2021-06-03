/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

/**
 * 测试网络  智能合约源码
 */
pragma solidity ^0.4.26;


library safeMath{
    function Add(uint256 a, uint256 b)internal pure returns(uint256){
        uint256 c = a + b;
        require( c >= a && c >= b);
        return c;
    }
    function Sub(uint256 a, uint256 b)internal pure returns(uint256){
        require( a >= b);
        uint256 c = a - b;
        return c;
    }
    function Mul(uint256 a, uint256 b)internal pure returns(uint256){
        uint256 c = a * b;
        require( a == 0 || c / a == b);
        return c;
    }
    function Div(uint256 a, uint256 b)internal pure returns(uint256){
        require(b > 0);
        uint256 c = a / b;
        require( a == b * c + a % b);
        return c;
    }
}

contract Token{
    uint256 public totalSupply;
    function transfer(address _to, uint256 _value) public returns(bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value)public returns(bool);
    function allowance(address _owner, address _spender) public constant returns(uint256);
    function balanceOf(address _owner) public constant returns(uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    using safeMath for uint256;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function balanceOf(address _owner) public constant returns(uint256){
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value)public returns(bool){
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
    }

    function allowance(address _owner, address _spender) public constant returns(uint256){
        return allowed[_owner][_spender];
    }

    function transfer (address _to, uint256 _value)public returns(bool){
        require(_to != address(0));
        require(_value >= 0);
        require(_value <= balances[msg.sender]);
        require(balances[_to] + _value > balances[_to]);
        balances[msg.sender] = safeMath.Sub(balances[msg.sender], _value);
        balances[_to] = safeMath.Add(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        require(_to != address(0));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require(balances[_to] + _value > balances[_to]);
        balances[_to] = safeMath.Add(balances[_to], _value);
        balances[_from] = safeMath.Sub(balances[_from], _value);
        allowed[_from][msg.sender] = safeMath.Sub(allowed[_from][msg.sender],_value);
        emit Transfer(_from, _to, _value);
        return true;
    }


}

contract SunToken is StandardToken {

    string constant public name = "SunToken";
    string constant public symbol = "SUN";
    uint8 constant public decimals = 18;

    function SunToken()public{
        totalSupply = 100000000 * 10**18;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
}