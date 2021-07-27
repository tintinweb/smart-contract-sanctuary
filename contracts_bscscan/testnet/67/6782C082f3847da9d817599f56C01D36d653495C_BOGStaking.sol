/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-01
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * $$$$$$$\                   $$$$$$$$\                  $$\
 * $$  __$$\                  \__$$  __|                 $$ |
 * $$ |  $$ | $$$$$$\   $$$$$$\  $$ | $$$$$$\   $$$$$$\  $$ | $$$$$$$\
 * $$$$$$$\ |$$  __$$\ $$  __$$\ $$ |$$  __$$\ $$  __$$\ $$ |$$  _____|
 * $$  __$$\ $$ /  $$ |$$ /  $$ |$$ |$$ /  $$ |$$ /  $$ |$$ |\$$$$$$\
 * $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |$$ |  $$ |$$ |  $$ |$$ | \____$$\
 * $$$$$$$  |\$$$$$$  |\$$$$$$$ |$$ |\$$$$$$  |\$$$$$$  |$$ |$$$$$$$  |
 * \_______/  \______/  \____$$ |\__| \______/  \______/ \__|\_______/
 *                     $$\   $$ |
 *                     \$$$$$$  |
 *                      \______/
 *
 * BogTools / Bogged Finance
 * https://bogtools.io/
 * https://bogged.finance/
 * Telegram: https://t.me/bogtools
 */

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * Provides ownable & authorized contexts
 */
abstract contract BOGAuth {
    address owner;
    mapping (address => bool) private authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender)); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender)); _;
    }

    /**
     * Authorize address. Any authorized address
     */
    function authorize(address adr) public authorized {
        authorizations[adr] = true;
        emit Authorized(adr);
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
        emit Unauthorized(adr);
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner.
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
    event Authorized(address adr);
    event Unauthorized(address adr);
}

abstract contract BOGPausable is BOGAuth {
    bool public paused;

    modifier whenPaused() {
        require(paused || isAuthorized(msg.sender)); _;
    }

    modifier notPaused() {
        require(!paused || isAuthorized(msg.sender)); _;
    }

    function pause() external notPaused authorized {
        paused = true;
        emit Paused();
    }

    function unpause() public whenPaused authorized {
        paused = false;
        emit Unpaused();
    }

    event Paused();
    event Unpaused();
}

abstract contract BOGFinalizable is BOGAuth {
    bool public isFinalized;

    modifier unfinalized() {
        require(!isFinalized, "FINALIZED"); _;
    }

    modifier finalized() {
        require(isFinalized, "!FINALIZED"); _;
    }

    function finalize() public authorized unfinalized {
        isFinalized = true;
        emit Finalized();
    }

    event Finalized();
}

interface IBOGMigrationData {
    function totalHolders() external view returns (uint256);
    function totalBalances() external view returns (uint256);
    function totalStakes() external view returns (uint256);
    
    function getInfo(address holder) external view returns (bool migrated, uint256 stake, uint256 balance, bool preExploitHolder);
    
    function hasBeenMigrated(address holder) external view returns (bool);
    function getBalance(address holder) external view returns (uint256);
    function getStake(address holder) external view returns (uint256);
    function isPreExploitHolder(address holder) external view returns (bool);
}

interface IBOGStaking {
    function stakingToken() external view returns (address);
    function rewardToken() external view returns (address);
    
    function totalStaked() external view returns (uint256);
    function totalRealised() external view returns (uint256);

    function getTotalRewards() external view returns (uint256);

    function getCumulativeRewardsPerLP() external view returns (uint256);
    function getLastContractBalance() external view returns (uint256);
    function getAccuracyFactor() external view returns (uint256);

    function getStake(address staker) external view returns (uint256);
    function getRealisedEarnings(address staker) external returns (uint256);
    function getUnrealisedEarnings(address staker) external view returns (uint256);

    function stake(uint256 amount) external;
    function stakeFor(address staker, uint256 amount) external;
    function stakeAll() external;

    function unstake(uint256 amount) external;
    function unstakeAll() external;
    
    function realise() external;

    event Realised(address account, uint amount);
    event Staked(address account, uint amount);
    event Unstaked(address account, uint amount);
}

contract BOGStaking is BOGAuth, BOGPausable, BOGFinalizable, IBOGStaking {
    using SafeMath for uint256;

    struct Stake {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address public override stakingToken;
    address public override rewardToken;

    uint256 public override totalRealised;
    uint256 public override totalStaked;

    mapping (address => Stake) public stakes;

    constructor (address _stakingToken, address _rewardToken) BOGAuth(msg.sender) {
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        finalize();
    }

    uint256 _accuracyFactor = 10 ** 36;
    uint256 _rewardsPerLP;
    uint256 _lastContractBalance;

    /**
     * Total rewards realised and to be realised
     */
    function getTotalRewards() external override view  returns (uint256) {
        return totalRealised + IBEP20(rewardToken).balanceOf(address(this));
    }

    /**
     * Total rewards per LP cumulatively, inflated by _accuracyFactor
     */
    function getCumulativeRewardsPerLP() external override view returns (uint256) {
        return _rewardsPerLP;
    }

    /**
     * The last balance the contract had
     */
    function getLastContractBalance() external override view returns (uint256) {
        return _lastContractBalance;
    }

    /**
     * Total amount of transaction fees sent or to be sent to stakers
     */
    function getAccuracyFactor() external override view returns (uint256) {
        return _accuracyFactor;
    }

    /**
     * Returns amount of LP that address has staked
     */
    function getStake(address account) public override view returns (uint256) {
        return stakes[account].amount;
    }

    /**
     * Returns total earnings (realised + unrealised)
     */
    function getRealisedEarnings(address staker) external view override returns (uint256) {
        return stakes[staker].totalRealised; // realised gains plus outstanding earnings
    }

    /**
     * Returns unrealised earnings
     */
    function getUnrealisedEarnings(address staker) external view override returns (uint256) {
        if(stakes[staker].amount == 0){ return 0; }

        uint256 stakerTotalRewards = stakes[staker].amount.mul(getCurrentRewardsPerLP()).div(_accuracyFactor);
        uint256 stakerTotalExcluded = stakes[staker].totalExcluded;

        if(stakerTotalRewards <= stakerTotalExcluded){ return 0; }

        return stakerTotalRewards.sub(stakerTotalExcluded);
    }

    function getCumulativeRewards(uint256 amount) public view returns (uint256) {
        return amount.mul(_rewardsPerLP).div(_accuracyFactor);
    }

    function stake(uint amount) external override {
        require(amount > 0);

        IBEP20(stakingToken).transferFrom(msg.sender, address(this), amount);

        _stake(msg.sender, amount);
    }

    function stakeFor(address staker, uint256 amount) external override {
        require(amount > 0);

        IBEP20(stakingToken).transferFrom(msg.sender, address(this), amount);

        _stake(staker, amount);
    }

    function stakeAll() external override {
        uint256 amount = IBEP20(stakingToken).balanceOf(msg.sender);
        require(amount > 0);

        IBEP20(stakingToken).transferFrom(msg.sender, address(this), amount);

        _stake(msg.sender, amount);
    }

    function unstake(uint amount) external override {
        require(amount > 0);

        _unstake(msg.sender, amount);
    }

    function unstakeAll() external override {
        uint256 amount = getStake(msg.sender);
        require(amount > 0);

        _unstake(msg.sender, amount);
    }

    function realise() external override notPaused {
        _realise(msg.sender);
    }

    function _realise(address staker) internal {
        _updateRewards();

        uint amount = earnt(staker);

        if (getStake(staker) == 0 || amount == 0) {
            return;
        }

        stakes[staker].totalRealised = stakes[staker].totalRealised.add(amount);
        stakes[staker].totalExcluded = stakes[staker].totalExcluded.add(amount);
        totalRealised = totalRealised.add(amount);

        IBEP20(rewardToken).transfer(staker, amount);

        _updateRewards();

        emit Realised(staker, amount);
    }

    function earnt(address staker) internal view returns (uint256) {
        if(stakes[staker].amount == 0){ return 0; }

        uint256 stakerTotalRewards = getCumulativeRewards(stakes[staker].amount);
        uint256 stakerTotalExcluded = stakes[staker].totalExcluded;

        if(stakerTotalRewards <= stakerTotalExcluded){ return 0; }

        return stakerTotalRewards.sub(stakerTotalExcluded);
    }

    function _stake(address staker, uint256 amount) internal notPaused {
        require(amount > 0);

        _realise(staker);

        // add to current address' stake
        stakes[staker].amount = stakes[staker].amount.add(amount);
        stakes[staker].totalExcluded = getCumulativeRewards(stakes[staker].amount);
        totalStaked = totalStaked.add(amount);

        emit Staked(staker, amount);
    }

    function _unstake(address staker, uint256 amount) internal notPaused {
        require(stakes[staker].amount >= amount, "Insufficient Stake");

        _realise(staker); // realise staking gains

        // remove stake
        stakes[staker].amount = stakes[staker].amount.sub(amount);
        stakes[staker].totalExcluded = getCumulativeRewards(stakes[staker].amount);
        totalStaked = totalStaked.sub(amount);

        IBEP20(stakingToken).transfer(staker, amount);

        emit Unstaked(staker, amount);
    }

    function _updateRewards() internal  {
        uint tokenBalance = IBEP20(rewardToken).balanceOf(address(this));

        if(tokenBalance > _lastContractBalance && totalStaked != 0) {
            uint256 newRewards = tokenBalance.sub(_lastContractBalance);
            uint256 additionalAmountPerLP = newRewards.mul(_accuracyFactor).div(totalStaked);
            _rewardsPerLP = _rewardsPerLP.add(additionalAmountPerLP);
        }
        
        if(totalStaked > 0){ _lastContractBalance = tokenBalance; }
    }

    function getCurrentRewardsPerLP() public view returns (uint256 currentRewardsPerLP) {
        uint tokenBalance = IBEP20(rewardToken).balanceOf(address(this));
        if(tokenBalance > _lastContractBalance && totalStaked != 0){
            uint256 newRewards = tokenBalance.sub(_lastContractBalance);
            uint256 additionalAmountPerLP = newRewards.mul(_accuracyFactor).div(totalStaked);
            currentRewardsPerLP = _rewardsPerLP.add(additionalAmountPerLP);
        }
    }

    function setAccuracyFactor(uint256 newFactor) external authorized {
        _rewardsPerLP = _rewardsPerLP.mul(newFactor).div(_accuracyFactor); // switch _rewardsPerLP to be inflated by the new factor instead
        _accuracyFactor = newFactor;
    }

    function emergencyUnstakeAll() external {
        require(stakes[msg.sender].amount > 0, "No Stake");

        IBEP20(stakingToken).transfer(msg.sender, stakes[msg.sender].amount);
        totalStaked = totalStaked.sub(stakes[msg.sender].amount);
        stakes[msg.sender].amount = 0;
    }

    function migrateStakingToken(address newToken) external authorized unfinalized {
        IBEP20(newToken).transferFrom(msg.sender, address(this), totalStaked);
        assert(IBEP20(newToken).balanceOf(address(this)) == totalStaked);

        IBEP20(stakingToken).transfer(msg.sender, totalStaked);
        
        stakingToken = newToken;

        finalize();
    }
}