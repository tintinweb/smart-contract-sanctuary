/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

pragma solidity 0.6.7;

contract GebMath {
    uint256 public constant RAY = 10 ** 27;
    uint256 public constant WAD = 10 ** 18;

    function ray(uint x) public pure returns (uint z) {
        z = multiply(x, 10 ** 9);
    }
    function rad(uint x) public pure returns (uint z) {
        z = multiply(x, 10 ** 27);
    }
    function minimum(uint x, uint y) public pure returns (uint z) {
        z = (x <= y) ? x : y;
    }
    function addition(uint x, uint y) public pure returns (uint z) {
        z = x + y;
        require(z >= x, "uint-uint-add-overflow");
    }
    function subtract(uint x, uint y) public pure returns (uint z) {
        z = x - y;
        require(z <= x, "uint-uint-sub-underflow");
    }
    function multiply(uint x, uint y) public pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "uint-uint-mul-overflow");
    }
    function rmultiply(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, y) / RAY;
    }
    function rdivide(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, RAY) / y;
    }
    function wdivide(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, WAD) / y;
    }
    function wmultiply(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, y) / WAD;
    }
    function rpower(uint x, uint n, uint base) public pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
}

abstract contract StabilityFeeTreasuryLike {
    function getAllowance(address) virtual external view returns (uint, uint);
    function systemCoin() virtual external view returns (address);
    function pullFunds(address, address, uint) virtual external;
    function setTotalAllowance(address, uint256) external virtual;
    function setPerBlockAllowance(address, uint256) external virtual;    
}

contract MandatoryFixedTreasuryReimbursement is GebMath {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "MandatoryFixedTreasuryReimbursement/account-not-authorized");
        _;
    }

    // --- Variables ---
    // The fixed reward sent by the treasury to a fee receiver
    uint256 public fixedReward;               // [wad]
    // SF treasury
    StabilityFeeTreasuryLike public treasury;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(
      bytes32 parameter,
      address addr
    );
    event ModifyParameters(
      bytes32 parameter,
      uint256 val
    );
    event RewardCaller(address indexed finalFeeReceiver, uint256 fixedReward);

    constructor(address treasury_, uint256 fixedReward_) public {
        require(fixedReward_ > 0, "MandatoryFixedTreasuryReimbursement/null-reward");
        require(treasury_ != address(0), "MandatoryFixedTreasuryReimbursement/null-treasury");

        authorizedAccounts[msg.sender] = 1;

        treasury    = StabilityFeeTreasuryLike(treasury_);
        fixedReward = fixedReward_;

        emit AddAuthorization(msg.sender);
        emit ModifyParameters("treasury", treasury_);
        emit ModifyParameters("fixedReward", fixedReward);
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Treasury Utils ---
    /*
    * @notify Return the amount of SF that the treasury can transfer in one transaction when called by this contract
    */
    function treasuryAllowance() public view returns (uint256) {
        (uint total, uint perBlock) = treasury.getAllowance(address(this));
        return minimum(total, perBlock);
    }
    /*
    * @notify Get the actual reward to be sent by taking the minimum between the fixed reward and the amount that can be sent by the treasury
    */
    function getCallerReward() public view returns (uint256 reward) {
        reward = minimum(fixedReward, treasuryAllowance() / RAY);
    }
    /*
    * @notice Send a SF reward to a fee receiver by calling the treasury
    * @param proposedFeeReceiver The address that will receive the reward (unless null in which case msg.sender will receive it)
    */
    function rewardCaller(address proposedFeeReceiver) internal {
        // If the receiver is the treasury itself or if the treasury is null or if the reward is zero, revert
        require(address(treasury) != proposedFeeReceiver, "MandatoryFixedTreasuryReimbursement/reward-receiver-cannot-be-treasury");
        require(both(address(treasury) != address(0), fixedReward > 0), "MandatoryFixedTreasuryReimbursement/invalid-treasury-or-reward");

        // Determine the actual fee receiver and reward them
        address finalFeeReceiver = (proposedFeeReceiver == address(0)) ? msg.sender : proposedFeeReceiver;
        uint256 finalReward      = getCallerReward();
        treasury.pullFunds(finalFeeReceiver, treasury.systemCoin(), finalReward);

        emit RewardCaller(finalFeeReceiver, finalReward);
    }
}

abstract contract AccountingEngineLike {
    function debtPoppers(uint256) virtual public view returns (address);
}

contract DebtPopperRewards is MandatoryFixedTreasuryReimbursement {
    // --- Variables ---
    // When the next reward period starts
    uint256 public rewardPeriodStart;                    // [unix timestamp]
    // Delay between two consecutive reward periods
    uint256 public interPeriodDelay;                     // [seconds]
    // Time (after a block of debt is popped) after which no reward can be given anymore
    uint256 public rewardTimeline;                       // [seconds]
    // Amount of pops that can be rewarded per period
    uint256 public maxPerPeriodPops;
    // Timestamp from which the contract accepts requests for rewarding debt poppers
    uint256 public rewardStartTime;

    // Whether a debt block has been popped
    mapping(uint256 => bool)    public rewardedPop;      // [unix timestamp => bool]
    // Amount of pops that were rewarded in each period
    mapping(uint256 => uint256) public rewardsPerPeriod; // [unix timestamp => wad]

    // Accounting engine contract
    AccountingEngineLike        public accountingEngine;

    // --- Events ---
    event SetRewardPeriodStart(uint256 rewardPeriodStart);
    event RewardForPop(uint256 slotTimestamp, uint256 reward);

    constructor(
        address accountingEngine_,
        address treasury_,
        uint256 rewardPeriodStart_,
        uint256 interPeriodDelay_,
        uint256 rewardTimeline_,
        uint256 fixedReward_,
        uint256 maxPerPeriodPops_,
        uint256 rewardStartTime_
    ) public MandatoryFixedTreasuryReimbursement(treasury_, fixedReward_) {
        require(rewardPeriodStart_ >= now, "DebtPopperRewards/invalid-reward-period-start");
        require(interPeriodDelay_ > 0, "DebtPopperRewards/invalid-inter-period-delay");
        require(rewardTimeline_ > 0, "DebtPopperRewards/invalid-harvest-timeline");
        require(maxPerPeriodPops_ > 0, "DebtPopperRewards/invalid-max-per-period-pops");
        require(accountingEngine_ != address(0), "DebtPopperRewards/null-accounting-engine");

        accountingEngine   = AccountingEngineLike(accountingEngine_);

        rewardPeriodStart  = rewardPeriodStart_;
        interPeriodDelay   = interPeriodDelay_;
        rewardTimeline     = rewardTimeline_;
        fixedReward        = fixedReward_;
        maxPerPeriodPops   = maxPerPeriodPops_;
        rewardStartTime    = rewardStartTime_;

        emit ModifyParameters("accountingEngine", accountingEngine_);
        emit ModifyParameters("interPeriodDelay", interPeriodDelay);
        emit ModifyParameters("rewardTimeline", rewardTimeline);
        emit ModifyParameters("rewardStartTime", rewardStartTime);
        emit ModifyParameters("maxPerPeriodPops", maxPerPeriodPops);

        emit SetRewardPeriodStart(rewardPeriodStart);
    }

    // --- Administration ---
    /*
    * @notify Modify a uint256 parameter
    * @param parameter The parameter name
    * @param val The new value for the parameter
    */
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        require(val > 0, "DebtPopperRewards/invalid-value");
        if (parameter == "interPeriodDelay") {
          interPeriodDelay = val;
        }
        else if (parameter == "rewardTimeline") {
          rewardTimeline = val;
        }
        else if (parameter == "fixedReward") {
          require(val > 0, "DebtPopperRewards/null-reward");
          fixedReward = val;
        }
        else if (parameter == "maxPerPeriodPops") {
          maxPerPeriodPops = val;
        }
        else if (parameter == "rewardPeriodStart") {
          require(val > now, "DebtPopperRewards/invalid-reward-period-start");
          rewardPeriodStart = val;
        }
        else revert("DebtPopperRewards/modify-unrecognized-param");
        emit ModifyParameters(parameter, val);
    }
    /*
    * @notify Set a new treasury address
    * @param parameter The parameter name
    * @param addr The new address for the parameter
    */
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        require(addr != address(0), "DebtPopperRewards/null-address");
        if (parameter == "treasury") treasury = StabilityFeeTreasuryLike(addr);
        else revert("DebtPopperRewards/modify-unrecognized-param");
        emit ModifyParameters(parameter, addr);
    }

    /*
    * @notify Get rewarded for popping a debt slot from the AccountingEngine debt queue
    * @oaran slotTimestamp The time of the popped slot
    * @param feeReceiver The address that will receive the reward for popping
    */
    function getRewardForPop(uint256 slotTimestamp, address feeReceiver) external {
        // Perform checks
        require(slotTimestamp >= rewardStartTime, "DebtPopperRewards/slot-time-before-reward-start");
        require(slotTimestamp < now, "DebtPopperRewards/slot-cannot-be-in-the-future");
        require(now >= rewardPeriodStart, "DebtPopperRewards/wait-more");
        require(addition(slotTimestamp, rewardTimeline) >= now, "DebtPopperRewards/missed-reward-window");
        require(accountingEngine.debtPoppers(slotTimestamp) == msg.sender, "DebtPopperRewards/not-debt-popper");
        require(!rewardedPop[slotTimestamp], "DebtPopperRewards/pop-already-rewarded");
        require(getCallerReward() >= fixedReward, "DebtPopperRewards/invalid-available-reward");

        // Update state
        rewardedPop[slotTimestamp]          = true;
        rewardsPerPeriod[rewardPeriodStart] = addition(rewardsPerPeriod[rewardPeriodStart], 1);

        // If we offered rewards for too many pops, enforce a delay since rewards are available again
        if (rewardsPerPeriod[rewardPeriodStart] >= maxPerPeriodPops) {
          rewardPeriodStart = addition(now, interPeriodDelay);
          emit SetRewardPeriodStart(rewardPeriodStart);
        }

        emit RewardForPop(slotTimestamp, fixedReward);

        // Give the reward
        rewardCaller(feeReceiver);
    }
}

contract DeployDebtPopperRewards {
    // --- Variables ---
    uint256 public constant WAD = 10**18;
    uint256 public constant RAY = 10**27;
    uint256 public constant RAD = 10**45;

    function execute(
        address _accountingEngine,
        address _treasury
    ) public returns (address) {
        // Define params
        uint256 rewardPeriodStart = now;
        uint256 interPeriodDelay = 1209600;
        uint256 rewardTimeline = 4838400;
        uint256 fixedReward = 5 * WAD;
        uint256 maxPerPeriodPops = 10;
        uint256 rewardStartTime = now;

        // deploy the throttler
        DebtPopperRewards popperRewards = new DebtPopperRewards(
            _accountingEngine,
            _treasury,
            rewardPeriodStart,
            interPeriodDelay,
            rewardTimeline,
            fixedReward,
            maxPerPeriodPops,
            rewardStartTime

        );

        // setting allowances in the SF treasury
        StabilityFeeTreasuryLike(_treasury).setPerBlockAllowance(address(popperRewards), 1 * RAD);
        StabilityFeeTreasuryLike(_treasury).setTotalAllowance(address(popperRewards), uint(-1));

        return address(popperRewards);
    }
}