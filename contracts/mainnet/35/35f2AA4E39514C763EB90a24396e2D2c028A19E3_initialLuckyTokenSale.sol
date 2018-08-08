pragma solidity 0.4.14;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control 
 * functions, this simplifies the implementation of "user permissions". 
 */
contract Ownable {
  address public owner;


  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev revert()s if called by any account other than the owner. 
   */
  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to. 
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}



/**
 * Math operations with safety checks
 */
library SafeMath {
  
  
  function mul256(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div256(uint256 a, uint256 b) internal returns (uint256) {
    require(b > 0); // Solidity automatically revert()s when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub256(uint256 a, uint256 b) internal returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add256(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }  
  

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}




/**
 * @title ERC20 interface
 * @dev ERC20 interface with allowances. 
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}




/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       revert();
     }
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub256(_value);
    balances[_to] = balances[_to].add256(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}




/**
 * @title Standard ERC20 token
 * @dev Implemantation of the basic standart token.
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already revert() if this condition is not met
    // if (_value > _allowance) revert();

    balances[_to] = balances[_to].add256(_value);
    balances[_from] = balances[_from].sub256(_value);
    allowed[_from][msg.sender] = _allowance.sub256(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) {

    //  To change the approve amount you first have to reduce the addresses
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }


}



/**
 * @title LuckyToken
 * @dev The main Lucky token contract
 * 
 */
 
contract LuckyToken is StandardToken, Ownable{
  string public name = "Lucky888Coin";
  string public symbol = "LKY";
  uint public decimals = 18;

  event TokenBurned(uint256 value);
  
  function LuckyToken() {
    totalSupply = (10 ** 8) * (10 ** decimals);
    balances[msg.sender] = totalSupply;
  }

  /**
   * @dev Allows the owner to burn the token
   * @param _value number of tokens to be burned.
   */
  function burn(uint _value) onlyOwner {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] = balances[msg.sender].sub256(_value);
    totalSupply = totalSupply.sub256(_value);
    TokenBurned(_value);
  }

}

/**
 * @title InitialTeuTokenSale
 * @dev The Initial TEU token sale contract
 * 
 */
contract initialLuckyTokenSale is Ownable {
  using SafeMath for uint256;
  event LogPeriodStart(uint period);
  event LogCollectionStart(uint period);
  event LogContribution(address indexed contributorAddress, uint256 weiAmount, uint period);
  event LogCollect(address indexed contributorAddress, uint256 tokenAmount, uint period); 

  LuckyToken                                       private  token; 
  mapping(uint => address)                       private  walletOfPeriod;
  uint256                                        private  minContribution = 0.1 ether;
  uint                                           private  saleStart;
  bool                                           private  isTokenCollectable = false;
  mapping(uint => uint)                          private  periodStart;
  mapping(uint => uint)                          private  periodDeadline;
  mapping(uint => uint256)                       private  periodTokenPool;

  mapping(uint => mapping (address => uint256))  private  contribution;  
  mapping(uint => uint256)                       private  periodContribution;  
  mapping(uint => mapping (address => bool))     private  collected;  
  mapping(uint => mapping (address => uint256))  private  tokenCollected;  
  
  uint public totalPeriod = 0;
  uint public currentPeriod = 0;


  /**
   * @dev Initialise the contract
   * @param _tokenAddress address of TEU token
   * @param _walletPeriod1 address of period 1 wallet
   * @param _walletPeriod2 address of period 2 wallet
   * @param _tokenPoolPeriod1 amount of pool of token in period 1
   * @param _tokenPoolPeriod2 amount of pool of token in period 2
   * @param _saleStartDate start date / time of the token sale
   */
  function initTokenSale (address _tokenAddress
  , address _walletPeriod1, address _walletPeriod2
  , uint256 _tokenPoolPeriod1, uint256 _tokenPoolPeriod2
  , uint _saleStartDate) onlyOwner {
    assert(totalPeriod == 0);
    assert(_tokenAddress != address(0));
    assert(_walletPeriod1 != address(0));
    assert(_walletPeriod2 != address(0));
    walletOfPeriod[1] = _walletPeriod1;
    walletOfPeriod[2] = _walletPeriod2;
    periodTokenPool[1] = _tokenPoolPeriod1;
    periodTokenPool[2] = _tokenPoolPeriod2;
    token = LuckyToken(_tokenAddress);
    assert(token.owner() == owner);
    setPeriodStart(_saleStartDate);
 
  }
  
  
  /**
   * @dev Allows the owner to set the starting time.
   * @param _saleStartDate the new sales start date / time
   */  
  function setPeriodStart(uint _saleStartDate) onlyOwner beforeSaleStart private {
    totalPeriod = 0;
    saleStart = _saleStartDate;
    
    uint period1_contributionInterval = 2 hours;
    uint period1_collectionInterval = 2 hours;
    uint period2_contributionInterval = 2 hours;
    
    addPeriod(saleStart, saleStart + period1_contributionInterval);
    addPeriod(saleStart + period1_contributionInterval + period1_collectionInterval, saleStart + period1_contributionInterval + period1_collectionInterval + period2_contributionInterval);

    currentPeriod = 1;    
  } 
  
  function addPeriod(uint _periodStart, uint _periodDeadline) onlyOwner beforeSaleEnd private {
    require(_periodStart >= now && _periodDeadline > _periodStart && (totalPeriod == 0 || _periodStart > periodDeadline[totalPeriod]));
    totalPeriod = totalPeriod + 1;
    periodStart[totalPeriod] = _periodStart;
    periodDeadline[totalPeriod] = _periodDeadline;
    periodContribution[totalPeriod] = 0;
  }


  /**
   * @dev Call this method to let the contract to go into next period of sales
   */
  function goNextPeriod() onlyOwner public {
    for (uint i = 1; i <= totalPeriod; i++) {
        if (currentPeriod < totalPeriod && now >= periodStart[currentPeriod + 1]) {
            currentPeriod = currentPeriod + 1;
            isTokenCollectable = false;
            LogPeriodStart(currentPeriod);
        }
    }
    
  }

  /**
   * @dev Call this method to let the contract to allow token collection after the contribution period
   */  
  function goTokenCollection() onlyOwner public {
    require(currentPeriod > 0 && now > periodDeadline[currentPeriod] && !isTokenCollectable);
    isTokenCollectable = true;
    LogCollectionStart(currentPeriod);
  }

  /**
   * @dev modifier to allow contribution only when the sale is ON
   */
  modifier saleIsOn() {
    require(currentPeriod > 0 && now >= periodStart[currentPeriod] && now < periodDeadline[currentPeriod]);
    _;
  }
  
  /**
   * @dev modifier to allow collection only when the collection is ON
   */
  modifier collectIsOn() {
    require(isTokenCollectable && currentPeriod > 0 && now > periodDeadline[currentPeriod] && (currentPeriod == totalPeriod || now < periodStart[currentPeriod + 1]));
    _;
  }
  
  /**
   * @dev modifier to ensure it is before start of first period of sale
   */  
  modifier beforeSaleStart() {
    require(totalPeriod == 0 || now < periodStart[1]);
    _;  
  }
  /**
   * @dev modifier to ensure it is before the deadline of last sale period
   */  
   
  modifier beforeSaleEnd() {
    require(currentPeriod == 0 || now < periodDeadline[totalPeriod]);
    _;
  }
  /**
   * @dev modifier to ensure it is after the deadline of last sale period
   */ 
  modifier afterSaleEnd() {
    require(currentPeriod > 0 && now > periodDeadline[totalPeriod]);
    _;
  }
  
  modifier overMinContribution() {
    require(msg.value >= minContribution);
    _;
  }
  
  
  /**
   * @dev record the contribution of a contribution 
   */
  function contribute() private saleIsOn overMinContribution {
    contribution[currentPeriod][msg.sender] = contribution[currentPeriod][msg.sender].add256(msg.value);
    periodContribution[currentPeriod] = periodContribution[currentPeriod].add256(msg.value);
    assert(walletOfPeriod[currentPeriod].send(msg.value));
    LogContribution(msg.sender, msg.value, currentPeriod);
  }

  /**
   * @dev Allows contributor to collect all token alloted for all period after preiod deadline
   */
  function collectToken() public collectIsOn {
    uint256 _tokenCollected = 0;
    for (uint i = 1; i <= totalPeriod; i++) {
        if (!collected[i][msg.sender] && contribution[i][msg.sender] > 0)
        {
            _tokenCollected = contribution[i][msg.sender].mul256(periodTokenPool[i]).div256(periodContribution[i]);

            collected[i][msg.sender] = true;
            token.transfer(msg.sender, _tokenCollected);

            tokenCollected[i][msg.sender] = _tokenCollected;
            LogCollect(msg.sender, _tokenCollected, i);
        }
    }
  }


  /**
   * @dev Allow owner to transfer out the token in the contract
   * @param _to address to transfer to
   * @param _amount amount to transfer
   */  
  function transferTokenOut(address _to, uint256 _amount) public onlyOwner {
    token.transfer(_to, _amount);
  }

  /**
   * @dev Allow owner to transfer out the ether in the contract
   * @param _to address to transfer to
   * @param _amount amount to transfer
   */  
  function transferEtherOut(address _to, uint256 _amount) public onlyOwner {
    assert(_to.send(_amount));
  }  

  /**
   * @dev to get the contribution amount of any contributor under different period
   * @param _period period to get the contribution amount
   * @param _contributor contributor to get the conribution amount
   */  
  function contributionOf(uint _period, address _contributor) public constant returns (uint256) {
    return contribution[_period][_contributor] ;
  }

  /**
   * @dev to get the total contribution amount of a given period
   * @param _period period to get the contribution amount
   */  
  function periodContributionOf(uint _period) public constant returns (uint256) {
    return periodContribution[_period];
  }

  /**
   * @dev to check if token is collected by any contributor under different period
   * @param _period period to get the collected status
   * @param _contributor contributor to get collected status
   */  
  function isTokenCollected(uint _period, address _contributor) public constant returns (bool) {
    return collected[_period][_contributor] ;
  }
  
  /**
   * @dev to get the amount of token collected by any contributor under different period
   * @param _period period to get the amount
   * @param _contributor contributor to get amont
   */  
  function tokenCollectedOf(uint _period, address _contributor) public constant returns (uint256) {
    return tokenCollected[_period][_contributor] ;
  }

  /**
   * @dev Fallback function which receives ether and create the appropriate number of tokens for the 
   * msg.sender.
   */
  function() external payable {
    contribute();
  }

}