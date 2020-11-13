// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

interface IStrategyV2 {
    function approve(IERC20 _token) external;

    function approveForSpender(IERC20 _token, address spender) external;

    // Deposit tokens to a farm to yield more tokens.
    function deposit(uint256 _poolId, uint256 _amount) external;

    // Claim farming tokens
    function claim(uint256 _poolId) external;

    // The vault request to harvest the profit
    function harvest(uint256 _bankPoolId, uint256 _poolId) external;

    // Withdraw the principal from a farm.
    function withdraw(uint256 _poolId, uint256 _amount) external;

    // Set 0 to disable quota (no limit)
    function poolQuota(uint256 _poolId) external view returns (uint256);

    // Use when we want to switch between strategies
    function forwardToAnotherStrategy(address _dest, uint256 _amount) external returns (uint256);

    // Source LP token of this strategy
    function getLpToken() external view returns(address);

    // Target farming token of this strategy by vault
    function getTargetToken(uint256 _poolId) external view returns(address);

    function balanceOf(uint256 _poolId) external view returns (uint256);

    function pendingReward(uint256 _poolId) external view returns (uint256);

    // Helper function, Should never use it on-chain.
    // Return 1e18x of APY. _lpPairUsdcPrice = current lpPair price (1-wei in USDC-wei) multiple by 1e18
    function expectedAPY(uint256 _poolId, uint256 _lpPairUsdcPrice) external view returns (uint256);

    function governanceRescueToken(IERC20 _token) external returns (uint256);
}

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

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

interface IValueLiquidPool {
    function swapExactAmountIn(address, uint, address, uint, uint) external returns (uint, uint);
    function swapExactAmountOut(address, uint, address, uint, uint) external returns (uint, uint);
    function calcInGivenOut(uint, uint, uint, uint, uint, uint) external pure returns (uint);
    function calcOutGivenIn(uint, uint, uint, uint, uint, uint) external pure returns (uint);
    function getDenormalizedWeight(address) external view returns (uint);
    function getBalance(address) external view returns (uint);
    function swapFee() external view returns (uint);
}

interface IStakingRewards {
    function lastTimeRewardApplicable() external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function rewardRate() external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function getRewardForDuration() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);

    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getReward() external;
    function exit() external;
}

interface ISushiPool {
    function deposit(uint256 _poolId, uint256 _amount) external;
    function claim(uint256 _poolId) external;
    function withdraw(uint256 _poolId, uint256 _amount) external;
    function emergencyWithdraw(uint256 _poolId) external;
}

interface IProfitSharer {
    function shareProfit() external returns (uint256);
}

interface IValueVaultBank {
    function make_profit(uint256 _poolId, uint256 _amount) external;
}

// Deposit UNIv2ETHUSDC to a standard StakingRewards pool (eg. UNI Pool - https://app.uniswap.org/#/uni)
// Wait for Vault commands: deposit, withdraw, claim, harvest (can be called by public via Vault)
contract Univ2ETHUSDCMultiPoolStrategy is IStrategyV2 {
    using SafeMath for uint256;

    address public strategist;
    address public governance;

    uint256 public constant FEE_DENOMINATOR = 10000;

    IERC20 public weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IOneSplit public onesplit = IOneSplit(0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e);
    IUniswapRouter public unirouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    ValueVaultMaster public valueVaultMaster;
    IERC20 public lpPair; // ETHUSDC_UNIv2
    IERC20 public lpPairTokenA; // USDC
    IERC20 public lpPairTokenB; // For this contract it will be always be WETH

    mapping(address => mapping(address => address[])) public uniswapPaths; // [input -> output] => uniswap_path
    mapping(address => mapping(address => address)) public liquidPools; // [input -> output] => value_liquid_pool (valueliquid.io)

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

    bool public aggressiveMode; // will try to stake all lpPair tokens available (be forwarded from bank or from another strategies)

    uint8[] public poolPreferredIds; // sorted by preference

    // lpPair: ETHUSDC_UNIv2 = 0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc
    // lpPairTokenA: USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    // lpPairTokenB: WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    constructor(ValueVaultMaster _valueVaultMaster,
                IERC20 _lpPair,
                IERC20 _lpPairTokenA,
                IERC20 _lpPairTokenB,
                bool _aggressiveMode) public {
        valueVaultMaster = _valueVaultMaster;
        lpPair = _lpPair;
        lpPairTokenA = _lpPairTokenA;
        lpPairTokenB = _lpPairTokenB;
        aggressiveMode = _aggressiveMode;
        governance = tx.origin;
        strategist = tx.origin;
        // Approve all
        lpPair.approve(valueVaultMaster.bank(), type(uint256).max);
        lpPairTokenA.approve(address(unirouter), type(uint256).max);
        lpPairTokenB.approve(address(unirouter), type(uint256).max);
    }

    // [0] targetToken: uniToken = 0x1f9840a85d5af5bf1d1762f925bdaddc4201f984
    //     targetPool: ETHUSDCUniPool = 0x7fba4b8dc5e7616e59622806932dbea72537a56b
    // [1] targetToken: draculaToken = 0xb78B3320493a4EFaa1028130C5Ba26f0B6085Ef8
    //     targetPool: MasterVampire[32] = 0xD12d68Fd52b54908547ebC2Cd77Ec6EbbEfd3099
    //     targetPoolId = 32
    function setPoolInfo(uint256 _poolId, address _vault, IERC20 _targetToken, address _targetPool, uint256 _targetPoolId, uint256 _minHarvestForTakeProfit, uint8 _poolType, uint256 _poolQuota) external {
        require(msg.sender == governance, "!governance");
        poolMap[_poolId].vault = _vault;
        poolMap[_poolId].targetToken = _targetToken;
        poolMap[_poolId].targetPool = _targetPool;
        poolMap[_poolId].targetPoolId = _targetPoolId;
        poolMap[_poolId].minHarvestForTakeProfit = _minHarvestForTakeProfit;
        poolMap[_poolId].poolType = _poolType;
        poolMap[_poolId].poolQuota = _poolQuota;
        _targetToken.approve(address(unirouter), type(uint256).max);
        lpPair.approve(_vault, type(uint256).max);
        lpPair.approve(address(_targetPool), type(uint256).max);
    }

    function approve(IERC20 _token) external override {
        require(msg.sender == governance, "!governance");
        _token.approve(valueVaultMaster.bank(), type(uint256).max);
        _token.approve(address(unirouter), type(uint256).max);
    }

    function approveForSpender(IERC20 _token, address spender) external override {
        require(msg.sender == governance, "!governance");
        _token.approve(spender, type(uint256).max);
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == governance || msg.sender == strategist, "!governance && !strategist");
        strategist = _strategist;
    }

    function setPoolPreferredIds(uint8[] memory _poolPreferredIds) public {
        require(msg.sender == governance || msg.sender == strategist, "!governance && !strategist");
        delete poolPreferredIds;
        for (uint8 i = 0; i < _poolPreferredIds.length; ++i) {
            poolPreferredIds.push(_poolPreferredIds[i]);
        }
    }

    function setMinHarvestForTakeProfit(uint256 _poolId, uint256 _minHarvestForTakeProfit) external {
        require(msg.sender == governance || msg.sender == strategist, "!governance && !strategist");
        poolMap[_poolId].minHarvestForTakeProfit = _minHarvestForTakeProfit;
    }

    function setPoolQuota(uint256 _poolId, uint256 _poolQuota) external {
        require(msg.sender == governance || msg.sender == strategist, "!governance && !strategist");
        poolMap[_poolId].poolQuota = _poolQuota;
    }

    // Sometime the balance could be slightly changed (due to the pool, or because we call xxxByGov methods)
    function setPoolBalance(uint256 _poolId, uint256 _balance) external {
        require(msg.sender == governance || msg.sender == strategist, "!governance && !strategist");
        poolMap[_poolId].balance = _balance;
    }

    function setTotalBalance(uint256 _totalBalance) external {
        require(msg.sender == governance || msg.sender == strategist, "!governance && !strategist");
        totalBalance = _totalBalance;
    }

    function setAggressiveMode(bool _aggressiveMode) external {
        require(msg.sender == governance || msg.sender == strategist, "!governance && !strategist");
        aggressiveMode = _aggressiveMode;
    }

    function setWETH(IERC20 _weth) external {
        require(msg.sender == governance || msg.sender == strategist, "!governance && !strategist");
        weth = _weth;
    }

    function setOnesplit(IOneSplit _onesplit) external {
        require(msg.sender == governance || msg.sender == strategist, "!governance && !strategist");
        onesplit = _onesplit;
    }

    function setUnirouter(IUniswapRouter _unirouter) external {
        require(msg.sender == governance || msg.sender == strategist, "!governance && !strategist");
        unirouter = _unirouter;
        lpPairTokenA.approve(address(unirouter), type(uint256).max);
        lpPairTokenB.approve(address(unirouter), type(uint256).max);
    }

    /**
     * @dev See {IStrategyV2-deposit}.
     */
    function deposit(uint256 _poolId, uint256 _amount) public override {
        PoolInfo storage pool = poolMap[_poolId];
        require(pool.vault == msg.sender, "sender not vault");
        if (aggressiveMode) {
            _amount = lpPair.balanceOf(address(this));
        }
        if (pool.poolType == 0) {
            IStakingRewards(pool.targetPool).stake(_amount);
        } else {
            ISushiPool(pool.targetPool).deposit(pool.targetPoolId, _amount);
        }
        pool.balance = pool.balance.add(_amount);
        totalBalance = totalBalance.add(_amount);
    }

    /**
     * @dev See {IStrategyV2-claim}.
     */
    function claim(uint256 _poolId) external override {
        require(poolMap[_poolId].vault == msg.sender, "sender not vault");
        _claim(_poolId);

    }

    function _claim(uint256 _poolId) internal {
        PoolInfo storage pool = poolMap[_poolId];
        if (pool.poolType == 0) {
            IStakingRewards(pool.targetPool).getReward();
        } else if (pool.poolType == 1) {
            ISushiPool(pool.targetPool).deposit(pool.targetPoolId, 0);
        } else {
            ISushiPool(pool.targetPool).claim(pool.targetPoolId);
        }
    }

    /**
     * @dev See {IStrategyV2-withdraw}.
     */
    function withdraw(uint256 _poolId, uint256 _amount) external override {
        PoolInfo storage pool = poolMap[_poolId];
        require(pool.vault == msg.sender, "sender not vault");
        if (pool.poolType == 0) {
            IStakingRewards(pool.targetPool).withdraw(_amount);
        } else {
            ISushiPool(pool.targetPool).withdraw(pool.targetPoolId, _amount);
        }
        if (pool.balance < _amount) {
            _amount = pool.balance;
        }
        pool.balance = pool.balance - _amount;
        if (totalBalance >= _amount) totalBalance = totalBalance - _amount;
    }

    function depositByGov(address pool, uint8 _poolType, uint256 _targetPoolId, uint256 _amount) external {
        require(msg.sender == governance || msg.sender == strategist, "!governance && !strategist");
        if (_poolType == 0) {
            IStakingRewards(pool).stake(_amount);
        } else {
            ISushiPool(pool).deposit(_targetPoolId, _amount);
        }
    }

    function claimByGov(address pool, uint8 _poolType, uint256 _targetPoolId) external {
        require(msg.sender == governance || msg.sender == strategist, "!governance && !strategist");
        if (_poolType == 0) {
            IStakingRewards(pool).getReward();
        } else if (_poolType == 1) {
            ISushiPool(pool).deposit(_targetPoolId, 0);
        } else {
            ISushiPool(pool).claim(_targetPoolId);
        }
    }

    function withdrawByGov(address pool, uint8 _poolType, uint256 _targetPoolId, uint256 _amount) external {
        require(msg.sender == governance || msg.sender == strategist, "!governance && !strategist");
        if (_poolType == 0) {
            IStakingRewards(pool).withdraw(_amount);
        } else {
            ISushiPool(pool).withdraw(_targetPoolId, _amount);
        }
    }

    function emergencyWithdrawByGov(address pool, uint256 _targetPoolId) external {
        require(msg.sender == governance || msg.sender == strategist, "!governance && !strategist");
        ISushiPool(pool).emergencyWithdraw(_targetPoolId);
    }

    /**
     * @dev See {IStrategyV2-poolQuota}.
     */
    function poolQuota(uint256 _poolId) external override view returns (uint256) {
        return poolMap[_poolId].poolQuota;
    }

    function forwardToAnotherStrategy(address _dest, uint256 _amount) external override returns (uint256 sent) {
        require(valueVaultMaster.isVault(msg.sender), "not vault");
        require(valueVaultMaster.isStrategy(_dest), "not strategy");
        require(IStrategyV2(_dest).getLpToken() == address(lpPair), "!lpPair");
        uint256 lpPairBal = lpPair.balanceOf(address(this));
        sent = (_amount < lpPairBal) ? _amount : lpPairBal;
        lpPair.transfer(_dest, sent);
    }

    function setUnirouterPath(address _input, address _output, address [] memory _path) public {
        require(msg.sender == governance || msg.sender == strategist, "!governance && !strategist");
        uniswapPaths[_input][_output] = _path;
    }

    function setLiquidPool(address _input, address _output, address _pool) public {
        require(msg.sender == governance || msg.sender == strategist, "!governance && !strategist");
        liquidPools[_input][_output] = _pool;
        IERC20(_input).approve(_pool, type(uint256).max);
    }

    function _swapTokens(address _input, address _output, uint256 _amount) internal {
        address _pool = liquidPools[_input][_output];
        if (_pool != address(0)) { // use ValueLiquid
            // swapExactAmountIn(tokenIn, tokenAmountIn, tokenOut, minAmountOut, maxPrice)
            IValueLiquidPool(_pool).swapExactAmountIn(_input, _amount, _output, 1, type(uint256).max);
        } else { // use Uniswap
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
    }

    function _addLiquidity() internal {
        // addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline)
        unirouter.addLiquidity(address(lpPairTokenA), address(lpPairTokenB), lpPairTokenA.balanceOf(address(this)), lpPairTokenB.balanceOf(address(this)), 1, 1, address(this), now.add(1800));
    }

    /**
     * @dev See {IStrategyV2-harvest}.
     */
    function harvest(uint256 _bankPoolId, uint256 _poolId) external override {
        address bank = valueVaultMaster.bank();
        address _vault = msg.sender;
        require(valueVaultMaster.isVault(_vault), "!vault"); // additional protection so we don't burn the funds

        PoolInfo storage pool = poolMap[_poolId];
        _claim(_poolId);

        IERC20 targetToken = pool.targetToken;
        uint256 targetTokenBal = targetToken.balanceOf(address(this));

        if (targetTokenBal < pool.minHarvestForTakeProfit) return;

        _swapTokens(address(targetToken), address(weth), targetTokenBal);
        uint256 wethBal = weth.balanceOf(address(this));

        if (wethBal > 0) {
            uint256 _reserved = 0;
            uint256 _gasFee = 0;
            uint256 _govVaultProfitShareFee = 0;

            if (valueVaultMaster.gasFee() > 0) {
                _gasFee = wethBal.mul(valueVaultMaster.gasFee()).div(FEE_DENOMINATOR);
                _reserved = _reserved.add(_gasFee);
            }

            if (valueVaultMaster.govVaultProfitShareFee() > 0) {
                _govVaultProfitShareFee = wethBal.mul(valueVaultMaster.govVaultProfitShareFee()).div(FEE_DENOMINATOR);
                _reserved = _reserved.add(_govVaultProfitShareFee);
            }

            uint256 wethToBuyTokenA = wethBal.sub(_reserved).div(2); // we have TokenB (WETH) already, so use 1/2 bal to buy TokenA (USDC)

            _swapTokens(address(weth), address(lpPairTokenA), wethToBuyTokenA);
            _addLiquidity();

            wethBal = weth.balanceOf(address(this));

            {
                address profitSharer = valueVaultMaster.profitSharer();
                address performanceReward = valueVaultMaster.performanceReward();

                if (_gasFee > 0 && performanceReward != address(0)) {
                    if (_gasFee.add(_govVaultProfitShareFee) < wethBal) {
                        _gasFee = wethBal.sub(_govVaultProfitShareFee);
                    }
                    weth.transfer(performanceReward, _gasFee);
                    wethBal = weth.balanceOf(address(this));
                }

                if (_govVaultProfitShareFee > 0 && profitSharer != address(0)) {
                    address govToken = valueVaultMaster.govToken();
                    _swapTokens(address(weth), govToken, wethBal);
                    IERC20(govToken).transfer(profitSharer, IERC20(govToken).balanceOf(address(this)));
                    IProfitSharer(profitSharer).shareProfit();
                }
            }

            uint256 balanceLeft = lpPair.balanceOf(address(this));
            if (balanceLeft > 0) {
                if (_bankPoolId == type(uint256).max) {
                    // this called by governance of vault, send directly to bank (dont make profit)
                    lpPair.transfer(bank, balanceLeft);
                } else {
                    if (lpPair.allowance(address(this), bank) < balanceLeft) {
                        lpPair.approve(bank, 0);
                        lpPair.approve(bank, balanceLeft);
                    }
                    IValueVaultBank(bank).make_profit(_bankPoolId, balanceLeft);
                }
            }
        }
    }

    /**
     * @dev See {IStrategyV2-getLpToken}.
     */
    function getLpToken() external view override returns(address) {
        return address(lpPair);
    }

    /**
     * @dev See {IStrategyV2-getTargetToken}.
     */
    function getTargetToken(uint256 _poolId) external override view returns(address) {
        return address(poolMap[_poolId].targetToken);
    }

    function balanceOf(uint256 _poolId) public override view returns (uint256) {
        return poolMap[_poolId].balance;
    }

    // Only support IStakingRewards pool
    function pendingReward(uint256 _poolId) public override view returns (uint256) {
        if (poolMap[_poolId].poolType != 0) return 0; // do not support other pool types
        return IStakingRewards(poolMap[_poolId].targetPool).earned(address(this));
    }

    // Helper function, Should never use it on-chain.
    // Return 1e18x of APY. _lpPairUsdcPrice = current lpPair price (1-wei in USDC-wei) multiple by 1e18
    function expectedAPY(uint256, uint256) public override view returns (uint256) {
        return 0; // not implemented
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

    event ExecuteTransaction(address indexed target, uint value, string signature, bytes data);

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
        require(success, "Univ2ETHUSDCMultiPoolStrategy::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(target, value, signature, data);

        return returnData;
    }
}