pragma solidity ^0.4.15;

contract Utils {
    /**
        constructor
    */
    function Utils() internal {
    }

    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }


    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }


    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }


    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}


contract IERC20Token {
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



contract StandardERC20Token is IERC20Token, Utils {
    string public name = "";
    string public symbol = "";
    uint8 public decimals = 0;
    uint256 public totalSupply = 0;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    


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


contract IOwned {
    // this function isn&#39;t abstract since the compiler emits automatically generated getter functions as external
    function owner() public constant returns (address) { owner; }

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}


contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

 
    function Owned() public {
        owner = msg.sender;
    }

    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }


    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }


    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

contract GoolaStop is Owned{

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


contract GoolaToken is StandardERC20Token, Owned,GoolaStop {



    uint256 constant public GOOLA_UNIT = 10 ** 18;
    uint256 public totalSupply = 100 * (10**8) * GOOLA_UNIT;

    uint256 constant public airdropSupply = 60 * 10**8 * GOOLA_UNIT;           
    uint256 constant public earlyInitProjectSupply = 10 * 10**8 * GOOLA_UNIT;  
    uint256 constant public teamSupply = 15 * 10**8 * GOOLA_UNIT;         
    uint256 constant public ecosystemSupply = 15 * 10**8 * GOOLA_UNIT;   
    
    uint256  public tokensReleasedToTeam = 0;
    uint256  public tokensReleasedToEcosystem = 0; 
    uint256  public currentSupply = 0;  
    
    address public goolaTeamAddress;     
    address public ecosystemAddress;
    address public backupAddress;

    uint256 internal createTime = 1527730299;             
    uint256 internal hasAirdrop = 0;
    uint256 internal hasReleaseForEarlyInit = 0;
    uint256 internal teamTranchesReleased = 0; 
    uint256 internal ecosystemTranchesReleased = 0;  
    uint256 internal maxTranches = 16;       

    function GoolaToken( address _ecosystemAddress, address _backupAddress, address _goolaTeamAddress)
    StandardERC20Token("Goola token", "GOOLA", 18) public
     {
        goolaTeamAddress = _goolaTeamAddress;
        ecosystemAddress = _ecosystemAddress;
        backupAddress = _backupAddress;
        createTime = now;
    }

    function transfer(address _to, uint256 _value) public stoppable returns (bool success) {
        return super.transfer(_to, _value);
    }


    function transferFrom(address _from, address _to, uint256 _value) public stoppable returns (bool success) {
            return super.transferFrom(_from, _to, _value);
    }
    
    function withdrawERC20TokenTo(IERC20Token _token, address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_to)
        notThis(_to)
    {
        assert(_token.transfer(_to, _amount));

    }
    
        
    function airdropBatchTransfer(address[] _to,uint256 _amountOfEach) public ownerOnly {
        require(_to.length > 0 && _amountOfEach > 0 && _to.length * _amountOfEach <=  (airdropSupply - hasAirdrop) && (currentSupply + (_to.length * _amountOfEach)) <= totalSupply && _to.length < 100000);
        for(uint16 i = 0; i < _to.length ;i++){
         balanceOf[_to[i]] = safeAdd(balanceOf[_to[i]], _amountOfEach);
          Transfer(0x0, _to[i], _amountOfEach);
        }
            currentSupply += (_to.length * _amountOfEach);
            hasAirdrop = safeAdd(hasAirdrop, _to.length * _amountOfEach);
    }
    
  function releaseForEarlyInit(address[] _to,uint256 _amountOfEach) public ownerOnly {
        require(_to.length > 0 && _amountOfEach > 0 && _to.length * _amountOfEach <=  (earlyInitProjectSupply - hasReleaseForEarlyInit) && (currentSupply + (_to.length * _amountOfEach)) <= totalSupply && _to.length < 100000);
        for(uint16 i = 0; i < _to.length ;i++){
          balanceOf[_to[i]] = safeAdd(balanceOf[_to[i]], _amountOfEach);
          Transfer(0x0, _to[i], _amountOfEach);
        }
            currentSupply += (_to.length * _amountOfEach);
            hasReleaseForEarlyInit = safeAdd(hasReleaseForEarlyInit, _to.length * _amountOfEach);
    }


    /**
        @dev Release one  tranche of the ecosystemSupply allocation to Goola ecosystem,6.25% every tranche.About 4 years ecosystemSupply release over.
       
        @return true if successful, throws if not
    */
    function releaseForEcosystem()   public ownerOnly  returns(bool success) {
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
        @dev Release one  tranche of the teamSupply allocation to Goola team,6.25% every tranche.About 4 years Goola team will get teamSupply Tokens.
       
        @return true if successful, throws if not
    */
    function releaseForGoolaTeam()   public ownerOnly  returns(bool success) {
        require(now >= createTime + 12 weeks);
        require(tokensReleasedToTeam < teamSupply);

        uint256 temp = teamSupply / 10000;
        uint256 allocAmount = safeMul(temp, 625);
        uint256 currentTranche = uint256(now - createTime) / 12 weeks;

        if(teamTranchesReleased < maxTranches && currentTranche > teamTranchesReleased && (currentSupply + allocAmount) <= totalSupply) {
            teamTranchesReleased++;
            balanceOf[goolaTeamAddress] = safeAdd(balanceOf[goolaTeamAddress], allocAmount);
            currentSupply += allocAmount;
            tokensReleasedToTeam = safeAdd(tokensReleasedToTeam, allocAmount);
            Transfer(0x0, goolaTeamAddress, allocAmount);
            return true;
        }
        revert();
    }
    
    function processWhenStop() public  ownerOnly   returns(bool success) {
        require(currentSupply <=  totalSupply && stopped);
        balanceOf[backupAddress] += (totalSupply - currentSupply);
        currentSupply = totalSupply;
       Transfer(0x0, backupAddress, (totalSupply - currentSupply));
        return true;
    }
    

}