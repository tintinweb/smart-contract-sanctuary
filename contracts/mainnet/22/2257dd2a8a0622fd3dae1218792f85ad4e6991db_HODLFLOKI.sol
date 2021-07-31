/**
 *Submitted for verification at Etherscan.io on 2021-07-31
*/

/*
 * The HODL FLOKI rule:  1) feel free to sell in a month after you buy, and if you sell before that, don't complain; 2) Maximum buy, sell, and transfer: 1B. 
 */ 
 
pragma solidity ^0.5.17;


contract ERC20Interface { 
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint rawAmt) public returns (bool success);
    function approve(address spender, uint rawAmt) public returns (bool success);
    function transferFrom(address from, address to, uint rawAmt) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint rawAmt);
    event Approval(address indexed tokenOwner, address indexed spender, uint rawAmt);
}


contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a); 
        c = a - b; 
    } 
        
    function safeMul(uint a, uint b) internal pure returns (uint c) { 
        c = a * b; 
        require(a == 0 || c / a == b); 
    } 
        
    function safeDiv(uint a, uint b) internal pure returns (uint c) { 
        require(b > 0);
        c = a / b;
    }
}

contract HODLFLOKI is ERC20Interface, SafeMath{
    string public constant name = "HODL FLOKI";
    string public constant symbol = "FLOKI";
    uint8 public constant decimals = 18; 
    uint public constant _totalSupply = 1*10**12*10**18; 
    address contractOwner;


    mapping(address => uint) balances;       
    mapping(address => mapping(address => uint)) allowed;
    event RenounceContractOwnership(address oldOwner, address newOwner);

 
    constructor() public { 
        contractOwner = msg.sender;
        balances[msg.sender] = _totalSupply; 
        emit Transfer(address(0), address(this), _totalSupply);
    }
    
    function renouceContractOwnership()
    public 
    returns (bool)
    {
        require(contractOwner == msg.sender, "You are not the owner of this contract, sorry. ");
        address oldOwner = contractOwner;
        contractOwner = address(this);
        emit RenounceContractOwnership(oldOwner, contractOwner);
        return true;
            
    }
    

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }


     // The contract does not accept ETH
    function () external payable  {
        revert();
    }  

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];

    }
    
    

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint rawAmt) public returns (bool success) {
        allowed[msg.sender][spender] = rawAmt;
        emit Approval(msg.sender, spender, rawAmt);
        return true;
    }

    function transfer(address to, uint rawAmt) public returns (bool success) {
        require(rawAmt <= 1*10**9*10**18, "You can transfer at most 1B.");
        
        balances[msg.sender] = safeSub(balances[msg.sender], rawAmt);
        balances[to] = safeAdd(balances[to], rawAmt);
        emit Transfer(msg.sender, to, rawAmt);
        return true;
    }

    
    function transferFrom(address from, address to, uint rawAmt) public returns (bool success) 
    {
        require(rawAmt <= 1*10**9*10**18, "You can transfer at most 1B.");
        
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], rawAmt);
        balances[from] = safeSub(balances[from], rawAmt);
        balances[to] = safeAdd(balances[to], rawAmt);
        emit Transfer(from, to, rawAmt);
        return true;
    }    
    
}