/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity 0.4.18;

//interface就是个外部合约，你给了地址才能调他的方法
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

/**
 * owned 是一个管理者
 */
contract owned {
    address public owner;

    //定义了
    function owned() public {
        owner = msg.sender;
    }

    //一个判断当前合约调用者是否是创建者的 modifier, 什么是 modifier?你可以理解成 python 的装饰器,具体请看:
    //http://solidity.readthedocs.io/en/develop/structure-of-a-contract.html?highlight=modifiersolidity
 
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    /**
     * 指派一个新的管理员
     * @param  newOwner address 新的管理员帐户地址
     */
    function transferOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract token is owned{
    /* 公共变量 */
    string public name; //代币名称
    string public symbol; //代币符号比如'$'
    uint8 public decimals = 18;  //代币单位，以太坊是18个0
    uint256 public totalSupply; //代币总量

    /*记录地址余额的mapping*/
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* 在区块链上创建一个event，用以通知客户端,event 你可以理解成日志*/
    event Transfer(address indexed from, address indexed to, uint256 value);  //转帐通知事件
    event Burn(address indexed from, uint256 value);  //减去用户余额事件

    /* 初始化合约，并且把初始的所有代币都给这合约的创建者
     * @param initialSupply 代币的总数
     * @param tokenName 代币名称
     * @param tokenSymbol 代币符号
     */
     //请注意,跟合约名字相同的函数是初始函数,理解成 init 函数即可
    function token(uint256 initialSupply, string tokenName, string tokenSymbol) public {

        //初始化总量
        totalSupply = initialSupply * 10 ** uint256(decimals);    //以太币是10^18，后面18个0，所以默认decimals是18

        //给指定帐户初始化代币总量，初始化用于奖励合约创建者
        //balanceOf[msg.sender] = totalSupply;
        balanceOf[this] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;

    }

    /**
    * 合约拥有者，可以为指定帐户创造一些代币,即所谓的增发
    * @param  target address 帐户地址
    * @param  mintedAmount uint256 增加的金额(单位是wei)
    */
    function mintToken(address target, uint256 mintedAmount) public onlyOwner {

        //给指定地址增加代币，同时总量也相加
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
    }
    /**
     * 私有方法从一个帐户发送给另一个帐户代币
     * @param  _from address 发送代币的地址
     * @param  _to address 接受代币的地址
     * @param  _value uint256 接受代币的数量
     */
    function _transfer(address _from, address _to, uint256 _value) internal {

      //避免转帐的地址是0x0,因为0x0地址代表销毁
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
     *
     * 调用过程，会检查设置的允许最大交易额
     *
     * @param  _from address 发送者地址
     * @param  _to address 接受者地址
     * @param  _value uint256 要转移的代币数量
     * @return success        是否交易成功
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //检查发送者是否拥有足够余额
        require(_value <= allowance[_from][msg.sender]);   // Check allowance

        allowance[_from][msg.sender] -= _value;

        _transfer(_from, _to, _value);

        return true;
    }

    /**
     * 设置帐户允许支付的最大金额
     * @param _spender 帐户地址
     * @param _value 金额
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * 设置帐户允许支付的最大金额
     *
     * 一般在智能合约的时候，避免支付过多，造成风险，可以在 tokenRecipient 中做其他操作
     *
     * @param _spender 帐户地址
     * @param _value 金额
     * @param _extraData 发送给合约的附加数据
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        //可以看到,tokenRecipient里需要传入一个地址
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * 减少代币调用者的余额
     *
     * 操作以后是不可逆的
     *
     * @param _value 要删除的数量
     */
    function burn(uint256 _value) public returns (bool success) {
        //检查帐户余额是否大于要减去的值
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough

        //给指定帐户减去余额
        balanceOf[msg.sender] -= _value;

        //代币问题做相应扣除
        totalSupply -= _value;

        Burn(msg.sender, _value);
        return true;
    }

    /**
     * 删除帐户的余额（含其他帐户）
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


 // 增加冻结用户、挖矿、根据指定汇率购买(售出)代币价格的功能

contract SunnyCoin is owned, token {

    //卖出的汇率,一个代币，可以换多少个以太币，单位是wei
    uint256 public sellPrice;

    //买入的汇率,1个以太币，可以买几个代币
    uint256 public buyPrice;

    //是否冻结帐户的列表
    mapping (address => bool) public frozenAccount;

    //定义一个事件，当有资产被冻结的时候，通知正在监听事件的客户端
    event FrozenFunds(address target, bool frozen);


    /*初始化合约，并且把初始的所有的令牌都给这合约的创建者
     * @param initialSupply 所有币的总数
     * @param tokenName 代币名称
     * @param tokenSymbol 代币符号
     * @param centralMinter 是否指定其他帐户为合约所有者,为0是去中心化
     */
    function SunnyCoin(
      uint256 initialSupply,
      string tokenName,
      string tokenSymbol,
      address centralMinter
    ) public token (initialSupply, tokenName, tokenSymbol) {

        //设置合约的管理者
        if(centralMinter != 0 ) owner = centralMinter;

        sellPrice = 1000;     //设置1个单位的代币(单位是wei)，能够赎回出0.001个以太币
        buyPrice = 100;      //设置1个以太币，可以买100个代币
    }


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

        //检查 冻结帐户
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
     * 合约拥有者，可以为指定帐户创造一些代币
     * @param  target address 帐户地址
     * @param  mintedAmount uint256 增加的金额(单位是wei)
     */
    function mintToken(address target, uint256 mintedAmount) public onlyOwner {

        //给指定地址增加代币，同时总量也相加
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;


        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

    /**
     * 增加冻结帐户名称
     *
     * 你可能需要监管功能以便你能控制谁可以/谁不可以使用你创建的代币合约
     *
     * @param  target address 帐户地址
     * @param  freeze bool    是否冻结
     */
    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    /**
     * 设置买卖价格
     *
     * 如果你想让ether(或其他代币)为你的代币进行背书,以便可以市场价自动化买卖代币,我们可以这么做。如果要使用浮动的价格，也可以在这里设置,这个函数已经实现了代币的市场化,当然比较初级
     *
     * @param newSellPrice 新的卖出价格
     * @param newBuyPrice 新的买入价格
     */
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    
    function () public payable{
        buy();
    }

    //注意,这些交易函数会消耗相应的以太币,目前,接受以太币的函数需要增加 payable 关键字
    /**
     * 使用以太币购买代币
     */
    function buy() payable public {
        uint256 tokensToBuy;
        uint256 etherUsed = msg.value;
        tokensToBuy = etherUsed * 1e18 / 1 ether * buyPrice;
        _transfer(this, msg.sender, tokensToBuy);
    }

    /**
     * @dev 卖出代币
     * @return 要卖出代币的数量
     */
    function sell(uint256 amount) public {

        //检查合约的余额是否足够
        require(this.balance >= amount / sellPrice);

        _transfer(msg.sender, this, amount);

        msg.sender.transfer(amount / sellPrice);
    }
    
    function extractEther() public onlyOwner {
      owner.transfer(address(this).balance);
   }
}