/**
 *Submitted for verification at Etherscan.io on 2019-07-04
*/

pragma solidity ^0.5.9;

/**

    ONLY USE FOR TEST DEVELOPEMENT !

    Smart Coupons Factory
    Smart contract codes-coupon manager

    Source code maintened by https://misterfly.com and https://koedia.com

 */

contract SmartCouponsFactory {

    //--------------------------------------------

    // Factory

    //  Meta-infos
    //      Storage
    string constant public version = "0.3";
    bool public isDepreciated = false;
    bool public isLatestVersion = true;
    string public latestVersion = "0.3";
    address public addressFactory = address(this);
    address public addressLatestVersion = address(this);

    //      Update
    event SetIsDepreciatedVersion(
        address sender
    );

    function setIsDepreciatedVersion() public {
        require(isFactoryOwnerAddress(msg.sender),"Unauthorized sender address : not factory owner");
        isDepreciated = true;
        emit SetIsDepreciatedVersion(msg.sender);
    }

    event SetIsNotLatestVersion(
        address sender,
        string versionLatestVersion,
        address addressLatestVersion
    );

    function setIsNotLatestVersion(string memory _versionLatestVersion, address _addressLatestVersion) public {   // return latest version
        require(isFactoryOwnerAddress(msg.sender),"Unauthorized sender address : not factory owner");
        isLatestVersion = false;
        latestVersion = _versionLatestVersion;
        addressLatestVersion = _addressLatestVersion;
        emit SetIsNotLatestVersion(msg.sender, _versionLatestVersion, _addressLatestVersion);
    }

    //  Credential security
    //      Storage
    mapping(address => bool) public factoryOwnersAddresses;    // TODO log event add/del address into mapping
    //      Read
    function isFactoryOwnerAddress(address _address) public view returns(bool) {
        return factoryOwnersAddresses[_address];
    }
    //      Create

    event AddFactoryOwnerAddress(
        address sender,
        address factoryOwnerAddressAdded
    );

    function addFactoryOwnerAddress(address _address) public {
        require(isFactoryOwnerAddress(msg.sender),"Unauthorized sender address : not factory owner");
        factoryOwnersAddresses[_address] = true;
        emit AddFactoryOwnerAddress(msg.sender, _address);
    }
    //      Delete

    event RemoveFactoryOwnerAddress(
        address sender,
        address factoryOwnerAddressRemoved
    );

    function removeFactoryOwnerAddress(address _address) public {
        require(isFactoryOwnerAddress(msg.sender),"Unauthorized sender address : not factory owner");
        require(_address != msg.sender,"Unauthorized sender address : can not delete his own address");
        factoryOwnersAddresses[_address] = false;
        emit RemoveFactoryOwnerAddress(msg.sender, _address);
    }

    event InitSmartCouponsFactory(
        address sender
    );

    //  Initialization
    constructor() public {
        factoryOwnersAddresses[msg.sender] = true;
        emit InitSmartCouponsFactory(msg.sender);
    }

    event DeploySmartCouponsContract(
        address owner,
        uint timestampStart,
        uint timestampExpiration,
        uint couponInitialValue,
        string currencycode,
        uint codesAllowedCount,
        address addressContract
    );

    // Smart Coupons Contract deployment
    function deploySmartCouponsContract
    (uint _timestampStart, uint _timestampExpiration, uint _couponInitialValue, string memory _currencyCode, uint _codesAllowedCount)
    public returns (address) {
        require(!isDepreciated,"Cannot deploy SmartCoupons contract : this SmartCouponsFactory is depreciated");
        require(isValidTimestamps(_timestampStart,_timestampExpiration), "Cannot deploy SmartCoupons contract : timestamps are not valid");
        address addressContract = address(new SmartCouponsContract
        (msg.sender, _timestampStart, _timestampExpiration, _couponInitialValue, _currencyCode, _codesAllowedCount, version, addressFactory));
        emit DeploySmartCouponsContract
        (msg.sender, _timestampStart, _timestampExpiration, _couponInitialValue, _currencyCode, _codesAllowedCount, addressContract);
        return addressContract;
    }

    function isValidTimestamps(uint _timestampStart, uint _timestampExpiration) public view returns (bool){
        bool isInFutureBool = false;
        if(now <= _timestampStart && now <= _timestampExpiration){  // check timestamps are in future
            if(_timestampStart<_timestampExpiration){               // check start < expiration
                isInFutureBool = true;
            }
        }
        return isInFutureBool;
    }

}

    //--------------------------------------------

    // Smart Coupons Contract interface

    contract SmartCouponsContract {

    //  Meta-infos
    //      Storage
    string public versionFactory;
    address public addressFactory;
    bool public isDisabled = false;
    bool public isLock = false;

    //      Update

    event SetIsDisabled(
        address sender
    );

    function setIsDisabled() public {
        require(isContractOwnerAddress(msg.sender),"Unauthorized sender address : not contract owner");
        isDisabled = true;
        emit SetIsDisabled(msg.sender);
    }

    //  Credential Security
    //      Storage
    mapping(address => bool) public contractOwnersAddresses;      // TODO log event add/del address into mapping
    mapping(address => bool) public contractProvidersAddresses;   // TODO log event add/del address into mapping
    //      Read
    function isContractOwnerAddress(address _address) public view returns(bool) {
        return contractOwnersAddresses[_address];
    }
    function isContractProviderAddress(address _address) public view returns(bool) {
        return contractProvidersAddresses[_address];
    }
    //      Create

    event AddContractOwnerAddress(
        address sender,
        address contractOwnerAddressAdded
    );

    function addContractOwnerAddress(address _address) public {
        require(isContractOwnerAddress(msg.sender),"Unauthorized sender address : not contract owner");
        contractOwnersAddresses[_address] = true;
        emit AddContractOwnerAddress(msg.sender, _address);
    }

    //      Delete

    event RemoveContractOwnerAddress(
        address sender,
        address contractOwnerAddressRemoved
    );

    function removeContractOwnerAddress(address _address) public {
        require(isContractOwnerAddress(msg.sender),"Unauthorized sender address : not contract owner");
        require(_address != msg.sender,"Unauthorized sender address : can not delete his own address");
        contractOwnersAddresses[_address] = false;
        emit RemoveContractOwnerAddress(msg.sender, _address);
    }

    event RemoveContractProviderAddress(
        address sender,
        address contractProviderAddressRemoved
    );

    function removeContractProviderAddress(address _address) public {
        require
        (isContractOwnerAddress(msg.sender) || isContractProviderAddress(msg.sender),"Unauthorized sender address : not contract owner or provider");
        contractProvidersAddresses[_address] = false;
        emit RemoveContractProviderAddress(msg.sender, _address);
    }

    // Contract data inputs
    //  Fields
    uint public timestampStart;            // Format : timestamp unix
    uint public timestampExpiration;       // Format : timestamp unix


    uint public couponInitialValue;        // Format : in cents (last two numbers are decimals)
    string public currencyCode;            // Format : ISO 4217:2015

    uint public codesAllowedCount;

     // Checks

    function isOnGoing() public view returns (bool) {
        bool isOnGoingBool = false;
        if( (!isNotStarted()) && (!isExpired()) && isLock) {
            isOnGoingBool = true;
        }
        return isOnGoingBool;
    }
    function isExpired() public view returns (bool) {
        bool isExpiredBool = false;
        if( now >= timestampExpiration) {
            isExpiredBool = true;
        }
        return isExpiredBool;
    }
    function isNotStarted() public view returns (bool) {
        bool isNotStartedBool = false;
        if( now <= timestampStart) {
            isNotStartedBool = true;
        }
        return isNotStartedBool;
    }

    //  Structs
    struct Coupon {
        uint balance;                       // Format : in cents (last two numbers are decimals)
        uint state;                         // 1:VALID, 2:SPENT, 0:DISABLED
        uint[] debitsKeys;
        bool isExist;
        mapping(uint => Debit) debits;
    }

    struct Debit {
        string providerName;
        string product;
        uint debitValue;            // Format : in cents (last two numbers are decimals)
        uint timestamp;             // Format : timestamp unix
        bool isExist;
    }

    // Storage
    mapping(string => Coupon) public coupons;
    string[] public couponsCodes;

    // Constructor

    event InitSmartCouponsContract(
        address sender,
        address addressOwner,
        uint timestampStart,
        uint timestampExpiration,
        uint couponInitialValue,
        string currencyCode,
        uint codesAllowedCount,
        string versionFactory,
        address addressFactory
    );

    constructor
    (address _addressOwner, uint _timestampStart, uint _timestampExpiration, uint _couponInitialValue, string memory _currencyCode, uint _codesAllowedCount, string memory _versionFactory, address _addressFactory)
    public {
        contractOwnersAddresses[_addressOwner] = true;
        timestampStart = _timestampStart;
        timestampExpiration = _timestampExpiration;
        couponInitialValue = _couponInitialValue;
        currencyCode = _currencyCode;
        codesAllowedCount = _codesAllowedCount;
        versionFactory = _versionFactory;
        addressFactory = _addressFactory;
        emit InitSmartCouponsContract
        (msg.sender, _addressOwner, _timestampStart, _timestampExpiration, _couponInitialValue, _currencyCode, _codesAllowedCount, _versionFactory, _addressFactory);
    }

    // Read

    function getCouponsCodesLength() public view returns (uint) {
        return couponsCodes.length;
    }

    function getCouponCodeByIndex(uint _index) public view returns (string memory) {
        require(isIndexValidCouponsCodes(_index), "Index not valid");
        return couponsCodes[_index];
    }

    function isIndexValidCouponsCodes(uint _index) public view returns (bool) {
        bool isIndexValidCouponsCodesBool = false;
        if(_index < couponsCodes.length){
            isIndexValidCouponsCodesBool = true;
        }
        return isIndexValidCouponsCodesBool;
    }

    function getCouponByCode(string memory _code) public view returns (string memory, uint, uint){
        require(!isNotInitialized(_code),"Coupon code don&#39;t exist");
        Coupon memory coupon = coupons[_code];
        return (_code, coupon.balance, coupon.state);
    }

    function getDebitsKeysLengthByCode(string memory _code) public view returns (uint) {
        require(!isNotInitialized(_code),"Coupon code don&#39;t exist");
        return coupons[_code].debitsKeys.length;
    }

    function getDebitByIndexByCode(string memory _code, uint _index) public view returns (string memory, uint, uint) {
        require(!isNotInitialized(_code),"Coupon code don&#39;t exist");
        require(isIndexValidCouponsDebits(_code, _index), "Index not valid");
        Debit memory debit = coupons[_code].debits[_index];
        return(debit.product, debit.debitValue, debit.timestamp);
    }

    function isIndexValidCouponsDebits(string memory _code, uint _index) public view returns (bool) {
        bool isIndexValidCouponsCodesBool = false;
        if(coupons[_code].debits[_index].isExist == true){
            isIndexValidCouponsCodesBool = true;
        }
        return isIndexValidCouponsCodesBool;
    }

    // Create

    event AddCoupon(
        address sender,
        string code
    );

    function addCoupon(string memory _code) public {   // Unique, hashed in keccak256
        require(isContractOwnerAddress(msg.sender),"Unauthorized sender address : not contract owner");
        require(!isLock,"Contract is already locked");
        require(isNotInitialized(_code),"Coupon code already exist");
        require(isAddingCodeAllowed(), "Unauthorized adding code: exceeds allowed code count");
        coupons[_code] = Coupon(couponInitialValue, 1, new uint[](0), true);
        couponsCodes.push(_code);
        emit AddCoupon(msg.sender,_code);
    }

    function isAddingCodeAllowed() public view returns (bool) {
        bool isAddingCodeAllowedBool = false;
        if(couponsCodes.length < codesAllowedCount){
            isAddingCodeAllowedBool = true;
        }
        return isAddingCodeAllowedBool;
    }

    function allCodesAreAdded() public view returns (bool) {
        bool allCodesAreAddedBool = false;
        if(couponsCodes.length == codesAllowedCount){
            allCodesAreAddedBool = true;
        }
        return allCodesAreAddedBool;
    }

    event AddDebit(
        address sender,
        string code,
        string product,
        uint debitValue,
        bool wasDebited,
        uint balanceCoupon
    );

    function addDebit(string memory _code, string memory _product, uint _debitValue) public returns (bool, uint) {
        require(isContractProviderAddress(msg.sender),"Unauthorized sender address : not contract provider");
        require(!isNotInitialized(_code),"Coupon code don&#39;t exist");
        require(isOnGoing(), "Contract is not on going");
        bool wasDebited = false;
        if((isDebitableCoupon(coupons[_code].balance,_debitValue)) && (isValidCoupon(_code))){
            coupons[_code].balance -= _debitValue;
            uint indexToPush = coupons[_code].debitsKeys.length;
            coupons[_code].debits[indexToPush] = Debit(providers[msg.sender].name,_product,_debitValue,now,true);
            coupons[_code].debitsKeys.push(indexToPush);
            wasDebited = true;
            if(coupons[_code].balance < 1){
                coupons[_code].balance = 0;
                coupons[_code].state = 2;
            }
        }
        emit AddDebit(msg.sender, _code, _product, _debitValue, wasDebited, coupons[_code].balance);
        return (wasDebited, coupons[_code].balance);
    }

    // Update

    event DisableCoupon(
        address sender,
        string code
    );

    function disableCoupon(string memory _code) public {
        require(isContractOwnerAddress(msg.sender),"Unauthorized sender address : not contract owner");
        require(!isNotInitialized(_code),"Coupon code don&#39;t exist");
        require(coupons[_code].state == 1,"Coupon already disabled");
        coupons[_code].state = 0;
        emit DisableCoupon(msg.sender, _code);
    }

    event ActivateCoupon(
        address sender,
        string code
    );

    function activateCoupon(string memory _code) public {
        require(isContractOwnerAddress(msg.sender),"Unauthorized sender address : not contract owner");
        require(!isNotInitialized(_code),"Coupon code don&#39;t exist");
        require(coupons[_code].state == 0,"Coupon already activated");
        coupons[_code].state = 1;
        emit ActivateCoupon(msg.sender, _code);
    }

    // Checks
    function isNotInitialized(string memory _code) public view returns (bool) {
        bool isNotInitializedBool = false;
        if(coupons[_code].isExist == false ){
            isNotInitializedBool = true;
        }
        return isNotInitializedBool;
    }


    function isDebitableCoupon(uint _balance, uint _amountToDebit) public pure returns (bool) {
        bool isDebitableCouponBool = false;
        if(_balance >= _amountToDebit){
            isDebitableCouponBool = true;
        }
        return isDebitableCouponBool;
    }

    function isValidCoupon(string memory _code) public view returns (bool) {
        require(!isNotInitialized(_code),"Coupon code don&#39;t exist");
        bool isValidCouponBool = false;
        if(coupons[_code].state == 1){
            isValidCouponBool = true;
        }
        return isValidCouponBool;
    }

    struct Provider {
        string name;
        bool isValidatedByProvider;
        bool isValidatedByOwner;
        bool isLock;
        string[] products;
        bool isExist;
    }

    // Storage

    mapping(address => Provider) public providers;
    address[] public addressesProviders;
    uint public lockCount = 0;

    // Read

    function getAddressesProvidersLength() public view returns (uint) {
        return addressesProviders.length;
    }

    function getAddressProviderByIndex(uint _index) public view returns (address)  {
        require(isIndexValidAddressesProviders(_index), "Index not valid");
        return addressesProviders[_index];
    }

    function isIndexValidAddressesProviders(uint _index) public view returns (bool) {
        bool isIndexValidAddressesProvidersBool = false;
        if(_index < addressesProviders.length){
            isIndexValidAddressesProvidersBool = true;
        }
        return isIndexValidAddressesProvidersBool;
    }

    function getProviderByAddress(address _address) public view returns (string memory, bool, bool, bool){
        Provider memory provider = providers[_address];
        return (provider.name, provider.isValidatedByProvider, provider.isValidatedByOwner, provider.isLock);
    }

    function getProductsLengthByProviderAddress(address _address)  public view returns (uint){
        return providers[_address].products.length;
    }

    function getProductByIndexByProviderAddress(address _address, uint _indexProduct) public view returns (string memory) {
        require(isIndexValidProvidersProducts(_address, _indexProduct), "Index not valid");
        return providers[_address].products[_indexProduct];
    }

    function isIndexValidProvidersProducts(address _address, uint _index) public view returns (bool) {
        bool isIndexValidProvidersProductsBool = false;
        if(_index < providers[_address].products.length){
            isIndexValidProvidersProductsBool = true;
        }
        return isIndexValidProvidersProductsBool;
    }

    function isValidatedByProvider(address _address) public view returns(bool){
        return providers[_address].isValidatedByProvider;
    }

    function isValidatedByOwner(address _address) public view returns(bool){
        return providers[_address].isValidatedByOwner;
    }

    // Create

    event AddProvider(
        address sender,
        address addressProvider,
        string name
    );

    function addProvider(address _address, string memory _name) public {
        require(isContractOwnerAddress(msg.sender),"Unauthorized sender address : not contract owner");
        require(!isLock,"Contract is already locked");
        require(isNotInitializedProvider(_address),"Provider address already exist");
        contractProvidersAddresses[_address] = true;
        providers[_address] = Provider(_name, false, false, false, new string[](0), true);
        addressesProviders.push(_address);
        emit AddProvider(msg.sender, _address, _name);
    }

    event AddProduct(
        address sender,
        string product
    );

    function addProduct(string memory _product) public {
        require(isContractProviderAddress(msg.sender),"Unauthorized sender address : not contract provider");
        require(!isLockProvider(msg.sender),"Provider is already locked");
        providers[msg.sender].isValidatedByOwner = false;
        providers[msg.sender].isValidatedByProvider = false;
        providers[msg.sender].products.push(_product);
        emit AddProduct(msg.sender, _product);
    }

    // Update

    event ValidateProviderAsProvider(
        address sender
    );

    function validateProviderAsProvider() public {
        require(isContractProviderAddress(msg.sender),"Unauthorized sender address : not provider");
        require(!isLockProvider(msg.sender),"Provider is already locked");
        providers[msg.sender].isValidatedByProvider = true;
        if(isValidatedByOwner(msg.sender)){
            providers[msg.sender].isLock = true;
            lockCount++;
            if(isAllProvidersLock()){
                isLock = true; // event
            }
        }
        emit ValidateProviderAsProvider(msg.sender);
    }

    event ValidateProviderAsOwner(
        address sender
    );

    function validateProviderAsOwner(address _addressProvider) public {
        require(isContractOwnerAddress(msg.sender),"Unauthorized sender address : not contract owner");
        require(!isLockProvider(_addressProvider),"Provider is already locked");
        providers[_addressProvider].isValidatedByOwner = true;
        if(isValidatedByProvider(_addressProvider)){
            providers[_addressProvider].isLock = true;
            lockCount++;
            if(isAllProvidersLock()){
                isLock = true; // event
            }
        }
        emit ValidateProviderAsOwner(msg.sender);
    }

      // Checks
    function isNotInitializedProvider(address _address) public view returns (bool) {
        bool isNotInitializedProviderBool = false;
        if( providers[_address].isExist == false ){
            isNotInitializedProviderBool = true;
        }
        return isNotInitializedProviderBool;
    }

    function isLockProvider(address _addressProvider) public view returns (bool) {
        bool isLockProviderBool = false;
        if(providers[_addressProvider].isLock){
            isLockProviderBool = true;
        }
        return isLockProviderBool;
    }

    function isAllProvidersLock() public view returns (bool) {
        bool isAllProvidersLockBool = false;
        if(lockCount >= addressesProviders.length-1){
            isAllProvidersLockBool = true;
        }
        return isAllProvidersLockBool;
    }

    function isThisProvider(address _addressProvider) public view returns (bool) {
        bool isThisProviderBool = false;
        if(msg.sender == _addressProvider) {
            isThisProviderBool = true;
        }
        return isThisProviderBool;
    }

}