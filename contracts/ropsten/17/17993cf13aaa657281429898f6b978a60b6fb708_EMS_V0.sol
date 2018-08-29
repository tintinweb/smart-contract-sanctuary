pragma solidity ^0.4.24;

// ---------------------------------------------------------------------------
//  EMS Contract
// ---------------------------------------------------------------------------
contract EMS_V0 {

  // -------------------------------------------------------------------------
  // events
  // -------------------------------------------------------------------------
  event StatEvent(string message);
  event MessageEvent(address indexed _toAddr, uint indexed batch, address _fromAddr, bytes message);


  // -------------------------------------------------------------------------
  // defines
  // -------------------------------------------------------------------------
  uint constant MESSAGE_ACCOUNT_TYPE = 0x00;
  uint constant ESCROW_ACCOUNT_TYPE  = 0x01;


  // -------------------------------------------------------------------------
  // Escrow structure
  // an escrow account between to parties
  // -------------------------------------------------------------------------
  struct Escrow {
    uint vendorBalance;                 // amount that vendor has put into escrow
    uint customerBalance;               // amount that customer has put into escrow
  }

  // -------------------------------------------------------------------------
  // Account structure
  // there is a single account structure for all account types
  // -------------------------------------------------------------------------
  struct Account {
    uint8 accountType;     // message account / escrow account
    uint8 messageCount;    // number of messages sent from this account
    uint8 batchCount;      // batch number of messages sent from this account
    uint messageFee;       // pay this much for every non-spam message sent to this account
    uint spamFee;          // pay this much for every spam message sent to this account
    uint balance;          // balance is only for escrow accounts, does not include escrowed funds
    uint obfuscatedSecret; // encryption parameter
    uint p;                // encryption parameter
    uint g;                // encryption parameter
    mapping (address => Escrow) escrows;
  }


  // -------------------------------------------------------------------------
  // data storage
  // -------------------------------------------------------------------------
  bool public isLocked;
  address public owner;
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
    emit StatEvent("ok: acct added");
  }


  // -------------------------------------------------------------------------
  // send message
  // -------------------------------------------------------------------------
  function sendMessage(address _toAddr, bytes message) public {
    emit MessageEvent(_toAddr, 0, msg.sender, message);
    Account storage _account = accounts[msg.sender];
    require(_account.g != 0);
    emit StatEvent("ok: message sent");
  }


  // -------------------------------------------------------------------------
  // for debug
  // only available before the contract is locked
  // -------------------------------------------------------------------------
  function haraKiri() public ownerOnly unlockedOnly {
    selfdestruct(owner);
  }
}