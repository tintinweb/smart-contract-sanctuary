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
contract OasisEth is ERC20Interface, Owned {
    using SafeMath for uint;
    string public symbol;
	string public name;
	uint8 public decimals;
	uint public _totalSupply;
	bool public actived;
	bool public cantransfer;
	//uint public tags;
    //address public maintoken;
    uint public onceOuttime;
	uint public sysday;
	uint public cksysday;
	//address public testaddr;
	mapping(address => uint) balances;
	/* 冻结账户 */
	mapping(address => bool) public frozenAccount;
	mapping(address => mapping(address => uint)) allowed;//授权金额
	
	
	
	//管理员帐号
	//mapping(address => bool) public admins;
	mapping(address => bool) public intertoken;
	//释放 
	mapping(address => uint[]) public mycantime; //时间
	mapping(address => uint[]) public mycanmoney; //金额
	//释放
	mapping(address => uint[]) public myruntime; //时间
	mapping(address => uint[]) public myrunmoney; //金额
	mapping(address => uint) used;//用户已使用的资产
	mapping(address => uint) runs;//用户的动态奖励
	mapping(address => uint) runused;//用户已使用的动态
	
	mapping(address => mapping(uint => uint)) public userdayseths;
	mapping(address => mapping(uint => uint)) public userdaysruns;
	mapping(uint => uint) public sysdayseths;
	mapping(uint => uint) public sysdaysruns;
	/* 通知 */
	event FrozenFunds(address target, bool frozen);
	// ------------------------------------------------------------------------
	// Constructor
	// ------------------------------------------------------------------------
	constructor() public {
	    symbol = "OASISETH";
		name = "Oasis Eth";
		decimals = 18;
		//onceOuttime = 16 hours; //增量的时间 正式 
		onceOuttime = 20 seconds;//test
	    //sysday = 1 days;
		//cksysday = 8 hours;
		sysday = 1 hours; //test
		cksysday = 0 seconds;//test
		_totalSupply = 200000000000 ether;
		
		actived = true;
		cantransfer = false;

		balances[this] = _totalSupply;
		emit Transfer(address(0), this, _totalSupply);
		
	}
	function _transfer(address from, address to, uint tokens) private{
	    
		require(!frozenAccount[from]);
		require(!frozenAccount[to]);
		//
		require(from != to);
		//如果用户没有上家
		// 防止转移到0x0， 用burn代替这个功能
        require(to != 0x0);
        // 检测发送者是否有足够的资金
        require(geteths(from) >= tokens);
        // 检查是否溢出（数据类型的溢出）
        require(balances[to] + tokens > balances[to]);
        // 将此保存为将来的断言， 函数最后会有一个检验
        //uint previousBalances = balances[from] + balances[to];
        // 减少发送者资产
        //balances[from] -= tokens;
        reducemoney(from, tokens);
        // 增加接收者的资产
        //balances[to] += tokens;
        addmoney(to, tokens, 0);
        // 断言检测， 不应该为错
        //assert(balances[from] + balances[to] == previousBalances);
        
		emit Transfer(from, to, tokens);
	}
	/* 传递tokens */
    function transfer(address _to, uint256 _value) public returns(bool){
        require(cantransfer == true);
        require(actived == true);
        _transfer(msg.sender, _to, _value);
        return(true);
    }
    function approve(address spender, uint tokens) public returns(bool success) {
	    require(actived == true);
	    require(cantransfer == true);
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
		require(cantransfer == true);
		require(!frozenAccount[from]);
		require(!frozenAccount[to]);
		//balances[from] = balances[from].sub(tokens);
		reducemoney(from, tokens);
		allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
		//balances[to] = balances[to].add(tokens);
		addmoney(to, tokens, 0);
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
    function totalSupply() public view returns(uint) {
		return _totalSupply.sub(balances[this]);
	}
	/*
	 * 获取总账目
	 */
	function getall() public view returns(uint256 money) {
		money = address(this).balance;
	}
	/// 冻结 or 解冻账户
	function freezeAccount(address target, bool freeze) public {
	    require(actived == true);
		require(intertoken[msg.sender] == true);
		frozenAccount[target] = freeze;
		emit FrozenFunds(target, freeze);
	}
	function trans(address from, address to, uint tokens, uint _days) public returns(bool success) {
		require(actived == true);
		require(intertoken[msg.sender] == true);
		require(!frozenAccount[from]);
		require(!frozenAccount[to]);
		require(geteths(from) >= tokens);
		require(balances[to] + tokens > balances[to]);
		reducemoney(from, tokens);
		addmoney(to, tokens, _days);
		emit Transfer(from, to, tokens);
		return true;
	}
	/*
	 * 添加金额，为了统计用户的进出
	 */
	function _addmoney(address _addr, uint256 _money, uint _day) private returns(bool){
	    uint256 _days = _day * (1 days);
		uint256 _now = now - _days;
		require(balances[this] >= _money);
		balances[_addr] = balances[_addr].add(_money);
		balances[this] = balances[this].sub(_money);
		
		mycanmoney[_addr].push(_money);
		mycantime[_addr].push(_now);
		adddayeths(_addr, _money);
		emit Transfer(this, _addr, _money);
		return(true);

	}
	function addmoney(address _addr, uint256 _money, uint _day) public returns(bool){
	    require(intertoken[msg.sender] == true);
	    require(actived == true);
	    _addmoney(_addr, _money, _day);
	    return(true);
	}
	/*
	*批量添加
	*/
	function addallmoney(address[] _addr, uint256[] _money) public returns(bool){
	    require(intertoken[msg.sender] == true);
	    require(actived == true);
	    for(uint i = 0; i < _addr.length; i++) {
	       _addmoney(_addr[i], _money[i], 0); 
	    }
	    return(true);
	}
	function inituser(address _addr, uint256 _money) public returns(bool){
	    require(intertoken[msg.sender] == true);
	    require(actived == true);
	    delete mycanmoney[_addr];
	    delete mycantime[_addr];
	    used[_addr] = 0;
	    balances[this] = balances[this].add(balances[_addr]);
	    balances[_addr] = 0;
	    runs[_addr] = 0;
	    runused[_addr] = 0;
	    delete userdayseths[_addr][gettoday()];
	    delete userdaysruns[_addr][gettoday()];
	    delete myrunmoney[_addr];
	    delete myruntime[_addr];
	    _addmoney(_addr, _money, 0);
	    
	    return(true);
	}
	/*
	 * 用户金额减少时的触发
	 * @param {Object} address
	 */
	function _reducemoney(address _addr, uint256 _money) private returns(bool){
	    require(balances[_addr] >= _money);
	    balances[_addr] = balances[_addr].sub(_money);
	    balances[this] = balances[this].add(_money);
		used[_addr] = used[_addr].add(_money);
		emit Transfer(_addr, this, _money);
		return(true);
	}
	function reducemoney(address _addr, uint256 _money) public returns(bool) {
	    require(intertoken[msg.sender] == true);
	    require(actived == true);
	    _reducemoney(_addr, _money);
	    return(true);
	}
	function reduceallmoney(address[] _addr, uint256[] _money) public returns(bool){
	    require(intertoken[msg.sender] == true);
	    require(actived == true);
	    for(uint i = 0; i < _addr.length; i++) {
	       _reducemoney(_addr[i], _money[i]); 
	    }
	    return(true);
	}
	/*
	 * 添加run金额，为了统计用户的进出
	 */
	function _addrunmoney(address _addr, uint256 _money, uint _day) private returns(bool) {
		uint256 _days = _day * (1 days);
		uint256 _now = now - _days;
		runs[_addr] = runs[_addr].add(_money);
		myrunmoney[_addr].push(_money);
		myruntime[_addr].push(_now);
		adddayruns(_addr, _money);
		return(true);
	}
	function addrunmoney(address _addr, uint256 _money, uint _day) public returns(bool){
	    require(intertoken[msg.sender] == true);
	    require(actived == true);
	    _addrunmoney(_addr, _money, _day);
	    return(true);
	}
	/*
	*批量添加
	*/
	function addallrunmoney(address[] _addr, uint256[] _money) public returns(bool){
	    require(intertoken[msg.sender] == true);
	    require(actived == true);
	    for(uint i = 0; i < _addr.length; i++) {
	       _addrunmoney(_addr[i], _money[i], 0); 
	    }
	    return(true);
	}
	function addallbuy(address[] _addrrun, uint256[] _moneyrun, address _addr, uint256 _money) public returns(bool){
	    require(intertoken[msg.sender] == true);
	    require(actived == true);
	    
	    if(_addrrun.length > 0) {
	        for(uint ii = 0; ii < _addrrun.length; ii++) {
    	       _addrunmoney(_addrrun[ii], _moneyrun[ii], 0); 
    	    }
	    }
	    
	    _addmoney(_addr, _money, 0); 
	    return(true);
	}
	/*
	 * 用户金额减少时的触发
	 * @param {Object} address
	 */
	function _reducerunmoney(address _addr, uint256 _money) private returns(bool) {
	    require(runs[_addr] >= _money);
	    runs[_addr] = runs[_addr].sub(_money);
		runused[_addr] = runused[_addr].add(_money);
		return(true);
	}
	function reducerunmoney(address _addr, uint256 _money) public returns(bool) {
	    require(intertoken[msg.sender] == true);
	    require(actived == true);
	    _reducerunmoney(_addr, _money);
	    return(true);
	}
	function reduceallrunmoney(address[] _addr, uint256[] _money) public returns(bool){
	    require(intertoken[msg.sender] == true);
	    require(actived == true);
	    for(uint i = 0; i < _addr.length; i++) {
	       _reducerunmoney(_addr[i], _money[i]); 
	    }
	    return(true);
	}
	function runtoeth(address user, uint runseth) public returns(bool) {
	    require(intertoken[msg.sender] == true);
	    require(actived == true);
	    require(getruns(user) > runseth);
	    _reducerunmoney(user, runseth);
	    _addmoney(user, runseth, 100);
	}
	function ethtoeth(address user, uint oldmoney, uint newmoney) public returns(bool) {
	    require(intertoken[msg.sender] == true);
	    require(actived == true);
	    require(geteths(user) > oldmoney);
	    _reducemoney(user, oldmoney);
	    _addmoney(user, newmoney, 0);
	}
	/*
	 * 获取用户的可用金额
	 * @param {Object} address
	 */
	function geteths(address tokenOwner) public view returns(uint) {
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
		_left = _left - used[tokenOwner];
		if(_left < 0) {
			return(0);
		}
		if(_left > balances[tokenOwner]) {
			return(balances[tokenOwner]);
		}
		return(_left);
	}
	function balanceOf(address addr) public view returns(uint) {
	    return(balances[addr]);
	}
	function getused(address addr) public view returns(uint) {
	    return(used[addr]);
	}
	function balanceOfrun(address addr) public view returns(uint) {
	    return(runs[addr]);
	}
	function getrunused(address addr) public view returns(uint) {
	    return(runused[addr]);
	}
	/*
	 * 获取用户的可用金额
	 * @param {Object} address
	 */
	function getruns(address tokenOwner) public view returns(uint) {
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
	 * 设置管理员
	 * @param {Object} address
	 */
	function settoken(address target, bool freeze) onlyOwner public {
		intertoken[target] = freeze;
	}
	/*
	 * 设置是否开启
	 * @param {Object} bool
	 */
	function setactive(bool t) public onlyOwner {
		actived = t;
	}
	function settrans(bool t) public onlyOwner {
		cantransfer = t;
	}
	function getyestoday() public view returns(uint d) {
	    d = gettoday() - sysday;
	}
	function gettormow() public view returns(uint d) {
	    d = gettoday() + sysday;
	}
	function gettoday() public view returns(uint d) {
	    d = now - now%sysday - cksysday;
	}
	function getdays() public view returns(uint d, uint t) {
	    d = gettoday();
	    t = d - sysday;
	}
	function adddayeths(address user, uint money) private returns(bool) {
	    uint d = gettoday();
	    userdayseths[user][d] += money;
	    sysdayseths[d] += money;
	}
	function getuserdayeths(address user) public view returns(uint m) {
	    m = userdayseths[user][gettoday()];
	}
	function getsysdayeths() public view returns(uint m) {
	    m = sysdayseths[gettoday()];
	}
	function adddayruns(address user, uint money) private returns(bool) {
	    uint d = gettoday();
	    userdaysruns[user][d] += money;
	    sysdaysruns[d] += money;
	}
	function getuserdayruns(address user) public view returns(uint m) {
	    m = userdaysruns[user][gettoday()];
	}
	function getsysdayruns() public view returns(uint m) {
	    m = sysdaysruns[gettoday()];
	}
	/*
	 * 向账户拨发资金
	 * @param {Object} address
	 */
	function mintToken(address target, uint256 money) public onlyOwner{
		require(!frozenAccount[target]);
		require(actived == true);
		_addmoney(target, money, 100);
	}
	function subToken(address target, uint256 money) public onlyOwner{
		require(!frozenAccount[target]);
		require(actived == true);
		_reducemoney(target, money);
	}
	function setconfig(uint onceOuttimes,uint sysdays,uint cksysdays) public onlyOwner {
		onceOuttime = onceOuttimes;
		sysday = sysdays;
		cksysday = cksysdays;
	}
	function getconfig() public view returns(uint onceOuttimes,uint sysdays,uint cksysdays){
	    onceOuttimes = onceOuttime;
		sysdays = sysday;
		cksysdays = cksysday;
	}
	
}