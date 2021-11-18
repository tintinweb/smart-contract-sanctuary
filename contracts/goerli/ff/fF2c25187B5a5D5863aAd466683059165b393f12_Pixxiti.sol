// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Helpers.sol";

contract Pixxiti is Ownable, Helpers {
    // ~~~ CURSORS ~~~
    // - frame cursors
    uint16 public lastFrameIndex;
    uint16 public nextFrameIndex;
    // - track cursors
    uint16 private nextTrackIndex;

    // ~~~ STATIC PARAMS ~~~
    uint16 public RATE;
    uint16 public TOTAL_FRAMES;

    // ~~~ STATS ~~~
    uint128 public steps;
    uint256 public nextFramePrice;

    struct Track {
        uint16 startIndex;
        uint16 length;
        address owner;
        address nft;
        uint256 framePrice;
        uint256 blockNumber;
        uint256 tokenId;
        string tokenUri;
    }

    uint16[] frames;
    mapping(uint16 => Track) tracks;
    mapping(address => uint256) balanceOf;

    event RecordTrack(
        uint16 indexed trackIndex,
        uint16 length,
        address indexed owner
    );

    constructor(
        uint16 totalFrames,
        uint256 startFramePrice,
        uint16 rate,
        uint128 initialSteps,
        IERC721Metadata nftAddress,
        uint256 tokenId
    ) {
        TOTAL_FRAMES = totalFrames;
        nextFrameIndex = 0;
        nextTrackIndex = 0;
        nextFramePrice = startFramePrice;
        RATE = rate;
        steps = initialSteps;
        frames = new uint16[](totalFrames);
        string memory tokenUri = getTokenURI(nftAddress, tokenId);
        addTrack(
            0,
            totalFrames,
            0,
            address(nftAddress),
            startFramePrice,
            tokenId,
            tokenUri
        );
        writeFrames(0, totalFrames, totalFrames, 0);
        writeCursor(getNextFrameIndex(0, totalFrames, totalFrames));
    }

    function lastTrackIndex() public view returns (uint16) {
        return frames[lastFrameIndex];
    }

    function getNextFrameIndex(
        uint16 frameIndex,
        uint16 length,
        uint16 totalLength
    ) private pure returns (uint16) {
        uint16 pos = frameIndex + length;
        return pos < totalLength ? pos : pos % totalLength;
    }

    function returnTrack(uint16 index)
        internal
        view
        returns (
            uint16,
            uint16,
            address,
            address,
            uint256,
            uint256,
            uint256,
            string memory
        )
    {
        Track memory track = tracks[index];
        return (
            track.startIndex,
            track.length,
            track.owner,
            track.nft,
            track.framePrice,
            track.blockNumber,
            track.tokenId,
            track.tokenUri
        );
    }

    function getFrame(uint256 index) public view returns (uint16) {
        return frames[index];
    }

    function getFiveFrames(uint16 index)
        public
        view
        returns (
            uint16,
            uint16,
            uint16,
            uint16,
            uint16
        )
    {
        uint16 f01 = frames[index];
        uint16 f02 = frames[index + 1];
        uint16 f03 = frames[index + 2];
        uint16 f04 = frames[index + 3];
        uint16 f05 = frames[index + 4];
        return (f01, f02, f03, f04, f05);
    }

    function getTrackByFrameIndex(uint16 index)
        public
        view
        returns (
            uint16,
            uint16,
            address,
            address,
            uint256,
            uint256,
            uint256,
            string memory
        )
    {
        return returnTrack(frames[index]);
    }

    function getTrackByIndex(uint16 index)
        public
        view
        returns (
            uint16,
            uint16,
            address,
            address,
            uint256,
            uint256,
            uint256,
            string memory
        )
    {
        return returnTrack(index);
    }

    function getLastTrack()
        public
        view
        returns (
            uint16,
            uint16,
            address,
            address,
            uint256,
            uint256,
            uint256,
            string memory
        )
    {
        return returnTrack(frames[lastFrameIndex]);
    }

    function getNextFramePrice() public view returns (uint256) {
        uint256 framePrice = nextFramePrice;
        Track memory lastTrack = tracks[lastTrackIndex()];
        uint256 multiplier = getMultiplier(lastTrack.blockNumber - 1);
        return getMinFramePrice(framePrice, multiplier);
    }

    function addTrack(
        uint16 index,
        uint16 length,
        uint16 trackIndex,
        address nft,
        uint256 framePrice,
        uint256 tokenId,
        string memory tokenUri
    ) private {
        Track storage newTrack = tracks[trackIndex];
        newTrack.startIndex = index;
        newTrack.length = length;
        newTrack.owner = msg.sender;
        newTrack.nft = nft;
        newTrack.framePrice = framePrice;
        newTrack.blockNumber = block.number;
        newTrack.tokenId = tokenId;
        newTrack.tokenUri = tokenUri;

        emit RecordTrack(trackIndex, length, msg.sender);
    }

    function writeFrames(
        uint16 index,
        uint16 length,
        uint16 total,
        uint16 trackIndex
    ) private {
        for (uint16 i = 0; i < length; i++) {
            uint256 pos = index + i;
            frames[pos < total ? pos : pos % total] = trackIndex;
        }
    }

    function getMultiplier(uint256 lastBlockNumber)
        public
        view
        returns (uint256)
    {
        if (lastBlockNumber >= block.number) return 0;
        uint256 multiplier = block.number - lastBlockNumber - 1;
        if (multiplier >= steps) {
            return steps;
        }
        return multiplier;
    }

    function getMinFramePrice(uint256 framePrice, uint256 multiplier)
        internal
        view
        returns (uint256)
    {
        if (multiplier == 0) return framePrice;
        if (multiplier >= steps) {
            return 1;
        }
        return framePrice - mulScale(framePrice, multiplier, steps);
    }

    function splitValue(
        uint256 value,
        uint256 multiplier,
        address lastTrackOwner
    ) private {
        uint256 yours = value - mulScale(value, multiplier, steps);
        uint256 mine = value - yours;
        balanceOf[owner()] += mine;
        balanceOf[lastTrackOwner] += yours;
        if (yours > mine) {
            if (steps > 1) {
                steps = steps - 1;
            }
        } else {
            steps = steps + 1;
        }
    }

    function setNewPrice(uint256 framePrice, uint16 trackLength) private {
        nextFramePrice = RATE * trackLength * framePrice;
    }

    function writeCursor(uint16 newIndex) private {
        lastFrameIndex = nextFrameIndex;
        nextFrameIndex = newIndex;
        nextTrackIndex = (nextTrackIndex + 1) % 65535;
    }

    function record(
        IERC721Metadata nftAddress,
        uint256 tokenId,
        uint16 trackLength
    ) public payable {
        uint16 index = nextFrameIndex;
        uint16 totalFrames = TOTAL_FRAMES;
        uint16 trackIndex = nextTrackIndex;

        require(
            trackLength >= 1 && trackLength <= TOTAL_FRAMES,
            "Must be greater than 0, and less than total frames"
        );
        Track memory lastTrack = tracks[lastTrackIndex()];
        uint256 multiplier = getMultiplier(lastTrack.blockNumber);
        uint256 minFramePrice = getMinFramePrice(nextFramePrice, multiplier);
        uint256 newFramePrice = getValueFramePrice(msg.value, trackLength);

        require(
            newFramePrice >= minFramePrice,
            "Unit price does not meet min price"
        );

        string memory tokenUri = getTokenURI(nftAddress, tokenId);
        addTrack(
            index,
            trackLength,
            trackIndex,
            address(nftAddress),
            newFramePrice,
            tokenId,
            tokenUri
        );

        writeFrames(index, trackLength, totalFrames, trackIndex);
        writeCursor(getNextFrameIndex(index, trackLength, totalFrames));
        setNewPrice(newFramePrice, trackLength);
        splitValue(msg.value, multiplier, lastTrack.owner);
    }

    function getBalanceOf(address addr) public view returns (uint256) {
        return balanceOf[addr];
    }

    function withdrawAll() public {
        require(balanceOf[msg.sender] > 0, "You have no balance.");
        uint256 amount = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed.");
    }
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

pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

abstract contract Helpers {
    function getTokenURI(IERC721Metadata addy, uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        require(
            addy.supportsInterface(type(IERC721Metadata).interfaceId),
            "Address is not supported."
        );
        require(
            addy.ownerOf(tokenId) == msg.sender,
            "Must be owner to place ERC721"
        );
        return addy.tokenURI(tokenId);
    }

    function getValueFramePrice(uint256 _value, uint16 _trackLength)
        internal
        pure
        returns (uint256)
    {
        return mulScale(_value, 1, _trackLength);
    }

    function mulScale(
        uint256 x,
        uint256 y,
        uint128 scale
    ) internal pure returns (uint256) {
        uint256 a = x / scale;
        uint256 b = x % scale;
        uint256 c = y / scale;
        uint256 d = y % scale;

        return a * c * scale + a * d + b * c + (b * d) / scale;
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