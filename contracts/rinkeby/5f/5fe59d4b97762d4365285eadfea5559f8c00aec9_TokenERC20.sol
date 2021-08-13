/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
    // 令牌的公共变量：全称、简称、精度、总供应
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    // 建立映射 地址对应了 uint' 便是他的余额
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // 事件，用来通知客户端Token交易发生
    event Transfer(address indexed from, address indexed to, uint256 value);

    // 事件，用来通知客户端代币被消耗(这里就不是转移, 是token用了就没了
    event Burn(address indexed from, uint256 value);

    /* 初始化代币给合约创建者 && 全程、简称、总供应 */
    function TokenERC20(uint256 initialSupply , string tokenName , string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals); 
        balanceOf[msg.sender] = totalSupply;              
        name = tokenName;                                  
        symbol = tokenSymbol;                              
    }

    /* 内部转账，只能被本合约调用 */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);    // 防止转到销毁地址，销毁用burn()instead。
        
        require(balanceOf[_from] >= _value);    // 检查余额足够
       
        require(balanceOf[_to] + _value > balanceOf[_to]);     // 检查判断溢出
       
        uint previousBalances = balanceOf[_from] + balanceOf[_to];     // 保存这个以备将来断言
        
        balanceOf[_from] -= _value;    // 从发件人中减去
       
        balanceOf[_to] += _value;     // 接收者增加
        
        Transfer(_from, _to, _value);
        
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);    // 断言用于使用静态分析来查找代码中的错误。 他们永远不应该失败
    }

    /* 发送_value代币 到地址_to */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /* 地址转移代币 */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);    
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /* 授权消费地址 */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* 授权允许_spender花费代币转账 */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /* 销毁删除令牌 */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   
        balanceOf[msg.sender] -= _value;           
        totalSupply -= _value;        
        Burn(msg.sender, _value);
        return true;
    }

    /* 销毁收到的代币，总供应量减少 */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);              
        require(_value <= allowance[_from][msg.sender]);  
        balanceOf[_from] -= _value;                    
        allowance[_from][msg.sender] -= _value;     
        totalSupply -= _value;                     
        Burn(_from, _value);
        return true;
    }
}