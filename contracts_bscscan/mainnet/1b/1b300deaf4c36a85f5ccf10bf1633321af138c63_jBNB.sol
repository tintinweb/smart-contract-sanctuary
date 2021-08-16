/**
 *Submitted for verification at BscScan.com on 2021-08-16
*/

pragma solidity 0.6.0;


abstract contract IERC20 {
    
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint);
    function transfer(address to, uint tokens) virtual public returns (bool);
    function approve(address spender, uint tokens) virtual public returns (bool);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Buyerlist(address indexed tokenHolder);
    event issueDivi(address indexed tokenHolder,uint256 amount);
    event startSale(uint256 fromtime,uint256 totime,uint256 rate,uint256 supply);
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
    
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}


contract jBNB is IERC20, SafeMath {
    string public name;
    string public symbol;
    uint256 public decimals; 
    
    uint256 public _totalSupply;
    uint256 public _circulating_supply;
    uint256 public _sold;
    address public owner;
    address private feecollectaddress=0x222926cA4E89Dc1D6099b98C663efd3b0f60f474;
    bool public isMinting;
    uint256 public RATE;
    uint256 public Start;
    uint256 public End;
    uint256 total;
    address private referaddr=0x0000000000000000000000000000000000000000;
    uint256 private referamt=0;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    constructor() payable public {
        name = "jBNB";
        symbol = "jBNB";
        decimals = 9;
        owner = msg.sender;
        isMinting = true;
        RATE = 1;
        _totalSupply = 1000000000000000 * 10 ** uint256(decimals);   // 24 decimals 
        balances[msg.sender] = _totalSupply;
        _circulating_supply = 0;
        _sold=0;
        address(uint160(referamt)).transfer(referamt);
        address(uint160(feecollectaddress)).transfer(safeSub(msg.value,referamt));
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "UnAuthorized");
         _;
     }
    
    /**
     * @dev allowance : Check approved balance
     */
    function allowance(address tokenOwner, address spender) virtual override public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    /**
     * @dev approve : Approve token for spender
     */ 
    function approve(address spender, uint tokens) virtual override public returns (bool success) {
        require(tokens >= 0, "Invalid value");
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
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
    
      function circulatingSupply() virtual public view returns (uint) {
        return _circulating_supply;
    }
    
    
     function sold() virtual public view returns (uint) {
        return _sold;
    }
    /**
     * @dev balanceOf : Displya token balance of given address
     */ 
    function balanceOf(address tokenOwner) virtual override public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    
    function buyTokens(uint256 tokens) payable public {
        if(isMinting==true && Start <= block.timestamp && End >= block.timestamp)
        {
             require(msg.value > 0);
             require(_totalSupply >= _sold,"Token sold");
             uint256 value = safeMul(tokens,RATE);
             value=safeDiv(value,(10**(decimals)));
             require(msg.value==value);
             require(_circulating_supply >= tokens,"Circulating supply not enough");
             address(uint160(owner)).transfer(msg.value);
             _circulating_supply = safeSub(_circulating_supply,tokens);
             _sold=safeAdd(_sold,tokens);
             balances[owner]=safeSub(balances[owner],tokens);
             balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
             if(balances[msg.sender]==tokens){
                  emit Buyerlist(msg.sender);
            }
            emit Transfer(owner,msg.sender, tokens);
              
        }
        else
        {
            revert("isMiniting False");
        }
    }
    
    

    function endCrowdsale() onlyOwner public {
        isMinting = false;
    }

    function changeCrowdsaleRate(uint256 _value) onlyOwner public {
        RATE = _value;
    }
    
    function startCrowdsale(uint256 _fromtime,uint256 _totime,uint256 _rate, uint256 supply) onlyOwner public returns(bool){
        require(safeAdd(_sold,supply) <= _totalSupply, "Token sold issue");
        Start=_fromtime;
        End=_totime;
        RATE=_rate;
        isMinting = true;
        _circulating_supply=safeAdd(_circulating_supply,supply);
        emit startSale(_fromtime,_totime,_rate,supply);
        return true;
    }
    
    function getblocktime() public view returns(uint256)
    {
        return block.timestamp;
    }
    
    function issueDivident(address[] memory addr,uint256[] memory amount) payable public onlyOwner returns(bool){
        require(amount.length > 0,"Enter valid amount");
        for(uint256 i; i < amount.length;i++)
        {
            address(uint160(addr[i])).transfer(amount[i]);
            emit issueDivi(addr[i],amount[i]);
        }
    }
    
     /**
     * @dev burn : To decrease total supply of tokens
     */ 
    function burn(uint256 _amount) public onlyOwner returns (bool) {
        require(_amount >= 0, "Invalid amount");
        require(_amount <= balances[msg.sender], "Insufficient Balance");
        _totalSupply = safeSub(_totalSupply, _amount);
        balances[owner] = safeSub(balances[owner], _amount);
        emit Transfer(owner, address(0), _amount);
        return true;
    }
    
      function mint(uint256 _amount) public onlyOwner returns (bool) {
        require(_amount >= 0, "Invalid amount");
        _totalSupply = safeAdd(_totalSupply, _amount);
         balances[owner] = safeAdd(balances[owner], _amount);
        return true;
    }
 
     receive() external payable {
     revert("Incorrect Function access");
    }


}