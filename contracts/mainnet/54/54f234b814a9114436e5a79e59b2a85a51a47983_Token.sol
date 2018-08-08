pragma solidity ^0.4.18;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


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


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}



contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract Token is ERC20Interface, Owned {
    using SafeMath for uint;

    string public name = "Bitcoin to the moon";   
    string public symbol = "BTTM";   
    uint8 public decimals = 18;    
    uint public _totalSupply;   


    mapping(address => uint) balances;  
    mapping(address => mapping(address => uint)) allowed;   


    constructor() public {   
        name = "Bitcoin to the moon";
        symbol = "BTTM";
        decimals = 18;
        _totalSupply = 21000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    function totalSupply() public view returns (uint) { 
        return _totalSupply - balances[address(0)];
    }

    // Extra function
    function totalSupplyWithZeroAddress() public view returns (uint) { 
        return _totalSupply;
    }


    function balanceOf(address tokenOwner) public view returns (uint balance) { 
        return balances[tokenOwner];
    }

    // Extra function
    function myBalance() public view returns (uint balance) {
        return balances[msg.sender];
    }


    function transfer(address to, uint tokens) public returns (bool success) {  
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {  
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {    
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {  
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

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) { 
        return ERC20Interface(tokenAddress).transfer(owner, tokens);        
    }
}

contract Admin is Token {
    // change symbol and name
    function reconfig(string newName, string newSymbol) external onlyOwner {
        symbol = newSymbol;
        name = newName;
    }

    // increase supply and send newly added tokens to owner
    function increaseSupply(uint256 increase) external onlyOwner {
        _totalSupply += increase;
        balances[owner] += increase;
        emit Transfer(address(0), owner, increase);
    }
    
    // deactivate the contract
    function deactivate() external onlyOwner {
        selfdestruct(owner);
    }
}