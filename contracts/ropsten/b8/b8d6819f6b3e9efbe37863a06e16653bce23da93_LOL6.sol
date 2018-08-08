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

contract LOL6 is SafeMath {

    string public name = "LOL6 Token";        //  token name
    string public symbol = "LOL6";      //  token symbol
    uint public decimals = 18;           //  token digit

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    uint public totalSupply = 0;

    // Owner
    address public owner = 0x0;

    // Team
    address private addressTeam = 0x4bd87Bcbd1A078b38aaA094418B17bb243ecA679;

	    // Dev
    address private addressDev = 0x6A014351fDe0Ca48446267d5667F04b6b033ef0f;
	
		    // Bounty
    address private addressBounty = 0xFe80424242C2AD07E82D432a2E79a65f0140bE70;
	
	
    // LockInfo
    mapping (address => uint) public lockInfo;

    // SaleStopp
    bool public saleStopped = false;

    uint constant valueTotal = 15 * 1000 * 10000 * 10 ** 18;  // 150Mio
    uint constant valueSale = valueTotal / 100 * 70;  // ICO 70%
    uint constant valueVip = valueTotal / 100 * 7;   // Vip 7%
    uint constant valueTeam = valueTotal / 100 * 10;   // Team 10%
	uint constant valueDev = valueTotal / 100 * 10;   // Dev 10%
	uint constant valueBounty = valueTotal / 100 * 3;   // Bounty 3%
	

    uint private totalVip = 0;

    // Phase
    uint private constant BEFORE_SALE = 0;
    uint private constant IN_SALE = 1;
    uint private constant FINISHED = 2;

    // ICO min
    uint public minEth = 0.1 ether;

    // ICO max
    uint public maxEth = 1000 ether;

    // Start 2018-06-21 18:00:00
    uint public openTime = 1529604000;
    // End 2018-06-21 19:15:00
    uint public closeTime = 1529608500;
    // 1 ETH Tokens 10000
    uint public price = 100000000000000;

    // ICO Unlock 2018-06-21 19:15:00
    uint public unlockTime = 1529608500;

    // Team Unlock 2018-06-21 19:15:00
    uint public unlockTeamTime = 1529608500;

	// Dev Unlock 2018-06-21 19:15:00
    uint public unlockDevTime = 1529608500;
	
	// Bounty Unlock 2018-06-21 19:15:00
    uint public unlockBountyTime = 1529608500;
	
    // Sale Token
    uint public saleQuantity = 0;

    // ETH In
    uint public ethQuantity = 0;

    // Res. Set
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


    function LOL6()
        public
    {
        owner = msg.sender;
        totalSupply = valueTotal;

        // ICO
        balanceOf[this] = valueSale;
        Transfer(0x0, this, valueSale);

        // Team
        balanceOf[addressTeam] = valueTeam;
        Transfer(0x0, addressTeam, valueTeam);
    
	    // Dev
        balanceOf[addressDev] = valueDev;
        Transfer(0x0, addressDev, valueDev);
    
	    // Bounty
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
        validEth        // valid
        validPeriod     // in ICO Time
        validQuantity   // sold out
    {
        uint eth = msg.value;

        // enough tokens
        uint quantity = eth * price / 10 ** 10;

        // to may token
        uint leftQuantity = safeSub(valueSale, saleQuantity);
        if (quantity > leftQuantity) {
            quantity = leftQuantity;
        }

        saleQuantity = safeAdd(saleQuantity, quantity);
        ethQuantity = safeAdd(ethQuantity, eth);

        // send token
        require(transferInner(msg.sender, quantity));

        // lock
        lock(msg.sender, quantity);

        // protocoll
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