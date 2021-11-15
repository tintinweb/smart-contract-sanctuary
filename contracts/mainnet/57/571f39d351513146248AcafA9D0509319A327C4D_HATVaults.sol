// SPDX-License-Identifier: MIT
// Disclaimer https://github.com/hats-finance/hats-contracts/blob/main/DISCLAIMER.md

pragma solidity 0.8.6;
import "./interfaces/ISwapRouter.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./HATMaster.sol";
import "./tokenlock/ITokenLockFactory.sol";
import "./Governable.sol";


contract  HATVaults is Governable, HATMaster {
    using SafeMath  for uint256;
    using SafeERC20 for IERC20;

    struct PendingApproval {
        address beneficiary;
        uint256 severity;
        address approver;
    }

    struct ClaimReward {
        uint256 hackerVestedReward;
        uint256 hackerReward;
        uint256 committeeReward;
        uint256 swapAndBurn;
        uint256 governanceHatReward;
        uint256 hackerHatReward;
    }

    struct PendingRewardsLevels {
        uint256 timestamp;
        uint256[] rewardsLevels;
    }

    struct GeneralParameters {
        uint256 hatVestingDuration;
        uint256 hatVestingPeriods;
        uint256 withdrawPeriod;
        uint256 safetyPeriod; //withdraw disable period in seconds
        uint256 setRewardsLevelsDelay;
        uint256 withdrawRequestEnablePeriod;
        uint256 withdrawRequestPendingPeriod;
        uint256 claimFee;  //claim fee in ETH
    }

    //pid -> committee address
    mapping(uint256=>address) public committees;
    mapping(address => uint256) public swapAndBurns;
    //hackerAddress ->(token->amount)
    mapping(address => mapping(address => uint256)) public hackersHatRewards;
    //token -> amount
    mapping(address => uint256) public governanceHatRewards;
    //pid -> PendingApproval
    mapping(uint256 => PendingApproval) public pendingApprovals;
    //poolId -> (address -> requestTime)
    mapping(uint256 => mapping(address => uint256)) public withdrawRequests;
    //poolId -> PendingRewardsLevels
    mapping(uint256 => PendingRewardsLevels) public pendingRewardsLevels;

    mapping(uint256 => bool) public poolDepositPause;

    GeneralParameters public generalParameters;

    uint256 internal constant REWARDS_LEVEL_DENOMINATOR = 10000;
    ITokenLockFactory public immutable tokenLockFactory;
    ISwapRouter public immutable uniSwapRouter;
    uint256 public constant MINIMUM_DEPOSIT = 1e6;

    modifier onlyCommittee(uint256 _pid) {
        require(committees[_pid] == msg.sender, "only committee");
        _;
    }

    modifier noPendingApproval(uint256 _pid) {
        require(pendingApprovals[_pid].beneficiary == address(0), "pending approval exist");
        _;
    }

    modifier noSafetyPeriod() {
      //disable withdraw for safetyPeriod (e.g 1 hour) each withdrawPeriod(e.g 11 hours)
      // solhint-disable-next-line not-rely-on-time
        require(block.timestamp % (generalParameters.withdrawPeriod + generalParameters.safetyPeriod) <
        generalParameters.withdrawPeriod,
        "safety period");
        _;
    }

    event SetCommittee(uint256 indexed _pid, address indexed _committee);

    event AddPool(uint256 indexed _pid,
                uint256 indexed _allocPoint,
                address indexed _lpToken,
                address _committee,
                string _descriptionHash,
                uint256[] _rewardsLevels,
                RewardsSplit _rewardsSplit,
                uint256 _rewardVestingDuration,
                uint256 _rewardVestingPeriods);

    event SetPool(uint256 indexed _pid, uint256 indexed _allocPoint, bool indexed _registered, string _descriptionHash);
    event Claim(address indexed _claimer, string _descriptionHash);
    event SetRewardsSplit(uint256 indexed _pid, RewardsSplit _rewardsSplit);
    event SetRewardsLevels(uint256 indexed _pid, uint256[] _rewardsLevels);
    event PendingRewardsLevelsLog(uint256 indexed _pid, uint256[] _rewardsLevels, uint256 _timeStamp);

    event SwapAndSend(uint256 indexed _pid,
                    address indexed _beneficiary,
                    uint256 indexed _amountSwaped,
                    uint256 _amountReceived,
                    address _tokenLock);

    event SwapAndBurn(uint256 indexed _pid, uint256 indexed _amountSwaped, uint256 indexed _amountBurned);
    event SetVestingParams(uint256 indexed _pid, uint256 indexed _duration, uint256 indexed _periods);
    event SetHatVestingParams(uint256 indexed _duration, uint256 indexed _periods);

    event ClaimApprove(address indexed _approver,
                    uint256 indexed _pid,
                    address indexed _beneficiary,
                    uint256 _severity,
                    address _tokenLock,
                    ClaimReward _claimReward);

    event PendingApprovalLog(uint256 indexed _pid,
                            address indexed _beneficiary,
                            uint256 indexed _severity,
                            address _approver);

    event WithdrawRequest(uint256 indexed _pid,
                        address indexed _beneficiary,
                        uint256 indexed _withdrawEnableTime);

    event SetWithdrawSafetyPeriod(uint256 indexed _withdrawPeriod, uint256 indexed _safetyPeriod);

    event RewardDepositors(uint256 indexed _pid, uint256 indexed _amount);

    /**
   * @dev constructor -
   * @param _rewardsToken the reward token address (HAT)
   * @param _rewardPerBlock the reward amount per block the contract will reward pools
   * @param _startBlock start block of of which the contract will start rewarding from.
   * @param _multiplierPeriod a fix period value. each period will have its own multiplier value.
   *        which set the reward for each period. e.g a value of 100000 means that each such period is 100000 blocks.
   * @param _hatGovernance the governance address.
   *        Some of the contracts functions are limited only to governance :
   *         addPool,setPool,dismissPendingApprovalClaim,approveClaim,
   *         setHatVestingParams,setVestingParams,setRewardsSplit
   * @param _uniSwapRouter uni swap v3 router to be used to swap tokens for HAT token.
   * @param _tokenLockFactory address of the token lock factory to be used
   *        to create a vesting contract for the approved claim reporter.
 */
    constructor(
        address _rewardsToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _multiplierPeriod,
        address _hatGovernance,
        ISwapRouter _uniSwapRouter,
        ITokenLockFactory _tokenLockFactory
    // solhint-disable-next-line func-visibility
    ) HATMaster(HATToken(_rewardsToken), _rewardPerBlock, _startBlock, _multiplierPeriod) {
        Governable.initialize(_hatGovernance);
        uniSwapRouter = _uniSwapRouter;
        tokenLockFactory = _tokenLockFactory;
        generalParameters = GeneralParameters({
            hatVestingDuration: 90 days,
            hatVestingPeriods:90,
            withdrawPeriod: 11 hours,
            safetyPeriod: 1 hours,
            setRewardsLevelsDelay: 2 days,
            withdrawRequestEnablePeriod: 7 days,
            withdrawRequestPendingPeriod: 7 days,
            claimFee: 0
        });
    }

      /**
     * @dev pendingApprovalClaim - called by a committee to set a pending approval claim.
     * The pending approval need to be approved or dismissed  by the hats governance.
     * This function should be called only on a safety period, where withdrawn is disable.
     * Upon a call to this function by the committee the pool withdrawn will be disable
     * till governance will approve or dismiss this pending approval.
     * @param _pid pool id
     * @param _beneficiary the approval claim beneficiary
     * @param _severity approval claim severity
   */
    function pendingApprovalClaim(uint256 _pid, address _beneficiary, uint256 _severity)
    external
    onlyCommittee(_pid)
    noPendingApproval(_pid) {
        require(_beneficiary != address(0), "beneficiary is zero");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp % (generalParameters.withdrawPeriod + generalParameters.safetyPeriod) >=
        generalParameters.withdrawPeriod,
        "none safety period");
        require(_severity < poolsRewards[_pid].rewardsLevels.length, "_severity is not in the range");

        pendingApprovals[_pid] = PendingApproval({
            beneficiary: _beneficiary,
            severity: _severity,
            approver: msg.sender
        });
        emit PendingApprovalLog(_pid, _beneficiary, _severity, msg.sender);
    }

    /**
     * @dev setWithdrawRequestParams - called by hats governance to set withdraw request params
     * @param _withdrawRequestPendingPeriod - the time period where the withdraw request is pending.
     * @param _withdrawRequestEnablePeriod - the time period where the withdraw is enable for a withdraw request.
    */
    function setWithdrawRequestParams(uint256 _withdrawRequestPendingPeriod, uint256  _withdrawRequestEnablePeriod)
    external
    onlyGovernance {
        generalParameters.withdrawRequestPendingPeriod = _withdrawRequestPendingPeriod;
        generalParameters.withdrawRequestEnablePeriod = _withdrawRequestEnablePeriod;
    }

  /**
   * @dev dismissPendingApprovalClaim - called by hats governance to dismiss a pending approval claim.
   * @param _pid pool id
  */
    function dismissPendingApprovalClaim(uint256 _pid) external onlyGovernance {
        delete pendingApprovals[_pid];
    }

    /**
   * @dev approveClaim - called by hats governance to approve a pending approval claim.
   * @param _pid pool id
 */
    function approveClaim(uint256 _pid) external onlyGovernance nonReentrant {
        require(pendingApprovals[_pid].beneficiary != address(0), "no pending approval");
        PoolReward storage poolReward = poolsRewards[_pid];
        PendingApproval memory pendingApproval = pendingApprovals[_pid];
        delete pendingApprovals[_pid];

        IERC20 lpToken = poolInfo[_pid].lpToken;
        ClaimReward memory claimRewards = calcClaimRewards(_pid, pendingApproval.severity);
        poolInfo[_pid].balance = poolInfo[_pid].balance.sub(
                            claimRewards.hackerReward
                            .add(claimRewards.hackerVestedReward)
                            .add(claimRewards.committeeReward)
                            .add(claimRewards.swapAndBurn)
                            .add(claimRewards.hackerHatReward)
                            .add(claimRewards.governanceHatReward));
        address tokenLock;
        if (claimRewards.hackerVestedReward > 0) {
        //hacker get its reward to a vesting contract
            tokenLock = tokenLockFactory.createTokenLock(
            address(lpToken),
            0x000000000000000000000000000000000000dEaD, //this address as owner, so it can do nothing.
            pendingApproval.beneficiary,
            claimRewards.hackerVestedReward,
            // solhint-disable-next-line not-rely-on-time
            block.timestamp, //start
            // solhint-disable-next-line not-rely-on-time
            block.timestamp + poolReward.vestingDuration, //end
            poolReward.vestingPeriods,
            0, //no release start
            0, //no cliff
            ITokenLock.Revocability.Disabled,
            false
        );
            lpToken.safeTransfer(tokenLock, claimRewards.hackerVestedReward);
        }
        lpToken.safeTransfer(pendingApproval.beneficiary, claimRewards.hackerReward);
        lpToken.safeTransfer(pendingApproval.approver, claimRewards.committeeReward);
        //storing the amount of token which can be swap and burned so it could be swapAndBurn in a seperate tx.
        swapAndBurns[address(lpToken)] = swapAndBurns[address(lpToken)].add(claimRewards.swapAndBurn);
        governanceHatRewards[address(lpToken)] =
        governanceHatRewards[address(lpToken)].add(claimRewards.governanceHatReward);
        hackersHatRewards[pendingApproval.beneficiary][address(lpToken)] =
        hackersHatRewards[pendingApproval.beneficiary][address(lpToken)].add(claimRewards.hackerHatReward);

        emit ClaimApprove(msg.sender,
                        _pid,
                        pendingApproval.beneficiary,
                        pendingApproval.severity,
                        tokenLock,
                        claimRewards);
        assert(poolInfo[_pid].balance > 0);
    }

    /**
     * @dev rewardDepositors - add funds to pool to reward depositors.
     * The funds will be given to depositors pro rata upon withdraw
     * @param _pid pool id
     * @param _amount amount to add
    */
    function rewardDepositors(uint256 _pid, uint256 _amount) external {
        require(poolInfo[_pid].balance.add(_amount).div(MINIMUM_DEPOSIT) < poolInfo[_pid].totalUsersAmount,
        "amount to reward is too big");
        poolInfo[_pid].lpToken.safeTransferFrom(msg.sender, address(this), _amount);
        poolInfo[_pid].balance = poolInfo[_pid].balance.add(_amount);
        emit RewardDepositors(_pid, _amount);
    }

    /**
     * @dev setClaimFee - called by hats governance to set claim fee
     * @param _fee claim fee in ETH
    */
    function setClaimFee(uint256 _fee) external onlyGovernance {
        generalParameters.claimFee = _fee;
    }

    /**
     * @dev setWithdrawSafetyPeriod - called by hats governance to set Withdraw Period
     * @param _withdrawPeriod withdraw enable period
     * @param _safetyPeriod withdraw disable period
    */
    function setWithdrawSafetyPeriod(uint256 _withdrawPeriod, uint256 _safetyPeriod) external onlyGovernance {
        generalParameters.withdrawPeriod = _withdrawPeriod;
        generalParameters.safetyPeriod = _safetyPeriod;
        emit SetWithdrawSafetyPeriod(generalParameters.withdrawPeriod, generalParameters.safetyPeriod);
    }

    //_descriptionHash - a hash of an ipfs encrypted file which describe the claim.
    // this can be use later on by the claimer to prove her claim
    function claim(string memory _descriptionHash) external payable {
        if (generalParameters.claimFee > 0) {
            require(msg.value >= generalParameters.claimFee, "not enough fee payed");
            // solhint-disable-next-line indent
            payable(governance()).transfer(msg.value);
        }
        emit Claim(msg.sender, _descriptionHash);
    }

    /**
   * @dev setVestingParams - set pool vesting params for rewarding claim reporter with the pool token
   * @param _pid pool id
   * @param _duration duration of the vesting period
   * @param _periods the vesting periods
 */
    function setVestingParams(uint256 _pid, uint256 _duration, uint256 _periods) external onlyGovernance {
        require(_duration < 120 days, "vesting duration is too long");
        require(_periods > 0, "vesting periods cannot be zero");
        require(_duration >= _periods, "vesting duration smaller than periods");
        poolsRewards[_pid].vestingDuration = _duration;
        poolsRewards[_pid].vestingPeriods = _periods;
        emit SetVestingParams(_pid, _duration, _periods);
    }

    /**
   * @dev setHatVestingParams - set HAT vesting params for rewarding claim reporter with HAT token
   * the function can be called only by governance.
   * @param _duration duration of the vesting period
   * @param _periods the vesting periods
 */
    function setHatVestingParams(uint256 _duration, uint256 _periods) external onlyGovernance {
        require(_duration < 180 days, "vesting duration is too long");
        require(_periods > 0, "vesting periods cannot be zero");
        require(_duration >= _periods, "vesting duration smaller than periods");
        generalParameters.hatVestingDuration = _duration;
        generalParameters.hatVestingPeriods = _periods;
        emit SetHatVestingParams(_duration, _periods);
    }

    /**
   * @dev setRewardsSplit - set the pool token rewards split upon an approval
   * the function can be called only by governance.
   * the sum of the rewards split should be less than 10000 (less than 100%)
   * @param _pid pool id
   * @param _rewardsSplit split
   * and sent to the hacker(claim reported)
 */
    function setRewardsSplit(uint256 _pid, RewardsSplit memory _rewardsSplit)
    external
    onlyGovernance noPendingApproval(_pid) noSafetyPeriod {
        validateSplit(_rewardsSplit);
        poolsRewards[_pid].rewardsSplit = _rewardsSplit;
        emit SetRewardsSplit(_pid, _rewardsSplit);
    }

    /**
   * @dev setRewardsLevelsDelay - set the timelock delay for setting rewars level
   * @param _delay time delay
 */
    function setRewardsLevelsDelay(uint256 _delay)
    external
    onlyGovernance {
        require(_delay >= 2 days, "delay is too short");
        generalParameters.setRewardsLevelsDelay = _delay;
    }

    /**
   * @dev setPendingRewardsLevels - set pending request to set pool token rewards level.
   * the reward level represent the percentage of the pool's token which will be split as a reward.
   * the function can be called only by the pool committee.
   * cannot be called if there already pending approval.
   * each level should be less than 10000
   * @param _pid pool id
   * @param _rewardsLevels the reward levels array
 */
    function setPendingRewardsLevels(uint256 _pid, uint256[] memory _rewardsLevels)
    external
    onlyCommittee(_pid) noPendingApproval(_pid) {
        pendingRewardsLevels[_pid].rewardsLevels = checkRewardsLevels(_rewardsLevels);
        // solhint-disable-next-line not-rely-on-time
        pendingRewardsLevels[_pid].timestamp = block.timestamp;
        emit PendingRewardsLevelsLog(_pid, _rewardsLevels, pendingRewardsLevels[_pid].timestamp);
    }

  /**
   * @dev setRewardsLevels - set the pool token rewards level of already pending set rewards level.
   * see pendingRewardsLevels
   * the reward level represent the percentage of the pool's token which will be split as a reward.
   * the function can be called only by the pool committee.
   * cannot be called if there already pending approval.
   * each level should be less than 10000
   * @param _pid pool id
 */
    function setRewardsLevels(uint256 _pid)
    external
    onlyCommittee(_pid) noPendingApproval(_pid) {
        require(pendingRewardsLevels[_pid].timestamp > 0, "no pending set rewards levels");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp - pendingRewardsLevels[_pid].timestamp > generalParameters.setRewardsLevelsDelay,
        "cannot confirm setRewardsLevels at this time");
        poolsRewards[_pid].rewardsLevels = pendingRewardsLevels[_pid].rewardsLevels;
        delete pendingRewardsLevels[_pid];
        emit SetRewardsLevels(_pid, poolsRewards[_pid].rewardsLevels);
    }

    /**
   * @dev committeeCheckIn - committee check in.
   * deposit is enable only after committee check in
   * @param _pid pool id
 */
    function committeeCheckIn(uint256 _pid) external onlyCommittee(_pid) {
        poolsRewards[_pid].committeeCheckIn = true;
    }


    /**
   * @dev setCommittee - set new committee address.
   * @param _pid pool id
   * @param _committee new committee address
 */
    function setCommittee(uint256 _pid, address _committee)
    external {
        require(_committee != address(0), "committee is zero");
        //governance can update committee only if committee was not checked in yet.
        if (msg.sender == governance() && committees[_pid] != msg.sender) {
            require(!poolsRewards[_pid].committeeCheckIn, "Committee already checked in");
        } else {
            require(committees[_pid] == msg.sender, "Only committee");
        }

        committees[_pid] = _committee;

        emit SetCommittee(_pid, _committee);
    }

    /**
   * @dev addPool - only Governance
   * @param _allocPoint the pool allocation point
   * @param _lpToken pool token
   * @param _committee pool committee address
   * @param _rewardsLevels pool reward levels(sevirities)
     each level is a number between 0 and 10000.
   * @param _rewardsSplit pool reward split.
     each entry is a number between 0 and 10000.
     total splits should be equal to 10000
   * @param _descriptionHash the hash of the pool description.
   * @param _rewardVestingParams vesting params
   *        _rewardVestingParams[0] - vesting duration
   *        _rewardVestingParams[1] - vesting periods
 */
    function addPool(uint256 _allocPoint,
                    address _lpToken,
                    address _committee,
                    uint256[] memory _rewardsLevels,
                    RewardsSplit memory _rewardsSplit,
                    string memory _descriptionHash,
                    uint256[2] memory _rewardVestingParams)
    external
    onlyGovernance {
        require(_rewardVestingParams[0] < 120 days, "vesting duration is too long");
        require(_rewardVestingParams[1] > 0, "vesting periods cannot be zero");
        require(_rewardVestingParams[0] >= _rewardVestingParams[1], "vesting duration smaller than periods");
        require(_committee != address(0), "committee is zero");
        add(_allocPoint, IERC20(_lpToken));
        uint256 poolId = poolInfo.length-1;
        committees[poolId] = _committee;
        uint256[] memory rewardsLevels = checkRewardsLevels(_rewardsLevels);

        RewardsSplit memory rewardsSplit = (_rewardsSplit.hackerVestedReward == 0 && _rewardsSplit.hackerReward == 0) ?
        getDefaultRewardsSplit() : _rewardsSplit;

        validateSplit(rewardsSplit);
        poolsRewards[poolId] = PoolReward({
            rewardsLevels: rewardsLevels,
            rewardsSplit: rewardsSplit,
            committeeCheckIn: false,
            vestingDuration: _rewardVestingParams[0],
            vestingPeriods: _rewardVestingParams[1]
        });

        emit AddPool(poolId,
                    _allocPoint,
                    address(_lpToken),
                    _committee,
                    _descriptionHash,
                    rewardsLevels,
                    rewardsSplit,
                    _rewardVestingParams[0],
                    _rewardVestingParams[1]);
    }

    /**
   * @dev setPool
   * @param _pid the pool id
   * @param _allocPoint the pool allocation point
   * @param _registered does this pool is registered (default true).
   * @param _depositPause pause pool deposit (default false).
   * This parameter can be used by the UI to include or exclude the pool
   * @param _descriptionHash the hash of the pool description.
 */
    function setPool(uint256 _pid,
                    uint256 _allocPoint,
                    bool _registered,
                    bool _depositPause,
                    string memory _descriptionHash)
    external onlyGovernance {
        require(poolInfo[_pid].lpToken != IERC20(address(0)), "pool does not exist");
        set(_pid, _allocPoint);
        poolDepositPause[_pid] = _depositPause;
        emit SetPool(_pid, _allocPoint, _registered, _descriptionHash);
    }

    /**
    * @dev swapBurnSend swap lptoken to HAT.
    * send to beneficiary and governance its hats rewards .
    * burn the rest of HAT.
    * only governance are authorized to call this function.
    * @param _pid the pool id
    * @param _beneficiary beneficiary
    * @param _amountOutMinimum minimum output of HATs at swap
    * @param _fees the fees for the multi path swap
    **/
    function swapBurnSend(uint256 _pid,
                        address _beneficiary,
                        uint256 _amountOutMinimum,
                        uint24[2] memory _fees)
    external
    onlyGovernance {
        IERC20 token = poolInfo[_pid].lpToken;
        uint256 amountToSwapAndBurn = swapAndBurns[address(token)];
        uint256 amountForHackersHatRewards = hackersHatRewards[_beneficiary][address(token)];
        uint256 amount = amountToSwapAndBurn.add(amountForHackersHatRewards).add(governanceHatRewards[address(token)]);
        require(amount > 0, "amount is zero");
        swapAndBurns[address(token)] = 0;
        governanceHatRewards[address(token)] = 0;
        hackersHatRewards[_beneficiary][address(token)] = 0;
        uint256 hatsReceived = swapTokenForHAT(amount, token, _fees, _amountOutMinimum);
        uint256 burntHats = hatsReceived.mul(amountToSwapAndBurn).div(amount);
        if (burntHats > 0) {
            HAT.burn(burntHats);
        }
        emit SwapAndBurn(_pid, amount, burntHats);
        address tokenLock;
        uint256 hackerReward = hatsReceived.mul(amountForHackersHatRewards).div(amount);
        if (hackerReward > 0) {
           //hacker get its reward via vesting contract
            tokenLock = tokenLockFactory.createTokenLock(
                address(HAT),
                0x000000000000000000000000000000000000dEaD, //this address as owner, so it can do nothing.
                _beneficiary,
                hackerReward,
                // solhint-disable-next-line not-rely-on-time
                block.timestamp, //start
                // solhint-disable-next-line not-rely-on-time
                block.timestamp + generalParameters.hatVestingDuration, //end
                generalParameters.hatVestingPeriods,
                0, //no release start
                0, //no cliff
                ITokenLock.Revocability.Disabled,
                true
            );
            HAT.transfer(tokenLock, hackerReward);
        }
        emit SwapAndSend(_pid, _beneficiary, amount, hackerReward, tokenLock);
        HAT.transfer(governance(), hatsReceived.sub(hackerReward).sub(burntHats));
    }

    /**
    * @dev withdrawRequest submit a withdraw request
    * @param _pid the pool id
    **/
    function withdrawRequest(uint256 _pid) external {
      // solhint-disable-next-line not-rely-on-time
        require(block.timestamp > withdrawRequests[_pid][msg.sender] + generalParameters.withdrawRequestEnablePeriod,
        "pending withdraw request exist");
        // solhint-disable-next-line not-rely-on-time
        withdrawRequests[_pid][msg.sender] = block.timestamp + generalParameters.withdrawRequestPendingPeriod;
        emit WithdrawRequest(_pid, msg.sender, withdrawRequests[_pid][msg.sender]);
    }

    /**
    * @dev deposit deposit to pool
    * @param _pid the pool id
    * @param _amount amount of pool's token to deposit
    **/
    function deposit(uint256 _pid, uint256 _amount) external {
        require(!poolDepositPause[_pid], "deposit paused");
        require(_amount >= MINIMUM_DEPOSIT, "amount less than 1e6");
        //clear withdraw request
        withdrawRequests[_pid][msg.sender] = 0;
        _deposit(_pid, _amount);
    }

    /**
    * @dev withdraw  - withdraw user's pool share.
    * user need first to submit a withdraw request.
    * @param _pid the pool id
    * @param _shares amount of shares user wants to withdraw
    **/
    function withdraw(uint256 _pid, uint256 _shares) external {
        checkWithdrawRequest(_pid);
        _withdraw(_pid, _shares);
    }

    /**
    * @dev emergencyWithdraw withdraw all user's pool share without claim for reward.
    * user need first to submit a withdraw request.
    * @param _pid the pool id
    **/
    function emergencyWithdraw(uint256 _pid) external {
        checkWithdrawRequest(_pid);
        _emergencyWithdraw(_pid);
    }

    function getPoolRewardsLevels(uint256 _pid) external view returns(uint256[] memory) {
        return poolsRewards[_pid].rewardsLevels;
    }

    function getPoolRewards(uint256 _pid) external view returns(PoolReward memory) {
        return poolsRewards[_pid];
    }

    // GET INFO for UI
    /**
    * @dev getRewardPerBlock return the current pool reward per block
    * @param _pid1 the pool id.
    *        if _pid1 = 0 , it return the current block reward for whole pools.
    *        otherwise it return the current block reward for _pid1-1.
    * @return rewardPerBlock
    **/
    function getRewardPerBlock(uint256 _pid1) external view returns (uint256) {
        if (_pid1 == 0) {
            return getRewardForBlocksRange(block.number-1, block.number, 1, 1);
        } else {
            return getRewardForBlocksRange(block.number-1,
                                        block.number,
                                        poolInfo[_pid1 - 1].allocPoint,
                                        globalPoolUpdates[globalPoolUpdates.length-1].totalAllocPoint);
        }
    }

    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 rewardPerShare = pool.rewardPerShare;

        if (block.number > pool.lastRewardBlock && pool.totalUsersAmount > 0) {
            uint256 reward = calcPoolReward(_pid, pool.lastRewardBlock, globalPoolUpdates.length-1);
            rewardPerShare = rewardPerShare.add(reward.mul(1e12).div(pool.totalUsersAmount));
        }
        return user.amount.mul(rewardPerShare).div(1e12).sub(user.rewardDebt);
    }

    function getGlobalPoolUpdatesLength() external view returns (uint256) {
        return globalPoolUpdates.length;
    }

    function getStakedAmount(uint _pid, address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        return  user.amount;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function calcClaimRewards(uint256 _pid, uint256 _severity)
    public
    view
    returns(ClaimReward memory claimRewards) {
        uint256 totalSupply = poolInfo[_pid].balance;
        require(totalSupply > 0, "totalSupply is zero");
        require(_severity < poolsRewards[_pid].rewardsLevels.length, "_severity is not in the range");
        //hackingRewardAmount
        uint256 claimRewardAmount =
        totalSupply.mul(poolsRewards[_pid].rewardsLevels[_severity]);
        claimRewards.hackerVestedReward =
        claimRewardAmount.mul(poolsRewards[_pid].rewardsSplit.hackerVestedReward)
        .div(REWARDS_LEVEL_DENOMINATOR*REWARDS_LEVEL_DENOMINATOR);
        claimRewards.hackerReward =
        claimRewardAmount.mul(poolsRewards[_pid].rewardsSplit.hackerReward)
        .div(REWARDS_LEVEL_DENOMINATOR*REWARDS_LEVEL_DENOMINATOR);
        claimRewards.committeeReward =
        claimRewardAmount.mul(poolsRewards[_pid].rewardsSplit.committeeReward)
        .div(REWARDS_LEVEL_DENOMINATOR*REWARDS_LEVEL_DENOMINATOR);
        claimRewards.swapAndBurn =
        claimRewardAmount.mul(poolsRewards[_pid].rewardsSplit.swapAndBurn)
        .div(REWARDS_LEVEL_DENOMINATOR*REWARDS_LEVEL_DENOMINATOR);
        claimRewards.governanceHatReward =
        claimRewardAmount.mul(poolsRewards[_pid].rewardsSplit.governanceHatReward)
        .div(REWARDS_LEVEL_DENOMINATOR*REWARDS_LEVEL_DENOMINATOR);
        claimRewards.hackerHatReward =
        claimRewardAmount.mul(poolsRewards[_pid].rewardsSplit.hackerHatReward)
        .div(REWARDS_LEVEL_DENOMINATOR*REWARDS_LEVEL_DENOMINATOR);
    }

    function getDefaultRewardsSplit() public pure returns (RewardsSplit memory) {
        return RewardsSplit({
            hackerVestedReward: 6000,
            hackerReward: 2000,
            committeeReward: 500,
            swapAndBurn: 0,
            governanceHatReward: 1000,
            hackerHatReward: 500
        });
    }

    function validateSplit(RewardsSplit memory _rewardsSplit) internal pure {
        require(_rewardsSplit.hackerVestedReward
            .add(_rewardsSplit.hackerReward)
            .add(_rewardsSplit.committeeReward)
            .add(_rewardsSplit.swapAndBurn)
            .add(_rewardsSplit.governanceHatReward)
            .add(_rewardsSplit.hackerHatReward) == REWARDS_LEVEL_DENOMINATOR,
        "total split % should be 10000");
    }

    function checkWithdrawRequest(uint256 _pid) internal noPendingApproval(_pid) noSafetyPeriod {
      // solhint-disable-next-line not-rely-on-time
        require(block.timestamp > withdrawRequests[_pid][msg.sender] &&
      // solhint-disable-next-line not-rely-on-time
                block.timestamp < withdrawRequests[_pid][msg.sender] + generalParameters.withdrawRequestEnablePeriod,
                "withdraw request not valid");
        withdrawRequests[_pid][msg.sender] = 0;
    }

    function swapTokenForHAT(uint256 _amount,
                            IERC20 _token,
                            uint24[2] memory _fees,
                            uint256 _amountOutMinimum)
    internal
    returns (uint256 hatsReceived)
    {
        if (address(_token) == address(HAT)) {
            return _amount;
        }
        require(_token.approve(address(uniSwapRouter), _amount), "token approve failed");
        uint256 hatBalanceBefore = HAT.balanceOf(address(this));
        address weth = uniSwapRouter.WETH9();
        bytes memory path;
        if (address(_token) == weth) {
            path = abi.encodePacked(address(_token), _fees[0], address(HAT));
        } else {
            path = abi.encodePacked(address(_token), _fees[0], weth, _fees[1], address(HAT));
        }
        hatsReceived = uniSwapRouter.exactInput(ISwapRouter.ExactInputParams({
            path: path,
            recipient: address(this),
            // solhint-disable-next-line not-rely-on-time
            deadline: block.timestamp,
            amountIn: _amount,
            amountOutMinimum: _amountOutMinimum
        }));
        require(HAT.balanceOf(address(this)) - hatBalanceBefore >= _amountOutMinimum, "wrong amount received");
    }

    /**
   * @dev checkRewardsLevels - check rewards levels.
   * each level should be less than 10000
   * if _rewardsLevels length is 0 a default reward levels will be return
   * default reward levels = [2000, 4000, 6000, 8000]
   * @param _rewardsLevels the reward levels array
   * @return rewardsLevels
 */
    function checkRewardsLevels(uint256[] memory _rewardsLevels)
    private
    pure
    returns (uint256[] memory rewardsLevels) {

        uint256 i;
        if (_rewardsLevels.length == 0) {
            rewardsLevels = new uint256[](4);
            for (i; i < 4; i++) {
              //defaultRewardLevels = [2000, 4000, 6000, 8000];
                rewardsLevels[i] = 2000*(i+1);
            }
        } else {
            for (i; i < _rewardsLevels.length; i++) {
                require(_rewardsLevels[i] < REWARDS_LEVEL_DENOMINATOR, "reward level can not be more than 10000");
            }
            rewardsLevels = _rewardsLevels;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }
    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);

    // solhint-disable-next-line func-name-mixedcase
    function WETH9() external pure returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
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
}

// SPDX-License-Identifier: MIT
// Disclaimer https://github.com/hats-finance/hats-contracts/blob/main/DISCLAIMER.md

pragma solidity 0.8.6;


import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "./HATToken.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";


contract HATMaster is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;     // The user share of the pool based on the amount of lpToken the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
      //
      // We do some fancy math here. Basically, any point in time, the amount of HATs
      // entitled to a user but is pending to be distributed is:
      //
      //   pending reward = (user.amount * pool.rewardPerShare) - user.rewardDebt
      //
      // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
      //   1. The pool's `rewardPerShare` (and `lastRewardBlock`) gets updated.
      //   2. User receives the pending reward sent to his/her address.
      //   3. User's `amount` gets updated.
      //   4. User's `rewardDebt` gets updated.
    }

    struct PoolUpdate {
        uint256 blockNumber;// update blocknumber
        uint256 totalAllocPoint; //totalAllocPoint
    }

    struct RewardsSplit {
        //the percentage of the total reward to reward the hacker via vesting contract(claim reported)
        uint256 hackerVestedReward;
        //the percentage of the total reward to reward the hacker(claim reported)
        uint256 hackerReward;
        // the percentage of the total reward to be sent to the committee
        uint256 committeeReward;
        // the percentage of the total reward to be swap to HAT and to be burned
        uint256 swapAndBurn;
        // the percentage of the total reward to be swap to HAT and sent to governance
        uint256 governanceHatReward;
        // the percentage of the total reward to be swap to HAT and sent to the hacker
        uint256 hackerHatReward;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 rewardPerShare;
        uint256 totalUsersAmount;
        uint256 lastProcessedTotalAllocPoint;
        uint256 balance;
    }

    // Info of each pool.
    struct PoolReward {
        RewardsSplit rewardsSplit;
        uint256[]  rewardsLevels;
        bool committeeCheckIn;
        uint256 vestingDuration;
        uint256 vestingPeriods;
    }

    HATToken public immutable HAT;
    uint256 public immutable REWARD_PER_BLOCK;
    uint256 public immutable START_BLOCK;
    uint256 public immutable MULTIPLIER_PERIOD;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    PoolUpdate[] public globalPoolUpdates;
    mapping(address => uint256) public poolId1; // poolId1 count from 1, subtraction 1 before using with poolInfo
    // Info of each user that stakes LP tokens. pid => user address => info
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    //pid -> PoolReward
    mapping (uint256=>PoolReward) internal poolsRewards;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SendReward(address indexed user, uint256 indexed pid, uint256 amount, uint256 requestedAmount);
    event MassUpdatePools(uint256 _fromPid, uint256 _toPid);

    constructor(
        HATToken _hat,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _multiplierPeriod
    // solhint-disable-next-line func-visibility
    ) {
        HAT = _hat;
        REWARD_PER_BLOCK = _rewardPerBlock;
        START_BLOCK = _startBlock;
        MULTIPLIER_PERIOD = _multiplierPeriod;
    }

  /**
   * @dev massUpdatePools - Update reward variables for all pools
   * Be careful of gas spending!
   * @param _fromPid update pools range from this pool id
   * @param _toPid update pools range to this pool id
   */
    function massUpdatePools(uint256 _fromPid, uint256 _toPid) external {
        require(_toPid <= poolInfo.length, "pool range is too big");
        require(_fromPid <= _toPid, "invalid pool range");
        for (uint256 pid = _fromPid; pid < _toPid; ++pid) {
            updatePool(pid);
        }
        emit MassUpdatePools(_fromPid, _toPid);
    }

    function claimReward(uint256 _pid) external {
        _deposit(_pid, 0);
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 lastRewardBlock = pool.lastRewardBlock;
        if (block.number <= lastRewardBlock) {
            return;
        }
        uint256 totalUsersAmount = pool.totalUsersAmount;
        uint256 lastPoolUpdate = globalPoolUpdates.length-1;
        if (totalUsersAmount == 0) {
            pool.lastRewardBlock = block.number;
            pool.lastProcessedTotalAllocPoint = lastPoolUpdate;
            return;
        }
        uint256 reward = calcPoolReward(_pid, lastRewardBlock, lastPoolUpdate);
        uint256 amountCanMint = HAT.minters(address(this));
        reward = amountCanMint < reward ? amountCanMint : reward;
        if (reward > 0) {
            HAT.mint(address(this), reward);
        }
        pool.rewardPerShare = pool.rewardPerShare.add(reward.mul(1e12).div(totalUsersAmount));
        pool.lastRewardBlock = block.number;
        pool.lastProcessedTotalAllocPoint = lastPoolUpdate;
    }

    /**
     * @dev getMultiplier - multiply blocks with relevant multiplier for specific range
     * @param _from range's from block
     * @param _to range's to block
     * will revert if from < START_BLOCK or _to < _from
     */
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256 result) {
        uint256[25] memory rewardMultipliers = [uint256(4413), 4413, 8825, 7788, 6873, 6065,
                                            5353, 4724, 4169, 3679, 3247, 2865,
                                            2528, 2231, 1969, 1738, 1534, 1353,
                                            1194, 1054, 930, 821, 724, 639, 0];
        uint256 max = rewardMultipliers.length;
        uint256 i = (_from - START_BLOCK) / MULTIPLIER_PERIOD + 1;
        for (; i < max; i++) {
            uint256 endBlock = MULTIPLIER_PERIOD * i + START_BLOCK;
            if (_to <= endBlock) {
                break;
            }
            result += (endBlock - _from) * rewardMultipliers[i-1];
            _from = endBlock;
        }
        result += (_to - _from) * rewardMultipliers[i > max ? (max-1) : (i-1)];
    }

    function getRewardForBlocksRange(uint256 _from, uint256 _to, uint256 _allocPoint, uint256 _totalAllocPoint)
    public
    view
    returns (uint256 reward) {
        if (_totalAllocPoint > 0) {
            reward = getMultiplier(_from, _to).mul(REWARD_PER_BLOCK).mul(_allocPoint).div(_totalAllocPoint).div(100);
        }
    }

    /**
     * @dev calcPoolReward -
     * calculate rewards for a pool by iterating over the history of totalAllocPoints updates.
     * and sum up all rewards periods from pool.lastRewardBlock till current block number.
     * @param _pid pool id
     * @param _from block starting calculation
     * @param _lastPoolUpdate lastPoolUpdate
     * @return reward
     */
    function calcPoolReward(uint256 _pid, uint256 _from, uint256 _lastPoolUpdate) public view returns(uint256 reward) {
        uint256 poolAllocPoint = poolInfo[_pid].allocPoint;
        uint256 i = poolInfo[_pid].lastProcessedTotalAllocPoint;
        for (; i < _lastPoolUpdate; i++) {
            uint256 nextUpdateBlock = globalPoolUpdates[i+1].blockNumber;
            reward =
            reward.add(getRewardForBlocksRange(_from,
                                            nextUpdateBlock,
                                            poolAllocPoint,
                                            globalPoolUpdates[i].totalAllocPoint));
            _from = nextUpdateBlock;
        }
        return reward.add(getRewardForBlocksRange(_from,
                                                block.number,
                                                poolAllocPoint,
                                                globalPoolUpdates[i].totalAllocPoint));
    }

    function _deposit(uint256 _pid, uint256 _amount) internal nonReentrant {
        require(poolsRewards[_pid].committeeCheckIn, "committee not checked in yet");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.rewardPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeTransferReward(msg.sender, pending, _pid);
            }
        }
        if (_amount > 0) {
            uint256 lpSupply = pool.balance;
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            pool.balance = pool.balance.add(_amount);
            uint256 factoredAmount = _amount;
            if (pool.totalUsersAmount > 0) {
                factoredAmount = pool.totalUsersAmount.mul(_amount).div(lpSupply);
            }
            user.amount = user.amount.add(factoredAmount);
            pool.totalUsersAmount = pool.totalUsersAmount.add(factoredAmount);
        }
        user.rewardDebt = user.amount.mul(pool.rewardPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function _withdraw(uint256 _pid, uint256 _amount) internal nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not enough user balance");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.rewardPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeTransferReward(msg.sender, pending, _pid);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            uint256 amountToWithdraw = _amount.mul(pool.balance).div(pool.totalUsersAmount);
            pool.balance = pool.balance.sub(amountToWithdraw);
            pool.lpToken.safeTransfer(msg.sender, amountToWithdraw);
            pool.totalUsersAmount = pool.totalUsersAmount.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.rewardPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function _emergencyWithdraw(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount > 0, "user.amount = 0");
        uint256 factoredBalance = user.amount.mul(pool.balance).div(pool.totalUsersAmount);
        pool.totalUsersAmount = pool.totalUsersAmount.sub(user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        pool.balance = pool.balance.sub(factoredBalance);
        pool.lpToken.safeTransfer(msg.sender, factoredBalance);
        emit EmergencyWithdraw(msg.sender, _pid, factoredBalance);
    }

    // -------- For manage pool ---------
    function add(uint256 _allocPoint, IERC20 _lpToken) internal {
        require(poolId1[address(_lpToken)] == 0, "HATMaster::add: lpToken is already in pool");
        poolId1[address(_lpToken)] = poolInfo.length + 1;
        uint256 lastRewardBlock = block.number > START_BLOCK ? block.number : START_BLOCK;
        uint256 totalAllocPoint = (globalPoolUpdates.length == 0) ? _allocPoint :
        globalPoolUpdates[globalPoolUpdates.length-1].totalAllocPoint.add(_allocPoint);

        if (globalPoolUpdates.length > 0 &&
            globalPoolUpdates[globalPoolUpdates.length-1].blockNumber == block.number) {
           //already update in this block
            globalPoolUpdates[globalPoolUpdates.length-1].totalAllocPoint = totalAllocPoint;
        } else {
            globalPoolUpdates.push(PoolUpdate({
                blockNumber: block.number,
                totalAllocPoint: totalAllocPoint
            }));
        }

        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            rewardPerShare: 0,
            totalUsersAmount: 0,
            lastProcessedTotalAllocPoint: globalPoolUpdates.length-1,
            balance: 0
        }));
    }

    function set(uint256 _pid, uint256 _allocPoint) internal {
        updatePool(_pid);
        uint256 totalAllocPoint =
        globalPoolUpdates[globalPoolUpdates.length-1].totalAllocPoint
        .sub(poolInfo[_pid].allocPoint).add(_allocPoint);

        if (globalPoolUpdates[globalPoolUpdates.length-1].blockNumber == block.number) {
           //already update in this block
            globalPoolUpdates[globalPoolUpdates.length-1].totalAllocPoint = totalAllocPoint;
        } else {
            globalPoolUpdates.push(PoolUpdate({
                blockNumber: block.number,
                totalAllocPoint: totalAllocPoint
            }));
        }
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Safe HAT transfer function, just in case if rounding error causes pool to not have enough HATs.
    function safeTransferReward(address _to, uint256 _amount, uint256 _pid) internal {
        uint256 hatBalance = HAT.balanceOf(address(this));
        if (_amount > hatBalance) {
            HAT.transfer(_to, hatBalance);
            emit SendReward(_to, _pid, hatBalance, _amount);
        } else {
            HAT.transfer(_to, _amount);
            emit SendReward(_to, _pid, _amount, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ITokenLock.sol";

interface ITokenLockFactory {
    // -- Factory --
    function setMasterCopy(address _masterCopy) external;

    function createTokenLock(
        address _token,
        address _owner,
        address _beneficiary,
        uint256 _managedAmount,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _periods,
        uint256 _releaseStartTime,
        uint256 _vestingCliffTime,
        ITokenLock.Revocability _revocable,
        bool _canDelegate
    ) external returns(address contractAddress);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an governance) that can be granted exclusive access to
 * specific functions.
 *
 * The governance account will be passed on initialization of the contract. This
 * can later be changed with {setPendingGovernance and then transferGovernorship  after 2 days}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyGovernance`, which can be applied to your functions to restrict their use to
 * the governance.
 */
contract Governable {
    address private _governance;
    address public governancePending;
    uint256 public setGovernancePendingAt;
    uint256 public constant TIME_LOCK_DELAY = 2 days;


    /// @notice An event thats emitted when a new governance address is set
    event GovernorshipTransferred(address indexed _previousGovernance, address indexed _newGovernance);
    /// @notice An event thats emitted when a new governance address is pending
    event GovernancePending(address indexed _previousGovernance, address indexed _newGovernance, uint256 _at);

    /**
     * @dev Throws if called by any account other than the governance.
     */
    modifier onlyGovernance() {
        require(msg.sender == _governance, "only governance");
        _;
    }

    /**
     * @dev setPendingGovernance set a pending governance address.
     * NOTE: transferGovernorship can be called after a time delay of 2 days.
     */
    function setPendingGovernance(address _newGovernance) external  onlyGovernance {
        require(_newGovernance != address(0), "Governable:new governance is the zero address");
        governancePending = _newGovernance;
        // solhint-disable-next-line not-rely-on-time
        setGovernancePendingAt = block.timestamp;
        emit GovernancePending(_governance, _newGovernance, setGovernancePendingAt);
    }

    /**
     * @dev transferGovernorship transfer governorship to the pending governance address.
     * NOTE: transferGovernorship can be called after a time delay of 2 days from the latest setPendingGovernance.
     */
    function transferGovernorship() external onlyGovernance {
        require(setGovernancePendingAt > 0, "Governable: no pending governance");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp - setGovernancePendingAt > TIME_LOCK_DELAY,
        "Governable: cannot confirm governance at this time");
        emit GovernorshipTransferred(_governance, governancePending);
        _governance = governancePending;
        setGovernancePendingAt = 0;
    }

    /**
     * @dev Returns the address of the current governance.
     */
    function governance() public view returns (address) {
        return _governance;
    }

    /**
     * @dev Initializes the contract setting the initial governance.
     */
    function initialize(address _initialGovernance) internal {
        _governance = _initialGovernance;
        emit GovernorshipTransferred(address(0), _initialGovernance);
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

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";


contract HATToken is IERC20 {

    struct PendingMinter {
        uint256 seedAmount;
        uint256 setMinterPendingAt;
    }

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice EIP-20 token name for this token
    // solhint-disable-next-line const-name-snakecase
    string public constant name = "hats.finance";

    /// @notice EIP-20 token symbol for this token
    // solhint-disable-next-line const-name-snakecase
    string public constant symbol = "HAT";

    /// @notice EIP-20 token decimals for this token
    // solhint-disable-next-line const-name-snakecase
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint public override totalSupply;

    address public governance;
    address public governancePending;
    uint256 public setGovernancePendingAt;
    uint256 public immutable timeLockDelay;
    uint256 public constant CAP = 10000000e18;

    /// @notice Address which may mint new tokens
    /// minter -> minting seedAmount
    mapping (address => uint256) public minters;

    /// @notice Address which may mint new tokens
    /// minter -> minting seedAmount
    mapping (address => PendingMinter) public pendingMinters;

    // @notice Allowance amounts on behalf of others
    mapping (address => mapping (address => uint96)) internal allowances;

    // @notice Official record of token balances for each account
    mapping (address => uint96) internal balances;

    /// @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
    keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
    keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH =
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @notice An event thats emitted when a new minter address is pending
    event MinterPending(address indexed minter, uint256 seedAmount, uint256 at);
    /// @notice An event thats emitted when the minter address is changed
    event MinterChanged(address indexed minter, uint256 seedAmount);
    /// @notice An event thats emitted when a new governance address is pending
    event GovernancePending(address indexed oldGovernance, address indexed newGovernance, uint256 at);
    /// @notice An event thats emitted when a new governance address is set
    event GovernanceChanged(address indexed oldGovernance, address indexed newGovernance);
    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Construct a new HAT token
     */
    // solhint-disable-next-line func-visibility
    constructor(address _governance, uint256 _timeLockDelay) {
        governance = _governance;
        timeLockDelay = _timeLockDelay;
    }

    function setPendingGovernance(address _governance) external {
        require(msg.sender == governance, "HAT:!governance");
        require(_governance != address(0), "HAT:!_governance");
        governancePending = _governance;
        // solhint-disable-next-line not-rely-on-time
        setGovernancePendingAt = block.timestamp;
        emit GovernancePending(governance, _governance, setGovernancePendingAt);
    }

    function confirmGovernance() external {
        require(msg.sender == governance, "HAT:!governance");
        require(setGovernancePendingAt > 0, "HAT:!governancePending");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp - setGovernancePendingAt > timeLockDelay,
        "HAT: cannot confirm governance at this time");
        emit GovernanceChanged(governance, governancePending);
        governance = governancePending;
        setGovernancePendingAt = 0;
    }

    function setPendingMinter(address _minter, uint256 _cap) external {
        require(msg.sender == governance, "HAT::!governance");
        pendingMinters[_minter].seedAmount = _cap;
        // solhint-disable-next-line not-rely-on-time
        pendingMinters[_minter].setMinterPendingAt = block.timestamp;
        emit MinterPending(_minter, _cap, pendingMinters[_minter].setMinterPendingAt);
    }

    function confirmMinter(address _minter) external {
        require(msg.sender == governance, "HAT::mint: only the governance can confirm minter");
        require(pendingMinters[_minter].setMinterPendingAt > 0, "HAT:: no pending minter was set");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp - pendingMinters[_minter].setMinterPendingAt > timeLockDelay,
        "HATToken: cannot confirm at this time");
        minters[_minter] = pendingMinters[_minter].seedAmount;
        pendingMinters[_minter].setMinterPendingAt = 0;
        emit MinterChanged(_minter, pendingMinters[_minter].seedAmount);
    }

    function burn(uint256 _amount) external {
        return _burn(msg.sender, _amount);
    }

    function mint(address _account, uint _amount) external {
        require(minters[msg.sender] >= _amount, "HATToken: amount greater than limitation");
        minters[msg.sender] = SafeMath.sub(minters[msg.sender], _amount);
        _mint(_account, _amount);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external override view returns (uint) {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint rawAmount) external override returns (bool) {
        uint96 amount;
        if (rawAmount == type(uint256).max) {
            amount = type(uint96).max;
        } else {
            amount = safe96(rawAmount, "HAT::approve: amount exceeds 96 bits");
        }

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
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
    function increaseAllowance(address spender, uint addedValue) external virtual returns (bool) {
        require(spender != address(0), "HAT: increaseAllowance to the zero address");
        uint96 valueToAdd = safe96(addedValue, "HAT::increaseAllowance: addedValue exceeds 96 bits");
        allowances[msg.sender][spender] =
        add96(allowances[msg.sender][spender], valueToAdd, "HAT::increaseAllowance: overflows");
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
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
    function decreaseAllowance(address spender, uint subtractedValue) external virtual returns (bool) {
        require(spender != address(0), "HAT: decreaseAllowance to the zero address");
        uint96 valueTosubtract = safe96(subtractedValue, "HAT::decreaseAllowance: subtractedValue exceeds 96 bits");
        allowances[msg.sender][spender] = sub96(allowances[msg.sender][spender], valueTosubtract,
        "HAT::decreaseAllowance: spender allowance is less than subtractedValue");
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    /**
     * @notice Triggers an approval from owner to spends
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(address owner, address spender, uint rawAmount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        uint96 amount;
        if (rawAmount == type(uint256).max) {
            amount = type(uint96).max;
        } else {
            amount = safe96(rawAmount, "HAT::permit: amount exceeds 96 bits");
        }

        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, rawAmount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "HAT::permit: invalid signature");
        require(signatory == owner, "HAT::permit: unauthorized");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "HAT::permit: signature expired");

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view override returns (uint) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint rawAmount) external override returns (bool) {
        uint96 amount = safe96(rawAmount, "HAT::transfer: amount exceeds 96 bits");
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint rawAmount) external override returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(rawAmount, "HAT::approve: amount exceeds 96 bits");

        if (spender != src && spenderAllowance != type(uint96).max) {
            uint96 newAllowance = sub96(spenderAllowance, amount,
            "HAT::transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "HAT::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "HAT::delegateBySig: invalid nonce");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= expiry, "HAT::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) external view returns (uint96) {
        require(blockNumber < block.number, "HAT::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    /**
     * @notice Mint new tokens
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to be minted
     */
    function _mint(address dst, uint rawAmount) internal {
        require(dst != address(0), "HAT::mint: cannot transfer to the zero address");
        require(SafeMath.add(totalSupply, rawAmount) <= CAP, "ERC20Capped: CAP exceeded");

        // mint the amount
        uint96 amount = safe96(rawAmount, "HAT::mint: amount exceeds 96 bits");
        totalSupply = safe96(SafeMath.add(totalSupply, amount), "HAT::mint: totalSupply exceeds 96 bits");

        // transfer the amount to the recipient
        balances[dst] = add96(balances[dst], amount, "HAT::mint: transfer amount overflows");
        emit Transfer(address(0), dst, amount);

        // move delegates
        _moveDelegates(address(0), delegates[dst], amount);
    }

    /**
     * Burn tokens
     * @param src The address of the source account
     * @param rawAmount The number of tokens to be burned
     */
    function _burn(address src, uint rawAmount) internal {
        require(src != address(0), "HAT::burn: cannot burn to the zero address");

        // burn the amount
        uint96 amount = safe96(rawAmount, "HAT::burn: amount exceeds 96 bits");
        totalSupply = safe96(SafeMath.sub(totalSupply, amount), "HAT::mint: totalSupply exceeds 96 bits");

        // reduce the amount from src address
        balances[src] = sub96(balances[src], amount, "HAT::burn: burn amount exceeds balance");
        emit Transfer(src, address(0), amount);

        // move delegates
        _moveDelegates(delegates[src], address(0), amount);
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != address(0), "HAT::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "HAT::_transferTokens: cannot transfer to the zero address");

        balances[src] = sub96(balances[src], amount, "HAT::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "HAT::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "HAT::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "HAT::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
        uint32 blockNumber = safe32(block.number, "HAT::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly { chainId := chainid() }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor () {
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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface ITokenLock {
    enum Revocability { NotSet, Enabled, Disabled }

    // -- Balances --

    function currentBalance() external view returns (uint256);

    // -- Time & Periods --

    function currentTime() external view returns (uint256);

    function duration() external view returns (uint256);

    function sinceStartTime() external view returns (uint256);

    function amountPerPeriod() external view returns (uint256);

    function periodDuration() external view returns (uint256);

    function currentPeriod() external view returns (uint256);

    function passedPeriods() external view returns (uint256);

    // -- Locking & Release Schedule --

    function availableAmount() external view returns (uint256);

    function vestedAmount() external view returns (uint256);

    function releasableAmount() external view returns (uint256);

    function totalOutstandingAmount() external view returns (uint256);

    function surplusAmount() external view returns (uint256);

    // -- Value Transfer --

    function release() external;

    function withdrawSurplus(uint256 _amount) external;

    function revoke() external;
}

