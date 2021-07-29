/**
 *Submitted for verification at polygonscan.com on 2021-07-28
*/

// Sources flattened with hardhat v2.4.3 https://hardhat.org

// File @animoca/ethereum-contracts-core-1.1.1/contracts/utils/types/[email protected]

// SPDX-License-Identifier: MIT

// Partially derived from OpenZeppelin:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/406c83649bd6169fc1b578e08506d78f0873b276/contracts/utils/Address.sol

pragma solidity >=0.7.6 <0.8.0;

/**
 * @dev Upgrades the address type to check if it is a contract.
 */
library AddressIsContract {
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
}


// File @animoca/ethereum-contracts-core-1.1.1/contracts/utils/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC20Wrapper
 * Wraps ERC20 functions to support non-standard implementations which do not return a bool value.
 * Calls to the wrapped functions revert only if they throw or if they return false.
 */
library ERC20Wrapper {
    using AddressIsContract for address;

    function wrappedTransfer(
        IWrappedERC20 token,
        address to,
        uint256 value
    ) internal {
        _callWithOptionalReturnData(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function wrappedTransferFrom(
        IWrappedERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callWithOptionalReturnData(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function wrappedApprove(
        IWrappedERC20 token,
        address spender,
        uint256 value
    ) internal {
        _callWithOptionalReturnData(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function _callWithOptionalReturnData(IWrappedERC20 token, bytes memory callData) internal {
        address target = address(token);
        require(target.isContract(), "ERC20Wrapper: non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = target.call(callData);
        if (success) {
            if (data.length != 0) {
                require(abi.decode(data, (bool)), "ERC20Wrapper: operation failed");
            }
        } else {
            // revert using a standard revert message
            if (data.length == 0) {
                revert("ERC20Wrapper: operation failed");
            }

            // revert using the revert message coming from the call
            assembly {
                let size := mload(data)
                revert(add(32, data), size)
            }
        }
    }
}

interface IWrappedERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);
}


// File @animoca/ethereum-contracts-core-1.1.1/contracts/metatx/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/*
 * Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner.
 */
abstract contract ManagedIdentity {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}


// File @animoca/ethereum-contracts-core-1.1.1/contracts/access/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC-173 Contract Ownership Standard
 * Note: the ERC-165 identifier for this interface is 0x7f5828d0
 */
interface IERC173 {
    /**
     * Event emited when ownership of a contract changes.
     * @param previousOwner the previous owner.
     * @param newOwner the new owner.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * Get the address of the owner
     * @return The address of the owner.
     */
    function owner() external view returns (address);

    /**
     * Set the address of the new owner of the contract
     * Set newOwner to address(0) to renounce any ownership.
     * @dev Emits an {OwnershipTransferred} event.
     * @param newOwner The address of the new owner of the contract. Using the zero address means renouncing ownership.
     */
    function transferOwnership(address newOwner) external;
}


// File @animoca/ethereum-contracts-core-1.1.1/contracts/access/[email protected]

pragma solidity >=0.7.6 <0.8.0;


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
abstract contract Ownable is ManagedIdentity, IERC173 {
    address internal _owner;

    /**
     * Initializes the contract, setting the deployer as the initial owner.
     * @dev Emits an {IERC173-OwnershipTransferred(address,address)} event.
     */
    constructor(address owner_) {
        _owner = owner_;
        emit OwnershipTransferred(address(0), owner_);
    }

    /**
     * Gets the address of the current contract owner.
     */
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    /**
     * See {IERC173-transferOwnership(address)}
     * @dev Reverts if the sender is not the current contract owner.
     * @param newOwner the address of the new owner. Use the zero address to renounce the ownership.
     */
    function transferOwnership(address newOwner) public virtual override {
        _requireOwnership(_msgSender());
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

    /**
     * @dev Reverts if `account` is not the contract owner.
     * @param account the account to test.
     */
    function _requireOwnership(address account) internal virtual {
        require(account == this.owner(), "Ownable: not the owner");
    }
}


// File @animoca/ethereum-contracts-core-1.1.1/contracts/utils/[email protected]

pragma solidity >=0.7.6 <0.8.0;



abstract contract Recoverable is ManagedIdentity, Ownable {
    using ERC20Wrapper for IWrappedERC20;

    /**
     * Extract ERC20 tokens which were accidentally sent to the contract to a list of accounts.
     * Warning: this function should be overriden for contracts which are supposed to hold ERC20 tokens
     * so that the extraction is limited to only amounts sent accidentally.
     * @dev Reverts if the sender is not the contract owner.
     * @dev Reverts if `accounts`, `tokens` and `amounts` do not have the same length.
     * @dev Reverts if one of `tokens` is does not implement the ERC20 transfer function.
     * @dev Reverts if one of the ERC20 transfers fail for any reason.
     * @param accounts the list of accounts to transfer the tokens to.
     * @param tokens the list of ERC20 token addresses.
     * @param amounts the list of token amounts to transfer.
     */
    function recoverERC20s(
        address[] calldata accounts,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external virtual {
        _requireOwnership(_msgSender());
        uint256 length = accounts.length;
        require(length == tokens.length && length == amounts.length, "Recov: inconsistent arrays");
        for (uint256 i = 0; i != length; ++i) {
            IWrappedERC20(tokens[i]).wrappedTransfer(accounts[i], amounts[i]);
        }
    }

    /**
     * Extract ERC721 tokens which were accidentally sent to the contract to a list of accounts.
     * Warning: this function should be overriden for contracts which are supposed to hold ERC721 tokens
     * so that the extraction is limited to only tokens sent accidentally.
     * @dev Reverts if the sender is not the contract owner.
     * @dev Reverts if `accounts`, `contracts` and `amounts` do not have the same length.
     * @dev Reverts if one of `contracts` is does not implement the ERC721 transferFrom function.
     * @dev Reverts if one of the ERC721 transfers fail for any reason.
     * @param accounts the list of accounts to transfer the tokens to.
     * @param contracts the list of ERC721 contract addresses.
     * @param tokenIds the list of token ids to transfer.
     */
    function recoverERC721s(
        address[] calldata accounts,
        address[] calldata contracts,
        uint256[] calldata tokenIds
    ) external virtual {
        _requireOwnership(_msgSender());
        uint256 length = accounts.length;
        require(length == contracts.length && length == tokenIds.length, "Recov: inconsistent arrays");
        for (uint256 i = 0; i != length; ++i) {
            IRecoverableERC721(contracts[i]).transferFrom(address(this), accounts[i], tokenIds[i]);
        }
    }
}

interface IRecoverableERC721 {
    /// See {IERC721-transferFrom(address,address,uint256)}
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}


// File @animoca/ethereum-contracts-core-1.1.1/contracts/payment/[email protected]

pragma solidity >=0.7.6 <0.8.0;


/**
    @title PayoutWallet
    @dev adds support for a payout wallet
    Note: .
 */
abstract contract PayoutWallet is ManagedIdentity, Ownable {
    event PayoutWalletSet(address payoutWallet_);

    address payable public payoutWallet;

    constructor(address owner, address payable payoutWallet_) Ownable(owner) {
        require(payoutWallet_ != address(0), "Payout: zero address");
        payoutWallet = payoutWallet_;
        emit PayoutWalletSet(payoutWallet_);
    }

    function setPayoutWallet(address payable payoutWallet_) public {
        _requireOwnership(_msgSender());
        require(payoutWallet_ != address(0), "Payout: zero address");
        payoutWallet = payoutWallet_;
        emit PayoutWalletSet(payoutWallet);
    }
}


// File @animoca/ethereum-contracts-core-1.1.1/contracts/introspection/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165.
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


// File @animoca/ethereum-contracts-assets-1.1.3/contracts/token/ERC20/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC20 Token Standard, Receiver
 * See https://eips.ethereum.org/EIPS/eip-20
 * Note: the ERC-165 identifier for this interface is 0x4fc35859.
 */
interface IERC20Receiver {
    /**
     * Handles the receipt of ERC20 tokens.
     * @param sender The initiator of the transfer.
     * @param from The address which transferred the tokens.
     * @param value The amount of tokens transferred.
     * @param data Optional additional data with no specified format.
     * @return bytes4 `bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))`
     */
    function onERC20Received(
        address sender,
        address from,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
}


// File @animoca/ethereum-contracts-assets-1.1.3/contracts/token/ERC20/[email protected]

pragma solidity >=0.7.6 <0.8.0;


abstract contract ERC20Receiver is IERC20Receiver, IERC165 {
    bytes4 internal constant _ERC20_RECEIVED = type(IERC20Receiver).interfaceId;
    bytes4 internal constant _ERC20_REJECTED = 0xffffffff;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC20Receiver).interfaceId;
    }
}


// File contracts/payment/SessionsManager.sol

pragma solidity >=0.7.6 <0.8.0;




/**
 * @title SessionsManager, a contract to register game sessions in REVV Racing.
 */
contract SessionsManager is Recoverable, ERC20Receiver, PayoutWallet {
    using ERC20Wrapper for IWrappedERC20;

    /**
     * Event emitted when a game session has been submitted.
     * @param account the address of the account which entered the session.
     * @param sessionId the session identifier provided by the server.
     * @param amount the amount of REVV paid for the session: 0 for a free session, the current session price otherwise.
     */
    event Admission(address account, string sessionId, uint256 amount);

    IWrappedERC20 public immutable revvToken;

    uint256 public freeSessions; // the total number of free sessions for each account.
    uint256 public sessionPrice; // the current price for a single session.

    mapping(address => uint256) public freeSessionsUsed; // the number of free sessions used by account.

    constructor(IWrappedERC20 revvToken_, address payable payoutWallet) PayoutWallet(msg.sender, payoutWallet) {
        revvToken = revvToken_;
    }

    /**
     * Adds `amount` of free sessions.
     * @dev Reverts if the sender is not the contract owner.
     * @dev Reverts if the number of free sessions overflows.
     * @param amount the number of additional free sessions.
     */
    function addFreeSessions(uint256 amount) external {
        _requireOwnership(_msgSender());
        uint256 freeSessions_ = freeSessions;
        uint256 newFreeSessions = freeSessions_ + amount;
        require(newFreeSessions > freeSessions, "Sessions: sessions overflow");
        freeSessions = newFreeSessions;
    }

    /**
     * Sets `price` as the new session price. Setting a zero price will prevent any session to be admitted.
     * @dev Reverts if the sender is not the contract owner.
     * @param price the new session price.
     */
    function setSessionPrice(uint256 price) external {
        _requireOwnership(_msgSender());
        sessionPrice = price;
    }

    /**
     * Registers a user to a game session.
     * This function is the entry point when doing a PolygonREVV `safeTransfer` or `safeTransferFrom` to this contract.
     * @dev Reverts if the function is called from another address than the PolygonREVV contract address.
     * @dev Reverts if the session price has not been set yet.
     * @dev Reverts if the received value is incorrect: must be the session price, or zero in case of a free session.
     * @dev Emits an `Admission` event.
     * @param from the initiator of the transfer.
     * @param value the amount of PolygonREVV received.
     * @param data ABI-encoded string representing the session id6.
     */
    function onERC20Received(
        address, /*sender*/
        address from,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        require(_msgSender() == address(revvToken), "Sessions: wrong token");
        uint256 price = sessionPrice;
        require(price != 0, "Sessions: price not set");
        uint256 userFreeSessions = freeSessionsUsed[from];
        if (userFreeSessions < freeSessions) {
            require(value == 0, "Sessions: session is free");
            freeSessionsUsed[from] = userFreeSessions + 1; // cannot overflow as user free sessions can never reach max uint256
        } else {
            require(value == price, "Sessions: wrong price");
            revvToken.wrappedTransfer(payoutWallet, value);
        }

        emit Admission(from, abi.decode(data, (string)), value);

        return _ERC20_RECEIVED;
    }
}