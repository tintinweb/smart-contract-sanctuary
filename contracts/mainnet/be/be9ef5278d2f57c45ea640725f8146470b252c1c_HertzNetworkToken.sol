/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

/*
* MIT License
* ===========
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/


pragma solidity >= 0.4.22<0.6.0;

library SafeMath {
  function mul(uint a, uint b) internal pure  returns (uint) {
	uint c = a * b;
	assert(a == 0 || c / a == b);
	return c;
  }
 
  function div(uint a, uint b) internal pure  returns (uint) {
	// assert(b > 0); // Solidity automatically throws when dividing by 0
	uint c = a / b;
	// assert(a == b * c + a % b); // There is no case in which this doesn't hold
	return c;
  }
 
  function sub(uint a, uint b) internal pure returns (uint) {
	assert(b <= a);
	return a - b;
  }
 
  function add(uint a, uint b) internal  pure   returns (uint) {
	uint c = a + b;
	assert(c >= a);
	return c;
  }
}
contract HertzNetworkToken {
	using SafeMath for uint;
	uint private totalSupplyAmount;
	address private owner;
	mapping(address => uint) private balances;
	mapping(address => mapping(address => uint)) private allowed;
	string private tokenName;
	string private tokenSymbol;
	uint8 private decimalPoints;
	
	 /**
  * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
    require(msg.data.length >= size + 4) ;
    _;
  }
	constructor(string name,string symbol,
	uint initialSupply,uint8 decimals) public {
    	tokenName=name;
    	tokenSymbol=symbol;
    	decimalPoints=decimals;
    	uint supply=SafeMath.mul(initialSupply,10**uint(decimalPoints));
    	totalSupplyAmount=supply;
    	owner=msg.sender;
    	balances[owner]=SafeMath.add(balances[owner],totalSupplyAmount);
    	emit Transfer(address(0),owner,totalSupplyAmount);
	}
    
	function name() public view returns(string memory){
    	return tokenName;
	}
    
	function symbol() public view returns(string memory){
    	return tokenSymbol;
	}
    
	function decimals() public view returns(uint){
    	return decimalPoints;
	}
 
	function totalSupply() public view returns(uint){
    	return totalSupplyAmount;
	}
    
	function balanceOf(address findingBalanceAddress) public view returns(uint){
    	return balances[findingBalanceAddress];
	}
    
	function getTokenOwnerAddress() public view returns(address){
    	return owner;
	}
    
	function transfer(address to,uint tokenAmountInWEI) public returns(bool){
    	require(balances[msg.sender]>=tokenAmountInWEI);
    	require(tokenAmountInWEI>0);
    	require((SafeMath.add(balances[to],tokenAmountInWEI))>balances[to]);
    	balances[msg.sender] = SafeMath.sub(balances[msg.sender],tokenAmountInWEI);
    	balances[to] = SafeMath.add(balances[to],tokenAmountInWEI);
    	emit Transfer(msg.sender,to,tokenAmountInWEI);
    	return true;
	}

	function transferFrom(address from,address to,uint tokenAmountInWEI) onlyPayloadSize(3 * 32) public returns(bool){
 	    require(balances[from]>=tokenAmountInWEI);   
 	    require(allowed[from] [msg.sender]>=tokenAmountInWEI);
 	    require(tokenAmountInWEI>0);
    
 	    require((SafeMath.add(balances[to],tokenAmountInWEI))>balances[to]);
 	    balances[to] = SafeMath.add(balances[to],tokenAmountInWEI);
 	    balances[from] = SafeMath.sub(balances[from],tokenAmountInWEI);
 	    allowed[from][msg.sender] = SafeMath.sub(allowed[from][msg.sender],tokenAmountInWEI);
 	    emit Transfer(from,to,tokenAmountInWEI);
 	    return true;
	}
    
	function approve(address spender,uint tokenAmountInWEI) public  returns(bool){
    	allowed[msg.sender][spender]=SafeMath.add(allowed[msg.sender][spender],tokenAmountInWEI);
     	emit  Approval(msg.sender,spender,tokenAmountInWEI);
    	return true;
	}
    
	function allownce(address from,address spender) public view returns(uint){
    	return allowed[from][spender];
	}
	
	function burn (uint tokenAmount) public returns(bool){
	    uint amountInWEI=SafeMath.mul(tokenAmount,10**uint(decimalPoints));
	    require(msg.sender==owner && balances[msg.sender]>=amountInWEI && totalSupplyAmount>=amountInWEI);
        totalSupplyAmount=SafeMath.sub(totalSupplyAmount,amountInWEI);
        balances[msg.sender]=SafeMath.sub(balances[msg.sender],amountInWEI);
        emit Transfer(msg.sender,address(0),amountInWEI);
        return true;
	}
	
	event Transfer(address indexed from,address indexed to,uint amount);
	event Approval(address indexed indexer,address indexed spender,uint amount);
}