// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
pragma solidity 0.8.1;
import "./interfaces/IInterestRateModel.sol";
import "./interfaces/IBSWrapperToken.sol";
import "./interfaces/IDebtToken.sol";

////////////////////////////////////////////////////////////////////////////////////////////
/// @title DataTypes
/// @author @samparsky
////////////////////////////////////////////////////////////////////////////////////////////

library DataTypes {
    struct BorrowAssetConfig {
        uint256 initialExchangeRateMantissa;
        uint256 reserveFactorMantissa;
        uint256 collateralFactor;
        IBSWrapperToken wrappedBorrowAsset;
        uint256 liquidationFee;
        IDebtToken debtToken;
    }

    function validBorrowAssetConfig(BorrowAssetConfig memory self, address _owner) internal view {
        require(self.initialExchangeRateMantissa > 0, "E");
        require(self.reserveFactorMantissa > 0, "F");
        require(self.collateralFactor > 0, "C");
        require(self.liquidationFee > 0, "L");
        require(address(self.wrappedBorrowAsset) != address(0), "B");
        require(address(self.debtToken) != address(0), "IB");
        require(self.wrappedBorrowAsset.owner() == _owner, "IW");
        require(self.debtToken.owner() == _owner, "IVW");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPriceOracleAggregator.sol";
import "./IBSWrapperToken.sol";
import "./IDebtToken.sol";
import "./IBSVault.sol";
import "../DataTypes.sol";

interface IBSLendingPair {
    event Initialized(
        address indexed pair,
        address indexed asset,
        address indexed collateralAsset,
        address pauseGuardian
    );

    /**
     * Emitted on deposit
     *
     * @param pair The pair being interacted with
     * @param asset The asset deposited in the pair
     * @param tokenReceipeint The user the receives the bsTokens
     * @param user The user that made the deposit
     * @param amount The amount deposited
     **/
    event Deposit(
        address indexed pair,
        address indexed asset,
        address indexed tokenReceipeint,
        address user,
        uint256 amount
    );

    event Borrow(address indexed borrower, uint256 amount);

    /**
     * Emitted on Redeem
     *
     * @param pair The pair being interacted with
     * @param asset The asset withdraw in the pair
     * @param user The user that's making the withdrawal
     * @param to The user the receives the withdrawn tokens
     * @param amount The amount being withdrawn
     **/
    event Redeem(
        address indexed pair,
        address indexed asset,
        address indexed user,
        address to,
        uint256 amount,
        uint256 amountofWrappedBurned
    );

    event WithdrawCollateral(address account, uint256 amount);

    event ReserveWithdraw(address user, uint256 shares);

    /**
     * Emitted on repay
     *
     * @param pair The pair being interacted with
     * @param asset The asset repaid in the pair
     * @param beneficiary The user that's getting their debt reduced
     * @param repayer The user that's providing the funds
     * @param amount The amount being repaid
     **/
    event Repay(
        address indexed pair,
        address indexed asset,
        address indexed beneficiary,
        address repayer,
        uint256 amount
    );

    /**
     * Emitted on liquidation
     *
     * @param pair The pair being interacted with
     * @param asset The asset that getting liquidated
     * @param user The user that's getting liquidated
     * @param liquidatedCollateralAmount The of collateral transferred to the liquidator
     * @param liquidator The liquidator
     **/
    event Liquidate(
        address indexed pair,
        address indexed asset,
        address indexed user,
        uint256 liquidatedCollateralAmount,
        address liquidator
    );

    /**
     * @dev Emitted on flashLoan
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param premium The fee flash borrowed
     **/
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium
    );

    /**
     * @dev Emitted on interest accrued
     * @param accrualBlockNumber block number
     * @param borrowIndex borrow index
     * @param totalBorrows total borrows
     * @param totalReserves total reserves
     **/
    event InterestAccrued(
        address indexed pair,
        uint256 accrualBlockNumber,
        uint256 borrowIndex,
        uint256 totalBorrows,
        uint256 totalReserves
    );

    event InterestShortCircuit(uint256 blockNumber);

    event ActionPaused(uint8 action, uint256 timestamp);
    event ActionUnPaused(uint8 action, uint256 timestamp);

    function initialize(
        string memory _name,
        string memory _symbol,
        IERC20 _asset,
        IERC20 _collateralAsset,
        DataTypes.BorrowAssetConfig calldata borrowConfig,
        IBSWrapperToken _wrappedCollateralAsset,
        IInterestRateModel _interestRate,
        address _pauseGuardian
    ) external;

    function asset() external view returns (IERC20);

    function depositBorrowAsset(address _tokenReceipeint, uint256 _amount) external;

    function depositCollateral(address _tokenReceipeint, uint256 _vaultShareAmount) external;

    function redeem(address _to, uint256 _amount) external;

    function collateralOfAccount(address _account) external view returns (uint256);

    function getMaxWithdrawAllowed(address account) external returns (uint256);

    function oracle() external view returns (IPriceOracleAggregator);

    function collateralAsset() external view returns (IERC20);

    function calcBorrowLimit(uint256 amount) external view returns (uint256);

    function accountInterestIndex(address) external view returns (uint256);

    function borrowIndex() external view returns (uint256);

    function debtToken() external view returns (IDebtToken);

    function borrowBalancePrior(address _account) external view returns (uint256);

    function wrapperBorrowedAsset() external view returns (IBSWrapperToken);

    function wrappedCollateralAsset() external view returns (IBSWrapperToken);

    function totalReserves() external view returns (uint256);

    function withdrawFees(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC3156FlashLender.sol";

interface IBSVault is IERC3156FlashLender {
    // ************** //
    // *** EVENTS *** //
    // ************** //

    /// @notice Emitted on deposit
    /// @param token being deposited
    /// @param from address making the depsoit
    /// @param to address to credit the tokens being deposited
    /// @param amount being deposited
    /// @param shares the represent the amount deposited in the vault
    event Deposit(
        IERC20 indexed token,
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 shares
    );

    /// @notice Emitted on withdraw
    /// @param token being deposited
    /// @param from address making the depsoit
    /// @param to address to credit the tokens being withdrawn
    /// @param amount Amount of underlying being withdrawn
    /// @param shares the represent the amount withdraw from the vault
    event Withdraw(
        IERC20 indexed token,
        address indexed from,
        address indexed to,
        uint256 shares,
        uint256 amount
    );

    event Transfer(IERC20 indexed token, address indexed from, address indexed to, uint256 amount);

    event FlashLoan(
        address indexed borrower,
        IERC20 indexed token,
        uint256 amount,
        uint256 feeAmount,
        address indexed receiver
    );

    event TransferControl(address _newTeam, uint256 timestamp);

    event UpdateFlashLoanRate(uint256 newRate);

    event Approval(address indexed user, address indexed allowed, bool status);

    event OwnershipAccepted(address newOwner, uint256 timestamp);

    event RegisterProtocol(address sender);

    event AllowContract(address whitelist, bool status);

    // ************** //
    // *** FUNCTIONS *** //
    // ************** //

    function initialize(uint256 _flashLoanRate, address _owner) external;

    function approveContract(
        address _user,
        address _contract,
        bool _status,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function deposit(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (uint256);

    function withdraw(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (uint256);

    function balanceOf(IERC20, address) external view returns (uint256);

    function transfer(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _shares
    ) external;

    function toShare(
        IERC20 token,
        uint256 amount,
        bool ceil
    ) external view returns (uint256);

    function toUnderlying(IERC20 token, uint256 share) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IRewardDistributorManager.sol";

interface IBSWrapperTokenBase is IERC20 {
    function initialize(
        address _owner,
        address _underlying,
        string memory _tokenName,
        string memory _tokenSymbol,
        IRewardDistributorManager _manager
    ) external;

    function burn(address _from, uint256 _amount) external;

    function owner() external view returns (address);
}

interface IBSWrapperToken is IBSWrapperTokenBase {
    function mint(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import {IBSWrapperTokenBase} from "./IBSWrapperToken.sol";

interface IDebtToken is IBSWrapperTokenBase {
    event DelegateBorrow(address from, address to, uint256 amount, uint256 timestamp);

    function increaseTotalDebt(uint256 _amount) external;

    function principal(address _account) external view returns (uint256);

    function mint(
        address _to,
        address _owner,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;
import "./IERC3156FlashBorrower.sol";

interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IInterestRateModel {
    /**
     * @notice Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @param reserveFactorMantissa The current reserve factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IOracle {
    /// @notice Price update event
    /// @param asset the asset
    /// @param newPrice price of the asset
    event PriceUpdated(address asset, uint256 newPrice);

    /// @dev returns latest answer
    function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOracle.sol";

interface IPriceOracleAggregator {
    event UpdateOracle(IERC20 token, IOracle oracle);

    function getPriceInUSD(IERC20 _token) external view returns (uint256);

    function getPriceInUSDMultiple(IERC20[] calldata _tokens)
        external
        view
        returns (uint256[] memory);

    function setOracleForAsset(IERC20[] calldata _asset, IOracle[] calldata _oracle) external;

    event OwnershipAccepted(address newOwner, uint256 timestamp);
    event TransferControl(address _newTeam, uint256 timestamp);
    event StableTokenAdded(IERC20 _token, uint256 timestamp);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardDistributor {
    event Initialized(
        IERC20 indexed _rewardToken,
        uint256 _amountDistributePerSecond,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        address _guardian,
        uint256 timestamp
    );

    function accumulateReward(address _tokenAddr, address _user) external;

    function endTimestamp() external returns (uint256);

    function initialize(
        string calldata _name,
        IERC20 _rewardToken,
        uint256 _amountDistributePerSecond,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        address _guardian
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "./IRewardDistributor.sol";

interface IRewardDistributorManager {
    /// @dev Emitted on Initialization
    event Initialized(address owner, uint256 timestamp);

    event ApprovedDistributor(IRewardDistributor distributor, uint256 timestamp);
    event AddReward(address tokenAddr, IRewardDistributor distributor, uint256 timestamp);
    event RemoveReward(address tokenAddr, IRewardDistributor distributor, uint256 timestamp);
    event TransferControl(address _newTeam, uint256 timestamp);
    event OwnershipAccepted(address newOwner, uint256 timestamp);

    function activateReward(address _tokenAddr) external;

    function removeReward(address _tokenAddr, IRewardDistributor _distributor) external;

    function accumulateRewards(address _from, address _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../util/Initializable.sol";
import "../interfaces/IBSLendingPair.sol";
import "../interfaces/IRewardDistributor.sol";
import "../interfaces/IRewardDistributorManager.sol";

abstract contract RewardDistributorStorageV1 is IRewardDistributor, Initializable {
    /// @dev PoolInfo
    struct PoolInfo {
        IERC20 receiptTokenAddr;
        uint256 lastUpdateTimestamp;
        uint256 accRewardTokenPerShare;
        uint128 allocPoint;
    }

    /// @dev UserInfo
    struct UserInfo {
        uint256 lastAccRewardTokenPerShare;
        uint256 pendingReward; // pending user reward to be withdrawn
        uint256 lastUpdateTimestamp; // last time user accumulated rewards
    }

    /// @notice reward distributor name
    string public name;

    /// @dev bool to check if rewarddistributor is activate
    bool public activated;

    /// @notice reward token to be distributed to users
    IERC20 public rewardToken;

    /// @notice poolInfo
    PoolInfo[] public poolInfo;

    /// @notice userInfo
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    /// @notice queue for receipt tokens awaiting activation
    address[] public pendingRewardActivation;

    /// @dev token -> pool id, use the `getTokenPoolID` function
    /// to get a receipt token pool id
    mapping(address => uint256) internal tokenPoolIDPair;

    /// @dev totalAllocPoint
    uint256 public totalAllocPoint;

    /// @notice start timestamp for distribution to begin
    uint256 public startTimestamp;

    /// @notice end timestamp for distribution to end
    uint256 public override endTimestamp;

    /// @notice responsible for updating reward distribution
    address public guardian;

    /// @notice rewardAmountDistributePerSecond scaled in 1e18
    uint256 public rewardAmountDistributePerSecond;
}

contract RewardDistributor is RewardDistributorStorageV1 {
    /// @notice manager
    IRewardDistributorManager public immutable rewardDistributorManager;

    uint256 private constant SHARE_SCALE = 1e12;

    /// @dev grace period for user to claim rewards after endTimestamp
    uint256 private constant CLAIM_REWARD_GRACE_PERIOD = 30 days;

    /// @dev period for users to withdraw rewards after endTimestamp before it can be
    /// reclaimed by the guardian to prevent funds being locked in contract
    uint256 private constant WITHDRAW_REWARD_GRACE_PERIOD = 90 days;

    event Withdraw(
        address indexed distributor,
        address indexed user,
        uint256 indexed poolId,
        address _to,
        uint256 amount
    );

    event AddDistribution(
        address indexed lendingPair,
        address indexed distributor,
        DistributorConfigVars vars,
        uint256 timestamp
    );

    event UpdateDistribution(uint256 indexed pid, uint256 newAllocPoint, uint256 timestamp);

    event AccumulateReward(address indexed receiptToken, uint256 indexed pid, address user);

    event WithdrawUnclaimedReward(address indexed distributor, uint256 amount, uint256 timestamp);

    event ActivateReward(address indexed distributor, uint256 timestamp);

    event UpdateEndTimestamp(address indexed distributor, uint256 newTimestamp, uint256 timestamp);

    modifier onlyGuardian {
        require(msg.sender == guardian, "ONLY_GUARDIAN");
        _;
    }

    /// @notice create a distributor
    /// @param _rewardDistributorManager the reward distributor manager address
    constructor(address _rewardDistributorManager) {
        require(_rewardDistributorManager != address(0), "INVALID_MANAGER");
        rewardDistributorManager = IRewardDistributorManager(_rewardDistributorManager);
    }

    /// @dev accumulates reward for a depositor
    /// @param _tokenAddr token to reward
    /// @param _user user to accumulate reward for
    function accumulateReward(address _tokenAddr, address _user) external override {
        require(_tokenAddr != address(0), "INVALID_ADDR");
        uint256 pid = getTokenPoolID(_tokenAddr);

        updatePoolAndDistributeUserReward(pid, _user);
        emit AccumulateReward(_tokenAddr, pid, _user);
    }

    /// @dev intialize
    /// @param _rewardToken asset to distribute
    /// @param _amountDistributePerSecond amount to distributer per second
    /// @param _startTimestamp time to start distributing
    /// @param _endTimestamp time to end distributing
    /// @param _guardian distributor guardian
    function initialize(
        string calldata _name,
        IERC20 _rewardToken,
        uint256 _amountDistributePerSecond,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        address _guardian
    ) external override initializer {
        require(address(_rewardToken) != address(0), "INVALID_TOKEN");
        require(_guardian != address(0), "INVALID_GUARDIAN");
        require(_amountDistributePerSecond > 0, "INVALID_DISTRIBUTE");
        require(_startTimestamp > 0, "INVALID_TIMESTAMP_1");
        require(_endTimestamp > 0, "INVALID_TIMESTAMP_2");
        require(_endTimestamp > _startTimestamp, "INVALID_TIMESTAMP_3");

        name = _name;
        rewardToken = _rewardToken;
        rewardAmountDistributePerSecond = _amountDistributePerSecond;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        guardian = _guardian;

        emit Initialized(
            _rewardToken,
            _amountDistributePerSecond,
            _startTimestamp,
            _endTimestamp,
            _guardian,
            block.timestamp
        );
    }

    struct DistributorConfigVars {
        uint128 collateralTokenAllocPoint;
        uint128 debtTokenAllocPoint;
        uint128 borrowAssetTokenAllocPoint;
    }

    /// @dev Add a distribution param for a lending pair
    /// @param _allocPoints specifies the allocation points
    /// @param _lendingPair the lending pair being added
    function add(DistributorConfigVars calldata _allocPoints, IBSLendingPair _lendingPair)
        external
        onlyGuardian
    {
        uint256 _startTimestamp = startTimestamp;

        // guardian can not add more once distribution starts
        require(block.timestamp < _startTimestamp, "DISTRIBUTION_STARTED");

        if (_allocPoints.collateralTokenAllocPoint > 0) {
            createPool(
                _allocPoints.collateralTokenAllocPoint,
                _lendingPair.wrappedCollateralAsset(),
                _startTimestamp
            );
        }

        if (_allocPoints.debtTokenAllocPoint > 0) {
            createPool(_allocPoints.debtTokenAllocPoint, _lendingPair.debtToken(), _startTimestamp);
        }

        if (_allocPoints.borrowAssetTokenAllocPoint > 0) {
            createPool(
                _allocPoints.borrowAssetTokenAllocPoint,
                _lendingPair.wrapperBorrowedAsset(),
                _startTimestamp
            );
        }

        emit AddDistribution(address(_lendingPair), address(this), _allocPoints, block.timestamp);
    }

    /// @notice activatePendingRewards Activate pending reward in the manger
    function activatePendingRewards() external {
        for (uint256 i = 0; i < pendingRewardActivation.length; i++) {
            rewardDistributorManager.activateReward(pendingRewardActivation[i]);
        }

        // reset storage
        delete pendingRewardActivation;

        // set activated to true
        if (!activated) activated = true;

        emit ActivateReward(address(this), block.timestamp);
    }

    /// @notice set update allocation point for a pool
    function set(
        uint256 _pid,
        uint128 _allocPoint,
        bool _withUpdate
    ) public onlyGuardian {
        if (_withUpdate) {
            massUpdatePools();
        }

        totalAllocPoint = (totalAllocPoint - poolInfo[_pid].allocPoint) + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;

        emit UpdateDistribution(_pid, _allocPoint, block.timestamp);
    }

    function getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_to > endTimestamp) _to = endTimestamp;
        return _to - _from;
    }

    function pendingRewardToken(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accRewardTokenPerShare = pool.accRewardTokenPerShare;
        uint256 totalSupply = pool.receiptTokenAddr.totalSupply();

        if (block.timestamp > pool.lastUpdateTimestamp && totalSupply != 0) {
            accRewardTokenPerShare = calculatePoolReward(pool, totalSupply);
        }

        uint256 amount = pool.receiptTokenAddr.balanceOf(_user);

        return calculatePendingReward(amount, accRewardTokenPerShare, user);
    }

    /// @dev return accumulated reward share for the pool
    function calculatePoolReward(PoolInfo memory pool, uint256 totalSupply)
        internal
        view
        returns (uint256 accRewardTokenPerShare)
    {
        if (pool.lastUpdateTimestamp >= endTimestamp) {
            return pool.accRewardTokenPerShare;
        }

        uint256 multiplier = getMultiplier(pool.lastUpdateTimestamp, block.timestamp);
        uint256 tokenReward =
            (multiplier * rewardAmountDistributePerSecond * pool.allocPoint) / totalAllocPoint;
        accRewardTokenPerShare =
            pool.accRewardTokenPerShare +
            ((tokenReward * SHARE_SCALE) / totalSupply);
    }

    /// @notice Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /// @notice Update reward variables of the given pool to be up-to-date.
    /// @param _pid pool id
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastUpdateTimestamp) {
            return;
        }
        uint256 totalSupply = pool.receiptTokenAddr.totalSupply();

        if (totalSupply == 0) {
            pool.lastUpdateTimestamp = block.timestamp;
            return;
        }

        pool.accRewardTokenPerShare = calculatePoolReward(pool, totalSupply);
        pool.lastUpdateTimestamp = block.timestamp > endTimestamp ? endTimestamp : block.timestamp;
    }

    /// @dev user to withdraw accumulated rewards from a pool
    /// @param _pid pool id
    /// @param _to address to transfer rewards to
    function withdraw(uint256 _pid, address _to) external {
        require(_to != address(0), "INVALID_TO");

        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePoolAndDistributeUserReward(_pid, msg.sender);

        uint256 amountToWithdraw = user.pendingReward;
        if (amountToWithdraw == 0) return;

        // set pending reward to 0
        user.pendingReward = 0;
        safeTokenTransfer(_to, amountToWithdraw);

        emit Withdraw(address(this), msg.sender, _pid, _to, amountToWithdraw);
    }

    /// @dev update the end timestamp
    /// @param _newEndTimestamp new end timestamp
    function updateEndTimestamp(uint256 _newEndTimestamp) external onlyGuardian {
        require(
            block.timestamp < endTimestamp && _newEndTimestamp > endTimestamp,
            "INVALID_TIMESTAMP"
        );
        endTimestamp = _newEndTimestamp;

        emit UpdateEndTimestamp(address(this), _newEndTimestamp, block.timestamp);
    }

    /// @dev withdraw unclaimed rewards
    /// @param _to address to withdraw to
    function withdrawUnclaimedRewards(address _to) external onlyGuardian {
        require(
            block.timestamp > endTimestamp + WITHDRAW_REWARD_GRACE_PERIOD,
            "REWARD_PERIOD_ACTIVE"
        );
        uint256 amount = rewardToken.balanceOf(address(this));
        rewardToken.transfer(_to, amount);

        emit WithdrawUnclaimedReward(address(this), amount, block.timestamp);
    }

    // Safe token transfer function, just in case if rounding error causes pool to not have enough tokens
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 balance = rewardToken.balanceOf(address(this));
        if (_amount > balance) {
            rewardToken.transfer(_to, balance);
        } else {
            rewardToken.transfer(_to, _amount);
        }
    }

    function getTokenPoolID(address _receiptTokenAddr) public view returns (uint256 poolId) {
        poolId = tokenPoolIDPair[address(_receiptTokenAddr)] - 1;
    }

    function calculatePendingReward(
        uint256 _amount,
        uint256 _accRewardTokenPerShare,
        UserInfo memory _userInfo
    ) internal view returns (uint256 pendingReward) {
        if (
            _userInfo.lastUpdateTimestamp >= endTimestamp ||
            block.timestamp > endTimestamp + CLAIM_REWARD_GRACE_PERIOD ||
            _amount == 0
        ) return 0;

        uint256 rewardDebt = (_amount * _userInfo.lastAccRewardTokenPerShare) / SHARE_SCALE;
        pendingReward = ((_amount * _accRewardTokenPerShare) / SHARE_SCALE) - rewardDebt;
        pendingReward += _userInfo.pendingReward;
    }

    /// @dev update pool and accrue rewards for user
    /// @param _pid pool id
    /// @param _user user to update rewards for
    function updatePoolAndDistributeUserReward(uint256 _pid, address _user) internal {
        if (activated == false || block.timestamp < startTimestamp) return;

        // update the pool
        updatePool(_pid);

        PoolInfo memory pool = poolInfo[_pid];

        if (_user != address(0)) {
            UserInfo storage user = userInfo[_pid][_user];
            uint256 amount = pool.receiptTokenAddr.balanceOf(_user);
            user.pendingReward = calculatePendingReward(amount, pool.accRewardTokenPerShare, user);
            user.lastAccRewardTokenPerShare = pool.accRewardTokenPerShare;
            user.lastUpdateTimestamp = block.timestamp;
        }
    }

    function createPool(
        uint128 _allocPoint,
        IERC20 _receiptTokenAddr,
        uint256 _lastUpdateTimestamp
    ) internal {
        require(address(_receiptTokenAddr) != address(0), "invalid_addr");
        require(tokenPoolIDPair[address(_receiptTokenAddr)] == 0, "token_exists");

        totalAllocPoint = totalAllocPoint + _allocPoint;

        poolInfo.push(
            PoolInfo({
                receiptTokenAddr: _receiptTokenAddr,
                allocPoint: _allocPoint,
                lastUpdateTimestamp: _lastUpdateTimestamp,
                accRewardTokenPerShare: 0
            })
        );

        tokenPoolIDPair[address(_receiptTokenAddr)] = poolInfo.length;
        pendingRewardActivation.push(address(_receiptTokenAddr));
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

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
        require(
            _initializing || _isConstructor() || !_initialized,
            "Initializable: contract is already initialized"
        );

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }
}

