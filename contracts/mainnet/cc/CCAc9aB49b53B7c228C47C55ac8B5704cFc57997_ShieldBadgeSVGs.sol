// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../interfaces/IShieldBadgeSVGs.sol';
import '../interfaces/IShields.sol';

/// @dev Generate Field SVG
contract ShieldBadgeSVGs is IShieldBadgeSVGs {
    function generateShieldBadgeSVG(IShields.ShieldBadge shieldBadge) public pure override returns (string memory svg) {
        if (shieldBadge == IShields.ShieldBadge.MAKER) {
            svg = makerBadgeSVG();
        }

        if (shieldBadge == IShields.ShieldBadge.STANDARD) {
            svg = standardBadgeSVG();
        }
    }

    function makerBadgeSVG() internal pure returns (string memory) {
        return
            '<svg xmlns="http://www.w3.org/2000/svg" xml:space="preserve" viewBox="0 0 500 600"><linearGradient id="a" x1="110.5" x2="389.5" y1="82.68" y2="82.68" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#4b4b4b"/><stop offset=".5" stop-color="gray"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><path fill="url(#a)" d="M377.14 76.5H122.86a12.37 12.37 0 0 0-12.36 12.36h279c0-6.82-5.54-12.36-12.36-12.36z"/><path fill="#1E1E1E" d="M122.86 521.5a12.37 12.37 0 0 1-12.36-12.36V90.86c0-6.82 5.54-12.36 12.36-12.36h254.28c6.82 0 12.36 5.54 12.36 12.36v418.28c0 6.82-5.54 12.36-12.36 12.36H122.86z"/><path fill="none" stroke="gray" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="3" d="M356.36 151.31a26.98 26.98 0 0 0 0-26.83m-5.46 23.68c4.19-7.22 2.96-15.43 0-20.53m-5.45 17.38a14.1 14.1 0 0 0 0-14.24M340 141.86a8.1 8.1 0 0 0 0-7.94"/><path fill="none" stroke="gray" stroke-miterlimit="10" d="M250 198.02v312m-110-312v312m110 0v-24"/><path fill="none" stroke="gray" stroke-miterlimit="10" stroke-width=".91" d="M120 354.02h260m-260 132h260m-260-264h260"/><path fill="none" stroke="gray" stroke-miterlimit="10" d="M360 198.02v312"/><path fill="#1E1E1E" d="M370 496.02v-284H130v284h240z"/><g stroke="#1E1E1E" stroke-miterlimit="10" stroke-width="3"><path fill="#4B4B4B" d="M360 222.02H140v264h220v-264"/><path fill="none" d="M150 222.02v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m-210-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220"/></g><g fill="none" stroke="#1E1E1E" stroke-miterlimit="10" stroke-width="4"><circle cx="200" cy="354" r="3"/><circle cx="225" cy="324" r="3"/><circle cx="225" cy="384" r="3"/><circle cx="275" cy="324" r="3"/><circle cx="275" cy="384" r="3"/><circle cx="250" cy="354" r="3"/><circle cx="300" cy="354" r="3"/><circle cx="250" cy="414" r="3"/><circle cx="200" cy="294" r="3"/><circle cx="250" cy="294" r="3"/><circle cx="300" cy="294" r="3"/></g><path fill="none" stroke="#1E1E1E" stroke-miterlimit="10" stroke-width="4" d="M244.42 318.1v21.72a14.48 14.48 0 1 1-28.96 0V318.1h28.96zm40.12 0v21.72a14.48 14.48 0 1 1-28.96 0V318.1h28.96zm-20.06 45.4v21.72a14.48 14.48 0 1 1-28.96 0V363.5h28.96z"/><path fill="none" stroke="#1E1E1E" stroke-width="4" d="M250 486.02v-264m110 0H140v264h220v-264zm0 132H140"/><g fill="none" stroke-miterlimit="10"><path stroke="#1E1E1E" stroke-width="4" d="m140 486.02 220-264m0 264-220-264m110 264v-264m0 192-50-60m50 60 50-60m-50-60-50 60m50-60 50 60m0 14.98a50.01 50.01 0 0 1-50 50 50.04 50.04 0 0 1-35.36-14.64A50.04 50.04 0 0 1 200 369v-75h100v75zm60-14.98H140m220-132H140v264h220v-264z"/><path stroke="gray" d="m140 486.02 220-264m0 264-220-264m110 264v-264m0 192-50-60m50 60 50-60m-50-60-50 60m50-60 50 60m0 14.98a50.01 50.01 0 0 1-50 50 50.04 50.04 0 0 1-35.36-14.64A50.04 50.04 0 0 1 200 369v-75h100v75zm60-14.98H140m220-132H140v264h220v-264z"/></g><g fill="gray"><circle cx="200" cy="354" r="3"/><circle cx="225" cy="324" r="3"/><circle cx="225" cy="384" r="3"/><circle cx="275" cy="324" r="3"/><circle cx="275" cy="384" r="3"/><circle cx="250" cy="354" r="3"/><circle cx="300" cy="354" r="3"/><circle cx="250" cy="414" r="3"/><circle cx="200" cy="294" r="3"/><circle cx="250" cy="294" r="3"/><circle cx="300" cy="294" r="3"/></g><linearGradient id="b" x1="146.83" x2="159.59" y1="174.76" y2="144.22" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#66b2ff"/><stop offset="1" stop-color="#007fff"/></linearGradient><path fill="url(#b)" d="m186 108 .9 2.16-8.2 9.84h-2.4l-8.2-9.84.9-2.16h17zm.41 29 .49-1.16-8.2-9.84h-2.4l-8.2 9.84.49 1.16h17.82zm-19.9-25.63-.51.22v22.82l.51.22 8-9.59V121l-8-9.63zM164 134.41v-22.82l-.51-.22-7.99 9.63v4l8 9.59.5-.18zM151.3 126l-8.2 9.84.49 1.16h17.82l.49-1.16-8.2-9.84h-2.4zm29.2 25v4l4 4.73h1.07a24.81 24.81 0 0 0 4.43-14.24V142l-1.51-.62-7.99 9.62zm-31 0-8-9.58-1.5.58v3.5a24.89 24.89 0 0 0 4.48 14.28h1.07l4-4.74-.05-4.04zm31-30v4l8 9.59 1.5-.59v-22l-1.51-.63-7.99 9.63zm2.64 40.38L178.7 156h-2.4l-8.3 10v3.6l1.06.61a24.9 24.9 0 0 0 14.09-7.48l-.01-1.35zM178.7 150l8.2-9.84-.49-1.16h-17.82l-.49 1.16 8.2 9.84h2.4zM162 169.58V166l-8.3-10h-2.4l-4.44 5.34v1.35a25 25 0 0 0 14.14 7.49l1-.6zM174.5 151l-8-9.59-.51.22V164l.73.36 7.78-9.36v-4zM164 164v-22.41l-.51-.22-7.99 9.63v4l7.77 9.32.73-.32zm-22.49-29.37 8-9.59V121l-8-9.59-1.51.59v22l1.51.63zM153.7 150l8.2-9.84-.49-1.16h-17.82l-.49 1.16 8.2 9.84h2.4zm-9.7-42-.9 2.16 8.2 9.84h2.4l8.2-9.84-.9-2.16h-17z"/><path fill="gray" d="M244.42 318.1v21.72a14.48 14.48 0 1 1-28.96 0V318.1h28.96zm40.12 0v21.72a14.48 14.48 0 1 1-28.96 0V318.1h28.96zm-20.06 45.4v21.72a14.48 14.48 0 1 1-28.96 0V363.5h28.96z"/></svg>';
    }

    function standardBadgeSVG() internal pure returns (string memory) {
        return
            '<svg xmlns="http://www.w3.org/2000/svg" xml:space="preserve" viewBox="0 0 500 600"><linearGradient id="a" x1="110.5" x2="389.5" y1="82.68" y2="82.68" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#a9a9a9"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="#a9a9a9"/></linearGradient><path fill="url(#a)" d="M377.14 76.5H122.86a12.37 12.37 0 0 0-12.36 12.36h279c0-6.82-5.54-12.36-12.36-12.36z"/><path fill="#007FFF" d="M122.86 521.5a12.37 12.37 0 0 1-12.36-12.36V90.86c0-6.82 5.54-12.36 12.36-12.36h254.28c6.82 0 12.36 5.54 12.36 12.36v418.28c0 6.82-5.54 12.36-12.36 12.36H122.86z"/><path fill="none" stroke="#FFF" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="3" d="M356.36 151.31a26.98 26.98 0 0 0 0-26.83m-5.46 23.68c4.19-7.22 2.96-15.43 0-20.53m-5.45 17.38a14.1 14.1 0 0 0 0-14.24M340 141.86a8.1 8.1 0 0 0 0-7.94"/><path fill="none" stroke="#FFF" stroke-miterlimit="10" d="M250 198.02v312m-110-312v312m110 0v-24"/><path fill="none" stroke="#FFF" stroke-miterlimit="10" stroke-width=".91" d="M120 354.02h260m-260 132h260m-260-264h260"/><path fill="none" stroke="#FFF" stroke-miterlimit="10" d="M360 198.02v312"/><path fill="#007FFF" d="M370 496.02v-284H130v284h240z"/><g stroke="#007FFF" stroke-miterlimit="10" stroke-width="3"><path fill="#3A9EFF" d="M360 222.02H140v264h220v-264"/><path fill="none" d="M150 222.02v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m-210-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220"/></g><g fill="none" stroke="#007FFF" stroke-miterlimit="10" stroke-width="4"><circle cx="200" cy="354" r="3"/><circle cx="225" cy="324" r="3"/><circle cx="225" cy="384" r="3"/><circle cx="275" cy="324" r="3"/><circle cx="275" cy="384" r="3"/><circle cx="250" cy="354" r="3"/><circle cx="300" cy="354" r="3"/><circle cx="250" cy="414" r="3"/><circle cx="200" cy="294" r="3"/><circle cx="250" cy="294" r="3"/><circle cx="300" cy="294" r="3"/></g><path fill="none" stroke="#007FFF" stroke-width="4" d="M250 486.02v-264m110 0H140v264h220v-264zm0 132H140"/><g fill="none" stroke-miterlimit="10"><path stroke="#007FFF" stroke-width="4" d="m140 486.02 220-264m0 264-220-264m110 264v-264m0 192-50-60m50 60 50-60m-50-60-50 60m50-60 50 60m0 14.98a50.01 50.01 0 0 1-50 50 50.04 50.04 0 0 1-35.36-14.64A50.04 50.04 0 0 1 200 369v-75h100v75zm60-14.98H140m220-132H140v264h220v-264z"/><path stroke="#FFF" d="m140 486.02 220-264m0 264-220-264m110 264v-264m0 192-50-60m50 60 50-60m-50-60-50 60m50-60 50 60m0 14.98a50.01 50.01 0 0 1-50 50 50.04 50.04 0 0 1-35.36-14.64A50.04 50.04 0 0 1 200 369v-75h100v75zm60-14.98H140m220-132H140v264h220v-264z"/></g><g fill="#FFF"><circle cx="200" cy="354" r="3"/><circle cx="225" cy="324" r="3"/><circle cx="225" cy="384" r="3"/><circle cx="275" cy="324" r="3"/><circle cx="275" cy="384" r="3"/><circle cx="250" cy="354" r="3"/><circle cx="300" cy="354" r="3"/><circle cx="250" cy="414" r="3"/><circle cx="200" cy="294" r="3"/><circle cx="250" cy="294" r="3"/><circle cx="300" cy="294" r="3"/></g><linearGradient id="b" x1="151.28" x2="178.23" y1="158.45" y2="106.1" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#a9a9a9"/></linearGradient><path fill="url(#b)" d="m186 108 .9 2.16-8.2 9.84h-2.4l-8.2-9.84.9-2.16h17zm.41 29 .49-1.16-8.2-9.84h-2.4l-8.2 9.84.49 1.16h17.82zm-19.9-25.63-.51.22v22.82l.51.22 8-9.59V121l-8-9.63zM164 134.41v-22.82l-.51-.22-7.99 9.63v4l8 9.59.5-.18zM151.3 126l-8.2 9.84.49 1.16h17.82l.49-1.16-8.2-9.84h-2.4zm29.2 25v4l4 4.73h1.07a24.81 24.81 0 0 0 4.43-14.24V142l-1.51-.62-7.99 9.62zm-31 0-8-9.58-1.5.58v3.5a24.89 24.89 0 0 0 4.48 14.28h1.07l4-4.74-.05-4.04zm31-30v4l8 9.59 1.5-.59v-22l-1.51-.63-7.99 9.63zm2.64 40.38L178.7 156h-2.4l-8.3 10v3.6l1.06.61a24.9 24.9 0 0 0 14.09-7.48l-.01-1.35zM178.7 150l8.2-9.84-.49-1.16h-17.82l-.49 1.16 8.2 9.84h2.4zM162 169.58V166l-8.3-10h-2.4l-4.44 5.34v1.35a25 25 0 0 0 14.14 7.49l1-.6zM174.5 151l-8-9.59-.51.22V164l.73.36 7.78-9.36v-4zM164 164v-22.41l-.51-.22-7.99 9.63v4l7.77 9.32.73-.32zm-22.49-29.37 8-9.59V121l-8-9.59-1.51.59v22l1.51.63zM153.7 150l8.2-9.84-.49-1.16h-17.82l-.49 1.16 8.2 9.84h2.4zm-9.7-42-.9 2.16 8.2 9.84h2.4l8.2-9.84-.9-2.16h-17z"/></svg>';
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './IShields.sol';

/// @dev Generate ShieldBadge SVG
interface IShieldBadgeSVGs {
    function generateShieldBadgeSVG(IShields.ShieldBadge shieldBadge) external view returns (string memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

/// @dev Build Customizable Shields for an NFT
interface IShields is IERC721 {
    enum ShieldBadge {
        MAKER,
        STANDARD
    }

    struct Shield {
        bool built;
        uint16 field;
        uint16 hardware;
        uint16 frame;
        ShieldBadge shieldBadge;
        uint24[4] colors;
    }

    function build(
        uint16 field,
        uint16 hardware,
        uint16 frame,
        uint24[4] memory colors,
        uint256 tokenId
    ) external payable;

    function shields(uint256 tokenId)
        external
        view
        returns (
            uint16 field,
            uint16 hardware,
            uint16 frame,
            uint24 color1,
            uint24 color2,
            uint24 color3,
            uint24 color4,
            ShieldBadge shieldBadge
        );
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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