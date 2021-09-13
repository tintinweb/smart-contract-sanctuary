/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: contracts/Liti/farming.sol


pragma solidity 0.8.4;


/// @title Liti Capital Staking contract
/// @author Jaime Delgado
/// @notice no token locking required, uses power law to incentivate staking to the end of the periods
/// @dev All function calls are currently implemented without side effects
contract Staking {
    struct Campaign {
        uint256 funds;
        uint256 endDate;
    }
    struct StakeInfo {
        uint256 amount;
        uint64 startDate;
        uint64 endDate;
        uint64 rate;
        uint64 coeff;
    }

    uint256 constant TT = 365 * 24 * 60 * 60;
    address public tokenAddress;
    uint256 constant RATE_DECIMALS = 3;
    uint256[3] public currentRate;
    uint256[3] public powLawCoeff;
    uint256[3] public periods = [30 days, 60 days, 90 days];
    uint256 public maxStaking;
    address public owner;
    Campaign public campaignInfo;

    mapping(address => uint256) private stakeId;
    mapping(address => mapping(uint256 => StakeInfo)) private stakes;
    mapping(address => uint256) private balances;

    // Events --------------------------------------------------------------------------

    ///@dev Emitted when a new campaign is created.
    event NewCampaign(uint256 funds, uint256 endDate);

    ///@dev Emitted when a campaign funds are increased or extended the time.
    event CampaignEdited(uint256 addedFunds, uint256 newEndDate);

    ///@dev Emitted when the reward funds are removed.
    event RewardFundsRemoved(uint256 amount);

    ///@dev Emitted when the rate, powerlaw coeff and maxStaking params are modified.
    event ParamsChanged(
        uint256[3] oldRates,
        uint256[3] newRates,
        uint256[3] oldCoeffs,
        uint256[3] newCoeffs,
        uint256 maxStaking
    );

    ///@dev Emitted when a new stake is created.
    event Staked(
        address indexed account,
        uint256 amount,
        uint256 startDate,
        uint256 endDate,
        uint256 rate,
        uint256 powLawCoeff,
        uint256 stakeId
    );

    ///@dev Emitted when an stake is removed.
    event UnStaked(
        address indexed account,
        uint256 amount,
        uint256 reward,
        uint256 stakeId
    );

    // Constructor ---------------------------------------------------------------------
    constructor(address _tokenAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
    }

    // Modifiers -----------------------------------------------------------------------
    modifier onlyAdmin() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    // Getters -------------------------------------------------------------------------
    /// @notice getter for stake information
    /// @param account is the account that created the stake
    /// @param userStakeId is the id generated for the stake
    /// @return struct with stake information
    function getStake(address account, uint256 userStakeId)
        public
        view
        returns (StakeInfo memory)
    {
        return stakes[account][userStakeId];
    }

    /// @notice getter for reward and staked amount
    /// @param account is the account that created the stake
    /// @param userStakeId is the id generated for the stake
    /// @return amount staked, reward at the current timestamp and maxReward
    function getStackAndReward(address account, uint256 userStakeId)
        public
        view
        returns (
            uint256 amount,
            uint256 reward,
            uint256 maxReward
        )
    {
        amount = stakes[account][userStakeId].amount;
        uint256 startDate = stakes[account][userStakeId].startDate;
        uint256 endDate = stakes[account][userStakeId].endDate;
        uint256 rate = stakes[account][userStakeId].rate;
        uint256 coeff = stakes[account][userStakeId].coeff;
        uint256 fd = endDate <= block.timestamp ? endDate : block.timestamp;
        uint256 tp = endDate - startDate;
        uint256 dt = fd - startDate;
        reward =
            (rate * amount * (dt**(coeff + 1))) /
            (TT * (tp**coeff) * (10**RATE_DECIMALS));
        maxReward = (amount * rate * tp) / (TT * (10**RATE_DECIMALS));
    }

    /// @notice getter for maxReward
    /// @param amount amount staked
    /// @param rate interest rate for this stake
    /// @param tp staking period in seconds
    /// @return maxReward
    function getMaxReward(
        uint256 amount,
        uint256 rate,
        uint256 tp
    ) public pure returns (uint256 maxReward) {
        maxReward = (amount * rate * tp) / (TT * (10**RATE_DECIMALS));
    }

    // Setters -------------------------------------------------------------------------
    /// @notice assign funds and endDate for a staking campaign
    /// @param funds for rewards
    /// @param endDate date after which no more stakings will accepted
    function newCampaign(uint256 funds, uint256 endDate) public onlyAdmin {
        require(campaignInfo.endDate < block.timestamp, "Campaign Active");
        IERC20 wliti = IERC20(tokenAddress);
        require(
            wliti.transferFrom(msg.sender, address(this), funds),
            "trasfer failed"
        );
        campaignInfo.funds = campaignInfo.funds + funds;
        campaignInfo.endDate = endDate;
        emit NewCampaign(funds, endDate);
    }

    /// @notice increase funds and/or extend campaign
    /// @param funds for rewards
    /// @param endDate date after which no more stakings will accepted
    function editCampaign(uint256 funds, uint256 endDate) public onlyAdmin {
        require(campaignInfo.endDate > block.timestamp, "Campaign inactive");
        require(endDate >= campaignInfo.endDate, "Campaign can't be shortened");
        campaignInfo.endDate = endDate;
        if (funds != 0) {
            IERC20 wliti = IERC20(tokenAddress);
            require(
                wliti.transferFrom(msg.sender, address(this), funds),
                "transfer failed"
            );
            campaignInfo.funds = campaignInfo.funds + funds;
        }
        emit CampaignEdited(funds, endDate);
    }

    /// @notice withdraw funds not commited
    /// @dev only after 3 months of the end of the campaign
    function removeRewardFunds() public onlyAdmin {
        require(
            campaignInfo.endDate + (90 days) < block.timestamp,
            "Campaign Active"
        );
        IERC20 wliti = IERC20(tokenAddress);
        require(wliti.transfer(owner, campaignInfo.funds), "transfer failed");
        emit RewardFundsRemoved(campaignInfo.funds);
        campaignInfo.funds = 0;
    }

    /// @notice change parameters of campaign
    /// @param rates interest rates for the three periods
    /// @param coeffs power law coefficients for each period
    /// @param maxStaking_ max staked per address
    function setNewParams(
        uint256[3] memory rates,
        uint256[3] memory coeffs,
        uint256 maxStaking_
    ) public onlyAdmin {
        emit ParamsChanged(
            currentRate,
            rates,
            powLawCoeff,
            coeffs,
            maxStaking_
        );
        currentRate = rates;
        powLawCoeff = coeffs;
        maxStaking = maxStaking_;
    }

    /// @notice create new stake
    /// @param amount amount staked
    /// @param periodIndex index for one of the three periods
    /// @return userStakeId
    function stake(uint256 amount, uint256 periodIndex)
        public
        returns (uint256)
    {
        uint256 userStakeId = stakeFor(msg.sender, amount, periodIndex);
        return userStakeId;
    }

    /// @notice create new stake for an account other than msg.sender
    /// @param account account that will own the stake
    /// @param amount amount staked
    /// @param periodIndex index for one of the three periods
    /// @return userStakeId
    function stakeFor(
        address account,
        uint256 amount,
        uint256 periodIndex
    ) public returns (uint256) {
        require(account != address(0), "Invalid address passed");
        require(balances[account] + amount <= maxStaking, "Max exceeded");
        require(campaignInfo.endDate > block.timestamp, "Campaign ended");
        require(periodIndex <= 2, "Invalid period ID");
        require(amount != 0, "Staking zero token");

        uint256 maxReward = getMaxReward(
            amount,
            currentRate[periodIndex],
            periods[periodIndex]
        );
        require(
            campaignInfo.funds >= maxReward,
            "Not enough funds in the contract"
        );

        campaignInfo.funds = campaignInfo.funds - maxReward;
        balances[account] = balances[account] + amount;

        IERC20 wliti = IERC20(tokenAddress);
        require(
            wliti.transferFrom(msg.sender, address(this), amount),
            "transfer failed"
        );

        uint256 userStakeId = stakeId[account];
        stakes[account][userStakeId] = StakeInfo(
            amount,
            uint64(block.timestamp),
            uint64(block.timestamp + periods[periodIndex]),
            uint64(currentRate[periodIndex]),
            uint64(powLawCoeff[periodIndex])
        );

        emit Staked(
            msg.sender,
            amount,
            block.timestamp,
            block.timestamp + periods[periodIndex],
            currentRate[periodIndex],
            powLawCoeff[periodIndex],
            userStakeId
        );
        stakeId[account] = userStakeId + 1;
        return userStakeId;
    }

    /// @notice unstake and create new stake of amount plus reward
    /// @param userStakeId_ stake to unstake
    /// @param periodIndex index for one of the three periods
    /// @return userStakeId id of the new stake
    function reStake(uint256 userStakeId_, uint256 periodIndex)
        public
        returns (uint256)
    {
        require(campaignInfo.endDate > block.timestamp, "Campaign ended");
        require(periodIndex <= 2, "Invalid period ID");

        (uint256 amount, uint256 reward, uint256 maxReward) = getStackAndReward(
            msg.sender,
            userStakeId_
        );
        require(amount != 0, "Invalid stake ID");
        campaignInfo.funds = campaignInfo.funds + (maxReward - reward);
        emit UnStaked(msg.sender, amount, reward, userStakeId_);

        amount = amount + reward;
        maxReward = getMaxReward(
            amount,
            currentRate[periodIndex],
            periods[periodIndex]
        );

        require(balances[msg.sender] + amount <= maxStaking, "Max exceeded");
        require(
            campaignInfo.funds >= maxReward,
            "Not enough funds in the contract"
        );
        campaignInfo.funds = campaignInfo.funds - maxReward;
        balances[msg.sender] = balances[msg.sender] + reward; // only the reward is newly added to the staked amount

        uint256 userStakeId = stakeId[msg.sender];
        stakes[msg.sender][userStakeId] = StakeInfo(
            amount,
            uint64(block.timestamp),
            uint64(block.timestamp + periods[periodIndex]),
            uint64(currentRate[periodIndex]),
            uint64(powLawCoeff[periodIndex])
        );

        emit Staked(
            msg.sender,
            amount,
            block.timestamp,
            block.timestamp + periods[periodIndex],
            currentRate[periodIndex],
            powLawCoeff[periodIndex],
            userStakeId
        );
        delete stakes[msg.sender][userStakeId_];
        stakeId[msg.sender] = userStakeId + 1;

        return userStakeId;
    }

    /// @notice unstake
    /// @param userStakeId stake to unstake
    function unstake(uint256 userStakeId) public {
        (uint256 amount, uint256 reward, uint256 maxReward) = getStackAndReward(
            msg.sender,
            userStakeId
        );
        require(amount != 0, "Invalid stake ID");
        IERC20 wliti = IERC20(tokenAddress);
        require(wliti.transfer(msg.sender, amount + reward), "transfer failed");
        delete stakes[msg.sender][userStakeId];
        campaignInfo.funds = campaignInfo.funds + (maxReward - reward);
        balances[msg.sender] = balances[msg.sender] - amount;
        emit UnStaked(msg.sender, amount, reward, userStakeId);
    }

    /// @notice unstake
    /// @param userStakeId array of stakeIds
    function unstakeMany(uint256[] memory userStakeId) public {
        require(userStakeId.length <= 10, "Number of un-stakes limted to 10");
        uint256 totalAmount;
        uint256 totalReward;
        uint256 totalMaxReward;
        for (uint256 i = 0; i < userStakeId.length; i++) {
            uint256 ind = userStakeId[i];
            (
                uint256 amount,
                uint256 reward,
                uint256 maxReward
            ) = getStackAndReward(msg.sender, ind);
            if (amount == 0) continue;
            totalAmount = totalAmount + amount;
            totalReward = totalReward + reward;
            totalMaxReward = totalMaxReward + maxReward;
            delete stakes[msg.sender][ind];
            emit UnStaked(msg.sender, amount, reward, ind);
        }
        campaignInfo.funds =
            campaignInfo.funds -
            (totalMaxReward - totalReward);
        balances[msg.sender] = balances[msg.sender] - totalAmount;
        IERC20 wliti = IERC20(tokenAddress);
        require(
            wliti.transfer(msg.sender, totalAmount + totalReward),
            "transfer failed"
        );
    }
}