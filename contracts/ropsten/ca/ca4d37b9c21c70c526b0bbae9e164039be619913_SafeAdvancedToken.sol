pragma solidity ^0.4.21;



//在执行检查时用普通数学替换安全数学


//     THIS IS NEXT CONTRACT TO BE TESTED

//VERSION 0.3


/**
 *
 *  数学运算与安全检查发生错误
 */


library SafeMath {

    /**
    * 将两个数字相乘，在溢出时抛出。
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
  * 两个数的整数除法，截断商。
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // 除以0时，固体自动抛出
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // 没有这种情况不成立
    return a / b;
  }

  /**
  *  减去两个数字，在溢出时抛出（即如果减数大于被减数）。
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * 添加两个数字，在溢出时抛出。
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract owned {
    //Safe Math
    using SafeMath for uint256;

    //Damage control
    bool internal contractBlocked = true;

    address internal ownerCandidate;//将所有权店主候选人转移到此变量并使其调用确认所有权以确保该地址实际上可以调用合同
    address public owner;

    //function owned() public {
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event ContractBlocked(uint256 time_of_blocking);

    function blockContract() onlyOwner public {
        emit ContractBlocked(now);
        contractBlocked = true;
    }

    event ContractEnabled(uint256 time_of_enabling);

    function enableContract() onlyOwner public {
        emit ContractEnabled(now);
        contractBlocked = false;
    }

    modifier onlyIfEnabled {
        require(contractBlocked == false);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        ownerCandidate = newOwner;
    }
    function confirmOwnership() public {
        require(msg.sender == ownerCandidate);
        owner = ownerCandidate;
    }

}


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 is owned {
    //Safe Math
    using SafeMath for uint256;

    // 令牌的公共变量
    string public name;
    string public symbol;
    uint8 public decimals = 18; // 18位小数是强烈建议的默认值，避免改变它
    uint256 public totalSupply;

    // 这将创建一个包含所有余额的数组
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // 这会在区块链上产生一个公共事件来通知客户
    event Transfer(address indexed from, address indexed to, uint256 value);

    // 这会通知客户有关已烧毁的金额
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * 将初始供应令牌初始化为合同的创建者
     */
    //function TokenERC20(
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol        
    ) public {
        totalSupply = initialSupply.mul(10 ** uint256(decimals));  // Update total supply with the decimal amount//!S!M        
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * 内部转移，只能由本合同调用
     */
     
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool){
        // 防止转移到0x0地址。
        require(_to != 0x0);
        // 检查发件人是否足够
        require(balanceOf[_from] >= _value);
        // 检查溢出
        require(balanceOf[_to].add(_value) > balanceOf[_to]);//!S!M
        // 将此保存为将来的断言
        uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]);//!S!M
        // 从发件人中减去
        balanceOf[_from] = balanceOf[_from].sub(_value);//!S!M
        // 将其添加到收件人
        balanceOf[_to] = balanceOf[_to].add(_value);//!S!M
        emit Transfer(_from, _to, _value);
        // 断言用于使用静态分析来查找代码中的错误。
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);//!S!M
        return true;
    }

    /**
     * Transfer tokens
     *
     * 从您的帐户发送`_value`令牌给`_to`
     *
     
     */
    function transfer(address _to, uint256 _value) onlyIfEnabled public returns (bool){
        return _transfer(msg.sender, _to, _value);        
    }

    /**
     * 从其他地址转移令牌
     *
     * 
     *
     *
     */
    function transferFrom(address _from, address _to, uint256 _value) onlyIfEnabled public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);//!S!M
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * 允许`_spender`代表您花费的`_value`代币
     *
     *  _spender授权使用的地址
     *  _value他们可以花费的最大金额
     */
    function approve(address _spender, uint256 _value) onlyIfEnabled public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * 设置其他地址的津贴并通知
     *
     * 允许`_spender`代替您花费`_value`代币，然后对合同进行ping处理
     *
     *  _spender授权使用的地址
     *  _value他们可以花费的最大金额
     * _extraData额外的信息发送到批准的合同
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) onlyIfEnabled
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * 不可逆地从系统中删除`_value`令牌
     *
     * _价值燃烧的金额
     */
    function burn(uint256 _value) onlyIfEnabled public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value); // Subtract from the sender//!S!M
        totalSupply = totalSupply.sub(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * 销毁来自其他帐户的令牌
     *
     * 代表`_from`，不可撤销地从系统中删除_value`标记。
     *
     *  来自发件人的地址
     *  _价值燃烧的金额
     */
    function burnFrom(address _from, uint256 _value) onlyIfEnabled public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] = balanceOf[_from].sub(_value);    // Subtract from the targeted balance//!S!M
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value); // Subtract from the sender&#39;s allowance//!S!M
        totalSupply = totalSupply.sub(_value);                              // Update totalSupply//!S!M
        emit Burn(_from, _value);
        return true;
    }
}

library SafeERC20 {
    function safeTransfer(TokenERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        TokenERC20 token,
        address from,
        address to,
        uint256 value
    )
    internal
    {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(TokenERC20 token, address spender, uint256 value) internal {
        require(token.approve(spender, value));
    }
}

/******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/

contract SafeAdvancedToken is TokenERC20 {
    //Safe Math
    using SafeMath for uint256;    

    //检查与正常ERC20的兼容性
    using SafeERC20 for TokenERC20;

    uint256 public sellPrice;
    uint256 public buyPrice;


    bool public weiCapSet = false;
    uint256 public hardCapWei = 0;//本合同可以在wei中接受的最大限度的醚
    uint256 public softCapWei = 0;//如果我们达到这个目标，ICO的资金就会成功
    uint256 public totalWei = 0;//筹集的总金额
    uint durationInyears  = 2;
    bool public ICOSet = true;
    uint256 public preICOstartTime = now;//决定资金何时开始的UNIX时间戳
    uint256 public preICOendTime = now + durationInyears  * 1 years;//UNIX时间戳决定资金何时结束
    uint256 public ICOstartTime = now;//决定资金何时开始的UNIX时间戳
    uint256 public ICOendTime = now + durationInyears  * 1 years;//UNIX时间戳决定资金何时结束
    bool public ICOPricesSet = true;
    uint256 public preICOBuyPrice;
    uint256 public ICOBuyPrice;
    uint256 public postICOBuyPrice;
    uint256 public postICOSellPrice;
    //添加功能，以防止用户在满足特定条件前销售代币
    //与ehter和coinbase和cryptopia帐户帐户
    //如果众包不成功，我们会退款
    // 应该使用钱包
    //如果我们在融资结束后达成softcap所有剩余的令牌
    //允许预售 - 在竞选的前几天为投资者提供早期的鸟类折扣基本上是必须的。
    //我们是否应该允许少数人马上购买大部分代币，或者我们是否想要分配它们

    modifier ICOnotSetup {
        require(ICOSet == true);
        _;
    }
    event SetupICONowTime(uint256 timestamp);
    function setupICO(uint256 _preICOstartTime, uint256 _preICOendTime, uint256 _ICOstartTime, uint256 _ICOendTime) onlyOwner ICOnotSetup public{        
        emit SetupICONowTime(now);
        require(_preICOstartTime<=_preICOendTime && _preICOendTime<=_ICOstartTime && _ICOstartTime<=_ICOendTime);        
        preICOstartTime=_preICOstartTime;
        preICOendTime=_preICOendTime;
        ICOstartTime=_ICOstartTime;
        ICOendTime=_ICOendTime;
        ICOSet=true;
    }
    event TimeOut(string command, int256 time);
    function isPreICO() public view returns(int8){
        if(ICOSet==true){
            emit TimeOut(&#39;isPreICO&#39;, int256(preICOendTime - now));
            if ((now>=preICOstartTime)&&(now<=preICOendTime)){
                return 1;
            } else {
                return 0;
            }
        } else {
            return -1;
        }
    }
    function isICO() public view returns(int8){
        if(ICOSet==true){
            emit TimeOut(&#39;isICO&#39;, int256(ICOendTime - now));
            if ((now>=ICOstartTime)&&(now<=ICOendTime)){
                return 1;
            } else {
                return 0;
            }
        } else {
            return -1;
        }
    }
    function isICOOver() public view returns(int8){        
        if(ICOSet==true){
            emit TimeOut(&#39;isICOOver&#39;, int256(ICOendTime - now));
            if (now>ICOendTime){            
                return 1;
            } else {
                return 0;
            }
        } else {
            return -1;
        }
    }
    function setupICOPrices(uint256 _preICOBuyPrice, uint256 _ICOBuyPrice, uint256 _postICOBuyPrice, uint256 _postICOSellPrice) onlyOwner public{
        require(ICOSet == true);
        ICOPricesSet = true;
        preICOBuyPrice=_preICOBuyPrice;
        ICOBuyPrice=_ICOBuyPrice;
        postICOBuyPrice=_postICOBuyPrice;
        postICOSellPrice=_postICOSellPrice;
    }
    modifier weiCapnotSet {
        require(weiCapSet == false);
        _;
    }
    function setupWeiCaps(uint256 _softCapWei, uint256 _hardCapWei) onlyOwner weiCapnotSet public {
        require(_hardCapWei>=_softCapWei);
        hardCapWei = _hardCapWei;
        softCapWei = _softCapWei;
        weiCapSet = true;
    }
    function SoftCapReached() public view returns (bool){
        return (weiCapSet == true)&&(totalWei>=softCapWei);
    }
    function HardCapReached() public view returns (bool){
        return (weiCapSet == true)&&(totalWei>=hardCapWei);
    }


    mapping (address => bool) public frozenAccount;


    /* 这会在区块链上产生一个公共事件来通知客户 */
    event FrozenFunds(address indexed target, bool indexed frozen);


    /* 将初始供应令牌初始化为合同的创建者 */
    //function SafeAdvancedToken(
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

    /* 内部转移，只能由本合同调用 */
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool){
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to].add(_value) > balanceOf[_to]); // Check for overflows//!S!M
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] = balanceOf[_from].sub(_value);                         // Subtract from the sender//!S!M
        balanceOf[_to] = balanceOf[_to].add(_value);                           // Add the same to the recipient//!S!M
        emit Transfer(_from, _to, _value);
        return true;
    }

    /// 请注意创建`mintedAmount`标记并将其发送到`target`
    /// 参数目标地址接收令牌
    /// param mintedAmount它将收到的令牌数量
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] = balanceOf[target].add(mintedAmount);//!S!M
        totalSupply = totalSupply.add(mintedAmount);//!S!M
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    /// 注意`冻结？防止|允许来自发送和接收令牌的“目标
    /// 参数目标地址被冻结
    /// param冻结或冻结或不冻结
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    /// 请注意允许用户为`newBuyPrice` eth购买代币并为`newSellPrice` eth销售代币
    /// 参数newSellPrice价格用户可以卖给合同
    /// param newBuyPrice Price用户可以从合同中购买
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    /// 注意通过发送乙醚来从合同中购买代币
    function buy() payable onlyIfEnabled public {
        if(ICOSet==true){
            require(isPreICO()==1 || isICO()==1);
            if(ICOPricesSet==true){
                if(isPreICO()==1){
                   buyPrice = preICOBuyPrice;
                } else if(isICO()==1){
                   buyPrice = ICOBuyPrice;
                } else if(isICOOver()==1){
                   buyPrice = postICOBuyPrice;
                   sellPrice = postICOSellPrice;
                }
            }
        }
        require(buyPrice>0);
        uint256 amount = msg.value.div(buyPrice);              // 计算金额//!S!M
        totalWei = totalWei.add(msg.value);
        require(HardCapReached()==false);
        require(_transfer(this, msg.sender, amount)==true);   // 进行转账
    }

    /// 通知销售&#39;金额&#39;令牌合同
    /// 参数金额的待售令牌

    bool public sellAllowed = false;
    function usersCanSell(bool value) onlyOwner public{
        sellAllowed = value;
    }
    function sell(uint256 amount) onlyIfEnabled public{
        require(sellAllowed==true);
        if(ICOSet==true){
            require(isICOOver()==1);
            if(ICOPricesSet==true){
                buyPrice = postICOBuyPrice;
                sellPrice = postICOSellPrice;
            }
        }       
        require(sellPrice>0);
        uint256 weiAmount = amount.mul(sellPrice);//!S!M
        require(address(this).balance >= weiAmount);      // 检查合约是否有足够的购买力//!S!M
        _transfer(msg.sender, this, amount);              // 进行转账        
        totalWei = totalWei.sub(weiAmount);
        msg.sender.transfer(weiAmount);          // 向卖家发送乙醚。最后做这件事很重要，以避免递归攻击
    }
    bool public refundEnabled = false;
    function setRefund(bool value) onlyOwner public{
        refundEnabled = value;
    }
    //以当前价格收回所有用户令牌，与销售所有所有者令牌相同
    function refundToken() onlyIfEnabled public{        
        require(refundEnabled==true);
        require(sellPrice>0);
        if(ICOSet==true){
            require(isICOOver()==1);
            if(ICOPricesSet==true){
                buyPrice = postICOBuyPrice;
                sellPrice = postICOSellPrice;
            }
        }       
        uint256 weiAmount = balanceOf[msg.sender].mul(sellPrice);//!S!M
        require(address(this).balance >= weiAmount);             // 检查合约是否有足够的购买力//!S!M
        _transfer(msg.sender, this, balanceOf[msg.sender]);              // 进行转账       
        totalWei = totalWei.sub(weiAmount);
        msg.sender.transfer(weiAmount);          // 向卖家发送乙醚。最后做这件事很重要，以避免递归攻击      
    }
    /// 请注意将乙醚发送给所有者
    /// 从合同转移到地址的参数金额
    event FundsToOwner(uint256 _time_of_transfer, uint256 amount);
    function fundsToOwner(uint256 amount)public onlyOwner{
        require(address(this).balance >= amount);
        owner.transfer(amount);
        emit FundsToOwner(now, amount);
    }

    // 请注意将ether发送到任何地址
    event FundsToAddress(uint256 _time_of_transfer, address indexed sendTo, uint256 amount);
    function fundsToAddress(address sendTo, uint256 amount)public onlyOwner{
        require(address(this).balance >= amount);
        sendTo.transfer(amount);
        emit FundsToAddress(now, sendTo, amount);
    }

   //实施自我毁灭（注意自杀被弃用）
    function warningERASEcontract() public onlyOwner {
        //检查ICO是否已经结束
        selfdestruct(owner);
    }

    //检查为什么后备功能不会将数据写入事件日志
    //回退函数只能记录日志，因为那么多的东西就是我们所有的天然气
    event FallbackEvent(address sender);//注意事项不得超过一个参数或气体不足（2300）
    function() payable public{//我们贪心我们总是接受以太网，即使我们被阻止但我们记录了转移基金！为了退还使用fundsToAddress
        emit FallbackEvent(msg.sender);
        //扔;在我们不想接受钱的情况下
    }
}