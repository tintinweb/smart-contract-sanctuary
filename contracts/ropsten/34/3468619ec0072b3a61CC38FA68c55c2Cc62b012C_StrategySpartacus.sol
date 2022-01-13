// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import "../../Interfaces/Rebasing/IRebaseStaker.sol";
import "../../Interfaces/Rebasing/IStakingManager.sol";
import "../../Interfaces/Uniswap/IUniswapRouterEth.sol";
import "../../Interfaces/Uniswap/IUniswapV2Pair.sol";
import "../../Interfaces/Rebasing/IBondDepository.sol";

import "../Common/FeeManager.sol";
import "../Common/StratManager.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";

/*
 __    __     __     __   __      ______   __
/\ "-./  \   /\ \   /\ "-.\ \    /\  ___\ /\ \
\ \ \-./\ \  \ \ \  \ \ \-.  \   \ \  __\ \ \ \
 \ \_\ \ \_\  \ \_\  \ \_\\"\_\   \ \_\    \ \_\
  \/_/  \/_/   \/_/   \/_/ \/_/    \/_/     \/_/
*/

/**
 * @dev Rebasing DAO yield optimizer for spartacus.finance
 * @author minimum.finance
 */
contract StrategySpartacus is StratManager, FeeManager {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev Super secret Discord link
     */
    string public discordLink;

    /**
     * @dev Tokens:
     * {rebaseToken}        - The rebase protocol's token
     * {stakedRebaseToken}  - The staked version of {rebaseToken}
     */
    address public constant rebaseToken =
        0x5602df4A94eB6C680190ACCFA2A475621E0ddBdc; // SPA
    address public constant stakedRebaseToken =
        0x8e2549225E21B1Da105563D419d5689b80343E01; // sSPA

    /**
     * @dev Bonds:
     * {bonds}              - Exhaustive list of the strategy's accepted bonds
     * {indexOfBond}        - Index of each bond in {bonds}
     * {currentBond}        - The current bond being used (0 address if not bonding)
     */
    address[] public bonds;
    mapping(address => uint256) indexOfBond; // 1-based to avoid default value
    address public currentBond;
    uint256 public rebaseBonded;

    /**
     * @dev RebasingDAO Contracts:
     * {rebaseStaker}       - The rebase StakingHelper contract
     * {stakeManager}       - The rebase OlympusStaking contract
     */
    address public rebaseStaker;
    address public stakeManager;

    struct Claim {
        bool fullyVested;
        uint256 amount;
        uint256 index;
    }

    /**
     * @dev Withdrawal:
     * {claimOfReserves}     - how much a user owns of the reserves in {rebaseToken}
     * {reserveUsers}        - list of users who requested a withdraw
     * {reserves}            - {rebaseToken} reserved for withdrawal use so that it cannot be bonded
     * {claimers}            - list of users who can calim -- for forcePayoutChunk
     */
    mapping(address => Claim) public claimOfReserves;
    address[] public reserveUsers;
    uint256 public reserves;
    address[] public claimers;

    // Utilities
    IUniswapV2Pair public constant rebaseTokenDaiPair =
        IUniswapV2Pair(0xFa5a5F0bC990Be1D095C5385Fff6516F6e03c0a7); // Used to get price of rebaseToken in USD

    /**
     * @dev Events:
     * Deposit          - Emitted when funds are deposited into the strategy
     * Reserve          - Emitted when funds are reserved from the strategy
     * Stake            - Emitted when {rebaseToken} is staked
     * Unstake          - Emitted when {rebaseToken} is unstaked
     * Bond             - Emitted when {rebaseToken} is bonded
     * BondAdded        - Emitted when a bondDepository is added to {bonds}
     * BondRemoved      - Emitted when a bondDepository is removed from {bonds}
     * Redeem           - Emitted when the keeper redeems a bond
     * RedeemFinal      - Emitted when the keeper executes the final redemption for a bond
     *
     * @notice trl - Total Rebasing Locked
     */
    event Deposit(uint256 trl);
    event Reserve(uint256 trl, uint256 payout);
    event Stake(uint256 totalStaked, uint256 totalBonded);
    event Unstake(
        uint256 totalStaked,
        uint256 totalUnstaked,
        uint256 totalBonded
    );
    event Bond(
        uint256 totalStaked,
        uint256 totalUnstaked,
        uint256 totalBonded,
        address bondDepository
    );
    event BondAdded(address[] bonds);
    event BondRemoved(address[] bonds);
    event Redeem(uint256 trl, uint256 rebaseRedeemed);
    event RedeemFinal(uint256 trl, uint256 rebaseRedeemed);

    constructor(
        address _vault,
        address _rebaseStaker,
        address _stakeManager,
        address _keeper,
        address _unirouter,
        address _serviceFeeRecipient,
        uint256 _minDeposit,
        string memory _discordLink
    )
        public
        StratManager(
            _keeper,
            _unirouter,
            _vault,
            _serviceFeeRecipient,
            _minDeposit
        )
    {
        require(
            _rebaseStaker != address(0) && _stakeManager != address(0),
            "!0 Address"
        );

        rebaseStaker = _rebaseStaker;
        stakeManager = _stakeManager;
        discordLink = _discordLink;
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
     * @dev Interface method for interoperability with vault
     */
    function want() external pure returns (address) {
        return rebaseToken;
    }

    /**
     * @dev Total staked and unstaked {rebaseToken} locked
     */
    function totalRebasing() public view returns (uint256) {
        return unstakedRebasing().add(stakedRebasing());
    }

    /**
     * @dev Total unstaked {rebaseToken} locked
     */
    function unstakedRebasing() public view returns (uint256) {
        return IERC20(rebaseToken).balanceOf(address(this));
    }

    /**
     * @dev Total staked {rebaseToken} locked
     */
    function stakedRebasing() public view returns (uint256) {
        return IERC20(stakedRebaseToken).balanceOf(address(this));
    }

    /**
     * @dev Total available staked and unstaked {rebaseToken} locked
     */
    function availableRebaseToken() public view returns (uint256) {
        return totalRebasing().sub(reserves);
    }

    /**
     * @dev Total staked, unstaked, and bonded {rebaseToken} locked
     */
    function totalBalance() public view returns (uint256) {
        uint256 rebaseAmount = totalRebasing();

        return
            reserves < rebaseAmount.add(rebaseBonded)
                ? rebaseAmount.add(rebaseBonded).sub(reserves)
                : 0;
    }

    /**
     * @dev Whether or not the strategy is currently bonding
     */
    function isBonding() public view returns (bool) {
        return currentBond != address(0);
    }

    /**
     * @dev Number of validated bonds
     */
    function numBonds() external view returns (uint256) {
        return bonds.length;
    }

    /**
     * @dev Check whether a bond is validated
     * @param _bondDepository BondDepository address
     */
    function isBondValid(address _bondDepository) public view returns (bool) {
        return indexOfBond[_bondDepository] != 0;
    }

    /* ======== USER FUNCTIONS ======== */

    /**
     * @dev Deposit available {rebaseToken} into Spartacus
     * @notice Emits Deposit(trl)
     */
    function deposit() external whenNotPaused {
        _stake();

        emit Deposit(totalBalance());
    }

    /**
     * @dev Reserves funds from staked {rebaseToken} to be paid out when bonding is over
     * @param _amount The amount of {rebaseToken} to reserve
     * @param _claimer The address whose funds need to be reserved
     * @notice Emits Reserve()
     * @notice If not currently bonding, sends funds immediately
     */
    function reserve(uint256 _amount, address _claimer) external {
        require(msg.sender == vault, "!Vault");

        _amount = _amount.sub(
            _amount.mul(withdrawalFee).div(WITHDRAWAL_FEE_DIVISOR)
        );

        if (isBonding()) {
            Claim memory previousClaim = claimOfReserves[_claimer];
            if (previousClaim.fullyVested || previousClaim.amount == 0)
                reserveUsers.push(_claimer);
            if (previousClaim.index == 0) claimers.push(_claimer);

            claimOfReserves[_claimer] = Claim({
                amount: previousClaim.amount.add(_amount),
                fullyVested: false, // Notice that users should claim before reserving again
                index: previousClaim.index == 0
                    ? claimers.length
                    : previousClaim.index
            });

            reserves = reserves.add(_amount);
        } else {
            if (_amount > totalRebasing()) _amount = totalRebasing();

            _pay(_claimer, _amount);
        }

        emit Reserve(totalBalance(), _amount);
    }

    /**
     * @dev Claim vested out position
     * @param _claimer The address of the claimer
     */
    function claim(address _claimer) external returns (uint256) {
        require(msg.sender == vault, "!Vault");
        require(claimOfReserves[_claimer].fullyVested, "!fullyVested");
        return _claim(_claimer);
    }

    /* ======== BOND FUNCTIONS ======== */

    /**
     * @dev Add a bond to the list of valid bonds
     * @param _bondDepository Bond to validate
     */
    function addBond(address _bondDepository) external onlyOwner {
        require(!isBondValid(_bondDepository), "!invalid bond");
        bonds.push(_bondDepository);
        indexOfBond[_bondDepository] = bonds.length; // 1 based indexing

        emit BondAdded(bonds);
    }

    /**
     * @dev Remove a bond from the list of valid bonds
     * @param _bondDepository Bond to invalidate
     */
    function removeBond(address _bondDepository) external onlyOwner {
        uint256 index = indexOfBond[_bondDepository]; // Starting from 1
        require(index <= bonds.length && index > 0, "!valid bond");

        if (bonds.length > 1) {
            bonds[index - 1] = bonds[bonds.length - 1]; // Replace with last element
        }
        // Remove last element as we have it saved in deleted slot
        bonds.pop();
        delete indexOfBond[_bondDepository];

        emit BondRemoved(bonds);
    }

    /**
     * @dev Move all sSPA from staking to bonding funds in a single token bond
     * @param bondDepository address of BondDepository to use
     * @param rebaseToPrincipleRoute the route from {rebaseToken} to bond principle
     */
    function stakeToBondSingleAll(
        IBondDepository bondDepository,
        address[] calldata rebaseToPrincipleRoute
    ) external {
        stakeToBondSingle(
            availableRebaseToken(),
            bondDepository,
            rebaseToPrincipleRoute
        );
    }

    /**
     * @dev Move all sSPA from staking to bonding funds in an LP token bond
     * @param bondDepository address of BondDepository to use
     * @param rebaseToToken0Route route from {rebaseToken} to token0 in the LP
     * @param rebaseToToken1Route route from {rebaseToken} to token1 in the LP
     */
    function stakeToBondLPAll(
        IBondDepository bondDepository,
        address[] calldata rebaseToToken0Route,
        address[] calldata rebaseToToken1Route
    ) external {
        stakeToBondLP(
            availableRebaseToken(),
            bondDepository,
            rebaseToToken0Route,
            rebaseToToken1Route
        );
    }

    /**
     * @dev Move from staking to bonding funds in a single token bond
     * @param _amount of sSPA to withdraw and bond
     * @param bondDepository BondDepository of the bond to use
     * @param rebaseToPrincipleRoute The route to take from {rebaseToken} to the bond principle token
     */
    function stakeToBondSingle(
        uint256 _amount,
        IBondDepository bondDepository,
        address[] calldata rebaseToPrincipleRoute
    ) public onlyManager {
        require(!isBonding(), "Already bonding!");
        require(_amount > 0, "amount <= 0!");
        require(isBondValid(address(bondDepository)), "Unapproved bond!");
        require(
            rebaseToPrincipleRoute.length > 0 &&
                rebaseToPrincipleRoute[0] == rebaseToken,
            "Route must start with rebaseToken!"
        );
        require(
            rebaseToPrincipleRoute[rebaseToPrincipleRoute.length - 1] ==
                bondDepository.principle(),
            "Route must end with bond principle!"
        );
        require(bondIsPositive(bondDepository), "!bondIsPositive");
        currentBond = address(bondDepository);

        uint256 maxBondableSPA = maxBondSize(bondDepository);

        if (_amount > availableRebaseToken()) _amount = availableRebaseToken();
        if (_amount > maxBondableSPA) _amount = maxBondableSPA;

        rebaseBonded = _amount;
        uint256 unstaked = unstakedRebasing();
        if (_amount > unstaked) _unstake(_amount.sub(unstaked)); // gets SPA to this strategy

        _bondSingleToken(_amount, bondDepository, rebaseToPrincipleRoute);
    }

    /**
     * @dev Move from staking to bonding funds in an LP token bond
     * @param _amount of sSPA to withdraw and bond
     * @param bondDepository BondDepository of the bond to use
     * @param rebaseToToken0Route route from {rebaseToken} to token0 in the LP
     * @param rebaseToToken1Route route from {rebaseToken} to token1 in the LP
     */
    function stakeToBondLP(
        uint256 _amount,
        IBondDepository bondDepository,
        address[] calldata rebaseToToken0Route,
        address[] calldata rebaseToToken1Route
    ) public onlyManager {
        require(!isBonding(), "Already bonding!");
        require(_amount > 0, "amount <= 0!");
        require(isBondValid(address(bondDepository)), "Unapproved bond!");
        require(
            rebaseToToken0Route.length > 0 &&
                rebaseToToken1Route.length > 0 &&
                rebaseToToken0Route[0] == rebaseToken &&
                rebaseToToken1Route[0] == rebaseToken,
            "Routes must start with {rebaseToken}!"
        );
        require(
            rebaseToToken0Route[rebaseToToken0Route.length - 1] ==
                IUniswapV2Pair(bondDepository.principle()).token0() &&
                rebaseToToken1Route[rebaseToToken1Route.length - 1] ==
                IUniswapV2Pair(bondDepository.principle()).token1(),
            "Routes must end with their respective tokens!"
        );
        require(bondIsPositive(bondDepository), "!bondIsPositive");
        currentBond = address(bondDepository);

        uint256 maxBondableSPA = maxBondSize(bondDepository);

        if (_amount > availableRebaseToken()) _amount = availableRebaseToken();
        if (_amount > maxBondableSPA) _amount = maxBondableSPA;

        uint256 unstaked = unstakedRebasing();
        if (_amount > unstaked) _unstake(_amount.sub(unstaked)); // gets SPA to this strategy

        _bondLPToken(
            _amount,
            bondDepository,
            rebaseToToken0Route,
            rebaseToToken1Route
        );
    }

    /**
     * @dev Redeem and stake rewards from a bond
     */
    function redeemAndStake() external onlyManager {
        _redeem();
    }

    /**
     * @dev Force push payout to claimer
     * @param _claimer The address of the claimer to payout
     */
    function forcePayout(address _claimer)
        external
        onlyOwner
        returns (uint256)
    {
        require(claimOfReserves[_claimer].fullyVested, "!fullyVested");
        return _claim(_claimer);
    }

    /**
     * @dev Force push payout to all claimers (in chunks to avoid gas limit)
     * @notice Necessary to be able to upgrade the strategy
     * @return Whether or not all claimers are paid out
     */
    function forcePayoutChunk() external onlyOwner returns (bool) {
        require(!isBonding(), "Cannot force payout chunk during bond!");
        uint256 chunkSize = Math.min(50, claimers.length);
        uint256 totalRebaseToken = totalRebasing();
        uint256 tempReserves = reserves;

        for (uint256 i = 0; i < chunkSize; i++) {
            address _claimer = claimers[i];
            Claim memory userClaim = claimOfReserves[_claimer];

            delete claimOfReserves[_claimer];

            // If for some reason we can't fulfill reserves, pay as much as we can to everyone
            uint256 _amount = reserves > totalRebaseToken
                ? userClaim.amount.mul(totalRebaseToken).div(reserves)
                : userClaim.amount;

            tempReserves = tempReserves.sub(_amount);

            _pay(_claimer, _amount);
        }

        for (uint256 i = 0; i < chunkSize; i++) {
            if (claimers.length > 1)
                claimers[i] = claimers[claimers.length - 1];
            claimers.pop();
        }

        reserves = claimers.length == 0 ? 0 : tempReserves; // Ensure no dust left in reserves

        return claimers.length == 0;
    }

    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /**
     * @dev Claim a user's vested out position
     * @param _claimer The address of the claimer
     */
    function _claim(address _claimer) internal returns (uint256) {
        Claim memory userClaim = claimOfReserves[_claimer];

        delete claimOfReserves[_claimer];

        // If for some reason we can't fulfill reserves, pay as much as we can to everyone
        uint256 _amount = reserves > totalRebasing()
            ? userClaim.amount.mul(totalRebasing()).div(reserves)
            : userClaim.amount;

        reserves = reserves.sub(_amount);

        if (claimers.length > 1)
            claimers[userClaim.index - 1] = claimers[claimers.length - 1];
        claimers.pop();

        _pay(_claimer, _amount);

        return _amount;
    }

    /**
     * @dev Send {rebaseToken} to the claimer
     * @param _claimer The address to send {rebaseToken} to
     * @param _amount The amount of {rebaseToken} to send
     */
    function _pay(address _claimer, uint256 _amount) internal {
        if (_amount > unstakedRebasing())
            _unstake(_amount.sub(unstakedRebasing()));

        IERC20(rebaseToken).safeTransfer(_claimer, _amount);
    }

    /**
     * @dev Stake all of the strategy's {rebaseToken}
     */
    function _stake() internal {
        uint256 _amount = unstakedRebasing();
        if (_amount < minDeposit) return;

        IERC20(rebaseToken).safeIncreaseAllowance(rebaseStaker, _amount);
        IRebaseStaker(rebaseStaker).stake(_amount);

        emit Stake(stakedRebasing(), rebaseBonded);
    }

    /**
     * @dev Unstake {stakedRebasingToken}
     * @param _amount of {stakedRebasingToken} to unstake
     * @notice if _amount exceeds the strategy's balance of
     * {stakedRebasingToken}, unstake all {stakedRebasingToken}
     */
    function _unstake(uint256 _amount) internal {
        if (_amount <= 0) return;
        if (_amount > stakedRebasing()) _amount = stakedRebasing();

        IERC20(stakedRebaseToken).safeIncreaseAllowance(stakeManager, _amount);
        IStakingManager(stakeManager).unstake(_amount, true);

        emit Unstake(stakedRebasing(), unstakedRebasing(), rebaseBonded);
    }

    /**
     * @dev Swap {rebaseToken} for {_outputToken}
     * @param _rebaseAmount The amount of {rebaseToken} to swap for {_outputToken}
     * @param rebaseToTokenRoute Route to swap from {rebaseToken} to the output
     * @notice If {_rebaseAmount} is greater than the available {rebaseToken}
     *         swaps all available {rebaseToken}
     * @notice Make sure to unstake {stakedRebaseToken} before calling!
     */
    function _swapRebaseForToken(
        uint256 _rebaseAmount,
        address[] memory rebaseToTokenRoute
    ) internal {
        require(
            rebaseToTokenRoute[0] == rebaseToken,
            "Route must start with rebaseToken!"
        );
        if (rebaseToTokenRoute[rebaseToTokenRoute.length - 1] == rebaseToken)
            return;

        IUniswapRouterETH(unirouter).swapExactTokensForTokens(
            _rebaseAmount > unstakedRebasing()
                ? unstakedRebasing()
                : _rebaseAmount,
            0,
            rebaseToTokenRoute,
            address(this),
            now
        );
    }

    /**
     * @dev Swap for token0 and token1 and provide liquidity to receive LP tokens
     * @param _amount The amount of {rebaseToken} to use to provide liquidity
     * @param token0 The first token in the LP
     * @param token1 The second token in the LP
     * @param rebaseToToken0Route The route to swap from {rebaseToken} to token0
     * @param rebaseToToken1Route The route to swap from {rebaseToken} to token1
     * @notice Make sure to unstake the desired amount of {stakedRebaseToken} before calling!
     */
    function _provideLiquidity(
        uint256 _amount,
        address token0,
        address token1,
        address[] memory rebaseToToken0Route,
        address[] memory rebaseToToken1Route
    ) internal {
        uint256 token0Before = IERC20(token0).balanceOf(address(this));
        uint256 token1Before = IERC20(token1).balanceOf(address(this));

        IERC20(rebaseToken).safeIncreaseAllowance(unirouter, _amount);

        if (rebaseToToken0Route.length > 1)
            _swapRebaseForToken(_amount.div(2), rebaseToToken0Route);
        if (rebaseToToken1Route.length > 1)
            _swapRebaseForToken(_amount.div(2), rebaseToToken1Route);

        uint256 token0After = IERC20(token0).balanceOf(address(this));
        uint256 token1After = IERC20(token1).balanceOf(address(this));

        uint256 token0Amount = token0After > token0Before
            ? token0After.sub(token0Before)
            : token0Before.sub(token0After);

        uint256 token1Amount = token1After > token1Before
            ? token1After.sub(token1Before)
            : token1Before.sub(token1After);

        IERC20(token0).safeIncreaseAllowance(unirouter, token0Amount);
        IERC20(token1).safeIncreaseAllowance(unirouter, token1Amount);

        IUniswapRouterETH(unirouter).addLiquidity(
            token0,
            token1,
            token0Amount,
            token1Amount,
            0,
            0,
            address(this),
            now
        );
    }

    /**
     * @dev Deposit into single sided bond
     * @param _amount of SPA to swap to single token and bond
     * @param bondDepository BondDepository address
     * @param rebaseToPrincipleRoute The route to swap from {rebaseToken} to the bond principle token
     */
    function _bondSingleToken(
        uint256 _amount,
        IBondDepository bondDepository,
        address[] memory rebaseToPrincipleRoute
    ) internal {
        address bondToken = rebaseToPrincipleRoute[
            rebaseToPrincipleRoute.length - 1
        ];
        uint256 bondTokenBalanceBefore = IERC20(bondToken).balanceOf(
            address(this)
        );

        // Swap allowance
        IERC20(rebaseToken).safeIncreaseAllowance(unirouter, _amount);

        _swapRebaseForToken(_amount, rebaseToPrincipleRoute);

        uint256 bondTokenObtained = IERC20(bondToken)
            .balanceOf(address(this))
            .sub(bondTokenBalanceBefore);

        _bondTokens(bondDepository, bondTokenObtained, bondToken);
    }

    /**
     * @dev Deposit into LP bond
     * @param _amount of SPA to swap to LP token and bond
     * @param bondDepository BondDepository address
     * @param rebaseToToken0Route route from {rebaseToken} to token0 in the LP
     * @param rebaseToToken1Route route from {rebaseToken} to token1 in the LP
     */
    function _bondLPToken(
        uint256 _amount,
        IBondDepository bondDepository,
        address[] memory rebaseToToken0Route,
        address[] memory rebaseToToken1Route
    ) internal {
        address bondToken = bondDepository.principle();
        address token0 = rebaseToToken0Route[rebaseToToken0Route.length - 1];
        address token1 = rebaseToToken1Route[rebaseToToken1Route.length - 1];

        uint256 bondTokenBalanceBefore = IERC20(bondToken).balanceOf(
            address(this)
        );

        uint256 unstakedBefore = unstakedRebasing();

        _provideLiquidity(
            _amount,
            token0,
            token1,
            rebaseToToken0Route,
            rebaseToToken1Route
        );

        rebaseBonded = unstakedBefore.sub(unstakedRebasing());

        uint256 bondTokenObtained = IERC20(bondToken)
            .balanceOf(address(this))
            .sub(bondTokenBalanceBefore);

        _bondTokens(bondDepository, bondTokenObtained, bondToken);
    }

    /**
     * @dev Bond tokens into the bond depository
     * @param bondDepository bond depository to bond into
     * @param _amount amount of principle to bond
     */
    function _bondTokens(
        IBondDepository bondDepository,
        uint256 _amount,
        address bondToken
    ) internal {
        uint256 acceptedSlippage = 5; // 0.5%
        uint256 maxPremium = bondDepository
            .bondPrice()
            .mul(acceptedSlippage.add(1000))
            .div(1000);

        // Update BondDepository allowances
        IERC20(bondToken).safeIncreaseAllowance(
            address(bondDepository),
            _amount
        );

        // Bond principle tokens
        bondDepository.deposit(_amount, maxPremium, address(this));
        _stake();

        emit Bond(
            stakedRebasing(),
            unstakedRebasing(),
            rebaseBonded,
            address(bondDepository)
        );
    }

    /**
     * @dev Claim redeem rewards from a bond and payout reserves if the bond is over.
     * @notice Stakes redeem rewards
     */
    function _redeem() internal {
        uint256 percentVested = IBondDepository(currentBond).percentVestedFor(
            address(this)
        );

        uint256 rebaseAmountBefore = unstakedRebasing();
        IBondDepository(currentBond).redeem(address(this), false);
        uint256 rebaseRedeemed = unstakedRebasing().sub(rebaseAmountBefore);
        _stake();
        rebaseRedeemed = _chargeFees(rebaseRedeemed);
        if (rebaseBonded > rebaseRedeemed) rebaseBonded -= rebaseRedeemed;
        else rebaseBonded = 0;

        // If this is final redemption, remove currentBond and update claimOfReserves
        if (percentVested >= 10000) {
            currentBond = address(0);
            rebaseBonded = 0;

            for (uint256 i = 0; i < reserveUsers.length; i++) {
                claimOfReserves[reserveUsers[i]].fullyVested = true;
            }
            emit RedeemFinal(totalRebasing(), rebaseRedeemed);
            delete reserveUsers;
        } else emit Redeem(totalBalance(), rebaseRedeemed);
    }

    /**
     * @dev Charge performance fees
     * @param _amount to fee
     */
    function _chargeFees(uint256 _amount) internal returns (uint256) {
        uint256 fee = _amount.mul(serviceFee).div(SERVICE_FEE_DIVISOR);
        IERC20(stakedRebaseToken).safeTransfer(serviceFeeRecipient, fee);
        return _amount.sub(fee);
    }

    /* ======== STRATEGY UPGRADE FUNCTIONS ======== */

    /**
     * @dev Retire strategy
     * @notice Called as part of strat migration.
     * @notice Sends all the available funds back to the vault
     */
    function retireStrat() external {
        require(msg.sender == vault, "!vault");
        require(reserves <= 0, "Reserves must be empty!");
        require(!isBonding(), "Cannot retire while bonding!");

        if (!paused()) _pause();
        _unstake(stakedRebasing());

        IERC20(rebaseToken).safeTransfer(vault, unstakedRebasing());
    }

    /* ======== EMERGENCY CONTROL FUNCTIONS ======== */

    /**
     * @dev Pauses deposits and withdraws all funds from third party systems
     */
    function panic() external onlyOwner {
        if (!paused()) _pause();
        if (isBonding()) _redeem();
        _unstake(stakedRebasing());
    }

    /**
     * @dev Pauses deposits
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses deposits
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Stakes all unstaked {rebaseToken} locked
     */
    function stake() external onlyOwner {
        _stake();
    }

    /**
     * @dev Unstakes all unstaked {rebaseToken} locked
     */
    function unstakeAll() external onlyOwner {
        _unstake(stakedRebasing());
    }

    /**
     * @dev Unstakes _amount of staked {rebaseToken}
     * @param _amount of staked {rebaseToken} to unstake
     */
    function unstake(uint256 _amount) external onlyOwner {
        _unstake(_amount);
    }

    /**
     * @dev Rescues random funds stuck that the strat can't handle
     * @param _token address of the token to rescue
     */
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        require(_token != rebaseToken && _token != stakedRebaseToken, "!token");

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    /* ======== UTILITY FUNCTIONS ======== */

    /**
     * @dev Returns the max amount of SPA that can be bonded into the given bond
     * @param bondDepository BondDepository to calculate the max bond size for
     */
    function maxBondSize(IBondDepository bondDepository)
        public
        view
        returns (uint256)
    {
        return
            bondDepository.bondPriceInUSD().mul(bondDepository.maxPayout()).div(
                rebaseTokenPriceInUSD(1e9)
            );
    }

    /**
     * @dev Whether or not a bond is positive
     * @param bondDepository The bond to examine
     */
    function bondIsPositive(IBondDepository bondDepository)
        public
        view
        returns (bool)
    {
        return bondDepository.bondPriceInUSD() < rebaseTokenPriceInUSD(1e9);
    }

    /**
     * @dev Get amount required in to receive an amount out
     * @param _amountOut Exact amount out
     * @param _inToOutRoute Route to swap from in to out
     * @notice Includes price impact
     */
    function getAmountIn(uint256 _amountOut, address[] calldata _inToOutRoute)
        external
        view
        returns (uint256)
    {
        return
            IUniswapRouterETH(unirouter).getAmountsIn(
                _amountOut,
                _inToOutRoute
            )[0];
    }

    /**
     * @dev Get amount received out from an exact amount in
     * @param _amountIn Exact amount in
     * @param _inToOutRoute Route to swap from in to out
     * @notice Includes price impact
     */
    function getAmountOut(uint256 _amountIn, address[] calldata _inToOutRoute)
        external
        view
        returns (uint256)
    {
        return
            IUniswapRouterETH(unirouter).getAmountsOut(
                _amountIn,
                _inToOutRoute
            )[_inToOutRoute.length - 1];
    }

    /**
     * @dev Convert token amount to {rebaseToken}
     * @param _tokenAmount to convert to {rebaseToken}
     * @param _tokenRebasePair Pair for calculation
     * @notice Does not include price impact
     */
    function tokenToRebase(
        uint256 _tokenAmount,
        IUniswapV2Pair _tokenRebasePair
    ) external view returns (uint256) {
        (uint256 Res0, uint256 Res1, ) = _tokenRebasePair.getReserves();
        // return # of {token} needed to buy _amount of rebaseToken
        return _tokenAmount.mul(Res1).div(Res0);
    }

    /**
     * @dev Get {rebaseToken} price in USD denomination
     * @param _amount of {rebaseToken}
     * @notice Does not include price impact
     */
    function rebaseTokenPriceInUSD(uint256 _amount)
        public
        view
        returns (uint256)
    {
        (uint256 Res0, uint256 Res1, ) = rebaseTokenDaiPair.getReserves();
        // return # of Dai needed to buy _amount of rebaseToken
        return _amount.mul(Res1).div(Res0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

/*
 * @dev Interface for StakingHelper contracts used with rebasing tokens.
 * @author minimum.finance
 */
interface IRebaseStaker {
    function stake(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

/*
 * @dev Interface for OlympusStaking contracts used with rebasing tokens.
 * @author minimum.finance
 */
interface IStakingManager {
    function unstake(uint256 _amount, bool _trigger) external;

    function rebase() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IUniswapRouterETH {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

/*
 * @dev Interface for BondDepository contracts used with rebasing tokens.
 * @author minimum.finance
 */
interface IBondDepository {
    function redeem(address _recipient, bool _stake) external;

    function deposit(
        uint256 _amount,
        uint256 _maxPrice,
        address _depositor
    ) external returns (uint256);

    function bondPrice() external view returns (uint256);

    function pendingPayoutFor(address _depositAddress)
        external
        view
        returns (uint256);

    function payoutFor(uint256 _amount) external view returns (uint256);

    function maxPayout() external view returns (uint256);

    function bondInfo(address _depositor)
        external
        view
        returns (
            uint256 payout,
            uint256 vesting,
            uint256 lastBlock,
            uint256 pricePaid
        );

    function principle() external view returns (address);

    function percentVestedFor(address _depositor)
        external
        view
        returns (uint256);

    function bondPriceInUSD() external view returns (uint256);

    function assetPrice() external view returns (uint256);

    function policy() external view returns (address);

    function setBondTerms(uint8 _paramater, uint256 _input) external;

    function setBasePrice(uint256 _basePrice) external;

    function terms()
        external
        view
        returns (
            uint256 controlVariable,
            uint256 vestingTerm,
            uint256 minimumPrice,
            uint256 maximumPayout,
            uint256 fee,
            uint256 maxDebt
        );

    function debtRatio() external view returns (uint256);

    function basePrice() external view returns (uint256);

    function isLiquidityBond() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./StratManager.sol";

abstract contract FeeManager is StratManager {
    uint256 public constant SERVICE_FEE_CAP = 300; // 3%
    uint256 public constant SERVICE_FEE_DIVISOR = 10000;
    uint256 public constant WITHDRAWAL_FEE_CAP = 50;
    uint256 public constant WITHDRAWAL_FEE_DIVISOR = 10000;

    /**
     * @dev Events emitted:
     * {SetServiceFee}          - Emitted when the service fee is changed
     * {SetWithdrawalFee}       - Emitted when the withdrawal fee is changed
     */
    event SetServiceFee(uint256 serviceFee);
    event SetWithdrawalFee(uint256 withdrawalFee);

    uint256 public serviceFee = 50; // .5%
    uint256 public withdrawalFee = 10; // .1%

    function setServiceFee(uint256 _fee) external onlyManager {
        require(_fee <= SERVICE_FEE_CAP, "!cap");

        serviceFee = _fee;

        emit SetServiceFee(withdrawalFee);
    }

    function setWithdrawalFee(uint256 _fee) external onlyManager {
        require(_fee <= WITHDRAWAL_FEE_CAP, "!cap");

        withdrawalFee = _fee;

        emit SetWithdrawalFee(withdrawalFee);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @dev Abstraction over common strategy components.
 */
abstract contract StratManager is Ownable, Pausable {
    /**
     * @dev Events:
     * NewKeeper                - Emitted when the {keeper} is changed
     * NewUnirouter             - Emitted when the {unirouter} is changed
     * NewVault                 - Emitted when the {vault} is changed
     * NewServiceFeeRecipient   - Emitted when the {serviceFeeRecipient} is changed
     * NewMinDeposit            - Emitted when the {minDeposit} is changed
     */
    event NewKeeper(address newKeeper);
    event NewUnirouter(address newUnirouter);
    event NewVault(address newVault);
    event NewServiceFeeRecipient(address newServiceFeeRecipient);
    event NewMinDeposit(uint256 newMinDeposit);

    /**
     * @dev Strategy behavior config:
     * {minDeposit}         - The minimum threshold of {rebaseToken} to enter rebasing
     */
    uint256 public minDeposit;

    /**
     * @dev Addresses:
     * {keeper}                 - Manages strategy performance
     * {unirouter}              - Address of exchange to execute swaps
     * {vault}                  - Address of the vault that controls the strategy's funds
     * {serviceFeeRecipient}    - Address to receive service fees
     */
    address public keeper;
    address public unirouter;
    address public vault;
    address public serviceFeeRecipient;

    constructor(
        address _keeper,
        address _unirouter,
        address _vault,
        address _serviceFeeRecipient,
        uint256 _minDeposit
    ) public {
        require(
            _keeper != address(0) &&
                _unirouter != address(0) &&
                _vault != address(0) &&
                _serviceFeeRecipient != address(0),
            "!0 Address"
        );

        keeper = _keeper;
        unirouter = _unirouter;
        vault = _vault;
        serviceFeeRecipient = _serviceFeeRecipient;
        minDeposit = _minDeposit;
    }

    // checks that caller is either owner or keeper.
    modifier onlyManager() {
        require(msg.sender == owner() || msg.sender == keeper, "!manager");
        _;
    }

    /**
     * @dev Updates address of the strat keeper.
     * @param _keeper new keeper address.
     */
    function setKeeper(address _keeper) external onlyOwner {
        require(_keeper != address(0), "!0 Address");

        keeper = _keeper;

        emit NewKeeper(_keeper);
    }

    /**
     * @dev Updates router that will be used for swaps.
     * @param _unirouter new unirouter address.
     */
    function setUnirouter(address _unirouter) external onlyOwner {
        require(_unirouter != address(0), "!0 Address");

        unirouter = _unirouter;

        emit NewUnirouter(_unirouter);
    }

    /**
     * @dev Updates parent vault.
     * @param _vault new vault address.
     */
    function setVault(address _vault) external onlyOwner {
        require(_vault != address(0), "!0 Address");

        vault = _vault;

        emit NewVault(_vault);
    }

    /**
     * @dev Updates beefy fee recipient.
     * @param _serviceFeeRecipient new beefy fee recipient address.
     */
    function setServiceFeeRecipient(address _serviceFeeRecipient)
        external
        onlyOwner
    {
        require(_serviceFeeRecipient != address(0), "!0 Address");

        serviceFeeRecipient = _serviceFeeRecipient;

        emit NewServiceFeeRecipient(_serviceFeeRecipient);
    }

    /**
     * @dev Updates the minimum deposit amount.
     * @param _minDeposit The new minimum deposit amount.
     */
    function setMinDeposit(uint256 _minDeposit) external onlyOwner {
        minDeposit = _minDeposit;

        emit NewMinDeposit(_minDeposit);
    }

    /**
     * @dev Function to synchronize balances before new user deposit.
     * Can be overridden in the strategy.
     */
    function beforeDeposit() external virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
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

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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