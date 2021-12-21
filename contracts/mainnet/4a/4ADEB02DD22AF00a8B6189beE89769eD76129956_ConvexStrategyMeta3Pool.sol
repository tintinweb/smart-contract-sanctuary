// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {ConvexBaseStrategy} from "./ConvexBaseStrategy.sol";
import {IDepositZap} from "../../interfaces/curve/IDepositZap.sol";
import {IERC20Detailed} from "../../interfaces/IERC20Detailed.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract ConvexStrategyMeta3Pool is ConvexBaseStrategy {
    using SafeERC20Upgradeable for IERC20Detailed;

    /// @notice curve N_COINS for the pool
    uint256 public constant CURVE_UNDERLYINGS_SIZE = 4;
    /// @notice curve 3pool deposit zap
    address public constant CRV_3POOL_DEPOSIT_ZAP =
        address(0xA79828DF1850E8a3A3064576f380D90aECDD3359);

    /// @return size of the curve deposit array
    function _curveUnderlyingsSize() internal pure override returns (uint256) {
        return CURVE_UNDERLYINGS_SIZE;
    }

    /// @notice Deposits in Curve for metapools based on 3pool
    function _depositInCurve(uint256 _minLpTokens) internal override {
        IERC20Detailed _deposit = IERC20Detailed(curveDeposit);
        uint256 _balance = _deposit.balanceOf(address(this));

        address _pool = _curvePool();

        _deposit.safeApprove(CRV_3POOL_DEPOSIT_ZAP, 0);
        _deposit.safeApprove(CRV_3POOL_DEPOSIT_ZAP, _balance);

        // we can accept 0 as minimum, this will be called only by trusted roles
        // we also use the zap to deploy funds into a meta pool
        uint256[4] memory _depositArray;
        _depositArray[depositPosition] = _balance;

        IDepositZap(CRV_3POOL_DEPOSIT_ZAP).add_liquidity(
            _pool,
            _depositArray,
            _minLpTokens
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "../../interfaces/IIdleCDOStrategy.sol";
import "../../interfaces/IERC20Detailed.sol";
import "../../interfaces/convex/IBooster.sol";
import "../../interfaces/convex/IBaseRewardPool.sol";
import "../../interfaces/curve/IMainRegistry.sol";

/// @author @dantop114
/// @title ConvexStrategy
/// @notice IIdleCDOStrategy to deploy funds in Convex Finance
/// @dev This contract should not have any funds at the end of each tx.
/// The contract is upgradable, to add storage slots, add them after the last `###### End of storage VXX`
abstract contract ConvexBaseStrategy is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC20Upgradeable,
    IIdleCDOStrategy
{
    using SafeERC20Upgradeable for IERC20Detailed;

    /// ###### Storage V1
    /// @notice one curve lp token
    /// @dev we use this as base unit of the strategy token too
    uint256 public ONE_CURVE_LP_TOKEN;
    /// @notice convex rewards pool id for the underlying curve lp token
    uint256 public poolID;
    /// @notice curve lp token to deposit in convex
    address public curveLpToken;
    /// @notice deposit token address to deposit into curve pool
    address public curveDeposit;
    /// @notice depositor contract used to deposit underlyings
    address public depositor;
    /// @notice deposit token array position
    uint256 public depositPosition;
    /// @notice convex crv rewards pool address
    address public rewardPool;
    /// @notice decimals of the underlying asset
    uint256 public curveLpDecimals;
    /// @notice Curve main registry
    address public constant MAIN_REGISTRY = address(0x90E00ACe148ca3b23Ac1bC8C240C2a7Dd9c2d7f5);
    /// @notice convex booster address
    address public constant BOOSTER =
        address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    /// @notice weth token address
    address public constant WETH =
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    /// @notice curve ETH mock address
    address public constant ETH = 
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    /// @notice whitelisted CDO for this strategy
    address public whitelistedCDO;

    /// @notice convex rewards for this specific lp token (cvx should be included in this list)
    address[] public convexRewards;
    /// @notice WETH to deposit token path
    address[] public weth2DepositPath;
    /// @notice univ2 router for weth to deposit swap
    address public weth2DepositRouter;
    /// @notice reward liquidation to WETH path
    mapping(address => address[]) public reward2WethPath;
    /// @notice univ2-like router for each reward
    mapping(address => address) public rewardRouter;

    /// @notice total LP tokens staked
    uint256 public totalLpTokensStaked;
    /// @notice total LP tokens locked
    uint256 public totalLpTokensLocked;
    /// @notice harvested LP tokens release delay
    uint256 public releaseBlocksPeriod;
    /// @notice latest harvest
    uint256 public latestHarvestBlock;

    /// ###### End of storage V1

    /// ###### Storage V2
    /// @notice blocks per year
    uint256 public BLOCKS_PER_YEAR;
    /// @notice latest harvest price gain in LP tokens
    uint256 public latestPriceIncrease;
    /// @notice latest estimated harvest interval
    uint256 public latestHarvestInterval;

    // ###################
    // Modifiers
    // ###################

    modifier onlyWhitelistedCDO() {
        require(msg.sender == whitelistedCDO, "Not whitelisted CDO");

        _;
    }

    // Used to prevent initialization of the implementation contract
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        curveLpToken = address(1);
    }

    // ###################
    // Initializer
    // ###################

    // Struct used to set Curve deposits
    struct CurveArgs {
        address deposit;
        address depositor;
        uint256 depositPosition;
    }

    // Struct used to initialize rewards swaps
    struct Reward {
        address reward;
        address router;
        address[] path;
    }

    // Struct used to initialize WETH -> deposit swaps
    struct Weth2Deposit {
        address router;
        address[] path;
    }

    /// @notice can only be called once
    /// @dev Initialize the upgradable contract. If `_deposit` equals WETH address, _weth2Deposit is ignored as param.
    /// @param _poolID convex pool id
    /// @param _owner owner address
    /// @param _curveArgs curve addresses and deposit details
    /// @param _rewards initial rewards (with paths and routers)
    /// @param _weth2Deposit initial WETH -> deposit paths and routers
    function initialize(
        uint256 _poolID,
        address _owner,
        uint256 _releasePeriod,
        CurveArgs memory _curveArgs,
        Reward[] memory _rewards,
        Weth2Deposit memory _weth2Deposit
    ) public initializer {
        // Sanity checks
        require(curveLpToken == address(0), "Initialized");
        require(_curveArgs.depositPosition < _curveUnderlyingsSize(), "Deposit token position invalid");

        // Initialize contracts
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        // Check Curve LP Token and Convex PoolID
        (address _crvLp, , , address _rewardPool, , bool shutdown) = IBooster(BOOSTER).poolInfo(_poolID);
        curveLpToken = _crvLp;

        // Pool and deposit asset checks
        address _deposit = _curveArgs.deposit == WETH ? ETH : _curveArgs.deposit;

        require(!shutdown, "Convex Pool is not active");
        require(_deposit == _curveUnderlyingCoins(_curveArgs.depositPosition), "Deposit token invalid");

        ERC20Upgradeable.__ERC20_init(
            string(abi.encodePacked("Idle ", IERC20Detailed(_crvLp).name(), " Convex Strategy")),
            string(abi.encodePacked("idleCvx", IERC20Detailed(_crvLp).symbol()))
        );

        // Set basic parameters
        poolID = _poolID;
        rewardPool = _rewardPool;
        curveLpDecimals = IERC20Detailed(_crvLp).decimals();
        ONE_CURVE_LP_TOKEN = 10**(curveLpDecimals);
        curveDeposit = _curveArgs.deposit;
        depositor = _curveArgs.depositor;
        depositPosition = _curveArgs.depositPosition;
        releaseBlocksPeriod = _releasePeriod;
        setBlocksPerYear(2465437); // given that blocks are mined at a 13.15s/block rate

        // set approval for curveLpToken
        IERC20Detailed(_crvLp).approve(BOOSTER, type(uint256).max);

        // set initial rewards
        for (uint256 i = 0; i < _rewards.length; i++) {
            addReward(_rewards[i].reward, _rewards[i].router, _rewards[i].path);
        }

        if (_curveArgs.deposit != WETH) setWeth2Deposit(_weth2Deposit.router, _weth2Deposit.path);

        // transfer ownership
        transferOwnership(_owner);
    }

    // ###################
    // Interface implementation
    // ###################

    function strategyToken() external view override returns (address) {
        return address(this);
    }

    function oneToken() external view override returns (uint256) {
        return ONE_CURVE_LP_TOKEN;
    }

    // @notice Underlying token
    function token() external view override returns (address) {
        return curveLpToken;
    }

    // @notice Underlying token decimals
    function tokenDecimals() external view override returns (uint256) {
        return curveLpDecimals;
    }

    function decimals() public view override returns (uint8) {
        return uint8(curveLpDecimals); // should be safe
    }

    // ###################
    // Public methods
    // ###################

    /// @dev msg.sender should approve this contract first to spend `_amount` of `token`
    /// @param _amount amount of `token` to deposit
    /// @return minted amount of strategy tokens minted
    function deposit(uint256 _amount)
        external
        override
        onlyWhitelistedCDO
        returns (uint256 minted)
    {
        if (_amount > 0) {
            /// get `tokens` from msg.sender
            IERC20Detailed(curveLpToken).safeTransferFrom(msg.sender, address(this), _amount);
            minted = _depositAndMint(msg.sender, _amount, price());
        }
    }

    /// @dev msg.sender doesn't need to approve the spending of strategy token
    /// @param _amount amount of strategyTokens to redeem
    /// @return redeemed amount of underlyings redeemed
    function redeem(uint256 _amount) external onlyWhitelistedCDO override returns (uint256 redeemed) {
        if(_amount > 0) {
            redeemed = _redeem(msg.sender, _amount, price());
        }
    }

    /// @dev msg.sender should approve this contract first
    /// to spend `_amount * ONE_IDLE_TOKEN / price()` of `strategyToken`
    /// @param _amount amount of underlying tokens to redeem
    /// @return redeemed amount of underlyings redeemed
    function redeemUnderlying(uint256 _amount)
        external
        override
        onlyWhitelistedCDO
        returns (uint256 redeemed)
    {
        if (_amount > 0) {
            uint256 _cachedPrice = price();
            uint256 _shares = (_amount * ONE_CURVE_LP_TOKEN) / _cachedPrice;
            redeemed = _redeem(msg.sender, _shares, _cachedPrice);
        }
    }

    /// @notice Anyone can call this because this contract holds no strategy tokens and so no 'old' rewards
    /// @dev msg.sender should approve this contract first to spend `_amount` of `strategyToken`.
    /// redeem rewards and transfer them to msg.sender
    /// @param _extraData extra data to be used when selling rewards for min amounts
    /// @return _balances array of minAmounts to use for swapping rewards to WETH, then weth to depositToken, then depositToken to curveLpToken
    function redeemRewards(bytes calldata _extraData)
        external
        override
        onlyWhitelistedCDO
        returns (uint256[] memory _balances)
    {
        address[] memory _convexRewards = convexRewards;
        // +2 for converting rewards to depositToken and then Curve LP Token
        _balances = new uint256[](_convexRewards.length + 2); 
        // decode params from _extraData to get the min amount for each convexRewards
        uint256[] memory _minAmountsWETH = new uint256[](_convexRewards.length);
        uint256 _minDepositToken;
        uint256 _minLpToken;
        (_minAmountsWETH, _minDepositToken, _minLpToken) = abi.decode(_extraData, (uint256[], uint256, uint256));

        IBaseRewardPool(rewardPool).getReward();

        for (uint256 i = 0; i < _convexRewards.length; i++) {
            address _reward = _convexRewards[i];

            // get reward balance and safety check
            IERC20Detailed _rewardToken = IERC20Detailed(_reward);
            uint256 _rewardBalance = _rewardToken.balanceOf(address(this));

            if (_rewardBalance == 0) continue;

            IUniswapV2Router02 _router = IUniswapV2Router02(
                rewardRouter[_reward]
            );

            // approve to v2 router
            _rewardToken.safeApprove(address(_router), 0);
            _rewardToken.safeApprove(address(_router), _rewardBalance);

            // we accept 1 as minimum because this is executed by a trusted CDO
            address[] memory _reward2WethPath = reward2WethPath[_reward];
            uint256[] memory _res = new uint256[](_reward2WethPath.length);
            _res = _router.swapExactTokensForTokens(
                _rewardBalance,
                _minAmountsWETH[i],
                _reward2WethPath,
                address(this),
                block.timestamp
            );
            // save in returned value the amount of weth receive to use off-chain
            _balances[i] = _res[_res.length - 1];
        }

        if (curveDeposit != WETH) {
            IERC20Detailed _weth = IERC20Detailed(WETH);
            IUniswapV2Router02 _wethRouter = IUniswapV2Router02(
                weth2DepositRouter
            );

            uint256 _wethBalance = _weth.balanceOf(address(this));
            _weth.safeApprove(address(_wethRouter), 0);
            _weth.safeApprove(address(_wethRouter), _wethBalance);

            address[] memory _weth2DepositPath = weth2DepositPath;
            uint256[] memory _res = new uint256[](_weth2DepositPath.length);
            _res = _wethRouter.swapExactTokensForTokens(
                _wethBalance,
                _minDepositToken,
                _weth2DepositPath,
                address(this),
                block.timestamp
            );
            // save in _balances the amount of depositToken to use off-chain
            _balances[_convexRewards.length] = _res[_res.length - 1];
        }

        IERC20Detailed _curveLpToken = IERC20Detailed(curveLpToken);
        uint256 _curveLpBalanceBefore = _curveLpToken.balanceOf(address(this));
        _depositInCurve(_minLpToken);
        uint256 _curveLpBalanceAfter = _curveLpToken.balanceOf(address(this));
        uint256 _gainedLpTokens = (_curveLpBalanceAfter - _curveLpBalanceBefore);

        // save in _balances the amount of curveLpTokens received to use off-chain
        _balances[_convexRewards.length + 1] = _gainedLpTokens;
        
        if (_curveLpBalanceAfter > 0) {
            // deposit in curve and stake on convex
            _stakeConvex(_curveLpBalanceAfter);

            // update locked lp tokens and apr computation variables
            latestHarvestInterval = (block.number - latestHarvestBlock);
            latestHarvestBlock = block.number;
            totalLpTokensLocked = _gainedLpTokens;
            
            // inline price increase calculation
            latestPriceIncrease = (_gainedLpTokens * ONE_CURVE_LP_TOKEN) / totalSupply();
        }
    }

    // ###################
    // Views
    // ###################

    /// @return _price net price in underlyings of 1 strategyToken
    function price() public view override returns (uint256 _price) {
        uint256 _totalSupply = totalSupply();

        if (_totalSupply == 0) {
            _price = ONE_CURVE_LP_TOKEN;
        } else {
            _price =
                ((totalLpTokensStaked - _lockedLpTokens()) *
                    ONE_CURVE_LP_TOKEN) /
                totalSupply();
        }
    }

    /// @return returns an APR estimation.
    /// @dev values returned by this method should be taken as an imprecise estimation.
    ///      For client integration something more complex should be done to have a more precise
    ///      estimate (eg. computing APR using historical APR data).
    ///      Also it does not take into account compounding (APY).
    function getApr() external view override returns (uint256) {
        // apr = rate * blocks in a year / harvest interval
        return latestPriceIncrease * (BLOCKS_PER_YEAR / latestHarvestInterval);
    }

    /// @return rewardTokens tokens array of reward token addresses
    function getRewardTokens()
        external
        view
        override
        returns (address[] memory rewardTokens) {}

    // ###################
    // Protected
    // ###################

    /// @notice Allow the CDO to pull stkAAVE rewards. Anyone can call this
    /// @return 0, this function is a noop in this strategy
    function pullStkAAVE() external pure override returns (uint256) {
        return 0;
    }

    /// @notice This contract should not have funds at the end of each tx (except for stkAAVE), this method is just for leftovers
    /// @dev Emergency method
    /// @param _token address of the token to transfer
    /// @param value amount of `_token` to transfer
    /// @param _to receiver address
    function transferToken(
        address _token,
        uint256 value,
        address _to
    ) external onlyOwner nonReentrant {
        IERC20Detailed(_token).safeTransfer(_to, value);
    }

    /// @notice This method can be used to change the value of BLOCKS_PER_YEAR
    /// @param blocksPerYear the new blocks per year value
    function setBlocksPerYear(uint256 blocksPerYear) public onlyOwner {
        require(blocksPerYear != 0, "Blocks per year cannot be zero");
        BLOCKS_PER_YEAR = blocksPerYear;
    }

    function setRouterForReward(address _reward, address _newRouter)
        external
        onlyOwner
    {
        require(_newRouter != address(0), "Router is address zero");
        rewardRouter[_reward] = _newRouter;
    }

    function setPathForReward(address _reward, address[] memory _newPath)
        external
        onlyOwner
    {
        _validPath(_newPath, WETH);
        reward2WethPath[_reward] = _newPath;
    }

    function setWeth2Deposit(address _router, address[] memory _path)
        public
        onlyOwner
    {
        address _curveDeposit = curveDeposit;

        require(_curveDeposit != WETH, "Deposit asset is WETH");

        _validPath(_path, _curveDeposit);
        weth2DepositRouter = _router;
        weth2DepositPath = _path;
    }

    function addReward(
        address _reward,
        address _router,
        address[] memory _path
    ) public onlyOwner {
        _validPath(_path, WETH);

        convexRewards.push(_reward);
        rewardRouter[_reward] = _router;
        reward2WethPath[_reward] = _path;
    }

    function removeReward(address _reward) external onlyOwner {
        address[] memory _newConvexRewards = new address[](
            convexRewards.length - 1
        );

        uint256 currentI = 0;
        for (uint256 i = 0; i < convexRewards.length; i++) {
            if (convexRewards[i] == _reward) continue;
            _newConvexRewards[currentI] = convexRewards[i];
            currentI += 1;
        }

        convexRewards = _newConvexRewards;

        delete rewardRouter[_reward];
        delete reward2WethPath[_reward];
    }

    /// @notice allow to update whitelisted address
    function setWhitelistedCDO(address _cdo) external onlyOwner {
        require(_cdo != address(0), "IS_0");
        whitelistedCDO = _cdo;
    }

    // ###################
    // Internal
    // ###################

    /// @return number of underlying coins depending on Curve pool
    function _curveUnderlyingsSize() internal virtual returns (uint256);

    /// @notice Virtual method that implements deposit in Curve
    function _depositInCurve(uint256 _minLpTokens) internal virtual;

    /// @return address of pool from LP token
    function _curvePool() internal returns (address) {
        return IMainRegistry(MAIN_REGISTRY).get_pool_from_lp_token(curveLpToken);
    }

    function _curveUnderlyingCoins(uint256 _position) internal returns (address) {
        address[8] memory _coins = IMainRegistry(MAIN_REGISTRY).get_underlying_coins(_curvePool());
        return _coins[_position];
    }

    /// @notice Internal helper function to deposit in convex and update total LP tokens staked
    /// @param _lpTokens number of LP tokens to stake
    function _stakeConvex(uint256 _lpTokens) internal {
        // update total staked lp tokens and deposit in convex
        totalLpTokensStaked += _lpTokens;
        IBooster(BOOSTER).depositAll(poolID, true);
    }

    /// @notice Internal function to deposit in the Convex Booster and mint shares
    /// @dev Used for deposit and during an harvest
    /// @param _lpTokens amount to mint
    /// @param _price we give the price as input to save on gas when calculating price
    function _depositAndMint(
        address _account,
        uint256 _lpTokens,
        uint256 _price
    ) internal returns (uint256 minted) {
        // deposit in convex
        _stakeConvex(_lpTokens);

        // mint strategy tokens to msg.sender
        minted = (_lpTokens * ONE_CURVE_LP_TOKEN) / _price;
        _mint(_account, minted);
    }

    /// @dev msg.sender does not need to approve this contract to spend `_amount` of `strategyToken`
    /// @param _shares amount of strategyTokens to redeem
    /// @param _price we give the price as input to save on gas when calculating price
    /// @return redeemed amount of underlyings redeemed
    function _redeem(
        address _account,
        uint256 _shares,
        uint256 _price
    ) internal returns (uint256 redeemed) {
        // update total staked lp tokens
        redeemed = (_shares * _price) / ONE_CURVE_LP_TOKEN;
        totalLpTokensStaked -= redeemed;

        IERC20Detailed _curveLpToken = IERC20Detailed(curveLpToken);

        // burn strategy tokens for the msg.sender
        _burn(_account, _shares);

        // exit reward pool (without claiming) and unwrap staking position
        IBaseRewardPool(rewardPool).withdraw(redeemed, false);
        IBooster(BOOSTER).withdraw(poolID, redeemed);

        // transfer underlying lp tokens to msg.sender
        _curveLpToken.safeTransfer(_account, redeemed);
    }

    function _lockedLpTokens() internal view returns (uint256 _locked) {
        uint256 _releaseBlocksPeriod = releaseBlocksPeriod;
        uint256 _blocksSinceLastHarvest = block.number - latestHarvestBlock;
        uint256 _totalLockedLpTokens = totalLpTokensLocked;

        if (_totalLockedLpTokens > 0 && _blocksSinceLastHarvest < _releaseBlocksPeriod) {
            // progressively release harvested rewards
            _locked = _totalLockedLpTokens * (_releaseBlocksPeriod - _blocksSinceLastHarvest) / _releaseBlocksPeriod;
        }
    }

    function _validPath(address[] memory _path, address _out) internal pure {
        require(_path.length >= 2, "Path length less than 2");
        require(_path[_path.length - 1] == _out, "Last asset should be WETH");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface IDepositZap {
    /// @notice Wraps underlying coins and deposit them into _pool.
    /// Returns the amount of LP tokens that were minted in the deposit.
    function add_liquidity(
        address _pool,
        uint256[4] memory _deposit_amounts,
        uint256 _min_mint_amount
    ) external returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20Detailed is IERC20Upgradeable {
  function name() external view returns(string memory);
  function symbol() external view returns(string memory);
  function decimals() external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

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
    using AddressUpgradeable for address;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

interface IIdleCDOStrategy {
  function strategyToken() external view returns(address);
  function token() external view returns(address);
  function tokenDecimals() external view returns(uint256);
  function oneToken() external view returns(uint256);
  function redeemRewards(bytes calldata _extraData) external returns(uint256[] memory);
  function pullStkAAVE() external returns(uint256);
  function price() external view returns(uint256);
  function getRewardTokens() external view returns(address[] memory);
  function deposit(uint256 _amount) external returns(uint256);
  // _amount in `strategyToken`
  function redeem(uint256 _amount) external returns(uint256);
  // _amount in `token`
  function redeemUnderlying(uint256 _amount) external returns(uint256);
  function getApr() external view returns(uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;
interface IBooster {
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external;
    function depositAll(uint256 _pid, bool _stake) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function withdrawAll(uint256 _pid) external;
    function poolInfo(uint256 _pid) external view returns (address lpToken, address, address, address, address, bool);
    function earmarkRewards(uint256 _pid) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface IBaseRewardPool {
    function balanceOf(address account) external view returns(uint256 amount);
    function pid() external view returns (uint256 _pid);
    function stakingToken() external view returns (address _stakingToken);
    function extraRewardsLength() external view returns (uint256 _length);
    function rewardToken() external view returns(address _rewardToken);
    function extraRewards() external view returns(address[] memory _extraRewards);
    function getReward() external;
    function stake(uint256 _amount) external;
    function stakeAll() external;
    function withdraw(uint256 amount, bool claim) external;
    function withdrawAll(bool claim) external;
    function withdrawAndUnwrap(uint256 amount, bool claim) external;
    function withdrawAllAndUnwrap(bool claim) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface IMainRegistry {
    function get_pool_from_lp_token(address lp_token)
        external
        returns (address);

    function get_underlying_coins(address pool)
        external
        returns (address[8] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}