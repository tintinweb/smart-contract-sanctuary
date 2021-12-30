// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./libraries/Base64.sol";
import "./libraries/FormatMetadata.sol";
import "./libraries/StringList.sol";
import "./layers/ITrait.sol";
import "./layers/Bodies.sol";
import "./layers/Eyes.sol";
import "./layers/Hats.sol";
import "./layers/Mouths.sol";
import "./layers/Pants.sol";
import "./layers/Tops.sol";
import "./ICritterzMetadata.sol";

contract CritterzMetadata is ICritterzMetadata, Ownable, VRFConsumerBase {
  using Base64 for bytes;
  using Strings for uint256;
  using StringList for string[];

  string internal constant HEADER =
    '<svg id="critterz" width="100%" height="100%" version="1.1" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
  string internal constant FRONT_HEADER_PLACEHOLDER =
    '<svg id="critterz" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
  string internal constant FRONT_HEADER =
    '<svg id="critterz" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" style="background-color:';
  string internal constant FRONT_HEADER_CLOSING = '">';
  string internal constant FOOTER =
    "<style>#critterz{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>";

  string internal constant PNG_HEADER =
    '<image x="0" y="0" width="64" height="64" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,';
  string internal constant PNG_HEADER_PLACEHOLDER =
    '<image x="0" y="0" width="40" height="40" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,';
  string internal constant PNG_FRONT_HEADER =
    '<image x="12" y="4" width="16" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,';
  string internal constant PNG_FRONT_ARMOR_HEADER =
    '<image x="11" y="3" width="18" height="36" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,';
  string internal constant PNG_FOOTER = '"/>';

  string internal constant STAKED_LAYER =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAD1BMVEUAAAAeDwA4HABcLRlnPizWq/oQAAAAAXRSTlMAQObYZgAAAC9JREFUGNNjYBgsQAlKM5koQBgqzhAGk7GTAJgh7GIEYYiYKELVOkMZDEICtHEVAG0PAxFGcat9AAAAAElFTkSuQmCC";

  string internal constant PLACEHOLDER_LAYER =
    "iVBORw0KGgoAAAANSUhEUgAAACgAAAAoBAMAAAB+0KVeAAAAElBMVEVQOAPvmQDxwgD/0Aro6N/////AfLfFAAAAiUlEQVQoz63S0QnDMAwE0ANN4GaDm8Do6ACFDFAo2n+VOh8lQdaHodHnwzpjydiLwk2oURPCCuyCFe1da5kbzDO+WhNnfDCj1LYzFec1FUbM+Iz4ZPQAQp7RFJaxVzhS3wUGciaPg7+HXlEJSQkiV+Z5tC/iyFzbUY0u/wc5r3h3+owkeff3vtYXMN7FTEvCxhsAAAAASUVORK5CYII=";

  address public bodies;
  address public eyes;
  address public mouths;
  address public pants;
  address public tops;
  address public hats;
  address public backgrounds;

  uint256 public override seed;

  bytes32 internal keyHash;
  uint256 internal fee;

  string internal _description;

  string internal _stakedDescription;

  struct TraitLayer {
    string name;
    string skinLayer;
    string frontLayer;
    string frontArmorLayer;
    uint256 bodyIndex;
  }

  constructor(
    address _bodies,
    address _eyes,
    address _mouths,
    address _pants,
    address _tops,
    address _hats,
    address _backgrounds,
    address _vrfCoordinator,
    address _link,
    bytes32 _keyHash,
    uint256 _fee
  ) VRFConsumerBase(_vrfCoordinator, _link) {
    bodies = _bodies;
    eyes = _eyes;
    mouths = _mouths;
    pants = _pants;
    tops = _tops;
    hats = _hats;
    backgrounds = _backgrounds;
    keyHash = _keyHash;
    fee = _fee;

    _description = "The first fully on-chain NFT collection to enable P2E while playing Minecraft. Stake to generate $BLOCK tokens in-game and use $BLOCK tokens to claim Plots of in-game land as NFTs.";
    _stakedDescription = "You should ONLY get staked Critterz from here if you want to RENT a Critter. These are NOT the same as Critterz NFTs -- staked Critterz have a steak in their hands. Rented Critterz also give access to the Critterz Minecraft world but generates less $BLOCK and are time limited.";
  }

  /*
  READ FUNCTIONS
  */

  function getMetadata(
    uint256 tokenId,
    bool staked,
    string[] calldata additionalAttributes
  ) external view override returns (string memory) {
    TraitLayer[8] memory traitLayers;

    traitLayers[0] = _getTrait(bodies, tokenId, 0);
    traitLayers[1] = _getTrait(eyes, tokenId, traitLayers[0].bodyIndex % 6);
    traitLayers[2] = _getTrait(mouths, tokenId, traitLayers[0].bodyIndex % 6);
    traitLayers[3] = _getTrait(pants, tokenId, 0);
    traitLayers[4] = _getTrait(tops, tokenId, 0);
    traitLayers[5] = _getTrait(hats, tokenId, 0);
    traitLayers[6] = _getTrait(backgrounds, tokenId, 0);

    string memory skinSvg = _getSkinSvg(
      traitLayers[0].skinLayer,
      traitLayers[1].skinLayer,
      traitLayers[2].skinLayer,
      traitLayers[3].skinLayer,
      traitLayers[4].skinLayer,
      traitLayers[5].skinLayer
    );

    string memory frontSvg = _getFrontSvg(
      traitLayers[0].frontLayer,
      traitLayers[1].frontLayer,
      traitLayers[2].frontLayer,
      traitLayers[3].frontLayer,
      traitLayers[4].frontLayer,
      traitLayers[5].frontLayer,
      traitLayers[5].frontArmorLayer,
      traitLayers[6].frontLayer,
      staked
    );

    string[] memory attributes = _getAttributes(
      traitLayers[0].name,
      traitLayers[1].name,
      traitLayers[2].name,
      traitLayers[3].name,
      traitLayers[4].name,
      traitLayers[5].name,
      traitLayers[6].name,
      additionalAttributes
    );

    return _formatMetadata(tokenId, skinSvg, frontSvg, attributes, staked);
  }

  function getPlaceholderMetadata(
    uint256 tokenId,
    bool staked,
    string[] calldata additionalAttributes
  ) external view override returns (string memory) {
    string memory svg = _getPlaceholderSvg(staked);
    return _formatMetadata(tokenId, svg, svg, additionalAttributes, staked);
  }

  function _getFrontSvg(
    string memory bodyLayer,
    string memory eyeLayer,
    string memory mouthLayer,
    string memory pantsLayer,
    string memory topLayer,
    string memory hatLayer,
    string memory hatFrontLayer,
    string memory backgroundHex,
    bool staked
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          _formatBackgroundHeader(backgroundHex),
          _formatLayer(bodyLayer, true, false),
          _formatLayer(eyeLayer, true, false),
          _formatLayer(mouthLayer, true, false),
          _formatLayer(pantsLayer, true, false),
          _formatLayer(topLayer, true, false),
          _formatLayer(hatLayer, true, false),
          _formatLayer(hatFrontLayer, true, true),
          staked ? _formatLayer(STAKED_LAYER, true, false) : "",
          FOOTER
        )
      );
  }

  function _getSkinSvg(
    string memory bodyLayer,
    string memory eyeLayer,
    string memory mouthLayer,
    string memory pantsLayer,
    string memory topLayer,
    string memory hatLayer
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          HEADER,
          _formatLayer(bodyLayer, false, false),
          _formatLayer(eyeLayer, false, false),
          _formatLayer(mouthLayer, false, false),
          _formatLayer(pantsLayer, false, false),
          _formatLayer(topLayer, false, false),
          _formatLayer(hatLayer, false, false),
          FOOTER
        )
      );
  }

  function _getPlaceholderSvg(bool staked)
    internal
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          FRONT_HEADER_PLACEHOLDER,
          string(abi.encodePacked(PNG_HEADER_PLACEHOLDER, PLACEHOLDER_LAYER, PNG_FOOTER)),
          staked ? _formatLayer(STAKED_LAYER, true, false) : "",
          FOOTER
        )
      );
  }

  function _getAttributes(
    string memory bodyName,
    string memory eyeName,
    string memory mouthName,
    string memory pantsName,
    string memory topName,
    string memory hatName,
    string memory backgroundName,
    string[] memory additionalAttributes
  ) internal pure returns (string[] memory) {
    string[] memory attributes = new string[](7);
    attributes[0] = FormatMetadata.formatTraitString("Body", bodyName);
    attributes[1] = FormatMetadata.formatTraitString("Eye", eyeName);
    attributes[2] = FormatMetadata.formatTraitString("Mouth", mouthName);
    attributes[3] = FormatMetadata.formatTraitString("Pants", pantsName);
    attributes[4] = FormatMetadata.formatTraitString("Top", topName);
    attributes[5] = FormatMetadata.formatTraitString("Hat", hatName);
    attributes[6] = FormatMetadata.formatTraitString(
      "Background",
      backgroundName
    );

    return attributes.concat(additionalAttributes);
  }

  function _getTrait(
    address trait,
    uint256 tokenId,
    uint256 layerIndex
  ) public view returns (TraitLayer memory) {
    {
      ITrait traitContract = ITrait(trait);
      uint256 index;
      uint256 nonce;
      string memory name;
      string memory skinLayer;
      // resample if layer doesn't exist on sampled trait
      while (bytes(skinLayer).length == 0 && nonce < 15) {
        index = traitContract.sampleTraitIndex(
          _random(trait, tokenId, nonce++)
        );
        name = traitContract.getName(index);
        // skin layer doesn't have background trait and all background layers
        // are valid. If name is empty, it means trait is "None"
        if (trait == backgrounds || bytes(name).length == 0) {
          break;
        }
        skinLayer = traitContract.getSkinLayer(index, layerIndex);
      }
      string memory frontLayer = traitContract.getFrontLayer(index, layerIndex);
      string memory frontArmorLayer = traitContract.getFrontArmorLayer(
        index,
        layerIndex
      );
      TraitLayer memory traitStruct = TraitLayer(
        name,
        skinLayer,
        frontLayer,
        frontArmorLayer,
        index
      );
      return traitStruct;
    }
  }

  function _formatMetadata(
    uint256 tokenId,
    string memory svg,
    string memory frontSvg,
    string[] memory attributes,
    bool staked
  ) internal view returns (string memory) {
    return
      FormatMetadata.formatMetadata(
        string(
          abi.encodePacked(staked ? "s" : "", "Critterz #", tokenId.toString())
        ),
        staked ? _stakedDescription : _description,
        string(
          abi.encodePacked(
            "data:image/svg+xml;base64,",
            bytes(frontSvg).encode()
          )
        ),
        attributes,
        string(
          abi.encodePacked(
            '"skinImage": "data:image/svg+xml;base64,',
            bytes(svg).encode(),
            '"'
          )
        )
      );
  }

  function _formatLayer(
    string memory layer,
    bool frontView,
    bool armorLayer
  ) internal pure returns (string memory) {
    if (!frontView) {
      assert(!armorLayer);
    }
    if (bytes(layer).length == 0) {
      return "";
    }
    if (frontView) {
      if (armorLayer) {
        return
          string(abi.encodePacked(PNG_FRONT_ARMOR_HEADER, layer, PNG_FOOTER));
      } else {
        return string(abi.encodePacked(PNG_FRONT_HEADER, layer, PNG_FOOTER));
      }
    } else {
      return string(abi.encodePacked(PNG_HEADER, layer, PNG_FOOTER));
    }
  }

  // Background exists only for the front view
  function _formatBackgroundHeader(string memory backgroundHex)
    internal
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(FRONT_HEADER, backgroundHex, FRONT_HEADER_CLOSING)
      );
  }

  function _random(
    address trait,
    uint256 tokenId,
    uint256 nonce
  ) internal view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            seed,
            trait,
            tokenId,
            keccak256(abi.encodePacked(nonce))
          )
        )
      );
  }

  /*
  OWNER FUNCTIONS
  */

  function setAddresses(
    address _bodies,
    address _eyes,
    address _mouths,
    address _tops,
    address _pants,
    address _hats
  ) external onlyOwner {
    bodies = _bodies;
    eyes = _eyes;
    mouths = _mouths;
    tops = _tops;
    pants = _pants;
    hats = _hats;
  }

  function setDescription(string calldata description) external onlyOwner {
    _description = description;
  }

  function setStakedDescription(string calldata stakedDescription)
    external
    onlyOwner
  {
    _stakedDescription = stakedDescription;
  }

  function initializeSeed() external onlyOwner returns (bytes32 requestId) {
    require(seed == 0, "Seed already initialized");
    return requestRandomness(keyHash, fee);
  }

  /**
   * Callback function used by VRF Coordinator
   */
  function fulfillRandomness(bytes32, uint256 randomness) internal override {
    seed = randomness;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
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
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
  string internal constant TABLE_ENCODE =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  function encode(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return "";

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
      for {

      } lt(dataPtr, endPtr) {

      } {
        // read 3 bytes
        dataPtr := add(dataPtr, 3)
        let input := mload(dataPtr)

        // write 4 characters
        mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
        resultPtr := add(resultPtr, 1)
        mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
        resultPtr := add(resultPtr, 1)
        mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
        resultPtr := add(resultPtr, 1)
        mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
        resultPtr := add(resultPtr, 1)
      }

      // padding with '='
      switch mod(mload(data), 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }
    }

    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./Base64.sol";
import "./StringList.sol";

library FormatMetadata {
  using Base64 for bytes;
  using StringList for string[];
  using Strings for uint256;

  function formatTraitString(string memory traitType, string memory value)
    internal
    pure
    returns (string memory)
  {
    if (bytes(value).length == 0) {
      return "";
    }
    return
      string(
        abi.encodePacked(
          '{"trait_type":"',
          traitType,
          '","value":"',
          value,
          '"}'
        )
      );
  }

  function formatTraitNumber(
    string memory traitType,
    uint256 value,
    string memory displayType
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '{"trait_type":"',
          traitType,
          '","value":',
          value.toString(),
          ',"display_type":"',
          displayType,
          '"}'
        )
      );
  }

  function formatTraitNumber(
    string memory traitType,
    int256 value,
    string memory displayType
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '{"trait_type":"',
          traitType,
          '","value":',
          intToString(value),
          ',"display_type":"',
          displayType,
          '"}'
        )
      );
  }

  function formatMetadata(
    string memory name,
    string memory description,
    string memory image,
    string[] memory attributes,
    string memory additionalMetadata
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          bytes(
            abi.encodePacked(
              '{"name": "',
              name,
              '", "description": "',
              description,
              '", "image": "',
              image,
              '", "attributes": [',
              attributes.join(", ", true),
              "]",
              bytes(additionalMetadata).length > 0 ? "," : "",
              additionalMetadata,
              "}"
            )
          ).encode()
        )
      );
  }

  function formatMetadataWithSVG(
    string memory name,
    string memory description,
    string memory svg,
    string[] memory attributes,
    string memory additionalMetadata
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          bytes(
            abi.encodePacked(
              '{"name": "',
              name,
              '", "description": "',
              description,
              '", "image_data": "',
              svg,
              '", "attributes": [',
              attributes.join(", ", true),
              "]",
              bytes(additionalMetadata).length > 0 ? "," : "",
              additionalMetadata,
              "}"
            )
          ).encode()
        )
      );
  }

  function intToString(int256 n) internal pure returns (string memory) {
    uint256 nAbs = n < 0 ? uint256(-n) : uint256(n);
    bool nNeg = n < 0;
    return string(abi.encodePacked(nNeg ? "-" : "", nAbs.toString()));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StringList {
  /**
   * @dev join list of strings with delimiter
   */
  function join(
    string[] memory list,
    string memory delimiter,
    bool skipEmpty
  ) internal pure returns (string memory) {
    if (list.length == 0) {
      return "";
    }
    string memory result = list[0];
    for (uint256 i = 1; i < list.length; i++) {
      if (skipEmpty && bytes(list[i]).length == 0) continue;
      result = string(abi.encodePacked(result, delimiter, list[i]));
    }
    return result;
  }

  /**
   * @dev concatenate two lists of strings
   */
  function concat(string[] memory list1, string[] memory list2)
    internal
    pure
    returns (string[] memory)
  {
    string[] memory result = new string[](list1.length + list2.length);
    for (uint256 i = 0; i < list1.length; i++) {
      result[i] = list1[i];
    }
    for (uint256 i = 0; i < list2.length; i++) {
      result[list1.length + i] = list2[i];
    }
    return result;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITrait {
  function getSkinLayer(uint256 traitIndex, uint256 layerIndex)
    external
    view
    returns (string memory layer);

  function getFrontLayer(uint256 traitIndex, uint256 layerIndex)
    external
    view
    returns (string memory frontLayer);

  function getFrontArmorLayer(uint256 traitIndex, uint256 layerIndex)
    external
    view
    returns (string memory frontArmorLayer);

  function getName(uint256 traitIndex)
    external
    view
    returns (string memory name);

  function sampleTraitIndex(uint256 rand) external view returns (uint256 index);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Trait.sol";

contract Bodies is Trait {
  // Skin view
  string public constant MOUSE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAHlBMVEUAAACbnZmoqqf3ocW1t7TCxMH6uNXP0c7/0ODy9PBk4k/iAAAAAXRSTlMAQObYZgAAAlFJREFUSMftlEGumzAQhnMFp0ZZg+AAT9l0a/SPvDaakdULoGwjYaGuK6EcoG/BbTsOpM0T5PUCbxYJyJ//sWeY/3DQ4JTIHCtzeBXCIlVlypcAJUlG47XCmOQ/AH8OsBB/Chgb8nr1EjgX4Wyqah8gYXMGzm8gJhHZAC7Kt+8iv95EYGOkDWDHhLwT4kWftwoco2RAaAwUxy1ANEoNFYiRKSVsgEL7ULOGT20p0m4AAHJk/UlwFdy2YQYGR6UYzpmy3aumyDQt//K3I8z99AT0/QOwgMvPXj4ATworYIdl0wawepClAZfLulwHO4Ko0q2mqoG2alsYg5zuDjSdT0BRAlFGUUBJ0lsrwEuClpOWQQE/zwNQH8VZtlFr7xbA6SeLOivMs2rVPnHBpPXFQwFX5sYBP+b5XYEmdZRoUIW0AvbKaFrIz3n+rajEzjMNTCvQdKeBWTqSrCDcxNjZq9Vj2XAHjgFX7WcrWeE9KwS2wepxi2Fpdwc9UNMtgFaE9BbhpAqe1xR6i6zAMV+TapAr+ClF1eYPrmq1Rvdroqq1ULbve1oUpts09f3lAhjiAC6NLfP77XbpD1/xFa9D1oFlfvGpPHzCy0tgUZBnb9gDCNO0swyMTu3MZUe2xmIHKBw4D5A4jyLsADqy3OgIJlcEj31gIFXI4Do0HzwbPujAqRsT1B2GreuTz2coWZXUv7cA6BQ8q8PpfmLvdqoQHYWjGpwf7EB7wOmqgA65DDQUvAMUan9N0BSOnB32ALaonRqDcxbbFHdPuEzT7e4X/7z+D7sW7hfwM1TYAAAAAElFTkSuQmCC";
  string public constant MOUSE_GOLD =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAFlUlEQVR42u1bO2/bVhQ+JMSkZho7bYcCHCR09NwOUn9B58JAli7N0h+RuXPm7l2y9CdkjIQAnT3LKAhkSNG0AB2YQtiB/MjvHt5LXsXUwwYPIJCiJYrn/Z2HA+mh4u/fCsmvRE7mIptUZJKUx/xKJJqKvH/ZfDiaNef5WkREgm9eBXLENPH6VDRtmOZrmmliXKJZc36nBQBNTxL1TViCg8k7wLyISOilfWYagtikch8o3Pob2hXuOPnFAGYYLqGv31sB1FF+KRIv2pHf6TqzeyKAeFEes6UZD/j6HWJYU1C8fV4YjMG0wRgY7aJsaX5Ou4i+Pz/Al78cFCeEhpkjwuOBK6aKxxflNXoVjy/a2QIvZj5bNue4/yQ5mvgR1trjh1OaDz68aWvuw5uWoGrGJ4kpDM38Ju20iv0K4OypmdcBdzUDXTghmjYaPZmbARSBk3GDBlUHDYJIa9pMa42mdmCk/RtoEQLUlsF/OyIsETZRvBLCJrWjPLYGxgJ4zwIEg3lavt6/NC3MJdyDWEC8aAMdQ9Nru+Z1YWTTbL4u02M0M69ny6MpliatdFe/70CDNqSoGcT9mMl8XcWE46kUA2v9z+8/+06Cm0spHpxLcHMpwZOfgt7+gReydDxQT/+g7k/AZR+el9c9n29rJBjcXBrHQcgFrmB9fXUJmjMDpNLearB4cG4cByEfRru+e71qgalPVVB4EMfT8SZb+guFcUVlAbdRUlD89XMhUWJWefGiATTXKzPaw/+y6nqUdGuYi6TIAYA4HUZJ+Z6PNquBELUbAHyBwa9/DfpjAPf3oqRhXuMBFElnlCI1U9FU5Kt5813dQXJlE74PznH/aNrOSn3+z+Cu0wXieTv/a61ryfelRBGR0wuRJ89E4u/Ll6sAgpazZXWuIDiKKVxjS7BBargIV7TeMSBft1FeCwWmfj3E8LQ54rxLa/FC5PRHsyK1mTkY1O6plcDf9xYA/BWaQkzQQommbn8WEfn8h/L48d/yJVJaQWd6s0DwPG2YQIHmU1ABmXqkydA7RdnM1whwU3v7nC2BBakFGs/NatSIVD0FlEai2xVDq/YDIQjaujx4UM0AiLUI5mENNuY1o115H+kSRZutYct/9+hdhpKvm5QGrA7f4koRx2xlSlwzY2MCbtBXV4Cpdy/amUG7h48LeMeAWqsz8wddN+hrlmiG2RK4muRYwkI5e9odxU/m7sEMulueg5vQ2s3tCyIun4PpZa8tpvzanQZZKNZYo1pvrujPLuMJuUsglK3aUb1LgozQbJrNr8qoH56W1sBpsDVkSbrTa11WK8GEj+pKsFtgr7qh8MfszwLlLhcWKC9dBVL9mf/+sGcRztc8SufcXneN1hawVV3/4lnn79uqV372bcvjkUYaaaSRRhpppJFGGmmkkUYa6f7T4M2C1n5A+MhoYITxt1vP/3fZ4NjLdHirHQPM/0X2skq3FwFsNb7G6JtmiYMuZxxCAFsRmp9VZ3cnCxpDxoDi7XPT53mvgNvSxtL1rJkIY1FTCwCLVnzU95L++X8fTQYX6bsXJlO6CxzNaBDTsY8YkxB4+5S31n3W9vfuApjMuMbbWtMtlah5Q7Zs1mF4rzm/8ttk37sFOH8pMQch0dQ+DLle0XDWIlyRRiADrNsOYwGudGWb5kL72cq9LGkbhetV/oEWrsNBmLdNinFNm2lu2e/DOI33jfVKzI7+S+32AtCa0iN1zgwiVfSvZpF6h5gtwLZxjt+bJO0sc7AYoLWJDMCMQXv6/4viuV0AbN7ZsowFJ/TZAa1h+CyA1MRa3yZu6H+u4CGrtrABssBukOAmNWf0HA8YB9jyOCNBNnF+DzcYIjntLO1huZEf2hY3Hp77WxVrfKAYcHso/M/vha34ce0c8LnvjN9VYH3Kerym/wFb+eX9GW42nAAAAABJRU5ErkJggg==";
  string public constant FROG =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAHlBMVEUAAAA7lEpEpFNNsmA+uFVLy2R565KV9mKK+Xuu+YeVjfWeAAAAAXRSTlMAQObYZgAAAoNJREFUSMftlcFu3CAQhvcVwFvlzMAqe4Uh7V6Dh8NeHVAfodpjUinWvkFybKKsy9t2bGerpLbTF8hcQPbHD8x4fq9WHAF8Nhbr1VLUiaIQFS4DOYXGUFwGYq4T0H4RiIkBattFIKVMzf5YPlCIN7vHh4+AHHePZR5IMRHkDCbHmCnlCeATcRYykefXMU+vauroTYKgfb8R0QQg01DalTuNiYg2MAEghNDwAe+IIk/9BNAQsCmlPKmrRAam9QCQbssKnfcJtHMTAMHpr6xQdJ3RIcxkAnFMkdbotMV1P6/wTeL/At/ao7DrQaPWpZsAeOxKLdZ2mOvyVuFw6EdX2s5coxzUXp/1t7DeATgQalt+l/Js1mupUJvIX+m43nGlAEQltv1dflkFwYMzlF01AEqmBgBdZXcDwHnzCMB1VWNWhcIAoJSU/RdRnkLFiO638GMbOBXDBqy1YgCeeXVlEIgSjIDlKvIplB0SXmRwFSEGrr0LI6ASH1MLYbcPDFQo7do5k3Kq9ABIlZqcpVKKFZ64vUAiIotmHCtreY+clXQqMCAdWn6PkQHxCsgNK2hUkh7Kpuov3ANNOitc/Ny/5Hx5i8JsIfT6PZBLm167/f7+dDiW9qjcl2ACb+A0tt3h0HbHbvUZn7Ec5y53YsFSz4D3/wHemcd74HQa+30c/wkh9A1oKVIO7FXg5gBQQmBKwVl2vjngSmLFxhB0jc7OAKYWCIoy8XpHM8DmykrNXUnaAlzPAWy00sacAPEa585QW6cUGwNbEPo5IGrtZEo3gbvXzbi+IcU+kiP/E+aBTeTWZzuKiQ9TzQD7l4vby7vvpTTILjAB2vZ0Ovxo2RZOp46H8/M/lvTY1DIlh4sAAAAASUVORK5CYII=";
  string public constant FROG_GOLD =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAIVBMVEUAAADPtCThwyXw0Cf+2xv+3TL/4Eb95Fr/8a7+9cX899RhptAzAAAAAXRSTlMAQObYZgAAAp9JREFUSMftlb1u2zAQx/0KNMt0tg0P7SaxZ8PZkiLeqfORtbfEpdNdoPkKjbYUKBB5K9wiMp+ylOx2qOT0BXIaSIg/nO6Lf/V60TJJfqyIeuds4cgwJs4D6BFv+XByFiCixWcGq7OAWXsiWX49C+RuQ3erXTjvgYxb7srw0ifMche6AWccSe8leGM8Od/OwMVH38dE4rHxpgUAGQInMa7Om45qEuRkl2EP0RHRVLYAiYh5DHBPZOK27QEk0jpEIInRgmwDUnKcRQ+ByElAbMcQ4/sUz8MkpoEkO1t1LNGCCOGKRL3nuggtAJZVwZRIGxhCG5jvDoGYUB1AUTRjE8oqDh6v95PTu/o4zqKUOGLJLBxC+AlC9AcWAO5BHQGMnZKyL9iszuWHGgwzShHkPTbh9jLucikJx2rZACMk0qkku0luGmCgCKVUyUjUExH2mRgijQDm/tQ4TA1OpVJZvwF+UX8kRKweutERULGLPl4bRU3BOa5F7Cpq6++OZVepi2ECY2pWRuANcSWsBbe1p4vEU5d7zwdJEj3sB4JSruvx8v7D6RPKOu9TjkOMACet5pa08ZYYndKcRg9AA05lmAqy6wutyeRrZ4/Au++rZ+8vHxdDmMlsyMle6I31obRaN0D1VBW7UBUZvkXAG0VyrMtQFOVhd+i92qv1XpD0442+Y2ck9Q9A8B8Ax+FwBqiqevXr4/qPMQYOQfTdNopu1s+6ABowRrlDVBLHXYDhJKIwIGjCqy5ADylNaEPyetwhyYxNjRpB/VeA21SqLiAKbT/T1smNVl0eJqQ+JondOpwT2S7AACC3a4c3RFmH6tcSoBKrQW6svu4ApvGHJNBsjdN2IzqA1fP7x8tvX0LINXUEWZZVVTw8RFmoqkN4+tuu37PtHby9UpV8AAAAAElFTkSuQmCC";
  string public constant CAT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAKlBMVEUAfoMAAADfhAbme6LykxL1qUH3s131uGb6vXLxu871woDw38b369768eo1FJ5bAAAAAXRSTlMAQObYZgAAAn1JREFUSMftVbtq41AQ9beYbbfdLwhmN72E6l17Msh2G4Lr9TAkcbeNIemCCfoAEdBNawgzt9kiWET6lx1JTgjRtfcHMhi50NGcM4977mBgAQAUWQwOBSJjlBwBADOoxTEAHgUQ038ymMijgBOEkxcVdxAwHI2H+nAdBgDhzyHQ8AshxCa2LxDg91eGv98BcGJiAiXS+AfgnxEyQELUz4BoPwQk46C4T4EA9ilh+zhb9jMwCJgOAGdkpqOvQYqi+PXNHg4wCWSYOhXJp87+8niZQKATqrVvyfbREVfVO4CvPwKQuo/2gPLpFfA6MqCn8j2g/AhgKF8B4ipRHUG2mKluswVC1OxPU3hLNihc7VUhShdXzj2nC14urWdgiH3JTrRQncglT+URLxkijJmaFJOuZBVvFIXLzuYiu+wMExsLUDO5jkKtQ6ZM0nQlLk9TZI5hZmsOHHcitXqxDDmncxXilJacWfsbHR0FOjQNSpt0/uJxk9IETmcqj6ahy0BEV6pMGZPIc2a9uLybWukAUdKN2yQbI2d2uBxmnMB4I977Zk32GUwWo1Fcq9tu0mSZjURrtf3ptnzXDmi1u7+YWTX3FxGfoqt8DSDtCAf1uixri+zcatXsPE7vJn79VAL4wyftMz6jOcSdJwBX/gDA+703VAcAnU8g3NweApQdxe1t8LXtrINxawzMEAAUVeGi5upo7SEAcF6dxPaSzXYpBHgUlcIAZtyd1/UyNG5qCq63gHGYopjamVyZKUMow8NcCe1dUemWlgFAbtdGcytILXngauK9UYC5dJUHKBqTsLAm+NrKpXCG1WpngMpL3b8i67os1+YTADc360rf5vkPQ7rZon2nXVAAAAAASUVORK5CYII=";
  string public constant CAT_GOLD =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAHlBMVEU3ZmbWs/X+2Q7/4lj853H864r/8779+NX9/PP8//vaF3CyAAAAAXRSTlMAQObYZgAAAlRJREFUSMftVUGO4kAM5C0ItA9I8gEoC+YK9i65r1acVwxp7gx23zea5LfrTmA1Ghr2A2NFOaQrrnLbXT2ZeADgwmPyKIiEiuoJACIwj2cAegpg4f9kcJFPAVPC9N00PAbMFlN73eUBYFpMwdMpE0oXey8Q2HwT/J4DtHQxmRJ5MQdtZiRAxXyfgcgfArFzcHlPQYD/yjS8sL3PIFC4DiA4meu416DNr2Yx81cAVZkMq72pHlYh2OVQbitkdsKsjwPZNUbirvsAiP1nAPH40xXQvt0At5aB39qPgPYzQNDeALrv1GzmM7M2O3szUKT5SYUPZJNj6KMZCpYfIfxhke3W9wyOuJYcLnY0WyrTSk++6yioFE4plmPJptEpmiD0otoKUeVtAafOjRTmG+XKVFBfwk8BiZRY+5hDylGkde+e4eAZ7OKpeeuL2iQdIwUFcg3m7Xx5j36CeIn52vTkGsYMzPzdTNhHXzVVIbJZhU6BohrbLemjt5pgwauosGCNMaYxuWZwWU4ttLNwFu+4zNR68/kZp7wdGlS3TGtNUgqZU+hiD+jQwkkvbdt7pD6oeY20WUZ5a4H4+KR9xVekQzx6AqSLDwAxXr2hewAYfYKwqx8B2pGirrPLPrMBi8EYRJABNN0xFOnqGOwhAwjR9lr6orjtcgawP6lp4wBKHpADxL17hSvYnUFlFmDNys9k7aaMXIbXFz+avtZ0duZtBnDwayPdCtrrIXM1ydUo4C7dHTIUySQ8fBNib0E5n6Gu07Hvovb3V2Tft624TwC7nXT2r59/AQMDMqrp7GQzAAAAAElFTkSuQmCC";
  string public constant APE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAGFBMVEUAAAA7DwhHEwdaGAhoGwh3Iw2nfibBkCsdplZnAAAAAXRSTlMAQObYZgAAAlhJREFUSMftlMFu2zAMhvMKloz2LFLLzuIvt+dYwnpfugdYW1jnZYD0+qPjYCtmu09QAolh8/Ov3yLFw0EDz3EIydBhLxLSWYzILpDzAICwC4xAdID7YAkMDuP+En5MoyWx+wrnZ2CaPvCQvu8DzEyZxY+IxOA1RAP6h1LZ8qi7kddAGNg8tMo0/BA/8LACJEUcWyWDjC/nvP5UieBja+RjdIOMae0BXp5qu7hwFh6wLphIwrfSXkmYLTYKxl3HmEo0hjsC88ZOAK0u1yWu9XXNvgPKCnDc3t4rtP8Bf1O9Rk91pTCilFs6MhHQ64+1XHNE8RT/dVikRIKTAE+t/Na0pjjOL9i49IJozDiearno45G1qIZnqWUnkwnCyETUJup5JAhGUBTJV8DCOGHTSz6W+pYY1qseBepuhRvBogoJdFfaJWXR28AcKISlcIHJCXGW7nGaXpCi8ZwDkQ2yfIWHFV2xE/+11F+qF1WvI3G4dVfMRm0pk1Cb5rX71a/WNtxMIpF+BcMg3l30fMoJ8GoikbsBfP+TQHNj6WtZe7vnx9eHFxdSfwVaq6W1VljgSDdgzCdtj6LPej58xmfsh6C0ZWpx2QQgbZqvBvdtB6jXhJG6o4ByVfDSymaanJ4rPeXB5YCwBehZonkS6DjkbgMwoM7N48OfWHgDYGdGo6fQI+jA3ARits6RkZP+bwA2zNMnKND1JFsmA50g7EgCkLZMBhg2sWMhM2ID6Jz1ksiy0yFgNwA3D1NY3YugM2kDuLvogFGvx5fHV6xN6pyYytSm2kqp1fz18Acnz6v6AMt3MQAAAABJRU5ErkJggg==";
  string public constant APE_GOLD =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAG1BMVEWjTRz73ET/6UP/8UP+90P//8D9/9v9/+/+//sa9BhIAAAAAXRSTlMAQObYZgAAAlxJREFUSMftlc1q5DAMx/sKkg0zV8mC7tVWDnu1o6V9ku65S2FynXYhfuxVJlkWNpk+QQUmIfmhL1t/Pzy4jTYMeQR+uGdttJGA7gNmQ1KGct+DjQZc4D7QBiNt9S4gzVoAwk9ycHt5sU9yaA5cjoEQApg0qSrALaQdAMLxaZpjCNXbYftSyRL86LOgWBGTfRhuAz/2mWG0JGb7UrNZeuzdHRhIaeM+hyHS89yvQEZBDrqZc+Onqb8RxRi05H2ZAMEukwEiYMF00AnWPi9P3ezWW+r/Gq/a+/8AYP/9KRA3rzeLsA/R0jRtv4cEoBrJ1+XnqJqKUPSOqG5nVMCwaM2qz72/q0phCRJRFWXdauZatMANuLqfiti8Yo+17guMWEtiA4h9bhErJNLKIDmvADJSSRibnab5bWR/ZQaoAEY3oHJcPIxK56lfRyPMRBgrUG7reUCgwsEyPF8u72UUiGjEhMRbFSk25QEonvt8bRqEUgNsoLZ6EAPSQgxWeq/J/QVfXANtSeqtCt/HIqcrsBfNKZKIl7oCjOdXViDx4aRguuTw7f3plajFG9D7PHU3pqXnjavVcumTf4v3J+3LvszPd1mnvAhOh0Aq/fYD07kfA3n1ANtzZ7qJhuR+FMKPPrHfK6rZBVHoCGjG4DqBIXCCQwAAkgOxhhwOgEiwiANJIZQ9wOwDZ0guqNXF4SAH14nKqHmZ7IiHSVauyeUCW9bU9l1wIIFrE/hg++tBCL8Xo9/gIVLOB1fkIgGJA2OClgmOqjhdWwkp4enX9w/eJ+k6cXGZ8DVN8wz69/sfNbmlnl7guAkAAAAASUVORK5CYII";
  string public constant ALIEN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAD1BMVEVzLWlnyeJtzudn3PqA4PnR7JeRAAAAAXRSTlMAQObYZgAAAbNJREFUSMftleuR6zAIhdMCchoQuAEDDTjQf033IN9kkvixM/t7Scbj2J+OJNAhtxvCLLw35ttZGIt1IjoFlFowXygAkEsgOl0DWKGIXi1S2SDRz4FwI3oc7yIR5mFuOWIPhOeSOaXjrWfsd2A2xsZQMtvPv0xqtpot92Cz/U5ksQ4RE5u028FOWLSLZcPoTtz2AHHvjEQ0UaKjgtEzmI8BTMKtvTJi2z4i1/UN6P0H4DcK/gKcxmGaMtfW7rh2mpFWr/xuqcYoTDJXJTxfgQrEBmTV2nRUI4qwGv8GuEf9iFFKXOsXSK9nn4DZmBc6hvvcKcSQ5rQFxydl8J9AaK0WFsKCXFz1C4Aq6wwClVdjBypfwEMFR3vCnlmlxDYFGAKOUOg/5geARnCx4IPvF4BnuGsd52aLbYpWT6jj2D2k1kCNCAlfie7321/8xXk8XR725uxPYHP5m7NPOo3/TgG2Mp6Uyp9+1LOrt1hUU4W346Bn47XH6Avp5fUDIOK/Db24C8AKyHNAfC7oFIDFQ9D7TwG0BRcQ5wBcrU/rf+ZRdWsFuDOWKyAP/4UJfaJ6xXdv+Ad3ppnSV1byKgAAAABJRU5ErkJggg==";
  string public constant ALIEN_GOLD =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAElBMVEUAAAD/64b+7I//76H+99H//fOpxc4dAAAAAXRSTlMAQObYZgAAAb5JREFUSMftlduN6zAMRNMCIacB3woE0gUYJAswTPXfyg7lTW4SPxbY72UCw7GPRhKpYW43hFl4Lcy3szAWq0R0CiiVYL5QACCXQFS6BrBCEb1apLJBop4D4Ua0Hu+iIczD3FqPPRDe5taG5njrLfY7MOtjoyuZ7eefBzVbzOZ7sNl+JzJbhYiJDVrtYCcsWsVawehKXPYAca2MRBRRoqOC0SOYjwFMwqU8M2LbPqItywtQ6w/AbxT8CTj1wzS0tpRyx7XShLR65ndLNUZhkikr4e0ZqEBsQMtam/ZqRBKW418A98gf0UuJa/4C6fnsHTDr80LHcN92CtGludmM49Ok8+9AaK4WFsKCXFz1A4Aq6wQClVdjByofwKqCoz1gz6ySYpsCDAFHKPTXaQVQCC4WfPD9APAMd6Xi3GyxTVHwZBwrjt0quQYqREj4Mo73++0v/uI8Hi4Pe3H2O7C5/MXZJ53Gf6cAWxkPSulPP+rZ2VsssqnC23HQs/Hao/eF5un1AyDi24ae3AVgCbRzQHxK6BSAxUPQ+08BtAUXEOcAXK0P67/nUXVrBbgzliugHf4Lj/9qzV6RvYHof2/4Au0Iyq3lC/iXAAAAAElFTkSuQmCC";
  string public constant DOGE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAOVBMVEUAAGc7LRZhSi6EYS+wgjevj1nHlUTPnEPQnVLfpEzaplPNqmzdqE/Xsm7jv4DwyoXtypf10Zf50ax+6m1uAAAAAXRSTlMAQObYZgAAAvFJREFUWMPtl9uW2jAMRWkaJFtxY4f//9ieIzkktJ3B0Fc0TJZDrB3dbIvLpUuWlFPKOYkk/l9elQxlqHb9twCSNQmVKfo6ACbAiNwB8jJAU1a34W2AKtSpv7i8DEjKNIhcr1eoX5e3gsgouP4rFiB4eK/ik4uUvCCOWZX5TG7SUwBmYb4qtEvJua43ArwYPCjPAXxj0lSYR0u3223NQib0IQOAhImaa62p2Fq31toKPbxbHT0GgP5a27ZOP27QXxcWNdM6Asg0oNZl+bUs9ecEdQwYWeqngSAmriDPfMgvXlCUKaI7YAGqn4A7wfX7skyDq9IgjN6prF2sy/G9CKZtbwMEhC8B0zZtzwGSt7b9BwAmnOeFcjETMd9I5hnlXESKB/TqYwkW8sIISOENqldOgGIoXd9EFgdA2oJqquY4PorHXHEBSKcNx2DCbNqnwBpOWde6rFU5pgmuyou5vj7sWCXcVDHaV/iZFRYAYD6+vxy3d4Admy6stNwB0j0wFDTEXQjfe0BDXwk7A7CSweCLwutiFT6sq4/dAbhYGCx8gMJH7C8L4L2JT5sFgCWCOHsSjH/MliEbbkmxhxhkPiPAnzELjGENd/h6PMK8wnT/WRssojI7wBi0okiltso0+jh83y8ldwMeXfAYGlMYABKww6iPfXpEgD51VDkAjcujOVm7B6r8UjV8uBMK5oUtrR2AbZsm1DeWSEhUX2Rrz6qHBTK1iYvW5fKRj3zkI2/1C9hhtlc2EQK4RR0A0fYyAPvXqbHQf/YF37qAjfLoC0TO90+VsT1L7KUYKtvgOKB5Hfjd4A2H9APBN2g/IDUahVFAP0pK6Wej0Qw2DM8BtN9yjtPg1Czx8NIhAO12QJzmO0F5Po26kAmwA+AHIxGqYwCc+BFD6y0aj3eHjFmgiMF+zDqA/VNP61AdUKXsUcTt7s9DZ/IdQPArtERH4X3DXPakjgKan+J+0kc/sLVofdpzAHsELiQ0DS7eDLCB+KIv+A3z8j1xfknTpQAAAABJRU5ErkJggg==";
  string public constant DOGE_GOLD =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAJ1BMVEUAAAAAAAANDAB+aQD73T3+5m3964L87JD88KH/87z+9cb8+t/8//sh9bMDAAAAAXRSTlMAQObYZgAAAndJREFUSMftlcFuo0AMhvMsPecxeknvhk601xkJ1CsibPfakES9QvCUY8qurbxANresVInsPNR6krTaCmhfoBbSIPPF/DPYf0YjiSJLMQmTcDQUawxTSOEDQOUhAASDAGYZCgCDQF6p/ENgscwTYOZBYBau4fqGJx+IzLJrZOwXmMLDrZ0+IS7SJMmSDhBW+eKZqXa4CJPbKu0ACvOc1vjDtWqRLHHdrbCsave9ds7hLF1i3gOgPDyMnduFs+WyC1T4+Pdp92fs9rieVeuuyCS93032iPsdPiTZoisS4R43+JsQqzQJ074viiLCr0YCJU73cM4NAoF+B4zHHUB9AoA55yQsggW4/rXiDe5vVhwYE2kDU2NUcQZoqgE2PyO7rds2sgEE0nwQGxOeGwhpYiRj5/bO1S9zCyYArVVjzKXD5ABKBQ2V8V1dt2Us5XRQkgfKE8BEAkwZjXywFo28X6RaERxcAGYsQHHqgWMqeWWILZkyUm8VUAUkFdpWKhhTlhZVHKGliwYqUClE3rbuiFyUuiAL9vVERmgnBWLMpeyiPcqPUS6SDn5tYiZMEKdcrRrnXqoVMYoEuxHKnoCtSEOMbLWaO2cEsGQt+9z2eALc1VjazTn2h6xlT8Ts3Dk3+oqvGI5XG9BmoFXegGAQOBxO3mA+AQDOa+fxvGArI2qetQ607gAGQQAqjGm00dAL+IlhmU2MA910gChSfiRkeCMxjLIHwMAScemdrCTb9wrlZ1aAWAyBTB9gZXAFaAoiKnqASCR6DQR+uz3n4J2Hm6hk8ZaLu7wHAk0WxUxuPNgHfBOn4GfxBbGCbdsB5G/pcOVNQdb/veEfCqS+LlEIo/sAAAAASUVORK5CYII=";

  // Front view
  string public constant FRONT_MOUSE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAHlBMVEUAAAD3ocW1t7T/0ODCxMGoqqebnZnP0c7y9PD6uNUYO1c3AAAAAXRSTlMAQObYZgAAAK5JREFUGNNVjjEOwyAMRX2FqDewEMwdWS0rdK7UC6Ak7ChKOlcZvDPltgWTDvX09OD7GwAGxAHa3JjvCoaZ/+GJjB2ISGEm7GZGhQXt8npiBOTAO7OFGJxIXi0YCiKrIzD5IXIYrPAW+VQTSU2G2MzhMiRqwNW0VDZ1z4k1flooZTE0el/b4r5bbXfr1IFagd78A9zcqBA31/+knMbrKXSDlLYrde0xPPW496UAfAHzjTeL5IzRoQAAAABJRU5ErkJggg==";
  string public constant FRONT_FROG =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAHlBMVEUAAABEpFNLy2Q+uFVNsmCK+Xuu+YeV9mJ565I7lEplCHFxAAAAAXRSTlMAQObYZgAAAKtJREFUGNM1z8ENwyAMBVCvYHAGwGQBQ5Q7bSJ1gfTeSLVy7RIZoBMXcMPp6WP0DQAgM0I7OXHu8BGlI6766QhPVYP+MVzJwxLyg75VCEqFqhTAvDZQvVrrcMaWNBBIas8j1qZhqxDIXJPXKJBYKjxCCnlTlyKw+gFFA5znV7wcR227Fxp7OzPZ8jHQrWMRP3UkcZbE7BZDoekaTjYcvX3ZBWfJvM97x3G2ph+xUif8/19AxAAAAABJRU5ErkJggg==";
  string public constant FRONT_CAT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAHlBMVEUAAADfhAb3s136vXL68erykxLxu87w38bme6L3697kvRXPAAAAAXRSTlMAQObYZgAAALlJREFUGNM1j0EKwkAMRXOFgidICtXtRJAu1dIyF/AGLrqthWG2HkEGP7mt05n6V4/3E0KIqGHX0JaD8rXAg+VZQES4ALOTAo65mnB8hwJYuriN8snsk0uWS4w3x6TSYRVRctoCdxFSPSMu2lPQ1uDOgbC2U5LgycMBNwyUElsU72mw3uInZTOcYJY8fUcz2Dznax6Gcn1IeXmLhZgKJMS1GuzGTztIeLX1i8uyv6PqaqVajf7NmEP0Az2IOx+h0qlJAAAAAElFTkSuQmCC";
  string public constant FRONT_APE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAFVBMVEUAAABoGwhHEwdaGAinfibBkCs7DwicKfTcAAAAAXRSTlMAQObYZgAAAK1JREFUGNMtz01ywzAIBWCu0B8fwA9Xe4tE+7qiB3Ch+ypO7n+EKsJs+GYeM8wjohfOMz3nosYBP7G44YQHJvN94F39a0Cqrn2twrVKSfSHyfUHTI0n051nEsArZiGURe2zZeJyqO8dwLXWDR35Q+2XnxDzV07EvB5769FlY2ReNlKVBFHt3wCk8f0NkIGcW6AVjqilE5xvZQAJgVtugYZH3KCkKHj/PqKgqVWif1kQJtsU7kIuAAAAAElFTkSuQmCC";
  string public constant FRONT_ALIEN =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAD1BMVEUAAABn3PqA4PlnyeJtzuejFreRAAAAAXRSTlMAQObYZgAAAIJJREFUGNOVjssVAkEIBDsFkATomQTUTYDZzj8m2dGL3qwDr3h8AZin4eJG3rew2WI27CP2ljIeW2ShLc/mmvFxHI+eY9KdzJZkOh3eeWY6jOa9yFHcXQvlYaZKyKlY1SWbUaWCaq5ZEqSOIWKMWbHG6Gsp/TyW3nu3NP9LNN9yNsALJUcY7sDqAgYAAAAASUVORK5CYII=";
  string public constant FRONT_DOGE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAMAAAAsVwj+AAAAM1BMVEUAAADIlUPPm0Leo0veqU/WsnTxyoTQnVHaplPzy5rjv4BhTC48LBXLqm+vkFnmqUqugja3Zpx/AAAAAXRSTlMAQObYZgAAANxJREFUKM9Vj1l2xSAMQ/EQR0CJs//VVn5thqePBN+DJdQaJWoublu7xMndLB5gthv2foOI3THiATz3MX8esLZtxZwPOIpQz41jre0CIswssB3uokKg7n2NsQKuBeo3RqwRCgWaF+ANgprRakYfJah+gAPBnTGcbqCHJsEq01RUCtJ7eYYnRBrgqT0q1tP/PE4nCcae5dF7r1xK1flts88u+pHwOP/7IFEJlySVHV/g5BsJcANWUG7lDbKA2gskTMzs+wbwtSL69jgLsPQrham66w1YIaV6XKo+V49fUFgJhmcLhjkAAAAASUVORK5CYII=";

  string public constant FRONT_MOUSE_GOLD =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAIVBMVEUAAAD/6Xv+9s//7pn/5GH/30L/8rP//O3//vv/8KT+9s1LjXuuAAAAAXRSTlMAQObYZgAAALVJREFUGNNVjjEOwyAMRX0FF8HeI1hWUNZIvQBKwo5Q0u4ZmrVTuEK4AbcsATrU09PHzx8AwDxwzY35XkAw8z8MyHVnIKICEzVrqvqMcn4MaABZ88oswWi1v52XIEiH4BWBcP2xbwIzvI7wyYmhPoRNODDuFY5NObD0zAnn5LKcyHdO3Hd/SohxFtSllNvMusrSrvxYga6C8ucf4KK6AmZRdcc627UnXRMkuzSr3RE8Vj2lGAG+jVgvhr3EkdsAAAAASUVORK5CYII=";
  string public constant FRONT_FROG_GOLD =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAHlBMVEUAAADw0Cf95Fr+3TL/4Eb+9cX899T/8a7hwyXPtCT2V0zAAAAAAXRSTlMAQObYZgAAAKRJREFUGNM1z9ERgzAIBmBWQMwASSYgqO1r6wz2Xe+KGzhIJy4hMU/fwc9BAABTQqhPprc4KCM71ll3R/yoOl7aEe7Ko1WIgn6VCdigygwocwVZa7awICA7LDPV8Yy2KWwGBklW2Q0lsYEQSpRNh5IhKQV8aoTr+jHxedZThbJvT4nazTlSab9gmhyFh1bJMvQMj3d4bK019/Eh9vByLIfjvOqmP4ELJ1XM0kwpAAAAAElFTkSuQmCC";
  string public constant FRONT_CAT_GOLD =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAGFBMVEUAAAD+2Q7853H864r9+NX9/PP8//v/877neKqBAAAAAXRSTlMAQObYZgAAALRJREFUGNM1j0ESgjAMRXMF1AuYAHsbwbXYwh6TugfKAZzh/pYW/+rN+8lkAgAFmgL2XBifCc5ItwREhAkQDSUwiNnY68kmkK50+yhWqmMske7OTQaBqZSeiMFwLTITAXP7cV9uwHKtH9NakL5ePNkAQYzIJCt4j+ooBFi1UTf6aNZKVH2A96wq2jTxWhCVdH31cXmPDs4n8LL12ciWTVgOoOFV5y8e3fEOs8kVczb8N3MMwA/sISy7wemIKAAAAABJRU5ErkJggg==";
  string public constant FRONT_APE_GOLD =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAG1BMVEUAAAD+90P/6UP9/+/+//v73ET//8D/8UP9/9uzqmsUAAAAAXRSTlMAQObYZgAAAK5JREFUGNM1z1EOwjAIBmCusDr0uTWNz1p2AWEHgI14jyXGA3hxu67y0i9/IQQAGGKIsNeJWBvOwkdyFU4dYg0jy9yb5d4wFBrqEzct38s7g9oo8rQX+I7ZFJKrcIgbOC7Ed0NQXKl+BUh5LOVZYWEVnmNNcBNBzRBjXGb3AKcpeX4tDyC6uX+I6jZ3y8d2q8N7JeywfbghdygqNni2Axrsn3hvxo51Wo4DmbgA/ACHzic41uzVBwAAAABJRU5ErkJggg==";
  string public constant FRONT_ALIEN_GOLD =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAD1BMVEUAAAD+99H//fP/64b/76E/c53eAAAAAXRSTlMAQObYZgAAAIJJREFUGNOVjssVAkEIBDsFkATomQTUTYDZzj8m2dGL3qwDr3h8AZin4eJG3rew2WI27CP2ljIeW2ShLc/mmvFxHI+eY9KdzJZkOh3eeWY6jOa9yFHcXQvlYaZKyKlY1SWbUaWCaq5ZEqSOIWKMWbHG6Gsp/TyW3nu3NP9LNN9yNsALJUcY7sDqAgYAAAAASUVORK5CYII=";
  string public constant FRONT_DOGE_GOLD =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAJFBMVEUAAAD+5m388KH/87z+9cb8+t/8//v87JANDAB+aQD73T3964LSVpU9AAAAAXRSTlMAQObYZgAAAMhJREFUGNMtzzGOwyAQBdC5AouVxkfYyhrCFq6iQS5MuckJQCOvUq0U5QhcxLkAiuWGyy1mloan0UefAYAP053hOBdHtoG+8NnAD8sCXlLD+ftHsN4QG2a8Ur1UN+PtdcmgtsmG4DNov7O9jwjkd2vDG8EUyxxKBVXEjUBvNRv8AMpMgSMpQLdziK5mZs98fxFwLMxlYkipLyUvy9FmPofW3mUlWIuS/+ConWwx9qbBocb/iZYJDW/JrEMhefXbZ9k0nmTllI6mPyFUO1tjRrmRAAAAAElFTkSuQmCC";

  constructor() {
    _tiers = [
      2500,
      4500,
      6500,
      8000,
      9140,
      9940,
      9950,
      9960,
      9970,
      9980,
      9990,
      10000
    ];
  }

  function getName(uint256 traitIndex)
    public
    pure
    override
    returns (string memory name)
  {
    if (traitIndex == 0) {
      return "Frog";
    } else if (traitIndex == 1) {
      return "Mouse";
    } else if (traitIndex == 2) {
      return "Ape";
    } else if (traitIndex == 3) {
      return "Cat";
    } else if (traitIndex == 4) {
      return "Alien";
    } else if (traitIndex == 5) {
      return "Doge";
    } else if (traitIndex == 6) {
      return "Frog Gold";
    } else if (traitIndex == 7) {
      return "Mouse Gold";
    } else if (traitIndex == 8) {
      return "Ape Gold";
    } else if (traitIndex == 9) {
      return "Cat Gold";
    } else if (traitIndex == 10) {
      return "Alien Gold";
    } else if (traitIndex == 11) {
      return "Doge Gold";
    }
  }

  function _getLayer(
    uint256 traitIndex,
    uint256,
    string memory prefix
  ) internal view override returns (string memory layer) {
    if (traitIndex == 0) {
      return _layer(prefix, "FROG");
    } else if (traitIndex == 1) {
      return _layer(prefix, "MOUSE");
    } else if (traitIndex == 2) {
      return _layer(prefix, "APE");
    } else if (traitIndex == 3) {
      return _layer(prefix, "CAT");
    } else if (traitIndex == 4) {
      return _layer(prefix, "ALIEN");
    } else if (traitIndex == 5) {
      return _layer(prefix, "DOGE");
    } else if (traitIndex == 6) {
      return _layer(prefix, "FROG_GOLD");
    } else if (traitIndex == 7) {
      return _layer(prefix, "MOUSE_GOLD");
    } else if (traitIndex == 8) {
      return _layer(prefix, "APE_GOLD");
    } else if (traitIndex == 9) {
      return _layer(prefix, "CAT_GOLD");
    } else if (traitIndex == 10) {
      return _layer(prefix, "ALIEN_GOLD");
    } else if (traitIndex == 11) {
      return _layer(prefix, "DOGE_GOLD");
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Trait.sol";

contract Eyes is Trait {
  // Skin view
  // Mouse: 0
  string public constant MOUSE_RIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVlLWckJCScnJzx8fGYJxp/AAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBhCgIsLTYCXl2EUjIJRMGAAAKbZAC/5M7/QAAAAAElFTkSuQmCC";
  string public constant MOUSE_LEFT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVlLWckJCScnJzx8fGYJxp/AAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBhCgIsLTYCdnWEUjIJRMGAAAHzHACMa7IPxAAAAAElFTkSuQmCC";
  string public constant MOUSE_CROSSED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVlLWckJCScnJzx8fGYJxp/AAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBhCgIsLTYCdl2EUjIJRMGAAAJHNACkBjKxHAAAAAElFTkSuQmCC";
  string public constant MOUSE_3D =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEUAAAD8RkZGw/zx8fFFHVXFAAAAAXRSTlMAQObYZgAAACJJREFUOMtjYBi8wP7/ART+/19f/6Op4D/AMApGwSgYKAAA+5EG+o56Gh4AAAAASUVORK5CYII=";
  string public constant MOUSE_LASER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAAE/5Pz/+hoZe3CQjAAAAAXRSTlMAQObYZgAAABtJREFUOMtjYBhCgIMDTUBNjZCKUTAKRgHtAAB+8QBtvTcAMwAAAABJRU5ErkJggg==";
  string public constant MOUSE_SUN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEUAAAAkJCRXyFKEAAAAAXRSTlMAQObYZgAAABdJREFUKM9jYKAZ4P//AcoyZhgFwxQAACR0AjJvfSwqAAAAAElFTkSuQmCC";

  // Frog: 1
  string public constant FROG_RIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVlLWcAAABCpkz///+XoPGRAAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBg0YAEXmsAFXoZRMApGwSAGAJ86AYhDlf2iAAAAAElFTkSuQmCC";
  string public constant FROG_LEFT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEUAAAAAAABCpkz///9ZYjdQAAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBg0YAEXmkABO8MoGAWjYBADACvZASKoINImAAAAAElFTkSuQmCC";
  string public constant FROG_CROSSED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVhYmwAAABCpkz///8p9twwAAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBg0YAEXmkABL8MoGAWjYBADAEGrASg0BSMWAAAAAElFTkSuQmCC";
  string public constant FROG_CLOSED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAAAQujUVCpkxbHzrDAAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBg0YAEXmkAAK8MoGAWjYBADALAEAQBNGbSAAAAAAElFTkSuQmCC";
  string public constant FROG_LASER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVHAOPfNB7fbmA8zv7oAAAAAXRSTlMAQObYZgAAABtJREFUOMtjYBg0QIEDTWCGGiEVo2AUjIKBBADbLwEPsGTK8wAAAABJRU5ErkJggg==";
  string public constant FROG_SUN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVrdEccEwC5FntbAAAAAXRSTlMAQObYZgAAABdJREFUKM9jYKA24P//Acp6zjAKhjsAAIyMAubQmKY3AAAAAElFTkSuQmCC";

  // Cats: 2
  string public constant CAT_RIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEV0ADMICAjW4cj17uQ4AAAAAXRSTlMAQObYZgAAABZJREFUOMtjYBjeQEWFYRSMglFAIwAA9xwASXm4vVAAAAAASUVORK5CYII=";
  string public constant CAT_LEFT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAAAIICAjW4chWtdgHAAAAAXRSTlMAQObYZgAAABZJREFUOMtjYBjeQEKCYRSMglFAIwAApigAMYl5xA8AAAAASUVORK5CYII=";
  string public constant CAT_CROSSED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAAOQICAjW4cg2xUsqAAAAAXRSTlMAQObYZgAAABZJREFUOMtjYBjeQEWCYRSMglFAIwAAzqgAPQRpQ1IAAAAASUVORK5CYII=";
  string public constant CAT_CLOSED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVzADHzkhJnCg09AAAAAXRSTlMAQObYZgAAABJJREFUKM9jYBgQkMYwCoYFAAC4VgBnaf6kIQAAAABJRU5ErkJggg==";
  string public constant CAT_3D =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVlLWfiYGBgt+L///9ibcCbAAAAAXRSTlMAQObYZgAAAB5JREFUOMtjYBhW4P9/NP7r62gif+wZRsEoGAXUAQCX2Ab61dcG7QAAAABJRU5ErkJggg==";
  string public constant CAT_LASER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVHAMzzUjr4koPwf4VCAAAAAXRSTlMAQObYZgAAABtJREFUOMtjYBhWQIEDTWCGGiEVo2AUjAJyAQCTdwEPtoqJgAAAAABJRU5ErkJggg==";
  string public constant CAT_SUN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEUAAAAICAhtdupNAAAAAXRSTlMAQObYZgAAABdJREFUKM9jYKAj4P//AcpKYxgFwwIAAFgNAmXWxHedAAAAAElFTkSuQmCC";

  // Ape: 3
  string public constant APE_RIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEV7+wMAAACSayD///8/JDF/AAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBhCQGMBmoDJBYZRMApGwYABAF4KAc2JOLBoAAAAAElFTkSuQmCC";
  string public constant APE_LEFT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVlLWcAAACSayD////l64lvAAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBhCQGMBmoBMAcMoGAWjYMAAALlcAVV93WgeAAAAAElFTkSuQmCC";
  string public constant APE_CROSSED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVhYmwAAACSayD///9bvaTOAAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBhCQGMBmoDMBYZRMApGwYABAAnaAbU/MvXGAAAAAElFTkSuQmCC";
  string public constant APE_CLOSED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAAEqCXhuSayBzqykqAAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBhCQGMBmoBIAMMoGAWjYMAAAC0sAS1SowumAAAAAElFTkSuQmCC";
  string public constant APE_3D =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVlLWffNB5PoNv//PdcxyH/AAAAAXRSTlMAQObYZgAAAB5JREFUOMtjYBg64D8QoIpcX4Ou5A/DKBgFo4BeAABeJQd7/5unYgAAAABJRU5ErkJggg==";
  string public constant APE_LASER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVwAMPfNB/fb2FvgwzdAAAAAXRSTlMAQObYZgAAABtJREFUOMtjYBhCQEEBTWDGDEIqRsEoGAW0AwDvEwGxXm8ZoQAAAABJRU5ErkJggg==";
  string public constant APE_SUN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVqZWMoHACkYH8mAAAAAXRSTlMAQObYZgAAABdJREFUKM9jYKAZ4P//AcrKYRgFwxQAAI43AmtGeoLrAAAAAElFTkSuQmCC";

  // Alien: 4
  string public constant ALIEN_RIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAAOoJDAdnzujtq9nGAAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBjKQEUFTUBCgmEUjIJRQC8AAKXTAHkKAFKsAAAAAElFTkSuQmCC";
  string public constant ALIEN_LEFT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAAKoICAhsyOJ1xWj1AAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBjKQEICTUBFhWEUjIJRQC8AAKQ7AHlAkZAkAAAAAElFTkSuQmCC";
  string public constant ALIEN_CROSSED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVwANQICAhsyOI5MQBWAAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBjKQEIFTUBFgmEUjIJRQC8AAKUHAHlRv0sRAAAAAElFTkSuQmCC";
  string public constant ALIEN_CLOSED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVHAM5BuNpWwN7KSNqmAAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBjKQEMDTUBEhGEUjIJRQC8AAKZbAHm+C5+oAAAAAElFTkSuQmCC";
  string public constant ALIEN_3D =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVlLWfiR0xHx+L8/v9h5aJlAAAAAXRSTlMAQObYZgAAAB5JREFUOMtjYBhC4P9/NP7112gif+wZRsEoGAX0AgCE5Qb6uWgeRgAAAABJRU5ErkJggg==";
  string public constant ALIEN_LASER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAAFzeVmXmgYyfcOAVAAAAAXRSTlMAQObYZgAAACJJREFUOMtjYBhCgIMDTUBNDU1gxgw0AQUFhlEwCkYBjQAANawBzdOo8sAAAAAASUVORK5CYII=";
  string public constant ALIEN_SUN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVya3UICAiZn1B1AAAAAXRSTlMAQObYZgAAABdJREFUKM9jYKA94P//AcpKYxgFwwsAAG2RAmVHLjXYAAAAAElFTkSuQmCC";

  // Doge: 5
  string public constant DOGE_RIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAANUVEQ7///+UYrkZAAAAAXRSTlMAQObYZgAAABZJREFUOMtjYBjEQIUAfxSMglEwoAAAB+cASbvRsD4AAAAASUVORK5CYII=";
  string public constant DOGE_LEFT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAAH0VEQ7////gJiQQAAAAAXRSTlMAQObYZgAAABZJREFUOMtjYBjEQIIAfxSMglEwoAAAsVAAMYYGv/kAAAAASUVORK5CYII=";
  string public constant DOGE_CROSSED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEV0AFEVEQ7///9FdOUhAAAAAXRSTlMAQObYZgAAABhJREFUOMtjYBjEQAKNr8IwCkbBKBhEAADcNAA9lvR/RAAAAABJRU5ErkJggg==";
  string public constant DOGE_CLOSED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEUAAACfdzgbVBGtAAAAAXRSTlMAQObYZgAAABRJREFUKM9jYKA6YIMxEhhGwXAHAMNOAGfViymQAAAAAElFTkSuQmCC";
  string public constant DOGE_3D =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVx+wP/AABBquz8/v/7RaQZAAAAAXRSTlMAQObYZgAAAB9JREFUOMtjYBi04D8QoIpcf42m5I89wygYBaNgwAAAHVsG+hdSEVQAAAAASUVORK5CYII=";
  string public constant DOGE_LASER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAABz/QUH/cnKceMWeAAAAAXRSTlMAQObYZgAAAB1JREFUOMtjYBg8QAGdPwNNYIYCAR2jYBSMAnoCABoqAbGPkLppAAAAAElFTkSuQmCC";
  string public constant DOGE_SUN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVya3UfGhWbBPmKAAAAAXRSTlMAQObYZgAAABdJREFUKM9jYKA24P//AcpKYxgFwx0AAJiZAmUBXFhvAAAAAElFTkSuQmCC";

  // Front view
  // Mouse: 0
  string public constant FRONT_MOUSE_RIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAAAAAA+4qcQAAAAAnRSTlMAAHaTzTgAAAAYSURBVCjPY2AgEsyZA8Fw8FEFgkfBcAYA3bAEmxgUpywAAAAASUVORK5CYII=";
  string public constant FRONT_MOUSE_LEFT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAAAAAA+4qcQAAAAAnRSTlMAAHaTzTgAAAAYSURBVCjPY2AgEsyZA8FwoPIRgkfBcAYA3BYEm2WQB0sAAAAASUVORK5CYII=";
  string public constant FRONT_MOUSE_CROSSED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAAAAAA+4qcQAAAAAnRSTlMAAHaTzTgAAAAdSURBVCjPY2AgEsyZA8FwoPKRgeGjCrHaR8HQBADc4wSbx3hv2QAAAABJRU5ErkJggg==";
  string public constant FRONT_MOUSE_3D =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAADx8fFGw/z8RkZ76pEBAAAAAXRSTlMAQObYZgAAABdJREFUCNdjYAAD0VAgERUPYrEyDCYAALi7AT4MkX99AAAAAElFTkSuQmCC";
  string public constant FRONT_MOUSE_LASER =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAAD+hob5Pz8OwnIiAAAAAXRSTlMAQObYZgAAABVJREFUCNdjYEAAFhYgISkJYw0KAAAlXQBDsjfRKgAAAABJRU5ErkJggg==";
  string public constant FRONT_MOUSE_SUN =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAAAAAA+4qcQAAAAAnRSTlMAAHaTzTgAAAAeSURBVCjPY2AgBBgZGBgYVKCcOwhxFRUIHgXDGQAABmMBkrRf8jEAAAAASUVORK5CYII=";

  // Frog: 1
  string public constant FRONT_FROG_RIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAABCpkz///8AAADaoYegAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYAhgZWBg2MDNMDgBAKTJARGvt+qEAAAAAElFTkSuQmCC";
  string public constant FRONT_FROG_LEFT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAABCpkwAAAD///8qussDAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYAhgZWBg2MDNMDgBAKTJARGvt+qEAAAAAElFTkSuQmCC";
  string public constant FRONT_FROG_CROSSED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAABCpkwAAAD///8qussDAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYAhgZWBg2MDHMDgBAKaRARSCVSMWAAAAAElFTkSuQmCC";
  string public constant FRONT_FROG_CLOSED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAABCpkwujUVVHvfnAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYAhgZWBgWMDFMDgBAJqhAQBfDkj7AAAAAElFTkSuQmCC";
  string public constant FRONT_FROG_LASER =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAADfbmDfNB6638WMAAAAAXRSTlMAQObYZgAAABZJREFUCNdjYBBgYWBgSJEEEmDWIAMAYxwApt1kpUkAAAAASUVORK5CYII=";
  string public constant FRONT_FROG_SUN =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAQMAAAAhR2qPAAAABlBMVEUAAAAcEwDRtKJJAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYGBg4P/AwFfAQBsAAIZyAX7ot6HTAAAAAElFTkSuQmCC";

  // Cats: 2
  string public constant FRONT_CAT_RIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAADW4cgICAgpWG32AAAAAXRSTlMAQObYZgAAABFJREFUCNdjYMAJJCQYBh4AABl4ADERYRJzAAAAAElFTkSuQmCC";
  string public constant FRONT_CAT_LEFT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAAAICAjW4cjBKskuAAAAAXRSTlMAQObYZgAAABFJREFUCNdjYMAJJCQYBh4AABl4ADERYRJzAAAAAElFTkSuQmCC";
  string public constant FRONT_CAT_CROSSED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAADW4cgICAgpWG32AAAAAXRSTlMAQObYZgAAABFJREFUCNdjYMAJJFQYBh4AAB+oAD1GfLEsAAAAAElFTkSuQmCC";
  string public constant FRONT_CAT_CLOSED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAQMAAAAhR2qPAAAABlBMVEUAAADzkhKiK+2WAAAAAXRSTlMAQObYZgAAABBJREFUCNdjYEAFbAkMVAUAH+AAZ1iIvc8AAAAASUVORK5CYII=";
  string public constant FRONT_CAT_3D =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAAD///9gt+LiYGCclyvXAAAAAXRSTlMAQObYZgAAABhJREFUCNdjYMAGQkOBRGYtkAgRZRhQAAAHagH68ks+IQAAAABJRU5ErkJggg==";
  string public constant FRONT_CAT_LASER =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAAD4koPzUjrXizT8AAAAAXRSTlMAQObYZgAAABVJREFUCNdjYMAGBFiARIokjDWAAABWOACmNAJ9WgAAAABJRU5ErkJggg==";
  string public constant FRONT_CAT_SUN =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAAAAAA+4qcQAAAAAnRSTlMAAHaTzTgAAAAeSURBVCjPY2CgHDAyMDAwcEA5P+DCHBwQPAqGMAAAC6oBIm0YoIMAAAAASUVORK5CYII=";

  // Ape: 3
  string public constant FRONT_APE_RIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAACSayD///8AAABjE7LuAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYEAAkQAgobOBYTABALRUAUE6qUrJAAAAAElFTkSuQmCC";
  string public constant FRONT_APE_LEFT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAACSayAAAAD///+TCP5NAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYEAAkQAgobOBYTABALRUAUE6qUrJAAAAAElFTkSuQmCC";
  string public constant FRONT_APE_CROSSED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAACSayAAAAD///+TCP5NAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYEAAkQAgofOAYTABAM70AXFIS3QeAAAAAElFTkSuQmCC";
  string public constant FRONT_APE_CLOSED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAACSayCCXhvR8cEyAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYEAAkQAgobGAYTABAKk4AS2OnR7CAAAAAElFTkSuQmCC";
  string public constant FRONT_APE_3D =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAAD//PffNB5PoNu2dNPXAAAAAXRSTlMAQObYZgAAABdJREFUCNdjYECA0FAgkfkFxAphGCQAAH9nArGt+abTAAAAAElFTkSuQmCC";
  string public constant FRONT_APE_LASER =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAADfb2HfNB9IBLvPAAAAAXRSTlMAQObYZgAAABVJREFUCNdjYEAAAQEgkZICYw0KAACTlAEJt/qpQQAAAABJRU5ErkJggg==";
  string public constant FRONT_APE_SUN =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAQMAAAAhR2qPAAAABlBMVEUAAAAoHAB1TvPKAAAAAXRSTlMAQObYZgAAABNJREFUCNdjYAAD/g8MbAcYaAAAmdsBxjfxqA8AAAAASUVORK5CYII=";

  // Alien: 4
  string public constant FRONT_ALIEN_RIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAABnzugJDAfufAhvAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYEADEhJAQkWFYZAAAEIEAHmk+RO7AAAAAElFTkSuQmCC";
  string public constant FRONT_ALIEN_LEFT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAAAICAhsyOKWHuTVAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYEADEhJAQkWFYZAAAEIEAHmk+RO7AAAAAElFTkSuQmCC";
  string public constant FRONT_ALIEN_CROSSED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAAAICAhsyOKWHuTVAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYEADEipAQkWCYZAAAEJAAHnqcWUsAAAAAElFTkSuQmCC";
  string public constant FRONT_ALIEN_CLOSED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAABWwN5BuNpNaNzWAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYEADIiJAQkODYZAAAEHcAHnnfXiLAAAAAElFTkSuQmCC";
  string public constant FRONT_ALIEN_3D =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAAD8/v/iR0xHx+LiC8udAAAAAXRSTlMAQObYZgAAABhJREFUCNdjYECA0FAgkVkLJEJEGQYJAAAbJAH6EljucAAAAABJRU5ErkJggg==";
  string public constant FRONT_ALIEN_LASER =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAADmgYzeVmU+WfbBAAAAAXRSTlMAQObYZgAAABtJREFUCNdjYEAAFhYgISkJJFJSgISAAMPAAwCdDQEjJ/SyKQAAAABJRU5ErkJggg==";
  string public constant FRONT_ALIEN_SUN =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAAAAAA+4qcQAAAAAnRSTlMAAHaTzTgAAAAeSURBVCjPY2AgGTAyMDAwcEA5P+DCHBwQPAqGEwAAHtsBIq1KNLoAAAAASUVORK5CYII=";

  // Doge: 5
  string public constant FRONT_DOGE_RIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAAD///8VEQ7dSuz9AAAAAXRSTlMAQObYZgAAABBJREFUCNdjYIAACSgebAAAHMAAMYYQwVYAAAAASUVORK5CYII=";
  string public constant FRONT_DOGE_LEFT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAAAVEQ7///9tmZX7AAAAAXRSTlMAQObYZgAAABBJREFUCNdjYIAACSgebAAAHMAAMYYQwVYAAAAASUVORK5CYII=";
  string public constant FRONT_DOGE_CROSSED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAAAVEQ7///9tmZX7AAAAAXRSTlMAQObYZgAAABJJREFUCNdjYIAACSBWYRh8AAAjsAA9lDVa0QAAAABJRU5ErkJggg==";
  string public constant FRONT_DOGE_CLOSED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAQMAAAAhR2qPAAAABlBMVEUAAACfdzgbVBGtAAAAAXRSTlMAQObYZgAAABFJREFUCNdjYACCBAY2BhoBACSWAGeG8raLAAAAAElFTkSuQmCC";
  string public constant FRONT_DOGE_3D =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAAD8/v//AABBquxVNP1bAAAAAXRSTlMAQObYZgAAABhJREFUCNdjYACD0FAgkVkLJEJEGQYTAAAlAQH6aSoA1gAAAABJRU5ErkJggg==";
  string public constant FRONT_DOGE_LASER =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAAD/cnL/QUFzoqIbAAAAAXRSTlMAQObYZgAAABdJREFUCNdjYGAQYADiFCCRAmYxDCoAAJtQAQnk4ZJQAAAAAElFTkSuQmCC";
  string public constant FRONT_DOGE_SUN =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAQMAAAAhR2qPAAAABlBMVEUAAAAfGhVv7UOyAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYGBg4P/AwJbAQBsAAH4qAWZN2x1aAAAAAElFTkSuQmCC";

  constructor() {
    _tiers = [3100, 6100, 8100, 9300, 9800, 9900, 10000];
  }

  function getName(uint256 traitIndex)
    public
    pure
    override
    returns (string memory name)
  {
    if (traitIndex == 0) {
      return "Right";
    } else if (traitIndex == 1) {
      return "Left";
    } else if (traitIndex == 2) {
      return "Crossed";
    } else if (traitIndex == 3) {
      return "Sun"; 
    } else if (traitIndex == 4) {
      return "Closed";
    } else if (traitIndex == 5) {
      return "3D";
    } else if (traitIndex == 6) {
      return "Laser";
    }
  }

  function _getLayer(
    uint256 traitIndex,
    uint256 layerIndex,
    string memory prefix
  ) internal view override returns (string memory layer) {
    if (traitIndex == 0) {
      return _indexedLayer(layerIndex, prefix, "RIGHT");
    } else if (traitIndex == 1) {
      return _indexedLayer(layerIndex, prefix, "LEFT");
    } else if (traitIndex == 2) {
      return _indexedLayer(layerIndex, prefix, "CROSSED");
    } else if (traitIndex == 3) {
      return _indexedLayer(layerIndex, prefix, "SUN");
    } else if (traitIndex == 4) {
      return _indexedLayer(layerIndex, prefix, "CLOSED");
    } else if (traitIndex == 5) {
      return _indexedLayer(layerIndex, prefix, "3D");
    } else if (traitIndex == 6) {
      return _indexedLayer(layerIndex, prefix, "LASER");
    }
  }

  function _getLayerPrefix(uint256 layerIndex)
    internal
    pure
    override
    returns (string memory prefix)
  {
    if (layerIndex == 0) {
      return "FROG_";
    } else if (layerIndex == 1) {
      return "MOUSE_";
    } else if (layerIndex == 2) {
      return "APE_";
    } else if (layerIndex == 3) {
      return "CAT_";
    } else if (layerIndex == 4) {
      return "ALIEN_";
    } else if (layerIndex == 5) {
      return "DOGE_";
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Trait.sol";

contract Hats is Trait {
  // Skin view
  string public constant SPECIAL_OPS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAD1BMVEVldC1BQDp+dliPhGKbkW5wpPPzAAAAAXRSTlMAQObYZgAAALJJREFUSMftkF0OhCAMhIvsATTxALvUA5C2B3Bb73+mrRqjxMjDPvOFv4EBBgCcZSsnL5b3VcPsc1fNIgQ11GipGkxRqgbGpPUTjKyYyB5ycA5Nkrjc4bmuOn7GfN4HIOgGj83+thQTz/E75k6855TX46P/Spf3GskMZSLhpGtrt4CJSMyLCqOi3l9jAbaACD1NRHwz5HCM+shouA52HYoOzoXhMAxP/xYKf6PRaDQa//ADr8MV+48oCrMAAAAASUVORK5CYII=";
  string public constant CROWN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAFVBMVEUAAAACZ7cxtwI16QL/0Sn/3Vv/5430D+K1AAAAAXRSTlMAQObYZgAAAERJREFUSMdjYMACEgJY2RgoAgEMDKwMtAWUW4HXmwkhrmyJQaZiIBqEMRS4uqWEuDqrhIBpIGYYBaNgFIyCUTAKRgwAAEUsCuU59t5pAAAAAElFTkSuQmCC";
  string public constant MOTORCYCLE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAHlBMVEUAAAAkJCQ6OjpUVFRhYWH/PT1ubm7/V1ejo6PX19epJvNBAAAAAXRSTlMAQObYZgAAAM5JREFUSMftkDEOwjAMRcPCTHoCagSsCLfKihTT7FCJvUKBmbT0BpyB4+KSFBbICfImy3n6yY8QPyjUsUBG/EOrlqJCUTri0/8CDgkxQZu6igpkWhsX9ncbfSSZiICFJjS1tfZMqNxbkjJbPWCsqJEP2spaIv4wzauJlHB9NvOQgM4PFxoTpE/Ig3Da+GHa6a8goQHp973bBcF0WH6EDPIg3GDhhwbWvXK9fwNHyJnfA9fjS6ZcApZ9dxAiZHxqDqh2KIFbGOMSiUQikYjzAm+BMKFIftxBAAAAAElFTkSuQmCC";
  string public constant KNIT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUwAIGvRA7fVhK/WBtCAAAAAXRSTlMAQObYZgAAACtJREFUOMtjYGBYtYoBFcAEtFbQQwDOhQAGdBAKBXCBmVDAMApGwSgYWAAARq4cTV6NFBEAAAAASUVORK5CYII=";
  string public constant HARDHAT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAD1BMVEVldC3gvADDw8P/2hD//JQq30h5AAAAAXRSTlMAQObYZgAAAFBJREFUSMdjYAACYyBgwAcMDYWFUQQMmIegAmNlI1RvMikgSYIAUAEMgAVZHJAUgNQgYQZBQQZGFScBEA3G6EAQDTCMglEwCkbBKBgFwwUAANLMDPQRsBm8AAAAAElFTkSuQmCC";
  string public constant KNIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAG1BMVEX4ClzkOzvuZGSZmZmzs7PAwMDNzc3a2trn5+eNpld+AAAAAXRSTlMAQObYZgAAALxJREFUSMftkTEOwjAMRSNRlZ2he4fCipQcoFLtnUp2ZlqRdGVKegN6bFIY0wYOkDdaT/a3LcQGyH0lAUDswTie04Kup6sQxa6AuvZJge0p3YGHy48OfTWr9qASIadFtsX2FsxMqP2y+MmODXMsEEAQ5pd3emg0RgIAkSifwltnDSNFAtH3gt5bzQ+OcyCoT9E5Y0yYFwkddID30jtjQ1yKR6jwpCBYGxIYhC4S5MrtCLxCIEUmk8lkMn/wBpnuNHgsWh6yAAAAAElFTkSuQmCC";
  string public constant RAINBOW =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAD1BMVEVldC3lUEdPjONl5Enj5Ekn+BeYAAAAAXRSTlMAQObYZgAAAG5JREFUSMftz7ENwzAMRFEi8QA5aYGA0AAOqAmM23+mUJ2vcDKA+RuCwGNBs2wQsF850c/7g3gpGAgBA7sC7wq8K4jpft6f098K2BSwKZiEgI1QQKJdv+gxF8j5AXjYvxJGHmDNPKBVVVVV1W36AkLsDMOwXhdMAAAAAElFTkSuQmCC";
  string public constant GAS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAFVBMVEVodAAQEBAqKipeXl5sbGyGhobN4uAxiuNyAAAAAXRSTlMAQObYZgAAAGZJREFUSMdjYBhZgJFRQACZb+DAwgznsAawBqCoNjZG1R0awBqKzFcCAhQFYQlsqch8BSYFJtIUMAkwKqDwFYUU8ClgcQBBFC8KMCJ7kdnQUUTYAEWBoCB+BaNgFIyCUTAKRgEBAAAFzwlvyOPfIwAAAABJRU5ErkJggg==";
  string public constant HAMBURGER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAGFBMVEUAAABWMBLzPSHEaB3miT488yF9+2z/6B+OeA4iAAAAAXRSTlMAQObYZgAAAI5JREFUSMftkTEOwyAMRb3Q3RN7z+AbmAN4gbmL2TPl+nVoIkUQoiqz32AJva9vEAAGpx8wY5N0HyBOzPPAHyvoPkD7JeYNtGl+uGJ3qbXQRYs1s6njITwENFfVrKWUrNUOQcNLigapIgEE4N1R4dNMk8XG2jGsiLgiLhEXmxgRhwB2XP7kGXAcx3GcB3wBQf41+gnJ8/EAAAAASUVORK5CYII=";
  string public constant ASTRONAUT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAJFBMVEUAAABwcHAOmNwQpe0Tsf8uuv9Uzf/Nzc236//n5+fx8fH09PT96emkAAAAAXRSTlMAQObYZgAAAPFJREFUSMftkTtuwzAMQIkuRrp18p4cITlAB/cI9hGCjvJkqFk6ZsxmSF6yklq6BSIvF8m1ChuFfQK9hYTwQPEDkChalVLP3pheaVgwE5gQ/wszCC0aALMqsHN2W/DMmwIS0XYFETKBVUEGkYXQBVJunAze+EGY2ZKT+PZyqJrr998E4m8AOyuhD+JR2B9Ozed1EtzD/8T46rRFdMMk1OdzEtqv2yg8yrDOqcL+9NEkwbaX+ySEdVr7Kxyruo7n6BTY8jJVaLHvNI5Nhj+q9yi8KUBECVfbkbDpQdNizKJUEOc3nR5DX+j1ZWUymUwmM+MJxypxehjjjQAAAAAASUVORK5CYII=";
  string public constant USHANKA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAElBMVEUAAAB5HByFhYWSkpKfn5+srKyqZcbPAAAAAXRSTlMAQObYZgAAAItJREFUSMftjzEKwzAMRQWtL9ATtLK6F8negxzvIXXuf5WaDK2DwZkLeugPH33EF0Bl2+eHk7C0Hqpzrd8iC4woSvMwEJB1GFBNcnIhpGHJgj4fAt2bVJbDspXLOl0ZX478/RLnaT/fSkmIHzdi5azKa/+Bx5SqJCGuiL4L8Lfe+ynFRzAMwzCMP+EDYuAXa3pgoK4AAAAASUVORK5CYII=";
  string public constant SANTA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAElBMVEVjb2zGJCrZKzHdQUbo6N/z8+6qFXUgAAAAAXRSTlMAQObYZgAAAH1JREFUSMftzrENw0AIhWGKZIDjlAGABeJHBkgK+kQ677+K3aWwwzUp+SokfiGITiwGoYyYzwLlNGBMA/Q0UEDTwHb5BVX8XLrs26bs5togfgjAwreIz9K6icnxkjzGGESxxou5nzwb8Z1CNNJnCfd8T5f3JLg+qZRSSvmLDRNvDyRpMVYXAAAAAElFTkSuQmCC";

  // Front view
  string public constant FRONT_SPECIAL_OPS =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAAB+dliPhGKbkW5+ND/UAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYEjgZWBgcGBkGJwAAGqxAK/ONtuCAAAAAElFTkSuQmCC";
  string public constant FRONT_CROWN =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAQAAAAAz8sVhAAAAAnRSTlMAAHaTzTgAAAAMSURBVAjXY2CgLQAAAGAAATeQF3gAAAAASUVORK5CYII=";
  string public constant FRONT_MOTORCYCLE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAAAAAA+4qcQAAAAAnRSTlMAAHaTzTgAAABMSURBVCjP7cyrDYAwAEDB4+NwiE7ACO2irNVuQYKoxyMIoWECBE+eeLzqYCGIKa8YLw9iijxQQyHDADPHtCsb+ntWFVpQtY9G/j7ZCRxkDJDlVoYwAAAAAElFTkSuQmCC";
  string public constant FRONT_KNIT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAQMAAAAhR2qPAAAABlBMVEUAAADfVhI86kBYAAAAAXRSTlMAQObYZgAAAA5JREFUCNdj4P/AQEsAAF4RAQAJJ6MzAAAAAElFTkSuQmCC";
  string public constant FRONT_HARDHAT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAAD/2hDDw8OFqE31AAAAAXRSTlMAQObYZgAAABRJREFUCNdjYIhMZWBgCGBlGJwAAKhHARREPXISAAAAAElFTkSuQmCC";
  string public constant FRONT_KNIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAQAAAAAz8sVhAAAAAnRSTlMAAHaTzTgAAAAMSURBVAjXY2CgLQAAAGAAATeQF3gAAAAASUVORK5CYII=";
  string public constant FRONT_RAINBOW =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAADj5EnlUEdPjONN8RqPAAAAAXRSTlMAQObYZgAAAA9JREFUCNdjYAhdzTCIAQCd9QEBc0kIcgAAAABJRU5ErkJggg==";
  string public constant FRONT_GAS =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAD1BMVEUAAACGhobN4uAqKioQEBCW/DTpAAAAAXRSTlMAQObYZgAAAC5JREFUGNNjYGBgFGAUYAABQQFGQTBDSIFJEZXB7MBigMpgcWBxgDBcXCCMYQkAFYoDQpDT6ogAAAAASUVORK5CYII=";
  string public constant FRONT_HAMBURGER =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAGFBMVEUAAADmiT7EaB19+2w88yHzPSH/6B9WMBInv3+2AAAAAXRSTlMAQObYZgAAADFJREFUGNNjYGAQBAIGEBBUFBQCM0xcTJzBjFAgADPSgADMKE8vK4cwgACiC6Z9WAIAD+MIYM1v0dEAAAAASUVORK5CYII=";
  string public constant FRONT_ASTRONAUT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAGFBMVEUAAADNzc0OmNwQpe0Tsf8uuv9Uzf+36/+lKt1+AAAAAXRSTlMAQObYZgAAADFJREFUGNNjYGAQBAIGEFB2CSuHMEzC0qGM0DQwQ8nENQzCMHYJhTCUTVzADLj2YQkAcDMGf78bGZYAAAAASUVORK5CYII=";
  string public constant FRONT_USHANKA =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAAAAAA+4qcQAAAAAnRSTlMAAHaTzTgAAAAcSURBVCjPY2BgYGBYswZBMjAwMDCsQaFGwcgFAFp8BAmdVdSNAAAAAElFTkSuQmCC";
  string public constant FRONT_SANTA =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAQAAAAAz8sVhAAAAAnRSTlMAAHaTzTgAAAAMSURBVAjXY2CgLQAAAGAAATeQF3gAAAAASUVORK5CYII=";

  // Front armor view
  string public constant FRONT_ARMOR_SPECIAL_OPS =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAD1BMVEUAAACPhGKbkW5BQDp+dlh+zwHRAAAAAXRSTlMAQObYZgAAAB9JREFUGNNjYGBgVDYSYAABIScRITBDUURIkWEUgAAAYMsBScRVzMEAAAAASUVORK5CYII=";
  string public constant FRONT_ARMOR_CROWN =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAFVBMVEUAAAD/540CZ7f/3VsxtwI16QL/0SnadNOZAAAAAXRSTlMAQObYZgAAABlJREFUGNNjYGAQMglWZACB5FQ3M4ZRgAIAKtAB/5DJXMEAAAAASUVORK5CYII=";
  string public constant FRONT_ARMOR_MOTORCYCLE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAElBMVEUAAABUVFRhYWH/V1f/PT1ubm5TBb01AAAAAXRSTlMAQObYZgAAACRJREFUGNNjYGAQVHYKZQABQWEjVQZigQADAytMVyjRuoYcAAALBQIHLifLJQAAAABJRU5ErkJggg==";
  string public constant FRONT_ARMOR_KNIT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAACvRA7fVhK/CDrWAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYACD0FAgMXMmw6ADABZDAd3yppsFAAAAAElFTkSuQmCC";
  string public constant FRONT_ARMOR_HARDHAT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAAD//JTgvADDw8N9xan+AAAAAXRSTlMAQObYZgAAABhJREFUCNdjYGB0YGBg0K0AEqtWMQw6AABOmAI7b+TcDwAAAABJRU5ErkJggg==";
  string public constant FRONT_ARMOR_KNIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAAAAAA+4qcQAAAAAnRSTlMAAHaTzTgAAABESURBVCjP7cyxDUBAAAXQd3LtH8ACDGB0cxiAASxgAYVERHWVyhvgFZgjET06t8PTsmlVrjSTJQbUd1phN5K1uf197wSkaQiNqd5CiwAAAABJRU5ErkJggg==";
  string public constant FRONT_ARMOR_RAINBOW =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAADj5EnlUEfV0W1oAAAAAXRSTlMAQObYZgAAABFJREFUCNdjYACD0FUMgxMAAJhdAQAOYUYrAAAAAElFTkSuQmCC";
  string public constant FRONT_ARMOR_GAS =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAAAAAA+4qcQAAAAAnRSTlMAAHaTzTgAAABOSURBVCjP7cxBCYBAFIThb8UAno3wMokJXirZTEYwwCbw4IIgBvDgfxn4mZkCrNhAgbisvacgovvBg9Irh/leSDJJGKFNS5W1vX78fJMT4r8KaMLOpcEAAAAASUVORK5CYII=";
  string public constant FRONT_ARMOR_HAMBURGER =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAAA88yF9+2wIpCLGAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYEAAt4lAwpGFYTABAKLiAR0JrN+2AAAAAElFTkSuQmCC";
  string public constant FRONT_ARMOR_ASTRONAUT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAAAAAA+4qcQAAAAAnRSTlMAAHaTzTgAAAAxSURBVCjPY2RgYGD48pmBgfczAy8PAxQ8R6GoBM4iGcoIYT1jYJBiYJCkqjWjgJoAAB/QCIUq0ToRAAAAAElFTkSuQmCC";
  string public constant FRONT_ARMOR_USHANKA =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAD1BMVEUAAACfn5+SkpKFhYV5HByeMTx6AAAAAXRSTlMAQObYZgAAAB9JREFUGNNjYGBgVDZWYAABZRNnQzBDyMhYiGEUgAAA7GUBzApMvPIAAAAASUVORK5CYII=";
  string public constant FRONT_ARMOR_SANTA =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAElBMVEUAAADdQUbZKzHGJCrz8+7o6N+uWPkKAAAAAXRSTlMAQObYZgAAAB9JREFUGNNjYGAQMlYyYgABk5AQZzDDlYEhhGEUgAAAfMQCUmAKvrwAAAAASUVORK5CYII=";

  constructor() {
    _frontArmorTraitsExists = true;
    _tiers = [
      4350,
      5150,
      5950,
      6600,
      7300,
      7900,
      8500,
      9000,
      9300,
      9500,
      9700,
      9900,
      10000
    ];
  }

  function getName(uint256 traitIndex)
    public
    pure
    override
    returns (string memory name)
  {
    if (traitIndex == 0) {
      return "";
    } else if (traitIndex == 1) {
      return "Knitted Cap";
    } else if (traitIndex == 2) {
      return "Hard Hat";
    } else if (traitIndex == 3) {
      return "Special Ops";
    } else if (traitIndex == 4) {
      return "Santa";
    } else if (traitIndex == 5) {
      return "Ushanka";
    } else if (traitIndex == 6) {
      return "Gas Mask";
    } else if (traitIndex == 7) {
      return "Rainbow Beanie";
    } else if (traitIndex == 8) {
      return "Motorcycle Helmet";
    } else if (traitIndex == 9) {
      return "Hamburger";
    } else if (traitIndex == 10) {
      return "Astronaut";
    } else if (traitIndex == 11) {
      return "Knight";
    } else if (traitIndex == 12) {
      return "Crown";
    }
  }

  function _getLayer(
    uint256 traitIndex,
    uint256,
    string memory prefix
  ) internal view override returns (string memory layer) {
    if (traitIndex == 0) {
      return "";
    } else if (traitIndex == 1) {
      return _layer(prefix, "KNIT");
    } else if (traitIndex == 2) {
      return _layer(prefix, "HARDHAT");
    } else if (traitIndex == 3) {
      return _layer(prefix, "SPECIAL_OPS");
    } else if (traitIndex == 4) {
      return _layer(prefix, "SANTA");
    } else if (traitIndex == 5) {
      return _layer(prefix, "USHANKA");
    } else if (traitIndex == 6) {
      return _layer(prefix, "GAS");
    } else if (traitIndex == 7) {
      return _layer(prefix, "RAINBOW");
    } else if (traitIndex == 8) {
      return _layer(prefix, "MOTORCYCLE");
    } else if (traitIndex == 9) {
      return _layer(prefix, "HAMBURGER");
    } else if (traitIndex == 10) {
      return _layer(prefix, "ASTRONAUT");
    } else if (traitIndex == 11) {
      return _layer(prefix, "KNIGHT");
    } else if (traitIndex == 12) {
      return _layer(prefix, "CROWN");
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Trait.sol";

contract Mouths is Trait {
  // Skin view
  // Mouse: 0
  string public constant MOUSE_MUSTACHE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAALVYWFj80eMK120yAAAAAXRSTlMAQObYZgAAABxJREFUOMtjYBjmQAFdIASNz+jKMApGwSggCwAAaIUAuwUYiUcAAAAASUVORK5CYII=";
  string public constant MOUSE_BIG =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAAOtYWFj80eN5Pf/YAAAAAXRSTlMAQObYZgAAABxJREFUOMtjYBjegFERXcQFXQUjwygYBaOALAAAXiEAaZ6N2uMAAAAASUVORK5CYII=";

  // Frog: 1
  string public constant FROG_SMALL =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVWa3SUT2C1RgEMAAAAAXRSTlMAQObYZgAAABJJREFUKM9jYKAD4GMYBcMUAAAcOgAPPOXO0QAAAABJRU5ErkJggg==";
  string public constant FROG_MUSTACHE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEV0APksIR6UTl1i+bioAAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBhCgDEETYB1KcMoGAWjYMAAAIeXAQDvPvAiAAAAAElFTkSuQmCC";

  // Cats: 2

  
  // Alien: 3
  string public constant ALIEN_SMIRK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVya3WUT2CRxyFJAAAAAXRSTlMAQObYZgAAABRJREFUKM9jYBgQoABjyDCMgqEMAGxgAD0bClW7AAAAAElFTkSuQmCC";
  string public constant ALIEN_BIG =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEUAAACUT2BlLptxAAAAAXRSTlMAQObYZgAAABJJREFUKM9jYBhYYMMwCoYyAABrQAA9cZpOMgAAAABJRU5ErkJggg==";
  string public constant ALIEN_SMALL =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVCaW6UT2BoZaUaAAAAAXRSTlMAQObYZgAAABJJREFUKM9jYBhYIMMwCoYyAAAzQAAddC7+RwAAAABJRU5ErkJggg==";
  string public constant ALIEN_MUSTACHE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVwANI1IAuUT2DNoiTcAAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBjegDEATYB1CsMoGAWjgDoAAA8gAOueLsSjAAAAAElFTkSuQmCC";

// Ape: 4
  string public constant APE_SMIRK = ALIEN_SMIRK;
  string public constant APE_BIG = ALIEN_BIG;
  string public constant APE_SMALL = ALIEN_SMALL;
  string public constant APE_FROWN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAAC6UT2BssdvWgWEuAAAAAXRSTlMAQObYZgAAABlJREFUOMtjYBhWQIGgCkYHhlEwCkYBdQAAST4AYreuqbAAAAAASUVORK5CYII=";
  string public constant APE_MUSTACHE = ALIEN_MUSTACHE;

  // Doge: 5
  string public constant DOGE_SMIRK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVya3WUT2CRxyFJAAAAAXRSTlMAQObYZgAAABRJREFUKM9jYBgQIABj8DGMgqEMADdQAB8IFVfpAAAAAElFTkSuQmCC";
  string public constant DOGE_BIG =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVzAACUT2DomOQeAAAAAXRSTlMAQObYZgAAABJJREFUKM9jYBhYIMcwCoYyAAA2wAAf/BIHWwAAAABJRU5ErkJggg==";
  string public constant DOGE_SMALL =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEUAAACUT2BlLptxAAAAAXRSTlMAQObYZgAAABJJREFUKM9jYBhYwMcwCoYyAAAawAAPQ9QEUQAAAABJRU5ErkJggg==";
  string public constant DOGE_FROWN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVwAJqUT2BsstvZNZqLAAAAAXRSTlMAQObYZgAAABxJREFUOMtjYBhWQIGwkgA0PiMLwygYBaOALAAAiwEAdlwHFK4AAAAASUVORK5CYII=";
  string public constant DOGE_MUSTACHE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEV0ACg2IQyUT2B2Y3PgAAAAAXRSTlMAQObYZgAAABlJREFUOMtjYBjmIASNz5jKMApGwSigDgAAcJ8AuwGKa1QAAAAASUVORK5CYII=";

  // Front view
  // Mouse: 0
  string public constant FRONT_MOUSE_MUSTACHE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAAD80eNYWFjkEfkPAAAAAXRSTlMAQObYZgAAABZJREFUCNdjYMANBEDECiBm6mIYKAAAnvIBRSBsz2QAAAAASUVORK5CYII=";
  string public constant FRONT_MOUSE_BIG =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAABYWFj80eN4mg01AAAAAXRSTlMAQObYZgAAABZJREFUCNdjYMAJGBVBpAuIxcgwUAAANNoAaVg+T9UAAAAASUVORK5CYII=";

  // Frog: 1
  string public constant FRONT_FROG_SMALL =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAQMAAAAhR2qPAAAABlBMVEUAAACUT2BlLptxAAAAAXRSTlMAQObYZgAAAA9JREFUCNdjYICDBww0AABKwADhDIMvpQAAAABJRU5ErkJggg==";
  string public constant FRONT_FROG_MUSTACHE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAAAsIR6UTl0+UFV7AAAAAXRSTlMAQObYZgAAABRJREFUCNdjYEAAxhAgwbqUYTABAI/BAQBb10M/AAAAAElFTkSuQmCC";

  // Cats: 2


  // Alien: 3
  string public constant FRONT_ALIEN_SMIRK =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAQMAAAAhR2qPAAAABlBMVEUAAACUT2BlLptxAAAAAXRSTlMAQObYZgAAABNJREFUCNdjYEAFTAwMjAcYqAcAOk0AxAK2t8EAAAAASUVORK5CYII=";
  string public constant FRONT_ALIEN_BIG =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAQMAAAAhR2qPAAAABlBMVEUAAACUT2BlLptxAAAAAXRSTlMAQObYZgAAABBJREFUCNdjYMAAzAcYqAcAOkcAxDphh+IAAAAASUVORK5CYII=";
  string public constant FRONT_ALIEN_SMALL =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAQMAAAAhR2qPAAAABlBMVEUAAACUT2BlLptxAAAAAXRSTlMAQObYZgAAABBJREFUCNdjYMAAjAcYqAcAOa0Awvt43+8AAAAASUVORK5CYII=";
  string public constant FRONT_ALIEN_MUSTACHE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAAA1IAuUT2ABXfVlAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYMAJGAOABOsUhgEFAHZRAOu70/C4AAAAAElFTkSuQmCC";

  // Ape: 4
  string public constant FRONT_APE_SMIRK = FRONT_ALIEN_SMIRK;
  string public constant FRONT_APE_BIG = FRONT_ALIEN_BIG;
  string public constant FRONT_APE_SMALL = FRONT_ALIEN_SMALL;
  string public constant FRONT_APE_FROWN =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAABssduUT2Dg7htjAAAAAXRSTlMAQObYZgAAABNJREFUCNdjYMAGBOAspgaGAQUAScAAk5NAtAAAAAAASUVORK5CYII=";
  string public constant FRONT_APE_MUSTACHE = FRONT_ALIEN_MUSTACHE;

  // Doge: 5
  string public constant FRONT_DOGE_SMIRK =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAQMAAAAhR2qPAAAABlBMVEUAAACUT2BlLptxAAAAAXRSTlMAQObYZgAAABJJREFUCNdjYEAFjED8gIF6AABDMADi7zfJjwAAAABJRU5ErkJggg==";
  string public constant FRONT_DOGE_BIG =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAQMAAAAhR2qPAAAABlBMVEUAAACUT2BlLptxAAAAAXRSTlMAQObYZgAAABBJREFUCNdjYMAAjA8YqAcAQy0A4p55BkcAAAAASUVORK5CYII=";
  string public constant FRONT_DOGE_SMALL =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAQMAAAAhR2qPAAAABlBMVEUAAACUT2BlLptxAAAAAXRSTlMAQObYZgAAAA9JREFUCNdjYMAEDxioBwBC4ADhVa/7BAAAAABJRU5ErkJggg==";
  string public constant FRONT_DOGE_FROWN =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAABsstuUT2CnTmGzAAAAAXRSTlMAQObYZgAAABZJREFUCNdjYMAGBBDMBUDMxMEwUAAAXWYAu5CDr/AAAAAASUVORK5CYII=";
  string public constant FRONT_DOGE_MUSTACHE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAAA2IQyUT2AnfpbCAAAAAXRSTlMAQObYZgAAABNJREFUCNdjYMANQoCYMZVhQAEAXosAu6Iz+KcAAAAASUVORK5CYII=";

  constructor() {
    _tiers = [3000, 5000, 7000, 9000, 10000];
  }

  function getName(uint256 traitIndex)
    public
    pure
    override
    returns (string memory name)
  {
    if (traitIndex == 0) {
      return "Small";
    } else if (traitIndex == 1) {
      return "Smirk";
    } else if (traitIndex == 2) {
      return "Big";
    } else if (traitIndex == 3) {
      return "Frown";
    } else if (traitIndex == 4) {
      return "Mustache";
    }
  }

  function _getLayer(
    uint256 traitIndex,
    uint256 layerIndex,
    string memory prefix
  ) internal view override returns (string memory layer) {
    if (traitIndex == 0) {
      return _indexedLayer(layerIndex, prefix, "SMALL");
    } else if (traitIndex == 1) {
      return _indexedLayer(layerIndex, prefix, "SMIRK");
    } else if (traitIndex == 2) {
      return _indexedLayer(layerIndex, prefix, "BIG");
    } else if (traitIndex == 3) {
      return _indexedLayer(layerIndex, prefix, "FROWN");
    } else if (traitIndex == 4) {
      return _indexedLayer(layerIndex, prefix, "MUSTACHE");
    }
  }

  function _getLayerPrefix(uint256 layerIndex)
    internal
    pure
    override
    returns (string memory prefix)
  {
    if (layerIndex == 0) {
      return "FROG_";
    } else if (layerIndex == 1) {
      return "MOUSE_";
    } else if (layerIndex == 2) {
      return "APE_";
    } else if (layerIndex == 3) {
      return "CAT_";
    } else if (layerIndex == 4) {
      return "ALIEN_";
    } else if (layerIndex == 5) {
      return "DOGE_";
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Trait.sol";

contract Pants is Trait {
  // Skin view
  // Short pants
  string public constant SHORT_FANCY =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVhYmzOfBTTexbcghM7VPhxAAAAAXRSTlMAQObYZgAAAFhJREFUOMtjYBgFVAdhU0MzUQT2rdxXhyKwbt/e9SgCdfv27kYTqEUVqNy1M2s0aIcNCN0eNgtF4OWqXXtRBN7m7duJIvCzbi+qip95tT9RBHbmZb6lrzcA0kkexhJMXJEAAAAASUVORK5CYII=";
  string public constant SHORT_BLACK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVlLWcXGBYcHRsfIR/lS+CTAAAAAXRSTlMAQObYZgAAAE9JREFUOMtjYBgFVAehQIAiUBtaW4siEFtbG4+qora2HE0gFlWgNBbN0FEwpNNIGlp0Xg0tRU0jd2NrS1EEvtaipaKvsbVfUQ2NjaVzGgEA9JIWUHO78tYAAAAASUVORK5CYII=";
  string public constant SHORT_BLUE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVyZXMUMGQeOXQfSIxwGWR2AAAAAXRSTlMAQObYZgAAAFhJREFUOMtjYBgFVAdhU0MzUQT2rdxXhyKwbt/e9SgCdfv27kYTqEUVyFy3Mm80aIcNCF0WNgtF4OWqXXtRBN7m7duJIvCzbi+qip95tT9RBFZm5b6krzcAVPMeeUDvN08AAAAASUVORK5CYII=";

  // Long pants
  string public constant LONG_FANCY =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAD1BMVEVzLWnOfBTTexbbgRLfhBdEB3xUAAAAAXRSTlMAQObYZgAAAJFJREFUSMftlMERAyEMA68FMA3YogELGjju+q8pFBD7mzzYh187GjOArutw+DNK1VL2CAXQFBSGghGE2xMKsjq7A7FALEmFuxN3Y7IkVPyNE/qANpcZCtU2+6jnRRwOX3qiQHZNWChQzWDwWPC6sBD/sKGycCcJQyvFZ9JV2th85gnNn1yAI26aUXT3nfEHV/ABZ+MVbV8H+hoAAAAASUVORK5CYII=";
  string public constant LONG_BLACK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAD1BMVEVzLWkVFhQYGRccHRsgIR/TWU0JAAAAAXRSTlMAQObYZgAAAIhJREFUSMftlLENBDEIBN0CfhqApxEQ/df064sPLrwP2MCJRyss27PWZPJnoS1EWErAQsWCowQ0LMw1S4AvwKwFuAX8NDQzYFvYs26wPADXQ25FcNR5EZPJjSfo+4EmtARCVE3Na8D3EUH9w1L4eMIbYMMT2bgKDQAeG3oAM9SmSRKcQuOFK/gBESgYVnnv5RIAAAAASUVORK5CYII=";
  string public constant LONG_BLUE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAD1BMVEUAAAAUMGQfOXQeRocfTaK1PriXAAAAAXRSTlMAQObYZgAAAJFJREFUSMftlMERAyEMA68FMA3YogELGjju+q8pFBD7mzzYh187GjOArutw+DNK1VL2CAXQFBSGghGE2xMKsjq7A7FALEmFuxN3Y7IkVPyNE/qANpcZCtU2+6jnRRwOX3qiWN01YaFANYPBY8HrwkL8w4bKwp0kDK0Un0lXaWPzmSc0f3IBjrhpRtHdd8YfXMEHZOIVaw91yZoAAAAASUVORK5CYII=";

  // New pants
  string public constant ASTRONAUT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAG1BMVEVPsue5AABWV1VvcW5/gX6+wb3Lzsrm6OXy9PHHtKnUAAAAAXRSTlMAQObYZgAAAMtJREFUSMftlLENAyEMRW8FmgwAGwAbcCscpE2BYAG8QTx37CsT2ZZS8yl58v2TxTuOnZ2vxGAAwQJ8tABtQu21X1ftIjDfDQdOEIGBAyZOlAGY91E6DBiodHDu4Wp3TgTaqn1CW1oH/gtUO9Te5A655FJKKiJAd/kkSl619yElc+E7O394IloaCN6aoAHsCD6yJ2CuJ70xGcBbBKiJBFkEyif4jSodyBEv5xRPsGXaUjzBBQeYnqjyhJzZFDnJnjjpVvMEOYJM8bvwD2e5RJo7hlZhAAAAAElFTkSuQmCC";
  string public constant COWBOY =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAIVBMVEUAAAAkFwYTH04WIFYyIwsUJWM4JwpZKgdvNxGJQBL+1QCN1Ay8AAAAAXRSTlMAQObYZgAAANBJREFUSMftlEEKwjAQRXuFQugBRN1LGPeBafY25ASN9gZt9QJNbpA5gdc0boWZgiC46N/m8SdhyKuqLVs+Mk0rwDj8FPCnvtMlLODqFsCD44HGeucBWMCocEXEmm9Qt+CdMEIbDPIdgkGngX8FnRUSUWKBSClRzJEHYs6xhAWe8/t4mYVVj8M0rS58y5Y/9AQc9n0n/DAHu4sF7aSGYEFowPporEXFN+jGIHjBE74pIzSvInDKlDvwQCZlW8kTKc9ExQWCJ+6yJ2Kc4/L4whMvV8tLH1+dY+AAAAAASUVORK5CYII=";
  string public constant LUMBERJACK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAFVBMVEUAAABiMQ8IRWARSWUAVHpgQShiZGEoVAkJAAAAAXRSTlMAQObYZgAAALFJREFUSMftlLENQyEMRP8KFGQAzhPYTABZgOIPkP2XiN1G8qEoTQqOkifOgO6u6+joQ6VsgLp+BaiFDXs2nSMF2sDsCk0BsQ5xKLfQblDJT8CAgllgwsAsZMSIkt8ijhcFu6bAGFBXXaWQx/b9et+rkn94vErZfvjR0f/1BJpEiI1kVFQaSbkMmd42PKORcwa4Aasiz3hXbjF9DttUkfQcMG+KRmaIjoiVAtERsb7uiTct3iR+3MrH0QAAAABJRU5ErkJggg==";
  string public constant SUIT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAFVBMVEUAAAAKFh8OHiwwHAs4IgYZKDZOMROMMu4EAAAAAXRSTlMAQObYZgAAAJdJREFUSMftlMEJgDAMRV2hhQ6QQDZwA4v3BNxA3H8Ek6vQHwS99ZecfPyk2PxlmZp6qK8JsPVfHQpVYq5lCPhHEz54CIjFYUMACyOAooWkgGLAGpxBvQgA4QABwS2u69yjxj+qb2vUfPRTr/VzDKQOzMWFcsKaBwlcoOYLdBBwSFYwWkQQJEBVNEM4aDJk4pABcQv9PiduMCsrUNLT6DgAAAAASUVORK5CYII=";
  string public constant KNIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAHlBMVEUAAAA2NjZKSkpxcXGZmZmzs7PAwMDNzc3a2trn5+difNTDAAAAAXRSTlMAQObYZgAAAMBJREFUSMftlDEOwjAMRXuFemJ1WJgJ4gJYFRdoEBdI071q6AhDRC6Q9LhQRpDNiJDy56cnWUpeVZWVvQ3wt8A0WW9dcCLgXEwCYBZg5oFhAa4bFiDStCMi/oK+PQEgfwdO5oIIwBtGY2WDN142+KYTDVprpfV2zQJ1DagUYnn0ZX/XiWBTTFboRAhjzLmfJcDnHCVgPxzvtxXfiYMmkjqB2J6T+InBxCxmAI3tvhm8bGg6LxlemZA6oRTgsxUfhgc/NTk1w29ieQAAAABJRU5ErkJggg==";
  string public constant POLICE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAElBMVEUAAAAGHDMLJkIIKUozJwZKOQilffLwAAAAAXRSTlMAQObYZgAAALxJREFUSMftlNENBCEIRK8FoAKgAoYW3A7W/ls59ncT+L1cIv6ZcVDivM/n1KlXrfVbQabDydAKAAe7WSsQTWcVbwVWp0UlWwGrBZR7B3bAwmi4Awenae8Qglq9IJ2qB/dzCIp6KNEw5n3vfd2tYO/7Wuu+zqc/9XecoMJAsaLHAFTgOkVQORHAkFE2towBA2Ll0rcQE68QDykvTmmiF3hxQt1igJmAyqSfQxataKBdMWKvNXDiYcTDivf+F1qGI59+bsDhAAAAAElFTkSuQmCC";

  // Front view
  // Short pants
  string public constant FRONT_SHORT_FANCY =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAADTexbOfBTcghMsdKvZAAAAAXRSTlMAQObYZgAAAB5JREFUCNdjYKAHyKoGEmGhQKJ2LojYC2OVziWgEwALYAYRFZBR2QAAAABJRU5ErkJggg==";
  string public constant FRONT_SHORT_BLACK =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAAAXGBYcHRsfIR8riSZSAAAAAXRSTlMAQObYZgAAAB1JREFUCNdjYKAHCE0DEaFAojYWRNTCWLGxBHQCANcVBM4rWVNSAAAAAElFTkSuQmCC";
  string public constant FRONT_SHORT_BLUE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAAAeOXQUMGQfSIyVuGQPAAAAAXRSTlMAQObYZgAAAB5JREFUCNdjYKAHyIoEEmGhQKJ2LojYC2PFTiWgEwD/pwXPMca/4wAAAABJRU5ErkJggg==";

  // Long pants
  string public constant FRONT_LONG_FANCY =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAD1BMVEUAAADTexbOfBTbgRLfhBffcoAOAAAAAXRSTlMAQObYZgAAADZJREFUGNNjYBiSQEhJWBnMEBQSFAQzhA0VHcEMEUNlCEPYUdEQKqICYQgLKaIxBAWFDPFaBAAzRwSS/7mIvgAAAABJRU5ErkJggg==";
  string public constant FRONT_LONG_BLACK =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAD1BMVEUAAAAYGRcVFhQcHRsgIR/IZ4SkAAAAAXRSTlMAQObYZgAAACxJREFUGNNjYBiSQEhJWBnMEBQSFAQzRBwVHaEMFUdcIkKKaAxBQSFHvBYBAFFsBRcWOvIhAAAAAElFTkSuQmCC";
  string public constant FRONT_LONG_BLUE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAD1BMVEUAAAAfOXQUMGQeRocfTaJii7rMAAAAAXRSTlMAQObYZgAAADZJREFUGNNjYBiSQEhJUBHMEBQSFAQzhA0VHcEMEUNlCEPYUdEQKqICYQgLKaIxBAWFDPFaBAAxrQSOcxLd+gAAAABJRU5ErkJggg==";

  string public constant FRONT_ASTRONAUT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAG1BMVEUAAAC+wb3Lzsrm6OXy9PG5AABvcW5/gX5WV1XM19zcAAAAAXRSTlMAQObYZgAAAD9JREFUGNNjYBiSQEhRSBHMEHZSMQQzlI2UjcAMFSNlJ1SRoNBQVVRdKk4qaGrSy9LLwAwgnQ5mdLRldDAwAADYYguPdveXlwAAAABJRU5ErkJggg==";
  string public constant FRONT_COWBOY =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAHlBMVEUAAAA4JwoWIFYUJWMTH04yIwskFwZvNxGJQBJZKgd8QHc+AAAAAXRSTlMAQObYZgAAAE9JREFUGNNjYBiSQMjE2RXMCFZ2MQMzAo2dRcEMUWHHMDBDUDQRwggVTYRIhYWmQkRSQ1MDwYyKiukdYEZ7+4x2MKO8fHo5mDFRcqIkAwMArrcPebGzeOMAAAAASUVORK5CYII=";
  string public constant FRONT_LUMBERJACK =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAFVBMVEUAAAARSWUAVHoIRWBiMQ9gQShiZGHXzFGbAAAAAXRSTlMAQObYZgAAAEZJREFUGNNjYBiSQFDJSBDMMFQ0EgYzhAyNFCEMQUOIiKGwoTGEIQhTI2yoCJOCiBgZGiuDGa4hriFgBpB2BTPcUtxSGBgAeOIIql2Q1FEAAAAASUVORK5CYII=";
  string public constant FRONT_SUIT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAFVBMVEUAAAAKFh8OHiwZKDZOMRM4IgYwHAtTPbD1AAAAAXRSTlMAQObYZgAAADVJREFUGNNjYBiSQEhRUBDCMBJWBDOUjYSNIAwlISNUKUyGsqGwEQ7triGuIWBGWGpYKgMDAElYB6ymxDOdAAAAAElFTkSuQmCC";
  string public constant FRONT_KNIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAAAAAA+4qcQAAAAAnRSTlMAAHaTzTgAAAB2SURBVCjP7c2xDcJQEIPhj0CFdAPkLUAGYGQWQPQRAzBAMgBXQfUk6BBNEhiAEjcn2f/Z/PVrreAslLFEi2ZOcroNVFDTN3HgAhvodRy7T+mJkuzbmRARolheqHXemYxQlVhWUpUyF2IYRuzAGl5Pt8f2Pl7xBva4HQsbSM+kAAAAAElFTkSuQmCC";
  string public constant FRONT_POLICE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAElBMVEUAAAALJkIIKUoGHDNKOQgzJwa3pY29AAAAAXRSTlMAQObYZgAAAENJREFUGNPVy1ENACAIRVEqgAmABGAFaED/LG6gIXxfZ3u7AF+OmPjCB0ImDUTDgfqA2alheuGv2g+6bK7IikZWFsABUEcHhkozIfgAAAAASUVORK5CYII=";

  constructor() {
    _tiers = [
      5000,
      5700,
      6400,
      7000,
      7600,
      8200,
      8800,
      9300,
      9500,
      9700,
      9900,
      9950,
      10000
    ];
  }

  function getName(uint256 traitIndex)
    public
    pure
    override
    returns (string memory name)
  {
    if (traitIndex == 0) {
      return "";
    } else if (traitIndex == 1) {
      return "Short Black";
    } else if (traitIndex == 2) {
      return "Long Black";
    } else if (traitIndex == 3) {
      return "Short Blue";
    } else if (traitIndex == 4) {
      return "Long Blue";
    } else if (traitIndex == 5) {
      return "Police";
    } else if (traitIndex == 6) {
      return "Suit";
    } else if (traitIndex == 7) {
      return "Lumberjack";
    } else if (traitIndex == 8) {
      return "Knight";
    } else if (traitIndex == 9) {
      return "Short Fancy";
    } else if (traitIndex == 10) {
      return "Long Fancy";
    } else if (traitIndex == 11) {
      return "Astronaut";
    } else if (traitIndex == 12) {
      return "Cowboy";
    }
  }

  function _getLayer(
    uint256 traitIndex,
    uint256,
    string memory prefix
  ) internal view override returns (string memory layer) {
    if (traitIndex == 0) {
      return "";
    } else if (traitIndex == 1) {
      return _layer(prefix, "SHORT_BLACK");
    } else if (traitIndex == 2) {
      return _layer(prefix, "LONG_BLACK");
    } else if (traitIndex == 3) {
      return _layer(prefix, "SHORT_BLUE");
    } else if (traitIndex == 4) {
      return _layer(prefix, "LONG_BLUE");
    } else if (traitIndex == 5) {
      return _layer(prefix, "POLICE");
    } else if (traitIndex == 6) {
      return _layer(prefix, "SUIT");
    } else if (traitIndex == 7) {
      return _layer(prefix, "LUMBERJACK");
    } else if (traitIndex == 8) {
      return _layer(prefix, "KNIGHT");
    } else if (traitIndex == 9) {
      return _layer(prefix, "SHORT_FANCY");
    } else if (traitIndex == 10) {
      return _layer(prefix, "LONG_FANCY");
    } else if (traitIndex == 11) {
      return _layer(prefix, "ASTRONAUT");
    } else if (traitIndex == 12) {
      return _layer(prefix, "COWBOY");
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Trait.sol";
import "./ITrait.sol";

contract Tops is Trait {
  // Skin view
  string private constant STRAPPY_TOP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAElBMVEUAMCI8BEk2B0FaMWNpOXR5QYaFvGz8AAAAAXRSTlMAQObYZgAAAHBJREFUSMft07sNgDAMRVE3GSArsILNBCZ9JPD+q5CPEEEYCoQUhHyKV93GhQGMUTmA2CcgYs67BafsvUBEopPqEPgk79RQb0AkJsbiItipgciMONZVA99Qg6GhBiEsSSieBcZ8DzNR/vKewc1f/t8KRdUnFMn/8bQAAAAASUVORK5CYII=";
  string private constant CHEF =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAGFBMVEUAAAAyMzHNFB3gISLM2drh5unk5uPp7vCYXFw/AAAAAXRSTlMAQObYZgAAARtJREFUSMftlMFOwzAQRK1+BL2DENeqOfSMFJQfwPGdxtlzobvz+x0HWhHXSYS4ZuSDFb+dWSftOrdqVVHHqqque0EJcG5z3aMvAB/OPd0crOSw29wicB8BxP0eGr6qAwxphXFMwPHx86BoBMJTKoxdPOILnqE8iQkxrsyBz5VlLJcUYZlD0HjCNjnYeWCkzSI0CiuVPZyNEb0Ey3roWKbaqCk3bVpZD90JD7ynQRnR0iQD9Nsh0MP/KHOwhlccgLp+q5PGPXh7Nd7CEyh+bPXWGbxX9WH96a/6g2ALQI8FQJYcgIXj9L/sdQ5IyDQgaTZApmOGAWMzDqwmgzgN9AITmWmS04MZceY1cc6wjUmgOBt+i2Ph/W42/EsXOlyFE/2FZvkAAAAASUVORK5CYII=";
  string private constant PREHISTORIC =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAElBMVEVwcABjSBOEYBvhnhXspBT2yXBrTUdUAAAAAXRSTlMAQObYZgAAALxJREFUSMftlD0OwyAMRllygCRcgIQeINg9AP7MXqnh/lcpSdQlJUuXqhJv4cfPlkAYYxqNK7rfCJ6cGtPHQ1DNZ0Gn3hsz0L5YBelxEkiGe4nwNs+OP0soccnJ6xZfQ/Q2nYyc942ujM8ZAqwpVw+gCLcwkvKkWhUWgiMmliHOVSGqJwTAWa5XgAw0OrGCUK9A0SoketDiq0IPFIWhXlEXSMUCXJD27ht/gpb2PLr8gvTu8iv2nyO3m/ySF7D/I9Xi8JzlAAAAAElFTkSuQmCC";
  string private constant TSHIRT_BLACK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEUAAAA2NjY4ODg5OTnWDzk4AAAAAXRSTlMAQObYZgAAALtJREFUOMtjYBgFmMCBEURGIgQOMIPI+egCdegC/+H8cAemUAfm0OX/66ECsVdE/9aGl8dfvw8V+JkaW/8/vzb2fzpU4P/Sq5W19+un1ZdDBepD42P/ViK5qzb07v2v/5EE/t8trf9fiiRQHhpa/f4vkkD89PDculokgfehqdVf/yEJ3A+9ej/3O7It0+K/lt8cTQX4wVV0gSh0gW3oAt/Q+KGh67+jCJRfrf6JqiIs/z+KQOy6+q+DKRQA8fVFNXs3A+0AAAAASUVORK5CYII=";
  string private constant TSHIRT_WHITE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAB9klEQVR42u2a3W7DIAyFnUFFpb3/o04C1YjdzJHrQNM2JKPt+W76k8TKsU8MghABAAAAAAAAAAAAbCTGWJ459kj8GGO5XC6lR7zulFLKM8fuRYQLW+N9vZrDcs4UQiAiImamj3NAMWyN53s+8yEESik1z2Xmah84n89TS6yNJ1UXJ9gkpJRmhxARTdM07ZoAKz6EMIt0zn3nnImIfqx95Wa1M1rJ07HlnFqcEMLVufcw9bI8M9OfWHLOzd9r7rh1cyklcs6R935RUZ2gllC5XpK95oBuTdB7TyEEcs4thNeqy8yUUrr6XwTZ5OlYEl+E1lwjyTvEATHGUrNj7eatXW0F9TFxVKs/9KLrMFgTbwXq3y3x2lF7060H1DqxrXZN+Nq1wztAbrT12XKGnsTo75KcI6rf7RHQ1tZN0IrQMzjv/dwEpWlJYzySLo+ACGpV2w6L0uR0t64NkcxMp9Np/CbYGrZEkBWvq55SImaujuePDGf/5gA9DOpJiK18TWBrUqPj7N0EAQAAAAAAAAAA8HkMt9hg9wP3XhDxoyVAxNsdpr0Y7v0A59zN7bG3T8ARC6FD9YC193zkUbCJkUXUtd3fl3CA3g2yq8c5Z/LeL16Hae0Mv5UDZGlcvy+wELDRAcOMArI3oC0vVa+JP3oLDQAAAADvxy8j65Qi++Br+AAAAABJRU5ErkJggg==";
  string private constant TSHIRT_BLUE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAB/0lEQVR42u2awW7CMAyGG5qq6t6Syw6cdtszcJjEade9JVHVoOyA/s6YBBiEKMD/XaC0smL7txPVNA0hhBBCCCGEEELIjSzX23DNvf/YX6634f3LhRz2FrkDMPTmqnuX0tm9Ddvmsbd4NIVNPsyO+13zegGQWbft7fZszpofetO4MV2WfhfvAz+fb1EtrzYuaHvIOpSw2riDB9wYDoL0/TGYuwZAOz/0ZnYSjuFayheLhaPy+pRtPBOzM/Tm4NkiCtD16MbQdNY0kw9RdcjF6UXimc6aI3nH1AVbOhidvTwI2XoAujK6tA5QTMoIiHZo8mklwL50NLaWYj1AR1ovXktWqmDyxyrAPb/b20r1h1xk3QVi2dDylNepOs65z989ANohXd+6eaVqUzYwqZTqAyAXHPtMKUMeYuT3VIOsugRkVmUTjHV5OGzbvyyjaaExliTLNigzKJsgnMG2iGvb7p091QN0MKtWQGrbgkPyPuocWXdjOAoGfs9x1C26DcpDEDIYy6w+1KActJ3S5UAIIYQQQgghhJDXwNS2ID0PvPdcwNYWAPkesQTVjcc7a06Ox54+ACVehFbVA879z0f+JUaXytCbs/P/h1CAnAbp1+OTD/McQQcmx1vjKppgbJwGJycf5kmSLhXbmucIALKPeQAcRNZjfYEzA0IIIYTcyi9gyVB9JbpWGAAAAABJRU5ErkJggg==";
  string private constant VERTICAL_RED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAD1BMVEVlLXTaT1Dg4t/t7+v6/PkXGOinAAAAAXRSTlMAQObYZgAAAIVJREFUSMft01EKhDAMBNAIHmAhcwGPMDfYQO5/Jq1UwSXdiPpn56vQR5IWItLTE+YrMmxnYwJoWYULACjA7CMyutPcgR9gaxSAu7UBoC3ACkqFqIWu9ywg/Ka9hSZA0wrLlA0wZeDEkKzPDIHWFs0he3rihJt9AEwA7V6LcLOfBvwPXpoZT/Eo1b+hauMAAAAASUVORK5CYII=";
  string private constant VERTICAL_GREEN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAD1BMVEVlLXQ4xmPg4t/t7+v6/Pk83kfxAAAAAXRSTlMAQObYZgAAAIVJREFUSMft01EKhDAMBNAIHmAhcwGPMDfYQO5/Jq1UwSXdiPpn56vQR5IWItLTE+YrMmxnYwJoWYULACjA7CMyutPcgR9gaxSAu7UBoC3ACkqFqIWu9ywg/Ka9hSZA0wrLlA0wZeDEkKzPDIHWFs0he3rihJt9AEwA7V6LcLOfBvwPXpoZT/Eo1b+hauMAAAAASUVORK5CYII=";
  string private constant VERTICAL_ORANGE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAD1BMVEVldC3slA3/oxjg4t/5+/gVaV5HAAAAAXRSTlMAQObYZgAAAJhJREFUSMftlLENwzAMBOkgA7jgCD9BJsgT2n8mU7YDJBYpw3AZXSVAh3+qoEQGg5C3yONzNrstMBamjgDUBLNZ5FmKsRTgV1CrEArEAlbBAOguaCvQEzzCBUsTVA8XbYUmgm4VHtBNYB0yEV5bRTqD7kN2K1gTsiG9gk76zMEgJlz9b3gmhH/DhYpwcQ8CTwRa8zdcqvhTFu2fLhJzL3fyAAAAAElFTkSuQmCC";
  string private constant TURTLENECK_BLACK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEUAAAA9PT1CQkJGRkYh3l+BAAAAAXRSTlMAQObYZgAAAM1JREFUOMvt0rEKwjAQBmBn3+8KFepocbCbPbTgW6gEqbp0ucGxIMHHENGSjhWHdlTcbIe0zQniA/QfDvJxl5CQXq/Ld4iqWjSw71dVclB8BOs1KAWOOgqaaBACbPFekafhheAV17CBciSQqgXow7DqcOuOBFy5aQF6YOd4In0wOZJGiFuaa/BzUrs4pVhDKmntWgCWBllQdDBuT7SMul/wO4oDckg5BPybDaY3E8JZYoJjnxkUdxMW2cOEOBubgE8Oiu3h5xcDoMx/r/ABd61lED+9l94AAAAASUVORK5CYII=";
  string private constant TURTLENECK_ORANGE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVhYmz2jCD3mTn4plAa+3z3AAAAAXRSTlMAQObYZgAAAM1JREFUOMvt0rEKwjAQBmBn3+8KFepocbCbPbTgW6gEqbp0ucGxIMHHENGSjhWHdlTcbIe0zQniA/QfDvJxl5CQXq/Ld4iqWjSw71dVclB8BOs1KAWOOgqaaBACbPFekafhheAV17CBciSQqgXow7DqcOuOBFy5aQF6YOd4In0wOZJGiFuaa/BzUrs4pVhDKmntWgCWBllQdDBuT7SMul/wO4oDckg5BPybDaY3E8JZYoJjnxkUdxMW2cOEOBubgE8Oiu3h5xcDoMx/r/ABd61lED+9l94AAAAASUVORK5CYII=";
  string private constant STRIPE_RED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAFVBMVEVoAADoSC76UDLg4t/t7+z3+fb+//xTrp1TAAAAAXRSTlMAQObYZgAAAPBJREFUSMftlE1uAyEMhVHVdF0sZV8/tRwgUi8QDbPujMD7VsH3P0IcVbMgYYq6562M/OGH+XNuaKipN+detjjHBvDq3GGLo3YqyHcH0OUhzTDgWdKXc085TwsQahsQv+cVHMrKYgNm1ECOSS0PaFJi8gymCog63fJGHBXBaBWuAElEUJmV8NHcJoBQNIkmUBNgOlpRM74vvSmJ/ICI4fXSBEo8ASLWJNqAzSarMmvmtgUz5dma5KK+vQb9TOzZUyhxXP2hf6isHSCfO8C8dAD920J1JbvbYReAZe1vwC5gX4O94J238WsxXQzI47hrXQGiRjKpvbWUKAAAAABJRU5ErkJggg==";
  string private constant STRIPE_BLUE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAFVBMVEVvcm0neeErhfXg4t/t7+z3+fb+//z67CVSAAAAAXRSTlMAQObYZgAAAPBJREFUSMftlE1uAyEMhVHVdF0sZV8/tRwgUi8QDbPujMD7VsH3P0IcVbMgYYq6562M/OGH+XNuaKipN+detjjHBvDq3GGLo3YqyHcH0OUhzTDgWdKXc085TwsQahsQv+cVHMrKYgNm1ECOSS0PaFJi8gymCog63fJGHBXBaBWuAElEUJmV8NHcJoBQNIkmUBNgOlpRM74vvSmJ/ICI4fXSBEo8ASLWJNqAzSarMmvmtgUz5dma5KK+vQb9TOzZUyhxXP2hf6isHSCfO8C8dAD920J1JbvbYReAZe1vwC5gX4O94J238WsxXQzI47hrXQGiRjKpvbWUKAAAAABJRU5ErkJggg==";
  string private constant STRIPE_ORANGE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAFVBMVEX7AwDrkw3/oxjg4t/t7+z3+fb+//zA9QaHAAAAAXRSTlMAQObYZgAAAPBJREFUSMftlE1uAyEMhVHVdF0sZV8/tRwgUi8QDbPujMD7VsH3P0IcVbMgYYq6562M/OGH+XNuaKipN+detjjHBvDq3GGLo3YqyHcH0OUhzTDgWdKXc085TwsQahsQv+cVHMrKYgNm1ECOSS0PaFJi8gymCog63fJGHBXBaBWuAElEUJmV8NHcJoBQNIkmUBNgOlpRM74vvSmJ/ICI4fXSBEo8ASLWJNqAzSarMmvmtgUz5dma5KK+vQb9TOzZUyhxXP2hf6isHSCfO8C8dAD920J1JbvbYReAZe1vwC5gX4O94J238WsxXQzI47hrXQGiRjKpvbWUKAAAAABJRU5ErkJggg==";
  string private constant SUIT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAElBMVEVjb2wKFh8PHiyQBQAZKDb09/M4xg+kAAAAAXRSTlMAQObYZgAAAPhJREFUSMftlEtuwzAMRJ1F9pWiHIADXiCLHsAED9Cg8P2v0pFiI0jNSItsPStJfCL1nWk6dChUWpa0tYEAuE7TfWurDYA8BJ4lAHy1EVx/zncgURB2sZZhf60qv99ZDTWE7Gy9ltkAZSgzyJaEANwl1/AesMtN62yXYooAcLlxODMDgymZzv8AFVG34io6hxnabMvKDN7WMO8BI1B3gdy2uwNSnefFllVBhscphJfNo0ECAXkDHDoUK/SG18c3AmRU4h1w4k+Q6hd0h7hMs4r6R+sL7yyR/7L39B/O0AVYYO4B1Rms9DMUG6zBexloggLp3EfoDR/pD84DPQp5evZaAAAAAElFTkSuQmCC";
  string private constant LUMBER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAHlBMVEUAAABgMhCSLidiQSi6OjFkY2LRVk37zFfc3Nzp6elLjlLzAAAAAXRSTlMAQObYZgAAANtJREFUSMftlL8KwjAQh6O+QGulu5gHsFZ0tVc87C7uxRPs7BuIS1fp0LytsVLon2tFEEHIl+WGH98dJBchDAaWuRCDsgbgA6OyJmICViXAGqxKC8aAuBQiJnKFCBGJUFMLSLnYDEOApZQzKQGkpmlIsiPRCjHoMIyj68sw7TbEhaFzht01AJj0zXDTM7g9huj+xnDOXoZApfoolbYNYWGYsneJuE+yE9EBccsGbM9ZXxzftn3PNk/f8AHsZldh/4ZvGkgD0NiqegNmq5qG1l7+neH5L+QqVz+8/AfiPlMwOCAUmQAAAABJRU5ErkJggg==";
  string private constant COWBOY =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAIVBMVEUAAAAkFwY4JwqOHQqmIwhvNxEMVWqJQBIVWm8TZnr+1QAbz5SLAAAAAXRSTlMAQObYZgAAASxJREFUSMftlLFOwzAQhiPxBFnZyMiE1DwAUirlAaqLKx4gcvcepiui7t2K1HC38qSYFqrGdRMxsOXLkEj+8vu3EjvLJiaSwMNN+fusnBAWWXYSyCaE9ZnAqQR4nJ0Eq5fD+FLNSgCsSiBhLxr1MG7zVs0RzaJGq2JJhXqCQyfz0jlTrx1zx8ocJ+DzR20w3JGsshCvooSn5hUNgnNOrJKI7wvGmOUuvB8uFBIVFo5Wgc37QUD0ItwGog6u2YX47xLCFIgT3CEBggjtDz1BAZotgO7BbJLfsiiK+8/iSFLI8/z2Lj8y/foTf0B0RPA0liAjgvrhYQ57jgZ6KOlKPfHAGsLWl4EexGI9ddeFUIE8d/b6FOyZ4rPhnLb1zDba2b0ORJenSz8hcTb8L1/HE4qVeT7A/AAAAABJRU5ErkJggg==";
  string private constant HIGHVIS_JACKET =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAGFBMVEUAAACcnpv7mQD/pAW8vrvCxMHy+gD4/wDT7TsBAAAAAXRSTlMAQObYZgAAAPBJREFUSMftlEGOwjAMRVmVda+AJQ5gS+UCcXsBe9ii6TTdIqDN9XE1KhLUpRfIX0Xy0/d3oni3y8pyhdc9zGdlFyhoPktwALgWh5eDeA6X4tVCdFEmoMueTPeKmIVFFzngcbYWdD9h4BAM+myDXQ0TcCTlidCwcGjQgNuJVIWVP3JY9+EMRNBW6F5Tin1XpzHG2EcXKMvyUZf/coHYp64ZYz+OKbkAIVlIuw2bwn8qwr/aQtJvBb4DwPCDeMB2xQEIhsampHbFISvLl/Nx3xV4A+AtB+WNsu0G+ZJDJASx7bAOWF00fHGYdoMq5+d+1xN/Fj0+ISur7wAAAABJRU5ErkJggg==";
  string private constant POLICE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAIVBMVEUAAAAGGzMKJkICKUsGLE0eKDMqNUCwsq72yzL23DTj5eFBYsbWAAAAAXRSTlMAQObYZgAAARdJREFUSMftlEFOwzAQRXMF21CJpf9E2XsGWcCONFdI92mEe4NegCNwArY5JTYqC6dxEELd5S0sS3n+HjmjqaqNjUWaqjr+7EVuLtC1IOKn6fi9jiJCCrMUJv/yOQo8y5Fpj87CZgJx48zI7Ec/gFrgVbs8Ad49xLOnEM5we9teC8MuRCFEWGB1NxdoUKfA9q3vDyw1687kRWoa7vuDuJSg6dHWrUEmhDDs4v0hJRiq27qV/AqN9Ak2JRgnCkqpvAYOIdbASZsuzGpoQhgBH9fFn60uxGeWrfU3/sCvDXNzAYp4tXF1B3764LJwB6bnd3ZloTYcKQtx9BBjVdDMAIpCmgtC4BVBQyCqKMTBEF/BmqKwOBv+xRclPU913ozfnwAAAABJRU5ErkJggg==";
  string private constant DOCTOR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAIVBMVEUAAABNTU0SYKEVbriournH2dnW4+Pp6enu7u7y8vL09PQCAr0yAAAAAXRSTlMAQObYZgAAAU9JREFUSMftlEFugzAQRVkmNylHYJ9F0n2P0DtkmaqVYrxqQxb+cwLPP2W/Q1OVyDSq1CUfBAae/e0xM02zaFFV583Grm2yAmya9eO17VYBds16d20DdwD692sjDuphwO59vTXwIvNyHQGwABQwdFvCSD3QaDbawHLBHHg7tU/6ap70dNaL0SbbXtfgJqB7Vj+1NNxZt3El4SiHZhXgL0ObyJ7IDv9wYZM1mOWhfaH39ER3K8cUYD51UYAjEa654AZAGrro7CELo5Zp03CbyyK6RTAH9CGFkCcAmU5tNGiE1OurFG+AMgdZOHJ1s+F4fVCIo8jl11/0B1Vrw09Va8Pk58MdwOYsVlDKYVIbboBLxrmSSnnrtSGiqziMp1XncfRopVBAXlVgtQ/hULJaB3+JgpuSez4WWofNWXwFuvSnzwJBpQEhhnlA6lMO/7f5n/dF3uKgDgDjAAAAAElFTkSuQmCC";
  string private constant SCARF =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVlLWcTXHw0fqUlkclQ/2RTAAAAAXRSTlMAQObYZgAAAD5JREFUOMtjYBgFmOBdHJpAAzOagAO6wKtqVP6y37d2vZuHJBCWuT1yWxiKGml0e9nQBbjRBVhGI2cUDCIAAPcdC0Sriwc2AAAAAElFTkSuQmCC";

  // Front view
  string private constant FRONT_STRAPPY_TOP =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAElBMVEUAAAB5QYZpOXRaMWM8BEk2B0FPX/j/AAAAAXRSTlMAQObYZgAAAEFJREFUGNNjYKAaYGRgEMDBEBRgFAQzlIAAzDBSNlIGM4yBAMwQNjY2BDNcgADMCAUCMEMICFAZykBAiAE3hxIAAIn5CUPRP/A/AAAAAElFTkSuQmCC";
  string private constant FRONT_CHEF =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAGFBMVEUAAADp7vDk5uPh5ungISLNFB0yMzHM2dqz5iDyAAAAAXRSTlMAQObYZgAAAGRJREFUGNO9jTEKwzAQBO8LcybuFxnUS0VqF35ACH6A/ANjiL6fU94QvM3CDOya/Sl42jaQwbI/VjAnvXg7Q6FJbijNNGkoCYUqOWqokmeOILUOUqtd3U/oz9j2j7ffieeYuzVfCIcMvEFIXXoAAAAASUVORK5CYII=";
  string private constant FRONT_PREHISTORIC =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAElBMVEUAAAD2yXDspBSEYBtjSBPhnhV+54yIAAAAAXRSTlMAQObYZgAAAFlJREFUGNNjYKAmYIQxhKC0oAmUFgqG0KKmqmBGsGGwK5ihahIaBGYYhapC1DiHukJ0OSmpKkPUqDgpgRlKyk4Q7SZKSoJghouRogBEVyCEZggSgNlNDR8BADOYCcf2m7C4AAAAAElFTkSuQmCC";
  string private constant FRONT_TSHIRT_BLACK =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAAAAAA+4qcQAAAAAnRSTlMAAHaTzTgAAABfSURBVCjP3czBCcNAEEPRt5rUtLj/S8A9zZLD2iYlhOgi9IXEb2gcVvUJjoUxFe00qd6gZdlREp2gtKQMmKC8kfu9aDcopas9oPXVXyDUXl1g0fL1AbW2vyBLei/+Sh92QxnEYz6W1wAAAABJRU5ErkJggg==";
  string private constant FRONT_TSHIRT_WHITE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAQAAACxgDBHAAAAgElEQVQ4y+3Q2wrDIBCE4c8asND3f9RCJBV7kcOakgfoRRZEdMad3+UuSEunKapniuult90wdwqoyK/GG4o6Giqy/dUukqW1WQZtEDMmH0fu3IOgIG3K45c6eH4MZVt1IMB1BI5PHx3yEBD7YGgxi2uGYGmn8xQR6zzqKeCuf6ovmrclCB/qexQAAAAASUVORK5CYII=";
  string private constant FRONT_TSHIRT_BLUE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAABmjfdhifZqkPe4/L/QAAAAAXRSTlMAQObYZgAAAEBJREFUCNdjYCASRDcwrmJY/0LrFcO6WetWMmRGvYplYFi1Hiiz6h2QeLcLxFoFJLJXg1izQMQrIJG5nlgbsAIAPkMTzjoNkgwAAAAASUVORK5CYII=";
  string private constant FRONT_VERTICAL_RED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAD1BMVEUAAADt7+vaT1D6/Png4t+h3+a4AAAAAXRSTlMAQObYZgAAAC5JREFUGNNjYKASEDIyYGBgMjJiMIICBEPISAhICRkBVYH5DPgZTlikhNCk6AYAf9ELa7EDmbwAAAAASUVORK5CYII=";
  string private constant FRONT_VERTICAL_GREEN =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAD1BMVEUAAADt7+s4xmP6/Png4t9g4G7rAAAAAXRSTlMAQObYZgAAAC5JREFUGNNjYKASEDIyYGBgMjJiMIICBEPISAhICRkBVYH5DPgZTlikhNCk6AYAf9ELa7EDmbwAAAAASUVORK5CYII=";
  string private constant FRONT_VERTICAL_ORANGE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAD1BMVEUAAAD5+/j/oxjslA3g4t9iQy2/AAAAAXRSTlMAQObYZgAAADZJREFUGNNjYKASEBIWYGBgEhICMoRAQBjKEAaKQGghkCohMIXKEEYVccKtxklIWJhaDiYOAAAMrAS1M4ONyAAAAABJRU5ErkJggg==";
  string private constant FRONT_TURTLENECK_BLACK =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAAAAAA+4qcQAAAAAnRSTlMAAHaTzTgAAABpSURBVCjPzdCxDQNBCETRdwiCbesKd1sbQOBgT67Akj0/+iMmgf/IdXf12gdK0DUOJTtYnasPCPCZPMXjZamAx7NsYT0XldNk2MrxhMizqZzcmNh2r71MzrL1BXdOmpwXEoxhfv3Gr+cNlQs5SgvhgjUAAAAASUVORK5CYII=";
  string private constant FRONT_TURTLENECK_ORANGE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAAD3mTn2jCD4plD1RLbEAAAAAXRSTlMAQObYZgAAAElJREFUCNdjYCASpL17t5QhMy0tjyHv9+51DHnv3gGJ3Tv3AlnPKxnqds/dzZC7rnw3w9ud93YyrHpbvoqBofwuUF9oKLE2YAUASgUcgbsGDRoAAAAASUVORK5CYII=";
  string private constant FRONT_STRIPE_RED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAFVBMVEUAAADt7+z3+fboSC76UDL+//zg4t8rmtWlAAAAAXRSTlMAQObYZgAAAFxJREFUGNNjYKASEFR2YGBgVDFhMHF2dlRScXFmMDFWDFVxMVZkEFIUBPIFA4GqTExcQsHKTVyCIAyjUFVnMEM1xMUEzEhxcVGFqDFRhDKURCFqkhSdjanlYOIAAHH5DOZvM6uHAAAAAElFTkSuQmCC";
  string private constant FRONT_STRIPE_BLUE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAFVBMVEUAAADt7+z3+fYneeErhfX+//zg4t8twd8zAAAAAXRSTlMAQObYZgAAAFxJREFUGNNjYKASEFR2YGBgVDFhMHF2dlRScXFmMDFWDFVxMVZkEFIUBPIFA4GqTExcQsHKTVyCIAyjUFVnMEM1xMUEzEhxcVGFqDFRhDKURCFqkhSdjanlYOIAAHH5DOZvM6uHAAAAAElFTkSuQmCC";
  string private constant FRONT_STRIPE_ORANGE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAFVBMVEUAAADt7+z3+fbrkw3/oxj+//zg4t+EruBNAAAAAXRSTlMAQObYZgAAAFxJREFUGNNjYKASEFR2YGBgVDFhMHF2dlRScXFmMDFWDFVxMVZkEFIUBPIFA4GqTExcQsHKTVyCIAyjUFVnMEM1xMUEzEhxcVGFqDFRhDKURCFqkhSdjanlYOIAAHH5DOZvM6uHAAAAAElFTkSuQmCC";
  string private constant FRONT_SUIT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAElBMVEUAAAAKFh8PHiz09/MZKDaQBQC6OIC8AAAAAXRSTlMAQObYZgAAAGBJREFUGNO1jYEJgDAMBCMuYCoOkOcHUIoLhC5Q3H8Xk3YFfcJzHCER+SgF+7leMCnN7idK4AmEcIIL4UePEmqzDk1Ds2GcXlrslASnSa109VrjdprxhFAMwLZM0DH/5QXVxg9lyNDWVAAAAABJRU5ErkJggg==";
  string private constant FRONT_LUMBER =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAHlBMVEUAAADRVk26OjFiQShgMhCSLifp6enc3NxkY2L7zFc4dVrNAAAAAXRSTlMAQObYZgAAAFVJREFUGNNjYKASEBIyYmAQERJiUFU1VWBVVlUFiYglCYNFXNVK4SJQNeqlKlCRIogaU7VUkEhamZF4knBaGdBIoIgy2OwmsSQJMMPZcrIztRxMHAAAU3sPFfsn/DYAAAAASUVORK5CYII=";
  string private constant FRONT_COWBOY =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAIVBMVEUAAAAVWm8TZnoMVWqJQBKmIwiOHQpvNxH+1QA4JwokFwZY6uHRAAAAAXRSTlMAQObYZgAAAG9JREFUGNNjYKASEBJ2DEtLFVJkUDR0Eg0LVTJiUBZyUQxNVRJiUBJyd1YJUTRkUBKsKJZ0VxRkUFQqKRRxFxZiUBRyL9YEMQQFXYpFXASVGIyNQSLGxkAjy4vFy8Fmz5zRORPMWLVi1ipqOZg4AAAIXRUILf2sbAAAAABJRU5ErkJggg==";
  string private constant FRONT_HIGHVIS_JACKET =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAGFBMVEUAAADCxMG8vrv/pAXy+gD4/wD7mQCcnpvRgHh+AAAAAXRSTlMAQObYZgAAAF1JREFUGNNjYKASEFI0dmA1FlJkUFJKDhJNU1JiUFQyc1RJVhICSiUHqZoBpRgYjANFk8HKXR1VQsGM8iCVcjAj1FE1BMwwBioGM8ycVCCKkwNFzKAMVWNqOZg4AAAc8g4MOkwg4gAAAABJRU5ErkJggg==";
  string private constant FRONT_POLICE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAHlBMVEUAAAACKUsKJkIqNUDj5eEGLE0GGzP23DSwsq4eKDN1tAz/AAAAAXRSTlMAQObYZgAAAHFJREFUGNOtzjEOwyAQBMD9AofjnkOmh5OQ3Z/c4x9gS0R5jyt+G5QXpPCUW+wu8BDjrGpyhMJ22iMTDvZzjeRQgp3fqRI45EsSOyyU2yon4RXyp9+VsRz5GgnDtK33uxmoiqyiOrq9SPyNtOGpw//5AsJIFHjeSLgRAAAAAElFTkSuQmCC";
  string private constant FRONT_DOCTOR =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAIVBMVEUAAADy8vL09PSournu7u4VbrgSYKHH2dnW4+NNTU3p6elNMf8JAAAAAXRSTlMAQObYZgAAAIBJREFUGNOtz8ENwjAMBdCPlAFqk0TiaCsLVOoAaTCHcssIkdiBEViEQQnJCODTk/1ly8CfimVdThsLlNdQN1HQ+RrbU2igvogglyM0TwzhFNohHZpiLcpQ8aEWVuzWR8U8zHzssL77mxlH6PbQiexoQLObnQTMzBu4D2TA/fzWB4aNEdL4EWwpAAAAAElFTkSuQmCC";
  string private constant FRONT_SCARF =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAAAlkck0fqUTXHy1QV4JAAAAAXRSTlMAQObYZgAAACBJREFUCNdjYCAWRFYBiddzQUxLEMEHIjhBBA/RZpAOADMCAriGZfwcAAAAAElFTkSuQmCC";

  address public tops2;

  constructor(address _tops2) {
    tops2 = _tops2;

    _tiers = [
      500,
      1000,
      1400,
      1800,
      2100,
      2400,
      2700,
      3000,
      3300,
      3600,
      3900,
      4200,
      4500,
      4800,
      5100,
      5400,
      5700,
      6000,
      6300,
      6600,
      6900,
      7200,
      7500,
      7800,
      8100,
      8300,
      8500,
      8700,
      8900,
      9100,
      9290,
      9470,
      9620,
      9720,
      9820,
      9870,
      9920,
      9970,
      9990,
      10000
    ];
  }

  function getName(uint256 traitIndex)
    public
    view
    override
    returns (string memory name)
  {
    if (traitIndex == 0) {
      return "";
    } else if (traitIndex == 1) {
      return "Strappy Top";
    } else if (traitIndex == 2) {
      return "Chef";
    } else if (traitIndex == 3) {
      return "Prehistoric";
    } else if (traitIndex == 4) {
      return "T-Shirt Black";
    } else if (traitIndex == 5) {
      return "T-Shirt White";
    } else if (traitIndex == 6) {
      return "T-Shirt Blue";
    } else if (traitIndex == 7) {
      return "Vertical Red";
    } else if (traitIndex == 8) {
      return "Vertical Green";
    } else if (traitIndex == 9) {
      return "Vertical Orange";
    } else if (traitIndex == 10) {
      return "Turtleneck Black";
    } else if (traitIndex == 11) {
      return "Turtleneck Orange";
    } else if (traitIndex == 12) {
      return "Stripe Red";
    } else if (traitIndex == 13) {
      return "Stripe Blue";
    } else if (traitIndex == 14) {
      return "Stripe Orange";
    } else if (traitIndex == 15) {
      return "Suit";
    } else if (traitIndex == 16) {
      return "Lumberjack";
    } else if (traitIndex == 17) {
      return "Cowboy";
    } else if (traitIndex == 18) {
      return "High-vis Vest";
    } else if (traitIndex == 19) {
      return "Police";
    } else if (traitIndex == 20) {
      return "Doctor";
    } else if (traitIndex == 21) {
      return "Scarf";
    } else {
      return ITrait(tops2).getName(traitIndex);
    }
  }

  function getSkinLayer(uint256 traitIndex, uint256)
    public
    view
    override
    returns (string memory layer)
  {
    if (traitIndex == 0) {
      return "";
    } else if (traitIndex == 1) {
      return STRAPPY_TOP;
    } else if (traitIndex == 2) {
      return CHEF;
    } else if (traitIndex == 3) {
      return PREHISTORIC;
    } else if (traitIndex == 4) {
      return TSHIRT_BLACK;
    } else if (traitIndex == 5) {
      return TSHIRT_WHITE;
    } else if (traitIndex == 6) {
      return TSHIRT_BLUE;
    } else if (traitIndex == 7) {
      return VERTICAL_RED;
    } else if (traitIndex == 8) {
      return VERTICAL_GREEN;
    } else if (traitIndex == 9) {
      return VERTICAL_ORANGE;
    } else if (traitIndex == 10) {
      return TURTLENECK_BLACK;
    } else if (traitIndex == 11) {
      return TURTLENECK_ORANGE;
    } else if (traitIndex == 12) {
      return STRIPE_RED;
    } else if (traitIndex == 13) {
      return STRIPE_BLUE;
    } else if (traitIndex == 14) {
      return STRIPE_ORANGE;
    } else if (traitIndex == 15) {
      return SUIT;
    } else if (traitIndex == 16) {
      return LUMBER;
    } else if (traitIndex == 17) {
      return COWBOY;
    } else if (traitIndex == 18) {
      return HIGHVIS_JACKET;
    } else if (traitIndex == 19) {
      return POLICE;
    } else if (traitIndex == 20) {
      return DOCTOR;
    } else if (traitIndex == 21) {
      return SCARF;
    } else {
      return ITrait(tops2).getSkinLayer(traitIndex, 0);
    }
  }

  function getFrontLayer(uint256 traitIndex, uint256)
    public
    view
    override
    returns (string memory layer)
  {
    if (traitIndex == 0) {
      return "";
    } else if (traitIndex == 1) {
      return FRONT_STRAPPY_TOP;
    } else if (traitIndex == 2) {
      return FRONT_CHEF;
    } else if (traitIndex == 3) {
      return FRONT_PREHISTORIC;
    } else if (traitIndex == 4) {
      return FRONT_TSHIRT_BLACK;
    } else if (traitIndex == 5) {
      return FRONT_TSHIRT_WHITE;
    } else if (traitIndex == 6) {
      return FRONT_TSHIRT_BLUE;
    } else if (traitIndex == 7) {
      return FRONT_VERTICAL_RED;
    } else if (traitIndex == 8) {
      return FRONT_VERTICAL_GREEN;
    } else if (traitIndex == 9) {
      return FRONT_VERTICAL_ORANGE;
    } else if (traitIndex == 10) {
      return FRONT_TURTLENECK_BLACK;
    } else if (traitIndex == 11) {
      return FRONT_TURTLENECK_ORANGE;
    } else if (traitIndex == 12) {
      return FRONT_STRIPE_RED;
    } else if (traitIndex == 13) {
      return FRONT_STRIPE_BLUE;
    } else if (traitIndex == 14) {
      return FRONT_STRIPE_ORANGE;
    } else if (traitIndex == 15) {
      return FRONT_SUIT;
    } else if (traitIndex == 16) {
      return FRONT_LUMBER;
    } else if (traitIndex == 17) {
      return FRONT_COWBOY;
    } else if (traitIndex == 18) {
      return FRONT_HIGHVIS_JACKET;
    } else if (traitIndex == 19) {
      return FRONT_POLICE;
    } else if (traitIndex == 20) {
      return FRONT_DOCTOR;
    } else if (traitIndex == 21) {
      return FRONT_SCARF;
    } else {
      return ITrait(tops2).getFrontLayer(traitIndex, 0);
    }
  }

  function _getLayer(
    uint256,
    uint256,
    string memory
  ) internal pure override returns (string memory layer) {
    return "";
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICritterzMetadata {
  function getMetadata(
    uint256 tokenId,
    bool staked,
    string[] calldata additionalAttributes
  ) external view returns (string memory);

  function getPlaceholderMetadata(
    uint256 tokenId,
    bool staked,
    string[] calldata additionalAttributes
  ) external view returns (string memory);

  function seed() external view returns (uint256);
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
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./ITrait.sol";

abstract contract Trait is ITrait {
  bool internal _frontArmorTraitsExists = false;
  uint256[] internal _tiers;

  /*
  READ FUNCTIONS
  */

  function getSkinLayer(uint256 traitIndex, uint256 layerIndex)
    public
    view
    virtual
    override
    returns (string memory layer)
  {
    return _getLayer(traitIndex, layerIndex, "");
  }

  function getFrontLayer(uint256 traitIndex, uint256 layerIndex)
    external
    view
    virtual
    override
    returns (string memory frontLayer)
  {
    return _getLayer(traitIndex, layerIndex, "FRONT_");
  }

  function getFrontArmorLayer(uint256 traitIndex, uint256 layerIndex)
    external
    view
    virtual
    override
    returns (string memory frontArmorLayer)
  {
    return _getLayer(traitIndex, layerIndex, "FRONT_ARMOR_");
  }

  function sampleTraitIndex(uint256 rand)
    external
    view
    virtual
    override
    returns (uint256 index)
  {
    rand = rand % 10000;
    for (uint256 i = 0; i < _tiers.length; i++) {
      if (rand < _tiers[i]) {
        return i;
      }
    }
  }

  function _layer(string memory prefix, string memory name)
    internal
    view
    virtual
    returns (string memory trait)
  {
    bytes memory sig = abi.encodeWithSignature(
      string(abi.encodePacked(prefix, name, "()")),
      ""
    );
    (bool success, bytes memory data) = address(this).staticcall(sig);
    return success ? abi.decode(data, (string)) : "";
  }

  function _indexedLayer(
    uint256 layerIndex,
    string memory prefix,
    string memory name
  ) internal view virtual returns (string memory layer) {
    return
      _layer(
        string(abi.encodePacked(prefix, _getLayerPrefix(layerIndex))),
        name
      );
  }

  function _getLayerPrefix(uint256)
    internal
    view
    virtual
    returns (string memory prefix)
  {
    return "";
  }

  /*
  PURE VIRTUAL FUNCTIONS
  */

  function _getLayer(
    uint256 traitIndex,
    uint256 layerIndex,
    string memory prefix
  ) internal view virtual returns (string memory layer);

  /*
  MODIFIERS
  */
}