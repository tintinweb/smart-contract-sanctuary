pragma solidity ^ 0.4.25;

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

contract ApproveAndCallFallBack {
	function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

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
contract AiToken is ERC20Interface, Owned {
	string public symbol;
	string public name;
	uint8 public decimals;
	uint _totalSupply;
	
	//address public owner;
	bool public actived;
	struct keyconf{
	    uint basekeynum;//5000
    	uint basekeysub;//5000
    	uint usedkeynum;//0
        uint startprice;//0.01
        uint keyprice;//0.01
        uint startbasekeynum;//5000
        //uint[] keyidarr;
    	//uint currentkeyid;
	}
	keyconf private keyconfig;
	uint[] public worksdata;
	
	uint public onceOuttime;
	uint8 public per;
	
	
	//uint[] public mans;
	//uint[] public mms;
	uint[] public pers;
	/*
	uint[] public prizeper;
	uint[] public prizelevelsuns;
	uint[] public prizelevelmans;
	uint[] public prizelevelsunsday;
	uint[] public prizelevelmoneyday;
	uint[] public prizeactivetime;*/
	
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
	uint public sellupper;
	uint public sysday;
	uint public cksysday;
	//uint public nulldayeth;
    mapping(uint => mapping(uint => uint)) allprize;
	//uint public allprizeused;
	mapping(address => uint) balances;
	
	mapping(address => mapping(address => uint)) allowed;
	mapping(address => bool) public frozenAccount;
	struct usercan{
	    uint eths;
	    uint used;
	    uint len;
	    uint adds;
	    uint[] times;
	    uint[] moneys;
	    //uint[] amounts;
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
	    //uint[] suns;
	    mapping(uint => uint) mysunsdaynum;
	    mapping(uint => uint) myprizedayget;
	    mapping(uint => uint) daysusereths;
	    mapping(uint => uint) daysuserdraws;
	    mapping(uint => uint) daysuserlucky;
	    mapping(uint => uint) levelget;
	    mapping(uint => bool) hascountprice;
	}
	mapping(address => userdata) my;
	mapping(address => uint) mysunmoney;
	struct sunsdata{
	    uint t1;
	    uint t2;
	    uint t3;
	    uint t4;
	    uint t5;
	    uint t6;
	    uint t7;
	}
	mapping(address => sunsdata) suns;

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
	string private version;
	string private downurl;
	string private notices;
	uint public hasusednum;
	uint[] private nullworker;
	uint[] private defworkper;
	uint public defkeynum;
	uint public currentkeyid;
	uint public initkeyid;
	mapping(uint => uint) public cuid;
	struct tndata{
	    uint cid;//1110000001
	    uint sellid;
	    uint selltime;
	    uint sellmoney;
	    
	    //address owneruser;
	    //bool ifopen;
	    //uint[] worksdata;
	}
	mapping(address => tndata) tnode;
	/*
	struct sundata{
	    uint cid;//1100000001
	    tndata tdata;
	    mapping(uint => tndata) tsuns;
	}
	struct topdata{
	    uint cid;//1000000001
	    tndata fdata;
	    //mapping(uint => sundata) suns;
	    //uint[] per;
	}
	mapping(uint => topdata) nodetop;*/
	/* 通知 */
	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
	event FrozenFunds(address target, bool frozen);
	event ethchange(address indexed from, address indexed to, uint tokens);
	modifier onlySystemStart() {
        require(actived == true);
	    require(tags == my[msg.sender].systemtag);
	    require(!frozenAccount[msg.sender]);
        _;
    }

	constructor() public {
		symbol = "AiKey";
		name = "AiKey";
		decimals = 18;
		_totalSupply = 100000000 ether;
	
		actived = true;
		tags = 0;
		tg[0] = tagsdata(0,0,0,0,0);
		
        //keyconfig.currentkeyid = 0;
        //keyconfig.keyidarr = [10055555,20055555,30055555,40055555,50055555,60055555,70055555,80055555,90055555];
        nullworker = [0,0,0,0,0,0,0,0,0];
        defworkper = [2,3,5];
        defkeynum = 1000000000;
        currentkeyid = 10000;
        initkeyid = 10000;
        runper = 10;
		//mans = [30,20,10,10,10,10,10];
		//mms = [2 ether, 10 ether, 30 ether];
		pers = [30,20,10,5,5,5,5];
		//prizeper = [2,2,2];
		//prizeactivetime = [0,0,0];
		pubper = 1;
		subper = 120;
		luckyper = 5;
		lastmoney = 0;
		lastper = 1;
		sellkeyper = 70;
		sellper = 5;
		sellupper = 50;
		//leveldata = [0,0,0];

        //onceOuttime = 24 hours;
        onceOuttime = 10 seconds;//test
        //keyconfig.basekeynum = 5000 ether;//4500
	    //keyconfig.basekeysub = 5000 ether;//500
	    keyconfig.usedkeynum = 0;//0
        keyconfig.startprice = 100 szabo;//
        keyconfig.keyprice   = 100 szabo;//
        //keyconfig.startbasekeynum = 5000 ether;//4500
        
        keyconfig.basekeynum = 5 ether;//4500 test
	    keyconfig.basekeysub = 5 ether;//500 test
	    keyconfig.startbasekeynum = 5 ether;//4500 test
	    
        per = 10;
        /*
        prizelevelsuns = [20,30,50];
		prizelevelmans = [100,300,800];
		prizelevelsunsday = [1,3,5];
		prizelevelmoneyday = [9 ether,29 ether,49 ether];*/
		//lasttime = 8 hours;
		lasttime = 600 seconds;//test
		//sysday = 1 days;
		sysday = 3600 seconds;//test
		//cksysday = 8 hours;//test
		cksysday = 0;
        version = &#39;1.01&#39;;
		balances[this] = _totalSupply;
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
	    total = tg[tags].ethnum;//0
	    mykeyid = my[user].mykeysid;//1
	    mytzs = my[user].tzs;//2
	    daysget = my[user].usereths*per/1000;//3
	    prizeget = my[user].prizecount;//4
	    mycans = getcanuse(user);//5
	    mykeynum = balanceOf(user);//6
	    keyprices = getbuyprice();//7
	    ltkeynum = leftnum();//8
	    tagss = tags;//9
	    mytags = my[user].systemtag;//10
	}
	function showteam(address user) public view returns(
	    uint daysnum,//0
	    uint dayseth,//1
	    uint daysnum1,//2
	    uint dayseth1,//3
	    //uint man1,//4
	    //uint man2,//5
	    //uint man3,//6
	    uint myruns,//7
	    uint canruns,//8
	    uint levelid,//9
	    uint mym
	){
	    uint d = gettoday();
	    uint t = getyestoday();
	    daysnum = my[user].mysunsdaynum[d];//5
	    dayseth = my[user].myprizedayget[d];//6
	    daysnum1 = my[user].mysunsdaynum[t];//5
	    dayseth1 = my[user].myprizedayget[t];//6
	    /*
	    man1 = my[user].suns[0];//2
	    man2 = my[user].sun2;//3
	    man3 = my[user].sun3;//4
	    */
	    myruns = myrun[user].eths;//6
	    canruns = getcanuserun(user);//7
	    levelid = my[user].mylevelid;//8
	    mym = mysunmoney[user];
	}
	/*
	function showlevel(address user) public view returns(
	    //uint myget,//0
	    //uint levelid,//1
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
	    //(levelid, myget) = getprizemoney(user);
	    //len2 = leveldata[1];
	    //len3 = leveldata[2];
	    m1 = allprize[0][0] - allprize[0][1];//5
	    m2 = allprize[1][0] - allprize[1][1];//6
	    m3 = allprize[2][0] - allprize[2][1];//7
	    t1 = prizeactivetime[0];//8
	    uint d = getyestoday();
	    if(t1 > 0) {
	        if(t1 + sysday > now){
    	        len1 = leveldata[0];
    	    }else{
    	        len1 = userlevelsnum[1][d];
	        }
	    }
	    
	    t2 = prizeactivetime[1];//9
	    if(t2 > 0) {
	        if(t2 + sysday > now){
    	        len2 = leveldata[1];
    	    }else{
    	        len2 = userlevelsnum[2][d];
    	    }
	    }
	    
	    t3 = prizeactivetime[2];//10
	    if(t3 > 0) {
	        if(t3 + sysday > now){
    	        len3 = leveldata[2];
    	    }else{
    	        len3 = userlevelsnum[3][d];
    	    }
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
	*/
	function addmoney(address _addr, uint256 _money, uint _day) private returns(bool){
		mycan[_addr].eths += _money;
		mycan[_addr].len++;
		//mycan[_addr].amounts.push(_amount);
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
	function addrunmoney(address _addr, uint256 _money, uint _day) private {
		myrun[_addr].eths += _money;
		myrun[_addr].len++;
		//myrun[_addr].amounts.push(_amount);
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
    			        uint smoney = mycan[user].moneys[i] * ((now - stime)/onceOuttime) * per/ 1000;
    			        if(smoney <= mycan[user].moneys[i]){
    			            _left += smoney;
    			        }else{
    			            _left += mycan[user].moneys[i];
    			        }
    			    }
    			    
    			}
    		}
		}
		_left += mycan[user].adds;
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
    			        uint smoney = myrun[user].moneys[i] * ((now - stime)/onceOuttime) * per/ 1000;
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
    function transfer(address _to, uint256 _value) public returns(bool){
        _transfer(msg.sender, _to, _value);
        return(true);
    }
    function activekey() public returns(bool) {
        require(actived == true);
	    address addr = msg.sender;
        uint keyval = 1 ether;
        require(balances[addr] >= keyval);
        require(my[addr].mykeysid < 1);
        if(balances[addr] == keyval) {
            keyval -= 1;
        }
        address top = my[addr].fromaddr;
        uint kid;
        uint topkeyid = my[top].mykeysid;
        
        if(top != address(0) && topkeyid > 0) {
            if(topkeyid < defkeynum) {
                kid = currentkeyid;
                currentkeyid++;
            }else{
                uint d0;
                uint d1;
                uint d2;
                uint ld;
                (d0, d1, d2, ld) = chknodenumber(topkeyid);
                uint nodeid = d0*defkeynum + d1*defkeynum/10 + d2*defkeynum/100;
                if(cuid[nodeid] <= topkeyid) {
                    cuid[nodeid] = topkeyid + 1;
                }
                kid = cuid[nodeid];
                cuid[nodeid]++;
                
            }
            //kid = topkeyid + 1;
            
        }else{
           
            if(currentkeyid == initkeyid) {
                tnode[addr] = tndata(0, defkeynum,now,100 ether);
                /*
                nodetop[0].cid = defkeynum;
                nodetop[0].fdata = tndata(0,defkeynum,now,100 ether);
                nodetop[0].per = defworkper;*/
            }
            kid = currentkeyid;
            currentkeyid++;
            
        }
        
        
        require(myidkeys[kid] == address(0));
        my[addr].mykeysid = kid;
	    myidkeys[kid] = addr;
	    balances[addr] -= keyval;
	    balances[owner] += keyval;
	    emit Transfer(addr, owner, keyval);
	    return(true);
    }
    function setnodemoney(address addr, uint amount) public returns(bool){
	    uint mykid = my[addr].mykeysid;
	    if(mykid > defkeynum) {
	        uint d0;
            uint d1;
            uint d2;
            uint ld;
            (d0, d1, d2, ld) = chknodenumber(mykid);
            if(ld < 1) {
                uint nodeid3 = d0*defkeynum + d1*defkeynum/10 + d2*defkeynum/100;
                uint nodeid2 = d0*defkeynum + d1*defkeynum/10;
                uint nodeid1 = d0*defkeynum;
                if(myidkeys[nodeid3] == address(0) && myidkeys[nodeid2] == address(0) && myidkeys[nodeid1] != address(0)) {
                    addrunmoney(myidkeys[nodeid1], amount*(defworkper[0] + defworkper[1] + defworkper[2])/100,0);
                }
                if(myidkeys[nodeid3] == address(0) && myidkeys[nodeid2] != address(0) && myidkeys[nodeid1] != address(0)) {
                    addrunmoney(myidkeys[nodeid2], amount*(defworkper[1] + defworkper[2])/100,0);
                }
                if(myidkeys[nodeid3] != address(0) && myidkeys[nodeid2] != address(0) && myidkeys[nodeid1] != address(0)) {
                    addrunmoney(myidkeys[nodeid2], amount*defworkper[2]/100,0);
                }
            }
	    }
	}
    function getnodeparam(address user) public view returns(uint ld,uint cid,uint nodeid){
        uint keyid = my[user].mykeysid;
        cid = tnode[user].cid;
        uint d0;
        uint d1;
        uint d2;
        if(keyid == initkeyid) {
            d0 = 1;
            d1 = 0;
            d2 = 0;
            ld = 1;
            nodeid = (tnode[user].cid + 1)*defkeynum;
        }
        if(keyid >= defkeynum){
            (d0, d1, d2, ld) = chknodenumber(keyid);
            if(ld > 0) {
                if(d1 < 1) {
                    nodeid = d0*defkeynum + (tnode[user].cid + 1)*defkeynum/10;
                }else{
                   nodeid = d0*defkeynum + d1*defkeynum/10 + (tnode[user].cid + 1)*defkeynum/100; 
                }
            }
        }
    }
    function gettnode(address addr) public view returns(uint cids, uint nid, uint t, uint m){
        cids = tnode[addr].cid;
        nid = tnode[addr].sellid;
        t = tnode[addr].selltime;
        m = tnode[addr].sellmoney;
    }
    function sellnode(uint money) public returns(bool){
        address user = msg.sender;
        (uint ld,uint cid, uint nodeid) = getnodeparam(user);
        require(nodeid > 0 && ld > 0 && cid < 9);
        tnode[user] = tndata(cid, nodeid,now,money);
    }
    function getbuynode(address user) public view returns(uint nodeid,uint money) {
        address top = my[user].fromaddr;
        if(top != address(0) && my[top].mykeysid > 0) {
            uint ld;
            uint cid;
            (ld,cid, nodeid) = getnodeparam(top);
            if(ld > 0 && tnode[top].selltime > 0) {
                money = tnode[top].sellmoney;
            }
        }
    }
    function buynode(uint keyid) public payable returns(bool) {
        require(myidkeys[keyid] == address(0));
        //tndata tn = tnode[user];
        address addr = msg.sender;
        require(my[addr].mykeysid < 1);
        address top = my[addr].fromaddr;
        uint amount = msg.value;
        require(top != address(0));
        require(my[top].mykeysid > 0);
        require(tnode[top].selltime > 1);
        require(amount >= tnode[top].sellmoney);
        require(addr.balance > amount);
        
        uint usekey = (amount*1 ether)/(10*keyconfig.keyprice);
	    require(usekey < balances[addr]);
	    
	    balances[addr] -= usekey;
		balances[owner] += usekey;
		emit Transfer(addr, owner, usekey);
		
		
		my[addr].mykeysid = keyid;
	    myidkeys[keyid] = addr;
	    
        top.transfer(amount);
        tnode[top].cid++;
        tnode[top].selltime = 1;
        
    }
    function chknodenumber(uint keyid) public view returns(uint d0, uint d1, uint d2, uint ld){
        //uint keyid = my[_addr].mykeysid;
        if(keyid >= defkeynum){
            //topkeyid 9928
            uint n = keyid/defkeynum;//9
            uint ln = keyid - (defkeynum*n);// 928
            uint k10 = defkeynum/10;//100
            uint k100 = defkeynum/100;//10
            //uint k1000 = defkeynum/1000;
            
            if(ln < k10){//is root
                d0 = n;
                d1 = 0;
                d2 = 0;
                if(ln < 1) {
                    ld = 1;
                }else{
                    ld = 0;
                }
            }else{
                uint nn = ln/k10;//9
                uint ln2 = ln - nn*k10;//28
                if(ln2 < k100) {
                    d0 = n;
                    d1 = nn;
                    d2 = 0;
                    if(ln2 < 1) {
                        ld = 2;
                    }else{
                        ld = 0;
                    }
                }else{
                    uint nnn = ln2/k100;//2
                    uint ln3 = ln2 - nnn*k100;//8
                    d0 = n;
                    d1 = nn;
                    d2 = nnn;
                    if(ln3 < 1) {
                        ld = 3;
                    }else{
                        ld = 0;
                    }
                }
                
            }
        }else{
            return(0,0,0,0);
        }
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

	function setactive(bool t) public onlyOwner{
		actived = t;
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

	
	
	function getfromsun(address addr, uint money, uint amount) private returns(bool){
	    address f1 = my[addr].fromaddr;
	    uint d = gettoday();
	    if(f1 != address(0) && f1 != addr) {
	        addrunmoney(f1, (money*pers[0])/100, 0);
	    	my[f1].myprizedayget[d] += amount;
	    	setnodemoney(addr, amount);
	    	/*
	    	if(my[f1].mykeysid > 10000000) {
	    	    worksdata[((my[f1].mykeysid/10000000) - 1)] += amount;
	    	}*/
	    	//setlevel(f1);
	    	address f2 = my[f1].fromaddr;
	    	if(f2 != address(0) && f2 != addr) {
    	        if(suns[f2].t1 > 1){
    	           addrunmoney(f2, (money*pers[1])/100, 0);
    	        }
    	    	my[f2].myprizedayget[d] += amount;
    	    	address f3 = my[f2].fromaddr;
    	    	if(f3 != address(0) && f3 != addr) {
        	        if(suns[f3].t1 > 2){
        	            addrunmoney(f3, (money*pers[2])/100, 0);
        	        }
        	    	my[f3].myprizedayget[d] += amount;
        	    	address f4 = my[f3].fromaddr;
        	    	if(f4 != address(0) && f4 != addr) {
            	        if(suns[f4].t1 > 3){
            	            addrunmoney(f4,(money*pers[3])/100, 0);
            	        }
            	    	my[f4].myprizedayget[d] += amount;
            	    	address f5 = my[f4].fromaddr;
            	    	if(f5 != address(0) && f5 != addr) {
                	        if(suns[f5].t1 > 4){
                	            addrunmoney(f5,  (money*pers[4])/100, 0);
                	        }
                	    	my[f5].myprizedayget[d] += amount;
                	    	address f6 = my[f5].fromaddr;
                	    	if(f6 != address(0) && f6 != addr) {
                    	        if(suns[f6].t1 > 5){
                    	            addrunmoney(f6,  (money*pers[5])/100, 0);
                    	        }
                    	    	my[f6].myprizedayget[d] += amount;
                    	    	address f7 = my[f6].fromaddr;
                    	    	if(f7 != address(0) && f7 != addr) {
                        	        if(suns[f7].t1 > 6){
                        	            addrunmoney(f7, (money*pers[6])/100, 0);
                        	        }
                        	    	my[f6].myprizedayget[d] += amount;
                        	    }
                    	    }
                	    }
            	    }
        	    }
    	    }	
	    }
	    
	}
	function setpubprize(uint sendmoney) private returns(bool) {
	    uint len = moneydata.length;
	    if(len > 0) {
	        uint all = 0;
	        uint start = 0;
	        uint m = 0;
	        if(len > 3) {
	            start = len - 3;
	        }
	        for(uint i = start; i < len; i++) {
	            all += moneydata[i];
	        }
	        //uint sendmoney = amount*pubper/100;
	        for(; start < len; start++) {
	            m = (sendmoney*moneydata[start])/all;
	            addrunmoney(mansdata[start],m, 100);
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
	    addrunmoney(user, money, 100);
	    my[user].daysuserlucky[d] += money;
	    my[user].prizecount += money;
	    /*
	    uint t = getyestoday() - sysday;
	    for(uint i = 0; i < moneydata.length; i++) {
    	    if(timedata[i] < t) {
    	        delete moneydata[i];
    	        delete timedata[i];
    	        delete mansdata[i];
    	    }
    	}*/
	}
	
	function runtoeth(uint amount) onlySystemStart() public returns(bool) {
	    address user = msg.sender;
	    uint usekey = (amount*runper*1 ether)/(100*keyconfig.keyprice);
	    require(usekey < balances[user]);
	    //uint mu = getcanuse(user);
	    require(getcanuserun(user) >= amount);
	    require(my[user].tzs > getcanuse(user));
	    require(amount <= my[user].tzs - getcanuse(user));
	    balances[user] -= usekey;
		balances[owner] += usekey;
		emit Transfer(user, owner, usekey);
	    reducerunmoney(user, amount);
	    mycan[user].adds += amount;
	    //addrunmoney(user, amount, 100);
	}
	function getlastuser() public view returns(address user) {
	    if(timedata.length > 0) {
    	    if(lastmoney > 0 && now - timedata[timedata.length - 1] > lasttime) {
    	        user = mansdata[mansdata.length - 1];
    	    }
	    } 
	}
	function getlastmoney() public returns(bool) {
	    require(actived == true);
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
        require(amount >= 100 finney);
		//require(amount%(100 finney) == 0);
		require(my[user].usereths <= 1000 ether);
		uint money = amount*3;
		uint d = gettoday();
		//uint t = getyestoday();
		bool ifadd = false;
		//if has no top
		
		if(my[user].fromaddr == address(0)) {
		    address topaddr = myidkeys[keyid];
		    if(keyid > 0 && topaddr != address(0) && topaddr != user) {
		        my[user].fromaddr = topaddr;
		        
    		    suns[topaddr].t1++;
    		    //my[topaddr].mysunsdaynum[d]++;
    		    //mysunmoney[topaddr] += amount;
    		    
    		    address top2 = my[topaddr].fromaddr;
    		    if(top2 != address(0) && top2 != user){
    		        suns[top2].t2++;
    		        address top3 = my[top2].fromaddr;
        		    if(top3 != address(0) && top3 != user){
        		        suns[top3].t3++;
        		        address top4 = my[top3].fromaddr;
            		    if(top4 != address(0) && top4 != user){
            		        suns[top4].t4++;
            		        address top5 = my[top4].fromaddr;
                		    if(top5 != address(0) && top5 != user){
                		        suns[top5].t5++;
                		        address top6 = my[top5].fromaddr;
                    		    if(top6 != address(0) && top6 != user){
                    		        suns[top6].t6++;
                    		        address top7 = my[top6].fromaddr;
                        		    if(top7 != address(0) && top7 != user){
                        		        suns[top7].t7++;
                        		    }
                    		    }
                    		    
                		    }
            		    }
        		    }
    		    }
    		    
    		    ifadd = true;
		    }
		}else{
		    ifadd = true;
		    //mysunmoney[my[user].fromaddr] += amount;
		}
		
		if(ifadd == true) {
		    money = amount*4;
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
		addmoney(user, money, 0);
		return(true);
	}
	
	function buykey(uint buynum) onlySystemStart() public payable returns(bool){
	    uint money = msg.value;
	    address user = msg.sender;
	    //require(buynum >= 1 ether);
	    //require(buynum%(1 ether) == 0);
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
	function keybuy(uint m) onlySystemStart() public returns(bool) {
	    address user = msg.sender;
	    require(m >= 1 ether);
	    require(balances[user] >= m);
	    uint amount = (m*keyconfig.keyprice)/(1 ether);
	    require(amount >= 100 finney);
	    uint money = amount*3;
	    
		//uint d = gettoday();
		//uint t = getyestoday();
		if(my[user].fromaddr != address(0)) {
		    money = amount*4;
		}
		/*
		if(daysgeteths[t] > 0 && daysgeteths[d] > daysgeteths[t]*subper/100) {
		    if(my[user].fromaddr == address(0)) {
    		    money = amount*2;
    		}else{
    		    money = amount*3;
    		}
		}*/
		tg[tags].ethnum += money;
		my[user].tzs += money;
		my[user].usereths += amount;
		addmoney(user, money, 0);
		balances[user] -= m;
	    balances[owner] += m;
	    
		emit Transfer(user, owner, m);
	    return(true);
	}
	function ethbuy(uint amount) onlySystemStart() public returns(bool) {
	    address user = msg.sender;
	    uint canmoney = getcanuse(user);
	    require(canmoney >= amount);
	    //require(amount >= 1 ether);
	    //require(amount%(1 ether) == 0);
	    require(amount >= 100 finney);
	    
	    require(mycan[user].eths >= amount);
	    require(my[user].tzs >= amount);
	    uint money = amount*3;
		//uint d = gettoday();
		//uint t = getyestoday();
		if(my[user].fromaddr == address(0)) {
		    money = amount*2;
		}
		/*
		if(daysgeteths[t] > 0 && daysgeteths[d] > daysgeteths[t]*subper/100) {
		    if(my[user].fromaddr == address(0)) {
    		    money = amount;
    		}else{
    		    money = amount*2;
    		}
		}*/
		addmoney(user, money, 0);
		my[user].tzs += money;
		mycan[user].used += amount;
		my[user].usereths += amount;
	    tg[tags].ethnum += money;
	    
	    return(true);
	}
	
	function charge() public payable returns(bool) {
		return(true);
	}
	
	function() payable public {
		buy(0);
	}
	
	function sell(uint256 amount) onlySystemStart() public returns(bool success) {
		address user = msg.sender;
		uint d = gettoday();
		uint t = getyestoday();
		uint256 canuse = getcanuse(user);
		require(canuse >= amount);
		require(address(this).balance > amount);
		uint p = sellper;
		if((daysysdraws[d] + amount) > (dayseths[d] + dayseths[t])){
		    p = sellupper;
		}
		uint useper = (amount*p*(1 ether))/(keyconfig.keyprice*100);
		
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
		require(keyconfig.keyprice >= keyconfig.startprice*10);
		uint d = gettoday();
		uint t = getyestoday();
		
		uint money = (keyconfig.keyprice*amount*sellkeyper)/(100 ether);
		if((daysysdraws[d] + money) > dayseths[t] + dayseths[d]){
		    money = (keyconfig.keyprice*amount)/(2 ether);
		}
		require(address(this).balance > money);
		//require(tg[tags].userethnumused + money <= tg[tags].userethnum/2);
		my[user].userethsused += money;
        tg[tags].userethnumused += money;
        daysysdraws[d] += money;
    	balances[user] -= amount;
	    balances[owner] += amount;
		emit Transfer(user, owner, amount);
		
    	user.transfer(money);
    	setend();
	}

	
	
	function setend() private returns(bool) {
	    if(tg[tags].userethnum > 0 && tg[tags].userethnumused > tg[tags].userethnum/2) {
	        tags++;
	        keyconfig.keyprice = keyconfig.startprice;
	        keyconfig.basekeynum = keyconfig.startbasekeynum;
	        keyconfig.usedkeynum = 0;
	        
	        //prizeactivetime = [0,0,0];
	        //leveldata = [0,0,0];
	        return(true);
	    }
	}
	function ended(bool ifget) public returns(bool) {
	    require(actived == true);
	    address user = msg.sender;
	    require(my[user].systemtag < tags);
	    require(!frozenAccount[user]);
	    if(ifget == true) {
    	    my[user].prizecount = 0;
    	    my[user].tzs = 0;
    	    my[user].prizecount = 0;
    		mycan[user].eths = 0;
    	    mycan[user].used = 0;
    	    if(mycan[user].len > 0) {
    	        delete mycan[user].times;
    	        //delete mycan[user].amounts;
    	        delete mycan[user].moneys;
    	    }
    	    mycan[user].len = 0;
    	    /*
    		myrun[user].eths = 0;
    	    myrun[user].used = 0;
    	    if(myrun[user].len > 0) {
    	        delete myrun[user].times;
    	        delete myrun[user].amounts;
    	        delete myrun[user].moneys;
    	    }
    	    myrun[user].len = 0;*/
    	    if(my[user].usereths/2 > my[user].userethsused) {
    	        uint money = my[user].usereths/2 - my[user].userethsused;
	            require(address(this).balance > money);
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
	
	function setmangeruser(address user, bool t) public onlyOwner{
	    mangeruser[user] = t;
	}
	function freezeAccount(address target, bool freeze) public{
	    require(actived == true);
	    require(mangeruser[msg.sender] == true);
		frozenAccount[target] = freeze;
		emit FrozenFunds(target, freeze);
	}
	/*
	function setmangerallow(address user, uint m) public {
	    require(actived == true);
	    require(mangeruser[msg.sender] == true);
	    require(mangeruser[user] == true);
	    require(user != address(0));
	    require(user != msg.sender);
	    //require(mangerallowed[user] == 0);
	    mangerallowed[user] = m;
	}*/
	
	function transto(address _to, uint money) public {
	    require(actived == true);
	    require(_to != 0x0);
	    address user = msg.sender;
	    require(mangeruser[user] == true);
    	//require(mangerallowed[user] == money);
    	//require(money > 1);
    	require(balances[this] >= money);
    	balances[_to] += money;
    	balances[this] -= money;
	    //hasusednum += money;
	    //mangerallowed[user] -= money - 1;
		emit Transfer(user, _to, money);
	}
    function setper(uint onceOuttimes,uint8 perss,uint runpers,uint pubpers,uint subpers,uint luckypers,uint lastpers,uint sellkeypers,uint sellpers,uint selluppers,uint lasttimes,uint sysdays,uint sellupperss) public onlyOwner{
	    onceOuttime = onceOuttimes;
	    per = perss;
	    runper = runpers;
	    pubper = pubpers;
	    subper = subpers;
	    luckyper = luckypers;
	    lastper = lastpers;
	    sellkeyper = sellkeypers;
	    sellper = sellpers;
	    sellupper = selluppers;
	    lasttime = lasttimes;//9
	    sysday = sysdays;
	    sellupper = sellupperss;
	}
	function setnotice(
	    string versions,
	    string downurls,
	    string noticess
	) public returns(bool){
	    require(actived == true);
	    require(mangeruser[msg.sender] == true);
	    version = versions;
	    downurl = downurls;
	    notices = noticess;
	}
	function getnotice() public view returns(
	    string versions,
	    string downurls,
	    string noticess,
	    bool isadm
	){
	    versions = version;
	    downurls = downurl;
	    noticess = notices;
	    isadm = mangeruser[msg.sender];
	}
	
}