pragma solidity ^0.4.19;

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

contract ContractResolver {
  address public owner;
  bool public locked;
  function init_register_contract(bytes32 _key, address _contract_address) public returns (bool _success);
  function unregister_contract(bytes32 _key) public returns (bool _success);
  function get_contract(bytes32 _key) public constant returns (address _contract);
}

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

contract GoldTokenStorage {
  function read_collectors_addresses() constant public returns (address[3] _collectors);
  function read_demurrage_config_underlying() public constant returns (uint256 _base, uint256 _rate, address _collector, bool _no_demurrage_fee);
  function read_recast_config() constant public returns (uint256 _base, uint256 _rate, uint256 _total_supply, uint256 _effective_total_supply, address _collector, uint256 _collector_balance);
  function read_transfer_config() public constant returns (uint256 _collector_balance, uint256 _base, uint256 _rate, address _collector, bool _no_transfer_fee, uint256 _minimum_transfer_amount);
}

contract ERCTwenty {
  function balanceOf( address who ) constant public returns (uint value);
}

/// @title Digix Gold Token&#39;s Information
/// @author Digix Holdings Pte Ltd
/// @notice This contract is used to read configs and information related to the Digix Gold Token
contract TokenInformation is ResolverClient, DigixConstants {

  function TokenInformation(address _resolver) public
  {
    require(init(CONTRACT_INTERACTIVE_TOKEN_INFORMATION, _resolver));
  }

  function gold_token_storage()
           internal
           constant
           returns (GoldTokenStorage _contract)
  {
    _contract = GoldTokenStorage(get_contract(CONTRACT_STORAGE_GOLD_TOKEN));
  }

  function token()
           internal
           constant
           returns (ERCTwenty _contract)
  {
    _contract = ERCTwenty(get_contract(CONTRACT_INTERACTIVE_TOKEN));
  }

  /// @dev read the addresses of the fees collectors
  /// @return _collectors the addresses (_collectors[0] = demurrage, _collectors[1] = recast, _collectors[2] = transfer)
  function showCollectorsAddresses()
           public
           constant
           returns (address[3] _collectors)
  {
    // order: demurrage, recast, transfer
    _collectors = gold_token_storage().read_collectors_addresses();
  }

  /// @dev read the balances of the fees collectors addresses
  /// @return _balances the balances (_balances[0] = demurrage, _balances[1] = recast, _balances[2] = transfer)
  function showCollectorsBalances()
           public
           constant
           returns (uint256[3] _balances)
  {
    // order: demurrage, recast, transfer
    address[3] memory _collectors = showCollectorsAddresses();
    for (uint256 i=0;i<3;i++) {
      _balances[i] = token().balanceOf(_collectors[i]);
    }
  }

  /// @dev read the demurrage configurations
  /// @return {
  ///   "_base": "denominator for calculating demurrage fees",
  ///   "_rate": "numerator for calculating demurrage fees",
  ///   "_collector": "ethereum address of the demurrage fees collector"
  ///   "_no_demurrage_fee": "true if demurrage fees is turned off globally"
  /// }
  function showDemurrageConfigs()
           public
           constant
           returns (uint256 _base, uint256 _rate, address _collector, bool _no_demurrage_fee)
  {
    (_base, _rate, _collector, _no_demurrage_fee) = gold_token_storage().read_demurrage_config_underlying();
  }

  /// @dev read the recast configurations
  /// @return {
  ///   "_base": "denominator for calculating recast fees",
  ///   "_rate": "numerator for calculating recast fees",
  ///   "_collector": "ethereum address of the recast fees collector"
  /// }
  function showRecastConfigs()
           public
           constant
           returns (uint256 _base, uint256 _rate, address _collector)
  {
    (_base, _rate,,, _collector,) = gold_token_storage().read_recast_config();
  }

  /// @dev read transfer configurations
  /// @return {
  ///   "_base": "denominator for calculating transfer fees",
  ///   "_rate": "numerator for calculating transfer fees",
  ///   "_collector": "the ethereum address of the transfer fees collector",
  ///   "_no_transfer_fee": "true if transfer fees is turned off globally",
  ///   "_minimum_transfer_amount": "minimum amount of DGX that can be transferred"
  /// }
  function showTransferConfigs()
           public
           constant
           returns (uint256 _base, uint256 _rate, address _collector, bool _no_transfer_fee, uint256 _minimum_transfer_amount)
  {
    (,_base, _rate, _collector, _no_transfer_fee, _minimum_transfer_amount) = gold_token_storage().read_transfer_config();
  }

}