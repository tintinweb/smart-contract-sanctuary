// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IHabitat.sol";
import "./interfaces/ICnM.sol";

contract CnMProxy is Ownable, Pausable {
    ICnM public cnmWithEth;
    ICnM public cnmWithCheddar;
    uint256 public PAID_TOKENS;
    uint16 public minted;
    IHabitat public habitat;

    struct CatMouse {
        bool isCat; // true if cat
        bool isCrazy; // true if cat is CrazyCatLady, only check if isCat equals to true
        uint8 roll; //0 - habitatless, 1 - Shack, 2 - Ranch, 3 - Mansion

        uint8 body;
        uint8 color;
        uint8 eyes;
        uint8 eyebrows;
        uint8 neck;
        uint8 glasses;
        uint8 hair;
        uint8 head;
        uint8 markings;
        uint8 mouth;
        uint8 nose;
        uint8 props;
        uint8 shirts;
    }

    /** CRITICAL TO SETUP / MODIFIERS */
    modifier requireContractsSet() {
        require(address(cnmWithEth) != address(0) && address(cnmWithCheddar) != address(0), "Contracts not set");
        _;
    }

    function setContracts(ICnM _cnmWithEth, ICnM _cnmWithCheddar, IHabitat _habitat) external onlyOwner {
        cnmWithEth = ICnM(_cnmWithEth);
        cnmWithCheddar = ICnM(_cnmWithCheddar);    
        habitat = _habitat;    
        minted = cnmWithCheddar.minted();
        PAID_TOKENS = cnmWithCheddar.getPaidTokens();
    }

    /**
    * Mint a token - any payment / game logic should be handled in the game contract.
    * This will just generate random 1 and mint a token to a designated address.
    */
    function mint(address recipient, uint256 seed) external whenNotPaused {
        cnmWithCheddar.mint(recipient, seed);
    }

    /**
    * Burn a token - any game logic should be handled before this function.
    */
    function burn(uint256 tokenId) external whenNotPaused {
        if(tokenId <= PAID_TOKENS) {
            cnmWithEth.burn(tokenId);
        } else {
            cnmWithCheddar.burn(tokenId);
        }
    }

    function setRoll(uint256 tokenId, uint8 habitatType) external whenNotPaused {
        if(tokenId <= PAID_TOKENS) {
            cnmWithEth.setRoll(tokenId, habitatType);
        } else {
            cnmWithCheddar.setRoll(tokenId, habitatType);
        }        
    }

    function updateOriginAccess(uint16[] memory tokenIds) external {        
        cnmWithCheddar.updateOriginAccess(tokenIds);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        if(tokenId <= PAID_TOKENS) {
            cnmWithEth.transferFrom(from, to, tokenId);
        } else {
            cnmWithCheddar.transferFrom(from, to, tokenId);
        }
    }
    /**
    * checks if a token is a Cat/Mouse
    * @param tokenId the ID of the token to check
    * @return bool - whether or not a token is a Cat
    */
    function isCat(uint256 tokenId) external view returns (bool) {
         if(tokenId <= PAID_TOKENS) {
            return cnmWithEth.isCat(tokenId);
        } else {
            return cnmWithCheddar.isCat(tokenId);
        }    
    }

    function isClaimable() external view returns (bool) {
        return cnmWithCheddar.isClaimable();
    }
    /**
    * checks if a token is a CrazyCatLady
    * @param tokenId the ID of the token to check
    * @return bool - whether or not a token is a CrazyCatLady
    */
    function isCrazyCatLady(uint256 tokenId) external view returns (bool) {
        if(tokenId <= PAID_TOKENS) {
            return cnmWithEth.isCrazyCatLady(tokenId);
        } else {
            return cnmWithCheddar.isCrazyCatLady(tokenId);
        }        
    }

    /**
    * returns the value of Mouse NFT's roll
    * @param tokenId the ID of the token to check
    * @return uint8 - 0, 1, 2, 3
    */
    function getTokenRoll(uint256 tokenId) external view returns (uint8) {
        if(tokenId <= PAID_TOKENS) {
            return cnmWithEth.getTokenRoll(tokenId);
        } else {
            return cnmWithCheddar.getTokenRoll(tokenId);
        }
    }

    function getMaxTokens() external view returns (uint256) {
        return cnmWithCheddar.getMaxTokens();
    }

    function getPaidTokens() external view returns (uint256) {
        return cnmWithCheddar.getPaidTokens();
    }
    /** ADMIN */
    /**
    * enables owner to pause / unpause minting
    */
    function setPaused(bool _paused) external requireContractsSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /** Traits */

    function getTokenTraits(uint256 tokenId) external view returns (ICnM.CatMouse memory) {
        if(tokenId <= PAID_TOKENS) {
            return cnmWithEth.getTokenTraits(tokenId);
        } else {
            return cnmWithCheddar.getTokenTraits(tokenId);
        }
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address addr;
        if(tokenId <= PAID_TOKENS) {
            addr = cnmWithEth.ownerOf(tokenId);
        } else {
            addr = cnmWithCheddar.ownerOf(tokenId);
        }
        return addr;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        if(address(habitat) == _msgSender()) {
            if(tokenId <= PAID_TOKENS) {
                try cnmWithEth.ownerOf(tokenId) {
                    cnmWithEth.transferFrom(from, to, tokenId);
                } catch (bytes memory reason) {}
            } else {
                try cnmWithCheddar.ownerOf(tokenId) {
                    cnmWithCheddar.transferFrom(from, to, tokenId);
                } catch (bytes memory reason) {}     
            }  
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual {
        if(address(habitat) == _msgSender()) {
            if(tokenId <= PAID_TOKENS) {
                try cnmWithEth.ownerOf(tokenId) {
                    cnmWithEth.transferFrom(from, to, tokenId);
                } catch (bytes memory reason) {}
            } else {
                try cnmWithCheddar.ownerOf(tokenId) {
                    cnmWithCheddar.transferFrom(from, to, tokenId);
                } catch (bytes memory reason) {}            
            }  
        }
    }

    function emitCatStakedEvent(address owner, uint256 tokenId) external whenNotPaused {
        if(tokenId <= PAID_TOKENS) {
            cnmWithEth.emitCatStakedEvent(owner, tokenId);
        } else {
            cnmWithCheddar.emitCatStakedEvent(owner, tokenId);
        }
    }

    /**
    * emit crazy cat stacked event
    * @param tokenId the ID of the token stacked
    */
    function emitCrazyCatStakedEvent(address owner, uint256 tokenId) external whenNotPaused {
        if(tokenId <= PAID_TOKENS) {
            cnmWithEth.emitCrazyCatStakedEvent(owner, tokenId);
        } else {
            cnmWithCheddar.emitCrazyCatStakedEvent(owner, tokenId);
        }
    }

    /**
    * emit mouse stacked event
    * @param tokenId the ID of the token stacked
    */
    function emitMouseStakedEvent(address owner, uint256 tokenId) external whenNotPaused {
        if(tokenId <= PAID_TOKENS) {
            cnmWithEth.emitMouseStakedEvent(owner, tokenId);
        } else {
            cnmWithCheddar.emitMouseStakedEvent(owner, tokenId);
        }
    }

    //----------------friedrich--------------
    /**
    * emit cat stacked event
    * @param tokenId the ID of the token stacked
    */
    function emitCatUnStakedEvent(address owner, uint256 tokenId) external whenNotPaused {
        if(tokenId <= PAID_TOKENS) {
            cnmWithEth.emitCatUnStakedEvent(owner, tokenId);
        } else {
            cnmWithCheddar.emitCatUnStakedEvent(owner, tokenId);
        }
    }

    /**
    * emit crazy cat stacked event
    * @param tokenId the ID of the token stacked
    */
    function emitCrazyCatUnStakedEvent(address owner, uint256 tokenId) external whenNotPaused {
        if(tokenId <= PAID_TOKENS) {
            cnmWithEth.emitCrazyCatUnStakedEvent(owner, tokenId);
        } else {
            cnmWithCheddar.emitCrazyCatUnStakedEvent(owner, tokenId);
        }
    }

    /**
    * emit mouse stacked event
    * @param tokenId the ID of the token stacked
    */
    function emitMouseUnStakedEvent(address owner, uint256 tokenId) external whenNotPaused {
        if(tokenId <= PAID_TOKENS) {
            cnmWithEth.emitMouseUnStakedEvent(owner, tokenId);
        } else {
            cnmWithCheddar.emitMouseUnStakedEvent(owner, tokenId);
        }
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
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface IHabitat {
  function addManyToStakingPool(address account, uint16[] calldata tokenIds) external;
  function addManyHouseToStakingPool(address account, uint16[] calldata tokenIds) external;
  function randomCatOwner(uint256 seed) external view returns (address);
  function randomCrazyCatOwner(uint256 seed) external view returns (address);
  function isOwner(uint256 tokenId, address owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ICnM is IERC721Enumerable {
    
    // Character NFT struct
    struct CatMouse {
        bool isCat; // true if cat
        bool isCrazy; // true if cat is CrazyCatLady, only check if isCat equals to true
        uint8 roll; //0 - habitatless, 1 - Shack, 2 - Ranch, 3 - Mansion

        uint8 body;
        uint8 color;
        uint8 eyes;
        uint8 eyebrows;
        uint8 neck;
        uint8 glasses;
        uint8 hair;
        uint8 head;
        uint8 markings;
        uint8 mouth;
        uint8 nose;
        uint8 props;
        uint8 shirts;
    }

    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64);
    function mint(address recipient, uint256 seed) external;
    // function setRoll(uint256 seed, uint256 tokenId, address addr) external;
    function setRoll(uint256 tokenId, uint8 habitatType) external;

    function emitCatStakedEvent(address owner,uint256 tokenId) external;
    function emitCrazyCatStakedEvent(address owner, uint256 tokenId) external;
    function emitMouseStakedEvent(address owner, uint256 tokenId) external;
    
    function emitCatUnStakedEvent(address owner, uint256 tokenId) external;
    function emitCrazyCatUnStakedEvent(address owner, uint256 tokenId) external;
    function emitMouseUnStakedEvent(address owner, uint256 tokenId) external;
    
    function burn(uint256 tokenId) external;
    function getPaidTokens() external view returns (uint256);
    function updateOriginAccess(uint16[] memory tokenIds) external;
    function isCat(uint256 tokenId) external view returns(bool);
    function isClaimable() external view returns(bool);
    function isCrazyCatLady(uint256 tokenId) external view returns(bool);
    function getTokenRoll(uint256 tokenId) external view returns(uint8);
    function getMaxTokens() external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (CatMouse memory);
    function minted() external view returns (uint16);
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