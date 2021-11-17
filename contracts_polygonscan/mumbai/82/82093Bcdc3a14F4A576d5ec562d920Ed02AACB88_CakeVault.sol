//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";

import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./IMasterChef.sol";
import "./IReferral.sol";
import "./IFundStorage.sol";
import "./IERC20.sol";


contract CakeVault is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct UserInfo {
        uint256 shares; // number of shares for a user
        uint256 lastDepositedTime; // keeps track of deposited time for potential penalty
        uint256 cakeAtLastUserAction; // keeps track of cake deposited at the last user action
        uint256 lastUserActionTime; // keeps track of the last user action time
    }

    struct ParentInfo {
        uint256 shares;
        uint256 lastRewardClaimed;
    }

    IERC20 public immutable token; // Cake token
    IERC20 public immutable receiptToken; // Syrup token

    IMasterChef public immutable masterchef;
    IReferral public immutable ref;

    mapping(address => UserInfo) public userInfo;
    mapping(address => ParentInfo) public parentInfo;
    mapping(address => bool) public isParent;

    uint256 public totalShares;
    uint256 public lastHarvestedTime;
    address public admin;
    address public treasury;

    uint256 public constant MAX_PERFORMANCE_FEE = 500; // 5%
    uint256 public constant MAX_CALL_FEE = 100; // 1%
    uint256 public constant MAX_WITHDRAW_FEE = 200; // 1%
    uint256 constant MAX_APPROVE = type(uint256).max;
    
    uint256 public refRewardRate = 1000;
    uint256 public performanceFee = 200; // 2%
    uint256 public callFee = 25; // 0.25%
    uint256 public withdrawFeePerDay = 10; // 0.1%
    uint256 public withdrawFeePeriod = 20 days; // 3 days
    uint256 public depositTax = 500; // 5%

    uint public totalFeeAvailable;

    address referralContract;
    address FundStorage;

    uint TotalReferralShares;
    uint public totalReferralRewardClaimed;


    event Deposit(address indexed sender, uint256 amount, uint256 shares, uint256 lastDepositedTime);
    event Withdraw(address indexed sender, uint256 amount, uint256 shares);
    event Harvest(address indexed sender, uint256 performanceFee, uint256 callFee);
    event Pause();
    event Unpause();

    /**
     * @notice Constructor
     * @param _token: Cake token contract
     * @param _receiptToken: Syrup token contract
     * @param _masterchef: MasterChef contract
     * @param _admin: address of the admin
     * @param _treasury: address of the treasury (collects fees)
     */
    constructor(
        IERC20 _token,
        IERC20 _receiptToken,
        IMasterChef _masterchef,
        address _admin,
        address _treasury,
        address _referralContract,
        address _FundStorage
    ) {
        token = _token;
        receiptToken = _receiptToken;
        masterchef = _masterchef;
        admin = _admin;
        treasury = _treasury;
        referralContract = _referralContract;
        FundStorage = _FundStorage;
        ref = IReferral(_referralContract); 

        // Infinite approve
        IERC20(_token).safeApprove(address(_masterchef), MAX_APPROVE);
        IERC20(_token).safeApprove(_FundStorage, MAX_APPROVE);
    }

    /**
     * @notice Checks if the msg.sender is the admin address
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "admin: wut?");
        _;
    }

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    // Calculate Withdraw Fee

    function calculateWithdrawFee(uint256 started, uint256 ended, uint256 amount) private returns (uint256){
        uint256 period_in_days = (ended.sub(started)).div(86400);
        uint fee_rate = 0;
        fee_rate = period_in_days.mul(withdrawFeePerDay);
        // getting fee by multiplying with days
        if (fee_rate < withdrawFeePerDay) {// if fee calculated is less than fee perday, set to minfee
            fee_rate = withdrawFeePerDay;
        }
        else if (fee_rate > MAX_WITHDRAW_FEE) {//if fee grater than max fee, then setting to max fee
            fee_rate = MAX_WITHDRAW_FEE;
        }
        uint256 fees = amount.mul(fee_rate).div(10000);
        totalFeeAvailable = totalFeeAvailable.add(fees);
        return (fees);
    }



    function claimParentReward(address _parent, uint _shares, bool withdrawalClaim) internal {
        ParentInfo storage parent = parentInfo[_parent];
        uint256 currentAmount = parent.shares.mul((getPricePerFullShare()));
        if (parent.lastRewardClaimed < currentAmount) {
            if(withdrawalClaim){
                uint withdrawPercent = _shares.mul(refRewardRate).div(10000);
                parent.shares = parent.shares.sub(withdrawPercent);
                TotalReferralShares = TotalReferralShares.sub(withdrawPercent);
            }
            parent.lastRewardClaimed = currentAmount.sub(parent.lastRewardClaimed);        
            totalReferralRewardClaimed += currentAmount.sub(parent.lastRewardClaimed);

            IFundStorage(FundStorage).transferReferral(_parent, currentAmount);
        }
    }

    function claimReferralReward() external returns (bool){
        require(isParent[msg.sender], "NOT A PARENT");
        claimParentReward(msg.sender, 0, false);
        return true;
    }

    function getParent(address _child) public returns(address parent) {
       if (ref.hasReferrer(_child)) {
            (bool success, bytes memory returndata) = referralContract.call(abi.encodeWithSignature('accounts(address)', _child));
            if (success){
                (address referrer,,) = abi.decode(returndata, (address, uint, uint));
                return referrer;
            }
        }

    }
    /**
     * @notice Deposits funds into the Cake Vault
     * @dev Only possible when contract not paused.
     * @param _amount: number of tokens to deposit (in CAKE)
     */
    function deposit(uint256 _amount) external whenNotPaused notContract {
        require(_amount > 0, "Nothing to deposit");

        uint256 pool = balanceOf();
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 currentShares = 0;
        if (depositTax > 0){
            uint tax = _amount.mul(depositTax).div(10000);
            _amount = _amount.sub(tax);
            token.safeTransfer(owner(),  tax);
        }

        if (totalShares != 0) {
            currentShares = (_amount.mul(totalShares)).div(pool);
        } else {
            currentShares = _amount;
        }

        UserInfo storage user = userInfo[msg.sender];
        user.shares = user.shares.add(currentShares);
        user.lastDepositedTime = block.timestamp;

        if (ref.hasReferrer(msg.sender)){
            address parentAddress = getParent(msg.sender);
            isParent[parentAddress] = true;
            ParentInfo storage parent = parentInfo[parentAddress];

            uint owedParentShares = currentShares.mul(refRewardRate).div(10000);
            parent.shares += owedParentShares;
            if (parent.lastRewardClaimed == 0){
                parent.lastRewardClaimed = parent.shares.mul(getPricePerFullShare());
            }
            TotalReferralShares += owedParentShares;
        }
        totalShares = totalShares.add(currentShares);

        user.cakeAtLastUserAction = user.shares.mul(balanceOf()).div(totalShares);
        user.lastUserActionTime = block.timestamp;

        _earn();

        emit Deposit(msg.sender, _amount, currentShares, block.timestamp);
    }

    /**
     * @notice Withdraws all funds for a user
     */
    function withdrawAll() external notContract {
        withdraw(userInfo[msg.sender].shares);
    }

    /**
     * @notice Reinvests CAKE tokens into MasterChef
     * @dev Only possible when contract not paused.
     */
    function harvest() external notContract whenNotPaused {
        IMasterChef(masterchef).leaveStaking(0);

        uint256 bal = available();
        uint256 currentPerformanceFee = bal.mul(performanceFee).div(10000);
        token.safeTransfer(treasury, currentPerformanceFee);

        uint256 currentCallFee = bal.mul(callFee).div(10000);
        token.safeTransfer(msg.sender, currentCallFee);

        _earn();

        lastHarvestedTime = block.timestamp;

        emit Harvest(msg.sender, currentPerformanceFee, currentCallFee);
    }

    /**
     * @notice Sets admin address
     * @dev Only callable by the contract owner.
     */
    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Cannot be zero address");
        admin = _admin;
    }

    /**
     * @notice Sets treasury address
     * @dev Only callable by the contract owner.
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Cannot be zero address");
        treasury = _treasury;
    }

    /**
     * @notice Sets performance fee
     * @dev Only callable by the contract admin.
     */
    function setPerformanceFee(uint256 _performanceFee) external onlyAdmin {
        require(_performanceFee <= MAX_PERFORMANCE_FEE, "performanceFee cannot be more than MAX_PERFORMANCE_FEE");
        performanceFee = _performanceFee;
    }

    /**
     * @notice Sets call fee
     * @dev Only callable by the contract admin.
     */
    function setCallFee(uint256 _callFee) external onlyAdmin {
        require(_callFee <= MAX_CALL_FEE, "callFee cannot be more than MAX_CALL_FEE");
        callFee = _callFee;
    }

    /**
     * @notice Sets withdraw fee
     * @dev Only callable by the contract admin.
     */
    function setWithdrawFeePerDay(uint256 _withdrawFeePerDay) external onlyAdmin {
        require(_withdrawFeePerDay <= MAX_WITHDRAW_FEE, "withdrawFeePerDay cannot be more than MAX_WITHDRAW_FEE");
        withdrawFeePerDay = _withdrawFeePerDay;
    }

    /**
     * @notice Sets withdraw fee period
     * @dev Only callable by the contract admin.
     */
    function setWithdrawFeePeriod(uint256 _withdrawFeePeriod) external onlyAdmin {
        withdrawFeePeriod = _withdrawFeePeriod;
    }

    /**
     * @notice Withdraws from MasterChef to Vault without caring about rewards.
     * @dev EMERGENCY ONLY. Only callable by the contract admin.
     */
    function emergencyWithdraw() external onlyAdmin {
        IMasterChef(masterchef).emergencyWithdraw(0);
    }

    /**
     * @notice Withdraw unexpected tokens sent to the Cake Vault
     */
    function inCaseTokensGetStuck(address _token) external onlyAdmin {
        require(_token != address(token), "Token cannot be same as deposit token");
        require(_token != address(receiptToken), "Token cannot be same as receipt token");

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Triggers stopped state
     * @dev Only possible when contract not paused.
     */
    function pause() external onlyAdmin whenNotPaused {
        _pause();
        emit Pause();
    }

    /**
     * @notice Returns to normal state
     * @dev Only possible when contract is paused.
     */
    function unpause() external onlyAdmin whenPaused {
        _unpause();
        emit Unpause();
    }

    /**
     * @notice Calculates the expected harvest reward from third party
     * @return Expected reward to collect in CAKE
     */
    function calculateHarvestCakeRewards() external view returns (uint256) {
        uint256 amount = IMasterChef(masterchef).pendingCake(0, address(this));
        amount = amount.add(available());
        uint256 currentCallFee = amount.mul(callFee).div(10000);

        return currentCallFee;
    }

    /**
     * @notice Calculates the total pending rewards that can be restaked
     * @return Returns total pending cake rewards
     */
    function calculateTotalPendingCakeRewards() external view returns (uint256) {
        uint256 amount = IMasterChef(masterchef).pendingCake(0, address(this));
        amount = amount.add(available());

        return amount;
    }

    function calculateTotalPendingReferralRewards() external view returns (uint256) {
        uint currentAmount = ((balanceOf().mul(TotalReferralShares)).div(totalShares)).sub(totalReferralRewardClaimed);
        return currentAmount;
    }

    function calculateReferralRewardForParent(address _parent) external view returns (uint256) {
        ParentInfo storage parent = parentInfo[_parent];

        if (parent.shares.mul(getPricePerFullShare()) < parent.lastRewardClaimed){
            return 0;
        }
        uint currentDebt = (parent.shares.mul(getPricePerFullShare())).sub(parent.lastRewardClaimed);
        return currentDebt;
    }

    /**
     * @notice Calculates the price per share
     */
    function getPricePerFullShare() public view returns (uint256) {
        return totalShares == 0 ? 1e18 : balanceOf().mul(1e18).div(totalShares);
    }

    /**
     * @notice Withdraws from funds from the Cake Vault
     * @param _shares: Number of shares to withdraw
     */
    function withdraw(uint256 _shares) public notContract {
        UserInfo storage user = userInfo[msg.sender];
        require(_shares > 0, "Nothing to withdraw");
        require(_shares <= user.shares, "Withdraw amount exceeds balance");

        if(ref.hasReferrer(msg.sender)){
            address parent = getParent(msg.sender);
            claimParentReward(parent, _shares, true);
        }

        uint256 currentAmount = (balanceOf().mul(_shares)).div(totalShares);
        user.shares = user.shares.sub(_shares);
        totalShares = totalShares.sub(_shares);


        // This part is making the withdraw fail

        uint256 bal = available();
        if (bal < currentAmount) {
            uint256 balWithdraw = currentAmount.sub(bal);
            IMasterChef(masterchef).leaveStaking(balWithdraw);
            uint256 balAfter = available();
            uint256 diff = balAfter.sub(bal);
            if (diff < balWithdraw) {
                currentAmount = bal.add(diff);
            }
        }

        if (block.timestamp < user.lastDepositedTime.add(withdrawFeePeriod)) {
            uint256 currentWithdrawFee = calculateWithdrawFee(user.lastDepositedTime, block.timestamp, currentAmount);
            token.safeTransfer(treasury, currentWithdrawFee);
            currentAmount = currentAmount.sub(currentWithdrawFee);
        }

        if (block.timestamp > user.lastDepositedTime.add(withdrawFeePeriod)) {
            uint256 currentWithdrawFee = currentAmount.mul(MAX_WITHDRAW_FEE).div(10000);
            totalFeeAvailable = totalFeeAvailable.add(currentWithdrawFee);
            token.safeTransfer(treasury, currentWithdrawFee);
            currentAmount = currentAmount.sub(currentWithdrawFee);
        }

        if (user.shares > 0) {
            user.cakeAtLastUserAction = user.shares.mul(balanceOf()).div(totalShares);
        } else {
            user.cakeAtLastUserAction = 0;
        }

        user.lastUserActionTime = block.timestamp;

        token.safeTransfer(msg.sender, currentAmount);

        emit Withdraw(msg.sender, currentAmount, _shares);
    }

    function setDepositTax(uint _tax) external {
        depositTax = _tax;
    }

    /**
     * @notice Custom logic for how much the vault allows to be borrowed
     * @dev The contract puts 100% of the tokens to work.
     */
    function available() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @notice Calculates the total underlying tokens
     * @dev It includes tokens held by the contract and held in MasterChef
     */
    function balanceOf() public view returns (uint256) {
        (uint256 amount, ) = IMasterChef(masterchef).userInfo(0, address(this));
        return token.balanceOf(address(this)).add(amount);
    }

    /**
     * @notice Deposits tokens into MasterChef to earn staking rewards
     */
    function _earn() internal {
        uint256 bal = available();
        if (bal > 0) {
            IMasterChef(masterchef).enterStaking(bal);
        }
    }

    /**
     * @notice Checks if address is a contract
     * @dev It prevents contract from being targetted
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}