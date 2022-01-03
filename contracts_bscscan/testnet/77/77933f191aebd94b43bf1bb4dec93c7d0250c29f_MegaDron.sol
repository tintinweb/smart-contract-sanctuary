/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.10;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b > 0);
    c = a / b;
  }
}

contract BEP20Interface {
  function totalSupply() public view returns (uint256);
  function balanceOf(address tokenOwner) public view returns (uint256 balance);
  function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
  function transfer(address to, uint256 tokens) public returns (bool success);
  function approve(address spender, uint256 tokens) public returns (bool success);
  function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint256 tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }
  function acceptOwnership() public {
    require(msg.sender == newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }
}

contract BEP20Token is BEP20Interface, Owned {
  using SafeMath for uint256;

  string public symbol;
  string public name;
  uint256 public decimals;
  uint256 _totalSupply;

  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) allowed;

  constructor() public {
    symbol = "MGD";
    name = "MegaDron";
    decimals = 18;
    _totalSupply =  1000000000e18;
    balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply.sub(balances[address(0)]);
  }
  function balanceOf(address tokenOwner) public view returns (uint256 balance) {
      return balances[tokenOwner];
  }
  function transfer(address to, uint256 tokens) public returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }
  function approve(address spender, uint256 tokens) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }
  function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }
  function allowance(address tokenOwner, address spender) public view returns (uint256 remaining) {
    return allowed[tokenOwner][spender];
  }
  function approveAndCall(address spender, uint256 tokens, bytes memory data) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
    return true;
  }
  function () external payable {
    revert();
  }
}

contract MegaDron is BEP20Token {
  uint256 public aSBlock; 
  uint256 public aEBlock; 
  uint256 public aCap; 
  uint256 public aTot; 
  uint256 public aAmt; 


  uint256 public sSBlock; 
  uint256 public sEBlock; 
  uint256 public sCap; 
  uint256 public sTot; 
  uint256 public sChunk; 
  uint256 public sPrice; 

  function getAirdrop(address _refer) public returns (bool success) {
    require(block.number >= aSBlock && block.number <= aEBlock);
    require(aTot < aCap || aCap == 0);
    aTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000) {
      balances[address(this)] = balances[address(this)].sub(aAmt);
      balances[_refer] = balances[_refer].add(aAmt);
      emit Transfer(address(this), _refer, aAmt);
    }
    balances[address(this)] = balances[address(this)].sub(aAmt);
    balances[msg.sender] = balances[msg.sender].add(aAmt);
    emit Transfer(address(this), msg.sender, aAmt);
    return true;
  }

  function tokenSale(address _refer) public payable returns (bool success) {
    require(block.number >= aSBlock && block.number <= aEBlock);
    require(sTot < sCap || sCap == 0);
    uint256 _bnb = msg.value;
    uint256 _result;
    if(sChunk != 0) {
      uint256 _price = _bnb / sPrice;
      _result = sChunk * _price;
    }
    else {
      _result = _bnb / sPrice;
    }
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000) {
      balances[address(this)] = balances[address(this)].sub(_result);
      balances[_refer] = balances[_refer].add(_result);
      emit Transfer(address(this), _refer, _result);
    }
    balances[address(this)] = balances[address(this)].sub(_result);
    balances[msg.sender] = balances[msg.sender].add(_result);
    emit Transfer(address(this), msg.sender, _result);
    return true;
  }

  function viewAirdrop() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 DropCap, uint256 DropCount, uint256 DropAmount) {
    return(aSBlock, aEBlock, aCap, aTot, aAmt);
  }

  function viewSale() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 SaleCap, uint256 SaleCount, uint256 ChunkSize, uint256 SalePrice) {
    return(sSBlock, sEBlock, sCap, sTot, sChunk, sPrice);
  }

  function startAirdrop(uint256 _aSBlock, uint256 _aEBlock, uint256 _aAmt, uint256 _aCap) public onlyOwner() {
    aSBlock = _aSBlock;
    aEBlock = _aEBlock;
    aAmt = _aAmt;
    aCap = _aCap;
    aTot = 0;
  }

  function startSale(uint256 _sSBlock, uint256 _sEBlock, uint256 _sChunk, uint256 _sPrice, uint256 _sCap) public onlyOwner() {
    sSBlock = _sSBlock;
    sEBlock = _sEBlock;
    sChunk = _sChunk;
    sPrice =_sPrice;
    sCap = _sCap;
    sTot = 0;
  }

  function mint(uint256 tokens) public onlyOwner() {
    require(address(this) != address(0), "BEP20: mint cannot to the zero address");
    balances[address(this)] = balances[address(this)].add(tokens);
    _totalSupply = _totalSupply.add(tokens);
    emit Transfer(address(0), address(this), tokens);
  }

  function burn(uint256 tokens) public onlyOwner() {
    require(tokens <= balances[address(this)]);
    balances[address(this)] = balances[address(this)].sub(tokens);
    _totalSupply = _totalSupply.sub(tokens);
    emit Transfer(address(this), 0x000000000000000000000000000000000000dEaD, tokens);
  }

  function clearBNB() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }

  function() external payable {
  }

}