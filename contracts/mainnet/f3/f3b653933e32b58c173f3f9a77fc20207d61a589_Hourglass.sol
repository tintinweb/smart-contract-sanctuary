/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

pragma solidity ^0.5.15;

/*
:'######::'########:'########::'#######::
'##... ##: ##.....::... ##..::'##.... ##:
 ##:::..:: ##:::::::::: ##:::: ##:::: ##:
 ##::::::: ######:::::: ##:::: ##:::: ##:
 ##::::::: ##...::::::: ##:::: ##:::: ##:
 ##::: ##: ##:::::::::: ##:::: ##:::: ##:
. ######:: ########:::: ##::::. #######::
:......:::........:::::..::::::.......:::

Creator: 773d62b24a9d49e1f990b22e3ef1a9903f44ee809a12d73e660c66c1772c47dd
*/

contract Hourglass {
    /*=================================
    =            MODIFIERS            =
    =================================*/
    // only people with tokens
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }

    // administrators can:
    // -> change the name of the contract
    // -> change the name of the token
    // -> change the PoS difficulty (How many tokens it costs to hold a masternode, in case it gets crazy high later)
    // they CANNOT:
    // -> take funds
    // -> disable withdrawals
    // -> kill the contract
    // -> change the price of tokens
    modifier onlyAdministrator() {
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress], "This address is not an admin");
        _;
    }

    // ensures that the first tokens in the contract will be equally distributed
    // meaning, no divine dump will be ever possible
    // result: healthy longevity.
    modifier antiEarlyWhale(uint256 _amountOfEthereum) {
        // are we still in the vulnerable phase?
        // if so, enact anti early whale protocol
        if (onlyAmbassadors) {
            address _customerAddress = msg.sender;

            if (
                (totalEthereumBalance() - _amountOfEthereum) <= ambassadorQuota_
            ) {
                require(
                    // is the customer in the ambassador list?
                    ambassadors_[_customerAddress] == true &&
                        // does the customer purchase exceed the max ambassador quota?
                        (ambassadorAccumulatedQuota_[_customerAddress] +
                            _amountOfEthereum) <=
                        ambassadorMaxPurchase_
                );

                // updated the accumulated quota
                ambassadorAccumulatedQuota_[_customerAddress] = SafeMath.add(
                    ambassadorAccumulatedQuota_[_customerAddress],
                    _amountOfEthereum
                );

                // execute
                _;
            } else {
                // in case the trx count drops low, the ambassador phase won't reinitiate
                onlyAmbassadors = false;
                _;
            }
        }

        // execute
        _;
    }

    /*==============================
    =            EVENTS            =
    ==============================*/
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned
    );

    event onReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );

    // ERC20
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // When a customer sets up AutoReinvestment
    event onAutoReinvestmentEntry(
        address indexed customerAddress,
        uint256 nextExecutionTime,
        uint256 rewardPerInvocation,
        uint24 period,
        uint256 minimumDividendValue
    );

    // When a customer stops AutoReinvestment
    event onAutoReinvestmentStop(address indexed customerAddress);

    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "Crystal Elephant Token";
    string public symbol = "ECETO";
    uint8 public constant decimals = 18;
    uint8 internal constant dividendFee_ = 10;
    uint256 internal constant tokenPriceInitial_ = 100e9; // unit: wei
    uint256 internal constant tokenPriceIncremental_ = 10e9; // unit: wei
    uint256 internal constant magnitude = 2**64;

    // requirement for earning a referral bonus (defaults at 360 tokens)
    uint256 public stakingRequirement = 30e18;

    // ambassador program
    mapping(address => bool) public ambassadors_;
    uint256 internal constant ambassadorMaxPurchase_ = 4e18; // 4 ETH
    uint256 internal constant ambassadorQuota_ = 100e18; // 100 ETH

    /*================================
    =            DATASETS            =
    ================================*/
    // amount of tokens for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;

    // TODO: 
    // amount of tokens bought with their buy timestamp for each address
    struct TimestampedBalance {
        uint256 value;
        uint256 timestamp;
        uint256 valueSold;
    }

    mapping(address => TimestampedBalance[])
        internal tokenTimestampedBalanceLedger_;

    // The start and end index of the unsold timestamped transactions list
    struct Cursor {
        uint256 start;
        uint256 end;
    }

    mapping(address => Cursor) internal tokenTimestampedBalanceCursor;

    // mappings to and from referral address
    mapping(address => bytes32) public referralMapping;
    mapping(bytes32 => address) public referralReverseMapping;

    // The current referral balance
    mapping(address => uint256) public referralBalance_;
    // All time referrals earnings
    mapping(address => uint256) public referralIncome_;

    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;

    // administrator list (see above on what they can do)
    mapping(address => bool) public administrators;

    // when this is set to true, only ambassadors can purchase tokens (this prevents a whale premine, it ensures a fairly distributed upper pyramid)
    bool public onlyAmbassadors = true;

    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /*
     * -- APPLICATION ENTRY POINTS --
     */
    constructor() public {
        address owner = msg.sender;
        administrators[owner] = true;

        ambassadors_[0x8c67C528a78c3142eEbA7A9FB9966c3141ABFc07] = true;
        ambassadors_[0xA3085Dc923e5de6E1919CFaE73a4D4557CF31734] = true;
        ambassadors_[0x62544c00f6458011796605E8E6E7F799E17b1348] = true;
        ambassadors_[0x5357777ddD555a192E1E87b96a93aAdcC463D0f8] = true;
        ambassadors_[0x8713c7d84dA4edC2795EbaBfFdeEF4bB2Ef654Df] = true;
        ambassadors_[0xC8b17a71fE39dB3AdD2438B89C1522d03767ebDA] = true;
        ambassadors_[0x6B6dDbb85000EFCbff006BEa12CeD803Fd0a0B96] = true;
        ambassadors_[0x2F09612675A16E9D97e8A0c27D2285A5d8FB6EBa] = true;
        ambassadors_[0xD82f5174e03E3352a35a933a11100e6c2607Ba1E] = true;
        ambassadors_[0x28eb45DB2c42b56A1C5BC915F4cc47DD79239632] = true;
        ambassadors_[0x12B2398405f49dEc00D7ceEF9C0925e6fc96c51F] = true;
        ambassadors_[0x32c0aE75EF5BEB409a17fcf26fDDb8561EEF8394] = true;
        ambassadors_[0x2FC1DbA620e749E86E51C2d9c42993174E1986ce] = true;
        ambassadors_[0xDBfc64ff6C4d85f42D8411680ebe90aD06bF3E81] = true;
        ambassadors_[0xBD54eb8AD245450e225A77Af5956F2b41301c845] = true;
        ambassadors_[0x58d1a5e3ca23F46E16BcA17849CE327a415A2ee5] = true;
        ambassadors_[0x33a2e739b428508643Ee49d874775e1196178A1c] = true;
        ambassadors_[0x45ADFF324Eb1ac03a6A115dc539052232D4bA980] = true;
        ambassadors_[0x3e666E4B6091263F3A70C004E47a1e172f31Ff42] = true;
        ambassadors_[0x766917c3Ee4AA5164b3A6F01363865efA8CE6fFd] = true;
        ambassadors_[0x3Ee362b5DB70c2935e718f7711B1CCAC7dbAd081] = true;
        ambassadors_[0xcb1A0F26c89fbC1BCb14fE1Ee9a2785BAE419e81] = true;
    }

    /**
     * Fallback function to handle ethereum that was send straight to the contract
     * Unfortunately we cannot use a referral address this way.
     */
    function() external payable {
        purchaseTokens(msg.sender, msg.value, address(0));
    }

    /**
     * Converts all incoming ethereum to tokens for the caller, and passes down the referral addy (if any)
     */
    function buy(address _referredBy) public payable {
        purchaseTokens(msg.sender, msg.value, _referredBy);
    }

    /**
     * Converts all of caller's dividends to tokens.
     */
    function reinvest(
        bool isAutoReinvestChecked,
        uint24 period,
        uint256 rewardPerInvocation,
        uint256 minimumDividendValue
    ) public {
        _reinvest(msg.sender);

        // Setup Auto Reinvestment
        if (isAutoReinvestChecked) {
            _setupAutoReinvest(
                period,
                rewardPerInvocation,
                msg.sender,
                minimumDividendValue
            );
        }
    }

    /**
     * Alias of sell() and withdraw().
     */
    function exit() public {
        // get token count for caller & sell them all
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if (_tokens > 0) sell(_tokens);
        withdraw();
    }

    /**
     * Withdraws all of the callers earnings.
     */
    function withdraw() public {
        _withdraw(msg.sender);
    }

    /**
     * Liquifies tokens to ethereum.
     */
    function sell(uint256 _amountOfTokens) public onlyBagholders() {
        // setup data
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);

        uint256 penalty =
            mulDiv(
                calculateAveragePenaltyAndUpdateLedger(
                    _amountOfTokens,
                    _customerAddress
                ),
                _ethereum,
                100
            );

        uint256 _dividends =
            SafeMath.add(
                penalty,
                SafeMath.div(SafeMath.sub(_ethereum, penalty), dividendFee_)
            );

        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);

        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(
            tokenBalanceLedger_[_customerAddress],
            _tokens
        );

        // update dividends tracker
        int256 _updatedPayouts =
            (int256)(profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

        if (tokenSupply_ > 0) {
            // update the amount of dividends per token
            profitPerShare_ = SafeMath.add(
                profitPerShare_,
                mulDiv(_dividends, magnitude, tokenSupply_)
            );
        }

        emit onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }

    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/
    /**
     * In case the amassador quota is not met, the administrator can manually disable the ambassador phase.
     */
    function disableInitialStage() public onlyAdministrator() {
        onlyAmbassadors = false;
    }

    function setAdministrator(address _identifier, bool _status)
        public
        onlyAdministrator()
    {
        administrators[_identifier] = _status;
    }

    /**
     * Precautionary measures in case we need to adjust the masternode rate.
     */
    function setStakingRequirement(uint256 _amountOfTokens)
        public
        onlyAdministrator()
    {
        stakingRequirement = _amountOfTokens;
    }

    /**
     * If we want to rebrand, we can.
     */
    function setName(string memory _name) public onlyAdministrator() {
        name = _name;
    }

    /**
     * If we want to rebrand, we can.
     */
    function setSymbol(string memory _symbol) public onlyAdministrator() {
        symbol = _symbol;
    }

    /*----------  REFERRAL FUNCTIONS  ----------*/

    function setReferralName(bytes32 ref_name) public returns (bool) {
        referralMapping[msg.sender] = ref_name;
        referralReverseMapping[ref_name] = msg.sender;
        return true;
    }

    function getReferralAddressForName(bytes32 ref_name)
        public
        view
        returns (address)
    {
        return referralReverseMapping[ref_name];
    }

    function getReferralNameForAddress(address ref_address)
        public
        view
        returns (bytes32)
    {
        return referralMapping[ref_address];
    }

    function getReferralBalance() public view returns (uint256, uint256) {
        address _customerAddress = msg.sender;
        return (
            referralBalance_[_customerAddress],
            referralIncome_[_customerAddress]
        );
    }

    /*------READ FUNCTIONS FOR TIMESTAMPED BALANCE LEDGER-------*/

    function getCursor() public view returns (uint256, uint256) {
        address _customerAddress = msg.sender;
        Cursor storage cursor = tokenTimestampedBalanceCursor[_customerAddress];

        return (cursor.start, cursor.end);
    }

    function getTimestampedBalanceLedger(uint256 counter)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        address _customerAddress = msg.sender;
        TimestampedBalance storage transaction =
            tokenTimestampedBalanceLedger_[_customerAddress][counter];
        return (
            transaction.value,
            transaction.timestamp,
            transaction.valueSold
        );
    }

    /*----------  HELPERS AND CALCULATORS  ----------*/
    /**
     * Method to view the current Ethereum stored in the contract
     * Example: totalEthereumBalance()
     */
    function totalEthereumBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * Retrieve the total token supply.
     */
    function totalSupply() public view returns (uint256) {
        return tokenSupply_;
    }

    /**
     * Retrieve the tokens owned by the caller.
     */
    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    /**
     * Retrieve the dividends owned by the caller.
     * If `_includeReferralBonus` is true, the referral bonus will be included in the calculations.
     * The reason for this, is that in the frontend, we will want to get the total divs (global + ref)
     * But in the internal calculations, we want them separate.
     */
    function myDividends(bool _includeReferralBonus)
        public
        view
        returns (uint256)
    {
        address _customerAddress = msg.sender;
        return
            _includeReferralBonus
                ? dividendsOf(_customerAddress) +
                    referralBalance_[_customerAddress]
                : dividendsOf(_customerAddress);
    }

    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

    /**
     * Retrieve the dividend balance of any single address.
     */
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

    /**
     * Return the ethereum received on selling 1 individual token.
     * We are not deducting the penalty over here as it's a general sell price
     * the user can use the `calculateEthereumReceived` to get the sell price specific to them
     */
    function sellPrice() public view returns (uint256) {
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
            uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }

    /**
     * Return the ethereum required for buying 1 individual token.
     */
    function buyPrice() public view returns (uint256) {
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _taxedEthereum =
                mulDiv(_ethereum, dividendFee_, (dividendFee_ - 1));
            return _taxedEthereum;
        }
    }

    /*
     * Function for the frontend to dynamically retrieve the price scaling of buy orders.
     */
    function calculateTokensReceived(uint256 _ethereumToSpend)
        public
        view
        returns (uint256)
    {
        uint256 _dividends = SafeMath.div(_ethereumToSpend, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        return _amountOfTokens;
    }

    function calculateTokensReinvested() public view returns (uint256) {
        uint256 _ethereumToSpend = myDividends(true);
        uint256 _dividends = SafeMath.div(_ethereumToSpend, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        return _amountOfTokens;
    }

    /**
     * Function for the frontend to dynamically retrieve the price scaling of sell orders.
     */
    function calculateEthereumReceived(uint256 _tokensToSell)
        public
        view
        returns (uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        require(_tokensToSell <= myTokens());
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        address _customerAddress = msg.sender;

        uint256 penalty =
            mulDiv(
                calculateAveragePenalty(_tokensToSell, _customerAddress),
                _ethereum,
                100
            );

        uint256 _dividends =
            SafeMath.add(
                penalty,
                SafeMath.div(SafeMath.sub(_ethereum, penalty), dividendFee_)
            );

        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }

    function calculateEthereumTransferred(uint256 _amountOfTokens)
        public
        view
        returns (uint256)
    {
        require(_amountOfTokens <= tokenSupply_);
        require(_amountOfTokens <= myTokens());
        uint256 _tokenFee = SafeMath.div(_amountOfTokens, dividendFee_);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        return _taxedTokens;
    }

    /**
     * Calculate the early exit penalty for selling x tokens
     */
    function calculateAveragePenalty(
        uint256 _amountOfTokens,
        address _customerAddress
    ) public view onlyBagholders() returns (uint256) {
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        uint256 tokensFound = 0;
        Cursor storage _customerCursor =
            tokenTimestampedBalanceCursor[_customerAddress];
        uint256 counter = _customerCursor.start;
        uint256 averagePenalty = 0;

        while (counter <= _customerCursor.end) {
            TimestampedBalance storage transaction =
                tokenTimestampedBalanceLedger_[_customerAddress][counter];
            uint256 tokensAvailable =
                SafeMath.sub(transaction.value, transaction.valueSold);

            uint256 tokensRequired = SafeMath.sub(_amountOfTokens, tokensFound);

            if (tokensAvailable < tokensRequired) {
                tokensFound += tokensAvailable;
                averagePenalty = SafeMath.add(
                    averagePenalty,
                    SafeMath.mul(
                        _calculatePenalty(transaction.timestamp),
                        tokensAvailable
                    )
                );
            } else if (tokensAvailable <= tokensRequired) {
                averagePenalty = SafeMath.add(
                    averagePenalty,
                    SafeMath.mul(
                        _calculatePenalty(transaction.timestamp),
                        tokensRequired
                    )
                );
                break;
            } else {
                averagePenalty = SafeMath.add(
                    averagePenalty,
                    SafeMath.mul(
                        _calculatePenalty(transaction.timestamp),
                        tokensRequired
                    )
                );
                break;
            }

            counter = SafeMath.add(counter, 1);
        }
        return SafeMath.div(averagePenalty, _amountOfTokens);
    }

    /**
     * Calculate the early exit penalty for selling after x days
     */
    function _calculatePenalty(uint256 timestamp)
        public
        view
        returns (uint256)
    {
        uint256 gap = block.timestamp - timestamp;

        if (gap > 30 days) {
            return 0;
        } else if (gap > 20 days) {
            return 25;
        } else if (gap > 10 days) {
            return 50;
        }
        return 75;
    }

    /**
     * Calculate Token price based on an amount of incoming ethereum
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function ethereumToTokens_(uint256 _ethereum)
        public
        view
        returns (uint256)
    {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived =
            ((
                SafeMath.sub(
                    (
                        sqrt(
                            (_tokenPriceInitial**2) +
                                (2 *
                                    (tokenPriceIncremental_ * 1e18) *
                                    (_ethereum * 1e18)) +
                                (((tokenPriceIncremental_)**2) *
                                    (tokenSupply_**2)) +
                                (2 *
                                    (tokenPriceIncremental_) *
                                    _tokenPriceInitial *
                                    tokenSupply_)
                        )
                    ),
                    _tokenPriceInitial
                )
            ) / (tokenPriceIncremental_)) - (tokenSupply_);

        return _tokensReceived;
    }

    /**
     * Calculate token sell value.
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function tokensToEthereum_(uint256 _tokens) public view returns (uint256) {
        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _ethereumReceived =
            (SafeMath.sub(
                (((tokenPriceInitial_ +
                    (tokenPriceIncremental_ * (_tokenSupply / 1e18))) -
                    tokenPriceIncremental_) * (tokens_ - 1e18)),
                (tokenPriceIncremental_ * ((tokens_**2 - tokens_) / 1e18)) / 2
            ) / 1e18);

        return _ethereumReceived;
    }

    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function purchaseTokens(
        address _customerAddress,
        uint256 _incomingEthereum,
        address _referredBy
    ) internal antiEarlyWhale(_incomingEthereum) returns (uint256) {
        // data setup
        uint256 _undividedDividends =
            SafeMath.div(_incomingEthereum, dividendFee_);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedEthereum =
            SafeMath.sub(_incomingEthereum, _undividedDividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;

        require(
            _amountOfTokens > 0 &&
                SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_
        );

        // is the user referred by a masternode?
        if (
            _referredBy != address(0) &&
            _referredBy != _customerAddress &&
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ) {
            // wealth redistribution
            referralBalance_[_referredBy] = SafeMath.add(
                referralBalance_[_referredBy],
                _referralBonus
            );
            referralIncome_[_referredBy] = SafeMath.add(
                referralIncome_[_referredBy],
                _referralBonus
            );
        } else {
            // no ref purchase
            // add the referral bonus back to the global dividends cake
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }

        if (tokenSupply_ > 0) {
            // add tokens to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare_ += ((_dividends * magnitude) / (tokenSupply_));

            // calculate the amount of tokens the customer receives over his purchase
            _fee =
                _fee -
                (_fee -
                    (_amountOfTokens *
                        ((_dividends * magnitude) / (tokenSupply_))));
        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;
        }

        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(
            tokenBalanceLedger_[_customerAddress],
            _amountOfTokens
        );
        tokenTimestampedBalanceLedger_[_customerAddress].push(
            TimestampedBalance(_amountOfTokens, block.timestamp, 0)
        );
        tokenTimestampedBalanceCursor[_customerAddress].end += 1;

        // You don't get dividends for the tokens before they owned them
        int256 _updatedPayouts =
            (int256)(profitPerShare_ * _amountOfTokens - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;

        // fire event
        emit onTokenPurchase(
            _customerAddress,
            _incomingEthereum,
            _amountOfTokens,
            _referredBy
        );

        emit Transfer(
            address(0),
            _customerAddress,
            _amountOfTokens
        );

        return _amountOfTokens;
    }

    function _reinvest(address _customerAddress) internal {
        uint256 _dividends = dividendsOf(_customerAddress);

        // onlyStronghands
        require(_dividends + referralBalance_[_customerAddress] > 0);

        payoutsTo_[_customerAddress] += (int256)(_dividends * magnitude);

        // retrieve ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens =
            purchaseTokens(_customerAddress, _dividends, address(0));

        // fire event
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }

    function _withdraw(address _customerAddress) internal {
        uint256 _dividends = dividendsOf(_customerAddress); // get ref. bonus later in the code

        // onlyStronghands
        require(_dividends + referralBalance_[_customerAddress] > 0);

        // update dividend tracker
        payoutsTo_[_customerAddress] += (int256)(_dividends * magnitude);

        // add ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        address payable _payableCustomerAddress =
            address(uint160(_customerAddress));
        _payableCustomerAddress.transfer(_dividends);

        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }

    /**
     * Update ledger after transferring x tokens
     */
    function _updateLedgerForTransfer(
        uint256 _amountOfTokens,
        address _customerAddress
    ) internal {
        // Parse through the list of transactions
        uint256 tokensFound = 0;
        Cursor storage _customerCursor =
            tokenTimestampedBalanceCursor[_customerAddress];
        uint256 counter = _customerCursor.start;

        while (counter <= _customerCursor.end) {
            TimestampedBalance storage transaction =
                tokenTimestampedBalanceLedger_[_customerAddress][counter];
            uint256 tokensAvailable =
                SafeMath.sub(transaction.value, transaction.valueSold);

            uint256 tokensRequired = SafeMath.sub(_amountOfTokens, tokensFound);

            if (tokensAvailable < tokensRequired) {
                tokensFound += tokensAvailable;

                delete tokenTimestampedBalanceLedger_[_customerAddress][
                    counter
                ];
            } else if (tokensAvailable <= tokensRequired) {
                delete tokenTimestampedBalanceLedger_[_customerAddress][
                    counter
                ];
                _customerCursor.start = counter + 1;
                break;
            } else {
                transaction.valueSold += tokensRequired;
                _customerCursor.start = counter;
                break;
            }
            counter += 1;
        }
    }

    /**
     * Calculate the early exit penalty for selling x tokens and edit the timestamped ledger
     */
    function calculateAveragePenaltyAndUpdateLedger(
        uint256 _amountOfTokens,
        address _customerAddress
    ) internal onlyBagholders() returns (uint256) {
        // Parse through the list of transactions
        uint256 tokensFound = 0;
        Cursor storage _customerCursor =
            tokenTimestampedBalanceCursor[_customerAddress];
        uint256 counter = _customerCursor.start;
        uint256 averagePenalty = 0;

        while (counter <= _customerCursor.end) {
            TimestampedBalance storage transaction =
                tokenTimestampedBalanceLedger_[_customerAddress][counter];
            uint256 tokensAvailable =
                SafeMath.sub(transaction.value, transaction.valueSold);

            uint256 tokensRequired = SafeMath.sub(_amountOfTokens, tokensFound);

            if (tokensAvailable < tokensRequired) {
                tokensFound += tokensAvailable;
                averagePenalty = SafeMath.add(
                    averagePenalty,
                    SafeMath.mul(
                        _calculatePenalty(transaction.timestamp),
                        tokensAvailable
                    )
                );
                delete tokenTimestampedBalanceLedger_[_customerAddress][
                    counter
                ];
            } else if (tokensAvailable <= tokensRequired) {
                averagePenalty = SafeMath.add(
                    averagePenalty,
                    SafeMath.mul(
                        _calculatePenalty(transaction.timestamp),
                        tokensRequired
                    )
                );
                delete tokenTimestampedBalanceLedger_[_customerAddress][
                    counter
                ];
                _customerCursor.start = counter + 1;
                break;
            } else {
                averagePenalty = SafeMath.add(
                    averagePenalty,
                    SafeMath.mul(
                        _calculatePenalty(transaction.timestamp),
                        tokensRequired
                    )
                );
                transaction.valueSold += tokensRequired;
                _customerCursor.start = counter;
                break;
            }

            counter += 1;
        }

        return SafeMath.div(averagePenalty, _amountOfTokens);
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /**
     * @dev calculates x*y and outputs a emulated 512bit number as l being the lower 256bit half and h the upper 256bit half.
     */
    function fullMul(uint256 x, uint256 y)
        public
        pure
        returns (uint256 l, uint256 h)
    {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    /**
     * @dev calculates x*y/z taking care of phantom overflows.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        require(h < z);
        uint256 mm = mulmod(x, y, z);
        if (mm > l) h -= 1;
        l -= mm;
        uint256 pow2 = z & -z;
        z /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        return l * r;
    }

    /*
     * =========================
     * Auto Reinvestment Feature
     * =========================
     */

    // uint256 recommendedRewardPerInvocation = 5000000; // 5 TRX

    struct AutoReinvestEntry {
        uint256 nextExecutionTime;
        uint256 rewardPerInvocation;
        uint256 minimumDividendValue;
        uint24 period;
    }

    mapping(address => AutoReinvestEntry) internal autoReinvestment;

    function setupAutoReinvest(
        uint24 period,
        uint256 rewardPerInvocation,
        uint256 minimumDividendValue
    ) public {
        _setupAutoReinvest(
            period,
            rewardPerInvocation,
            msg.sender,
            minimumDividendValue
        );
    }

    function _setupAutoReinvest(
        uint24 period,
        uint256 rewardPerInvocation,
        address customerAddress,
        uint256 minimumDividendValue
    ) internal {
        autoReinvestment[customerAddress] = AutoReinvestEntry(
            block.timestamp + period,
            rewardPerInvocation,
            minimumDividendValue,
            period
        );

        // Launch an event that this entry has been created
        emit onAutoReinvestmentEntry(
            customerAddress,
            autoReinvestment[customerAddress].nextExecutionTime,
            rewardPerInvocation,
            period,
            minimumDividendValue
        );
    }

    // Anyone can call this function and claim the reward
    function invokeAutoReinvest(address _customerAddress)
        external
        returns (uint256)
    {
        AutoReinvestEntry storage entry = autoReinvestment[_customerAddress];

        if (
            entry.nextExecutionTime > 0 &&
            block.timestamp >= entry.nextExecutionTime
        ) {
            // fetch dividends
            uint256 _dividends = dividendsOf(_customerAddress);

            // Only execute if the user's dividends are more that the
            // rewardPerInvocation and the minimumDividendValue
            if (
                _dividends > entry.minimumDividendValue &&
                _dividends > entry.rewardPerInvocation
            ) {
                // Deduct the reward from the users dividends
                payoutsTo_[_customerAddress] += (int256)(
                    entry.rewardPerInvocation * magnitude
                );

                // Update the Auto Reinvestment entry
                entry.nextExecutionTime +=
                    (((block.timestamp - entry.nextExecutionTime) /
                        uint256(entry.period)) + 1) *
                    uint256(entry.period);

                /*
                 * Do the reinvestment
                 */
                _reinvest(_customerAddress);

                // Send the caller their reward
                msg.sender.transfer(entry.rewardPerInvocation);
            }
        }

        return entry.nextExecutionTime;
    }

    // Read function for the frontend to determine if the user has setup Auto Reinvestment or not
    function getAutoReinvestEntry()
        public
        view
        returns (
            uint256,
            uint256,
            uint24,
            uint256
        )
    {
        address _customerAddress = msg.sender;
        AutoReinvestEntry storage _autoReinvestEntry =
            autoReinvestment[_customerAddress];
        return (
            _autoReinvestEntry.nextExecutionTime,
            _autoReinvestEntry.rewardPerInvocation,
            _autoReinvestEntry.period,
            _autoReinvestEntry.minimumDividendValue
        );
    }

    // Read function for the scheduling workers determine if the user has setup Auto Reinvestment or not
    function getAutoReinvestEntryOf(address _customerAddress)
        public
        view
        returns (
            uint256,
            uint256,
            uint24,
            uint256
        )
    {
        AutoReinvestEntry storage _autoReinvestEntry =
            autoReinvestment[_customerAddress];
        return (
            _autoReinvestEntry.nextExecutionTime,
            _autoReinvestEntry.rewardPerInvocation,
            _autoReinvestEntry.period,
            _autoReinvestEntry.minimumDividendValue
        );
    }

    // The user can stop the autoReinvestment whenever they want
    function stopAutoReinvest() external {
        address customerAddress = msg.sender;
        if (autoReinvestment[customerAddress].nextExecutionTime > 0) {
            delete autoReinvestment[customerAddress];

            // Launch an event that this entry has been deleted
            emit onAutoReinvestmentStop(customerAddress);
        }
    }

    // Allowance, Approval and Transfer From

    mapping(address => mapping(address => uint256)) private _allowances;

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        uint256 final_amount =
            SafeMath.sub(_allowances[sender][msg.sender], amount);

        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, final_amount);
        return true;
    }

    function transfer(address _toAddress, uint256 _amountOfTokens)
        public
        onlyBagholders
        returns (bool)
    {
        _transfer(msg.sender, _toAddress, _amountOfTokens);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient` after liquifying 10% of the tokens `amount` as dividens.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `_customerAddress` cannot be the zero address.
     * - `_toAddress` cannot be the zero address.
     * - `_customerAddress` must have a balance of at least `_amountOfTokens`.
     */
    function _transfer(
        address _customerAddress,
        address _toAddress,
        uint256 _amountOfTokens
    ) internal {
        require(
            _customerAddress != address(0),
            "ERC20: transfer from the zero address"
        );
        require(
            _toAddress != address(0),
            "ERC20: transfer to the zero address"
        );

        // also disables transfers until ambassador phase is over
        // ( we dont want whale premines )
        // make sure we have the requested tokens
        require(
            !onlyAmbassadors &&
                _amountOfTokens <= tokenBalanceLedger_[_customerAddress]
        );

        // withdraw all outstanding dividends first
        if (
            dividendsOf(_customerAddress) + referralBalance_[_customerAddress] >
            0
        ) {
            _withdraw(_customerAddress);
        }

        // updating tokenTimestampedBalanceLedger_ for _customerAddress
        _updateLedgerForTransfer(_amountOfTokens, _customerAddress);

        // liquify 10% of the remaining tokens that are transfered
        // these are dispersed to shareholders
        uint256 _tokenFee = SafeMath.div(_amountOfTokens, dividendFee_);

        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToEthereum_(_tokenFee);

        // burn the fee tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(
            tokenBalanceLedger_[_customerAddress],
            _amountOfTokens
        );
        tokenBalanceLedger_[_toAddress] = SafeMath.add(
            tokenBalanceLedger_[_toAddress],
            _taxedTokens
        );

        // updating tokenTimestampedBalanceLedger_ for _toAddress
        tokenTimestampedBalanceLedger_[_toAddress].push(
            TimestampedBalance(_taxedTokens, block.timestamp, 0)
        );
        tokenTimestampedBalanceCursor[_toAddress].end += 1;

        // update dividend trackers
        payoutsTo_[_customerAddress] -= (int256)(
            profitPerShare_ * _amountOfTokens
        );
        payoutsTo_[_toAddress] += (int256)(profitPerShare_ * _taxedTokens);

        // disperse dividends among holders
        profitPerShare_ = SafeMath.add(
            profitPerShare_,
            mulDiv(_dividends, magnitude, tokenSupply_)
        );

        // fire event
        emit Transfer(_customerAddress, _toAddress, _taxedTokens);
    }

    // Atomically increases the allowance granted to `spender` by the caller.

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        uint256 final_allowance =
            SafeMath.add(_allowances[msg.sender][spender], addedValue);

        _approve(msg.sender, spender, final_allowance);
        return true;
    }

    //Atomically decreases the allowance granted to `spender` by the caller.
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 final_allowance =
            SafeMath.sub(_allowances[msg.sender][spender], subtractedValue);

        _approve(msg.sender, spender, final_allowance);
        return true;
    }

    // Sets `amount` as the allowance of `spender` over the `owner`s tokens.
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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