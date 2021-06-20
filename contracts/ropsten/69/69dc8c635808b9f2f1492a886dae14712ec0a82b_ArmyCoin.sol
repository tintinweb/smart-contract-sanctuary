/**
 *Submitted for verification at Etherscan.io on 2021-06-20
*/

pragma solidity ^0.4.24;
 

contract owned {
    address public owner;
 
    constructor() {
        owner = msg.sender;
    }
 
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
 
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


//Safe Math Interface
 
contract SafeMath {
 
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
 
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
 
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
 
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
 
 
//ERC Token Standard #20 Interface
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
 
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Burn(address indexed from, uint256 tokens);
}
 
 
//Contract function to receive approval and execute function in one call
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
 
//Actual token contract
 
contract ArmyCoin is ERC20Interface, SafeMath, owned {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public totalSupply;
    uint public initialSupply;
    address centralMinter;
 
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
 
    constructor() public {
        
        if(centralMinter != 0 ) owner = centralMinter;
        symbol = "AC";
        name = "Army Coin";
        decimals = 2;
        initialSupply = 10000;
        totalSupply = initialSupply;
        
        balances[0x18A093FAA08dF34308c8A98F44cA90Cb21D88B19] = initialSupply;
        emit Transfer(address(0), 0x18A093FAA08dF34308c8A98F44cA90Cb21D88B19, initialSupply);
    }
 
    function totalSupply() public constant returns (uint) {
        return totalSupply  - balances[address(0)];
    }
 
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
 
    function transfer(address to, uint tokens) public returns (bool success) {
        require(balances[msg.sender] >= tokens && balances[to] + tokens >= balances[to]);
        
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
 
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
 
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
 
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
 
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    
    function mintToken(address target, uint256 tokens) onlyOwner public {
    balances[target] += tokens;
    totalSupply += tokens;
    
    emit Transfer(0, owner, tokens);
    emit Transfer(owner, target, tokens);
    }
    
    function burn(uint256 tokens) public returns (bool success) {
        require(balances[msg.sender] >= tokens);   // Check if the sender has enough
        balances[msg.sender] -= tokens;            // Subtract from the sender
        totalSupply -= tokens;                      // Updates totalSupply
        emit Burn(msg.sender, tokens);
        return true;
    }    

 
    function () public payable {
        revert();
    }
}