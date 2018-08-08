pragma solidity ^0.4.13;

interface ERC777TokensOperator {
  function madeOperatorForTokens(
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes userData,
    bytes operatorData
  ) public;
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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

interface ERC20Token {
    function name() public constant returns (string); //solium-disable-line no-constant
    function symbol() public constant returns (string); //solium-disable-line no-constant
    function decimals() public constant returns (uint8); //solium-disable-line no-constant
    function totalSupply() public constant returns (uint256); //solium-disable-line no-constant
    function balanceOf(address owner) public constant returns (uint256); //solium-disable-line no-constant
    function transfer(address to, uint256 amount) public returns (bool);
    function transferFrom(address from, address to, uint256 amount) public returns (bool);
    function approve(address spender, uint256 amount) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256); //solium-disable-line no-constant

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

contract ERC820Registry {
  function getManager(address addr) public view returns(address);
  function setManager(address addr, address newManager) public;
  function getInterfaceImplementer(address addr, bytes32 iHash) public view returns (address);
  function setInterfaceImplementer(address addr, bytes32 iHash, address implementer) public;
}

contract UnstructuredOwnable {
  /**
   * @dev Event to show ownership has been transferred
   * @param previousOwner representing the address of the previous owner
   * @param newOwner representing the address of the new owner
   */
  event OwnershipTransferred(address previousOwner, address newOwner);
  event OwnerSet(address newOwner);

  // Owner of the contract
  address private _owner;

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner());
    _;
  }

  /**
   * @dev The constructor sets the original owner of the contract to the sender account.
   */
  constructor () public {
    setOwner(msg.sender);
  }

  /**
   * @dev Tells the address of the owner
   * @return the address of the owner
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Sets a new owner address
   */
  function setOwner(address newOwner) internal {
    _owner = newOwner;
    emit OwnerSet(newOwner);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner(), newOwner);
    setOwner(newOwner);
  }
}

contract Pausable is UnstructuredOwnable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

interface Lockable {
    function lockAndDistributeTokens(
      address _tokenHolder, 
      uint256 _amount, 
      uint256 _percentageToLock, 
      uint256 _unlockTime
    ) public;
    function getAmountOfUnlockedTokens(address tokenOwner) public returns(uint);

    event LockedTokens(address indexed tokenHolder, uint256 amountToLock, uint256 unlockTime);
}

interface ERC777Token {
    function name() public view returns (string);
    function symbol() public view returns (string);
    function totalSupply() public view returns (uint256);
    function granularity() public view returns (uint256);
    function balanceOf(address owner) public view returns (uint256);

    function send(address to, uint256 amount) public;
    function send(address to, uint256 amount, bytes userData) public;

    function authorizeOperator(address operator) public;
    function revokeOperator(address operator) public;
    function isOperatorFor(address operator, address tokenHolder) public view returns (bool);
    function operatorSend(
      address from, 
      address to, 
      uint256 amount, 
      bytes userData, 
      bytes operatorData
    ) public;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes userData,
        bytes operatorData
    );
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes userData, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

interface ERC777TokensSender {
  function tokensToSend(
    address operator,
    address from,
    address to,
    uint amount,
    bytes userData,
    bytes operatorData
  ) public;
}

contract ERC820Implementer {
  ERC820Registry internal erc820Registry = ERC820Registry(0x991a1bcb077599290d7305493c9A630c20f8b798);
  //ERC820Implementer public erc820Registry;
  function setIntrospectionRegistry(address _erc820Registry) internal {
    erc820Registry = ERC820Registry(_erc820Registry);
  }

  function getIntrospectionRegistry() public view returns(address) {
    return erc820Registry;
  }

  function setInterfaceImplementation(string ifaceLabel, address impl) internal {
    bytes32 ifaceHash = keccak256(abi.encodePacked(ifaceLabel));
    erc820Registry.setInterfaceImplementer(this, ifaceHash, impl);
  }

  function interfaceAddr(address addr, string ifaceLabel) internal view returns(address) {
    bytes32 ifaceHash = keccak256(abi.encodePacked(ifaceLabel));
    return erc820Registry.getInterfaceImplementer(addr, ifaceHash);
  }

  function delegateManagement(address newManager) internal {
    erc820Registry.setManager(this, newManager);
  }
}

contract Basic777 is Pausable, ERC20Token, ERC777Token, Lockable, ERC820Implementer {
  using SafeMath for uint256;
  
  string private mName;
  string private mSymbol;
  uint256 private mGranularity;
  uint256 private mTotalSupply;
  bool private _initialized;
  
  bool private mErc20compatible;
  
  mapping(address => uint) private mBalances;
  mapping(address => lockedTokens) private mLockedBalances;
  mapping(address => mapping(address => bool)) private mAuthorized;
  mapping(address => mapping(address => uint256)) private mAllowed;
  
  struct lockedTokens {
    uint amount;
    uint256 timeLockedUntil;
  }
  
  /* -- Constructor -- */
  constructor () public { }
  
  /* -- Initializer -- */
  //
  /// @notice Constructor to create a ReferenceToken
  /// @param _name Name of the new token
  /// @param _symbol Symbol of the new token.
  /// @param _granularity Minimum transferable chunk.
  function initialize (
    string _name,
    string _symbol,
    uint256 _granularity,
    address _eip820RegistryAddr,
    address _owner
  )  public {
    require(!_initialized, "This contract has already been initialized. You can only do this once.");
    mName = _name;
    mSymbol = _symbol;
    mErc20compatible = true;
    setOwner(_owner);
    require(_granularity >= 1, "The granularity must be >= 1");
    mGranularity = _granularity;
    setIntrospectionRegistry(_eip820RegistryAddr);
    setInterfaceImplementation("ERC20Token", this);
    setInterfaceImplementation("ERC777Token", this);
    setInterfaceImplementation("Lockable", this);
    setInterfaceImplementation("Pausable", this);
    _initialized = true;
  }

  function initialized() public  view returns(bool) {
    return _initialized;
  }
  
  function getIntrospectionRegistry() public view returns(address){
    return address(erc820Registry);
  }
  
  /* -- ERC777 Interface Implementation -- */
  //
  /// @return the name of the token
  function name() public constant returns (string) { return mName; } //solium-disable-line no-constant
  
  /// @return the symbol of the token
  function symbol() public constant returns (string) { return mSymbol; } //solium-disable-line no-constant
  
  /// @return the granularity of the token
  function granularity() public view returns (uint256) { return mGranularity; }
  
  /// @return the total supply of the token
  function totalSupply() public constant returns (uint256) { return mTotalSupply; } //solium-disable-line no-constant
  
  /// @notice Return the account balance of some account
  /// @param _tokenHolder Address for which the balance is returned
  /// @return the balance of `_tokenAddress`.
  function balanceOf(address _tokenHolder) public constant returns (uint256) { //solium-disable-line no-constant
    return mBalances[_tokenHolder]; 
  }
  
  /// @notice Send `_amount` of tokens to address `_to`
  /// @param _to The address of the recipient
  /// @param _amount The number of tokens to be sent
  function send(address _to, uint256 _amount) public whenNotPaused {
    doSend(
      msg.sender, 
      _to, 
      _amount, 
      "", 
      msg.sender, 
      "", 
      true
    );
  }
  
  /// @notice Send `_amount` of tokens to address `_to` passing `_userData` to the recipient
  /// @param _to The address of the recipient
  /// @param _amount The number of tokens to be sent
  function send(address _to, uint256 _amount, bytes _userData) public whenNotPaused {
    doSend(
      msg.sender, 
      _to, 
      _amount, 
      _userData, 
      msg.sender, 
      "", 
      true
    );
  }
  
  /// @notice Authorize a third party `_operator` to manage (send) `msg.sender`&#39;s tokens.
  /// @param _operator The operator that wants to be Authorized
  function authorizeOperator(address _operator) public whenNotPaused {
    require(_operator != msg.sender, "You cannot authorize yourself as an operator");
    mAuthorized[_operator][msg.sender] = true;
    emit AuthorizedOperator(_operator, msg.sender);
  }
  
  /// @notice extended 777 approveAndCall and erc20 approve functionality that gives an allowance and calls the new operator.
  ///  `msg.sender` approves `_spender` to spend `_amount` tokens on its behalf.
  /// @param _operator The address of the account able to transfer the tokens
  /// @param _amount The number of tokens to be approved for transfer
  /// @dev to revoke the operator of SOME allowance simply call it again as it will overwrite its previous allowance.
  /// @return `true`, if the approve can&#39;t be done, it should fail.
  function approveAndCall(address _operator, uint256 _amount, bytes _operatorData) public whenNotPaused returns (bool success) {
    uint balanceAvailable = getAmountOfUnlockedTokens(msg.sender);
    require(balanceAvailable >= _amount, "The amount of unlocked tokens must be >= the amount sent");
    mAllowed[msg.sender][_operator] = _amount;
    callOperator(
      _operator, 
      msg.sender, 
      _operator, 
      _amount, 
      "0x0", 
      _operatorData, 
      true
    );
    emit Approval(msg.sender, _operator, _amount);
    return true;
  }
  
  /// @notice Revoke a third party `_operator`&#39;s rights to manage (send) `msg.sender`&#39;s tokens.
  /// @param _operator The operator that wants to be Revoked
  function revokeOperator(address _operator) public whenNotPaused {
    require(_operator != msg.sender, "You cannot authorize yourself as an operator");
    mAuthorized[_operator][msg.sender] = false;
    emit RevokedOperator(_operator, msg.sender);
  }
  
  /// @notice Check whether the `_operator` address is allowed to manage the tokens held by `_tokenHolder` address.
  /// @param _operator address to check if it has the right to manage the tokens
  /// @param _tokenHolder address which holds the tokens to be managed
  /// @return `true` if `_operator` is authorized for `_tokenHolder`
  function isOperatorFor(address _operator, address _tokenHolder) public view returns (bool) {
    return _operator == _tokenHolder || mAuthorized[_operator][_tokenHolder];
  }
  
  /// @notice Send `_amount` of tokens on behalf of the address `from` to the address `to`.
  /// @param _from The address holding the tokens being sent
  /// @param _to The address of the recipient
  /// @param _amount The number of tokens to be sent
  /// @param _userData Data generated by the user to be sent to the recipient
  /// @param _operatorData Data generated by the operator to be sent to the recipient
  function operatorSend(
    address _from, 
    address _to, 
    uint256 _amount, 
    bytes _userData, 
    bytes _operatorData
  ) public whenNotPaused {
    require(isOperatorFor(msg.sender, _from), "Only an approved operator can use operatorSend");
    doSend(
      _from, 
      _to, 
      _amount, 
      _userData, 
      msg.sender, 
      _operatorData, 
      true
    );
  }
  
  /* -- Mint And Burn Functions (not part of the ERC777 standard, only the Events/tokensReceived are) -- */
  //
  /// @notice Generates `_amount` tokens to be assigned to `_tokenHolder`
  ///  Sample mint function to showcase the use of the `Minted` event and the logic to notify the recipient.
  /// @param _tokenHolder The address that will be assigned the new tokens
  /// @param _amount The quantity of tokens generated
  /// @param _operatorData Data that will be passed to the recipient as a first transfer
  function mint(address _tokenHolder, uint256 _amount, bytes _operatorData) public onlyOwner {
    requireMultiple(_amount);
    mTotalSupply = mTotalSupply.add(_amount);
    mBalances[_tokenHolder] = mBalances[_tokenHolder].add(_amount);
    
    callRecipient(
      msg.sender, 
      0x0, 
      _tokenHolder, 
      _amount, 
      "", 
      _operatorData, 
      true
    );
    
    emit Minted(
      msg.sender, 
      _tokenHolder, 
      _amount, 
      _operatorData
    );
    if (mErc20compatible) { 
      emit Transfer(0x0, _tokenHolder, _amount); 
    }
  }

  function burn(uint256 _amount, bytes _holderData) public whenNotPaused {
    doBurn(
      msg.sender, 
      msg.sender, 
      _amount, 
      _holderData, 
      ""
    );
  }

  function operatorBurn(
    address _tokenHolder, 
    uint256 _amount, 
    bytes _holderData, 
    bytes _operatorData
  ) public whenNotPaused {
    require(isOperatorFor(msg.sender, _tokenHolder), "Only and approved operator can use operatorBurn");
    doBurn(
      msg.sender, 
      _tokenHolder, 
      _amount, 
      _holderData, 
      _operatorData
    );
  }

  /// @notice Helper function actually performing the burning of tokens.
  /// @param _operator The address performing the burn
  /// @param _tokenHolder The address holding the tokens being burn
  /// @param _amount The number of tokens to be burnt
  /// @param _holderData Data generated by the token holder
  /// @param _operatorData Data generated by the operator
  function doBurn(
    address _operator, 
    address _tokenHolder, 
    uint256 _amount, 
    bytes _holderData, 
    bytes _operatorData
  ) internal whenNotPaused {
    requireMultiple(_amount);
    uint balanceAvailable = getAmountOfUnlockedTokens(_tokenHolder);
    require(
      balanceAvailable >= _amount, 
      "You can only burn tokens when you have a balance grater than or equal to the amount specified"
    );

    mBalances[_tokenHolder] = mBalances[_tokenHolder].sub(_amount);
    mTotalSupply = mTotalSupply.sub(_amount);
    
    callSender(
      _operator, 
      _tokenHolder, 
      0x0, 
      _amount, 
      _holderData, 
      _operatorData
    );
    
    emit Burned(
      _operator, 
      _tokenHolder, 
      _amount, 
      _holderData, 
      _operatorData
    );
  }
  
  /* -- ERC20 Compatible Methods -- */
  //
  /// @notice This modifier is applied to erc20 obsolete methods that are
  ///  implemented only to maintain backwards compatibility. When the erc20
  ///  compatibility is disabled, this methods will fail.
  modifier erc20 () {
    require(mErc20compatible, "You can only use this function when the &#39;ERC20Token&#39; interface is enabled");
    _;
  }
  
  /// @notice Disables the ERC20 interface. This function can only be called
  ///  by the owner.
  function disableERC20() public onlyOwner {
    mErc20compatible = false;
    setInterfaceImplementation("ERC20Token", 0x0);
  }
  
  /// @notice Re enables the ERC20 interface. This function can only be called
  ///  by the owner.
  function enableERC20() public onlyOwner {
    mErc20compatible = true;
    setInterfaceImplementation("ERC20Token", this);
  }
  
  /// @notice For Backwards compatibility
  /// @return The decimls of the token. Forced to 18 in ERC777.
  function decimals() public erc20 view returns (uint8) { return uint8(18); } //solium-disable-line no-constant
  
  /// @notice ERC20 backwards compatible transfer.
  /// @param _to The address of the recipient
  /// @param _amount The number of tokens to be transferred
  /// @return `true`, if the transfer can&#39;t be done, it should fail.
  function transfer(address _to, uint256 _amount) public whenNotPaused erc20 returns (bool success) {
    doSend(
      msg.sender, 
      _to, 
      _amount, 
      "", 
      msg.sender, 
      "", 
      false
    );
    return true;
  }
  
  /// @notice ERC20 backwards compatible transferFrom.
  /// @param _from The address holding the tokens being transferred
  /// @param _to The address of the recipient
  /// @param _amount The number of tokens to be transferred
  /// @return `true`, if the transfer can&#39;t be done, it should fail.
  function transferFrom(address _from, address _to, uint256 _amount) public whenNotPaused erc20 returns (bool success) {
    uint balanceAvailable = getAmountOfUnlockedTokens(_from);
    require(
      balanceAvailable >= _amount, 
      "You can only use transferFrom when you specify an amount of tokens >= the &#39;_from&#39; address&#39;s amount of unlocked tokens"
    );
    require(
      _amount <= mAllowed[_from][msg.sender],
      "You can only use transferFrom with an amount less than or equal to the current &#39;mAllowed&#39; allowance."
    );
    
    // Cannot be after doSend because of tokensReceived re-entry
    mAllowed[_from][msg.sender] = mAllowed[_from][msg.sender].sub(_amount);
    doSend(
      _from, 
      _to, 
      _amount, 
      "", 
      msg.sender, 
      "", 
      false
    );
    return true;
  }
  
  /// @notice ERC20 backwards compatible approve.
  ///  `msg.sender` approves `_spender` to spend `_amount` tokens on its behalf.
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _amount The number of tokens to be approved for transfer
  /// @return `true`, if the approve can&#39;t be done, it should fail.
  function approve(address _spender, uint256 _amount) public whenNotPaused erc20 returns (bool success) {
    uint balanceAvailable = getAmountOfUnlockedTokens(msg.sender);
    require(
      balanceAvailable >= _amount, 
      "You can only approve an amount >= the amount of tokens currently unlocked for this account"
    );
    mAllowed[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }
  
  /// @notice ERC20 backwards compatible allowance.
  ///  This function makes it easy to read the `allowed[]` map
  /// @param _owner The address of the account that owns the token
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens of _owner that _spender is allowed
  ///  to spend
  function allowance(address _owner, address _spender) public erc20 constant returns (uint256 remaining) { //solium-disable-line no-constant
    return mAllowed[_owner][_spender];
  }
  
  /* -- Helper Functions -- */
  //
  /// @notice Internal function that ensures `_amount` is multiple of the granularity
  /// @param _amount The quantity that want&#39;s to be checked
  function requireMultiple(uint256 _amount) internal view {
    require(
      _amount.div(mGranularity).mul(mGranularity) == _amount, 
      "You can only use tokens using the granularity currently set."
    );
  }
  
  /// @notice Check whether an address is a regular address or not.
  /// @param _addr Address of the contract that has to be checked
  /// @return `true` if `_addr` is a regular address (not a contract)
  function isRegularAddress(address _addr) internal view returns(bool) {
    if (_addr == 0) { 
      return false; 
    }
    uint size;
    assembly { size := extcodesize(_addr) } //solium-disable-line security/no-inline-assembly
    return size == 0;
  }
  
  /// @notice Helper function actually performing the sending of tokens.
  /// @param _from The address holding the tokens being sent
  /// @param _to The address of the recipient
  /// @param _amount The number of tokens to be sent
  /// @param _userData Data generated by the user to be passed to the recipient
  /// @param _operatorData Data generated by the operator to be passed to the recipient
  /// @param _preventLocking `true` if you want this function to throw when tokens are sent to a contract not
  ///  implementing `erc777_tokenHolder`.
  ///  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
  ///  functions SHOULD set this parameter to `false`.
  function doSend(
    address _from,
    address _to,
    uint256 _amount,
    bytes _userData,
    address _operator,
    bytes _operatorData,
    bool _preventLocking
  ) private whenNotPaused {
    requireMultiple(_amount);
    uint balanceAvailable = getAmountOfUnlockedTokens(_from);
    
    callSender(
      _operator, 
      _from, 
      _to, 
      _amount, 
      _userData, 
      _operatorData
    );
    
    require(
      _to != address(0), 
      "You cannot invoke doSend with a the burn address (0x0) as the recipient &#39;to&#39; address"
    );          // forbid sending to 0x0 (=burning)
    require(
      balanceAvailable >= _amount, 
      "You can only invoke doSend when the &#39;from&#39; address has an unlocked balance >= the &#39;_amount&#39; sent"
    ); // ensure enough funds
    
    mBalances[_from] = mBalances[_from].sub(_amount);
    mBalances[_to] = mBalances[_to].add(_amount);
    
    callRecipient(
      _operator, 
      _from, 
      _to, 
      _amount, 
      _userData, 
      _operatorData, 
      _preventLocking
    );
    
    emit Sent(
      _operator, 
      _from, 
      _to, 
      _amount, 
      _userData, 
      _operatorData
    );
    if (mErc20compatible) { 
      emit Transfer(_from, _to, _amount); 
    }
  }
  
  /// @notice Helper function that checks for ERC777TokensRecipient on the recipient and calls it.
  ///  May throw according to `_preventLocking`
  /// @param _from The address holding the tokens being sent
  /// @param _to The address of the recipient
  /// @param _amount The number of tokens to be sent
  /// @param _userData Data generated by the user to be passed to the recipient
  /// @param _operatorData Data generated by the operator to be passed to the recipient
  /// @param _preventLocking `true` if you want this function to throw when tokens are sent to a contract not
  ///  implementing `ERC777TokensRecipient`.
  ///  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
  ///  functions SHOULD set this parameter to `false`.
  function callRecipient(
    address _operator,
    address _from,
    address _to,
    uint256 _amount,
    bytes _userData,
    bytes _operatorData,
    bool _preventLocking
  ) private {
    address recipientImplementation = interfaceAddr(_to, "ERC777TokensRecipient");
    if (recipientImplementation != 0) {
      ERC777TokensRecipient(recipientImplementation).tokensReceived(
        _operator, 
        _from, 
        _to, 
        _amount, 
        _userData, 
        _operatorData
      );
    } else if (_preventLocking) {
      require(
        isRegularAddress(_to),
        "When &#39;_preventLocking&#39; is true, you cannot invoke &#39;callOperator&#39; to a contract address that does not support the &#39;ERC777TokensOperator&#39; interface"
      );
    }
  }
  
  /// @notice Helper function that checks for ERC777TokensSender on the sender and calls it.
  ///  May throw according to `_preventLocking`
  /// @param _from The address holding the tokens being sent
  /// @param _to The address of the recipient
  /// @param _amount The amount of tokens to be sent
  /// @param _userData Data generated by the user to be passed to the recipient
  /// @param _operatorData Data generated by the operator to be passed to the recipient
  ///  implementing `ERC777TokensSender`.
  ///  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
  ///  functions SHOULD set this parameter to `false`.
  function callSender(
    address _operator,
    address _from,
    address _to,
    uint256 _amount,
    bytes _userData,
    bytes _operatorData
  ) private whenNotPaused {
    address senderImplementation = interfaceAddr(_from, "ERC777TokensSender");
    if (senderImplementation != 0) {
      ERC777TokensSender(senderImplementation).tokensToSend(
        _operator, 
        _from, 
        _to, 
        _amount, 
        _userData, 
        _operatorData
      );
    }
  }
  
  /// @notice Helper function that checks for IEIP777TokensOperator on the recipient and calls it.
  ///  May throw according to `_preventLocking`
  /// @param _from The address holding the tokens being sent
  /// @param _to The address of the recipient
  /// @param _value The amount of tokens to be sent
  /// @param _userData Data generated by the user to be passed to the recipient
  /// @param _operatorData Data generated by the operator to be passed to the recipient
  /// @param _preventLocking `true` if you want this function to throw when tokens are sent to a contract not
  ///  implementing `IEIP777TokensOperator`
  ///  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
  ///  functions SHOULD set this parameter to `false`.
  function callOperator(
    address _operator,
    address _from,
    address _to,
    uint256 _value,
    bytes _userData,
    bytes _operatorData,
    bool _preventLocking
  ) private {
    address recipientImplementation = interfaceAddr(_to, "ERC777TokensOperator");
    if (recipientImplementation != 0) {
      ERC777TokensOperator(recipientImplementation).madeOperatorForTokens(
        _operator, 
        _from, 
        _to, 
        _value, 
        _userData, 
        _operatorData
      );
    } else if (_preventLocking) {
      require(
        isRegularAddress(_to),
        "When &#39;_preventLocking&#39; is true, you cannot invoke &#39;callOperator&#39; to a contract address that does not support the &#39;ERC777TokensOperator&#39; interface"
      );
    }
  }
  
  /// @notice locks a percentage of tokens for a specified time period and then grants ownership to the specified owner
  /// @param _tokenHolder The address to give the tokens to
  /// @param _amount The amount of tokens to give the holder (the immediate amount including the amount to lock)
  /// @param _percentageToLock the percentage of the distributed tokens to lock
  /// @param _unlockTime the block.timestamp to unlock the tokens at
  function lockAndDistributeTokens(
    address _tokenHolder, 
    uint256 _amount, 
    uint256 _percentageToLock, 
    uint256 _unlockTime
  ) public onlyOwner {
    requireMultiple(_amount);
    require(
      _percentageToLock <= 100 && 
      _percentageToLock > 0, 
      "You can only lock a percentage between 0 and 100."
    );
    require(
      mLockedBalances[_tokenHolder].amount == 0, 
      "You can only lock one amount of tokens for a given address. It is currently indicating that there are already locked tokens for this address."
    );
    uint256 amountToLock = _amount.mul(_percentageToLock).div(100);
    mBalances[msg.sender] = mBalances[msg.sender].sub(_amount);
    mBalances[_tokenHolder] = mBalances[_tokenHolder].add(_amount);
    mLockedBalances[_tokenHolder] = lockedTokens({
      amount: amountToLock,
      timeLockedUntil: _unlockTime
    });
    
    callRecipient(
      msg.sender, 
      0x0, 
      _tokenHolder, 
      _amount, 
      "", 
      "", 
      true
    );

    emit LockedTokens(_tokenHolder, amountToLock, _unlockTime);
    
    if (mErc20compatible) { 
      emit Transfer(0x0, _tokenHolder, _amount); 
    }
  }
  
  /// @notice Helper function that returns the amount of tokens aof an owner minus the amount currently locked
  /// @param _tokenOwner The address holding the tokens
  function getAmountOfUnlockedTokens(address _tokenOwner) public returns(uint) {
    uint balanceAvailable = mBalances[_tokenOwner];
    if (
      mLockedBalances[_tokenOwner].amount != 0 && 
      mLockedBalances[_tokenOwner].timeLockedUntil > block.timestamp //solium-disable-line security/no-block-members
    ){
      balanceAvailable = balanceAvailable.sub(mLockedBalances[_tokenOwner].amount);
    } else if (
      mLockedBalances[_tokenOwner].amount != 0 && 
      mLockedBalances[_tokenOwner].timeLockedUntil < block.timestamp //solium-disable-line security/no-block-members
    ) {
      mLockedBalances[_tokenOwner] = lockedTokens({
        amount: 0,
        timeLockedUntil: 0
      }); //todo wrtie test to check if cleared
    }
    return balanceAvailable;
  }
}

contract KPXV0_1_0 is Basic777 {
  constructor() public Basic777() { }
}

interface ERC777TokensRecipient {
  function tokensReceived(
    address operator,
    address from,
    address to,
    uint amount,
    bytes userData,
    bytes operatorData
  ) public;
}