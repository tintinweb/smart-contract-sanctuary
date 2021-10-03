/**
 *Submitted for verification at BscScan.com on 2021-10-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


/**
ERC20 Token
 
Symbol                  : CC
Name                    : Cybercash
Initial total supply    : 104 250 000
Decimals                : 18
 
*/
 
abstract contract ERC20Interface {
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  function balanceOf(address _owner) public view virtual returns (uint256 balance);
  function transfer(address _to, uint256 _value) public virtual returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
  function approve(address _spender, uint256 _value) public virtual returns (bool success);
  function allowance(address _owner, address _spender) public view virtual returns (uint256 remaining);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract TokenAccessControl {
    
    bool public paused = false;
    address public owner;
    address public newContractOwner;
 
    event Pause();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    constructor () {
        owner = msg.sender;
    }
 
    modifier ifNotPaused {
        require(!paused);
        _;
    }
 
    modifier onlyContractOwner {
        require(msg.sender == owner);
        _;
    }
 
    function transferOwnership(address _newOwner) external onlyContractOwner {
        require(_newOwner != address(0));
        newContractOwner = _newOwner;
    }
 
    function acceptOwnership() external {
        require(msg.sender == newContractOwner);
        emit OwnershipTransferred(owner, newContractOwner);
        owner = newContractOwner;
        newContractOwner = address(0);
    }
    
    function setPause(bool _paused) public onlyContractOwner {
        paused = _paused;
        if (paused) {
            emit Pause();
        }
    }
   
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

abstract contract TokenRecipient {
 function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public virtual;
}

contract CybercashToken is ERC20Interface, TokenAccessControl {
    uint256 public maxSupply;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowed;
    using SafeMath for uint256;
  
 constructor() {
   name = "Cybercash";
   symbol = "Ccash";
   decimals = 18;
   totalSupply = 104250000 * 10 ** uint256(decimals);
   maxSupply = 100000000000 * 10 ** uint256(decimals);
   _balances[msg.sender] = totalSupply;
 }
 
 event Burn(address indexed from, uint256 value);
 
  function changeNameAndSymbol(string memory _name, string memory _symbol) public onlyContractOwner {
      name = _name;
      symbol = _symbol;
  }
 
 function mint(uint256 _amount) public onlyContractOwner ifNotPaused returns (bool success) {
   require(totalSupply.add(_amount) <= maxSupply);
   _balances[msg.sender] = _balances[msg.sender].add(_amount);
   totalSupply = totalSupply.add(_amount);
   return true;
 }
 
 function balanceOf(address _owner) public view override returns (uint256 balance) {
   return _balances[_owner];
 }
 
 function transfer(address _to, uint256 _value) public override ifNotPaused returns (bool success) {
   _transfer(msg.sender, _to, _value);
   return true;
 }
 
 function batchTransfer(address[] memory _to, uint256[] memory _value) public ifNotPaused returns (bool success) {
   require(_to.length == _value.length);
   uint256 i;
   for (i = 0; i < _to.length; i++) {
       _transfer(msg.sender, _to[i], _value[i]);
   }
   return true;
 }
 
 function transferFrom(address _from, address _to, uint256 _value) public override ifNotPaused returns (bool success) {
   require(_value <= _allowed[_from][msg.sender]);
   _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
   _transfer(_from, _to, _value);
   return true;
 }
 
 function approve(address _spender, uint256 _value) public override ifNotPaused returns (bool success) {
   _allowed[msg.sender][_spender] = _value;
   emit Approval(msg.sender, _spender, _value);
   return true;
 }
 
 function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {
   return _allowed[_owner][_spender];
 }
 
 function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public ifNotPaused returns (bool success) {
   TokenRecipient spender = TokenRecipient(_spender);
   approve(_spender, _value);
   spender.receiveApproval(msg.sender, _value, address(this), _extraData);
   return true;
 }
 
 function burn(uint256 _value) public ifNotPaused returns (bool success) {
   require(_balances[msg.sender] >= _value);
   _balances[msg.sender] = _balances[msg.sender].sub(_value);
   totalSupply = totalSupply.sub(_value);
   emit Burn(msg.sender, _value);
   return true;
 }
 
 function burnFrom(address _from, uint256 _value) public ifNotPaused returns (bool success) {
   require(_balances[_from] >= _value);
   require(_value <= _allowed[_from][msg.sender]);
   _balances[_from] = _balances[_from].sub(_value);
   _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
   totalSupply = totalSupply.sub(_value);
   emit Burn(_from, _value);
   return true;
 }
 
 function _transfer(address _from, address _to, uint _value) internal {
   require(_to != address(0x0));
   require(_balances[_from] >= _value);
   require(_balances[_to].add(_value) > _balances[_to]);
  
   uint previousBalances = _balances[_from].add(_balances[_to]);
   _balances[_from] = _balances[_from].sub(_value);
   _balances[_to] = _balances[_to].add(_value);
   emit Transfer(_from, _to, _value);
   assert(_balances[_from].add(_balances[_to]) == previousBalances);
 }
 
 receive() external payable{
 }
  
 fallback() external payable {
   revert();
 }
    
 function withdrawBalance(uint256 _amount) external onlyContractOwner {
     payable(owner).transfer(_amount);
 }
 
}