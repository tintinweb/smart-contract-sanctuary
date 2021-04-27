/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity ^0.4.24;

// File: node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: node_modules/openzeppelin-solidity/contracts/ownership/rbac/Roles.sol

/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 *      See RBAC.sol for example usage.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

  /**
   * @dev remove an address' access to this role
   */
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

// File: node_modules/openzeppelin-solidity/contracts/ownership/rbac/RBAC.sol

/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * @dev Supports unlimited numbers of roles and addresses.
 * @dev See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 *  for you to write your own implementation of this interface using Enums or similar.
 * It's also recommended that you define constants in the contract, like ROLE_ADMIN below,
 *  to avoid typos.
 */
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

  /**
   * @dev reverts if addr does not have role
   * @param addr address
   * @param roleName the name of the role
   * // reverts
   */
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

  /**
   * @dev determine if addr has role
   * @param addr address
   * @param roleName the name of the role
   * @return bool
   */
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

  /**
   * @dev add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

  /**
   * @dev remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param roleName the name of the role
   * // reverts
   */
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param roleNames the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] roleNames) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < roleNames.length; i++) {
  //         if (hasRole(msg.sender, roleNames[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}

// File: contracts/ERC2980/Issuable.sol

/**
 * @title Issuable
 * @dev The Issuable contract defines the issuer role who can perform certain kind of actions
 * even if he is not the owner.
 * An issuer can transfer his role to a new address.
 */
contract Issuable is Ownable, RBAC {
  string public constant ROLE_ISSUER = "issuer";

  /**
   * @dev Throws if called by any account that's not a issuer.
   */
  modifier onlyIssuer() {
    require(isIssuer(msg.sender), 'Issuable: caller is not the issuer');
    _;
  }

  modifier onlyOwnerOrIssuer() {
    require(msg.sender == owner || isIssuer(msg.sender), 'Issuable: caller is not the issuer or the owner');
    _;
  }

  /**
   * @dev getter to determine if address has issuer role
   */
  function isIssuer(address _addr) public view returns (bool) {
    return hasRole(_addr, ROLE_ISSUER);
  }

  /**
   * @dev add a new issuer address
   * @param _operator address
   * @return true if the address was not an issuer, false if the address was already an issuer
   */
  function addIssuer(address _operator) public onlyOwner {
    addRole(_operator, ROLE_ISSUER);
  }

    /**
   * @dev remove an address from issuers
   * @param _operator address
   * @return true if the address has been removed from issuers,
   * false if the address wasn't in the issuer list in the first place
   */
  function removeIssuer(address _operator) public onlyOwner {
    removeRole(_operator, ROLE_ISSUER);
  }

  /**
   * @dev Allows the current issuer to transfer his role to a newIssuer.
   * @param _newIssuer The address to transfer the issuer role to.
   */
  function transferIssuer(address _newIssuer) public onlyIssuer {
    require(_newIssuer != address(0));
    removeRole(msg.sender, ROLE_ISSUER);
    addRole(_newIssuer, ROLE_ISSUER);
  }

}

// File: contracts/ERC2980/Frozenlist.sol

/**
 * @title Frozenlist
 * @dev The Frozenlist contract has a frozen list of addresses, and provides basic authorization control functions.
 * This simplifies the implementation of "user permissions".
 */
contract Frozenlist is Issuable {

  event FundsFrozen(address target);

  string public constant ROLE_FROZENLIST = "frozenlist";

  /**
   * @dev Throws if operator is frozen.
   * @param _operator address
   */
  modifier onlyIfNotFrozen(address _operator) {
    require(!hasRole(_operator, ROLE_FROZENLIST), "Account frozen");
    _;
  }

  /**
   * @dev add an address to the frozenlist
   * @param _operator address
   * @return true if the address was added to the frozenlist, false if the address was already in the frozenlist
   */
  function addAddressToFrozenlist(address _operator) public onlyIssuer {
    addRole(_operator, ROLE_FROZENLIST);
    emit FundsFrozen(_operator);
  }

  /**
   * @dev getter to determine if address is in frozenlist
   */
  function frozenlist(address _operator) public view returns (bool) {
    return hasRole(_operator, ROLE_FROZENLIST);
  }

  /**
   * @dev add addresses to the frozenlist
   * @param _operators addresses
   * @return true if at least one address was added to the frozenlist,
   * false if all addresses were already in the frozenlist
   */
  function addAddressesToFrozenlist(address[] _operators) public onlyIssuer {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToFrozenlist(_operators[i]);
    }
  }

  /**
   * @dev remove an address from the frozenlist
   * @param _operator address
   * @return true if the address was removed from the frozenlist,
   * false if the address wasn't in the frozenlist in the first place
   */
  function removeAddressFromFrozenlist(address _operator) public onlyIssuer {
    removeRole(_operator, ROLE_FROZENLIST);
  }

  /**
   * @dev remove addresses from the frozenlist
   * @param _operators addresses
   * @return true if at least one address was removed from the frozenlist,
   * false if all addresses weren't in the frozenlist in the first place
   */
  function removeAddressesFromFrozenlist(address[] _operators) public onlyIssuer {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromFrozenlist(_operators[i]);
    }
  }

}

// File: contracts/ERC2980/Whitelist.sol

/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * This simplifies the implementation of "user permissions".
    By default whitelist in not enabled.
 */
contract Whitelist is Issuable {
  string public constant ROLE_WHITELISTED = "whitelist";
  bool public whitelistEnabled;

  constructor(bool enableWhitelist)
    public {
      whitelistEnabled = enableWhitelist;
  }

  /**
   * @dev Throws if operator is not whitelisted and whitelist is enabled.
   * @param _operator address
   */
  modifier onlyIfWhitelisted(address _operator) {
    if(whitelistEnabled) {
      checkRole(_operator, ROLE_WHITELISTED);
    }
    _;
  }

  function enableWhitelist() public onlyOwner {
    whitelistEnabled = true;
  }

  function disableWhitelist() public onlyOwner {
    whitelistEnabled = false;
  }

  /**
   * @dev add an address to the whitelist
   * @param _operator address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToWhitelist(address _operator) public onlyIssuer {
    addRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev getter to determine if address is in whitelist
   */
  function whitelist(address _operator) public view returns (bool) {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev add addresses to the whitelist
   * @param _operators addresses
   * @return true if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToWhitelist(address[] _operators) public onlyIssuer {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param _operator address
   * @return true if the address was removed from the whitelist,
   * false if the address wasn't in the whitelist in the first place
   */
  function removeAddressFromWhitelist(address _operator) public onlyIssuer {
    removeRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev remove addresses from the whitelist
   * @param _operators addresses
   * @return true if at least one address was removed from the whitelist,
   * false if all addresses weren't in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] _operators) public onlyIssuer {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}

// File: contracts/NokuPricingPlan.sol

/**
* @dev The NokuPricingPlan contract defines the responsibilities of a Noku pricing plan.
*/
contract NokuPricingPlan {
    /**
    * @dev Pay the fee for the service identified by the specified name.
    * The fee amount shall already be approved by the client.
    * @param serviceName The name of the target service.
    * @param multiplier The multiplier of the base service fee to apply.
    * @param client The client of the target service.
    * @return true if fee has been paid.
    */
    function payFee(bytes32 serviceName, uint256 multiplier, address client) public returns(bool paid);

    /**
    * @dev Get the usage fee for the service identified by the specified name.
    * The returned fee amount shall be approved before using #payFee method.
    * @param serviceName The name of the target service.
    * @param multiplier The multiplier of the base service fee to apply.
    * @return The amount to approve before really paying such fee.
    */
    function usageFee(bytes32 serviceName, uint256 multiplier) public constant returns(uint fee);
}

// File: contracts/NokuCustomToken.sol

contract NokuCustomToken is Ownable {

    event LogBurnFinished();
    event LogPricingPlanChanged(address indexed caller, address indexed pricingPlan);

    // The pricing plan determining the fee to be paid in NOKU tokens by customers for using Noku services
    NokuPricingPlan public pricingPlan;

    // The entity acting as Custom Token service provider i.e. Noku
    address public serviceProvider;

    // Flag indicating if Custom Token burning has been permanently finished or not.
    bool public burningFinished;

    /**
    * @dev Modifier to make a function callable only by service provider i.e. Noku.
    */
    modifier onlyServiceProvider() {
        require(msg.sender == serviceProvider, "caller is not service provider");
        _;
    }

    modifier canBurn() {
        require(!burningFinished, "burning finished");
        _;
    }

    constructor(address _pricingPlan, address _serviceProvider) internal {
        require(_pricingPlan != 0, "_pricingPlan is zero");
        require(_serviceProvider != 0, "_serviceProvider is zero");

        pricingPlan = NokuPricingPlan(_pricingPlan);
        serviceProvider = _serviceProvider;
    }

    /**
    * @dev Presence of this function indicates the contract is a Custom Token.
    */
    function isCustomToken() public pure returns(bool isCustom) {
        return true;
    }

    /**
    * @dev Stop burning new tokens.
    * @return true if the operation was successful.
    */
    function finishBurning() public onlyOwner canBurn returns(bool finished) {
        burningFinished = true;

        emit LogBurnFinished();

        return true;
    }

    /**
    * @dev Change the pricing plan of service fee to be paid in NOKU tokens.
    * @param _pricingPlan The pricing plan of NOKU token to be paid, zero means flat subscription.
    */
    function setPricingPlan(address _pricingPlan) public onlyServiceProvider {
        require(_pricingPlan != 0, "_pricingPlan is 0");
        require(_pricingPlan != address(pricingPlan), "_pricingPlan == pricingPlan");

        pricingPlan = NokuPricingPlan(_pricingPlan);

        emit LogPricingPlanChanged(msg.sender, _pricingPlan);
    }
}

// File: contracts/openzeppelin-origin/introspection/ERC165.sol

/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface ERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

// File: contracts/openzeppelin-origin/introspection/SupportsInterfaceWithLookup.sol

/**
 * @title SupportsInterfaceWithLookup
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract SupportsInterfaceWithLookup is ERC165 {

  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
  /**
   * 0x01ffc9a7 ===
   *   bytes4(keccak256('supportsInterface(bytes4)'))
   */

  /**
   * @dev a mapping of interface id to whether or not it's supported
   */
  mapping(bytes4 => bool) internal supportedInterfaces;

  /**
   * @dev A contract implementing SupportsInterfaceWithLookup
   * implement ERC165 itself
   */
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

  /**
   * @dev implement supportsInterface(bytes4) using a lookup table
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

  /**
   * @dev private method for registering an interface
   */
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}

// File: contracts/openzeppelin-origin/token/ERC721/ERC721Basic.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic is ERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
  /*
   * 0x80ac58cd ===
   *   bytes4(keccak256('balanceOf(address)')) ^
   *   bytes4(keccak256('ownerOf(uint256)')) ^
   *   bytes4(keccak256('approve(address,uint256)')) ^
   *   bytes4(keccak256('getApproved(uint256)')) ^
   *   bytes4(keccak256('setApprovalForAll(address,bool)')) ^
   *   bytes4(keccak256('isApprovedForAll(address,address)')) ^
   *   bytes4(keccak256('transferFrom(address,address,uint256)')) ^
   *   bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
   *   bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
   */

  bytes4 internal constant InterfaceId_ERC721Exists = 0x4f558e79;
  /*
   * 0x4f558e79 ===
   *   bytes4(keccak256('exists(uint256)'))
   */

  bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
  /**
   * 0x780e9d63 ===
   *   bytes4(keccak256('totalSupply()')) ^
   *   bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
   *   bytes4(keccak256('tokenByIndex(uint256)'))
   */

  bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
  /**
   * 0x5b5e139f ===
   *   bytes4(keccak256('name()')) ^
   *   bytes4(keccak256('symbol()')) ^
   *   bytes4(keccak256('tokenURI(uint256)'))
   */

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

// File: contracts/openzeppelin-origin/token/ERC721/ERC721.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

// File: node_modules/openzeppelin-solidity/contracts/AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

// File: node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/openzeppelin-origin/token/ERC721/ERC721Receiver.sol

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract ERC721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   * after a `safetransfer`. This function MAY throw to revert and reject the
   * transfer. Return of other than the magic value MUST result in the
   * transaction being reverted.
   * Note: the contract address is always the message sender.
   * @param _operator The address which called `safeTransferFrom` function
   * @param _from The address which previously owned the token
   * @param _tokenId The NFT identifier which is being transferred
   * @param _data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}

// File: contracts/openzeppelin-origin/token/ERC721/ERC721BasicToken.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

  using SafeMath for uint256;
  using AddressUtils for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

  // Mapping from token ID to owner
  mapping (uint256 => address) internal tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) internal tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) internal ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  constructor()
    public
  {
    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
  }

  /**
   * @dev Gets the balance of the specified address
   * @param _owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

  /**
   * @dev Gets the owner of the specified token ID
   * @param _tokenId uint256 ID of the token to query the owner of
   * @return owner address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

  /**
   * @dev Returns whether the specified token exists
   * @param _tokenId uint256 ID of the token to query the existence of
   * @return whether the token exists
   */
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param _to address to be approved for the given token ID
   * @param _tokenId uint256 ID of the token to be approved
   */
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    tokenApprovals[_tokenId] = _to;
    emit Approval(owner, _to, _tokenId);
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all tokens of the sender on their behalf
   * @param _to operator address to set the approval
   * @param _approved representing the status of the approval to be set
   */
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner
   * @param _owner owner address which you want to query the approval of
   * @param _operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   *
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    // solium-disable-next-line arg-overflow
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
  {
    transferFrom(_from, _to, _tokenId);
    // solium-disable-next-line arg-overflow
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param _spender address of the spender to query
   * @param _tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token
   */
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
    // Disable solium check because of
    // https://github.com/duaraghav8/Solium/issues/175
    // solium-disable-next-line operator-whitespace
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
   * @param _to The address that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

  /**
   * @dev Internal function to clear current approval of a given token ID
   * Reverts if the given address is not indeed the owner of the token
   * @param _owner owner of the token
   * @param _tokenId uint256 ID of the token to be transferred
   */
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
    }
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

  /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * The call is not executed if the target address is not a contract
   * @param _from address representing the previous owner of the given token ID
   * @param _to target address that will receive the tokens
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

// File: contracts/openzeppelin-origin/token/ERC721/ERC721Token.sol

/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

  // Token name
  string internal name_;

  // Token symbol
  string internal symbol_;

  // Mapping from owner to list of owned token IDs
  mapping(address => uint256[]) internal ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) internal ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] internal allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) internal allTokensIndex;

  // Optional mapping for token URIs
  mapping(uint256 => string) internal tokenURIs;

  /**
   * @dev Constructor function
   */
  constructor(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;

    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

  /**
   * @dev Gets the token name
   * @return string representing the token name
   */
  function name() external view returns (string) {
    return name_;
  }

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() external view returns (string) {
    return symbol_;
  }

  /**
   * @dev Returns an URI for a given token ID
   * Throws if the token ID does not exist. May return an empty string.
   * @param _tokenId uint256 ID of the token to query
   */
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

  /**
   * @dev Gets the token ID at a given index of the tokens list of the requested owner
   * @param _owner address owning the tokens list to be accessed
   * @param _index uint256 representing the index to be accessed of the requested tokens list
   * @return uint256 token ID at the given index of the tokens list owned by the requested address
   */
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256)
  {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

  /**
   * @dev Gets the total amount of tokens stored by the contract
   * @return uint256 representing the total amount of tokens
   */
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

  /**
   * @dev Gets the token ID at a given index of all the tokens in this contract
   * Reverts if the index is greater or equal to the total number of tokens
   * @param _index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

  /**
   * @dev Internal function to set the token URI for a given token
   * Reverts if the token ID does not exist
   * @param _tokenId uint256 ID of the token to set its URI
   * @param _uri string URI to assign
   */
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);

    // To prevent a gap in the array, we store the last token in the index of the token to delete, and
    // then delete the last slot.
    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    // This also deletes the contents at the last position of the array
    ownedTokens[_from].length--;

    // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
    // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
    // the lastToken to the first position, and then dropping the element placed in the last position of the list

    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
   * @param _to address the beneficiary that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param _owner owner of the token to burn
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

    // Clear metadata (if any)
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

    // Reorg all tokens array
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}

// File: contracts/NokuCustomERC721.sol

/**
* @dev The NokuCustomERC721Token contract is a custom ERC721-compliant token available in the Noku Service Platform (NSP).
* The Noku customer is able to choose the token name, symbol, decimals, initial supply and to administer its lifecycle
* by minting or burning tokens in order to increase or decrease the token supply.
*/
contract NokuCustomERC721 is NokuCustomToken, ERC721Token, Issuable, Frozenlist, Whitelist {
    using SafeMath for uint256;
    enum StorageTypes { None, IPFS, NOKU }

    bool public isAdvanced = false;
    bool public mintingFinished = false;

    StorageTypes private storageType;
    string private tokenBaseURIValue = "";
    mapping (uint256 => string) private metadataURIs;

    event LogNokuCustomERC721Created(
        address indexed caller,
        string indexed name,
        string indexed symbol,
        address pricingPlan,
        address serviceProvider,
        string baseURI,
        StorageTypes _storageType
    );

    // event LogInformationChanged(
    //     address indexed caller, 
    //     string name, 
    //     string symbol
    // );

    event MintFinished();

    event FundsReassigned(address _from, address _to, uint256 _tokenId);
    event FundsRevoked(address _from, uint256 _tokenId);

    bytes32 public constant BURN_SERVICE_NAME = "NokuCustomERC721.burn";
    bytes32 public constant MINT_SERVICE_NAME = "NokuCustomERC721.mint";
    bytes32 public constant TRANSFERFROM_SERVICE_NAME = "NokuCustomERC721.transferFrom";

    bytes4 internal constant InterfaceId_ERC721Advanced = 0xdb1e569f;
    /**
    * 0xdb1e569f ===
    *   bytes4(keccak256('isERC721Advanced()'))
    */

    modifier canBurnToken(uint256 _tokenId) {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }

    modifier canMint() {
        require(!mintingFinished, 'Mint finished');
        _;
    }

    modifier isERC721Advanced() {
        require(isAdvanced, 'ERC721 Advanced functions not available');
        _;
    }

    modifier onlyIfNotFrozen(address _operator) {
        if (isAdvanced) {
            require(!hasRole(_operator, ROLE_FROZENLIST), "Account frozen");
        }
        _;
    }
    
    constructor (
        string _name,
        string _symbol,
        string _tokenBaseURI,
        bool _enableWhitelist,
        bool _isAdvanced,
        StorageTypes _storageType,
        address _pricingPlan,
        address _serviceProvider
    )
    NokuCustomToken(_pricingPlan, _serviceProvider)
    ERC721Token(_name, _symbol)
    Whitelist(_enableWhitelist)
    public
    {
        _registerInterface(InterfaceId_ERC721Advanced);
        isAdvanced = _isAdvanced;

        addIssuer(owner);
        if(_enableWhitelist) {
            addAddressToWhitelist(owner);
        }

        require(bytes(_name).length > 0, "_name is empty");
        require(bytes(_symbol).length > 0, "_symbol is empty");

        if(bytes(_tokenBaseURI).length > 0){
            tokenBaseURIValue = _tokenBaseURI;
        }


        storageType = _storageType;

        emit LogNokuCustomERC721Created(
            msg.sender,
            _name,
            _symbol,
            _pricingPlan,
            _serviceProvider,
            _tokenBaseURI,
            _storageType
        );
    }

    // function setInformation(string _name, string _symbol) public onlyOwner returns(bool successful) {
    //     require(bytes(_name).length > 0, "_name is empty");
    //     require(bytes(_symbol).length > 0, "_symbol is empty");

    //     name_ = _name;
    //     symbol_ = _symbol;

        // emit LogInformationChanged(msg.sender, _name, _symbol);

    //     return true;
    // }

    function getStorageType() public view returns(StorageTypes) {
        return storageType;
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(exists(_tokenId), "tokenId does not exist");
        if(getStorageType() == StorageTypes.IPFS) {
            return tokenMetadataURI(_tokenId);
        } else if(getStorageType() == StorageTypes.NOKU) {
            string memory partialPath = string(abi.encodePacked(tokenBaseURIValue, toString(this)));
            return string(abi.encodePacked(string(abi.encodePacked(partialPath, "/")), uint2str(_tokenId)));
        } else {
            return string(abi.encodePacked(tokenBaseURIValue, uint2str(_tokenId)));
        }
    }

    function tokenBaseURI() public view returns (string) {
        return tokenBaseURIValue;
    }

    function updateTokenBaseURI(string memory _newBaseURI) public onlyOwner {
        tokenBaseURIValue = _newBaseURI;
    }

    function updateTokenMetadataURI(uint256 _tokenId, string _tokenMetadataURI) public onlyOwner {
        require(exists(_tokenId), "tokenId does not exist");
        _setTokenMetadataURI(_tokenId, _tokenMetadataURI);
    }

    function tokenMetadataURI(uint256 _tokenId) public view returns (string) {
        return metadataURIs[_tokenId];
    }

    function mint(uint256 _tokenId, address _to) public onlyOwner {
        _mint(_tokenId, _to, "");
    }

    function mint(uint256 _tokenId, address _to, string _tokenMetadataURI) public onlyOwner {
        _mint(_tokenId, _to, _tokenMetadataURI);
    }

    function multipleMint(uint256[] _tokensIds, address _to) public onlyOwner {
        _multipleMint(_tokensIds, _to, "");
    }

    function multipleMint(uint256[] _tokensIds, address _to, string _tokenMetadataURI) public onlyOwner {
        _multipleMint(_tokensIds, _to, _tokenMetadataURI);
    }

    function safeMint(uint256 _tokenId, address _to) public onlyOwner {
        _safeMint(_tokenId, _to, "", "");
    }

    function safeMint(uint256 _tokenId, address _to, bytes memory _data) public onlyOwner {
        _safeMint(_tokenId, _to, "", _data);
    }

    function safeMint(uint256 _tokenId, address _to, string _tokenMetadataURI) public onlyOwner {
        _safeMint(_tokenId, _to, _tokenMetadataURI, "");
    }

    function safeMint(uint256 _tokenId, address _to, string _tokenMetadataURI, bytes memory _data) public onlyOwner {
        _safeMint(_tokenId, _to, _tokenMetadataURI, _data);
    }

    function multipleSafeMint(uint256[] _tokensIds, address _to) public onlyOwner {
        _multipleSafeMint(_tokensIds, _to, "", "");
    }

    function multipleSafeMint(uint256[] _tokensIds, address _to, bytes memory _data) public onlyOwner {
        _multipleSafeMint(_tokensIds, _to, "", _data);
    }

    function multipleSafeMint(uint256[] _tokensIds, address _to, string _tokenMetadataURI) public onlyOwner {
        _multipleSafeMint(_tokensIds, _to, _tokenMetadataURI, "");
    }

    function multipleSafeMint(uint256[] _tokensIds, address _to, string _tokenMetadataURI, bytes memory _data) public onlyOwner {
        _multipleSafeMint(_tokensIds, _to, _tokenMetadataURI, _data);
    }

    function burn(uint256 _tokenId) public canBurn canBurnToken(_tokenId) onlyIfNotFrozen(msg.sender) {
        if (bytes(metadataURIs[_tokenId]).length != 0) {
            delete metadataURIs[_tokenId];
        }
        super._burn(ownerOf(_tokenId), _tokenId);
        require(pricingPlan.payFee(BURN_SERVICE_NAME, 1 * 10**18, msg.sender), "burn fee payment failed");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public onlyIfNotFrozen(_from) onlyIfNotFrozen(_to) onlyIfWhitelisted(_to) canTransfer(_tokenId) {
        super.transferFrom(_from, _to, _tokenId);
        require(pricingPlan.payFee(TRANSFERFROM_SERVICE_NAME, 1 * 10**18, msg.sender), "transferFrom fee payment failed");
    }

    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    function reassign(address _from, address _to, uint256 _tokenId) public onlyIssuer isERC721Advanced {
        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
        emit FundsReassigned(_from, _to, _tokenId);
    }

    function revoke(address _from, uint256 _tokenId) public onlyIssuer isERC721Advanced {
        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(msg.sender, _tokenId);

        emit Transfer(_from, msg.sender, _tokenId);
        emit FundsRevoked(_from, _tokenId);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        if(isIssuer(owner)) {
            if(whitelistEnabled) {
                removeAddressFromWhitelist(owner);
                addAddressToWhitelist(_newOwner);
            }
            transferIssuer(_newOwner);
        }
        super.transferOwnership(_newOwner);
    }

    function renounceOwnership() public onlyOwner {
        if(whitelistEnabled) {
            removeAddressFromWhitelist(owner);
        }
        removeIssuer(owner);
        super.renounceOwnership();
    }

    function addAddressToFrozenlist(address _operator) public isERC721Advanced {
        super.addAddressToFrozenlist(_operator);
    }

    function removeAddressFromFrozenlist(address _operator) public isERC721Advanced {
        super.removeAddressFromFrozenlist(_operator);
    }

    //Internal functions

    function _mint(uint256 _tokenId, address _to, string _tokenMetadataURI) canMint onlyIfNotFrozen(_to) onlyIfWhitelisted(_to) internal returns (uint256) {
        require(!exists(_tokenId), 'tokenId already exists');

        if (storageType == StorageTypes.IPFS) {
            require(bytes(_tokenMetadataURI).length > 0, "missing IPFS uri");
        } else if (storageType == StorageTypes.NOKU) {
            require(bytes(_tokenMetadataURI).length > 0, "missing Noku uri");
        }

        super._mint(_to, _tokenId);
        _setTokenMetadataURI(_tokenId, _tokenMetadataURI);

        require(pricingPlan.payFee(MINT_SERVICE_NAME, 1 * 10**18, msg.sender), "mint fee payment failed");

        return _tokenId;
    }

    function _multipleMint(uint256[] _tokensIds, address _to, string _tokenMetadataURI) internal {
        for(uint256 i = 0; i < _tokensIds.length; i++) {
            _mint(_tokensIds[i], _to, _tokenMetadataURI);
        }
    }

    function _safeMint(uint256 _tokenId, address _to, string _tokenMetadataURI, bytes memory _data) internal returns (uint256) {
        _mint(_tokenId, _to, _tokenMetadataURI);
        require(checkAndCallSafeTransfer(address(0), _to, _tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
        return _tokenId;
    }

    function _multipleSafeMint(uint256[] _tokensIds, address _to, string _tokenMetadataURI, bytes memory _data) internal {
        for(uint256 i = 0; i < _tokensIds.length; i++) {
            _safeMint(_tokensIds[i], _to, _tokenMetadataURI, _data);
        }
    }

    function _setTokenMetadataURI(uint256 _tokenId, string _tokenMetadataURI) internal {
        if (storageType != StorageTypes.None) {
            metadataURIs[_tokenId] = _tokenMetadataURI;
        }
    }

    function uint2str(uint i) internal pure returns (string) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

    function toString(address _addr) internal pure returns (string) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }

    //Private functions

}

// File: node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: contracts/NokuCustomService.sol

contract NokuCustomService is Pausable {
    using AddressUtils for address;

    event LogPricingPlanChanged(address indexed caller, address indexed pricingPlan);

    // The pricing plan determining the fee to be paid in NOKU tokens by customers
    NokuPricingPlan public pricingPlan;

    constructor(address _pricingPlan) internal {
        require(_pricingPlan.isContract(), "_pricingPlan is not contract");

        pricingPlan = NokuPricingPlan(_pricingPlan);
    }

    function setPricingPlan(address _pricingPlan) public onlyOwner {
        require(_pricingPlan.isContract(), "_pricingPlan is not contract");
        require(NokuPricingPlan(_pricingPlan) != pricingPlan, "_pricingPlan equal to current");
        
        pricingPlan = NokuPricingPlan(_pricingPlan);

        emit LogPricingPlanChanged(msg.sender, _pricingPlan);
    }
}

// File: contracts/NokuCustomERC721Service.sol

/**
* @dev The NokuCustomERC721Service contract .
*/
contract NokuCustomERC721Service is NokuCustomService {
    event LogNokuCustomERC721ServiceCreated(address caller, address indexed _pricingPlan);

    uint256 public constant CREATE_AMOUNT = 1 * 10**18;

    bytes32 public constant CREATE_SERVICE_NAME = "NokuCustomERC721.create";

    constructor(address _pricingPlan) NokuCustomService(_pricingPlan) public {
        emit LogNokuCustomERC721ServiceCreated(msg.sender, _pricingPlan);
    }

    function createCustomToken(string _name, string _symbol, string _tokenBaseURI, bool _enableWhitelist, bool _isAdvanced, NokuCustomERC721.StorageTypes _storageType, NokuPricingPlan _pricingPlan) public returns(NokuCustomERC721 customToken) {
        customToken = new NokuCustomERC721(
            _name,
            _symbol,
            _tokenBaseURI,
            _enableWhitelist,
            _isAdvanced,
            _storageType,
            _pricingPlan,
            owner
        );

        // Transfer NokuCustomERC721 ownership to the client
        customToken.transferOwnership(msg.sender);

        require(_pricingPlan.payFee(CREATE_SERVICE_NAME, CREATE_AMOUNT, msg.sender), "fee payment failed");
    }

}