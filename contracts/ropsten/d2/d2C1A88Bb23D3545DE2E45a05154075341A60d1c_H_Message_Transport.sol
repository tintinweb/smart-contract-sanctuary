pragma solidity ^0.4.24;

// ---------------------------------------------------------------------------
//  Message_Transport
// ---------------------------------------------------------------------------
contract H_Message_Transport {

  // -------------------------------------------------------------------------
  // events
  // -------------------------------------------------------------------------
  event InviteEvent(address indexed _toAddr, address indexed _fromAddr);
  event MessageEvent(uint indexed _id, address _fromAddr, address _toAddr, uint _mimeType, uint _ref, uint _nonce, bytes message);
  event MessageTxEvent(address indexed _fromAddr, uint indexed _txCount, uint _id);
  event MessageRxEvent(address indexed _toAddr, uint indexed _rxCount, uint _id);


  // -------------------------------------------------------------------------
  // defines
  // -------------------------------------------------------------------------
  uint constant MIME_TYPE_TEXT_PLAIN = 0;
  uint constant MIME_TYPE_TEXT_HTML  = 1;
  uint constant MIME_TYPE_IMAGE_JPEG = 2;
  uint constant MIME_TYPE_IMAGE_PNG  = 3;


  // -------------------------------------------------------------------------
  // Account structure
  // there is a single account structure for all account types
  // -------------------------------------------------------------------------
  struct Account {
    uint messageFee;           // pay this much for every non-spam message sent to this account
    uint spamFee;              // pay this much for every spam message sent to this account
    uint feeBalance;           // includes spam and non-spam fees
    uint recvMessageCount;     // total messages received
    uint sentMessageCount;     // total messages sent
    bytes publicKey;           // encryption parameter
    bytes encryptedPrivateKey; // encryption parameter
    mapping (address => uint256) peerRecvMessageCount;
  }


  // -------------------------------------------------------------------------
  // data storage
  // -------------------------------------------------------------------------
  bool public isLocked;
  address public owner;
  address public communityAddr;
  uint messageCount;
  uint communityBalance;
  uint contractSendGas = 100000;
  mapping (address => bool) public trusted;
  mapping (address => Account) public accounts;


  // -------------------------------------------------------------------------
  // modifiers
  // -------------------------------------------------------------------------
  modifier ownerOnly {
    require(msg.sender == owner);
    _;
  }
  modifier unlockedOnly {
    require(!isLocked);
    _;
  }
  modifier trustedOnly {
    require(trusted[msg.sender] == true);
    _;
  }


  // -------------------------------------------------------------------------
  //  EMS constructor
  // -------------------------------------------------------------------------
  constructor() public {
    owner = msg.sender;
  }
  function setTrust(address _trustedAddr, bool _trust) public ownerOnly {
    trusted[_trustedAddr] = _trust;
  }
  function tune(uint _contractSendGas) public ownerOnly {
    contractSendGas = _contractSendGas;
  }
  function lock() public ownerOnly {
    isLocked = true;
  }


  // -------------------------------------------------------------------------
  // register a simple message account
  // -------------------------------------------------------------------------
  function register(uint256 _messageFee, uint256 _spamFee, bytes _publicKey, bytes _encryptedPrivateKey) public {
    Account storage _account = accounts[msg.sender];
    _account.messageFee = _messageFee;
    _account.spamFee = _spamFee;
    _account.publicKey = _publicKey;
    _account.encryptedPrivateKey = _encryptedPrivateKey;
  }


  // -------------------------------------------------------------------------
  // get the number of messages that have been sent from one peer to another
  // -------------------------------------------------------------------------
  function getPeerMessageCount(address _from, address _to) public view returns(uint256 _messageCount) {
    Account storage _account = accounts[_to];
    _messageCount = _account.peerRecvMessageCount[_from];
  }


  // -------------------------------------------------------------------------
  // get the required fee in order to send a message (or spam message)
  // this is handy for contract calls
  // -------------------------------------------------------------------------
  function getFee(address _toAddr) public view returns(uint256 _fee) {
    Account storage _sendAccount = accounts[msg.sender];
    Account storage _recvAccount = accounts[_toAddr];
    if (_sendAccount.peerRecvMessageCount[_toAddr] == 0)
      _fee = _recvAccount.spamFee;
    else
      _fee = _recvAccount.messageFee;
  }
  function getFee(address _fromAddr, address _toAddr) public view trustedOnly returns(uint256 _fee) {
    Account storage _sendAccount = accounts[_fromAddr];
    Account storage _recvAccount = accounts[_toAddr];
    if (_sendAccount.peerRecvMessageCount[_toAddr] == 0)
      _fee = _recvAccount.spamFee;
    else
      _fee = _recvAccount.messageFee;
  }


  // -------------------------------------------------------------------------
  // send message
  // -------------------------------------------------------------------------
  function sendMessage(address _toAddr, uint mimeType, uint _ref, bytes _message) public payable returns (uint _messageId) {
    Account storage _sendAccount = accounts[msg.sender];
    Account storage _recvAccount = accounts[_toAddr];
    //require(_sendAccount.publicKey != 0);
    //require(_recvAccount.publicKey != 0);
    //if message text is empty then no fees are necessary, and we don&#39;t create a log entry.
    //after you introduce yourself to someone this way their subsequent message to you won&#39;t
    //incur your spamFee.
    if (msg.data.length > 4 + 20 + 32) {
      require(msg.value >= _recvAccount.messageFee);
      if (_sendAccount.peerRecvMessageCount[_toAddr] == 0)
        require(msg.value >= _recvAccount.spamFee);
      ++messageCount;
      _recvAccount.recvMessageCount += 1;
      _sendAccount.sentMessageCount += 1;
      emit MessageEvent(messageCount, msg.sender, _toAddr, mimeType, _ref, _sendAccount.sentMessageCount, _message);
      emit MessageTxEvent(msg.sender, _sendAccount.sentMessageCount, messageCount);
      emit MessageRxEvent(_toAddr, _recvAccount.recvMessageCount, messageCount);
      //return message id, which a calling function might want to log
      _messageId = messageCount;
    } else {
      emit InviteEvent(_toAddr, msg.sender);
      _messageId = 0;
    }
    uint _communityAmount = msg.value / 10;
    communityBalance += _communityAmount;
    _recvAccount.feeBalance += (msg.value - _communityAmount);
    _recvAccount.peerRecvMessageCount[msg.sender] += 1;
  }

  function sendMessage(address _fromAddr, address _toAddr, uint mimeType, uint _ref, bytes _message) public payable trustedOnly returns (uint _messageId) {
    Account storage _sendAccount = accounts[_fromAddr];
    Account storage _recvAccount = accounts[_toAddr];
    //require(_sendAccount.publicKey != 0);
    //require(_recvAccount.publicKey != 0);
    //if message text is empty then no fees are necessary, and we don&#39;t create a log entry.
    //after you introduce yourself to someone this way their subsequent message to you won&#39;t
    //incur your spamFee.
    if (msg.data.length > 4 + 20 + 20 + 32) {
      require(msg.value >= _recvAccount.messageFee);
      if (_sendAccount.peerRecvMessageCount[_toAddr] == 0)
        require(msg.value >= _recvAccount.spamFee);
      ++messageCount;
      _recvAccount.recvMessageCount += 1;
      _sendAccount.sentMessageCount += 1;
      emit MessageEvent(messageCount, _fromAddr, _toAddr, mimeType, _ref, _sendAccount.sentMessageCount, _message);
      emit MessageTxEvent(_fromAddr, _sendAccount.sentMessageCount, messageCount);
      emit MessageRxEvent(_toAddr, _recvAccount.recvMessageCount, messageCount);
      //return message id, which a calling function might want to log
      _messageId = messageCount;
    } else {
      emit InviteEvent(_toAddr, msg.sender);
      _messageId = 0;
    }
    uint _communityAmount = msg.value / 10;
    communityBalance += _communityAmount;
    _recvAccount.feeBalance += (msg.value - _communityAmount);
    _recvAccount.peerRecvMessageCount[msg.sender] += 1;
  }

  // -------------------------------------------------------------------------
  // withdraw accumulated message & spam fees
  // -------------------------------------------------------------------------
  function withdraw() public {
    Account storage _account = accounts[msg.sender];
    uint _amount = _account.feeBalance;
    _account.feeBalance = 0;
    msg.sender.transfer(_amount);
  }


  // -------------------------------------------------------------------------
  // pay community funds to the community
  // can send to a contract if contractSendGas is sufficient
  // -------------------------------------------------------------------------
  function withdrawCommunityFunds() public {
    uint _amount = communityBalance;
    communityBalance = 0;
    if (!communityAddr.call.gas(contractSendGas).value(_amount)())
      revert();
  }


  // -------------------------------------------------------------------------
  // for debug
  // only available before the contract is locked
  // -------------------------------------------------------------------------
  function killContract() public ownerOnly unlockedOnly {
    selfdestruct(owner);
  }
}