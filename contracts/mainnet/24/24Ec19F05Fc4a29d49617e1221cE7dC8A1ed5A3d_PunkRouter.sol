// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./interfaces/IWrappedPunks.sol";
import "./interfaces/IAssetWrapper.sol";
import "./interfaces/IPunks.sol";

/**
 * @dev {ERC721} Router contract allowing users to automatically
 *  wrap and deposit original cryptopunks into the AssetWrapper
 */
contract PunkRouter is ERC721Holder {
    IAssetWrapper public assetWrapper;
    IWrappedPunks public wrappedPunks;
    IPunks public punks;
    address public proxy;

    constructor(
        IAssetWrapper _assetWrapper,
        IWrappedPunks _wrappedPunks,
        IPunks _punks
    ) {
        assetWrapper = _assetWrapper;
        punks = _punks;
        wrappedPunks = _wrappedPunks;
        wrappedPunks.registerProxy();
        proxy = wrappedPunks.proxyInfo(address(this));
    }

    /**
     * @dev Wrap and deposit an original cryptopunk into an AssetWrapper bundle
     *
     * @param punkIndex The index of the CryptoPunk to deposit
     * @param bundleId The id of the wNFT to deposit into
     *
     * Requirements:
     *
     * - CryptoPunk punkIndex must be offered for sale to this address for 0 ETH
     *      Equivalent to an approval for normal ERC721s
     * - msg.sender must be the owner of punkIndex
     */
    function depositPunk(uint256 punkIndex, uint256 bundleId) external {
        IPunks _punks = punks;
        IWrappedPunks _wrappedPunks = wrappedPunks;
        IAssetWrapper _assetWrapper = assetWrapper;
        address owner = _punks.punkIndexToAddress(punkIndex);
        require(owner == msg.sender, "PunkRouter: not owner");
        _punks.buyPunk(punkIndex);
        _punks.transferPunk(proxy, punkIndex);

        _wrappedPunks.mint(punkIndex);
        _wrappedPunks.approve(address(_assetWrapper), punkIndex);
        _assetWrapper.depositERC721(address(_wrappedPunks), punkIndex, bundleId);
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
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Interface for a permittable ERC721 contract
 * See https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC72 allowance (see {IERC721-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC721-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IWrappedPunks is IERC721 {
    function mint(uint256 punkIndex) external;

    function burn(uint256 punkIndex) external;

    function registerProxy() external;

    function proxyInfo(address user) external returns (address proxy);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface for an AssetWrapper contract
 */
interface IAssetWrapper {
    /**
     * @dev Emitted when an ERC20 token is deposited
     */
    event DepositERC20(address indexed depositor, uint256 indexed bundleId, address tokenAddress, uint256 amount);

    /**
     * @dev Emitted when an ERC721 token is deposited
     */
    event DepositERC721(address indexed depositor, uint256 indexed bundleId, address tokenAddress, uint256 tokenId);

    /**
     * @dev Emitted when an ERC1155 token is deposited
     */
    event DepositERC1155(
        address indexed depositor,
        uint256 indexed bundleId,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount
    );

    /**
     * @dev Emitted when ETH is deposited
     */
    event DepositETH(address indexed depositor, uint256 indexed bundleId, uint256 amount);

    /**
     * @dev Emitted when ETH is deposited
     */
    event Withdraw(address indexed withdrawer, uint256 indexed bundleId);

    /**
     * @dev Creates a new bundle token for `to`. Its token ID will be
     * automatically assigned (and available on the emitted {IERC721-Transfer} event)
     *
     * See {ERC721-_mint}.
     */
    function initializeBundle(address to) external;

    /**
     * @dev Deposit some ERC20 tokens into a given bundle
     *
     * Requirements:
     *
     * - The bundle with id `bundleId` must have been initialized with {initializeBundle}
     * - `amount` tokens from `msg.sender` on `tokenAddress` must have been approved to this contract
     */
    function depositERC20(
        address tokenAddress,
        uint256 amount,
        uint256 bundleId
    ) external;

    /**
     * @dev Deposit an ERC721 token into a given bundle
     *
     * Requirements:
     *
     * - The bundle with id `bundleId` must have been initialized with {initializeBundle}
     * - The `tokenId` NFT from `msg.sender` on `tokenAddress` must have been approved to this contract
     */
    function depositERC721(
        address tokenAddress,
        uint256 tokenId,
        uint256 bundleId
    ) external;

    /**
     * @dev Deposit an ERC1155 token into a given bundle
     *
     * Requirements:
     *
     * - The bundle with id `bundleId` must have been initialized with {initializeBundle}
     * - The `tokenId` from `msg.sender` on `tokenAddress` must have been approved for at least `amount`to this contract
     */
    function depositERC1155(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 bundleId
    ) external;

    /**
     * @dev Deposit some ETH into a given bundle
     *
     * Requirements:
     *
     * - The bundle with id `bundleId` must have been initialized with {initializeBundle}
     */
    function depositETH(uint256 bundleId) external payable;

    /**
     * @dev Withdraw all assets in the given bundle, returning them to the msg.sender
     *
     * Requirements:
     *
     * - The bundle with id `bundleId` must have been initialized with {initializeBundle}
     * - The bundle with id `bundleId` must be owned by or approved to msg.sender
     */
    function withdraw(uint256 bundleId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface for a permittable ERC721 contract
 * See https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC72 allowance (see {IERC721-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC721-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IPunks {
    function punkIndexToAddress(uint256 punkIndex) external view returns (address owner);

    function buyPunk(uint256 punkIndex) external;

    function transferPunk(address to, uint256 punkIndex) external;
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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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

{
  "metadata": {
    "bytecodeHash": "none"
  },
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}