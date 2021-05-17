// SPDX-License-Identifier: Unlicense

pragma solidity =0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./Address.sol";
import "./TickMath.sol";
import "./LiquidityAmounts.sol";

import {Yang} from "./YangNFT.sol";

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

interface INonfungiblePositionManager {
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

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

    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
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

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    function burn(uint256 tokenId) external payable;
}

interface IUniswapV3PoolActions {
    function initialize(uint160 sqrtPriceX96) external;
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
    function tickSpacing() external view returns (int24);
    function maxLiquidityPerTick() external view returns (uint128);
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
}

interface IUniswapV3Factory {
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);
}

interface IUniversalVault {
    struct DelegateVault {
        uint256 tokenId;
        address delegate;
        address token;
        uint256 balance;
    }

    struct DelegateLiquidity {
        uint256 tokenId;
        uint256 uniTokenId;
        address delegate;
        address lptoken;
        address token0;
        address token1;
        uint24 fee;
        uint256 liquidity;
    }

    struct DelegateFee {
        address token0;
        address token1;
        uint256 fee0;
        uint256 fee1;
    }

    struct MintLiquidParam {
        address token0;
        address token1;
        uint256 amount0;
        uint256 amount1;
        uint256 amount0Min;
        uint256 amount1Min;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 deadline;
    }

    struct BurnLiquidParam {
        uint256 uniTokenId;
        address lptoken;
    }

    function deposit(uint256 tokenId, address token, uint256 amount) external;
    function withdraw(uint256 tokenId, address token, uint256 amount) external;

    event Deposit(uint256 tokenId, address delegate, address token, uint256 amount);
    event Withdraw(uint256 tokenId, address delegate, address token, uint256 amount);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

contract UniversalVault is
    IUniversalVault,
    ReentrancyGuard
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    address internal constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address internal constant UNISWAP_V3_SWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address internal constant POSITION_MANAGER = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    uint128 internal constant MAX_UINT128 = 340282366920938463463374607431768211455;

    Yang private nft;
    address private grandmaster;
    address private governance;
    address private factory;
    address private manager;
    IUniswapV3Factory private uniswapV3Factory;
    INonfungiblePositionManager private positionManager;

    constructor(
        address _nft,
        address _grandmaster,
        address _governance,
        address _factory,
        address _manager
    ) {
        positionManager = INonfungiblePositionManager(_manager);
        uniswapV3Factory = IUniswapV3Factory(_factory);

        nft = Yang(_nft);
        grandmaster = _grandmaster;
        governance = _governance;
        factory = _factory;
        manager = _manager;
    }

    mapping(bytes32 => DelegateVault) private delegateVaults;
    EnumerableSet.Bytes32Set private delegateVaultSet;

    mapping(bytes32 => DelegateLiquidity) private delegateLiquidities;
    EnumerableSet.Bytes32Set private delegateLiquidSet;

    mapping(bytes32 => DelegateFee) private delegateFees;
    EnumerableSet.Bytes32Set private delegateFeeSet;


    modifier onlyGrandMaster(address sender) {
        require(sender == grandmaster, "Only GrandMaster");
        _;
    }

    function calculateHashKey(uint256 tokenId, address delegate, address token)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(tokenId, delegate, token));
    }

    function deposit(uint256 tokenId, address token, uint256 amount) external override {
        require(nft.ownerOf(tokenId) == msg.sender, "Invalid auth");
        require(amount > 0, "Invalid amount");

        IERC20 vault = IERC20(token);
        vault.safeTransferFrom(msg.sender, address(this), amount);
        bytes32 key = calculateHashKey(tokenId, msg.sender, token);

        if (delegateVaultSet.contains(key)) {
            delegateVaults[key].balance = delegateVaults[key].balance.add(amount);
        } else {
            assert(delegateVaultSet.add(key));
            delegateVaults[key] = DelegateVault(tokenId, msg.sender, token, amount);
        }

        emit Deposit(tokenId, msg.sender, token, amount);
    }

    function withdraw(uint256 tokenId, address token, uint256 amount) external override {
        require(nft.ownerOf(tokenId) == msg.sender, "Invalid auth");
        IERC20 vault = IERC20(token);
        require(vault.balanceOf(address(this)) >= amount, "Insufficient balance");

        bytes32 key = calculateHashKey(tokenId, msg.sender, token);
        require(delegateVaultSet.contains(key), "Missing delegate vault key");
        require(delegateVaults[key].balance >= amount, "Invalid balance amount");
        if (delegateVaults[key].balance >= amount) {
            delegateVaults[key].balance = delegateVaults[key].balance.sub(amount);
        }
        vault.approve(address(this), amount);
        vault.safeTransferFrom(address(this), msg.sender, amount);
        emit Withdraw(tokenId, msg.sender, token, amount);
    }

    function getVaultBalance(uint256 tokenId, address delegate, address token) external view returns (uint256)
    {
        bytes32 key = calculateHashKey(tokenId, delegate, token);
        return _getBalance(key);
    }

    function _getBalance(bytes32 key) internal view returns (uint256)
    {
        require(delegateVaultSet.contains(key), "missing delegate key");
        return delegateVaults[key].balance;
    }

    function _amountsForLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        IUniswapV3PoolActions pool
    ) internal view returns (uint256, uint256) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        return
            LiquidityAmounts.getAmountsForLiquidity(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidity
            );
    }

    function _liquidityForAmounts(
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1,
        IUniswapV3PoolActions pool
    ) internal view returns (uint128)
    {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        return
            LiquidityAmounts.getLiquidityForAmounts(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                amount0,
                amount1
            );
    }

    function _addLiquidity(
        uint256 tokenId,
        uint256 uniTokenId,
        uint256 amount0,
        uint256 amount1,
        address delegate,
        address lptoken,
        uint128 liquidity,
        MintLiquidParam memory param
    ) internal
    {
        bytes32 lpKey = calculateHashKey(tokenId, delegate, lptoken);
        bytes32 key0 = calculateHashKey(tokenId, delegate, param.token0);
        bytes32 key1 = calculateHashKey(tokenId, delegate, param.token1);
        require(delegateVaults[key0].balance >= amount0, "Insufficient amount0");
        require(delegateVaults[key1].balance >= amount1, "Insufficient amount1");

        delegateVaults[key0].balance = delegateVaults[key0].balance.sub(amount0);
        delegateVaults[key1].balance = delegateVaults[key1].balance.sub(amount1);

        if (delegateLiquidSet.contains(lpKey)) {
            delegateLiquidities[lpKey].liquidity = delegateLiquidities[lpKey].liquidity.add(liquidity);
        } else{
            assert(delegateLiquidSet.add(lpKey));
            delegateLiquidities[lpKey] = DelegateLiquidity(tokenId,
                                                           uniTokenId,
                                                           delegate,
                                                           lptoken,
                                                           param.token0,
                                                           param.token1,
                                                           param.fee,
                                                           liquidity);
        }
    }

    function _mintLiquidity(
        uint256 tokenId,
        address delegate,
        address lptoken,
        MintLiquidParam memory param
    ) internal returns (uint256 uniTokenId, uint128 liquidity, uint256 ret0, uint256 ret1) {
        (uniTokenId, liquidity, ret0, ret1) = positionManager.mint(
            INonfungiblePositionManager.MintParams({
                token0: param.token0,
                token1: param.token1,
                fee: param.fee,
                tickLower: param.tickLower,
                tickUpper: param.tickUpper,
                amount0Desired: param.amount0,
                amount1Desired: param.amount1,
                amount0Min: param.amount0Min,
                amount1Min: param.amount1Min,
                recipient: address(this),
                deadline: param.deadline
            })
        );
        _addLiquidity(tokenId, uniTokenId, ret0, ret1, delegate, lptoken, liquidity, param);
    }

    function mintLiquidity(
        uint256 tokenId,
        address delegate,
        bytes calldata data
    )
        onlyGrandMaster(msg.sender)
        external
        nonReentrant
        returns (uint256 uniTokenId, uint128 liquidity, uint256 ret0, uint256 ret1)
    {
        require(nft.ownerOf(tokenId) == delegate, "Invalid auth");
        MintLiquidParam memory param = abi.decode(data, (MintLiquidParam));

        PoolAddress.PoolKey memory poolKey = PoolAddress.PoolKey({token0: param.token0, token1: param.token1, fee: param.fee});
        address lptoken = PoolAddress.computeAddress(address(factory), poolKey);
        IUniswapV3PoolActions pool = IUniswapV3PoolActions(lptoken);

        bytes32 key0 = calculateHashKey(tokenId, delegate, param.token0);
        bytes32 key1 = calculateHashKey(tokenId, delegate, param.token1);
        require(_getBalance(key0) >= param.amount0, "Insufficient balance0");
        require(_getBalance(key1) >= param.amount1, "Insufficient balance1");
        return _mintLiquidity(tokenId, delegate, lptoken, param);
    }

    function _collectFee(uint256 tokenId, uint256 uniTokenId, bytes32 lpkey) internal returns (int24, int24, uint128) {
        (, , address token0, address token1, , int24 tickLower, int24 tickUpper, uint128 liquidity, , , ,) = positionManager.positions(tokenId);
        (uint256 fee0, uint256 fee1) = positionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: uniTokenId,
                recipient: address(this),
                amount0Max: MAX_UINT128,
                amount1Max: MAX_UINT128
            })
        );
        if (fee0 > 0 && fee1 > 0) {
            IERC20(token0).transfer(governance, fee0.mul(3).div(100));
            IERC20(token1).transfer(governance, fee1.mul(3).div(100));
            if (delegateFeeSet.contains(lpkey)) {
                delegateFees[lpkey].fee0 = delegateFees[lpkey].fee0.add(fee0.mul(97).div(100));
                delegateFees[lpkey].fee1 = delegateFees[lpkey].fee1.add(fee1.mul(97).div(100));
            } else {
                assert(delegateFeeSet.add(lpkey));
                delegateFees[lpkey] = DelegateFee(token0, token1, fee0, fee1);
            }
        }
        return (tickLower, tickUpper, liquidity);
    }

    function _updateLiquidity(
        uint256 tokenId,
        address delegate,
        bytes32 lpkey,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) internal returns (uint256 amount0, uint256 amount1) {
        require(delegateLiquidSet.contains(lpkey), "delegate liquid set missing key");

        address lptoken = delegateLiquidities[lpkey].lptoken;
        IUniswapV3PoolActions pool = IUniswapV3PoolActions(lptoken);
        (amount0, amount1) = _amountsForLiquidity(tickLower, tickUpper, liquidity, pool);

        bytes32 key0 = calculateHashKey(tokenId, delegate, delegateLiquidities[lpkey].token0);
        bytes32 key1 = calculateHashKey(tokenId, delegate, delegateLiquidities[lpkey].token1);
        require(delegateVaultSet.contains(key0), "delegate vault set missing key0");
        require(delegateVaultSet.contains(key1), "delegate vault set missing key1");
        delegateVaults[key0].balance = delegateVaults[key0].balance.add(amount0);
        delegateVaults[key1].balance = delegateVaults[key1].balance.add(amount1);

        delegateLiquidities[lpkey].liquidity = delegateLiquidities[lpkey].liquidity.sub(liquidity);
    }

    function burnLiquidity(uint256 tokenId, address delegate, bytes calldata data)
        onlyGrandMaster(msg.sender)
        external
        nonReentrant
        returns (uint256 amount0, uint256 amount1, uint128 liquidity)
    {
        require(nft.ownerOf(tokenId) == delegate, "Invalid auth");
        BurnLiquidParam memory param = abi.decode(data, (BurnLiquidParam));

        bytes32 lpkey = calculateHashKey(tokenId, delegate, param.lptoken);
        require(delegateLiquidSet.contains(lpkey), "LP key does not exist in delegate liquidity set");

        (int24 tickLower, int24 tickUpper, uint128 _liquidity) = _collectFee(tokenId, param.uniTokenId, lpkey);
        positionManager.burn(param.uniTokenId);
        liquidity = _liquidity;
        (amount0, amount1) = _updateLiquidity(tokenId, delegate, lpkey, tickLower, tickUpper, liquidity);
    }
}