pragma solidity ^0.4.16;
contract Token{
    uint256 public totalSupply;
 
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns   
    (bool success);
 
    function approve(address _spender, uint256 _value) public returns (bool success);
 
    function allowance(address _owner, address _spender) public constant returns 
    (uint256 remaining);    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 
contract TokenDemo is Token {    
	string public name;                   //名称，例如"My test token"
    uint8 public decimals;               //返回token使用的小数点后几位。比如如果设置为3，就是支持0.001表示.
    string public symbol;               //token简称,like MTT
	uint256  startTime;//记录合约部署时间
	address simu;//私募账户
	address team;//团队账户
    function TokenDemo(uint256 _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol,address sq,address sm,address yy,address group) public {
        totalSupply = _initialAmount * 10 ** uint256(_decimalUnits);         // 设置初始总量
       // balances[msg.sender] = totalSupply; // 初始token数量给予消息发送者，因为是构造函数，所以这里也是合约的创建者
	   balances[sq]=totalSupply/10*3;//社区账户
	   simu=sm;
	   balances[simu]=totalSupply/10*3;//私募账户
	   balances[yy]=totalSupply/10*2;//运营账户
	   team=group;
	   balances[team]=totalSupply/10*2;//
       name = _tokenName;                   
       decimals = _decimalUnits;          
       symbol = _tokenSymbol;
	   startTime=now;
    }
    function transfer(address _to, uint256 _value) public returns (bool success) {
            //默认totalSupply 不会超过最大值 (2^256 - 1).        
    //如果随着时间的推移将会有新的token生成，则可以用下面这句避免溢出的异常
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(_to != 0x0);
        balances[msg.sender] -= _value;//从消息发送者账户中减去token数量_value
        balances[_to] += _value;//往接收账户增加token数量_value
        Transfer(msg.sender, _to, _value);//触发转币交易事件
        return true;
    }
 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		if(_from==team){
			uint256 timeTemp=(now-startTime)/60/60;//小时
		if(timeTemp<1){//第一阶段里时间小于1小时不允许交易直接返回
			return false;
		}
		if(timeTemp<2&&timeTemp>=1&&(balances[_from]-_value)<(totalSupply/25*4)){
			return false;//第二阶段不允许时间大于1小时且小于2小时，账户额度减转账值少于4/25的交易;
		}
		if(timeTemp<3&&timeTemp>=2&&(balances[_from]-_value)<(totalSupply/25*3)){
			return false;//第三阶段不允许时间大于2小时且小于3小时，账户额度减转账值少于3/25的交易;
		}
		if(timeTemp<4&&timeTemp>=3&&(balances[_from]-_value)<(totalSupply/25*2)){
			return false;//第四阶段不允许时间大于3小时且小于4小时，账户额度减转账值少于2/25的交易;
		}
		if(timeTemp<5&&timeTemp>=4&&(balances[_from]-_value)<(totalSupply/25)){
			return false;//第五阶段不允许时间大于4小时且小于5小时，账户额度减转账值少于1/25的交易;
		}
		record(_to,_value);//记录团队组员账户的收币时间与初始额度
		}
		
		if(_from==simu){//记录私募投资人账户的收币时间与初始额度
			record(_to,_value);
		}
		if(time[_from]>0){//判断发起交易的是否为投资人或组员账户
			judge(_value,_from);//判断发起的交易是否满足时间限制
		}
		
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;//接收账户增加token数量_value
        balances[_from] -= _value; //支出账户_from减去token数量_value
        allowed[_from][msg.sender] -= _value;//消息发送者可以从账户_from中转出的数量减少_value
        Transfer(_from, _to, _value);//触发转币交易事件
        return true;
    }
	function record(address iniadr,uint256 account)private{
		time[iniadr]=now;//记录转出账户与时间的映射关系.
		init[iniadr]=account;//记录转出账户的初始额.
	}
	function judge(uint256 value,address addr)private constant returns (bool power){//代币权限
		
			uint256 timeTemp=(now-time[addr])/60/60;//小时
		if(timeTemp<1&&(balances[addr]-value<init[addr]/5*4)){//第一阶段里时间不允许账户额度减转账值少于初始资产4/5的交易;
			return false;
		}
		if(timeTemp<2&&timeTemp>=1&&(balances[addr]-value<init[addr]/5*3)){
			return false;//第二阶段不允许时间大于1小时且小于2小时，账户额度减转账值少于初始资产3/5的交易;
		}
		if(timeTemp<3&&timeTemp>=2&&(balances[addr]-value<init[addr]/5*2)){
			return false;//第三阶段不允许时间大于2小时且小于3小时，账户额度减转账值少于初始资产2/5的交易;
		}
		if(timeTemp<4&&timeTemp>=3&&(balances[addr]-value<init[addr]/5)){
			return false;//第四阶段不允许时间大于3小时且小于4小时，账户额度减转账值少于初始资产1/5的交易;
		}
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
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
	mapping (address => uint256) time;//账户->收款时间
	mapping (address => uint256) init;//账户初始额度
}