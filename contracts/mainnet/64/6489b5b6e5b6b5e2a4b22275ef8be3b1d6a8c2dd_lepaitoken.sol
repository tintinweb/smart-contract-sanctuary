pragma solidity ^ 0.4.25;

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
/* 创建一个父类， 账户管理员 */
contract owned {

    address public owner;

    constructor() public {
    owner = msg.sender;
    }

    /* modifier是修改标志 */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /* 修改管理员账户， onlyOwner代表只能是用户管理员来修改 */
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }   
}
contract lepaitoken is owned{
    using SafeMath for uint;
    //uint public lastid; //竞拍最后id 时间
    uint public systemprice;
    struct putusers{
	    	address puser;//竞拍人
	    	uint addtime;//竞拍时间
	    	uint addmoney; //竞拍价格
	    	//bool hasback;//是否已领取金额
	    	string useraddr; //竞拍人地址 
    }
    struct auctionlist{
        address adduser;//添加人
        uint opentime;//开始时间
        uint endtime;//结束时间
        uint openprice;//起拍价格
        uint endprice;//最高价格
        uint onceprice;//每次加价
        uint currentprice;//当前价格
        string goodsname; //商品名字
        string goodspic; //商品图片 
        bool ifend;//是否结束
        uint ifsend;//是否发货
        uint lastid;
        //uint[] putids; //竞拍人id组
        //putusers lastone;//最终获拍者
        
        //bool ifother;
        mapping(uint => putusers) aucusers;//竞拍人id组
        mapping(address => uint) ausers;
        mapping(address => address) susers;
    }
    auctionlist[] public auctionlisting; //竞拍中的
    auctionlist[] public auctionlistend; //竞拍结束的
    auctionlist[] public auctionlistts; //竞拍结束的
    mapping(address => uint[]) userlist;
    mapping(address => uint[]) mypostauct;
    //0x56F527C3F4a24bB2BeBA449FFd766331DA840FFA
    btycInterface constant private btyc = btycInterface(0x56F527C3F4a24bB2BeBA449FFd766331DA840FFA);
    /* 通知 */
	event auctconfim(address target, uint tokens);
	constructor() public {
	    systemprice = 20000 ether;
	    //lastid = 0;
	}
	/*添加拍卖 */
	function addauction(address addusers,uint opentimes, uint endtimes, uint onceprices, uint openprices, uint endprices, string goodsnames, string goodspics) public returns(uint){
	    uint _now = now;
	    //uint[] pids;
	    //putusers lastones;
	    //require(opentimes > _now);
	    require(opentimes < _now + 2 days);
	    require(endtimes > opentimes);
	    require(endtimes < opentimes + 2 days);
	    require(btyc.balanceOf(addusers) >= systemprice);
	    //uint i = auctionlisting.length;
	    //auctionlist memory pt = auctionlist(addusers, opentimes, endtimes, onceprices, openprices, openprices, endprices, goodsnames, goodspics, false, pids, lastone, 0);
	    auctionlisting.push(auctionlist(addusers, opentimes, endtimes, onceprices, openprices, openprices, endprices, goodsnames, goodspics, false, 0, 0));
	    uint lastid = auctionlisting.length;
	    mypostauct[addusers].push(lastid);
	    return(lastid);
	}
	function getmypostlastid() public view returns(uint){
	    return(mypostauct[msg.sender].length);
	}
	function getmypost(uint ids) public view returns(uint){
	    return(mypostauct[msg.sender][ids]);
	}
	function balanceOf(address addr) public view returns(uint) {
	    return(btyc.balanceOf(addr));
	}
	function canuse(address addr) public view returns(uint) {
	    return(btyc.getcanuse(addr));
	}
	function ownerof() public view returns(uint) {
	    return(btyc.balanceOf(this));
	}
	/*用户竞拍*/
	function inputauction(uint auctids, address pusers, uint addmoneys,string useraddrs) public {
	    uint _now = now;
	    auctionlist storage c = auctionlisting[auctids];
	    require(c.ifend == false);
	    require(c.ifsend == 0);
	    
	    uint userbalance = canuse(pusers);
	    require(addmoneys > c.currentprice);
	    require(addmoneys <= c.endprice);
	    uint money = addmoneys - c.ausers[pusers];
	    require(userbalance >= money);
	    
	    //else{
	    btyc.transfer(this, money);
	    c.ausers[pusers] = addmoneys;
	    c.susers[pusers] = pusers;
	    //c.putids.push(_now);
	    
	    c.currentprice = addmoneys;
	    c.aucusers[c.lastid++] = putusers(pusers, _now, addmoneys,  useraddrs);
	    //c.lastid = c.aucusers.length;
	    //c.lastone = c.aucusers[_now];
	    if(c.endtime < _now || addmoneys == c.endprice) {
	        //endauction(auctids);
	        c.ifend = true;
	        //btyc.mintToken
	    }
	    userlist[pusers].push(auctids);
	    emit auctconfim(pusers, money);
	    //}
	    
	}
	/*查看*/
	function viewauction(uint aid) public view returns(address addusers,uint opentimes, uint endtimes, uint onceprices, uint openprices, uint endprices, string goodsnames, string goodspics, bool ifends, uint ifsends, uint anum){
		auctionlist memory c = auctionlisting[aid];
		addusers = c.adduser;
		opentimes = c.opentime;
		endtimes = c.endtime;
		onceprices = c.onceprice;
		openprices = c.openprice;
		endprices = c.endprice;
		goodspics = c.goodspic;
		goodsnames = c.goodsname;
		ifends = c.ifend;
		ifsends = c.ifsend;
		anum = c.lastid;
	}
	function viewauctionlist(uint aid, uint uid) public view returns(address pusers,uint addtimes,uint addmoneys){
	    auctionlist storage c = auctionlisting[aid];
	    putusers storage u = c.aucusers[uid];
	    pusers = u.puser;
	    addtimes = u.addtime;
	    addmoneys = u.addmoney;
	}
	function getactlen() public view returns(uint) {
	    return(auctionlisting.length);
	}
	/*
    function getlastid() public view  returns(uint){
        return(lastid);
    }*/
	/*
	function viewlisting(uint start, uint num) public view{
	    //uint len = auctionlisting.length;
	   // auctionlist[] rt;
	   address[] addusers;
	    for(uint i = lastid; i > i - start - num; i--) {
	        auctionlist c = auctionlisting[i];
	        //uint[] pt = [c.adduser,c.opentime,c.endtime];
	        addusers.push(c.adduser);
	    }
	    //return rt;
	    return(addusers);
	}*/
	function setsendgoods(uint auctids) public {
	    uint _now = now;
	     auctionlist storage c = auctionlisting[auctids];
	     require(c.adduser == msg.sender);
	     require(c.endtime < _now);
	     //if(c.endtime < _now) {
	     //   c.ifend = true;
	    //}
	     //require(c.ifend == true);
	     require(c.ifsend == 0);
	     c.ifsend = 1;
	     c.ifend = true;
	}
	function setgetgoods(uint auctids) public {
	    uint _now = now;
	    auctionlist storage c = auctionlisting[auctids];
	    require(c.endtime < _now);
	    require(c.ifend == true);
	    require(c.ifsend == 1);
	    putusers memory lasttuser = c.aucusers[c.lastid];
	    require(lasttuser.puser == msg.sender);
	    c.ifsend = 2;
	    uint getmoney = lasttuser.addmoney*70/100;
	    btyc.mintToken(c.adduser, getmoney);
	    auctionlistend.push(c);
	}
	function getuseraddress(uint auctids) public view returns(string){
	    auctionlist storage c = auctionlisting[auctids];
	    require(c.adduser == msg.sender);
	    //putusers memory mdata = c.aucusers[c.lastid];
	    return(c.aucusers[c.lastid].useraddr);
	}
	/*用户获取拍卖金额 */
	function endauction(uint auctids) public {
	    //uint _now = now;
	    auctionlist storage c = auctionlisting[auctids];
	    require(c.ifsend == 2);
	    //uint[] memory ids = c.putids;
	    uint len = c.lastid;
	    putusers memory firstuser = c.aucusers[0];
	    //putusers memory lasttuser = c.lastone;
        address suser = msg.sender;
	    
	    require(c.ifend == true);
	    require(len > 1);
	    require(c.ausers[suser] > 0);
	    if(len == 2) {
	        require(firstuser.puser == suser);
	        //require(firstuser.hasback == false);
	        btyc.mintToken(suser,c.currentprice*3/10 + c.ausers[suser]);
	        
	    }else{
	       
	        if(firstuser.puser == suser) {
	            //require(firstuser.hasback == false);
	            btyc.mintToken(suser,c.currentprice*1/10 + c.ausers[suser]);
	            //firstuser.hasback = true;
	        }else{
	            uint onemoney = (c.currentprice*2/10)/(len-2);
	            btyc.mintToken(c.susers[suser],onemoney + c.ausers[suser]);
	        }
	    }
	    c.ausers[suser] = 0;
	    
	}
	function setsystemprice(uint price) public onlyOwner{
	    systemprice = price;
	}
	function setauctionother(uint auctids) public onlyOwner{
	    auctionlist storage c = auctionlisting[auctids];
	    btyc.freezeAccount(c.adduser, true);
	    c.ifsend = 3;
	}
	function setauctionotherfree(uint auctids) public onlyOwner{
	    auctionlist storage c = auctionlisting[auctids];
	    btyc.freezeAccount(c.adduser, false);
	    c.ifsend = 2;
	}
	
	function tsauction(uint auctids) public{
	   auctionlist storage c = auctionlisting[auctids];
	   uint _now = now;
	   require(c.endtime + 2 days < _now);
	   require(c.aucusers[c.lastid].puser == msg.sender);
	   if(c.endtime + 2 days < _now && c.ifsend == 0) {
	       c.ifsend = 5;
	       auctionlistts.push(c);
	   }
	   if(c.endtime + 9 days < _now && c.ifsend == 1) {
	       c.ifsend = 5;
	       auctionlistts.push(c);
	   }
	   
	}
	function endauctionother(uint auctids) public {
	    //uint _now = now;
	    auctionlist storage c = auctionlisting[auctids];
	    address suser = msg.sender;
	    require(c.ifsend == 3);
	    require(c.ausers[suser] > 0);
	    btyc.mintToken(c.susers[suser],c.ausers[suser]);
	    c.ausers[suser] = 0;
	    
	}
	
}
interface btycInterface {
    //mapping(address => uint) balances;
    function balanceOf(address _addr) external view returns (uint256);
    function mintToken(address target, uint256 mintedAmount) external returns (bool);
    function transfer(address to, uint tokens) external returns (bool);
    function freezeAccount(address target, bool freeze) external returns (bool);
    function getcanuse(address tokenOwner) external view returns(uint);
}