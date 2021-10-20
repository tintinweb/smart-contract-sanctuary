/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

pragma solidity ^0.4.19;

contract ERC20Basic {

    string public constant name = "SmoothBrain"; //change token name
    string public constant symbol = "SMB"; // change token symbol
    uint8 public constant decimals = 18;  // default decimal amount


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances; // balance of each owner account

    mapping(address => mapping (address => uint256)) allowed; // stores approved accounts + withdrawal sum for each
    
    // set total supply of tokens
    uint256 totalSupply_;

    using SafeMath for uint256;


   constructor(uint256 total) public {  //constructor runs after contract is deployed
	totalSupply_ = total;
	balances[msg.sender] = totalSupply_;
    }  
    
    // get total token supply of contract
    function totalSupply() public view returns (uint256) {
	return totalSupply_;
    }
    
    // get token balance of owner
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    // transfer tokens to another account
    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    // Approve delegate to withdraw tokens for marketplaces without prior approval
    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        Approval(msg.sender, delegate, numTokens);
        return true;
    }

    // Get Number of Tokens Approved for Withdrawal
    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    // Transfer Tokens by Delegate from peer of approve function
    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    // verify owner has sufficient balance for xfer
        require(numTokens <= allowed[owner][msg.sender]); // verify delegate has approval for numtokens to withdraw
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        Transfer(owner, buyer, numTokens);
        return true;
    }
}


// including safemath lirbary for security - integer overflows
library SafeMath { 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}