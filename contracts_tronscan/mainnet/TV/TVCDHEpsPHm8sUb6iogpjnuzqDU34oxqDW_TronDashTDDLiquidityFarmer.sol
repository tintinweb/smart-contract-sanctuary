//SourceUnit: tddLiquidityFarmer.sol

/*
    SPDX-License-Identifier: MIT
    TronDash TDD Liquidity Farmer
*/
pragma solidity ^0.4.25;

contract Token {
    function approve(address spender, uint256 value) public returns (bool);

    function allowance(address owner, address spender)
        public
        view
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool);

    function transfer(address to, uint256 value) public returns (bool);

    function balanceOf(address who) public view returns (uint256);

    function totalSupply() public view returns (uint256);
}

contract DashToken {
    function transfer(address to, uint256 value) public returns (bool);
}

contract Swap {
    /**
     * @dev Pricing function for converting between TRX && Tokens.
     * @param input_amount Amount of TRX or Tokens being sold.
     * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
     * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
     * @return Amount of TRX or Tokens bought.
     */
    function getInputPrice(
        uint256 input_amount,
        uint256 input_reserve,
        uint256 output_reserve
    ) public view returns (uint256);

    /**
     * @dev Pricing function for converting between TRX && Tokens.
     * @param output_amount Amount of TRX or Tokens being bought.
     * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
     * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
     * @return Amount of TRX or Tokens sold.
     */
    function getOutputPrice(
        uint256 output_amount,
        uint256 input_reserve,
        uint256 output_reserve
    ) public view returns (uint256);

    /**
     * @notice Convert TRX to Tokens.
     * @dev User specifies exact input (msg.value) && minimum output.
     * @param min_tokens Minimum Tokens bought.
     * @return Amount of Tokens bought.
     */
    function trxToTokenSwapInput(uint256 min_tokens)
        public
        payable
        returns (uint256);

    /**
     * @notice Convert TRX to Tokens.
     * @dev User specifies maximum input (msg.value) && exact output.
     * @param tokens_bought Amount of tokens bought.
     * @return Amount of TRX sold.
     */
    function trxToTokenSwapOutput(uint256 tokens_bought)
        public
        payable
        returns (uint256);

    /**
     * @notice Convert Tokens to TRX.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_trx Minimum TRX purchased.
     * @return Amount of TRX bought.
     */
    function tokenToTrxSwapInput(uint256 tokens_sold, uint256 min_trx)
        public
        returns (uint256);

    /**
     * @notice Convert Tokens to TRX.
     * @dev User specifies maximum input && exact output.
     * @param trx_bought Amount of TRX purchased.
     * @param max_tokens Maximum Tokens sold.
     * @return Amount of Tokens sold.
     */
    function tokenToTrxSwapOutput(uint256 trx_bought, uint256 max_tokens)
        public
        returns (uint256);

    /***********************************|
    |         Getter Functions          |
    |__________________________________*/

    /**
     * @notice Public price function for TRX to Token trades with an exact input.
     * @param trx_sold Amount of TRX sold.
     * @return Amount of Tokens that can be bought with input TRX.
     */
    function getTrxToTokenInputPrice(uint256 trx_sold)
        public
        view
        returns (uint256);

    /**
     * @notice Public price function for TRX to Token trades with an exact output.
     * @param tokens_bought Amount of Tokens bought.
     * @return Amount of TRX needed to buy output Tokens.
     */
    function getTrxToTokenOutputPrice(uint256 tokens_bought)
        public
        view
        returns (uint256);

    /**
     * @notice Public price function for Token to TRX trades with an exact input.
     * @param tokens_sold Amount of Tokens sold.
     * @return Amount of TRX that can be bought with input Tokens.
     */
    function getTokenToTrxInputPrice(uint256 tokens_sold)
        public
        view
        returns (uint256);

    /**
     * @notice Public price function for Token to TRX trades with an exact output.
     * @param trx_bought Amount of output TRX.
     * @return Amount of Tokens needed to buy output TRX.
     */
    function getTokenToTrxOutputPrice(uint256 trx_bought)
        public
        view
        returns (uint256);

    /**
     * @return Address of Token that is sold on this exchange.
     */
    function tokenAddress() public view returns (address);

    function tronBalance() public view returns (uint256);

    function tokenBalance() public view returns (uint256);

    function getTrxToLiquidityInputPrice(uint256 trx_sold)
        public
        view
        returns (uint256);

    function getLiquidityToReserveInputPrice(uint256 amount)
        public
        view
        returns (uint256, uint256);

    function txs(address owner) public view returns (uint256);

    /***********************************|
    |        Liquidity Functions        |
    |__________________________________*/

    /**
     * @notice Deposit TRX && Tokens (token) at current ratio to mint lp tokens.
     * @dev min_liquidity does nothing when total TDDTRX supply is 0.
     * @param min_liquidity Minimum number of TDDTRX sender will mint if total TDDTRX supply is greater than 0.
     * @param max_tokens Maximum number of tokens deposited. Deposits max amount if total TDDTRX supply is 0.
     * @return The amount of TDDTRX minted.
     */
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens)
        public
        payable
        returns (uint256);

    /**
     * @dev Burn lp tokens to withdraw TRX && Tokens at current ratio.
     * @param amount Amount of TDDTRX burned.
     * @param min_trx Minimum TRX withdrawn.
     * @param min_tokens Minimum Tokens withdrawn.
     * @return The amount of TRX && Tokens withdrawn.
     */
    function removeLiquidity(
        uint256 amount,
        uint256 min_trx,
        uint256 min_tokens
    ) public returns (uint256, uint256);
}

contract TronDashTDDLiquidityFarmer {
    using SafeMath for uint256;

    /*---------------------------------
    =            MODIFIERS            =
    ---------------------------------*/
    //only owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
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

    /*------------------------------
    =            EVENTS            =
    ------------------------------*/

    event onLeaderBoard(
        address indexed customerAddress,
        uint256 invested,
        uint256 tokens,
        uint256 soldTokens,
        uint256 timestamp
    );

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingtrx,
        uint256 tokensMinted,
        uint256 timestamp
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 trxEarned,
        uint256 timestamp
    );

    event onReinvestment(
        address indexed customerAddress,
        uint256 trxReinvested,
        uint256 tokensMinted,
        uint256 timestamp
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 trxWithdrawn,
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

    event onBuyBack(uint256 trxAmount, uint256 tokenAmount, uint256 timestamp);

    event onBalance(
        uint256 trxBalance,
        uint256 tokenBalance,
        uint256 timestamp
    );

    event Approval(
        address indexed src,
        address indexed account,
        uint256 amount
    );
    event Transfer(address indexed src, address indexed dst, uint256 amount);

    event onLiquiditySweep(uint256 amount);

    event onLiquidityProviderReward(uint256 amount);

    struct Stats {
        uint256 invested;
        uint256 reinvested;
        uint256 withdrawn;
        uint256 rewarded;
        uint256 contributed;
        uint256 transferredTokens;
        uint256 receivedTokens;
        uint256 xInvested;
        uint256 xReinvested;
        uint256 xRewarded;
        uint256 xContributed;
        uint256 xWithdrawn;
        uint256 xTransferredTokens;
        uint256 xReceivedTokens;
    }

    /*-------------------------------------
    =            CONFIGURABLES            =
    -------------------------------------*/

    /// @dev 10% dividends for token purchase
    uint8 internal constant entryFee_ = 10;

    uint8 internal constant dripFee = 40; //80% of fees go to drip/instant divs, the rest is locked into token liquidity

    uint8 internal constant instantFee = 40;

    uint8 constant payoutRate_ = 2;

    uint256 internal constant magnitude = 2**64;

    uint256 constant MAX_UINT = 2**256 - 1;
    /*---------------------------------
     =            TOKEN DATA            =
     --------------------------------*/

    string public name = "TDD Liquidity Farmer";
    string public symbol = "TDDFRM";
    uint256 public decimals = 6;
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _approvals;

    /*---------------------------------
     =            DATASETS            =
     --------------------------------*/

    // amount of shares for each address (scaled number)
    mapping(address => uint256) private tokenBalanceLedger_;
    mapping(address => int256) private payoutsTo_;
    mapping(address => Stats) private stats;

    address public owner;
    address public dev;

    uint8 public miningRate = 10;
    uint256 public totalMined = 0;

    uint256 private tokenSupply_;
    uint256 private profitPerShare_;
    uint256 public totalDeposits;
    uint256 public totalWithdrawn;
    uint256 internal lastBalance_;
    uint256 private lockedBalance;

    uint256 public players;
    uint256 public totalTxs;
    uint256 public dividendBalance;

    uint256 public lastPayout;

    uint256 public balanceInterval = 2 seconds;
    uint256 public distributionInterval = 2 seconds;

    address public constant swapAddress = address(
        0x41FB585E0170AEEC89EE782DBA1C53F9EEBD131CCD
    ); //TYtCU5129eRyMF35g3dz7J3Nan5kqAkg67
    address public constant collateralAddress = address(
        0x419A2D022ACB6276EA8CBE1C5F9F74B735CC340D12
    ); //TQ2Qyqu6rPXskGGfcPSkF8X7vYnfLMxCx5
    address public constant dashAddress = address(
        0x4159E0DCA594D0318E73862DBE816F81729D80C1B2
    ); //TJASWoyYgUw2M1jvDje7zYLooDCzWYRdkm

    Token private swapToken;
    Token private cToken;
    Swap private swap;
    DashToken private dashToken;

    /*---------------------------------------
    =            PUBLIC FUNCTIONS           =
    ---------------------------------------*/

    constructor() public {
        swapToken = Token(swapAddress);
        swap = Swap(swapAddress);
        cToken = Token(collateralAddress);
        dashToken = DashToken(dashAddress);
        lastPayout = now;
        owner = msg.sender;
        dev = msg.sender;
    }

    /// @dev converts TRX into liquidity and buys
    function buy() public payable returns (uint256) {
        require(msg.value > 1e4, "Has to be greater than 0.01 TRX");

        totalDeposits += msg.value;

        //Refresh approvals
        approveSwap();

        //use remainder from previous txs
        uint256 balance = address(this).balance;

        uint256 tokens = sellTrx(balance / 2);

        //add liquidity
        uint256 trxAmount = SafeMath.min(
            swap.getTokenToTrxInputPrice(tokens),
            address(this).balance
        );

        uint256 liquidAmount = swap.addLiquidity.value(trxAmount)(1, tokens);
        return buyFor(msg.sender, liquidAmount);
    }

    /// @dev Converts all incoming trx to tokens for the caller
    function buyFor(address _customerAddress, uint256 _buy_amount)
        internal
        returns (uint256)
    {
        uint256 amount = purchaseTokens(_customerAddress, _buy_amount);

        emit onLeaderBoard(
            _customerAddress,
            stats[_customerAddress].invested,
            tokenBalanceLedger_[_customerAddress],
            stats[_customerAddress].withdrawn,
            now
        );

        return amount;
    }

    /**
     * @dev Fallback function to handle trx that was send straight to the contract
     */
    function() public payable {
        //do nothing
    }

    /*---------------------------------
     =            TOKEN FUNCTIONS     =
     --------------------------------*/
    function allowance(address src, address account)
        public
        view
        returns (uint256)
    {
        return _approvals[src][account];
    }

    function transferFrom(
        address _customerAddress,
        address _toAddress,
        uint256 _amountOfTokens
    ) external returns (bool) {
        if (_customerAddress != msg.sender) {
            require(
                _approvals[_customerAddress][msg.sender] >= _amountOfTokens,
                "ds-token-insufficient-approval"
            );
            _approvals[_customerAddress][msg.sender] = SafeMath.sub(
                _approvals[_customerAddress][msg.sender],
                _amountOfTokens
            );
        }

        //--------------------------
        // setup

        // make sure we have the requested tokens
        require(
            _amountOfTokens <= tokenBalanceLedger_[_customerAddress],
            "Amount of tokens is greater than balance"
        );

        // withdraw all outstanding dividends first from the user

        if (dividendsOf(_customerAddress) > 0) {
            withdrawForUser(_customerAddress);
        }

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(
            tokenBalanceLedger_[_customerAddress],
            _amountOfTokens
        );
        tokenBalanceLedger_[_toAddress] = SafeMath.add(
            tokenBalanceLedger_[_toAddress],
            _amountOfTokens
        );

        // update dividend trackers
        payoutsTo_[_customerAddress] -= (int256)(
            profitPerShare_ * _amountOfTokens
        );
        payoutsTo_[_toAddress] += (int256)(profitPerShare_ * _amountOfTokens);

        /* Members
            A player can be initialized by buying or receiving and we want to add the user first
         */
        if (
            stats[_toAddress].invested == 0 &&
            stats[_toAddress].receivedTokens == 0
        ) {
            players += 1;
        }

        //Stats
        stats[_customerAddress].xTransferredTokens += 1;
        stats[_customerAddress].transferredTokens += _amountOfTokens;
        stats[_toAddress].receivedTokens += _amountOfTokens;
        stats[_toAddress].xReceivedTokens += 1;
        totalTxs += 1;

        emit onTransfer(_customerAddress, _toAddress, _amountOfTokens, now);
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);

        emit onLeaderBoard(
            _customerAddress,
            stats[_customerAddress].invested,
            tokenBalanceLedger_[_customerAddress],
            stats[_customerAddress].withdrawn,
            now
        );

        emit onLeaderBoard(
            _toAddress,
            stats[_toAddress].invested,
            tokenBalanceLedger_[_toAddress],
            stats[_toAddress].withdrawn,
            now
        );
        return true;
    }

    function approve(address account, uint256 amount) public returns (bool) {
        _approvals[msg.sender][account] = amount;

        emit Approval(msg.sender, account, amount);

        return true;
    }

    /*---------------------------------
     =            FARM FUNCTIONS     =
     --------------------------------*/

    /// @dev Converts all of caller's dividends to tokens.
    function reinvest() public onlyStronghands returns (uint256) {
        // fetch dividends
        uint256 _dividends = myDividends();

        // pay out the dividends virtually
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] += (int256)(_dividends * magnitude);

        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens = purchaseTokens(msg.sender, _dividends);

        uint256 trxAmount = calculateLiquidityToTrx(_dividends);

        // fire event
        emit onReinvestment(_customerAddress, trxAmount, _tokens, now);

        //Stats
        stats[_customerAddress].reinvested = SafeMath.add(
            stats[_customerAddress].reinvested,
            trxAmount
        );
        stats[_customerAddress].xReinvested += 1;

        emit onLeaderBoard(
            _customerAddress,
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
    function withdraw() public onlyStronghands returns (uint256) {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends();

        // update dividend tracker
        payoutsTo_[_customerAddress] += (int256)(_dividends * magnitude);

        //remove liquidity and sell the tokens for TRX
        (uint256 trxAmount, uint256 tokenAmount) = swap.removeLiquidity(
            _dividends,
            1,
            1
        );
        trxAmount = trxAmount.add(sellTokens(tokenAmount));

        _customerAddress.transfer(trxAmount);

        totalWithdrawn += trxAmount;

        //update stats
        stats[_customerAddress].withdrawn = SafeMath.add(
            stats[_customerAddress].withdrawn,
            trxAmount
        );
        stats[_customerAddress].xWithdrawn += 1;
        totalTxs += 1;

        //events
        emit onWithdraw(_customerAddress, trxAmount, now);

        emit onLeaderBoard(
            _customerAddress,
            stats[_customerAddress].invested,
            tokenBalanceLedger_[_customerAddress],
            stats[_customerAddress].withdrawn,
            now
        );

        return trxAmount;
    }

    /// @dev Withdraws all of the callers earnings.
    function withdrawForUser(address _customerAddress)
        internal
        returns (uint256)
    {
        // setup data
        uint256 _dividends = dividendsOf(_customerAddress);
        // update dividend tracker
        payoutsTo_[_customerAddress] += (int256)(_dividends * magnitude);

        //remove liquidity and sell the tokens for TRX
        (uint256 trxAmount, uint256 tokenAmount) = swap.removeLiquidity(
            _dividends,
            1,
            1
        );
        trxAmount = trxAmount.add(sellTokens(tokenAmount));

        _customerAddress.transfer(trxAmount);

        totalWithdrawn += trxAmount;

        //update stats
        stats[_customerAddress].withdrawn = SafeMath.add(
            stats[_customerAddress].withdrawn,
            trxAmount
        );
        stats[_customerAddress].xWithdrawn += 1;
        totalTxs += 1;

        //events
        emit onWithdraw(_customerAddress, trxAmount, now);

        emit onLeaderBoard(
            _customerAddress,
            stats[_customerAddress].invested,
            tokenBalanceLedger_[_customerAddress],
            stats[_customerAddress].withdrawn,
            now
        );

        return trxAmount;
    }

    function transfer(address _toAddress, uint256 _amountOfTokens)
        external
        onlyBagholders
        returns (bool)
    {
        // setup
        address _customerAddress = msg.sender;

        // make sure we have the requested tokens
        require(
            _amountOfTokens <= tokenBalanceLedger_[_customerAddress],
            "Amount of tokens is greater than balance"
        );

        // withdraw all outstanding dividends first
        if (myDividends() > 0) {
            withdraw();
        }

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(
            tokenBalanceLedger_[_customerAddress],
            _amountOfTokens
        );
        tokenBalanceLedger_[_toAddress] = SafeMath.add(
            tokenBalanceLedger_[_toAddress],
            _amountOfTokens
        );

        // update dividend trackers
        payoutsTo_[_customerAddress] -= (int256)(
            profitPerShare_ * _amountOfTokens
        );
        payoutsTo_[_toAddress] += (int256)(profitPerShare_ * _amountOfTokens);

        /* Members
            A player can be initialized by buying or receiving and we want to add the user first
         */
        if (
            stats[_toAddress].invested == 0 &&
            stats[_toAddress].receivedTokens == 0
        ) {
            players += 1;
        }

        //Stats
        stats[_customerAddress].xTransferredTokens += 1;
        stats[_customerAddress].transferredTokens += _amountOfTokens;
        stats[_toAddress].receivedTokens += _amountOfTokens;
        stats[_toAddress].xReceivedTokens += 1;
        totalTxs += 1;

        emit onTransfer(_customerAddress, _toAddress, _amountOfTokens, now);
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);

        emit onLeaderBoard(
            _customerAddress,
            stats[_customerAddress].invested,
            tokenBalanceLedger_[_customerAddress],
            stats[_customerAddress].withdrawn,
            now
        );

        emit onLeaderBoard(
            _toAddress,
            stats[_toAddress].invested,
            tokenBalanceLedger_[_toAddress],
            stats[_toAddress].withdrawn,
            now
        );

        return true;
    }

    /*-------------------------------------
    =      ownership Functions           =
    -------------------------------------*/
    function changeownership(address newAddr) public onlyOwner {
        owner = newAddr;
    }

    function changedev(address newAddr) public onlyOwner {
        dev = newAddr;
    }

    /*-------------------------------------
    =      Dash mining Functions           =
    -------------------------------------*/
    function transferDash(address customerAddress, uint256 amount)
        public
        onlyOwner
    {
        dashToken.transfer(customerAddress, amount);
    }

    function changeminingrate(uint8 rate) public onlyOwner {
        miningRate = rate;
        //change to 0 to turn this feature off
    }

    function changeminingtoken(address newtoken) public onlyOwner {
        dashToken = DashToken(newtoken);
    }

    /*-------------------------------------
    =      PROMO Functions                =
    -------------------------------------*/
    function promote() public payable {
        msg.sender.transfer(msg.value);
    }

    function raisetheroof() public returns (bool) {
        return true;
    }

    /*-------------------------------------
    =      HELPERS AND CALCULATORS        =
    -------------------------------------*/

    /**
     * @dev Method to view the current trx stored in the contract
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

    /// @dev Retrieve TRX dividends.
    function myTrxDivs() public view returns (uint256) {
        address _customerAddress = msg.sender;
        uint256 _customerTokenDivs = dividendsOf(_customerAddress);
        //calculate the trx output
        uint256 _trxDiv = calculateLiquidityToTrx(_customerTokenDivs);
        return _trxDiv;
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
    function trxBalance(address _customerAddress)
        public
        view
        returns (uint256)
    {
        return _customerAddress.balance;
    }

    /// @dev Retrieve the dividend balance of any single address.
    function dividendsOf(address _customerAddress)
        public
        view
        returns (uint256)
    {
        return
            (uint256)(
                (int256)(
                    profitPerShare_ * tokenBalanceLedger_[_customerAddress]
                ) - payoutsTo_[_customerAddress]
            ) / magnitude;
    }

    function approveSwap() internal {
        require(
            cToken.approve(swapAddress, MAX_UINT),
            "Need to approve swap before selling tokens"
        );
    }

    function sellTokens(uint256 amount) internal returns (uint256) {
        approveSwap();
        return swap.tokenToTrxSwapInput(amount, 1);
    }

    function sellTrx(uint256 amount) internal returns (uint256) {
        return swap.trxToTokenSwapInput.value(amount)(1);
    }

    function calculateLiquidityToTrx(uint256 _amount)
        public
        view
        returns (uint256)
    {
        if (_amount > 0) {
            (uint256 trxAmount, uint256 tokenAmount) = swap
                .getLiquidityToReserveInputPrice(_amount);
            return trxAmount.add(swap.getTokenToTrxInputPrice(tokenAmount));
        } else {
            return 0;
        }
    }

    function calculateTaxedTrxToTokenLiquidity(uint256 _amount)
        public
        view
        returns (uint256)
    {
        if (_amount > 0) {
            uint256 amount = swap.getTrxToLiquidityInputPrice(_amount.div(2));
            return amount.mul(SafeMath.sub(100, entryFee_)).div(100);
        } else {
            return 0;
        }
    }

    function calculateTaxedLiquidityToTrx(uint256 _amount)
        public
        view
        returns (uint256)
    {
        if (_amount > 0) {
            _amount = _amount.mul(SafeMath.sub(100, entryFee_)).div(100);
            (uint256 trxAmount, uint256 tokenAmount) = swap
                .getLiquidityToReserveInputPrice(_amount);
            return trxAmount.add(swap.getTokenToTrxInputPrice(tokenAmount));
        } else {
            return 0;
        }
    }

    function sweep() public returns (uint256) {
        uint256 balanceOriginTokens = collateralBalance();

        if (balanceOriginTokens >= 10e6 && tokenSupply_ > 0) {
            uint256 halfTokens = balanceOriginTokens.div(2);

            //We need to start with TRX so we can safely split and add liquidity; also collect remaining TRX in the contract
            uint256 balanceTrx = sellTokens(halfTokens);

            uint256 balanceTokens = collateralBalance();
            //add the liquidity
            uint256 trxAmount = SafeMath.min(
                swap.getTokenToTrxInputPrice(balanceTokens),
                balanceTrx
            );

            uint256 liquidAmount = swap.addLiquidity.value(trxAmount)(
                1,
                balanceTokens
            );

            //half goes to lock and the other half goes to LP token holders
            uint256 halfLiq = liquidAmount.div(2);

            uint256 sweepBalance = liquidAmount.sub(halfLiq);

            //Add the new liquidity to drip dividends;
            dividendBalance += sweepBalance;

            //Add the new liquidity to locked;
            lockedBalance += halfLiq;

            emit onLiquiditySweep(halfLiq);
            emit onLiquidityProviderReward(halfLiq);
            return liquidAmount;
        } else {
            return 0;
        }
    }

    /// @dev Stats of any single address
    function statsOf(address _customerAddress)
        public
        view
        returns (uint256[14] memory)
    {
        Stats memory s = stats[_customerAddress];
        uint256[14] memory statArray = [
            s.invested,
            s.withdrawn,
            s.rewarded,
            s.contributed,
            s.transferredTokens,
            s.receivedTokens,
            s.xInvested,
            s.xRewarded,
            s.xContributed,
            s.xWithdrawn,
            s.xTransferredTokens,
            s.xReceivedTokens,
            s.reinvested,
            s.xReinvested
        ];
        return statArray;
    }

    /// @dev Calculate daily estimate of lp tokens awarded in TRX
    function dailyEstimateTrx(address _customerAddress)
        public
        view
        returns (uint256)
    {
        if (tokenSupply_ > 0) {
            uint256 share = dividendBalance.mul(payoutRate_).div(100);
            uint256 estimate = share
                .mul(tokenBalanceLedger_[_customerAddress])
                .div(tokenSupply_);
            (uint256 trxAmount, uint256 tokenAmount) = swap
                .getLiquidityToReserveInputPrice(estimate);
            return trxAmount.add(swap.getTokenToTrxInputPrice(tokenAmount));
        } else {
            return 0;
        }
    }

    /// @dev Calculate daily estimate of lp tokens awarded
    function dailyEstimate(address _customerAddress)
        public
        view
        returns (uint256)
    {
        uint256 share = dividendBalance.mul(payoutRate_).div(100);
        return
            (tokenSupply_ > 0)
                ? share.mul(tokenBalanceLedger_[_customerAddress]).div(
                    tokenSupply_
                )
                : 0;
    }

    /*------------------------------------------
    =            INTERNAL FUNCTIONS            =
    ------------------------------------------*/

    /// @dev Distribute undividend in and out fees across drip pools and instant divs
    function allocateFees(uint256 fee) private {
        uint256 _share = fee.div(100);
        uint256 _drip = _share.mul(dripFee);
        uint256 _instant = _share.mul(instantFee);
        uint256 _lock = fee.safeSub(_drip + _instant);

        //Apply divs
        profitPerShare_ = SafeMath.add(
            profitPerShare_,
            (_instant * magnitude) / tokenSupply_
        );

        //Add to dividend drip pools
        dividendBalance += _drip;

        //Add locked tokens to global count
        lockedBalance += _lock;
    }

    // @dev Distribute drip pools
    function distribute() private {
        if (
            now.safeSub(lastBalance_) > balanceInterval &&
            totalTokenBalance() > 0
        ) {
            (uint256 trxAmount, uint256 tokenAmount) = swap
                .getLiquidityToReserveInputPrice(totalTokenBalance());
            emit onBalance(trxAmount, tokenAmount, now);
            lastBalance_ = now;
        }

        if (
            SafeMath.safeSub(now, lastPayout) > distributionInterval &&
            tokenSupply_ > 0
        ) {
            //A portion of the dividend is paid out according to the rate
            uint256 share = dividendBalance.mul(payoutRate_).div(100).div(
                24 hours
            );
            //divide the profit by seconds in the day
            uint256 profit = share * now.safeSub(lastPayout);
            //share times the amount of time elapsed
            dividendBalance = dividendBalance.safeSub(profit);

            //Apply divs
            profitPerShare_ = SafeMath.add(
                profitPerShare_,
                (profit * magnitude) / tokenSupply_
            );

            sweep();

            lastPayout = now;
        }
    }

    /// @dev Internal function to actually purchase the tokens.
    function purchaseTokens(address _customerAddress, uint256 _incomingtokens)
        internal
        returns (uint256)
    {
        /* Members */
        if (
            stats[_customerAddress].invested == 0 &&
            stats[_customerAddress].receivedTokens == 0
        ) {
            players += 1;
        }

        totalTxs += 1;

        // data setup
        uint256 _undividedDividends = SafeMath.mul(_incomingtokens, entryFee_) /
            100;
        uint256 _amountOfTokens = SafeMath.sub(
            _incomingtokens,
            _undividedDividends
        );

        uint256 trxAmount = calculateLiquidityToTrx(_incomingtokens);

        emit onTokenPurchase(_customerAddress, trxAmount, _amountOfTokens, now);

        require(
            _amountOfTokens > 0 &&
                SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_,
            "Tokens need to be positive"
        );

        // do not allow infinite trx
        if (tokenSupply_ > 0) {
            // add tokens to the pool
            tokenSupply_ += _amountOfTokens;
        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;
        }

        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(
            tokenBalanceLedger_[_customerAddress],
            _amountOfTokens
        );

        int256 _updatedPayouts = (int256)(profitPerShare_ * _amountOfTokens);
        payoutsTo_[_customerAddress] += _updatedPayouts;

        //drip and buybacks; instant requires being called after supply is updated
        allocateFees(_undividedDividends);

        stats[_customerAddress].invested += trxAmount;
        stats[_customerAddress].xInvested += 1;
        emit Transfer(address(this), _customerAddress, _amountOfTokens);
        //we send some mined dash to the user
        if (miningRate > 0) {
            uint256 miningbonus = SafeMath.div(trxAmount, miningRate);
            dashToken.transfer(_customerAddress, miningbonus);
            totalMined = SafeMath.add(totalMined, miningbonus);
        }

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
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
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