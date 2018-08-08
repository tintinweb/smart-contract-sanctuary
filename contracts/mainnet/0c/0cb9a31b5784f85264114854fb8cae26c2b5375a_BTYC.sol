pragma solidity ^0.4.23;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

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
// Owned contract
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
// ERC20 Token, with the addition of symbol, name and decimals and a
// fixed supply
// ----------------------------------------------------------------------------
contract BTYCToken is ERC20Interface, Owned {
     using SafeMath for uint;
    /*
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;*/

    uint256 public sellPrice; //出售价格 1枚代币换多少以太 /1000
	uint256 public buyPrice; //购买价格 多少以太可购买1枚代币 /1000
	uint256 public sysPrice; //挖矿的衡量值
	uint256 public sysPer; //挖矿的增量百分比 /100
	
	uint256 public onceOuttime; //增量的时间 测试  
	uint256 public onceAddTime; //挖矿的时间 测试
	uint256 public onceoutTimePer; //增量的百分比 测试
	
	
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /* 冻结账户 */
	mapping(address => bool) public frozenAccount;
	// 记录各个账户的冻结数目
	//mapping(address => uint256) public freezeOf;
	// 记录各个账户的可用数目
	mapping(address => uint256) public canOf;
	// 记录各个账户的释放时间
	mapping(address => uint) public cronoutOf;
	// 记录各个账户的增量时间
	mapping(address => uint) public cronaddOf;
	
	 /* 通知 */
	event FrozenFunds(address target, bool frozen);
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public{
       
        
        sellPrice = 510; //出售价格 1枚代币换多少以太 /1000000
    	buyPrice =  526; //购买价格 多少以太可购买1枚代币 /1000000
    	sysPrice = 766; //挖矿的衡量值
    	sysPer = 225; //挖矿的增量百分比 /100
    	
    	onceOuttime = 86400; //增量的时间 正式 
    	onceAddTime = 864000; //挖矿的时间 正式
    	onceoutTimePer = 8640000; //增量的百分比 正式
    	
    	//onceOuttime = 600; //增量的时间 测试  
    	//onceAddTime = 1800; //挖矿的时间 测试
    	//onceoutTimePer = 60000; //增量的百分比 测试
	
	
        
       
    }



    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function canuseOf(address tokenOwner) public view returns (uint balance) {
        return canOf[tokenOwner];
    }
    function myuseOf(address tokenOwner) public returns (uint balance) {
        //return balances[tokenOwner];
        if(cronoutOf[tokenOwner] < 1) {
			return 0;
		}else{
		    uint lefttimes = now - cronoutOf[tokenOwner];
    		if(lefttimes >= onceOuttime) {
    			uint leftpers = lefttimes / onceoutTimePer;
    			if(leftpers > 1) {
    				leftpers = 1;
    			}
    			canOf[tokenOwner] = balances[tokenOwner] * leftpers;
    			return canOf[tokenOwner];
    		}else{
    		    return canOf[tokenOwner];
    		}
		}
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[to]);
        canOf[msg.sender] = myuseOf(msg.sender);
        canOf[msg.sender] = canOf[msg.sender].sub(tokens);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    /*
    function buytoken(address user, uint256 amount) public{
        balances[user] = balances[user].sub(amount);
        //buyeth(amount);
        emit Transfer(address(0), user, amount);
    }*/
    
    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    /// 向指定账户拨发资金
	function mintToken(address target, uint256 mintedAmount) onlyOwner public {
		require(!frozenAccount[target]);
		if(cronoutOf[target] < 1) {
		    cronoutOf[target] = now + onceOuttime;
		}
		if(cronaddOf[target] < 1) {
		    cronaddOf[target] = now + onceAddTime;
		}

		balances[target] += mintedAmount;
		uint256 amounts = mintedAmount / 100;
		canOf[target] += amounts;
		//emit Transfer(0, this, mintedAmount);
		emit Transfer(this, target, mintedAmount);

	}
	//用户每隔10天挖矿一次
	function mint() public {
		require(!frozenAccount[msg.sender]);
		require(cronaddOf[msg.sender] > 0 && now > cronaddOf[msg.sender]);
		uint256 mintAmount = balances[msg.sender] * sysPer / 10000;
		balances[msg.sender] += mintAmount;
		cronaddOf[msg.sender] = now + onceAddTime;
		//emit Transfer(0, this, mintAmount);
		emit Transfer(this, msg.sender, mintAmount);

	}
    
	/// 冻结 or 解冻账户
	function freezeAccount(address target, bool freeze) onlyOwner public {
		frozenAccount[target] = freeze;
		emit FrozenFunds(target, freeze);
	}
	// 设置销售购买价格
	function setPrices( uint256 newBuyPrice, uint256 newSellPrice, uint256 systyPrice, uint256 sysPermit) onlyOwner public {
		buyPrice = newBuyPrice;
		sellPrice = newSellPrice;
		sysPrice = systyPrice;
		sysPer = sysPermit;
	}
	// 获取价格 
	function getprice()  public view returns (uint256 bprice,uint256 spice,uint256 sprice,uint256 sper) {
          bprice = buyPrice;
          spice = sellPrice;
          sprice = sysPrice;
          sper = sysPer;
   }
   


    
}
contract BTYC is BTYCToken{
  string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public{
        symbol = "BTYC";
        name = "BTYC Coin";
        decimals = 18;
        _totalSupply = 86400000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }
    /*
    function buy(uint money) public payable {
        require(!frozenAccount[msg.sender]);
        uint amount = money * buyPrice;
        balances[msg.sender] += amount;
        //msg.sender.transfer(money);
        emit Transfer(this, msg.sender, amount);
    }
    function () payable public {
        buy(msg.value);
    }
    /*
    function selleth(uint amount) public payable {
        //address user = msg.sender;
        //canOf[user] = myuseOf(user);
        //require(balances[user] >= amount );
        //uint money = amount * sellPrice;
       // balances[msg.sender] += money;
        owner.transfer(amount);
    }*/
    /*
    function sell(uint amount)  public returns (bool success){
        //address user = msg.sender;
        //canOf[msg.sender] = myuseOf(msg.sender);
        //require(!frozenAccount[msg.sender]);
        require(canOf[msg.sender] >= amount ); 
        balances[msg.sender] -= amount;
        canOf[msg.sender] -= amount;
        uint moneys = amount / sellPrice;
        msg.sender.transfer(moneys);
        //canOf[user] -= amount;
        return true;              
    }*/
    

  
}