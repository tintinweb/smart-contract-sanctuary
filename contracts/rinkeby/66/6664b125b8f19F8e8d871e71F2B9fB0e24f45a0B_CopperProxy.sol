// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import {TransferHelper} from "./TransferHelper.sol";
import {IERC20} from "./IERC20.sol";
import {Ownable} from "./Ownable.sol";
import {EnumerableSet} from "./EnumerableSet.sol";

interface LBPFactory {
    function create(
        string memory name,
        string memory symbol,
        address[] memory tokens,
        uint256[] memory weights,
        uint256 swapFeePercentage,
        address owner,
        bool swapEnabledOnStart
    ) external returns (address);
}

interface Vault {
    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external;

    function exitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        ExitPoolRequest memory request
    ) external;

    function getPoolTokens(bytes32 poolId)
    external
    view
    returns (
        address[] memory tokens,
        uint256[] memory balances,
        uint256 lastChangeBlock
    );
}

interface LBP {
    function updateWeightsGradually(
        uint256 startTime,
        uint256 endTime,
        uint256[] memory endWeights
    ) external;

    function setSwapEnabled(bool swapEnabled) external;

    function getPoolId() external returns (bytes32 poolID);
}

/// @title CopperProxy
/// @notice This contract allows for simplified creation and management of Balancer LBPs
/// It currently supports:
/// - LBPs with 2 tokens
/// - Withdrawl of the full liquidity at once
/// - Charging a fee on the amount raised
contract CopperProxy is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct PoolData {
        address owner;
        bool isCorrectOrder;
        uint256 fundTokenInputAmount;
    }

    mapping(address => PoolData) private _poolData;
    EnumerableSet.AddressSet private _pools;

    address public constant VAULT = address(0xF07513C68C55A31337E3b58034b176A15Dce16eD);
    address public immutable _LBPFactoryAddress;
    uint256 public immutable _feeBPS;
    address public _feeRecipient;

    constructor(
        uint256 feeBPS,
        address feeRecipient,
        address LBPFactoryAddress
    ) {
        _feeBPS = feeBPS;
        _feeRecipient = feeRecipient;
        _LBPFactoryAddress = LBPFactoryAddress;
    }

    // Events
    event PoolCreated(
        address indexed pool,
        bytes32 poolId,
        string  name,
        string  symbol,
        address[]  tokens,
        uint256[]  weights,
        uint256 swapFeePercentage,
        address owner,
        bool swapEnabledOnStart
    );

    event JoinedPool(address indexed pool, address[] tokens, uint256[] amounts, bytes userData);

    event GradualWeightUpdateScheduled(address indexed pool, uint256 startTime, uint256 endTime, uint256[] endWeights);

    event SwapEnabledSet(address indexed pool, bool swapEnabled);

    event TransferedPoolOwnership(address indexed pool, address previousOwner, address newOwner);

    event ExitedPool(address indexed pool, address[] tokens, uint256[] minAmountsOut, bytes userData);

    event TransferedFee(address indexed pool, address token, address feeRecipient, uint256 feeAmount);

    event TransferedToken(address indexed pool, address token, address to, uint256 amount);

    event ChangedFeeRecipient(address previousRecipient, address newRecipient);

    event Skimmed(address token, address to, uint256 balance);

    // Pool access control
    modifier onlyPoolOwner(address pool) {
        require(msg.sender == _poolData[pool].owner, "!owner");
        _;
    }

    function isPool(address pool) external view returns (bool valid) {
        return _pools.contains(pool);
    }

    function poolCount() external view returns (uint256 count) {
        return _pools.length();
    }

    function getPoolAt(uint256 index) external view returns (address pool) {
        return _pools.at(index);
    }

    function getPools() external view returns (address[] memory pools) {
        return _pools.values();
    }

    function getPoolData(address pool) external view returns (PoolData memory poolData) {
        return _poolData[pool];
    }

    function getBPTTokenBalance(address pool) external view returns (uint256 bptBalance) {
        return IERC20(pool).balanceOf(address(this));
    }

    struct PoolConfig {
        string name;
        string symbol;
        address[] tokens;
        uint256[] amounts;
        uint256[] weights;
        uint256[] endWeights;
        bool isCorrectOrder;
        uint256 swapFeePercentage;
        bytes userData;
        uint256 startTime;
        uint256 endTime;
    }

    function createAuction(PoolConfig memory poolConfig) external returns (address) {
        // 1: deposit tokens and approve vault
        require(poolConfig.tokens.length == 2, "only two tokens");
        TransferHelper.safeTransferFrom(poolConfig.tokens[0], msg.sender, address(this), poolConfig.amounts[0]);
        TransferHelper.safeTransferFrom(poolConfig.tokens[1], msg.sender, address(this), poolConfig.amounts[1]);
        TransferHelper.safeApprove(poolConfig.tokens[0], VAULT, poolConfig.amounts[0]);
        TransferHelper.safeApprove(poolConfig.tokens[1], VAULT, poolConfig.amounts[1]);

        // 2: pool creation
        address pool = LBPFactory(_LBPFactoryAddress).create(
            poolConfig.name,
            poolConfig.symbol,
            poolConfig.tokens,
            poolConfig.weights,
            poolConfig.swapFeePercentage,
            address(this), // owner set to this proxy
            false // swaps disabled on start
        );

        bytes32 poolId = LBP(pool).getPoolId();
        emit PoolCreated(
            pool,
            poolId,
            poolConfig.name,
            poolConfig.symbol,
            poolConfig.tokens,
            poolConfig.weights,
            poolConfig.swapFeePercentage,
            address(this),
            false
        );

        // 3: store pool data
        _poolData[pool] = PoolData(
            msg.sender,
            poolConfig.isCorrectOrder,
            poolConfig.amounts[poolConfig.isCorrectOrder ? 0 : 1]
        );
        require(_pools.add(pool), "exists already");

        // 4: deposit tokens into pool
        Vault(VAULT).joinPool(
            poolId,
            address(this), // sender
            address(this), // recipient
            Vault.JoinPoolRequest(poolConfig.tokens, poolConfig.amounts, poolConfig.userData, false)
        );
        emit JoinedPool(pool, poolConfig.tokens, poolConfig.amounts, poolConfig.userData);

        // 5: configure weights
        LBP(pool).updateWeightsGradually(poolConfig.startTime, poolConfig.endTime, poolConfig.endWeights);
        emit GradualWeightUpdateScheduled(pool, poolConfig.startTime, poolConfig.endTime, poolConfig.endWeights);

        return pool;
    }

    function setSwapEnabled(address pool, bool swapEnabled) external onlyPoolOwner(pool) {
        LBP(pool).setSwapEnabled(swapEnabled);
        emit SwapEnabledSet(pool, swapEnabled);
    }

    function transferPoolOwnership(address pool, address newOwner) external onlyPoolOwner(pool) {
        address previousOwner = _poolData[pool].owner;
        _poolData[pool].owner = newOwner;
        emit TransferedPoolOwnership(pool, previousOwner, newOwner);
    }

    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT
    }

    /**
     * Exit a pool, burn the BPT token and transfer back the tokens.
     * If maxBPTTokenOut is passed as 0, the function will use the total balance available for the BPT token.
     * If maxBPTTokenOut is between 0 and the total of BPT available, that will be the amount used to burn.
     * maxBPTTokenOut must be grader or equal than 0
     */
    function exitPool(address pool, uint256[] calldata minAmountsOut, uint256 maxBPTTokenOut) external onlyPoolOwner(pool) {
        // 1. Get pool data
        bytes32 poolId = LBP(pool).getPoolId();
        (address[] memory poolTokens, , ) = Vault(VAULT).getPoolTokens(poolId);
        require(poolTokens.length == minAmountsOut.length, "invalid input length");
        PoolData memory poolData = _poolData[pool];

        // 2. Specify the exact BPT amount to burn
        uint256 bptToBurn;
        uint256 bptBalance = IERC20(pool).balanceOf(address(this));
        require(maxBPTTokenOut <= bptBalance, "Not enough BPT token amount");
        require(bptBalance > 0, "invalid pool");
        if (maxBPTTokenOut == 0 ) {
            bptToBurn = bptBalance;
        } else {
            bptToBurn = maxBPTTokenOut;
        }

        bytes memory userData = abi.encode(ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT, bptToBurn);
        Vault.ExitPoolRequest memory exitRequest = Vault.ExitPoolRequest(poolTokens, minAmountsOut, userData, false);

        // 3. Exit pool and keep tokens in contract
        Vault(VAULT).exitPool(poolId, address(this), payable(address(this)), exitRequest);
        emit ExitedPool(pool, poolTokens, minAmountsOut, userData);

        // 4. Calculate and transfer fee to recipient
        address fundToken = poolTokens[poolData.isCorrectOrder ? 0 : 1];
        uint256 fundTokenBalance = IERC20(fundToken).balanceOf(address(this));
        if (fundTokenBalance > poolData.fundTokenInputAmount) {
            uint256 feeAmount = ((fundTokenBalance - poolData.fundTokenInputAmount) * _feeBPS) / 10_000;
            TransferHelper.safeTransfer(fundToken, _feeRecipient, feeAmount);
            emit TransferedFee(pool, fundToken, _feeRecipient, feeAmount);
        }

        // 5. Transfer to user
        uint256 firstTokenBalance = IERC20(poolTokens[0]).balanceOf(address(this));
        TransferHelper.safeTransfer(
            poolTokens[0],
            msg.sender,
            firstTokenBalance
        );
        emit TransferedToken(pool, poolTokens[0], msg.sender, firstTokenBalance);

        uint256 secondTokenBalance = IERC20(poolTokens[1]).balanceOf(address(this));
        TransferHelper.safeTransfer(
            poolTokens[1],
            msg.sender,
            secondTokenBalance
        );
        emit TransferedToken(pool, poolTokens[1], msg.sender, secondTokenBalance);
    }

    function changeFeeRecipient(address newRecipient) external onlyOwner {
        address previousFeeReciepient = _feeRecipient;
        _feeRecipient = newRecipient;
        emit ChangedFeeRecipient(previousFeeReciepient, newRecipient);
    }

    function skim(address token, address recipient) external onlyOwner {
        require(!_pools.contains(token), "can't skim LBP token");
        uint256 balance = IERC20(token).balanceOf(address(this));
        TransferHelper.safeTransfer(token, recipient, balance);
        emit Skimmed(token, recipient, balance);
    }
}