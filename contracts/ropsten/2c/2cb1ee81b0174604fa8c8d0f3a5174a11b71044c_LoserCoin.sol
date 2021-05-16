/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

//This pragma is only for compiler compatibility. Once the contracts are compiled, we don't have to worry about this as the contract isn't in solidity anymore.
pragma solidity ^0.5.2;

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
    function mult(uint256 a, uint256 b) internal pure returns (uint256){
        
        if (a == 0){
            return 0;
        }
        
        uint256 c = a * b;
        require(c / a == b);
        
        return c;
        
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256){
        require(b > 0);
        uint256 c = a / b;
        
        return c;
    }
    
}
contract LoserCoin is ERC20Interface, SafeMath{
    
    string public name;
    string public symbol;
    uint8 public decimal;
    
    //Creates associative array for tracking user balances (array of Key:Value pairs) - address is the key that represents account addresses and has a value that is of type uint256
     mapping(address => uint256) public balances;
    //Associative array to track user accounts that are allowed to withdraw from a given account paired with the withdrawal amount.
     mapping(address => mapping (address => uint256)) public allowed;
    uint256 public totalSupply_;
     constructor() public {
        totalSupply_ = 100;
        name = "LoserCoin";
        symbol = "LSR";
        decimal = 18; 
        balances[msg.sender] = totalSupply_;
        
        emit Transfer(address(0), msg.sender, totalSupply_);
    }

    function totalSupply() public view returns (uint256){
        return totalSupply_ - balances[address(0)];
    }

    function balanceOf(address userAccount) public view returns (uint){
        return balances[userAccount];
    }
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