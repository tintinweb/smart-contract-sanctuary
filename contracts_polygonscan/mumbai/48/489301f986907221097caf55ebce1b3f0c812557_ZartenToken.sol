/**
 *Submitted for verification at polygonscan.com on 2021-12-17
*/

pragma solidity ^0.4.0;

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

contract ZartenToken is ERC20Interface{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;
    
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    
    constructor() public {
        symbol = "ATN";
        name = "Anthony";
        decimals = 18;
        _totalSupply = 100000000 * 10**uint256(decimals);
        balances[msg.sender] = _totalSupply;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function transfer(address to, uint256 tokens) public returns (bool success) {

        // 检验接收者地址是否合法
        require(to != address(0));

        // 检验发送者账户余额是否足够
        require(balances[msg.sender] >= tokens);

        // 检验是否会发生溢出
        require(balances[to] + tokens >= balances[to]);



        // 扣除发送者账户余额
        balances[msg.sender] -= tokens;

        // 增加接收者账户余额
        balances[to] += tokens;



        // 触发相应的事件
        emit Transfer(msg.sender, to, tokens);
        return true;

    }
    
    function approve(address spender, uint256 tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        // 检验地址是否合法
        require(to != address(0) && from != address(0));

        // 检验发送者账户余额是否足够
        require(balances[from] >= tokens);

        // 检验操作的金额是否是被允许的
        require(allowed[from][msg.sender] <= tokens);

        // 检验是否会发生溢出
        require(balances[to] + tokens >= balances[to]);

        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }
    

}