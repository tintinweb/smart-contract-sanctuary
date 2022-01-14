/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-14
*/

pragma solidity ^0.4.25;

interface IToken {
    function approve(address spender, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address who) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface ISwap {

    /**
      * @dev Pricing function for converting between BNB && Tokens.
      * @param input_amount Amount of BNB or Tokens being sold.
      * @param input_reserve Amount of BNB or Tokens (input type) in exchange reserves.
      * @param output_reserve Amount of BNB or Tokens (output type) in exchange reserves.
      * @return Amount of BNB or Tokens bought.
      */
    function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);

    /**
      * @dev Pricing function for converting between BNB && Tokens.
      * @param output_amount Amount of BNB or Tokens being bought.
      * @param input_reserve Amount of BNB or Tokens (input type) in exchange reserves.
      * @param output_reserve Amount of BNB or Tokens (output type) in exchange reserves.
      * @return Amount of BNB or Tokens sold.
      */
    function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);
    /**
     * @notice Convert BNB to Tokens.
     * @dev User specifies exact input (msg.value) && minimum output.
     * @param min_tokens Minimum Tokens bought.
     * @return Amount of Tokens bought.
     */
    function bnbToTokenSwapInput(uint256 min_tokens) external payable returns (uint256);

    /**
     * @notice Convert BNB to Tokens.
     * @dev User specifies maximum input (msg.value) && exact output.
     * @param tokens_bought Amount of tokens bought.
     * @return Amount of BNB sold.
     */
    function bnbToTokenSwapOutput(uint256 tokens_bought) external payable returns (uint256);

    /**
     * @notice Convert Tokens to BNB.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_bnb Minimum BNB purchased.
     * @return Amount of BNB bought.
     */
    function tokenToBnbSwapInput(uint256 tokens_sold, uint256 min_bnb) external returns (uint256);

    /**
     * @notice Convert Tokens to BNB.
     * @dev User specifies maximum input && exact output.
     * @param bnb_bought Amount of BNB purchased.
     * @param max_tokens Maximum Tokens sold.
     * @return Amount of Tokens sold.
     */
    function tokenToBnbSwapOutput(uint256 bnb_bought, uint256 max_tokens) external returns (uint256);

    /***********************************|
    |         Getter Functions          |
    |__________________________________*/

    /**
     * @notice Public price function for BNB to Token trades with an exact input.
     * @param bnb_sold Amount of BNB sold.
     * @return Amount of Tokens that can be bought with input BNB.
     */
    function getBnbToTokenInputPrice(uint256 bnb_sold) external view returns (uint256);

    /**
     * @notice Public price function for BNB to Token trades with an exact output.
     * @param tokens_bought Amount of Tokens bought.
     * @return Amount of BNB needed to buy output Tokens.
     */
    function getBnbToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256);

    /**
     * @notice Public price function for Token to BNB trades with an exact input.
     * @param tokens_sold Amount of Tokens sold.
     * @return Amount of BNB that can be bought with input Tokens.
     */
    function getTokenToBnbInputPrice(uint256 tokens_sold) external view returns (uint256);

    /**
     * @notice Public price function for Token to BNB trades with an exact output.
     * @param bnb_bought Amount of output BNB.
     * @return Amount of Tokens needed to buy output BNB.
     */
    function getTokenToBnbOutputPrice(uint256 bnb_bought) external view returns (uint256) ;

    /**
     * @return Address of Token that is sold on this exchange.
     */
    function tokenAddress() external view returns (address) ;

    function bnbBalance() external view returns (uint256);

    function tokenBalance() external view returns (uint256);

    function getBnbToLiquidityInputPrice(uint256 bnb_sold) external view returns (uint256);

    function getLiquidityToReserveInputPrice(uint amount) external view returns (uint256, uint256);

    function txs(address owner) external view returns (uint256) ;


    /***********************************|
    |        Liquidity Functions        |
    |__________________________________*/

    /**
     * @notice Deposit BNB && Tokens (token) at current ratio to mint SWAP tokens.
     * @dev min_liquidity does nothing when total SWAP supply is 0.
     * @param min_liquidity Minimum number of SWAP sender will mint if total SWAP supply is greater than 0.
     * @param max_tokens Maximum number of tokens deposited. Deposits max amount if total SWAP supply is 0.
     * @return The amount of SWAP minted.
     */
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens) external payable returns (uint256) ;

    /**
     * @dev Burn SWAP tokens to withdraw BNB && Tokens at current ratio.
     * @param amount Amount of SWAP burned.
     * @param min_bnb Minimum BNB withdrawn.
     * @param min_tokens Minimum Tokens withdrawn.
     * @return The amount of BNB && Tokens withdrawn.
     */
    function removeLiquidity(uint256 amount, uint256 min_bnb, uint256 min_tokens) external returns (uint256, uint256);
}

contract Reservoir {

    using SafeMath for uint;

    /*=================================
    =            MODIFIERS            =
    =================================*/

    /// @dev Only people with tokens
    modifier onlyBagholders {
        require(myTokens() > 0);
        _;
    }

    /// @dev Only people with profits
    modifier onlyStronghands {
        require(myDividends() > 0);
        _;
    }



    /*==============================
    =            EVENTS            =
    ==============================*/


    event onLeaderBoard(
        address indexed customerAddress,
        uint256 invested,
        uint256 tokens,
        uint256 soldTokens,
        uint256 timestamp
    );

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingeth,
        uint256 tokensMinted,
        uint timestamp
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethEarned,
        uint timestamp
    );

    event onReinvestment(
        address indexed customerAddress,
        uint256 ethReinvested,
        uint256 tokensMinted,
        uint256 timestamp
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 ethWithdrawn,
        uint256 timestamp
    );

    event onClaim(
        address indexed customerAddress,
        uint256 tokens,
        uint256 timestamp
    );

    event onTransfer(
        address indexed from,
        address indexed to,
        uint256 tokens,
        uint256 timestamp
    );

    event onBalance(
        uint256 bnbBalance,
        uint256 tokenBalance,
        uint256 timestamp
    );

    event onLiquiditySweep(
        uint amount
    );

    event onLiquidityProviderReward(
        uint amount
    );

    // Onchain Stats!!!
    struct Stats {
        uint invested;
        uint reinvested;
        uint withdrawn;
        uint rewarded;
        uint taxes;
        uint contributed;
        uint transferredTokens;
        uint receivedTokens;
        uint xInvested;
        uint xReinvested;
        uint xRewarded;
        uint xContributed;
        uint xWithdrawn;
        uint xTransferredTokens;
        uint xReceivedTokens;
    }

    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/

    /// @dev 15% dividends for token purchase
    uint8 constant internal entryFee_ = 10;

    uint8 constant internal exitFee_  = 10;

    uint8 constant internal dripFee = 50;

    uint8 constant internal instantFee = 20;

    uint8 constant payoutRate_ = 2;

    uint256 constant internal magnitude = 2 ** 64;

    uint constant MAX_UINT = 2**256 - 1;

    /*=================================
     =            DATASETS            =
     ================================*/

    // amount of shares for each address (scaled number)
    mapping(address => uint256) private tokenBalanceLedger_;
    mapping(address => int256) private payoutsTo_;
    mapping(address => Stats) private stats;

    //on chain referral tracking
    uint256 private tokenSupply_;
    uint256 private profitPerShare_;
    uint256 public totalDeposits;
    uint256 public totalWithdrawn;
    uint256 internal lastBalance_;
    uint private lockedBalance;

    uint public players;
    uint public totalTxs;
    uint public dividendBalance;

    uint public lastPayout;
    uint public totalClaims;

    uint256 public balanceInterval = 30 seconds;
    uint256 public distributionInterval = 3 seconds;

    address public swapAddress;
    address public collateralAddress;

    IToken private swapToken;
    IToken private cToken;
    ISwap private swap;


    /*=======================================
    =            PUBLIC FUNCTIONS           =
    =======================================*/

    constructor(address _swapAddress, address _collateralAddress) public {

        swapAddress = _swapAddress;

        collateralAddress = _collateralAddress;

        swapToken = IToken(_swapAddress);

        swap = ISwap(_swapAddress);

        cToken = IToken(_collateralAddress);

        lastPayout = now;

    }

    /// @dev converts BNB into liquidity and buys
    function buy() public payable returns (uint256){

        require(msg.value >= 1e16, "min buy is 0.01 BNB");

        totalDeposits += msg.value;

        //Refresh approvals
        approveSwap();

        //use dust from previous txs
        uint balance = address(this).balance;

        uint tokens = sellBnb(balance / 2);

        //the secret sauce for adding liquidity properly
        uint bnbAmount = SafeMath.min(swap.getTokenToBnbInputPrice(tokens), address(this).balance);

        //If you don't get bnbAmount from the contract you will have pain
        uint liquidAmount = swap.addLiquidity.value(bnbAmount)(1, tokens);

        return buyFor(msg.sender, liquidAmount);
    }

    /// @dev Converts all incoming eth to tokens for the caller, and passes down the referral addy (if any)
    function buyFor(address _customerAddress, uint _buy_amount) internal returns (uint256)  {

        uint amount = purchaseTokens(_customerAddress, _buy_amount);

        emit onLeaderBoard(_customerAddress,
            stats[_customerAddress].invested,
            tokenBalanceLedger_[_customerAddress],
            stats[_customerAddress].withdrawn,
            now
        );

        //distribute
        distribute();

        return amount;
    }


    /**
     * @dev Fallback function to handle eth that was send straight to the contract
     *  Unfortunately we cannot use a referral address this way.
     */
    function() public payable  {
        //DO NOTHING!!! Swap will send BNB to us!!!
    }

    /// @dev Converts all of caller's dividends to tokens.
    function reinvest() public onlyStronghands returns (uint) {
        // fetch dividends
        uint256 _dividends = myDividends();
        // retrieve ref. bonus later in the code

        // pay out the dividends virtually
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens = purchaseTokens(msg.sender, _dividends);

        uint bnbAmount = calculateLiquidityToBnb(_dividends);

        // fire event
        emit onReinvestment(_customerAddress, bnbAmount, _tokens, now);

        //Stats
        stats[_customerAddress].reinvested = SafeMath.add(stats[_customerAddress].reinvested, bnbAmount);
        stats[_customerAddress].xReinvested += 1;

        emit onLeaderBoard(_customerAddress,
            stats[_customerAddress].invested,
            tokenBalanceLedger_[_customerAddress],
            stats[_customerAddress].withdrawn,
            now
        );

        //distribute
        distribute();

        return _tokens;
    }

    /// @dev Withdraws all of the callers earnings.
    function withdraw() public onlyStronghands returns (uint) {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(); // 100% of divs

        // update dividend tracker
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

        //remove liquidity and sell the tokens for BNB
        (uint bnbAmount, uint tokenAmount) = swap.removeLiquidity(_dividends,1,1);
        bnbAmount = bnbAmount.add(sellTokens(tokenAmount));

        // lambo delivery service
        _customerAddress.transfer(bnbAmount);

        totalWithdrawn += bnbAmount;

        //stats
        stats[_customerAddress].withdrawn = SafeMath.add(stats[_customerAddress].withdrawn, bnbAmount);
        stats[_customerAddress].xWithdrawn += 1;
        totalTxs += 1;
        totalClaims += _dividends;

        // fire event
        emit onWithdraw(_customerAddress, bnbAmount, now);

        emit onLeaderBoard(_customerAddress,
            stats[_customerAddress].invested,
            tokenBalanceLedger_[_customerAddress],
            stats[_customerAddress].withdrawn,
            now
        );

        //distribute
        distribute();

        return bnbAmount;
    }

    function sell(uint256 _amountOfTokens) onlyStronghands public {
        // setup data
        address _customerAddress = msg.sender;

        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        // data setup
        uint256 _undividedDividends = SafeMath.mul(_amountOfTokens, exitFee_) / 100;
        uint256 _taxedeth = SafeMath.sub(_amountOfTokens, _undividedDividends);

        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _amountOfTokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

        // update dividends tracker
        int256 _updatedPayouts = (int256) (profitPerShare_ * _amountOfTokens + (_taxedeth * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

        //drip and buybacks
        allocateFees(_undividedDividends);

        // fire event
        emit onTokenSell(_customerAddress, _amountOfTokens, _taxedeth, now);

        //distribute
        distribute();
    }

    /*=====================================
    =      HELPERS AND CALCULATORS        =
    =====================================*/

    /**
     * @dev Method to view the current eth stored in the contract
     */
    function totalTokenBalance() public view returns (uint256) {
        return swapToken.balanceOf(address(this));
    }

    function lockedTokenBalance() public view returns (uint256) {
        return lockedBalance;
    }

    function collateralBalance() public view returns (uint256) {
        return cToken.balanceOf(address(this));
    }

    /// @dev Retrieve the total token supply.
    function totalSupply() public view returns (uint256) {
        return tokenSupply_;
    }

    /// @dev Retrieve the tokens owned by the caller.
    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    /**
     * @dev Retrieve the dividends owned by the caller.
     */
    function myDividends() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return dividendsOf(_customerAddress);
    }


    /// @dev Retrieve the token balance of any single address.
    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

    /// @dev Retrieve the token balance of any single address.
    function bnbBalance(address _customerAddress) public view returns (uint256) {
        return _customerAddress.balance;
    }

    /// @dev Retrieve the dividend balance of any single address.
    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

    function approveSwap() internal {
        require(cToken.approve(swapAddress, MAX_UINT), "Need to approve swap before selling tokens");
    }

    function sellTokens(uint256 amount) internal returns (uint256) {
        approveSwap();
        return swap.tokenToBnbSwapInput(amount,1);
    }

    function sellBnb(uint256 amount) internal returns (uint256){
        return swap.bnbToTokenSwapInput.value(amount)(1);
    }

    function calculateLiquidityToBnb(uint256 _amount) public view returns (uint256) {
        if (_amount > 0){
            (uint bnbAmount, uint tokenAmount) = swap.getLiquidityToReserveInputPrice(_amount);
            return bnbAmount.add(swap.getTokenToBnbInputPrice(tokenAmount));
        } else {
            return 0;
        }
    }

    function calculateTaxedBnbToTokenLiquidity(uint256 _amount) public view returns (uint256) {
        if (_amount > 0){
            uint amount = swap.getBnbToLiquidityInputPrice(_amount.div(2));
            return amount.mul(SafeMath.sub(100,entryFee_)).div(100);
        } else {
            return 0;
        }
    }


    function calculateTaxedLiquidityToBnb(uint256 _amount) public view returns (uint256){
        if (_amount > 0){
            _amount = _amount.mul(SafeMath.sub(100,entryFee_)).div(100);
            (uint bnbAmount, uint tokenAmount) = swap.getLiquidityToReserveInputPrice(_amount);
            return bnbAmount.add(swap.getTokenToBnbInputPrice(tokenAmount));
        } else {
            return 0;
        }
    }

    function sweep() public returns (uint256){

        uint balanceOriginTokens = collateralBalance();
        if (balanceOriginTokens >= 1e18  && tokenSupply_ > 0){

            uint halfTokens = balanceOriginTokens.div(2);

            //We need to start with BNB so we can safely split and add liquidity; also collect BNB dust in the contract
            uint balanceBnb = sellTokens(halfTokens);
            uint balanceTokens = collateralBalance();
            //the secret sauce for adding liquidity properly
            uint bnbAmount = SafeMath.min(swap.getTokenToBnbInputPrice(balanceTokens), balanceBnb);

            //If you don't get bnbAmount from the contract you will have pain
            uint liquidAmount = swap.addLiquidity.value(bnbAmount)(1, balanceTokens);

            //half goes to lock and the other half goes to Stronghold LPs
            uint halfLiq = liquidAmount.div(2);

            uint sweepBalance = liquidAmount.sub(halfLiq);

            //Add the new liquidity to drip dividends;
            dividendBalance += sweepBalance;

            //Add the new liquidity to locked; Stronghold should show up on the leaderboard
            lockedBalance += halfLiq;

            emit onLiquiditySweep(halfLiq);
            emit onLiquidityProviderReward(halfLiq);
            return liquidAmount;
        } else {
            return 0;
        }
    }


    /// @dev Stats of any single address
    function statsOf(address _customerAddress) public view returns (uint256[15] memory){
        Stats memory s = stats[_customerAddress];
        uint256[15] memory statArray = [s.invested, s.withdrawn, s.rewarded, s.taxes, s.contributed, s.transferredTokens, s.receivedTokens, s.xInvested, s.xRewarded, s.xContributed, s.xWithdrawn, s.xTransferredTokens, s.xReceivedTokens, s.reinvested, s.xReinvested];
        return statArray;
    }

    /// @dev Calculate daily estimate of swap tokens awarded in BNB
    function dailyEstimateBnb(address _customerAddress) public view returns (uint256){
        if (tokenSupply_ > 0){
            uint256 share = dividendBalance.mul(payoutRate_).div(100);
            uint256 estimate = share.mul(tokenBalanceLedger_[_customerAddress]).div(tokenSupply_);
            (uint bnbAmount, uint tokenAmount) = swap.getLiquidityToReserveInputPrice(estimate);
            return bnbAmount.add(swap.getTokenToBnbInputPrice(tokenAmount));
        } else {
            return 0;
        }
    }

    /// @dev Calculate daily estimate of swap tokens awarded
    function dailyEstimate(address _customerAddress) public view returns (uint256){
        uint256 share = dividendBalance.mul(payoutRate_).div(100);
        return (tokenSupply_ > 0) ? share.mul(tokenBalanceLedger_[_customerAddress]).div(tokenSupply_) : 0;
    }

    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/

    /// @dev Distribute undividend in and out fees across drip pools and instant divs
    function allocateFees(uint fee) private {
        uint _share = fee.div(100);
        uint _drip = _share.mul(dripFee);           //40 --> 50
        uint _instant = _share.mul(instantFee);     //40 --> 20
        uint _lock = fee.safeSub(_drip + _instant); //20 --> 30

        if (tokenSupply_ > 0) {
            //Apply divs
            profitPerShare_ = SafeMath.add(profitPerShare_, (_instant * magnitude) / tokenSupply_);
        }
        //Add to dividend drip pools
        dividendBalance += _drip;

        //Add locked tokens to global count;
        lockedBalance += _lock;

    }

    // @dev Distribute drip pools
    function distribute() private {

        // @Bb updates balance data of contract
        if (now.safeSub(lastBalance_) > balanceInterval && totalTokenBalance() > 0) {
            (uint bnbAmount, uint tokenAmount) = swap.getLiquidityToReserveInputPrice(totalTokenBalance());
            emit onBalance(bnbAmount, tokenAmount, now);
            lastBalance_ = now;
        }

        if (SafeMath.safeSub(now, lastPayout) > distributionInterval && tokenSupply_ > 0) {

            //A portion of the dividend is paid out according to the rate
            uint256 share = dividendBalance.mul(payoutRate_).div(100).div(24 hours);
            //divide the profit by seconds in the day
            uint256 profit = share * now.safeSub(lastPayout);
            //share times the amount of time elapsed
            dividendBalance = dividendBalance.safeSub(profit);

            //Apply divs
            profitPerShare_ = SafeMath.add(profitPerShare_, (profit * magnitude) / tokenSupply_);

            sweep();

            lastPayout = now;
        }
    }

    /// @dev Internal function to actually purchase the tokens.
    function purchaseTokens(address _customerAddress, uint256 _incomingtokens) internal returns (uint256) {

        /* Members */
        if (stats[_customerAddress].invested == 0 && stats[_customerAddress].receivedTokens == 0) {
            players += 1;
        }

        totalTxs += 1;

        // data setup @bb _incomingtokens is 'LP token'
        uint256 _undividedDividends = SafeMath.mul(_incomingtokens, entryFee_) / 100;     // 10% of drops
        uint256 _amountOfTokens     = SafeMath.sub(_incomingtokens, _undividedDividends); // 90% of drops (100% - 10% above)

        uint256 bnbAmount = calculateLiquidityToBnb(_incomingtokens); //total bnb worth of lp token

        // fire event
        emit onTokenPurchase(_customerAddress, bnbAmount, _amountOfTokens, now);

        // yes we know that the safemath function automatically rules out the "greater then" equation.
        require(_amountOfTokens > 0 && SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_, "Tokens need to be positive");

        // we can't give people infinite eth
        if (tokenSupply_ > 0) {
            // add tokens to the pool
            tokenSupply_ += _amountOfTokens;
        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;

        }


        //drip and buybacks; instant requires being called after supply is updated
        allocateFees(_undividedDividends);

        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

        // Tells the contract that the buyer doesn't deserve dividends for the tokens before they owned them;
        int256 _updatedPayouts = (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_customerAddress] += _updatedPayouts;

        //Stats
        stats[_customerAddress].taxes += _undividedDividends;
        stats[_customerAddress].invested += bnbAmount;
        stats[_customerAddress].xInvested += 1;

        return _amountOfTokens;
    }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /* @dev Subtracts two numbers, else returns zero */
    function safeSub(uint a, uint b) internal pure returns (uint) {
        if (b > a) {
            return 0;
        } else {
            return a - b;
        }
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// splash token 0xe0046B0873132643C338291F399143F8EA4c38f6


// fountain   0x620DD286F245d2E5Ca4C7f9A4F5fDcbbd5dFfC83