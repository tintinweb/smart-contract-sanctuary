pragma solidity ^0.4.16;
contract moduleTokenInterface{
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed a_owner, address indexed _spender, uint256 _value);
    event OwnerChang(address indexed _old,address indexed _new,uint256 _coin_change);
	event adminUsrChange(address usrAddr,address changeBy,bool isAdded);
	event onAdminTransfer(address to,uint256 value);
}

contract moduleToken is moduleTokenInterface {
    
    struct transferPlanInfo{
        uint256 transferValidValue;
        bool isInfoValid;
    }
    
    struct ethPlanInfo{
	    uint256 ethNum;
	    uint256 coinNum;
	    bool isValid;
	}
	
	//管理员之一发起一个转账操作，需要多人批准时采用这个数据结构
	struct transferEthAgreement{
		//要哪些人签署
	    mapping(address=>bool) signUsrList;		
		
		//已经签署的人数
		uint32 signedUsrCount;
		
		//要求转出的eth数量
	    uint256 transferEthInWei;
		
		//转往哪里
		address to;
		
		//当前转账要求的发起人
		address infoOwner;
		
		//当前记录是否有效(必须123456789)
	    uint32 magic;
	    
	    //是否生效了
	    bool isValid;
	}
	
	

    string public name;                   //名称，例如"My test token"
    uint8 public decimals;               //返回token使用的小数点后几位。比如如果设置为3，就是支持0.001表示.
    string public symbol;               //token简称,like MTT
    address public owner;
    
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
	
	//是否允许直接接受eth而不返回cot
	bool public canRecvEthDirect=false;
    
    
    //以下为本代币协议特殊逻辑所需的相关变
    //
    
    //币的价格，为0时则花钱按价格购买的逻辑不生效   
	uint256 public coinPriceInWei;
	
	//在列表里的人转出代币必须遵守规定的时间、数量限制(比如实现代币定时解冻)
	mapping(address=>transferPlanInfo) public transferPlanList;
	
	//指定的人按指定的以太币数量、代币数量购买代币，不按价格逻辑购买（比如天使轮募资）
	//否则按价格相关逻辑处理购买代币的请求
	mapping(address => ethPlanInfo) public ethPlanList;
	
	uint public blockTime=block.timestamp;
    
    bool public isTransPaused=true;//为true时禁止转账 
    
     //实现多管理员相关的变量  
    struct adminUsrInfo{
        bool isValid;
	    string userName;
		string descInfo;
    }
    mapping(address=>adminUsrInfo) public adminOwners; //管理员组
    bool public isAdminOwnersValid;
    uint32 public adminUsrCount;//有效的管理员用户数
    mapping(uint256=>transferEthAgreement) public transferEthAgreementList;

    function moduleToken(
        uint256 _initialAmount,
        uint8 _decimalUnits) public 
    {
        owner=msg.sender;//记录合约的owner
		if(_initialAmount<=0){
		    totalSupply = 100000000000;   // 设置初始总量
		    balances[owner]=100000000000;
		}else{
		    totalSupply = _initialAmount;   // 设置初始总量
		    balances[owner]=_initialAmount;
		}
		if(_decimalUnits<=0){
		    decimals=2;
		}else{
		    decimals = _decimalUnits;
		}
        name = "CareerOn Token"; 
        symbol = "COT";
    }
    
    function changeContractName(string _newName,string _newSymbol) public {
        require(msg.sender==owner || adminOwners[msg.sender].isValid);
        name=_newName;
        symbol=_newSymbol;
    }
    
    
    function transfer(
        address _to, 
        uint256 _value) public returns (bool success) 
    {
        if(isTransPaused){
            emit Transfer(msg.sender, _to, 0);//触发转币交易事件
            revert();
            return;
        }
        //默认totalSupply 不会超过最大值 (2^256 - 1).
        //如果随着时间的推移将会有新的token生成，则可以用下面这句避免溢出的异常
		if(_to==address(this)){
			emit Transfer(msg.sender, _to, 0);//触发转币交易事件
            revert();
            return;
		}
		if(balances[msg.sender] < _value || 
			balances[_to] + _value <= balances[_to])
		{
			emit Transfer(msg.sender, _to, 0);//触发转币交易事件
            revert();
            return;
		}
        if(transferPlanList[msg.sender].isInfoValid && transferPlanList[msg.sender].transferValidValue<_value)
		{
			emit Transfer(msg.sender, _to, 0);//触发转币交易事件
            revert();
            return;
		}
        balances[msg.sender] -= _value;//从消息发送者账户中减去token数量_value
        balances[_to] += _value;//往接收账户增加token数量_value
        if(transferPlanList[msg.sender].isInfoValid){
            transferPlanList[msg.sender].transferValidValue -=_value;
        }
        emit Transfer(msg.sender, _to, _value);//触发转币交易事件
        return true;
    }


    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value) public returns (bool success) 
    {
        if(isTransPaused){
            emit Transfer(_from, _to, 0);//触发转币交易事件
            revert();
            return;
        }
		if(_to==address(this)){
			emit Transfer(_from, _to, 0);//触发转币交易事件
            revert();
            return;
		}
        if(balances[_from] < _value ||
			allowed[_from][msg.sender] < _value)
		{
			emit Transfer(_from, _to, 0);//触发转币交易事件
            revert();
            return;
		}
        if(transferPlanList[_from].isInfoValid && transferPlanList[_from].transferValidValue<_value)
		{
			emit Transfer(_from, _to, 0);//触发转币交易事件
            revert();
            return;
		}
        balances[_to] += _value;//接收账户增加token数量_value
        balances[_from] -= _value; //支出账户_from减去token数量_value
        allowed[_from][msg.sender] -= _value;//消息发送者可以从账户_from中转出的数量减少_value
        if(transferPlanList[_from].isInfoValid){
            transferPlanList[_from].transferValidValue -=_value;
        }
        emit Transfer(_from, _to, _value);//触发转币交易事件
        return true;
    }
    
    function balanceOf(address accountAddr) public constant returns (uint256 balance) {
        return balances[accountAddr];
    }


    function approve(address _spender, uint256 _value) public returns (bool success) 
    { 
        require(msg.sender!=_spender && _value>0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(
        address _owner, 
        address _spender) public constant returns (uint256 remaining) 
    {
        return allowed[_owner][_spender];//允许_spender从_owner中转出的token数
    }
	
	//以下为本代币协议的特殊逻辑
	
	//转移协议所有权并将附带的代币一并转移过去
	function changeOwner(address newOwner) public{
        require(msg.sender==owner && msg.sender!=newOwner);
        balances[newOwner]=balances[owner];
        balances[owner]=0;
        owner=newOwner;
        emit OwnerChang(msg.sender,newOwner,balances[owner]);//触发合约所有权的转移事件
    }
    
    function setPauseStatus(bool isPaused)public{
        if(msg.sender!=owner && !adminOwners[msg.sender].isValid){
            revert();
            return;
        }
        isTransPaused=isPaused;
    }
    
    //设置转账限制，比如冻结什么的
	function setTransferPlan(address addr,
	                        uint256 allowedMaxValue,
	                        bool isValid) public
	{
	    if(msg.sender!=owner && !adminOwners[msg.sender].isValid){
	        revert();
	        return ;
	    }
	    transferPlanList[addr].isInfoValid=isValid;
	    if(transferPlanList[addr].isInfoValid){
	        transferPlanList[addr].transferValidValue=allowedMaxValue;
	    }
	}
    
    //把本代币协议账户下的eth转到指定账户
	function TransferEthToAddr(address _to,uint256 _value)public payable{
        require(msg.sender==owner && !isAdminOwnersValid);
        _to.transfer(_value);
    }
    
    function createTransferAgreement(uint256 agreeMentId,
                                      uint256 transferEthInWei,
                                      address to) public {
        require(msg.sender==tx.origin);
        require(adminOwners[msg.sender].isValid && 
        transferEthAgreementList[agreeMentId].magic!=123456789 && 
        transferEthAgreementList[agreeMentId].magic!=987654321);
        transferEthAgreementList[agreeMentId].magic=123456789;
        transferEthAgreementList[agreeMentId].infoOwner=msg.sender;
        transferEthAgreementList[agreeMentId].transferEthInWei=transferEthInWei;
        transferEthAgreementList[agreeMentId].to=to;
        transferEthAgreementList[agreeMentId].isValid=true;
        transferEthAgreementList[agreeMentId].signUsrList[msg.sender]=true;
        transferEthAgreementList[agreeMentId].signedUsrCount=1;
        
    }
	
	function disableTransferAgreement(uint256 agreeMentId) public {
	    require(msg.sender==tx.origin);
		require(transferEthAgreementList[agreeMentId].infoOwner==msg.sender &&
			    transferEthAgreementList[agreeMentId].magic==123456789);
		transferEthAgreementList[agreeMentId].isValid=false;
		transferEthAgreementList[agreeMentId].magic=987654321;
	}
	
	function sign(uint256 agreeMentId,address to,uint256 transferEthInWei) public payable{
	    require(tx.origin==msg.sender);
		require(transferEthAgreementList[agreeMentId].magic==123456789 &&
		transferEthAgreementList[agreeMentId].isValid &&
		transferEthAgreementList[agreeMentId].transferEthInWei==transferEthInWei &&
		transferEthAgreementList[agreeMentId].to==to &&
		adminOwners[msg.sender].isValid &&
		transferEthAgreementList[agreeMentId].signUsrList[msg.sender]!=true &&
		adminUsrCount>=2
		);
		transferEthAgreementList[agreeMentId].signUsrList[msg.sender]=true;
		transferEthAgreementList[agreeMentId].signedUsrCount++;
		
		if(transferEthAgreementList[agreeMentId].signedUsrCount<=adminUsrCount/2)
		{
			return;
		}
		to.transfer(transferEthInWei);
		transferEthAgreementList[agreeMentId].isValid=false;
		transferEthAgreementList[agreeMentId].magic=987654321;
		emit onAdminTransfer(to,transferEthInWei);
		return;
	}
	
	struct needToAddAdminInfo{
		uint256 magic;
		mapping(address=>uint256) postedPeople;
		uint32 postedCount;
	}
	mapping(address=>needToAddAdminInfo) public needToAddAdminInfoList;
	function addAdminOwners(address usrAddr,
					  string userName,
					  string descInfo)public 
	{
		require(msg.sender==tx.origin);
		needToAddAdminInfo memory info;
		//不是管理员也不是owner，则禁止任何操作
		if(!adminOwners[msg.sender].isValid && owner!=msg.sender){
			revert();
			return;
		}
		//任何情况,owner地址不可以被添加到管理员组
		if(usrAddr==owner){
			revert();
			return;
		}
		
		//已经在管理员组的不可以被添加
		if(adminOwners[usrAddr].isValid){
			revert();
			return;
		}
		//不允许添加自己到管理员组
		if(usrAddr==msg.sender){
			revert();
			return;
		}
		//管理员不到2人时，owner可以至多添加2人到管理员
		if(adminUsrCount<2){
			if(msg.sender!=owner){
				revert();
				return;
			}
			adminOwners[usrAddr].isValid=true;
			adminOwners[usrAddr].userName=userName;
			adminOwners[usrAddr].descInfo=descInfo;
			adminUsrCount++;
			if(adminUsrCount>=2) isAdminOwnersValid=true;
			emit adminUsrChange(usrAddr,msg.sender,true);
			return;
		}
		//管理员大于等于2人时，owner添加管理员需要得到过半数管理员的同意，而且至少必须是2
		if(msg.sender==owner){
			//某个用户已经被要求添加到管理员组，owner此时是没有投票权的
			if(needToAddAdminInfoList[usrAddr].magic==123456789){
				revert();
				return;
			}
			//允许owner把某个人添加到要求进入管理员组的列表里，后续由其它管理员投票
			info.magic=123456789;
			info.postedCount=0;
			needToAddAdminInfoList[usrAddr]=info;
			return;
			
		}//管理员大于等于2人时，owner添加新的管理员，必须过半数管理员同意且至少是2
		else if(adminOwners[msg.sender].isValid)
		{
			//管理员只能投票确认添加管理员，不能直接添加管理员
			if(needToAddAdminInfoList[usrAddr].magic!=123456789){
				revert();
				return;
			}
			//已经投过票的管理员不允许再投			
			if(needToAddAdminInfoList[usrAddr].postedPeople[msg.sender]==123456789){
				revert();
				return;
			}
			needToAddAdminInfoList[usrAddr].postedCount++;
			needToAddAdminInfoList[usrAddr].postedPeople[msg.sender]=123456789;
			if(adminUsrCount>=2 && 
			   needToAddAdminInfoList[usrAddr].postedCount>adminUsrCount/2){
				adminOwners[usrAddr].userName=userName;
				adminOwners[usrAddr].descInfo=descInfo;
				adminOwners[usrAddr].isValid=true;
				needToAddAdminInfoList[usrAddr]=info;
				adminUsrCount++;
				emit adminUsrChange(usrAddr,msg.sender,true);
				return;
			}
			
		}else{
			return revert();//其它情况一律不可以添加管理员
		}		
	}
	struct needDelFromAdminInfo{
		uint256 magic;
		mapping(address=>uint256) postedPeople;
		uint32 postedCount;
	}
	mapping(address=>needDelFromAdminInfo) public needDelFromAdminInfoList;
	function delAdminUsrs(address usrAddr) public {
	    require(msg.sender==tx.origin);
	    //不是管理员也不是owner，则禁止任何操作
		if(!adminOwners[msg.sender].isValid && owner!=msg.sender){
			revert();
			return;
		}
		needDelFromAdminInfo memory info;
		//尚不是管理员，无需删除
		if(!adminOwners[usrAddr].isValid){
			revert();
			return;
		}
		//当前管理员数小于4的话不让再删用户
		if(adminUsrCount<4){
			revert();
			return;
		}
		//当前管理员数是奇数时不让删用户
		if(adminUsrCount%2!=0){
			revert();
			return;
		}
		//不允许把自己退出管理员
		if(usrAddr==msg.sender){
			revert();
			return;
		}
		if(msg.sender==owner){
			//owner没有权限确认删除管理员
			if(needDelFromAdminInfoList[usrAddr].magic==123456789){
				revert();
				return;
			}
			//owner可以提议删除管理员，但是需要管理员过半数同意
			info.magic=123456789;
			info.postedCount=0;
			needDelFromAdminInfoList[usrAddr]=info;
			return;
		}
		
		//管理员确认删除用户
		
		//管理员只有权限确认删除
		if(needDelFromAdminInfoList[usrAddr].magic!=123456789){
			revert();
			return;
		}
		//已经投过票的不允许再投
		if(needDelFromAdminInfoList[usrAddr].postedPeople[msg.sender]==123456789){
			revert();
			return;
		}
		needDelFromAdminInfoList[usrAddr].postedCount++;
		needDelFromAdminInfoList[usrAddr].postedPeople[msg.sender]=123456789;
		//同意的人数尚未超过一半则直接返回
		if(needDelFromAdminInfoList[usrAddr].postedCount<=adminUsrCount/2){
			return;
		}
		//同意的人数超过一半
		adminOwners[usrAddr].isValid=false;
		if(adminUsrCount>=1) adminUsrCount--;
		if(adminUsrCount<=1) isAdminOwnersValid=false;
		needDelFromAdminInfoList[usrAddr]=info;
		emit adminUsrChange(usrAddr,msg.sender,false);
	}
	
	//设置指定人按固定eth数、固定代币数购买代币，比如天使轮募资
	function setEthPlan(address addr,uint256 _ethNum,uint256 _coinNum,bool _isValid) public {
	    require(msg.sender==owner &&
	        _ethNum>=0 &&
	        _coinNum>=0 &&
	        (_ethNum + _coinNum)>0 &&
	        _coinNum<=balances[owner]);
	    ethPlanList[addr].isValid=_isValid;
	    if(ethPlanList[addr].isValid){
	        ethPlanList[addr].ethNum=_ethNum;
	        ethPlanList[addr].coinNum=_coinNum;
	    }
	}
	
	//设置代币价格(Wei)
	function setCoinPrice(uint256 newPriceInWei) public returns(uint256 oldPriceInWei){
	    require(msg.sender==owner);
	    uint256 _old=coinPriceInWei;
	    coinPriceInWei=newPriceInWei;
	    return _old;
	}
	
	function balanceInWei() public constant returns(uint256 nowBalanceInWei){
	    return address(this).balance;
	}
	
	function changeRecvEthStatus(bool _canRecvEthDirect) public{
		if(msg.sender!=owner){
			revert();
			return;
		}
		canRecvEthDirect=_canRecvEthDirect;
	}
	
	//
	
	//回退函数
    //合约账户收到eth时会被调用
    //任何异常时，这个函数也会被调用
	//若有零头不找零，避免被DDOS攻击
    function () public payable {
		if(canRecvEthDirect){
			return;
		}
        if(ethPlanList[msg.sender].isValid==true &&
            msg.value>=ethPlanList[msg.sender].ethNum &&
            ethPlanList[msg.sender].coinNum>=0 &&
            ethPlanList[msg.sender].coinNum<=balances[owner]){
                ethPlanList[msg.sender].isValid=false;
                balances[owner] -= ethPlanList[msg.sender].coinNum;//从消息发送者账户中减去token数量_value
                balances[msg.sender] += ethPlanList[msg.sender].coinNum;//往接收账户增加token数量_value
		        emit Transfer(this, msg.sender, ethPlanList[msg.sender].coinNum);//触发转币交易事件
        }else if(!ethPlanList[msg.sender].isValid &&
            coinPriceInWei>0 &&
            msg.value/coinPriceInWei<=balances[owner] &&
            msg.value/coinPriceInWei+balances[msg.sender]>balances[msg.sender]){
            uint256 buyCount=msg.value/coinPriceInWei;
            balances[owner] -=buyCount;
            balances[msg.sender] +=buyCount;
            emit Transfer(this, msg.sender, buyCount);//触发转币交易事件
               
        }else{
            revert();
        }
    }
}