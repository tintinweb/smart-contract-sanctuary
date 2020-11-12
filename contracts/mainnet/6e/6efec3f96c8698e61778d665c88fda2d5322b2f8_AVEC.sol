pragma solidity^0.6.0;
/*
* Team Equitable Builds Inc presents..
* ====================================*
*        _____ ___ _______ ______     *
*       |  _  |  ||  |  __|   __|     *
*       |     |  |  |  __|   |__      *
*       |__|__|_____|____|_____|      *
*                                     *
* ====================================*
*/
contract AVEC{
    /*=================================
    =            MODIFIERS            =
    =================================*/
    //verify caller address members_ = true
    modifier onlyMembers(address _customerAddress) {
        require(
                // is the customer in the member whitelist?
                members_[_customerAddress] == true
            );
            // execute
        _;
    }
    //verify caller address founderdevelopers_ = true
    modifier onlyFounderDevelopers(address _customerAddress) {
        require(
                // is the customer in the Founder Developer whitelist?
                founderdevelopers_[_customerAddress] == true
            );
            // execute
        _;
    }
    //verify caller address ceva_ = true
    modifier onlyCEVA(address _customerAddress) {
        require(
                // is the customer in the ceva whitelist?
                ceva_[_customerAddress] == true
            );
            // execute
        _;
    }
    modifier onlyAdministrator(address _customerAddress){
        require(
            administrators[_customerAddress] == true
            );
        _;
    }
    /*==============================
    =            EVENTS            =
    ==============================*/
    event onWithdraw(
        address indexed customerAddress,
        uint256 tokensWithdrawn
    );
    // ERC20
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );
    event Burn(
        address indexed from,
        uint256 tokens,
        uint256 propertyValue
    );
    // ERC20
    event Approval(
        address indexed _owner, 
        address indexed _spender, 
        uint256 _value
    );
    event PropertyValuation(
        address indexed from,
        bytes32 _propertyUniqueID,
        uint256 propertyValue
    );
    event PropertyWhitelisted(
        address indexed from,
        bytes32 _propertyUniqueID,
        bool _trueFalse
    );
    event MemberWhitelisted(
        address indexed from,
        address indexed to,
        bool _trueFalse
    );
    event FounderDeveloperWhitelisted(
        address indexed from,
        address indexed to,
        bool _trueFalse
    );
    event CEVAWhitelisted(
        address indexed from,
        address indexed to,
        bool _trueFalse
    );
    event AdminWhitelisted(
        address indexed from,
        address indexed to,
        bool _trueFalse
    );
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string private name = "AlternateVirtualEquityCredits";
    string private symbol = "AVEC";
    uint8 private decimals = 18;
    address internal whoaaddress_ = 0x314d0ED76d866826C809fb6a51d63642b2E9eC3e;
    address internal whoamaintenanceaddress_ = 0x2722B426B11978c29660e8395a423Ccb93AE0403;
    address internal whoarewardsaddress_ = 0xA9d241b568DF9E8A7Ec9e44737f29a8Ee00bfF53;
    address internal cevaaddress_ = 0xdE281c22976dE2E9b3f4F87bEB60aE9E67DFf5C4;
    address internal credibleyouaddress_ = 0xc9c1Ffd6B4014232Ef474Daa4CA1506A6E39Be89;
    address internal techaddress_ = 0xB6148C62e6A6d48f41241D01e3C4841139144ABa;
    address internal existholdingsaddress_ = 0xac1B6580a175C1f2a4e3220A24e6f65fF3AB8A03;
    address internal existcryptoaddress_ = 0xb8C098eE976f1162aD277936a5D1BCA7a8Fe61f5;
    // founder developer address whitelist archive
    mapping(address => bool) internal members_;
    // members whitelist address archive
    mapping(address => bool) internal founderdevelopers_;
    // ceva whitelist address archive
    mapping(address => bool) internal ceva_;
    // administrator list (see above on what they can do)
    mapping(address => bool) internal administrators;
    // setting for allowance function determines amount of tokens address can spend from mapped address
    mapping (address => mapping (address => uint256)) private _allowed;
    mapping (address => mapping(bytes32 => bool)) internal mintrequestwhitelist_;
    mapping (address => mapping(bytes32 => bool)) internal burnrequestwhitelist_;
    mapping (address => mapping(bytes32 => bool)) internal propertywhitelist_;
    mapping (address => mapping(bytes32 => uint256)) internal propertyvalue_;
    mapping(address => bytes32) workingPropertyid_;
    mapping(address => bytes32) workingMintRequestid_;
    mapping(address => bytes32) workingBurnRequestid_;
   /*================================
    =            DATASETS            =
    ================================*/
    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_ ;
    mapping(address => uint256) internal mintingDepositsOf_;
    mapping(address => uint256) internal AmountCirculated_;
    mapping(address => uint256) internal taxesFeeTotalWithdrawn_;
    mapping(address => uint256) internal taxesPreviousWithdrawn_;
    mapping(address => uint256) internal taxesFeeSharehold_;
    mapping(address => uint256) internal insuranceFeeTotalWithdrawn_;
    mapping(address => uint256) internal insurancePreviousWithdrawn_;
    mapping(address => uint256) internal insuranceFeeSharehold_;
    mapping(address => uint256) internal maintenanceFeeTotalWithdrawn_;
    mapping(address => uint256) internal maintenancePreviousWithdrawn_;
    mapping(address => uint256) internal maintenanceFeeSharehold_;
    mapping(address => uint256) internal waECOFeeTotalWithdrawn_;
    mapping(address => uint256) internal waECOPreviousWithdrawn_;
    mapping(address => uint256) internal waECOFeeSharehold_;
    mapping(address => uint256) internal holdoneTotalWithdrawn_;
    mapping(address => uint256) internal holdonePreviousWithdrawn_;
    mapping(address => uint256) internal holdoneSharehold_;
    mapping(address => uint256) internal holdtwoTotalWithdrawn_;
    mapping(address => uint256) internal holdtwoPreviousWithdrawn_;
    mapping(address => uint256) internal holdtwoSharehold_;
    mapping(address => uint256) internal holdthreeTotalWithdrawn_;
    mapping(address => uint256) internal holdthreePreviousWithdrawn_;
    mapping(address => uint256) internal holdthreeSharehold_;
    mapping(address => uint256) internal rewardsTotalWithdrawn_;
    mapping(address => uint256) internal rewardsPreviousWithdrawn_;
    mapping(address => uint256) internal rewardsSharehold_;
    mapping(address => uint256) internal techTotalWithdrawn_;
    mapping(address => uint256) internal techPreviousWithdrawn_;
    mapping(address => uint256) internal techSharehold_;
    mapping(address => uint256) internal existholdingsTotalWithdrawn_;
    mapping(address => uint256) internal existholdingsPreviousWithdrawn_;
    mapping(address => uint256) internal existholdingsSharehold_;
    mapping(address => uint256) internal existcryptoTotalWithdrawn_;
    mapping(address => uint256) internal existcryptoPreviousWithdrawn_;
    mapping(address => uint256) internal existcryptoSharehold_;
    mapping(address => uint256) internal whoaTotalWithdrawn_;
    mapping(address => uint256) internal whoaPreviousWithdrawn_;
    mapping(address => uint256) internal whoaSharehold_;
    mapping(address => uint256) internal credibleyouTotalWithdrawn_;
    mapping(address => uint256) internal credibleyouPreviousWithdrawn_;
    mapping(address => uint256) internal credibleyouSharehold_;
    mapping(address => uint256) internal numberofmintingrequestswhitelisted_;
    mapping(address => uint256) internal numberofpropertieswhitelisted_;
    mapping(address => uint256) internal numberofburnrequestswhitelisted_;
    mapping(address => uint256) internal transferingFromWallet_;
    uint256 public tokenSupply_ = 0;
    uint256 public feeTotalHolds_ = 0;
    uint256 internal cevaBurnerStockpile_ = 0;
    uint256 internal cevaBurnerStockpileWithdrawn_ = 0;
    uint256 internal taxesfeeTotalHolds_ = 0;
    uint256 internal taxesfeeBalanceLedger_ = 0;
    uint256 internal insurancefeeTotalHolds_ = 0;
    uint256 internal insurancefeeBalanceLedger_ = 0;
    uint256 internal maintencancefeeTotalHolds_ = 0;
    uint256 internal maintenancefeeBalanceLedger_ = 0;
    uint256 internal waECOfeeTotalHolds_ = 0;
    uint256 internal waECOfeeBalanceLedger_ = 0;
    uint256 internal holdonefeeTotalHolds_ = 0;
    uint256 internal holdonefeeBalanceLedger_ = 0;
    uint256 internal holdtwofeeTotalHolds_ = 0;
    uint256 internal holdtwofeeBalanceLedger_ = 0;
    uint256 internal holdthreefeeTotalHolds_ = 0;
    uint256 internal holdthreefeeBalanceLedger_ = 0;
    uint256 internal RewardsfeeTotalHolds_ = 0;
    uint256 internal RewardsfeeBalanceLedger_ = 0;
    uint256 internal techfeeTotalHolds_ = 0;
    uint256 internal techfeeBalanceLedger_ = 0;
    uint256 internal existholdingsfeeTotalHolds_ = 0;
    uint256 internal existholdingsfeeBalanceLedger_ = 0;
    uint256 internal existcryptofeeTotalHolds_ = 0;
    uint256 internal existcryptofeeBalanceLedger_ = 0;
    uint256 internal whoafeeTotalHolds_ = 0;
    uint256 internal whoafeeBalanceLedger_ = 0;
    uint256 internal credibleyoufeeTotalHolds_ = 0;
    uint256 internal credibleyoufeeBalanceLedger_ = 0;
    /*=======================================
    =            MEMBER FUNCTIONS            =
    =======================================*/
    /*
    * -- APPLICATION ENTRY POINTS -- 
    */
    constructor()
        public
    {
    }
    /*
    * -- APPLICATION ENTRY POINTS -- 
    */
    function InitialSet()
        public
    {
        // add the first users
        //James Admin
        administrators[0x27851761A8fBC03f57965b42528B39af07cdC42b] = true;
        //Brenden Admin
        administrators[0xA9873d93db3BCA9F68aDfEAb226Fa9189641069A] = true;
        members_[0x314d0ED76d866826C809fb6a51d63642b2E9eC3e] = true;
        members_[0x2722B426B11978c29660e8395a423Ccb93AE0403] = true;
        members_[0xdE281c22976dE2E9b3f4F87bEB60aE9E67DFf5C4] = true;
        members_[0xc9c1Ffd6B4014232Ef474Daa4CA1506A6E39Be89] = true;
        members_[0xac1B6580a175C1f2a4e3220A24e6f65fF3AB8A03] = true;
        members_[0xb8C098eE976f1162aD277936a5D1BCA7a8Fe61f5] = true;
        members_[0xB6148C62e6A6d48f41241D01e3C4841139144ABa] = true;
        members_[0xA9d241b568DF9E8A7Ec9e44737f29a8Ee00bfF53] = true;
        members_[0x314d0ED76d866826C809fb6a51d63642b2E9eC3e] = true;
        members_[0x314d0ED76d866826C809fb6a51d63642b2E9eC3e] = true;
        
    }
    /*
    * -- APPLICATION ENTRY POINTS -- 
    */
    function genesis(address _existcryptoaddress, address _existhooldingsaddress, address _techaddress, 
        address _credibleyouaddress, address _cevaaddress, address _whoaddress, address _whoarewardsaddress, address _whoamaintenanceaddress)
        public
        onlyAdministrator(msg.sender)
    {
        require(administrators[msg.sender]);
        // adds the first founder developer here.
        founderdevelopers_[msg.sender] = true;
        // adds the _whoaddress input as the current whoa address
        whoaaddress_ = _whoaddress;
        // adds the _whoamaintenanceaddress input as the current whoa maintenence address
        whoamaintenanceaddress_ = _whoamaintenanceaddress;
        // adds the _whoarewardsaddress input as the current whoa rewards address
        whoarewardsaddress_ = _whoarewardsaddress;
        // adds the )cevaaddress_ input as the current ceva address
        cevaaddress_ = _cevaaddress;
        // adds the _credibleyouaddress input as the current credible you address
        credibleyouaddress_ = _credibleyouaddress;
        // adds the _techaddress input as the current tech address
        techaddress_ = _techaddress;
        // adds the __existhooldingsaddress input as the current exist holdings address
        existholdingsaddress_ = _existhooldingsaddress;
        // adds the _existcryptoaddress input as the current exist crypto address
        existcryptoaddress_ = _existcryptoaddress;
        // adds the first ceva qualified founder developers here.
        ceva_[msg.sender] = true;
        numberofburnrequestswhitelisted_[msg.sender] = 0;
        numberofpropertieswhitelisted_[msg.sender] = 0;
        numberofmintingrequestswhitelisted_[msg.sender] = 0;
        // adds the first member here.
        members_[msg.sender] = true;
    }
    /**
     * Withdraws all of the callers taxes earnings.
     */
    function buyFounderDeveloperLicense(address _FounderDeveloperOne, address _FounderDeveloperTwo, address _CEVA)
        onlyMembers(msg.sender)
        public
        returns(bool _success)
    {
        require(founderdevelopers_[_FounderDeveloperOne] == true && ceva_[_CEVA] == true && founderdevelopers_[_FounderDeveloperTwo] == true);
        // setup data
            address _customerAddress = msg.sender;
            uint256 _licenseprice = (1000 * 1e18);
            if(tokenBalanceLedger_[_customerAddress] > _licenseprice){
                tokenBalanceLedger_[_CEVA] = (_licenseprice / 5) + tokenBalanceLedger_[_CEVA];
                tokenBalanceLedger_[_FounderDeveloperOne] =  (_licenseprice / 5) + tokenBalanceLedger_[_FounderDeveloperOne];
                tokenBalanceLedger_[_FounderDeveloperTwo] =  (_licenseprice / 10) + tokenBalanceLedger_[_FounderDeveloperTwo];
                tokenBalanceLedger_[_customerAddress] =  tokenBalanceLedger_[_customerAddress] - _licenseprice;
                founderdevelopers_[_customerAddress] = true;
                return true;
            } else {
                return false;
        }
    }
    /**
     * Withdraws all of the callers taxes earnings.
     */
    function withdrawTaxesdividends()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = EtaxesdividendsOf(msg.sender);
        // update dividend tracker
        taxesFeeTotalWithdrawn_[_customerAddress] +=  _dividends;
        tokenBalanceLedger_[_customerAddress] +=  _dividends;
        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }
    /**
     * Withdraws all of the callers taxes earnings.
     */
    function withdrawInsurancedividends()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = EinsurancedividendsOf(msg.sender);
        // update dividend tracker
        insuranceFeeTotalWithdrawn_[_customerAddress] += _dividends;
        tokenBalanceLedger_[_customerAddress] += _dividends;
        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }
    /**
     * Withdraws all of the callers taxes earnings.
     */
    function withdrawMaintenancedividends()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = EmaintenancedividendsOf(msg.sender);
        // update dividend tracker
        maintenanceFeeTotalWithdrawn_[_customerAddress] += _dividends;
        tokenBalanceLedger_[_customerAddress] += _dividends;
        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }
    /**
     * Withdraws all of the callers taxes earnings.
     */
    function withdrawwaECOdividends()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = EwaECOdividendsOf(msg.sender);
        // update dividend tracker
        maintenanceFeeTotalWithdrawn_[_customerAddress] +=  _dividends;
        waECOFeeTotalWithdrawn_[_customerAddress] +=  _dividends;
        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }
    /**
     * Withdraws all of the callers taxes earnings.
     */
    function withdrawHoldOnedividends()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = EholdonedividendsOf(msg.sender);
        // update dividend tracker
        holdoneTotalWithdrawn_[_customerAddress] +=  _dividends;
        tokenBalanceLedger_[_customerAddress] +=  _dividends;
        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }
    /**
     * Withdraws all of the callers taxes earnings.
     */
    function withdrawHoldTwodividends()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = EholdtwodividendsOf(msg.sender);
        // update dividend tracker
        holdtwoTotalWithdrawn_[_customerAddress] +=  _dividends;
        tokenBalanceLedger_[_customerAddress] +=  _dividends;
        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }
    /**
     * Withdraws all of the callers taxes earnings.
     */
    function withdrawHoldThreeedividends()
        onlyMembers(msg.sender)
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = EholdthreedividendsOf(msg.sender);
        // update dividend tracker
        holdthreeTotalWithdrawn_[_customerAddress] +=  _dividends;
        tokenBalanceLedger_[_customerAddress] +=  _dividends;
        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }
    /**
     * Withdraws all of the callers taxes earnings.
     */
    function withdrawRewardsdividends()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = ErewardsdividendsOf(msg.sender);
        // update dividend tracker
        rewardsTotalWithdrawn_[_customerAddress] +=  _dividends;
        tokenBalanceLedger_[_customerAddress] +=  _dividends;
        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }
    /**
     * Withdraws all of the callers taxes earnings.
     */
    function withdrawTechdividends()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = EtechdividendsOf(msg.sender);
        // update dividend tracker
        techTotalWithdrawn_[_customerAddress] +=  _dividends;
        tokenBalanceLedger_[_customerAddress] +=  _dividends;
        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }
    /**
     * Withdraws all of the callers taxes earnings.
     */
    function withdrawExistHoldingsdividends()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = existholdingsdividendsOf(msg.sender);
        // update dividend tracker
        existholdingsTotalWithdrawn_[_customerAddress] +=  _dividends;
        tokenBalanceLedger_[_customerAddress] +=  _dividends;
        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }
    /**
     * Withdraws all of the callers taxes earnings.
     */
    function withdrawExistCryptodividends()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = existcryptodividendsOf(msg.sender);
        // update dividend tracker
        existcryptoTotalWithdrawn_[_customerAddress] +=  _dividends;
        tokenBalanceLedger_[_customerAddress] +=  _dividends;
        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }
    /**
     * Withdraws all of the callers taxes earnings.
     */
    function withdrawWHOAdividends()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = EwhoadividendsOf(msg.sender);
        // update dividend tracker
        whoaTotalWithdrawn_[_customerAddress] +=  _dividends;
        tokenBalanceLedger_[_customerAddress] +=  _dividends;
        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }
    /**
     * Withdraws all of the callers taxes earnings.
     */
    function withdrawCrediblelYoudividends()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = EcredibleyoudividendsOf(msg.sender);
        // update dividend tracker
        credibleyouTotalWithdrawn_[_customerAddress] +=  _dividends;
        tokenBalanceLedger_[_customerAddress] +=  _dividends;
        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }
    /**
     * Transfer tokens from the caller to a new holder.
     * Remember, there's a 2% fee here as well. members only
     */
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyMembers(msg.sender)
        public
        returns(bool)
    {
        if(_amountOfTokens > 0){
        // make sure we have the requested tokens
            require(_amountOfTokens + (_amountOfTokens / 50) <= tokenBalanceLedger_[msg.sender] && 
            _amountOfTokens >= 0 && _toAddress != msg.sender && members_[_toAddress] == true);
        //Exchange tokens
            tokenBalanceLedger_[_toAddress] = tokenBalanceLedger_[_toAddress] + _amountOfTokens;
            tokenBalanceLedger_[msg.sender] -= _amountOfTokens + (_amountOfTokens / 50);
        //Update Equity Rents
            updateEquityRents(_amountOfTokens);
            AmountCirculated_[msg.sender] += _amountOfTokens;
            emit Transfer(msg.sender, _toAddress, (_amountOfTokens + (_amountOfTokens / 50)));
            return true;
        } else {
            return false;
        }
    }
    /**
     * Transfer tokens from the caller to a new holder.
     * Remember, there's a 2% fee here as well. members only
     */
    function transferFrom(address from, address to, uint256 tokens)
        onlyMembers(msg.sender)
        public
        returns(bool)
    {
        if(tokens >= 0){
            require(members_[to] == true);
            // setup
            address _customerAddress = msg.sender;
            // make sure we have the requested tokens
            require(tokens + (tokens / 50) <= tokenBalanceLedger_[from] && tokens >= 0 && to != _customerAddress && from != to && 
            tokens + (tokens / 50) <= _allowed[from][msg.sender] && msg.sender != from && transferingFromWallet_[msg.sender] == 0);
            transferingFromWallet_[msg.sender] = 1;
            //Exchange tokens
            tokenBalanceLedger_[to] = tokenBalanceLedger_[to] + tokens;
            tokenBalanceLedger_[msg.sender] -= tokens + (tokens / 50);
            //Reduce Approval Amount
            _allowed[from][msg.sender] -= tokens + (tokens / 50);
            emit Transfer(_customerAddress, to, (tokens + (tokens / 50)));
            transferingFromWallet_[msg.sender] = 0;
            return true;
        } else {
            return false;
        }
    }
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return _allowed[tokenOwner][spender];
    }
     /**
     * Transfer tokens from the caller to a new holder.
     * Remember, there's a 2% fee here as well. members only
     */
    function clearTitle(uint256 _propertyValue, uint256 _amountOfTokens, address _clearFrom)
        onlyMembers(msg.sender)
        public
        returns(bool)
    {
        if((_amountOfTokens / 1e18) * 100 <= _propertyValue){
            require(burnrequestwhitelist_[_clearFrom][workingBurnRequestid_[msg.sender]] == true && propertywhitelist_[_clearFrom][workingPropertyid_[msg.sender]] == true && 
            _amountOfTokens <= tokenBalanceLedger_[_clearFrom] && _amountOfTokens >= 0);
            //Burn Tokens
            burnA(_propertyValue);
            tokenSupply_ -= _amountOfTokens;
            taxesfeeTotalHolds_ -= _propertyValue / 100;
            insurancefeeTotalHolds_ -= (propertyvalue_[_clearFrom][workingPropertyid_[msg.sender]] / 100);
            maintencancefeeTotalHolds_ -= (propertyvalue_[_clearFrom][workingPropertyid_[msg.sender]] / 100);
            waECOfeeTotalHolds_ -= (propertyvalue_[_clearFrom][workingPropertyid_[msg.sender]] / 100);
            holdonefeeTotalHolds_ -= (propertyvalue_[_clearFrom][workingPropertyid_[msg.sender]] / 100);
            holdtwofeeTotalHolds_ -= (propertyvalue_[_clearFrom][workingPropertyid_[msg.sender]] / 100);
            holdthreefeeTotalHolds_ -= (propertyvalue_[_clearFrom][workingPropertyid_[msg.sender]] / 100); 
            // take tokens out of stockpile
            //Exchange tokens
            cevaBurnerStockpile_ -= ((propertyvalue_[_clearFrom][workingPropertyid_[msg.sender]] / 100) * 1e18) - _amountOfTokens;
            tokenBalanceLedger_[msg.sender] -= _amountOfTokens;
            //  burn fee shareholds
            taxesFeeSharehold_[msg.sender] -= (propertyvalue_[_clearFrom][workingPropertyid_[msg.sender]] / 100);
            insuranceFeeSharehold_[msg.sender] -= (propertyvalue_[_clearFrom][workingPropertyid_[msg.sender]] / 100);
            maintenanceFeeSharehold_[whoamaintenanceaddress_] -= (propertyvalue_[_clearFrom][workingPropertyid_[msg.sender]] / 100);
            waECOFeeSharehold_[msg.sender] -= (propertyvalue_[_clearFrom][workingPropertyid_[msg.sender]] / 100);
            holdoneSharehold_[msg.sender] -= (propertyvalue_[_clearFrom][workingPropertyid_[msg.sender]] / 100);
            holdtwoSharehold_[msg.sender] -= (propertyvalue_[_clearFrom][workingPropertyid_[msg.sender]] / 100);
            holdthreeSharehold_[msg.sender] -= (propertyvalue_[_clearFrom][workingPropertyid_[msg.sender]] / 100);
            rewardsSharehold_[msg.sender] -= (propertyvalue_[_clearFrom][workingPropertyid_[msg.sender]] / 100);
            techSharehold_[techaddress_] -= (propertyvalue_[_clearFrom][workingPropertyid_[msg.sender]] / 100);
            existholdingsSharehold_[existholdingsaddress_] -= (propertyvalue_[_clearFrom][workingPropertyid_[msg.sender]] / 100);
            existcryptoSharehold_[existcryptoaddress_] -= (propertyvalue_[_clearFrom][workingPropertyid_[msg.sender]] / 100);
            whoaSharehold_[whoaaddress_] -= (propertyvalue_[_clearFrom][workingPropertyid_[msg.sender]] / 100);
            credibleyouSharehold_[credibleyouaddress_] -= (propertyvalue_[_clearFrom][workingPropertyid_[msg.sender]] / 100);
            // returns bool true
            emit Burn(msg.sender, _amountOfTokens, _propertyValue);
            
            return true;
        } else {
            return false;
        }
    }
    /**
     * Transfer fee sharehold from the caller to a new holder.
     */
    function sellTaxesFeeSharehold(address _toAddress, uint256 _amount)
        onlyMembers(msg.sender)
        public
        returns(bool)
    {
        if(_amount > 0){
            require(members_[_toAddress] == true);
        // setup
            address _customerAddress = msg.sender;
        // make sure we have the requested sharehold
            require(_amount <= taxesFeeSharehold_[_customerAddress] && _amount >= 0 && _toAddress != _customerAddress);
        //Update fee sharehold previous withdrawals    
                taxesPreviousWithdrawn_[_toAddress] += (taxesFeeTotalWithdrawn_[_customerAddress] / taxesFeeSharehold_[_customerAddress]) * _amount;
        //Exchange sharehold
                taxesFeeSharehold_[_toAddress] += _amount;
                taxesFeeSharehold_[_customerAddress] -= _amount;
                return true;
        } else {
            return false;
        }
    }
    /**
     * Transfer fee sharehold from the caller to a new holder.
     */
    function sellInsuranceFeeSharehold(address _toAddress, uint256 _amount)
        onlyMembers(msg.sender)
        public
        returns(bool)
    {
        if(_amount > 0){
            require(members_[_toAddress] == true);
        // setup
            address _customerAddress = msg.sender;
        // make sure we have the requested sharehold
            require(_amount <= insuranceFeeSharehold_[_customerAddress] && _amount >= 0 && _toAddress != _customerAddress);
        //Update fee sharehold previous withdrawals    
                insurancePreviousWithdrawn_[_toAddress] += (insuranceFeeTotalWithdrawn_[_customerAddress] / insuranceFeeSharehold_[_customerAddress]) * _amount;
        //Exchange sharehold
                insuranceFeeSharehold_[_toAddress] += _amount;
                insuranceFeeSharehold_[_customerAddress] -= _amount;
                return true;
        } else {
            return false;
        }
    }
    /**
     * Transfer fee sharehold from the caller to a new holder.
     */
    function sellMaintenanceFeeSharehold(address _toAddress, uint256 _amount)
        onlyMembers(msg.sender)
        public
        returns(bool)
    {
        if(_amount > 0){
            require(members_[_toAddress] == true);
        // setup
            address _customerAddress = msg.sender;
        // make sure we have the requested sharehold
            require(_amount <= maintenanceFeeSharehold_[_customerAddress] && _amount >= 0 && _toAddress != _customerAddress);
        //Update fee sharehold previous withdrawals    
                maintenancePreviousWithdrawn_[_toAddress] += (maintenanceFeeTotalWithdrawn_[_customerAddress] / maintenanceFeeSharehold_[_customerAddress]) * _amount;
        //Exchange sharehold
                maintenanceFeeSharehold_[_toAddress] += _amount;
                maintenanceFeeSharehold_[_customerAddress] -= _amount;
                return true;
        } else {
            return false;
        }
    }
    /**
     * Transfer fee sharehold from the caller to a new holder.
     */
    function sellwaECOFeeSharehold(address _toAddress, uint256 _amount)
        onlyMembers(msg.sender)
        public
        returns(bool)
    {
        if(_amount > 0){
            require(members_[_toAddress] == true);
        // setup
            address _customerAddress = msg.sender;
        // make sure we have the requested sharehold
            require(_amount <= waECOFeeSharehold_[_customerAddress] && _amount >= 0 && _toAddress != _customerAddress);
        //Update fee sharehold previous withdrawals    
                waECOPreviousWithdrawn_[_toAddress] += (waECOFeeTotalWithdrawn_[_customerAddress] / waECOFeeSharehold_[_customerAddress]) * _amount;
        //Exchange sharehold
                waECOFeeSharehold_[_toAddress] += _amount;
                waECOFeeSharehold_[_customerAddress] -= _amount;
                return true;
        } else {
            return false;
        }
    }
    /**
     * Transfer fee sharehold from the caller to a new holder.
     */
    function sellHoldOneFeeSharehold(address _toAddress, uint256 _amount)
        onlyMembers(msg.sender)
        public
        returns(bool)
    {
        if(_amount > 0){
            require(members_[_toAddress] == true);
        // setup
            address _customerAddress = msg.sender;
        // make sure we have the requested sharehold
            require(_amount <= holdoneSharehold_[_customerAddress] && _amount >= 0 && _toAddress != _customerAddress);
        //Update fee sharehold previous withdrawals    
                holdonePreviousWithdrawn_[_toAddress] += (holdoneTotalWithdrawn_[_customerAddress] / holdoneSharehold_[_customerAddress]) * _amount;
        //Exchange sharehold
                holdoneSharehold_[_toAddress] += _amount;
                holdoneSharehold_[_customerAddress] -= _amount;
                return true;
        } else {
            return false;
        }
    }
    /**
     * Transfer fee sharehold from the caller to a new holder.
     */
    function sellHoldTwoFeeSharehold(address _toAddress, uint256 _amount)
        onlyMembers(msg.sender)
        public
        returns(bool)
    {
        if(_amount > 0){
            require(members_[_toAddress] == true);
        // setup
            address _customerAddress = msg.sender;
        // make sure we have the requested sharehold
            require(_amount <= holdtwoSharehold_[_customerAddress] && _amount >= 0 && _toAddress != _customerAddress);
        //Update fee sharehold previous withdrawals    
                holdtwoPreviousWithdrawn_[_toAddress] += (holdtwoTotalWithdrawn_[_customerAddress] / holdtwoSharehold_[_customerAddress]) * _amount;
        //Exchange sharehold
                holdtwoSharehold_[_toAddress] += _amount;
                holdtwoSharehold_[_customerAddress] -= _amount;
            
                return true;
        } else {
            return false;
        }
    }
    /**
     * Transfer fee sharehold from the caller to a new holder.
     */
    function sellHoldThreeFeeSharehold(address _toAddress, uint256 _amount)
        onlyMembers(msg.sender)
        public
        returns(bool)
    {
        if(_amount > 0){
            require(members_[_toAddress] == true);
        // setup
            address _customerAddress = msg.sender;
        // make sure we have the requested sharehold
            require(_amount <= holdthreeSharehold_[_customerAddress] && _amount >= 0 && _toAddress != _customerAddress);
        //Update fee sharehold previous withdrawals    
                holdthreePreviousWithdrawn_[_toAddress] += (holdthreeTotalWithdrawn_[_customerAddress] / holdthreeSharehold_[_customerAddress]) * _amount;
        //Exchange sharehold
                holdthreeSharehold_[_toAddress] += _amount;
                holdthreeSharehold_[_customerAddress] -= _amount;
                return true;
        } else {
            return false;
        }
    }
    /**
     * Transfer fee sharehold from the caller to a new holder.
     */
    function sellRewardsFeeSharehold(address _toAddress, uint256 _amount)
        onlyMembers(msg.sender)
        public
        returns(bool)
    {
        if(_amount > 0){
            require(members_[_toAddress] == true);
        // setup
            address _customerAddress = msg.sender;
        // make sure we have the requested sharehold
            require(_amount <= rewardsSharehold_[_customerAddress] && _amount >= 0 && _toAddress != _customerAddress);
        //Update fee sharehold previous withdrawals    
                rewardsPreviousWithdrawn_[_toAddress] += (rewardsTotalWithdrawn_[_customerAddress] / rewardsSharehold_[_customerAddress]) * _amount;
        //Exchange sharehold
                rewardsSharehold_[_toAddress] += _amount;
                rewardsSharehold_[_customerAddress] -= _amount;
                return true;
        } else {
            return false;
        }
    }
    /**
     * Transfer fee sharehold from the caller to a new holder.
     */
    function sellTechFeeSharehold(address _toAddress, uint256 _amount)
        onlyMembers(msg.sender)
        public
        returns(bool)
    {
        if(_amount > 0){
            require(members_[_toAddress] == true);
        // setup
            address _customerAddress = msg.sender;
        // make sure we have the requested sharehold
            require(_amount <= techSharehold_[_customerAddress] && _amount >= 0 && _toAddress != _customerAddress);
        //Update fee sharehold previous withdrawals    
                techPreviousWithdrawn_[_toAddress] += (techTotalWithdrawn_[_customerAddress] / techSharehold_[_customerAddress]) * _amount;
        //Exchange sharehold
                techSharehold_[_toAddress] += _amount;
                techSharehold_[_customerAddress] -= _amount;
                return true;
        } else {
            return false;
        }
    }
    /**
     * Transfer fee sharehold from the caller to a new holder.
     */
    function sellExistHoldingsFeeSharehold(address _toAddress, uint256 _amount)
        onlyMembers(msg.sender)
        onlyMembers(_toAddress)
        public
        returns(bool)
    {
        if(_amount > 0){
            //require(members_[_toAddress] == true);
        // setup
            address _customerAddress = msg.sender;
        // make sure we have the requested sharehold
            require(_amount <= existholdingsSharehold_[_customerAddress] && _amount >= 0 && _toAddress != _customerAddress);
        //Update fee sharehold previous withdrawals    
                existholdingsPreviousWithdrawn_[_toAddress] += (existholdingsTotalWithdrawn_[_customerAddress] / existholdingsSharehold_[_customerAddress]) * _amount;
        //Exchange sharehold
                existholdingsSharehold_[_toAddress] += _amount;
                existholdingsSharehold_[_customerAddress] -= _amount;
                return true;
        } else {
            return false;
        }
    }
    /**
     * Transfer fee sharehold from the caller to a new holder.
     */
    function sellExistCryptoFeeSharehold(address _toAddress, uint256 _amount)
        onlyMembers(msg.sender)
        public
        returns(bool)
    {
        if(_amount > 0){
            require(members_[_toAddress] == true);
        // setup
            address _customerAddress = msg.sender;
        // make sure we have the requested sharehold
            require(_amount <= existcryptoSharehold_[_customerAddress] && _amount >= 0 && _toAddress != _customerAddress);
        //Update fee sharehold previous withdrawals    
                existcryptoPreviousWithdrawn_[_toAddress] += (existcryptoTotalWithdrawn_[_customerAddress] / existcryptoSharehold_[_customerAddress]) * _amount;
        //Exchange sharehold
                existcryptoSharehold_[_toAddress] += _amount;
                existcryptoSharehold_[_customerAddress] -= _amount;
                return true;
        } else {
            return false;
        }
    }
    /**
     * Transfer fee sharehold from the caller to a new holder.
     */
    function sellWHOAFeeSharehold(address _toAddress, uint256 _amount)
        onlyMembers(msg.sender)
        public
        returns(bool)
    {
        if(_amount > 0){
            require(members_[_toAddress] == true);
        // setup
         address _customerAddress = msg.sender;
        // make sure we have the requested sharehold
            require(_amount <= whoaSharehold_[_customerAddress] && _amount >= 0 && _toAddress != _customerAddress);
        //Update fee sharehold previous withdrawals    
                whoaPreviousWithdrawn_[_toAddress] += (whoaTotalWithdrawn_[_customerAddress] / whoaSharehold_[_customerAddress]) * _amount;
        //Exchange sharehold
                whoaSharehold_[_toAddress] += _amount;
                whoaSharehold_[_customerAddress] -= _amount;
                return true;
        } else {
            return false;
        }
    }
    /**
     * Transfer fee sharehold from the caller to a new holder.
     */
    function sellCredibleYouFeeSharehold(address _toAddress, uint256 _amount)
        onlyMembers(msg.sender)
        public
        returns(bool)
    {
        if(_amount > 0){
            require(members_[_toAddress] == true);
        // setup
            address _customerAddress = msg.sender;
        // make sure we have the requested sharehold
            require(_amount <= credibleyouSharehold_[_customerAddress] && _amount >= 0 && _toAddress != _customerAddress);
        //Update fee sharehold previous withdrawals    
                credibleyouPreviousWithdrawn_[_toAddress] += (credibleyouTotalWithdrawn_[_customerAddress] / credibleyouSharehold_[_customerAddress]) * _amount;
        //Exchange sharehold
                credibleyouSharehold_[_toAddress] += _amount;
                credibleyouSharehold_[_customerAddress] -= _amount;
                return true;
        } else {
            return false;
        }
    }
    /**
     * Check and address to see if it has CEVA privileges or not
     */
    function checkCEVA(address _identifier)
        public
        view
        returns(bool)
    {
        if(ceva_[_identifier] == true){
            return true;
        } else {
            return false;
        }
    }
    /**
     * Check and address to see if it has member privileges
     */
    function checkMember(address _identifier)
        public
        view
        returns(bool) 
    {
        if(members_[_identifier] == true){
            return true;
        } else {
            return false;
        }
    }
    /**
     * Check and address to see is its got founder developer privileges
     */
    function checkFounderDeveloper(address _identifier)
        public
        view
        returns(bool)
    {
        if(founderdevelopers_[_identifier] == true){
            return true;
        } else {
            return false;
        }
    }
    /**
     * Check and address to see if it has admin privileges
     */
    function checkAdmin(address _identifier)
        public
        view
        returns(bool)
    {
        if(administrators[_identifier] == true){
            return true;
        } else {
            return false;
        }
    }
    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/
    /**
     * whitelist Admins admin only
     */
    function AwhitelistAdministrator(address _identifier, bool _status)
        onlyAdministrator(msg.sender)
        public
    {
        require(msg.sender != _identifier);
            administrators[_identifier] = _status;
            emit AdminWhitelisted(msg.sender, _identifier, _status);
    }
    /**
     * Automation entrypoint to whitelist ceva_ admin only
     */
    function AwhitelistCEVA(address _identifier, bool _status)
        onlyAdministrator(msg.sender)
        public
    {
        require(msg.sender != _identifier);
            ceva_[_identifier] = _status;
            numberofburnrequestswhitelisted_[msg.sender] = 0;
            numberofpropertieswhitelisted_[msg.sender] = 0;
            numberofmintingrequestswhitelisted_[msg.sender] = 0;
            emit CEVAWhitelisted(msg.sender, _identifier, _status);
    }
    function withdrawCEVABurnerStockpiledividends(uint256 _amountOfTokens)
        onlyCEVA(msg.sender)
        public
    {
        // setup data
        require(_amountOfTokens <= cevaBurnerStockpile_);
            // update dividend tracker
            cevaBurnerStockpile_ -= _amountOfTokens;
            cevaBurnerStockpileWithdrawn_ += _amountOfTokens;
            tokenBalanceLedger_[cevaaddress_] += _amountOfTokens;
            emit Transfer(msg.sender, msg.sender, _amountOfTokens);
    }
    /**
     * Whitelist a Property that has been confirmed on the site.. ceva only
     */
    function AwhitelistMintRequest(address _OwnerAddress, bool _trueFalse, bytes32 _mintingRequestUniqueid)
        onlyCEVA(msg.sender)
        public
        returns(bool)
    {
        if(_mintingRequestUniqueid == workingMintRequestid_[msg.sender]){
            require(msg.sender != _OwnerAddress);
            mintrequestwhitelist_[_OwnerAddress][_mintingRequestUniqueid] = _trueFalse;
            return true;
        } else { 
            return false;
        }
    }
    /**
     * Whitelist a Property that has been confirmed on the site.. ceva only
     */
    function AwhitelistBurnRequest(address _OwnerAddress, bool _trueFalse, bytes32 _burnrequestUniqueID)
        onlyCEVA(msg.sender)
        public
        returns(bool)
    {
        if(_burnrequestUniqueID == workingBurnRequestid_[msg.sender]){
            require(msg.sender != _OwnerAddress);
            burnrequestwhitelist_[_OwnerAddress][_burnrequestUniqueID] = _trueFalse;
            return true;
        } else { 
            return false;
        }
    }
    
    /**
     * Whitelist a Minting Request that has been confirmed on the site.. ceva only
     */
    function AwhitelistProperty(address _OwnerAddress, bool _trueFalse, bytes32 _propertyUniqueID)
        onlyCEVA(msg.sender)
        public
        returns(bool)
    {
        if(_trueFalse = true){
            require(workingPropertyid_[msg.sender] == _propertyUniqueID);
            propertywhitelist_[_OwnerAddress][_propertyUniqueID] = _trueFalse;
            emit PropertyWhitelisted(msg.sender, _propertyUniqueID, _trueFalse);
            return true;
        } else { 
            return false;
        }
    }
    /**
     * Whitelist a Minting Request that has been confirmed on the site.. ceva only
     */
    function AsetWhitelistedPropertyValue(address _OwnerAddress, bytes32 _propertyUniqueID, uint256 _propertyValue)
        onlyCEVA(msg.sender)
        public
        returns(uint256)
    {
        require(propertywhitelist_[_OwnerAddress][_propertyUniqueID] = true && _propertyValue >= 0);
            if(_OwnerAddress != msg.sender){
                address _customerAddress = msg.sender;
                numberofmintingrequestswhitelisted_[msg.sender] += 1;
                emit PropertyValuation(_customerAddress, _propertyUniqueID, _propertyValue);
                return _propertyValue;
            } else { 
                numberofmintingrequestswhitelisted_[msg.sender] -= 1;
                _propertyValue = 0;
                return _propertyValue;
            }
    }
    /**
     * Whitelist a Minting Request that has been confirmed on the site.. ceva only
     */
    function AsetworkingPropertyid(address _OwnerAddress, bytes32 _propertyUniqueID)
        onlyFounderDevelopers(msg.sender)
        public
        returns(bool)
    {
        require(propertywhitelist_[_OwnerAddress][_propertyUniqueID] = true);
            if(_OwnerAddress != msg.sender){
                workingPropertyid_[_OwnerAddress] = _propertyUniqueID;
                return true;
            } else { 
                return false;
            }
    }
    /**
     * Whitelist a Minting Request that has been confirmed on the site.. ceva only
     */
    function AsetworkingMintingRequest(address _OwnerAddress, bytes32 _mintingRequestUniqueid)
        onlyFounderDevelopers(msg.sender)
        public
        returns(bool)
    {
        require(mintrequestwhitelist_[_OwnerAddress][_mintingRequestUniqueid] = true);
            if(_OwnerAddress != msg.sender){
                workingMintRequestid_[_OwnerAddress] = _mintingRequestUniqueid;
                return true;
            } else { 
                return false;
            }
    }
    /**
     * Whitelist a Minting Request that has been confirmed on the site.. ceva only
     */
    function Asetworkingburnrequestid(address _OwnerAddress, bytes32 _propertyUniqueID, uint256 _propertyValue)
        onlyFounderDevelopers(msg.sender)
        public
        returns(bytes32)
    {
        require(burnrequestwhitelist_[_OwnerAddress][_propertyUniqueID] = true);
            if(_OwnerAddress != msg.sender){
                workingPropertyid_[_OwnerAddress] = _propertyUniqueID;
                numberofmintingrequestswhitelisted_[msg.sender] += 1;
                emit PropertyValuation(msg.sender, _propertyUniqueID, _propertyValue);
                return _propertyUniqueID;
            } else { 
                numberofmintingrequestswhitelisted_[msg.sender] -= 1;
                _propertyValue = 0;
                return _propertyUniqueID;
            }
    }
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
    function bStringToBytes32(string memory source) 
    public pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
}
    /**
     * Whitelist a Founder Developer ceva only
     */
    function AWhitelistFounderDeveloper(address _identifier, bool _status)
        onlyCEVA(msg.sender)
        public
    {
            founderdevelopers_[_identifier] = _status;
            numberofburnrequestswhitelisted_[msg.sender] = 0;
            numberofpropertieswhitelisted_[msg.sender] = 0;
            numberofmintingrequestswhitelisted_[msg.sender] = 0;
            emit FounderDeveloperWhitelisted(msg.sender, _identifier, _status);
    }
    /*----------  FOUNDER DEVELOPER ONLY FUNCTIONS  ----------*/
    // Mint an amount of tokens to an address 
    // using a whitelisted minting request unique ID founder developer only
    function _mint(uint256 _FounderDeveloperFee, address _toAddress, address _holdOne, address _holdTwo, address _holdThree, 
        uint256 _propertyValue, bytes32 _propertyUniqueID, bytes32 _mintingRequestUniqueid)
        onlyFounderDevelopers(msg.sender)
        public
    {
        if(_propertyValue >= 100){
        // data setup
            uint256 _amountOfTokens = (_propertyValue * 1e18) / 100;
            require(members_[_toAddress] == true && _FounderDeveloperFee >= 20001 && _FounderDeveloperFee <= 100000 && 
            (_amountOfTokens + tokenSupply_) > tokenSupply_ && msg.sender != _toAddress && _propertyUniqueID == workingPropertyid_[msg.sender]
            && _mintingRequestUniqueid == workingMintRequestid_[msg.sender] && _propertyValue == propertyvalue_[_toAddress][_propertyUniqueID]);
            // add tokens to the pool
            tokenSupply_ = tokenSupply_ + _amountOfTokens;
            updateHoldsandSupply(_amountOfTokens);
            // add to burner stockpile
            cevaBurnerStockpile_ += (_amountOfTokens / 16667) * 100;
            // whoa fee
            whoafeeBalanceLedger_ = whoafeeBalanceLedger_ + _amountOfTokens;
            // credit founder developer fee
            tokenBalanceLedger_[msg.sender] += (_amountOfTokens / _FounderDeveloperFee) * 1000;
            //credit Envelope Fee Shareholds
            creditFeeSharehold(_amountOfTokens, _toAddress, _holdOne, _holdTwo, _holdThree);
            // credit tech feeSharehold_    ;
            uint256 _TechFee = (_amountOfTokens / 25000) * 100;
            techfeeBalanceLedger_ = techfeeBalanceLedger_ + _TechFee;
            // fire event
            // add tokens to the _toAddress 
            uint256 _cevabTransferfees = (_amountOfTokens / 333334) * 10000;
            uint256 _Fee = (_amountOfTokens / _FounderDeveloperFee) * 1000;
            tokenBalanceLedger_[_toAddress] = tokenBalanceLedger_[_toAddress] + (_amountOfTokens - _cevabTransferfees);
            tokenBalanceLedger_[_toAddress] -= _Fee;
            tokenBalanceLedger_[_toAddress] -= _TechFee;
            emit Transfer(msg.sender, _toAddress, _amountOfTokens);
            mintingDepositsOf_[_toAddress] += _amountOfTokens;
        } else {
            return;
        }
    }
    function AworkingPropertyIDOf(address _user)
        onlyFounderDevelopers(msg.sender)
        public
        view
        returns(bytes32)
    {
        return workingPropertyid_[_user];
    }
    function AworkingBurnRequestIDOf(address _user)
        onlyFounderDevelopers(msg.sender)
        public
        view
        returns(bytes32)
    {
        return workingBurnRequestid_[_user];
    }
    function AworkingMintIDOf(address _user)
        onlyFounderDevelopers(msg.sender)
        public
        view
        returns(bytes32)
    {
        return workingMintRequestid_[_user];
    }
    /**
     * whitelist a member founder developer only
     */
    function AWhitelistMember(address _identifier, bool _status)
        onlyFounderDevelopers(msg.sender)
        public
    {
        require(msg.sender != _identifier);
            members_[_identifier] = _status;
            emit MemberWhitelisted(msg.sender, _identifier, _status);
    } 
    /*----------  HELPERS AND CALCULATORS  ----------*/
    /**
     * Retrieve the tokens owned by the caller.
     */
    function TokensNoDecimals()
        view
        public
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        uint256 _tokens =  (balanceOf(_customerAddress) / 1e18);
        if(_tokens >= 1){
            return _tokens;
        } else {
            return 0;
        }
    }
    function balanceOf(address _owner)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger_[_owner];
    }
    function EtaxesdividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        uint256 _dividendPershare;
        if(taxesFeeSharehold_[_customerAddress] == 0){
            return 0;
        } else {
            _dividendPershare = (taxesfeeBalanceLedger_ / taxesfeeTotalHolds_);
            return (uint256) ((_dividendPershare * taxesFeeSharehold_[_customerAddress]) - 
            (taxesFeeTotalWithdrawn_[_customerAddress] + taxesPreviousWithdrawn_[_customerAddress])) / 
            calulateAmountQualified(mintingDepositsOf_[_customerAddress], AmountCirculated_[_customerAddress]);
            
        }
    }
    /**
     * Retrieve the  taxes dividend balance of any single address.
     */
    function EtaxesShareholdOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        
        if(taxesFeeSharehold_[_customerAddress] == 0){
            return 0;
        } else {
            return taxesFeeSharehold_[_customerAddress];
        }
    }
    /**
     * Retrieve the  insurance dividend balance of any single address.
     */
    function EinsurancedividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        uint256 _dividendPershare;
        if(insuranceFeeSharehold_[_customerAddress] == 0){
            return 0;
        } else {
            _dividendPershare = (insurancefeeBalanceLedger_ / insurancefeeTotalHolds_);
            return (uint256) ((_dividendPershare * insuranceFeeSharehold_[_customerAddress]) - 
            (insuranceFeeTotalWithdrawn_[_customerAddress] + insurancePreviousWithdrawn_[_customerAddress])) / 
            calulateAmountQualified(mintingDepositsOf_[_customerAddress], AmountCirculated_[_customerAddress]);
            
        }
    }
    /**
     * Retrieve the  taxes dividend balance of any single address.
     */
    function EinsuranceShareholdOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        
        if(insuranceFeeSharehold_[_customerAddress] == 0){
            return 0;
        } else {
            return insuranceFeeSharehold_[_customerAddress];
        }
    }
    /**
     * Retrieve the  maintenance dividend balance of any single address.
     */
    function EmaintenancedividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        uint256 _dividendPershare;
        if(maintenanceFeeSharehold_[_customerAddress] == 0){
            return 0;
        } else {
            _dividendPershare = (maintenancefeeBalanceLedger_ / maintencancefeeTotalHolds_);
            return (uint256) ((_dividendPershare * maintenanceFeeSharehold_[_customerAddress]) - 
            (maintenanceFeeTotalWithdrawn_[_customerAddress] + maintenancePreviousWithdrawn_[_customerAddress])) / 
            calulateAmountQualified(mintingDepositsOf_[_customerAddress], AmountCirculated_[_customerAddress]);
            
        }
    }
    /**
     * Retrieve the  taxes dividend balance of any single address.
     */
    function EmaintenanceShareholdOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        if(maintenanceFeeSharehold_[_customerAddress] == 0){
            return 0;
        } else {
            return maintenanceFeeSharehold_[_customerAddress];
        }
    }
    /**
     * Retrieve the  Wealth Architect ECO Register 1.2 dividend balance of any single address.
     */
    function EwaECOdividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        uint256 _dividendPershare;
        if(waECOFeeSharehold_[_customerAddress] == 0){
            return 0;
        } else {
            _dividendPershare = (waECOfeeBalanceLedger_ / waECOfeeTotalHolds_);
            return (uint256) ((_dividendPershare * waECOFeeSharehold_[_customerAddress]) - 
            (waECOFeeTotalWithdrawn_[_customerAddress] + waECOPreviousWithdrawn_[_customerAddress])) / 
            calulateAmountQualified(mintingDepositsOf_[_customerAddress], AmountCirculated_[_customerAddress]);
            
        }
        }
    /**
     * Retrieve the  taxes dividend balance of any single address.
     */
    function EwaECOShareholdOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        if(waECOFeeSharehold_[_customerAddress] == 0){
            return 0;
        } else {
            return waECOFeeSharehold_[_customerAddress];
        }
    }
    /**
     * Retrieve the hold one dividend balance of any single address.
     */
    function EholdonedividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        uint256 _dividendPershare;
        if(holdoneSharehold_[_customerAddress] == 0){
            return 0;
        } else {
            _dividendPershare = (holdonefeeBalanceLedger_ / holdonefeeTotalHolds_);
            return (uint256) ((_dividendPershare * holdoneSharehold_[_customerAddress]) - 
            (holdoneTotalWithdrawn_[_customerAddress] + holdonePreviousWithdrawn_[_customerAddress])) / 
            calulateAmountQualified(mintingDepositsOf_[_customerAddress], AmountCirculated_[_customerAddress]);
            
        }
    }
    
    /**
     * Retrieve the  taxes dividend balance of any single address.
     */
    function EholdoneShareholdOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        if(holdoneSharehold_[_customerAddress] == 0){
            return 0;
        } else {
            return holdoneSharehold_[_customerAddress];
        }
    }
    /**
     * Retrieve the hold two dividend balance of any single address.
     */
    function EholdtwodividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        uint256 _dividendPershare;
        if(holdtwoSharehold_[_customerAddress] == 0){
            return 0;
        } else {
            _dividendPershare = (holdtwofeeBalanceLedger_ / holdtwofeeTotalHolds_);
            return (uint256) ((_dividendPershare * holdtwoSharehold_[_customerAddress]) -
            (holdtwoTotalWithdrawn_[_customerAddress] + holdtwoPreviousWithdrawn_[_customerAddress])) / 
            calulateAmountQualified(mintingDepositsOf_[_customerAddress], AmountCirculated_[_customerAddress]);
            
        }
    }
    /**
     * Retrieve the  taxes dividend balance of any single address.
     */
    function EholdtwoShareholdOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        if(holdtwoSharehold_[_customerAddress] == 0){
            return 0;
        } else {
            return holdtwoSharehold_[_customerAddress];
        }
    }
    /**
     * Retrieve the hold three dividend balance of any single address.
     */
    function EholdthreedividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        uint256 _dividendPershare;
        if(holdthreeSharehold_[_customerAddress] == 0){
            return 0;
        } else {
            _dividendPershare = (holdthreefeeBalanceLedger_ / holdthreefeeTotalHolds_);
            return (uint256) ((_dividendPershare * holdthreeSharehold_[_customerAddress]) -
            (holdthreeTotalWithdrawn_[_customerAddress] + holdthreePreviousWithdrawn_[_customerAddress])) / 
            calulateAmountQualified(mintingDepositsOf_[_customerAddress], AmountCirculated_[_customerAddress]);
            
        }
    }
    /**
     * Retrieve the  taxes dividend balance of any single address.
     */
    function EholdthreeShareholdOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        if(holdthreeSharehold_[_customerAddress] == 0){
            return 0;
        } else {
            return holdthreeSharehold_[_customerAddress];
        }
    }
    /**
     * Retrieve the rewards dividend balance of any single address.
     */
    function ErewardsdividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        uint256 _dividendPershare;
        if(rewardsSharehold_[_customerAddress] == 0){
            return 0;
        } else {
            _dividendPershare = (RewardsfeeBalanceLedger_ / RewardsfeeTotalHolds_);
            return (uint256) ((_dividendPershare * rewardsSharehold_[_customerAddress]) -
            (rewardsTotalWithdrawn_[_customerAddress] + rewardsPreviousWithdrawn_[_customerAddress])) / 
            calulateAmountQualified(mintingDepositsOf_[_customerAddress], AmountCirculated_[_customerAddress]);
            
        }
    }
    /**
     * Retrieve the  taxes dividend balance of any single address.
     */
    function ErewardsShareholdOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        if(rewardsSharehold_[_customerAddress] == 0){
            return 0;
        } else {
            return rewardsSharehold_[_customerAddress];
        }
    }
    /**
     * Retrieve the tech dividend balance of any single address.
     */
    function EtechdividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        uint256 _dividendPershare;
        if(techfeeTotalHolds_ == 0){
            return 0;
        } else {
            _dividendPershare = (techfeeBalanceLedger_ / techfeeTotalHolds_);
            return (uint256) ((_dividendPershare * techSharehold_[_customerAddress]) -
            (techTotalWithdrawn_[_customerAddress] + techPreviousWithdrawn_[_customerAddress])) /
            calulateAmountQualified(mintingDepositsOf_[_customerAddress], AmountCirculated_[_customerAddress]);
            
        }
    }
    /**
     * Retrieve the  taxes dividend balance of any single address.
     */
    function EtechShareholdOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        if(techSharehold_[_customerAddress] == 0){
            return 0;
        } else {
            return techSharehold_[_customerAddress];
        }
    }
    /**
     * Retrieve the exist holdings dividend balance of any single address.
     */
    function existholdingsdividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        uint256 _dividendPershare;
        if(existholdingsfeeTotalHolds_ == 0){
            return 0;
        } else {
            _dividendPershare = (existholdingsfeeBalanceLedger_ / existholdingsfeeTotalHolds_);
            return (uint256) ((_dividendPershare * existholdingsSharehold_[_customerAddress]) -
            (existholdingsTotalWithdrawn_[_customerAddress] + existholdingsPreviousWithdrawn_[_customerAddress])) / 
            calulateAmountQualified(mintingDepositsOf_[_customerAddress], AmountCirculated_[_customerAddress]);
            
        }
    }
    /**
     * Retrieve the  taxes dividend balance of any single address.
     */
    function existholdingsShareholdOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        
        if(existholdingsSharehold_[_customerAddress] == 0){
            return 0;
        } else {
            return existholdingsSharehold_[_customerAddress];
        }
    }
    /**
     * Retrieve the exist crypto dividend balance of any single address.
     */
    function existcryptodividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        uint256 _dividendPershare;
        if(existcryptofeeTotalHolds_ == 0){
            return 0;
        } else {
            _dividendPershare = (existcryptofeeBalanceLedger_ / existcryptofeeTotalHolds_);
            return (uint256) ((_dividendPershare * existcryptoSharehold_[_customerAddress]) -
            (existcryptoTotalWithdrawn_[_customerAddress] + existcryptoPreviousWithdrawn_[_customerAddress])) / 
            calulateAmountQualified(mintingDepositsOf_[_customerAddress], AmountCirculated_[_customerAddress]);
            
        }
    }
    /**
     * Retrieve the  taxes dividend balance of any single address.
     */
    function existcryptoShareholdOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        if(existcryptoSharehold_[_customerAddress] == 0){
            return 0;
        } else {
            return existcryptoSharehold_[_customerAddress];
        }
    }
    /**
     * Retrieve the Worldwide Home Owners Association dividend balance of any single address.
     */
    function EwhoadividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        uint256 _dividendPershare;
        if(whoafeeTotalHolds_ == 0){
            return 0;
        } else {
            _dividendPershare = (whoafeeBalanceLedger_ / whoafeeTotalHolds_);
            return (uint256) ((_dividendPershare * whoaSharehold_[_customerAddress]) -
            (whoaTotalWithdrawn_[_customerAddress] + whoaPreviousWithdrawn_[_customerAddress])) /
            calulateAmountQualified(mintingDepositsOf_[_customerAddress], AmountCirculated_[_customerAddress]);
            
        }
    }
    /**
     * Retrieve the WHOA dividend balance of any single address.
     */
    function EwhoaShareholdOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        if(whoaSharehold_[_customerAddress] == 0){
            return 0;
        } else {
            return whoaSharehold_[_customerAddress];
        }
    }
    /**
     * Retrieve the Credible You dividend balance of any single address.
     */
    function EcredibleyoudividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        uint256 _dividendPershare;
        if(credibleyoufeeTotalHolds_ == 0){
            return 0;
        } else {
            _dividendPershare = (credibleyoufeeBalanceLedger_ / credibleyoufeeTotalHolds_);
            return (uint256) ((_dividendPershare * credibleyouSharehold_[_customerAddress]) -
            (credibleyouTotalWithdrawn_[_customerAddress] + credibleyouPreviousWithdrawn_[_customerAddress]))
            / calulateAmountQualified(mintingDepositsOf_[_customerAddress], AmountCirculated_[_customerAddress]);
            
        }
    }
    /**
     * Retrieve the  taxes dividend balance of any single address.
     */
    function EcredibleyouShareholdOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        if(credibleyouSharehold_[_customerAddress] == 0){
            return 0;
        } else {
            return credibleyouSharehold_[_customerAddress];
        }
    }
    
    /**
     * Retrieve the CEVA Burner Stockpile dividend balance using a CEVA whitelisted address.
     */
    function EcevaBurnerStockpileDividends()
        onlyCEVA(msg.sender)
        view
        public
        returns(uint256)
    {
        uint256 _dividendPershare;
        address _customerAddress = msg.sender;
        if(ceva_[_customerAddress] != true){
            return 0;
        } else {
            _dividendPershare = cevaBurnerStockpile_;
            return _dividendPershare;
        }
    }
    
    function totalSupply() 
        public 
        view
        returns(uint256)
    {
            if(tokenSupply_ == 0){
                return 0;
            } else {
            return tokenSupply_;}
    }
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    /**
     * Update token balance ledger of an address tokens from the caller to a new holder.
     */
    function updateHoldsandSupply(uint256 _amountOfTokens)
        internal
        returns(bool)
    {
        tokenSupply_ = tokenSupply_ + _amountOfTokens;
        taxesfeeTotalHolds_ = (_amountOfTokens / 1e18) + taxesfeeTotalHolds_;
        insurancefeeTotalHolds_ = (_amountOfTokens / 1e18) + insurancefeeTotalHolds_;
        maintencancefeeTotalHolds_ = (_amountOfTokens / 1e18) + maintencancefeeTotalHolds_;
        waECOfeeTotalHolds_ = (_amountOfTokens / 1e18) + waECOfeeTotalHolds_;
        holdonefeeTotalHolds_ = (_amountOfTokens / 1e18) + holdonefeeTotalHolds_;
        holdtwofeeTotalHolds_ = (_amountOfTokens / 1e18) + holdtwofeeTotalHolds_;
        holdthreefeeTotalHolds_ = (_amountOfTokens / 1e18) + holdthreefeeTotalHolds_;
        RewardsfeeTotalHolds_ = (_amountOfTokens / 1e18) + RewardsfeeTotalHolds_;
        techfeeTotalHolds_ = (_amountOfTokens / 1e18) + techfeeTotalHolds_;
        existholdingsfeeTotalHolds_ = (_amountOfTokens / 1e18) + existholdingsfeeTotalHolds_;
        existcryptofeeTotalHolds_ = (_amountOfTokens / 1e18) + existcryptofeeTotalHolds_;
        whoafeeTotalHolds_ = (_amountOfTokens / 1e18) + whoafeeTotalHolds_;
        credibleyoufeeTotalHolds_= (_amountOfTokens / 1e18) + credibleyoufeeTotalHolds_;
        feeTotalHolds_ = ((_amountOfTokens / 1e18)* 13) + feeTotalHolds_;
        return true;
    }
    /**
     * Update token balance ledger of an address tokens from the caller to a new holder.
     * Remember, there's a fee here as well.
     */
    function burnA(uint256 _amount)
        internal
        returns(bool)
    {
        uint256 _pValue = _amount / 100;
        if(_amount > 0){
            RewardsfeeTotalHolds_ -= _pValue;
            techfeeTotalHolds_ -= _pValue;
            existholdingsfeeTotalHolds_ -= _pValue;
            existcryptofeeTotalHolds_ -= _pValue;
            whoafeeTotalHolds_-= _pValue;
            credibleyoufeeTotalHolds_ -= _pValue;
            feeTotalHolds_ -= _pValue;
            return true;
        } else {
            return false;
        } 
    }
    /**
     * calculate 2% total transfer fee based on _amountOfTokens
     */
    function calulateAmountQualified(uint256 _TokenMintingDepositsOf, uint256 _AmountCirculated)
        internal
        pure
        returns(uint256 _AmountQualified)
    {
        _AmountQualified = _TokenMintingDepositsOf / _AmountCirculated;
        if(_AmountQualified <= 1){
            _AmountQualified = 1;
            return _AmountQualified;
        } else {
            return _AmountQualified;
        }
    }
    function updateEquityRents(uint256 _amountOfTokens)
        internal
        returns(bool)
    {
        if(_amountOfTokens < 0){
            _amountOfTokens = 0;
            return false;
        } else {
            taxesfeeBalanceLedger_ = taxesfeeBalanceLedger_ + (_amountOfTokens / 800);
            insurancefeeBalanceLedger_ = insurancefeeBalanceLedger_ + (_amountOfTokens / 800);
            maintenancefeeBalanceLedger_ = maintenancefeeBalanceLedger_ + (_amountOfTokens / 800);
            waECOfeeBalanceLedger_ = waECOfeeBalanceLedger_ + (_amountOfTokens / 800);
            holdonefeeBalanceLedger_ = holdonefeeBalanceLedger_ + (_amountOfTokens / 800);
            holdtwofeeBalanceLedger_ = holdtwofeeBalanceLedger_ + (_amountOfTokens / 800);
            holdthreefeeBalanceLedger_ = holdthreefeeBalanceLedger_ + (_amountOfTokens / 800);
            RewardsfeeBalanceLedger_ = RewardsfeeBalanceLedger_ + (_amountOfTokens / 800);
            techfeeBalanceLedger_ = techfeeBalanceLedger_ + ((_amountOfTokens / 25000) * 100);
            existholdingsfeeBalanceLedger_ = existholdingsfeeBalanceLedger_ + (_amountOfTokens / 445);
            existcryptofeeBalanceLedger_ = existcryptofeeBalanceLedger_ + (_amountOfTokens / 800);
            whoafeeBalanceLedger_ = whoafeeBalanceLedger_ + (_amountOfTokens / 800);
            credibleyoufeeBalanceLedger_ = credibleyoufeeBalanceLedger_ + (_amountOfTokens / 800);
            return true;
        } 
    }
    /**
     * Update taxes fee sharehold of an address..
     */
    function creditTaxesFeeSharehold(uint256 _amountOfTokens,  address _toAddress)
        internal
    {
        taxesFeeSharehold_[_toAddress] += _amountOfTokens;
    }
    /**
     * Update insurance fee sharehold of an address..
     */
    function creditInsuranceFeeSharehold(uint256 _amountOfTokens, address _toAddress)
        internal
    {
        insuranceFeeSharehold_[_toAddress] += _amountOfTokens;
    }
    /**
     * Update maintenance fee sharehold of an address..
     */
    function creditMaintenanceFeeSharehold(uint256 _amountOfTokens, address _toAddress)
        internal
    {
        maintenanceFeeSharehold_[_toAddress] += _amountOfTokens;
    }
    /**
     * Update Wealth Architect fee sharehold of an address..
     */
    function creditwaECOFeeSharehold(uint256 _amountOfTokens, address _toAddress)
        internal
    {
        waECOFeeSharehold_[_toAddress] += _amountOfTokens;
    }
    /**
     * Update hold one fee sharehold of an address..
     */
    function creditHoldOneFeeSharehold(uint256 _amountOfTokens, address _toAddress)
        internal
    {
        holdoneSharehold_[_toAddress] += _amountOfTokens;
    }
    /**
     * Update hold two fee sharehold of an address..
     */
    function creditHoldTwoFeeSharehold(uint256 _amountOfTokens, address _toAddress)
        internal
    {
        holdtwoSharehold_[_toAddress] += _amountOfTokens;
    }
    /**
     * Update hold three fee sharehold of an address..
     */
    function creditHoldThreeFeeSharehold(uint256 _amountOfTokens, address _toAddress)
        internal
    {
        holdthreeSharehold_[_toAddress] += _amountOfTokens;
    }
    /**
     * Update Rewards fee sharehold of an address..
     */
    function creditRewardsFeeSharehold(uint256 _amountOfTokens, address _toAddress)
        internal
    {
        rewardsSharehold_[_toAddress] += _amountOfTokens;
    }
    /**
     * Update Tech fee sharehold of an address..
     */
    function creditTechFeeSharehold(uint256 _amountOfTokens, address _toAddress)
        internal
    {
        techSharehold_[_toAddress] += _amountOfTokens;
    }
    /**
     * Update Exist Holdings fee sharehold of an address..
     */
    function creditExistHoldingsFeeSharehold(uint256 _amountOfTokens, address _toAddress)
        internal
    {
        existholdingsSharehold_[_toAddress] += _amountOfTokens;
    }
    /**
     * Update Exist Crypto fee sharehold of an address..
     */
    function creditExistCryptoFeeSharehold(uint256 _amountOfTokens, address _toAddress)
        internal
    {
        existcryptoSharehold_[_toAddress] += _amountOfTokens;
    }
    /**
     * Update WHOA fee sharehold of an address..
     */
    function creditWHOAFeeSharehold(uint256 _amountOfTokens, address _toAddress)
        internal
    {
        whoaSharehold_[_toAddress] += _amountOfTokens;
    }
    /**
     * Update Credible You fee sharehold of an address..
     */
    function creditCredibleYouFeeSharehold(uint256 _amountOfTokens, address _toAddress)
        internal
    {
        credibleyouSharehold_[_toAddress] += _amountOfTokens;
    }
    /**
     * Update Exist Holdings fee sharehold of an address..
     */
    function creditFeeSharehold(uint256 _amountOfTokens, address _owner, address _toAddress, address _toAddresstwo, address _toAddressthree)
        internal
        returns(bool)
    {
        creditTaxesFeeSharehold((_amountOfTokens / 1e18), _owner);
        creditInsuranceFeeSharehold((_amountOfTokens / 1e18), _owner);
        creditMaintenanceFeeSharehold((_amountOfTokens / 1e18), whoamaintenanceaddress_);
        creditwaECOFeeSharehold((_amountOfTokens / 1e18), _owner);
        creditHoldOneFeeSharehold((_amountOfTokens / 1e18), _toAddress);
        creditHoldTwoFeeSharehold((_amountOfTokens / 1e18), _toAddresstwo);
        creditHoldThreeFeeSharehold((_amountOfTokens / 1e18), _toAddressthree);
        creditRewardsFeeSharehold((_amountOfTokens / 1e18), whoarewardsaddress_);
        creditTechFeeSharehold((_amountOfTokens / 1e18), techaddress_);
        creditExistHoldingsFeeSharehold((_amountOfTokens / 1e18), existholdingsaddress_);
        creditExistCryptoFeeSharehold((_amountOfTokens / 1e18), existcryptoaddress_);
        creditWHOAFeeSharehold((_amountOfTokens / 1e18), whoaaddress_);
        creditCredibleYouFeeSharehold((_amountOfTokens / 1e18), credibleyouaddress_);
        return true;
    }
    //This is where all your gas goes, sorry
    //Not sorry, you probably only paid 1 gwei
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}