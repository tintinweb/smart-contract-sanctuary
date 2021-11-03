/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

pragma solidity ^0.5.0;

contract ERC20T2 {
    
    string public name;
    string public symbol;
    uint8 public decimals; //จำนวนทศนิยม
    uint256 public _totalSupply;
    
    address public minter;//เก็บaddressคนที่สร้างเหรียญ
    mapping(address => mapping(address => uint)) public allowed;
    mapping(address => uint256) public balances;//ดึงกระเป๋าของaddress
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    

    constructor()public{
        name = "Beeba Tokens";
        symbol = "BBT";
        decimals = 18;
        _totalSupply = 10000 ether;
        
        minter = msg.sender;
        balances[msg.sender] = _totalSupply;
    }
    //----------------------function safeMath-----------------------
        function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; 
    } 
    //---------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
   function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function mint(address tokenOwner,uint amount) public {
        require(msg.sender == minter);//เช็คคนที่เชื่อมมีaddressตรงกับคนสร้าง
        balances[tokenOwner] =balances[tokenOwner] + amount;
        _totalSupply = _totalSupply+amount;
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
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    function burn(uint amount) public returns (bool success){
        require(balances[msg.sender] >= amount);//เช็คจำนวนเงิน
        balances[msg.sender] =balances[msg.sender] - amount;
        _totalSupply = _totalSupply-amount;
        return true;
    }
}