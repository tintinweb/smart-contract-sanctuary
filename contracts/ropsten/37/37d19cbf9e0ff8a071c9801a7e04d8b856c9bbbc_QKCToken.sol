/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

pragma solidity ^0.4.24;
 
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
    //This function will return the number of all tokens allocated 
    //by this contract regardless of owner
    function totalSupply() public constant returns (uint);
    
    //This will return the current token balance of an account
    //identified by it's owner's address
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    
    //It is used to move amount of tokens from owners balance
    //to that of another user 
    function transfer(address to, uint tokens) public returns (bool success);
    
    //It is the peer of the approve function. It allows delegate
    //approved for withdrawal to transfer owner funds to a third-party account
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    //It allow an owner i.e msg.sender to approve a delegate account
    // possibly the marketplace itself to withdraw tokend from his
    //account to transfer them to other accounts
    function approve(address spender, uint tokens) public returns (bool success);
    
    //The function returns the current approved number of tokens by an
    //owner to a specific delegate as set in "approve" function
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    
 
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
 
 
//Contract function to receive approval and execute function in one call
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
 
//Actual token contract
 
contract QKCToken is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
 
    // It will hold the token balance of each owner account
    mapping(address => uint) balances;
 
    // It will include all of the accounts approved to 
    //  withdraw given account together with the 
    //      withdrawal sum allowed for each 
    mapping(address => mapping(address => uint)) allowed;
 
    constructor() public {
        symbol = "RTN";
        name = "Return Token";
        decimals = 2;
        _totalSupply = 1000000;
        balances[0xd97fC9Ba0296Afbc8cDf95Bd36678C80827fE2F0] = _totalSupply;
        emit Transfer(address(0), 0xd97fC9Ba0296Afbc8cDf95Bd36678C80827fE2F0, _totalSupply);
    }
 
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
 
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
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
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
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
 
    function () public payable {
        revert();
    }
}