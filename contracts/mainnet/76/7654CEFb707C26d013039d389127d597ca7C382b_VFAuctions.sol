// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

import '../derived/OwnableClone.sol';
import '../sales/ISaleable.sol';

import '../utils/BinaryDecoder.sol';

contract VFAuctions is AccessControl {
  struct Listing {
    uint16    template;
    uint16    consigner;
    uint16    offeringId;
  }

  struct ListingTemplate {
    uint64    openTime;
    uint16    startOffsetMin;
    uint16    endOffsetMin;
    uint16    startPriceTenFinnies;
    uint16    priceReductionTenFinnies;
  }

  address[] internal consigners;
  bytes32[0xFFFF] internal listings;
  bytes32[0xFFFF] internal templates;
  uint256 internal numListings;
  mapping (uint256 => bool) internal listingPurchased;
  address payable public benefactor;

  string public name;

  event ListingPurchased(uint256 indexed listingId, uint16 index, address buyer, uint256 price);

  constructor(string memory _name) {
    name = _name;
    benefactor = payable(msg.sender);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  uint256 constant private TEN_FINNY_TO_WEI = 10000000000000000;

  function calculateCurrentPrice(ListingTemplate memory template) internal view returns (uint256) {
    // solhint-disable-next-line not-rely-on-time
    uint256 currentTime = block.timestamp;
    uint256 delta = uint256(template.priceReductionTenFinnies) * TEN_FINNY_TO_WEI;
    uint256 startPrice = uint256(template.startPriceTenFinnies) * TEN_FINNY_TO_WEI;
    uint64 startTime = template.openTime + (uint64(template.startOffsetMin) * 60);
    uint64 endTime = template.openTime + (uint64(template.endOffsetMin) * 60);

    if (currentTime >= endTime) {
      return startPrice - delta;
    } else if (currentTime <= startTime) {
      return startPrice;
    }


    uint256 reduction =
      SafeMath.div(SafeMath.mul(delta, currentTime - startTime ), endTime - startTime);
    return startPrice - reduction;
  }

  function calculateCurrentPrice(uint256 listingId) public view returns (uint256) {
    require(numListings >= listingId, 'No such listing');
    Listing memory listing = decodeListing(uint16(listingId));
    ListingTemplate memory template = decodeTemplate(listing.template);
    return calculateCurrentPrice(template);
  }

  function bid(
    uint256 listingId
  ) public payable {
    require(listingPurchased[listingId] == false, 'listing sold out');
    require(numListings >= listingId, 'No such listing');
    Listing memory listing = decodeListing(uint16(listingId));
    ListingTemplate memory template = decodeTemplate(listing.template);

    uint256 currentPrice = calculateCurrentPrice(template);
    require(msg.value >= currentPrice, 'Wrong price');
    ISaleable(consigners[listing.consigner]).processSale(listing.offeringId, msg.sender, currentPrice);
    listingPurchased[listingId] = true;

    emit ListingPurchased(listingId, listing.offeringId, msg.sender, currentPrice);

    if (currentPrice < msg.value) {
      Address.sendValue(payable(msg.sender), msg.value - currentPrice);
    }
  }

  function addConsigners( address[] memory newConsigners ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    for (uint idx = 0; idx < newConsigners.length; idx++) {
      consigners.push(newConsigners[idx]);
    }
  }

  function addListings( bytes32[] calldata newListings, uint offset, uint length) public onlyRole(DEFAULT_ADMIN_ROLE) {
    uint idx = 0;
    while(idx < newListings.length) {
      listings[offset + idx] = newListings[idx];
      idx++;
    }
    numListings = length;
  }

  function addListingTemplates( bytes32[] calldata newTemplates, uint offset) public onlyRole(DEFAULT_ADMIN_ROLE) {
    uint idx = 0;
    while(idx < newTemplates.length) {
      templates[offset + idx] = newTemplates[idx];
      idx++;
    }
  }

  struct OutputListing {
    uint16   listingId;
    address  consigner;
    uint16[] soldOfferingIds;
    uint16[] availableOfferingIds;
    uint256  startPrice;
    uint256  endPrice;
    uint64   startTime;
    uint64   endTime;
    uint64   openTime;
  }

  function getListingsLength() public view returns (uint) {
    return numListings;
  }

  function getListings(uint16 start, uint16 length) public view returns (OutputListing[] memory) {
    require(start < numListings, 'out of range');
    uint256 remaining = numListings - start;
    uint256 actualLength = remaining < length ? remaining : length;
    OutputListing[] memory result = new OutputListing[](actualLength);

    for (uint16 idx = 0; idx < actualLength; idx++) {
      uint16 listingId = start + idx;
      Listing memory listing = decodeListing(listingId);
      ListingTemplate memory template = decodeTemplate(listing.template);
      bool isPurchased = listingPurchased[listingId];

      result[idx].listingId   = listingId;
      result[idx].consigner   = consigners[listing.consigner];

      if (isPurchased) {
        result[idx].soldOfferingIds = new uint16[](1);
        result[idx].availableOfferingIds = new uint16[](0);
        result[idx].soldOfferingIds[0] = listing.offeringId;
      } else {
        result[idx].soldOfferingIds = new uint16[](0);
        result[idx].availableOfferingIds = new uint16[](1);
        result[idx].availableOfferingIds[0] = listing.offeringId;
      }

      uint256 reduction = uint256(template.priceReductionTenFinnies) * TEN_FINNY_TO_WEI;
      uint256 startPrice = uint256(template.startPriceTenFinnies)  * TEN_FINNY_TO_WEI;
      uint64 startTime = template.openTime + (uint64(template.startOffsetMin) * 60);
      uint64 endTime = template.openTime + (uint64(template.endOffsetMin) * 60);

      result[idx].startPrice  = startPrice;
      result[idx].endPrice    = startPrice - reduction;
      result[idx].startTime   = startTime;
      result[idx].endTime     = endTime;
      result[idx].openTime   = template.openTime;
    }

    return result;
  }

  function getBufferIndexAndOffset(uint index, uint stride) internal pure returns (uint, uint) {
    uint offset = index * stride;
    return (offset / 32, offset % 32);
  }

  function decodeListing(uint16 idx) internal view returns (Listing memory) {
    (uint bufferIndex, uint offset) = getBufferIndexAndOffset(idx, 6);
    Listing memory result;

    (result.template,bufferIndex,offset) = BinaryDecoder.decodeUint16Aligned(listings, bufferIndex, offset);
    (result.consigner,bufferIndex,offset) = BinaryDecoder.decodeUint16Aligned(listings, bufferIndex, offset);
    (result.offeringId,bufferIndex,offset) = BinaryDecoder.decodeUint16Aligned(listings, bufferIndex, offset);

    return result;
  }

  function decodeTemplate(uint16 idx) internal view returns (ListingTemplate memory) {
    (uint bufferIndex, uint offset) = getBufferIndexAndOffset(idx, 16);
    ListingTemplate memory result;

    (result.openTime,bufferIndex,offset) = BinaryDecoder.decodeUint64Aligned(templates, bufferIndex, offset);
    (result.startOffsetMin,bufferIndex,offset) = BinaryDecoder.decodeUint16Aligned(templates, bufferIndex, offset);
    (result.endOffsetMin,bufferIndex,offset) = BinaryDecoder.decodeUint16Aligned(templates, bufferIndex, offset);
    (result.startPriceTenFinnies,bufferIndex,offset) = BinaryDecoder.decodeUint16Aligned(templates, bufferIndex, offset);
    (result.priceReductionTenFinnies,bufferIndex,offset) = BinaryDecoder.decodeUint16Aligned(templates, bufferIndex, offset);

    return result;
  }

  function withdraw() public {
    require(msg.sender == benefactor || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'not authorized');
    uint amount = address(this).balance;
    require(amount > 0, 'no balance');

    Address.sendValue(benefactor, amount);
  }

  function setBenefactor(address payable newBenefactor, bool sendBalance) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(benefactor != newBenefactor, 'already set');
    uint amount = address(this).balance;
    address payable oldBenefactor = benefactor;
    benefactor = newBenefactor;

    if (sendBalance && amount > 0) {
      Address.sendValue(oldBenefactor, amount);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableClone is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function init(address initialOwner) internal {
    require(_owner == address(0), 'Contract is already initialized');
    _owner = initialOwner;
    emit OwnershipTransferred(address(0), initialOwner);
  }

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    init(msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner() == _msgSender(), 'caller is not the owner');
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'new owner is null address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISaleable {
  function processSale(uint256 offeringId, address buyer, uint256 price) external;

  function getSellersFor(uint256 offeringId) external view returns (address[] memory sellers);

  event SellerAdded(address indexed seller, uint256 indexed offeringId);
  event SellerRemoved(address indexed seller, uint256 indexed offeringId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library BinaryDecoder {
    function increment(uint bufferIdx, uint offset, uint amount) internal pure returns (uint, uint) {
      offset+=amount;
      return (bufferIdx + (offset / 32), offset % 32);
    }

    function decodeUint8(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint8, uint, uint) {
      uint8 result = 0;
      result |= uint8(buffers[bufferIdx][offset]);
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (result, bufferIdx, offset);
    }

    function decodeUint16(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint16, uint, uint) {
      uint result = 0;
      if (offset % 32 < 31) {
        return decodeUint16Aligned(buffers, bufferIdx, offset);
      }

      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (uint16(result), bufferIdx, offset);
    }

    function decodeUint16Aligned(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint16, uint, uint) {
      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      result |= uint(uint8(buffers[bufferIdx][offset + 1]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 2);
      return (uint16(result), bufferIdx, offset);
    }

    function decodeUint32(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint32, uint, uint) {
      if (offset % 32 < 29) {
        return decodeUint32Aligned(buffers, bufferIdx, offset);
      }

      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 24;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 16;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (uint32(result), bufferIdx, offset);
    }

    function decodeUint32Aligned(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint32, uint, uint) {
      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 24;
      result |= uint(uint8(buffers[bufferIdx][offset + 1])) << 16;
      result |= uint(uint8(buffers[bufferIdx][offset + 2])) << 8;
      result |= uint(uint8(buffers[bufferIdx][offset + 3]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 4);
      return (uint32(result), bufferIdx, offset);
    }

    function decodeUint64(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint64, uint, uint) {
      if (offset % 32 < 25) {
        return decodeUint64Aligned(buffers, bufferIdx, offset);
      }

      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 56;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 48;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 40;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 32;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 24;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 16;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (uint64(result), bufferIdx, offset);
    }

    function decodeUint64Aligned(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint64, uint, uint) {
      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 56;
      result |= uint(uint8(buffers[bufferIdx][offset + 1])) << 48;
      result |= uint(uint8(buffers[bufferIdx][offset + 2])) << 40;
      result |= uint(uint8(buffers[bufferIdx][offset + 3])) << 32;
      result |= uint(uint8(buffers[bufferIdx][offset + 4])) << 24;
      result |= uint(uint8(buffers[bufferIdx][offset + 5])) << 16;
      result |= uint(uint8(buffers[bufferIdx][offset + 6])) << 8;
      result |= uint(uint8(buffers[bufferIdx][offset + 7]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 8);
      return (uint64(result), bufferIdx, offset);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}