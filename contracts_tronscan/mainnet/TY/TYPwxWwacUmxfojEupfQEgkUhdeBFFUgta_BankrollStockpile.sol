//SourceUnit: Stockama.sol

/*
    SPDX-License-Identifier: MIT
    A Bankteller Production
    Bankroll Network
    Copyright 2020
*/
pragma solidity ^0.4.25;


contract Token {
    function approve(address spender, uint256 value) public returns (bool);

    function allowance(address owner, address spender) public view returns (uint256); 

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function transfer(address to, uint256 value) public returns (bool);

    function balanceOf(address who) public view returns (uint256);

    function totalSupply() public view returns (uint256);
}

contract Swap {

    /**
      * @dev Pricing function for converting between TRX && Tokens.
      * @param input_amount Amount of TRX or Tokens being sold.
      * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
      * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
      * @return Amount of TRX or Tokens bought.
      */
    function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public view returns (uint256);

    /**
      * @dev Pricing function for converting between TRX && Tokens.
      * @param output_amount Amount of TRX or Tokens being bought.
      * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
      * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
      * @return Amount of TRX or Tokens sold.
      */
    function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve) public view returns (uint256);
    /**
     * @notice Convert TRX to Tokens.
     * @dev User specifies exact input (msg.value) && minimum output.
     * @param min_tokens Minimum Tokens bought.
     * @return Amount of Tokens bought.
     */
    function trxToTokenSwapInput(uint256 min_tokens) public payable returns (uint256);

    /**
     * @notice Convert TRX to Tokens.
     * @dev User specifies maximum input (msg.value) && exact output.
     * @param tokens_bought Amount of tokens bought.
     * @return Amount of TRX sold.
     */
    function trxToTokenSwapOutput(uint256 tokens_bought) public payable returns (uint256);

    /**
     * @notice Convert Tokens to TRX.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_trx Minimum TRX purchased.
     * @return Amount of TRX bought.
     */
    function tokenToTrxSwapInput(uint256 tokens_sold, uint256 min_trx) public returns (uint256);

    /**
     * @notice Convert Tokens to TRX.
     * @dev User specifies maximum input && exact output.
     * @param trx_bought Amount of TRX purchased.
     * @param max_tokens Maximum Tokens sold.
     * @return Amount of Tokens sold.
     */
    function tokenToTrxSwapOutput(uint256 trx_bought, uint256 max_tokens) public returns (uint256);

    /***********************************|
    |         Getter Functions          |
    |__________________________________*/

    /**
     * @notice Public price function for TRX to Token trades with an exact input.
     * @param trx_sold Amount of TRX sold.
     * @return Amount of Tokens that can be bought with input TRX.
     */
    function getTrxToTokenInputPrice(uint256 trx_sold) public view returns (uint256);

    /**
     * @notice Public price function for TRX to Token trades with an exact output.
     * @param tokens_bought Amount of Tokens bought.
     * @return Amount of TRX needed to buy output Tokens.
     */
    function getTrxToTokenOutputPrice(uint256 tokens_bought) public view returns (uint256);

    /**
     * @notice Public price function for Token to TRX trades with an exact input.
     * @param tokens_sold Amount of Tokens sold.
     * @return Amount of TRX that can be bought with input Tokens.
     */
    function getTokenToTrxInputPrice(uint256 tokens_sold) public view returns (uint256);

    /**
     * @notice Public price function for Token to TRX trades with an exact output.
     * @param trx_bought Amount of output TRX.
     * @return Amount of Tokens needed to buy output TRX.
     */
    function getTokenToTrxOutputPrice(uint256 trx_bought) public view returns (uint256) ;

    /**
     * @return Address of Token that is sold on this exchange.
     */
    function tokenAddress() public view returns (address) ;


    function tronBalance() public view returns (uint256);

    function tokenBalance() public view returns (uint256);

    function getTrxToLiquidityInputPrice(uint256 trx_sold) public view returns (uint256);

    function getLiquidityToReserveInputPrice(uint amount) public view returns (uint256, uint256);

    function txs(address owner) public view returns (uint256) ;


    /***********************************|
    |        Liquidity Functions        |
    |__________________________________*/

    /**
     * @notice Deposit TRX && Tokens (token) at current ratio to mint SWAP tokens.
     * @dev min_liquidity does nothing when total SWAP supply is 0.
     * @param min_liquidity Minimum number of SWAP sender will mint if total SWAP supply is greater than 0.
     * @param max_tokens Maximum number of tokens deposited. Deposits max amount if total SWAP supply is 0.
     * @return The amount of SWAP minted.
     */
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens) public payable returns (uint256) ;

    /**
     * @dev Burn SWAP tokens to withdraw TRX && Tokens at current ratio.
     * @param amount Amount of SWAP burned.
     * @param min_trx Minimum TRX withdrawn.
     * @param min_tokens Minimum Tokens withdrawn.
     * @return The amount of TRX && Tokens withdrawn.
     */
    function removeLiquidity(uint256 amount, uint256 min_trx, uint256 min_tokens) public returns (uint256, uint256);
}

/*
 * @dev Life is a perpetual rewards contract the collects 9% fee for a dividend pool that drips 2% daily.
 * A 1% fee is used to buy back a specified ERC20/TRC20 token and distribute to LYF holders via a 2% drip
*/


contract BankrollStockpile {

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

    event onBuyBack(
        uint ethAmount,
        uint tokenAmount,
        uint256 timestamp
    );

    event onBalance(
        uint256 trxBalance,
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


    /// @dev 5% dividends for token selling
    uint8 constant internal exitFee_ = 10;

    uint8 constant internal dripFee = 40;  //80% of fees go to drip/instant, the rest, 20%,  to lock into token liquidity

    uint8 constant internal instantFee = 40;

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

    uint256 public balanceInterval = 2 seconds;
    uint256 public distributionInterval = 2 seconds;


    address constant public swapAddress =  address(0x410bf515389a27ba991f09f92cd1bd1b85ad8aade1); //TB4S2pvyX8uQsBPrTDWYCuSDfYSg6tMJm7
    address constant public collateralAddress = address(0x4167da83cfc7d0a1894bb52d7fb12ac8f536b0716f); //TKSLNVrDjb7xCiAySZvjXB9SxxVFieZA7C

    Token private swapToken;
    Token private cToken;
    Swap private swap;


    /*=======================================
    =            PUBLIC FUNCTIONS           =
    =======================================*/

    constructor() public {

        swapToken = Token(swapAddress);
        swap = Swap(swapAddress);

        
        cToken = Token(collateralAddress);
    
        lastPayout = now;

    }

    /// @dev converts TRX into liquidity and buys
    function buy() public payable returns (uint256){
        require(msg.value > 1e4, "Has to be greater than 0.01 TRX");

        totalDeposits += msg.value;

        //Refresh approvals
        approveSwap();

        //use dust from previous txs
        uint balance = address(this).balance;
        
        uint tokens = sellTrx(balance / 2);

        //the secret sauce for adding liquidity properly
        uint trxAmount = SafeMath.min(swap.getTokenToTrxInputPrice(tokens), address(this).balance);

        //If you don't get trxAmount from the contract you will have pain
        uint liquidAmount = swap.addLiquidity.value(trxAmount)(1, tokens);
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

        return amount;
    }




    /**
     * @dev Fallback function to handle eth that was send straight to the contract
     *  Unfortunately we cannot use a referral address this way.
     */
    function() public payable  {
       //DO NOTHING!!! Swap will send TRX to us!!!
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

        uint trxAmount = calculateLiquidityToTrx(_dividends);

        // fire event
        emit onReinvestment(_customerAddress, trxAmount, _tokens, now);

        //Stats
        stats[_customerAddress].reinvested = SafeMath.add(stats[_customerAddress].reinvested, trxAmount);
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
        uint256 _dividends = myDividends();

        // update dividend tracker
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

        //remove liquidity and sell the tokens for TRX
        (uint trxAmount, uint tokenAmount) = swap.removeLiquidity(_dividends,1,1);
        trxAmount = trxAmount.add(sellTokens(tokenAmount));
    
        // lambo delivery service
        _customerAddress.transfer(trxAmount);

        totalWithdrawn += trxAmount;

        //stats
        stats[_customerAddress].withdrawn = SafeMath.add(stats[_customerAddress].withdrawn, trxAmount);
        stats[_customerAddress].xWithdrawn += 1;
        totalTxs += 1;

        // fire event
        emit onWithdraw(_customerAddress, trxAmount, now);

        emit onLeaderBoard(_customerAddress,
            stats[_customerAddress].invested,
            tokenBalanceLedger_[_customerAddress],
            stats[_customerAddress].withdrawn,
            now
        );

        return trxAmount;
    }


    /* @dev Liquifies STCK to collateral tokens.
    /* The same as Stronghold except you can't sell your tokens */ 
    

    /**
    * @dev Transfer tokens from the caller to a new holder.
    *  Zero fees
    */
    function transfer(address _toAddress, uint256 _amountOfTokens) external onlyBagholders  returns (bool) {
        // setup
        address _customerAddress = msg.sender;

        // make sure we have the requested tokens
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress], "Amount of tokens is greater than balance");

        // withdraw all outstanding dividends first
        if (myDividends() > 0) {
            withdraw();
        }


        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);

        // update dividend trackers
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);

        /* Members
            A player can be initialized by buying or receiving and we want to add the user ASAP
         */
        if (stats[_toAddress].invested == 0 && stats[_toAddress].receivedTokens == 0) {
            players += 1;
        }

        //Stats
        stats[_customerAddress].xTransferredTokens += 1;
        stats[_customerAddress].transferredTokens += _amountOfTokens;
        stats[_toAddress].receivedTokens += _amountOfTokens;
        stats[_toAddress].xReceivedTokens += 1;
        totalTxs += 1;

        // fire event
        emit onTransfer(_customerAddress, _toAddress, _amountOfTokens, now);

        emit onLeaderBoard(_customerAddress,
            stats[_customerAddress].invested,
            tokenBalanceLedger_[_customerAddress],
            stats[_customerAddress].withdrawn,
            now
        );

        emit onLeaderBoard(_toAddress,
            stats[_toAddress].invested,
            tokenBalanceLedger_[_toAddress],
            stats[_toAddress].withdrawn,
            now
        );

        // ERC20
        return true;
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
    function trxBalance(address _customerAddress) public view returns (uint256) {
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
        return swap.tokenToTrxSwapInput(amount,1);
    }

    function sellTrx(uint256 amount) internal returns (uint256){
        return swap.trxToTokenSwapInput.value(amount)(1);
    }


    function calculateLiquidityToTrx(uint256 _amount) public view returns (uint256){
        if (_amount > 0){
            (uint trxAmount, uint tokenAmount) = swap.getLiquidityToReserveInputPrice(_amount);
            return trxAmount.add(swap.getTokenToTrxInputPrice(tokenAmount));
        } else {
            return 0;
        }
    }

    function calculateTaxedTrxToTokenLiquidity(uint256 _amount) public view returns (uint256){
         if (_amount > 0){
            uint amount = swap.getTrxToLiquidityInputPrice(_amount.div(2));
            return amount.mul(SafeMath.sub(100,entryFee_)).div(100);
         } else {
             return 0;
         }
    }
    

    function calculateTaxedLiquidityToTrx(uint256 _amount) public view returns (uint256){
         if (_amount > 0){
             _amount = _amount.mul(SafeMath.sub(100,entryFee_)).div(100);
            (uint trxAmount, uint tokenAmount) = swap.getLiquidityToReserveInputPrice(_amount);
            return trxAmount.add(swap.getTokenToTrxInputPrice(tokenAmount));
         } else {
             return 0;
         }
    }

    function sweep() public returns (uint256){

        uint balanceOriginTokens = collateralBalance();

        
        if (balanceOriginTokens >= 10e6  && tokenSupply_ > 0){

            uint halfTokens = balanceOriginTokens.div(2);

            //We need to start with TRX so we can safely split and add liquidity; also collect TRX dust in the constract
            uint balanceTrx = sellTokens(halfTokens);

            uint balanceTokens = collateralBalance();

             //the secret sauce for adding liquidity properly
            uint trxAmount = SafeMath.min(swap.getTokenToTrxInputPrice(balanceTokens), balanceTrx);

            //If you don't get trxAmount from the contract you will have pain
            uint liquidAmount = swap.addLiquidity.value(trxAmount)(1, balanceTokens);

            //half goes to lock and the other half goes to Stronghold LPs
            uint halfLiq = liquidAmount.div(2);
            
            
            uint sweepBalance = liquidAmount.sub(halfLiq);

            //Add the new liquidity to drip dividends; Stronghold should show up on the leaderboard
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
    function statsOf(address _customerAddress) public view returns (uint256[14] memory){
        Stats memory s = stats[_customerAddress];
        uint256[14] memory statArray = [s.invested, s.withdrawn, s.rewarded, s.contributed, s.transferredTokens, s.receivedTokens, s.xInvested, s.xRewarded, s.xContributed, s.xWithdrawn, s.xTransferredTokens, s.xReceivedTokens, s.reinvested, s.xReinvested];
        return statArray;
    }

    /// @dev Calculate daily estimate of swap tokens awarded in TRX
    function dailyEstimateTrx(address _customerAddress) public view returns (uint256){
        if (tokenSupply_ > 0){
            uint256 share = dividendBalance.mul(payoutRate_).div(100);
            uint256 estimate = share.mul(tokenBalanceLedger_[_customerAddress]).div(tokenSupply_);     
            (uint trxAmount, uint tokenAmount) = swap.getLiquidityToReserveInputPrice(estimate);
            return trxAmount.add(swap.getTokenToTrxInputPrice(tokenAmount));
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
        uint _drip = _share.mul(dripFee);
        uint _instant = _share.mul(instantFee);
        uint _lock = fee.safeSub(_drip + _instant);

        //Apply divs
        profitPerShare_ = SafeMath.add(profitPerShare_, (_instant * magnitude) / tokenSupply_);

        //Add to dividend drip pools
        dividendBalance += _drip;

        //Add locked tokens to global count; we don't actually every move them
        lockedBalance += _lock;
        
    }

    // @dev Distribute drip pools
    function distribute() private {

        if (now.safeSub(lastBalance_) > balanceInterval && totalTokenBalance() > 0) {
            (uint trxAmount, uint tokenAmount) = swap.getLiquidityToReserveInputPrice(totalTokenBalance());
            emit onBalance(trxAmount, tokenAmount, now);
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

        // data setup
        uint256 _undividedDividends = SafeMath.mul(_incomingtokens, entryFee_) / 100;
        uint256 _amountOfTokens = SafeMath.sub(_incomingtokens, _undividedDividends);

        uint256 trxAmount = calculateLiquidityToTrx(_incomingtokens);

        // fire event
        emit onTokenPurchase(_customerAddress, trxAmount, _amountOfTokens, now);

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

        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

        // Tells the contract that the buyer doesn't deserve dividends for the tokens before they owned them;
        // really i know you think you do but you don't
        int256 _updatedPayouts = (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_customerAddress] += _updatedPayouts;

        //drip and buybacks; instant requires being called after supply is updated
        allocateFees(_undividedDividends);

        //Stats
        stats[_customerAddress].invested += trxAmount;
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