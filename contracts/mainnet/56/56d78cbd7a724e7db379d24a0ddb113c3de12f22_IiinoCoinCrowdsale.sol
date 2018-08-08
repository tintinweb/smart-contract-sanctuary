pragma solidity ^0.4.20;

// File: contracts/Ownable.sol

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
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

// File: contracts/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transferInternal(address to, uint256 value) internal returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
    function transferInternal(address _to, uint256 _value) internal returns (bool) {
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

// File: contracts/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowanceInternal(address owner, address spender) internal view returns (uint256);
    function transferFromInternal(address from, address to, uint256 value) internal returns (bool);
    function approveInternal(address spender, uint256 value) internal returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/StandardToken.sol

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
    function transferFromInternal(address _from, address _to, uint256 _value) internal returns (bool) {
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
    function approveInternal(address _spender, uint256 _value) internal returns (bool) {
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
    function allowanceInternal(address _owner, address _spender) internal view returns (uint256) {
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
    function increaseApprovalInternal(address _spender, uint _addedValue) internal returns (bool) {
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
    function decreaseApprovalInternal(address _spender, uint _subtractedValue) internal returns (bool) {
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

// File: contracts/MintableToken.sol

//import "./StandardToken.sol";
//import "../../ownership/Ownable.sol";



/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;
    address public icoContractAddress;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
    * @dev Throws if called by any account other than the icoContract.
    */
    modifier onlyIcoContract() {
        require(msg.sender == icoContractAddress);
        _;
    }
  

    /**
    * @dev Function to mint tokens
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) onlyIcoContract canMint external returns (bool) {
        //return true;
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyOwner canMint external returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

}

// File: contracts/Pausable.sol

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
    function pause() onlyOwner whenNotPaused external {
        paused = true;
        emit Pause();
    }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
    function unpause() onlyOwner whenPaused external {
        paused = false;
        emit Unpause();
    }
}

// File: contracts/PausableToken.sol

/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

    function transferInternal(address _to, uint256 _value) internal whenNotPaused returns (bool) {
        return super.transferInternal(_to, _value);
    }

    function transferFromInternal(address _from, address _to, uint256 _value) internal whenNotPaused returns (bool) {
        return super.transferFromInternal(_from, _to, _value);
    }

    function approveInternal(address _spender, uint256 _value) internal whenNotPaused returns (bool) {
        return super.approveInternal(_spender, _value);
    }

    function increaseApprovalInternal(address _spender, uint _addedValue) internal whenNotPaused returns (bool success) {
        return super.increaseApprovalInternal(_spender, _addedValue);
    }

    function decreaseApprovalInternal(address _spender, uint _subtractedValue) internal whenNotPaused returns (bool success) {
        return super.decreaseApprovalInternal(_spender, _subtractedValue);
    }
}

// File: contracts/ReentrancyGuard.sol

/**
 * @title Helps contracts guard agains reentrancy attacks.
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="5b293e3638341b69">[email&#160;protected]</a>π.com>
 * @notice If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private reentrancy_lock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!reentrancy_lock);
    reentrancy_lock = true;
    _;
    reentrancy_lock = false;
  }

}

// File: contracts/IiinoCoin.sol

contract IiinoCoin is MintableToken, PausableToken, ReentrancyGuard {
    event RewardMint(address indexed to, uint256 amount);
    event RewardMintingAmt(uint256 _amountOfTokensMintedPreCycle);
    event ResetReward();
    event RedeemReward(address indexed to, uint256 value);

    event CreatedEscrow(bytes32 _tradeHash);
    event ReleasedEscrow(bytes32 _tradeHash);
    event Dispute(bytes32 _tradeHash);
    event CancelledBySeller(bytes32 _tradeHash);
    event CancelledByBuyer(bytes32 _tradeHash);
    event BuyerArbitratorSet(bytes32 _tradeHash);
    event SellerArbitratorSet(bytes32 _tradeHash);
    event DisputeResolved (bytes32 _tradeHash);
    event IcoContractAddressSet (address _icoContractAddress);
    
    using SafeMath for uint256;
    
    // Mapping of rewards to beneficiaries of the reward
    mapping(address => uint256) public reward;
  
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public amountMintPerDuration; // amount to mint during one minting cycle
    uint256 public durationBetweenRewardMints; // reward miniting cycle duration
    uint256 public previousDistribution; //EPOCH time of the previous distribution
    uint256 public totalRewardsDistributed; //Total amount of the rewards distributed
    uint256 public totalRewardsRedeemed; //Total amount of the rewards redeemed
    uint256 public minimumRewardWithdrawalLimit; //The minimum limit of rewards that can be withdrawn
    uint256 public rewardAvailableCurrentDistribution; //The amount of rewards available for the current Distribution.

    function IiinoCoin(
        string _name, 
        string _symbol, 
        uint8 _decimals, 
        uint256 _amountMintPerDuration, 
        uint256 _durationBetweenRewardMints 
    ) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        amountMintPerDuration = _amountMintPerDuration;
        durationBetweenRewardMints = _durationBetweenRewardMints;
        previousDistribution = now; // To initialize the previous distribution to the time of the creation of the contract
        totalRewardsDistributed = 0;
        totalRewardsRedeemed = 0;
        minimumRewardWithdrawalLimit = 10 ether; //Defaulted to 10 iiinos represented in iii
        rewardAvailableCurrentDistribution = amountMintPerDuration;
        icoContractAddress = msg.sender; 
    }
    
    /**
    * @dev set the icoContractAddress in the token so that the ico Contract can mint the token
    * @param _icoContractAddress array of address. The address to which the reward needs to be distributed
    */
    function setIcoContractAddress(
        address _icoContractAddress
    ) external nonReentrant onlyOwner whenNotPaused {
        require (_icoContractAddress != address(0));
        emit IcoContractAddressSet(_icoContractAddress);
        icoContractAddress = _icoContractAddress;    
    }

    /**
    * @dev distribute reward tokens to the list of addresses based on their proportion
    * @param _rewardAdresses array of address. The address to which the reward needs to be distributed
    */
    function batchDistributeReward(
        address[] _rewardAdresses,
        uint256[] _amountOfReward, 
        uint256 _timestampOfDistribution
    ) external nonReentrant onlyOwner whenNotPaused {
        require(_timestampOfDistribution > previousDistribution.add(durationBetweenRewardMints)); //To only allow a distribution to happen 30 days (2592000 seconds) after the previous distribution
        require(_timestampOfDistribution < now); // To only allow a distribution time in the past
        require(_rewardAdresses.length == _amountOfReward.length); // To verify the length of the arrays are the same.
        
        uint256 rewardDistributed = 0;

        for (uint j = 0; j < _rewardAdresses.length; j++) {
            rewardMint(_rewardAdresses[j], _amountOfReward[j]);
            rewardDistributed = rewardDistributed.add(_amountOfReward[j]);
        }
        require(rewardAvailableCurrentDistribution >= rewardDistributed);
        totalRewardsDistributed = totalRewardsDistributed.add(rewardDistributed);
        rewardAvailableCurrentDistribution = rewardAvailableCurrentDistribution.sub(rewardDistributed);
    }
    
    /**
    * @dev distribute reward tokens to a addresse based on the proportion
    * @param _rewardAddress The address to which the reward needs to be distributed
    */
    function distributeReward(
        address _rewardAddress, 
        uint256 _amountOfReward, 
        uint256 _timestampOfDistribution
    ) external nonReentrant onlyOwner whenNotPaused {
        
        require(_timestampOfDistribution > previousDistribution);
        require(_timestampOfDistribution < previousDistribution.add(durationBetweenRewardMints)); //To only allow a distribution to happen 30 days (2592000 seconds) after the previous distribution
        require(_timestampOfDistribution < now); // To only allow a distribution time in the past
        //reward[_rewardAddress] = reward[_rewardAddress].add(_amountOfReward);
        rewardMint(_rewardAddress, _amountOfReward);
        
    }

    /**
    * @dev reset reward tokensfor the new duration
    */
    function resetReward() external nonReentrant onlyOwner whenNotPaused {
        require(now > previousDistribution.add(durationBetweenRewardMints)); //To only allow a distribution to happen 30 days (2592000 seconds) after the previous distribution
        previousDistribution = previousDistribution.add(durationBetweenRewardMints); // To set the new distribution period as the previous distribution timestamp
        rewardAvailableCurrentDistribution = amountMintPerDuration;
        emit ResetReward();
    }

    /**
   * @dev Redeem Reward tokens from one rewards array to balances array
   * @param _beneficiary address The address which contains the reward as well as the address to which the balance will be transferred
   * @param _value uint256 the amount of tokens to be redeemed
   */
    function redeemReward(
        address _beneficiary, 
        uint256 _value
    ) external nonReentrant whenNotPaused{
        //Need to consider what happens to rewards after the stopping of minting process
        require(msg.sender == _beneficiary);
        require(_value >= minimumRewardWithdrawalLimit);
        require(reward[_beneficiary] >= _value);
        reward[_beneficiary] = reward[_beneficiary].sub(_value);
        balances[_beneficiary] = balances[_beneficiary].add(_value);
        totalRewardsRedeemed = totalRewardsRedeemed.add(_value);
        emit RedeemReward(_beneficiary, _value);
    }

    function rewardMint(
        address _to, 
        uint256 _amount
    ) onlyOwner canMint whenNotPaused internal returns (bool) {
        require(_amount > 0);
        require(_to != address(0));
        require(rewardAvailableCurrentDistribution >= _amount);
        totalSupply_ = totalSupply_.add(_amount);
        reward[_to] = reward[_to].add(_amount);
        totalRewardsDistributed = totalRewardsDistributed.add(_amount);
        rewardAvailableCurrentDistribution = rewardAvailableCurrentDistribution.sub(_amount);
        emit RewardMint(_to, _amount);
        //Transfer(address(0), _to, _amount); //balance of the user will only be updated on claiming the coin
        return true;
    }
    function userRewardAccountBalance(
        address _address
    ) whenNotPaused external view returns (uint256) {
        require(_address != address(0));
        return reward[_address];
    }
    function changeRewardMintingAmount(
        uint256 _newRewardMintAmt
    ) whenNotPaused nonReentrant onlyOwner external {
        require(_newRewardMintAmt < amountMintPerDuration);
        amountMintPerDuration = _newRewardMintAmt;
        emit RewardMintingAmt(_newRewardMintAmt);
    }

    function transferFrom(address _from, address _to, uint256 _value) external nonReentrant returns (bool) {
        return transferFromInternal(_from, _to, _value);
    }
    function approve(address _spender, uint256 _value) external nonReentrant returns (bool) {
        return approveInternal(_spender, _value);
    }
    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowanceInternal(_owner, _spender);
    }
    function increaseApproval(address _spender, uint _addedValue) external nonReentrant returns (bool) {
        return increaseApprovalInternal(_spender, _addedValue);
    }
    function decreaseApproval(address _spender, uint _subtractedValue) external nonReentrant returns (bool) {
        return decreaseApprovalInternal(_spender, _subtractedValue);
    }
    function transfer(address _to, uint256 _value) external nonReentrant returns (bool) {
        return transferInternal(_to, _value);
    } 
}

// File: contracts/Crowdsale.sol

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale {
    using SafeMath for uint256;
    IiinoCoin public token;
    address public iiinoTokenAddress;
    uint256 public startTime;
    uint256 public endTime;

  // address where funds are collected
    address public wallet;

  // how many token units a buyer gets per wei
    uint256 public rate;

  // amount of raised money in wei
    uint256 public weiRaised;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


    function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
        //require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_rate > 0);
        require(_wallet != address(0));

        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
    }

    // fallback function can be used to buy tokens
    function () external payable {
        buyTokensInternal(msg.sender);
    }

    function buyTokensInternal(address beneficiary) internal {
        require(beneficiary != address(0));
        require(validPurchase());
        require(msg.value >= (0.01 ether));

        uint256 weiAmount = msg.value;
        uint256 tokens = getTokenAmount(weiAmount);
        weiRaised = weiRaised.add(weiAmount);
        token.mint(beneficiary, tokens);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
        forwardFunds();
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }

    function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
        return weiAmount.mul(rate);
    }

    // send ether to the fund collection wallet
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

}

// File: contracts/IiinoCoinCrowdsale.sol

contract IiinoCoinCrowdsale is Crowdsale, Pausable, ReentrancyGuard {
    event ReferralAwarded(address indexed purchaser, address indexed referrer, uint256 iiinoPurchased, uint256 iiinoAwarded);

    using SafeMath for uint256;
    
    address devWallet;
    uint256 noOfTokenAlocatedForDev;
    uint256 public noOfTokenAlocatedForSeedRound;
    uint256 public noOfTokenAlocatedForPresaleRound;
    uint256 public totalNoOfTokenAlocated;
    uint256 public noOfTokenAlocatedPerICOPhase; //The token allocation for each phase of the ICO
    uint256 public noOfICOPhases; //No. of ICO phases
    uint256 public seedRoundEndTime; // to be in seconds
    uint256 public thresholdEtherLimitForSeedRound; //minimum amount of wei needed to participate
    uint256 public moreTokenPerEtherForSeedRound; // the more amount of Iiinos given per ether during seed round
    uint256 public moreTokenPerEtherForPresaleRound; //the more amount of Iiinos given per ether during presale round
    
    uint256 public referralTokensAvailable; //To hold the value of the referral token limit.
    uint256 public referralPercent; //The percentage of referral to be awarded on each order with a referrer
    uint256 public referralTokensAllocated; // To hold the total number of token allocated to referrals

    uint256 public presaleEndTime; // to be in seconds
    uint256 public issueRateDecDuringICO; //The number of iiino that needs to be decreased for every next phase of the ICO 
    //uint256 public percentToMintPerDuration; //The percentage of Genesis ICO that will be minted every minting cycle
    //uint256 public durationBetweenRewardMints; //The length of a reward minting cycle
    

    function IiinoCoinCrowdsale(
        uint256[] _params, // All the params that need to initialize the crowdsale as well as the iiino Token
        address _wallet, 
        address _devTeamWallet,
        address _iiinoTokenAddress
    ) public Crowdsale(_params[0], _params[1], _params[4], _wallet) {
        devWallet = _devTeamWallet;
        issueRateDecDuringICO = _params[5];
        seedRoundEndTime = _params[2];
        presaleEndTime = _params[3];
          
        moreTokenPerEtherForSeedRound = _params[13];
        moreTokenPerEtherForPresaleRound = _params[14];
          
        referralTokensAvailable = _params[15];
        referralTokensAllocated = _params[15]; //Initially all the allocated tokens are available
        referralPercent = _params[16];

        noOfTokenAlocatedForDev = _params[6];
        noOfTokenAlocatedForSeedRound = _params[7];
        noOfTokenAlocatedForPresaleRound = _params[8];
        totalNoOfTokenAlocated = _params[10];
        noOfTokenAlocatedPerICOPhase = _params[9];
        noOfICOPhases = _params[11];
        thresholdEtherLimitForSeedRound = _params[12];

        //Neeed to test the total allocation with the sum of all allocations.
        //token.transferOwnership(msg.sender);

        //token.mint(_devTeamWallet, noOfTokenAlocatedForDev);
        //iiinoTokenAddress = _iiinoTokenAddress;
        token = IiinoCoin(_iiinoTokenAddress);
    }

    function initialTransferToDevTeam() nonReentrant onlyOwner whenNotPaused external {
        require(devWallet != address(0));
        //To assign the initial dev tokens to the dev wallet
        token.mint(devWallet, noOfTokenAlocatedForDev);
        //Sets the devTeamWallet to 0x00, to restrict future transfers
        devWallet = address(0);
    }

    /*
    //Temp Function to retreive values
    function tempGetDataToCheck (uint indx, uint256 weiAmt) public view returns (uint256) {
      //string temp = "thresholdEtherLimitForSeedRound =>" + thresholdEtherLimitForSeedRound + "Total Supply => " + token.totalSupply() + "noOfTokenAlocatedForSeedRound => " + noOfTokenAlocatedForSeedRound + "noOfTokenAlocatedForDev => " + noOfTokenAlocatedForDev + "rate => " + rate;
        if (indx == 0)
          return issueRateDecDuringICO;
        else if (indx == 1)
          return seedRoundEndTime;
        else if (indx == 2)
          return presaleEndTime;
        else if (indx == 3)
          return moreTokenPerEtherForSeedRound;
        else if (indx == 4)
          return moreTokenPerEtherForPresaleRound;
        else if (indx == 5)
          return noOfTokenAlocatedForDev;
        else if (indx == 6)
          return noOfTokenAlocatedForSeedRound;
        else if (indx == 61)
          return noOfTokenAlocatedForPresaleRound;
        else if (indx == 7)
          return totalNoOfTokenAlocated;
        else if (indx == 8)
          return noOfTokenAlocatedPerICOPhase;
        else if (indx == 9)
          return noOfICOPhases;
        else if (indx == 10)
          return thresholdEtherLimitForSeedRound;
        else if (indx == 11)
          return 0;//percentToMintPerDuration;
        else if (indx == 12)
        {
            uint currentRate;
            uint256 icoMultiplier;
            (currentRate, icoMultiplier) = getCurrentRateInternal();
            return currentRate;//durationBetweenRewardMints;
        }  
        else if (indx == 13)
          return token.totalSupply();
        else if (indx == 14)
          return getTokenAmount(weiAmt);
        else if (indx == 15)
          return now;
        else if (indx == 16)
          return startTime;
        else if (indx == 17)
          return endTime;
        
    }
    */
    function getTokenAmount (uint256 weiAmount) whenNotPaused internal view returns (uint256) {
        uint currRate;
        uint256 multiplierForICO;
        uint256 amountOfIiino = 0;
        uint256 referralsDistributed = referralTokensAllocated.sub(referralTokensAvailable);
        uint256 _totalSupply = (token.totalSupply()).sub(referralsDistributed);
        if (now <= seedRoundEndTime) {
          
            require(weiAmount >= thresholdEtherLimitForSeedRound);
            require(_totalSupply < noOfTokenAlocatedForSeedRound.add(noOfTokenAlocatedForDev));
            (currRate, multiplierForICO) = getCurrentRateInternal();
            
            amountOfIiino = weiAmount.mul(currRate);
            
            //Only if there is enough available amount of iiino in the phase will it allocate it, else it will just revert the transaction and return the ether 
            require (_totalSupply.add(amountOfIiino) <= noOfTokenAlocatedForSeedRound.add(noOfTokenAlocatedForDev));
            return amountOfIiino;

        } else if (now <= presaleEndTime) {
            require(_totalSupply < noOfTokenAlocatedForSeedRound.add(noOfTokenAlocatedForPresaleRound).add(noOfTokenAlocatedForDev));
            (currRate, multiplierForICO) = getCurrentRateInternal();
            
            amountOfIiino = weiAmount.mul(currRate);
            //Only if there is enough available amount of iiino in the phase will it allocate it, else it will just revert the transaction and return the ether 
            require (_totalSupply.add(amountOfIiino) <= noOfTokenAlocatedForSeedRound.add(noOfTokenAlocatedForPresaleRound).add(noOfTokenAlocatedForDev));
            return amountOfIiino;
        } else {
            
           
            require(_totalSupply < noOfTokenAlocatedForSeedRound.add(noOfTokenAlocatedForPresaleRound).add(noOfTokenAlocatedForDev));
            require(now < endTime);
            
            (currRate,multiplierForICO) = getCurrentRateInternal();
            //To check if the amount of tokens for the current ICO phase is exhausted
            //uint256 a = 1;
            //amountOfIiino = (weiAmount.mul(currRate)).div(a);
            
            amountOfIiino = weiAmount * currRate;
            
            require(_totalSupply.add(amountOfIiino) <= noOfTokenAlocatedForSeedRound.add(noOfTokenAlocatedForPresaleRound).add(noOfTokenAlocatedForDev).add(noOfTokenAlocatedPerICOPhase.mul(multiplierForICO.add(1))));
            return amountOfIiino;
          
        }
      
    }

  //function getCurrentRate returns the amount of iii for the amount of wei at the current point in time (now)
    function getCurrentRateInternal() whenNotPaused internal view returns (uint,uint256) {
        uint currRate;
        uint256 multiplierForICO = 0; 

        if (now <= seedRoundEndTime) {
            currRate = rate.add(moreTokenPerEtherForSeedRound);
        } else if (now <= presaleEndTime) {
            currRate = rate.add(moreTokenPerEtherForPresaleRound);
        } else {
            multiplierForICO = (now.sub(presaleEndTime)).div(30 days); //86400 seconds in a day
            currRate = rate.sub((issueRateDecDuringICO.mul(multiplierForICO)));
            require(multiplierForICO < noOfICOPhases);
        }
        return (currRate,multiplierForICO);
    }
    
    function buyTokensWithReferrer(address referrer) nonReentrant whenNotPaused external payable {
        address beneficiary = msg.sender;
        require(referrer != address(0));
        require(beneficiary != address(0));
        require(validPurchase());
        require(msg.value >= (0.01 ether));

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = getTokenAmount(weiAmount);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        //To send the referrer his percentage of tokens.
        uint256 referrerTokens = tokens.mul(referralPercent).div(100);
        if (referralTokensAvailable > 0) {
            if (referrerTokens > referralTokensAvailable) {
                referrerTokens = referralTokensAvailable;
            }
            
            token.mint(referrer, referrerTokens);
            referralTokensAvailable = referralTokensAvailable.sub(referrerTokens);
            emit ReferralAwarded(msg.sender, referrer, tokens, referrerTokens);

        }
        
        forwardFunds();

    }

    function getCurrentRate() whenNotPaused external view returns (uint,uint256) {
        return getCurrentRateInternal ();
    }

    function buyTokens(address beneficiary) nonReentrant whenNotPaused external payable {
        buyTokensInternal(beneficiary);
    }

    function forwardFunds() whenNotPaused internal {
        super.forwardFunds();
    }

}