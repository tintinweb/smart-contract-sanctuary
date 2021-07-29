/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

// Sources flattened with hardhat v2.4.3 https://hardhat.org

// File contracts/solidity/interface/INFTXEligibility.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFTXEligibility {
    // Read functions.
    function name() external pure returns (string memory);
    function finalized() external view returns (bool);
    function targetAsset() external pure returns (address);
    function checkAllEligible(uint256[] calldata tokenIds)
        external
        view
        returns (bool);
    function checkEligible(uint256[] calldata tokenIds)
        external
        view
        returns (bool[] memory);
    function checkAllIneligible(uint256[] calldata tokenIds)
        external
        view
        returns (bool);
    function checkIsEligible(uint256 tokenId) external view returns (bool);

    // Write functions.
    function __NFTXEligibility_init_bytes(bytes calldata configData) external;
    function beforeMintHook(uint256[] calldata tokenIds) external;
    function afterMintHook(uint256[] calldata tokenIds) external;
    function beforeRedeemHook(uint256[] calldata tokenIds) external;
    function afterRedeemHook(uint256[] calldata tokenIds) external;
}


// File contracts/solidity/proxy/IBeacon.sol



pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function childImplementation() external view returns (address);
    function upgradeChildTo(address newImplementation) external;
}


// File contracts/solidity/interface/INFTXVaultFactory.sol



pragma solidity ^0.8.0;

interface INFTXVaultFactory is IBeacon {
  // Read functions.
  function numVaults() external view returns (uint256);
  function zapContract() external view returns (address);
  function feeDistributor() external view returns (address);
  function eligibilityManager() external view returns (address);
  function vault(uint256 vaultId) external view returns (address);
  function vaultsForAsset(address asset) external view returns (address[] memory);
  function isLocked(uint256 id) external view returns (bool);
  function excludedFromFees(address addr) external view returns (bool);

  event NewFeeDistributor(address oldDistributor, address newDistributor);
  event NewZapContract(address oldZap, address newZap);
  event FeeExclusion(address feeExcluded, bool excluded);
  event NewEligibilityManager(address oldEligManager, address newEligManager);
  event NewVault(uint256 indexed vaultId, address vaultAddress, address assetAddress);

  // Write functions.
  function __NFTXVaultFactory_init(address _vaultImpl, address _feeDistributor) external;
  function createVault(
      string calldata name,
      string calldata symbol,
      address _assetAddress,
      bool is1155,
      bool allowAllItems
  ) external returns (uint256);
  function setFeeDistributor(address _feeDistributor) external;
  function setEligibilityManager(address _eligibilityManager) external;
  function setZapContract(address _zapContract) external;
  function setFeeExclusion(address _excludedAddr, bool excluded) external;
}


// File contracts/solidity/interface/INFTXVault.sol



pragma solidity ^0.8.0;


interface INFTXVault {
    function manager() external returns (address);
    function assetAddress() external returns (address);
    function vaultFactory() external returns (INFTXVaultFactory);
    function eligibilityStorage() external returns (INFTXEligibility);

    function is1155() external returns (bool);
    function allowAllItems() external returns (bool);
    function enableMint() external returns (bool);
    function enableRandomRedeem() external returns (bool);
    function enableTargetRedeem() external returns (bool);

    function vaultId() external returns (uint256);
    function nftIdAt(uint256 holdingsIndex) external view returns (uint256);
    function allHoldings() external view returns (uint256[] memory);
    function totalHoldings() external view returns (uint256);
    function mintFee() external returns (uint256);
    function randomRedeemFee() external returns (uint256);
    function targetRedeemFee() external returns (uint256);

    event VaultInit(
        uint256 indexed vaultId,
        address assetAddress,
        bool is1155,
        bool allowAllItems
    );

    event ManagerSet(address manager);
    event EligibilityDeployed(uint256 moduleIndex, address eligibilityAddr);
    // event CustomEligibilityDeployed(address eligibilityAddr);

    event EnableMintUpdated(bool enabled);
    event EnableRandomRedeemUpdated(bool enabled);
    event EnableTargetRedeemUpdated(bool enabled);

    event MintFeeUpdated(uint256 mintFee);
    event RandomRedeemFeeUpdated(uint256 randomRedeemFee);
    event TargetRedeemFeeUpdated(uint256 targetRedeemFee);

    event Minted(uint256[] nftIds, uint256[] amounts, address to);
    event Redeemed(uint256[] nftIds, uint256[] specificIds, address to);
    event Swapped(
        uint256[] nftIds,
        uint256[] amounts,
        uint256[] specificIds,
        uint256[] redeemedIds,
        address to
    );

    function __NFTXVault_init(
        string calldata _name,
        string calldata _symbol,
        address _assetAddress,
        bool _is1155,
        bool _allowAllItems
    ) external;

    function finalizeVault() external;

    function setVaultMetadata(
        string memory name_, 
        string memory symbol_
    ) external;

    function setVaultFeatures(
        bool _enableMint,
        bool _enableRandomRedeem,
        bool _enableTargetRedeem
    ) external;

    function setFees(
        uint256 _mintFee,
        uint256 _randomRedeemFee,
        uint256 _targetRedeemFee
    ) external;

    // This function allows for an easy setup of any eligibility module contract from the EligibilityManager.
    // It takes in ABI encoded parameters for the desired module. This is to make sure they can all follow
    // a similar interface.
    function deployEligibilityStorage(
        uint256 moduleIndex,
        bytes calldata initData
    ) external returns (address);

    // The manager has control over options like fees and features
    function setManager(address _manager) external;

    function mint(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts /* ignored for ERC721 vaults */
    ) external returns (uint256);

    function mintTo(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts, /* ignored for ERC721 vaults */
        address to
    ) external returns (uint256);

    function redeem(uint256 amount, uint256[] calldata specificIds)
        external
        returns (uint256[] calldata);

    function redeemTo(
        uint256 amount,
        uint256[] calldata specificIds,
        address to
    ) external returns (uint256[] calldata);

    function swap(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts, /* ignored for ERC721 vaults */
        uint256[] calldata specificIds
    ) external returns (uint256[] calldata);

    function swapTo(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts, /* ignored for ERC721 vaults */
        uint256[] calldata specificIds,
        address to
    ) external returns (uint256[] calldata);

    function allValidNFTs(uint256[] calldata tokenIds)
        external
        view
        returns (bool);
}


// File contracts/solidity/interface/INFTXLPStaking.sol



pragma solidity ^0.8.0;

interface INFTXLPStaking {
    function nftxVaultFactory() external view returns (address);
    function rewardDistTokenImpl() external view returns (address);
    function stakingTokenProvider() external view returns (address);
    function vaultToken(address _stakingToken) external view returns (address);
    function stakingToken(address _vaultToken) external view returns (address);
    function rewardDistributionToken(uint256 vaultId) external view returns (address);
    function rewardDistributionTokenAddr(address stakingToken, address rewardToken) external view returns (address);
    
    // Write functions.
    function __NFTXLPStaking__init(address _stakingTokenProvider) external;
    function setNFTXVaultFactory(address newFactory) external;
    function setStakingTokenProvider(address newProvider) external;
    function addPoolForVault(uint256 vaultId) external;
    function updatePoolForVault(uint256 vaultId) external;
    function updatePoolForVaults(uint256[] calldata vaultId) external;
    function receiveRewards(uint256 vaultId, uint256 amount) external returns (bool);
    function deposit(uint256 vaultId, uint256 amount) external;
    function depositFor(uint256 vaultId, uint256 amount, address to) external;
    function exit(uint256 vaultId, uint256 amount) external;
    function rescue(uint256 vaultId) external;
    function withdraw(uint256 vaultId, uint256 amount) external;
    function claimRewards(uint256 vaultId) external;
}


// File contracts/solidity/interface/IUniswapV2Router01.sol



pragma solidity ^0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB)
        external
        pure
        returns (uint256 amountB);
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}


// File contracts/solidity/testing/IERC165.sol



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


// File contracts/solidity/testing/IERC721.sol



pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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


// File contracts/solidity/interface/IERC165Upgradeable.sol



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
interface IERC165Upgradeable {
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


// File contracts/solidity/token/IERC1155Upgradeable.sol



pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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


// File contracts/solidity/token/IERC20Upgradeable.sol



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


// File contracts/solidity/token/IERC721ReceiverUpgradeable.sol



pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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


// File contracts/solidity/token/ERC721HolderUpgradeable.sol



pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is IERC721ReceiverUpgradeable {
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


// File contracts/solidity/token/IERC1155ReceiverUpgradeable.sol



pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {

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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
}


// File contracts/solidity/util/ERC165Upgradeable.sol



pragma solidity ^0.8.0;

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
abstract contract ERC165Upgradeable is IERC165Upgradeable {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
}


// File contracts/solidity/token/ERC1155ReceiverUpgradeable.sol



pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }
}


// File contracts/solidity/token/ERC1155HolderUpgradeable.sol



pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155HolderUpgradeable is ERC1155ReceiverUpgradeable {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}


// File contracts/solidity/proxy/Initializable.sol



// solhint-disable-next-line compiler-version
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


// File contracts/solidity/util/ContextUpgradeable.sol



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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


// File contracts/solidity/util/OwnableUpgradeable.sol



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
    uint256[49] private __gap;
}


// File contracts/solidity/NFTXStakingZap.sol



pragma solidity ^0.8.0;










// Authors: @0xKiwi_.

interface IWETH {
  function deposit() external payable;
  function transfer(address to, uint value) external returns (bool);
  function withdraw(uint) external;
}

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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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

contract NFTXStakingZap is Ownable, ReentrancyGuard, ERC721HolderUpgradeable, ERC1155HolderUpgradeable {
  IWETH public WETH; 
  INFTXLPStaking public lpStaking;
  INFTXVaultFactory public immutable nftxFactory;
  IUniswapV2Router01 public sushiRouter;

  uint256 public lockTime = 48 hours; 

  mapping(uint256 => mapping(address => uint256)) private zapLock;
  mapping(uint256 => mapping(address => uint256)) private lockedBalance;

  uint256 constant BASE = 10**18;

  event UserStaked(uint256 vaultId, uint256 count, uint256 lpBalance, uint256 timelockUntil, address sender);
  event Withdraw(uint256 vaultId, uint256 lpBalance, address sender);

  constructor(address _nftxFactory, address _sushiRouter) Ownable() ReentrancyGuard() {
    nftxFactory = INFTXVaultFactory(_nftxFactory);
    sushiRouter = IUniswapV2Router01(_sushiRouter);
    WETH = IWETH(sushiRouter.WETH());
    IERC20Upgradeable(address(WETH)).approve(address(sushiRouter), type(uint256).max);
  }

  function setLpStakingAddress(address newLpStaking) external onlyOwner {
    lpStaking = INFTXLPStaking(newLpStaking);
  } 

  function setLockTime(uint256 newLockTime) external onlyOwner {
    require(newLockTime <= 7 days, "Lock too long");
    lockTime = newLockTime;
  } 

  function addLiquidity721ETH(
    uint256 vaultId, 
    uint256[] memory ids, 
    uint256 minWethIn
  ) public payable nonReentrant returns (uint256) {
    WETH.deposit{value: msg.value}();
    (, uint256 amountEth, uint256 liquidity) = _addLiquidity721WETH(vaultId, ids, minWethIn, msg.value);

    // Return extras.
    if (amountEth < msg.value) {
      WETH.withdraw(msg.value-amountEth);
      msg.sender.call{value: msg.value-amountEth};
    }

    return liquidity;
  }

  function addLiquidity1155ETH(
    uint256 vaultId, 
    uint256[] memory ids, 
    uint256[] memory amounts,
    uint256 minEthIn
  ) public payable nonReentrant returns (uint256) {
    WETH.deposit{value: msg.value}();
    // Finish this.
    (, uint256 amountEth, uint256 liquidity) = _addLiquidity1155WETH(vaultId, ids, amounts, minEthIn, msg.value);

    // Return extras.
    if (amountEth < msg.value) {
      WETH.withdraw(msg.value-amountEth);
      msg.sender.call{value: msg.value-amountEth};
    }

    return liquidity;
  }

  function addLiquidity721(
    uint256 vaultId, 
    uint256[] memory ids, 
    uint256 minWethIn,
    uint256 wethIn
  ) public nonReentrant returns (uint256) {
    IERC20Upgradeable(address(WETH)).transferFrom(msg.sender, address(this), wethIn);
    (, uint256 amountEth, uint256 liquidity) = _addLiquidity721WETH(vaultId, ids, minWethIn, wethIn);

    // Return extras.
    if (amountEth < wethIn) {
      WETH.transfer(msg.sender, wethIn-amountEth);
    }

    return liquidity;
  }

  function addLiquidity1155(
    uint256 vaultId, 
    uint256[] memory ids,
    uint256[] memory amounts,
    uint256 minWethIn,
    uint256 wethIn
  ) public nonReentrant returns (uint256) {
    IERC20Upgradeable(address(WETH)).transferFrom(msg.sender, address(this), wethIn);
    (, uint256 amountEth, uint256 liquidity) = _addLiquidity1155WETH(vaultId, ids, amounts, minWethIn, wethIn);

    // Return extras.
    if (amountEth < wethIn) {
      WETH.transfer(msg.sender, wethIn-amountEth);
    }

    return liquidity;
  }

  function withdrawXLPTokens(uint256 vaultId) public {
    uint256 lockedBal = lockedBalance[vaultId][msg.sender];
    require(block.timestamp >= zapLock[vaultId][msg.sender], "NFTXZap: Locked");
    require(lockedBal > 0, "NFTXZap: Nothing locked");
    
    zapLock[vaultId][msg.sender] = 0;
    lockedBalance[vaultId][msg.sender] = 0;

    address xLPtoken = lpStaking.rewardDistributionToken(vaultId);
    IERC20Upgradeable(xLPtoken).transfer(msg.sender, lockedBal);

    emit Withdraw(vaultId, lockedBal, msg.sender);
  }

  function lockedUntil(uint256 vaultId, address who) external view returns (uint256) {
    return zapLock[vaultId][who];
  }

  function lockedLPBalance(uint256 vaultId, address who) external view returns (uint256) {
    return lockedBalance[vaultId][who];
  }

  function _addLiquidity721WETH(
    uint256 vaultId, 
    uint256[] memory ids, 
    uint256 minWethIn,
    uint256 wethIn
  ) internal returns (uint256, uint256, uint256) {
    address vault = nftxFactory.vault(vaultId);
    require(vault != address(0), "NFTXZap: Vault does not exist");

    // Transfer tokens to zap and mint to NFTX.
    address assetAddress = INFTXVault(vault).assetAddress();
    for (uint256 i = 0; i < ids.length; i++) {
      transferFromERC721(assetAddress, ids[i]);
      approveERC721(assetAddress, vault, ids[i]);
    }
    uint256[] memory emptyIds;
    uint256 count = INFTXVault(vault).mint(ids, emptyIds);
    uint256 balance = (count * BASE); // We should not be experiencing fees.
    require(balance == IERC20Upgradeable(vault).balanceOf(address(this)), "Did not receive expected balance");
    
    return _addLiquidityAndLock(vaultId, vault, balance, minWethIn, wethIn);
  }

  function _addLiquidity1155WETH(
    uint256 vaultId, 
    uint256[] memory ids,
    uint256[] memory amounts,
    uint256 minWethIn,
    uint256 wethIn
  ) internal returns (uint256, uint256, uint256) {
    address vault = nftxFactory.vault(vaultId);
    require(vault != address(0), "NFTXZap: Vault does not exist");

    // Transfer tokens to zap and mint to NFTX.
    address assetAddress = INFTXVault(vault).assetAddress();
    IERC1155Upgradeable(assetAddress).safeBatchTransferFrom(msg.sender, address(this), ids, amounts, "");
    IERC1155Upgradeable(assetAddress).setApprovalForAll(vault, true);
    uint256 count = INFTXVault(vault).mint(ids, amounts);
    uint256 balance = (count * BASE); // We should not be experiencing fees.
    require(balance == IERC20Upgradeable(vault).balanceOf(address(this)), "Did not receive expected balance");
    
    return _addLiquidityAndLock(vaultId, vault, balance, minWethIn, wethIn);
  }

  function _addLiquidityAndLock(
    uint256 vaultId, 
    address vault, 
    uint256 minTokenIn, 
    uint256 minWethIn, 
    uint256 wethIn
  ) internal returns (uint256, uint256, uint256) {
    // Provide liquidity.
    IERC20Upgradeable(vault).approve(address(sushiRouter), minTokenIn);
    (uint256 amountToken, uint256 amountEth, uint256 liquidity) = sushiRouter.addLiquidity(
      address(vault), 
      sushiRouter.WETH(),
      minTokenIn, 
      wethIn, 
      minTokenIn,
      minWethIn,
      address(this), 
      block.timestamp
    );

    // Stake in LP rewards contract 
    address lpToken = pairFor(vault, address(WETH));
    IERC20Upgradeable(lpToken).approve(address(lpStaking), liquidity);
    lpStaking.deposit(vaultId, liquidity);
    
    lockedBalance[vaultId][msg.sender] += liquidity;
    uint256 lockEndTime = block.timestamp + lockTime;
    zapLock[vaultId][msg.sender] = lockEndTime;

    if (amountToken < minTokenIn) {
      IERC20Upgradeable(vault).transfer(msg.sender, minTokenIn-amountToken);
    }

    emit UserStaked(vaultId, minTokenIn, liquidity, lockEndTime, msg.sender);
    return (amountToken, amountEth, liquidity);
  }

  function transferFromERC721(address assetAddr, uint256 tokenId) internal virtual {
    address kitties = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
    address punks = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    bytes memory data;
    if (assetAddr == kitties) {
        // Cryptokitties.
        data = abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), tokenId);
    } else if (assetAddr == punks) {
        // CryptoPunks.
        // Fix here for frontrun attack. Added in v1.0.2.
        bytes memory punkIndexToAddress = abi.encodeWithSignature("punkIndexToAddress(uint256)", tokenId);
        (bool checkSuccess, bytes memory result) = address(assetAddr).staticcall(punkIndexToAddress);
        (address owner) = abi.decode(result, (address));
        require(checkSuccess && owner == msg.sender, "Not the owner");
        data = abi.encodeWithSignature("buyPunk(uint256)", tokenId);
    } else {
        // Default.
        data = abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", msg.sender, address(this), tokenId);
    }
    (bool success, bytes memory resultData) = address(assetAddr).call(data);
    require(success, string(resultData));
  }

  function approveERC721(address assetAddr, address to, uint256 tokenId) internal virtual {
    address kitties = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
    address punks = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    bytes memory data;
    if (assetAddr == kitties) {
        // Cryptokitties.
        data = abi.encodeWithSignature("approve(address,uint256)", to, tokenId);
    } else if (assetAddr == punks) {
        // CryptoPunks.
        data = abi.encodeWithSignature("offerPunkForSaleToAddress(uint256,uint256,address)", tokenId, 0, to);
    } else {
        if (IERC721(assetAddr).isApprovedForAll(address(this), to)) {
          return;
        }
        // Default.
        data = abi.encodeWithSignature("setApprovalForAll(address,bool)", to, true);
    }
    (bool success, bytes memory resultData) = address(assetAddr).call(data);
    require(success, string(resultData));
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(address tokenA, address tokenB) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = address(uint160(uint256(keccak256(abi.encodePacked(
      hex'ff',
      0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac,
      keccak256(abi.encodePacked(token0, token1)),
      hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303' // init code hash
    )))));
  }

  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
      require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
      (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
      require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
  }
}