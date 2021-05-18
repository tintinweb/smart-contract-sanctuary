/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

pragma solidity ^0.7.4;

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface ERC20Interface {

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract SampleCoin is ERC20Interface {
    using SafeMath for uint256;

    // Determined in compile-time, not take up state variable storage space
    // -> cheaper & safer
    string public constant name = "Gcoin";
    string public constant symbol = "Gcoin";

uint8 public immutable decimals;
uint256 toalSupply_;
mapping(address => uint256) private balances;
mapping(address => mapping(address => uint256)) private allowed;

constructor(uint8 _decimals, uint256 _totalSupply) {
decimals = _decimals;
toalSupply_ = _totalSupply;
balances[msg.sender] = _totalSupply;
}

function totalSupply() public override view returns (uint256) {
return toalSupply_;
}

function balanceOf(address _owner) public override view returns (uint256 balance) {
return balances[_owner];
}

function transfer(address _to, uint256 _value) public override returns (bool success) {
require(_to != address(0), "Cannot transfer to address(0)");
require(_value <= balances[msg.sender], "Balance not enough!");

balances[msg.sender] = balances[msg.sender].sub(_value);
balances[_to] = balances[_to].add(_value);
emit Transfer(msg.sender, _to, _value);
return true;
}

function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
require(_to != address(0), "Cannot transfer to address(0)");
require(_value <= allowed[_from][msg.sender], "Tokens allowed is not enough!");
require(_value <= balances[_from], "Balance not enough!");
balances[_from] = balances[_from].sub(_value);
allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
balances[_to] = balances[_to].add(_value);
emit Transfer(_from, _to, _value);
return true;
}


function approve(address _spender, uint256 _value) public override returns (bool success) {
allowed[msg.sender][_spender] = _value;
emit Approval(msg.sender, _spender, _value);
return true;
}

function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
return allowed[_owner][_spender];
}
}