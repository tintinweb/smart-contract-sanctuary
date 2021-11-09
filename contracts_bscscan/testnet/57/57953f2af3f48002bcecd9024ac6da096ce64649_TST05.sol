/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

/*
	 Submitted for verification at BscScan.com on data
	*/
	
	
	// SPDX-License-Identifier: MIT
	
	pragma solidity 0.8.6;
	
	abstract contract BEP20Interface {
	    function totalSupply() public virtual view returns (uint);
	    function balanceOf(address tokenOwnerBr007) public virtual view returns (uint balance);
	    function allowance(address tokenOwnerBr007, address spenderBr007) public virtual view returns (uint remaining);
	    function transfer(address to, uint tokens) public virtual returns (bool success);
	    function approve(address spenderBr007, uint tokens) public virtual returns (bool success);
	    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);
	
	    event Transfer(address indexed from, address indexed to, uint tokens);
	    event Approval(address indexed tokenOwnerBr007, address indexed spenderBr007, uint tokens);
	}
	

	contract TST05_ {
function sum(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        require(c >= a);

        return c;
    }

    function sub(uint a, uint b) internal pure returns(uint) {
        require(b <= a);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns(uint) {
        if(a == 0) {
            return 0;
        } 

        uint c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint a, uint b) internal pure returns(uint) {
        uint c = a / b;

        return c;
    }
}
	

	contract TST05 is BEP20Interface, TST05_ {
	    string public tokenNameBr007 = "TST05";
	    string public tokenSymbolBr007 = "TST05";
	    uint public _tokenSupplyBr007 = 50000000000 * 10**8;
	
	    mapping(address => uint) _balances;
	    mapping(address => mapping(address => uint)) allowed;
	
	    constructor() {
	        _balances[msg.sender] = _tokenSupplyBr007;
	        emit Transfer(address(0), msg.sender, _tokenSupplyBr007);
	    }
	    
	     function name() public view virtual returns (string memory) {
	        return tokenNameBr007;
	    }
	
	
	    function symbol() public view virtual returns (string memory) {
	        return tokenSymbolBr007;
	    }
	
	
	    function decimals() public view virtual returns (uint8) {
	        return 8;
	    }
	
	    function totalSupply() public override view returns (uint) {
	        return _tokenSupplyBr007;
	    }
	
	    function balanceOf(address tokenOwnerBr007) public override view returns (uint balance) {
	        return _balances[tokenOwnerBr007];
	    }
	
	    function allowance(address tokenOwnerBr007, address spenderBr007) public override view returns (uint remaining) {
	        return allowed[tokenOwnerBr007][spenderBr007];
	    }
	    
	   function _transfer(address sender, address recipient, uint256 amount) internal virtual {
	        require(sender != address(0), "BEP20: transfer from the zero address");
	        require(recipient != address(0), "BEP20: transfer to the zero address");
	
	        _beforeTokenTransfer(sender, recipient, amount);
	
	        uint256 senderBalance = _balances[sender];
	        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
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
	
	    function approve(address spenderBr007, uint tokens) public override returns (bool success) {
	        allowed[msg.sender][spenderBr007] = tokens;
	        emit Approval(msg.sender, spenderBr007, tokens);
	        return true;
	    }
	
	    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
	        allowed[from][msg.sender] = sub(allowed[from][msg.sender], tokens);
	        _transfer(from, to, tokens);
	        emit Transfer(from, to, tokens);
	        return true;
	    }
	    
	    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
	}