/**
 *Submitted for verification at Etherscan.io on 2020-08-31
*/

pragma solidity ^0.6.0;

contract PION {

    string public constant name = "PION";
    string public constant symbol = "PION";
    uint256 public constant decimals = 18;  
    uint256 private constant initialSupply = 5000000*10**decimals;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_;
    address  contractOwner_;

    using SafeMath for uint256;


   constructor() public {  
        totalSupply_ = initialSupply;
        balances[msg.sender] = initialSupply;
        contractOwner_ = msg.sender;
        emit Transfer(address(0),msg.sender,initialSupply);
    }  
    
    function mint (uint rawAmount) public {
        require(msg.sender == contractOwner_);
        balances[msg.sender] =  balances[msg.sender].add(rawAmount);
        totalSupply_ = totalSupply_.add(rawAmount);
        emit Transfer(address(0x0),msg.sender,rawAmount);
    }

    function totalSupply() public view returns (uint256) {
	    return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
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
        emit Transfer(owner, buyer, numTokens);
        return true;
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