pragma solidity ^ 0.4.24;

// ----------------------------------------------------------------------------
// 安全的加减乘除
// ----------------------------------------------------------------------------
library SafeMath {
	function add(uint a, uint b) internal pure returns(uint c) {
		c = a + b;
		require(c >= a);
	}

	function sub(uint a, uint b) internal pure returns(uint c) {
		require(b <= a);
		c = a - b;
	}

	function mul(uint a, uint b) internal pure returns(uint c) {
		c = a * b;
		require(a == 0 || c / a == b);
	}

	function div(uint a, uint b) internal pure returns(uint c) {
		require(b > 0);
		c = a / b;
	}
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
	function totalSupply() public constant returns(uint);

	function balanceOf(address tokenOwner) public constant returns(uint balance);

	function allowance(address tokenOwner, address spender) public constant returns(uint remaining);

	function transfer(address to, uint tokens) public returns(bool success);

	function approve(address spender, uint tokens) public returns(bool success);

	function transferFrom(address from, address to, uint tokens) public returns(bool success);

	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
	function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

// ----------------------------------------------------------------------------
// 管理员
// ----------------------------------------------------------------------------
contract Owned {
	address public owner;
	address public newOwner;

	event OwnershipTransferred(address indexed _from, address indexed _to);

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address _newOwner) public onlyOwner {
		newOwner = _newOwner;
	}

	function acceptOwnership() public {
		require(msg.sender == newOwner);
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
		newOwner = address(0);
	}
}

// ----------------------------------------------------------------------------
// 核心类
// ----------------------------------------------------------------------------
contract Oasis is ERC20Interface, Owned {
	using SafeMath
	for uint;

	string public symbol;
	string public name;
	uint8 public decimals;
	uint _totalSupply;
	uint basekeynum;//4500
	uint basekeysub;//500
	uint basekeylast;//2000

	
	bool public actived;

	
	uint public keyprice;//钥匙的价格
	uint public keysid;//当前钥匙的最大id
	uint public onceOuttime;
	
	uint public ethnum;//用户总资产
	uint public sysethnum;//系统总eth
	uint public userethnum;//用户总eth
	uint8 public per;//用户每日静态的释放比例
	uint public allprize;
	uint public allprizeused;
	
	uint[] public mans;//用户上线人数的数组
	uint[] public pers;//用户上线分额的比例数组
	uint[] public prizeper;//用户每日静态的释放比例
	uint[] public prizelevelsuns;//用户上线人数的数组
	uint[] public prizelevelmans;//用户上线人数的比例数组
	address[] public level1;
	address[] public level2;
	address[] public level3;
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

	mapping(address => uint) balances;//用户的钥匙数量
	
	mapping(address => uint) systemtag;//用户的系统标志 
	mapping(address => uint) eths;//用户的资产数量
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
	mapping(address => mapping(uint => uint)) public myprizedaygetdata;
	//管理员帐号
	mapping(address => bool) public admins;
	//用户钥匙id
	mapping(address => uint) public mykeysid;
	mapping(address => uint) public mykeyeths;
	mapping(address => uint) public mykeyethsused;
	//与用户钥匙id对应
	mapping(uint => address) public myidkeys;
	//all once day get all
	mapping(uint => uint) public daysgeteths;
	mapping(uint => uint) public dayseths;
	//user once day pay
	mapping(address => mapping(uint => uint)) public daysusereths;

	/* 通知 */
	event FrozenFunds(address target, bool frozen);
	// ------------------------------------------------------------------------
	// Constructor
	// ------------------------------------------------------------------------
	constructor() public {

		symbol = "OASIS";
		name = "Oasis Key";
		decimals = 18;
		ethnum = 0;
		_totalSupply = 50000000 ether;
	
		actived = true;
		tags = 0;
		onceOuttime = 16 hours; //增量的时间 正式 
        keysid = 55555;
        
        basekeynum = 2000 ether;
        basekeysub = 500 ether;
        basekeylast = 2500 ether;
        allprize = 0;
		balances[this] = _totalSupply;
		per = 15;
		runper = 20;
		mans = [2,4,6];
		pers = [20,15,10];
		prizeper = [2,2,2];
		prizelevelsuns = [20,30,50];
		prizelevelmans = [100,300,800];
		prizelevelsunsday = [2,4,6];
		prizelevelmansday = [10 ether,30 ether,50 ether];
		prizeactivetime = [0,0,0];
		pubper = 2;
		subper = 120;
		luckyper = 5;
		lastmoney = 0;
		lastper = 2;
		lasttime = 8 hours;
		keyprice = 0.01 ether;
		sellkeyper = 30;
		isend = false;
		opentime = now;
		emit Transfer(address(0), owner, _totalSupply);

	}

	/* 获取用户金额 */
	function balanceOf(address tokenOwner) public view returns(uint balance) {
		return balances[tokenOwner];
	}
	function indexview(address addr) public view returns(uint keynum,
	uint kprice, uint ethss, uint ethscan, uint level, 
	uint keyid, uint runsnum, uint runscan,
	 uint top1num, uint top2num, uint top3num, uint yestodaycom
	 ){
	     uint d = getyestoday();
	    keynum = balances[addr];//0
	    kprice = keyprice;//1
	    ethss = eths[addr];//2
	    ethscan = getcanuse(addr);//3
	    level = getlevel(addr);//4
	    keyid = mykeysid[addr];//5
	    runsnum = runs[addr];//6
	    runscan = getcanuserun(addr);//7
	    top1num = mysuns[addr].length;//8
	    top2num = mysecond[addr].length;//9
	    top3num = mythird[addr].length;//10
	    yestodaycom = myprizedaygetdata[addr][d];//11
	    
	}
	function indexextend() public view returns(uint lttime, address lkuser){
	    uint len = timedata.length;
	    if(len == 0) {
	        lttime = opentime;//0
	    }else{
	        lttime = timedata[len - 1];
	    }
	    lkuser = getluckyuser();//1
	}
	function gettags(address addr) public view returns(uint t) {
	    t = systemtag[addr];
	}
	/*
	 * 添加金额，为了统计用户的进出
	 */
	function addmoney(address _addr, uint256 _money, uint _day) private {
	    uint256 _days = _day * (1 days);
		uint256 _now = now - _days;
		mycanmoney[_addr].push(_money);
		mycantime[_addr].push(_now);

	}
	/*
	 * 用户金额减少时的触发
	 * @param {Object} address
	 */
	function reducemoney(address _addr, uint256 _money) private {
		used[_addr] += _money;
	}
	/*
	 * 添加run金额，为了统计用户的进出
	 */
	function addrunmoney(address _addr, uint256 _money, uint _day) private {
		uint256 _days = _day * (1 days);
		uint256 _now = now - _days;
		myrunmoney[_addr].push(_money);
		myruntime[_addr].push(_now);

	}
	/*
	 * 用户金额减少时的触发
	 * @param {Object} address
	 */
	function reducerunmoney(address _addr, uint256 _money) private {
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
		if(tokenOwner == owner) {
			return(eths[owner]);
		}
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
		_left = _left - used[tokenOwner];
		if(_left < 0) {
			return(0);
		}
		if(_left > eths[tokenOwner]) {
			return(eths[tokenOwner]);
		}
		return(_left);
	}
	/*
	 * 获取用户的可用金额
	 * @param {Object} address
	 */
	function getcanuserun(address tokenOwner) public view returns(uint) {
		uint256 _now = now;
		uint256 _left = 0;
		if(tokenOwner == owner) {
			return(runs[owner]);
		}
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
		_left = _left - runused[tokenOwner];
		if(_left < 0) {
			return(0);
		}
		if(_left > runs[tokenOwner]) {
			return(runs[tokenOwner]);
		}
		return(_left);
	}

	/*
	 * 用户转账
	 * @param {Object} address
	 */
	function _transfer(address from, address to, uint tokens) internal{
	    
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
    function transfer(address _to, uint256 _value) public returns(bool){
        require(actived == true);
	    require(isend == false);
        _transfer(msg.sender, _to, _value);
        mykeyethsused[msg.sender].add(_value);
        return(true);
    }
    //激活钥匙
    function activekey(address addr) public returns(bool) {
        require(actived == true);
	    require(isend == false);
        uint keyval = 1 ether;
        require(balances[msg.sender] >= keyval);
        
        if(mykeysid[addr] < 1) {
	        keysid = keysid + 1;
	        mykeysid[addr] = keysid;
	        myidkeys[keysid] = addr;
	        transfer(owner, keyval);
	    }
	    return(true);
	    
    }
	/*
	 * 获取真实值
	 * @param {Object} uint
	 */
	function getnum(uint num) public view returns(uint) {
		return(num * 10 ** uint(decimals));
	}
	/*
	 * 获取上家地址
	 * @param {Object} address
	 */
	function getfrom(address _addr) public view returns(address) {
		return(fromaddr[_addr]);
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
		balances[from] = balances[from].sub(tokens);
		//reducemoney(from, tokens);
		allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
		balances[to] = balances[to].add(tokens);
		//addmoney(to, tokens, 0);
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

	/*
	 * 授权
	 * @param {Object} address
	 */
	function approveAndCall(address spender, uint tokens, bytes data) public returns(bool success) {
		//require(admins[msg.sender] == true);
		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
		return true;
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
	function admAccount(address target, bool freeze) onlyOwner public {
		admins[target] = freeze;
	}
	/*
	 * 系统设置
	 * @param {Object} uint
	 
	function setPrices(uint keyprices) public {
		require(admins[msg.sender] == true);
		keyprice = keyprices;
	}*/
	/*
	 * 获取系统设置
	 
	function getprice() public view returns(uint price) {
		price = keyprice;
	}
	*/
	/*
	 * 设置是否开启
	 * @param {Object} bool
	 */
	function setactive(bool t) public onlyOwner {
		actived = t;
	}

	
	/*
	 * 向账户拨发资金
	 * @param {Object} address
	 */
	function mintToken(address target, uint256 mintedAmount) public onlyOwner{
		require(!frozenAccount[target]);
		require(actived == true);
		balances[target] = balances[target].add(mintedAmount);
		emit Transfer(owner, target, mintedAmount);
	}
	
	/*
	 * 获取总账目
	 */
	function getall() public view returns(uint256 money) {
		money = address(this).balance;
	}
	function getmykeyid(address addr) public view returns(uint ky) {
	    ky = mykeysid[addr];
	}
	function getyestoday() public view returns(uint d) {
	    uint today = gettoday();
	    d = today - 86400;
	}
	function gettormow() public view returns(uint d) {
	    uint today = gettoday();
	    d = today + 86400;
	}
	function gettoday() public view returns(uint d) {
	    uint n = now;
	    d = n - n%86400 - 28800;
	}
	function gettodayget() public view returns(uint m) {
	    uint d = gettoday();
	    m = daysgeteths[d];
	}
	function getyestodayget() public view returns(uint m) {
	    uint d = getyestoday();
	    m = daysgeteths[d];
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
	/*
	function setprize(address addr, uint money) private returns(bool){
	    uint level = getlevel(addr);
	    uint d = gettoday();
	    allprize.add(money);
	    if(level > 0) {
	        uint p = level - 1;
	        uint ps = money*prizeper[p]/100;
	        
	        myprizedayget[addr][d].add(ps);
	    }
	    return(true);
	}*/
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
	function getprize() public returns(bool) {
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
	        if(now - activedtime > 86400) {
	            p = gettruelevel(mymans, money);
	        }
	        uint ps = allmoney*prizeper[p]/100;
	        eths[user].add(ps);
	        addmoney(user, ps, 100);
	        myprizedayget[user][d].sub(money);
	        allprizeused.add(money);
	    }
	}
	function setactivelevel(uint level) private returns(bool) {
	    uint t = prizeactivetime[level];
	    if(t == 0) {
	        prizeactivetime[level] = now + 86400;
	    }
	    return(true);
	}
	function setuserlevel(address user) private returns(bool) {
	    uint level = getlevel(user);
	    bool has = false;
	    if(level == 1) {
	        
	        for(uint i = 0; i < level1.length; i++) {
	            if(level1[i] == user) {
	                has = true;
	            }
	        }
	        if(has == false) {
	            level1.push(user);
	            setactivelevel(0);
	            return(true);
	        }
	    }
	    if(level == 2) {
	        if(has == true) {
	            for(uint ii = 0; ii < level1.length; ii++) {
    	            if(level1[ii] == user) {
    	                delete level1[ii];
    	            }
    	        }
    	        level2.push(user);
    	        setactivelevel(1);
    	        return(true);
	        }else{
	           for(uint i2 = 0; i2 < level2.length; i2++) {
    	            if(level1[i2] == user) {
    	                has = true;
    	            }
    	        }
    	        if(has == false) {
    	            level2.push(user);
    	            setactivelevel(1);
    	            return(true);
    	        }
	        }
	    }
	    if(level == 3) {
	        if(has == true) {
	            for(uint iii = 0; iii < level2.length; iii++) {
    	            if(level2[iii] == user) {
    	                delete level2[iii];
    	            }
    	        }
    	        level3.push(user);
    	        setactivelevel(2);
    	        return(true);
	        }else{
	           for(uint i3 = 0; i3 < level3.length; i3++) {
    	            if(level3[i3] == user) {
    	                has = true;
    	            }
    	        }
    	        if(has == false) {
    	            level3.push(user);
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
	    if(f1 != address(0)) {
	        if(mysuns[f1].length >= mans[0]) {
	            uint sendmoney1 = (money*per/1000)*pers[0]/100;
    	        runs[f1].add(sendmoney1);
    	        addrunmoney(f1, sendmoney1, 0);
    	        myprizedayget[f1][d].add(amount);
    	        myprizedaygetdata[f1][d].add(amount);
    	        setuserlevel(f1);
    	        
	        }
	    }
	    if(f1 != address(0) && f2 != address(0)) {
	        if(mysuns[f2].length >= mans[1]) {
	            uint sendmoney2 = (money*per/1000)*pers[1]/100;
    	        runs[f2].add(sendmoney2);
    	        addrunmoney(f2, sendmoney2, 0);
    	        myprizedayget[f2][d].add(amount);
    	        myprizedaygetdata[f2][d].add(amount);
    	        setuserlevel(f2);
	        }
	        
	        
	    }
	    if(f1 != address(0) && f2 != address(0) && f3 != address(0)) {
	        if(mysuns[f3].length >= mans[2]) {
	            uint sendmoney3 = (money*per/1000)*pers[2]/100;
    	        runs[f3].add(sendmoney3);
    	        addrunmoney(f3, sendmoney3, 0);
    	        myprizedayget[f3][d].add(amount);
    	        myprizedaygetdata[f3][d].add(amount);
    	        setuserlevel(f3);
	        }
	       
	        
	    }
	    
	}
	function setpubprize(uint amount) private returns(bool) {
	    uint len = moneydata.length;
	    if(len > 1) {
	        uint all = 0;
	        uint start = 0;
	        if(len > 10) {
	            start = len - 10;
	        }
	        for(uint i = start; i < len; i++) {
	            all += moneydata[i];
	        }
	        uint sendmoney = amount*pubper/100;
	        for(uint ii = start; ii < len; ii++) {
	            all += moneydata[i];
	            address user = mansdata[ii];
	            uint money = sendmoney*moneydata[ii]/all;
	            eths[user] = eths[user].add(money);
	            addmoney(user, money, 100);
	        }
	    }
	    return(true);
	}
	function getluckyuser() public view returns(address addr) {
	    uint d = gettoday();
	    uint t = getyestoday();
	    uint maxmoney = moneydata[0];
	    for(uint i = 0; i < moneydata.length; i++) {
	        if(timedata[i] > t && timedata[i] < d && moneydata[i] > maxmoney) {
	            addr = mansdata[i];
	        }
	    }
	}
	function getluckyprize() public returns(bool) {
	    address user = msg.sender;
	    require(user == getluckyuser());
	    uint d = getyestoday();
	    require(daysusereths[user][d] > 0);
	    uint money = dayseths[d]*luckyper/1000;
	    eths[user].add(money);
	    addmoney(user, money, 100);
	}
	function setlastprize() private returns(bool) {
	    uint l = timedata.length;
	    if(l > 0 && lastmoney > 0) {
	        uint ltime = timedata[l - 1];
	        if(now - ltime > lasttime) {
	            uint money = lastmoney*lastper/100;
	            address user = msg.sender;
	            eths[user].add(money);
	            addmoney(user, money, 100);
	            lastmoney = 0;
	        }
	    }
	    
	}
	function runtoeth(uint amount) public returns(bool) {
	    address user = msg.sender;
	    uint can = getcanuserun(user);
	    uint kn = balances[user];
	    uint usekey = amount*runper/100;
	    require(usekey <= kn);
	    require(runs[user] >= can);
	    require(can >= amount);
	    
	    runs[user].sub(amount);
	    reducerunmoney(user, amount);
	    eths[user].add(amount);
	    addmoney(user, amount, 100);
	    transfer(owner, usekey);
	}
	/*
	 * 购买
	 */
	function buy(uint keyid) public payable returns(uint) {
		require(actived == true);
	    require(isend == false);
		address user = msg.sender;
		require(!frozenAccount[user]);
		require(msg.value > 0);

		uint amount = msg.value;
		require(amount >= 1 ether);
		uint money = amount*3;
		uint d = gettoday();
		uint t = getyestoday();
		bool ifadd = false;
		//如果用户没有上家
		if(fromaddr[user] == address(0)) {
		    if(keyid > 0) {
		        address topaddr = myidkeys[keyid];
		        address top2 = fromaddr[topaddr];
		        address top3 = fromaddr[top2];
		        //set sun addr
		        fromaddr[user] = topaddr;
		        //record suns log
		        mysuns[topaddr].push(user);
		        //mysunsdayget[topaddr][d].add(money);
		        mysunsdaynum[topaddr][d]++;
		        if(top2 != address(0)){
		            mysecond[top2].push(user);
		            //mysunsdayget[top2][d].add(money);
		            mysunsdaynum[top2][d]++;
		        }
		        if(top3 != address(0)){
		            mythird[top3].push(user);
		            //mysunsdayget[top3][d].add(money);
		            mysunsdaynum[top3][d]++;
		        }
		        ifadd = true;
		        //money = money + amount;
		    }
		}else{
		    ifadd = true;
		    //money = money + amount;
		}
		if(ifadd == true) {
		    money = amount*4;
		}
		uint yestodaymoney = daysgeteths[t]*subper/100;
		if(daysgeteths[d] > yestodaymoney) {
		    if(ifadd == true) {
    		    money = amount*3;
    		}else{
    		    money = amount*2;
    		}
		}
		ethnum.add(money);
		sysethnum.add(amount);
		userethnum.add(amount);
		
		setlastprize();
		lastmoney.add(amount);
		
		usereths[user].add(amount);
		eths[msg.sender] = eths[msg.sender].add(money);
        if(fromaddr[user] != address(0)) {
            getfromsun(user, money, amount);
        }
		addmoney(user, money, 0);
        //setlastprize();
	    daysgeteths[d].add(money);
	    dayseths[d].add(amount);
	    
		daysusereths[user][d].add(money);
		//public prize
		setpubprize(amount);
		mansdata.push(user);
		moneydata.push(amount);
		timedata.push(now);
		return(amount);
	}
	function keybuy(uint amount) public returns(bool) {
	    require(actived == true);
	    require(isend == false);
	    //address user = msg.sender;
	    //require(amount > balances[user]);
	    _transfer(msg.sender, owner, amount);
	    uint money = amount*keyprice;
	    moneybuy(money);
	    return(true);
	}
	function ethbuy(uint amount) public returns(bool) {
	    require(actived == true);
	    require(isend == false);
	    address user = msg.sender;
	    uint canmoney = getcanuse(user);
	    require(canmoney >= amount);
	    eths[user].sub(amount);
	    reducemoney(user, amount);
	    moneybuy(amount);
	    return(true);
	}
	function moneybuy(uint amount) private returns(bool) {
	    require(actived == true);
	    require(isend == false);
		address user = msg.sender;
		require(!frozenAccount[user]);
		uint money = amount*4;
		uint d = gettoday();
		uint t = getyestoday();
		if(fromaddr[user] == address(0)) {
		    money = amount*3;
		}
		uint yestodaymoney = daysgeteths[t]*subper/100;
		if(daysgeteths[d] > yestodaymoney) {
		    if(fromaddr[user] == address(0)) {
    		    money = amount*2;
    		}else{
    		    money = amount*3;
    		}
		}
		ethnum.add(money);
		eths[user] = eths[user].add(money);
		addmoney(user, money, 0);
		
	}
	/*
	 * 系统充值
	 */
	function charge() public payable returns(bool) {
		//require(actived == true);
		return(true);
	}
	
	function() payable public {
		//buy();
	}
	/*
	 * 系统提现
	 * @param {Object} address
	 */
	function withdraw(address _to, uint money) public onlyOwner {
		require(actived == true);
		require(!frozenAccount[_to]);
		require(money <= address(this).balance);
		sysethnum.sub(money);
		_to.transfer(money);
	}
	function setend(uint money) private returns(bool) {
	    uint syshas = address(this).balance;
	    uint chkhas = sysethnum/2;
	    //require(syshas >= chkhas);
	    if(sysethnum - money < chkhas || syshas < chkhas){
	        isend = true;
	        opentime = now + 86400;
	        return(true);
	    }else{
	        return(false);
	    }
	}
	/*
	 * 出售
	 * @param {Object} uint256
	 */
	function sell(uint256 amount) public returns(bool success) {
		require(actived == true);
		address user = msg.sender;
		require(!frozenAccount[user]);
		require(isend == false);
		require(amount > 0);
		require(setend(amount) == false);
		uint256 canuse = getcanuse(user);
		require(canuse >= amount);
		require(eths[user] >= amount);
		require(address(this).balance > amount);
		msg.sender.transfer(amount);
		userethsused[user].add(amount);
		reducemoney(user, amount);
		eths[user] = eths[user].sub(amount);
        userethsused[user].add(amount);
		//emit Transfer(owner, msg.sender, moneys);
		return(true);
	}
	
	function sellkey(uint256 amount) public returns(bool) {
	    require(actived == true);
	    require(isend == false);
	    address user = msg.sender;
		require(!frozenAccount[user]);
		
		require(balances[user] >= amount);
		uint money = keyprice*amount*(100 - sellkeyper)/100;
		require(setend(money) == false);
		require(address(this).balance > money);
		userethsused[user].add(money);
		user.transfer(money);
	}
	/*
	 * 获取总发行
	 */
	function totalSupply() public view returns(uint) {
		return _totalSupply.sub(balances[this]);
	}
	
	function canbuynum() public view returns(uint num) {
	    num = basekeynum.add(basekeylast).sub(totalSupply());
	    if(num == 0) {
	        num = 1 ether;
	    }
	}
	function buyprices() public view returns(uint price) {
	    price = keyprice;
	}
	function buynums(uint money) public view returns(uint num) {
	    num = money.div(keyprice);
	}
	function buykey(uint buynum) public payable returns(bool success){
	    require(actived == true);
	    require(isend == false);
	    uint money = msg.value;
	    address user = msg.sender;
	    require(user.balance > keyprice);
	    require(money >= keyprice);
	    //require(money <= keyprice.mul(2000));
	    require(user.balance > money);
	    require(eths[user] > 0);
	    require(buynum >= 1 ether);
	    uint buymoney = keyprice.mul(buynum.div(1 ether));
	    require(buymoney == money);
	    uint canbuynums = canbuynum();
	    require(buynum <= canbuynums);
	    uint total = totalSupply().add(buynum);
	    
	    if(total > basekeynum + basekeylast){
	       basekeynum = basekeynum + basekeylast;
	       basekeylast = basekeylast + basekeysub;
	       keyprice = ((basekeylast/basekeysub) - 4)/100;
	    }
	    mykeyeths[user].add(money);
	    sysethnum.add(money);
		//userethnum.add(money);
	    _transfer(this, user, buynum);
	    return(true);
	    
	}
	function activeuser() public returns(bool) {
	    address user = msg.sender;
	    eths[user] = 0;
	    systemtag[user] = tags;
	    return(true);
	}
	function ended() public returns(bool) {
	    require(isend == true);
	    require(now > opentime);
	    
	    address user = msg.sender;
	    require(usereths[user]/2 > userethsused[user]);
	    uint money = usereths[user]/2 - userethsused[user];
	    require(address(this).balance > money);
		userethsused[user].add(money);
		eths[user] = 0;
		
		user.transfer(money);
		if(now - opentime > 86400) {
	        isend = false;
	        tags++;
	        //this todo restart
	        
	    }
	    
	}
	

}