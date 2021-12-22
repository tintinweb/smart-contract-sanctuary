// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import 'base64-sol/base64.sol';
import './legacy_colors/TheColors.sol';
import './legacy_colors/INFTOwner.sol';

/**
 * @title Sync x Colors contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract SyncXColors is ERC721Enumerable, Ownable {
  using Strings for uint256;
  using Strings for uint16;
  using Strings for uint8;

  uint256 public constant TotalReservedAmount = 17; // Amount reserved for promotions (giveaways, team)
  uint256 public constant MAX_SUPPLY = 4317 - TotalReservedAmount;

  // Declare Public
  address public constant THE_COLORS = 
    address(0x9fdb31F8CE3cB8400C7cCb2299492F2A498330a4);

  uint256 public constant mintPrice = 0.05 ether; // Price per mint
  uint256 public constant resyncPrice = 0.005 ether; // Price per color resync
  uint256 public constant maxMintAmount = 10; // Max amount of mints per transaction
  uint256 public MintedReserves = 0; // Total Promotional Reserves Minted

  // Declare Private
  address private constant TREASURY =
    address(0x48aE900E9Df45441B2001dB4dA92CE0E7C08c6d2);
  address private constant TEAM =
    address(0x263853ef2C3Dd98a986799aB72E3b78334EB88cb);

  mapping(uint256 => uint16[]) private _colorTokenIds;
  mapping(uint256 => uint256) private _seed; // Trait seed is generated at time of mint and stored on-chain
  mapping(uint256 => uint8) private _resync_count; //Store count of color resyncs applied
  
  // Struct for NFT traits
  struct SyncTraitsStruct {
    uint8[] shape_color;
    uint8[] shape_type;
    uint16[] shape_x;
    uint16[] shape_y;
    uint16[] shape_sizey;
    uint16[] shape_sizex;
    uint16[] shape_r;
    uint16 rarity_roll;
    bytes[] baseColors;
    bytes[] bgColors;
    bytes[] infColors;
    bytes logoColors;
    bytes driftColors;
    bytes theme;
    bytes7 sigil;
  }

  // Constructor
  constructor() ERC721('Sync x Colors', 'SyncXColors') {}

  /**
   * Returns NFT tokenURI JSON
   */
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721)
    returns (string memory)
  {
    require(_exists(tokenId), 'ERC721: operator query for nonexistent token');

    SyncTraitsStruct memory syncTraits = generateTraits(tokenId);

    string memory svgData = generateSVGImage(tokenId, syncTraits);
    string memory image = Base64.encode(bytes(svgData));

    return
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{',
                '"image":"',
                'data:image/svg+xml;base64,',
                image,
                '",',
                generateNameDescription(),
                ',',
                generateAttributes(tokenId, syncTraits),
                '}'
              )
            )
          )
        )
      );
  }

  /**
   * Withdraw accrued funds from contract. 50% treasury, 10% to each team member
   */
  function withdraw() internal {
    bool sent;
    uint256 balance = address(this).balance;
    (sent, ) = payable(TEAM).call{value: (balance * 50) / 100}('');
    require(sent);
    (sent, ) = payable(TREASURY).call{value: (balance * 50) / 100}('');
    require(sent);
  }

  /**
   * Withdraw by owner
   */
  function withdrawOwner() external onlyOwner {
    withdraw();
  }

  /**
   * Withdraw by team
   */
  function withdrawTeam() external {
    require(msg.sender == TEAM, 'Only team can withdraw');
    withdraw();
  }

  /**
   * Mint 1 or multiple NFTs
   */
  function mint(uint256 _mintAmount, uint16[] calldata colorTokenIds)
    external
    payable
  {
    // Requires
    uint256 _mintIndex = totalSupply();
    require(
      _mintAmount > 0 && _mintAmount <= maxMintAmount,
      'Max mint 10 per tx'
    );
    require(colorTokenIds.length <= 3, '# COLORS tokenIds must be <=3');
    if (msg.sender == TEAM) {
      require(
        MintedReserves + _mintAmount <= TotalReservedAmount,
        'Not enough reserve tokens'
      );
      // Update reserve count
      MintedReserves += _mintAmount;
    } else {
      require(_mintIndex + _mintAmount <= MAX_SUPPLY, 'Exceeds supply');
      require(msg.value == (mintPrice * _mintAmount), 'Insufficient funds');
      // Validate colorTokenIds
      require(isHolder(colorTokenIds), 'COLORS not owned by sender.');
    }

    for (uint256 i = _mintIndex; i < (_mintIndex + _mintAmount); i++) {
      // Update states
      _colorTokenIds[i] = colorTokenIds;
      _seed[i] = _rng(i);

      // Mint
      _safeMint(msg.sender, i);
    }
  }

  /**
   * Store mapping between tokenId and applied tokenIdColors
   */
  function updateColors(uint256 tokenId, uint16[] calldata colorTokenIds)
    external
    payable
  {
    require(msg.sender == ownerOf(tokenId), 'Only NFT holder can updateColors');
    require(colorTokenIds.length <= 3, '# COLORS tokenIds must be <=3');
    require(msg.value >= resyncPrice, 'Insufficient funds');
    // Validate colorTokenIds
    require(isHolder(colorTokenIds), 'COLORS not owned by sender.');
    // Update state
    _colorTokenIds[tokenId] = colorTokenIds;
    _resync_count[tokenId] += 1;
  }

  /**
   * Verify that sender holds supplied colorTokenIds
   */
  function isHolder(uint16[] calldata colorTokenIds)
    private
    view
    returns (bool)
  {
    address colors_address = THE_COLORS;
    for (uint256 i = 0; i < colorTokenIds.length; i++) {
      if (
        msg.sender !=
        INFTOwner(colors_address).ownerOf(uint256(colorTokenIds[i]))
      ) {
        return false;
      }
    }
    return true;
  }

  /**
   * Return NFT description
   */
  function generateNameDescription()
    internal
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '"external_url":"https://syncxcolors.xyz",',
          unicode'"description":"Sync X Colors is a unique, on-chain generative collection of Syncs on Ethereum. Each Sync can be re-colored with new Colors at any time."'
        )
      );
  }

  /**
   * Generate attributes json
   */
  function generateAttributes(
    uint256 tokenId,
    SyncTraitsStruct memory syncTraits
  ) internal view returns (string memory) {
    uint16[] memory colorTokenIds = _colorTokenIds[tokenId];
    uint256 length = colorTokenIds.length;
    bytes[] memory colorArray = new bytes[](3);
    for (uint256 i = 0; i < length; i++) {
      colorArray[i] = bytes(
        TheColors(THE_COLORS).getHexColor(uint256(colorTokenIds[i]))
      );
    }
    // fixing assembly overflow error, too much params
    string memory attributes = string(
        abi.encodePacked(
          '"attributes":[',
          '{"trait_type":"Rarity","value":"',
          syncTraits.theme,
          '"},',
          '{"trait_type":"Sigil","value":"',
          syncTraits.sigil,
          '"},'
        )
    );
    attributes = string(
        abi.encodePacked(
          attributes,
          '{"trait_type":"Color 1","value":"',
          colorArray[0],
          '"},',
          '{"trait_type":"Color 2","value":"',
          colorArray[1],
          '"},',
          '{"trait_type":"Color 3","value":"',
          colorArray[2],
          '"},',
          '{"trait_type":"Resyncs","value":',
          _resync_count[tokenId].toString(),
          '}]'
      )
    );
    return attributes;
  }

  /**
   * Returns hex strings representing colorTokenIDs as an array
   */
  function getColorsHexStrings(uint256 tokenId)
    internal
    view
    returns (bytes[] memory)
  {
    uint16[] memory colorTokenIds = _colorTokenIds[tokenId];
    uint256 length = _colorTokenIds[tokenId].length;
    bytes[] memory hexColors = new bytes[](3);
    hexColors[0] = '#222222'; // Defaults (grayscale)
    hexColors[1] = '#777777';
    hexColors[2] = '#AAAAAA';
    for (uint256 i = 0; i < length; i++) {
      hexColors[i] = bytes(
        TheColors(THE_COLORS).getHexColor(uint256(colorTokenIds[i]))
      );
    }
    return hexColors;
  }

  /**
   * Generates the SVG
   */
  function generateSVGImage(uint256 tokenId, SyncTraitsStruct memory syncTraits)
    private
    pure
    returns (string memory)
  {
    bytes memory svgBG = generateSVGBG(syncTraits);
    bytes memory svgInfinity = generateSVGInfinity(syncTraits.infColors);
    bytes memory svgLogo = generateSVGLogo(
      syncTraits.baseColors,
      syncTraits.logoColors,
      syncTraits.rarity_roll,
      tokenId.toString()
    );
    bytes memory svgDrift = generateSVGDrift(
      syncTraits.baseColors,
      syncTraits.driftColors,
      syncTraits.rarity_roll,
      syncTraits.sigil,
      tokenId.toString()
    );
    return
      string(
        abi.encodePacked(
          '<svg xmlns="http://www.w3.org/2000/svg" width="500" height="500" viewbox="0 0 500 500" style="background-color:#111111">',
          svgBG,
          svgInfinity,
          svgLogo,
          svgDrift,
          '</svg>'
        )
      );
  }

  /**
   * Generates the SVG Background
   */
  function generateSVGBG(SyncTraitsStruct memory syncTraits)
    private
    pure
    returns (bytes memory)
  {
    bytes memory newShape;
    bytes memory svgBG = '<g fill-opacity="0.3">';

    for (uint256 i = 0; i < 15; i++) {
      if (syncTraits.shape_type[i] == 0) {
        newShape = abi.encodePacked(
          '<circle fill="',
          syncTraits.bgColors[syncTraits.shape_color[i]],
          '" cx="',
          syncTraits.shape_x[i].toString(),
          '" cy="',
          syncTraits.shape_y[i].toString(),
          '" r="',
          syncTraits.shape_sizex[i].toString(),
          '"'
        );
      } else if (syncTraits.shape_type[i] == 1) {
        newShape = abi.encodePacked(
          '<rect fill="',
          syncTraits.bgColors[syncTraits.shape_color[i]],
          '" x="',
          (syncTraits.shape_x[i] / 2).toString(),
          '" y="',
          (syncTraits.shape_y[i] / 2).toString(),
          '" width="',
          (syncTraits.shape_sizex[i] * 2).toString(),
          '" height="',
          (syncTraits.shape_sizey[i] * 2).toString(),
          '" transform="rotate(',
          syncTraits.shape_r[i].toString(),
          ')"'
        );
      }
      if (
        (syncTraits.rarity_roll % 19 == 0 &&
          syncTraits.rarity_roll % 95 != 0) ||
        (syncTraits.rarity_roll % 13 == 0)
      ) {
        // Silver or Mosaic
        // Add strokes to background elements
        newShape = abi.encodePacked(
          newShape,
          ' stroke="',
          syncTraits.infColors[syncTraits.shape_color[i]],
          '"/>'
        );
      } else {
        newShape = abi.encodePacked(newShape, '/>');
      }

      svgBG = abi.encodePacked(svgBG, newShape);
    }
    return abi.encodePacked(svgBG, '</g>');
  }

  /**
   * Generates the infinity
   */
  function generateSVGInfinity(bytes[] memory infColors)
    private
    pure
    returns (bytes memory)
  {
    bytes memory infinity1 = abi.encodePacked(
      '<g><path stroke-dasharray="0" stroke-dashoffset="0" stroke-width="16" ',
      'd="M195.5 248c0 30 37.5 30 52.5 0s 52.5-30 52.5 0s-37.5 30-52.5 0s-52.5-30-52.5 0" fill="none">',
      '<animate begin="s.begin" attributeType="XML" attributeName="stroke" values="',
      infColors[0],
      ';',
      infColors[1],
      ';',
      infColors[0],
      '" dur="4s" fill="freeze"/>'
    );
    bytes memory infinity2 = abi.encodePacked(
      '<animate begin="s.begin" attributeType="XML" attributeName="stroke-dasharray" values="0;50;0" dur="6s" fill="freeze"/>',
      '<animate begin="a.begin" attributeType="XML" attributeName="stroke-width" values="16;20;16" dur="1s" fill="freeze"/>',
      '</path><path stroke-dasharray="300" stroke-dashoffset="300" stroke-width="16" ',
      'd="M195.5 248c0 30 37.5 30 52.5 0s 52.5-30 52.5 0s-37.5 30-52.5 0s-52.5-30-52.5 0" fill="none">'
    );
    bytes memory infinity3 = abi.encodePacked(
      '<animate begin="s.begin" attributeType="XML" attributeName="stroke" values="',
      infColors[2],
      ';',
      infColors[0],
      ';',
      infColors[2],
      '" dur="4s" fill="freeze"/>',
      '<animate id="a" begin="s.begin;a.end" attributeType="XML" attributeName="stroke-width" values="16;20;16" dur="1s" fill="freeze"/>',
      '<animate id="s" attributeType="XML" attributeName="stroke-dashoffset" begin="0s;s.end" to= "-1800" dur="6s"/></path></g>'
    );
    return abi.encodePacked(infinity1, infinity2, infinity3);
  }

  /**
   * Generates the logo
   */
  function generateSVGLogo(
    bytes[] memory baseColors,
    bytes memory logoColors,
    uint16 rarity_roll,
    string memory tokenId
  ) private pure returns (bytes memory) {
    
    bytes memory logo = abi.encodePacked(
      '<g id="',tokenId,'b">',
      '<path d="M194 179H131c-34 65 0 143 0 143h63C132 251 194 179 194 179Zm-26 128H144s-25-35 0-111h23S126 245 168 307Z" ',
      'stroke="black" fill-opacity="0.9" stroke-width="0.7">'
    );

    if (
      rarity_roll % 333 == 0 || rarity_roll % 241 == 0 || rarity_roll % 19 == 0
    ) {
      //Shimmer
      logo = abi.encodePacked(
        logo,
        '<set attributeName="stroke-dasharray" to="20"/>',
        '<set attributeName="stroke-width" to="2"/>',
        '<set attributeName="fill" to="',
        logoColors,
        '"/>',
        '<animate begin="s.begin" attributeType="XML" attributeName="stroke-dashoffset" from="0" to="280" dur="6s" fill="freeze"/>',
        '<animate begin="s.begin" attributeType="XML" attributeName="stroke" values="',
        baseColors[0],
        ';',
        baseColors[1],
        ';',
        baseColors[2],
        ';',
        baseColors[0],
        '" dur="6s" fill="freeze"/>'
      );
    } else {
      logo = abi.encodePacked(
        logo,
        '<animate begin="s.begin" attributeName="fill" dur="6s" '
        'values="black;',
        baseColors[0],
        ';black;',
        baseColors[1],
        ';black;',
        baseColors[2],
        ';black"/>'
      );
    }
    return logo;
  }

  /**
   * Generates the drift
   */
  function generateSVGDrift(
    bytes[] memory baseColors,
    bytes memory driftColors,
    uint16 rarity_roll,
    bytes7 sigil,
    string memory tokenId
  ) private pure returns (bytes memory) {
    if (rarity_roll % 11 != 0) {
      // Drift is colored as a single color unless Tokyo Drift trait
      baseColors[0] = driftColors;
      baseColors[1] = driftColors;
      baseColors[2] = driftColors;
    }
    bytes memory borders1 = abi.encodePacked(
      '</path><text x="2" y="40" font-size="3em" fill-opacity="0.3" fill="',
      'black">',
      sigil,
      '</text>',
      '<path d="M90 203c-21 41 0 91 0 91h11c0 0-16-42 0-91z" stroke-opacity="0.7" fill-opacity="0.7" fill="transparent">'
      '<animate id="w" attributeName="fill" values="transparent;',
      baseColors[0],
      ';transparent" begin="s.begin+.17s;s.begin+2.17s;s.begin+4.17s" dur="1s"/>',
      '<animate begin="w.begin" attributeName="stroke" values="transparent;black;transparent" dur="1s"/>',
      '</path>'
    );

    bytes memory borders2 = abi.encodePacked(
      '<path d="M60 212c-17 34 0 74 0 74h9c0-1-13-34 0-74z" stroke-opacity="0.5" fill-opacity="0.5" fill="transparent">',
      '<animate attributeName="fill" values="transparent;',
      baseColors[1],
      ';transparent" begin="w.begin+0.2s" dur="1s"/>',
      '<animate attributeName="stroke" values="transparent;black;transparent" begin="w.begin+0.2s" dur="1s"/>',
      '</path>'
    );

    bytes memory borders3 = abi.encodePacked(
      '<path d="M37 221c-13 26 0 57 0 57h7c0 0-10-26 0-57z" stroke-opacity="0.3" fill-opacity="0.3" fill="transparent">',
      '<animate attributeName="fill" values="transparent;',
      baseColors[2],
      ';transparent" begin="w.begin+0.4s" dur="1s"/>',
      '<animate attributeName="stroke" values="transparent;black;transparent" begin="w.begin+0.4s" dur="1s"/>',
      '</path></g><use href="#',tokenId,'b" x="-500" y="-500" transform="rotate(180)"/>'
    );

    return abi.encodePacked(borders1, borders2, borders3);
  }

  /**
   * Generates the NFT traits by stored seed (note: seed generated and stored at mint)
   */
  function generateTraits(uint256 tokenId)
    private
    view
    returns (SyncTraitsStruct memory)
  {
    // Initialize struct arrays
    SyncTraitsStruct memory syncTraits;
    syncTraits.shape_x = new uint16[](15);
    syncTraits.shape_y = new uint16[](15);
    syncTraits.shape_sizex = new uint16[](15);
    syncTraits.shape_sizey = new uint16[](15);
    syncTraits.shape_r = new uint16[](15);
    syncTraits.shape_type = new uint8[](15);
    syncTraits.shape_color = new uint8[](15);
    syncTraits.bgColors = new bytes[](3);
    syncTraits.infColors = new bytes[](3);

    // Retrieve seed from storage
    uint256 seed = _seed[tokenId];
    syncTraits.rarity_roll = uint16(
      1 + ((seed & 0x3FF) % 1000) // range 1 to 2047 % 1000 - ~ slightly bottom heavy but round numbers nicer
    );

    // Calculate traits
    syncTraits.baseColors = getColorsHexStrings(tokenId);

    if (syncTraits.rarity_roll % 333 == 0) {
      // 0.3% probability (3 in 1000)
      syncTraits.theme = 'Concave';
      syncTraits.sigil = '\xE2\x9D\xAA\x20\xE2\x9D\xAB'; //( )
      syncTraits.bgColors[0] = '#214F70'; //Light Blue
      syncTraits.bgColors[1] = '#2E2E3F'; //Dark Blue
      syncTraits.bgColors[2] = '#2E2E3F'; //Dark Blue
      syncTraits.infColors[0] = '#FAF7C0'; //Con-yellow
      syncTraits.infColors[1] = '#214F70'; //Light Blue
      syncTraits.infColors[2] = '#FAF7C0'; //Con-yellow
      syncTraits.logoColors = '#FAF7C0'; //Con-yellow
      syncTraits.driftColors = '#FAF7C0';
    } else if (syncTraits.rarity_roll % 241 == 0) {
      // 0.4% probability (4 in 1000)
      syncTraits.theme = 'Olympus';
      syncTraits.sigil = '\xF0\x9D\x9B\x80\x20\x20\x20'; // OMEGA
      syncTraits.bgColors[0] = '#80A6AF'; // Oly Blue
      syncTraits.bgColors[1] = '#3A424F'; // Dark Blue
      syncTraits.bgColors[2] = '#80A6AF'; // Oly Blue
      syncTraits.infColors[0] = '#FFC768'; // Oly yellow
      syncTraits.infColors[1] = '#3A424F'; // Dark Blue
      syncTraits.infColors[2] = '#FFC768'; // Oly yellow
      syncTraits.logoColors = '#FFC768'; // Oly-yellow
      syncTraits.driftColors = '#FFC768';
    } else if (syncTraits.rarity_roll % 19 == 0) {
      // ~4% probability (50-10 in 1000)
      syncTraits.theme = 'Silver';
      syncTraits.sigil = '\xE2\x98\x86\x20\x20\x20\x20'; // Empty Star
      syncTraits.bgColors[0] = '#c0c0c0'; // Silver
      syncTraits.bgColors[1] = '#e5e4e2'; // Platinum
      syncTraits.bgColors[2] = '#c0c0c0'; // Silver
      syncTraits.infColors[0] = 'white';
      syncTraits.infColors[1] = '#C0C0C0'; // silver
      syncTraits.infColors[2] = '#CD7F32'; // Gold
      syncTraits.logoColors = 'black';
      syncTraits.driftColors = 'black';
      // Silver has 1 in 4 chance of upgrading to gold
      // (contract memory usage happened to be more efficient this way)
      if (syncTraits.rarity_roll % 95 == 0) {
        // `~1% probability (10 in 1000)
        syncTraits.theme = 'Gold'; // Gold
        syncTraits.sigil = '\xE2\x98\x85\x20\x20\x20\x20'; // Full star
        syncTraits.bgColors[0] = '#CD7F32'; // Gold
        syncTraits.bgColors[2] = '#725d18'; // Darker Gold
        syncTraits.infColors[0] = 'black';
        syncTraits.infColors[2] = '#E5E4E2'; // Platinum
      }
    } else {
      syncTraits.theme = 'Common'; // Common
      syncTraits.sigil = '\xE2\x97\x8F\x20\x20\x20\x20'; // Circle 
      syncTraits.driftColors = 'white';
      syncTraits.bgColors = syncTraits.baseColors;
      syncTraits.infColors = syncTraits.baseColors;

      bytes[] memory upgrades = new bytes[](3);
      upgrades[0] = '#214F70';
      upgrades[1] = '#FAF7C0';
      upgrades[2] = '#222222';
      
      if (syncTraits.rarity_roll % 13 == 0) {
        // 7.7% probability ((77 in 1000)
        syncTraits.theme = 'Mosaic';
        syncTraits.sigil = '\xE2\x9C\xA6\x20\x20\x20\x20'; // Full Diamond
        upgrades[2] = '#3A424F';
      } else if (syncTraits.rarity_roll % 11 == 0) {
        // 9% probability (91 in 1000)
        syncTraits.theme = 'Tokyo Drift';
        syncTraits.sigil = '\xE2\x9C\xA7\x20\x20\x20\x20'; //Empty Diamond
        upgrades[2] = '#3A424F';
      }
      if (_colorTokenIds[tokenId].length == 0){
        syncTraits.baseColors[0] = upgrades[syncTraits.rarity_roll % 3];
      }
    }
    //Background generation
    for (uint256 i = 0; i < 15; i++) {
      syncTraits.shape_x[i] = uint16(1 + ((seed & 0x3FF) % 500));
      syncTraits.shape_y[i] = uint16(1 + (((seed & 0x3FF0000) / 2**4) % 500));
      syncTraits.shape_sizex[i] = uint16(
        250 + (((seed & 0x1FF00000000) / 2**5) % 151)
      );
      syncTraits.shape_sizey[i] = uint16(
        250 + (((seed & 0x1FF000000000000) >> 48) % 151)
      );
      syncTraits.shape_r[i] = uint16(
        1 + (((seed & 0x1FF0000000000000000) / 2**6) % 360)
      );
      syncTraits.shape_type[i] = uint8(
        ((seed & 0x1FF00000000000000000000) >> 80) % 2
      );
      syncTraits.shape_color[i] = uint8(
        ((seed & 0x1FF000000000000000000000000) >> 96) % 3
      );
      seed = seed >> 2;
    }
    return syncTraits;
  }

  /**
   * Produce a PRNG uint256 as hash of several inputs
   */
  function _rng(uint256 tokenId) private view returns (uint256) {
    uint256 _tokenId = tokenId + 1;
    uint256 seed = uint256(uint160(THE_COLORS));
    return
      uint256(
        keccak256(
          abi.encodePacked(
            _tokenId.toString(),
            block.timestamp,
            block.difficulty,
            seed
          )
        )
      ) + uint256(_tokenId * seed);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import 'base64-sol/base64.sol';
import './INFTOwner.sol';


/**
 * @title TheColors contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract TheColors is ERC721Enumerable, Ownable {
  using Strings for uint256;
  using Strings for uint32;

  string public PROVENANCE_HASH = '';

  /*address constant public THE_COLORS_LEGACY = address(0xc22f6c6f04c24Fac546A43Eb2E2eB10b1D2953DA);*/

  uint256 public constant MAX_COLORS = 4317;

  mapping(uint256 => uint32) private _hexColors;
  mapping(uint32 => bool) public existingHexColors;

  constructor() ERC721('The Colors (thecolors.art)', 'COLORS') {}

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721)
    returns (string memory)
  {
    require(
      _hexColors[tokenId] > 0,
      'ERC721Metadata: URI query for nonexistent token'
    );

    uint32 hexColor = _hexColors[tokenId];
    string memory hexString = uintToHexString(hexColor);
    string memory image = Base64.encode(bytes(generateSVGImage(hexString)));

    return
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{',
                '"image":"',
                'data:image/svg+xml;base64,',
                image,
                '",',
                '"image_data":"',
                escapeQuotes(generateSVGImage(hexString)),
                '",',
                generateNameDescription(tokenId, hexString),
                generateAttributes(hexColor, hexString),
                '}'
              )
            )
          )
        )
      );
  }

  function getTokenMetadata(uint256 tokenId)
    public
    view
    returns (string memory)
  {
    uint32 hexColor = _hexColors[tokenId];
    string memory hexString = uintToHexString(hexColor);
    string memory image = Base64.encode(bytes(generateSVGImage(hexString)));

    return
      string(
        abi.encodePacked(
          'data:application/json',
          '{',
          '"image":"',
          'data:image/svg+xml;base64,',
          image,
          '",',
          '"image_data":"',
          escapeQuotes(generateSVGImage(hexString)),
          '",',
          generateNameDescription(tokenId, hexString),
          generateAttributes(hexColor, hexString),
          '}'
        )
      );
  }

  function getTokenSVG(uint256 tokenId) public view returns (string memory) {
    uint32 hexColor = _hexColors[tokenId];
    string memory hexString = uintToHexString(hexColor);
    return generateSVGImage(hexString);
  }

  function getBase64TokenSVG(uint256 tokenId)
    public
    view
    returns (string memory)
  {
    uint32 hexColor = _hexColors[tokenId];
    string memory hexString = uintToHexString(hexColor);
    string memory image = Base64.encode(bytes(generateSVGImage(hexString)));
    return string(abi.encodePacked('data:application/json;base64', image));
  }

  function getHexColor(uint256 tokenId) public view returns (string memory) {
    uint32 hexColor = _hexColors[tokenId];
    string memory hexString = uintToHexString(hexColor);
    return string(abi.encodePacked('#', hexString));
  }

  function getRGB(uint256 tokenId) public view returns (string memory) {
    string memory r = getRed(tokenId).toString();
    string memory g = getGreen(tokenId).toString();
    string memory b = getBlue(tokenId).toString();

    return string(abi.encodePacked('rgb(', r, ',', g, ',', b, ')'));
  }

  function getRed(uint256 tokenId) public view returns (uint32) {
    uint32 hexColor = _hexColors[tokenId];
    return ((hexColor >> 16) & 0xFF); // Extract the RR byte
  }

  function getGreen(uint256 tokenId) public view returns (uint32) {
    uint32 hexColor = _hexColors[tokenId];
    return ((hexColor >> 8) & 0xFF); // Extract the GG byte
  }

  function getBlue(uint256 tokenId) public view returns (uint32) {
    uint32 hexColor = _hexColors[tokenId];
    return ((hexColor) & 0xFF); // Extract the BB byte
  }

  /*
   * Set provenance once it's calculated
   */
  function setProvenanceHash(string memory provenanceHash) public onlyOwner {
    PROVENANCE_HASH = provenanceHash;
  }

  /**
   * Mints The Colors to The Colors Legacy holders
   */
  function mintNextColors(uint256 numberOfTokens) public {
    require(
      totalSupply() + numberOfTokens <= MAX_COLORS,
      'Purchase would exceed max supply of Colors'
    );

    uint256 mintIndex;
    /*address tokenOwner;*/
    for (uint256 i = 0; i < numberOfTokens; i++) {
      mintIndex = totalSupply();

      if (totalSupply() < MAX_COLORS) {
        /*tokenOwner = INFTOwner(THE_COLORS_LEGACY).ownerOf(mintIndex);*/

        _safeMint(msg.sender, mintIndex);
        generateRandomHexColor(mintIndex);
      }
    }
  }

  function generateNameDescription(uint256 tokenId, string memory hexString)
    internal
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '"external_url":"https://thecolors.art",',
          unicode'"description":"The Colors are a set of 8,888 iconic shades generated and stored entirely on-chain to be used as a primitive and for color field vibes. ~ A Color is Forever ∞',
          '\\nHex: #',
          hexString,
          '\\n\\nToken id: #',
          tokenId.toString(),
          '",',
          '"name":"#',
          hexString,
          '",'
        )
      );
  }

  function generateAttributes(uint32 hexColor, string memory hexString)
    internal
    pure
    returns (string memory)
  {
    string memory r = ((hexColor >> 16) & 0xFF).toString(); // Extract the RR byte
    string memory g = ((hexColor >> 8) & 0xFF).toString(); // Extract the GG byte
    string memory b = ((hexColor) & 0xFF).toString(); // Extract the BB byte

    string memory rgb = string(
      abi.encodePacked('rgb(', r, ',', g, ',', b, ')')
    );

    return
      string(
        abi.encodePacked(
          '"attributes":[',
          '{"trait_type":"Hex code","value":"#',
          hexString,
          '"},'
          '{"trait_type":"RGB","value":"',
          rgb,
          '"},',
          '{"trait_type":"Red","value":"',
          r,
          '"},',
          '{"trait_type":"Green","value":"',
          g,
          '"},',
          '{"trait_type":"Blue","value":"',
          b,
          '"}',
          ']'
        )
      );
  }

  function generateSVGImage(string memory hexString)
    internal
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '<svg width="690" height="690" xmlns="http://www.w3.org/2000/svg" style="background-color:#',
          hexString,
          '">',
          '</svg>'
        )
      );
  }

  function generateRandomHexColor(uint256 tokenId) internal returns (uint32) {
    uint32 hexColor = uint32(_rng() % 16777215);

    while (existingHexColors[hexColor]) {
      hexColor = uint32(
        uint256(hexColor + block.timestamp * tokenId) % 16777215
      );
    }

    existingHexColors[hexColor] = true;
    _hexColors[tokenId] = hexColor;

    return hexColor;
  }

  function uintToHexString(uint256 number) public pure returns (string memory) {
    bytes32 value = bytes32(number);
    bytes memory alphabet = '0123456789abcdef';

    bytes memory str = new bytes(6);
    for (uint256 i = 0; i < 3; i++) {
      str[i * 2] = alphabet[uint256(uint8(value[i + 29] >> 4))];
      str[1 + i * 2] = alphabet[uint256(uint8(value[i + 29] & 0x0f))];
    }

    return string(str);
  }

  function escapeQuotes(string memory symbol)
    internal
    pure
    returns (string memory)
  {
    bytes memory symbolBytes = bytes(symbol);
    uint256 quotesCount = 0;
    for (uint256 i = 0; i < symbolBytes.length; i++) {
      if (symbolBytes[i] == '"') {
        quotesCount++;
      }
    }
    if (quotesCount > 0) {
      bytes memory escapedBytes = new bytes(symbolBytes.length + (quotesCount));
      uint256 index;
      for (uint256 i = 0; i < symbolBytes.length; i++) {
        if (symbolBytes[i] == '"') {
          escapedBytes[index++] = '\\';
        }
        escapedBytes[index++] = symbolBytes[i];
      }
      return string(escapedBytes);
    }
    return symbol;
  }

  function _rng() internal view returns (uint256) {
    return
      uint256(keccak256(abi.encodePacked(block.timestamp + block.difficulty)));
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface INFTOwner {
  function ownerOf(uint256 tokenId) external view returns (address);
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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