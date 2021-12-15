/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

/**
 *Submitted for verification at Centurion invest.
 *Author : Aymen Haddaji
*/
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;


/**
* ERC20 Interfacs
*/
abstract contract IERC20 {
    
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint);
    function allowance(address sender, address reciever) virtual public view returns (uint);
    function transfer(address to, uint tokens) virtual public returns (bool);
    function approve(address reciever, uint tokens) virtual public returns (bool);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract SafeMath {
    
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
}


contract CIC_COIN is IERC20, SafeMath {

    string public name;
    string public symbol;
    uint8 public decimals;  
    uint256 public _totalSupply;
    address public owner;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    constructor() public payable {
        name = "Centurion Invest Coin";
        symbol = "CIC";
        decimals = 2;
        owner = msg.sender;
        _totalSupply =  2400000000 * 10 ** uint256(decimals);   // n decimals 
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "No permession");
        _;
    }

    
    /**
     * @dev allowance : Check approved balance
     */
    function allowance(address sender, address reciever) virtual override public view returns (uint remaining) {
        return allowed[sender][reciever];
    }
    
    /**
     * @dev approve : Approve token for spender = reciever
     */ 
    function approve(address reciever, uint tokens) virtual override public returns (bool success) {
        require(tokens >= 0, "Invalid value");
        allowed[msg.sender][reciever] = tokens;
        emit Approval(msg.sender, reciever, tokens);
        return true;
    }
    
    /**
     * @dev transfer : Transfer token to another etherum address
     */ 
    function transfer(address to, uint tokens) virtual override public returns (bool success) {
        require(to != address(0), "Null address");                                         
        require(tokens > 0, "Invalid Value");
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    /**
     * @dev transferFrom : Transfer token after approval 
     */ 
    function transferFrom(address from, address to, uint tokens) virtual override public returns (bool success) {
        require(to != address(0), "Null address");
        require(from != address(0), "Null address");
        require(tokens > 0, "Invalid value"); 
        require(tokens <= balances[from], "Insufficient balance");
        require(tokens <= allowed[from][msg.sender], "Insufficient allowance");
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    /**
     * @dev totalSupply : Display total supply of token
     */ 
    function totalSupply() virtual override public view returns (uint) {
        return _totalSupply;
    }
    
    /**
     * @dev balanceOf : Displya token balance of given address
     */ 
    function balanceOf(address tokenOwner) virtual override public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    /**
     * @dev mint : To increase total supply of tokens
     */ 
    function mint(uint256 _amount) public onlyOwner returns (bool) {
        require(_amount >= 0, "Invalid amount");
        _totalSupply = safeAdd(_totalSupply, _amount);
        balances[owner] = safeAdd(balances[owner], _amount);
        return true;
    }
    
     /**
     * @dev burn : To decrease total supply of tokens
     */ 
    function burn(uint256 _amount) public returns (bool) {
        require(_amount >= 0, "Invalid amount");
        require(owner == msg.sender, "UnAuthorized");
        require(_amount <= balances[msg.sender], "Insufficient Balance");
        _totalSupply = safeSub(_totalSupply, _amount);
        balances[owner] = safeSub(balances[owner], _amount);
        emit Transfer(owner, address(0), _amount);
        return true;
    }

    /**
    *@dev send_bonus : set and send ammount of bonus.
    *
    */
    function send_bonus(address to, uint bonus) virtual public returns (bool success) {
        transfer(to, bonus);
        return true;
    }

    /**
    *@dev send_bonus : set and send ammount of bonus.
    *
    */
    function send_referral(address to, uint referamt) virtual public returns (bool success) {
        transfer(to, referamt);
        return true;
    }
}