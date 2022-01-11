// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

import "./utils/ENSInterfaces.sol";
import "./PermissionManagement.sol";

contract MonumentENSResolver is IENSResolver {
    PermissionManagement internal permissionManagement;

    /**
     * @notice Constructor that sets the PermissionManagement contract
     * @param _permissionManagementContractAddress The address of the Permission Management Contract
     */
    constructor (
        address _permissionManagementContractAddress
    ) {
        permissionManagement = PermissionManagement(_permissionManagementContractAddress);
    }


    // ============ Constants ============

    bytes4 constant SUPPORT_INTERFACE_ID = 0x01ffc9a7;
    bytes4 constant ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant NAME_INTERFACE_ID = 0x691f3431;


    // ============ Structs ============

    struct Record {
        address addr;
        string name;
    }


    // ============ Mappings ============

    // mapping between namehash and resolved records
    mapping(bytes32 => Record) records;


    // ============ Public Functions ============

    /**
     * @notice Lets the manager set the address associated with an ENS node.
     * @param _node The node to update.
     * @param _addr The address to set.
     */
    function setAddr(bytes32 _node, address _addr) public override {
        permissionManagement.adminOnlyMethod(msg.sender);

        records[_node].addr = _addr;
        emit AddrChanged(_node, _addr);
    }

    /**
     * @notice Lets the manager set the name associated with an ENS node.
     * @param _node The node to update.
     * @param _name The name to set.
     */
    function setName(bytes32 _node, string memory _name)
        public
        override
    {
        permissionManagement.adminOnlyMethod(msg.sender);

        records[_node].name = _name;
        emit NameChanged(_node, _name);
    }

    /**
     * @notice Gets the address associated to an ENS node.
     * @param _node The target node.
     * @return the address of the target node.
     */
    function addr(bytes32 _node) public view override returns (address) {
        return records[_node].addr;
    }

    /**
     * @notice Gets the name associated to an ENS node.
     * @param _node The target ENS node.
     * @return the name of the target ENS node.
     */
    function name(bytes32 _node) public view override returns (string memory) {
        return records[_node].name;
    }

    /**
     * @notice Returns true if the resolver implements the interface specified by the provided hash.
     * @param _interfaceID The ID of the interface to check for.
     * @return True if the contract implements the requested interface.
     */
    function supportsInterface(bytes4 _interfaceID) public pure returns (bool) {
        return
            _interfaceID == SUPPORT_INTERFACE_ID ||
            _interfaceID == ADDR_INTERFACE_ID ||
            _interfaceID == NAME_INTERFACE_ID;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

interface IENS {
    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function setApprovalForAll(address operator, bool approved) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
    function recordExists(bytes32 node) external view returns (bool);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IENSResolver {
    event AddrChanged(bytes32 indexed _node, address _addr);
    event NameChanged(bytes32 indexed _node, string _name);

    function addr(bytes32 _node) external view returns (address);
    function setAddr(bytes32 _node, address _addr) external;
    function name(bytes32 _node) external view returns (string memory);
    function setName(bytes32 _node, string calldata _name) external;
}

interface IMonumentENSRegistrar {
    function changeRootNodeOwner(address newOwner_) external;
    function register(string calldata label_, address owner_) external;
    function labelOwner(string calldata label) external view returns (address);
    function changeLabelOwner(string calldata label_, address newOwner_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/**
 * Author: Kumar Abhirup (kumareth)
 * Version: 1.0.1
 * Compiles best with: 0.7.6

 * Many contracts have ownerOnly functions, 
 * but I believe it's safer to have multiple owner addresses
 * to fallback to, in case you lose one.

 * You can inherit this PermissionManagement contract
 * to let multiple people do admin operations on your contract effectively.

 * You can add & remove admins and moderators.
 * You can transfer ownership (basically you can change the founder).
 * You can change the beneficiary (the prime payable wallet) as well.

 * You can also ban & unban addresses,
 * to restrict certain features on your contract for certain addresses.

 * Use modifiers like "founderOnly", "adminOnly", "moderatorOnly" & "adhereToBan"
 * in your contract to put the permissions to use.

 * Code: https://ipfs.io/ipfs/QmbVZevdhRwXfoeVti9GLo7tESUrSg7b2psHxugz9Dx1cg
 * IPFS Metadata: https://ipfs.io/ipfs/Qmdh8DC3FHxCPEVEvhXzZWMHZ8y3Dbavzvtib7s7rEBmcs

 * Access the Contract on the Ethereum Ropsten Testnet Network
 * https://ropsten.etherscan.io/address/0xceaef9490f7516914c056bc5902633e76790a999
 */

/// @title PermissionManagement Contract
/// @author [email protected]
/// @notice Like Openzepplin Ownable, but with many Admins and Moderators.
/// @dev Like Openzepplin Ownable, but with many Admins and Moderators.
/// In Monument.app context, It's recommended that all the admins except the Market Contract give up their admin perms later down the road, or maybe delegate those powers to another transparent contract to ensure trust.
contract PermissionManagement {
  address public founder = msg.sender;
  address payable public beneficiary = payable(msg.sender);

  mapping(address => bool) public admins;
  mapping(address => bool) public moderators;
  mapping(address => bool) public bannedAddresses;

  enum RoleChange { 
    MADE_FOUNDER, 
    MADE_BENEFICIARY, 
    PROMOTED_TO_ADMIN, 
    PROMOTED_TO_MODERATOR, 
    DEMOTED_TO_MODERATOR, 
    KICKED_FROM_TEAM, 
    BANNED, 
    UNBANNED 
  }

  event PermissionsModified(address _address, RoleChange _roleChange);

  constructor (
    address[] memory _admins, 
    address[] memory _moderators
  ) {
    // require more admins for safety and backup
    require(_admins.length > 0, "Admin addresses not provided");

    // make founder the admin and moderator
    admins[founder] = true;
    moderators[founder] = true;
    emit PermissionsModified(founder, RoleChange.MADE_FOUNDER);

    // give admin privileges, and also make admins moderators.
    for (uint256 i = 0; i < _admins.length; i++) {
      admins[_admins[i]] = true;
      moderators[_admins[i]] = true;
      emit PermissionsModified(_admins[i], RoleChange.PROMOTED_TO_ADMIN);
    }

    // give moderator privileges
    for (uint256 i = 0; i < _moderators.length; i++) {
      moderators[_moderators[i]] = true;
      emit PermissionsModified(_moderators[i], RoleChange.PROMOTED_TO_MODERATOR);
    }
  }

  modifier founderOnly() {
    require(
      msg.sender == founder,
      "This function is restricted to the contract's founder."
    );
    _;
  }

  modifier adminOnly() {
    require(
      admins[msg.sender] == true,
      "This function is restricted to the contract's admins."
    );
    _;
  }

  modifier moderatorOnly() {
    require(
      moderators[msg.sender] == true,
      "This function is restricted to the contract's moderators."
    );
    _;
  }

  modifier adhereToBan() {
    require(
      bannedAddresses[msg.sender] != true,
      "You are banned from accessing this function in the contract."
    );
    _;
  }

  modifier addressMustNotBeFounder(address _address) {
    require(
      _address != founder,
      "Address must not be the Founder's address."
    );
    _;
  }

  modifier addressMustNotBeAdmin(address _address) {
    require(
      admins[_address] != true,
      "Address must not be an Admin's address."
    );
    _;
  }

  modifier addressMustNotBeModerator(address _address) {
    require(
      moderators[_address] != true,
      "Address must not be a Moderator's address."
    );
    _;
  }

  modifier addressMustNotBeBeneficiary(address _address) {
    require(
      _address != beneficiary,
      "Address must not be a Beneficiary's address."
    );
    _;
  }

  function founderOnlyMethod(address _address) public view {
    require(
      _address == founder,
      "This function is restricted to the contract's founder."
    );
  }

  function adminOnlyMethod(address _address) public view {
    require(
      admins[_address] == true,
      "This function is restricted to the contract's admins."
    );
  }

  function moderatorOnlyMethod(address _address) public view {
    require(
      moderators[_address] == true,
      "This function is restricted to the contract's moderators."
    );
  }

  function adhereToBanMethod(address _address) public view {
    require(
      bannedAddresses[_address] != true,
      "You are banned from accessing this function in the contract."
    );
  }

  function addressMustNotBeFounderMethod(address _address) public view {
    require(
      _address != founder,
      "Address must not be the Founder's address."
    );
  }

  function addressMustNotBeAdminMethod(address _address) public view {
    require(
      admins[_address] != true,
      "Address must not be an Admin's address."
    );
  }

  function addressMustNotBeModeratorMethod(address _address) public view {
    require(
      moderators[_address] != true,
      "Address must not be a Moderator's address."
    );
  }

  function addressMustNotBeBeneficiaryMethod(address _address) public view {
    require(
      _address != beneficiary,
      "Address must not be a Beneficiary's address."
    );
  }

  function transferFoundership(address payable _founder) 
    public 
    founderOnly
    addressMustNotBeFounder(_founder)
    returns(address)
  {
    require(_founder != msg.sender, "You cant make yourself the founder.");
    
    founder = _founder;
    admins[_founder] = true;
    moderators[_founder] = true;

    emit PermissionsModified(_founder, RoleChange.MADE_FOUNDER);

    return founder;
  }

  function changeBeneficiary(address payable _beneficiary) 
    public
    adminOnly
    returns(address)
  {
    require(_beneficiary != msg.sender, "You cant make yourself the beneficiary.");
    
    beneficiary = _beneficiary;
    emit PermissionsModified(_beneficiary, RoleChange.MADE_BENEFICIARY);

    return beneficiary;
  }

  function addAdmin(address _admin) 
    public 
    adminOnly
    returns(address) 
  {
    admins[_admin] = true;
    moderators[_admin] = true;
    emit PermissionsModified(_admin, RoleChange.PROMOTED_TO_ADMIN);
    return _admin;
  }

  function removeAdmin(address _admin) 
    public 
    adminOnly
    addressMustNotBeFounder(_admin)
    returns(address) 
  {
    require(_admin != msg.sender, "You cant remove yourself from the admin role.");
    delete admins[_admin];
    emit PermissionsModified(_admin, RoleChange.DEMOTED_TO_MODERATOR);
    return _admin;
  }

  function addModerator(address _moderator) 
    public 
    adminOnly
    returns(address) 
  {
    moderators[_moderator] = true;
    emit PermissionsModified(_moderator, RoleChange.PROMOTED_TO_MODERATOR);
    return _moderator;
  }

  function removeModerator(address _moderator) 
    public 
    adminOnly
    addressMustNotBeFounder(_moderator)
    addressMustNotBeAdmin(_moderator)
    returns(address) 
  {
    require(_moderator != msg.sender, "You cant remove yourself from the moderator role.");
    delete moderators[_moderator];
    emit PermissionsModified(_moderator, RoleChange.KICKED_FROM_TEAM);
    return _moderator;
  }

  function ban(address _ban) 
    public 
    moderatorOnly
    addressMustNotBeFounder(_ban)
    addressMustNotBeAdmin(_ban)
    addressMustNotBeModerator(_ban)
    addressMustNotBeBeneficiary(_ban)
    returns(address) 
  {
    bannedAddresses[_ban] = true;
    emit PermissionsModified(_ban, RoleChange.BANNED);
    return _ban;
  }

  function unban(address _ban) 
    public 
    moderatorOnly
    returns(address) 
  {
    bannedAddresses[_ban] = false;
    emit PermissionsModified(_ban, RoleChange.UNBANNED);
    return _ban;
  }
}