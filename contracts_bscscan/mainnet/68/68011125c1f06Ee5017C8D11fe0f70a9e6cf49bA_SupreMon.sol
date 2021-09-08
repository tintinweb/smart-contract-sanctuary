/**
 *Submitted for verification at BscScan.com on 2021-09-08
*/

pragma solidity ^0.4.16;
 
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }
/**
 * owned是合约的管理者
 */
contract owned {
    address public owner;
 
    /**
     * 初台化构造函数
     */
    function owned () public {
        owner = msg.sender;
    }
 
    /**
     * 判断当前合约调用者是否是合约的所有者
     */
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
 
    /**
     * 合约的所有者指派一个新的管理员
     * @param  newOwner address 新的管理员帐户地址
     */
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}
 
/**
 * 基础代币合约
 */
contract TokenERC20 {
    string public name; //发行的代币名称
    string public symbol; //发行的代币符号
    uint8 public decimals = 18;  //代币单位，展示的小数点后面多少个0。
    uint256 public totalSupply; //发行的代币总量
 
    /*记录所有余额的映射*/
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
 
    /* 在区块链上创建一个事件，用以通知客户端*/
    //转帐通知事件
    event Transfer(address indexed from, address indexed to, uint256 value);  
    event Burn(address indexed from, uint256 value);  //减去用户余额事件
 
    /* 初始化合约
     * @param initialSupply 代币的总数
     * @param tokenName 代币名称
     * @param tokenSymbol 代币符号
     */
    function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        //初始化总量
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        //给指定帐户初始化代币总量，初始化用于奖励合约创建者
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }
 
 
    /**
     * 私有方法从一个帐户发送给另一个帐户代币
     * @param  _from address 发送代币的地址
     * @param  _to address 接受代币的地址
     * @param  _value uint256 接受代币的数量
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
 
      //避免转帐的地址是0x0
      require(_to != 0x0);
 
      //检查发送者是否拥有足够余额
      require(balanceOf[_from] >= _value);
 
      //检查是否溢出
      require(balanceOf[_to] + _value > balanceOf[_to]);
 
      //保存数据用于后面的判断
      uint previousBalances = balanceOf[_from] + balanceOf[_to];
 
      //从发送者减掉发送额
      balanceOf[_from] -= _value;
 
      //给接收者加上相同的量
      balanceOf[_to] += _value;
 
      //通知任何监听该交易的客户端
      Transfer(_from, _to, _value);
 
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
     * 调用过程，会检查设置的允许最大交易额
     * @param  _from address 发送者地址
     * @param  _to address 接受者地址
     * @param  _value uint256 要转移的代币数量
     * @return success        是否交易成功
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //检查发送者是否拥有足够余额
        require(_value <= allowance[_from][msg.sender]);
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
    function approve(address _spender, uint256 _value) public returns (bool success) {
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
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
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
        //检查帐户余额是否大于要减去的值
        require(balanceOf[msg.sender] >= _value);
        //给指定帐户减去余额
        balanceOf[msg.sender] -= _value;
        //代币问题做相应扣除
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }
 
    /**
     * 删除帐户的余额
     * 删除以后是不可逆的
     * @param _from 要操作的帐户地址
     * @param _value 要减去的数量
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        //检查帐户余额是否大于要减去的值
        require(balanceOf[_from] >= _value);
        //检查 其他帐户 的余额是否够使用
        require(_value <= allowance[_from][msg.sender]);
        //减掉代币
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        //更新总量
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}
 
/**
 * 代币冻结机器人、
 * 代币自动销售和购买、
 * 高级代币功能
 */
contract SupreMon is owned, TokenERC20 {
 
    //卖出的汇率,一个代币，可以卖出多少个以太币，单位是wei
    uint256 public sellPrice;
 
    //买入的汇率,1个以太币，可以买几个代币
    uint256 public buyPrice;
 
    //是否冻结机器人帐户的列表
    mapping (address => bool) public frozenAccount;
 
    //定义一个事件，当有机器人被冻结的时候，通知正在监听事件的客户端
    event FrozenFunds(address target, bool frozen);
 
 
    /*初始化合约，并且把初始的所有的令牌都给这合约的创建者
     * @param initialSupply 所有币的总数
     * @param tokenName 代币名称
     * @param tokenSymbol 代币符号
     */
        function SupreMon(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}
 
 
    /**
     * 私有方法，从指定帐户转出余额
     * @param  _from address 发送代币的地址
     * @param  _to address 接受代币的地址
     * @param  _value uint256 接受代币的数量
     */
    function _transfer(address _from, address _to, uint _value) internal {
 
        //避免转帐的地址是0x0
        require (_to != 0x0);
 
        //检查发送者是否拥有足够余额
        require (balanceOf[_from] > _value);
 
        //检查是否溢出
        require (balanceOf[_to] + _value > balanceOf[_to]);
 
        //冻结机器人帐户
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
 
        //从发送者减掉发送额
        balanceOf[_from] -= _value;
 
        //给接收者加上相同的量
        balanceOf[_to] += _value;
 
        //通知任何监听该交易的客户端
        Transfer(_from, _to, _value);
 
    }
 
    /**
     * 合约拥有者，可以为指定帐户转移一些代币
     * @param  target address 帐户地址
     * @param  mintedAmount uint256 转移的金额(单位是wei)
     */
    function BatchSend(address target, uint256 mintedAmount) onlyOwner public {
 
        //给指定地址转移代币，同时该账户余额减少
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
 
 
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
 
    /**
     * 自动冻结机器人帐户名称
     *
     */
    function withdrawtoken(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
 
    /**
     * 设置买卖价格
     *
     * 如果你想让ether(或其他代币)为你的代币进行背书,以便可以市场价自动化买卖代币,我们可以这么做。如果要使用浮动的价格，也可以在这里设置
     *
     * @param newSellPrice 新的卖出价格
     * @param newBuyPrice 新的买入价格
     */
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
 
    /**
     * 使用以太币购买代币
     */
    function buy() payable public {
      uint amount = msg.value / buyPrice;
 
      _transfer(this, msg.sender, amount);
    }
 
    /**
     * @dev 卖出代币
     * @return 要卖出的数量(单位是wei)
     */
    function sell(uint256 amount) public {
 
        //检查合约的余额是否充足
        require(this.balance >= amount * sellPrice);
 
        _transfer(msg.sender, this, amount);
 
        msg.sender.transfer(amount * sellPrice);
    }
}