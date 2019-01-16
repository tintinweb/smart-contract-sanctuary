/*************************
 * 
 *  `＿　　　　　   (三|  
 *  |ﾋ_)　／￣￣＼ 　PDT  
 *  | | ／●) (●)  ＼｜｜  
 *  |_|(　(_人_)　　)^亅  
 *  | ヽ＼　￣　＿／ ミﾉ  
 *  ヽﾉﾉ￣|ﾚ―-ｲ / ﾉ  ／   
 *  　＼　ヽ＼ |/ イ      
 * 　／￣二二二二二二＼   
 * `｜raj｜ Paradise ｜｜  
 * 　＼＿二二二二二二／   
 *
 *************************/

pragma solidity ^0.5.0;

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
  constructor() public {
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

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
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

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

 /**
 * @title ERC20Basic
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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

/**
 * @title Basic token
 * @dev Basic version of StandardToken
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
    emit Transfer(msg.sender, _to, _value);
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

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
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
    emit Transfer(_from, _to, _value);
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
    emit Approval(msg.sender, _spender, _value);
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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


/*
 * ParadiseToken is a standard ERC20 token with some additional functionalities:
 * - Transfers are only enabled after contract owner enables it (After StartTime)
 * - Contract sets 70% of the total supply as allowance for ICO contract
 */
    
contract ParadiseToken is StandardToken, Ownable {
    
    // Constants
    string public constant symbol = "PDT";
    string public constant name = "Paradise Token";
    uint8 public constant decimals = 18;
    uint256 public constant InitialSupplyCup = 300000000 * (10 ** uint256(decimals)); // 300 mil tokens minted
    uint256 public constant TokenAllowance = 210000000 * (10 ** uint256(decimals));   // 210 mil tokens public allowed 
    uint256 public constant AdminAllowance = InitialSupplyCup - TokenAllowance;       // 90 mil tokens admin allowed 
    
    // Properties
    address public adminAddr;              // the number of tokens available for the administrator
    address public tokenAllowanceAddr = 0x9A4518ad59ac1D0Fc9A77d9083f233cD0b8d77Fa; // the number of tokens available for crowdsales
    bool public transferEnabled = false;   // indicates if transferring tokens is enabled or not
    
    
    modifier onlyWhenTransferAllowed() {
        require(transferEnabled || msg.sender == adminAddr || msg.sender == tokenAllowanceAddr);
        _;
    }

    /**
     * Check if token offering address is set or not
     */
    modifier onlyTokenOfferingAddrNotSet() {
        require(tokenAllowanceAddr == address(0x0));
        _;
    }

    /**
     * Check if address is a valid destination to transfer tokens to
     * - must not be zero address
     * - must not be the token address
     * - must not be the owner&#39;s address
     * - must not be the admin&#39;s address
     * - must not be the token offering contract address
     */
    modifier validDestination(address to) {
        require(to != address(0x0));
        require(to != address(this));
        require(to != owner);
        require(to != address(adminAddr));
        require(to != address(tokenAllowanceAddr));
        _;
    }
    
    /**
     * Token contract constructor
     *
     * @param admin Address of admin account
     */
    constructor(address admin) public {
        totalSupply = InitialSupplyCup;
        
        // Mint tokens
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply);

        // Approve allowance for admin account
        adminAddr = admin;
        approve(adminAddr, AdminAllowance);
    }

    /**
     * Set token offering to approve allowance for offering contract to distribute tokens
     *
     * Note that if _amountForSale is 0, then it is assumed that the full
     * remaining crowdsale supply is made available to the crowdsale.
     * 
     * @param offeringAddr Address of token offerng contract
     * @param amountForSale Amount of tokens for sale, set 0 to max out
     */
    function setTokenOffering(address offeringAddr, uint256 amountForSale) external onlyOwner {
        require(!transferEnabled);

        uint256 amount = (amountForSale == 0) ? TokenAllowance : amountForSale;
        require(amount <= TokenAllowance);

        approve(offeringAddr, amount);
        tokenAllowanceAddr = offeringAddr;
        
    }
    
    /**
     * Enable transfers
     */
    function enableTransfer() external onlyOwner {
        transferEnabled = true;

        // End the offering
        approve(tokenAllowanceAddr, 0);
    }

    /**
     * Transfer from sender to another account
     *
     * @param to Destination address
     * @param value Amount of PDTtokens to send
     */
    function transfer(address to, uint256 value) public onlyWhenTransferAllowed validDestination(to) returns (bool) {
        return super.transfer(to, value);
    }
    
    /**
     * Transfer from `from` account to `to` account using allowance in `from` account to the sender
     *
     * @param from Origin address
     * @param to Destination address
     * @param value Amount of PDTtokens to send
     */
    function transferFrom(address from, address to, uint256 value) public onlyWhenTransferAllowed validDestination(to) returns (bool) {
        return super.transferFrom(from, to, value);
    }
    
}

/**
 * The ParadiseToken token (PDT) has a fixed supply and restricts the ability
 * to transfer tokens until the owner has called the enableTransfer()
 * function.
 *
 * The owner can associate the token with a token sale contract. In that
 * case, the token balance is moved to the token sale contract, which
 * in turn can transfer its tokens to contributors to the sale.
 */

contract ParadiseTokenSale is Pausable {

    using SafeMath for uint256;

    // The beneficiary is the future recipient of the funds
    address public beneficiary = 0x6c0ac78467670f47E65dd5798c104869b7C639AD;

    // The crowdsale has a funding goal, cap, deadline, and minimum contribution
    uint public fundingGoal = 7300 ether;   // Base on 230$ per ether
    uint public fundingCap = 17000 ether;
    uint public minContribution = 10**17;  // 0.1 Ether
    bool public fundingGoalReached = false;
    bool public fundingCapReached = false;
    bool public saleClosed = false;

    // Time period of sale (UNIX timestamps)
    uint public startTime = 1543392911; // 11/28/2018 @ 8:15am (UTC)
    uint public endTime = 1544601672;  //  12/12/2018 @ 8:01am (UTC)
   
    // Keeps track of the amount of wei raised
    uint public amountRaised;
    // amount that has been refunded so far
    uint public refundAmount;

    // The ratio of PDT to Ether
    uint public rate;
    uint public constant LOW_RANGE_RATE = 10000;    // 0% bonus
    uint public constant HIGH_RANGE_RATE = 14000;   // 40% bonus for 1 week
    
    // The token being sold
    ParadiseToken public tokenReward;

    // A map that tracks the amount of wei contributed by address
    mapping(address => uint256) public balanceOf;
    
    // Events
    event GoalReached(address _beneficiary, uint _amountRaised);
    event CapReached(address _beneficiary, uint _amountRaised);
    event FundTransfer(address _backer, uint _amount, bool _isContribution);

    // Modifiers
    modifier beforeDeadline()   { require (currentTime() < endTime); _; }
    modifier afterDeadline()    { require (currentTime() >= endTime); _; }
    modifier afterStartTime()    { require (currentTime() >= startTime); _; }

    modifier saleNotClosed()    { require (!saleClosed); _; }

    
    /**
     * Constructor for a crowdsale of ParadiseToken tokens.
     *
     * @param ifSuccessfulSendTo            the beneficiary of the fund
     * @param fundingGoalInEthers           the minimum goal to be reached
     * @param fundingCapInEthers            the cap (maximum) size of the fund
     * @param minimumContributionInWei      minimum contribution (in wei)
     * @param start                         the start time (UNIX timestamp)
     * @param durationInMinutes             the duration of the crowdsale in minutes
     * @param ratePDTToEther                the conversion rate from PDT to Ether
     * @param addressOfTokenUsedAsReward    address of the token being sold
     */
    constructor(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint fundingCapInEthers,
        uint minimumContributionInWei,
        uint start,
        uint durationInMinutes,
        uint ratePDTToEther,
        address addressOfTokenUsedAsReward
    ) public {
        require(ifSuccessfulSendTo != address(0) && ifSuccessfulSendTo != address(this));
        require(addressOfTokenUsedAsReward != address(0) && addressOfTokenUsedAsReward != address(this));
        require(fundingGoalInEthers <= fundingCapInEthers);
        require(durationInMinutes > 0);
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        fundingCap = fundingCapInEthers * 1 ether;
        minContribution = minimumContributionInWei;
        startTime = start;
        endTime = start + durationInMinutes * 1 minutes; 
        setRate(ratePDTToEther);
        tokenReward = ParadiseToken(addressOfTokenUsedAsReward);
    }

    /**
     * This function is called whenever Ether is sent to the
     * smart contract. It can only be executed when the crowdsale is
     * not paused, not closed, and before the deadline has been reached.
     *
     * This function will update state variables for whether or not the
     * funding goal or cap have been reached. It also ensures that the
     * tokens are transferred to the sender, and that the correct
     * number of tokens are sent according to the current rate.
     */
    function () payable external {
        buy();
    }

    function buy ()
        payable public
        whenNotPaused
        beforeDeadline
        afterStartTime
        saleNotClosed
    {
        require(msg.value >= minContribution);
        uint amount = msg.value;
        
        // Compute the number of tokens to be rewarded to the sender
        // Note: it&#39;s important for this calculation that both wei
        // and PDT have the same number of decimal places (18)
        uint numTokens = amount.mul(rate);
        
        // Transfer the tokens from the crowdsale supply to the sender
        if (tokenReward.transferFrom(tokenReward.owner(), msg.sender, numTokens)) {
    
        // update the total amount raised
        amountRaised = amountRaised.add(amount);
     
        // update the sender&#39;s balance of wei contributed
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);

        emit FundTransfer(msg.sender, amount, true);
        // Check if the funding goal or cap have been reached
        checkFundingGoal();
        checkFundingCap();
        }
        else {
            revert();
        }
    }
    
    /**
     * The owner can update the rate (PDT to ETH).
     *
     * @param _rate  the new rate for converting PDT to ETH
     */
    function setRate(uint _rate) public onlyOwner {
        require(_rate >= LOW_RANGE_RATE && _rate <= HIGH_RANGE_RATE);
        rate = _rate;
    }
    
     /**
     * The owner can terminate the crowdsale at any time.
     */
    function terminate() external onlyOwner {
        saleClosed = true;
    }
    
     /**
     *
     * The owner can allocate the specified amount of tokens from the
     * crowdsale allowance to the recipient (to).
     *
     * NOTE: be extremely careful to get the amounts correct, which
     * are in units of wei and PDT. Every digit counts.
     *
     * @param to            the recipient of the tokens
     * @param amountWei     the amount contributed in wei
     * @param amountPDT the amount of tokens transferred in PDT
     */
     
     
     function ownerAllocateTokens(address to, uint amountWei, uint amountPDT) public
            onlyOwner 
    {
        //don&#39;t allocate tokens for the admin
        //require(tokenReward.adminAddr() != to);
        
        if (!tokenReward.transferFrom(tokenReward.owner(), to, amountPDT)) {
            revert();
        }
        amountRaised = amountRaised.add(amountWei);
        balanceOf[to] = balanceOf[to].add(amountWei);
        emit FundTransfer(to, amountWei, true);
        checkFundingGoal();
        checkFundingCap();
    }

    /**
     * The owner can call this function to withdraw the funds that
     * have been sent to this contract. The funds will be sent to
     * the beneficiary specified when the crowdsale was created.
     */
    function ownerSafeWithdrawal() external onlyOwner  {
        uint balanceToSend = address(this).balance;
        address(0x6c0ac78467670f47E65dd5798c104869b7C639AD).transfer(balanceToSend);
        emit FundTransfer(beneficiary, balanceToSend, false);
    }
    
   /**
     * Checks if the funding goal has been reached. If it has, then
     * the GoalReached event is triggered.
     */
    function checkFundingGoal() internal {
        if (!fundingGoalReached) {
            if (amountRaised >= fundingGoal) {
                fundingGoalReached = true;
                emit GoalReached(beneficiary, amountRaised);
            }
        }
    }

    /**
     * Checks if the funding cap has been reached. If it has, then
     * the CapReached event is triggered.
     */
   function checkFundingCap() internal {
        if (!fundingCapReached) {
            if (amountRaised >= fundingCap) {
                fundingCapReached = true;
                saleClosed = true;
                emit CapReached(beneficiary, amountRaised);
            }
        }
    }

    /**
     * Returns the current time.
     * Useful to abstract calls to "now" for tests.
    */
    function currentTime() view public returns (uint _currentTime) {
        return now;
    }
}

interface IERC20 {
  function balanceOf(address _owner) external view returns (uint256);
  function allowance(address _owner, address _spender) external view returns (uint256);
  function transfer(address _to, uint256 _value) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
  function approve(address _spender, uint256 _value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title ParadiseToken initial distribution
 * @dev Distribute airdrop tokens
 */
 
contract PDTDistribution is Ownable {
  function drop(IERC20 token, address[] memory recipients, uint256[] memory values) public onlyOwner {
    for (uint256 i = 0; i < recipients.length; i++) {
      token.transfer(recipients[i], values[i]);
    }
  }
}

/*
 *（｀・P・）（｀・P・&#180;）（・P・&#180;）
 *     Created by Paradise
 *（&#180;・P・）（&#180;・P・｀）（・P・｀）
 */