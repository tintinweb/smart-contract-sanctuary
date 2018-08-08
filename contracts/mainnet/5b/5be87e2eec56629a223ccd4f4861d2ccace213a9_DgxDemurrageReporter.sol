pragma solidity ^0.4.19;

library Types {
  struct MutableUint {
    uint256 pre;
    uint256 post;
  }

  struct MutableTimestamp {
    MutableUint time;
    uint256 in_units;
  }

  function advance_by(MutableTimestamp memory _original, uint256 _units)
           internal
           constant
           returns (MutableTimestamp _transformed)
  {
    _transformed = _original;
    require(now >= _original.time.pre);
    uint256 _lapsed = now - _original.time.pre;
    _transformed.in_units = _lapsed / _units;
    uint256 _ticks = _transformed.in_units * _units;
    if (_transformed.in_units == 0) {
      _transformed.time.post = _original.time.pre;
    } else {
      _transformed.time = add(_transformed.time, _ticks);
    }
  }

  function add(MutableUint memory _original, uint256 _amount)
           internal
           pure
           returns (MutableUint _transformed)
  {
    require((_original.pre + _amount) >= _original.pre);
    _transformed = _original;
    _transformed.post = _original.pre + _amount;
  }
}

contract DigixConstants {
    /// general constants
    uint256 constant SECONDS_IN_A_DAY = 24 * 60 * 60;

    /// asset events
    uint256 constant ASSET_EVENT_CREATED_VENDOR_ORDER = 1;
    uint256 constant ASSET_EVENT_CREATED_TRANSFER_ORDER = 2;
    uint256 constant ASSET_EVENT_CREATED_REPLACEMENT_ORDER = 3;
    uint256 constant ASSET_EVENT_FULFILLED_VENDOR_ORDER = 4;
    uint256 constant ASSET_EVENT_FULFILLED_TRANSFER_ORDER = 5;
    uint256 constant ASSET_EVENT_FULFILLED_REPLACEMENT_ORDER = 6;
    uint256 constant ASSET_EVENT_MINTED = 7;
    uint256 constant ASSET_EVENT_MINTED_REPLACEMENT = 8;
    uint256 constant ASSET_EVENT_RECASTED = 9;
    uint256 constant ASSET_EVENT_REDEEMED = 10;
    uint256 constant ASSET_EVENT_FAILED_AUDIT = 11;
    uint256 constant ASSET_EVENT_ADMIN_FAILED = 12;
    uint256 constant ASSET_EVENT_REMINTED = 13;

    /// roles
    uint256 constant ROLE_ZERO_ANYONE = 0;
    uint256 constant ROLE_ROOT = 1;
    uint256 constant ROLE_VENDOR = 2;
    uint256 constant ROLE_XFERAUTH = 3;
    uint256 constant ROLE_POPADMIN = 4;
    uint256 constant ROLE_CUSTODIAN = 5;
    uint256 constant ROLE_AUDITOR = 6;
    uint256 constant ROLE_MARKETPLACE_ADMIN = 7;
    uint256 constant ROLE_KYC_ADMIN = 8;
    uint256 constant ROLE_FEES_ADMIN = 9;
    uint256 constant ROLE_DOCS_UPLOADER = 10;
    uint256 constant ROLE_KYC_RECASTER = 11;
    uint256 constant ROLE_FEES_DISTRIBUTION_ADMIN = 12;

    /// states
    uint256 constant STATE_ZERO_UNDEFINED = 0;
    uint256 constant STATE_CREATED = 1;
    uint256 constant STATE_VENDOR_ORDER = 2;
    uint256 constant STATE_TRANSFER = 3;
    uint256 constant STATE_CUSTODIAN_DELIVERY = 4;
    uint256 constant STATE_MINTED = 5;
    uint256 constant STATE_AUDIT_FAILURE = 6;
    uint256 constant STATE_REPLACEMENT_ORDER = 7;
    uint256 constant STATE_REPLACEMENT_DELIVERY = 8;
    uint256 constant STATE_RECASTED = 9;
    uint256 constant STATE_REDEEMED = 10;
    uint256 constant STATE_ADMIN_FAILURE = 11;

    /// interactive contracts
    bytes32 constant CONTRACT_INTERACTIVE_ASSETS_EXPLORER = "i:asset:explorer";
    bytes32 constant CONTRACT_INTERACTIVE_DIGIX_DIRECTORY = "i:directory";
    bytes32 constant CONTRACT_INTERACTIVE_MARKETPLACE = "i:mp";
    bytes32 constant CONTRACT_INTERACTIVE_MARKETPLACE_ADMIN = "i:mpadmin";
    bytes32 constant CONTRACT_INTERACTIVE_POPADMIN = "i:popadmin";
    bytes32 constant CONTRACT_INTERACTIVE_PRODUCTS_LIST = "i:products";
    bytes32 constant CONTRACT_INTERACTIVE_TOKEN = "i:token";
    bytes32 constant CONTRACT_INTERACTIVE_BULK_WRAPPER = "i:bulk-wrapper";
    bytes32 constant CONTRACT_INTERACTIVE_TOKEN_CONFIG = "i:token:config";
    bytes32 constant CONTRACT_INTERACTIVE_TOKEN_INFORMATION = "i:token:information";
    bytes32 constant CONTRACT_INTERACTIVE_MARKETPLACE_INFORMATION = "i:mp:information";
    bytes32 constant CONTRACT_INTERACTIVE_IDENTITY = "i:identity";

    /// controller contracts
    bytes32 constant CONTRACT_CONTROLLER_ASSETS = "c:asset";
    bytes32 constant CONTRACT_CONTROLLER_ASSETS_RECAST = "c:asset:recast";
    bytes32 constant CONTRACT_CONTROLLER_ASSETS_EXPLORER = "c:explorer";
    bytes32 constant CONTRACT_CONTROLLER_DIGIX_DIRECTORY = "c:directory";
    bytes32 constant CONTRACT_CONTROLLER_MARKETPLACE = "c:mp";
    bytes32 constant CONTRACT_CONTROLLER_MARKETPLACE_ADMIN = "c:mpadmin";
    bytes32 constant CONTRACT_CONTROLLER_PRODUCTS_LIST = "c:products";

    bytes32 constant CONTRACT_CONTROLLER_TOKEN_APPROVAL = "c:token:approval";
    bytes32 constant CONTRACT_CONTROLLER_TOKEN_CONFIG = "c:token:config";
    bytes32 constant CONTRACT_CONTROLLER_TOKEN_INFO = "c:token:info";
    bytes32 constant CONTRACT_CONTROLLER_TOKEN_TRANSFER = "c:token:transfer";

    bytes32 constant CONTRACT_CONTROLLER_JOB_ID = "c:jobid";
    bytes32 constant CONTRACT_CONTROLLER_IDENTITY = "c:identity";

    /// storage contracts
    bytes32 constant CONTRACT_STORAGE_ASSETS = "s:asset";
    bytes32 constant CONTRACT_STORAGE_ASSET_EVENTS = "s:asset:events";
    bytes32 constant CONTRACT_STORAGE_DIGIX_DIRECTORY = "s:directory";
    bytes32 constant CONTRACT_STORAGE_MARKETPLACE = "s:mp";
    bytes32 constant CONTRACT_STORAGE_PRODUCTS_LIST = "s:products";
    bytes32 constant CONTRACT_STORAGE_GOLD_TOKEN = "s:goldtoken";
    bytes32 constant CONTRACT_STORAGE_JOB_ID = "s:jobid";
    bytes32 constant CONTRACT_STORAGE_IDENTITY = "s:identity";

    /// service contracts
    bytes32 constant CONTRACT_SERVICE_TOKEN_DEMURRAGE = "sv:tdemurrage";
    bytes32 constant CONTRACT_SERVICE_MARKETPLACE = "sv:mp";
    bytes32 constant CONTRACT_SERVICE_DIRECTORY = "sv:directory";

    /// fees distributors
    bytes32 constant CONTRACT_DEMURRAGE_FEES_DISTRIBUTOR = "fees:distributor:demurrage";
    bytes32 constant CONTRACT_RECAST_FEES_DISTRIBUTOR = "fees:distributor:recast";
    bytes32 constant CONTRACT_TRANSFER_FEES_DISTRIBUTOR = "fees:distributor:transfer";
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract ResolverClient {
  /// @dev Get the address of a contract
  /// @param _key the resolver key to look up
  /// @return _contract the address of the contract
  function get_contract(bytes32 _key) public constant returns (address _contract);
}

contract TokenInformation is ResolverClient {
  function showDemurrageConfigs() public constant returns (uint256 _base, uint256 _rate, address _collector, bool _no_demurrage_fee);
  function showCollectorsAddresses() public constant returns (address[3] _collectors);
}

contract Token {
  function totalSupply() constant public returns (uint256 _total_supply);
  function balanceOf(address _owner) constant public returns (uint256 balance);
}

contract DgxDemurrageCalculator {
  address public TOKEN_ADDRESS;
  address public TOKEN_INFORMATION_ADDRESS;

  function token_information() internal view returns (TokenInformation _token_information) {
    _token_information = TokenInformation(TOKEN_INFORMATION_ADDRESS);
  }

  function DgxDemurrageCalculator(address _token_address, address _token_information_address) public {
    TOKEN_ADDRESS = _token_address;
    TOKEN_INFORMATION_ADDRESS = _token_information_address;
  }

  function calculateDemurrage(uint256 _initial_balance, uint256 _days_elapsed)
           public
           view
           returns (uint256 _demurrage_fees, bool _no_demurrage_fees)
  {
    uint256 _base;
    uint256 _rate;
    (_base, _rate,,_no_demurrage_fees) = token_information().showDemurrageConfigs();
    _demurrage_fees = (_initial_balance * _days_elapsed * _rate) / _base;
  }
}


/// @title Digix Gold Token Demurrage Reporter
/// @author Digix Holdings Pte Ltd
/// @notice This contract is used to keep a close estimate of how much demurrage fees would have been collected on Digix Gold Token if the demurrage fees is on.
/// @notice Anyone can call the function updateDemurrageReporter() to keep this contract updated to the lastest day. The more often this function is called the more accurate the estimate will be (but it can only be updated at most every 24hrs)
contract DgxDemurrageReporter is DgxDemurrageCalculator, Claimable, DigixConstants {
  address[] public exempted_accounts;
  uint256 public last_demurrageable_balance; // the total balance of DGX in non-exempted accounts, at last_payment_timestamp
  uint256 public last_payment_timestamp;  // the last time this contract is updated
  uint256 public culmulative_demurrage_collected; // this is the estimate of the demurrage fees that would have been collected from start_of_report_period to last_payment_timestamp
  uint256 public start_of_report_period; // the timestamp when this contract started keeping track of demurrage fees

  using Types for Types.MutableTimestamp;

  function DgxDemurrageReporter(address _token_address, address _token_information_address) public DgxDemurrageCalculator(_token_address, _token_information_address)
  {
    address[3] memory _collectors;
    _collectors = token_information().showCollectorsAddresses();
    exempted_accounts.push(_collectors[0]);
    exempted_accounts.push(_collectors[1]);
    exempted_accounts.push(_collectors[2]);

    exempted_accounts.push(token_information().get_contract(CONTRACT_DEMURRAGE_FEES_DISTRIBUTOR));
    exempted_accounts.push(token_information().get_contract(CONTRACT_RECAST_FEES_DISTRIBUTOR));
    exempted_accounts.push(token_information().get_contract(CONTRACT_TRANSFER_FEES_DISTRIBUTOR));

    exempted_accounts.push(token_information().get_contract(CONTRACT_STORAGE_MARKETPLACE));
    start_of_report_period = now;
    last_payment_timestamp = now;
    updateDemurrageReporter();
  }

  function addExemptedAccount(address _account) public onlyOwner {
    exempted_accounts.push(_account);
  }

  function updateDemurrageReporter() public {
    Types.MutableTimestamp memory payment_timestamp;
    payment_timestamp.time.pre = last_payment_timestamp;
    payment_timestamp = payment_timestamp.advance_by(1 days);

    uint256 _base;
    uint256 _rate;
    (_base, _rate,,) = token_information().showDemurrageConfigs();

    culmulative_demurrage_collected += (payment_timestamp.in_units * last_demurrageable_balance * _rate) / _base;
    last_payment_timestamp = payment_timestamp.time.post;
    last_demurrageable_balance = getDemurrageableBalance();
  }

  function getDemurrageableBalance() internal view returns (uint256 _last_demurrageable_balance) {
    Token token = Token(TOKEN_ADDRESS);
    uint256 _total_supply = token.totalSupply();
    uint256 _no_demurrage_balance = 0;
    for (uint256 i=0;i<exempted_accounts.length;i++) {
      _no_demurrage_balance += token.balanceOf(exempted_accounts[i]);
    }
    _last_demurrageable_balance = _total_supply - _no_demurrage_balance;
  }

}