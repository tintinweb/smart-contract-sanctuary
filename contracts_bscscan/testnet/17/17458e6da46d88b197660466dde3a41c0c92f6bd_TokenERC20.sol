/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
    // 代币名
    string public name;
   // 代币logo
    string public symbol;
    // 代币小数位数
    uint8 public decimals = 18;
    // 18位小数是强烈建议的默认值，避免改变它
    uint256 public totalSupply;

    // 这将创建一个包含所有余额的数组
    mapping (address => uint256) public balanceOf;
    //某人授权给某人，使用自己的多少代币.
    //比如：当前调用者msg.sender，可以授权给很多地址他代币的使用权限。
    mapping (address => mapping (address => uint256)) public allowance;

    // 代币转移日志
    event Transfer(address indexed from, address indexed to, uint256 value);

    // 销毁代币日志
    event Burn(address indexed from, uint256 value);

    /**
     * 构造方法 
     */
    function TokenERC20(uint256 initialSupply,string tokenName,string tokenSymbol) public {
        //10 ** uint256(decimals)是10^18次方。
        totalSupply = initialSupply * 10 ** uint256(decimals);  //初始化代币总数  使用 decimal，两个星号**表示次方。
        balanceOf[msg.sender] = totalSupply;                // 给创建者所有的初始化代币
        name = tokenName;                                   // 设置代币显示的名字  
        symbol = tokenSymbol;                               //设置代币显示的符合，代币logo 
    }

    /**
     * 代币转移, internal只能合约内部调用
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // 防止传输到0x0地址。 使用burn（）来代替
        require(_to != 0x0);
        // 检查发送方有足够代币
        require(balanceOf[_from] >= _value);
        // 防止溢出，超过uint的数据范围，会变为负数
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // 保存以备将来的断言
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // 发送方减掉代币
        balanceOf[_from] -= _value;
        // 接收方增加代币
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);//event 日志
        // 断言用于使用静态分析来查找代码中的bug。 他们永远不会失败
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * @param _to 收币方地址
     * @param _value 转移多少代币
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * 从其他地址转移代币，需要其他地址授权给调用的人。
     *
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // 检查授权额度
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * 允许其他人，花费我的代币。
     *
     *授权给_spender地址，_value个代币
     *
     * @param _spender 授权给_spender地址
     * @param _value 代币数
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * 允许 `_spender` 代表你花费不大于`_value` 个代币, and then ping the contract about it
     *
     * @param _spender 授权给哪个地址
     * @param _value 授权最大代币数量
     * @param _extraData 一些额外的信息发送到批准的合同
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * 销毁代币 
     *
     * 从系统中不可逆地删除`_value'个代币
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   //检查调用者金额大于销毁数量
        balanceOf[msg.sender] -= _value;            // 调用者代币减掉
        totalSupply -= _value;                      // 总供应量减掉
        Burn(msg.sender, _value);                  // event日志
        return true;
    }

    /**
     * 从其他账户销毁代币
     *
     *
     * @param _from 从哪个账户销毁代币
     * @param _value 销毁的代币数
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // 减掉总供应量
        Burn(_from, _value);                              // event日志
        return true;
    }
}