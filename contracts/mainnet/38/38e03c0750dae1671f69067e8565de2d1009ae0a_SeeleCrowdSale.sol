pragma solidity ^0.4.18;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

// File: zeppelin-solidity/contracts/token/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

// File: zeppelin-solidity/contracts/token/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: zeppelin-solidity/contracts/token/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: zeppelin-solidity/contracts/token/PausableToken.sol

/**
 * @title Pausable token
 *
 * @dev StandardToken modified with pausable transfers.
 **/

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

// File: contracts/SeeleToken.sol

/// @title SeeleToken Contract
/// For more information about this token sale, please visit https://seele.pro
/// @author reedhong
contract SeeleToken is PausableToken {
    using SafeMath for uint;

    /// Constant token specific fields
    string public constant name = "SeeleToken";
    string public constant symbol = "Seele";
    uint public constant decimals = 18;

    /// seele total tokens supply
    uint public currentSupply;

    /// Fields that are only changed in constructor
    /// seele sale  contract
    address public minter; 

    /// Fields that can be changed by functions
    mapping (address => uint) public lockedBalances;

    /// claim flag
    bool public claimedFlag;  

    /*
     * MODIFIERS
     */
    modifier onlyMinter {
        require(msg.sender == minter);
        _;
    }

    modifier canClaimed {
        require(claimedFlag == true);
        _;
    }

    modifier maxTokenAmountNotReached (uint amount){
        require(currentSupply.add(amount) <= totalSupply);
        _;
    }

    modifier validAddress( address addr ) {
        require(addr != address(0x0));
        require(addr != address(this));
        _;
    }

    /**
     * CONSTRUCTOR 
     * 
     * @dev Initialize the Seele Token
     * @param _minter The SeeleCrowdSale Contract 
     * @param _maxTotalSupply total supply token    
     */
    function SeeleToken(address _minter, address _admin, uint _maxTotalSupply) 
        public 
        validAddress(_admin)
        validAddress(_minter)
        {
        minter = _minter;
        totalSupply = _maxTotalSupply;
        claimedFlag = false;
        paused = true;
        transferOwnership(_admin);
    }

    /**
     * EXTERNAL FUNCTION 
     * 
     * @dev SeeleCrowdSale contract instance mint token
     * @param receipent The destination account owned mint tokens    
     * @param amount The amount of mint token
     * @param isLock Lock token flag
     * be sent to this address.
     */

    function mint(address receipent, uint amount, bool isLock)
        external
        onlyMinter
        maxTokenAmountNotReached(amount)
        returns (bool)
    {
        if (isLock ) {
            lockedBalances[receipent] = lockedBalances[receipent].add(amount);
        } else {
            balances[receipent] = balances[receipent].add(amount);
        }
        currentSupply = currentSupply.add(amount);
        return true;
    }


    function setClaimedFlag(bool flag) 
        public
        onlyOwner 
    {
        claimedFlag = flag;
    }

     /*
     * PUBLIC FUNCTIONS
     */

    /// @dev Locking period has passed - Locked tokens have turned into tradeable
    function claimTokens(address[] receipents)
        external
        onlyOwner
        canClaimed
    {        
        for (uint i = 0; i < receipents.length; i++) {
            address receipent = receipents[i];
            balances[receipent] = balances[receipent].add(lockedBalances[receipent]);
            lockedBalances[receipent] = 0;
        }
    }

    function airdrop(address[] receipents, uint[] tokens)
        external
    {        
        for (uint i = 0; i < receipents.length; i++) {
            address receipent = receipents[i];
            uint token = tokens[i];
            if(balances[msg.sender] >= token ){
                balances[msg.sender] = balances[msg.sender].sub(token);
                balances[receipent] = balances[receipent].add(token);
            }
        }
    }
}

// File: contracts/SeeleCrowdSale.sol

/// @title SeeleCrowdSale Contract
/// For more information about this token sale, please visit https://seele.pro
/// @author reedhong
contract SeeleCrowdSale is Pausable {
    using SafeMath for uint;

    /// Constant fields
    /// seele total tokens supply
    uint public constant SEELE_TOTAL_SUPPLY = 1000000000 ether;
    uint public constant MAX_SALE_DURATION = 4 days;
    uint public constant STAGE_1_TIME =  6 hours;
    uint public constant STAGE_2_TIME = 12 hours;
    uint public constant MIN_LIMIT = 0.1 ether;
    uint public constant MAX_STAGE_1_LIMIT = 1 ether;
    uint public constant MAX_STAGE_2_LIMIT = 2 ether;

    uint public constant STAGE_1 = 1;
    uint public constant STAGE_2 = 2;
    uint public constant STAGE_3 = 3;


    /// Exchange rates
    uint public  exchangeRate = 12500;


    uint public constant MINER_STAKE = 3000;    // for minter
    uint public constant OPEN_SALE_STAKE = 625; // for public
    uint public constant OTHER_STAKE = 6375;    // for others

    
    uint public constant DIVISOR_STAKE = 10000;

    // max open sale tokens
    uint public constant MAX_OPEN_SOLD = SEELE_TOTAL_SUPPLY * OPEN_SALE_STAKE / DIVISOR_STAKE;
    uint public constant STAKE_MULTIPLIER = SEELE_TOTAL_SUPPLY / DIVISOR_STAKE;

    /// All deposited ETH will be instantly forwarded to this address.
    address public wallet;
    address public minerAddress;
    address public otherAddress;

    /// Contribution start time
    uint public startTime;
    /// Contribution end time
    uint public endTime;

    /// Fields that can be changed by functions
    /// Accumulator for open sold tokens
    uint public openSoldTokens;
    /// ERC20 compilant seele token contact instance
    SeeleToken public seeleToken; 

    SeeleToken public oldSeeleToken;

    /// tags show address can join in open sale
    mapping (address => bool) public fullWhiteList;

    mapping (address => bool) public vistFlagList;

    mapping (address => uint) public firstStageFund;
    mapping (address => uint) public secondStageFund;

    /*
     * EVENTS
     */
    event NewSale(address indexed destAddress, uint ethCost, uint gotTokens);
    event NewWallet(address onwer, address oldWallet, address newWallet);

    modifier notEarlierThan(uint x) {
        require(now >= x);
        _;
    }

    modifier earlierThan(uint x) {
        require(now < x);
        _;
    }

    modifier ceilingNotReached() {
        require(openSoldTokens < MAX_OPEN_SOLD);
        _;
    }  

    modifier isSaleEnded() {
        require(now > endTime || openSoldTokens >= MAX_OPEN_SOLD);
        _;
    }

    modifier validAddress( address addr ) {
        require(addr != address(0x0));
        require(addr != address(this));
        _;
    }

    function SeeleCrowdSale (
        address _wallet, 
        address _minerAddress,
        address _otherAddress
        ) public 
        validAddress(_wallet) 
        validAddress(_minerAddress) 
        validAddress(_otherAddress) 
        {
        paused = true;  
        wallet = _wallet;
        minerAddress = _minerAddress;
        otherAddress = _otherAddress;     

        openSoldTokens = 0;
        /// Create seele token contract instance
        seeleToken = new SeeleToken(this, msg.sender, SEELE_TOTAL_SUPPLY);

        seeleToken.mint(minerAddress, MINER_STAKE * STAKE_MULTIPLIER, false);
        seeleToken.mint(otherAddress, OTHER_STAKE * STAKE_MULTIPLIER, false);
    }

    function setOldSeelToken(address addr)
        public
        onlyOwner
    {
        oldSeeleToken = SeeleToken(addr);
    }

    function setExchangeRate(uint256 rate)
        public
        onlyOwner
        earlierThan(endTime)
    {
        exchangeRate = rate;
    }

    function setStartTime(uint _startTime )
        public
        onlyOwner
    {
        startTime = _startTime;
        endTime = startTime + MAX_SALE_DURATION;
    }

    /// @dev batch set quota for user admin
    /// if openTag <=0, removed 
    function setWhiteList(address[] users, bool openTag)
        external
        onlyOwner
        earlierThan(endTime)
    {
        require(saleNotEnd());
        for (uint i = 0; i < users.length; i++) {
            address receipient = users[i];
            bool visitFlag = vistFlagList[receipient];
            if( openTag == true && visitFlag == false){
                uint token = oldSeeleToken.lockedBalances(receipient);
                if( token > 0){
                    seeleToken.mint(receipient, token,true);
                    openSoldTokens = openSoldTokens.add(token);
                }
                vistFlagList[receipient] = true;
            }
            fullWhiteList[receipient] = openTag;
        }
    }


    /// @dev batch set quota for early user quota
    /// if openTag <=0, removed 
    function addWhiteList(address user, bool openTag)
        external
        onlyOwner
        earlierThan(endTime)
    {
        require(saleNotEnd());
        fullWhiteList[user] = openTag;

    }

    /// @dev Emergency situation
    function setWallet(address newAddress)  external onlyOwner { 
        NewWallet(owner, wallet, newAddress);
        wallet = newAddress; 
    }

    /// @return true if sale not ended, false otherwise.
    function saleNotEnd() constant internal returns (bool) {
        return now < endTime && openSoldTokens < MAX_OPEN_SOLD;
    }

    /**
     * Fallback function 
     * 
     * @dev If anybody sends Ether directly to this  contract, consider he is getting seele token
     */
    function () public payable {
        buySeele(msg.sender);
    }

    /*
     * PUBLIC FUNCTIONS
     */
    /// @dev Exchange msg.value ether to Seele for account recepient
    /// @param receipient Seele tokens receiver
    function buySeele(address receipient) 
        internal 
        whenNotPaused  
        ceilingNotReached 
        notEarlierThan(startTime)
        earlierThan(endTime)
        validAddress(receipient)
        returns (bool) 
    {
        // Do not allow contracts to game the system
        require(!isContract(msg.sender));    
        require(tx.gasprice <= 100000000000 wei);
        require(msg.value >= MIN_LIMIT);

        bool inWhiteListTag = fullWhiteList[receipient];       
        require(inWhiteListTag == true);

        uint stage = STAGE_3;
        if ( startTime <= now && now < startTime + STAGE_1_TIME ) {
            stage = STAGE_1;
            require(msg.value <= MAX_STAGE_1_LIMIT);
            uint fund1 = firstStageFund[receipient];
            require (fund1 < MAX_STAGE_1_LIMIT );
        }else if ( startTime + STAGE_1_TIME <= now && now < startTime + STAGE_2_TIME ) {
            stage = STAGE_2;
            require(msg.value <= MAX_STAGE_2_LIMIT);
            uint fund2 = secondStageFund[receipient];
            require (fund2 < MAX_STAGE_2_LIMIT );
        }

        doBuy(receipient, stage);

        return true;
    }


    /// @dev Buy seele token normally
    function doBuy(address receipient, uint stage) internal {
        // protect partner quota in stage one
        uint value = msg.value;

        if ( stage == STAGE_1 ) {
            uint fund1 = firstStageFund[receipient];
            fund1 = fund1.add(value);
            if (fund1 > MAX_STAGE_1_LIMIT ) {
                uint refund1 = fund1.sub(MAX_STAGE_1_LIMIT);
                value = value.sub(refund1);
                msg.sender.transfer(refund1);
            }
        }else if ( stage == STAGE_2 ) {
            uint fund2 = secondStageFund[receipient];
            fund2 = fund2.add(value);
            if (fund2 > MAX_STAGE_2_LIMIT) {
                uint refund2 = fund2.sub(MAX_STAGE_2_LIMIT);
                value = value.sub(refund2);
                msg.sender.transfer(refund2);
            }            
        }

        uint tokenAvailable = MAX_OPEN_SOLD.sub(openSoldTokens);
        require(tokenAvailable > 0);
        uint toFund;
        uint toCollect;
        (toFund, toCollect) = costAndBuyTokens(tokenAvailable, value);
        if (toFund > 0) {
            require(seeleToken.mint(receipient, toCollect,true));         
            wallet.transfer(toFund);
            openSoldTokens = openSoldTokens.add(toCollect);
            NewSale(receipient, toFund, toCollect);             
        }

        // not enough token sale, just return eth
        uint toReturn = value.sub(toFund);
        if (toReturn > 0) {
            msg.sender.transfer(toReturn);
        }

        if ( stage == STAGE_1 ) {
            firstStageFund[receipient] = firstStageFund[receipient].add(toFund);
        }else if ( stage == STAGE_2 ) {
            secondStageFund[receipient] = secondStageFund[receipient].add(toFund);          
        }
    }

    /// @dev Utility function for calculate available tokens and cost ethers
    function costAndBuyTokens(uint availableToken, uint value) constant internal returns (uint costValue, uint getTokens) {
        // all conditions has checked in the caller functions
        getTokens = exchangeRate * value;

        if (availableToken >= getTokens) {
            costValue = value;
        } else {
            costValue = availableToken / exchangeRate;
            getTokens = availableToken;
        }
    }

    /// @dev Internal function to determine if an address is a contract
    /// @param _addr The address being queried
    /// @return True if `_addr` is a contract
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) {
            return false;
        }

        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}