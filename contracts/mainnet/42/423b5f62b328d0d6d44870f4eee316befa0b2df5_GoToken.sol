pragma solidity ^0.4.18;
/*
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
GoToken, a highly scalable, low cost mobile first network infrastructure for Ethereum
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
*/

contract Token {
/*
---------------------------------------------------------------------------------------------
    ERC20 Token standard implementation
    https://github.com/ethereum/EIPs/blob/f90864a3d2b2b45c4decf95efd26b3f0c276051a/EIPS/eip-20-token-standard.md
    https://github.com/ethereum/EIPs/issues/20

    We didn&#39;t implement a separate totalsupply() function. Instead the public variable
    totalSupply will automatically create a getter function to access the supply
    of the token.
---------------------------------------------------------------------------------------------
*/
    uint256 public totalSupply;

/*
    ERC20 Token Model
*/
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _who, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _who) public constant returns (uint256 remaining);

/*
---------------------------------------------------------------------------------------------
    Events
---------------------------------------------------------------------------------------------
*/
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


/// @title Standard token contract - Standard token implementation.
contract StandardToken is Token {

/*
---------------------------------------------------------------------------------------------
    Storage data structures
---------------------------------------------------------------------------------------------
*/
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

/*
---------------------------------------------------------------------------------------------
    Public facing functions
---------------------------------------------------------------------------------------------
*/

    /// @notice Send "_value" tokens to "_to" from "msg.sender".
    /// @dev Transfers sender&#39;s tokens to a given address. Returns success.
    /// @param _to Address of token receiver.
    /// @param _value Number of tokens to transfer.
    /// @return Returns success of function call.
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    /// @notice Transfer "_value" tokens from "_from" to "_to" if "msg.sender" is allowed.
    /// @dev Allows for an approved third party to transfer tokens from one
    /// address to another. Returns success.
    /// @param _from Address from where tokens are withdrawn.
    /// @param _to Address to where tokens are sent.
    /// @param _value Number of tokens to transfer.
    /// @return Returns success of function call.
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool)
    {
        //Address shouldn&#39;t be null
        require(_from != 0x0);
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);

        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    /// @notice Approves "_who" to transfer "_value" tokens from "msg.sender" to any address.
    /// @dev Sets approved amount of tokens for the spender. Returns success.
    /// @param _who Address of allowed account.
    /// @param _value Number of approved tokens.
    /// @return Returns success of function call.
    function approve(address _who, uint256 _value) public returns (bool) {

        // Address shouldn&#39;t be null
        require(_who != 0x0);

        // To change the approve amount you first have to reduce the addresses`
        // allowance to zero by calling `approve(_who, 0)` if it is not
        // already 0 to mitigate the race condition described here:
        // https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(_value == 0 || allowed[msg.sender][_who] == 0);

        allowed[msg.sender][_who] = _value;
        emit Approval(msg.sender, _who, _value);
        return true;
    }

    /// @dev Returns number of allowed tokens that a spender can transfer on behalf of a token owner.
    /// @param _owner Address of token owner.
    /// @param _who Address of token spender.
    /// @return Returns remaining allowance for spender.
    function allowance(address _owner, address _who) constant public returns (uint256)
    {
        return allowed[_owner][_who];
    }

    /// @dev Returns number of tokens owned by a given address.
    /// @param _owner Address of token owner.
    /// @return Returns balance of owner.
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }
}


/// @title GoToken, a highly scalable, low cost mobile first network infrastructure for Ethereum
contract GoToken is StandardToken {
/*
---------------------------------------------------------------------------------------------
      All GoToken balances are transferable.
      Token name, ticker symbol and decimals
      1 token (GOT) = 1 indivisible unit * multiplier
      The multiplier is set dynamically from token&#39;s number of decimals (i.e. 10 ** decimals)

---------------------------------------------------------------------------------------------
*/

/*
---------------------------------------------------------------------------------------------
    Storage data structures
---------------------------------------------------------------------------------------------
*/
    string constant public name = "GoToken";
    string constant public symbol = "GOT";
    uint256 constant public decimals = 18;
    uint256 constant multiplier = 10 ** (decimals);

/*
---------------------------------------------------------------------------------------------
    Events
---------------------------------------------------------------------------------------------
*/
    event Deployed(uint256 indexed _total_supply);
    //event Burnt(address indexed _receiver, uint256 indexed _num, uint256 indexed _total_supply);

/*
---------------------------------------------------------------------------------------------
    Public facing functions
---------------------------------------------------------------------------------------------
*/

    /// @dev GoToken Contract constructor function sets GoToken dutch auction
    /// contract address and assigns the tokens to the auction.
    /// @param auction_address Address of dutch auction contract.
    /// @param wallet_address Address of wallet.
    /// @param initial_supply Number of initially provided token units (indivisible units).
    function GoToken(address auction_address, address wallet_address, uint256 initial_supply) public
    {
        // Auction address should not be null.
        require(auction_address != 0x0);
        require(wallet_address != 0x0);

        // Initial supply is in indivisible units e.g. 50e24
        require(initial_supply > multiplier);

        // Total supply of indivisible GOT units at deployment
        totalSupply = initial_supply;

        // preallocation
        balances[auction_address] = initial_supply / 2;
        balances[wallet_address] = initial_supply / 2;

        // Record the events
        emit Transfer(0x0, auction_address, balances[auction_address]);
        emit Transfer(0x0, wallet_address, balances[wallet_address]);

        emit Deployed(totalSupply);

        assert(totalSupply == balances[auction_address] + balances[wallet_address]);
    }

}


/// @title GoToken Uniform Price Dutch auction contract - distribution of a fixed
/// number of tokens using second price auction, where everybody gets the same final
/// price when the auction ends i.e. the ending bid becomes the finalized
/// price per token for all participants.
contract GoTokenDutchAuction {
/*
---------------------------------------------------------------------------------------------
    GoToken Uniform Price Dutch auction contract - distribution of a fixed
    number of tokens using seconprice auction, where everybody gets the lowest
    price when the auction ends i.e. the ending bid becomes the finalized
    price per token. This is the mechanism for price discovery.

    The uniform price Dutch auction is set up to discover a fair price for a
    fixed amount of GOT tokens. It starts with a very high price which
    continuously declines with every block over time, based on a predefined
    formula. After the auction is started, participants can send in ETH to bid.
    The auction ends once the price multiplied with the number of offered tokens
    equals the total ETH amount sent to the auction. All participants receive
    their tokens at the same final price.

    The main goals of the auction are to enable everyone to participate while
    offering certainty about the maximum total value of all tokens at the time
    of the bid.

    All token balances are transferable.
    Token name, ticker symbol and decimals
    1 token (GOT) = 1 indivisible unit * multiplier
    multiplier set from token&#39;s number of decimals (i.e. 10 ** decimals)

---------------------------------------------------------------------------------------------
*/

/*
---------------------------------------------------------------------------------------------
    Data structures for Storage
---------------------------------------------------------------------------------------------
*/

    GoToken public token;
    address public owner_address;
    address public wallet_address;
    address public whitelister_address;
    address public distributor_address;

    // Minimum bid value during the auction
    uint256 constant public bid_threshold = 10 finney;

    // Maximum contribution per ETH address during public sale
    //uint256 constant public MAX_CONTRIBUTION_PUBLICSALE = 20 ether;

    // token multiplied derived out of decimals
    uint256 public token_multiplier;

    // Total number of indivisible GoTokens (GOT * token_multiplier) that will be auctioned
    uint256 public num_tokens_auctioned;

/*
---------------------------------------------------------------------------------------------
    Price decay function parameters to be changed depending on the desired outcome
    This is modeled based on composite exponentially decaying curve auction price model.
    The price curves are mathematically modeled per the business needs. There are two
    exponentially decaying curves for teh auction: curve 1 is for teh first eight days
    and curve 2 is for the remaining days until the auction is finalized.
---------------------------------------------------------------------------------------------
*/

    // Starting price in WEI; e.g. 2 * 10 ** 18
    uint256 public price_start;

    uint256 constant public CURVE_CUTOFF_DURATION = 8 days;

    // Price constant for first eight days of the price curve; e.g. 1728
    uint256 public price_constant1;

    // Price exponent for first eight days of the price curve; e.g. 2
    uint256 public price_exponent1;

    // Price constant for eight plus days of the price curve; e.g. 1257
    uint256 public price_constant2;

    // Price exponent for eight plus days of the price curve; e.g. 2
    uint256 public price_exponent2;

    // For private sale start time (same as auction deployement time)
    uint256 public privatesale_start_time;

    // For calculating elapsed time for price auction
    uint256 public auction_start_time;
    uint256 public end_time;
    uint256 public start_block;

    // All ETH received from the bids
    uint256 public received_wei;
    uint256 public received_wei_with_bonus;

    // Cumulative ETH funds for which the tokens have been claimed
    uint256 public funds_claimed;

    // Wei per token (GOT * token_multiplier)
    uint256 public final_price;

    struct Account {
  		uint256 accounted;	// bid value including bonus
  		uint256 received;	// the amount received, without bonus
  	}

    // Address of the Bidder => bid value
    mapping (address => Account) public bids;

    // privatesalewhitelist for private ETH addresses
    mapping (address => bool) public privatesalewhitelist;

    // publicsalewhitelist for addresses that want to bid in public sale excluding private sale accounts
    mapping (address => bool) public publicsalewhitelist;

/*
---------------------------------------------------------------------------------------------
    Bonus tiers
---------------------------------------------------------------------------------------------
*/
    // Maximum duration after sale begins that 15% bonus is active.
  	uint256 constant public BONUS_DAY1_DURATION = 24 hours; ///24 hours;

  	// Maximum duration after sale begins that 10% bonus is active.
  	uint256 constant public BONUS_DAY2_DURATION = 48 hours; ///48 hours;

  	// Maximum duration after sale begins that 5% bonus is active.
  	uint256 constant public BONUS_DAY3_DURATION = 72 hours; ///72 hours;

    // The current percentage of bonus that contributors get.
  	uint256 public currentBonus = 0;

    // Waiting time in days before a participant can claim tokens after the end of the auction
    uint256 constant public TOKEN_CLAIM_WAIT_PERIOD = 0 days;

    // Keep track of stages during the auction and contract deployment process
    Stages public stage;

    enum Stages {
        AuctionDeployed,
        AuctionSetUp,
        AuctionStarted,
        AuctionEnded,
        TokensDistributed
    }

/*
---------------------------------------------------------------------------------------------
    Modifiers
---------------------------------------------------------------------------------------------
*/
    // State of the auction
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

    // Only owner of the contract
    modifier isOwner() {
        require(msg.sender == owner_address);
        _;
    }

    // Only who is allowed to whitelist the participant ETH addresses (specified
    // during the contract deployment)
    modifier isWhitelister() {
        require(msg.sender == whitelister_address);
        _;
    }

    // Only who is allowed to distribute the GOT to the participant ETH addresses (specified
    // during the contract deployment)
    modifier isDistributor() {
        require(msg.sender == distributor_address);
        _;
    }
/*
---------------------------------------------------------------------------------------------
    Events
---------------------------------------------------------------------------------------------
*/

    event Deployed(uint256 indexed _price_start, uint256 _price_constant1, uint256 _price_exponent1, uint256  _price_constant2, uint256 _price_exponent2);
    event Setup();
    event AuctionStarted(uint256 indexed _auction_start_time, uint256 indexed _block_number);
    event BidSubmission(address indexed _sender,uint256 _amount, uint256 _amount_with_bonus, uint256 _remaining_funds_to_end_auction);
    event ClaimedTokens(address indexed _recipient, uint256 _sent_amount);
    event AuctionEnded(uint256 _final_price);
    event TokensDistributed();

    /// whitelisting events for private sale and public sale ETH addresses
  	event PrivateSaleWhitelisted(address indexed who);
    event RemovedFromPrivateSaleWhitelist(address indexed who);
    event PublicSaleWhitelisted(address indexed who);
    event RemovedFromPublicSaleWhitelist(address indexed who);

/*
---------------------------------------------------------------------------------------------
    Public facing functions
---------------------------------------------------------------------------------------------
*/

    /// @dev GoToken Contract constructor function sets the starting price,
    /// price constant and price exponent for calculating the Dutch Auction price.
    /// @param _wallet_address Wallet address to which all contributed ETH will be forwarded.
    function GoTokenDutchAuction(
        address _wallet_address,
        address _whitelister_address,
        address _distributor_address,
        uint256 _price_start,
        uint256 _price_constant1,
        uint256 _price_exponent1,
        uint256 _price_constant2,
        uint256 _price_exponent2)
        public
    {
        // Address shouldn&#39;t be null
        require(_wallet_address != 0x0);
        require(_whitelister_address != 0x0);
        require(_distributor_address != 0x0);
        wallet_address = _wallet_address;
        whitelister_address = _whitelister_address;
        distributor_address = _distributor_address;

        owner_address = msg.sender;
        stage = Stages.AuctionDeployed;
        changePriceCurveSettings(_price_start, _price_constant1, _price_exponent1, _price_constant2, _price_exponent2);
        Deployed(_price_start, _price_constant1, _price_exponent1, _price_constant2, _price_exponent2);
    }

    /// @dev Fallback function for the contract, which calls bid()
    function () public payable {
        bid();
    }

    /// @notice Set "_token_address" as the token address to be used in the auction.
    /// @dev Setup function sets external contracts addresses.
    /// @param _token_address Token address.
    function setup(address _token_address) public isOwner atStage(Stages.AuctionDeployed) {
        require(_token_address != 0x0);
        token = GoToken(_token_address);

        // Get number of GoToken indivisible tokens (GOT * token_multiplier)
        // to be auctioned from token auction balance
        num_tokens_auctioned = token.balanceOf(address(this));

        // Set the number of the token multiplier for its decimals
        token_multiplier = 10 ** (token.decimals());

        // State is set to Auction Setup
        stage = Stages.AuctionSetUp;
        Setup();
    }

    /// @notice Set "_price_start", "_price_constant1" and "_price_exponent1"
    ///  "_price_constant2" and "_price_exponent2" as
    /// the new starting price, price constant and price exponent for the auction price.
    /// @dev Changes auction price function parameters before auction is started.
    /// @param _price_start Updated start price.
    /// @param _price_constant1 Updated price divisor constant.
    /// @param _price_exponent1 Updated price divisor exponent.
    /// @param _price_constant2 Updated price divisor constant.
    /// @param _price_exponent2 Updated price divisor exponent.
    function changePriceCurveSettings(
        uint256 _price_start,
        uint256 _price_constant1,
        uint256 _price_exponent1,
        uint256 _price_constant2,
        uint256 _price_exponent2)
        internal
    {
        // You can change the price curve settings only when either the auction is Deployed
        // or the auction is setup. You can&#39;t change during the auction is running or ended.
        require(stage == Stages.AuctionDeployed || stage == Stages.AuctionSetUp);
        require(_price_start > 0);
        require(_price_constant1 > 0);
        require(_price_constant2 > 0);

        price_start = _price_start;
        price_constant1 = _price_constant1;
        price_exponent1 = _price_exponent1;
        price_constant2 = _price_constant2;
        price_exponent2 = _price_exponent2;
    }

/*
---------------------------------------------------------------------------------------------
    Functions related to whitelisting of presale and public sale ETH addresses.
    The Whitelister must add the participant&#39;s ETH address before they can bid.
---------------------------------------------------------------------------------------------
*/
    // @notice Adds account addresses to public sale ETH whitelist.
    // @dev Adds account addresses to public sale ETH whitelist.
    // @param _bidder_addresses Array of addresses. Use double quoted array.
    function addToPublicSaleWhitelist(address[] _bidder_addresses) public isWhitelister {
        for (uint32 i = 0; i < _bidder_addresses.length; i++) {
            require(!privatesalewhitelist[_bidder_addresses[i]]); //Can&#39;t be in public whitelist
            publicsalewhitelist[_bidder_addresses[i]] = true;
            PublicSaleWhitelisted(_bidder_addresses[i]);
        }
    }

    // @notice Removes account addresses from public sale ETH whitelist.
    // @dev Removes account addresses from public sale ETH whitelist.
    // @param _bidder_addresses Array of addresses.  Use double quoted array.
    function removeFromPublicSaleWhitelist(address[] _bidder_addresses) public isWhitelister {
        for (uint32 i = 0; i < _bidder_addresses.length; i++) {
            publicsalewhitelist[_bidder_addresses[i]] = false;
            RemovedFromPublicSaleWhitelist(_bidder_addresses[i]);
        }
    }

    // Private sale contributors whitelist. Only Admin can add or remove

  	// @notice Adds presale account addresses to privatesalewhitelist.
    // @ Admin Adds presale account addresses to privatesalewhitelist.
    // @param _bidder_addresses Array of addresses.
    function addToPrivateSaleWhitelist(address[] _bidder_addresses) public isOwner {
        for (uint32 i = 0; i < _bidder_addresses.length; i++) {
              privatesalewhitelist[_bidder_addresses[i]] = true;
  						PrivateSaleWhitelisted(_bidder_addresses[i]);
          }
      }

      // @notice Removes presale account addresses from privatesalewhitelist.
      // @ Admin Removes presale account addresses from privatesalewhitelist.
      // @param _bidder_addresses Array of addresses.
      function removeFromPrivateSaleWhitelist(address[] _bidder_addresses) public isOwner {
          for (uint32 i = 0; i < _bidder_addresses.length; i++) {
              privatesalewhitelist[_bidder_addresses[i]] = false;
  						RemovedFromPrivateSaleWhitelist(_bidder_addresses[i]);
          }
      }

    // @notice Start the auction.
    // @dev Starts auction and sets auction_start_time.
    function startAuction() public isOwner atStage(Stages.AuctionSetUp) {
        stage = Stages.AuctionStarted;
        auction_start_time = now;
        start_block = block.number;
        AuctionStarted(auction_start_time, start_block);
    }

    /// @notice Send "msg.value" WEI to the auction from the "msg.sender" account.
    /// @dev Allows to send a bid to the auction.
    function bid() public payable
    {
        // Address shouldn&#39;t be null and the minimum bid amount of contribution is met.
        // Private sale contributor can submit a bid at AuctionSetUp before AuctionStarted
        // When AuctionStarted only private sale and public sale whitelisted ETH addresses can participate
        require(stage == Stages.AuctionSetUp || stage == Stages.AuctionStarted);
        require(privatesalewhitelist[msg.sender] || publicsalewhitelist[msg.sender]);
        if (stage == Stages.AuctionSetUp){
          require(privatesalewhitelist[msg.sender]);
        }
        require(msg.value > 0);
        require(bids[msg.sender].received + msg.value >= bid_threshold);
        assert(bids[msg.sender].received + msg.value >= msg.value);

        // Maximum public sale contribution per ETH account
        //if (stage == Stages.AuctionStarted && publicsalewhitelist[msg.sender]) {
        //  require (bids[msg.sender].received + msg.value <= MAX_CONTRIBUTION_PUBLICSALE);
        //}

        // Remaining funds without the current bid value to end the auction
        uint256 remaining_funds_to_end_auction = remainingFundsToEndAuction();

        // The bid value must be less than the funds remaining to end the auction
        // at the current price.
        require(msg.value <= remaining_funds_to_end_auction);

/*
---------------------------------------------------------------------------------------------
        Bonus period settings
---------------------------------------------------------------------------------------------
*/
        //Private sale bids before Auction starts
        if (stage == Stages.AuctionSetUp){
          require(privatesalewhitelist[msg.sender]);
          currentBonus = 25; //private sale bonus before AuctionStarted
        }
        else if (stage == Stages.AuctionStarted) {
          // private sale contributors bonus period settings
      		if (privatesalewhitelist[msg.sender] && now >= auction_start_time  && now < auction_start_time + BONUS_DAY1_DURATION) {
      				currentBonus = 25; //private sale contributor Day 1 bonus
      		}
          else if (privatesalewhitelist[msg.sender] && now >= auction_start_time + BONUS_DAY1_DURATION && now < auction_start_time + BONUS_DAY2_DURATION ) {
      				currentBonus = 25; //private sale contributor Day 2 bonus
      		}
      		else if (privatesalewhitelist[msg.sender] && now >= auction_start_time + BONUS_DAY2_DURATION && now < auction_start_time + BONUS_DAY3_DURATION) {
      				currentBonus = 25; //private sale contributor Day 3 bonus
      		}
          else if (privatesalewhitelist[msg.sender] && now >= auction_start_time + BONUS_DAY3_DURATION) {
              currentBonus = 25; //private sale contributor Day 4+ bonus
          }
          else if (publicsalewhitelist[msg.sender] && now >= auction_start_time  && now < auction_start_time + BONUS_DAY1_DURATION) {
      				currentBonus = 15; //private sale contributor Day 1 bonus
      		}
          else if (publicsalewhitelist[msg.sender] && now >= auction_start_time + BONUS_DAY1_DURATION && now < auction_start_time + BONUS_DAY2_DURATION ) {
      				currentBonus = 10; //private sale contributor Day 2 bonus
      		}
      		else if (publicsalewhitelist[msg.sender] && now >= auction_start_time + BONUS_DAY2_DURATION && now < auction_start_time + BONUS_DAY3_DURATION) {
      				currentBonus = 5; //private sale contributor Day 3 bonus
      		}
          else if (publicsalewhitelist[msg.sender] && now >= auction_start_time + BONUS_DAY3_DURATION) {
              currentBonus = 0; //private sale contributor Day 4+ bonus
          }
      		else {
      				currentBonus = 0;
      		}
        }
        else {
          currentBonus = 0;
        }

        // amount raised including bonus
        uint256 accounted = msg.value + msg.value * (currentBonus) / 100;

        // Save the bid amount received with and without bonus.
    		bids[msg.sender].accounted += accounted; //including bonus
    		bids[msg.sender].received += msg.value;

        // keep track of total amount raised and with bonus
        received_wei += msg.value;
        received_wei_with_bonus += accounted;

        // Send bid amount to wallet
        wallet_address.transfer(msg.value);

        //Log the bid
        BidSubmission(msg.sender, msg.value, accounted, remaining_funds_to_end_auction);

        assert(received_wei >= msg.value);
        assert(received_wei_with_bonus >= accounted);
    }

    // @notice Finalize the auction - sets the final GoToken price and
    // changes the auction stage after no bids are allowed. Only owner can finalize the auction.
    // The owner can end the auction anytime after either the auction is deployed or started.
    // @dev Finalize auction and set the final GOT token price.
    function finalizeAuction() public isOwner
    {
        // The owner can end the auction anytime during the stages
        // AuctionSetUp and AuctionStarted
        require(stage == Stages.AuctionSetUp || stage == Stages.AuctionStarted);

        // Calculate the final price = WEI / (GOT / token_multiplier)
        final_price = token_multiplier * received_wei_with_bonus / num_tokens_auctioned;

        // End the auction
        end_time = now;
        stage = Stages.AuctionEnded;
        AuctionEnded(final_price);

        assert(final_price > 0);
    }

    // @notice Distribute GoTokens for "receiver_address" after the auction has ended by the owner.
    // @dev Distribute GoTokens for "receiver_address" after auction has ended by the owner.
    // @param receiver_address GoTokens will be assigned to this address if eligible.
    function distributeGoTokens(address receiver_address)
        public isDistributor atStage(Stages.AuctionEnded) returns (bool)
    {
        // Waiting period in days after the end of the auction, before anyone can claim GoTokens.
        // Ensures enough time to check if auction was finalized correctly
        // before users start transacting tokens
        require(now > end_time + TOKEN_CLAIM_WAIT_PERIOD);
        require(receiver_address != 0x0);
        require(bids[receiver_address].received > 0);

        if (bids[receiver_address].received == 0 || bids[receiver_address].accounted == 0) {
            return false;
        }

        // Number of GOT = bid_wei_with_bonus / (wei_per_GOT * token_multiplier)
        // Includes the bonus
        uint256 num = (token_multiplier * bids[receiver_address].accounted) / final_price;

        // Due to final_price rounding, the number of assigned tokens may be higher
        // than expected. Therefore, the number of remaining unassigned auction tokens
        // may be smaller than the number of tokens needed for the last claimTokens call
        uint256 auction_tokens_balance = token.balanceOf(address(this));
        if (num > auction_tokens_balance) {
            num = auction_tokens_balance;
        }

        // Update the total amount of funds for which tokens have been claimed
        funds_claimed += bids[receiver_address].received;

        // Set receiver bid to 0 before assigning tokens
        bids[receiver_address].accounted = 0;
        bids[receiver_address].received = 0;

        // Send the GoTokens to the receiver address including the qualified bonus
        require(token.transfer(receiver_address, num));

        // Log the event for claimed GoTokens
        ClaimedTokens(receiver_address, num);

        // After the last tokens are claimed, change the auction stage
        // Due to the above logic described, rounding errors will not be an issue here.
        if (funds_claimed == received_wei) {
            stage = Stages.TokensDistributed;
            TokensDistributed();
        }

        assert(token.balanceOf(receiver_address) >= num);
        assert(bids[receiver_address].accounted == 0);
        assert(bids[receiver_address].received == 0);
        return true;
    }

    /// @notice Get the GOT price in WEI during the auction, at the time of
    /// calling this function. Returns 0 if auction has ended.
    /// Returns "price_start" before auction has started.
    /// @dev Calculates the current GOT token price in WEI.
    /// @return Returns WEI per indivisible GOT (token_multiplier * GOT).
    function price() public constant returns (uint256) {
        if (stage == Stages.AuctionEnded ||
            stage == Stages.TokensDistributed) {
            return 0;
        }
        return calcTokenPrice();
    }

    /// @notice Get the remaining funds needed to end the auction, calculated at
    /// the current GOT price in WEI.
    /// @dev The remaining funds necessary to end the auction at the current GOT price in WEI.
    /// @return Returns the remaining funds to end the auction in WEI.
    function remainingFundsToEndAuction() constant public returns (uint256) {

        // num_tokens_auctioned = total number of indivisible GOT (GOT * token_multiplier) that is auctioned
        uint256 required_wei_at_price = num_tokens_auctioned * price() / token_multiplier;
        if (required_wei_at_price <= received_wei) {
            return 0;
        }

        return required_wei_at_price - received_wei;
    }

/*
---------------------------------------------------------------------------------------------
    Private function for calcuclating current token price
---------------------------------------------------------------------------------------------
*/

    // @dev Calculates the token price (WEI / GOT) at the current timestamp
    // during the auction; elapsed time = 0 before auction starts.
    // This is a composite exponentially decaying curve (two curves combined).
    // The curve 1 is for the first 8 days and the curve 2 is for the remaining days.
    // They are of the form:
    //         current_price  = price_start * (1 + elapsed) / (1 + elapsed + decay_rate);
    //          where, decay_rate = elapsed ** price_exponent / price_constant;
    // Based on the provided parameters, the price does not change in the first
    // price_constant^(1/price_exponent) seconds due to rounding.
    // Rounding in `decay_rate` also produces values that increase instead of decrease
    // in the beginning of the auction; these spikes decrease over time and are noticeable
    // only in first hours. This should be calculated before usage.
    // @return Returns the token price - WEI per GOT.

    function calcTokenPrice() constant private returns (uint256) {
        uint256 elapsed;
        uint256 decay_rate1;
        uint256 decay_rate2;
        if (stage == Stages.AuctionDeployed || stage == Stages.AuctionSetUp){
          return price_start;
        }
        if (stage == Stages.AuctionStarted) {
            elapsed = now - auction_start_time;
            // The first eight days auction price curve
            if (now >= auction_start_time && now < auction_start_time + CURVE_CUTOFF_DURATION){
              decay_rate1 = elapsed ** price_exponent1 / price_constant1;
              return price_start * (1 + elapsed) / (1 + elapsed + decay_rate1);
            }
            // The remaining days auction price curve
            else if (now >= auction_start_time && now >= auction_start_time + CURVE_CUTOFF_DURATION){
              decay_rate2 = elapsed ** price_exponent2 / price_constant2;
              return price_start * (1 + elapsed) / (1 + elapsed + decay_rate2);
            }
            else {
              return price_start;
            }

        }
    }

}