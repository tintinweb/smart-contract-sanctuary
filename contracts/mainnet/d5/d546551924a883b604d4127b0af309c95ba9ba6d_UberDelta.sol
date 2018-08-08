pragma solidity ^0.4.19;

// 
// UberDelta Exchange Contract - v1.0.0
// 
//  www.uberdelta.com
//

contract Token {
  function balanceOf(address _owner) public view returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function approve(address _spender, uint256 _value) public returns (bool success);
}

contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    require(c / a == b);
    return c;
  }
  
  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b > 0); //gentler than an assert.
    c = a / b;
    return c;
  }


  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }


  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a);
    return c;
  }
}

contract OwnerManager {

  address public owner;
  address public newOwner;
  address public manager;

  event OwnershipTransferProposed(address indexed _from, address indexed _to);
  event OwnershipTransferConfirmed(address indexed _from, address indexed _to);
  event NewManager(address indexed _newManager);


  modifier onlyOwner {
    assert(msg.sender == owner);
    _;
  }
  
  modifier onlyManager {
    assert(msg.sender == manager);
    _;
  }


  function OwnerManager() public{
    owner = msg.sender;
    manager = msg.sender;
  }


  function transferOwnership(address _newOwner) onlyOwner external{
    require(_newOwner != owner);
    
    OwnershipTransferProposed(owner, _newOwner);
    
    newOwner = _newOwner;
  }


  function confirmOwnership() external {
    assert(msg.sender == newOwner);
    
    OwnershipTransferConfirmed(owner, newOwner);
    
    owner = newOwner;
  }


  function newManager(address _newManager) onlyOwner external{
    require(_newManager != address(0x0));
    
    NewManager(_newManager);
    
    manager = _newManager;
  }

}


contract Helper is OwnerManager {

  mapping (address => bool) public isHelper;

  modifier onlyHelper {
    assert(isHelper[msg.sender] == true);
    _;
  }

  event ChangeHelper(
    address indexed helper,
    bool status
  );

  function Helper() public{
    isHelper[msg.sender] = true;
  }

  function changeHelper(address _helper, bool _status) external onlyManager {
	  ChangeHelper(_helper, _status);
    isHelper[_helper] = _status;
  }

}


contract Compliance {
  function canDeposit(address _user) public view returns (bool isAllowed);
  function canTrade(address _token, address _user) public view returns (bool isAllowed);
  function validateTrade(
    address _token,
    address _getUser,
    address _giveUser
  )
    public
    view
    returns (bool isAllowed)
  ;
}

contract OptionRegistry {
  function registerOptionPair(
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires
  )
  public
  returns(bool)
  ;
  
  function isOptionPairRegistered(
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires
  )
  public
  view
  returns(bool)  
  ;
  
}

contract EOS {
    function register(string key) public;
}

contract UberDelta is SafeMath, OwnerManager, Helper {

  // The account that will receive fees
  address public feeAccount;
  
  // The account that will receive lost ERC20 tokens
  address public sweepAccount;
  
  // The address of the compliance engine
  address public complianceAddress;
  
  // The address of the options registry
  address public optionsRegistryAddress;
  
  // The address of the next exchange contract
  address public newExchange;

  // Turn off deposits and trades, allow upgrade and withdraw
  bool public contractLocked;
  
  bytes32 signedTradeHash = keccak256(
    "address contractAddress",
    "address takerTokenAddress",
    "uint256 takerTokenAmount",
    "address makerTokenAddress",
    "uint256 makerTokenAmount",
    "uint256 tradeExpires",
    "uint256 salt",
    "address maker",
    "address restrictedTo"
  );
  
  bytes32 signedWithdrawHash = keccak256(
    "address contractAddress",
    "uint256 amount",
    "uint256 fee",
    "uint256 withdrawExpires",
    "uint256 salt",
    "address maker",
    "address restrictedTo"
  );


  // Balance per token, for each user.
  mapping (address => mapping (address => uint256)) public balances;
  
  // global token balance tracking (to detect lost tokens)
  mapping (address => uint256) public globalBalance;
  
  // List of orders created by calling the exchange contract directly.
  mapping (bytes32 => bool) public orders;
  
  // Lists the amount of each order that has been filled or cancelled.
  mapping (bytes32 => uint256) public orderFills;
  
  // Tokens that need to be checked through the compliance engine.
  mapping (address => bool) public restrictedTokens;

  // Mapping of fees by user class (default class == 0x0)
  mapping (uint256 => uint256) public feeByClass;
  
  // Mapping of users to user classes.
  mapping (address => uint256) public userClass; 
  
  
  /*******************************************
  / Exchange Regular Events
  /******************************************/
  
  // Note: Order creation is usually off-chain
  event Order(
    bytes32 indexed tradePair,
    address indexed maker,
    address[4] addressData,
    uint256[4] numberData
  );
  
  event Cancel(
    bytes32 indexed tradePair,
    address indexed maker,
    address[4] addressData,
    uint256[4] numberData,
    uint256 status
  );
  
   event FailedTrade( 
    bytes32 indexed tradePair,
    address indexed taker,
    bytes32 hash,
    uint256 failReason
  ); 
  
  event Trade( 
    bytes32 indexed tradePair,
    address indexed maker,
    address indexed taker,
    address makerToken,
    address takerToken,
    address restrictedTo,
    uint256[4] numberData,
    uint256 tradeAmount,
    bool fillOrKill
  );
  
  event Deposit(
    address indexed token,
    address indexed toUser,
    address indexed sender,
    uint256 amount
  );
  
  event Withdraw(
    address indexed token,
    address indexed toUser,
    uint256 amount
  );

  event InternalTransfer(
    address indexed token,
    address indexed toUser,
    address indexed sender,
    uint256 amount
  );

  event TokenSweep(
    address indexed token,
    address indexed sweeper,
    uint256 amount,
    uint256 balance
  );
  
  event RestrictToken(
    address indexed token,
    bool status
  );
  
  event NewExchange(
    address newExchange
  );
  
  event ChangeFeeAccount(
    address feeAccount
  );
  
  event ChangeSweepAccount(
    address sweepAccount
  );
  
  event ChangeClassFee(
    uint256 indexed class,
    uint256 fee
  );
  
  event ChangeUserClass(
    address indexed user,
    uint256 class
  );
  
  event LockContract(
    bool status
  );
  
  event UpdateComplianceAddress(
    address newComplianceAddress
  );
  
  event UpdateOptionsRegistryAddress(
    address newOptionsRegistryAddress
  );
  
  event Upgrade(
    address indexed user,
    address indexed token,
    address newExchange,
    uint256 amount
  );
  
  event RemoteWithdraw(
    address indexed maker,
    address indexed sender,
    uint256 withdrawAmount,
    uint256 feeAmount,
    uint256 withdrawExpires,
    uint256 salt,
    address restrictedTo
  );
  
  event CancelRemoteWithdraw(
    address indexed maker,
    uint256 withdrawAmount,
    uint256 feeAmount,
    uint256 withdrawExpires,
    uint256 salt,
    address restrictedTo,
    uint256 status
  );

  //Constructor Function, set initial values.
  function UberDelta() public {
    feeAccount = owner;
    sweepAccount = owner;
    feeByClass[0x0] = 3000000000000000;
    contractLocked = false;
    complianceAddress = this;
    optionsRegistryAddress = this;
  }


  // Prevent raw sends of Eth.
  function() public {
    revert();
  }
  
  
  
  /*******************************************
  / Contract Control Functions
  /******************************************/
  function changeNewExchange(address _newExchange) external onlyOwner {
    //since _newExchange being zero turns off the upgrade function, lets
    //allow this to be reset to 0x0.
    
    newExchange = _newExchange;
    
    NewExchange(_newExchange);
  }


  function changeFeeAccount(address _feeAccount) external onlyManager {
    require(_feeAccount != address(0x0));
    
    feeAccount = _feeAccount;
    
    ChangeFeeAccount(_feeAccount);
  }

  function changeSweepAccount(address _sweepAccount) external onlyManager {
    require(_sweepAccount != address(0x0));
    
    sweepAccount = _sweepAccount;
    
    ChangeSweepAccount(_sweepAccount);
  }

  function changeClassFee(uint256 _class, uint256 _fee) external onlyManager {
    require(_fee <= 10000000000000000); //Max 1%.

    feeByClass[_class] = _fee;

    ChangeClassFee(_class, _fee);
  }
  
  function changeUserClass(address _user, uint256 _newClass) external onlyHelper {
    userClass[_user] = _newClass;
    
    ChangeUserClass(_user, _newClass);
  }
  
  //Turn off deposits and trades, but still allow withdrawals and upgrades.
  function lockContract(bool _lock) external onlyManager {
    contractLocked = _lock;
    
    LockContract(_lock);
  }
  
  function updateComplianceAddress(address _newComplianceAddress)
    external
    onlyManager
  {
    complianceAddress = _newComplianceAddress;
    
    UpdateComplianceAddress(_newComplianceAddress);
  }

  function updateOptionsRegistryAddress(address _newOptionsRegistryAddress)
    external
    onlyManager
  {
    optionsRegistryAddress = _newOptionsRegistryAddress;
    
    UpdateOptionsRegistryAddress(_newOptionsRegistryAddress);
  }


  // restriction function for tokens that need additional verifications
  function tokenRestriction(address _newToken, bool _status) external onlyHelper {
    restrictedTokens[_newToken] = _status;
    
    RestrictToken(_newToken, _status);
  }

  
  //Turn off deposits and trades, but still allow withdrawals and upgrades.
  modifier notLocked() {
    require(!contractLocked);
    _;
  }
  
  
  /*******************************************************
  / Deposit/Withdrawal/Transfer
  /
  / In all of the following functions, it should be noted
  / that the 0x0 address is used to represent ETH.
  /******************************************************/
  
  // SafeMath sanity checks inputs in deposit(), withdraw(), and token functions.
  
  // Deposit ETH in the contract to trade with
  function deposit() external notLocked payable returns(uint256) {
    require(Compliance(complianceAddress).canDeposit(msg.sender)); 
    // defaults to true until we change compliance code
    
    balances[address(0x0)][msg.sender] = safeAdd(balances[address(0x0)][msg.sender], msg.value);
    globalBalance[address(0x0)] = safeAdd(globalBalance[address(0x0)], msg.value);

    Deposit(0x0, msg.sender, msg.sender, msg.value);
    
    return(msg.value);
  }

  // Withdraw ETH from the contract to your wallet  (internal transaction on etherscan)
  function withdraw(uint256 _amount) external returns(uint256) {
    //require(balances[address(0x0)][msg.sender] >= _amount);
    //handled by safeSub.
    
    balances[address(0x0)][msg.sender] = safeSub(balances[address(0x0)][msg.sender], _amount);
    globalBalance[address(0x0)] = safeSub(globalBalance[address(0x0)], _amount);
 
    //transfer has a built in require
    msg.sender.transfer(_amount);
    
    Withdraw(0x0, msg.sender, _amount);
    
    return(_amount);
  }


  // Deposit ERC20 tokens in the contract to trade with
  // Token(_token).approve(this, _amount) must be called in advance
  // ERC223 tokens must be deposited by a transfer to this contract ( see tokenFallBack(..) )
  function depositToken(address _token, uint256 _amount) external notLocked returns(uint256) {
    require(_token != address(0x0));
    
    require(Compliance(complianceAddress).canDeposit(msg.sender));

    balances[_token][msg.sender] = safeAdd(balances[_token][msg.sender], _amount);
    globalBalance[_token] = safeAdd(globalBalance[_token], _amount);
    
    require(Token(_token).transferFrom(msg.sender, this, _amount));

    Deposit(_token, msg.sender, msg.sender, _amount);
    
    return(_amount);
  }

  // Withdraw ERC20/223 tokens from the contract back to your wallet
  function withdrawToken(address _token, uint256 _amount)
    external
    returns (uint256)
  {
    if (_token == address(0x0)){
      //keep the nulls to reduce gas usage.
      //require(balances[_token)][msg.sender] >= _amount);
      //handled by safeSub.
      balances[address(0x0)][msg.sender] = safeSub(balances[address(0x0)][msg.sender], _amount);
      globalBalance[address(0x0)] = safeSub(globalBalance[address(0x0)], _amount);

      //transfer has a built in require
      msg.sender.transfer(_amount);
    } else {
      //require(balances[_token][msg.sender] >= _amount);
      //handled by safeSub 
 
      balances[_token][msg.sender] = safeSub(balances[_token][msg.sender], _amount);
      globalBalance[_token] = safeSub(globalBalance[_token], _amount);

      require(Token(_token).transfer(msg.sender, _amount));
    }    

    Withdraw(_token, msg.sender, _amount);
    
    return _amount;
  }

  // Deposit ETH in the contract on behalf of another address
  // Warning: afterwards, only _user will be able to trade or withdraw these funds
  function depositToUser(address _toUser) external payable notLocked returns (bool success) {
    require(
        (_toUser != address(0x0))
     && (_toUser != address(this))
     && (Compliance(complianceAddress).canDeposit(_toUser))
    );
    
    balances[address(0x0)][_toUser] = safeAdd(balances[address(0x0)][_toUser], msg.value);
    globalBalance[address(0x0)] = safeAdd(globalBalance[address(0x0)], msg.value);
    
    Deposit(0x0, _toUser, msg.sender, msg.value);
    
    return true;
  }

  // Deposit ERC20 tokens in the contract on behalf of another address
  // Token(_token).approve(this, _amount) must be called in advance
  // Warning: afterwards, only _toUser will be able to trade or withdraw these funds
  // ERC223 tokens must be deposited by a transfer to this contract ( see tokenFallBack(..) )
  function depositTokenToUser(
    address _toUser,
    address _token,
    uint256 _amount
  )
    external
    notLocked
    returns (bool success)
  {
    require(
        (_token != address(0x0))

     && (_toUser  != address(0x0))
     && (_toUser  != address(this))
     && (_toUser  != _token)
     && (Compliance(complianceAddress).canDeposit(_toUser))
    );
    
    balances[_token][_toUser] = safeAdd(balances[_token][_toUser], _amount);
    globalBalance[_token] = safeAdd(globalBalance[_token], _amount);

    require(Token(_token).transferFrom(msg.sender, this, _amount));

    Deposit(_token, _toUser, msg.sender, _amount);
    
    return true;
  }


  //ERC223 Token Acceptor function, called when an ERC2223 token is transferred to this contract
  // provide _sendTo to make it a deposit on behalf of another address (depositToUser)
  function tokenFallback(
    address _from,  // user calling the function
    uint256 _value, // the number of tokens
    bytes _sendTo     // "deposit to other user" if exactly 20 bytes sent
    
  )
    external
    notLocked
  {
    //first lets figure out who this is going to.
    address toUser = _from;     //probably this
    if (_sendTo.length == 20){  //but use data for sendTo otherwise.

      // I&#39;m about 90% sure I don&#39;t need to do the casting here, but for
      // like twenty gas, I&#39;ll take the protection from potentially
      // stomping on weird memory locations.
      
      uint256 asmAddress;
      assembly { //uses 50 gas
        asmAddress := calldataload(120)
      }
      toUser = address(asmAddress);
    }
    
    //sanity checks.
    require(
        (toUser != address(0x0))
     && (toUser != address(this))
     && (toUser != msg.sender)  // msg.sender is the token
     && (Compliance(complianceAddress).canDeposit(toUser))
    );
    
    // check if a contract is calling this
    uint256 codeLength;
    assembly {
      codeLength := extcodesize(caller)
    }
    require(codeLength > 0);    
    
    globalBalance[msg.sender] = safeAdd(globalBalance[msg.sender], _value);
    balances[msg.sender][toUser] = safeAdd(balances[msg.sender][toUser], _value);
    
    //sanity check, and as a perk, we check for balanceOf();
    require(Token(msg.sender).balanceOf(this) >= _value);

    Deposit(msg.sender, toUser, _from, _value);
  }

  // Move deposited tokens or ETH (0x0) from one to another address within the contract
  function internalTransfer(
    address _toUser,
    address _token,
    uint256 _amount
  )
    external
    notLocked 
    returns(uint256)
  {
    require(
        (balances[_token][msg.sender] >= _amount)
     && (_toUser != address(0x0))
     && (_toUser != address(this))
     && (_toUser != _token)
     && (Compliance(complianceAddress).canDeposit(_toUser))
    );
 
    balances[_token][msg.sender] = safeSub(balances[_token][msg.sender], _amount);
    balances[_token][_toUser] = safeAdd(balances[_token][_toUser], _amount);

    InternalTransfer(_token, _toUser, msg.sender, _amount);
    
    return(_amount);
  }
  
  // return the token/ETH balance a user has deposited in the contract
  function balanceOf(address _token, address _user) external view returns (uint) {
    return balances[_token][_user];
  }

  
  // In order to see the ERC20 total balance, we&#39;re calling an external contract,
  // and this contract claims to be ERC20, but we don&#39;t know what&#39;s really there.
  // We can&#39;t rely on the EVM or solidity to enforce "view", so even though a
  // normal token can rely on itself to be non-malicious, we can&#39;t.
  // We have no idea what potentially evil tokens we&#39;ll be interacting with.
  // The call to check the reported balance needs to go after the state changes,
  // even though it&#39;s un-natural. Now, on one hand, this function might at first
  // appear safe, since we&#39;re only allowing the sweeper address to access
  // *this function,* but we are reading the state of the globalBalance.
  // In theory, a malicious token could do the following:
  //  1a) Check if the caller of balanceOf is our contract, if it&#39;s not, act normally.
  //  1b) If the caller is our contract, it does the following:
  //  2) Read our contracts globalBalance for its own address.
  //  3) Sets our contract&#39;s balance of the token (in the token controller) to our internal globalBalance
  //  4) Allocates some other address the difference in globalBalance and actual balance for our contract.
  //  5) Report back to this function exactly the amount we had in globalBalance.
  // (which, by then is true, since they were stolen).
  // Now we&#39;re always going to see 0 extra tokens, and our users have had their tokens perminantly lost.
  // bonus: this is why there is no "sweep all" function.
    
  // Detect ERC20 tokens that have been sent to the contract without a deposit (lost tokens),
  // which are not included in globalBalance[..]
  function sweepTokenAmount(address _token, uint256 _amount) external returns(uint256) {
    assert(msg.sender == sweepAccount);

    balances[_token][sweepAccount] = safeAdd(balances[_token][sweepAccount], _amount);
    globalBalance[_token] = safeAdd(globalBalance[_token], _amount);
    
    //You go last!
	if(_token != address(0x0)) { 
      require(globalBalance[_token] <= Token(_token).balanceOf(this));
	} else {
	  // if another contract performs selfdestruct(UberDelta),
    // ETH can get in here without being in globalBalance
	  require(globalBalance[address(0x0)] <= this.balance); 
	}
    
    TokenSweep(_token, msg.sender, _amount, balances[_token][sweepAccount]);
    
    return(_amount);
  }
  
  
  /*******************************************
  / Regular Trading functions
  /******************************************/
  
  //now contracts can place orders!
  
  
  // Normal order creation happens off-chain and orders are signed by creators,
  // this function allows for on-chain orders to be created
  function order(
    address[4] _addressData,
    uint256[4] _numberData //web3 isn&#39;t ready for structs.
  )
    external
    notLocked
    returns (bool success)
  {
  
//    _addressData[2] is maker;
    if (msg.sender != _addressData[2]) { return false; }
    
    bytes32 hash = getHash(_addressData, _numberData);

    orders[hash] = true;

    Order(
      (bytes32(_addressData[0]) ^ bytes32(_addressData[1])),
      msg.sender,
      _addressData,
      _numberData);
    
    return true;
  }  


  function tradeBalances(
    address _takerTokenAddress,
    uint256 _takerTokenAmount,
    address _makerTokenAddress,
    uint256 _makerTokenAmount,
    address _maker,
    uint256 _tradeAmount
  )
    internal
  {
    require(_takerTokenAmount > 0); //safeDiv

    // We charge only the takers this fee
    uint256 feeValue = safeMul(_tradeAmount, feeByClass[userClass[msg.sender]]) / (1 ether);
    
    balances[_takerTokenAddress][_maker] =
      safeAdd(balances[_takerTokenAddress][_maker], _tradeAmount);
    balances[_takerTokenAddress][msg.sender] =
      safeSub(balances[_takerTokenAddress][msg.sender], safeAdd(_tradeAmount, feeValue));
    
    balances[_makerTokenAddress][_maker] =
      safeSub(
        balances[_makerTokenAddress][_maker],
        safeMul(_makerTokenAmount, _tradeAmount) / _takerTokenAmount
      );
    balances[_makerTokenAddress][msg.sender] =
      safeAdd(
        balances[_makerTokenAddress][msg.sender],
        safeMul(_makerTokenAmount, _tradeAmount) / _takerTokenAmount
      );
    
    balances[_takerTokenAddress][feeAccount] =
      safeAdd(balances[_takerTokenAddress][feeAccount], feeValue);
  }


  function trade(
    address[4] _addressData,
    uint256[4] _numberData, //web3 isn&#39;t ready for structs.
    uint8 _v,
    bytes32 _r,
    bytes32 _s,
    uint256 _amount,
    bool _fillOrKill
  )
    external
    notLocked
    returns(uint256 tradeAmount)
  {
  
//      _addressData[0], // takerTokenAddress;
//      _numberData[0], // takerTokenAmount;
//      _addressData[1], // makerTokenAddress;
//      _numberData[1], // makerTokenAmount;
//      _numberData[2], // tradeExpires;
//      _numberData[3], // salt;
//      _addressData[2], // maker;
//      _addressData[3] // restrictedTo;
    
    bytes32 hash = getHash(_addressData, _numberData);
    
    tradeAmount = safeSub(_numberData[0], orderFills[hash]); //avail to trade
    
    //balance of giveToken / amount I said I&#39;d give of giveToken * amount I said I want of getToken
    if (
      tradeAmount > safeDiv(
        safeMul(balances[_addressData[1]][_addressData[2]], _numberData[0]),
        _numberData[1]
      )
    )
    {
      tradeAmount = safeDiv(
        safeMul(balances[_addressData[1]][_addressData[2]], _numberData[0]),
        _numberData[1]
      );
    }
    
    if (tradeAmount > _amount) { tradeAmount = _amount; }
    
        //_numberData[0] is takerTokenAmount
    if (tradeAmount == 0) { //idfk. There&#39;s nothing there to get. Canceled? Traded?
      if (orderFills[hash] < _numberData[0]) { //Maker seems to be missing tokens?
        FailedTrade(
          (bytes32(_addressData[0]) ^ bytes32(_addressData[1])),
          msg.sender,
          hash,
          0
        );
      } else {  // either cancelled or already traded.
        FailedTrade(
          (bytes32(_addressData[0]) ^ bytes32(_addressData[1])),
          msg.sender,
          hash,
          1
        );
      }
      return 0;
    }
    
    
    if (block.number > _numberData[2]) { //order is expired
      FailedTrade(
        (bytes32(_addressData[0]) ^ bytes32(_addressData[1])),
        msg.sender,
        hash,
        2
      );
      return 0;
    }


    if ((_fillOrKill == true) && (tradeAmount < _amount)) { //didnt fill, so kill
      FailedTrade(
        (bytes32(_addressData[0]) ^ bytes32(_addressData[1])),
        msg.sender,
        hash,
        3
      );
      return 0;
    }
    
        
    uint256 feeValue = safeMul(_amount, feeByClass[userClass[msg.sender]]) / (1 ether);

    //if they trade more than they have, get 0.
    if ( (_amount + feeValue) > balances[_addressData[0]][msg.sender])  { 
      FailedTrade(
        (bytes32(_addressData[0]) ^ bytes32(_addressData[1])),
        msg.sender,
        hash,
        4
      );
      return 0;
    }
    
    if ( //not a valid order.
        (ecrecover(keccak256(signedTradeHash, hash), _v, _r, _s) != _addressData[2])
        && (! orders[hash])
    )
    {
      FailedTrade(
        (bytes32(_addressData[0]) ^ bytes32(_addressData[1])),
        msg.sender,
        hash,
        5
      );
      return 0;
    }

    
    if ((_addressData[3] != address(0x0)) && (_addressData[3] != msg.sender)) { //check restrictedTo
      FailedTrade(
        (bytes32(_addressData[0]) ^ bytes32(_addressData[1])),
        msg.sender,
        hash,
        6
      );
      return 0;
    }
        
    
    if ( //if there&#39;s a compliance restriction.
      ((_addressData[0] != address(0x0)) //if not Eth, and restricted, check with Compliance.
        && (restrictedTokens[_addressData[0]] )
        && ! Compliance(complianceAddress).validateTrade(_addressData[0], _addressData[2], msg.sender)
      )
      || ((_addressData[1] != address(0x0))  //ditto
        && (restrictedTokens[_addressData[1]])
        && ! Compliance(complianceAddress).validateTrade(_addressData[1], _addressData[2], msg.sender)
      )
    )
    {
      FailedTrade(
        (bytes32(_addressData[0]) ^ bytes32(_addressData[1])),
        msg.sender,
        hash,
        7
      );
      return 0;
    }
    
    //Do the thing!
    
    tradeBalances(
      _addressData[0], // takerTokenAddress;
      _numberData[0], // takerTokenAmount;
      _addressData[1], // makerTokenAddress;
      _numberData[1], // makerTokenAmount;
      _addressData[2], // maker;
      tradeAmount
    );

    orderFills[hash] = safeAdd(orderFills[hash], tradeAmount);

    Trade(
      (bytes32(_addressData[0]) ^ bytes32(_addressData[1])),
      _addressData[2],
      msg.sender,
      _addressData[1],
      _addressData[0],
      _addressData[3],
      _numberData,
      tradeAmount,
      _fillOrKill
    );
    
    return(tradeAmount);
  }
  
  
  // Cancel a signed order, once this is confirmed nobody will be able to trade it anymore
  function cancelOrder(
    address[4] _addressData,
    uint256[4] _numberData //web3 isn&#39;t ready for structs.
  )
    external
    returns(uint256 amountCancelled)
  {
    
    require(msg.sender == _addressData[2]);
    
    //  msg.sender can &#39;cancel&#39; nonexistent orders since they&#39;re offchain.
    bytes32 hash = getHash(_addressData, _numberData);
 
    amountCancelled = safeSub(_numberData[0],orderFills[hash]);
    
    orderFills[hash] = _numberData[0];
 
    //event trigger is moved ahead of balance resetting to allow expression of the already-filled amount
//    _numberData[0] is takerTokenAmount;
    Cancel(
      (bytes32(_addressData[0]) ^ bytes32(_addressData[1])),
      msg.sender,
      _addressData,
      _numberData,
      amountCancelled);

    return amountCancelled;    
  }



  /**************************
  / Remote Withdraw
  ***************************/
  
  // Perform an ETH withdraw transaction for someone else based on their signed message
  // Useful if the owner of the funds does not have enough ETH for gas fees in their wallet.
  // msg.sender receives fee for the effort and gas costs
  function remoteWithdraw(
    uint256 _withdrawAmount,
    uint256 _feeAmount,
    uint256 _withdrawExpires,
    uint256 _salt,
    address _maker,
    address _restrictedTo, //0x0 = anyone
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  )
    external
    notLocked
    returns(bool)
  {
    //is the withdraw possible?
    require(
        (balances[address(0x0)][_maker] >= safeAdd(_withdrawAmount, _feeAmount))
     && (
            (_restrictedTo == address(0x0))
         || (_restrictedTo == msg.sender)
        )
     && ((_feeAmount == 0) || (Compliance(complianceAddress).canDeposit(msg.sender)))
    );
    
    //has this withdraw happened already? (and generate the hash)

    bytes32 hash = keccak256(
      this, 
      _withdrawAmount,
      _feeAmount,
      _withdrawExpires,
      _salt,
      _maker,
      _restrictedTo
    );

    require(orderFills[hash] == 0);

    //is this real?
    require(
      ecrecover(keccak256(signedWithdrawHash, hash), _v, _r, _s) == _maker
    );
    
    //only once.
    orderFills[hash] = 1;

    balances[address(0x0)][_maker] =
      safeSub(balances[address(0x0)][_maker], safeAdd(_withdrawAmount, _feeAmount));
    // pay fee to the user performing the remote withdraw
    balances[address(0x0)][msg.sender] = safeAdd(balances[address(0x0)][msg.sender], _feeAmount);
    
    globalBalance[address(0x0)] = safeSub(globalBalance[address(0x0)], _withdrawAmount);

    RemoteWithdraw(
      _maker,
      msg.sender,
      _withdrawAmount,
      _feeAmount,
      _withdrawExpires,
      _salt,
      _restrictedTo
    );

    //implicit require included.
    _maker.transfer(_withdrawAmount);
    
    return(true);
  }

  // cancel a signed request for a remote withdraw
  function cancelRemoteWithdraw(
    uint256 _withdrawAmount,
    uint256 _feeAmount,
    uint256 _withdrawExpires,
    uint256 _salt,
    address _restrictedTo //0x0 = anyone
  )
    external
  {
      // msg.sender can cancel nonexsistent orders.
    bytes32 hash = keccak256(
      this, 
      _withdrawAmount,
      _feeAmount,
      _withdrawExpires,
      _salt,
      msg.sender,
      _restrictedTo
    );
    
    CancelRemoteWithdraw(
      msg.sender,
      _withdrawAmount,
      _feeAmount,
      _withdrawExpires,
      _salt,
      _restrictedTo,
      orderFills[hash]
    );
    
    //set to completed after, event shows pre-cancel status.
    orderFills[hash] = 1;
  }
  
  
 

  /**************************
  /Upgrade Function
  ***************************/
      
  // move tokens/ETH over to a new upgraded smart contract  (avoids having to withdraw & deposit)
  function upgrade(address _token) external returns(uint256 moveBalance) {
    require (newExchange != address(0x0));

    moveBalance = balances[_token][msg.sender];

    globalBalance[_token] = safeSub(globalBalance[_token], moveBalance);
    balances[_token][msg.sender] = 0;

    if (_token != address(0x0)){
      require(Token(_token).approve(newExchange, moveBalance));
      require(UberDelta(newExchange).depositTokenToUser(msg.sender, _token, moveBalance));
    } else {
      require(UberDelta(newExchange).depositToUser.value(moveBalance)(msg.sender));
    }

    Upgrade(msg.sender, _token, newExchange, moveBalance);
    
    return(moveBalance);
  }


  
  /*******************************************
  / Data View functions
  /******************************************/
  
  function testTrade(
    address[4] _addressData,
    uint256[4] _numberData, //web3 isn&#39;t ready for structs.
    uint8 _v,
    bytes32 _r,
    bytes32 _s,
    uint256 _amount,
    address _sender,
    bool _fillOrKill
  )
    public
    view
    returns(uint256)
  {
    uint256 feeValue = safeMul(_amount, feeByClass[userClass[_sender]]) / (1 ether);

    if (
      contractLocked
      ||
      ((_addressData[0] != address(0x0)) //if not Eth, and restricted, check with Compliance.
        && (restrictedTokens[_addressData[0]] )
        && ! Compliance(complianceAddress).validateTrade(_addressData[0], _addressData[2], _sender)
      )
      || ((_addressData[1] != address(0x0))  //ditto
        && (restrictedTokens[_addressData[1]])
        && ! Compliance(complianceAddress).validateTrade(_addressData[1], _addressData[2], _sender)
      )
         //if they trade more than they have, get 0.
      || ((_amount + feeValue) > balances[_addressData[0]][_sender]) 
      || ((_addressData[3] != address(0x0)) && (_addressData[3] != _sender)) //check restrictedTo
    )
    {
      return 0;
    }
      
    uint256 tradeAmount = availableVolume(
        _addressData,
        _numberData,
        _v,
        _r,
        _s
    );
    
    if (tradeAmount > _amount) { tradeAmount = _amount; }
    
    if ((_fillOrKill == true) && (tradeAmount < _amount)) {
      return 0;
    }

    return tradeAmount;
  }


  // get how much of an order is left (unfilled)
  // return value in order of _takerTokenAddress
  function availableVolume(
    address[4] _addressData,
    uint256[4] _numberData, //web3 isn&#39;t ready for structs.
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  )
    public
    view
    returns(uint256 amountRemaining)
  {     
//    _addressData[0] // takerTokenAddress;
//    _numberData[0] // takerTokenAmount;
//    _addressData[1] // makerTokenAddress;
//    _numberData[1] // makerTokenAmount;
//    _numberData[2] // tradeExpires;
//    _numberData[3] // salt;
//    _addressData[2] // maker;
//    _addressData[3] // restrictedTo;

    bytes32 hash = getHash(_addressData, _numberData);

    if (
      (block.number > _numberData[2])
      || ( 
        (ecrecover(keccak256(signedTradeHash, hash), _v, _r, _s) != _addressData[2])
        && (! orders[hash])
      )
    ) { return 0; }

    //uint256 amountRemaining = safeSub(myTrade.takerTokenAmount, orderFills[hash]);
     amountRemaining = safeSub(_numberData[0], orderFills[hash]);

    if (
      amountRemaining < safeDiv(
        safeMul(balances[_addressData[1]][_addressData[2]], _numberData[0]),
        _numberData[1]
      )
    ) return amountRemaining;

    return (
      safeDiv(
        safeMul(balances[_addressData[1]][_addressData[2]], _numberData[0]),
        _numberData[1]
      )
    );
  }


  // get how much of an order has been filled
  // return value in order of _takerTokenAddress
  function getUserFee(
    address _user
  )
    external
    view
    returns(uint256)
  {
    return feeByClass[userClass[_user]];
  }


  // get how much of an order has been filled
  // return value in order of _takerTokenAddress
  function amountFilled(
    address[4] _addressData,
    uint256[4] _numberData //web3 isn&#39;t ready for structs.
  )
    external
    view
    returns(uint256)
  {
    bytes32 hash = getHash(_addressData, _numberData);

    return orderFills[hash];
  }

  
  // check if a request for a remote withdraw is still valid
  function testRemoteWithdraw(
    uint256 _withdrawAmount,
    uint256 _feeAmount,
    uint256 _withdrawExpires,
    uint256 _salt,
    address _maker,
    address _restrictedTo,
    uint8 _v,
    bytes32 _r,
    bytes32 _s,
    address _sender
  )
    external
    view
    returns(uint256)
  {
    bytes32 hash = keccak256(
      this,
      _withdrawAmount,
      _feeAmount,
      _withdrawExpires,
      _salt,
      _maker,
      _restrictedTo
    );

    if (
      contractLocked
      ||
      (balances[address(0x0)][_maker] < safeAdd(_withdrawAmount, _feeAmount))
      ||((_restrictedTo != address(0x0)) && (_restrictedTo != _sender))
      || (orderFills[hash] != 0)
      || (ecrecover(keccak256(signedWithdrawHash, hash), _v, _r, _s) != _maker)
      || ((_feeAmount > 0) && (! Compliance(complianceAddress).canDeposit(_sender)))
    )
    {
      return 0;
    } else {
      return _withdrawAmount;
    }
  }
  
  
  
  function getHash(
    address[4] _addressData,
    uint256[4] _numberData //web3 isn&#39;t ready for structs.
  )
    public
    view
    returns(bytes32)
  {
    return(
      keccak256(
        this,
        _addressData[0], // takerTokenAddress;
        _numberData[0], // takerTokenAmount;
        _addressData[1], // makerTokenAddress;
        _numberData[1], // makerTokenAmount;
        _numberData[2], // tradeExpires;
        _numberData[3], // salt;
        _addressData[2], // maker;
        _addressData[3] // restrictedTo;
      )
    );
  }
  
  

  /***********************************
  / Compliance View Code
  ************************************/
  //since the compliance code might move, we should have a way to always
  //call a function to this contract to get the current values

    function testCanDeposit(
    address _user
  )
    external
    view
    returns (bool)
  {
    return(Compliance(complianceAddress).canDeposit(_user));
  }
  
  function testCanTrade(
    address _token,
    address _user
  )
    external
    view
    returns (bool)
  {
    return(Compliance(complianceAddress).canTrade(_token, _user));
  }

  
  function testValidateTrade(
    address _token,
    address _getUser,
    address _giveUser
  )
    external
    view
    returns (bool isAllowed)
  {
    return(Compliance(complianceAddress).validateTrade(_token, _getUser, _giveUser));
  }
  


  /**************************
  / Default Compliance Code
  ***************************/
  // These will eventually live in a different contract.
  // every can deposit by default, later a registry?
  // For now, always say no if called for trades. 
  // the earliest use may be halting trade in a token.
  function canDeposit(
    address _user
  )
    public
    view
    returns (bool isAllowed)
  {
    return(true);
  }
  
  function canTrade(
    address _token,
    address _user
  )
    public
    view
    returns (bool isAllowed)
  {
    return(false);
  }

  
  function validateTrade(
    address _token,
    address _getUser,
    address _giveUser
  )
    public
    view
    returns (bool isAllowed)
  {
    return(false);
  }
  


  /***********************************
  / THIS IS WHERE OPTIONS LIVE!!!!
  /**********************************/
  
  
  mapping (address => uint256) public exercisedOptions;
  
  //get asset for tickets
  event CollapseOption(
    address indexed user,
    address indexed holderTicketAddress,
    address indexed writerTicketAddress,
    uint256 ticketsCollapsed,
    bytes32 optionPair //assetTokenAddress xor strikeTokenAddress
  );    
  
  //get holderticket + asset for strike
  event ExcerciseUnwind(
    address indexed user,
    address indexed holderTicketAddress,
    uint256 ticketsUnwound,
    bytes32 optionPair,
    bool fillOrKill
  );  
  
  //get asset for writerticket
  event ExpireOption(
    address indexed user,
    address indexed writerTicketAddress,
    uint256 ticketsExpired,
    bytes32 optionPair
  );  
  
  //get tickets for asset
  event CreateOption(
    address indexed user,
    address indexed holderTicketAddress,
    address indexed writerTicketAddress,
    uint256 ticketsCreated,
    bytes32 optionPair
  );  
  
  //get assset for strike + holderticket
  event ExcerciseOption(
    address indexed user,
    address indexed holderTicketAddress,
    uint256 ticketsExcercised,
    bytes32 optionPair //assetTokenAddress xor strikeTokenAddress
  );  
  
  /******************
  / optionFunctions
  ******************/
  
  //if before expiry, deposit asset, get buy ticket, write ticket
  // 1 ticket gets (10^18) option units credited to them.
  function createOptionPair( //#65
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires,
    uint256 _ticketAmount //tickets times (1 ether)
  )
    external
    notLocked
    returns (uint256 ticketsCreated)
  {
    //if before expiry
    require (block.number < _optionExpires); //option would be expired
    
    //if they have the asset
    //[checked by safemath during locking]

    //lock asset to 0x0.
    //the percent of one contract times _assetTokenAmount = amount moving
    //creation fee?
    balances[_assetTokenAddress][0x0] =
      safeAdd(
        balances[_assetTokenAddress][0x0],
        safeDiv(safeMul(_assetTokenAmount, _ticketAmount), 1 ether)
      );

    balances[_assetTokenAddress][msg.sender] =
      safeSub(
        balances[_assetTokenAddress][msg.sender],
        safeDiv(safeMul(_assetTokenAmount, _ticketAmount), 1 ether)
      );
    
    
    address holderTicketAddress = getOptionAddress(
      _assetTokenAddress,
      _assetTokenAmount,
      _strikeTokenAddress,
      _strikeTokenAmount,
      _optionExpires,
      false
    );
    
    address writerTicketAddress = getOptionAddress(
      _assetTokenAddress,
      _assetTokenAmount,
      _strikeTokenAddress,
      _strikeTokenAmount,
      _optionExpires,
      true
    );
    
    //issue write option
    balances[writerTicketAddress][msg.sender] =
      safeAdd(balances[writerTicketAddress][msg.sender], _ticketAmount);
    globalBalance[writerTicketAddress] =
      safeAdd(globalBalance[writerTicketAddress], _ticketAmount);

    //issue hold option
    balances[holderTicketAddress][msg.sender] =
      safeAdd(balances[holderTicketAddress][msg.sender], _ticketAmount);
    globalBalance[holderTicketAddress] =
      safeAdd(globalBalance[holderTicketAddress], _ticketAmount);

    CreateOption(
      msg.sender,
      holderTicketAddress,
      writerTicketAddress,
      _ticketAmount,
      (bytes32(_assetTokenAddress) ^ bytes32(_strikeTokenAddress))
    );
    
    //check if we need to register, and do if we do.
    if (
      OptionRegistry(optionsRegistryAddress).isOptionPairRegistered(
        _assetTokenAddress,
        _assetTokenAmount,
        _strikeTokenAddress,
        _strikeTokenAmount,
        _optionExpires
      )
      == false
    )
    {
      require(
        OptionRegistry(optionsRegistryAddress).registerOptionPair(
          _assetTokenAddress,
          _assetTokenAmount,
          _strikeTokenAddress,
          _strikeTokenAmount,
          _optionExpires
        )
      );
    }
    return _ticketAmount;
  }
  
  //if own buy & writer ticket get asset, void tickets
  // 1 ticket gets 10^18 option units voided.
  function collapseOptionPair( //#66
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires,
    uint256 _ticketAmount
  )
    external
    returns (uint256 ticketsCollapsed)
  {
    
    address holderTicketAddress = getOptionAddress(
      _assetTokenAddress,
      _assetTokenAmount,
      _strikeTokenAddress,
      _strikeTokenAmount,
      _optionExpires,
      false
    );
    
    address writerTicketAddress = getOptionAddress(
      _assetTokenAddress,
      _assetTokenAmount,
      _strikeTokenAddress,
      _strikeTokenAmount,
      _optionExpires,
      true
    );
    
    //if they have the write option
    //if they have the hold option
    require (
      (balances[holderTicketAddress][msg.sender] >= _ticketAmount)
      && (balances[writerTicketAddress][msg.sender] >= _ticketAmount)
    );
    //I guess it can be expired, since you have both legs.
    
    //void write option
    balances[writerTicketAddress][msg.sender] =
      safeSub(balances[writerTicketAddress][msg.sender], _ticketAmount);
    globalBalance[writerTicketAddress] =
      safeSub(globalBalance[writerTicketAddress], _ticketAmount);

    //void hold option
    balances[holderTicketAddress][msg.sender] =
      safeSub(balances[holderTicketAddress][msg.sender], _ticketAmount);
    globalBalance[holderTicketAddress] =
      safeSub(globalBalance[holderTicketAddress], _ticketAmount);
 
    //unlock asset
    balances[_assetTokenAddress][0x0] = safeSub(
      balances[_assetTokenAddress][0x0],
      safeDiv(safeMul(_assetTokenAmount, _ticketAmount), 1 ether)
    );

    balances[_assetTokenAddress][msg.sender] = safeAdd(
      balances[_assetTokenAddress][msg.sender],
      safeDiv(safeMul(_assetTokenAmount, _ticketAmount), 1 ether)
    );
    
    //emit event
    CollapseOption(
      msg.sender,
      holderTicketAddress,
      writerTicketAddress,
      _ticketAmount,
      (bytes32(_assetTokenAddress) ^ bytes32(_strikeTokenAddress))
    );
    
    return _ticketAmount;
  }

  /*about invisableHandOfAdamSmith():
    q: why would someone ever want to buy an out-of-the-money,
       collaterized call option at strike price?

    a: if an american option is executed, and the collateral&#39;s movement
       makes it later out of the money, the value of the option would
       need to be calculated by including the "pre-executed" amount.
       * 
       This would prevent an external actor performing weird arb trades
       (write a billion tickets, collapse a billion tickets, profit!).
       Skip the middle man! Writers are more likely to get 100% token or
       strike at expiry, based on market value, and holders still have
       their option intact.
       * 
       Arbers gonna arb. Let them do their thing.
*/

  //if there have been executions, Adam Smith can deposit asset, get strike, up to execution amount.
//  function invisibleHandOfAdamSmith( //#67

  function optionExcerciseUnwind(
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires,
    uint256 _ticketAmount,
    bool _fillOrKill //do we want? probably...
  )
    external
    notLocked
    returns (uint256 ticketsUnwound) //(amountTraded)
  {
    //only before, equal to expiry
    require(block.number <= _optionExpires);
    
    address holderTicketAddress = getOptionAddress(
      _assetTokenAddress,
      _assetTokenAmount,
      _strikeTokenAddress,
      _strikeTokenAmount,
      _optionExpires,
      false
    );
    
    //if strike-pool[hash] != 0 {
    ticketsUnwound = exercisedOptions[holderTicketAddress];

    //fill or kill.
    require((_fillOrKill == false) || (ticketsUnwound >= _ticketAmount));

    //get amount to trade.
    if (ticketsUnwound > _ticketAmount) ticketsUnwound = _ticketAmount;
    
    require(ticketsUnwound > 0);
    //cant buy zero, either because not avail, or you asked for zero.
 
    //check compliance, like a trade!
    require(
      (! restrictedTokens[holderTicketAddress]) //if it is not restricted
    || Compliance(complianceAddress).canTrade(holderTicketAddress, msg.sender) // or compliance says yes.
    );

    //debit balance of caller of asset tokens, credit 0x0
    balances[_assetTokenAddress][msg.sender] = safeSub(
      balances[_assetTokenAddress][msg.sender],
      safeDiv(safeMul(_assetTokenAmount, ticketsUnwound), 1 ether)
    );

    balances[_assetTokenAddress][0x0] = safeAdd(
      balances[_assetTokenAddress][0x0],
      safeDiv(safeMul(_assetTokenAmount, ticketsUnwound), 1 ether)
    );
    
    //debit balance of exercisedOptions of holdOption, credit caller.
    //no change in global balances.
    exercisedOptions[holderTicketAddress] =
      safeSub(exercisedOptions[holderTicketAddress], ticketsUnwound);
    balances[holderTicketAddress][msg.sender] =
      safeAdd(balances[holderTicketAddress][msg.sender], ticketsUnwound);

    //debit balance of 0x0 of strike, credit caller.
    balances[_strikeTokenAddress][0x0] = safeSub(
      balances[_strikeTokenAddress][0x0],
      safeDiv(safeMul(_strikeTokenAmount, ticketsUnwound), 1 ether)
    );

    balances[_strikeTokenAddress][msg.sender] = safeAdd(
      balances[_strikeTokenAddress][msg.sender],
      safeDiv(safeMul(_strikeTokenAmount, ticketsUnwound), 1 ether)
    );
    
    //emit event.
    ExcerciseUnwind(
      msg.sender,
      holderTicketAddress,
      ticketsUnwound,
      (bytes32(_assetTokenAddress) ^ bytes32(_strikeTokenAddress)),
      _fillOrKill
    );
    
    return ticketsUnwound;
  }
  
  //if before expiry, and own hold ticket, then pay strike, get asset, void hold ticket
  function excerciseOption( //#68
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires,
    uint256 _ticketAmount
  )
  external 
  returns (uint256 ticketsExcercised)
  {  
    //only holder before, equal to expiry
    require(block.number <= _optionExpires);
    
    address holderTicketAddress = getOptionAddress(
      _assetTokenAddress,
      _assetTokenAmount,
      _strikeTokenAddress,
      _strikeTokenAmount,
      _optionExpires,
      false
    );
    
    //get balance of tickets
    ticketsExcercised = balances[holderTicketAddress][msg.sender];
    require(ticketsExcercised >= _ticketAmount); //its just a balance here.
    
    //get amount to trade.
    if (ticketsExcercised > _ticketAmount) ticketsExcercised = _ticketAmount;
    
    //cant execute zero, either you have zero, or you asked for zero.
    require(ticketsExcercised > 0);
    
    //debit balance of caller for holdOption, credit exercisedOptions    
    balances[holderTicketAddress][msg.sender] =
      safeSub(balances[holderTicketAddress][msg.sender], ticketsExcercised);
    exercisedOptions[holderTicketAddress] =
      safeAdd(exercisedOptions[holderTicketAddress], ticketsExcercised);
        
    //debit balance of caller for strikeToken, credit 0x0
    balances[_strikeTokenAddress][msg.sender] = safeSub(
      balances[_strikeTokenAddress][msg.sender],
      safeDiv(safeMul(_strikeTokenAmount, ticketsExcercised), 1 ether)
    );

    balances[_strikeTokenAddress][0x0] = safeAdd(
      balances[_strikeTokenAddress][0x0],
      safeDiv(safeMul(_strikeTokenAmount, ticketsExcercised), 1 ether)
    );
    
    //debit balance of 0x0 of asset, credit caller.   
    balances[_assetTokenAddress][0x0] = safeSub(
      balances[_assetTokenAddress][0x0],
      safeDiv(safeMul(_assetTokenAmount, ticketsExcercised), 1 ether)
    );
    
    balances[_assetTokenAddress][msg.sender] = safeAdd(
      balances[_assetTokenAddress][msg.sender],
      safeDiv(safeMul(_assetTokenAmount, ticketsExcercised), 1 ether)
    );

    
    //no change in global balances.
    //emit event.
    ExcerciseOption(
      msg.sender,
      holderTicketAddress,
      ticketsExcercised,
      (bytes32(_assetTokenAddress) ^ bytes32(_strikeTokenAddress))
    );
    
    return ticketsExcercised;
  }

  
  //if after expiry, get collateral, void option.
  function expireOption( //#69
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires,
    uint256 _ticketAmount
  )
  external 
  returns (uint256 ticketsExpired)
  {
  //only writer, only after expiry
    require(block.number > _optionExpires);
        
    address holderTicketAddress = getOptionAddress(
      _assetTokenAddress,
      _assetTokenAmount,
      _strikeTokenAddress,
      _strikeTokenAmount,
      _optionExpires,
      false
    );
    
    address writerTicketAddress = getOptionAddress(
      _assetTokenAddress,
      _assetTokenAmount,
      _strikeTokenAddress,
      _strikeTokenAmount,
      _optionExpires,
      true
    );
    
    //get balance of tickets
    ticketsExpired = balances[writerTicketAddress][msg.sender];
    require(ticketsExpired >= _ticketAmount); //its just a balance here.
    
    //get amount to trade.
    if (ticketsExpired > _ticketAmount) ticketsExpired = _ticketAmount;
    
    //cant execute zero, either you have zero, or you asked for zero.
    require(ticketsExpired > 0);
    
    // debit holder tickets from user, add to exercisedOptions.
    balances[writerTicketAddress][msg.sender] =
      safeSub(balances[writerTicketAddress][msg.sender], ticketsExpired);
    exercisedOptions[writerTicketAddress] =
      safeAdd(exercisedOptions[writerTicketAddress], ticketsExpired);
    
    //calculate amounts
    uint256 strikeTokenAmount =
      safeDiv(
        safeMul(
          safeDiv(safeMul(ticketsExpired, _strikeTokenAmount), 1 ether), //tickets
          exercisedOptions[holderTicketAddress]
        ),
        globalBalance[holderTicketAddress]
      );

    uint256 assetTokenAmount =
      safeDiv(
        safeMul(
          safeDiv(safeMul(ticketsExpired, _assetTokenAmount), 1 ether), //tickets
          safeSub(globalBalance[holderTicketAddress], exercisedOptions[holderTicketAddress])
        ),
        globalBalance[holderTicketAddress]
      );
    

    //debit zero, add to msg.sender
    balances[_strikeTokenAddress][0x0] =
      safeSub(balances[_strikeTokenAddress][0x0], strikeTokenAmount);
    balances[_assetTokenAddress][0x0] =
      safeSub(balances[_assetTokenAddress][0x0], assetTokenAmount);
    balances[_strikeTokenAddress][msg.sender] =
      safeAdd(balances[_strikeTokenAddress][msg.sender], strikeTokenAmount);
    balances[_assetTokenAddress][msg.sender] =
      safeAdd(balances[_assetTokenAddress][msg.sender], assetTokenAmount);
  
  //set inactive

    ExpireOption( //#69]
      msg.sender,
      writerTicketAddress,
      ticketsExpired,
      (bytes32(_assetTokenAddress) ^ bytes32(_strikeTokenAddress))
    );
    return ticketsExpired;
  }


  //get an option&#39;s Hash&#39;s address
  //  (•_•)  ( •_•)>⌐■-■  (⌐■_■)
  //
  //going from 32 bytes to 20 bytes still gives us 160 bits of hash goodness.
  //that&#39;s still a crazy large number, and used by ethereum for addresses.
  function getOptionAddress(
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires,
    bool _isWriter
  )
    public
    view
    returns(address)
  {
    return(
      address(
        keccak256(
          _assetTokenAddress,
          _assetTokenAmount,
          _strikeTokenAddress,
          _strikeTokenAmount,
          _optionExpires,
          _isWriter
        )
      )
    );
  }

  /***********************************
  / Options View Code
  ************************************/
  //since the options code might move, we should have a way to always
  //call a function to this contract to get the current values
  
  function testIsOptionPairRegistered(
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires
  )
  external
  view
  returns(bool)
  {
    return(
      OptionRegistry(optionsRegistryAddress).isOptionPairRegistered(
        _assetTokenAddress,
        _assetTokenAmount,
        _strikeTokenAddress,
        _strikeTokenAmount,
        _optionExpires
      )
    );
  }
  

  /***********************************
  / Default Options Registration Code
  ************************************/
  // Register emits an event and adds it to restrictedToken.
  // We&#39;ll deal with any other needed registration later.
  // Set up for upgradeable external contract.
  // return bools.
  
  event RegisterOptionsPair(
    bytes32 indexed optionPair, //assetTokenAddress xor strikeTokenAddress
    address indexed writerTicketAddress,
    address indexed holderTicketAddress,
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires
  );  
  
    
  function registerOptionPair(
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires
  )
  public
  returns(bool)
  {
    address holderTicketAddress = getOptionAddress(
      _assetTokenAddress,
      _assetTokenAmount,
      _strikeTokenAddress,
      _strikeTokenAmount,
      _optionExpires,
      false
    );
    
//    if (
//      isOptionPairRegistered(
//        _assetTokenAddress,
//        _assetTokenAmount,
//        _strikeTokenAddress,
//        _strikeTokenAmount,
//        _optionExpires
//      )
//    )
    //cheaper not to make call gaswise, same result.
    
    if (restrictedTokens[holderTicketAddress]) {
      return false;
    //return halts execution, but else is better for readibility
    } else {

      address writerTicketAddress = getOptionAddress(
        _assetTokenAddress,
        _assetTokenAmount,
        _strikeTokenAddress,
        _strikeTokenAmount,
        _optionExpires,
        true
      );
    
      restrictedTokens[holderTicketAddress] = true;
      restrictedTokens[writerTicketAddress] = true;
    
      //an external contract would need to call something like this:
      // after being registered as a helper contract on the main site.
      //UberDelta(uberdeltaAddress).tokenRestriction(holderTicketAddress, true);
      //UberDelta(uberdeltaAddress).tokenRestriction(writerTicketAddress, true);
    
      RegisterOptionsPair(
        (bytes32(_assetTokenAddress) ^ bytes32(_strikeTokenAddress)),
        holderTicketAddress,
        writerTicketAddress,
        _assetTokenAddress,
        _assetTokenAmount,
        _strikeTokenAddress,
        _strikeTokenAmount,
        _optionExpires
      );
    
      return(true);
    }
  }
  
  
  // for v1, we&#39;ll simply return if there&#39;s a restriction.
  function isOptionPairRegistered(
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires
  )
  public
  view
  returns(bool)
  {
    address holderTicketAddress = getOptionAddress(
      _assetTokenAddress,
      _assetTokenAmount,
      _strikeTokenAddress,
      _strikeTokenAmount,
      _optionExpires,
      false
    );
    
    return(restrictedTokens[holderTicketAddress]);
  }
  
  
  function getOptionPair(
    address _assetTokenAddress,
    uint256 _assetTokenAmount,
    address _strikeTokenAddress,
    uint256 _strikeTokenAmount,
    uint256 _optionExpires
  )
  public
  view
  returns(address holderTicketAddress, address writerTicketAddress)
  {
    holderTicketAddress = getOptionAddress(
      _assetTokenAddress,
      _assetTokenAmount,
      _strikeTokenAddress,
      _strikeTokenAmount,
      _optionExpires,
      false
    );
    
    writerTicketAddress = getOptionAddress(
      _assetTokenAddress,
      _assetTokenAmount,
      _strikeTokenAddress,
      _strikeTokenAmount,
      _optionExpires,
      true
    );
    
    return(holderTicketAddress, writerTicketAddress);
  }
  
  
  /******************
  / EOS Registration
  ******************/
  // some users will accidentally keep EOS on the exchange during the snapshot.
  function EOSRegistration (string _key) external onlyOwner{
    EOS(0xd0a6E6C54DbC68Db5db3A091B171A77407Ff7ccf).register(_key);
  }
  
}