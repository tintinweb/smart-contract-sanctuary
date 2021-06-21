/**
 *Submitted for verification at Etherscan.io on 2021-06-20
*/

// File: contracts\farming\FarmData.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

struct FarmingPositionRequest {
    uint256 setupIndex; // index of the chosen setup.
    uint256 amount0; // amount of main token or liquidity pool token.
    uint256 amount1; // amount of other token or liquidity pool token. Needed for gen2
    address positionOwner; // position extension or address(0) [msg.sender].
}

struct FarmingSetupConfiguration {
    bool add; // true if we're adding a new setup, false we're updating it.
    bool disable;
    uint256 index; // index of the setup we're updating.
    FarmingSetupInfo info; // data of the new or updated setup
}

struct FarmingSetupInfo {
    uint256 blockDuration; // duration of setup
    uint256 startBlock; // optional start block used for the delayed activation of the first setup
    uint256 originalRewardPerBlock;
    uint256 minStakeable; // minimum amount of staking tokens.
    uint256 renewTimes; // if the setup is renewable or if it's one time.
    address liquidityPoolTokenAddress; // address of the liquidity pool token
    address mainTokenAddress; // eg. buidl address.
    bool involvingETH; // if the setup involves ETH or not.
    uint256 setupsCount; // number of setups created by this info.
    uint256 lastSetupIndex; // index of last setup;
    int24 tickLower; // Gen2 Only - tickLower of the UniswapV3 pool
    int24 tickUpper; // Gen 2 Only - tickUpper of the UniswapV3 pool
}

struct FarmingSetup {
    uint256 infoIndex; // setup info
    bool active; // if the setup is active or not.
    uint256 startBlock; // farming setup start block.
    uint256 endBlock; // farming setup end block.
    uint256 lastUpdateBlock; // number of the block where an update was triggered.
    uint256 objectId; // need for gen2. uniswapV3 NFT position Id
    uint256 rewardPerBlock; // farming setup reward per single block.
    uint128 totalSupply; // Total LP token liquidity of all the positions of this setup
}

struct FarmingPosition {
    address uniqueOwner; // address representing the owner of the position.
    uint256 setupIndex; // the setup index related to this position.
    uint256 creationBlock; // block when this position was created.
    uint128 liquidityPoolTokenAmount; // amount of liquidity pool token in the position.
    uint256 reward; // position reward.
}

// File: contracts\farming\IFarmMain.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;


interface IFarmMain {

    function ONE_HUNDRED() external view returns(uint256);
    function _rewardTokenAddress() external view returns(address);
    function position(uint256 positionId) external view returns (FarmingPosition memory);
    function setups() external view returns (FarmingSetup[] memory);
    function setup(uint256 setupIndex) external view returns (FarmingSetup memory, FarmingSetupInfo memory);
    function setFarmingSetups(FarmingSetupConfiguration[] memory farmingSetups) external;
    function openPosition(FarmingPositionRequest calldata request) external payable returns(uint256 positionId);
    function addLiquidity(uint256 positionId, FarmingPositionRequest calldata request) external payable;
}

// File: contracts\farming\IFarmExtension.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
//pragma abicoder v2;


interface IFarmExtension {

    function init(bool byMint, address host, address treasury) external;

    function setHost(address host) external;
    function setTreasury(address treasury) external;

    function data() external view returns(address farmMainContract, bool byMint, address host, address treasury, address rewardTokenAddress);

    function transferTo(uint256 amount) external;
    function backToYou(uint256 amount) external payable;

    function setFarmingSetups(FarmingSetupConfiguration[] memory farmingSetups) external;
}

// File: contracts\farming\IFarmFactory.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;

interface IFarmFactory {

    event ExtensionCloned(address indexed);

    function feePercentageInfo() external view returns (uint256, address);
    function farmDefaultExtension() external view returns(address);
    function cloneFarmDefaultExtension() external returns(address);
    function getFarmTokenCollectionURI() external view returns (string memory);
    function getFarmTokenURI() external view returns (string memory);
}

// File: contracts\farming\util\IERC20.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function safeApprove(address spender, uint256 amount) external;

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);
}

// File: node_modules\@openzeppelin\contracts\introspection\IERC165.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.7.0;

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

// File: node_modules\@openzeppelin\contracts\token\ERC721\IERC721.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.7.0;


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

// File: @openzeppelin\contracts\token\ERC721\IERC721Metadata.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.7.0;


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

// File: @openzeppelin\contracts\token\ERC721\IERC721Enumerable.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.7.0;


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

// File: node_modules\@uniswap\v3-periphery\contracts\interfaces\IPoolInitializer.sol

// SPDX_License_Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
//pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// File: node_modules\@uniswap\v3-periphery\contracts\interfaces\IERC721Permit.sol

// SPDX_License_Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;


/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// File: node_modules\@uniswap\v3-periphery\contracts\interfaces\IPeripheryPayments.sol

// SPDX_License_Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// File: node_modules\@uniswap\v3-periphery\contracts\interfaces\IPeripheryImmutableState.sol

// SPDX_License_Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// File: node_modules\@uniswap\v3-periphery\contracts\libraries\PoolAddress.sol

// SPDX_License_Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

// File: @uniswap\v3-periphery\contracts\interfaces\INonfungiblePositionManager.sol

// SPDX_License_Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
//pragma abicoder v2;








/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// File: contracts\farming\util\IUniswapV3Library.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;


interface IUniswapV3Library {
    function fetchUpdatedFeesInfo(INonfungiblePositionManager nonFungiblePositionManager, uint256 nftId) external view returns (uint256 tokensOwed0, uint256 tokensOwed1);
}

// File: node_modules\@uniswap\v3-core\contracts\interfaces\pool\IUniswapV3PoolImmutables.sol

// SPDX_License_Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// File: node_modules\@uniswap\v3-core\contracts\interfaces\pool\IUniswapV3PoolState.sol

// SPDX_License_Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// File: node_modules\@uniswap\v3-core\contracts\interfaces\pool\IUniswapV3PoolDerivedState.sol

// SPDX_License_Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// File: node_modules\@uniswap\v3-core\contracts\interfaces\pool\IUniswapV3PoolActions.sol

// SPDX_License_Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// File: node_modules\@uniswap\v3-core\contracts\interfaces\pool\IUniswapV3PoolOwnerActions.sol

// SPDX_License_Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// File: node_modules\@uniswap\v3-core\contracts\interfaces\pool\IUniswapV3PoolEvents.sol

// SPDX_License_Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// File: @uniswap\v3-core\contracts\interfaces\IUniswapV3Pool.sol

// SPDX_License_Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;







/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// File: @uniswap\v3-core\contracts\libraries\TickMath.sol

// SPDX_License_Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// File: @uniswap\v3-periphery\contracts\interfaces\IMulticall.sol

// SPDX_License_Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
//pragma abicoder v2;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

// File: contracts\farming\FarmMain.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
//pragma abicoder v2;










contract FarmMain is IFarmMain {

    // percentage
    uint256 public override constant ONE_HUNDRED = 1e18;
    // event that tracks contracts deployed for the given reward token
    event RewardToken(address indexed rewardTokenAddress);
    // new or transferred farming position event
    event Transfer(uint256 indexed positionId, address indexed from, address indexed to);
    // event that tracks involved tokens for this contract
    event SetupToken(address indexed mainToken, address indexed involvedToken);
    // factory address that will create clones of this contract
    address public _factory;
    // address of the extension of this contract
    address public _extension;
    // address of the reward token
    address public override _rewardTokenAddress;
    // address of the NonfungblePositionManager used for gen2
    INonfungiblePositionManager public nonfungiblePositionManager;
    // mapping containing all the currently available farming setups info
    mapping(uint256 => FarmingSetupInfo) private _setupsInfo;
    // counter for the farming setup info
    uint256 public _farmingSetupsInfoCount;
    // mapping containing all the currently available farming setups
    mapping(uint256 => FarmingSetup) private _setups;
    // counter for the farming setups
    uint256 public _farmingSetupsCount;
    // mapping containing all the positions
    mapping(uint256 => FarmingPosition) private _positions;
    // mapping containing the reward per token per setup per block
    mapping(uint256 => uint256) private _rewardPerTokenPerSetup;
    // mapping containing the reward per token paid per position
    mapping(uint256 => uint256) private _rewardPerTokenPaid;
    // mapping containing all the number of opened positions for each setups
    mapping(uint256 => uint256) private _setupPositionsCount;
    // mapping containing all the reward received/paid per setup
    mapping(uint256 => uint256) public _rewardReceived;
    mapping(uint256 => uint256) public _rewardPaid;

    address private _libraryAddress;
    address private _WETH;

    /** Modifiers. */

    /** @dev byExtension modifier used to check for unauthorized changes. */
    modifier byExtension() {
        require(msg.sender == _extension, "Unauthorized");
        _;
    }

    /** @dev byPositionOwner modifier used to check for unauthorized accesses. */
    modifier byPositionOwner(uint256 positionId) {
        require(_positions[positionId].uniqueOwner == msg.sender && _positions[positionId].creationBlock != 0, "Not owned");
        _;
    }

    /** @dev activeSetupOnly modifier used to check for function calls only if the setup is active. */
    modifier activeSetupOnly(uint256 setupIndex) {
        require(_setups[setupIndex].active, "Setup not active");
        require(_setups[setupIndex].startBlock <= block.number && _setups[setupIndex].endBlock > block.number, "Invalid setup");
        _;
    }

    receive() external payable {}

    /** Extension methods */

    /** @dev initializes the farming contract.
      * @param extension extension address.
      * @param extensionInitData lm extension init payload.
      * @param uniswapV3NonfungiblePositionManager Uniswap V3 Nonfungible Position Manager address.
      * @param rewardTokenAddress address of the reward token.
      * @param farmingSetupInfosBytes optional initial farming Setup Info
      * @return extensionReturnCall result of the extension initialization function, if it was called.
     */
    function init(address extension, bytes memory extensionInitData, address uniswapV3NonfungiblePositionManager, address libraryAddress, address rewardTokenAddress, bytes memory farmingSetupInfosBytes) public returns(bytes memory extensionReturnCall) {
        require(_factory == address(0), "Already initialized");
        require((_extension = extension) != address(0), "extension");
        _factory = msg.sender;
        emit RewardToken(_rewardTokenAddress = rewardTokenAddress);
        if (keccak256(extensionInitData) != keccak256("")) {
            extensionReturnCall = _call(_extension, extensionInitData);
        }
        _WETH = (nonfungiblePositionManager = INonfungiblePositionManager(uniswapV3NonfungiblePositionManager)).WETH9();
        if(farmingSetupInfosBytes.length > 0) {
            FarmingSetupInfo[] memory farmingSetupInfos = abi.decode(farmingSetupInfosBytes, (FarmingSetupInfo[]));
            for(uint256 i = 0; i < farmingSetupInfos.length; i++) {
                _setOrAddFarmingSetupInfo(farmingSetupInfos[i], true, false, 0);
            }
        }
        _libraryAddress = libraryAddress;
    }

    function setFarmingSetups(FarmingSetupConfiguration[] memory farmingSetups) public override byExtension {
        for (uint256 i = 0; i < farmingSetups.length; i++) {
            _setOrAddFarmingSetupInfo(farmingSetups[i].info, farmingSetups[i].add, farmingSetups[i].disable, farmingSetups[i].index);
        }
    }

    function finalFlush(address[] calldata tokens, uint256[] calldata amounts) public {
        for(uint256 i = 0; i < _farmingSetupsCount; i++) {
            require(_setupPositionsCount[i] == 0 && !_setups[i].active && _setups[i].totalSupply == 0, "Not Empty");
        }
        (,,, address receiver,) = IFarmExtension(_extension).data();
        require(tokens.length == amounts.length, "length");
        for(uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 amount = amounts[i];
            require(receiver != address(0));
            if(token == address(0)) {
                (bool result,) = receiver.call{value : amount}("");
                require(result, "ETH");
            } else {
                _safeTransfer(token, receiver, amount);
            }
        }
    }

    /** Public methods */

    /** @dev returns the position with the given id.
      * @param positionId id of the position.
      * @return farming position with the given id.
     */
    function position(uint256 positionId) public override view returns (FarmingPosition memory) {
        return _positions[positionId];
    }

    function setup(uint256 setupIndex) public override view returns (FarmingSetup memory, FarmingSetupInfo memory) {
        return (_setups[setupIndex], _setupsInfo[_setups[setupIndex].infoIndex]);
    }

    function setups() public override view returns (FarmingSetup[] memory) {
        FarmingSetup[] memory farmingSetups = new FarmingSetup[](_farmingSetupsCount);
        for (uint256 i = 0; i < _farmingSetupsCount; i++) {
            farmingSetups[i] = _setups[i];
        }
        return farmingSetups;
    }

    function activateSetup(uint256 setupInfoIndex) public {
        require(_setupsInfo[setupInfoIndex].renewTimes > 0 && !_setups[_setupsInfo[setupInfoIndex].lastSetupIndex].active, "Invalid toggle.");
        _toggleSetup(_setupsInfo[setupInfoIndex].lastSetupIndex);
    }

    function toggleSetup(uint256 setupInfoIndex) public {
        uint256 setupIndex = _setupsInfo[setupInfoIndex].lastSetupIndex;
        require(_setups[setupIndex].active && block.number > _setups[setupIndex].endBlock, "Invalid toggle.");
        _toggleSetup(setupIndex);
        _tryClearSetup(setupIndex);
    }

    function openPosition(FarmingPositionRequest memory request) public override payable activeSetupOnly(request.setupIndex) returns(uint256 positionId) {
        // retrieve the unique owner
        address uniqueOwner = (request.positionOwner != address(0)) ? request.positionOwner : msg.sender;
        // create the position id
        positionId = uint256(keccak256(abi.encode(uniqueOwner, request.setupIndex)));
        require(_positions[positionId].creationBlock == 0, "Invalid open");
        uint128 liquidityAmount = _addLiquidity(request.setupIndex, request);
        _updateFreeSetup(request.setupIndex, liquidityAmount, positionId, false);
        _positions[positionId] = FarmingPosition({
            uniqueOwner: uniqueOwner,
            setupIndex : request.setupIndex,
            liquidityPoolTokenAmount: liquidityAmount,
            reward: 0,
            creationBlock: block.number
        });
        _setupPositionsCount[request.setupIndex] += 1;
        emit Transfer(positionId, address(0), uniqueOwner);
    }

    function addLiquidity(uint256 positionId, FarmingPositionRequest memory request) public override payable activeSetupOnly(request.setupIndex) byPositionOwner(positionId) {
        // retrieve farming position
        FarmingPosition storage farmingPosition = _positions[positionId];
        FarmingSetup storage chosenSetup = _setups[farmingPosition.setupIndex];
        uint128 liquidityAmount = _addLiquidity(farmingPosition.setupIndex, request);
        // rebalance the reward per token
        _rewardPerTokenPerSetup[farmingPosition.setupIndex] += (((block.number - chosenSetup.lastUpdateBlock) * chosenSetup.rewardPerBlock) * 1e18) / chosenSetup.totalSupply;
        farmingPosition.reward = calculateFreeFarmingReward(positionId, false);
        _rewardPerTokenPaid[positionId] = _rewardPerTokenPerSetup[farmingPosition.setupIndex];
        farmingPosition.liquidityPoolTokenAmount += liquidityAmount;
        // update the last block update variablex
        chosenSetup.lastUpdateBlock = block.number;
        chosenSetup.totalSupply += liquidityAmount;
    }


    /** @dev this function allows a user to withdraw the reward.
      * @param positionId farming position id.
     */
    function withdrawReward(uint256 positionId) external byPositionOwner(positionId) {
        _withdrawReward(positionId, 0);
    }

    function _withdrawReward(uint256 positionId, uint128 liquidityToRemove) private {
        // retrieve farming position
        FarmingPosition storage farmingPosition = _positions[positionId];
        FarmingSetup memory farmingSetup = _setups[farmingPosition.setupIndex];
        uint256 reward = farmingPosition.reward;
        uint256 currentBlock = block.number;
        // rebalance setup
        currentBlock = currentBlock > farmingSetup.endBlock ? farmingSetup.endBlock : currentBlock;
        _rewardPerTokenPerSetup[farmingPosition.setupIndex] += (((currentBlock - farmingSetup.lastUpdateBlock) * farmingSetup.rewardPerBlock) * 1e18) / farmingSetup.totalSupply;
        reward = calculateFreeFarmingReward(positionId, false);
        _rewardPerTokenPaid[positionId] = _rewardPerTokenPerSetup[farmingPosition.setupIndex];
        farmingPosition.reward = 0;
        // update the last block update variable
        farmingSetup.lastUpdateBlock = currentBlock;
        _safeTransfer(_rewardTokenAddress, farmingPosition.uniqueOwner, reward);
        _rewardPaid[farmingPosition.setupIndex] += reward;

        _retrieveGen2LiquidityAndFees(positionId, farmingSetup.objectId, reward, farmingPosition.uniqueOwner, liquidityToRemove);

        if (farmingSetup.endBlock <= block.number && farmingSetup.active) {
            _toggleSetup(farmingPosition.setupIndex);
        }
    }

    function withdrawLiquidity(uint256 positionId, uint128 removedLiquidity) byPositionOwner(positionId) public {
        // retrieve farming position
        FarmingPosition storage farmingPosition = _positions[positionId];
        // current owned liquidity
        require(
            farmingPosition.creationBlock != 0 &&
            removedLiquidity <= farmingPosition.liquidityPoolTokenAmount &&
            farmingPosition.uniqueOwner == msg.sender,
            "Invalid withdraw"
        );
        _withdrawReward(positionId, removedLiquidity);
        _setups[farmingPosition.setupIndex].totalSupply -= removedLiquidity;
        farmingPosition.liquidityPoolTokenAmount -= removedLiquidity;
        // delete the farming position after the withdraw
        if (farmingPosition.liquidityPoolTokenAmount == 0) {
            _setupPositionsCount[farmingPosition.setupIndex] -= 1;
            _tryClearSetup(farmingPosition.setupIndex);
            delete _positions[positionId];
        }
    }

    function _tryClearSetup(uint256 setupIndex) private {
        if (_setupPositionsCount[setupIndex] == 0 && !_setups[setupIndex].active && _setups[setupIndex].objectId != 0) {
            uint256 objectId = _setups[setupIndex].objectId;
            address(nonfungiblePositionManager).call(abi.encodeWithSelector(nonfungiblePositionManager.collect.selector, INonfungiblePositionManager.CollectParams({
                tokenId: objectId,
                recipient: address(this),
                amount0Max: 0xffffffffffffffffffffffffffffffff,
                amount1Max: 0xffffffffffffffffffffffffffffffff
            })));
            nonfungiblePositionManager.burn(objectId);
            //address(nonfungiblePositionManager).call(abi.encodeWithSelector(nonfungiblePositionManager.burn.selector, objectId));
            delete _setups[setupIndex];
        }
    }

    function calculateFreeFarmingReward(uint256 positionId, bool isExt) public view returns(uint256 reward) {
        FarmingPosition memory farmingPosition = _positions[positionId];
        reward = ((_rewardPerTokenPerSetup[farmingPosition.setupIndex] - _rewardPerTokenPaid[positionId]) * farmingPosition.liquidityPoolTokenAmount) / 1e18;
        if (isExt) {
            uint256 currentBlock = block.number < _setups[farmingPosition.setupIndex].endBlock ? block.number : _setups[farmingPosition.setupIndex].endBlock;
            uint256 lastUpdateBlock = _setups[farmingPosition.setupIndex].lastUpdateBlock < _setups[farmingPosition.setupIndex].startBlock ? _setups[farmingPosition.setupIndex].startBlock : _setups[farmingPosition.setupIndex].lastUpdateBlock;
            uint256 rpt = (((currentBlock - lastUpdateBlock) * _setups[farmingPosition.setupIndex].rewardPerBlock) * 1e18) / _setups[farmingPosition.setupIndex].totalSupply;
            reward += (rpt * farmingPosition.liquidityPoolTokenAmount) / 1e18;
        }
        reward += farmingPosition.reward;
    }

    /// @dev only for gen2, where fees are taken out from the nft. 
    /// @notice calculates the amount of unclaimed fees of a FarmingPosition
    function calculateTradingFees(uint256 positionId, uint256 reward, uint128 tokensOwed0, uint128 tokensOwed1) public view returns (uint256 token0Fees, uint256 token1Fees) {
        FarmingPosition memory farmingPosition = _positions[positionId];
        FarmingSetup memory chosenSetup = _setups[farmingPosition.setupIndex];

        uint256 lastRedeemeableBlock = block.number > chosenSetup.endBlock ? chosenSetup.endBlock : block.number;
        uint256 percentageOfFeesOwnedByPosition = 
        reward * ONE_HUNDRED / (((chosenSetup.rewardPerBlock * (lastRedeemeableBlock - chosenSetup.startBlock)) - _rewardPaid[farmingPosition.setupIndex]));

        // the following needs to be done as to fetch up to date fees information from the NFT
        // tokensOwed0 and 1 represent fees owed for that NFT
        if(tokensOwed0 == 0 && tokensOwed1 == 0) {
            (,,,,,,,,,, tokensOwed0, tokensOwed1) = INonfungiblePositionManager(nonfungiblePositionManager).positions(_setups[_positions[positionId].setupIndex].objectId);
        }
        token0Fees = (tokensOwed0 * percentageOfFeesOwnedByPosition) / ONE_HUNDRED;
        token1Fees = (tokensOwed1 * percentageOfFeesOwnedByPosition) / ONE_HUNDRED;
    }

    /** Private methods */

    function _setOrAddFarmingSetupInfo(FarmingSetupInfo memory info, bool add, bool disable, uint256 setupIndex) private {
        FarmingSetupInfo memory farmingSetupInfo = info;

        if(add || !disable) {
            farmingSetupInfo.renewTimes = farmingSetupInfo.renewTimes + 1;
            if(farmingSetupInfo.renewTimes == 0) {
                farmingSetupInfo.renewTimes = farmingSetupInfo.renewTimes - 1;
            }
        }

        if (add) {
            require(
                farmingSetupInfo.liquidityPoolTokenAddress != address(0) &&
                farmingSetupInfo.originalRewardPerBlock > 0,
                "Invalid setup configuration"
            );
            _checkTicks(farmingSetupInfo.tickLower, farmingSetupInfo.tickUpper);
            address[] memory tokenAddresses = new address[](2);
            tokenAddresses[0] = IUniswapV3Pool(info.liquidityPoolTokenAddress).token0();
            tokenAddresses[1] = IUniswapV3Pool(info.liquidityPoolTokenAddress).token1();
            bool mainTokenFound = false;
            bool ethTokenFound = false;
            for(uint256 z = 0; z < tokenAddresses.length; z++) {
                if(tokenAddresses[z] == _WETH) {
                    ethTokenFound = true;
                }
                if(tokenAddresses[z] == farmingSetupInfo.mainTokenAddress) {
                    mainTokenFound = true;
                } else {
                    emit SetupToken(farmingSetupInfo.mainTokenAddress, tokenAddresses[z]);
                }
            }
            require(mainTokenFound, "No main token");
            require(!farmingSetupInfo.involvingETH || ethTokenFound, "No ETH token");
            farmingSetupInfo.setupsCount = 0;
            _setupsInfo[_farmingSetupsInfoCount] = farmingSetupInfo;
            _setups[_farmingSetupsCount] = FarmingSetup(_farmingSetupsInfoCount, false, 0, 0, 0, 0, farmingSetupInfo.originalRewardPerBlock, 0);
            _setupsInfo[_farmingSetupsInfoCount].lastSetupIndex = _farmingSetupsCount;
            _farmingSetupsInfoCount += 1;
            _farmingSetupsCount += 1;
            return;
        }

        FarmingSetup storage setup = _setups[setupIndex];
        farmingSetupInfo = _setupsInfo[_setups[setupIndex].infoIndex];

        if(disable) {
            require(setup.active, "Not possible");
            _toggleSetup(setupIndex);
            return;
        }

        info.renewTimes -= 1;

        if (setup.active) {
            setup = _setups[setupIndex];
            if(block.number < setup.endBlock) {
                uint256 difference = info.originalRewardPerBlock < farmingSetupInfo.originalRewardPerBlock ? farmingSetupInfo.originalRewardPerBlock - info.originalRewardPerBlock : info.originalRewardPerBlock - farmingSetupInfo.originalRewardPerBlock;
                uint256 duration = setup.endBlock - block.number;
                uint256 amount = difference * duration;
                if (amount > 0) {
                    if (info.originalRewardPerBlock > farmingSetupInfo.originalRewardPerBlock) {
                        require(_ensureTransfer(amount), "Insufficient reward in extension.");
                        _rewardReceived[setupIndex] += amount;
                    }
                    _updateFreeSetup(setupIndex, 0, 0, false);
                    setup.rewardPerBlock = info.originalRewardPerBlock;
                }
            }
            _setupsInfo[_setups[setupIndex].infoIndex].originalRewardPerBlock = info.originalRewardPerBlock;
        }
        if(_setupsInfo[_setups[setupIndex].infoIndex].renewTimes > 0) {
            _setupsInfo[_setups[setupIndex].infoIndex].renewTimes = info.renewTimes;
        }
    }

    function _transferToMeAndCheckAllowance(FarmingSetup memory setup, FarmingPositionRequest memory request) private {
        address[] memory tokens = new address[](2);
        tokens[0] = IUniswapV3Pool(_setupsInfo[setup.infoIndex].liquidityPoolTokenAddress).token0();
        tokens[1] = IUniswapV3Pool(_setupsInfo[setup.infoIndex].liquidityPoolTokenAddress).token1();
        uint256[] memory tokenAmounts = new uint256[](2);
        tokenAmounts[0] = request.amount0;
        tokenAmounts[1] = request.amount1;
        require((_setupsInfo[setup.infoIndex].mainTokenAddress == tokens[0] ? tokenAmounts[0] : tokenAmounts[1]) >= _setupsInfo[setup.infoIndex].minStakeable, "Invalid liquidity.");
        // iterate the tokens and perform the transferFrom and the approve
        for(uint256 i = 0; i < tokens.length; i++) {
            if(_setupsInfo[setup.infoIndex].involvingETH && _WETH == tokens[i]) {
                require(msg.value == tokenAmounts[i], "Incorrect eth value");
            } else {
                _safeTransferFrom(tokens[i], msg.sender, address(this), tokenAmounts[i]);
                _safeApprove(tokens[i], address(nonfungiblePositionManager), tokenAmounts[i]);
            }
        }
    }

    /// @dev addliquidity only for gen2
    function _addLiquidity(uint256 setupIndex, FarmingPositionRequest memory request) private returns(uint128 liquidityAmount) {
        _transferToMeAndCheckAllowance(_setups[setupIndex], request);

        FarmingSetupInfo memory setupInfo = _setupsInfo[_setups[setupIndex].infoIndex];
        bytes[] memory data = new bytes[](setupInfo.involvingETH ? 2 : 1);

        address token0 = IUniswapV3Pool(setupInfo.liquidityPoolTokenAddress).token0();
        address token1 = IUniswapV3Pool(setupInfo.liquidityPoolTokenAddress).token1();
        uint256 ethValue = setupInfo.involvingETH ? token0 == _WETH ? request.amount0 : request.amount1 : 0;
        uint256 amount0;
        uint256 amount1;

        if(setupInfo.involvingETH) {
            data[1] = abi.encodeWithSelector(nonfungiblePositionManager.refundETH.selector);
        }
        if(_setupPositionsCount[setupIndex] == 0 && _setups[setupIndex].objectId == 0) {
            data[0] = abi.encodeWithSelector(nonfungiblePositionManager.mint.selector, INonfungiblePositionManager.MintParams({
                token0: token0, 
                token1: token1,
                fee: IUniswapV3Pool(setupInfo.liquidityPoolTokenAddress).fee(),
                tickLower: setupInfo.tickLower, 
                tickUpper: setupInfo.tickUpper,
                amount0Desired: request.amount0, 
                amount1Desired: request.amount1,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp + 10000
            }));
            (_setups[setupIndex].objectId, liquidityAmount, amount0, amount1) = abi.decode(IMulticall(address(nonfungiblePositionManager)).multicall{ value: ethValue }(data)[0], (uint256, uint128, uint256, uint256));
        } else {
            data[0] = abi.encodeWithSelector(nonfungiblePositionManager.increaseLiquidity.selector, INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: _setups[request.setupIndex].objectId, 
                amount0Desired: request.amount0, 
                amount1Desired: request.amount1,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp + 10000
            }));
            (liquidityAmount, amount0, amount1) = abi.decode(IMulticall(address(nonfungiblePositionManager)).multicall{ value : ethValue }(data)[0], (uint128, uint256, uint256));
        }

        if(amount0 < request.amount0){
            _safeTransfer(setupInfo.involvingETH && token0 == _WETH ? address(0) : token0, msg.sender, request.amount0 - amount0);
        }

        if(amount1 < request.amount1){
            _safeTransfer(setupInfo.involvingETH && token1 == _WETH ? address(0) : token1, msg.sender, request.amount1 - amount1);
        }
    }

    /** @dev updates the free setup with the given index.
      * @param setupIndex index of the setup that we're updating.
      * @param amount amount of liquidity that we're adding/removeing.
      * @param positionId position id.
      * @param fromExit if it's from an exit or not.
     */
    function _updateFreeSetup(uint256 setupIndex, uint128 amount, uint256 positionId, bool fromExit) private {
        uint256 currentBlock = block.number < _setups[setupIndex].endBlock ? block.number : _setups[setupIndex].endBlock;
        if (_setups[setupIndex].totalSupply != 0) {
            uint256 lastUpdateBlock = _setups[setupIndex].lastUpdateBlock < _setups[setupIndex].startBlock ? _setups[setupIndex].startBlock : _setups[setupIndex].lastUpdateBlock;
            _rewardPerTokenPerSetup[setupIndex] += (((currentBlock - lastUpdateBlock) * _setups[setupIndex].rewardPerBlock) * 1e18) / _setups[setupIndex].totalSupply;
        }
        // update the last block update variable
        _setups[setupIndex].lastUpdateBlock = currentBlock;
        if (positionId != 0) {
            _rewardPerTokenPaid[positionId] = _rewardPerTokenPerSetup[setupIndex];
        }
        if (amount > 0) {
            fromExit ? _setups[setupIndex].totalSupply -= amount : _setups[setupIndex].totalSupply += amount;
        }
    }

    function _toggleSetup(uint256 setupIndex) private {
        FarmingSetup storage setup = _setups[setupIndex];
        // require(!setup.active || block.number >= setup.endBlock, "Not valid activation");

        require(block.number > _setupsInfo[setup.infoIndex].startBlock, "Too early for this setup");

        if (setup.active && block.number >= setup.endBlock && _setupsInfo[setup.infoIndex].renewTimes == 0) {
            setup.active = false;
            return;
        } else if (block.number >= setup.startBlock && block.number < setup.endBlock && setup.active) {
            setup.active = false;
            _setupsInfo[setup.infoIndex].renewTimes = 0;
            uint256 amount = (setup.endBlock - block.number) * setup.rewardPerBlock;
            setup.endBlock = block.number;
            _updateFreeSetup(setupIndex, 0, 0, false);
            _rewardReceived[setupIndex] -= amount;
            return;
        }

        bool wasActive = setup.active;
        setup.active = _ensureTransfer(setup.rewardPerBlock * _setupsInfo[setup.infoIndex].blockDuration);

        if (setup.active && wasActive) {
            _rewardReceived[_farmingSetupsCount] = setup.rewardPerBlock * _setupsInfo[setup.infoIndex].blockDuration;
            // set new setup
            _setups[_farmingSetupsCount] = abi.decode(abi.encode(setup), (FarmingSetup));
            // update old setup
            _setups[setupIndex].active = false;
            // update new setup
            _setupsInfo[setup.infoIndex].renewTimes -= 1;
            _setupsInfo[setup.infoIndex].setupsCount += 1;
            _setupsInfo[setup.infoIndex].lastSetupIndex = _farmingSetupsCount;
            _setups[_farmingSetupsCount].startBlock = block.number;
            _setups[_farmingSetupsCount].endBlock = block.number + _setupsInfo[_setups[_farmingSetupsCount].infoIndex].blockDuration;
            _setups[_farmingSetupsCount].objectId = 0;
            _setups[_farmingSetupsCount].totalSupply = 0;
            _farmingSetupsCount += 1;
        } else if (setup.active && !wasActive) {
            _rewardReceived[setupIndex] = setup.rewardPerBlock * _setupsInfo[_setups[setupIndex].infoIndex].blockDuration;
            // update new setup
            _setups[setupIndex].startBlock = block.number;
            _setups[setupIndex].endBlock = block.number + _setupsInfo[_setups[setupIndex].infoIndex].blockDuration;
            _setups[setupIndex].totalSupply = 0;
            _setupsInfo[_setups[setupIndex].infoIndex].renewTimes -= 1;
        } else {
            _setupsInfo[_setups[setupIndex].infoIndex].renewTimes = 0;
        }
    }

    /** @dev function used to safely approve ERC20 transfers.
      * @param erc20TokenAddress address of the token to approve.
      * @param to receiver of the approval.
      * @param value amount to approve for.
     */
    function _safeApprove(address erc20TokenAddress, address to, uint256 value) internal virtual {
        if(value == 0) {
            return;
        }
        bytes memory returnData = _call(erc20TokenAddress, abi.encodeWithSelector(IERC20(erc20TokenAddress).approve.selector, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'APPROVE_FAILED');
    }

    /** @dev function used to safe transfer ERC20 tokens.
      * @param erc20TokenAddress address of the token to transfer.
      * @param to receiver of the tokens.
      * @param value amount of tokens to transfer.
     */
    function _safeTransfer(address erc20TokenAddress, address to, uint256 value) internal virtual {
        if(value == 0) {
            return;
        }
        if(erc20TokenAddress == address(0)) {
            (bool result,) = to.call{value : value}("");
            require(result, "TRANSFER_FAILED");
            return;
        }
        bytes memory returnData = _call(erc20TokenAddress, abi.encodeWithSelector(IERC20(erc20TokenAddress).transfer.selector, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'TRANSFER_FAILED');
    }

    /** @dev this function safely transfers the given ERC20 value from an address to another.
      * @param erc20TokenAddress erc20 token address.
      * @param from address from.
      * @param to address to.
      * @param value amount to transfer.
     */
    function _safeTransferFrom(address erc20TokenAddress, address from, address to, uint256 value) private {
        if(value == 0) {
            return;
        }
        bytes memory returnData = _call(erc20TokenAddress, abi.encodeWithSelector(IERC20(erc20TokenAddress).transferFrom.selector, from, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'TRANSFERFROM_FAILED');
    }

    /** @dev calls the contract at the given location using the given payload and returns the returnData.
      * @param location location to call.
      * @param payload call payload.
      * @return returnData call return data.
     */
    function _call(address location, bytes memory payload) private returns(bytes memory returnData) {
        assembly {
            let result := call(gas(), location, 0, add(payload, 0x20), mload(payload), 0, 0)
            let size := returndatasize()
            returnData := mload(0x40)
            mstore(returnData, size)
            let returnDataPayloadStart := add(returnData, 0x20)
            returndatacopy(returnDataPayloadStart, 0, size)
            mstore(0x40, add(returnDataPayloadStart, size))
            switch result case 0 {revert(returnDataPayloadStart, size)}
        }
    }

    /** @dev gives back the reward to the extension.
      * @param amount to give back.
     */
    function _giveBack(uint256 amount) private {
        if(amount == 0) {
            return;
        }
        if (_rewardTokenAddress == address(0)) {
            IFarmExtension(_extension).backToYou{value : amount}(amount);
        } else {
            _safeApprove(_rewardTokenAddress, _extension, amount);
            IFarmExtension(_extension).backToYou(amount);
        }
    }

    /** @dev ensures the transfer from the contract to the extension.
      * @param amount amount to transfer.
     */
    function _ensureTransfer(uint256 amount) private returns(bool) {
        uint256 initialBalance = _rewardTokenAddress == address(0) ? address(this).balance : IERC20(_rewardTokenAddress).balanceOf(address(this));
        uint256 expectedBalance = initialBalance + amount;
        try IFarmExtension(_extension).transferTo(amount) {} catch {}
        uint256 actualBalance = _rewardTokenAddress == address(0) ? address(this).balance : IERC20(_rewardTokenAddress).balanceOf(address(this));
        if(actualBalance == expectedBalance) {
            return true;
        }
        _giveBack(actualBalance - initialBalance);
        return false;
    }

    /// @dev Common checks for valid tick inputs.
    function _checkTicks(int24 tickLower, int24 tickUpper) private pure {
        require(tickLower < tickUpper, 'TLU');
        require(tickLower >= TickMath.MIN_TICK, 'TLM');
        require(tickUpper <= TickMath.MAX_TICK, 'TUM');
    }

    // only called from gen2 code
    function _retrieveGen2LiquidityAndFees(uint256 positionId, uint256 objectId, uint256 reward, address recipient, uint128 liquidityToRemove) private {
        uint256 collectedAmount0 = 0;
        uint256 collectedAmount1 = 0;

        (uint256 wei0, uint256 wei1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams({
            tokenId: objectId,
            recipient: address(0),
            amount0Max: 1,
            amount1Max: 1
        }));

        (uint256 feeAmount0, uint256 feeAmount1) = (0, 0);
        if(reward > 0) {
            (feeAmount0, feeAmount1) = calculateTradingFees(positionId, reward, 0, 0);
        }
        if(liquidityToRemove > 0) {
            (collectedAmount0, collectedAmount1) = nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(
                objectId,
                liquidityToRemove,
                0,
                0,
                block.timestamp + 10000
            ));
        }
        collectedAmount0 += feeAmount0;
        collectedAmount1 += feeAmount1;
        if (collectedAmount0 > 0 || collectedAmount1 > 0) {
            (address token0, address token1) = _collect(positionId, collectedAmount0, collectedAmount1);
            uint256 dfoFee0 = 0;
            uint256 dfoFee1 = 0;
            (uint256 exitFeePercentage, address exitFeeWallet) = IFarmFactory(_factory).feePercentageInfo();
            if (exitFeePercentage > 0) {
                dfoFee0 = (feeAmount0 * ((exitFeePercentage * 1e18) / ONE_HUNDRED)) / 1e18;
                dfoFee1 = (feeAmount1 * ((exitFeePercentage * 1e18) / ONE_HUNDRED)) / 1e18;
                _safeTransfer(token0, exitFeeWallet, dfoFee0);
                _safeTransfer(token1, exitFeeWallet, dfoFee1);
            }
            _safeTransfer(token0, recipient, collectedAmount0 - dfoFee0);
            _safeTransfer(token1, recipient, collectedAmount1 - dfoFee1);
        }
    }

    function _collect(uint256 positionId, uint256 collectedAmount0, uint256 collectedAmount1) private returns (address token0, address token1) {
        require(collectedAmount0 > 0 || collectedAmount1 > 0, "0 amount");
        bool involvingETH = _setupsInfo[_setups[_positions[positionId].setupIndex].infoIndex].involvingETH;
        bytes[] memory data = new bytes[](involvingETH ? 3 : 1);
        data[0] = abi.encodeWithSelector(nonfungiblePositionManager.collect.selector, INonfungiblePositionManager.CollectParams({
            tokenId: _setups[_positions[positionId].setupIndex].objectId,
            recipient: involvingETH ? address(0) : address(this),
            amount0Max: uint128(collectedAmount0),
            amount1Max: uint128(collectedAmount1)
        }));
        (,, token0, token1, , , , , , , , ) = nonfungiblePositionManager.positions(_setups[_positions[positionId].setupIndex].objectId);
        if(involvingETH) {
            data[1] = abi.encodeWithSelector(nonfungiblePositionManager.unwrapWETH9.selector, 0, address(this));
            data[2] = abi.encodeWithSelector(nonfungiblePositionManager.sweepToken.selector, token0 == _WETH ? token1 : token0, 0, address(this));
            token0 = token0 == _WETH ? address(0) : token0;
            token1 = token1 == _WETH ? address(0) : token1;
        }
        (uint256 amount0, uint256 amount1) = abi.decode(IMulticall(address(nonfungiblePositionManager)).multicall(data)[0], (uint256, uint256));
        //require(amount0 == collectedAmount0, "Invalid amount0");
        //require(amount1 == collectedAmount1, "Invalid amount1");
    }
}