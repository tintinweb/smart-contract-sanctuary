/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.5.0;

library SafeMath { // Only relevant functions
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256)   {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
          return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
      }
     function div(uint256 a, uint256 b) internal pure returns (uint256) {
         if (a == 0) {
          return 0;
        }
        uint256 c = a / b;
        return c;
      }
}

contract doco 
{
    uint256 initialSupply_;
    uint256 totalSupply_;
    uint decimal;
    string name;
    string symbol;
    uint256 burnStopSupply_;
    string burnPercentage_;
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
   
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to,uint tokens);
 

    constructor( ) public payable{
        name = "DOCOTOKENV";
        symbol = "DOCOV";
        initialSupply_ = 100000000 *10**18;   // Value is 100000000
        totalSupply_ = 100000000 *10**18 ;   // Value is 100000000
        burnStopSupply_ = 20000000 *10**18 ;   // Value is 20000000
        burnPercentage_ = "0.001%";
        decimal = 18;
        balances[msg.sender] = totalSupply_;
    }
    
    function tokenName() public view returns (string memory) {
        return name;
    }
    
    function tokenSymbol() public view returns (string memory) {
        return symbol;
    }
    
     function initialSupply() public view returns (uint256) {
        return initialSupply_;
    }
    
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function burnPercentage() public view returns (string memory) {
        return burnPercentage_;
    }   
    
    function burnStopSupply() public view returns (uint256) {
        return burnStopSupply_;
    }
    
    
    
    
    function Decimals() public view returns (uint){
        return decimal;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }
    
    function findBurnTokens(uint256 numTokens) public view returns (uint256)  {
        uint256 burntokens_ =0;
        if (totalSupply_ > burnStopSupply_)
        {
            burntokens_= numTokens.mul(100).div(100000);
        }
        return burntokens_;
  }
    
    function transfer(address receiver,uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        require(allowed[msg.sender][receiver] >= numTokens);
        uint256 burntokens_ = findBurnTokens(numTokens);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens).sub(burntokens_);
        emit Transfer(msg.sender, receiver, numTokens.sub(burntokens_));
        totalSupply_ = totalSupply_.sub(burntokens_);
        return true;
    }
    
    function approve(address delegate,uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }
    
    function allowance(address owner,address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }
    
    function transferFrom(address owner, address buyer, uint numTokens) public  returns (bool) {
        require(numTokens <= balances[msg.sender]);
        require(numTokens <= allowed[msg.sender][owner]);
        uint256 burntokens_ = findBurnTokens(numTokens);
        
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        totalSupply_ = totalSupply_.sub(burntokens_);
        allowed[msg.sender] [owner]= allowed[msg.sender][owner].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens).sub(burntokens_);
        emit Transfer(owner, buyer, numTokens);
        
        return true;
    }
    
    event Received(address, uint);
    function() external payable {
        emit Received(msg.sender, msg.value);
    }

}