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
    string public standard = "Token 0.1";
    string public name = "";
    string public symbol = "";
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

/*
    We consider every contract to be a &#39;token holder&#39; since it&#39;s currently not possible
    for a contract to deny receiving tokens.

    The TokenHolder&#39;s contract sole purpose is to provide a safety mechanism that allows
    the owner to send tokens that were sent to the contract by mistake back to their sender.
*/
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


contract tSLDToken is ERC20Token, TokenHolder {

///////////////////////////////////////// VARIABLE INITIALIZATION /////////////////////////////////////////

    uint256 constant public tSLD_UNIT = 10 ** 18;
    uint256 public totalSupply = 2 * (10**9) * tSLD_UNIT;

    //  Constants
    uint256 constant public maxPresaleSupply = 600 * 10**6 * tSLD_UNIT;           // Total presale supply at max bonus
    uint256 constant public minCrowdsaleAllocation = 200 * 10**6 * tSLD_UNIT;     // Min amount for crowdsale
    uint256 constant public incentivisationAllocation = 600 * 10**6 * tSLD_UNIT;  // Incentivisation Allocation
    uint256 constant public storageAllocation = 600 * 10**6 * tSLD_UNIT;          // Advisors Allocation
    uint256 constant public sollidaTeamAllocation = 600 * 10**6 * tSLD_UNIT;         // sollida Team allocation

    address public crowdFundAddress;                                             // Address of the crowdfund
    address public advisorAddress;                                               // sollida advisor&#39;s address
    address public incentivisationFundAddress;                                   // Address that holds the incentivization funds
    address public sollidaTeamAddress;                                             // sollida Team address

    //  Variables

    uint256 public totalAllocatedToAdvisors = 0;                                 // Counter to keep track of advisor token allocation
    uint256 public totalAllocatedToTeam = 0;                                     // Counter to keep track of team token allocation
    uint256 public totalAllocated = 0;                                           // Counter to keep track of overall token allocation
    uint256 constant public endTime = 1509494340;                                // 10/31/2017 @ 11:59pm (UTC) crowdsale end time (in seconds)

    bool internal isReleasedToPublic = false;                         // Flag to allow transfer/transferFrom before the end of the crowdfund

    uint256 internal teamTranchesReleased = 0;                          // Track how many tranches (allocations of 12.5% team tokens) have been released
    uint256 internal maxTeamTranches = 8;                               // The number of tranches allowed to the team until depleted

///////////////////////////////////////// MODIFIERS /////////////////////////////////////////

    // sollida Team timelock    
    modifier safeTimelock() {
        require(now >= endTime + 6 * 4 weeks);
        _;
    }

    // Advisor Team timelock    
    modifier advisorTimelock() {
        require(now >= endTime + 2 * 4 weeks);
        _;
    }

    // Function only accessible by the Crowdfund contract
    modifier crowdfundOnly() {
        require(msg.sender == crowdFundAddress);
        _;
    }

    ///////////////////////////////////////// CONSTRUCTOR /////////////////////////////////////////

    /**
        @dev constructor
        @param _crowdFundAddress   Crowdfund address
        @param _advisorAddress     Advisor address
    */
    function tSLDToken(address _crowdFundAddress, address _advisorAddress, address _incentivisationFundAddress, address _sollidaTeamAddress)
    ERC20Token("Token Sollida", "tSLD", 18)
     {
        crowdFundAddress = _crowdFundAddress;
        advisorAddress = _advisorAddress;
        sollidaTeamAddress = _sollidaTeamAddress;
        incentivisationFundAddress = _incentivisationFundAddress;
        balanceOf[_crowdFundAddress] = minCrowdsaleAllocation + maxPresaleSupply; // Total presale + crowdfund tokens
        balanceOf[_incentivisationFundAddress] = incentivisationAllocation;       // 10% Allocated for Marketing and Incentivisation
        totalAllocated += incentivisationAllocation;                              // Add to total Allocated funds
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
        if (isTransferAllowed() == true || msg.sender == crowdFundAddress || msg.sender == incentivisationFundAddress) {
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
        if (isTransferAllowed() == true || msg.sender == crowdFundAddress || msg.sender == incentivisationFundAddress) {        
            assert(super.transferFrom(_from, _to, _value));
            return true;
        }
        revert();
    }

///////////////////////////////////////// ALLOCATION FUNCTIONS /////////////////////////////////////////

    /**
        @dev Release one single tranche of the sollida Team Token allocation
        throws if before timelock (6 months) ends and if not initiated by the owner of the contract
        returns true if valid
        Schedule goes as follows:
        3 months: 12.5% (this tranche can only be released after the initial 6 months has passed)
        6 months: 12.5%
        9 months: 12.5%
        12 months: 12.5%
        15 months: 12.5%
        18 months: 12.5%
        21 months: 12.5%
        24 months: 12.5%
        @return true if successful, throws if not
    */
    function releasesollidaTeamTokens() safeTimelock ownerOnly returns(bool success) {
        require(totalAllocatedToTeam < sollidaTeamAllocation);

        uint256 sollidaTeamAlloc = sollidaTeamAllocation / 1000;
        uint256 currentTranche = uint256(now - endTime) / 12 weeks;     // "months" after crowdsale end time (division floored)

        if(teamTranchesReleased < maxTeamTranches && currentTranche > teamTranchesReleased) {
            teamTranchesReleased++;

            uint256 amount = safeMul(sollidaTeamAlloc, 125);
            balanceOf[sollidaTeamAddress] = safeAdd(balanceOf[sollidaTeamAddress], amount);
            Transfer(0x0, sollidaTeamAddress, amount);
            totalAllocated = safeAdd(totalAllocated, amount);
            totalAllocatedToTeam = safeAdd(totalAllocatedToTeam, amount);
            return true;
        }
        revert();
    }

    /**
        @dev release Advisors Token allocation
        throws if before timelock (2 months) ends or if no initiated by the advisors address
        or if there is no more allocation to give out
        returns true if valid

        @return true if successful, throws if not
    */
    function releaseAdvisorTokens() advisorTimelock ownerOnly returns(bool success) {
        require(totalAllocatedToAdvisors == 0);
        balanceOf[advisorAddress] = safeAdd(balanceOf[advisorAddress], storageAllocation);
        totalAllocated = safeAdd(totalAllocated, storageAllocation);
        totalAllocatedToAdvisors = storageAllocation;
        Transfer(0x0, advisorAddress, storageAllocation);
        return true;
    }

    /**
        @dev Retrieve unsold tokens from the crowdfund
        throws if before timelock (6 months from end of Crowdfund) ends and if no initiated by the owner of the contract
        returns true if valid

        @return true if successful, throws if not
    */
    function retrieveUnsoldTokens() safeTimelock ownerOnly returns(bool success) {
        uint256 amountOfTokens = balanceOf[crowdFundAddress];
        balanceOf[crowdFundAddress] = 0;
        balanceOf[incentivisationFundAddress] = safeAdd(balanceOf[incentivisationFundAddress], amountOfTokens);
        totalAllocated = safeAdd(totalAllocated, amountOfTokens);
        Transfer(crowdFundAddress, incentivisationFundAddress, amountOfTokens);
        return true;
    }

    /**
        @dev Keep track of token allocations
        can only be called by the crowdfund contract
    */
    function addToAllocation(uint256 _amount) crowdfundOnly {
        totalAllocated = safeAdd(totalAllocated, _amount);
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