pragma solidity ^0.4.8;
// ================= Ownable Contract start =============================
/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
    //生产模式打开下方代码的注释
        //require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}
// ================= Ownable Contract end ===============================


// ================= Safemath library start ============================
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * 这是一个安全检查库，用来检查运算表达式
 */
library SafeMath {
    //乘法
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    //除法
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
    //减法
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    //加法
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
// ================= Safemath library end ============================

contract Token{
    // token总量，默认会为public变量生成一个getter函数接口，名称为totalSupply().
    uint256 public totalSupply;

    /// 获取账户_owner拥有token的数量 
    function balanceOf(address _owner) public constant returns (uint256 balance);

    //从消息发送者账户中往_to账户转数量为_value的token
    function transfer(address _to, uint256 _value) public returns (bool success);

    //从账户_from中往账户_to转数量为_value的token，与approve方法配合使用
    function transferFrom(address _from, address _to, uint256 _value) public returns   
    (bool success);

    //消息发送账户设置账户_spender能从发送账户中转出数量为_value的token
    function approve(address _spender, uint256 _value) public returns (bool success);

    //获取账户_spender可以从账户_owner中转出token的数量
    function allowance(address _owner, address _spender) public constant returns 
    (uint256 remaining);

    //发生转账时必须要触发的事件 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    //当函数approve(address _spender, uint256 _value)成功执行时必须触发的事件
    event Approval(address indexed _owner, address indexed _spender, uint256 
    _value);
}

contract standardToken is Token, Ownable {
    uint8 public decimals = 18;				//最多的小数位数
    
    using SafeMath for uint256;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    address public icoContract;

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
   
    function transfer(address _to, uint256 _value) public returns (bool success) {
        //默认totalSupply 不会超过最大值 (2^256 - 1).
        //如果随着时间的推移将会有新的token生成，则可以用下面这句避免溢出的异常
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;//从消息发送者账户中减去token数量_value
        balances[_to] += _value;//往接收账户增加token数量_value
        Transfer(msg.sender, _to, _value);//触发转币交易事件
        //如果send的地址为基金钱包，则表示为赎回交易，将份额转换为eth返还给客户账户
        //if(_to == wallet){
        //    msg.sender.transfer(_value.mul(nav).div(rate));
        //}
        return true;
    }
   

    function transferFrom(address _from, address _to, uint256 _value) public returns 
    (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= 
         _value && balances[_to] + _value > balances[_to]);
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;//接收账户增加token数量_value
        balances[_from] -= _value; //支出账户_from减去token数量_value
        allowed[_from][msg.sender] -= _value;//消息发送者可以从账户_from中转出的数量减少_value
        Transfer(_from, _to, _value);//触发转币交易事件
        return true;
    }
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success)   
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];//允许_spender从_owner中转出的token数
    }


    function mintToken(address target, uint256 _amount) onlyOwner public {
        uint256 amount = getWei(_amount);
        balances[target] += amount;
        totalSupply += amount;
        Transfer(0, this, amount);
        Transfer(this, target, amount);
    }
    
    function exchange(address _from, address _to, uint256 _amount) public returns (bool success) 
    {   
        uint256 amount = getWei(_amount);
        require(icoContract == msg.sender);
        require(balances[_from] >= amount);
        balances[_to] += amount;//接收账户增加token数量_value
        balances[_from] -= amount; //支出账户_from减去token数量_value
        Transfer(_from, _to, amount);//触发转币交易事件
    }
    
    function setIcoContract(address _icoContract) onlyOwner {
        if (_icoContract != address(0)) {
            icoContract = _icoContract;
        }
    }
    
    /**
     * 额度转wei
     *
     */
    function getWei(uint256 _value) internal returns (uint256){
	    //return _value * 10 ** uint256(decimals);
	    return _value;
    }
    
}


contract GBI is standardToken {
    string public name = &quot;CHIFU GBI&quot;;	//合约名称
    string public symbol = &quot;GBI&quot;;			//合约简称
    uint8 public decimals = 18;				//最多的小数位数
    string public version = &quot;V0.1&quot;;	//版本

}

contract TWDT is standardToken {
    string public name = &quot;CHIFU TWDT&quot;;	//合约名称
    string public symbol = &quot;TWDT&quot;;			//合约简称
    uint8 public decimals = 18;				//最多的小数位数
    string public version = &quot;V0.1&quot;;	//版本

}


/*
* 交易合约
*/
contract Purchase is Ownable {
    using SafeMath for uint256;
    // 订单状态枚举类型
    enum State { Created, Inactive, Finish }
    uint256 public nav;
    
    GBI gbi;
    TWDT twdt;
    mapping (address => uint256) balances;
    
    // 定义一个交易信息对象
    struct TradeData {
        string appsno;
        uint256 price;  //价格
        uint32 decimals; 
        address seller;
        address buyer;
        uint256 value;
        State state;
        bool used;
        uint8 flag;    //1:GBI->TWDT, 2:TWDT->GBI
    }

    mapping (string => TradeData) tradeRecords;  //记录用户交易流水
    

    function Purchase(address _gbi, address _twdt) {
        gbi = GBI(_gbi);
        twdt = TWDT(_twdt); 
    }

    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    modifier onlyBuyer(string _appsno) {
        TradeData data = tradeRecords[_appsno];
        require(msg.sender == data.buyer);
        _;
    }

    modifier onlySeller(string _appsno) {
        TradeData data = tradeRecords[_appsno];
        require(msg.sender == data.seller);
        _;
    }

    modifier inState(State _state,string _appsno) {
        TradeData data = tradeRecords[_appsno];
        require(data.state == _state);
        _;
    }

    // 订单状态变化时调用的事件函数
    event Aborted();
    event Finished();
    event Sold();
    
 
    function sell(uint8 _flag, string _appsno, uint256 _value, uint256 _price, uint32 _decimals){
        require(!tradeRecords[_appsno].used);
        require(_value > 0 && _price > 0);
        require(_flag == 1 || _flag == 2);
        
        TradeData memory data;
        data.appsno = _appsno;
        data.seller = msg.sender;
        data.value = _value;
        data.price = _price;
        data.state = State.Created;
        data.used = true;
        data.flag = _flag;
        data.decimals = _decimals;
    
        tradeRecords[_appsno]=data;
        if(_flag == 1){
            gbi.exchange(msg.sender, address(this), _value);
        }
        if(_flag == 2){
            twdt.exchange(msg.sender, address(this), _value);
        }
        Sold();
    }
    

    // 订单处于锁定之前，卖家可以终止购买并退回份额
    function abort(string _appsno)
        public
        onlySeller(_appsno)
        inState(State.Created, _appsno)
    {
        require(tradeRecords[_appsno].used);
        
        TradeData data = tradeRecords[_appsno];
        data.state = State.Inactive;
        tradeRecords[_appsno]=data;
        
        uint8 _flag = data.flag;
        if(_flag == 1){
            gbi.exchange(this, msg.sender, data.value); //退还份额
        }
        if(_flag == 2){
            twdt.exchange(this, msg.sender, data.value);
        }
        
        Aborted();
    }
    
    function buy(string _appsno) public{
        require(tradeRecords[_appsno].used);
        
        TradeData data = tradeRecords[_appsno];
        data.state = State.Finish;
        data.buyer = msg.sender;
        
        tradeRecords[_appsno]=data;
        
        uint8 _flag = data.flag;
        uint32 decimals = data.decimals;
        if(_flag == 1){
            gbi.exchange(this, msg.sender, data.value);
            if(decimals == 0){
                twdt.exchange(msg.sender, data.seller, data.value.mul(data.price));
            }else{
                twdt.exchange(msg.sender, data.seller, data.value.mul(data.price).div(decimals*10));
            }
        }
        if(_flag == 2){
            twdt.exchange(this, msg.sender, data.value);
            if(decimals == 0){
                gbi.exchange(msg.sender, data.seller, data.value.mul(data.price));
            }else{
                gbi.exchange(msg.sender, data.seller, data.value.mul(data.price).div(decimals*10));
            }
        }
        
        Finished();
    }
    
    // 当交易没有数据或者数据不对时，触发此函数，
    // 重置操作，确保参与者不会丢失资金
    function() {
        throw;
    }
    
    function setTokenGbi(address _token) onlyOwner {
        gbi = GBI(_token);
    }
    function setTokenTwdt(address _token) onlyOwner {
        twdt = TWDT(_token);
    }
   
    /**
     * 设置净值
     */
    function setNav(uint256 _value) onlyOwner public returns (bool success) {
        nav = _value;
        return true;
    }
    
}