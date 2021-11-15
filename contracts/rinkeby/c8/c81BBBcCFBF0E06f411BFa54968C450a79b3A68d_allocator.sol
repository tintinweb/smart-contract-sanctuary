pragma solidity ^0.7.5;

//import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IRNG.sol";




struct request {
    IERC721Enumerable     token;
    address[]             vaults;
    address               recipient;
    bytes32               requestHash;
    bool                  callback;
    bool                  collected;
}
contract allocator is Ownable {
    // see you later allocator....

    IRNG                          public rnd;
    string                        public sixties_reference = "https://www.youtube.com/watch?v=1Hb66FH9AzI";

    mapping(bytes32 => request)   public requestsFromHashes;
    mapping(bytes32 => uint256[]) public repliesFromHashes;
    mapping(address => bytes32[]) public userRequests;

    mapping (address => mapping(address => bool)) public canRequestThisVault; // can this source access these tokens
    mapping (address => bool)                     public auth;

    mapping (address => uint)                     public vaultRequests;

    bool                                                 inside;

    event ImmediateResolution(address requestor,IERC721Enumerable token,address vault,address recipient,uint256 tokenId);
    event RandomCardRequested(address requestor,IERC721Enumerable token,address vault,address recipient, bytes32 requestHash);
    event VaultControlChanged(address operator, address vault, bool allow);
    event OperatorSet(address operator, bool enabled);

    modifier onlyAuth() {
        require (auth[msg.sender] || (msg.sender == owner()),"unauthorised");
        _;
    }

    modifier noCallbacks() {
        require (!inside, "No rentrancy");
        inside = true;
        _;
        inside = false;
    }

    constructor(IRNG _rnd) {
        rnd = _rnd;
    }

    function getMeRandomCardsWithCallback(IERC721Enumerable token, address[] memory vaults, address recipient) external noCallbacks onlyAuth returns (bytes32) {
        return getMeRandomCards(token, vaults, recipient, true);
    }

    function getMeRandomCardsWithoutCallback(IERC721Enumerable token, address[] memory vaults, address recipient) external noCallbacks onlyAuth  returns (bytes32){
        return getMeRandomCards(token, vaults, recipient, false);
    }

    function getMeRandomCards(IERC721Enumerable token, address[] memory vaults, address recipient, bool withCallback ) internal returns (bytes32) {
        require(vaults.length <= 8,"Max 8 draws");
        bytes32 requestHash;
        if (withCallback) {
            requestHash = rnd.requestRandomNumberWithCallback();
        } else {
            requestHash = rnd.requestRandomNumber();
        }
        userRequests[recipient].push(requestHash);
        requestsFromHashes[requestHash] = request(
                token,
                vaults,
                recipient,
                requestHash,
                withCallback,
                false
            );
        for (uint j = 0; j < vaults.length; j++) {
            address vault = vaults[j];
            require(token.isApprovedForAll(vault, address(this)),"Vault does not allow token transfers");
            require(canRequestThisVault[msg.sender][vault],"Caller is not allowed to access this vault");
            uint256 supply = token.balanceOf(vault);
            require(vaultRequests[vault] < supply, "Not enough tokens to fulfill request");
            // This assumes that all the cards in this wallet are of the correct category
            vaultRequests[vault]++;
            emit RandomCardRequested(msg.sender,token,vault,recipient,requestHash);
        }
        return requestHash;
    }

    function process(uint256 random, bytes32 _requestId) external {
        require(msg.sender == address(rnd), "Unauthorised");
        my_process(random,_requestId);
    }

    function my_process(uint256 random, bytes32 _requestId) internal {
        request memory req = requestsFromHashes[_requestId];
        uint256[] storage replies = repliesFromHashes[_requestId];
        uint256 len = req.vaults.length;
        for (uint j = 0; j < len; j++) {
            uint randX = random & 0xffffffff;
            address vault = req.vaults[j];
            uint256 bal = req.token.balanceOf(vault);
            uint256 tokenId = req.token.tokenOfOwnerByIndex(vault, randX % bal);
            req.token.transferFrom(vault,req.recipient,tokenId);
            vaultRequests[vault]--;
            replies.push(tokenId);
            random = random >> 32;
        }
        requestsFromHashes[_requestId].collected=true;
    }

    function pickUpMyCards() external  {
        pickUpCardsFor(msg.sender);
    }

    function pickUpCardsFor(address recipient) public noCallbacks {
        uint256 len = userRequests[recipient].length;
        for (uint j = 0; j < len;j++) {
            bytes32 reqHash = userRequests[recipient][j]; 
            request memory req = requestsFromHashes[reqHash];
            if (!req.collected) {
                if (rnd.isRequestComplete(reqHash)) {
                    uint256 random  = rnd.randomNumber(reqHash);
                    my_process(random,reqHash);
                }
            }
        }
    }

    function numberOfRequests(address _owner) external view returns (uint256) {
        return userRequests[_owner].length;
    }

    
    function numberOfReplies(bytes32 _requestId) external view returns (uint256) {
        return repliesFromHashes[_requestId].length;
    }

    

    // ADMIN ------------------------

    function setAuth(address operator, bool enabled) external onlyAuth {
        auth[operator] = enabled;
        emit OperatorSet(operator, enabled);
    }

    // VAULTS ------------------------

    function setVaultAccess(address operator, address vault, bool allow) external onlyAuth {
        canRequestThisVault[operator][vault] = allow;
        emit VaultControlChanged(operator, vault, allow);
    }

    function checkAccess(IERC721Enumerable token, address vault) external view returns (bool) {
        return token.isApprovedForAll(vault, address(this));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

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

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

abstract contract IRNG {

    function requestRandomNumber() external virtual returns (bytes32 requestId) ;

    function requestRandomNumberWithCallback( ) external virtual returns (bytes32) ;

    function isRequestComplete(bytes32 requestId) external virtual view returns (bool isCompleted) ; 

    function randomNumber(bytes32 requestId) external view virtual returns (uint256 randomNum) ;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

