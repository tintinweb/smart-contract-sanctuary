pragma solidity ^0.4.18;

// File: contracts/EtherDeltaI.sol

contract EtherDeltaI {

  uint public feeMake; //percentage times (1 ether)
  uint public feeTake; //percentage times (1 ether)

  mapping (address => mapping (address => uint)) public tokens; //mapping of token addresses to mapping of account balances (token=0 means Ether)
  mapping (address => mapping (bytes32 => bool)) public orders; //mapping of user accounts to mapping of order hashes to booleans (true = submitted by user, equivalent to offchain signature)
  mapping (address => mapping (bytes32 => uint)) public orderFills; //mapping of user accounts to mapping of order hashes to uints (amount of order that has been filled)

  function deposit() payable;

  function withdraw(uint amount);

  function depositToken(address token, uint amount);

  function withdrawToken(address token, uint amount);

  function balanceOf(address token, address user) constant returns (uint);

  function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce);

  function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount);

  function testTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, address sender) constant returns(bool);

  function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) constant returns(uint);

  function amountFilled(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) constant returns(uint);

  function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s);

}

// File: contracts/KindMath.sol

/**
 * @title KindMath
 * @dev Math operations with safety checks that fail
 */
library KindMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}

// File: contracts/KeyValueStorage.sol

contract KeyValueStorage {

  mapping(address => mapping(bytes32 => uint256)) _uintStorage;
  mapping(address => mapping(bytes32 => address)) _addressStorage;
  mapping(address => mapping(bytes32 => bool)) _boolStorage;
  mapping(address => mapping(bytes32 => bytes32)) _bytes32Storage;

  /**** Get Methods ***********/

  function getAddress(bytes32 key) public view returns (address) {
      return _addressStorage[msg.sender][key];
  }

  function getUint(bytes32 key) public view returns (uint) {
      return _uintStorage[msg.sender][key];
  }

  function getBool(bytes32 key) public view returns (bool) {
      return _boolStorage[msg.sender][key];
  }

  function getBytes32(bytes32 key) public view returns (bytes32) {
      return _bytes32Storage[msg.sender][key];
  }

  /**** Set Methods ***********/

  function setAddress(bytes32 key, address value) public {
      _addressStorage[msg.sender][key] = value;
  }

  function setUint(bytes32 key, uint value) public {
      _uintStorage[msg.sender][key] = value;
  }

  function setBool(bytes32 key, bool value) public {
      _boolStorage[msg.sender][key] = value;
  }

  function setBytes32(bytes32 key, bytes32 value) public {
      _bytes32Storage[msg.sender][key] = value;
  }

  /**** Delete Methods ***********/

  function deleteAddress(bytes32 key) public {
      delete _addressStorage[msg.sender][key];
  }

  function deleteUint(bytes32 key) public {
      delete _uintStorage[msg.sender][key];
  }

  function deleteBool(bytes32 key) public {
      delete _boolStorage[msg.sender][key];
  }

  function deleteBytes32(bytes32 key) public {
      delete _bytes32Storage[msg.sender][key];
  }

}

// File: contracts/StorageStateful.sol

contract StorageStateful {
  KeyValueStorage public keyValueStorage;
}

// File: contracts/TokenI.sol

contract Token {
  /// @return total amount of tokens
  function totalSupply() public returns (uint256);

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) public returns (uint256);

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) public returns (bool);

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

  /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of wei to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) public returns (bool);

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) public returns (uint256);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint256 public decimals;
  string public name;
}

// File: contracts/EnclavesDEX.sol

contract EnclavesDEX is StorageStateful {
  using KindMath for uint256;

  address public admin; //the admin address
  address public feeAccount; //the account that will receive fees

  struct EtherDeltaInfo {
    uint256 feeMake;
    uint256 feeTake;
  }

  EtherDeltaInfo public etherDeltaInfo;

  uint256 public feeTake; //percentage times 1 ether
  uint256 public feeAmountThreshold; //gasPrice amount under which no fees are charged

  address public etherDelta;

  bool public useEIP712 = true;
  bytes32 public tradeABIHash;
  bytes32 public withdrawABIHash;

  bool freezeTrading;
  bool depositTokenLock;

  mapping (address => mapping (uint256 => bool)) nonceCheck;

  mapping (address => mapping (address => uint256)) public tokens; //mapping of token addresses to mapping of account balances (token=0 means Ether)
  mapping (address => mapping (bytes32 => bool)) public orders; //mapping of user accounts to mapping of order hashes to booleans (true = submitted by user, equivalent to offchain signature)
  mapping (address => mapping (bytes32 => uint256)) public orderFills; //mapping of user accounts to mapping of order hashes to uints (amount of order that has been filled)

  //Unused here - used in Proxy
  address internal implementation;
  address public proposedImplementation;
  uint256 public proposedTimestamp;

  event Order(address indexed tokenGet, uint256 amountGet, address indexed tokenGive, uint256 amountGive, uint256 expires, uint256 nonce, address indexed user);
  event Cancel(address indexed tokenGet, uint256 amountGet, address indexed tokenGive, uint256 amountGive, uint256 expires, uint256 nonce, address indexed user, uint8 v, bytes32 r, bytes32 s);
  event Trade(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, address indexed get, address indexed give, uint8 exchange);
  event Deposit(address indexed token, address indexed user, uint256 amount, uint256 balance);
  event Withdraw(address indexed token, address indexed user, uint256 amount, uint256 balance);
  event WithdrawPreSigned(address indexed feeToken, uint256 feeValue, address indexed feeReceiver);
  event Rebalance(address indexed dex, address indexed token, uint256 amount);

  modifier onlyAdmin {
    require(msg.sender == admin);
    _;
  }

  modifier onlyEtherDelta {
    require(msg.sender == etherDelta);
    _;
  }

  modifier markTokenDeposit {
    depositTokenLock = true;
    _;
    depositTokenLock = false;
  }

  modifier inTokenDeposit {
    require(depositTokenLock);
    _;
  }

  modifier notFrozen {
    require(!freezeTrading);
    _;
  }

  function setEtherDeltaFees() public onlyAdmin {
    etherDeltaInfo.feeMake = EtherDeltaI(etherDelta).feeMake();
    etherDeltaInfo.feeTake = EtherDeltaI(etherDelta).feeTake();
  }

  function() public payable onlyEtherDelta {
  }

  function setTradeABIHash(bytes32 _tradeABIHash) public onlyAdmin {
    tradeABIHash = _tradeABIHash;
  }

  function setWithdrawABIHash(bytes32 _withdrawABIHash) public onlyAdmin {
    withdrawABIHash = _withdrawABIHash;
  }

  function setUseEIP712(bool _useEIP712) public onlyAdmin {
    useEIP712 = _useEIP712;
  }

  function changeAdmin(address _admin) public onlyAdmin {
    admin = _admin;
  }

  function changeFeeAccount(address _feeAccount) public onlyAdmin {
    require(_feeAccount != address(0));
    feeAccount = _feeAccount;
  }

  function changeFeeTake(uint256 _feeTake) public onlyAdmin {
    feeTake = _feeTake;
  }

  function changeFeeAmountThreshold(uint256 _feeAmountThreshold) public onlyAdmin {
    feeAmountThreshold = _feeAmountThreshold;
  }

  function changeFreezeTrading(bool _freezeTrading) public onlyAdmin {
    freezeTrading = _freezeTrading;
  }

  function deposit() public payable {
    if (msg.value > 0) {
      tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].add(msg.value);
      Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }
  }

  function depositEther(uint256 _amount) internal {
    //Will throw if not enough ether sent
    uint256 refund = msg.value.sub(_amount);
    if (_amount != 0) {
      tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].add(_amount);
      Deposit(address(0), msg.sender, _amount, tokens[address(0)][msg.sender]);
    }
    if (refund > 0) {
      msg.sender.transfer(refund);
    }
  }

  function depositToken(address _token, uint256 _amount) public markTokenDeposit {
    require(_token != address(0));
    require(Token(_token).transferFrom(msg.sender, address(this), _amount));
    tokens[_token][msg.sender] = tokens[_token][msg.sender].add(_amount);
    Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
  }

  function depositBoth(address _token, uint256 _amount) public payable {
    depositToken(_token, _amount);
    deposit();
  }

  function processDeposits(address _token, uint256 _amount) internal {
    //Always need to deal with possible non-zero msg.value
    uint256 etherAmount = 0;
    if ((_token == address(0)) && (tokens[address(0)][msg.sender] < _amount)) {
      etherAmount = _amount.sub(tokens[address(0)][msg.sender]);
    }
    depositEther(etherAmount);
    //Only pull tokens if needed
    if ((_token != address(0)) && (tokens[_token][msg.sender] < _amount)) {
      depositToken(_token, _amount.sub(tokens[_token][msg.sender]));
    }
  }

  function withdraw(uint256 _amount) public {
    withdrawUser(_amount, msg.sender);
  }

  function withdrawUser(uint256 _amount, address _user) internal {
    tokens[address(0)][_user] = tokens[address(0)][_user].sub(_amount);
    if (this.balance < _amount) {
      rebalanceEnclaves(address(0), _amount);
    }
    _user.transfer(_amount);
    Withdraw(address(0), _user, _amount, tokens[address(0)][_user]);
  }

  function withdrawToken(address _token, uint256 _amount) public {
    withdrawTokenUser(_token, _amount, msg.sender);
  }

  function withdrawTokenUser(address _token, uint256 _amount, address _user) internal {
    require(_token != 0);
    tokens[_token][_user] = tokens[_token][_user].sub(_amount);
    if (Token(_token).balanceOf(address(this)) < _amount) {
      rebalanceEnclaves(_token, _amount);
    }
    require(Token(_token).transfer(_user, _amount));
    Withdraw(_token, _user, _amount, tokens[_token][_user]);
  }

  function withdrawTokenMulti(address[] _tokens, uint256[] _amounts) public {
    require(_tokens.length == _amounts.length);
    for (uint256 i = 0; i < _tokens.length; i++) {
      withdrawToken(_tokens[i], _amounts[i]);
    }
  }

  function withdrawBoth(address _token, uint256 _tokenAmount, uint256 _ethAmount) public {
    withdrawToken(_token, _tokenAmount);
    withdraw(_ethAmount);
  }

  function tokenFallback(address /* _from */, uint256 /* _value */, bytes /* _data */) public view inTokenDeposit {
    //Having this function allows ERC23 tokens to be deposited via the usual approve / transferFrom methods
    //It should only be called whilst a depositToken is occurring
  }

  function balanceOf(address _token, address _user) public view returns (uint256) {
    return tokens[_token][_user];
  }

  function order(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, uint256 _expires, uint256 _nonce) public {
    bytes32 orderHash = keccak256(address(this), _tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce);
    orders[msg.sender][orderHash] = true;
    Order(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, msg.sender);
  }

  function rebalanceEtherDelta(address _token, uint256 _amount) internal {
    uint256 enclavesBalance;
    if (_token == address(0)) {
      enclavesBalance = this.balance;
      if (enclavesBalance < _amount) {
        _amount = enclavesBalance;
      }
      EtherDeltaI(etherDelta).deposit.value(_amount)();
    } else {
      enclavesBalance = Token(_token).balanceOf(address(this));
      if (enclavesBalance < _amount) {
        _amount = enclavesBalance;
      }
      Token(_token).approve(etherDelta, _amount);
      EtherDeltaI(etherDelta).depositToken(_token, _amount);
    }
    Rebalance(etherDelta, _token, _amount);
  }

  function rebalanceEnclaves(address _token, uint256 _amount) internal {
    uint256 edBalance = EtherDeltaI(etherDelta).balanceOf(_token, address(this));
    if (edBalance < _amount) {
      _amount = edBalance;
    }
    if (_token == address(0)) {
      EtherDeltaI(etherDelta).withdraw(_amount);
    } else {
      EtherDeltaI(etherDelta).withdrawToken(_token, _amount);
    }
    Rebalance(address(this), _token, _amount);
  }

  function tradeEtherDelta(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, uint256 _expires, uint256 _nonce, address _user, uint8 _v, bytes32 _r, bytes32 _s, uint256 _amount, bool _withdraw) public notFrozen payable returns (uint256) {
    _amount = availableVolumeEtherDelta(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, _user, _amount);
    require(_amount > 0);
    _tradeEtherDelta(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, _user, _v, _r, _s, _amount);
    if (_withdraw) {
      if (_tokenGive == address(0)) {
        withdraw(_amountGive.mul(_amount) / _amountGet);
      } else {
        withdrawToken(_tokenGive, _amountGive.mul(_amount) / _amountGet);
      }
    }
    return _amount;
  }

  //amount is denominated in tokenGet
  function _tradeEtherDelta(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, uint256 _expires, uint256 _nonce, address _user, uint8 _v, bytes32 _r, bytes32 _s, uint256 _amount) internal {
    uint256 cost = _amount.add(_amount.mul(etherDeltaInfo.feeTake) / 1 ether);
    processDeposits(_tokenGet, cost);
    tokens[_tokenGet][msg.sender] = tokens[_tokenGet][msg.sender].sub(cost);
    if (EtherDeltaI(etherDelta).balanceOf(_tokenGet, address(this)) < cost) {
      rebalanceEtherDelta(_tokenGet, cost);
    }
    EtherDeltaI(etherDelta).trade(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, _user, _v, _r, _s, _amount);
    //Reuse cost to avoid "CompilerError: Stack too deep, try removing local variables."
    cost = _amountGive.mul(_amount) / _amountGet;
    tokens[_tokenGive][msg.sender] = tokens[_tokenGive][msg.sender].add(cost);
    Trade(_tokenGet, _amount, _tokenGive, cost, _user, msg.sender, 1);
  }

  function trade(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, uint256 _expires, uint256 _nonce, address _user, uint8 _v, bytes32 _r, bytes32 _s, uint256 _amount, bool _withdraw) public notFrozen payable returns (uint256) {
    uint256 availableVolume;
    //Reuse _r to avoid "CompilerError: Stack too deep, try removing local variables."
    (availableVolume, _r) = availableVolumeEnclaves(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, _user, _v, _r, _s);
    _amount = (availableVolume < _amount) ? availableVolume : _amount;
    require(_amount > 0);
    _trade(_tokenGet, _amountGet, _tokenGive, _amountGive, _user, _amount, _r);
    if (_withdraw) {
      if (_tokenGive == address(0)) {
        withdraw(_amountGive.mul(_amount) / _amountGet);
      } else {
        withdrawToken(_tokenGive, _amountGive.mul(_amount) / _amountGet);
      }
    }
    return _amount;
  }

  //_amount is denominated in tokenGet
  function _trade(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, address _user, uint256 _amount, bytes32 _orderHash) internal {
    uint256 ethAmount = (_tokenGet == address(0)) ? _amount : _amountGive.mul(_amount) / _amountGet;
    uint256 feeTakeXfer = (ethAmount <= feeAmountThreshold) ? 0 : _amount.mul(feeTake) / (1 ether);
    uint256 cost = _amount.add(feeTakeXfer);
    processDeposits(_tokenGet, cost);
    tokens[_tokenGet][msg.sender] = tokens[_tokenGet][msg.sender].sub(cost);
    //
    tokens[_tokenGet][_user] = tokens[_tokenGet][_user].add(_amount);
    if (feeTakeXfer > 0) {
      tokens[_tokenGet][feeAccount] = tokens[_tokenGet][feeAccount].add(feeTakeXfer);
    }
    tokens[_tokenGive][_user] = tokens[_tokenGive][_user].sub(_amountGive.mul(_amount) / _amountGet);
    //
    //Reuse cost to avoid "CompilerError: Stack too deep, try removing local variables."
    cost = _amountGive.mul(_amount) / _amountGet;
    tokens[_tokenGive][msg.sender] = tokens[_tokenGive][msg.sender].add(cost);
    orderFills[_user][_orderHash] = orderFills[_user][_orderHash].add(_amount);
    Trade(_tokenGet, _amount, _tokenGive, cost, _user, msg.sender, 0);
  }

  function checkSig(bytes32 _abiHash, bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s, address _user) public view returns(bool) {
    if (useEIP712) {
      return (ecrecover(keccak256(_abiHash, _hash), _v, _r, _s) == _user);
    } else {
      return (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", _hash), _v, _r, _s) == _user);
    }
  }

  function availableVolumeEnclaves(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, uint256 _expires, uint256 _nonce, address _user, uint8 _v, bytes32 _r, bytes32 _s) public view returns (uint256, bytes32) {
    bytes32 orderHash = keccak256(address(this), _tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce);
    if (!(
      (orders[_user][orderHash] || checkSig(tradeABIHash, orderHash, _v, _r, _s, _user)) &&
      block.number <= _expires
    )) return (0, orderHash);
    //Reuse amountGet/Give to avoid "CompilerError: Stack too deep, try removing local variables."
    _amountGive = tokens[_tokenGive][_user].mul(_amountGet) / _amountGive;
    _amountGet = _amountGet.sub(orderFills[_user][orderHash]);
    _amountGet = (_amountGive < _amountGet) ? _amountGive : _amountGet;
    return (_amountGet, orderHash);
  }

  function availableVolumeEtherDelta(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, uint256 _expires, uint256 _nonce, address _user, uint256 _amount) public view returns (uint256) {
    if (block.number > _expires) {
      return 0;
    }
    bytes32 orderHash = sha256(etherDelta, _tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce);
    //Reuse amountGet/Give to avoid "CompilerError: Stack too deep, try removing local variables."
    _amountGive = EtherDeltaI(etherDelta).tokens(_tokenGive, _user).mul(_amountGet) / _amountGive;
    _amountGet = _amountGet.sub(EtherDeltaI(etherDelta).orderFills(_user, orderHash));
    if (_amountGet > _amountGive) {
      _amountGet = _amountGive;
    }
    if (_amountGet > _amount) {
      _amountGet = _amount;
    }
    return _amountGet;
  }

  function amountFilled(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, uint256 _expires, uint256 _nonce, address _user) public view returns(uint256) {
    bytes32 hash = keccak256(address(this), _tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce);
    return orderFills[_user][hash];
  }

  function cancelOrder(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, uint256 _expires, uint256 _nonce, uint8 _v, bytes32 _r, bytes32 _s) public {
    bytes32 hash = keccak256(address(this), _tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce);
    require(orders[msg.sender][hash] || checkSig(tradeABIHash, hash, _v, _r, _s, msg.sender));
    orderFills[msg.sender][hash] = _amountGet;
    Cancel(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, msg.sender, _v, _r, _s);
  }

  function withdrawPreSigned(address _token, uint256 _value, address _feeToken, uint256 _feeValue, uint256 _nonce, address _user, uint8 _v, bytes32 _r, bytes32 _s) public {
    require(nonceCheck[_user][_nonce] == false);
    bytes32 hash = keccak256(address(this), _token, _value, _feeToken, _feeValue, _nonce);
    require(checkSig(withdrawABIHash, hash, _v, _r, _s, _user));
    nonceCheck[_user][_nonce] = true;
    //Debit fee to sender
    tokens[_feeToken][_user] = tokens[_feeToken][_user].sub(_feeValue);
    tokens[_feeToken][msg.sender] = tokens[_feeToken][msg.sender].add(_feeValue);
    if (_token == address(0)) {
      withdrawUser(_value, _user);
    } else {
      withdrawTokenUser(_token, _value, _user);
    }
    WithdrawPreSigned(_feeToken, _feeValue, msg.sender);
  }

}