pragma solidity ^0.5.1;

contract ERC20Interface {
    // 代币名称
    string public name;
    // 代币符号或者说简写
    string public symbol;
    // 代币小数点位数，代币的最小单位
    uint8 public decimals;
    // 代币的发行总量
    uint public totalSupply;

    // 实现代币交易，用于给某个地址转移代币
    function transfer(address to, uint tokens) public returns (bool success);
    // 实现代币用户之间的交易，从一个地址转移代币到另一个地址
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    // 允许spender多次从你的账户取款，并且最多可取tokens个，主要用于某些场景下授权委托其他用户从你的账户上花费代币
    function approve(address spender, uint tokens) public returns (bool success);
    // 查询spender允许从tokenOwner上花费的代币数量
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);

    // 代币交易时触发的事件，即调用transfer方法时触发
    event Transfer(address indexed from, address indexed to, uint tokens);
    // 允许其他用户从你的账户上花费代币时触发的事件，即调用approve方法时触发
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// 实现ERC-20标准接口
contract STAR is ERC20Interface {
    // 存储每个地址的余额（因为是public的所以会自动生成balanceOf方法）
    mapping (address => uint256) public balanceOf;
    // 存储每个地址可操作的地址及其可操作的金额
    mapping (address => mapping (address => uint256)) internal allowed;

    // 初始化属性
    constructor() public {
        name = "SUPER STAR";
        symbol = "STAR"; 
        decimals = 6;
        totalSupply = 190000000 * 10**uint(decimals);
        // 初始化该代币的账户会拥有所有的代币
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        // 检验接收者地址是否合法
        require(to != address(0));
        // 检验发送者账户余额是否足够
        require(balanceOf[msg.sender] >= tokens);
        // 检验是否会发生溢出
        require(balanceOf[to] + tokens >= balanceOf[to]);

        // 扣除发送者账户余额
        balanceOf[msg.sender] -= tokens;
        // 增加接收者账户余额
        balanceOf[to] += tokens;

        // 触发相应的事件
        emit Transfer(msg.sender, to, tokens);

                success = true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        // 检验地址是否合法
        require(to != address(0) && from != address(0));
        // 检验发送者账户余额是否足够
        require(balanceOf[from] >= tokens);
        // 检验操作的金额是否是被允许的
        require(allowed[from][msg.sender] <= tokens);
        // 检验是否会发生溢出
        require(balanceOf[to] + tokens >= balanceOf[to]);

        // 扣除发送者账户余额
        balanceOf[from] -= tokens;
        // 增加接收者账户余额
        balanceOf[to] += tokens;

        // 触发相应的事件
        emit Transfer(from, to, tokens);   

        success = true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        // 触发相应的事件
        emit Approval(msg.sender, spender, tokens);

        success = true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
}