pragma solidity ^0.4.15;

contract Utils {
    /**
        constructor
    */
    function Utils() internal {
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
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
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
    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    /**
        @dev returns the product of multiplying _x by _y, asserts if the calculation overflows

        @param _x   factor 1
        @param _y   factor 2

        @return product
    */
    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
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
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}


/**
    ERC20 Standard Token implementation
*/
contract StandardERC20Token is IERC20Token, Utils {
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
    function StandardERC20Token(string _name, string _symbol, uint8 _decimals) public{
        require(bytes(_name).length > 0 && bytes(_symbol).length > 0); // validate input

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

     function balanceOf(address _owner) constant returns (uint256) {
        return balanceOf[_owner];
    }
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowance[_owner][_spender];
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
        require(balanceOf[msg.sender] >= _value && _value > 0);
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
        require(balanceOf[_from] >= _value && _value > 0);
        require(allowance[_from][msg.sender] >= _value);
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
    function Owned() public {
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

contract YooStop is Owned{

    bool public stopped = false;

    modifier stoppable {
        assert (!stopped);
        _;
    }
    function stop() public ownerOnly{
        stopped = true;
    }
    function start() public ownerOnly{
        stopped = false;
    }

}


contract YOOBAToken is StandardERC20Token, Owned,YooStop {



    uint256 constant public YOO_UNIT = 10 ** 18;
    uint256 public totalSupply = 100 * (10**8) * YOO_UNIT;

    //  Constants 
    uint256 constant public airdropSupply = 20 * 10**8 * YOO_UNIT;           
    uint256 constant public earlyInvestorSupply = 5 * 10**8 * YOO_UNIT;    
    uint256 constant public earlyCommunitySupply = 5 * 10**8 * YOO_UNIT;  
    uint256 constant public icoReservedSupply = 40 * 10**8 * YOO_UNIT;          // ico Reserved,not for other usages.
    uint256 constant public teamSupply = 12 * 10**8 * YOO_UNIT;         // Team,Community,Research，etc.
    uint256 constant public ecosystemSupply = 18 * 10**8 * YOO_UNIT;         // Community,Research，Infrastructure，etc.
    
    uint256  public tokensReleasedToIco = 0;  //the tokens has released for ico.
    uint256  public tokensReleasedToEarlyInvestor = 0;  //the tokens has released for early investor.
    uint256  public tokensReleasedToTeam = 0;  //the tokens has released to team.
    uint256  public tokensReleasedToEcosystem = 0;  //the tokens has released to ecosystem.
    uint256  public currentSupply = 0;  //all tokens released currently.

    
    
    address public airdropAddress;                                           
    address public yoobaTeamAddress;     
    address public earlyCommunityAddress;
    address public ecosystemAddress;// use for community,Research，Infrastructure，etc.
    address public backupAddress;


    
    
    uint256 internal createTime = 1522261875;                                // will be replace by (UTC) contract create time (in seconds)
    uint256 internal teamTranchesReleased = 0;                          // Track how many tranches (allocations of 6.25% teamSupply tokens) have been released，about 4 years,teamSupply tokens will be allocate to team.
    uint256 internal ecosystemTranchesReleased = 0;                          // Track how many tranches (allocations of 6.25% ecosystemSupply tokens) have been released.About 4 years,that will be release all. 
    uint256 internal maxTranches = 16;       
    bool internal isInitAirdropAndEarlyAlloc = false;


    /**
        @dev constructor
        
    */
    function YOOBAToken(address _airdropAddress, address _ecosystemAddress, address _backupAddress, address _yoobaTeamAddress,address _earlyCommunityAddress)
    StandardERC20Token("Yooba token", "YOO", 18) public
     {
        airdropAddress = _airdropAddress;
        yoobaTeamAddress = _yoobaTeamAddress;
        ecosystemAddress = _ecosystemAddress;
        backupAddress = _backupAddress;
        earlyCommunityAddress = _earlyCommunityAddress;
        createTime = now;
    }
    
    
    /**
        @dev 
        the tokens at the airdropAddress will be airdroped before 2018.12.31
    */
     function initAirdropAndEarlyAlloc()   public ownerOnly stoppable returns(bool success){
         require(!isInitAirdropAndEarlyAlloc);
         require(airdropAddress != 0x0 && earlyCommunityAddress != 0x0);
         require((currentSupply + earlyCommunitySupply + airdropSupply) <= totalSupply);
         balanceOf[earlyCommunityAddress] += earlyCommunitySupply; 
         currentSupply += earlyCommunitySupply;
         Transfer(0x0, earlyCommunityAddress, earlyCommunitySupply);
        balanceOf[airdropAddress] += airdropSupply;       
        currentSupply += airdropSupply;
        Transfer(0x0, airdropAddress, airdropSupply);
        isInitAirdropAndEarlyAlloc = true;
        return true;
     }
    


    /**
        @dev send tokens
        throws on any error rather then return a false flag to minimize user errors
        in addition to the standard checks, the function throws if transfers are disabled

        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, throws if it wasn&#39;t
    */
    function transfer(address _to, uint256 _value) public stoppable returns (bool success) {
        return super.transfer(_to, _value);
    }

    /**
        @dev 
        throws on any error rather then return a false flag to minimize user errors
        in addition to the standard checks, the function throws if transfers are disabled

        @param _from    source address
        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, throws if it wasn&#39;t
    */
    function transferFrom(address _from, address _to, uint256 _value) public stoppable returns (bool success) {
            return super.transferFrom(_from, _to, _value);
    }


    /**
        @dev Release one  tranche of the ecosystemSupply allocation to Yooba team,6.25% every tranche.About 4 years ecosystemSupply release over.
       
        @return true if successful, throws if not
    */
    function releaseForEcosystem()   public ownerOnly stoppable returns(bool success) {
        require(now >= createTime + 12 weeks);
        require(tokensReleasedToEcosystem < ecosystemSupply);

        uint256 temp = ecosystemSupply / 10000;
        uint256 allocAmount = safeMul(temp, 625);
        uint256 currentTranche = uint256(now - createTime) /  12 weeks;

        if(ecosystemTranchesReleased < maxTranches && currentTranche > ecosystemTranchesReleased && (currentSupply + allocAmount) <= totalSupply) {
            ecosystemTranchesReleased++;
            balanceOf[ecosystemAddress] = safeAdd(balanceOf[ecosystemAddress], allocAmount);
            currentSupply += allocAmount;
            tokensReleasedToEcosystem = safeAdd(tokensReleasedToEcosystem, allocAmount);
            Transfer(0x0, ecosystemAddress, allocAmount);
            return true;
        }
        revert();
    }
    
       /**
        @dev Release one  tranche of the teamSupply allocation to Yooba team,6.25% every tranche.About 4 years Yooba team will get teamSupply Tokens.
       
        @return true if successful, throws if not
    */
    function releaseForYoobaTeam()   public ownerOnly stoppable returns(bool success) {
        require(now >= createTime + 12 weeks);
        require(tokensReleasedToTeam < teamSupply);

        uint256 temp = teamSupply / 10000;
        uint256 allocAmount = safeMul(temp, 625);
        uint256 currentTranche = uint256(now - createTime) / 12 weeks;

        if(teamTranchesReleased < maxTranches && currentTranche > teamTranchesReleased && (currentSupply + allocAmount) <= totalSupply) {
            teamTranchesReleased++;
            balanceOf[yoobaTeamAddress] = safeAdd(balanceOf[yoobaTeamAddress], allocAmount);
            currentSupply += allocAmount;
            tokensReleasedToTeam = safeAdd(tokensReleasedToTeam, allocAmount);
            Transfer(0x0, yoobaTeamAddress, allocAmount);
            return true;
        }
        revert();
    }

  
    
        /**
        @dev release ico Tokens 

        @return true if successful, throws if not
    */
    function releaseForIco(address _icoAddress, uint256 _value) public  ownerOnly stoppable returns(bool success) {
          require(_icoAddress != address(0x0) && _value > 0  && (tokensReleasedToIco + _value) <= icoReservedSupply && (currentSupply + _value) <= totalSupply);
          balanceOf[_icoAddress] = safeAdd(balanceOf[_icoAddress], _value);
          currentSupply += _value;
          tokensReleasedToIco += _value;
          Transfer(0x0, _icoAddress, _value);
         return true;
    }

        /**
        @dev release  earlyInvestor Tokens 

        @return true if successful, throws if not
    */
    function releaseForEarlyInvestor(address _investorAddress, uint256 _value) public  ownerOnly  stoppable  returns(bool success) {
          require(_investorAddress != address(0x0) && _value > 0  && (tokensReleasedToEarlyInvestor + _value) <= earlyInvestorSupply && (currentSupply + _value) <= totalSupply);
          balanceOf[_investorAddress] = safeAdd(balanceOf[_investorAddress], _value);
          currentSupply += _value;
          tokensReleasedToEarlyInvestor += _value;
          Transfer(0x0, _investorAddress, _value);
         return true;
    }
    /**
     @dev  This only run for urgent situation.Or Yooba mainnet is run well and all tokens release over. 

        @return true if successful, throws if not
    */
    function processWhenStop() public  ownerOnly   returns(bool success) {
        require(currentSupply <=  totalSupply && stopped);
        balanceOf[backupAddress] += (totalSupply - currentSupply);
        currentSupply = totalSupply;
       Transfer(0x0, backupAddress, (totalSupply - currentSupply));
        return true;
    }
    

}