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
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AbstractStarbaseToken is ERC20 {
    function isFundraiser(address fundraiserAddress) public returns (bool);
    function company() public returns (address);
    function allocateToCrowdsalePurchaser(address to, uint256 value) public returns (bool);
    function allocateToMarketingSupporter(address to, uint256 value) public returns (bool);
}

contract AbstractStarbaseCrowdsale {
    function workshop() constant returns (address) {}
    function startDate() constant returns (uint256) {}
    function endedAt() constant returns (uint256) {}
    function isEnded() constant returns (bool);
    function totalRaisedAmountInCny() constant returns (uint256);
    function numOfPurchasedTokensOnCsBy(address purchaser) constant returns (uint256);
    function numOfPurchasedTokensOnEpBy(address purchaser) constant returns (uint256);
}

// @title EarlyPurchase contract - Keep track of purchased amount by Early Purchasers
/// @author Starbase PTE. LTD. - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="056c6b636a4576716477676476602b666a">[email&#160;protected]</a>>
contract StarbaseEarlyPurchase {
    /*
     *  Constants
     */
    string public constant PURCHASE_AMOUNT_UNIT = &#39;CNY&#39;;    // Chinese Yuan
    string public constant PURCHASE_AMOUNT_RATE_REFERENCE = &#39;http://www.xe.com/currencytables/&#39;;
    uint256 public constant PURCHASE_AMOUNT_CAP = 9000000;

    /*
     *  Types
     */
    struct EarlyPurchase {
        address purchaser;
        uint256 amount;        // CNY based amount
        uint256 purchasedAt;   // timestamp
    }

    /*
     *  External contracts
     */
    AbstractStarbaseCrowdsale public starbaseCrowdsale;

    /*
     *  Storage
     */
    address public owner;
    EarlyPurchase[] public earlyPurchases;
    uint256 public earlyPurchaseClosedAt;

    /*
     *  Modifiers
     */
    modifier noEther() {
        require(msg.value == 0);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyBeforeCrowdsale() {
        assert(address(starbaseCrowdsale) == address(0) || starbaseCrowdsale.startDate() == 0);
        _;
    }

    modifier onlyEarlyPurchaseTerm() {
        assert(earlyPurchaseClosedAt <= 0);
        _;
    }

    /*
     *  Contract functions
     */

    /**
     * @dev Returns early purchased amount by purchaser&#39;s address
     * @param purchaser Purchaser address
     */
    function purchasedAmountBy(address purchaser)
        external
        constant
        noEther
        returns (uint256 amount)
    {
        for (uint256 i; i < earlyPurchases.length; i++) {
            if (earlyPurchases[i].purchaser == purchaser) {
                amount += earlyPurchases[i].amount;
            }
        }
    }

    /**
     * @dev Returns total amount of raised funds by Early Purchasers
     */
    function totalAmountOfEarlyPurchases()
        constant
        noEther
        public
        returns (uint256 totalAmount)
    {
        for (uint256 i; i < earlyPurchases.length; i++) {
            totalAmount += earlyPurchases[i].amount;
        }
    }

    /**
     * @dev Returns number of early purchases
     */
    function numberOfEarlyPurchases()
        external
        constant
        noEther
        returns (uint256)
    {
        return earlyPurchases.length;
    }

    /**
     * @dev Append an early purchase log
     * @param purchaser Purchaser address
     * @param amount Purchase amount
     * @param purchasedAt Timestamp of purchased date
     */
    function appendEarlyPurchase(address purchaser, uint256 amount, uint256 purchasedAt)
        external
        noEther
        onlyOwner
        onlyBeforeCrowdsale
        onlyEarlyPurchaseTerm
        returns (bool)
    {
        if (amount == 0 ||
            totalAmountOfEarlyPurchases() + amount > PURCHASE_AMOUNT_CAP)
        {
            return false;
        }

        assert(purchasedAt != 0 || purchasedAt <= now);

        earlyPurchases.push(EarlyPurchase(purchaser, amount, purchasedAt));
        return true;
    }

    /**
     * @dev Close early purchase term
     */
    function closeEarlyPurchase()
        external
        noEther
        onlyOwner
        returns (bool)
    {
        earlyPurchaseClosedAt = now;
    }

    /**
     * @dev Setup function sets external contract&#39;s address
     * @param starbaseCrowdsaleAddress Token address
     */
    function setup(address starbaseCrowdsaleAddress)
        external
        noEther
        onlyOwner
        returns (bool)
    {
        if (address(starbaseCrowdsale) == 0) {
            starbaseCrowdsale = AbstractStarbaseCrowdsale(starbaseCrowdsaleAddress);
            return true;
        }
        return false;
    }

    /**
     * @dev Contract constructor function
     */
    function StarbaseEarlyPurchase() noEther {
        owner = msg.sender;
    }
}


/// @title EarlyPurchaseAmendment contract - Amend early purchase records of the original contract
/// @author Starbase PTE. LTD. - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="cfbcbabfbfa0bdbb8fbcbbaebdadaebcaae1aca0">[email&#160;protected]</a>>
contract StarbaseEarlyPurchaseAmendment {
    /*
     *  Events
     */
    event EarlyPurchaseInvalidated(uint256 epIdx);
    event EarlyPurchaseAmended(uint256 epIdx);

    /*
     *  External contracts
     */
    AbstractStarbaseCrowdsale public starbaseCrowdsale;
    StarbaseEarlyPurchase public starbaseEarlyPurchase;

    /*
     *  Storage
     */
    address public owner;
    uint256[] public invalidEarlyPurchaseIndexes;
    uint256[] public amendedEarlyPurchaseIndexes;
    mapping (uint256 => StarbaseEarlyPurchase.EarlyPurchase) public amendedEarlyPurchases;

    /*
     *  Modifiers
     */
    modifier noEther() {
        require(msg.value == 0);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyBeforeCrowdsale() {
        assert(address(starbaseCrowdsale) == address(0) || starbaseCrowdsale.startDate() == 0);
        _;
    }

    modifier onlyEarlyPurchasesLoaded() {
        assert(address(starbaseEarlyPurchase) != address(0));
        _;
    }

    /*
     *  Functions below are compatible with starbaseEarlyPurchase contract
     */

    /**
     * @dev Returns an early purchase record
     * @param earlyPurchaseIndex Index number of an early purchase
     */
    function earlyPurchases(uint256 earlyPurchaseIndex)
        external
        constant
        onlyEarlyPurchasesLoaded
        returns (address purchaser, uint256 amount, uint256 purchasedAt)
    {
        return starbaseEarlyPurchase.earlyPurchases(earlyPurchaseIndex);
    }

    /**
     * @dev Returns early purchased amount by purchaser&#39;s address
     * @param purchaser Purchaser address
     */
    function purchasedAmountBy(address purchaser)
        external
        constant
        noEther
        returns (uint256 amount)
    {
        StarbaseEarlyPurchase.EarlyPurchase[] memory normalizedEP =
            normalizedEarlyPurchases();
        for (uint256 i; i < normalizedEP.length; i++) {
            if (normalizedEP[i].purchaser == purchaser) {
                amount += normalizedEP[i].amount;
            }
        }
    }

    /**
     * @dev Returns total amount of raised funds by Early Purchasers
     */
    function totalAmountOfEarlyPurchases()
        constant
        noEther
        public
        returns (uint256 totalAmount)
    {
        StarbaseEarlyPurchase.EarlyPurchase[] memory normalizedEP =
            normalizedEarlyPurchases();
        for (uint256 i; i < normalizedEP.length; i++) {
            totalAmount += normalizedEP[i].amount;
        }
    }

    /**
     * @dev Returns number of early purchases
     */
    function numberOfEarlyPurchases()
        external
        constant
        noEther
        returns (uint256)
    {
        return normalizedEarlyPurchases().length;
    }

    /**
     * @dev Sets up function sets external contract&#39;s address
     * @param starbaseCrowdsaleAddress Token address
     */
    function setup(address starbaseCrowdsaleAddress)
        external
        noEther
        onlyOwner
        returns (bool)
    {
        if (address(starbaseCrowdsale) == 0) {
            starbaseCrowdsale = AbstractStarbaseCrowdsale(starbaseCrowdsaleAddress);
            return true;
        }
        return false;
    }

    /*
     *  Contract functions unique to StarbaseEarlyPurchaseAmendment
     */

     /**
      * @dev Invalidate early purchase
      * @param earlyPurchaseIndex Index number of the purchase
      */
    function invalidateEarlyPurchase(uint256 earlyPurchaseIndex)
        external
        noEther
        onlyOwner
        onlyEarlyPurchasesLoaded
        onlyBeforeCrowdsale
        returns (bool)
    {
        assert(numberOfRawEarlyPurchases() > earlyPurchaseIndex); // Array Index Out of Bounds Exception

        for (uint256 i; i < invalidEarlyPurchaseIndexes.length; i++) {
            assert(invalidEarlyPurchaseIndexes[i] != earlyPurchaseIndex);
        }

        invalidEarlyPurchaseIndexes.push(earlyPurchaseIndex);
        EarlyPurchaseInvalidated(earlyPurchaseIndex);
        return true;
    }

    /**
     * @dev Checks whether early purchase is invalid
     * @param earlyPurchaseIndex Index number of the purchase
     */
    function isInvalidEarlyPurchase(uint256 earlyPurchaseIndex)
        constant
        noEther
        public
        returns (bool)
    {
        assert(numberOfRawEarlyPurchases() > earlyPurchaseIndex); // Array Index Out of Bounds Exception


        for (uint256 i; i < invalidEarlyPurchaseIndexes.length; i++) {
            if (invalidEarlyPurchaseIndexes[i] == earlyPurchaseIndex) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Amends a given early purchase with data
     * @param earlyPurchaseIndex Index number of the purchase
     * @param purchaser Purchaser&#39;s address
     * @param amount Value of purchase
     * @param purchasedAt Purchase timestamp
     */
    function amendEarlyPurchase(uint256 earlyPurchaseIndex, address purchaser, uint256 amount, uint256 purchasedAt)
        external
        noEther
        onlyOwner
        onlyEarlyPurchasesLoaded
        onlyBeforeCrowdsale
        returns (bool)
    {
        assert(purchasedAt != 0 || purchasedAt <= now);

        assert(numberOfRawEarlyPurchases() > earlyPurchaseIndex);

        assert(!isInvalidEarlyPurchase(earlyPurchaseIndex)); // Invalid early purchase cannot be amended

        if (!isAmendedEarlyPurchase(earlyPurchaseIndex)) {
            amendedEarlyPurchaseIndexes.push(earlyPurchaseIndex);
        }

        amendedEarlyPurchases[earlyPurchaseIndex] =
            StarbaseEarlyPurchase.EarlyPurchase(purchaser, amount, purchasedAt);
        EarlyPurchaseAmended(earlyPurchaseIndex);
        return true;
    }

    /**
     * @dev Checks whether early purchase is amended
     * @param earlyPurchaseIndex Index number of the purchase
     */
    function isAmendedEarlyPurchase(uint256 earlyPurchaseIndex)
        constant
        noEther
        returns (bool)
    {
        assert(numberOfRawEarlyPurchases() > earlyPurchaseIndex); // Array Index Out of Bounds Exception

        for (uint256 i; i < amendedEarlyPurchaseIndexes.length; i++) {
            if (amendedEarlyPurchaseIndexes[i] == earlyPurchaseIndex) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Loads early purchases data to StarbaseEarlyPurchaseAmendment contract
     * @param starbaseEarlyPurchaseAddress Address from starbase early purchase
     */
    function loadStarbaseEarlyPurchases(address starbaseEarlyPurchaseAddress)
        external
        noEther
        onlyOwner
        onlyBeforeCrowdsale
        returns (bool)
    {
        assert(starbaseEarlyPurchaseAddress != 0 ||
            address(starbaseEarlyPurchase) == 0);

        starbaseEarlyPurchase = StarbaseEarlyPurchase(starbaseEarlyPurchaseAddress);
        assert(starbaseEarlyPurchase.earlyPurchaseClosedAt() != 0); // the early purchase must be closed

        return true;
    }

    /**
     * @dev Contract constructor function. It sets owner
     */
    function StarbaseEarlyPurchaseAmendment() noEther {
        owner = msg.sender;
    }

    /**
     * Internal functions
     */

    /**
     * @dev Normalizes early purchases data
     */
    function normalizedEarlyPurchases()
        constant
        internal
        returns (StarbaseEarlyPurchase.EarlyPurchase[] normalizedEP)
    {
        uint256 rawEPCount = numberOfRawEarlyPurchases();
        normalizedEP = new StarbaseEarlyPurchase.EarlyPurchase[](
            rawEPCount - invalidEarlyPurchaseIndexes.length);

        uint256 normalizedIdx;
        for (uint256 i; i < rawEPCount; i++) {
            if (isInvalidEarlyPurchase(i)) {
                continue;   // invalid early purchase should be ignored
            }

            StarbaseEarlyPurchase.EarlyPurchase memory ep;
            if (isAmendedEarlyPurchase(i)) {
                ep = amendedEarlyPurchases[i];  // amended early purchase should take a priority
            } else {
                ep = getEarlyPurchase(i);
            }

            normalizedEP[normalizedIdx] = ep;
            normalizedIdx++;
        }
    }

    /**
     * @dev Fetches early purchases data
     */
    function getEarlyPurchase(uint256 earlyPurchaseIndex)
        internal
        constant
        onlyEarlyPurchasesLoaded
        returns (StarbaseEarlyPurchase.EarlyPurchase)
    {
        var (purchaser, amount, purchasedAt) =
            starbaseEarlyPurchase.earlyPurchases(earlyPurchaseIndex);
        return StarbaseEarlyPurchase.EarlyPurchase(purchaser, amount, purchasedAt);
    }

    /**
     * @dev Returns raw number of early purchases
     */
    function numberOfRawEarlyPurchases()
        internal
        constant
        onlyEarlyPurchasesLoaded
        returns (uint256)
    {
        return starbaseEarlyPurchase.numberOfEarlyPurchases();
    }
}


/**
 * @title Crowdsale contract - Starbase crowdsale to create STAR.
 * @author Starbase PTE. LTD. - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="1871767e77586b6c796a7a796b7d367b77">[email&#160;protected]</a>>
 */
contract StarbaseCrowdsale is Ownable {
    /*
     *  Events
     */
    event CrowdsaleEnded(uint256 endedAt);
    event StarBasePurchasedWithEth(address purchaser, uint256 amount, uint256 rawAmount, uint256 cnyEthRate, uint256 bonusTokensPercentage);
    event StarBasePurchasedOffChain(address purchaser, uint256 amount, uint256 rawAmount, uint256 cnyBtcRate, uint256 bonusTokensPercentage, string data);
    event CnyEthRateUpdated(uint256 cnyEthRate);
    event CnyBtcRateUpdated(uint256 cnyBtcRate);
    event QualifiedPartnerAddress(address qualifiedPartner);
    event PurchaseInvalidated(uint256 purchaseIdx);
    event PurchaseAmended(uint256 purchaseIdx);

    /**
     *  External contracts
     */
    AbstractStarbaseToken public starbaseToken;
    StarbaseEarlyPurchaseAmendment public starbaseEpAmendment;

    /**
     *  Constants
     */
    uint256 constant public crowdsaleTokenAmount = 125000000e18;
    uint256 constant public earlyPurchaseTokenAmount = 50000000e18;
    uint256 constant public MIN_INVESTMENT = 1; // min is 1 Wei
    uint256 constant public MAX_CROWDSALE_CAP = 60000000; // approximately 9M USD for the crowdsale(CS). 1M (by EP) + 9M (by CS) = 10M (Total)
    string public constant PURCHASE_AMOUNT_UNIT = &#39;CNY&#39;;  // Chinese Yuan

    /**
     * Types
     */
    struct CrowdsalePurchase {
        address purchaser;
        uint256 amount;        // CNY based amount with bonus
        uint256 rawAmount;     // CNY based amount no bonus
        uint256 purchasedAt;   // timestamp
        string data;           // additional data (e.g. Tx ID of Bitcoin)
        uint256 bonus;
    }

    struct QualifiedPartners {
        uint256 amountCap;
        uint256 amountRaised;
        bool    bonaFide;
        uint256 commissionFeePercentage; // example 5 will calculate the percentage as 5%
    }

    /**
     *  Storage
     */
    address public workshop; // holds undelivered STARs

    uint public numOfDeliveredCrowdsalePurchases = 0;  // index to keep the number of crowdsale purchases have already been processed by `deliverPurchasedTokens`
    uint public numOfDeliveredEarlyPurchases = 0;  // index to keep the number of early purchases have already been processed by `deliverPurchasedTokens`
    uint256 public numOfLoadedEarlyPurchases = 0; // index to keep the number of early purchases that have already been loaded by `loadEarlyPurchases`

    address[] public earlyPurchasers;
    mapping (address => QualifiedPartners) public qualifiedPartners;
    mapping (address => uint256) public earlyPurchasedAmountBy; // early purchased amount in CNY per purchasers&#39; address
    bool public earlyPurchasesLoaded = false;  // returns whether all early purchases are loaded into this contract

    // crowdsale
    uint256 public purchaseStartBlock;  // crowdsale purchases can be accepted from this block number
    uint256 public startDate;
    uint256 public endedAt;
    CrowdsalePurchase[] public crowdsalePurchases;
    uint256 public cnyBtcRate; // this rate won&#39;t be used from a smart contract function but external system
    uint256 public cnyEthRate;

    // bonus milestones
    uint256 public firstBonusSalesEnds;
    uint256 public secondBonusSalesEnds;
    uint256 public thirdBonusSalesEnds;
    uint256 public fourthBonusSalesEnds;
    uint256 public fifthBonusSalesEnds;
    uint256 public firstExtendedBonusSalesEnds;
    uint256 public secondExtendedBonusSalesEnds;
    uint256 public thirdExtendedBonusSalesEnds;
    uint256 public fourthExtendedBonusSalesEnds;
    uint256 public fifthExtendedBonusSalesEnds;
    uint256 public sixthExtendedBonusSalesEnds;

    // after the crowdsale
    mapping(uint256 => CrowdsalePurchase) public invalidatedOrigPurchases;  // Original purchase which was invalidated by owner
    mapping(uint256 => CrowdsalePurchase) public amendedOrigPurchases;      // Original purchase which was amended by owner

    mapping (address => uint256) public numOfPurchasedTokensOnCsBy;    // the number of tokens purchased on the crowdsale by a purchaser
    mapping (address => uint256) public numOfPurchasedTokensOnEpBy;    // the number of tokens early purchased by a purchaser

    /**
     *  Modifiers
     */
    modifier minInvestment() {
        // User has to send at least the ether value of one token.
        assert(msg.value >= MIN_INVESTMENT);
        _;
    }

    modifier whenEnded() {
        assert(isEnded());
        _;
    }

    modifier hasBalance() {
        assert(this.balance > 0);
        _;
    }
    modifier rateIsSet(uint256 _rate) {
        assert(_rate != 0);
        _;
    }

    modifier whenNotEnded() {
        assert(!isEnded());
        _;
    }

    modifier tokensNotDelivered() {
        assert(numOfDeliveredCrowdsalePurchases == 0);
        assert(numOfDeliveredEarlyPurchases == 0);
        _;
    }

    modifier onlyFundraiser() {
      assert(address(starbaseToken) != 0);
      assert(starbaseToken.isFundraiser(msg.sender));
      _;
    }

    /**
     * Contract functions
     */

    /**
     * @dev Contract constructor function sets owner and start date.
     * @param workshopAddr The address that will hold undelivered Star tokens
     * @param starbaseEpAddr The address that holds the early purchasers Star tokens
     */
    function StarbaseCrowdsale(address workshopAddr, address starbaseEpAddr) {
        require(workshopAddr != 0 && starbaseEpAddr != 0);

        owner = msg.sender;
        workshop = workshopAddr;
        starbaseEpAmendment = StarbaseEarlyPurchaseAmendment(starbaseEpAddr);
    }

    /**
     * @dev Fallback accepts payment for Star tokens with Eth
     */
    function() payable {
        redirectToPurchase();
    }

    /**
     * External functions
     */

    /**
     * @dev Setup function sets external contracts&#39; addresses.
     * @param starbaseTokenAddress Token address.
     * @param _purchaseStartBlock Block number to start crowdsale
     */
    function setup(address starbaseTokenAddress, uint256 _purchaseStartBlock)
        external
        onlyOwner
        returns (bool)
    {
        assert(address(starbaseToken) == 0);
        starbaseToken = AbstractStarbaseToken(starbaseTokenAddress);
        purchaseStartBlock = _purchaseStartBlock;
        return true;
    }

    /**
     * @dev Allows owner to record a purchase made outside of Ethereum blockchain
     * @param purchaser Address of a purchaser
     * @param rawAmount Purchased amount in CNY
     * @param purchasedAt Timestamp at the purchase made
     * @param data Identifier as an evidence of the purchase (e.g. btc:1xyzxyz)
     */
    function recordOffchainPurchase(
        address purchaser,
        uint256 rawAmount,
        uint256 purchasedAt,
        string data
    )
        external
        onlyFundraiser
        whenNotEnded
        rateIsSet(cnyBtcRate)
        returns (bool)
    {
        require(purchaseStartBlock > 0 && block.number >= purchaseStartBlock);
        if (startDate == 0) {
            startCrowdsale(block.timestamp);
        }

        uint256 bonusTier = getBonusTier();
        uint amount = recordPurchase(purchaser, rawAmount, purchasedAt, data, bonusTier);

        StarBasePurchasedOffChain(purchaser, amount, rawAmount, cnyBtcRate, bonusTier, data);
        return true;
    }

    /**
     * @dev Transfers raised funds to company&#39;s wallet address at any given time.
     */
    function withdrawForCompany()
        external
        onlyFundraiser
        hasBalance
    {
        address company = starbaseToken.company();
        require(company != address(0));
        company.transfer(this.balance);
    }

    /**
     * @dev Update the CNY/ETH rate to record purchases in CNY
     */
    function updateCnyEthRate(uint256 rate)
        external
        onlyFundraiser
        returns (bool)
    {
        cnyEthRate = rate;
        CnyEthRateUpdated(cnyEthRate);
        return true;
    }

    /**
     * @dev Update the CNY/BTC rate to record purchases in CNY
     */
    function updateCnyBtcRate(uint256 rate)
        external
        onlyFundraiser
        returns (bool)
    {
        cnyBtcRate = rate;
        CnyBtcRateUpdated(cnyBtcRate);
        return true;
    }

    /**
     * @dev Allow for the possibilyt for contract owner to start crowdsale
     */
    function ownerStartsCrowdsale(uint256 timestamp)
        external
        onlyOwner
    {
        assert(startDate == 0 && block.number >= purchaseStartBlock);   // overwriting startDate is not permitted and it should be after the crowdsale start block
        startCrowdsale(timestamp);

    }

    /**
     * @dev Ends crowdsale
     * @param timestamp Timestamp at the crowdsale ended
     */
    function endCrowdsale(uint256 timestamp)
        external
        onlyOwner
    {
        assert(timestamp > 0 && timestamp <= now);
        assert(endedAt == 0);   // overwriting time is not permitted
        endedAt = timestamp;
        CrowdsaleEnded(endedAt);
    }

    /**
     * @dev Invalidate a crowdsale purchase if something is wrong with it
     * @param purchaseIdx Index number of the crowdsalePurchases to invalidate
     */
    function invalidatePurchase(uint256 purchaseIdx)
        external
        onlyOwner
        whenEnded
        tokensNotDelivered
        returns (bool)
    {
        CrowdsalePurchase memory purchase = crowdsalePurchases[purchaseIdx];
        assert(purchase.purchaser != 0 && purchase.amount != 0);

        crowdsalePurchases[purchaseIdx].amount = 0;
        crowdsalePurchases[purchaseIdx].rawAmount = 0;
        invalidatedOrigPurchases[purchaseIdx] = purchase;
        PurchaseInvalidated(purchaseIdx);
        return true;
    }

    /**
     * @dev Amend a crowdsale purchase if something is wrong with it
     * @param purchaseIdx Index number of the crowdsalePurchases to invalidate
     * @param purchaser Address of the buyer
     * @param amount Purchased tokens as per the CNY rate used
     * @param rawAmount Purchased tokens as per the CNY rate used without the bonus
     * @param purchasedAt Timestamp at the purchase made
     * @param data Identifier as an evidence of the purchase (e.g. btc:1xyzxyz)
     * @param bonus bonus milestones of the purchase
     */
    function amendPurchase(
        uint256 purchaseIdx,
        address purchaser,
        uint256 amount,
        uint256 rawAmount,
        uint256 purchasedAt,
        string data,
        uint256 bonus
    )
        external
        onlyOwner
        whenEnded
        tokensNotDelivered
        returns (bool)
    {
        CrowdsalePurchase memory purchase = crowdsalePurchases[purchaseIdx];
        assert(purchase.purchaser != 0 && purchase.amount != 0);

        amendedOrigPurchases[purchaseIdx] = purchase;
        crowdsalePurchases[purchaseIdx] =
            CrowdsalePurchase(purchaser, amount, rawAmount, purchasedAt, data, bonus);
        PurchaseAmended(purchaseIdx);
        return true;
    }

    /**
     * @dev Deliver tokens to purchasers according to their purchase amount in CNY
     */
    function deliverPurchasedTokens()
        external
        onlyOwner
        whenEnded
        returns (bool)
    {
        assert(earlyPurchasesLoaded);
        assert(address(starbaseToken) != 0);

        uint256 totalAmountOfPurchasesInCny = totalRaisedAmountInCny(); // totalPreSale + totalCrowdsale

        for (uint256 i = numOfDeliveredCrowdsalePurchases; i < crowdsalePurchases.length && msg.gas > 200000; i++) {
            CrowdsalePurchase memory purchase = crowdsalePurchases[i];
            if (purchase.amount == 0) {
                continue;   // skip invalidated purchase
            }

            /*
             * “Value” refers to the contribution of the User:
             *  {crowdsale_purchaser_token_amount} =
             *  {crowdsale_token_amount} * {crowdsalePurchase_value} / {earlypurchase_value} + {crowdsale_value}.
             *
             * Example: If a User contributes during the Contribution Period 100 CNY (including applicable
             * Bonus, if any) and the total amount early purchases amounts to 6’000’000 CNY
             * and total amount raised during the Contribution Period is 30’000’000, then he will get
             * 347.22 STAR = 125’000’000 STAR * 100 CNY / 30’000’000 CNY + 6’000’000 CNY.
            */

            uint256 crowdsalePurchaseValue = purchase.amount;
            uint256 tokenCount = SafeMath.mul(crowdsaleTokenAmount, crowdsalePurchaseValue) / totalAmountOfPurchasesInCny;

            numOfPurchasedTokensOnCsBy[purchase.purchaser] = SafeMath.add(numOfPurchasedTokensOnCsBy[purchase.purchaser], tokenCount);
            starbaseToken.allocateToCrowdsalePurchaser(purchase.purchaser, tokenCount);
            numOfDeliveredCrowdsalePurchases = SafeMath.add(i, 1);
        }

        for (uint256 j = numOfDeliveredEarlyPurchases; j < earlyPurchasers.length && msg.gas > 200000; j++) {
            address earlyPurchaser = earlyPurchasers[j];

            /*
             * “Value” refers to the contribution of the User:
             * {earlypurchaser_token_amount} =
             * {earlypurchaser_token_amount} * ({earlypurchase_value} / {total_earlypurchase_value})
             *  + {crowdsale_token_amount} * ({earlypurchase_value} / {earlypurchase_value} + {crowdsale_value}).
             *
             * Example: If an Early Purchaser contributes 100 CNY (including Bonus of 20%) and the
             * total amount of early purchases amounts to 6’000’000 CNY and the total amount raised
             * during the Contribution Period is 30’000’000 CNY, then he will get 1180.55 STAR =
             * 50’000’000 STAR * 100 CNY / 6’000’000 CNY + 125’000’000 STAR * 100 CNY /
             * 30’000’000 CNY + 6’000’000 CNY
             */

            uint256 earlyPurchaserPurchaseValue = earlyPurchasedAmountBy[earlyPurchaser];

            uint256 epTokenCalculationFromEPTokenAmount = SafeMath.mul(earlyPurchaseTokenAmount, earlyPurchaserPurchaseValue) / totalAmountOfEarlyPurchases();

            uint256 epTokenCalculationFromCrowdsaleTokenAmount = SafeMath.mul(crowdsaleTokenAmount, earlyPurchaserPurchaseValue) / totalAmountOfPurchasesInCny;

            uint256 epTokenCount = SafeMath.add(epTokenCalculationFromEPTokenAmount, epTokenCalculationFromCrowdsaleTokenAmount);

            numOfPurchasedTokensOnEpBy[earlyPurchaser] = SafeMath.add(numOfPurchasedTokensOnEpBy[earlyPurchaser], epTokenCount);
            starbaseToken.allocateToCrowdsalePurchaser(earlyPurchaser, epTokenCount);
            numOfDeliveredEarlyPurchases = SafeMath.add(j, 1);
        }

        return true;
    }

    /**
     * @dev Load early purchases from the contract keeps track of them
     */
    function loadEarlyPurchases() external onlyOwner returns (bool) {
        if (earlyPurchasesLoaded) {
            return false;    // all EPs have already been loaded
        }

        uint256 numOfOrigEp = starbaseEpAmendment
            .starbaseEarlyPurchase()
            .numberOfEarlyPurchases();

        for (uint256 i = numOfLoadedEarlyPurchases; i < numOfOrigEp && msg.gas > 200000; i++) {
            if (starbaseEpAmendment.isInvalidEarlyPurchase(i)) {
                continue;
            }
            var (purchaser, amount,) =
                starbaseEpAmendment.isAmendedEarlyPurchase(i)
                ? starbaseEpAmendment.amendedEarlyPurchases(i)
                : starbaseEpAmendment.earlyPurchases(i);
            if (amount > 0) {
                if (earlyPurchasedAmountBy[purchaser] == 0) {
                    earlyPurchasers.push(purchaser);
                }
                // each early purchaser receives 20% bonus
                uint256 bonus = SafeMath.mul(amount, 20) / 100;
                uint256 amountWithBonus = SafeMath.add(amount, bonus);

                earlyPurchasedAmountBy[purchaser] += amountWithBonus;
            }
        }

        numOfLoadedEarlyPurchases += i;
        assert(numOfLoadedEarlyPurchases <= numOfOrigEp);
        if (numOfLoadedEarlyPurchases == numOfOrigEp) {
            earlyPurchasesLoaded = true;    // enable the flag
        }
        return true;
    }

    /**
      * @dev Set qualified crowdsale partner i.e. Bitcoin Suisse address
      * @param _qualifiedPartner Address of the qualified partner that can purchase during crowdsale
      * @param _amountCap Ether value which partner is able to contribute
      * @param _commissionFeePercentage Integer that represents the fee to pay qualified partner 5 is 5%
      */
    function setQualifiedPartner(address _qualifiedPartner, uint256 _amountCap, uint256 _commissionFeePercentage)
        external
        onlyOwner
    {
        assert(!qualifiedPartners[_qualifiedPartner].bonaFide);
        qualifiedPartners[_qualifiedPartner].bonaFide = true;
        qualifiedPartners[_qualifiedPartner].amountCap = _amountCap;
        qualifiedPartners[_qualifiedPartner].commissionFeePercentage = _commissionFeePercentage;
        QualifiedPartnerAddress(_qualifiedPartner);
    }

    /**
     * @dev Remove address from qualified partners list.
     * @param _qualifiedPartner Address to be removed from the list.
     */
    function unlistQualifiedPartner(address _qualifiedPartner) external onlyOwner {
        assert(qualifiedPartners[_qualifiedPartner].bonaFide);
        qualifiedPartners[_qualifiedPartner].bonaFide = false;
    }

    /**
     * @dev Update whitelisted address amount allowed to raise during the presale.
     * @param _qualifiedPartner Qualified Partner address to be updated.
     * @param _amountCap Amount that the address is able to raise during the presale.
     */
    function updateQualifiedPartnerCapAmount(address _qualifiedPartner, uint256 _amountCap) external onlyOwner {
        assert(qualifiedPartners[_qualifiedPartner].bonaFide);
        qualifiedPartners[_qualifiedPartner].amountCap = _amountCap;
    }

    /**
     * Public functions
     */

    /**
     * @dev Returns boolean for whether crowdsale has ended
     */
    function isEnded() constant public returns (bool) {
        return (endedAt > 0 && endedAt <= now);
    }

    /**
     * @dev Returns number of purchases to date.
     */
    function numOfPurchases() constant public returns (uint256) {
        return crowdsalePurchases.length;
    }

    /**
     * @dev Calculates total amount of tokens purchased includes bonus tokens.
     */
    function totalAmountOfCrowdsalePurchases() constant public returns (uint256 amount) {
        for (uint256 i; i < crowdsalePurchases.length; i++) {
            amount = SafeMath.add(amount, crowdsalePurchases[i].amount);
        }
    }

    /**
     * @dev Calculates total amount of tokens purchased without bonus conversion.
     */
    function totalAmountOfCrowdsalePurchasesWithoutBonus() constant public returns (uint256 amount) {
        for (uint256 i; i < crowdsalePurchases.length; i++) {
            amount = SafeMath.add(amount, crowdsalePurchases[i].rawAmount);
        }
    }

    /**
     * @dev Returns total raised amount in CNY (includes EP) and bonuses
     */
    function totalRaisedAmountInCny() constant public returns (uint256) {
        return SafeMath.add(totalAmountOfEarlyPurchases(), totalAmountOfCrowdsalePurchases());
    }

    /**
     * @dev Returns total amount of early purchases in CNY
     */
    function totalAmountOfEarlyPurchases() constant public returns(uint256) {
       return starbaseEpAmendment.totalAmountOfEarlyPurchases();
    }

    /**
     * @dev Allows qualified crowdsale partner to purchase Star Tokens
     */
    function purchaseAsQualifiedPartner()
        payable
        public
        rateIsSet(cnyEthRate)
        returns (bool)
    {
        require(qualifiedPartners[msg.sender].bonaFide);
        qualifiedPartners[msg.sender].amountRaised = SafeMath.add(msg.value, qualifiedPartners[msg.sender].amountRaised);

        assert(qualifiedPartners[msg.sender].amountRaised <= qualifiedPartners[msg.sender].amountCap);

        uint256 bonusTier = 30; // Pre sale purchasers get 30 percent bonus
        uint256 rawAmount = SafeMath.mul(msg.value, cnyEthRate) / 1e18;
        uint amount = recordPurchase(msg.sender, rawAmount, now, &#39;&#39;, bonusTier);

        if (qualifiedPartners[msg.sender].commissionFeePercentage > 0) {
            sendQualifiedPartnerCommissionFee(msg.sender, msg.value);
        }

        StarBasePurchasedWithEth(msg.sender, amount, rawAmount, cnyEthRate, bonusTier);
        return true;
    }

    /**
     * @dev Allows user to purchase STAR tokens with Ether
     */
    function purchaseWithEth()
        payable
        public
        minInvestment
        whenNotEnded
        rateIsSet(cnyEthRate)
        returns (bool)
    {
        require(purchaseStartBlock > 0 && block.number >= purchaseStartBlock);
        if (startDate == 0) {
            startCrowdsale(block.timestamp);
        }

        uint256 bonusTier = getBonusTier();

        uint256 rawAmount = SafeMath.mul(msg.value, cnyEthRate) / 1e18;
        uint amount = recordPurchase(msg.sender, rawAmount, now, &#39;&#39;, bonusTier);

        StarBasePurchasedWithEth(msg.sender, amount, rawAmount, cnyEthRate, bonusTier);
        return true;
    }

    /**
     * Internal functions
     */

    /**
     * @dev Initializes Starbase crowdsale
     */
    function startCrowdsale(uint256 timestamp) internal {
        startDate = timestamp;

        // set token bonus milestones
        firstBonusSalesEnds = startDate + 7 days;             // 1. 1st ~ 7th day
        secondBonusSalesEnds = firstBonusSalesEnds + 14 days; // 2. 8th ~ 21st day
        thirdBonusSalesEnds = secondBonusSalesEnds + 14 days; // 3. 22nd ~ 35th day
        fourthBonusSalesEnds = thirdBonusSalesEnds + 7 days;  // 4. 36th ~ 42nd day
        fifthBonusSalesEnds = fourthBonusSalesEnds + 3 days;  // 5. 43rd ~ 45th day

        // extended sales bonus milestones
        firstExtendedBonusSalesEnds = fifthBonusSalesEnds + 3 days;         // 1. 46th ~ 48th day
        secondExtendedBonusSalesEnds = firstExtendedBonusSalesEnds + 3 days; // 2. 49th ~ 51st day
        thirdExtendedBonusSalesEnds = secondExtendedBonusSalesEnds + 3 days; // 3. 52nd ~ 54th day
        fourthExtendedBonusSalesEnds = thirdExtendedBonusSalesEnds + 3 days; // 4. 55th ~ 57th day
        fifthExtendedBonusSalesEnds = fourthExtendedBonusSalesEnds + 3 days;  // 5. 58th ~ 60th day
        sixthExtendedBonusSalesEnds = fifthExtendedBonusSalesEnds + 60 days; // 6. 61st ~ 120th day
    }

    /**
     * @dev Abstract record of a purchase to Tokens
     * @param purchaser Address of the buyer
     * @param rawAmount Amount in CNY as per the CNY/ETH rate used
     * @param timestamp Timestamp at the purchase made
     * @param data Identifier as an evidence of the purchase (e.g. btc:1xyzxyz)
     * @param bonusTier bonus milestones of the purchase
     */
    function recordPurchase(
        address purchaser,
        uint256 rawAmount,
        uint256 timestamp,
        string data,
        uint256 bonusTier
    )
        internal
        returns(uint256 amount)
    {
        amount = rawAmount; // amount to check reach of max cap. it does not care for bonus tokens here

        // presale transfers which occurs before the crowdsale ignores the crowdsale hard cap
        if (block.number >= purchaseStartBlock) {

            assert(totalAmountOfCrowdsalePurchasesWithoutBonus() <= MAX_CROWDSALE_CAP);

            uint256 crowdsaleTotalAmountAfterPurchase = SafeMath.add(totalAmountOfCrowdsalePurchasesWithoutBonus(), amount);

            // check whether purchase goes over the cap and send the difference back to the purchaser.
            if (crowdsaleTotalAmountAfterPurchase > MAX_CROWDSALE_CAP) {
              uint256 difference = SafeMath.sub(crowdsaleTotalAmountAfterPurchase, MAX_CROWDSALE_CAP);
              uint256 ethValueToReturn = SafeMath.mul(difference, 1e18) / cnyEthRate;
              purchaser.transfer(ethValueToReturn);
              amount = SafeMath.sub(amount, difference);
              rawAmount = amount;
            }

        }

        uint256 covertedAmountwWithBonus = SafeMath.mul(amount, bonusTier) / 100;
        amount = SafeMath.add(amount, covertedAmountwWithBonus); // at this point amount bonus is calculated

        CrowdsalePurchase memory purchase = CrowdsalePurchase(purchaser, amount, rawAmount, timestamp, data, bonusTier);
        crowdsalePurchases.push(purchase);
        return amount;
    }

    /**
     * @dev Fetchs Bonus tier percentage per bonus milestones
     */
    function getBonusTier() internal returns (uint256) {
        bool firstBonusSalesPeriod = now >= startDate && now <= firstBonusSalesEnds; // 1st ~ 7th day get 20% bonus
        bool secondBonusSalesPeriod = now > firstBonusSalesEnds && now <= secondBonusSalesEnds; // 8th ~ 21st day get 15% bonus
        bool thirdBonusSalesPeriod = now > secondBonusSalesEnds && now <= thirdBonusSalesEnds; // 22nd ~ 35th day get 10% bonus
        bool fourthBonusSalesPeriod = now > thirdBonusSalesEnds && now <= fourthBonusSalesEnds; // 36th ~ 42nd day get 5% bonus
        bool fifthBonusSalesPeriod = now > fourthBonusSalesEnds && now <= fifthBonusSalesEnds; // 43rd and 45th day get 0% bonus

        // extended bonus sales
        bool firstExtendedBonusSalesPeriod = now > fifthBonusSalesEnds && now <= firstExtendedBonusSalesEnds; // extended sales 46th ~ 48th day get 20% bonus
        bool secondExtendedBonusSalesPeriod = now > firstExtendedBonusSalesEnds && now <= secondExtendedBonusSalesEnds; // 49th ~ 51st 15% bonus
        bool thirdExtendedBonusSalesPeriod = now > secondExtendedBonusSalesEnds && now <= thirdExtendedBonusSalesEnds; // 52nd ~ 54th day get 10% bonus
        bool fourthExtendedBonusSalesPeriod = now > thirdExtendedBonusSalesEnds && now <= fourthExtendedBonusSalesEnds; // 55th ~ 57th day day get 5% bonus
        bool fifthExtendedBonusSalesPeriod = now > fourthExtendedBonusSalesEnds && now <= fifthExtendedBonusSalesEnds; // 58th ~ 60th day get 0% bonus
        bool sixthExtendedBonusSalesPeriod = now > fifthExtendedBonusSalesEnds && now <= sixthExtendedBonusSalesEnds; // 61st ~ 120th day get {number_of_days} - 60 * 1% bonus

        if (firstBonusSalesPeriod || firstExtendedBonusSalesPeriod) return 20;
        if (secondBonusSalesPeriod || secondExtendedBonusSalesPeriod) return 15;
        if (thirdBonusSalesPeriod || thirdExtendedBonusSalesPeriod) return 10;
        if (fourthBonusSalesPeriod || fourthExtendedBonusSalesPeriod) return 5;
        if (fifthBonusSalesPeriod || fifthExtendedBonusSalesPeriod) return 0;

        if (sixthExtendedBonusSalesPeriod) {
          uint256 DAY_IN_SECONDS = 86400;
          uint256 secondsSinceStartDate = SafeMath.sub(now, startDate);
          uint256 numberOfDays = secondsSinceStartDate / DAY_IN_SECONDS;

          return SafeMath.sub(numberOfDays, 60);
        }
    }

    /**
     * @dev Fetchs Bonus tier percentage per bonus milestones
     * @dev qualifiedPartner Address of partners that participated in pre sale
     * @dev amountSent Value sent by qualified partner
     */
    function sendQualifiedPartnerCommissionFee(address qualifiedPartner, uint256 amountSent) internal {
        //calculate the commission fee to send to qualified partner
        uint256 commissionFeePercentageCalculationAmount = SafeMath.mul(amountSent, qualifiedPartners[qualifiedPartner].commissionFeePercentage) / 100;

        // send commission fee amount
        qualifiedPartner.transfer(commissionFeePercentageCalculationAmount);
    }

    /**
     * @dev redirectToPurchase Redirect to adequate purchase function within the smart contract
     */
    function redirectToPurchase() internal {
        if (block.number < purchaseStartBlock) {
            purchaseAsQualifiedPartner();
        } else {
            purchaseWithEth();
        }
    }
}