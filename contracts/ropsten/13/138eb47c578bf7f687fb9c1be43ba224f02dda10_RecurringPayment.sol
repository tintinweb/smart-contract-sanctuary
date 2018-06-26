pragma solidity 0.4.24;


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
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


contract AccountRoles {
    bytes32 public constant ROLE_TRANSFER_ETHER = keccak256(&quot;transfer_ether&quot;);
    bytes32 public constant ROLE_TRANSFER_TOKEN = keccak256(&quot;transfer_token&quot;);
    bytes32 public constant ROLE_TRANSFER_OWNERSHIP = keccak256(&quot;transfer_ownership&quot;);	
    
    /**
    * @dev modifier to validate the roles 
    * @param roles to be validated
    * // reverts
    */
    modifier validAccountRoles(bytes32[] roles) {
        for (uint8 i = 0; i < roles.length; i++) {
            require(roles[i] == ROLE_TRANSFER_ETHER 
            || roles[i] == ROLE_TRANSFER_TOKEN
            || roles[i] == ROLE_TRANSFER_OWNERSHIP, &quot;Invalid account role&quot;);
        }
        _;
    }
}


contract ISmartAccount {
    function transferOwnership(address _newOwner) public;
    function executeCall(address _destination, uint256 _value, uint256 _gasLimit, bytes _data) public;
}


contract UIExtension {
    string public uiExtensionVersion = &quot;0.0.1&quot;;
	
    uint256 constant INTEGER = 1;
    uint256 constant FLOAT = 2;
    uint256 constant ADDRESS = 3;
    uint256 constant BOOL = 4;
    uint256 constant DATE = 5;
    uint256 constant STRING = 6;
    uint256 constant BYTE = 7;
    uint256 constant SMARTACCOUNTADDRESS = 8;
	
    struct Parameter {
        bool isArray;
        bool isOptional;
        uint256 typeReference;
        uint256 decimals; //only for INTEGER and FLOAT types (the value that will be multiplied, default 1, not defined or zero is equal 1 too)
        string description;
    }

    struct ConfigParameter {
        bool isEditable;
        Parameter parameter;
    }
    
    struct Setup {
        bytes4 createFunctionSignature; //function signature to create new configurable instance (view notes below)
        bytes4 updateFunctionSignature; //function signature to update existing configurable instance (view notes below)
        ConfigParameter[] parameters;
    }
    
    struct Action {
        bytes4 functionSignature;
        string description;
        Parameter[] parameters;
    }
    
    struct ViewData {
        bytes4 functionSignature;
        Parameter output;
    }
    
    struct BaseStorage {
        bytes4 functionSignature;
        uint256 parametersCount;
        string description;
    }
    
    struct Storage {
        BaseStorage baseData;
        mapping(uint256 => Parameter) parameters;
    }
    
    struct ConfigStorage {
        bytes4 createFunctionSignature;
        bytes4 updateFunctionSignature;
        uint256 parametersCount;
        mapping(uint256 => ConfigParameter) parameters;
    }
    
    ConfigStorage private setupParameters;
    Storage[] private viewDatas;
    Storage[] private actions;
    
    constructor() public {
        addConfigurableParameters(getSetupParameters());
        addViewDatas(getViewDatas());
        addActions(getActions());
    }
    
    function getName() pure external returns(string);
    function getDescription() pure external returns(string);
    function getSetupParameters() pure internal returns(Setup);
    function getActions() pure internal returns(Action[]);
    function getViewDatas() pure internal returns(ViewData[]);
    
    // IMPORTANT NOTES
    
    /* All view data functions must receive as arguments an address and a bytes32 (address,bytes32)
     * the arguments are smart account address and the respective identifier
     */
    
    /* Function to create new configurable instance must receive all setup parameters
     * using the same order defined in getSetupParameters() function 
     */
     
    /* Function to update existing configurable instance must receive 
     * respective identifier + all setup parameters (bytes32, [setup parameters])
     * setup parameters must use the same order defined in getSetupParameters() function 
     */
    
    /* Extension must always implement a function with the signature getSetup(address,bytes32)
     * the arguments are smart account address and respective identifier
     * the returns must be the value for all setup parameters 
     * using the same order defined in getSetupParameters() function 
     */ 
    
    function getSetupParametersCount() 
        view 
        public 
        returns(uint256) 
    {
        return setupParameters.parametersCount;
    }
    
    function getViewDatasCount() 
        view 
        public 
        returns(uint256) 
    {
        return viewDatas.length;
    }
    
    function getActionsCount() 
        view 
        public 
        returns(uint256) 
    {
        return actions.length;
    }
    
    function getSetupFunctions() 
        view 
        public 
        returns(bytes4, bytes4) 
    {
        return (setupParameters.createFunctionSignature, setupParameters.updateFunctionSignature);
    }
    
    function getSetupParametersByIndex(uint256 _index) 
        view 
        public 
        returns(bool, bool, bool, uint256, uint256, string) 
    {
        bool isArray;
        bool isOptional;
        uint256 typeReference; 
        uint256 decimals;
        string memory description;
        (isArray, isOptional, typeReference, decimals, description) = getParameter(setupParameters.parameters[_index].parameter);
        return (setupParameters.parameters[_index].isEditable, isArray, isOptional, typeReference, decimals, description);
    }
    
    function getViewDataByIndex(uint256 _index) 
        view 
        public 
        returns(bytes4, bool, bool, uint256, uint256, string) 
    {
        bool isArray;
        bool isOptional;
        uint256 typeReference;
        uint256 decimals;
        string memory description;
        (isArray, isOptional, typeReference, decimals, description) = getParameter(viewDatas[_index].parameters[0]);
        return (viewDatas[_index].baseData.functionSignature, isArray, isOptional, typeReference, decimals, description);
    }
    
    function getActionByIndex(uint256 _index) 
        view 
        public 
        returns(bytes4, string, uint256) 
    {
        return (actions[_index].baseData.functionSignature, actions[_index].baseData.description, actions[_index].baseData.parametersCount);
    }
    
    function getActionParametersCountByIndex(uint256 _index) 
        view 
        public 
        returns(uint256) 
    {
        return actions[_index].baseData.parametersCount;
    }
    
    function getActionParameterByIndexes(uint256 _actionIndex, uint256 _parameterIndex) 
        view 
        public 
        returns(bool, bool, uint256, uint256, string) 
    {
        return getParameter(actions[_actionIndex].parameters[_parameterIndex]);
    }

    function getParameter(Parameter _parameter)
        pure
        private
        returns(bool, bool, uint256, uint256, string)
    {
        return (_parameter.isArray, _parameter.isOptional, _parameter.typeReference, _parameter.decimals, _parameter.description);
    }
    
    function validateTypeReference(uint256 _typeReference, bool _isArray) 
        pure 
        private 
    {
        require (_typeReference == INTEGER
            || _typeReference == FLOAT 
            || _typeReference == ADDRESS 
            || _typeReference == BOOL
            || _typeReference == DATE
            || (_typeReference == SMARTACCOUNTADDRESS && !_isArray)
            || (_typeReference == STRING && !_isArray)
            || (_typeReference == BYTE && !_isArray));
    }
    
    function validateDescription(string _description) 
        pure 
        private 
    {
        bytes memory description = bytes(_description);
        require(description.length > 0);
    }
    
    function addConfigurableParameters(Setup _setup) 
        private 
    {
        require(_setup.createFunctionSignature != _setup.updateFunctionSignature);
        require(_setup.createFunctionSignature != &quot;&quot; && _setup.updateFunctionSignature != &quot;&quot;);
            
        setupParameters.createFunctionSignature = _setup.createFunctionSignature;
        setupParameters.updateFunctionSignature = _setup.updateFunctionSignature;
        setupParameters.parametersCount = _setup.parameters.length;
        for(uint256 i = 0; i < _setup.parameters.length; i++) {
            validateTypeReference(_setup.parameters[i].parameter.typeReference, _setup.parameters[i].parameter.isArray);
            setupParameters.parameters[i] = _setup.parameters[i];
        }
    }
    
    function addActions(Action[] _actions) 
        private 
    {
        require(_actions.length > 0);
        
        for(uint256 i = 0; i < _actions.length; i++) {
            validateDescription(_actions[i].description);
            Storage memory s;
            s.baseData = setBaseStorage(_actions[i].functionSignature, _actions[i].parameters.length, _actions[i].description);
            actions.push(s);
            for(uint256 j = 0; j < _actions[i].parameters.length; j++) {
                validateTypeReference(_actions[i].parameters[j].typeReference, _actions[i].parameters[j].isArray);
                validateDescription(_actions[i].parameters[j].description);
                actions[i].parameters[j] = _actions[i].parameters[j];
            }
        }
    }
    
    function addViewDatas(ViewData[] _viewDatas) private {
        for(uint256 i = 0; i < _viewDatas.length; i++) {
            validateTypeReference(_viewDatas[i].output.typeReference, _viewDatas[i].output.isArray);
            validateDescription(_viewDatas[i].output.description);
            Storage memory s;
            s.baseData = setBaseStorage(_viewDatas[i].functionSignature, 1, &quot;&quot;);
            viewDatas.push(s);
            viewDatas[i].parameters[0] = _viewDatas[i].output;
        }
    }
    
    function setBaseStorage(
        bytes4 _functionSignature, 
        uint256 _parametersCount, 
        string _description
    ) 
        private 
        pure 
        returns (BaseStorage) 
    {
        require(_functionSignature != &quot;&quot;);
        BaseStorage memory s;
        s.functionSignature = _functionSignature;
        s.parametersCount = _parametersCount;
        s.description = _description;
        return s;
    }
}


contract ManagerExtension {
    string public managerExtensionVersion = &quot;0.0.1&quot;;

    mapping(address => bytes32[]) private identifier; //all extensions should define the identifier, it is necessary because the smart account can add the extension more than once
    mapping(bytes32 => uint256) private indexes;
    
    event SetIdentifier(address sender, address smartAccount, bytes32 identifier);
      event RemoveIdentifier(address sender, address smartAccount, bytes32 identifier);
    
    // Options are ROLE_TRANSFER_ETHER, ROLE_TRANSFER_TOKEN and/or ROLE_TRANSFER_OWNERSHIP
    function getRoles() pure public returns(bytes32[]);
	
    function setIdentifier(address _smartAccount, bytes32 _identifier) internal {
        bool alreadyExist = false;
        for (uint256 i = 0; i < identifier[_smartAccount].length; ++i) {
            if (identifier[_smartAccount][i] == _identifier) {
                alreadyExist = true;
                break;
            }
        }
        if (!alreadyExist) {
            indexes[keccak256(abi.encodePacked(_smartAccount, _identifier))] = identifier[_smartAccount].push(_identifier) - 1;
            emit SetIdentifier(msg.sender, _smartAccount, _identifier);
        }
    }
    
    function removeIdentifier(address _smartAccount, bytes32 _identifier) internal {
        require(getIdentifiersCount(_smartAccount) > 0);
        uint256 index = indexes[keccak256(abi.encodePacked(_smartAccount, _identifier))];
        bytes32 indexReplacer = identifier[_smartAccount][identifier[_smartAccount].length - 1];
        identifier[_smartAccount][index] = indexReplacer;
        indexes[keccak256(abi.encodePacked(_smartAccount, indexReplacer))] = index;
        identifier[_smartAccount].length--;
        emit RemoveIdentifier(msg.sender, _smartAccount, _identifier);
    }
    
    function getIdentifiers(address _smartAccount) 
        view 
        public 
        returns(bytes32[]) 
    {
        return identifier[_smartAccount];
    }
    
    function getIdentifiersCount(address _smartAccount) 
        view 
        public 
        returns(uint256) 
    {
        return identifier[_smartAccount].length;
    }
    
    function getIdentifierByIndex(address _smartAccount, uint256 _index) view public returns(bytes32) {
        return identifier[_smartAccount][_index];
    }
    
    function transferTokenFrom(address _smartAccount, address _tokenAddress, address _to, uint256 _amount) internal {
        bytes memory data = abi.encodePacked(bytes4(keccak256(&quot;transfer(address,uint256)&quot;)), bytes32(_to), _amount);
        ISmartAccount(_smartAccount).executeCall(_tokenAddress, 0, 0, data);
    }
    
    function transferEtherFrom(address _smartAccount, address _to, uint256 _amount) internal {
        ISmartAccount(_smartAccount).executeCall(_to, _amount, 0, &quot;&quot;);
    }
}


contract IExtension is UIExtension, ManagerExtension, AccountRoles {
}


//Example 2
//TODO: add comments and events
contract RecurringPayment is IExtension {
    using SafeMath for uint256;
    
    struct Configuration {
        uint256 recurrenceTime;
        uint256 periods;
        bool paymentInEther;
        address tokenAddress;
        uint256 maximumAmountPerPeriod;
    }
    
    struct Data {
        uint256 releasedPeriods;
        uint256 releasedAmount;
        uint256 start;
        mapping(uint256 => uint256) releasedPerPeriod;
    }
    
    mapping(address => mapping(address => Configuration)) configuration;
    mapping(bytes32 => Data) paymentData;
    
    function getName() pure external returns(string) {
        return &quot;Recurring Payment&quot;;
    }
    
    function getDescription() pure external returns(string) {
        return &quot;Define an authorized address to withdraw a number of Ethers or Tokens for some recurrent period.&quot;;
    }
    
    function getSetupParameters() pure internal returns(Setup) {
        ConfigParameter[] memory parameters = new ConfigParameter[](6);
        parameters[0] = ConfigParameter(false, Parameter(false, false, ADDRESS, 0, &quot;Beneficiary address&quot;));
        parameters[1] = ConfigParameter(false, Parameter(false, false, INTEGER, 86400, &quot;Recurrence time in days&quot;));
        parameters[2] = ConfigParameter(true, Parameter(false, false, INTEGER, 0, &quot;Number of periods&quot;));
        parameters[3] = ConfigParameter(false, Parameter(false, false, BOOL, 0, &quot;Payment in Ether&quot;));
        parameters[4] = ConfigParameter(false, Parameter(false, true, ADDRESS, 0, &quot;Token address if payment not in Ether&quot;));
        parameters[5] = ConfigParameter(true, Parameter(false, false, FLOAT, 1000000000000000000, &quot;Maximum amount per period&quot;));
        return Setup(bytes4(keccak256(&quot;createSetup(address,uint256,uint256,bool,address,uint256)&quot;)), 
            bytes4(keccak256(&quot;updateSetup(bytes32,address,uint256,uint256,bool,address,uint256)&quot;)),
            parameters);
    }
    
    function getActions() pure internal returns(Action[]) {
        Parameter[] memory parameters1 = new Parameter[](2);
        parameters1[0] = Parameter(false, false, SMARTACCOUNTADDRESS, 0, &quot;Smart account&quot;);
        parameters1[1] = Parameter(false, false, FLOAT, 1000000000000000000, &quot;Amount&quot;);
        Parameter[] memory parameters2 = new Parameter[](1);
        parameters2[0] = Parameter(false, false, ADDRESS, 0, &quot;Beneficiary&quot;);
        Action[] memory action = new Action[](2);
        action[0].description = &quot;Make a withdraw&quot;;
        action[0].parameters = parameters1;
        action[0].functionSignature = bytes4(keccak256(&quot;withdrawal(address,uint256)&quot;));
        action[1].description = &quot;Cancel recurring payment&quot;;
        action[1].parameters = parameters2;
        action[1].functionSignature = bytes4(keccak256(&quot;cancelRecurringPayment(bytes32)&quot;));
        return action;
    }
    
    function getViewDatas() pure internal returns(ViewData[]) {
        ViewData[] memory viewData = new ViewData[](3);
        viewData[0].functionSignature = bytes4(keccak256(&quot;getAvailableAmountWithdrawal(address,bytes32)&quot;));
        viewData[0].output = Parameter(false, false, FLOAT, 1000000000000000000, &quot;Available amount to withdrawal&quot;);
        viewData[1].functionSignature = bytes4(keccak256(&quot;getAmountWithdrawal(address,bytes32)&quot;));
        viewData[1].output = Parameter(false, false, FLOAT, 1000000000000000000, &quot;Amount released&quot;);
        viewData[2].functionSignature = bytes4(keccak256(&quot;getPeriodsWithdrawal(address,bytes32)&quot;));
        viewData[2].output = Parameter(false, false, INTEGER, 0, &quot;Amount of periods released&quot;);
        return viewData;
    }
    
    function getRoles() pure public returns(bytes32[]) {
        bytes32[] memory roles = new bytes32[](2); 
        roles[0] = ROLE_TRANSFER_ETHER;
        roles[1] = ROLE_TRANSFER_TOKEN;
        return roles;
    }
    
    function createSetup(
        address _beneficiary, 
        uint256 _recurrenceTime, 
        uint256 _periods, 
        bool _paymentInEther, 
        address _tokenAddress, 
        uint256 _maximumAmountPerPeriod
    )
        public
    {
        require(_beneficiary != address(0) && msg.sender != _beneficiary);
        require(_recurrenceTime > 0);
        require(_periods > 0);
        require(_maximumAmountPerPeriod > 0);
        require(_paymentInEther || _tokenAddress != address(0));
        if (configuration[msg.sender][_beneficiary].recurrenceTime > 0) {
            require(configuration[msg.sender][_beneficiary].recurrenceTime == _recurrenceTime);
            require(configuration[msg.sender][_beneficiary].paymentInEther == _paymentInEther);
            require(configuration[msg.sender][_beneficiary].tokenAddress == _tokenAddress);
        } else {
            configuration[msg.sender][_beneficiary].recurrenceTime = _recurrenceTime;
            configuration[msg.sender][_beneficiary].paymentInEther = _paymentInEther;
            configuration[msg.sender][_beneficiary].tokenAddress = _tokenAddress;
            setIdentifier(msg.sender, bytes32(_beneficiary));
        }
        configuration[msg.sender][_beneficiary].periods = _periods;
        configuration[msg.sender][_beneficiary].maximumAmountPerPeriod = _maximumAmountPerPeriod;
    }
    
    function updateSetup(
        bytes32,
        address _beneficiary, 
        uint256 _recurrenceTime, 
        uint256 _periods, 
        bool _paymentInEther, 
        address _tokenAddress, 
        uint256 _maximumAmountPerPeriod
    )
        external
    {
        createSetup(_beneficiary, _recurrenceTime, _periods, _paymentInEther, _tokenAddress, _maximumAmountPerPeriod);
    }
        
    function getSetup(address _reference, bytes32 _identifier) 
        view 
        external 
        returns (address, uint256, uint256, bool, address, uint256) 
    {
        return (address(_identifier),
            configuration[_reference][address(_identifier)].recurrenceTime,
            configuration[_reference][address(_identifier)].periods,
            configuration[_reference][address(_identifier)].paymentInEther,
            configuration[_reference][address(_identifier)].tokenAddress,
            configuration[_reference][address(_identifier)].maximumAmountPerPeriod);
    }

    function getPeriodsWithdrawal(address _reference, bytes32 _identifier) view external returns(uint256) {
        return paymentData[keccak256(abi.encodePacked(_reference, _identifier))].releasedPeriods;
    }

    function getAmountWithdrawal(address _reference, bytes32 _identifier) view external returns(uint256) {
        return paymentData[keccak256(abi.encodePacked(_reference, _identifier))].releasedAmount;
    }

    function getAvailableAmountWithdrawal(address _reference, bytes32 _identifier) view external returns(uint256) {
        bytes32 key = keccak256(abi.encodePacked(_reference, _identifier));
        uint256 allowedAmount;
        uint256 pendingPeriods;
        (allowedAmount, pendingPeriods) = getAllowedAmountAndPendingPeriods(_reference, address(_identifier), key);
        return allowedAmount;
    }
    
    function cancelRecurringPayment(address _beneficiary) external {
        require(configuration[msg.sender][_beneficiary].recurrenceTime > 0);
        configuration[msg.sender][_beneficiary].recurrenceTime = 0;
        configuration[msg.sender][_beneficiary].periods = 0;
        configuration[msg.sender][_beneficiary].maximumAmountPerPeriod = 0;
        configuration[msg.sender][_beneficiary].paymentInEther = false;
        configuration[msg.sender][_beneficiary].tokenAddress = address(0);
        removeIdentifier(msg.sender, bytes32(_beneficiary));
    }
    
    function withdrawal(address _smartAccount, uint256 _amount) external { 
        require(_amount > 0);
        require(configuration[_smartAccount][msg.sender].recurrenceTime > 0);
        bytes32 key = keccak256(abi.encodePacked(_smartAccount, bytes32(msg.sender)));
        require(paymentData[key].releasedPeriods == 0 
            || configuration[_smartAccount][msg.sender].periods > paymentData[key].releasedPeriods);
        
        uint256 allowedAmount;
        uint256 pendingPeriods;
        (allowedAmount, pendingPeriods) = getAllowedAmountAndPendingPeriods(_smartAccount, msg.sender, key);
        require(allowedAmount >= _amount);

        if (paymentData[key].start == 0) {
            paymentData[key].start = now;
        }
        paymentData[key].releasedPeriods = paymentData[key].releasedPeriods.add(pendingPeriods);
        paymentData[key].releasedPerPeriod[paymentData[key].releasedPeriods] = 
            paymentData[key].releasedPerPeriod[paymentData[key].releasedPeriods].add(_amount); 
        paymentData[key].releasedAmount = paymentData[key].releasedAmount.add(_amount);

        if (configuration[_smartAccount][msg.sender].paymentInEther) {
            transferEtherFrom(_smartAccount, msg.sender, _amount);
        } else {
            transferTokenFrom(_smartAccount, configuration[_smartAccount][msg.sender].tokenAddress, msg.sender, _amount);
        }
    }
    
    function getAllowedAmountAndPendingPeriods(address _smartAccount, address _beneficiary, bytes32 _key) internal view returns (uint256, uint256) {
        if (paymentData[_key].start == 0) {
            return (configuration[_smartAccount][_beneficiary].maximumAmountPerPeriod, 1);
        } else {
    		uint256 secondsFromTheStart = now.sub(paymentData[_key].start);
            uint256 pendingPeriods = min(secondsFromTheStart.div(configuration[_smartAccount][_beneficiary].recurrenceTime).add(1), 
                                        configuration[_smartAccount][msg.sender].periods.sub(paymentData[_key].releasedPeriods));
                                        
    		if (pendingPeriods == 0) {
                return (configuration[_smartAccount][_beneficiary].maximumAmountPerPeriod 
                        .sub(paymentData[_key].releasedPerPeriod[paymentData[_key].releasedPeriods]), 0);
    		} else {
    			return (configuration[_smartAccount][_beneficiary].maximumAmountPerPeriod.mul(pendingPeriods), pendingPeriods);
    		}
        }
    }
    
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }
}