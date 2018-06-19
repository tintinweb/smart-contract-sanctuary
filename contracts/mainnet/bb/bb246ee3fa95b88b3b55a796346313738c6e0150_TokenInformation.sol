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
  bytes32 constant CONTRACT_INTERACTIVE_ASSETS_EXPLORER = &quot;i:asset:explorer&quot;;
  bytes32 constant CONTRACT_INTERACTIVE_DIGIX_DIRECTORY = &quot;i:directory&quot;;
  bytes32 constant CONTRACT_INTERACTIVE_MARKETPLACE = &quot;i:mp&quot;;
  bytes32 constant CONTRACT_INTERACTIVE_MARKETPLACE_ADMIN = &quot;i:mpadmin&quot;;
  bytes32 constant CONTRACT_INTERACTIVE_POPADMIN = &quot;i:popadmin&quot;;
  bytes32 constant CONTRACT_INTERACTIVE_PRODUCTS_LIST = &quot;i:products&quot;;
  bytes32 constant CONTRACT_INTERACTIVE_TOKEN = &quot;i:token&quot;;
  bytes32 constant CONTRACT_INTERACTIVE_BULK_WRAPPER = &quot;i:bulk-wrapper&quot;;
  bytes32 constant CONTRACT_INTERACTIVE_TOKEN_CONFIG = &quot;i:token:config&quot;;
  bytes32 constant CONTRACT_INTERACTIVE_TOKEN_INFORMATION = &quot;i:token:information&quot;;
  bytes32 constant CONTRACT_INTERACTIVE_MARKETPLACE_INFORMATION = &quot;i:mp:information&quot;;
  bytes32 constant CONTRACT_INTERACTIVE_IDENTITY = &quot;i:identity&quot;;

  /// controller contracts
  bytes32 constant CONTRACT_CONTROLLER_ASSETS = &quot;c:asset&quot;;
  bytes32 constant CONTRACT_CONTROLLER_ASSETS_RECAST = &quot;c:asset:recast&quot;;
  bytes32 constant CONTRACT_CONTROLLER_ASSETS_EXPLORER = &quot;c:explorer&quot;;
  bytes32 constant CONTRACT_CONTROLLER_DIGIX_DIRECTORY = &quot;c:directory&quot;;
  bytes32 constant CONTRACT_CONTROLLER_MARKETPLACE = &quot;c:mp&quot;;
  bytes32 constant CONTRACT_CONTROLLER_MARKETPLACE_ADMIN = &quot;c:mpadmin&quot;;
  bytes32 constant CONTRACT_CONTROLLER_PRODUCTS_LIST = &quot;c:products&quot;;

  bytes32 constant CONTRACT_CONTROLLER_TOKEN_APPROVAL = &quot;c:token:approval&quot;;
  bytes32 constant CONTRACT_CONTROLLER_TOKEN_CONFIG = &quot;c:token:config&quot;;
  bytes32 constant CONTRACT_CONTROLLER_TOKEN_INFO = &quot;c:token:info&quot;;
  bytes32 constant CONTRACT_CONTROLLER_TOKEN_TRANSFER = &quot;c:token:transfer&quot;;

  bytes32 constant CONTRACT_CONTROLLER_JOB_ID = &quot;c:jobid&quot;;
  bytes32 constant CONTRACT_CONTROLLER_IDENTITY = &quot;c:identity&quot;;

  /// storage contracts
  bytes32 constant CONTRACT_STORAGE_ASSETS = &quot;s:asset&quot;;
  bytes32 constant CONTRACT_STORAGE_ASSET_EVENTS = &quot;s:asset:events&quot;;
  bytes32 constant CONTRACT_STORAGE_DIGIX_DIRECTORY = &quot;s:directory&quot;;
  bytes32 constant CONTRACT_STORAGE_MARKETPLACE = &quot;s:mp&quot;;
  bytes32 constant CONTRACT_STORAGE_PRODUCTS_LIST = &quot;s:products&quot;;
  bytes32 constant CONTRACT_STORAGE_GOLD_TOKEN = &quot;s:goldtoken&quot;;
  bytes32 constant CONTRACT_STORAGE_JOB_ID = &quot;s:jobid&quot;;
  bytes32 constant CONTRACT_STORAGE_IDENTITY = &quot;s:identity&quot;;

  /// service contracts
  bytes32 constant CONTRACT_SERVICE_TOKEN_DEMURRAGE = &quot;sv:tdemurrage&quot;;
  bytes32 constant CONTRACT_SERVICE_MARKETPLACE = &quot;sv:mp&quot;;
  bytes32 constant CONTRACT_SERVICE_DIRECTORY = &quot;sv:directory&quot;;

  /// fees distributors
  bytes32 constant CONTRACT_DEMURRAGE_FEES_DISTRIBUTOR = &quot;fees:distributor:demurrage&quot;;
  bytes32 constant CONTRACT_RECAST_FEES_DISTRIBUTOR = &quot;fees:distributor:recast&quot;;
  bytes32 constant CONTRACT_TRANSFER_FEES_DISTRIBUTOR = &quot;fees:distributor:transfer&quot;;
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
  ///   &quot;_base&quot;: &quot;denominator for calculating demurrage fees&quot;,
  ///   &quot;_rate&quot;: &quot;numerator for calculating demurrage fees&quot;,
  ///   &quot;_collector&quot;: &quot;ethereum address of the demurrage fees collector&quot;
  ///   &quot;_no_demurrage_fee&quot;: &quot;true if demurrage fees is turned off globally&quot;
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
  ///   &quot;_base&quot;: &quot;denominator for calculating recast fees&quot;,
  ///   &quot;_rate&quot;: &quot;numerator for calculating recast fees&quot;,
  ///   &quot;_collector&quot;: &quot;ethereum address of the recast fees collector&quot;
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
  ///   &quot;_base&quot;: &quot;denominator for calculating transfer fees&quot;,
  ///   &quot;_rate&quot;: &quot;numerator for calculating transfer fees&quot;,
  ///   &quot;_collector&quot;: &quot;the ethereum address of the transfer fees collector&quot;,
  ///   &quot;_no_transfer_fee&quot;: &quot;true if transfer fees is turned off globally&quot;,
  ///   &quot;_minimum_transfer_amount&quot;: &quot;minimum amount of DGX that can be transferred&quot;
  /// }
  function showTransferConfigs()
           public
           constant
           returns (uint256 _base, uint256 _rate, address _collector, bool _no_transfer_fee, uint256 _minimum_transfer_amount)
  {
    (,_base, _rate, _collector, _no_transfer_fee, _minimum_transfer_amount) = gold_token_storage().read_transfer_config();
  }

}