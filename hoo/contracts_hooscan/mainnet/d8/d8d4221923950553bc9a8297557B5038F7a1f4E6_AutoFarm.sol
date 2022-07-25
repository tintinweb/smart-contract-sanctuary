pragma solidity >=0.8.9;

import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IMasterchef.sol";
import "./ICosmicDelegator.sol";
import "./gWDT.sol";

// Cosmic farm that distributes multiple tokens to users.
// If Cosmis farm has same earning token with staking, it can be auto compounded.

// Cosmic farms initially starts with auto-compounded Token pool. 
// Users will stake to get a share from this pool.
// All stakers will earn other tokens from delegators related from their shares.

contract AutoFarm is Ownable, Pausable {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_PERFORMANCE_FEE = 500; // 5%
    uint256 public constant MAX_CALL_FEE = 100; // 1%
    uint256 public constant MAX_WITHDRAW_FEE = 100; // 1%
    uint256 public constant MAX_WITHDRAW_FEE_PERIOD = 72 hours; // 3 days

    uint256 public performanceFee = 200; // 2%
    uint256 public callFee = 10; // 0.25%
    uint256 public withdrawFee = 10; // 0.1%
    uint256 public withdrawFeePeriod = 72 hours; // 3 days
    mapping(address => bool) public isExcludedFromCallFee; // we dont really want to front-run bots get all call fees.

    IERC20 public stakingToken;
    IMasterchef public immutable Masterchef; 


    mapping(address => UserInfo) public userInfo;
    struct UserInfo {
        uint256 shares; // number of shares for a user
        uint256 lastDepositedTime; // keeps track of deposited time for potential penalty
        uint256 tokenAtLastUserAction; // keeps track of cake deposited at the last user action
        uint256 lastUserActionTime; // keeps track of the last user action time
        uint256 lastDepositBlock; // we assume that user entered farm at this point
    }

    CosmicDelegator[] public delegators; // delegators have their own earn mechanisms seperated from cosmic farm.

    struct CosmicDelegator {
        ICosmicDelegator delegator;
        bool isActive;
    }

    struct DelegatorEarning {
        IERC20 token;
        uint256 amount;
    }

    uint256 public totalShares;
    uint256 public lastHarvestedTime;

    gWDTToken public gWDT;

    address public admin;
    address public treasury; // fee address

    uint256 public constant MAXIMUM_FEE_BP = 1000; // %10
    uint256 public depositFeeBP; // deposit fee
    uint256 public minDeposit;
    uint256 public poolId; // pool id of $TOKEN farm.
    // this address should be excluded from $TOKEN fees to working properly.

    bool public disableDelegators = false;

    constructor(IERC20 _stakingToken, IMasterchef _masterchef, gWDTToken _govToken, address _treasury, uint256 _depositFee, uint256 _minDeposit, uint256 _poolId) {
        stakingToken = _stakingToken;
        Masterchef = _masterchef;
        depositFeeBP = _depositFee;
        treasury = _treasury;
        minDeposit = _minDeposit;
        poolId = _poolId;

        gWDT = _govToken;

        IERC20(_stakingToken).safeApprove(address(_masterchef), type(uint256).max);
    }


    function deposit(uint256 _amount) public whenNotPaused notContract{
        require(_amount > minDeposit, "Too low deposit");

        uint256 pool = balanceOf();

        uint256 beforeBalance = stakingToken.balanceOf(address(this));
        stakingToken.transferFrom(msg.sender, address(this), _amount); // there wont be any transfer fee for cosmic farms
        uint256 afterBalance = stakingToken.balanceOf(address(this));

        require((afterBalance - beforeBalance) == _amount, "Disable transfer fee operator.");

        uint256 fee = 0;
        if(depositFeeBP > 0) {
            fee = (_amount * depositFeeBP) / 10000;
            stakingToken.transfer(treasury, fee);
            _amount = _amount - fee;
        }
        
        uint256 currentShares = 0;
        if (totalShares != 0) {
            currentShares = (_amount * totalShares) / pool;
        } else {
            currentShares = _amount;
        }

        gWDT.mint(msg.sender, currentShares);

        UserInfo storage user = userInfo[msg.sender];

        user.shares = user.shares + (currentShares);
        user.lastDepositedTime = block.timestamp;
        user.lastDepositBlock = block.number; // will be used at delegators.

        totalShares = totalShares + (currentShares);

        user.tokenAtLastUserAction = (user.shares * balanceOf()) / totalShares;
        user.lastUserActionTime = block.timestamp;

        _earn();

        emit Deposit(msg.sender, _amount, currentShares, block.timestamp);
    }

    /**
     * @notice Reinvests CAKE tokens into MasterChef
     * @dev Only possible when contract not paused.
     */
     function harvest() external notContract whenNotPaused {
        //IMasterChef(masterchef).leaveStaking(0);
        Masterchef.withdraw(poolId, 0);
        uint256 bal = available();

        uint256 currentPerformanceFee = (bal * performanceFee) / 10000;
        stakingToken.safeTransfer(treasury, currentPerformanceFee);

        uint256 currentCallFee = 0;
        if(isExcludedFromCallFee[msg.sender] == false) {
            currentCallFee = (bal * callFee) / 10000;
            stakingToken.safeTransfer(msg.sender, currentCallFee);
        }

        _earn();

        lastHarvestedTime = block.timestamp;

        emit Harvest(msg.sender, currentPerformanceFee, currentCallFee);
    }

    function withdrawAll() external notContract {
        withdraw(userInfo[msg.sender].shares);
    }
        /**
     * @notice Calculates the expected harvest reward from third party
     * @return Expected reward to collect in CAKE
     */
     function calculateHarvestCakeRewards() external view returns (uint256) {
        /*
        uint256 amount = IMasterChef(masterchef).pendingCake(0, address(this));
        amount = amount.add(available());
        uint256 currentCallFee = amount.mul(callFee).div(10000);
        */
        uint256 amount = Masterchef.pendingToken(poolId, address(this));
        amount = amount + available();
        uint256 currentCallFee = (amount * callFee) / 10000;
        return currentCallFee;
    }

    /**
     * @notice Calculates the total pending rewards that can be restaked
     * @return Returns total pending token rewards
     */
    function calculateTotalPendingTokenRewards() external view returns (uint256) {
        uint256 amount = Masterchef.pendingToken(poolId, address(this));
        amount = amount + available();

        return amount;
    }

    /**
     * @notice Calculates the price per share
     */
    function getPricePerFullShare() external view returns (uint256) {
        return totalShares == 0 ? 1e18 : (balanceOf() * (1e18)) / (totalShares);
    }

    /**
     * @notice Withdraws from funds from the Cake Vault
     * @param _shares: Number of shares to withdraw
     */
    function withdraw(uint256 _shares) public notContract {
        UserInfo storage user = userInfo[msg.sender];
        require(_shares > 0, "Nothing to withdraw");
        require(_shares <= user.shares, "Withdraw amount exceeds balance");

        uint256 currentAmount = (balanceOf() * _shares) / totalShares;
        user.shares = user.shares - _shares;
        totalShares = totalShares - _shares;

        uint256 bal = available();
        if (bal < currentAmount) {
            uint256 balWithdraw = currentAmount - (bal);
            // IMasterChef(masterchef).leaveStaking(balWithdraw);
            Masterchef.withdraw(poolId, balWithdraw);
            uint256 balAfter = available();
            uint256 diff = balAfter - (bal);
            if (diff < balWithdraw) {
                currentAmount = bal + (diff);
            }
        }

        if (block.timestamp < user.lastDepositedTime + (withdrawFeePeriod)) {
            uint256 currentWithdrawFee = (currentAmount * withdrawFee) / (10000);
            stakingToken.safeTransfer(treasury, currentWithdrawFee);
            currentAmount = currentAmount - (currentWithdrawFee);
        }

        if (user.shares > 0) {
            user.tokenAtLastUserAction = (user.shares * balanceOf()) / (totalShares);
        } else {
            user.tokenAtLastUserAction = 0;
        }

        gWDT.burn(msg.sender, _shares);

        user.lastUserActionTime = block.timestamp;

        stakingToken.safeTransfer(msg.sender, currentAmount);

        emit Withdraw(msg.sender, currentAmount, _shares);
    }

    function harvestUserRewardsFromDelegators() public notContract {
        // harvests user funds on delegators
        UserInfo storage user = userInfo[msg.sender];
        for(uint i = 0; i < delegators.length; i++) {
            CosmicDelegator storage delegator = delegators[i];
            if(delegator.isActive) {
                delegator.delegator.harvestUserReward(msg.sender, user.lastDepositBlock, totalShares, user.shares);
            }
        }
    }

    /**
     * @notice Calculates the total underlying tokens
     * @dev Tüm STAKING TOKEN balanceını dönsün. Delegatorler looplanması lazım.
     */
    function balanceOf() public view returns (uint256) {
        //(uint256 amount, ) = IMasterChef(masterchef).userInfo(0, address(this));
        (uint256 amount,,,) = IMasterchef(Masterchef).userInfo(poolId,address(this));
        return stakingToken.balanceOf(address(this)) + amount;
    }

    function available() public view returns (uint256) {
        return stakingToken.balanceOf(address(this));
    }

    // return pending reward with delegator index
    function userPendingRewardOnDelegator(address _user, uint _index) public view returns(uint256) {
        if(_index > delegators.length && _user == address(0)) {
            return 0;
        }
        CosmicDelegator storage delegator = delegators[_index];
        UserInfo storage user = userInfo[_user];

        uint256 userReward = delegator.delegator.pendingReward(_user, user.lastDepositBlock, totalShares, user.shares);

        return userReward;
    }
    // return token contracts
    function earningTokens() public view returns(IERC20[] memory) {
        IERC20[] memory tokens;
        tokens[0] = stakingToken;
        uint index = 1;
        if(delegators.length > 0) {
            for(uint i = 1; i <= delegators.length; i++) {
                CosmicDelegator storage _delegator = delegators[i];
                (uint256 rewardStart, uint256 rewardEnd) = _delegator.delegator.getRewardBlocks();
                IERC20 rewardToken = _delegator.delegator.getRewardToken();
                if(_delegator.isActive && rewardStart <= block.number && rewardEnd > block.number) {
                    tokens[index] = rewardToken;
                    index = index + 1;
                }
            }
        }

        return tokens;
    }

    function userPendingRewardOnDelegators(address _user) public view returns(DelegatorEarning[] memory) {
        UserInfo storage user = userInfo[_user];
        DelegatorEarning[] memory earnings = new DelegatorEarning[](delegators.length);
        if(_user == address(0)) {
            return earnings;
        }
        for(uint i = 0; i < delegators.length; i++) {
            CosmicDelegator storage _delegator = delegators[i];
            if(_delegator.isActive) {
                uint256 userPending = _delegator.delegator.pendingReward(_user, user.lastDepositBlock, totalShares, user.shares);
                IERC20 rewardToken = _delegator.delegator.getRewardToken();
                earnings[i].token = rewardToken;
                earnings[i].amount = userPending;
            }
        }

        return earnings;
    }

    // return total token earned by delegator
    function delegatorEarnings() public view returns(DelegatorEarning[] memory) {
        DelegatorEarning[] memory earnings = new DelegatorEarning[](delegators.length);
        for(uint i = 0; i < delegators.length; i++) {
            CosmicDelegator storage _delegator = delegators[i];
            if(_delegator.isActive) {
                IERC20 rewardToken = _delegator.delegator.getRewardToken();
                uint256 earned = _delegator.delegator.getTotalEarning();
                earnings[i].token = rewardToken;
                earnings[i].amount = earned;
            }
        }

        return earnings;
    }

    function _earn() internal {
        // This function always called after deposit & harvest.
        // We will also call our delegators here.
        uint256 bal = available();
        
        if (bal > 0) {
            IMasterchef(Masterchef).deposit(poolId, bal);
        }
        if(!disableDelegators) {
            _compoundDelegators();
        }
    }

    function _compoundDelegators() internal {
        for(uint i = 0; i< delegators.length; i++) {
            CosmicDelegator storage _delegator = delegators[i];
            if(_delegator.isActive) {
                _delegator.delegator.updateDelegator();
            }
        }
    }

    /// OWNER FUNCTIONS

    function addDelegator(ICosmicDelegator _delegator, bool _start) public onlyOwner { // Delegator will be token distributor. Staking tokens should be approved if it TOKEN farm
        //approve unutma
        require(address(_delegator) != address(0), "delegator zero");

        delegators.push(CosmicDelegator({
            delegator : _delegator,
            isActive : _start
        }));
        
    }

    function setActivationDelegator(uint _index, bool _value) public onlyOwner {
        CosmicDelegator storage delegator = delegators[_index];
        delegator.isActive = _value;
    }

    function removeDelegator(uint _index) public onlyOwner {
        // deletes delegator
        delete delegators[_index];

        emit DelegatorRemoved(_index);
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
    function setWithdrawFee(uint256 _withdrawFee) external onlyAdmin {
        require(_withdrawFee <= MAX_WITHDRAW_FEE, "withdrawFee cannot be more than MAX_WITHDRAW_FEE");
        withdrawFee = _withdrawFee;
    }

    /**
     * @notice Sets withdraw fee period
     * @dev Only callable by the contract admin.
     */
    function setWithdrawFeePeriod(uint256 _withdrawFeePeriod) external onlyAdmin {
        require(
            _withdrawFeePeriod <= MAX_WITHDRAW_FEE_PERIOD,
            "withdrawFeePeriod cannot be more than MAX_WITHDRAW_FEE_PERIOD"
        );
        withdrawFeePeriod = _withdrawFeePeriod;
    }

    /// EMERGENCY

        /**
     * @notice Withdraws from MasterChef to Vault without caring about rewards.
     * @dev EMERGENCY ONLY. Only callable by the contract admin.
     */
    function emergencyWithdraw() external onlyAdmin {
        Masterchef.emergencyWithdraw(poolId);
    }
    /**
     * @notice Withdraw unexpected tokens sent to the Cake Vault
     */
    function inCaseTokensGetStuck(address _token) external onlyAdmin {
        require(_token != address(stakingToken), "Token cannot be same as deposit token");

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    function setDisableDelegators(bool _value) external onlyAdmin {
        disableDelegators = _value;
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


    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "admin: wut?");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    event Deposit(address indexed sender, uint256 amount, uint256 shares, uint256 lastDepositedTime);
    event Withdraw(address indexed sender, uint256 amount, uint256 shares);
    event Harvest(address indexed sender, uint256 performanceFee, uint256 callFee);
    event Pause();
    event Unpause();
    event DelegatorAdded();
    event DelegatorRemoved(uint index);
}