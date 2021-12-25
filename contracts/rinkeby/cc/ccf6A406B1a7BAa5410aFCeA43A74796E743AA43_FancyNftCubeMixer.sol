// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./RecoverableErc20ByOwner.sol";
import "./interfaces/IERC721Burnable.sol";
import "./interfaces/IFancyNftHeroesS1.sol";
import "./interfaces/IFancyTokenSupplier.sol";

/// @custom:security-contact [email protected]
contract FancyNftCubeMixer is RecoverableErc20ByOwner {
    address public immutable heroes;
    address public immutable items;
    address public immutable tokenSupplier;

    uint8 public constant totalColors = 4; // values: 1-4
    uint8 public constant totalFacets = 3; // values: 0-2
    uint8 public constant totalPlaces = 9; // values: 0-8
    uint8 public constant totalCells = 27; // values: 0-26

    uint256 public extraRate = 0.25 ether;
    uint256 public rewards = 10000000000 ether;

    mapping(uint256 => bool) private _cubes;
    mapping(uint256 => uint8[totalFacets]) private _facets;
    mapping(uint256 => uint8[totalCells]) private _cells;

    event Mixed(
        uint256 indexed heroTokenId,
        uint256 indexed itemTokenId,
        uint8 cellId,
        uint8 colorId
    );

    constructor(
        address heroes_,
        address items_,
        address tokenSupplier_
    ) {
        heroes = heroes_;
        items = items_;
        tokenSupplier = tokenSupplier_;
    }

    function setRewards(uint256 rewards_) external onlyOwner {
        rewards = rewards_;
    }

    function setExtraRate(uint256 extraRate_) external onlyOwner {
        extraRate = extraRate_;
    }

    function mix(uint256 heroTokenId, uint256 itemTokenId) public {
        uint8 facetId = getFacetId(itemTokenId);
        require(_facets[heroTokenId][facetId] == 0, "Facet is done");

        uint8 colorId = getColorId(itemTokenId);
        require(!isColorUsed(itemTokenId, colorId), "This color is used");

        require(
            _msgSender() == IERC721Enumerable(heroes).ownerOf(heroTokenId),
            "Not own"
        );
        IERC721Burnable(items).burnFrom(_msgSender(), itemTokenId);

        uint8 cellId = getCellId(itemTokenId);
        _setColorInCell(heroTokenId, cellId, colorId);
        emit Mixed(heroTokenId, itemTokenId, cellId, colorId);

        if (facetIsDone(heroTokenId, facetId)) {
            _facets[heroTokenId][facetId] = colorId;
            IFancyNftHeroesS1(heroes).addExtraRate(heroTokenId, extraRate);
            IFancyTokenSupplier(tokenSupplier).sendRewards(
                _msgSender(),
                rewards
            );

            if (cubeIsDone(heroTokenId)) {
                _cubes[heroTokenId] = true;
                IFancyNftHeroesS1(heroes).addExtraRate(heroTokenId, extraRate);
                IFancyTokenSupplier(tokenSupplier).sendRewards(
                    _msgSender(),
                    rewards
                );
            }
        }
    }

    function isColorUsed(uint256 heroTokenId, uint8 colorId)
        public
        view
        returns (bool)
    {
        return
            _facets[heroTokenId][0] == colorId ||
            _facets[heroTokenId][1] == colorId ||
            _facets[heroTokenId][2] == colorId;
    }

    function _setColorInCell(
        uint256 heroTokenId,
        uint8 cellId,
        uint8 colorId
    ) internal {
        _cells[heroTokenId][cellId] = colorId;
    }

    // facets
    function getCubeFacets(uint256 heroTokenId)
        public
        view
        returns (uint8[totalFacets] memory cube)
    {
        for (uint8 i = 0; i < totalFacets; i++) {
            cube[i] = _facets[heroTokenId][i];
        }
    }

    function getFacet(uint256 heroTokenId, uint8 facetId)
        public
        view
        returns (uint8 facet)
    {
        facet = _facets[heroTokenId][facetId];
    }

    // cells
    function getCubeCells(uint256 heroTokenId)
        public
        view
        returns (uint8[totalCells] memory cube)
    {
        for (uint8 i = 0; i < totalCells; i++) {
            cube[i] = _cells[heroTokenId][i];
        }
    }

    function getFacetCells(uint256 heroTokenId, uint8 facetId)
        public
        view
        returns (uint8[totalPlaces] memory facet)
    {
        uint8 offset = facetId * totalPlaces;
        for (uint8 i = offset; i < (offset + totalPlaces); i++) {
            facet[i - offset] = _cells[heroTokenId][i];
        }
    }

    function getCell(uint256 heroTokenId, uint8 cellId)
        public
        view
        returns (uint8 cell)
    {
        cell = _cells[heroTokenId][cellId];
    }

    function getCell(
        uint256 heroTokenId,
        uint8 facetId,
        uint8 placeId
    ) public view returns (uint8 cell) {
        cell = getCell(heroTokenId, getCellId(facetId, placeId));
    }

    // State
    function cubeIsDone(uint256 heroTokenId) public view returns (bool) {
        return
            facetIsDone(heroTokenId, 0) &&
            facetIsDone(heroTokenId, 1) &&
            facetIsDone(heroTokenId, 2);
    }

    function facetIsDone(uint256 heroTokenId, uint8 facetId)
        public
        view
        returns (bool)
    {
        if (cellIsDone(heroTokenId, facetId, 0)) {
            uint8 place0ColorId = getCell(heroTokenId, facetId, 0);
            return
                place0ColorId == getCell(heroTokenId, facetId, 1) &&
                place0ColorId == getCell(heroTokenId, facetId, 2) &&
                place0ColorId == getCell(heroTokenId, facetId, 3) &&
                place0ColorId == getCell(heroTokenId, facetId, 4) &&
                place0ColorId == getCell(heroTokenId, facetId, 5) &&
                place0ColorId == getCell(heroTokenId, facetId, 6) &&
                place0ColorId == getCell(heroTokenId, facetId, 7) &&
                place0ColorId == getCell(heroTokenId, facetId, 8);
        }
        return false;
    }

    function cellIsDone(uint256 heroTokenId, uint8 cellId)
        public
        view
        returns (bool)
    {
        return _cells[heroTokenId][cellId] != 0;
    }

    function cellIsDone(
        uint256 heroTokenId,
        uint8 facetId,
        uint8 placeId
    ) public view returns (bool) {
        return cellIsDone(heroTokenId, getCellId(facetId, placeId));
    }

    // id
    function getCellId(uint8 facetId, uint8 placeId)
        public
        pure
        returns (uint8 cellId)
    {
        cellId = facetId * totalPlaces + placeId;
    }

    function getCellId(uint256 itemTokenId) public pure returns (uint8) {
        return uint8(itemTokenId % totalCells);
    }

    function getPlaceId(uint256 itemTokenId) public pure returns (uint8) {
        return uint8(itemTokenId % totalPlaces);
    }

    function getFacetId(uint256 itemTokenId) public pure returns (uint8) {
        if (itemTokenId % totalCells < totalPlaces) return 0;
        else if (itemTokenId % totalCells < totalPlaces * 2) return 1;
        else return 2;
    }

    function getColorId(uint256 itemTokenId) public pure returns (uint8) {
        return uint8(itemTokenId % totalColors) + 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IFancyTokenSupplier {
    function supplyToken(uint256 maxTime) external returns (uint256);

    function sendRewards(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IFancyNftHeroesS1 {
    function extraRate(uint256 tokenId) external view returns (uint256);

    function addExtraRate(uint256 tokenId, uint256 extraRate) external;

    function mintsOf(address account) external view returns (uint256);

    function investorsRate() external view returns (uint256);

    function investorsRateOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IERC721Burnable {
    function burn(uint256 tokenId) external;

    function burnFrom(address from, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev The contract is intendent to help recovering arbitrary ERC20 tokens
 * accidentally transferred to the contract address.
 */
abstract contract RecoverableErc20ByOwner is Ownable {
    function _getRecoverableAmount(address tokenAddress)
        internal
        view
        virtual
        returns (uint256)
    {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    /**
     * @param tokenAddress ERC20 token's address to recover
     * @param amount to recover from contract's address
     * @param to address to receive tokens from the contract
     */
    function recoverFunds(
        address tokenAddress,
        uint256 amount,
        address to
    ) external virtual onlyOwner {
        uint256 recoverableAmount = _getRecoverableAmount(tokenAddress);
        require(
            amount <= recoverableAmount,
            "RecoverableByOwner: RECOVERABLE_AMOUNT_NOT_ENOUGH"
        );
        recoverErc20(tokenAddress, amount, to);
    }

    function recoverErc20(
        address tokenAddress,
        uint256 amount,
        address to
    ) private {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = tokenAddress.call(
            abi.encodeWithSelector(0xa9059cbb, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "RecoverableByOwner: TRANSFER_FAILED"
        );
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
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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