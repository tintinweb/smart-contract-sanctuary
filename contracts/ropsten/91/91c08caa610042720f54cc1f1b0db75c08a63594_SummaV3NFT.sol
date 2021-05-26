/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

interface ISummaV3PairImmutables {

    function pairCreator() external view returns (address);


    function token0() external view returns (address);


    function token1() external view returns (address);


    function fee() external view returns (uint24);


    function tickSpacing() external view returns (int24);

    function maxLiquidityPerTick() external view returns (uint128);
}

interface ISummaV3PairState {

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


    function feeGrowthGlobal0X128() external view returns (uint256);

    function feeGrowthGlobal1X128() external view returns (uint256);

    function protocolFees() external view returns (uint128 token0, uint128 token1);

    function liquidity() external view returns (uint128);

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

    function tickBitmap(int16 wordPosition) external view returns (uint256);

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
interface ISummaV3PairEvents {

    event Initialize(uint160 sqrtPriceX96, int24 tick);
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}
interface ISummaV3PairDerivedState {

    function observe(uint32[] calldata secondsAgos)
    external
    view
    returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
    external
    view
    returns (
        int56 tickCumulativeInside,
        uint160 secondsPerLiquidityInsideX128,
        uint32 secondsInside
    );
}

interface ISummaV3PairActions {

    function initialize(uint160 sqrtPriceX96) external;

    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}
interface ISummaV3PairOwnerActions {

    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;


    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}
interface IMulticall {
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
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
interface IPairInitializer {
    function createAndInitializePairIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pair);
}
interface IERC721Permit is IERC721 {

    function PERMIT_TYPEHASH() external pure returns (bytes32);


    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}
interface IPeripheryPayments {

    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    function refundETH() external payable;

    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}
interface IPeripheryImmutableState {
    function pairCreator() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}
interface ISelfPermit {
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}
interface IERC20PermitAllowed {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

interface IERC1271 {

    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}


interface ISummaV3PairCreator {

    event OwnerChanged(address indexed oldOwner, address indexed newOwner);


    event PairCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pair
    );

    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    function owner() external view returns (address);

    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    function getPair(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pair);

    function createPair(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pair);

    function setOwner(address _owner) external;

    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;

    function parameters()
    external
    view
    returns (
        address pairCreator,
        address token0,
        address token1,
        uint24 fee,
        int24 tickSpacing
    );
}
interface ISummaV3MintCallback {

    function summaswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}
interface ISummaV3Pair is
ISummaV3PairImmutables,
ISummaV3PairState,
ISummaV3PairDerivedState,
ISummaV3PairActions,
ISummaV3PairOwnerActions,
ISummaV3PairEvents
{

}

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

interface ISummaV3NFT is
IPairInitializer,
IPeripheryPayments,
IPeripheryImmutableState,
IERC721Metadata,
IERC721Enumerable,
IERC721Permit
{

    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

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
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    function burn(uint256 tokenId) external payable;
}
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}
abstract contract PeripheryImmutableState is IPeripheryImmutableState {
address public immutable override pairCreator;
/// @inheritdoc IPeripheryImmutableState
address public immutable override WETH9;

constructor(address _pairCreator, address _WETH9) {
pairCreator = _pairCreator;
WETH9 = _WETH9;
}
}
abstract contract PeripheryPayments is IPeripheryPayments, PeripheryImmutableState {
receive() external payable {
require(msg.sender == WETH9, 'Not WETH9');
}
function unwrapWETH9(uint256 amountMinimum, address recipient) external payable override {
uint256 balanceWETH9 = IWETH9(WETH9).balanceOf(address(this));
require(balanceWETH9 >= amountMinimum, 'Insufficient WETH9');

if (balanceWETH9 > 0) {
IWETH9(WETH9).withdraw(balanceWETH9);
TransferHelper.safeTransferETH(recipient, balanceWETH9);
}
}

function sweepToken(
address token,
uint256 amountMinimum,
address recipient
) external payable override {
uint256 balanceToken = IERC20(token).balanceOf(address(this));
require(balanceToken >= amountMinimum, 'Insufficient token');

if (balanceToken > 0) {
TransferHelper.safeTransfer(token, recipient, balanceToken);
}
}

/// @inheritdoc IPeripheryPayments
function refundETH() external payable override {
if (address(this).balance > 0) TransferHelper.safeTransferETH(msg.sender, address(this).balance);
}

function pay(
address token,
address payer,
address recipient,
uint256 value
) internal {
if (token == WETH9 && address(this).balance >= value) {
// pay with WETH9
IWETH9(WETH9).deposit{value: value}(); // wrap only what is needed to pay
IWETH9(WETH9).transfer(recipient, value);
} else if (payer == address(this)) {
// pay with tokens already in the contract (for the exact input multihop case)
TransferHelper.safeTransfer(token, recipient, value);
} else {
// pull payment
TransferHelper.safeTransferFrom(token, payer, recipient, value);
}
}
}
abstract contract LiquidityManagement is ISummaV3MintCallback, PeripheryImmutableState, PeripheryPayments {
struct MintCallbackData {
PairAddress.PairKey pairKey;
address payer;
}

function summaswapV3MintCallback(
uint256 amount0Owed,
uint256 amount1Owed,
bytes calldata data
) external override {
MintCallbackData memory decoded = abi.decode(data, (MintCallbackData));
CallbackValidation.verifyCallback(pairCreator, decoded.pairKey);

if (amount0Owed > 0) pay(decoded.pairKey.token0, decoded.payer, msg.sender, amount0Owed);
if (amount1Owed > 0) pay(decoded.pairKey.token1, decoded.payer, msg.sender, amount1Owed);
}

struct AddLiquidityParams {
address token0;
address token1;
uint24 fee;
address recipient;
int24 tickLower;
int24 tickUpper;
uint256 amount0Desired;
uint256 amount1Desired;
uint256 amount0Min;
uint256 amount1Min;
}

function addLiquidity(AddLiquidityParams memory params)
internal
returns (
uint128 liquidity,
uint256 amount0,
uint256 amount1,
ISummaV3Pair pair
)
{
PairAddress.PairKey memory pairKey =
PairAddress.PairKey({token0: params.token0, token1: params.token1, fee: params.fee});

pair = ISummaV3Pair(PairAddress.computeAddress(pairCreator, pairKey));

{
(uint160 sqrtPriceX96, , , , , , ) = pair.slot0();
uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(params.tickLower);
uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(params.tickUpper);

liquidity = LiquidityAmounts.getLiquidityForAmounts(
sqrtPriceX96,
sqrtRatioAX96,
sqrtRatioBX96,
params.amount0Desired,
params.amount1Desired
);
}

(amount0, amount1) = pair.mint(
params.recipient,
params.tickLower,
params.tickUpper,
liquidity,
abi.encode(MintCallbackData({pairKey: pairKey, payer: msg.sender}))
);

require(amount0 >= params.amount0Min && amount1 >= params.amount1Min, 'Price slippage check');
}
}
abstract contract BlockTimestamp {
function _blockTimestamp() internal view virtual returns (uint256) {
return block.timestamp;
}
}
abstract contract Context {
function _msgSender() internal view virtual returns (address payable) {
return msg.sender;
}

function _msgData() internal view virtual returns (bytes memory) {
this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
return msg.data;
}
}
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
using SafeMath for uint256;
using Address for address;
using EnumerableSet for EnumerableSet.UintSet;
using EnumerableMap for EnumerableMap.UintToAddressMap;
using Strings for uint256;

// Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
// which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

// Mapping from holder address to their (enumerable) set of owned tokens
mapping (address => EnumerableSet.UintSet) private _holderTokens;

// Enumerable mapping from token ids to their owners
EnumerableMap.UintToAddressMap private _tokenOwners;

// Mapping from token ID to approved address
mapping (uint256 => address) private _tokenApprovals;

// Mapping from owner to operator approvals
mapping (address => mapping (address => bool)) private _operatorApprovals;

// Token name
string private _name;

// Token symbol
string private _symbol;

// Optional mapping for token URIs
mapping (uint256 => string) private _tokenURIs;

// Base URI
string private _baseURI;

/*
 *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
 *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
 *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
 *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
 *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
 *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
 *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
 *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
 *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
 *
 *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
 *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
 */
bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

/*
 *     bytes4(keccak256('name()')) == 0x06fdde03
 *     bytes4(keccak256('symbol()')) == 0x95d89b41
 *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
 *
 *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
 */
bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

/*
 *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
 *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
 *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
 *
 *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
 */
bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

/**
 * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
 */
constructor (string memory name_, string memory symbol_) {
_name = name_;
_symbol = symbol_;

// register the supported interfaces to conform to ERC721 via ERC165
_registerInterface(_INTERFACE_ID_ERC721);
_registerInterface(_INTERFACE_ID_ERC721_METADATA);
_registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
}

/**
 * @dev See {IERC721-balanceOf}.
 */
function balanceOf(address owner) public view virtual override returns (uint256) {
require(owner != address(0), "ERC721: balance query for the zero address");
return _holderTokens[owner].length();
}

/**
 * @dev See {IERC721-ownerOf}.
 */
function ownerOf(uint256 tokenId) public view virtual override returns (address) {
return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
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

string memory _tokenURI = _tokenURIs[tokenId];
string memory base = baseURI();

// If there is no base URI, return the token URI.
if (bytes(base).length == 0) {
return _tokenURI;
}
// If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
if (bytes(_tokenURI).length > 0) {
return string(abi.encodePacked(base, _tokenURI));
}
// If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
return string(abi.encodePacked(base, tokenId.toString()));
}

/**
* @dev Returns the base URI set via {_setBaseURI}. This will be
* automatically added as a prefix in {tokenURI} to each token's URI, or
* to the token ID if no specific URI is set for that token ID.
*/
function baseURI() public view virtual returns (string memory) {
return _baseURI;
}

/**
 * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
 */
function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
return _holderTokens[owner].at(index);
}

/**
 * @dev See {IERC721Enumerable-totalSupply}.
 */
function totalSupply() public view virtual override returns (uint256) {
// _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
return _tokenOwners.length();
}

/**
 * @dev See {IERC721Enumerable-tokenByIndex}.
 */
function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
(uint256 tokenId, ) = _tokenOwners.at(index);
return tokenId;
}

/**
 * @dev See {IERC721-approve}.
 */
function approve(address to, uint256 tokenId) public virtual override {
address owner = ERC721.ownerOf(tokenId);
require(to != owner, "ERC721: approval to current owner");

require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
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
function transferFrom(address from, address to, uint256 tokenId) public virtual override {
//solhint-disable-next-line max-line-length
require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

_transfer(from, to, tokenId);
}

/**
 * @dev See {IERC721-safeTransferFrom}.
 */
function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
safeTransferFrom(from, to, tokenId, "");
}

/**
 * @dev See {IERC721-safeTransferFrom}.
 */
function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
return _tokenOwners.contains(tokenId);
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
return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
}

/**
 * @dev Safely mints `tokenId` and transfers it to `to`.
 *
 * Requirements:
 d*
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
function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
_mint(to, tokenId);
require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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

_holderTokens[to].add(tokenId);

_tokenOwners.set(tokenId, to);

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
address owner = ERC721.ownerOf(tokenId); // internal owner

_beforeTokenTransfer(owner, address(0), tokenId);

// Clear approvals
_approve(address(0), tokenId);

// Clear metadata (if any)
if (bytes(_tokenURIs[tokenId]).length != 0) {
delete _tokenURIs[tokenId];
}

_holderTokens[owner].remove(tokenId);

_tokenOwners.remove(tokenId);

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
function _transfer(address from, address to, uint256 tokenId) internal virtual {
require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
require(to != address(0), "ERC721: transfer to the zero address");

_beforeTokenTransfer(from, to, tokenId);

// Clear approvals from the previous owner
_approve(address(0), tokenId);

_holderTokens[from].remove(tokenId);
_holderTokens[to].add(tokenId);

_tokenOwners.set(tokenId, to);

emit Transfer(from, to, tokenId);
}

/**
 * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
 *
 * Requirements:
 *
 * - `tokenId` must exist.
 */
function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
_tokenURIs[tokenId] = _tokenURI;
}

/**
 * @dev Internal function to set the base URI for all token IDs. It is
 * automatically added as a prefix to the value returned in {tokenURI},
 * or to the token ID if {tokenURI} is empty.
 */
function _setBaseURI(string memory baseURI_) internal virtual {
_baseURI = baseURI_;
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
function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
private returns (bool)
{
if (!to.isContract()) {
return true;
}
bytes memory returndata = to.functionCall(abi.encodeWithSelector(
IERC721Receiver(to).onERC721Received.selector,
_msgSender(),
from,
tokenId,
_data
), "ERC721: transfer to non ERC721Receiver implementer");
bytes4 retval = abi.decode(returndata, (bytes4));
return (retval == _ERC721_RECEIVED);
}

/**
 * @dev Approve `to` to operate on `tokenId`
 *
 * Emits an {Approval} event.
 */
function _approve(address to, uint256 tokenId) internal virtual {
_tokenApprovals[tokenId] = to;
emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
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
function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}
abstract contract ERC721Permit is BlockTimestamp, ERC721, IERC721Permit {
/// @dev Gets the current nonce for a token ID and then increments it, returning the original value
function _getAndIncrementNonce(uint256 tokenId) internal virtual returns (uint256);

/// @dev The hash of the name used in the permit signature verification
bytes32 private immutable nameHash;

/// @dev The hash of the version string used in the permit signature verification
bytes32 private immutable versionHash;

/// @notice Computes the nameHash and versionHash
constructor(
string memory name_,
string memory symbol_,
string memory version_
) ERC721(name_, symbol_) {
nameHash = keccak256(bytes(name_));
versionHash = keccak256(bytes(version_));
}

/// @inheritdoc IERC721Permit
function DOMAIN_SEPARATOR() public view override returns (bytes32) {
return
keccak256(
abi.encode(
// keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
nameHash,
versionHash,
ChainId.get(),
address(this)
)
);
}

bytes32 public constant override PERMIT_TYPEHASH =
0x49ecf333e5b8c95c40fdafc95c1ad136e8914a8fb55e9dc8bb01eaa83a2df9ad;

function permit(
address spender,
uint256 tokenId,
uint256 deadline,
uint8 v,
bytes32 r,
bytes32 s
) external payable override {
require(_blockTimestamp() <= deadline, 'Permit expired');

bytes32 digest =
keccak256(
abi.encodePacked(
'\x19\x01',
DOMAIN_SEPARATOR(),
keccak256(abi.encode(PERMIT_TYPEHASH, spender, tokenId, _getAndIncrementNonce(tokenId), deadline))
)
);
address owner = ownerOf(tokenId);
require(spender != owner, 'ERC721Permit: approval to current owner');

if (Address.isContract(owner)) {
require(IERC1271(owner).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e, 'Unauthorized');
} else {
address recoveredAddress = ecrecover(digest, v, r, s);
require(recoveredAddress != address(0), 'Invalid signature');
require(recoveredAddress == owner, 'Unauthorized');
}

_approve(spender, tokenId);
}
}
abstract contract PeripheryValidation is BlockTimestamp {
modifier checkDeadline(uint256 deadline) {
require(_blockTimestamp() <= deadline, 'Transaction too old');
_;
}
}
abstract contract SelfPermit is ISelfPermit {
/// @inheritdoc ISelfPermit
function selfPermit(
address token,
uint256 value,
uint256 deadline,
uint8 v,
bytes32 r,
bytes32 s
) public payable override {
IERC20Permit(token).permit(msg.sender, address(this), value, deadline, v, r, s);
}

/// @inheritdoc ISelfPermit
function selfPermitIfNecessary(
address token,
uint256 value,
uint256 deadline,
uint8 v,
bytes32 r,
bytes32 s
) external payable override {
if (IERC20(token).allowance(msg.sender, address(this)) < value) selfPermit(token, value, deadline, v, r, s);
}

/// @inheritdoc ISelfPermit
function selfPermitAllowed(
address token,
uint256 nonce,
uint256 expiry,
uint8 v,
bytes32 r,
bytes32 s
) public payable override {
IERC20PermitAllowed(token).permit(msg.sender, address(this), nonce, expiry, true, v, r, s);
}

/// @inheritdoc ISelfPermit
function selfPermitAllowedIfNecessary(
address token,
uint256 nonce,
uint256 expiry,
uint8 v,
bytes32 r,
bytes32 s
) external payable override {
if (IERC20(token).allowance(msg.sender, address(this)) < type(uint256).max)
selfPermitAllowed(token, nonce, expiry, v, r, s);
}
}
abstract contract PairInitializer is IPairInitializer, PeripheryImmutableState {
function createAndInitializePairIfNecessary(
address token0,
address token1,
uint24 fee,
uint160 sqrtPriceX96
) external payable override returns (address pair) {
require(token0 < token1);
pair = ISummaV3PairCreator(pairCreator).getPair(token0, token1, fee);

if (pair == address(0)) {
pair = ISummaV3PairCreator(pairCreator).createPair(token0, token1, fee);
ISummaV3Pair(pair).initialize(sqrtPriceX96);
} else {
(uint160 sqrtPriceX96Existing, , , , , , ) = ISummaV3Pair(pair).slot0();
if (sqrtPriceX96Existing == 0) {
ISummaV3Pair(pair).initialize(sqrtPriceX96);
}
}
}
}


abstract contract Multicall is IMulticall {
/// @inheritdoc IMulticall
function multicall(bytes[] calldata data) external payable override returns (bytes[] memory results) {
results = new bytes[](data.length);
for (uint256 i = 0; i < data.length; i++) {
(bool success, bytes memory result) = address(this).delegatecall(data[i]);

if (!success) {
// Next 5 lines from https://ethereum.stackexchange.com/a/83577
if (result.length < 68) revert();
assembly {
result := add(result, 0x04)
}
revert(abi.decode(result, (string)));
}

results[i] = result;
}
}
}
contract SummaV3NFT is
ISummaV3NFT,
Multicall,
ERC721Permit,
PeripheryImmutableState,
PairInitializer,
LiquidityManagement,
PeripheryValidation,
SelfPermit
{
// details about the uniswap position
struct Position {
// the nonce for permits
uint96 nonce;
// the address that is approved for spending this token
address operator;
// the ID of the pool with which this token is connected
uint80 pairId;
// the tick range of the position
int24 tickLower;
int24 tickUpper;
// the liquidity of the position
uint128 liquidity;
// the fee growth of the aggregate position as of the last action on the individual position
uint256 feeGrowthInside0LastX128;
uint256 feeGrowthInside1LastX128;
// how many uncollected tokens are owed to the position, as of the last computation
uint128 tokensOwed0;
uint128 tokensOwed1;
}

/// @dev IDs of pools assigned by this contract
mapping(address => uint80) private _pairIds;

/// @dev Pool keys by pool ID, to save on SSTOREs for position data
mapping(uint80 => PairAddress.PairKey) private _pairIdToPairKey;

/// @dev The token ID position data
mapping(uint256 => Position) private _positions;

/// @dev The ID of the next token that will be minted. Skips 0
uint176 private _nextId = 1;
/// @dev The ID of the next pool that is used for the first time. Skips 0
uint80 private _nextPairId = 1;

constructor(
address _pairCreator,
address _WETH9
) ERC721Permit('Summaswap NFT', 'SUMMA NFT', '1') PeripheryImmutableState(_pairCreator, _WETH9) {

}
function positions(uint256 tokenId)
external
view
override
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
)
{
Position memory position = _positions[tokenId];
require(position.pairId != 0, 'Invalid token ID');
PairAddress.PairKey memory pairKey = _pairIdToPairKey[position.pairId];
return (
position.nonce,
position.operator,
pairKey.token0,
pairKey.token1,
pairKey.fee,
position.tickLower,
position.tickUpper,
position.liquidity,
position.feeGrowthInside0LastX128,
position.feeGrowthInside1LastX128,
position.tokensOwed0,
position.tokensOwed1
);
}

function cachePairKey(address pair, PairAddress.PairKey memory pairKey) private returns (uint80 pairId) {
pairId = _pairIds[pair];
if (pairId == 0) {
_pairIds[pair] = (pairId = _nextPairId++);
_pairIdToPairKey[pairId] = pairKey;
}
}
function mint(MintParams calldata params)
external
payable
override
checkDeadline(params.deadline)
returns (
uint256 tokenId,
uint128 liquidity,
uint256 amount0,
uint256 amount1
)
{
ISummaV3Pair pair;
(liquidity, amount0, amount1, pair) = addLiquidity(
AddLiquidityParams({
token0: params.token0,
token1: params.token1,
fee: params.fee,
recipient: address(this),
tickLower: params.tickLower,
tickUpper: params.tickUpper,
amount0Desired: params.amount0Desired,
amount1Desired: params.amount1Desired,
amount0Min: params.amount0Min,
amount1Min: params.amount1Min
})
);

_mint(params.recipient, (tokenId = _nextId++));

bytes32 positionKey = PositionKey.compute(address(this), params.tickLower, params.tickUpper);
(, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, , ) = pair.positions(positionKey);

// idempotent set
uint80 pairId =
cachePairKey(
address(pair),
PairAddress.PairKey({token0: params.token0, token1: params.token1, fee: params.fee})
);

_positions[tokenId] = Position({
nonce: 0,
operator: address(0),
pairId: pairId,
tickLower: params.tickLower,
tickUpper: params.tickUpper,
liquidity: liquidity,
feeGrowthInside0LastX128: feeGrowthInside0LastX128,
feeGrowthInside1LastX128: feeGrowthInside1LastX128,
tokensOwed0: 0,
tokensOwed1: 0
});

emit IncreaseLiquidity(tokenId, liquidity, amount0, amount1);
}

modifier isAuthorizedForToken(uint256 tokenId) {
require(_isApprovedOrOwner(msg.sender, tokenId), 'Not approved');
_;
}

function increaseLiquidity(IncreaseLiquidityParams calldata params)
external
payable
override
checkDeadline(params.deadline)
returns (
uint128 liquidity,
uint256 amount0,
uint256 amount1
)
{
Position storage position = _positions[params.tokenId];

PairAddress.PairKey memory pairKey = _pairIdToPairKey[position.pairId];

ISummaV3Pair pair;
(liquidity, amount0, amount1, pair) = addLiquidity(
AddLiquidityParams({
token0: pairKey.token0,
token1: pairKey.token1,
fee: pairKey.fee,
tickLower: position.tickLower,
tickUpper: position.tickUpper,
amount0Desired: params.amount0Desired,
amount1Desired: params.amount1Desired,
amount0Min: params.amount0Min,
amount1Min: params.amount1Min,
recipient: address(this)
})
);

bytes32 positionKey = PositionKey.compute(address(this), position.tickLower, position.tickUpper);

// this is now updated to the current transaction
(, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, , ) = pair.positions(positionKey);

position.tokensOwed0 += uint128(
FullMath.mulDiv(
feeGrowthInside0LastX128 - position.feeGrowthInside0LastX128,
position.liquidity,
FixedPoint128.Q128
)
);
position.tokensOwed1 += uint128(
FullMath.mulDiv(
feeGrowthInside1LastX128 - position.feeGrowthInside1LastX128,
position.liquidity,
FixedPoint128.Q128
)
);

position.feeGrowthInside0LastX128 = feeGrowthInside0LastX128;
position.feeGrowthInside1LastX128 = feeGrowthInside1LastX128;
position.liquidity += liquidity;

emit IncreaseLiquidity(params.tokenId, liquidity, amount0, amount1);
}

function decreaseLiquidity(DecreaseLiquidityParams calldata params)
external
payable
override
isAuthorizedForToken(params.tokenId)
checkDeadline(params.deadline)
returns (uint256 amount0, uint256 amount1)
{
require(params.liquidity > 0);
Position storage position = _positions[params.tokenId];

uint128 positionLiquidity = position.liquidity;
require(positionLiquidity >= params.liquidity);

PairAddress.PairKey memory pairKey = _pairIdToPairKey[position.pairId];
ISummaV3Pair pair = ISummaV3Pair(PairAddress.computeAddress(pairCreator, pairKey));
(amount0, amount1) = pair.burn(position.tickLower, position.tickUpper, params.liquidity);

require(amount0 >= params.amount0Min && amount1 >= params.amount1Min, 'Price slippage check');

bytes32 positionKey = PositionKey.compute(address(this), position.tickLower, position.tickUpper);
// this is now updated to the current transaction
(, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, , ) = pair.positions(positionKey);

position.tokensOwed0 +=
uint128(amount0) +
uint128(
FullMath.mulDiv(
feeGrowthInside0LastX128 - position.feeGrowthInside0LastX128,
positionLiquidity,
FixedPoint128.Q128
)
);
position.tokensOwed1 +=
uint128(amount1) +
uint128(
FullMath.mulDiv(
feeGrowthInside1LastX128 - position.feeGrowthInside1LastX128,
positionLiquidity,
FixedPoint128.Q128
)
);

position.feeGrowthInside0LastX128 = feeGrowthInside0LastX128;
position.feeGrowthInside1LastX128 = feeGrowthInside1LastX128;
// subtraction is safe because we checked positionLiquidity is gte params.liquidity
position.liquidity = positionLiquidity - params.liquidity;

emit DecreaseLiquidity(params.tokenId, params.liquidity, amount0, amount1);
}

function collect(CollectParams calldata params)
external
payable
override
isAuthorizedForToken(params.tokenId)
returns (uint256 amount0, uint256 amount1)
{
require(params.amount0Max > 0 || params.amount1Max > 0);
// allow collecting to the nft position manager address with address 0
address recipient = params.recipient == address(0) ? address(this) : params.recipient;

Position storage position = _positions[params.tokenId];

PairAddress.PairKey memory pairKey = _pairIdToPairKey[position.pairId];

ISummaV3Pair pair = ISummaV3Pair(PairAddress.computeAddress(pairCreator, pairKey));

(uint128 tokensOwed0, uint128 tokensOwed1) = (position.tokensOwed0, position.tokensOwed1);

// trigger an update of the position fees owed and fee growth snapshots if it has any liquidity
if (position.liquidity > 0) {
pair.burn(position.tickLower, position.tickUpper, 0);
(, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, , ) =
pair.positions(PositionKey.compute(address(this), position.tickLower, position.tickUpper));

tokensOwed0 += uint128(
FullMath.mulDiv(
feeGrowthInside0LastX128 - position.feeGrowthInside0LastX128,
position.liquidity,
FixedPoint128.Q128
)
);
tokensOwed1 += uint128(
FullMath.mulDiv(
feeGrowthInside1LastX128 - position.feeGrowthInside1LastX128,
position.liquidity,
FixedPoint128.Q128
)
);

position.feeGrowthInside0LastX128 = feeGrowthInside0LastX128;
position.feeGrowthInside1LastX128 = feeGrowthInside1LastX128;
}

// compute the arguments to give to the pool#collect method
(uint128 amount0Collect, uint128 amount1Collect) =
(
params.amount0Max > tokensOwed0 ? tokensOwed0 : params.amount0Max,
params.amount1Max > tokensOwed1 ? tokensOwed1 : params.amount1Max
);

// the actual amounts collected are returned
(amount0, amount1) = pair.collect(
recipient,
position.tickLower,
position.tickUpper,
amount0Collect,
amount1Collect
);

// sometimes there will be a few less wei than expected due to rounding down in core, but we just subtract the full amount expected
// instead of the actual amount so we can burn the token
(position.tokensOwed0, position.tokensOwed1) = (tokensOwed0 - amount0Collect, tokensOwed1 - amount1Collect);

emit Collect(params.tokenId, recipient, amount0Collect, amount1Collect);
}

function burn(uint256 tokenId) external payable override isAuthorizedForToken(tokenId) {
Position storage position = _positions[tokenId];
require(position.liquidity == 0 && position.tokensOwed0 == 0 && position.tokensOwed1 == 0, 'Not cleared');
delete _positions[tokenId];
_burn(tokenId);
}

function _getAndIncrementNonce(uint256 tokenId) internal override returns (uint256) {
return uint256(_positions[tokenId].nonce++);
}

/// @inheritdoc IERC721
function getApproved(uint256 tokenId) public view override(ERC721, IERC721) returns (address) {
require(_exists(tokenId), 'ERC721: approved query for nonexistent token');

return _positions[tokenId].operator;
}

/// @dev Overrides _approve to use the operator in the position, which is packed with the position permit nonce
function _approve(address to, uint256 tokenId) internal override(ERC721) {
_positions[tokenId].operator = to;
emit Approval(ownerOf(tokenId), to, tokenId);
}
}

library FixedPoint128 {
uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}


library FullMath {

function mulDiv(
uint256 a,
uint256 b,
uint256 denominator
) internal pure returns (uint256 result) {

uint256 prod0; // Least significant 256 bits of the product
uint256 prod1; // Most significant 256 bits of the product
assembly {
let mm := mulmod(a, b, not(0))
prod0 := mul(a, b)
prod1 := sub(sub(mm, prod0), lt(mm, prod0))
}

// Handle non-overflow cases, 256 by 256 division
if (prod1 == 0) {
require(denominator > 0);
assembly {
result := div(prod0, denominator)
}
return result;
}

// Make sure the result is less than 2**256.
// Also prevents denominator == 0
require(denominator > prod1);

uint256 remainder;
assembly {
remainder := mulmod(a, b, denominator)
}
// Subtract 256 bit number from 512 bit number
assembly {
prod1 := sub(prod1, gt(remainder, prod0))
prod0 := sub(prod0, remainder)
}

// Factor powers of two out of denominator
// Compute largest power of two divisor of denominator.
// Always >= 1.
uint256 twos = -denominator & denominator;
// Divide denominator by power of two
assembly {
denominator := div(denominator, twos)
}

// Divide [prod1 prod0] by the factors of two
assembly {
prod0 := div(prod0, twos)
}

// If twos is zero, then it becomes one
assembly {
twos := add(div(sub(0, twos), twos), 1)
}
prod0 |= prod1 * twos;

uint256 inv = (3 * denominator) ^ 2;

inv *= 2 - denominator * inv; // inverse mod 2**8
inv *= 2 - denominator * inv; // inverse mod 2**16
inv *= 2 - denominator * inv; // inverse mod 2**32
inv *= 2 - denominator * inv; // inverse mod 2**64
inv *= 2 - denominator * inv; // inverse mod 2**128
inv *= 2 - denominator * inv; // inverse mod 2**256


result = prod0 * inv;
return result;
}

function mulDivRoundingUp(
uint256 a,
uint256 b,
uint256 denominator
) internal pure returns (uint256 result) {
result = mulDiv(a, b, denominator);
if (mulmod(a, b, denominator) > 0) {
require(result < type(uint256).max);
result++;
}
}
}



library PositionKey {
/// @dev Returns the key of the position in the core library
function compute(
address owner,
int24 tickLower,
int24 tickUpper
) internal pure returns (bytes32) {
return keccak256(abi.encodePacked(owner, tickLower, tickUpper));
}
}

library PairAddress {
bytes32 internal constant POOL_INIT_CODE_HASH = 0xc479e3837ed827519d0f79fed0a77248bf562c36da5c24de997f2f0d0ec0cf4a;

/// @notice The identifying key of the pool
struct PairKey {
address token0;
address token1;
uint24 fee;
}

/// @notice Returns PoolKey: the ordered tokens with the matched fee levels
/// @param tokenA The first token of a pool, unsorted
/// @param tokenB The second token of a pool, unsorted
/// @param fee The fee level of the pool
/// @return Poolkey The pool details with ordered token0 and token1 assignments
function getPairKey(
address tokenA,
address tokenB,
uint24 fee
) internal pure returns (PairKey memory) {
if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
return PairKey({token0: tokenA, token1: tokenB, fee: fee});
}
function computeAddress(address pairCreator, PairKey memory key) internal pure returns (address pair) {
require(key.token0 < key.token1);
pair = address(
uint256(
keccak256(
abi.encodePacked(
hex'ff',
pairCreator,
keccak256(abi.encode(key.token0, key.token1, key.fee)),
POOL_INIT_CODE_HASH
)
)
)
);
}
}
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
library CallbackValidation {

function verifyCallback(
address pairCreator,
address tokenA,
address tokenB,
uint24 fee
) internal view returns (ISummaV3Pair pair) {
return verifyCallback(pairCreator, PairAddress.getPairKey(tokenA, tokenB, fee));
}

function verifyCallback(address pairCreator, PairAddress.PairKey memory pairKey)
internal
view
returns (ISummaV3Pair pair)
{
pair = ISummaV3Pair(PairAddress.computeAddress(pairCreator, pairKey));
require(msg.sender == address(pair));
}
}
library LiquidityAmounts {

function toUint128(uint256 x) private pure returns (uint128 y) {
require((y = uint128(x)) == x);
}

/// @notice Computes the amount of liquidity received for a given amount of token0 and price range
/// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
/// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
/// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
/// @param amount0 The amount0 being sent in
/// @return liquidity The amount of returned liquidity
function getLiquidityForAmount0(
uint160 sqrtRatioAX96,
uint160 sqrtRatioBX96,
uint256 amount0
) internal pure returns (uint128 liquidity) {
if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
}

/// @notice Computes the amount of liquidity received for a given amount of token1 and price range
/// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
/// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
/// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
/// @param amount1 The amount1 being sent in
/// @return liquidity The amount of returned liquidity
function getLiquidityForAmount1(
uint160 sqrtRatioAX96,
uint160 sqrtRatioBX96,
uint256 amount1
) internal pure returns (uint128 liquidity) {
if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
}

/// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
/// pool prices and the prices at the tick boundaries
/// @param sqrtRatioX96 A sqrt price representing the current pool prices
/// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
/// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
/// @param amount0 The amount of token0 being sent in
/// @param amount1 The amount of token1 being sent in
/// @return liquidity The maximum amount of liquidity received
function getLiquidityForAmounts(
uint160 sqrtRatioX96,
uint160 sqrtRatioAX96,
uint160 sqrtRatioBX96,
uint256 amount0,
uint256 amount1
) internal pure returns (uint128 liquidity) {
if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

if (sqrtRatioX96 <= sqrtRatioAX96) {
liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
} else if (sqrtRatioX96 < sqrtRatioBX96) {
uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
} else {
liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
}
}

/// @notice Computes the amount of token0 for a given amount of liquidity and a price range
/// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
/// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
/// @param liquidity The liquidity being valued
/// @return amount0 The amount of token0
function getAmount0ForLiquidity(
uint160 sqrtRatioAX96,
uint160 sqrtRatioBX96,
uint128 liquidity
) internal pure returns (uint256 amount0) {
if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

return
FullMath.mulDiv(
uint256(liquidity) << FixedPoint96.RESOLUTION,
sqrtRatioBX96 - sqrtRatioAX96,
sqrtRatioBX96
) / sqrtRatioAX96;
}

/// @notice Computes the amount of token1 for a given amount of liquidity and a price range
/// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
/// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
/// @param liquidity The liquidity being valued
/// @return amount1 The amount of token1
function getAmount1ForLiquidity(
uint160 sqrtRatioAX96,
uint160 sqrtRatioBX96,
uint128 liquidity
) internal pure returns (uint256 amount1) {
if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
}

/// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
/// pool prices and the prices at the tick boundaries
/// @param sqrtRatioX96 A sqrt price representing the current pool prices
/// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
/// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
/// @param liquidity The liquidity being valued
/// @return amount0 The amount of token0
/// @return amount1 The amount of token1
function getAmountsForLiquidity(
uint160 sqrtRatioX96,
uint160 sqrtRatioAX96,
uint160 sqrtRatioBX96,
uint128 liquidity
) internal pure returns (uint256 amount0, uint256 amount1) {
if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

if (sqrtRatioX96 <= sqrtRatioAX96) {
amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
} else if (sqrtRatioX96 < sqrtRatioBX96) {
amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
} else {
amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
}
}
}
library FixedPoint96 {
uint8 internal constant RESOLUTION = 96;
uint256 internal constant Q96 = 0x1000000000000000000000000;
}
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
interface IWETH9 is IERC20 {
/// @notice Deposit ether to get wrapped ether
function deposit() external payable;

/// @notice Withdraw wrapped ether to get ether
function withdraw(uint256) external;
}
library TransferHelper {
/// @notice Transfers tokens from the targeted address to the given destination
/// @notice Errors with 'STF' if transfer fails
/// @param token The contract address of the token to be transferred
/// @param from The originating address from which the tokens will be transferred
/// @param to The destination address of the transfer
/// @param value The amount to be transferred
function safeTransferFrom(
address token,
address from,
address to,
uint256 value
) internal {
(bool success, bytes memory data) =
token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
}

/// @notice Transfers tokens from msg.sender to a recipient
/// @dev Errors with ST if transfer fails
/// @param token The contract address of the token which will be transferred
/// @param to The recipient of the transfer
/// @param value The value of the transfer
function safeTransfer(
address token,
address to,
uint256 value
) internal {
(bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
}

/// @notice Approves the stipulated contract to spend the given allowance in the given token
/// @dev Errors with 'SA' if transfer fails
/// @param token The contract address of the token to be approved
/// @param to The target of the approval
/// @param value The amount of the given token the target will be allowed to spend
function safeApprove(
address token,
address to,
uint256 value
) internal {
(bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
}

/// @notice Transfers ETH to the recipient address
/// @dev Fails with `STE`
/// @param to The destination of the transfer
/// @param value The value to be transferred
function safeTransferETH(address to, uint256 value) internal {
(bool success, ) = to.call{value: value}(new bytes(0));
require(success, 'STE');
}
}
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
library SafeMath {
/**
 * @dev Returns the addition of two unsigned integers, with an overflow flag.
 *
 * _Available since v3.4._
 */
function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
uint256 c = a + b;
if (c < a) return (false, 0);
return (true, c);
}

/**
 * @dev Returns the substraction of two unsigned integers, with an overflow flag.
 *
 * _Available since v3.4._
 */
function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
if (b > a) return (false, 0);
return (true, a - b);
}

/**
 * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
 *
 * _Available since v3.4._
 */
function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
// benefit is lost if 'b' is also tested.
// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
if (a == 0) return (true, 0);
uint256 c = a * b;
if (c / a != b) return (false, 0);
return (true, c);
}

/**
 * @dev Returns the division of two unsigned integers, with a division by zero flag.
 *
 * _Available since v3.4._
 */
function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
if (b == 0) return (false, 0);
return (true, a / b);
}

/**
 * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
 *
 * _Available since v3.4._
 */
function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
if (b == 0) return (false, 0);
return (true, a % b);
}

/**
 * @dev Returns the addition of two unsigned integers, reverting on
 * overflow.
 *
 * Counterpart to Solidity's `+` operator.
 *
 * Requirements:
 *
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
 *
 * - Subtraction cannot overflow.
 */
function sub(uint256 a, uint256 b) internal pure returns (uint256) {
require(b <= a, "SafeMath: subtraction overflow");
return a - b;
}

/**
 * @dev Returns the multiplication of two unsigned integers, reverting on
 * overflow.
 *
 * Counterpart to Solidity's `*` operator.
 *
 * Requirements:
 *
 * - Multiplication cannot overflow.
 */
function mul(uint256 a, uint256 b) internal pure returns (uint256) {
if (a == 0) return 0;
uint256 c = a * b;
require(c / a == b, "SafeMath: multiplication overflow");
return c;
}

/**
 * @dev Returns the integer division of two unsigned integers, reverting on
 * division by zero. The result is rounded towards zero.
 *
 * Counterpart to Solidity's `/` operator. Note: this function uses a
 * `revert` opcode (which leaves remaining gas untouched) while Solidity
 * uses an invalid opcode to revert (consuming all remaining gas).
 *
 * Requirements:
 *
 * - The divisor cannot be zero.
 */
function div(uint256 a, uint256 b) internal pure returns (uint256) {
require(b > 0, "SafeMath: division by zero");
return a / b;
}

/**
 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
 * reverting when dividing by zero.
 *
 * Counterpart to Solidity's `%` operator. This function uses a `revert`
 * opcode (which leaves remaining gas untouched) while Solidity uses an
 * invalid opcode to revert (consuming all remaining gas).
 *
 * Requirements:
 *
 * - The divisor cannot be zero.
 */
function mod(uint256 a, uint256 b) internal pure returns (uint256) {
require(b > 0, "SafeMath: modulo by zero");
return a % b;
}

/**
 * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
 * overflow (when the result is negative).
 *
 * CAUTION: This function is deprecated because it requires allocating memory for the error
 * message unnecessarily. For custom revert reasons use {trySub}.
 *
 * Counterpart to Solidity's `-` operator.
 *
 * Requirements:
 *
 * - Subtraction cannot overflow.
 */
function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
require(b <= a, errorMessage);
return a - b;
}

/**
 * @dev Returns the integer division of two unsigned integers, reverting with custom message on
 * division by zero. The result is rounded towards zero.
 *
 * CAUTION: This function is deprecated because it requires allocating memory for the error
 * message unnecessarily. For custom revert reasons use {tryDiv}.
 *
 * Counterpart to Solidity's `/` operator. Note: this function uses a
 * `revert` opcode (which leaves remaining gas untouched) while Solidity
 * uses an invalid opcode to revert (consuming all remaining gas).
 *
 * Requirements:
 *
 * - The divisor cannot be zero.
 */
function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
require(b > 0, errorMessage);
return a / b;
}

/**
 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
 * reverting with custom message when dividing by zero.
 *
 * CAUTION: This function is deprecated because it requires allocating memory for the error
 * message unnecessarily. For custom revert reasons use {tryMod}.
 *
 * Counterpart to Solidity's `%` operator. This function uses a `revert`
 * opcode (which leaves remaining gas untouched) while Solidity uses an
 * invalid opcode to revert (consuming all remaining gas).
 *
 * Requirements:
 *
 * - The divisor cannot be zero.
 */
function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
require(b > 0, errorMessage);
return a % b;
}
}
library EnumerableSet {
// To implement this library for multiple types with as little code
// repetition as possible, we write it in terms of a generic Set type with
// bytes32 values.
// The Set implementation uses private functions, and user-facing
// implementations (such as AddressSet) are just wrappers around the
// underlying Set.
// This means that we can only create new EnumerableSets for types that fit
// in bytes32.

struct Set {
// Storage of set values
bytes32[] _values;

// Position of the value in the `values` array, plus 1 because index 0
// means a value is not in the set.
mapping (bytes32 => uint256) _indexes;
}

/**
 * @dev Add a value to a set. O(1).
 *
 * Returns true if the value was added to the set, that is if it was not
 * already present.
 */
function _add(Set storage set, bytes32 value) private returns (bool) {
if (!_contains(set, value)) {
set._values.push(value);
// The value is stored at length-1, but we add 1 to all indexes
// and use 0 as a sentinel value
set._indexes[value] = set._values.length;
return true;
} else {
return false;
}
}

/**
 * @dev Removes a value from a set. O(1).
 *
 * Returns true if the value was removed from the set, that is if it was
 * present.
 */
function _remove(Set storage set, bytes32 value) private returns (bool) {
// We read and store the value's index to prevent multiple reads from the same storage slot
uint256 valueIndex = set._indexes[value];

if (valueIndex != 0) { // Equivalent to contains(set, value)
// To delete an element from the _values array in O(1), we swap the element to delete with the last one in
// the array, and then remove the last element (sometimes called as 'swap and pop').
// This modifies the order of the array, as noted in {at}.

uint256 toDeleteIndex = valueIndex - 1;
uint256 lastIndex = set._values.length - 1;

// When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
// so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

bytes32 lastvalue = set._values[lastIndex];

// Move the last value to the index where the value to delete is
set._values[toDeleteIndex] = lastvalue;
// Update the index for the moved value
set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

// Delete the slot where the moved value was stored
set._values.pop();

// Delete the index for the deleted slot
delete set._indexes[value];

return true;
} else {
return false;
}
}

/**
 * @dev Returns true if the value is in the set. O(1).
 */
function _contains(Set storage set, bytes32 value) private view returns (bool) {
return set._indexes[value] != 0;
}

/**
 * @dev Returns the number of values on the set. O(1).
 */
function _length(Set storage set) private view returns (uint256) {
return set._values.length;
}

/**
 * @dev Returns the value stored at position `index` in the set. O(1).
 *
 * Note that there are no guarantees on the ordering of values inside the
 * array, and it may change when more values are added or removed.
 *
 * Requirements:
 *
 * - `index` must be strictly less than {length}.
 */
function _at(Set storage set, uint256 index) private view returns (bytes32) {
require(set._values.length > index, "EnumerableSet: index out of bounds");
return set._values[index];
}

// Bytes32Set

struct Bytes32Set {
Set _inner;
}

/**
 * @dev Add a value to a set. O(1).
 *
 * Returns true if the value was added to the set, that is if it was not
 * already present.
 */
function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
return _add(set._inner, value);
}

/**
 * @dev Removes a value from a set. O(1).
 *
 * Returns true if the value was removed from the set, that is if it was
 * present.
 */
function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
return _remove(set._inner, value);
}

/**
 * @dev Returns true if the value is in the set. O(1).
 */
function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
return _contains(set._inner, value);
}

/**
 * @dev Returns the number of values in the set. O(1).
 */
function length(Bytes32Set storage set) internal view returns (uint256) {
return _length(set._inner);
}

/**
 * @dev Returns the value stored at position `index` in the set. O(1).
 *
 * Note that there are no guarantees on the ordering of values inside the
 * array, and it may change when more values are added or removed.
 *
 * Requirements:
 *
 * - `index` must be strictly less than {length}.
 */
function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
return _at(set._inner, index);
}

// AddressSet

struct AddressSet {
Set _inner;
}

/**
 * @dev Add a value to a set. O(1).
 *
 * Returns true if the value was added to the set, that is if it was not
 * already present.
 */
function add(AddressSet storage set, address value) internal returns (bool) {
return _add(set._inner, bytes32(uint256(uint160(value))));
}

/**
 * @dev Removes a value from a set. O(1).
 *
 * Returns true if the value was removed from the set, that is if it was
 * present.
 */
function remove(AddressSet storage set, address value) internal returns (bool) {
return _remove(set._inner, bytes32(uint256(uint160(value))));
}

/**
 * @dev Returns true if the value is in the set. O(1).
 */
function contains(AddressSet storage set, address value) internal view returns (bool) {
return _contains(set._inner, bytes32(uint256(uint160(value))));
}

/**
 * @dev Returns the number of values in the set. O(1).
 */
function length(AddressSet storage set) internal view returns (uint256) {
return _length(set._inner);
}

/**
 * @dev Returns the value stored at position `index` in the set. O(1).
 *
 * Note that there are no guarantees on the ordering of values inside the
 * array, and it may change when more values are added or removed.
 *
 * Requirements:
 *
 * - `index` must be strictly less than {length}.
 */
function at(AddressSet storage set, uint256 index) internal view returns (address) {
return address(uint160(uint256(_at(set._inner, index))));
}


// UintSet

struct UintSet {
Set _inner;
}

/**
 * @dev Add a value to a set. O(1).
 *
 * Returns true if the value was added to the set, that is if it was not
 * already present.
 */
function add(UintSet storage set, uint256 value) internal returns (bool) {
return _add(set._inner, bytes32(value));
}

/**
 * @dev Removes a value from a set. O(1).
 *
 * Returns true if the value was removed from the set, that is if it was
 * present.
 */
function remove(UintSet storage set, uint256 value) internal returns (bool) {
return _remove(set._inner, bytes32(value));
}

/**
 * @dev Returns true if the value is in the set. O(1).
 */
function contains(UintSet storage set, uint256 value) internal view returns (bool) {
return _contains(set._inner, bytes32(value));
}

/**
 * @dev Returns the number of values on the set. O(1).
 */
function length(UintSet storage set) internal view returns (uint256) {
return _length(set._inner);
}

/**
 * @dev Returns the value stored at position `index` in the set. O(1).
 *
 * Note that there are no guarantees on the ordering of values inside the
 * array, and it may change when more values are added or removed.
 *
 * Requirements:
 *
 * - `index` must be strictly less than {length}.
 */
function at(UintSet storage set, uint256 index) internal view returns (uint256) {
return uint256(_at(set._inner, index));
}
}
library EnumerableMap {
// To implement this library for multiple types with as little code
// repetition as possible, we write it in terms of a generic Map type with
// bytes32 keys and values.
// The Map implementation uses private functions, and user-facing
// implementations (such as Uint256ToAddressMap) are just wrappers around
// the underlying Map.
// This means that we can only create new EnumerableMaps for types that fit
// in bytes32.

struct MapEntry {
bytes32 _key;
bytes32 _value;
}

struct Map {
// Storage of map keys and values
MapEntry[] _entries;

// Position of the entry defined by a key in the `entries` array, plus 1
// because index 0 means a key is not in the map.
mapping (bytes32 => uint256) _indexes;
}

/**
 * @dev Adds a key-value pair to a map, or updates the value for an existing
 * key. O(1).
 *
 * Returns true if the key was added to the map, that is if it was not
 * already present.
 */
function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
// We read and store the key's index to prevent multiple reads from the same storage slot
uint256 keyIndex = map._indexes[key];

if (keyIndex == 0) { // Equivalent to !contains(map, key)
map._entries.push(MapEntry({ _key: key, _value: value }));
// The entry is stored at length-1, but we add 1 to all indexes
// and use 0 as a sentinel value
map._indexes[key] = map._entries.length;
return true;
} else {
map._entries[keyIndex - 1]._value = value;
return false;
}
}

/**
 * @dev Removes a key-value pair from a map. O(1).
 *
 * Returns true if the key was removed from the map, that is if it was present.
 */
function _remove(Map storage map, bytes32 key) private returns (bool) {
// We read and store the key's index to prevent multiple reads from the same storage slot
uint256 keyIndex = map._indexes[key];

if (keyIndex != 0) { // Equivalent to contains(map, key)
// To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
// in the array, and then remove the last entry (sometimes called as 'swap and pop').
// This modifies the order of the array, as noted in {at}.

uint256 toDeleteIndex = keyIndex - 1;
uint256 lastIndex = map._entries.length - 1;

// When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
// so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

MapEntry storage lastEntry = map._entries[lastIndex];

// Move the last entry to the index where the entry to delete is
map._entries[toDeleteIndex] = lastEntry;
// Update the index for the moved entry
map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

// Delete the slot where the moved entry was stored
map._entries.pop();

// Delete the index for the deleted slot
delete map._indexes[key];

return true;
} else {
return false;
}
}

/**
 * @dev Returns true if the key is in the map. O(1).
 */
function _contains(Map storage map, bytes32 key) private view returns (bool) {
return map._indexes[key] != 0;
}

/**
 * @dev Returns the number of key-value pairs in the map. O(1).
 */
function _length(Map storage map) private view returns (uint256) {
return map._entries.length;
}

/**
 * @dev Returns the key-value pair stored at position `index` in the map. O(1).
 *
 * Note that there are no guarantees on the ordering of entries inside the
 * array, and it may change when more entries are added or removed.
 *
 * Requirements:
 *
 * - `index` must be strictly less than {length}.
 */
function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
require(map._entries.length > index, "EnumerableMap: index out of bounds");

MapEntry storage entry = map._entries[index];
return (entry._key, entry._value);
}

/**
 * @dev Tries to returns the value associated with `key`.  O(1).
 * Does not revert if `key` is not in the map.
 */
function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
uint256 keyIndex = map._indexes[key];
if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
}

/**
 * @dev Returns the value associated with `key`.  O(1).
 *
 * Requirements:
 *
 * - `key` must be in the map.
 */
function _get(Map storage map, bytes32 key) private view returns (bytes32) {
uint256 keyIndex = map._indexes[key];
require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
return map._entries[keyIndex - 1]._value; // All indexes are 1-based
}

/**
 * @dev Same as {_get}, with a custom error message when `key` is not in the map.
 *
 * CAUTION: This function is deprecated because it requires allocating memory for the error
 * message unnecessarily. For custom revert reasons use {_tryGet}.
 */
function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
uint256 keyIndex = map._indexes[key];
require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
return map._entries[keyIndex - 1]._value; // All indexes are 1-based
}

// UintToAddressMap

struct UintToAddressMap {
Map _inner;
}

/**
 * @dev Adds a key-value pair to a map, or updates the value for an existing
 * key. O(1).
 *
 * Returns true if the key was added to the map, that is if it was not
 * already present.
 */
function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
}

/**
 * @dev Removes a value from a set. O(1).
 *
 * Returns true if the key was removed from the map, that is if it was present.
 */
function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
return _remove(map._inner, bytes32(key));
}

/**
 * @dev Returns true if the key is in the map. O(1).
 */
function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
return _contains(map._inner, bytes32(key));
}

/**
 * @dev Returns the number of elements in the map. O(1).
 */
function length(UintToAddressMap storage map) internal view returns (uint256) {
return _length(map._inner);
}

/**
 * @dev Returns the element stored at position `index` in the set. O(1).
 * Note that there are no guarantees on the ordering of values inside the
 * array, and it may change when more values are added or removed.
 *
 * Requirements:
 *
 * - `index` must be strictly less than {length}.
 */
function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
(bytes32 key, bytes32 value) = _at(map._inner, index);
return (uint256(key), address(uint160(uint256(value))));
}

/**
 * @dev Tries to returns the value associated with `key`.  O(1).
 * Does not revert if `key` is not in the map.
 *
 * _Available since v3.4._
 */
function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
(bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
return (success, address(uint160(uint256(value))));
}

/**
 * @dev Returns the value associated with `key`.  O(1).
 *
 * Requirements:
 *
 * - `key` must be in the map.
 */
function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
return address(uint160(uint256(_get(map._inner, bytes32(key)))));
}

/**
 * @dev Same as {get}, with a custom error message when `key` is not in the map.
 *
 * CAUTION: This function is deprecated because it requires allocating memory for the error
 * message unnecessarily. For custom revert reasons use {tryGet}.
 */
function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
}
}
library Strings {
/**
 * @dev Converts a `uint256` to its ASCII `string` representation.
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
uint256 index = digits - 1;
temp = value;
while (temp != 0) {
buffer[index--] = bytes1(uint8(48 + temp % 10));
temp /= 10;
}
return string(buffer);
}
}
library ChainId {
/// @dev Gets the current chain ID
/// @return chainId The current chain ID
function get() internal pure returns (uint256 chainId) {
assembly {
chainId := chainid()
}
}
}