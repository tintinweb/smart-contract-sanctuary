/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol



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

// File: @openzeppelin/contracts/utils/Context.sol



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
        return msg.data;
    }
}

// File: contracts/IBox.sol


pragma solidity ^0.8.0;

/**
 * @title Box events and storage
 * @notice Collection of events and storage to handle boxes
 */
interface IBox {
    // ERC721 token information {address and token ids} used for function parameters
    struct ERC721TokenInfos {
        address addr;
        uint256[] ids;
    }
    // ERC20 token information {address and amount} used for function parameters
    struct ERC20TokenInfos {
        address addr;
        uint256 amount;
    }
    // ERC1155 token information {address, token ids and token amounts} used for function parameters
    struct ERC1155TokenInfos {
        address addr;
        uint256[] ids;
        uint256[] amounts;
    }

    event Store(
        uint256 indexed boxId,
        uint256 ethAmount,
        ERC20TokenInfos[] erc20s,
        ERC721TokenInfos[] erc721s,
        ERC1155TokenInfos[] erc1155s
    );

    event Withdraw(
        uint256 indexed boxId,
        uint256 ethAmount,
        ERC20TokenInfos[] erc20s,
        ERC721TokenInfos[] erc721s,
        ERC1155TokenInfos[] erc1155s,
        address to
    );

    event TransferBetweenBoxes(
        uint256 indexed srcBoxId,
        uint256 indexed destBoxId,
        uint256 ethAmount,
        ERC20TokenInfos[] erc20s,
        ERC721TokenInfos[] erc721s,
        ERC1155TokenInfos[] erc1155s
    );

    event Destroyed(uint256 indexed boxId);   

    function store(
        uint256 boxId,
        ERC20TokenInfos[] calldata erc20s,
        ERC721TokenInfos[] calldata erc721s,
        ERC1155TokenInfos[] calldata erc1155s
    ) external payable;

    function withdraw(
        uint256 boxId,
        uint256 ethAmount,
        ERC20TokenInfos[] calldata erc20s,
        ERC721TokenInfos[] calldata erc721s,
        ERC1155TokenInfos[] calldata erc1155s,
        address payable to
    ) external;

    function transferBetweenBoxes(
        uint256 srcBoxId,
        uint256 destBoxId,
        uint256 ethAmount,
        ERC20TokenInfos[] calldata erc20s,
        ERC721TokenInfos[] calldata erc721s,
        ERC1155TokenInfos[] calldata erc1155s
    ) external;

    function destroy(
        uint256 boxId,
        uint256 ethAmount,
        ERC20TokenInfos[] calldata erc20ToWithdraw,
        ERC721TokenInfos[] calldata erc721ToWithdraw,
        ERC1155TokenInfos[] calldata erc1155ToWithdraw,
        address payable to
    ) external;


    function EthBalanceOf(uint256 _boxId) external view returns (uint256);

    function erc20BalanceOf(uint256 _boxId, address _tokenAddress) external view returns (uint256);

    function erc721BalanceOf(uint256 _boxId, address _tokenAddress, uint256 _tokenId) external view returns (uint256);

    function erc1155BalanceOf(uint256 _boxId, address _tokenAddress, uint256 _tokenId) external view returns (uint256);

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external returns(bytes4);

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4);
}

// File: contracts/BoxStorage.sol


pragma solidity ^0.8.0;

/**
 * @title Box storage
 * @notice Collection storage to handle boxes
 */
abstract contract BoxStorage {
    // ERC20: Mapping from hash(boxId, tokenAddress) to balance
    // ERC721: Mapping from hash(boxId, tokenAddress, tokenId) to 1 (owned) / 0 (not owned)
    // ER1155: Mapping from hash(boxId, tokenAddress, tokenId) to balance
    mapping(bytes32 => uint256) public _indexedTokens;
    
    // ETH: Mapping from boxId to balance
    mapping(uint256 => uint256) public _indexedEth;

    // Mapping of destroyed boxes
    mapping(uint256 => bool) public destroyedBoxes;
}

// File: contracts/OnlyDelegateCall.sol


pragma solidity ^0.8.0;

/**
 * @title Allows only delegate call
 */
contract OnlyDelegateCall {
    /// address of this very contract
    address private thisVeryContract;

    /**
     * @dev Constructor
     */
    constructor() {
        thisVeryContract = address(this);
    }
    
    /**
     * @dev Modifier throwing if the function is not called through a delegate call
     */
    modifier onlyDelegateCall() {
        require(address(this) != thisVeryContract, 'only delegateCall');
        _;
    }
}

// File: contracts/BoxBase.sol


pragma solidity ^0.8.0;








/**
 * @title Box with functions to store, withdraw, transferBetweenBoxes and destroy
 * @notice This contract is meant to be delegateCalled by a contract inheriting from BoxExternal
 * @notice This contract forbid reception of ERC1155 and ERC721
 * @notice Don't send ERC20 to this contract !
 */
contract BoxBase is IBox, BoxStorage, Context, OnlyDelegateCall {
    /**
     * @dev Store tokens inside a box
     * @notice allowance for the tokens must be done to the BoxExternal contract
     *
     * @param boxId id of the box
     * @param erc20s list of erc20 to store
     * @param erc721s list of erc721 to store
     * @param erc1155s list of erc1155 to store
     */
    function store(
        uint256 boxId,
        ERC20TokenInfos[] calldata erc20s,
        ERC721TokenInfos[] calldata erc721s,
        ERC1155TokenInfos[] calldata erc1155s
    ) external payable override onlyDelegateCall {
        // store ETH tokens
        _storeEth(boxId, msg.value);

        // store ERC721 tokens
        for (uint256 j = 0; j < erc721s.length; j++) {
            _storeErc721(boxId, erc721s[j].addr, erc721s[j].ids);
        }

        // store ERC20 tokens
        for (uint256 j = 0; j < erc20s.length; j++) {
            _storeErc20(boxId, erc20s[j].addr, erc20s[j].amount);
        }

        // store ERC1155 tokens
        for (uint256 j = 0; j < erc1155s.length; j++) {
            _storeErc1155(
                boxId,
                erc1155s[j].addr,
                erc1155s[j].ids,
                erc1155s[j].amounts
            );
        }

        emit Store(boxId, msg.value, erc20s, erc721s, erc1155s);
    }

    /**
     * @dev Withdraw tokens from a box to an address
     *
     * @param boxId id of the box
     * @param ethAmount amount of eth to withdraw
     * @param erc20s list of erc20 to withdraw
     * @param erc721s list of erc721 to withdraw
     * @param erc1155s list of erc1155 to withdraw
     * @param to address of reception
     */
    function withdraw(
        uint256 boxId,
        uint256 ethAmount,
        ERC20TokenInfos[] calldata erc20s,
        ERC721TokenInfos[] calldata erc721s,
        ERC1155TokenInfos[] calldata erc1155s,
        address payable to
    ) external override onlyDelegateCall {
        // withdraw ETH tokens
        _withdrawEth(boxId, ethAmount, to);

        // withdraw ERC721 tokens
        for (uint256 j = 0; j < erc721s.length; j++) {
            _withdrawERC721(boxId, erc721s[j].addr, erc721s[j].ids, to);
        }

        // withdraw ERC20 tokens
        for (uint256 j = 0; j < erc20s.length; j++) {
            _withdrawERC20(boxId, erc20s[j].addr, erc20s[j].amount, to);
        }

        // withdraw ERC1155 tokens
        for (uint256 j = 0; j < erc1155s.length; j++) {
            _withdrawERC1155(
                boxId,
                erc1155s[j].addr,
                erc1155s[j].ids,
                erc1155s[j].amounts,
                to
            );
        }

        emit Withdraw(boxId, ethAmount, erc20s, erc721s, erc1155s, to);
    }

    /**
     * @dev Transfer tokens from a box to another
     *
     * @param srcBoxId source box
     * @param destBoxId destination box
     * @param ethAmount amount of eth to transfer
     * @param erc20s list of erc20 to transfer
     * @param erc721s list of erc721 to transfer
     * @param erc1155s list of erc1155 to transfer
     */
    function transferBetweenBoxes(
        uint256 srcBoxId,
        uint256 destBoxId,
        uint256 ethAmount,
        ERC20TokenInfos[] calldata erc20s,
        ERC721TokenInfos[] calldata erc721s,
        ERC1155TokenInfos[] calldata erc1155s
    ) external override onlyDelegateCall {
        // transferBetweenBoxes Ethers
        _transferEthBetweenBoxes(srcBoxId, destBoxId, ethAmount);

        // transferBetweenBoxes ERC721 tokens
        _transferErc721BetweenBoxes(srcBoxId, destBoxId, erc721s);

        // transferBetweenBoxes ERC20 tokens
        _transferErc20BetweenBoxes(srcBoxId, destBoxId, erc20s);

        // transferBetweenBoxes ERC1155 tokens
        _transferErc1155BetweenBoxes(srcBoxId, destBoxId, erc1155s);

        emit TransferBetweenBoxes(
            srcBoxId,
            destBoxId,
            ethAmount,
            erc20s,
            erc721s,
            erc1155s
        );
    }

    /**
     * @dev Destroy a box
     *
     * @param boxId id of the box
     * @param ethAmount amount of eth to withdraw
     * @param erc20ToWithdraw list of erc20 to withdraw
     * @param erc721ToWithdraw list of erc721 to withdraw
     * @param erc1155ToWithdraw list of erc1155 to withdraw
     * @param to address of reception
     */
    function destroy(
        uint256 boxId,
        uint256 ethAmount,
        ERC20TokenInfos[] calldata erc20ToWithdraw,
        ERC721TokenInfos[] calldata erc721ToWithdraw,
        ERC1155TokenInfos[] calldata erc1155ToWithdraw,
        address payable to
    ) external override onlyDelegateCall {
        // destroy the box
        destroyedBoxes[boxId] = true;
        emit Destroyed(boxId);

        // withdraw ETH tokens
        _withdrawEth(boxId, ethAmount, to);

        // withdraw ERC721 tokens
        for (uint256 j = 0; j < erc721ToWithdraw.length; j++) {
            _withdrawERC721(
                boxId,
                erc721ToWithdraw[j].addr,
                erc721ToWithdraw[j].ids,
                to
            );
        }

        // withdraw ERC20 tokens
        for (uint256 j = 0; j < erc20ToWithdraw.length; j++) {
            _withdrawERC20(
                boxId,
                erc20ToWithdraw[j].addr,
                erc20ToWithdraw[j].amount,
                to
            );
        }

        // withdraw ERC1155 tokens
        for (uint256 j = 0; j < erc1155ToWithdraw.length; j++) {
            _withdrawERC1155(
                boxId,
                erc1155ToWithdraw[j].addr,
                erc1155ToWithdraw[j].ids,
                erc1155ToWithdraw[j].amounts,
                to
            );
        }

        emit Withdraw(
            boxId,
            ethAmount,
            erc20ToWithdraw,
            erc721ToWithdraw,
            erc1155ToWithdraw,
            to
        );
    }

    /**
     * @dev Get the balance of ethers in a box
     * @notice will always revert
     */
    function EthBalanceOf(uint256) public pure override returns (uint256) {
        revert();
    }

    /**
     * @dev Get the balance of an erc20 token in a box
     * @notice will always revert
     */
    function erc20BalanceOf(uint256, address)
        public
        pure
        override
        returns (uint256)
    {
        revert();
    }

    /**
     * @dev Get the balance of an erc1155 token in a box
     * @notice will always revert
     */
    function erc1155BalanceOf(
        uint256,
        address,
        uint256
    ) public pure override returns (uint256) {
        revert();
    }

    /**
     * @dev Check if an ERC721 token is in a box
     * @notice will always revert
     */
    function erc721BalanceOf(
        uint256,
        address,
        uint256
    ) public pure override returns (uint256) {
        revert();
    }

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types
     * @notice will always revert
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public pure override returns (bytes4) {
        revert();
    }

    /**
     * @dev Handles the receipt of a multiple ERC721 token types
     * @notice will always revert
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        revert();
    }

    /**
     * @dev Withdraw ethers from a box to an address
     *
     * @param boxId id of the box
     * @param amount amount of eth to withdraw
     */
    function _withdrawEth(
        uint256 boxId,
        uint256 amount,
        address payable to
    ) private {
        // update the box and check if the amount in the box in sufficient
        _indexedEth[boxId] -= amount;

        payable(to).transfer(amount);
    }

    /**
     * @dev Withdraw erc721 tokens from a box to an address
     *
     * @param boxId id of the box
     * @param tokenAddress address of the token
     * @param tokenIds list of token ids to withdraw
     * @param to address of reception
     */
    function _withdrawERC721(
        uint256 boxId,
        address tokenAddress,
        uint256[] calldata tokenIds,
        address to
    ) private {
        IERC721 token = IERC721(tokenAddress);

        for (uint256 k = 0; k < tokenIds.length; k++) {
            uint256 tokenId = tokenIds[k];
            bytes32 index = keccak256(
                abi.encodePacked(boxId, tokenAddress, tokenId)
            );

            // check if the token is in the box
            require(_indexedTokens[index] == 1, "e6");

            // update balance to avoid reentrancy
            delete _indexedTokens[index];

            // transfer the token to the owner of the box
            token.transferFrom(address(this), to, tokenId);
        }
    }

    /**
     * @dev Withdraw erc20 tokens from a box to an address
     *
     * @param boxId id of the box
     * @param tokenAddress address of the token
     * @param amountToWithdraw amount to withdraw
     * @param to address of reception
     */
    function _withdrawERC20(
        uint256 boxId,
        address tokenAddress,
        uint256 amountToWithdraw,
        address to
    ) private {
        bytes32 index = keccak256(abi.encodePacked(boxId, tokenAddress));

        // update the box and check if the amount in the box is sufficient
        _indexedTokens[index] -= amountToWithdraw;

        // transfer the token
        IERC20 token = IERC20(tokenAddress);
        token.transfer(to, amountToWithdraw);
    }

    /**
     * @dev Withdraw erc1155 tokens from a box to an address
     *
     * @param boxId id of the box
     * @param tokenAddress address of the token
     * @param tokenIds list of token ids to withdraw
     * @param amounts amount to withdraw for each token id
     * @param to address of reception
     */
    function _withdrawERC1155(
        uint256 boxId,
        address tokenAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        address to
    ) private {
        for (uint256 j = 0; j < tokenIds.length; j++) {
            bytes32 index = keccak256(
                abi.encodePacked(boxId, tokenAddress, tokenIds[j])
            );

            // update the box and check if the amount in the box in sufficient
            _indexedTokens[index] -= amounts[j];
        }

        IERC1155 token = IERC1155(tokenAddress);
        token.safeBatchTransferFrom(address(this), to, tokenIds, amounts, "");
    }

    /**
     * @dev store eth inside a box
     *
     * @param boxId id of the box
     * @param amount amount of eth to store
     */
    function _storeEth(uint256 boxId, uint256 amount) private {
        // update the box
        _indexedEth[boxId] += amount;
    }

    /**
     * @dev store erc721 tokens inside a box
     *
     * @param boxId id of the box
     * @param tokenAddress address of the token
     * @param tokenIds list of token ids to store
     */
    function _storeErc721(
        uint256 boxId,
        address tokenAddress,
        uint256[] calldata tokenIds
    ) private {
        // Avoid storing a box in a box
        require(tokenAddress != address(this), "e20");

        IERC721 token = IERC721(tokenAddress);

        for (uint256 j = 0; j < tokenIds.length; j++) {
            bytes32 index = keccak256(
                abi.encodePacked(boxId, tokenAddress, tokenIds[j])
            );

            require(_indexedTokens[index] == 0, "e1");

            // update the box
            _indexedTokens[index] = 1;

            // transfer the token to this very contract
            token.safeTransferFrom(_msgSender(), address(this), tokenIds[j]);
        }
    }

    /**
     * @dev store erc20 tokens in a box
     *
     * @param boxId id of the box
     * @param tokenAddress address of the token
     * @param amount amount to store
     */
    function _storeErc20(
        uint256 boxId,
        address tokenAddress,
        uint256 amount
    ) private {
        bytes32 index = keccak256(abi.encodePacked(boxId, tokenAddress));

        // update the box
        _indexedTokens[index] += amount;

        IERC20 token = IERC20(tokenAddress);

        // transfer the token to this very contract
        token.transferFrom(_msgSender(), address(this), amount);
    }

    /**
     * @dev store erc1155 tokens in a box
     *
     * @param boxId id of the box
     * @param tokenAddress address of the token
     * @param tokenIds list of token ids to store
     * @param amounts amount to store for each token id
     */
    function _storeErc1155(
        uint256 boxId,
        address tokenAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) private {
        for (uint256 j = 0; j < tokenIds.length; j++) {
            bytes32 index = keccak256(
                abi.encodePacked(boxId, tokenAddress, tokenIds[j])
            );

            // update the box
            _indexedTokens[index] += amounts[j];
        }

        IERC1155 token = IERC1155(tokenAddress);

        // transfer the token to this very contract
        token.safeBatchTransferFrom(
            _msgSender(),
            address(this),
            tokenIds,
            amounts,
            ""
        );
    }

    /**
     * @dev transfer ethers from a box to another
     *
     * @param srcBoxId id of the source box
     * @param srcBoxId id of the destination box
     * @param ethAmount amount of eth to transfer
     */
    function _transferEthBetweenBoxes(
        uint256 srcBoxId,
        uint256 destBoxId,
        uint256 ethAmount
    ) private {
        // remove from the source box
        _indexedEth[srcBoxId] -= ethAmount;

        // destination index
        _indexedEth[destBoxId] += ethAmount;
    }

    /**
     * @dev transfer erc721 from a box to another
     *
     * @param srcBoxId id of the source box
     * @param srcBoxId id of the destination box
     * @param erc721s list of erc721s token to transfer
     */
    function _transferErc721BetweenBoxes(
        uint256 srcBoxId,
        uint256 destBoxId,
        ERC721TokenInfos[] calldata erc721s
    ) private {
        for (uint256 j = 0; j < erc721s.length; j++) {
            for (uint256 k = 0; k < erc721s[j].ids.length; k++) {
                // source index
                bytes32 index = keccak256(
                    abi.encodePacked(
                        srcBoxId,
                        erc721s[j].addr,
                        erc721s[j].ids[k]
                    )
                );
                require(_indexedTokens[index] == 1, "e16");
                // remove from the source box
                delete _indexedTokens[index];

                // destination index
                index = keccak256(
                    abi.encodePacked(
                        destBoxId,
                        erc721s[j].addr,
                        erc721s[j].ids[k]
                    )
                );
                // add to the destination box
                _indexedTokens[index] = 1;
            }
        }
    }

    /**
     * @dev transfer erc20 from a box to another
     *
     * @param srcBoxId id of the source box
     * @param srcBoxId id of the destination box
     * @param erc20s list of erc20s token to transfer
     */
    function _transferErc20BetweenBoxes(
        uint256 srcBoxId,
        uint256 destBoxId,
        ERC20TokenInfos[] calldata erc20s
    ) private {
        for (uint256 j = 0; j < erc20s.length; j++) {
            // source index
            bytes32 index = keccak256(
                abi.encodePacked(srcBoxId, erc20s[j].addr)
            );

            // remove from the source box
            _indexedTokens[index] -= erc20s[j].amount;

            // destination index
            index = keccak256(abi.encodePacked(destBoxId, erc20s[j].addr));
            // add to the destination box
            _indexedTokens[index] += erc20s[j].amount;
        }
    }

    /**
     * @dev transfer erc1155 from a box to another
     *
     * @param srcBoxId id of the source box
     * @param srcBoxId id of the destination box
     * @param erc1155s list of erc1155 tokens to transfer
     */
    function _transferErc1155BetweenBoxes(
        uint256 srcBoxId,
        uint256 destBoxId,
        ERC1155TokenInfos[] calldata erc1155s
    ) private {
        for (uint256 j = 0; j < erc1155s.length; j++) {
            for (uint256 k = 0; k < erc1155s[j].ids.length; k++) {
                // source index
                bytes32 index = keccak256(
                    abi.encodePacked(
                        srcBoxId,
                        erc1155s[j].addr,
                        erc1155s[j].ids[k]
                    )
                );

                // remove from the source box
                _indexedTokens[index] -= erc1155s[j].amounts[k];

                // destination index
                index = keccak256(
                    abi.encodePacked(
                        destBoxId,
                        erc1155s[j].addr,
                        erc1155s[j].ids[k]
                    )
                );
                // add to the destination box
                _indexedTokens[index] += erc1155s[j].amounts[k];
            }
        }
    }
}