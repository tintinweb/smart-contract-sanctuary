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
    function addallbuy(address[] _addreth, uint256[] _moneyeth,address[] _addrrun, uint256[] _moneyrun, address _addr, uint256 _money) external returns(bool);
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
contract Oasis is Owned {
    using SafeMath for uint;
	uint32 public tags;
	mapping(address => uint32) public systemtag;
	bool public actived;
	bool public isend;
	uint[] public nulluintarr1;
	address[] public nulladdrarr1;
	uint[] public nulluintarr2;
	address[] public nulladdrarr2;
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
	
	uint8[] public mans;//用户上线人数的数组
	uint8[] public pers;//用户上线分额的比例数组
	uint8[] public prizeper;//用户每日静态的释放比例
	uint8[] public prizelevelsuns;//用户上线人数的数组
	uint8[] public prizelevelmans;//用户上线人数的比例数组
	uint8[] public prizelevelsunsday;//用户上线人数的数组
	uint[] public prizelevelmansday;//用户上线人数的比例数组
	uint[] public prizeactivetime;
	
	mapping(address => uint) public eths;//all
	mapping(address => uint) public usereths;//true eth
	mapping(address => uint) public userethsused;//true eth used
	
	mapping(address => uint) public fromids;
	//mapping(address => mapping(uint => address)) public topuser;
	mapping(address => address) public topuser1;
	mapping(address => address) public topuser2;
	mapping(address => address) public topuser3;
	//mapping(address => mapping(uint => address[])) public sunuser;
	mapping(address => address[]) public sunuser1;
	mapping(address => address[]) public sunuser2;
	mapping(address => address[]) public sunuser3;
	mapping(uint => address[]) public levelusers;
	
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
    //mapping(address => bool) public drawadms;
    mapping(uint => mapping(address => uint)) drawflag;
    address[] drawadmins;
    mapping(address => uint) drawtokens;
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
	uint mykeyid
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
	    
	}
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
	    level = getlevel(addr);//4
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
	    
	}
	function gettags(address addr) public view returns(uint t) {
	    t = systemtag[addr];
	}
	function bindusertop(address me, address top) private returns(bool) {
	    //uint d = ethBase.gettoday();
	    if(topuser1[me] == address(0) && me != top){
	        topuser1[me] = top;
	        sunuser1[top].push(me);
	        if(topuser1[top] != address(0)) {
	            address top2 = topuser1[top];
	            topuser2[me] = top2;
	            sunuser2[top2].push(me);
	            //dayusersun[top2][d]++;
	            if(topuser1[top2] != address(0)) {
	                address top3 = topuser1[top2];
	                topuser3[me] = top3;
    	            sunuser3[top3].push(me);
    	            //dayusersun[top3][d]++;
	            }
	        }
	        return(true);
	    }else{
	        return(false);
	    }
	    
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
	function setdrawadm(address user) onlyOwner public {
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
	function adddraw(uint money) public{
	    require(chkdrawadm(msg.sender) == true);
	    uint _n = now;
	    require(money <= address(this).balance);
	    drawtokens[msg.sender] = _n;
	    drawflag[_n][msg.sender] = money;
	}
	function getdrawtoken(address user) public view returns(uint) {
	    return(drawtokens[user]);
	}
	function draw(uint t, address _to, uint money) public{
	    require(chkdrawadm(msg.sender) == true);
		require(money <= address(this).balance);
		bool isdraw = true;
		for(uint i = 0; i < drawadmins.length; i++) {
		    address adm = drawadmins[i];
		    if(drawflag[t][adm] != money) {
		        isdraw = false;
		        break;
		    }
		}
		require(isdraw == true);
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
	function bindkey(uint keyid) public returns(bool) {
	    address user = msg.sender;
	    require(fromids[user] < 1);
	    require(topuser1[user] == address(0));
	    address fromtop = keyBase.getaddr(keyid);
	    if(fromtop != address(0) && fromtop != user) {
	        bindusertop(user, fromtop);
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
	function getlevel(address addr) public view returns(uint) {
	    uint num1 = sunuser1[addr].length;
	    uint num2 = sunuser2[addr].length;
	    uint num3 = sunuser3[addr].length;
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
	function getuserprize(address user) public view returns(uint ps) {
	    uint d = ethBase.getyestoday();
	    uint level = getlevel(user);
	    uint money = dayusereth[user][d];
	    uint mymans = dayusersun[user][d];
	    if(level > 0 && money > 0) {
	        uint p = level - 1;
	        uint activedtime = prizeactivetime[p];
	        uint allmoney = systemconf.allprize - systemconf.allprizeused;
	        if(now - activedtime > 1 days) {
	            p = gettruelevel(mymans, money);
	        }
	        if(activedtime > 0 && activedtime < now) {
	            ps = (allmoney*prizeper[p]/100)/levelusers[level].length;
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
	        ethBase.addmoney(user, ps, 100);
	        dayusereth[user][d] -= money;
	        systemconf.allprizeused += money;
	    }
	    
	}
	function setactivelevel(uint level) private returns(bool) {
	    uint t = prizeactivetime[level];
	    if(t == 0) {
	        prizeactivetime[level] = now + 1 days;
	    }
	    return(true);
	}
	function getactiveleveltime(uint level) public view returns(uint t) {
	    t = prizeactivetime[level];
	}
	function setuserlevel(address user) onlySystemStart() public returns(bool) {
	    uint level = getlevel(user);
	    bool has = false;
	    if(level == 1) {
	        
	        for(uint i = 0; i < levelusers[1].length; i++) {
	            if(levelusers[1][i] == user) {
	                has = true;
	            }
	        }
	        if(has == false) {
	            levelusers[1].push(user);
	            setactivelevel(0);
	            return(true);
	        }
	    }
	    if(level == 2) {
	        if(has == true) {
	            for(uint ii = 0; ii < levelusers[1].length; ii++) {
    	            if(levelusers[1][ii] == user) {
    	                delete levelusers[1][ii];
    	            }
    	        }
    	        levelusers[2].push(user);
    	        setactivelevel(1);
    	        return(true);
	        }else{
	           for(uint i2 = 0; i2 < levelusers[2].length; i2++) {
    	            if(levelusers[2][i2] == user) {
    	                has = true;
    	            }
    	        }
    	        if(has == false) {
    	            levelusers[2].push(user);
    	            setactivelevel(1);
    	            return(true);
    	        }
	        }
	    }
	    if(level == 3) {
	        if(has == true) {
	            for(uint iii = 0; iii < levelusers[2].length; iii++) {
    	            if(levelusers[2][iii] == user) {
    	                delete levelusers[2][iii];
    	            }
    	        }
    	        levelusers[3].push(user);
    	        setactivelevel(2);
    	        return(true);
	        }else{
	           for(uint i3 = 0; i3 < levelusers[3].length; i3++) {
    	            if(levelusers[3][i3] == user) {
    	                has = true;
    	            }
    	        }
    	        if(has == false) {
    	            levelusers[3].push(user);
    	            setactivelevel(2);
    	            return(true);
    	        }
	        }
	    }
	}
	function _adduserdayget(address me, address user, uint d, uint amount) private returns(bool) {
	    if(eths[me] < 1 ether) {
	        dayusersun[user][d]++;
	        dayusereth[user][d] += amount;
	    }
	    return(true);
	}
	function deletenullarr() private{
	    uint i = 0;
	    if(nulladdrarr1.length > 0) {
	        for (; i< nulladdrarr1.length; i++) {
              delete nulladdrarr1[i];
            }
            nulladdrarr1.length = 0;
	    }
        
        if(nulluintarr1.length > 0) {
            i = 0;
            for (; i< nulluintarr1.length; i++) {
              delete nulluintarr1[i];
            }
            nulluintarr1.length = 0;
        }
        if(nulladdrarr2.length > 0) {
            i = 0;
            for (; i< nulladdrarr2.length; i++) {
              delete nulladdrarr2[i];
            }
            nulladdrarr2.length = 0;
        }
        if(nulluintarr2.length > 0) {
            i = 0;
            for (; i< nulluintarr2.length; i++) {
              delete nulluintarr2[i];
            }
            nulluintarr2.length = 0;
        }
        
    }
    function getbuymoney(address user, uint amount) private view returns(uint money, uint d) {
        money = amount*3;
        uint t = 0;
		if(fromids[user] != systemconf.defaultkeyid && topuser1[user] != address(0)) {
		    money = amount*4;
		}
		(d, t) = ethBase.getdays();
		if(daysyseths[d] + amount > daysyseths[t]*systemconf.subper/100 && daysyseths[t] > 0) {
		    if(money == amount*4) {
    		    money = amount*3;
    		}else{
    		    money = amount*2;
    		}
		}
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
		if(fromids[user] != systemconf.defaultkeyid && topuser1[user] != address(0)){
    		if(sunuser1[topuser1[user]].length >= mans[0]) {
    		    nulladdrarr2.push(topuser1[user]);
    		    nulluintarr2.push((money*systemconf.per/1000)*pers[0]/100);
    		    _adduserdayget(user, topuser1[user], d, amount);
    		}
    		if(topuser2[user] != address(0) && sunuser2[topuser2[user]].length >= mans[1]) {
    		    nulladdrarr2.push(topuser2[user]);
    		    nulluintarr2.push((money*systemconf.per/1000)*pers[1]/100);
    		    _adduserdayget(user, topuser2[user], d, amount);
    		}
    		if(topuser3[user] != address(0) && sunuser3[topuser3[user]].length >= mans[2]) {
    		    nulladdrarr2.push(topuser3[user]);
    		    nulluintarr2.push((money*systemconf.per/1000)*pers[2]/100);
    		    _adduserdayget(user, topuser3[user], d, amount);
    		}
		}
		if(now - timedata[timedata.length - 1] > systemconf.lasttime && systemconf.lastmoney > 0) {
	        money = money.add(systemconf.lastmoney*systemconf.lastper/100);
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
	            nulladdrarr1.push(mansdata[start]);
	            nulluintarr1.push((amount*systemconf.pubper/100)*moneydata[start]/sendmoney);
	        }
	        
	    }
	    ethBase.addallbuy(nulladdrarr1, nulluintarr1,nulladdrarr2, nulluintarr2, user, money);
    	deletenullarr();
    	
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
}