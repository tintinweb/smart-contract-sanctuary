/**
 * Source Code first verified at https://etherscan.io on Wednesday, June 6, 2018
 (UTC) */

pragma solidity ^0.4.16;
//pragma solidity ^0.5.1;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
    // Public variables of the token
    string public name;							/* name 代币名称 */
    string public symbol;						/* symbol 代币图标 */
    uint8  public decimals = 18;			/* decimals 代币小数点位数 */ 
    uint256 public totalSupply;			//代币总量

    
    /* 设置一个数组存储每个账户的代币信息，创建所有账户余额数组 */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    /* event事件，它的作用是提醒客户端发生了这个事件，你会注意到钱包有时候会在右下角弹出信息 */
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
     /*初始化合约，将最初的令牌打入创建者的账户中*/
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  //以太币是10^18，后面18个0，所以默认decimals是18,给令牌设置18位小数的长度
        balanceOf[msg.sender] = totalSupply;                		// 给创建者所有初始令牌
        name = tokenName;                                   		// 设置代币（token）名称
        symbol = tokenSymbol;                               		// 设置代币（token）符号
    }

    /**
     * Internal transfer, only can be called by this contract
     */
     /**
     * 私有方法从一个帐户发送给另一个帐户代币
     * @param  _from address 发送代币的地址
     * @param  _to address 接受代币的地址
     * @param  _value uint256 接受代币的数量
     */
    function _transfer(address _from, address _to, uint _value) internal {
    
        // Prevent transfer to 0x0 address. Use burn() instead
        //避免转帐的地址是0x0
        require(_to != 0x0);
        
        // Check if the sender has enough
        //检查发送者是否拥有足够余额
        require(balanceOf[_from] >= _value);
        
        // Check for overflows
        //检查是否溢出
        require(balanceOf[_to] + _value > balanceOf[_to]);
        
        // Save this for an assertion in the future
        //保存数据用于后面的判断
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        
        // Subtract from the sender
        //从发送者减掉发送额
        balanceOf[_from] -= _value;
        
        // Add the same to the recipient
        //给接收者加上相同的量
        balanceOf[_to] += _value;
        
        //通知任何监听该交易的客户端
        Transfer(_from, _to, _value);
        
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        
        //判断买、卖双方的数据是否和转换前一致
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    
     /**
     * 从主帐户合约调用者发送给别人代币
     * @param  _to address 接受代币的地址
     * @param  _value uint256 接受代币的数量
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     /**
     * 从某个指定的帐户中，向另一个帐户发送代币
     *
     * 调用过程，会检查设置的允许最大交易额
     *
     * @param  _from address 发送者地址
     * @param  _to address 接受者地址
     * @param  _value uint256 要转移的代币数量
     * @return success        是否交易成功
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

 		/**
     * 设置帐户允许支付的最大金额
     * 一般在智能合约的时候，避免支付过多，造成风险
     * @param _spender 帐户地址
     * @param _value 金额
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

		/**
     * 设置帐户允许支付的最大金额
     * 一般在智能合约的时候，避免支付过多，造成风险，加入时间参数，可以在 tokenRecipient 中做其他操作
     * @param _spender 帐户地址
     * @param _value 金额
     * @param _extraData 操作的时间
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
     * 减少代币调用者的余额
     * 操作以后是不可逆的
     * @param _value 要删除的数量
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * 删除帐户的余额（含其他帐户）
     * 删除以后是不可逆的
     * @param _from 要操作的帐户地址
     * @param _value 要减去的数量
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
}