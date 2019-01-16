pragma solidity ^ 0.4.25;
contract Oasis{
	string public symbol;
	string public name;
	uint8 public decimals;
	uint _totalSupply;
	
	address owner;
	bool public actived;
	struct keyconf{
	    uint basekeynum;//4500
    	uint basekeysub;//500
    	uint usedkeynum;//0
        uint startprice;//0.01
        uint keyprice;//0.01
        uint startbasekeynum;//4500
        uint[] keyidarr;
    	uint currentkeyid;
	}
	keyconf private keyconfig;
	uint[] public worksdata;
	
	uint public onceOuttime;
	uint8 public per;
	
	
	uint[] public mans;
	uint[] public pers;
	uint[] public prizeper;
	uint[] public prizelevelsuns;
	uint[] public prizelevelmans;
	uint[] public prizelevelsunsday;
	uint[] public prizelevelmoneyday;
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
	
	//bool public isend;
	uint public tags;
	//uint public opentime;
	
	uint public runper;
	uint public sellper;
	uint public sysday;
	uint public cksysday;
	uint public nulldayeth;
    mapping(uint => mapping(uint => uint)) allprize;
	//uint public allprizeused;
	mapping(address => uint) balances;
	
	mapping(address => mapping(address => uint)) allowed;
	mapping(address => bool) public frozenAccount;
	struct usercan{
	    uint eths;
	    uint used;
	    uint len;
	    uint[] times;
	    uint[] moneys;
	    uint[] amounts;
	}
	mapping(address => usercan) mycan;
	mapping(address => usercan) myrun;
	struct userdata{
	    uint systemtag;
	    uint tzs;
	    uint usereths;
	    uint userethsused;
	    uint mylevelid;
	    uint mykeysid;
	    uint mykeyeths;
	    uint prizecount;
	    address fromaddr;
	    uint sun1;
	    uint sun2;
	    uint sun3;
	    //address[] mysuns;
	    //address[] mysecond;
	    //address[] mythird;
	    
	    mapping(uint => uint) mysunsdaynum;
	    mapping(uint => uint) myprizedayget;
	    mapping(uint => uint) daysusereths;
	    mapping(uint => uint) daysuserdraws;
	    mapping(uint => uint) daysuserlucky;
	    mapping(uint => uint) levelget;
	}
	mapping(address => userdata) my;
	uint[] public leveldata;
	mapping(uint => mapping(uint => uint)) public userlevelsnum;

	//与用户钥匙id对应
	mapping(uint => address) public myidkeys;
	//all once day get all
	mapping(uint => uint) public daysgeteths;
	mapping(uint => uint) public dayseths;
	//user once day pay
	mapping(uint => uint) public daysysdraws;
	struct tagsdata{
	    uint ethnum;//用户总资产
	    uint sysethnum;//系统总eth
	    uint userethnum;//用户总eth
	    uint userethnumused;//用户总eth
	    uint syskeynum;//系统总key
	}
	mapping(uint => tagsdata) tg;
	mapping(address => bool) mangeruser;
	mapping(address => uint) mangerallowed;
	/*
	struct sysnotice{
	    string version;
	    string downurl;
	    string notices;
	    string aboutus;
	    string contractus;
	    string others;
	}
	sysnotice systemnotice;
	*/
	string private version;
	string private downurl;
	/* 通知 */
	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
	event FrozenFunds(address target, bool frozen);
	modifier onlySystemStart() {
        require(actived == true);
	    require(tags == my[msg.sender].systemtag);
	    require(!frozenAccount[msg.sender]);
        _;
    }

	constructor() public {
		symbol = "OASIS";
		name = "Oasis";
		decimals = 18;
		_totalSupply = 50000000 ether;
	
		actived = true;
		tags = 0;
		tg[0] = tagsdata(0,0,0,0,0);
		
        keyconfig.currentkeyid = 0;
        keyconfig.keyidarr = [10055555,20055555,30055555,40055555,50055555,60055555,70055555,80055555,90055555];
        worksdata = [0,0,0,0,0,0,0,0,0];   
        runper = 20;
		mans = [2,4,6];
		pers = [20,15,10];
		prizeper = [2,2,2];
		prizeactivetime = [0,0,0];
		pubper = 2;
		subper = 120;
		luckyper = 5;
		lastmoney = 0;
		lastper = 2;
		sellkeyper = 70;
		sellper = 10;	
		leveldata = [0,0,0];
		
        /*
        onceOuttime = 16 hours;
        nulldayeth = 100 ether;
        basekeynum = 4500 ether;//4500
	    basekeysub = 500 ether;//500
	    usedkeynum = 0;//0
        startprice = 0.01 ether;//
        keyprice   = 0.01 ether;//
        startbasekeynum = 4500 ether;//4500
        per = 15;  
        prizelevelsuns = [20,30,50];
		prizelevelmans = [100,300,800];
		prizelevelsunsday = [2,4,6];
		prizelevelmoneyday = [10 ether,30 ether,50 ether];
		lasttime = 8 hours;
		sysday = 1 days;
		cksysday = 8 hours;
		*/
        
        onceOuttime = 600 seconds;//test
        nulldayeth = 5 ether;//test
        keyconfig.startprice = 0.01 ether;//test
        keyconfig.keyprice   = 0.01 ether;//test
        keyconfig.basekeynum = 450 ether;//test
        keyconfig.basekeysub = 50 ether;//test
        keyconfig.usedkeynum = 0;//test
        keyconfig.startbasekeynum = 450 ether;//test
        per = 100;//test
        prizelevelsuns = [2,2,2];//test
		prizelevelmans = [6,7,8];//test
		prizelevelsunsday = [1,2,3];//test
		prizelevelmoneyday = [1 ether,3 ether,5 ether];//test
		lasttime = 1800 seconds;//test
		sysday = 600 seconds; //test
		cksysday = 0 seconds;//test
        version = &#39;1.01&#39;;
		balances[this] = _totalSupply;
		owner = msg.sender;
		emit Transfer(address(0), this, _totalSupply);
	}

	function balanceOf(address tokenOwner) public view returns(uint balance) {
		return balances[tokenOwner];
	}
	
	function showlvzhou(address user) public view returns(
	    uint total,
	    uint mykeyid,
	    uint mytzs,
	    uint daysget,
	    uint prizeget,
	    uint mycans,
	    uint mykeynum,
	    uint keyprices,
	    uint ltkeynum,
	    uint tagss,
	    uint mytags
	    
	){
	    total = tg[tags].userethnum;//0
	    mykeyid = my[user].mykeysid;//1
	    mytzs = my[user].tzs;//2
	    daysget = my[user].usereths*per/1000;//3
	    prizeget = my[user].prizecount;//4
	    mycans = getcanuse(user);//5
	    mykeynum = balanceOf(user);//6
	    keyprices = getbuyprice();//7
	    ltkeynum = leftnum();//8
	    tagss = tagss;//9
	    mytags = my[user].systemtag;//10
	}
	function showteam(address user) public view returns(
	    uint daysnum,//0
	    uint dayseth,//1
	    uint daysnum1,//2
	    uint dayseth1,//3
	    uint man1,//4
	    uint man2,//5
	    uint man3,//6
	    uint myruns,//7
	    uint canruns,//8
	    uint levelid//9
	){
	    uint d = gettoday();
	    uint t = getyestoday();
	    daysnum = my[user].mysunsdaynum[d];//5
	    dayseth = my[user].myprizedayget[d];//6
	    daysnum1 = my[user].mysunsdaynum[t];//5
	    dayseth1 = my[user].myprizedayget[t];//6
	    man1 = my[user].sun1;//2
	    man2 = my[user].sun2;//3
	    man3 = my[user].sun3;//4
	    myruns = myrun[user].eths;//6
	    canruns = getcanuserun(user);//7
	    levelid = my[user].mylevelid;//8
	}
	function showlevel(address user) public view returns(
	    uint myget,//0
	    uint levelid,//1
	    uint len1,//2
	    uint len2,//3
	    uint len3,//4
	    uint m1,//5
	    uint m2,//6
	    uint m3,//7
	    uint t1,//8
	    uint t2,//9
	    uint t3,//10
	    uint levelget//11
	){
	    (levelid, myget) = getprizemoney(user);
	    //len2 = leveldata[1];
	    //len3 = leveldata[2];
	    m1 = allprize[0][0] - allprize[0][1];//5
	    m2 = allprize[1][0] - allprize[1][1];//6
	    m3 = allprize[2][0] - allprize[2][1];//7
	    t1 = prizeactivetime[0];//8
	    uint d = getyestoday();
	    if(t1 + sysday < now){
	        len1 = leveldata[0];
	    }else{
	        len1 = userlevelsnum[1][d];
	    }
	    t2 = prizeactivetime[1];//9
	    if(t2 + sysday < now){
	        len2 = leveldata[1];
	    }else{
	        len2 = userlevelsnum[2][d];
	    }
	    t3 = prizeactivetime[2];//10
	    if(t3 + sysday < now){
	        len3 = leveldata[2];
	    }else{
	        len3 = userlevelsnum[3][d];
	    }
	    levelget = my[user].levelget[d];//11
	}
	
	
	function showethconf(address user) public view returns(
	    uint todaymyeth,
	    uint todaymydraw,
	    uint todaysyseth,
	    uint todaysysdraw,
	    uint yestodaymyeth,
	    uint yestodaymydraw,
	    uint yestodaysyseth,
	    uint yestodaysysdraw
	){
	    uint d = gettoday();
		uint t = getyestoday();
		todaymyeth = my[user].daysusereths[d];
		todaymydraw = my[user].daysuserdraws[d];
		todaysyseth = dayseths[d];
		todaysysdraw = daysysdraws[d];
		yestodaymyeth = my[user].daysusereths[t];
		yestodaymydraw = my[user].daysuserdraws[t];
		yestodaysyseth = dayseths[t];
		yestodaysysdraw = daysysdraws[t];
		
	}
	function showprize(address user) public view returns(
	    uint lttime,//0
	    uint ltmoney,//1
	    address ltaddr,//2
	    uint lastmoneys,//3
	    address lastuser,//4
	    uint luckymoney,//5
	    address luckyuser,//6
	    uint luckyget//7
	){
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
	    lastmoneys = lastmoney;
	    lastuser = getlastuser();
	    uint d = getyestoday();
	    if(dayseths[d] > 0) {
	        luckymoney = dayseths[d]*luckyper/1000;
	        luckyuser = getluckyuser();
	        luckyget = my[user].daysuserlucky[d];
	    }
	    
	}
	function interuser(address user) public view returns(
	    uint skeyid,
	    uint stzs,
	    uint seths,
	    uint sethcan,
	    uint sruns,
	    uint srunscan,
	    uint skeynum
	    
	){
	    skeyid = my[user].mykeysid;
	    stzs = my[user].tzs;
	    seths = mycan[user].eths;
	    sethcan = getcanuse(user);
	    sruns = myrun[user].eths;
	    srunscan = getcanuserun(user);
	    skeynum = balances[user];
	}
	function showworker() public view returns(
	    uint w0,
	    uint w1,
	    uint w2,
	    uint w3,
	    uint w4,
	    uint w5,
	    uint w6,
	    uint w7,
	    uint w8
	){
	    w0 = worksdata[0];
	    w1 = worksdata[1];
	    w2 = worksdata[2];
	    w3 = worksdata[3];
	    w4 = worksdata[4];
	    w5 = worksdata[5];
	    w6 = worksdata[6];
	    w7 = worksdata[7];
	    w8 = worksdata[8];
	}
	
	function addmoney(address _addr, uint256 _amount, uint256 _money, uint _day) private returns(bool){
		mycan[_addr].eths += _money;
		mycan[_addr].len++;
		mycan[_addr].amounts.push(_amount);
		mycan[_addr].moneys.push(_money);
		if(_day > 0){
		    mycan[_addr].times.push(0);
		}else{
		    mycan[_addr].times.push(now);
		}
		
	}
	function reducemoney(address _addr, uint256 _money) private returns(bool){
	    if(mycan[_addr].eths >= _money && my[_addr].tzs >= _money) {
	        mycan[_addr].used += _money;
    		mycan[_addr].eths -= _money;
    		my[_addr].tzs -= _money;
    		return(true);
	    }else{
	        return(false);
	    }
		
	}
	function addrunmoney(address _addr, uint256 _amount, uint256 _money, uint _day) private {
		myrun[_addr].eths += _money;
		myrun[_addr].len++;
		myrun[_addr].amounts.push(_amount);
		myrun[_addr].moneys.push(_money);
		if(_day > 0){
		    myrun[_addr].times.push(0);
		}else{
		    myrun[_addr].times.push(now);
		}
	}
	function reducerunmoney(address _addr, uint256 _money) private {
		myrun[_addr].eths -= _money;
		myrun[_addr].used += _money;
	}

	function getcanuse(address user) public view returns(uint _left) {
		if(mycan[user].len > 0) {
		    for(uint i = 0; i < mycan[user].len; i++) {
    			uint stime = mycan[user].times[i];
    			if(stime == 0) {
    			    _left += mycan[user].moneys[i];
    			}else{
    			    if(now - stime >= onceOuttime) {
    			        uint smoney = mycan[user].amounts[i] * ((now - stime)/onceOuttime) * per/ 1000;
    			        if(smoney <= mycan[user].moneys[i]){
    			            _left += smoney;
    			        }else{
    			            _left += mycan[user].moneys[i];
    			        }
    			    }
    			    
    			}
    		}
		}
		if(_left < mycan[user].used) {
			return(0);
		}
		if(_left > mycan[user].eths) {
			return(mycan[user].eths);
		}
		return(_left - mycan[user].used);
		
	}
	function getcanuserun(address user) public view returns(uint _left) {
		if(myrun[user].len > 0) {
		    for(uint i = 0; i < myrun[user].len; i++) {
    			uint stime = myrun[user].times[i];
    			if(stime == 0) {
    			    _left += myrun[user].moneys[i];
    			}else{
    			    if(now - stime >= onceOuttime) {
    			        uint smoney = myrun[user].amounts[i] * ((now - stime)/onceOuttime) * per/ 1000;
    			        if(smoney <= myrun[user].moneys[i]){
    			            _left += smoney;
    			        }else{
    			            _left += myrun[user].moneys[i];
    			        }
    			    }
    			}
    		}
		}
		if(_left < myrun[user].used) {
			return(0);
		}
		if(_left > myrun[user].eths) {
			return(myrun[user].eths);
		}
		return(_left - myrun[user].used);
	}

	function _transfer(address from, address to, uint tokens) private{
		require(!frozenAccount[from]);
		require(!frozenAccount[to]);
		require(actived == true);
		require(from != to);
        require(to != 0x0);
        require(balances[from] >= tokens);
        require(balances[to] + tokens > balances[to]);
        uint previousBalances = balances[from] + balances[to];
        balances[from] -= tokens;
        balances[to] += tokens;
        assert(balances[from] + balances[to] == previousBalances);
        
		emit Transfer(from, to, tokens);
	}
    function transfer(address _to, uint256 _value) onlySystemStart() public returns(bool){
        _transfer(msg.sender, _to, _value);
        return(true);
    }
    function activekey() onlySystemStart() public returns(bool) {
	    address addr = msg.sender;
        uint keyval = 1 ether;
        require(balances[addr] > keyval);
        require(my[addr].mykeysid < 1);
        address top = my[addr].fromaddr;
        uint topkeyids = keyconfig.currentkeyid;
        if(top != address(0) && my[top].mykeysid > 0) {
            topkeyids = my[top].mykeysid/10000000 - 1;
        }else{
            keyconfig.currentkeyid++;
            if(keyconfig.currentkeyid > 8){
                keyconfig.currentkeyid = 0;
            }
        }
        keyconfig.keyidarr[topkeyids]++;
        uint kid = keyconfig.keyidarr[topkeyids];
        require(myidkeys[kid] == address(0));
        my[addr].mykeysid = kid;
	    myidkeys[kid] = addr;
	    balances[addr] -= keyval;
	    balances[owner] += keyval;
	    emit Transfer(addr, owner, keyval);
	    return(true);
	    
    }
    
	function getfrom(address _addr) public view returns(address) {
		return(my[_addr].fromaddr);
	}
    function gettopid(address addr) public view returns(uint) {
        address topaddr = my[addr].fromaddr;
        if(topaddr == address(0)) {
            return(0);
        }
        uint keyid = my[topaddr].mykeysid;
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

	function allowance(address tokenOwner, address spender) public view returns(uint remaining) {
		return allowed[tokenOwner][spender];
	}

	function freezeAccount(address target, bool freeze) public {
		require(msg.sender == owner);
		frozenAccount[target] = freeze;
		emit FrozenFunds(target, freeze);
	}
	
	function setactive(bool t) public {
	    require(msg.sender == owner);
		actived = t;
	}
    
	function mintToken(address target, uint256 mintedAmount) public{
	    require(msg.sender == owner);
		require(!frozenAccount[target]);
		require(actived == true);
		require(mintedAmount < balances[this]*20/100);
		balances[target] += mintedAmount;
		balances[this] -= mintedAmount;
		emit Transfer(this, target, mintedAmount);
	}
	
	function getyestoday() public view returns(uint d) {
	    uint today = gettoday();
	    d = today - sysday;
	}
	
	function gettoday() public view returns(uint d) {
	    uint n = now;
	    d = n - n%sysday - cksysday;
	}
	function totalSupply() public view returns(uint) {
		return(_totalSupply - balances[this]);
	}

	function getbuyprice() public view returns(uint kp) {
        if(keyconfig.usedkeynum == keyconfig.basekeynum) {
            kp = keyconfig.keyprice + keyconfig.startprice;
        }else{
            kp = keyconfig.keyprice;
        }
	    
	}
	function leftnum() public view returns(uint num) {
	    if(keyconfig.usedkeynum == keyconfig.basekeynum) {
	        num = keyconfig.basekeynum + keyconfig.basekeysub;
	    }else{
	        num = keyconfig.basekeynum - keyconfig.usedkeynum;
	    }
	}
	
	function getlevel(address addr) public view returns(uint) {
	    uint nums = my[addr].sun1 + my[addr].sun2 + my[addr].sun3;
	    if(my[addr].sun1 >= prizelevelsuns[2] && nums >= prizelevelmans[2]) {
	        return(3);
	    }
	    if(my[addr].sun1 >= prizelevelsuns[1] && nums >= prizelevelmans[1]) {
	        return(2);
	    }
	    if(my[addr].sun1 >= prizelevelsuns[0] && nums >= prizelevelmans[0]) {
	        return(1);
	    }
	    return(0);
	}
	
	function gettruelevel(address user) public view returns(uint) {
	    uint d = getyestoday();
	    uint money = my[user].myprizedayget[d];
	    uint mymans = my[user].mysunsdaynum[d];
	    if(mymans >= prizelevelsunsday[2] && money >= prizelevelmoneyday[2]) {
	        if(my[user].mylevelid != 3){
	            return(my[user].mylevelid);
	        }else{
	           return(3); 
	        }
	        
	    }
	    if(mymans >= prizelevelsunsday[1] && money >= prizelevelmoneyday[1]) {
	        if(my[user].mylevelid != 2){
	            return(my[user].mylevelid);
	        }else{
	           return(2); 
	        }
	    }
	    if(mymans >= prizelevelsunsday[0] && money >= prizelevelmoneyday[0]) {
	        if(my[user].mylevelid != 1){
	            return(my[user].mylevelid);
	        }else{
	           return(1); 
	        }
	    }
	    return(0);
	    
	}
	function getprizemoney(address user) public view returns(uint lid, uint ps) {
	    lid = my[user].mylevelid;
	    if(lid > 0) {
	        uint p = lid - 1;
	        uint activedtime = prizeactivetime[p];
	        if(activedtime > 0 && activedtime < now) {
	            if(now  > activedtime  + sysday){
	                lid = gettruelevel(user);
	                p = lid - 1;
	            }
	            if(lid > 0 && allprize[p][0] > allprize[p][1]){
	                if(now  < activedtime  + sysday){
	                    ps = (allprize[p][0] - allprize[p][1])/leveldata[p];
	                }else{
	                    ps = (allprize[p][0] - allprize[p][1])/userlevelsnum[lid][getyestoday()];
	                }
	            }
	        }
	    }
	}
	function getprize() onlySystemStart() public returns(bool) {
	    
	    address user = msg.sender;
	    if(my[user].mylevelid > 0) {
	        (uint lid, uint ps) = getprizemoney(user);
	        if(lid > 0 && ps > 0) {
	            uint d = getyestoday();
	            require(my[user].levelget[d] == 0);
        	    my[user].levelget[d] += ps;
        	    allprize[lid - 1][1] += ps;
        	    addrunmoney(user, ps, ps, 100);
	        }
	    }
	}
	
	function setlevel(address user) private returns(bool) {
	    uint lid = getlevel(user);
	    uint uid = my[user].mylevelid;
	    uint d = gettoday();
	    if(uid < lid) {
	        if(uid > 0) {
	            leveldata[uid - 1]--;
	        }
	        my[user].mylevelid = lid;
	        uint p = lid - 1;
	        leveldata[p]++;
	        if(prizeactivetime[p] < 1) {
	            prizeactivetime[p] = d + sysday*2;
	        }
	    }
	    if(my[user].mylevelid > 0) {
	        uint tid = gettruelevel(user);
	        if(tid > 0) {
	           userlevelsnum[tid][d]++; 
	        }
	    }
	}
	
	function getfromsun(address addr, uint money, uint amount) private returns(bool){
	    address f1 = my[addr].fromaddr;
	    address f2 = my[f1].fromaddr;
	    address f3 = my[f2].fromaddr;
	    uint d = gettoday();
	    if(f1 != address(0) && f1 != addr) {
	        if(my[f1].sun1 >= mans[0]){
	            addrunmoney(f1, (amount*pers[0])/100, (money*pers[0])/100, 0);
	        }
	    	my[f1].myprizedayget[d] += amount;
	    	if(my[f1].mykeysid > 10000000) {
	    	    worksdata[((my[f1].mykeysid/10000000) - 1)] += amount;
	    	}
	    	setlevel(f1);
	    }
	    if(f2 != address(0) && f2 != addr) {
	        if(my[f2].sun1 >= mans[1]){
	           addrunmoney(f2, (amount*pers[1])/100, (money*pers[1])/100, 0); 
	        }
	    	my[f2].myprizedayget[d] += amount;
	    	setlevel(f2);
	    }
	    if(f3 != address(0) && f3 != addr) {
	        if(my[f3].sun1 >= mans[2]){
	            addrunmoney(f3, (amount*pers[2])/100, (money*pers[2])/100, 0);
	        }
	    	my[f3].myprizedayget[d] += amount;
	    	setlevel(f3);
	    }
	    
	}
	function setpubprize(uint sendmoney) private returns(bool) {
	    uint len = moneydata.length;
	    if(len > 0) {
	        uint all = 0;
	        uint start = 0;
	        uint m = 0;
	        if(len > 10) {
	            start = len - 10;
	        }
	        for(uint i = start; i < len; i++) {
	            all += moneydata[i];
	        }
	        //uint sendmoney = amount*pubper/100;
	        for(; start < len; start++) {
	            m = (sendmoney*moneydata[start])/all;
	            addmoney(mansdata[start],m, m, 100);
	            my[mansdata[start]].prizecount += m;
	        }
	    }
	    return(true);
	}
	function getluckyuser() public view returns(address addr) {
	    if(moneydata.length > 0){
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
	    
	}
	function getluckyprize() onlySystemStart() public returns(bool) {
	    address user = msg.sender;
	    require(user != address(0));
	    require(user == getluckyuser());
	    uint d = getyestoday();
	    require(my[user].daysusereths[d] > 0);
	    require(my[user].daysuserlucky[d] == 0);
	    uint money = dayseths[d]*luckyper/1000;
	    addmoney(user, money,money, 100);
	    my[user].daysuserlucky[d] += money;
	    my[user].prizecount += money;
	    uint t = getyestoday() - sysday;
	    for(uint i = 0; i < moneydata.length; i++) {
    	    if(timedata[i] < t) {
    	        delete moneydata[i];
    	        delete timedata[i];
    	        delete mansdata[i];
    	    }
    	}
	}
	
	function runtoeth(uint amount) onlySystemStart() public returns(bool) {
	    address user = msg.sender;
	    uint usekey = ((amount*runper/100)/keyconfig.keyprice)*1 ether;
	    require(usekey < balances[user]);
	    require(getcanuserun(user) >= amount);
	    require(transfer(owner, usekey) == true);
	    reducerunmoney(user, amount);
	    addmoney(user, amount, amount, 100);
	    
	}
	function getlastuser() public view returns(address user) {
	    if(timedata.length > 0) {
    	    if(lastmoney > 0 && now - timedata[timedata.length - 1] > lasttime) {
    	        user = mansdata[mansdata.length - 1];
    	    }
	    } 
	}
	function getlastmoney() public returns(bool) {
	    address user = getlastuser();
	    require(user != address(0));
	    require(user == msg.sender);
	    require(lastmoney > 0);
	    require(lastmoney <= address(this).balance/2);
	    user.transfer(lastmoney);
	    lastmoney = 0;
	}
	
	function buy(uint keyid) onlySystemStart() public payable returns(bool) {
		address user = msg.sender;
		require(msg.value > 0);
        uint amount = msg.value;
		require(amount >= 1 ether);
		require(amount%(1 ether) == 0);
		require(my[user].usereths <= 100 ether);
		uint money = amount*3;
		uint d = gettoday();
		uint t = getyestoday();
		bool ifadd = false;
		//if has no top
		if(my[user].fromaddr == address(0)) {
		    address topaddr = myidkeys[keyid];
		    if(keyid > 0 && topaddr != address(0) && topaddr != user) {
		        my[user].fromaddr = topaddr;
    		    my[topaddr].sun1++;
    		    my[topaddr].mysunsdaynum[d]++;
    		    address top2 = my[topaddr].fromaddr;
    		    if(top2 != address(0) && top2 != user){
    		        my[top2].sun2++;
    		        my[top2].mysunsdaynum[d]++;
    		    }
    		    address top3 = my[top2].fromaddr;
    		    if(top3 != address(0) && top3 != user){
    		        my[top3].sun3++;
    		        my[top3].mysunsdaynum[d]++;
    		    }
    		    ifadd = true;
		    }
		}else{
		    ifadd = true;
		}
		if(ifadd == true) {
		    money = amount*4;
		}
		//uint yeseths = nulldayeth;
		if(daysgeteths[t] > 0) {
		    nulldayeth = daysgeteths[t];
		}
		if(daysgeteths[d] > (nulldayeth*subper)/100) {
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
	    tg[tags].sysethnum += amount;
		tg[tags].userethnum += amount;
		my[user].daysusereths[d] += amount;
		
		my[user].tzs += money;
		lastmoney += amount*lastper/100;
		tg[tags].ethnum += money;
		my[user].usereths += amount;
		allprize[0][0] += amount*prizeper[0]/100;
		allprize[1][0] += amount*prizeper[1]/100;
		allprize[2][0] += amount*prizeper[2]/100;
		addmoney(user, amount, money, 0);
		return(true);
	}
	
	function keybuy(uint m) onlySystemStart() public returns(bool) {
	    address user = msg.sender;
	    require(m >= 1 ether);
	    require(m >= balances[user]);
	    uint amount = (m*keyconfig.keyprice)/1 ether;
	    require(amount >= 1 ether);
	    require(amount%(1 ether) == 0);
	    //require(transfer(owner, m) == true);
	    
	    //moneybuy(user, money);
	    uint money = amount*4;
		uint d = gettoday();
		uint t = getyestoday();
		if(my[user].fromaddr == address(0)) {
		    money = amount*3;
		}
		//uint yeseths = nulldayeth;
		if(daysgeteths[t] > 0) {
		    nulldayeth = daysgeteths[t];
		}
		if(daysgeteths[d] > nulldayeth*subper/100) {
		    if(my[user].fromaddr == address(0)) {
    		    money = amount*2;
    		}else{
    		    money = amount*3;
    		}
		}
		tg[tags].ethnum += money;
		my[user].tzs += money;
		addmoney(user, amount, money, 0);
		balances[user] -= m;
	    balances[owner] += m;
		emit Transfer(user, owner, m);
	    return(true);
	}
	function ethbuy(uint amount) onlySystemStart() public returns(bool) {
	    address user = msg.sender;
	    uint canmoney = getcanuse(user);
	    require(canmoney >= amount);
	    require(amount >= 1 ether);
	    require(amount%(1 ether) == 0);
	    require(mycan[user].eths >= amount);
	    require(my[user].tzs >= amount);
	    uint money = amount*3;
		uint d = gettoday();
		uint t = getyestoday();
		if(my[user].fromaddr == address(0)) {
		    money = amount*2;
		}
		//uint yeseths = nulldayeth;
		if(daysgeteths[t] > 0) {
		    nulldayeth = daysgeteths[t];
		}
		if(daysgeteths[d] > nulldayeth*subper/100) {
		    if(my[user].fromaddr == address(0)) {
    		    money = amount;
    		}else{
    		    money = amount*2;
    		}
		}
		//eths[user] += money;
		
		addmoney(user, amount, money, 0);
		my[user].tzs += money;
		mycan[user].used += money;
	    tg[tags].ethnum += money;
	    
	    return(true);
	}
	
	function charge() public payable returns(bool) {
		return(true);
	}
	
	function() payable public {
		buy(0);
	}
	
	function setnewowner(address user) public {
	    require(msg.sender == owner);
	    owner = user;
	}
	
	function sell(uint256 amount) onlySystemStart() public returns(bool success) {
		address user = msg.sender;
		require(amount > 0);
		uint d = gettoday();
		uint t = getyestoday();
		uint256 canuse = getcanuse(user);
		require(canuse >= amount);
		require(address(this).balance/2 > amount);
		if(my[user].daysusereths[d] > 0) {
		    require((my[user].daysuserdraws[d] + amount) < (my[user].daysusereths[d]*subper/100));
		}else{
		    require(dayseths[t] > 0);
		    require((daysysdraws[d] + amount) < (dayseths[t]*subper/100));
		}
		
		uint useper = (amount*sellper/keyconfig.keyprice)*(1 ether)/100;
		require(balances[user] >= useper);
		require(reducemoney(user, amount) == true);
		
		my[user].userethsused += amount;
		tg[tags].userethnumused += amount;
		my[user].daysuserdraws[d] += amount;
		daysysdraws[d] += amount;
		//_transfer(user, owner, useper);
		balances[user] -= useper;
	    balances[owner] += useper;
		emit Transfer(user, owner, useper);
		user.transfer(amount);
		
		setend();
		return(true);
	}
	
	function sellkey(uint256 amount) onlySystemStart() public returns(bool) {
	    address user = msg.sender;
		require(balances[user] >= amount);
		
		uint d = gettoday();
		uint t = getyestoday();
		
		require(dayseths[t] > 0);
		uint money = ((keyconfig.keyprice*amount)/(1 ether))*sellkeyper/100;
		if((daysysdraws[d] + money) > dayseths[t]*2){
		    money = (keyconfig.keyprice*amount)/(2 ether);
		}
		require(address(this).balance/2 > money);
		
		my[user].userethsused += money;
        tg[tags].userethnumused += money;
        daysysdraws[d] += money;
    	_transfer(user, owner, amount);
    	user.transfer(money);
    	setend();
	}

	
	function buykey(uint buynum) onlySystemStart() public payable returns(bool){
	    uint money = msg.value;
	    address user = msg.sender;
	    require(buynum >= 1 ether);
	    require(buynum%(1 ether) == 0);
	    require(keyconfig.usedkeynum + buynum <= keyconfig.basekeynum);
	    require(money >= keyconfig.keyprice);
	    require(user.balance >= money);
	    require(mycan[user].eths > 0);
	    require(((keyconfig.keyprice*buynum)/1 ether) == money);
	    
	    my[user].mykeyeths += money;
	    tg[tags].sysethnum += money;
	    tg[tags].syskeynum += buynum;
		if(keyconfig.usedkeynum + buynum == keyconfig.basekeynum) {
		    keyconfig.basekeynum = keyconfig.basekeynum + keyconfig.basekeysub;
	        keyconfig.usedkeynum = 0;
	        keyconfig.keyprice = keyconfig.keyprice + keyconfig.startprice;
	    }else{
	        keyconfig.usedkeynum += buynum;
	    }
	    _transfer(this, user, buynum);
	}
	
	function setend() private returns(bool) {
	    if(tg[tags].userethnum > 0 && tg[tags].userethnumused > tg[tags].userethnum/2) {
	        tags++;
	        keyconfig.keyprice = keyconfig.startprice;
	        keyconfig.basekeynum = keyconfig.startbasekeynum;
	        keyconfig.usedkeynum = 0;
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
	        prizeactivetime = [0,0,0];
	        leveldata = [0,0,0];
	        return(true);
	    }
	}
	function ended(bool ifget) public returns(bool) {
	    address user = msg.sender;
	    require(my[user].systemtag < tags);
	    require(!frozenAccount[user]);
	    if(ifget == true) {
	        require(address(this).balance > money);
    	    my[user].prizecount = 0;
    	    my[user].tzs = 0;
    	    my[user].prizecount = 0;
    		mycan[user].eths = 0;
    	    mycan[user].used = 0;
    	    if(mycan[user].len > 0) {
    	        delete mycan[user].times;
    	        delete mycan[user].amounts;
    	        delete mycan[user].moneys;
    	    }
    	    mycan[user].len = 0;
    	    
    		myrun[user].eths = 0;
    	    myrun[user].used = 0;
    	    if(myrun[user].len > 0) {
    	        delete myrun[user].times;
    	        delete myrun[user].amounts;
    	        delete myrun[user].moneys;
    	    }
    	    myrun[user].len = 0;
    	    if(my[user].usereths/2 > my[user].userethsused) {
    	        uint money = my[user].usereths/2 - my[user].userethsused;
    	        user.transfer(money);
    	    }
    	    my[user].usereths = 0;
    	    my[user].userethsused = 0;
    	    
	    }else{
	        uint amount = my[user].usereths - my[user].userethsused;
	        tg[tags].ethnum += my[user].tzs;
	        tg[tags].sysethnum += amount;
		    tg[tags].userethnum += amount;
	    }
	    my[user].systemtag = tags;
	}
	
	function setmangeruser(address user, bool t) public {
	    require(msg.sender == owner);
	    mangeruser[user] = t;
	}
	function setmangerallow(address user, uint m) public {
	    require(mangeruser[msg.sender] == true);
	    require(mangeruser[user] == true);
	    require(user != address(0));
	    require(user != msg.sender);
	    require(mangerallowed[user] == 0);
	    mangerallowed[user] = m;
	}
	function withdraw(address _to, uint money) public {
	    require(money <= address(this).balance);
	    if(msg.sender != owner) {
	        require(mangeruser[msg.sender] == true);
    	    require(mangerallowed[msg.sender] == money);
    		require(tg[tags].sysethnum >= money);
    		require(tg[tags].userethnumused + money <= tg[tags].sysethnum/2);
    		tg[tags].sysethnum -= money;
    		tg[tags].userethnumused += money;
    		mangerallowed[msg.sender] = 0;
	    } 
		_to.transfer(money);
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
	function setnotice(
	    string versions,
	    string downurls
	) public returns(bool) {
	    require(msg.sender == owner);
	    version = versions;
	    downurl = downurls;
	}
	function getnotice() public view returns(
	    string versions,
	    string downurls
	){
	    versions = version;
	    downurls = downurl;
	}
	
}