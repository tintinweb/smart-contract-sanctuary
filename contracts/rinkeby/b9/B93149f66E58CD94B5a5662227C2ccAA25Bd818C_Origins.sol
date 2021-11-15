// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Origins is ERC721Enumerable, ReentrancyGuard, Ownable {
  bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  string[165] private CITIES = [
    "Black Hollow",
    "Zumka",
    "Oakheart",
    "Erast",
    "Millstone",
    "Ered",
    "Boatwright",
    "Embertown",
    "Northtown",
    "Glaskerville",
    "South Warren",
    "Frostenvale",
    "The Gale",
    "Ramshorn",
    "Zeffari",
    "Lakestown",
    "Aerilon",
    "Gulltown",
    "Xynnar",
    "Doonatel",
    "Saker Keep",
    "Pinnella Pass",
    "Greenloft",
    "Lamorra",
    "Willowdale",
    "Arnor",
    "Seameet",
    "Windrip",
    "City of Fire",
    "Yarrin",
    "Doriath",
    "Hull",
    "Goldcrest",
    "Pineland",
    "Eredluin",
    "Oakensword",
    "Brilthor",
    "New Cresthill",
    "Icemeet",
    "Brickelwhyte",
    "Wolfsrealm",
    "Ironforge",
    "Erede",
    "Wellspring",
    "Veritas",
    "Avaglade",
    "Jongvale",
    "Lothlann",
    "Nuxvar",
    "Far Water",
    "Camorrus",
    "Leeside",
    "Hollyhead",
    "Northpass",
    "Briar Glen",
    "Broken Shield",
    "Pran",
    "Eastford",
    "Eastwatch",
    "Aquarin",
    "Lochley",
    "Ecrin",
    "Mountmend",
    "Deathfall",
    "Firecrow",
    "Northstead",
    "Wintervale",
    "Aramoor",
    "Moonbright",
    "Hwen",
    "Westwend",
    "Goldenleaf",
    "Frostford",
    "Freevale",
    "Ethermoor",
    "Harsengaard",
    "Rivermouth",
    "Frostfangs",
    "Darendale",
    "Beleriand",
    "Adurant",
    "Nogrod",
    "Hillfar",
    "Suilwen",
    "Fallenedge",
    "Rhuin",
    "Pony Run",
    "Hogsfeet",
    "Nargorthon",
    "Westend",
    "Elbright",
    "Haran",
    "Dry Gulch",
    "Swordbreak",
    "The Last Battle",
    "Cullfield",
    "Snowforge",
    "Tarrin",
    "East Armistice",
    "Legolin",
    "Valley of Dusk",
    "Vertrock",
    "Trudid",
    "Dorthonion",
    "Anfauglith",
    "Three Streams",
    "Riverwind",
    "Rhaunar",
    "Vale of Doom",
    "Fangorn",
    "Amram",
    "Duarudelf",
    "Duskendale",
    "Red Hawk",
    "Nearon",
    "Battlecliff",
    "Yellowseed",
    "Bruinen",
    "Pyreacre",
    "Queenstown",
    "Orrinshire",
    "Rhudaur",
    "Doveseal",
    "Whiterun",
    "Dorlomin",
    "Merriwich",
    "Lakeshore",
    "Bullmar",
    "Silverkeep",
    "Carran",
    "Firebend",
    "Linesse",
    "Bay of Balar",
    "Ashdrift",
    "Zao Ying",
    "Greenflower",
    "Stonewatch",
    "Ekaia",
    "Greenglade",
    "Ubbin Falls",
    "Lullin",
    "Eribourne",
    "Pavv",
    "Irragin",
    "Old Ashton",
    "Arrendyll",
    "Thales",
    "Ozryn",
    "Whiteridge",
    "Wintergale",
    "Blue Field",
    "Last Lock",
    "Coalfell",
    "Darkwell",
    "Dimbar",
    "Sundance",
    "Quan Ma",
    "Eldarmar",
    "Shiny Ship",
    "Azmar",
    "Wolfden",
    "Strong Oak",
    "Harlen",
    "Iron Hills",
    "Easthaven"
  ];

  uint256 private constant TOTAL_CITIES = 165;
  uint256 private constant TOTAL_PROVINCES = 15;
  uint256 private constant TOTAL_REALMS = 5;
  uint256 private constant TOTAL_SKILLS = 5;

  string[5] private realms = ["Zallafen", "Karatana", "Orune", "Melvoran", "Goth"];
  string[5] private talents = ["Persuade", "Heal", "Discover", "Stealth", "Power"];

  mapping(uint256 => string[11]) private cities;
  mapping(uint256 => string[3]) private provinces;

  uint256[6] private colorProbility = [4, 14, 29, 48, 71, 99];

  constructor() ERC721("Origins", "ORIGINS") Ownable() {
    provinces[0] = ["Feroborn", "Trobolove", "Sandiri"];
    provinces[1] = ["Emoran", "Vulcor", "Elo"];
    provinces[2] = ["Firthsire", "Pronos", "Cardaseth"];
    provinces[3] = ["Phoruso", "Glitoa", "Korutia"];
    provinces[4] = ["Nordrine", "Hrumara", "Anora"];
    for (uint256 i = 0; i <= 14; i++) {
      uint256 j = i * 10;

      if (i != 0) {
        j = j + i;
      }

      uint256 limit = j + 10;
      uint256 index = 0;

      for (; j <= limit; j++) {
        cities[i][index] = CITIES[j];
        index++;
      }
    }
  }

  function getRealm(uint256 tokenId) public view returns (uint256, string memory) {
    uint256 index = _getRand(tokenId, 1) % TOTAL_REALMS;

    return (index, realms[index]);
  }

  function getProvince(uint256 tokenId, uint256 realmIndex) public view returns (uint256, string memory) {
    uint256 index = _getRand(tokenId, 2) % TOTAL_PROVINCES;

    return (index, provinces[realmIndex][index]);
  }

  function getCity(uint256 tokenId, uint256 provinceIndex) public view returns (string memory) {
    return cities[provinceIndex][_getRand(tokenId, 3) % TOTAL_CITIES];
  }

  function getTalent(uint256 realmIndex) public view returns (string memory) {
    return talents[realmIndex];
  }

  function getTalentScore(uint256 tokenId) public pure returns (uint256) {
    return _getRand(tokenId, 4) % 100;
  }

  function claim(uint256 tokenId) public nonReentrant {
    require(tokenId > 0 && tokenId <= 9800, "Token ID invalid");
    require(!_exists(tokenId), "Token ID invalid");

    _safeMint(_msgSender(), tokenId);
  }

  function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
    require(tokenId > 9800 && tokenId < 10000, "Token ID invalid");
    require(!_exists(tokenId), "Token ID invalid");

    _safeMint(owner(), tokenId);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string[18] memory parts;

    (uint256 realmIndex, string memory realm) = getRealm(tokenId);
    (uint256 provinceIndex, string memory province) = getProvince(tokenId, realmIndex);
    string memory city = getCity(tokenId, provinceIndex);
    string memory talent = string(abi.encodePacked(getTalent(realmIndex), " ", getTalentScore(tokenId)));

    parts[
      0
    ] = '<?xml version="1.0" encoding="UTF-8"?><svg width="750px" height="750px" viewBox="0 0 750 750" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><g stroke="none" stroke-width="1" fill="none" fill-rule="evenodd"><rect fill="#231D39" x="0" y="0" width="750" height="750"></rect><g transform="translate(60.000000, 35.000000)" fill="#FFFFFF" fill-rule="nonzero"><g transform="translate(0.000000, 15.000000)"><path d="M41.7518248,77.1077844 C39.1698869,73.5756487 36.8398454,69.9489022 34.7617003,66.2275449 C31.927866,60.9293413 29.3774152,55.4734531 27.1103478,49.8598802 L18.9866896,49.8598802 L18.9866896,77.1077844 L0,77.1077844 L0,1.89221557 L32.2112495,1.89221557 C35.0450837,1.95528942 37.878918,2.36526946 40.7127523,3.12215569 C44.1133534,4.13133733 47.2305711,5.77125749 50.0644053,8.04191617 C55.6061257,12.7093812 58.471447,18.6698603 58.6603693,25.9233533 C58.5973952,30.338523 57.4323744,34.3752495 55.165307,38.0335329 C52.5833691,41.9441118 49.214255,44.9716567 45.0579648,47.1161677 C47.7028768,52.0359281 50.5681981,56.798004 53.6539287,61.4023952 C57.2434521,66.7636727 60.9904108,71.9988024 64.8948046,77.1077844 L41.7518248,77.1077844 Z M18.9866896,36.2359281 L28.6217261,36.2359281 C31.6444826,36.299002 34.3208816,35.3844311 36.6509231,33.4922156 C38.6660942,31.6630739 39.7051667,29.3608782 39.7681408,26.5856287 C39.7051667,23.8734531 38.6031201,21.6027944 36.4620009,19.7736527 C34.1949334,18.0075848 31.6129956,17.093014 28.7161872,17.0299401 L18.9866896,17.0299401 L18.9866896,36.2359281 Z"></path><path d="M106.457707,20.057485 C110.173179,21.3189621 113.447832,23.2742515 116.281666,25.9233533 C119.052526,28.7616766 121.130671,32.041517 122.516101,35.7628743 C124.02748,39.9888224 124.783169,44.3409182 124.783169,48.8191617 C124.783169,53.360479 124.02748,57.7441118 122.516101,61.9700599 C121.130671,65.6914172 119.052526,68.9397206 116.281666,71.7149701 C113.447832,74.4271457 110.173179,76.3824351 106.457707,77.5808383 C103.371977,78.4638723 100.254759,78.9369261 97.1060541,79 C93.8943753,78.9369261 90.7456705,78.4638723 87.6599399,77.5808383 C83.9444683,76.3824351 80.6383283,74.4271457 77.74152,71.7149701 C74.9706598,68.9397206 72.8925147,65.6914172 71.5070846,61.9700599 C69.9957063,57.7441118 69.2715042,53.360479 69.3344783,48.8191617 C69.2715042,44.3409182 69.9957063,39.9888224 71.5070846,35.7628743 C72.8925147,32.041517 74.9706598,28.7616766 77.74152,25.9233533 C80.6383283,23.2742515 83.9444683,21.3189621 87.6599399,20.057485 C90.7456705,19.1744511 93.8943753,18.7013972 97.1060541,18.6383234 C100.254759,18.7013972 103.371977,19.1744511 106.457707,20.057485 Z M100.8845,62.7269461 C102.081008,61.8439122 103.088593,60.7401198 103.907256,59.4155689 C104.788894,57.7756487 105.418635,56.0095808 105.796479,54.1173653 C106.048376,52.3512974 106.205811,50.5852295 106.268785,48.8191617 C106.205811,47.1161677 106.048376,45.3816367 105.796479,43.6155689 C105.418635,41.7233533 104.788894,39.9572854 103.907256,38.3173653 C103.088593,36.9928144 102.081008,35.889022 100.8845,35.005988 C99.687992,34.2491018 98.4285101,33.8391218 97.1060541,33.7760479 C95.6576499,33.8391218 94.366681,34.2491018 93.2331473,35.005988 C91.9736654,35.889022 90.9345928,36.9928144 90.1159296,38.3173653 C89.2342923,39.9572854 88.6045513,41.7233533 88.2267067,43.6155689 C87.9748104,45.3816367 87.8488622,47.1161677 87.8488622,48.8191617 C87.8488622,50.5852295 87.9748104,52.3512974 88.2267067,54.1173653 C88.6045513,56.0095808 89.2342923,57.7756487 90.1159296,59.4155689 C90.9345928,60.8031936 91.9736654,61.906986 93.2331473,62.7269461 C94.366681,63.4838323 95.6576499,63.8622754 97.1060541,63.8622754 C98.4285101,63.8622754 99.687992,63.4838323 100.8845,62.7269461 Z"></path><path d="M162.756548,77.8646707 C158.978102,78.6215569 155.168169,79 151.32675,79 C148.303993,78.9369261 145.438672,78.3692615 142.730786,77.297006 C140.274796,76.1616766 138.196651,74.5532934 136.49635,72.4718563 C134.79605,70.1381238 133.631029,67.5205589 133.001288,64.6191617 C132.434521,62.0331337 132.182625,59.3840319 132.245599,56.6718563 L132.245599,-8.40312517e-15 L150.759983,-8.40312517e-15 L150.759983,52.3197605 C150.634035,54.653493 150.759983,56.9241517 151.137827,59.1317365 C151.389724,60.4562874 152.019465,61.5285429 153.02705,62.348503 C153.971662,63.1053892 155.073708,63.5784431 156.33319,63.7676647 C157.844568,64.0199601 159.387434,64.0830339 160.961786,63.9568862 L162.756548,77.8646707 Z"></path><path d="M184.765994,53.6443114 C185.206813,56.6087824 186.560756,59.0371257 188.827823,60.9293413 C190.150279,61.938523 191.598683,62.6954092 193.173036,63.2 C194.93631,63.7045908 196.762559,63.9253493 198.651782,63.8622754 C201.170746,63.8622754 203.658222,63.5153693 206.114212,62.8215569 C208.633176,62.1277445 211.057679,61.1816367 213.38772,59.9832335 L217.449549,72.4718563 C214.23787,74.742515 210.711321,76.4139721 206.869901,77.4862275 C203.091456,78.4954092 199.281523,79 195.440103,79 C191.031916,79 186.812652,78.2115768 182.78231,76.6347305 C179.129813,75.0578842 175.949621,72.8187625 173.241735,69.9173653 C170.596823,66.7636727 168.7076,63.2 167.574066,59.2263473 C166.692429,55.8203593 166.25161,52.3512974 166.25161,48.8191617 C166.188636,44.2778443 166.881351,39.8311377 168.329755,35.4790419 C169.715185,31.7576846 171.79333,28.5093812 174.564191,25.7341317 C177.460999,23.0850299 180.798626,21.1928144 184.577072,20.057485 C187.725776,19.1744511 190.968942,18.7013972 194.306569,18.6383234 C197.329326,18.7013972 200.289108,19.1744511 203.185917,20.057485 C206.649492,21.1928144 209.672248,23.053493 212.254186,25.639521 C214.836124,28.4147705 216.756834,31.6 218.016316,35.1952096 C219.338772,39.3580838 220,43.6155689 220,47.9676647 C220,49.9229541 219.937026,51.8151697 219.811078,53.6443114 L184.765994,53.6443114 Z M202.524689,42.8586826 C202.398741,40.4618762 201.580077,38.3489022 200.068699,36.5197605 C198.368398,34.7536926 196.32174,33.8391218 193.928725,33.7760479 C191.472735,33.9021956 189.363103,34.8167665 187.599828,36.5197605 C185.899528,38.2858283 184.923429,40.3988024 184.671533,42.8586826 L202.524689,42.8586826 Z"></path></g><polygon transform="translate(95.392136, 15.110538) rotate(-62.153664) translate(-95.392136, -15.110538) " points="89.0944127 -5.31770227 101.68986 -5.31770227 101.68986 35.5387792 89.0944127 35.5387792"></polygon></g><text id="Male-Demons-Chaotic" font-family="Georgia" font-size="28" font-weight="normal" line-spacing="44" fill="#FFFFFF"><tspan x="60" y="165" fill-opacity="60%" font-size="larger">Origin</tspan><tspan x="60" y="230" fill-opacity="100%" font-size="18px" text-decoration="underline">City</tspan><tspan x="60" y="265" fill-opacity="100%" font-size="smaller" fill="';
    parts[1] = _getColor(tokenId, 4);
    parts[2] = '">';
    parts[3] = city;
    parts[
      4
    ] = '</tspan><tspan x="60" y="315" fill-opacity="100%" font-size="18px" text-decoration="underline">Province</tspan><tspan x="60" y="350" fill-opacity="100%" font-size="smaller" fill="';
    parts[5] = _getColor(tokenId, 5);
    parts[6] = '">';
    parts[7] = province;
    parts[
      8
    ] = '</tspan><tspan x="60" y="400" fill-opacity="100%" font-size="18px" text-decoration="underline">Realm</tspan><tspan x="60" y="435" fill-opacity="100%" font-size="smaller" fill="';
    parts[9] = _getColor(tokenId, 6);
    parts[10] = '">';
    parts[11] = realm;
    parts[12] = '</tspan><tspan x="60" y="485" fill-opacity="100%" font-size="12px" fill="';
    parts[13] = _getColor(tokenId, 7);
    parts[14] = '">';
    parts[15] = talent;
    parts[16] = "</tspan></text>";
    parts[17] = "</g></svg>";

    string memory output =
      string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
    output = string(abi.encodePacked(output, parts[7], parts[8], parts[9], parts[10], parts[11], parts[12], parts[13]));
    output = string(abi.encodePacked(output, parts[14], parts[15], parts[16], parts[17]));

    string memory atrrOutput = _makeAttributeParts(city, province, realm);
    string memory json =
      _encode(
        bytes(
          string(
            abi.encodePacked(
              '{"name": "Role Origin #',
              _toString(tokenId),
              '", "description": "Origin adds to the dynamics of a Role. Each location can provide the Role with varying abilities.", "image": "data:image/svg+xml;base64,',
              _encode(bytes(output)),
              '"',
              ',"attributes":',
              atrrOutput,
              "}"
            )
          )
        )
      );
    output = string(abi.encodePacked("data:application/json;base64,", json));

    return output;
  }

  function _toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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

  function _makeAttributeParts(
    string memory city,
    string memory province,
    string memory realm
  ) internal pure returns (string memory) {
    string[7] memory attrParts;
    attrParts[0] = '[{ "trait_type": "City", "value": "';
    attrParts[1] = city;
    attrParts[2] = '" }, { "trait_type": "Province", "value": "';
    attrParts[3] = province;
    attrParts[4] = '" }, { "trait_type": "Realm", "value": "';
    attrParts[5] = realm;
    attrParts[6] = '" }]';

    string memory atrrOutput =
      string(
        abi.encodePacked(
          attrParts[0],
          attrParts[1],
          attrParts[2],
          attrParts[3],
          attrParts[4],
          attrParts[5],
          attrParts[6]
        )
      );

    return atrrOutput;
  }

  function _random(string memory salt) internal pure returns (uint256) {
    uint256 seed = uint256(keccak256(abi.encodePacked(salt)));

    return seed;
  }

  function _getColor(uint256 tokenId, uint256 salt) internal view returns (string memory) {
    uint256 rand = _random(string(abi.encodePacked(tokenId, salt)));

    uint256 colorScore = rand % 100;
    uint256 j = 0;
    for (; j < colorProbility.length; j++) {
      if (colorScore <= colorProbility[j]) {
        break;
      }
    }
    return _getColorFull(j + 1);
  }

  function _getColorFull(uint256 index) internal pure returns (string memory) {
    if (index == 1) {
      return "#ffc000";
    } else if (index == 2) {
      return "#c00000";
    } else if (index == 3) {
      return "#ed7d31";
    } else if (index == 4) {
      return "#5b9bd5";
    } else if (index == 5) {
      return "#70ad47";
    } else {
      return "#ffffff";
    }
  }

  function _getRand(uint256 tokenId, uint256 salt) internal pure returns (uint256 id) {
    uint256 rand = _random(string(abi.encodePacked(tokenId, salt)));

    return rand;
  }

  function _encode(bytes memory data) internal pure returns (string memory) {
    uint256 len = data.length;
    if (len == 0) return "";

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((len + 2) / 3);

    // Add some extra buffer at the end
    bytes memory result = new bytes(encodedLen + 32);

    bytes memory table = TABLE;

    assembly {
      let tablePtr := add(table, 1)
      let resultPtr := add(result, 32)

      for {
        let i := 0
      } lt(i, len) {

      } {
        i := add(i, 3)
        let input := and(mload(add(data, i)), 0xffffff)

        let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
        out := shl(224, out)

        mstore(resultPtr, out)

        resultPtr := add(resultPtr, 4)
      }

      switch mod(len, 3)
        case 1 {
          mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
        }
        case 2 {
          mstore(sub(resultPtr, 1), shl(248, 0x3d))
        }

      mstore(result, encodedLen)
    }

    return string(result);
  }
}

// SPDX-License-Identifier: MIT

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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

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

