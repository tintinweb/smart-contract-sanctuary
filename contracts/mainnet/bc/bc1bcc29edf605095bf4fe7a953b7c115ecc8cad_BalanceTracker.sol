/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity ^0.4.25;



/*
 * Hubii Nahmii
 *
 * Compliant with the Hubii Nahmii specification v0.12.
 *
 * Copyright (C) 2017-2018 Hubii AS
 */


/**
 * @title Modifiable
 * @notice A contract with basic modifiers
 */
contract Modifiable {
    //
    // Modifiers
    // -----------------------------------------------------------------------------------------------------------------
    modifier notNullAddress(address _address) {
        require(_address != address(0));
        _;
    }

    modifier notThisAddress(address _address) {
        require(_address != address(this));
        _;
    }

    modifier notNullOrThisAddress(address _address) {
        require(_address != address(0));
        require(_address != address(this));
        _;
    }

    modifier notSameAddresses(address _address1, address _address2) {
        if (_address1 != _address2)
            _;
    }
}

/*
 * Hubii Nahmii
 *
 * Compliant with the Hubii Nahmii specification v0.12.
 *
 * Copyright (C) 2017-2018 Hubii AS
 */



/**
 * @title SelfDestructible
 * @notice Contract that allows for self-destruction
 */
contract SelfDestructible {
    //
    // Variables
    // -----------------------------------------------------------------------------------------------------------------
    bool public selfDestructionDisabled;

    //
    // Events
    // -----------------------------------------------------------------------------------------------------------------
    event SelfDestructionDisabledEvent(address wallet);
    event TriggerSelfDestructionEvent(address wallet);

    //
    // Functions
    // -----------------------------------------------------------------------------------------------------------------
    /// @notice Get the address of the destructor role
    function destructor()
    public
    view
    returns (address);

    /// @notice Disable self-destruction of this contract
    /// @dev This operation can not be undone
    function disableSelfDestruction()
    public
    {
        // Require that sender is the assigned destructor
        require(destructor() == msg.sender);

        // Disable self-destruction
        selfDestructionDisabled = true;

        // Emit event
        emit SelfDestructionDisabledEvent(msg.sender);
    }

    /// @notice Destroy this contract
    function triggerSelfDestruction()
    public
    {
        // Require that sender is the assigned destructor
        require(destructor() == msg.sender);

        // Require that self-destruction has not been disabled
        require(!selfDestructionDisabled);

        // Emit event
        emit TriggerSelfDestructionEvent(msg.sender);

        // Self-destruct and reward destructor
        selfdestruct(msg.sender);
    }
}

/*
 * Hubii Nahmii
 *
 * Compliant with the Hubii Nahmii specification v0.12.
 *
 * Copyright (C) 2017-2018 Hubii AS
 */






/**
 * @title Ownable
 * @notice A modifiable that has ownership roles
 */
contract Ownable is Modifiable, SelfDestructible {
    //
    // Variables
    // -----------------------------------------------------------------------------------------------------------------
    address public deployer;
    address public operator;

    //
    // Events
    // -----------------------------------------------------------------------------------------------------------------
    event SetDeployerEvent(address oldDeployer, address newDeployer);
    event SetOperatorEvent(address oldOperator, address newOperator);

    //
    // Constructor
    // -----------------------------------------------------------------------------------------------------------------
    constructor(address _deployer) internal notNullOrThisAddress(_deployer) {
        deployer = _deployer;
        operator = _deployer;
    }

    //
    // Functions
    // -----------------------------------------------------------------------------------------------------------------
    /// @notice Return the address that is able to initiate self-destruction
    function destructor()
    public
    view
    returns (address)
    {
        return deployer;
    }

    /// @notice Set the deployer of this contract
    /// @param newDeployer The address of the new deployer
    function setDeployer(address newDeployer)
    public
    onlyDeployer
    notNullOrThisAddress(newDeployer)
    {
        if (newDeployer != deployer) {
            // Set new deployer
            address oldDeployer = deployer;
            deployer = newDeployer;

            // Emit event
            emit SetDeployerEvent(oldDeployer, newDeployer);
        }
    }

    /// @notice Set the operator of this contract
    /// @param newOperator The address of the new operator
    function setOperator(address newOperator)
    public
    onlyOperator
    notNullOrThisAddress(newOperator)
    {
        if (newOperator != operator) {
            // Set new operator
            address oldOperator = operator;
            operator = newOperator;

            // Emit event
            emit SetOperatorEvent(oldOperator, newOperator);
        }
    }

    /// @notice Gauge whether message sender is deployer or not
    /// @return true if msg.sender is deployer, else false
    function isDeployer()
    internal
    view
    returns (bool)
    {
        return msg.sender == deployer;
    }

    /// @notice Gauge whether message sender is operator or not
    /// @return true if msg.sender is operator, else false
    function isOperator()
    internal
    view
    returns (bool)
    {
        return msg.sender == operator;
    }

    /// @notice Gauge whether message sender is operator or deployer on the one hand, or none of these on these on
    /// on the other hand
    /// @return true if msg.sender is operator, else false
    function isDeployerOrOperator()
    internal
    view
    returns (bool)
    {
        return isDeployer() || isOperator();
    }

    // Modifiers
    // -----------------------------------------------------------------------------------------------------------------
    modifier onlyDeployer() {
        require(isDeployer());
        _;
    }

    modifier notDeployer() {
        require(!isDeployer());
        _;
    }

    modifier onlyOperator() {
        require(isOperator());
        _;
    }

    modifier notOperator() {
        require(!isOperator());
        _;
    }

    modifier onlyDeployerOrOperator() {
        require(isDeployerOrOperator());
        _;
    }

    modifier notDeployerOrOperator() {
        require(!isDeployerOrOperator());
        _;
    }
}

/*
 * Hubii Nahmii
 *
 * Compliant with the Hubii Nahmii specification v0.12.
 *
 * Copyright (C) 2017-2018 Hubii AS
 */





/**
 * @title Servable
 * @notice An ownable that contains registered services and their actions
 */
contract Servable is Ownable {
    //
    // Types
    // -----------------------------------------------------------------------------------------------------------------
    struct ServiceInfo {
        bool registered;
        uint256 activationTimestamp;
        mapping(bytes32 => bool) actionsEnabledMap;
        bytes32[] actionsList;
    }

    //
    // Variables
    // -----------------------------------------------------------------------------------------------------------------
    mapping(address => ServiceInfo) internal registeredServicesMap;
    uint256 public serviceActivationTimeout;

    //
    // Events
    // -----------------------------------------------------------------------------------------------------------------
    event ServiceActivationTimeoutEvent(uint256 timeoutInSeconds);
    event RegisterServiceEvent(address service);
    event RegisterServiceDeferredEvent(address service, uint256 timeout);
    event DeregisterServiceEvent(address service);
    event EnableServiceActionEvent(address service, string action);
    event DisableServiceActionEvent(address service, string action);

    //
    // Functions
    // -----------------------------------------------------------------------------------------------------------------
    /// @notice Set the service activation timeout
    /// @param timeoutInSeconds The set timeout in unit of seconds
    function setServiceActivationTimeout(uint256 timeoutInSeconds)
    public
    onlyDeployer
    {
        serviceActivationTimeout = timeoutInSeconds;

        // Emit event
        emit ServiceActivationTimeoutEvent(timeoutInSeconds);
    }

    /// @notice Register a service contract whose activation is immediate
    /// @param service The address of the service contract to be registered
    function registerService(address service)
    public
    onlyDeployer
    notNullOrThisAddress(service)
    {
        _registerService(service, 0);

        // Emit event
        emit RegisterServiceEvent(service);
    }

    /// @notice Register a service contract whose activation is deferred by the service activation timeout
    /// @param service The address of the service contract to be registered
    function registerServiceDeferred(address service)
    public
    onlyDeployer
    notNullOrThisAddress(service)
    {
        _registerService(service, serviceActivationTimeout);

        // Emit event
        emit RegisterServiceDeferredEvent(service, serviceActivationTimeout);
    }

    /// @notice Deregister a service contract
    /// @param service The address of the service contract to be deregistered
    function deregisterService(address service)
    public
    onlyDeployer
    notNullOrThisAddress(service)
    {
        require(registeredServicesMap[service].registered);

        registeredServicesMap[service].registered = false;

        // Emit event
        emit DeregisterServiceEvent(service);
    }

    /// @notice Enable a named action in an already registered service contract
    /// @param service The address of the registered service contract
    /// @param action The name of the action to be enabled
    function enableServiceAction(address service, string action)
    public
    onlyDeployer
    notNullOrThisAddress(service)
    {
        require(registeredServicesMap[service].registered);

        bytes32 actionHash = hashString(action);

        require(!registeredServicesMap[service].actionsEnabledMap[actionHash]);

        registeredServicesMap[service].actionsEnabledMap[actionHash] = true;
        registeredServicesMap[service].actionsList.push(actionHash);

        // Emit event
        emit EnableServiceActionEvent(service, action);
    }

    /// @notice Enable a named action in a service contract
    /// @param service The address of the service contract
    /// @param action The name of the action to be disabled
    function disableServiceAction(address service, string action)
    public
    onlyDeployer
    notNullOrThisAddress(service)
    {
        bytes32 actionHash = hashString(action);

        require(registeredServicesMap[service].actionsEnabledMap[actionHash]);

        registeredServicesMap[service].actionsEnabledMap[actionHash] = false;

        // Emit event
        emit DisableServiceActionEvent(service, action);
    }

    /// @notice Gauge whether a service contract is registered
    /// @param service The address of the service contract
    /// @return true if service is registered, else false
    function isRegisteredService(address service)
    public
    view
    returns (bool)
    {
        return registeredServicesMap[service].registered;
    }

    /// @notice Gauge whether a service contract is registered and active
    /// @param service The address of the service contract
    /// @return true if service is registered and activate, else false
    function isRegisteredActiveService(address service)
    public
    view
    returns (bool)
    {
        return isRegisteredService(service) && block.timestamp >= registeredServicesMap[service].activationTimestamp;
    }

    /// @notice Gauge whether a service contract action is enabled which implies also registered and active
    /// @param service The address of the service contract
    /// @param action The name of action
    function isEnabledServiceAction(address service, string action)
    public
    view
    returns (bool)
    {
        bytes32 actionHash = hashString(action);
        return isRegisteredActiveService(service) && registeredServicesMap[service].actionsEnabledMap[actionHash];
    }

    //
    // Internal functions
    // -----------------------------------------------------------------------------------------------------------------
    function hashString(string _string)
    internal
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(_string));
    }

    //
    // Private functions
    // -----------------------------------------------------------------------------------------------------------------
    function _registerService(address service, uint256 timeout)
    private
    {
        if (!registeredServicesMap[service].registered) {
            registeredServicesMap[service].registered = true;
            registeredServicesMap[service].activationTimestamp = block.timestamp + timeout;
        }
    }

    //
    // Modifiers
    // -----------------------------------------------------------------------------------------------------------------
    modifier onlyActiveService() {
        require(isRegisteredActiveService(msg.sender));
        _;
    }

    modifier onlyEnabledServiceAction(string action) {
        require(isEnabledServiceAction(msg.sender, action));
        _;
    }
}

/*
 * Hubii Nahmii
 *
 * Compliant with the Hubii Nahmii specification v0.12.
 *
 * Copyright (C) 2017-2018 Hubii AS based on Open-Zeppelin&#39;s SafeMath library
 */



/**
 * @title     SafeMathIntLib
 * @dev       Math operations with safety checks that throw on error
 */
library SafeMathIntLib {
    int256 constant INT256_MIN = int256((uint256(1) << 255));
    int256 constant INT256_MAX = int256(~((uint256(1) << 255)));

    //
    //Functions below accept positive and negative integers and result must not overflow.
    //
    function div(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        require(a != INT256_MIN || b != - 1);
        return a / b;
    }

    function mul(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        require(a != - 1 || b != INT256_MIN);
        // overflow
        require(b != - 1 || a != INT256_MIN);
        // overflow
        int256 c = a * b;
        require((b == 0) || (c / b == a));
        return c;
    }

    function sub(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));
        return a - b;
    }

    function add(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    //
    //Functions below only accept positive integers and result must be greater or equal to zero too.
    //
    function div_nn(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        require(a >= 0 && b > 0);
        return a / b;
    }

    function mul_nn(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        require(a >= 0 && b >= 0);
        int256 c = a * b;
        require(a == 0 || c / a == b);
        require(c >= 0);
        return c;
    }

    function sub_nn(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        require(a >= 0 && b >= 0 && b <= a);
        return a - b;
    }

    function add_nn(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        require(a >= 0 && b >= 0);
        int256 c = a + b;
        require(c >= a);
        return c;
    }

    //
    //Conversion and validation functions.
    //
    function abs(int256 a)
    public
    pure
    returns (int256)
    {
        return a < 0 ? neg(a) : a;
    }

    function neg(int256 a)
    public
    pure
    returns (int256)
    {
        return mul(a, - 1);
    }

    function toNonZeroInt256(uint256 a)
    public
    pure
    returns (int256)
    {
        require(a > 0 && a < (uint256(1) << 255));
        return int256(a);
    }

    function toInt256(uint256 a)
    public
    pure
    returns (int256)
    {
        require(a >= 0 && a < (uint256(1) << 255));
        return int256(a);
    }

    function toUInt256(int256 a)
    public
    pure
    returns (uint256)
    {
        require(a >= 0);
        return uint256(a);
    }

    function isNonZeroPositiveInt256(int256 a)
    public
    pure
    returns (bool)
    {
        return (a > 0);
    }

    function isPositiveInt256(int256 a)
    public
    pure
    returns (bool)
    {
        return (a >= 0);
    }

    function isNonZeroNegativeInt256(int256 a)
    public
    pure
    returns (bool)
    {
        return (a < 0);
    }

    function isNegativeInt256(int256 a)
    public
    pure
    returns (bool)
    {
        return (a <= 0);
    }

    //
    //Clamping functions.
    //
    function clamp(int256 a, int256 min, int256 max)
    public
    pure
    returns (int256)
    {
        if (a < min)
            return min;
        return (a > max) ? max : a;
    }

    function clampMin(int256 a, int256 min)
    public
    pure
    returns (int256)
    {
        return (a < min) ? min : a;
    }

    function clampMax(int256 a, int256 max)
    public
    pure
    returns (int256)
    {
        return (a > max) ? max : a;
    }
}

/*
 * Hubii Nahmii
 *
 * Compliant with the Hubii Nahmii specification v0.12.
 *
 * Copyright (C) 2017-2018 Hubii AS based on Open-Zeppelin&#39;s SafeMath library
 */



/**
 * @title     SafeMathUintLib
 * @dev       Math operations with safety checks that throw on error
 */
library SafeMathUintLib {
    function mul(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    //
    //Clamping functions.
    //
    function clamp(uint256 a, uint256 min, uint256 max)
    public
    pure
    returns (uint256)
    {
        return (a > max) ? max : ((a < min) ? min : a);
    }

    function clampMin(uint256 a, uint256 min)
    public
    pure
    returns (uint256)
    {
        return (a < min) ? min : a;
    }

    function clampMax(uint256 a, uint256 max)
    public
    pure
    returns (uint256)
    {
        return (a > max) ? max : a;
    }
}

/*
 * Hubii Nahmii
 *
 * Compliant with the Hubii Nahmii specification v0.12.
 *
 * Copyright (C) 2017-2018 Hubii AS
 */




/**
 * @title     MonetaryTypesLib
 * @dev       Monetary data types
 */
library MonetaryTypesLib {
    //
    // Structures
    // -----------------------------------------------------------------------------------------------------------------
    struct Currency {
        address ct;
        uint256 id;
    }

    struct Figure {
        int256 amount;
        Currency currency;
    }
}

/*
 * Hubii Nahmii
 *
 * Compliant with the Hubii Nahmii specification v0.12.
 *
 * Copyright (C) 2017-2018 Hubii AS
 */







library CurrenciesLib {
    using SafeMathUintLib for uint256;

    //
    // Structures
    // -----------------------------------------------------------------------------------------------------------------
    struct Currencies {
        MonetaryTypesLib.Currency[] currencies;
        mapping(address => mapping(uint256 => uint256)) indexByCurrency;
    }

    //
    // Functions
    // -----------------------------------------------------------------------------------------------------------------
    function add(Currencies storage self, address currencyCt, uint256 currencyId)
    internal
    {
        // Index is 1-based
        if (0 == self.indexByCurrency[currencyCt][currencyId]) {
            self.currencies.push(MonetaryTypesLib.Currency(currencyCt, currencyId));
            self.indexByCurrency[currencyCt][currencyId] = self.currencies.length;
        }
    }

    function removeByCurrency(Currencies storage self, address currencyCt, uint256 currencyId)
    internal
    {
        // Index is 1-based
        uint256 index = self.indexByCurrency[currencyCt][currencyId];
        if (0 < index)
            removeByIndex(self, index - 1);
    }

    function removeByIndex(Currencies storage self, uint256 index)
    internal
    {
        require(index < self.currencies.length);

        address currencyCt = self.currencies[index].ct;
        uint256 currencyId = self.currencies[index].id;

        if (index < self.currencies.length - 1) {
            self.currencies[index] = self.currencies[self.currencies.length - 1];
            self.indexByCurrency[self.currencies[index].ct][self.currencies[index].id] = index + 1;
        }
        self.currencies.length--;
        self.indexByCurrency[currencyCt][currencyId] = 0;
    }

    function count(Currencies storage self)
    internal
    view
    returns (uint256)
    {
        return self.currencies.length;
    }

    function has(Currencies storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (bool)
    {
        return 0 != self.indexByCurrency[currencyCt][currencyId];
    }

    function getByIndex(Currencies storage self, uint256 index)
    internal
    view
    returns (MonetaryTypesLib.Currency)
    {
        require(index < self.currencies.length);
        return self.currencies[index];
    }

    function getByIndices(Currencies storage self, uint256 low, uint256 up)
    internal
    view
    returns (MonetaryTypesLib.Currency[])
    {
        require(0 < self.currencies.length);
        require(low <= up);

        up = up.clampMax(self.currencies.length - 1);
        MonetaryTypesLib.Currency[] memory _currencies = new MonetaryTypesLib.Currency[](up - low + 1);
        for (uint256 i = low; i <= up; i++)
            _currencies[i - low] = self.currencies[i];

        return _currencies;
    }
}

/*
 * Hubii Nahmii
 *
 * Compliant with the Hubii Nahmii specification v0.12.
 *
 * Copyright (C) 2017-2018 Hubii AS
 */







library FungibleBalanceLib {
    using SafeMathIntLib for int256;
    using SafeMathUintLib for uint256;
    using CurrenciesLib for CurrenciesLib.Currencies;

    //
    // Structures
    // -----------------------------------------------------------------------------------------------------------------
    struct Record {
        int256 amount;
        uint256 blockNumber;
    }

    struct Balance {
        mapping(address => mapping(uint256 => int256)) amountByCurrency;
        mapping(address => mapping(uint256 => Record[])) recordsByCurrency;

        CurrenciesLib.Currencies inUseCurrencies;
        CurrenciesLib.Currencies everUsedCurrencies;
    }

    //
    // Functions
    // -----------------------------------------------------------------------------------------------------------------
    function get(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (int256)
    {
        return self.amountByCurrency[currencyCt][currencyId];
    }

    function getByBlockNumber(Balance storage self, address currencyCt, uint256 currencyId, uint256 blockNumber)
    internal
    view
    returns (int256)
    {
        (int256 amount,) = recordByBlockNumber(self, currencyCt, currencyId, blockNumber);
        return amount;
    }

    function set(Balance storage self, int256 amount, address currencyCt, uint256 currencyId)
    internal
    {
        self.amountByCurrency[currencyCt][currencyId] = amount;

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.amountByCurrency[currencyCt][currencyId], block.number)
        );

        updateCurrencies(self, currencyCt, currencyId);
    }

    function add(Balance storage self, int256 amount, address currencyCt, uint256 currencyId)
    internal
    {
        self.amountByCurrency[currencyCt][currencyId] = self.amountByCurrency[currencyCt][currencyId].add(amount);

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.amountByCurrency[currencyCt][currencyId], block.number)
        );

        updateCurrencies(self, currencyCt, currencyId);
    }

    function sub(Balance storage self, int256 amount, address currencyCt, uint256 currencyId)
    internal
    {
        self.amountByCurrency[currencyCt][currencyId] = self.amountByCurrency[currencyCt][currencyId].sub(amount);

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.amountByCurrency[currencyCt][currencyId], block.number)
        );

        updateCurrencies(self, currencyCt, currencyId);
    }

    function transfer(Balance storage _from, Balance storage _to, int256 amount,
        address currencyCt, uint256 currencyId)
    internal
    {
        sub(_from, amount, currencyCt, currencyId);
        add(_to, amount, currencyCt, currencyId);
    }

    function add_nn(Balance storage self, int256 amount, address currencyCt, uint256 currencyId)
    internal
    {
        self.amountByCurrency[currencyCt][currencyId] = self.amountByCurrency[currencyCt][currencyId].add_nn(amount);

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.amountByCurrency[currencyCt][currencyId], block.number)
        );

        updateCurrencies(self, currencyCt, currencyId);
    }

    function sub_nn(Balance storage self, int256 amount, address currencyCt, uint256 currencyId)
    internal
    {
        self.amountByCurrency[currencyCt][currencyId] = self.amountByCurrency[currencyCt][currencyId].sub_nn(amount);

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.amountByCurrency[currencyCt][currencyId], block.number)
        );

        updateCurrencies(self, currencyCt, currencyId);
    }

    function transfer_nn(Balance storage _from, Balance storage _to, int256 amount,
        address currencyCt, uint256 currencyId)
    internal
    {
        sub_nn(_from, amount, currencyCt, currencyId);
        add_nn(_to, amount, currencyCt, currencyId);
    }

    function recordsCount(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (uint256)
    {
        return self.recordsByCurrency[currencyCt][currencyId].length;
    }

    function recordByBlockNumber(Balance storage self, address currencyCt, uint256 currencyId, uint256 blockNumber)
    internal
    view
    returns (int256, uint256)
    {
        uint256 index = indexByBlockNumber(self, currencyCt, currencyId, blockNumber);
        return 0 < index ? recordByIndex(self, currencyCt, currencyId, index - 1) : (0, 0);
    }

    function recordByIndex(Balance storage self, address currencyCt, uint256 currencyId, uint256 index)
    internal
    view
    returns (int256, uint256)
    {
        if (0 == self.recordsByCurrency[currencyCt][currencyId].length)
            return (0, 0);

        index = index.clampMax(self.recordsByCurrency[currencyCt][currencyId].length - 1);
        Record storage record = self.recordsByCurrency[currencyCt][currencyId][index];
        return (record.amount, record.blockNumber);
    }

    function lastRecord(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (int256, uint256)
    {
        if (0 == self.recordsByCurrency[currencyCt][currencyId].length)
            return (0, 0);

        Record storage record = self.recordsByCurrency[currencyCt][currencyId][self.recordsByCurrency[currencyCt][currencyId].length - 1];
        return (record.amount, record.blockNumber);
    }

    function hasInUseCurrency(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (bool)
    {
        return self.inUseCurrencies.has(currencyCt, currencyId);
    }

    function hasEverUsedCurrency(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (bool)
    {
        return self.everUsedCurrencies.has(currencyCt, currencyId);
    }

    function updateCurrencies(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    {
        if (0 == self.amountByCurrency[currencyCt][currencyId] && self.inUseCurrencies.has(currencyCt, currencyId))
            self.inUseCurrencies.removeByCurrency(currencyCt, currencyId);
        else if (!self.inUseCurrencies.has(currencyCt, currencyId)) {
            self.inUseCurrencies.add(currencyCt, currencyId);
            self.everUsedCurrencies.add(currencyCt, currencyId);
        }
    }

    function indexByBlockNumber(Balance storage self, address currencyCt, uint256 currencyId, uint256 blockNumber)
    internal
    view
    returns (uint256)
    {
        if (0 == self.recordsByCurrency[currencyCt][currencyId].length)
            return 0;
        for (uint256 i = self.recordsByCurrency[currencyCt][currencyId].length; i > 0; i--)
            if (self.recordsByCurrency[currencyCt][currencyId][i - 1].blockNumber <= blockNumber)
                return i;
        return 0;
    }
}

/*
 * Hubii Nahmii
 *
 * Compliant with the Hubii Nahmii specification v0.12.
 *
 * Copyright (C) 2017-2018 Hubii AS
 */







library NonFungibleBalanceLib {
    using SafeMathIntLib for int256;
    using SafeMathUintLib for uint256;
    using CurrenciesLib for CurrenciesLib.Currencies;

    //
    // Structures
    // -----------------------------------------------------------------------------------------------------------------
    struct Record {
        int256[] ids;
        uint256 blockNumber;
    }

    struct Balance {
        mapping(address => mapping(uint256 => int256[])) idsByCurrency;
        mapping(address => mapping(uint256 => mapping(int256 => uint256))) idIndexById;
        mapping(address => mapping(uint256 => Record[])) recordsByCurrency;

        CurrenciesLib.Currencies inUseCurrencies;
        CurrenciesLib.Currencies everUsedCurrencies;
    }

    //
    // Functions
    // -----------------------------------------------------------------------------------------------------------------
    function get(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (int256[])
    {
        return self.idsByCurrency[currencyCt][currencyId];
    }

    function getByIndices(Balance storage self, address currencyCt, uint256 currencyId, uint256 indexLow, uint256 indexUp)
    internal
    view
    returns (int256[])
    {
        if (0 == self.idsByCurrency[currencyCt][currencyId].length)
            return new int256[](0);

        indexUp = indexUp.clampMax(self.idsByCurrency[currencyCt][currencyId].length - 1);

        int256[] memory idsByCurrency = new int256[](indexUp - indexLow + 1);
        for (uint256 i = indexLow; i < indexUp; i++)
            idsByCurrency[i - indexLow] = self.idsByCurrency[currencyCt][currencyId][i];

        return idsByCurrency;
    }

    function idsCount(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (uint256)
    {
        return self.idsByCurrency[currencyCt][currencyId].length;
    }

    function hasId(Balance storage self, int256 id, address currencyCt, uint256 currencyId)
    internal
    view
    returns (bool)
    {
        return 0 < self.idIndexById[currencyCt][currencyId][id];
    }

    function recordByBlockNumber(Balance storage self, address currencyCt, uint256 currencyId, uint256 blockNumber)
    internal
    view
    returns (int256[], uint256)
    {
        uint256 index = indexByBlockNumber(self, currencyCt, currencyId, blockNumber);
        return 0 < index ? recordByIndex(self, currencyCt, currencyId, index - 1) : (new int256[](0), 0);
    }

    function recordByIndex(Balance storage self, address currencyCt, uint256 currencyId, uint256 index)
    internal
    view
    returns (int256[], uint256)
    {
        if (0 == self.recordsByCurrency[currencyCt][currencyId].length)
            return (new int256[](0), 0);

        index = index.clampMax(self.recordsByCurrency[currencyCt][currencyId].length - 1);
        Record storage record = self.recordsByCurrency[currencyCt][currencyId][index];
        return (record.ids, record.blockNumber);
    }

    function lastRecord(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (int256[], uint256)
    {
        if (0 == self.recordsByCurrency[currencyCt][currencyId].length)
            return (new int256[](0), 0);

        Record storage record = self.recordsByCurrency[currencyCt][currencyId][self.recordsByCurrency[currencyCt][currencyId].length - 1];
        return (record.ids, record.blockNumber);
    }

    function recordsCount(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (uint256)
    {
        return self.recordsByCurrency[currencyCt][currencyId].length;
    }

    function set(Balance storage self, int256 id, address currencyCt, uint256 currencyId)
    internal
    {
        int256[] memory ids = new int256[](1);
        ids[0] = id;
        set(self, ids, currencyCt, currencyId);
    }

    function set(Balance storage self, int256[] ids, address currencyCt, uint256 currencyId)
    internal
    {
        uint256 i;
        for (i = 0; i < self.idsByCurrency[currencyCt][currencyId].length; i++)
            self.idIndexById[currencyCt][currencyId][self.idsByCurrency[currencyCt][currencyId][i]] = 0;

        self.idsByCurrency[currencyCt][currencyId] = ids;

        for (i = 0; i < self.idsByCurrency[currencyCt][currencyId].length; i++)
            self.idIndexById[currencyCt][currencyId][self.idsByCurrency[currencyCt][currencyId][i]] = i + 1;

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.idsByCurrency[currencyCt][currencyId], block.number)
        );

        updateInUseCurrencies(self, currencyCt, currencyId);
    }

    function reset(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    {
        for (uint256 i = 0; i < self.idsByCurrency[currencyCt][currencyId].length; i++)
            self.idIndexById[currencyCt][currencyId][self.idsByCurrency[currencyCt][currencyId][i]] = 0;

        self.idsByCurrency[currencyCt][currencyId].length = 0;

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.idsByCurrency[currencyCt][currencyId], block.number)
        );

        updateInUseCurrencies(self, currencyCt, currencyId);
    }

    function add(Balance storage self, int256 id, address currencyCt, uint256 currencyId)
    internal
    returns (bool)
    {
        if (0 < self.idIndexById[currencyCt][currencyId][id])
            return false;

        self.idsByCurrency[currencyCt][currencyId].push(id);

        self.idIndexById[currencyCt][currencyId][id] = self.idsByCurrency[currencyCt][currencyId].length;

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.idsByCurrency[currencyCt][currencyId], block.number)
        );

        updateInUseCurrencies(self, currencyCt, currencyId);

        return true;
    }

    function sub(Balance storage self, int256 id, address currencyCt, uint256 currencyId)
    internal
    returns (bool)
    {
        uint256 index = self.idIndexById[currencyCt][currencyId][id];

        if (0 == index)
            return false;

        if (index < self.idsByCurrency[currencyCt][currencyId].length) {
            self.idsByCurrency[currencyCt][currencyId][index - 1] = self.idsByCurrency[currencyCt][currencyId][self.idsByCurrency[currencyCt][currencyId].length - 1];
            self.idIndexById[currencyCt][currencyId][self.idsByCurrency[currencyCt][currencyId][index - 1]] = index;
        }
        self.idsByCurrency[currencyCt][currencyId].length--;
        self.idIndexById[currencyCt][currencyId][id] = 0;

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.idsByCurrency[currencyCt][currencyId], block.number)
        );

        updateInUseCurrencies(self, currencyCt, currencyId);

        return true;
    }

    function transfer(Balance storage _from, Balance storage _to, int256 id,
        address currencyCt, uint256 currencyId)
    internal
    returns (bool)
    {
        return sub(_from, id, currencyCt, currencyId) && add(_to, id, currencyCt, currencyId);
    }

    function hasInUseCurrency(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (bool)
    {
        return self.inUseCurrencies.has(currencyCt, currencyId);
    }

    function hasEverUsedCurrency(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (bool)
    {
        return self.everUsedCurrencies.has(currencyCt, currencyId);
    }

    function updateInUseCurrencies(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    {
        if (0 == self.idsByCurrency[currencyCt][currencyId].length && self.inUseCurrencies.has(currencyCt, currencyId))
            self.inUseCurrencies.removeByCurrency(currencyCt, currencyId);
        else if (!self.inUseCurrencies.has(currencyCt, currencyId)) {
            self.inUseCurrencies.add(currencyCt, currencyId);
            self.everUsedCurrencies.add(currencyCt, currencyId);
        }
    }

    function indexByBlockNumber(Balance storage self, address currencyCt, uint256 currencyId, uint256 blockNumber)
    internal
    view
    returns (uint256)
    {
        if (0 == self.recordsByCurrency[currencyCt][currencyId].length)
            return 0;
        for (uint256 i = self.recordsByCurrency[currencyCt][currencyId].length; i > 0; i--)
            if (self.recordsByCurrency[currencyCt][currencyId][i - 1].blockNumber <= blockNumber)
                return i;
        return 0;
    }
}

/*
 * Hubii Nahmii
 *
 * Compliant with the Hubii Nahmii specification v0.12.
 *
 * Copyright (C) 2017-2018 Hubii AS
 */










/**
 * @title Balance tracker
 * @notice An ownable to track balances of generic types
 */
contract BalanceTracker is Ownable, Servable {
    using SafeMathIntLib for int256;
    using SafeMathUintLib for uint256;
    using FungibleBalanceLib for FungibleBalanceLib.Balance;
    using NonFungibleBalanceLib for NonFungibleBalanceLib.Balance;

    //
    // Constants
    // -----------------------------------------------------------------------------------------------------------------
    string constant public DEPOSITED_BALANCE_TYPE = "deposited";
    string constant public SETTLED_BALANCE_TYPE = "settled";
    string constant public STAGED_BALANCE_TYPE = "staged";

    //
    // Structures
    // -----------------------------------------------------------------------------------------------------------------
    struct Wallet {
        mapping(bytes32 => FungibleBalanceLib.Balance) fungibleBalanceByType;
        mapping(bytes32 => NonFungibleBalanceLib.Balance) nonFungibleBalanceByType;
    }

    //
    // Variables
    // -----------------------------------------------------------------------------------------------------------------
    bytes32 public depositedBalanceType;
    bytes32 public settledBalanceType;
    bytes32 public stagedBalanceType;

    bytes32[] public _allBalanceTypes;
    bytes32[] public _activeBalanceTypes;

    bytes32[] public trackedBalanceTypes;
    mapping(bytes32 => bool) public trackedBalanceTypeMap;

    mapping(address => Wallet) private walletMap;

    address[] public trackedWallets;
    mapping(address => uint256) public trackedWalletIndexByWallet;

    //
    // Constructor
    // -----------------------------------------------------------------------------------------------------------------
    constructor(address deployer) Ownable(deployer)
    public
    {
        depositedBalanceType = keccak256(abi.encodePacked(DEPOSITED_BALANCE_TYPE));
        settledBalanceType = keccak256(abi.encodePacked(SETTLED_BALANCE_TYPE));
        stagedBalanceType = keccak256(abi.encodePacked(STAGED_BALANCE_TYPE));

        _allBalanceTypes.push(settledBalanceType);
        _allBalanceTypes.push(depositedBalanceType);
        _allBalanceTypes.push(stagedBalanceType);

        _activeBalanceTypes.push(settledBalanceType);
        _activeBalanceTypes.push(depositedBalanceType);
    }

    //
    // Functions
    // -----------------------------------------------------------------------------------------------------------------
    /// @notice Get the fungible balance (amount) of the given wallet, type and currency
    /// @param wallet The address of the concerned wallet
    /// @param _type The balance type
    /// @param currencyCt The address of the concerned currency contract (address(0) == ETH)
    /// @param currencyId The ID of the concerned currency (0 for ETH and ERC20)
    /// @return The stored balance
    function get(address wallet, bytes32 _type, address currencyCt, uint256 currencyId)
    public
    view
    returns (int256)
    {
        return walletMap[wallet].fungibleBalanceByType[_type].get(currencyCt, currencyId);
    }

    /// @notice Get the non-fungible balance (IDs) of the given wallet, type, currency and index range
    /// @param wallet The address of the concerned wallet
    /// @param _type The balance type
    /// @param currencyCt The address of the concerned currency contract (address(0) == ETH)
    /// @param currencyId The ID of the concerned currency (0 for ETH and ERC20)
    /// @param indexLow The lower index of IDs
    /// @param indexUp The upper index of IDs
    /// @return The stored balance
    function getByIndices(address wallet, bytes32 _type, address currencyCt, uint256 currencyId,
        uint256 indexLow, uint256 indexUp)
    public
    view
    returns (int256[])
    {
        return walletMap[wallet].nonFungibleBalanceByType[_type].getByIndices(
            currencyCt, currencyId, indexLow, indexUp
        );
    }

    /// @notice Get all the non-fungible balance (IDs) of the given wallet, type and currency
    /// @param wallet The address of the concerned wallet
    /// @param _type The balance type
    /// @param currencyCt The address of the concerned currency contract (address(0) == ETH)
    /// @param currencyId The ID of the concerned currency (0 for ETH and ERC20)
    /// @return The stored balance
    function getAll(address wallet, bytes32 _type, address currencyCt, uint256 currencyId)
    public
    view
    returns (int256[])
    {
        return walletMap[wallet].nonFungibleBalanceByType[_type].get(
            currencyCt, currencyId
        );
    }

    /// @notice Get the count of non-fungible IDs of the given wallet, type and currency
    /// @param wallet The address of the concerned wallet
    /// @param _type The balance type
    /// @param currencyCt The address of the concerned currency contract (address(0) == ETH)
    /// @param currencyId The ID of the concerned currency (0 for ETH and ERC20)
    /// @return The count of IDs
    function idsCount(address wallet, bytes32 _type, address currencyCt, uint256 currencyId)
    public
    view
    returns (uint256)
    {
        return walletMap[wallet].nonFungibleBalanceByType[_type].idsCount(
            currencyCt, currencyId
        );
    }

    /// @notice Gauge whether the ID is included in the given wallet, type and currency
    /// @param wallet The address of the concerned wallet
    /// @param _type The balance type
    /// @param id The ID of the concerned unit
    /// @param currencyCt The address of the concerned currency contract (address(0) == ETH)
    /// @param currencyId The ID of the concerned currency (0 for ETH and ERC20)
    /// @return true if ID is included, else false
    function hasId(address wallet, bytes32 _type, int256 id, address currencyCt, uint256 currencyId)
    public
    view
    returns (bool)
    {
        return walletMap[wallet].nonFungibleBalanceByType[_type].hasId(
            id, currencyCt, currencyId
        );
    }

    /// @notice Set the balance of the given wallet, type and currency to the given value
    /// @param wallet The address of the concerned wallet
    /// @param _type The balance type
    /// @param value The value (amount of fungible, id of non-fungible) to set
    /// @param currencyCt The address of the concerned currency contract (address(0) == ETH)
    /// @param currencyId The ID of the concerned currency (0 for ETH and ERC20)
    /// @param fungible True if setting fungible balance, else false
    function set(address wallet, bytes32 _type, int256 value, address currencyCt, uint256 currencyId, bool fungible)
    public
    onlyActiveService
    {
        // Update the balance
        if (fungible)
            walletMap[wallet].fungibleBalanceByType[_type].set(
                value, currencyCt, currencyId
            );

        else
            walletMap[wallet].nonFungibleBalanceByType[_type].set(
                value, currencyCt, currencyId
            );

        // Update balance type hashes
        _updateTrackedBalanceTypes(_type);

        // Update tracked wallets
        _updateTrackedWallets(wallet);
    }

    /// @notice Set the non-fungible balance IDs of the given wallet, type and currency to the given value
    /// @param wallet The address of the concerned wallet
    /// @param _type The balance type
    /// @param ids The ids of non-fungible) to set
    /// @param currencyCt The address of the concerned currency contract (address(0) == ETH)
    /// @param currencyId The ID of the concerned currency (0 for ETH and ERC20)
    function setIds(address wallet, bytes32 _type, int256[] ids, address currencyCt, uint256 currencyId)
    public
    onlyActiveService
    {
        // Update the balance
        walletMap[wallet].nonFungibleBalanceByType[_type].set(
            ids, currencyCt, currencyId
        );

        // Update balance type hashes
        _updateTrackedBalanceTypes(_type);

        // Update tracked wallets
        _updateTrackedWallets(wallet);
    }

    /// @notice Add the given value to the balance of the given wallet, type and currency
    /// @param wallet The address of the concerned wallet
    /// @param _type The balance type
    /// @param value The value (amount of fungible, id of non-fungible) to add
    /// @param currencyCt The address of the concerned currency contract (address(0) == ETH)
    /// @param currencyId The ID of the concerned currency (0 for ETH and ERC20)
    /// @param fungible True if adding fungible balance, else false
    function add(address wallet, bytes32 _type, int256 value, address currencyCt, uint256 currencyId,
        bool fungible)
    public
    onlyActiveService
    {
        // Update the balance
        if (fungible)
            walletMap[wallet].fungibleBalanceByType[_type].add(
                value, currencyCt, currencyId
            );
        else
            walletMap[wallet].nonFungibleBalanceByType[_type].add(
                value, currencyCt, currencyId
            );

        // Update balance type hashes
        _updateTrackedBalanceTypes(_type);

        // Update tracked wallets
        _updateTrackedWallets(wallet);
    }

    /// @notice Subtract the given value from the balance of the given wallet, type and currency
    /// @param wallet The address of the concerned wallet
    /// @param _type The balance type
    /// @param value The value (amount of fungible, id of non-fungible) to subtract
    /// @param currencyCt The address of the concerned currency contract (address(0) == ETH)
    /// @param currencyId The ID of the concerned currency (0 for ETH and ERC20)
    /// @param fungible True if subtracting fungible balance, else false
    function sub(address wallet, bytes32 _type, int256 value, address currencyCt, uint256 currencyId,
        bool fungible)
    public
    onlyActiveService
    {
        // Update the balance
        if (fungible)
            walletMap[wallet].fungibleBalanceByType[_type].sub(
                value, currencyCt, currencyId
            );
        else
            walletMap[wallet].nonFungibleBalanceByType[_type].sub(
                value, currencyCt, currencyId
            );

        // Update tracked wallets
        _updateTrackedWallets(wallet);
    }

    /// @notice Gauge whether this tracker has in-use data for the given wallet, type and currency
    /// @param wallet The address of the concerned wallet
    /// @param _type The balance type
    /// @param currencyCt The address of the concerned currency contract (address(0) == ETH)
    /// @param currencyId The ID of the concerned currency (0 for ETH and ERC20)
    /// @return true if data is stored, else false
    function hasInUseCurrency(address wallet, bytes32 _type, address currencyCt, uint256 currencyId)
    public
    view
    returns (bool)
    {
        return walletMap[wallet].fungibleBalanceByType[_type].hasInUseCurrency(currencyCt, currencyId)
        || walletMap[wallet].nonFungibleBalanceByType[_type].hasInUseCurrency(currencyCt, currencyId);
    }

    /// @notice Gauge whether this tracker has ever-used data for the given wallet, type and currency
    /// @param wallet The address of the concerned wallet
    /// @param _type The balance type
    /// @param currencyCt The address of the concerned currency contract (address(0) == ETH)
    /// @param currencyId The ID of the concerned currency (0 for ETH and ERC20)
    /// @return true if data is stored, else false
    function hasEverUsedCurrency(address wallet, bytes32 _type, address currencyCt, uint256 currencyId)
    public
    view
    returns (bool)
    {
        return walletMap[wallet].fungibleBalanceByType[_type].hasEverUsedCurrency(currencyCt, currencyId)
        || walletMap[wallet].nonFungibleBalanceByType[_type].hasEverUsedCurrency(currencyCt, currencyId);
    }

    /// @notice Get the count of fungible balance records for the given wallet, type and currency
    /// @param wallet The address of the concerned wallet
    /// @param _type The balance type
    /// @param currencyCt The address of the concerned currency contract (address(0) == ETH)
    /// @param currencyId The ID of the concerned currency (0 for ETH and ERC20)
    /// @return The count of balance log entries
    function fungibleRecordsCount(address wallet, bytes32 _type, address currencyCt, uint256 currencyId)
    public
    view
    returns (uint256)
    {
        return walletMap[wallet].fungibleBalanceByType[_type].recordsCount(currencyCt, currencyId);
    }

    /// @notice Get the fungible balance record for the given wallet, type, currency
    /// log entry index
    /// @param wallet The address of the concerned wallet
    /// @param _type The balance type
    /// @param currencyCt The address of the concerned currency contract (address(0) == ETH)
    /// @param currencyId The ID of the concerned currency (0 for ETH and ERC20)
    /// @param index The concerned record index
    /// @return The balance record
    function fungibleRecordByIndex(address wallet, bytes32 _type, address currencyCt, uint256 currencyId,
        uint256 index)
    public
    view
    returns (int256 amount, uint256 blockNumber)
    {
        return walletMap[wallet].fungibleBalanceByType[_type].recordByIndex(currencyCt, currencyId, index);
    }

    /// @notice Get the non-fungible balance record for the given wallet, type, currency
    /// block number
    /// @param wallet The address of the concerned wallet
    /// @param _type The balance type
    /// @param currencyCt The address of the concerned currency contract (address(0) == ETH)
    /// @param currencyId The ID of the concerned currency (0 for ETH and ERC20)
    /// @param _blockNumber The concerned block number
    /// @return The balance record
    function fungibleRecordByBlockNumber(address wallet, bytes32 _type, address currencyCt, uint256 currencyId,
        uint256 _blockNumber)
    public
    view
    returns (int256 amount, uint256 blockNumber)
    {
        return walletMap[wallet].fungibleBalanceByType[_type].recordByBlockNumber(currencyCt, currencyId, _blockNumber);
    }

    /// @notice Get the last (most recent) non-fungible balance record for the given wallet, type and currency
    /// @param wallet The address of the concerned wallet
    /// @param _type The balance type
    /// @param currencyCt The address of the concerned currency contract (address(0) == ETH)
    /// @param currencyId The ID of the concerned currency (0 for ETH and ERC20)
    /// @return The last log entry
    function lastFungibleRecord(address wallet, bytes32 _type, address currencyCt, uint256 currencyId)
    public
    view
    returns (int256 amount, uint256 blockNumber)
    {
        return walletMap[wallet].fungibleBalanceByType[_type].lastRecord(currencyCt, currencyId);
    }

    /// @notice Get the count of non-fungible balance records for the given wallet, type and currency
    /// @param wallet The address of the concerned wallet
    /// @param _type The balance type
    /// @param currencyCt The address of the concerned currency contract (address(0) == ETH)
    /// @param currencyId The ID of the concerned currency (0 for ETH and ERC20)
    /// @return The count of balance log entries
    function nonFungibleRecordsCount(address wallet, bytes32 _type, address currencyCt, uint256 currencyId)
    public
    view
    returns (uint256)
    {
        return walletMap[wallet].nonFungibleBalanceByType[_type].recordsCount(currencyCt, currencyId);
    }

    /// @notice Get the non-fungible balance record for the given wallet, type, currency
    /// and record index
    /// @param wallet The address of the concerned wallet
    /// @param _type The balance type
    /// @param currencyCt The address of the concerned currency contract (address(0) == ETH)
    /// @param currencyId The ID of the concerned currency (0 for ETH and ERC20)
    /// @param index The concerned record index
    /// @return The balance record
    function nonFungibleRecordByIndex(address wallet, bytes32 _type, address currencyCt, uint256 currencyId,
        uint256 index)
    public
    view
    returns (int256[] ids, uint256 blockNumber)
    {
        return walletMap[wallet].nonFungibleBalanceByType[_type].recordByIndex(currencyCt, currencyId, index);
    }

    /// @notice Get the non-fungible balance record for the given wallet, type, currency
    /// and block number
    /// @param wallet The address of the concerned wallet
    /// @param _type The balance type
    /// @param currencyCt The address of the concerned currency contract (address(0) == ETH)
    /// @param currencyId The ID of the concerned currency (0 for ETH and ERC20)
    /// @param _blockNumber The concerned block number
    /// @return The balance record
    function nonFungibleRecordByBlockNumber(address wallet, bytes32 _type, address currencyCt, uint256 currencyId,
        uint256 _blockNumber)
    public
    view
    returns (int256[] ids, uint256 blockNumber)
    {
        return walletMap[wallet].nonFungibleBalanceByType[_type].recordByBlockNumber(currencyCt, currencyId, _blockNumber);
    }

    /// @notice Get the last (most recent) non-fungible balance record for the given wallet, type and currency
    /// @param wallet The address of the concerned wallet
    /// @param _type The balance type
    /// @param currencyCt The address of the concerned currency contract (address(0) == ETH)
    /// @param currencyId The ID of the concerned currency (0 for ETH and ERC20)
    /// @return The last log entry
    function lastNonFungibleRecord(address wallet, bytes32 _type, address currencyCt, uint256 currencyId)
    public
    view
    returns (int256[] ids, uint256 blockNumber)
    {
        return walletMap[wallet].nonFungibleBalanceByType[_type].lastRecord(currencyCt, currencyId);
    }

    /// @notice Get the count of tracked balance types
    /// @return The count of tracked balance types
    function trackedBalanceTypesCount()
    public
    view
    returns (uint256)
    {
        return trackedBalanceTypes.length;
    }

    /// @notice Get the count of tracked wallets
    /// @return The count of tracked wallets
    function trackedWalletsCount()
    public
    view
    returns (uint256)
    {
        return trackedWallets.length;
    }

    /// @notice Get the default full set of balance types
    /// @return The set of all balance types
    function allBalanceTypes()
    public
    view
    returns (bytes32[])
    {
        return _allBalanceTypes;
    }

    /// @notice Get the default set of active balance types
    /// @return The set of active balance types
    function activeBalanceTypes()
    public
    view
    returns (bytes32[])
    {
        return _activeBalanceTypes;
    }

    /// @notice Get the subset of tracked wallets in the given index range
    /// @param low The lower index
    /// @param up The upper index
    /// @return The subset of tracked wallets
    function trackedWalletsByIndices(uint256 low, uint256 up)
    public
    view
    returns (address[])
    {
        require(0 < trackedWallets.length);
        require(low <= up);

        up = up.clampMax(trackedWallets.length - 1);
        address[] memory _trackedWallets = new address[](up - low + 1);
        for (uint256 i = low; i <= up; i++)
            _trackedWallets[i - low] = trackedWallets[i];

        return _trackedWallets;
    }

    //
    // Private functions
    // -----------------------------------------------------------------------------------------------------------------
    function _updateTrackedBalanceTypes(bytes32 _type)
    private
    {
        if (!trackedBalanceTypeMap[_type]) {
            trackedBalanceTypeMap[_type] = true;
            trackedBalanceTypes.push(_type);
        }
    }

    function _updateTrackedWallets(address wallet)
    private
    {
        if (0 == trackedWalletIndexByWallet[wallet]) {
            trackedWallets.push(wallet);
            trackedWalletIndexByWallet[wallet] = trackedWallets.length;
        }
    }
}