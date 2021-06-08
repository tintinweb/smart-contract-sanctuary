/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// SPDX-License-Identifier: Unlicensed
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
    string public name;
    string public symbol;
    uint public decimals;
    uint256 public initialSupply;
    uint256 public totalSupply;
    uint256 public burnStopSupply;
    string public burnPercentage;
    using SafeMath for uint256;
    address payable creator;
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
   
    
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event Transfer(address indexed from, address indexed to,uint256 tokens);
 

    constructor( ) public payable{
        creator = msg.sender;
        name = "DOCOVSR";
        symbol = "DOCOVSR";
        initialSupply = 100000000 *10**18;   // Value is 100000000
        totalSupply = 100000000 *10**18;   // Value is 100000000
        burnStopSupply = 90000000 *10**18;   // Value is 20000000
        burnPercentage = "0.001%";
        decimals = 18;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }
    
    function findBurnTokens(uint256 numTokens) public view returns (uint256)  {
        uint256 burntokens_ =0;
        if (totalSupply > burnStopSupply)
        {
            burntokens_= numTokens.mul(1000000).div(1000000000);
        }
        return burntokens_;
  }
    
    function transfer(address receiver,uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        uint256 burntokens_ = findBurnTokens(numTokens);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        balances[creator] = balances[creator].sub(burntokens_);
        totalSupply = totalSupply.sub(burntokens_);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    
    function approve(address delegate,uint256 numTokens) public returns (bool) {
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
        
        balances[creator] = balances[creator].sub(numTokens);
        totalSupply = totalSupply.sub(burntokens_);
        allowed[msg.sender] [owner]= allowed[msg.sender][owner].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        
        return true;
    }
    
    
    
    event Received(address, uint256);
    function() external payable {
        emit Received(msg.sender, msg.value);
    }

}