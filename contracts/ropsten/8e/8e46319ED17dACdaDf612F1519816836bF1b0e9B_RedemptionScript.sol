pragma solidity 0.5.17;

import {ITokenRecipient} from "../interfaces/ITokenRecipient.sol";
import {TBTCDepositToken} from "../system/TBTCDepositToken.sol";
import {TBTCToken} from "../system/TBTCToken.sol";
import {FeeRebateToken} from "../system/FeeRebateToken.sol";
import {VendingMachine} from "../system/VendingMachine.sol";
import {Deposit} from "../deposit/Deposit.sol";
import {BytesLib} from "@summa-tx/bitcoin-spv-sol/contracts/BytesLib.sol";

/// @notice A one-click script for redeeming TBTC into BTC.
/// @dev Wrapper script for VendingMachine.tbtcToBtc
/// This contract implements receiveApproval() and can therefore use
/// approveAndCall(). This pattern combines TBTC Token approval and
/// vendingMachine.tbtcToBtc() in a single transaction.
contract RedemptionScript is ITokenRecipient {
    using BytesLib for bytes;

    TBTCToken tbtcToken;
    VendingMachine vendingMachine;
    FeeRebateToken feeRebateToken;

    constructor(
        address _VendingMachine,
        address _TBTCToken,
        address _FeeRebateToken
    ) public {
        vendingMachine = VendingMachine(_VendingMachine);
        tbtcToken = TBTCToken(_TBTCToken);
        feeRebateToken = FeeRebateToken(_FeeRebateToken);
    }

    /// @notice Receives approval for a TBTC transfer, and calls `VendingMachine.tbtcToBtc` for a user.
    /// @dev Implements the approveAndCall receiver interface.
    /// @param _from The owner of the token who approved them for transfer.
    /// @param _amount Approved TBTC amount for the transfer.
    /// @param _extraData Encoded function call to `VendingMachine.tbtcToBtc`.
    function receiveApproval(
        address _from,
        uint256 _amount,
        address,
        bytes memory _extraData
    ) public {
        // not external to allow bytes memory parameters
        require(
            msg.sender == address(tbtcToken),
            "Only token contract can call receiveApproval"
        );

        tbtcToken.transferFrom(_from, address(this), _amount);
        tbtcToken.approve(address(vendingMachine), _amount);

        // Verify _extraData is a call to tbtcToBtc.
        bytes4 functionSignature;
        assembly {
            functionSignature := and(mload(add(_extraData, 0x20)), not(0xff))
        }
        require(
            functionSignature == vendingMachine.tbtcToBtc.selector,
            "Bad _extraData signature. Call must be to tbtcToBtc."
        );

        // We capture the `returnData` in order to forward any nested revert message
        // from the contract call.
        // solium-disable-next-line security/no-low-level-calls
        (bool success, bytes memory returnData) =
            address(vendingMachine).call(_extraData);

        string memory revertMessage;
        assembly {
            // A revert message is ABI-encoded as a call to Error(string).
            // Slicing the Error() signature (4 bytes) and Data offset (4 bytes)
            // leaves us with a pre-encoded string.
            // We also slice off the ABI-coded length of returnData (32).
            revertMessage := add(returnData, 0x44)
        }

        require(success, revertMessage);
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

pragma solidity ^0.5.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a `safeTransfer`. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

pragma solidity ^0.5.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity ^0.5.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * 
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either `approve` or `setApproveForAll`.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either `approve` or `setApproveForAll`.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

pragma solidity ^0.5.0;

import "./ERC721.sol";
import "./IERC721Metadata.sol";
import "../../introspection/ERC165.sol";

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /**
     * @dev Constructor function
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned by the msg.sender
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

pragma solidity ^0.5.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../drafts/Counters.sol";
import "../../introspection/ERC165.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => Counters.Counter) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use `safeTransferFrom` whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether the specified token exists.
     * @param tokenId uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke `onERC721Received` on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * This function is deprecated.
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Private function to clear current approval of a given token ID.
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.0;

import "./IERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * [EIP](https://eips.ethereum.org/EIPS/eip-165).
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others (`ERC165Checker`).
 *
 * For an implementation, see `ERC165`.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.5.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the `IERC165` interface.
 *
 * Contracts may inherit from this and call `_registerInterface` to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See `IERC165.supportsInterface`.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See `IERC165.supportsInterface`.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

pragma solidity ^0.5.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the SafeMath
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

pragma solidity ^0.5.10;

/** @title ValidateSPV*/
/** @author Summa (https://summa.one) */

import {BytesLib} from "./BytesLib.sol";
import {SafeMath} from "./SafeMath.sol";
import {BTCUtils} from "./BTCUtils.sol";


library ValidateSPV {

    using BTCUtils for bytes;
    using BTCUtils for uint256;
    using BytesLib for bytes;
    using SafeMath for uint256;

    enum InputTypes { NONE, LEGACY, COMPATIBILITY, WITNESS }
    enum OutputTypes { NONE, WPKH, WSH, OP_RETURN, PKH, SH, NONSTANDARD }

    uint256 constant ERR_BAD_LENGTH = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant ERR_INVALID_CHAIN = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe;
    uint256 constant ERR_LOW_WORK = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd;

    function getErrBadLength() internal pure returns (uint256) {
        return ERR_BAD_LENGTH;
    }

    function getErrInvalidChain() internal pure returns (uint256) {
        return ERR_INVALID_CHAIN;
    }

    function getErrLowWork() internal pure returns (uint256) {
        return ERR_LOW_WORK;
    }

    /// @notice                     Validates a tx inclusion in the block
    /// @dev                        `index` is not a reliable indicator of location within a block
    /// @param _txid                The txid (LE)
    /// @param _merkleRoot          The merkle root (as in the block header)
    /// @param _intermediateNodes   The proof's intermediate nodes (digests between leaf and root)
    /// @param _index               The leaf's index in the tree (0-indexed)
    /// @return                     true if fully valid, false otherwise
    function prove(
        bytes32 _txid,
        bytes32 _merkleRoot,
        bytes memory _intermediateNodes,
        uint _index
    ) internal pure returns (bool) {
        // Shortcut the empty-block case
        if (_txid == _merkleRoot && _index == 0 && _intermediateNodes.length == 0) {
            return true;
        }

        bytes memory _proof = abi.encodePacked(_txid, _intermediateNodes, _merkleRoot);
        // If the Merkle proof failed, bubble up error
        return _proof.verifyHash256Merkle(_index);
    }

    /// @notice             Hashes transaction to get txid
    /// @dev                Supports Legacy and Witness
    /// @param _version     4-bytes version
    /// @param _vin         Raw bytes length-prefixed input vector
    /// @param _vout        Raw bytes length-prefixed output vector
    /// @param _locktime   4-byte tx locktime
    /// @return             32-byte transaction id, little endian
    function calculateTxId(
        bytes memory _version,
        bytes memory _vin,
        bytes memory _vout,
        bytes memory _locktime
    ) internal pure returns (bytes32) {
        // Get transaction hash double-Sha256(version + nIns + inputs + nOuts + outputs + locktime)
        return abi.encodePacked(_version, _vin, _vout, _locktime).hash256();
    }

    /// @notice             Checks validity of header chain
    /// @notice             Compares the hash of each header to the prevHash in the next header
    /// @param _headers     Raw byte array of header chain
    /// @return             The total accumulated difficulty of the header chain, or an error code
    function validateHeaderChain(bytes memory _headers) internal view returns (uint256 _totalDifficulty) {

        // Check header chain length
        if (_headers.length % 80 != 0) {return ERR_BAD_LENGTH;}

        // Initialize header start index
        bytes32 _digest;

        _totalDifficulty = 0;

        for (uint256 _start = 0; _start < _headers.length; _start += 80) {

            // ith header start index and ith header
            bytes memory _header = _headers.slice(_start, 80);

            // After the first header, check that headers are in a chain
            if (_start != 0) {
                if (!validateHeaderPrevHash(_header, _digest)) {return ERR_INVALID_CHAIN;}
            }

            // ith header target
            uint256 _target = _header.extractTarget();

            // Require that the header has sufficient work
            _digest = _header.hash256View();
            if(uint256(_digest).reverseUint256() > _target) {
                return ERR_LOW_WORK;
            }

            // Add ith header difficulty to difficulty sum
            _totalDifficulty = _totalDifficulty.add(_target.calculateDifficulty());
        }
    }

    /// @notice             Checks validity of header work
    /// @param _digest      Header digest
    /// @param _target      The target threshold
    /// @return             true if header work is valid, false otherwise
    function validateHeaderWork(bytes32 _digest, uint256 _target) internal pure returns (bool) {
        if (_digest == bytes32(0)) {return false;}
        return (abi.encodePacked(_digest).reverseEndianness().bytesToUint() < _target);
    }

    /// @notice                     Checks validity of header chain
    /// @dev                        Compares current header prevHash to previous header's digest
    /// @param _header              The raw bytes header
    /// @param _prevHeaderDigest    The previous header's digest
    /// @return                     true if the connect is valid, false otherwise
    function validateHeaderPrevHash(bytes memory _header, bytes32 _prevHeaderDigest) internal pure returns (bool) {

        // Extract prevHash of current header
        bytes32 _prevHash = _header.extractPrevBlockLE().toBytes32();

        // Compare prevHash of current header to previous header's digest
        if (_prevHash != _prevHeaderDigest) {return false;}

        return true;
    }
}

pragma solidity ^0.5.10;

/*
The MIT License (MIT)

Copyright (c) 2016 Smart Contract Solutions, Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        require(c / _a == _b, "Overflow during multiplication.");
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
        return _a / _b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, "Underflow during subtraction.");
        return _a - _b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        require(c >= _a, "Overflow during addition.");
        return c;
    }
}

pragma solidity ^0.5.10;

/** @title CheckBitcoinSigs */
/** @author Summa (https://summa.one) */

import {BytesLib} from "./BytesLib.sol";
import {BTCUtils} from "./BTCUtils.sol";


library CheckBitcoinSigs {

    using BytesLib for bytes;
    using BTCUtils for bytes;

    /// @notice          Derives an Ethereum Account address from a pubkey
    /// @dev             The address is the last 20 bytes of the keccak256 of the address
    /// @param _pubkey   The public key X & Y. Unprefixed, as a 64-byte array
    /// @return          The account address
    function accountFromPubkey(bytes memory _pubkey) internal pure returns (address) {
        require(_pubkey.length == 64, "Pubkey must be 64-byte raw, uncompressed key.");

        // keccak hash of uncompressed unprefixed pubkey
        bytes32 _digest = keccak256(_pubkey);
        return address(uint256(_digest));
    }

    /// @notice          Calculates the p2wpkh output script of a pubkey
    /// @dev             Compresses keys to 33 bytes as required by Bitcoin
    /// @param _pubkey   The public key, compressed or uncompressed
    /// @return          The p2wkph output script
    function p2wpkhFromPubkey(bytes memory _pubkey) internal pure returns (bytes memory) {
        bytes memory _compressedPubkey;
        uint8 _prefix;

        if (_pubkey.length == 64) {
            _prefix = uint8(_pubkey[_pubkey.length - 1]) % 2 == 1 ? 3 : 2;
            _compressedPubkey = abi.encodePacked(_prefix, _pubkey.slice(0, 32));
        } else if (_pubkey.length == 65) {
            _prefix = uint8(_pubkey[_pubkey.length - 1]) % 2 == 1 ? 3 : 2;
            _compressedPubkey = abi.encodePacked(_prefix, _pubkey.slice(1, 32));
        } else {
            _compressedPubkey = _pubkey;
        }

        require(_compressedPubkey.length == 33, "Witness PKH requires compressed keys");

        bytes memory _pubkeyHash = _compressedPubkey.hash160();
        return abi.encodePacked(hex"0014", _pubkeyHash);
    }

    /// @notice          checks a signed message's validity under a pubkey
    /// @dev             does this using ecrecover because Ethereum has no soul
    /// @param _pubkey   the public key to check (64 bytes)
    /// @param _digest   the message digest signed
    /// @param _v        the signature recovery value
    /// @param _r        the signature r value
    /// @param _s        the signature s value
    /// @return          true if signature is valid, else false
    function checkSig(
        bytes memory _pubkey,
        bytes32 _digest,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal pure returns (bool) {
        require(_pubkey.length == 64, "Requires uncompressed unprefixed pubkey");
        address _expected = accountFromPubkey(_pubkey);
        address _actual = ecrecover(_digest, _v, _r, _s);
        return _actual == _expected;
    }

    /// @notice                     checks a signed message against a bitcoin p2wpkh output script
    /// @dev                        does this my verifying the p2wpkh matches an ethereum account
    /// @param _p2wpkhOutputScript  the bitcoin output script
    /// @param _pubkey              the uncompressed, unprefixed public key to check
    /// @param _digest              the message digest signed
    /// @param _v                   the signature recovery value
    /// @param _r                   the signature r value
    /// @param _s                   the signature s value
    /// @return                     true if signature is valid, else false
    function checkBitcoinSig(
        bytes memory _p2wpkhOutputScript,
        bytes memory _pubkey,
        bytes32 _digest,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal pure returns (bool) {
        require(_pubkey.length == 64, "Requires uncompressed unprefixed pubkey");

        bool _isExpectedSigner = keccak256(p2wpkhFromPubkey(_pubkey)) == keccak256(_p2wpkhOutputScript);  // is it the expected signer?
        if (!_isExpectedSigner) {return false;}

        bool _sigResult = checkSig(_pubkey, _digest, _v, _r, _s);
        return _sigResult;
    }

    /// @notice             checks if a message is the sha256 preimage of a digest
    /// @dev                this is NOT the hash256!  this step is necessary for ECDSA security!
    /// @param _digest      the digest
    /// @param _candidate   the purported preimage
    /// @return             true if the preimage matches the digest, else false
    function isSha256Preimage(
        bytes memory _candidate,
        bytes32 _digest
    ) internal pure returns (bool) {
        return sha256(_candidate) == _digest;
    }

    /// @notice             checks if a message is the keccak256 preimage of a digest
    /// @dev                this step is necessary for ECDSA security!
    /// @param _digest      the digest
    /// @param _candidate   the purported preimage
    /// @return             true if the preimage matches the digest, else false
    function isKeccak256Preimage(
        bytes memory _candidate,
        bytes32 _digest
    ) internal pure returns (bool) {
        return keccak256(_candidate) == _digest;
    }

    /// @notice                 calculates the signature hash of a Bitcoin transaction with the provided details
    /// @dev                    documented in bip143. many values are hardcoded here
    /// @param _outpoint        the bitcoin UTXO id (32-byte txid + 4-byte output index)
    /// @param _inputPKH        the input pubkeyhash (hash160(sender_pubkey))
    /// @param _inputValue      the value of the input in satoshi
    /// @param _outputValue     the value of the output in satoshi
    /// @param _outputScript    the length-prefixed output script
    /// @return                 the double-sha256 (hash256) signature hash as defined by bip143
    function wpkhSpendSighash(
        bytes memory _outpoint,  // 36-byte UTXO id
        bytes20 _inputPKH,       // 20-byte hash160
        bytes8 _inputValue,      // 8-byte LE
        bytes8 _outputValue,     // 8-byte LE
        bytes memory _outputScript    // lenght-prefixed output script
    ) internal pure returns (bytes32) {
        // Fixes elements to easily make a 1-in 1-out sighash digest
        // Does not support timelocks
        bytes memory _scriptCode = abi.encodePacked(
            hex"1976a914",  // length, dup, hash160, pkh_length
            _inputPKH,
            hex"88ac");  // equal, checksig
        bytes32 _hashOutputs = abi.encodePacked(
            _outputValue,  // 8-byte LE
            _outputScript).hash256();
        bytes memory _sighashPreimage = abi.encodePacked(
            hex"01000000",  // version
            _outpoint.hash256(),  // hashPrevouts
            hex"8cb9012517c817fead650287d61bdd9c68803b6bf9c64133dcab3e65b5a50cb9",  // hashSequence(00000000)
            _outpoint,  // outpoint
            _scriptCode,  // p2wpkh script code
            _inputValue,  // value of the input in 8-byte LE
            hex"00000000",  // input nSequence
            _hashOutputs,  // hash of the single output
            hex"00000000",  // nLockTime
            hex"01000000"  // SIGHASH_ALL
        );
        return _sighashPreimage.hash256();
    }

    /// @notice                 calculates the signature hash of a Bitcoin transaction with the provided details
    /// @dev                    documented in bip143. many values are hardcoded here
    /// @param _outpoint        the bitcoin UTXO id (32-byte txid + 4-byte output index)
    /// @param _inputPKH        the input pubkeyhash (hash160(sender_pubkey))
    /// @param _inputValue      the value of the input in satoshi
    /// @param _outputValue     the value of the output in satoshi
    /// @param _outputPKH       the output pubkeyhash (hash160(recipient_pubkey))
    /// @return                 the double-sha256 (hash256) signature hash as defined by bip143
    function wpkhToWpkhSighash(
        bytes memory _outpoint,  // 36-byte UTXO id
        bytes20 _inputPKH,  // 20-byte hash160
        bytes8 _inputValue,  // 8-byte LE
        bytes8 _outputValue,  // 8-byte LE
        bytes20 _outputPKH  // 20-byte hash160
    ) internal pure returns (bytes32) {
        return wpkhSpendSighash(
            _outpoint,
            _inputPKH,
            _inputValue,
            _outputValue,
            abi.encodePacked(
              hex"160014",  // wpkh tag
              _outputPKH)
            );
    }

    /// @notice                 Preserved for API compatibility with older version
    /// @dev                    documented in bip143. many values are hardcoded here
    /// @param _outpoint        the bitcoin UTXO id (32-byte txid + 4-byte output index)
    /// @param _inputPKH        the input pubkeyhash (hash160(sender_pubkey))
    /// @param _inputValue      the value of the input in satoshi
    /// @param _outputValue     the value of the output in satoshi
    /// @param _outputPKH       the output pubkeyhash (hash160(recipient_pubkey))
    /// @return                 the double-sha256 (hash256) signature hash as defined by bip143
    function oneInputOneOutputSighash(
        bytes memory _outpoint,  // 36-byte UTXO id
        bytes20 _inputPKH,  // 20-byte hash160
        bytes8 _inputValue,  // 8-byte LE
        bytes8 _outputValue,  // 8-byte LE
        bytes20 _outputPKH  // 20-byte hash160
    ) internal pure returns (bytes32) {
        return wpkhToWpkhSighash(_outpoint, _inputPKH, _inputValue, _outputValue, _outputPKH);
    }

}

pragma solidity ^0.5.10;

/*

https://github.com/GNSPS/solidity-bytes-utils/

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <https://unlicense.org>
*/


/** @title BytesLib **/
/** @author https://github.com/GNSPS **/

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
                add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes_slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes_slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                        ),
                        // and now shift left the number of bytes to
                        // leave space for the length in the slot
                        exp(0x100, sub(32, newlength))
                        ),
                        // increase length by the double of the memory
                        // bytes length
                        mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                    ),
                    and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(bytes memory _bytes, uint _start, uint _length) internal  pure returns (bytes memory res) {
        if (_length == 0) {
            return hex"";
        }
        uint _end = _start + _length;
        require(_end > _start && _bytes.length >= _end, "Slice out of bounds");

        assembly {
            // Alloc bytes array with additional 32 bytes afterspace and assign it's size
            res := mload(0x40)
            mstore(0x40, add(add(res, 64), _length))
            mstore(res, _length)

            // Compute distance between source and destination pointers
            let diff := sub(res, add(_bytes, _start))

            for {
                let src := add(add(_bytes, 32), _start)
                let end := add(src, _length)
            } lt(src, end) {
                src := add(src, 32)
            } {
                mstore(add(src, diff), mload(src))
            }
        }
    }

    function toAddress(bytes memory _bytes, uint _start) internal  pure returns (address) {
        uint _totalLen = _start + 20;
        require(_totalLen > _start && _bytes.length >= _totalLen, "Address conversion out of bounds.");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint(bytes memory _bytes, uint _start) internal  pure returns (uint256) {
        uint _totalLen = _start + 32;
        require(_totalLen > _start && _bytes.length >= _totalLen, "Uint conversion out of bounds.");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    // the next line is the loop condition:
                    // while(uint(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes_slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes_slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function toBytes32(bytes memory _source) pure internal returns (bytes32 result) {
        if (_source.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(_source, 32))
        }
    }

    function keccak256Slice(bytes memory _bytes, uint _start, uint _length) pure internal returns (bytes32 result) {
        uint _end = _start + _length;
        require(_end > _start && _bytes.length >= _end, "Slice out of bounds");

        assembly {
            result := keccak256(add(add(_bytes, 32), _start), _length)
        }
    }
}

pragma solidity ^0.5.10;

/** @title BitcoinSPV */
/** @author Summa (https://summa.one) */

import {BytesLib} from "./BytesLib.sol";
import {SafeMath} from "./SafeMath.sol";

library BTCUtils {
    using BytesLib for bytes;
    using SafeMath for uint256;

    // The target at minimum Difficulty. Also the target of the genesis block
    uint256 public constant DIFF1_TARGET = 0xffff0000000000000000000000000000000000000000000000000000;

    uint256 public constant RETARGET_PERIOD = 2 * 7 * 24 * 60 * 60;  // 2 weeks in seconds
    uint256 public constant RETARGET_PERIOD_BLOCKS = 2016;  // 2 weeks in blocks

    uint256 public constant ERR_BAD_ARG = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /* ***** */
    /* UTILS */
    /* ***** */

    /// @notice         Determines the length of a VarInt in bytes
    /// @dev            A VarInt of >1 byte is prefixed with a flag indicating its length
    /// @param _flag    The first byte of a VarInt
    /// @return         The number of non-flag bytes in the VarInt
    function determineVarIntDataLength(bytes memory _flag) internal pure returns (uint8) {
        if (uint8(_flag[0]) == 0xff) {
            return 8;  // one-byte flag, 8 bytes data
        }
        if (uint8(_flag[0]) == 0xfe) {
            return 4;  // one-byte flag, 4 bytes data
        }
        if (uint8(_flag[0]) == 0xfd) {
            return 2;  // one-byte flag, 2 bytes data
        }

        return 0;  // flag is data
    }

    /// @notice     Parse a VarInt into its data length and the number it represents
    /// @dev        Useful for Parsing Vins and Vouts. Returns ERR_BAD_ARG if insufficient bytes.
    ///             Caller SHOULD explicitly handle this case (or bubble it up)
    /// @param _b   A byte-string starting with a VarInt
    /// @return     number of bytes in the encoding (not counting the tag), the encoded int
    function parseVarInt(bytes memory _b) internal pure returns (uint256, uint256) {
        uint8 _dataLen = determineVarIntDataLength(_b);

        if (_dataLen == 0) {
            return (0, uint8(_b[0]));
        }
        if (_b.length < 1 + _dataLen) {
            return (ERR_BAD_ARG, 0);
        }
        uint256 _number = bytesToUint(reverseEndianness(_b.slice(1, _dataLen)));
        return (_dataLen, _number);
    }

    /// @notice          Changes the endianness of a byte array
    /// @dev             Returns a new, backwards, bytes
    /// @param _b        The bytes to reverse
    /// @return          The reversed bytes
    function reverseEndianness(bytes memory _b) internal pure returns (bytes memory) {
        bytes memory _newValue = new bytes(_b.length);

        for (uint i = 0; i < _b.length; i++) {
            _newValue[_b.length - i - 1] = _b[i];
        }

        return _newValue;
    }

    /// @notice          Changes the endianness of a uint256
    /// @dev             https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel
    /// @param _b        The unsigned integer to reverse
    /// @return          The reversed value
    function reverseUint256(uint256 _b) internal pure returns (uint256 v) {
        v = _b;

        // swap bytes
        v = ((v >> 8) & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
        // swap 2-byte long pairs
        v = ((v >> 16) & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
        // swap 4-byte long pairs
        v = ((v >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);
        // swap 8-byte long pairs
        v = ((v >> 64) & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) |
            ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);
        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }

    /// @notice          Converts big-endian bytes to a uint
    /// @dev             Traverses the byte array and sums the bytes
    /// @param _b        The big-endian bytes-encoded integer
    /// @return          The integer representation
    function bytesToUint(bytes memory _b) internal pure returns (uint256) {
        uint256 _number;

        for (uint i = 0; i < _b.length; i++) {
            _number = _number + uint8(_b[i]) * (2 ** (8 * (_b.length - (i + 1))));
        }

        return _number;
    }

    /// @notice          Get the last _num bytes from a byte array
    /// @param _b        The byte array to slice
    /// @param _num      The number of bytes to extract from the end
    /// @return          The last _num bytes of _b
    function lastBytes(bytes memory _b, uint256 _num) internal pure returns (bytes memory) {
        uint256 _start = _b.length.sub(_num);

        return _b.slice(_start, _num);
    }

    /// @notice          Implements bitcoin's hash160 (rmd160(sha2()))
    /// @dev             abi.encodePacked changes the return to bytes instead of bytes32
    /// @param _b        The pre-image
    /// @return          The digest
    function hash160(bytes memory _b) internal pure returns (bytes memory) {
        return abi.encodePacked(ripemd160(abi.encodePacked(sha256(_b))));
    }

    /// @notice          Implements bitcoin's hash256 (double sha2)
    /// @dev             abi.encodePacked changes the return to bytes instead of bytes32
    /// @param _b        The pre-image
    /// @return          The digest
    function hash256(bytes memory _b) internal pure returns (bytes32) {
        return sha256(abi.encodePacked(sha256(_b)));
    }

    /// @notice          Implements bitcoin's hash256 (double sha2)
    /// @dev             sha2 is precompiled smart contract located at address(2)
    /// @param _b        The pre-image
    /// @return          The digest
    function hash256View(bytes memory _b) internal view returns (bytes32 res) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            pop(staticcall(gas, 2, add(_b, 32), mload(_b), ptr, 32))
            pop(staticcall(gas, 2, ptr, 32, ptr, 32))
            res := mload(ptr)
        }
    }

    /* ************ */
    /* Legacy Input */
    /* ************ */

    /// @notice          Extracts the nth input from the vin (0-indexed)
    /// @dev             Iterates over the vin. If you need to extract several, write a custom function
    /// @param _vin      The vin as a tightly-packed byte array
    /// @param _index    The 0-indexed location of the input to extract
    /// @return          The input as a byte array
    function extractInputAtIndex(bytes memory _vin, uint256 _index) internal pure returns (bytes memory) {
        uint256 _varIntDataLen;
        uint256 _nIns;

        (_varIntDataLen, _nIns) = parseVarInt(_vin);
        require(_varIntDataLen != ERR_BAD_ARG, "Read overrun during VarInt parsing");
        require(_index < _nIns, "Vin read overrun");

        bytes memory _remaining;

        uint256 _len = 0;
        uint256 _offset = 1 + _varIntDataLen;

        for (uint256 _i = 0; _i < _index; _i ++) {
            _remaining = _vin.slice(_offset, _vin.length - _offset);
            _len = determineInputLength(_remaining);
            require(_len != ERR_BAD_ARG, "Bad VarInt in scriptSig");
            _offset = _offset + _len;
        }

        _remaining = _vin.slice(_offset, _vin.length - _offset);
        _len = determineInputLength(_remaining);
        require(_len != ERR_BAD_ARG, "Bad VarInt in scriptSig");
        return _vin.slice(_offset, _len);
    }

    /// @notice          Determines whether an input is legacy
    /// @dev             False if no scriptSig, otherwise True
    /// @param _input    The input
    /// @return          True for legacy, False for witness
    function isLegacyInput(bytes memory _input) internal pure returns (bool) {
        return _input.keccak256Slice(36, 1) != keccak256(hex"00");
    }

    /// @notice          Determines the length of a scriptSig in an input
    /// @dev             Will return 0 if passed a witness input.
    /// @param _input    The LEGACY input
    /// @return          The length of the script sig
    function extractScriptSigLen(bytes memory _input) internal pure returns (uint256, uint256) {
        if (_input.length < 37) {
            return (ERR_BAD_ARG, 0);
        }
        bytes memory _afterOutpoint = _input.slice(36, _input.length - 36);

        uint256 _varIntDataLen;
        uint256 _scriptSigLen;
        (_varIntDataLen, _scriptSigLen) = parseVarInt(_afterOutpoint);

        return (_varIntDataLen, _scriptSigLen);
    }

    /// @notice          Determines the length of an input from its scriptSig
    /// @dev             36 for outpoint, 1 for scriptSig length, 4 for sequence
    /// @param _input    The input
    /// @return          The length of the input in bytes
    function determineInputLength(bytes memory _input) internal pure returns (uint256) {
        uint256 _varIntDataLen;
        uint256 _scriptSigLen;
        (_varIntDataLen, _scriptSigLen) = extractScriptSigLen(_input);
        if (_varIntDataLen == ERR_BAD_ARG) {
            return ERR_BAD_ARG;
        }

        return 36 + 1 + _varIntDataLen + _scriptSigLen + 4;
    }

    /// @notice          Extracts the LE sequence bytes from an input
    /// @dev             Sequence is used for relative time locks
    /// @param _input    The LEGACY input
    /// @return          The sequence bytes (LE uint)
    function extractSequenceLELegacy(bytes memory _input) internal pure returns (bytes memory) {
        uint256 _varIntDataLen;
        uint256 _scriptSigLen;
        (_varIntDataLen, _scriptSigLen) = extractScriptSigLen(_input);
        require(_varIntDataLen != ERR_BAD_ARG, "Bad VarInt in scriptSig");
        return _input.slice(36 + 1 + _varIntDataLen + _scriptSigLen, 4);
    }

    /// @notice          Extracts the sequence from the input
    /// @dev             Sequence is a 4-byte little-endian number
    /// @param _input    The LEGACY input
    /// @return          The sequence number (big-endian uint)
    function extractSequenceLegacy(bytes memory _input) internal pure returns (uint32) {
        bytes memory _leSeqence = extractSequenceLELegacy(_input);
        bytes memory _beSequence = reverseEndianness(_leSeqence);
        return uint32(bytesToUint(_beSequence));
    }
    /// @notice          Extracts the VarInt-prepended scriptSig from the input in a tx
    /// @dev             Will return hex"00" if passed a witness input
    /// @param _input    The LEGACY input
    /// @return          The length-prepended scriptSig
    function extractScriptSig(bytes memory _input) internal pure returns (bytes memory) {
        uint256 _varIntDataLen;
        uint256 _scriptSigLen;
        (_varIntDataLen, _scriptSigLen) = extractScriptSigLen(_input);
        require(_varIntDataLen != ERR_BAD_ARG, "Bad VarInt in scriptSig");
        return _input.slice(36, 1 + _varIntDataLen + _scriptSigLen);
    }


    /* ************* */
    /* Witness Input */
    /* ************* */

    /// @notice          Extracts the LE sequence bytes from an input
    /// @dev             Sequence is used for relative time locks
    /// @param _input    The WITNESS input
    /// @return          The sequence bytes (LE uint)
    function extractSequenceLEWitness(bytes memory _input) internal pure returns (bytes memory) {
        return _input.slice(37, 4);
    }

    /// @notice          Extracts the sequence from the input in a tx
    /// @dev             Sequence is a 4-byte little-endian number
    /// @param _input    The WITNESS input
    /// @return          The sequence number (big-endian uint)
    function extractSequenceWitness(bytes memory _input) internal pure returns (uint32) {
        bytes memory _leSeqence = extractSequenceLEWitness(_input);
        bytes memory _inputeSequence = reverseEndianness(_leSeqence);
        return uint32(bytesToUint(_inputeSequence));
    }

    /// @notice          Extracts the outpoint from the input in a tx
    /// @dev             32-byte tx id with 4-byte index
    /// @param _input    The input
    /// @return          The outpoint (LE bytes of prev tx hash + LE bytes of prev tx index)
    function extractOutpoint(bytes memory _input) internal pure returns (bytes memory) {
        return _input.slice(0, 36);
    }

    /// @notice          Extracts the outpoint tx id from an input
    /// @dev             32-byte tx id
    /// @param _input    The input
    /// @return          The tx id (little-endian bytes)
    function extractInputTxIdLE(bytes memory _input) internal pure returns (bytes32) {
        return _input.slice(0, 32).toBytes32();
    }

    /// @notice          Extracts the LE tx input index from the input in a tx
    /// @dev             4-byte tx index
    /// @param _input    The input
    /// @return          The tx index (little-endian bytes)
    function extractTxIndexLE(bytes memory _input) internal pure returns (bytes memory) {
        return _input.slice(32, 4);
    }

    /* ****** */
    /* Output */
    /* ****** */

    /// @notice          Determines the length of an output
    /// @dev             Works with any properly formatted output
    /// @param _output   The output
    /// @return          The length indicated by the prefix, error if invalid length
    function determineOutputLength(bytes memory _output) internal pure returns (uint256) {
        if (_output.length < 9) {
            return ERR_BAD_ARG;
        }
        bytes memory _afterValue = _output.slice(8, _output.length - 8);

        uint256 _varIntDataLen;
        uint256 _scriptPubkeyLength;
        (_varIntDataLen, _scriptPubkeyLength) = parseVarInt(_afterValue);

        if (_varIntDataLen == ERR_BAD_ARG) {
            return ERR_BAD_ARG;
        }

        // 8-byte value, 1-byte for tag itself
        return 8 + 1 + _varIntDataLen + _scriptPubkeyLength;
    }

    /// @notice          Extracts the output at a given index in the TxOuts vector
    /// @dev             Iterates over the vout. If you need to extract multiple, write a custom function
    /// @param _vout     The _vout to extract from
    /// @param _index    The 0-indexed location of the output to extract
    /// @return          The specified output
    function extractOutputAtIndex(bytes memory _vout, uint256 _index) internal pure returns (bytes memory) {
        uint256 _varIntDataLen;
        uint256 _nOuts;

        (_varIntDataLen, _nOuts) = parseVarInt(_vout);
        require(_varIntDataLen != ERR_BAD_ARG, "Read overrun during VarInt parsing");
        require(_index < _nOuts, "Vout read overrun");

        bytes memory _remaining;

        uint256 _len = 0;
        uint256 _offset = 1 + _varIntDataLen;

        for (uint256 _i = 0; _i < _index; _i ++) {
            _remaining = _vout.slice(_offset, _vout.length - _offset);
            _len = determineOutputLength(_remaining);
            require(_len != ERR_BAD_ARG, "Bad VarInt in scriptPubkey");
            _offset += _len;
        }

        _remaining = _vout.slice(_offset, _vout.length - _offset);
        _len = determineOutputLength(_remaining);
        require(_len != ERR_BAD_ARG, "Bad VarInt in scriptPubkey");
        return _vout.slice(_offset, _len);
    }

    /// @notice          Extracts the value bytes from the output in a tx
    /// @dev             Value is an 8-byte little-endian number
    /// @param _output   The output
    /// @return          The output value as LE bytes
    function extractValueLE(bytes memory _output) internal pure returns (bytes memory) {
        return _output.slice(0, 8);
    }

    /// @notice          Extracts the value from the output in a tx
    /// @dev             Value is an 8-byte little-endian number
    /// @param _output   The output
    /// @return          The output value
    function extractValue(bytes memory _output) internal pure returns (uint64) {
        bytes memory _leValue = extractValueLE(_output);
        bytes memory _beValue = reverseEndianness(_leValue);
        return uint64(bytesToUint(_beValue));
    }

    /// @notice          Extracts the data from an op return output
    /// @dev             Returns hex"" if no data or not an op return
    /// @param _output   The output
    /// @return          Any data contained in the opreturn output, null if not an op return
    function extractOpReturnData(bytes memory _output) internal pure returns (bytes memory) {
        if (_output.keccak256Slice(9, 1) != keccak256(hex"6a")) {
            return hex"";
        }
        bytes memory _dataLen = _output.slice(10, 1);
        return _output.slice(11, bytesToUint(_dataLen));
    }

    /// @notice          Extracts the hash from the output script
    /// @dev             Determines type by the length prefix and validates format
    /// @param _output   The output
    /// @return          The hash committed to by the pk_script, or null for errors
    function extractHash(bytes memory _output) internal pure returns (bytes memory) {
        uint8 _scriptLen = uint8(_output[8]);

        // don't have to worry about overflow here.
        // if _scriptLen + 9 overflows, then output.length would have to be < 9
        // for this check to pass. if it's < 9, then we errored when assigning
        // _scriptLen
        if (_scriptLen + 9 != _output.length) {
            return hex"";
        }

        if (uint8(_output[9]) == 0) {
            if (_scriptLen < 2) {
                return hex"";
            }
            uint256 _payloadLen = uint8(_output[10]);
            // Check for maliciously formatted witness outputs.
            // No need to worry about underflow as long b/c of the `< 2` check
            if (_payloadLen != _scriptLen - 2 || (_payloadLen != 0x20 && _payloadLen != 0x14)) {
                return hex"";
            }
            return _output.slice(11, _payloadLen);
        } else {
            bytes32 _tag = _output.keccak256Slice(8, 3);
            // p2pkh
            if (_tag == keccak256(hex"1976a9")) {
                // Check for maliciously formatted p2pkh
                // No need to worry about underflow, b/c of _scriptLen check
                if (uint8(_output[11]) != 0x14 ||
                    _output.keccak256Slice(_output.length - 2, 2) != keccak256(hex"88ac")) {
                    return hex"";
                }
                return _output.slice(12, 20);
            //p2sh
            } else if (_tag == keccak256(hex"17a914")) {
                // Check for maliciously formatted p2sh
                // No need to worry about underflow, b/c of _scriptLen check
                if (uint8(_output[_output.length - 1]) != 0x87) {
                    return hex"";
                }
                return _output.slice(11, 20);
            }
        }
        return hex"";  /* NB: will trigger on OPRETURN and any non-standard that doesn't overrun */
    }

    /* ********** */
    /* Witness TX */
    /* ********** */


    /// @notice      Checks that the vin passed up is properly formatted
    /// @dev         Consider a vin with a valid vout in its scriptsig
    /// @param _vin  Raw bytes length-prefixed input vector
    /// @return      True if it represents a validly formatted vin
    function validateVin(bytes memory _vin) internal pure returns (bool) {
        uint256 _varIntDataLen;
        uint256 _nIns;

        (_varIntDataLen, _nIns) = parseVarInt(_vin);

        // Not valid if it says there are too many or no inputs
        if (_nIns == 0 || _varIntDataLen == ERR_BAD_ARG) {
            return false;
        }

        uint256 _offset = 1 + _varIntDataLen;

        for (uint256 i = 0; i < _nIns; i++) {
            // If we're at the end, but still expect more
            if (_offset >= _vin.length) {
                return false;
            }

            // Grab the next input and determine its length.
            bytes memory _next = _vin.slice(_offset, _vin.length - _offset);
            uint256 _nextLen = determineInputLength(_next);
            if (_nextLen == ERR_BAD_ARG) {
                return false;
            }

            // Increase the offset by that much
            _offset += _nextLen;
        }

        // Returns false if we're not exactly at the end
        return _offset == _vin.length;
    }

    /// @notice      Checks that the vout passed up is properly formatted
    /// @dev         Consider a vout with a valid scriptpubkey
    /// @param _vout Raw bytes length-prefixed output vector
    /// @return      True if it represents a validly formatted vout
    function validateVout(bytes memory _vout) internal pure returns (bool) {
        uint256 _varIntDataLen;
        uint256 _nOuts;

        (_varIntDataLen, _nOuts) = parseVarInt(_vout);

        // Not valid if it says there are too many or no outputs
        if (_nOuts == 0 || _varIntDataLen == ERR_BAD_ARG) {
            return false;
        }

        uint256 _offset = 1 + _varIntDataLen;

        for (uint256 i = 0; i < _nOuts; i++) {
            // If we're at the end, but still expect more
            if (_offset >= _vout.length) {
                return false;
            }

            // Grab the next output and determine its length.
            // Increase the offset by that much
            bytes memory _next = _vout.slice(_offset, _vout.length - _offset);
            uint256 _nextLen = determineOutputLength(_next);
            if (_nextLen == ERR_BAD_ARG) {
                return false;
            }

            _offset += _nextLen;
        }

        // Returns false if we're not exactly at the end
        return _offset == _vout.length;
    }



    /* ************ */
    /* Block Header */
    /* ************ */

    /// @notice          Extracts the transaction merkle root from a block header
    /// @dev             Use verifyHash256Merkle to verify proofs with this root
    /// @param _header   The header
    /// @return          The merkle root (little-endian)
    function extractMerkleRootLE(bytes memory _header) internal pure returns (bytes memory) {
        return _header.slice(36, 32);
    }

    /// @notice          Extracts the target from a block header
    /// @dev             Target is a 256-bit number encoded as a 3-byte mantissa and 1-byte exponent
    /// @param _header   The header
    /// @return          The target threshold
    function extractTarget(bytes memory _header) internal pure returns (uint256) {
        bytes memory _m = _header.slice(72, 3);
        uint8 _e = uint8(_header[75]);
        uint256 _mantissa = bytesToUint(reverseEndianness(_m));
        uint _exponent = _e - 3;

        return _mantissa * (256 ** _exponent);
    }

    /// @notice          Calculate difficulty from the difficulty 1 target and current target
    /// @dev             Difficulty 1 is 0x1d00ffff on mainnet and testnet
    /// @dev             Difficulty 1 is a 256-bit number encoded as a 3-byte mantissa and 1-byte exponent
    /// @param _target   The current target
    /// @return          The block difficulty (bdiff)
    function calculateDifficulty(uint256 _target) internal pure returns (uint256) {
        // Difficulty 1 calculated from 0x1d00ffff
        return DIFF1_TARGET.div(_target);
    }

    /// @notice          Extracts the previous block's hash from a block header
    /// @dev             Block headers do NOT include block number :(
    /// @param _header   The header
    /// @return          The previous block's hash (little-endian)
    function extractPrevBlockLE(bytes memory _header) internal pure returns (bytes memory) {
        return _header.slice(4, 32);
    }

    /// @notice          Extracts the timestamp from a block header
    /// @dev             Time is not 100% reliable
    /// @param _header   The header
    /// @return          The timestamp (little-endian bytes)
    function extractTimestampLE(bytes memory _header) internal pure returns (bytes memory) {
        return _header.slice(68, 4);
    }

    /// @notice          Extracts the timestamp from a block header
    /// @dev             Time is not 100% reliable
    /// @param _header   The header
    /// @return          The timestamp (uint)
    function extractTimestamp(bytes memory _header) internal pure returns (uint32) {
        return uint32(bytesToUint(reverseEndianness(extractTimestampLE(_header))));
    }

    /// @notice          Extracts the expected difficulty from a block header
    /// @dev             Does NOT verify the work
    /// @param _header   The header
    /// @return          The difficulty as an integer
    function extractDifficulty(bytes memory _header) internal pure returns (uint256) {
        return calculateDifficulty(extractTarget(_header));
    }

    /// @notice          Concatenates and hashes two inputs for merkle proving
    /// @param _a        The first hash
    /// @param _b        The second hash
    /// @return          The double-sha256 of the concatenated hashes
    function _hash256MerkleStep(bytes memory _a, bytes memory _b) internal pure returns (bytes32) {
        return hash256(abi.encodePacked(_a, _b));
    }

    /// @notice          Verifies a Bitcoin-style merkle tree
    /// @dev             Leaves are 0-indexed.
    /// @param _proof    The proof. Tightly packed LE sha256 hashes. The last hash is the root
    /// @param _index    The index of the leaf
    /// @return          true if the proof is valid, else false
    function verifyHash256Merkle(bytes memory _proof, uint _index) internal pure returns (bool) {
        // Not an even number of hashes
        if (_proof.length % 32 != 0) {
            return false;
        }

        // Special case for coinbase-only blocks
        if (_proof.length == 32) {
            return true;
        }

        // Should never occur
        if (_proof.length == 64) {
            return false;
        }

        uint _idx = _index;
        bytes32 _root = _proof.slice(_proof.length - 32, 32).toBytes32();
        bytes32 _current = _proof.slice(0, 32).toBytes32();

        for (uint i = 1; i < (_proof.length.div(32)) - 1; i++) {
            if (_idx % 2 == 1) {
                _current = _hash256MerkleStep(_proof.slice(i * 32, 32), abi.encodePacked(_current));
            } else {
                _current = _hash256MerkleStep(abi.encodePacked(_current), _proof.slice(i * 32, 32));
            }
            _idx = _idx >> 1;
        }
        return _current == _root;
    }

    /*
    NB: https://github.com/bitcoin/bitcoin/blob/78dae8caccd82cfbfd76557f1fb7d7557c7b5edb/src/pow.cpp#L49-L72
    NB: We get a full-bitlength target from this. For comparison with
        header-encoded targets we need to mask it with the header target
        e.g. (full & truncated) == truncated
    */
    /// @notice                 performs the bitcoin difficulty retarget
    /// @dev                    implements the Bitcoin algorithm precisely
    /// @param _previousTarget  the target of the previous period
    /// @param _firstTimestamp  the timestamp of the first block in the difficulty period
    /// @param _secondTimestamp the timestamp of the last block in the difficulty period
    /// @return                 the new period's target threshold
    function retargetAlgorithm(
        uint256 _previousTarget,
        uint256 _firstTimestamp,
        uint256 _secondTimestamp
    ) internal pure returns (uint256) {
        uint256 _elapsedTime = _secondTimestamp.sub(_firstTimestamp);

        // Normalize ratio to factor of 4 if very long or very short
        if (_elapsedTime < RETARGET_PERIOD.div(4)) {
            _elapsedTime = RETARGET_PERIOD.div(4);
        }
        if (_elapsedTime > RETARGET_PERIOD.mul(4)) {
            _elapsedTime = RETARGET_PERIOD.mul(4);
        }

        /*
          NB: high targets e.g. ffff0020 can cause overflows here
              so we divide it by 256**2, then multiply by 256**2 later
              we know the target is evenly divisible by 256**2, so this isn't an issue
        */

        uint256 _adjusted = _previousTarget.div(65536).mul(_elapsedTime);
        return _adjusted.div(RETARGET_PERIOD).mul(65536);
    }
}

/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

/// @title ECDSA Keep
/// @notice Contract reflecting an ECDSA keep.
contract IBondedECDSAKeep {
    /// @notice Returns public key of this keep.
    /// @return Keeps's public key.
    function getPublicKey() external view returns (bytes memory);

    /// @notice Returns the amount of the keep's ETH bond in wei.
    /// @return The amount of the keep's ETH bond in wei.
    function checkBondAmount() external view returns (uint256);

    /// @notice Calculates a signature over provided digest by the keep. Note that
    /// signatures from the keep not explicitly requested by calling `sign`
    /// will be provable as fraud via `submitSignatureFraud`.
    /// @param _digest Digest to be signed.
    function sign(bytes32 _digest) external;

    /// @notice Distributes ETH reward evenly across keep signer beneficiaries.
    /// @dev Only the value passed to this function is distributed.
    function distributeETHReward() external payable;

    /// @notice Distributes ERC20 reward evenly across keep signer beneficiaries.
    /// @dev This works with any ERC20 token that implements a transferFrom
    /// function.
    /// This function only has authority over pre-approved
    /// token amount. We don't explicitly check for allowance, SafeMath
    /// subtraction overflow is enough protection.
    /// @param _tokenAddress Address of the ERC20 token to distribute.
    /// @param _value Amount of ERC20 token to distribute.
    function distributeERC20Reward(address _tokenAddress, uint256 _value)
        external;

    /// @notice Seizes the signers' ETH bonds. After seizing bonds keep is
    /// terminated so it will no longer respond to signing requests. Bonds can
    /// be seized only when there is no signing in progress or requested signing
    /// process has timed out. This function seizes all of signers' bonds.
    /// The application may decide to return part of bonds later after they are
    /// processed using returnPartialSignerBonds function.
    function seizeSignerBonds() external;

    /// @notice Returns partial signer's ETH bonds to the pool as an unbounded
    /// value. This function is called after bonds have been seized and processed
    /// by the privileged application after calling seizeSignerBonds function.
    /// It is entirely up to the application if a part of signers' bonds is
    /// returned. The application may decide for that but may also decide to
    /// seize bonds and do not return anything.
    function returnPartialSignerBonds() external payable;

    /// @notice Submits a fraud proof for a valid signature from this keep that was
    /// not first approved via a call to sign.
    /// @dev The function expects the signed digest to be calculated as a sha256
    /// hash of the preimage: `sha256(_preimage)`.
    /// @param _v Signature's header byte: `27 + recoveryID`.
    /// @param _r R part of ECDSA signature.
    /// @param _s S part of ECDSA signature.
    /// @param _signedDigest Digest for the provided signature. Result of hashing
    /// the preimage.
    /// @param _preimage Preimage of the hashed message.
    /// @return True if fraud, error otherwise.
    function submitSignatureFraud(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes32 _signedDigest,
        bytes calldata _preimage
    ) external returns (bool _isFraud);

    /// @notice Closes keep when no longer needed. Releases bonds to the keep
    /// members. Keep can be closed only when there is no signing in progress or
    /// requested signing process has timed out.
    /// @dev The function can be called only by the owner of the keep and only
    /// if the keep has not been already closed.
    function closeKeep() external;
}

pragma solidity 0.5.17;

/// @title  Vending Machine Authority.
/// @notice Contract to secure function calls to the Vending Machine.
/// @dev    Secured by setting the VendingMachine address and using the
///         onlyVendingMachine modifier on functions requiring restriction.
contract VendingMachineAuthority {
    address internal VendingMachine;

    constructor(address _vendingMachine) public {
        VendingMachine = _vendingMachine;
    }

    /// @notice Function modifier ensures modified function caller address is the vending machine.
    modifier onlyVendingMachine() {
        require(
            msg.sender == VendingMachine,
            "caller must be the vending machine"
        );
        _;
    }
}

pragma solidity 0.5.17;

import {SafeMath} from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import {TBTCDepositToken} from "./TBTCDepositToken.sol";
import {FeeRebateToken} from "./FeeRebateToken.sol";
import {TBTCToken} from "./TBTCToken.sol";
import {TBTCConstants} from "./TBTCConstants.sol";
import "../deposit/Deposit.sol";
import "./TBTCSystemAuthority.sol";

/// @title  Vending Machine
/// @notice The Vending Machine swaps TDTs (`TBTCDepositToken`)
///         to TBTC (`TBTCToken`) and vice versa.
/// @dev    The Vending Machine should have exclusive TBTC and FRT (`FeeRebateToken`) minting
///         privileges.
contract VendingMachine is TBTCSystemAuthority {
    using SafeMath for uint256;

    TBTCToken tbtcToken;
    TBTCDepositToken tbtcDepositToken;
    FeeRebateToken feeRebateToken;

    uint256 createdAt;

    constructor(address _systemAddress)
        public
        TBTCSystemAuthority(_systemAddress)
    {
        createdAt = block.timestamp;
    }

    /// @notice Set external contracts needed by the Vending Machine.
    /// @dev    Addresses are used to update the local contract instance.
    /// @param _tbtcToken        TBTCToken contract. More info in `TBTCToken`.
    /// @param _tbtcDepositToken TBTCDepositToken (TDT) contract. More info in `TBTCDepositToken`.
    /// @param _feeRebateToken   FeeRebateToken (FRT) contract. More info in `FeeRebateToken`.
    function setExternalAddresses(
        TBTCToken _tbtcToken,
        TBTCDepositToken _tbtcDepositToken,
        FeeRebateToken _feeRebateToken
    ) external onlyTbtcSystem {
        tbtcToken = _tbtcToken;
        tbtcDepositToken = _tbtcDepositToken;
        feeRebateToken = _feeRebateToken;
    }

    /// @notice Burns TBTC and transfers the tBTC Deposit Token to the caller
    ///         as long as it is qualified.
    /// @dev    We burn the lotSize of the Deposit in order to maintain
    ///         the TBTC supply peg in the Vending Machine. VendingMachine must be approved
    ///         by the caller to burn the required amount.
    /// @param _tdtId ID of tBTC Deposit Token to buy.
    function tbtcToTdt(uint256 _tdtId) external {
        require(
            tbtcDepositToken.exists(_tdtId),
            "tBTC Deposit Token does not exist"
        );
        require(isQualified(address(_tdtId)), "Deposit must be qualified");

        uint256 depositValue = Deposit(address(uint160(_tdtId))).lotSizeTbtc();
        require(
            tbtcToken.balanceOf(msg.sender) >= depositValue,
            "Not enough TBTC for TDT exchange"
        );
        tbtcToken.burnFrom(msg.sender, depositValue);

        // TODO do we need the owner check below? transferFrom can be approved for a user, which might be an interesting use case.
        require(
            tbtcDepositToken.ownerOf(_tdtId) == address(this),
            "Deposit is locked"
        );
        tbtcDepositToken.transferFrom(address(this), msg.sender, _tdtId);
    }

    /// @notice Transfer the tBTC Deposit Token and mint TBTC.
    /// @dev    Transfers TDT from caller to vending machine, and mints TBTC to caller.
    ///         Vending Machine must be approved to transfer TDT by the caller.
    /// @param _tdtId ID of tBTC Deposit Token to sell.
    function tdtToTbtc(uint256 _tdtId) public {
        require(
            tbtcDepositToken.exists(_tdtId),
            "tBTC Deposit Token does not exist"
        );
        require(isQualified(address(_tdtId)), "Deposit must be qualified");

        tbtcDepositToken.transferFrom(msg.sender, address(this), _tdtId);

        Deposit deposit = Deposit(address(uint160(_tdtId)));
        uint256 signerFee = deposit.signerFeeTbtc();
        uint256 depositValue = deposit.lotSizeTbtc();

        require(
            canMint(depositValue),
            "Can't mint more than the max supply cap"
        );

        // If the backing Deposit does not have a signer fee in escrow, mint it.
        if (tbtcToken.balanceOf(address(_tdtId)) < signerFee) {
            tbtcToken.mint(msg.sender, depositValue.sub(signerFee));
            tbtcToken.mint(address(_tdtId), signerFee);
        } else {
            tbtcToken.mint(msg.sender, depositValue);
        }

        // owner of the TDT during first TBTC mint receives the FRT
        if (!feeRebateToken.exists(_tdtId)) {
            feeRebateToken.mint(msg.sender, _tdtId);
        }
    }

    /// @notice Return whether an amount of TBTC can be minted according to the supply cap
    ///         schedule
    /// @dev This function is also used by TBTCSystem to decide whether to allow a new deposit.
    /// @return True if the amount can be minted without hitting the max supply, false otherwise.
    function canMint(uint256 amount) public view returns (bool) {
        return getMintedSupply().add(amount) < getMaxSupply();
    }

    /// @notice Determines whether a deposit is qualified for minting TBTC.
    /// @param _depositAddress The address of the deposit
    function isQualified(address payable _depositAddress)
        public
        view
        returns (bool)
    {
        return Deposit(_depositAddress).inActive();
    }

    /// @notice Return the minted TBTC supply in weitoshis (BTC * 10 ** 18).
    function getMintedSupply() public view returns (uint256) {
        return tbtcToken.totalSupply();
    }

    /// @notice Get the maximum TBTC token supply based on the age of the
    ///         contract deployment. The supply cap starts at 2 BTC for the two
    ///         days, 100 for the first week, 250 for the next, then 500, 750,
    ///         1000, 1500, 2000, 2500, and 3000... finally removing the minting
    ///         restriction after 9 weeks and returning 21M BTC as a sanity
    ///         check.
    /// @return The max supply in weitoshis (BTC * 10 ** 18).
    function getMaxSupply() public view returns (uint256) {
        uint256 age = block.timestamp - createdAt;

        if (age < 2 days) {
            return 2 * 10**18;
        }

        if (age < 7 days) {
            return 100 * 10**18;
        }

        if (age < 14 days) {
            return 250 * 10**18;
        }

        if (age < 21 days) {
            return 500 * 10**18;
        }

        if (age < 28 days) {
            return 750 * 10**18;
        }

        if (age < 35 days) {
            return 1000 * 10**18;
        }

        if (age < 42 days) {
            return 1500 * 10**18;
        }

        if (age < 49 days) {
            return 2000 * 10**18;
        }

        if (age < 56 days) {
            return 2500 * 10**18;
        }

        if (age < 63 days) {
            return 3000 * 10**18;
        }

        return 21e6 * 10**18;
    }

    // WRAPPERS

    /// @notice Qualifies a deposit and mints TBTC.
    /// @dev User must allow VendingManchine to transfer TDT.
    function unqualifiedDepositToTbtc(
        address payable _depositAddress,
        bytes4 _txVersion,
        bytes memory _txInputVector,
        bytes memory _txOutputVector,
        bytes4 _txLocktime,
        uint8 _fundingOutputIndex,
        bytes memory _merkleProof,
        uint256 _txIndexInBlock,
        bytes memory _bitcoinHeaders
    ) public {
        // not external to allow bytes memory parameters
        Deposit _d = Deposit(_depositAddress);
        _d.provideBTCFundingProof(
            _txVersion,
            _txInputVector,
            _txOutputVector,
            _txLocktime,
            _fundingOutputIndex,
            _merkleProof,
            _txIndexInBlock,
            _bitcoinHeaders
        );

        tdtToTbtc(uint256(_depositAddress));
    }

    /// @notice Redeems a Deposit by purchasing a TDT with TBTC for _finalRecipient,
    ///         and using the TDT to redeem corresponding Deposit as _finalRecipient.
    ///         This function will revert if the Deposit is not in ACTIVE state.
    /// @dev Vending Machine transfers TBTC allowance to Deposit.
    /// @param  _depositAddress     The address of the Deposit to redeem.
    /// @param  _outputValueBytes   The 8-byte Bitcoin transaction output size in Little Endian.
    /// @param  _redeemerOutputScript The redeemer's length-prefixed output script.
    function tbtcToBtc(
        address payable _depositAddress,
        bytes8 _outputValueBytes,
        bytes memory _redeemerOutputScript
    ) public {
        // not external to allow bytes memory parameters
        require(
            tbtcDepositToken.exists(uint256(_depositAddress)),
            "tBTC Deposit Token does not exist"
        );
        Deposit _d = Deposit(_depositAddress);

        tbtcToken.burnFrom(msg.sender, _d.lotSizeTbtc());
        tbtcDepositToken.approve(_depositAddress, uint256(_depositAddress));

        uint256 tbtcOwed = _d.getOwnerRedemptionTbtcRequirement(msg.sender);

        if (tbtcOwed != 0) {
            tbtcToken.transferFrom(msg.sender, address(this), tbtcOwed);
            tbtcToken.approve(_depositAddress, tbtcOwed);
        }

        _d.transferAndRequestRedemption(
            _outputValueBytes,
            _redeemerOutputScript,
            msg.sender
        );
    }
}

pragma solidity 0.5.17;

import {ERC20} from "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import {
    ERC20Detailed
} from "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import {VendingMachineAuthority} from "./VendingMachineAuthority.sol";
import {ITokenRecipient} from "../interfaces/ITokenRecipient.sol";

/// @title  TBTC Token.
/// @notice This is the TBTC ERC20 contract.
/// @dev    Tokens can only be minted by the `VendingMachine` contract.
contract TBTCToken is ERC20Detailed, ERC20, VendingMachineAuthority {
    /// @dev Constructor, calls ERC20Detailed constructor to set Token info
    ///      ERC20Detailed(TokenName, TokenSymbol, NumberOfDecimals)
    constructor(address _VendingMachine)
        public
        ERC20Detailed("tBTC", "TBTC", 18)
        VendingMachineAuthority(_VendingMachine)
    {
        // solium-disable-previous-line no-empty-blocks
    }

    /// @dev             Mints an amount of the token and assigns it to an account.
    ///                  Uses the internal _mint function.
    /// @param _account  The account that will receive the created tokens.
    /// @param _amount   The amount of tokens that will be created.
    function mint(address _account, uint256 _amount)
        external
        onlyVendingMachine
        returns (bool)
    {
        // NOTE: this is a public function with unchecked minting. Only the
        // vending machine is allowed to call it, and it is in charge of
        // ensuring minting is permitted.
        _mint(_account, _amount);
        return true;
    }

    /// @dev             Burns an amount of the token from the given account's balance.
    ///                  deducting from the sender's allowance for said account.
    ///                  Uses the internal _burn function.
    /// @param _account  The account whose tokens will be burnt.
    /// @param _amount   The amount of tokens that will be burnt.
    function burnFrom(address _account, uint256 _amount) external {
        _burnFrom(_account, _amount);
    }

    /// @dev Destroys `amount` tokens from `msg.sender`, reducing the
    /// total supply.
    /// @param _amount   The amount of tokens that will be burnt.
    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }

    /// @notice           Set allowance for other address and notify.
    ///                   Allows `_spender` to spend no more than `_value`
    ///                   tokens on your behalf and then ping the contract about
    ///                   it.
    /// @dev              The `_spender` should implement the `ITokenRecipient`
    ///                   interface to receive approval notifications.
    /// @param _spender   Address of contract authorized to spend.
    /// @param _value     The max amount they can spend.
    /// @param _extraData Extra information to send to the approved contract.
    /// @return true if the `_spender` was successfully approved and acted on
    ///         the approval, false (or revert) otherwise.
    function approveAndCall(
        ITokenRecipient _spender,
        uint256 _value,
        bytes memory _extraData
    ) public returns (bool) {
        // not external to allow bytes memory parameters
        if (approve(address(_spender), _value)) {
            _spender.receiveApproval(
                msg.sender,
                _value,
                address(this),
                _extraData
            );
            return true;
        }
        return false;
    }
}

pragma solidity 0.5.17;

/// @title  TBTC System Authority.
/// @notice Contract to secure function calls to the TBTC System contract.
/// @dev    The `TBTCSystem` contract address is passed as a constructor parameter.
contract TBTCSystemAuthority {
    address internal tbtcSystemAddress;

    /// @notice Set the address of the System contract on contract initialization.
    constructor(address _tbtcSystemAddress) public {
        tbtcSystemAddress = _tbtcSystemAddress;
    }

    /// @notice Function modifier ensures modified function is only called by TBTCSystem.
    modifier onlyTbtcSystem() {
        require(
            msg.sender == tbtcSystemAddress,
            "Caller must be tbtcSystem contract"
        );
        _;
    }
}

pragma solidity 0.5.17;

import {
    ERC721Metadata
} from "openzeppelin-solidity/contracts/token/ERC721/ERC721Metadata.sol";
import {DepositFactoryAuthority} from "./DepositFactoryAuthority.sol";
import {ITokenRecipient} from "../interfaces/ITokenRecipient.sol";

/// @title tBTC Deposit Token for tracking deposit ownership
/// @notice The tBTC Deposit Token, commonly referenced as the TDT, is an
///         ERC721 non-fungible token whose ownership reflects the ownership
///         of its corresponding deposit. Each deposit has one TDT, and vice
///         versa. Owning a TDT is equivalent to owning its corresponding
///         deposit. TDTs can be transferred freely. tBTC's VendingMachine
///         contract takes ownership of TDTs and in exchange returns fungible
///         TBTC tokens whose value is backed 1-to-1 by the corresponding
///         deposit's BTC.
/// @dev Currently, TDTs are minted using the uint256 casting of the
///      corresponding deposit contract's address. That is, the TDT's id is
///      convertible to the deposit's address and vice versa. TDTs are minted
///      automatically by the factory during each deposit's initialization. See
///      DepositFactory.createNewDeposit() for more info on how the TDT is minted.
contract TBTCDepositToken is ERC721Metadata, DepositFactoryAuthority {
    constructor(address _depositFactoryAddress)
        public
        ERC721Metadata("tBTC Deposit Token", "TDT")
    {
        initialize(_depositFactoryAddress);
    }

    /// @dev Mints a new token.
    /// Reverts if the given token ID already exists.
    /// @param _to The address that will own the minted token
    /// @param _tokenId uint256 ID of the token to be minted
    function mint(address _to, uint256 _tokenId) external onlyFactory {
        _mint(_to, _tokenId);
    }

    /// @dev Returns whether the specified token exists.
    /// @param _tokenId uint256 ID of the token to query the existence of.
    /// @return bool whether the token exists.
    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    /// @notice           Allow another address to spend on the caller's behalf.
    ///                   Set allowance for other address and notify.
    ///                   Allows `_spender` to transfer the specified TDT
    ///                   on your behalf and then ping the contract about it.
    /// @dev              The `_spender` should implement the `ITokenRecipient`
    ///                   interface below to receive approval notifications.
    /// @param _spender   `ITokenRecipient`-conforming contract authorized to
    ///        operate on the approved token.
    /// @param _tdtId     The TDT they can spend.
    /// @param _extraData Extra information to send to the approved contract.
    function approveAndCall(
        ITokenRecipient _spender,
        uint256 _tdtId,
        bytes memory _extraData
    ) public returns (bool) {
        // not external to allow bytes memory parameters
        approve(address(_spender), _tdtId);
        _spender.receiveApproval(msg.sender, _tdtId, address(this), _extraData);
        return true;
    }
}

pragma solidity 0.5.17;

library TBTCConstants {
    // This is intended to make it easy to update system params
    // During testing swap this out with another constats contract

    // System Parameters
    uint256 public constant BENEFICIARY_FEE_DIVISOR = 1000; // 1/1000 = 10 bps = 0.1% = 0.001
    uint256 public constant SATOSHI_MULTIPLIER = 10**10; // multiplier to convert satoshi to TBTC token units
    uint256 public constant DEPOSIT_TERM_LENGTH = 180 * 24 * 60 * 60; // 180 days in seconds
    uint256 public constant TX_PROOF_DIFFICULTY_FACTOR = 6; // confirmations on the Bitcoin chain

    // Redemption Flow
    uint256 public constant REDEMPTION_SIGNATURE_TIMEOUT = 2 * 60 * 60; // seconds
    uint256 public constant INCREASE_FEE_TIMER = 4 * 60 * 60; // seconds
    uint256 public constant REDEMPTION_PROOF_TIMEOUT = 6 * 60 * 60; // seconds
    uint256 public constant MINIMUM_REDEMPTION_FEE = 2000; // satoshi
    uint256 public constant MINIMUM_UTXO_VALUE = 2000; // satoshi

    // Funding Flow
    uint256 public constant FUNDING_PROOF_TIMEOUT = 3 * 60 * 60; // seconds
    uint256 public constant FORMATION_TIMEOUT = 3 * 60 * 60; // seconds

    // Liquidation Flow
    uint256 public constant COURTESY_CALL_DURATION = 6 * 60 * 60; // seconds
    uint256 public constant AUCTION_DURATION = 24 * 60 * 60; // seconds

    // Getters for easy access
    function getBeneficiaryRewardDivisor() external pure returns (uint256) {
        return BENEFICIARY_FEE_DIVISOR;
    }

    function getSatoshiMultiplier() external pure returns (uint256) {
        return SATOSHI_MULTIPLIER;
    }

    function getDepositTerm() external pure returns (uint256) {
        return DEPOSIT_TERM_LENGTH;
    }

    function getTxProofDifficultyFactor() external pure returns (uint256) {
        return TX_PROOF_DIFFICULTY_FACTOR;
    }

    function getSignatureTimeout() external pure returns (uint256) {
        return REDEMPTION_SIGNATURE_TIMEOUT;
    }

    function getIncreaseFeeTimer() external pure returns (uint256) {
        return INCREASE_FEE_TIMER;
    }

    function getRedemptionProofTimeout() external pure returns (uint256) {
        return REDEMPTION_PROOF_TIMEOUT;
    }

    function getMinimumRedemptionFee() external pure returns (uint256) {
        return MINIMUM_REDEMPTION_FEE;
    }

    function getMinimumUtxoValue() external pure returns (uint256) {
        return MINIMUM_UTXO_VALUE;
    }

    function getFundingTimeout() external pure returns (uint256) {
        return FUNDING_PROOF_TIMEOUT;
    }

    function getSigningGroupFormationTimeout() external pure returns (uint256) {
        return FORMATION_TIMEOUT;
    }

    function getCourtesyCallTimeout() external pure returns (uint256) {
        return COURTESY_CALL_DURATION;
    }

    function getAuctionDuration() external pure returns (uint256) {
        return AUCTION_DURATION;
    }
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Metadata.sol";
import "./VendingMachineAuthority.sol";

/// @title  Fee Rebate Token
/// @notice The Fee Rebate Token (FRT) is a non fungible token (ERC721)
///         the ID of which corresponds to a given deposit address.
///         If the corresponding deposit is still active, ownership of this token
///         could result in reimbursement of the signer fee paid to open the deposit.
/// @dev    This token is minted automatically when a TDT (`TBTCDepositToken`)
///         is exchanged for TBTC (`TBTCToken`) via the Vending Machine (`VendingMachine`).
///         When the Deposit is redeemed, the TDT holder will be reimbursed
///         the signer fee if the redeemer is not the TDT holder and Deposit is not
///         at-term or in COURTESY_CALL.
contract FeeRebateToken is ERC721Metadata, VendingMachineAuthority {
    constructor(address _vendingMachine)
        public
        ERC721Metadata("tBTC Fee Rebate Token", "FRT")
        VendingMachineAuthority(_vendingMachine)
    {
        // solium-disable-previous-line no-empty-blocks
    }

    /// @dev Mints a new token.
    /// Reverts if the given token ID already exists.
    /// @param _to The address that will own the minted token.
    /// @param _tokenId uint256 ID of the token to be minted.
    function mint(address _to, uint256 _tokenId) external onlyVendingMachine {
        _mint(_to, _tokenId);
    }

    /// @dev Returns whether the specified token exists.
    /// @param _tokenId uint256 ID of the token to query the existence of.
    /// @return bool whether the token exists.
    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }
}

pragma solidity 0.5.17;

/// @title  Deposit Factory Authority
/// @notice Contract to secure function calls to the Deposit Factory.
/// @dev    Secured by setting the depositFactory address and using the onlyFactory
///         modifier on functions requiring restriction.
contract DepositFactoryAuthority {
    bool internal _initialized = false;
    address internal _depositFactory;

    /// @notice Set the address of the System contract on contract
    ///         initialization.
    /// @dev Since this function is not access-controlled, it should be called
    ///      transactionally with contract instantiation. In cases where a
    ///      regular contract directly inherits from DepositFactoryAuthority,
    ///      that should happen in the constructor. In cases where the inheritor
    ///      is binstead used via a clone factory, the same function that
    ///      creates a new clone should also trigger initialization.
    function initialize(address _factory) public {
        require(_factory != address(0), "Factory cannot be the zero address.");
        require(!_initialized, "Factory can only be initialized once.");

        _depositFactory = _factory;
        _initialized = true;
    }

    /// @notice Function modifier ensures modified function is only called by set deposit factory.
    modifier onlyFactory() {
        require(_initialized, "Factory initialization must have been called.");
        require(
            msg.sender == _depositFactory,
            "Caller must be depositFactory contract"
        );
        _;
    }
}

pragma solidity 0.5.17;

/// @title Interface of recipient contract for `approveAndCall` pattern.
///        Implementors will be able to be used in an `approveAndCall`
///        interaction with a supporting contract, such that a token approval
///        can call the contract acting on that approval in a single
///        transaction.
///
///        See the `FundingScript` and `RedemptionScript` contracts as examples.
interface ITokenRecipient {
    /// Typically called from a token contract's `approveAndCall` method, this
    /// method will receive the original owner of the token (`_from`), the
    /// transferred `_value` (in the case of an ERC721, the token id), the token
    /// address (`_token`), and a blob of `_extraData` that is informally
    /// specified by the implementor of this method as a way to communicate
    /// additional parameters.
    ///
    /// Token calls to `receiveApproval` should revert if `receiveApproval`
    /// reverts, and reverts should remove the approval.
    ///
    /// @param _from The original owner of the token approved for transfer.
    /// @param _value For an ERC20, the amount approved for transfer; for an
    ///        ERC721, the id of the token approved for transfer.
    /// @param _token The address of the contract for the token whose transfer
    ///        was approved.
    /// @param _extraData An additional data blob forwarded unmodified through
    ///        `approveAndCall`, used to allow the token owner to pass
    ///         additional parameters and data to this method. The structure of
    ///         the extra data is informally specified by the implementor of
    ///         this interface.
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes calldata _extraData
    ) external;
}

pragma solidity 0.5.17;

/**
 * @title Keep interface
 */

interface ITBTCSystem {
    // expected behavior:
    // return the price of 1 sat in wei
    // these are the native units of the deposit contract
    function fetchBitcoinPrice() external view returns (uint256);

    // passthrough requests for the oracle
    function fetchRelayCurrentDifficulty() external view returns (uint256);

    function fetchRelayPreviousDifficulty() external view returns (uint256);

    function getNewDepositFeeEstimate() external view returns (uint256);

    function getAllowNewDeposits() external view returns (bool);

    function isAllowedLotSize(uint64 _requestedLotSizeSatoshis)
        external
        view
        returns (bool);

    function requestNewKeep(
        uint64 _requestedLotSizeSatoshis,
        uint256 _maxSecuredLifetime
    ) external payable returns (address);

    function getSignerFeeDivisor() external view returns (uint16);

    function getInitialCollateralizedPercent() external view returns (uint16);

    function getUndercollateralizedThresholdPercent()
        external
        view
        returns (uint16);

    function getSeverelyUndercollateralizedThresholdPercent()
        external
        view
        returns (uint16);
}

pragma solidity 0.5.17;

import {DepositLog} from "../DepositLog.sol";
import {DepositUtils} from "./DepositUtils.sol";

library OutsourceDepositLogging {
    /// @notice               Fires a Created event.
    /// @dev                  `DepositLog.logCreated` fires a Created event with
    ///                       _keepAddress, msg.sender and block.timestamp.
    ///                       msg.sender will be the calling Deposit's address.
    /// @param  _keepAddress  The address of the associated keep.
    function logCreated(DepositUtils.Deposit storage _d, address _keepAddress)
        external
    {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logCreated(_keepAddress);
    }

    /// @notice                 Fires a RedemptionRequested event.
    /// @dev                    This is the only event without an explicit timestamp.
    /// @param  _redeemer       The ethereum address of the redeemer.
    /// @param  _digest         The calculated sighash digest.
    /// @param  _utxoValue       The size of the utxo in sat.
    /// @param  _redeemerOutputScript The redeemer's length-prefixed output script.
    /// @param  _requestedFee   The redeemer or bump-system specified fee.
    /// @param  _outpoint       The 36 byte outpoint.
    /// @return                 True if successful, else revert.
    function logRedemptionRequested(
        DepositUtils.Deposit storage _d,
        address _redeemer,
        bytes32 _digest,
        uint256 _utxoValue,
        bytes memory _redeemerOutputScript,
        uint256 _requestedFee,
        bytes memory _outpoint
    ) public {
        // not external to allow bytes memory parameters
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logRedemptionRequested(
            _redeemer,
            _digest,
            _utxoValue,
            _redeemerOutputScript,
            _requestedFee,
            _outpoint
        );
    }

    /// @notice         Fires a GotRedemptionSignature event.
    /// @dev            We append the sender, which is the deposit contract that called.
    /// @param  _digest Signed digest.
    /// @param  _r      Signature r value.
    /// @param  _s      Signature s value.
    /// @return         True if successful, else revert.
    function logGotRedemptionSignature(
        DepositUtils.Deposit storage _d,
        bytes32 _digest,
        bytes32 _r,
        bytes32 _s
    ) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logGotRedemptionSignature(_digest, _r, _s);
    }

    /// @notice     Fires a RegisteredPubkey event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logRegisteredPubkey(
        DepositUtils.Deposit storage _d,
        bytes32 _signingGroupPubkeyX,
        bytes32 _signingGroupPubkeyY
    ) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logRegisteredPubkey(_signingGroupPubkeyX, _signingGroupPubkeyY);
    }

    /// @notice     Fires a SetupFailed event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logSetupFailed(DepositUtils.Deposit storage _d) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logSetupFailed();
    }

    /// @notice     Fires a FunderAbortRequested event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logFunderRequestedAbort(
        DepositUtils.Deposit storage _d,
        bytes memory _abortOutputScript
    ) public {
        // not external to allow bytes memory parameters
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logFunderRequestedAbort(_abortOutputScript);
    }

    /// @notice     Fires a FraudDuringSetup event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logFraudDuringSetup(DepositUtils.Deposit storage _d) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logFraudDuringSetup();
    }

    /// @notice     Fires a Funded event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logFunded(DepositUtils.Deposit storage _d, bytes32 _txid)
        external
    {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logFunded(_txid);
    }

    /// @notice     Fires a CourtesyCalled event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logCourtesyCalled(DepositUtils.Deposit storage _d) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logCourtesyCalled();
    }

    /// @notice             Fires a StartedLiquidation event.
    /// @dev                We append the sender, which is the deposit contract that called.
    /// @param _wasFraud    True if liquidating for fraud.
    function logStartedLiquidation(
        DepositUtils.Deposit storage _d,
        bool _wasFraud
    ) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logStartedLiquidation(_wasFraud);
    }

    /// @notice     Fires a Redeemed event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logRedeemed(DepositUtils.Deposit storage _d, bytes32 _txid)
        external
    {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logRedeemed(_txid);
    }

    /// @notice     Fires a Liquidated event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logLiquidated(DepositUtils.Deposit storage _d) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logLiquidated();
    }

    /// @notice     Fires a ExitedCourtesyCall event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logExitedCourtesyCall(DepositUtils.Deposit storage _d) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logExitedCourtesyCall();
    }
}

pragma solidity 0.5.17;

import {ValidateSPV} from "@summa-tx/bitcoin-spv-sol/contracts/ValidateSPV.sol";
import {BTCUtils} from "@summa-tx/bitcoin-spv-sol/contracts/BTCUtils.sol";
import {BytesLib} from "@summa-tx/bitcoin-spv-sol/contracts/BytesLib.sol";
import {
    IBondedECDSAKeep
} from "@keep-network/keep-ecdsa/contracts/api/IBondedECDSAKeep.sol";
import {
    IERC721
} from "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import {SafeMath} from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import {DepositStates} from "./DepositStates.sol";
import {TBTCConstants} from "../system/TBTCConstants.sol";
import {ITBTCSystem} from "../interfaces/ITBTCSystem.sol";
import {TBTCToken} from "../system/TBTCToken.sol";
import {FeeRebateToken} from "../system/FeeRebateToken.sol";

library DepositUtils {
    using SafeMath for uint256;
    using SafeMath for uint64;
    using BytesLib for bytes;
    using BTCUtils for bytes;
    using BTCUtils for uint256;
    using ValidateSPV for bytes;
    using ValidateSPV for bytes32;
    using DepositStates for DepositUtils.Deposit;

    struct Deposit {
        // SET DURING CONSTRUCTION
        ITBTCSystem tbtcSystem;
        TBTCToken tbtcToken;
        IERC721 tbtcDepositToken;
        FeeRebateToken feeRebateToken;
        address vendingMachineAddress;
        uint64 lotSizeSatoshis;
        uint8 currentState;
        uint16 signerFeeDivisor;
        uint16 initialCollateralizedPercent;
        uint16 undercollateralizedThresholdPercent;
        uint16 severelyUndercollateralizedThresholdPercent;
        uint256 keepSetupFee;
        // SET ON FRAUD
        uint256 liquidationInitiated; // Timestamp of when liquidation starts
        uint256 courtesyCallInitiated; // When the courtesy call is issued
        address payable liquidationInitiator;
        // written when we request a keep
        address keepAddress; // The address of our keep contract
        uint256 signingGroupRequestedAt; // timestamp of signing group request
        // written when we get a keep result
        uint256 fundingProofTimerStart; // start of the funding proof period. reused for funding fraud proof period
        bytes32 signingGroupPubkeyX; // The X coordinate of the signing group's pubkey
        bytes32 signingGroupPubkeyY; // The Y coordinate of the signing group's pubkey
        // INITIALLY WRITTEN BY REDEMPTION FLOW
        address payable redeemerAddress; // The redeemer's address, used as fallback for fraud in redemption
        bytes redeemerOutputScript; // The redeemer output script
        uint256 initialRedemptionFee; // the initial fee as requested
        uint256 latestRedemptionFee; // the fee currently required by a redemption transaction
        uint256 withdrawalRequestTime; // the most recent withdrawal request timestamp
        bytes32 lastRequestedDigest; // the digest most recently requested for signing
        // written when we get funded
        bytes8 utxoValueBytes; // LE uint. the size of the deposit UTXO in satoshis
        uint256 fundedAt; // timestamp when funding proof was received
        bytes utxoOutpoint; // the 36-byte outpoint of the custodied UTXO
        /// @dev Map of ETH balances an address can withdraw after contract reaches ends-state.
        mapping(address => uint256) withdrawableAmounts;
        /// @dev Map of timestamps representing when transaction digests were approved for signing
        mapping(bytes32 => uint256) approvedDigests;
    }

    /// @notice Closes keep associated with the deposit.
    /// @dev Should be called when the keep is no longer needed and the signing
    /// group can disband.
    function closeKeep(DepositUtils.Deposit storage _d) internal {
        IBondedECDSAKeep _keep = IBondedECDSAKeep(_d.keepAddress);
        _keep.closeKeep();
    }

    /// @notice         Gets the current block difficulty.
    /// @dev            Calls the light relay and gets the current block difficulty.
    /// @return         The difficulty.
    function currentBlockDifficulty(Deposit storage _d)
        public
        view
        returns (uint256)
    {
        return _d.tbtcSystem.fetchRelayCurrentDifficulty();
    }

    /// @notice         Gets the previous block difficulty.
    /// @dev            Calls the light relay and gets the previous block difficulty.
    /// @return         The difficulty.
    function previousBlockDifficulty(Deposit storage _d)
        public
        view
        returns (uint256)
    {
        return _d.tbtcSystem.fetchRelayPreviousDifficulty();
    }

    /// @notice                     Evaluates the header difficulties in a proof.
    /// @dev                        Uses the light oracle to source recent difficulty.
    /// @param  _bitcoinHeaders     The header chain to evaluate.
    /// @return                     True if acceptable, otherwise revert.
    function evaluateProofDifficulty(
        Deposit storage _d,
        bytes memory _bitcoinHeaders
    ) public view {
        uint256 _reqDiff;
        uint256 _current = currentBlockDifficulty(_d);
        uint256 _previous = previousBlockDifficulty(_d);
        uint256 _firstHeaderDiff =
            _bitcoinHeaders.extractTarget().calculateDifficulty();

        if (_firstHeaderDiff == _current) {
            _reqDiff = _current;
        } else if (_firstHeaderDiff == _previous) {
            _reqDiff = _previous;
        } else {
            revert("not at current or previous difficulty");
        }

        uint256 _observedDiff = _bitcoinHeaders.validateHeaderChain();

        require(
            _observedDiff != ValidateSPV.getErrBadLength(),
            "Invalid length of the headers chain"
        );
        require(
            _observedDiff != ValidateSPV.getErrInvalidChain(),
            "Invalid headers chain"
        );
        require(
            _observedDiff != ValidateSPV.getErrLowWork(),
            "Insufficient work in a header"
        );

        require(
            _observedDiff >=
                _reqDiff.mul(TBTCConstants.getTxProofDifficultyFactor()),
            "Insufficient accumulated difficulty in header chain"
        );
    }

    /// @notice                 Syntactically check an SPV proof for a bitcoin transaction with its hash (ID).
    /// @dev                    Stateless SPV Proof verification documented elsewhere (see https://github.com/summa-tx/bitcoin-spv).
    /// @param _d               Deposit storage pointer.
    /// @param _txId            The bitcoin txid of the tx that is purportedly included in the header chain.
    /// @param _merkleProof     The merkle proof of inclusion of the tx in the bitcoin block.
    /// @param _txIndexInBlock  The index of the tx in the Bitcoin block (0-indexed).
    /// @param _bitcoinHeaders  An array of tightly-packed bitcoin headers.
    function checkProofFromTxId(
        Deposit storage _d,
        bytes32 _txId,
        bytes memory _merkleProof,
        uint256 _txIndexInBlock,
        bytes memory _bitcoinHeaders
    ) public view {
        require(
            _txId.prove(
                _bitcoinHeaders.extractMerkleRootLE().toBytes32(),
                _merkleProof,
                _txIndexInBlock
            ),
            "Tx merkle proof is not valid for provided header and txId"
        );
        evaluateProofDifficulty(_d, _bitcoinHeaders);
    }

    /// @notice                     Find and validate funding output in transaction output vector using the index.
    /// @dev                        Gets `_fundingOutputIndex` output from the output vector and validates if it is
    ///                             a p2wpkh output with public key hash matching this deposit's public key hash.
    /// @param _d                   Deposit storage pointer.
    /// @param _txOutputVector      All transaction outputs prepended by the number of outputs encoded as a VarInt, max 0xFC outputs.
    /// @param _fundingOutputIndex  Index of funding output in _txOutputVector.
    /// @return                     Funding value.
    function findAndParseFundingOutput(
        DepositUtils.Deposit storage _d,
        bytes memory _txOutputVector,
        uint8 _fundingOutputIndex
    ) public view returns (bytes8) {
        bytes8 _valueBytes;
        bytes memory _output;

        // Find the output paying the signer PKH
        _output = _txOutputVector.extractOutputAtIndex(_fundingOutputIndex);

        require(
            keccak256(_output.extractHash()) ==
                keccak256(abi.encodePacked(signerPKH(_d))),
            "Could not identify output funding the required public key hash"
        );
        require(
            _output.length == 31 &&
                _output.keccak256Slice(8, 23) ==
                keccak256(abi.encodePacked(hex"160014", signerPKH(_d))),
            "Funding transaction output type unsupported: only p2wpkh outputs are supported"
        );

        _valueBytes = bytes8(_output.slice(0, 8).toBytes32());
        return _valueBytes;
    }

    /// @notice                     Validates the funding tx and parses information from it.
    /// @dev                        Takes a pre-parsed transaction and calculates values needed to verify funding.
    /// @param  _d                  Deposit storage pointer.
    /// @param _txVersion           Transaction version number (4-byte LE).
    /// @param _txInputVector       All transaction inputs prepended by the number of inputs encoded as a VarInt, max 0xFC(252) inputs.
    /// @param _txOutputVector      All transaction outputs prepended by the number of outputs encoded as a VarInt, max 0xFC(252) outputs.
    /// @param _txLocktime          Final 4 bytes of the transaction.
    /// @param _fundingOutputIndex  Index of funding output in _txOutputVector (0-indexed).
    /// @param _merkleProof         The merkle proof of transaction inclusion in a block.
    /// @param _txIndexInBlock      Transaction index in the block (0-indexed).
    /// @param _bitcoinHeaders      Single bytestring of 80-byte bitcoin headers, lowest height first.
    /// @return                     The 8-byte LE UTXO size in satoshi, the 36byte outpoint.
    function validateAndParseFundingSPVProof(
        DepositUtils.Deposit storage _d,
        bytes4 _txVersion,
        bytes memory _txInputVector,
        bytes memory _txOutputVector,
        bytes4 _txLocktime,
        uint8 _fundingOutputIndex,
        bytes memory _merkleProof,
        uint256 _txIndexInBlock,
        bytes memory _bitcoinHeaders
    ) public view returns (bytes8 _valueBytes, bytes memory _utxoOutpoint) {
        // not external to allow bytes memory parameters
        require(_txInputVector.validateVin(), "invalid input vector provided");
        require(
            _txOutputVector.validateVout(),
            "invalid output vector provided"
        );

        bytes32 txID =
            abi
                .encodePacked(
                _txVersion,
                _txInputVector,
                _txOutputVector,
                _txLocktime
            )
                .hash256();

        _valueBytes = findAndParseFundingOutput(
            _d,
            _txOutputVector,
            _fundingOutputIndex
        );

        require(
            bytes8LEToUint(_valueBytes) >= _d.lotSizeSatoshis,
            "Deposit too small"
        );

        checkProofFromTxId(
            _d,
            txID,
            _merkleProof,
            _txIndexInBlock,
            _bitcoinHeaders
        );

        // The utxoOutpoint is the LE txID plus the index of the output as a 4-byte LE int
        // _fundingOutputIndex is a uint8, so we know it is only 1 byte
        // Therefore, pad with 3 more bytes
        _utxoOutpoint = abi.encodePacked(
            txID,
            _fundingOutputIndex,
            hex"000000"
        );
    }

    /// @notice Retreive the remaining term of the deposit
    /// @dev    The return value is not guaranteed since block.timestmap can be lightly manipulated by miners.
    /// @return The remaining term of the deposit in seconds. 0 if already at term
    function remainingTerm(DepositUtils.Deposit storage _d)
        public
        view
        returns (uint256)
    {
        uint256 endOfTerm = _d.fundedAt.add(TBTCConstants.getDepositTerm());
        if (block.timestamp < endOfTerm) {
            return endOfTerm.sub(block.timestamp);
        }
        return 0;
    }

    /// @notice     Calculates the amount of value at auction right now.
    /// @dev        We calculate the % of the auction that has elapsed, then scale the value up.
    /// @param _d   Deposit storage pointer.
    /// @return     The value in wei to distribute in the auction at the current time.
    function auctionValue(Deposit storage _d) external view returns (uint256) {
        uint256 _elapsed = block.timestamp.sub(_d.liquidationInitiated);
        uint256 _available = address(this).balance;
        if (_elapsed > TBTCConstants.getAuctionDuration()) {
            return _available;
        }

        // This should make a smooth flow from base% to 100%
        uint256 _basePercentage = getAuctionBasePercentage(_d);
        uint256 _elapsedPercentage =
            uint256(100).sub(_basePercentage).mul(_elapsed).div(
                TBTCConstants.getAuctionDuration()
            );
        uint256 _percentage = _basePercentage.add(_elapsedPercentage);

        return _available.mul(_percentage).div(100);
    }

    /// @notice         Gets the lot size in erc20 decimal places (max 18)
    /// @return         uint256 lot size in 10**18 decimals.
    function lotSizeTbtc(Deposit storage _d) public view returns (uint256) {
        return _d.lotSizeSatoshis.mul(TBTCConstants.getSatoshiMultiplier());
    }

    /// @notice         Determines the fees due to the signers for work performed.
    /// @dev            Signers are paid based on the TBTC issued.
    /// @return         Accumulated fees in 10**18 decimals.
    function signerFeeTbtc(Deposit storage _d) public view returns (uint256) {
        return lotSizeTbtc(_d).div(_d.signerFeeDivisor);
    }

    /// @notice             Determines the prefix to the compressed public key.
    /// @dev                The prefix encodes the parity of the Y coordinate.
    /// @param  _pubkeyY    The Y coordinate of the public key.
    /// @return             The 1-byte prefix for the compressed key.
    function determineCompressionPrefix(bytes32 _pubkeyY)
        public
        pure
        returns (bytes memory)
    {
        if (uint256(_pubkeyY) & 1 == 1) {
            return hex"03"; // Odd Y
        } else {
            return hex"02"; // Even Y
        }
    }

    /// @notice             Compresses a public key.
    /// @dev                Converts the 64-byte key to a 33-byte key, bitcoin-style.
    /// @param  _pubkeyX    The X coordinate of the public key.
    /// @param  _pubkeyY    The Y coordinate of the public key.
    /// @return             The 33-byte compressed pubkey.
    function compressPubkey(bytes32 _pubkeyX, bytes32 _pubkeyY)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(determineCompressionPrefix(_pubkeyY), _pubkeyX);
    }

    /// @notice    Returns the packed public key (64 bytes) for the signing group.
    /// @dev       We store it as 2 bytes32, (2 slots) then repack it on demand.
    /// @return    64 byte public key.
    function signerPubkey(Deposit storage _d)
        external
        view
        returns (bytes memory)
    {
        return abi.encodePacked(_d.signingGroupPubkeyX, _d.signingGroupPubkeyY);
    }

    /// @notice    Returns the Bitcoin pubkeyhash (hash160) for the signing group.
    /// @dev       This is used in bitcoin output scripts for the signers.
    /// @return    20-bytes public key hash.
    function signerPKH(Deposit storage _d) public view returns (bytes20) {
        bytes memory _pubkey =
            compressPubkey(_d.signingGroupPubkeyX, _d.signingGroupPubkeyY);
        bytes memory _digest = _pubkey.hash160();
        return bytes20(_digest.toAddress(0)); // dirty solidity hack
    }

    /// @notice    Returns the size of the deposit UTXO in satoshi.
    /// @dev       We store the deposit as bytes8 to make signature checking easier.
    /// @return    UTXO value in satoshi.
    function utxoValue(Deposit storage _d) external view returns (uint256) {
        return bytes8LEToUint(_d.utxoValueBytes);
    }

    /// @notice     Gets the current price of Bitcoin in Ether.
    /// @dev        Polls the price feed via the system contract.
    /// @return     The current price of 1 sat in wei.
    function fetchBitcoinPrice(Deposit storage _d)
        external
        view
        returns (uint256)
    {
        return _d.tbtcSystem.fetchBitcoinPrice();
    }

    /// @notice     Fetches the Keep's bond amount in wei.
    /// @dev        Calls the keep contract to do so.
    /// @return     The amount of bonded ETH in wei.
    function fetchBondAmount(Deposit storage _d)
        external
        view
        returns (uint256)
    {
        IBondedECDSAKeep _keep = IBondedECDSAKeep(_d.keepAddress);
        return _keep.checkBondAmount();
    }

    /// @notice         Convert a LE bytes8 to a uint256.
    /// @dev            Do this by converting to bytes, then reversing endianness, then converting to int.
    /// @return         The uint256 represented in LE by the bytes8.
    function bytes8LEToUint(bytes8 _b) public pure returns (uint256) {
        return abi.encodePacked(_b).reverseEndianness().bytesToUint();
    }

    /// @notice         Gets timestamp of digest approval for signing.
    /// @dev            Identifies entry in the recorded approvals by keep ID and digest pair.
    /// @param _digest  Digest to check approval for.
    /// @return         Timestamp from the moment of recording the digest for signing.
    ///                 Returns 0 if the digest was not approved for signing.
    function wasDigestApprovedForSigning(Deposit storage _d, bytes32 _digest)
        external
        view
        returns (uint256)
    {
        return _d.approvedDigests[_digest];
    }

    /// @notice         Looks up the Fee Rebate Token holder.
    /// @return         The current token holder if the Token exists.
    ///                 address(0) if the token does not exist.
    function feeRebateTokenHolder(Deposit storage _d)
        public
        view
        returns (address payable)
    {
        address tokenHolder = address(0);
        if (_d.feeRebateToken.exists(uint256(address(this)))) {
            tokenHolder = address(
                uint160(_d.feeRebateToken.ownerOf(uint256(address(this))))
            );
        }
        return address(uint160(tokenHolder));
    }

    /// @notice         Looks up the deposit beneficiary by calling the tBTC system.
    /// @dev            We cast the address to a uint256 to match the 721 standard.
    /// @return         The current deposit beneficiary.
    function depositOwner(Deposit storage _d)
        public
        view
        returns (address payable)
    {
        return
            address(
                uint160(_d.tbtcDepositToken.ownerOf(uint256(address(this))))
            );
    }

    /// @notice     Deletes state after termination of redemption process.
    /// @dev        We keep around the redeemer address so we can pay them out.
    function redemptionTeardown(Deposit storage _d) public {
        _d.redeemerOutputScript = "";
        _d.initialRedemptionFee = 0;
        _d.withdrawalRequestTime = 0;
        _d.lastRequestedDigest = bytes32(0);
    }

    /// @notice     Get the starting percentage of the bond at auction.
    /// @dev        This will return the same value regardless of collateral price.
    /// @return     The percentage of the InitialCollateralizationPercent that will result
    ///             in a 100% bond value base auction given perfect collateralization.
    function getAuctionBasePercentage(Deposit storage _d)
        internal
        view
        returns (uint256)
    {
        return uint256(10000).div(_d.initialCollateralizedPercent);
    }

    /// @notice     Seize the signer bond from the keep contract.
    /// @dev        we check our balance before and after.
    /// @return     The amount seized in wei.
    function seizeSignerBonds(Deposit storage _d) internal returns (uint256) {
        uint256 _preCallBalance = address(this).balance;

        IBondedECDSAKeep _keep = IBondedECDSAKeep(_d.keepAddress);
        _keep.seizeSignerBonds();

        uint256 _postCallBalance = address(this).balance;
        require(
            _postCallBalance > _preCallBalance,
            "No funds received, unexpected"
        );
        return _postCallBalance.sub(_preCallBalance);
    }

    /// @notice     Adds a given amount to the withdraw allowance for the address.
    /// @dev        Withdrawals can only happen when a contract is in an end-state.
    function enableWithdrawal(
        DepositUtils.Deposit storage _d,
        address _withdrawer,
        uint256 _amount
    ) internal {
        _d.withdrawableAmounts[_withdrawer] = _d.withdrawableAmounts[
            _withdrawer
        ]
            .add(_amount);
    }

    /// @notice     Withdraw caller's allowance.
    /// @dev        Withdrawals can only happen when a contract is in an end-state.
    function withdrawFunds(DepositUtils.Deposit storage _d) internal {
        uint256 available = _d.withdrawableAmounts[msg.sender];

        require(_d.inEndState(), "Contract not yet terminated");
        require(available > 0, "Nothing to withdraw");
        require(
            address(this).balance >= available,
            "Insufficient contract balance"
        );

        // zero-out to prevent reentrancy
        _d.withdrawableAmounts[msg.sender] = 0;

        /* solium-disable-next-line security/no-call-value */
        (bool ok, ) = msg.sender.call.value(available)("");
        require(ok, "Failed to send withdrawable amount to sender");
    }

    /// @notice     Get the caller's withdraw allowance.
    /// @return     The caller's withdraw allowance in wei.
    function getWithdrawableAmount(DepositUtils.Deposit storage _d)
        internal
        view
        returns (uint256)
    {
        return _d.withdrawableAmounts[msg.sender];
    }

    /// @notice     Distributes the fee rebate to the Fee Rebate Token owner.
    /// @dev        Whenever this is called we are shutting down.
    function distributeFeeRebate(Deposit storage _d) internal {
        address rebateTokenHolder = feeRebateTokenHolder(_d);

        // exit the function if there is nobody to send the rebate to
        if (rebateTokenHolder == address(0)) {
            return;
        }

        // pay out the rebate if it is available
        if (_d.tbtcToken.balanceOf(address(this)) >= signerFeeTbtc(_d)) {
            _d.tbtcToken.transfer(rebateTokenHolder, signerFeeTbtc(_d));
        }
    }

    /// @notice             Pushes ether held by the deposit to the signer group.
    /// @dev                Ether is returned to signing group members bonds.
    /// @param  _ethValue   The amount of ether to send.
    function pushFundsToKeepGroup(Deposit storage _d, uint256 _ethValue)
        internal
    {
        require(address(this).balance >= _ethValue, "Not enough funds to send");
        if (_ethValue > 0) {
            IBondedECDSAKeep _keep = IBondedECDSAKeep(_d.keepAddress);
            _keep.returnPartialSignerBonds.value(_ethValue)();
        }
    }

    /// @notice Calculate TBTC amount required for redemption by a specified
    ///         _redeemer. If _assumeRedeemerHoldTdt is true, return the
    ///         requirement as if the redeemer holds this deposit's TDT.
    /// @dev Will revert if redemption is not possible by the current owner and
    ///      _assumeRedeemerHoldsTdt was not set. Setting
    ///      _assumeRedeemerHoldsTdt only when appropriate is the responsibility
    ///      of the caller; as such, this function should NEVER be publicly
    ///      exposed.
    /// @param _redeemer The account that should be treated as redeeming this
    ///        deposit  for the purposes of this calculation.
    /// @param _assumeRedeemerHoldsTdt If true, the calculation assumes that the
    ///        specified redeemer holds the TDT. If false, the calculation
    ///        checks the deposit owner against the specified _redeemer. Note
    ///        that this parameter should be false for all mutating calls to
    ///        preserve system correctness.
    /// @return A tuple of the amount the redeemer owes to the deposit to
    ///         initiate redemption, the amount that is owed to the TDT holder
    ///         when redemption is initiated, and the amount that is owed to the
    ///         FRT holder when redemption is initiated.
    function calculateRedemptionTbtcAmounts(
        DepositUtils.Deposit storage _d,
        address _redeemer,
        bool _assumeRedeemerHoldsTdt
    )
        internal
        view
        returns (
            uint256 owedToDeposit,
            uint256 owedToTdtHolder,
            uint256 owedToFrtHolder
        )
    {
        bool redeemerHoldsTdt =
            _assumeRedeemerHoldsTdt || depositOwner(_d) == _redeemer;
        bool preTerm = remainingTerm(_d) > 0 && !_d.inCourtesyCall();

        require(
            redeemerHoldsTdt || !preTerm,
            "Only TDT holder can redeem unless deposit is at-term or in COURTESY_CALL"
        );

        bool frtExists = feeRebateTokenHolder(_d) != address(0);
        bool redeemerHoldsFrt = feeRebateTokenHolder(_d) == _redeemer;
        uint256 signerFee = signerFeeTbtc(_d);

        uint256 feeEscrow =
            calculateRedemptionFeeEscrow(
                signerFee,
                preTerm,
                frtExists,
                redeemerHoldsTdt,
                redeemerHoldsFrt
            );

        // Base redemption + fee = total we need to have escrowed to start
        // redemption.
        owedToDeposit = calculateBaseRedemptionCharge(
            lotSizeTbtc(_d),
            redeemerHoldsTdt
        )
            .add(feeEscrow);

        // Adjust the amount owed to the deposit based on any balance the
        // deposit already has.
        uint256 balance = _d.tbtcToken.balanceOf(address(this));
        if (owedToDeposit > balance) {
            owedToDeposit = owedToDeposit.sub(balance);
        } else {
            owedToDeposit = 0;
        }

        // Pre-term, the FRT rebate is payed out, but if the redeemer holds the
        // FRT, the amount has already been subtracted from what is owed to the
        // deposit at this point (by calculateRedemptionFeeEscrow). This allows
        // the redeemer to simply *not pay* the fee rebate, rather than having
        // them pay it only to have it immediately returned.
        if (preTerm && frtExists && !redeemerHoldsFrt) {
            owedToFrtHolder = signerFee;
        }

        // The TDT holder gets any leftover balance.
        owedToTdtHolder = balance.add(owedToDeposit).sub(signerFee).sub(
            owedToFrtHolder
        );

        return (owedToDeposit, owedToTdtHolder, owedToFrtHolder);
    }

    /// @notice                    Get the base TBTC amount needed to redeem.
    /// @param _lotSize   The lot size to use for the base redemption charge.
    /// @param _redeemerHoldsTdt   True if the redeemer is the TDT holder.
    /// @return                    The amount in TBTC.
    function calculateBaseRedemptionCharge(
        uint256 _lotSize,
        bool _redeemerHoldsTdt
    ) internal pure returns (uint256) {
        if (_redeemerHoldsTdt) {
            return 0;
        }
        return _lotSize;
    }

    /// @notice  Get fees owed for redemption
    /// @param signerFee The value of the signer fee for fee calculations.
    /// @param _preTerm               True if the Deposit is at-term or in courtesy_call.
    /// @param _frtExists     True if the FRT exists.
    /// @param _redeemerHoldsTdt     True if the the redeemer holds the TDT.
    /// @param _redeemerHoldsFrt     True if the redeemer holds the FRT.
    /// @return                      The fees owed in TBTC.
    function calculateRedemptionFeeEscrow(
        uint256 signerFee,
        bool _preTerm,
        bool _frtExists,
        bool _redeemerHoldsTdt,
        bool _redeemerHoldsFrt
    ) internal pure returns (uint256) {
        // Escrow the fee rebate so the FRT holder can be repaids, unless the
        // redeemer holds the FRT, in which case we simply don't require the
        // rebate from them.
        bool escrowRequiresFeeRebate =
            _preTerm && _frtExists && !_redeemerHoldsFrt;

        bool escrowRequiresFee =
            _preTerm ||
                // If the FRT exists at term/courtesy call, the fee is
                // "required", but should already be escrowed before redemption.
                _frtExists ||
                // The TDT holder always owes fees if there is no FRT.
                _redeemerHoldsTdt;

        uint256 feeEscrow = 0;
        if (escrowRequiresFee) {
            feeEscrow += signerFee;
        }
        if (escrowRequiresFeeRebate) {
            feeEscrow += signerFee;
        }

        return feeEscrow;
    }
}

pragma solidity 0.5.17;

import {DepositUtils} from "./DepositUtils.sol";

library DepositStates {
    enum States {
        // DOES NOT EXIST YET
        START,
        // FUNDING FLOW
        AWAITING_SIGNER_SETUP,
        AWAITING_BTC_FUNDING_PROOF,
        // FAILED SETUP
        FAILED_SETUP,
        // ACTIVE
        ACTIVE, // includes courtesy call
        // REDEMPTION FLOW
        AWAITING_WITHDRAWAL_SIGNATURE,
        AWAITING_WITHDRAWAL_PROOF,
        REDEEMED,
        // SIGNER LIQUIDATION FLOW
        COURTESY_CALL,
        FRAUD_LIQUIDATION_IN_PROGRESS,
        LIQUIDATION_IN_PROGRESS,
        LIQUIDATED
    }

    /// @notice     Check if the contract is currently in the funding flow.
    /// @dev        This checks on the funding flow happy path, not the fraud path.
    /// @param _d   Deposit storage pointer.
    /// @return     True if contract is currently in the funding flow else False.
    function inFunding(DepositUtils.Deposit storage _d)
        external
        view
        returns (bool)
    {
        return (_d.currentState == uint8(States.AWAITING_SIGNER_SETUP) ||
            _d.currentState == uint8(States.AWAITING_BTC_FUNDING_PROOF));
    }

    /// @notice     Check if the contract is currently in the signer liquidation flow.
    /// @dev        This could be caused by fraud, or by an unfilled margin call.
    /// @param _d   Deposit storage pointer.
    /// @return     True if contract is currently in the liquidaton flow else False.
    function inSignerLiquidation(DepositUtils.Deposit storage _d)
        external
        view
        returns (bool)
    {
        return (_d.currentState == uint8(States.LIQUIDATION_IN_PROGRESS) ||
            _d.currentState == uint8(States.FRAUD_LIQUIDATION_IN_PROGRESS));
    }

    /// @notice     Check if the contract is currently in the redepmtion flow.
    /// @dev        This checks on the redemption flow, not the REDEEMED termination state.
    /// @param _d   Deposit storage pointer.
    /// @return     True if contract is currently in the redemption flow else False.
    function inRedemption(DepositUtils.Deposit storage _d)
        external
        view
        returns (bool)
    {
        return (_d.currentState ==
            uint8(States.AWAITING_WITHDRAWAL_SIGNATURE) ||
            _d.currentState == uint8(States.AWAITING_WITHDRAWAL_PROOF));
    }

    /// @notice     Check if the contract has halted.
    /// @dev        This checks on any halt state, regardless of triggering circumstances.
    /// @param _d   Deposit storage pointer.
    /// @return     True if contract has halted permanently.
    function inEndState(DepositUtils.Deposit storage _d)
        external
        view
        returns (bool)
    {
        return (_d.currentState == uint8(States.LIQUIDATED) ||
            _d.currentState == uint8(States.REDEEMED) ||
            _d.currentState == uint8(States.FAILED_SETUP));
    }

    /// @notice     Check if the contract is available for a redemption request.
    /// @dev        Redemption is available from active and courtesy call.
    /// @param _d   Deposit storage pointer.
    /// @return     True if available, False otherwise.
    function inRedeemableState(DepositUtils.Deposit storage _d)
        external
        view
        returns (bool)
    {
        return (_d.currentState == uint8(States.ACTIVE) ||
            _d.currentState == uint8(States.COURTESY_CALL));
    }

    /// @notice     Check if the contract is currently in the start state (awaiting setup).
    /// @dev        This checks on the funding flow happy path, not the fraud path.
    /// @param _d   Deposit storage pointer.
    /// @return     True if contract is currently in the start state else False.
    function inStart(DepositUtils.Deposit storage _d)
        external
        view
        returns (bool)
    {
        return (_d.currentState == uint8(States.START));
    }

    function inAwaitingSignerSetup(DepositUtils.Deposit storage _d)
        external
        view
        returns (bool)
    {
        return _d.currentState == uint8(States.AWAITING_SIGNER_SETUP);
    }

    function inAwaitingBTCFundingProof(DepositUtils.Deposit storage _d)
        external
        view
        returns (bool)
    {
        return _d.currentState == uint8(States.AWAITING_BTC_FUNDING_PROOF);
    }

    function inFailedSetup(DepositUtils.Deposit storage _d)
        external
        view
        returns (bool)
    {
        return _d.currentState == uint8(States.FAILED_SETUP);
    }

    function inActive(DepositUtils.Deposit storage _d)
        external
        view
        returns (bool)
    {
        return _d.currentState == uint8(States.ACTIVE);
    }

    function inAwaitingWithdrawalSignature(DepositUtils.Deposit storage _d)
        external
        view
        returns (bool)
    {
        return _d.currentState == uint8(States.AWAITING_WITHDRAWAL_SIGNATURE);
    }

    function inAwaitingWithdrawalProof(DepositUtils.Deposit storage _d)
        external
        view
        returns (bool)
    {
        return _d.currentState == uint8(States.AWAITING_WITHDRAWAL_PROOF);
    }

    function inRedeemed(DepositUtils.Deposit storage _d)
        external
        view
        returns (bool)
    {
        return _d.currentState == uint8(States.REDEEMED);
    }

    function inCourtesyCall(DepositUtils.Deposit storage _d)
        external
        view
        returns (bool)
    {
        return _d.currentState == uint8(States.COURTESY_CALL);
    }

    function inFraudLiquidationInProgress(DepositUtils.Deposit storage _d)
        external
        view
        returns (bool)
    {
        return _d.currentState == uint8(States.FRAUD_LIQUIDATION_IN_PROGRESS);
    }

    function inLiquidationInProgress(DepositUtils.Deposit storage _d)
        external
        view
        returns (bool)
    {
        return _d.currentState == uint8(States.LIQUIDATION_IN_PROGRESS);
    }

    function inLiquidated(DepositUtils.Deposit storage _d)
        external
        view
        returns (bool)
    {
        return _d.currentState == uint8(States.LIQUIDATED);
    }

    function setAwaitingSignerSetup(DepositUtils.Deposit storage _d) external {
        _d.currentState = uint8(States.AWAITING_SIGNER_SETUP);
    }

    function setAwaitingBTCFundingProof(DepositUtils.Deposit storage _d)
        external
    {
        _d.currentState = uint8(States.AWAITING_BTC_FUNDING_PROOF);
    }

    function setFailedSetup(DepositUtils.Deposit storage _d) external {
        _d.currentState = uint8(States.FAILED_SETUP);
    }

    function setActive(DepositUtils.Deposit storage _d) external {
        _d.currentState = uint8(States.ACTIVE);
    }

    function setAwaitingWithdrawalSignature(DepositUtils.Deposit storage _d)
        external
    {
        _d.currentState = uint8(States.AWAITING_WITHDRAWAL_SIGNATURE);
    }

    function setAwaitingWithdrawalProof(DepositUtils.Deposit storage _d)
        external
    {
        _d.currentState = uint8(States.AWAITING_WITHDRAWAL_PROOF);
    }

    function setRedeemed(DepositUtils.Deposit storage _d) external {
        _d.currentState = uint8(States.REDEEMED);
    }

    function setCourtesyCall(DepositUtils.Deposit storage _d) external {
        _d.currentState = uint8(States.COURTESY_CALL);
    }

    function setFraudLiquidationInProgress(DepositUtils.Deposit storage _d)
        external
    {
        _d.currentState = uint8(States.FRAUD_LIQUIDATION_IN_PROGRESS);
    }

    function setLiquidationInProgress(DepositUtils.Deposit storage _d)
        external
    {
        _d.currentState = uint8(States.LIQUIDATION_IN_PROGRESS);
    }

    function setLiquidated(DepositUtils.Deposit storage _d) external {
        _d.currentState = uint8(States.LIQUIDATED);
    }
}

pragma solidity 0.5.17;

import {BTCUtils} from "@summa-tx/bitcoin-spv-sol/contracts/BTCUtils.sol";
import {BytesLib} from "@summa-tx/bitcoin-spv-sol/contracts/BytesLib.sol";
import {ValidateSPV} from "@summa-tx/bitcoin-spv-sol/contracts/ValidateSPV.sol";
import {
    CheckBitcoinSigs
} from "@summa-tx/bitcoin-spv-sol/contracts/CheckBitcoinSigs.sol";
import {
    IERC721
} from "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import {SafeMath} from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import {
    IBondedECDSAKeep
} from "@keep-network/keep-ecdsa/contracts/api/IBondedECDSAKeep.sol";
import {DepositUtils} from "./DepositUtils.sol";
import {DepositStates} from "./DepositStates.sol";
import {OutsourceDepositLogging} from "./OutsourceDepositLogging.sol";
import {TBTCConstants} from "../system/TBTCConstants.sol";
import {TBTCToken} from "../system/TBTCToken.sol";
import {DepositLiquidation} from "./DepositLiquidation.sol";

library DepositRedemption {
    using SafeMath for uint256;
    using CheckBitcoinSigs for bytes;
    using BytesLib for bytes;
    using BTCUtils for bytes;
    using ValidateSPV for bytes;
    using ValidateSPV for bytes32;

    using DepositUtils for DepositUtils.Deposit;
    using DepositStates for DepositUtils.Deposit;
    using DepositLiquidation for DepositUtils.Deposit;
    using OutsourceDepositLogging for DepositUtils.Deposit;

    /// @notice     Pushes signer fee to the Keep group by transferring it to the Keep address.
    /// @dev        Approves the keep contract, then expects it to call transferFrom.
    function distributeSignerFee(DepositUtils.Deposit storage _d) internal {
        IBondedECDSAKeep _keep = IBondedECDSAKeep(_d.keepAddress);

        _d.tbtcToken.approve(_d.keepAddress, _d.signerFeeTbtc());
        _keep.distributeERC20Reward(address(_d.tbtcToken), _d.signerFeeTbtc());
    }

    /// @notice Approves digest for signing by a keep.
    /// @dev Calls given keep to sign the digest. Records a current timestamp
    /// for given digest.
    /// @param _digest Digest to approve.
    function approveDigest(DepositUtils.Deposit storage _d, bytes32 _digest)
        internal
    {
        IBondedECDSAKeep(_d.keepAddress).sign(_digest);

        _d.approvedDigests[_digest] = block.timestamp;
    }

    /// @notice Handles TBTC requirements for redemption.
    /// @dev Burns or transfers depending on term and supply-peg impact.
    ///      Once these transfers complete, the deposit balance should be
    ///      sufficient to pay out signer fees once the redemption transaction
    ///      is proven on the Bitcoin side.
    function performRedemptionTbtcTransfers(DepositUtils.Deposit storage _d)
        internal
    {
        address tdtHolder = _d.depositOwner();
        address frtHolder = _d.feeRebateTokenHolder();
        address vendingMachineAddress = _d.vendingMachineAddress;

        (
            uint256 tbtcOwedToDeposit,
            uint256 tbtcOwedToTdtHolder,
            uint256 tbtcOwedToFrtHolder
        ) = _d.calculateRedemptionTbtcAmounts(_d.redeemerAddress, false);

        if (tbtcOwedToDeposit > 0) {
            _d.tbtcToken.transferFrom(
                msg.sender,
                address(this),
                tbtcOwedToDeposit
            );
        }
        if (tbtcOwedToTdtHolder > 0) {
            if (tdtHolder == vendingMachineAddress) {
                _d.tbtcToken.burn(tbtcOwedToTdtHolder);
            } else {
                _d.tbtcToken.transfer(tdtHolder, tbtcOwedToTdtHolder);
            }
        }
        if (tbtcOwedToFrtHolder > 0) {
            _d.tbtcToken.transfer(frtHolder, tbtcOwedToFrtHolder);
        }
    }

    function _requestRedemption(
        DepositUtils.Deposit storage _d,
        bytes8 _outputValueBytes,
        bytes memory _redeemerOutputScript,
        address payable _redeemer
    ) internal {
        require(
            _d.inRedeemableState(),
            "Redemption only available from Active or Courtesy state"
        );
        bytes memory _output =
            abi.encodePacked(_outputValueBytes, _redeemerOutputScript);
        require(
            _output.extractHash().length > 0,
            "Output script must be a standard type"
        );

        // set redeemerAddress early to enable direct access by other functions
        _d.redeemerAddress = _redeemer;

        performRedemptionTbtcTransfers(_d);

        // Convert the 8-byte LE ints to uint256
        uint256 _outputValue =
            abi
                .encodePacked(_outputValueBytes)
                .reverseEndianness()
                .bytesToUint();
        uint256 _requestedFee = _d.utxoValue().sub(_outputValue);

        require(
            _requestedFee >= TBTCConstants.getMinimumRedemptionFee(),
            "Fee is too low"
        );
        require(
            _requestedFee < _d.utxoValue() / 2,
            "Initial fee cannot exceed half of the deposit's value"
        );

        // Calculate the sighash
        bytes32 _sighash =
            CheckBitcoinSigs.wpkhSpendSighash(
                _d.utxoOutpoint,
                _d.signerPKH(),
                _d.utxoValueBytes,
                _outputValueBytes,
                _redeemerOutputScript
            );

        // write all request details
        _d.redeemerOutputScript = _redeemerOutputScript;
        _d.initialRedemptionFee = _requestedFee;
        _d.latestRedemptionFee = _requestedFee;
        _d.withdrawalRequestTime = block.timestamp;
        _d.lastRequestedDigest = _sighash;

        approveDigest(_d, _sighash);

        _d.setAwaitingWithdrawalSignature();
        _d.logRedemptionRequested(
            _redeemer,
            _sighash,
            _d.utxoValue(),
            _redeemerOutputScript,
            _requestedFee,
            _d.utxoOutpoint
        );
    }

    /// @notice                     Anyone can request redemption as long as they can.
    ///                             approve the TDT transfer to the final recipient.
    /// @dev                        The redeemer specifies details about the Bitcoin redemption tx and pays for the redemption
    ///                             on behalf of _finalRecipient.
    /// @param  _d                  Deposit storage pointer.
    /// @param  _outputValueBytes   The 8-byte LE output size.
    /// @param  _redeemerOutputScript The redeemer's length-prefixed output script.
    /// @param  _finalRecipient     The address to receive the TDT and later be recorded as deposit redeemer.
    function transferAndRequestRedemption(
        DepositUtils.Deposit storage _d,
        bytes8 _outputValueBytes,
        bytes memory _redeemerOutputScript,
        address payable _finalRecipient
    ) public {
        // not external to allow bytes memory parameters
        _d.tbtcDepositToken.transferFrom(
            msg.sender,
            _finalRecipient,
            uint256(address(this))
        );

        _requestRedemption(
            _d,
            _outputValueBytes,
            _redeemerOutputScript,
            _finalRecipient
        );
    }

    /// @notice                     Only TDT holder can request redemption,
    ///                             unless Deposit is expired or in COURTESY_CALL.
    /// @dev                        The redeemer specifies details about the Bitcoin redemption transaction.
    /// @param  _d                  Deposit storage pointer.
    /// @param  _outputValueBytes   The 8-byte LE output size.
    /// @param  _redeemerOutputScript The redeemer's length-prefixed output script.
    function requestRedemption(
        DepositUtils.Deposit storage _d,
        bytes8 _outputValueBytes,
        bytes memory _redeemerOutputScript
    ) public {
        // not external to allow bytes memory parameters
        _requestRedemption(
            _d,
            _outputValueBytes,
            _redeemerOutputScript,
            msg.sender
        );
    }

    /// @notice     Anyone may provide a withdrawal signature if it was requested.
    /// @dev        The signers will be penalized if this (or provideRedemptionProof) is not called.
    /// @param  _d  Deposit storage pointer.
    /// @param  _v  Signature recovery value.
    /// @param  _r  Signature R value.
    /// @param  _s  Signature S value. Should be in the low half of secp256k1 curve's order.
    function provideRedemptionSignature(
        DepositUtils.Deposit storage _d,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(
            _d.inAwaitingWithdrawalSignature(),
            "Not currently awaiting a signature"
        );

        // If we're outside of the signature window, we COULD punish signers here
        // Instead, we consider this a no-harm-no-foul situation.
        // The signers have not stolen funds. Most likely they've just inconvenienced someone

        // Validate `s` value for a malleability concern described in EIP-2.
        // Only signatures with `s` value in the lower half of the secp256k1
        // curve's order are considered valid.
        require(
            uint256(_s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "Malleable signature - s should be in the low half of secp256k1 curve's order"
        );

        // The signature must be valid on the pubkey
        require(
            _d.signerPubkey().checkSig(_d.lastRequestedDigest, _v, _r, _s),
            "Invalid signature"
        );

        // A signature has been provided, now we wait for fee bump or redemption
        _d.setAwaitingWithdrawalProof();
        _d.logGotRedemptionSignature(_d.lastRequestedDigest, _r, _s);
    }

    /// @notice                             Anyone may notify the contract that a fee bump is needed.
    /// @dev                                This sends us back to AWAITING_WITHDRAWAL_SIGNATURE.
    /// @param  _d                          Deposit storage pointer.
    /// @param  _previousOutputValueBytes   The previous output's value.
    /// @param  _newOutputValueBytes        The new output's value.
    function increaseRedemptionFee(
        DepositUtils.Deposit storage _d,
        bytes8 _previousOutputValueBytes,
        bytes8 _newOutputValueBytes
    ) public {
        require(
            _d.inAwaitingWithdrawalProof(),
            "Fee increase only available after signature provided"
        );
        require(
            block.timestamp >=
                _d.withdrawalRequestTime.add(
                    TBTCConstants.getIncreaseFeeTimer()
                ),
            "Fee increase not yet permitted"
        );

        uint256 _newOutputValue =
            checkRelationshipToPrevious(
                _d,
                _previousOutputValueBytes,
                _newOutputValueBytes
            );

        // If the fee bump shrinks the UTXO value below the minimum allowed
        // value, clamp it to that minimum. Further fee bumps will be disallowed
        // by checkRelationshipToPrevious.
        if (_newOutputValue < TBTCConstants.getMinimumUtxoValue()) {
            _newOutputValue = TBTCConstants.getMinimumUtxoValue();
        }

        _d.latestRedemptionFee = _d.utxoValue().sub(_newOutputValue);

        // Calculate the next sighash
        bytes32 _sighash =
            CheckBitcoinSigs.wpkhSpendSighash(
                _d.utxoOutpoint,
                _d.signerPKH(),
                _d.utxoValueBytes,
                _newOutputValueBytes,
                _d.redeemerOutputScript
            );

        // Ratchet the signature and redemption proof timeouts
        _d.withdrawalRequestTime = block.timestamp;
        _d.lastRequestedDigest = _sighash;

        approveDigest(_d, _sighash);

        // Go back to waiting for a signature
        _d.setAwaitingWithdrawalSignature();
        _d.logRedemptionRequested(
            msg.sender,
            _sighash,
            _d.utxoValue(),
            _d.redeemerOutputScript,
            _d.latestRedemptionFee,
            _d.utxoOutpoint
        );
    }

    function checkRelationshipToPrevious(
        DepositUtils.Deposit storage _d,
        bytes8 _previousOutputValueBytes,
        bytes8 _newOutputValueBytes
    ) public view returns (uint256 _newOutputValue) {
        // Check that we're incrementing the fee by exactly the redeemer's initial fee
        uint256 _previousOutputValue =
            DepositUtils.bytes8LEToUint(_previousOutputValueBytes);
        _newOutputValue = DepositUtils.bytes8LEToUint(_newOutputValueBytes);
        require(
            _previousOutputValue.sub(_newOutputValue) ==
                _d.initialRedemptionFee,
            "Not an allowed fee step"
        );

        // Calculate the previous one so we can check that it really is the previous one
        bytes32 _previousSighash =
            CheckBitcoinSigs.wpkhSpendSighash(
                _d.utxoOutpoint,
                _d.signerPKH(),
                _d.utxoValueBytes,
                _previousOutputValueBytes,
                _d.redeemerOutputScript
            );
        require(
            _d.wasDigestApprovedForSigning(_previousSighash) ==
                _d.withdrawalRequestTime,
            "Provided previous value does not yield previous sighash"
        );
    }

    /// @notice                 Anyone may provide a withdrawal proof to prove redemption.
    /// @dev                    The signers will be penalized if this is not called.
    /// @param  _d              Deposit storage pointer.
    /// @param  _txVersion      Transaction version number (4-byte LE).
    /// @param  _txInputVector  All transaction inputs prepended by the number of inputs encoded as a VarInt, max 0xFC(252) inputs.
    /// @param  _txOutputVector All transaction outputs prepended by the number of outputs encoded as a VarInt, max 0xFC(252) outputs.
    /// @param  _txLocktime     Final 4 bytes of the transaction.
    /// @param  _merkleProof    The merkle proof of inclusion of the tx in the bitcoin block.
    /// @param  _txIndexInBlock The index of the tx in the Bitcoin block (0-indexed).
    /// @param  _bitcoinHeaders An array of tightly-packed bitcoin headers.
    function provideRedemptionProof(
        DepositUtils.Deposit storage _d,
        bytes4 _txVersion,
        bytes memory _txInputVector,
        bytes memory _txOutputVector,
        bytes4 _txLocktime,
        bytes memory _merkleProof,
        uint256 _txIndexInBlock,
        bytes memory _bitcoinHeaders
    ) public {
        // not external to allow bytes memory parameters
        bytes32 _txid;
        uint256 _fundingOutputValue;

        require(
            _d.inRedemption(),
            "Redemption proof only allowed from redemption flow"
        );

        _fundingOutputValue = redemptionTransactionChecks(
            _d,
            _txInputVector,
            _txOutputVector
        );

        _txid = abi
            .encodePacked(
            _txVersion,
            _txInputVector,
            _txOutputVector,
            _txLocktime
        )
            .hash256();
        _d.checkProofFromTxId(
            _txid,
            _merkleProof,
            _txIndexInBlock,
            _bitcoinHeaders
        );

        require(
            (_d.utxoValue().sub(_fundingOutputValue)) <= _d.latestRedemptionFee,
            "Incorrect fee amount"
        );

        // Transfer TBTC to signers and close the keep.
        distributeSignerFee(_d);
        _d.closeKeep();

        _d.distributeFeeRebate();

        // We're done yey!
        _d.setRedeemed();
        _d.redemptionTeardown();
        _d.logRedeemed(_txid);
    }

    /// @notice                 Check the redemption transaction input and output vector to ensure the transaction spends
    ///                         the correct UTXO and sends value to the appropriate public key hash.
    /// @dev                    We only look at the first input and first output. Revert if we find the wrong UTXO or value recipient.
    ///                         It's safe to look at only the first input/output as anything that breaks this can be considered fraud
    ///                         and can be caught by ECDSAFraudProof.
    /// @param  _d              Deposit storage pointer.
    /// @param _txInputVector   All transaction inputs prepended by the number of inputs encoded as a VarInt, max 0xFC(252) inputs.
    /// @param _txOutputVector  All transaction outputs prepended by the number of outputs encoded as a VarInt, max 0xFC(252) outputs.
    /// @return                 The value sent to the redeemer's public key hash.
    function redemptionTransactionChecks(
        DepositUtils.Deposit storage _d,
        bytes memory _txInputVector,
        bytes memory _txOutputVector
    ) public view returns (uint256) {
        require(_txInputVector.validateVin(), "invalid input vector provided");
        require(
            _txOutputVector.validateVout(),
            "invalid output vector provided"
        );
        bytes memory _input =
            _txInputVector.slice(1, _txInputVector.length - 1);

        require(
            keccak256(_input.extractOutpoint()) == keccak256(_d.utxoOutpoint),
            "Tx spends the wrong UTXO"
        );

        bytes memory _output =
            _txOutputVector.slice(1, _txOutputVector.length - 1);
        bytes memory _expectedOutputScript = _d.redeemerOutputScript;
        require(
            _output.length - 8 >= _d.redeemerOutputScript.length,
            "Output script is too short to extract the expected script"
        );
        require(
            keccak256(_output.slice(8, _expectedOutputScript.length)) ==
                keccak256(_expectedOutputScript),
            "Tx sends value to wrong output script"
        );
        return (uint256(_output.extractValue()));
    }

    /// @notice     Anyone may notify the contract that the signers have failed to produce a signature.
    /// @dev        This is considered fraud, and is punished.
    /// @param  _d  Deposit storage pointer.
    function notifyRedemptionSignatureTimedOut(DepositUtils.Deposit storage _d)
        external
    {
        require(
            _d.inAwaitingWithdrawalSignature(),
            "Not currently awaiting a signature"
        );
        require(
            block.timestamp >
                _d.withdrawalRequestTime.add(
                    TBTCConstants.getSignatureTimeout()
                ),
            "Signature timer has not elapsed"
        );
        _d.startLiquidation(false); // not fraud, just failure
    }

    /// @notice     Anyone may notify the contract that the signers have failed to produce a redemption proof.
    /// @dev        This is considered fraud, and is punished.
    /// @param  _d  Deposit storage pointer.
    function notifyRedemptionProofTimedOut(DepositUtils.Deposit storage _d)
        external
    {
        require(
            _d.inAwaitingWithdrawalProof(),
            "Not currently awaiting a redemption proof"
        );
        require(
            block.timestamp >
                _d.withdrawalRequestTime.add(
                    TBTCConstants.getRedemptionProofTimeout()
                ),
            "Proof timer has not elapsed"
        );
        _d.startLiquidation(false); // not fraud, just failure
    }
}

pragma solidity 0.5.17;

import {BTCUtils} from "@summa-tx/bitcoin-spv-sol/contracts/BTCUtils.sol";
import {BytesLib} from "@summa-tx/bitcoin-spv-sol/contracts/BytesLib.sol";
import {
    IBondedECDSAKeep
} from "@keep-network/keep-ecdsa/contracts/api/IBondedECDSAKeep.sol";
import {SafeMath} from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import {DepositStates} from "./DepositStates.sol";
import {DepositUtils} from "./DepositUtils.sol";
import {TBTCConstants} from "../system/TBTCConstants.sol";
import {OutsourceDepositLogging} from "./OutsourceDepositLogging.sol";
import {TBTCToken} from "../system/TBTCToken.sol";
import {ITBTCSystem} from "../interfaces/ITBTCSystem.sol";

library DepositLiquidation {
    using BTCUtils for bytes;
    using BytesLib for bytes;
    using SafeMath for uint256;
    using SafeMath for uint64;

    using DepositUtils for DepositUtils.Deposit;
    using DepositStates for DepositUtils.Deposit;
    using OutsourceDepositLogging for DepositUtils.Deposit;

    /// @notice Notifies the keep contract of fraud. Reverts if not fraud.
    /// @dev Calls out to the keep contract. this could get expensive if preimage
    ///      is large.
    /// @param  _d Deposit storage pointer.
    /// @param  _v Signature recovery value.
    /// @param  _r Signature R value.
    /// @param  _s Signature S value.
    /// @param _signedDigest The digest signed by the signature vrs tuple.
    /// @param _preimage The sha256 preimage of the digest.
    function submitSignatureFraud(
        DepositUtils.Deposit storage _d,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes32 _signedDigest,
        bytes memory _preimage
    ) public {
        IBondedECDSAKeep _keep = IBondedECDSAKeep(_d.keepAddress);
        _keep.submitSignatureFraud(_v, _r, _s, _signedDigest, _preimage);
    }

    /// @notice     Determines the collateralization percentage of the signing group.
    /// @dev        Compares the bond value and lot value.
    /// @param _d   Deposit storage pointer.
    /// @return     Collateralization percentage as uint.
    function collateralizationPercentage(DepositUtils.Deposit storage _d)
        public
        view
        returns (uint256)
    {
        // Determine value of the lot in wei
        uint256 _satoshiPrice = _d.fetchBitcoinPrice();
        uint64 _lotSizeSatoshis = _d.lotSizeSatoshis;
        uint256 _lotValue = _lotSizeSatoshis.mul(_satoshiPrice);

        // Amount of wei the signers have
        uint256 _bondValue = _d.fetchBondAmount();

        // This converts into a percentage
        return (_bondValue.mul(100).div(_lotValue));
    }

    /// @dev              Starts signer liquidation by seizing signer bonds.
    ///                   If the deposit is currently being redeemed, the redeemer
    ///                   receives the full bond value; otherwise, a falling price auction
    ///                   begins to buy 1 TBTC in exchange for a portion of the seized bonds;
    ///                   see purchaseSignerBondsAtAuction().
    /// @param _wasFraud  True if liquidation is being started due to fraud, false if for any other reason.
    /// @param _d         Deposit storage pointer.
    function startLiquidation(DepositUtils.Deposit storage _d, bool _wasFraud)
        internal
    {
        _d.logStartedLiquidation(_wasFraud);

        uint256 seized = _d.seizeSignerBonds();
        address redeemerAddress = _d.redeemerAddress;

        // Reclaim used state for gas savings
        _d.redemptionTeardown();

        // If we see fraud in the redemption flow, we shouldn't go to auction.
        // Instead give the full signer bond directly to the redeemer.
        if (_d.inRedemption() && _wasFraud) {
            _d.setLiquidated();
            _d.enableWithdrawal(redeemerAddress, seized);
            _d.logLiquidated();
            return;
        }

        _d.liquidationInitiator = msg.sender;
        _d.liquidationInitiated = block.timestamp; // Store the timestamp for auction

        if (_wasFraud) {
            _d.setFraudLiquidationInProgress();
        } else {
            _d.setLiquidationInProgress();
        }
    }

    /// @notice                 Anyone can provide a signature that was not requested to prove fraud.
    /// @dev                    Calls out to the keep to verify if there was fraud.
    /// @param  _d              Deposit storage pointer.
    /// @param  _v              Signature recovery value.
    /// @param  _r              Signature R value.
    /// @param  _s              Signature S value.
    /// @param _signedDigest    The digest signed by the signature vrs tuple.
    /// @param _preimage        The sha256 preimage of the digest.
    function provideECDSAFraudProof(
        DepositUtils.Deposit storage _d,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes32 _signedDigest,
        bytes memory _preimage
    ) public {
        // not external to allow bytes memory parameters
        require(!_d.inFunding(), "Use provideFundingECDSAFraudProof instead");
        require(
            !_d.inSignerLiquidation(),
            "Signer liquidation already in progress"
        );
        require(!_d.inEndState(), "Contract has halted");
        submitSignatureFraud(_d, _v, _r, _s, _signedDigest, _preimage);

        startLiquidation(_d, true);
    }

    /// @notice     Closes an auction and purchases the signer bonds. Payout to buyer, funder, then signers if not fraud.
    /// @dev        For interface, reading auctionValue will give a past value. the current is better.
    /// @param  _d  Deposit storage pointer.
    function purchaseSignerBondsAtAuction(DepositUtils.Deposit storage _d)
        external
    {
        bool _wasFraud = _d.inFraudLiquidationInProgress();
        require(_d.inSignerLiquidation(), "No active auction");

        _d.setLiquidated();
        _d.logLiquidated();

        // Send the TBTC to the redeemer if they exist, otherwise to the TDT
        // holder. If the TDT holder is the Vending Machine, burn it to maintain
        // the peg. This is because, if there is a redeemer set here, the TDT
        // holder has already been made whole at redemption request time.
        address tbtcRecipient = _d.redeemerAddress;
        if (tbtcRecipient == address(0)) {
            tbtcRecipient = _d.depositOwner();
        }
        uint256 lotSizeTbtc = _d.lotSizeTbtc();

        require(
            _d.tbtcToken.balanceOf(msg.sender) >= lotSizeTbtc,
            "Not enough TBTC to cover outstanding debt"
        );

        if (tbtcRecipient == _d.vendingMachineAddress) {
            _d.tbtcToken.burnFrom(msg.sender, lotSizeTbtc); // burn minimal amount to cover size
        } else {
            _d.tbtcToken.transferFrom(msg.sender, tbtcRecipient, lotSizeTbtc);
        }

        // Distribute funds to auction buyer
        uint256 valueToDistribute = _d.auctionValue();
        _d.enableWithdrawal(msg.sender, valueToDistribute);

        // Send any TBTC left to the Fee Rebate Token holder
        _d.distributeFeeRebate();

        // For fraud, pay remainder to the liquidation initiator.
        // For non-fraud, split 50-50 between initiator and signers. if the transfer amount is 1,
        // division will yield a 0 value which causes a revert; instead,
        // we simply ignore such a tiny amount and leave some wei dust in escrow
        uint256 contractEthBalance = address(this).balance;
        address payable initiator = _d.liquidationInitiator;

        if (initiator == address(0)) {
            initiator = address(0xdead);
        }
        if (contractEthBalance > valueToDistribute + 1) {
            uint256 remainingUnallocated =
                contractEthBalance.sub(valueToDistribute);
            if (_wasFraud) {
                _d.enableWithdrawal(initiator, remainingUnallocated);
            } else {
                // There will always be a liquidation initiator.
                uint256 split = remainingUnallocated.div(2);
                _d.pushFundsToKeepGroup(split);
                _d.enableWithdrawal(initiator, remainingUnallocated.sub(split));
            }
        }
    }

    /// @notice     Notify the contract that the signers are undercollateralized.
    /// @dev        Calls out to the system for oracle info.
    /// @param  _d  Deposit storage pointer.
    function notifyCourtesyCall(DepositUtils.Deposit storage _d) external {
        require(_d.inActive(), "Can only courtesy call from active state");
        require(
            collateralizationPercentage(_d) <
                _d.undercollateralizedThresholdPercent,
            "Signers have sufficient collateral"
        );
        _d.courtesyCallInitiated = block.timestamp;
        _d.setCourtesyCall();
        _d.logCourtesyCalled();
    }

    /// @notice     Goes from courtesy call to active.
    /// @dev        Only callable if collateral is sufficient and the deposit is not expiring.
    /// @param  _d  Deposit storage pointer.
    function exitCourtesyCall(DepositUtils.Deposit storage _d) external {
        require(_d.inCourtesyCall(), "Not currently in courtesy call");
        require(
            collateralizationPercentage(_d) >=
                _d.undercollateralizedThresholdPercent,
            "Deposit is still undercollateralized"
        );
        _d.setActive();
        _d.logExitedCourtesyCall();
    }

    /// @notice     Notify the contract that the signers are undercollateralized.
    /// @dev        Calls out to the system for oracle info.
    /// @param  _d  Deposit storage pointer.
    function notifyUndercollateralizedLiquidation(
        DepositUtils.Deposit storage _d
    ) external {
        require(
            _d.inRedeemableState(),
            "Deposit not in active or courtesy call"
        );
        require(
            collateralizationPercentage(_d) <
                _d.severelyUndercollateralizedThresholdPercent,
            "Deposit has sufficient collateral"
        );
        startLiquidation(_d, false);
    }

    /// @notice     Notifies the contract that the courtesy period has elapsed.
    /// @dev        This is treated as an abort, rather than fraud.
    /// @param  _d  Deposit storage pointer.
    function notifyCourtesyCallExpired(DepositUtils.Deposit storage _d)
        external
    {
        require(_d.inCourtesyCall(), "Not in a courtesy call period");
        require(
            block.timestamp >=
                _d.courtesyCallInitiated.add(
                    TBTCConstants.getCourtesyCallTimeout()
                ),
            "Courtesy period has not elapsed"
        );
        startLiquidation(_d, false);
    }
}

pragma solidity 0.5.17;

import {BytesLib} from "@summa-tx/bitcoin-spv-sol/contracts/BytesLib.sol";
import {BTCUtils} from "@summa-tx/bitcoin-spv-sol/contracts/BTCUtils.sol";
import {
    IBondedECDSAKeep
} from "@keep-network/keep-ecdsa/contracts/api/IBondedECDSAKeep.sol";
import {SafeMath} from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import {TBTCToken} from "../system/TBTCToken.sol";
import {DepositUtils} from "./DepositUtils.sol";
import {DepositLiquidation} from "./DepositLiquidation.sol";
import {DepositStates} from "./DepositStates.sol";
import {OutsourceDepositLogging} from "./OutsourceDepositLogging.sol";
import {TBTCConstants} from "../system/TBTCConstants.sol";

library DepositFunding {
    using SafeMath for uint256;
    using SafeMath for uint64;
    using BTCUtils for bytes;
    using BytesLib for bytes;

    using DepositUtils for DepositUtils.Deposit;
    using DepositStates for DepositUtils.Deposit;
    using DepositLiquidation for DepositUtils.Deposit;
    using OutsourceDepositLogging for DepositUtils.Deposit;

    /// @notice     Deletes state after funding.
    /// @dev        This is called when we go to ACTIVE or setup fails without fraud.
    function fundingTeardown(DepositUtils.Deposit storage _d) internal {
        _d.signingGroupRequestedAt = 0;
        _d.fundingProofTimerStart = 0;
    }

    /// @notice     Deletes state after the funding ECDSA fraud process.
    /// @dev        This is only called as we transition to setup failed.
    function fundingFraudTeardown(DepositUtils.Deposit storage _d) internal {
        _d.keepAddress = address(0);
        _d.signingGroupRequestedAt = 0;
        _d.fundingProofTimerStart = 0;
        _d.signingGroupPubkeyX = bytes32(0);
        _d.signingGroupPubkeyY = bytes32(0);
    }

    /// @notice Internally called function to set up a newly created Deposit
    ///         instance. This should not be called by developers, use
    ///         `DepositFactory.createDeposit` to create a new deposit.
    /// @dev If called directly, the transaction will revert since the call will
    ///      be executed on an already set-up instance.
    /// @param _d Deposit storage pointer.
    /// @param _lotSizeSatoshis Lot size in satoshis.
    function initialize(
        DepositUtils.Deposit storage _d,
        uint64 _lotSizeSatoshis
    ) public {
        require(
            _d.tbtcSystem.getAllowNewDeposits(),
            "New deposits aren't allowed."
        );
        require(_d.inStart(), "Deposit setup already requested");

        _d.lotSizeSatoshis = _lotSizeSatoshis;

        _d.keepSetupFee = _d.tbtcSystem.getNewDepositFeeEstimate();

        // Note: this is a library, and library functions cannot be marked as
        // payable. Thus, we disable Solium's check that msg.value can only be
        // used in a payable function---this restriction actually applies to the
        // caller of this `initialize` function, Deposit.initializeDeposit.
        /* solium-disable-next-line value-in-payable */
        _d.keepAddress = _d.tbtcSystem.requestNewKeep.value(msg.value)(
            _lotSizeSatoshis,
            TBTCConstants.getDepositTerm()
        );

        require(
            _d.fetchBondAmount() >= _d.keepSetupFee,
            "Insufficient signer bonds to cover setup fee"
        );

        _d.signerFeeDivisor = _d.tbtcSystem.getSignerFeeDivisor();
        _d.undercollateralizedThresholdPercent = _d
            .tbtcSystem
            .getUndercollateralizedThresholdPercent();
        _d.severelyUndercollateralizedThresholdPercent = _d
            .tbtcSystem
            .getSeverelyUndercollateralizedThresholdPercent();
        _d.initialCollateralizedPercent = _d
            .tbtcSystem
            .getInitialCollateralizedPercent();
        _d.signingGroupRequestedAt = block.timestamp;

        _d.setAwaitingSignerSetup();
        _d.logCreated(_d.keepAddress);
    }

    /// @notice     Anyone may notify the contract that signing group setup has timed out.
    /// @param  _d  Deposit storage pointer.
    function notifySignerSetupFailed(DepositUtils.Deposit storage _d) external {
        require(_d.inAwaitingSignerSetup(), "Not awaiting setup");
        require(
            block.timestamp >
                _d.signingGroupRequestedAt.add(
                    TBTCConstants.getSigningGroupFormationTimeout()
                ),
            "Signing group formation timeout not yet elapsed"
        );

        // refund the deposit owner the cost to create a new Deposit at the time the Deposit was opened.
        uint256 _seized = _d.seizeSignerBonds();

        if (_seized >= _d.keepSetupFee) {
            /* solium-disable-next-line security/no-send */
            _d.enableWithdrawal(_d.depositOwner(), _d.keepSetupFee);
            _d.pushFundsToKeepGroup(_seized.sub(_d.keepSetupFee));
        }

        _d.setFailedSetup();
        _d.logSetupFailed();

        fundingTeardown(_d);
    }

    /// @notice             we poll the Keep contract to retrieve our pubkey.
    /// @dev                We store the pubkey as 2 bytestrings, X and Y.
    /// @param  _d          Deposit storage pointer.
    /// @return             True if successful, otherwise revert.
    function retrieveSignerPubkey(DepositUtils.Deposit storage _d) public {
        require(
            _d.inAwaitingSignerSetup(),
            "Not currently awaiting signer setup"
        );

        bytes memory _publicKey =
            IBondedECDSAKeep(_d.keepAddress).getPublicKey();
        require(
            _publicKey.length == 64,
            "public key not set or not 64-bytes long"
        );

        _d.signingGroupPubkeyX = _publicKey.slice(0, 32).toBytes32();
        _d.signingGroupPubkeyY = _publicKey.slice(32, 32).toBytes32();
        require(
            _d.signingGroupPubkeyY != bytes32(0) &&
                _d.signingGroupPubkeyX != bytes32(0),
            "Keep returned bad pubkey"
        );
        _d.fundingProofTimerStart = block.timestamp;

        _d.setAwaitingBTCFundingProof();
        _d.logRegisteredPubkey(_d.signingGroupPubkeyX, _d.signingGroupPubkeyY);
    }

    /// @notice Anyone may notify the contract that the funder has failed to
    ///         prove that they have sent BTC in time.
    /// @dev This is considered a funder fault, and the funder's payment for
    ///      opening the deposit is not refunded. Reverts if the funding timeout
    ///      has not yet elapsed, or if the deposit is not currently awaiting
    ///      funding proof.
    /// @param _d Deposit storage pointer.
    function notifyFundingTimedOut(DepositUtils.Deposit storage _d) external {
        require(
            _d.inAwaitingBTCFundingProof(),
            "Funding timeout has not started"
        );
        require(
            block.timestamp >
                _d.fundingProofTimerStart.add(
                    TBTCConstants.getFundingTimeout()
                ),
            "Funding timeout has not elapsed."
        );
        _d.setFailedSetup();
        _d.logSetupFailed();

        _d.closeKeep();
        fundingTeardown(_d);
    }

    /// @notice Requests a funder abort for a failed-funding deposit; that is,
    ///         requests return of a sent UTXO to `_abortOutputScript`. This can
    ///         be used for example when a UTXO is sent that is the wrong size
    ///         for the lot. Must be called after setup fails for any reason,
    ///         and imposes no requirement or incentive on the signing group to
    ///         return the UTXO.
    /// @dev This is a self-admitted funder fault, and should only be callable
    ///      by the TDT holder.
    /// @param _d Deposit storage pointer.
    /// @param _abortOutputScript The output script the funder wishes to request
    ///        a return of their UTXO to.
    function requestFunderAbort(
        DepositUtils.Deposit storage _d,
        bytes memory _abortOutputScript
    ) public {
        // not external to allow bytes memory parameters
        require(_d.inFailedSetup(), "The deposit has not failed funding");

        _d.logFunderRequestedAbort(_abortOutputScript);
    }

    /// @notice                 Anyone can provide a signature that was not requested to prove fraud during funding.
    /// @dev                    Calls out to the keep to verify if there was fraud.
    /// @param  _d              Deposit storage pointer.
    /// @param  _v              Signature recovery value.
    /// @param  _r              Signature R value.
    /// @param  _s              Signature S value.
    /// @param _signedDigest    The digest signed by the signature vrs tuple.
    /// @param _preimage        The sha256 preimage of the digest.
    /// @return                 True if successful, otherwise revert.
    function provideFundingECDSAFraudProof(
        DepositUtils.Deposit storage _d,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes32 _signedDigest,
        bytes memory _preimage
    ) public {
        // not external to allow bytes memory parameters
        require(
            _d.inAwaitingBTCFundingProof(),
            "Signer fraud during funding flow only available while awaiting funding"
        );

        _d.submitSignatureFraud(_v, _r, _s, _signedDigest, _preimage);
        _d.logFraudDuringSetup();

        // Allow deposit owner to withdraw seized bonds after contract termination.
        uint256 _seized = _d.seizeSignerBonds();
        _d.enableWithdrawal(_d.depositOwner(), _seized);

        fundingFraudTeardown(_d);
        _d.setFailedSetup();
        _d.logSetupFailed();
    }

    /// @notice                     Anyone may notify the deposit of a funding proof to activate the deposit.
    ///                             This is the happy-path of the funding flow. It means that we have succeeded.
    /// @dev                        Takes a pre-parsed transaction and calculates values needed to verify funding.
    /// @param  _d                  Deposit storage pointer.
    /// @param _txVersion           Transaction version number (4-byte LE).
    /// @param _txInputVector       All transaction inputs prepended by the number of inputs encoded as a VarInt, max 0xFC(252) inputs.
    /// @param _txOutputVector      All transaction outputs prepended by the number of outputs encoded as a VarInt, max 0xFC(252) outputs.
    /// @param _txLocktime          Final 4 bytes of the transaction.
    /// @param _fundingOutputIndex  Index of funding output in _txOutputVector (0-indexed).
    /// @param _merkleProof         The merkle proof of transaction inclusion in a block.
    /// @param _txIndexInBlock      Transaction index in the block (0-indexed).
    /// @param _bitcoinHeaders      Single bytestring of 80-byte bitcoin headers, lowest height first.
    function provideBTCFundingProof(
        DepositUtils.Deposit storage _d,
        bytes4 _txVersion,
        bytes memory _txInputVector,
        bytes memory _txOutputVector,
        bytes4 _txLocktime,
        uint8 _fundingOutputIndex,
        bytes memory _merkleProof,
        uint256 _txIndexInBlock,
        bytes memory _bitcoinHeaders
    ) public {
        // not external to allow bytes memory parameters

        require(_d.inAwaitingBTCFundingProof(), "Not awaiting funding");

        bytes8 _valueBytes;
        bytes memory _utxoOutpoint;

        (_valueBytes, _utxoOutpoint) = _d.validateAndParseFundingSPVProof(
            _txVersion,
            _txInputVector,
            _txOutputVector,
            _txLocktime,
            _fundingOutputIndex,
            _merkleProof,
            _txIndexInBlock,
            _bitcoinHeaders
        );

        // Write down the UTXO info and set to active. Congratulations :)
        _d.utxoValueBytes = _valueBytes;
        _d.utxoOutpoint = _utxoOutpoint;
        _d.fundedAt = block.timestamp;

        bytes32 _txid =
            abi
                .encodePacked(
                _txVersion,
                _txInputVector,
                _txOutputVector,
                _txLocktime
            )
                .hash256();

        fundingTeardown(_d);
        _d.setActive();
        _d.logFunded(_txid);
    }
}

pragma solidity 0.5.17;

import {DepositLiquidation} from "./DepositLiquidation.sol";
import {DepositUtils} from "./DepositUtils.sol";
import {DepositFunding} from "./DepositFunding.sol";
import {DepositRedemption} from "./DepositRedemption.sol";
import {DepositStates} from "./DepositStates.sol";
import {ITBTCSystem} from "../interfaces/ITBTCSystem.sol";
import {
    IERC721
} from "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import {TBTCToken} from "../system/TBTCToken.sol";
import {FeeRebateToken} from "../system/FeeRebateToken.sol";

import "../system/DepositFactoryAuthority.sol";

// solium-disable function-order
// Below, a few functions must be public to allow bytes memory parameters, but
// their being so triggers errors because public functions should be grouped
// below external functions. Since these would be external if it were possible,
// we ignore the issue.

/// @title  tBTC Deposit
/// @notice This is the main contract for tBTC. It is the state machine that
///         (through various libraries) handles bitcoin funding, bitcoin-spv
///         proofs, redemption, liquidation, and fraud logic.
/// @dev This contract presents a public API that exposes the following
///      libraries:
///
///       - `DepositFunding`
///       - `DepositLiquidaton`
///       - `DepositRedemption`,
///       - `DepositStates`
///       - `DepositUtils`
///       - `OutsourceDepositLogging`
///       - `TBTCConstants`
///
///      Where these libraries require deposit state, this contract's state
///      variable `self` is used. `self` is a struct of type
///      `DepositUtils.Deposit` that contains all aspects of the deposit state
///      itself.
contract Deposit is DepositFactoryAuthority {
    using DepositRedemption for DepositUtils.Deposit;
    using DepositFunding for DepositUtils.Deposit;
    using DepositLiquidation for DepositUtils.Deposit;
    using DepositUtils for DepositUtils.Deposit;
    using DepositStates for DepositUtils.Deposit;

    DepositUtils.Deposit self;

    /// @dev Deposit should only be _constructed_ once. New deposits are created
    ///      using the `DepositFactory.createDeposit` method, and are clones of
    ///      the constructed deposit. The factory will set the initial values
    ///      for a new clone using `initializeDeposit`.
    constructor() public {
        // The constructed Deposit will never be used, so the deposit factory
        // address can be anything. Clones are updated as per above.
        initialize(address(0xdeadbeef));
    }

    /// @notice Deposits do not accept arbitrary ETH.
    function() external payable {
        require(
            msg.data.length == 0,
            "Deposit contract was called with unknown function selector."
        );
    }

    //----------------------------- METADATA LOOKUP ------------------------------//

    /// @notice Get this deposit's BTC lot size in satoshis.
    /// @return uint64 lot size in satoshis.
    function lotSizeSatoshis() external view returns (uint64) {
        return self.lotSizeSatoshis;
    }

    /// @notice Get this deposit's lot size in TBTC.
    /// @dev This is the same as lotSizeSatoshis(), but is multiplied to scale
    ///      to 18 decimal places.
    /// @return uint256 lot size in TBTC precision (max 18 decimal places).
    function lotSizeTbtc() external view returns (uint256) {
        return self.lotSizeTbtc();
    }

    /// @notice Get the signer fee for this deposit, in TBTC.
    /// @dev This is the one-time fee required by the signers to perform the
    ///      tasks needed to maintain a decentralized and trustless model for
    ///      tBTC. It is a percentage of the deposit's lot size.
    /// @return Fee amount in TBTC.
    function signerFeeTbtc() external view returns (uint256) {
        return self.signerFeeTbtc();
    }

    /// @notice Get the integer representing the current state.
    /// @dev We implement this because contracts don't handle foreign enums
    ///      well. See `DepositStates` for more info on states.
    /// @return The 0-indexed state from the DepositStates enum.
    function currentState() external view returns (uint256) {
        return uint256(self.currentState);
    }

    /// @notice Check if the Deposit is in ACTIVE state.
    /// @return True if state is ACTIVE, false otherwise.
    function inActive() external view returns (bool) {
        return self.inActive();
    }

    /// @notice Get the contract address of the BondedECDSAKeep associated with
    ///         this Deposit.
    /// @dev The keep contract address is saved on Deposit initialization.
    /// @return Address of the Keep contract.
    function keepAddress() external view returns (address) {
        return self.keepAddress;
    }

    /// @notice Retrieve the remaining term of the deposit in seconds.
    /// @dev The value accuracy is not guaranteed since block.timestmap can be
    ///      lightly manipulated by miners.
    /// @return The remaining term of the deposit in seconds. 0 if already at
    ///         term.
    function remainingTerm() external view returns (uint256) {
        return self.remainingTerm();
    }

    /// @notice Get the current collateralization level for this Deposit.
    /// @dev This value represents the percentage of the backing BTC value the
    ///      signers currently must hold as bond.
    /// @return The current collateralization level for this deposit.
    function collateralizationPercentage() external view returns (uint256) {
        return self.collateralizationPercentage();
    }

    /// @notice Get the initial collateralization level for this Deposit.
    /// @dev This value represents the percentage of the backing BTC value
    ///      the signers hold initially. It is set at creation time.
    /// @return The initial collateralization level for this deposit.
    function initialCollateralizedPercent() external view returns (uint16) {
        return self.initialCollateralizedPercent;
    }

    /// @notice Get the undercollateralization level for this Deposit.
    /// @dev This collateralization level is semi-critical. If the
    ///      collateralization level falls below this percentage the Deposit can
    ///      be courtesy-called by calling `notifyCourtesyCall`. This value
    ///      represents the percentage of the backing BTC value the signers must
    ///      hold as bond in order to not be undercollateralized. It is set at
    ///      creation time. Note that the value for new deposits in TBTCSystem
    ///      can be changed by governance, but the value for a particular
    ///      deposit is static once the deposit is created.
    /// @return The undercollateralized level for this deposit.
    function undercollateralizedThresholdPercent()
        external
        view
        returns (uint16)
    {
        return self.undercollateralizedThresholdPercent;
    }

    /// @notice Get the severe undercollateralization level for this Deposit.
    /// @dev This collateralization level is critical. If the collateralization
    ///      level falls below this percentage the Deposit can get liquidated.
    ///      This value represents the percentage of the backing BTC value the
    ///      signers must hold as bond in order to not be severely
    ///      undercollateralized. It is set at creation time. Note that the
    ///      value for new deposits in TBTCSystem can be changed by governance,
    ///      but the value for a particular deposit is static once the deposit
    ///      is created.
    /// @return The severely undercollateralized level for this deposit.
    function severelyUndercollateralizedThresholdPercent()
        external
        view
        returns (uint16)
    {
        return self.severelyUndercollateralizedThresholdPercent;
    }

    /// @notice Get the value of the funding UTXO.
    /// @dev This call will revert if the deposit is not in a state where the
    ///      UTXO info should be valid. In particular, before funding proof is
    ///      successfully submitted (i.e. in states START,
    ///      AWAITING_SIGNER_SETUP, and AWAITING_BTC_FUNDING_PROOF), this value
    ///      would not be valid.
    /// @return The value of the funding UTXO in satoshis.
    function utxoValue() external view returns (uint256) {
        require(
            !self.inFunding(),
            "Deposit has not yet been funded and has no available funding info"
        );

        return self.utxoValue();
    }

    /// @notice Returns information associated with the funding UXTO.
    /// @dev This call will revert if the deposit is not in a state where the
    ///      funding info should be valid. In particular, before funding proof
    ///      is successfully submitted (i.e. in states START,
    ///      AWAITING_SIGNER_SETUP, and AWAITING_BTC_FUNDING_PROOF), none of
    ///      these values are set or valid.
    /// @return A tuple of (uxtoValueBytes, fundedAt, uxtoOutpoint).
    function fundingInfo()
        external
        view
        returns (
            bytes8 utxoValueBytes,
            uint256 fundedAt,
            bytes memory utxoOutpoint
        )
    {
        require(
            !self.inFunding(),
            "Deposit has not yet been funded and has no available funding info"
        );

        return (self.utxoValueBytes, self.fundedAt, self.utxoOutpoint);
    }

    /// @notice Calculates the amount of value at auction right now.
    /// @dev This call will revert if the deposit is not in a state where an
    ///      auction is currently in progress.
    /// @return The value in wei that would be received in exchange for the
    ///         deposit's lot size in TBTC if `purchaseSignerBondsAtAuction`
    ///         were called at the time this function is called.
    function auctionValue() external view returns (uint256) {
        require(
            self.inSignerLiquidation(),
            "Deposit has no funds currently at auction"
        );

        return self.auctionValue();
    }

    /// @notice Get caller's ETH withdraw allowance.
    /// @dev Generally ETH is only available to withdraw after the deposit
    ///      reaches a closed state. The amount reported is for the sender, and
    ///      can be withdrawn using `withdrawFunds` if the deposit is in an end
    ///      state.
    /// @return The withdraw allowance in wei.
    function withdrawableAmount() external view returns (uint256) {
        return self.getWithdrawableAmount();
    }

    //------------------------------ FUNDING FLOW --------------------------------//

    /// @notice Notify the contract that signing group setup has timed out if
    ///         retrieveSignerPubkey is not successfully called within the
    ///         allotted time.
    /// @dev This is considered a signer fault, and the signers' bonds are used
    ///      to make the deposit setup fee available for withdrawal by the TDT
    ///      holder as a refund. The remainder of the signers' bonds are
    ///      returned to the bonding pool and the signers are released from any
    ///      further responsibilities. Reverts if the deposit is not awaiting
    ///      signer setup or if the signing group formation timeout has not
    ///      elapsed.
    function notifySignerSetupFailed() external {
        self.notifySignerSetupFailed();
    }

    /// @notice Notify the contract that the ECDSA keep has generated a public
    ///         key so the deposit contract can pull it in.
    /// @dev Stores the pubkey as 2 bytestrings, X and Y. Emits a
    ///      RegisteredPubkey event with the two components. Reverts if the
    ///      deposit is not awaiting signer setup, if the generated public key
    ///      is unset or has incorrect length, or if the public key has a 0
    ///      X or Y value.
    function retrieveSignerPubkey() external {
        self.retrieveSignerPubkey();
    }

    /// @notice Notify the contract that the funding phase of the deposit has
    ///         timed out if `provideBTCFundingProof` is not successfully called
    ///         within the allotted time. Any sent BTC is left under control of
    ///         the signer group, and the funder can use `requestFunderAbort` to
    ///         request an at-signer-discretion return of any BTC sent to a
    ///         deposit that has been notified of a funding timeout.
    /// @dev This is considered a funder fault, and the funder's payment for
    ///      opening the deposit is not refunded. Emits a SetupFailed event.
    ///      Reverts if the funding timeout has not yet elapsed, or if the
    ///      deposit is not currently awaiting funding proof.
    function notifyFundingTimedOut() external {
        self.notifyFundingTimedOut();
    }

    /// @notice Requests a funder abort for a failed-funding deposit; that is,
    ///         requests the return of a sent UTXO to _abortOutputScript. It
    ///         imposes no requirements on the signing group. Signers should
    ///         send their UTXO to the requested output script, but do so at
    ///         their discretion and with no penalty for failing to do so. This
    ///         can be used for example when a UTXO is sent that is the wrong
    ///         size for the lot.
    /// @dev This is a self-admitted funder fault, and is only be callable by
    ///      the TDT holder. This function emits the FunderAbortRequested event,
    ///      but stores no additional state.
    /// @param _abortOutputScript The output script the funder wishes to request
    ///        a return of their UTXO to.
    function requestFunderAbort(bytes memory _abortOutputScript) public {
        // not external to allow bytes memory parameters
        require(
            self.depositOwner() == msg.sender,
            "Only TDT holder can request funder abort"
        );

        self.requestFunderAbort(_abortOutputScript);
    }

    /// @notice Anyone can provide a signature corresponding to the signers'
    ///         public key to prove fraud during funding. Note that during
    ///         funding no signature has been requested from the signers, so
    ///         any signature is effectively fraud.
    /// @dev Calls out to the keep to verify if there was fraud.
    /// @param _v Signature recovery value.
    /// @param _r Signature R value.
    /// @param _s Signature S value.
    /// @param _signedDigest The digest signed by the signature (v,r,s) tuple.
    /// @param _preimage The sha256 preimage of the digest.
    function provideFundingECDSAFraudProof(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes32 _signedDigest,
        bytes memory _preimage
    ) public {
        // not external to allow bytes memory parameters
        self.provideFundingECDSAFraudProof(
            _v,
            _r,
            _s,
            _signedDigest,
            _preimage
        );
    }

    /// @notice Anyone may submit a funding proof to the deposit showing that
    ///         a transaction was submitted and sufficiently confirmed on the
    ///         Bitcoin chain transferring the deposit lot size's amount of BTC
    ///         to the signer-controlled private key corresopnding to this
    ///         deposit. This will move the deposit into an active state.
    /// @dev Takes a pre-parsed transaction and calculates values needed to
    ///      verify funding.
    /// @param _txVersion Transaction version number (4-byte little-endian).
    /// @param _txInputVector All transaction inputs prepended by the number of
    ///        inputs encoded as a VarInt, max 0xFC(252) inputs.
    /// @param _txOutputVector All transaction outputs prepended by the number
    ///         of outputs encoded as a VarInt, max 0xFC(252) outputs.
    /// @param _txLocktime Final 4 bytes of the transaction.
    /// @param _fundingOutputIndex Index of funding output in _txOutputVector
    ///        (0-indexed).
    /// @param _merkleProof The merkle proof of transaction inclusion in a
    ///        block.
    /// @param _txIndexInBlock Transaction index in the block (0-indexed).
    /// @param _bitcoinHeaders Single bytestring of 80-byte bitcoin headers,
    ///        lowest height first.
    function provideBTCFundingProof(
        bytes4 _txVersion,
        bytes memory _txInputVector,
        bytes memory _txOutputVector,
        bytes4 _txLocktime,
        uint8 _fundingOutputIndex,
        bytes memory _merkleProof,
        uint256 _txIndexInBlock,
        bytes memory _bitcoinHeaders
    ) public {
        // not external to allow bytes memory parameters
        self.provideBTCFundingProof(
            _txVersion,
            _txInputVector,
            _txOutputVector,
            _txLocktime,
            _fundingOutputIndex,
            _merkleProof,
            _txIndexInBlock,
            _bitcoinHeaders
        );
    }

    //---------------------------- LIQUIDATION FLOW ------------------------------//

    /// @notice Notify the contract that the signers are undercollateralized.
    /// @dev This call will revert if the signers are not in fact
    ///      undercollateralized according to the price feed. After
    ///      TBTCConstants.COURTESY_CALL_DURATION, courtesy call times out and
    ///      regular abort liquidation occurs; see
    ///      `notifyCourtesyTimedOut`.
    function notifyCourtesyCall() external {
        self.notifyCourtesyCall();
    }

    /// @notice Notify the contract that the signers' bond value has recovered
    ///         enough to be considered sufficiently collateralized.
    /// @dev This call will revert if collateral is still below the
    ///      undercollateralized threshold according to the price feed.
    function exitCourtesyCall() external {
        self.exitCourtesyCall();
    }

    /// @notice Notify the contract that the courtesy period has expired and the
    ///         deposit should move into liquidation.
    /// @dev This call will revert if the courtesy call period has not in fact
    ///      expired or is not in the courtesy call state. Courtesy call
    ///      expiration is treated as an abort, and is handled by seizing signer
    ///      bonds and putting them up for auction for the lot size amount in
    ///      TBTC (see `purchaseSignerBondsAtAuction`). Emits a
    ///      LiquidationStarted event. The caller is captured as the liquidation
    ///      initiator, and is eligible for 50% of any bond left after the
    ///      auction is completed.
    function notifyCourtesyCallExpired() external {
        self.notifyCourtesyCallExpired();
    }

    /// @notice Notify the contract that the signers are undercollateralized.
    /// @dev Calls out to the system for oracle info.
    /// @dev This call will revert if the signers are not in fact severely
    ///      undercollateralized according to the price feed. Severe
    ///      undercollateralization is treated as an abort, and is handled by
    ///      seizing signer bonds and putting them up for auction in exchange
    ///      for the lot size amount in TBTC (see
    ///      `purchaseSignerBondsAtAuction`). Emits a LiquidationStarted event.
    ///      The caller is captured as the liquidation initiator, and is
    ///      eligible for 50% of any bond left after the auction is completed.
    function notifyUndercollateralizedLiquidation() external {
        self.notifyUndercollateralizedLiquidation();
    }

    /// @notice Anyone can provide a signature corresponding to the signers'
    ///         public key that was not requested to prove fraud. A redemption
    ///         request and a redemption fee increase are the only ways to
    ///         request a signature from the signers.
    /// @dev This call will revert if the underlying keep cannot verify that
    ///      there was fraud. Fraud is handled by seizing signer bonds and
    ///      putting them up for auction in exchange for the lot size amount in
    ///      TBTC (see `purchaseSignerBondsAtAuction`). Emits a
    ///      LiquidationStarted event. The caller is captured as the liquidation
    ///      initiator, and is eligible for any bond left after the auction is
    ///      completed.
    /// @param  _v Signature recovery value.
    /// @param  _r Signature R value.
    /// @param  _s Signature S value.
    /// @param _signedDigest The digest signed by the signature (v,r,s) tuple.
    /// @param _preimage The sha256 preimage of the digest.
    function provideECDSAFraudProof(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes32 _signedDigest,
        bytes memory _preimage
    ) public {
        // not external to allow bytes memory parameters
        self.provideECDSAFraudProof(_v, _r, _s, _signedDigest, _preimage);
    }

    /// @notice Notify the contract that the signers have failed to produce a
    ///         signature for a redemption request in the allotted time.
    /// @dev This is considered an abort, and is punished by seizing signer
    ///      bonds and putting them up for auction. Emits a LiquidationStarted
    ///      event and a Liquidated event and sends the full signer bond to the
    ///      redeemer. Reverts if the deposit is not currently awaiting a
    ///      signature or if the allotted time has not yet elapsed. The caller
    ///      is captured as the liquidation initiator, and is eligible for 50%
    ///      of any bond left after the auction is completed.
    function notifyRedemptionSignatureTimedOut() external {
        self.notifyRedemptionSignatureTimedOut();
    }

    /// @notice Notify the contract that the deposit has failed to receive a
    ///         redemption proof in the allotted time.
    /// @dev This call will revert if the deposit is not currently awaiting a
    ///      signature or if the allotted time has not yet elapsed. This is
    ///      considered an abort, and is punished by seizing signer bonds and
    ///      putting them up for auction for the lot size amount in TBTC (see
    ///      `purchaseSignerBondsAtAuction`). Emits a LiquidationStarted event.
    ///      The caller is captured as the liquidation initiator, and
    ///      is eligible for 50% of any bond left after the auction is
    ///     completed.
    function notifyRedemptionProofTimedOut() external {
        self.notifyRedemptionProofTimedOut();
    }

    /// @notice Closes an auction and purchases the signer bonds by transferring
    ///         the lot size in TBTC to the redeemer, if there is one, or to the
    ///         TDT holder if not. Any bond amount that is not currently up for
    ///         auction is either made available for the liquidation initiator
    ///         to withdraw (for fraud) or split 50-50 between the initiator and
    ///         the signers (for abort or collateralization issues).
    /// @dev The amount of ETH given for the transferred TBTC can be read using
    ///      the `auctionValue` function; note, however, that the function's
    ///      value is only static during the specific block it is queried, as it
    ///      varies by block timestamp.
    function purchaseSignerBondsAtAuction() external {
        self.purchaseSignerBondsAtAuction();
    }

    //---------------------------- REDEMPTION FLOW -------------------------------//

    /// @notice Get TBTC amount required for redemption by a specified
    ///         _redeemer.
    /// @dev This call will revert if redemption is not possible by _redeemer.
    /// @param _redeemer The deposit redeemer whose TBTC requirement is being
    ///        requested.
    /// @return The amount in TBTC needed by the `_redeemer` to redeem the
    ///         deposit.
    function getRedemptionTbtcRequirement(address _redeemer)
        external
        view
        returns (uint256)
    {
        (uint256 tbtcPayment, , ) =
            self.calculateRedemptionTbtcAmounts(_redeemer, false);
        return tbtcPayment;
    }

    /// @notice Get TBTC amount required for redemption assuming _redeemer
    ///         is this deposit's owner (TDT holder).
    /// @param _redeemer The assumed owner of the deposit's TDT .
    /// @return The amount in TBTC needed to redeem the deposit.
    function getOwnerRedemptionTbtcRequirement(address _redeemer)
        external
        view
        returns (uint256)
    {
        (uint256 tbtcPayment, , ) =
            self.calculateRedemptionTbtcAmounts(_redeemer, true);
        return tbtcPayment;
    }

    /// @notice Requests redemption of this deposit, meaning the transmission,
    ///         by the signers, of the deposit's UTXO to the specified Bitocin
    ///         output script. Requires approving the deposit to spend the
    ///         amount of TBTC needed to redeem.
    /// @dev The amount of TBTC needed to redeem can be looked up using the
    ///      `getRedemptionTbtcRequirement` or `getOwnerRedemptionTbtcRequirement`
    ///      functions.
    /// @param  _outputValueBytes The 8-byte little-endian output size. The
    ///         difference between this value and the lot size of the deposit
    ///         will be paid as a fee to the Bitcoin miners when the signed
    ///         transaction is broadcast.
    /// @param  _redeemerOutputScript The redeemer's length-prefixed output
    ///         script.
    function requestRedemption(
        bytes8 _outputValueBytes,
        bytes memory _redeemerOutputScript
    ) public {
        // not external to allow bytes memory parameters
        self.requestRedemption(_outputValueBytes, _redeemerOutputScript);
    }

    /// @notice Anyone may provide a withdrawal signature if it was requested.
    /// @dev The signers will be penalized if this function is not called
    ///      correctly within `TBTCConstants.REDEMPTION_SIGNATURE_TIMEOUT`
    ///      seconds of a redemption request or fee increase being received.
    /// @param _v Signature recovery value.
    /// @param _r Signature R value.
    /// @param _s Signature S value. Should be in the low half of secp256k1
    ///        curve's order.
    function provideRedemptionSignature(
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        self.provideRedemptionSignature(_v, _r, _s);
    }

    /// @notice Anyone may request a signature for a transaction with an
    ///         increased Bitcoin transaction fee.
    /// @dev This call will revert if the fee is already at its maximum, or if
    ///      the new requested fee is not a multiple of the initial requested
    ///      fee. Transaction fees can only be bumped by the amount of the
    ///      initial requested fee. Calling this sends the deposit back to
    ///      the `AWAITING_WITHDRAWAL_SIGNATURE` state and requires the signers
    ///      to `provideRedemptionSignature` for the new output value in a
    ///      timely fashion.
    /// @param _previousOutputValueBytes The previous output's value.
    /// @param _newOutputValueBytes The new output's value.
    function increaseRedemptionFee(
        bytes8 _previousOutputValueBytes,
        bytes8 _newOutputValueBytes
    ) external {
        self.increaseRedemptionFee(
            _previousOutputValueBytes,
            _newOutputValueBytes
        );
    }

    /// @notice Anyone may submit a redemption proof to the deposit showing that
    ///         a transaction was submitted and sufficiently confirmed on the
    ///         Bitcoin chain transferring the deposit lot size's amount of BTC
    ///         from the signer-controlled private key corresponding to this
    ///         deposit to the requested redemption output script. This will
    ///         move the deposit into a redeemed state.
    /// @dev Takes a pre-parsed transaction and calculates values needed to
    ///      verify funding. Signers can have their bonds seized if this is not
    ///      called within `TBTCConstants.REDEMPTION_PROOF_TIMEOUT` seconds of
    ///      a redemption signature being provided.
    /// @param _txVersion Transaction version number (4-byte little-endian).
    /// @param _txInputVector All transaction inputs prepended by the number of
    ///        inputs encoded as a VarInt, max 0xFC(252) inputs.
    /// @param _txOutputVector All transaction outputs prepended by the number
    ///         of outputs encoded as a VarInt, max 0xFC(252) outputs.
    /// @param _txLocktime Final 4 bytes of the transaction.
    /// @param _merkleProof The merkle proof of transaction inclusion in a
    ///        block.
    /// @param _txIndexInBlock Transaction index in the block (0-indexed).
    /// @param _bitcoinHeaders Single bytestring of 80-byte bitcoin headers,
    ///        lowest height first.
    function provideRedemptionProof(
        bytes4 _txVersion,
        bytes memory _txInputVector,
        bytes memory _txOutputVector,
        bytes4 _txLocktime,
        bytes memory _merkleProof,
        uint256 _txIndexInBlock,
        bytes memory _bitcoinHeaders
    ) public {
        // not external to allow bytes memory parameters
        self.provideRedemptionProof(
            _txVersion,
            _txInputVector,
            _txOutputVector,
            _txLocktime,
            _merkleProof,
            _txIndexInBlock,
            _bitcoinHeaders
        );
    }

    //--------------------------- MUTATING HELPERS -------------------------------//

    /// @notice This function can only be called by the deposit factory; use
    ///         `DepositFactory.createDeposit` to create a new deposit.
    /// @dev Initializes a new deposit clone with the base state for the
    ///      deposit.
    /// @param _tbtcSystem `TBTCSystem` contract. More info in `TBTCSystem`.
    /// @param _tbtcToken `TBTCToken` contract. More info in TBTCToken`.
    /// @param _tbtcDepositToken `TBTCDepositToken` (TDT) contract. More info in
    ///        `TBTCDepositToken`.
    /// @param _feeRebateToken `FeeRebateToken` (FRT) contract. More info in
    ///        `FeeRebateToken`.
    /// @param _vendingMachineAddress `VendingMachine` address. More info in
    ///        `VendingMachine`.
    /// @param _lotSizeSatoshis The minimum amount of satoshi the funder is
    ///                         required to send. This is also the amount of
    ///                         TBTC the TDT holder will be eligible to mint:
    ///                         (10**7 satoshi == 0.1 BTC == 0.1 TBTC).
    function initializeDeposit(
        ITBTCSystem _tbtcSystem,
        TBTCToken _tbtcToken,
        IERC721 _tbtcDepositToken,
        FeeRebateToken _feeRebateToken,
        address _vendingMachineAddress,
        uint64 _lotSizeSatoshis
    ) public payable onlyFactory {
        self.tbtcSystem = _tbtcSystem;
        self.tbtcToken = _tbtcToken;
        self.tbtcDepositToken = _tbtcDepositToken;
        self.feeRebateToken = _feeRebateToken;
        self.vendingMachineAddress = _vendingMachineAddress;
        self.initialize(_lotSizeSatoshis);
    }

    /// @notice This function can only be called by the vending machine.
    /// @dev Performs the same action as requestRedemption, but transfers
    ///      ownership of the deposit to the specified _finalRecipient. Used as
    ///      a utility helper for the vending machine's shortcut
    ///      TBTC->redemption path.
    /// @param  _outputValueBytes The 8-byte little-endian output size.
    /// @param  _redeemerOutputScript The redeemer's length-prefixed output script.
    /// @param  _finalRecipient     The address to receive the TDT and later be recorded as deposit redeemer.
    function transferAndRequestRedemption(
        bytes8 _outputValueBytes,
        bytes memory _redeemerOutputScript,
        address payable _finalRecipient
    ) public {
        // not external to allow bytes memory parameters
        require(
            msg.sender == self.vendingMachineAddress,
            "Only the vending machine can call transferAndRequestRedemption"
        );
        self.transferAndRequestRedemption(
            _outputValueBytes,
            _redeemerOutputScript,
            _finalRecipient
        );
    }

    /// @notice Withdraw the ETH balance of the deposit allotted to the caller.
    /// @dev Withdrawals can only happen when a contract is in an end-state.
    function withdrawFunds() external {
        self.withdrawFunds();
    }
}

pragma solidity 0.5.17;

import {TBTCDepositToken} from "./system/TBTCDepositToken.sol";


// solium-disable function-order
// Below, a few functions must be public to allow bytes memory parameters, but
// their being so triggers errors because public functions should be grouped
// below external functions. Since these would be external if it were possible,
// we ignore the issue.

contract DepositLog {
    /*
    Logging philosophy:
      Every state transition should fire a log
      That log should have ALL necessary info for off-chain actors
      Everyone should be able to ENTIRELY rely on log messages
    */

    // `TBTCDepositToken` mints a token for every new Deposit.
    // If a token exists for a given ID, we know it is a valid Deposit address.
    TBTCDepositToken tbtcDepositToken;

    // This event is fired when we init the deposit
    event Created(
        address indexed _depositContractAddress,
        address indexed _keepAddress,
        uint256 _timestamp
    );

    // This log event contains all info needed to rebuild the redemption tx
    // We index on request and signers and digest
    event RedemptionRequested(
        address indexed _depositContractAddress,
        address indexed _requester,
        bytes32 indexed _digest,
        uint256 _utxoValue,
        bytes _redeemerOutputScript,
        uint256 _requestedFee,
        bytes _outpoint
    );

    // This log event contains all info needed to build a witnes
    // We index the digest so that we can search events for the other log
    event GotRedemptionSignature(
        address indexed _depositContractAddress,
        bytes32 indexed _digest,
        bytes32 _r,
        bytes32 _s,
        uint256 _timestamp
    );

    // This log is fired when the signing group returns a public key
    event RegisteredPubkey(
        address indexed _depositContractAddress,
        bytes32 _signingGroupPubkeyX,
        bytes32 _signingGroupPubkeyY,
        uint256 _timestamp
    );

    // This event is fired when we enter the FAILED_SETUP state for any reason
    event SetupFailed(
        address indexed _depositContractAddress,
        uint256 _timestamp
    );

    // This event is fired when a funder requests funder abort after
    // FAILED_SETUP has been reached. Funder abort is a voluntary signer action
    // to return UTXO(s) that were sent to a signer-controlled wallet despite
    // the funding proofs having failed.
    event FunderAbortRequested(
        address indexed _depositContractAddress,
        bytes _abortOutputScript
    );

    // This event is fired when we detect an ECDSA fraud before seeing a funding proof
    event FraudDuringSetup(
        address indexed _depositContractAddress,
        uint256 _timestamp
    );

    // This event is fired when we enter the ACTIVE state
    event Funded(
        address indexed _depositContractAddress,
        bytes32 indexed _txid,
        uint256 _timestamp
    );

    // This event is called when we enter the COURTESY_CALL state
    event CourtesyCalled(
        address indexed _depositContractAddress,
        uint256 _timestamp
    );

    // This event is fired when we go from COURTESY_CALL to ACTIVE
    event ExitedCourtesyCall(
        address indexed _depositContractAddress,
        uint256 _timestamp
    );

    // This log event is fired when liquidation
    event StartedLiquidation(
        address indexed _depositContractAddress,
        bool _wasFraud,
        uint256 _timestamp
    );

    // This event is fired when the Redemption SPV proof is validated
    event Redeemed(
        address indexed _depositContractAddress,
        bytes32 indexed _txid,
        uint256 _timestamp
    );

    // This event is fired when Liquidation is completed
    event Liquidated(
        address indexed _depositContractAddress,
        uint256 _timestamp
    );

    //
    // Logging
    //

    /// @notice               Fires a Created event.
    /// @dev                  We append the sender, which is the deposit contract that called.
    /// @param  _keepAddress  The address of the associated keep.
    /// @return               True if successful, else revert.
    function logCreated(address _keepAddress) external {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit Created(msg.sender, _keepAddress, block.timestamp);
    }

    /// @notice                 Fires a RedemptionRequested event.
    /// @dev                    This is the only event without an explicit timestamp.
    /// @param  _requester      The ethereum address of the requester.
    /// @param  _digest         The calculated sighash digest.
    /// @param  _utxoValue       The size of the utxo in sat.
    /// @param  _redeemerOutputScript The redeemer's length-prefixed output script.
    /// @param  _requestedFee   The requester or bump-system specified fee.
    /// @param  _outpoint       The 36 byte outpoint.
    /// @return                 True if successful, else revert.
    function logRedemptionRequested(
        address _requester,
        bytes32 _digest,
        uint256 _utxoValue,
        bytes memory _redeemerOutputScript,
        uint256 _requestedFee,
        bytes memory _outpoint
    ) public {
        // not external to allow bytes memory parameters
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit RedemptionRequested(
            msg.sender,
            _requester,
            _digest,
            _utxoValue,
            _redeemerOutputScript,
            _requestedFee,
            _outpoint
        );
    }

    /// @notice         Fires a GotRedemptionSignature event.
    /// @dev            We append the sender, which is the deposit contract that called.
    /// @param  _digest signed digest.
    /// @param  _r      signature r value.
    /// @param  _s      signature s value.
    function logGotRedemptionSignature(bytes32 _digest, bytes32 _r, bytes32 _s)
        external
    {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit GotRedemptionSignature(
            msg.sender,
            _digest,
            _r,
            _s,
            block.timestamp
        );
    }

    /// @notice     Fires a RegisteredPubkey event.
    /// @dev        We append the sender, which is the deposit contract that called.
    function logRegisteredPubkey(
        bytes32 _signingGroupPubkeyX,
        bytes32 _signingGroupPubkeyY
    ) external {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit RegisteredPubkey(
            msg.sender,
            _signingGroupPubkeyX,
            _signingGroupPubkeyY,
            block.timestamp
        );
    }

    /// @notice     Fires a SetupFailed event.
    /// @dev        We append the sender, which is the deposit contract that called.
    function logSetupFailed() external {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit SetupFailed(msg.sender, block.timestamp);
    }

    /// @notice     Fires a FunderAbortRequested event.
    /// @dev        We append the sender, which is the deposit contract that called.
    function logFunderRequestedAbort(bytes memory _abortOutputScript) public {
        // not external to allow bytes memory parameters
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit FunderAbortRequested(msg.sender, _abortOutputScript);
    }

    /// @notice     Fires a FraudDuringSetup event.
    /// @dev        We append the sender, which is the deposit contract that called.
    function logFraudDuringSetup() external {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit FraudDuringSetup(msg.sender, block.timestamp);
    }

    /// @notice     Fires a Funded event.
    /// @dev        We append the sender, which is the deposit contract that called.
    function logFunded(bytes32 _txid) external {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit Funded(msg.sender, _txid, block.timestamp);
    }

    /// @notice     Fires a CourtesyCalled event.
    /// @dev        We append the sender, which is the deposit contract that called.
    function logCourtesyCalled() external {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit CourtesyCalled(msg.sender, block.timestamp);
    }

    /// @notice             Fires a StartedLiquidation event.
    /// @dev                We append the sender, which is the deposit contract that called.
    /// @param _wasFraud    True if liquidating for fraud.
    function logStartedLiquidation(bool _wasFraud) external {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit StartedLiquidation(msg.sender, _wasFraud, block.timestamp);
    }

    /// @notice     Fires a Redeemed event
    /// @dev        We append the sender, which is the deposit contract that called.
    function logRedeemed(bytes32 _txid) external {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit Redeemed(msg.sender, _txid, block.timestamp);
    }

    /// @notice     Fires a Liquidated event
    /// @dev        We append the sender, which is the deposit contract that called.
    function logLiquidated() external {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit Liquidated(msg.sender, block.timestamp);
    }

    /// @notice     Fires a ExitedCourtesyCall event
    /// @dev        We append the sender, which is the deposit contract that called.
    function logExitedCourtesyCall() external {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit ExitedCourtesyCall(msg.sender, block.timestamp);
    }

    /// @notice               Sets the tbtcDepositToken contract.
    /// @dev                  The contract is used by `approvedToLog` to check if the
    ///                       caller is a Deposit contract. This should only be called once.
    /// @param  _tbtcDepositTokenAddress  The address of the tbtcDepositToken.
    function setTbtcDepositToken(TBTCDepositToken _tbtcDepositTokenAddress)
        internal
    {
        require(
            address(tbtcDepositToken) == address(0),
            "tbtcDepositToken is already set"
        );
        tbtcDepositToken = _tbtcDepositTokenAddress;
    }

    //
    // AUTH
    //

    /// @notice             Checks if an address is an allowed logger.
    /// @dev                checks tbtcDepositToken to see if the caller represents
    ///                     an existing deposit.
    ///                     We don't require this, so deposits are not bricked if the system borks.
    /// @param  _caller     The address of the calling contract.
    /// @return             True if approved, otherwise false.
    function approvedToLog(address _caller) public view returns (bool) {
        return tbtcDepositToken.exists(uint256(_caller));
    }
}

