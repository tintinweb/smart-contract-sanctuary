/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

// SPDX-License-Identifier: MIT
	pragma solidity 0.8.2;
 
	abstract contract MetaF20Interface {
	    function totalSupply() public virtual view returns (uint);
	    function balanceOf(address tokenOwnerMetaF) public virtual view returns (uint balance);
	    function allowance(address tokenOwnerMetaF, address spenderMetaF) public virtual view returns (uint remaining);
	    function transfer(address to, uint tokens) public virtual returns (bool success);
	    function approve(address spenderMetaF, uint tokens) public virtual returns (bool success);
	    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);
 
	    event Transfer(address indexed from, address indexed to, uint tokens);
	    event Approval(address indexed tokenOwnerMetaF, address indexed spenderMetaF, uint tokens);
	}
 
	pragma solidity 0.8.2;
 
	contract Math {
	    function safeAdd(uint x, uint b) public pure returns (uint y) {
	        y = x + b;
	        require(y >= x);
	    }
	    function safeSub(uint x, uint b) public pure returns (uint y) {
	        require(b <= x);
	        y = x - b;
	    }
	    function safeMul(uint x, uint b) public pure returns (uint y) {
	        y = x * b;
	        require(x == 0 || y / x == b);
	    }
	    function safeDiv(uint x, uint b) public pure returns (uint y) {
	        require(b > 0);
	        y = x / b;
	    }
	}
 
	pragma solidity 0.8.2;
 
	contract MetaFloki is MetaF20Interface, Math {
	    string public tokenNameMetaF = "Meta Floki";
	    string public tokenSymbolMetaF = "MetaF";
	    uint public _tokenSupplyMetaF = 1*10**9 * 10**9;
 
	    mapping(address => uint) _balances;
	    mapping(address => mapping(address => uint)) allowed;
 
	    constructor() {
	        _balances[msg.sender] = _tokenSupplyMetaF;
	        emit Transfer(address(0), msg.sender, _tokenSupplyMetaF);
	    }
 
	     function name() public view virtual returns (string memory) {
	        return tokenNameMetaF;
	    }
 
 
	    function symbol() public view virtual returns (string memory) {
	        return tokenSymbolMetaF;
	    }
 
 
	    function decimals() public view virtual returns (uint8) {
	        return 9;
	    }
 
	    function totalSupply() public override view returns (uint) {
	        return _tokenSupplyMetaF;
	    }
 
	    function balanceOf(address tokenOwnerMetaF) public override view returns (uint balance) {
	        return _balances[tokenOwnerMetaF];
	    }
 
	    function allowance(address tokenOwnerMetaF, address spenderMetaF) public override view returns (uint remaining) {
	        return allowed[tokenOwnerMetaF][spenderMetaF];
	    }
 
	   function _transfer(address sender, address recipient, uint256 amount) internal virtual {
	        require(sender != address(0), "MetaF20: transfer from the zero address");
	        require(recipient != address(0), "MetaF20: transfer to the zero address");
 
	        _beforeTokenTransfer(sender, recipient, amount);
 
	        uint256 senderBalance = _balances[sender];
	        require(senderBalance >= amount, "MetaF20: transfer amount exceeds balance");
	        unchecked {
	            _balances[sender] = senderBalance - amount;
	        }
	        _balances[recipient] += amount;
 
	        emit Transfer(sender, recipient, amount);
	    }
 
	    function transfer(address to, uint tokens) public override returns (bool success) {
	        _transfer(msg.sender, to, tokens);
	        emit Transfer(msg.sender, to, tokens);
	        return true;
	    }
 
	    function approve(address spenderMetaF, uint tokens) public override returns (bool success) {
	        allowed[msg.sender][spenderMetaF] = tokens;
	        emit Approval(msg.sender, spenderMetaF, tokens);
	        return true;
	    }
 
	    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
	        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
	        _transfer(from, to, tokens);
	        emit Transfer(from, to, tokens);
	        return true;
	    }
 
	    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
	}