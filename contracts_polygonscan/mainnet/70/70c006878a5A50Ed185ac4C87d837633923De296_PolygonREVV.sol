/**
 *Submitted for verification at polygonscan.com on 2021-07-27
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
 * @title ERC20 Token Standard, basic interface
 * @dev See https://eips.ethereum.org/EIPS/eip-20
 * Note: The ERC-165 identifier for this interface is 0x36372b07.
 */
interface IERC20 {
    /**
     * @dev Emitted when tokens are transferred, including zero value transfers.
     * @param _from The account where the transferred tokens are withdrawn from.
     * @param _to The account where the transferred tokens are deposited to.
     * @param _value The amount of tokens being transferred.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /**
     * @dev Emitted when a successful call to {IERC20-approve(address,uint256)} is made.
     * @param _owner The account granting an allowance to `_spender`.
     * @param _spender The account being granted an allowance from `_owner`.
     * @param _value The allowance amount being granted.
     */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
     * @notice Returns the total token supply.
     * @return The total token supply.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Returns the account balance of another account with address `owner`.
     * @param owner The account whose balance will be returned.
     * @return The account balance of another account with address `owner`.
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * Transfers `value` amount of tokens to address `to`.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender does not have enough balance.
     * @dev Emits an {IERC20-Transfer} event.
     * @dev Transfers of 0 values are treated as normal transfers and fire the {IERC20-Transfer} event.
     * @param to The receiver account.
     * @param value The amount of tokens to transfer.
     * @return True if the transfer succeeds, false otherwise.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @notice Transfers `value` amount of tokens from address `from` to address `to` via the approval mechanism.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender is not `from` and has not been approved by `from` for at least `value`.
     * @dev Reverts if `from` does not have at least `value` of balance.
     * @dev Emits an {IERC20-Transfer} event.
     * @dev Transfers of 0 values are treated as normal transfers and fire the {IERC20-Transfer} event.
     * @param from The emitter account.
     * @param to The receiver account.
     * @param value The amount of tokens to transfer.
     * @return True if the transfer succeeds, false otherwise.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    /**
     * Sets `value` as the allowance from the caller to `spender`.
     *  IMPORTANT: Beware that changing an allowance with this method brings the risk
     *  that someone may use both the old and the new allowance by unfortunate
     *  transaction ordering. One possible solution to mitigate this race
     *  condition is to first reduce the spender's allowance to 0 and set the
     *  desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @dev Reverts if `spender` is the zero address.
     * @dev Emits the {IERC20-Approval} event.
     * @param spender The account being granted the allowance by the message caller.
     * @param value The allowance amount to grant.
     * @return True if the approval succeeds, false otherwise.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * Returns the amount which `spender` is allowed to spend on behalf of `owner`.
     * @param owner The account that has granted an allowance to `spender`.
     * @param spender The account that was granted an allowance by `owner`.
     * @return The amount which `spender` is allowed to spend on behalf of `owner`.
     */
    function allowance(address owner, address spender) external view returns (uint256);
}


// File @animoca/ethereum-contracts-assets-1.1.3/contracts/token/ERC20/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC20 Token Standard, optional extension: Detailed
 * See https://eips.ethereum.org/EIPS/eip-20
 * Note: the ERC-165 identifier for this interface is 0xa219a025.
 */
interface IERC20Detailed {
    /**
     * Returns the name of the token. E.g. "My Token".
     * @return The name of the token.
     */
    function name() external view returns (string memory);

    /**
     * Returns the symbol of the token. E.g. "HIX".
     * @return The symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * Returns the number of decimals used to display the balances.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it does  not impact the arithmetic of the contract.
     * @return The number of decimals used to display the balances.
     */
    function decimals() external view returns (uint8);
}


// File @animoca/ethereum-contracts-assets-1.1.3/contracts/token/ERC20/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC20 Token Standard, optional extension: Allowance
 * See https://eips.ethereum.org/EIPS/eip-20
 * Note: the ERC-165 identifier for this interface is 0xd5b86388.
 */
interface IERC20Allowance {
    /**
     * Increases the allowance granted by the sender to `spender` by `value`.
     *  This is an alternative to {approve} that can be used as a mitigation for
     *  problems described in {IERC20-approve}.
     * @dev Reverts if `spender` is the zero address.
     * @dev Reverts if `spender`'s allowance overflows.
     * @dev Emits an {IERC20-Approval} event with an updated allowance for `spender`.
     * @param spender The account whose allowance is being increased by the message caller.
     * @param value The allowance amount increase.
     * @return True if the allowance increase succeeds, false otherwise.
     */
    function increaseAllowance(address spender, uint256 value) external returns (bool);

    /**
     * Decreases the allowance granted by the sender to `spender` by `value`.
     *  This is an alternative to {approve} that can be used as a mitigation for
     *  problems described in {IERC20-approve}.
     * @dev Reverts if `spender` is the zero address.
     * @dev Reverts if `spender` has an allowance with the message caller for less than `value`.
     * @dev Emits an {IERC20-Approval} event with an updated allowance for `spender`.
     * @param spender The account whose allowance is being decreased by the message caller.
     * @param value The allowance amount decrease.
     * @return True if the allowance decrease succeeds, false otherwise.
     */
    function decreaseAllowance(address spender, uint256 value) external returns (bool);
}


// File @animoca/ethereum-contracts-assets-1.1.3/contracts/token/ERC20/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC20 Token Standard, optional extension: Safe Transfers
 * Note: the ERC-165 identifier for this interface is 0x53f41a97.
 */
interface IERC20SafeTransfers {
    /**
     * Transfers tokens from the caller to `to`. If this address is a contract, then calls `onERC20Received(address,address,uint256,bytes)` on it.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if `value` is greater than the sender's balance.
     * @dev Reverts if `to` is a contract which does not implement `onERC20Received(address,address,uint256,bytes)`.
     * @dev Reverts if `to` is a contract and the call to `onERC20Received(address,address,uint256,bytes)` returns a wrong value.
     * @dev Emits an {IERC20-Transfer} event.
     * @param to The address for the tokens to be transferred to.
     * @param amount The amount of tokens to be transferred.
     * @param data Optional additional data with no specified format, to be passed to the receiver contract.
     * @return true.
     */
    function safeTransfer(
        address to,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    /**
     * Transfers tokens from `from` to another address, using the allowance mechanism.
     *  If this address is a contract, then calls `onERC20Received(address,address,uint256,bytes)` on it.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if `value` is greater than `from`'s balance.
     * @dev Reverts if the sender does not have at least `value` allowance by `from`.
     * @dev Reverts if `to` is a contract which does not implement `onERC20Received(address,address,uint256,bytes)`.
     * @dev Reverts if `to` is a contract and the call to `onERC20Received(address,address,uint256,bytes)` returns a wrong value.
     * @dev Emits an {IERC20-Transfer} event.
     * @param from The address which owns the tokens to be transferred.
     * @param to The address for the tokens to be transferred to.
     * @param amount The amount of tokens to be transferred.
     * @param data Optional additional data with no specified format, to be passed to the receiver contract.
     * @return true.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}


// File @animoca/ethereum-contracts-assets-1.1.3/contracts/token/ERC20/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC20 Token Standard, optional extension: Multi Transfers
 * Note: the ERC-165 identifier for this interface is 0xd5b86388.
 */
interface IERC20BatchTransfers {
    /**
     * Moves multiple `amounts` tokens from the caller's account to each of `recipients`.
     * @dev Reverts if `recipients` and `amounts` have different lengths.
     * @dev Reverts if one of `recipients` is the zero address.
     * @dev Reverts if the caller has an insufficient balance.
     * @dev Emits an {IERC20-Transfer} event for each individual transfer.
     * @param recipients the list of recipients to transfer the tokens to.
     * @param amounts the amounts of tokens to transfer to each of `recipients`.
     * @return a boolean value indicating whether the operation succeeded.
     */
    function batchTransfer(address[] calldata recipients, uint256[] calldata amounts) external returns (bool);

    /**
     * Moves multiple `amounts` tokens from an account to each of `recipients`, using the approval mechanism.
     * @dev Reverts if `recipients` and `amounts` have different lengths.
     * @dev Reverts if one of `recipients` is the zero address.
     * @dev Reverts if `from` has an insufficient balance.
     * @dev Reverts if the sender does not have at least the sum of all `amounts` as allowance by `from`.
     * @dev Emits an {IERC20-Transfer} event for each individual transfer.
     * @dev Emits an {IERC20-Approval} event.
     * @param from The address which owns the tokens to be transferred.
     * @param recipients the list of recipients to transfer the tokens to.
     * @param amounts the amounts of tokens to transfer to each of `recipients`.
     * @return a boolean value indicating whether the operation succeeded.
     */
    function batchTransferFrom(
        address from,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external returns (bool);
}


// File @animoca/ethereum-contracts-assets-1.1.3/contracts/token/ERC20/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC20 Token Standard, ERC1046 optional extension: Metadata
 * See https://eips.ethereum.org/EIPS/eip-1046
 * Note: the ERC-165 identifier for this interface is 0x3c130d90.
 */
interface IERC20Metadata {
    /**
     * Returns a distinct Uniform Resource Identifier (URI) for the token metadata.
     * @return a distinct Uniform Resource Identifier (URI) for the token metadata.
     */
    function tokenURI() external view returns (string memory);
}


// File @animoca/ethereum-contracts-assets-1.1.3/contracts/token/ERC20/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC20 Token Standard, ERC2612 optional extension: permit – 712-signed approvals
 * @dev Interface for allowing ERC20 approvals to be made via ECDSA `secp256k1` signatures.
 * See https://eips.ethereum.org/EIPS/eip-2612
 * Note: the ERC-165 identifier for this interface is 0x9d8ff7da.
 */
interface IERC20Permit {
    /**
     * Sets `value` as the allowance of `spender` over the tokens of `owner`, given `owner` account's signed permit.
     * @dev WARNING: The standard ERC-20 race condition for approvals applies to `permit()` as well: https://swcregistry.io/docs/SWC-114
     * @dev Reverts if `owner` is the zero address.
     * @dev Reverts if the current blocktime is > `deadline`.
     * @dev Reverts if `r`, `s`, and `v` is not a valid `secp256k1` signature from `owner`.
     * @dev Emits an {IERC20-Approval} event.
     * @param owner The token owner granting the allowance to `spender`.
     * @param spender The token spender being granted the allowance by `owner`.
     * @param value The token amount of the allowance.
     * @param deadline The deadline from which the permit signature is no longer valid.
     * @param v Permit signature v parameter
     * @param r Permit signature r parameter.
     * @param s Permis signature s parameter.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * Returns the current permit nonce of `owner`.
     * @param owner the address to check the nonce of.
     * @return the current permit nonce of `owner`.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * Returns the EIP-712 encoded hash struct of the domain-specific information for permits.
     *
     * @dev A common ERC-20 permit implementation choice for the `DOMAIN_SEPARATOR` is:
     *
     *  keccak256(
     *      abi.encode(
     *          keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
     *          keccak256(bytes(name)),
     *          keccak256(bytes(version)),
     *          chainId,
     *          address(this)))
     *
     *  where
     *   - `name` (string) is the ERC-20 token name.
     *   - `version` (string) refers to the ERC-20 token contract version.
     *   - `chainId` (uint256) is the chain ID to which the ERC-20 token contract is deployed to.
     *   - `verifyingContract` (address) is the ERC-20 token contract address.
     *
     * @return the EIP-712 encoded hash struct of the domain-specific information for permits.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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











/**
 * @title ERC20 Fungible Token Contract.
 */
abstract contract ERC20 is
    ManagedIdentity,
    IERC165,
    IERC20,
    IERC20Detailed,
    IERC20Metadata,
    IERC20Allowance,
    IERC20BatchTransfers,
    IERC20SafeTransfers,
    IERC20Permit
{
    using AddressIsContract for address;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    bytes32 internal constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    uint256 public immutable deploymentChainId;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    mapping(address => uint256) public override nonces;

    string internal _name;
    string internal _symbol;
    uint8 internal immutable _decimals;
    string internal _tokenURI;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 internal _totalSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        string memory tokenURI_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _tokenURI = tokenURI_;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        deploymentChainId = chainId;
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(chainId, bytes(name_));
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        // recompute the domain separator in case of fork and chainid update
        return chainId == deploymentChainId ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId, bytes(_name));
    }

    function _calculateDomainSeparator(uint256 chainId, bytes memory name_) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(name_),
                    keccak256("1"),
                    chainId,
                    address(this)
                )
            );
    }

    /////////////////////////////////////////// ERC165 ///////////////////////////////////////

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IERC20Detailed).interfaceId ||
            interfaceId == type(IERC20Metadata).interfaceId ||
            interfaceId == type(IERC20Allowance).interfaceId ||
            interfaceId == type(IERC20BatchTransfers).interfaceId ||
            interfaceId == type(IERC20SafeTransfers).interfaceId ||
            interfaceId == type(IERC20Permit).interfaceId;
    }

    /////////////////////////////////////////// ERC20Detailed ///////////////////////////////////////

    /// @dev See {IERC20Detailed-name}.
    function name() external view override returns (string memory) {
        return _name;
    }

    /// @dev See {IERC20Detailed-symbol}.
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /// @dev See {IERC20Detailed-decimals}.
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /////////////////////////////////////////// ERC20Metadata ///////////////////////////////////////

    /// @dev See {IERC20Metadata-tokenURI}.
    function tokenURI() external view override returns (string memory) {
        return _tokenURI;
    }

    /////////////////////////////////////////// ERC20 ///////////////////////////////////////

    /// @dev See {IERC20-totalSupply}.
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /// @dev See {IERC20-balanceOf}.
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    /// @dev See {IERC20-allowance}.
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /// @dev See {IERC20-approve}.
    function approve(address spender, uint256 value) external virtual override returns (bool) {
        _approve(_msgSender(), spender, value);
        return true;
    }

    /////////////////////////////////////////// ERC20 Allowance ///////////////////////////////////////

    /// @dev See {IERC20Allowance-increaseAllowance}.
    function increaseAllowance(address spender, uint256 addedValue) external virtual override returns (bool) {
        require(spender != address(0), "ERC20: zero address spender");
        address owner = _msgSender();
        uint256 allowance_ = _allowances[owner][spender];
        if (addedValue != 0) {
            uint256 newAllowance = allowance_ + addedValue;
            require(newAllowance > allowance_, "ERC20: allowance overflow");
            _allowances[owner][spender] = newAllowance;
            allowance_ = newAllowance;
        }
        emit Approval(owner, spender, allowance_);

        return true;
    }

    /// @dev See {IERC20Allowance-decreaseAllowance}.
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual override returns (bool) {
        require(spender != address(0), "ERC20: zero address spender");
        _decreaseAllowance(_msgSender(), spender, subtractedValue);
        return true;
    }

    /// @dev See {IERC20-transfer}.
    function transfer(address to, uint256 value) external virtual override returns (bool) {
        _transfer(_msgSender(), to, value);
        return true;
    }

    /// @dev See {IERC20-transferFrom}.
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external virtual override returns (bool) {
        _transferFrom(_msgSender(), from, to, value);
        return true;
    }

    /////////////////////////////////////////// ERC20MultiTransfer ///////////////////////////////////////

    /// @dev See {IERC20MultiTransfer-multiTransfer(address[],uint256[])}.
    function batchTransfer(address[] calldata recipients, uint256[] calldata values) external virtual override returns (bool) {
        uint256 length = recipients.length;
        require(length == values.length, "ERC20: inconsistent arrays");
        address sender = _msgSender();
        uint256 balance = _balances[sender];

        uint256 totalValue;
        uint256 selfTransferTotalValue;
        for (uint256 i; i != length; ++i) {
            address to = recipients[i];
            require(to != address(0), "ERC20: to zero address");

            uint256 value = values[i];
            if (value != 0) {
                uint256 newTotalValue = totalValue + value;
                require(newTotalValue > totalValue, "ERC20: values overflow");
                totalValue = newTotalValue;
                if (sender != to) {
                    _balances[to] += value;
                } else {
                    require(value <= balance, "ERC20: insufficient balance");
                    selfTransferTotalValue += value; // cannot overflow as 'selfTransferTotalValue <= totalValue' is always true
                }
            }
            emit Transfer(sender, to, value);
        }

        if (totalValue != 0 && totalValue != selfTransferTotalValue) {
            uint256 newBalance = balance - totalValue;
            require(newBalance < balance, "ERC20: insufficient balance"); // balance must be sufficient, including self-transfers
            _balances[sender] = newBalance + selfTransferTotalValue; // do not deduct self-transfers from the sender balance
        }
        return true;
    }

    /// @dev See {IERC20MultiTransfer-multiTransferFrom(address,address[],uint256[])}.
    function batchTransferFrom(
        address from,
        address[] calldata recipients,
        uint256[] calldata values
    ) external virtual override returns (bool) {
        uint256 length = recipients.length;
        require(length == values.length, "ERC20: inconsistent arrays");

        uint256 balance = _balances[from];

        uint256 totalValue;
        uint256 selfTransferTotalValue;
        for (uint256 i; i != length; ++i) {
            address to = recipients[i];
            require(to != address(0), "ERC20: to zero address");

            uint256 value = values[i];

            if (value != 0) {
                uint256 newTotalValue = totalValue + value;
                require(newTotalValue > totalValue, "ERC20: values overflow");
                totalValue = newTotalValue;
                if (from != to) {
                    _balances[to] += value;
                } else {
                    require(value <= balance, "ERC20: insufficient balance");
                    selfTransferTotalValue += value; // cannot overflow as 'selfTransferTotalValue <= totalValue' is always true
                }
            }

            emit Transfer(from, to, value);
        }

        if (totalValue != 0 && totalValue != selfTransferTotalValue) {
            uint256 newBalance = balance - totalValue;
            require(newBalance < balance, "ERC20: insufficient balance"); // balance must be sufficient, including self-transfers
            _balances[from] = newBalance + selfTransferTotalValue; // do not deduct self-transfers from the sender balance
        }

        address sender = _msgSender();
        if (from != sender) {
            _decreaseAllowance(from, sender, totalValue);
        }

        return true;
    }

    /////////////////////////////////////////// ERC20SafeTransfers ///////////////////////////////////////

    /// @dev See {IERC20Safe-safeTransfer(address,uint256,bytes)}.
    function safeTransfer(
        address to,
        uint256 amount,
        bytes calldata data
    ) external virtual override returns (bool) {
        address sender = _msgSender();
        _transfer(sender, to, amount);
        if (to.isContract()) {
            require(IERC20Receiver(to).onERC20Received(sender, sender, amount, data) == type(IERC20Receiver).interfaceId, "ERC20: transfer refused");
        }
        return true;
    }

    /// @dev See {IERC20Safe-safeTransferFrom(address,address,uint256,bytes)}.
    function safeTransferFrom(
        address from,
        address to,
        uint256 amount,
        bytes calldata data
    ) external virtual override returns (bool) {
        address sender = _msgSender();
        _transferFrom(sender, from, to, amount);
        if (to.isContract()) {
            require(IERC20Receiver(to).onERC20Received(sender, from, amount, data) == type(IERC20Receiver).interfaceId, "ERC20: transfer refused");
        }
        return true;
    }

    /////////////////////////////////////////// ERC20Permit ///////////////////////////////////////

    /// @dev See {IERC2612-permit(address,address,uint256,uint256,uint8,bytes32,bytes32)}.
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override {
        require(owner != address(0), "ERC20: zero address owner");
        require(block.timestamp <= deadline, "ERC20: expired permit");
        bytes32 hashStruct = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), hashStruct));
        address signer = ecrecover(hash, v, r, s);
        require(signer == owner, "ERC20: invalid permit");
        _approve(owner, spender, value);
    }

    /////////////////////////////////////////// Internal Functions ///////////////////////////////////////

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal {
        require(spender != address(0), "ERC20: zero address spender");
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _decreaseAllowance(
        address owner,
        address spender,
        uint256 subtractedValue
    ) internal {
        uint256 allowance_ = _allowances[owner][spender];

        if (allowance_ != type(uint256).max && subtractedValue != 0) {
            // save gas when allowance is maximal by not reducing it (see https://github.com/ethereum/EIPs/issues/717)
            uint256 newAllowance = allowance_ - subtractedValue;
            require(newAllowance < allowance_, "ERC20: insufficient allowance");
            _allowances[owner][spender] = newAllowance;
            allowance_ = newAllowance;
        }
        emit Approval(owner, spender, allowance_);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual {
        require(to != address(0), "ERC20: to zero address");

        if (value != 0) {
            uint256 balance = _balances[from];
            uint256 newBalance = balance - value;
            require(newBalance < balance, "ERC20: insufficient balance");
            if (from != to) {
                _balances[from] = newBalance;
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    function _transferFrom(
        address sender,
        address from,
        address to,
        uint256 value
    ) internal {
        _transfer(from, to, value);
        if (from != sender) {
            _decreaseAllowance(from, sender, value);
        }
    }

    function _mint(address to, uint256 value) internal virtual {
        require(to != address(0), "ERC20: zero address");
        uint256 supply = _totalSupply;
        if (value != 0) {
            uint256 newSupply = supply + value;
            require(newSupply > supply, "ERC20: supply overflow");
            _totalSupply = newSupply;
            _balances[to] += value; // balance cannot overflow if supply does not
        }
        emit Transfer(address(0), to, value);
    }

    function _batchMint(address[] memory recipients, uint256[] memory values) internal virtual {
        uint256 length = recipients.length;
        require(length == values.length, "ERC20: inconsistent arrays");

        uint256 totalValue;
        for (uint256 i; i != length; ++i) {
            address to = recipients[i];
            require(to != address(0), "ERC20: zero address");

            uint256 value = values[i];
            if (value != 0) {
                uint256 newTotalValue = totalValue + value;
                require(newTotalValue > totalValue, "ERC20: values overflow");
                totalValue = newTotalValue;
                _balances[to] += value; // balance cannot overflow if supply does not
            }
            emit Transfer(address(0), to, value);
        }

        if (totalValue != 0) {
            uint256 supply = _totalSupply;
            uint256 newSupply = supply + totalValue;
            require(newSupply > supply, "ERC20: supply overflow");
            _totalSupply = newSupply;
        }
    }

    function _burn(address from, uint256 value) internal virtual {
        if (value != 0) {
            uint256 balance = _balances[from];
            uint256 newBalance = balance - value;
            require(newBalance < balance, "ERC20: insufficient balance");
            _balances[from] = newBalance;
            _totalSupply -= value; // will not underflow if balance does not
        }
        emit Transfer(from, address(0), value);
    }

    function _burnFrom(address from, uint256 value) internal virtual {
        _burn(from, value);
        address sender = _msgSender();
        if (from != sender) {
            _decreaseAllowance(from, sender, value);
        }
    }

    function _batchBurnFrom(address[] memory owners, uint256[] memory values) internal virtual {
        uint256 length = owners.length;
        require(length == values.length, "ERC20: inconsistent arrays");

        address sender = _msgSender();

        uint256 totalValue;
        for (uint256 i; i != length; ++i) {
            address from = owners[i];
            uint256 value = values[i];
            if (value != 0) {
                uint256 balance = _balances[from];
                uint256 newBalance = balance - value;
                require(newBalance < balance, "ERC20: insufficient balance");
                _balances[from] = newBalance;
                totalValue += value; // totalValue cannot overflow if the individual balances do not underflow
            }
            emit Transfer(from, address(0), value);

            if (from != sender) {
                _decreaseAllowance(from, sender, value);
            }
        }

        if (totalValue != 0) {
            _totalSupply -= totalValue; // _totalSupply cannot underfow as balances do not underflow
        }
    }
}


// File @animoca/ethereum-contracts-core-1.1.1/contracts/bridging/[email protected]

pragma solidity >=0.7.6 <0.8.0;

interface IChildToken {
    function deposit(address user, bytes calldata depositData) external;
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


// File @animoca/ethereum-contracts-assets-1.1.3/contracts/bridging/[email protected]

pragma solidity >=0.7.6 <0.8.0;


/**
 * Polygon (MATIC) bridging base child ERC20 for deployment on the child chain (Polygon/MATIC).
 */
abstract contract ChildERC20Base is IChildToken, ERC20Receiver {
    event Withdrawn(address account, uint256 value);

    // see https://github.com/maticnetwork/pos-portal/blob/master/contracts/child/ChildChainManager/ChildChainManager.sol
    address public childChainManager;

    /**
     * Constructor
     * @param childChainManager_ the Polygon/MATIC ChildChainManager proxy address.
     */
    constructor(address childChainManager_) {
        childChainManager = childChainManager_;
    }

    function _requireDepositorRole(address account) internal view {
        require(account == childChainManager, "ChildERC20: only depositor");
    }
}


// File @animoca/ethereum-contracts-assets-1.1.3/contracts/token/ERC20/[email protected]

pragma solidity >=0.7.6 <0.8.0;


abstract contract ChildERC20 is ERC20, ChildERC20Base {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        string memory tokenURI_,
        address childChainManager
    ) ERC20(name_, symbol_, decimals_, tokenURI_) ChildERC20Base(childChainManager) {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC20, ERC20Receiver) returns (bool) {
        return ERC20.supportsInterface(interfaceId) || ERC20Receiver.supportsInterface(interfaceId);
    }

    /**
     * Called when tokens have been deposited on the root chain.
     * @dev Should handle deposit by un-escrowing the required amount for user.
     * @dev Reverts if not sent by the depositor (ChildChainManager).
     * @param user address for whom deposit has been done.
     * @param depositData abi encoded amount.
     */
    function deposit(address user, bytes calldata depositData) public virtual override {
        _requireDepositorRole(_msgSender());
        uint256 amount = abi.decode(depositData, (uint256));
        _transfer(address(this), user, amount);
    }

    /**
     * Called when user wants to withdraw tokens back to the root chain.
     * @dev Should escrow user's tokens. This transaction will be verified when exiting on root chain.
     * @dev Emits a {Withdrawn} event.
     * @param amount amount of tokens to withdraw.
     */
    function withdraw(uint256 amount) public virtual {
        address sender = _msgSender();
        _transferFrom(sender, sender, address(this), amount);
        emit Withdrawn(sender, amount);
    }

    /**
     * Called when user wants to withdraw tokens back to the root chain (no pre-approval required).
     * @dev Should escrow user's tokens. This transaction will be verified when exiting on root chain.
     * @dev Reverts if the sender is not this contract.
     * @dev Emits a {Withdrawn} event.
     * _param operator The initiator of the transfer.
     * @param from The address which transferred the tokens.
     * @param amount The amount of tokens transferred.
     * _param data Optional additional data with no specified format.
     * @return bytes4 `bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))`
     */
    function onERC20Received(
        address, /*operator*/
        address from,
        uint256 amount,
        bytes calldata /*data*/
    ) public virtual override returns (bytes4) {
        require(_msgSender() == address(this), "ChildERC20: wrong sender");
        emit Withdrawn(from, amount);
        return _ERC20_RECEIVED;
    }
}


// File ethereum-universal-forwarder/src/solc_0.7/ERC2771/[email protected]
pragma solidity ^0.7.0;

abstract contract UsingAppendedCallData {
    function _lastAppendedDataAsSender() internal pure virtual returns (address payable sender) {
        // Copied from openzeppelin : https://github.com/OpenZeppelin/openzeppelin-contracts/blob/9d5f77db9da0604ce0b25148898a94ae2c20d70f/contracts/metatx/ERC2771Context.sol1
        // The assembly code is more direct than the Solidity version using `abi.decode`.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sender := shr(96, calldataload(sub(calldatasize(), 20)))
        }
    }

    function _msgDataAssuming20BytesAppendedData() internal pure virtual returns (bytes calldata) {
        return msg.data[:msg.data.length - 20];
    }
}


// File ethereum-universal-forwarder/src/solc_0.7/ERC2771/[email protected]
pragma solidity ^0.7.0;

interface IERC2771 {
    function isTrustedForwarder(address forwarder) external view returns (bool);
}


// File ethereum-universal-forwarder/src/solc_0.7/ERC2771/[email protected]
pragma solidity ^0.7.0;

interface IForwarderRegistry {
    function isForwarderFor(address, address) external view returns (bool);
}


// File ethereum-universal-forwarder/src/solc_0.7/ERC2771/[email protected]
pragma solidity ^0.7.0;



abstract contract UsingUniversalForwarding is UsingAppendedCallData, IERC2771 {
    IForwarderRegistry internal immutable _forwarderRegistry;
    address internal immutable _universalForwarder;

    constructor(IForwarderRegistry forwarderRegistry, address universalForwarder) {
        _universalForwarder = universalForwarder;
        _forwarderRegistry = forwarderRegistry;
    }

    function isTrustedForwarder(address forwarder) external view virtual override returns (bool) {
        return forwarder == _universalForwarder || forwarder == address(_forwarderRegistry);
    }

    function _msgSender() internal view virtual returns (address payable) {
        address payable msgSender = msg.sender;
        address payable sender = _lastAppendedDataAsSender();
        if (msgSender == address(_forwarderRegistry) || msgSender == _universalForwarder) {
            // if forwarder use appended data
            return sender;
        }

        // if msg.sender is neither the registry nor the universal forwarder,
        // we have to check the last 20bytes of the call data intepreted as an address
        // and check if the msg.sender was registered as forewarder for that address
        // we check tx.origin to save gas in case where msg.sender == tx.origin
        // solhint-disable-next-line avoid-tx-origin
        if (msgSender != tx.origin && _forwarderRegistry.isForwarderFor(sender, msgSender)) {
            return sender;
        }

        return msgSender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        address payable msgSender = msg.sender;
        if (msgSender == address(_forwarderRegistry) || msgSender == _universalForwarder) {
            // if forwarder use appended data
            return _msgDataAssuming20BytesAppendedData();
        }

        // we check tx.origin to save gas in case where msg.sender == tx.origin
        // solhint-disable-next-line avoid-tx-origin
        if (msgSender != tx.origin && _forwarderRegistry.isForwarderFor(_lastAppendedDataAsSender(), msgSender)) {
            return _msgDataAssuming20BytesAppendedData();
        }
        return msg.data;
    }
}


// File contracts/token/ERC20/PolygonREVV.sol

pragma solidity >=0.7.6 <0.8.0;




contract PolygonREVV is Recoverable, UsingUniversalForwarding, ChildERC20 {
    using ERC20Wrapper for IWrappedERC20;

    uint256 public escrowed;

    constructor(
        uint256 supply,
        address childChainManager,
        IForwarderRegistry forwarderRegistry,
        address universalForwarder
    ) ChildERC20("REVV", "REVV", 18, "", childChainManager) UsingUniversalForwarding(forwarderRegistry, universalForwarder) Ownable(msg.sender) {
        _mint(address(this), supply);
        escrowed = supply;
    }

    function setTokenURI(string memory tokenURI_) external {
        _requireOwnership(_msgSender());
        _tokenURI = tokenURI_;
    }

    function deposit(address user, bytes calldata depositData) public virtual override {
        escrowed -= abi.decode(depositData, (uint256));
        super.deposit(user, depositData);
    }

    function withdraw(uint256 amount) public virtual override {
        escrowed += amount;
        super.withdraw(amount);
    }

    function onERC20Received(
        address operator,
        address from,
        uint256 amount,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        escrowed += amount;
        return super.onERC20Received(operator, from, amount, data);
    }

    function recoverERC20s(
        address[] calldata accounts,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external virtual override {
        _requireOwnership(_msgSender());
        uint256 length = accounts.length;
        require(length == tokens.length && length == amounts.length, "Recov: inconsistent arrays");
        for (uint256 i = 0; i != length; ++i) {
            address token = tokens[i];
            uint256 amount = amounts[i];
            if (token == address(this)) {
                uint256 recoverable = _balances[address(this)] - escrowed;
                require(amount <= recoverable, "Recov: insufficient balance");
            }
            IWrappedERC20(token).wrappedTransfer(accounts[i], amount);
        }
    }

    function _msgSender() internal view virtual override(ManagedIdentity, UsingUniversalForwarding) returns (address payable) {
        return UsingUniversalForwarding._msgSender();
    }

    function _msgData() internal view virtual override(ManagedIdentity, UsingUniversalForwarding) returns (bytes memory ret) {
        return UsingUniversalForwarding._msgData();
    }
}