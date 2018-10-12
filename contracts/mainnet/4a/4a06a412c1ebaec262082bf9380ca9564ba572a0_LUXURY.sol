pragma solidity ^0.4.24;

//   ----------------------------------------------------------------------------------
//                                                                                   
//   ooooo        ooooo     ooo ooooooo  ooooo ooooo     ooo ooooooooo.   oooooo   oooo 
//   `888&#39;        `888&#39;     `8&#39;  `8888    d8&#39;  `888&#39;     `8&#39; `888   `Y88.  `888.   .8&#39;  
//    888          888       8     Y888..8P     888       8   888   .d88&#39;   `888. .8&#39;   
//    888          888       8      `8888&#39;      888       8   888ooo88P&#39;     `888.8&#39;    
//    888          888       8     .8PY888.     888       8   888`88b.        `888&#39;     
//    888       o  `88.    .8&#39;    d8&#39;  `888b    `88.    .8&#39;   888  `88b.       888      
//   o888ooooood8    `YbodP&#39;    o888o  o88888o    `YbodP&#39;    o888o  o888o     o888o     
//                                                                                    
//
//                  +-+-+-+-+-+-+-+-+ +-+ +-+-+-+-+ +-+-+-+-+-+-+
//                  |D|I|A|M|O|N|D|S| |/| |R|E|A|L| |E|S|T|A|T|E|
//                  +-+-+-+-+-+-+-+-+ +-+ +-+-+-+-+ +-+-+-+-+-+-+
// 
//   ----------------------------------------------------------------------------------


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

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
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

contract LUXURY is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        symbol = "LUX";
        name = "LUXURY";
        decimals = 4;
        _totalSupply = 10000000000;
        balances[0xe5DB32b1FDa0345Ab81fACD4304725672e5413B8] = _totalSupply;
        emit Transfer(address(0), 0xe5DB32b1FDa0345Ab81fACD4304725672e5413B8, _totalSupply);
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

    function () public payable {
        revert();
    }

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}