// 定义语言和版本
pragma solidity ^0.4.16;

// 调用人合约
contract owned {

    //地址
    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    //必须是自己
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    //转移所有权
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

// 定义令牌接收接口
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

// 合约主要逻辑
contract TokenERC20 {

    // Public variables of the token
    // 令牌的公共变量
    
    // 令牌的名称
    string public name;

    // 令牌的标识
    string public symbol;

    // 18 decimals is the strongly suggested default, avoid changing it
    // 强烈建议18位小数
    uint8 public decimals = 18;
    
    // 总供应量
    uint256 public totalSupply;

    // This creates an array with all balances
    // 创建一个map保存所有代币持有者的余额
    mapping (address => uint256) public balanceOf;

    // 地址配额
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    // 这将在区块链上生成将通知客户的公共事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This generates a public event on the blockchain that will notify clients
    // 这将在区块链上生成将通知客户的公共事件
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    // 通知客户销毁的总量
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     * 构造函数
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor ( uint256 initialSupply, string tokenName, string tokenSymbol ) public {               
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens 给令牌创建者所有初始化的数量
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     * 内部转账，私有函数，内部调用
     */
    function _transfer( address _from, address _to, uint _value ) internal {

        // Prevent transfer to 0x0 address. Use burn() instead
        // 检查地址格式
        require(_to != 0x0);

        // Check if the sender has enough
        // 检查转账者是否有足够token
        require(balanceOf[_from] >= _value);

        // Check for overflows
        // 检查是否超过最大量
        require(balanceOf[_to] + _value > balanceOf[_to]);

        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        // Subtract from the sender
        // 转出人减少
        balanceOf[_from] -= _value;

        // Add the same to the recipient
        // 转入人增加
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);

        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        // 该断言用于使用静态分析来查找代码中的错误，他们永远不应该失败
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     * 转账
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer( address _to, uint256 _value ) public returns (bool success) {

        //这里注意发送者就是合约调用者
        _transfer(msg.sender, _to, _value);

        return true;
    }

    /**
     * Transfer tokens from other address
     * 从另一个地址转移一定配额的token
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom( address _from, address _to, uint256 _value ) public returns (bool success) {

        require(_value <= allowance[_from][msg.sender]);     // Check allowance 检查从from地址中转移一定配额的token到to地址

        allowance[_from][msg.sender] -= _value; //转入地址的数量减少
        _transfer(_from, _to, _value);

        return true;
    }

    /**
     * Set allowance for other address
     * 设置配额给其他地址
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve( address _spender, uint256 _value) public returns (bool success) {

        allowance[msg.sender][_spender] = _value;   //调用地址给指定地址一定数量的配额
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }

    /**
     * Set allowance for other address and notify
     * 设置配额给其他地址，并且触发
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall( address _spender, uint256 _value, bytes _extraData ) public returns (bool success) {

        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     * 销毁令牌
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {

        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough 检查销毁地址余额
        balanceOf[msg.sender] -= _value;            // Subtract from the sender 账户里减少
        totalSupply -= _value;                      // Updates totalSupply 总供应量减少
        emit Burn(msg.sender, _value);              // 销毁

        return true;
    }

    /**
     * Destroy tokens from other account
     * 从指定账户销毁令牌
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender       地址
     * @param _value the amount of money to burn    数量
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {

        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough 检查余额
        require(_value <= allowance[_from][msg.sender]);    // Check allowance 检查配额

        balanceOf[_from] -= _value;                         // Subtract from the targeted balance 
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply 总供应量减少
        emit Burn(_from, _value);                           // 销毁

        return true;
    }
}

/******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/
// 高级版本
contract FOMOWINNER is owned, TokenERC20 {

    // 销售价格
    uint256 public sellPrice;

    // 购买价格
    uint256 public buyPrice;

    // 定义冻结账户
    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    // 冻结消息通知
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    // 构造
    constructor ( uint256 initialSupply, string tokenName, string tokenSymbol ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

    /* Internal transfer, only can be called by this contract */
    // 转账，内部私有函数
    function _transfer( address _from, address _to, uint _value  ) internal {
        
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead 检查转账地址格式
        require (balanceOf[_from] >= _value);               // Check if the sender has enough 检查转出地址余额
        require (balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows           检查转入金额不能为负

        require(!frozenAccount[_from]);                     // Check if sender is frozen  转出地址不在冻结账户中
        require(!frozenAccount[_to]);                       // Check if recipient is frozen 转入地址不在冻结账户中
        balanceOf[_from] -= _value;                         // Subtract from the spender  转出地址减少
        balanceOf[_to] += _value;                           // Add the same to the recipient 转入地址增加

        emit Transfer(_from, _to, _value);
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    /// 蒸发
    function mintToken( address target, uint256 mintedAmount ) onlyOwner public {

        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    /// 冻结账户
    function freezeAccount( address target, bool freeze ) onlyOwner public { 

        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    /// @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    /// @param newSellPrice Price the users can sell to the contract
    /// @param newBuyPrice Price users can buy from the contract
    /// 设置价格，针对eth
    function setPrices( uint256 newSellPrice, uint256 newBuyPrice ) onlyOwner public {

        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    /// @notice Buy tokens from contract by sending ether
    /// 从合约中购买令牌
    function buy() payable public {
        uint amount = msg.value / buyPrice;               // calculates the amount 计算收到的eth能换多少token
        _transfer(this, msg.sender, amount);              // makes the transfers  token转账
    }

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    /// 向合约卖出令牌
    function sell(uint256 amount) public {
        address myAddress = this;
        require(myAddress.balance >= amount * sellPrice); // checks if the contract has enough ether to buy 检查合约地址是否有足够的eth
        _transfer(msg.sender, this, amount);              // makes the transfers  token转账
        msg.sender.transfer(amount * sellPrice);          // sends ether to the seller. It&#39;s important to do this last to avoid recursion attacks 向对方发送eth
    }
}