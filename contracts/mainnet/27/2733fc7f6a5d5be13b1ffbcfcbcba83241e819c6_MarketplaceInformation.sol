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

contract IdentityStorage {
  function read_user(address _user) public constant returns (uint256 _id_expiration, bytes32 _doc);
}

contract MarketplaceStorage {
  function read_user(address _user) public constant returns (uint256 _daily_dgx_limit, uint256 _total_purchased_today);
  function read_user_daily_limit(address _user) public constant returns (uint256 _daily_dgx_limit);
  function read_config() public constant returns (uint256 _global_daily_dgx_ng_limit, uint256 _minimum_purchase_dgx_ng, uint256 _maximum_block_drift, address _payment_collector);
  function read_dgx_inventory_balance_ng() public constant returns (uint256 _balance);
  function read_total_number_of_purchases() public constant returns (uint256 _total_number_of_purchases);
  function read_total_number_of_user_purchases(address _user) public constant returns (uint256 _total_number_of_user_purchases);
  function read_purchase_at_index(uint256 _index) public constant returns (address _recipient, uint256 _timestamp, uint256 _amount, uint256 _price);
  function read_user_purchase_at_index(address _user, uint256 _index) public constant returns (address _recipient, uint256 _timestamp, uint256 _amount, uint256 _price);
  function read_total_global_purchased_today() public constant returns (uint256 _total_global_purchased_today);
  function read_total_purchased_today(address _user) public constant returns (uint256 _total_purchased_today);
  function read_max_dgx_available_daily() public constant returns (uint256 _max_dgx_available_daily);
  function read_price_floor() public constant returns (uint256 _price_floor_wei_per_dgx_mg);
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

/// @title Digix Marketplace Information
/// @author Digix Holdings Pte Ltd
/// @notice This contract is used to read the configuration of the Digix&#39;s Marketplace
contract MarketplaceInformation is MarketplaceCommon {

  function MarketplaceInformation(address _resolver) public
  {
    require(init(CONTRACT_INTERACTIVE_MARKETPLACE_INFORMATION, _resolver));
  }

  function identity_storage()
           internal
           constant
           returns (IdentityStorage _contract)
  {
    _contract = IdentityStorage(get_contract(CONTRACT_STORAGE_IDENTITY));
  }

  /// @dev show user&#39;s current marketplace information and configuration, as well as some global configurations
  /// @param _user the user&#39;s ethereum address
  /// @return {
  ///   &quot;_user_daily_dgx_limit&quot;: &quot;the amount of DGX that the user can purchase at any given day&quot;,
  ///   &quot;_user_id_expiration&quot;: &quot;if KYC approved this will be a non-zero value as Unix timestamp when the submitted ID will expire&quot;,
  ///   &quot;_user_total_purchased_today&quot;: &quot;The amount of tokens that the user has purchased in the last 24 hours&quot;,
  ///   &quot;_config_maximum_block_drift&quot;: &quot;The number of ethereum blocks for which a pricefeed is valid for&quot;
  ///   &quot;_config_minimum_purchase_dgx_ng&quot;: &quot;The minimum amount of DGX that has to be purchased in one order&quot;,
  ///   &quot;_config_payment_collector&quot;: &quot;Ethereum address of the collector which collects marketplace ether sent by buyers to buy DGX&quot;
  /// }
  function getUserInfoAndConfig(address _user)
           public
           constant
           returns (uint256 _user_daily_dgx_limit, uint256 _user_id_expiration, uint256 _user_total_purchased_today,
                    uint256 _config_global_daily_dgx_ng_limit, uint256 _config_maximum_block_drift,
                    uint256 _config_minimum_purchase_dgx_ng, address _config_payment_collector)
  {
    (_user_daily_dgx_limit, _user_total_purchased_today) =
      marketplace_storage().read_user(_user);

    (_user_id_expiration,) = identity_storage().read_user(_user);

    (_config_global_daily_dgx_ng_limit, _config_minimum_purchase_dgx_ng, _config_maximum_block_drift, _config_payment_collector) =
      marketplace_storage().read_config();
  }

  /// @dev get global marketplace configuration
  /// @return {
  ///     &quot;_global_daily_dgx_ng_limit,&quot;: &quot;the default max amount of DGX in nanograms the user can purchase daily&quot;,
  ///     &quot;_minimum_purchase_dgx_ng&quot;: &quot;The minimum DGX nanograms that can be purchased&quot;,
  ///     &quot;_maximum_block_drift&quot;: &quot;The number of blocks a pricefeed is valid for&quot;,
  ///     &quot;_payment_collector&quot;: &quot;The ETH address where the payment should be sent to&quot;
  /// }
  function getConfig()
           public
           constant
           returns (uint256 _global_daily_dgx_ng_limit, uint256 _minimum_purchase_dgx_ng, uint256 _maximum_block_drift, address _payment_collector)
  {
     (_global_daily_dgx_ng_limit, _minimum_purchase_dgx_ng, _maximum_block_drift, _payment_collector) =
       marketplace_storage().read_config();
  }

  /// @dev show the user&#39;s daily limit on DGX purchase
  /// @param _user the user&#39;s ethereum address
  /// @return {
  ///   &quot;_maximum_purchase_amount_ng&quot;: &quot;The amount in DGX nanograms that the user can purchase daily&quot;
  /// }
  function userMaximumPurchaseAmountNg(address _user)
           public
           constant
           returns (uint256 _maximum_purchase_amount_ng)
  {
    _maximum_purchase_amount_ng = marketplace_storage().read_user_daily_limit(_user);
  }

  /// @dev show how many nanograms of DGX is in the Marketplace&#39;s inventory
  /// @return {
  ///   &quot;_available_ng&quot;: &quot;The amount in DGX nanograms in the inventory&quot;
  /// }
  function availableDgxNg()
           public
           constant
           returns (uint256 _available_ng)
  {
    _available_ng = marketplace_storage().read_dgx_inventory_balance_ng();
  }

  /// @dev return the total number of purchases done on marketplace
  /// @return _total_number_of_purchases the total number of purchases on marketplace
  function readTotalNumberOfPurchases()
           public
           constant
           returns (uint256 _total_number_of_purchases)
  {
    _total_number_of_purchases = marketplace_storage().read_total_number_of_purchases();
  }

  /// @dev read the total number of purchases by a user
  /// @param _user Ethereum address of the user
  /// @return _total_number_of_user_purchases the total number of purchases made by the user on marketplace
  function readTotalNumberOfUserPurchases(address _user)
           public
           constant
           returns (uint256 _total_number_of_user_purchases)
  {
    _total_number_of_user_purchases = marketplace_storage().read_total_number_of_user_purchases(_user);
  }

  /// @dev read the purchase details at an index from all purchases
  /// @param _index the index of the purchase in all purchases (index starts from 0)
  /// @return {
  ///   &quot;_recipient&quot;: &quot;DGX was purchases to this Ethereum address&quot;,
  ///   &quot;_timestamp&quot;: &quot;the time at which the purchase was made&quot;,
  ///   &quot;_amount&quot;: &quot;the amount of DGX nanograms purchased in this purchase&quot;,
  ///   &quot;_price&quot;: &quot;the price paid by purchaser in web per dgx milligram&quot;
  /// }
  function readPurchaseAtIndex(uint256 _index)
           public
           constant
           returns (address _recipient, uint256 _timestamp, uint256 _amount, uint256 _price)
  {
    (_recipient, _timestamp, _amount, _price) = marketplace_storage().read_purchase_at_index(_index);
  }

  /// @dev read the purchase details by a user at an index from all the user&#39;s purchases
  /// @param _index the index of the purchase in all purchases by this user (index starts from 0)
  /// @return {
  ///   &quot;_recipient&quot;: &quot;DGX was purchases to this Ethereum address&quot;,
  ///   &quot;_timestamp&quot;: &quot;the time at which the purchase was made&quot;,
  ///   &quot;_amount&quot;: &quot;the amount of DGX nanograms purchased in this purchase&quot;,
  ///   &quot;_price&quot;: &quot;the price paid by purchaser in web per dgx milligram&quot;
  /// }
  function readUserPurchaseAtIndex(address _user, uint256 _index)
           public
           constant
           returns (address _recipient, uint256 _timestamp, uint256 _amount, uint256 _price)
  {
    (_recipient, _timestamp, _amount, _price) = marketplace_storage().read_user_purchase_at_index(_user, _index);
  }

  /// @dev read the total amount of DGX purchased today
  /// @return _total_purchased_today the total amount of DGX purchased today at marketplace
  function readGlobalPurchasedToday()
           public
           constant
           returns (uint256 _total_purchased_today)
  {
    _total_purchased_today = marketplace_storage().read_total_global_purchased_today();
  }

  /// @dev read the amount of DGX purchased today by a user
  /// @param _user Ethereum address of the user
  /// @return _user_total_purchased_today the total amount of DGX purchased today by a user
  function readUserPurchasedToday(address _user)
           public
           constant
           returns (uint256 _user_total_purchased_today)
  {
    _user_total_purchased_today = marketplace_storage().read_total_purchased_today(_user);
  }

  /// @dev read the marketplace configurations
  /// @return {
  ///   &quot;_global_default_user_daily_limit,&quot;: &quot;Default maximum number of DGX nanograms that a user can purchase per day&quot;,
  ///   &quot;_minimum_purchase_dgx_ng&quot;: &quot;minimum number of DGX nanograms that has to be purchased in a single purchase&quot;,
  ///   &quot;_maximum_block_drift&quot;: &quot;the number of ethereum blocks for which the pricefeed is valid for&quot;,
  ///   &quot;_payment_collector&quot;: &quot;the ethereum address that will receive the eth paid for a purchase&quot;,
  ///   &quot;_max_dgx_available_daily&quot;: &quot;maximum number of DGX nanograms that are available for purchase on marketplace in a day&quot;,
  ///   &quot;_price_floor_wei_per_dgx_mg&quot;: &quot;the price floor, minimum price, below which a purchase is invalid&quot;
  function readMarketplaceConfigs()
           public
           constant
           returns (uint256 _global_default_user_daily_limit,
                    uint256 _minimum_purchase_dgx_ng,
                    uint256 _maximum_block_drift,
                    address _payment_collector,
                    uint256 _max_dgx_available_daily,
                    uint256 _price_floor_wei_per_dgx_mg)
  {
    (_global_default_user_daily_limit, _minimum_purchase_dgx_ng, _maximum_block_drift, _payment_collector)
      = marketplace_storage().read_config();
    _max_dgx_available_daily = marketplace_storage().read_max_dgx_available_daily();
    _price_floor_wei_per_dgx_mg = marketplace_storage().read_price_floor();
  }

}