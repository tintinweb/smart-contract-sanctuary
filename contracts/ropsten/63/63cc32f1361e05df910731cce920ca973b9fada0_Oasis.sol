pragma solidity ^ 0.4.25;
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
interface keyInterface {
    function trans(address from, address to, uint tokens, uint _days) external returns(bool);
    function activekey(address addr) external returns(bool);
    function subkey(address addr, uint amount) external returns(bool);
    function getbuyprice(uint buynum) external view returns(uint);
    function getprice() external view returns(uint);
    function sell(uint256 amount, address user) external returns(bool);
    function getsellmoney(uint amount) external view returns(uint);
    function buy(uint buynum, uint money, address user) external returns(bool);
    function balanceOf(address _addr) external view returns (uint256);
    function restart() external returns(bool);
    function getid(address addr) external view returns(uint);
    function getaddr(uint keyid) external view returns(address);
    function leftnum() external view returns(uint);
}
interface ethInterface {
    function totalSupply() external view returns(uint);
    function trans(address from, address to, uint tokens, uint _days) external returns(bool);
    function addmoney(address _addr, uint256 _money, uint _day) external returns(bool);
    function addallmoney(address[] _addr, uint256[] _money) external returns(bool);
    function inituser(address _addr, uint256 _money) external returns(bool);
    function reducemoney(address _addr, uint256 _money) external returns(bool);
    function reduceallmoney(address[] _addr, uint256[] _money) external returns(bool);
    function addrunmoney(address _addr, uint256 _money, uint _day) external returns(bool);
    function addallrunmoney(address[] _addr, uint256[] _money) external returns(bool);
    function addallbuy(address[] _addrrun, uint256[] _moneyrun, address _addr, uint256 _money) external returns(bool);
    function reducerunmoney(address _addr, uint256 _money) external returns(bool);
    function reduceallrunmoney(address[] _addr, uint256[] _money) external returns(bool);
    function geteths(address tokenOwner) external view returns(uint);
    function balanceOf(address addr) external view returns(uint);
    function balanceOfrun(address addr) external view returns(uint);
    function getruns(address tokenOwner) external view returns(uint);
    function gettoday() external view returns(uint);
    function getyestoday() external view returns(uint);
    function getdays() external view returns(uint d, uint t);
    function getuserdayeths(address user) external view returns(uint);
    function getsysdayeths() external view returns(uint);
    function getuserdayruns(address user) external view returns(uint);
    function getsysdayruns() external view returns(uint);
    function runtoeth(address user, uint runseth) external returns(bool);
    function ethtoeth(address user, uint oldmoney, uint newmoney) external returns(bool);
}
interface drawInterface {
    function chkcan(address user, uint t, uint money) external view returns(bool);
}
interface userInterface {
    function bindusertop(address me, address top) external returns(bool);
    function getlevel(address addr) external view returns(uint);
    function gettruelevel(uint n, uint m) external view returns(uint);
    function getlevellen(uint l) external view returns(uint);
    function gettopuser(address user) external view returns(address);
    function gettops(address user) external view returns(address top1,address top2,address top3);
    function getactiveleveltime(uint level) external view returns(uint t);
}
contract Oasis is Owned {
    using SafeMath for uint;
	uint32 public tags;
	mapping(address => uint32) public systemtag;
	bool public actived;
	bool public isend;
	//uint[] public nulluintarr;
	//address[] public nulladdrarr;
	struct sysconfig{
	    uint32 defaultkeyid;
	    uint8 per;//用户每日静态的释放比例15
    	uint8 runper;//20
    	uint8 sellper;//10
    	uint allprize;//0
    	uint allused;
    	uint allprizeused;//0
    	uint8 pubper;//2
    	uint8 subper;//120
    	uint8 luckyper;//5
    	uint lastmoney;//0
    	uint8 lastper;//2
    	uint lasttime;//8 hours
    	uint starttime;//now
    }
    sysconfig public systemconf;
    address[] public mansdata;
	uint[] public moneydata;
	uint[] public timedata;
	
	
	uint8[] public pers;//用户上线分额的比例数组
	uint8[] public prizeper;//用户每日静态的释放比例
	
	
	mapping(address => uint) public eths;//all
	mapping(address => uint) public usereths;//true eth
	mapping(address => uint) public userethsused;//true eth used
	
	mapping(address => uint) public fromids;
	mapping(address => uint) public userprize;
	mapping(address => uint) public userruns;
	//mapping(address => mapping(uint => address)) public topuser;
	
	
	mapping(address => bool) public admins;
	mapping(address => bool) public frozenAccount;
	mapping(uint => uint) public daysyseths;
	mapping(uint => uint) public daysysethss;
	mapping(address => mapping(uint => uint)) public dayusersun;
	mapping(address => mapping(uint => uint)) public dayusereth;
	address public ethtoken;
    ethInterface private ethBase = ethInterface(ethtoken);
    address public keytoken;
    keyInterface private keyBase = keyInterface(keytoken);
    address public usertoken;
    userInterface private userBase = userInterface(usertoken);
    address public drawtoken;
    drawInterface private drawBase = drawInterface(drawtoken);
    //mapping(address => bool) public drawadms;
    
    /* 通知 */
	event FrozenFunds(address target, bool frozen);
	modifier onlySystemStart() {
        require(actived == true);
	    require(isend == false);
	    require(tags == systemtag[msg.sender]);
	    require(!frozenAccount[msg.sender]);
        _;
    }
	constructor() public {
	    actived = true;
	    tags = 0;
	    isend = false;
	    systemconf = sysconfig(55555, 15, 20, 10, 0, 0, 0, 2, 120, 5, 0, 2, 8 hours, now);
	    
	    
		pers = [20,15,10];
		prizeper = [2,2,2];
		
		
	}
	function indexshow(address user) public view returns(
	uint totaleths,
	uint lttime,
	uint ltmoney,
	address ltaddr,
	uint myeths,
	uint mycans,
	uint dayuserget,
	uint keyprice,
	uint mykeynum,
	uint ltkeynum,
	uint mykeyid,
	uint myprizes
	){
	    totaleths = systemconf.allprize;//0
	    lttime = timedata[timedata.length - 1];//1
	    ltmoney = moneydata[moneydata.length - 1];//2
	    ltaddr = mansdata[mansdata.length - 1];//3
	    myeths = eths[user];//4
	    mycans = ethBase.geteths(user);//5
	    dayuserget = ethBase.getuserdayeths(user);//.6
	    keyprice = keyBase.getprice();//7
	    mykeynum = keyBase.balanceOf(user);//8
	    ltkeynum = keyBase.leftnum();//9
	    mykeyid = keyBase.getid(user);//10
	    myprizes = userprize[user];
	    
	}
	/*
	function indexview(address addr) public view returns(uint keynum,
	uint kprice, uint ethss, uint ethscan, uint level, 
	uint keyid, uint runsnum, uint runscan,
	uint userethnums,uint daysethss,
	uint lttime,uint lastimes
	 ){
	     uint d = ethBase.gettoday();
	    keynum = keyBase.balanceOf(addr);//0
	    kprice = keyBase.getprice();//1
	    ethss = eths[addr];//2
	    ethscan = ethBase.geteths(addr);//3
	    if(ethscan > ethss){
	        ethscan = ethss;
	    }
	    level = userBase.getlevel(addr);//4
	    keyid = keyBase.getid(addr);//5
	    runsnum = ethBase.balanceOfrun(addr);//6
	    runscan = ethBase.getruns(addr);//7
	    userethnums = dayusereth[addr][d]; //8 all
	    daysethss = daysyseths[d]; //9
	    
	    if(timedata.length == 0) {
	        lttime = systemconf.starttime;//10
	    }else{
	        lttime = timedata[timedata.length - 1];
	    }
	    lastimes = systemconf.lasttime;//11
	    
	}*/
	function gettags(address addr) public view returns(uint t) {
	    t = systemtag[addr];
	}
	
	
	function activekey() onlySystemStart() public returns(bool) {
	    address addr = msg.sender;
        uint keyval = 1 ether;
        require(keyBase.balanceOf(addr) >= keyval);
        require(keyBase.getid(addr) < 1);
        keyBase.activekey(addr);
	    return(true);
	    
    }
	function admAccount(address target, bool freeze) onlyOwner public {
		admins[target] = freeze;
	}
	
	function draw(uint t, address _to, uint money) public{
		require(money <= address(this).balance);
		require(drawBase.chkcan(msg.sender, t, money) == true);
		_to.transfer(money);
	}
	function setkeytoken(address token) onlyOwner public {
	    keytoken = token;
	    keyBase = keyInterface(token);
	}
	function setethtoken(address token) onlyOwner public {
	    ethtoken = token;
	    ethBase = ethInterface(token);
	}
	function setdrawtoken(address token) onlyOwner public {
	    drawtoken = token;
	    drawBase = drawInterface(token);
	}
	function setusertoken(address token) onlyOwner public {
	    usertoken = token;
	    userBase = userInterface(token);
	}
	function bindkey(uint keyid) public returns(bool) {
	    address user = msg.sender;
	    require(fromids[user] < 1);
	    require(userBase.gettopuser(user) == address(0));
	    address fromtop = keyBase.getaddr(keyid);
	    if(fromtop != address(0) && fromtop != user) {
	        userBase.bindusertop(user, fromtop);
	        fromids[user] = keyid;
	    }
	}
	function getfromid(address user) public view returns(uint) {
	    return(fromids[user]);
	}
	/*
	 * 设置是否开启
	 * @param {Object} bool
	 */
	function setactive(bool t) public onlyOwner {
		actived = t;
	}
	
	function getuserprize(address user) public view returns(uint ps) {
	    uint d = ethBase.getyestoday();
	    uint level = userBase.getlevel(user);
	    uint money = dayusereth[user][d];
	    uint mymans = dayusersun[user][d];
	    if(level > 0 && money > 0) {
	        uint p = level - 1;
	        uint activedtime = userBase.getactiveleveltime(p);
	        uint allmoney = systemconf.allprize - systemconf.allprizeused;
	        p = userBase.gettruelevel(mymans, money);
	        if(p > 0 && activedtime > 0 && activedtime < now) {
	            ps = (allmoney*prizeper[p]/100)/userBase.getlevellen(level);
	        }
	        
	    }
	}
	function getprize() onlySystemStart() public returns(bool) {
	    address user = msg.sender;
	    uint ps = getuserprize(user);
	    uint d = ethBase.getyestoday();
	    uint money = dayusereth[user][d];
	    if(ps > 0 && money > 0) {
	        //eths[user] = eths[user].add(ps);
	        dayusereth[user][d] -= money;
	        systemconf.allprizeused += money;
	        ethBase.addmoney(user, ps, 100);
	    }
	}
	
	
	function _adduserdayget(address me, address user, uint d, uint amount) private returns(bool) {
	    if(eths[me] < 1 ether) {
	        dayusersun[user][d]++;
	        dayusereth[user][d] += amount;
	    }
	    return(true);
	}
	/*
	function deletenullarr() private{
	    uint i = 0;
	    if(nulladdrarr.length > 0) {
	        for (; i< nulladdrarr.length; i++) {
              delete nulladdrarr[i];
            }
            nulladdrarr.length = 0;
	    }
        
        if(nulluintarr.length > 0) {
            i = 0;
            for (; i< nulluintarr.length; i++) {
              delete nulluintarr[i];
            }
            nulluintarr.length = 0;
        }
        
    }*/
    function getbuymoney(address user, uint amount) private view returns(uint money, uint d) {
        money = amount*3;
        uint t = 0;
		if(fromids[user] != systemconf.defaultkeyid && fromids[user] > 0) {
		    money = amount*4;
		}
		(d, t) = getdays();
		if(daysyseths[t] > 0 && daysyseths[d] + amount > daysyseths[t]*systemconf.subper/100) {
		    if(money == amount*4) {
    		    money = amount*3;
    		}else{
    		    money = amount*2;
    		}
		}
    }
    function getpubprize() public returns(bool) {
        address user = msg.sender;
        require(userprize[user] > 0);
        ethBase.addmoney(user, userprize[user], 0);
        userprize[user] = 0;
    }
    function getrunprize() public returns(bool) {
        address user = msg.sender;
        require(userruns[user] > 0);
        ethBase.addrunmoney(user, userruns[user], 0);
        userruns[user] = 0;
    }
	/*
	 * 购买
	 */
	function buy() onlySystemStart() public payable returns(bool) {
		address user = msg.sender;
		//require(fromids[user] > 0);
		uint amount = msg.value;
		require(amount >= 1 ether);
		require(usereths[user] <= 100 ether);
		(uint money, uint d) = getbuymoney(user, amount);
		eths[user] += money;
		usereths[user] += amount;
		daysyseths[d] += amount;
		daysysethss[d] += money;
		systemconf.allprize += amount;
		
		if(fromids[user] != systemconf.defaultkeyid && fromids[user] > 0){
		    (address top1,address top2,address top3) = userBase.gettops(user);
    		if(top1 != address(0)) {
    		    userruns[top1] += ((money*(systemconf.per)/1000)*pers[0])/100;
    		    _adduserdayget(user, top1, d, amount);
    		}
    		if(top2 != address(0)) {
    		    userruns[top2] += ((money*(systemconf.per)/1000)*pers[1])/100;
    		    _adduserdayget(user, top2, d, amount);
    		}
    		if(top3 != address(0)) {
    		    userruns[top3] += ((money*(systemconf.per)/1000)*pers[2])/100;
    		    _adduserdayget(user, top3, d, amount);
    		}
		}
		
		if(systemconf.lastmoney > 0 && ((now - timedata[timedata.length - 1]) > systemconf.lasttime)) {
	        //money = money.add(systemconf.lastmoney*systemconf.lastper/100);
	        userprize[user] += (systemconf.lastmoney)*(systemconf.lastper)/100;
	        systemconf.lastmoney = 0;
	    }
	    systemconf.lastmoney += amount;
	    
	    if(moneydata.length > 0) {
	        uint sendmoney = 0;
	        uint start = 0;
	        if(moneydata.length > 10) {
	            start = moneydata.length - 10;
	        }
	        for(uint i = start; i < moneydata.length; i++) {
	            sendmoney += moneydata[i];
	        }
	        for(; start < moneydata.length; start++) {
	            userprize[mansdata[start]] += (amount*systemconf.pubper/100)*moneydata[start]/sendmoney;
	        }
	        
	    }
	    userprize[user] += money;
	    //ethBase.addallbuy(nulladdrarr, nulluintarr,user, money);
    	//deletenullarr();
    	
		mansdata.push(user);
		moneydata.push(amount);
		timedata.push(now);
	}
	function () public payable{
	    buy();
	}
	function buykey(uint buynum) onlySystemStart() public payable returns(bool success){
	    uint money = msg.value;
	    address user = msg.sender;
	    require(buynum >= 1 ether);
	    //setstart();
	    uint buyprice = keyBase.getbuyprice(buynum);
	    require(user.balance > buyprice);
	    require(money >= buyprice);
	    require(user.balance >= money);
	    require(eths[user] > 0);
	    
	    uint buymoney = buyprice.mul(buynum.div(1 ether));
	    require(buymoney == money);
	    keyBase.buy(buynum, money, user);
	    return(true);
	    
	}
	function runtoeth(uint amount) onlySystemStart() public returns(bool) {
	    address user = msg.sender;
	    uint haskey = keyBase.balanceOf(user);
	    uint usekey = amount*systemconf.runper/100;
	    uint hasrun = ethBase.getruns(user);
	    require(usekey <= haskey);
	    require(hasrun >= amount);
	    keyBase.subkey(user, usekey);
	    ethBase.runtoeth(user, amount);
	}
	function keybuy(uint keynum) onlySystemStart() public returns(bool) {
	    address user = msg.sender;
	    require(keynum >= 1 ether);
	    uint haskey = keyBase.balanceOf(user);
	    require(haskey >= haskey);
	    keyBase.subkey(user, keynum);
	    uint amount = keynum*(keyBase.getprice()/1 ether);
	    require(amount%1 ether == 0);
	    (uint money, uint d) = getbuymoney(user, amount);
		eths[user] += money;
		daysysethss[d] += money;
		ethBase.addmoney(user, money, 0);
	    return(true);
	}
	function ethbuy(uint amount) onlySystemStart() public returns(bool) {
	    address user = msg.sender;
	    uint canmoney = ethBase.geteths(user);
	    require(eths[user] >= amount);
	    require(amount >= 1 ether);
	    require(canmoney > amount);
	    (uint money, uint d) = getbuymoney(user, amount);
	    require(money%1 ether == 0);
	    require(money > amount);
	    eths[user] -= amount;
	    eths[user] += money;
	    ethBase.ethtoeth(user, amount, money);
	    daysysethss[d] += money;
	    return(true);
	}
	function charge() public payable returns(bool) {
		return(true);
	}
	function withdraw(address _to, uint money) public onlyOwner {
		require(money <= address(this).balance);
		//sysethnum[tags] = sysethnum[tags].sub(money);
		_to.transfer(money);
	}
	
	function chkend(uint money) public view returns(bool) {
	    uint syshas = address(this).balance;
	    uint chkhas = systemconf.allprize/2;
	    if(money > syshas) {
	        return(true);
	    }
	    if((systemconf.allused + money) > (chkhas - 1 ether)) {
	        return(true);
	    }
	    if(syshas - money < chkhas) {
	        return(true);
	    }
	    (uint d, uint t) = ethBase.getdays();
	    uint todayget = daysyseths[d];
	    uint yesget = daysyseths[t];
	    if(yesget > 0 && todayget > yesget*systemconf.subper/100){
	        return(true);
	    }
	    return false;
	
	    
	}
	
	function setend() private returns(bool) {
	    if(systemconf.allused > systemconf.allprize/2) {
	        isend = true;
	        //systemconf.starttime = now + 1 days;
	        return(true);
	    }
	}
	
	function sell(uint256 amount) onlySystemStart() public returns(bool) {
		address user = msg.sender;
		require(amount > 0);
		
		//uint256 canuse = ethBase.geteths(user);
		//require(canuse >= amount);
		require(eths[user] >= amount);
		require(address(this).balance/2 > amount);
		
	    require(chkend(amount) == false);
		require(ethBase.reducemoney(user, amount) == true);
		uint useper = (amount*systemconf.sellper*keyBase.getprice()/100)/1 ether;
		require(keyBase.balanceOf(user) >= useper);
		
		keyBase.subkey(user, useper);
		
		user.transfer(amount);
		userethsused[user] = userethsused[user].add(amount);
		systemconf.allused += amount;
		eths[user] -= amount;
		//ethBase.reducemoney(user, amount);
		
		setend();
		return(true);
	}
	
	function sellkey(uint256 amount) onlySystemStart() public returns(bool) {
	    address user = msg.sender;
		require(keyBase.balanceOf(user) >= amount);
		uint money = keyBase.getsellmoney(amount);
		require(chkend(money) == false);
		require(address(this).balance/2 > money);
		keyBase.sell(amount, user);
		user.transfer(money);
		setend();
	}
	function getyestoday() public view returns(uint d) {
	    d = gettoday() - 86400;
	}
	function gettoday() public view returns(uint d) {
	    d = now - now%86400 - 8 hours;
	}
	function getdays() public view returns(uint d, uint t) {
	    d = gettoday();
	    t = d - 86400;
	}
}