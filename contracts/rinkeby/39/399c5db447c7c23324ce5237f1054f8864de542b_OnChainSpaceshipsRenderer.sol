//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Author: MouseDev.eth

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "./IOnChainSpaceships.sol";
import "./OnChainSpaceshipsLibrary.sol";

contract OnChainSpaceshipsRenderer is Ownable {
    struct Trait {
        uint256 traitId;
        bytes traitName;
        bytes traitType;
        bytes pngImage;
        //The traits rarity: 0 if not a rarity based trait.
        uint16 traitRarity;
        //Was this a trait that actually had a rarity, during launch.
        bool baseTrait;
    }


    //Mappings
    mapping(uint256 => Trait[]) public traitTypes;

    //Trait type id to its index
    mapping(uint256 => uint256) public traitIdToIndex;

    //Token ID to it's spaceship parts, will initialize as [0,0,0,0,0]
    mapping(uint256 => uint256[5]) public tokenIdToSpaceshipParts;

    uint256 public traitTypeCount = 5;
    uint256 public traitIdCounter = 1;

    address public OnChainSpaceshipsAddress;


    constructor() {}

    function getTraitOfTokenByIndex(uint256 tokenId, uint16 traitTypeIndex) public view returns(Trait memory) {
        uint256 thisTraitId = tokenIdToSpaceshipParts[tokenId][traitTypeIndex];

        if(thisTraitId == 0){
            //It is unset
            return getOriginalTraitByIndex(tokenId, traitTypeIndex);
        } else {
            //It has been updated, or swapped.
            return traitTypes[traitTypeIndex][traitIdToIndex[thisTraitId]];
        }
    }

    function getOriginalTraitByIndex(uint256 tokenId, uint16 traitTypeIndex) public view returns(Trait memory) {
        uint8 thisTraitIndex = rarityGen(generateARandomNumber(tokenId, abi.encodePacked(getEntropySeed(), traitTypeIndex)), traitTypeIndex);
        return traitTypes[traitTypeIndex][thisTraitIndex];
    }


    function generateARandomNumber(
        uint256 tokenId,
        bytes memory entropySeed
    ) public pure returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(tokenId, entropySeed))
            ) % 10000;
    }

    /**
     * @dev Converts a digit from 0 - 10000 into its corresponding rarity based on the given rarity tier.
     * @param randInput The input from 0 - 10000 to use for rarity gen.
     * @param traitTypeIndex The traitTypeIndex to use.
     */
    function rarityGen(uint256 randInput, uint16 traitTypeIndex)
        internal
        view
        returns (uint8)
    {
        uint16 currentLowerBound = 0;
        for (uint8 i = 0; i < traitTypes[traitTypeIndex].length; i++) {
            uint16 thisPercentage = traitTypes[traitTypeIndex][i].traitRarity;
            if (
                randInput >= currentLowerBound &&
                randInput < currentLowerBound + thisPercentage
            ) return i;
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert();
    }

    function generatePNGForSVG(bytes memory pngImage)
        public
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                '<image x="1" y="1" width="48" height="48" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="',
                pngImage,
                '" />'
            );
    }

    function generateMetadataString(
        bytes memory traitType,
        bytes memory traitName
    ) public pure returns (bytes memory) {
        return
            abi.encodePacked(
                '{"trait_type":"',
                traitName,
                '","value":"',
                traitType,
                '"}'
            );
    }

    function getEntropySeed() internal view returns(bytes32){
        return IOnChainSpaceships(OnChainSpaceshipsAddress)
            .entropySeed();
    }

    function setTrait(uint256 tokenId, uint16 traitTypeIndex, uint256 traitId) public {
        require(msg.sender == IERC721(OnChainSpaceshipsAddress).ownerOf(tokenId), "You don't own this spaceship!");
        //Require they are allowed to set this traitTypeId as well!.
        require(traitTypes[traitTypeIndex][traitIdToIndex[traitId]].traitId ==  traitId, "Trait ID must be a compatible part!");

        tokenIdToSpaceshipParts[tokenId][traitTypeIndex] = traitId;
    }

    function generateMetadata(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        bytes memory runningMetadata = bytes("[");

        for (
            uint16 traitTypeIndex = 0;
            traitTypeIndex < traitTypeCount;
            traitTypeIndex++
        ) {
            Trait memory thisTrait = getTraitOfTokenByIndex(tokenId, traitTypeIndex);

            if (traitTypeIndex < 4) {
                runningMetadata = abi.encodePacked(
                    runningMetadata,
                    generateMetadataString(
                        thisTrait.traitType,
                        thisTrait.traitName
                    ),
                    ","
                );
            } else {
                runningMetadata = abi.encodePacked(
                    runningMetadata,
                    generateMetadataString(
                        thisTrait.traitType,
                        thisTrait.traitName
                    ),
                    "]"
                );
            }
        }

        return string(runningMetadata);
    }

    function generateSVG(uint256 tokenId) public view returns (string memory) {
        bytes memory runningSVG = bytes(
            '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="spaceship" width="100%" height="100%" version="1.1" viewBox="0 0 48 48">'
        );

        for (
            uint16 traitTypeIndex = 0;
            traitTypeIndex < traitTypeCount;
            traitTypeIndex++
        ) {
            Trait memory thisTrait = getTraitOfTokenByIndex(tokenId, traitTypeIndex);

            runningSVG = abi.encodePacked(
                runningSVG,
                generatePNGForSVG(
                    thisTrait.pngImage
                )
            );
        }

        runningSVG = abi.encodePacked(
            runningSVG,
            "<style>#spaceship{shape-rendering: crispedges;image-rendering: -webkit-crisp-edges;image-rendering: -moz-crisp-edges;image-rendering: crisp-edges;image-rendering: pixelated;-ms-interpolation-mode: nearest-neighbor;}</style></svg>"
        );

        return string(runningSVG);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    OnChainSpaceshipsLibrary.encode(
                        abi.encodePacked(
                            '{"description": "On Chain Spaceships is an experimental project testing a new method for cheap on chain minting.","image": "data:image/svg+xml;base64,',
                            OnChainSpaceshipsLibrary.encode(
                                bytes(generateSVG(tokenId))
                            ),
                            '","name": "On Chain Spaceship #',
                            OnChainSpaceshipsLibrary.toString(tokenId),
                            '","attributes":',
                            generateMetadata(tokenId),
                            "}"
                        )
                    )
                )
            );
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
            uint256 thisTraitTypeId = traitIdCounter;
            traitIdCounter++;

            //Push this trait into the trait types array.
            traitTypes[_traitTypeIndex].push(
                Trait(
                    thisTraitTypeId,
                    traits[i].traitName,
                    traits[i].traitType,
                    traits[i].pngImage,
                    traits[i].traitRarity,
                    traits[i].baseTrait
                )
            );

            //Store the index of this trait for easy future retrieval.
            traitIdToIndex[thisTraitTypeId] = traitTypes[_traitTypeIndex].length - 1;
        }

        return;
    }

    function setOnChainSpaceshipsAddress(address newAddress) public onlyOwner {
        OnChainSpaceshipsAddress = newAddress;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOnChainSpaceships {
    function entropySeed() external view returns(bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library OnChainSpaceshipsLibrary {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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