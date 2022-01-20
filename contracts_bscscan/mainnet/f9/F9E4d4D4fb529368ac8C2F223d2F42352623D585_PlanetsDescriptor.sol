// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./utils/SVGUtils.sol";
import "./interface/IPlanetsDescriptor.sol";
import "./interface/IPlanetsName.sol";
import "./interface/ISVGDescriptor.sol";
import "./interface/IPlanetsManager.sol";
import "./utils/PlanetRandom.sol";

contract PlanetsDescriptor is AccessControl, IPlanetsDescriptor {
  bytes32 public constant PLANETS_MANAGER_ROLE = keccak256("PLANETS_MANAGER_ROLE");

  struct PlanetPosition {
    int256 x;
    int256 y;
  }

  struct PlanetMetadata {
    string name;
    uint256 habitability;
    uint256 temperature;
    uint256 size;
    uint256 nSatellite;
    PlanetPosition position;
  }

  mapping (uint => PlanetPosition) public planetCoordinates;

  IPlanetsManager public planetsManager;

  bool canChangePlanetsName = true;
  IPlanetsName public planetsName;

  bool canChangeSvgDescriptor = true;
  ISVGDescriptor public svgDescriptor;

  mapping (uint256 => bytes32) public _tokenIdToBlockhash;

  uint public planetsMintedBeforeUnveil;

  constructor (address _planetsManager) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    planetsManager = IPlanetsManager(_planetsManager);
    planetsMintedBeforeUnveil = IPlanetsManager(_planetsManager).totalSupply();
  }

  function getPlanetsMintedBeforeUnveil() external override view returns(uint) {
    return planetsMintedBeforeUnveil;
  }

  function initPlanet(uint256 tokenId_) external virtual override onlyRole(PLANETS_MANAGER_ROLE) {
    if (planetsManager.unveilBlockHash() == bytes32(0)) {
      planetsMintedBeforeUnveil += 1;
    } else {
      _tokenIdToBlockhash[tokenId_] = blockhash(block.number - 1);
    }
  }

  function computeMysteryHash(uint _tokenId) public view returns (bytes32) {

    bytes32 unveilBlockHash = planetsManager.unveilBlockHash();
    bytes32 mysteryHash;
    if (_tokenId <= planetsMintedBeforeUnveil) {
      mysteryHash = keccak256(abi.encodePacked(unveilBlockHash, SVGUtils.uint2str(_tokenId, 0)));
    } else {
      mysteryHash = keccak256(abi.encodePacked(unveilBlockHash, _tokenIdToBlockhash[_tokenId]));
    }

    return mysteryHash;
  }

  /**
  * @notice Constructs the token uri of the specified token
  * @param _tokenId The token id.
  * @dev For other details see {IPlanetDescriptor-tokenURI}. Note that this function
          is supposed to be called only by the PlanetsManager
  */
  function tokenURI(uint _tokenId) external view virtual override onlyRole(PLANETS_MANAGER_ROLE) returns (string memory)  {
    // getMetadata
    PlanetMetadata memory planetMetadata = getMetadata(_tokenId);

    bytes32 mysteryHash = this.computeMysteryHash(_tokenId);
    return svgDescriptor.constructTokenURI(_tokenId, mysteryHash, planetMetadata);
  }

  /**
  * @notice Constructs the token uri of the specified token without the card
  * @param _tokenId The token id.
  * @dev For other details see {IPlanetDescriptor-tokenURI}. Note that this fucntion
          is supposed to be called only by the PlanetsManager
  */
  function tokenURIWithoutCard(uint _tokenId) external view virtual override onlyRole(PLANETS_MANAGER_ROLE) returns (string memory)  {
    // getMetadata
    PlanetMetadata memory planetMetadata = getMetadata(_tokenId);

    bytes32 mysteryHash = this.computeMysteryHash(_tokenId);
    return svgDescriptor.constructTokenURIWithoutCard(_tokenId, mysteryHash, planetMetadata);
  }

  /**
   * @notice return metadata by planetId
   * @param _tokenId Tokens id we want get metadata
   */
  function getMetadata(uint256 _tokenId) public view returns(PlanetMetadata memory) {
    require(_tokenId > 0 && _tokenId <= planetsManager.totalSupply(), "PlanetsDescriptor: tokenId not exist");

    bytes32 mysteryHash = this.computeMysteryHash(_tokenId);

    PlanetMetadata memory planetMetadata;
    planetMetadata.habitability = PlanetRandom.calcRandom(1,101, mysteryHash, _tokenId);

    planetMetadata.temperature = PlanetRandom.calcRandom(173, 373, mysteryHash, _tokenId); // ° kelvin

    planetMetadata.size = PlanetRandom.calcRandom(1000,3001, mysteryHash, _tokenId);

    planetMetadata.nSatellite = PlanetRandom.calcRandom(1,21, mysteryHash, _tokenId);

    uint shiftedId = computeShiftedId(_tokenId, mysteryHash);
    planetMetadata.position = planetCoordinates[shiftedId];

    planetMetadata.name = address(planetsName) == address(0) ?
    string(abi.encodePacked("Planet ",SVGUtils.uint2str(_tokenId, 0)))
    :
    planetsName.getPlanetNameById(_tokenId);


    return planetMetadata;
  }

  /**
   * @notice Batch add planet coordinates
   * @param _tokenIds Tokens ids relative to the position at the same index
   * @param _xCoord X coordinates
   * @param _yCoord Y coordinates
   */
  function insertPlanetCoordinates(uint[] memory _tokenIds, int[] memory _xCoord, int[] memory _yCoord) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_tokenIds.length == _xCoord.length, "PlanetsDescriptor: invalid array");
    require(_xCoord.length == _yCoord.length, "PlanetsDescriptor: invalid array");

    for (uint i = 0; i < _tokenIds.length; i++) {
      PlanetPosition memory position = PlanetPosition({
        x: _xCoord[i],
        y: _yCoord[i]
      });

      planetCoordinates[_tokenIds[i]] = position;
    }
  }

  /**
   * @notice Compute the shifted token id based on the mysteryHash
   * @param _tokenId Original token id
   * @return shiftedId uint Shifted token id
   */
  function computeShiftedId(uint _tokenId, bytes32 _mysteryHash) private view returns (uint) {
    uint unveilIndex = uint(_mysteryHash) % 1123;

    return ((_tokenId + unveilIndex) % 1123) + 1;
  }

  /**
   * @notice Change SVG Descriptor contract address
   * @param _descriptor The address of the new SVG Descriptor
   */
  function addSVGDescriptor(address _descriptor) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(canChangeSvgDescriptor, "PlanetsDescriptor: can't change SVG descriptor");
    require(_descriptor != address(svgDescriptor), "PlanetsDescriptor: same SVG descriptor address");

    svgDescriptor = ISVGDescriptor(_descriptor);
  }

  /**
   * @notice Disable the opportunity to change the address of the SVG descriptor
   */
  function disableSVGDescriptorUpgradability() external onlyRole(DEFAULT_ADMIN_ROLE) {
    canChangeSvgDescriptor = false;
  }

  /**
   * @notice Change planets name contract address
   * @param _planetsName The address of the new planets name
   */
  function addPlanetsName(address _planetsName) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(canChangePlanetsName, "PlanetsDescriptor: can't change planets name");
    require(_planetsName != address(planetsName), "PlanetsDescriptor: same planets name address");

    planetsName = IPlanetsName(_planetsName);
  }

  /**
   * @notice Disable the opportunity to change the address of the planets name
   */
  function disablePlanetsNameUpgradability() external onlyRole(DEFAULT_ADMIN_ROLE) {
    canChangePlanetsName = false;
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library SVGUtils {

  function checkCoordinates(uint xPoint, uint yPoint) public pure returns (bool) {
    if ((xPoint > 170 && xPoint < 394) && ( yPoint > 170 && yPoint < 394)) {
      return false;
    }
    return true;
  }

  function uint2str(uint i_, uint decimals_) public pure returns (string memory _uintAsString) { // only 1 decimal
    if (i_ == 0) {
      return "0";
    }
    uint j = i_;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    if (len != 1 && decimals_ > 0) {
      len ++;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    uint index = 0;
    if(len == 1 && decimals_ > 0) {
      bstr = new bytes(3);
      bstr[0] = bytes1(uint8(48));
      bstr[1] = bytes1(uint8(46));
      bstr[2] = bytes1((48 + uint8(i_ - i_ / 10 * 10)));
    } else {
      while (i_ != 0) {
        k = k-1;
        if (index == decimals_ && index != 0) {
          bstr[k] = bytes1(uint8(46));
          k = k-1;
        }
        uint8 temp = (48 + uint8(i_ - i_ / 10 * 10));
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        i_ /= 10;
        index ++;
      }
    }
    return string(bstr);
  }

  function abs(int x) public pure returns (int) {
    return x >= 0 ? x : -x;
  }

}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;

interface IPlanetsDescriptor{
  /**
  * @dev return SVG code
  */
  function tokenURI(uint256 tokenId_) external view returns  (string memory);
  function tokenURIWithoutCard(uint256 tokenId_) external view returns  (string memory);
  function initPlanet(uint256 tokenId_) external;
  function getPlanetsMintedBeforeUnveil() external view returns(uint);
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;

interface IPlanetsName{

  /**
  * @dev return planet name by tokenId_
  */
  function getPlanetNameById(uint256 tokenId_) external view returns  (string memory);

  function setPlanetName(uint tokenId_, string memory newName_) external returns(bool);

}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;

import "./../PlanetsDescriptor.sol";

interface ISVGDescriptor {
    function constructTokenURI(uint256 tokenId_, bytes32 blockhashInit_, PlanetsDescriptor.PlanetMetadata memory planetMetadata_) external view returns (string memory);
    function constructTokenURIWithoutCard(uint256 tokenId_, bytes32 blockhashInit_, PlanetsDescriptor.PlanetMetadata memory planetMetadata_) external view returns (string memory);
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

interface IPlanetsManager is IERC721Upgradeable, IAccessControlUpgradeable{
  function unveilBlockHash() external view returns (bytes32);
  function unveilIndex() external view returns (uint);

  function totalSupply() external view returns(uint);

  function MAX_PLANET_SUPPLY() external view returns (uint);

  function computeShiftedId(uint _tokenId) external view returns (uint);
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import 'base64-sol/base64.sol';


library PlanetRandom {

  /**
   * @notice Return random number from blockhash
   * @dev min include, max exclude
   */
  function calcRandom(uint256 min_, uint256 max_, bytes32 blockhash_, uint256 payload_) public pure returns (uint256) {
    uint256 randomHash = uint(keccak256(abi.encodePacked(blockhash_, payload_)));
    return (randomHash % (max_ - min_)) + min_;
  }

  function getRandomHash(bytes32 blockhash_, uint256 payload_) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(blockhash_, payload_));
  }

  function calcRandomBytes1(uint256 min_, uint256 max_, bytes32 randomHash_, uint index_) public pure returns (uint) {
    uint randomHashIndex;
    if ( index_ == 31 ) {
      randomHashIndex = uint(uint8(randomHash_[index_])) * (uint8(randomHash_[0]));
    } else {
      randomHashIndex = uint(uint8(randomHash_[index_])) * (uint8(randomHash_[index_ + 1]));
    }
    return ((randomHashIndex ) % (max_ - min_)) + min_;
  }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
     * bearer except when using {AccessControl-_setupRole}.
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
     * bearer except when using {AccessControl-_setupRole}.
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
interface IERC165Upgradeable {
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

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}