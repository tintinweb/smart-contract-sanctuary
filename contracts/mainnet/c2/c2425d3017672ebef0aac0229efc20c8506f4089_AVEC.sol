/**
 *Submitted for verification at Etherscan.io on 2020-12-04
*/

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

    event AVECtoONUS(

        address indexed MemberAddress,

        uint256 tokensConverted

    );

    event ONUStoAVEC(

        address indexed MemberAddress,

        uint256 tokensConverted

    );

    event OnWithdraw(

        address indexed MemberAddress,

        uint256 tokensWithdrawn,

        uint8 envelopeNumber

    );

    // ERC20

    event Transfer(

        address indexed from,

        address indexed to,

        uint256 value

    );

    event PropertyTransfer(

        address indexed from,

        address indexed to,

        uint256 value,

        bytes32 property

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

    mapping (bytes32 => mapping(address => uint256)) internal propertyBalanceLedger_;

    mapping (bytes32 => mapping(address => uint256)) internal propertyLastKnownValue_;

    mapping (address => mapping(bytes32 => uint256)) internal propertyvalue_;

    mapping (address => mapping(bytes32 => uint256)) internal propertyvalueOld_;

    mapping (address => mapping(bytes32 => uint256)) internal propertyPriceUpdateCountMember_;

    mapping(bytes32 => uint256) internal propertyPriceUpdateCountAsset_;

    mapping(bytes32 => uint256) internal propertyGlobalBalance_;

    mapping(bytes32 => uint256) internal propertyPriceUpdatesAsset_;

    mapping(bytes32 => address) internal propertyOwner_;

    mapping(bytes32 => uint256) internal lastMintingPrice_;

    mapping(address => bytes32) internal transferingPropertyid_;

    mapping(address => bytes32) internal workingPropertyid_;

    mapping(address => bytes32) internal workingMintRequestid_;

    mapping(address => bytes32) internal workingBurnRequestid_;

   /*================================

    =            DATASETS            =

    ================================*/

    // amount of shares for each address (scaled number)

    mapping(address => uint256) internal tokenBalanceLedger_ ;

    mapping(address => uint256) internal mintingDepositsOf_;

    mapping(address => uint256) internal amountCirculated_;

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
    
    mapping(address => uint8) internal transferType_;
    
    bytes32 internal onusCode_ = 0x676c6f62616c0000000000000000000000000000000000000000000000000000;
    
    bytes32 internal omniCode_ = 0x4f4d4e4900000000000000000000000000000000000000000000000000000000;

    uint256 internal tokenSupply_;

    uint256 internal feeTotalHolds_;

    uint256 internal cevaBurnerStockpile_;

    uint256 internal cevaBurnerStockpileWithdrawn_;

    uint256 internal globalFeeLedger_;

    uint256 internal taxesfeeTotalHolds_;

    uint256 internal insurancefeeTotalHolds_;

    uint256 internal maintencancefeeTotalHolds_;

    uint256 internal waECOfeeTotalHolds_;

    uint256 internal holdonefeeTotalHolds_;

    uint256 internal holdtwofeeTotalHolds_;

    uint256 internal holdthreefeeTotalHolds_;

    uint256 internal rewardsfeeTotalHolds_;

    uint256 internal techfeeTotalHolds_;

    uint256 internal existholdingsfeeTotalHolds_;

    uint256 internal existcryptofeeTotalHolds_;

    uint256 internal whoafeeTotalHolds_;

    uint256 internal credibleyoufeeTotalHolds_;

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

    function adminInitialSet()

        public

    {

        // add the first users
        
        propertyOwner_[0x676c6f62616c0000000000000000000000000000000000000000000000000000] = whoaaddress_;

        //James Admin

        administrators[0xA9873d93db3BCA9F68aDfEAb226Fa9189641069A] 
        = true;

        //Brenden Admin

        administrators[0x27851761A8fBC03f57965b42528B39af07cdC42b] 
        = true;

        members_[0x314d0ED76d866826C809fb6a51d63642b2E9eC3e] 
        = true;

        members_[0x2722B426B11978c29660e8395a423Ccb93AE0403] 
        = true;

        members_[0x27851761A8fBC03f57965b42528B39af07cdC42b] 
        = true;

        members_[0xA9873d93db3BCA9F68aDfEAb226Fa9189641069A] 
        = true;

        members_[0xdE281c22976dE2E9b3f4F87bEB60aE9E67DFf5C4] 
        = true;

        members_[0xc9c1Ffd6B4014232Ef474Daa4CA1506A6E39Be89] 
        = true;

        members_[0xac1B6580a175C1f2a4e3220A24e6f65fF3AB8A03] 
        = true;

        members_[0xB6148C62e6A6d48f41241D01e3C4841139144ABa] 
        = true;

        members_[0xb8C098eE976f1162aD277936a5D1BCA7a8Fe61f5] 
        = true;

        members_[0xA9d241b568DF9E8A7Ec9e44737f29a8Ee00bfF53] 
        = true;

        members_[0x27851761A8fBC03f57965b42528B39af07cdC42b] 
        = true;

        members_[0xa1Ff1474e0a5db4801E426289DB485b456de7882] 
        = true;



    }
    
    /*

    * -- APPLICATION ENTRY POINTS --

    */

    function adminGenesis(address _existcryptoaddress, address _existhooldingsaddress, address _techaddress,

        address _credibleyouaddress, address _cevaaddress, address _whoaddress, address _whoarewardsaddress, address _whoamaintenanceaddress)

        public

        onlyAdministrator(msg.sender)

    {

        require(administrators[msg.sender], "AdminFalse");

        // adds the _whoaddress input as the current whoa address

        whoaaddress_ 
        = _whoaddress;

        // adds the _whoamaintenanceaddress input as the current whoa maintenence address

        whoamaintenanceaddress_ 
        = _whoamaintenanceaddress;

        // adds the _whoarewardsaddress input as the current whoa rewards address

        whoarewardsaddress_ 
        = _whoarewardsaddress;

        // adds the )cevaaddress_ input as the current ceva address

        cevaaddress_ 
        = _cevaaddress;

        // adds the _credibleyouaddress input as the current credible you address

        credibleyouaddress_ 
        = _credibleyouaddress;

        // adds the _techaddress input as the current tech address

        techaddress_ 
        = _techaddress;

        // adds the __existhooldingsaddress input as the current exist holdings address

        existholdingsaddress_ 
        = _existhooldingsaddress;

        // adds the _existcryptoaddress input as the current exist crypto address

        existcryptoaddress_ 
        = _existcryptoaddress;

        // adds the first ceva qualified founder developers here.
        
        numberofburnrequestswhitelisted_[msg.sender] 
        = 0;

        numberofpropertieswhitelisted_[msg.sender] 
        = 0;

        numberofmintingrequestswhitelisted_[msg.sender] 
        = 0;

        // adds the first member here.

        members_[msg.sender] = true;

    }

    /**

     * Withdraws all of the callers taxes earnings.

     */

    function memberBuyFounderDeveloperLicense(address _founderDeveloperOne, address _founderDeveloperTwo, address _ceva)

        public

        onlyMembers(msg.sender)

        returns(bool _success)

    {

        require(founderdevelopers_[_founderDeveloperOne] == true 
        && ceva_[_ceva] == true 
        && founderdevelopers_[_founderDeveloperTwo] == true);

        // setup data

            address _customerAddress 
            = msg.sender;

            uint256 _licenseprice 
            = 1000 * 1e18;

            if(tokenBalanceLedger_[_customerAddress] > _licenseprice){

                propertyBalanceLedger_[0x676c6f62616c0000000000000000000000000000000000000000000000000000][_ceva] 
                = (_licenseprice / 5) + propertyBalanceLedger_[0x676c6f62616c0000000000000000000000000000000000000000000000000000][_ceva];

                tokenBalanceLedger_[_ceva] = tokenBalanceLedger_[_ceva] 
                + (_licenseprice / 5);

                propertyBalanceLedger_[0x676c6f62616c0000000000000000000000000000000000000000000000000000][_founderDeveloperOne] 
                =  (_licenseprice / 5) + propertyBalanceLedger_[0x676c6f62616c0000000000000000000000000000000000000000000000000000][_founderDeveloperOne];

                tokenBalanceLedger_[_founderDeveloperOne] = tokenBalanceLedger_[_founderDeveloperOne] + (_licenseprice / 5);

                propertyBalanceLedger_[0x676c6f62616c0000000000000000000000000000000000000000000000000000][_founderDeveloperTwo] 
                =  (_licenseprice / 10) + propertyBalanceLedger_[0x676c6f62616c0000000000000000000000000000000000000000000000000000][_founderDeveloperTwo];

                tokenBalanceLedger_[_founderDeveloperTwo] = tokenBalanceLedger_[_founderDeveloperTwo] 
                + (_licenseprice / 10);

                propertyBalanceLedger_[transferingPropertyid_[_customerAddress]][_customerAddress] 
                = propertyBalanceLedger_[transferingPropertyid_[_customerAddress]][_customerAddress] - _licenseprice;

                tokenBalanceLedger_[_customerAddress] 
                = tokenBalanceLedger_[_customerAddress] - _licenseprice;

                founderdevelopers_[_customerAddress] 
                = true;

                return true;

            } else {

                return false;

        }

    }

    /**

     * Withdraws all of the callers taxes earnings. ------------------------------------------------------------------------

     * global bytes32 encoded 0x676c6f62616c0000000000000000000000000000000000000000000000000000

     * set transferingPropertyid_ to global bytes32 code to transfer "Global Balance"

     * =============================================------------------------------------------------------------------------

     */

    function memberWithdrawDividends(uint8 _envelopeNumber)

        public

        onlyMembers(msg.sender)

    {

        // setup data

        address _customerAddress 
        = msg.sender;

        uint256 _dividends;

        if(_envelopeNumber == 1){

            _dividends 
            = checkDividendsOf(msg.sender, _envelopeNumber);

            taxesFeeTotalWithdrawn_[_customerAddress] 
            +=  _dividends;

        } else if(_envelopeNumber == 2){

            _dividends 
            = checkDividendsOf(msg.sender, _envelopeNumber);

            insuranceFeeTotalWithdrawn_[_customerAddress] 
            +=  _dividends;

        } else if(_envelopeNumber == 3){

            _dividends 
            = checkDividendsOf(msg.sender, _envelopeNumber);

            maintenanceFeeTotalWithdrawn_[_customerAddress] 
            +=  _dividends;

        } else if(_envelopeNumber == 4){

            _dividends 
            = checkDividendsOf(msg.sender, _envelopeNumber);

            waECOFeeTotalWithdrawn_[_customerAddress] 
            +=  _dividends;

        } else if(_envelopeNumber == 5){

            _dividends 
            = checkDividendsOf(msg.sender, _envelopeNumber);

            holdoneTotalWithdrawn_[_customerAddress] 
            +=  _dividends;

        } else if(_envelopeNumber == 6){

            _dividends 
            = checkDividendsOf(msg.sender, _envelopeNumber);

            holdtwoTotalWithdrawn_[_customerAddress] 
            +=  _dividends;

        } else if(_envelopeNumber == 7){

            _dividends 
            = checkDividendsOf(msg.sender, _envelopeNumber);

            holdthreeTotalWithdrawn_[_customerAddress] 
            +=  _dividends;

        } else if(_envelopeNumber == 8){

            _dividends 
            = checkDividendsOf(msg.sender, _envelopeNumber);

            rewardsTotalWithdrawn_[_customerAddress] 
            +=  _dividends;

        } else if(_envelopeNumber == 9){

            _dividends 
            = checkDividendsOf(msg.sender, _envelopeNumber);

            techTotalWithdrawn_[_customerAddress] 
            +=  _dividends;

        } else if(_envelopeNumber == 10){

            _dividends 
            = checkDividendsOf(msg.sender, _envelopeNumber);

            existholdingsTotalWithdrawn_[_customerAddress] 
            +=  _dividends;

        } else if(_envelopeNumber == 11){

            _dividends 
            = checkDividendsOf(msg.sender, _envelopeNumber);

            existcryptoTotalWithdrawn_[_customerAddress] 
            +=  _dividends;

        } else if(_envelopeNumber == 12){

            _dividends 
            = checkDividendsOf(msg.sender, _envelopeNumber);

            whoaTotalWithdrawn_[_customerAddress] 
            +=  _dividends;

        } else if(_envelopeNumber == 13){

            _dividends 
            = checkDividendsOf(msg.sender, _envelopeNumber);

            credibleyouTotalWithdrawn_[_customerAddress] 
            +=  _dividends;

        }

        // update dividend tracker

        propertyBalanceLedger_[0x676c6f62616c0000000000000000000000000000000000000000000000000000][_customerAddress] 
        +=  _dividends;

        tokenBalanceLedger_[_customerAddress] = tokenBalanceLedger_[_customerAddress] +_dividends;

        // fire event

        emit OnWithdraw(_customerAddress, _dividends, _envelopeNumber);

    }

    function propertyTransfer(address from, address to, uint256 value, bytes32 propertyID)

        internal

    {

        emit PropertyTransfer(from, to, value, propertyID);

    }
    /**

     * Transfer tokens from the caller to a new holder.

     * Remember, there's a 2% fee here as well. members only

     */

    function transfer(address _toAddress, uint256 _amountOfTokens)

        public

    {
        transferingFromWallet_[msg.sender] = 1;
        
        uint256 _fee = _amountOfTokens / 50;
        
        _amountOfTokens += _fee;
        
        require(_amountOfTokens <= propertyBalanceLedger_[transferingPropertyid_[msg.sender]][msg.sender], "Not Enough Token");
        
        _amountOfTokens -= _fee;
        
        if(transferType_[msg.sender] == 1){
        
            require(members_[_toAddress] == true, "Not a member");
            
        }
        
        updateRollingPropertyValueMember(_toAddress, transferingPropertyid_[msg.sender]);
        
        uint256 _value 
        = _amountOfTokens + _fee;
        
        address _ownerAddress 
        = propertyOwner_[transferingPropertyid_[msg.sender]];

        uint256 _divideby 
        = ((((propertyLastKnownValue_[transferingPropertyid_[msg.sender]][msg.sender] * 1e18) / 100) * 1000000) / propertyBalanceLedger_[transferingPropertyid_[msg.sender]][msg.sender]);

        uint256 _propertyValue 
        = ((propertyvalue_[_ownerAddress][transferingPropertyid_[msg.sender]] * 1e18) / 100) * 1000000;

        uint256 _pCalculate 
        = _propertyValue / _divideby;
            
        propertyBalanceLedger_[transferingPropertyid_[msg.sender]][msg.sender] 
        = _pCalculate - _value;
        
        propertyPriceUpdateCountMember_[msg.sender][transferingPropertyid_[msg.sender]] 
        = propertyPriceUpdateCountAsset_[transferingPropertyid_[msg.sender]];

        propertyLastKnownValue_[transferingPropertyid_[msg.sender]][msg.sender] 
        = propertyvalue_[_ownerAddress][transferingPropertyid_[msg.sender]];

        tokenBalanceLedger_[_toAddress] 
        = tokenBalanceLedger_[_toAddress] + _amountOfTokens;

        tokenBalanceLedger_[msg.sender] 
        -= _value ;

        propertyBalanceLedger_[transferingPropertyid_[msg.sender]][_toAddress] 
        = propertyBalanceLedger_[transferingPropertyid_[msg.sender]][_toAddress] + _amountOfTokens;

        updateEquityRents(_amountOfTokens);
        
        transferingFromWallet_[msg.sender] = 0;
        
        emit Transfer(msg.sender, _toAddress, _value);
    }

    /**

     * Convert AVEC into ONUS

     */

    function memberConvertAVECtoONUS(uint256 tokens)

        public

    {

        bytes32 _propertyUniqueID 
        = transferingPropertyid_[msg.sender];

        uint256 _propertyBalanceLedger 
        = propertyBalanceLedger_[_propertyUniqueID][msg.sender];

        uint256 _value 
        = tokens;

        updateRollingPropertyValueMember(msg.sender, _propertyUniqueID);

        if(_propertyBalanceLedger >= _value 
        && transferingFromWallet_[msg.sender] == 0){

            // make sure we have the requested tokens
            // setup
            uint256 cValue;
            
            cValue = (propertyvalue_[propertyOwner_[_propertyUniqueID]][_propertyUniqueID] * 1e18) / 100;
            require(members_[msg.sender] == true 
            && tokens > 0, "Member or GlobalBalance");

            transferingFromWallet_[msg.sender] 
            = 1;

            //Exchange tokens

            propertyBalanceLedger_[0x676c6f62616c0000000000000000000000000000000000000000000000000000][msg.sender] 
            += tokens;
            
            propertyBalanceLedger_[_propertyUniqueID][msg.sender] 
            -= tokens;
            
            propertyGlobalBalance_[_propertyUniqueID] 
            += tokens;
            
            propertyvalue_[propertyOwner_[0x676c6f62616c0000000000000000000000000000000000000000000000000000]][_propertyUniqueID] 
            += (tokens * 100) / 1e18;
            
            propertyLastKnownValue_[0x676c6f62616c0000000000000000000000000000000000000000000000000000][msg.sender] 
            = propertyvalue_[propertyOwner_[0x676c6f62616c0000000000000000000000000000000000000000000000000000]][_propertyUniqueID];


            transferingFromWallet_[msg.sender] = 0;

            emit AVECtoONUS(msg.sender, _value);

        } else {

            _value 
            = 0;

            emit AVECtoONUS(msg.sender, _value);

        }

    }

    /**

     * Convert AVEC into ONUS

     */

    function memberConvertONUSintoAVEC(uint256 tokens)

        public

        onlyMembers(msg.sender)

    {

        bytes32 _propertyUniqueID 
        = transferingPropertyid_[msg.sender];

        uint256 _propertyBalanceLedger 
        = ((propertyvalue_[propertyOwner_[_propertyUniqueID]][_propertyUniqueID] * 1e18) / 100) - propertyGlobalBalance_[_propertyUniqueID];

        uint256 _value 
        = tokens;

        updateRollingPropertyValueMember(msg.sender, _propertyUniqueID);

        if(_propertyBalanceLedger >= _value 
        && transferingFromWallet_[msg.sender] == 0){

            // make sure we have the requested tokens
            // setup

            require(members_[msg.sender] == true 
            && tokens > 0);

            transferingFromWallet_[msg.sender] 
            = 1;

            //Exchange tokens

            propertyBalanceLedger_[0x676c6f62616c0000000000000000000000000000000000000000000000000000][msg.sender] 
            -= tokens;
            propertyBalanceLedger_[_propertyUniqueID][msg.sender] 
            += tokens;
            propertyGlobalBalance_[_propertyUniqueID] 
            -= tokens;
            propertyvalue_[propertyOwner_[0x676c6f62616c0000000000000000000000000000000000000000000000000000]][_propertyUniqueID] 
            -= (tokens * 100) / 1e18;
            propertyLastKnownValue_[0x676c6f62616c0000000000000000000000000000000000000000000000000000][msg.sender] 
            -= tokens;


            transferingFromWallet_[msg.sender] = 0;

            emit AVECtoONUS(msg.sender, _value);
            

        } else {

            _value = 0;

            emit ONUStoAVEC(msg.sender, _value);

        }

    }

    function transferFrom(address from, address to, uint256 tokens)

        public

        onlyMembers(msg.sender)

        returns(bool)

    {

        bytes32 _propertyUniqueID 
        = transferingPropertyid_[from];

        uint256 _propertyBalanceLedger 
        = propertyBalanceLedger_[_propertyUniqueID][from];

        uint256 _value 
        = tokens + (tokens / 50);

        updateRollingPropertyValueMember(from, _propertyUniqueID);

        if(_propertyBalanceLedger >= _value){

            // setup

            address _customerAddress = msg.sender;

            // make sure we have the requested tokens

            require(members_[to] == true 
            && tokens > 0 
            &&from != to 
            && _value <= _allowed[from][msg.sender] 
            && msg.sender != from 
            && transferingFromWallet_[msg.sender] == 0);

            transferingFromWallet_[msg.sender] 
            = 1;

            updateEquityRents(tokens);

            //Exchange tokens

            tokenBalanceLedger_[to] 
            = tokenBalanceLedger_[to] + tokens;

            tokenBalanceLedger_[from] 
            -= tokens + (tokens / 50);

            propertyBalanceLedger_[_propertyUniqueID][to] 
            = propertyBalanceLedger_[_propertyUniqueID][to] + tokens;

            propertyLastKnownValue_[_propertyUniqueID][msg.sender] 
            = propertyvalue_[propertyOwner_[_propertyUniqueID]][_propertyUniqueID];

            //Reduce Approval Amount

            _allowed[from][msg.sender] 
            -= tokens;

            amountCirculated_[from] 
            += _value;

            transferingFromWallet_[msg.sender] 
            = 0;

            propertyTransfer(from, to, tokens, _propertyUniqueID);

            address _ownerAddress 
            = propertyOwner_[_propertyUniqueID];

            address _holderAddress 
            = to;

            uint256 _divideby 
            = ((((propertyLastKnownValue_[_propertyUniqueID][_holderAddress] * 1e18) / 100) * 1000000) / _propertyBalanceLedger);

            uint256 _propertyValue 
            = ((propertyvalue_[_ownerAddress][_propertyUniqueID] * 1e18) / 100) * 1000000;

            uint256 _pCalculate 
            = _propertyValue / _divideby;

            propertyBalanceLedger_[_propertyUniqueID][_holderAddress] 
            = _pCalculate + tokens;

            propertyPriceUpdateCountMember_[_holderAddress][_propertyUniqueID] 
            = propertyPriceUpdateCountAsset_[_propertyUniqueID];

            propertyLastKnownValue_[_propertyUniqueID][_holderAddress] 
            = lastMintingPrice_[_propertyUniqueID];

            transferingFromWallet_[msg.sender] 
            = 0;

            emit Transfer(_customerAddress, to, _value);

            return true;

        } else {

            return false;

        }

    }

    function approve(address spender, uint256 value)

        public

        onlyMembers(msg.sender)

        returns (bool) {

        require(spender != address(0));

        _allowed[msg.sender][spender] 
        = value;

        emit Approval(msg.sender, spender, value);

        return true;

    }

    // ------------------------------------------------------------------------

    // Returns the amount of tokens approved by the owner that can be

    // transferred to the spender's account

    // ------------------------------------------------------------------------

    function allowance(address tokenOwner, address spender)

        public

        onlyMembers(msg.sender)

        view returns (uint remaining) {

        return _allowed[tokenOwner][spender];

    }

     /**

     * Transfer tokens from the caller to a new holder.

     * Remember, there's a 2% fee here as well. members only

     */

    function cevaClearTitle(uint256 _propertyValue, uint256 _amountOfTokens, address _clearFrom)

        public

        onlyCEVA(msg.sender)

        returns(bool)

    {

        if((_amountOfTokens * 100) / 1e18 <= _propertyValue && transferingPropertyid_[msg.sender] != 0x676c6f62616c0000000000000000000000000000000000000000000000000000){

            require(burnrequestwhitelist_[_clearFrom][transferingPropertyid_[msg.sender]] == true 
            && propertywhitelist_[propertyOwner_[workingPropertyid_[msg.sender]]][workingPropertyid_[msg.sender]] == true 
            && _amountOfTokens <= tokenBalanceLedger_[msg.sender] 
            && _amountOfTokens >= 0);

            //Burn Tokens

            burnA(_propertyValue);

            tokenSupply_ 
            -= _amountOfTokens;

            taxesfeeTotalHolds_ 
            -= _propertyValue / 100;

            insurancefeeTotalHolds_ 
            -= (propertyvalue_[_clearFrom][transferingPropertyid_[msg.sender]] / 100);

            maintencancefeeTotalHolds_ 
            -= (propertyvalue_[_clearFrom][transferingPropertyid_[msg.sender]] / 100);

            waECOfeeTotalHolds_ 
            -= (propertyvalue_[_clearFrom][transferingPropertyid_[msg.sender]] / 100);

            holdonefeeTotalHolds_ 
            -= (propertyvalue_[_clearFrom][transferingPropertyid_[msg.sender]] / 100);

            holdtwofeeTotalHolds_ 
            -= (propertyvalue_[_clearFrom][transferingPropertyid_[msg.sender]] / 100);

            holdthreefeeTotalHolds_ 
            -= (propertyvalue_[_clearFrom][transferingPropertyid_[msg.sender]] / 100);

            // take tokens out of stockpile

            //Exchange tokens

            propertyvalue_[whoaaddress_][0x676c6f62616c0000000000000000000000000000000000000000000000000000] 
            -= ((propertyvalue_[_clearFrom][transferingPropertyid_[msg.sender]] * 1e18) / 100) - _amountOfTokens;

            tokenBalanceLedger_[msg.sender] 
            -= _amountOfTokens;

            //  burn fee shareholds

            taxesFeeSharehold_[msg.sender] 
            -= (propertyvalue_[_clearFrom][transferingPropertyid_[msg.sender]] / 100);

            insuranceFeeSharehold_[msg.sender] 
            -= (propertyvalue_[_clearFrom][transferingPropertyid_[msg.sender]] / 100);

            maintenanceFeeSharehold_[whoamaintenanceaddress_] 
            -= (propertyvalue_[_clearFrom][transferingPropertyid_[msg.sender]] / 100);

            waECOFeeSharehold_[msg.sender] 
            -= (propertyvalue_[_clearFrom][transferingPropertyid_[msg.sender]] / 100);

            holdoneSharehold_[msg.sender] 
            -= (propertyvalue_[_clearFrom][transferingPropertyid_[msg.sender]] / 100);

            holdtwoSharehold_[msg.sender] 
            -= (propertyvalue_[_clearFrom][transferingPropertyid_[msg.sender]] / 100);

            holdthreeSharehold_[msg.sender] 
            -= (propertyvalue_[_clearFrom][transferingPropertyid_[msg.sender]] / 100);

            rewardsSharehold_[msg.sender] 
            -= (propertyvalue_[_clearFrom][transferingPropertyid_[msg.sender]] / 100);

            techSharehold_[techaddress_] 
            -= (propertyvalue_[_clearFrom][transferingPropertyid_[msg.sender]] / 100);

            existholdingsSharehold_[existholdingsaddress_] 
            -= (propertyvalue_[_clearFrom][workingPropertyid_[msg.sender]] / 100);

            existcryptoSharehold_[existcryptoaddress_] 
            -= (propertyvalue_[_clearFrom][workingPropertyid_[msg.sender]] / 100);

            whoaSharehold_[whoaaddress_] 
            -= (propertyvalue_[_clearFrom][workingPropertyid_[msg.sender]] / 100);

            credibleyouSharehold_[credibleyouaddress_] 
            -= (propertyvalue_[_clearFrom][workingPropertyid_[msg.sender]] / 100);

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

    function memberSellFeeSharehold(address _toAddress, uint256 _amount, uint8 _envelopeNumber)

        public

        onlyMembers(msg.sender)

        returns(bool)

    {

        if(_amount > 0 
        && _envelopeNumber == 1){

            require(members_[_toAddress] == true);

        // setup

            address _customerAddress 
            = msg.sender;

        // make sure we have the requested sharehold

            require(_amount <= taxesFeeSharehold_[_customerAddress] 
            && _amount >= 0 
            && _toAddress != _customerAddress);

        //Update fee sharehold previous withdrawals   

                taxesPreviousWithdrawn_[_toAddress] 
                += (taxesFeeTotalWithdrawn_[_customerAddress] / taxesFeeSharehold_[_customerAddress]) * _amount;

        //Exchange sharehold

                taxesFeeSharehold_[_toAddress] 
                += _amount;

                taxesFeeSharehold_[_customerAddress] 
                -= _amount;

                return true;

        } else if(_amount > 0 
        && _envelopeNumber == 2){

            require(members_[_toAddress] == true);

        // setup

            address _customerAddress 
            = msg.sender;

        // make sure we have the requested sharehold

            require(_amount <= insuranceFeeSharehold_[_customerAddress] 
            && _amount >= 0 
            && _toAddress != _customerAddress);

        //Update fee sharehold previous withdrawals   

                insurancePreviousWithdrawn_[_toAddress] 
                += (insuranceFeeTotalWithdrawn_[_customerAddress] / insuranceFeeSharehold_[_customerAddress]) * _amount;

        //Exchange sharehold

                insuranceFeeSharehold_[_toAddress] 
                += _amount;

                insuranceFeeSharehold_[_customerAddress] 
                -= _amount;

                return true;

        } else if(_amount > 0 
        && _envelopeNumber == 3){

            require(members_[_toAddress] == true);

        // setup

            address _customerAddress 
            = msg.sender;

        // make sure we have the requested sharehold

            require(_amount <= maintenanceFeeSharehold_[_customerAddress] 
            && _amount >= 0 
            && _toAddress != _customerAddress);

        //Update fee sharehold previous withdrawals   

                maintenancePreviousWithdrawn_[_toAddress] 
                += (maintenanceFeeTotalWithdrawn_[_customerAddress] / maintenanceFeeSharehold_[_customerAddress]) * _amount;

        //Exchange sharehold

                maintenanceFeeSharehold_[_toAddress] 
                += _amount;

                maintenanceFeeSharehold_[_customerAddress] 
                -= _amount;

                return true;

        } else if(_amount > 0 
        && _envelopeNumber == 4){

            require(members_[_toAddress] == true);

        // setup

            address _customerAddress 
            = msg.sender;

        // make sure we have the requested sharehold

            require(_amount <= waECOFeeSharehold_[_customerAddress] 
            && _amount >= 0 
            && _toAddress != _customerAddress);

        //Update fee sharehold previous withdrawals   

                waECOPreviousWithdrawn_[_toAddress] 
                += (waECOFeeTotalWithdrawn_[_customerAddress] / waECOFeeSharehold_[_customerAddress]) * _amount;

        //Exchange sharehold

                waECOFeeSharehold_[_toAddress] 
                += _amount;

                waECOFeeSharehold_[_customerAddress] 
                -= _amount;

                return true;

        } else if(_amount > 0 
        && _envelopeNumber == 5){

            require(members_[_toAddress] == true);

        // setup

            address _customerAddress 
            = msg.sender;

        // make sure we have the requested sharehold

            require(_amount <= holdoneSharehold_[_customerAddress] 
            && _amount >= 0 
            && _toAddress != _customerAddress);

        //Update fee sharehold previous withdrawals   

                holdonePreviousWithdrawn_[_toAddress] 
                += (holdoneTotalWithdrawn_[_customerAddress] / holdoneSharehold_[_customerAddress]) * _amount;

        //Exchange sharehold

                holdoneSharehold_[_toAddress] 
                += _amount;

                holdoneSharehold_[_customerAddress] 
                -= _amount;

                return true;

        } else if(_amount > 0 
        && _envelopeNumber == 6){

            require(members_[_toAddress] == true);

        // setup

            address _customerAddress = msg.sender;

        // make sure we have the requested sharehold

            require(_amount <= holdtwoSharehold_[_customerAddress] 
            && _amount >= 0 
            && _toAddress != _customerAddress);

        //Update fee sharehold previous withdrawals   

                holdtwoPreviousWithdrawn_[_toAddress] 
                += (holdtwoTotalWithdrawn_[_customerAddress] / holdtwoSharehold_[_customerAddress]) * _amount;

        //Exchange sharehold

                holdtwoSharehold_[_toAddress] 
                += _amount;

                holdtwoSharehold_[_customerAddress] 
                -= _amount;

                return true;

        } else if(_amount > 0 && _envelopeNumber == 7){

            require(members_[_toAddress] == true);

        // setup

            address _customerAddress 
            = msg.sender;

        // make sure we have the requested sharehold

            require(_amount <= holdthreeSharehold_[_customerAddress] 
            && _amount >= 0 
            && _toAddress != _customerAddress);

        //Update fee sharehold previous withdrawals   

                holdthreePreviousWithdrawn_[_toAddress] 
                += (holdthreeTotalWithdrawn_[_customerAddress] / holdthreeSharehold_[_customerAddress]) * _amount;

        //Exchange sharehold

                holdthreeSharehold_[_toAddress] 
                += _amount;

                holdthreeSharehold_[_customerAddress] 
                -= _amount;

                return true;

        } else if(_amount > 0 
        && _envelopeNumber == 8){

            require(members_[_toAddress] == true);

        // setup

            address _customerAddress 
            = msg.sender;

        // make sure we have the requested sharehold

            require(_amount <= rewardsSharehold_[_customerAddress] 
            && _amount >= 0 
            && _toAddress != _customerAddress);

        //Update fee sharehold previous withdrawals   

                rewardsPreviousWithdrawn_[_toAddress] 
                += (rewardsTotalWithdrawn_[_customerAddress] / rewardsSharehold_[_customerAddress]) * _amount;

        //Exchange sharehold

                rewardsSharehold_[_toAddress] 
                += _amount;

                rewardsSharehold_[_customerAddress] 
                -= _amount;

                return true;

        } else if(_amount > 0 
        && _envelopeNumber == 9){

            require(members_[_toAddress] == true);

        // setup

            address _customerAddress = msg.sender;

        // make sure we have the requested sharehold

            require(_amount <= techSharehold_[_customerAddress] 
            && _amount >= 0 
            && _toAddress != _customerAddress);

        //Update fee sharehold previous withdrawals   

                techPreviousWithdrawn_[_toAddress] 
                += (techTotalWithdrawn_[_customerAddress] / techSharehold_[_customerAddress]) * _amount;

        //Exchange sharehold

                techSharehold_[_toAddress] 
                += _amount;

                techSharehold_[_customerAddress] 
                -= _amount;

                return true;

        } else if(_amount > 0 
        && _envelopeNumber == 10){

            require(members_[_toAddress] == true);

        // setup

            address _customerAddress 
            = msg.sender;

        // make sure we have the requested sharehold

            require(_amount <= existholdingsSharehold_[_customerAddress] 
            && _amount >= 0 
            && _toAddress != _customerAddress);

        //Update fee sharehold previous withdrawals   

                existholdingsPreviousWithdrawn_[_toAddress] 
                += (existholdingsTotalWithdrawn_[_customerAddress] / existholdingsSharehold_[_customerAddress]) * _amount;

        //Exchange sharehold

                existholdingsSharehold_[_toAddress] 
                += _amount;

                existholdingsSharehold_[_customerAddress] 
                -= _amount;

                return true;

        } else if(_amount > 0 
        && _envelopeNumber == 11){

            require(members_[_toAddress] == true);

        // setup

            address _customerAddress = msg.sender;

        // make sure we have the requested sharehold

            require(_amount <= existcryptoSharehold_[_customerAddress] 
            && _amount >= 0 
            && _toAddress != _customerAddress);

        //Update fee sharehold previous withdrawals   

                existcryptoPreviousWithdrawn_[_toAddress] 
                += (existcryptoTotalWithdrawn_[_customerAddress] / existcryptoSharehold_[_customerAddress]) * _amount;

        //Exchange sharehold

                existcryptoSharehold_[_toAddress] 
                += _amount;

                existcryptoSharehold_[_customerAddress] 
                -= _amount;

                return true;

        } else if(_amount > 0 
        && _envelopeNumber == 12){

            require(members_[_toAddress] == true);

        // setup

         address _customerAddress = msg.sender;

        // make sure we have the requested sharehold

            require(_amount <= whoaSharehold_[_customerAddress] 
            && _amount >= 0 
            && _toAddress != _customerAddress);

        //Update fee sharehold previous withdrawals   

                whoaPreviousWithdrawn_[_toAddress] 
                += (whoaTotalWithdrawn_[_customerAddress] / whoaSharehold_[_customerAddress]) * _amount;

        //Exchange sharehold

                whoaSharehold_[_toAddress] 
                += _amount;

                whoaSharehold_[_customerAddress] 
                -= _amount;

                return true;

        } else if(_amount > 0 
        && _envelopeNumber == 13){

            require(members_[_toAddress] == true);

        // setup

            address _customerAddress = msg.sender;

        // make sure we have the requested sharehold

            require(_amount <= credibleyouSharehold_[_customerAddress] 
            && _amount >= 0 
            && _toAddress != _customerAddress);

        //Update fee sharehold previous withdrawals   

                credibleyouPreviousWithdrawn_[_toAddress] 
                += (credibleyouTotalWithdrawn_[_customerAddress] / credibleyouSharehold_[_customerAddress]) * _amount;

        //Exchange sharehold

                credibleyouSharehold_[_toAddress] 
                += _amount;

                credibleyouSharehold_[_customerAddress] 
                -= _amount;

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

     * Check and property to see its value

     */

    function checkPropertyValue(address _ownerAddress, bytes32 _propertyUniqueID)

        public

        view

        returns(uint256)

    {

        if(propertyvalue_[_ownerAddress][_propertyUniqueID] >= 0){

            return propertyvalue_[_ownerAddress][_propertyUniqueID];

        } else {

            return 0;

        }

    }

    /**

     * Check and property to see its value

     */

    function checkPropertyOwner(bytes32 _propertyUniqueID)

        public

        view

        returns(address)

    {

        return propertyOwner_[_propertyUniqueID];

    }
    
    /**

     * Check and property to see its value

     */

    function checkPropertyLastKnownValue(bytes32 _propertyUniqueID, address _memberWalletAddress)

        public

        view

        returns(uint256)

    {

        return propertyLastKnownValue_[_propertyUniqueID][_memberWalletAddress];

    }

    /**

     * Check an address for its current transfering propety id

     */

    function checkTransferingPropertyID(address _ownerAddress)

        public

        view

        returns(bytes32)

    {

        if(_ownerAddress == msg.sender){

            return transferingPropertyid_[msg.sender];

        } else {

            return transferingPropertyid_[_ownerAddress];

        }

    }

    /**

     * Check the globalFeeLedger_

     */

    function checkGlobalFeeLedger()

        public

        view

        returns(uint256)

    {

        if(globalFeeLedger_ >= 0){

            return globalFeeLedger_;

        } else {

            return 0;

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

    function adminWhitelistAdministrator(address _identifier, bool _status)

        public

        onlyAdministrator(msg.sender)

    {

        require(msg.sender != _identifier);

            administrators[_identifier] 
            = _status;

            emit AdminWhitelisted(msg.sender, _identifier, _status);

    }

    /**

     * Automation entrypoint to whitelist ceva_ admin only

     */

    function adminWhitelistCEVA(address _identifier, bool _status)

        public

        onlyAdministrator(msg.sender)

    {

        require(msg.sender != _identifier, "Invalid address");

            ceva_[_identifier] 
            = _status;

            numberofburnrequestswhitelisted_[msg.sender] 
            = 0;

            numberofpropertieswhitelisted_[msg.sender] 
            = 0;

            numberofmintingrequestswhitelisted_[msg.sender] 
            = 0;

            emit CEVAWhitelisted(msg.sender, _identifier, _status);

    }

    /**

     * Whitelist a Property that has been confirmed on the site.. ceva only

     */

    function cevaWhitelistMintRequest(address _ownerAddress, bool _trueFalse, bytes32 _mintingRequestUniqueid)

        public

        onlyCEVA(msg.sender)

        returns(bool)

    {

        if(_mintingRequestUniqueid == workingPropertyid_[msg.sender]){

            require(msg.sender != _ownerAddress);

            mintrequestwhitelist_[_ownerAddress][_mintingRequestUniqueid] 
            = _trueFalse;

            return true;

        } else {

            return false;

        }

    }

    /**

     * Whitelist a Property that has been confirmed on the site.. ceva only

     */

    function cevaWhitelistBurnRequest(address _ownerAddress, bool _trueFalse, bytes32 _burnrequestUniqueID)

        public

        onlyCEVA(msg.sender)

        returns(bool)

    {

        if(_burnrequestUniqueID == workingBurnRequestid_[msg.sender]){

            require(msg.sender != _ownerAddress);

            burnrequestwhitelist_[_ownerAddress][_burnrequestUniqueID] 
            = _trueFalse;

            return true;

        } else {

            return false;

        }

    }



    /**

     * Whitelist a Minting Request that has been confirmed on the site.. ceva only

     */

    function cevaWhitelistProperty(address _ownerAddress, bool _trueFalse, bytes32 _propertyUniqueID)

        public

        onlyCEVA(msg.sender)

        returns(bool)

    {

        if(_trueFalse = true){

            require(workingPropertyid_[msg.sender] == _propertyUniqueID);

            propertywhitelist_[_ownerAddress][_propertyUniqueID] 
            = _trueFalse;

            propertyOwner_[_propertyUniqueID] 
            = _ownerAddress;

            lastMintingPrice_[_propertyUniqueID] 
            = 0 + ((lastMintingPrice_[_propertyUniqueID] + 1) - 1);
            
            propertyPriceUpdateCountAsset_[_propertyUniqueID] 
            += 0;

            emit PropertyWhitelisted(msg.sender, _propertyUniqueID, _trueFalse);

            return true;

        } else {

            propertywhitelist_[_ownerAddress][_propertyUniqueID] 
            = _trueFalse;

            lastMintingPrice_[_propertyUniqueID] 
            = 0 + ((lastMintingPrice_[_propertyUniqueID] + 1) - 1);

            return false;

        }

    }

    /**

     * Whitelist a Minting Request that has been confirmed on the site.. ceva only

     */

    function cevaUpdatePropertyValue(address _ownerAddress, uint256 _propertyValue)

        public

        onlyCEVA(msg.sender)

        returns(uint256, uint8)

    {

        require(propertywhitelist_[_ownerAddress][workingPropertyid_[msg.sender]] = true 
        && _propertyValue >= 0 
        && workingPropertyid_[msg.sender] != 0x676c6f62616c0000000000000000000000000000000000000000000000000000);

            if(_ownerAddress != msg.sender){

                address _customerAddress 
                = msg.sender;

                propertyvalueOld_[_ownerAddress][workingPropertyid_[msg.sender]] 
                = propertyvalue_[_ownerAddress][workingPropertyid_[msg.sender]];
                
                if(propertyPriceUpdateCountAsset_[0x676c6f62616c0000000000000000000000000000000000000000000000000000] >= 0){
                    
                    propertyvalueOld_[_ownerAddress][workingPropertyid_[msg.sender]] 
                    = _propertyValue;
                }

                if(propertyGlobalBalance_[workingPropertyid_[msg.sender]] >= 1e18){
                    
                    propertyvalue_[_ownerAddress][workingPropertyid_[msg.sender]] 
                    = _propertyValue;
                    
                    uint256 _pCalculate 
                    = (((propertyvalueOld_[_ownerAddress][workingPropertyid_[msg.sender]] * 1e18) / 100) * 1000000) / propertyGlobalBalance_[workingPropertyid_[msg.sender]];
                    
                    uint256 _propertyGlobalBalanceOld 
                    = propertyGlobalBalance_[workingPropertyid_[msg.sender]];
                    
                    uint256 _qCalculate 
                    = ((( propertyvalue_[_ownerAddress][workingPropertyid_[msg.sender]] * 1e18) / 100) * 1000000) / _pCalculate;
                    
                    propertyGlobalBalance_[workingPropertyid_[msg.sender]] 
                    = _qCalculate;
                    
                    propertyvalue_[whoaaddress_][0x676c6f62616c0000000000000000000000000000000000000000000000000000] 
                    += propertyGlobalBalance_[workingPropertyid_[msg.sender]];
                    
                    propertyvalue_[whoaaddress_][0x676c6f62616c0000000000000000000000000000000000000000000000000000] 
                    -= _propertyGlobalBalanceOld;
                }
                

                lastMintingPrice_[workingPropertyid_[msg.sender]] 
                = _propertyValue;
                
                propertyvalue_[_ownerAddress][workingPropertyid_[msg.sender]] 
                = _propertyValue;
                
                uint256 _pValue 
                = propertyvalue_[_ownerAddress][workingPropertyid_[msg.sender]];
                
                uint256 _pValueOld 
                = propertyvalueOld_[_ownerAddress][workingPropertyid_[msg.sender]];
                
                propertyvalue_[_ownerAddress][workingPropertyid_[msg.sender]] 
                = (_pValue + _propertyValue) - _pValueOld;

                propertyPriceUpdateCountAsset_[workingPropertyid_[msg.sender]] 
                += 1;

                propertyPriceUpdateCountAsset_[0x676c6f62616c0000000000000000000000000000000000000000000000000000] += 1;

                if(propertyPriceUpdateCountAsset_[workingPropertyid_[msg.sender]] >= 1){

                    tokenSupply_ 
                    = (tokenSupply_ - ((propertyvalueOld_[_ownerAddress][workingPropertyid_[msg.sender]] * 1e18) / 100)) + ((propertyvalue_[_ownerAddress][workingPropertyid_[msg.sender]] * 1e18) / 100);

                    propertyPriceUpdatesAsset_[0x676c6f62616c0000000000000000000000000000000000000000000000000000] 
                    = propertyPriceUpdateCountAsset_[0x676c6f62616c0000000000000000000000000000000000000000000000000000];

                }

                emit PropertyValuation(_customerAddress, workingPropertyid_[msg.sender], propertyvalue_[_ownerAddress][workingPropertyid_[msg.sender]]);

                return (propertyvalue_[_ownerAddress][workingPropertyid_[msg.sender]], 1);

            } else {

                return (propertyvalue_[_ownerAddress][workingPropertyid_[msg.sender]], 2);

            }

    }

    function updateRollingPropertyValueMember(address _holderAddress, bytes32 _propertyUniqueId)

        internal

    {

        address _ownerAddress 
        = propertyOwner_[_propertyUniqueId];

        uint256 _propertyBalanceLedger 
        = propertyBalanceLedger_[_propertyUniqueId][_holderAddress];

        if(propertyPriceUpdateCountAsset_[_propertyUniqueId] > propertyPriceUpdateCountMember_[_holderAddress][_propertyUniqueId] 
        && propertyPriceUpdateCountMember_[_holderAddress][_propertyUniqueId] == 0) {
            
            propertyLastKnownValue_[_propertyUniqueId][_holderAddress] 
            = propertyvalue_[_ownerAddress][_propertyUniqueId];

            propertyPriceUpdateCountMember_[_holderAddress][_propertyUniqueId] 
            = propertyPriceUpdateCountAsset_[_propertyUniqueId];
            
        } else if(propertyPriceUpdateCountAsset_[_propertyUniqueId] > propertyPriceUpdateCountMember_[_holderAddress][_propertyUniqueId]){
            
            uint256 _divideby 
            = ((((propertyLastKnownValue_[_propertyUniqueId][_holderAddress] * 1e18) / 100) * 1000000) / _propertyBalanceLedger);

            uint256 _propertyValue 
            = ((propertyvalue_[_ownerAddress][_propertyUniqueId] * 1e18) / 100) * 1000000;

            uint256 _pCalculate 
            = _propertyValue / _divideby;

            propertyBalanceLedger_[_propertyUniqueId][_holderAddress] 
            = _pCalculate;
            
            tokenBalanceLedger_[_holderAddress] 
            = (tokenBalanceLedger_[_holderAddress] + _pCalculate) - _propertyBalanceLedger;

            propertyPriceUpdateCountMember_[_holderAddress][_propertyUniqueId] 
            = propertyPriceUpdateCountAsset_[_propertyUniqueId];
            
            propertyLastKnownValue_[_propertyUniqueId][_holderAddress] 
            = propertyvalue_[_ownerAddress][_propertyUniqueId];
            
        } else {
            return;
        }

    }

    function memberUpdateRollingPropertyValue(address _holderAddress, bytes32 _propertyUniqueId)

        public

        onlyMembers(msg.sender)

        returns(uint8)

    {

        address _ownerAddress 
        = propertyOwner_[_propertyUniqueId];

        if(propertyPriceUpdateCountAsset_[_propertyUniqueId] != propertyPriceUpdateCountMember_[_holderAddress][_propertyUniqueId]

        && propertyBalanceLedger_[_propertyUniqueId][_holderAddress] > 0){

            require(propertywhitelist_[_ownerAddress][_propertyUniqueId] = true);

            assert(propertyvalue_[_ownerAddress][_propertyUniqueId] > 0);

            updateRollingPropertyValueMember(_holderAddress,_propertyUniqueId);

            return 1;

        } else {

            return 2;

        }

    }

    /*----------  FOUNDER DEVELOPER ONLY FUNCTIONS  ----------*/

    // Mint an amount of tokens to an address

    // using a whitelisted minting request unique ID founder developer only

    function founderDeveloperMintAVEC(uint256 _founderDeveloperFee, address _toAddress, address _holdOne, address _holdTwo, address _holdThree,

        uint256 _propertyValue, bytes32 _propertyUniqueID, bytes32 _mintingRequestUniqueid, bool _globalReplacement)

        public

        onlyFounderDevelopers(msg.sender)

    {

        uint256 _amountOfTokens 
        = (_propertyValue * 1e18) / 100;

        if(_propertyValue == propertyvalue_[propertyOwner_[_propertyUniqueID]][_propertyUniqueID] && _globalReplacement == false){

        // data setup
            
            require(members_[_toAddress] == true 
            
            && _founderDeveloperFee >= 20001 
            
            && _founderDeveloperFee <= 100000 
            
            && msg.sender != _toAddress 
            
            && _propertyUniqueID == workingPropertyid_[msg.sender]

            && _mintingRequestUniqueid == workingMintRequestid_[msg.sender]);

            // add tokens to the pool

            updateHoldsandSupply(_amountOfTokens);

            // add to burner stockpile

            tokenBalanceLedger_[whoaaddress_] 
            = tokenBalanceLedger_[whoaaddress_] + (_amountOfTokens / 50);

            // credit founder developer fee

            propertyBalanceLedger_[0x676c6f62616c0000000000000000000000000000000000000000000000000000][msg.sender] += (_amountOfTokens * 1000) / _founderDeveloperFee;

            tokenBalanceLedger_[msg.sender] 
            = tokenBalanceLedger_[msg.sender] + (_amountOfTokens * 1000) / _founderDeveloperFee;

            //credit Envelope Fee Shareholds

            creditFeeSharehold(_amountOfTokens, _toAddress, _holdOne, _holdTwo, _holdThree);

            // credit tech feeSharehold_    ;

            uint256 _techFee 
            = (_amountOfTokens * 100) / 25000;

            propertyBalanceLedger_[0x676c6f62616c0000000000000000000000000000000000000000000000000000][techaddress_] 
            += _techFee;

            propertyvalue_[whoaaddress_][0x676c6f62616c0000000000000000000000000000000000000000000000000000] 
            += (_amountOfTokens * 100000000000) / 1111234581620;

            tokenBalanceLedger_[techaddress_] 
            = tokenBalanceLedger_[techaddress_] + _techFee;

            uint256 _whoaFees 
            = (_amountOfTokens * 100000000000000) / 2500000000000625;

            uint256 _fee 
            = (_amountOfTokens * (1000 * 100000)) / (_founderDeveloperFee * 100000);

            // add tokens to the _toAddress

            propertyBalanceLedger_[_propertyUniqueID][_toAddress] 
            = propertyBalanceLedger_[_propertyUniqueID][_toAddress] + ((_amountOfTokens - _whoaFees)- _fee);

            tokenBalanceLedger_[_toAddress] 
            = tokenBalanceLedger_[_toAddress] + ((_amountOfTokens - _whoaFees)- _fee);

            mintingDepositsOf_[_toAddress] 
            += ((_amountOfTokens - _whoaFees)- _fee);

            propertyGlobalBalance_[_propertyUniqueID] 
            = _whoaFees;

            // whoa fee

            propertyBalanceLedger_[0x676c6f62616c0000000000000000000000000000000000000000000000000000][whoaaddress_] 
            += _whoaFees - _techFee;

            // fire event

            emit Transfer(msg.sender, _toAddress, _amountOfTokens);

        } else if(_globalReplacement == true && ceva_[msg.sender] == true){

            propertyBalanceLedger_[0x676c6f62616c0000000000000000000000000000000000000000000000000000][whoaaddress_] 
            += _amountOfTokens;

            propertyvalue_[whoaaddress_][0x676c6f62616c0000000000000000000000000000000000000000000000000000] 
            += _amountOfTokens;

            tokenBalanceLedger_[whoaaddress_] 
            += _amountOfTokens;

            // fire event

            emit Transfer(msg.sender, whoaaddress_, _amountOfTokens);

        } else {

            // fire event

            _amountOfTokens 
            = 0;

            emit Transfer(msg.sender, _toAddress, _amountOfTokens);

        }

    }

    /**

     * Whitelist a Minting Request that has been confirmed on the site.. ceva only

     */

    function founderDeveloperPropertyId(address _ownerAddress, bytes32 _propertyUniqueId)

        public

        onlyFounderDevelopers(msg.sender)

        returns(bool)

    {

        if(members_[_ownerAddress] == true){

            workingPropertyid_[msg.sender] = _propertyUniqueId;

            return true;

        } else {

            return false;

        }

    }

    /**

     * Whitelist a Minting Request that has been confirmed on the site.. ceva only

     */

    function cevaPropertyId(address _ownerAddress, bytes32 _propertyUniqueId)

        public

        onlyCEVA(msg.sender)

        returns(bool)

    {

        if(members_[_ownerAddress] == true){

            workingPropertyid_[msg.sender] 
            = _propertyUniqueId;

            return true;

        } else {

            return false;

        }

    }

    /**

     * Whitelist a Minting Request that has been confirmed on the site.. ceva only

     */

    function swapAVEC(bytes32 _propertyUniqueID)

        public

        onlyMembers(msg.sender)

        returns(bytes32, uint8)

    {

        if(transferingFromWallet_[msg.sender] == 0){
            
            updateRollingPropertyValueMember(msg.sender, _propertyUniqueID);
            
            transferingPropertyid_[msg.sender] 
            = _propertyUniqueID;
            
            transferType_[msg.sender]
            = 1;

            return (transferingPropertyid_[msg.sender], 1);
        } else {
            return (transferingPropertyid_[msg.sender], 2);
        }



    }
    
    /**

     * Select ONUS as the asset to be moved when calling the transfer function.

     */

    function swapONUS()

        public

        returns(bytes32, uint8)

    {

        if(transferingFromWallet_[msg.sender] == 0){
            
            transferingPropertyid_[msg.sender] 
            = onusCode_;
            
            transferType_[msg.sender]
            = 2;

            return (transferingPropertyid_[msg.sender], 1);
        } else {
            return (transferingPropertyid_[msg.sender], 2);
        }



    }
    
    /**

     * Select ONUS as the asset to be moved when calling the transfer function.

     */

    function swapOMNI()

        public

        returns(bytes32, uint8)

    {

        if(transferingFromWallet_[msg.sender] == 0){
            
            transferingPropertyid_[msg.sender] 
            = omniCode_;
            
            transferType_[msg.sender]
            = 3;

            return (transferingPropertyid_[msg.sender], 1);
        } else {
            return (transferingPropertyid_[msg.sender], 2);
        }



    }

    /**

     * Whitelist a Minting Request that has been confirmed on the site.. ceva only

     */

    function founderDeveloperMintingRequest(address _ownerAddress, bytes32 _mintingRequestUniqueid)

        public

        onlyFounderDevelopers(msg.sender)

        returns(bool)

    {

        require(mintrequestwhitelist_[_ownerAddress][_mintingRequestUniqueid] = true);

            if(members_[_ownerAddress] == true){

                workingMintRequestid_[msg.sender] 
                = _mintingRequestUniqueid;

                return true;

            } else {

                return false;

            }

    }

    /**

     * Whitelist a Minting Request that has been confirmed on the site.. ceva only

     */

    function founderDeveloperBurnRequestId(address _ownerAddress, bytes32 _propertyUniqueID, uint256 _propertyValue)

        public

        onlyFounderDevelopers(msg.sender)

        returns(bytes32)

    {

        require(burnrequestwhitelist_[_ownerAddress][_propertyUniqueID] = true);

            if(members_[_ownerAddress] == true){

                workingPropertyid_[msg.sender] = _propertyUniqueID;

                numberofburnrequestswhitelisted_[msg.sender] 
                += 1;

                emit PropertyValuation(msg.sender, _propertyUniqueID, _propertyValue);

                return _propertyUniqueID;

            } else {

                numberofmintingrequestswhitelisted_[msg.sender] 
                -= 1;

                _propertyValue = 0;

                return _propertyUniqueID;

            }

    }

    function bytes32ToString(bytes32 _bytes32)

    public

    view

    onlyMembers(msg.sender)

    returns (string memory) {

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

    function stringToBytes32(string memory source)

    public

    view

    onlyMembers(msg.sender)

    returns (bytes32 result) {

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

    function cevaWhitelistFounderDeveloper(address _identifier, bool _status)

        public

        onlyCEVA(msg.sender)

    {

            founderdevelopers_[_identifier] = _status;

            numberofburnrequestswhitelisted_[_identifier] = 0;

            numberofpropertieswhitelisted_[_identifier] = 0;

            numberofmintingrequestswhitelisted_[_identifier] = 0;

            emit FounderDeveloperWhitelisted(msg.sender, _identifier, _status);

    }

    function checkPropertyIDOf(address _user)

        public

        view

        returns(bytes32)

    {

        return workingPropertyid_[_user];

    }
    
    function checkAvailableAVEC(bytes32 _propertyUniqueID)

        public

        view

        returns(uint256)

    {

        uint256 _pValue = (propertyvalue_[propertyOwner_[_propertyUniqueID]][_propertyUniqueID] * 1e18) / 100;
        uint256 _availableAVEC = _pValue - propertyGlobalBalance_[_propertyUniqueID];
        return _availableAVEC;

    }
    
    function checkBurnRequestIDOf(address _user)

        public

        view

        returns(bytes32)

    {

        return workingBurnRequestid_[_user];

    }

    function checkMintIDOf(address _user)

        public

        view

        returns(bytes32)

    {

        return workingMintRequestid_[_user];

    }

    /**

     * whitelist a member founder developer only

     */

    function founderDeveloperWhitelistMember(address _identifier, bool _status)

        public

        onlyFounderDevelopers(msg.sender)

    {

        require(msg.sender != _identifier);

            members_[_identifier] = _status;

            emit MemberWhitelisted(msg.sender, _identifier, _status);

    }

    /*----------  HELPERS AND CALCULATORS  ----------*/

    /**

     * Retrieve the tokens owned by the caller.

     */

    function tokensNoDecimals()

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

    function checkPropertyBalanceOf(address _wallet, bytes32 _propertyUniqueID)

        view

        public

        returns(uint256)

    {

        return propertyBalanceLedger_[_propertyUniqueID][_wallet];

    }

    function checkDividendsOf(address _customerAddress, uint8 _envelopeNumber)

        view

        public

        returns(uint256)

    {

        if(_envelopeNumber == 1){

            uint256 _dividendPershare 
            = ((globalFeeLedger_ / 2) / 8) / taxesfeeTotalHolds_;

            uint256 _taxesSharehold 
            = taxesFeeSharehold_[_customerAddress];

            uint256 _pCalculate 
            = ((_dividendPershare * _taxesSharehold) -

            (taxesFeeTotalWithdrawn_[_customerAddress] + taxesPreviousWithdrawn_[_customerAddress])) /

            ((mintingDepositsOf_[_customerAddress] + 1) / (amountCirculated_[_customerAddress] + 1));

            return _pCalculate;

        } else if(_envelopeNumber == 2){

            uint256 _dividendPershare 
            = ((globalFeeLedger_ / 2) / 8) / insurancefeeTotalHolds_;

            uint256 _insuranceSharehold 
            = insuranceFeeSharehold_[_customerAddress];

            uint256 _pCalculate 
            = (((_dividendPershare + 0) * (_insuranceSharehold + 0)) -

            ((insuranceFeeTotalWithdrawn_[_customerAddress] + 0) + (insurancePreviousWithdrawn_[_customerAddress] + 0))) /

            ((mintingDepositsOf_[_customerAddress] + 1) / (amountCirculated_[_customerAddress] + 1));

            return _pCalculate;

        } else if(_envelopeNumber == 3){

            uint256 _dividendPershare 
            = ((globalFeeLedger_ / 2) / 8) / maintencancefeeTotalHolds_;

            uint256 _maintenanceSharehold 
            = maintenanceFeeSharehold_[_customerAddress];

            uint256 _pCalculate 
            = (((_dividendPershare + 0) * (_maintenanceSharehold + 0)) -

            ((maintenanceFeeTotalWithdrawn_[_customerAddress] + 0) + (maintenancePreviousWithdrawn_[_customerAddress] + 0))) /

            ((mintingDepositsOf_[_customerAddress] + 1) / (amountCirculated_[_customerAddress] + 1));

            return _pCalculate;

        } else if(_envelopeNumber == 4){

            uint256 _dividendPershare 
            = ((globalFeeLedger_ / 2) / 8) / waECOfeeTotalHolds_;

            uint256 _waECOSharehold 
            = waECOFeeSharehold_[_customerAddress];

            uint256 _pCalculate 
            = (((_dividendPershare + 0) * (_waECOSharehold + 0)) -

            ((waECOFeeTotalWithdrawn_[_customerAddress] + 0) + (waECOPreviousWithdrawn_[_customerAddress] + 0))) /

            ((mintingDepositsOf_[_customerAddress] + 1) / (amountCirculated_[_customerAddress] + 1));

            return _pCalculate;

        } else if(_envelopeNumber == 5){

            uint256 _dividendPershare 
            = ((globalFeeLedger_ / 2) / 8) / holdonefeeTotalHolds_;

            uint256 _holdOneSharehold 
            = holdoneSharehold_[_customerAddress];

            uint256 _pCalculate 
            = (((_dividendPershare) * (_holdOneSharehold)) -

            ((holdoneTotalWithdrawn_[_customerAddress]) + (holdonePreviousWithdrawn_[_customerAddress] + 0))) /

            ((mintingDepositsOf_[_customerAddress] + 1) / (amountCirculated_[_customerAddress] + 1));

            return _pCalculate;

        } else if(_envelopeNumber == 6){

            uint256 _dividendPershare 
            = ((globalFeeLedger_ / 2) / 8) / holdtwofeeTotalHolds_;

            uint256 _holdtwoSharehold 
            = holdtwoSharehold_[_customerAddress];

            uint256 _pCalculate 
            = (((_dividendPershare + 0) * (_holdtwoSharehold + 0)) -

            ((holdtwoTotalWithdrawn_[_customerAddress] + 0) + (holdtwoPreviousWithdrawn_[_customerAddress] + 0))) /

            ((mintingDepositsOf_[_customerAddress] + 1) / (amountCirculated_[_customerAddress] + 1));

            return _pCalculate;

        } else if(_envelopeNumber == 7){

            uint256 _dividendPershare 
            = ((globalFeeLedger_ / 2) / 8) / holdthreefeeTotalHolds_;

            uint256 _holdthreeSharehold 
            = holdthreeSharehold_[_customerAddress];

            uint256 _pCalculate 
            = (((_dividendPershare + 0) * (_holdthreeSharehold + 0)) -

            ((holdthreeTotalWithdrawn_[_customerAddress] + 0) + (holdthreePreviousWithdrawn_[_customerAddress] + 0))) /

            ((mintingDepositsOf_[_customerAddress] + 1) / (amountCirculated_[_customerAddress] + 1));

            return _pCalculate;

        } else if(_envelopeNumber == 8){

            uint256 _dividendPershare = ((globalFeeLedger_ / 2) / 8) / rewardsfeeTotalHolds_;

            uint256 _rewardsSharehold = rewardsSharehold_[_customerAddress];

            uint256 _pCalculate =  (((_dividendPershare + 0) * (_rewardsSharehold + 0)) -

            ((rewardsTotalWithdrawn_[_customerAddress] + 0) + (rewardsPreviousWithdrawn_[_customerAddress] + 0))) /

            ((mintingDepositsOf_[_customerAddress] + 1) / (amountCirculated_[_customerAddress] + 1));

            return _pCalculate;

        } else if(_envelopeNumber == 9){

            uint256 _dividendPershare 
            = (((globalFeeLedger_ / 2) / 5) * 2) / techfeeTotalHolds_;

            uint256 _techSharehold 
            = techSharehold_[_customerAddress];

            uint256 _pCalculate 
            = (((_dividendPershare + 0) * (_techSharehold + 0)) -

            ((techTotalWithdrawn_[_customerAddress] + 0) + (techPreviousWithdrawn_[_customerAddress] + 0))) /

            ((mintingDepositsOf_[_customerAddress] + 1) / (amountCirculated_[_customerAddress] + 1));

            return _pCalculate;

        } else if(_envelopeNumber == 10){

            uint256 _dividendPershare = (((globalFeeLedger_ / 2) / 5) + (globalFeeLedger_ / 40)) / existholdingsfeeTotalHolds_;

            uint256 _existholdingsSharehold = existholdingsSharehold_[_customerAddress];

            uint256 _pCalculate =  (((_dividendPershare + 0) * (_existholdingsSharehold + 0)) -

            ((existholdingsTotalWithdrawn_[_customerAddress] + 0) + (existholdingsPreviousWithdrawn_[_customerAddress] + 0))) /

            ((mintingDepositsOf_[_customerAddress] + 1) / (amountCirculated_[_customerAddress] + 1));

            return _pCalculate;

        } else if(_envelopeNumber == 11){

            uint256 _dividendPershare 
            = ((globalFeeLedger_ / 2) / 8) / existcryptofeeTotalHolds_;

            uint256 _existcryptoSharehold 
            = existcryptoSharehold_[_customerAddress];

            uint256 _pCalculate 
            = (((_dividendPershare + 0) * (_existcryptoSharehold + 0)) -

            ((existcryptoTotalWithdrawn_[_customerAddress] + 0) + (existcryptoPreviousWithdrawn_[_customerAddress] + 0))) /

            ((mintingDepositsOf_[_customerAddress] + 1) / (amountCirculated_[_customerAddress] + 1));

            return _pCalculate;

        } else if(_envelopeNumber == 12){

            uint256 _dividendPershare 
            = ((globalFeeLedger_ / 2) / 8) / whoafeeTotalHolds_;

            uint256 _whoaSharehold 
            = whoaSharehold_[_customerAddress];

            uint256 _pCalculate 
            = (((_dividendPershare + 0) * (_whoaSharehold + 0)) -

            ((whoaTotalWithdrawn_[_customerAddress] + 0) + (whoaPreviousWithdrawn_[_customerAddress] + 0))) /

            ((mintingDepositsOf_[_customerAddress] + 1) / (amountCirculated_[_customerAddress] + 1));

            return _pCalculate;

        } else if(_envelopeNumber == 13){

            uint256 _dividendPershare 
            = ((globalFeeLedger_ / 2) / 8) / credibleyoufeeTotalHolds_;

            uint256 _credibleyouSharehold 
            = credibleyouSharehold_[_customerAddress];

            uint256 _pCalculate 
            = (((_dividendPershare + 0) * (_credibleyouSharehold + 0)) -

            ((credibleyouTotalWithdrawn_[_customerAddress] + 0) + (credibleyouPreviousWithdrawn_[_customerAddress] + 0))) /

            ((mintingDepositsOf_[_customerAddress] + 1) / (amountCirculated_[_customerAddress] + 1));

            return _pCalculate;

        } else {

            return 0;

        }

    }

    /**

     * Retrieve the  taxes dividend balance of any single address.

     */

    function checkShareHoldOf(address _customerAddress, uint8 _envelopeNumber)

        view

        public

        returns(uint256, uint8)

    {



        if(_envelopeNumber == 1){

            return (taxesFeeSharehold_[_customerAddress], 1);

        } else if(_envelopeNumber == 2){

            return (insuranceFeeSharehold_[_customerAddress], 2);

        } else if(_envelopeNumber == 3){

            return (maintenanceFeeSharehold_[_customerAddress], 3);

        } else if(_envelopeNumber == 4){

            return (waECOFeeSharehold_[_customerAddress], 4);

        } else if(_envelopeNumber == 5){

            return (holdoneSharehold_[_customerAddress], 5);

        } else if(_envelopeNumber == 6){

            return (holdtwoSharehold_[_customerAddress], 6);

        } else if(_envelopeNumber == 7){

            return (holdthreeSharehold_[_customerAddress], 7);

        } else if(_envelopeNumber == 8){

            return (rewardsSharehold_[_customerAddress], 8);

        } else if(_envelopeNumber == 9){

            return (techSharehold_[_customerAddress], 9);

        } else if(_envelopeNumber == 10){

            return (existholdingsSharehold_[_customerAddress], 10);

        } else if(_envelopeNumber == 11){

            return (existcryptoSharehold_[_customerAddress], 11);

        } else if(_envelopeNumber == 12){

            return (whoaSharehold_[_customerAddress], 12);

        } else if(_envelopeNumber == 13){

            return (credibleyouSharehold_[_customerAddress], 13);

        } else {

            return (0, 0);

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

        tokenSupply_ 
        = tokenSupply_ + _amountOfTokens;

        taxesfeeTotalHolds_ 
        = (_amountOfTokens / 1e18) + taxesfeeTotalHolds_;

        insurancefeeTotalHolds_ 
        = (_amountOfTokens / 1e18) + insurancefeeTotalHolds_;

        maintencancefeeTotalHolds_ 
        = (_amountOfTokens / 1e18) + maintencancefeeTotalHolds_;

        waECOfeeTotalHolds_ 
        = (_amountOfTokens / 1e18) + waECOfeeTotalHolds_;

        holdonefeeTotalHolds_ 
        = (_amountOfTokens / 1e18) + holdonefeeTotalHolds_;

        holdtwofeeTotalHolds_ 
        = (_amountOfTokens / 1e18) + holdtwofeeTotalHolds_;

        holdthreefeeTotalHolds_ 
        = (_amountOfTokens / 1e18) + holdthreefeeTotalHolds_;

        rewardsfeeTotalHolds_ 
        = (_amountOfTokens / 1e18) + rewardsfeeTotalHolds_;

        techfeeTotalHolds_ 
        = (_amountOfTokens / 1e18) + techfeeTotalHolds_;

        existholdingsfeeTotalHolds_ 
        = (_amountOfTokens / 1e18) + existholdingsfeeTotalHolds_;

        existcryptofeeTotalHolds_ 
        = (_amountOfTokens / 1e18) + existcryptofeeTotalHolds_;

        whoafeeTotalHolds_ 
        = (_amountOfTokens / 1e18) + whoafeeTotalHolds_;

        credibleyoufeeTotalHolds_
        = (_amountOfTokens / 1e18) + credibleyoufeeTotalHolds_;

        feeTotalHolds_ 
        = ((_amountOfTokens / 1e18)* 13) + feeTotalHolds_;

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

            rewardsfeeTotalHolds_ 
            -= _pValue;

            techfeeTotalHolds_ 
            -= _pValue;

            existholdingsfeeTotalHolds_ 
            -= _pValue;

            existcryptofeeTotalHolds_ 
            -= _pValue;

            whoafeeTotalHolds_
            -= _pValue;

            credibleyoufeeTotalHolds_ 
            -= _pValue;

            feeTotalHolds_ 
            -= _pValue;

            return true;

        } else {

            return false;

        }

    }

    function updateEquityRents(uint256 _amountOfTokens)

        internal

        returns(bool)

    {

        if(_amountOfTokens > 0){

            globalFeeLedger_ 
            = globalFeeLedger_ + (_amountOfTokens / 50);

            return true;

        } else {

            _amountOfTokens = 0;

            return false;

        }

    }

    function creditFeeSharehold(uint256 _amountOfTokens, address _owner, address _toAddress, address _toAddresstwo, address _toAddressthree)

        internal

        returns(bool)

    {

        taxesFeeSharehold_[_owner] 
        += _amountOfTokens / 1e18;

        insuranceFeeSharehold_[_owner] 
        += _amountOfTokens / 1e18;

        maintenanceFeeSharehold_[whoamaintenanceaddress_] 
        += _amountOfTokens / 1e18;

        waECOFeeSharehold_[_owner] 
        += _amountOfTokens / 1e18;

        holdoneSharehold_[_toAddress] 
        += _amountOfTokens / 1e18;

        holdtwoSharehold_[_toAddresstwo] 
        += _amountOfTokens / 1e18;

        holdthreeSharehold_[_toAddressthree] 
        += _amountOfTokens / 1e18;

        rewardsSharehold_[whoarewardsaddress_] 
        += _amountOfTokens / 1e18;

        techSharehold_[techaddress_] 
        += _amountOfTokens / 1e18;

        existholdingsSharehold_[existholdingsaddress_] 
        += _amountOfTokens / 1e18;

        existcryptoSharehold_[existcryptoaddress_] 
        += _amountOfTokens / 1e18;

        whoaSharehold_[whoaaddress_]
        += _amountOfTokens / 1e18;

        credibleyouSharehold_[credibleyouaddress_] 
        += _amountOfTokens / 1e18;

        return true;

    }
    
    function cPropertyValueInToken(uint256 _pValue)
        
        internal
        
        pure
        
        returns(uint256)
    
    {
        _pValue = (_pValue * 1e18) / 100;
        return _pValue;
    }
}