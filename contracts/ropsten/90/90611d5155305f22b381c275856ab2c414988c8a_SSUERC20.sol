/**
 *Submitted for verification at Etherscan.io on 2021-05-02
*/

//This pragma is only for compiler compatibility. Once the contracts are compiled, we don't have to worry about this as the contract isn't in solidity anymore.
pragma solidity ^0.5.2;

//Introducing SafeMath to prevent overflows and underflows.
//We're using uint256 here, if we get to the max value (2^256) and increment, the variable will go back to 0. 
//Similarly, if we're at 0 and we decrement we'll circle around to the max value (2^256).
//This library prevents those two situations from occuring

//ERC Token Standard Interface, from here: https://en.bitcoinwiki.org/wiki/ERC20 

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256){
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256){
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    //Check for proper multiplication
    function mult(uint256 a, uint256 b) internal pure returns (uint256){
        
        if (a == 0){
            return 0;
        }
        
        uint256 c = a * b;
        require(c / a == b);
        
        return c;
        
    }
    
    //Check for proper division 
    function div(uint256 a, uint256 b) internal pure returns (uint256){
        require(b > 0);
        uint256 c = a / b;
        
        return c;
    }
    
}




contract SSUERC20 is ERC20Interface, SafeMath{
    
    string public name;
    string public symbol;
    
    //  How many decimals you can use to break a token up (to get "fractions" of a token), e.g. “0” decimals makes the token binary, either you have a token or you don’t.
    //  “2” decimals allows you to fraction a token, being the smaller size 0.01; and you can add up to “18” decimals.
    uint8 public decimal;
    
    //Bring in our SafeMath library 

    
    
    //Creates associative array for tracking user balances (array of Key:Value pairs) - address is the key that represents account addresses and has a value that is of type uint256
     mapping(address => uint256) public balances;
    //Associate array to track user accounts that are allowed to withdraw from a given account paired with the withdrawal amount.
     mapping(address => mapping (address => uint256)) public allowed;
    
    //Total supply of tokens
    uint256 public totalSupply_;
    
    //Constructor that takes the supply of tokens as a parameter and assigns all of the tokens created to the contract owner. 
    //There are multiple methods to set the number of tokens, but this is a simple and secure way that fits the needs of this project.
     constructor() public {
        totalSupply_ = 1000;
        name = "SSUToken";
        symbol = "SSU";
        decimal = 18; 
        balances[msg.sender] = totalSupply_;
        
        emit Transfer(address(0), msg.sender, totalSupply_);
    }
    
    //get current token supply    
    function totalSupply() public view returns (uint256){
        return totalSupply_ - balances[address(0)];
    }
    
    //Get balance of a user 
    function balanceOf(address userAccount) public view returns (uint){
        return balances[userAccount];
    }
    

    //Function to transfer token to a user account 
    function transfer(address userReceive, uint numberOfTokens) public returns (bool) {
        //Adjust the balance of the sender
        balances[msg.sender] = sub(balances[msg.sender], numberOfTokens);
        //Adjust the balance of the receiver
        balances[userReceive] = add(balances[userReceive],numberOfTokens);
        emit Transfer(msg.sender, userReceive, numberOfTokens);
        return true;
    }    
    
    
    function approve(address delegate, uint numberOfTokens) public returns (bool){
        allowed[msg.sender][delegate] = numberOfTokens;
        emit Approval(msg.sender, delegate, numberOfTokens);
        return true;
    }
    
    
    
    function allowance(address owner, address delegate) public view returns (uint){
        return allowed[owner][delegate];
    }
    
    function transferFrom(address owner, address buyer, uint numberOfTokens) public returns (bool) {
      balances[owner] = sub(balances[owner], numberOfTokens);
      allowed[owner][msg.sender] = sub(allowed[owner][msg.sender], numberOfTokens);
      balances[buyer] = add(balances[buyer], numberOfTokens);
      emit Transfer(owner, buyer, numberOfTokens);
      return true;
    }
    
}