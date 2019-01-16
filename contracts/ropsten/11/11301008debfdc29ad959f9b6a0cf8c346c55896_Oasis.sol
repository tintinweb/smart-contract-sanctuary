pragma solidity ^ 0.4.25;
contract Oasis{
	string public symbol;
	string public name;
	uint8 public decimals;
	uint _totalSupply;
	uint basekeynum;//4500
	uint basekeysub;//500
	uint basekeylast;//2000
    uint startprice;
    uint startbasekeynum;//4500
    uint startbasekeylast;//2000
	address owner;
	bool public actived;
	uint public keyprice;//钥匙的价格
	uint public keysid;//当前钥匙的最大id
	uint public onceOuttime;
	uint8 public per;//用户每日静态的释放比例
	uint public allprize;
	uint public allprizeused;
	
	uint[] public mans;//用户上线人数的数组
	uint[] public pers;//用户上线分额的比例数组
	uint[] public prizeper;//用户每日静态的释放比例
	uint[] public prizelevelsuns;//用户上线人数的数组
	uint[] public prizelevelmans;//用户上线人数的比例数组
	uint[] public prizelevelsunsday;//用户上线人数的数组
	uint[] public prizelevelmansday;//用户上线人数的比例数组
	uint[] public prizeactivetime;
	
	address[] public mansdata;
	uint[] public moneydata;
	uint[] public timedata;
	uint public pubper;
	uint public subper;
	uint public luckyper;
	uint public lastmoney;
	uint public lastper;
	uint public lasttime;
	uint public sellkeyper;
	
	bool public isend;
	uint public tags;
	uint public opentime;
	
	uint public runper;
	uint public sellper;
	uint public sysday;
	uint public cksysday;

	mapping(address => uint) balances;//用户的钥匙数量
	mapping(address => uint) systemtag;//用户的系统标志 
	mapping(address => uint) eths;//用户的资产数量
	mapping(address => uint) tzs;//用户的资产数量
	mapping(address => uint) usereths;//用户的总投资
	mapping(address => uint) userethsused;//用户的总投资
	mapping(address => uint) runs;//用户的动态奖励
	mapping(address => uint) used;//用户已使用的资产
	mapping(address => uint) runused;//用户已使用的动态
	mapping(address => mapping(address => uint)) allowed;//授权金额
	/* 冻结账户 */
	mapping(address => bool) public frozenAccount;
	//释放 
	mapping(address => uint[]) public mycantime; //时间
	mapping(address => uint[]) public mycanmoney; //金额
	//上线释放
	mapping(address => uint[]) public myruntime; //时间
	mapping(address => uint[]) public myrunmoney; //金额
	//上家地址
	mapping(address => address) public fromaddr;
	//一代数组
	mapping(address => address[]) public mysuns;
	//2代数组
	mapping(address => address[]) public mysecond;
	//3代数组
	mapping(address => address[]) public mythird;
	//all 3代数组days moeny
	//mapping(address => mapping(uint => uint)) public mysunsdayget;
	//all 3代数组days moeny
	mapping(address => mapping(uint => uint)) public mysunsdaynum;
	//current day prize
	mapping(address => mapping(uint => uint)) public myprizedayget;
	//mapping(address => mapping(uint => uint)) public myprizedaygetdata;
	mapping(uint => address[]) public userlevels;
	mapping(uint => mapping(uint => uint)) public userlevelsnum;
	//管理员帐号
	mapping(address => bool) public admins;
	//用户钥匙id
	mapping(address => uint) public mykeysid;
	//与用户钥匙id对应
	mapping(uint => address) public myidkeys;
	mapping(address => uint) public mykeyeths;
	mapping(address => uint) public mykeyethsused;
	
	//all once day get all
	mapping(uint => uint) public daysgeteths;
	mapping(uint => uint) public dayseths;
	//user once day pay
	mapping(address => mapping(uint => uint)) public daysusereths;
	
	mapping(uint => uint)  public ethnum;//用户总资产
	mapping(uint => uint)  public sysethnum;//系统总eth
	mapping(uint => uint)  public userethnum;//用户总eth
	mapping(uint => uint)  public userethnumused;//用户总eth
	mapping(uint => uint)  public syskeynum;//系统总key

	/* 通知 */
	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
	event FrozenFunds(address target, bool frozen);
	modifier onlySystemStart() {
        require(actived == true);
	    //require(isend == false);
	    require(tags == systemtag[msg.sender]);
	    require(!frozenAccount[msg.sender]);
        _;
    }
	// ------------------------------------------------------------------------
	// Constructor
	// ------------------------------------------------------------------------
	constructor() public {
		symbol = "OASIS";
		name = "Oasis";
		decimals = 18;
		_totalSupply = 50000000 ether;
	
		actived = true;
		tags = 0;
		ethnum[0] = 0;
		sysethnum[0] = 0;
		userethnum[0] = 0;
		userethnumused[0] = 0;
		//onceOuttime = 16 hours; //增量的时间 正式 
		onceOuttime = 20 seconds;//test
        keysid = 55555;
        
        //basekeynum = 2000 ether;
        //basekeysub = 500 ether;
        //basekeylast = 2500 ether;
        //startbasekeynum = 2000 ether;
        //startbasekeylast = 2500 ether;
        basekeynum = 20 ether;//test
        basekeysub = 5 ether;//test
        basekeylast = 25 ether;//test
        startbasekeynum = 20 ether;//test
        startbasekeylast = 25 ether;//test
        allprize = 0;
		balances[this] = _totalSupply;
		per = 15;
		runper = 20;
		mans = [2,4,6];
		pers = [20,15,10];
		prizeper = [2,2,2];
		//prizelevelsuns = [20,30,50];
		//prizelevelmans = [100,300,800];
		//prizelevelsunsday = [2,4,6];
		//prizelevelmansday = [10 ether,30 ether,50 ether];
		
		prizelevelsuns = [2,3,5];//test
		prizelevelmans = [3,5,8];//test
		prizelevelsunsday = [1,2,3];//test
		prizelevelmansday = [1 ether,3 ether,5 ether];//test
		
		prizeactivetime = [0,0,0];
		pubper = 2;
		subper = 120;
		luckyper = 5;
		lastmoney = 0;
		lastper = 2;
		//lasttime = 8 hours;
		lasttime = 300 seconds;//test
		//sysday = 1 days;
		//cksysday = 8 hours;
		sysday = 1 hours; //test
		cksysday = 0 seconds;//test
		
		keyprice = 0.01 ether;
		startprice = 0.01 ether;
		//keyprice = 0.0001 ether;//test
		sellkeyper = 30;
		sellper = 10;
		isend = false;
		opentime = now;
		//userethnum = 0;
		//sysethnum = 0;
		//balances[owner] = _totalSupply;
		owner = msg.sender;
		emit Transfer(address(0), this, _totalSupply);

	}

	/* 获取用户金额 */
	function balanceOf(address tokenOwner) public view returns(uint balance) {
		return balances[tokenOwner];
	}
	/*
	function getper() public view returns(uint onceOuttimes,uint perss,uint runpers,uint pubpers,uint subpers,uint luckypers,uint lastpers,uint sellkeypers,uint sellpers,uint lasttimes,uint sysdays,uint cksysdays) {
	    onceOuttimes = onceOuttime;//0
	    perss = per;//1
	    runpers = runper;//2
	    pubpers = pubper;//3
	    subpers = subper;//4
	    luckypers = luckyper;//5
	    lastpers = lastper;//6
	    sellkeypers = sellkeyper;//7
	    sellpers = sellper;//8
	    lasttimes = lasttime;//9
	    sysdays = sysday;//10
	    cksysdays = cksysday;//11
	    
	}*/
	function indexshow(address user) public view returns(uint totaleths,uint lttime,uint ltmoney,address ltaddr,uint myeths,uint mycans,uint dayuserget,uint dayusereth,uint keyprices,uint mykeynum,uint ltkeynum,uint mykeyid){
	    totaleths = userethnum[tags];//0
	    lttime = timedata[timedata.length - 1];//1
	    ltmoney = moneydata[moneydata.length - 1];//2
	    ltaddr = mansdata[mansdata.length - 1];//3
	    myeths = tzs[user];//4
	    mycans = getcanuse(user);//5
	    uint d = gettoday();
	    dayuserget = myprizedayget[user][d];//.6
	    dayusereth = daysusereths[user][d];//7
	    keyprices = keyprice;//8
	    mykeynum = balanceOf(user);//9
	    ltkeynum = leftnum();//10
	    mykeyid = mykeysid[user];//11
	    
	}
	function prizeshow(address user) public view returns(uint totalgold,uint lttime,uint levelid,uint man1,uint man2,uint man3,uint len1,uint len2,uint len3,uint nl1,uint nl2,uint nl3){
	    totalgold = allprize - allprizeused;//0
	    lttime = timedata[timedata.length - 1];//1
	    levelid = getlevel(user);//2
	    man1 = mysuns[user].length;//3
	    man2 = mysuns[user].length;//4
	    man3 = mysuns[user].length;//5
	    len1 = userlevels[1].length;//6
	    len2 = userlevels[2].length;//7
	    len3 = userlevels[3].length;//8
	    uint d = gettoday();
	    nl1 = userlevelsnum[1][d];//9
	    nl2 = userlevelsnum[2][d];//10
	    nl3 = userlevelsnum[3][d];//11
	}
	
	function gettags(address addr) public view returns(uint t) {
	    t = systemtag[addr];
	}
	/*
	 * 添加金额，为了统计用户的进出
	 */
	function addmoney(address _addr, uint256 _money, uint _day) private returns(bool){
		eths[_addr] += _money;
		mycanmoney[_addr].push(_money);
		mycantime[_addr].push((now - (_day * 86400)));

	}
	/*
	 * 用户金额减少时的触发
	 * @param {Object} address
	 */
	function reducemoney(address _addr, uint256 _money) private returns(bool){
	    if(eths[_addr] >= _money && tzs[_addr] >= _money) {
	        used[_addr] += _money;
    		eths[_addr] -= _money;
    		tzs[_addr] -= _money;
    		return(true);
	    }else{
	        return(false);
	    }
		
	}
	/*
	 * 添加run金额，为了统计用户的进出
	 */
	function addrunmoney(address _addr, uint256 _money, uint _day) private {
		uint256 _days = _day * (1 days);
		uint256 _now = now - _days;
		runs[_addr] += _money;
		myrunmoney[_addr].push(_money);
		myruntime[_addr].push(_now);

	}
	/*
	 * 用户金额减少时的触发
	 * @param {Object} address
	 */
	function reducerunmoney(address _addr, uint256 _money) private {
		runs[_addr] -= _money;
		runused[_addr] += _money;
	}
	function geteths(address addr) public view returns(uint) {
	    return(eths[addr]);
	}
	function getruns(address addr) public view returns(uint) {
	    return(runs[addr]);
	}
	/*
	 * 获取用户的可用金额
	 * @param {Object} address
	 */
	function getcanuse(address tokenOwner) public view returns(uint) {
		uint256 _now = now;
		uint256 _left = 0;
		for(uint256 i = 0; i < mycantime[tokenOwner].length; i++) {
			uint256 stime = mycantime[tokenOwner][i];
			uint256 smoney = mycanmoney[tokenOwner][i];
			uint256 lefttimes = _now - stime;
			if(lefttimes >= onceOuttime) {
				uint256 leftpers = lefttimes / onceOuttime;
				if(leftpers > 100) {
					leftpers = 100;
				}
				_left = smoney * leftpers / 100 + _left;
			}
		}
		if(_left < used[tokenOwner]) {
			return(0);
		}
		if(_left > eths[tokenOwner]) {
			return(eths[tokenOwner]);
		}
		_left = _left - used[tokenOwner];
		
		return(_left);
	}
	/*
	 * 获取用户的可用金额
	 * @param {Object} address
	 */
	function getcanuserun(address tokenOwner) public view returns(uint) {
		uint256 _now = now;
		uint256 _left = 0;
		for(uint256 i = 0; i < myruntime[tokenOwner].length; i++) {
			uint256 stime = myruntime[tokenOwner][i];
			uint256 smoney = myrunmoney[tokenOwner][i];
			uint256 lefttimes = _now - stime;
			if(lefttimes >= onceOuttime) {
				uint256 leftpers = lefttimes / onceOuttime;
				if(leftpers > 100) {
					leftpers = 100;
				}
				_left = smoney * leftpers / 100 + _left;
			}
		}
		if(_left < runused[tokenOwner]) {
			return(0);
		}
		if(_left > runs[tokenOwner]) {
			return(runs[tokenOwner]);
		}
		_left = _left - runused[tokenOwner];
		
		
		return(_left);
	}

	/*
	 * 用户转账
	 * @param {Object} address
	 */
	function _transfer(address from, address to, uint tokens) private{
	    
		require(!frozenAccount[from]);
		require(!frozenAccount[to]);
		require(actived == true);
		//
		require(from != to);
		//如果用户没有上家
		// 防止转移到0x0， 用burn代替这个功能
        require(to != 0x0);
        // 检测发送者是否有足够的资金
        require(balances[from] >= tokens);
        // 检查是否溢出（数据类型的溢出）
        require(balances[to] + tokens > balances[to]);
        // 将此保存为将来的断言， 函数最后会有一个检验
        uint previousBalances = balances[from] + balances[to];
        // 减少发送者资产
        balances[from] -= tokens;
        // 增加接收者的资产
        balances[to] += tokens;
        // 断言检测， 不应该为错
        assert(balances[from] + balances[to] == previousBalances);
        
		emit Transfer(from, to, tokens);
	}
	/* 传递tokens */
    function transfer(address _to, uint256 _value) onlySystemStart() public returns(bool){
        _transfer(msg.sender, _to, _value);
        mykeyethsused[msg.sender] += _value;
        return(true);
    }
    //激活钥匙
    function activekey() onlySystemStart() public returns(bool) {
	    address addr = msg.sender;
        uint keyval = 1 ether;
        require(balances[addr] >= keyval);
        require(mykeysid[addr] < 1);
        //require(fromaddr[addr] == address(0));
        keysid = keysid + 1;
	    mykeysid[addr] = keysid;
	    myidkeys[keysid] = addr;
	    
	    balances[addr] -= keyval;
	    balances[owner] += keyval;
	    emit Transfer(addr, owner, keyval);
	    
	    //_transfer(addr, owner, keyval);
	    return(true);
	    
    }
	
	/*
	 * 获取上家地址
	 * @param {Object} address
	 */
	function getfrom(address _addr) public view returns(address) {
		return(fromaddr[_addr]);
	}
    function gettopid(address addr) public view returns(uint) {
        address topaddr = fromaddr[addr];
        if(topaddr == address(0)) {
            return(0);
        }
        uint keyid = mykeysid[topaddr];
        if(keyid > 0 && myidkeys[keyid] == topaddr) {
            return(keyid);
        }else{
            return(0);
        }
    }
	function approve(address spender, uint tokens) public returns(bool success) {
	    require(actived == true);
		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		return true;
	}
	/*
	 * 授权转账
	 * @param {Object} address
	 */
	function transferFrom(address from, address to, uint tokens) public returns(bool success) {
		require(actived == true);
		require(!frozenAccount[from]);
		require(!frozenAccount[to]);
		balances[from] -= tokens;
		allowed[from][msg.sender] -= tokens;
		balances[to] += tokens;
		emit Transfer(from, to, tokens);
		return true;
	}

	/*
	 * 获取授权信息
	 * @param {Object} address
	 */
	function allowance(address tokenOwner, address spender) public view returns(uint remaining) {
		return allowed[tokenOwner][spender];
	}

	

	/// 冻结 or 解冻账户
	function freezeAccount(address target, bool freeze) public {
		require(admins[msg.sender] == true);
		frozenAccount[target] = freeze;
		emit FrozenFunds(target, freeze);
	}
	/*
	 * 设置管理员
	 * @param {Object} address
	 */
	function admAccount(address target, bool freeze) public {
	    require(msg.sender == owner);
		admins[target] = freeze;
	}
	
	/*
	 * 设置是否开启
	 * @param {Object} bool
	 */
	function setactive(bool t) public {
	    require(msg.sender == owner);
		actived = t;
	}

	/*
	 * 向账户拨发资金
	 * @param {Object} address
	 */
	function mintToken(address target, uint256 mintedAmount) public{
	    require(msg.sender == owner);
		require(!frozenAccount[target]);
		require(actived == true);
		balances[target] += mintedAmount;
		balances[this] -= mintedAmount;
		emit Transfer(this, target, mintedAmount);
	}
	
	
	function getmykeyid(address addr) public view returns(uint ky) {
	    ky = mykeysid[addr];
	}
	function getyestoday() public view returns(uint d) {
	    uint today = gettoday();
	    d = today - sysday;
	}
	
	function gettoday() public view returns(uint d) {
	    uint n = now;
	    d = n - n%sysday - cksysday;
	}
	
	
	function getlevel(address addr) public view returns(uint) {
	    uint num1 = mysuns[addr].length;
	    uint num2 = mysecond[addr].length;
	    uint num3 = mythird[addr].length;
	    uint nums = num1 + num2 + num3;
	    if(num1 >= prizelevelsuns[2] && nums >= prizelevelmans[2]) {
	        return(3);
	    }
	    if(num1 >= prizelevelsuns[1] && nums >= prizelevelmans[1]) {
	        return(2);
	    }
	    if(num1 >= prizelevelsuns[0] && nums >= prizelevelmans[0]) {
	        return(1);
	    }
	    return(0);
	}
	
	function gettruelevel(uint n, uint m) public view returns(uint) {
	    if(n >= prizelevelsunsday[2] && m >= prizelevelmansday[2]) {
	        return(2);
	    }
	    if(n >= prizelevelsunsday[1] && m >= prizelevelmansday[1]) {
	        return(1);
	    }
	    if(n >= prizelevelsunsday[0] && m >= prizelevelmansday[0]) {
	        return(0);
	    }
	    
	}
	function getprize() onlySystemStart() public returns(bool) {
	    uint d = getyestoday();
	    address user = msg.sender;
	    uint level = getlevel(user);
	   
	    uint money = myprizedayget[user][d];
	    uint mymans = mysunsdaynum[user][d];
	    if(level > 0 && money > 0) {
	        uint p = level - 1;
	        uint activedtime = prizeactivetime[p];
	        require(activedtime > 0);
	        require(activedtime < now);
	        uint allmoney = allprize - allprizeused;
	        if(now - activedtime > sysday) {
	            p = gettruelevel(mymans, money);
	        }
	        uint ps = (allmoney*prizeper[p]/100)/userlevels[level].length;
	        //eths[user] = eths[user].add(ps);
	        addmoney(user, ps, 100);
	        myprizedayget[user][d] -= money;
	        allprizeused += money;
	    }
	}
	function setactivelevel(uint level) private returns(bool) {
	    uint t = prizeactivetime[level];
	    if(t < 1) {
	        prizeactivetime[level] = now + sysday;
	    }
	    return(true);
	}
	function getactiveleveltime(uint level) public view returns(uint t) {
	    t = prizeactivetime[level];
	}
	function setuserlevel(address user) onlySystemStart() public returns(bool) {
	    uint level = getlevel(user);
	    bool has = false;
	    uint i = 0;
	    uint d = gettoday();
	    if(level == 1) {
	        
	        for(; i < userlevels[1].length; i++) {
	            if(userlevels[1][i] == user) {
	                has = true;
	            }
	        }
	        if(has == false) {
	            userlevels[1].push(user);
	            userlevelsnum[1][d]++;
	            setactivelevel(0);
	            return(true);
	        }
	    }
	    if(level == 2) {
	        i = 0;
	        if(has == true) {
	            for(; i < userlevels[1].length; i++) {
    	            if(userlevels[1][i] == user) {
    	                delete userlevels[1][i];
    	            }
    	        }
    	        userlevels[2].push(user);
    	        userlevelsnum[2][d]++;
    	        setactivelevel(1);
    	        return(true);
	        }else{
	           for(; i < userlevels[2].length; i++) {
    	            if(userlevels[2][i] == user) {
    	                has = true;
    	            }
    	        }
    	        if(has == false) {
    	            userlevels[2].push(user);
    	            userlevelsnum[2][d]++;
    	            setactivelevel(1);
    	            return(true);
    	        }
	        }
	    }
	    if(level == 3) {
	        i = 0;
	        if(has == true) {
	            for(; i < userlevels[2].length; i++) {
    	            if(userlevels[2][i] == user) {
    	                delete userlevels[2][i];
    	            }
    	        }
    	        userlevels[3].push(user);
    	        userlevelsnum[3][d]++;
    	        setactivelevel(2);
    	        return(true);
	        }else{
	           for(; i < userlevels[3].length; i++) {
    	            if(userlevels[3][i] == user) {
    	                has = true;
    	            }
    	        }
    	        if(has == false) {
    	            userlevels[3].push(user);
    	            userlevelsnum[3][d]++;
    	            setactivelevel(2);
    	            return(true);
    	        }
	        }
	    }
	}
	
	function getfromsun(address addr, uint money, uint amount) private returns(bool){
	    address f1 = fromaddr[addr];
	    address f2 = fromaddr[f1];
	    address f3 = fromaddr[f2];
	    uint d = gettoday();
	    if(f1 != address(0) && mysuns[f1].length >= mans[0]) {
	        addrunmoney(f1, ((money*per/1000)*pers[0])/100, 0);
	    	myprizedayget[f1][d] += amount;
	    }
	    if(f2 != address(0) && mysuns[f2].length >= mans[1]) {
	        addrunmoney(f2, ((money*per/1000)*pers[1])/100, 0);
	    	myprizedayget[f2][d] += amount;
	    }
	    if(f3 != address(0) && mysuns[f3].length >= mans[2]) {
	        addrunmoney(f3, ((money*per/1000)*pers[2])/100, 0);
	    	myprizedayget[f3][d] += amount;
	    }
	    
	}
	function setpubprize(uint sendmoney) private returns(bool) {
	    uint len = moneydata.length;
	    if(len > 0) {
	        uint all = 0;
	        uint start = 0;
	        
	        if(len > 10) {
	            start = len - 10;
	        }
	        for(uint i = start; i < len; i++) {
	            all += moneydata[i];
	        }
	        //uint sendmoney = amount*pubper/100;
	        for(; start < len; start++) {
	            addmoney(mansdata[start], sendmoney*moneydata[start]/all, 100);
	        }
	    }
	    return(true);
	}
	function getluckyuser() public view returns(address addr) {
	    uint d = gettoday();
	    uint t = getyestoday();
	    uint maxmoney = 1 ether;
	    for(uint i = 0; i < moneydata.length; i++) {
	        if(timedata[i] > t && timedata[i] < d && moneydata[i] >= maxmoney) {
	            maxmoney = moneydata[i];
	            addr = mansdata[i];
	        }
	    }
	}
	function getluckyprize() onlySystemStart() public returns(bool) {
	    address user = msg.sender;
	    require(user == getluckyuser());
	    uint d = getyestoday();
	    require(daysusereths[user][d] > 0);
	    addmoney(user, dayseths[d]*luckyper/1000, 100);
	}
	
	function runtoeth(uint amount) onlySystemStart() public returns(bool) {
	    address user = msg.sender;
	    uint can = getcanuserun(user);
	    uint kn = balances[user];
	    uint usekey = amount*runper/100;
	    require(usekey <= kn);
	    require(runs[user] >= can);
	    require(can >= amount);
	    
	    //runs[user] = runs[user].sub(amount);
	    reducerunmoney(user, amount);
	    //eths[user] = eths[user].add(amount);
	    addmoney(user, amount, 100);
	    transfer(owner, usekey);
	}
	/*
	
	function testtop2() public view returns(uint s) {
	    uint money = 3 ether;
	    s = (money*per/1000)*pers[0]/100;
	}*/
	/*
	 * 购买
	 */
	function buy(uint keyid) onlySystemStart() public payable returns(bool) {
		address user = msg.sender;
		require(msg.value > 0);

		uint amount = msg.value;
		require(amount >= 1 ether);
		require(usereths[user] <= 100 ether);
		uint money = amount*3;
		uint d = gettoday();
		uint t = getyestoday();
		bool ifadd = false;
		//如果用户没有上家
		if(fromaddr[user] == address(0)) {
		    address topaddr = myidkeys[keyid];
		    if(keyid > 0 && topaddr != address(0) && topaddr != user) {
		        fromaddr[user] = topaddr;
    		    mysuns[topaddr].push(user);
    		    mysunsdaynum[topaddr][d]++;
    		    address top2 = fromaddr[topaddr];
    		    if(top2 != address(0)){
    		        mysecond[top2].push(user);
    		        mysunsdaynum[top2][d]++;
    		    }
    		    address top3 = fromaddr[top2];
    		    if(top3 != address(0)){
    		        mythird[top3].push(user);
    		        mysunsdaynum[top3][d]++;
    		    }
    		    ifadd = true;
		        
		    }
		}else{
		    ifadd = true;
		}
		if(ifadd == true) {
		    money = amount*4;
		}
		if(daysgeteths[t] > 0 && (daysgeteths[d] > (daysgeteths[t]*subper)/100)) {
		    if(ifadd == true) {
    		    money = amount*3;
    		}else{
    		    money = amount*2;
    		}
		}
		
		
		if(ifadd == true) {
		    getfromsun(user, money, amount);
		}
		setpubprize(amount*pubper/100);
		mansdata.push(user);
		moneydata.push(amount);
		timedata.push(now);
		
	    daysgeteths[d] += money;
	    dayseths[d] += amount;
	    sysethnum[tags] += amount;
		userethnum[tags] += amount;
		daysusereths[user][d] += money;
		
		tzs[user] += money;
	    uint ltime = timedata[timedata.length - 1];
	    if(lastmoney > 0 && now - ltime > lasttime) {
	        money += lastmoney*lastper/100;
	        lastmoney = 0;
	    }
		lastmoney += amount;
		ethnum[tags] += money;
		usereths[user] += amount;
		
		addmoney(user, money, 0);
		return(true);
	}
	function keybuy(uint amount) onlySystemStart() public returns(bool) {
	    address user = msg.sender;
	    require(amount > balances[user]);
	    require(amount >= 1 ether);
	    _transfer(user, owner, amount);
	    uint money = amount*(keyprice/1 ether);
	    moneybuy(user, money);
	    return(true);
	}
	function ethbuy(uint amount) onlySystemStart() public returns(bool) {
	    address user = msg.sender;
	    uint canmoney = getcanuse(user);
	    require(canmoney >= amount);
	    require(amount >= 1 ether);
	    //eths[user] = eths[user].sub(amount);
	    require(reducemoney(user, amount) == true);
	    moneybuy(user, amount);
	    return(true);
	}
	function moneybuy(address user,uint amount) private returns(bool) {
		uint money = amount*4;
		uint d = gettoday();
		uint t = getyestoday();
		if(fromaddr[user] == address(0)) {
		    money = amount*3;
		}
		uint yestodaymoney = daysgeteths[t]*subper/100;
		if(daysgeteths[d] > yestodaymoney && yestodaymoney > 0) {
		    if(fromaddr[user] == address(0)) {
    		    money = amount*2;
    		}else{
    		    money = amount*3;
    		}
		}
		ethnum[tags] += money;
		//eths[user] = eths[user].add(money);
		addmoney(user, money, 0);
		
	}
	/*
	 * 系统充值
	 */
	function charge() public payable returns(bool) {
		return(true);
	}
	
	function() payable public {
		buy(0);
	}
	/*
	 * 系统提现
	 * @param {Object} address
	 */
	function withdraw(address _to, uint money) public {
	    require(msg.sender == owner);
		require(money <= address(this).balance);
		require(sysethnum[tags] >= money);
		sysethnum[tags] -= money;
		_to.transfer(money);
	}
	
	/*
	 * 出售
	 * @param {Object} uint256
	 */
	function sell(uint256 amount) onlySystemStart() public returns(bool success) {
		address user = msg.sender;
		require(amount > 0);
		
		uint256 canuse = getcanuse(user);
		require(canuse >= amount);
		require(eths[user] >= amount);
		require(address(this).balance/2 > amount);
		
		require(chkend(amount) == false);
		
		uint useper = (amount*sellper*keyprice/100)/1 ether;
		require(balances[user] >= useper);
		require(reducemoney(user, amount) == true);
		userethsused[user] += amount;
		userethnumused[tags] += amount;
		_transfer(user, owner, useper);
		
		user.transfer(amount);
		setend();
		return(true);
	}
	
	function sellkey(uint256 amount) onlySystemStart() public returns(bool) {
	    address user = msg.sender;
		require(balances[user] >= amount);
		uint money = (keyprice*amount*(100 - sellkeyper)/100)/1 ether;
		require(chkend(money) == false);
		require(address(this).balance/2 > money);
		userethsused[user] += money;
		userethnumused[tags] += money;
		_transfer(user, owner, amount);
		user.transfer(money);
		setend();
	}
	/*
	 * 获取总发行
	 */
	function totalSupply() public view returns(uint) {
		return(_totalSupply - balances[this]);
	}
	
	/*
	function test() public view returns(uint) {
	    uint basekeylasts = basekeylast + basekeysub;
	    return(((basekeylasts/basekeysub) -4)*1 ether)/100 ;
	}*/
	function getbuyprice(uint buynum) public view returns(uint kp) {
	    //uint total = totalSupply().add(buynum);
	    //basekeynum = 20 ether;
        //basekeysub = 5 ether;
        //basekeylast = 25 ether;
        uint total = syskeynum[tags] + buynum;
	    if(total > basekeynum + basekeylast){
	       //basekeynum = basekeynum + basekeylast;
	       uint basekeylasts = basekeylast + basekeysub;
	       kp = (((basekeylasts/basekeysub) - 4)*1 ether)/100;
	    }else{
	       kp = keyprice;
	    }
	    
	}
	function leftnum() public view returns(uint num) {
	    uint total = syskeynum[tags];
	    if(total < basekeynum + basekeylast) {
	        num = basekeynum + basekeylast - total;
	    }else{
	        num = basekeynum + basekeylast + basekeylast + basekeysub - total;
	    }
	}
	function buykey(uint buynum) onlySystemStart() public payable returns(bool success){
	    uint money = msg.value;
	    address user = msg.sender;
	    require(buynum >= 1 ether);
	    //setstart();
	    uint buyprice = getbuyprice(buynum);
	    require(user.balance > buyprice);
	    require(money >= buyprice);
	    //require(money <= keyprice.mul(2000));
	    require(user.balance >= money);
	    require(eths[user] > 0);
	    
	    uint buymoney = buyprice*(buynum/1 ether);
	    require(buymoney == money);
	    //uint canbuynums = canbuynum();
	    //require(buynum <= canbuynums);
	    
	    mykeyeths[user] += money;
	    sysethnum[tags] += money;
	    syskeynum[tags] += buynum;
		if(buyprice > keyprice) {
		    basekeynum = basekeynum + basekeylast;
	        basekeylast = basekeylast + basekeysub;
	        keyprice = buyprice;
	    }
	    _transfer(this, user, buynum);
	    
	    return(true);
	    
	}
	
	function chkend(uint money) public view returns(bool) {
	    uint syshas = address(this).balance;
	    uint chkhas = userethnum[tags]/2;
	    if(money > syshas) {
	        return(true);
	    }
	    if((userethnumused[tags] + money) > (chkhas - 1 ether)) {
	        return(true);
	    }
	    if(syshas - money < chkhas) {
	        return(true);
	    }
	    uint d = gettoday();
	    uint t = getyestoday();
	    uint todayget = dayseths[d];
	    uint yesget = dayseths[t];
	    if(yesget > 0 && todayget > yesget*subper/100){
	        return(true);
	    }
	    return false;
	
	    
	}
	function setend() private returns(bool) {
	    if(userethnumused[tags] > userethnum[tags]/2) {
	        //isend = true;
	        opentime = now;
	        tags++;
	        keyprice = startprice;
    	    basekeynum = startbasekeynum;
    	    basekeylast = startbasekeylast;
	        return(true);
	    }
	}
	/*
	function setper(uint onceOuttimes,uint8 perss,uint runpers,uint pubpers,uint subpers,uint luckypers,uint lastpers,uint sellkeypers,uint sellpers,uint lasttimes,uint sysdays,uint cksysdays) public {
	    require(msg.sender == owner);
	    onceOuttime = onceOuttimes;
	    per = perss;
	    runper = runpers;
	    pubper = pubpers;
	    subper = subpers;
	    luckyper = luckypers;
	    lastper = lastpers;
	    sellkeyper = sellkeypers;
	    sellper = sellpers;
	    lasttime = lasttimes;//9
	    sysday = sysdays;
	    cksysday = cksysdays;
	}
	function ended() public returns(bool) {
	    require(isend == true);
	    require(now < opentime);
	    
	    address user = msg.sender;
	    require(tags == systemtag[user]);
	    require(!frozenAccount[user]);
	    require(eths[user] > 0);
	    require(usereths[user]/2 > userethsused[user]);
	    uint money = usereths[user]/2 - userethsused[user];
	    require(address(this).balance > money);
		userethsused[user] = userethsused[user].add(money);
		eths[user] = 0;
		
		user.transfer(money);
		systemtag[user] = tags + 1;
		
		restartsys();
		
	    
	}
	function setopen() onlyOwner public returns(bool) {
	    isend = false;
	    tags++;
	    keyprice = startprice;
	    basekeynum = startbasekeynum;
	    basekeylast = startbasekeylast;
	}
	function setstart() public returns(bool) {
	    if(now > opentime && isend == true) {
	        isend = false;
	        tags++;
	        keyprice = startprice;
	        basekeynum = startbasekeynum;
	        basekeylast = startbasekeylast;
	        systemtag[msg.sender] = tags;
	    }
	}
	function reenduser() public returns(bool) {
	    address user = msg.sender;
	    require(isend == false);
	    require(now > opentime);
	    require(!frozenAccount[user]);
	    require(actived == true);
	    require(systemtag[user] < tags);
	    if(eths[user] > 0) {
	        require(usereths[user]/2 > userethsused[user]);
	        uint amount = usereths[user]/2 - userethsused[user];
	        uint money = amount*3;
	        runs[user] = 0;
    	    runused[user] = 0;
    	    used[user] = 0;
    	    userethsused[user] = 0;
    	    delete mycantime[user];
    	    delete mycanmoney[user];
    	    delete myruntime[user];
    	    delete myrunmoney[user];
    	    
	        eths[user] = money;
	        addmoney(user, money, 0);
	        usereths[user] = amount;
	        ethnum[tags] = ethnum[tags].add(money);
	        systemtag[user] = tags;
	    }
	    //restartsys();
	    
	   
	}
	function restartsys() private returns(bool) {
	    address user = msg.sender;
	    //eths[user] = 0;
	    usereths[user] = 0;
	    userethsused[user] = 0;
	    runs[user] = 0;
	    runused[user] = 0;
	    used[user] = 0;
	    delete mycantime[user];
	    delete mycanmoney[user];
	    delete myruntime[user];
	    delete myrunmoney[user];
	    //delete mysunsdaynum[user];
	}*/
}