// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
}

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

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IWETH.sol";
import "./RoleAware.sol";

contract Fund is RoleAware, Ownable {
    address public WETH;
    mapping(address => bool) public activeTokens;

    constructor(address _WETH, address _roles) Ownable() RoleAware(_roles) {
        WETH = _WETH;
    }

    function activateToken(address token) external {
        require(
            isTokenActivator(msg.sender),
            "Address not authorized to activate tokens"
        );
        activeTokens[token] = true;
    }

    function deactivateToken(address token) external {
        require(
            isTokenActivator(msg.sender),
            "Address not authorized to activate tokens"
        );
        activeTokens[token] = false;
    }

    function deposit(address depositToken, uint256 depositAmount)
        external
        returns (bool)
    {
        require(activeTokens[depositToken], "Deposit token is not active");
        return
            IERC20(depositToken).transferFrom(
                msg.sender,
                address(this),
                depositAmount
            );
    }

    function depositFor(
        address sender,
        address depositToken,
        uint256 depositAmount
    ) external returns (bool) {
        require(activeTokens[depositToken], "Deposit token is not active");
        require(isWithdrawer(msg.sender), "Contract not authorized to deposit");
        return
            IERC20(depositToken).transferFrom(
                sender,
                address(this),
                depositAmount
            );
    }

    function depositToWETH() external payable {
        IWETH(WETH).deposit{value: msg.value}();
    }

    // withdrawers role
    function withdraw(
        address withdrawalToken,
        address recipient,
        uint256 withdrawalAmount
    ) external returns (bool) {
        require(
            isWithdrawer(msg.sender),
            "Contract not authorized to withdraw"
        );
        return IERC20(withdrawalToken).transfer(recipient, withdrawalAmount);
    }

    // withdrawers role
    function withdrawETH(address recipient, uint256 withdrawalAmount) external {
        require(isWithdrawer(msg.sender), "Not authorized to withdraw");
        IWETH(WETH).withdraw(withdrawalAmount);
        payable(recipient).transfer(withdrawalAmount);
    }
}

// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./RoleAware.sol";
import "./Fund.sol";

struct Claim {
    uint256 startingRewardRateFP;
    address recipient;
    uint256 amount;
}

contract IncentiveDistribution is RoleAware, Ownable {
    // fixed point number factor
    uint256 constant FP32 = 2**32;
    // the amount of contraction per thousand, per day
    // of the overal daily incentive distribution
    uint256 constant contractionPerMil = 999;
    // the period for which claims are batch updated
    uint256 constant period = 4 hours;
    uint256 constant periodsPerDay = 24 hours / period;
    address MFI;

    constructor(
        address _MFI,
        uint256 startingDailyDistributionWithoutDecimals,
        address _roles
    ) RoleAware(_roles) Ownable() {
        MFI = _MFI;
        currentDailyDistribution =
            startingDailyDistributionWithoutDecimals *
            (1 ether);
        lastDailyDistributionUpdate = block.timestamp / (1 days);
    }

    // how much is going to be distributed, contracts every day
    uint256 public currentDailyDistribution;
    // last day on which we updated currentDailyDistribution
    uint256 lastDailyDistributionUpdate;
    // portion of daily distribution per each tranche
    mapping(uint8 => uint256) public trancheShare;
    uint256 public trancheShareTotal;

    // tranche => claim totals for the period we're currently aggregating
    mapping(uint8 => uint256) public currentPeriodTotals;
    // tranche => timestamp / period of last update
    mapping(uint8 => uint256) public lastUpdatedPeriods;

    // how each claim unit would get if they had staked from the dawn of time
    // expressed as fixed point number
    // claim amounts are expressed relative to this ongoing aggregate
    mapping(uint8 => uint256) public aggregatePeriodicRewardRateFP;
    // claim records
    mapping(uint256 => Claim) public claims;
    uint256 public nextClaimId = 1;

    function setTrancheShare(uint8 tranche, uint256 share) external onlyOwner {
        require(
            lastUpdatedPeriods[tranche] > 0,
            "Tranche is not initialized, please initialize first"
        );
        _setTrancheShare(tranche, share);
    }

    function _setTrancheShare(uint8 tranche, uint256 share) internal {
        if (share > trancheShare[tranche]) {
            trancheShareTotal += share - trancheShare[tranche];
        } else {
            trancheShareTotal -= trancheShare[tranche] - share;
        }
        trancheShare[tranche] = share;
    }

    function initTranche(uint8 tranche, uint256 share) external onlyOwner {
        _setTrancheShare(tranche, share);

        lastUpdatedPeriods[tranche] = block.timestamp / period;
        // simply initialize to 1.0
        aggregatePeriodicRewardRateFP[tranche] = FP32;
    }

    function updatePeriodTotals(uint8 tranche) internal {
        uint256 currentPeriod = block.timestamp / period;

        // update the amount that gets distributed per day, if there has been
        // a day transition
        updateCurrentDailyDistribution();
        // Do a bunch of updating of periodic variables when the period changes
        uint256 lU = lastUpdatedPeriods[tranche];
        uint256 periodDiff = currentPeriod - lU;

        if (periodDiff > 0) {
            aggregatePeriodicRewardRateFP[tranche] +=
                currentPeriodicRewardRateFP(tranche) *
                periodDiff;
        }

        lastUpdatedPeriods[tranche] = currentPeriod;
    }

    function forcePeriodTotalUpdate(uint8 tranche) external {
        updatePeriodTotals(tranche);
    }

    function updateCurrentDailyDistribution() internal {
        uint256 nowDay = block.timestamp / (1 days);
        uint256 dayDiff = nowDay - lastDailyDistributionUpdate;

        // shrink the daily distribution for every day that has passed
        for (uint256 i = 0; i < dayDiff; i++) {
            currentDailyDistribution =
                (currentDailyDistribution * contractionPerMil) /
                1000;
        }
        // now update this memo
        lastDailyDistributionUpdate = nowDay;
    }

    function currentPeriodicRewardRateFP(uint8 tranche)
        internal
        view
        returns (uint256)
    {
        // scale daily distribution down to tranche share
        uint256 tranchePeriodDistributionFP =
            (FP32 * currentDailyDistribution * trancheShare[tranche]) /
                trancheShareTotal /
                periodsPerDay;

        // rate = (total_reward / total_claims) per period
        return tranchePeriodDistributionFP / currentPeriodTotals[tranche];
    }

    function startClaim(
        uint8 tranche,
        address recipient,
        uint256 claimAmount
    ) external returns (uint256) {
        require(
            isIncentiveReporter(msg.sender),
            "Contract not authorized to report incentives"
        );
        if (currentDailyDistribution > 0) {
            updatePeriodTotals(tranche);

            currentPeriodTotals[tranche] += claimAmount;

            claims[nextClaimId] = Claim({
                startingRewardRateFP: aggregatePeriodicRewardRateFP[tranche],
                recipient: recipient,
                amount: claimAmount
            });
            nextClaimId += 1;
            return nextClaimId - 1;
        } else {
            return 0;
        }
    }

    function addToClaimAmount(
        uint8 tranche,
        uint256 claimId,
        uint256 additionalAmount
    ) external {
        require(
            isIncentiveReporter(msg.sender),
            "Contract not authorized to report incentives"
        );
        if (currentDailyDistribution > 0) {
            updatePeriodTotals(tranche);

            currentPeriodTotals[tranche] += additionalAmount;

            Claim storage claim = claims[claimId];
            require(
                claim.startingRewardRateFP > 0,
                "Trying to add to non-existant claim"
            );
            _withdrawReward(tranche, claim);
            claim.amount += additionalAmount;
        }
    }

    function subtractFromClaimAmount(
        uint8 tranche,
        uint256 claimId,
        uint256 subtractAmount
    ) external {
        require(
            isIncentiveReporter(msg.sender),
            "Contract not authorized to report incentives"
        );
        updatePeriodTotals(tranche);

        currentPeriodTotals[tranche] -= subtractAmount;

        Claim storage claim = claims[claimId];
        _withdrawReward((tranche), claim);
        claim.amount -= subtractAmount;
    }

    function endClaim(uint8 tranche, uint256 claimId) external {
        require(
            isIncentiveReporter(msg.sender),
            "Contract not authorized to report incentives"
        );
        updatePeriodTotals(tranche);
        Claim storage claim = claims[claimId];

        if (claim.startingRewardRateFP > 0) {
            _withdrawReward(tranche, claim);
            delete claim.recipient;
            delete claim.startingRewardRateFP;
            delete claim.amount;
        }
    }

    function calcRewardAmount(uint8 tranche, Claim storage claim)
        internal
        view
        returns (uint256)
    {
        return
            (claim.amount *
                (aggregatePeriodicRewardRateFP[tranche] -
                    claim.startingRewardRateFP)) / FP32;
    }

    function viewRewardAmount(uint8 tranche, uint256 claimId)
        external
        view
        returns (uint256)
    {
        return calcRewardAmount(tranche, claims[claimId]);
    }

    function withdrawReward(uint8 tranche, uint256 claimId)
        external
        returns (uint256)
    {
        require(
            isIncentiveReporter(msg.sender),
            "Contract not authorized to report incentives"
        );
        updatePeriodTotals(tranche);
        Claim storage claim = claims[claimId];
        return _withdrawReward(tranche, claim);
    }

    function _withdrawReward(uint8 tranche, Claim storage claim)
        internal
        returns (uint256 rewardAmount)
    {
        rewardAmount = calcRewardAmount(tranche, claim);

        require(
            Fund(fund()).withdraw(MFI, claim.recipient, rewardAmount),
            "There seems to be a lack of MFI in the incentive fund!"
        );

        claim.startingRewardRateFP = aggregatePeriodicRewardRateFP[tranche];
    }
}

// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;

import "./Roles.sol";

/// Main characters are for service discovery
/// Whereas roles are for access control
contract RoleAware {
    uint16 public constant WITHDRAWER = 1;
    uint16 public constant MARGIN_CALLER = 2;
    uint16 public constant BORROWER = 3;
    uint16 public constant MARGIN_TRADER = 4;
    uint16 public constant FEE_SOURCE = 5;
    uint16 public constant LIQUIDATOR = 6;
    uint16 public constant AUTHORIZED_FUND_TRADER = 7;
    uint16 public constant INCENTIVE_REPORTER = 8;
    uint16 public constant TOKEN_ACTIVATOR = 9;
    uint16 public constant STAKE_PENALIZER = 10;

    uint16 public constant FUND = 101;
    uint16 public constant LENDING = 102;
    uint16 public constant ROUTER = 103;
    uint16 public constant MARGIN_TRADING = 104;
    uint16 public constant FEE_CONTROLLER = 105;
    uint16 public constant PRICE_CONTROLLER = 106;
    uint16 public constant ADMIN = 107;
    uint16 public constant INCENTIVE_DISTRIBUTION = 108;

    Roles public roles;
    mapping(uint16 => address) public mainCharacterCache;
    mapping(address => mapping(uint16 => bool)) public roleCache;

    constructor(address _roles) {
        roles = Roles(_roles);
    }

    modifier noIntermediary() {
        require(
            msg.sender == tx.origin,
            "Currently no intermediaries allowed for this function call"
        );
        _;
    }

    function updateRoleCache(uint16 role, address contr) public virtual {
        roleCache[contr][role] = roles.getRole(role, contr);
    }

    function updateMainCharacterCache(uint16 role) public virtual {
        mainCharacterCache[role] = roles.mainCharacters(role);
    }

    function fund() internal view returns (address) {
        return mainCharacterCache[FUND];
    }

    function lending() internal view returns (address) {
        return mainCharacterCache[LENDING];
    }

    function router() internal view returns (address) {
        return mainCharacterCache[ROUTER];
    }

    function marginTrading() internal view returns (address) {
        return mainCharacterCache[MARGIN_TRADING];
    }

    function feeController() internal view returns (address) {
        return mainCharacterCache[FEE_CONTROLLER];
    }

    function price() internal view returns (address) {
        return mainCharacterCache[PRICE_CONTROLLER];
    }

    function admin() internal view returns (address) {
        return mainCharacterCache[ADMIN];
    }

    function incentiveDistributor() internal view returns (address) {
        return mainCharacterCache[INCENTIVE_DISTRIBUTION];
    }

    function isBorrower(address contr) internal view returns (bool) {
        return roleCache[contr][BORROWER];
    }

    function isWithdrawer(address contr) internal view returns (bool) {
        return roleCache[contr][WITHDRAWER];
    }

    function isMarginTrader(address contr) internal view returns (bool) {
        return roleCache[contr][MARGIN_TRADER];
    }

    function isFeeSource(address contr) internal view returns (bool) {
        return roleCache[contr][FEE_SOURCE];
    }

    function isMarginCaller(address contr) internal view returns (bool) {
        return roleCache[contr][MARGIN_CALLER];
    }

    function isLiquidator(address contr) internal view returns (bool) {
        return roleCache[contr][LIQUIDATOR];
    }

    function isAuthorizedFundTrader(address contr)
        internal
        view
        returns (bool)
    {
        return roleCache[contr][AUTHORIZED_FUND_TRADER];
    }

    function isIncentiveReporter(address contr) internal view returns (bool) {
        return roleCache[contr][INCENTIVE_REPORTER];
    }

    function isTokenActivator(address contr) internal view returns (bool) {
        return roleCache[contr][TOKEN_ACTIVATOR];
    }

    function isStakePenalizer(address contr) internal view returns (bool) {
        return roles.getRole(STAKE_PENALIZER, contr);
    }
}

// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Roles is Ownable {
    mapping(address => mapping(uint16 => bool)) public roles;
    mapping(uint16 => address) public mainCharacters;

    constructor() Ownable() {
        // token activation from the get-go
        roles[msg.sender][9] = true;
    }

    function giveRole(uint16 role, address actor) external onlyOwner {
        roles[actor][role] = true;
    }

    function removeRole(uint16 role, address actor) external onlyOwner {
        roles[actor][role] = false;
    }

    function setMainCharacter(uint16 role, address actor) external onlyOwner {
        mainCharacters[role] = actor;
    }

    function getRole(uint16 role, address contr) external view returns (bool) {
        return roles[contr][role];
    }
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}