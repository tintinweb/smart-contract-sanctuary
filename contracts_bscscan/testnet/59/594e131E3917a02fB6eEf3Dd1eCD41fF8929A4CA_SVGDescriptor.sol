// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import 'base64-sol/base64.sol';
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./PlanetsDescriptor.sol";
import "./utils/SVGUtils.sol";
import "./interface/ISVGDescriptor.sol";
import "./layersSVG/PictureFrame/PictureFrameDescriptor.sol";
import "./layersSVG/Data/DataDescriptor.sol";
import "./layersSVG/Sky/SkyDescriptor.sol";
import "./layersSVG/PlanetBase/PlanetBaseDescriptor.sol";
import "./layersSVG/PlanetSurface/PlanetSurfaceDescriptor.sol";
import "./layersSVG/PlanetRing/PlanetRingDescriptor.sol";
import "./layersSVG/PlanetColor.sol";

contract SVGDescriptor is AccessControl, ISVGDescriptor {
    bytes32 public constant PLANETS_DESCRIPTOR_ROLE = keccak256("PLANETS_DESCRIPTOR_ROLE");

    struct SVGDescriptionParams {
        uint256 revealBlock;
    }

  /**
  * @dev See {IERC721Metadata-tokenURI}.
  string(
      abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(
          bytes(
            abi.encodePacked(
              '{"name":"',
              name,
              '", "description":"',
              descriptionPartOne,
              descriptionPartTwo,
              '", "image": "',
              'data:image/svg+xml;base64,',
              image,
              '"}'
            )
          )
        )
      )
    );
  */

    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function constructTokenURI(uint256 tokenId_, bytes32 blockhashInit_, PlanetsDescriptor.PlanetMetadata memory planetMetadata_) public view override onlyRole(PLANETS_DESCRIPTOR_ROLE) returns (string memory) {

    string memory habitability = string(
      abi.encodePacked(
        '{"trait_type":"Habitability","value":', 
        SVGUtils.uint2str(planetMetadata_.habitability, 0),
        '}'
        )
      );
    
    string memory temperature = string(
      abi.encodePacked(
        '{"trait_type":"Temperature","value":', 
        SVGUtils.uint2str(planetMetadata_.temperature, 0),
        '}'
        )
      );

    string memory size = string(
      abi.encodePacked(
        '{"trait_type":"Size","value":', 
        SVGUtils.uint2str(planetMetadata_.size, 0),
        '}'
        )
      );

    string memory satellites = string(
      abi.encodePacked(
        '{"trait_type":"Satellites","value":', 
        SVGUtils.uint2str(planetMetadata_.nSatellite, 0),
        '}'
        )
      );

        (string memory image1, uint offsetRandom, PlanetColor.PlanetColorPalette memory planetColorPalette) = generateSVGImage1(tokenId_, blockhashInit_, planetMetadata_);

        string memory image2 = generateSVGImage2(tokenId_, blockhashInit_, planetMetadata_, offsetRandom, planetColorPalette);

    return string(abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name":"', planetMetadata_.name,
                '", "description":"',
                'Planet Wars is a Play-to-earn space-warfare game based on Binance Smart Chain that includes NFT, DeFi and gamification concepts.',
                '", "attributes":[',
                habitability,
                ',',
                temperature,
                ',',
                size,
                ',',
                satellites,
                '], "image":"',
                'data:image/svg+xml;base64,',
                Base64.encode(bytes(abi.encodePacked(image1, image2))),
                '"}'
              )
            )
          )
      ));
  }

    function constructTokenURIWithoutCard(uint256 tokenId_, bytes32 blockhashInit_, PlanetsDescriptor.PlanetMetadata memory planetMetadata_) public view override onlyRole(PLANETS_DESCRIPTOR_ROLE) returns (string memory) {

    string memory habitability = string(
      abi.encodePacked(
        '{"trait_type":"Habitability","value":',
        SVGUtils.uint2str(planetMetadata_.habitability, 0),
        '}'
        )
      );

    string memory temperature = string(
      abi.encodePacked(
        '{"trait_type":"Temperature","value":',
        SVGUtils.uint2str(planetMetadata_.temperature, 0),
        '}'
        )
      );

    string memory size = string(
      abi.encodePacked(
        '{"trait_type":"Size","value":',
        SVGUtils.uint2str(planetMetadata_.size, 0),
        '}'
        )
      );

    string memory satellites = string(
      abi.encodePacked(
        '{"trait_type":"Satellites","value":',
        SVGUtils.uint2str(planetMetadata_.nSatellite, 0),
        '}'
        )
      );

        (string memory image1, uint offsetRandom, PlanetColor.PlanetColorPalette memory planetColorPalette) = generateSVGWithoutCardImage1(tokenId_, blockhashInit_, planetMetadata_);

        string memory image2 = generateSVGWithoutCardImage2(tokenId_, blockhashInit_, planetMetadata_, offsetRandom, planetColorPalette);

    return string(abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name":"', planetMetadata_.name,
                '", "description":"',
                'Planet Wars is a Play-to-earn space-warfare game based on Binance Smart Chain that includes NFT, DeFi and gamification concepts.',
                '", "attributes":[',
                habitability,
                ',',
                temperature,
                ',',
                size,
                ',',
                satellites,
                '], "image":"',
                'data:image/svg+xml;base64,',
                Base64.encode(bytes(abi.encodePacked(image1, image2))),
                '"}'
              )
            )
          )
      ));
  }

    function generateSVGImage1(uint256 tokenId_, bytes32 blockhashInit_, PlanetsDescriptor.PlanetMetadata memory planetMetadata_) private view returns (string memory svg, uint offsetRandom, PlanetColor.PlanetColorPalette memory planetColorPalette) {
        uint offsetRandomInit = 1124;

        (string memory svgSky, uint newOffsetRandom) = SkyDescriptor.getSVG(tokenId_, blockhashInit_, offsetRandomInit);
        (PlanetColor.PlanetColorPalette memory planetColorPalette_1, uint newOffsetRandom2) = PlanetColor.getPlanetColor(planetMetadata_.temperature, blockhashInit_, newOffsetRandom);

        svg = string(abi.encodePacked(
            '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" ',
            'y="0px" viewBox="0 0 566.93 935.43" xml:space="preserve"> ',
            '<style type="text/css"> ',
            '.fill_base{fill:#',planetColorPalette_1.colorBase,';} ',
            '.fill_surface{fill:#',planetColorPalette_1.colorSurface,';} ',
            '.fill_ring{fill:#',planetColorPalette_1.colorRing,';} ',
            '.fill_white{fill:#FFFFFF;} ',
            '.fill_field{fill:#00FFFF;} ',
            '.fill_white_star{fill:#FFFFFF;} ',
            '.fill_red_star{fill:#E0B1B1;} ',
            '.fill_blue_star{fill:#BFDCF4;} ',
            '.fill_purple_star{fill:#8E97CC;} ',
            '.text_name{fill:#FFFFFF; font-size:45.7187px;} ',
            '.text_metadata{fill:#FFFFFF; font-size:25.8782px;} ',
            '.circle_logo{fill:none;stroke:#00FFFF;stroke-miterlimit:10;} ',
            '.style_pic_frame{fill:none;stroke:#FFFFFF;stroke-width:0.5;stroke-miterlimit:10;} ',
            '.clip_path{clip-path:url(#clipPath_animation_planet);} ',
            '</style> ',
            svgSky,
            PlanetBaseDescriptor.getSVG(planetColorPalette_1.colorBase),
            PictureFrameDescriptor.getSVG()
              )
            );

            offsetRandom = newOffsetRandom2;
            planetColorPalette = planetColorPalette_1;
    }

    function generateSVGImage2(uint256 tokenId_, bytes32 blockhashInit_, PlanetsDescriptor.PlanetMetadata memory planetMetadata_, uint offsetRandom_, PlanetColor.PlanetColorPalette memory planetColorPalette_) private view returns (string memory svg) {
        (string memory svgSurface, uint newOffsetRandom) = PlanetSurfaceDescriptor.getSVG(tokenId_, blockhashInit_, planetMetadata_.habitability, offsetRandom_);

        svg = string(abi.encodePacked(
            DataDescriptor.getSVG(tokenId_, planetMetadata_),
            svgSurface,
            PlanetRingDescriptor.getSVG(planetMetadata_.nSatellite, planetColorPalette_),
            '</svg> '
          )
        );
    }

    function generateSVGWithoutCardImage1(uint256 tokenId_, bytes32 blockhashInit_, PlanetsDescriptor.PlanetMetadata memory planetMetadata_) private view returns (string memory svg, uint offsetRandom, PlanetColor.PlanetColorPalette memory planetColorPalette) {
        uint offsetRandomInit = 1124;

        (string memory svgSky, uint newOffsetRandom) = SkyDescriptor.getSVG(tokenId_, blockhashInit_, offsetRandomInit);
        (PlanetColor.PlanetColorPalette memory planetColorPalette_1, uint newOffsetRandom2) = PlanetColor.getPlanetColor(planetMetadata_.temperature, blockhashInit_, newOffsetRandom);

        svg = string(abi.encodePacked(
                '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" ',
                'y="0px" viewBox="0 0 566.93 935.43" xml:space="preserve"> ',
                '<style type="text/css"> ',
                '.fill_base{fill:#',planetColorPalette_1.colorBase,';} ',
                '.fill_surface{fill:#',planetColorPalette_1.colorSurface,';} ',
                '.fill_ring{fill:#',planetColorPalette_1.colorRing,';} ',
                '.fill_white{fill:#FFFFFF;} ',
                '.fill_field{fill:#00FFFF;} ',
                '.fill_white_star{fill:#FFFFFF;} ',
                '.fill_red_star{fill:#E0B1B1;} ',
                '.fill_blue_star{fill:#BFDCF4;} ',
                '.fill_purple_star{fill:#8E97CC;} ',
                '.text_name{fill:#FFFFFF; font-size:45.7187px;} ',
                '.text_metadata{fill:#FFFFFF; font-size:25.8782px;} ',
                '.circle_logo{fill:none;stroke:#00FFFF;stroke-miterlimit:10;} ',
                '.style_pic_frame{fill:none;stroke:#FFFFFF;stroke-width:0.5;stroke-miterlimit:10;} ',
                '.clip_path{clip-path:url(#clipPath_animation_planet);} ',
                '</style> ',
                svgSky,
                PlanetBaseDescriptor.getSVG(planetColorPalette_1.colorBase)
            )
        );

        offsetRandom = newOffsetRandom2;
        planetColorPalette = planetColorPalette_1;
    }

    function generateSVGWithoutCardImage2(uint256 tokenId_, bytes32 blockhashInit_, PlanetsDescriptor.PlanetMetadata memory planetMetadata_, uint offsetRandom_, PlanetColor.PlanetColorPalette memory planetColorPalette_) private view returns (string memory svg) {
        (string memory svgSurface, uint newOffsetRandom) = PlanetSurfaceDescriptor.getSVG(tokenId_, blockhashInit_, planetMetadata_.habitability, offsetRandom_);

        svg = string(abi.encodePacked(
                svgSurface,
                PlanetRingDescriptor.getSVG(planetMetadata_.nSatellite, planetColorPalette_),
                '</svg> '
            )
        );
    }

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

  IPlanetsManager private planetsManager;

  bool canChangePlanetsName = true;
  IPlanetsName private planetsName;

  bool canChangeSvgDescriptor = true;
  ISVGDescriptor public svgDescriptor;

  mapping (uint256 => bytes32) _tokenIdToBlockhash;

  constructor (address _planetsManager) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    planetsManager = IPlanetsManager(_planetsManager);
  }

  function initPlanet(uint256 tokenId_) external virtual override onlyRole(PLANETS_MANAGER_ROLE) {
    _tokenIdToBlockhash[tokenId_] = blockhash(block.number - 1);
  }

  function computeMysteryHash(uint _tokenId) external view returns (bytes32) {

    bytes32 unveilBlockHash = planetsManager.unveilBlockHash();
    bytes32 mysteryHash = keccak256(abi.encodePacked(unveilBlockHash, _tokenIdToBlockhash[_tokenId]));

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

import "./../PlanetsDescriptor.sol";

interface ISVGDescriptor {
    function constructTokenURI(uint256 tokenId_, bytes32 blockhashInit_, PlanetsDescriptor.PlanetMetadata memory planetMetadata_) external view returns (string memory);
    function constructTokenURIWithoutCard(uint256 tokenId_, bytes32 blockhashInit_, PlanetsDescriptor.PlanetMetadata memory planetMetadata_) external view returns (string memory);
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library PictureFrameDescriptor {

  function getSVG() public pure returns (string memory svg) {

    svg = string(
      abi.encodePacked(
        '<linearGradient id="LG_PF_1" gradientUnits="userSpaceOnUse" x1="297.0556" y1="547.687" x2="279.3617" y2="238.0428"> ',
        '<stop offset="0" style="stop-color:#FCFCFC;stop-opacity:0.9865"/> ',
        '<stop offset="0" style="stop-color:#FFFFFF"/> ',
        '<stop offset="1" style="stop-color:#FFFFFF;stop-opacity:0"/> ',
        '</linearGradient> ',
        '<path style="opacity:0.15;fill:url(#LG_PF_1);" d="M0,619.68l53.7-54.2h459.24',
        'l53.99-54.2V308.09l0-308.09C389.23,0,412.18,0,0,0L0,619.68z"/> ',
        '<linearGradient id="LG_PF_2" gradientUnits="userSpaceOnUse" ',
        'x1="283.4646" y1="935.433" x2="283.4646" y2="4.277267e-05"> ',
        '<stop offset="0.1902" style="stop-color:#000000"/> ',
        '<stop offset="0.3813" style="stop-color:#000000;stop-opacity:0"/> ',
        '</linearGradient> ',
        '<path style="fill:url(#LG_PF_2); opacity:0.5;" d="M525.58,0H41.35C18.51,0,0,18.51,0,41.35',
        'v852.74c0,22.83,18.51,41.35,41.35,41.35h484.24c22.83,0,41.35-18.51,41.35-41.35V596.75v-80.71V41.35',
        'C566.93,18.51,548.42,0,525.58,0z"/> ',
        '<linearGradient id="LG_PF_3" gradientUnits="userSpaceOnUse" ',
        'x1="283.4646" y1="935.433" x2="283.4646" y2="4.277267e-05"> ',
        '<stop offset="0.1902" style="stop-color:#000000"/> ',
        '<stop offset="1" style="stop-color:#000000;stop-opacity:0"/> ',
        '</linearGradient> ',
        '<path style="fill:url(#LG_PF_3); opacity:0.5;" d="M525.58,0H41.35C18.51,0,0,18.51,0,41.35',
        'v852.74c0,22.83,18.51,41.35,41.35,41.35h484.24c22.83,0,41.35-18.51,41.35-41.35V596.75v-80.71V41.35',
        'C566.93,18.51,548.42,0,525.58,0z M546.78,531.49l-34.26,33.93H54.26L20,599.68V54.56C20,35.47,35.47,20,54.56,20h115.64',
        'l27.88,18.25h171.68L397.64,20h112.68c9.75,0,19.07,3.99,25.79,11.05v0c6.3,6.61,9.82,15.39,9.84,24.52L546.78,531.49z"/> ',
        '<path style="fill:none;stroke:#FFFFFF;stroke-width:0.5;stroke-miterlimit:10;" d="M13.11,54.36v835.56',
        'c0,18.25,14.79,33.04,33.04,33.04h474.64c18.25,0,33.04-17.11,33.04-35.36V54.36',
        'c0-24.05-19.5-43.55-43.55-43.55H56.66C32.61,10.81,13.11,30.3,13.11,54.36z"/> ',
        '<polygon style="fill:#1D1D1B;stroke:#FFFFFF;stroke-width:0.5;stroke-miterlimit:10;" ',
        'points="227.76,10.41 227.76,0 340.86,0 340.86,10.41 326.65,19.45 241.58,19.45"/> ',
        '<linearGradient id="LG_PF_2" gradientUnits="userSpaceOnUse" x1="297.0556" y1="547.687" x2="279.3617" y2="238.0428"> ',
        '<stop  offset="0" style="stop-color:#FCFCFC;stop-opacity:0.9865"/> ',
        '<stop  offset="0" style="stop-color:#FFFFFF"/> ',
        '<stop  offset="1" style="stop-color:#FFFFFF;stop-opacity:0"/> ',
        '</linearGradient> ',
        '<path style="opacity:0.8;fill:url(#LG_PF_2);" d="M0,619.68l53.7-54.2h459.24',
        'l53.99-54.2V308.09l0-308.09C389.23,0,412.18,0,0,0L0,619.68z"/>'
    )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import "./DataDescriptor_1.sol";
import "./DataDescriptor_2.sol";
import "../../PlanetsDescriptor.sol";


library DataDescriptor {

  function getSVG(uint tokenId_, PlanetsDescriptor.PlanetMetadata memory planetMetadata_) public pure returns (string memory svg) {

    svg = string(
      abi.encodePacked(
        DataDescriptor_1.getSVG(tokenId_, planetMetadata_),
        DataDescriptor_2.getSVG(planetMetadata_)
    )
    );
  }

}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import "./SkyBaseDescriptor.sol";
import "./SkyCircleDescriptor.sol";
import "./SkyRhombusDescriptor.sol";


library SkyDescriptor {

  function getSVG(uint256 tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public view returns (string memory svg, uint offsetRandom) {

    (string memory svgBase, uint newOffsetRandom) = SkyBaseDescriptor.getSVG(tokenId_, blockhashInit_, offsetRandom_);
    (string memory svgRhombus, uint newOffsetRandom2) = SkyRhombusDescriptor.getSVG(tokenId_, blockhashInit_, newOffsetRandom);
    (string memory svgCircle, uint newOffsetRandom3) = SkyCircleDescriptor.getSVG(tokenId_, blockhashInit_, newOffsetRandom);

    offsetRandom = newOffsetRandom;
    svg = string(
      abi.encodePacked(
        svgBase,
        svgCircle,
        svgRhombus
      )
    );

  }

}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library PlanetBaseDescriptor {

    function getSVG(string memory colorGlow_) public pure returns (string memory svg) {

        svg = string(
            abi.encodePacked(
                '<circle class="fill_base" cx="282.51" cy="282.52" r="106.3"/> ',
                '<g id="glow"> ',
                '<radialGradient id="LG_GLOW" cx="550.4155" cy="390.2722" r="112.2293" ',
                'gradientTransform="matrix(0.2335 1.0265 -1.0346 0.2353 557.7655 -374.3157)" gradientUnits="userSpaceOnUse"> ',
                '<stop  offset="0.6916" style="stop-color:#',colorGlow_,'"/> ',
                '<stop  offset="1" style="stop-color:#',colorGlow_,';stop-opacity:0"/> ',
                '</radialGradient> ',
                '<path style="opacity:0.8;fill:url(#LG_GLOW);" d="M308.71,397.72',
                'c-64.12,14.58-127.84-25.17-142.31-88.8c-14.47-63.63,25.77-127.03,89.9-141.61c64.13-14.59,127.84,25.17,142.32,88.8',
                'C413.08,319.74,372.84,383.14,308.71,397.72z"/> ',
                '</g> ',
                '<g id="light"> ',
                '<radialGradient id="RD_LIGHT" cx="527.4973" cy="615.1716" r="138.7598" ',
                'gradientTransform="matrix(0.5786 -0.811 0.8107 0.5788 -587.1754 332.4611)" gradientUnits="userSpaceOnUse"> ',
                '<stop  offset="0" style="stop-color:#F4F4F4"/> ',
                '<stop  offset="0.1357" style="stop-color:#EEEEEE"/> ',
                '<stop  offset="0.1591" style="stop-color:#EBEBEB;stop-opacity:0.9802"/> ',
                '<stop  offset="0.2536" style="stop-color:#E9E9E9;stop-opacity:0.9"/> ',
                '<stop  offset="0.2757" style="stop-color:#E7E7E7;stop-opacity:0.8812"/> ',
                '<stop  offset="0.3712" style="stop-color:#E4E4E4;stop-opacity:0.8"/> ',
                '<stop  offset="0.5802" style="stop-color:#C4C4C4;stop-opacity:0.5"/> ',
                '<stop  offset="0.6792" style="stop-color:#B7B7B6;stop-opacity:0.3536"/> ',
                '<stop  offset="0.783" style="stop-color:#AEAEAD;stop-opacity:0.2"/> ',
                '<stop  offset="0.8566" style="stop-color:#838382;stop-opacity:0.1321"/> ',
                '<stop  offset="0.9527" style="stop-color:#50504F;stop-opacity:0.0436"/> ',
                '<stop  offset="1" style="stop-color:#3C3C3B;stop-opacity:0"/> ',
                '</radialGradient> ',
                '<path id="light-path" style="opacity:0.6;fill:url(#RD_LIGHT);" d="',
                'M251.1,180.98c-22.4,6.93-41.43,20.68-55.04,39.75c-19.44,27.26-24.92,61.22-15.03,93.18c8.38,27.12,26.83,49.34,51.93,62.59',
                'c25.1,13.25,53.85,15.91,80.96,7.52c22.4-6.93,41.43-20.68,55.04-39.76c19.44-27.25,24.92-61.21,15.03-93.17',
                'C366.68,195.1,307.07,163.66,251.1,180.98z"/> ',
                '</g> '

        )
        );
    }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import '../../utils/PlanetRandom.sol';
import '../../utils/SVGUtils.sol';
import './PlanetSurface1/PlanetSurface1Descriptor.sol';
import './PlanetSurface2/PlanetSurface2Descriptor.sol';
import './PlanetSurface3/PlanetSurface3Descriptor.sol';
import './PlanetSurface4/PlanetSurface4Descriptor.sol';

library PlanetSurfaceDescriptor {

  function getSVG(uint256 tokenId_, bytes32 blockhashInit_, uint256 habitability, uint offsetRandom_) public pure returns (string memory svg, uint offsetRandom) {

    string memory speedPlanet = SVGUtils.uint2str(PlanetRandom.calcRandom(25,50, blockhashInit_, tokenId_), 0);
    offsetRandom = offsetRandom_;
    svg = string(
      abi.encodePacked(
        '<g class="fill_surface"> ',
        '<defs> <ellipse id="overflow_planet" cx="282.51" cy="282.52" rx="106.3" ry="106.3"/> </defs> ',
        '<clipPath id="clipPath_animation_planet"> <use xlink:href="#overflow_planet" style="overflow:visible;" /> ',
        '<animateTransform attributeName="transform" type="translate" ',
        'from="0 0" to="390.6 0" begin="earth_1.begin" dur="',speedPlanet,'" /> </clipPath> '
      ));

    if (habitability <= 25 ) {
      svg = string(
        abi.encodePacked(
          svg,
            PlanetSurface1Descriptor.getSVG()
        )
      );
    }
    if (habitability > 25 && habitability <= 50) {
      svg = string(
        abi.encodePacked(
          svg,
            PlanetSurface2Descriptor.getSVG()
        )
      );
    }

    if (habitability > 50 && habitability <= 75) {
      svg = string(
        abi.encodePacked(
          svg,
            PlanetSurface3Descriptor.getSVG()
        )
      );
    }

    if (habitability > 75 && habitability <= 100) {
      svg = string(
        abi.encodePacked(
          svg,
            PlanetSurface4Descriptor.getSVG()
        )
      );
    }

    svg = string(
      abi.encodePacked(
        svg,
        '<animateTransform id="earth_1" attributeName="transform" type="translate" ',
        'from="0 0" to="-390.6 0" begin="0s;earth_1.end" dur="',speedPlanet,'" /> </path> ',
        '</g> '
      )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import "./PlanetRing1Descriptor.sol";
import "./PlanetRing2Descriptor.sol";
import "./PlanetRing3Descriptor.sol";
import "../PlanetColor.sol";

library PlanetRingDescriptor {

  function getSVG(uint256 nSatellite_, PlanetColor.PlanetColorPalette memory planetColorPalette_) public pure returns (string memory svg) {

    svg = string(abi.encodePacked('<g class="ring"> '));
    if (nSatellite_ > 5 && nSatellite_ <= 10) {
      svg = string(
        abi.encodePacked(
          svg,
          PlanetRing1Descriptor.getSVG(planetColorPalette_)
        )
      );
    }

    if (nSatellite_ > 10 && nSatellite_ <= 15) {
      svg = string(
        abi.encodePacked(
          svg,
          PlanetRing2Descriptor.getSVG()
        )
      );
    }

    if (nSatellite_ > 15 && nSatellite_ <= 20) {
      svg = string(
        abi.encodePacked(
          svg,
          PlanetRing3Descriptor.getSVG()
        )
      );
    }

    svg = string(
      abi.encodePacked(
        svg,
        '</g> '
      )
    );

  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
import "../utils/PlanetRandom.sol";

library PlanetColor {

  struct PlanetColorPalette {
    string colorSurface;
    string colorBase;
    string colorRing;
  }

  function getPlanetColor(uint temperature_, bytes32 blockhashInit_,  uint offsetRandom_) public pure returns (PlanetColorPalette memory planetColorPalette, uint offsetRandom) {

    uint newOffsetRandom;

    // select random sky layer
    uint randomColorSurface = PlanetRandom.calcRandom(0,3, blockhashInit_, offsetRandom_);
    newOffsetRandom = offsetRandom_ + 1124;
    uint randomColorBase = PlanetRandom.calcRandom(0,3, blockhashInit_, newOffsetRandom);
    newOffsetRandom = newOffsetRandom + 1124;
    uint randomColorRing = PlanetRandom.calcRandom(0,3, blockhashInit_, newOffsetRandom);
    newOffsetRandom = newOffsetRandom + 1124;

    string[3] memory planetColorSurfaceList;
    string[3] memory planetColorBaseList;
    string[3] memory planetColorRingList;
    PlanetColorPalette memory planetColorPaletteTemp;

    if (temperature_ < 193) {
      planetColorSurfaceList = ["F5FAF6","90CA9C","787A78"];
      planetColorBaseList = ["0A5F84","856A18","04916F"];
      planetColorRingList = ["751E87","10871D","87802B"];
    } else if (temperature_ < 213) {
      planetColorSurfaceList = ["7D5191","544A91","918B60"];
      planetColorBaseList = ["0C6A74","067341","113673"];
      planetColorRingList = ["D8D8D8","8DCFD9","D6AB89"];
    } else if (temperature_ < 233) {
      planetColorSurfaceList = ["8F97FF","A432CA","46C9DF"];
      planetColorBaseList = ["194D8C","8C894A","614A8A"];
      planetColorRingList = ["B4EBA0","EBDD59","EB6A4D"];
    } else if (temperature_ < 253) {
      planetColorSurfaceList = ["26171B","172619","733B4A"];
      planetColorBaseList = ["9FD7F2","F2CEA0","5D8DA6"];
      planetColorRingList = ["CCC922","6E23CC","807E0B"];
    } else if (temperature_ < 273) {
      planetColorSurfaceList = ["7D5191","410087","1C003B"];
      planetColorBaseList = ["0b670b","086424","630908"];
      planetColorRingList = ["1454C9","C99014","806838"];
    } else if (temperature_ < 293) {
      planetColorSurfaceList = ["FFFF00","B3091D","FFAA52"];
      planetColorBaseList = ["420087","8E1919","1C003B"];
      planetColorRingList = ["070E87","3B2F00","D48B20"];
    } else if (temperature_ < 313) {
      planetColorSurfaceList = ["C50034","007810","86129A"];
      planetColorBaseList = ["6C78AC","ABA75B","8874AB"];
      planetColorRingList = ["410087","33870E","870780"];
    } else if (temperature_ < 333) {
      planetColorSurfaceList = ["0A0A8F","56118F","8F6118"];
      planetColorBaseList = ["C87D4F","61C790","C7A058"];
      planetColorRingList = ["77BD69","A37DBD","BD5F57"];
    } else if (temperature_ < 353) {
      planetColorSurfaceList = ["8E1919","478F21","8F138F"];
      planetColorBaseList = ["FFFF00","FF0095","B30068"];
      planetColorRingList = ["E0940E","004894","945F04"];
    } else if (temperature_ < 373) {
      planetColorSurfaceList = ["FF5C37","B33215","039560"];
      planetColorBaseList = ["FFD55B","B3912E","B35D0C"];
      planetColorRingList = ["1CC5E5","007F99","199908"];
    }

    planetColorPaletteTemp.colorSurface = planetColorSurfaceList[randomColorSurface];
    planetColorPaletteTemp.colorBase = planetColorBaseList[randomColorBase];
    planetColorPaletteTemp.colorRing = planetColorRingList[randomColorRing];

    planetColorPalette = planetColorPaletteTemp;
    offsetRandom = newOffsetRandom;

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

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;

interface IPlanetsDescriptor{
  /**
  * @dev return SVG code
  */
  function tokenURI(uint256 tokenId_) external view returns  (string memory);
  function tokenURIWithoutCard(uint256 tokenId_) external view returns  (string memory);
  function initPlanet(uint256 tokenId_) external;

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

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import "../../utils/SVGUtils.sol";
import "../../PlanetsDescriptor.sol";


library DataDescriptor_1 {

  function getSVG(uint tokenId_, PlanetsDescriptor.PlanetMetadata memory planetMetadata_) public pure returns (string memory svg) {

    svg = string(
      abi.encodePacked(
    getLogo(),
    getPlanetIDField(tokenId_),
    getNameField(planetMetadata_.name),
    getSizeField(planetMetadata_.size)
    )
    );
  }

  function getLogo() private pure returns (string memory svg) {

    svg = string(
      abi.encodePacked(
        '<path class="fill_white" d="M499.15,52.62c-1.25-0.38-2.61-0.58-4.02-0.63c-1.22-0.77-2.66-1.22-4.21-1.22c-2.8,0-5.25,1.45-6.66,3.64',
        'c-1.4,0.72-2.67,1.58-3.72,2.57c-4.44,4.17-3.32,8.98,2.52,10.74c5.83,1.76,14.16-0.19,18.61-4.36',
        'C506.11,59.2,504.98,54.39,499.15,52.62z M498.36,62.37c-0.25,0.24-0.53,0.46-0.82,0.68c0.82-1.25,1.3-2.74,1.3-4.35',
        'c0-1.06-0.21-2.08-0.59-3C500.78,57.22,500.94,59.95,498.36,62.37z M483.01,58.91c0.08,2.95,1.76,5.49,4.21,6.79',
        'c-0.57-0.07-1.12-0.18-1.64-0.34C482,64.28,481.01,61.53,483.01,58.91z M484.11,66.74c-5.07-1.53-6.05-5.71-2.19-9.34',
        'c0.45-0.42,0.94-0.81,1.47-1.17c-0.03,0.09-0.06,0.18-0.08,0.27c-0.42,0.3-0.82,0.62-1.18,0.96c-3.77,3.54-2.82,7.63,2.14,9.13',
        'c2.74,0.83,6.13,0.69,9.26-0.2c2.52-0.72,4.87-1.92,6.55-3.51c3.77-3.54,2.82-7.63-2.14-9.13c-0.34-0.1-0.69-0.19-1.05-0.26',
        'c-0.06-0.07-0.13-0.14-0.19-0.21c0.48,0.09,0.95,0.19,1.4,0.32c5.07,1.53,6.05,5.71,2.19,9.34c-1.9,1.78-4.62,3.1-7.5,3.8',
        'C489.82,67.46,486.69,67.51,484.11,66.74z"/> ',
        '<circle class="circle_logo" cx="491.1" cy="59.58" r="18.29"/> '


    )
    );
  }

  function getPlanetIDField(uint tokenId_) private pure returns (string memory svg) {

    svg = string(
      abi.encodePacked(
        '<path class="fill_field" d="M389.25,45.63c0.63,0,1.16,0.22,1.6,0.67c0.44,0.44,0.67,0.97,0.67,1.59c0,0.62-0.22,1.16-0.67,1.6',
        'c-0.44,0.44-0.97,0.67-1.6,0.67h-9.38v3.23h-1.29v-4.53h10.67c0.27,0,0.5-0.09,0.69-0.28c0.19-0.19,0.28-0.42,0.28-0.69',
        'c0-0.26-0.09-0.49-0.28-0.68c-0.19-0.19-0.42-0.28-0.69-0.28h-10.67v-1.3H389.25z',
        'M394.44,45.63v6.47h11.64v1.29h-12.93v-7.76H394.44z',
        'M415.69,45.63l6.83,7.76h-1.72l-5.68-6.46l-5.68,6.46h-1.72l6.83-7.76H415.69z',
        'M437.08,45.63v7.76h-1.81l-9.83-6.55v6.55h-1.29v-7.76h1.81l9.83,6.55v-6.55H437.08z',
        'M451.65,45.63v1.3h-12.93v-1.3H451.65z M451.65,48.86v1.3H440v1.94h11.64v1.29h-12.93v-4.53H451.65z',
        'M466.21,45.63v1.3h-5.82v6.46h-1.3v-6.46h-5.82v-1.3H466.21z"/> ',
        '<text transform="matrix(1 0 0 1 410.87,80)" class="text_metadata">',SVGUtils.uint2str(tokenId_, 0),'</text> '
      )
    );
  }

  function getNameField(string memory name_) private pure returns (string memory svg) {

    svg = string(
      abi.encodePacked(
        '<path class="fill_field" d="M70.75,505.83v7.76h-1.81l-9.83-6.55v6.55h-1.29v-7.76h1.81l9.83,6.55v-6.55H70.75z',
        'M80.36,505.83l6.83,7.76h-1.72l-5.68-6.46l-5.68,6.46h-1.72l6.83-7.76H80.36z',
        'M102.39,505.83v7.76h-1.3v-5.99l-5.49,4.92l-5.5-4.92v5.99h-1.29v-7.76h1.25l5.54,4.95l5.54-4.95H102.39z',
        'M116.95,505.83v1.3h-12.94v-1.3H116.95z M116.95,509.06v1.3h-11.64v1.94h11.64v1.29h-12.94v-4.53H116.95z"/> ',
        '<text transform="matrix(1 0 0 1 56.997 552.985)" class="text_name">', name_,'</text> ',
        '<rect x="57.69" y="572.68" class="fill_field" width="451.15" height="1.77"/> '
    )
    );
  }

  function getSizeField(uint size_) private pure returns (string memory svg) {

    svg = string(
      abi.encodePacked(
      '<path class="fill_field" d="M58.66,630.26v-1.67h13.38c0.35,0,0.64-0.12,0.89-0.37c0.24-0.24,0.36-0.54,0.36-0.88',
      'c0-0.35-0.12-0.64-0.36-0.89c-0.25-0.24-0.55-0.37-0.89-0.37H61.16c-0.8,0-1.49-0.29-2.07-0.86c-0.57-0.57-0.86-1.26-0.86-2.07',
      'c0-0.8,0.29-1.49,0.86-2.06c0.58-0.58,1.27-0.86,2.07-0.86h13.39v1.68H61.16c-0.35,0-0.64,0.12-0.88,0.37',
      'c-0.25,0.25-0.37,0.54-0.37,0.88c0,0.35,0.12,0.64,0.37,0.89c0.24,0.24,0.54,0.37,0.88,0.37h10.88c0.81,0,1.5,0.29,2.07,0.86',
      'c0.57,0.57,0.86,1.26,0.86,2.07c0,0.8-0.29,1.49-0.86,2.07c-0.57,0.57-1.26,0.86-2.07,0.86H58.66z',
      'M77.08,620.22h1.67v10.04h-1.67V620.22z',
      'M97.59,620.22v1.33l-12.67,7.04h12.67v1.67H80.86v-1.33l12.67-7.04H80.86v-1.68H97.59z',
      'M116.43,620.22v1.68H99.7v-1.68H116.43z M116.43,624.4v1.68h-15.07v2.51h15.07v1.67H99.7v-5.86H116.43z"/> ',
      '<linearGradient id="LG_DATA_2" gradientUnits="userSpaceOnUse" x1="165.0645" y1="693.3967" x2="165.0645" y2="636.9879"> ',
      '<stop  offset="0" style="stop-color:#1E1E1E"/> <stop  offset="1" style="stop-color:#212121"/> ',
      '</linearGradient> ',
      '<polygon style="fill:url(#LG_DATA_2);" points="62.26,692.92 66.86,693.4 ',
      '58.69,685.22 58.69,645.16 66.86,636.99 263.27,636.99 271.44,645.16 271.44,685.22"/> ',
      '<text transform="matrix(1 0 0 1 75.7793 673.9238)" class="text_metadata">', SVGUtils.uint2str(size_, 0),' mq</text> '

    )
    );
  }

}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import "../../utils/SVGUtils.sol";
import "../../PlanetsDescriptor.sol";


library DataDescriptor_2 {

  function getSVG(PlanetsDescriptor.PlanetMetadata memory planetMetadata_) public pure returns (string memory svg) {

    svg = string(
      abi.encodePacked(
      getPositionField(planetMetadata_.position.x, planetMetadata_.position.y),
      getHabitabilityField(planetMetadata_.habitability),
      getTemperatureField(planetMetadata_.temperature),
      getSatelliteField(planetMetadata_.nSatellite)
    )
    );
  }

  function getPositionField(int xPosition_, int yPosition_) private pure returns (string memory svg) {

    svg = string(
      abi.encodePacked(
        '<path class="fill_field" d="M72.04,711.81c0.81,0,1.5,0.29,2.07,0.86c0.57,0.57,0.86,1.26,0.86,2.06c0,0.81-0.29,1.5-0.86,2.07',
        'c-0.57,0.57-1.26,0.86-2.07,0.86H59.91v4.18h-1.67V716h13.8c0.35,0,0.64-0.12,0.89-0.37c0.24-0.25,0.36-0.54,0.36-0.89',
        'c0-0.34-0.12-0.64-0.36-0.88c-0.25-0.24-0.55-0.37-0.89-0.37h-13.8v-1.68H72.04z',
        'M80.01,721.86c-0.8,0-1.49-0.29-2.07-0.86c-0.57-0.57-0.86-1.26-0.86-2.07v-4.19',
        'c0-0.8,0.29-1.49,0.86-2.06c0.58-0.58,1.27-0.86,2.07-0.86h10.88c0.81,0,1.5,0.29,2.07,0.86c0.57,0.57,0.86,1.26,0.86,2.06v4.19',
        'c0,0.8-0.29,1.49-0.86,2.07c-0.57,0.57-1.26,0.86-2.07,0.86H80.01z M80.01,713.49c-0.35,0-0.64,0.12-0.88,0.37',
        'c-0.25,0.25-0.37,0.54-0.37,0.88v4.19c0,0.35,0.12,0.64,0.37,0.88c0.24,0.25,0.54,0.37,0.88,0.37h10.88',
        'c0.35,0,0.64-0.12,0.89-0.37c0.24-0.24,0.36-0.54,0.36-0.88v-4.19c0-0.34-0.12-0.64-0.36-0.88c-0.25-0.24-0.55-0.37-0.89-0.37',
        'H80.01zM96.34,721.86v-1.67h13.38c0.35,0,0.64-0.12,0.89-0.37c0.24-0.24,0.36-0.54,0.36-0.88',
        'c0-0.35-0.12-0.64-0.36-0.89c-0.25-0.24-0.55-0.37-0.89-0.37H98.85c-0.8,0-1.49-0.29-2.07-0.86c-0.57-0.57-0.86-1.26-0.86-2.07',
        'c0-0.8,0.29-1.49,0.86-2.06c0.58-0.58,1.27-0.86,2.07-0.86h13.39v1.68H98.85c-0.35,0-0.64,0.12-0.88,0.37',
        'c-0.25,0.25-0.37,0.54-0.37,0.88c0,0.35,0.12,0.64,0.37,0.89c0.24,0.24,0.54,0.37,0.88,0.37h10.88c0.81,0,1.5,0.29,2.07,0.86',
        'c0.57,0.57,0.86,1.26,0.86,2.07c0,0.8-0.29,1.49-0.86,2.07c-0.57,0.57-1.26,0.86-2.07,0.86H96.34z',
        'M114.76,711.81h1.67v10.04h-1.67V711.81z',
        'M135.28,711.81v1.68h-7.53v8.36h-1.68v-8.36h-7.53v-1.68H135.28z',
        'M137.38,711.81h1.67v10.04h-1.67V711.81z',
        'M144.08,721.86c-0.8,0-1.49-0.29-2.07-0.86c-0.57-0.57-0.86-1.26-0.86-2.07v-4.19',
        'c0-0.8,0.29-1.49,0.86-2.06c0.58-0.58,1.27-0.86,2.07-0.86h10.88c0.81,0,1.5,0.29,2.07,0.86c0.57,0.57,0.86,1.26,0.86,2.06v4.19',
        'c0,0.8-0.29,1.49-0.86,2.07c-0.57,0.57-1.26,0.86-2.07,0.86H144.08z M144.08,713.49c-0.35,0-0.64,0.12-0.88,0.37',
        'c-0.25,0.25-0.37,0.54-0.37,0.88v4.19c0,0.35,0.12,0.64,0.37,0.88c0.24,0.25,0.54,0.37,0.88,0.37h10.88',
        'c0.35,0,0.64-0.12,0.89-0.37c0.24-0.24,0.36-0.54,0.36-0.88v-4.19c0-0.34-0.12-0.64-0.36-0.88c-0.25-0.24-0.55-0.37-0.89-0.37',
        'H144.08z',
        'M176.74,711.81v10.04h-2.34l-12.72-8.48v8.48H160v-10.04h2.34l12.72,8.48v-8.48H176.74z"/> ',
        '<linearGradient id="LG_DATA_3" gradientUnits="userSpaceOnUse" x1="163.8996" y1="787.3193" x2="163.8996" y2="730.9104"> ',
        '<stop  offset="0" style="stop-color:#1E1E1E"/> <stop  offset="1" style="stop-color:#212121"/> </linearGradient> ',
        '<polygon style="fill:url(#LG_DATA_3);" points="263.27,787.32 64.53,787.32 ',
        '56.36,779.14 56.36,739.08 64.53,730.91 263.27,730.91 271.44,739.08 271.44,779.14"/> ',
        '<text transform="matrix(1 0 0 1 75.7793 770.3943)" class="text_metadata"> X ',xPosition_>=0?'':'-',SVGUtils.uint2str(uint(SVGUtils.abs(xPosition_)), 0),' Y ',yPosition_>=0?'':'-',SVGUtils.uint2str(uint(SVGUtils.abs(yPosition_)), 0),'</text> '
    )
    );
  }

  function getHabitabilityField(uint habitability_) private pure returns (string memory svg) {

    svg = string(
      abi.encodePacked(
        '<path class="fill_field" d="M314.07,711.81v10.04h-1.68v-4.18H299v4.18h-1.67v-10.04H299V716h13.39v-4.18H314.07z',
        'M326.5,711.81l8.83,10.04h-2.23l-7.36-8.36l-7.35,8.36h-2.23l8.83-10.04H326.5z',
        'M337.44,721.86v-10.04h13.8c0.81,0,1.5,0.29,2.07,0.86c0.57,0.57,0.86,1.26,0.86,2.06',
        'c0,0.82-0.29,1.52-0.88,2.1c0.59,0.57,0.88,1.27,0.88,2.09c0,0.8-0.29,1.49-0.86,2.07c-0.57,0.57-1.26,0.86-2.07,0.86H337.44z',
        'M339.11,716h12.13c0.35,0,0.64-0.12,0.89-0.37c0.24-0.25,0.37-0.54,0.37-0.89c0-0.34-0.12-0.64-0.37-0.88',
        'c-0.25-0.24-0.54-0.37-0.89-0.37h-12.13V716z M339.11,720.19h12.13c0.35,0,0.64-0.12,0.89-0.37c0.24-0.24,0.37-0.54,0.37-0.88',
        'c0-0.35-0.12-0.64-0.37-0.89c-0.25-0.24-0.54-0.37-0.89-0.37h-12.13V720.19z',
        'M356.28,711.81h1.67v10.04h-1.67V711.81z',
        'M376.8,711.81v1.68h-7.53v8.36h-1.68v-8.36h-7.53v-1.68H376.8z',
        'M384.32,711.81l8.83,10.04h-2.23l-7.35-8.36l-7.35,8.36h-2.23l8.83-10.04H384.32z',
        'M395.26,721.86v-10.04h13.8c0.81,0,1.5,0.29,2.07,0.86c0.57,0.57,0.86,1.26,0.86,2.06',
        'c0,0.82-0.3,1.52-0.88,2.1c0.59,0.57,0.88,1.27,0.88,2.09c0,0.8-0.29,1.49-0.86,2.07c-0.57,0.57-1.26,0.86-2.07,0.86H395.26z',
        'M396.93,716h12.13c0.35,0,0.64-0.12,0.89-0.37c0.24-0.25,0.36-0.54,0.36-0.89c0-0.34-0.12-0.64-0.36-0.88',
        'c-0.25-0.24-0.55-0.37-0.89-0.37h-12.13V716z M396.93,720.19h12.13c0.35,0,0.64-0.12,0.89-0.37c0.24-0.24,0.36-0.54,0.36-0.88',
        'c0-0.35-0.12-0.64-0.36-0.89c-0.25-0.24-0.55-0.37-0.89-0.37h-12.13V720.19z',
        'M414.1,711.81h1.67v10.04h-1.67V711.81z',
        'M419.55,711.81v8.37h15.07v1.67h-16.74v-10.04H419.55z',
        'M436.72,711.81h1.67v10.04h-1.67V711.81z',
        'M457.23,711.81v1.68h-7.53v8.36h-1.68v-8.36h-7.53v-1.68H457.23z',
        'M476.63,711.81l-7.81,5.86v4.18h-1.67v-4.18l-7.81-5.86h2.79l5.86,4.39l5.86-4.39H476.63z" />',
        '<linearGradient id="LG_DATA_4" gradientUnits="userSpaceOnUse" x1="402.3722" y1="787.3193" x2="402.3722" y2="730.9104"> ',
        '<stop  offset="0" style="stop-color:#1E1E1E"/> ',
        '<stop  offset="1" style="stop-color:#212121"/> ',
        '</linearGradient> ',
        '<polygon style="fill:url(#LG_DATA_4);" points="501.12,787.32 303.63,787.32 ',
        '295.45,779.14 295.45,739.08 303.63,730.91 501.12,730.91 509.29,739.08 509.29,779.14"/> ',
        '<text transform="matrix(1 0 0 1 314.8719 770.6815)" class="text_metadata">',SVGUtils.uint2str(habitability_, 0),' %</text> '
    )
    );
  }

  function getTemperatureField(uint temperature_) private pure returns (string memory svg) {

    svg = string(
      abi.encodePacked(
        '<path class="fill_field" d="M399.51,620.22v1.68h-7.53v8.36h-1.68v-8.36h-7.53v-1.68H399.51z',
        'M418.35,620.22v1.68h-16.74v-1.68H418.35z M418.35,624.4v1.68h-15.07v2.51h15.07v1.67h-16.74v-5.86H418.35z',
        'M438.03,620.22v10.04h-1.68v-7.75l-7.11,6.36l-7.12-6.36v7.75h-1.67v-10.04h1.62l7.16,6.41l7.16-6.41H438.03z',
        'M453.94,620.22c0.81,0,1.5,0.29,2.07,0.86c0.57,0.57,0.86,1.26,0.86,2.06c0,0.81-0.29,1.5-0.86,2.07',
        'c-0.57,0.57-1.26,0.86-2.07,0.86H441.8v4.18h-1.67v-5.86h13.8c0.35,0,0.64-0.12,0.89-0.37c0.24-0.25,0.36-0.54,0.36-0.89',
        'c0-0.34-0.12-0.64-0.36-0.88c-0.25-0.24-0.55-0.37-0.89-0.37h-13.8v-1.68H453.94z',
        'M458.98,628.59h1.67v1.67h-1.67V628.59z"/> ',
        '<linearGradient id="LG_DATA_5" gradientUnits="userSpaceOnUse" x1="446.2581" y1="693.3967" x2="446.2581" y2="636.9879"> ',
        '<stop  offset="0" style="stop-color:#1E1E1E"/> ',
        '<stop  offset="1" style="stop-color:#212121"/> ',
        '</linearGradient> ',
        '<polygon style="fill:url(#LG_DATA_5);" points="501.12,693.4 391.4,693.4 ',
        '383.22,685.22 383.22,645.16 391.4,636.99 501.12,636.99 509.29,645.16 509.29,685.22"/> ',
        '<text transform="matrix(1 0 0 1 395.9025 673.9238)" class="text_metadata">', SVGUtils.uint2str(temperature_, 0),' K</text> '

    )
    );
  }

  function getSatelliteField(uint nSatellite_) private pure returns (string memory svg) {

    svg = string(
      abi.encodePacked(
        '<path class="fill_field" d="M60.28,824.54v-1.8h14.46c0.37,0,0.69-0.13,0.96-0.4c0.26-0.26,0.39-0.58,0.39-0.96',
        's-0.13-0.7-0.39-0.96c-0.27-0.26-0.59-0.39-0.96-0.39H62.99c-0.87,0-1.61-0.31-2.24-0.93c-0.62-0.62-0.92-1.36-0.92-2.24',
        'c0-0.87,0.31-1.61,0.92-2.23c0.62-0.62,1.37-0.93,2.24-0.93h14.47v1.81H62.99c-0.37,0-0.69,0.13-0.96,0.39',
        'c-0.27,0.27-0.4,0.59-0.4,0.96c0,0.37,0.13,0.7,0.4,0.96c0.26,0.26,0.58,0.39,0.96,0.39h11.75c0.87,0,1.62,0.31,2.24,0.93',
        'c0.62,0.62,0.93,1.36,0.93,2.24c0,0.87-0.31,1.61-0.93,2.24c-0.62,0.62-1.36,0.92-2.24,0.92H60.28z',
        'M91.34,813.69l9.54,10.85h-2.41l-1.59-1.8h-12.7l-1.59,1.8h-2.41l9.54-10.85H91.34z M85.77,820.92h9.53',
        'l-4.77-5.41L85.77,820.92z',
        'M115.93,813.69v1.81h-8.14v9.04h-1.81v-9.04h-8.13v-1.81H115.93z',
        'M136.29,813.69v1.81h-18.08v-1.81H136.29z M136.29,818.21v1.81h-16.28v2.71h16.28v1.8h-18.08v-6.33',
        'H136.29z',
        'M140.37,813.69v9.04h16.28v1.8h-18.08v-10.85H140.37z',
        'M160.73,813.69v9.04H177v1.8h-18.08v-10.85H160.73z',
        'M179.28,813.69h1.8v10.85h-1.8V813.69z',
        'M201.44,813.69v1.81h-8.14v9.04h-1.81v-9.04h-8.13v-1.81H201.44z',
        'M221.8,813.69v1.81h-18.08v-1.81H221.8z M221.8,818.21v1.81h-16.28v2.71h16.28v1.8h-18.08v-6.33H221.8z',
        'M224.52,824.54v-1.8h14.46c0.37,0,0.69-0.13,0.96-0.4c0.26-0.26,0.39-0.58,0.39-0.96',
        's-0.13-0.7-0.39-0.96c-0.27-0.26-0.59-0.39-0.96-0.39h-11.75c-0.87,0-1.61-0.31-2.24-0.93c-0.62-0.62-0.92-1.36-0.92-2.24',
        'c0-0.87,0.31-1.61,0.92-2.23c0.62-0.62,1.37-0.93,2.24-0.93h14.47v1.81h-14.47c-0.37,0-0.69,0.13-0.96,0.39',
        'c-0.27,0.27-0.4,0.59-0.4,0.96c0,0.37,0.13,0.7,0.4,0.96c0.26,0.26,0.58,0.39,0.96,0.39h11.75c0.87,0,1.62,0.31,2.24,0.93',
        'c0.62,0.62,0.93,1.36,0.93,2.24c0,0.87-0.31,1.61-0.93,2.24c-0.62,0.62-1.36,0.92-2.24,0.92H224.52z"/> ',
        '<linearGradient id="LG_DATA_6" gradientUnits="userSpaceOnUse" x1="119.5293" y1="887.6956" x2="119.5293" y2="831.2867"> ',
        '<stop  offset="0" style="stop-color:#1E1E1E"/> ',
        '<stop  offset="1" style="stop-color:#212121"/> ',
        '</linearGradient> ',
        '<polygon style="fill:url(#LG_DATA_6);" points="174.39,887.7 64.67,887.7 ',
        '56.49,879.52 56.49,839.46 64.67,831.29 174.39,831.29 182.56,839.46 182.56,879.52 "/> ',
        '<text transform="matrix(1 0 0 1 69.1736 868.2227)" class="text_metadata">', SVGUtils.uint2str(nSatellite_, 0),' </text> '
    )
    );
  }

}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import "../../utils/PlanetRandom.sol";
import "./Sky4/Sky4Descriptor.sol";
import "./Sky1/Sky1Descriptor.sol";
import "./Sky2/Sky2Descriptor.sol";
import "./Sky3/Sky3Descriptor.sol";


library SkyBaseDescriptor {

  function getSVG(uint256 tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public view returns (string memory svg, uint offsetRandom) {

    string memory svgLayer;
    uint newOffsetRandom;

    // select random sky layer
    uint randomSkyLayer = PlanetRandom.calcRandom(0,4, blockhashInit_, tokenId_);

    if (randomSkyLayer == 0) {
      (svgLayer, newOffsetRandom) = Sky4Descriptor.getSVG(tokenId_, blockhashInit_, offsetRandom_);
      svg = string(
        abi.encodePacked(
          '<g id="sky_4"> ',
          svgLayer,
          '</g> '
        )
      );
    } else if (randomSkyLayer == 1) {
      (svgLayer, newOffsetRandom) = Sky1Descriptor.getSVG(tokenId_, blockhashInit_, offsetRandom_);
      svg = string(
        abi.encodePacked(
          '<g id="sky_1"> ',
          svgLayer,
          '</g> '
        )
      );
    } else if (randomSkyLayer == 2) {
      (svgLayer, newOffsetRandom) = Sky2Descriptor.getSVG(tokenId_, blockhashInit_, offsetRandom_);
      svg = string(
        abi.encodePacked(
          '<g id="sky_2"> ',
          svgLayer,
          '</g> '
        )
      );
    } else {
      (svgLayer, newOffsetRandom) = Sky3Descriptor.getSVG(tokenId_, blockhashInit_, offsetRandom_);
      svg = string(
        abi.encodePacked(
          '<g id="sky_3"> ',
          svgLayer,
          '</g> '
        )
      );
    }
    offsetRandom = newOffsetRandom;
  }

}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import "../../utils/PlanetRandom.sol";
import "../../utils/SVGUtils.sol";

library SkyCircleDescriptor {

    struct ParamsCircle {
        string fillClass;
        uint nMin;
        uint nMax;

    }

    function getSVG(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public view returns (string memory svg, uint offsetRandom) {

        (string memory svgCircleWhite, uint newOffsetRandom1) = getCircleSVG(tokenId_, blockhashInit_, offsetRandom_, ParamsCircle("fill_white_star",10,21) );
        (string memory svgCircleRed, uint newOffsetRandom2) = getCircleSVG(tokenId_, blockhashInit_, newOffsetRandom1, ParamsCircle("fill_red_star",5,10) );
        (string memory svgCircleBlue, uint newOffsetRandom3) = getCircleSVG(tokenId_, blockhashInit_, newOffsetRandom2, ParamsCircle("fill_blue_star",10,21) );
        (string memory svgCirclePurple, uint newOffsetRandom4) = getCircleSVG(tokenId_, blockhashInit_, newOffsetRandom3, ParamsCircle("fill_purple_star",5,10) );

        offsetRandom = newOffsetRandom4;

        svg = string(
            abi.encodePacked(
                svgCircleWhite,
                svgCircleRed,
                svgCircleBlue,
                svgCirclePurple
            )
        );

    }

    function getCircleSVG(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_, ParamsCircle memory paramsCircle) private pure returns (string memory svg, uint offsetRandom) {
        uint index = 0;

        bytes32 randomHash = PlanetRandom.getRandomHash(blockhashInit_, tokenId_ + offsetRandom_);
        offsetRandom_ = offsetRandom_ + 1124;

        uint nCircle = PlanetRandom.calcRandomBytes1(paramsCircle.nMin, paramsCircle.nMax, randomHash, index);
        index ++;

        string memory svgTemp = "";

        for(uint i = 0; i < nCircle ; i++) {
            if (index == 31 || index +1 == 31 || index +2 == 31 ) {
                randomHash = PlanetRandom.getRandomHash(blockhashInit_, tokenId_ + offsetRandom_);
                offsetRandom_ = offsetRandom_ + 1124;
                index = 0;
            }
            uint xPoint = PlanetRandom.calcRandomBytes1(0, 566, randomHash, index);
            index ++;
            uint yPoint = PlanetRandom.calcRandomBytes1(0, 935, randomHash, index);
            index ++;
            uint size = PlanetRandom.calcRandomBytes1(0, 25, randomHash, index);
            index ++;

            svgTemp = string(
                abi.encodePacked(
                    svgTemp,
                    '<circle class="', paramsCircle.fillClass, '" ',
                    'cx="', SVGUtils.uint2str(xPoint, 0), '" ',
                    'cy="', SVGUtils.uint2str(yPoint, 0), '" ',
                    'r="', SVGUtils.uint2str(size, 1),'"/> '
                )
            );
        }

        svg = svgTemp;
        offsetRandom = offsetRandom_;
    }

}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import "../../utils/PlanetRandom.sol";
import "../../utils/SVGUtils.sol";


library SkyRhombusDescriptor {

  function getSVG(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public pure returns (string memory svg, uint offsetRandom) {

    (string memory svgRhombusBig, uint newOffsetRandom) = getRhombusBig(tokenId_, blockhashInit_, offsetRandom_);
    (string memory svgRhombusMedium, uint newOffsetRandom2) = getRhombusMedium(tokenId_, blockhashInit_, newOffsetRandom);
    (string memory svgRhombusSmall, uint newOffsetRandom3) = getRhombusSmall(tokenId_, blockhashInit_, newOffsetRandom2);

    offsetRandom = newOffsetRandom3;
    svg = string(
      abi.encodePacked(
        svgRhombusBig,
        svgRhombusMedium,
        svgRhombusSmall
      )
    );
  }

  function getRhombusBig(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) private pure returns (string memory svg, uint offsetRandom) {
    uint index = 0;

    bytes32 randomHashRhombusBig = PlanetRandom.getRandomHash(blockhashInit_, tokenId_ + offsetRandom_);
    offsetRandom_ = offsetRandom_ + 1124;

    uint nRhombus = PlanetRandom.calcRandomBytes1(1, 5, randomHashRhombusBig, index);
    index ++;

    string memory svgTemp = "";

    for (uint i = 0; i < nRhombus; i++) {
      if (index == 31 || index + 1 == 31) {
        randomHashRhombusBig = PlanetRandom.getRandomHash(blockhashInit_, tokenId_ + offsetRandom_);
        offsetRandom_ = offsetRandom_ + 1124;
        index = 0;
      }
      uint xPoint = PlanetRandom.calcRandomBytes1(0, 566, randomHashRhombusBig, index);
      index ++;
      uint yPoint = PlanetRandom.calcRandomBytes1(0, 935, randomHashRhombusBig, index);
      index ++;

      svgTemp = string(
        abi.encodePacked(
          svgTemp,
          '<path class="fill_white" d="',
          'M', SVGUtils.uint2str(xPoint, 0), ',', SVGUtils.uint2str(yPoint, 0),
          'l1.9,8.4c0.2,1,1,1.7,2,1.9l8.5,1.5l-8.4,1.9c-1,0.2-1.7,1-1.9,2l-1.5,8.5',
          'L', SVGUtils.uint2str(xPoint < 1 ?0:xPoint - 1, 0), ',', SVGUtils.uint2str(yPoint + 16, 0),
          'c-0.2-1-1-1.7-2-1.9',
          'L', SVGUtils.uint2str(xPoint < 12 ?0:xPoint - 12, 0), ',', SVGUtils.uint2str(yPoint + 13, 0),
          'l8.4-1.9c1-0.2,1.7-1,1.9-2',
          'L', SVGUtils.uint2str(xPoint, 0), ',', SVGUtils.uint2str(yPoint, 0),
          'z"/> '
        )
      );

    }

    svg = svgTemp;
    offsetRandom = offsetRandom_;
  }

  function getRhombusMedium(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) private pure returns (string memory svg, uint offsetRandom) {
    uint index = 0;

    bytes32 randomHashRhombusMedium = PlanetRandom.getRandomHash(blockhashInit_, tokenId_ + offsetRandom_);
    offsetRandom_ = offsetRandom_ + 1124;

    uint nRhombus = PlanetRandom.calcRandomBytes1(1, 5, randomHashRhombusMedium, index);
    index ++;

    string memory svgTemp = "";

    for (uint i = 0; i < nRhombus; i++) {
      if (index == 31 || index + 1 == 31) {
        randomHashRhombusMedium = PlanetRandom.getRandomHash(blockhashInit_, tokenId_ + offsetRandom_);
        offsetRandom_ = offsetRandom_ + 1124;
        index = 0;
      }
      uint xPoint = PlanetRandom.calcRandomBytes1(0, 566, randomHashRhombusMedium, index);
      index ++;
      uint yPoint = PlanetRandom.calcRandomBytes1(0, 935, randomHashRhombusMedium, index);
      index ++;

      svgTemp = string(
        abi.encodePacked(
          svgTemp,
          '<path class="fill_white" d="',
          'M', SVGUtils.uint2str(xPoint, 0), ',', SVGUtils.uint2str(yPoint, 0),
          'l1.6,7c0.2,0.8,0.8,1.4,1.7,1.6l7,1.3l-7,1.6c-0.8,0.2-1.4,0.8-1.6,1.7l-1.3,7l-1.6-7',
          'c-0.2-0.8-0.8-1.4-1.7-1.6l-7-1.3l7-1.6c0.8-0.2,1.4-0.8,1.6-1.7',
          'L', SVGUtils.uint2str(xPoint, 0), ',', SVGUtils.uint2str(yPoint, 0), 'z"/> '
        )
      );

    }

    svg = svgTemp;
    offsetRandom = offsetRandom_;
  }

  function getRhombusSmall(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) private pure returns (string memory svg, uint offsetRandom) {
    uint index = 0;

    bytes32 randomHashRhombusSmall = PlanetRandom.getRandomHash(blockhashInit_, tokenId_ + offsetRandom_);
    offsetRandom_ = offsetRandom_ + 1124;

    uint nRhombus = PlanetRandom.calcRandomBytes1(1, 5, randomHashRhombusSmall, index);
    index ++;

    string memory svgTemp = "";

    for (uint i = 0; i < nRhombus; i++) {
      if (index == 31 || index + 1 == 31) {
        randomHashRhombusSmall = PlanetRandom.getRandomHash(blockhashInit_, tokenId_ + offsetRandom_);
        offsetRandom_ = offsetRandom_ + 1124;
        index = 0;
      }
      uint xPoint = PlanetRandom.calcRandomBytes1(0, 566, randomHashRhombusSmall, index);
      index ++;
      uint yPoint = PlanetRandom.calcRandomBytes1(0, 935, randomHashRhombusSmall, index);
      index ++;

      svgTemp = string(
        abi.encodePacked(
          svgTemp,
          '<path class="fill_white" d="',
          'M', SVGUtils.uint2str(xPoint, 0), ',', SVGUtils.uint2str(yPoint, 0),
          'l0.9,4.1c0.1,0.5,0.5,0.8,1,0.9l4.1,0.7l-4.1,0.9c-0.5,0.1-0.8,0.5-0.9,1l-0.7,4.1l-0.9-4.1',
          'c-0.1-0.5-0.5-0.8-1-0.9l-4.1-0.7l4.1-0.9c0.5-0.1,0.8-0.5,0.9-1',
          'L', SVGUtils.uint2str(xPoint, 0), ',', SVGUtils.uint2str(yPoint, 0), 'z"/> '
        )
      );

    }

    svg = svgTemp;
    offsetRandom = offsetRandom_;
  }

}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import "./Sky4PathDescriptor.sol";

library Sky4Descriptor {

  function getSVG(uint256 tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public pure returns (string memory svg, uint offsetRandom) {

    (string memory svgPath, uint newOffsetRandom) = Sky4PathDescriptor.getSVG(tokenId_, blockhashInit_, offsetRandom_);

    offsetRandom = newOffsetRandom;
    svg = string(
      abi.encodePacked(
        '<linearGradient id="SKY_4_MAIN" gradientUnits="userSpaceOnUse" ',
        'x1="283.4646" y1="3.1512" x2="283.4646" y2="562.0206"> ',
        '<stop  offset="0.1587" style="stop-color:#224D4D"/> ',
        '<stop  offset="0.315" style="stop-color:#12414A"/> ',
        '<stop  offset="0.8087" style="stop-color:#0A1913"/> </linearGradient> ',
        '<path style="fill:url(#SKY_4_MAIN);" d="M0,0v935.43h566.9V0H0z"/> ',
        svgPath
      )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import "./Sky1PathDescriptor.sol";


library Sky1Descriptor {

    function getSVG(uint256 tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public view returns (string memory svg, uint offsetRandom) {

        (string memory svgPath, uint newOffsetRandom) = Sky1PathDescriptor.getSVG(tokenId_, blockhashInit_, offsetRandom_);

        offsetRandom = newOffsetRandom;
        svg = string(
            abi.encodePacked(
                '<radialGradient id="SKY_1_MAIN" cx="283.4646" cy="283.4646" r="283.4646" gradientUnits="userSpaceOnUse"> ',
                '<stop  offset="0" style="stop-color:#4F4FA6"/> ',
                '<stop  offset="0.35" style="stop-color:#212145"/> ',
                '<stop  offset="0.6706" style="stop-color:#0F1120"/> ',
                '</radialGradient> ',
                '<path style="fill:url(#SKY_1_MAIN);" d="M0,0v935.43h566.9V0H0z"/> ',
                    svgPath
            )
        );
    }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import "./Sky2PathDescriptor.sol";


library Sky2Descriptor {

  function getSVG(uint256 tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public pure returns (string memory svg, uint offsetRandom) {

    (string memory svgPath, uint newOffsetRandom) = Sky2PathDescriptor.getSVG(tokenId_, blockhashInit_, offsetRandom_);

    offsetRandom = newOffsetRandom;
    svg = string(
      abi.encodePacked(
        '<radialGradient id="SKY_2_MAIN" cx="268.519" cy="295.4548" r="324.6202" gradientUnits="userSpaceOnUse"> ',
        '<stop  offset="0.0634" style="stop-color:#543833"/> ',
        '<stop  offset="0.4356" style="stop-color:#362209"/> ',
        '<stop  offset="0.89" style="stop-color:#0F0903"/> ',
        '</radialGradient> ',
        '<path style="fill:url(#SKY_2_MAIN);" d="M0,0v935.43h566.9V0H0z"/> ',
          svgPath
    )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import "./Sky3PathDescriptor.sol";


library Sky3Descriptor {

  function getSVG(uint256 tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public pure returns (string memory svg, uint offsetRandom) {

    (string memory svgPathShadow, uint newOffsetRandom) = Sky3PathDescriptor.getSVG(tokenId_, blockhashInit_, offsetRandom_);

    offsetRandom = newOffsetRandom;
    svg = string(
      abi.encodePacked(
        '<radialGradient id="SKY_3_MAIN" cx="289.8016" cy="275.1698" r="511.3439" gradientUnits="userSpaceOnUse"> ',
        '<stop  offset="0" style="stop-color:#7A346D"/> ',
        '<stop  offset="0.337" style="stop-color:#331A2E"/> ',
        '<stop  offset="0.6867" style="stop-color:#140912"/> ',
        '</radialGradient> ',
        '<path style="fill:url(#SKY_3_MAIN);" d="M0,0v935.43h566.9V0H0z"/> ',
        svgPathShadow
    )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import "../../../utils/PlanetRandom.sol";
import "./Sky4Path1_2Descriptor.sol";
import "./Sky4Path3_4Descriptor.sol";


library Sky4PathDescriptor {

  function getSVG(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public pure returns (string memory svg, uint offsetRandom) {
    uint index;

    // select random path layer
    uint randomPathLayer = PlanetRandom.calcRandom(0, 4, blockhashInit_, offsetRandom_);
    offsetRandom_ = offsetRandom_ + 1124;

    if (randomPathLayer == 0) {
      svg = Sky4Path1_2Descriptor.getPath1();
    } else if (randomPathLayer == 1) {
      svg = Sky4Path1_2Descriptor.getPath2();
    } else if (randomPathLayer == 2) {
      svg = Sky4Path3_4Descriptor.getPath3();
    } else {
      svg = Sky4Path3_4Descriptor.getPath4();
    }

    offsetRandom = offsetRandom_;
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library Sky4Path1_2Descriptor {

  function getPath1() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<path style="opacity:0.3;fill:#31398E;" d="M138.44,117.23c8.52,3.06,17.03,6.13,25.55,9.19c10.46,3.77,21.14,7.65,29.74,14.4',
        'c3.22,2.53,6.17,5.53,7.77,9.18c1.5,3.43,1.73,7.23,1.58,10.94c-0.11,2.88-0.47,5.87-2.08,8.32c-2.74,4.17-8.59,5.8-13.76,5.11',
        'c-5.17-0.69-9.81-3.27-14.19-5.94c-10.84-6.63-21.01-14.2-30.37-22.59c-6.17-5.54-8.94-10.78-11.07-18.29',
        'C129.79,121.1,128.2,113.54,138.44,117.23z',
        'M138.44,117.23c8.52,3.06,17.03,6.13,25.55,9.19c10.46,3.77,21.14,7.65,29.74,14.4',
        'c3.22,2.53,6.17,5.53,7.77,9.18c1.5,3.43,1.73,7.23,1.58,10.94c-0.11,2.88-0.47,5.87-2.08,8.32c-2.74,4.17-8.59,5.8-13.76,5.11',
        'c-5.17-0.69-9.81-3.27-14.19-5.94c-10.84-6.63-21.01-14.2-30.37-22.59c-6.17-5.54-8.94-10.78-11.07-18.29',
        'C129.79,121.1,128.2,113.54,138.44,117.23z"/>',
        '<path style="fill:#4285BC;" d="M33.06,556.69c7.26-36.34,37.89-63.87,70.99-80.54c10.39-5.23,34.2-14.86,42.85-2.15',
        'c5.75,8.46-8.7,15.17-14.61,20.36c-8.17,7.17-16.03,14.72-23.2,22.9c-2.88,3.28-11.31,13.71-12.04,14.62',
        'c-14.01,17.6-28,35.5-48.65,43.31c-0.02,0.01-0.04,0.01-0.06,0.02c-3.13,1.18-6.66,0.55-9.23-1.59l-3.47-2.88',
        'c-1.19-2.46-2.21-4.59-3.4-7.05C32.25,561.35,32.61,558.99,33.06,556.69z"/> ',
        '<linearGradient id="SKY4_LG1" gradientUnits="userSpaceOnUse" x1="69.1293" y1="377.9744" x2="400.7008" y2="377.9744"> ',
        '<stop  offset="5.952380e-03" style="stop-color:#0B0A16"/> ',
        '<stop  offset="1" style="stop-color:#1D6EAF"/> ',
        '</linearGradient> ',
        '<path style="opacity:0.15;fill:url(#SKY4_LG1);" d="M109.11,366.43',
        'c-7.78-1.44-18.31-3.5-29.36-6.21c-8.35-2.05-14.15,8.16-8.15,14.31c5.68,5.83,11.83,11.21,17.17,13.84',
        'c4.48,2.72,9.18,4.87,13.98,6.06c24.02,5.97,39.65-7.4,55.56-2.1C160.27,387.66,123.28,369.05,109.11,366.43z"/> ',
        '<linearGradient id="SKY4_LG2" gradientUnits="userSpaceOnUse" x1="289.8289" y1="240.5063" x2="566.9291" y2="240.5063"> ',
        '<stop  offset="0" style="stop-color:#FFFFFF"/> ',
        '<stop  offset="0.994" style="stop-color:#0B0A16"/> ',
        '</linearGradient> ',
        '<path style="fill:url(#SKY4_LG2);opacity:0.5;" d="M439.9,299.66',
        'c-4.71-12.88-5.74-41.11,14.18-55.55c13.85-10.04,28.21-18.76,42.4-27.95c50.05-32.43-23.45-66.78-31.13-68.88',
        'c-20.64-5.64-41.28-11.28-61.92-16.92c-4.83-1.32-11.04-5.44-9.64-11.73c0.57-2.57,2.34-4.3,4.07-5.66',
        'c10.55-8.26,23.25-9.51,35.31-12.35c12.06-2.83,24.86-8.33,31.77-21.79c2.96-5.76,4.58-13.37,2.48-19.76',
        'c-2.19-6.68-7.68-10.15-12.79-12.77c-7.7-3.93-15.58-7.21-23.59-9.81c-7.51-2.44-15.34-4.4-21.8-10.07',
        'c-6.45-5.67-11.22-16.3-9.05-26.18L302.38,0c-10.06,12.13-24.9,44.05,5.86,57.33c5.42,2.34,211.37-14.27,29.04,74.44',
        'c-8.51,4.14-12.32,20.4-8.47,31.31c4.05,11.48,15.12,13.77,24.48,16.19c29.61,7.68,66,1.86,92.23,4.54',
        'c47.84,4.9-8.89,54.25-22.1,68.74c-50.12,54.95,0.23,179.88,143.5,228.46v-95.77C512.07,385.24,451.64,331.76,439.9,299.66z',
        'M480.96,197.13c1.34-3.62,3.86-6.18,6.38-8.42c3.83-3.42,8.07-6.51,12.68-6.78c2.02-0.12,4.55,0.95,4.77,3.62',
        'c0.09,1.08-0.24,2.14-0.65,3.08c-1.21,2.82-3.07,5.03-4.93,7.12c-3.98,4.47-8.26,8.72-13.15,11.28c-2.37,1.24-4.04,2.21-5.3-1.37',
        'C479.82,203,480,199.73,480.96,197.13z M471.39,212.05c0.83-1.68,5.76-6.24,6.96-3c1.09,2.96-5.01,5.21-6.37,5.22',
        'c-0.21,0-0.42-0.01-0.6-0.15C470.87,213.72,471.07,212.7,471.39,212.05z"/> ',
        '<linearGradient id="SKY4_LG3" gradientUnits="userSpaceOnUse" x1="-53.8455" y1="58.5552" x2="169.0079" y2="58.5552"> ',
        '<stop  offset="5.952380e-03" style="stop-color:#0B0A16"/> ',
        '<stop  offset="1" style="stop-color:#1D6EAF"/> ',
        '</linearGradient> ',
        '<path style="opacity:0.15;fill:url(#SKY4_LG3);" d="M90.24,0',
        'c0,0-0.2,82.43,60.2,115.48c12.39,6.78,24.68-9.11,15.2-19.58C144.4,72.42,123,38.31,128.86,0H90.24z"/> ',
        '<linearGradient id="SKY4_LG4" gradientUnits="userSpaceOnUse" x1="8.8616" y1="670.2307" x2="302.4382" y2="670.2307"> ',
        '<stop  offset="5.952380e-03" style="stop-color:#0B0A16"/> ',
        '<stop  offset="1" style="stop-color:#1D6EAF"/> ',
        '</linearGradient> ',
        '<path style="opacity:0.15;fill:url(#SKY4_LG4);" d="M76.98,662.58',
        'c-16.96-10.97-18.95,31.92-29.93,47.89c-4.75,6.9-18.26-43.82-2.99-95.77c28.44-96.77,70.03-138.35,99.08-168.59',
        'c14.39-14.98,15.17-53.78-29.38-36.91C77.11,423.07,12.62,496.32,8.99,668.41c-4.3,203.63,104.77,267.03,104.77,267.03h80.94',
        'h72.49h35.25c-68.59-6.32-177.58-47.81-212.2-147.15C71.45,734.35,83.71,666.94,76.98,662.58z"/> ',
        '<linearGradient id="SKY4_LG5" gradientUnits="userSpaceOnUse" x1="444.4587" y1="192.6205" x2="566.9291" y2="192.6205"> ',
        '<stop  offset="5.952380e-03" style="stop-color:#0B0A16"/> ',
        '<stop  offset="1" style="stop-color:#1D6EAF"/> ',
        '</linearGradient> ',
        '<path style="opacity:0.15;fill:url(#SKY4_LG5);" d="M566.93,385.24',
        'c0,0-160.53-43.07-102.47-129.69s46.05-76.21,8.58-123.71C431.2,78.83,428.98,39.75,509.37,0h34.5c0,0-69.07,22.48-69.83,69.99',
        'c-1,61.85,83.8,52.87,63.97,141.27c-13.41,59.76-58.74,89.82,28.93,89.82"/> '
      )
    );
  }

  function getPath2() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<linearGradient id="SKY4_LG6" gradientUnits="userSpaceOnUse" x1="523.2549" y1="1314.5845" x2="841.3302" y2="1314.5845" gradientTransform="matrix(-1 0 0 1 841.3302 -1227.0485)"> ',
        '<stop  offset="5.952380e-03" style="stop-color:#0B0A16"/> ',
        '<stop  offset="1" style="stop-color:#1D6EAF"/> ',
        '</linearGradient> ',
        '<path style="opacity:0.2;fill:url(#SKY4_LG6);" d="M0,0v58.73',
        'c3.09,1.23,6.33,2.4,9.71,3.51c23.97,7.89,54.91,12.88,87.67,16.57c5.97,0.67,11.99,1.3,18.05,1.9',
        'c9.49,0.94,19.06,1.79,28.58,2.59c8.36,0.72,16.69,1.39,24.9,2.05c6.45,0.52,13.03,1,19.53,1.48c5.44,0.41,10.82,0.81,16,1.26',
        'c6.29,0.53,12.3,1.11,17.79,1.79c0.01,0,0.01,0,0.01,0c16.31,2,28.08,4.86,29.17,9.87c0.92,4.24-6.22,7.95-14.76,11.91',
        'c-2.98,1.38-6.13,2.8-9.16,4.28c-8.52,4.16-16.14,8.85-16.58,14.82c-0.48,6.43,7.41,14.07,30.66,23.11c0,0.01,0,0.01,0.01,0',
        'c13.86,5.39,33.18,11.28,59.45,17.69c0.01,0,0.01,0,0.02,0c0.72,0.18,1.45,0.35,2.18,0.54c1.83,0.44,3.68,0.88,5.57,1.32',
        'c0.98,0.24,1.97,0.47,2.97,0.7c0.24,0.05,0.49,0.11,0.73,0.17c0.34,0.07,0.68,0.16,1.02,0.24h0.03c0.17,0.04,0.34,0.08,0.51,0.12',
        'c0.05,0.01,0.1,0.03,0.15,0.04c0.56,0.13,1.13,0.26,1.7,0.39c-0.51-0.24-1.01-0.47-1.51-0.69c-0.09-0.04-0.18-0.09-0.27-0.13',
        'c-0.2-0.1-0.4-0.18-0.6-0.28c0,0-0.01,0-0.01-0.01c-0.15-0.07-0.29-0.13-0.44-0.21c-0.3-0.13-0.59-0.27-0.89-0.41',
        'c-1.3-0.61-2.57-1.21-3.81-1.79c-7.46-3.56-13.69-6.74-18.86-9.59c-7.45-4.11-12.72-7.52-16.34-10.37',
        'c-0.01-0.01-0.01-0.01-0.01-0.01c-1.66-1.29-2.96-2.47-3.98-3.54c-0.95-1-1.65-1.9-2.14-2.72c-1.16-1.92-1.2-3.41-0.64-4.59',
        'c0.77-1.64,2.68-2.63,5.34-3.29c9.67-2.44,29.23-0.58,39.66-10c11.99-10.83,6.5-31.72-6.14-46.98c-1.82-2.19-3.78-4.27-5.86-6.18',
        'c-2.51-2.31-5.23-4.42-8.1-6.33h-0.01c-35.26-23.47-94.67-18.47-96.89-12.5c-1.02,2.74,9.76,6.52,18.99,10.15h0.01',
        'c7.12,2.8,13.33,5.5,12.5,7.58c-1.23,3.09-18.31,5.33-37.94,2.89c-5.79-0.71-11.8-1.83-17.7-3.46c-0.46-0.13-0.93-0.26-1.39-0.4',
        'c-7.73-2.24-15.21-5.37-21.66-9.62c-0.79-0.51-1.56-1.04-2.31-1.59c-0.78-0.57-1.54-1.16-2.28-1.76',
        'c-5.83-4.75-10.32-10.43-13.38-16.77c-1.84-3.77-3.17-7.77-3.97-11.93c-1.5-7.65-1.23-15.85,0.89-24.21h0.01',
        'c0.53-2.1,1.18-4.21,1.95-6.32H0z"/> ',
        '<linearGradient id="SKY4_LG7" gradientUnits="userSpaceOnUse" x1="200.4768" y1="-123.5029" x2="340.0362" y2="272.5439"> ',
        '<stop  offset="0" style="stop-color:#FFFFFF"/> ',
        '<stop  offset="0.994" style="stop-color:#0B0A16"/> ',
        '</linearGradient> ',
        '<path style="opacity:0.5;fill:url(#SKY4_LG7);" d="M566.93,136.15',
        'c-0.12-0.09-0.24-0.17-0.35-0.25c-0.02-0.02-0.05-0.04-0.07-0.06c-0.05-0.03-0.08-0.05-0.12-0.07c-0.03-0.03-0.08-0.07-0.14-0.1',
        'c-1.01-0.72-2.01-1.42-3.02-2.1c-0.05-0.03-0.1-0.07-0.15-0.1c-0.34-0.22-0.68-0.45-1-0.67c-0.42-0.27-0.84-0.54-1.27-0.8',
        'c0-0.01-0.02-0.01-0.02-0.01c-3.78-2.42-7.54-4.54-11.3-6.39c-11.32-5.61-22.37-8.82-32.31-10.64c-0.4-0.07-0.79-0.14-1.18-0.21',
        'c-3.04-0.53-5.97-0.93-8.76-1.23c-2.36-0.26-4.64-0.44-6.8-0.57c-25.85-1.57-45.3,3.83-67.42,9.92',
        'c-13.8,3.8-28.63,7.88-46.72,10.7h-0.02c-9.4,1.47-19.69,2.6-31.16,3.17c-2.94,0.15-5.96,0.26-9.06,0.33',
        'c-19.91,0.46-29.8-1.07-43.33-3.39c-10.29-1.76-22.68-3.97-43.19-6.11c-8.45-0.88-18.27-1.75-29.9-2.57',
        'c-31.52-2.22-59.11-2.87-81.28-3.25c-33.36-0.59-54.4-0.59-57.91-4.5c-5.06-5.62,33.83-10.65,30.37-17.23',
        'c-0.93-1.75-4.56-3.05-10.31-4.08c-1.67-0.3-3.53-0.57-5.53-0.83C83.34,92.36,42.64,91.75,0,87.85V0h169.07',
        'c0.02,0.01,0.02,0.01,0.02,0.01h0.02c11,7.91,19.2,16.17,23.76,23.99c4.02,6.88,5.21,13.43,3.02,19.12',
        'c-2.33,6.11-8.55,11.21-19.37,14.67c-24.8,7.93-61.52,3.28-65.8,8.61c-2.67,3.31,8.49,8.8,26.84,13.63',
        'c4.4,1.17,9.23,2.29,14.38,3.34c21.6,4.4,48.91,7.46,75.19,6.3c33.22-1.47,43.48-8.75,70.87-6.89c5.43,0.37,10.71,1.04,15.69,1.94',
        'c15.17,2.71,27.57,7.46,33.07,11.88c3.17,2.54,4.05,4.99,1.86,6.87c-5.1,4.37-26.36,5.34-42.3,5.81',
        'c-10.34,0.3-18.43,0.4-18.44,1.09c0,0.46,3.58,1.18,9.95,1.92c20.2,2.37,68.64,5.05,121.65,0.66',
        'c57.13-4.72,74.88-13.58,101.24-10.34c9.92,1.22,20.96,4.16,30.19,11.12c3.91,2.97,7.53,6.68,10.56,11.3',
        'c1.35,2.06,2.6,4.3,3.71,6.74c0.17,0.4,0.35,0.82,0.52,1.23v0.01c0.08,0.16,0.15,0.32,0.2,0.48c0.03,0.06,0.07,0.13,0.08,0.19',
        'c0.08,0.19,0.15,0.38,0.24,0.57c0.17,0.44,0.34,0.89,0.51,1.34c0.02,0.03,0.03,0.06,0.03,0.09c0.03,0.06,0.05,0.11,0.07,0.17',
        'c0,0.02,0.02,0.03,0.02,0.05C566.86,135.96,566.9,136.06,566.93,136.15z"/> ',
        '<linearGradient id="SKY4_LG8" gradientUnits="userSpaceOnUse" x1="7.7404" y1="386.3394" x2="397.5282" y2="386.3394" gradientTransform="matrix(-0.6921 0.7218 0.7218 0.6921 210.9596 38.0781)"> ',
        '<stop  offset="5.952380e-03" style="stop-color:#0B0A16"/> ',
        '<stop  offset="1" style="stop-color:#1D6EAF"/> ',
        '</linearGradient> ',
        '<path style="opacity:0.15;fill:url(#SKY4_LG8);" d="M567.48,397.86',
        'c0-35.56-70.94,0.91-105.33,11c-19.8,5.81-39.33,13.27-58.44,21.54c-0.82,0.34-1.63,0.7-2.45,1.07',
        'c-23.35,10.19-46.12,21.53-68.09,32.49c-6.17,3.08-12.37,6.3-18.52,9.47c-4.43,2.3-8.84,4.59-13.21,6.79',
        'c-1.25,0.62-2.47,1.24-3.71,1.85c-2.89,1.43-5.75,2.82-8.58,4.15c-1.46,0.67-2.89,1.33-4.32,1.98',
        'c-22.75,10.17-43.28,15.62-58.1,6.35c-4.93-3.09-8.12-7.09-10.31-11.76c-2.84-6.01-3.99-13.08-5.08-20.61',
        'c-0.61-4.44-1.22-9.04-2.13-13.66c-2.43-12.46-6.99-25.07-20.08-35.3c-16.39-12.79-45.38-21.24-95.95-19.28',
        'c-1.71,2.6-2.88,5.44-3.04,8.52c-0.32,6.4,3.93,12.68,9.27,18.17c1.52,1.56,3.12,3.07,4.79,4.54c6.27,2.76,10.19,5.52,12.65,8.12',
        'c1.43,1.52,2.34,2.96,2.85,4.36c0.59,0.54,0.67,1.12,0.42,1.58c0.1,0.63,0.12,1.25,0.07,1.86c-0.85,11.41-25.18,21.17-11.51,45.71',
        'c10.94,19.62,42.61,42.28,77.22,60.14c19.73,10.17,40.42,18.77,58.78,24.35c1.66,0.51,3.3,0.98,4.93,1.44',
        'c35.52,9.99,64.29,9.24,85.91,3.6c1.04-0.28,2.08-0.54,3.08-0.84c0,0,0,0,0.01-0.01c35.88-10.44,50.77-34.39,42.77-42.23',
        'c-4.07-3.98-14.94-4.69-26.98-4.82c-0.03-0.01-0.04,0-0.04,0c-16.32-0.17-34.78,0.73-41.46-3.96l-0.02-0.01',
        'c-0.38-0.26-0.71-0.53-1.01-0.83c-0.28-0.28-0.53-0.59-0.76-0.91c-4.7-6.96,6.12-22.28,29.89-30.72c7.98-2.84,17.42-4.9,28.24-5.6',
        'c11.3-0.75,24.1-0.01,38.29,2.88c1.41,0.28,2.82,0.59,4.26,0.92c5.34,1.23,10.79,2.74,16.34,4.51',
        'c11.26,3.61,22.94,8.34,34.77,14.03c3.26,1.56,6.55,3.21,9.84,4.93c8.06,4.2,16.15,8.83,24.23,13.83l0.03,0.01',
        'c11.13,6.91,59.13,14.53,69.96,22.77v-97.97C566.93,452.33,567.48,452.33,567.48,397.86z"/> ',
        '<path style="opacity:0.3;fill:#31398E;" d="M398.24,588.29c-15.03-3.64-20.42-16.51-29.81-19.7c-5.21-1.78-10.5-2.24-16.14-0.89',
        'c-20.94,5.01-21.76,28.77-40.39,32.04c-10.22,1.79-17.14-4.08-26.43-14.19c-10.31-11.26-23.54-27.76-47.42-44.76',
        'c-3.03-2.15-5.95-4.11-8.78-5.91c-9.58-6.12-18.01-10.32-25.44-13.5c-4.76-2.04-9.13-3.64-13.11-5.06',
        'c-1.27-0.45-2.47-0.87-3.67-1.28c-3.84-1.34-7.32-2.57-10.47-3.9c-7.19-3.06-12.68-6.73-16.95-14.01',
        'c-4.74-8.07-5.48-16.15-3.98-24.09c5.6-29.6,42.38-57.15,19.77-74.48c-1.91-1.47-4.36-2.93-7.5-4.29',
        'c-3.58-1.53-8.09-2.93-13.84-4.02c-6.63-1.27-28.11-7.63-29.53-10.27c44.54-8.95,64.52-6.4,74.36-1.62',
        'c19.25,9.37-0.71,26.87,6,59.07c5.24,25.21,24.31,43.78,38.79,53.34c8.12,5.36,14.82,7.9,16.86,7.21c2.91-1-3.78-8.73-6.91-17.32',
        'c-2.43-6.67-2.7-13.87,5.36-18.83c3.32-2.04,7.99-3.65,13.43-4.81c13.05-2.75,30.68-2.86,45.43,0.04',
        'c8.56,1.67,16.13,4.35,21.31,8.1c15.51,11.26-2.48,23.57,5.23,41.01c3.86,8.75,12.94,15.98,24.43,21.59',
        'c9.13,4.48,19.8,7.93,30.55,10.33c18.37,4.12,37.06,5.15,48.91,2.9c3.19-0.6,5.88-1.43,7.95-2.51c5.12-2.66,4.94-6.03,3.27-10.16',
        'c-3.03-7.44-10.92-17.35-1.52-30.17c6.71-9.15,20.74-17.72,39.49-25.32c19.55-7.92,44.23-14.78,71.15-20.16',
        'c5.09-1.02-6.97-1.98-1.75-2.89v96.78C566.93,546.58,560.4,627.54,398.24,588.29z"/> '
      )
    );
  }

}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library Sky4Path3_4Descriptor {

  function getPath3() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<linearGradient id="SKY4_LG9" gradientUnits="userSpaceOnUse" x1="50.3526" y1="521.6964" x2="50.3526" y2="0.0606">',
        '<stop  offset="0" style="stop-color:#FFFFFF"/>',
        '<stop  offset="0.994" style="stop-color:#0B0A16"/>',
        '</linearGradient>',
        '<path style="opacity:0.5;fill:url(#SKY4_LG9);" d="M94.48,507.98',
        'c17.17-25.09-5.37-64.05-17.19-49.01C65.47,474,36.48,486.89,22.52,477.23C14.96,472,6.77,465.81,0,457.32v28.29',
        'C34.58,525.49,78.48,531.34,94.48,507.98z"/>',
        '<linearGradient id="SKY4_LG10" gradientUnits="userSpaceOnUse" x1="228.4631" y1="521.733" x2="228.4631" y2="5.727501e-05">',
        '<stop  offset="0" style="stop-color:#FFFFFF"/>',
        '<stop  offset="0.994" style="stop-color:#0B0A16"/>',
        '</linearGradient>',
        '<path style="opacity:0.5;fill:url(#SKY4_LG10);" d="M187.9,0',
        'c0,0,4,4.09,9.34,11.4c0.95,1.3,7.33,11.01,8.77,13.53c15.82,27.57,31.51,75.43-2,130.12c-22.53,36.78-55.5,62.73-97.47,82.08',
        'c-0.16,0.23-0.41,0.4-0.72,0.4c-0.04,0-0.07-0.02-0.1-0.02C75.07,251.54,39.64,262.07,0,270.74v66.83',
        'c2.94-4.9,12.91-16.73,23.79-23.9c15.93-10.48,43.58-26.37,69.61-30.22c27.91-4.12,42.58-3.83,58.95-4.44',
        'c7.23-0.27,10.34-8.66-8.93-9.23c-5-0.16-33.31-1.59-35.17-6.93c-2.38-6.9,23.11-13.86,27.23-15.28',
        'c23.06-7.95,51.16-45.22,52.89-46.95c84.13-83.75,125.37-45.17,152.44-103.93C376.98,18.22,456.93,0,456.93,0H187.9z"/>',
        '<linearGradient id="SKY4_LG11" gradientUnits="userSpaceOnUse" x1="330.6834" y1="123.5238" x2="330.6834" y2="76.5895">',
        '<stop  offset="0" style="stop-color:#FFFFFF"/>',
        '<stop  offset="0.994" style="stop-color:#0B0A16"/>',
        '</linearGradient>',
        '<path style="opacity:0.5;fill:url(#SKY4_LG11);" d="M324.34,85.75',
        'c-0.29,6.95,0.19,20.71,6.55,21.2c3.1,0.24,4.97-3.34,5.61-6.39c0.89-4.24,1.05-8.63,0.45-12.92c-0.52-3.83-1.84-7.86-5.03-10.02',
        'c-1.15-0.78-2.59-1.28-3.92-0.89c-2.38,0.68-3.2,3.58-3.46,6.04c-0.05,0.45-0.09,1.04-0.14,1.75c-0.31,0.22-0.43,0.63-0.26,0.98',
        'C324.19,85.59,324.26,85.68,324.34,85.75z"/>',
        '<linearGradient id="SKY4_LG12" gradientUnits="userSpaceOnUse" x1="14.6983" y1="656.2689" x2="977.3593" y2="656.2689">',
        '<stop  offset="5.952380e-03" style="stop-color:#0B0A16"/>',
        '<stop  offset="1" style="stop-color:#1D6EAF"/>',
        '</linearGradient>',
        '<path style="opacity:0.2;fill:url(#SKY4_LG12);" d="M489.82,377.1',
        'c1.69,3.94,3.24,7.95,4.68,12c1.27,0.46,2.56,1.18,3.76,2.1c6.74,5.12,9.55,15.29,7.95,23.32c-0.57,2.89-1.45,4.66-2.48,5.6',
        'c3.09,12.09,5.62,23.37,8.18,32.48c3.03,10.8,4.39,20.48,4.67,29.02c2.24,17.13-1.01,33.08-10.89,45.3l0,0l0,0',
        'c-2.43,3-4.87,6.37-8.49,8.3c-122.73,65.4-93.85,400.04-108.26,400.22h132.42c0,0-46.03-303.78,45.57-402.4v-21.3',
        'c-0.98,3.8-2.33,7.55-4.99,10.41c-4.82,5.17-13.18,6.01-19.64,3.13c-6.46-2.89-11.14-8.87-13.93-15.36',
        'c-2.81-6.5-3.94-13.57-5.06-20.56c-3.24-20.33-6.31-40.7-9.73-61c-1.97-11.63-5.88-34.12,14.21-30',
        'c16.25,3.34,30.64,14.82,37.49,29.94c0.61,1.34,1.15,2.71,1.65,4.1v-34.62C556.21,383.75,515.95,383.08,489.82,377.1z"/>',
        '<linearGradient id="SKY4_LG13" gradientUnits="userSpaceOnUse" x1="51.4405" y1="312.1204" x2="950.0517" y2="312.1204">',
        '<stop  offset="5.952380e-03" style="stop-color:#0B0A16"/>',
        '<stop  offset="1" style="stop-color:#1D6EAF"/>',
        '</linearGradient>',
        '<path style="opacity:0.2;fill:url(#SKY4_LG13);" d="M505.83,280.55',
        'c20.74,1.37,41.31,5.28,61.1,11.63v-10.53c-4.2-1.32-8.55-2.47-13.03-3.47c-0.07,0.05-0.14,0.08-0.23,0.09',
        'c-0.18,0.01-0.34-0.09-0.43-0.23c-131.93-10.35-157.55,7.13-154.11,6.39c13.66-2.95,28.67-5.88,41.14-5.22',
        'c9.64,0.51,16.08,6,24.36,10.98c8.7,5.23,15.8,16.24,11.12,25.25c-3.09,5.98-10.07,8.63-16.49,10.67',
        'c-2.87,0.91-5.75,1.79-8.64,2.65c9.34,5.07,17.08,12.26,23.56,20.74c11.57-7.79,31.98-12.48,32.47-19.01',
        'c0.68-9.16,28.86-1.2,60.28-4.74v-11.52c-15.58,2.8-31.41,4.13-47.23,3.87c-8.46-0.14-17.34-0.85-24.41-5.48',
        'c-7.47-4.89-14.55-16.47-14.71-25.6C481.01,281.65,497.24,279.99,505.83,280.55z"/>',
        '<linearGradient id="SKY4_LG14" gradientUnits="userSpaceOnUse" x1="14.6984" y1="368.8175" x2="903.7394" y2="368.8175">',
        '<stop  offset="5.952380e-03" style="stop-color:#0B0A16"/>',
        '<stop  offset="1" style="stop-color:#1D6EAF"/>',
        '</linearGradient>',
        '<path style="opacity:0.2;fill:url(#SKY4_LG14);" d="M162.5,291.04',
        'c-30.04-6.77-60.34-9.84-87.35,6.02c-46.18,27.09-12.89,53.45-17.19,78.15c-4.29,24.7-47.26,12.88-42.96,40.81',
        'c4.22,27.48,46.97,35.85,48.3,36.09c-13.96-6.9-32.14-56.52,58.01-96.23c1.6-0.71,3.23-1.38,4.89-2.04',
        'c10.19-3.96-32.6-6.39-52.18-1.74c-1.41,0.33-2.9,0.27-4.28-0.11c-4.99-1.42-6.39-7.75-6.56-12.94',
        'c-0.23-6.67,0.1-13.56,2.85-19.65c4.21-9.38,13.67-15.62,23.62-18.18c9.95-2.58,20.43-1.97,30.65-0.85',
        'c16.99,1.69,36,13.33,47.84,5.35C173.81,301.89,167.69,292.21,162.5,291.04z',
        'M511.91,452.6c-2.56-9.11-5.08-20.39-8.18-32.48c-3.54,3.21-9.02-3.3-11.42-8.37c-2.32-4.89-6.65-12.57-5.72-18.24',
        'c0.8-4.87,4.27-5.74,7.91-4.41c-1.44-4.05-2.99-8.06-4.68-12c-10.88-2.49-19.32-5.89-22.15-11.57',
        'c-3.38-6.76,0.29-11.86,6.52-16.05c-6.48-8.49-14.21-15.67-23.56-20.74c-14.26,4.21-28.77,7.59-43.56,8.89',
        'c-10.32,0.91-20.66,0.8-30.99,0.11c-2.9,4.86,50.21,35.83,69.58,47.14c39.77,23.19,66.43,62.34,70.93,96.75',
        'C516.29,473.08,514.94,463.4,511.91,452.6z"/>'
      )
    );
  }

  function getPath4() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
          '<linearGradient id="SKY4_LG15" gradientUnits="userSpaceOnUse" x1="659.2993" y1="799.0061" x2="659.2993" y2="672.641" ',
          'gradientTransform="matrix(-0.9985 -0.0554 0.0554 -0.9985 812.2495 1155.7041)"> ',
          '<stop  offset="5.952380e-03" style="stop-color:#0B0A16"/> ',
          '<stop  offset="1" style="stop-color:#1D6EAF"/> ',
          '</linearGradient> ',
          '<path style="opacity:0.2;fill-rule:evenodd;clip-rule:evenodd;fill:url(#SKY4_LG15);" d="',
          'M238.93,409.27c0,0-22.06-16.24-28.16-22.08c-6.09-5.84-26.98-9.45-31.01-11.2c-4.03-1.75-13.14-16.01-13.14-16.01',
          's-5.12-10.46-6.08-17.8c-0.96-7.35-18.76-16.59-18.76-16.59l-16.91-8.28c0,0,25.16,31.66,27.75,39.14s-1.45,13.98,6.11,18.38',
          'c7.56,4.39,26.12,11.84,27.68,19.27c1.56,7.42,30.92,34.73,40.42,39.84c9.5,5.11,37.81,17.69,37.81,17.69',
          'S247.55,419.84,238.93,409.27z"/> ',
          '<linearGradient id="SKY4_LG16" gradientUnits="userSpaceOnUse" x1="625.9933" y1="712.609" x2="625.9933" y2="498.6406" ',
          'gradientTransform="matrix(-0.9985 -0.0554 0.0554 -0.9985 812.2495 1155.7041)"> ',
          '<stop  offset="5.952380e-03" style="stop-color:#0B0A16"/> ',
          '<stop  offset="1" style="stop-color:#1D6EAF"/> ',
          '</linearGradient> ',
          '<path style="opacity:0.15;fill-rule:evenodd;clip-rule:evenodd;fill:url(#SKY4_LG16);" d="',
          'M237.47,564.94c0,0-28.9-28.93-46.39-40.53c-17.49-11.6-27.65-7.61-27.65-7.61s-15.7-5.54-25.05-13.59',
          'c-9.35-8.05-7.08-21.59-12.71-29.49c-5.63-7.9-30.9-3.99-30.9-3.99l-35.12-43.41l-23.29-27.39c0,0,24.76,36.29,28.83,44.11',
          'c4.07,7.82,32.65,53.43,38.29,61.33c5.63,7.9,14.04,6.85,19.51,17.78c5.47,10.93,11.6,23.42,20.94,33.04',
          'c9.33,9.63,28.99,24.38,39.64,31.04c10.65,6.66,27.71,13.68,27.71,13.68l29.89,8.49l164.07,25.29c0,0-63.9-49.33-93.47-62.36',
          'C300.57,566.41,237.47,564.94,237.47,564.94z"/> ',
          '<linearGradient id="SKY4_LG17" gradientUnits="userSpaceOnUse" x1="702.6287" y1="588.2362" x2="702.6287" y2="506.131" ',
          'gradientTransform="matrix(-0.9985 -0.0554 0.0554 -0.9985 812.2495 1155.7041)">',
          '<stop  offset="5.952380e-03" style="stop-color:#0B0A16"/> ',
          '<stop  offset="1" style="stop-color:#1D6EAF"/> ',
          '</linearGradient> ',
          '<path style="opacity:0.2;fill-rule:evenodd;clip-rule:evenodd;fill:url(#SKY4_LG17);" d="',
          'M198.06,614.7c0,0-15.16-24.37-26.57-31.84c-11.41-7.46-26.15-11.19-31.35-18.31c-5.19-7.12-25.9-23.89-25.9-23.89L84,526.13',
          'c0,0,40.18,37.98,44.34,46.52c4.16,8.54,16.18,16.04,16.18,16.04L198.06,614.7z"/> ',
          '<path style="opacity:0.3;fill:#31398E;" d="M199.84,0c0,0,42.78,31.93,62.51,40.34c0,0,24.67-1.84,28.01,0c3.34,1.84,17.99,10.94,19.5,14.47',
          'c1.52,3.54,2.53,11.12,5.56,14.65c3.03,3.54,30.32,16.67,39.92,18.19s32.84,6.06,37.39,9.09c4.55,3.03,3.03,10.11,5.56,13.64',
          'c2.53,3.54,17.68,9.6,23.75,13.64c6.06,4.04,25.01,3.03,30.69,5.56c5.69,2.53,17.81,10.11,17.81,10.11l4.54,4.04',
          'c0,0-2.53,8.59,0,11.12s13.14,4.55,13.14,4.55s-8.08-8.08-8.08-13.14c0-5.05-5.06-9.09-5.06-9.09s-25.26-11.62-28.79-14.65',
          'c-3.54-3.03-35.37-29.31-37.89-33.85c-2.53-4.55-8.08-17.18-11.12-20.72c-3.03-3.54-31.83-11.12-38.91-14.15',
          's-16.18-12.13-20.47-19.71c-4.29-7.58-12.37-28.56-14.9-31.33S314.92,0,314.92,0H199.84z"/> ',
          '<path style="opacity:0.3;fill:#31398E;" d="M383.63,156.37c0,0,22.93,14.99,29.34,20.48c6.41,5.49,27.46,7.94,31.59,9.46',
          'c4.12,1.53,14.01,15.26,14.01,15.26s5.7,10.16,7.06,17.44c1.37,7.28,19.65,15.52,19.65,15.52l17.34,7.33',
          'c0,0-26.88-30.22-29.88-37.54c-3-7.33,0.68-14.04-7.12-18.01c-7.79-3.97-26.74-10.38-28.71-17.7',
          'c-1.97-7.33-32.8-32.96-42.57-37.54c-9.77-4.58-38.73-15.57-38.73-15.57S374.44,146.29,383.63,156.37z"/> ',
          '<linearGradient id="SKY4_LG18" gradientUnits="userSpaceOnUse" x1="204.6214" y1="236.9106" x2="204.6214" y2="0"> ',
          '<stop  offset="0" style="stop-color:#FFFFFF"/> ',
          '<stop  offset="0.994" style="stop-color:#0B0A16"/> ',
          '</linearGradient> ',
          '<path style="opacity:0.5;fill-rule:evenodd;clip-rule:evenodd;fill:url(#SKY4_LG18);" d="',
          'M0,134.61c0,0,35.52,25.69,42.65,31.87c7.13,6.18,26.28,5.71,32.62,12.2c6.34,6.49,17.71,9.33,25.67,18.14',
          'c7.96,8.81,34.32,15.3,43.31,25.7c8.99,10.4,34.41,21.77,29.66,8.12C169.15,217,171.85,200,171.85,200s6.11-1.34,0-12.63',
          'c-6.11-11.29-1.01-18.49-8.67-27.97c-7.67-9.47-11.33-26.53-6.09-34.48s17.46-31.32,14.76-45.22',
          'c-2.7-13.9,21.02-24.13,21.02-24.13s35.87,3.41,40.18,9.09c4.31,5.68,35.88,15.04,35.88,15.04s25.22,1.39,28.66,0',
          'c3.44-1.39,14.25,7.7,23.05,15.66c8.81,7.96,10.52,3.11,22.75,11.63c12.23,8.52,14.57,21.38,21.58,27.63',
          'c0,0-7.85-13.73-10.32-27.63c0,0,12.56,1.38,21.66,3.66c9.09,2.27,13.45,1.77,19.74,6.57c6.28,4.8,13.2,7.83,13.2,7.83',
          's-10.64-9.6-13.2-14.91c-2.56-5.31-4.58-10.61-7.86-12.63c-3.28-2.02-40.44-11.4-49.96-15.8c-9.52-4.41-17.58-18.93-17.58-18.93',
          's-21.79-30.61-35.53-31.07c-13.74-0.46-37.84-7.08-46.61-13.26C229.72,12.25,211.21,0,211.21,0H41.14C18.42,0,0,18.42,0,41.14',
          'V134.61z"/> '
      )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import "../../../utils/PlanetRandom.sol";
import "../../../utils/SVGUtils.sol";
import "./Sky1Path1_2Descriptor.sol";
import "./Sky1Path3_4Descriptor.sol";


library Sky1PathDescriptor {

  function getSVG(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public pure returns (string memory svg, uint offsetRandom) {
    uint index = 0;

    // select random path layer
    uint randomPathLayer = PlanetRandom.calcRandom(0, 4, blockhashInit_, offsetRandom_);
    offsetRandom_ = offsetRandom_ + 1124;

    if (randomPathLayer == 0) {
      svg = Sky1Path1_2Descriptor.getPath1();
    } else if (randomPathLayer == 1) {
      svg = Sky1Path1_2Descriptor.getPath2();
    } else if (randomPathLayer == 2) {
      svg = Sky1Path3_4Descriptor.getPath3();
    } else {
      svg = Sky1Path3_4Descriptor.getPath4();
    }

    offsetRandom = offsetRandom_;
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library Sky1Path1_2Descriptor {

  function getPath1() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<path style="fill:#5D5DC2;opacity:0.1;" d="M558.34,134.84c-20.2-28.81-47.43-48.91-73.55-62.8c-2.18-1.16-4.36-2.28-6.52-3.35',
        'c-7.37-3.66-14.59-6.84-21.49-9.58h-0.01c-8.87-3.53-17.2-6.34-24.56-8.56h-0.03c-73.9,0-147.2,13.08-216.62,38.4',
        'c-14.96,5.46-31.43,11.22-49.79,17.2c-22.63,7.38-44.21,13.83-64.54,19.46c-11.07,3.07-21.77,5.9-32.06,8.5',
        'c-0.58,0.15-1.14,0.29-1.71,0.43c-0.01,0.01-0.01,0.01-0.02,0c-0.01,0.01-0.01,0.01-0.02,0c-25.17,6.34-47.8,11.35-67.42,15.31',
        'V288.7c0.89-1.28,1.79-2.56,2.69-3.83c15.03-21.26,30.74-41,46.95-59.12c0,0,0,0,0.01-0.01c2.49-2.77,4.97-5.5,7.47-8.2',
        'c7.05-7.59,14.19-14.88,21.4-21.86c28.63-27.71,58.44-50.54,88.57-68.03c0.44-0.26,0.88-0.51,1.32-0.76',
        'c18.2-10.46,36.5-18.98,54.74-25.45c0.01-0.01,0.02-0.01,0.03-0.01C270.37,84.7,317.06,81.68,360,94.1c0.02,0,0.03,0,0.03,0.01',
        'c4.6,1.33,9.18,2.84,13.7,4.54c3.64,1.36,7.36,2.89,11.18,4.58c0.01,0,0.01,0.01,0.01,0.01c7.46,3.29,15.21,7.22,23.06,11.74',
        'c6.18,3.55,12.43,7.47,18.64,11.75c2.38,1.63,4.76,3.32,7.12,5.07c1.56,1.14,3.12,2.31,4.67,3.51',
        'c9.58,7.35,18.95,15.55,27.72,24.54c17.7,18.09,33.04,39.36,43.05,63.34c0.47,1.11,0.92,2.24,1.36,3.37',
        'c6.71,17.08,10.72,35.49,10.97,55.08c0.01,0.8,0.02,1.6,0.01,2.39c-0.01,2.92-0.1,5.82-0.27,8.68c-0.44,7.4-1.43,14.6-2.88,21.6',
        'c-4.48,21.58-13.47,41.29-25.21,58.99c-26.47,39.98-66.94,69.69-100.98,87.46c-0.01,0.01-0.03,0.01-0.04,0.02',
        'c-7.39,3.85-14.47,7.14-21.04,9.85C298.52,500.55,206.51,493.3,150.1,457c-0.01,0-0.01,0-0.01,0c-2.43-1.56-4.8-3.18-7.11-4.86',
        'c-1.16-0.84-2.3-1.7-3.42-2.58c-10.77-8.35-19.83-17.96-26.67-28.74c-0.68-1.06-1.33-2.14-1.96-3.22',
        'c-4-6.88-7.12-14.21-9.24-21.97c-9.6-35.21,3.33-72.51,19.82-102.36c1.87-3.38,3.78-6.67,5.72-9.84',
        'c2.28-3.77,4.6-7.38,6.91-10.82c7.28-10.91,14.37-20.03,19.78-26.62c1.63-1.98,3.1-3.74,4.39-5.24c1.44-1.69,2.64-3.07,3.55-4.11',
        'c5.35-6.14,11.16-12.16,17.35-17.95c32.71-30.61,76.25-55.01,121.41-59.17c21.72-1.99,43.83,0.69,65.28,9.62',
        'c1.41,0.58,3.88,1.62,7.12,3.13c0,0,0,0,0.01,0c2.65,1.23,5.8,2.78,9.28,4.66c2.64,1.42,5.47,3.04,8.41,4.86h0.01',
        'c21.04,12.93,48,35.92,53.65,71.35c1.6,10.08,1.33,20.22-0.49,30.2c-0.62,3.38-1.41,6.74-2.36,10.07',
        'c-0.55,1.88-1.14,3.76-1.79,5.62c-3.5,10.13-8.48,19.97-14.6,29.26c-1.81,2.77-3.74,5.5-5.76,8.17',
        'c-4.51,5.98-9.47,11.68-14.77,17.03c-17.86,18.02-39.59,32.02-60.95,39.14c-17.05,5.69-34.75,7.28-51.86,5.95',
        'c-20.64-1.6-40.42-7.46-57.13-15.51c-4.6-2.22-8.97-4.61-13.06-7.11c-2.89-1.77-5.64-3.6-8.23-5.49',
        'c-16.61-12.02-26.9-25.94-26.67-37.83c0.02-1.11,0.15-2.22,0.35-3.32c-5.35-10.88-8.89-22.82-10.23-35.41',
        'c-21.2,17.67-36.55,38.93-34.59,59.73c1.83,19.54,18.52,36.93,42.58,49.88c2.21,1.19,4.48,2.34,6.81,3.45',
        'c0.63,0.31,1.26,0.6,1.9,0.9c4.12,1.9,8.4,3.69,12.82,5.34c2.16,0.81,4.36,1.59,6.58,2.33c3.55,1.19,7.17,2.3,10.86,3.32',
        'c1.56,0.44,3.13,0.85,4.71,1.25c15.85,4.03,32.67,6.45,49.32,6.94c10.32,0.3,20.59-0.15,30.53-1.42',
        'c12.16-1.56,67.03-8.6,109.51-51.09c12.59-12.59,24.09-28.3,33.07-47.9c0.46-1.01,3.9-8.74,7.77-20.56',
        'c1.26-3.86,2.58-8.17,3.85-12.82c0.85-3.11,1.67-6.38,2.46-9.77c1.76-7.58,3.29-15.79,4.29-24.34c0.1-0.87,0.2-1.74,0.29-2.61',
        'c2.62-25.08,0.58-52.71-13.43-75.4c-4.26-6.9-9.28-12.78-14.91-17.78c-6.68-5.94-14.22-10.62-22.36-14.24',
        'c-0.18-0.08-0.36-0.16-0.54-0.24c-2.74-1.21-5.54-2.29-8.41-3.27c0,0,0,0-0.01,0c-9.24-3.14-19.09-5.13-29.2-6.22h-0.01',
        'c-22.54-2.44-46.39-0.44-67.92,3.19h-0.01c-31.86,5.36-58.63,14.27-68.53,17.57c-12.91,4.29-26.42,9.68-40.12,15.97',
        'c-0.96,0.44-1.93,0.89-2.89,1.34c-13.03,6.09-26.19,12.99-39.14,20.55c-31.48,18.35-61.67,40.58-85.43,64.47',
        'c-7.05,7.07-13.52,14.29-19.3,21.6c-2.23,2.82-4.36,5.66-6.37,8.5c-4.42,6.25-8.31,12.54-11.57,18.85',
        'c-9.17,17.73-13.45,35.56-11,52.7c3.06,21.4,16.76,42.94,37.98,62.67c16.61,15.47,37.84,29.82,62.18,42.15',
        'c0.58,0.3,1.18,0.6,1.77,0.89c1.92,0.96,3.85,1.91,5.81,2.83h0.01c24.33,11.61,51.46,21.19,80.02,27.88l43.96,10.64',
        'c43.82,10.6,89.78,9.36,132.71-4.38c47.59-15.23,71.86-38.9,90.69-54.53c2.22-1.83,4.41-3.71,6.57-5.65',
        'c10.05-9,20.16-19.6,29.88-31.48h0.01c2.55-3.13,5.08-6.36,7.58-9.66c9.27-12.25,18.04-25.63,25.92-39.86',
        'c4.8-8.65,9.25-17.61,13.29-26.81V148.18C564.16,143.54,561.32,139.09,558.34,134.84z"/> '
    )
    );
  }

  function getPath2() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<path style="opacity:0.16;fill:#5D5DC2;" d="M558.52,419.07c-7.38-53.97-20.87-135.1-40.22-182.77c-6.66-16.4-13.69-34.46-20.99-54.58',
        'c-9-24.81-16.87-48.47-23.74-70.75c-3.75-12.14-7.2-23.87-10.37-35.15c-0.18-0.63-0.35-1.25-0.52-1.87',
        'c-0.01-0.01-0.01-0.01,0-0.02c-0.01-0.01-0.01-0.01,0-0.02c-7.74-27.59-13.85-52.4-18.68-73.91H274.58',
        'c1.56,0.98,3.12,1.96,4.67,2.94c25.94,16.48,50.02,33.7,72.13,51.47c0,0,0,0,0.01,0.01c3.38,2.72,6.71,5.45,10,8.19',
        'c9.26,7.72,18.16,15.55,26.67,23.46c33.81,31.38,61.66,64.07,83,97.09c0.32,0.49,0.62,0.97,0.93,1.44',
        'c12.76,19.95,23.16,40.02,31.05,60c0.01,0.01,0.01,0.02,0.01,0.04c20.41,51.73,24.1,102.91,8.94,149.99c0,0.02,0,0.03-0.01,0.04',
        'c-1.62,5.05-3.47,10.07-5.54,15.02c-1.66,3.99-3.53,8.07-5.59,12.26c0,0.01-0.01,0.01-0.01,0.01',
        'c-4.01,8.17-8.81,16.67-14.32,25.28c-4.33,6.78-9.11,13.62-14.34,20.44c-1.99,2.61-4.05,5.22-6.19,7.81',
        'c-1.39,1.71-2.82,3.42-4.28,5.12c-8.97,10.51-18.97,20.77-29.94,30.39c-22.07,19.41-48.02,36.22-77.28,47.19',
        'c-1.35,0.52-2.73,1.01-4.11,1.49c-20.84,7.36-43.3,11.75-67.2,12.03c-0.98,0.01-1.95,0.02-2.92,0.01',
        'c-3.56-0.01-7.1-0.11-10.59-0.3c-9.03-0.49-17.81-1.57-26.35-3.15c-26.33-4.91-50.38-14.77-71.97-27.64',
        'c-48.78-29.02-85.03-73.38-106.71-110.7c-0.01-0.01-0.01-0.03-0.02-0.05c-4.7-8.1-8.71-15.86-12.02-23.07',
        'C16.1,327.24,24.94,226.38,69.23,164.54c0-0.01,0-0.01,0-0.01c1.9-2.67,3.88-5.27,5.93-7.79c1.02-1.27,2.07-2.52,3.15-3.75',
        'c10.19-11.81,21.91-21.74,35.07-29.24c1.29-0.75,2.61-1.46,3.93-2.15c8.39-4.39,17.34-7.81,26.81-10.13',
        'c42.96-10.52,88.47,3.65,124.89,21.73c4.12,2.05,8.14,4.14,12.01,6.27c4.6,2.5,9,5.05,13.2,7.57',
        'c13.31,7.98,24.44,15.75,32.48,21.68c2.42,1.79,4.56,3.4,6.39,4.81c2.06,1.58,3.75,2.9,5.01,3.89',
        'c7.49,5.87,14.84,12.24,21.9,19.02c37.35,35.86,67.12,83.59,72.19,133.09c2.43,23.81-0.84,48.04-11.74,71.56',
        'c-0.71,1.55-1.98,4.25-3.82,7.81c0,0,0,0,0,0.01c-1.5,2.91-3.39,6.36-5.69,10.17c-1.73,2.9-3.71,5.99-5.93,9.22v0.01',
        'c-15.78,23.07-43.83,52.62-87.05,58.81c-12.3,1.76-24.67,1.46-36.85-0.54c-4.12-0.68-8.22-1.55-12.29-2.59',
        'c-2.29-0.6-4.59-1.25-6.86-1.96c-12.36-3.83-24.37-9.3-35.7-16c-3.38-1.99-6.71-4.1-9.97-6.31c-7.3-4.94-14.25-10.38-20.78-16.19',
        'c-21.99-19.58-39.07-43.4-47.76-66.82c-6.94-18.69-8.88-38.09-7.26-56.85c1.95-22.63,9.1-44.31,18.92-62.63',
        'c2.71-5.05,5.62-9.84,8.67-14.32c2.16-3.16,4.39-6.18,6.7-9.02c10.22-12.68,21.56-22,32.4-26.4',
        'c12.79-12.84,28.84-22.42,46.8-27.41c-18.29-15.75-38.65-25.86-58.67-24.18c-23.84,2.01-45.06,20.3-60.86,46.68',
        'c-1.45,2.43-2.86,4.91-4.21,7.47c-0.38,0.69-0.73,1.39-1.1,2.08c-2.32,4.51-4.5,9.21-6.52,14.05c-0.99,2.37-1.94,4.78-2.84,7.22',
        'c-1.45,3.89-2.81,7.86-4.05,11.9c-0.54,1.71-1.04,3.43-1.53,5.16c-4.92,17.38-7.87,35.81-8.47,54.07',
        'c-0.37,11.32,0.18,22.57,1.73,33.47c1.9,13.33,10.49,73.48,62.34,120.05c15.36,13.8,34.53,26.41,58.44,36.25',
        'c1.23,0.51,10.66,4.27,25.09,8.52c4.71,1.39,9.97,2.83,15.64,4.23c3.79,0.93,7.78,1.84,11.92,2.7c9.25,1.93,19.27,3.6,29.7,4.7',
        'c1.06,0.11,2.12,0.22,3.18,0.32c30.6,2.88,64.31,0.63,92-14.72c8.42-4.66,15.59-10.17,21.69-16.35',
        'c7.25-7.32,12.96-15.59,17.37-24.51c0.1-0.2,0.2-0.39,0.29-0.59c1.48-3,2.79-6.07,3.99-9.22c0,0,0,0,0-0.01',
        'c3.83-10.13,6.26-20.93,7.59-32v-0.01c2.98-24.71,0.54-50.86-3.89-74.46v-0.01c-6.54-34.93-17.41-64.27-21.44-75.13',
        'c-5.23-14.15-11.81-28.96-19.49-43.98c-0.54-1.05-1.09-2.11-1.64-3.16c-7.43-14.28-15.85-28.71-25.07-42.9',
        'c-22.39-34.51-49.51-67.6-78.66-93.65c-8.63-7.72-17.44-14.83-26.35-21.15c-3.44-2.45-6.91-4.78-10.37-6.99',
        'c-7.63-4.85-15.3-9.11-23-12.69c-21.63-10.06-43.39-14.74-64.3-12.05c-26.11,3.36-52.39,18.37-76.46,41.63',
        'C87.2,91.01,69.7,114.28,54.65,140.97c-0.37,0.64-0.73,1.29-1.09,1.94c-1.17,2.1-2.33,4.23-3.45,6.37v0.01',
        'c-14.17,26.67-25.85,56.41-34.02,87.73L3.12,285.2c0,64.46-3.29,85.74,5.34,145.48c7.92,54.81,47.46,78.77,66.53,99.41',
        'c2.23,2.44,4.53,4.84,6.89,7.21c10.98,11.02,23.91,22.1,38.41,32.75v0.01c3.82,2.8,7.76,5.57,11.79,8.31',
        'c14.95,10.16,31.27,19.78,48.63,28.41c10.55,5.26,21.49,10.14,32.71,14.57c0,0,91.01,34.58,248.88-9.28',
        'c40.03-11.12,59.68-51.99,76.62-80.62c1.42-2.39,2.78-4.78,4.09-7.15c4.47-8.08,8.35-15.99,11.69-23.55v-0.01',
        'C559.01,491.01,562.92,451.27,558.52,419.07z"/> '
    )
    );
  }

}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library Sky1Path3_4Descriptor {

  function getPath3() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<path style="opacity:0.16;fill:#5D5DC2;" d="M566.81,83.96c0,0-31.92,4.99-38.91,73.82s61.85,244.42-70.83,289.31',
        'c-73.11,24.74-120.89,106.66-180.57,106.75c-52.27,0.07-94.76-55.7-122.71-109.74c-59.86-115.72-67.23-250.6,60.86-272.35',
        'c52.87-8.98,50.44-28.51,67.84-34.92c75.82-27.93,167.6,123.71,151.64,74.82c0,0-69.83-118.72-169.6-110.74',
        'S25.1,254.55,117.88,481.01c29.27,71.45,120.71,112.73,258.38,80.81c68.08-15.79,156.99-89.22,184.56-184.56',
        'c26.35-91.12-50.56-183.56,5.99-183.56V83.96z"/> '
    )
    );
  }

  function getPath4() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<path style="opacity:0.16;fill:#5D5DC2;" d="M135.82,252.15c-0.13,2.59-0.04,8.45-2.1,10.65c-2.33,2.48-7.04,0.68-9.76,0.39',
        'c-2.26-0.24-4.49-1.01-6.78-0.87c-1.9,0.12-3.69,0.79-5.61,0.65c-1.39-0.1-3.97-0.37-5.19-0.99c-1.45-0.73-2.17-2.09-3.25-3.29',
        'c-2.65-2.94-4.34-6.95-6.54-10.26c-1.39-2.09-1.63-4.03-1.87-6.49c-0.32-3.26-0.89-6.5-1.09-9.77c-0.29-4.68-0.84-9.67-0.01-14.32',
        'c0.77-4.31,2.67-7.1,5.75-10.16c1.27-1.26,2.85-2.07,4.1-3.35c1.52-1.54,2.96-3.28,4.83-4.45c1.02-0.64,2.25-1.32,3.42-1.59',
        'c1.65-0.38,2.47,0.16,3.97,0.34c2.18,0.26,3.12,0.13,5.05,1.31c1.44,0.88,2.78,1.98,3.81,3.31c2.13,2.73,4.83,5.13,6.73,7.98',
        'c2.54,3.82,3.93,7.2,3.97,11.88c0.03,4.1,0.69,8.08,1.41,12.14c0.59,3.35,1.49,8.08,0.72,11.55',
        'C136.83,249.34,135.64,251.34,135.82,252.15z"/> ',
        '<path style="fill:#5D5DC2;opacity:0.16;" d="M546.39,262.72c-6.8,2.72-14.83,12.27-18.88,13.48c-2.48,0.74-5.04,0.17-7.64,1.19',
        'c-2.48,0.97-4.03,2.49-6.19,3.91c-3.24,2.08-7.35,4.6-10.56,2.01c-3.17-2.62-2.33-10.29-7.86-9.07',
        'c-2.75,0.65-4.37,3.58-7.51,4.19c-2.67,0.48-4.74,0.81-7.28,1.86c-4.32,1.75-7.32,4.07-11.25,6.33',
        'c-1.98,1.16-3.74,1.04-5.92,1.32c-1.72,0.24-4.82,1.7-6.37,1.5c-5.64-0.64-3.44-7.04-2.68-10.58c0.42-1.84,1.2-4.1,1.37-5.98',
        'c0.18-2.22-0.61-3-0.98-5.05c-1.05-5.22,0.97-10.16,3.4-14.78c3.55-6.74,7.19-13.99,8.7-21.45c0.68-3.37,1.67-5.47,0.98-8.78',
        'c-0.5-2.48-0.93-4.93-1.35-7.44c-0.53-3.04-0.62-5.58-0.68-8.65c-0.12-4.06-1.55-7.83-1.81-11.88',
        'c-0.21-3.45,0.73-11.02,2.9-13.87c1.05-1.32,2.83-1.78,3.79-3.35c0.97-1.53,0.61-3.05,2-4.36c3.16-3.01,11.47-2.5,15.38-2.61',
        'c5.95-0.15,12.96,1.3,18.43,3.58c5.99,2.51,10.28,5.88,15.57,9.29c1.86,1.22,5.96,3.28,9.24,3.48c-0.88-2.47-1.81-4.97-2.78-7.44',
        'c-18.95-48.22-50.53-87.7-89.47-116.13c-0.66-0.22-1.32-0.44-1.96-0.61c-3.46-0.93-7.64-1.72-11.23-1.88',
        'c-3.2-0.13-6.17,0.8-9.05,0.88c-5,0.15-10.23-0.66-15.2-1.66c-6.07-1.24-11.94-0.89-18-1.99c-15.83-2.89-28.87-14.36-41.95-23.01',
        'c-3.16-2.1-5.26-3.32-8.08-5.75c-1.93-1.63-4.01-2.43-6.32-3.34c-5-2.04-10.79-3.92-16.26-2.53c-3.3,0.82-5.25,3.64-7.69,6.03',
        'c-3.36,3.23-4.56,4.42-0.82,7.14c6.49,4.75,15.2,8.95,12,18.75c-2.03,6.24-3.52,12.4-6.4,18.3c-3.21,6.51-4.96,15.16-11.36,19.63',
        'c-4.76,3.3-11.33,1.4-16.83,1.46c-4.89,0.06-10.1-0.56-14.84,0.82c-3.72,1.08-6.24,3.55-9.55,5.42',
        'c-5.1,2.91-11.48,4.27-16.03,0.1c-1.75-1.55-1.36-2.37-3.91-3.04c-2.34-0.61-5.73,0.11-8.03,0.44',
        'c-7.01,1.09-13.69,4.38-20.65,5.35c-4.66,0.64-9.75,0.3-14.44,0.38c-3.09,0.02-6.47,1.25-9.28,0.78',
        'c-1.63-0.27-3.58-1.22-5.3-1.59c-5.11-1.24-8.44-1.21-13.39,0.87c-9.81,4.05-21.71,12.25-28.85,20.4',
        'c-4.64,5.31-3.36,8.57,0.7,13.32c3.46,4.08,9.93,8.4,10.76,13.9c0.72,4.63-1.32,9.39-1.19,13.97c0.11,4.53,0.17,8.8,3.54,12.16',
        'c5.65,5.65,14,8.43,20.21,13.33c7,5.55,14,16.82,8.41,25.17c-2.78,4.1-3.42,8.64-4.55,13.43c-0.73,3.24-0.91,7.89-5.05,8.52',
        'c-2.75,0.41-6.11-2.08-8.86-1.91c-3.17,0.2-5.18,2.23-6.95,4.64c-2.7,3.68-6.76,7.81-8.4,12.12c-3,7.9,2.16,19.95,8,25.33',
        'c6.99,6.51,13.63,13.44,23.62,14.23c0.33,0.03,0.67,0.04,1,0.05c-0.34-3.46-0.52-6.98-0.52-10.53',
        'c0-58.71,47.59-106.3,106.3-106.3c58.71,0,106.3,47.59,106.3,106.3c0,10.89-1.64,21.4-4.68,31.29c1.91,4.21,4.05,8.28,6.61,12.08',
        'c3.43,5.09,7.13,9.41,11.28,13.79c1.35,1.38,1.76,0.6,2.22,2.99c0.27,1.42-0.21,6.14-0.58,7.62c-0.95,3.9-4.58,8.24-6.31,11.97',
        'c-1.66,3.66-4.38,6.44-6.61,9.75c-3.24,4.75-6.65,9.05-9.99,13.66c-5.43,7.43-1.5,17.05-5.5,25.44',
        'c-5.67,11.91-15.46,17.57-25.04,26.1c-7.67,6.83-15.68,12.89-22.42,20.5c-4.23,4.76-6.93,9.92-11.67,14.36',
        'c-6,5.6-13.13,9.55-19.7,14.32c-5.2,3.76-10.88,6.9-17.13,8.59c-4.06,1.07-7.43,1.01-11.58,2.69c-7.31,2.87-14.66,5.9-22.06,8.67',
        'c-3.96,1.46-8.05,0.87-12.26,0.96c-4.25,0.1-8.61-0.19-12.92-0.12c-11.25,0.13-25.89,3.78-35.99-2.5',
        'c-2.96-1.84-5.55-4.4-8.63-6.05c-2.61-1.31-5.35-1.48-8.08-2.36c-2.3-0.76-4.15-1.47-6.47-1.89c-3.75-0.67-6.01-2.07-9.47-3.72',
        'c-2.81-1.33-5.87-2.08-8.96-2.54c-1.57-0.24-4.34,0.13-5.71-0.57c-1.83-0.9-1.38-1.94-2.37-3.6c-1.07-1.87-2.59-3.08-3.81-4.85',
        'c-3.2-4.75-8.6-9.88-14.97-10.91c-3.46-0.55-5.53-0.12-8.89-1.37c-6.26-2.21-9.06-3.88-13.45-9.22c-0.02,0.2-0.04,0.4-0.03,0.54',
        'c37.64,39.2,73.83,68.73,123.2,79.91c13.92,3.15,28.49,2.14,41.76-3.12c1.63-0.65,2.79-1.18,3.08-1.5',
        'c4.08-4.42,8.62-6.11,14.09-8.21c7.19-2.83,13.79-6.18,20.37-10.3c5.84-3.58,11.76-6,18.22-8.49c7.97-3.03,14.95-7.83,23-10.9',
        'c7.65-2.86,15.47-3.36,23.47-4.6c11.46-1.79,21.49-9.16,31.06-15.4c4.34-2.8,7.69-7.12,12.17-9.69c2.73-1.55,5.6-2.49,8.29-4.26',
        'c6.36-4.08,15.45-8.26,22.9-10.05c5.11-1.2,8.53,1.8,13.07,2.78c4.79,1.03,9.08-2.99,13.45-4.14c5.1-1.34,10.59,1.23,14.39,4.93',
        'C524.15,403.48,549.91,333.93,546.39,262.72z M354.39,67.59c-0.37,3.2-2.48,6.32-4.74,8.45c-1.7,1.62-5.13,3.83-7.36,4.7',
        'c-5.27,2.12-11.79-0.14-16.79-1.7c-2.91-0.86-9.76-4.08-1.94-4.58c-1.56-1.67-3.15-2.91-3.78-5c-0.45-1.4-0.57-3.26-0.75-4.71',
        'c-0.51-3.47,0.37-6.82,0.12-10.25c-0.21-2.59-0.48-5.82-1.27-8.33c-0.71-2.3-2.14-3.98-0.73-6.34c0.89-1.49,1.94-1.86,3.49-1.56',
        'c1.63,0.27,3.61,2.02,5.15,2.79c1.73,0.89,3.43,1.8,5.11,2.81c4.95,2.78,8.63,7.39,13.31,10.56c2.64,1.73,4.89,2.85,7.06,5.34',
        'C353.15,61.88,354.66,64.62,354.39,67.59z M451.21,167.1c-2.82-3.42-4.91-6.56-7.3-10.2c-2.83-4.42-6.72-8.24-9.97-12.39',
        'c-5.38-6.9-11.96-15.14-13.03-24.17c-0.69-5.88,1.21-13.31,5.96-16.99c3.34-2.55,8.11-4.62,12.31-4.84',
        'c5.29-0.36,10.5,1.36,15.44,3c4.84,1.63,9.64,4.51,12.85,8.54c2.29,2.92,3.96,6.31,6.47,9.05c1.27,1.41,2.47,2.65,3.63,4.15',
        'c1.42,1.92,3.51,2.87,5.42,4.21c2.89,2.01,5.35,3.29,6.77,6.55c1.34,3.05,2.39,6.21,3.61,9.31c1.15,2.93,2.74,5.65,2.25,8.89',
        'c-0.82,5.33-6.84,9.17-11.18,11.6c-6.42,3.57-15.31,4.73-22.59,5.63c-3.09,0.4-5.41,0.31-8.34-0.59',
        'C450.45,167.97,446.9,168.17,451.21,167.1z"/> ',
        '<path style="opacity:0.16;fill:#5D5DC2;" d="M533.8,299.23c-3.93-0.47-8.46,2.43-12.02,3.77c-5.71,2.14-11.44,0.16-16.58-2.54',
        'c-4.17-2.19-7.85-5.02-12.21-6.85c-2.15-0.91-4.89-2.79-7.3-2.58c-1.81,0.16-4.13,1.31-5.6,2.26',
        'c-3.59,2.33-7.45,4.05-11.72,4.82c-3.75,0.67-9.09,1.48-12.67-0.03c-2.31-0.98-4.42-2.75-6.59-4.02',
        'c-3.19-1.88-4.39-7.16-4.42-10.73c-0.08-7.5-2.24-14.84-2-22.34c0.15-4.75,6.01-5.68,8.71-8.99c2.13-2.61,2.42-5.56,3.61-8.51',
        'c1.04-2.56,3.09-5.01,4.56-7.37c4.9-7.88,2.94-16.59-5.73-21.17c-4.96-2.62-10.6-2.22-14.93,1.17c-1.93,1.5-3.97,2.95-5.71,4.66',
        'c-2.3,2.27-3.99,4.88-6.86,6.57c-10.96,6.46-23.34,3.89-35.06,2.12c-5.33-0.81-11.26-0.96-16.54,0.22',
        'c8.94,15.57,14.07,33.6,14.07,52.84c0,4.1-0.24,8.15-0.69,12.13c1.53,2.49,3.45,4.69,6.1,6.26c2.07,1.23,3.86,1.72,6.28,0.92',
        'c2.18-0.72,3.48-2.54,5.73-3.27c1.88-0.61,3.5,0.17,5.46,0.28c2.48,0.14,4.96,0.13,7.44,0.12c2.37-0.01,3.7,0.48,5.83,1.35',
        'c1.83,0.75,4.04,0.63,5.31,2.42c1.35,1.9-0.42,4.01-1.06,5.99c-1.28,4-2.5,7.54-5.43,10.66c-1.84,1.97-2.89,2.34-5.5,2.5',
        'c-2.42,0.15-4.69,0.19-6.3,2.41c-2.08,2.88-3.69,6.53-4.19,10.05c-0.07,0.47-0.02,2.21,0.08,2.55c0.49,1.66,0.14,0.55,1.28,1.44',
        'c1.27,0.98,2.44,1.45,3.09,3.1c0.93,2.38,1.05,6.27,0.71,8.76c-0.24,1.76-0.71,3.63-1.62,5.2c-1.06,1.84-1.48,3.71-2.73,5.48',
        'c-2.42,3.43-3.45,7.2-6.33,10.46c-3.35,3.8-6.02,8.12-8.66,12.44c-5.56,9.11-12.32,16.66-13.85,27.62',
        'c-0.37,2.67,0.34,7.74,2.65,9.57c0.92,0.73,2.72,0.93,3.81,1.51c2.05,1.11,3.06,2.66,4.6,4.37c1.66,1.84,4.13,4.69,6.61,5.44',
        'c2.43,0.73,6.22,0.09,8.64-0.72c1.44-0.49,2.64-1.11,4.12-1.47c1.13-0.27,2-0.11,3.2-0.5c4.16-1.38,7.57-2.87,12.2-1.99',
        'c1.58,0.3,2.95,0.96,4.31,1.76c1.6,0.95,3.11,2.79,4.83,3.47c3.49,1.38,7.93-3.01,10.07-4.97c3.14-2.88,6.41-6.94,10.85-7.78',
        'c2.68-0.51,5.28,0.71,8.03,0.58c3.79-0.19,6.74-0.1,10.43,0.61c1.57,0.3,2.38,0.59,3.98,0.06c4.85-1.62,8.41-6.17,11.55-9.98',
        'c3.74-4.54,6.74-9.59,10.47-14.1c4.11-4.97,6.55-9.24,9.17-15.13c2.35-5.27,5.88-9.65,8.84-14.56',
        'c2.25-3.72,4.36-7.52,6.54-11.28c2.23-3.86,3.51-8.18,5.15-12.29c1.3-3.27,2.89-6.18,3.6-9.64c0.78-3.84,1.28-7.9,2.47-11.6',
        'c1.29-4.02,2.15-7.57,2.65-11.76C538.98,307.18,539.32,299.9,533.8,299.23z"/> '
    )
    );
  }

}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import "../../../utils/PlanetRandom.sol";
import "./Sky2Path1_2Descriptor.sol";
import "./Sky2Path3_4Descriptor.sol";


library Sky2PathDescriptor {

  function getSVG(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public pure returns (string memory svg, uint offsetRandom) {
    uint index = 0;

    // select random path layer
    uint randomPathLayer = PlanetRandom.calcRandom(0, 4, blockhashInit_, offsetRandom_);

    if (randomPathLayer == 0) {
      svg = Sky2Path1_2Descriptor.getPath1();
    } else if (randomPathLayer == 1) {
      svg = Sky2Path1_2Descriptor.getPath2();
    } else if (randomPathLayer == 2) {
      svg = Sky2Path3_4Descriptor.getPath3();
    } else {
      svg = Sky2Path3_4Descriptor.getPath4();
    }

    offsetRandom = offsetRandom_;
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library Sky2Path1_2Descriptor {

  function getPath1() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<linearGradient id="SKY2_LG1" gradientUnits="userSpaceOnUse" x1="0" y1="252.8589" x2="252.0218" y2="252.8589"> ',
        '<stop  offset="0" style="stop-color:#573C30"/> ',
        '<stop  offset="1" style="stop-color:#301E14"/> ',
        '</linearGradient> ',
        '<path style="opacity:0.3;fill:url(#SKY2_LG1);" d="M191.95,0',
        'c0,0-84.67,62.34-84.67,207.48c0,140.83,9.51,218.55-107.28,218.55v79.61c0,0,139.11,8.96,137.97-167.95',
        'C136.83,160.78,155.71,49.39,252.02,0H191.95z"/> ',
        '<linearGradient id="SKY2_LG2" gradientUnits="userSpaceOnUse" x1="77.0295" y1="574.7913" x2="566.9291" y2="574.7913"> ',
        '<stop  offset="0" style="stop-color:#573C30"/> ',
        '<stop  offset="1" style="stop-color:#301E14"/> ',
        '</linearGradient> ',
        '<path style="opacity:0.3;fill:url(#SKY2_LG2);" d="M566.93,214.15',
        'c0,0-7.31,294.38-156.29,292.58c-89.05-1.07-157.15,7.69-209.67,31.68C8.56,626.33,97.61,935.43,97.61,935.43H199.8',
        'c0,0-29.6-65.74-44.51-140.44c-49.04-245.65,173.59-239.36,262.97-251.2c101.86-13.49,148.67-100.02,148.67-143.51V214.15z"/> '
    )
    );
  }

  function getPath2() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
    '<linearGradient id="SKY2_LG3" gradientUnits="userSpaceOnUse" x1="375.7122" y1="733.1992" x2="375.7122" y2="111.1077" ',
    'gradientTransform="matrix(0.9537 -0.3009 0.3009 0.9537 -209.1915 141.8566)"> ',
    '<stop  offset="0" style="stop-color:#573C30"/> ',
    '<stop  offset="1" style="stop-color:#301E14"/> ',
    '</linearGradient> ',
    '<path style="fill:url(#SKY2_LG3);opacity:0.3;" d="M566.93,526.69v139.11',
    'c0,0-109.52-38.06-139.9-160.91c-3.08-12.46-15.46-20.33-28.02-17.67c-65.79,13.93-148.94,86.37-210.67,78.95',
    'C16.09,545.46,0,394.45,0,329.37V192.36C6.08,689.93,410.64,315.49,464.8,485C494.16,576.87,566.93,526.69,566.93,526.69z"/> ',
    '<linearGradient id="SKY2_LG4" gradientUnits="userSpaceOnUse" x1="22.823" y1="859.8785" x2="22.823" y2="456.9759" ',
    'gradientTransform="matrix(-3.464102e-07 1 1 3.464102e-07 -292.9521 75.5515)"> ',
    '<stop  offset="0" style="stop-color:#573C30"/> ',
    '<stop  offset="1" style="stop-color:#2D1C12"/> ',
    '</linearGradient> ',
    '<path style="fill:url(#SKY2_LG4);opacity:0.3;" d="M164.03,0',
    'c3.69,6.73,11.69,26.73,51.42,26.73c103.86,0,78.92,170.01,351.48,170.01l0-109.53c-38.82,0-163.8,1.75-211.13-13.53',
    'c-32.67-10.55-64.41-29.22-91.16-62.18C253.76-1.9,204.25,20.34,193.74,0L164.03,0z"/> ',
    '<linearGradient id="SKY2_LG5" gradientUnits="userSpaceOnUse" x1="58.6611" y1="859.8785" x2="58.6611" y2="440.3556" ',
    'gradientTransform="matrix(-3.464102e-07 1 1 3.464102e-07 -292.9521 75.5515)"> ',
    '<stop  offset="0" style="stop-color:#6E564B"/> ',
    '<stop  offset="1" style="stop-color:#2D1C12"/> ',
    '</linearGradient> ',
    '<path style="fill:url(#SKY2_LG5);opacity:0.3;" d="M164.03,0',
    'c3.69,6.73,11.69,26.73,51.42,26.73c99.37,0,99.38,74.62,159.35,117.36c45.53,32.44,167.72,31.87,192.13,31.87v92.46',
    'c-239.28,0-237.84-226.32-348.8-226.32c-61.84,0-70.72-26.78-70.72-42.1L164.03,0z"/> '
    )
    );
  }

}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library Sky2Path3_4Descriptor {

  function getPath3() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<linearGradient id="SKY2_LG6" gradientUnits="userSpaceOnUse" x1="313.0611" y1="875.2369" x2="313.0611" y2="-9.505934e-05" ',
        'gradientTransform="matrix(-1 0 0 -1 566.9291 935.433)"> ',
        '<stop  offset="0" style="stop-color:#573C30"/> ',
        '<stop  offset="1" style="stop-color:#301E14"/> ',
        '</linearGradient> ',
        '<path style="fill:url(#SKY2_LG6);opacity:0.3;" d="M0,62.66',
        'c77.39-12.84,102.17,25.36,87.79,94.83c-50.67,244.78,59.2,288.86,103.92,305.43c64.26,23.82,129.87,35.73,193.64,64.61',
        'C543.39,599.1,503.66,888,502.38,935.43h-66.53C579.78,459.09,0,537.81,0,351.35L0,62.66z"/> ',
        '<linearGradient id="SKY2_LG7" gradientUnits="userSpaceOnUse" x1="98.3717" y1="935.433" x2="98.3717" y2="532.5305" ',
        'gradientTransform="matrix(-1 0 0 -1 566.9291 935.433)"> ',
        '<stop  offset="0" style="stop-color:#573C30"/> ',
        '<stop  offset="1" style="stop-color:#2D1C12"/> ',
        '</linearGradient> ',
        '<path style="fill:url(#SKY2_LG7);opacity:0.3;" d="M566.93,402.9',
        'c-6.73-3.69-26.73-11.69-26.73-51.42c0-103.86-170.01-78.92-170.01-351.48l109.53,0c0,38.82-1.75,163.8,13.53,211.13',
        'c10.55,32.67,29.22,64.41,62.18,91.16c13.4,10.88-8.83,60.39,11.51,70.9V402.9z"/> ',
        '<linearGradient id="SKY2_LG8" gradientUnits="userSpaceOnUse" x1="134.2097" y1="935.433" x2="134.2097" y2="515.9101" ',
        'gradientTransform="matrix(-1 0 0 -1 566.9291 935.433)"> ',
        '<stop  offset="0" style="stop-color:#6E564B"/> ',
        '<stop  offset="1" style="stop-color:#2D1C12"/> ',
        '</linearGradient> ',
        '<path style="fill:url(#SKY2_LG8);opacity:0.3;" d="M566.93,402.9',
        'c-6.73-3.69-26.73-11.69-26.73-51.42c0-99.37-74.62-99.38-117.36-159.35C390.4,146.6,390.97,24.41,390.97,0l-92.46,0',
        'c0,239.28,226.32,237.84,226.32,348.8c0,61.84,26.78,70.72,42.1,70.72V402.9z"/> '
    )
    );
  }

  function getPath4() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<linearGradient id="SKY2_LG9" gradientUnits="userSpaceOnUse" x1="356.8032" y1="455.9965" x2="356.8032" y2="1.546141e-11"> ',
        '<stop  offset="0" style="stop-color:#573C30"/> ',
        '<stop  offset="1" style="stop-color:#301E14"/> ',
        '</linearGradient> ',
        '<path style="fill:url(#SKY2_LG9);opacity:0.3;" d="M566.93,456',
        'c-67.96-35.84-85.46-140.01-73.43-176.31c42.38-127.89-49.51-150.92-86.92-159.58c-53.75-12.45-109.06-18.08-161.96-33.75',
        'c-23.79-7.05-47.46-16.38-66.38-32.43S145.67,24.78,146.74,0h55.65c25.23,98.92,226.23,52.09,274.64,62.01',
        'c36.84,7.55,62.85,22.95,89.91,53.31V456z"/> ',
        '<linearGradient id="SKY2_LG10" gradientUnits="userSpaceOnUse" x1="184.1407" y1="935.433" x2="184.1407" y2="181.2457"> ',
        '<stop  offset="0" style="stop-color:#573C30"/> ',
        '<stop  offset="1" style="stop-color:#2D1C12"/> ',
        '</linearGradient> ',
        '<path style="fill:url(#SKY2_LG10);opacity:0.3;" d="M0,181.25',
        'c12.59,6.9,50.04,21.88,50.04,96.25c0,194.42,318.24,147.74,318.24,657.94H163.26c0-72.67,3.28-306.62-25.33-395.21',
        'c-19.75-61.15-54.69-120.56-116.39-170.64C-3.55,349.22,38.07,256.55,0,236.87V181.25z"/> ',
        '<linearGradient id="SKY2_LG11" gradientUnits="userSpaceOnUse" x1="251.2253" y1="935.433" x2="251.2253" y2="150.1344"> ',
        '<stop  offset="0" style="stop-color:#6E564B"/> ',
        '<stop  offset="1" style="stop-color:#2D1C12"/> ',
        '</linearGradient> ',
        '<path style="fill:url(#SKY2_LG11);opacity:0.3;" d="M0,181.25',
        'c12.59,6.9,50.04,21.88,50.04,96.25c0,186.01,139.69,186.02,219.68,298.29c60.73,85.23,59.65,313.96,59.65,359.65h173.08',
        'c0-447.9-423.64-445.21-423.64-652.92c0-115.76-50.13-132.38-78.81-132.38V181.25z"/> '
    )
    );
  }

}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import "../../../utils/PlanetRandom.sol";
import "./Sky3Path1_2Descriptor.sol";
import "./Sky3Path3_4Descriptor.sol";


library Sky3PathDescriptor {

  function getSVG(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public pure returns (string memory svg, uint offsetRandom) {
    uint index = 0;

    // select random path layer
    uint randomPathLayer = PlanetRandom.calcRandom(0, 4, blockhashInit_, offsetRandom_);
    offsetRandom_ = offsetRandom_ + 1124;

    if (randomPathLayer == 0) {
      svg = Sky3Path1_2Descriptor.getPath1();
    } else if (randomPathLayer == 1) {
      svg = Sky3Path1_2Descriptor.getPath2();
    } else if (randomPathLayer == 2) {
      svg = Sky3Path3_4Descriptor.getPath3();
    } else {
      svg = Sky3Path3_4Descriptor.getPath4();
    }

    offsetRandom = offsetRandom_;
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library Sky3Path1_2Descriptor {

  function getPath1() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<path style="opacity:0.3;fill:#7A346D;" d="M238.23,0H120.88c0,99.42,278.06,14.82,345.15,139.46c48.34,89.8,37,160.58,100.9,177.35v-81.21',
        'C513.46,240.97,525.61,0,238.23,0z',
        'M180.16,545.58c160.89,51.08,384.72-59.1,386.77-57.97v-99.53c-1.7-0.21-244.24,171.55-385.87,138.61',
        'C71.36,501.18,79.94,362.96,0,362.96v32.43C56.64,395.39,89.3,516.73,180.16,545.58z"/> '
    )
    );
  }

  function getPath2() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<path style="opacity:0.3;fill:#7A346D;" d="M120.43,197.69C256.46,174.02,340.04,126.14,348.31,0h-69.39c2.1,54.83,10.38,149.78-128.95,174.79',
        'C49.59,192.8,8.54,188.08,0,201.7v122.28C11.52,271.49-7.28,219.91,120.43,197.69z',
        'M557.95,382.59c-8.01,7.51-44.76,33.49-75.27,42.89c-23.23,7.16-100.8,18.12-172.92,80.47',
        'c-127.7,110.4-193.54,428.33-195.57,429.48h116.78c1.06-1.34-20.99-330.38,94.42-418.84c57.3-43.92,120.31-65.57,145.3-68.06',
        'c45.48-4.53,86.63-2.88,96.25-12.49v-62C564.41,376.9,560.98,379.77,557.95,382.59z"/> '
      )
    );
  }

}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library Sky3Path3_4Descriptor {

  function getPath3() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
    '<path style="opacity:0.3;fill:#7A346D;" d="M84.67,0h56.5c26.87,40.92,91.66,113.57,221.73,67.68c149.51-52.75,204.02,40.17,204.02,40.17l1.87,122.79',
    'c0,0-37.67-149.14-232.1-131.22C226.74,109.55,133.39,59.65,84.67,0z',
    'M164.91,393.99c168.36-12.23,399.77,107.81,402.02,107.19v140.78c-1.7-0.19-261.39-248.46-405.55-229.4',
    'C89.8,422.03,95.73,526.41,0,526.41c0,0,0-16.21,0-43.84C68.32,482.57,69.82,400.9,164.91,393.99z"/> '

      )
    );
  }

  function getPath4() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<path style="opacity:0.3;fill:#7A346D;" d="M235.38,0h-39.67c7.64,102.18-17.07,103.58-114.6,201.11C14.2,268.02,0,335.36,0,335.36v105.7',
        'c0,0,41.92-16.76,56.64-148.59S239.69,138.12,235.38,0z',
        'M56.64,935.43c0,0-67.56-134.52,94.16-244.59s396.06-180.87,326.22-375.42S351.05,61.69,375.63,0h58.5',
        'c0,0-51.02,34.49-22.46,115.03c28.56,80.54,141.12,178.35,108.23,360.45S167.15,654.86,168.76,815.1s54.57,120.33,54.57,120.33',
        'H56.64z"/> '
      )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import './PlanetSurface1_1Descriptor.sol';
import './PlanetSurface1_2Descriptor.sol';

library PlanetSurface1Descriptor {

  function getSVG() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        PlanetSurface1_1Descriptor.getSVG(),
        PlanetSurface1_2Descriptor.getSVG()
    )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import './PlanetSurface2_1Descriptor.sol';
import './PlanetSurface2_2Descriptor.sol';
import './PlanetSurface2_3Descriptor.sol';

library PlanetSurface2Descriptor {

  function getSVG() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        PlanetSurface2_1Descriptor.getSVG(),
        PlanetSurface2_2Descriptor.getSVG(),
        PlanetSurface2_3Descriptor.getSVG()
    )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import './PlanetSurface3_1Descriptor.sol';
import './PlanetSurface3_2Descriptor.sol';

library PlanetSurface3Descriptor {

  function getSVG() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        PlanetSurface3_1Descriptor.getSVG(),
        PlanetSurface3_2Descriptor.getSVG()
      )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import './PlanetSurface4_1Descriptor.sol';
import './PlanetSurface4_2Descriptor.sol';

library PlanetSurface4Descriptor {

  function getSVG() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        PlanetSurface4_1Descriptor.getSVG(),
        PlanetSurface4_2Descriptor.getSVG()
    )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library PlanetSurface1_1Descriptor {

  function getSVG() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<path class="clip_path" d="M251.1,203.77c16.11,0.5,32.41,0.04,48.53-0.52c26.23-0.78,52.66-0.07,78.83-1.45',
        'c1.91,0.06,9.39-0.78,4.12-2.03c-33.05-3.7-67.12-2.59-100.48-3.51c-44.18-0.46-51.95-0.59-105.88-0.56v8.06',
        'C212.03,203.77,240.91,203.77,251.1,203.77z',
        'M281.24,193.07c63.93,1.97,210.22,2.89,263.51,2.12c-84.52-1.61-149.96,0.52-200.34-2.86',
        'c-0.06-1.27,6.84-0.71,6.37-1.89c-1.44-1.16-6.54-0.75-8.91-1.02c-68.26-1.36-77.13-0.45-165.67-0.5v3.33',
        'C235.23,192.73,237.57,191.68,281.24,193.07z',
        'M359.34,384.42c-75.85-1.76-91.49-0.94-183.13-1.49v4.63c99.55,0.07,113.61,3.3,184.02-0.24',
        'C369.9,386.73,367.66,384.31,359.34,384.42z',
        'M394.4,208.77c8.24-0.75,15.91,1.29,24.3,0.91c5.28-0.02,70.08-0.04,131.71,0.12',
        'c5.55,0.01,16.53-0.88,16.53-0.88c-94.56-2.44-160.99,0.13-207.03-0.93c5.57,1.04,12.21,0.29,17.95,0.68',
        'C383.36,208.73,388.77,209.17,394.4,208.77z',
        'M220.34,217.28c-2.78-0.43-2.61-1.16-2.44-1.9c-0.14-0.02-16.88-0.03-41.68-0.04v2.75',
        'c25.71-0.09,43.31-0.16,43.92-0.2C220.86,217.7,220.93,217.38,220.34,217.28z',
        'M219.7,267.52c-0.51-0.08-17.95-0.15-43.49-0.2v1.54c25.51-0.07,43.38-0.15,45.26-0.23',
        'C222.42,268.04,221.08,267.75,219.7,267.52z',
        'M228.96,206.1c0.84-0.02,2.22,0.19,2.33-0.34c-12.85-0.65-27.62-0.03-55.08-0.25v0.6',
        'C206.35,206.13,227.74,206.13,228.96,206.1z',
        'M410.22,360.71c2.1,0.37,4.19,0.37,6.26,0C414.41,360.76,412.34,360.4,410.22,360.71z',
        'M303.99,359.2c16.41-0.62,32.94-1.13,49.33-1.13c12.3-0.26,24.12-1.28,36.04-2.09',
        'c2.5-0.17,4.25-0.88,3.95-1.39c-0.26-0.46-2.83-1.02-4.73-1.17c-20.33-1.58-41.28-0.45-61.68-0.8c-3.56,0.65-8.55-0.22-11.72,0.94',
        'c13.06-0.01,26.15-0.17,38.85,1.02c1.31,0.12,3.28,0.09,3.24,0.79c-0.04,0.55-1.04,0.82-2.61,1.06',
        'c-73.93,3.3-84.75,1.9-178.45,2.39v0.39C241.07,359.3,273.34,358.8,303.99,359.2z',
        'M399.58,220.06c-0.78,0-1.57,0-2.33-0.01c-0.95,0.45-3,0.02-3.91,0.46c6.28-0.15,12.43,0.36,18.67,0.27',
        'c-0.17-0.6-1.9-0.37-2.96-0.46C405.97,220.02,402.67,220.36,399.58,220.06z',
        'M298.07,348.1c-5.31,0-10.64-0.03-15.6,0.7C287.65,348.52,292.98,348.58,298.07,348.1z',
        'M415.14,221.01c1.1,0.4,2.57,0.18,3.91,0.24C417.95,220.85,416.48,221.07,415.14,221.01z',
        'M250.56,230.36c-6.07-0.77-12.57,0.16-18.69-0.01C238.11,230.8,244.34,230.64,250.56,230.36z',
        'M641.82,203.77c16.11,0.5,32.41,0.04,48.53-0.52c26.23-0.78,52.66-0.07,78.83-1.45',
        'c1.91,0.06,9.39-0.78,4.12-2.03c-33.05-3.7-67.12-2.59-100.48-3.51c-44.18-0.46-51.95-0.59-105.88-0.56v0.06',
        'c-33.27,0.02-58.31,0.07-87.76,0c16.84,0,65.23,7.98,87.76,7.99v0.02C602.75,203.77,631.62,203.77,641.82,203.77z',
        'M728.87,336.18c-7.33,0.03-14.7-0.07-22.08-0.11c-0.84,0.25-0.65,0.55-0.28,0.86c1.27,1.08,7.88,2.3,12,2.22',
        'c20.31-0.01,40.7,0.21,61.02-0.35v-2.68C754.31,336.14,748.82,336.22,728.87,336.18z',
        'M747.95,321.7c-11.49,0.02-23.35-0.44-34.81,0.18c-119.04-0.37-265.33-0.12-390.72,0',
        'c-61.32-0.02-70.35-0.41-146.21-0.24v7.26c112.6-2.31,221.49-1.73,330.45-0.48c-49.38,0.49-86.38-0.73-93.03,0.61',
        'c-0.02,0-0.04-0.01-0.06-0.01c-93.15-2.2-132.88,0.6-237.36,0.53v6.26c68.81,0.04,69.57,0.11,118.22,0.09',
        'c6.26-0.34,13.73,0.98,19.64-0.74c82.54,0.66,170.21,0.52,252.86,0.7v-0.05c68.81,0.04,69.57,0.11,118.22,0.09',
        'c6.26-0.34,13.73,0.98,19.64-0.74c24.84,0.84,49.83,0.08,74.74,0.39v-7.06c-100.9-0.59-216.48,1.84-327.28,1.05',
        'c108.65,0.19,223.06-3.36,327.28-2.07v-5.55C768.98,321.93,758.48,321.9,747.95,321.7z M278.44,332.84',
        'c-12.72,0.24-25.57-0.14-38.28,0.18c-0.13,0.1-0.05,0.14-0.08,0.22c-0.11-0.03-0.3-0.01-0.38-0.06',
        'c-5.41,0.03-10.8-0.09-16.18-0.16c2.21-0.08,2.54-0.19,0.62-0.33c18.53-0.08,37.03,0.21,55.54,0.13',
        'C279.27,332.82,278.85,332.84,278.44,332.84z M614.86,332.68c18.53-0.08,37.03,0.21,55.54,0.13c-13.13,0.29-26.39-0.12-39.51,0.2',
        'c-0.13,0.1-0.05,0.14-0.08,0.22c-0.11-0.03-0.3-0.01-0.38-0.06c-5.41,0.03-10.8-0.09-16.18-0.16',
        'C616.45,332.94,616.78,332.83,614.86,332.68z',
        'M738.54,192.92c-1.36-0.05-3.13-0.07-3.41-0.6c-0.07-1.26,6.84-0.71,6.37-1.89c-0.37-0.7-2.85-0.69-4.7-0.82',
        'c-70.07-1.79-80.07-0.55-169.88-0.7v0.14c-22.78,0.03-59.34,3.05-58.2,3.05c16.33-0.01,36.54-0.01,58.2,0.01v0.13',
        'c87.98-0.14,131.62,1.35,212.6,2.91v-1.17C765.8,193.79,752.22,193.37,738.54,192.92z',
        'M727.53,371.86c-11.9-0.34-23.77,0.34-35.71,0.21c-12.61,0.41-25.93-0.85-38.37,0.55',
        'c0.01,0.02,0.08,0.01,0.09,0.03c-136.2-1.61-281.72-1.86-390.81-0.03c0.01,0.02,0.08,0.01,0.09,0.03',
        'c-24.38,0.5-33.51-0.01-86.61-0.32v8.43c70.76-0.06,88.38,0.79,149.53,1.88c26.12-0.11,52.09,1.15,78.22,1.71',
        'c1.01,0.02,2.93-0.01,2.24,0.64c59.27-2.32,260.7,5.99,321.52,3.42c7.94,0.05,15.69-0.31,23.24-1.12c2.78-0.32,6.6-0.47,6.35-1.58',
        'c-0.26-1.19-4.21-1.19-7.25-1.31c-75.86-1.76-91.49-0.94-183.13-1.49c0,0-38.97,0.05-42.85-0.78',
        'c43.74-2.73,99.57-1.02,132.82-0.56c40.86,0.86,81.78,0.94,122.63,2.4v-12.38C762.16,371.79,744.89,371.64,727.53,371.86z',
        'M769.61,208.12c-6.34-0.09-12.67-0.03-18.99-0.14c9.35,1.12,19.43,0.41,28.91,0.95v-0.83',
        'C776.2,208.13,772.88,208.16,769.61,208.12z',
        'M610.85,217.89c2.38-0.93-3.21-0.29-2.24-2.51c-11.53-0.06-84.13-0.03-101.95-0.01v0.2',
        'c-47.98,0.02-88.67,0.06-89.94,0.01c-1.75-0.51-3.39-1.02-3.69-1.81c-0.22-0.66-0.58-1.32-0.97-1.98',
        'c-24.04-2.26-49.01-0.37-73.3-0.47c-3.07,0-7.72-0.18-8.78,1.01c-1.34,1.5-4.88,1.57-8.33,1.5c-16.71-0.23-33.51,0.84-50.19,1.25',
        'c-3.58,0.32-6.82-0.31-10.33,0.06c-10.56,1.02-21.67-0.5-32.28,0.31c17.04,0.82,34.31,0.39,51.44,0.27',
        'c26.31,0.89,52.76,1.24,79.17,1.14c-0.82,0.07-1.69,0.12-2.37,0.28c6.08,2.78,16,1,22.94,1.14c7-0.6,14.17,0.23,21.1-0.1',
        'c5.08,0.52,10.49-0.07,15.56,0.47c0.14,0,0.92-0.01,2.28-0.02C425.79,218.42,578.06,218.09,610.85,217.89z',
        'M612.19,268.63c0.95-0.6-0.39-0.88-1.77-1.11c-3.85-0.93-102.61,0.81-103.76,1.91',
        'C526.04,269.38,599.27,269.3,612.19,268.63z',
        'M752.74,233.97c-69.83-1.41-111.01,1.29-185.81,0.31c-187.35-0.06-228.4-0.91-390.72,0.2v1.76',
        'c202.99-0.39,397.26,0.19,603.32-0.13v-2.07C770.61,233.95,761.68,233.86,752.74,233.97z',
        'M724.34,242.59c-184.58,1.49-361.05,2.21-548.13,2.91v6.28c28.64,0.04,43.01-0.02,46.5,0.16',
        'c-1.55-0.04-20.05-0.07-46.5-0.09v9.5c25.04,0.06,41.98,0.12,42.19,0.2c-1.98,0-18.47-0.02-42.19-0.04v5',
        'c37.68,0.15,41.72-0.34,57.1,0.28c5.99-0.12,13.03,0.84,18.75-0.49c-0.9-0.81-3.3-0.77-5.4-0.81c-4.39-0.09-8.78-0.03-13.19-0.06',
        'c9.51-1.96,21.55-0.98,31.39-2.07c6.26-0.33,12.5-0.61,18.73-0.55c8.42-0.21,16.3,1.68,24.4,1.39',
        'c13.09,1.47,26.72,1.39,39.95,0.57c3.52-0.4,7.17-0.55,10.96-0.52c0.73,0,1.73-0.03,1.77,0.29c-1.62,0.77-4.47,0.54-6.41,0.92',
        'c-6.6,0.67-12.67,1.82-19.73,2.08c-0.28,0.16-0.5,0.32-0.78,0.47c3.11-0.16,6.24-0.32,9.34-0.46c-1.45,0.71-5.2,0.51-6.23,1.41',
        'c5.62,0.01,10.24-1.33,15.61-1.18c3.18,0.69,6.19-0.47,9.4-0.16c1.19-0.02,2.29-0.14,3.28-0.36c8.35-1.85,18.04-1.93,27.75-1.85',
        'c44.97-0.06,193.73,2.15,249.89,0.89c-0.9-0.81-3.3-0.77-5.4-0.81c-4.39-0.09-8.78-0.03-13.19-0.06',
        'c9.51-1.96,21.55-0.98,31.39-2.07c6.26-0.33,12.5-0.61,18.73-0.55c8.42-0.21,16.3,1.68,24.4,1.39',
        'c13.09,1.47,26.72,1.39,39.95,0.57c3.52-0.4,7.17-0.55,10.96-0.52c0.73,0,1.73-0.03,1.77,0.29c-1.62,0.77-4.47,0.54-6.41,0.92',
        'c-6.6,0.67-12.67,1.82-19.73,2.08c-0.28,0.16-0.5,0.32-0.78,0.47c3.11-0.16,6.24-0.32,9.34-0.46c-1.45,0.71-5.2,0.51-6.23,1.41',
        'c5.62,0.01,10.24-1.33,15.61-1.18c3.16,0.7,6.2-0.47,9.4-0.16c1.19-0.02,2.29-0.14,3.28-0.36c7.18-1.59,15.35-1.87,23.67-1.87',
        'v-21.04c-46.65,0.81-93.42,0.8-140.15,1.14c-1.73-0.06-42.15,0.16-77.11-0.07c-0.13,0-0.26-0.01-0.39-0.02l-4.82-0.43',
        'c97.76,0.03,137.03-0.02,222.47-1.71v-1.81C761.1,241.67,742.82,242.6,724.34,242.59z M566.93,251.77',
        'c28.64,0.04,43.01-0.02,46.5,0.16c-1.55-0.04-20.05-0.07-46.5-0.09c0,0-7.33,0.04-9.34,0.04',
        'C557.82,251.62,566.93,251.77,566.93,251.77z M566.93,261.34c25.04,0.06,41.98,0.12,42.19,0.2c-6.2,0.03-72.47-0.1-88.99-0.2',
        'H566.93zM761.18,358.09c-2.13-0.03-4.81-0.05-6.21,0.7c-21.96,0.99-44.3,0.71-66.29,1.36',
        'c30.29,0.02,60.52,0.56,90.84,0.54v-2.92C773.43,357.93,767.34,358.2,761.18,358.09z',
        'M622.01,205.77c-12.85-0.65-27.62-0.03-55.08-0.25v-0.02c-22.31,0-43.27-0.01-60.27-0.02V206',
        'c16.66,0.01,37.71,0.03,60.27,0.04v0.07C600.08,205.81,617.1,206.74,622.01,205.77z',
        'M763.35,352.63c-19.04,0.55-38.66-1.15-57.45,0.93c13.06-0.01,26.15-0.17,38.85,1.02',
        'c1.31,0.12,3.28,0.09,3.24,0.79c-0.04,0.55-1.04,0.82-2.61,1.06c-73.93,3.3-84.75,1.9-178.45,2.39v0.02',
        'c-22.8,0-43.71,0.01-60.27,0.01c0,0,37.58,0.31,60.27,0.32v0.03c103.12-0.71,129.68,1.72,212.6-3.17v-2.58',
        'C774.26,352.98,768.95,352.62,763.35,352.63z',
        'M688.78,348.1c-5.31,0-10.64-0.03-15.6,0.7C678.37,348.52,683.7,348.58,688.78,348.1z',
        'M641.28,230.36c-6.07-0.77-12.57,0.16-18.69-0.01C628.83,230.8,635.06,230.64,641.28,230.36z',
        'M769.35,178.03c-38.43-2.27-77.49-2.33-116.01-0.76c-9.79,0.23-116.52,0.64-146.68,2.32',
        'c-30.13,0.15-140.81-1.73-175.94-3.27c-64.1-0.31-68.49,1.82-154.5,1.58v7.92c163.64,0.23,202.43-0.02,390.72-0.11v0.11',
        'c83.6-0.3,133.95,0.55,212.6,0.07v-7.61C774.25,178.19,770.61,178.11,769.35,178.03z',
        'M758.46,210.85c-9.63,0.19-19.25,0.46-28.98,0.46c-3.07,0-7.72-0.18-8.78,1.01c-1.34,1.5-4.88,1.57-8.33,1.5',
        'c-16.71-0.23-33.51,0.84-50.19,1.25c-3.58,0.32-6.82-0.31-10.33,0.06c-10.56,1.02-21.67-0.5-32.28,0.31',
        'c17.04,0.82,34.31,0.39,51.44,0.27c26.31,0.89,52.76,1.24,79.17,1.14c-0.82,0.07-1.69,0.12-2.37,0.28',
        'c1.69,1.02,4.53,1.42,8.03,1.47c7.95,0.15,15.76-0.62,23.67-0.56v-7.24C772.52,210.88,765.46,210.71,758.46,210.85z',
        'M756.26,225.5c-21.94-0.87-43.87-1.18-65.8-1.73c-21.56-0.54-43.01,0.68-64.55,0.44',
        'c0.01-0.27-0.3-0.49-1.07-0.63c-1.97-0.25-3.94-0.19-5.89-0.04c-16.45-2.55-17.21-1.49-52.02-2.04',
        'c-46.48-0.07-172.61,2.58-201.38,4.01c-21.95-0.87-43.87-1.18-65.8-1.73c-21.56-0.54-43,0.68-64.55,0.44',
        'c0.01-0.27-0.3-0.49-1.07-0.63c-1.97-0.25-3.94-0.19-5.89-0.04c-16.74-2.55-17-1.49-52.02-2.04v9.13',
        'c75.15-0.48,82.41-1.24,129.97-0.88c-14.32,0.46-28.97-0.62-43.19,0.61c-1.01-0.32-11.38-0.68-10.83,0.48',
        'c39.83,0.75,79.58-0.47,119.42,0.31c60.21,1.29,245.84-1.68,325.32-1.39c-14.32,0.46-28.97-0.62-43.19,0.61',
        'c-1.01-0.32-11.38-0.68-10.83,0.48c45.57,0.72,91.06-0.55,136.64,0.52v-6.54C771.73,225.6,764.16,225.63,756.26,225.5z',
        'M739.49,307.25c-94.54-1.48-262.88-0.97-360.01,0.15c-82.52-0.57-104.91-1.17-203.27-1.09v4.42',
        'c210.12-0.66,406.52,0.14,603.32-0.38v-3.04C766.21,307.49,752.84,307.38,739.49,307.25z'
    )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library PlanetSurface1_2Descriptor {

  function getSVG() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        'M765.96,297.37c-9.19-0.19-18.47-0.01-27.66-0.08c-3.22-0.02-5.24,0.29-6.3,1.2',
        'c-18.26-0.61-36.45-0.67-54.73-0.32c-11.01,0.54-21.72-1.16-32.54-0.21c-31.15-3.17-38.03-1-77.8-1.83',
        'c-61.66-0.18-172.81,0.88-219.35,1.16c-3.22-0.02-5.24,0.29-6.3,1.2c-18.26-0.61-36.45-0.67-54.73-0.32',
        'c-11.01,0.54-21.72-1.16-32.54-0.21c-31.1-3.16-38.06-1-77.8-1.83v5.31c167.9-2.08,202.13,3.5,390.72,2.43',
        'c33.32-0.64,57.61-3.57,59.57-3.47c51.02,1.26,101.97,1.43,153.03,2.41v-5.8C775.07,297.23,770.6,297.48,765.96,297.37z',
        'M715.53,319.66c-181.08-1.51-358.56,0.62-539.32-0.59v1.85c180.88,0.03,392.92,0.04,603.32,0.07v-1.4',
        'C758.17,319.67,736.9,320.13,715.53,319.66z',
        'M699.07,312.31c-60.41-0.9-219.48-0.01-282.16,0.84c-94.26-0.96-135.18-1.16-240.7-1.26v4.99',
        'c201.33-1.12,402.93,0.81,603.32-0.79v-3.25C752.71,312.67,725.92,312.25,699.07,312.31z',
        'M769.57,231.58c-81.35-1.54-136.92,0.77-225.26,1.02c-175.06-0.11-212.19-2.6-368.1-0.41v1.19',
        'c163.78-0.78,199.65,0.26,390.72,0.39c86.43-0.47,132.35-1.39,212.6-0.34v-1.65C776.21,231.83,772.88,231.76,769.57,231.58z',
        'M758.22,287.28c-7.15-0.13-14.38-0.21-21.46-0.71c-3.22-0.72-7.53-0.52-10.52-1.29',
        'c-1.62-0.41-3.33-0.54-5.42-0.45c-2.12,0.1-4.92,0-5.37-0.61c-1.16-1.41-4.86-1.83-8.24-2.45c-4.4-0.8-9.04-1.48-13.53-2.2',
        'c-4.27,0.47-8.62,0.24-12.97,0.46v0.01c2.91,0.36,4.1,1.2,5.96,1.89c2.65,0.98,2.27,2.61,7.25,3.07c0.34,0.86,3.41,0.5,4.7,0.95',
        'c-2.7,0.14-5.2-0.28-7.83-0.25c0,0.16-0.02,0.32,0,0.47c-8.31-0.25-16.61-0.96-24.94-2.14c-9.24-1.74-19.72-1.18-29.2-1.83',
        'c-3.55,0.99-24.23-0.66-21.47,3.69c-65.55-1-193.55,1.58-247.69,1.39c-10.6-0.16-21.62-0.31-31.98-2c-2.53-1-8.95,0.24-10.79-1.06',
        'c-1.16-1.41-4.86-1.83-8.24-2.45c-4.4-0.8-9.04-1.48-13.53-2.2c-4.27,0.47-8.62,0.24-12.97,0.46v0.01c2.91,0.36,4.1,1.2,5.96,1.89',
        'c2.65,0.98,2.27,2.61,7.25,3.07c0.34,0.86,3.41,0.5,4.7,0.95c-2.7,0.14-5.2-0.28-7.83-0.25c0,0.16-0.02,0.32,0,0.47',
        'c-8.31-0.25-16.61-0.96-24.94-2.14c-9.24-1.74-19.72-1.18-29.2-1.83c-3.55,0.99-24.23-0.66-21.47,3.69',
        'c-12.34-0.06-19.48-0.3-48.26-0.29v7.69c26.33,0.04,44.56,0.09,45.6,0.18c4.42,0.36,8.54-0.33,10.97-1.59',
        'c16.31-0.11,32.46,0.32,48.74-0.21c1.05,0,2.69,0.01,2.68-0.55c14.25,1.21,28.95,0.52,43.23,0.27',
        'c31.08,2.31,62.08,1.76,93.18,1.59c15.25,0.14,166.68,0.23,191.93,0.49c4.42,0.36,8.54-0.33,10.97-1.59',
        'c16.31-0.11,32.46,0.32,48.74-0.21c1.05,0,2.69,0.01,2.68-0.55c14.25,1.21,28.95,0.52,43.23,0.27',
        'c20.54,1.37,40.85,2.01,61.39,1.75v-5.88C772.42,287.37,765.32,287.46,758.22,287.28z',
        'M736.75,340.04c-1.55-0.06-3.13-0.08-4.59,0.14c-0.14,0.09-0.08,0.13-0.13,0.2',
        'c-4.09-0.48-8.63-1.37-12.78-0.43c0-0.03,0.01-0.06,0-0.09v-0.01c-12.89-2.3-26.57-2.77-40.26-0.96',
        'c-17.17,0.33-34.69-0.9-51.73,0.43c-11.98-0.05-97.37-0.09-120.61-0.11c19.94,1.41,110.47,2.01,130.56,1.4',
        'c0.02-0.06-0.08-0.08-0.09-0.13c0.06,0.02,0.18,0.01,0.23,0.04c12.92,0.81,26.13,0.94,39-0.21c-1.47,0.38-2.91,0.76-4.38,1.13',
        'c-0.6,0.14-1.6,0.19-1.27,0.5c2.68,0.75,6.11-0.08,8.76-0.19c11.1-0.55,22.38-0.44,33.57-0.68c-3.35,0.92-8.48-0.36-11.75,0.68',
        'c5.15,0.79,10.98,0.58,16.42,0.96c-0.01,0.01,0,0.02-0.01,0.02c-12.19-0.66-24.89-0.91-36.7,0.29',
        'c-10.03,0.84-19.96,1.4-30.13,0.38c-10.17-1-20.68-1.06-31.12-1.04c-67.6-0.44-189.96,3.38-228.87-0.6',
        'c-0.04-0.26-0.6-0.43-1.36-0.52c-2.85-0.37-5.7-0.75-8.95-0.74c-13.06,0.3-26.17-0.56-39.14-0.3c-0.14,0.09-0.08,0.13-0.13,0.2',
        'c-4.09-0.48-8.63-1.37-12.78-0.43c0-0.03,0.01-0.06,0-0.09v-0.01c-12.89-2.3-26.57-2.77-40.26-0.96',
        'c-17.17,0.33-34.69-0.9-51.73,0.43c-4.28-0.01-26.79-0.06-60.34-0.07v1.5c45.77-0.13,40.62,0.17,70.29-0.15',
        'c0.02-0.06-0.08-0.08-0.09-0.13c0.06,0.02,0.18,0.01,0.23,0.04c12.92,0.81,26.13,0.94,39-0.21c-1.47,0.38-2.91,0.76-4.38,1.13',
        'c-0.6,0.14-1.6,0.19-1.27,0.5c2.68,0.75,6.11-0.08,8.76-0.19c11.1-0.55,22.38-0.44,33.57-0.68c-3.35,0.92-8.48-0.36-11.75,0.68',
        'c5.15,0.79,10.98,0.58,16.42,0.96c-0.01,0.01,0,0.02-0.01,0.02c-12.19-0.66-24.89-0.91-36.7,0.29',
        'c-10.03,0.84-19.96,1.4-30.13,0.38c-27.74-2.08-55.84-0.62-83.95-1.06v2.99c42.66-0.59,67.08,0.99,106.59,2.01',
        'c4.99,0.18,10.8-0.17,15.65,0.8c13.47,1.03,27.74-0.8,41.22,0.62c4.73,0.35,8.53,1.11,9.88,2.67c3.07,0.5,6.78,0.74,9.91,0.03',
        'c67.36,1.22,75,0.46,182.29,0.84c8.45,0.01,12.7-1.27,2.23-2.69c-7.63-1.03-14.2-2.12-14.13-2.83c17.81-2.97,60.84-0.8,73.79-1.45',
        'c23.61-0.15,46.23,1.89,69.87,2.02c5.01,0.18,10.79-0.17,15.65,0.8c13.47,1.03,27.74-0.8,41.22,0.62',
        'c4.73,0.35,8.53,1.11,9.88,2.67c3.07,0.5,6.78,0.74,9.91,0.03c9.57,0.98,19.65,0.11,29.34,0.42v-10.71',
        'C765.5,339.69,750.83,340.92,736.75,340.04z',
        'M749.22,361.85c-116.66-2.38-277.85,0.41-390.72,0c-68.67-0.79-108.18-1.14-182.29-1.03v3.93',
        'c49.43-0.02,98.15,0.64,147.46,1.11c8.29,1.82,17.69,0.62,26.26,1.16c45.96,0.16,72.9-0.04,156.73,0.08',
        'c-107.23,1.95-218.25-0.37-330.45-0.8v3.17c195.72-0.37,397.27,0.21,603.32-0.27v-1.32c-51.82-0.48-103.78,0.09-155.52-1.6',
        'c-10.13-0.55-81.62,1.26-100.16-0.99c4.77-1.1,43.08-0.53,43.08-0.53c49.43-0.02,98.15,0.64,147.46,1.11',
        'c8.28,1.82,17.69,0.62,26.26,1.16c13.72,0.31,24.6-0.09,38.88,0.02v-4.98C769.43,361.92,759.33,361.75,749.22,361.85z',
        'M298.12,244.63c103.56-1.38,125.27-2.5,259.26-2.41c3.2-0.01-12.52-1.47-23.75-1.43',
        'c-169.42-0.08-202.44,2.9-357.42,2.9v1.28C247.68,244.9,249.8,245.08,298.12,244.63z',
        'M566.93,355.97c-113.46,0.97-141.12-0.44-202.67,2.82c-21.96,0.99-44.3,0.71-66.29,1.36',
        'c36.39,0.01,72.78,0.78,109.17,0.55c-0.98-0.96-5.36-0.46-6-1.24c19.02-3.41,82.58-0.22,165.79-1.41V355.97z',
        'M327.79,339.14c30.1,0.1,60.43-0.12,90.48-0.46c-4.02-0.75-61.94-3.23-80.12-2.5',
        'c-7.32,0.03-14.7-0.07-22.08-0.11c-0.84,0.25-0.65,0.55-0.28,0.86C317.05,338.01,323.67,339.23,327.79,339.14z ">'
    )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;


library PlanetSurface2_1Descriptor {

  function getSVG() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<path class="clip_path" d="M342.24,298.94c3.41,3.93-6.57-17.79-6.4-10.05C338.66,290.99,339.28,296.7,342.24,298.94z',
        'M362.76,191.44c0.35,0.07,0.03-0.55-0.22-0.42C362.59,191.41,362.69,191.53,362.76,191.44z',
        'M388.81,206.8c2.07-1.14,0.75,1.69,1.34,2.38c2.88-2,2.26-2.17,5.94-0.62c4.62-0.41-2.14-2.95-3.49-2.45',
        'c6.4-11.78-16.64-14.98-25.24-13.7c-2.97,0.73-2.32,1.74-1.05,2.71C378.81,196.05,375.55,210.39,388.81,206.8z M391.05,201.87',
        'c1.74,0.1,1.64,3.16-0.19,2.64C390.96,203.72,390.01,202.21,391.05,201.87z',
        'M315.37,291.47c-1.68,1.71,2.93,2.52,2.57,0.47C317.1,292.03,316.24,291.39,315.37,291.47z',
        'M380.13,341.48c-0.07-0.02-0.14-0.11-0.21-0.11C380.19,341.54,380.19,341.49,380.13,341.48z',
        'M383.31,339.52c0.4-2.07-3.03-3.76-4.19-2.72C376.55,339.69,382.33,344.57,383.31,339.52z',
        'M317.13,280.17c-3.05-0.55-1.8,5.6,0.95,7.04C321.01,287.04,318.01,283.06,317.13,280.17z',
        'M357.36,238.2c0.01-0.04,0.03-0.09,0-0.14C357.36,238.11,357.36,238.16,357.36,238.2z',
        'M338.8,210.83c-8.63,2.94,2.58,0.75,5.88-0.48c-2.9,1.38-13.58,9-9.81,1.72',
        'c-12.05-8.17-18.39,49.79-6.68,54.87c1.95-30.1,0.52-19.9,10.92,0.05c3.72-2.67,3.72-15.44,7.48-4.9',
        'c14.12-1.96,19.68-16.8,23.22-30.43c-2.35,13.49,10.9-7.61,1.31-4.39c7.78-40.88-9.55-12.09-16.81-19.89',
        'C348.53,204.99,353.13,208.81,338.8,210.83z M371.01,227.79c0.29,0.46-0.22,0.71-0.4,1.35',
        'C370.74,228.69,370.88,228.24,371.01,227.79z M330.22,230.3c-0.69,3.63-2.65,15.46-2.78,15.33c-0.29-5.6,4.19-27.04-3.59-14.52',
        'c1.04-3.13,2.62-5.57,4.18-8.14c1.65-3.4,3.55-12.21,4.08-4.29C338.39,216.12,327.26,224.24,330.22,230.3z M350.67,211.89',
        'c-0.63,6.11-9.31,4.8-10.1,11.52c4.94,0.35,0.54,2.79,1.99,6.96c1.93,6.41,9.5,11.51,10.87,3.74c0.39,17.1-19.09-2.26-12.63-11.46',
        'c-3.46-0.4-5.24,10.33-4.45,11.62c6.32-1.05,5.2,15.19,12.3,7.91c-4.66,15.44,12.57,2.65,8.8-3.96c2.46,2.82,1.42-3.89,0.17-2.29',
        'c-1.51,0.71,3.55-9.87-0.88-2.01c-0.43-15.78-6.92-3.91-9.16-12.09c-2.17,0.17-4.42,1.19-1.36-1.31c6.12-2.12,9.31-7.61,12.5,0.66',
        'c5.79-4.26-0.05,4.87,2.39,9.69C377.21,285.24,293.17,228.61,350.67,211.89z',
        'M332.12,319.33c0.03-0.06,0.06-0.1,0.09-0.14C332.14,319.1,332.1,319.12,332.12,319.33z',
        'M332.21,319.19c0.25,0.29,1.35,2.86,1.75,2.8C335.49,321.7,333.17,317.08,332.21,319.19z',
        'M378.68,277.96c0.96,1.96,1.88-2.35,0.3-1.62C378.85,276.82,378.71,277.16,378.68,277.96z',
        'M220.06,325.2c-5.58-3.12-9.37,7.32-2.94,7.06C222.1,331.57,229.61,321.71,220.06,325.2z',
        'M305.58,210.43c-14.67,13.41-14.45,60.68-5.4,41.48c-0.13,0.95-0.2,2.93-0.02,2.96',
        'c8.1-20.06-0.22-12.57,12-34.63c-15.45,38.04,9.6-18.38,30.17-20.98C333.76,189.43,313.9,200.8,305.58,210.43z M300.38,251.15',
        'c0.34-2.32,1.04-4.55,1.95-6.65C301.75,246.77,301.16,249.04,300.38,251.15z',
        'M324.26,267.57c-1.74-7.96-6.86,0.84-4.15,4.09C322.07,272.24,325.41,270.99,324.26,267.57z',
        'M249.9,226.48c2.6-0.11,0.58-6.75-0.87-2.96C249.78,224.17,248.75,226.46,249.9,226.48z',
        'M241.62,257.35c0.42,1.73,3.91,0.89,3.21-1.03C243.75,256.11,241.81,255.06,241.62,257.35z',
        'M202.99,293.24c-2.69,0.9,0.95,4.93,1.12,1.28C204.03,293.83,203.05,293.19,202.99,293.24z',
        'M305.59,257.98c-0.17,1.25,1.13,3.5,2.1,3.59C310.01,261.57,307.02,257.11,305.59,257.98z',
        'M328.45,316.59c-0.99-2.43-3.17-8.86-6.37-6.92C321.94,312.89,325.48,322.7,328.45,316.59z',
        'M325.07,329.86c2.95,5.31,1.17-3.29-0.56,0.54C324.64,330.28,324.74,330.11,325.07,329.86z',
        'M362.18,369.81c-0.82-3.75-5.1-5.44-5.68-0.9C357.1,372.93,363.47,376.6,362.18,369.81z',
        'M366.26,368.6c-0.61-0.02-2.68,0.09-1.2,0.19C365.83,370.82,368.07,370.83,366.26,368.6z',
        'M380.79,344.07c-0.85,0.09-1.71-0.55-2.58-0.47C376.58,345.33,381.15,346.13,380.79,344.07z',
        'M380.22,341.48c-0.07-0.02-0.14-0.11-0.21-0.11C380.29,341.54,380.29,341.49,380.22,341.48z',
        'M380.78,376.55c-1.24-0.03-0.9,2.02,0.32,1.51C381.8,377.83,381.15,376.87,380.78,376.55z',
        'M387.47,229.74c-1.05,3.12-2.76,5.65-2.16,8.81C387.74,236.76,388.72,232.36,387.47,229.74z',
        'M377.36,378.97c-2.11,0.85-4.07-1.21-5.19,2.15C373.06,381.54,380.53,381.16,377.36,378.97z',
        'M315.86,252.82c1.47-2.59,3.59-20.86-3.45-12.92C309.24,245.15,309.24,268.83,315.86,252.82z',
        'M316.84,233.03c3.43,2.33,3.87-6.03,1.09-5.67C315.92,227.4,316.48,231.34,316.84,233.03z',
        'M337.91,309.16c2.59,0.03,1.83-0.77,0.9-2.76C336.28,306.17,335.65,307.87,337.91,309.16z',
        'M363.97,310.19c0.12,0.15,0.23,0.25,0.34,0.33C364.21,310.37,364.09,310.3,363.97,310.19z',
        'M388.81,331.12c4.07-4.7-4.55,3.79-6.16-1.66c-5.93-5.97,12.95-4.55,9.62-14.26',
        'c-2.9,5.73-5.98,11.59-12.92,5.41c-25.07-17.24-1.66-6.09-9.57,11.6C370.41,337.15,384.97,333.24,388.81,331.12z M371.19,315.87',
        'c3.55,1.27,11.8,11.64,5.89,13.85C370.55,329.68,374.99,322.12,371.19,315.87z',
        'M362.8,308.85c-3.71-4.52-8.83-2.68-10.74-10.24c3.94-4.8-3.21,1.21-5.63-1.16',
        'c-4.79-1.96-2.78-7.61-3.41-11.85c-4.98,7.1-5.88-19.27-10.85-18.18c-1.94-10.63-5.95,6.35-2.81,11.66',
        'c-0.11,2.75,5.67,14,4.77,6.48c-2.64-2.79-2.21-10.65-5.03-13.45c8.49-8.72,9.11,21.8,15.96,25.05',
        'C346.7,300.35,360.53,308.54,362.8,308.85z',
        'M375.66,329.08c0.74-0.35,0.04-0.88-0.25-1.56C374.13,327.53,374.34,329.54,375.66,329.08z',
        'M345.35,248.98c0.02-0.01-0.15-0.04-0.11,0.01C342.19,251.42,350.1,251.96,345.35,248.98z',
        'M384.11,228.12c-5.03,3.15-6.97-15.96-9.84-21.41c13.15,44.06-4.34,50.54-33.37,62.35',
        'c-2.72,4-3.52,0.13-4.25-2.86c-3.46,10.93,3.59,6.21,8.42,4.34c6.75,5.18,10.06-10.98,12.08-9.55',
        'C372.86,267.09,381.68,243.61,384.11,228.12z',
        'M344.65,330.31c-5.51-6.14-11.82-2.48-12.41,4.58C336.23,340.49,350.4,337.92,344.65,330.31z',
        'M330.51,334.79c-0.21-1.59-1.33-1.9-1.87-0.65C327.64,336.95,332.37,337.2,330.51,334.79z',
        'M357.89,201.01c-3.1,0.01-6.14,2.25-6,5.1C353.87,203.96,356.52,204.1,357.89,201.01z',
        'M335.94,363.02c-0.67,0.73,6.47,8.92,4.32,4.64C339.24,366.66,337.82,362.82,335.94,363.02z',
        'M335.09,359.58c0.94-0.54-0.59-3.36-1.27-2.84C334.18,356.68,334.52,359.37,335.09,359.58z',
        'M379.83,306.13c0.46-0.04-0.37-2.73-0.66-2.76C378.8,303.97,379.3,305.46,379.83,306.13z',
        'M376.1,282.57c-2.79,0.83-3.23,10.97-0.27,9.12C376.11,289.17,377.17,284.66,376.1,282.57z',
        'M376.96,282.12c0.42,0.22,0.98,0.5,1.36-0.1C378.89,280.88,376.82,280.93,376.96,282.12z',
        'M378.42,277.09c-2.1-4.23-5.41,4.69-2.3,3.37C377.81,280.23,378.86,278.71,378.42,277.09z',
        'M343.52,276.72c-1.26,0-0.71,2.15-0.23,2.9C344.54,281.45,344.67,277.41,343.52,276.72z',
        'M298.27,348.36c7.57-9.12,10.71,1.42,15.94,5.08c20.38-0.24,8.2-1.42,1.29-9.08',
        'C320.25,328,275.97,348.66,298.27,348.36z',
        'M292.32,280.38c15.81-19.15-1.34,29.62,15.26,32.39c15.66-7.69,1.56-37.3,0.39-44.14',
        'c-2.34-11.86-6.45-9.54-8.44,0.92c-9.05,5.41-14.9,10.23-16.67,23.99c-0.09,11.94-8.17,2.41-12.32,7.69',
        'c-14.1,41.53-3.82,29.41,10.21,69.42c16.15-15.12-26.97-38.41-5.73-63.21c9.14,2.41,10.09-17.97,11.85-15.03',
        'c0.78,1.18,2.05-0.3,1.37-1.61C285.33,287.04,288.36,282.59,292.32,280.38z M264.53,332.14c-2.54-2.57-2.1-8.32,0.81-10.8',
        'C265.18,323.93,269.47,333.31,264.53,332.14z M268.18,335.06c0.23,3.28-2.43,1.24-2.3-0.85',
        'C266.39,333.09,268.03,333.87,268.18,335.06z M273.74,305.84c1.63-1.85,4.05-0.22,5.88-1.45',
        'C277.87,305.73,275.69,306.04,273.74,305.84z',
        'M277.12,215.84c0.91,0.46,3.26-0.05,2.66-1.78C278.59,213.26,275.26,213.77,277.12,215.84z',
        'M272.1,355.03c-0.2-0.03-1.56,1.07-1.05,1.01C271.62,356.96,273.26,356.01,272.1,355.03z',
        'M267.33,358.83c-0.11,0.81-1.92,3.42-1.05,3.63C268.31,362.78,270.36,359.4,267.33,358.83z',
        'M250.86,345.24c-0.61-0.1-1.35,1.1-0.73,1.56C249.58,352.9,253.98,346.68,250.86,345.24z',
        'M248.36,327.65c-4.88,1.43,4.17,9.74,0.39,3.77C247.17,330.55,248.92,328.53,248.36,327.65z',
        'M229.93,329.06c0.47,0.45,0.6,1.82,1.34,1.38C231.97,330.04,230.15,327.52,229.93,329.06z',
        'M223.76,236.81c-1.16,1.99-3.72,7.23-0.68,7.88C227.83,245.71,227.86,238.19,223.76,236.81z',
        'M218.59,240.2c-1.19,0.4-0.72,3.27,0.01,4.01C221.06,245.98,219.89,240.87,218.59,240.2z',
        'M176.31,279.24c-0.89,8.56,4.07,4.69,9.92,1.39c5.04-1.91,14.43,3.29,13.29-4.83',
        'c-0.23-2.01-3.05-4.93-3.05-4.93c3.31-11.16,2.06-1.95,10.08-3.23c-15.05-10.46-4.82,3.36-16.8,3.53c-0.24,2.35,3.99-0.2,4.81-0.2',
        'c3.81,2.28,3.68,7.29-2.21,7.64C188.05,276.41,179.56,283.81,176.31,279.24z',
        'M186.63,265.33c-2.04,5.83,20.2-1.43,3.61-5.38c-4.12-1.16-3.04,2.93-3.05,4.38c1.63-4.17,4.16-1.06,7.12-1.6',
        'C196.66,268.38,186.18,264.63,186.63,265.33z',
        'M233.54,358.39c-7.73-7.48-21.46-3.91-30.58-11.7c0,0,14.4,3.87,14.4,3.87',
        'c-17.08-16.31-28.59,4.71-32.32-32.1c0.18-6.29,11.46-5.62,11.47-11.03c-5.03,2.84-8.27,3.51-13.48,7.3',
        'c8.6-22.04,28.69-9.61,44.43-15.68c-2.27,8.56,5.38,1.82,5.12,2.53c4.85,5.41-16.48,13.33-16.31,18.01',
        'c1.01-0.52,9.96,7.74,7.89,1.95c1.46-7.77,9.13-7.26,16.59-13.72c15.04-10.86,8.64-13.3,24.78-17.6',
        'c29.54,25.92,11.4-59.42-0.09-2.61c-20.49,4.53-24.05,23.82-28.13,14.09c-4.35-10.79,3.66-3.88,4.31-9.86',
        'c-13.89-15.29-1.91-5.49-7.13-15.21c-5.63,4.18-8.92,1.04-1.2-1.01c3.36-1.43,8.48-14.84,1.88-12.3',
        'c-5.56,16.96-22.25-3.62-29.96-10.06c-9.63,2.37-3.2-13.68-10.74-7.66c-2.74-0.08-5.66-0.47-5.91-4.91',
        'c-2.02-16.7-7.08-6.5,9.1-22.05c7.19-7.6-1.55-1.36-3.81,0.95c6.32-9.27,6.7-9.36,15.54-6.82c30.34-0.69-1.43-12.63,18.14-6.31',
        'c23.64,11.74,27.5-1.3,37.5,25.19c-15.19,17.08-35.63-4.29-50.26-4.8c12.91,8.54,40.09,16.29,41.69,41.09',
        'c-0.63-7.73-3.43-16.66-0.76-24.58c44.13-0.53,26.32-34.77,61.37-50.18c-4.94-10.31-31.43,21.65-40.98-4.85',
        'c-3.33-28.22,0.41,33.71-10.36,42.65c-2.86-12.35-8.68-22.69-21.66-24.92c29.93,5.29-3.67-10.62-14.84-12.72',
        'c-45.84-14.65-30.58,4.83-50.18,7.93c0.84-5.17,12.42-7.05,9.17-10.28c-14.69,4.06-12.26,17.68-11.93,30.75',
        'c-0.23,11.25,3.62,0.27,2.01,15.02c-0.6-1.99-2.31-2.41-2.04,0.04c4.48,0.3-3.66,4.17,5.93,6.02',
        'c51.96,31.97,15.36,50.48,48.61,41.81c30.49,24.24-66.89,6.81-49.17,12.36c9.5,1.81-0.26,5.23-1.5,9.19',
        'c4.12,2.96,9.82-2.81,7.88-7.27c11.25,1.2-1.17,4.2-5.73,14.73C156.1,329.16,214.92,379.66,233.54,358.39z M252.49,245.63',
        'c-2.37,3.28-8.25-6.1-6.77-6.37C245.81,235.43,254.44,243.18,252.49,245.63z M270.05,227.25c5.96-7.06,1.9-34.2,15.25-24.67',
        'C311.72,198.93,261.44,265.48,270.05,227.25z M206.36,204.3c-1.61,3.77-30.13,21.23-12.18,16.38',
        'C166.09,236.4,213.64,197.24,206.36,204.3z M236.76,208.5c-1.21-0.18-3.35-0.34-4.16-1.32',
        'C233.61,206.55,239.28,208.02,236.76,208.5z M194.32,194.76c17.25-6.22,51.28,2.86,55.5,10.42c-5.17,2.18-18.58-9.85-11.29-0.26'
    )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;


library PlanetSurface2_2Descriptor {

  function getSVG() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        'c-4.32,1.77,15.89,4.99,17.8,8.66c-14.58-7.28-10.94,1.1-19.7-7.02c-7.45-3.98-23.25-0.66-6.29-6.62',
        'C221.87,192.33,201.35,194.63,194.32,194.76z M199.24,197.44c5.2-5.24,36.12,1.49,16.72,4.78',
        'C208.5,200.56,179.71,214.64,199.24,197.44z M183.79,224.9c-2.77,3.29-1.98-9.71-6.48-9.7c-1.22-3.52,1.31-9.25,3.97-11.51',
        'c4.7-2.1,6.16,12.8,7.54,5.5C193,180.9,193.01,214.87,183.79,224.9z M221.29,276.7c-0.34-0.16-0.76-2.79-0.99-2.77',
        'C216.41,275.62,221.46,269.24,221.29,276.7z',
        'M258.55,378.18c-7.94-9.24-30.11,2.56-41.94-3.31c8.65-3.85,5.34-1.48-5.73-5.13',
        'c-23.09-6.14-9.59,5.52-25.67,8.45C181.08,382.34,297.46,386.17,258.55,378.18z',
        'M322.72,372.15c-11.16,1.63-19.76,11.45-28.41,9.05c2.8,3.94,30.83-0.91,31.62-4.22',
        'C340.7,381.92,333.78,373.96,322.72,372.15z',
        'M335.81,379.16c0.72,0.61,1.27,0.97,1.57,0.83C337.77,379.82,337.05,379.52,335.81,379.16z',
        'M388.92,222.02c-0.62-1.99-2.43-2.94-2.82-0.44C386.26,229.86,391.18,229.49,388.92,222.02z',
        'M388.81,229.32c-0.88-0.62-0.5,1.12-0.3,1.44C389.14,230.64,389.34,229.84,388.81,229.32z',
        'M391.78,215.61c4.96,7.96,4.54-9.53-0.64-4.29C393.65,213.48,395.63,215.37,391.78,215.61z',
        'M398.04,304.28c8.05,18.11,26.85-0.79,18.67-10.79C402.01,294.31,396.52,275.52,398.04,304.28z',
        'M407.19,287.04c0.23,0.45,1.04,0.46,2.53,1.01C412.84,285.84,407.13,283.22,407.19,287.04z',
        'M413.72,323.31c0.41-1.58,0.88-6.58-1.06-6.14C411.04,319.31,409.29,325.02,413.72,323.31z',
        'M396.07,338.19c5,5.36,12.48-1.23,8.73-7.55C403.09,338.27,397.29,332.93,396.07,338.19z',
        'M410.66,213.63c1.25,0.12,0.79-0.98,0.14-1.6C409.91,212.07,409.67,213.64,410.66,213.63z',
        'M399.97,284.71c1.25,0.12,0.79-0.98,0.14-1.6C399.21,283.15,398.99,284.71,399.97,284.71z',
        'M496.9,320.91c-0.48,0.94,0.35,1.2,1.18,1.57C500.1,322.45,498.11,319.73,496.9,320.91z',
        'M501.34,292.75c14.81,3.97,20.42,0.4,12.04-14.39C503.76,269.95,496.47,286.26,501.34,292.75z',
        'M543.36,203.98c0.61,0.02,2.68-0.09,1.2-0.19C543.79,201.76,541.55,201.75,543.36,203.98z',
        'M496.12,322.01c-0.02,0.02-0.05,0-0.09-0.03C494.43,320.08,495.59,325.53,496.12,322.01z',
        'M493.51,224.47c1.3-0.77,2.84-2.2,3.07-4.01C495.63,221.62,492.27,222.42,493.51,224.47z',
        'M529.79,266.44c-0.46,0.04,0.37,2.73,0.66,2.76C530.82,268.6,530.32,267.11,529.79,266.44z',
        'M533.51,292.11c-1.7,0.23-2.74,1.77-2.3,3.38C533.32,299.72,536.61,290.8,533.51,292.11z',
        'M540.27,374.13c-10.13-15.91-56.7-0.15-29.43,7.42c7.93,9.78,27.17,15.24,25.59-1.72',
        'c2.16-0.45,2.75,3.27,3.09,4.82C541.1,382.34,545.94,376.1,540.27,374.13z',
        'M390.76,325.77c1.78,3.46,3.54-3.56,0.97-1.25C391.1,324.53,390.27,326.31,390.76,325.77z',
        'M410.82,209.06c6.06-0.62,16.28,4.06,27.6,4.04c12.3,1.28,18.76-11.27,20.41-0.48',
        'c-0.12,3.23,0.42,8.03-5.01,5.2c-3.37,0.3-1.58,5.27,0.33,8.52c25.24,35.85-7.72-8.62,7.56-5.62',
        'c35.16,8.78,48.05,33.14,85.85,28.02c-8.42-5.33-57.52,1.29-34.32-13.35c-2.15-4.19-9.87-2.64-9.34,3.03',
        'c-12.24-6.93,11.06-5.49,9.2-12.49c-9.94,11.22-24.11,5.2-34.11-2.97c-31-8.29-11.36-12.24,3.92-17.89',
        'C461.59,201.77,430.48,212.83,410.82,209.06z',
        'M553.81,353.42c-0.52-2.7-10.27,5.93-4.68-0.33c-0.69-2.82,5.66-6.73-1.03-6.18',
        'c3.48-9.16-16.37-7.19-10.83-7.79c0.18-2.78-4.71-1.64-2.63,0.65C521.47,340.06,540.28,378.52,553.81,353.42z',
        'M499.19,322.19c-1.56,4.03,6.01,2.75,6.43-0.01C503.66,321.95,501.14,321.02,499.19,322.19z',
        'M529.96,236c0.89-3.02-1.61-8.24-3.65-2.94C525.91,234.9,528.83,236.52,529.96,236z',
        'M496.13,322.01c0.02,0.06,0.01-0.03,0.01-0.05C496.14,321.99,496.13,321.97,496.13,322.01z',
        'M535.35,287.9c0.46-1.48,0.94-9.22-1.56-7.02C533.38,283.19,531.73,293.67,535.35,287.9z',
        'M530.94,294.61c-0.96-1.96-1.88,2.35-0.3,1.62C530.77,295.74,530.91,295.43,530.94,294.61z',
        'M524.92,286.8c1.69-2.71-1.08-2.92-3.19-4.16C514.53,280.81,520.68,291.54,524.92,286.8z',
        'M499.04,328.48c-0.2-0.2-0.45,0.04-0.6-0.03C496.29,331.69,500.89,331.64,499.04,328.48z',
        'M494.64,362.69c-44.23,11.28-11.1-58.82-21.91-84.73c2.62,25.88-9.79,58.55-30.22,74.8',
        'c-9.89-6.87-17.84,2.22-24.29,9.65c9.99-31.06,29.22-5.42,33.71-45.77c2.4,4.29-0.35,11.72,0.58,16.72',
        'c16.82-15.94,23.59-85.82-9.63-95.19c2.88-9.1-10.16-12.96-18.54-11.81c3.26-5.56-2.51-3.04-4.2-2.38',
        'c-26.28,2.95-40.02,22.83-43.37,48.49c7.26-30.12,2.84,65.35,15.5,13.56c9.61-1.45-16.55-29.19-3.45-39.17',
        'c13.27-16.1,41.67,16.27,49.09,18.08c-6.2-1.05-2.03,5.48-3.58,9.24c-2.49,6.54,8.57,12.18,8.71,18.03',
        'c7.21-9.84,4.1-7.61,4.47,3.25c-8.41,23.52,3.58,29.35-9.25,44.04c-10.14-2.27-25.19,11.29-33.04,1.77',
        'c-15.06,1.78-6.77,4.79-16.38,12.62c-12.07,9.24,0,12.13,9.63,15.52c33.8-6.34,36.87-26.7,57.41,7.6',
        'c-2.73-23.57-14.81-18.26,3.9-40.47c13.51-26.24,4.81,23,21.11,50.11C506.82,391.04,463.94,373.06,494.64,362.69z M489.44,365.58',
        'c-0.18,0.15-0.37,0.28-0.56,0.39C489.07,365.85,489.26,365.71,489.44,365.58z M488.82,366c-1.41,0.74-2.77,2.18-4.33,2.18',
        'C486.04,367.85,487.39,366.79,488.82,366z M384.34,251.65c0.46-1.5,1.32-2.49,2.16-3.13',
        'C385.79,249.47,385.07,250.52,384.34,251.65z M393.89,235.71c-0.57-0.23-0.41-1.49,0.25-1.38',
        'C396.9,229.57,397.06,236.74,393.89,235.71z M409.46,238.84c0.29-5.9-9.33-3.88-12.73-3.22c6.53-13.01,11.87,1.32,23.28,0.62',
        'c1.14-0.92-0.38-2.41-1.18-2.47c-11.17-2.43,4.07-7.36,7.41-4.86c32.11,9.02-4.6,14.98,8,16.33',
        'C475.21,246.93,422.05,251.77,409.46,238.84z M444.85,267.45c-7.77-2.24-11.04-10.54-16.25-16.12c-4.6-3.72-16.94-9.88-7.61,2.55',
        'c-11.02-10.3-5.82-13.02,5.57-5.64C430.17,253.69,450.51,273.35,444.85,267.45z M443.33,261.9',
        'c-16.31-33.74,27.41,8.61,11.54,26.59C446.89,283.83,451.49,268.1,443.33,261.9z M445.1,318.62c-1.07-7.29,4.02-7.12,4.42-11.54',
        'c2.09-5.07-1.65-16.89,1.28-19.34c11.36,27.61,9.58-26,3.25-35.44c-1.31-6.93,6.49,11.94,6.67,16.91',
        'c-0.59,10.17,3.56,58.39-5.12,50.51c-5.85,14.01,5.48-25.71-3.25-9.36c-3.27-8.45-2.83,19.36-6.8,23.94',
        'C447.17,329.52,448.88,305.77,445.1,318.62z M437.62,339.81c-0.62,0.36-1.25,0.7-1.88,1.04',
        'C436.55,340.36,437.19,340.03,437.62,339.81z M412.61,357.2c-24.59,14.59-20.18-1.14-7.39-11.5c1.84,2.66,10.9,2.64,7.85,6.28',
        'c0.47-0.88,2.16-0.68,2.85-2.07C423.63,349.52,419.85,359.29,412.61,357.2z M479.91,370.69c-0.37-0.46-0.16-0.33,0.35-0.32',
        'C480.17,370.46,480.06,370.56,479.91,370.69z',
        'M504.59,350.54c-7.86-9.79-9.7-17.49-14.71-2.41c-0.53,4.66,8.74,10.79,11.1,4.16',
        'C502.21,351.9,504.89,354.6,504.59,350.54z M495.34,341.55c-0.05-0.01,0.03-0.03,0.04-0.04',
        'C495.38,341.51,495.34,341.55,495.34,341.55z',
        'M497.52,337.66c0.96,3.02,4.61-0.09,2.67-2.32C499.16,334.05,496.84,335.38,497.52,337.66z',
        'M501.79,341.72c3.95,2,12.99-1.94,10.75-7.79C509.8,335.81,498.79,334.47,501.79,341.72z',
        'M507.9,201.98c8.77-0.76,15.71,2.46,22.31-3.22c2.75-2.41,9.78,2.82,6.72-3.22',
        'c-4.37-10.94-12.77-0.9-20.47-4.84c-1.22,0.8,14.36,4.83,7.03,5.23C523.57,196.09,492.15,199.51,507.9,201.98z',
        'M732.86,298.95c3.41,3.93-6.57-17.79-6.4-10.05C729.28,291,729.9,296.71,732.86,298.95z',
        'M753.38,191.45c0.35,0.07,0.03-0.55-0.22-0.42C753.21,191.42,753.31,191.54,753.38,191.45z',
        'M779.41,196.43c-6.6-3.39-18.06-7.45-23.56-2.26C766.7,196.84,781.06,221.91,779.41,196.43z',
        'M705.99,291.48c-1.68,1.71,2.93,2.52,2.57,0.47C707.72,292.04,706.86,291.4,705.99,291.48z',
        'M770.75,341.49c-0.07-0.02-0.14-0.11-0.21-0.11C770.81,341.55,770.81,341.5,770.75,341.49z',
        'M773.93,339.53c0.4-2.07-3.03-3.76-4.19-2.72C767.17,339.7,772.95,344.58,773.93,339.53z',
        'M707.75,280.18c-3.05-0.55-1.8,5.6,0.95,7.04C711.63,287.05,708.63,283.07,707.75,280.18z',
        'M747.98,238.21c0.01-0.04,0.03-0.09,0-0.14C747.98,238.12,747.98,238.17,747.98,238.21z',
        'M729.42,210.84c-8.63,2.94,2.58,0.75,5.88-0.48c-2.9,1.38-13.58,9-9.81,1.72',
        'c-12.05-8.17-18.39,49.79-6.68,54.87c1.95-30.1,0.52-19.9,10.92,0.05c3.72-2.67,3.72-15.44,7.48-4.9',
        'c14.12-1.96,19.68-16.8,23.22-30.43c-2.35,13.49,10.9-7.61,1.31-4.39c7.78-40.88-9.55-12.09-16.81-19.89',
        'C739.15,205,743.75,208.82,729.42,210.84z M761.63,227.8c0.29,0.46-0.22,0.71-0.4,1.35C761.36,228.7,761.5,228.25,761.63,227.8z',
        'M720.84,230.31c-0.69,3.63-2.65,15.46-2.78,15.33c-0.29-5.6,4.19-27.04-3.59-14.52c1.04-3.13,2.62-5.57,4.18-8.14',
        'c1.65-3.4,3.55-12.21,4.08-4.29C729.01,216.13,717.88,224.25,720.84,230.31z M741.29,211.9c-0.63,6.11-9.31,4.8-10.1,11.52',
        'c4.94,0.35,0.54,2.79,1.99,6.96c1.93,6.41,9.5,11.51,10.87,3.74c0.39,17.1-19.09-2.26-12.63-11.46',
        'c-3.46-0.4-5.24,10.33-4.45,11.62c6.32-1.05,5.2,15.19,12.3,7.91c-4.66,15.44,12.57,2.65,8.8-3.96c2.46,2.83,1.42-3.89,0.17-2.29',
        'c-1.51,0.71,3.55-9.87-0.88-2.01c-0.43-15.78-6.92-3.91-9.16-12.09c-2.17,0.17-4.42,1.19-1.36-1.31c6.12-2.12,9.31-7.61,12.5,0.66',
        'c5.79-4.26-0.05,4.87,2.39,9.69C767.83,285.25,683.79,228.62,741.29,211.9z',
        'M722.74,319.34c0.03-0.06,0.06-0.1,0.09-0.14C722.76,319.11,722.72,319.13,722.74,319.34z',
        'M722.83,319.2c0.25,0.29,1.35,2.86,1.75,2.8C726.11,321.71,723.79,317.09,722.83,319.2z',
        'M769.3,277.97c0.96,1.96,1.88-2.35,0.3-1.62C769.47,276.83,769.33,277.17,769.3,277.97z',
        'M610.68,325.21c-5.58-3.12-9.37,7.32-2.94,7.06C612.72,331.58,620.23,321.72,610.68,325.21z',
        'M696.2,210.44c-14.67,13.41-14.45,60.68-5.4,41.48c-0.13,0.95-0.2,2.93-0.02,2.96',
        'c8.1-20.06-0.22-12.57,12-34.63c-15.45,38.04,9.6-18.38,30.17-20.98C724.38,189.44,704.52,200.81,696.2,210.44z M691,251.16',
        'c0.34-2.32,1.04-4.55,1.95-6.65C692.37,246.78,691.78,249.05,691,251.16z',
        'M714.88,267.58c-1.74-7.96-6.86,0.84-4.15,4.09C712.69,272.25,716.03,271,714.88,267.58z',
        'M640.52,226.49c2.6-0.11,0.58-6.75-0.87-2.96C640.4,224.18,639.37,226.47,640.52,226.49z',
        'M632.24,257.36c0.42,1.73,3.91,0.89,3.21-1.03C634.37,256.12,632.43,255.07,632.24,257.36z',
        'M594.73,294.53c-0.64-1.92-1.97-1.37-2.22,0.5C593.09,296.22,595.03,296.52,594.73,294.53z',
        'M696.21,257.99c-0.17,1.25,1.13,3.5,2.1,3.59C700.63,261.58,697.64,257.12,696.21,257.99z',
        'M719.07,316.6c-0.99-2.43-3.17-8.86-6.37-6.92C712.56,312.9,716.1,322.71,719.07,316.6z',
        'M715.69,329.87c2.95,5.31,1.17-3.29-0.56,0.54C715.26,330.29,715.36,330.12,715.69,329.87z',
        'M752.8,369.82c-0.82-3.75-5.1-5.44-5.68-0.9C747.72,372.94,754.09,376.61,752.8,369.82z',
        'M756.88,368.61c-0.61-0.02-2.68,0.09-1.2,0.19C756.45,370.83,758.69,370.84,756.88,368.61z',
        'M771.41,344.08c-0.85,0.09-1.71-0.55-2.58-0.47C767.2,345.34,771.77,346.14,771.41,344.08z',
        'M770.84,341.49c-0.07-0.02-0.14-0.11-0.21-0.11C770.91,341.55,770.91,341.5,770.84,341.49z'
    )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;


library PlanetSurface2_3Descriptor {

  function getSVG() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        'M771.4,376.56c-1.24-0.03-0.9,2.02,0.32,1.51C772.42,377.84,771.77,376.88,771.4,376.56z',
        'M777.58,236.76c1.02-1.11,1.41-5.78,0.51-7.01C777.02,232.07,773.81,241.14,777.58,236.76z',
        'M767.98,378.98c-2.11,0.85-4.07-1.21-5.19,2.15C763.68,381.55,771.15,381.17,767.98,378.98z',
        'M706.48,252.83c1.47-2.59,3.59-20.86-3.45-12.92C699.86,245.16,699.86,268.84,706.48,252.83z',
        'M707.46,233.04c3.43,2.33,3.87-6.03,1.09-5.67C706.54,227.41,707.1,231.35,707.46,233.04z',
        'M728.53,309.17c2.59,0.03,1.83-0.77,0.9-2.76C726.9,306.18,726.27,307.88,728.53,309.17z',
        'M754.59,310.2c0.12,0.15,0.23,0.25,0.34,0.33C754.83,310.38,754.71,310.31,754.59,310.2z',
        'M769.97,320.62c-13.98-8.15-14.92-16.45-7.75,2.44c1.55,3.43-5.56,13.27,1.18,11.43',
        'c4.33-2.28,14.15,1.28,16.03-4.34c-3.63,3.16-7.41-0.5-8.05-4.46C786.87,321.36,775.67,324.98,769.97,320.62z M767.7,329.73',
        'c-6.53-0.04-2.09-7.6-5.89-13.85C765.36,317.15,773.61,327.52,767.7,329.73z',
        'M753.42,308.86c-3.71-4.52-8.83-2.68-10.74-10.24c3.94-4.8-3.21,1.21-5.63-1.16',
        'c-4.79-1.96-2.78-7.61-3.41-11.85c-4.98,7.1-5.88-19.27-10.85-18.18c-1.94-10.63-5.95,6.35-2.81,11.66',
        'c-0.11,2.75,5.67,14,4.77,6.48c-2.64-2.79-2.21-10.65-5.03-13.45c8.49-8.72,9.11,21.8,15.96,25.05',
        'C737.32,300.36,751.15,308.55,753.42,308.86z',
        'M765.95,327.58c-1.25-0.03-0.9,2.02,0.33,1.51C766.98,328.87,766.34,327.88,765.95,327.58z',
        'M735.97,248.99c0.02-0.01-0.15-0.04-0.11,0.01C732.8,251.43,740.72,251.97,735.97,248.99z',
        'M772.41,226.43c-4.3-1.59-9.41-30.01-6.03-12.59c11.56,37.07-9.66,45.2-32.52,54',
        'c-3.42,2.56-5.9,4.95-6.51-1.76c-3.79,15.64,6.98,0.67,10.08,6.15c10.94-5.17,5.62-14.94,14.7-9.13',
        'C764.52,260.57,777.46,238.06,772.41,226.43z',
        'M735.27,330.32c-5.51-6.14-11.82-2.48-12.41,4.58C726.85,340.5,741.02,337.93,735.27,330.32z',
        'M721.13,334.8c-0.21-1.59-1.33-1.9-1.87-0.65C718.26,336.96,722.99,337.21,721.13,334.8z',
        'M748.51,201.02c-3.1,0.01-6.14,2.25-6,5.1C744.49,203.97,747.14,204.11,748.51,201.02z',
        'M726.56,363.03c-0.67,0.73,6.47,8.92,4.32,4.64C729.86,366.67,728.44,362.83,726.56,363.03z',
        'M725.71,359.59c0.94-0.54-0.59-3.36-1.27-2.84C724.8,356.69,725.14,359.38,725.71,359.59z',
        'M769.74,304.41c0.98,3.82,1.04-0.14,0.05-1.03C769.4,303.56,769.81,304.4,769.74,304.41z',
        'M766.72,282.58c-2.79,0.83-3.23,10.97-0.27,9.12C766.73,289.18,767.79,284.67,766.72,282.58z',
        'M767.58,282.13c0.42,0.22,0.98,0.5,1.36-0.1C769.51,280.89,767.44,280.94,767.58,282.13z',
        'M769.04,277.1c-2.1-4.23-5.41,4.69-2.3,3.37C768.43,280.24,769.48,278.72,769.04,277.1z',
        'M734.14,276.73c-1.26,0-0.71,2.15-0.23,2.9C735.16,281.46,735.29,277.42,734.14,276.73z',
        'M688.89,348.37c7.57-9.12,10.71,1.42,15.94,5.08c20.38-0.24,8.2-1.42,1.29-9.08',
        'C710.87,328.01,666.59,348.67,688.89,348.37z',
        'M682.94,280.39c15.81-19.15-1.34,29.62,15.26,32.39c15.66-7.69,1.56-37.3,0.39-44.14',
        'c-2.34-11.86-6.45-9.54-8.44,0.92c-9.05,5.41-14.9,10.23-16.67,23.99c-0.09,11.94-8.17,2.41-12.32,7.69',
        'c-14.1,41.53-3.82,29.41,10.21,69.42c16.15-15.12-26.97-38.41-5.73-63.21c9.14,2.41,10.09-17.97,11.85-15.03',
        'c0.78,1.18,2.05-0.3,1.37-1.61C675.95,287.05,678.98,282.6,682.94,280.39z M655.15,332.15c-2.54-2.57-2.1-8.32,0.81-10.8',
        'C655.8,323.94,660.09,333.32,655.15,332.15z M658.8,335.07c0.23,3.28-2.43,1.24-2.3-0.85C657.01,333.1,658.65,333.88,658.8,335.07',
        'z M664.36,305.85c1.63-1.85,4.05-0.22,5.88-1.45C668.49,305.74,666.31,306.05,664.36,305.85z',
        'M667.74,215.85c0.91,0.46,3.26-0.05,2.66-1.78C669.21,213.27,665.88,213.78,667.74,215.85z',
        'M662.72,355.04c-0.2-0.03-1.56,1.07-1.05,1.01C662.24,356.97,663.88,356.02,662.72,355.04z',
        'M657.95,358.84c-0.11,0.81-1.92,3.42-1.05,3.63C658.93,362.79,660.98,359.41,657.95,358.84z',
        'M641.48,345.25c-0.61-0.1-1.35,1.1-0.73,1.56C640.2,352.91,644.6,346.69,641.48,345.25z',
        'M638.98,327.66c-4.88,1.43,4.17,9.74,0.39,3.77C637.79,330.56,639.54,328.54,638.98,327.66z',
        'M620.55,329.07c0.47,0.45,0.6,1.82,1.34,1.38C622.59,330.05,620.77,327.53,620.55,329.07z',
        'M614.38,236.82c-1.16,1.99-3.72,7.23-0.68,7.88C618.45,245.72,618.48,238.2,614.38,236.82z',
        'M609.21,240.21c-1.19,0.4-0.72,3.27,0.01,4.01C611.68,245.99,610.51,240.88,609.21,240.21z',
        'M581.74,267.64c7.56-1.18,5.55-7.42-0.61-7.64c-4.99-2.05-3.84,7.13-2.06,2.63c0.91-2.08,1.63-0.01,3.97,0.1',
        'c3.2,0.47,2.49-0.64,1.99,2.31c-2.29,2.48-7.63-0.65-7.9,0.52C575.48,269.5,579.48,265.16,581.74,267.64z',
        'M624.16,358.4c-7.72-7.48-21.46-3.91-30.58-11.7c0,0,14.4,3.87,14.4,3.87c-14.43-12.2-41.36-4.66-28.52-38',
        'c15.45-4.24,1.65-5.36-5.8,2.18c9.02-25.11,41.39-8.28,49.12-14.2c5.18,9.14-16.91,12.95-15.43,19.5',
        'c12.63,7.51,1.15-1.7,24.03-12.21c15.46-12.24,15.54-20.74,31.61-13.27c15.37,1.67,11.49-24.27,0.22-26.81',
        'c-3.92,6.68-6.18,12.09-7.14,19.87c-20.63,4.56-24.04,24.03-28.22,13.92c-4.09-10.87,3.76-3.57,4.4-9.69',
        'c-0.34-2.92-5.34-6.56-8.1-8.64c5.71-5.05,1.3-8-3.79-4.25c-4.61-1.29,1.7-2.24,3.56-3.33c3.36-1.43,8.48-14.84,1.88-12.3',
        'c-7.44,18.57-28.27-10.46-36.91-14.19c4.13-10.49-9.69,1.9-9.7-8.44c1.52-2.51,0.49-9.57-3.24-7.5',
        'c-1.59-5.44,26.1-25.32,8.53-13.6c0.34-2.32,7.77-8.76,10-10.3c1.73,9.88,30.81,0.27,14.62-5.3c68.46,14.14,52.34,50.35-3.7,22.85',
        'c12.92,8.54,40.08,16.3,41.69,41.1c-4.68-14.46-1.44-37.81,18.91-25.17c17.56-11.47,18.22-43.84,41.7-49.58',
        'c-12.32-8.93-35,27.57-43.08-15.06c-0.77,17.58,1.8,37.62-8.25,52.84c0.56-21.28-35.13-27.44-7.7-23.77',
        'c-19.03-13.66-59.45-31.46-73.78-5.73c-7.87-0.78-3.84-3.88,2.9-6.88c7.05-9.15-9.7,3.23-10.83,3.53',
        'c-2.29,3.56-3.56-14.74-8.71-16.98c17,51.45-38.06,20.9-61.6,36.69c14.58-8.13,48.47,8.84,59.12,32.15',
        'c-4.39,16.64,3.9,22.14,11.18,33.35c2.29,3.77,10.08-4.44,17.17-3.43c8.03,2.94,6.87-5.95,2.99-9.06c1.96-9.4,3.9-2.64,10.08-3.23',
        'c-14.87-10.09-5.05,3.32-16.8,3.53c2,2.54,7.97-3.14,7.41,5.23c-43.13,22.87-31.77-63-5.63-24.51c42.86,18.05,0.93,40.62,39.72,33',
        'c33.67,22.47-86.44,8.75-51.2,10.64c13.37,5.31-1.17,5.64,0.94,11.24c4.59,1.51,7.9-3.85,7.44-7.81',
        'c10.42,0.92-1.58,4.95-6.3,14.53c-32.63,17.67-32,0.67-55.31-12.95c-25.93,11.59-24.25-37.3-18.79-50.77',
        'c-18.88-11.6,1.33,38.03-8.01,24.96c-7.66-20.96-27.7-12.67-11.14-4.94c1.72,0.94-6.56-5.16-1.86-5.07',
        'c11.67,9.18,15.14,28.19,24.69,38.73c15.61,0.62,5.22,19.66,15.01,26.31c-1.87-53.57,1.45,3.44,49.61-3.22',
        'C566.81,344.57,608.99,375.57,624.16,358.4z M643.11,245.64c-2.37,3.28-8.25-6.1-6.77-6.37',
        'C636.43,235.44,645.06,243.19,643.11,245.64z M660.67,227.26c5.96-7.06,1.9-34.2,15.25-24.67',
        'C702.34,198.94,652.06,265.49,660.67,227.26z M524,218.9c-0.44-0.12-1-0.32-1.28-0.84C522.99,218.34,524.83,219.15,524,218.9z',
        'M528.02,216.21c-0.35,0-0.7-0.05-1.04-0.08C527.18,215.96,528.34,215.85,528.02,216.21z M596.98,204.31',
        'c-1.61,3.77-30.13,21.23-12.18,16.38C556.71,236.41,604.26,197.25,596.98,204.31z M627.38,208.51c-1.21-0.18-3.35-0.34-4.16-1.32',
        'C624.23,206.56,629.9,208.03,627.38,208.51z M584.94,194.77c17.25-6.22,51.28,2.86,55.5,10.42c-5.17,2.18-18.58-9.85-11.29-0.26',
        'c-4.32,1.77,15.89,4.99,17.8,8.66c-14.58-7.28-10.94,1.1-19.7-7.02c-7.45-3.98-23.25-0.66-6.29-6.62',
        'C612.49,192.34,591.97,194.64,584.94,194.77z M589.86,197.45c5.2-5.24,36.12,1.49,16.72,4.78',
        'C599.12,200.57,570.33,214.65,589.86,197.45z M567,204.03c-0.12-0.14,0-0.97-0.04-1.42C566.97,203.27,566.99,203.8,567,204.03z',
        'M566.94,221.74c0.5,0.66,0.25,0.22,0.06,0.28C566.93,221.98,566.94,221.81,566.94,221.74z M567.82,238.96',
        'c0.16-0.86-2.31-1.45-0.93-2.15C568.24,236.06,570.09,239.99,567.82,238.96z M568.93,236.77c-1.62-4.61-4.17,2.7-2-4.94',
        'c-10.03,4.66-6.91,19.45-16.51,5.38c-30.61-27.75-5.8-12.66,14.05-29.09c-7.01,7.02,5.08,7.85-0.55,8.63',
        'c2.97,2.83-7.23,9.17-7.25,11.86c-0.23,9.02,4.72-5.48,10.23-0.31C571.64,223.63,567.74,233.22,568.93,236.77z M574.41,224.91',
        'c-2.77,3.29-1.98-9.71-6.48-9.7c-1.22-3.52,1.31-9.25,3.97-11.51c4.7-2.1,6.16,12.8,7.54,5.5',
        'C583.62,180.91,583.63,214.88,574.41,224.91z M611.91,276.71c-0.34-0.16-0.76-2.79-0.99-2.77',
        'C607.03,275.63,612.08,269.25,611.91,276.71z',
        'M649.17,378.19c-7.94-9.24-30.11,2.56-41.94-3.31c8.65-3.85,5.34-1.48-5.73-5.13',
        'c-23.09-6.14-9.59,5.52-25.67,8.45C571.7,382.35,688.08,386.18,649.17,378.19z',
        'M713.34,372.16c-11.16,1.63-19.76,11.45-28.41,9.05c2.8,3.94,30.83-0.91,31.62-4.22',
        'C731.32,381.93,724.4,373.97,713.34,372.16z',
        'M726.43,379.17c0.72,0.61,1.27,0.97,1.57,0.83C728.39,379.83,727.67,379.53,726.43,379.17z',
        'M777.31,220.17c-1.81,2.96,1.12,8.86,2.12,7.45C779.22,226.19,780.4,219.19,777.31,220.17z',
        'M778.81,229.46c0.23,0.17,0.04,1.11,0.32,1.31C779.73,230.83,779.5,228.35,778.81,229.46z',
        'M779.43,364.83v-10.94C772.99,361.62,770.8,361.58,779.43,364.83z',
        'M770.81,258.98c-1.62,3.45-3.91,9.94-3.42,13.49c1.98-8.32,4.08-13.26,3.08-1.84',
        'c4.25,4.25,0.84,46.65,8.95,25.66c0.04,0.01,0-29.35,0.01-29.35c-3.72-4.47-6.97-15.31,0-20.09',
        'C776.83,245.49,769.96,251.69,770.81,258.98z M774.96,251.66c0.46-1.5,1.32-2.49,2.16-3.13',
        'C776.41,249.48,775.69,250.53,774.96,251.66z "> '
    )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library PlanetSurface3_1Descriptor {

  function getSVG() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
      '<path class="clip_path" d="M512.77,280.44c-24.82,19.78,8.58,9.34,16.38,3.13c-20.42,0.74-8.5-10.52-7.42-24',
      'c-5.47,2.03-19.3,12.85-9.2,16.99C513.76,277,513.26,278.47,512.77,280.44z',
      'M518.9,260.3C518.9,260.3,518.9,260.3,518.9,260.3C518.9,260.3,518.9,260.3,518.9,260.3z',
      'M442.03,228.36c10.09,3.28,44.35-1.82,23.06-14.28C464.63,225.17,454.26,227.32,442.03,228.36z',
      'M461.45,234.45c2.4-0.67,22.39-5.39,15.56-8.81c-2.13,0.56-13.96,7.11-15.63,8.28c-0.82-0.54-0.87-0.52,0,0',
      'C460.89,234.39,460.36,234.59,461.45,234.45z',
      'M351.72,219.94c-12.24-4.96-29.05-4-41.42-2.92C331.1,212.28,386.8,252.17,351.72,219.94z',
      'M378.43,321.34c-8.79,10.46-19.55,11.46-36.56,8.19c-11.88,4.94,15.58,17.07,21.59,14.73',
      'c2.73-0.68,3.02-4.75,3.17-6.63C366.54,332.78,380.02,325.35,378.43,321.34z',
      'M548.58,224.26c0.02-0.06-0.07-0.08-0.09-0.04C548.49,224.21,548.58,224.26,548.58,224.26z',
      'M497.84,282.09c-13.09,2.2-8.12,14.91,1.43,0.41C500.99,280.41,499.64,281.6,497.84,282.09z',
      'M263.04,365.8c-24.47-2.21-55.54-24.1-76.03-26.52c8.88,13.36,51.55,28.15,70.97,29.21',
      'c4.09,1.68,0.15,3.67-0.31,5.6C267.31,379.21,279.38,372.69,263.04,365.8z',
      'M253.79,375.36c-1.95-3.6-19.29,3.43-18.94,3.09C238.44,378.42,263.29,380.9,253.79,375.36z',
      'M237.55,371.28c16.8-5.09-47.44-12.21-51.22-24.56c-6-5.82-4.81,1.41,3.34,9c1.73,2.52,9.89,6.77,4.95,7.09',
      'c-27.15,4.21,13.21,2.61,22.58,5.92c-2.27,4.45-19.58-1.2-28.12-0.42c-4.64,0.01-9.1,0.76-12.86,2.07v2.56',
      'c1.7-0.3,3.24-0.51,4.26-0.54C196.43,374.87,222.04,376.86,237.55,371.28z',
      'M549.14,251.77c0,0-0.06-0.36-0.06-0.36C549.04,251.49,549.11,251.7,549.14,251.77z',
      'M548.7,251.04c2.39,0.53,2.29-5,0.69-4.59C548.13,246.22,546.16,250.72,548.7,251.04z',
      'M549.21,241.26c7.43,0.74,1.86-10.71-0.71-3.64C547.89,239.49,548.69,241.56,549.21,241.26z',
      'M343.64,365.18c0.59-0.04,2.24,0.97,2.54,0.2C345.46,365.33,343.95,364.47,343.64,365.18z',
      'M190.34,309.96c10.98-0.06,18.84,8.41,13.4-10.52c-8.5,5.65-17.56,5.15-23.09-4.74',
      'c-1.54-1.96-3.02-3.95-4.44-5.96v15.96l0.77,0.48C181.08,307.72,185.53,310.07,190.34,309.96z',
      'M432.2,373.05c16.36-8.23,34.99-4.39,50.64-1.58c12.4,0.68,71.87-14.89,42.76-33',
      'c-46.93-6.51-101.85-20.95-129.43-65.04c-2.87-6.93-19.08-28.19-9.23-30.85c5.7-9.79,4.68-24.06,19.27-26.12',
      'c8.78-3.05,8.54-2.85,9.79-4.07c-2.86,0.59-6.05-11.53-1.02-10.23c4.42,4.76,21.12,13.58,16.99-0.45',
      'c-38.87-36.55-192.18,1.23-254.42-11.81c-0.23-0.02-0.45-0.04-0.69-0.04c-0.03,0-0.1,0-0.15-0.01c-0.01,0-0.01,0-0.02,0',
      'c-0.18-0.01-0.34-0.04-0.48-0.08V196c2.15,0.31,4.52,0.47,7.09,0.47c32.84,0.64,76-2.14,106.23,2.37',
      'c-26.44,11.06-56.81,23.19-63.83,54.45c-4.45-6.98,3.32-31.71,12.9-37.88c21.46-17.02-34.55-2.49-25.1-9.9',
      'c-3.3-0.34-18.51,3.69-24.49,6.83c0.51-5.42,9.48-6.78,20.09-8.27c10.43,0.28,48.03-7.05,47.07,3.43',
      'c-5.77,5.18-20.91,9.27-20.83,17c11.74-8.76,23.88-16.93,37.57-23.19c-30.25-4.68-63.2-2.5-93.81,0.12',
      'c-1.04,0.01-1.98-0.01-2.88-0.05v20.17c1.35,2.03,2.49,4.25,3.17,6.72c0.82,4.82-0.33,10.42-0.73,14.94',
      'c-0.69,0.34-1.33,0.53-1.95,0.57c-0.08,0.01-0.15,0-0.22,0c-0.08-0.01-0.18-0.03-0.27-0.04v13.56c2.26,2.7,4.86,5.16,8.26,6.87',
      'c13.74,17.73,7.9-2.19,10.49-11.69c3.42-7.07-12.51-33.97-4.78-33.85c2.5-3.25,14.58-14.14,16.79-9.06',
      'c-28.15,9.99,14.69,55.45-13.05,67.7c-7.46-0.12-13.47-7.59-17.71-13.4v16.25c2.23,3.39,4.63,6.9,7.21,10.35',
      'c16,23.85,24.3-18.65,26.63,13.58c4.63-11.91,5.85-26.72,11.68-38.28c2.99,17.24-22.29,49.25,7.26,57.31',
      'c7.04,3.92,21.11,4.09,21.07-5.7c5.41-3.41,23.65-17.81,25.29-13.3c-10.43,8.68-20.26,17.75-32.86,25.39',
      'c0.91,1.14,4.34,2.49,5.15,4.04c-0.73,1.65,1.13,1.19,1.87,0.83c4.57-7.91,17.05-20.39,27.42-22.98',
      'c-0.85,12.3-11.63,34.71,6.76,39.2c21.31,9.04,49.78,17.31,65.6,17.93c-19.83-8.66-56.74-10.72-60.56-32.77',
      'c5.38-25.91,13.13,10.96,28.21,13.39c23.31,14.88,62.47,21.61,83.56,0.86c5.09-4.21,6.81-17.13,10.43-3.86',
      'c11.99,31.17-51.04,11.78-54.32,20.9c24.79,2.66,62.37,8.16,77.09-16.35c19.3-11.34-11.24,22.99-17.29,19.72',
      'c42.09-6.99,38.15-58.49,88-24.84c24.8,12.96-27.15,24.69-23.52,11.2c4.15,2.36,19.81,0.53,7.69-1.76',
      'c-5.64-0.57,10.61-10.22-3.09-12.62c-4.45-0.42-13.92,6.11-4.93,3.32c10.95-0.84-7.23,13.62-11.04,7.94',
      'c-1.2-2.8-12.64,5.02-11.83,0.87c28.41-10.21-2.58-6.49-8.69,1.47c-4.24,2.33,2.98,0.96,4.66,2.45',
      'c-2.95,6.99-19.65,6.8-25.65,11.95c-34.41,37.97-213.53-20.78-91.87,3.01c-22.02-9.78-98.21-9.38-64.16-56.02',
      'c-5.23,2.4-15.91,23.97-12.49,32.16c-3.13-2.07-20.08-3.2-8.79-9.15c3.27-5.64-9.14,5.67-10.46,2.21',
      'c1.52-2.59,10.17-5.75,3.8-6.43c-2.25,0.06-0.06-2.19-1.39-2.93c-1.94-0.63-6.68,1.09-2.97,3.26c4.13,11-18.69-1.03-21.47-7.36',
      'c-8.15-10.89-25.48-11.64-37.42-17.09c-1.55-0.67-3.08-1.38-4.59-2.12v7.69c0.49,0.35,0.97,0.69,1.43,0.98',
      'c7.09,5.22,34.84,6.13,10.56,10.9c1.81-0.15,2.97-0.14,5.04,0.11c7.39,1.13,8.52-3.58,14.1,2.71c8.69,8.74-1.11,2.13-6.72,1.72',
      'C257.94,360.96,361.28,413.89,432.2,373.05z M226.8,299.03c-1-1.91-2.44-3.79-1.89-5.96c-1.89,5.32-5.57,11.99-2.45,16.96',
      'c0.02,2.44,6.23,6.99,2.03,6.57c-15.36-17.5,12.48-74.74,23.43-92.61c20.79-17.08,96.92-31.17,29.54-31.29',
      'c42.09-3.83,92.45-7.85,135.11-0.92c15.12,8.86-26.17-6.01-31.57,5.88c-30.58-15.93-77.75,0.8-107.88,19.25',
      'c-25.99,5.94-56.86,76.58-19.94,33.64c-7.02,15-27.47,30.95-22.9,49.99C230.02,303.03,227.07,300.08,226.8,299.03z M371.26,244.4',
      'c-3.91-1.17-26.11-6.04-15.54-1.81c6.01,3.06,18.24,9.29,9.18,11.19c-16.12-0.82-18.87-20.92-32.48-26.82',
      'c-12.87-6.64-39.32-1.54-25.83-8.46c-6.15,0.75-27.45,12.62-17.79,2.71c3.52-2.64,2.78-1.35,1.65-3.56',
      'c3.07-3.17,16.44-4.37,27.2-6.92C378.57,204.47,381.57,267.95,371.26,244.4z M337.1,203.5c7.79,0.97,32.77,6.76,30.67-5.51',
      'c9.59,3.25-4.17,13.46-11.51,10.46c-11.06-1.91-30.3-1.47-37.1-6.32c6.39-0.92,15.75-5.88,21.17-3.1',
      'C339.9,200.6,333.65,200.68,337.1,203.5z M256.09,244.16c-16.76,16.99-3.91-6.11,4.89-12.41c3.51,1.34,2.01,2.54,8.43-1.98',
      'c2.4-1.01,0.96,1.36,1.71,2.2c0.69,0.07,2.63,0.06,1.72,1.24C267.7,235.43,257.96,250.93,256.09,244.16z M288.58,309.74',
      'c1.39,23.5-21.68,37.46-5.42,3.34c3.63-6.59,2.16-12-5.95-10.93C284.74,294.85,293.52,297.78,288.58,309.74z M290.52,290.69',
      'c-7.08,1.23-19.13,11.79-24.38,9.57c6.29-4.65,26.47-15.61,34.95-12.57c-0.03,5.98-3.72,12.47-5.93,16.8',
      'C291.85,300.61,300.07,289.35,290.52,290.69z M311.9,280.94c1.92,1.89,2.99,2.47,5.64,1.36c0.43,4.97-9.65,11.86-12.87,15.29',
      'C303.28,293.57,309.44,284.78,311.9,280.94z M294.23,266.14c-7.64-0.12-15.65,6.18-23.33,7.84c-0.43-4.24,11.49-7.53,15.48-9.1',
      'c10.66,0.18,21.82-5.67,30.07-1.09C309.88,265.05,299.27,264.76,294.23,266.14z M303.39,282.01c-7.64,0.83-18.32,7.98-20.28,4.61',
      'C287.57,285.11,303.59,273.88,303.39,282.01z M334.22,352.48c-7.69-1.35-31.8-14.04-19.99-18.98',
      'C321.49,337.57,328.96,346.73,334.22,352.48z M358.6,350.41c-17.51,3.4-21.98-15.78-36.83-20.64',
      'c-4.24-2.88-12.16-2.82-11.17-9.71c10.34-12.36,31.04,11.95,45.04,7.06c6.22-0.54,14.65-7.51,16.82-12.94',
      'c22.91-14.83,27.26,29.66,4.07,24.44C364.02,340.58,396.07,343.17,358.6,350.41z M403.19,325.36',
      'c-2.77,15.36-22.64,33.72-35.93,28.86c22.42-4.32,26.44-19.23,32.85-32.3C394.96,308.45,406.89,316.74,403.19,325.36z',
      'M406.62,311.74c-56.17-24.98-38.4,26.52-67.03,5.84c17.39,6.25,19.81-16.49,35.92-18.54c-4.38-2.77-23.01-5.43-20.74,6.65',
      'c0.39,4.97-2.45,7.32-7.24,6.62c-63.55-5.92,29.59-21.96-1.17-46.1c17.68,23.52-59.45,30.29-22.3,44.81',
      'c-8.09-0.26-22.2-1.79-31.01,2.96c-0.14-6.67,4.11-10.48,8.21-14.63c9.32,0.81,30.74-22.17,24.5-32.35',
      'c-13.53-4.64-1.6-4.43,4.38-2.52c7.4-0.29-0.93,11.51,6.38,8.85c9.49-24.48-42.43-15.49-55.75-11.3',
      'c-9.34,3.13-34.75,17.28-29.58,26.93c-0.75,3.58-10.84,7.5-6.08,11.17c16.44-7.72,45.02-42.12,64.18-25.01',
      'c-4.25,0.06-21.74-1.04-21.78,1.69c2.13,5.94-25.57,13.34-30.01,20c-8.45,3.72-21.69,26.84-30.02,13.84',
      'c17.28,1.96,15.9-17.92,11.1-10.5c1.11,1.2,2.75,2.24,0.77,3.74c-14.11,5.43,4.37-28.79,8.72-36.2',
      'c12.08-16.89,31.22-39.36,53.78-40.26c-1.76,2.61-6.99,2.9-7.41,3.9c13.73-1.61,35.17-1.79,42.25,8.29',
      'c-36.3-10.61-64.2-4.47-89.05,37.55c7.68,7,50.35-57.7,83.03-28.36c-10.16-4.59-45.79-2.02-52.52,9.24',
      'c23.57-14.91,106.5-6.79,69.45,33.25c-6.56,3.27-18.48,14.72-5,16.33c8.37,2.32,6.04-4.69,0.68-6.65',
      'c4.17-6.54,13.86-8.4,16.32-16.79c8.57-22.65-14.55-28.68,18.31-14.38c-1.39-9.26,6.89,0.78,3.58,3.9',
      'c11.02,6.83,21.1,16.81,23.74,22.77c-14.69-0.74-23.53-15.21-34.38-22.04c0.43,8.6,11.03,15.73,21.09,21.76',
      'c-5.62,2.94-19.79-11.17-24.22-14.8c6.41,19.29,37.6,25.15,53.59,28.85c4.7,1.75,9.33,3.11,3.83,5.45',
      'c7.04,5.38,18,8.21,29.34,12.07C441.8,333.17,417.86,321.82,406.62,311.74z M427.53,350.99c-2.33,3.85-3.88,3.8-5.82,0.01',
      'c1.69,4.86-1,9.79-6.63,9.7c6.12-15.44-9.72-22.79-6.74-42.17C420.22,318.9,417.56,346.13,427.53,350.99z M458.15,337.91',
      'c-2.89,2.07-18.99,12.14-14.37,2.54c-1.99,1.3-10.01,5.36-13.57,5.63c-3.03-2.59-8.02-7.3-1.67-9.7',
      'C435.3,336.66,454.71,332.32,458.15,337.91z',
      'M177.25,360.31c-0.01-0.1,0.01-0.19,0.05-0.28c3.41-7.11,2.37-16.24,0.9-22.65',
      'c-0.08-0.54-0.16-0.65-0.69-2.4c-0.41-1.32-0.87-2.81-1.3-4.25v31.47c0.27-0.32,0.53-0.63,0.75-0.93',
      'C177.18,360.98,177.28,360.65,177.25,360.31z',
      'M180.09,326.13c0.38-0.02,0.9,0.11,0.68-0.46c-0.3-0.47-2.27-1.97-4.56-3.39v2.3',
      'c0.51,0.21,1.06,0.49,1.38,0.65C178.42,325.65,179.45,326.17,180.09,326.13z',
      'M235.43,277.2l-0.68-0.06C234.91,277.17,235.27,277.22,235.43,277.2z',
      'M370.34,375.44c-7.3-0.82-37.43-2.81-15.07,3.07c18.86,1.14,42.22-3.28,60.25-4.32',
      'C407.07,370.94,377.84,369.18,370.34,375.44z',
      'M405.05,356.3c-9.53,6.25-3.67,7.39,2.57-0.35C411.09,350.48,404.91,350.35,405.05,356.3z',
      'M407.51,351.2C407.51,351.2,407.51,351.2,407.51,351.2C407.51,351.2,407.51,351.2,407.51,351.2z',
      'M383.17,363.93C383.17,363.93,383.17,363.93,383.17,363.93C383.17,363.93,383.17,363.93,383.17,363.93z',
      'M397.61,362.2c0.14-1.07-2.62,0.2-2.74,0.81C395.71,362.9,397.66,362.7,397.61,362.2z',
      'M752.76,234.57c-0.23-21.96-35.48-18.19-51.73-17.89C722.34,217.49,739.98,225.55,752.76,234.57z',
      'M768.77,320.83c-8.66,12.8-19.66,11.04-36.18,8.7c-11.88,4.94,15.58,17.06,21.59,14.73',
      'c5.66-2.99,0.38-8.98,6.83-12.25C765.39,328.75,770.42,322.85,768.77,320.83z',
      'M653.76,365.8c-24.47-2.21-55.54-24.1-76.03-26.52c8.88,13.36,51.55,28.15,70.97,29.21',
      'c4.09,1.68,0.15,3.67-0.31,5.6C658.03,379.21,670.09,372.69,653.76,365.8z',
      'M644.5,375.36c-1.95-3.6-19.29,3.43-18.94,3.09C629.15,378.42,654.01,380.9,644.5,375.36z',
      'M734.36,365.18c0.59-0.04,2.24,0.97,2.54,0.2C736.17,365.33,734.66,364.47,734.36,365.18z',
      'M566.93,322.29c-1.52,0-7.99-5.67-8.21-7.41C556.65,321.51,579.94,331.16,566.93,322.29z',
      'M768.32,383.62c-27.86-1.38-66.46-4.33-92.23-19.09c18.16,1.82,35.75,7.81,52.02,8.76'
    )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library PlanetSurface3_2Descriptor {

  function getSVG() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
    'c-33.53-10.6-96.28-11.15-65.65-56.28c-9.46,9.82-14.24,22.79-12.23,32.48c-4.31-2.27-20.07-3.39-7.9-9.8',
    'c-0.94-3.97-9.13,6.44-11.35,2.86c11.59-10.15,3.95-2.01,2.41-9.36c-12.04-0.07,7.69,7.71-6.91,7.32',
    'c-15.76-1.84-20.59-22.24-38.38-23c-9.97-0.19-22.02-12.12-30.76-8.39c7.17,14.28,49.23,15.32,21.59,20.34',
    'c3.65-1.05,11.61,2.7,12.21-1.35c5.27,0.42,6.01,5.69,9.66,6.74c4.15,5.41-16.79-5.93-9.91,2.82',
    'c60.13,18.81,119.53,54.4,186.08,50.11c0.89,0,1.74-0.01,2.57-0.03v-4.48c-0.68,0.04-1.35,0.09-2.05,0.12',
    'C774.53,383.54,771.45,383.62,768.32,383.62z',
    'M594.46,299.45c-11.72,8.99-20.94,0.33-27.53-10.7c-1.3,12.56,0.06,21.74,15.31,21.18',
    'c3.99-0.37,8.3,1.2,11.89,3.08C596.5,309.4,597.11,299.95,594.46,299.45z',
    'M769.16,280.49c-2.45-1.78-6.19-5.95-7.63-5.69c0.71,7.45,9.07,13.97,17.99,19.51v-4.89',
    'c-2.7-2.06-5.17-4.28-7.42-6.31C771.09,282.19,770.11,281.31,769.16,280.49z',
    'M669.11,191.96c33.99-2.33,72.39-4.33,107.14-3.43c1.13,0.06,2.22,0.12,3.28,0.18v-1.6',
    'c-0.66,0-1.33,0-1.99,0l-1.37,0c-114.05,0.41-228.37,9.44-340.28-0.24c-11.81,10.33,8.23,18.01,13.36,24.85',
    'c0.81,7.85-19.68,4.68-23.21,2.98c-55.57,3.4-27.65,73.04,17.81,92.93c25.88,22.8,67.22,12.19,95.52,19.73',
    'c9.24,41.48-41.86,44.87-27.16,47.67c-10.36,7.83-44.51-3.2-61.99,2.06c-12.92,1.53-49.43,17.13-15.54,9.6',
    'c37.79-12.65,93.12-1.51,122.46-9.4c8.54-10.3,36.07,0.09,52.27-2.58c43.21-3.95,12.96-10.14-8.57-14.97',
    'c-12.44-1.96-19.5-10.7-27.24-15.15c-4.76,1.84,14.66,16.14,12.55,18.24c-35.09,4.62,26.83,1.93,20.45,7.34',
    'c-45.45-7.27-38.99,15.44-49.77-24.82c2.55-13.54,7.91,23.84,10.1,16.87c4.95-8.29,3.69-18.98,1.3-27.22',
    'c-5.83-20.91-7.4,19.22-11.72-21.51c-4.7,20.84,3.76,65.74-31.61,60.59c26.26-8.04,25.35-45.34,19.95-66.82',
    'c8.04-3.51,3.26-8.16-5.99-1.33c-11.06,18.19-38.34,19-56.97,14.21c-10.21-3.12,18.38-0.18,21.06-4.71',
    'c-44.24-0.43-71.31-38.8-93.8-65.55c13.58,25.97,37.17,56.09,66.87,68.06c-35.84-9.76-76.07-37.12-72.28-77.87',
    'c6.22-21.28,39.43-10.89,51.14-25.56c-1.92-23.28,76.67,37.83-15.52,22.98c-6.98-1.44-36.74-4.17-29.46,6.34',
    'c11.28-0.71,63.12-1.82,22.58,8.34c3.68,1.09,30.85-4.57,40.1-4.35c17.26,5.59,26.03-17.54,14.14-29.35',
    'c-9.14-17.16-40.58-6.89-49.41-23.55c-1.58-8.79,16.02,5.26,23.88,5.24c24.5,6.78,56.89,29.46,32.71,56.32',
    'c-3.62,7.71-28.41-5.83-30.42,1.82c1.07,2.78,22.19-0.35,22.14,2.81c-12.01,2.76-25.46,0.01-36.59,4.05',
    'c1.12-3.24,2.9-6.51-3.26-6.15c-11.44-1.6-9.2,29.49-1.29,9.12c2.54,2.48-1.69,16.22,5.98,20.92c3.34,3.43,10.29,7.92,11.08,0.83',
    'c17.15,16.75,52.05,23.51,69.56,8.32c10.96-3.4,13.12-13.1-0.19-2.32c-0.76-6.07-4.99-5.08-9.19-1.07',
    'c-12.01,8.12-51.26,10.64-45.23-11.27c17.78,6.31,43.79-28.7,42.41-47.66c-0.48-14.91-22.51-23.49-33.93-31.84',
    'c33.19,11.09,42.13,19.63,37.21,50.1c9.74,0.61,4.72-14.18,11.6-14.29c3.56-2.6-8.32-17.22-1.78-18.91',
    'c3.67-0.21,4.83,8.21,5.56,18.48c5.78-7.37,4.32-17.16-3.51-23.56c-32.75-16.39-2.64,9.86-22.87-2.44',
    'c-10.55-5.97-18.59-7.15-9.55-11.31c-8.16-2.77-17.09-3.91-25.76-6.92c32.65-3,99.36,2.6,93.94,47.3',
    'c-1.27,1.44-3.78,2.78-4.74-1.21c1.58-29.24-25.57-42.25-56.84-39.33c7.78-1.06,39.95,8.7,37.41,20.58',
    'c-2.93,2.92,2.91,17.17,2.87,4.59c0.17-1.48-2.01-4.65,1.34-3.33c5.95,8.37,10.56,17.99,13.34,28.74',
    'c4.53,6.14,16.53,17.42,20.51,18.75c1.58-8.81,3.9-28.27-2.94-42.99c-4.77-13.48-2.6-6.36,4.54-14.27',
    'c3.42-4.06,8-5.77,12.93-5.41c-12.85,4.58-12.16,16.41-7.67,28.05c9.53,21.75-1.87,59.76-23.63,27.18c0,0,0,16.25,0,16.25',
    'c22.11,42.4,30.97-10.2,33.84,23.93c3.8-12.29,6.99-24.36,10.57-37.69c5.42,16.5-24.63,56.95,17.85,59.18',
    'c14.49-2.34,19.65-19.14,36.41-23.09c4.4,0.02-3.07,3.9-3.85,5.27c-1.75,1.67-4.46,3.55-4.56,3.61',
    'c-7.13,7.15-16.17,12.85-24.16,18.37c2.24,1.08,5.24,2.63,5.35,4.86c6.39-6.27,15.64-15.65,25.31-22.83',
    'c13.8-0.29-16.77,35.01,14.71,40.41c20.84,8.6,46.67,15.66,61.62,16.34c-19.92-8.71-76.7-14.45-55.23-43.91',
    'c12.46,26.89,52.08,43.57,82.98,36.42c3.95-0.44,8.03-0.91,11.76-2.13v-10.95c-4.48,3.65-10.29,6-18.18,7.32',
    'c-6.24,1.34-3.53-1.57,0.77-2.39c6.98-2.3,13.05-5.67,17.41-9.62v-9.22c-1.36,1.85-2.9,3.65-4.6,5.36',
    'c-4.69-0.61-18.85-1.54-5.49,3.49c-21.9,18.98-38.73-0.65-56.94-13.06c-4.23-2.88-12.16-2.81-11.18-9.7',
    'c10.34-12.36,31.04,11.95,45.04,7.06c12.48-0.41,15.39-19.1,28.49-15.32c1.76,0.91,3.32,1.95,4.67,3.08v-8.22',
    'c-0.65-0.14-1.35-0.29-2.17-0.46c-0.09-0.02-0.17-0.05-0.25-0.08c-21.71-11.39-27.6,29.36-48.04,11.84',
    'c18.99,5.98,18.61-16.11,37.15-18.15c0.85-2.36-15.34-5.1-18.34-1.46c-3.93,3.15-0.86,9.72-3.93,12.83',
    'c-8.65,3.19-31.24-2.3-29.84-7.82c9.94-7.96,42.87-20.95,23.9-36.44c-1.79-0.59,6.66,8.04-7.24,18.91',
    'c-16.23,14.45-40.04,8.8-17.03,26.4c-11.25-5.34-20.91-0.6-29.96,1.73c0.09-5.88,4.52-13.71,9.79-14.47',
    'c9.26-1.18,37.95-30.97,16.19-35.52c3.94-1.74,17.98-0.79,14.07,6.5c-1.12,1.8,1.7,4.8,3.42,2.86',
    'c10.6-21.53-30.81-14.91-42.73-14.89c-14.71,2.74-45.84,15.94-42.6,30.52c-1.03,3.61-12.46,9.08-4.73,11.74',
    'c15.33-11.86,44.72-41.17,62.83-25.58c-4.22,0.07-21.76-1.05-21.78,1.69c4.96,2.49-2.68,3.43-5.59,5.59',
    'c-13.97,3.42-28.96,22.7-35.57,21.09c-1.02,8.24-20.26,16.54-17.39,6.28c6.52,2.85,14.01-3.42,12.57-10.21',
    'c-2.06-3.59-3.91,0.72-1.17,2.86c-15.79,13.23,2.96-28.96,7.7-34.73c12.08-16.89,31.21-39.37,53.78-40.26',
    'c-1.79,2.6-6.97,2.91-7.41,3.9c13.72-1.61,35.18-1.79,42.25,8.29c-9.62-4.04-24.03-4.53-35.17-3.86',
    'c-18.03-11.55-79.23,67.73-40.39,33.5c8.75-11.46,49.99-41.72,69.48-19.48c-12.34-8.24-45.74-1.2-52.46,8.26',
    'c10.25-4.14,42.03-11.56,54.49-4.72c66.04,19.66-20.86,49.72,12.36,54.83c5.96,0.07,3.11-5.69-0.98-6.32',
    'c5.82-9.54,26.7-21.27,15.17-37.64c-4.51-11.28,21.83,14.17,18.65,2.28c3.98-2.89,4.18,6.81,4.18,7.45',
    'c2.4,1.48,4.66,3.11,6.79,4.8v-18.97c-1.01-2.35-1.93-4.74-2.72-7.14c-1.43-2.71-5.23-9.77-0.48-10.3',
    'c0.44,0.03,0.87,0.11,1.34,0.26l0.19,0.06l0.07-0.23c0.51-1.44,1.05-2.88,1.6-4.32v-44.56c-2.36,0.68-4.46,1.64-6.26,2.91',
    'c-41.58-15.3-147.09,13.03-143.38,70.77c3.95-4.64,6.83-13.7,14.01-16.65c-7.02,15-27.47,30.95-22.9,50',
    'c-4.31,4.69-5.61-13.75-6.29-3.68c-7.44,6.57,1.78,15.72,1.17,19.92c-17.36-13.61,12.45-77.1,22.76-92.79',
    'c19.36-10.08,37.65-20.39,57.54-26.29C704.82,190.9,666.96,196.22,669.11,191.96z M464.36,280.58c-7.23,1.44-2.28,6.27-4.07,8.74',
    'C439.72,283.58,459.8,257.15,464.36,280.58z M503.21,250.01c7.72-12.27,5.56-18.91,1.29-27.87c16.96,8.21,2.01,39.76-11.4,50.39',
    'c-4.91,1.48-13.44-0.08-17.66-1.83C486.52,266.95,498.83,262.96,503.21,250.01z M701.28,337.65',
    'c4.31-13.03,17.07,11.08,23.59,13.88C718.4,353.51,705.1,342.63,701.28,337.65z M679.3,309.74c1.39,23.5-21.68,37.46-5.42,3.34',
    'c3.63-6.59,2.16-12-5.95-10.93C675.46,294.85,684.24,297.78,679.3,309.74z M684.95,266.14c-7.64-0.12-15.65,6.18-23.33,7.84',
    'c-0.43-4.24,11.49-7.53,15.48-9.1c10.66,0.18,21.82-5.67,30.07-1.09C700.6,265.05,689.99,264.76,684.95,266.14z M696.11,292.89',
    'c2.71-3.02,3.57-12.48,7.47-11.38c0.78,2.65,3.12,0.88,4.67,0.79C709.96,285.94,689.8,304.75,696.11,292.89z M673.82,286.62',
    'c5.59-1.61,16.9-11.69,20.92-5.34C688.28,283.32,675.41,289.57,673.82,286.62z M656.86,300.26c7.43-7.85,9.74-3.04,19.61-10.08',
    'c15.87-7.32,18.59-2.6,10.78,11.58c-0.05,5.16-3.28,1.7-1.99-1.59C690.75,277.17,662.9,304.11,656.86,300.26z M709.63,202.24',
    'c3.62-1.39,26.36-6.88,18.91-1.91c-8.42,6.26,35.29,8.23,30.2-0.99C774.86,212.97,715.54,207.77,709.63,202.24z M675.94,223.88',
    'c17.71-24.34,94.06-14.04,90.61,26.38c-5.17,2.28-2.49-4.01-4.57-5.86c-3.92-1.35-20.3-4.38-18.15-3.19',
    'c10.82,3.29,23.5,17.21,4.87,10.57c-11.34-4.99-13.3-19.23-25.02-24.61c-11.57-6.42-40.41-2.09-26.34-8.56',
    'C689.2,217.84,681.33,229.33,675.94,223.88z M644.14,247.45c-15.06,13.62,3.98-19.53,9.47-14.35c0.04,0.06,0.33,0,0.44,0.03',
    'c-0.55,1.68,6.58-5.26,7.7-2.55c3.85,4.37-9.97,12.33-14.13,16.12C646.81,243.07,644.43,243.44,644.14,247.45z M679.88,197.48',
    'c-20.52,13.01-58,23.06-63.46,55.8c-6.63-11.55,8.98-35.13,17.97-44.27c-7.54-4.53-19.38-2.14-31.87-0.68',
    'c-3.07-0.35,0.35-2.01,1.89-2.72c-1.7-0.33-17.75,2.21-23.39,6.6c2.77-11.77,54.43-12.7,67.97-6.45',
    'c-6.15,6.56-21.6,9.53-23.21,18.81c11.93-8.6,24.01-17.05,37.84-23.29c-17.24-3.38-36.4-1.86-54.8-2.68',
    'c-17.13-2.77-41.4,10.09-53.38-1.09c-4.09,2.51,5.98,7.28,1.65,8.17C494.28,182.5,666.47,201.69,679.88,197.48z',
    'M759.02,281.27c-3.2,4.08,11.67,13.62,15.95,17c1.58,1.34,3.04,2.58,4.56,3.56v-5.46',
    'C771.87,292.43,763.07,287.59,759.02,281.27z',
    'M773.9,364.65c-43.68-1.65-26.45,6.76,2.56,3.71c1.01,0,2.03,0,3.07,0v-3.7c-0.48,0-0.97,0-1.44,0',
    'C776.67,364.65,775.27,364.65,773.9,364.65z',
    'M626.14,277.2l-0.68-0.06C625.63,277.17,625.98,277.22,626.14,277.2z',
    'M765.13,373.33c-1.35-0.71-3.08-1.08-3.87,0.22c-1.1,5.9-16.17-1.17-20.66,0.04',
    'c-10.58,2.41,6.73,6.23,11,5.07c9.24,0.09,18.68-0.82,27.93-1.82v-5.23c-4.66,0.31-9.3,0.93-13.51,1.83',
    'C765.71,373.51,765.38,373.46,765.13,373.33z',
    'M773.89,363.93C773.89,363.93,773.89,363.93,773.89,363.93C773.89,363.93,773.89,363.93,773.89,363.93z',
    'M547.97,263.12c-29.69,4.49,6.3-25.18-7.6-22.67c-41.9,61.37,21.9,31.85,26.09,50.68',
    'c-2.71,0.95-4.86-3.62-6.07-5.47c-1.56,1.37,3.85,10.51-0.89,8.84c-7.42-7.25-2.15,6.21-1.22,9.85c2.16-3.3,3.3-5.82,4.15-0.05',
    'c8.8,1.51,3.54-14.29,2.13-23.81C573.93,264.26,560.68,254.99,547.97,263.12z M561.53,264.98c-3.18,11.45-30.16,19.93-28.66,6',
    'C542.9,274.51,555.52,263.43,561.53,264.98z "> '
    )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;


library PlanetSurface4_1Descriptor {

  function getSVG() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<path class="clip_path" d="M487.79,262.81c-1.8,3.63-0.23,6.97,3.96,7.72c2.3-2.45-3.28-7.72-3.04-10.3c0,0,0,0,0,0c0,0,0,0,0,0',
        'C488.45,261.06,488.1,261.94,487.79,262.81z',
        'M430.07,307.27c0.14,0.07,0.27,0.14,0.41,0.21c-0.67-1.67,4.22-5.89-0.64-5.88',
        'C423.22,301.93,425.64,305.23,430.07,307.27z',
        'M425.64,311.35L425.64,311.35c1.32-2.89-2.37-3.73-5.36-3.84C421.54,309.7,422.46,311.3,425.64,311.35z',
        'M404.58,303.26c-2.49,2.34,4.63,2.54,4.31,0.57C408.1,303.35,405.86,303.07,404.58,303.26z',
        'M302.27,261.95c15.83,2.53,31.84-7.84,45.82-15.15c8.29,1.13,18.45-4.69,22.46-10.46',
        'c-4.38-3.28-11.16-5.35-16.63-4.82c4.39-6.01-12.02,0.89-10.91,2.88c-1.85,2.83-9.44-0.73-10.56,2.96',
        'c-3.06,6.93-21.39,13.74-22.77,20.19C305.28,259.87,303.66,260.53,302.27,261.95z',
        'M299.93,244.12c8.54-0.01-2.59-7.43-1.99-0.13c0.02,0,0.02,0,0.02,0',
        'C298.71,244.07,299.36,244.12,299.93,244.12z',
        'M178.9,292.07c15.04-6.46,31.65,10.35,31.7,1.55c-2.53-3.53-6.72-5.74-9.86-8.61',
        'c-2.44-6.27,2.28-10.13-7.48-12.88c2.11-2.65,4.98-6.01-0.26-6.81c-0.58-4.47,1.62-9.19,4.2-12.71c2.84-2.37,5.13-4.91,5.51-8.42',
        'c0.22-2.23,3.54-2.24,5.88-2.57c0.53-0.58,1.31-0.97,2.08-0.71c2.16-4-6.55-2.62-7.09-6.15c-0.74-2.03,1.23-3.61,0.89-5.55',
        'c-0.87-1.83-1.74-3.64-2.42-5.58c-1.19-1.75-4.24-1.1-5.04-3.12c-0.57-2.42,2.17-4.1,3.47-5.9c-0.17-1.59-0.75-3-1.67-4.42',
        'c9.61-2.84,20.91,4.52,27.82,0.27c2.57,1.2,5.31,2.11,8.06,2.84c2.18,3.16,7.38,2.13,10.83,1.71c4.57-8.12-2.7-6.16-7.58-8.53',
        'c-3.06-1.86-3.64-5.42-5.95-7.82c-1.99-3.05-19.27-6.01-14.66,1.05c0.89,0.46,1.74,0.89,2.67,1.35c-5.07,1.06,0.39,1.53,1.95,1.89',
        'c-4.99,3.58-14.2,1.74-18.62-1.25c3.78-1.17,2.97-4.78,3.65-7.75c1.36-2.44,1.11-5.18-1.71-6.55c-0.6-8.28-14.75-4.9-20.5-6.92',
        'c-3.03-1.01-5.14-3.76-8.55-3.95v116.19C177.13,292.45,177.94,292.19,178.9,292.07z',
        'M257.03,354.6c-2.58-0.71-5.27-1.16-7.95-1.35c-4.96-7.07-12.98-9.79-19.76-14.39',
        'c-1.38-0.63-2.21-0.38-3.6,0.04c-4.08,1.12-8.42,0.55-12.59,0.31c0.05-5.25-12.31-5.23-16.07-4.12',
        'c-4.43-2.89-10.51-5.15-15.79-4.19c-0.27,3.14-1.16,6.1-2.68,9.04c-0.84-0.28-1.64-0.63-2.38-1.07v24.01',
        'c6.9,1.82,5.04,0.4,7.08-5.15c4.46,2.43,12.26,1.5,14.18,6.64c4.09-1.13,7.84-2.14,11.05-4.92c0.53,1.03,1.97,1.89,3.34,1.7',
        'c-0.2-1.1,1.27-2.95,0.19-4.03v-0.01c3.69-2.35,7.56-3.18,10.98,0.07c3.37,1.94,8.32,3.27,12.7,3.94',
        'c8.56,1.68,17.1-0.28,25.67,0.07C265.53,359.58,259.79,354.91,257.03,354.6z M230.09,341.34c0.19-0.06,0.36-0.13,0.54-0.2',
        'l0.33,0.39C230.67,341.46,230.38,341.4,230.09,341.34z M253.69,357.26c-0.15-0.01-0.27-0.09-0.39-0.19',
        'c0.88,0.14,1.77,0.29,2.63,0.51C255.18,357.5,254.44,357.4,253.69,357.26z',
        'M423.04,287.23c-0.23-0.56-0.39-1.12-0.4-1.69c9.84,2.31,19.42-0.31,28.72-2.81',
        'c-0.07,3.55-8.49,8.1-1.42,10.09c3.13-2.03,1.88-6.63,9.7-6.42c5.99-1.14,8.8-1.37,12.5-4.05c3.96-3.6-2.07-8.49-0.22-12.71',
        'c2.27-3.32,5.42-6.57-1.56-5.34c-0.23-1.57-0.79-2.97-1.75-4.36c2.39-0.32,2.79-2.09,0.62-3.44c0.19-3.67,11.72-12.73,1.61-15.99',
        'c0.5,3.8-4.06,5.19-6.81,7.29c-0.61-1.57-1.57-3-2.7-4.27c0.19-3.57-0.87-6.98-3.16-9.98c1.49-2.05-0.96-5.09-3.18-6.43',
        'c6.24-7.58,17.14-7.3,25.5-10.67c23.98-13.26-14.48-13.36-23.24-13.66c-8.7-0.5-16.78-3.56-25.35-4.79',
        'c-5.66-1.23-21.12-1.64-29.72-1.03c-9.42,0.78-17.3,3.2-26.57,0.23c0.26,0.07,1.35,0.31,3.56,0.82',
        'c-5.43-0.34-10.74-0.53-16.29-0.9c-0.48-0.89-5.78-0.41-5.36,0.15c-14.8,0.69-28.64,6.2-43.38,7.42',
        'c-2.28-0.82-17.46-1.51-12.88,3.48c-5.01,1.54-2.51,5.51,1.74,5.35c5.53-1.43,10.03-3.39,15.84-2.18',
        'c6.36,0.58,12.69,0.09,18.12-3.38c3.89-0.76,8.05-0.29,12.02-0.03c-0.38,0.35-0.03,0.58,0.68,0.76c2.77-0.95,10.97,1.04,9.14,4.77',
        'c5.74,3.05,11.99,6.19,18.52,6.93c1.95,0.22,4.77-0.45,6.08,1.28c0.33,0.01,0.66,0.03,0.99,0.04c-0.3,0.93-0.84,1.9-0.9,2.7',
        'c-2.5,2.66-2.25,4.45,1.8,2.32c0.54,0.14,1.05,0.3,1.56,0.48c0.29,0.66,0.66,1.31,1.11,1.94c-2.05,2.62-5.56,6.54-0.53,8.02',
        'c1.91-0.34,4.15-0.02,5.68,1.22c2.21,0.56,5.82,2.75,3.05,4.94c-0.95,3.9-8.52,3.05-8.3,7.83c-0.83,0.3-1.46,1.05-1.45,1.99',
        'c0.21,0.05,0.43,0.06,0.67,0.05c-0.47,1.88-0.14,3.87,1.18,5.87c-1.54,3.39-6.35,1.61-9.06,3.22c-3.74,2.86-6.49,4.34-11.22,7.18',
        'c-7.62-3.54-16.15,3.12-23.05,5.63c-3.41,1.59-4.72,5.95-8.78,5.3c-2.31-11.87-20.47,8.22-6.13,6.93',
        'c-2.34,1.66,0.41,3.53,0.64,5.24c-4.28,4.09-10.47,3.83-15.06,7.13c-3.31,5.3-0.03,3.06-6.12,6.54c-3.1,0.6-9.1,1.21-3.15,4.12',
        'c4.12,1.79,7.69-0.1,11.31-1.17c-2.9,2.37-7.11,3.39-0.18,5.51c5.23-1.55,10.55-2.97,15.98-1.54c5.82,1.29,11.07,4.08,16.86,5.45',
        'c8.61,2.97,23-5.03,28.86,3.67c5.59-0.09,15.24,5.64,18.51-1.77c5.49-1.28,4.85-5.86,1.71-9.47c-2.67-1.68-5.34-2.55-6.92-5.07',
        'c1.01-3.48,8.67-3.91,11.07-7.62c4.91,0.94,8.03-1,11.76-2.31C421.27,294.76,426.88,293.8,423.04,287.23z',
        'M390.18,355.27c-4.6-5.8-16.96-12.69-21.59-12.77c-3.04-0.19-9.86,2.75-10.84-1.4',
        'c0.23-2.58,2.41-4.68,5.07-4.77c1.38-1.75,4.61-2.08,5.04-4.53c0.34-2.55-2.74-4.34-5.08-4.1c-1.08,0.1-1.59,0.65-2.23,1.38',
        'c-2.88,5.06-9.51,4.95-14.71,6.16c-16,2.28-20.94-6.03-42.77-3.25c-3.99-3.8-9.53-0.83-13.32,1.7c-4,2.3-17.79-8.19-15.14,1.83',
        'c-0.81,0.81-1.01,2.13-0.66,3.15c-3.3,3.45,5.2,6.05-1.17,7.85c-8.37,4.83,7.93,13.29,6.2,7.24c5.02-1.39,6.3,0.32,10.88,1.52',
        'c-0.1,1.26-0.59,2.48-1.6,3.5c-0.27,0.28-0.15,0.54,0.1,0.76c-3.33,1.13-13.11,3.42-5.42,6.8c2.29,0.72,4.29,0.22,6.02-0.97',
        'c2.27,0.17,4.44-0.26,6.5-1.05c4.13,3.51,10.65,1.53,15.36,0.12c7.47-1.13,16.54,5.66,23.28-0.06',
        'c17.16,3.71,35.24-4.77,48.61-10.03c1,0.04,2.19,0.19,2.85,0.87c2.07,2.15-3.28,7.63,2.62,9.39',
        'C393.3,362.99,393.28,358.72,390.18,355.27z M277.73,347.8c-0.79,0.27-1.23,1.09-1.98,1.27c0.64-1.24,2.27-1.51,3.37-2.29',
        'C278.96,347.31,278.23,347.55,277.73,347.8z',
        'M489.87,276.01c-1.92,0.93-0.36,3.56,3.28,4.1C497.68,277.92,493.38,275.28,489.87,276.01z',
        'M483.46,259.05c5.13,0.33,3.78-6.33,0.85-8.58c-2.61-1.17-5.08-2.58-7.11-0.66',
        'C475.28,252.3,479.13,258.87,483.46,259.05z',
        'M478.84,278.8c-2.65,2.64,3.61,4.37,1.61-0.12C479.91,278.54,479.22,278.56,478.84,278.8z',
        'M468.35,199.06c0.03,0.44,6.19,1.96,4.44,0.25C471.75,198.65,466.84,197.08,468.35,199.06z',
        'M464.06,296.53c-1-0.1-2.51,0.98-1.75,1.87C463.65,299.42,466.65,296.62,464.06,296.53z',
        'M460.44,225.7c-1.27-0.63-3.95-0.54-1.85,1.06C459.88,227.76,463.11,227.52,460.44,225.7z',
        'M450.88,305.67c4.03-1.12,7.9-2.87,6.45-5.47C454.49,295.41,446.64,302.43,450.88,305.67z',
        'M444,286.68c-1.27-2.55-6.23-0.29-3.13,2.1C442.26,288.69,443.95,288.1,444,286.68z',
        'M441.36,305.56c0.67-0.04,1.5-0.29,2.17-0.27c1.14-2.14-4-1.86-2.89-0.01',
        'C440.67,305.52,440.96,305.58,441.36,305.56z',
        'M441.09,291.02c-0.23,1.26-0.65,2.44-1.18,3.69C441.87,294.29,442.41,291.88,441.09,291.02z',
        'M439.34,296.33c-2.19-0.69-2.61,3.36-2.03,4.45C443.51,302.35,446.43,298.72,439.34,296.33z',
        'M426.59,371.84c-3.09-3.21-8.04-0.23-2.27,2.21C426.44,375.04,429.45,374.23,426.59,371.84z',
        'M405.32,185.47c-1-1.62-15.94-1.31-12.71-0.83C398.23,185.15,398.56,186.31,405.32,185.47z',
        'M384.11,249.57c3.45-3.8-2.51-3.35-1.68,0.43C383.05,250.15,383.64,249.94,384.11,249.57z',
        'M369.1,243.13c-8.43,7.05-4.84,8.06,4.1,4.92C376.66,245.38,376.34,240.02,369.1,243.13z',
        'M368.51,253.41c-4.97,2.21-1.53,7.53,2.7,7.78c8.97-0.55,6.33-7.4,1.57-8.43',
        'C370.96,252.73,369.56,252.98,368.51,253.41z',
        'M368.21,362.93c-0.83-0.03-2.07,0.16-3.8,0.64c1.12,5.07-13.24,4.62-9.41,9.59',
        'C357.52,374.54,373.95,364.62,368.21,362.93z',
        'M356.41,383.87c-0.94-0.2-3.94,0.02-3.23,1.24C354.36,386.27,362.33,384.74,356.41,383.87z',
        'M353.97,263.29c-2.68-0.08-1.62,3.39,0.21,3.49c1.36,0.06,2.02-1.64,2.4-2.64',
        'C356.8,264.09,354.74,263.28,353.97,263.29z',
        'M344.7,385.26c-4.54-4.19-23.27-7.75-20.17,3.17C327.57,388.6,346.6,390.1,344.7,385.26z',
        'M331.6,371.44c-0.11-1.31-2.14-1.7-3.27-1.7C326.9,370.98,331.12,373.76,331.6,371.44z',
        'M329.84,264.8c-1.99-0.42-2.74,1.3-2.56,3.29C331.13,268.13,332.88,266.03,329.84,264.8z',
        'M314.26,384.7c-0.61-0.4-2.04-0.65-1.3-1.22c5.45-1.49-6.13-4.2-7.6-4.57',
        'C297.71,380.02,319.28,389.22,314.26,384.7z',
        'M310.51,233.07c1.05-0.42,4.16-1.97,1.6-2.51C310.55,230.28,306.48,233.41,310.51,233.07z',
        'M296.92,250.42c3.26,2.14,12.98-2.18,9.9-6.08C304.24,242.69,294.81,246.83,296.92,250.42z',
        'M306.79,253.94c0.53-0.2,0.34-0.7,0-0.87C304.82,252.5,304.58,255.32,306.79,253.94z',
        'M309.01,387.28c-1.39-0.94-7.16-2.79-7.51-0.58C301.72,388.83,312.25,390,309.01,387.28z',
        'M285.7,259.81c3.2,1.83,7.74-1.07,8.35-4.46C293.23,249.72,280.61,256.07,285.7,259.81z',
        'M293.84,268.92c-0.64,0.62-0.8,1.29-0.61,1.93c-0.02,0.01-0.02,0.02,0,0.03c-0.07,0.74,0.29,1.25,0.76,1.76',
        'c-0.09,0.36,0.07,1.08,0.24,1.57c-6.74,2.23-5.64,7.59,1.37,6.72c4.68-2.59,14.44-1.44,17.25-5.74c0.29-0.81,0.14-1.44,0.73-2.24',
        'c2.51-2.21,5.79-2.81,9.01-2.37c7.46-1.79-5.33-9.56-11.45-7.01c-0.02-0.01-0.03-0.01-0.03,0c-5.84,0.26-9.78,3.45-14.42,4.08',
        'c-1.44-0.08-2.59,0.37-2.82,1.24C293.86,268.9,293.84,268.9,293.84,268.92z',
        'M288.8,382.92c-0.47-0.22-2.66-1.1-2.42-0.06C287.43,384.18,291.65,384.55,288.8,382.92z',
        'M242.22,268.24c-0.89-0.77-2.77-0.93-3.91-0.72C236.41,274.11,249.03,279.49,242.22,268.24z',
        'M240.44,306.03c5.72,3.61,1.97-8.07,1.58-10.34c-4.5-0.53-1.89,5.83-4.5,7.6',
        'C238.7,304.57,239.66,305.46,240.44,306.03z',
        'M240.56,251.57c-2.24-8.38,6.57-9.01,1.5-19.71c-5.77-2.08-5.61-3.21-1.81-6.65',
        'c2.05-3.21-12.04-5.95-11.72-2.59c-0.3,3.08,0.73,6.61-3.92,6.86c-1.18,7.1,6.02,3.99,4.6,6.3c-0.75,1.08-1.7,1.85-2.83,2.89',
        'c-3.74,1.78-4.41,7.18-7.12,9.87c-6.53,6.65-20.05,3.35-0.46,14.39c-8.88-2.12-5.85-0.43-9.18,5.55',
        'c-3.42,0.28-6.43,0.35-9.13,2.58c10.89,2.3,13.17,1.87,17.19-4.96c9.72,3.72,14.29-3.19,19.48-9.3',
        'C237.03,252.3,234.66,252.26,240.56,251.57z',
        'M692.99,261.95c15.83,2.53,31.84-7.84,45.82-15.15c8.29,1.13,18.45-4.69,22.46-10.46',
        'c-4.38-3.28-11.16-5.35-16.63-4.82c4.39-6.01-12.02,0.89-10.91,2.88c-1.85,2.83-9.44-0.73-10.56,2.96',
        'c-3.06,6.93-21.39,13.74-22.77,20.19C696,259.87,694.38,260.53,692.99,261.95z',
        'M690.65,244.12c8.54-0.01-2.59-7.43-1.99-0.13c0.02,0,0.02,0,0.02,0',
        'C689.42,244.07,690.08,244.12,690.65,244.12z',
        'M647.74,354.6c-2.58-0.71-5.27-1.16-7.95-1.35c-4.96-7.07-12.98-9.79-19.76-14.39',
        'c-1.38-0.63-2.21-0.38-3.6,0.04c-4.08,1.12-8.42,0.55-12.59,0.31c0.05-5.25-12.31-5.23-16.07-4.12'
    )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;


library PlanetSurface4_2Descriptor {

  function getSVG() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        'c-4.43-2.89-10.51-5.15-15.79-4.19c-0.27,3.14-1.16,6.1-2.68,9.04c-14.12-5.2-11.29-6.91-10.15,4.4',
        'c-0.5,3.33-3.72,9.81-11.34,11.14s-21.17,2.43-23.45,5.29c-2.29,2.86,0.71,4.67,7.69,3.6c6.98-1.07,21.28-3.9,23.78-2.73',
        'c3.34,1.36,11.23,1.07,12.06,1.45c6.09,1.81,4.25-0.95,6.12-5.35c4.46,2.43,12.26,1.5,14.18,6.64c4.09-1.13,7.84-2.14,11.05-4.92',
        'c0.53,1.03,1.97,1.89,3.34,1.7c-0.2-1.1,1.27-2.95,0.19-4.03v-0.01c3.69-2.35,7.56-3.18,10.98,0.07c3.37,1.94,8.32,3.27,12.7,3.94',
        'c8.56,1.68,17.1-0.28,25.67,0.07C656.25,359.58,650.51,354.91,647.74,354.6z M620.81,341.34c0.19-0.06,0.36-0.13,0.54-0.2',
        'l0.33,0.39C621.39,341.46,621.1,341.4,620.81,341.34z M644.41,357.26c-0.15-0.01-0.27-0.09-0.39-0.19',
        'c0.88,0.14,1.77,0.29,2.63,0.51C645.9,357.5,645.15,357.4,644.41,357.26z',
        'M778.66,199.24c-4.08-0.52-8.33-1.32-12.33-2.03c0.26,0.07,1.35,0.31,3.56,0.82',
        'c-5.43-0.34-10.74-0.53-16.29-0.9c-0.48-0.89-5.78-0.41-5.36,0.15c-14.8,0.69-28.64,6.2-43.38,7.42',
        'c-2.28-0.82-17.46-1.51-12.88,3.48c-5.01,1.54-2.51,5.51,1.74,5.35c5.53-1.43,10.03-3.39,15.84-2.18',
        'c6.36,0.58,12.69,0.09,18.12-3.38c3.89-0.76,8.05-0.29,12.02-0.03c-0.38,0.35-0.03,0.58,0.68,0.76c2.77-0.95,10.97,1.04,9.14,4.77',
        'c5.74,3.05,11.99,6.19,18.52,6.93c1.95,0.22,4.77-0.45,6.08,1.28c0.33,0.01,0.66,0.03,0.99,0.04c-0.3,0.93-0.84,1.9-0.9,2.7',
        'c-2.5,2.66-2.25,4.45,1.8,2.32c0.54,0.14,1.05,0.3,1.56,0.48c0.29,0.66,0.66,1.31,1.11,1.94c-2.77,3.08-5.64,8.03,0.85,7.89',
        'v-38.08C779.24,199.06,778.95,199.14,778.66,199.24z',
        'M778.65,250.6c-0.03,0.19-0.05,0.38-0.07,0.56c-0.83,0.3-1.46,1.05-1.45,1.99c0.21,0.05,0.43,0.06,0.67,0.05',
        'c-0.47,1.88-0.14,3.87,1.18,5.87c-1.54,3.39-6.35,1.61-9.06,3.22c-3.74,2.86-6.49,4.34-11.22,7.18',
        'c-7.62-3.54-16.15,3.12-23.05,5.63c-3.41,1.59-4.72,5.95-8.78,5.3c-2.31-11.87-20.47,8.22-6.13,6.93',
        'c-2.34,1.66,0.41,3.53,0.64,5.24c-4.28,4.09-10.47,3.83-15.06,7.13c-3.31,5.3-0.03,3.06-6.12,6.54c-3.1,0.6-9.1,1.21-3.15,4.12',
        'c4.12,1.79,7.69-0.1,11.31-1.17c-2.9,2.37-7.11,3.39-0.18,5.51c5.23-1.55,10.55-2.97,15.98-1.54c5.82,1.29,11.07,4.08,16.86,5.45',
        'c8.61,2.97,23-5.03,28.86,3.67c3.48,0.05,6.15,1.1,9.67,1.92v-75.47C779.04,249.25,778.77,249.86,778.65,250.6z',
        'M777.68,352.02c-5.12-4.54-14.88-9.6-18.37-9.53c-3.03-0.19-9.87,2.75-10.84-1.4',
        'c0.23-2.58,2.41-4.68,5.07-4.77c1.38-1.75,4.61-2.08,5.04-4.53c0.34-2.55-2.74-4.34-5.08-4.1c-1.08,0.1-1.59,0.65-2.23,1.38',
        'c-2.88,5.06-9.51,4.95-14.71,6.16c-16,2.28-20.94-6.03-42.77-3.25c-3.99-3.8-9.53-0.83-13.32,1.7c-4,2.3-17.79-8.19-15.14,1.83',
        'c-0.81,0.81-1.01,2.13-0.66,3.15c-3.3,3.45,5.2,6.05-1.17,7.85c-8.37,4.83,7.93,13.29,6.2,7.24c5.02-1.39,6.3,0.32,10.88,1.52',
        'c-0.1,1.26-0.59,2.48-1.6,3.5c-0.27,0.28-0.15,0.54,0.1,0.76c-3.33,1.13-13.11,3.42-5.42,6.8c2.29,0.72,4.29,0.22,6.02-0.97',
        'c2.27,0.17,4.44-0.26,6.5-1.05c4.13,3.51,10.65,1.53,15.36,0.12c7.47-1.13,16.54,5.66,23.28-0.06',
        'c17.16,3.71,35.24-4.77,48.61-10.03c1,0.04,2.19,0.19,2.85,0.87c1.94,1.71-3.31,9.4,3.25,9.14v-10.59',
        'C778.95,353.15,778.34,352.6,777.68,352.02z M668.45,347.8c-0.79,0.27-1.23,1.09-1.98,1.27c0.64-1.24,2.27-1.51,3.37-2.29',
        'C669.68,347.31,668.95,347.55,668.45,347.8z',
        'M774.83,249.57c3.45-3.8-2.51-3.35-1.68,0.43C773.76,250.15,774.36,249.94,774.83,249.57z',
        'M759.82,243.13c-8.43,7.05-4.84,8.06,4.1,4.92C767.37,245.38,767.06,240.02,759.82,243.13z',
        'M759.23,253.41c-4.97,2.21-1.53,7.53,2.7,7.78c8.97-0.55,6.33-7.4,1.57-8.43',
        'C761.68,252.73,760.27,252.98,759.23,253.41z',
        'M758.93,362.93c-0.83-0.03-2.07,0.16-3.8,0.64c1.12,5.07-13.24,4.62-9.41,9.59',
        'C748.24,374.54,764.67,364.62,758.93,362.93z',
        'M747.13,383.87c-0.94-0.2-3.94,0.02-3.23,1.24C745.08,386.27,753.05,384.74,747.13,383.87z',
        'M744.69,263.29c-2.68-0.08-1.62,3.39,0.21,3.49c1.36,0.06,2.02-1.64,2.4-2.64',
        'C747.52,264.09,745.46,263.28,744.69,263.29z',
        'M735.42,385.26c-4.54-4.19-23.27-7.75-20.17,3.17C718.29,388.6,737.32,390.1,735.42,385.26z',
        'M722.32,371.44c-0.11-1.31-2.14-1.7-3.27-1.7C717.62,370.98,721.83,373.76,722.32,371.44z',
        'M720.55,264.8c-1.99-0.42-2.74,1.3-2.56,3.29C721.85,268.13,723.6,266.03,720.55,264.8z',
        'M704.98,384.7c-0.61-0.4-2.04-0.65-1.3-1.22c5.45-1.49-6.13-4.2-7.6-4.57',
        'C688.43,380.02,710,389.22,704.98,384.7z',
        'M701.23,233.07c1.05-0.42,4.16-1.97,1.6-2.51C701.27,230.28,697.2,233.41,701.23,233.07z',
        'M687.64,250.42c3.26,2.14,12.98-2.18,9.9-6.08C694.96,242.69,685.53,246.83,687.64,250.42z',
        'M697.51,253.94c0.53-0.2,0.34-0.7,0-0.87C695.54,252.5,695.3,255.32,697.51,253.94z',
        'M699.73,387.28c-1.39-0.94-7.16-2.79-7.51-0.58C692.44,388.83,702.97,390,699.73,387.28z',
        'M676.42,259.81c3.2,1.83,7.74-1.07,8.35-4.46C683.95,249.72,671.33,256.07,676.42,259.81z',
        'M684.56,268.92c-0.64,0.62-0.8,1.29-0.61,1.93c-0.02,0.01-0.02,0.02,0,0.03c-0.07,0.74,0.29,1.25,0.76,1.76',
        'c-0.09,0.36,0.07,1.08,0.24,1.57c-6.74,2.23-5.64,7.59,1.37,6.72c4.68-2.59,14.44-1.44,17.25-5.74c0.29-0.81,0.14-1.44,0.73-2.24',
        'c2.51-2.21,5.79-2.81,9.01-2.37c7.46-1.79-5.33-9.56-11.45-7.01c-0.02-0.01-0.03-0.01-0.03,0c-5.84,0.26-9.78,3.45-14.42,4.08',
        'c-1.44-0.08-2.59,0.37-2.82,1.24C684.58,268.9,684.56,268.9,684.56,268.92z',
        'M679.52,382.92c-0.47-0.22-2.66-1.1-2.42-0.06C678.15,384.18,682.37,384.55,679.52,382.92z',
        'M632.93,268.24c-0.89-0.77-2.77-0.93-3.91-0.72C627.12,274.11,639.75,279.49,632.93,268.24z',
        'M631.16,306.03c5.72,3.61,1.97-8.07,1.58-10.34c-4.5-0.53-1.89,5.83-4.5,7.6',
        'C629.42,304.57,630.38,305.46,631.16,306.03z',
        'M631.27,251.57c-2.24-8.38,6.57-9.01,1.5-19.71c-5.77-2.08-5.61-3.21-1.81-6.65',
        'c2.05-3.21-12.04-5.95-11.72-2.59c-0.3,3.08,0.73,6.61-3.92,6.86c-1.18,7.1,6.02,3.99,4.6,6.3c-0.75,1.08-1.7,1.85-2.83,2.89',
        'c-3.74,1.78-4.41,7.18-7.12,9.87c-6.53,6.65-20.05,3.35-0.46,14.39c-8.88-2.12-5.85-0.43-9.18,5.55',
        'c-3.42,0.28-6.43,0.35-9.13,2.58c10.89,2.3,13.17,1.87,17.19-4.96c9.72,3.72,14.29-3.19,19.48-9.3',
        'C627.75,252.3,625.38,252.26,631.27,251.57z',
        'M553.44,341.71c0.7-1.58,0.3-3.41-1.12-4.55c-1.03-1.96-6.68-0.98-8.51-0.11',
        'c-4.84,4.03-11.41,6.31-14.35,12.4c-0.25,0.46,4.32,2.21,4.75,1.42c0.31-0.58,0.67-1.15,1.05-1.71c2.83,0.38,4.66-2.58,7.38-3.1',
        'c2.46,1.01,12.89,0.86,9.3-3.64C552.41,342.27,553.17,342.13,553.44,341.71z',
        'M525.98,328.14c3.12-1.25,7.81-0.68,11.02-2.42c4.04-2.51,3.79-3.14,8.79-2.86c4.18-0.17,6.64-1.43,7.21-7.78',
        'c-2.84-7.49-0.95-9.36,6.65-10.9c2.06-0.18,0.4-2.91,1.66-5.6c4.27-7.12,7.6-5.89,13.38-7.89c6.75-0.77,13.39,1.94,19.73,3.95',
        'c2.4,1.49,6.8,3.56,6.89-1c-2.53-3.53-6.72-5.74-9.86-8.61c-2.44-6.27,2.28-10.13-7.48-12.88c2.11-2.65,4.98-6.01-0.26-6.81',
        'c-0.58-4.47,1.62-9.19,4.2-12.71c2.84-2.37,5.13-4.91,5.51-8.42c0.22-2.23,3.54-2.24,5.88-2.57c0.53-0.58,1.31-0.97,2.08-0.71',
        'c2.16-4-6.55-2.62-7.09-6.15c-0.74-2.03,1.23-3.61,0.89-5.55c-0.87-1.83-1.74-3.64-2.42-5.58c-1.19-1.75-4.24-1.1-5.04-3.12',
        'c-0.57-2.42,2.17-4.1,3.47-5.9c-0.17-1.59-0.75-3-1.67-4.42c9.61-2.84,20.91,4.52,27.82,0.27c2.57,1.2,5.31,2.11,8.06,2.84',
        'c2.18,3.16,7.38,2.13,10.83,1.71c4.57-8.12-2.7-6.16-7.58-8.53c-3.06-1.86-3.64-5.42-5.95-7.82c-1.99-3.05-19.27-6.01-14.66,1.05',
        'c0.89,0.46,1.74,0.89,2.67,1.35c-5.07,1.06,0.39,1.53,1.95,1.89c-4.99,3.58-14.2,1.74-18.62-1.25c3.78-1.17,2.97-4.78,3.65-7.75',
        'c1.36-2.44,1.11-5.18-1.71-6.55c-0.61-8.27-14.74-4.9-20.5-6.92c-3.03-1.01-5.14-3.76-8.55-3.95c0,0-18.08-0.96-30.71,2.03',
        'c-12.64,2.99-2.66,6.65-1.66,8.98c1,2.33,2.49,3.16,2.33,3.82c-0.17,0.67-1.83,1,0.17,2.33c2,1.33,6.65-0.32,7.32,2.92',
        'c0.35,7.57,1.21,8.16,6.9,10c-4.03,3.52-0.63,4.16,2.97,3.73c-0.96,1.74-0.25,3.32,1.6,3.84c-4.51,1.06-10.31,2.32-13.46,2.61',
        'c-6.09,1.37-13.31-2.15-16.28,2.31c-11.55-5.42-24.63,9.57-13.99,18.15c-7.01,4.77-2.99,7.95,3.49,9.26',
        'c1.92,10.45,18.02,8.11,8.87-0.52c0.15-0.14,0.29-0.29,0.43-0.45c5.43,1.96,5.3-3.73,2.36-6.55c5.61,0.55,9.23,2.9,14.46,7.81',
        'c2.99,3.61,9.48,3.84,11.47,6.39s8.72,3.39,10.48,7.05c1.81,6.33-6.01,10.64-10.02,9c-5.25-16.68-17.87-1.65-9,9.96',
        'c0.9,1.54,1.73,2.8,1.56,4.63c-2.57,7.29-11.31,3.56-7.41,16c-5.86-1.17-7.54,7.28-13.23,6.72c-1.22,0.12-2.47,0.41-3.54,1.02',
        'c-3.05-1.12-6.47-0.75-9.56,0.03c-9.52-2.81-20.89-4.81-29.93,0.26c-12.27-0.66-24.83-2.94-37.17-0.37',
        'c-4.84-1.6-10.27-0.96-10.13,4.75c-9.39,1.9-7.48,14.86,2.14,12.57c2.25,2.76,5.72,3.22,8.78,2.38c0.74,0.59,1.52,1.17,2.33,1.73',
        'c-0.36,4.49,5.66,5.27,9.09,6.24c5.78,1.4,10.75,4.58,15.56,7.77c8,6.15,18.17,7.55,27.88,8.79c10.92,4.84,18.02,0.74,8.56-9.72',
        'c0-0.01-0.02-0.01-0.02-0.01c-1.24-1.66-2.88-3.93-1.59-5.78c0.5-0.27,1.02-0.98,1.61-0.86',
        'C516.13,336.54,520.7,330.69,525.98,328.14z M512.39,236.78c-0.03-0.05-0.03-0.09,0.02-0.09',
        'C512.43,236.7,512.42,236.73,512.39,236.78z M512.93,242.67C512.91,242.81,512.83,242.82,512.93,242.67L512.93,242.67z',
        'M522.81,249.32c0-0.01,0-0.01-0.01-0.02C522.76,249.19,522.99,249.37,522.81,249.32z "> '
    )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;

import "../PlanetColor.sol";
pragma abicoder v2;

library PlanetRing1Descriptor {

  function getSVG(PlanetColor.PlanetColorPalette memory planetColorPalette_) public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<linearGradient id="RING_1_LG_1" gradientUnits="userSpaceOnUse" ',
        'x1="156.6662" y1="302.3599" x2="892.5151" y2="251.0216"> ',
        '<stop  offset="0" style="stop-color:#A7B8C3"/> ',
        '<stop  offset="0.4969" style="stop-color:#', planetColorPalette_.colorRing,'"/> ',
        '</linearGradient> ',
        '<path style="fill:url(#RING_1_LG_1);" d="M398.16,150.23',
        'c-8.8-7.07-34.07,8.43-66.15,38.25c0.6,0.31,1.2,0.63,1.8,0.97c29.55-27.79,52.37-42.39,59.95-36.31',
        'c7.79,6.22-2.1,32.76-23.79,68.95c-1.59,2.66-3.26,5.39-4.98,8.14c-4.42,7.09-9.24,14.5-14.43,22.17',
        'c-0.52,0.79-1.08,1.61-1.63,2.41c-12.33,18.04-26.66,37.39-42.47,57.13c-4.66,5.84-9.31,11.52-13.95,17.06',
        'c-2.04,2.44-4.08,4.84-6.09,7.21c-14.48,16.98-28.62,32.38-41.8,45.64c-2.4,2.41-4.76,4.75-7.08,7.02',
        'c-32.91,32.1-58.75,49.54-66.95,42.99c-8.52-6.82,4.14-37.98,30.29-79.53c-0.86,0.12-1.74,0.22-2.61,0.33',
        'c-26.76,43.43-39.21,76.38-29.55,84.12c9.46,7.59,37.98-10.91,73.51-45.21c2.59-2.5,5.23-5.1,7.91-7.79',
        'c14.43-14.45,29.82-31.26,45.44-49.82c2.04-2.4,4.05-4.81,6.08-7.27c3.06-3.7,6.12-7.45,9.18-11.27',
        'c17.06-21.31,32.34-42.24,45.3-61.7c0.52-0.78,1.04-1.56,1.55-2.32c3.88-5.88,7.54-11.61,10.96-17.18',
        'c1.55-2.5,3.03-4.96,4.47-7.39C396.74,187.17,407.27,157.52,398.16,150.23z"/> ',
        '<linearGradient id="RING_1_LG_2" gradientUnits="userSpaceOnUse" ',
        'x1="99.5356" y1="330.8851" x2="901.7024" y2="252.0497"> ',
        '<stop offset="0" style="stop-color:#A7B8C3"/> ',
        '<stop offset="0.4969" style="stop-color:#', planetColorPalette_.colorRing,'"/> ',
        '</linearGradient> ',
        '<path style="fill:url(#RING_1_LG_2);" d="M457.59,259.11',
        'c-2.59-10.86-31.42-14.16-74.25-10.5c0.2,0.63,0.41,1.25,0.6,1.88c39.7-3.64,66.15-1.14,68.38,8.23',
        'c2.3,9.53-20.89,24.06-59,39.06c-1.92,0.77-3.88,1.52-5.89,2.28c-24.06,9.14-53.45,18.36-85.78,26.66',
        'c-2.03,2.46-4.04,4.88-6.08,7.27c33.99-8.47,65.05-18.15,90.7-27.94c2.42-0.93,4.79-1.85,7.11-2.78',
        'C434.85,286.74,460.25,270.21,457.59,259.11z',
        'M285.98,330.6c-29.07,6.97-56.74,12.29-81.33,15.85c-0.91,0.14-1.83,0.27-2.73,0.41c-0.97,0.14-1.92,0.27-2.89,0.41',
        'c-0.23,0.03-0.46,0.06-0.69,0.09c-53.23,7.23-90.54,5.84-93.22-5.37c-2.54-10.59,26.4-27.36,72.31-44.09',
        'c-0.12-0.69-0.21-1.38-0.29-2.07c-48.7,18.06-79.45,36.72-76.54,48.89c3.06,12.72,42.21,15.07,97.68,7.96',
        'c0.87-0.11,1.75-0.21,2.61-0.33c0.29-0.05,0.55-0.08,0.81-0.11c0.19-0.03,0.38-0.05,0.57-0.07',
        'c25.41-3.41,54.09-8.78,84.17-15.95c2.01-2.37,4.05-4.77,6.09-7.21C290.34,329.55,288.17,330.08,285.98,330.6z"/> '
      )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library PlanetRing2Descriptor {

  function getSVG() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<path class="fill_ring" d="M449.18,121.1c-2.43-2.43-9.81-9.82-64.92,33.02c-13.99,10.89-29.37,23.71-45.6,38.02',
        'c-23.87,21.02-49.57,45.23-75.44,71.09c-25.83,25.83-50.01,51.5-71.01,75.33c-14.32,16.26-27.18,31.67-38.09,45.69',
        'c-42.84,55.11-35.45,62.5-33.02,64.93c1.7,1.7,4.12,2.49,7.2,2.49c20.07,0,67.02-34.19,108.76-73.2',
        'c-1.44-0.66-2.86-1.38-4.27-2.13c-45.96,42.77-78.21,62.7-95.23,68.73c-7.12,2.52-11.6,2.61-13.28,0.91',
        'c-0.72-0.7-5.88-8.46,33.39-58.96c10.65-13.7,23.16-28.71,37.1-44.55c21.12-24.03,45.52-49.96,71.64-76.07',
        'c26.13-26.14,52.1-50.57,76.14-71.7c15.81-13.92,30.8-26.4,44.46-37.04c50.5-39.27,58.26-34.11,58.98-33.39',
        'c0.43,0.43,3.22,4.09-5.1,20.48c-1.86,3.69-4.29,8.01-7.44,13.08c-8.96,14.43-26.21,38.86-57.72,73.59',
        'c0.77,1.41,1.5,2.84,2.21,4.27C420.62,188.85,461.1,133.02,449.18,121.1z"/> ',
        '<path class="fill_ring" d="M438.39,144c4.11-8.21,2.46-9.86,1.57-10.74c-4.38-4.39-23.86,7.18-57.87,34.38',
        'c-11.17,8.93-23.17,19.02-35.62,29.89c-24.91,21.78-51.63,46.77-76.98,72.14c-25.29,25.29-50.21,51.89-71.9,76.71',
        'c-10.95,12.52-21.09,24.59-30.04,35.79c-27.14,33.96-38.67,53.4-34.27,57.79c0.45,0.44,1.08,1.08,2.65,1.08',
        'c3.3,0,10.74-2.84,29.18-16.29c16.56-12.07,38.07-29.84,62.32-51.46c-0.9-0.53-1.79-1.08-2.65-1.65',
        'c-62.1,55.3-87.05,68.54-89.39,66.2c-1.3-1.3,2.32-13.53,34.5-53.79c8.84-11.05,18.81-22.93,29.58-35.27',
        'c21.77-24.9,46.76-51.6,72.14-77c25.47-25.47,52.29-50.55,77.28-72.38c12.25-10.71,24.07-20.62,35.07-29.43',
        'c40.35-32.25,52.59-35.89,53.89-34.59c2.32,2.33-10.91,27.23-66.14,89.3c0.57,0.87,1.11,1.75,1.65,2.64',
        'c21.58-24.21,39.31-45.69,51.39-62.22C431.91,155.3,436.07,148.61,438.39,144z"/> ',
        '<path class="fill_ring" d="M422.09,151.88c-2.41-2.43-18.07,8.77-46.53,33.27c-6.84,5.88-13.98,12.18-21.36,18.81',
        'c-24.15,21.72-50.77,47.02-76.98,73.25c-26.19,26.19-51.48,52.8-73.18,76.92c-6.64,7.39-12.98,14.57-18.87,21.42',
        'c-24.5,28.45-35.7,44.11-33.27,46.54c0.21,0.21,0.54,0.32,0.96,0.32c8.4,0,55.29-41.04,68.7-52.93c-0.42-0.29-0.84-0.59-1.26-0.89',
        'c-42.42,37.71-64.93,53.39-67.3,52.48c-1.18-3.11,18.87-28.89,52.1-65.84c20.14-22.41,45.15-48.93,73.18-76.96',
        'c28.07-28.06,54.61-53.08,77.04-73.26c36.91-33.2,62.66-53.27,65.69-52.11c0.97,2.47-14.67,24.93-52.35,67.32',
        'c0.32,0.4,0.61,0.82,0.9,1.24C382.14,207.26,426.63,156.42,422.09,151.88z"/> '
      )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library PlanetRing3Descriptor {

  function getSVG() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<path style="opacity:0.6;" class="fill_ring" d="M411.17,180.15c91.21,27.57,108.84,102.78,39.36,167.98c-69.48,65.22-199.75,95.73-290.97,68.16',
        's-108.83-102.78-39.35-168c33.08-31.05,79.94-54.22,129.81-67c-17.52,5.6-33.06,15.65-45.29,28.79',
        'c-25.8,11.31-49.12,25.95-67.63,43.33c-62.39,58.53-46.56,126.06,35.32,150.81c41.55,12.55,92.13,11.68,140.04,0.13',
        'c46.49-11.2,90.45-32.47,121.17-61.32c62.37-58.55,46.56-126.06-35.33-150.81c-23.64-7.15-50.2-9.95-77.54-8.9',
        'c-11.88-4.59-24.78-7.11-38.28-7.11c-5.28,0-10.47,0.39-15.54,1.14C316.75,167.07,368.29,167.19,411.17,180.15z"/> ',
        '<path style="opacity:0.55;" class="fill_ring" d="M388.85,201.11c75.02,22.68,89.51,84.54,32.37,138.16c-25.45,23.88-60.82,42.12-98.86,52.99',
        'c-47.37,13.53-98.85,15.66-140.46,3.08c-75.03-22.68-89.52-84.54-32.37-138.18c12.1-11.36,26.44-21.44,42.25-30.05',
        'c-2.37,3.85-4.49,7.88-6.34,12.03c-9.89,6.26-18.96,13.17-26.99,20.71c-53.4,50.11-39.87,107.91,30.24,129.11',
        'c35.21,10.63,77.97,10.02,118.59,0.42c40.27-9.51,78.43-27.85,105.02-52.8c53.4-50.11,39.85-107.93-30.24-129.1',
        'c-9.87-2.99-20.32-5.07-31.17-6.33c-3.46-2.93-7.11-5.62-10.93-8.1C357.11,193.88,373.64,196.52,388.85,201.11z"/> ',
        '<path style="opacity:0.75;" class="fill_ring" d="M392.24,197.91c-18.06-5.46-37.93-8.23-58.53-8.57c2.13,1.17,4.2,2.41,6.24,3.71',
        'c17.16,0.82,33.69,3.46,48.9,8.05c75.02,22.68,89.51,84.54,32.37,138.16c-25.46,23.88-60.82,42.12-98.86,53',
        'c-47.37,13.53-98.85,15.66-140.46,3.07c-75.03-22.68-89.52-84.54-32.37-138.18c12.11-11.35,26.45-21.44,42.25-30.05',
        'c1.26-2.05,2.58-4.06,3.98-6.03c-19.11,9.66-36.41,21.33-50.68,34.72c-59.03,55.39-44.06,119.3,33.42,142.71',
        'c42.89,12.96,95.93,10.82,144.75-3.09c39.41-11.19,76.08-30.06,102.43-54.81C484.7,285.23,469.73,221.34,392.24,197.91z"/> ',
        '<path style="opacity:0.8;" class="fill_ring" d="M398.32,192.23c-23.64-7.15-50.2-9.94-77.54-8.89c2.73,1.05,5.4,2.21,8.03,3.48',
        'c23.22-0.13,45.64,2.7,65.89,8.8c79.26,23.96,94.56,89.31,34.18,145.98c-29.71,27.9-72.24,48.5-117.22,59.36',
        'c-46.38,11.19-95.37,12.05-135.62-0.12c-79.26-23.97-94.57-89.32-34.18-145.99c15.91-14.94,35.52-27.78,57.2-38.15',
        'c1.8-2.28,3.69-4.48,5.68-6.61c-25.8,11.31-49.12,25.95-67.63,43.34c-62.39,58.53-46.56,126.06,35.32,150.81',
        'c41.55,12.55,92.13,11.69,140.04,0.14c46.48-11.21,90.45-32.48,121.17-61.32C496.01,284.49,480.2,216.98,398.32,192.23z"/> ',
        '<path style="opacity:0.35;" class="fill_ring" d="M382.06,207.48c-9.87-2.98-20.32-5.07-31.17-6.33c4.1,3.42,7.92,7.16,11.43,11.18',
        'c0.9,0.96,1.77,1.92,2.62,2.91c2.31,0.57,4.61,1.2,6.86,1.88c62.66,18.95,74.76,70.6,27.03,115.39',
        'c-13.29,12.46-29.8,23.1-48.09,31.53c-28.34,13.06-60.89,20.85-92.16,22.08c-21.01,0.84-41.44-1.3-59.62-6.79',
        'c-62.66-18.93-74.76-70.59-27.03-115.39c2.31-2.16,4.73-4.28,7.23-6.33c1.53-6.39,3.64-12.55,6.29-18.45',
        'c-9.89,6.25-18.96,13.17-26.98,20.71c-53.4,50.11-39.87,107.91,30.24,129.11c35.21,10.63,77.97,10.02,118.59,0.42',
        'c40.28-9.51,78.44-27.85,105.02-52.8C465.7,286.47,452.15,228.66,382.06,207.48z"/> '
      )
    );
  }
}