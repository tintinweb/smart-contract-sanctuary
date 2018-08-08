pragma solidity ^0.4.13;

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


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



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
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
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
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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

contract AbstractStarbaseCrowdsale {
    function startDate() constant returns (uint256) {}
    function endedAt() constant returns (uint256) {}
    function isEnded() constant returns (bool);
    function totalRaisedAmountInCny() constant returns (uint256);
    function numOfPurchasedTokensOnCsBy(address purchaser) constant returns (uint256);
    function numOfPurchasedTokensOnEpBy(address purchaser) constant returns (uint256);
}

contract AbstractStarbaseMarketingCampaign {}

/// @title Token contract - ERC20 compatible Starbase token contract.
/// @author Starbase PTE. LTD. - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="462f282029063532273424273523682529">[email&#160;protected]</a>>
contract StarbaseToken is StandardToken {
    /*
     *  Events
     */
    event PublicOfferingPlanDeclared(uint256 tokenCount, uint256 unlockCompanysTokensAt);
    event MvpLaunched(uint256 launchedAt);
    event LogNewFundraiser (address indexed fundraiserAddress, bool isBonaFide);
    event LogUpdateFundraiser(address indexed fundraiserAddress, bool isBonaFide);

    /*
     *  Types
     */
    struct PublicOfferingPlan {
        uint256 tokenCount;
        uint256 unlockCompanysTokensAt;
        uint256 declaredAt;
    }

    /*
     *  External contracts
     */
    AbstractStarbaseCrowdsale public starbaseCrowdsale;
    AbstractStarbaseMarketingCampaign public starbaseMarketingCampaign;

    /*
     *  Storage
     */
    address public company;
    PublicOfferingPlan[] public publicOfferingPlans;  // further crowdsales
    mapping(address => uint256) public initialEcTokenAllocation;    // Initial token allocations for Early Contributors
    uint256 public mvpLaunchedAt;  // 0 until a MVP of Starbase Platform launches
    mapping(address => bool) private fundraisers; // Fundraisers are vetted addresses that are allowed to execute functions within the contract

    /*
     *  Constants / Token meta data
     */
    string constant public name = "Starbase";  // Token name
    string constant public symbol = "STAR";  // Token symbol
    uint8 constant public decimals = 18;
    uint256 constant public initialSupply = 1000000000e18; // 1B STAR tokens
    uint256 constant public initialCompanysTokenAllocation = 750000000e18;  // 750M
    uint256 constant public initialBalanceForCrowdsale = 175000000e18;  // CS(125M)+EP(50M)
    uint256 constant public initialBalanceForMarketingCampaign = 12500000e18;   // 12.5M

    /*
     *  Modifiers
     */
    modifier onlyCrowdsaleContract() {
        assert(msg.sender == address(starbaseCrowdsale));
        _;
    }

    modifier onlyMarketingCampaignContract() {
        assert(msg.sender == address(starbaseMarketingCampaign));
        _;
    }

    modifier onlyFundraiser() {
        // Only rightful fundraiser is permitted.
        assert(isFundraiser(msg.sender));
        _;
    }

    modifier onlyBeforeCrowdsale() {
        require(starbaseCrowdsale.startDate() == 0);
        _;
    }

    modifier onlyAfterCrowdsale() {
        require(starbaseCrowdsale.isEnded());
        _;
    }

    /*
     *  Contract functions
     */

    /**
     * @dev Contract constructor function
     * @param starbaseCompanyAddr The address that will holds untransferrable tokens
     * @param starbaseCrowdsaleAddr Address of the crowdsale contract
     * @param starbaseMarketingCampaignAddr The address of the marketing campaign contract
     */

    function StarbaseToken(
        address starbaseCompanyAddr,
        address starbaseCrowdsaleAddr,
        address starbaseMarketingCampaignAddr
    ) {
        assert(
            starbaseCompanyAddr != 0 &&
            starbaseCrowdsaleAddr != 0 &&
            starbaseMarketingCampaignAddr != 0);

        starbaseCrowdsale = AbstractStarbaseCrowdsale(starbaseCrowdsaleAddr);
        starbaseMarketingCampaign = AbstractStarbaseMarketingCampaign(starbaseMarketingCampaignAddr);
        company = starbaseCompanyAddr;

        // msg.sender becomes first fundraiser
        fundraisers[msg.sender] = true;
        LogNewFundraiser(msg.sender, true);

        // Tokens for crowdsale and early purchasers
        balances[address(starbaseCrowdsale)] = initialBalanceForCrowdsale;

        // Tokens for marketing campaign supporters
        balances[address(starbaseMarketingCampaign)] = initialBalanceForMarketingCampaign;

        // Tokens for early contributors, should be allocated by function
        balances[0] = 62500000e18; // 62.5M

        // Starbase company holds untransferrable tokens initially
        balances[starbaseCompanyAddr] = initialCompanysTokenAllocation; // 750M

        totalSupply = initialSupply;    // 1B
    }

    /**
     * @dev Setup function sets external contracts&#39; addresses
     * @param starbaseCrowdsaleAddr Crowdsale contract address.
     * @param starbaseMarketingCampaignAddr Marketing campaign contract address
     */
    function setup(address starbaseCrowdsaleAddr, address starbaseMarketingCampaignAddr)
        external
        onlyFundraiser
        onlyBeforeCrowdsale
        returns (bool)
    {
        require(starbaseCrowdsaleAddr != 0 && starbaseMarketingCampaignAddr != 0);
        assert(balances[address(starbaseCrowdsale)] == initialBalanceForCrowdsale);
        assert(balances[address(starbaseMarketingCampaign)] == initialBalanceForMarketingCampaign);

        // Move the balances to the new ones
        balances[address(starbaseCrowdsale)] = 0;
        balances[address(starbaseMarketingCampaign)] = 0;
        balances[starbaseCrowdsaleAddr] = initialBalanceForCrowdsale;
        balances[starbaseMarketingCampaignAddr] = initialBalanceForMarketingCampaign;

        // Update the references
        starbaseCrowdsale = AbstractStarbaseCrowdsale(starbaseCrowdsaleAddr);
        starbaseMarketingCampaign = AbstractStarbaseMarketingCampaign(starbaseMarketingCampaignAddr);
        return true;
    }

    /*
     *  External functions
     */

    /**
     * @dev Returns number of declared public offering plans
     */
    function numOfDeclaredPublicOfferingPlans()
        external
        constant
        returns (uint256)
    {
        return publicOfferingPlans.length;
    }

    /**
     * @dev Declares a public offering plan to make company&#39;s tokens transferable
     * @param tokenCount Number of tokens to transfer.
     * @param unlockCompanysTokensAt Time of the tokens will be unlocked
     */
    function declarePublicOfferingPlan(uint256 tokenCount, uint256 unlockCompanysTokensAt)
        external
        onlyFundraiser
        onlyAfterCrowdsale
        returns (bool)
    {
        assert(tokenCount <= 100000000e18);    // shall not exceed 100M tokens
        assert(SafeMath.sub(now, starbaseCrowdsale.endedAt()) >= 180 days);   // shall not be declared for 6 months after the crowdsale ended
        assert(SafeMath.sub(unlockCompanysTokensAt, now) >= 60 days);   // tokens must be untransferable at least for 2 months

        // check if last declaration was more than 6 months ago
        if (publicOfferingPlans.length > 0) {
            uint256 lastDeclaredAt =
                publicOfferingPlans[publicOfferingPlans.length - 1].declaredAt;
            assert(SafeMath.sub(now, lastDeclaredAt) >= 180 days);
        }

        uint256 totalDeclaredTokenCount = tokenCount;
        for (uint8 i; i < publicOfferingPlans.length; i++) {
            totalDeclaredTokenCount = SafeMath.add(totalDeclaredTokenCount, publicOfferingPlans[i].tokenCount);
        }
        assert(totalDeclaredTokenCount <= initialCompanysTokenAllocation);   // shall not exceed the initial token allocation

        publicOfferingPlans.push(
            PublicOfferingPlan(tokenCount, unlockCompanysTokensAt, now));

        PublicOfferingPlanDeclared(tokenCount, unlockCompanysTokensAt);
    }

    /**
     * @dev Allocate tokens to a marketing supporter from the marketing campaign share
     * @param to Address to where tokens are allocated
     * @param value Number of tokens to transfer
     */
    function allocateToMarketingSupporter(address to, uint256 value)
        external
        onlyMarketingCampaignContract
        returns (bool)
    {
        return allocateFrom(address(starbaseMarketingCampaign), to, value);
    }

    /**
     * @dev Allocate tokens to an early contributor from the early contributor share
     * @param to Address to where tokens are allocated
     * @param value Number of tokens to transfer
     */
    function allocateToEarlyContributor(address to, uint256 value)
        external
        onlyFundraiser
        returns (bool)
    {
        initialEcTokenAllocation[to] =
            SafeMath.add(initialEcTokenAllocation[to], value);
        return allocateFrom(0, to, value);
    }

    /**
     * @dev Issue new tokens according to the STAR token inflation limits
     * @param _for Address to where tokens are allocated
     * @param value Number of tokens to issue
     */
    function issueTokens(address _for, uint256 value)
        external
        onlyFundraiser
        onlyAfterCrowdsale
        returns (bool)
    {
        // check if the value under the limits
        assert(value <= numOfInflatableTokens());

        totalSupply = SafeMath.add(totalSupply, value);
        balances[_for] = SafeMath.add(balances[_for], value);
        return true;
    }

    /**
     * @dev Declares Starbase MVP has been launched
     * @param launchedAt When the MVP launched (timestamp)
     */
    function declareMvpLaunched(uint256 launchedAt)
        external
        onlyFundraiser
        onlyAfterCrowdsale
        returns (bool)
    {
        require(mvpLaunchedAt == 0); // overwriting the launch date is not permitted
        require(launchedAt <= now);
        require(starbaseCrowdsale.isEnded());

        mvpLaunchedAt = launchedAt;
        MvpLaunched(launchedAt);
        return true;
    }

    /**
     * @dev Allocate tokens to a crowdsale or early purchaser from the crowdsale share
     * @param to Address to where tokens are allocated
     * @param value Number of tokens to transfer
     */
    function allocateToCrowdsalePurchaser(address to, uint256 value)
        external
        onlyCrowdsaleContract
        onlyAfterCrowdsale
        returns (bool)
    {
        return allocateFrom(address(starbaseCrowdsale), to, value);
    }

    /*
     *  Public functions
     */

    /**
     * @dev Transfers sender&#39;s tokens to a given address. Returns success.
     * @param to Address of token receiver.
     * @param value Number of tokens to transfer.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        assert(isTransferable(msg.sender, value));
        return super.transfer(to, value);
    }

    /**
     * @dev Allows third party to transfer tokens from one address to another. Returns success.
     * @param from Address from where tokens are withdrawn.
     * @param to Address to where tokens are sent.
     * @param value Number of tokens to transfer.
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        assert(isTransferable(from, value));
        return super.transferFrom(from, to, value);
    }

    /**
     * @dev Adds fundraiser. Only called by another fundraiser.
     * @param fundraiserAddress The address in check
     */
    function addFundraiser(address fundraiserAddress) public onlyFundraiser {
        assert(!isFundraiser(fundraiserAddress));

        fundraisers[fundraiserAddress] = true;
        LogNewFundraiser(fundraiserAddress, true);
    }

    /**
     * @dev Update fundraiser address rights.
     * @param fundraiserAddress The address to update
     * @param isBonaFide Boolean that denotes whether fundraiser is active or not.
     */
    function updateFundraiser(address fundraiserAddress, bool isBonaFide)
       public
       onlyFundraiser
       returns(bool)
    {
        assert(isFundraiser(fundraiserAddress));

        fundraisers[fundraiserAddress] = isBonaFide;
        LogUpdateFundraiser(fundraiserAddress, isBonaFide);
        return true;
    }

    /**
     * @dev Returns whether fundraiser address has rights.
     * @param fundraiserAddress The address in check
     */
    function isFundraiser(address fundraiserAddress) constant public returns(bool) {
        return fundraisers[fundraiserAddress];
    }

    /**
     * @dev Returns whether the transferring of tokens is available fundraiser.
     * @param from Address of token sender
     * @param tokenCount Number of tokens to transfer.
     */
    function isTransferable(address from, uint256 tokenCount)
        constant
        public
        returns (bool)
    {
        if (tokenCount == 0 || balances[from] < tokenCount) {
            return false;
        }

        // company&#39;s tokens may be locked up
        if (from == company) {
            if (tokenCount > numOfTransferableCompanysTokens()) {
                return false;
            }
        }

        uint256 untransferableTokenCount = 0;

        // early contributor&#39;s tokens may be locked up
        if (initialEcTokenAllocation[from] > 0) {
            untransferableTokenCount = SafeMath.add(
                untransferableTokenCount,
                numOfUntransferableEcTokens(from));
        }

        // EP and CS purchasers&#39; tokens should be untransferable initially
        if (starbaseCrowdsale.isEnded()) {
            uint256 passedDays =
                SafeMath.sub(now, starbaseCrowdsale.endedAt()) / 86400; // 1d = 86400s
            if (passedDays < 7) {  // within a week
                // crowdsale purchasers cannot transfer their tokens for a week
                untransferableTokenCount = SafeMath.add(
                    untransferableTokenCount,
                    starbaseCrowdsale.numOfPurchasedTokensOnCsBy(from));
            }
            if (passedDays < 14) {  // within two weeks
                // early purchasers cannot transfer their tokens for two weeks
                untransferableTokenCount = SafeMath.add(
                    untransferableTokenCount,
                    starbaseCrowdsale.numOfPurchasedTokensOnEpBy(from));
            }
        }

        uint256 transferableTokenCount =
            SafeMath.sub(balances[from], untransferableTokenCount);

        if (transferableTokenCount < tokenCount) {
            return false;
        } else {
            return true;
        }
    }

    /**
     * @dev Returns the number of transferable company&#39;s tokens
     */
    function numOfTransferableCompanysTokens() constant public returns (uint256) {
        uint256 unlockedTokens = 0;
        for (uint8 i; i < publicOfferingPlans.length; i++) {
            PublicOfferingPlan memory plan = publicOfferingPlans[i];
            if (plan.unlockCompanysTokensAt <= now) {
                unlockedTokens = SafeMath.add(unlockedTokens, plan.tokenCount);
            }
        }
        return SafeMath.sub(
            balances[company],
            initialCompanysTokenAllocation - unlockedTokens);
    }

    /**
     * @dev Returns the number of untransferable tokens of the early contributor
     * @param _for Address of early contributor to check
     */
    function numOfUntransferableEcTokens(address _for) constant public returns (uint256) {
        uint256 initialCount = initialEcTokenAllocation[_for];
        if (mvpLaunchedAt == 0) {
            return initialCount;
        }

        uint256 passedWeeks = SafeMath.sub(now, mvpLaunchedAt) / 7 days;
        if (passedWeeks <= 52) {    // a year ≈ 52 weeks
            // all tokens should be locked up for a year
            return initialCount;
        }

        // unlock 1/52 tokens every weeks after a year
        uint256 transferableTokenCount = initialCount / 52 * (passedWeeks - 52);
        if (transferableTokenCount >= initialCount) {
            return 0;
        } else {
            return SafeMath.sub(initialCount, transferableTokenCount);
        }
    }

    /**
     * @dev Returns number of tokens which can be issued according to the inflation rules
     */
    function numOfInflatableTokens() constant public returns (uint256) {
        if (starbaseCrowdsale.endedAt() == 0) {
            return 0;
        }
        uint256 passedDays = SafeMath.sub(now, starbaseCrowdsale.endedAt()) / 86400;  // 1d = 60s * 60m * 24h = 86400s
        uint256 passedYears = passedDays * 100 / 36525;    // about 365.25 days in a year
        uint256 inflatedSupply = initialSupply;
        for (uint256 i; i < passedYears; i++) {
            inflatedSupply = SafeMath.add(inflatedSupply, SafeMath.mul(inflatedSupply, 25) / 1000); // 2.5%/y = 0.025/y
        }

        uint256 remainderedDays = passedDays * 100 % 36525 / 100;
        if (remainderedDays > 0) {
            uint256 inflatableTokensOfNextYear =
                SafeMath.mul(inflatedSupply, 25) / 1000;
            inflatedSupply = SafeMath.add(inflatedSupply, SafeMath.mul(
                inflatableTokensOfNextYear, remainderedDays * 100) / 36525);
        }

        return SafeMath.sub(inflatedSupply, totalSupply);
    }

    /*
     *  Internal functions
     */

    /**
     * @dev Allocate tokens value from an address to another one. This function is only called internally.
     * @param from Address from where tokens come
     * @param to Address to where tokens are allocated
     * @param value Number of tokens to transfer
     */
    function allocateFrom(address from, address to, uint256 value) internal returns (bool) {
        assert(value > 0 && balances[from] >= value);
        balances[from] = SafeMath.sub(balances[from], value);
        balances[to] = SafeMath.add(balances[to], value);
        Transfer(from, to, value);
        return true;
    }
}