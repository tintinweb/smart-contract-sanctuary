/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

pragma solidity ^0.5.0;


contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a,"c should be greater than a");
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a,"");c = a - b;
        }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b,"");
        }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0,"");
        c = a / b;
    }
}
// ERC20 interface
interface erc20 {
    
    function totalSupply() external view returns (uint);
    
    function balanceOf(address _tokenOwner) external view returns (uint balance);
    
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    
    function transfer(address to, uint tokens) 	external returns (bool success);

    function approve(address spender, uint tokens) 	external returns (bool success);
    
    function transferFrom (address from, address to, uint tokens) external returns (bool success);


    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
// Custom Token 
contract CustomToken is erc20, SafeMath {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    uint private _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor(string memory name, string memory symbol,uint8 decimals,uint totalSupply) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _totalSupply = totalSupply;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
function totalSupply() public view returns (uint) {
    return _totalSupply - balances[address(0)];
}

function name() public view returns(string memory) {
    return _name;
}

function symbol() public view returns (string memory) {
    return _symbol;
}

function decimals() public view returns (uint8) {
        return _decimals;
    }

function balanceOf(address tokenOwner) public  view returns (uint balance) {
    return balances[tokenOwner];
}

function allowance(address tokenOwner, address spender) public  view returns (uint remaining) {
    return allowed[tokenOwner][spender];
}

function approve(address spender, uint tokens) 	public  returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
}

function transfer(address to, uint tokens) public  returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], tokens);
    balances[to] = safeAdd(balances[to], tokens);

    emit Transfer(msg.sender, to, tokens);
    return true;
}

function transferFrom(address from, address to, uint tokens) public  returns (bool success) {
    balances[from] = safeSub(balances[from], tokens);
    allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
    balances[to] = safeAdd(balances[to], tokens);
        
	emit Transfer(from, to, tokens);
    return true;
}

}