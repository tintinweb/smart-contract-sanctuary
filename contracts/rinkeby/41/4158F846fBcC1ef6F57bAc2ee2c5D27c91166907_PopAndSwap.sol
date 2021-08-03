/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.8.0;

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
    constructor () {
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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


// File @openzeppelin/contracts/token/ERC777/[email protected].1.0

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(address recipient, uint256 amount, bytes calldata data) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC1155/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}


// File contracts/IPopAndSwap.sol

pragma solidity ^0.8.0;

// --------------------------------------------------------------------------------------
//
// (c) PopAndSwap 03/08/2021
// Designed by, DeGatchi (https://github.com/DeGatchi).
//
// Inspired by the Steam (https://store.steampowered.com/) trading system.
//
// Growing up I spent majority of my time playing video games. Earnings items and
// racking up hours on a multitude of games (Rust, Gmod, LoL, etc). Some of these games
// reward you with Trading Card type items and in game specific skins for spending 
// time on the game. These items are tradable via the Steam trading system, where users
// are able to put their items in slots, wait for the other participant to
// deposit their items in (if they choose to), and `ready up`. When both participants
// have `readied up`, each user accepts the trade and the items swap and each person
// receives the other person's items. 
//
// My vision for this is a Steam like trading system for NFTs and ERC20s where users
// are able to transfer their `items` for whatever the opposing person proposes, without
// any third party, just like Steam. 
//
// The users approve the contract to move the assets user1 their wallets with 
// `safeTransferFrom` so it can move the assets user1 one user to the other directly.
//
// Frontend: approve the unlimited amount of the asset.
//
// --------------------------------------------------------------------------------------

interface IPopAndSwap {

    event NewTrade(
        uint256 indexed tradeId,
        address indexed user1,
        address indexed user2
    );
    event UserReady(
        uint256 indexed tradeId, 
        address indexed user
    );
    event TradeExecuted(
        uint256 indexed tradeId,
        address indexed user1,
        address indexed user2
    );
    event TradeCanceled(
        uint256 indexed tradeId,
        address indexed user1,
        address indexed user2
    );
}


// File contracts/PopAndSwap.sol

pragma solidity ^0.8.0;

// --------------------------------------------------------------------------------------
//
// (c) PopAndSwap 03/08/2021 | SPDX-License-Identifier: MIT
// Designed by, DeGatchi (https://github.com/DeGatchi).
//
// Inspired by the Steam (https://store.steampowered.com/) trading system.
//
// Growing up I spent majority of my time playing video games. Earnings items and
// racking up hours on a multitude of games (Rust, Gmod, LoL, etc). Some of these games
// reward you with Trading Card type items and in game specific skins for spending
// time on the game. These items are tradable via the Steam trading system, where users
// are able to put their items in slots, wait for the other participant to
// deposit their items in (if they choose to), and `ready up`. When both participants
// have `readied up`, each user accepts the trade and the items swap and each person
// receives the other person's items.
//
// My vision for this is a Steam like trading system for NFTs and ERC20s where users
// are able to transfer their `items` for whatever the opposing person proposes, without
// any third party, just like Steam.
//
// The users approve the contract to move the assets user1 their wallets with
// `safeTransferFrom` so it can move the assets user1 one user to the other directly.
//
// --------------------------------------------------------------------------------------

contract PopAndSwap is IPopAndSwap, Ownable {

    struct Trade {
        TokenDetails[] user1Tokens;
        TokenDetails[] user2Tokens;
        address user1;
        address user2;
        bool inactive; // whether trade is available
    }

    struct TokenDetails {
        address token;
        uint16 ercType; // either: 1(CRYPTOPUNK), 20, 777, 721 or 1155
        uint256[] ids;
        uint256[] amounts;
    }

    uint256 public serviceFee; // fee per swap execution
    address public bypass; // NFT to bypass the `serviceFee`
    uint256 public totalTrades; // total platform trades
    uint256 public timeOfLastTrade; // last platform trade

    mapping(uint256 => Trade) public trades; // total trades of user
    mapping(address => uint256) public userTrades; // total successful trades of user
    mapping(address => mapping(uint256 => uint256)) public userTradeTimes; // times of each trade

    // Trade creators are able to deactivate their active trades
    function cancelTrade(uint256 tradeId) external {
        Trade storage trade = trades[tradeId];
        require( msg.sender == trade.user1,  "cancelTrade: not trade creator");
        trade.inactive = true;
    }

    // Checks if the user has the tokens specified in the tradeId
    function currentBalOfUser(uint256 tradeId, address user) view external returns (bool hasBalance) {
        Trade memory trade = trades[tradeId];
        require(user == trade.user1 || user == trade.user2, "currentBalOfUser: not apart of trade");

        if (user == trade.user1) {
            if (trade.user1Tokens[0].token != address(0)) {
                for (uint8 i; i < trade.user1Tokens.length; i++) {
                    if (trade.user1Tokens[i].ercType == 20) {
                        if (!(IERC20(trade.user1Tokens[i].token).balanceOf(trade.user1) >= trade.user1Tokens[i].amounts[0])) {
                            return false;
                        } 
                    } else if (trade.user1Tokens[i].ercType == 777) { 
                        if (!(IERC777(trade.user1Tokens[i].token).balanceOf(msg.sender) >= trade.user1Tokens[i].amounts[0])) {
                            return false;
                        }
                    } else if (trade.user1Tokens[i].ercType == 721) {
                        for (uint8 id; id < trade.user1Tokens[i].ids.length; id++) {
                            if (IERC721(trade.user1Tokens[i].token).ownerOf(trade.user1Tokens[i].ids[id]) != trade.user1) {
                                return false;
                            }
                        }
                    } else if (trade.user1Tokens[i].ercType == 1155) {
                        for (uint8 id; id < trade.user1Tokens[i].ids.length; id++) {                       
                            if (!(IERC1155(trade.user1Tokens[i].token).balanceOf(trade.user1, trade.user2Tokens[i].ids[id]) >= trade.user1Tokens[i].amounts[id])) {
                                return false;
                            }
                        }
                    } 
                }
            }
        } else {
            if (trade.user2Tokens[0].token != address(0)) {
                for (uint8 i; i < trade.user2Tokens.length; i++) {
                    if (trade.user2Tokens[i].ercType == 20) {
                        if (!(IERC20(trade.user2Tokens[i].token).balanceOf(trade.user2) >= trade.user2Tokens[i].amounts[0])) {
                            return false;
                        } 
                    } else if (trade.user2Tokens[i].ercType == 777) { 
                        if (!(IERC777(trade.user2Tokens[i].token).balanceOf(msg.sender) >= trade.user2Tokens[i].amounts[0])) {
                            return false;
                        }
                    } else if (trade.user2Tokens[i].ercType == 721) {
                        for (uint8 id; id < trade.user2Tokens[i].ids.length; id++) {
                            if (IERC721(trade.user2Tokens[i].token).ownerOf(trade.user2Tokens[i].ids[id]) != trade.user2) {
                                return false;
                            }
                        }
                    } else if (trade.user2Tokens[i].ercType == 1155) {
                        for (uint8 id; id < trade.user2Tokens[i].ids.length; id++) {                       
                            if (!(IERC1155(trade.user2Tokens[i].token).balanceOf(trade.user2, trade.user2Tokens[i].ids[id]) >= trade.user2Tokens[i].amounts[id])) {
                                return false;
                            }
                        }
                    } 
                }
            }
        }
        return true;
    }

    // Create a P2P atomic trade w/o storing your tokens in the contract
    function createTrade(
        address to,
        TokenDetails[] memory givingTokens,
        TokenDetails[] memory gettingTokens
    ) external returns (uint256 tradeId) {
        if (givingTokens[0].token != address(0)) {
            for (uint8 i; i < givingTokens.length; i++) {
                if (givingTokens[i].ercType == 20) {
                    require(
                        IERC20(givingTokens[i].token).allowance(address(this), msg.sender) >= givingTokens[i].amounts[0], 
                        "createTrade: erc20 approval unset"
                    );
                } else if (givingTokens[i].ercType == 777) { 
                    require(
                        IERC777(givingTokens[i].token).isOperatorFor(address(this), msg.sender) || 
                        IERC20(givingTokens[i].token).allowance(msg.sender, address(this)) >= givingTokens[i].amounts[0],
                        "createTrade: erc777 operator and/or appproval unset"
                    );
                } else if (givingTokens[i].ercType == 721) {
                    // If approved for all isn't true, check each approval individually
                    if (!IERC721(givingTokens[i].token).isApprovedForAll(msg.sender, address(this))) {
                        for (uint8 id; id < givingTokens[i].ids.length; id++) {
                            require(
                                IERC721(givingTokens[i].token).getApproved(givingTokens[i].ids[id]) == address(this) , 
                                "createTrade: erc721 approval unset"
                            );
                        }
                    }
                } else if (givingTokens[i].ercType == 1155) {
                    require(
                        IERC1155(givingTokens[i].token).isApprovedForAll(msg.sender, address(this)), 
                        "createTrade: erc1155 approval unset"
                    );
                } else {
                    revert("createTrade: unsupported erc type");
                }
            }
        }

        Trade storage trade = trades[totalTrades];
        trade.user1 = msg.sender;
        trade.user2 = to;

        for (uint8 i; i < givingTokens.length; i++) {
            trade.user1Tokens.push(givingTokens[i]);
        }    
        
        for (uint8 i; i < gettingTokens.length; i++) {
            trade.user2Tokens.push(gettingTokens[i]);
        }  

        totalTrades++;
        emit NewTrade(totalTrades - 1, msg.sender, to);
        return totalTrades - 1;
    }

    function acceptTrade(uint256 tradeId) external {
        Trade storage trade = trades[tradeId];
        require(!trade.inactive, "acceptTrade: trade inactive");

        executeTrade(tradeId);
        trade.inactive = true;

        totalTrades++;
        userTrades[msg.sender]++;
        userTrades[trade.user1]++;
        timeOfLastTrade = block.timestamp;

        emit TradeExecuted(tradeId, trade.user1, trade.user2);
    }

    function executeTrade(uint256 tradeId) private {
        Trade memory trade = trades[tradeId];

        if (trade.user1Tokens[0].token != address(0)) {
            for (uint8 i; i < trade.user1Tokens.length; i++) {
                if (trade.user1Tokens[i].ercType == 20) {
                     IERC20(trade.user1Tokens[i].token).transferFrom(trade.user1, trade.user2, trade.user1Tokens[i].amounts[0]); 
                } else if (trade.user1Tokens[i].ercType == 777) { 
                    if (IERC777(trade.user1Tokens[i].token).isOperatorFor(address(this), msg.sender)) {
                        // If IERC777 operator was set
                        IERC777(trade.user1Tokens[i].token).operatorSend(trade.user1, trade.user2, trade.user1Tokens[i].amounts[0], '', '');
                    } else {
                        // If IERC20 allowance was set
                        IERC20(trade.user1Tokens[i].token).transferFrom(trade.user1, trade.user2, trade.user1Tokens[i].amounts[0]); 
                    }
                } else if (trade.user1Tokens[i].ercType == 721) {
                    for (uint8 id; id < trade.user1Tokens[i].ids.length; id++) {
                        IERC721(trade.user1Tokens[i].token).transferFrom(trade.user1, trade.user2, trade.user1Tokens[i].ids[id]);
                    }
                } else if (trade.user1Tokens[i].ercType == 1155) {
                    // If multiple ids, safeBatch to save gas
                    if (trade.user1Tokens[i].ids.length > 1) {
                        IERC1155(trade.user1Tokens[i].token).safeBatchTransferFrom(
                            trade.user1, 
                            trade.user2, 
                            trade.user1Tokens[i].ids,
                            trade.user1Tokens[i].amounts,
                            ""
                        );
                    } else {
                        // for single id
                        IERC1155(trade.user1Tokens[i].token).safeTransferFrom(
                            trade.user1, 
                            trade.user2, 
                            trade.user1Tokens[i].ids[0],
                            trade.user1Tokens[i].amounts[0],
                            ""
                        );
                    }
                } else {
                    revert("executeTrade: user 1 unsupported erc type");
                }
            }
        }

        if (trade.user2Tokens[0].token != address(0)) {
            for (uint8 i; i < trade.user2Tokens.length; i++) {
                if (trade.user2Tokens[i].ercType == 20) {
                     IERC20(trade.user2Tokens[i].token).transferFrom(trade.user2, trade.user1, trade.user2Tokens[i].amounts[0]); 
                } else if (trade.user2Tokens[i].ercType == 777) { 
                    if (IERC777(trade.user2Tokens[i].token).isOperatorFor(address(this), msg.sender)) {
                        // If IERC777 operator was set
                        IERC777(trade.user2Tokens[i].token).operatorSend(trade.user2, trade.user1, trade.user2Tokens[i].amounts[0], '', '');
                    } else {
                        // If IERC20 allowance was set
                        IERC20(trade.user2Tokens[i].token).transferFrom(trade.user2, trade.user1, trade.user2Tokens[i].amounts[0]); 
                    }
                } else if (trade.user2Tokens[i].ercType == 721) {
                    for (uint8 id; id < trade.user2Tokens[i].ids.length; id++) {
                        IERC721(trade.user2Tokens[i].token).transferFrom(trade.user2, trade.user1, trade.user2Tokens[i].ids[id]);
                    }
                } else if (trade.user2Tokens[i].ercType == 1155) {
                    // If multiple ids, safeBatch to save gas
                    if (trade.user2Tokens[i].ids.length > 1) {
                        IERC1155(trade.user2Tokens[i].token).safeBatchTransferFrom(
                            trade.user2, 
                            trade.user1, 
                            trade.user2Tokens[i].ids,
                            trade.user2Tokens[i].amounts,
                            ""
                        );
                    } else {
                        // for single id
                        IERC1155(trade.user2Tokens[i].token).safeTransferFrom(
                            trade.user2, 
                            trade.user1, 
                            trade.user2Tokens[i].ids[0],
                            trade.user2Tokens[i].amounts[0],
                            ""
                        );
                    }
                } else {
                    revert("executeTrade: user 2 unsupported erc type");
                }
            }
        }
    }
}