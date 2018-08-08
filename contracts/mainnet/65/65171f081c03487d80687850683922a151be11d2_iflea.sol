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

contract iflea is StandardToken, Ownable {

    string public name = "iflea";
    string public symbol = "IFLE";
    uint public decimals = 18;

    // The token allocation
    uint public constant TOTAL_SUPPLY       = 600000000e18;
    uint public constant ALLOC_FOUNDER    =  600000000e18; // 100%


    // wallets
    address public constant WALLET_FOUNDER    = 0x90bb1cC328197C836B242Dfdb3340E5D39E357E0; 
    
    
    // 2 groups of lockup
    mapping(address => uint256) public contributors_locked; 
    mapping(address => uint256) public investors_locked;

    // 2 types of releasing
    mapping(address => uint256) public contributors_countdownDate;
    mapping(address => uint256) public investors_deliveryDate;

    // MODIFIER

    // checks if the address can transfer certain amount of tokens
    modifier canTransfer(address _sender, uint256 _value) {
        require(_sender != address(0));

        uint256 remaining = balances[_sender].sub(_value);
        uint256 totalLockAmt = 0;

        if (contributors_locked[_sender] > 0) {
            totalLockAmt = totalLockAmt.add(getLockedAmount_contributors(_sender));
        }

        if (investors_locked[_sender] > 0) {
            totalLockAmt = totalLockAmt.add(getLockedAmount_investors(_sender));
        }

        require(remaining >= totalLockAmt);

        _;
    }

    // EVENTS
    event UpdatedLockingState(string whom, address indexed to, uint256 value, uint256 date);

    // FUNCTIONS

    function iflea() public {
        balances[msg.sender] = TOTAL_SUPPLY;
        totalSupply = TOTAL_SUPPLY;

        // do the distribution of the token, in token transfer
        transfer(WALLET_FOUNDER, ALLOC_FOUNDER);
    }
	
    // get contributors&#39; locked amount of token
    // this lockup will be released in 8 batches which take place every 180 days
    function getLockedAmount_contributors(address _contributor) 
        public
		constant
		returns (uint256)
	{
        uint256 countdownDate = contributors_countdownDate[_contributor];
        uint256 lockedAmt = contributors_locked[_contributor];

        if (now <= countdownDate + (180 * 1 days)) {return lockedAmt;}
        if (now <= countdownDate + (180 * 2 days)) {return lockedAmt.mul(7).div(8);}
        if (now <= countdownDate + (180 * 3 days)) {return lockedAmt.mul(6).div(8);}
        if (now <= countdownDate + (180 * 4 days)) {return lockedAmt.mul(5).div(8);}
        if (now <= countdownDate + (180 * 5 days)) {return lockedAmt.mul(4).div(8);}
        if (now <= countdownDate + (180 * 6 days)) {return lockedAmt.mul(3).div(8);}
        if (now <= countdownDate + (180 * 7 days)) {return lockedAmt.mul(2).div(8);}
        if (now <= countdownDate + (180 * 8 days)) {return lockedAmt.mul(1).div(8);}
	
        return 0;
    }

    // get investors&#39; locked amount of token
    // this lockup will be released in 3 batches: 
    // 1. on delievery date
    // 2. three months after the delivery date
    // 3. six months after the delivery date
    function getLockedAmount_investors(address _investor)
        public
		constant
		returns (uint256)
	{
        uint256 delieveryDate = investors_deliveryDate[_investor];
        uint256 lockedAmt = investors_locked[_investor];

        if (now <= delieveryDate) {return lockedAmt;}
        if (now <= delieveryDate + 90 days) {return lockedAmt.mul(2).div(3);}
        if (now <= delieveryDate + 180 days) {return lockedAmt.mul(1).div(3);}
	
        return 0;
    }

    // set lockup for contributors 
    function setLockup_contributors(address _contributor, uint256 _value, uint256 _countdownDate)
        public
        onlyOwner
    {
        require(_contributor != address(0));

        contributors_locked[_contributor] = _value;
        contributors_countdownDate[_contributor] = _countdownDate;
        UpdatedLockingState("contributor", _contributor, _value, _countdownDate);
    }

    // set lockup for strategic investor
    function setLockup_investors(address _investor, uint256 _value, uint256 _delieveryDate)
        public
        onlyOwner
    {
        require(_investor != address(0));

        investors_locked[_investor] = _value;
        investors_deliveryDate[_investor] = _delieveryDate;
        UpdatedLockingState("investor", _investor, _value, _delieveryDate);
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