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

contract Constants {
  address constant NULL_ADDRESS = address(0x0);
  uint256 constant ZERO = uint256(0);
  bytes32 constant EMPTY = bytes32(0x0);
}

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

contract MarketplaceStorage {
}

contract MarketplaceControllerCommon {
}

contract MarketplaceController {
}

contract MarketplaceAdminController {
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

contract DigixConstantsExtras {
    /// storage contracts
    bytes32 constant CONTRACT_STORAGE_MARKETPLACE_EXTRAS = "s:mp:extras";
    bytes32 constant CONTRACT_CONTROLLER_MARKETPLACE_ADMIN_EXTRAS = "c:mpadmin:extras";
    bytes32 constant CONTRACT_INTERACTIVE_MARKETPLACE_V2 = "i:mp:v2";
    bytes32 constant CONTRACT_INTERACTIVE_MARKETPLACE_ADMIN_EXTRAS = "i:mpadmin:extras";
}

contract MarketplaceControllerV2 {
  function purchase_with_eth(
    uint256 _wei_sent,
    address _buyer,
    uint256 _block_number,
    uint256 _nonce,
    uint256 _wei_per_dgx_mg,
    address _signer,
    bytes _signature
  ) payable public returns (bool _success, uint256 _purchased_amount);

  function purchase_with_dai(
    uint256 _dai_sent,
    address _buyer,
    uint256 _block_number,
    uint256 _nonce,
    uint256 _dai_per_ton,
    address _signer,
    bytes _signature
  ) public returns (bool _success, uint256 _purchased_amount);
}

/// @title Digix&#39;s Marketplace
/// @author Digix Holdings Pte Ltd
/// @notice This contract is for KYC-approved users to purchase DGX using ETH
contract MarketplaceV2 is MarketplaceCommon, DigixConstantsExtras {

  function MarketplaceV2(address _resolver) public
  {
    require(init(CONTRACT_INTERACTIVE_MARKETPLACE_V2, _resolver));
  }

  function marketplace_controller_v2()
           internal
           constant
           returns (MarketplaceControllerV2 _contract)
  {
    _contract = MarketplaceControllerV2(get_contract(CONTRACT_CONTROLLER_MARKETPLACE));
  }

  /// @dev purchase DGX gold using ETH
  /// @param _block_number Block number from DTPO (Digix Trusted Price Oracle)
  /// @param _nonce Nonce from DTPO
  /// @param _wei_per_dgx_mg Price in wei for one milligram of DGX
  /// @param _signer Address of the DTPO signer
  /// @param _signature Signature of the payload
  /// @return {
  ///   "_success": "returns true if operation is successful",
  ///   "_purchased_amount": "DGX nanograms received"
  /// }
  function purchaseWithEth(uint256 _block_number, uint256 _nonce, uint256 _wei_per_dgx_mg, address _signer, bytes _signature)
           payable
           public
           returns (bool _success, uint256 _purchased_amount)
  {
    address _sender = msg.sender;

    (_success, _purchased_amount) =
      marketplace_controller_v2().purchase_with_eth.value(msg.value).gas(600000)(msg.value, _sender, _block_number,
                                                                             _nonce, _wei_per_dgx_mg, _signer, _signature);
    require(_success);
  }

  /// @dev purchase DGX gold using DAI
  /// @param _dai_sent amount of DAI sent
  /// @param _block_number Block number from DTPO (Digix Trusted Price Oracle)
  /// @param _nonce Nonce from DTPO
  /// @param _dai_per_ton Despite the variable name, this is actually the price in DAI for 1000 tonnes of DGXs
  /// @param _signer Address of the DTPO signer
  /// @param _signature Signature of the payload
  /// @return {
  ///   "_success": "returns true if operation is successful",
  ///   "_purchased_amount": "DGX nanograms received"
  /// }
  function purchaseWithDai(uint256 _dai_sent, uint256 _block_number, uint256 _nonce, uint256 _dai_per_ton, address _signer, bytes _signature)
           public
           returns (bool _success, uint256 _purchased_amount)
  {
    address _sender = msg.sender;

    (_success, _purchased_amount) =
      marketplace_controller_v2().purchase_with_dai.gas(800000)(_dai_sent, _sender, _block_number,
                                                                             _nonce, _dai_per_ton, _signer, _signature);
    require(_success);
  }
}