/* MVG合约 */
pragma solidity ^0.4.16;
/* 创建一个父类， 账户管理员 */
contract owned {

    address public owner;

    function owned() public {
    owner = msg.sender;
    }

    /* modifier是修改标志 */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /* 修改管理员账户， onlyOwner代表只能是用户管理员来修改 */
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }   
}

/* receiveApproval服务合约指示代币合约将代币从发送者的账户转移到服务合约的账户（通过调用服务合约的 */
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
    // 代币（token）的公共变量
    string public name;             //代币名字
    string public symbol;           //代币符号
    uint8 public decimals = 18;     //代币小数点位数， 18是默认， 尽量不要更改

    uint256 public totalSupply;     //代币总量

    // 记录各个账户的代币数目
    mapping (address => uint256) public balanceOf;

    // A账户存在B账户资金
    mapping (address => mapping (address => uint256)) public allowance;

    // 转账通知事件
    event Transfer(address indexed from, address indexed to, uint256 value);

    // 销毁金额通知事件
    event Burn(address indexed from, uint256 value);

    /* 构造函数 */
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // 根据decimals计算代币的数量
        balanceOf[msg.sender] = totalSupply;                    // 给生成者所有的代币数量
        name = tokenName;                                       // 设置代币的名字
        symbol = tokenSymbol;                                   // 设置代币的符号
    }

    /* 私有的交易函数 */
    function _transfer(address _from, address _to, uint _value) internal {
        // 防止转移到0x0， 用burn代替这个功能
        require(_to != 0x0);
        // 检测发送者是否有足够的资金
        require(balanceOf[_from] >= _value);
        // 检查是否溢出（数据类型的溢出）
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // 将此保存为将来的断言， 函数最后会有一个检验
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // 减少发送者资产
        balanceOf[_from] -= _value;
        // 增加接收者的资产
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // 断言检测， 不应该为错
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /* 传递tokens */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /* 从其他账户转移资产 */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /*  授权第三方从发送者账户转移代币，然后通过transferFrom()函数来执行第三方的转移操作 */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /*
    为其他地址设置津贴， 并通知
    发送者通知代币合约, 代币合约通知服务合约receiveApproval, 服务合约指示代币合约将代币从发送者的账户转移到服务合约的账户（通过调用服务合约的transferFrom)
    */

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
    * 销毁代币
    */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
    * 从其他账户销毁代币
    */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
}

/******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/

contract KAPAYcoin is owned, TokenERC20 {

    uint256 public sellPrice;
    uint256 public buyPrice;

    /* 冻结账户 */
    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* 构造函数 */
    function KAPAYcoin(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

    /* 转账， 比父类加入了账户冻结 */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        Transfer(_from, _to, _value);
    }

/// 向指定账户增发资金
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);

    }


    /// 冻结 or 解冻账户
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    /// @notice Buy tokens from contract by sending ether
    function buy() payable public {
        uint amount = msg.value / buyPrice;               // calculates the amount
        _transfer(this, msg.sender, amount);              // makes the transfers
    }

    function sell(uint256 amount) public {
        require(this.balance >= amount * sellPrice);      // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, amount);              // makes the transfers
        msg.sender.transfer(amount * sellPrice);          // sends ether to the seller. It&#39;s important to do this last to avoid recursion attacks
    }
}