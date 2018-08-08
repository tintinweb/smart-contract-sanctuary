pragma solidity 0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value > 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_from != address(0));
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract EIForceCoin is StandardToken, Ownable {

    string public name = " EIForceCoin ";
    string public symbol = "EFT";
    uint public decimals = 18;

    // The token allocation
    uint public constant TOTAL_SUPPLY       = 1000000000e18;
    uint public constant ALLOC_FOUNDER    =  1000000000e18; // 100%


    // wallets
    address public constant WALLET_FOUNDER    = 0x4aDE23e2dc751527b16289c18c7E26fE4dF7a4B7; 
    
    
    // 2 groups of lockup
    mapping(address => uint256) public jishis_locked; 
    mapping(address => uint256) public simus_locked;
    mapping(address => uint256) public jiedians_locked;
    mapping(address => uint256) public dakehus_locked;

    // 2 types of releasing
    mapping(address => uint256) public jishis_jishiDate;
    mapping(address => uint256) public simus_simuDate;
    mapping(address => uint256) public jiedians_jiedianDate;
    mapping(address => uint256) public dakehus_dakehuDate;

    // MODIFIER

    // checks if the address can transfer certain amount of tokens
    modifier canTransfer(address _sender, uint256 _value) {
        require(_sender != address(0));

        uint256 remaining = balances[_sender].sub(_value);
        uint256 totalLockAmt = 0;

        if (jishis_locked[_sender] > 0) {
            totalLockAmt = totalLockAmt.add(getLockedAmount_jishis(_sender));
        }

        if (simus_locked[_sender] > 0) {
            totalLockAmt = totalLockAmt.add(getLockedAmount_simus(_sender));
        }

  		if (simus_locked[_sender] > 0) {
            totalLockAmt = totalLockAmt.add(getLockedAmount_jiedians(_sender));
        }

 		 if (simus_locked[_sender] > 0) {
            totalLockAmt = totalLockAmt.add(getLockedAmount_dakehus(_sender));
        }
        require(remaining >= totalLockAmt);

        _;
    }

    // EVENTS
    event UpdatedLockingState(string whom, address indexed to, uint256 value, uint256 date);

    // FUNCTIONS

    function EIForceCoin () public {
        balances[msg.sender] = TOTAL_SUPPLY;
        totalSupply = TOTAL_SUPPLY;

        // do the distribution of the token, in token transfer
        transfer(WALLET_FOUNDER, ALLOC_FOUNDER);
    }
	
    // get jishis&#39; locked amount of token
    function getLockedAmount_jishis(address _jishi) 
        public
		constant
		returns (uint256)
	{
        uint256 jishiDate = jishis_jishiDate[_jishi];
        uint256 lockedAmt = jishis_locked[_jishi];

        if (now <= jishiDate + (30 * 1 days)) {return lockedAmt;}
        if (now <= jishiDate + (30 * 2 days)) {return lockedAmt.mul(4).div(5);}
        if (now <= jishiDate + (30 * 3 days)) {return lockedAmt.mul(3).div(5);}
        if (now <= jishiDate + (30 * 4 days)) {return lockedAmt.mul(2).div(5);}
        if (now <= jishiDate + (30 * 5 days)) {return lockedAmt.mul(1).div(5);}
     
	
        return 0;
    }

    // get simus&#39; locked amount of token
      function getLockedAmount_simus(address _simu)
        public
		constant
		returns (uint256)
	{
        uint256 simuDate = simus_simuDate[_simu];
        uint256 lockedAmt = simus_locked[_simu];

        if (now <= simuDate + (30 * 1 days)) {return lockedAmt;}
        if (now <= simuDate + (30 * 2 days)) {return lockedAmt.mul(9).div(10);}
        if (now <= simuDate + (30 * 3 days)) {return lockedAmt.mul(8).div(10);}
        if (now <= simuDate + (30 * 4 days)) {return lockedAmt.mul(7).div(10);}
        if (now <= simuDate + (30 * 5 days)) {return lockedAmt.mul(6).div(10);}
        if (now <= simuDate + (30 * 6 days)) {return lockedAmt.mul(5).div(10);}
        if (now <= simuDate + (30 * 7 days)) {return lockedAmt.mul(4).div(10);}
        if (now <= simuDate + (30 * 8 days)) {return lockedAmt.mul(3).div(10);}
        if (now <= simuDate + (30 * 9 days)) {return lockedAmt.mul(2).div(10);}
        if (now <= simuDate + (30 * 10 days)) {return lockedAmt.mul(1).div(10);}
	
        return 0;
    }

    function getLockedAmount_jiedians(address _jiedian)
        public
		constant
		returns (uint256)
	{
        uint256 jiedianDate = jiedians_jiedianDate[_jiedian];
        uint256 lockedAmt = jiedians_locked[_jiedian];

        if (now <= jiedianDate + (30 * 1 days)) {return lockedAmt;}
        if (now <= jiedianDate + (30 * 2 days)){return lockedAmt.mul(11).div(12);}
        if (now <= jiedianDate + (30 * 3 days)) {return lockedAmt.mul(10).div(12);}
        if (now <= jiedianDate + (30 * 4 days)) {return lockedAmt.mul(9).div(12);}
        if (now <= jiedianDate + (30 * 5 days)) {return lockedAmt.mul(8).div(12);}
        if (now <= jiedianDate + (30 * 6 days)) {return lockedAmt.mul(7).div(12);}
        if (now <= jiedianDate + (30 * 7 days)) {return lockedAmt.mul(6).div(12);}
        if (now <= jiedianDate + (30 * 8 days)) {return lockedAmt.mul(5).div(12);}
        if (now <= jiedianDate + (30 * 9 days)) {return lockedAmt.mul(4).div(12);}
        if (now <= jiedianDate + (30 * 10 days)) {return lockedAmt.mul(3).div(12);}
        if (now <= jiedianDate + (30 * 11 days)) {return lockedAmt.mul(2).div(12);}
        if (now <= jiedianDate + (30 * 12 days)) {return lockedAmt.mul(1).div(12);}
	
        return 0;
    }

    function getLockedAmount_dakehus(address _dakehu)
        public
		constant
		returns (uint256)
	{
        uint256 dakehuDate = dakehus_dakehuDate[_dakehu];
        uint256 lockedAmt = dakehus_locked[_dakehu];

        if (now <= dakehuDate + (30 * 1 days)) {return lockedAmt;}
        if (now <= dakehuDate + (30 * 2 days)) {return lockedAmt.mul(23).div(24);}
        if (now <= dakehuDate + (30 * 3 days)) {return lockedAmt.mul(22).div(24);}
        if (now <= dakehuDate + (30 * 4 days)) {return lockedAmt.mul(21).div(24);}
        if (now <= dakehuDate + (30 * 5 days)) {return lockedAmt.mul(20).div(24);}
        if (now <= dakehuDate + (30 * 6 days)) {return lockedAmt.mul(19).div(24);}
        if (now <= dakehuDate + (30 * 7 days)) {return lockedAmt.mul(18).div(24);}
        if (now <= dakehuDate + (30 * 8 days)) {return lockedAmt.mul(17).div(24);}
        if (now <= dakehuDate + (30 * 9 days)) {return lockedAmt.mul(16).div(24);}
        if (now <= dakehuDate + (30 * 10 days)) {return lockedAmt.mul(15).div(24);}
        if (now <= dakehuDate + (30 * 11 days)) {return lockedAmt.mul(14).div(24);}
        if (now <= dakehuDate + (30 * 12 days)) {return lockedAmt.mul(13).div(24);}
        if (now <= dakehuDate + (30 * 13 days)) {return lockedAmt.mul(12).div(24);}
        if (now <= dakehuDate + (30 * 14 days)) {return lockedAmt.mul(11).div(24);}
        if (now <= dakehuDate + (30 * 15 days)) {return lockedAmt.mul(10).div(24);}
        if (now <= dakehuDate + (30 * 16 days)) {return lockedAmt.mul(9).div(24);}
        if (now <= dakehuDate + (30 * 17 days)) {return lockedAmt.mul(8).div(24);}
        if (now <= dakehuDate + (30 * 18 days)) {return lockedAmt.mul(7).div(24);}
        if (now <= dakehuDate + (30 * 19 days)) {return lockedAmt.mul(6).div(24);}
        if (now <= dakehuDate + (30 * 20 days)) {return lockedAmt.mul(5).div(24);}
        if (now <= dakehuDate + (30 * 21 days)) {return lockedAmt.mul(4).div(24);}
        if (now <= dakehuDate + (30 * 22 days)) {return lockedAmt.mul(3).div(24);}
        if (now <= dakehuDate + (30 * 23 days)) {return lockedAmt.mul(2).div(24);}
        if (now <= dakehuDate + (30 * 24 days)) {return lockedAmt.mul(1).div(24);}

	
        return 0;
    }


    // set lockup for jishis 
    function setLockup_jishis(address _jishi, uint256 _value, uint256 _jishiDate)
        public
        onlyOwner
    {
        require(_jishi != address(0));

        jishis_locked[_jishi] = _value;
        jishis_jishiDate[_jishi] = _jishiDate;
        UpdatedLockingState("jishi", _jishi, _value, _jishiDate);
    }

    // set lockup for strategic simu
    function setLockup_simus(address _simu, uint256 _value, uint256 _simuDate)
        public
        onlyOwner
    {
        require(_simu != address(0));

        simus_locked[_simu] = _value;
        simus_simuDate[_simu] = _simuDate;
        UpdatedLockingState("simu", _simu, _value, _simuDate);
    }

    function setLockup_jiedians(address _jiedian, uint256 _value, uint256 _jiedianDate)
        public
        onlyOwner
    {
        require(_jiedian != address(0));

        jiedians_locked[_jiedian] = _value;
        jiedians_jiedianDate[_jiedian] = _jiedianDate;
        UpdatedLockingState("jiedian", _jiedian, _value, _jiedianDate);
    }

    function setLockup_dakehus(address _dakehu, uint256 _value, uint256 _dakehuDate)
        public
        onlyOwner
    {
        require(_dakehu != address(0));

        dakehus_locked[_dakehu] = _value;
        dakehus_dakehuDate[_dakehu] = _dakehuDate;
        UpdatedLockingState("dakehu", _dakehu, _value, _dakehuDate);
    }


	// Transfer amount of tokens from sender account to recipient.
    function transfer(address _to, uint _value)
        public
        canTransfer(msg.sender, _value)
		returns (bool success)
	{
        return super.transfer(_to, _value);
    }

	// Transfer amount of tokens from a specified address to a recipient.
    function transferFrom(address _from, address _to, uint _value)
        public
        canTransfer(_from, _value)
		returns (bool success)
	{
        return super.transferFrom(_from, _to, _value);
    }
}