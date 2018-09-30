pragma solidity ^0.4.24;

// ---------------------------------------------------------------------------
//  Message_Transport
// ---------------------------------------------------------------------------
contract C_Message_Transport {

  // -------------------------------------------------------------------------
  // events
  // -------------------------------------------------------------------------
  event InviteEvent(address indexed _toAddr, address indexed _fromAddr);
  event MessageTxEvent(address indexed _fromAddr, uint indexed _count, address _toAddr, uint _toCount);
  event MessageRxEvent(address indexed _toAddr, uint indexed _count, address _fromAddr, uint _mimeType, bytes message);


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
    uint obfuscatedSecret;     // encryption parameter
    uint p;                    // encryption parameter
    uint g;                    // encryption parameter
    mapping (address => uint256) peerRecvMessageCount;
  }


  // -------------------------------------------------------------------------
  // data storage
  // -------------------------------------------------------------------------
  bool public isLocked;
  address public owner;
  uint communityBalance;
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


  // -------------------------------------------------------------------------
  //  EMS constructor
  // -------------------------------------------------------------------------
  constructor() public {
    owner = msg.sender;
  }
  function lock() public ownerOnly {
    isLocked = true;
  }


  // -------------------------------------------------------------------------
  // register a simple message account
  // -------------------------------------------------------------------------
  function register(uint256 _messageFee, uint256 _spamFee, uint256 _obfuscatedSecret, uint256 _g, uint256 _p) public {
    Account storage _account = accounts[msg.sender];
    _account.messageFee = _messageFee;
    _account.spamFee = _spamFee;
    _account.obfuscatedSecret = _obfuscatedSecret;
    _account.g = _g;
    _account.p = _p;
  }


  // -------------------------------------------------------------------------
  // get the number of messages that have been sent from one peer to another
  // -------------------------------------------------------------------------
  function getPeerMessageCount(address _from, address _to) public view returns(uint256 _messageCount) {
    Account storage _account = accounts[_to];
    _messageCount = _account.peerRecvMessageCount[_from];
  }


  // -------------------------------------------------------------------------
  // send message
  // -------------------------------------------------------------------------
  function sendMessage(address _toAddr, uint mimeType, bytes message) public payable {
    Account storage _sendAccount = accounts[msg.sender];
    Account storage _recvAccount = accounts[_toAddr];
    require(_sendAccount.g != 0);
    require(_recvAccount.g != 0);
    //if message text is empty then no fees are necessary, and we don&#39;t create a log entry.
    //after you introduce yourself to someone this way their subsequent message to you won&#39;t
    //incur your spamFee.
    if (msg.data.length > 32 + 4) {
      require(msg.value >= _recvAccount.messageFee);
      if (_sendAccount.peerRecvMessageCount[_toAddr] == 0)
        require(msg.value >= _recvAccount.spamFee);
      _recvAccount.recvMessageCount += 1;
      _sendAccount.sentMessageCount += 1;
      emit MessageRxEvent(_toAddr, _recvAccount.recvMessageCount, msg.sender, mimeType, message);
      emit MessageTxEvent(msg.sender, _sendAccount.sentMessageCount, _toAddr, _recvAccount.recvMessageCount);
    } else {
      emit InviteEvent(_toAddr, msg.sender);
    }

    uint _communityAmount = msg.value / 10;
    communityBalance += _communityAmount;
    _recvAccount.feeBalance += (msg.value - _communityAmount);
    _recvAccount.peerRecvMessageCount[msg.sender] += 1;
  }


  // -------------------------------------------------------------------------
  // for debug
  // only available before the contract is locked
  // -------------------------------------------------------------------------
  function killContract() public ownerOnly unlockedOnly {
    selfdestruct(owner);
  }
}