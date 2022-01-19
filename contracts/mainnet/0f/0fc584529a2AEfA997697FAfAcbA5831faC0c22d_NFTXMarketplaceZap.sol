/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// Sources flattened with hardhat v2.8.2 https://hardhat.org

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
  function allVaults() external view returns (address[] memory);
  function vaultsForAsset(address asset) external view returns (address[] memory);
  function isLocked(uint256 id) external view returns (bool);
  function excludedFromFees(address addr) external view returns (bool);
  function factoryMintFee() external view returns (uint64);
  function factoryRandomRedeemFee() external view returns (uint64);
  function factoryTargetRedeemFee() external view returns (uint64);
  function factoryRandomSwapFee() external view returns (uint64);
  function factoryTargetSwapFee() external view returns (uint64);
  function vaultFees(uint256 vaultId) external view returns (uint256, uint256, uint256, uint256, uint256);

  event NewFeeDistributor(address oldDistributor, address newDistributor);
  event NewZapContract(address oldZap, address newZap);
  event FeeExclusion(address feeExcluded, bool excluded);
  event NewEligibilityManager(address oldEligManager, address newEligManager);
  event NewVault(uint256 indexed vaultId, address vaultAddress, address assetAddress);
  event UpdateVaultFees(uint256 vaultId, uint256 mintFee, uint256 randomRedeemFee, uint256 targetRedeemFee, uint256 randomSwapFee, uint256 targetSwapFee);
  event DisableVaultFees(uint256 vaultId);
  event UpdateFactoryFees(uint256 mintFee, uint256 randomRedeemFee, uint256 targetRedeemFee, uint256 randomSwapFee, uint256 targetSwapFee);

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

  function setFactoryFees(
    uint256 mintFee, 
    uint256 randomRedeemFee, 
    uint256 targetRedeemFee,
    uint256 randomSwapFee, 
    uint256 targetSwapFee
  ) external; 
  function setVaultFees(
      uint256 vaultId, 
      uint256 mintFee, 
      uint256 randomRedeemFee, 
      uint256 targetRedeemFee,
      uint256 randomSwapFee, 
      uint256 targetSwapFee
  ) external;
  function disableVaultFees(uint256 vaultId) external;
}


// File contracts/solidity/interface/INFTXVault.sol



pragma solidity ^0.8.0;



interface INFTXVault is IERC20Upgradeable {
    function manager() external view returns (address);
    function assetAddress() external view returns (address);
    function vaultFactory() external view returns (INFTXVaultFactory);
    function eligibilityStorage() external view returns (INFTXEligibility);

    function is1155() external view returns (bool);
    function allowAllItems() external view returns (bool);
    function enableMint() external view returns (bool);
    function enableRandomRedeem() external view returns (bool);
    function enableTargetRedeem() external view returns (bool);
    function enableRandomSwap() external view returns (bool);
    function enableTargetSwap() external view returns (bool);

    function vaultId() external view returns (uint256);
    function nftIdAt(uint256 holdingsIndex) external view returns (uint256);
    function allHoldings() external view returns (uint256[] memory);
    function totalHoldings() external view returns (uint256);
    function mintFee() external view returns (uint256);
    function randomRedeemFee() external view returns (uint256);
    function targetRedeemFee() external view returns (uint256);
    function randomSwapFee() external view returns (uint256);
    function targetSwapFee() external view returns (uint256);
    function vaultFees() external view returns (uint256, uint256, uint256, uint256, uint256);

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
    event EnableRandomSwapUpdated(bool enabled);
    event EnableTargetSwapUpdated(bool enabled);

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
        bool _enableTargetRedeem,
        bool _enableRandomSwap,
        bool _enableTargetSwap
    ) external;

    function setFees(
        uint256 _mintFee,
        uint256 _randomRedeemFee,
        uint256 _targetRedeemFee,
        uint256 _randomSwapFee,
        uint256 _targetSwapFee
    ) external;
    function disableVaultFees() external;

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


// File contracts/solidity/interface/INFTXFeeDistributor.sol



pragma solidity ^0.8.0;

interface INFTXFeeDistributor {
  
  struct FeeReceiver {
    uint256 allocPoint;
    address receiver;
    bool isContract;
  }

  function nftxVaultFactory() external returns (address);
  function lpStaking() external returns (address);
  function treasury() external returns (address);
  function defaultTreasuryAlloc() external returns (uint256);
  function defaultLPAlloc() external returns (uint256);
  function allocTotal(uint256 vaultId) external returns (uint256);
  function specificTreasuryAlloc(uint256 vaultId) external returns (uint256);

  // Write functions.
  function __FeeDistributor__init__(address _lpStaking, address _treasury) external;
  function rescueTokens(address token) external;
  function distribute(uint256 vaultId) external;
  function addReceiver(uint256 _vaultId, uint256 _allocPoint, address _receiver, bool _isContract) external;
  function initializeVaultReceivers(uint256 _vaultId) external;
  function changeMultipleReceiverAlloc(
    uint256[] memory _vaultIds, 
    uint256[] memory _receiverIdxs, 
    uint256[] memory allocPoints
  ) external;

  function changeMultipleReceiverAddress(
    uint256[] memory _vaultIds, 
    uint256[] memory _receiverIdxs, 
    address[] memory addresses, 
    bool[] memory isContracts
  ) external;
  function changeReceiverAlloc(uint256 _vaultId, uint256 _idx, uint256 _allocPoint) external;
  function changeReceiverAddress(uint256 _vaultId, uint256 _idx, address _address, bool _isContract) external;
  function removeReceiver(uint256 _vaultId, uint256 _receiverIdx) external;

  // Configuration functions.
  function setTreasuryAddress(address _treasury) external;
  function setDefaultTreasuryAlloc(uint256 _allocPoint) external;
  function setSpecificTreasuryAlloc(uint256 _vaultId, uint256 _allocPoint) external;
  function setLPStakingAddress(address _lpStaking) external;
  function setNFTXVaultFactory(address _factory) external;
  function setDefaultLPAlloc(uint256 _allocPoint) external;
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
    function newRewardDistributionToken(uint256 vaultId) external view returns (address);
    function oldRewardDistributionToken(uint256 vaultId) external view returns (address);
    function unusedRewardDistributionToken(uint256 vaultId) external view returns (address);
    function rewardDistributionTokenAddr(address stakedToken, address rewardToken) external view returns (address);
    
    // Write functions.
    function __NFTXLPStaking__init(address _stakingTokenProvider) external;
    function setNFTXVaultFactory(address newFactory) external;
    function setStakingTokenProvider(address newProvider) external;
    function addPoolForVault(uint256 vaultId) external;
    function updatePoolForVault(uint256 vaultId) external;
    function updatePoolForVaults(uint256[] calldata vaultId) external;
    function receiveRewards(uint256 vaultId, uint256 amount) external returns (bool);
    function deposit(uint256 vaultId, uint256 amount) external;
    function timelockDepositFor(uint256 vaultId, address account, uint256 amount, uint256 timelockLength) external;
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


// File contracts/solidity/util/Address.sol



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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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


// File contracts/solidity/util/SafeERC20Upgradeable.sol



pragma solidity ^0.8.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using Address for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/solidity/NFTXMarketplaceZap.sol



pragma solidity ^0.8.0;










// Authors: @0xKiwi_.

interface IWETH {
  function deposit() external payable;
  function transfer(address to, uint value) external returns (bool);
  function withdraw(uint) external;
  function balanceOf(address to) external view returns (uint256);
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

contract NFTXMarketplaceZap is Ownable, ReentrancyGuard, ERC721HolderUpgradeable, ERC1155HolderUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  
  IWETH public immutable WETH; 
  INFTXLPStaking public immutable lpStaking;
  INFTXVaultFactory public immutable nftxFactory;
  IUniswapV2Router01 public immutable sushiRouter;

  uint256 constant BASE = 1e18;

  event Buy(uint256 count, uint256 ethSpent, address to);
  event Sell(uint256 count, uint256 ethReceived, address to);
  event Swap(uint256 count, uint256 ethSpent, address to);

  constructor(address _nftxFactory, address _sushiRouter) Ownable() ReentrancyGuard() {
    nftxFactory = INFTXVaultFactory(_nftxFactory);
    lpStaking = INFTXLPStaking(INFTXFeeDistributor(INFTXVaultFactory(_nftxFactory).feeDistributor()).lpStaking());
    sushiRouter = IUniswapV2Router01(_sushiRouter);
    WETH = IWETH(IUniswapV2Router01(_sushiRouter).WETH());
    IERC20Upgradeable(address(IUniswapV2Router01(_sushiRouter).WETH())).safeApprove(_sushiRouter, type(uint256).max);
  }

  function mintAndSell721(
    uint256 vaultId, 
    uint256[] calldata ids, 
    uint256 minEthOut, 
    address[] calldata path,
    address to
  ) external nonReentrant {
    require(to != address(0) && to != address(this));
    require(ids.length != 0);
    (address vault, uint256 vaultBalance) = _mint721(vaultId, ids);
    uint256[] memory amounts = _sellVaultTokenETH(vault, minEthOut, vaultBalance, path, to);
    emit Sell(ids.length, amounts[amounts.length-1], to);
  }

  function mintAndSell721WETH(
    uint256 vaultId, 
    uint256[] calldata ids, 
    uint256 minWethOut, 
    address[] calldata path,
    address to
  ) external nonReentrant {
    require(to != address(0) && to != address(this));
    require(ids.length != 0);
    (address vault, uint256 vaultBalance) = _mint721(vaultId, ids);
    uint256[] memory amounts = _sellVaultTokenWETH(vault, minWethOut, vaultBalance, path, to);
    emit Sell(ids.length, amounts[amounts.length-1], to);
  }

  function buyAndSwap721(
    uint256 vaultId, 
    uint256[] calldata idsIn, 
    uint256[] calldata specificIds, 
    address[] calldata path,
    address to
  ) external payable nonReentrant {
    require(to != address(0) && to != address(this));
    require(idsIn.length != 0);
    WETH.deposit{value: msg.value}();
    INFTXVault vault = INFTXVault(nftxFactory.vault(vaultId));
    uint256 redeemFees = (vault.targetSwapFee() * specificIds.length) + (
        vault.randomSwapFee() * (idsIn.length - specificIds.length)
    );
    uint256[] memory amounts = _buyVaultToken(redeemFees, msg.value, path);
    _swap721(vaultId, idsIn, specificIds, to);

    emit Swap(idsIn.length, amounts[0], to);

    // Return extras.
    uint256 remaining = WETH.balanceOf(address(this));
    WETH.withdraw(remaining);
    (bool success, ) = payable(to).call{value: remaining}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  function buyAndSwap721WETH(
    uint256 vaultId, 
    uint256[] calldata idsIn, 
    uint256[] calldata specificIds, 
    uint256 maxWethIn, 
    address[] calldata path,
    address to
  ) external nonReentrant {
    require(to != address(0) && to != address(this));
    require(idsIn.length != 0);
    IERC20Upgradeable(address(WETH)).safeTransferFrom(msg.sender, address(this), maxWethIn);
    INFTXVault vault = INFTXVault(nftxFactory.vault(vaultId));
    uint256 redeemFees = (vault.targetSwapFee() * specificIds.length) + (
        vault.randomSwapFee() * (idsIn.length - specificIds.length)
    );
    uint256[] memory amounts = _buyVaultToken(redeemFees, maxWethIn, path);
    _swap721(vaultId, idsIn, specificIds, to);

    emit Swap(idsIn.length, amounts[0], to);

    // Return extras.
    uint256 remaining = WETH.balanceOf(address(this));
    if (remaining != 0) {
      WETH.transfer(to, remaining);
    }
  }

  function buyAndSwap1155(
    uint256 vaultId, 
    uint256[] calldata idsIn, 
    uint256[] calldata amounts, 
    uint256[] calldata specificIds, 
    address[] calldata path,
    address to
  ) external payable nonReentrant {
    require(to != address(0) && to != address(this));
    uint256 length = idsIn.length;
    require(length != 0);
    WETH.deposit{value: msg.value}();
    uint256 count;
    for (uint256 i; i < length; ++i) {
        uint256 amount = amounts[i];
        require(amount > 0, "Transferring < 1");
        count += amount;
    }
    INFTXVault vault = INFTXVault(nftxFactory.vault(vaultId));
    uint256 redeemFees = (vault.targetSwapFee() * specificIds.length) + (
        vault.randomSwapFee() * (count - specificIds.length)
    );
    uint256[] memory swapAmounts = _buyVaultToken(redeemFees, msg.value, path);
    _swap1155(vaultId, idsIn, amounts, specificIds, to);

    emit Swap(count, swapAmounts[0], to);

    // Return extras.
    uint256 remaining = WETH.balanceOf(address(this));
    WETH.withdraw(remaining);
    (bool success, ) = payable(to).call{value: remaining}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  function buyAndSwap1155WETH(
    uint256 vaultId, 
    uint256[] calldata idsIn, 
    uint256[] calldata amounts, 
    uint256[] calldata specificIds, 
    uint256 maxWethIn, 
    address[] calldata path,
    address to
  ) external payable nonReentrant {
    require(to != address(0) && to != address(this));
    require(idsIn.length != 0);
    uint256 count;
    for (uint256 i = 0; i < idsIn.length; i++) {
        uint256 amount = amounts[i];
        require(amount > 0, "Transferring < 1");
        count += amount;
    }
    INFTXVault vault = INFTXVault(nftxFactory.vault(vaultId));
    uint256 redeemFees = (vault.targetSwapFee() * specificIds.length) + (
        vault.randomSwapFee() * (count - specificIds.length)
    );
    IERC20Upgradeable(address(WETH)).safeTransferFrom(msg.sender, address(this), maxWethIn);
    uint256[] memory swapAmounts = _buyVaultToken(redeemFees, maxWethIn, path);
    _swap1155(vaultId, idsIn, amounts, specificIds, to);

    emit Swap(count, swapAmounts[0], to);

    // Return extras.
    uint256 remaining = WETH.balanceOf(address(this));
    WETH.transfer(to, remaining);
  }

  function buyAndRedeem(
    uint256 vaultId, 
    uint256 amount,
    uint256[] calldata specificIds, 
    address[] calldata path,
    address to
  ) external payable nonReentrant {
    require(to != address(0) && to != address(this));
    require(amount != 0);
    WETH.deposit{value: msg.value}();
    (, uint256 randomRedeemFee, uint256 targetRedeemFee, ,) = nftxFactory.vaultFees(vaultId);
    uint256 totalFee = (targetRedeemFee * specificIds.length) + (
        randomRedeemFee * (amount - specificIds.length)
    );
    uint256[] memory amounts = _buyVaultToken((amount*BASE)+totalFee, msg.value, path);
    _redeem(vaultId, amount, specificIds, to);

    emit Buy(amount, amounts[0], to);

    uint256 remaining = WETH.balanceOf(address(this));
    if (remaining != 0) {
      WETH.withdraw(remaining);
      (bool success, ) = payable(to).call{value: remaining}("");
      require(success, "Address: unable to send value, recipient may have reverted");
    }
  }

  function buyAndRedeemWETH(
    uint256 vaultId, 
    uint256 amount,
    uint256[] calldata specificIds, 
    uint256 maxWethIn, 
    address[] calldata path,
    address to
  ) external nonReentrant {
    require(to != address(0) && to != address(this));
    require(amount != 0);
    uint256 totalFee;
    {
    (, uint256 randomRedeemFee, uint256 targetRedeemFee, ,) = nftxFactory.vaultFees(vaultId);
      totalFee = (targetRedeemFee * specificIds.length) + (
        randomRedeemFee * (amount - specificIds.length)
    );
    }
    IERC20Upgradeable(address(WETH)).safeTransferFrom(msg.sender, address(this), maxWethIn);
    uint256[] memory amounts = _buyVaultToken((amount*BASE) + totalFee, maxWethIn, path);
    _redeem(vaultId, amount, specificIds, to);
    emit Buy(amount, amounts[0], to);

    uint256 remaining = WETH.balanceOf(address(this));
    if (remaining != 0) {
      WETH.transfer(to, remaining);
    }
  }

  function mintAndSell1155(
    uint256 vaultId, 
    uint256[] calldata ids, 
    uint256[] calldata amounts,
    uint256 minWethOut, 
    address[] calldata path,
    address to
  ) external nonReentrant {
    require(to != address(0) && to != address(this));
    require(ids.length != 0);
    (address vault, uint256 vaultTokenBalance) = _mint1155(vaultId, ids, amounts);
    uint256[] memory uniAmounts = _sellVaultTokenETH(vault, minWethOut, vaultTokenBalance, path, to);

    uint256 count;
    uint256 length = ids.length;
    for (uint256 i; i < length; ++i) {
        count += amounts[i];
    }
    emit Sell(count, uniAmounts[uniAmounts.length-1], to);
  }

  function mintAndSell1155WETH(
    uint256 vaultId, 
    uint256[] calldata ids, 
    uint256[] calldata amounts,
    uint256 minWethOut, 
    address[] calldata path,
    address to
  ) external nonReentrant {
    require(to != address(0) && to != address(this));
    require(ids.length != 0);
    (address vault, uint256 vaultTokenBalance) = _mint1155(vaultId, ids, amounts);
    _sellVaultTokenWETH(vault, minWethOut, vaultTokenBalance, path, to);

    uint256 count;
    uint256 length = ids.length;
    for (uint256 i; i < length; ++i) {
        count += amounts[i];
    }
    emit Sell(count, amounts[amounts.length-1], to);
  }

  function _mint721(
    uint256 vaultId, 
    uint256[] memory ids
  ) internal returns (address, uint256) {
    address vault = nftxFactory.vault(vaultId);

    // Transfer tokens to zap and mint to NFTX.
    address assetAddress = INFTXVault(vault).assetAddress();
    uint256 length = ids.length;
    for (uint256 i; i < length; ++i) {
      transferFromERC721(assetAddress, ids[i], vault);
      approveERC721(assetAddress, vault, ids[i]);
    }
    uint256[] memory emptyIds;
    INFTXVault(vault).mint(ids, emptyIds);
    uint256 count = ids.length;
    uint256 balance = (count * BASE) - (count * INFTXVault(vault).mintFee()); 
    
    return (vault, balance);
  }

  function _swap721(
    uint256 vaultId, 
    uint256[] memory idsIn,
    uint256[] memory idsOut,
    address to
  ) internal returns (address) {
    address vault = nftxFactory.vault(vaultId);

    // Transfer tokens to zap and mint to NFTX.
    address assetAddress = INFTXVault(vault).assetAddress();
    uint256 length = idsIn.length;
    for (uint256 i; i < length; ++i) {
      transferFromERC721(assetAddress, idsIn[i], vault);
      approveERC721(assetAddress, vault, idsIn[i]);
    }
    uint256[] memory emptyIds;
    INFTXVault(vault).swapTo(idsIn, emptyIds, idsOut, to);
    
    return (vault);
  }

  function _swap1155(
    uint256 vaultId, 
    uint256[] memory idsIn,
    uint256[] memory amounts,
    uint256[] memory idsOut,
    address to
  ) internal returns (address) {
    address vault = nftxFactory.vault(vaultId);

    // Transfer tokens to zap and mint to NFTX.
    address assetAddress = INFTXVault(vault).assetAddress();
    IERC1155Upgradeable(assetAddress).safeBatchTransferFrom(msg.sender, address(this), idsIn, amounts, "");
    IERC1155Upgradeable(assetAddress).setApprovalForAll(vault, true);
    INFTXVault(vault).swapTo(idsIn, amounts, idsOut, to);
    
    return (vault);
  }

  function _redeem(
    uint256 vaultId, 
    uint256 amount,
    uint256[] memory specificIds,
    address to
  ) internal {
    address vault = nftxFactory.vault(vaultId);
    INFTXVault(vault).redeemTo(amount, specificIds, to);
  }

  function _mint1155(
    uint256 vaultId, 
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal returns (address, uint256) {
    address vault = nftxFactory.vault(vaultId);
    require(vault != address(0), "NFTXZap: Vault does not exist");

    // Transfer tokens to zap and mint to NFTX.
    address assetAddress = INFTXVault(vault).assetAddress();
    IERC1155Upgradeable(assetAddress).safeBatchTransferFrom(msg.sender, address(this), ids, amounts, "");
    IERC1155Upgradeable(assetAddress).setApprovalForAll(vault, true);

    uint256 count = INFTXVault(vault).mint(ids, amounts);
    uint256 balance = (count * BASE) - (INFTXVault(vault).mintFee()*count);
    
    return (vault, balance);
  }

  function _buyVaultToken(
    uint256 minTokenOut, 
    uint256 maxWethIn, 
    address[] calldata path
  ) internal returns (uint256[] memory) {
    uint256[] memory amounts = sushiRouter.swapTokensForExactTokens(
      minTokenOut,
      maxWethIn,
      path, 
      address(this),
      block.timestamp
    );

    return amounts;
  }
  function _sellVaultTokenWETH(
    address vault, 
    uint256 minWethOut, 
    uint256 maxTokenIn, 
    address[] calldata path,
    address to
  ) internal returns (uint256[] memory) {
    IERC20Upgradeable(vault).safeApprove(address(sushiRouter), maxTokenIn);
    uint256[] memory amounts = sushiRouter.swapExactTokensForTokens(
      maxTokenIn,
      minWethOut,
      path, 
      to,
      block.timestamp
    );

    return amounts;
  }

  function _sellVaultTokenETH(
    address vault, 
    uint256 minEthOut, 
    uint256 maxTokenIn, 
    address[] calldata path,
    address to
  ) internal returns (uint256[] memory) {
    IERC20Upgradeable(vault).safeApprove(address(sushiRouter), maxTokenIn);
    uint256[] memory amounts = sushiRouter.swapExactTokensForETH(
      maxTokenIn,
      minEthOut,
      path, 
      to,
      block.timestamp
    );

    return amounts;
  }

  function transferFromERC721(address assetAddr, uint256 tokenId, address to) internal virtual {
    address kitties = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
    address punks = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    bytes memory data;
    if (assetAddr == kitties) {
        // Cryptokitties.
        data = abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, to, tokenId);
    } else if (assetAddr == punks) {
        // CryptoPunks.
        // Fix here for frontrun attack. Added in v1.0.2.
        bytes memory punkIndexToAddress = abi.encodeWithSignature("punkIndexToAddress(uint256)", tokenId);
        (bool checkSuccess, bytes memory result) = address(assetAddr).staticcall(punkIndexToAddress);
        (address nftOwner) = abi.decode(result, (address));
        require(checkSuccess && nftOwner == msg.sender, "Not the NFT owner");
        data = abi.encodeWithSignature("buyPunk(uint256)", tokenId);
    } else {
        // Default.
        // We push to the vault to avoid an unneeded transfer.
        data = abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", msg.sender, to, tokenId);
    }
    (bool success, bytes memory resultData) = address(assetAddr).call(data);
    require(success, string(resultData));
  }

  function approveERC721(address assetAddr, address to, uint256 tokenId) internal virtual {
    address kitties = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
    address punks = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    bytes memory data;
    if (assetAddr == kitties) {
        // // Cryptokitties.
        // data = abi.encodeWithSignature("approve(address,uint256)", to, tokenId);
        // No longer needed to approve with pushing.
        return;
    } else if (assetAddr == punks) {
        // CryptoPunks.
        data = abi.encodeWithSignature("offerPunkForSaleToAddress(uint256,uint256,address)", tokenId, 0, to);
    } else {
      // No longer needed to approve with pushing.
      return;
    }
    (bool success, bytes memory resultData) = address(assetAddr).call(data);
    require(success, string(resultData));
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(address tokenA, address tokenB) internal view returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = address(uint160(uint256(keccak256(abi.encodePacked(
      hex'ff',
      sushiRouter.factory(),
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

  function rescue(address token) external onlyOwner {
    if (token == address(0)) {
      (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
      require(success, "Address: unable to send value, recipient may have reverted");
    } else {
      IERC20Upgradeable(token).safeTransfer(msg.sender, IERC20Upgradeable(token).balanceOf(address(this)));
    }
  }

  receive() external payable {
    require(msg.sender == address(WETH), "Only WETH");
  }
}