pragma solidity ^0.4.17;

/*
    Utilities & Common Modifiers
*/
contract Utils {
    /**
        constructor
    */
    function Utils() public {
    }

    // verifies that an amount is greater than zero
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

    // validates an address - currently only checks that it isn&#39;t null
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

    // Overflow protected math functions

    /**
        @dev returns the sum of _x and _y, asserts if the calculation overflows

        @param _x   value 1
        @param _y   value 2

        @return sum
    */
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    /**
        @dev returns the difference of _x minus _y, asserts if the subtraction results in a negative number

        @param _x   minuend
        @param _y   subtrahend

        @return difference
    */
    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    /**
        @dev returns the product of multiplying _x by _y, asserts if the calculation overflows

        @param _x   factor 1
        @param _y   factor 2

        @return product
    */
    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

contract IOwned {
    // this function isn&#39;t abstract since the compiler emits automatically generated getter functions as external
    function owner() public pure returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}


/*
    owned 是一个管理者
*/
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address _prevOwner, address _newOwner);

    /**
     * 初始化构造函数
     */
    function Owned() public {
        owner = msg.sender;
    }

    /**
     * 判断当前合约调用者是否是管理员
     */
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    /**
     * 指派一个新的管理员
     * @param  _newOwner address 新的管理员帐户地址
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract IToken {
    // these functions aren&#39;t abstract since the compiler emits automatically generated getter functions as external
    function name() public pure returns (string) {}
    function symbol() public pure returns (string) {}
    function decimals() public pure returns (uint8) {}
    function totalSupply() public pure returns (uint256) {}
    function balanceOf(address _owner) public pure returns (uint256) { _owner; }
    function allowance(address _owner, address _spender) public pure returns (uint256) { _owner; _spender; }

    function _transfer(address _from, address _to, uint256 _value) internal;
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);

}


contract Token is IToken, Owned, Utils {
    /* 公共变量 */
    string public standard = &#39;&#39;;
    string public name = &#39;&#39;; //代币名称
    string public symbol = &#39;&#39;; //代币符号比如&#39;$&#39;
    uint8 public decimals = 0;  //代币单位
    uint256 public totalSupply = 0; //代币总量

    /*记录所有余额的映射*/
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* 在区块链上创建一个事件，用以通知客户端*/
    event Transfer(address indexed from, address indexed to, uint256 value);  //转帐通知事件
    event Approval(address indexed _owner, address indexed _spender, uint256 _value); //设置允许用户支付最大金额通知

    function Token() public 
    {
        name = &#39;YaoDun Chain&#39;;
        symbol = &#39;YAODUN&#39;;
        decimals = 8;
        totalSupply = 2000000000 * 10 ** uint256(decimals);

        balanceOf[owner] = totalSupply;
    }


    /**
     * 私有方法从一个帐户发送给另一个帐户代币
     * @param  _from address 发送代币的地址
     * @param  _to address 接受代币的地址
     * @param  _value uint256 接受代币的数量
     */
    function _transfer(address _from, address _to, uint256 _value)
      internal
      validAddress(_from)
      validAddress(_to)
    {


      //检查发送者是否拥有足够余额
      require(balanceOf[_from] >= _value);

      //检查是否溢出
      require(balanceOf[_to] + _value > balanceOf[_to]);

      //保存数据用于后面的判断
      uint previousBalances = safeAdd(balanceOf[_from], balanceOf[_to]);

      //从发送者减掉发送额
      balanceOf[_from] = safeSub(balanceOf[_from], _value);

      //给接收者加上相同的量
      balanceOf[_to] += safeAdd(balanceOf[_to], _value);

      //通知任何监听该交易的客户端
      emit Transfer(_from, _to, _value);

      //判断买、卖双方的数据是否和转换前一致
      assert(balanceOf[_from] + balanceOf[_to] == previousBalances);

    }

    /**
     * 从主帐户合约调用者发送给别人代币
     * @param  _to address 接受代币的地址
     * @param  _value uint256 接受代币的数量
     */
    function transfer(address _to, uint256 _value)
      public
      validAddress(_to)
      returns (bool)
    {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * 从某个指定的帐户中，向另一个帐户发送代币
     *
     * 调用过程，会检查设置的允许最大交易额
     *
     * @param  _from address 发送者地址
     * @param  _to address 接受者地址
     * @param  _value uint256 要转移的代币数量
     * @return        是否交易成功
     */
    function transferFrom(address _from, address _to, uint256 _value)
        public
        validAddress(_from)
        validAddress(_to)
        returns (bool)
    {
        //检查发送者是否拥有足够余额支出的设置
        require(_value <= allowance[_from][msg.sender]);   // Check allowance

        allowance[_from][msg.sender] -= safeSub(allowance[_from][msg.sender], _value);

        _transfer(_from, _to, _value);

        return true;
    }

    /**
     * 设置帐户允许支付的最大金额
     *
     * 一般在智能合约的时候，避免支付过多，造成风险
     *
     * @param _spender 帐户地址
     * @param _value 金额
     */
    function approve(address _spender, uint256 _value)
        public
        validAddress(_spender)
        returns (bool success)
    {

        require(_value == 0 || allowance[msg.sender][_spender] == 0);

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}

contract IYaoDun {

    function _transfer(address _from, address _to, uint256 _value) internal;
    function mintToken(address target, uint256 mintedAmount) public;
    function freezeAccount(address target, bool freeze) public;
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public;
    function buy() payable public;
    function sell(uint256 amount) public;
}


contract SmartToken is Owned, Token {

    string public version = &#39;0.1&#39;;

    // triggered when a smart token is deployed - the _token address is defined for forward compatibility, in case we want to trigger the event from a factory
    event NewSmartToken(address _token);

    /* 初始化合约，并且把初始的所有代币都给这合约的创建者
     * @param tokenName 代币名称
     * @param tokenSymbol 代币符号
     * @param tokenTotal 代币总量
     * @param decimalsUnits 代币后面的单位，小数点后面多少个0，以太币一样后面是是18个0
     */
    function SmartToken()
        public
        Token ()
    {
        emit NewSmartToken(address(this));
    }

}


contract YaoDun is IYaoDun, Token {

    //卖出的汇率,一个代币，可以卖出多少个以太币，单位是wei
    uint256 public sellPrice;

    //买入的汇率,1个以太币，可以买几个代币
    uint256 public buyPrice;

    //是否冻结帐户的列表
    mapping (address => bool) public frozenAccount;

    //定义一个事件，当有资产被冻结的时候，通知正在监听事件的客户端
    event FrozenFunds(address target, bool frozen);

    // triggered when a smart token is deployed - the _token address is defined for forward compatibility, in case we want to trigger the event from a factory
    event NewSmartToken(address _token);


    function YaoDun()
      public
      Token ()
    {
        sellPrice = 2;     //设置1个单位的代币(单位是wei)，能够卖出2个以太币
        buyPrice = 4;      //设置1个以太币，可以买0.25个代币
        emit NewSmartToken(address(this));
    }


    function _transfer(address _from, address _to, uint _value)
        validAddress(_from)
        validAddress(_to)
        internal
    {
        //检查发送者是否拥有足够余额
        require (balanceOf[_from] > _value);

        //检查是否溢出
        require (balanceOf[_to] + _value > balanceOf[_to]);

        //检查 冻结帐户
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);



        //从发送者减掉发送额
        balanceOf[_from] = safeSub(balanceOf[_from], _value);

        //给接收者加上相同的量
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);

        //通知任何监听该交易的客户端
        emit Transfer(_from, _to, _value);

    }

    /**
     * 账户挖矿
     * @param  target address 帐户地址
     * @param  mintedAmount uint256 增加的金额(单位是wei)
     */
    function mintToken(address target, uint256 mintedAmount)
        validAddress(target)
        public
        onlyOwner
    {

        //给指定地址增加代币，同时总量也相加
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;


        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    /**
     * 增加冻结帐户名称
     *
     * 你可能需要监管功能以便你能控制谁可以/谁不可以使用你创建的代币合约
     *
     * @param  target address 帐户地址
     * @param  freeze bool    是否冻结
     */
    function freezeAccount(address target, bool freeze)
        validAddress(target)
        public
        onlyOwner
    {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    /**
     * 设置买卖价格
     *
     * 如果你想让ether(或其他代币)为你的代币进行背书,以便可以市场价自动化买卖代币,我们可以这么做。如果要使用浮动的价格，也可以在这里设置
     *
     * @param newSellPrice 新的卖出价格
     * @param newBuyPrice 新的买入价格
     */
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
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
        require(balanceOf[address(this)] >= amount * sellPrice);

        _transfer(msg.sender, this, amount);

        msg.sender.transfer(amount * sellPrice);
    }
}