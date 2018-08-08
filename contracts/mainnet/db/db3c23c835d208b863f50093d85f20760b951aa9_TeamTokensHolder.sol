pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Owned {

    /// @dev `owner` is the only address that can call a function with this modifier
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    

    /// @notice The Constructor assigns the message sender to be `owner`
    constructor() public {
        owner = msg.sender;
    }

    /// @notice `owner` can step down and assign some other address to this role
    /// @param _newOwner The address of the new owner. 0x0 can be used to create
    ///  an unowned neutral vault, however that cannot be undone
    function changeOwner(address _newOwner) onlyOwner public returns(bool){
        require (_newOwner != address(0));
        
        newOwner = _newOwner;
        return true;
    }

    function acceptOwnership() public returns(bool) {
        require(newOwner != address(0));
        require(msg.sender == newOwner);

        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
        return true;
    }
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require (_value <= allowed[_from][msg.sender]);
    
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract LifeBankerCoin is Owned, StandardToken{
    string public constant name = "LifeBanker Coin";
    string public constant symbol = "LBC";
    uint8 public constant decimals = 18;

    address public lockAddress;
    address public teamAddress;

    constructor() public {
        totalSupply = 10000000000000000000000000000; //10 billion
    }

    /*
     * @dev Initialize token attribution,only allowed to call once
     * @param _team address : TeamTokensHolder contract deployment address
     * @param _lock address : TokenLock contract deployment address
     * @param _sare address : The token storage address of the sales part
     */
    function initialization(address _team, address _lock, address _sale) onlyOwner public returns(bool) {
        require(lockAddress == 0 && teamAddress == 0);
        require(_team != 0 && _lock != 0);
        require(_sale != 0);
        teamAddress = _team;
        lockAddress = _lock;
    
        balances[teamAddress] = totalSupply.mul(225).div(1000); //22.5% 
        balances[lockAddress] = totalSupply.mul(500).div(1000); //50.0% 
        balances[_sale]       = totalSupply.mul(275).div(1000); //27.5%
        return true;
    }
}

/* @title This contract locks the tokens of the team and early investors.
 * @notice The tokens are locked for a total of three years, unlocking one-sixth every six months.
 * Unlockable Amount(%)
 *    ^
 * 100|---------------------------- * * *
 *    |                           / :  
 *    |----------------------- *    :  
 *    |                      / :    :  
 *    |------------------ *    :    :  
 *    |                 / :    :    :  
 *  50|------------- *    :    :    :  
 *    |            / :    :    :    :  
 *    |-------- *    :    :    :    :  
 *    |       / :    :    :    :    :  
 *    |--- *    :    :    :    :    :  
 *    |  / :    :    :    :    :    :  
 *    +----*----*----*----*----*----*-->
 *    0   0.5   1   1.5   2   2.5   3   Time(year)
 *
 */
contract TeamTokensHolder is Owned{
    using SafeMath for uint256;

    LifeBankerCoin public LBC;
    uint256 public startTime;
    uint256 public duration = 6 * 30 * 24 * 3600; //six months

    uint256 public total = 2250000000000000000000000000;  // 2.25 billion  22.5% 
    uint256 public amountPerRelease = total.div(6);       // 375 million
    uint256 public collectedTokens;


    event TokensWithdrawn(address indexed _holder, uint256 _amount);
    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);


    constructor(address _owner, address _lbc) public{
        owner = _owner;
        LBC = LifeBankerCoin(_lbc);
        startTime = now;
    }

    /*
     * @dev The Dev (Owner) will call this method to extract the tokens
     */
    function unLock() public onlyOwner returns(bool){
        uint256 balance = LBC.balanceOf(address(this));

        //  amountPerRelease * [(now - startTime) / duration]
        uint256 canExtract = amountPerRelease.mul((getTime().sub(startTime)).div(duration));

        uint256 amount = canExtract.sub(collectedTokens);

        if (amount == 0){
            revert();
        } 

        if (amount > balance) {
            amount = balance;
        }

        assert (LBC.transfer(owner, amount));
        emit TokensWithdrawn(owner, amount);
        collectedTokens = collectedTokens.add(amount);
        
        return true;
    }

    /* Get the timestamp of the current block */
    function getTime() view public returns(uint256){
        return now;
    }

    /// Safe Function
    /// @dev This method can be used by the controller to extract mistakenly
    /// @param _token The address of the token contract that you want to recover
    function claimTokens(address _token) public onlyOwner returns(bool){
        require(_token != address(LBC));

        ERC20 token = ERC20(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
        emit ClaimedTokens(_token, owner, balance);
        return true;
    }
}

/*
 * @title This contract locks 50% of the total, 30% for mining, 
 *        10% for community promotion, and 10% for operation and maintenance.
 * @notice The tokens are locked for a total of five years, 
 *        and the number of tokens that can be unlocked each year is halved. 
 *        Each year&#39;s tokens are divided into 12 months equals to unlock.
 *        Percentage per year : 50%, 25%, 12.5%, 6.25% ,6.25% 
 * Unlockable Amount(%)
 *    ^
 * 100|_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 
 *    |_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _     *   :
 *    |_ _ _ _ _ _ _ _ _ _ _ _ _      *   :        : 
 *    |                         *:        :        : 
 *  75|_ _ _ _ _ _ _ _ _    *    :        :        : 
 *    |                *:        :        :        : 
 *    |             *   :        :        :        : 
 *    |          *      :        :        :        : 
 *  50|_ _ _ _ *        :        :        :        :   
 *    |       *:        :        :        :        : 
 *    |      * :        :        :        :        : 
 *    |     *  :        :        :        :        : 
 *    |    *   :        :        :        :        : 
 *    |   *    :        :        :        :        : 
 *    |  *     :        :        :        :        : 
 *    | *      :        :        :        :        : 
 *    |*       :        :        :        :        : 
 *    +--------*--------*--------*--------*--------*---> Time(year)
 *    0        1        2        3        4        5    
 */
contract TokenLock is Owned{
    using SafeMath for uint256;

    LifeBankerCoin public LBC;

    uint256 public totalSupply = 10000000000000000000000000000;
    uint256 public totalLocked = totalSupply.div(2); // 50% of totalSupply
    uint256 public collectedTokens;
    uint256 public startTime;

    address public POSAddress       = 0x72CE608648c5b2E7FB5575F72De32B4F5dfCee18; //30% DPOS
    address public CommunityAddress = 0x7fD2944a178f4dc0A50783De6Bad1857147774c0; //10% Community promotion
    address public OperationAddress = 0x33Df6bace87AE59666DD1DE2FDEB383D164f1f36; //10% Operation and maintenance

    uint256 _1stYear = totalLocked.mul(5000).div(10000);  // 50%
    uint256 _2stYear = totalLocked.mul(2500).div(10000);  // 25%
    uint256 _3stYear = totalLocked.mul(1250).div(10000);  // 12.5%
    uint256 _4stYear = totalLocked.mul(625).div(10000);   // 6.25%
    uint256 _5stYear = totalLocked.mul(625).div(10000);   // 6.25%

    mapping (address => bool) whiteList;
    

    event TokensWithdrawn(uint256 _amount);
    event LogMangeWhile(address indexed _dest, bool _allow);

    modifier onlyWhite() { 
        require (whiteList[msg.sender] == true); 
        _; 
    }

    /// @param _lbc address : LifeBankerCoin contract deployment address
    constructor(address _lbc) public{
        startTime = now;
        LBC = LifeBankerCoin(_lbc);
        whiteList[msg.sender] = true;
    }
    
    /**
     * @dev Add or remove call permissions for an address
     * @param _dest    address  : The address of the permission to be modified
     * @param _allow   bool     : True means increase, False means remove
     * @return success bool     : Successful operation returns True
     */
    function mangeWhileList(address _dest, bool _allow) onlyOwner public returns(bool success){
        require(_dest != address(0));

        whiteList[_dest] = _allow;
        emit LogMangeWhile(_dest, _allow);
        return true;
    }

    /* @dev Called by &#39;owner&#39; to unlock the token.   */
    function unlock() public onlyWhite returns(bool success){
        uint256 canExtract = calculation();
        uint256 _amount = canExtract.sub(collectedTokens); // canExtract - collectedTokens
        distribute(_amount);
        collectedTokens = collectedTokens.add(_amount);

        return true;
    }

    /*
     * @dev Calculates the total number of tokens that can be unlocked based on time.
     * @return uint256 : total number of unlockable
     */
    function calculation() view internal returns(uint256){
        uint256 _month = getMonths();
        uint256 _amount;

        if (_month == 0){
            revert();
        }

        if (_month <= 12 ){
            _amount = _1stYear.mul(_month).div(12);

        }else if(_month <= 24){
            // _1stYear + [_2stYear * (moneth - 12) / 12]
            _amount = _1stYear;
            _amount = _amount.add(_2stYear.mul(_month.sub(12)).div(12));

        }else if(_month <= 36){
            // _1stYear + _2stYear + [_3stYear * (moneth - 24) / 12]
            _amount = _1stYear + _2stYear;
            _amount = _amount.add(_3stYear.mul(_month.sub(24)).div(12));

        }else if(_month <= 48){
            // _1stYear + _2stYear + _3stYear + [_4stYear * (moneth - 36) / 12]
            _amount = _1stYear + _2stYear + _3stYear;
            _amount = _amount.add(_4stYear.mul(_month.sub(36)).div(12));      

        }else if(_month <= 60){
            // _1stYear + _2stYear + _3stYear + _4stYear + [_5stYear * (moneth - 48) / 12]
            _amount = _1stYear + _2stYear + _3stYear + _4stYear;
            _amount = _amount.add(_5stYear.mul(_month.sub(48)).div(12)); 

        }else{
            // more than 5years
            _amount = LBC.balanceOf(this);
        }
        return _amount;
    }

    /* Get how many months have passed since the contract was deployed. */
    function getMonths() view internal returns(uint256){
        uint256 countMonth = (getTime().sub(startTime)).div(30 * 24 * 3600);
        return countMonth; // begin 0
    }

    /*
     * @dev Distribute unlockable tokens to three addresses, proportion 3:1:1
     * @param _amount uint256 : Number of tokens that can be unlocked
     */
    function distribute(uint256 _amount) internal returns(bool){
        require (_amount != 0);

        uint256 perAmount = _amount.div(5);
        
        assert (LBC.transfer(POSAddress, perAmount.mul(3)));
        assert (LBC.transfer(CommunityAddress, perAmount.mul(1)));
        assert (LBC.transfer(OperationAddress, perAmount.mul(1)));

        emit TokensWithdrawn(_amount);
        return true;
    }

    /* Get the timestamp of the current block */
    function getTime() view internal returns(uint256){
        return now; //block.timestamp
    }
}