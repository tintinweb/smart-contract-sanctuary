pragma solidity ^0.4.15;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

contract BasicToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */

    function transfer(address _to, uint256 _value) returns (bool) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        }else {
            return false;
        }
    }
    

    /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */

    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        uint256 _allowance = allowed[_from][msg.sender];
        allowed[_from][msg.sender] = _allowance.sub(_value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
}


    /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */

    function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract TalentToken is BasicToken {

using SafeMath for uint256;

string public name = "Talent Token";              
string public symbol = "TAL";                               // Token&#39;s Symbol
uint8 public decimals = 18;                                 // How Many Decimals for Token
uint256 public totalSupply = 98000000 * 10**18;             // The total supply.

// variables
uint256 public TotalTokens;                // variable to keep track of funds allocated
uint256 public LongTermProjectTokens;      // Funds to be used in the long term for the development of future projects.
uint256 public TeamFundsTokens;            // Funds for the team.
uint256 public IcoTokens;                  // Funds to be used for the ICO
uint256 public platformTokens;             // Tokens to be retained for future sale by various platforms.

// addresses    
address public owner;                               // Owner of the Contract
address public crowdFundAddress;                    // Crowdfund Contract Address
address public founderAddress = 0xe3f38940A588922F2082FE30bCAe6bB0aa633a7b;
address public LongTermProjectTokensAddress = 0x689Aff79dCAbdFd611273703C62821baBb39823a;
address public teamFundsAddress = 0x2dd75A9A6C99B824811e3aCe16a63882Ff4C1C03;
address public platformTokensAddress = 0x5F0Be8081692a3A96d2ad10Ae5ce14488a045B10;

//events

event ChangeFoundersWalletAddress(uint256  _blockTimeStamp, address indexed _foundersWalletAddress);

//modifiers

  modifier onlyCrowdFundAddress() {
    require(msg.sender == crowdFundAddress);
    _;
  }

  modifier nonZeroAddress(address _to) {
    require(_to != 0x0);
    _;
  }

  modifier onlyFounders() {
    require(msg.sender == founderAddress);
    _;
  }
  
   // creation of the token contract 
   function TalentToken (address _crowdFundAddress) {
    owner = msg.sender;
    crowdFundAddress = _crowdFundAddress;

    // Token Distribution 
    LongTermProjectTokens = 22540000 * 10**18;    // 23 % allocation of totalSupply. Used for further development of projects.
    TeamFundsTokens = 1960000 * 10**18;           // 2% of total tokens.
    platformTokens = 19600000 * 10**18;           // 20% of total tokens.
    IcoTokens = 53900000 * 10**18;                // ICO Tokens = 55% allocation of totalSupply

    //Assigned budget
    balances[crowdFundAddress] = IcoTokens;
    balances[LongTermProjectTokensAddress] = LongTermProjectTokens;
    balances[teamFundsAddress] = TeamFundsTokens;
    balances[platformTokensAddress] = platformTokens;

  }


// fallback function to restrict direct sending of ether
  function () {
    revert();
  }

}

contract TalentICO {

    using SafeMath for uint256;
    
    TalentToken public token;                                 // Token contract reference
         
    uint256 public IcoStartDate = 1519862400;                 // March 1st, 2018, 00:00:00
    uint256 public IcoEndDate = 1546300799;                   // 31st Dec, 11:59:59
    uint256 public WeiRaised;                                 // Counter to track the amount raised
    uint256 public initialExchangeRateForETH = 15000;         // Initial Number of Token per Ether
    uint256 internal IcoTotalTokensSold = 0;
    uint256 internal minAmount = 1 * 10 ** 17;                //The minimum amount to trade.
    bool internal isTokenDeployed = false;                    // Flag to track the token deployment -- only can be set once


     // Founder&#39;s Address
    address public founderAddress = 0xe3f38940A588922F2082FE30bCAe6bB0aa633a7b;                            
    // Owner of the contract
    address public owner;                                              
    
    enum State {Crowdfund, Finish}

    //events
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount); 
    event CrowdFundClosed(uint256 _blockTimeStamp);
    event ChangeFoundersWalletAddress(uint256 _blockTimeStamp, address indexed _foundersWalletAddress);
   
    //Modifiers
    modifier tokenIsDeployed() {
        require(isTokenDeployed == true);
        _;
    }
    modifier nonZeroEth() {
        require(msg.value > 0);
        _;
    }

    modifier nonZeroAddress(address _to) {
        require(_to != 0x0);
        _;
    }

    modifier onlyFounders() {
        require(msg.sender == founderAddress);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyPublic() {
        require(msg.sender != founderAddress);
        _;
    }

    modifier inState(State state) {
        require(getState() == state); 
        _;
    }

     // Constructor
    function TalentICO () {
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public onlyOwner returns (bool) {
        owner = newOwner;
    }

    // Used to attach the token&#39;s contract.
    function setTokenAddress(address _tokenAddress) external onlyFounders nonZeroAddress(_tokenAddress) {
        require(isTokenDeployed == false);
        token = TalentToken(_tokenAddress);
        isTokenDeployed = true;
    }


    // Used to change founder&#39;s address.
     function setfounderAddress(address _newFounderAddress) onlyFounders  nonZeroAddress(_newFounderAddress) {
        founderAddress = _newFounderAddress;
        ChangeFoundersWalletAddress(now, founderAddress);
    }

    // function call after ICO ends.
    // Transfers Remaining Tokens to holder.
    function ICOend() onlyFounders inState(State.Finish) returns (bool) {
        require(now > IcoEndDate);
        uint256 remainingToken = token.balanceOf(this);  // remaining tokens
        if (remainingToken != 0) 
          token.transfer(founderAddress, remainingToken); 
        CrowdFundClosed(now);
        return true; 
    }

    // Allows users to buy tokens.
    function buyTokens(address beneficiary) 
    nonZeroEth 
    tokenIsDeployed 
    onlyPublic 
    nonZeroAddress(beneficiary) 
    payable 
    returns(bool) 
    {
        require(msg.value >= minAmount);

        require(now >= IcoStartDate && now <= IcoEndDate);
        fundTransfer(msg.value);

        uint256 amount = numberOfTokens(getCurrentExchangeRate(), msg.value);
            
        if (token.transfer(beneficiary, amount)) {
            IcoTotalTokensSold = IcoTotalTokensSold.add(amount);
            WeiRaised = WeiRaised.add(msg.value);
            TokenPurchase(beneficiary, msg.value, amount);
            return true;
        } 

    return false;
       
    }

    // Function determines current exchange rate.
    // This increases the price of the token, as time passes.
    function getCurrentExchangeRate() internal view returns (uint256) {

        uint256 timeDiff = IcoEndDate - IcoStartDate;

        uint256 etherDiff = 11250; //Difference of exchange rate between start date and end date.

        uint256 initialTimeDiff = now - IcoStartDate;

        uint256 exchangeRateLess = (initialTimeDiff * etherDiff) / timeDiff;

        return (initialExchangeRateForETH - exchangeRateLess);    

    }
           

// Calculates total number of tokens.
    function numberOfTokens(uint256 _exchangeRate, uint256 _amount) internal constant returns (uint256) {
         uint256 noOfToken = _amount.mul(_exchangeRate);
         return noOfToken;
    }

    // Transfers funds to founder&#39;s account.
    function fundTransfer(uint256 weiAmount) internal {
        founderAddress.transfer(weiAmount);
    }


// Get functions 

    // Gets the current state of the crowdsale
    function getState() public constant returns(State) {

        if (now >= IcoStartDate && now <= IcoEndDate) {
            return State.Crowdfund;
        } 
        return State.Finish;
    }

    // GET functions

    function getExchangeRate() public constant returns (uint256 _exchangeRateForETH) {

        return getCurrentExchangeRate();
    
    }

    function getNoOfSoldToken() public constant returns (uint256 _IcoTotalTokensSold) {
        return (IcoTotalTokensSold);
    }

    function getWeiRaised() public constant returns (uint256 _WeiRaised) {
        return WeiRaised;
    }

    //Sends ether to founder&#39;s address.
    function() public payable {
        buyTokens(msg.sender);
    }
}