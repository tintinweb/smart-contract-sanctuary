// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

import "./utils/ENSInterfaces.sol";
import "./utils/Payable.sol";
import "./PermissionManagement.sol";

contract MonumentENSRegistrar is IMonumentENSRegistrar, Payable {
    PermissionManagement internal permissionManagement;

    // ============ Immutable Storage ============

    /**
     * The name of the ENS root, e.g. "monument.app".
     * @dev dependency injectable for testnet.
     */
    string public rootName;

    /**
     * The node of the root name (e.g. namehash(monument.app))
     */
    bytes32 public immutable rootNode;

    /**
     * The address of the public ENS registry.
     * @dev Dependency-injectable for testing purposes, but otherwise this is the
     * canonical ENS registry at 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e.
     */
    IENS public immutable ensRegistry;

    /**
     * The address of the MonumentENSResolver.
     */
    IENSResolver public immutable ensResolver;


    // ============ Events ============

    event RootNodeOwnerChange(bytes32 indexed node, address indexed owner);
    event RegisteredENS(address indexed _owner, string _ens);
    event UpdatedENS(address indexed _owner, string _ens);


    // ============ Constructor ============

    /**
     * @notice Constructor that sets the ENS root name and root node to manage.
     * @param rootName_ The root name (e.g. monument.app).
     * @param rootNode_ The node of the root name (e.g. namehash(monument.app)).
     * @param ensRegistry_ The address of the ENS registry
     * @param ensResolver_ The address of the ENS resolver
     * @param _permissionManagementContractAddress The address of the Permission Management Contract
     */
    constructor (
        string memory rootName_,
        bytes32 rootNode_,
        address ensRegistry_,
        address ensResolver_,
        address _permissionManagementContractAddress
    )
    Payable(_permissionManagementContractAddress)
    payable {
        permissionManagement = PermissionManagement(_permissionManagementContractAddress);

        rootName = rootName_;
        rootNode = rootNode_;

        // Registrations are cheaper if these are instantiated.
        ensRegistry = IENS(ensRegistry_);
        ensResolver = IENSResolver(ensResolver_);
    }


    // ============ Registration ============

    /**
     * @notice Assigns an ENS subdomain of the root node to a target address.
     * Registers both the forward. Can only be called by writeToken.
     * @param label_ The subdomain label.
     * @param owner_ The owner of the subdomain.
     */
    function register(string calldata label_, address owner_)
        external
        override
    {
        permissionManagement.moderatorOnlyMethod(msg.sender);

        bytes32 labelNode = keccak256(abi.encodePacked(label_));
        bytes32 node = keccak256(abi.encodePacked(rootNode, labelNode));

        require(
            ensRegistry.owner(node) == address(0),
            "MonumentENSManager: label is already owned"
        );

        // Forward ENS
        ensRegistry.setSubnodeRecord(
            rootNode,
            labelNode,
            owner_,
            address(ensResolver),
            0
        );
        ensResolver.setAddr(node, owner_);

        emit RegisteredENS(owner_, label_);
    }


    // ============ ENS Management ============

    /**
     * @notice This function must be called when the ENSRegistrar contract is replaced
     * and the address of the new ENSRegistrar should be provided.
     * @param _newOwner The address of the new ENS Registrar that will manage the root node.
     */
    function changeRootNodeOwner(address _newOwner)
        external
        override
    {
        permissionManagement.adminOnlyMethod(msg.sender);

        ensRegistry.setOwner(rootNode, _newOwner);
        emit RootNodeOwnerChange(rootNode, _newOwner);
    }


    // ============ ENS Subnode Management ============

    function labelOwner(string calldata label)
        external
        view
        override
        returns (address)
    {
        bytes32 labelNode = keccak256(abi.encodePacked(label));
        bytes32 node = keccak256(abi.encodePacked(rootNode, labelNode));

        return ensRegistry.owner(node);
    }

    function changeLabelOwner(string calldata label_, address newOwner_)
        external
        override
    {
        bytes32 labelNode = keccak256(abi.encodePacked(label_));
        bytes32 node = keccak256(abi.encodePacked(rootNode, labelNode));

        require(
            ensRegistry.owner(node) == msg.sender ||
            permissionManagement.moderators(msg.sender) == true,
            "MonumentENSManager: sender does not own label"
        );

        // Forward ENS
        ensRegistry.setSubnodeRecord(
            rootNode,
            labelNode,
            newOwner_,
            address(ensResolver),
            0
        );
        ensResolver.setAddr(node, newOwner_);

        emit UpdatedENS(
            newOwner_,
            string(abi.encodePacked(label_, ".", rootName))
        );
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

// SPDX-License-Identifier: ISC
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ERC721/IERC721.sol";
import "../PermissionManagement.sol";

/// @title Payable Contract
/// @author [email protected]
/// @notice If this abstract contract is inherited, the Contract becomes payable, it also allows Admins to manage Assets owned by the Contract.
abstract contract Payable {
  PermissionManagement private permissionManagement;

  constructor (
    address _permissionManagementContractAddress
  ) {
    permissionManagement = PermissionManagement(_permissionManagementContractAddress);
  }

  event ReceivedFunds(
    address indexed by,
    uint256 fundsInwei,
    uint256 timestamp
  );

  event SentToBeneficiary(
    address indexed actionCalledBy,
    address indexed beneficiary,
    uint256 fundsInwei,
    uint256 timestamp
  );

  event ERC20SentToBeneficiary(
    address indexed actionCalledBy,
    address indexed beneficiary,
    address indexed erc20Token,
    uint256 tokenAmount,
    uint256 timestamp
  );

  event ERC721SentToBeneficiary(
    address indexed actionCalledBy,
    address indexed beneficiary,
    address indexed erc721ContractAddress,
    uint256 tokenId,
    uint256 timestamp
  );

  function getBalance() public view returns(uint256) {
    return address(this).balance;
  }

  /// @notice To pay the contract
  function fund() external payable {
    emit ReceivedFunds(msg.sender, msg.value, block.timestamp);
  }

  fallback() external virtual payable {
    emit ReceivedFunds(msg.sender, msg.value, block.timestamp);
  }

  receive() external virtual payable {
    emit ReceivedFunds(msg.sender, msg.value, block.timestamp);
  }

  /// So the Admins can maintain control over all the Funds the Contract might own in future
  /// @notice Sends Wei the Contract might own, to the Beneficiary
  /// @param _amountInWei Amount in Wei you think the Contract has, that you want to send to the Beneficiary
  function sendToBeneficiary(uint256 _amountInWei) external returns(uint256) {
    permissionManagement.adminOnlyMethod(msg.sender);

    payable(permissionManagement.beneficiary()).transfer(_amountInWei);
    emit SentToBeneficiary(msg.sender, permissionManagement.beneficiary(), _amountInWei, block.timestamp);
    return _amountInWei;
  }

  /// So the Admins can maintain control over all the ERC20 Tokens the Contract might own in future
  /// @notice Sends ERC20 tokens the Contract might own, to the Beneficiary
  /// @param _erc20address Address of the ERC20 Contract
  /// @param _tokenAmount Amount of Tokens you wish to send to the Beneficiary.
  function sendERC20ToBeneficiary(address _erc20address, uint256 _tokenAmount) external returns(address, uint256) {
    permissionManagement.adminOnlyMethod(msg.sender);

    IERC20 erc20Token;
    erc20Token = IERC20(_erc20address);

    erc20Token.transferFrom(address(this), permissionManagement.beneficiary(), _tokenAmount);

    emit ERC20SentToBeneficiary(msg.sender, permissionManagement.beneficiary(), _erc20address, _tokenAmount, block.timestamp);

    return (_erc20address, _tokenAmount);
  }

  /// So the Admins can maintain control over all the ERC721 Tokens the Contract might own in future.
  /// @notice Sends ERC721 tokens the Contract might own, to the Beneficiary
  /// @param _erc721address Address of the ERC721 Contract
  /// @param _tokenId ID of the Token you wish to send to the Beneficiary.
  function sendERC721ToBeneficiary(address _erc721address, uint256 _tokenId) external returns(address, uint256) {
    permissionManagement.adminOnlyMethod(msg.sender);

    IERC721 erc721Token;
    erc721Token = IERC721(_erc721address);

    erc721Token.safeTransferFrom(address(this), permissionManagement.beneficiary(), _tokenId);

    emit ERC721SentToBeneficiary(msg.sender, permissionManagement.beneficiary(), _erc721address, _tokenId, block.timestamp);

    return (_erc721address, _tokenId);
  }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}