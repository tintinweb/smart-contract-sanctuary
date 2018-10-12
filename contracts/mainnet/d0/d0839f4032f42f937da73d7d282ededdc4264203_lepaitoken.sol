pragma solidity ^ 0.4.25;

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
    string public symbol;
	string public name;
	uint8 public decimals;
    uint public systemprice;
    struct putusers{
	    	address puser;//竞拍人
	    	uint addtime;//竞拍时间
	    	uint addmoney; //竞拍价格
	    	string useraddr; //竞拍人地址 
    }
    struct auctionlist{
        address adduser;//添加人0
        uint opentime;//开始时间1
        uint endtime;//结束时间2
        uint openprice;//起拍价格3
        uint endprice;//最高价格4
        uint onceprice;//每次加价5
        uint currentprice;//当前价格6
        string goodsname; //商品名字7
        string goodspic; //商品图片8 
        bool ifend;//是否结束9
        uint ifsend;//是否发货10
        uint lastid;//竞拍数11
        mapping(uint => putusers) aucusers;//竞拍人的数据组
        mapping(address => uint) ausers;//竞拍人的竞拍价格
    }
    auctionlist[] public auctionlisting; //竞拍中的
    auctionlist[] public auctionlistend; //竞拍结束的
    auctionlist[] public auctionlistts; //竞拍投诉 
    mapping(address => uint[]) userlist;//用户所有竞拍的订单
    mapping(address => uint[]) mypostauct;//发布者所有发布的订单
    mapping(address => uint) balances;
    //管理员帐号
	mapping(address => bool) public admins;
    //0x56F527C3F4a24bB2BeBA449FFd766331DA840FFA
    address btycaddress = 0x56F527C3F4a24bB2BeBA449FFd766331DA840FFA;
    btycInterface constant private btyc = btycInterface(0x56F527C3F4a24bB2BeBA449FFd766331DA840FFA);
    /* 通知 */
	event auctconfim(address target, uint tokens);//竞拍成功通知
	event getmoneys(address target, uint tokens);//获取返利通知
	event Transfer(address indexed from, address indexed to, uint tokens);
	/* modifier是修改标志 */
    modifier onlyadmin {
        require(admins[msg.sender] == true);
        _;
    }
	constructor() public {
	    symbol = "BTYClepai";
		name = "BTYC lepai";
		decimals = 18;
	    systemprice = 20000 ether;
	    admins[owner] = true;
	}
	/*添加拍卖 */
	function addauction(address addusers,uint opentimes, uint endtimes, uint onceprices, uint openprices, uint endprices, string goodsnames, string goodspics) public returns(uint){
	    uint _now = now;
	    require(opentimes >= _now - 1 hours);
	    require(opentimes < _now + 2 days);
	    require(endtimes > opentimes);
	    //require(endtimes > _now + 2 days);
	    require(endtimes < opentimes + 2 days);
	    require(btyc.balanceOf(addusers) >= systemprice);
	    auctionlisting.push(auctionlist(addusers, opentimes, endtimes, openprices, endprices, onceprices, openprices, goodsnames, goodspics, false, 0, 0));
	    uint lastid = auctionlisting.length;
	    mypostauct[addusers].push(lastid);
	    return(lastid);
	}
	//发布者发布的数量
	function getmypostlastid() public view returns(uint){
	    return(mypostauct[msg.sender].length);
	}
	//发布者发布的订单id
	function getmypost(uint ids) public view returns(uint){
	    return(mypostauct[msg.sender][ids]);
	}
	/* 获取用户金额 */
	function balanceOf(address tokenOwner) public view returns(uint balance) {
		return balances[tokenOwner];
	}
	//btyc用户余额
	function btycBalanceOf(address addr) public view returns(uint) {
	    return(btyc.balanceOf(addr));
	}
	/* 私有的交易函数 */
    function _transfer(address _from, address _to, uint _value) private {
        // 防止转移到0x0
        require(_to != 0x0);
        // 检测发送者是否有足够的资金
        require(balances[_from] >= _value);
        // 检查是否溢出（数据类型的溢出）
        require(balances[_to] + _value > balances[_to]);
        // 将此保存为将来的断言， 函数最后会有一个检验
        uint previousBalances = balances[_from] + balances[_to];
        // 减少发送者资产
        balances[_from] -= _value;
        // 增加接收者的资产
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        // 断言检测， 不应该为错
        assert(balances[_from] + balances[_to] == previousBalances);
    }
    function transfer(address _to, uint256 _value) public returns(bool){
        _transfer(msg.sender, _to, _value);
    }
    function transferadmin(address _from, address _to, uint _value)  public onlyadmin{
        _transfer(_from, _to, _value);
    }
    function transferto(uint256 _value) public returns(bool){
        _transfer(msg.sender, this, _value);
    }
	function() payable public {
	    address to = msg.sender;
		balances[to] = balances[to].add(msg.value);
		emit Transfer(msg.sender, this, msg.value);
	}
	//用户可用余额
	function canuse(address addr) public view returns(uint) {
	    return(btyc.getcanuse(addr));
	}
	//合约现有余额
	function btycownerof() public view returns(uint) {
	    return(btyc.balanceOf(this));
	}
	function ownerof() public view returns(uint) {
	    return(balances[this]);
	}
	//把合约余额转出
	function sendleftmoney(address _to, uint _value) public onlyadmin{
	     _transfer(this, _to, _value);
	}
	/*用户竞拍*/
	function inputauction(uint auctids, address pusers, uint addmoneys,string useraddrs) public payable{
	    uint _now = now;
	    auctionlist storage c = auctionlisting[auctids];
	    require(c.ifend == false);
	    require(c.ifsend == 0);
	    
	    uint userbalance = balances[pusers];
	    require(addmoneys > c.currentprice);
	    require(addmoneys <= c.endprice);
	   // uint userhasmoney = c.ausers[pusers];
	   require(addmoneys > c.ausers[pusers]);
	    uint money = addmoneys - c.ausers[pusers];
	    
	    require(userbalance >= money);
	    if(c.endtime < _now) {
	        c.ifend = true;
	    }else{
	        if(addmoneys == c.endprice){
	            c.ifend = true;
	        }
	        transferto(money);
	        c.ausers[pusers] = addmoneys;
	        c.currentprice = addmoneys;
	        c.aucusers[c.lastid++] = putusers(pusers, _now, addmoneys,  useraddrs);
	    
	        userlist[pusers].push(auctids);
	        //emit auctconfim(pusers, money);
	    }
	    
	    
	    //}
	    
	}
	//获取用户自己竞拍的总数
	function getuserlistlength(address uaddr) public view returns(uint len) {
	    len = userlist[uaddr].length;
	}
	//查看单个订单
	function viewauction(uint aid) public view returns(address addusers,uint opentimes, uint endtimes, uint onceprices, uint openprices, uint endprices, uint currentprices, string goodsnames, string goodspics, bool ifends, uint ifsends, uint anum){
		auctionlist storage c = auctionlisting[aid];
		addusers = c.adduser;//0
		opentimes = c.opentime;//1
		endtimes = c.endtime;//2
		onceprices = c.onceprice;//3
		openprices = c.openprice;//4
		endprices = c.endprice;//5
		currentprices = c.currentprice;//6
		goodspics = c.goodspic;//7
		goodsnames = c.goodsname;//8
		ifends = c.ifend;//9
		ifsends = c.ifsend;//10
		anum = c.lastid;//11
		
	}
	//获取单个订单的竞拍者数据
	function viewauctionlist(uint aid, uint uid) public view returns(address pusers,uint addtimes,uint addmoneys){
	    auctionlist storage c = auctionlisting[aid];
	    putusers storage u = c.aucusers[uid];
	    pusers = u.puser;//0
	    addtimes = u.addtime;//1
	    addmoneys = u.addmoney;//2
	}
	//获取所有竞拍商品的总数
	function getactlen() public view returns(uint) {
	    return(auctionlisting.length);
	}
	//获取投诉订单的总数
	function getacttslen() public view returns(uint) {
	    return(auctionlistts.length);
	}
	//获取竞拍完结的总数
	function getactendlen() public view returns(uint) {
	    return(auctionlistend.length);
	}
	//发布者设定发货
	function setsendgoods(uint auctids) public {
	    uint _now = now;
	     auctionlist storage c = auctionlisting[auctids];
	     require(c.adduser == msg.sender);
	     require(c.endtime < _now);
	     require(c.ifsend == 0);
	     c.ifsend = 1;
	     c.ifend = true;
	}
	//竞拍者收到货物后动作
	function setgetgoods(uint auctids) public {
	    uint _now = now;
	    auctionlist storage c = auctionlisting[auctids];
	    require(c.endtime < _now);
	    require(c.ifend == true);
	    require(c.ifsend == 1);
	    putusers storage lasttuser = c.aucusers[c.lastid];
	    require(lasttuser.puser == msg.sender);
	    c.ifsend = 2;
	    uint getmoney = lasttuser.addmoney*70/100;
	    btyc.mintToken(c.adduser, getmoney);
	    auctionlistend.push(c);
	}
	//获取用户的发货地址（发布者）
	function getuseraddress(uint auctids) public view returns(string){
	    auctionlist storage c = auctionlisting[auctids];
	    require(c.adduser == msg.sender);
	    //putusers memory mdata = c.aucusers[c.lastid];
	    return(c.aucusers[c.lastid].useraddr);
	}
	function editusetaddress(uint aid, string setaddr) public returns(bool){
	    auctionlist storage c = auctionlisting[aid];
	    putusers storage data = c.aucusers[c.lastid];
	    require(data.puser == msg.sender);
	    data.useraddr = setaddr;
	    return(true);
	}
	/*用户获取拍卖金额和返利，只能返利一次 */
	function endauction(uint auctids) public {
	    //uint _now = now;
	    auctionlist storage c = auctionlisting[auctids];
	    require(c.ifsend == 2);
	    uint len = c.lastid;
	    putusers storage firstuser = c.aucusers[0];
        address suser = msg.sender;
	    
	    require(c.ifend == true);
	    require(len > 1);
	    require(c.ausers[suser] > 0);
	    uint sendmoney = 0;
	    if(len == 2) {
	        require(firstuser.puser == suser);
	        sendmoney = c.currentprice*3/10 + c.ausers[suser];
	    }else{
	        if(firstuser.puser == suser) {
	            sendmoney = c.currentprice*1/10 + c.ausers[suser];
	        }else{
	            uint onemoney = (c.currentprice*2/10)/(len-2);
	            sendmoney = onemoney + c.ausers[suser];
	        }
	    }
	    require(sendmoney > 0);
	    c.ausers[suser] = 0;
	    btyc.mintToken(suser, sendmoney);
	    emit getmoneys(suser, sendmoney);
	    
	}
	//设定拍卖标准价
	function setsystemprice(uint price) public onlyadmin{
	    systemprice = price;
	}
	//管理员冻结发布者和商品
	function setauctionother(uint auctids) public onlyadmin{
	    auctionlist storage c = auctionlisting[auctids];
	    btyc.freezeAccount(c.adduser, true);
	    c.ifend = true;
	    c.ifsend = 3;
	}
	//设定商品状态
	function setauctionsystem(uint auctids, uint setnum) public onlyadmin{
	    auctionlist storage c = auctionlisting[auctids]; 
	    c.ifend = true;
	    c.ifsend = setnum;
	}
	
	//设定商品正常
	function setauctionotherfree(uint auctids) public onlyadmin{
	    auctionlist storage c = auctionlisting[auctids];
	    btyc.freezeAccount(c.adduser, false);
	    c.ifsend = 2;
	}
	//投诉发布者未发货或货物不符
	function tsauction(uint auctids) public{
	   auctionlist storage c = auctionlisting[auctids];
	   uint _now = now;
	   require(c.endtime > _now);
	   require(c.endtime + 2 days < _now);
	   require(c.aucusers[c.lastid].puser == msg.sender);
	   if(c.endtime + 2 days < _now && c.ifsend == 0) {
	       c.ifsend = 5;
	       c.ifend = true;
	       auctionlistts.push(c);
	   }
	   if(c.endtime + 9 days < _now && c.ifsend == 1) {
	       c.ifsend = 5;
	       c.ifend = true;
	       auctionlistts.push(c);
	   }
	}
	//管理员设定违规竞拍返还竞拍者
	function endauctionother(uint auctids) public {
	    //uint _now = now;
	    auctionlist storage c = auctionlisting[auctids];
	    address suser = msg.sender;
	    require(c.ifsend == 3);
	    require(c.ausers[suser] > 0);
	    btyc.mintToken(suser,c.ausers[suser]);
	    c.ausers[suser] = 0;
	    emit getmoneys(suser, c.ausers[suser]);
	}
	/*
	 * 设置管理员
	 * @param {Object} address
	 */
	function admAccount(address target, bool freeze) onlyOwner public {
		admins[target] = freeze;
	}
	
}
//btyc接口类
interface btycInterface {
    function balanceOf(address _addr) external view returns (uint256);
    function mintToken(address target, uint256 mintedAmount) external returns (bool);
    //function transfer(address to, uint tokens) external returns (bool);
    function freezeAccount(address target, bool freeze) external returns (bool);
    function getcanuse(address tokenOwner) external view returns(uint);
    //function getprice() external view returns(uint addtime, uint outtime, uint bprice, uint spice, uint sprice, uint sper, uint givefrom, uint giveto, uint giveper, uint sdfrozen, uint sdper1, uint sdper2, uint sdper3);
}
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