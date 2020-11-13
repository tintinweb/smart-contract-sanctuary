/*OnePiece t.me/OPTreasure*/

pragma solidity ^0.5.0;


contract ERC20Interface {
    
    function allowance(address tokenOwner, address spender) 
        public 
        view 
        returns (uint remaining);
   
    function approve(address spender, uint tokens) 
        public 
        returns (bool success);
    
    function totalSupply() 
        public 
        view 
        returns (uint);
   
    function balanceOf(address tokenOwner) 
        public 
        view 
        returns (uint balance);
        
    function transfer(address to, uint tokens) 
        public 
        returns (bool success);
        
    function transferFrom(address from, address to, uint tokens) 
        public 
        returns (bool success);
     
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
}

library SafeMath {
    function add(uint256 x, uint256 y) 
        internal 
        pure returns (uint256) 
    {
        uint256 z = x + y;
        assert(z >= x);
        return z;
    }
      
    function subtract(uint256 x, uint256 y) 
        internal 
        pure 
        returns (uint256) 
    {
        assert(y <= x);
        return x - y;
    }
    
    function multiply(uint256 x, uint256 y) 
        internal 
        pure 
        returns (uint256) 
    {
        if (x == 0) {
          return 0;
        }
        uint256 z = x * y;
        assert(z / x == y);
        return z;
    }
    
    function divide(uint256 x, uint256 y) 
        internal 
        pure 
        returns (uint256) 
    {
        uint256 z = x / y;
        return z;
    }
    
    function ceil(uint256 x, uint256 y) 
        internal 
        pure 
        returns (uint256) 
    {
        uint256 c = add(x,y);
        uint256 d = subtract(c,1);
        return multiply(divide(d,y),y);
    }
}

contract OnePiece is ERC20Interface {
    
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    
    uint256 public foundationRatio = 100;
    uint256 public _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        name = "OnePieceTreasure";
        symbol = "OPT";
        decimals = 18;
        _totalSupply = 400000000000000000000;
        
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function getBurnPercent(uint256 value) public view returns (uint256)  {
        uint256 roundValue = value.ceil(foundationRatio);
        uint256 onePercent = roundValue.multiply(foundationRatio).divide(30000); // 3 percent burn
        return onePercent;
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].subtract(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].subtract(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    
    function transfer(address to, uint value) public returns (bool success) {

        require(value <= balances[msg.sender]);
        require(to != address(0));
    
        uint256 tokensToBurn = getBurnPercent(value);
        uint256 tokensToTransfer = value.subtract(tokensToBurn);
    
        balances[msg.sender] = balances[msg.sender].subtract(value);
        balances[to] = balances[to].add(tokensToTransfer);
    
        _totalSupply = _totalSupply.subtract(tokensToBurn);
    
        emit Transfer(msg.sender, to, tokensToTransfer);
        emit Transfer(msg.sender, address(0), tokensToBurn);
        return true;
    }
    
    
    
}