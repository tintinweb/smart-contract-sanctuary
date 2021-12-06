// SPDX-License-Identifier: LicenseRef-DSPL AND LicenseRef-NIGGER
pragma solidity 0.8.10;

import "./IMarebitsLockerAccount.sol";
import "./IMarebitsLockerToken.sol";
import "./IMarebitsVault.sol";
import "./IOwnershipTransferrable.sol";
import "./IRecoverable.sol";
import "../libraries/Account.sol";
import "../libraries/Token.sol";

/**
 * @title The interface for the Mare Bits Locker
 * @author Twifag
 */
interface IMarebitsLocker is IOwnershipTransferrable, IRecoverable {
	/**
	 * @notice Emitted when a token is locked or the lock on a token is extended
	 * @param accountId (also `tokenId`) representing the locked account
	 * @param owner contract address
	 * @param amount locked in locker
	 * @param tokenContract for the locked token
	 * @param tokenId of the locked token; should always be 0 for locked ERC20 tokens
	 * @param tokenType of token locked; see {Token.Type}
	 * @param unlockTime after which locked tokens can be withdrawn (in seconds after UNIX epoch)
	 */
	event TokensLocked(uint256 indexed accountId, address indexed owner, uint256 amount, address tokenContract, uint256 tokenId, Token.Type tokenType, uint64 unlockTime);

	/**
	 * @notice Emitted after a Mare Bits Locker Token is redeemed for its locked tokens
	 * @param accountId (also `tokenId`) representing the locked account
	 * @param owner contract address
	 * @param amount locked in locker
	 * @param tokenContract for the locked token
	 * @param tokenId of the locked token; should always be 0 for locked ERC20 tokens
	 * @param tokenType of token locked; see {Token.Type}
	 */
	event TokenRedeemed(uint256 indexed accountId, address indexed owner, uint256 amount, address tokenContract, uint256 tokenId, Token.Type tokenType);

	/**
	 * @notice Thrown when the required balance is less than the available balance
	 * @param required balance
	 * @param available balance
	 */
	error InsufficientBalance(uint256 required, uint256 available);

	/**
	 * @notice Thrown when an invalid amount is entered
	 * @param reason amount is invalid
	 */
	error InvalidAmount(string reason);

	/** @notice Thrown when called by an invalid caller (such as a contract) */
	error InvalidCaller();

	/**
	 * @notice Thrown when the given token type `tokenType` is not valid.  Must be 1 for ERC1155, 2 for ERC20, or 3 for ERC721
	 * @param tokenType of the token to check
	 */
	error InvalidTokenType(Token.Type tokenType);

	/** 
	 * @notice Thrown when attempting to redeem a token for an account that is still locked
	 * @param expiresAt time when the lock expires (in seconds since UNIX epoch)
	 * @param currentTime (in seconds since UNIX epoch)
	 */
	error LockedAccount(uint64 expiresAt, uint64 currentTime);

	/**
	 * @notice Thrown when someone attempts to interact with this contract who does not hodl $MARE.
	 * @param wallet the address with no $MARE
	 */
	error NeedsMoreMARE(address wallet);

	/**
	 * @notice Thrown when the account does not exist
	 * @param accountId of the account that does not exists
	 */
	error NonexistentAccount(uint256 accountId);

	/**
	 * @notice Thrown when attempting to transfer a token the caller does not own
	 * @param tokenId for the token that is attempting to be transferred
	 * @param claimedOwner of the token
	 * @param actualOwner of the token
	 */
	error NotTokenOwner(uint256 tokenId, address claimedOwner, address actualOwner);

	/**
	 * @notice Thrown when a passed time value is out of the stated bounds
	 * @param given time (in seconds since UNIX epoch)
	 * @param minimum time bound (in seconds since UNIX epoch)
	 * @param maximum time bound (in seconds since UNIX epoch)
	 */
	error TimeOutOfBounds(uint64 given, uint64 minimum, uint64 maximum);

	/**
	 * @notice Thrown when the caller has not approved the token transfer
	 * @param tokenAddress that was attempted to be transferred, the function `approvalFunction` should be called on this address
	 * @param approvalFunction that needs to be called to grant approval
	 */
	error UnapprovedTokenTransfer(address tokenAddress, string approvalFunction);

	/** @notice Thrown when a zero amount is passed */
	error ZeroAmountGiven();

	/**
	 * @notice Internally marks a token as having been burnt
	 * @dev Only callable by the {Ownable.owner} of this contract
	 * @param accountId representing the account being burned
	 */
	function __burn(uint256 accountId) external;

	/**
	 * @notice Extends the `unlockTime` for a given `accountId`
	 * @dev Emits a {TokensLocked} event
	 * @param accountId (also `tokenId`) representing the locked account
	 * @param unlockTime after which locked tokens can be withdrawn (in seconds after UNIX epoch, must be greater than existing `unlockTime` value)
	 * @return accountId for the locked tokens
	 */
	function extendLock(uint256 accountId, uint64 unlockTime) external returns (uint256);

	/**
	 * @notice Gets the account details for the account `accountId`
	 * @param accountId (also `tokenId`) representing the locked account
	 * @return Account.Info representing `accountId`; see {Account.Info}
	 */
	function getAccount(uint256 accountId) external view returns (Account.Info memory);

	/**
	 * @notice Locks tokens in a Mare Bits Locker and issues a redeemable Mare Bits Locker Token that can be used to unlock the tokens after the time `unlockTime` has passed
	 * @dev Emits a {TokensLocked} event
	 * @param tokenType of token to be locked; see {Token.Type}
	 * @param tokenContract for the token to be locked
	 * @param tokenId of the token to be locked; should always be 0 for locked ERC20 tokens
	 * @param amount of tokens to lock in locker
	 * @param unlockTime after which locked tokens can be withdrawn (in seconds after UNIX epoch)
	 * @return accountId for the locked tokens
	 */
	function lockTokens(Token.Type tokenType, address tokenContract, uint256 tokenId, uint256 amount, uint64 unlockTime) external returns (uint256);

	/**
	 * @notice Redeems (burns) a Mare Bits Locker Token and transfers all locked tokens back to the caller
	 * @dev Emits a {TokenRedeemed} event
	 * @param accountId (also `tokenId`) representing the locked account
	 */
	function redeemToken(uint256 accountId) external;
}

// SPDX-License-Identifier: LicenseRef-DSPL AND LicenseRef-NIGGER
pragma solidity 0.8.10;

import "../libraries/Account.sol";
import "../libraries/Token.sol";
import "./IRecoverable.sol";

/**
 * @title The interface for the Mare Bits Locker Account
 * @author Twifag
 */
interface IMarebitsLockerAccount is IRecoverable {
	/**
	 * @notice Thrown when the account does not exist
	 * @param accountId of the account that does not exists
	 */
	error NonexistentAccount(uint256 accountId);

	/**
	 * @notice Internally marks a token as having been burnt by setting the `isBurned` flag in the {IMarebitsLockerAccount.Account}
	 * @dev Only callable by the {Ownable.owner} of this contract
	 * @param accountId representing the account being burned
	 */
	function __burn(uint256 accountId) external;

	/**
	 * @notice Creates a new {IMarebitsLockerAccount.Account}
	 * @dev Only callable by the {Ownable.owner} of this contract
	 * @param accountId representing the new account
	 * @param amount of tokens to lock in locker
	 * @param tokenContract for the token to be locked
	 * @param tokenId of the token to be locked; should always be 0 for locked ERC20 tokens
	 * @param tokenType of token to be locked; see {Token.Type}
	 * @param unlockTime after which locked tokens can be withdrawn (in seconds after UNIX epoch)
	 */
	function __createAccount(uint256 accountId, uint256 amount, address tokenContract, uint256 tokenId, Token.Type tokenType, uint64 unlockTime) external;

	/**
	 * @notice Marks account `accountId` as redeemed by setting the `amount` to 0, `isRedeemed` to true, and the `unlockTime` to the current time
	 * @dev Only callable by the {Ownable.owner} of this contract
	 * @param accountId representing the account to redeem
	 */
	function __redeem(uint256 accountId) external;

	/**
	 * @notice Updates the amount of tokens locked in this account to `amount`; should only be called during a burn/redemption
	 * @dev Only callable by the {Ownable.owner} of this contract
	 * @param accountId representing the account
	 * @param amount new amount of tokens to be locked
	 */
	// function __setAmount(uint256 accountId, uint256 amount) external;

	/**
	 * @notice Updates the unlock time of tokens locked in this account to `unlockTime`; called by {IMarebitsLocker.extendLock}
	 * @dev Only callable by the {Ownable.owner} of this contract
	 * @param accountId representing the account
	 * @param unlockTime in seconds after UNIX epoch
	 */
	function __setUnlockTime(uint256 accountId, uint64 unlockTime) external;

	/**
	 *  @notice Gets the account details for the account `accountId`
	 *  @param accountId (also `tokenId`) representing the locked account
	 *  @return Account representing `accountId`; see {IMarebitsLockerAccount.Account}
	 */
	function getAccount(uint256 accountId) external view returns (Account.Info memory);

	/**
	 * @param accountId (also `tokenId`) representing the locked account
	 * @return uint256 amount of tokens locked in the account `accountId`
	 */
	// function getAmount(uint256 accountId) external view returns (uint256);

	/**
	 * @param accountId (also `tokenId`) representing the locked account
	 * @return address token contract address for the tokens locked in the account `accountId`
	 */
	// function getTokenContract(uint256 accountId) external view returns (address);

	/**
	 * @param accountId (also `tokenId`) representing the locked account
	 * @return Token.Type type of tokens locked in the account `accountId`; see {Token.Type}
	 */
	// function getTokenType(uint256 accountId) external view returns (Token.Type);

	/**
	 * @param accountId (also `tokenId`) representing the locked account
	 * @return uint256 token ID of the tokens locked in the account `accountId`
	 */
	// function getTokenId(uint256 accountId) external view returns (uint256);

	/**
	 * @param accountId (also `tokenId`) representing the locked account
	 * @return uint256 time after which tokens locked in the account `accountId` can be withdrawn (in seconds after UNIX epoch)
	 */
	// function getUnlockTime(uint256 accountId) external view returns (uint64);

	/**
	 * @param accountId (also `tokenId`) representing the locked account
	 * @return bool true if the account exists; otherwise, false
	 */
	// function hasAccount(uint256 accountId) external view returns (bool);

	/**
	 * @param accountId (also `tokenId`) representing the locked account
	 * @return bool true if the `unlockTime` has expired for the account `accountId`; otherwise, false
	 */
	// function isUnlocked(uint256 accountId) external view returns (bool);
}

// SPDX-License-Identifier: LicenseRef-DSPL AND LicenseRef-NIGGER
pragma solidity 0.8.10;

import "./IRecoverable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/**
 * @title The interface for the Mare Bits Locker Token
 * @author Twifag
 */
interface IMarebitsLockerToken is IERC721Metadata, IRecoverable {
	/**
	 * @notice Emitted when the URI of the token `id` has changed to `value`
	 * @param value of the new token URI
	 * @param id of the token
	 */
	event URI(string value, uint256 indexed id);

	/**
	 * @notice Thrown when attempting to transfer a token the caller does not own or is not approved to transfer
	 * @param tokenId for the token that is attempting to be transferred
	 */
	error NotApprovedOrOwner(uint256 tokenId);

	/**
	 * @notice Thrown when attempting to make a call that only the owner of this contract's owner can make
	 * @param claimedOwner of the token
	 * @param actualOwner of the token
	 */
	error NotLockerOwner(address claimedOwner, address actualOwner);

	/**
	 * @notice Burns the given token `tokenId`
	 * @dev Only callable by the {Ownable.owner} of this contract
	 * @param tokenId of the token to burn/destroy
	 */
	function __burn(uint256 tokenId) external;

	/**
	 * @dev Only callable by the {Ownable.owner} of this contract
	 * @param tokenId to check
	 * @return bool true if the token `tokenId` exists; otherwise, false
	 */
	function __exists(uint256 tokenId) external view returns (bool);

	/**
	 * @notice Gets the next token `tokenId` or `accountId`, incrementing the counter `_tokenIdTracker`
	 * @dev Only callable by the {Ownable.owner} of this contract
	 * @return tokenId of the next token ID
	 */
	function __getNextTokenId() external returns (uint256 tokenId);

	/**
	 * @notice Issues a new token to the address `owner` for the token `tokenId`
	 * @dev Only callable by the {Ownable.owner} of this contract
	 * @param owner of the newly issued token
	 * @param tokenId to be issued
	 */
	function __issueToken(address payable owner, uint256 tokenId) external;

	/**
	 * @notice Sets the `__baseURI`
	 * @dev Only callable by the {Ownable.owner} of this contract's owner
	 * @param baseURI that will be set as the new baseURI
	 */
	function __setBaseURI(string calldata baseURI) external;

	/**
	 * @notice Destroys token `tokenId`.  See {ERC721._burn}
	 * @dev Only callable by the {Ownable.owner} of the implementing contract
	 * @param tokenId of the token to burn/destroy
	 */
	function burn(uint256 tokenId) external;

	/**
	 * @notice Gets the image URI for token `tokenId`
	 * @param tokenId of the token for which you want the image URI
	 * @return imageUri string token image URI
	 */
	// function imageURI(uint256 tokenId) external view returns (string memory imageUri);

	/**
	 * @notice Returns the URI for the token ID `tokenId`
	 * @dev see {ERC1155.uri}
	 * @param tokenId of the token for which to retreive metadata
	 * @return string metadata for the token
	 */
	// function uri(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: LicenseRef-DSPL AND LicenseRef-NIGGER
pragma solidity 0.8.10;

import "../libraries/Token.sol";
import "./IRecoverableEther.sol";

/**
 * @title The interface for the Mare Bits Vault
 * @author Twifag
 */
interface IMarebitsVault is IRecoverableEther {
	/**
	 * @notice Transfers tokens out of this contract and to the original owner
	 * @dev Only callable by the {Ownable.owner} of this contract
	 * @param tokenType of token to be transferred; see {Token.Type}
	 * @param tokenContract for the token to be transferred
	 * @param to wallet address
	 * @param tokenId of the token to be transferred; should always be 0 for locked ERC20 tokens
	 * @param amount of tokens to be transferred
	 */
	function __transfer(Token.Type tokenType, address tokenContract, address payable to, uint256 tokenId, uint256 amount) external;
}

// SPDX-License-Identifier: LicenseRef-DSPL AND LicenseRef-NIGGER
pragma solidity 0.8.10;

import "./IOwnable.sol";

/**
 * @title Ownable abstract contract
 * @dev Represents the [ERC-173](https://eips.ethereum.org/EIPS/eip-173) specification (and a little more)
 */
interface IOwnershipTransferrable is IOwnable {
	/**
	 * @notice Leaves the contract without owner.  It will not be possible to call `onlyOwner` functions anymore.
	 * @dev Can only be called by the current owner.
	 */
	// function renounceOwnership() external;

	/**
	 * @notice Transfers ownership of the contract to a new account (`newAccount`).
	 * @dev Can only be called by the current owner.
	 * @param newOwner address of the new owner
	 */
	function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: LicenseRef-DSPL AND LicenseRef-NIGGER
pragma solidity 0.8.10;

import "./IRecoverableEther.sol";
import "./IRecoverableTokens.sol";

interface IRecoverable is IRecoverableEther, IRecoverableTokens {}

// SPDX-License-Identifier: LicenseRef-DSPL AND LicenseRef-NIGGER
pragma solidity 0.8.10;

import "./Token.sol";

/**
 * @title Account library grouping functions related to an account and the Account.Info struct
 * @author Twifag
 */
library Account {
	using Token for Token.Type;

	/**
	 * @dev Data representing an account or issued token
	 * @param accountId of the account; also, the `tokenId` of the Mare Bits Locker Token
	 * @param amount of tokens held
	 * @param tokenId of tokens held; should always be 0 for locked ERC20 tokens
	 * @param tokenContract of tokens held
	 * @param tokenType of tokens held; see {Token.Type}
	 * @param unlockTime after which held tokens can be withdrawn (in seconds after UNIX epoch)
	 * @param isBurned is true if the token representing this account has been burned; otherwise, false
	 * @param isRedeemed is true when token has been redeemed and account is closed; otherwise, false
	 */
	struct Info {
		uint256 accountId;
		uint256 amount;
		uint256 tokenId;
		address tokenContract;
		Token.Type tokenType;
		uint64 unlockTime;
		bool isBurned;
		bool isRedeemed;
	}

	/**
	 * @dev Internally marks a token as having been burnt by setting the `isBurned` flag
	 * @param self represents an {Account.Info}
	 */
	function burn(Info storage self) internal { self.isBurned = true; }

	/**
	 * @dev Creates a new {Account.Info} instance
	 * @param self a mapping(uint256 => Info) representing a collection of {Account.Info}s
	 * @param accountId representing the new account
	 * @param amount of tokens to lock in locker
	 * @param tokenContract for the token to be locked
	 * @param tokenId of the token to be locked; should always be 0 for locked ERC20 tokens
	 * @param tokenType of token to be locked; see {Token.Type}
	 * @param unlockTime after which locked tokens can be withdrawn (in seconds after UNIX epoch)
	 */
	function create(mapping(uint256 => Info) storage self, uint256 accountId, uint256 amount, address tokenContract, uint256 tokenId, Token.Type tokenType, uint64 unlockTime) internal {
		self[accountId] = Info({ accountId: accountId, amount: amount, tokenId: tokenId, tokenContract: tokenContract, tokenType: tokenType, unlockTime: unlockTime, isBurned: false, isRedeemed: false });
	}

	/**
	 * @dev Gets the account details for the account `accountId`
	 * @param self a mapping(uint256 => Info) representing a collection of {Account.Info}s
	 * @param accountId (also `tokenId`) representing the locked account
	 * @return Account.Info representing `accountId`; see {Account.Info}
	 */
	function get(mapping(uint256 => Info) storage self, uint256 accountId) internal view returns (Info storage) { return self[accountId]; }

	/**
	 * @param self represents an {Account.Info}
	 * @return bool true if the account is defined; otherwise, false
	 */
	function isDefined(Info storage self) internal view returns (bool) { return self.tokenType.isValid(); }

	/**
	 * @param self represents an {Account.Info}
	 * @return bool true if the account is unlocked; otherwise, false
	 */
	function isUnlocked(Info storage self) internal view returns (bool) { return uint256(self.unlockTime) <= block.timestamp; }

	/**
	 * @dev Marks account `self` as redeemed by setting the `amount` to 0, `isRedeemed` to true, and the `unlockTime` to the current time
	 * @param self represents an {Account.Info}
	 */
	function redeem(Info storage self) internal { (self.amount, self.isRedeemed, self.unlockTime) = (0, true, uint64(block.timestamp)); }

	/**
	 * @dev Updates the amount of tokens locked in this account to `amount`; should only be called during a burn/redemption
	 * @param self represents an {Account.Info}
	 * @param amount new amount of tokens to be locked
	 */
	function setAmount(Info storage self, uint256 amount) internal { self.amount = amount; }

	/**
	 * @dev Updates the unlock time of tokens locked in this account to `unlockTime`
	 * @param self represents an {Account.Info}
	 * @param unlockTime in seconds after UNIX epoch
	 */
	function setUnlockTime(Info storage self, uint64 unlockTime) internal { self.unlockTime = unlockTime; }
}

// SPDX-License-Identifier: LicenseRef-DSPL AND LicenseRef-NIGGER
pragma solidity 0.8.10;

library Token {
	/** @dev Enum for token types; 0 is UNDEFINED, 1 is ERC1155, 2 is ERC20, and 3 is ERC721 */
	enum Type { UNDEFINED, ERC1155, ERC20, ERC721 }

	/**
	 * @param self representing a {Token.Type}
	 * @return bool true if `self` represents a valid token; otherwise, false
	 */
	function isValid(Type self) internal pure returns (bool) { return self == Type.ERC1155 || self == Type.ERC20 || self == Type.ERC721; }

	/**
	 * @param self representing a {Token.Type}
	 * @return bytes9 name of the token type `self`
	 */
	function nameOf(Type self) internal pure returns (bytes9) {
		bytes9[4] memory names = [bytes9("UNDEFINED"), "ERC1155", "ERC20", "ERC721"];

		if (uint8(self) > names.length - 1) {
			self = Type.UNDEFINED;
		}
		return names[uint8(self)];
	}
}

// SPDX-License-Identifier: LicenseRef-DSPL AND LicenseRef-NIGGER
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title The abstract Recoverable Ether contract
 * @author Twifag
 */
interface IRecoverableEther is IERC165 {
	/** @notice Thrown when the send fails */
	error FailedSend();

	/**
	 * @notice Recovers ether accidentally sent to this contract
	 * @dev Only callable by the {Ownable.owner} of this contract
	 */
	function __recoverEther() external payable;
}

// SPDX-License-Identifier: LicenseRef-DSPL AND LicenseRef-NIGGER
pragma solidity 0.8.10;

import "../libraries/Token.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title The abstract Recoverable Tokens interface
 * @author Twifag
 */
interface IRecoverableTokens is IERC165 {
	/**
	 * @notice Recovers ERC20, ERC721, or ERC1155 tokens accidentally sent to this contract
	 * @dev Only callable by the {Ownable.owner} of this contract
	 * @param tokenType of token to recover; see {Token.Type}
	 * @param tokenContract address of the token to recover
	 * @param tokenId of the token to recover; should always be 0 for ERC20 tokens
	 */
	function __recoverTokens(Token.Type tokenType, address tokenContract, uint256 tokenId) external;
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

// SPDX-License-Identifier: LicenseRef-DSPL AND LicenseRef-NIGGER
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title Ownable abstract contract
 * @dev Closely (but not quite, see {TransferrableOwnership}) represents the [ERC-173](https://eips.ethereum.org/EIPS/eip-173) specification
 */
interface IOwnable is IERC165 {
	/// @notice This emits when ownership of a contract changes.
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/// @notice Thrown when called by any account other than the owner.
	error CallerIsNotOwner(address caller, address owner);

	/// @notice Get the address of the owner
	/// @return The address of the owner.
	function owner() view external returns(address);
}

// SPDX-License-Identifier: LicenseRef-DSPL AND LicenseRef-NIGGER
pragma solidity 0.8.10;

import "./interfaces/IMarebitsLocker.sol";
import "./interfaces/IMarebitsLockerToken.sol";
import "./interfaces/IOwnable.sol";
import "./KnowsBestPony.sol";
import "./Ownable.sol";
import "./Recoverable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title The implementation for the Mare Bits Locker Token
 * @author Twifag
 */
contract MarebitsLockerToken is Recoverable, ERC721Enumerable, KnowsBestPony, IMarebitsLockerToken {
	using Strings for uint256;

	/** @dev The base URI for computing the {ERC721#tokenURI}, roundabout way of overriding {ERC721#_baseURI} */
	string private __baseURI;

	/** @dev Optional mapping for image URIs */
	// mapping(uint256 => string) private _imageURIs;

	/** @dev uint256 to keep track of the tokens as they are created */
	uint256 private _tokenIdTracker;

	/** @dev Require that the caller is the same address as the owner of this contract's owner */
	modifier onlyLockerOwner() {
		address lockerOwner = IOwnable(owner()).owner();

		if (lockerOwner != _msgSender()) {
			revert NotLockerOwner(_msgSender(), lockerOwner);
		}
		_;
	}

	/**
	 * @param name of this token
	 * @param symbol of this token
	 * @param baseURI initially set for this token
	 */
	constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) { __baseURI = baseURI; }

	/// @inheritdoc IMarebitsLockerToken
	function __burn(uint256 tokenId) external onlyOwner { _burn(tokenId); }

	/// @inheritdoc IMarebitsLockerToken
	function __exists(uint256 tokenId) external view onlyOwner returns (bool) { return _exists(tokenId); }

	/// @inheritdoc IMarebitsLockerToken
	function __getNextTokenId() external onlyOwner returns (uint256 tokenId) { return _tokenIdTracker++; }

	/// @inheritdoc IMarebitsLockerToken
	function __issueToken(address payable owner, uint256 tokenId) external onlyOwner { _safeMint(owner, tokenId); }

	/// @inheritdoc IMarebitsLockerToken
	function __setBaseURI(string calldata baseURI) external onlyLockerOwner { __baseURI = baseURI; }

	/** @return string the `__baseURI` */
	function _baseURI() internal view override returns (string memory) { return __baseURI; }

	/** 
	 * @param path of the URI
	 * @param suffix of the URI
	 * @return string the generated URI by combining `__baseURI`, `path`, and `suffix` */
	function _generateURI(string memory path, string memory suffix) private view returns (string memory) { return string(abi.encodePacked(_baseURI(), path, suffix)); }

	/**
	 * @dev Marks the {IMarebitsLockerAccount.Account} as being burned and frees up storage, see {ERC721Enumerable}
	 * @inheritdoc ERC721
	 */
	function _burn(uint256 tokenId) internal override {
		IMarebitsLocker(owner()).__burn(tokenId);
		super._burn(tokenId);
	}

	/// @inheritdoc ERC721
	function _mint(address to, uint256 tokenId) internal override {
		emit URI(tokenURI(tokenId), tokenId);
		super._mint(to, tokenId);
	}

	/// @inheritdoc IMarebitsLockerToken
	function burn(uint256 tokenId) external {
		if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
			revert NotApprovedOrOwner(tokenId);
		}
		_burn(tokenId);
	}

	/// @inheritdoc IMarebitsLockerToken
	// function imageURI(uint256 tokenId) external view returns (string memory) {return _generateURI(tokenId.toString(), ".svg"); }

	/**
	* @dev Implementation of the {IERC165} interface.
	* @inheritdoc ERC165
	*/
	function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721Enumerable, Recoverable) returns (bool) {
		return interfaceId == type(IMarebitsLockerToken).interfaceId || 
			interfaceId == type(KnowsBestPony).interfaceId || 
			interfaceId == type(Recoverable).interfaceId || 
			interfaceId == type(IERC721Metadata).interfaceId || 
			ERC721Enumerable.supportsInterface(interfaceId) || 
			Recoverable.supportsInterface(interfaceId);
	}

	/// @inheritdoc ERC721
	function tokenURI(uint256 tokenId) public view override(ERC721, IERC721Metadata) returns (string memory tokenUri) { tokenUri = _generateURI(tokenId.toString(), ".json"); }

	/// @inheritdoc IMarebitsLockerToken
	// function uri(uint256 tokenId) external view returns (string memory) { return tokenURI(tokenId); }
}

// SPDX-License-Identifier: LicenseRef-DSPL AND LicenseRef-NIGGER
pragma solidity 0.8.10;

/**
 * @title The abstract Knows Best Pony contract
 * @author Twifag
 */
abstract contract KnowsBestPony {
	/** @return string the absolute best pony (hint: it's Twilight Sparkle) */
	function bestPony() public pure returns (string memory) { return "Twilight Sparkle is the cutest, smartest, all around best pony!"; }
}

// SPDX-License-Identifier: LicenseRef-DSPL AND LicenseRef-NIGGER
pragma solidity 0.8.10;

import "./interfaces/IOwnable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title Ownable abstract contract
 * @dev Closely (but not quite, see {TransferrableOwnership}) implements [ERC-173](https://eips.ethereum.org/EIPS/eip-173)
 */
abstract contract Ownable is Context, ERC165, IOwnable {
	address private _owner;

	/// @dev Initializes the contract setting the deployer as the initial owner.
	constructor() { _transferOwnership(_msgSender()); }

	/// @dev Throws if called by any account other than the owner.
	modifier onlyOwner() {
		if (owner() != _msgSender()) {
			revert CallerIsNotOwner(_msgSender(), owner());
		}
		_;
	}

	/// @dev Transfers ownership of the contract to a new account (`newOwner`)
	function _transferOwnership(address newOwner) internal virtual {
		address oldOwner = owner();
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, owner());
	}

	/// @inheritdoc IOwnable
	function owner() public view returns (address) { return _owner; }

	/**
	* @dev Implementation of the {IERC165} interface.
	* @inheritdoc ERC165
	*/
	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
		return interfaceId == type(IOwnable).interfaceId || 
			super.supportsInterface(interfaceId);
	}
}

// SPDX-License-Identifier: LicenseRef-DSPL AND LicenseRef-NIGGER
pragma solidity 0.8.10;

import "./RecoverableEther.sol";
import "./RecoverableTokens.sol";

abstract contract Recoverable is RecoverableEther, RecoverableTokens {
	/**
	* @dev Implementation of the {IERC165} interface.
	* @inheritdoc ERC165
	*/
	function supportsInterface(bytes4 interfaceId) public view virtual override(RecoverableEther, RecoverableTokens) returns (bool) {
		return RecoverableEther.supportsInterface(interfaceId) || 
			RecoverableTokens.supportsInterface(interfaceId);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

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

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: LicenseRef-DSPL AND LicenseRef-NIGGER
pragma solidity 0.8.10;

import "./interfaces/IRecoverableEther.sol";
import "./Ownable.sol";

/**
 * @title The abstract Recoverable Ether contract
 * @author Twifag
 */
abstract contract RecoverableEther is Ownable, IRecoverableEther {
	// @inheritdoc IRecoverableEther
	function __recoverEther() public virtual override payable onlyOwner {
		(bool success, ) = payable(owner()).call{value: address(this).balance}("");

		if (!success) {
			revert FailedSend();
		}
	}

	/**
	* @dev Implementation of the {IERC165} interface.
	* @inheritdoc ERC165
	*/
	function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, Ownable) returns (bool) {
		return interfaceId == type(IRecoverableEther).interfaceId || 
			super.supportsInterface(interfaceId);
	}
}

// SPDX-License-Identifier: LicenseRef-DSPL AND LicenseRef-NIGGER
pragma solidity 0.8.10;

import "./interfaces/IRecoverableTokens.sol";
import "./libraries/Token.sol";
import "./Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title The abstract Recoverable Tokens contract
 * @author Twifag
 */
abstract contract RecoverableTokens is Ownable, IRecoverableTokens {
	using SafeERC20 for IERC20;

	/**
	 * @dev Recovers ERC1155 tokens accidentally sent to this contract
	 * @param token to recover
	 * @param tokenId to recover
	 */
	function __recoverERC1155(IERC1155 token, uint256 tokenId) internal {
		uint256 balance = token.balanceOf(address(this), tokenId);
		token.safeTransferFrom(address(this), payable(owner()), tokenId, balance, "");
	}

	/**
	 * @dev Recovers ERC20 tokens accidentally sent to this contract
	 * @param token to recover
	 */
	function __recoverERC20(IERC20 token) internal {
		uint256 balance = token.balanceOf(address(this));
		token.safeTransfer(payable(owner()), balance);
	}

	/**
	 * @dev Recovers ERC721 tokens accidentally sent to this contract
	 * @param token to recover
	 * @param tokenId to recover
	 */
	function __recoverERC721(IERC721 token, uint256 tokenId) internal { token.safeTransferFrom(address(this), payable(owner()), tokenId); }

	/// @inheritdoc IRecoverableTokens
	function __recoverTokens(Token.Type tokenType, address tokenContract, uint256 tokenId) public virtual onlyOwner {
		if (tokenType == Token.Type.ERC1155) {
			__recoverERC1155(IERC1155(tokenContract), tokenId);
		} else if (tokenType == Token.Type.ERC20) {
			__recoverERC20(IERC20(tokenContract));
		} else if (tokenType == Token.Type.ERC721) {
			__recoverERC721(IERC721(tokenContract), tokenId);
		}
	}

	/**
	* @dev Implementation of the {IERC165} interface.
	* @inheritdoc ERC165
	*/
	function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, Ownable) returns (bool) {
		return interfaceId == type(IRecoverableTokens).interfaceId || 
			super.supportsInterface(interfaceId);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
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

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: LicenseRef-DSPL
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestERC721 is Ownable, ERC721 {
	constructor() ERC721("Test ERC721 Token", "TestERC721") {
		for (uint i = 0; i < 10; i++) {
			_safeMint(payable(owner()), i);
		}
	}
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

// SPDX-License-Identifier: LicenseRef-DSPL
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is Ownable, ERC20 {
	constructor() ERC20("Test ERC20 Token", "Test\\ERC<20") { _mint(payable(owner()), 1000 ether); }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: LicenseRef-DSPL AND LicenseRef-NIGGER
pragma solidity 0.8.10;

import "./interfaces/IOwnershipTransferrable.sol";
import "./Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

abstract contract OwnershipTransferrable is Ownable, IOwnershipTransferrable {
	/**
	* @dev Implementation of the {IERC165} interface.
	* @inheritdoc ERC165
	*/
	function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, Ownable) returns (bool) {
		return interfaceId == type(IOwnershipTransferrable).interfaceId || 
			super.supportsInterface(interfaceId);
	}

	/// @inheritdoc IOwnershipTransferrable
	function transferOwnership(address newOwner) public virtual onlyOwner { _transferOwnership(newOwner); }
}

// SPDX-License-Identifier: LicenseRef-DSPL AND LicenseRef-NIGGER
pragma solidity 0.8.10;

import "./interfaces/IMarebitsVault.sol";
import "./KnowsBestPony.sol";
import "./libraries/Token.sol";
import "./Ownable.sol";
import "./RecoverableEther.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title The implementation for the Mare Bits Vault
 * @author Twifag
 */
contract MarebitsVault is ERC1155Holder, ERC721Holder, KnowsBestPony, RecoverableEther, IMarebitsVault {
	using SafeERC20 for IERC20;

	/// @inheritdoc IMarebitsVault
	function __transfer(Token.Type tokenType, address tokenContract, address payable to, uint256 tokenId, uint256 amount) external onlyOwner {
		if (tokenType == Token.Type.ERC1155) {
			_transferERC1155(IERC1155(tokenContract), to, tokenId, amount);
		} else if (tokenType == Token.Type.ERC20) {
			_transferERC20(IERC20(tokenContract), to, amount);
		} else if (tokenType == Token.Type.ERC721) {
			_transferERC721(IERC721(tokenContract), to, tokenId);
		}
	}

	/**
	 * @dev Transfers ERC1155 tokens out of this contract and to the original owner
	 * @param token to be transferred
	 * @param to wallet address
	 * @param tokenId of the token to be transferred
	 * @param amount of tokens to be transferred
	 */
	function _transferERC1155(IERC1155 token, address payable to, uint256 tokenId, uint256 amount) private { token.safeTransferFrom(address(this), to, tokenId, amount, ""); }

	/**
	 * @dev Transfers ERC20 tokens out of this contract and to the original owner
	 * @param token to be transferred
	 * @param to wallet address
	 * @param amount of tokens to be transferred
	 */
	function _transferERC20(IERC20 token, address payable to, uint256 amount) private { token.safeTransfer(to, amount); }

	/**
	 * @dev Transfers ERC721 tokens out of this contract and to the original owner
	 * @param token to be transferred
	 * @param to wallet address
	 * @param tokenId of the token to be transferred
	 */
	function _transferERC721(IERC721 token, address payable to, uint256 tokenId) private { token.safeTransferFrom(address(this), to, tokenId); }

	/**
	* @dev Implementation of the {IERC165} interface.
	* @inheritdoc ERC165
	*/
	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Receiver, IERC165, RecoverableEther) returns (bool) {
		return interfaceId == type(IERC721Receiver).interfaceId || 
			interfaceId == type(KnowsBestPony).interfaceId || 
			interfaceId == type(RecoverableEther).interfaceId || 
			ERC1155Receiver.supportsInterface(interfaceId) || 
			RecoverableEther.supportsInterface(interfaceId);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: LicenseRef-DSPL AND LicenseRef-NIGGER
pragma solidity 0.8.10;

import "./interfaces/IMarebitsLocker.sol";
import "./interfaces/IMarebitsLockerAccount.sol";
import "./interfaces/IMarebitsLockerToken.sol";
import "./interfaces/IMarebitsVault.sol";
import "./interfaces/IRecoverableEther.sol";
import "./interfaces/IRecoverableTokens.sol";
import "./KnowsBestPony.sol";
import "./libraries/Account.sol";
import "./libraries/Token.sol";
import "./MarebitsLockerAccount.sol";
import "./MarebitsLockerToken.sol";
import "./MarebitsVault.sol";
import "./Recoverable.sol";
import "./OwnershipTransferrable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "marebits/contracts/MareBits.sol";

/**
 * @title The implementation for the Mare Bits Locker
 * @author Twifag
 */
contract MarebitsLocker is OwnershipTransferrable, Recoverable, KnowsBestPony, ReentrancyGuard, IMarebitsLocker {
	using SafeERC20 for IERC20;
	using Token for Token.Type;

	/** @dev the maximum value for time */
	uint64 private constant MAXIMUM_TIME = (2 << 63) - 1;

	/// @dev {IMarebitsLockerAccount} associated with this {IMarebitsLocker}
	IMarebitsLockerAccount public immutable accounts;

	/// @dev {IMarebitsLockerToken} associated with this {IMarebitsLocker}
	IMarebitsLockerToken public immutable lockerToken;

	/** @dev Address of the Mare Bits Token contract */
	MareBits private immutable mareBitsToken;

	/// @dev {IMarebitsVault} associated with this {IMarebitsLocker}
	IMarebitsVault public immutable vault;

	/**
	 * @dev Must pass a non-zero amount
	 * @param amount that must be greater than zero
	 */
	modifier nonZeroAmount(uint256 amount) {
		if (amount == 0) {
			revert ZeroAmountGiven();
		}
		_;
	}

	/** @dev Only humans can interact */
	modifier onlyHuman() {
		address account = _msgSender();
		uint256 size;

		assembly {
			size := extcodesize(account)
		}

		if (size > 0) {
			revert InvalidCaller();
		}
		_;
	}

	/** @dev Caller must have $MARE to interact with this locker */
	modifier mareHodlerOnly() {
		if (address(mareBitsToken) != address(0) && mareBitsToken.balanceOf(_msgSender()) == 0) {
			revert NeedsMoreMARE(_msgSender());
		}
		_;
	}

	/**
	 * @param name of the {MarebitsLockerToken}
	 * @param symbol of the {MarebitsLockerToken}
	 * @param baseURI initially set for the {MarebitsLockerToken}
	 */
	constructor(string memory name, string memory symbol, string memory baseURI, MareBits mareBitsToken_) {
		accounts = new MarebitsLockerAccount();
		lockerToken = new MarebitsLockerToken(name, symbol, baseURI);
		mareBitsToken = mareBitsToken_;
		vault = new MarebitsVault();
	}

	/** @notice In the case of child contracts somehow receiving ether, this lets us recover it from them.  Do not send ether to any of these contracts, please! */
	receive() external payable {}

	/// @inheritdoc IMarebitsLocker
	function __burn(uint256 accountId) external {
		if (_msgSender() != address(lockerToken)) {
			revert InvalidCaller();
		}
		accounts.__burn(accountId);
	}

	/**
	 * @notice Recovers ether accidentally sent to this contract or the contracts owned by this one ({MarebitsLockerAccount}, {MarebitsLockerToken}, and {MarebitsVault})
	 * @dev Only callable by the {Ownable.owner} of this contract
	 * @inheritdoc RecoverableEther
	 */
	function __recoverEther() public override(IRecoverableEther, RecoverableEther) payable onlyOwner {
		accounts.__recoverEther();
		lockerToken.__recoverEther();
		vault.__recoverEther();
		super.__recoverEther();
	}

	/**
	 * @notice Recovers ERC20, ERC721, or ERC1155 tokens accidentally sent to this contract or the non-vault contracts owned by this one ({MarebitsLockerAccount} and {MarebitsLockerToken})
	 * @dev Only callable by the {Ownable.owner} of this contract
	 * @inheritdoc RecoverableTokens
	 */
	function __recoverTokens(Token.Type tokenType, address tokenContract, uint256 tokenId) public override(IRecoverableTokens, RecoverableTokens) onlyOwner {
		accounts.__recoverTokens(tokenType, tokenContract, tokenId);
		lockerToken.__recoverTokens(tokenType, tokenContract, tokenId);
		super.__recoverTokens(tokenType, tokenContract, tokenId);
	}

	/**
	 * @dev Checks if an account exists and reverts if it does not
	 * @param accountId for account to check
	 */
	function _checkAccountExists(uint256 accountId) private view {
		if (!lockerToken.__exists(accountId)) {
			revert NonexistentAccount(accountId);
		}
	}

	/**
	 * @dev Checks if approval has been received to transfer a token and reverts if not
	 * @param isApproved is true when approval has been received; otherwise, false
	 * @param tokenAddress of the token for which approval is being requested to transfer
	 * @param approvalFunction that needs to be called in order to grant approval
	 */
	function _checkApproval(bool isApproved, address tokenAddress, string memory approvalFunction) private pure {
		if (!isApproved) {
			revert UnapprovedTokenTransfer(tokenAddress, approvalFunction);
		}
	}

	/**
	 * @dev Checks if the token is owned by the address `claimedOwner` and reverts if not
	 * @param tokenId of the token to check
	 * @param claimedOwner address that is claiming ownership of the token
	 * @param actualOwner address of the actual owner of the token
	 */
	function _checkOwner(uint256 tokenId, address claimedOwner, address actualOwner) private pure {
		if (claimedOwner != actualOwner) {
			revert NotTokenOwner(tokenId, claimedOwner, actualOwner);
		}
	}

	/**
	 * @dev Checks if there is sufficient balance and reverts if not
	 * @param required balance
	 * @param available balance
	 */
	function _checkSufficientBalance(uint256 required, uint256 available) private pure {
		if (required > available) {
			revert InsufficientBalance(required, available);
		}
	}

	/**
	 * @dev Checks if the time `given` falls within the bounds of `maximum` and `minimum` and reverts if not
	 * @param given time (in seconds since UNIX epoch)
	 * @param minimum time bound (in seconds since UNIX epoch)
	 * @param maximum time bound (in seconds since UNIX epoch)
	 */
	function _checkTimeBounds(uint64 given, uint64 minimum, uint64 maximum) private pure {
		if (given < minimum || given > maximum) {
			revert TimeOutOfBounds(given, minimum, maximum);
		}
	}

	/**
	 * @dev Checks if the given token type is valid and reverts if not
	 * @param tokenType to check
	 */
	function _checkTokenType(Token.Type tokenType) private pure {
		if (!tokenType.isValid()) {
			revert InvalidTokenType(tokenType);
		}
	}
	
	/**
	 * @dev Gets a new `accountId` and creates a new {MarebitsLockerAccount}
	 * @param amount of tokens to lock in locker
	 * @param tokenContract for the token to be locked
	 * @param tokenId of the token to be locked; should always be 0 for locked ERC20 tokens
	 * @param tokenType of token to be locked; see {Token.Type}
	 * @param unlockTime after which locked tokens can be withdrawn (in seconds after UNIX epoch)
	 * @return accountId for the newly created account
	 */
	function _createAccount(uint256 amount, address tokenContract, uint256 tokenId, Token.Type tokenType, uint64 unlockTime) private returns (uint256 accountId) {
		if (tokenType == Token.Type.ERC721 && amount > 1) {
			revert InvalidAmount("`amount` must be 1 for ERC721");
		}
		accountId = lockerToken.__getNextTokenId();
		accounts.__createAccount(accountId, amount, tokenContract, tokenId, tokenType, unlockTime);
	}

	/**
	 * @dev Issues a new token by calling {MarebitsLockerToken#__issueToken}
	 * @param accountId (also `tokenId`) representing the locked account
	 */
	function _issueToken(uint256 accountId) private { lockerToken.__issueToken(payable(_msgSender()), accountId); }

	/**
	 * @dev Locks ERC1155 tokens in a Mare Bits Locker and issues a redeemable Mare Bits Locker Token that can be used to unlock the tokens after the time `unlockTime` has passed
	 * @param token to be locked
	 * @param tokenId of the token to be locked
	 * @param amount of tokens to lock in locker
	 * @param unlockTime after which locked tokens can be withdrawn (in seconds after UNIX epoch)
	 * @return accountId (also `tokenId`) representing the locked account
	 */
	function _lockERC1155(IERC1155 token, uint256 tokenId, uint256 amount, uint64 unlockTime) private nonZeroAmount(amount) returns (uint256 accountId) {
		_checkSufficientBalance(amount, token.balanceOf(_msgSender(), tokenId));
		_checkApproval(token.isApprovedForAll(_msgSender(), address(this)), address(token), "setApprovalForAll()");
		accountId = _createAccount(amount, address(token), tokenId, Token.Type.ERC1155, unlockTime);
		token.safeTransferFrom(_msgSender(), payable(address(vault)), tokenId, amount, "");
		_issueToken(accountId);
		emit TokensLocked(accountId, _msgSender(), amount, address(token), tokenId, Token.Type.ERC1155, unlockTime);
	}

	/**
	 * @dev Locks ERC20 tokens in a Mare Bits Locker and issues a redeemable Mare Bits Locker Token that can be used to unlock the tokens after the time `unlockTime` has passed
	 * @param token to be locked
	 * @param amount of tokens to lock in locker
	 * @param unlockTime after which locked tokens can be withdrawn (in seconds after UNIX epoch)
	 * @return accountId (also `tokenId`) representing the locked account
	 */
	function _lockERC20(IERC20 token, uint256 amount, uint64 unlockTime) private nonZeroAmount(amount) returns (uint256 accountId) {
		_checkSufficientBalance(amount, token.balanceOf(_msgSender()));
		_checkApproval(token.allowance(_msgSender(), address(this)) >= amount, address(token), "approve()");
		accountId = _createAccount(amount, address(token), 0, Token.Type.ERC20, unlockTime);
		token.safeTransferFrom(_msgSender(), payable(address(vault)), amount);
		_issueToken(accountId);
		emit TokensLocked(accountId, _msgSender(), amount, address(token), 0, Token.Type.ERC20, unlockTime);
	}

	/**
	 * @dev Locks ERC721 tokens in a Mare Bits Locker and issues a redeemable Mare Bits Locker Token that can be used to unlock the tokens after the time `unlockTime` has passed
	 * @param token to be locked
	 * @param tokenId of the token to be locked
	 * @param unlockTime after which locked tokens can be withdrawn (in seconds after UNIX epoch)
	 * @return accountId (also `tokenId`) representing the locked account
	 */
	function _lockERC721(IERC721 token, uint256 tokenId, uint64 unlockTime) private returns (uint256 accountId) {
		_checkOwner(tokenId, _msgSender(), token.ownerOf(tokenId));
		_checkApproval(token.getApproved(tokenId) == address(this), address(token), "approve()");
		accountId = _createAccount(1, address(token), tokenId, Token.Type.ERC721, unlockTime);
		token.safeTransferFrom(_msgSender(), payable(address(vault)), tokenId);
		_issueToken(accountId);
		emit TokensLocked(accountId, _msgSender(), 1, address(token), tokenId, Token.Type.ERC721, unlockTime);
	}

	/// @inheritdoc IMarebitsLocker
	function extendLock(uint256 accountId, uint64 unlockTime) external nonReentrant onlyHuman mareHodlerOnly returns (uint256) {
		_checkAccountExists(accountId);
		_checkOwner(accountId, _msgSender(), lockerToken.ownerOf(accountId));
		Account.Info memory account = accounts.getAccount(accountId);
		_checkTimeBounds(unlockTime, account.unlockTime, MAXIMUM_TIME);
		accounts.__setUnlockTime(accountId, unlockTime);
		emit TokensLocked(accountId, _msgSender(), account.amount, account.tokenContract, account.tokenId, account.tokenType, unlockTime);
		return accountId;
	}

	/// @inheritdoc IMarebitsLocker
	function getAccount(uint256 accountId) external view returns (Account.Info memory) { return accounts.getAccount(accountId); }

	/// @inheritdoc IMarebitsLocker
	function lockTokens(Token.Type tokenType, address tokenContract, uint256 tokenId, uint256 amount, uint64 unlockTime) external nonReentrant onlyHuman mareHodlerOnly returns (uint256) {
		_checkTokenType(tokenType);
		_checkTimeBounds(unlockTime, uint64(block.timestamp), MAXIMUM_TIME);

		if (tokenType == Token.Type.ERC1155) {
			return _lockERC1155(IERC1155(tokenContract), tokenId, amount, unlockTime);
		} else if (tokenType == Token.Type.ERC20) {
			return _lockERC20(IERC20(tokenContract), amount, unlockTime);
		} else if (tokenType == Token.Type.ERC721) {
			return _lockERC721(IERC721(tokenContract), tokenId, unlockTime);
		} else {
			return 0;
		}
	}

	/// @inheritdoc IMarebitsLocker
	function redeemToken(uint256 accountId) external nonReentrant onlyHuman mareHodlerOnly {
		Account.Info memory account = accounts.getAccount(accountId);

		if (uint256(account.unlockTime) > block.timestamp) {
			revert LockedAccount(account.unlockTime, uint64(block.timestamp));
		}
		_checkAccountExists(accountId);
		_checkOwner(accountId, _msgSender(), lockerToken.ownerOf(accountId));
		_checkSufficientBalance(1, account.amount);
		accounts.__redeem(accountId);
		lockerToken.__burn(accountId);
		vault.__transfer(account.tokenType, account.tokenContract, payable(_msgSender()), account.tokenId, account.amount);
		emit TokenRedeemed(accountId, _msgSender(), account.amount, account.tokenContract, account.tokenId, account.tokenType);
	}

	/**
	* @dev Implementation of the {IERC165} interface.
	* @inheritdoc ERC165
	*/
	function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, OwnershipTransferrable, Recoverable) returns (bool) {
		return interfaceId == type(IMarebitsLocker).interfaceId || 
			interfaceId == type(KnowsBestPony).interfaceId || 
			OwnershipTransferrable.supportsInterface(interfaceId) || 
			Recoverable.supportsInterface(interfaceId);
	}
}

// SPDX-License-Identifier: LicenseRef-DSPL AND LicenseRef-NIGGER
pragma solidity 0.8.10;

import "./interfaces/IMarebitsLockerAccount.sol";
import "./libraries/Account.sol";
import "./libraries/Token.sol";
import "./KnowsBestPony.sol";
import "./Ownable.sol";
import "./Recoverable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title The implementation for the Mare Bits Locker Account
 * @author Twifag
 */
contract MarebitsLockerAccount is Recoverable, KnowsBestPony, IMarebitsLockerAccount {
	using Account for mapping(uint256 => Account.Info);
	using Account for Account.Info;

	/** @dev the maximum value for time (uint64) */
	uint64 private constant MAXIMUM_TIME = (2 << 63) - 1;

	/** @dev Stores all the accounts; `accountId` => {IMarebitsLockerAccount.Account} */
	mapping(uint256 => Account.Info) private _accounts;

	/**
	 * @dev The account must exist
	 * @param accountId (also `tokenId`) representing the locked account
	 */
	modifier accountExists(uint256 accountId) {
		if (!_accounts[accountId].isDefined()) {
			revert NonexistentAccount(accountId);
		}
		_;
	}

	/// @inheritdoc IMarebitsLockerAccount
	function __createAccount(uint256 accountId, uint256 amount, address tokenContract, uint256 tokenId, Token.Type tokenType, uint64 unlockTime) public onlyOwner {
		_accounts.create(accountId, amount, tokenContract, tokenId, tokenType, unlockTime);
	}

	/// @inheritdoc IMarebitsLockerAccount
	function __burn(uint256 accountId) external onlyOwner accountExists(accountId) { _accounts[accountId].burn(); }

	// /// @inheritdoc IMarebitsLockerAccount
	function __redeem(uint256 accountId) external onlyOwner accountExists(accountId) { _accounts[accountId].redeem(); }

	// /// @inheritdoc IMarebitsLockerAccount
	// function __setAmount(uint256 accountId, uint256 amount) external onlyOwner accountExists(accountId) { _accounts[accountId].setAmount(amount); }

	// /// @inheritdoc IMarebitsLockerAccount
	function __setUnlockTime(uint256 accountId, uint64 unlockTime) external onlyOwner accountExists(accountId) { _accounts[accountId].setUnlockTime(unlockTime); }

	/// @inheritdoc IMarebitsLockerAccount
	function getAccount(uint256 accountId) external view accountExists(accountId) returns (Account.Info memory) { return _accounts[accountId]; }

	// /// @inheritdoc IMarebitsLockerAccount
	// function getAmount(uint256 accountId) external view accountExists(accountId) returns (uint256) { return _accounts[accountId].amount; }

	// /// @inheritdoc IMarebitsLockerAccount
	// function getTokenContract(uint256 accountId) external view accountExists(accountId) returns (address) { return _accounts[accountId].tokenContract; }

	// /// @inheritdoc IMarebitsLockerAccount
	// function getTokenType(uint256 accountId) external view accountExists(accountId) returns (Token.Type) { return _accounts[accountId].tokenType; }

	// /// @inheritdoc IMarebitsLockerAccount
	// function getTokenId(uint256 accountId) external view accountExists(accountId) returns (uint256) { return _accounts[accountId].tokenId; }

	// /// @inheritdoc IMarebitsLockerAccount
	// function getUnlockTime(uint256 accountId) external view accountExists(accountId) returns (uint64) { return _accounts[accountId].unlockTime; }

	// /// @inheritdoc IMarebitsLockerAccount
	// function hasAccount(uint256 accountId) external view returns (bool) { return _accounts[accountId].isDefined(); }

	// /// @inheritdoc IMarebitsLockerAccount
	// function isUnlocked(uint256 accountId) external view accountExists(accountId) returns (bool) { return _accounts[accountId].isUnlocked(); }

	/**
	* @dev Implementation of the {IERC165} interface.
	* @inheritdoc ERC165
	*/
	function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, Recoverable) returns (bool) {
		return interfaceId == type(IMarebitsLockerAccount).interfaceId || 
			interfaceId == type(KnowsBestPony).interfaceId || 
			interfaceId == type(Recoverable).interfaceId || 
			super.supportsInterface(interfaceId);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract MareBits is OwnableUpgradeable, ERC20Upgradeable {
        function initialize(string memory name, string memory symbol, uint256 initialSupply, address owner) public virtual initializer {
                __MareBitsFixedSupply_init(name, symbol, initialSupply, owner);
        }

        function __MareBitsFixedSupply_init(string memory name, string memory symbol, uint256 initialSupply, address owner) internal initializer {
                __Context_init_unchained();
                __Ownable_init_unchained();
                __ERC20_init_unchained(name, symbol);
                __MareBits_init_unchained(name, symbol, initialSupply, owner);
        }

        function __MareBits_init_unchained(string memory name, string memory symbol, uint256 initialSupply, address owner) internal initializer {
                _mint(owner, initialSupply);
        }
        uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: LicenseRef-DSPL
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract TestERC1155 is Ownable, ERC1155 {
	constructor() ERC1155("https://mare.biz/test/") {
		for (uint i = 0; i < 10; i++) {
			_mint(payable(owner()), i + 1, 1, "");
		}
		_mint(payable(owner()), 0, 1000 ether, "");
	}
}

// SPDX-License-Identifier: LicenseRef-DSPL AND LicenseRef-NIGGER
pragma solidity 0.8.10;

/**
 * @title Bools library, overrides for the bool type
 * @author Twifan
 */
library Bools {
	/**
	 * @notice Converts a bool to a bytes5 value
	 * @param self the bool to convert
	 * @return bytes5 converted value of the bool
	 */
	function toBytes(bool self) internal pure returns (bytes5) { return self ? bytes5("true") : bytes5("false"); }

	/**
	 * @notice Converts a bool to a string value
	 * @param self the bool to convert
	 * @return string converted value of the bool
	 */
	function toString(bool self) internal pure returns (string memory) { return self ? "true" : "false"; }
}