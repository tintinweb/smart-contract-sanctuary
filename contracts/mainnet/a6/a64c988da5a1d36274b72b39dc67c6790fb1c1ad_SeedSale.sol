pragma solidity ^0.4.20;


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
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

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


contract ufoodoToken is StandardToken, Ownable {
    using SafeMath for uint256;

    // Token where will be stored and managed
    address public vault = this;

    string public name = "ufoodo Token";
    string public symbol = "UFT";
    uint8 public decimals = 18;

    // Total Supply DAICO: 500,000,000 UFT
    uint256 public INITIAL_SUPPLY = 500000000 * (10**uint256(decimals));
    // 400,000,000 UFT for DAICO at Q4 2018
    uint256 public supplyDAICO = INITIAL_SUPPLY.mul(80).div(100);

    address public salesAgent;
    mapping (address => bool) public owners;

    event SalesAgentPermissionsTransferred(address indexed previousSalesAgent, address indexed newSalesAgent);
    event SalesAgentRemoved(address indexed currentSalesAgent);

    // 100,000,000 Seed UFT
    function supplySeed() public view returns (uint256) {
        uint256 _supplySeed = INITIAL_SUPPLY.mul(20).div(100);
        return _supplySeed;
    }
    // Constructor
    function ufoodoToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
    // Transfer sales agent permissions to another account
    function transferSalesAgentPermissions(address _salesAgent) onlyOwner public {
        emit SalesAgentPermissionsTransferred(salesAgent, _salesAgent);
        salesAgent = _salesAgent;
    }

    // Remove sales agent from token
    function removeSalesAgent() onlyOwner public {
        emit SalesAgentRemoved(salesAgent);
        salesAgent = address(0);
    }

    function transferFromVault(address _from, address _to, uint256 _amount) public {
        require(salesAgent == msg.sender);
        balances[vault] = balances[vault].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
    }

    // Lock the DAICO supply until 2018-09-01 14:00:00
    // Which can then transferred to the created DAICO contract
    function transferDaico(address _to) public onlyOwner returns(bool) {
        require(now >= 1535810400);

        balances[vault] = balances[vault].sub(supplyDAICO);
        balances[_to] = balances[_to].add(supplyDAICO);
        emit Transfer(vault, _to, supplyDAICO);
        return(true);
    }

}

contract SeedSale is Ownable, Pausable {
    using SafeMath for uint256;

    // Tokens that will be sold
    ufoodoToken public token;

    // Time in Unix timestamp
    // Start: 01-Apr-18 14:00:00 UTC
    uint256 public constant seedStartTime = 1522591200;
    // End: 31-May-18 14:00:00 UTC
    uint256 public constant seedEndTime = 1527775200;

    uint256 public seedSupply_ = 0;

    // Update all funds raised that are not validated yet, 140 ether from private sale already added
    uint256 public fundsRaised = 140 ether;

    // Update only funds validated, 140 ether from private sale already added
    uint256 public fundsRaisedFinalized = 140 ether; //

    // Lock tokens for team
    uint256 public releasedLockedAmount = 0;

    // All pending UFT which needs to validated before transfered to contributors
    uint256 public pendingUFT = 0;
    // Conclude UFT which are transferred to contributer if soft cap reached and contributor is validated
    uint256 public concludeUFT = 0;

    uint256 public constant softCap = 200 ether;
    uint256 public constant hardCap = 3550 ether;
    uint256 public constant minContrib = 0.1 ether;

    uint256 public lockedTeamUFT = 0;
    uint256 public privateReservedUFT = 0;

    // Will updated in condition with funds raised finalized
    bool public SoftCapReached = false;
    bool public hardCapReached = false;
    bool public seedSaleFinished = false;

    //Refund will enabled if seed sale End and min cap not reached
    bool public refundAllowed = false;

    // Address where only validated funds will be transfered
    address public fundWallet = 0xf7d4C80DE0e2978A1C5ef3267F488B28499cD22E;

    // Amount of ether in wei, needs to be validated first
    mapping(address => uint256) public weiContributedPending;
    // Amount of ether in wei validated
    mapping(address => uint256) public weiContributedConclude;
    // Amount of UFT which will reserved first until the contributor is validated
    mapping(address => uint256) public pendingAmountUFT;

    event OpenTier(uint256 activeTier);
    event LogContributionPending(address contributor, uint256 amountWei, uint256 tokenAmount, uint256 activeTier, uint256 timestamp);
    event LogContributionConclude(address contributor, uint256 amountWei, uint256 tokenAmount, uint256 timeStamp);
    event ValidationFailed(address contributor, uint256 amountWeiRefunded, uint timestamp);

    // Initialized Tier
    uint public activeTier = 0;

    // Max ether per tier to collect
    uint256[8] public tierCap = [
        400 ether,
        420 ether,
        380 ether,
        400 ether,
        410 ether,
        440 ether,
        460 ether,
        500 ether
    ];

    // Based on 1 Ether = 12500
    // Tokenrate + tokenBonus = totalAmount the contributor received
    uint256[8] public tierTokens = [
        17500, //40%
        16875, //35%
        16250, //30%
        15625, //25%
        15000, //20%
        13750, //10%
        13125, //5%
        12500  //0%
    ];

    // Will be updated due wei contribution
    uint256[8] public activeFundRaisedTier = [
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    ];

    // Constructor
    function SeedSale(address _vault) public {
        token = ufoodoToken(_vault);
        privateReservedUFT = token.supplySeed().mul(4).div(100);
        lockedTeamUFT = token.supplySeed().mul(20).div(100);
        seedSupply_ = token.supplySeed();
    }

    function seedStarted() public view returns (bool) {
        return now >= seedStartTime;
    }

    function seedEnded() public view returns (bool) {
        return now >= seedEndTime || fundsRaised >= hardCap;
    }

    modifier checkContribution() {
        require(canContribute());
        _;
    }

    function canContribute() internal view returns(bool) {
        if(!seedStarted() || seedEnded()) {
            return false;
        }
        if(msg.value < minContrib) {
            return false;
        }
        return true;
    }

    // Fallback function
    function() payable public whenNotPaused {
        buyUFT(msg.sender);
    }

    // Process UFT contribution
    function buyUFT(address contributor) public whenNotPaused checkContribution payable {
        uint256 weiAmount = msg.value;
        uint256 refund = 0;
        uint256 _tierIndex = activeTier;
        uint256 _activeTierCap = tierCap[_tierIndex];
        uint256 _activeFundRaisedTier = activeFundRaisedTier[_tierIndex];

        require(_activeFundRaisedTier < _activeTierCap);

        // Checks Amoount of eth still can contributed to the active Tier
        uint256 tierCapOverSold = _activeTierCap.sub(_activeFundRaisedTier);

        // if contributer amount will oversold the active tier cap, partial
        // purchase will proceed, rest contributer amount will refunded to contributor
        if(tierCapOverSold < weiAmount) {
            weiAmount = tierCapOverSold;
            refund = msg.value.sub(weiAmount);

        }
        // Calculate the amount of tokens the Contributor will receive
        uint256 amountUFT = weiAmount.mul(tierTokens[_tierIndex]);

        // Update status
        fundsRaised = fundsRaised.add(weiAmount);
        activeFundRaisedTier[_tierIndex] = activeFundRaisedTier[_tierIndex].add(weiAmount);
        weiContributedPending[contributor] = weiContributedPending[contributor].add(weiAmount);
        pendingAmountUFT[contributor] = pendingAmountUFT[contributor].add(amountUFT);
        pendingUFT = pendingUFT.add(amountUFT);

        // partial process, refund rest value
        if(refund > 0) {
            msg.sender.transfer(refund);
        }

        emit LogContributionPending(contributor, weiAmount, amountUFT, _tierIndex, now);
    }

    function softCapReached() public returns (bool) {
        if (fundsRaisedFinalized >= softCap) {
            SoftCapReached = true;
            return true;
        }
        return false;
    }

    // Next Tier will increment manually and Paused by the team to guarantee safe transition
    // Initialized next tier if previous tier sold out
    // For contributor safety we pause the seedSale process
    function nextTier() onlyOwner public {
        require(paused == true);
        require(activeTier < 7);
        uint256 _tierIndex = activeTier;
        activeTier = _tierIndex +1;
        emit OpenTier(activeTier);
    }

    // Validation Update Process
    // After we finished the kyc process, we update each validated contributor and transfer if softCapReached the tokens
    // If the contributor is not validated due failed validation, the contributed wei amount will refundet back to the contributor
    function validationPassed(address contributor) onlyOwner public returns (bool) {
        require(contributor != 0x0);

        uint256 amountFinalized = pendingAmountUFT[contributor];
        pendingAmountUFT[contributor] = 0;
        token.transferFromVault(token, contributor, amountFinalized);

        // Update status
        uint256 _fundsRaisedFinalized = fundsRaisedFinalized.add(weiContributedPending[contributor]);
        fundsRaisedFinalized = _fundsRaisedFinalized;
        concludeUFT = concludeUFT.add(amountFinalized);

        weiContributedConclude[contributor] = weiContributedConclude[contributor].add(weiContributedPending[contributor]);

        emit LogContributionConclude(contributor, weiContributedPending[contributor], amountFinalized, now);
        softCapReached();
        // Amount finalized tokes update status

        return true;
    }

    // Update which address is not validated
    // By updating the address, the contributor will receive his contribution back
    function validationFailed(address contributor) onlyOwner public returns (bool) {
        require(contributor != 0x0);
        require(weiContributedPending[contributor] > 0);

        uint256 currentBalance = weiContributedPending[contributor];

        weiContributedPending[contributor] = 0;
        contributor.transfer(currentBalance);
        emit ValidationFailed(contributor, currentBalance, now);
        return true;
    }

    // If seed sale ends and soft cap is not reached, Contributer can claim their funds
    function refund() public {
        require(refundAllowed);
        require(!SoftCapReached);
        require(weiContributedPending[msg.sender] > 0);

        uint256 currentBalance = weiContributedPending[msg.sender];

        weiContributedPending[msg.sender] = 0;
        msg.sender.transfer(currentBalance);
    }


   // Allows only to refund the contributed amount that passed the validation and reached the softcap
    function withdrawFunds(uint256 _weiAmount) public onlyOwner {
        require(SoftCapReached);
        fundWallet.transfer(_weiAmount);
    }

    /*
     * If tokens left make a priveledge token sale for contributor that are already validated
     * make a new date time for left tokens only for priveledge whitelisted
     * If not enouhgt tokens left for a sale send directly to locked contract/ vault
     */
    function seedSaleTokenLeft(address _tokenContract) public onlyOwner {
        require(seedEnded());
        uint256 amountLeft = pendingUFT.sub(concludeUFT);
        token.transferFromVault(token, _tokenContract, amountLeft );
    }


    function vestingToken(address _beneficiary) public onlyOwner returns (bool) {
      require(SoftCapReached);
      uint256 release_1 = seedStartTime.add(180 days);
      uint256 release_2 = release_1.add(180 days);
      uint256 release_3 = release_2.add(180 days);
      uint256 release_4 = release_3.add(180 days);

      //20,000,000 UFT total splitted in 4 time periods
      uint256 lockedAmount_1 = lockedTeamUFT.mul(25).div(100);
      uint256 lockedAmount_2 = lockedTeamUFT.mul(25).div(100);
      uint256 lockedAmount_3 = lockedTeamUFT.mul(25).div(100);
      uint256 lockedAmount_4 = lockedTeamUFT.mul(25).div(100);

      if(seedStartTime >= release_1 && releasedLockedAmount < lockedAmount_1) {
        token.transferFromVault(token, _beneficiary, lockedAmount_1 );
        releasedLockedAmount = releasedLockedAmount.add(lockedAmount_1);
        return true;

      } else if(seedStartTime >= release_2 && releasedLockedAmount < lockedAmount_2.mul(2)) {
        token.transferFromVault(token, _beneficiary, lockedAmount_2 );
        releasedLockedAmount = releasedLockedAmount.add(lockedAmount_2);
        return true;

      } else if(seedStartTime >= release_3 && releasedLockedAmount < lockedAmount_3.mul(3)) {
        token.transferFromVault(token, _beneficiary, lockedAmount_3 );
        releasedLockedAmount = releasedLockedAmount.add(lockedAmount_3);
        return true;

      } else if(seedStartTime >= release_4 && releasedLockedAmount < lockedAmount_4.mul(4)) {
        token.transferFromVault(token, _beneficiary, lockedAmount_4 );
        releasedLockedAmount = releasedLockedAmount.add(lockedAmount_4);
        return true;
      }

    }

    // Total Reserved from Private Sale Contributor 4,000,000 UFT
    function transferPrivateReservedUFT(address _beneficiary, uint256 _amount) public onlyOwner {
        require(SoftCapReached);
        require(_amount > 0);
        require(privateReservedUFT >= _amount);

        token.transferFromVault(token, _beneficiary, _amount);
        privateReservedUFT = privateReservedUFT.sub(_amount);

    }

     function finalizeSeedSale() public onlyOwner {
        if(seedStartTime >= seedEndTime && SoftCapReached) {

        // Bounty Campaign: 5,000,000 UFT
        uint256 bountyAmountUFT = token.supplySeed().mul(5).div(100);
        token.transferFromVault(token, fundWallet, bountyAmountUFT);

        // Reserved Company: 20,000,000 UFT
        uint256 reservedCompanyUFT = token.supplySeed().mul(20).div(100);
        token.transferFromVault(token, fundWallet, reservedCompanyUFT);

        } else if(seedStartTime >= seedEndTime && !SoftCapReached) {

            // Enable fund`s crowdsale refund if soft cap is not reached
            refundAllowed = true;

            token.transferFromVault(token, owner, seedSupply_);
            seedSupply_ = 0;

        }
    }

}