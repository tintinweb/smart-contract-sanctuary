pragma solidity 0.4.25;

/*===========================================================================================*
*********************************** https://p4d.io/ropsten ***********************************
*============================================================================================*
*   
*                            ,-.----.           ,--,              
*                            \    /  \        ,--.&#39;|    ,---,     
*                            |   :    \    ,--,  | :  .&#39;  .&#39; `\   
*                            |   |  .\ :,---.&#39;|  : &#39;,---.&#39;     \  
*                            .   :  |: |;   : |  | ;|   |  .`\  | 
*                            |   |   \ :|   | : _&#39; |:   : |  &#39;  | 
*                            |   : .   /:   : |.&#39;  ||   &#39; &#39;  ;  : 
*                            ;   | |`-&#39; |   &#39; &#39;  ; :&#39;   | ;  .  | 
*                            |   | ;    \   \  .&#39;. ||   | :  |  &#39; 
*                            :   &#39; |     `---`:  | &#39;&#39;   : | /  ;  
*                            :   : :          &#39;  ; ||   | &#39;` ,/   
*                            |   | :          |  : ;;   :  .&#39;     
*                            `---&#39;.|          &#39;  ,/ |   ,.&#39;       
*                              `---`          &#39;--&#39;  &#39;---&#39;         
*                _____ _            _   _              __  __ _      _       _     
*               |_   _| |          | | | |            / _|/ _(_)    (_)     | |    
*                 | | | |__   ___  | | | |_ __   ___ | |_| |_ _  ___ _  __ _| |    
*                 | | | &#39;_ \ / _ \ | | | | &#39;_ \ / _ \|  _|  _| |/ __| |/ _` | |    
*                 | | | | | |  __/ | |_| | | | | (_) | | | | | | (__| | (_| | |    
*                 \_/ |_| |_|\___|  \___/|_| |_|\___/|_| |_| |_|\___|_|\__,_|_|         
*                                                                                  
*               ______ ___________   _____                           _             
*               | ___ \____ |  _  \ |  ___|                         (_)            
*               | |_/ /   / / | | | | |____  ___ __   __ _ _ __  ___ _  ___  _ __  
*               |  __/    \ \ | | | |  __\ \/ / &#39;_ \ / _` | &#39;_ \/ __| |/ _ \| &#39;_ \ 
*               | |   .___/ / |/ /  | |___>  <| |_) | (_| | | | \__ \ | (_) | | | |
*               \_|   \____/|___/   \____/_/\_\ .__/ \__,_|_| |_|___/_|\___/|_| |_|
*                                             | |                                  
*                                             |_|                                              
*                                                       _L/L
*                                                     _LT/l_L_
*                                                   _LLl/L_T_lL_
*                               _T/L              _LT|L/_|__L_|_L_
*                             _Ll/l_L_          _TL|_T/_L_|__T__|_l_
*                           _TLl/T_l|_L_      _LL|_Tl/_|__l___L__L_|L_
*                         _LT_L/L_|_L_l_L_  _&#39;|_|_|T/_L_l__T _ l__|__|L_
*                       _Tl_L|/_|__|_|__T _LlT_|_Ll/_l_ _|__[ ]__|__|_l_L_
*                ..__ _LT_l_l/|__|__l_T _T_L|_|_|l/___|__ | _l__|_ |__|_T_L_  __
*                   _       ___            _                  _       ___       
*                  /_\     / __\___  _ __ | |_ _ __ __ _  ___| |_    / __\_   _ 
*                 //_\\   / /  / _ \| &#39;_ \| __| &#39;__/ _` |/ __| __|  /__\// | | |
*                /  _  \ / /__| (_) | | | | |_| | | (_| | (__| |_  / \/  \ |_| |
*                \_/ \_/ \____/\___/|_| |_|\__|_|  \__,_|\___|\__| \_____/\__, |
*                                   ╔═╗╔═╗╦      ╔╦╗╔═╗╦  ╦               |___/ 
*                                   ╚═╗║ ║║       ║║║╣ ╚╗╔╝
*                                   ╚═╝╚═╝╩═╝────═╩╝╚═╝ ╚╝ 
*                                      0x736f6c5f646576
*                                      ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
* 
* -> What?
* The original autonomous pyramid, improved (again!):
*  [x] Developer optimized to include utility functions:
*      -> approve(): allow others to transfer on your behalf
*      -> approveAndCall(): callback for contracts that want to use approve()
*      -> transferFrom(): use your approval allowance to transfer P4D on anothers behalf
*      -> transferAndCall(): callback for contracts that want to use transfer()
*  [x] Designed to be a bridge for P3D to make the token functional for use in external contracts
*  [x] Masternodes are also used in P4D as well as when it buys P3D:
*      -> If the referrer has more than 10,000 P4D tokens, they will get 1/3 of the 10% divs
*      -> If the referrer also has more than 100 P3D tokens, they will be used as the ref
*         on the buy order to P3D and receive 1/3 of the 10% P3D divs upon purchase
*  [x] As this contract holds P3D, it will receive ETH dividends proportional to it&#39;s
*      holdings, this ETH is then distributed to all P4D token holders proportionally
*  [x] On top of the ETH divs from P3D, you will also receive P3D divs from buys and sells
*      in the P4D exchange
*  [x] There&#39;s a 10% div tax for buys, a 5% div tax on sells and a 0% tax on transfers
*  [x] No auto-transfers for dividends or subdividends, they will all be stored until
*      either withdraw() or reinvest() are called, this makes it easier for external
*      contracts to calculate how much they received upon a withdraw/reinvest
*  [x] Partial withdraws and reinvests for both dividends and subdividends
*
*/


// P3D interface
interface P3D {
    function buy(address) external payable returns(uint256);
    function transfer(address, uint256) external returns(bool);
    function myTokens() external view returns(uint256);
    function balanceOf(address) external view returns(uint256);
    function myDividends(bool) external view returns(uint256);
    function withdraw() external;
    function calculateTokensReceived(uint256) external view returns(uint256);
    function stakingRequirement() external view returns(uint256);
}

// ERC677 style token transfer callback
interface usingP4D {
    function tokenCallback(address _from, uint256 _value, bytes _data) external returns (bool);
}

// ERC20 style approval callback
interface controllingP4D {
    function approvalCallback(address _from, uint256 _value, bytes _data) external returns (bool);
}

contract P4D {

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
    // -> change the PoS difficulty (how many tokens it costs to hold a masternode, in case it gets crazy high later)
    // -> allow a contract to accept P4D tokens
    // they CANNOT:
    // -> take funds
    // -> disable withdrawals
    // -> kill the contract
    // -> change the price of tokens
    modifier onlyAdministrator() {
        require(administrators[msg.sender] || msg.sender == _dev);
        _;
    }

    // ensures that the first tokens in the contract will be equally distributed
    // meaning, no divine dump will be ever possible
    // result: healthy longevity.
    modifier purchaseFilter(address _sender, uint256 _amountETH) {

        // no restrictions for ropsten
        //require(!isContract(_sender) || canAcceptTokens_[_sender]);
        
        if (now >= ACTIVATION_TIME) {
            onlyAmbassadors = false;
        }

        // are we still in the vulnerable phase?
        // if so, enact anti early whale protocol
        if (onlyAmbassadors && ((totalAmbassadorQuotaSpent_ + _amountETH) <= ambassadorQuota_)) {
            require(
                // is the customer in the ambassador list?
                ambassadors_[_sender] == true &&

                // does the customer purchase exceed the max ambassador quota?
                (ambassadorAccumulatedQuota_[_sender] + _amountETH) <= ambassadorMaxPurchase_
            );

            // updated the accumulated quota
            ambassadorAccumulatedQuota_[_sender] = SafeMath.add(ambassadorAccumulatedQuota_[_sender], _amountETH);
            totalAmbassadorQuotaSpent_ = SafeMath.add(totalAmbassadorQuotaSpent_, _amountETH);

            // execute
            _;
        } else {
            require(!onlyAmbassadors);
            _;
        }

    }

    /*==============================
    =            EVENTS            =
    ==============================*/
    event onTokenPurchase(
        address indexed _customerAddress,
        uint256 _incomingP3D,
        uint256 _tokensMinted,
        address indexed _referredBy
    );

    event onTokenSell(
        address indexed _customerAddress,
        uint256 _tokensBurned,
        uint256 _P3D_received
    );

    event onReinvestment(
        address indexed _customerAddress,
        uint256 _P3D_reinvested,
        uint256 _tokensMinted
    );

    event onSubdivsReinvestment(
        address indexed _customerAddress,
        uint256 _ETH_reinvested,
        uint256 _tokensMinted
    );

    event onWithdraw(
        address indexed _customerAddress,
        uint256 _P3D_withdrawn
    );

    event onSubdivsWithdraw(
        address indexed _customerAddress,
        uint256 _ETH_withdrawn
    );

    // ERC20
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _tokens
    );

    event Approval(
        address indexed _tokenOwner,
        address indexed _spender,
        uint256 _tokens
    );


    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "PoWH4D";
    string public symbol = "P4D";
    uint256 constant public decimals = 18;
    uint256 constant internal buyDividendFee_ = 10; // 10% dividend tax on each buy
    uint256 constant internal sellDividendFee_ = 5; // 5% dividend tax on each sell
    uint256 internal tokenPriceInitial_; // set in the constructor
    uint256 constant internal tokenPriceIncremental_ = 1e9; // 1/10th the incremental of P3D
    uint256 constant internal magnitude = 2**64;
    uint256 public stakingRequirement = 1e22; // 10,000 P4D
    uint256 constant internal initialBuyLimitPerTx_ = 1 ether;
    uint256 constant internal initialBuyLimitCap_ = 100 ether;
    uint256 internal totalInputETH_ = 0;


    // ambassador program
    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_ = 1 ether;
    uint256 constant internal ambassadorQuota_ = 12 ether;
    uint256 internal totalAmbassadorQuotaSpent_ = 0;
    address internal _dev;


    uint256 public ACTIVATION_TIME;


   /*================================
    =            DATASETS            =
    ================================*/
    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal dividendsStored_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;

    // administrator list (see above on what they can do)
    mapping(address => bool) public administrators;

    // when this is set to true, only ambassadors can purchase tokens (this prevents a whale premine, it ensures a fairly distributed upper pyramid)
    bool public onlyAmbassadors = true;

    // contracts can interact with the exchange but only approved ones
    mapping(address => bool) public canAcceptTokens_;

    // ERC20 standard
    mapping(address => mapping (address => uint256)) public allowed;

    // P3D contract reference
    P3D internal _P3D;

    // structure to handle the distribution of ETH divs paid out by the P3D contract
    struct P3D_dividends {
        uint256 balance;
        uint256 lastDividendPoints;
    }
    mapping(address => P3D_dividends) internal divsMap_;
    uint256 internal totalDividendPoints_;
    uint256 internal lastContractBalance_;


    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /*
    * -- APPLICATION ENTRY POINTS --
    */
    constructor(uint256 _activationTime, address _P3D_address) public {

        _dev = msg.sender;

        ACTIVATION_TIME = _activationTime;

        totalDividendPoints_ = 1; // non-zero value

        _P3D = P3D(_P3D_address);

        // virtualized purchase of the entire ambassador quota
        // calculateTokensReceived() for this contract will return how many tokens can be bought starting at 1e9 P3D per P4D
        // as the price increases by the incremental each time we can just multiply it out and scale it back to e18
        //
        // this is used as the initial P3D-P4D price as it makes it fairer on other investors that aren&#39;t ambassadors
        uint256 _P4D_received;
        (, _P4D_received) = calculateTokensReceived(ambassadorQuota_);
        tokenPriceInitial_ = tokenPriceIncremental_ * _P4D_received / 1e18;

        // admins
        administrators[_dev] = true;
        
        // ambassadors
        ambassadors_[_dev] = true;
    }


    /**
     * Converts all incoming ethereum to tokens for the caller, and passes down the referral address
     */
    function buy(address _referredBy)
        payable
        public
        returns(uint256)
    {
        return purchaseInternal(msg.sender, msg.value, _referredBy);
    }

    /**
     * Fallback function to handle ethereum that was sent straight to the contract
     * Unfortunately we cannot use a referral address this way.
     */
    function()
        payable
        public
    {
        if (msg.sender != address(_P3D)) {
            purchaseInternal(msg.sender, msg.value, address(0x0));
        }

        // all other ETH is from the withdrawn dividends from
        // the P3D contract, this is distributed out via the
        // updateSubdivsFor() method
        // no more computation can be done inside this function
        // as when you call address.transfer(uint256), only
        // 2,300 gas is forwarded to this function so no variables
        // can be mutated with that limit
        // address(this).balance will represent the total amount
        // of ETH dividends from the P3D contract (minus the amount
        // that&#39;s already been withdrawn)
    }

    /**
     * Distribute any ETH sent to this method out to all token holders
     */
    function donate()
        payable
        public
    {
        // nothing happens here in order to save gas
        // all of the ETH sent to this function will be distributed out
        // via the updateSubdivsFor() method
        // 
        // this method is designed for external contracts that have 
        // extra ETH that they want to evenly distribute to all
        // P4D token holders
    }

    /**
     * Converts all of caller&#39;s dividends to tokens.
     * The argument is not used but it allows MetaMask to render
     * &#39;Reinvest&#39; in your transactions list once the function sig
     * is registered to the contract at;
     * https://etherscan.io/address/0x44691B39d1a75dC4E0A0346CBB15E310e6ED1E86#writeContract
     */
    function reinvest(bool)
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        withdrawInternal(_customerAddress);

        uint256 reinvestableDividends = dividendsStored_[_customerAddress];
        reinvestAmount(reinvestableDividends);
    }

    /**
     * Converts a portion of caller&#39;s dividends to tokens.
     */
    function reinvestAmount(uint256 _amount)
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        withdrawInternal(_customerAddress);

        if (_amount > 0 && _amount <= dividendsStored_[_customerAddress]) {
            dividendsStored_[_customerAddress] = SafeMath.sub(dividendsStored_[_customerAddress], _amount);

            // dispatch a buy order with the virtualized "withdrawn dividends"
            uint256 _tokens = purchaseTokens(_customerAddress, _amount, address(0x0));

            // fire event
            emit onReinvestment(_customerAddress, _amount, _tokens);
        }
    }

    /**
     * Converts all of caller&#39;s subdividends to tokens.
     * The argument is not used but it allows MetaMask to render
     * &#39;Reinvest Subdivs&#39; in your transactions list once the function sig
     * is registered to the contract at;
     * https://etherscan.io/address/0x44691B39d1a75dC4E0A0346CBB15E310e6ED1E86#writeContract
     */
    function reinvestSubdivs(bool)
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        updateSubdivsFor(_customerAddress);

        uint256 reinvestableSubdividends = divsMap_[_customerAddress].balance;
        reinvestSubdivsAmount(reinvestableSubdividends);
    }

    /**
     * Converts all of caller&#39;s subdividends to tokens.
     */
    function reinvestSubdivsAmount(uint256 _amount)
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        updateSubdivsFor(_customerAddress);

        if (_amount > 0 && _amount <= divsMap_[_customerAddress].balance) {
            divsMap_[_customerAddress].balance = SafeMath.sub(divsMap_[_customerAddress].balance, _amount);
            lastContractBalance_ = SafeMath.sub(lastContractBalance_, _amount);

            // purchase tokens with the ETH subdividends
            uint256 _tokens = purchaseInternal(_customerAddress, _amount, address(0x0));

            // fire event
            emit onSubdivsReinvestment(_customerAddress, _amount, _tokens);
        }
    }

    /**
     * Alias of sell() and withdraw().
     * The argument is not used but it allows MetaMask to render
     * &#39;Exit&#39; in your transactions list once the function sig
     * is registered to the contract at;
     * https://etherscan.io/address/0x44691B39d1a75dC4E0A0346CBB15E310e6ED1E86#writeContract
     */
    function exit(bool)
        public
    {
        // get token count for caller & sell them all
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if(_tokens > 0) sell(_tokens);

        // lambo delivery service
        withdraw(true);
        withdrawSubdivs(true);
    }

    /**
     * Withdraws all of the callers dividend earnings.
     * The argument is not used but it allows MetaMask to render
     * &#39;Withdraw&#39; in your transactions list once the function sig
     * is registered to the contract at;
     * https://etherscan.io/address/0x44691B39d1a75dC4E0A0346CBB15E310e6ED1E86#writeContract
     */
    function withdraw(bool)
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        withdrawInternal(_customerAddress);

        uint256 withdrawableDividends = dividendsStored_[_customerAddress];
        withdrawAmount(withdrawableDividends);
    }

    /**
     * Withdraws all of the callers dividend earnings.
     */
    function withdrawAmount(uint256 _amount)
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        withdrawInternal(_customerAddress);

        if (_amount > 0 && _amount <= dividendsStored_[_customerAddress]) {
            dividendsStored_[_customerAddress] = SafeMath.sub(dividendsStored_[_customerAddress], _amount);
            
            // lambo delivery service
            _P3D.transfer(_customerAddress, _amount);
            // NOTE!
            // P3D has a 10% transfer tax so even though this is sending your entire
            // dividend count to you, you will only actually receive 90%.

            // fire event
            emit onWithdraw(_customerAddress, _amount);
        }
    }

    /**
     * Withdraws all of the callers subdividend earnings.
     * The argument is not used but it allows MetaMask to render
     * &#39;Withdraw Subdivs&#39; in your transactions list once the function sig
     * is registered to the contract at;
     * https://etherscan.io/address/0x44691B39d1a75dC4E0A0346CBB15E310e6ED1E86#writeContract
     */
    function withdrawSubdivs(bool)
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        updateSubdivsFor(_customerAddress);

        uint256 withdrawableSubdividends = divsMap_[_customerAddress].balance;
        withdrawSubdivsAmount(withdrawableSubdividends);
    }

    /**
     * Withdraws all of the callers subdividend earnings.
     */
    function withdrawSubdivsAmount(uint256 _amount)
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        updateSubdivsFor(_customerAddress);

        if (_amount > 0 && _amount <= divsMap_[_customerAddress].balance) {
            divsMap_[_customerAddress].balance = SafeMath.sub(divsMap_[_customerAddress].balance, _amount);
            lastContractBalance_ = SafeMath.sub(lastContractBalance_, _amount);

            // transfer all withdrawable subdividends
            _customerAddress.transfer(_amount);

            // fire event
            emit onSubdivsWithdraw(_customerAddress, _amount);
        }
    }

    /**
     * Liquifies tokens to P3D.
     */
    function sell(uint256 _amountOfTokens)
        onlyBagholders()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        updateSubdivsFor(_customerAddress);

        // russian hackers BTFO
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _P3D_amount = tokensToP3D_(_tokens);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_P3D_amount, sellDividendFee_), 100);
        uint256 _taxedP3D = SafeMath.sub(_P3D_amount, _dividends);

        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

        // update dividends tracker
        int256 _updatedPayouts = (int256)(profitPerShare_ * _tokens + (_taxedP3D * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

        // dividing by zero is a bad idea
        if (tokenSupply_ > 0) {
            // update the amount of dividends per token
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

        // fire events
        emit onTokenSell(_customerAddress, _tokens, _taxedP3D);
        emit Transfer(_customerAddress, address(0x0), _tokens);
    }

    /**
     * Transfer tokens from the caller to a new holder.
     * REMEMBER THIS IS 0% TRANSFER FEE
     */
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyBagholders()
        public
        returns(bool)
    {
        address _customerAddress = msg.sender;
        return transferInternal(_customerAddress, _toAddress, _amountOfTokens);
    }

    /**
     * Transfer token to a specified address and forward the data to recipient
     * ERC-677 standard
     * https://github.com/ethereum/EIPs/issues/677
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     * @param _data  Transaction metadata.
     */
    function transferAndCall(address _to, uint256 _value, bytes _data)
        external
        returns(bool)
    {
        // no restrictions for ropsten
        //require(canAcceptTokens_[_to]); // approved contracts only
        require(transfer(_to, _value)); // do a normal token transfer to the contract

        if (isContract(_to)) {
            usingP4D receiver = usingP4D(_to);
            require(receiver.tokenCallback(msg.sender, _value, _data));
        }

        return true;
    }

    /**
     * ERC20 token standard for transferring tokens on anothers behalf
     */
    function transferFrom(address _from, address _to, uint256 _amountOfTokens)
        public
        returns(bool)
    {
        require(allowed[_from][msg.sender] >= _amountOfTokens);
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _amountOfTokens);

        return transferInternal(_from, _to, _amountOfTokens);
    }

    /**
     * ERC20 token standard for allowing another address to transfer your tokens
     * on your behalf up to a certain limit
     */
    function approve(address _spender, uint256 _tokens)
        public
        returns(bool)
    {
        allowed[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        return true;
    }

    /**
     * ERC20 token standard for approving and calling an external
     * contract with data
     */
    function approveAndCall(address _to, uint256 _value, bytes _data)
        external
        returns(bool)
    {
        require(approve(_to, _value)); // do a normal approval

        if (isContract(_to)) {
            controllingP4D receiver = controllingP4D(_to);
            require(receiver.approvalCallback(msg.sender, _value, _data));
        }

        return true;
    }


    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/
    /**
     * In case one of us dies, we need to replace ourselves.
     */
    function setAdministrator(address _identifier, bool _status)
        onlyAdministrator()
        public
    {
        administrators[_identifier] = _status;
    }

    /**
     * Add a new ambassador to the exchange
     */
    function setAmbassador(address _identifier, bool _status)
        onlyAdministrator()
        public
    {
        ambassadors_[_identifier] = _status;
    }

    /**
     * Precautionary measures in case we need to adjust the masternode rate.
     */
    function setStakingRequirement(uint256 _amountOfTokens)
        onlyAdministrator()
        public
    {
        stakingRequirement = _amountOfTokens;
    }

    /**
     * Add a sub-contract, which can accept P4D tokens
     */
    function setCanAcceptTokens(address _address)
        onlyAdministrator()
        public
    {
        require(isContract(_address));
        canAcceptTokens_[_address] = true; // one way switch
    }

    /**
     * If we want to rebrand, we can.
     */
    function setName(string _name)
        onlyAdministrator()
        public
    {
        name = _name;
    }

    /**
     * If we want to rebrand, we can.
     */
    function setSymbol(string _symbol)
        onlyAdministrator()
        public
    {
        symbol = _symbol;
    }


    /*----------  HELPERS AND CALCULATORS  ----------*/
    /**
     * Method to view the current P3D tokens stored in the contract
     */
    function totalBalance()
        public
        view
        returns(uint256)
    {
        return _P3D.myTokens();
    }

    /**
     * Retrieve the total token supply.
     */
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return tokenSupply_;
    }

    /**
     * Retrieve the tokens owned by the caller.
     */
    function myTokens()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    /**
     * Retrieve the dividends owned by the caller.
     * If `_includeReferralBonus` is set to true, the referral bonus will be included in the calculations.
     * The reason for this, is that in the frontend, we will want to get the total divs (global + ref)
     * But in the internal calculations, we want them separate.
     */
    function myDividends(bool _includeReferralBonus)
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return (_includeReferralBonus ? dividendsOf(_customerAddress) + referralDividendsOf(_customerAddress) : dividendsOf(_customerAddress));
    }

    /**
     * Retrieve the subdividend owned by the caller.
     */
    function myStoredDividends()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return storedDividendsOf(_customerAddress);
    }

    /**
     * Retrieve the subdividend owned by the caller.
     */
    function mySubdividends()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return subdividendsOf(_customerAddress);
    }

    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _customerAddress)
        public
        view
        returns(uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }

    /**
     * Retrieve the dividend balance of any single address.
     */
    function dividendsOf(address _customerAddress)
        public
        view
        returns(uint256)
    {
        return (uint256)((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

    /**
     * Retrieve the referred dividend balance of any single address.
     */
    function referralDividendsOf(address _customerAddress)
        public
        view
        returns(uint256)
    {
        return referralBalance_[_customerAddress];
    }

    /**
     * Retrieve the stored dividend balance of any single address.
     */
    function storedDividendsOf(address _customerAddress)
        public
        view
        returns(uint256)
    {
        return dividendsStored_[_customerAddress] + dividendsOf(_customerAddress) + referralDividendsOf(_customerAddress);
    }

    /**
     * Retrieve the subdividend balance owing of any single address.
     */
    function subdividendsOwing(address _customerAddress)
        public
        view
        returns(uint256)
    {
        return (divsMap_[_customerAddress].lastDividendPoints == 0 ? 0 : (balanceOf(_customerAddress) * (totalDividendPoints_ - divsMap_[_customerAddress].lastDividendPoints)) / magnitude);
    }

    /**
     * Retrieve the subdividend balance of any single address.
     */
    function subdividendsOf(address _customerAddress)
        public
        view
        returns(uint256)
    {
        return SafeMath.add(divsMap_[_customerAddress].balance, subdividendsOwing(_customerAddress));
    }

    /**
     * Retrieve the allowance of an owner and spender.
     */
    function allowance(address _tokenOwner, address _spender) 
        public
        view
        returns(uint256)
    {
        return allowed[_tokenOwner][_spender];
    }

    /**
     * Return the buy price of 1 individual token.
     */
    function sellPrice()
        public
        view
        returns(uint256)
    {
        // our calculation relies on the token supply, so we need supply. Doh.
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _P3D_received = tokensToP3D_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_P3D_received, sellDividendFee_), 100);
            uint256 _taxedP3D = SafeMath.sub(_P3D_received, _dividends);

            return _taxedP3D;
        }
    }

    /**
     * Return the sell price of 1 individual token.
     */
    function buyPrice()
        public
        view
        returns(uint256)
    {
        // our calculation relies on the token supply, so we need supply. Doh.
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _P3D_received = tokensToP3D_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_P3D_received, buyDividendFee_), 100);
            uint256 _taxedP3D =  SafeMath.add(_P3D_received, _dividends);
            
            return _taxedP3D;
        }
    }

    /**
     * Function for the frontend to dynamically retrieve the price scaling of buy orders.
     */
    function calculateTokensReceived(uint256 _amountOfETH)
        public
        view
        returns(uint256 _P3D_received, uint256 _P4D_received)
    {
        uint256 P3D_received = _P3D.calculateTokensReceived(_amountOfETH);

        uint256 _dividends = SafeMath.div(SafeMath.mul(P3D_received, buyDividendFee_), 100);
        uint256 _taxedP3D = SafeMath.sub(P3D_received, _dividends);
        uint256 _amountOfTokens = P3DtoTokens_(_taxedP3D);
        
        return (P3D_received, _amountOfTokens);
    }

    /**
     * Function for the frontend to dynamically retrieve the price scaling of sell orders.
     */
    function calculateAmountReceived(uint256 _tokensToSell)
        public
        view
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _P3D_received = tokensToP3D_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_P3D_received, sellDividendFee_), 100);
        uint256 _taxedP3D = SafeMath.sub(_P3D_received, _dividends);
        
        return _taxedP3D;
    }

    /**
    * Utility method to expose the P3D address for any child contracts to use
    */
    function P3D_address()
        public
        view
        returns(address)
    {
        return address(_P3D);
    }

    /**
    * Utility method to return all of the data needed for the front end in 1 call
    */
    function fetchAllDataForCustomer(address _customerAddress)
        public
        view
        returns(uint256 _totalSupply, uint256 _totalBalance, uint256 _buyPrice, uint256 _sellPrice, uint256 _activationTime,
                uint256 _customerTokens, uint256 _customerUnclaimedDividends, uint256 _customerStoredDividends, uint256 _customerSubdividends)
    {
        _totalSupply = totalSupply();
        _totalBalance = totalBalance();
        _buyPrice = buyPrice();
        _sellPrice = sellPrice();
        _activationTime = ACTIVATION_TIME;
        _customerTokens = balanceOf(_customerAddress);
        _customerUnclaimedDividends = dividendsOf(_customerAddress) + referralDividendsOf(_customerAddress);
        _customerStoredDividends = storedDividendsOf(_customerAddress);
        _customerSubdividends = subdividendsOf(_customerAddress);
    }


    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/

    // This function should always be called before a customers P4D balance changes.
    // It&#39;s responsible for withdrawing any outstanding ETH dividends from the P3D exchange
    // as well as distrubuting all of the additional ETH balance since the last update to
    // all of the P4D token holders proportionally.
    // After this it will move any owed subdividends into the customers withdrawable subdividend balance.
    function updateSubdivsFor(address _customerAddress)
        internal
    {   
        // withdraw the P3D dividends first
        if (_P3D.myDividends(true) > 0) {
            _P3D.withdraw();
        }

        // check if we have additional ETH in the contract since the last update
        uint256 contractBalance = address(this).balance;
        if (contractBalance > lastContractBalance_ && totalSupply() != 0) {
            uint256 additionalDivsFromP3D = SafeMath.sub(contractBalance, lastContractBalance_);
            totalDividendPoints_ = SafeMath.add(totalDividendPoints_, SafeMath.div(SafeMath.mul(additionalDivsFromP3D, magnitude), totalSupply()));
            lastContractBalance_ = contractBalance;
        }

        // if this is the very first time this is called for a customer, set their starting point
        if (divsMap_[_customerAddress].lastDividendPoints == 0) {
            divsMap_[_customerAddress].lastDividendPoints = totalDividendPoints_;
        }

        // move any owing subdividends into the customers subdividend balance
        uint256 owing = subdividendsOwing(_customerAddress);
        if (owing > 0) {
            divsMap_[_customerAddress].balance = SafeMath.add(divsMap_[_customerAddress].balance, owing);
            divsMap_[_customerAddress].lastDividendPoints = totalDividendPoints_;
        }
    }

    function withdrawInternal(address _customerAddress)
        internal
    {
        // setup data
        // dividendsOf() will return only divs, not the ref. bonus
        uint256 _dividends = dividendsOf(_customerAddress); // get ref. bonus later in the code

        // update dividend tracker
        payoutsTo_[_customerAddress] += (int256)(_dividends * magnitude);

        // add ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        // store the divs
        dividendsStored_[_customerAddress] = SafeMath.add(dividendsStored_[_customerAddress], _dividends);
    }

    function transferInternal(address _customerAddress, address _toAddress, uint256 _amountOfTokens)
        internal
        returns(bool)
    {
        // make sure we have the requested tokens
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        updateSubdivsFor(_customerAddress);
        updateSubdivsFor(_toAddress);

        // withdraw and store all outstanding dividends first
        withdrawInternal(_customerAddress);

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);

        // update dividend trackers
        payoutsTo_[_customerAddress] -= (int256)(profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256)(profitPerShare_ * _amountOfTokens);

        // fire event
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);

        // ERC20
        return true;
    }

    function purchaseInternal(address _sender, uint256 _incomingEthereum, address _referredBy)
        purchaseFilter(_sender, _incomingEthereum)
        internal
        returns(uint256)
    {

        uint256 purchaseAmount = _incomingEthereum;
        uint256 excess = 0;
        if (totalInputETH_ <= initialBuyLimitCap_) { // check if the total input ETH is less than the cap
            if (purchaseAmount > initialBuyLimitPerTx_) { // if so check if the transaction is over the initial buy limit per transaction
                purchaseAmount = initialBuyLimitPerTx_;
                excess = SafeMath.sub(_incomingEthereum, purchaseAmount);
            }
            totalInputETH_ = SafeMath.add(totalInputETH_, purchaseAmount);
        }

        // return the excess if there is any
        if (excess > 0) {
             _sender.transfer(excess);
        }

        // buy P3D tokens with the entire purchase amount
        // even though _P3D.buy() returns uint256, it was never implemented properly inside the P3D contract
        // so in order to find out how much P3D was purchased, you need to check the balance first then compare
        // the balance after the purchase and the difference will be the amount purchased
        uint256 tmpBalanceBefore = _P3D.myTokens();
        _P3D.buy.value(purchaseAmount)(_referredBy);
        uint256 purchasedP3D = SafeMath.sub(_P3D.myTokens(), tmpBalanceBefore);

        return purchaseTokens(_sender, purchasedP3D, _referredBy);
    }


    function purchaseTokens(address _sender, uint256 _incomingP3D, address _referredBy)
        internal
        returns(uint256)
    {
        updateSubdivsFor(_sender);

        // data setup
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingP3D, buyDividendFee_), 100);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedP3D = SafeMath.sub(_incomingP3D, _undividedDividends);
        uint256 _amountOfTokens = P3DtoTokens_(_taxedP3D);
        uint256 _fee = _dividends * magnitude;

        // no point in continuing execution if OP is a poorfag russian hacker
        // prevents overflow in the case that the pyramid somehow magically starts being used by everyone in the world
        // (or hackers)
        // and yes we know that the safemath function automatically rules out the "greater then" equasion.
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_));

        // is the user referred by a masternode?
        if (
            // is this a referred purchase?
            _referredBy != address(0x0) &&

            // no cheating!
            _referredBy != _sender &&

            // does the referrer have at least X whole tokens?
            // i.e is the referrer a godly chad masternode
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ) {
            // wealth redistribution
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
            // no ref purchase
            // add the referral bonus back to the global dividends cake
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }

        // we can&#39;t give people infinite P3D
        if(tokenSupply_ > 0){

            // add tokens to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));

            // calculate the amount of tokens the customer receives over their purchase
            _fee = _fee - (_fee - (_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));

        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;
        }

        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_sender] = SafeMath.add(tokenBalanceLedger_[_sender], _amountOfTokens);

        // Tells the contract that the buyer doesn&#39;t deserve dividends for the tokens before they owned them;
        // really I know you think you do but you don&#39;t
        payoutsTo_[_sender] += (int256)((profitPerShare_ * _amountOfTokens) - _fee);

        // fire events
        emit onTokenPurchase(_sender, _incomingP3D, _amountOfTokens, _referredBy);
        emit Transfer(address(0x0), _sender, _amountOfTokens);

        return _amountOfTokens;
    }

    /**
     * Calculate token price based on an amount of incoming P3D
     * It&#39;s an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function P3DtoTokens_(uint256 _P3D_received)
        internal
        view
        returns(uint256)
    {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived =
         (
            (
                // underflow attempts BTFO
                SafeMath.sub(
                    (sqrt
                        (
                            (_tokenPriceInitial**2)
                            +
                            (2 * (tokenPriceIncremental_ * 1e18)*(_P3D_received * 1e18))
                            +
                            (((tokenPriceIncremental_)**2) * (tokenSupply_**2))
                            +
                            (2 * (tokenPriceIncremental_) * _tokenPriceInitial * tokenSupply_)
                        )
                    ), _tokenPriceInitial
                )
            ) / (tokenPriceIncremental_)
        ) - (tokenSupply_);

        return _tokensReceived;
    }

    /**
     * Calculate token sell value.
     * It&#39;s an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function tokensToP3D_(uint256 _P4D_tokens)
        internal
        view
        returns(uint256)
    {

        uint256 tokens_ = (_P4D_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _P3D_received =
        (
            // underflow attempts BTFO
            SafeMath.sub(
                (
                    (
                        (
                            tokenPriceInitial_ + (tokenPriceIncremental_ * (_tokenSupply / 1e18))
                        ) - tokenPriceIncremental_
                    ) * (tokens_ - 1e18)
                ), (tokenPriceIncremental_ * ((tokens_**2 - tokens_) / 1e18)) / 2
            )
        / 1e18);

        return _P3D_received;
    }


    // This is where all your gas goes, sorry
    // Not sorry, you probably only paid 1 gwei
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /**
    * Additional check that the address we are sending tokens to is a contract
    * assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    */
    function isContract(address _addr)
        internal
        constant
        returns(bool)
    {
        // retrieve the size of the code on target address, this needs assembly
        uint length;
        assembly { length := extcodesize(_addr) }
        return length > 0;
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
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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


// 
// pragma solidity ^0.4.25;
// 
// interface P4D {
//     function buy(address) external payable returns(uint256);
//     function sell(uint256) external;
//     function transfer(address, uint256) external returns(bool);
//     function myTokens() external view returns(uint256);
//     function myStoredDividends() external view returns(uint256);
//     function mySubdividends() external view returns(uint256);
//     function reinvest(bool) external;
//     function reinvestSubdivs(bool) external;
//     function withdraw(bool) external;
//     function withdrawSubdivs(bool) external;
//     function exit(bool) external; // sell + withdraw + withdrawSubdivs
//     function P3D_address() external view returns(address);
// }
// 
// contract usingP4D {
// 
//     P4D public tokenContract;
// 
//     constructor(address _P4D_address) public {
//         tokenContract = P4D(_P4D_address);
//     }
// 
//     modifier onlyTokenContract {
//         require(msg.sender == address(tokenContract));
//         _;
//     }
// 
//     function tokenCallback(address _from, uint256 _value, bytes _data) external returns (bool);
// }
// 
// contract YourDapp is usingP4D {
// 
//     constructor(address _P4D_address)
//         public
//         usingP4D(_P4D_address)
//     {
//         //...
//     }
// 
//     function tokenCallback(address _from, uint256 _value, bytes _data)
//         external
//         onlyTokenContract
//         returns (bool)
//     {
//         //...
//         return true;
//     }
//
//     function()
//         payable
//         public
//     {
//         if (msg.sender != address(tokenContract)) {
//             //...
//         }
//     }
// }
//
/*===========================================================================================*
*********************************** https://p4d.io/ropsten ***********************************
*===========================================================================================*/