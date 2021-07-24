/**
 *Submitted for verification at polygonscan.com on 2021-07-24
*/

/**
 *Submitted for verification at Etherscan.io on 2017-10-18
*/

pragma solidity ^0.4.17;

/// @title ERC223ReceivingContract - Standard contract implementation for compatibility with ERC223 tokens.
contract ERC223ReceivingContract {

    /// @dev Function that is called when a user or another contract wants to transfer funds.
    /// @param _from Transaction initiator, analogue of msg.sender
    /// @param _value Number of tokens to transfer.
    /// @param _data Data containig a function signature and/or parameters
    function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

contract Token {
    /*
     * Implements ERC 20 standard.
     * https://github.com/ethereum/EIPs/blob/f90864a3d2b2b45c4decf95efd26b3f0c276051a/EIPS/eip-20-token-standard.md
     * https://github.com/ethereum/EIPs/issues/20
     *
     *  Added support for the ERC 223 "tokenFallback" method in a "transfer" function with a payload.
     *  https://github.com/ethereum/EIPs/issues/223
     */

    /*
     * This is a slight change to the ERC20 base standard.
     * function totalSupply() constant returns (uint256 supply);
     * is replaced with:
     * uint256 public totalSupply;
     * This automatically creates a getter function for the totalSupply.
     * This is moved to the base contract since public getter functions are not
     * currently recognised as an implementation of the matching abstract
     * function by the compiler.
     */
    uint256 public totalSupply;

    /*
     * ERC 20
     */
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    /*
     * ERC 223
     */
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool success);

    /*
     * Events
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // There is no ERC223 compatible Transfer event, with `_data` included.
}


/// @title Standard token contract - Standard token implementation.
contract StandardToken is Token {

    /*
     * Data structures
     */
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    /*
     * Public functions
     */
    /// @notice Send `_value` tokens to `_to` from `msg.sender`.
    /// @dev Transfers sender's tokens to a given address. Returns success.
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

        Transfer(msg.sender, _to, _value);

        return true;
    }

    /// @notice Send `_value` tokens to `_to` from `msg.sender` and trigger
    /// tokenFallback if sender is a contract.
    /// @dev Function that is called when a user or another contract wants to transfer funds.
    /// @param _to Address of token receiver.
    /// @param _value Number of tokens to transfer.
    /// @param _data Data to be sent to tokenFallback
    /// @return Returns success of function call.
    function transfer(
        address _to,
        uint256 _value,
        bytes _data)
        public
        returns (bool)
    {
        require(transfer(_to, _value));

        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly.
            codeLength := extcodesize(_to)
        }

        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }

        return true;
    }

    /// @notice Transfer `_value` tokens from `_from` to `_to` if `msg.sender` is allowed.
    /// @dev Allows for an approved third party to transfer tokens from one
    /// address to another. Returns success.
    /// @param _from Address from where tokens are withdrawn.
    /// @param _to Address to where tokens are sent.
    /// @param _value Number of tokens to transfer.
    /// @return Returns success of function call.
    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool)
    {
        require(_from != 0x0);
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);

        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;

        Transfer(_from, _to, _value);

        return true;
    }

    /// @notice Allows `_spender` to transfer `_value` tokens from `msg.sender` to any address.
    /// @dev Sets approved amount of tokens for spender. Returns success.
    /// @param _spender Address of allowed account.
    /// @param _value Number of approved tokens.
    /// @return Returns success of function call.
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != 0x0);

        // To change the approve amount you first have to reduce the addresses`
        // allowance to zero by calling `approve(_spender, 0)` if it is not
        // already 0 to mitigate the race condition described here:
        // https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(_value == 0 || allowed[msg.sender][_spender] == 0);

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /*
     * Read functions
     */
    /// @dev Returns number of allowed tokens that a spender can transfer on
    /// behalf of a token owner.
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    /// @return Returns remaining allowance for spender.
    function allowance(address _owner, address _spender)
        constant
        public
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /// @dev Returns number of tokens owned by the given address.
    /// @param _owner Address of token owner.
    /// @return Returns balance of owner.
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }
}


/// @title Raiden Token
contract RaidenToken is StandardToken {

    /*
     *  Terminology:
     *  1 token unit = Rei
     *  1 token = RDN = Rei * multiplier
     *  multiplier set from token's number of decimals (i.e. 10 ** decimals)
     */

    /*
     *  Token metadata
     */
    string constant public name = "Raiden Token";
    string constant public symbol = "RDN";
    uint8 constant public decimals = 18;
    uint constant multiplier = 10 ** uint(decimals);

    event Deployed(uint indexed _total_supply);
    event Burnt(
        address indexed _receiver,
        uint indexed _num,
        uint indexed _total_supply
    );

    /*
     *  Public functions
     */
    /// @dev Contract constructor function sets dutch auction contract address
    /// and assigns all tokens to dutch auction.
    /// @param auction_address Address of dutch auction contract.
    /// @param wallet_address Address of wallet.
    /// @param initial_supply Number of initially provided token units (Rei).
    function RaidenToken(
        address auction_address,
        address wallet_address,
        uint initial_supply)
        public
    {
        // Auction address should not be null.
        require(auction_address != 0x0);
        require(wallet_address != 0x0);

        // Initial supply is in Rei
        require(initial_supply > multiplier);

        // Total supply of Rei at deployment
        totalSupply = initial_supply;

        balances[auction_address] = initial_supply / 2;
        balances[wallet_address] = initial_supply / 2;

        Transfer(0x0, auction_address, balances[auction_address]);
        Transfer(0x0, wallet_address, balances[wallet_address]);

        Deployed(totalSupply);

        assert(totalSupply == balances[auction_address] + balances[wallet_address]);
    }

    /// @notice Allows `msg.sender` to simply destroy `num` token units (Rei). This means the total
    /// token supply will decrease.
    /// @dev Allows to destroy token units (Rei).
    /// @param num Number of token units (Rei) to burn.
    function burn(uint num) public {
        require(num > 0);
        require(balances[msg.sender] >= num);
        require(totalSupply >= num);

        uint pre_balance = balances[msg.sender];

        balances[msg.sender] -= num;
        totalSupply -= num;
        Burnt(msg.sender, num, totalSupply);
        Transfer(msg.sender, 0x0, num);

        assert(balances[msg.sender] == pre_balance - num);
    }

}


/// @title Dutch auction contract - distribution of a fixed number of tokens using an auction.
/// The contract code is inspired by the Gnosis auction contract. Main difference is that the
/// auction ends if a fixed number of tokens was sold.
contract DutchAuction {
    /*
     * Auction for the RDN Token.
     *
     * Terminology:
     * 1 token unit = Rei
     * 1 token = RDN = Rei * token_multiplier
     * token_multiplier set from token's number of decimals (i.e. 10 ** decimals)
     */

    // Wait 7 days after the end of the auction, before anyone can claim tokens
    uint constant public token_claim_waiting_period = 7 days;

    // Bid value over which the address has to be whitelisted
    // At deployment moment, less than 1k$
    uint constant public bid_threshold = 2.5 ether;

    /*
     * Storage
     */

    RaidenToken public token;
    address public owner_address;
    address public wallet_address;
    address public whitelister_address;

    // Price decay function parameters to be changed depending on the desired outcome

    // Starting price in WEI; e.g. 2 * 10 ** 18
    uint public price_start;

    // Divisor constant; e.g. 524880000
    uint public price_constant;

    // Divisor exponent; e.g. 3
    uint32 public price_exponent;

    // For calculating elapsed time for price
    uint public start_time;
    uint public end_time;
    uint public start_block;

    // Keep track of all ETH received in the bids
    uint public received_wei;

    // Keep track of cumulative ETH funds for which the tokens have been claimed
    uint public funds_claimed;

    uint public token_multiplier;

    // Total number of Rei (RDN * token_multiplier) that will be auctioned
    uint public num_tokens_auctioned;

    // Wei per RDN (Rei * token_multiplier)
    uint public final_price;

    // Bidder address => bid value
    mapping (address => uint) public bids;

    // Whitelist for addresses that want to bid more than bid_threshold
    mapping (address => bool) public whitelist;

    Stages public stage;

    /*
     * Enums
     */
    enum Stages {
        AuctionDeployed,
        AuctionSetUp,
        AuctionStarted,
        AuctionEnded,
        TokensDistributed
    }

    /*
     * Modifiers
     */
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

    modifier isOwner() {
        require(msg.sender == owner_address);
        _;
    }

    modifier isWhitelister() {
        require(msg.sender == whitelister_address);
        _;
    }

    /*
     * Events
     */

    event Deployed(
        uint indexed _price_start,
        uint indexed _price_constant,
        uint32 indexed _price_exponent
    );
    event Setup();
    event AuctionStarted(uint indexed _start_time, uint indexed _block_number);
    event BidSubmission(
        address indexed _sender,
        uint _amount,
        uint _missing_funds
    );
    event ClaimedTokens(address indexed _recipient, uint _sent_amount);
    event AuctionEnded(uint _final_price);
    event TokensDistributed();

    /*
     * Public functions
     */

    /// @dev Contract constructor function sets the starting price, divisor constant and
    /// divisor exponent for calculating the Dutch Auction price.
    /// @param _wallet_address Wallet address to which all contributed ETH will be forwarded.
    /// @param _price_start High price in WEI at which the auction starts.
    /// @param _price_constant Auction price divisor constant.
    /// @param _price_exponent Auction price divisor exponent.
    function DutchAuction(
        address _wallet_address,
        address _whitelister_address,
        uint _price_start,
        uint _price_constant,
        uint32 _price_exponent)
        public
    {
        require(_wallet_address != 0x0);
        require(_whitelister_address != 0x0);
        wallet_address = _wallet_address;
        whitelister_address = _whitelister_address;

        owner_address = msg.sender;
        stage = Stages.AuctionDeployed;
        changeSettings(_price_start, _price_constant, _price_exponent);
        Deployed(_price_start, _price_constant, _price_exponent);
    }

    /// @dev Fallback function for the contract, which calls bid() if the auction has started.
    function () public payable atStage(Stages.AuctionStarted) {
        bid();
    }

    /// @notice Set `_token_address` as the token address to be used in the auction.
    /// @dev Setup function sets external contracts addresses.
    /// @param _token_address Token address.
    function setup(address _token_address) public isOwner atStage(Stages.AuctionDeployed) {
        require(_token_address != 0x0);
        token = RaidenToken(_token_address);

        // Get number of Rei (RDN * token_multiplier) to be auctioned from token auction balance
        num_tokens_auctioned = token.balanceOf(address(this));

        // Set the number of the token multiplier for its decimals
        token_multiplier = 10 ** uint(token.decimals());

        stage = Stages.AuctionSetUp;
        Setup();
    }

    /// @notice Set `_price_start`, `_price_constant` and `_price_exponent` as
    /// the new starting price, price divisor constant and price divisor exponent.
    /// @dev Changes auction price function parameters before auction is started.
    /// @param _price_start Updated start price.
    /// @param _price_constant Updated price divisor constant.
    /// @param _price_exponent Updated price divisor exponent.
    function changeSettings(
        uint _price_start,
        uint _price_constant,
        uint32 _price_exponent)
        internal
    {
        require(stage == Stages.AuctionDeployed || stage == Stages.AuctionSetUp);
        require(_price_start > 0);
        require(_price_constant > 0);

        price_start = _price_start;
        price_constant = _price_constant;
        price_exponent = _price_exponent;
    }

    /// @notice Adds account addresses to whitelist.
    /// @dev Adds account addresses to whitelist.
    /// @param _bidder_addresses Array of addresses.
    function addToWhitelist(address[] _bidder_addresses) public isWhitelister {
        for (uint32 i = 0; i < _bidder_addresses.length; i++) {
            whitelist[_bidder_addresses[i]] = true;
        }
    }

    /// @notice Removes account addresses from whitelist.
    /// @dev Removes account addresses from whitelist.
    /// @param _bidder_addresses Array of addresses.
    function removeFromWhitelist(address[] _bidder_addresses) public isWhitelister {
        for (uint32 i = 0; i < _bidder_addresses.length; i++) {
            whitelist[_bidder_addresses[i]] = false;
        }
    }

    /// @notice Start the auction.
    /// @dev Starts auction and sets start_time.
    function startAuction() public isOwner atStage(Stages.AuctionSetUp) {
        stage = Stages.AuctionStarted;
        start_time = now;
        start_block = block.number;
        AuctionStarted(start_time, start_block);
    }

    /// @notice Finalize the auction - sets the final RDN token price and changes the auction
    /// stage after no bids are allowed anymore.
    /// @dev Finalize auction and set the final RDN token price.
    function finalizeAuction() public atStage(Stages.AuctionStarted)
    {
        // Missing funds should be 0 at this point
        uint missing_funds = missingFundsToEndAuction();
        require(missing_funds == 0);

        // Calculate the final price = WEI / RDN = WEI / (Rei / token_multiplier)
        // Reminder: num_tokens_auctioned is the number of Rei (RDN * token_multiplier) that are auctioned
        final_price = token_multiplier * received_wei / num_tokens_auctioned;

        end_time = now;
        stage = Stages.AuctionEnded;
        AuctionEnded(final_price);

        assert(final_price > 0);
    }

    /// --------------------------------- Auction Functions ------------------


    /// @notice Send `msg.value` WEI to the auction from the `msg.sender` account.
    /// @dev Allows to send a bid to the auction.
    function bid()
        public
        payable
        atStage(Stages.AuctionStarted)
    {
        require(msg.value > 0);
        require(bids[msg.sender] + msg.value <= bid_threshold || whitelist[msg.sender]);
        assert(bids[msg.sender] + msg.value >= msg.value);

        // Missing funds without the current bid value
        uint missing_funds = missingFundsToEndAuction();

        // We require bid values to be less than the funds missing to end the auction
        // at the current price.
        require(msg.value <= missing_funds);

        bids[msg.sender] += msg.value;
        received_wei += msg.value;

        // Send bid amount to wallet
        wallet_address.transfer(msg.value);

        BidSubmission(msg.sender, msg.value, missing_funds);

        assert(received_wei >= msg.value);
    }

    /// @notice Claim auction tokens for `msg.sender` after the auction has ended.
    /// @dev Claims tokens for `msg.sender` after auction. To be used if tokens can
    /// be claimed by beneficiaries, individually.
    function claimTokens() public atStage(Stages.AuctionEnded) returns (bool) {
        return proxyClaimTokens(msg.sender);
    }

    /// @notice Claim auction tokens for `receiver_address` after the auction has ended.
    /// @dev Claims tokens for `receiver_address` after auction has ended.
    /// @param receiver_address Tokens will be assigned to this address if eligible.
    function proxyClaimTokens(address receiver_address)
        public
        atStage(Stages.AuctionEnded)
        returns (bool)
    {
        // Waiting period after the end of the auction, before anyone can claim tokens
        // Ensures enough time to check if auction was finalized correctly
        // before users start transacting tokens
        require(now > end_time + token_claim_waiting_period);
        require(receiver_address != 0x0);

        if (bids[receiver_address] == 0) {
            return false;
        }

        // Number of Rei = bid_wei / Rei = bid_wei / (wei_per_RDN * token_multiplier)
        uint num = (token_multiplier * bids[receiver_address]) / final_price;

        // Due to final_price floor rounding, the number of assigned tokens may be higher
        // than expected. Therefore, the number of remaining unassigned auction tokens
        // may be smaller than the number of tokens needed for the last claimTokens call
        uint auction_tokens_balance = token.balanceOf(address(this));
        if (num > auction_tokens_balance) {
            num = auction_tokens_balance;
        }

        // Update the total amount of funds for which tokens have been claimed
        funds_claimed += bids[receiver_address];

        // Set receiver bid to 0 before assigning tokens
        bids[receiver_address] = 0;

        require(token.transfer(receiver_address, num));

        ClaimedTokens(receiver_address, num);

        // After the last tokens are claimed, we change the auction stage
        // Due to the above logic, rounding errors will not be an issue
        if (funds_claimed == received_wei) {
            stage = Stages.TokensDistributed;
            TokensDistributed();
        }

        assert(token.balanceOf(receiver_address) >= num);
        assert(bids[receiver_address] == 0);
        return true;
    }

    /// @notice Get the RDN price in WEI during the auction, at the time of
    /// calling this function. Returns `0` if auction has ended.
    /// Returns `price_start` before auction has started.
    /// @dev Calculates the current RDN token price in WEI.
    /// @return Returns WEI per RDN (token_multiplier * Rei).
    function price() public constant returns (uint) {
        if (stage == Stages.AuctionEnded ||
            stage == Stages.TokensDistributed) {
            return 0;
        }
        return calcTokenPrice();
    }

    /// @notice Get the missing funds needed to end the auction,
    /// calculated at the current RDN price in WEI.
    /// @dev The missing funds amount necessary to end the auction at the current RDN price in WEI.
    /// @return Returns the missing funds amount in WEI.
    function missingFundsToEndAuction() constant public returns (uint) {

        // num_tokens_auctioned = total number of Rei (RDN * token_multiplier) that is auctioned
        uint required_wei_at_price = num_tokens_auctioned * price() / token_multiplier;
        if (required_wei_at_price <= received_wei) {
            return 0;
        }

        // assert(required_wei_at_price - received_wei > 0);
        return required_wei_at_price - received_wei;
    }

    /*
     *  Private functions
     */

    /// @dev Calculates the token price (WEI / RDN) at the current timestamp
    /// during the auction; elapsed time = 0 before auction starts.
    /// Based on the provided parameters, the price does not change in the first
    /// `price_constant^(1/price_exponent)` seconds due to rounding.
    /// Rounding in `decay_rate` also produces values that increase instead of decrease
    /// in the beginning; these spikes decrease over time and are noticeable
    /// only in first hours. This should be calculated before usage.
    /// @return Returns the token price - Wei per RDN.
    function calcTokenPrice() constant private returns (uint) {
        uint elapsed;
        if (stage == Stages.AuctionStarted) {
            elapsed = now - start_time;
        }

        uint decay_rate = elapsed ** price_exponent / price_constant;
        return price_start * (1 + elapsed) / (1 + elapsed + decay_rate);
    }
}