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

/// @title Some useful constants
/// @author Digix Holdings Pte Ltd
contract Constants {
  address constant NULL_ADDRESS = address(0x0);
  uint256 constant ZERO = uint256(0);
  bytes32 constant EMPTY = bytes32(0x0);
}

/// @title Condition based access control
/// @author Digix Holdings Pte Ltd
contract ACConditions is Constants {

  modifier not_null_address(address _item) {
    require(_item != NULL_ADDRESS);
    _;
  }

  modifier if_null_address(address _item) {
    require(_item == NULL_ADDRESS);
    _;
  }

  modifier not_null_uint(uint256 _item) {
    require(_item != ZERO);
    _;
  }

  modifier if_null_uint(uint256 _item) {
    require(_item == ZERO);
    _;
  }

  modifier not_empty_bytes(bytes32 _item) {
    require(_item != EMPTY);
    _;
  }

  modifier if_empty_bytes(bytes32 _item) {
    require(_item == EMPTY);
    _;
  }

  modifier not_null_string(string _item) {
    bytes memory _i = bytes(_item);
    require(_i.length > 0);
    _;
  }

  modifier if_null_string(string _item) {
    bytes memory _i = bytes(_item);
    require(_i.length == 0);
    _;
  }

  modifier require_gas(uint256 _requiredgas) {
    require(msg.gas  >= (_requiredgas - 22000));
    _;
  }

  function is_contract(address _contract)
           public
           constant
           returns (bool _is_contract)
  {
    uint32 _code_length;

    assembly {
      _code_length := extcodesize(_contract)
    }

    if(_code_length > 1) {
      _is_contract = true;
    } else {
      _is_contract = false;
    }
  }

  modifier if_contract(address _contract) {
    require(is_contract(_contract) == true);
    _;
  }

  modifier unless_contract(address _contract) {
    require(is_contract(_contract) == false);
    _;
  }
}

contract MarketplaceAdminController {
}

contract MarketplaceStorage {
}

contract MarketplaceController {
  function put_purchase_for(uint256 _wei_sent, address _buyer, address _recipient, uint256 _block_number, uint256 _nonce, uint256 _wei_per_dgx_mg, address _signer, bytes _signature) payable public returns (bool _success, uint256 _purchased_amount);
}

contract MarketplaceCommon is ResolverClient, ACConditions, DigixConstants {

  function marketplace_admin_controller()
           internal
           constant
           returns (MarketplaceAdminController _contract)
  {
    _contract = MarketplaceAdminController(get_contract(CONTRACT_CONTROLLER_MARKETPLACE_ADMIN));
  }

  function marketplace_storage()
           internal
           constant
           returns (MarketplaceStorage _contract)
  {
    _contract = MarketplaceStorage(get_contract(CONTRACT_STORAGE_MARKETPLACE));
  }

  function marketplace_controller()
           internal
           constant
           returns (MarketplaceController _contract)
  {
    _contract = MarketplaceController(get_contract(CONTRACT_CONTROLLER_MARKETPLACE));
  }
}

/// @title Digix&#39;s Marketplace
/// @author Digix Holdings Pte Ltd
/// @notice This contract is for KYC-approved users to purchase DGX using ETH
contract Marketplace is MarketplaceCommon {

  function Marketplace(address _resolver) public
  {
    require(init(CONTRACT_INTERACTIVE_MARKETPLACE, _resolver));
  }

  /// @dev purchase DGX gold
  /// @param _block_number Block number from DTPO (Digix Trusted Price Oracle)
  /// @param _nonce Nonce from DTPO
  /// @param _wei_per_dgx_mg Price in wei for one milligram of DGX
  /// @param _signer Address of the DTPO signer
  /// @param _signature Signature of the payload
  /// @return {
  ///   &quot;_success&quot;: &quot;returns true if operation is successful&quot;,
  ///   &quot;_purchased_amount&quot;: &quot;DGX nanograms received&quot;
  /// }
  function purchase(uint256 _block_number, uint256 _nonce, uint256 _wei_per_dgx_mg, address _signer, bytes _signature)
           payable
           public
           returns (bool _success, uint256 _purchased_amount)
  {
    address _sender = msg.sender;

    (_success, _purchased_amount) =
      marketplace_controller().put_purchase_for.value(msg.value).gas(600000)(msg.value, _sender, _sender, _block_number,
                                                                             _nonce, _wei_per_dgx_mg, _signer, _signature);
    require(_success);
  }
}