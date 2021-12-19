// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import 'base64-sol/base64.sol';
import "./PlanetsDescriptor.sol";
import "./utils/SVGUtils.sol";
import "./interface/ISVGDescriptor.sol";
import "./layersSVG/PictureFrameDescriptor.sol";
import "./layersSVG/DataDescriptor/DataDescriptor.sol";
import "./layersSVG/SkyDescriptor/SkyDescriptor.sol";

// Todo access role
contract SVGDescriptor is ISVGDescriptor {

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

    constructor(){}

  function constructTokenURI(uint256 tokenId_, bytes32 blockhashInit_, PlanetsDescriptor.PlanetMetadata memory planetMetadata_) public view override returns (string memory) {

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

    string memory image = Base64.encode(bytes(generateSVGImage1(tokenId_, blockhashInit_, planetMetadata_)));

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
                image,
                '"}'
              )
            )
          )
      ));
  }

  function generateSVGImage1(uint256 tokenId_, bytes32 blockhashInit_, PlanetsDescriptor.PlanetMetadata memory planetMetadata_) private view returns (string memory svg) {
      uint offsetRandomInit = 1124;
      // initial RandomHash
      //bytes32 randomHash = PlanetRandom.getRandomHash(blockhashInit_, tokenId_);


      (string memory svgSky, uint newOffsetRandom) = SkyDescriptor.getSVG(tokenId_, blockhashInit_, offsetRandomInit);

      svg = string(abi.encodePacked(
        '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" ',
        'y="0px" viewBox="0 0 566.93 935.43" xml:space="preserve"> ',
        '<style type="text/css"> ',
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
        '</style> ',
        svgSky,
        PictureFrameDescriptor.getSVG(),
        DataDescriptor.getSVG(tokenId_, planetMetadata_),
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

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./utils/SVGUtils.sol";
import "./interface/IPlanetsDescriptor.sol";
import "./interface/ISVGDescriptor.sol";
import "./interface/IPlanetsManager.sol";
import "./utils/PlanetRandom.sol";

contract PlanetsDescriptor is AccessControl, IPlanetsDescriptor {

  struct PlanetPosition {
    uint256 x;
    uint256 y;
  }

  struct PlanetMetadata {
    string name;
    uint256 habitability;
    uint256 temperature;
    uint256 size;
    uint256 nSatellite;
    PlanetPosition position;
  }

  address public planetManagerAddress;
  address  public planetNameAddress;
  uint public planetPositionDecimals = 18;

  mapping (uint => PlanetPosition) public planetCoordinates;

  IPlanetsManager private planetsManager;

  bool canChangeSvgDescriptor = true;
  ISVGDescriptor public svgDescriptor;

  /**
  * @dev Throws if called by any address other than the planet contract.
  */
  // TODO make role PLANET_MANAGER instead of onlyPlanet
  modifier onlyPlanet() {
    require(planetManagerAddress != address(0), "PlanetDescriptor: planet manager contract is not already assigned");
    require(planetManagerAddress == _msgSender(), "PlanetDescriptor: caller is not the planet manager contract");
    _;
  }

  mapping (uint256 => bytes32) _tokenIdToBlockhash;

  constructor (address _svgDescriptor, address _planetsManager) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    svgDescriptor = ISVGDescriptor(_svgDescriptor);
    planetsManager = IPlanetsManager(_planetsManager);
    planetManagerAddress = _planetsManager;
  }

  function addPlanetNameAddress(address planetNameAddress_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    planetNameAddress = planetNameAddress_;
  }

  function initPlanet(uint256 tokenId_) external virtual override onlyPlanet {
    _tokenIdToBlockhash[tokenId_] = blockhash(block.number - 1);
  }

  function computeMysteryHash(uint _tokenId) external view returns (bytes32) {
    uint originalTokenId = computeTokenIdFromShiftedTokenId(_tokenId);

    bytes32 unveilBlockHash = planetsManager.unveilBlockHash();
    bytes32 mysteryHash = keccak256(abi.encodePacked(unveilBlockHash, _tokenIdToBlockhash[originalTokenId]));

    return mysteryHash;
  }

  /**
  * @notice Constructs the token uri of the specified token
  * @param _tokenId The SHIFTED token id.
  * @dev For other details see {IPlanetDescriptor-tokenURI}. Note that this fucntion
          is supposed to be called only by the PlanetsManager
  */
  // TODO only planet manager can call this function
  function tokenURI(uint _tokenId) external view virtual override onlyPlanet returns (string memory)  {
    bytes32 mysteryHash = this.computeMysteryHash(_tokenId);

    // getMetadata
    PlanetMetadata memory planetMetadata = getMetadata(_tokenId, mysteryHash);

    return svgDescriptor.constructTokenURI(_tokenId, mysteryHash, planetMetadata);
  }

  /**
   * @notice Computes the originale token id that generated the specified shifted token id
   * @param _shiftedTokenId The shifted token id
   * @return originalId uint The original token id
   */
  function computeTokenIdFromShiftedTokenId(uint _shiftedTokenId) public view returns (uint) {
    require(_shiftedTokenId > 0 && _shiftedTokenId <= 1123, "PlanetsDescriptor: invalid shifted token id");

    uint shift = planetsManager.unveilIndex();
    uint maxPlanetsSupply = planetsManager.MAX_PLANET_SUPPLY();
    uint originalId;

    if (shift < _shiftedTokenId) {
      originalId = _shiftedTokenId - shift - 1;
    }
    else {
      originalId = maxPlanetsSupply + _shiftedTokenId - shift - 1;
    }

    // exclude sun
    if (originalId == 0) {
      originalId = maxPlanetsSupply;
    }

    return originalId;
  }

  function getMetadata(uint256 tokenId_, bytes32 mysteryHash_) public view returns(PlanetMetadata memory){
    PlanetMetadata memory planetMetadata;
    planetMetadata.habitability = PlanetRandom.calcRandom(1,100, mysteryHash_, tokenId_);

    planetMetadata.temperature = PlanetRandom.calcRandom(173, 373, mysteryHash_, tokenId_); // ° kelvin

    planetMetadata.size = PlanetRandom.calcRandom(1000,3000, mysteryHash_, tokenId_);

    planetMetadata.nSatellite = PlanetRandom.calcRandom(0,20, mysteryHash_, tokenId_);

    planetMetadata.position = planetCoordinates[tokenId_];

    planetMetadata.name = planetNameAddress == address(0) ?
      string(abi.encodePacked("Planet ",SVGUtils.uint2str(tokenId_, 0)))
      :
      ""; //IPlanetName(planetNameAddress).getPlanetNameById(tokenId_);

    return planetMetadata;
  }

  /**
   * @notice Batch add planet coordinates
   * @param _tokenIds Tokens ids relative to the positio at the same index
   * @param _xCoord X coordinates
   * @param _yCoord Y coordinates
   */
  function insertPlanetCoordinates(uint[] memory _tokenIds, uint[] memory _xCoord, uint[] memory _yCoord) external onlyRole(DEFAULT_ADMIN_ROLE) {
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
   * @notice Change SVG Descriptor contract address
   * @param _descriptor The address of the new SVG Descriptor
   */
  function changeSVGDescriptor(address _descriptor) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(canChangeSvgDescriptor, "Planet Descriptor: can't change SVG descriptor");
    require(_descriptor != address(svgDescriptor), "Planet Descriptor: same SVG descriptor address");

    svgDescriptor = ISVGDescriptor(_descriptor);
  }

  /**
   * @notice Disable the opportunity to change the address of the SVG descriptor
   */
  function disableSVGDescriptoUpgradability() external onlyRole(DEFAULT_ADMIN_ROLE) {
    canChangeSvgDescriptor = false;
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
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;

import "./../PlanetsDescriptor.sol";

interface ISVGDescriptor {
    function constructTokenURI(uint256 tokenId_, bytes32 blockhashInit_, PlanetsDescriptor.PlanetMetadata memory planetMetadata_) external view returns (string memory);
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
import "../../utils/PlanetRandom.sol";
import "./SkyStar/SkyStarDescriptor.sol";
import "./SkyPurple/SkyPurpleDescriptor.sol";
import "./SkyDark/SkyDarkDescriptor.sol";
import "./SkyBrown/SkyBrownDescriptor.sol";


library SkyDescriptor {

  function getSVG(uint256 tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public view returns (string memory svg, uint offsetRandom) {

    string memory svgLayer;
    uint newOffsetRandom;

    // select random sky layer
    uint randomSkyLayer = PlanetRandom.calcRandom(0,4, blockhashInit_, tokenId_);

    if (randomSkyLayer == 0) { // dark layer
      (svgLayer, newOffsetRandom) = SkyDarkDescriptor.getSVG(tokenId_, blockhashInit_, offsetRandom_);
      svg = string(
        abi.encodePacked(
          '<g id="sky_dark"> ',
          svgLayer,
          '</g> '
        )
      );
    } else if (randomSkyLayer == 1) { // star layer
      (svgLayer, newOffsetRandom) = SkyStarDescriptor.getSVG(tokenId_, blockhashInit_, offsetRandom_);
      svg = string(
        abi.encodePacked(
          '<g id="sky_star"> ',
          svgLayer,
          '</g> '
        )
      );
    } else if (randomSkyLayer == 2) { // brown layer
      (svgLayer, newOffsetRandom) = SkyBrownDescriptor.getSVG(tokenId_, blockhashInit_, offsetRandom_);
      svg = string(
        abi.encodePacked(
          '<g id="sky_brown"> ',
          svgLayer,
          '</g> '
        )
      );
    } else { // purple layer
      (svgLayer, newOffsetRandom) = SkyPurpleDescriptor.getSVG(tokenId_, blockhashInit_, offsetRandom_);
      svg = string(
        abi.encodePacked(
          '<g id="sky_purple"> ',
          svgLayer,
          '</g> '
        )
      );
    }
    offsetRandom = newOffsetRandom;
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

interface IPlanetsDescriptor{


  /**
  * @dev return SVG code
  */
  function tokenURI(uint256 tokenId_) external view returns  (string memory);

  function initPlanet(uint256 tokenId_) external;
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;

interface IPlanetsManager {
  function unveilBlockHash() external view returns (bytes32);
  function unveilIndex() external view returns (uint);

  function MAX_PLANET_SUPPLY() external view returns (uint);
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import 'base64-sol/base64.sol';


library PlanetRandom {

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
      getPositionField(123, 345), // todo add position pyton
      getHabitabilityField(planetMetadata_.habitability),
      getTemperatureField(planetMetadata_.temperature),
      getSatelliteField(planetMetadata_.nSatellite)
    )
    );
  }

  function getPositionField(uint xPosition_, uint yPosition_) private pure returns (string memory svg) {

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
        '<text transform="matrix(1 0 0 1 75.7793 770.3943)" class="text_metadata">',SVGUtils.uint2str(xPosition_, 0),'  -  ',SVGUtils.uint2str(yPosition_, 0),'</text> '
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
import "./SkyStarCircleDescriptor.sol";
import "./SkyStarPathDescriptor.sol";


library SkyStarDescriptor {

    function getSVG(uint256 tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public view returns (string memory svg, uint offsetRandom) {

        (string memory svgPathShadow, uint newOffsetRandom) = SkyStarPathDescriptor.getPathShadow(tokenId_, blockhashInit_, offsetRandom_);
        //(string memory svgCircle, uint newOffsetRandom2) = SkyStarCircleDescriptor.getCircle(tokenId_, blockhashInit_, newOffsetRandom);

        offsetRandom = newOffsetRandom; // todo set offsetRandom2
        svg = string(
            abi.encodePacked(
                '<radialGradient id="SKY_STAR_LG_1" cx="283.4646" cy="283.4646" r="283.4646" gradientUnits="userSpaceOnUse"> ',
                '<stop  offset="0" style="stop-color:#4F4FA6"/> ',
                '<stop  offset="0.35" style="stop-color:#212145"/> ',
                '<stop  offset="0.6706" style="stop-color:#0F1120"/> ',
                '</radialGradient> ',
                '<path style="fill:url(#SKY_STAR_LG_1);" d="M0,0v935.43h566.9V0H0z"/> ',
                //svgCircle,
                svgPathShadow
            )
        );
    }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import "./SkyPurpleCircleDescriptor.sol";
import "./SkyPurpleRhombusDescriptor.sol";
import "./SkyPurplePathDescriptor.sol";


library SkyPurpleDescriptor {

  function getSVG(uint256 tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public pure returns (string memory svg, uint offsetRandom) {

    (string memory svgRhombus, uint newOffsetRandom) = SkyPurpleRhombusDescriptor.getRhombus(tokenId_, blockhashInit_, offsetRandom_);
    (string memory svgPathShadow, uint newOffsetRandom2) = SkyPurplePathDescriptor.getPathShadow(tokenId_, blockhashInit_, newOffsetRandom);
    //(string memory svgCircle, uint newOffsetRandom3) = SkyPurpleCircleDescriptor.getCircle(tokenId_, blockhashInit_, newOffsetRandom2);

    offsetRandom = newOffsetRandom2; // toto set offsetRandom4
    svg = string(
      abi.encodePacked(
        '<radialGradient id="SKY_PURPLE_MAIN" cx="289.8016" cy="275.1698" r="511.3439" gradientUnits="userSpaceOnUse"> ',
        '<stop  offset="0" style="stop-color:#7A346D"/> ',
        '<stop  offset="0.337" style="stop-color:#331A2E"/> ',
        '<stop  offset="0.6867" style="stop-color:#140912"/> ',
        '</radialGradient> ',
        '<path style="fill:url(#SKY_PURPLE_MAIN);" d="M0,0v935.43h566.9V0H0z"/> ',
        //svgCircle,
        svgRhombus,
        svgPathShadow
    )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import "./SkyDarkCircleDescriptor.sol";
import "./SkyDarkPathDescriptor.sol";

library SkyDarkDescriptor {

  function getSVG(uint256 tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public pure returns (string memory svg, uint offsetRandom) {

    (string memory svgPath, uint newOffsetRandom) = SkyDarkPathDescriptor.getPath(tokenId_, blockhashInit_, offsetRandom_);
  //(string memory svgCircle, uint newOffsetRandom2) = SkyDarkCircleDescriptor.getCircle(tokenId_, blockhashInit_, newOffsetRandom);

    offsetRandom = newOffsetRandom; // todo set offsetRandom2
    svg = string(
      abi.encodePacked(
        '<linearGradient id="SKY_DARK_LG_MAIN" gradientUnits="userSpaceOnUse" ',
        'x1="283.4646" y1="3.1512" x2="283.4646" y2="562.0206"> ',
        '<stop  offset="0.1587" style="stop-color:#224D4D"/> ',
        '<stop  offset="0.315" style="stop-color:#12414A"/> ',
        '<stop  offset="0.8087" style="stop-color:#0A1913"/> </linearGradient> ',
        '<path style="fill:url(#SKY_DARK_LG_MAIN);" d="M0,0v935.43h566.9V0H0z"/> ',
        //svgCircle,
        svgPath
      )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import "./SkyBrownCircleDescriptor.sol";
import "./SkyBrownPathDescriptor.sol";


library SkyBrownDescriptor {

  function getSVG(uint256 tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public pure returns (string memory svg, uint offsetRandom) {

    (string memory svgPathShadow, uint newOffsetRandom) = SkyBrownPathDescriptor.getPathShadow(tokenId_, blockhashInit_, offsetRandom_);
    //(string memory svgCircle, uint newOffsetRandom2) = SkyBrownCircleDescriptor.getCircle(tokenId_, blockhashInit_, newOffsetRandom);
    //(string memory svgPathComets, uint newOffsetRandom3) = SkyStarPathDescriptor.getPathComets(tokenId_, blockhashInit_, newOffsetRandom2);

    offsetRandom = newOffsetRandom; // todo set offsetRandom2
    svg = string(
      abi.encodePacked(
        '<radialGradient id="SKY_BROWN_MAIN" cx="268.519" cy="295.4548" r="324.6202" gradientUnits="userSpaceOnUse"> ',
        '<stop  offset="0.0634" style="stop-color:#543833"/> ',
        '<stop  offset="0.4356" style="stop-color:#362209"/> ',
        '<stop  offset="0.89" style="stop-color:#0F0903"/> ',
        '</radialGradient> ',
        '<path style="fill:url(#SKY_BROWN_MAIN);" d="M0,0v935.43h566.9V0H0z"/> ',
        //svgCircle,
        svgPathShadow
        //svgPathComets
    )
    );
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;
import "../../../utils/PlanetRandom.sol";
import "../../../utils/SVGUtils.sol";

library SkyStarCircleDescriptor {

    struct ParamsCircle {
        string fillClass;
        uint nMin;
        uint nMax;

    }

    function getCircle(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public view returns (string memory svg, uint offsetRandom) {

        (string memory svgCircleWhite, uint newOffsetRandom1) = getCircleSVG(tokenId_, blockhashInit_, offsetRandom_, ParamsCircle("fill_white_star",50,100) );
        (string memory svgCircleRed, uint newOffsetRandom2) = getCircleSVG(tokenId_, blockhashInit_, newOffsetRandom1, ParamsCircle("fill_red_star",30,60) );
        (string memory svgCircleBlue, uint newOffsetRandom3) = getCircleSVG(tokenId_, blockhashInit_, newOffsetRandom2, ParamsCircle("fill_blue_star",50,100) );
        (string memory svgCirclePurple, uint newOffsetRandom4) = getCircleSVG(tokenId_, blockhashInit_, newOffsetRandom3, ParamsCircle("fill_purple_star",30,60) );

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

    function getCircleSVG(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_, ParamsCircle memory paramsCircle) private view returns (string memory svg, uint offsetRandom) {
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
import "../../../utils/PlanetRandom.sol";
import "../../../utils/SVGUtils.sol";
import "./SkyStarPath1_2Descriptor.sol";
import "./SkyStarPath3_4Descriptor.sol";


library SkyStarPathDescriptor {

  function getPathShadow(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public pure returns (string memory svg, uint offsetRandom) {
    uint index = 0;

    bytes32 randomHashPath = PlanetRandom.getRandomHash(blockhashInit_, tokenId_ + offsetRandom_);
    offsetRandom_ = offsetRandom_ + 1124;

    // select random path layer
    uint randomPathLayer = PlanetRandom.calcRandomBytes1(0, 4, randomHashPath, index);

    if (randomPathLayer == 0) {
      svg = SkyStarPath1_2Descriptor.getPath1();
    } else if (randomPathLayer == 1) {
      svg = SkyStarPath1_2Descriptor.getPath2();
    } else if (randomPathLayer == 2) {
      svg = SkyStarPath3_4Descriptor.getPath3();
    } else {
      svg = SkyStarPath3_4Descriptor.getPath4();
    }

    offsetRandom = offsetRandom_;
  }
  /*
    function getPathComets(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public pure returns (string memory svg, uint offsetRandom) {
      (string memory svgCometsNE, uint newOffsetRandom) = getCometNE(tokenId_, blockhashInit_, offsetRandom_);

      svg = string(
        abi.encodePacked(
          svgCometsNE
        )
      );

      offsetRandom = newOffsetRandom;
    }

    function getCometNE(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) private pure returns(string memory svg, uint offsetRandom) {
      uint index = 0;
      bytes32 randomHashCometNe = PlanetRandom.getRandomHash(blockhashInit_, tokenId_  + offsetRandom);
      offsetRandom_ = offsetRandom_ + 1124;

      uint xPoint = PlanetRandom.calcRandomBytes1(0, 566, randomHashCometNe, index);
      index ++;
      uint yPoint = PlanetRandom.calcRandomBytes1(0, 935, randomHashCometNe, index);
      index ++;

      uint x1 = int(xPoint) - 226 > 0 ? xPoint - 226: 226 - xPoint;
      uint y = yPoint + 150;
      uint x2 = int(xPoint) - 181 > 0 ? xPoint - 181: 181 - xPoint;
      svg = string(
        abi.encodePacked(
          '<linearGradient id="LG_COMET_NE" gradientUnits="userSpaceOnUse" ',
          'x1="',int(xPoint) - 226 > 0 ?"":"-",SVGUtils.uint2str(x1, 0),'" y1="',SVGUtils.uint2str(y,0),'" ',
          'x2="',int(xPoint) - 118 > 0 ?"":"-",SVGUtils.uint2str(x2, 0),'" y2="',SVGUtils.uint2str(y,0),'"> ',
          '<stop  offset="0" style="stop-color:#3B5883;stop-opacity:0"/> ',
          '<stop  offset="1" style="stop-color:#8AB4D7"/> ',
          '</linearGradient> ',
          '<path style="fill:url(#LG_COMET_NE);" d="M',SVGUtils.uint2str(xPoint, 0),',',SVGUtils.uint2str(yPoint, 0),'',
          'c0,0-31.09,30.6-31.43,30.26l0,0c-0.34-0.34,30.2-31.5,30.2-31.5c0.34-0.34,0.89-0.34,1.23,0l0,0z"/> '

      )
      );

      offsetRandom = offsetRandom_;
    }

    function getCometSE(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) private pure returns(string memory svg, uint offsetRandom) {
      uint index = 0;
      bytes32 randomHashCometNe = PlanetRandom.getRandomHash(blockhashInit_, tokenId_  + offsetRandom);
      offsetRandom_ = offsetRandom_ + 1124;

      uint xPoint = PlanetRandom.calcRandomBytes1(0, 566, randomHashCometNe, index);
      index ++;
      uint yPoint = PlanetRandom.calcRandomBytes1(0, 935, randomHashCometNe, index);
      index ++;

      uint x1 = int(xPoint) - 226 > 0 ? xPoint - 226: 226 - xPoint;
      uint y = yPoint + 150;
      uint x2 = int(xPoint) - 181 > 0 ? xPoint - 181: 181 - xPoint;
      svg = string(
        abi.encodePacked(
      '<linearGradient id="LG_COMET_SE" gradientUnits="userSpaceOnUse" ',
      'x1="514.0268" y1="-102.4346" ',
      'x2="558.5244" y2="-102.4346" > ',
      '<stop  offset="0" style="stop-color:#3B5883;stop-opacity:0"/> ',
      '<stop  offset="1" style="stop-color:#8AB4D7"/> ',
      '</linearGradient> ',
      '<path style="fill:url(#LG_COMET_SE);" d="M451.37,650.21',
      'c0,0-41.58-13.2-41.44-13.66l0,0c0.14-0.46,41.95,11.99,41.95,11.99c0.46,0.14,0.72,0.63,0.58,1.09l0,0',
      'C452.32,650.1,451.83,650.36,451.37,650.21z"/> '

      )
      );

      offsetRandom = offsetRandom_;
    }
  */
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library SkyStarPath1_2Descriptor {

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

library SkyStarPath3_4Descriptor {

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
import "../../../utils/SVGUtils.sol";


library SkyPurpleCircleDescriptor {

  function getCircle(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public pure returns (string memory svg, uint offsetRandom) {

    (string memory svgCircleWhite, uint newOffsetRandom1) = getCircleWhite(tokenId_, blockhashInit_, offsetRandom_);
    (string memory svgCircleRed, uint newOffsetRandom2) = getCircleRed(tokenId_, blockhashInit_, newOffsetRandom1);

    offsetRandom = newOffsetRandom2;

    svg = string(
      abi.encodePacked(
        svgCircleWhite,
        svgCircleRed
      )
    );

  }

  function getCircleWhite(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) private pure returns (string memory svg, uint offsetRandom) {
    uint index = 0;

    bytes32 randomHashCircleWhite = PlanetRandom.getRandomHash(blockhashInit_, tokenId_ + offsetRandom_);
    offsetRandom_ = offsetRandom_ + 1124;

    uint nCircle = PlanetRandom.calcRandomBytes1(50, 100, randomHashCircleWhite, index);
    index ++;

    string memory svgTemp = "";

    for(uint i = 0; i < nCircle ; i++) {
      if (index == 31 || index +1 == 31 || index +2 == 31 ) {
        randomHashCircleWhite = PlanetRandom.getRandomHash(blockhashInit_, tokenId_ + offsetRandom_);
        offsetRandom_ = offsetRandom_ + 1124;
        index = 0;
      }
      uint xPoint = PlanetRandom.calcRandomBytes1(0, 566, randomHashCircleWhite, index);
      index ++;
      uint yPoint = PlanetRandom.calcRandomBytes1(0, 935, randomHashCircleWhite, index);
      index ++;
      uint size = PlanetRandom.calcRandomBytes1(0, 25, randomHashCircleWhite, index);
      index ++;

      svgTemp = string(
        abi.encodePacked(
          svgTemp,
          '<circle class="circle_white" ',
          'cx="', SVGUtils.uint2str(xPoint, 0), '" ',
          'cy="', SVGUtils.uint2str(yPoint, 0), '" ',
          'r="', SVGUtils.uint2str(size, 1),'"/> '
        )
      );
    }

    svg = svgTemp;
    offsetRandom = offsetRandom_;
  }

  function getCircleRed(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) private pure returns (string memory svg, uint offsetRandom) {
    uint index = 0;

    bytes32 randomHashCircleRed = PlanetRandom.getRandomHash(blockhashInit_, tokenId_  + offsetRandom);
    offsetRandom_ = offsetRandom_ + 1124;

    uint nCircle = PlanetRandom.calcRandomBytes1(30, 60, randomHashCircleRed, index);
    index ++;

    string memory svgTemp = "";

    for(uint i = 0; i < nCircle ; i++) {
      if (index == 31 || index +1 == 31 || index +2 == 31 ) {
        randomHashCircleRed = PlanetRandom.getRandomHash(blockhashInit_, tokenId_ + offsetRandom_);
        offsetRandom_ = offsetRandom_ + 1124;
        index = 0;
      }
      uint xPoint = PlanetRandom.calcRandomBytes1(0, 566, randomHashCircleRed, index);
      index ++;
      uint yPoint = PlanetRandom.calcRandomBytes1(0, 935, randomHashCircleRed, index);
      index ++;
      uint size = PlanetRandom.calcRandomBytes1(0, 25, randomHashCircleRed, index);
      index ++;

      svgTemp = string(
        abi.encodePacked(
          svgTemp,
          '<circle class="circle_red" ',
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
import "../../../utils/PlanetRandom.sol";
import "../../../utils/SVGUtils.sol";


library SkyPurpleRhombusDescriptor {

  function getRhombus(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public pure returns (string memory svg, uint offsetRandom) {

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

    uint nRhombus = PlanetRandom.calcRandomBytes1(2, 4, randomHashRhombusBig, index);
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
          'L', SVGUtils.uint2str(xPoint - 1, 0), ',', SVGUtils.uint2str(yPoint + 16, 0),
          'c-0.2-1-1-1.7-2-1.9',
          'L', SVGUtils.uint2str(xPoint - 12, 0), ',', SVGUtils.uint2str(yPoint + 13, 0),
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

    uint nRhombus = PlanetRandom.calcRandomBytes1(3, 6, randomHashRhombusMedium, index);
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

    uint nRhombus = PlanetRandom.calcRandomBytes1(6, 12, randomHashRhombusSmall, index);
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
import "../../../utils/PlanetRandom.sol";
import "./SkyPurplePath1_2Descriptor.sol";
import "./SkyPurplePath3_4Descriptor.sol";


library SkyPurplePathDescriptor {

  function getPathShadow(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public pure returns (string memory svg, uint offsetRandom) {
    uint index = 0;

    bytes32 randomHashPath = PlanetRandom.getRandomHash(blockhashInit_, tokenId_ + offsetRandom_);
    offsetRandom_ = offsetRandom_ + 1124;

    // select random path layer
    uint randomPathLayer = PlanetRandom.calcRandomBytes1(0, 4, randomHashPath, index);

    if (randomPathLayer == 0) {
      svg = SkyPurplePath1_2Descriptor.getPath1();
    } else if (randomPathLayer == 1) {
      svg = SkyPurplePath1_2Descriptor.getPath2();
    } else if (randomPathLayer == 2) {
      svg = SkyPurplePath3_4Descriptor.getPath3();
    } else {
      svg = SkyPurplePath3_4Descriptor.getPath4();
    }

    offsetRandom = offsetRandom_;
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library SkyPurplePath1_2Descriptor {

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

library SkyPurplePath3_4Descriptor {

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
import "../../../utils/PlanetRandom.sol";
import "../../../utils/SVGUtils.sol";


library SkyDarkCircleDescriptor {

  function getCircle(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public pure returns (string memory svg, uint offsetRandom) {

    (string memory svgCircleWhite, uint newOffsetRandom1) = getCircleWhite(tokenId_, blockhashInit_, offsetRandom_);
    (string memory svgCircleRed, uint newOffsetRandom2) = getCircleRed(tokenId_, blockhashInit_, newOffsetRandom1);
    (string memory svgCircleBlue, uint newOffsetRandom3) = getCircleBlue(tokenId_, blockhashInit_, newOffsetRandom2);
    (string memory svgCirclePurple, uint newOffsetRandom4) = getCirclePurple(tokenId_, blockhashInit_, newOffsetRandom3);

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

  function getCircleWhite(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) private pure returns (string memory svg, uint offsetRandom) {
    uint index = 0;

    bytes32 randomHashCircleWhite = PlanetRandom.getRandomHash(blockhashInit_, tokenId_ + offsetRandom_);
    offsetRandom_ = offsetRandom_ + 1124;

    uint nCircle = PlanetRandom.calcRandomBytes1(40, 80, randomHashCircleWhite, index);
    index ++;

    string memory svgTemp = "";

    for(uint i = 0; i < nCircle ; i++) {
      if (index == 31 || index +1 == 31 || index +2 == 31 ) {
        randomHashCircleWhite = PlanetRandom.getRandomHash(blockhashInit_, tokenId_ + offsetRandom_);
        offsetRandom_ = offsetRandom_ + 1124;
        index = 0;
      }
      uint xPoint = PlanetRandom.calcRandomBytes1(0, 566, randomHashCircleWhite, index);
      index ++;
      uint yPoint = PlanetRandom.calcRandomBytes1(0, 935, randomHashCircleWhite, index);
      index ++;
      uint size = PlanetRandom.calcRandomBytes1(0, 25, randomHashCircleWhite, index);
      index ++;

      svgTemp = string(
        abi.encodePacked(
          svgTemp,
          '<circle class="circle_white" ',
          'cx="', SVGUtils.uint2str(xPoint, 0), '" ',
          'cy="', SVGUtils.uint2str(yPoint, 0), '" ',
          'r="', SVGUtils.uint2str(size, 1),'"/> '
        )
      );
    }

    svg = svgTemp;
    offsetRandom = offsetRandom_;
  }

  function getCircleRed(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) private pure returns (string memory svg, uint offsetRandom) {
    uint index = 0;

    bytes32 randomHashCircleRed = PlanetRandom.getRandomHash(blockhashInit_, tokenId_  + offsetRandom);
    offsetRandom_ = offsetRandom_ + 1124;

    uint nCircle = PlanetRandom.calcRandomBytes1(20, 40, randomHashCircleRed, index);
    index ++;

    string memory svgTemp = "";

    for(uint i = 0; i < nCircle ; i++) {
      if (index == 31 || index +1 == 31 || index +2 == 31 ) {
        randomHashCircleRed = PlanetRandom.getRandomHash(blockhashInit_, tokenId_ + offsetRandom_);
        offsetRandom_ = offsetRandom_ + 1124;
        index = 0;
      }
      uint xPoint = PlanetRandom.calcRandomBytes1(0, 566, randomHashCircleRed, index);
      index ++;
      uint yPoint = PlanetRandom.calcRandomBytes1(0, 935, randomHashCircleRed, index);
      index ++;
      uint size = PlanetRandom.calcRandomBytes1(0, 25, randomHashCircleRed, index);
      index ++;

      svgTemp = string(
        abi.encodePacked(
          svgTemp,
          '<circle class="circle_red" ',
          'cx="', SVGUtils.uint2str(xPoint, 0), '" ',
          'cy="', SVGUtils.uint2str(yPoint, 0), '" ',
          'r="', SVGUtils.uint2str(size, 1),'"/> '
        )
      );
    }

    svg = svgTemp;
    offsetRandom = offsetRandom_;
  }

  function getCircleBlue(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) private pure returns (string memory svg, uint offsetRandom) {
    uint index = 0;

    bytes32 randomHashCircleBlue = PlanetRandom.getRandomHash(blockhashInit_, tokenId_  + offsetRandom);
    offsetRandom_ = offsetRandom_ + 1124;

    uint nCircle = PlanetRandom.calcRandomBytes1(40, 80, randomHashCircleBlue, index);
    index ++;

    string memory svgTemp = "";

    for(uint i = 0; i < nCircle ; i++) {
      if (index == 31 || index +1 == 31 || index +2 == 31 ) {
        randomHashCircleBlue = PlanetRandom.getRandomHash(blockhashInit_, tokenId_ + offsetRandom_);
        offsetRandom_ = offsetRandom_ + 1124;
        index = 0;
      }
      uint xPoint = PlanetRandom.calcRandomBytes1(0, 566, randomHashCircleBlue, index);
      index ++;
      uint yPoint = PlanetRandom.calcRandomBytes1(0, 935, randomHashCircleBlue, index);
      index ++;
      uint size = PlanetRandom.calcRandomBytes1(0, 25, randomHashCircleBlue, index);
      index ++;

      svgTemp = string(
        abi.encodePacked(
          svgTemp,
          '<circle class="circle_blue" ',
          'cx="', SVGUtils.uint2str(xPoint, 0), '" ',
          'cy="', SVGUtils.uint2str(yPoint, 0), '" ',
          'r="', SVGUtils.uint2str(size, 1),'"/> '
        )
      );
    }

    svg = svgTemp;
    offsetRandom = offsetRandom_;
  }

  function getCirclePurple(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) private pure returns (string memory svg, uint offsetRandom) {
    uint index = 0;

    bytes32 randomHashCirclePurple = PlanetRandom.getRandomHash(blockhashInit_, tokenId_ + offsetRandom_);
    offsetRandom_ = offsetRandom_ + 1124;

    uint nCircle = PlanetRandom.calcRandomBytes1(20, 40, randomHashCirclePurple, index);
    index ++;

    string memory svgTemp = "";

    for(uint i = 0; i < nCircle ; i++) {
      if (index == 31 || index +1 == 31 || index +2 == 31 ) {
        randomHashCirclePurple = PlanetRandom.getRandomHash(blockhashInit_, tokenId_ + offsetRandom_);
        offsetRandom_ = offsetRandom_ + 1124;
        index = 0;
      }
      uint xPoint = PlanetRandom.calcRandomBytes1(0, 566, randomHashCirclePurple, index);
      index ++;
      uint yPoint = PlanetRandom.calcRandomBytes1(0, 935, randomHashCirclePurple, index);
      index ++;
      uint size = PlanetRandom.calcRandomBytes1(0, 25, randomHashCirclePurple, index);
      index ++;

      svgTemp = string(
        abi.encodePacked(
          svgTemp,
          '<circle class="circle_purple" ',
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
import "../../../utils/PlanetRandom.sol";
import "./SkyDarkPath1_2Descriptor.sol";
import "./SkyDarkPath3_4Descriptor.sol";


library SkyDarkPathDescriptor {

  function getPath(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public pure returns (string memory svg, uint offsetRandom) {
    uint index;

    bytes32 randomHashPath = PlanetRandom.getRandomHash(blockhashInit_, tokenId_ + offsetRandom_);
    offsetRandom_ = offsetRandom_ + 1124;

    // select random path layer
    uint randomPathLayer = PlanetRandom.calcRandomBytes1(0, 4, randomHashPath, index);

    if (randomPathLayer == 0) {
      svg = SkyDarkPath1_2Descriptor.getPath1();
    } else if (randomPathLayer == 1) {
      svg = SkyDarkPath1_2Descriptor.getPath2();
    } else if (randomPathLayer == 2) {
      svg = SkyDarkPath3_4Descriptor.getPath3();
    } else {
      svg = SkyDarkPath3_4Descriptor.getPath4();
    }

    offsetRandom = offsetRandom_;
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library SkyDarkPath1_2Descriptor {

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
        '<linearGradient id="SKY1_LG1" gradientUnits="userSpaceOnUse" x1="69.1293" y1="377.9744" x2="400.7008" y2="377.9744"> ',
        '<stop  offset="5.952380e-03" style="stop-color:#0B0A16"/> ',
        '<stop  offset="1" style="stop-color:#1D6EAF"/> ',
        '</linearGradient> ',
        '<path style="opacity:0.15;fill:url(#SKY1_LG1);" d="M109.11,366.43',
        'c-7.78-1.44-18.31-3.5-29.36-6.21c-8.35-2.05-14.15,8.16-8.15,14.31c5.68,5.83,11.83,11.21,17.17,13.84',
        'c4.48,2.72,9.18,4.87,13.98,6.06c24.02,5.97,39.65-7.4,55.56-2.1C160.27,387.66,123.28,369.05,109.11,366.43z"/> ',
        '<linearGradient id="SKY1_LG2" gradientUnits="userSpaceOnUse" x1="289.8289" y1="240.5063" x2="566.9291" y2="240.5063"> ',
        '<stop  offset="0" style="stop-color:#FFFFFF"/> ',
        '<stop  offset="0.994" style="stop-color:#0B0A16"/> ',
        '</linearGradient> ',
        '<path style="fill:url(#SKY1_LG2);opacity:0.5;" d="M439.9,299.66',
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
        '<linearGradient id="SKY1_LG3" gradientUnits="userSpaceOnUse" x1="-53.8455" y1="58.5552" x2="169.0079" y2="58.5552"> ',
        '<stop  offset="5.952380e-03" style="stop-color:#0B0A16"/> ',
        '<stop  offset="1" style="stop-color:#1D6EAF"/> ',
        '</linearGradient> ',
        '<path style="opacity:0.15;fill:url(#SKY1_LG3);" d="M90.24,0',
        'c0,0-0.2,82.43,60.2,115.48c12.39,6.78,24.68-9.11,15.2-19.58C144.4,72.42,123,38.31,128.86,0H90.24z"/> ',
        '<linearGradient id="SKY1_LG4" gradientUnits="userSpaceOnUse" x1="8.8616" y1="670.2307" x2="302.4382" y2="670.2307"> ',
        '<stop  offset="5.952380e-03" style="stop-color:#0B0A16"/> ',
        '<stop  offset="1" style="stop-color:#1D6EAF"/> ',
        '</linearGradient> ',
        '<path style="opacity:0.15;fill:url(#SKY1_LG4);" d="M76.98,662.58',
        'c-16.96-10.97-18.95,31.92-29.93,47.89c-4.75,6.9-18.26-43.82-2.99-95.77c28.44-96.77,70.03-138.35,99.08-168.59',
        'c14.39-14.98,15.17-53.78-29.38-36.91C77.11,423.07,12.62,496.32,8.99,668.41c-4.3,203.63,104.77,267.03,104.77,267.03h80.94',
        'h72.49h35.25c-68.59-6.32-177.58-47.81-212.2-147.15C71.45,734.35,83.71,666.94,76.98,662.58z"/> ',
        '<linearGradient id="SKY1_LG5" gradientUnits="userSpaceOnUse" x1="444.4587" y1="192.6205" x2="566.9291" y2="192.6205"> ',
        '<stop  offset="5.952380e-03" style="stop-color:#0B0A16"/> ',
        '<stop  offset="1" style="stop-color:#1D6EAF"/> ',
        '</linearGradient> ',
        '<path style="opacity:0.15;fill:url(#SKY1_LG5);" d="M566.93,385.24',
        'c0,0-160.53-43.07-102.47-129.69s46.05-76.21,8.58-123.71C431.2,78.83,428.98,39.75,509.37,0h34.5c0,0-69.07,22.48-69.83,69.99',
        'c-1,61.85,83.8,52.87,63.97,141.27c-13.41,59.76-58.74,89.82,28.93,89.82"/> '
      )
    );
  }

  function getPath2() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<linearGradient id="SKY1_LG6" gradientUnits="userSpaceOnUse" x1="523.2549" y1="1314.5845" x2="841.3302" y2="1314.5845" gradientTransform="matrix(-1 0 0 1 841.3302 -1227.0485)"> ',
        '<stop  offset="5.952380e-03" style="stop-color:#0B0A16"/> ',
        '<stop  offset="1" style="stop-color:#1D6EAF"/> ',
        '</linearGradient> ',
        '<path style="opacity:0.2;fill:url(#SKY1_LG6);" d="M0,0v58.73',
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
        '<linearGradient id="SKY1_LG7" gradientUnits="userSpaceOnUse" x1="200.4768" y1="-123.5029" x2="340.0362" y2="272.5439"> ',
        '<stop  offset="0" style="stop-color:#FFFFFF"/> ',
        '<stop  offset="0.994" style="stop-color:#0B0A16"/> ',
        '</linearGradient> ',
        '<path style="opacity:0.5;fill:url(#SKY1_LG7);" d="M566.93,136.15',
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
        '<linearGradient id="SKY1_LG8" gradientUnits="userSpaceOnUse" x1="7.7404" y1="386.3394" x2="397.5282" y2="386.3394" gradientTransform="matrix(-0.6921 0.7218 0.7218 0.6921 210.9596 38.0781)"> ',
        '<stop  offset="5.952380e-03" style="stop-color:#0B0A16"/> ',
        '<stop  offset="1" style="stop-color:#1D6EAF"/> ',
        '</linearGradient> ',
        '<path style="opacity:0.15;fill:url(#SKY1_LG8);" d="M567.48,397.86',
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

library SkyDarkPath3_4Descriptor {

  function getPath3() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<linearGradient id="SKY1_LG9" gradientUnits="userSpaceOnUse" x1="50.3526" y1="521.6964" x2="50.3526" y2="0.0606">',
        '<stop  offset="0" style="stop-color:#FFFFFF"/>',
        '<stop  offset="0.994" style="stop-color:#0B0A16"/>',
        '</linearGradient>',
        '<path style="opacity:0.5;fill:url(#SKY1_LG9);" d="M94.48,507.98',
        'c17.17-25.09-5.37-64.05-17.19-49.01C65.47,474,36.48,486.89,22.52,477.23C14.96,472,6.77,465.81,0,457.32v28.29',
        'C34.58,525.49,78.48,531.34,94.48,507.98z"/>',
        '<linearGradient id="SKY1_LG10" gradientUnits="userSpaceOnUse" x1="228.4631" y1="521.733" x2="228.4631" y2="5.727501e-05">',
        '<stop  offset="0" style="stop-color:#FFFFFF"/>',
        '<stop  offset="0.994" style="stop-color:#0B0A16"/>',
        '</linearGradient>',
        '<path style="opacity:0.5;fill:url(#SKY1_LG10);" d="M187.9,0',
        'c0,0,4,4.09,9.34,11.4c0.95,1.3,7.33,11.01,8.77,13.53c15.82,27.57,31.51,75.43-2,130.12c-22.53,36.78-55.5,62.73-97.47,82.08',
        'c-0.16,0.23-0.41,0.4-0.72,0.4c-0.04,0-0.07-0.02-0.1-0.02C75.07,251.54,39.64,262.07,0,270.74v66.83',
        'c2.94-4.9,12.91-16.73,23.79-23.9c15.93-10.48,43.58-26.37,69.61-30.22c27.91-4.12,42.58-3.83,58.95-4.44',
        'c7.23-0.27,10.34-8.66-8.93-9.23c-5-0.16-33.31-1.59-35.17-6.93c-2.38-6.9,23.11-13.86,27.23-15.28',
        'c23.06-7.95,51.16-45.22,52.89-46.95c84.13-83.75,125.37-45.17,152.44-103.93C376.98,18.22,456.93,0,456.93,0H187.9z"/>',
        '<linearGradient id="SKY1_LG11" gradientUnits="userSpaceOnUse" x1="330.6834" y1="123.5238" x2="330.6834" y2="76.5895">',
        '<stop  offset="0" style="stop-color:#FFFFFF"/>',
        '<stop  offset="0.994" style="stop-color:#0B0A16"/>',
        '</linearGradient>',
        '<path style="opacity:0.5;fill:url(#SKY1_LG11);" d="M324.34,85.75',
        'c-0.29,6.95,0.19,20.71,6.55,21.2c3.1,0.24,4.97-3.34,5.61-6.39c0.89-4.24,1.05-8.63,0.45-12.92c-0.52-3.83-1.84-7.86-5.03-10.02',
        'c-1.15-0.78-2.59-1.28-3.92-0.89c-2.38,0.68-3.2,3.58-3.46,6.04c-0.05,0.45-0.09,1.04-0.14,1.75c-0.31,0.22-0.43,0.63-0.26,0.98',
        'C324.19,85.59,324.26,85.68,324.34,85.75z"/>',
        '<linearGradient id="SKY1_LG12" gradientUnits="userSpaceOnUse" x1="14.6983" y1="656.2689" x2="977.3593" y2="656.2689">',
        '<stop  offset="5.952380e-03" style="stop-color:#0B0A16"/>',
        '<stop  offset="1" style="stop-color:#1D6EAF"/>',
        '</linearGradient>',
        '<path style="opacity:0.2;fill:url(#SKY1_LG12);" d="M489.82,377.1',
        'c1.69,3.94,3.24,7.95,4.68,12c1.27,0.46,2.56,1.18,3.76,2.1c6.74,5.12,9.55,15.29,7.95,23.32c-0.57,2.89-1.45,4.66-2.48,5.6',
        'c3.09,12.09,5.62,23.37,8.18,32.48c3.03,10.8,4.39,20.48,4.67,29.02c2.24,17.13-1.01,33.08-10.89,45.3l0,0l0,0',
        'c-2.43,3-4.87,6.37-8.49,8.3c-122.73,65.4-93.85,400.04-108.26,400.22h132.42c0,0-46.03-303.78,45.57-402.4v-21.3',
        'c-0.98,3.8-2.33,7.55-4.99,10.41c-4.82,5.17-13.18,6.01-19.64,3.13c-6.46-2.89-11.14-8.87-13.93-15.36',
        'c-2.81-6.5-3.94-13.57-5.06-20.56c-3.24-20.33-6.31-40.7-9.73-61c-1.97-11.63-5.88-34.12,14.21-30',
        'c16.25,3.34,30.64,14.82,37.49,29.94c0.61,1.34,1.15,2.71,1.65,4.1v-34.62C556.21,383.75,515.95,383.08,489.82,377.1z"/>',
        '<linearGradient id="SKY1_LG13" gradientUnits="userSpaceOnUse" x1="51.4405" y1="312.1204" x2="950.0517" y2="312.1204">',
        '<stop  offset="5.952380e-03" style="stop-color:#0B0A16"/>',
        '<stop  offset="1" style="stop-color:#1D6EAF"/>',
        '</linearGradient>',
        '<path style="opacity:0.2;fill:url(#SKY1_LG13);" d="M505.83,280.55',
        'c20.74,1.37,41.31,5.28,61.1,11.63v-10.53c-4.2-1.32-8.55-2.47-13.03-3.47c-0.07,0.05-0.14,0.08-0.23,0.09',
        'c-0.18,0.01-0.34-0.09-0.43-0.23c-131.93-10.35-157.55,7.13-154.11,6.39c13.66-2.95,28.67-5.88,41.14-5.22',
        'c9.64,0.51,16.08,6,24.36,10.98c8.7,5.23,15.8,16.24,11.12,25.25c-3.09,5.98-10.07,8.63-16.49,10.67',
        'c-2.87,0.91-5.75,1.79-8.64,2.65c9.34,5.07,17.08,12.26,23.56,20.74c11.57-7.79,31.98-12.48,32.47-19.01',
        'c0.68-9.16,28.86-1.2,60.28-4.74v-11.52c-15.58,2.8-31.41,4.13-47.23,3.87c-8.46-0.14-17.34-0.85-24.41-5.48',
        'c-7.47-4.89-14.55-16.47-14.71-25.6C481.01,281.65,497.24,279.99,505.83,280.55z"/>',
        '<linearGradient id="SKY1_LG14" gradientUnits="userSpaceOnUse" x1="14.6984" y1="368.8175" x2="903.7394" y2="368.8175">',
        '<stop  offset="5.952380e-03" style="stop-color:#0B0A16"/>',
        '<stop  offset="1" style="stop-color:#1D6EAF"/>',
        '</linearGradient>',
        '<path style="opacity:0.2;fill:url(#SKY1_LG14);" d="M162.5,291.04',
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
          '<linearGradient id="SKY1_LG15" gradientUnits="userSpaceOnUse" x1="659.2993" y1="799.0061" x2="659.2993" y2="672.641" ',
          'gradientTransform="matrix(-0.9985 -0.0554 0.0554 -0.9985 812.2495 1155.7041)"> ',
          '<stop  offset="5.952380e-03" style="stop-color:#0B0A16"/> ',
          '<stop  offset="1" style="stop-color:#1D6EAF"/> ',
          '</linearGradient> ',
          '<path style="opacity:0.2;fill-rule:evenodd;clip-rule:evenodd;fill:url(#SKY1_LG15);" d="',
          'M238.93,409.27c0,0-22.06-16.24-28.16-22.08c-6.09-5.84-26.98-9.45-31.01-11.2c-4.03-1.75-13.14-16.01-13.14-16.01',
          's-5.12-10.46-6.08-17.8c-0.96-7.35-18.76-16.59-18.76-16.59l-16.91-8.28c0,0,25.16,31.66,27.75,39.14s-1.45,13.98,6.11,18.38',
          'c7.56,4.39,26.12,11.84,27.68,19.27c1.56,7.42,30.92,34.73,40.42,39.84c9.5,5.11,37.81,17.69,37.81,17.69',
          'S247.55,419.84,238.93,409.27z"/> ',
          '<linearGradient id="SKY1_LG16" gradientUnits="userSpaceOnUse" x1="625.9933" y1="712.609" x2="625.9933" y2="498.6406" ',
          'gradientTransform="matrix(-0.9985 -0.0554 0.0554 -0.9985 812.2495 1155.7041)"> ',
          '<stop  offset="5.952380e-03" style="stop-color:#0B0A16"/> ',
          '<stop  offset="1" style="stop-color:#1D6EAF"/> ',
          '</linearGradient> ',
          '<path style="opacity:0.15;fill-rule:evenodd;clip-rule:evenodd;fill:url(#SKY1_LG16);" d="',
          'M237.47,564.94c0,0-28.9-28.93-46.39-40.53c-17.49-11.6-27.65-7.61-27.65-7.61s-15.7-5.54-25.05-13.59',
          'c-9.35-8.05-7.08-21.59-12.71-29.49c-5.63-7.9-30.9-3.99-30.9-3.99l-35.12-43.41l-23.29-27.39c0,0,24.76,36.29,28.83,44.11',
          'c4.07,7.82,32.65,53.43,38.29,61.33c5.63,7.9,14.04,6.85,19.51,17.78c5.47,10.93,11.6,23.42,20.94,33.04',
          'c9.33,9.63,28.99,24.38,39.64,31.04c10.65,6.66,27.71,13.68,27.71,13.68l29.89,8.49l164.07,25.29c0,0-63.9-49.33-93.47-62.36',
          'C300.57,566.41,237.47,564.94,237.47,564.94z"/> ',
          '<linearGradient id="SKY1_LG17" gradientUnits="userSpaceOnUse" x1="702.6287" y1="588.2362" x2="702.6287" y2="506.131" ',
          'gradientTransform="matrix(-0.9985 -0.0554 0.0554 -0.9985 812.2495 1155.7041)">',
          '<stop  offset="5.952380e-03" style="stop-color:#0B0A16"/> ',
          '<stop  offset="1" style="stop-color:#1D6EAF"/> ',
          '</linearGradient> ',
          '<path style="opacity:0.2;fill-rule:evenodd;clip-rule:evenodd;fill:url(#SKY1_LG17);" d="',
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
          '<linearGradient id="SKY1_LG18" gradientUnits="userSpaceOnUse" x1="204.6214" y1="236.9106" x2="204.6214" y2="0"> ',
          '<stop  offset="0" style="stop-color:#FFFFFF"/> ',
          '<stop  offset="0.994" style="stop-color:#0B0A16"/> ',
          '</linearGradient> ',
          '<path style="opacity:0.5;fill-rule:evenodd;clip-rule:evenodd;fill:url(#SKY1_LG18);" d="',
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


library SkyBrownCircleDescriptor {

  function getCircle(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public pure returns (string memory svg, uint offsetRandom) {

    (string memory svgCircleWhite, uint newOffsetRandom1) = getCircleWhite(tokenId_, blockhashInit_, offsetRandom_);

    offsetRandom = newOffsetRandom1;

    svg = string(
      abi.encodePacked(
        svgCircleWhite
      )
    );

  }

  function getCircleWhite(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) private pure returns (string memory svg, uint offsetRandom) {
    uint index = 0;

    bytes32 randomHashCircleWhite = PlanetRandom.getRandomHash(blockhashInit_, tokenId_ + offsetRandom_);
    offsetRandom_ = offsetRandom_ + 1124;

    uint nCircle = PlanetRandom.calcRandomBytes1(40, 80, randomHashCircleWhite, index);
    index ++;

    string memory svgTemp = "";

    for(uint i = 0; i < nCircle ; i++) {
      if (index == 31 || index +1 == 31 || index +2 == 31 ) {
        randomHashCircleWhite = PlanetRandom.getRandomHash(blockhashInit_, tokenId_ + offsetRandom_);
        offsetRandom_ = offsetRandom_ + 1124;
        index = 0;
      }
      uint xPoint = PlanetRandom.calcRandomBytes1(0, 566, randomHashCircleWhite, index);
      index ++;
      uint yPoint = PlanetRandom.calcRandomBytes1(0, 935, randomHashCircleWhite, index);
      index ++;
      uint size = PlanetRandom.calcRandomBytes1(0, 25, randomHashCircleWhite, index);
      index ++;

      svgTemp = string(
        abi.encodePacked(
          svgTemp,
          '<circle class="circle_white" ',
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
import "../../../utils/PlanetRandom.sol";
import "./SkyBrownPath1_2Descriptor.sol";
import "./SkyBrownPath3_4Descriptor.sol";


library SkyBrownPathDescriptor {

  function getPathShadow(uint tokenId_, bytes32 blockhashInit_, uint offsetRandom_) public pure returns (string memory svg, uint offsetRandom) {
    uint index = 0;

    bytes32 randomHashPath = PlanetRandom.getRandomHash(blockhashInit_, tokenId_ + offsetRandom_);
    offsetRandom_ = offsetRandom_ + 1124;

    // select random path layer
    uint randomPathLayer = PlanetRandom.calcRandomBytes1(0, 4, randomHashPath, index);

    if (randomPathLayer == 0) {
      svg = SkyBrownPath1_2Descriptor.getPath1();
    } else if (randomPathLayer == 1) {
      svg = SkyBrownPath1_2Descriptor.getPath2();
    } else if (randomPathLayer == 2) {
      svg = SkyBrownPath3_4Descriptor.getPath3();
    } else {
      svg = SkyBrownPath3_4Descriptor.getPath4();
    }

    offsetRandom = offsetRandom_;
  }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library SkyBrownPath1_2Descriptor {

  function getPath1() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<linearGradient id="SKY3_LG1" gradientUnits="userSpaceOnUse" x1="0" y1="252.8589" x2="252.0218" y2="252.8589"> ',
        '<stop  offset="0" style="stop-color:#573C30"/> ',
        '<stop  offset="1" style="stop-color:#301E14"/> ',
        '</linearGradient> ',
        '<path style="opacity:0.3;fill:url(#SKY3_LG1);" d="M191.95,0',
        'c0,0-84.67,62.34-84.67,207.48c0,140.83,9.51,218.55-107.28,218.55v79.61c0,0,139.11,8.96,137.97-167.95',
        'C136.83,160.78,155.71,49.39,252.02,0H191.95z"/> ',
        '<linearGradient id="SKY3_LG2" gradientUnits="userSpaceOnUse" x1="77.0295" y1="574.7913" x2="566.9291" y2="574.7913"> ',
        '<stop  offset="0" style="stop-color:#573C30"/> ',
        '<stop  offset="1" style="stop-color:#301E14"/> ',
        '</linearGradient> ',
        '<path style="opacity:0.3;fill:url(#SKY3_LG2);" d="M566.93,214.15',
        'c0,0-7.31,294.38-156.29,292.58c-89.05-1.07-157.15,7.69-209.67,31.68C8.56,626.33,97.61,935.43,97.61,935.43H199.8',
        'c0,0-29.6-65.74-44.51-140.44c-49.04-245.65,173.59-239.36,262.97-251.2c101.86-13.49,148.67-100.02,148.67-143.51V214.15z"/> '
    )
    );
  }

  function getPath2() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
    '<linearGradient id="SKY3_LG3" gradientUnits="userSpaceOnUse" x1="375.7122" y1="733.1992" x2="375.7122" y2="111.1077" ',
    'gradientTransform="matrix(0.9537 -0.3009 0.3009 0.9537 -209.1915 141.8566)"> ',
    '<stop  offset="0" style="stop-color:#573C30"/> ',
    '<stop  offset="1" style="stop-color:#301E14"/> ',
    '</linearGradient> ',
    '<path style="fill:url(#SKY3_LG3);opacity:0.3;" d="M566.93,526.69v139.11',
    'c0,0-109.52-38.06-139.9-160.91c-3.08-12.46-15.46-20.33-28.02-17.67c-65.79,13.93-148.94,86.37-210.67,78.95',
    'C16.09,545.46,0,394.45,0,329.37V192.36C6.08,689.93,410.64,315.49,464.8,485C494.16,576.87,566.93,526.69,566.93,526.69z"/> ',
    '<linearGradient id="SKY3_LG4" gradientUnits="userSpaceOnUse" x1="22.823" y1="859.8785" x2="22.823" y2="456.9759" ',
    'gradientTransform="matrix(-3.464102e-07 1 1 3.464102e-07 -292.9521 75.5515)"> ',
    '<stop  offset="0" style="stop-color:#573C30"/> ',
    '<stop  offset="1" style="stop-color:#2D1C12"/> ',
    '</linearGradient> ',
    '<path style="fill:url(#SKY3_LG4);opacity:0.3;" d="M164.03,0',
    'c3.69,6.73,11.69,26.73,51.42,26.73c103.86,0,78.92,170.01,351.48,170.01l0-109.53c-38.82,0-163.8,1.75-211.13-13.53',
    'c-32.67-10.55-64.41-29.22-91.16-62.18C253.76-1.9,204.25,20.34,193.74,0L164.03,0z"/> ',
    '<linearGradient id="SKY3_LG5" gradientUnits="userSpaceOnUse" x1="58.6611" y1="859.8785" x2="58.6611" y2="440.3556" ',
    'gradientTransform="matrix(-3.464102e-07 1 1 3.464102e-07 -292.9521 75.5515)"> ',
    '<stop  offset="0" style="stop-color:#6E564B"/> ',
    '<stop  offset="1" style="stop-color:#2D1C12"/> ',
    '</linearGradient> ',
    '<path style="fill:url(#SKY3_LG5);opacity:0.3;" d="M164.03,0',
    'c3.69,6.73,11.69,26.73,51.42,26.73c99.37,0,99.38,74.62,159.35,117.36c45.53,32.44,167.72,31.87,192.13,31.87v92.46',
    'c-239.28,0-237.84-226.32-348.8-226.32c-61.84,0-70.72-26.78-70.72-42.1L164.03,0z"/> '
    )
    );
  }

}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library SkyBrownPath3_4Descriptor {

  function getPath3() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<linearGradient id="SKY3_LG6" gradientUnits="userSpaceOnUse" x1="313.0611" y1="875.2369" x2="313.0611" y2="-9.505934e-05" ',
        'gradientTransform="matrix(-1 0 0 -1 566.9291 935.433)"> ',
        '<stop  offset="0" style="stop-color:#573C30"/> ',
        '<stop  offset="1" style="stop-color:#301E14"/> ',
        '</linearGradient> ',
        '<path style="fill:url(#SKY3_LG6);opacity:0.3;" d="M0,62.66',
        'c77.39-12.84,102.17,25.36,87.79,94.83c-50.67,244.78,59.2,288.86,103.92,305.43c64.26,23.82,129.87,35.73,193.64,64.61',
        'C543.39,599.1,503.66,888,502.38,935.43h-66.53C579.78,459.09,0,537.81,0,351.35L0,62.66z"/> ',
        '<linearGradient id="SKY3_LG7" gradientUnits="userSpaceOnUse" x1="98.3717" y1="935.433" x2="98.3717" y2="532.5305" ',
        'gradientTransform="matrix(-1 0 0 -1 566.9291 935.433)"> ',
        '<stop  offset="0" style="stop-color:#573C30"/> ',
        '<stop  offset="1" style="stop-color:#2D1C12"/> ',
        '</linearGradient> ',
        '<path style="fill:url(#SKY3_LG7);opacity:0.3;" d="M566.93,402.9',
        'c-6.73-3.69-26.73-11.69-26.73-51.42c0-103.86-170.01-78.92-170.01-351.48l109.53,0c0,38.82-1.75,163.8,13.53,211.13',
        'c10.55,32.67,29.22,64.41,62.18,91.16c13.4,10.88-8.83,60.39,11.51,70.9V402.9z"/> ',
        '<linearGradient id="SKY3_LG8" gradientUnits="userSpaceOnUse" x1="134.2097" y1="935.433" x2="134.2097" y2="515.9101" ',
        'gradientTransform="matrix(-1 0 0 -1 566.9291 935.433)"> ',
        '<stop  offset="0" style="stop-color:#6E564B"/> ',
        '<stop  offset="1" style="stop-color:#2D1C12"/> ',
        '</linearGradient> ',
        '<path style="fill:url(#SKY3_LG8);opacity:0.3;" d="M566.93,402.9',
        'c-6.73-3.69-26.73-11.69-26.73-51.42c0-99.37-74.62-99.38-117.36-159.35C390.4,146.6,390.97,24.41,390.97,0l-92.46,0',
        'c0,239.28,226.32,237.84,226.32,348.8c0,61.84,26.78,70.72,42.1,70.72V402.9z"/> '
    )
    );
  }

  function getPath4() public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<linearGradient id="SKY3_LG9" gradientUnits="userSpaceOnUse" x1="356.8032" y1="455.9965" x2="356.8032" y2="1.546141e-11"> ',
        '<stop  offset="0" style="stop-color:#573C30"/> ',
        '<stop  offset="1" style="stop-color:#301E14"/> ',
        '</linearGradient> ',
        '<path style="fill:url(#SKY3_LG9);opacity:0.3;" d="M566.93,456',
        'c-67.96-35.84-85.46-140.01-73.43-176.31c42.38-127.89-49.51-150.92-86.92-159.58c-53.75-12.45-109.06-18.08-161.96-33.75',
        'c-23.79-7.05-47.46-16.38-66.38-32.43S145.67,24.78,146.74,0h55.65c25.23,98.92,226.23,52.09,274.64,62.01',
        'c36.84,7.55,62.85,22.95,89.91,53.31V456z"/> ',
        '<linearGradient id="SKY3_LG10" gradientUnits="userSpaceOnUse" x1="184.1407" y1="935.433" x2="184.1407" y2="181.2457"> ',
        '<stop  offset="0" style="stop-color:#573C30"/> ',
        '<stop  offset="1" style="stop-color:#2D1C12"/> ',
        '</linearGradient> ',
        '<path style="fill:url(#SKY3_LG10);opacity:0.3;" d="M0,181.25',
        'c12.59,6.9,50.04,21.88,50.04,96.25c0,194.42,318.24,147.74,318.24,657.94H163.26c0-72.67,3.28-306.62-25.33-395.21',
        'c-19.75-61.15-54.69-120.56-116.39-170.64C-3.55,349.22,38.07,256.55,0,236.87V181.25z"/> ',
        '<linearGradient id="SKY3_LG11" gradientUnits="userSpaceOnUse" x1="251.2253" y1="935.433" x2="251.2253" y2="150.1344"> ',
        '<stop  offset="0" style="stop-color:#6E564B"/> ',
        '<stop  offset="1" style="stop-color:#2D1C12"/> ',
        '</linearGradient> ',
        '<path style="fill:url(#SKY3_LG11);opacity:0.3;" d="M0,181.25',
        'c12.59,6.9,50.04,21.88,50.04,96.25c0,186.01,139.69,186.02,219.68,298.29c60.73,85.23,59.65,313.96,59.65,359.65h173.08',
        'c0-447.9-423.64-445.21-423.64-652.92c0-115.76-50.13-132.38-78.81-132.38V181.25z"/> '
    )
    );
  }

}