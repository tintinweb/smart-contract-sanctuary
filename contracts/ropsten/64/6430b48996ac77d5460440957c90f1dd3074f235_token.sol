pragma solidity ^0.4.20;

/**
 * @title 基础版的代币合约
 */
contract token {
    
    /* 公共变量 */
    string public standard = "https://mshk.top";
    
    /*记录所有余额的映射*/
    mapping (address => uint256) public balanceOf;
    
    /* 初始化合约，并且把初始的所有代币都给这合约的创建者
     * @param initialSupply 代币的总数
     */
    function token (uint256 initialSupply) public {
        balanceOf[msg.sender] = initialSupply;
    }
    
    /**
     * 私有方法从一个帐户发送给另一个帐户代币
     * @param  from address 发送代币的地址
     * @param  to address 接受代币的地址
     * @param  value uint256 接受代币的数量
     */
    function _transfer (address from, address to, uint256 value) internal {
        
        //避免转帐的地址是0x0
        require(to != 0x0);
        
        //检查发送者是否拥有足够余额
        require(balanceOf[from] >= value);
        
        //检查是否溢出
        require(balanceOf[to] + value > balanceOf[to]);
        
        //保存数据用于后面的判断
        uint previousBalances = balanceOf[from] + balanceOf[to];
        
        //从发送者减掉发送额
        balanceOf[from] -= value;
        
        //给接收者加上相同的量
        balanceOf[to] += value;
        
        //判断买、卖双方的数据是否和转换前一致
        assert(balanceOf[from] + balanceOf[to] == previousBalances);
    }
    
    /**
     * 从主帐户合约调用者发送给别人代币
     * @param  to address 接受代币的地址
     * @param  value uint256 接受代币的数量
     */
    function transfer (address to, uint256 value) public {
        _transfer(msg.sender, to, value);
    }
}