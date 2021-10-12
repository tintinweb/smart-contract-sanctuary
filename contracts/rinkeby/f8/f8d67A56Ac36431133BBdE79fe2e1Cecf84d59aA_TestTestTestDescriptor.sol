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

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAnonymiceBreeding.sol";
import "./IAnonymice.sol";
import "./AnonymiceLibrary.sol";

contract TestTestTestDescriptor is Ownable {
    /*

           _   _  ____  _   ___     ____  __ _____ _____ ______   ____  _____  ______ ______ _____ _____ _   _  _____ 
     /\   | \ | |/ __ \| \ | \ \   / /  \/  |_   _/ ____|  ____| |  _ \|  __ \|  ____|  ____|  __ \_   _| \ | |/ ____|
    /  \  |  \| | |  | |  \| |\ \_/ /| \  / | | || |    | |__    | |_) | |__) | |__  | |__  | |  | || | |  \| | |  __ 
   / /\ \ | . ` | |  | | . ` | \   / | |\/| | | || |    |  __|   |  _ <|  _  /|  __| |  __| | |  | || | | . ` | | |_ |
  / ____ \| |\  | |__| | |\  |  | |  | |  | |_| || |____| |____  | |_) | | \ \| |____| |____| |__| || |_| |\  | |__| |
 /_/    \_\_| \_|\____/|_| \_|  |_|  |_|  |_|_____\_____|______| |____/|_|  \_\______|______|_____/_____|_| \_|\_____|
                                                                                                                      
                                                                                                                      
*/

    using AnonymiceLibrary for uint8;
    //addresses
    address ANONYMICE_ADDRESS;
    address ANONYMICE_BREEDING_ADDRESS;

    //Trait struct
    struct Trait {
        string traitName;
        string traitType;
        string pixels;
        uint256 pixelCount;
    }

    struct Legendary {
        string svg;
        string metadata;
        string name;
    }

    //Mappings
    mapping(uint256 => Trait[]) public traitTypes;
    mapping(uint256 => Legendary) public legendaries;

    string internal SVG_PIECE;

    //string arrays
    string[] LETTERS = [
        "a",
        "b",
        "c",
        "d",
        "e",
        "f",
        "g",
        "h",
        "i",
        "j",
        "k",
        "l",
        "m",
        "n",
        "o",
        "p",
        "q",
        "r",
        "s",
        "t",
        "u",
        "v",
        "w",
        "x",
        "y",
        "z"
    ];

    /*
 ____     ___   ____  ___        _____  __ __  ____     __ ______  ____  ___   ____   _____
|    \   /  _] /    ||   \      |     ||  |  ||    \   /  ]      ||    |/   \ |    \ / ___/
|  D  ) /  [_ |  o  ||    \     |   __||  |  ||  _  | /  /|      | |  ||     ||  _  (   \_ 
|    / |    _]|     ||  D  |    |  |_  |  |  ||  |  |/  / |_|  |_| |  ||  O  ||  |  |\__  |
|    \ |   [_ |  _  ||     |    |   _] |  :  ||  |  /   \_  |  |   |  ||     ||  |  |/  \ |
|  .  \|     ||  |  ||     |    |  |   |     ||  |  \     | |  |   |  ||     ||  |  |\    |
|__|\_||_____||__|__||_____|    |__|    \__,_||__|__|\____| |__|  |____|\___/ |__|__| \___|
                                                                                           
*/

    /**
     * @dev Helper function to reduce pixel size within contract
     */
    function letterToNumber(string memory _inputLetter)
        internal
        view
        returns (uint8)
    {
        for (uint8 i = 0; i < LETTERS.length; i++) {
            if (
                keccak256(abi.encodePacked((LETTERS[i]))) ==
                keccak256(abi.encodePacked((_inputLetter)))
            ) return (i + 1);
        }
        revert();
    }

    function blocksTill(uint256 blockThen) internal view returns (uint256) {
        if (block.number > blockThen) {
            return 0;
        } else {
            return blockThen - block.number;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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

    function parseInt(string memory _a)
        internal
        pure
        returns (uint8 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    /**
     * @dev Hash to SVG function
     */
    function hashToSVG(string memory _hash)
        public
        view
        returns (string memory)
    {
        string memory svgString;
        bool[24][24] memory placedPixels;

        for (uint8 i = 0; i < 9; i++) {
            uint8 thisTraitIndex = parseInt(substring(_hash, i, i + 1));

            for (
                uint16 j = 0;
                j < traitTypes[i][thisTraitIndex].pixelCount;
                j++
            ) {
                string memory thisPixel = substring(
                    traitTypes[i][thisTraitIndex].pixels,
                    j * 4,
                    j * 4 + 4
                );

                uint8 x = letterToNumber(substring(thisPixel, 0, 1));
                uint8 y = letterToNumber(substring(thisPixel, 1, 2));

                if (placedPixels[x][y]) continue;

                svgString = string(
                    abi.encodePacked(
                        svgString,
                        "<rect class='bc",
                        substring(thisPixel, 2, 4),
                        "' x='",
                        toString(x),
                        "' y='",
                        toString(y),
                        "'/>"
                    )
                );

                placedPixels[x][y] = true;
            }
        }

        svgString = string(
            abi.encodePacked(
                '<svg id="mouse-svg" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 24 24"> ',
                svgString,
                "<style>rect{width:1px;height:1px;} #mouse-svg{shape-rendering: crispedges;} .bc00{fill:#000000}.bc01{fill:#DBDCE9}.bc02{fill:#9194B7}.bc03{fill:#EFA2A2}.bc04{fill:#FFCDCD}.bc05{fill:#F2B4B4}.bc06{fill:#E69754}.bc07{fill:#C86842}.bc08{fill:#E6BFAE}.bc09{fill:#AE8776}.bc10{fill:#A58F82}.bc11{fill:#7F625A}.bc12{fill:#848893}.bc13{fill:#454056}.bc14{fill:#6098B9}.bc15{fill:#447A9B}.bc16{fill:#7ABD4C}.bc17{fill:#476E2C}.bc18{fill:#ffffff}.bc19{fill:#A34C4C}.bc20{fill:#D86F6F}.bc21{fill:#1E223F}.bc22{fill:#33385F}.bc23{fill:#BD8447}.bc24{fill:#D8A952}.bc25{fill:#FFDB67}.bc26{fill:#1E223F}.bc27{fill:#404677}.bc28{fill:#2A2536}.bc29{fill:#3D384B}.bc30{fill:#8A80A9}.bc31{fill:#61587A}.bc32{fill:#3D384B}.bc33{fill:#3F3528}.bc34{fill:#6B5942}.bc35{fill:#775F40}.bc36{fill:#C0A27B}.bc37{fill:#C3AA8B}.bc38{fill:#FFE3BF}.bc39{fill:#977E5D}.bc40{fill:#E9CEAB}.bc41{fill:#403E4E}.bc42{fill:#666577}.bc43{fill:#8E8CA3}.bc44{fill:#BCB9D5}.bc45{fill:#1B3322}.bc46{fill:#304B38}.bc47{fill:#51715B}.bc48{fill:#FFD369}.bc49{fill:#D89120}.bc50{fill:#C08123}.bc51{fill:#FFF484}.bc52{fill:#FFD946}.bc53{fill:#E0AB2C}.bc54{fill:#471812}.bc55{fill:#8D3225}.bc56{fill:#BD9271}.bc57{fill:#D5B18D}.bc58{fill:#FFFFC1}.bc59{fill:#4B433F}.bc60{fill:#A19691}.bc61{fill:#C2B6AF}.bc62{fill:#F9F1EC}.bc63{fill:#62BDFB}.bc64{fill:#D5D5D5}.bc65{fill:#E9EAF5}.bc66{fill:#3941C6}.bc67{fill:#454FE9}.bc68{fill:#CF3B3B}.bc69{fill:#E94545}.bc70{fill:#F6F7FF}.bc71{fill:#C9CBE6}.bc72{fill:#B2B4D2}.bc73{fill:#34324E}.bc74{fill:#A99CD5}.bc75{fill:#4B4365}.bc76{fill:#23202D}.bc77{fill:#E8E9FF}.bc78{fill:#C3C9D8}.bc79{fill:#F5F2FB}.bc80{fill:#EFC25D}.bc81{fill:#F5CD62}.bc82{fill:#CF924C}.bc83{fill:#328529}.bc84{fill:#3FA934}.bc85{fill:#FFF5D9}.bc86{fill:#FFE7A4}.bc87{fill:#B06837}.bc88{fill:#8F4B0E}.bc89{fill:#DCBD91}.bc90{fill:#A35E40}.bc91{fill:#D39578}.bc92{fill:#876352}.bc93{fill:#8A84B1}</style></svg>"
            )
        );

        return svgString;
    }

    /**
     * @dev Hash to metadata function
     */
    function hashToMetadata(string memory _hash)
        public
        view
        returns (string memory)
    {
        string memory metadataString;

        for (uint8 i = 0; i < 9; i++) {
            uint8 thisTraitIndex = parseInt(substring(_hash, i, i + 1));

            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                    traitTypes[i][thisTraitIndex].traitType,
                    '","value":"',
                    traitTypes[i][thisTraitIndex].traitName,
                    '"}'
                )
            );

            if (i != 8)
                metadataString = string(abi.encodePacked(metadataString, ","));
        }

        return string(abi.encodePacked("[", metadataString, "]"));
    }

    function tokenIdToMetadata(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        if (
            ITestTestTest(ANONYMICE_BREEDING_ADDRESS)._tokenToRevealed(_tokenId)
        ) {
            //This is a revealed baby

            if (
                ITestTestTest(ANONYMICE_BREEDING_ADDRESS)._tokenIdToLegendary(
                    _tokenId
                )
            ) {
                uint8 legendaryId = ITestTestTest(ANONYMICE_BREEDING_ADDRESS)
                    ._tokenIdToLegendaryNumber(_tokenId);
                return legendaries[legendaryId].metadata;
            }
            return
                hashToMetadata(
                    ITestTestTest(ANONYMICE_BREEDING_ADDRESS)._tokenIdToHash(
                        _tokenId
                    )
                );
        } else {
            //This is an unrevealed baby
            return
                string(
                    abi.encodePacked(
                        '[{"trait_type":"Blocks Till Reveal", "display_type": "number", "value": ',
                        toString(
                            blocksTill(
                                ITestTestTest(ANONYMICE_BREEDING_ADDRESS)
                                    ._tokenToIncubator(_tokenId)
                                    .revealBlock
                            )
                        ),
                        '},{"trait_type": "Parent #1 ID", "value": "',
                        toString(
                            ITestTestTest(ANONYMICE_BREEDING_ADDRESS)
                                ._tokenToIncubator(_tokenId)
                                .parentId1
                        ),
                        '"},{"trait_type": "Parent #2 ID", "value": "',
                        toString(
                            ITestTestTest(ANONYMICE_BREEDING_ADDRESS)
                                ._tokenToIncubator(_tokenId)
                                .parentId2
                        ),
                        '"}, {"trait_type" :"revealed","value" : "Not Revealed "}]'
                    )
                );
        }
    }

    function tokenIdToSVG(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        if (
            ITestTestTest(ANONYMICE_BREEDING_ADDRESS)._tokenToRevealed(_tokenId)
        ) {
            //This is a revealed baby

            if (
                ITestTestTest(ANONYMICE_BREEDING_ADDRESS)._tokenIdToLegendary(
                    _tokenId
                )
            ) {
                uint8 legendaryId = ITestTestTest(ANONYMICE_BREEDING_ADDRESS)
                    ._tokenIdToLegendaryNumber(_tokenId);
                return legendaries[legendaryId].svg;
            }
            return
                hashToSVG(
                    ITestTestTest(ANONYMICE_BREEDING_ADDRESS)._tokenIdToHash(
                        _tokenId
                    )
                );
        } else {
            //This is an unrevealed baby

            return
                string(
                    abi.encodePacked(
                        SVG_PIECE,
                        toString(_tokenId),
                        '</text><text transform="translate(148.22 120.65)" style="font-size: 16px;fill: #d5eef5;font-family: PixelFont">',
                        toString(
                            blocksTill(
                                ITestTestTest(ANONYMICE_BREEDING_ADDRESS)
                                    ._tokenToIncubator(_tokenId)
                                    .revealBlock
                            )
                        ),
                        '</text><text transform="translate(65.44 343.09)" style="font-size: 20px;fill: #d5eef5;font-family: PixelFont">',
                        toString(
                            ITestTestTest(ANONYMICE_BREEDING_ADDRESS)
                                ._tokenToIncubator(_tokenId)
                                .parentId1
                        ),
                        '</text><text transform="translate(234.44 343.09)" style="font-size: 20px;fill: #d5eef5;font-family: PixelFont">',
                        toString(
                            ITestTestTest(ANONYMICE_BREEDING_ADDRESS)
                                ._tokenToIncubator(_tokenId)
                                .parentId2
                        ),
                        '</text><svg x="54" y="204" width="84" height="84">',
                        IAnonymice(ANONYMICE_ADDRESS).hashToSVG(
                            IAnonymice(ANONYMICE_ADDRESS)._tokenIdToHash(
                                ITestTestTest(ANONYMICE_BREEDING_ADDRESS)
                                    ._tokenToIncubator(_tokenId)
                                    .parentId1
                            )
                        ),
                        '</svg><svg x="223" y="204" width="84" height="84">',
                        IAnonymice(ANONYMICE_ADDRESS).hashToSVG(
                            IAnonymice(ANONYMICE_ADDRESS)._tokenIdToHash(
                                ITestTestTest(ANONYMICE_BREEDING_ADDRESS)
                                    ._tokenToIncubator(_tokenId)
                                    .parentId2
                            )
                        ),
                        "</svg></svg>"
                    )
                );
        }
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        string memory name;

        if (
            ITestTestTest(ANONYMICE_BREEDING_ADDRESS)._tokenToRevealed(_tokenId)
        ) {
            if (
                ITestTestTest(ANONYMICE_BREEDING_ADDRESS)._tokenIdToLegendary(
                    _tokenId
                )
            ) {
                name = string(
                    abi.encodePacked(
                        '{"name": "',
                        legendaries[
                            ITestTestTest(ANONYMICE_BREEDING_ADDRESS)
                                ._tokenIdToLegendaryNumber(_tokenId)
                        ].name
                    )
                );
            } else {
                name = string(
                    abi.encodePacked(
                        '{"name": "Baby Mouse #',
                        toString(_tokenId)
                    )
                );
            }
        } else {
            name = string(
                abi.encodePacked('{"name": "Incubator #', toString(_tokenId))
            );
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    AnonymiceLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    name,
                                    '", "image": "data:image/svg+xml;base64,',
                                    AnonymiceLibrary.encode(
                                        bytes(tokenIdToSVG(_tokenId))
                                    ),
                                    '","attributes":',
                                    tokenIdToMetadata(_tokenId),
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    /*

  ___   __    __  ____     ___  ____       _____  __ __  ____     __ ______  ____  ___   ____   _____
 /   \ |  |__|  ||    \   /  _]|    \     |     ||  |  ||    \   /  ]      ||    |/   \ |    \ / ___/
|     ||  |  |  ||  _  | /  [_ |  D  )    |   __||  |  ||  _  | /  /|      | |  ||     ||  _  (   \_ 
|  O  ||  |  |  ||  |  ||    _]|    /     |  |_  |  |  ||  |  |/  / |_|  |_| |  ||  O  ||  |  |\__  |
|     ||  `  '  ||  |  ||   [_ |    \     |   _] |  :  ||  |  /   \_  |  |   |  ||     ||  |  |/  \ |
|     | \      / |  |  ||     ||  .  \    |  |   |     ||  |  \     | |  |   |  ||     ||  |  |\    |
 \___/   \_/\_/  |__|__||_____||__|\_|    |__|    \__,_||__|__|\____| |__|  |____|\___/ |__|__| \___|
                                                                                                     
    */

    /**
     * @dev Clears the traits.
     */
    function clearTraits() public onlyOwner {
        for (uint256 i = 0; i < 9; i++) {
            delete traitTypes[i];
        }
    }

    function uploadSVGPiece(string memory _svgPiece) public onlyOwner {
        SVG_PIECE = _svgPiece;
    }

    /**
     * @dev Add a trait type
     * @param _traitTypeIndex The trait type index
     * @param traits Array of traits to add
     */

    function addTraitType(uint256 _traitTypeIndex, Trait[] memory traits)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < traits.length; i++) {
            traitTypes[_traitTypeIndex].push(
                Trait(
                    traits[i].traitName,
                    traits[i].traitType,
                    traits[i].pixels,
                    traits[i].pixelCount
                )
            );
        }

        return;
    }

    function addLegendary(uint256 _legendaryId, Legendary memory legendary)
        public
        onlyOwner
    {
        legendaries[_legendaryId] = legendary;
    }

    function setAddresses(
        address _anonymiceBreedingAddress,
        address _anonymiceAddress
    ) public onlyOwner {
        ANONYMICE_BREEDING_ADDRESS = _anonymiceBreedingAddress;
        ANONYMICE_ADDRESS = _anonymiceAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AnonymiceLibrary {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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

    function parseInt(string memory _a)
        internal
        pure
        returns (uint8 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IAnonymice is IERC721Enumerable {
    function _tokenIdToHash(uint256 _tokenId)
        external
        view
        returns (string memory);

    function hashToSVG(string memory _hash)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ITestTestTest is IERC721Enumerable {
    struct BreedingEvent {
        uint256 parentId1;
        uint256 parentId2;
        uint256 childId;
        uint256 releaseBlock;
    }

    struct Incubator {
        uint256 parentId1;
        uint256 parentId2;
        uint256 childId;
        uint256 revealBlock;
    }

    function _addressToBreedingEvents(address userAddress, uint256 index)
        external
        view
        returns (BreedingEvent memory);

    function _tokenToIncubator(uint256 _tokenId)
        external
        view
        returns (Incubator memory);

    function _tokenToRevealed(uint256 _tokenId) external view returns (bool);
    function _tokenIdToHash(uint256 _tokenId) external view returns(string memory);
    function _tokenIdToLegendary(uint256 _tokenId) external view returns(bool);
    function _tokenIdToLegendaryNumber(uint256 _tokenId) external view returns(uint8);
}