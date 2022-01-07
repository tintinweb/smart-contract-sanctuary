// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./lib/Initializable.sol";
import "./IJaxAdmin.sol";
import "./JaxOwnable.sol";

interface IJaxPlanet {

  struct Colony {
    uint128 level;
    uint128 transaction_tax;
    bytes32 _policy_hash;
    string _policy_link;
  }

  function ubi_tax_wallet() external view returns (address);
  function ubi_tax() external view returns (uint);
  function jaxcorp_dao_wallet() external view returns (address);
  function getMotherColonyAddress(address) external view returns(address);
  function getColony(address addr) external view returns(Colony memory);
  function getUserColonyAddress(address user) external view returns(address);
}

contract JaxPlanet is Initializable, IJaxPlanet, JaxOwnable{
  
  IJaxAdmin public jaxAdmin;

  address public ubi_tax_wallet;
  address public jaxcorp_dao_wallet;
  
  // ubi tax
  uint public ubi_tax;
  
  uint128 public min_transaction_tax;

  mapping (address => address) private mother_colony_addresses;
  mapping (address => address) private user_colony_addresses;
  mapping (address => Colony) private colonies;


  event Set_Jax_Admin(address old_admin, address new_admin);
  event Set_Ubi_Tax(uint ubi_tax, address ubi_tax_wallet);
  event Register_Colony(address colony_external_key, uint128 tx_tax, string colony_policy_link, bytes32 colony_policy_hash, address mother_colony_external_key);
  event Set_Colony_Address(address addr, address colony);
  event Set_Jax_Corp_Dao(address jax_corp_dao_wallet, uint128 tx_tax, string policy_link, bytes32 policy_hash);
  event Set_Min_Transaction_Tax(uint min_tx_tax);

  modifier onlyAdmin() {
    require(jaxAdmin.userIsAdmin(msg.sender) || msg.sender == owner, "Not_Admin"); //Only Admin can perform this operation.
    _;
  }

  modifier onlyGovernor() {
    require(jaxAdmin.userIsGovernor(msg.sender), "Not_Governor"); //Only Governor can perform this operation.
    _;
  }

  modifier onlyAjaxPrime() {
    require(jaxAdmin.userIsAjaxPrime(msg.sender), "Not_AjaxPrime"); //Only AjaxPrime can perform this operation.
    _;
  }

  modifier isActive() {
      require(jaxAdmin.system_status() == 2, "Swap_Paused"); //Swap has been paused by Admin.
      _;
  }

  function setJaxAdmin(address newJaxAdmin) external onlyAdmin {
    address oldAdmin = address(jaxAdmin);
    jaxAdmin = IJaxAdmin(newJaxAdmin);
    jaxAdmin.system_status();
    emit Set_Jax_Admin(oldAdmin, newJaxAdmin);
  }

  function setUbiTax(uint _ubi_tax, address wallet) external onlyAjaxPrime {
      require(_ubi_tax <= 1e8 * 50 / 100 , "UBI tax can't be more than 50.");
      ubi_tax = _ubi_tax;
      ubi_tax_wallet = wallet;
      emit Set_Ubi_Tax(_ubi_tax, wallet);
  }

  function registerColony(uint128 tx_tax, string memory colony_policy_link, bytes32 colony_policy_hash, address mother_colony_external_key) external {

    require(tx_tax <= (1e8) * 20 / 100, "Tx tax can't be more than 20%");
    require(msg.sender != mother_colony_external_key, "Mother colony can't be set");
    require(user_colony_addresses[msg.sender] == address(0), "User can't be a colony");
    
    if (colonies[mother_colony_external_key].level == 0) {
      mother_colony_addresses[msg.sender] = address(0);
      colonies[msg.sender].level = 2;
    } else {
      if (colonies[mother_colony_external_key].level < colonies[msg.sender].level || colonies[msg.sender].level == 0) {
        mother_colony_addresses[msg.sender] = mother_colony_external_key;
        colonies[msg.sender].level = colonies[mother_colony_external_key].level + 1;
      }
    }
    
    colonies[msg.sender].transaction_tax = tx_tax;
    colonies[msg.sender]._policy_link = colony_policy_link;
    colonies[msg.sender]._policy_hash = colony_policy_hash;
    emit Register_Colony(msg.sender, tx_tax, colony_policy_link, colony_policy_hash, mother_colony_external_key);
  }

  function getColony(address addr) external view returns(Colony memory) {
      Colony memory colony = colonies[addr];
      if(colony.transaction_tax < min_transaction_tax)
        colony.transaction_tax = min_transaction_tax;
      return colony;
  }

  function getUserColonyAddress(address addr) external view returns(address) {
      return user_colony_addresses[addr];
  }

  function getMotherColonyAddress(address account) external view returns(address) {
    return mother_colony_addresses[account];
  }

  function setColonyAddress(address colony) external {
    require(mother_colony_addresses[msg.sender] == address(0), "Colony can't be a user");
    require(msg.sender != colony && colonies[colony].level != 0, "Mother Colony is invalid");
    user_colony_addresses[msg.sender] = colony;
    emit Set_Colony_Address(msg.sender, colony);
  }

  function setJaxCorpDAO(address jaxCorpDao_wallet, uint128 tx_tax, string memory policy_link, bytes32 policy_hash) external onlyAjaxPrime {
      require(tx_tax <= (1e8) * 20 / 100, "Tx tax can't be more than 20%");
      jaxcorp_dao_wallet = jaxCorpDao_wallet;

      colonies[address(0)].transaction_tax = tx_tax;
      colonies[address(0)]._policy_link = policy_link;
      colonies[address(0)]._policy_hash = policy_hash;
      colonies[address(0)].level = 1;

      emit Set_Jax_Corp_Dao(jaxCorpDao_wallet, tx_tax, policy_link, policy_hash);
  }

  function setMinTransactionTax(uint128 min_tx_tax) external onlyAjaxPrime {
    min_transaction_tax = min_tx_tax;
    emit Set_Min_Transaction_Tax(min_tx_tax);
  }

  function initialize(address _jaxAdmin) external initializer {
    jaxAdmin = IJaxAdmin(_jaxAdmin);
    owner = msg.sender;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IJaxAdmin {

  function userIsAdmin (address _user) external view returns (bool);
  function userIsGovernor (address _user) external view returns (bool);
  function userIsAjaxPrime (address _user) external view returns (bool);
  function system_status () external view returns (uint);
  function electGovernor (address _governor) external;  
  function blacklist(address _user) external view returns (bool);
  function fee_blacklist(address _user) external view returns (bool);
  function priceImpactLimit() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract JaxOwnable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner() {
      require(owner == msg.sender, "JaxOwnable: caller is not the owner");
      _;
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "new owner is the zero address");
    _transferOwnership(newOwner);
  }

  function renounceOwnership() external onlyOwner {
    _transferOwnership(address(0));
  }

  /**
  * @dev Transfers ownership of the contract to a new account (`newOwner`).
  * Internal function without access restriction.
  */
  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = owner;
    owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}