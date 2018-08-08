pragma solidity ^0.4.19;

// File: contracts/ClaimRegistry.sol

contract ClaimRegistry {
    function getSingleSubjectByAddress(address linkedAddress, uint subjectIndex) public view returns(address subject);
    function getSubjectClaimSetSize(address subject, uint typeNameIx, uint attrNameIx) public constant returns (uint) ;
    function getSubjectClaimSetEntryAt(address subject, uint typeNameIx, uint attrNameIx, uint ix) public constant returns (address issuer, uint url);
    function getSubjectCountByAddress(address linkedAddress) public view returns(uint subjectCount);
 }

// File: contracts/NotakeyVerifierForICOP.sol

contract NotakeyVerifierForICOP {

    uint public constant ICO_CONTRIBUTOR_TYPE = 6;
    uint public constant REPORT_BUNDLE = 6;
    uint public constant NATIONALITY_INDEX = 7;

    address public claimRegistryAddr;
    address public trustedIssuerAddr;
    // address private callerIdentitySubject;

    uint public constant USA = 883423532389192164791648750371459257913741948437809479060803100646309888;
        // USA is 240nd; blacklist: 1 << (240-1)
    uint public constant CHINA = 8796093022208;
        // China is 44th; blacklist: 1 << (44-1)
    uint public constant SOUTH_KOREA = 83076749736557242056487941267521536;
        // SK is 117th; blacklist: 1 << (117-1)

     event GotUnregisteredPaymentAddress(address indexed paymentAddress);


    function NotakeyVerifierForICOP(address _trustedIssuerAddr, address _claimRegistryAddr) public {
        claimRegistryAddr = _claimRegistryAddr;
        trustedIssuerAddr  = _trustedIssuerAddr;
    }

    modifier onlyVerifiedSenders(address paymentAddress, uint256 nationalityBlacklist) {
        // DISABLED for ICOP sale
        // require(_hasIcoContributorType(paymentAddress));
        require(!_preventedByNationalityBlacklist(paymentAddress, nationalityBlacklist));

        _;
    }

    function sanityCheck() public pure returns (string) {
        return "Hello Dashboard";
    }

    function isVerified(address subject, uint256 nationalityBlacklist) public constant onlyVerifiedSenders(subject, nationalityBlacklist) returns (bool) {
        return true;
    }

    function _preventedByNationalityBlacklist(
        address paymentAddress,
        uint256 nationalityBlacklist) internal constant returns (bool)
    {
        var claimRegistry = ClaimRegistry(claimRegistryAddr);

        uint subjectCount = _lookupOwnerIdentityCount(paymentAddress);

        uint256 ignoredClaims;
        uint claimCount;
        address subject;

        // Loop over all isued identities associated to this wallet adress and
        // throw if any match to blacklist
        for (uint subjectIndex = 0 ; subjectIndex < subjectCount ; subjectIndex++ ){
            subject = claimRegistry.getSingleSubjectByAddress(paymentAddress, subjectIndex);
            claimCount = claimRegistry.getSubjectClaimSetSize(subject, ICO_CONTRIBUTOR_TYPE, NATIONALITY_INDEX);
            ignoredClaims = 0;

            for (uint i = 0; i < claimCount; ++i) {
                var (issuer, url) = claimRegistry.getSubjectClaimSetEntryAt(subject, ICO_CONTRIBUTOR_TYPE, NATIONALITY_INDEX, i);
                var countryMask = 2**(url-1);

                if (issuer != trustedIssuerAddr) {
                    ignoredClaims += 1;
                } else {
                    if (((countryMask ^ nationalityBlacklist) & countryMask) != countryMask) {
                        return true;
                    }
                }
            }
        }

        // If the blacklist is empty (0), then that&#39;s fine for the V1 contract (where we validate the bundle);
        // For our own sale, however, this attribute is a proxy indicator for whether the address is verified.
        //
        // Account for ignored claims (issued by unrecognized issuers)
        require((claimCount - ignoredClaims) > 0);

        return false;
    }

    function _lookupOwnerIdentityCount(address paymentAddress) internal constant returns (uint){
        var claimRegistry = ClaimRegistry(claimRegistryAddr);
        var subjectCount = claimRegistry.getSubjectCountByAddress(paymentAddress);

        // The address is unregistered so we throw and log event
        // This method and callers have to overriden as non-constant to emit events
        // if ( subjectCount == 0 ) {
            // GotUnregisteredPaymentAddress( paymentAddress );
            // revert();
        // }

        require(subjectCount > 0);

        return subjectCount;
    }

    function _hasIcoContributorType(address paymentAddress) internal constant returns (bool)
    {
        uint subjectCount = _lookupOwnerIdentityCount(paymentAddress);

        var atLeastOneValidReport = false;
        var atLeastOneValidNationality = false;
        address subject;

        var claimRegistry = ClaimRegistry(claimRegistryAddr);

        // Loop over all isued identities associated to this wallet address and
        // exit loop any satisfy the business logic requirement
        for (uint subjectIndex = 0 ; subjectIndex < subjectCount ; subjectIndex++ ){
            subject = claimRegistry.getSingleSubjectByAddress(paymentAddress, subjectIndex);

            var nationalityCount = claimRegistry.getSubjectClaimSetSize(subject, ICO_CONTRIBUTOR_TYPE, NATIONALITY_INDEX);
            for (uint nationalityIndex = 0; nationalityIndex < nationalityCount; ++nationalityIndex) {
                var (nationalityIssuer,) = claimRegistry.getSubjectClaimSetEntryAt(subject, ICO_CONTRIBUTOR_TYPE, NATIONALITY_INDEX, nationalityIndex);
                if (nationalityIssuer == trustedIssuerAddr) {
                    atLeastOneValidNationality = true;
                    break;
                }
            }

            var reportCount = claimRegistry.getSubjectClaimSetSize(subject, ICO_CONTRIBUTOR_TYPE, REPORT_BUNDLE);
            for (uint reportIndex = 0; reportIndex < reportCount; ++reportIndex) {
                var (reportIssuer,) = claimRegistry.getSubjectClaimSetEntryAt(subject, ICO_CONTRIBUTOR_TYPE, REPORT_BUNDLE, reportIndex);
                if (reportIssuer == trustedIssuerAddr) {
                    atLeastOneValidReport = true;
                    break;
                }
            }
        }

        return atLeastOneValidNationality && atLeastOneValidReport;
    }
}

// File: contracts/SecondPriceAuction.sol

//! Copyright Parity Technologies, 2017.
//! (original version: https://github.com/paritytech/second-price-auction)
//!
//! Copyright Notakey Latvia SIA, 2017.
//! Original version modified to verify contributors against Notakey
//! KYC smart contract.
//!
//! Released under the Apache Licence 2.

pragma solidity ^0.4.19;



/// Stripped down ERC20 standard token interface.
contract Token {
  function transferFrom(address from, address to, uint256 value) public returns (bool);
}

/// Simple modified second price auction contract. Price starts high and monotonically decreases
/// until all tokens are sold at the current price with currently received funds.
/// The price curve has been chosen to resemble a logarithmic curve
/// and produce a reasonable auction timeline.
contract SecondPriceAuction {
	// Events:

	/// Someone bought in at a particular max-price.
	event Buyin(address indexed who, uint accounted, uint received, uint price);

	/// Admin injected a purchase.
	event Injected(address indexed who, uint accounted, uint received);

	/// At least 5 minutes has passed since last Ticked event.
	event Ticked(uint era, uint received, uint accounted);

	/// The sale just ended with the current price.
	event Ended(uint price);

	/// Finalised the purchase for `who`, who has been given `tokens` tokens.
	event Finalised(address indexed who, uint tokens);

	/// Auction is over. All accounts finalised.
	event Retired();

	// Constructor:

	/// Simple constructor.
	/// Token cap should take be in smallest divisible units.
	/// 	NOTE: original SecondPriceAuction contract stipulates token cap must be given in whole tokens.
	///		This does not seem correct, as only whole token values are transferred via transferFrom (which - in our wallet&#39;s case -
	///     expects transfers in the smallest divisible amount)
	function SecondPriceAuction(
		address _trustedClaimIssuer,
		address _notakeyClaimRegistry,
		address _tokenContract,
		address _treasury,
		address _admin,
		uint _beginTime,
		uint _tokenCap
	)
		public
	{
		// this contract must be created by the notakey claim issuer (sender)
		verifier = new NotakeyVerifierForICOP(_trustedClaimIssuer, _notakeyClaimRegistry);

		tokenContract = Token(_tokenContract);
		treasury = _treasury;
		admin = _admin;
		beginTime = _beginTime;
		tokenCap = _tokenCap;
		endTime = beginTime + DEFAULT_AUCTION_LENGTH;
	}

	function() public payable { buyin(); }

	// Public interaction:
	function moveStartDate(uint newStart)
		public
		before_beginning
		only_admin
	{
		beginTime = newStart;
		endTime = calculateEndTime();
	}

	/// Buyin function. Throws if the sale is not active and when refund would be needed.
	function buyin()
		public
		payable
		when_not_halted
		when_active
		only_eligible(msg.sender)
	{
		flushEra();

		// Flush bonus period:
		if (currentBonus > 0) {
			// Bonus is currently active...
			if (now >= beginTime + BONUS_MIN_DURATION				// ...but outside the automatic bonus period
				&& lastNewInterest + BONUS_LATCH <= block.number	// ...and had no new interest for some blocks
			) {
				currentBonus--;
			}
			if (now >= beginTime + BONUS_MAX_DURATION) {
				currentBonus = 0;
			}
			if (buyins[msg.sender].received == 0) {	// We have new interest
				lastNewInterest = uint32(block.number);
			}
		}

		uint accounted;
		bool refund;
		uint price;
		(accounted, refund, price) = theDeal(msg.value);

		/// No refunds allowed.
		require (!refund);

		// record the acceptance.
		buyins[msg.sender].accounted += uint128(accounted);
		buyins[msg.sender].received += uint128(msg.value);
		totalAccounted += accounted;
		totalReceived += msg.value;
		endTime = calculateEndTime();
		Buyin(msg.sender, accounted, msg.value, price);

		// send to treasury
		treasury.transfer(msg.value);
	}

	/// Like buyin except no payment required and bonus automatically given.
	function inject(address _who, uint128 _received)
		public
		only_admin
		only_basic(_who)
		before_beginning
	{
		uint128 bonus = _received * uint128(currentBonus) / 100;
		uint128 accounted = _received + bonus;

		buyins[_who].accounted += accounted;
		buyins[_who].received += _received;
		totalAccounted += accounted;
		totalReceived += _received;
		endTime = calculateEndTime();
		Injected(_who, accounted, _received);
	}

	/// Mint tokens for a particular participant.
	function finalise(address _who)
		public
		when_not_halted
		when_ended
		only_buyins(_who)
	{
		// end the auction if we&#39;re the first one to finalise.
		if (endPrice == 0) {
			endPrice = totalAccounted / tokenCap;
			Ended(endPrice);
		}

		// enact the purchase.
		uint total = buyins[_who].accounted;
		uint tokens = total / endPrice;
		totalFinalised += total;
		delete buyins[_who];
		require (tokenContract.transferFrom(treasury, _who, tokens));

		Finalised(_who, tokens);

		if (totalFinalised == totalAccounted) {
			Retired();
		}
	}

	// Prviate utilities:

	/// Ensure the era tracker is prepared in case the current changed.
	function flushEra() private {
		uint currentEra = (now - beginTime) / ERA_PERIOD;
		if (currentEra > eraIndex) {
			Ticked(eraIndex, totalReceived, totalAccounted);
		}
		eraIndex = currentEra;
	}

	// Admin interaction:

	/// Emergency function to pause buy-in and finalisation.
	function setHalted(bool _halted) public only_admin { halted = _halted; }

	/// Emergency function to drain the contract of any funds.
	function drain() public only_admin { treasury.transfer(this.balance); }

	// Inspection:

	/// The current end time of the sale assuming that nobody else buys in.
	function calculateEndTime() public constant returns (uint) {
		var factor = tokenCap / DIVISOR * EURWEI;
		uint16 scaleDownRatio = 1; // 1 for prod
		return beginTime + (182035 * factor / (totalAccounted + factor / 10 ) - 0) / scaleDownRatio;
	}

	/// The current price for a single indivisible part of a token. If a buyin happens now, this is
	/// the highest price per indivisible token part that the buyer will pay. This doesn&#39;t
	/// include the discount which may be available.
	function currentPrice() public constant when_active returns (uint weiPerIndivisibleTokenPart) {
		return ((EURWEI * 184325000 / (now - beginTime + 5760) - EURWEI*5) / DIVISOR);
	}

	/// Returns the total indivisible token parts available for purchase right now.
	function tokensAvailable() public constant when_active returns (uint tokens) {
		uint _currentCap = totalAccounted / currentPrice();
		if (_currentCap >= tokenCap) {
			return 0;
		}
		return tokenCap - _currentCap;
	}

	/// The largest purchase than can be made at present, not including any
	/// discount.
	function maxPurchase() public constant when_active returns (uint spend) {
		return tokenCap * currentPrice() - totalAccounted;
	}

	/// Get the number of `tokens` that would be given if the sender were to
	/// spend `_value` now. Also tell you what `refund` would be given, if any.
	function theDeal(uint _value)
		public
		constant
		when_active
		returns (uint accounted, bool refund, uint price)
	{
		uint _bonus = bonus(_value);

		price = currentPrice();
		accounted = _value + _bonus;

		uint available = tokensAvailable();
		uint tokens = accounted / price;
		refund = (tokens > available);
	}

	/// Any applicable bonus to `_value`.
	function bonus(uint _value)
		public
		constant
		when_active
		returns (uint extra)
	{
		return _value * uint(currentBonus) / 100;
	}

	/// True if the sale is ongoing.
	function isActive() public constant returns (bool) { return now >= beginTime && now < endTime; }

	/// True if all buyins have finalised.
	function allFinalised() public constant returns (bool) { return now >= endTime && totalAccounted == totalFinalised; }

	/// Returns true if the sender of this transaction is a basic account.
	function isBasicAccount(address _who) internal constant returns (bool) {
		uint senderCodeSize;
		assembly {
			senderCodeSize := extcodesize(_who)
		}
	    return senderCodeSize == 0;
	}

	// Modifiers:

	/// Ensure the sale is ongoing.
	modifier when_active { require (isActive()); _; }

	/// Ensure the sale has not begun.
	modifier before_beginning { require (now < beginTime); _; }

	/// Ensure the sale is ended.
	modifier when_ended { require (now >= endTime); _; }

	/// Ensure we&#39;re not halted.
	modifier when_not_halted { require (!halted); _; }

	/// Ensure `_who` is a participant.
	modifier only_buyins(address _who) { require (buyins[_who].accounted != 0); _; }

	/// Ensure sender is admin.
	modifier only_admin { require (msg.sender == admin); _; }

	/// Ensure that the signature is valid, `who` is a certified, basic account,
	/// the gas price is sufficiently low and the value is sufficiently high.
	modifier only_eligible(address who) {
		require (
			verifier.isVerified(who, verifier.USA() | verifier.CHINA() | verifier.SOUTH_KOREA()) &&
			isBasicAccount(who) &&
			msg.value >= DUST_LIMIT
		);
		_;
	}

	/// Ensure sender is not a contract.
	modifier only_basic(address who) { require (isBasicAccount(who)); _; }

	// State:

	struct Account {
		uint128 accounted;	// including bonus & hit
		uint128 received;	// just the amount received, without bonus & hit
	}

	/// Those who have bought in to the auction.
	mapping (address => Account) public buyins;

	/// Total amount of ether received, excluding phantom "bonus" ether.
	uint public totalReceived = 0;

	/// Total amount of ether accounted for, including phantom "bonus" ether.
	uint public totalAccounted = 0;

	/// Total amount of ether which has been finalised.
	uint public totalFinalised = 0;

	/// The current end time. Gets updated when new funds are received.
	uint public endTime;

	/// The price per token; only valid once the sale has ended and at least one
	/// participant has finalised.
	uint public endPrice;

	/// Must be false for any public function to be called.
	bool public halted;

	/// The current percentage of bonus that purchasers get.
	uint8 public currentBonus = 15;

	/// The last block that had a new participant.
	uint32 public lastNewInterest;

	// Constants after constructor:

	/// The tokens contract.
	Token public tokenContract;

	/// The Notakey verifier contract.
	NotakeyVerifierForICOP public verifier;

	/// The treasury address; where all the Ether goes.
	address public treasury;

	/// The admin address; auction can be paused or halted at any time by this.
	address public admin;

	/// The time at which the sale begins.
	uint public beginTime;

	/// Maximum amount of tokens to mint. Once totalAccounted / currentPrice is
	/// greater than this, the sale ends.
	uint public tokenCap;

	// Era stuff (isolated)
	/// The era for which the current consolidated data represents.
	uint public eraIndex;

	/// The size of the era in seconds.
	uint constant public ERA_PERIOD = 5 minutes;

	// Static constants:

	/// Anything less than this is considered dust and cannot be used to buy in.
	uint constant public DUST_LIMIT = 5 finney;

	//# Statement to actually sign.
	//# ```js
	//# statement = function() { this.STATEMENT().map(s => s.substr(28)) }
	//# ```

	/// Minimum duration after sale begins that bonus is active.
	uint constant public BONUS_MIN_DURATION = 1 hours;

	/// Minimum duration after sale begins that bonus is active.
	uint constant public BONUS_MAX_DURATION = 12 hours;

	/// Number of consecutive blocks where there must be no new interest before bonus ends.
	uint constant public BONUS_LATCH = 2;

	/// Number of Wei in one EUR, constant.
	uint constant public EURWEI = 2000 szabo; // 500 eur ~ 1 eth

	/// Initial auction length
	uint constant public DEFAULT_AUCTION_LENGTH = 2 days;

	/// Divisor of the token.
	uint constant public DIVISOR = 1000;
}