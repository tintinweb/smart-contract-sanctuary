pragma solidity ^0.5.16;

import "./KineOracleInterface.sol";
import "./KineControllerInterface.sol";
import "./KUSDMinterDelegate.sol";
import "./Math.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

/// @notice IKineUSD, a simplified interface of KineUSD (see KineUSD)
interface IKineUSD {
    function mint(address account, uint amount) external;

    function burn(address account, uint amount) external;

    function balanceOf(address account) external view returns (uint256);
}

/// @notice IKMCD, a simplified interface of KMCD (see KMCD)
interface IKMCD {
    function borrowBehalf(address payable borrower, uint borrowAmount) external;

    function repayBorrowBehalf(address borrower, uint repayAmount) external;

    function liquidateBorrowBehalf(address liquidator, address borrower, uint repayAmount, address kTokenCollateral, uint minSeizeKToken) external;

    function borrowBalance(address account) external view returns (uint);

    function totalBorrows() external view returns (uint);
}

/**
 * @title IRewardDistributionRecipient
 */
contract IRewardDistributionRecipient is KUSDMinterDelegate {
    /// @notice Emitted when reward distributor changed
    event NewRewardDistribution(address oldRewardDistribution, address newRewardDistribution);

    /// @notice The reward distributor who is responsible to transfer rewards to this recipient and notify the recipient that reward is added.
    address public rewardDistribution;

    /// @notice Notify this recipient that reward is added.
    function notifyRewardAmount(uint reward) external;

    /// @notice Only reward distributor can notify that reward is added.
    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    /// @notice Set reward distributor to new one.
    function setRewardDistribution(address _rewardDistribution) external onlyOwner {
        address oldRewardDistribution = rewardDistribution;
        rewardDistribution = _rewardDistribution;
        emit NewRewardDistribution(oldRewardDistribution, _rewardDistribution);
    }
}

/**
 * @title KUSDMinter is responsible to stake/unstake users' Kine MCD (see KMCD) and mint/burn KUSD (see KineUSD) on behalf of users.
 * When user want to mint KUSD against their collaterals (see KToken), KUSDMinter will borrow Knie MCD on behalf of user (which will increase user's debt ratio)
 * and then call KineUSD to mint KUSD to user. When user want to  burn KUSD, KUSDMinter will call KineUSD to burn KUSD from user and  repay Kine MCD on behalf of user.
 * KUSDMinter also let treasury account to mint/burn its balance to keep KUSD amount (the part that user transferred into Kine off-chain trading system) synced with Kine off-chain trading system.
 * @author Kine
 */
contract KUSDMinter is IRewardDistributionRecipient {
    using KineSafeMath for uint;
    using SafeERC20 for IERC20;

    /// @notice Emitted when KMCD changed
    event NewKMCD(address oldKMCD, address newKMCD);
    /// @notice Emitted when KineUSD changed
    event NewKUSD(address oldKUSD, address newKUSD);
    /// @notice Emitted when Kine changed
    event NewKine(address oldKine, address newKine);
    /// @notice Emitted when reward duration changed
    event NewRewardDuration(uint oldRewardDuration, uint newRewardDuration);
    /// @notice Emitted when reward release period changed
    event NewRewardReleasePeriod(uint oldRewardReleasePeriod, uint newRewardReleasePeriod);
    /// @notice Emitted when burn cool down time changed
    event NewBurnCooldownTime(uint oldCooldown, uint newCooldownTime);
    /// @notice Emitted when user mint KUSD
    event Mint(address indexed user, uint mintKUSDAmount, uint stakedKMCDAmount, uint userStakesNew, uint totalStakesNew);
    /// @notice Emitted when user burnt KUSD
    event Burn(address indexed user, uint burntKUSDAmount, uint unstakedKMCDAmount, uint userStakesNew, uint totalStakesNew);
    /// @notice Emitted when user burnt maximum KUSD
    event BurnMax(address indexed user, uint burntKUSDAmount, uint unstakedKMCDAmount, uint userStakesNew, uint totalStakesNew);
    /// @notice Emitted when liquidator liquidate staker's Kine MCD
    event Liquidate(address indexed liquidator, address indexed staker, uint burntKUSDAmount, uint unstakedKMCDAmount, uint stakerStakesNew, uint totalStakesNew);
    /// @notice Emitted when distributor notify reward is added
    event RewardAdded(uint reward);
    /// @notice Emitted when user claimed reward
    event RewardPaid(address indexed user, uint reward);
    /// @notice Emitted when treasury account mint kusd
    event TreasuryMint(uint amount);
    /// @notice Emitted when treasury account burn kusd
    event TreasuryBurn(uint amount);
    /// @notice Emitted when treasury account changed
    event NewTreasury(address oldTreasury, address newTreasury);
    /// @notice Emitted when vault account changed
    event NewVault(address oldVault, address newVault);
    /// @notice Emitted when controller changed
    event NewController(address oldController, address newController);

    /**
     * @notice This is for avoiding reward calculation overflow (see https://sips.synthetix.io/sips/sip-77)
     * 1.15792e59 < uint(-1) / 1e18
    */
    uint public constant REWARD_OVERFLOW_CHECK = 1.15792e59;

    /**
     * @notice Implementation address slot for delegation mode;
     */
    address public implementation;

    /// @notice Flag to mark if this contract has been initialized before
    bool public initialized;

    /// @notice Contract which holds Kine MCD
    IKMCD public kMCD;

    /// @notice Contract which holds Kine USD
    IKineUSD public kUSD;

    /// @notice Contract of controller which holds Kine Oracle
    KineControllerInterface public controller;

    /// @notice Treasury is responsible to keep KUSD amount consisted with Kine off-chain trading system
    address public treasury;

    /// @notice Vault is the place to store Kine trading system's reserved KUSD
    address public vault;

    /****************
    * Reward related
    ****************/

    /// @notice Contract which hold Kine Token
    IERC20 public kine;
    /// @notice Reward distribution duration. Added reward will be distribute to Kine MCD stakers within this duration.
    uint public rewardDuration;
    /// @notice Staker's reward will mature gradually in this period.
    uint public rewardReleasePeriod;
    /// @notice Start time that users can start staking/burning KUSD and claim their rewards.
    uint public startTime;
    /// @notice End time of this round of reward distribution.
    uint public periodFinish = 0;
    /// @notice Per second reward to be distributed
    uint public rewardRate = 0;
    /// @notice Accrued reward per Kine MCD staked per second.
    uint public rewardPerTokenStored;
    /// @notice Last time that rewardPerTokenStored is updated. Happens whenever total stakes going to be changed.
    uint public lastUpdateTime;
    /**
     * @notice The minium cool down time before user can burn kUSD after they mint kUSD everytime.
     * This is to raise risk and cost to arbitrageurs who front run our prices updates in oracle to drain profit from stakers.
     * Should be larger then minium price post interval.
     */
    uint public burnCooldownTime;

    struct AccountRewardDetail {
        /// @dev Last time account claimed its reward
        uint lastClaimTime;
        /// @dev RewardPerTokenStored at last time accrue rewards to this account
        uint rewardPerTokenUpdated;
        /// @dev Accrued rewards haven't been claimed of this account
        uint accruedReward;
        /// @dev Last time account mint kUSD
        uint lastMintTime;
    }

    /// @notice Mapping of account addresses to account reward detail
    mapping(address => AccountRewardDetail) public accountRewardDetails;

    function initialize(address kine_, address kUSD_, address kMCD_, address controller_, address treasury_, address vault_, address rewardDistribution_, uint startTime_, uint rewardDuration_, uint rewardReleasePeriod_) external {
        require(initialized == false, "KUSDMinter can only be initialized once");
        kine = IERC20(kine_);
        kUSD = IKineUSD(kUSD_);
        kMCD = IKMCD(kMCD_);
        controller = KineControllerInterface(controller_);
        treasury = treasury_;
        vault = vault_;
        rewardDistribution = rewardDistribution_;
        startTime = startTime_;
        rewardDuration = rewardDuration_;
        rewardReleasePeriod = rewardReleasePeriod_;
        initialized = true;
    }

    /**
     * @dev Local vars in calculating equivalent amount between KUSD and Kine MCD
     */
    struct CalculateVars {
        uint equivalentKMCDAmount;
        uint equivalentKUSDAmount;
    }

    /// @notice Prevent stakers' actions before start time
    modifier checkStart() {
        require(block.timestamp >= startTime, "not started yet");
        _;
    }

    /// @notice Prevent accounts other than treasury to mint/burn KUSD
    modifier onlyTreasury() {
        require(msg.sender == treasury, "only treasury account is allowed");
        _;
    }

    modifier afterCooldown(address staker) {
        require(accountRewardDetails[staker].lastMintTime.add(burnCooldownTime) < block.timestamp, "burn still cooling down");
        _;
    }

    /***
     * @notice Accrue account's rewards and store this time accrued results
     * @param account Reward status of whom to be updated
     */
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            accountRewardDetails[account].accruedReward = earned(account);
            accountRewardDetails[account].rewardPerTokenUpdated = rewardPerTokenStored;
            if (accountRewardDetails[account].lastClaimTime == 0) {
                accountRewardDetails[account].lastClaimTime = block.timestamp;
            }
        }
        _;
    }

    /**
     * @notice Current time which hasn't past this round reward's duration.
     * @return Current timestamp that hasn't past this round rewards' duration.
     */
    function lastTimeRewardApplicable() public view returns (uint) {
        return Math.min(block.timestamp, periodFinish);
    }

    /**
     * @notice Calculate new accrued reward per staked Kine MCD.
     * @return Current accrued reward per staked Kine MCD.
     */
    function rewardPerToken() public view returns (uint) {
        uint totalStakes = totalStakes();
        if (totalStakes == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.add(
            lastTimeRewardApplicable()
            .sub(lastUpdateTime)
            .mul(rewardRate)
            .mul(1e18)
            .div(totalStakes)
        );
    }

    /**
     * @notice Calculate account's earned rewards so far.
     * @param account Which account to be viewed.
     * @return Account's earned rewards so far.
     */
    function earned(address account) public view returns (uint) {
        return accountStakes(account)
        .mul(rewardPerToken().sub(accountRewardDetails[account].rewardPerTokenUpdated))
        .div(1e18)
        .add(accountRewardDetails[account].accruedReward);
    }

    /**
     * @notice Calculate account's claimable rewards so far.
     * @param account Which account to be viewed.
     * @return Account's claimable rewards so far.
     */
    function claimable(address account) external view returns (uint) {
        uint accountNewAccruedReward = earned(account);
        uint pastTime = block.timestamp.sub(accountRewardDetails[account].lastClaimTime);
        uint maturedReward = rewardReleasePeriod == 0 ? accountNewAccruedReward : accountNewAccruedReward.mul(pastTime).div(rewardReleasePeriod);
        if (maturedReward > accountNewAccruedReward) {
            maturedReward = accountNewAccruedReward;
        }
        return maturedReward;
    }

    /**
    * @notice Mint will borrow equivalent Kine MCD for user, stake borrowed MCD and mint specified amount of KUSD. Call will fail if hasn't reached start time.
    * Mint will fail if hasn't reach start time.
    * @param kUSDAmount The amount of KUSD user want to mint
    */
    function mint(uint kUSDAmount) external checkStart updateReward(msg.sender) {
        address payable msgSender = _msgSender();
        // update sender's mint time
        accountRewardDetails[msgSender].lastMintTime = block.timestamp;

        uint kMCDPriceMantissa = KineOracleInterface(controller.getOracle()).getUnderlyingPrice(address(kMCD));
        require(kMCDPriceMantissa != 0, "Mint: get Kine MCD price zero");

        CalculateVars memory vars;

        // KUSD has 18 decimals
        // KMCD has 18 decimals
        // kMCDPriceMantissa is KMCD's price (quoted by KUSD, has 6 decimals) scaled by 1e36 / KMCD's decimals = 1e36 / 1e18 = 1e18
        // so the calculation of equivalent Kine MCD amount is as below
        //                          kUSDAmount        1e12 * 1e6               kUSDAmount * 1e18
        // equivalentKMCDAmount =  ----------- *  ------------------ * 1e18 =  -----------------
        //                             1e18         kMCDPriceMantissa           kMCDPriceMantissa

        vars.equivalentKMCDAmount = kUSDAmount.mul(1e18).div(kMCDPriceMantissa);

        // call KMCD contract to borrow Kine MCD for user and stake them
        kMCD.borrowBehalf(msgSender, vars.equivalentKMCDAmount);

        // mint KUSD to user
        kUSD.mint(msgSender, kUSDAmount);

        emit Mint(msgSender, kUSDAmount, vars.equivalentKMCDAmount, accountStakes(msgSender), totalStakes());
    }

    /**
    * @notice Burn repay equivalent Kine MCD for user and burn specified amount of KUSD
    * Burn will fail if hasn't reach start time.
    * @param kUSDAmount The amount of KUSD user want to burn
    */
    function burn(uint kUSDAmount) external checkStart afterCooldown(msg.sender) updateReward(msg.sender) {
        address msgSender = _msgSender();

        // burn user's KUSD
        kUSD.burn(msgSender, kUSDAmount);

        // calculate equivalent Kine MCD amount to specified amount of KUSD
        uint kMCDPriceMantissa = KineOracleInterface(controller.getOracle()).getUnderlyingPrice(address(kMCD));
        require(kMCDPriceMantissa != 0, "Burn: get Kine MCD price zero");

        CalculateVars memory vars;

        // KUSD has 18 decimals
        // KMCD has 18 decimals
        // kMCDPriceMantissa is KMCD's price (quoted by KUSD, has 6 decimals) scaled by 1e36 / KMCD's decimals = 1e36 / 1e18 = 1e18
        // so the calculation of equivalent Kine MCD amount is as below
        //                          kUSDAmount        1e12 * 1e6               kUSDAmount * 1e18
        // equivalentKMCDAmount =  ----------- *  ------------------ * 1e18 =  -----------------
        //                             1e18         kMCDPriceMantissa           kMCDPriceMantissa

        vars.equivalentKMCDAmount = kUSDAmount.mul(1e18).div(kMCDPriceMantissa);

        // call KMCD contract to repay Kine MCD for user
        kMCD.repayBorrowBehalf(msgSender, vars.equivalentKMCDAmount);

        emit Burn(msgSender, kUSDAmount, vars.equivalentKMCDAmount, accountStakes(msgSender), totalStakes());
    }

    /**
    * @notice BurnMax unstake and repay all borrowed Kine MCD for user and burn equivalent KUSD
    */
    function burnMax() external checkStart afterCooldown(msg.sender) updateReward(msg.sender) {
        address msgSender = _msgSender();

        uint kMCDPriceMantissa = KineOracleInterface(controller.getOracle()).getUnderlyingPrice(address(kMCD));
        require(kMCDPriceMantissa != 0, "BurnMax: get Kine MCD price zero");

        CalculateVars memory vars;

        // KUSD has 18 decimals
        // KMCD has 18 decimals
        // kMCDPriceMantissa is KMCD's price (quoted by KUSD, has 6 decimals) scaled by 1e36 / KMCD's decimals = 1e36 / 1e18 = 1e18
        // so the calculation of equivalent KUSD amount is as below
        //                         accountStakes     kMCDPriceMantissa         accountStakes * kMCDPriceMantissa
        // equivalentKUSDAmount =  ------------- *  ------------------ * 1e18 = ---------------------------------
        //                             1e18            1e12 * 1e6                          1e18
        //

        // try to unstake all Kine MCD
        uint userStakes = accountStakes(msgSender);
        vars.equivalentKMCDAmount = userStakes;
        vars.equivalentKUSDAmount = userStakes.mul(kMCDPriceMantissa).div(1e18);

        // in case user's kUSD is not enough to unstake all mcd, then just burn all kUSD and unstake part of MCD
        uint kUSDbalance = kUSD.balanceOf(msgSender);
        if (vars.equivalentKUSDAmount > kUSDbalance) {
            vars.equivalentKUSDAmount = kUSDbalance;
            vars.equivalentKMCDAmount = kUSDbalance.mul(1e18).div(kMCDPriceMantissa);
        }

        // burn user's equivalent KUSD
        kUSD.burn(msgSender, vars.equivalentKUSDAmount);

        // call KMCD contract to repay Kine MCD for user
        kMCD.repayBorrowBehalf(msgSender, vars.equivalentKMCDAmount);

        emit BurnMax(msgSender, vars.equivalentKUSDAmount, vars.equivalentKMCDAmount, accountStakes(msgSender), totalStakes());
    }

    /**
     * @notice Caller liquidates the staker's Kine MCD and seize staker's collateral.
     * Liquidate will fail if hasn't reach start time.
     * @param staker The staker of Kine MCD to be liquidated.
     * @param unstakeKMCDAmount The amount of Kine MCD to unstake.
     * @param maxBurnKUSDAmount The max amount limit of KUSD of liquidator to be burned.
     * @param kTokenCollateral The market in which to seize collateral from the staker.
     */
    function liquidate(address staker, uint unstakeKMCDAmount, uint maxBurnKUSDAmount, address kTokenCollateral, uint minSeizeKToken) external checkStart updateReward(staker) {
        address msgSender = _msgSender();

        uint kMCDPriceMantissa = KineOracleInterface(controller.getOracle()).getUnderlyingPrice(address(kMCD));
        require(kMCDPriceMantissa != 0, "Liquidate: get Kine MCD price zero");

        CalculateVars memory vars;

        // KUSD has 18 decimals
        // KMCD has 18 decimals
        // kMCDPriceMantissa is KMCD's price (quoted by KUSD, has 6 decimals) scaled by 1e36 / KMCD's decimals = 1e36 / 1e18 = 1e18
        // so the calculation of equivalent KUSD amount is as below
        //                         accountStakes     kMCDPriceMantissa         accountStakes * kMCDPriceMantissa
        // equivalentKUSDAmount =  ------------- *  ------------------ * 1e18 = ---------------------------------
        //                             1e18            1e12 * 1e6                          1e30
        //

        vars.equivalentKUSDAmount = unstakeKMCDAmount.mul(kMCDPriceMantissa).div(1e18);

        require(maxBurnKUSDAmount >= vars.equivalentKUSDAmount, "Liquidate: reach out max burn KUSD amount limit");

        // burn liquidator's KUSD
        kUSD.burn(msgSender, vars.equivalentKUSDAmount);

        // call KMCD contract to liquidate staker's Kine MCD and seize collateral
        kMCD.liquidateBorrowBehalf(msgSender, staker, unstakeKMCDAmount, kTokenCollateral, minSeizeKToken);

        emit Liquidate(msgSender, staker, vars.equivalentKUSDAmount, unstakeKMCDAmount, accountStakes(staker), totalStakes());
    }

    /**
     * @notice Show account's staked Kine MCD amount
     * @param account The account to be get MCD amount from
     */
    function accountStakes(address account) public view returns (uint) {
        return kMCD.borrowBalance(account);
    }

    /// @notice Show total staked Kine MCD amount
    function totalStakes() public view returns (uint) {
        return kMCD.totalBorrows();
    }

    /**
     * @notice Claim the matured rewards of caller.
     * Claim will fail if hasn't reach start time.
     */
    function getReward() external checkStart updateReward(msg.sender) {
        uint reward = accountRewardDetails[msg.sender].accruedReward;
        if (reward > 0) {
            uint pastTime = block.timestamp.sub(accountRewardDetails[msg.sender].lastClaimTime);
            uint maturedReward = rewardReleasePeriod == 0 ? reward : reward.mul(pastTime).div(rewardReleasePeriod);
            if (maturedReward > reward) {
                maturedReward = reward;
            }

            accountRewardDetails[msg.sender].accruedReward = reward.sub(maturedReward);
            accountRewardDetails[msg.sender].lastClaimTime = block.timestamp;
            kine.safeTransfer(msg.sender, maturedReward);
            emit RewardPaid(msg.sender, maturedReward);
        }
    }

    /**
     * @notice Notify rewards has been added, trigger a new round of reward period, recalculate reward rate and duration end time.
     * If distributor notify rewards before this round duration end time, then the leftover rewards of this round will roll over to
     * next round and will be distributed together with new rewards in next round of reward period.
     * @param reward How many of rewards has been added for new round of reward period.
     */
    function notifyRewardAmount(uint reward) external onlyRewardDistribution updateReward(address(0)) {
        if (block.timestamp > startTime) {
            if (block.timestamp >= periodFinish) {
                // @dev to avoid of rewardPerToken calculation overflow (see https://sips.synthetix.io/sips/sip-77), we check the reward to be inside a properate range
                // which is 2^256 / 10^18
                require(reward < REWARD_OVERFLOW_CHECK, "reward rate will overflow");
                rewardRate = reward.div(rewardDuration);
            } else {
                uint remaining = periodFinish.sub(block.timestamp);
                uint leftover = remaining.mul(rewardRate);
                // @dev to avoid of rewardPerToken calculation overflow (see https://sips.synthetix.io/sips/sip-77), we check the reward to be inside a properate range
                // which is 2^256 / 10^18
                require(reward.add(leftover) < REWARD_OVERFLOW_CHECK, "reward rate will overflow");
                rewardRate = reward.add(leftover).div(rewardDuration);
            }
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(rewardDuration);
            emit RewardAdded(reward);
        } else {
            // @dev to avoid of rewardPerToken calculation overflow (see https://sips.synthetix.io/sips/sip-77), we check the reward to be inside a properate range
            // which is 2^256 / 10^18
            require(reward < REWARD_OVERFLOW_CHECK, "reward rate will overflow");
            rewardRate = reward.div(rewardDuration);
            lastUpdateTime = startTime;
            periodFinish = startTime.add(rewardDuration);
            emit RewardAdded(reward);
        }
    }

    /**
     * @notice Set new reward duration, will start a new round of reward period immediately and recalculate rewardRate.
     * @param newRewardDuration New duration of each reward period round.
     */
    function _setRewardDuration(uint newRewardDuration) external onlyOwner updateReward(address(0)) {
        uint oldRewardDuration = rewardDuration;
        rewardDuration = newRewardDuration;

        if (block.timestamp > startTime) {
            if (block.timestamp >= periodFinish) {
                rewardRate = 0;
            } else {
                uint remaining = periodFinish.sub(block.timestamp);
                uint leftover = remaining.mul(rewardRate);
                rewardRate = leftover.div(rewardDuration);
            }
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(rewardDuration);
        } else {
            rewardRate = rewardRate.mul(oldRewardDuration).div(rewardDuration);
            lastUpdateTime = startTime;
            periodFinish = startTime.add(rewardDuration);
        }

        emit NewRewardDuration(oldRewardDuration, newRewardDuration);
    }

    /**
     * @notice Set new reward release period. The unclaimed rewards will be affected immediately.
     * @param newRewardReleasePeriod New release period of how long all earned rewards will be matured each time
     * before user claim reward.
     */
    function _setRewardReleasePeriod(uint newRewardReleasePeriod) external onlyOwner updateReward(address(0)) {
        uint oldRewardReleasePeriod = rewardReleasePeriod;
        rewardReleasePeriod = newRewardReleasePeriod;
        emit NewRewardReleasePeriod(oldRewardReleasePeriod, newRewardReleasePeriod);
    }

    function _setCooldownTime(uint newCooldownTime) external onlyOwner {
        uint oldCooldown = burnCooldownTime;
        burnCooldownTime = newCooldownTime;
        emit NewBurnCooldownTime(oldCooldown, newCooldownTime);
    }

    /**
     * @notice Mint KUSD to treasury account to keep on-chain KUSD consist with off-chain trading system
     * @param amount The amount of KUSD to mint to treasury
     */
    function treasuryMint(uint amount) external onlyTreasury {
        kUSD.mint(vault, amount);
        emit TreasuryMint(amount);
    }

    /**
     * @notice Burn KUSD from treasury account to keep on-chain KUSD consist with off-chain trading system
     * @param amount The amount of KUSD to burn from treasury
     */
    function treasuryBurn(uint amount) external onlyTreasury {
        kUSD.burn(vault, amount);
        emit TreasuryBurn(amount);
    }

    /**
     * @notice Change treasury account to a new one
     * @param newTreasury New treasury account address
     */
    function _setTreasury(address newTreasury) external onlyOwner {
        address oldTreasury = treasury;
        treasury = newTreasury;
        emit NewTreasury(oldTreasury, newTreasury);
    }

    /**
     * @notice Change vault account to a new one
     * @param newVault New vault account address
     */
    function _setVault(address newVault) external onlyOwner {
        address oldVault = vault;
        vault = newVault;
        emit NewVault(oldVault, newVault);
    }

    /**
     * @notice Change KMCD contract address to a new one.
     * @param newKMCD New KMCD contract address.
     */
    function _setKMCD(address newKMCD) external onlyOwner {
        address oldKMCD = address(kMCD);
        kMCD = IKMCD(newKMCD);
        emit NewKMCD(oldKMCD, newKMCD);
    }

    /**
     * @notice Change KUSD contract address to a new one.
     * @param newKUSD New KineUSD contract address.
     */
    function _setKUSD(address newKUSD) external onlyOwner {
        address oldKUSD = address(kUSD);
        kUSD = IKineUSD(newKUSD);
        emit NewKUSD(oldKUSD, newKUSD);
    }

    /**
     * @notice Change Kine contract address to a new one.
     * @param newKine New Kine contract address.
     */
    function _setKine(address newKine) external onlyOwner {
        address oldKine = address(kine);
        kine = IERC20(newKine);
        emit NewKine(oldKine, newKine);
    }
    /**
     * @notice Change Kine Controller address to a new one.
     * @param newController New Controller contract address.
     */
    function _setController(address newController) external onlyOwner {
        address oldController = address(controller);
        controller = KineControllerInterface(newController);
        emit NewController(oldController, newController);
    }
}