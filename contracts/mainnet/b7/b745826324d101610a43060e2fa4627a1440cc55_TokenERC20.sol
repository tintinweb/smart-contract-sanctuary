/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
    // 令牌的公有变量
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals 极力推荐使用默认值，尽量别改
    uint256 public totalSupply;

    // 创建所有账户余额数组
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // 在区块链上创建一个公共事件，它触发就会通知所有客户端
    event Transfer(address indexed from, address indexed to, uint256 value);

    // 通知客户端销毁数额
    event Burn(address indexed from, uint256 value);

    /**
     * 合约方法
     *
     * 初始化合约，将最初的令牌打入创建者的账户中
     */
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // 更新总发行量
        balanceOf[msg.sender] = totalSupply;                // 给创建者所有初始令牌
        name = tokenName;                                   // 设置显示名称
        symbol = tokenSymbol;                               // 设置显示缩写，例如比特币是BTC
    }

    /**
     * 内部转账，只能被该合约调用
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // 如果转账到 0x0 地址. 使用 burn() 替代
        require(_to != 0x0);
        // 检查发送者是否拥有足够的币
        require(balanceOf[_from] >= _value);
        // 检查越界
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // 将此信息保存用于将来确认
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // 从发送者扣币
        balanceOf[_from] -= _value;
        // 给接收者加相同数量币
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // 使用assert是为了使用静态分析找到代码bug. 它永远不会失败
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * 发送令牌
     *
     * 从你的账户发送个`_value` 令牌到 `_to` 
     *
     * @param _to 接收地址
     * @param _value 发送数量
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * 从其他地址发送令牌
     *
     * 从`_from` 发送 `_value` 个令牌到 `_to` 
     *
     * @param _from 发送地址
     * @param _to 接收地址
     * @param _value 发送数量
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * 设置其他地址限额
     *
     * 允许 `_spender` 以你的名义使用不超过 `_value`令牌 
     *
     * @param _spender 授权使用的地址
     * @param _value 最大可使用数量
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * 设置其他地址限额，并通知
     *
     * 允许 `_spender`以你的名义使用最多 `_value`个令牌, 然后通知合约
     *
     * @param _spender 授权使用的地址
     * @param _value  最大使用额度
     * @param _extraData 发送给已经证明的合约额外信息
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
     * 销毁令牌
     *
     * 永久除去 `_value` 个令牌，不可恢复
     *
     * @param _value 数量
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * 从其他账户销毁令牌
     *
     * 以‘_from’的名义，移除其 `_value`个令牌，不可恢复.
     *
     * @param _from 地址
     * @param _value 销毁数量
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