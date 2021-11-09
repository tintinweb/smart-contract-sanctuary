/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

pragma solidity ^0.5.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address tokenOwner,uint amount) external;
    function burn(uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Bought(uint256 amount);
    event Sold(uint256 amount);
}

contract ERC20T2 is IERC20{
    
    string public name;
    string public symbol;
    uint8 public decimals; //จำนวนทศนิยม
    uint256 public _totalSupply;
    
    address public minter;//เก็บaddressคนที่สร้างเหรียญ
    mapping(address => mapping(address => uint)) public allowed;
    mapping(address => uint256) public balances;//ดึงกระเป๋าของaddress

    constructor()public{
        name = "MisterSiGz Tokens(test01)";
        symbol = "MST";
        decimals = 18;
        _totalSupply = 1000000 ether;
        
        minter = msg.sender;
        balances[msg.sender] = _totalSupply;
    }
    //----------------------function safeMath-----------------------
        function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    
    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a); c = a - b; 
    } 
    //---------------------------------------------------------------
    function totalSupply() public view returns (uint256) {
        return _totalSupply  - balances[address(0)];
    }
    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }
   function transfer(address to, uint256 tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function mint(address tokenOwner,uint256 amount) public {
        require(msg.sender == minter);//เช็คคนที่เชื่อมมีaddressตรงกับคนสร้าง
        balances[tokenOwner] =balances[tokenOwner] + amount;
        _totalSupply = _totalSupply+amount;
    }
    function approve(address spender, uint256 tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
    function burn(uint256 amount) public returns (bool success){
        require(balances[msg.sender] >= amount);//เช็คจำนวนเงิน
        balances[msg.sender] =balances[msg.sender] - amount;
        _totalSupply = _totalSupply-amount;
        return true;
    }
    
}