pragma solidity ^0.4.15;
/*
    Utilities & Common Modifiers
*/
contract Utils {
    /**
        constructor
    */
    function Utils() {
    }

    // validates an address - currently only checks that it isn&#39;t null
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

    // Overflow protected math functions

    /**
        @dev returns the sum of _x and _y, asserts if the calculation overflows

        @param _x   value 1
        @param _y   value 2

        @return sum
    */
    function safeAdd(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    /**
        @dev returns the difference of _x minus _y, asserts if the subtraction results in a negative number

        @param _x   minuend
        @param _y   subtrahend

        @return difference
    */
    function safeSub(uint256 _x, uint256 _y) internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    /**
        @dev returns the product of multiplying _x by _y, asserts if the calculation overflows

        @param _x   factor 1
        @param _y   factor 2

        @return product
    */
    function safeMul(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren&#39;t abstract since the compiler emits automatically generated getter functions as external
    function name() public constant returns (string) { name; }
    function symbol() public constant returns (string) { symbol; }
    function decimals() public constant returns (uint8) { decimals; }
    function totalSupply() public constant returns (uint256) { totalSupply; }
    function balanceOf(address _owner) public constant returns (uint256 balance) { _owner; balance; }
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) { _owner; _spender; remaining; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}


/**
    ERC20 Standard Token implementation
*/
contract ERC20Token is IERC20Token, Utils {
    string public standard = &quot;Token 0.1&quot;;
    string public name = &quot;&quot;;
    string public symbol = &quot;&quot;;
    uint8 public decimals = 0;
    uint256 public totalSupply = 0;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
        @dev constructor

        @param _name        token name
        @param _symbol      token symbol
        @param _decimals    decimal points, for display purposes
    */
    function ERC20Token(string _name, string _symbol, uint8 _decimals) {
        require(bytes(_name).length > 0 && bytes(_symbol).length > 0); // validate input

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /**
        @dev send coins
        throws on any error rather then return a false flag to minimize user errors

        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, false if it wasn&#39;t
    */
    function transfer(address _to, uint256 _value)
        public
        validAddress(_to)
        returns (bool success)
    {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
        @dev an account/contract attempts to get the coins
        throws on any error rather then return a false flag to minimize user errors

        @param _from    source address
        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, false if it wasn&#39;t
    */
    function transferFrom(address _from, address _to, uint256 _value)
        public
        validAddress(_from)
        validAddress(_to)
        returns (bool success)
    {
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
        @dev allow another account/contract to spend some tokens on your behalf
        throws on any error rather then return a false flag to minimize user errors

        also, to minimize the risk of the approve/transferFrom attack vector
        (see https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/), approve has to be called twice
        in 2 separate transactions - once to change the allowance to 0 and secondly to change it to the new allowance value

        @param _spender approved address
        @param _value   allowance amount

        @return true if the approval was successful, false if it wasn&#39;t
    */
    function approve(address _spender, uint256 _value)
        public
        validAddress(_spender)
        returns (bool success)
    {
        // if the allowance isn&#39;t 0, it can only be updated to 0 to prevent an allowance change immediately after withdrawal
        require(_value == 0 || allowance[msg.sender][_spender] == 0);

        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}

/*
    Owned contract interface
*/
contract IOwned {
    // this function isn&#39;t abstract since the compiler emits automatically generated getter functions as external
    function owner() public constant returns (address) { owner; }

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

/*
    Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

    /**
        @dev constructor
    */
    function Owned() {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

    /**
        @dev allows transferring the contract ownership
        the new owner still needs to accept the transfer
        can only be called by the contract owner

        @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /**
        @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

/*
    Token Holder interface
*/
contract ITokenHolder is IOwned {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public;
}


contract TokenHolder is ITokenHolder, Owned, Utils {
    /**
        @dev constructor
    */
    function TokenHolder() {
    }

    /**
        @dev withdraws tokens held by the contract and sends them to an account
        can only be called by the owner

        @param _token   ERC20 token contract address
        @param _to      account to receive the new amount
        @param _amount  amount to withdraw
    */
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_to)
        notThis(_to)
    {
        assert(_token.transfer(_to, _amount));
    }
}


contract TCLRToken is ERC20Token, TokenHolder {

///////////////////////////////////////// VARIABLE INITIALIZATION /////////////////////////////////////////

    uint256 constant public TCLR_UNIT = 10 ** 18;
    uint256 public totalSupply = 86374977 * TCLR_UNIT;

    //  Constants 
    uint256 constant public maxIcoSupply = 48369987 * TCLR_UNIT;           // ICO pool allocation
    uint256 constant public Company = 7773748 * TCLR_UNIT;     //  Company pool allocation
    uint256 constant public Bonus = 16411245 * TCLR_UNIT;  // Bonus Allocation
    uint256 constant public Bounty = 1727500 * TCLR_UNIT;  // Bounty Allocation
    uint256 constant public advisorsAllocation = 4318748 * TCLR_UNIT;          // Advisors Allocation
    uint256 constant public TCLRinTeamAllocation = 7773748 * TCLR_UNIT;         // TCLRin Team allocation

    address public icoAddress;   // ico address
    address public companyAddress;                                             // Address of the company
    address public advisorAddress;                                               // TCLRin advisor&#39;s address
    address public bonusAddress;                                   // Address that holds the bonus 
    address public TCLRinTeamAddress;                              // TCLRin Team address
    address public bountyAddress;                                            // Bounty address

    //  Variables

    uint256 public totalAllocatedToAdvisors = 0;                                 // Counter to keep track of advisor token allocation
    uint256 public totalAllocatedToTeam = 0;                                     // Counter to keep track of team token allocation
    uint256 public totalAllocated = 0;                                           // Counter to keep track of overall token allocation
    uint256 constant public endTime = 0;                                // time (in seconds)

    bool internal isReleasedToPublic = false;                         // Flag to allow transfer/transferFrom 

    

///////////////////////////////////////// MODIFIERS /////////////////////////////////////////

    // TCLRin Team timelock    
    modifier safeTimelock() {
        require(now >= endTime + 52 weeks);
        _;
    }

    // Advisor Team timelock    
    modifier advisorTimelock() {
        require(now >= endTime + 26 weeks);
        _;
    }

    

    ///////////////////////////////////////// CONSTRUCTOR /////////////////////////////////////////

    
    function TCLRToken(address _icoAddress, address _companyAddress, address _advisorAddress, address _bonusAddress, address _TCLRinTeamAddress, address _bountyAddress)
    ERC20Token(&quot;TCLR&quot;, &quot;TCLR&quot;, 18)
     {
        icoAddress = _icoAddress;
        companyAddress = _companyAddress;
        advisorAddress = _advisorAddress;
        bonusAddress = _bonusAddress;
        TCLRinTeamAddress = _TCLRinTeamAddress;
        bountyAddress = _bountyAddress;
        
        balanceOf[_icoAddress] = maxIcoSupply; // ico TCLR tokens
        balanceOf[_companyAddress] = Company; // Company TCLR tokens
        balanceOf[_bonusAddress] = Bonus;       // bonus TCLR tokens
        totalAllocated += maxIcoSupply+ Company+ Bonus;                              // Add to total Allocated funds
    }

///////////////////////////////////////// ERC20 OVERRIDE /////////////////////////////////////////

    /**
        @dev send coins
        throws on any error rather then return a false flag to minimize user errors
        in addition to the standard checks, the function throws if transfers are disabled

        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, throws if it wasn&#39;t
    */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (isTransferAllowed() == true) {
            assert(super.transfer(_to, _value));
            return true;
        }
        revert();        
    }

    /**
        @dev an account/contract attempts to get the coins
        throws on any error rather then return a false flag to minimize user errors
        in addition to the standard checks, the function throws if transfers are disabled

        @param _from    source address
        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, throws if it wasn&#39;t
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (isTransferAllowed() == true ) {        
            assert(super.transferFrom(_from, _to, _value));
            return true;
        }
        revert();
    }

///////////////////////////////////////// ALLOCATION FUNCTIONS /////////////////////////////////////////

    
    function releaseTCLRinTeamTokens() safeTimelock ownerOnly returns(bool success) {
        require(totalAllocatedToTeam < TCLRinTeamAllocation);

        uint256 TCLRinTeamAlloc = TCLRinTeamAllocation;
        

       

            uint256 amount = TCLRinTeamAlloc;
            balanceOf[TCLRinTeamAddress] = safeAdd(balanceOf[TCLRinTeamAddress], amount);
            Transfer(0x0, TCLRinTeamAddress, amount);
            totalAllocated = safeAdd(totalAllocated, amount);
            totalAllocatedToTeam = safeAdd(totalAllocatedToTeam, amount);
            return true;
        
        
    }

    
    function releaseAdvisorTokens() advisorTimelock ownerOnly returns(bool success) {
        require(totalAllocatedToAdvisors == 0);
        balanceOf[advisorAddress] = safeAdd(balanceOf[advisorAddress], advisorsAllocation);
        totalAllocated = safeAdd(totalAllocated, advisorsAllocation);
        totalAllocatedToAdvisors = advisorsAllocation;
        Transfer(0x0, advisorAddress, advisorsAllocation);
        return true;
    }

    
    function burnTokens(address _pool, uint256 _value) ownerOnly returns(bool success) {
        uint256 amountOfTokens = _value;

        balanceOf[_pool]=safeSub(balanceOf[_pool], amountOfTokens);
        totalSupply=safeSub(totalSupply, amountOfTokens);       
        Transfer(_pool, 0x0, amountOfTokens);
        return true;
    }

    

    /**
        @dev Function to allow transfers
        can only be called by the owner of the contract
        Transfers will be allowed regardless after the crowdfund end time.
    */
    function allowTransfers() ownerOnly {
        isReleasedToPublic = true;
    } 

    /**
        @dev User transfers are allowed/rejected
        Transfers are forbidden before the end of the crowdfund
    */
    function isTransferAllowed() internal constant returns(bool) {
        if (now > endTime || isReleasedToPublic == true) {
            return true;
        }
        return false;
    }
}