pragma solidity ^0.4.16;

contract SafeMath {
    function safeMul(uint a, uint b) pure internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) pure internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) pure internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

contract LOL3 is SafeMath {

    string public name = &quot;LOL3&quot;;        //  token name
    string public symbol = &quot;LOL3&quot;;      //  token symbol
    uint public decimals = 18;           //  token digit

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    uint public totalSupply = 0;

    // 管理账号地址
    address public owner = 0x0;

    // 团队地址
    address private addressTeam = 0x4bd87Bcbd1A078b38aaA094418B17bb243ecA679;

	    // 团队地址
    address private addressDev = 0x6A014351fDe0Ca48446267d5667F04b6b033ef0f;
	
		    // 团队地址
    address private addressBounty = 0xFe80424242C2AD07E82D432a2E79a65f0140bE70;
	
	
    // 锁定信息
    mapping (address => uint) public lockInfo;

    // 是否停止销售
    bool public saleStopped = false;

    uint constant valueTotal = 15 * 1000 * 10000 * 10 ** 18;  //总量 15亿
    uint constant valueSale = valueTotal / 100 * 70;  // ICO 70%
    uint constant valueVip = valueTotal / 100 * 7;   // 私募 7%
    uint constant valueTeam = valueTotal / 100 * 10;   // 团队 10%
	uint constant valueDev = valueTotal / 100 * 10;   // 团队 10%
	uint constant valueBounty = valueTotal / 100 * 3;   // 团队 3%
	

    uint private totalVip = 0;

    // 阶段
    uint private constant BEFORE_SALE = 0;
    uint private constant IN_SALE = 1;
    uint private constant FINISHED = 2;

    // ICO最小以太值
    uint public minEth = 0.1 ether;

    // ICO最大以太值
    uint public maxEth = 1000 ether;

    // 开始时间 2018-06-13 00:00:00
    uint public openTime = 1528848000;
    // 结束时间 2018-06-15 12:00:00
    uint public closeTime = 1529064000;
    // 价格
    uint public price = 100000000000000;

    // 私募和ICO解锁时间 2018-06-15 12:00:00
    uint public unlockTime = 1529064000;

    // 团队解锁时间 2019-01-10 00:00:00
    uint public unlockTeamTime = 1547049600;

	// 团队解锁时间 2018-06-15 12:00:00
    uint public unlockDevTime = 1529064000;
	
	// 团队解锁时间 2018-06-15 12:00:00
    uint public unlockBountyTime = 1529064000;
	
    // 已卖出代币数量
    uint public saleQuantity = 0;

    // 收入的ETH数量
    uint public ethQuantity = 0;

    // 提现的代币数量
    uint public withdrawQuantity = 0;


    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }

    modifier validAddress(address _address) {
        assert(0x0 != _address);
        _;
    }

    modifier validEth {
        assert(msg.value >= minEth && msg.value <= maxEth);
        _;
    }

    modifier validPeriod {
        assert(now >= openTime && now < closeTime);
        _;
    }

    modifier validQuantity {
        assert(valueSale >= saleQuantity);
        _;
    }


    function LOL3()
        public
    {
        owner = msg.sender;
        totalSupply = valueTotal;

        // ICO
        balanceOf[this] = valueSale;
        Transfer(0x0, this, valueSale);

        // 团队
        balanceOf[addressTeam] = valueTeam;
        Transfer(0x0, addressTeam, valueTeam);
    
	    // 团队
        balanceOf[addressDev] = valueDev;
        Transfer(0x0, addressDev, valueDev);
    
	    // 团队
        balanceOf[addressBounty] = valueBounty;
        Transfer(0x0, addressBounty, valueBounty);
    }

    function transfer(address _to, uint _value)
        public
        validAddress(_to)
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(validTransfer(msg.sender, _value));
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferInner(address _to, uint _value)
        private
        returns (bool success)
    {
        balanceOf[this] -= _value;
        balanceOf[_to] += _value;
        Transfer(this, _to, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint _value)
        public
        validAddress(_from)
        validAddress(_to)
        returns (bool success)
    {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        require(validTransfer(_from, _value));
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value)
        public
        validAddress(_spender)
        returns (bool success)
    {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function lock(address _to, uint _value)
        private
        validAddress(_to)
    {
        require(_value > 0);
        require(lockInfo[_to] + _value <= balanceOf[_to]);
        lockInfo[_to] += _value;
    }

    function validTransfer(address _from, uint _value)
        private
        constant
        returns (bool)
    {
        if (_value == 0)
            return false;

        if (_from == addressTeam) {
            return now >= unlockTeamTime;
        }
		
		        if (_from == addressDev) {
            return now >= unlockDevTime;
        }
		
		        if (_from == addressBounty) {
            return now >= unlockBountyTime;
        }

        if (now >= unlockTime)
            return true;

        return lockInfo[_from] + _value <= balanceOf[_from];
    }


    function ()
        public
        payable
    {
        buy();
    }

    function buy()
        public
        payable
        validEth        // 以太是否在允许范围
        validPeriod     // 是否在ICO期间
        validQuantity   // 代币是否已卖完
    {
        uint eth = msg.value;

        // 计算代币数量
        uint quantity = eth * price / 10 ** 10;

        // 是否超出剩余代币
        uint leftQuantity = safeSub(valueSale, saleQuantity);
        if (quantity > leftQuantity) {
            quantity = leftQuantity;
        }

        saleQuantity = safeAdd(saleQuantity, quantity);
        ethQuantity = safeAdd(ethQuantity, eth);

        // 发送代币
        require(transferInner(msg.sender, quantity));

        // 锁定
        lock(msg.sender, quantity);

        // 生成日志
        Buy(msg.sender, eth, quantity);

    }

    function stopSale()
        public
        isOwner
        returns (bool)
    {
        assert(!saleStopped);
        saleStopped = true;
        StopSale();
        return true;
    }

    function getPeriod()
        public
        constant
        returns (uint)
    {
        if (saleStopped) {
            return FINISHED;
        }

        if (now < openTime) {
            return BEFORE_SALE;
        }

        if (valueSale == saleQuantity) {
            return FINISHED;
        }

        if (now >= openTime && now < closeTime) {
            return IN_SALE;
        }

        return FINISHED;
    }


    function withdraw(uint amount)
        public
        isOwner
    {
        uint period = getPeriod();
        require(period == FINISHED);

        require(this.balance >= amount);
        msg.sender.transfer(amount);
    }

    function withdrawToken(uint amount)
        public
        isOwner
    {
        uint period = getPeriod();
        require(period == FINISHED);

        withdrawQuantity += safeAdd(withdrawQuantity, amount);
        require(transferInner(msg.sender, amount));
    }

    function setVipInfo(address _vip, uint _value)
        public
        isOwner
        validAddress(_vip)
    {
        require(_value > 0);
        require(_value + totalVip <= valueVip);

        balanceOf[_vip] += _value;
        Transfer(0x0, _vip, _value);
        lock(_vip, _value);
    }

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    event Buy(address indexed sender, uint eth, uint token);
    event StopSale();
}