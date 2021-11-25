// SPDX-License-Identifier:MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// libraries
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { DataTypes } from "../../libraries/types/DataTypes.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

// helper contracts
import { Modifiers } from "../../protocol/configuration/Modifiers.sol";

// interfaces
import { ISushiswapMasterChef } from "./interfaces/ISushiswapMasterChef.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IHarvestCodeProvider } from "../interfaces/IHarvestCodeProvider.sol";
import { IAdapter } from "../../interfaces/defiAdapters/IAdapter.sol";
import { IAdapterInvestLimit } from "../../interfaces/defiAdapters/IAdapterInvestLimit.sol";
import { IAdapterHarvestReward } from "../../interfaces/defiAdapters/IAdapterHarvestReward.sol";

/**
 * @title Adapter for Sushiswap protocol
 * @author Opty.fi
 * @dev Abstraction layer to Sushiswap's MasterChef contract
 */

contract SushiswapAdapter is IAdapter, IAdapterInvestLimit, IAdapterHarvestReward, Modifiers {
    using SafeMath for uint256;
    using Address for address;

    /** @notice max deposit value datatypes */
    DataTypes.MaxExposure public maxDepositProtocolMode;

    /** @notice Sushiswap's reward token address */
    address public rewardToken;

    /** @notice Sushiswap router contract address */
    address public constant SUSHISWAP_ROUTER = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    /** @notice Sushiswap WETH-USDC pair contract address */
    address public constant SUSHI_WETH_USDC = address(0x397FF1542f962076d0BFE58eA045FfA2d347ACa0);

    /** @notice Sushiswap MasterChef V1 contract address */
    address public constant MASTERCHEF_V1 = address(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);

    /** @notice max deposit's protocol value in percentage */
    uint256 public maxDepositProtocolPct; // basis points

    /** @notice Maps liquidityPool to max deposit value in percentage */
    mapping(address => uint256) public maxDepositPoolPct; // basis points

    /** @notice Maps liquidityPool to max deposit value in absolute value for a specific token */
    mapping(address => mapping(address => uint256)) public maxDepositAmount;

    /** @notice Maps underlyingToken to the ID of its pool */
    mapping(address => mapping(address => uint256)) public underlyingTokenToMasterChefToPid;

    constructor(address _registry) public Modifiers(_registry) {
        setMaxDepositProtocolPct(uint256(10000)); // 100%
        setMaxDepositProtocolMode(DataTypes.MaxExposure.Pct);
        setUnderlyingTokenToMasterChefToPid(
            SUSHI_WETH_USDC,
            MASTERCHEF_V1, // MasterChef V1 contract address
            uint256(1)
        );
    }

    /**
     * @inheritdoc IAdapterInvestLimit
     */
    function setMaxDepositPoolPct(address _underlyingToken, uint256 _maxDepositPoolPct)
        external
        override
        onlyRiskOperator
    {
        require(_underlyingToken.isContract(), "!isContract");
        maxDepositPoolPct[_underlyingToken] = _maxDepositPoolPct;
        emit LogMaxDepositPoolPct(maxDepositPoolPct[_underlyingToken], msg.sender);
    }

    /**
     * @inheritdoc IAdapterInvestLimit
     */
    function setMaxDepositAmount(
        address _masterChef,
        address _underlyingToken,
        uint256 _maxDepositAmount
    ) external override onlyRiskOperator {
        require(_masterChef.isContract(), "!_masterChef.isContract()");
        require(_underlyingToken.isContract(), "!_underlyingToken.isContract()");
        maxDepositAmount[_masterChef][_underlyingToken] = _maxDepositAmount;
        emit LogMaxDepositAmount(maxDepositAmount[_masterChef][_underlyingToken], msg.sender);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getDepositAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _masterChef
    ) external view override returns (bytes[] memory) {
        uint256 _amount = IERC20(_underlyingToken).balanceOf(_vault);
        return getDepositSomeCodes(_vault, _underlyingToken, _masterChef, _amount);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getWithdrawAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _masterChef
    ) external view override returns (bytes[] memory) {
        uint256 _redeemAmount = getLiquidityPoolTokenBalance(_vault, _underlyingToken, _masterChef);
        return getWithdrawSomeCodes(_vault, _underlyingToken, _masterChef, _redeemAmount);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getUnderlyingTokens(address, address) external view override returns (address[] memory) {
        revert("!empty");
    }

    /**
     * @inheritdoc IAdapter
     */
    function getSomeAmountInToken(
        address,
        address,
        uint256
    ) external view override returns (uint256) {
        revert("!empty");
    }

    /**
     * @inheritdoc IAdapter
     */
    function calculateAmountInLPToken(
        address,
        address,
        uint256
    ) external view override returns (uint256) {
        revert("!empty");
    }

    /**
     * @inheritdoc IAdapter
     */
    function calculateRedeemableLPTokenAmount(
        address payable _vault,
        address _underlyingToken,
        address _masterChef,
        uint256
    ) external view override returns (uint256) {
        uint256 _pid = underlyingTokenToMasterChefToPid[_underlyingToken][_masterChef];
        return ISushiswapMasterChef(_masterChef).userInfo(_pid, _vault).amount;
    }

    /**
     * @inheritdoc IAdapter
     */
    function isRedeemableAmountSufficient(
        address payable _vault,
        address _underlyingToken,
        address _masterChef,
        uint256 _redeemAmount
    ) external view override returns (bool) {
        uint256 _balanceInToken = getAllAmountInToken(_vault, _underlyingToken, _masterChef);
        return _balanceInToken >= _redeemAmount;
    }

    /* solhint-disable no-empty-blocks */

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getClaimRewardTokenCode(address payable, address) external view override returns (bytes[] memory) {}

    /* solhint-enable no-empty-blocks */

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getHarvestAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _masterChef
    ) external view override returns (bytes[] memory) {
        uint256 _rewardTokenAmount = IERC20(getRewardToken(_masterChef)).balanceOf(_vault);
        return getHarvestSomeCodes(_vault, _underlyingToken, _masterChef, _rewardTokenAmount);
    }

    /**
     * @inheritdoc IAdapter
     */
    function canStake(address) external view override returns (bool) {
        return false;
    }

    /**
     * @notice Map underlyingToken to its pool ID
     * @param _underlyingToken pair contract address to be mapped with pool ID
     * @param _pid pool ID to be linked with pair address
     */
    function setUnderlyingTokenToMasterChefToPid(
        address _underlyingToken,
        address _masterChef,
        uint256 _pid
    ) public onlyOperator {
        require(_underlyingToken != address(0) && _masterChef != address(0), "!address(0)");
        require(
            underlyingTokenToMasterChefToPid[_underlyingToken][_masterChef] == uint256(0),
            "underlyingTokenToMasterChefToPid already set"
        );
        underlyingTokenToMasterChefToPid[_underlyingToken][_masterChef] = _pid;
    }

    /**
     * @inheritdoc IAdapterInvestLimit
     */
    function setMaxDepositProtocolMode(DataTypes.MaxExposure _mode) public override onlyRiskOperator {
        maxDepositProtocolMode = _mode;
        emit LogMaxDepositProtocolMode(maxDepositProtocolMode, msg.sender);
    }

    /**
     * @inheritdoc IAdapterInvestLimit
     */
    function setMaxDepositProtocolPct(uint256 _maxDepositProtocolPct) public override onlyRiskOperator {
        maxDepositProtocolPct = _maxDepositProtocolPct;
        emit LogMaxDepositProtocolPct(maxDepositProtocolPct, msg.sender);
    }

    /* solhint-disable no-unused-vars */

    /**
     * @inheritdoc IAdapter
     */
    function getDepositSomeCodes(
        address payable,
        address _underlyingToken,
        address _masterChef,
        uint256 _amount
    ) public view override returns (bytes[] memory _codes) {
        if (_amount > 0) {
            uint256 _pid = underlyingTokenToMasterChefToPid[_underlyingToken][_masterChef];
            uint256 _depositAmount = _getDepositAmount(_masterChef, _underlyingToken, _amount);
            _codes = new bytes[](3);
            _codes[0] = abi.encode(
                _underlyingToken,
                abi.encodeWithSignature("approve(address,uint256)", _masterChef, uint256(0))
            );
            _codes[1] = abi.encode(
                _underlyingToken,
                abi.encodeWithSignature("approve(address,uint256)", _masterChef, _depositAmount)
            );
            _codes[2] = abi.encode(
                _masterChef,
                abi.encodeWithSignature("deposit(uint256,uint256)", _pid, _depositAmount)
            );
        }
    }

    /**
     * @inheritdoc IAdapter
     */
    function getWithdrawSomeCodes(
        address payable,
        address _underlyingToken,
        address _masterChef,
        uint256 _redeemAmount
    ) public view override returns (bytes[] memory _codes) {
        if (_redeemAmount > 0) {
            uint256 _pid = underlyingTokenToMasterChefToPid[_underlyingToken][_masterChef];
            _codes = new bytes[](1);
            _codes[0] = abi.encode(
                _masterChef,
                abi.encodeWithSignature("withdraw(uint256,uint256)", _pid, _redeemAmount)
            );
        }
    }

    /**
     * @inheritdoc IAdapter
     */
    function getPoolValue(address _masterChef, address _underlyingToken) public view override returns (uint256) {
        return IERC20(_underlyingToken).balanceOf(_masterChef);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getLiquidityPoolToken(address _underlyingToken, address) public view override returns (address) {
        return _underlyingToken;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getAllAmountInToken(
        address payable _vault,
        address _underlyingToken,
        address _masterChef
    ) public view override returns (uint256) {
        uint256 _pid = underlyingTokenToMasterChefToPid[_underlyingToken][_masterChef];
        uint256 _balance = ISushiswapMasterChef(_masterChef).userInfo(_pid, _vault).amount;
        uint256 _unclaimedReward = getUnclaimedRewardTokenAmount(_vault, _masterChef, _underlyingToken);
        if (_unclaimedReward > 0) {
            _balance = _balance.add(
                IHarvestCodeProvider(registryContract.getHarvestCodeProvider()).rewardBalanceInUnderlyingTokens(
                    getRewardToken(_masterChef),
                    _underlyingToken,
                    _unclaimedReward
                )
            );
        }
        return _balance;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getLiquidityPoolTokenBalance(
        address payable _vault,
        address _underlyingToken,
        address _masterChef
    ) public view override returns (uint256) {
        uint256 _pid = underlyingTokenToMasterChefToPid[_underlyingToken][_masterChef];
        uint256 _lpTokenBalance = ISushiswapMasterChef(_masterChef).userInfo(_pid, _vault).amount;
        return _lpTokenBalance;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getRewardToken(address _masterChef) public view override returns (address) {
        return ISushiswapMasterChef(_masterChef).sushi();
    }

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getUnclaimedRewardTokenAmount(
        address payable _vault,
        address _masterChef,
        address _underlyingToken
    ) public view override returns (uint256) {
        uint256 _pid = underlyingTokenToMasterChefToPid[_underlyingToken][_masterChef];
        return ISushiswapMasterChef(_masterChef).pendingSushi(_pid, _vault);
    }

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getHarvestSomeCodes(
        address payable _vault,
        address _underlyingToken,
        address _masterChef,
        uint256 _rewardTokenAmount
    ) public view override returns (bytes[] memory) {
        return
            IHarvestCodeProvider(registryContract.getHarvestCodeProvider()).getHarvestCodes(
                _vault,
                getRewardToken(_masterChef),
                _underlyingToken,
                _rewardTokenAmount
            );
    }

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getAddLiquidityCodes(address payable _vault, address _underlyingToken)
        public
        view
        override
        returns (bytes[] memory)
    {
        return
            IHarvestCodeProvider(registryContract.getHarvestCodeProvider()).getAddLiquidityCodes(
                SUSHISWAP_ROUTER,
                _vault,
                _underlyingToken
            );
    }

    function _getDepositAmount(
        address _masterChef,
        address _underlyingToken,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 _limit =
            maxDepositProtocolMode == DataTypes.MaxExposure.Pct
                ? _getMaxDepositAmountByPct(_masterChef, _underlyingToken)
                : maxDepositAmount[_masterChef][_underlyingToken];
        return _amount > _limit ? _limit : _amount;
    }

    function _getMaxDepositAmountByPct(address _masterChef, address _underlyingToken) internal view returns (uint256) {
        uint256 _poolValue = getPoolValue(_masterChef, _underlyingToken);
        uint256 _poolPct = maxDepositPoolPct[_underlyingToken];
        uint256 _limit =
            _poolPct == 0
                ? _poolValue.mul(maxDepositProtocolPct).div(uint256(10000))
                : _poolValue.mul(_poolPct).div(uint256(10000));
        return _limit;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library DataTypes {
    /**
     * @notice Container for User Deposit/withdraw operations
     * @param account User's address
     * @param isDeposit True if it is deposit and false if it withdraw
     * @param value Amount to deposit/withdraw
     */
    struct UserDepositOperation {
        address account;
        uint256 value;
    }

    /**
     * @notice Container for token balance in vault contract in a specific block
     * @param actualVaultValue current balance of the vault contract
     * @param blockMinVaultValue minimum balance recorded for vault contract in the same block
     * @param blockMaxVaultValue maximum balance recorded for vault contract in the same block
     */
    struct BlockVaultValue {
        uint256 actualVaultValue;
        uint256 blockMinVaultValue;
        uint256 blockMaxVaultValue;
    }

    /**
     * @notice Container for Strategy Steps used by Strategy
     * @param pool Liquidity Pool address
     * @param outputToken Output token of the liquidity pool
     * @param isBorrow If borrow is allowed or not for the liquidity pool
     */
    struct StrategyStep {
        address pool;
        address outputToken;
        bool isBorrow;
    }

    /**
     * @notice Container for pool's configuration
     * @param rating Rating of the liquidity pool
     * @param isLiquidityPool If pool is enabled as liquidity pool
     */
    struct LiquidityPool {
        uint8 rating;
        bool isLiquidityPool;
    }

    /**
     * @notice Container for Strategy used by Vault contract
     * @param index Index at which strategy is stored
     * @param strategySteps StrategySteps consisting pool, outputToken and isBorrow
     */
    struct Strategy {
        uint256 index;
        StrategyStep[] strategySteps;
    }

    /**
     * @notice Container for all Tokens
     * @param index Index at which token is stored
     * @param tokens List of token addresses
     */
    struct Token {
        uint256 index;
        address[] tokens;
    }

    /**
     * @notice Container for pool and its rating
     * @param pool Address of liqudity pool
     * @param rate Value to be set as rate for the liquidity pool
     */
    struct PoolRate {
        address pool;
        uint8 rate;
    }

    /**
     * @notice Container for mapping the liquidity pool and adapter
     * @param pool liquidity pool address
     * @param adapter adapter contract address corresponding to pool
     */
    struct PoolAdapter {
        address pool;
        address adapter;
    }

    /**
     * @notice Container for having limit range for the pools
     * @param lowerLimit liquidity pool rate's lower limit
     * @param upperLimit liquidity pool rate's upper limit
     */
    struct PoolRatingsRange {
        uint8 lowerLimit;
        uint8 upperLimit;
    }

    /**
     * @notice Container for having limit range for withdrawal fee
     * @param lowerLimit withdrawal fee's lower limit
     * @param upperLimit withdrawal fee's upper limit
     */
    struct WithdrawalFeeRange {
        uint256 lowerLimit;
        uint256 upperLimit;
    }

    /**
     * @notice Container for containing risk Profile's configuration
     * @param index Index at which risk profile is stored
     * @param canBorrow True if borrow is allowed for the risk profile
     * @param poolRatingsRange Container for having limit range for the pools
     * @param exists if risk profile exists or not
     */
    struct RiskProfile {
        uint256 index;
        bool canBorrow;
        PoolRatingsRange poolRatingsRange;
        bool exists;
        string name;
        string symbol;
    }

    /**
     * @notice Container for holding percentage of reward token to hold and convert
     * @param hold reward token hold percentage in basis point
     * @param convert reward token convert percentage in basis point
     */
    struct VaultRewardStrategy {
        uint256 hold; //  should be in basis eg: 50% means 5000
        uint256 convert; //  should be in basis eg: 50% means 5000
    }

    /** @notice Named Constants for defining max exposure state */
    enum MaxExposure { Number, Pct }

    /** @notice Named Constants for defining default strategy state */
    enum DefaultStrategyState { Zero, CompoundOrAave }

    /**
     * @notice Container for persisting ODEFI contract's state
     * @param index The market's last index
     * @param timestamp The block number the index was last updated at
     */
    struct RewardsState {
        uint224 index;
        uint32 timestamp;
    }

    /**
     * @notice Container for Treasury accounts along with their shares
     * @param treasury treasury account address
     * @param share treasury's share in percentage from the withdrawal fee
     */
    struct TreasuryShare {
        address treasury;
        uint256 share; //  should be in basis eg: 5% means 500
    }

    /**
     * @notice Container for combining Vault contract's configuration
     * @param discontinued If the vault contract is discontinued or not
     * @param unpaused If the vault contract is paused or unpaused
     * @param withdrawalFee withdrawal fee for a particular vault contract
     * @param treasuryShares Treasury accounts along with their shares
     */
    struct VaultConfiguration {
        bool discontinued;
        bool unpaused;
        uint256 withdrawalFee; //  should be in basis eg: 15% means 1500
        TreasuryShare[] treasuryShares;
    }

    /**
     * @notice Container for persisting all strategy related contract's configuration
     * @param investStrategyRegistry investStrategyRegistry contract address
     * @param strategyProvider strategyProvider contract address
     * @param aprOracle aprOracle contract address
     */
    struct StrategyConfiguration {
        address investStrategyRegistry;
        address strategyProvider;
        address aprOracle;
    }

    /**
     * @notice Container for persisting contract addresses required by vault contract
     * @param strategyManager strategyManager contract address
     * @param riskManager riskManager contract address
     * @param optyDistributor optyDistributor contract address
     * @param operator operator contract address
     */
    struct VaultStrategyConfiguration {
        address strategyManager;
        address riskManager;
        address optyDistributor;
        address odefiVaultBooster;
        address operator;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

//  libraries
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { DataTypes } from "../../libraries/types/DataTypes.sol";

//  interfaces
import { IRegistry } from "../../interfaces/opty/IRegistry.sol";
import { IModifiers } from "../../interfaces/opty/IModifiers.sol";

/**
 * @title Modifiers Contract
 * @author Opty.fi
 * @notice Contract used to keep all the modifiers at one place
 * @dev Contract is used throughout the contracts expect registry contract
 */
abstract contract Modifiers is IModifiers {
    /**
     * @notice Registry contract instance address
     */
    IRegistry public registryContract;

    using Address for address;

    constructor(address _registry) internal {
        registryContract = IRegistry(_registry);
    }

    /**
     * @inheritdoc IModifiers
     */
    function setRegistry(address _registry) external override onlyOperator {
        require(_registry.isContract(), "!isContract");
        registryContract = IRegistry(_registry);
    }

    /**
     * @notice Modifier to check if the address is zero address or not
     */
    modifier onlyValidAddress() {
        require(msg.sender != address(0), "caller is zero address");
        _;
    }

    /**
     * @notice Modifier to check caller is governance or not
     */
    modifier onlyGovernance() {
        require(msg.sender == registryContract.getGovernance(), "caller is not having governance");
        _;
    }

    /**
     * @notice Modifier to check caller is financeOperator or not
     */
    modifier onlyFinanceOperator() {
        require(msg.sender == registryContract.getFinanceOperator(), "caller is not the financeOperator");
        _;
    }

    /**
     * @notice Modifier to check caller is riskOperator or not
     */
    modifier onlyRiskOperator() {
        require(msg.sender == registryContract.getRiskOperator(), "caller is not the riskOperator");
        _;
    }

    /**
     * @notice Modifier to check caller is operator or not
     */
    modifier onlyStrategyOperator() {
        require(msg.sender == registryContract.getStrategyOperator(), "caller is not the strategyOperator");
        _;
    }

    /**
     * @notice Modifier to check caller is operator or not
     */
    modifier onlyOperator() {
        require(msg.sender == registryContract.getOperator(), "caller is not the operator");
        _;
    }

    /**
     * @notice Modifier to check caller is optyDistributor or not
     */
    modifier onlyOPTYDistributor() {
        require(msg.sender == registryContract.getOPTYDistributor(), "!optyDistributor");
        _;
    }

    /**
     * @notice Modifier to check if vault is unpaused or discontinued
     * @param _vault Address of vault/stakingVault contract to disconitnue
     */
    modifier ifNotPausedAndDiscontinued(address _vault) {
        _ifNotPausedAndDiscontinued(_vault);
        _;
    }

    /**
     * @notice Modifier to check caller is registry or not
     */
    modifier onlyRegistry() {
        require(msg.sender == address(registryContract), "!Registry Contract");
        _;
    }

    function _ifNotPausedAndDiscontinued(address _vault) internal view {
        DataTypes.VaultConfiguration memory _vaultConfiguration = registryContract.getVaultConfiguration(_vault);
        require(_vaultConfiguration.unpaused && !_vaultConfiguration.discontinued, "paused or discontinued");
    }

    /**
     * @notice Checks if vault contract is paused or unpaused from usage
     * @param _vault Address of vault/stakingVault contract to pause/unpause
     */
    function _isUnpaused(address _vault) internal view {
        DataTypes.VaultConfiguration memory _vaultConfiguration = registryContract.getVaultConfiguration(_vault);
        require(_vaultConfiguration.unpaused, "paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface ISushiswapMasterChef {
    /*
     * @notice Struct that stores each of the user's states for each pair token
     */
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided
        uint256 rewardDebt; // Reward debt
    }

    /*
     * @notice Function that returns the state of the user regarding a specific pair token (e.g., SUSHI-WETH-USDC)
     * @param _pid Pool ID in MasterChef contract
     * @param _user User's address
     */
    function userInfo(uint256 _pid, address _user) external view returns (UserInfo memory);

    /*
     * @notice Function that returns the amount of accrued SUSHI corresponding to a specific pair token
     *        (e.g., SUSHI-WETH-USDC) that hasn't been claimed yet
     * @param _pid Pool ID in MasterChef contract
     * @param _user User address
     */
    function pendingSushi(uint256 _pid, address _user) external view returns (uint256);

    function sushi() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @title Interface for HarvestCodeProvider Contract
 * @author Opty.fi
 * @notice Abstraction layer to DeFi exchanges like Uniswap
 * @dev Interface for facilitating the logic for harvest reward token codes
 */
interface IHarvestCodeProvider {
    /**
     * @dev Get the codes for harvesting the tokens using uniswap router
     * @param _vault Vault contract address
     * @param _rewardToken Reward token address
     * @param _underlyingToken Token address acting as underlying Asset for the vault contract
     * @param _rewardTokenAmount reward token amount to harvest
     * @return _codes List of harvest codes for harvesting reward tokens
     */
    function getHarvestCodes(
        address payable _vault,
        address _rewardToken,
        address _underlyingToken,
        uint256 _rewardTokenAmount
    ) external view returns (bytes[] memory _codes);

    /**
     * @dev Get the codes for adding liquidity using Sushiswap or Uniswap router
     * @param _router Address of Router Contract
     * @param _vault Address of Vault Contract
     * @param _underlyingToken Token address acting as underlying Asset for the vault contract
     * @return _codes List of codes for adding liquidity on Uniswap or Sushiswap
     */
    function getAddLiquidityCodes(
        address _router,
        address payable _vault,
        address _underlyingToken
    ) external view returns (bytes[] memory _codes);

    /**
     * @dev Get the optimal amount for the token while borrow
     * @param _borrowToken Address of token which has to be borrowed
     * @param _underlyingToken Token address acting as underlying Asset for the vault contract
     * @param _borrowTokenAmount amount of token to borrow
     * @return borrow token's optimal amount
     */
    function getOptimalTokenAmount(
        address _borrowToken,
        address _underlyingToken,
        uint256 _borrowTokenAmount
    ) external view returns (uint256);

    /**
     * @dev Get the underlying token amount equivalent to reward token amount
     * @param _rewardToken Reward token address
     * @param _underlyingToken Token address acting as underlying Asset for the vault contract
     * @param _amount reward token balance amount
     * @return equivalent reward token balance in Underlying token value
     */
    function rewardBalanceInUnderlyingTokens(
        address _rewardToken,
        address _underlyingToken,
        uint256 _amount
    ) external view returns (uint256);

    /**
     * @dev Get the no. of tokens equivalent to the amount provided
     * @param _underlyingToken Underlying token address
     * @param _amount amount in weth
     * @return equivalent WETH token balance in Underlying token value
     */
    function getWETHInToken(address _underlyingToken, uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @title Interface for all the DeFi adapters
 * @author Opty.fi
 * @notice Interface with minimal functions to be inhertied in all DeFi adapters
 * @dev Abstraction layer to different DeFi protocols like AaveV1, Compound etc.
 * It is used as a layer for adding any new function which will be used in all DeFi adapters
 * Conventions used:
 *  - lpToken: liquidity pool token
 */
interface IAdapter {
    /**
     * @notice Returns pool value in underlying token (for all adapters except Curve for which the poolValue is
     * in US dollar) for the given liquidity pool and underlyingToken
     * @dev poolValue can be in US dollar for protocols like Curve if explicitly specified, underlyingToken otherwise
     * for protocols like Compound etc.
     * @param _liquidityPool Liquidity pool's contract address
     * @param _underlyingToken Contract address of the liquidity pool's underlying token
     * @return Pool value in underlying token for the given liquidity pool and underlying token
     */
    function getPoolValue(address _liquidityPool, address _underlyingToken) external view returns (uint256);

    /**
     * @dev Get batch of function calls for depositing specified amount of underlying token in given liquidity pool
     * @param _vault Vault contract address
     * @param _underlyingToken  Underlying token's address supported by the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address where to deposit
     * @param _amount Underlying token's amount
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getDepositSomeCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _amount
    ) external view returns (bytes[] memory _codes);

    /**
     * @dev Get batch of function calls for depositing vault's full balance in underlying tokens in given liquidity pool
     * @param _vault Vault contract address
     * @param _underlyingToken  Underlying token's address supported by the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address where to deposit
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getDepositAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) external view returns (bytes[] memory _codes);

    /**
     * @notice Get batch of function calls for redeeming specified amount of lpTokens held in the vault
     * @dev Redeem specified `amount` of `liquidityPoolToken` and send the `underlyingToken` to the caller`
     * @param _vault Vault contract address
     * @param _underlyingToken  Underlying token's address supported by the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address from where to withdraw
     * @param _amount Amount of underlying token to redeem from the given liquidity pool
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getWithdrawSomeCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _amount
    ) external view returns (bytes[] memory _codes);

    /**
     * @notice Get batch of function calls for redeeming full balance of lpTokens held in the vault
     * @dev Redeem full `amount` of `liquidityPoolToken` and send the `underlyingToken` to the caller`
     * @param _vault Vault contract address
     * @param _underlyingToken  Underlying token's address supported by the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address from where to withdraw
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getWithdrawAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) external view returns (bytes[] memory _codes);

    /**
     * @notice Get the lpToken address
     * @param _underlyingToken Underlying token address
     * @param _liquidityPool Liquidity pool's contract address from where to get the lpToken
     * @return Returns the lpToken address
     */
    function getLiquidityPoolToken(address _underlyingToken, address _liquidityPool) external view returns (address);

    /**
     * @notice Get the underlying token addresses given the liquidity pool and/or lpToken
     * @dev there are some defi pools which requires liqudiity pool and lpToken's address to return underlying token
     * @param _liquidityPool Liquidity pool's contract address from where to get the lpToken
     * @param _liquidityPoolToken LpToken's address
     * @return _underlyingTokens Returns the array of underlying token addresses
     */
    function getUnderlyingTokens(address _liquidityPool, address _liquidityPoolToken)
        external
        view
        returns (address[] memory _underlyingTokens);

    /**
     * @dev Returns the market value in underlying for all the lpTokens held in a specified liquidity pool
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token address for which to get the balance
     * @param _liquidityPool Liquidity pool's contract address which holds the given underlying token
     * @return Returns the amount of underlying token balance
     */
    function getAllAmountInToken(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) external view returns (uint256);

    /**
     * @notice Get the balance of vault in lpTokens in the specified liquidity pool
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token address supported by given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address from where to get the balance of lpToken
     * @return Returns the balance of lpToken (lpToken)
     */
    function getLiquidityPoolTokenBalance(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) external view returns (uint256);

    /**
     * @notice Returns the equivalent value of underlying token for given amount of lpToken
     * @param _underlyingToken Underlying token address supported by given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address from where to get the balance of lpToken
     * @param _liquidityPoolTokenAmount LpToken amount for which to get equivalent underlyingToken amount
     * @return Returns the equivalent amount of underlying token for given lpToken amount
     */
    function getSomeAmountInToken(
        address _underlyingToken,
        address _liquidityPool,
        uint256 _liquidityPoolTokenAmount
    ) external view returns (uint256);

    /**
     * @dev Returns the equivalent value of lpToken for given amount of underlying token
     * @param _underlyingToken Underlying token address for the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address from where to redeem the tokens
     * @param _underlyingTokenAmount Amount of underlying token to be calculated w.r.t. lpToken
     * @return Returns the calculated amount of lpToken equivalent to underlyingTokenAmount
     */
    function calculateAmountInLPToken(
        address _underlyingToken,
        address _liquidityPool,
        uint256 _underlyingTokenAmount
    ) external view returns (uint256);

    /**
     * @dev Returns the market value in underlying token of the shares in the specified liquidity pool
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token address for the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address from where to redeem the tokens
     * @param _redeemAmount Amount of token to be redeemed
     * @return _amount Returns the market value in underlying token of the shares in the given liquidity pool
     */
    function calculateRedeemableLPTokenAmount(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _redeemAmount
    ) external view returns (uint256 _amount);

    /**
     * @notice Checks whether the vault has enough lpToken (+ rewards) to redeem for the specified amount of shares
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token address for the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address from where to redeem the tokens
     * @param _redeemAmount Amount of lpToken (+ rewards) enough to redeem
     * @return Returns a boolean true if lpToken (+ rewards) to redeem for given amount is enough else it returns false
     */
    function isRedeemableAmountSufficient(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _redeemAmount
    ) external view returns (bool);

    /**
     * @notice Returns reward token address for the liquidity pool provided
     * @param _liquidityPool Liquidity pool's contract address for which to get the reward token address
     * @return Returns the reward token supported by given liquidity pool
     */
    function getRewardToken(address _liquidityPool) external view returns (address);

    /**
     * @notice Returns whether the protocol can stake lpToken
     * @param _liquidityPool Liquidity pool's contract address for which to check if staking is enabled or not
     * @return Returns a boolean true if lpToken staking is allowed else false if it not enabled
     */
    function canStake(address _liquidityPool) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { DataTypes } from "../../libraries/types/DataTypes.sol";

/**
 * @title Interface for setting deposit invest limit for DeFi adapters except Curve
 * @author Opty.fi
 * @notice Interface of the DeFi protocol adapter for setting invest limit for deposit
 * @dev Abstraction layer to different DeFi protocols like AaveV1, Compound etc except Curve.
 * It is used as an interface layer for setting max invest limit and its type in number or percentage for DeFi adapters
 */
interface IAdapterInvestLimit {
    /**
     * @notice Notify when Max Deposit Protocol mode is set
     * @param maxDepositProtocolMode Mode of maxDeposit set (can be absolute value or percentage)
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogMaxDepositProtocolMode(DataTypes.MaxExposure indexed maxDepositProtocolMode, address indexed caller);

    /**
     * @notice Notify when Max Deposit Protocol percentage is set
     * @param maxDepositProtocolPct Protocol's max deposit percentage (in basis points, For eg: 50% means 5000)
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogMaxDepositProtocolPct(uint256 indexed maxDepositProtocolPct, address indexed caller);

    /**
     * @notice Notify when Max Deposit Pool percentage is set
     * @param maxDepositPoolPct Liquidity pool's max deposit percentage (in basis points, For eg: 50% means 5000)
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogMaxDepositPoolPct(uint256 indexed maxDepositPoolPct, address indexed caller);

    /**
     * @notice Notify when Max Deposit Amount is set
     * @param maxDepositAmount Absolute max deposit amount in underlying set for the given liquidity pool
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogMaxDepositAmount(uint256 indexed maxDepositAmount, address indexed caller);

    /**
     * @notice Sets the absolute max deposit value in underlying for the given liquidity pool
     * @param _liquidityPool liquidity pool address for which to set max deposit value (in absolute value)
     * @param _underlyingToken address of underlying token
     * @param _maxDepositAmount absolute max deposit amount in underlying to be set for given liquidity pool
     */
    function setMaxDepositAmount(
        address _liquidityPool,
        address _underlyingToken,
        uint256 _maxDepositAmount
    ) external;

    /**
     * @notice Sets the percentage of max deposit value for the given liquidity pool
     * @param _liquidityPool liquidity pool address
     * @param _maxDepositPoolPct liquidity pool's max deposit percentage (in basis points, For eg: 50% means 5000)
     */
    function setMaxDepositPoolPct(address _liquidityPool, uint256 _maxDepositPoolPct) external;

    /**
     * @notice Sets the percentage of max deposit protocol value
     * @param _maxDepositProtocolPct protocol's max deposit percentage (in basis points, For eg: 50% means 5000)
     */
    function setMaxDepositProtocolPct(uint256 _maxDepositProtocolPct) external;

    /**
     * @notice Sets the type of investment limit
     *                  1. Percentage of pool value
     *                  2. Amount in underlying token
     * @dev Types (can be number or percentage) supported for the maxDeposit value
     * @param _mode Mode of maxDeposit to be set (can be absolute value or percentage)
     */
    function setMaxDepositProtocolMode(DataTypes.MaxExposure _mode) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @title Interface for Reward tokens and Swapping tokens for the DeFi adapters
 * @author Opty.fi
 * @notice Interface of the DeFi protocol code adapter for reward tokens and swapping tokens functionality
 * @dev Abstraction layer to different DeFi protocols like Compound, Cream etc.
 * It is used as a layer for adding any new function related to reward token feature to be used in DeFi-adapters.
 * It is also used as a middleware for adding functionality of swapping/harvesting of tokens used in DeFi-adapters.
 */
interface IAdapterHarvestReward {
    /**
     * @notice Returns the amount of accrued reward tokens
     * @param _vault Vault contract address
     * @param _liquidityPool Liquidity pool's contract address from where to claim reward tokens
     * @param _underlyingToken Underlying token's contract address for which to claim reward tokens
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getUnclaimedRewardTokenAmount(
        address payable _vault,
        address _liquidityPool,
        address _underlyingToken
    ) external view returns (uint256 _codes);

    /**
     * @notice Get batch of function calls for claiming the reward tokens (eg: COMP etc.)
     * @param _vault Vault contract address
     * @param _liquidityPool Liquidity pool's contract address from where to claim reward tokens
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getClaimRewardTokenCode(address payable _vault, address _liquidityPool)
        external
        view
        returns (bytes[] memory _codes);

    /**
     * @dev Get batch of function calls for swapping specified amount of rewards in vault to underlying tokens
     * via DEX like Uniswap
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token address for the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address where the vault's deposit is generating rewards
     * @param _rewardTokenAmount Amount of reward token to be harvested to underlyingTokens via DEX
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getHarvestSomeCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _rewardTokenAmount
    ) external view returns (bytes[] memory _codes);

    /**
     * @dev Get batch of function calls for adding liquidity in a DEX like Uniswap
     * @param _vault Vault contract address
     * @param _underlyingToken Pair token's contract address where the vault is going to provide liquidity
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getAddLiquidityCodes(address payable _vault, address _underlyingToken)
        external
        view
        returns (bytes[] memory _codes);

    /**
     * @dev Get batch of function calls for swapping full balance of rewards in vault to underlying tokens
     * via DEX like Uniswap
     * @param _vault Vault contract address
     * @param _underlyingToken List of underlying token addresses for the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address where the vault's deposit is generating rewards
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getHarvestAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) external view returns (bytes[] memory _codes);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

//  libraries
import { DataTypes } from "../../libraries/types/DataTypes.sol";

/**
 * @title Interface for Registry Contract
 * @author Opty.fi
 * @notice Interface of the opty.fi's protocol reegistry to store all the mappings, governance
 * operator, minter, strategist and all optyFi's protocol contract addresses
 */
interface IRegistry {
    /**
     * @notice Set the treasury accounts with their fee shares corresponding to vault contract
     * @param _vault Vault contract address
     * @param _treasuryShares Array of treasuries and their fee shares
     * @return Returns a boolean value indicating whether the operation succeeded
     */
    function setTreasuryShares(address _vault, DataTypes.TreasuryShare[] memory _treasuryShares)
        external
        returns (bool);

    /**
     * @notice Set the treasury's address for optyfi's earn protocol
     * @param _treasury Treasury's address
     * @return Returns a boolean value indicating whether the operation succeeded
     */
    function setTreasury(address _treasury) external returns (bool);

    /**
     * @notice Set the investStrategyRegistry contract address
     * @param _investStrategyRegistry InvestStrategyRegistry contract address
     * @return A boolean value indicating whether the operation succeeded
     */
    function setInvestStrategyRegistry(address _investStrategyRegistry) external returns (bool);

    /**
     * @notice Set the APROracle contract address
     * @param _aprOracle Address of APR Pracle contract to be set
     * @return A boolean value indicating whether the operation succeeded
     */
    function setAPROracle(address _aprOracle) external returns (bool);

    /**
     * @notice Set the StrategyProvider contract address
     * @param _strategyProvider Address of StrategyProvider Contract
     * @return A boolean value indicating whether the operation succeeded
     */
    function setStrategyProvider(address _strategyProvider) external returns (bool);

    /**
     * @notice Set the RiskManager's contract address
     * @param _riskManager Address of RiskManager Contract
     * @return A boolean value indicating whether the operation succeeded
     */
    function setRiskManager(address _riskManager) external returns (bool);

    /**
     * @notice Set the HarvestCodeProvider contract address
     * @param _harvestCodeProvider Address of HarvestCodeProvider Contract
     * @return A boolean value indicating whether the operation succeeded
     */
    function setHarvestCodeProvider(address _harvestCodeProvider) external returns (bool);

    /**
     * @notice Set the StrategyManager contract address
     * @param _strategyManager Address of StrategyManager Contract
     * @return A boolean value indicating whether the operation succeeded
     */
    function setStrategyManager(address _strategyManager) external returns (bool);

    /**
     * @notice Set the $OPTY token's contract address
     * @param _opty Address of Opty Contract
     * @return A boolean value indicating whether the operation succeeded
     */
    function setOPTY(address _opty) external returns (bool);

    /**
     * @notice Set the PriceOracle contract address
     * @param _priceOracle Address of PriceOracle Contract
     * @return A boolean value indicating whether the operation succeeded
     */
    function setPriceOracle(address _priceOracle) external returns (bool);

    /**
     * @notice Set the OPTYStakingRateBalancer contract address
     * @param _optyStakingRateBalancer Address of OptyStakingRateBalancer Contract
     * @return A boolean value indicating whether the operation succeeded
     */
    function setOPTYStakingRateBalancer(address _optyStakingRateBalancer) external returns (bool);

    /**
     * @notice Set the ODEFIVaultBooster contract address
     * @dev Can only be called by the current governance
     * @param _odefiVaultBooster address of the ODEFIVaultBooster Contract
     * @return A boolean value indicating whether the operation succeeded
     */
    function setODEFIVaultBooster(address _odefiVaultBooster) external returns (bool);

    /**
     * @dev Sets multiple `_token` from the {tokens} mapping.
     * @notice Approves multiple tokens in one transaction
     * @param _tokens List of tokens to approve
     * @return A boolean value indicating whether the operation succeeded
     */
    function approveToken(address[] memory _tokens) external returns (bool);

    /**
     * @notice Approves the token provided
     * @param _token token to approve
     * @return A boolean value indicating whether the operation succeeded
     */
    function approveToken(address _token) external returns (bool);

    /**
     * @notice Disable multiple tokens in one transaction
     * @param _tokens List of tokens to revoke
     * @return A boolean value indicating whether the operation succeeded
     */
    function revokeToken(address[] memory _tokens) external returns (bool);

    /**
     * @notice Disable the token
     * @param _token token to revoke
     * @return A boolean value indicating whether the operation succeeded
     */
    function revokeToken(address _token) external returns (bool);

    /**
     * @notice Approves multiple liquidity pools in one transaction
     * @param _pools list of liquidity/credit pools to approve
     * @return A boolean value indicating whether the operation succeeded
     */
    function approveLiquidityPool(address[] memory _pools) external returns (bool);

    /**
     * @notice For approving single liquidity pool
     * @param _pool liquidity/credit pool to approve
     * @return A boolean value indicating whether the operation succeeded
     */
    function approveLiquidityPool(address _pool) external returns (bool);

    /**
     * @notice Revokes multiple liquidity pools in one transaction
     * @param _pools list of liquidity/credit pools to revoke
     * @return A boolean value indicating whether the operation succeeded
     */
    function revokeLiquidityPool(address[] memory _pools) external returns (bool);

    /**
     * @notice Revokes the liquidity pool
     * @param _pool liquidity/credit pool to revoke
     * @return A boolean value indicating whether the operation succeeded
     */
    function revokeLiquidityPool(address _pool) external returns (bool);

    /**
     * @notice Sets multiple pool rates and liquidity pools provided
     * @param _poolRates List of pool rates ([_pool, _rate]) to set
     * @return A boolean value indicating whether the operation succeeded
     */
    function rateLiquidityPool(DataTypes.PoolRate[] memory _poolRates) external returns (bool);

    /**
     * @notice Sets the pool rate for the liquidity pool provided
     * @param _pool liquidityPool to map with its rating
     * @param _rate rate for the liquidityPool provided
     * @return A boolean value indicating whether the operation succeeded
     */
    function rateLiquidityPool(address _pool, uint8 _rate) external returns (bool);

    /**
     * @notice Approves multiple credit pools in one transaction
     * @param _pools List of pools for approval to be considered as creditPool
     * @return A boolean value indicating whether the operation succeeded
     */
    function approveCreditPool(address[] memory _pools) external returns (bool);

    /**
     * @notice Approves the credit pool
     * @param _pool credit pool address to be approved
     * @return A boolean value indicating whether the operation succeeded
     */
    function approveCreditPool(address _pool) external returns (bool);

    /**
     * @notice Revokes multiple credit pools in one transaction
     * @param _pools List of pools for revoking from being used as creditPool
     * @return A boolean value indicating whether the operation succeeded
     */
    function revokeCreditPool(address[] memory _pools) external returns (bool);

    /**
     * @notice Revokes the credit pool
     * @param _pool pool for revoking from being used as creditPool
     * @return A boolean value indicating whether the operation succeeded
     */
    function revokeCreditPool(address _pool) external returns (bool);

    /**
     * @notice Sets the multiple pool rates and credit pools provided
     * @param _poolRates List of pool rates ([_pool, _rate]) to set for creditPool
     * @return A boolean value indicating whether the operation succeeded
     */
    function rateCreditPool(DataTypes.PoolRate[] memory _poolRates) external returns (bool);

    /**
     * @notice Sets the pool rate for the credit pool provided
     * @param _pool creditPool to map with its rating
     * @param _rate rate for the creaditPool provided
     * @return A boolean value indicating whether the operation succeeded.
     */
    function rateCreditPool(address _pool, uint8 _rate) external returns (bool);

    /**
     * @notice Maps multiple liquidity pools to their protocol adapters
     * @param _poolAdapters List of [pool, adapter] pairs to set
     * @return A boolean value indicating whether the operation succeeded
     */
    function setLiquidityPoolToAdapter(DataTypes.PoolAdapter[] memory _poolAdapters) external returns (bool);

    /**
     * @notice Maps liquidity pool to its protocol adapter
     * @param _pool liquidityPool to map with its adapter
     * @param _adapter adapter for the liquidityPool provided
     * @return A boolean value indicating whether the operation succeeded
     */
    function setLiquidityPoolToAdapter(address _pool, address _adapter) external returns (bool);

    /**
     * @notice Maps multiple token pairs to their keccak256 hash
     * @param _setOfTokens List of mulitple token addresses to map with their (paired tokens) hashes
     * @return A boolean value indicating whether the operation succeeded
     */
    function setTokensHashToTokens(address[][] memory _setOfTokens) external returns (bool);

    /**
     * @notice Sets token pair to its keccak256 hash
     * @param _tokens List of token addresses to map with their hashes
     * @return A boolean value indicating whether the operation succeeded
     */
    function setTokensHashToTokens(address[] memory _tokens) external returns (bool);

    /**
     * @notice Maps the Vault contract with underlying assets and riskProfile
     * @param _vault Vault contract address
     * @param _riskProfileCode Risk profile mapped to the vault contract
     * @param _underlyingAssets List of token addresses to map with the riskProfile and Vault contract
     * @return A boolean value indicating whether the operation succeeded
     */
    function setUnderlyingAssetHashToRPToVaults(
        address[] memory _underlyingAssets,
        uint256 _riskProfileCode,
        address _vault
    ) external returns (bool);

    /**
     * @notice Set the withdrawal fee's range
     * @param _withdrawalFeeRange the withdrawal fee's range
     * @return _success Returns a boolean value indicating whether the operation succeeded
     */
    function setWithdrawalFeeRange(DataTypes.WithdrawalFeeRange memory _withdrawalFeeRange)
        external
        returns (bool _success);

    /**
     * @notice Set the withdrawal fee for the vault contract
     * @param _vault Vault contract address
     * @param _withdrawalFee Withdrawal fee to be set for vault contract
     * @return _success Returns a boolean value indicating whether the operation succeeded
     */
    function setWithdrawalFee(address _vault, uint256 _withdrawalFee) external returns (bool _success);

    /**
     * @notice Maps mulitple underlying tokens to risk profiles to vault contracts address
     * @param _vaults List of Vault contract address
     * @param _riskProfileCodes List of Risk profile codes mapped to the vault contract
     * @param _underlyingAssets List of paired token addresses to map with the riskProfile and Vault contract
     * @return A boolean value indicating whether the operation succeeded
     */
    function setUnderlyingAssetHashToRPToVaults(
        address[][] memory _underlyingAssets,
        uint256[] memory _riskProfileCodes,
        address[][] memory _vaults
    ) external returns (bool);

    /**
     * @notice Discontinue the Vault contract from use permanently
     * @dev Once Vault contract is disconitnued, then it CAN NOT be re-activated for usage
     * @param _vault Vault address to discontinue
     * @return A boolean value indicating whether operation is succeeded
     */
    function discontinue(address _vault) external returns (bool);

    /**
     * @notice Pause/Unpause tha Vault contract for use temporarily during any emergency
     * @param _vault Vault contract address to pause
     * @param _unpaused A boolean value true to unpause vault contract and false for pause vault contract
     */
    function unpauseVaultContract(address _vault, bool _unpaused) external returns (bool);

    /**
     * @notice Adds the risk profile in Registry contract Storage
     * @param _riskProfileCode code of riskProfile
     * @param _name name of riskProfile
     * @param _symbol symbol of riskProfile
     * @param _canBorrow A boolean value indicating whether the riskProfile allows borrow step
     * @param _poolRatingRange pool rating range ([lowerLimit, upperLimit]) supported by given risk profile
     * @return A boolean value indicating whether the operation succeeded
     */
    function addRiskProfile(
        uint256 _riskProfileCode,
        string memory _name,
        string memory _symbol,
        bool _canBorrow,
        DataTypes.PoolRatingsRange memory _poolRatingRange
    ) external returns (bool);

    /**
     * @notice Adds list of the risk profiles in Registry contract Storage in one transaction
     * @dev All parameters must be in the same order.
     * @param _riskProfileCodes codes of riskProfiles
     * @param _names names of riskProfiles
     * @param _symbols symbols of riskProfiles
     * @param _canBorrow List of boolean values indicating whether the riskProfile allows borrow step
     * @param _poolRatingRanges List of pool rating range supported by given list of risk profiles
     * @return A boolean value indicating whether the operation succeeded
     */
    function addRiskProfile(
        uint256[] memory _riskProfileCodes,
        string[] memory _names,
        string[] memory _symbols,
        bool[] memory _canBorrow,
        DataTypes.PoolRatingsRange[] memory _poolRatingRanges
    ) external returns (bool);

    /**
     * @notice Change the borrow permission for existing risk profile
     * @param _riskProfileCode Risk profile code (Eg: 1,2, and so on where 0 is reserved for 'no strategy')
     * to update with strategy steps
     * @param _canBorrow A boolean value indicating whether the riskProfile allows borrow step
     * @return A boolean value indicating whether the operation succeeded
     */
    function updateRiskProfileBorrow(uint256 _riskProfileCode, bool _canBorrow) external returns (bool);

    /**
     * @notice Update the pool ratings for existing risk profile
     * @param _riskProfileCode Risk profile code (Eg: 1,2, and so on where 0 is reserved for 'no strategy')
     * to update with pool rating range
     * @param _poolRatingRange pool rating range ([lowerLimit, upperLimit]) to update for given risk profile
     * @return A boolean value indicating whether the operation succeeded
     */
    function updateRPPoolRatings(uint256 _riskProfileCode, DataTypes.PoolRatingsRange memory _poolRatingRange)
        external
        returns (bool);

    /**
     * @notice Remove the existing risk profile in Registry contract Storage
     * @param _index Index of risk profile to be removed
     * @return A boolean value indicating whether the operation succeeded
     */
    function removeRiskProfile(uint256 _index) external returns (bool);

    /**
     * @notice Get the list of tokensHash
     * @return Returns the list of tokensHash.
     */
    function getTokenHashes() external view returns (bytes32[] memory);

    /**
     * @notice Get list of token given the tokensHash
     * @return Returns the list of tokens corresponding to tokensHash
     */
    function getTokensHashToTokenList(bytes32 _tokensHash) external view returns (address[] memory);

    /**
     * @notice Get the list of all the riskProfiles
     * @return Returns the list of all riskProfiles stored in Registry Storage
     */
    function getRiskProfileList() external view returns (uint256[] memory);

    /**
     * @notice Retrieve the StrategyManager contract address
     * @return Returns the StrategyManager contract address
     */
    function getStrategyManager() external view returns (address);

    /**
     * @notice Retrieve the StrategyProvider contract address
     * @return Returns the StrategyProvider contract address
     */
    function getStrategyProvider() external view returns (address);

    /**
     * @notice Retrieve the InvestStrategyRegistry contract address
     * @return Returns the InvestStrategyRegistry contract address
     */
    function getInvestStrategyRegistry() external view returns (address);

    /**
     * @notice Retrieve the RiskManager contract address
     * @return Returns the RiskManager contract address
     */
    function getRiskManager() external view returns (address);

    /**
     * @notice Retrieve the OPTYDistributor contract address
     * @return Returns the OPTYDistributor contract address
     */
    function getOPTYDistributor() external view returns (address);

    /**
     * @notice Retrieve the ODEFIVaultBooster contract address
     * @return Returns the ODEFIVaultBooster contract address
     */
    function getODEFIVaultBooster() external view returns (address);

    /**
     * @notice Retrieve the Governance address
     * @return Returns the Governance address
     */
    function getGovernance() external view returns (address);

    /**
     * @notice Retrieve the FinanceOperator address
     * @return Returns the FinanceOperator address
     */
    function getFinanceOperator() external view returns (address);

    /**
     * @notice Retrieve the RiskOperator address
     * @return Returns the RiskOperator address
     */
    function getRiskOperator() external view returns (address);

    /**
     * @notice Retrieve the StrategyOperator address
     * @return Returns the StrategyOperator address
     */
    function getStrategyOperator() external view returns (address);

    /**
     * @notice Retrieve the Operator address
     * @return Returns the Operator address
     */
    function getOperator() external view returns (address);

    /**
     * @notice Retrieve the HarvestCodeProvider contract address
     * @return Returns the HarvestCodeProvider contract address
     */
    function getHarvestCodeProvider() external view returns (address);

    /**
     * @notice Retrieve the AprOracle contract address
     * @return Returns the AprOracle contract address
     */
    function getAprOracle() external view returns (address);

    /**
     * @notice Retrieve the OPTYStakingRateBalancer contract address
     * @return Returns the OPTYStakingRateBalancer contract address
     */
    function getOPTYStakingRateBalancer() external view returns (address);

    /**
     * @notice Get the configuration of vault contract
     * @return _vaultConfiguration Returns the configuration of vault contract
     */
    function getVaultConfiguration(address _vault)
        external
        view
        returns (DataTypes.VaultConfiguration memory _vaultConfiguration);

    /**
     * @notice Get the properties corresponding to riskProfile code provided
     * @return _riskProfile Returns the properties corresponding to riskProfile provided
     */
    function getRiskProfile(uint256) external view returns (DataTypes.RiskProfile memory _riskProfile);

    /**
     * @notice Get the index corresponding to tokensHash provided
     * @param _tokensHash Hash of token address/addresses
     * @return _index Returns the index corresponding to tokensHash provided
     */
    function getTokensHashIndexByHash(bytes32 _tokensHash) external view returns (uint256 _index);

    /**
     * @notice Get the tokensHash available at the index provided
     * @param _index Index at which you want to get the tokensHash
     * @return _tokensHash Returns the tokensHash available at the index provided
     */
    function getTokensHashByIndex(uint256 _index) external view returns (bytes32 _tokensHash);

    /**
     * @notice Get the rating and Is pool a liquidity pool for the _pool provided
     * @param _pool Liquidity Pool (like cDAI etc.) address
     * @return _liquidityPool Returns the rating and Is pool a liquidity pool for the _pool provided
     */
    function getLiquidityPool(address _pool) external view returns (DataTypes.LiquidityPool memory _liquidityPool);

    /**
     * @notice Get the configuration related to Strategy contracts
     * @return _strategyConfiguration Returns the configuration related to Strategy contracts
     */
    function getStrategyConfiguration()
        external
        view
        returns (DataTypes.StrategyConfiguration memory _strategyConfiguration);

    /**
     * @notice Get the contract address required as part of strategy by vault contract
     * @return _vaultStrategyConfiguration Returns the configuration related to Strategy for Vault contracts
     */
    function getVaultStrategyConfiguration()
        external
        view
        returns (DataTypes.VaultStrategyConfiguration memory _vaultStrategyConfiguration);

    /**
     * @notice Get the adapter address mapped to the _pool provided
     * @param _pool Liquidity Pool (like cDAI etc.) address
     * @return _adapter Returns the adapter address mapped to the _pool provided
     */
    function getLiquidityPoolToAdapter(address _pool) external view returns (address _adapter);

    /**
     * @notice Get the treasury accounts with their fee shares corresponding to vault contract
     * @param _vault Vault contract address
     * @return Returns Treasuries along with their fee shares
     */
    function getTreasuryShares(address _vault) external view returns (DataTypes.TreasuryShare[] memory);

    /**
     * @notice Check if the token is approved or not
     * @param _token Token address for which to check if it is approved or not
     * @return _isTokenApproved Returns a boolean for token approved or not
     */
    function isApprovedToken(address _token) external view returns (bool _isTokenApproved);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @title Interface for Modifiers Contract
 * @author Opty.fi
 * @notice Interface used to set the registry contract address
 */
interface IModifiers {
    /**
     * @notice Sets the regsitry contract address
     * @param _registry address of registry contract
     */
    function setRegistry(address _registry) external;
}