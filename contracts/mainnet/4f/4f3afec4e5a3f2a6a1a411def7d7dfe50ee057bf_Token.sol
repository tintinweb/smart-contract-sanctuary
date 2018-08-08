pragma solidity ^0.4.19;

/// @title Contract Resolver Interface
/// @author Digix Holdings Pte Ltd

contract ResolverClient {

  /// The address of the resolver contract for this project
  address public resolver;
  /// The key to identify this contract
  bytes32 public key;

  /// Make our own address available to us as a constant
  address public CONTRACT_ADDRESS;

  /// Function modifier to check if msg.sender corresponds to the resolved address of a given key
  /// @param _contract The resolver key
  modifier if_sender_is(bytes32 _contract) {
    require(msg.sender == ContractResolver(resolver).get_contract(_contract));
    _;
  }

  /// Function modifier to check resolver&#39;s locking status.
  modifier unless_resolver_is_locked() {
    require(is_locked() == false);
    _;
  }

  /// @dev Initialize new contract
  /// @param _key the resolver key for this contract
  /// @return _success if the initialization is successful
  function init(bytes32 _key, address _resolver)
           internal
           returns (bool _success)
  {
    bool _is_locked = ContractResolver(_resolver).locked();
    if (_is_locked == false) {
      CONTRACT_ADDRESS = address(this);
      resolver = _resolver;
      key = _key;
      require(ContractResolver(resolver).init_register_contract(key, CONTRACT_ADDRESS));
      _success = true;
    }  else {
      _success = false;
    }
  }

  /// @dev Destroy the contract and unregister self from the ContractResolver
  /// @dev Can only be called by the owner of ContractResolver
  function destroy()
           public
           returns (bool _success)
  {
    bool _is_locked = ContractResolver(resolver).locked();
    require(!_is_locked);

    address _owner_of_contract_resolver = ContractResolver(resolver).owner();
    require(msg.sender == _owner_of_contract_resolver);

    _success = ContractResolver(resolver).unregister_contract(key);
    require(_success);

    selfdestruct(_owner_of_contract_resolver);
  }

  /// @dev Check if resolver is locked
  /// @return _locked if the resolver is currently locked
  function is_locked()
           private
           constant
           returns (bool _locked)
  {
    _locked = ContractResolver(resolver).locked();
  }

  /// @dev Get the address of a contract
  /// @param _key the resolver key to look up
  /// @return _contract the address of the contract
  function get_contract(bytes32 _key)
           public
           constant
           returns (address _contract)
  {
    _contract = ContractResolver(resolver).get_contract(_key);
  }
}

contract ContractResolver {
  address public owner;
  bool public locked;
  function init_register_contract(bytes32 _key, address _contract_address)
           public
           returns (bool _success) {}

  /// @dev Unregister a contract.  This can only be called from the contract with the key itself
  /// @param _key the bytestring of the contract name
  /// @return _success if the operation is successful
  function unregister_contract(bytes32 _key)
           public
           returns (bool _success) {}

  /// @dev Get address of a contract
  /// @param _key the bytestring name of the contract to look up
  /// @return _contract the address of the contract
  function get_contract(bytes32 _key)
           public
           constant
           returns (address _contract) {}
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

contract TokenLoggerCallback is ResolverClient, DigixConstants {

  event Transfer(address indexed _from,  address indexed _to,  uint256 _value);
  event Approval(address indexed _owner,  address indexed _spender,  uint256 _value);

  function log_mint(address _to, uint256 _value)
           if_sender_is(CONTRACT_CONTROLLER_ASSETS)
           public
  {
    Transfer(address(0x0), _to, _value);
  }

  function log_recast_fees(address _from, address _to, uint256 _value)
           if_sender_is(CONTRACT_CONTROLLER_ASSETS_RECAST)
           public
  {
    Transfer(_from, _to, _value);
  }

  function log_recast(address _from, uint256 _value)
           if_sender_is(CONTRACT_CONTROLLER_ASSETS_RECAST)
           public
  {
    Transfer(_from, address(0x0), _value);
  }

  function log_demurrage_fees(address _from, address _to, uint256 _value)
           if_sender_is(CONTRACT_SERVICE_TOKEN_DEMURRAGE)
           public
  {
    Transfer(_from, _to, _value);
  }

  function log_move_fees(address _from, address _to, uint256 _value)
           if_sender_is(CONTRACT_CONTROLLER_TOKEN_CONFIG)
           public
  {
    Transfer(_from, _to, _value);
  }

  function log_transfer(address _from, address _to, uint256 _value)
           if_sender_is(CONTRACT_CONTROLLER_TOKEN_TRANSFER)
           public
  {
    Transfer(_from, _to, _value);
  }

  function log_approve(address _owner, address _spender, uint256 _value)
           if_sender_is(CONTRACT_CONTROLLER_TOKEN_APPROVAL)
           public
  {
    Approval(_owner, _spender, _value);
  }

}


contract TokenInfoController {
  function get_total_supply() constant public returns (uint256 _total_supply){}
  function get_allowance(address _account, address _spender) constant public returns (uint256 _allowance){}
  function get_balance(address _user) constant public returns (uint256 _actual_balance){}
}

contract TokenTransferController {
  function put_transfer(address _sender, address _recipient, address _spender, uint256 _amount, bool _transfer_from) public returns (bool _success){}
}

contract TokenApprovalController {
  function approve(address _account, address _spender, uint256 _amount) public returns (bool _success){}
}

/// The interface of a contract that can receive tokens from transferAndCall()
contract TokenReceiver {
  function tokenFallback(address from, uint256 amount, bytes32 data) public returns (bool success);
}

/// @title DGX2.0 ERC-20 Token. ERC-677 is also implemented https://github.com/ethereum/EIPs/issues/677
/// @author Digix Holdings Pte Ltd
contract Token is TokenLoggerCallback {

  string public constant name = "Digix Gold Token";
  string public constant symbol = "DGX";
  uint8 public constant decimals = 9;

  function Token(address _resolver) public
  {
    require(init(CONTRACT_INTERACTIVE_TOKEN, _resolver));
  }

  /// @notice show the total supply of gold tokens
  /// @return {
  ///    "totalSupply": "total number of tokens"
  /// }
  function totalSupply()
           constant
           public
           returns (uint256 _total_supply)
  {
    _total_supply = TokenInfoController(get_contract(CONTRACT_CONTROLLER_TOKEN_INFO)).get_total_supply();
  }

  /// @notice display balance of given account
  /// @param _owner the account to query
  /// @return {
  ///    "balance": "balance of the given account in nanograms"
  /// }
  function balanceOf(address _owner)
           constant
           public
           returns (uint256 balance)
  {
    balance = TokenInfoController(get_contract(CONTRACT_CONTROLLER_TOKEN_INFO)).get_balance(_owner);
  }

  /// @notice transfer amount to account
  /// @param _to account to send to
  /// @param _value the amount in nanograms to send
  /// @return {
  ///    "success": "returns true if successful"
  /// }
  function transfer(address _to, uint256 _value)
           public
           returns (bool success)
  {
    success =
      TokenTransferController(get_contract(CONTRACT_CONTROLLER_TOKEN_TRANSFER)).put_transfer(msg.sender, _to, 0x0, _value, false);
  }

  /// @notice transfer amount to account from account deducting from spender allowance
  /// @param _to account to send to
  /// @param _from account to send from
  /// @param _value the amount in nanograms to send
  /// @return {
  ///    "success": "returns true if successful"
  /// }
  function transferFrom(address _from, address _to, uint256 _value)
           public
           returns (bool success)
  {
    success =
      TokenTransferController(get_contract(CONTRACT_CONTROLLER_TOKEN_TRANSFER)).put_transfer(_from, _to, msg.sender,
                                                                             _value, true);
  }

  /// @notice implements transferAndCall() of ERC677
  /// @param _receiver the contract to receive the token
  /// @param _amount the amount of tokens to be transfered
  /// @param _data the data to be passed to the tokenFallback function of the receiving contract
  /// @return {
  ///    "success": "returns true if successful"
  /// }
  function transferAndCall(address _receiver, uint256 _amount, bytes32 _data)
           public
           returns (bool success)
  {
    transfer(_receiver, _amount);
    success = TokenReceiver(_receiver).tokenFallback(msg.sender, _amount, _data);
    require(success);
  }

  /// @notice approve given spender to transfer given amount this will set allowance to 0 if current value is non-zero
  /// @param _spender the account that is given an allowance
  /// @param _value the amount in nanograms to approve
  /// @return {
  ///   "success": "returns true if successful"
  /// }
  function approve(address _spender, uint256 _value)
           public
           returns (bool success)
  {
    success = TokenApprovalController(get_contract(CONTRACT_CONTROLLER_TOKEN_APPROVAL)).approve(msg.sender, _spender, _value);
  }

  /// @notice check the spending allowance of a given user from a given account
  /// @param _owner the account to spend from
  /// @param _spender the spender
  /// @return {
  ///    "remaining": "the remaining allowance in nanograms"
  /// }
  function allowance(address _owner, address _spender)
           constant
           public
           returns (uint256 remaining)
  {
    remaining = TokenInfoController(get_contract(CONTRACT_CONTROLLER_TOKEN_INFO)).get_allowance(_owner, _spender);
  }

}