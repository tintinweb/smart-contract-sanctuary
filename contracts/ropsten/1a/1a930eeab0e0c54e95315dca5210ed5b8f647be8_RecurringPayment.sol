pragma solidity ^0.4.24;


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
  bytes32 public constant ROLE_TRANSFER_ETHER = keccak256("transfer_ether");
  bytes32 public constant ROLE_TRANSFER_TOKEN = keccak256("transfer_token");
  bytes32 public constant ROLE_TRANSFER_OWNERSHIP = keccak256("transfer_ownership");  
  
  /**
  * @dev modifier to validate the roles 
  * @param roles to be validated
  * // reverts
  */
  modifier validAccountRoles(bytes32[] roles) {
    for (uint8 i = 0; i < roles.length; i++) {
      require(roles[i] == ROLE_TRANSFER_ETHER 
        || roles[i] == ROLE_TRANSFER_TOKEN
        || roles[i] == ROLE_TRANSFER_OWNERSHIP, "Invalid account role");
    }
    _;
  }
}


contract UIExtension {
  string public uiExtensionVersion = "0.0.1";
  
  uint256 constant INTEGER = 1;
  uint256 constant FLOAT = 2;
  uint256 constant ADDRESS = 3;
  uint256 constant BOOL = 4;
  uint256 constant DATE = 5;
  uint256 constant STRING = 6;
  uint256 constant BYTE = 7;
  uint256 constant SMARTACCOUNTADDRESS = 8; //used to inform that the respective smart account should be inputted on the parameter
  uint256 constant IDENTIFIER = 9; //used to inform that the respective smart account identifier should be inputted on the parameter
  
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
    bool directlyCallFunction; //function to be called directly on extension contract (used for trusted addresses that are authorized by extension)
    string description;
    Parameter[] parameters;
  }
  
  struct ViewData {
    bytes4 functionSignature;
    Parameter output;
  }
  
  struct ActionStorage {
    bytes4 functionSignature;
    bool directlyCallFunction;
    uint256 parametersCount;
    string description;
    mapping(uint256 => Parameter) parameters;
  }
  
  struct ViewDataStorage {
    bytes4 functionSignature;
    mapping(uint256 => Parameter) parameters;
  }
  
  struct ConfigStorage {
    bytes4 createFunctionSignature;
    bytes4 updateFunctionSignature;
    uint256 parametersCount;
    mapping(uint256 => ConfigParameter) parameters;
  }
  
  ConfigStorage private setupParameters;
  ViewDataStorage[] private viewDatas;
  ActionStorage[] private actions;
  
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
    return (viewDatas[_index].functionSignature, isArray, isOptional, typeReference, decimals, description);
  }
    
  function getActionByIndex(uint256 _index) 
    view 
    public 
    returns(bytes4, bool, uint256, string) 
  {
    return (actions[_index].functionSignature, actions[_index].directlyCallFunction, actions[_index].parametersCount, actions[_index].description);
  }
    
  function getActionParametersCountByIndex(uint256 _index) 
    view 
    public 
    returns(uint256) 
  {
    return actions[_index].parametersCount;
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
      || (_typeReference == IDENTIFIER && !_isArray)
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
  
  function validateFunction(bytes4 _functionSignature) 
    pure 
    private 
  {
    require(_functionSignature != "");
  }
  
  function addConfigurableParameters(Setup _setup) private {
    require(_setup.createFunctionSignature != _setup.updateFunctionSignature);
    validateFunction(_setup.createFunctionSignature);
    validateFunction(_setup.updateFunctionSignature);
        
    setupParameters.createFunctionSignature = _setup.createFunctionSignature;
    setupParameters.updateFunctionSignature = _setup.updateFunctionSignature;
    setupParameters.parametersCount = _setup.parameters.length;
    for(uint256 i = 0; i < _setup.parameters.length; i++) {
      validateTypeReference(_setup.parameters[i].parameter.typeReference, _setup.parameters[i].parameter.isArray);
      validateDescription(_setup.parameters[i].parameter.description);
      setupParameters.parameters[i] = _setup.parameters[i];
    }
  }
    
  function addActions(Action[] _actions) private {
    require(_actions.length > 0);
    
    for(uint256 i = 0; i < _actions.length; i++) {
      validateDescription(_actions[i].description);
      validateFunction(_actions[i].functionSignature);
      actions.push(ActionStorage(_actions[i].functionSignature, _actions[i].directlyCallFunction, _actions[i].parameters.length, _actions[i].description));
      for(uint256 j = 0; j < _actions[i].parameters.length; j++) {
        validateTypeReference(_actions[i].parameters[j].typeReference, _actions[i].parameters[j].isArray);
        validateDescription(_actions[i].parameters[j].description);
        actions[i].parameters[j] = _actions[i].parameters[j];
      }
    }
  }
    
  function addViewDatas(ViewData[] _viewDatas) private {
    for(uint256 i = 0; i < _viewDatas.length; i++) {
      validateFunction(_viewDatas[i].functionSignature);
      validateTypeReference(_viewDatas[i].output.typeReference, _viewDatas[i].output.isArray);
      validateDescription(_viewDatas[i].output.description);
      viewDatas.push(ViewDataStorage(_viewDatas[i].functionSignature));
      viewDatas[i].parameters[0] = _viewDatas[i].output;
    }
  }
}


contract ISmartAccount {
  function transferOwnership(address _newOwner) public;
  function executeCall(address _destination, uint256 _value, uint256 _gasLimit, bytes _data) public;
}


contract ManagerExtension {
  string public managerExtensionVersion = "0.0.1";

  mapping(address => bytes32[]) private identifier; //all extensions should define the identifier, it is necessary because the smart account can add the extension more than once
  mapping(bytes32 => uint256) private indexes;
  
  event SetIdentifier(address smartAccount, bytes32 identifier);
  event RemoveIdentifier(address smartAccount, bytes32 identifier);
  
  // Options are ROLE_TRANSFER_ETHER, ROLE_TRANSFER_TOKEN and/or ROLE_TRANSFER_OWNERSHIP
  function getRoles() pure public returns(bytes32[]);
  
  function setIdentifier(bytes32 _identifier) internal {
    bool alreadyExist = false;
    for (uint256 i = 0; i < identifier[msg.sender].length; ++i) {
      if (identifier[msg.sender][i] == _identifier) {
        alreadyExist = true;
        break;
      }
    }
    if (!alreadyExist) {
      indexes[keccak256(abi.encodePacked(msg.sender, _identifier))] = identifier[msg.sender].push(_identifier) - 1;
      emit SetIdentifier(msg.sender, _identifier);
    }
  }
  
  function removeIdentifier(bytes32 _identifier) internal {
    require(getIdentifiersCount(msg.sender) > 0);
    uint256 index = indexes[keccak256(abi.encodePacked(msg.sender, _identifier))];
    bytes32 indexReplacer = identifier[msg.sender][identifier[msg.sender].length - 1];
    identifier[msg.sender][index] = indexReplacer;
    indexes[keccak256(abi.encodePacked(msg.sender, indexReplacer))] = index;
    identifier[msg.sender].length--;
    emit RemoveIdentifier(msg.sender, _identifier);
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
    bytes memory data = abi.encodePacked(bytes4(keccak256("transfer(address,uint256)")), bytes32(_to), _amount);
    ISmartAccount(_smartAccount).executeCall(_tokenAddress, 0, 0, data);
  }
  
  function transferEtherFrom(address _smartAccount, address _to, uint256 _amount) internal {
    ISmartAccount(_smartAccount).executeCall(_to, _amount, 0, "");
  }
}


contract IExtension is UIExtension, ManagerExtension, AccountRoles {
}


//Simple Example 2
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
    return "Recurring Payment";
  }
  
  function getDescription() pure external returns(string) {
    return "Define an authorized address to withdraw a number of Ethers or Tokens for some recurrent period.";
  }
  
  function getSetupParameters() pure internal returns(Setup) {
    ConfigParameter[] memory parameters = new ConfigParameter[](6);
    parameters[0] = ConfigParameter(false, Parameter(false, false, ADDRESS, 0, "Beneficiary address"));
    parameters[1] = ConfigParameter(false, Parameter(false, false, INTEGER, 86400, "Recurrence time in days"));
    parameters[2] = ConfigParameter(true, Parameter(false, false, INTEGER, 0, "Number of periods"));
    parameters[3] = ConfigParameter(false, Parameter(false, false, BOOL, 0, "Payment in Ether"));
    parameters[4] = ConfigParameter(false, Parameter(false, true, ADDRESS, 0, "Token address if payment not in Ether"));
    parameters[5] = ConfigParameter(true, Parameter(false, false, FLOAT, 1000000000000000000, "Maximum amount per period"));
    return Setup(bytes4(keccak256("createSetup(address,uint256,uint256,bool,address,uint256)")), bytes4(keccak256("updateSetup(bytes32,address,uint256,uint256,bool,address,uint256)")), parameters);
  }
  
  function getActions() pure internal returns(Action[]) {
    Parameter[] memory parameters1 = new Parameter[](2);
    parameters1[0] = Parameter(false, false, SMARTACCOUNTADDRESS, 0, "Smart account");
    parameters1[1] = Parameter(false, false, FLOAT, 1000000000000000000, "Amount");
    Parameter[] memory parameters2 = new Parameter[](1);
    parameters2[0] = Parameter(false, false, ADDRESS, 0, "Beneficiary");
    Action[] memory action = new Action[](2);
    action[0].description = "Make a withdraw";
    action[0].parameters = parameters1;
    action[0].directlyCallFunction = true;
    action[0].functionSignature = bytes4(keccak256("withdrawal(address,uint256)"));
    action[1].description = "Cancel recurring payment";
    action[1].parameters = parameters2;
    action[1].functionSignature = bytes4(keccak256("cancelRecurringPayment(bytes32)"));
    return action;
  }
  
  function getViewDatas() pure internal returns(ViewData[]) {
    ViewData[] memory viewData = new ViewData[](3);
    viewData[0].functionSignature = bytes4(keccak256("getAvailableAmountWithdrawal(address,bytes32)"));
    viewData[0].output = Parameter(false, false, FLOAT, 1000000000000000000, "Available amount to withdrawal");
    viewData[1].functionSignature = bytes4(keccak256("getAmountWithdrawal(address,bytes32)"));
    viewData[1].output = Parameter(false, false, FLOAT, 1000000000000000000, "Amount released");
    viewData[2].functionSignature = bytes4(keccak256("getPeriodsWithdrawal(address,bytes32)"));
    viewData[2].output = Parameter(false, false, INTEGER, 0, "Amount of periods released");
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
      setIdentifier(bytes32(_beneficiary));
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
    removeIdentifier(bytes32(_beneficiary));
  }
  
  function withdrawal(address _smartAccount, uint256 _amount) external { 
    require(_amount > 0);
    require(configuration[_smartAccount][msg.sender].recurrenceTime > 0);
    bytes32 key = keccak256(abi.encodePacked(_smartAccount, bytes32(msg.sender)));
    require(paymentData[key].releasedPeriods == 0 || configuration[_smartAccount][msg.sender].periods > paymentData[key].releasedPeriods);
    
    uint256 allowedAmount;
    uint256 pendingPeriods;
    (allowedAmount, pendingPeriods) = getAllowedAmountAndPendingPeriods(_smartAccount, msg.sender, key);
    require(allowedAmount >= _amount);

    if (paymentData[key].start == 0) {
      paymentData[key].start = now;
    }
    paymentData[key].releasedPeriods = paymentData[key].releasedPeriods.add(pendingPeriods);
    paymentData[key].releasedPerPeriod[paymentData[key].releasedPeriods] = paymentData[key].releasedPerPeriod[paymentData[key].releasedPeriods].add(_amount); 
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
      uint256 pendingPeriods = min(secondsFromTheStart.div(configuration[_smartAccount][_beneficiary].recurrenceTime).add(1), configuration[_smartAccount][_beneficiary].periods.sub(paymentData[_key].releasedPeriods));
                                      
      if (pendingPeriods == 0) {
        return (configuration[_smartAccount][_beneficiary].maximumAmountPerPeriod.sub(paymentData[_key].releasedPerPeriod[paymentData[_key].releasedPeriods]), 0);
      } else {
        return (configuration[_smartAccount][_beneficiary].maximumAmountPerPeriod.mul(pendingPeriods), pendingPeriods);
      }
    }
  }
  
  function min(uint256 x, uint256 y) internal pure returns (uint256) {
    return x < y ? x : y;
  }
}