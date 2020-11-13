// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// File: @openzeppelin/contracts/math/SafeMath.sol

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: contracts/vaults/ValueVaultMaster.sol

/*
 * Here we have a list of constants. In order to get access to an address
 * managed by ValueVaultMaster, the calling contract should copy and define
 * some of these constants and use them as keys.
 * Keys themselves are immutable. Addresses can be immutable or mutable.
 *
 * Vault addresses are immutable once set, and the list may grow:
 * K_VAULT_WETH = 0;
 * K_VAULT_ETH_USDC_UNI_V2_LP = 1;
 * K_VAULT_ETH_WBTC_UNI_V2_LP = 2;
 *
 * Strategy addresses are mutable:
 * K_STRATEGY_WETH_SODA_POOL = 0;
 * K_STRATEGY_WETH_MULTI_POOL = 1;
 * K_STRATEGY_ETHUSDC_MULTIPOOL = 100;
 * K_STRATEGY_ETHWBTC_MULTIPOOL = 200;
 */

/*
 * ValueVaultMaster manages all the vaults and strategies of our Value Vaults system.
 */
contract ValueVaultMaster {
    address public governance;

    address public bank;
    address public minorPool;
    address public profitSharer;

    address public govToken; // VALUE
    address public yfv; // When harvesting, convert some parts to YFV for govVault
    address public usdc; // we only used USDC to estimate APY

    address public govVault; // YFV -> VALUE, vUSD, vETH and 6.7% profit from Value Vaults
    address public insuranceFund = 0xb7b2Ea8A1198368f950834875047aA7294A2bDAa; // set to Governance Multisig at start
    address public performanceReward = 0x7Be4D5A99c903C437EC77A20CB6d0688cBB73c7f; // set to deploy wallet at start

    uint256 public constant FEE_DENOMINATOR = 10000;
    uint256 public govVaultProfitShareFee = 670; // 6.7% | VIP-1 (https://yfv.finance/vip-vote/vip_1)
    uint256 public gasFee = 50; // 0.5% at start and can be set by governance decision

    uint256 public minStakeTimeToClaimVaultReward = 24 hours;

    mapping(address => bool) public isVault;
    mapping(uint256 => address) public vaultByKey;

    mapping(address => bool) public isStrategy;
    mapping(uint256 => address) public strategyByKey;
    mapping(address => uint256) public strategyQuota;

    constructor(address _govToken, address _yfv, address _usdc) public {
        govToken = _govToken;
        yfv = _yfv;
        usdc = _usdc;
        governance = tx.origin;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    // Immutable once set.
    function setBank(address _bank) external {
        require(msg.sender == governance, "!governance");
        require(bank == address(0));
        bank = _bank;
    }

    // Mutable in case we want to upgrade the pool.
    function setMinorPool(address _minorPool) external {
        require(msg.sender == governance, "!governance");
        minorPool = _minorPool;
    }

    // Mutable in case we want to upgrade this module.
    function setProfitSharer(address _profitSharer) external {
        require(msg.sender == governance, "!governance");
        profitSharer = _profitSharer;
    }

    // Mutable, in case governance want to upgrade VALUE to new version
    function setGovToken(address _govToken) external {
        require(msg.sender == governance, "!governance");
        govToken = _govToken;
    }

    // Immutable once added, and you can always add more.
    function addVault(uint256 _key, address _vault) external {
        require(msg.sender == governance, "!governance");
        require(vaultByKey[_key] == address(0), "vault: key is taken");

        isVault[_vault] = true;
        vaultByKey[_key] = _vault;
    }

    // Mutable and removable.
    function addStrategy(uint256 _key, address _strategy) external {
        require(msg.sender == governance, "!governance");
        isStrategy[_strategy] = true;
        strategyByKey[_key] = _strategy;
    }

    // Set 0 to disable quota (no limit)
    function setStrategyQuota(address _strategy, uint256 _quota) external {
        require(msg.sender == governance, "!governance");
        strategyQuota[_strategy] = _quota;
    }

    function removeStrategy(uint256 _key) external {
        require(msg.sender == governance, "!governance");
        isStrategy[strategyByKey[_key]] = false;
        delete strategyByKey[_key];
    }

    function setGovVault(address _govVault) public {
        require(msg.sender == governance, "!governance");
        govVault = _govVault;
    }

    function setInsuranceFund(address _insuranceFund) public {
        require(msg.sender == governance, "!governance");
        insuranceFund = _insuranceFund;
    }

    function setPerformanceReward(address _performanceReward) public{
        require(msg.sender == governance, "!governance");
        performanceReward = _performanceReward;
    }

    function setGovVaultProfitShareFee(uint256 _govVaultProfitShareFee) public {
        require(msg.sender == governance, "!governance");
        govVaultProfitShareFee = _govVaultProfitShareFee;
    }

    function setGasFee(uint256 _gasFee) public {
        require(msg.sender == governance, "!governance");
        gasFee = _gasFee;
    }

    function setMinStakeTimeToClaimVaultReward(uint256 _minStakeTimeToClaimVaultReward) public {
        require(msg.sender == governance, "!governance");
        minStakeTimeToClaimVaultReward = _minStakeTimeToClaimVaultReward;
    }

    /**
     * This function allows governance to take unsupported tokens out of the contract.
     * This is in an effort to make someone whole, should they seriously mess up.
     * There is no guarantee governance will vote to return these.
     * It also allows for removal of airdropped tokens.
     */
    function governanceRecoverUnsupported(IERC20x _token, uint256 amount, address to) external {
        require(msg.sender == governance, "!governance");
        _token.transfer(to, amount);
    }
}

interface IERC20x {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

// File: contracts/vaults/strategies/WETHMultiPoolStrategy.sol

interface IStrategyV2p1 {
    function approve(IERC20 _token) external;

    function approveForSpender(IERC20 _token, address spender) external;

    // Deposit tokens to a farm to yield more tokens.
    function deposit(address _vault, uint256 _amount) external; // IStrategy
    function deposit(uint256 _poolId, uint256 _amount) external; // IStrategyV2

    // Claim farming tokens
    function claim(address _vault) external; // IStrategy
    function claim(uint256 _poolId) external; // IStrategyV2

    // The vault request to harvest the profit
    function harvest(uint256 _bankPoolId) external; // IStrategy
    function harvest(uint256 _bankPoolId, uint256 _poolId) external; // IStrategyV2

    // Withdraw the principal from a farm.
    function withdraw(address _vault, uint256 _amount) external; // IStrategy
    function withdraw(uint256 _poolId, uint256 _amount) external; // IStrategyV2

    // Set 0 to disable quota (no limit)
    function poolQuota(uint256 _poolId) external view returns (uint256);

    // Use when we want to switch between strategies
    function forwardToAnotherStrategy(address _dest, uint256 _amount) external returns (uint256);
    function switchBetweenPoolsByGov(uint256 _sourcePoolId, uint256 _destPoolId, uint256 _amount) external; // IStrategyV2p1

    // Source LP token of this strategy
    function getLpToken() external view returns(address);

    // Target farming token of this strategy.
    function getTargetToken(address _vault) external view returns(address); // IStrategy
    function getTargetToken(uint256 _poolId) external view returns(address); // IStrategyV2

    function balanceOf(address _vault) external view returns (uint256); // IStrategy
    function balanceOf(uint256 _poolId) external view returns (uint256); // IStrategyV2

    function pendingReward(address _vault) external view returns (uint256); // IStrategy
    function pendingReward(uint256 _poolId) external view returns (uint256); // IStrategyV2

    function expectedAPY(address _vault) external view returns (uint256); // IStrategy
    function expectedAPY(uint256 _poolId, uint256 _lpTokenUsdcPrice) external view returns (uint256); // IStrategyV2

    function governanceRescueToken(IERC20 _token) external returns (uint256);
}

interface IOneSplit {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    ) external view returns(
        uint256 returnAmount,
        uint256[] memory distribution
    );
}

interface IUniswapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function rewardRate() external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function getRewardForDuration() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);

    // Mutative
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getReward() external;
    function exit() external;
}

interface ISushiPool {
    function deposit(uint256 _poolId, uint256 _amount) external;
    function withdraw(uint256 _poolId, uint256 _amount) external;
}

interface ISodaPool {
    function deposit(uint256 _poolId, uint256 _amount) external;
    function claim(uint256 _poolId) external;
    function withdraw(uint256 _poolId, uint256 _amount) external;
}

interface IProfitSharer {
    function shareProfit() external returns (uint256);
}

interface IValueVaultBank {
    function make_profit(uint256 _poolId, uint256 _amount) external;
}

// This contract is owned by Timelock.
// What it does is simple: deposit WETH to pools, and wait for ValueVaultBank's command.
// Atm we support 3 pool types: IStakingRewards (golff.finance), ISushiPool (chickenswap.org), ISodaPool (soda.finance)
contract WETHMultiPoolStrategy is IStrategyV2p1 {
    using SafeMath for uint256;

    address public governance; // will be a Timelock contract
    address public operator; // can be EOA for non-fund transferring operation

    uint256 public constant FEE_DENOMINATOR = 10000;

    IOneSplit public onesplit = IOneSplit(0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e);
    IUniswapRouter public unirouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    ValueVaultMaster public valueVaultMaster;
    IERC20 public lpToken; // WETH

    mapping(address => mapping(address => address[])) public uniswapPaths; // [input -> output] => uniswap_path

    struct PoolInfo {
        address vault;
        IERC20 targetToken;
        address targetPool;
        uint256 targetPoolId; // poolId in soda/chicken pool (no use for IStakingRewards pool eg. golff.finance)
        uint256 minHarvestForTakeProfit;
        uint8 poolType; // 0: IStakingRewards, 1: ISushiPool, 2: ISodaPool
        uint256 poolQuota; // set 0 to disable quota (no limit)
        uint256 balance;
    }

    mapping(uint256 => PoolInfo) public poolMap; // poolIndex -> poolInfo
    uint256 public totalBalance;

    bool public aggressiveMode; // will try to stake all lpTokens available (be forwarded from bank or from another strategies)

    uint8[] public poolPreferredIds; // sorted by preference

    // weth = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    // golffToken = "0x7AfB39837Fd244A651e4F0C5660B4037214D4aDF"
    // poolMap[0].targetPool = "0x74BCb8b78996F49F46497be185174B2a89191fD6"
    constructor(ValueVaultMaster _valueVaultMaster,
                IERC20 _lpToken,
                bool _aggressiveMode) public {
        valueVaultMaster = _valueVaultMaster;
        lpToken = _lpToken;
        aggressiveMode = _aggressiveMode;
        governance = tx.origin;
        operator = msg.sender;
        // Approve all
        lpToken.approve(valueVaultMaster.bank(), type(uint256).max);
        lpToken.approve(address(unirouter), type(uint256).max);
    }

    // targetToken: golffToken = 0x7AfB39837Fd244A651e4F0C5660B4037214D4aDF
    // targetPool: poolMap[0].targetPool = 0x74BCb8b78996F49F46497be185174B2a89191fD6
    function setPoolInfo(uint256 _poolId, address _vault, IERC20 _targetToken, address _targetPool, uint256 _targetPoolId, uint256 _minHarvestForTakeProfit, uint8 _poolType, uint256 _poolQuota) external {
        require(msg.sender == governance || msg.sender == operator, "!governance && !operator");
        poolMap[_poolId].vault = _vault;
        poolMap[_poolId].targetToken = _targetToken;
        poolMap[_poolId].targetPool = _targetPool;
        poolMap[_poolId].targetPoolId = _targetPoolId;
        poolMap[_poolId].minHarvestForTakeProfit = _minHarvestForTakeProfit;
        poolMap[_poolId].poolType = _poolType;
        poolMap[_poolId].poolQuota = _poolQuota;
        _targetToken.approve(address(unirouter), type(uint256).max);
        lpToken.approve(_vault, type(uint256).max);
        lpToken.approve(address(_targetPool), type(uint256).max);
    }

    function approve(IERC20 _token) external override {
        require(msg.sender == governance || msg.sender == operator, "!governance && !operator");
        _token.approve(valueVaultMaster.bank(), type(uint256).max);
        _token.approve(address(unirouter), type(uint256).max);
    }

    function approveForSpender(IERC20 _token, address spender) external override {
        require(msg.sender == governance || msg.sender == operator, "!governance && !operator");
        _token.approve(spender, type(uint256).max);
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setOperator(address _operator) external {
        require(msg.sender == governance || msg.sender == operator, "!governance && !operator");
        operator = _operator;
    }

    function setPoolPreferredIds(uint8[] memory _poolPreferredIds) public {
        require(msg.sender == governance || msg.sender == operator, "!governance && !operator");
        delete poolPreferredIds;
        for (uint8 i = 0; i < _poolPreferredIds.length; ++i) {
            poolPreferredIds.push(_poolPreferredIds[i]);
        }
    }

    function setMinHarvestForTakeProfit(uint256 _poolId, uint256 _minHarvestForTakeProfit) external {
        require(msg.sender == governance || msg.sender == operator, "!governance && !operator");
        poolMap[_poolId].minHarvestForTakeProfit = _minHarvestForTakeProfit;
    }

    function setPoolQuota(uint256 _poolId, uint256 _poolQuota) external {
        require(msg.sender == governance || msg.sender == operator, "!governance && !operator");
        poolMap[_poolId].poolQuota = _poolQuota;
    }

    // Sometime the balance could be slightly changed (due to the pool, or because we call xxxByGov methods)
    function setPoolBalance(uint256 _poolId, uint256 _balance) external {
        require(msg.sender == governance || msg.sender == operator, "!governance && !operator");
        poolMap[_poolId].balance = _balance;
    }

    function setTotalBalance(uint256 _totalBalance) external {
        require(msg.sender == governance || msg.sender == operator, "!governance && !operator");
        totalBalance = _totalBalance;
    }

    function setAggressiveMode(bool _aggressiveMode) external {
        require(msg.sender == governance || msg.sender == operator, "!governance && !operator");
        aggressiveMode = _aggressiveMode;
    }

    function setOnesplit(IOneSplit _onesplit) external {
        require(msg.sender == governance || msg.sender == operator, "!governance && !operator");
        onesplit = _onesplit;
    }

    function setUnirouter(IUniswapRouter _unirouter) external {
        require(msg.sender == governance || msg.sender == operator, "!governance && !operator");
        unirouter = _unirouter;
    }

    /**
     * @dev See {IStrategy-deposit}.
     */
    function deposit(address _vault, uint256 _amount) public override {
        require(valueVaultMaster.isVault(msg.sender), "sender not vault");
        require(poolPreferredIds.length > 0, "no pool");
        for (uint256 i = 0; i < poolPreferredIds.length; ++i) {
            uint256 _pid = poolPreferredIds[i];
            if (poolMap[_pid].vault == _vault) {
                uint256 _quota = poolMap[_pid].poolQuota;
                if (_quota == 0 || balanceOf(_pid) < _quota) {
                    _deposit(_pid, _amount);
                    return;
                }
            }
        }
        revert("Exceeded pool quota");
    }

    /**
     * @dev See {IStrategyV2-deposit}.
     */
    function deposit(uint256 _poolId, uint256 _amount) public override {
        require(poolMap[_poolId].vault == msg.sender, "sender not vault");
        _deposit(_poolId, _amount);
    }

    function _deposit(uint256 _poolId, uint256 _amount) internal {
        if (aggressiveMode) {
            _amount = lpToken.balanceOf(address(this));
        }
        if (poolMap[_poolId].poolType == 0) {
            IStakingRewards(poolMap[_poolId].targetPool).stake(_amount);
        } else {
            ISushiPool(poolMap[_poolId].targetPool).deposit(poolMap[_poolId].targetPoolId, _amount);
        }
        poolMap[_poolId].balance = poolMap[_poolId].balance.add(_amount);
        totalBalance = totalBalance.add(_amount);
    }

    /**
     * @dev See {IStrategy-claim}.
     */
    function claim(address _vault) external override {
        require(valueVaultMaster.isVault(_vault), "not vault");
        require(poolPreferredIds.length > 0, "no pool");
        for (uint256 i = 0; i < poolPreferredIds.length; ++i) {
            uint256 _pid = poolPreferredIds[i];
            if (poolMap[_pid].vault == _vault) {
                _claim(_pid);
            }
        }
    }

    /**
     * @dev See {IStrategyV2-claim}.
     */
    function claim(uint256 _poolId) external override {
        require(poolMap[_poolId].vault == msg.sender, "sender not vault");
        _claim(_poolId);
    }

    function _claim(uint256 _poolId) internal {
        if (poolMap[_poolId].poolType == 0) {
            IStakingRewards(poolMap[_poolId].targetPool).getReward();
        } else if (poolMap[_poolId].poolType == 1) {
            ISushiPool(poolMap[_poolId].targetPool).deposit(poolMap[_poolId].targetPoolId, 0);
        } else {
            ISodaPool(poolMap[_poolId].targetPool).claim(poolMap[_poolId].targetPoolId);
        }
    }

    /**
     * @dev See {IStrategy-withdraw}.
     */
    function withdraw(address _vault, uint256 _amount) external override {
        require(valueVaultMaster.isVault(msg.sender), "sender not vault");
        require(poolPreferredIds.length > 0, "no pool");
        for (uint256 i = poolPreferredIds.length; i >= 1; --i) {
            uint256 _pid = poolPreferredIds[i - 1];
            if (poolMap[_pid].vault == _vault) {
                uint256 _bal = poolMap[_pid].balance;
                if (_bal > 0) {
                    _withdraw(_pid, (_bal > _amount) ? _amount : _bal);
                    uint256 strategyBal = lpToken.balanceOf(address(this));
                    lpToken.transfer(valueVaultMaster.bank(), strategyBal);
                    if (strategyBal >= _amount) break;
                    if (strategyBal > 0) _amount = _amount - strategyBal;
                }
            }
        }
    }

    /**
     * @dev See {IStrategyV2-withdraw}.
     */
    function withdraw(uint256 _poolId, uint256 _amount) external override {
        require(poolMap[_poolId].vault == msg.sender, "sender not vault");
        if (lpToken.balanceOf(address(this)) >= _amount) return; // has enough balance, no need to withdraw from pool
        _withdraw(_poolId, _amount);
    }

    function _withdraw(uint256 _poolId, uint256 _amount) internal {
        if (poolMap[_poolId].poolType == 0) {
            IStakingRewards(poolMap[_poolId].targetPool).withdraw(_amount);
        } else {
            ISushiPool(poolMap[_poolId].targetPool).withdraw(poolMap[_poolId].targetPoolId, _amount);
        }
        if (poolMap[_poolId].balance < _amount) {
            _amount = poolMap[_poolId].balance;
        }
        poolMap[_poolId].balance = poolMap[_poolId].balance - _amount;
        if (totalBalance >= _amount) totalBalance = totalBalance - _amount;
    }

    function depositByGov(address pool, uint8 _poolType, uint256 _targetPoolId, uint256 _amount) external {
        require(msg.sender == governance, "!governance");
        if (_poolType == 0) {
            IStakingRewards(pool).stake(_amount);
        } else {
            ISushiPool(pool).deposit(_targetPoolId, _amount);
        }
    }

    function claimByGov(address pool, uint8 _poolType, uint256 _targetPoolId) external {
        require(msg.sender == governance, "!governance");
        if (_poolType == 0) {
            IStakingRewards(pool).getReward();
        } else if (_poolType == 1) {
            ISushiPool(pool).deposit(_targetPoolId, 0);
        } else {
            ISodaPool(pool).claim(_targetPoolId);
        }
    }

    function withdrawByGov(address pool, uint8 _poolType, uint256 _targetPoolId, uint256 _amount) external {
        require(msg.sender == governance, "!governance");
        if (_poolType == 0) {
            IStakingRewards(pool).withdraw(_amount);
        } else {
            ISushiPool(pool).withdraw(_targetPoolId, _amount);
        }
    }

    function switchBetweenPoolsByGov(uint256 _sourcePoolId, uint256 _destPoolId, uint256 _amount) external override {
        require(msg.sender == governance, "!governance");
        _withdraw(_sourcePoolId, _amount);
        _deposit(_destPoolId, _amount);
    }

    /**
     * @dev See {IStrategyV2-poolQuota}
     */
    function poolQuota(uint256 _poolId) external override view returns (uint256) {
        return poolMap[_poolId].poolQuota;
    }

    /**
     * @dev See {IStrategyV2-forwardToAnotherStrategy}
     */
    function forwardToAnotherStrategy(address _dest, uint256 _amount) external override returns (uint256 sent) {
        require(valueVaultMaster.isVault(msg.sender) || msg.sender == governance, "!vault && !governance");
        require(valueVaultMaster.isStrategy(_dest), "not strategy");
        require(IStrategyV2p1(_dest).getLpToken() == address(lpToken), "!lpToken");
        uint256 lpTokenBal = lpToken.balanceOf(address(this));
        sent = (_amount < lpTokenBal) ? _amount : lpTokenBal;
        lpToken.transfer(_dest, sent);
    }

    function setUnirouterPath(address _input, address _output, address [] memory _path) public {
        require(msg.sender == governance || msg.sender == operator, "!governance && !operator");
        uniswapPaths[_input][_output] = _path;
    }

    function _swapTokens(address _input, address _output, uint256 _amount) internal {
        address[] memory path = uniswapPaths[_input][_output];
        if (path.length == 0) {
            // path: _input -> _output
            path = new address[](2);
            path[0] = _input;
            path[1] = _output;
        }
        // swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline)
        unirouter.swapExactTokensForTokens(_amount, 1, path, address(this), now.add(1800));
    }

    /**
     * @dev See {IStrategy-harvest}.
     */
    function harvest(uint256 _bankPoolId) external override {
        address _vault = msg.sender;
        require(valueVaultMaster.isVault(_vault), "!vault"); // additional protection so we don't burn the funds
        require(poolPreferredIds.length > 0, "no pool");
        for (uint256 i = 0; i < poolPreferredIds.length; ++i) {
            uint256 _pid = poolPreferredIds[i];
            if (poolMap[_pid].vault == _vault) {
                _harvest(_bankPoolId, _pid);
            }
        }
    }

    /**
     * @dev See {IStrategy-harvest}.
     */
    function harvest(uint256 _bankPoolId, uint256 _poolId) external override {
        require(valueVaultMaster.isVault(msg.sender), "!vault"); // additional protection so we don't burn the funds
        _harvest(_bankPoolId, _poolId);
    }

    uint256 public log_golffBal;
    uint256 public log_wethBal;
    uint256 public log_yfvGovVault;

    function _harvest(uint256 _bankPoolId, uint256 _poolId) internal {
        _claim(_poolId);
        IERC20 targetToken = poolMap[_poolId].targetToken;
        uint256 targetTokenBal = targetToken.balanceOf(address(this));
        log_golffBal = targetTokenBal;

        if (targetTokenBal < poolMap[_poolId].minHarvestForTakeProfit) return;

        _swapTokens(address(targetToken), address(lpToken), targetTokenBal);
        uint256 wethBal = lpToken.balanceOf(address(this));

        log_wethBal = wethBal;

        if (wethBal > 0) {
            address profitSharer = valueVaultMaster.profitSharer();
            address performanceReward = valueVaultMaster.performanceReward();
            address bank = valueVaultMaster.bank();

            if (valueVaultMaster.govVaultProfitShareFee() > 0 && profitSharer != address(0)) {
                address yfv = valueVaultMaster.yfv();
                uint256 _govVaultProfitShareFee = wethBal.mul(valueVaultMaster.govVaultProfitShareFee()).div(FEE_DENOMINATOR);
                _swapTokens(address(lpToken), yfv, _govVaultProfitShareFee);
                log_yfvGovVault = IERC20(yfv).balanceOf(address(this));
                IERC20(yfv).transfer(profitSharer, IERC20(yfv).balanceOf(address(this)));
                IProfitSharer(profitSharer).shareProfit();
            }

            if (valueVaultMaster.gasFee() > 0 && performanceReward != address(0)) {
                uint256 _gasFee = wethBal.mul(valueVaultMaster.gasFee()).div(FEE_DENOMINATOR);
                lpToken.transfer(performanceReward, _gasFee);
            }

            uint256 balanceLeft = lpToken.balanceOf(address(this));
            if (lpToken.allowance(address(this), bank) < balanceLeft) {
                lpToken.approve(bank, 0);
                lpToken.approve(bank, balanceLeft);
            }
            IValueVaultBank(bank).make_profit(_bankPoolId, balanceLeft);
        }
    }

    /**
     * @dev See {IStrategyV2-getLpToken}.
     */
    function getLpToken() external view override returns(address) {
        return address(lpToken);
    }

    /**
     * @dev See {IStrategy-getTargetToken}.
     * Always use pool 0 (default).
     */
    function getTargetToken(address) external override view returns(address) {
        return address(poolMap[0].targetToken);
    }

    /**
     * @dev See {IStrategyV2-getTargetToken}.
     */
    function getTargetToken(uint256 _poolId) external override view returns(address) {
        return address(poolMap[_poolId].targetToken);
    }

    function balanceOf(address _vault) public override view returns (uint256 _balanceOfVault) {
        _balanceOfVault = 0;
        for (uint256 i = 0; i < poolPreferredIds.length; ++i) {
            uint256 _pid = poolPreferredIds[i];
            if (poolMap[_pid].vault == _vault) {
                _balanceOfVault = _balanceOfVault.add(poolMap[_pid].balance);
            }
        }
    }

    function balanceOf(uint256 _poolId) public override view returns (uint256) {
        return poolMap[_poolId].balance;
    }

    function pendingReward(address) public override view returns (uint256) {
        return pendingReward(0);
    }

    // Only support IStakingRewards pool
    function pendingReward(uint256 _poolId) public override view returns (uint256) {
        if (poolMap[_poolId].poolType != 0) return 0; // do not support other pool types
        return IStakingRewards(poolMap[_poolId].targetPool).earned(address(this));
    }

    // always use pool 0 (default)
    function expectedAPY(address) public override view returns (uint256) {
        return expectedAPY(0, 0);
    }

    // Helper function - should never use it on-chain.
    // Only support IStakingRewards pool.
    // Return 10000x of APY. _lpTokenUsdcPrice is not used.
    function expectedAPY(uint256 _poolId, uint256) public override view returns (uint256) {
        if (poolMap[_poolId].poolType != 0) return 0; // do not support other pool types
        IStakingRewards targetPool = IStakingRewards(poolMap[_poolId].targetPool);
        uint256 totalSupply = targetPool.totalSupply();
        if (totalSupply == 0) return 0;
        uint256 investAmt = poolMap[_poolId].balance;
        uint256 oneHourReward = targetPool.rewardRate().mul(3600);
        uint256 returnAmt = oneHourReward.mul(investAmt).div(totalSupply);
        IERC20 usdc = IERC20(valueVaultMaster.usdc());
        (uint256 investInUSDC, ) = onesplit.getExpectedReturn(lpToken, usdc, investAmt, 10, 0);
        (uint256 returnInUSDC, ) = onesplit.getExpectedReturn(poolMap[_poolId].targetToken, usdc, returnAmt, 10, 0);
        return returnInUSDC.mul(8760).mul(FEE_DENOMINATOR).div(investInUSDC); // 100 -> 1%
    }

    event ExecuteTransaction(address indexed target, uint value, string signature, bytes data);

    /**
     * @dev This is from Timelock contract, the governance should be a Timelock contract before calling this
     */
    function executeTransaction(address target, uint value, string memory signature, bytes memory data) public returns (bytes memory) {
        require(msg.sender == governance, "!governance");

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "WETHSodaPoolStrategy::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(target, value, signature, data);

        return returnData;
    }

    /**
     * @dev if there is any token stuck we will need governance support to rescue the fund
     */
    function governanceRescueToken(IERC20 _token) external override returns (uint256 balance) {
        address bank = valueVaultMaster.bank();
        require(bank == msg.sender, "sender not bank");

        balance = _token.balanceOf(address(this));
        _token.transfer(bank, balance);
    }
}