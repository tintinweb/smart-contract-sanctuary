/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.2;

/// @title A ERC20 Token MVP named GitCoin (GTC)
/// @author Diego de Franco Matos
/// @notice This contract complies with the ERC20 implementation standard
/// @dev Code Updated to Version 0.8.x 

library SafeMath {

	function add(uint a, uint b) internal pure returns(uint){
        uint c = a + b;
        require(c >= a, "Sum Overflow!");
		return c;  
	}

	function sub(uint a, uint b) internal pure returns(uint){
        require(b <= a, "Sub Overflow!");    
        uint c = a - b;
		return c;  
	}

	function mul(uint a, uint b) internal pure returns(uint){
        if (a == 0) return 0;
        uint c = a * b;
        require(c / a == b, "Mul Overflow");
	return c;  
	}
	
	function div(uint a, uint b) internal pure returns(uint){
      uint c = a / b;
	  return c;  
	}


	function fpow(uint a, uint b) internal pure returns(uint){
		return a ** b;  
	}

}

 contract Ownable {

	address payable public owner;
    
	event OwnershipTransferred(address newOwner);

    constructor() payable {  
	    owner = payable(msg.sender);
	}

	modifier onlyOwner(){
		require(msg.sender == owner, "You are not the Owner!");
		_;
	}

	function transferOwnership(address payable newOwner) onlyOwner public {
		owner = newOwner;
        emit OwnershipTransferred(owner);
	}

}

abstract contract ERC20 {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) public  virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 contract BasicToken is Ownable, ERC20 {    

    using SafeMath for uint;
   
/*  Tipo   Visibilidade  Variável */
	uint   internal     _totalSupply; /*intenal visivel para qqer contrato que herde de Basic Token*/
    mapping(address => uint) internal _balances;
/*  mapping to approve function */
	mapping(address => mapping(address => uint)) internal _allowed;

	function totalSupply() override public view returns (uint){

		return _totalSupply;
	}

	function balanceOf(address tokenOwner) override public view returns (uint balance){

		return _balances[tokenOwner];
	}

	function transferFrom(address from, address to, uint tokens) override public returns (bool success) {
	 	require(_allowed[from][msg.sender] >= tokens);
		require(_balances[from] >= tokens); 
		require(to != address(0));

		  _balances[from] = _balances[from].sub(tokens);
		  _balances[to]   = _balances[to].add(tokens);
		  _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(tokens);

		  emit Transfer(msg.sender, to, tokens);

		  return true;
	}

	function approve(address spender, uint tokens) override public returns (bool success){
          
		  _allowed[msg.sender][spender] = tokens;

		  emit Approval(msg.sender, spender, tokens);

		  return true;

	}

	 function allowance(address tokenOwner, address spender) override
	   public view returns (uint remaining) {
	   
	   return _allowed[tokenOwner][spender];
	   }

	function transfer(address to, uint tokens) override public returns (bool success){
        require(_balances[msg.sender] >= tokens);
         _balances[msg.sender] = _balances[msg.sender].sub(tokens);
		 _balances[to] = _balances[to].add(tokens);

		return true;
	}

}

contract MintableToken is BasicToken {
	 using SafeMath for uint;

	event Mint(address indexed to, uint tokens);

	function mint(address to, uint tokens) onlyOwner public payable {

          _balances[to] = _balances[to].add(tokens); 
		  _totalSupply  = _totalSupply.add(tokens);

		  emit Mint(to, tokens);
	}
}
contract GitCoin is MintableToken {
	 using SafeMath for uint;

	string public constant name =    "Git Coin"; 
	string public constant symbol =  "GTC";
	uint8  public constant decimals = 18;

	}