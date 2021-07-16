/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;


contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}



abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);
    event Issue(uint amount);
    event Deprecate(address newAddress);
}



abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
}



contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        if (newOwner != address(0)) {newOwner = _newOwner;}
    }
    
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}



contract Paused is Owned {
    
  event Pause();
  event Unpause();


  bool public paused = false;
  
  
  modifier isNotPaused() {
    require(!paused);
    _;
  }


  modifier isPaused() {
    require(paused);
    _;
  }


  function pause() onlyOwner isNotPaused public {
    paused = true;
    emit Pause();
  }
  
  
  function unpause() onlyOwner isPaused public {
    paused = false;
    emit Unpause();
  }
}



contract YCN is ERC20Interface, Owned, Paused, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint internal _totalSupply;
    address public upgradedAddress;
    bool public deprecated = false;

    mapping(address => uint) balances;
    mapping (address => uint256) public freezeOf;
    mapping(address => mapping(address => uint)) allowed;
    
    

    constructor() {
        symbol = "YCN";
        name = "YCN";
        decimals = 18;
        _totalSupply = 2000000000 * 10 ** 18;
        deprecated = false;
        paused = false;
        balances[0x8477539B55fe0969bB9713b00Bd23acdF8524Ad2] = _totalSupply;
        emit Transfer(address(0), 0x8477539B55fe0969bB9713b00Bd23acdF8524Ad2, _totalSupply);
    }



    function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }



    function transfer(address to, uint tokens) public isNotPaused override returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    
    
    function transferFrom(address from, address to, uint tokens) public isNotPaused override returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    
    
    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    

    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }




    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }



    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
    
    
    
    function burn(uint256 _value) public returns (bool success) {
        if (balances[msg.sender] < _value) revert();            
		if (_value <= 0) revert(); 
        balances[msg.sender] = SafeMath.safeSub(balances[msg.sender], _value);                      
        _totalSupply = SafeMath.safeSub(_totalSupply,_value);                                
        emit Burn(msg.sender, _value);
        return true;
    }
    
	
	
	function freeze(uint256 _value) public returns (bool success) {
        if (balances[msg.sender] < _value) revert();       
		if (_value <= 0) revert(); 
        balances[msg.sender] = SafeMath.safeSub(balances[msg.sender], _value);                     
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                           
        emit Freeze(msg.sender, _value);
        return true;
    }
	
	
	
	function unfreeze(uint256 _value) public returns (bool success) {
        if (freezeOf[msg.sender] < _value) revert();          
		if (_value <= 0) revert(); 
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                  
		balances[msg.sender] = SafeMath.safeAdd(balances[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
    
    
    
    function issue(uint amount) public onlyOwner {
        require(_totalSupply + amount > _totalSupply);
        require(balances[owner] + amount > balances[owner]);
        balances[owner] += amount;
        _totalSupply += amount;
        emit Issue(amount);
    }
    
    
    
    function deprecate(address _upgradedAddress) public onlyOwner {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }

    

    fallback() external payable {
    }


    receive() external payable {
    }
}