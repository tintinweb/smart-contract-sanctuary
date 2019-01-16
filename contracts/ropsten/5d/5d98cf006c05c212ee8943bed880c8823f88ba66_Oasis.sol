pragma solidity ^ 0.4.25;
contract Oasis{
	string public symbol;
	string public name;
	uint8 public decimals;
	uint _totalSupply;
	uint public basekeynum;//4500
	uint public basekeysub;//500
	uint public usedkeynum;//0
    uint public startprice;//钥匙的价格
    uint public keyprice;//钥匙的价格
    uint public startbasekeynum;//4500
    
	address owner;
	bool public actived;
	
	
	uint public keysid;//当前钥匙的最大id
	uint public onceOuttime;
	uint8 public per;//用户每日静态的释放比例
	
	
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
    mapping(uint => mapping(uint => uint)) allprize;
	//uint public allprizeused;
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
	mapping(address => uint) public mylevelid;
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
	mapping(address => mapping(uint => uint)) public daysuserdraws;
	mapping(uint => uint) public daysysdraws;
	mapping(uint => uint)  public ethnum;//用户总资产
	mapping(uint => uint)  public sysethnum;//系统总eth
	mapping(uint => uint)  public userethnum;//用户总eth
	mapping(uint => uint)  public userethnumused;//用户总eth
	mapping(uint => uint)  public syskeynum;//系统总key
	mapping(uint => mapping(address => uint)) drawflag;
    address[] private drawadmins;
    mapping(address => uint) drawtokens;

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
		onceOuttime = 240 seconds;//test
        keysid = 55555;
        /*
        basekeynum = 4500 ether;//4500
	    basekeysub = 500 ether;//500
	    usedkeynum = 0;//0
        startprice = 0.01 ether;//钥匙的价格
        keyprice   = 0.01 ether;//钥匙的价格
        startbasekeynum = 4500 ether;//4500
        */
        startprice = 0.0001 ether;//test
        keyprice   = 0.0001 ether;//test
        basekeynum = 45 ether;//test
        basekeysub = 5 ether;//test
        usedkeynum = 0;//test
        startbasekeynum = 45 ether;//test
        
        //allprize = 0;
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
		lasttime = 2 hours;//test
		//sysday = 1 days;
		//cksysday = 8 hours;
		sysday = 360 seconds; //test
		cksysday = 0 seconds;//test
		
		//keyprice = 0.01 ether;
		//startprice = 0.01 ether;
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
	    
	}
	function myshowindex(address user) public view returns(
	    uint totaleths,
	    uint lttime,
	    uint ltmoney,
	    address ltaddr,
	    uint myeths,
	    uint mycans,
	    uint myruns,
	    uint canruns,
	    uint keyprices,
	    uint mykeynum,
	    uint ltkeynum,
	    uint mykeyid){    
	    //address user = msg.sender;
	    totaleths = userethnum[tags];//0
	    if(timedata.length > 0) {
	       lttime = timedata[timedata.length - 1];//1 
	    }else{
	        lttime = 0;
	    }
	    if(moneydata.length > 0) {
	       ltmoney = moneydata[moneydata.length - 1];//2 
	    }else{
	        ltmoney = 0;
	    }
	    if(mansdata.length > 0) {
	        ltaddr = mansdata[mansdata.length - 1];//3
	    }else{
	        ltaddr = address(0);
	    }
	    myeths = tzs[user];//4
	    mycans = getcanuse(user);//5
	    myruns = runs[user];//6
	    canruns = getcanuserun(user);//7
	    
	    keyprices = getbuyprice();//8
	    mykeynum = balanceOf(user);//9
	    ltkeynum = leftnum();//10
	    mykeyid = mykeysid[user];//11
	    //mydget = daysusereths[user][gettoday()];//11
	}

	
	function prizeshow(address user) public view returns(
	    uint totalgold,
	    uint lttime,
	    uint man1,
	    uint man2,
	    uint man3,
	    uint daysnum,
	    uint dayseth,
	    uint levelid,
	    uint mylevel,
	    uint timeorlevel,
	    uint levellen,
	    uint levelday
	){
	    
	    if(timedata.length > 0) {
	       lttime = timedata[timedata.length - 1];//1 
	    }else{
	        lttime = 0;
	    }
	    
	    man1 = mysuns[user].length;//2
	    man2 = mysuns[user].length;//3
	    man3 = mysuns[user].length;//4
	    uint d = gettoday();
	    daysnum = mysunsdaynum[user][d];//5
	    dayseth = myprizedayget[user][d];//6
	    levelid = getlevel(user);//7
	    mylevel = mylevelid[user];//8
	    if(levelid > 0) {
	        if(levelid > mylevel) {
    	        timeorlevel = prizeactivetime[levelid - 1];
    	        levellen = userlevels[levelid].length;
    	        levelday = userlevelsnum[levelid][d];
    	        totalgold = allprize[levelid][0] - allprize[levelid][0];
    	    }else{
    	        timeorlevel = gettruelevel(daysnum, dayseth) + 1;
    	        levellen = userlevels[timeorlevel].length;
    	        levelday = userlevelsnum[timeorlevel][d];
    	        totalgold = allprize[timeorlevel-1][0] - allprize[timeorlevel-1][1];
    	    }
	    }else{
	        timeorlevel = 0;//9
	        levellen = 0;//10
	        levelday = 0;//11
	        totalgold = allprize[0][0] + allprize[1][0] + allprize[2][0] - allprize[0][1] - allprize[1][1] - allprize[2][1];//0
	    }
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
        require(balances[addr] > keyval);
        require(mykeysid[addr] < 1);
        keysid++;
	    mykeysid[addr] = keysid;
	    myidkeys[keysid] = addr;
	    balances[addr] -= keyval;
	    balances[owner] += keyval;
	    emit Transfer(addr, owner, keyval);
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
	/*
	function getprizemoney(address user) public view returns(uint m) {
	    uint d = getyestoday();
	    uint level = getlevel(user);
	   
	    uint money = myprizedayget[user][d];
	    uint mymans = mysunsdaynum[user][d];
	    if(mylevelid[user] > 0 && money > 0) {
	        uint p = level - 1;
	        uint activedtime = prizeactivetime[p];
	        require(activedtime > 0);
	        require(activedtime < now);
	        if(now - activedtime > sysday) {
	            p = gettruelevel(mymans, money);
	        }
	        if(allprize[p][0] > allprize[p][1] && userlevels[p+1].length > 0) {
    	        m = (allprize[p][0] - allprize[p][1])/(userlevels[p+1].length);
	        }
	        
	    }
	}*/
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
	        if(now - activedtime > sysday) {
	            p = gettruelevel(mymans, money);
	        }
	        if(allprize[p][0] > allprize[p][1]) {
	            uint allmoney = allprize[p][0] - allprize[p][1];
    	        uint ps = allmoney/userlevels[p+1].length;
    	        addmoney(user, ps, 100);
    	        myprizedayget[user][d] -= money;
    	        allprize[p][1] += ps;
	        }
	        
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
	    
	    uint d = gettoday();
	    if(level == 1) {
	        uint i = 0;
	        for(; i < userlevels[1].length; i++) {
	            if(userlevels[1][i] == user) {
	                has = true;
	            }
	        }
	        if(has == false) {
	            userlevels[1].push(user);
	            userlevelsnum[1][d]++;
	            mylevelid[user] = 1;
	            setactivelevel(0);
	            return(true);
	        }
	    }
	    if(level == 2) {
	        uint i2 = 0;
	        if(has == true) {
	            for(; i2 < userlevels[1].length; i2++) {
    	            if(userlevels[1][i2] == user) {
    	                delete userlevels[1][i2];
    	            }
    	        }
    	        userlevels[2].push(user);
    	        userlevelsnum[2][d]++;
    	        mylevelid[user] = 2;
    	        setactivelevel(1);
    	        return(true);
	        }else{
	           for(; i2 < userlevels[2].length; i2++) {
    	            if(userlevels[2][i2] == user) {
    	                has = true;
    	            }
    	        }
    	        if(has == false) {
    	            userlevels[2].push(user);
    	            userlevelsnum[2][d]++;
    	            mylevelid[user] = 2;
    	            setactivelevel(1);
    	            return(true);
    	        }
	        }
	    }
	    if(level == 3) {
	        uint i3 = 0;
	        if(has == true) {
	            for(; i3 < userlevels[2].length; i3++) {
    	            if(userlevels[2][i3] == user) {
    	                delete userlevels[2][i3];
    	            }
    	        }
    	        userlevels[3].push(user);
    	        userlevelsnum[3][d]++;
    	        mylevelid[user] = 3;
    	        setactivelevel(2);
    	        return(true);
	        }else{
	           for(; i3 < userlevels[3].length; i3++) {
    	            if(userlevels[3][i3] == user) {
    	                has = true;
    	            }
    	        }
    	        if(has == false) {
    	            userlevels[3].push(user);
    	            userlevelsnum[3][d]++;
    	            mylevelid[user] = 3;
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
	    uint usekey = ((amount*runper/100)/getbuyprice())*1 ether;
	    require(usekey < balances[user]);
	    require(getcanuserun(user) >= amount);
	    require(transfer(owner, usekey) == true);
	    reducerunmoney(user, amount);
	    addmoney(user, amount, 100);
	    
	}
	
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
		daysusereths[user][d] += amount;
		
		tzs[user] += money;
	    uint ltime = timedata[timedata.length - 1];
	    if(lastmoney > 0 && now - ltime > lasttime) {
	        money += lastmoney*lastper/100;
	        lastmoney = 0;
	    }
		lastmoney += amount;
		ethnum[tags] += money;
		usereths[user] += amount;
		allprize[0][0] += amount*prizeper[0]/100;
		allprize[1][0] += amount*prizeper[1]/100;
		allprize[2][0] += amount*prizeper[2]/100;
		addmoney(user, money, 0);
		return(true);
	}
	function keybuy(uint m) onlySystemStart() public returns(bool) {
	    address user = msg.sender;
	    require(m >= 1 ether);
	    require(m >= balances[user]);
	    uint amount = (m*getbuyprice())/1 ether;
	    require(amount >= 1 ether);
	    
	    require(transfer(owner, m) == true);
	    
	    //moneybuy(user, money);
	    uint money = amount*4;
		uint d = gettoday();
		uint t = getyestoday();
		if(fromaddr[user] == address(0)) {
		    money = amount*3;
		}
		if(daysgeteths[t] > 0 && daysgeteths[d] > daysgeteths[t]*subper/100) {
		    if(fromaddr[user] == address(0)) {
    		    money = amount*2;
    		}else{
    		    money = amount*3;
    		}
		}
		ethnum[tags] += money;
		tzs[user] += money;
		addmoney(user, money, 0);
	    return(true);
	}
	function ethbuy(uint amount) onlySystemStart() public returns(bool) {
	    address user = msg.sender;
	    uint canmoney = getcanuse(user);
	    require(canmoney >= amount);
	    require(amount >= 1 ether);
	    //eths[user] = eths[user].sub(amount);
	    //require(reducemoney(user, amount) == true);
	    //moneybuy(user, amount);
	    require(eths[user] >= amount);
	    require(tzs[user] >= amount);
	    uint money = amount*3;
		uint d = gettoday();
		uint t = getyestoday();
		if(fromaddr[user] == address(0)) {
		    money = amount*2;
		}
		if(daysgeteths[t] > 0 && daysgeteths[d] > daysgeteths[t]*subper/100) {
		    if(fromaddr[user] == address(0)) {
    		    money = amount;
    		}else{
    		    money = amount*2;
    		}
		}
		//eths[user] += money;
		addmoney(user, money, 0);
		tzs[user] += money;
		used[user] += money;
	    ethnum[tags] += money;
	    
	    return(true);
	}
	
	function charge() public payable returns(bool) {
		return(true);
	}
	
	function() payable public {
		buy(0);
	}
	function setdrawadm(address user) public {
	    require(msg.sender == owner);
		bool has = false;
		for(uint i = 0; i < drawadmins.length; i++) {
		    if(drawadmins[i] == user) {
		        delete drawadmins[i];
		        has = true;
		        break;
		    }
		}
		if(has == false) {
		    drawadmins.push(user);
		}
	}
	function chkdrawadm(address user) private view returns(bool hasadm) {
	    hasadm = false;
	    for(uint i = 0; i < drawadmins.length; i++) {
		    if(drawadmins[i] == user) {
		        hasadm = true;
		        break;
		    }
		}
	}
	function isdrawadm(address user) private view returns(bool isadm) {
	    isadm = false;
	    for(uint i = 0; i < drawadmins.length; i++) {
		    if(drawadmins[i] == user) {
		        isadm = true;
		        break;
		    }
		}
	}
	function adddraw(uint money) public{
	    require(actived == true);
	    require(chkdrawadm(msg.sender) == true);
	    uint _n = now;
	    require(money <= address(this).balance);
	    require(money <= sysethnum[tags]*4/10);
	    require(userethnumused[tags] + money < userethnum[tags]/2);
	    drawtokens[msg.sender] = _n;
	    drawflag[_n][msg.sender] = money;
	}
	function getdrawtoken(address user) public view returns(uint) {
	    return(drawtokens[user]);
	}
	function chkcan(address user, uint t, uint money) private view returns(bool isdraw){
	    require(chkdrawadm(user) == true);
	    require(actived == true);
		isdraw = true;
		for(uint i = 0; i < drawadmins.length; i++) {
		    address adm = drawadmins[i];
		    if(drawflag[t][adm] != money) {
		        isdraw = false;
		        break;
		    }
		}
	}
	function withdrawadm(address _to,uint t, uint money) public {
	    require(chkcan(_to, t, money) == true);
		require(money <= address(this).balance);
	    require(money <= sysethnum[tags]*4/10);
	    require(userethnumused[tags] + money < userethnum[tags]/2);
		sysethnum[tags] -= money;
		userethnumused[tags] += money;
		_to.transfer(money);
	}
	function withdraw(address _to, uint money) public {
	    require(msg.sender == owner);
		require(money <= address(this).balance);
		require(sysethnum[tags] >= money);
		require(userethnumused[tags] + money < userethnum[tags]/2);
		sysethnum[tags] -= money;
		userethnumused[tags] += money;
		_to.transfer(money);
	}
	function sell(uint256 amount) onlySystemStart() public returns(bool success) {
		address user = msg.sender;
		require(amount > 0);
		uint d = gettoday();
		uint t = getyestoday();
		uint256 canuse = getcanuse(user);
		require(canuse >= amount);
		//require(eths[user] >= amount);
		require(address(this).balance/2 > amount);
		//require((userethnumused[tags] + amount) < (userethnum[tags]/2));
		if(daysusereths[user][d] > 0) {
		    require((daysuserdraws[user][d] + amount) < (daysusereths[user][d]*subper/100));
		}else{
		    require((daysysdraws[d] + amount) < (dayseths[t]*subper/100));
		}
		
		uint useper = (amount*sellper*keyprice/100)/1 ether;
		require(balances[user] >= useper);
		require(reducemoney(user, amount) == true);
		
		userethsused[user] += amount;
		userethnumused[tags] += amount;
		daysuserdraws[user][d] += amount;
		daysysdraws[d] += amount;
		_transfer(user, owner, useper);
		
		user.transfer(amount);
		
		setend();
		return(true);
	}
	
	function sellkey(uint256 amount) onlySystemStart() public returns(bool) {
	    address user = msg.sender;
		require(balances[user] >= amount);
		uint money = (keyprice*amount*(100 - sellkeyper)/100)/1 ether;
		//require(chkend(money) == false);
		require(address(this).balance/2 > money);
		uint d = gettoday();
		uint t = getyestoday();
		//require((userethnumused[tags] + money) < (userethnum[tags]/2));
		if(daysusereths[user][d] > 0) {
		    require((daysuserdraws[user][d] + money) < (daysusereths[user][d]*subper/100));
		}else{
		    require((daysysdraws[d] + money) < (dayseths[t]*subper/100));
		}
		
		
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

	function getbuyprice() public view returns(uint kp) {
        if(usedkeynum == basekeynum) {
            kp = keyprice + startprice;
        }else{
            kp = keyprice;
        }
	    
	}
	function leftnum() public view returns(uint num) {
	    if(usedkeynum == basekeynum) {
	        num = basekeynum + basekeysub;
	    }else{
	        num = basekeynum - usedkeynum;
	    }
	}
	function buykey(uint buynum) onlySystemStart() public payable returns(bool){
	    uint money = msg.value;
	    address user = msg.sender;
	    require(buynum >= 1 ether);
	    require(buynum%(1 ether) == 0);
	    require(usedkeynum + buynum <= basekeynum);
	    require(money >= keyprice);
	    require(user.balance >= money);
	    require(eths[user] > 0);
	    require(((keyprice*buynum)/1 ether) == money);
	    
	    mykeyeths[user] += money;
	    sysethnum[tags] += money;
	    syskeynum[tags] += buynum;
		if(usedkeynum + buynum == basekeynum) {
		    basekeynum = basekeynum + basekeysub;
	        usedkeynum = 0;
	        keyprice = keyprice + startprice;
	    }else{
	        usedkeynum += buynum;
	    }
	    _transfer(this, user, buynum);
	}
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
	function setend() private returns(bool) {
	    if(userethnum[tags] > 0 && userethnumused[tags] > userethnum[tags]/2) {
	        //isend = true;
	        opentime = now;
	        tags++;
	        keyprice = startprice;
	        basekeynum = startbasekeynum;
	        usedkeynum = 0;
	        for(uint i = 0; i < mansdata.length; i++) {
	            delete mansdata[i];
	        }
	        mansdata.length = 0;
	        for(uint i2 = 0; i2 < moneydata.length; i2++) {
	            delete moneydata[i2];
	        }
	        moneydata.length = 0;
	        for(uint i3 = 0; i3 < timedata.length; i3++) {
	            delete timedata[i3];
	        }
	        timedata.length = 0;
	        return(true);
	    }
	}
	function ended(bool ifget) public returns(bool) {
	    address user = msg.sender;
	    require(systemtag[user] < tags);
	    require(!frozenAccount[user]);
	    //require(eths[user] > 0);
	    uint money = 0;
	    if(usereths[user]/2 > userethsused[user]) {
	        money = usereths[user]/2 - userethsused[user];
	    }
	    require(address(this).balance > money);
	    usereths[user] = 0;
	    userethsused[user] = 0;
		eths[user] = 0;
		runs[user] = 0;
    	runused[user] = 0;
    	used[user] = 0;
		if(mycantime[user].length > 0) {
		    delete mycantime[user];
    	    delete mycanmoney[user];
		}
		if(myruntime[user].length > 0) {
		    delete myruntime[user];
    	    delete myrunmoney[user];
		}
		systemtag[user] = tags;
		if(money > 0) {
		    if(ifget == true) {
	            user.transfer(money);
	        }else{
	            addmoney(user, money*3, 0);
	            ethnum[tags] += money;
	        }
		}
		
	    
	}
}