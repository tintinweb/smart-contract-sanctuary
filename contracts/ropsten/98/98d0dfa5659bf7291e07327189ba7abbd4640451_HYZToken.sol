pragma solidity ^0.4.16;

library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    //构造函数，自动执行
    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    //转移合约到新的合约拥有者
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


interface tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;}

contract TokenERC20 {
    using SafeMath for uint256;

    // Public variables of the token
    string public name;    // 代币符合，一般用代币名称的缩写，如 LBJ
    string public symbol;  // token 标志
    uint8 public decimals = 18;  // 每个代币可细分的到多少位，即最小代币单位
    // 代币总供应量，这里指的是一共有多少个以最小单位所计量的代币
    uint256 public totalSupply;

    // 用mapping保存每个地址对应的余额
    mapping(address => uint256) public balanceOf;
    // 返回_owner给_spender授权token的剩余量
    mapping(address => mapping(address => uint256)) public allowance;

    // 事件，用来通知客户端交易发生
    event Transfer(address indexed from, address indexed to, uint256 value);

    // 事件，用来通知客户端代币被销毁
    event Burn(address indexed from, uint256 value);

    /**
     * 构造函数，自动执行
     *
     */
    constructor (
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        // 供应的份额，份额跟最小的代币单位有关，份额 = 币数 * 10 ** decimals
        balanceOf[msg.sender] = totalSupply;
        // 创建者拥有所有的代币
        name = tokenName;
        // 代币名称
        symbol = tokenSymbol;
        // 代币符号
    }

    /**
     * @dev 代币交易转移的内部实现,只能被本合约调用
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // 确保目地地址不为0x0，因为0x0地址代表的是销毁
        require(_to != 0x0);
        // 确保发送者账户有足够的余额
        require(balanceOf[_from] >= _value && _value > 0);
        // 确保_value为正数，如果为负数，那相当于付款者账户钱越买越多～哈哈～
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // 交易前，双方账户余额总和
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // 将发送方账户余额减value
        balanceOf[_from] = balanceOf[_from].sub(_value);
        // 将接收方账户余额加value
        balanceOf[_to] = balanceOf[_to].add(_value);
        //通知客户端交易发生 Transfer(_from, _to, _value);
        emit Transfer(_from, _to, _value);
        // 用assert来检查代码逻辑,即交易前后双发账户余额的和应该是相同的
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * @dev 从合约创建交易者账号发送`_value`个代币到 `_to`账号
     *
     * @param _to 接收者地址
     * @param _value 转移数额
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        //_from始终是合约创建者的地址 _transfer(msg.sender, _to, _value); }
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * 批量转账固定金额
     */
    function batchTransfer(address[] _to, uint _value) public returns (bool success) {
        require(_to.length > 0 && _to.length <= 20);
        for (uint i = 0; i < _to.length; i++) {
            _transfer(msg.sender, _to[i], _value);
        }
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        // Check allowance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * 授权_spender地址可以操作msg.sender账户下最多数量为_value的token。
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * 设置允许一个地址（合约）以我（创建交易者）的名义可最多花费的代币数
     *
     * @param _spender 被授权的地址（合约）
     * @param _value 最大可花费代币数
     * @param _extraData 发送给合约的附加数据
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    public
    returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            // 通知合约
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * 销毁合约账户中指定数量的代币
     *
     * @param _value 销毁的数量
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        // 检查合约账户是否有足够的代币
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        // 将合约账户余额减少
        totalSupply = totalSupply.sub(_value);
        // 更新总币数
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * 销毁用户账户中指定个代币
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);
        // Check allowance
        balanceOf[_from] = balanceOf[_from].sub(_value);
        // Subtract from the targeted balance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        // Subtract from the sender&#39;s allowance
        totalSupply = totalSupply.sub(_value);
        // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}

/******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/

contract HYZToken is Ownable, TokenERC20 {

    //设置买卖价格
    uint256 public sellPrice;
    uint256 public buyPrice;

    uint minBalanceForAccounts;

    mapping(address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor (
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        // Prevent transfer to 0x0 address. Use burn() instead
        require(balanceOf[_from] >= _value);
        // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Check for overflows
        require(!frozenAccount[_from]);
        // 检查发送人账号是否被冻结
        require(!frozenAccount[_to]);
        // 检查接收人账号是否被冻结

        if (msg.sender.balance < minBalanceForAccounts)
            sell((minBalanceForAccounts - msg.sender.balance) / sellPrice);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);
        // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }

    /// 给指定的账户增加代币，同时增加总供应量，只有合约部署者可调用
    /// @notice 创建`mintedAmount`标记并将其发送到`target`
    /// @param target 目标地址可以收到增发的token，同时发币总数增加
    /// @param mintedAmount 增发的数量 单位为wei
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] = balanceOf[target].add(mintedAmount);
        totalSupply = totalSupply.add(mintedAmount);
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    /// 资产冻结
    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target 目标冻结的账户地址
    /// @param freeze 是否冻结 true|false
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    /// 代币买卖（兑换）只有合约部署者可调用
    /// 注意买卖的价格单位是wei（最小的货币单位： 1 eth = 1000000000000000000 wei)
    /// @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    /// @param newSellPrice Price the users can sell to the contract
    /// @param newBuyPrice Price users can buy from the contract
    /**
    这个函数是设置代币的汇率。包括购买汇率buyPrice，出售汇率sellPrice。我们在实验时，为了简单，设置buyPrice=sellPrice=0.01ETH。当然这个比例是自由设定的。在实际中，你可以设计买入代币buyPrice的价格是1ETH，卖出代币sellPrice的价格是0.8ETH，这意味着每个代币的流入流出，你可以收取0.2ETH的交易费。是不是很激动，前提是你要忽悠大家用你的代币。0.01eth = 10**16
    */
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    /// 从合约购买货币的函数
    // 这个value是用户输入的购买代币支付的以太币数目。amount是根据汇率算出来的代币数目
    function buy() payable public {
        uint amount = msg.value.div(buyPrice);
        // 计算数量
        _transfer(this, msg.sender, amount);
        // makes the transfers
    }

    /// 向合约出售货币的函数
    /// @param amount amount of tokens to be sold
    function sell(uint256 amount) public {
        address myAddress = this;
        require(myAddress.balance >= amount * sellPrice);
        // 检查合约是否有足够的以太币去购买
        _transfer(msg.sender, this, amount);
        // makes the transfers
        msg.sender.transfer(amount.mul(sellPrice));
        // 发送以太币给卖家. 最后做这件事很重要，以避免递归攻击
    }

    /* 设置自动补充gas的阈值信息 */
    function setMinBalance(uint minimumBalanceInFinney) onlyOwner public {
        minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
    }
}