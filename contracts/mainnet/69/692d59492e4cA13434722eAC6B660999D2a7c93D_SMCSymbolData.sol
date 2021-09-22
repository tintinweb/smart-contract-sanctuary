// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./ISMCSymbol.sol";

contract SMCSymbolData is ISMCSymbolData {
    string[] public japaneseZodiacs = [
        "NE (Rat)",
        "USHI (Ox)",
        "TORA (Tiger)",
        "U (Rabbit)",
        "TATSU (Dragon)",
        "MI (Snake)",
        "UMA (Horse)",
        "HITSUJI (Sheep)",
        "SARU (Monkey)",
        "YORI (Rooster)",
        "INU (Dog)",
        "I (Boar)"
    ];

    function JapaneseZodiacs()
        external
        view
        override
        returns (string[] memory)
    {
        return japaneseZodiacs;
    }

    string[] public CodesOfArts = [
        "Seditious",
        "Fastidious",
        "Malicious",
        "Audacious",
        "Pernicious",
        "Viscous",
        "Capricious",
        "Stratify",
        "Dignify",
        "Defy",
        "Satisfy",
        "Pacify",
        "Nullify"
    ];

    string[] public rarities = [
        "",
        "",
        "Stardust",
        "Soldier",
        "Ninja",
        "Shogun",
        "",
        "",
        "",
        ""
    ];

    function Rarities() external view override returns (string[] memory) {
        return rarities;
    }

    string[] public initials = [
        "A",
        "B",
        "C",
        "D",
        "E",
        "F",
        "G",
        "H",
        "I",
        "J",
        "K",
        "L",
        "M",
        "N",
        "O",
        "P",
        "Q",
        "R",
        "S",
        "T",
        "U",
        "V",
        "W",
        "X",
        "Y",
        "Z"
    ];

    function Initials() external view override returns (string[] memory) {
        return initials;
    }

    string[] public firstNames = [
        "Oichi",
        "Naka",
        "Nene",
        "Francisco",
        "Matsu",
        "Luis",
        "Shigezane",
        "Masamune",
        "Mancio",
        "Naotora",
        "Naomasa",
        "Ittetsu",
        "Naoie",
        "Hirotsuna",
        "Hidekatsu",
        "Eihime",
        "Oman",
        "Motonobu",
        "Kiyomasa",
        "Saizo",
        "Harunobu",
        "Ujisato",
        "Tsunamoto",
        "Akimasa",
        "Musashi",
        "Maria",
        "Yoshitaka",
        "Oribe",
        "Matabei",
        "Teruhime",
        "Go",
        "Kaihime",
        "Murashige",
        "Ukon",
        "Kanbei",
        "Mototaka",
        "Munehisa",
        "Yoshimoto",
        "Narimasa",
        "Kojiro",
        "Yoshimutsu",
        "Yoshitatsu",
        "Dosan",
        "Toshimitsu",
        "Tatsuoki",
        "Garasha",
        "Tadaoki",
        "Yusai",
        "Yasumasa",
        "Magoichi",
        "Nagayoshi",
        "Tokitsugu",
        "Masakage",
        "Kazutoyo",
        "Kansuke",
        "Yoritsuna",
        "Tsunenaga",
        "Bokuzen",
        "Katsuie",
        "Eitoku",
        "Okuni",
        "Hatsu",
        "Yukinaga",
        "Hideaki",
        "Takakage",
        "Enshu",
        "Hisahide",
        "Tadateru",
        "Tadanao",
        "Kagetora",
        "Kagekatsu",
        "Kenshin",
        "Nobutaka",
        "Nobuhide",
        "Nobutada",
        "Nobunaga",
        "Ranmaru",
        "Yukimura",
        "Masayuki",
        "Goemon",
        "Mitsunari",
        "Hidehisa",
        "Chiyo",
        "Rikyu",
        "Nagamasa",
        "Keiji",
        "Toshie",
        "Nagamori",
        "Yoshihide",
        "Yoshiteru",
        "Yoshiaki",
        "Toshikiyo",
        "Sessai",
        "Gyuichi",
        "Dokan",
        "Tadachika",
        "Masashige",
        "Yoshioki",
        "Yoshimune",
        "Sorin",
        "Kazumasu",
        "Terumasa",
        "Tsuneoki",
        "Hanbei",
        "Chacha",
        "Shirojiro",
        "Yoshikage",
        "Asahihime",
        "Motochika",
        "Tohaku",
        "Kanetsugu",
        "Sokyu",
        "Tsuruhime",
        "Sakon",
        "Yoshihiro",
        "Takatora",
        "Ieyasu",
        "Hidetada",
        "Tenkai",
        "Yoshihisa",
        "Katsuhisa",
        "Haruhisa",
        "Nohime",
        "Toramasa",
        "Sotatsu",
        "Yoshinobu",
        "Katsuyori",
        "Shingen",
        "Nobutora",
        "Kotaro",
        "Hanzo",
        "Masanori",
        "Kojuro",
        "Tomonobu",
        "Koroku",
        "Hideyoshi",
        "Hidenaga",
        "Hideyori",
        "Tsurumatsu",
        "Ujiyasu",
        "Ujimasa",
        "Soun",
        "Masanobu",
        "Tadakatsu",
        "Mitsuhide",
        "Terumoto",
        "Motonari",
        "Munenori",
        "Ginchiyo",
        "Yasuke"
    ];

    function FirstNames() external view override returns (string[] memory) {
        return firstNames;
    }

    string[] public nativePlaces = [
        "Omi",
        "Mino",
        "Hida",
        "Shinano",
        "Kozuke",
        "Shimotsuke",
        "Mutsu",
        "Wakasa",
        "Echizen",
        "Kaga",
        "Noto",
        "Etchu",
        "Echigo",
        "Sado",
        "Iga",
        "Ise",
        "Shima",
        "Owari",
        "Mikawa",
        "Totomi",
        "Suruga",
        "Izu",
        "Kai",
        "Sagami",
        "Musashi",
        "Awa",
        "Kazusa",
        "Shimousa",
        "Hitachi",
        "Yamato",
        "Yamashiro",
        "Settsu",
        "Kawachi",
        "Izumi",
        "Tanba",
        "Tango",
        "Tajima",
        "Inaba",
        "Hoki",
        "Izumo",
        "Iwami",
        "Oki",
        "Harima",
        "Mimasaka",
        "Bizen",
        "Bitchu",
        "Bingo",
        "Aki",
        "Suo",
        "Nagato",
        "Kii",
        "Awaji",
        "Sanuki",
        "Iyo",
        "Tosa",
        "Chikuzen",
        "Chikugo",
        "Buzen",
        "Bungo",
        "Hizen",
        "Higo",
        "Hyuga",
        "Osumi",
        "Satsuma",
        "Iki",
        "Tsushima",
        "Ezo",
        "Ryukyu",
        "Portugal",
        "Mozambique",
        "Joseon",
        "Netherlands",
        "England",
        "Ming",
        "Moon",
        "Underworld",
        "Unknown"
    ];

    function NativePlaces() external view override returns (string[] memory) {
        return nativePlaces;
    }

    string[] public colors = [
        "",
        "Red",
        "Green",
        "Blue",
        "Purple",
        "White",
        "Sakura",
        "Navy"
    ];

    function Colors() external view override returns (string[] memory) {
        return colors;
    }

    string[] public patterns = [
        "Ichimatsu",
        "Asanoha",
        "Seigaiha",
        "Uroko",
        "Yagasuri",
        "Shichiyoumon",
        "Mitsudomoe",
        "Sankuzushi",
        "Chidori",
        "Kikkou",
        "Plain"
    ];

    function Patterns() external view override returns (string[] memory) {
        return patterns;
    }

    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ISMCSymbolDescriptor {
    function tokenURI(ISMCManager manager, uint256 tokenId)
        external
        view
        returns (string memory);
}

interface ISMCSymbolData {
    function JapaneseZodiacs() external view returns (string[] memory);

    function Initials() external view returns (string[] memory);

    function Rarities() external view returns (string[] memory);

    function FirstNames() external view returns (string[] memory);

    function NativePlaces() external view returns (string[] memory);

    function Colors() external view returns (string[] memory);

    function Patterns() external view returns (string[] memory);
}

interface ISMCManager is IERC721 {
    function getRespect() external view returns (string memory);

    function getRespectColorCode() external view returns (uint256);

    function getCodesOfArt(uint256 tokenId)
        external
        view
        returns (string memory);

    function getRarity(uint256 tokenId) external view returns (string memory);

    function getRarityDigit(uint256 tokenId) external view returns (uint256);

    function getSamurights(uint256 tokenId) external view returns (uint256);

    function getName(uint256 tokenId) external view returns (string memory);

    function getNativePlace(uint256 tokenId)
        external
        view
        returns (string memory);

    function getJapaneseZodiac(uint256 tokenId)
        external
        view
        returns (string memory);

    function getColorLCode(uint256 tokenId) external view returns (uint256);

    function getColorL(uint256 tokenId) external view returns (string memory);

    function getColorRCode(uint256 tokenId) external view returns (uint256);

    function getColorR(uint256 tokenId) external view returns (string memory);

    function getPatternLCode(uint256 tokenId) external view returns (uint256);

    function getPatternL(uint256 tokenId) external view returns (string memory);

    function getPatternRCode(uint256 tokenId) external view returns (uint256);

    function getPatternR(uint256 tokenId) external view returns (string memory);

    function getActivatedKatana(uint256 tokenId)
        external
        view
        returns (string memory);
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}