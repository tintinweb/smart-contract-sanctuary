// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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
pragma solidity ^0.8.10;

import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/interfaces/IERC721.sol';

library SplitWithdrawals {
    event SplitWithdrawal(address _tokenAddressOrNone, address recipient, uint256 _amount);

    struct Payout {
        address[] recipients;
        uint16[] splits;
        uint16 BASE;
        bool initialized;
    }

    modifier onlyWhenInitialized(bool initialized) {
        require(initialized, 'This withdrawal split must be initialized.');
        _;
    }

    event PayoutCreated(address indexed _sender, uint256 _amount, uint16 _split);

    function initialize(Payout storage _payout) external {
        // configure fee sharing
        require(_payout.recipients.length > 0, 'You must specify at least one recipient.');
        require(_payout.recipients.length == _payout.splits.length, 'Recipients and splits must be the same length.');

        uint16 _total = 0;
        for (uint8 i = 0; i < _payout.splits.length; i++) {
            _total += _payout.splits[i];
        }
        require(_total == _payout.BASE, 'Total must be equal to 100%.');

        // initialized flag
        _payout.initialized = true;
    }

    // WITHDRAWAL

    /// @dev withdraw native tokens divided by splits
    function withdraw(Payout storage _payout) external onlyWhenInitialized(_payout.initialized) {
        uint256 _amount = address(this).balance;
        if (_amount > 0) {
            for (uint256 i = 0; i < _payout.recipients.length; i++) {
                // we don't want to fail here or it can lock the contract withdrawals
                uint256 _share = (_amount * _payout.splits[i]) / _payout.BASE;
                (bool _success, ) = payable(_payout.recipients[i]).call{value: _share}('');
                if (_success) {
                    emit SplitWithdrawal(address(0), _payout.recipients[i], _share);
                }
            }
        }
    }

    /// @dev withdraw ERC20 tokens divided by splits
    function withdrawTokens(Payout storage _payout, address _tokenContract)
        external
        onlyWhenInitialized(_payout.initialized)
    {
        IERC20 tokenContract = IERC20(_tokenContract);

        // transfer the token from address of this contract
        uint256 _amount = tokenContract.balanceOf(address(this));
        /* istanbul ignore else */
        if (_amount > 0) {
            for (uint256 i = 0; i < _payout.recipients.length; i++) {
                uint256 _share = i != _payout.recipients.length - 1
                    ? (_amount * _payout.splits[i]) / _payout.BASE
                    : tokenContract.balanceOf(address(this));
                tokenContract.transfer(_payout.recipients[i], _share);
                emit SplitWithdrawal(_tokenContract, _payout.recipients[i], _share);
            }
        }
    }

    /// @dev withdraw ERC721 tokens to the first recipient
    function withdrawNFT(
        Payout storage _payout,
        address _tokenContract,
        uint256[] memory _id
    ) external onlyWhenInitialized(_payout.initialized) {
        IERC721 tokenContract = IERC721(_tokenContract);
        for (uint256 i = 0; i < _id.length; i++) {
            address _recipient = getNftRecipient(_payout);
            tokenContract.safeTransferFrom(address(this), _recipient, _id[i]);
        }
    }

    /// @dev Allow a recipient to update to a new address
    function updateRecipient(Payout storage _payout, address _recipient)
        external
        onlyWhenInitialized(_payout.initialized)
    {
        require(_recipient != address(0), 'Cannot use the zero address.');
        require(_recipient != address(this), 'Cannot use the address of this contract.');

        // loop over all the recipients and update the address
        bool _found = false;
        for (uint256 i = 0; i < _payout.recipients.length; i++) {
            // if the sender matches one of the recipients, update the address
            if (_payout.recipients[i] == msg.sender) {
                _payout.recipients[i] = _recipient;
                _found = true;
                break;
            }
        }
        require(_found, 'The sender is not a recipient.');
    }

    function getNftRecipient(Payout storage _payout)
        internal
        view
        onlyWhenInitialized(_payout.initialized)
        returns (address)
    {
        return _payout.recipients[0];
    }
}