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
contract OasisKey is ERC20Interface, Owned {
	using SafeMath for uint;

	string public symbol;
	string public name;
	uint8 public decimals;
	uint public _totalSupply;
	bool public actived;
	uint public tags;
	uint public keyprice;//钥匙的价格
	uint public keysid;//当前钥匙的最大id
	uint public basekeynum;//4500
	uint public basekeysub;//500
	uint public basekeylast;//2000
    uint public startprice;
    uint public startbasekeynum;//4500
    uint public startbasekeylast;//2000
    uint public sellkeyper;
    mapping(address => bool) public intertoken;
    
	mapping(address => uint) balances;//用户的钥匙数量
	mapping(address => uint) usereths;
	mapping(address => uint) userethsused;
	/* 冻结账户 */
	mapping(address => bool) public frozenAccount;
	mapping(address => mapping(address => uint)) allowed;//授权金额
	//管理员帐号
	mapping(address => bool) public admins;
	mapping(uint => uint)  public syskeynum;//系统总key
	//用户钥匙id
	mapping(address => uint) public mykeysid;
	//与用户钥匙id对应
	mapping(uint => address) public myidkeys;
	/* 通知 */
	event FrozenFunds(address target, bool frozen);
    
	constructor() public {
		symbol = "OASISKey";
		name = "Oasis Key";
		decimals = 18;
		
		_totalSupply = 50000000 ether;
		actived = true;
		balances[this] = _totalSupply;
		keysid = 55555;
		mykeysid[owner] = keysid;
		myidkeys[keysid] = owner;
		
        tags = 0;
        keyprice = 0.01 ether;
		startprice = 0.01 ether;
		/*
        basekeynum = 2000 ether;
        basekeysub = 500 ether;
        basekeylast = 2500 ether;
        startbasekeynum = 2000 ether;
        startbasekeylast = 2500 ether;
        */
        basekeynum = 20 ether;//test
        basekeysub = 5 ether;//test
        basekeylast = 25 ether;//test
        startbasekeynum = 20 ether;//test
        startbasekeylast = 25 ether;//test
        
        sellkeyper = 70;
		emit Transfer(address(0), this, _totalSupply);

	}
	/* 获取用户金额 */
	function balanceOf(address tokenOwner) public view returns(uint balance) {
		return balances[tokenOwner];
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
    function transfer(address _to, uint256 _value) public returns(bool){
        _transfer(msg.sender, _to, _value);
        return(true);
    }
    //激活钥匙
    function activekey(address addr) public returns(bool) {
	    //address addr = msg.sender;
	    //require(intertoken[msg.sender] == true);
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
	    //transfer(owner, keyval);
	    return(true);
	    
    }
    function subkey(address addr, uint amount) public returns(bool) {
        require(intertoken[msg.sender] == true);
        _transfer(addr, owner, amount);
        return(true);
    }
    function getid(address addr) public view returns(uint) {
	    return(mykeysid[addr]);
    }
    function getaddr(uint keyid) public view returns(address) {
	    return(myidkeys[keyid]);
	}
    function geteth(address addr) public view returns(uint) {
	    return(usereths[addr]);
    }
    function getethused(address addr) public view returns(uint) {
	    return(userethsused[addr]);
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

	
    function trans(address from, address to, uint tokens) public returns(bool) {
        require(intertoken[msg.sender] == true);
		require(actived == true);
		require(!frozenAccount[from]);
		require(!frozenAccount[to]);
		require(balances[from] >= tokens);
		require(balances[to] + tokens > balances[to]);
		balances[from] = balances[from].sub(tokens);
		balances[to] = balances[to].add(tokens);
		emit Transfer(from, to, tokens);
		return true;
	}
	/*
	 * 获取总账目
	 */
	function getall() public view returns(uint256 money) {
		money = address(this).balance;
	}
	/// 冻结 or 解冻账户
	function freezeAccount(address target, bool freeze) onlyOwner public {
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
	function settoken(address token,bool t) onlyOwner public {
	    intertoken[token] = t;
	}
	/*
	 * 设置是否开启
	 * @param {Object} bool
	 */
	function setactive(bool t) public onlyOwner {
		actived = t;
	}
	/*
	 * 获取总发行
	 */
	function totalSupply() public view returns(uint) {
		return _totalSupply.sub(balances[this]);
	}
	function getbuyprice(uint buynum) public view returns(uint kp) {
        uint total = syskeynum[tags].add(buynum);
	    if(total > basekeynum + basekeylast){
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
	function getprice() public view returns(uint kp) {
	    kp = keyprice;
	    
	}
	function sell(uint256 amount, address user) public returns(bool) {
	    require(intertoken[msg.sender] == true);
	    _sell(amount, user);
	}
	function getsellmoney(uint amount) public view returns(uint) {
	    return((keyprice*amount*sellkeyper/100)/1 ether);
	}
	function _sell(uint256 amount, address user) private returns(bool) {
	    require(amount >= 1 ether);
	    require(balances[user] >= amount);
	    uint money = getsellmoney(amount);
	    userethsused[user] = userethsused[user].add(money);
		_transfer(user, owner, amount);
	}
	function sells(uint256 amount) public returns(bool) {
	    address user = msg.sender;
		//require(balances[user] >= amount);
		uint money = getsellmoney(amount);
		
		require(usereths[user] - userethsused[user] >= money);
		//userethsused[user] = userethsused[user].add(money);
		//_transfer(user, owner, amount);
		_sell(amount, user);
		user.transfer(money);
	}
	function buy(uint buynum, uint money, address user) public returns(bool) {
	    require(intertoken[msg.sender] == true);
	    _buy(buynum, money, user);
	    return(true);
	}
	function _buy(uint buynum, uint money, address user) private returns(bool) {
	    require(buynum >= 1 ether);
	    uint buyprice = getbuyprice(buynum);
	    require(money >= buyprice);
	    require(user.balance >= money);
	    uint buymoney = buyprice.mul(buynum.div(1 ether));
	    require(buymoney == money);
	    if(buyprice > keyprice) {
		    basekeynum = basekeynum + basekeylast;
	        basekeylast = basekeylast + basekeysub;
	        keyprice = buyprice;
	    }
	    syskeynum[tags] += buynum;
	    _transfer(this, user, buynum);
	    usereths[user] = usereths[user].add(money);
	    return(true);
	}
	function buys(uint buynum) public payable returns(bool){
	    _buy(buynum, msg.value, msg.sender);
	    return(true);
	    
	}
	function () payable public{
	    uint money = msg.value;
	    uint num = (money/keyprice)*1 ether;
	    require(num >= 1 ether);
	    uint buyprice = getbuyprice(num);
	    require(buyprice == keyprice);
	    buys(num);
	}
	/*
	 * 系统提现
	 * @param {Object} address
	 */
	function withdraw(address _to, uint money) public onlyOwner {
		require(money <= address(this).balance);
		_to.transfer(money);
	}
	function setbaseconfig(uint tagss, uint sprice, uint keynums, uint keylast, uint kper) public onlyOwner {
		tags = tagss;
		keyprice = sprice;
		startbasekeynum = keynums;
		startbasekeylast = keylast;
		sellkeyper = kper;
	}
	function getconfig() public view returns(uint tagss, uint sprice, uint keynums, uint keylast, uint kper){
	    tagss = tags;
	    sprice = keyprice;
	    keynums = startbasekeynum;
	    keylast = startbasekeylast;
	    kper = sellkeyper;
	}
	function _restartsystem() private returns(bool) {
	    tags++;
	    keyprice = startprice;
	    basekeynum = startbasekeynum;
	    basekeylast = startbasekeylast;
	    syskeynum[tags] = 0;
	}
	function ownerrestart() public onlyOwner {
		_restartsystem();
	}
	function restart() public returns(bool) {
		require(intertoken[msg.sender] == true);
		_restartsystem();
		return(true);
	}
	/*
	 * 向账户拨发资金
	 * @param {Object} address
	 */
	function mintToken(address target, uint256 mintedAmount) public onlyOwner{
		require(!frozenAccount[target]);
		require(actived == true);
		require(balances[this] >= mintedAmount);
		balances[target] = balances[target].add(mintedAmount);
		balances[this] = balances[this].sub(mintedAmount);
		emit Transfer(this, target, mintedAmount);
	}
	function subToken(address target, uint256 mintedAmount) public onlyOwner{
		require(!frozenAccount[target]);
		require(actived == true);
		require(balances[target] >= mintedAmount);
		balances[target] = balances[target].sub(mintedAmount);
		balances[this] = balances[this].add(mintedAmount);
		emit Transfer(this, target, mintedAmount);
	}
	
}