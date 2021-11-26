// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IBrincGovToken is IERC20Upgradeable {
    function mint(address _to, uint256 _amount) external;

    function mintToTreasury(uint256 _amount) external;

    function getTreasuryOwner() external view returns (address);
}

interface IStakedBrincGovToken {
    function mint(address _to, uint256 _amount) external;

    function burnFrom(address _to, uint256 _amount) external;
}

// BrincStaking is the contract in which the Brinc token can be staked to earn
// Brinc governance tokens as rewards.
//
// Note that it's ownable and the owner wields tremendous power. Staking will
// governable in the future with the Brinc Governance token.

contract BrincStaking is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IBrincGovToken;
    // Stake mode
    enum StakeMode {MODE1, MODE2, MODE3, MODE4, MODE5, MODE6}
    // Info of each user.
    struct UserInfo {
        uint256 brcStakedAmount; // Amount of BRC tokens the user will stake.
        uint256 gBrcStakedAmount; // Amount of gBRC tokens the user will stake.
        uint256 blockNumber; // Stake block number.
        uint256 rewardDebt; // Receivable reward. See explanation below.
        StakeMode mode; // Stake mode

        // We do some fancy math here. Basically, any point in time, the amount of govBrinc tokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.brcStakedAmount * accGovBrincPerShare) - user.rewardDebt
        //   rewardDebt = staked rewards for a user 

        // Whenever a user deposits or withdraws LP tokens to a pool. The following happens:
        //   1. The pool's `accGovBrincPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        uint256 supply; // Weighted balance of Brinc tokens in the pool
        uint256 lockBlockCount; // Lock block count
        uint256 weight; // Weight for the pool
        uint256 accGovBrincPerShare; // Accumulated govBrinc tokens per share, times 1e12. See below.
        bool brcOnly;
    }

    // Last block number that govBrinc token distribution occurs.
    uint256 lastRewardBlock;

    // The Brinc TOKEN!
    IERC20Upgradeable public brincToken;
    // The governance Brinc TOKEN!
    IBrincGovToken public govBrincToken;
    // The staked governance Brinc TOKEN!
    IStakedBrincGovToken public stakedGovBrincToken;
    // govBrinc tokens created per block.
    uint256 public govBrincPerBlock;
    // Info of each pool.
    mapping(StakeMode => PoolInfo) public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo[]) public userInfo;

    // ratioBrcToGov is the ratio of Brinc to govBrinc tokens needed to stake
    uint256 public ratioBrcToGov;
    // gBrcStakeAmount = brc * ratio / 1e10

    // treasuryRewardBalance is the number of tokens awarded to the treasury address
    // this is implemented this way so that the treasury address will be responsible for paying for the minting of rewards.
    uint256 public treasuryRewardBalance;

    // paused indicates whether staking is paused.
    // when paused, the staking pools will not update, nor will any gov tokens be minted.
    bool public paused;
    // pausedBlock is the block number that pause was started.
    // 0 if not paused.
    uint256 public pausedBlock;

    event Deposit(address indexed user, uint256 amount, StakeMode mode);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event TreasuryMint(uint256 amount);

    event LockBlockCountChanged(
        StakeMode mode,
        uint256 oldLockBlockCount,
        uint256 newLockBlockCount
    );
    event WeightChanged(
        StakeMode mode,
        uint256 oldWeight,
        uint256 newWeight
    );
    event GovBrincPerBlockChanged(
        uint256 oldGovBrincPerBlock,
        uint256 newGovBrincPerBlock
    );
    event RatioBrcToGovChanged(
        uint256 oldRatioBrcToGov, 
        uint256 newRatioBrcToGov
    );

    event Paused();
    event Resumed();

    function initialize(
        IERC20Upgradeable _brincToken,
        IBrincGovToken _brincGovToken,
        IStakedBrincGovToken _stakedGovBrincToken,
        uint256 _govBrincPerBlock,
        uint256 _ratioBrcToGov
    ) initializer public {
        brincToken = _brincToken;
        govBrincToken = _brincGovToken;
        stakedGovBrincToken = _stakedGovBrincToken;
        govBrincPerBlock = _govBrincPerBlock;
        lastRewardBlock = block.number;
        ratioBrcToGov = _ratioBrcToGov;
        paused = false;
        pausedBlock = 0;
        poolInfo[StakeMode.MODE1] = PoolInfo({
            supply: 0,
            lockBlockCount: uint256(199384), // 30 days in block count. 1 block = 13 seconds
            weight: 10,
            accGovBrincPerShare: 0,
            // represents the reward amount for each brinc token in the pool
            brcOnly: true
        });
        poolInfo[StakeMode.MODE2] = PoolInfo({
            supply: 0,
            lockBlockCount: uint256(398769), // 60 days in block count. 1 block = 13 seconds
            weight: 15,
            accGovBrincPerShare: 0,
            brcOnly: true
        });
        poolInfo[StakeMode.MODE3] = PoolInfo({
            supply: 0,
            lockBlockCount: uint256(598153), // 90 days in block count. 1 block = 13 seconds
            weight: 25,
            accGovBrincPerShare: 0,
            brcOnly: true
        });
        poolInfo[StakeMode.MODE4] = PoolInfo({
            supply: 0,
            lockBlockCount: uint256(199384), // 30 days in block count. 1 block = 13 seconds
            weight: 80,
            accGovBrincPerShare: 0,
            brcOnly: false
        });
        poolInfo[StakeMode.MODE5] = PoolInfo({
            supply: 0,
            lockBlockCount: uint256(398769), // 60 days in block count. 1 block = 13 seconds
            weight: 140,
            accGovBrincPerShare: 0,
            brcOnly: false
        });
        poolInfo[StakeMode.MODE6] = PoolInfo({
            supply: 0,
            lockBlockCount: uint256(598153), // 90 days in block count. 1 block = 13 seconds
            weight: 256,
            accGovBrincPerShare: 0,
            brcOnly: false
        });

        __Ownable_init();
    }

    modifier isNotPaused {
     require(paused == false, "paused: operations are paused by admin");
     _;
   }

   /**
     * @dev pause the staking contract
     * paused features:
     * - deposit
     * - withdraw
     * - updating pools
     */
    /// #if_succeeds {:msg "pause: paused is true"}
        /// paused == true;
    function pause() public onlyOwner {
        paused = true;
        pausedBlock = block.number;
        emit Paused();
    }

    /**
     * @dev resume the staking contract
     * resumed features:
     * - deposit
     * - withdraw
     * - updating pools
     */
    /// #if_succeeds {:msg "resume: paused is false"}
        /// paused == false;
    function resume() public onlyOwner {
        paused = false;
        pausedBlock = 0;
        emit Resumed();
    }

    /**
     * @dev if paused or not 
     *
     * @return paused
     */
    /// #if_succeeds {:msg "isPaused: returns paused"}
        /// $result == paused;
    function isPaused() public view returns(bool) {
        return paused;
    }

    /**
     * @dev block that pause was called.
     *
     * @return pausedBlock
     */
    /// #if_succeeds {:msg "getPausedBlock: returns PausedBlock"}
        /// $result == pausedBlock;
    function getPausedBlock() public view returns(uint256) {
        return pausedBlock;
    }

    /**
     * @dev last reward block that has been recorded
     *
     * @return lastRewardBlock
     */
    /// #if_succeeds {:msg "getLastRewardBlock: returns lastRewardBlock"}
        /// $result == lastRewardBlock;
    function getLastRewardBlock() public view returns(uint256) {
        return lastRewardBlock;
    }

    /**
     * @dev address of the Brinc token contract 
     *
     * @return Brinc token address
     */
    /// #if_succeeds {:msg "getBrincTokenAddress: returns Brinc Token address"}
        /// $result == address(brincToken);
    function getBrincTokenAddress() public view returns(address) {
        return address(brincToken);
    }

    /**
     * @dev address of the Brinc Governance token contract 
     *
     * @return Brinc Gov token address
     */
    /// #if_succeeds {:msg "getGovTokenAddress: returns Brinc Gov token address"}
        /// $result == address(govBrincToken);
    function getGovTokenAddress() public view returns(address) {
        return address(govBrincToken);
    }

    /**
     * @dev the number of Gov tokens that can be issued per block
     *
     * @return Brinc Gov reward tokens per block
     */
    /// #if_succeeds {:msg "getGovBrincPerBlock: returns Brinc Gov reward tokens per block"}
        /// $result == govBrincPerBlock;
    function getGovBrincPerBlock() public view returns(uint256) {
        return govBrincPerBlock;
    }

    /**
     * @dev The ratio of BRC to gBRC tokens 
     * The ratio dictates the amount of tokens of BRC and gBRC required for staking
     *
     * @return BRC to gBRC ratio required for staking
     */
    /// #if_succeeds {:msg "getRatioBtoG: returns BRC to gBRC ratio required for staking"}
        /// $result == ratioBrcToGov;
    function getRatioBtoG() public view returns(uint256) {
        return ratioBrcToGov;
    }

    /**
     * @dev get specified pool supply
     *
     * @return pool's supply
     */
    /// #if_succeeds {:msg "getPoolSupply: returns pool's supply"}
        /// $result == poolInfo[_mode].supply;
    function getPoolSupply(StakeMode _mode) public view returns(uint256) {
        return poolInfo[_mode].supply;
    }

    /**
     * @dev get specified pool lockBlockCount
     *
     * @return pool's lockBlockCount
     */
    /// #if_succeeds {:msg "getPoolLockBlockCount: returns pool's lockBlockCount"}
        /// $result == poolInfo[_mode].lockBlockCount;
    function getPoolLockBlockCount(StakeMode _mode) public view returns(uint256) {
        return poolInfo[_mode].lockBlockCount;
    }
    
    /**
     * @dev get specified pool weight
     *
     * @return pool's weight
     */
    /// #if_succeeds {:msg "getPoolWeight: returns pool's weight"}
        /// $result == poolInfo[_mode].weight;
    function getPoolWeight(StakeMode _mode) public view returns(uint256) {
        return poolInfo[_mode].weight;
    }

    /**
     * @dev get specified pool accGovBrincPerShare
     *
     * @return pool's accGovBrincPerShare
     */
    /// #if_succeeds {:msg "getPoolAccGovBrincPerShare: returns pool's accGovBrincPerShare"}
        /// $result == poolInfo[_mode].accGovBrincPerShare;
    function getPoolAccGovBrincPerShare(StakeMode _mode) public view returns(uint256) {
        return poolInfo[_mode].accGovBrincPerShare;
    }

    /**
     * @dev get specified user information with correlating index
     * _address will be required to have an active staking deposit.
     * 
     * @return UserInfo
     */
    function getUserInfo(address _address, uint256 _index) public view returns(UserInfo memory) {
        require(userInfo[_address].length > 0, "getUserInfo: user has not made any stakes");
        return userInfo[_address][_index];
    }

    /**
     * @dev gets the number of stakes the user has made.
     * 
     * @return UserStakeCount
     */
    /// #if_succeeds {:msg "getStakeCount: returns user's active stakes"}
        /// $result == userInfo[_msgSender()].length;
    function getStakeCount() public view returns (uint256) {
        return userInfo[_msgSender()].length;
    }

    /**
     * @dev gets the total supply of all the rewards that .
     * totalSupply = ( poolSupply1 * poolWeight1 ) + ( poolSupply2 * poolWeight2 ) + ( poolSupply3 * poolWeight3 )
     *
     * @return total supply of all pools
     */
    /*
    // there is an error: `throw e;`
    // seems to be an issue with the scribble compiler
    /// #if_succeeds {:msg "getTotalSupplyOfAllPools: returns total supply of all pool tokens"}
        /// let pool1 := poolInfo[StakeMode.MODE1].supply.mul(poolInfo[StakeMode.MODE1].weight) in
        /// let pool2 := poolInfo[StakeMode.MODE2].supply.mul(poolInfo[StakeMode.MODE2].weight) in
        /// let pool3 := poolInfo[StakeMode.MODE3].supply.mul(poolInfo[StakeMode.MODE3].weight) in
        /// let pool4 := poolInfo[StakeMode.MODE4].supply.mul(poolInfo[StakeMode.MODE4].weight) in
        /// let pool5 := poolInfo[StakeMode.MODE5].supply.mul(poolInfo[StakeMode.MODE5].weight) in
        /// let pool6 := poolInfo[StakeMode.MODE6].supply.mul(poolInfo[StakeMode.MODE6].weight) in
        /// $result == pool1.add(pool2).add(pool3).add(pool4).add(pool5).add(pool6);
    */
    function getTotalSupplyOfAllPools() private view returns (uint256) {
        uint256 totalSupply;

        totalSupply = totalSupply.add(
            poolInfo[StakeMode.MODE1].supply.mul(poolInfo[StakeMode.MODE1].weight)
        )
        .add(
            poolInfo[StakeMode.MODE2].supply.mul(poolInfo[StakeMode.MODE2].weight)
        )
        .add(
            poolInfo[StakeMode.MODE3].supply.mul(poolInfo[StakeMode.MODE3].weight)
        )
        .add(
            poolInfo[StakeMode.MODE4].supply.mul(poolInfo[StakeMode.MODE4].weight)
        )
        .add(
            poolInfo[StakeMode.MODE5].supply.mul(poolInfo[StakeMode.MODE5].weight)
        )
        .add(
            poolInfo[StakeMode.MODE6].supply.mul(poolInfo[StakeMode.MODE6].weight)
        );

        return totalSupply;
    }

    /**
     * @dev gets the pending rewards of a user.]
     * View function to see pending govBrinc on frontend.
     *
     * formula:
     * reward = multiplier * govBrincPerBlock * pool.supply * pool.weight / totalSupply
     *
     * @return pending reward of a user
     */

    /// #if_succeeds {:msg "pendingRewards: the pending rewards of a given user should be correct - case: maturity has not passed"}
        /// let pendingReward, complete := $result in
        /// userInfo[_user][_id].blockNumber > block.number ==> 
        /// pendingReward == 0 && complete == false;
    /// #if_succeeds {:msg "pendingRewards: the pending rewards of a given user should be correct - case: maturity has passed with no pending rewards"}
        /// let accGovBrincPerShare := old(poolInfo[userInfo[_user][_id].mode].accGovBrincPerShare) in
        /// let totalSupply := old(getTotalSupplyOfAllPools()) in
        /// let multiplier := old(block.number.sub(lastRewardBlock)) in
        /// let govBrincReward := multiplier.mul(govBrincPerBlock).mul(poolInfo[userInfo[_user][_id].mode].supply).mul(poolInfo[userInfo[_user][_id].mode].weight).div(totalSupply) in
        /// let scaled := govBrincReward.mul(1e12).div(poolInfo[userInfo[_user][_id].mode].supply) in
        /// let updatedAccGovBrincPerShare := accGovBrincPerShare.add(scaled) in
        /// let pendingReward, complete := $result in
        /// (block.number > lastRewardBlock) && (poolInfo[userInfo[_user][_id].mode].supply != 0) ==> pendingReward == userInfo[_user][_id].brcStakedAmount.mul(updatedAccGovBrincPerShare).div(1e12).sub(userInfo[_user][_id].rewardDebt) && complete == true;
    /// #if_succeeds {:msg "pendingRewards: the pending rewards of a given user should be correct - case: maturity has passed with pending rewards"}
        /// let accGovBrincPerShare := poolInfo[userInfo[_user][_id].mode].accGovBrincPerShare in
        /// let pendingReward, complete := $result in
        /// (userInfo[_user][_id].blockNumber <= block.number) || (poolInfo[userInfo[_user][_id].mode].supply == 0) ==> pendingReward == userInfo[_user][_id].brcStakedAmount.mul(accGovBrincPerShare).div(1e12).sub(userInfo[_user][_id].rewardDebt) && complete == true;
    function pendingRewards(address _user, uint256 _id) public view returns (uint256, bool) {
        require(_id < userInfo[_user].length, "pendingRewards: invalid stake id");

        UserInfo storage user = userInfo[_user][_id];

        bool withdrawable; // false

        // only withdrawable after the user's stake has passed maturity
        if (block.number >= user.blockNumber) {
            withdrawable = true;
        }

        PoolInfo storage pool = poolInfo[user.mode];
        uint256 accGovBrincPerShare = pool.accGovBrincPerShare;
        uint256 totalSupply = getTotalSupplyOfAllPools();
        if (block.number > lastRewardBlock && pool.supply != 0) {
            uint256 multiplier;
            if (paused) {
                multiplier = pausedBlock.sub(lastRewardBlock);
            } else {
                multiplier = block.number.sub(lastRewardBlock);
            }
            
            uint256 govBrincReward =
                multiplier
                    .mul(govBrincPerBlock)
                    .mul(pool.supply) // supply is the number of staked Brinc tokens
                    .mul(pool.weight)
                    .div(totalSupply);
            accGovBrincPerShare = accGovBrincPerShare.add(
                govBrincReward.mul(1e12).div(pool.supply)
            );
        }
        return
            (user.brcStakedAmount.mul(accGovBrincPerShare).div(1e12).sub(user.rewardDebt), withdrawable);
    }

    function totalRewards(address _user) external view returns (uint256) {
        UserInfo[] storage stakes = userInfo[_user];
        uint256 total;
        for (uint256 i = 0; i < stakes.length; i++) {
            (uint256 reward, bool withdrawable) = pendingRewards(_user, i);
            if (withdrawable) {
                total = total.add(reward);
            }
        }
        return total;
    }

    /**
     * @dev updates the lockBlockCount required for stakers to lock up their stakes for. 
     * This will be taken as seconds but will be converted to blocks by multiplying by the average block time.
     * This can only be called by the owner of the contract.
     * 
     * lock up blocks = lock up time * 13 [avg. block time]
     *
     * @param _updatedLockBlockCount new lock up time
     */
    /// #if_succeeds {:msg "updateLockBlockCount: the sender must be Owner"}
        /// old(msg.sender == this.owner());
    /// #if_succeeds {:msg "updateLockBlockCount: sets lockBlockCount correctly"}
        /// poolInfo[_mode].lockBlockCount == _updatedLockBlockCount;
    function updateLockBlockCount(StakeMode _mode, uint256 _updatedLockBlockCount) public onlyOwner {
        PoolInfo storage pool = poolInfo[_mode];
        uint256 oldLockBlockCount = pool.lockBlockCount;
        pool.lockBlockCount = _updatedLockBlockCount;
        emit LockBlockCountChanged(_mode, oldLockBlockCount, _updatedLockBlockCount);
    }

    /**
     * @dev updates the weight of a specified pool. The mode specified will map to the period 
     *
     * @param _mode period of the pool you wish to update
     * @param _weight new weight
     */
    /// #if_succeeds {:msg "updateWeight: the sender must be Owner"}
        /// old(msg.sender == this.owner());
    /// #if_succeeds {:msg "updateWeight: sets weight correctly"}
        /// poolInfo[_mode].weight == _weight;
    function updateWeight(StakeMode _mode, uint256 _weight) public onlyOwner {
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_mode];
        uint256 oldWeight = pool.weight;
        pool.weight = _weight;
        emit WeightChanged(_mode, oldWeight, _weight);
    }

    /**
     * @dev updates the govBrincPerBlock reward amount that will be issued to the stakers. This can only be called by the owner of the contract.
     *
     * @param _updatedGovBrincPerBlock new reward amount
     */
    /// #if_succeeds {:msg "updateGovBrincPerBlock: the sender must be Owner"}
        /// old(msg.sender == this.owner());
    /// #if_succeeds {:msg "updateGovBrincPerBlock: sets govBrincPerBlock correctly"}
        /// govBrincPerBlock == _updatedGovBrincPerBlock;
    function updateGovBrincPerBlock(uint256 _updatedGovBrincPerBlock) public onlyOwner {
        massUpdatePools();
        uint256 oldGovBrincPerBlock = govBrincPerBlock;
        govBrincPerBlock = _updatedGovBrincPerBlock;
        emit GovBrincPerBlockChanged(oldGovBrincPerBlock, govBrincPerBlock);
    }

    /**
     * @dev updates the ratio of BRC to gBRC tokens required for staking.
     *
     * @param _updatedRatioBrcToGov new ratio of BRC to gBRC for staking
     */
    /// #if_succeeds {:msg "updateRatioBrcToGov: the sender must be Owner"}
        /// old(msg.sender == this.owner());
    /// #if_succeeds {:msg "updateRatioBrcToGov: sets ratioBrcToGov correctly"}
        /// ratioBrcToGov == _updatedRatioBrcToGov;
    function updateRatioBrcToGov(uint256 _updatedRatioBrcToGov) public onlyOwner {
        uint256 oldRatioBrcToGov = ratioBrcToGov;
        ratioBrcToGov = _updatedRatioBrcToGov;
        emit RatioBrcToGovChanged(oldRatioBrcToGov, ratioBrcToGov);
    }

    /**
     * @dev staking owner will call to mint treasury tokens
     * implemented this way so that users will not have to pay for the minting of the treasury tokens
     * when pools are updated
     * the `treasuryBalance` variable is used to keep track of the total number of tokens that the
     * the treasury address will be able to mint at any given time.
     */
    /// #if_succeeds {:msg "treasuryMint: the sender must be Owner"}
        /// old(msg.sender == this.owner());
    function treasuryMint() public onlyOwner {
        require(treasuryRewardBalance > 0, "treasuryMint: not enough balance to mint");
        uint256 balanceToMint;
        balanceToMint = treasuryRewardBalance;
        treasuryRewardBalance = 0;
        govBrincToken.mintToTreasury(balanceToMint);
        emit TreasuryMint(balanceToMint);
    }

    /**
     * @dev updates all pool information.
     *
     * Note Update reward vairables for all pools. Be careful of gas spending!
     */
    /// #if_succeeds {:msg "massUpdatePools: case totalSupply == 0"}
        /// let multiplier := block.number - lastRewardBlock in
        /// let unusedReward := multiplier.mul(govBrincPerBlock) in
        /// getTotalSupplyOfAllPools() > 0 ==> treasuryRewardBalance == old(treasuryRewardBalance) + unusedReward;
    /// #if_succeeds {:msg "massUpdatePools: updates lastRewardBlock"}
        /// lastRewardBlock == block.number;
    function massUpdatePools() internal isNotPaused {
        uint256 totalSupply = getTotalSupplyOfAllPools();
        if (totalSupply == 0) {
            if (block.number > lastRewardBlock) {
                uint256 multiplier = block.number.sub(lastRewardBlock);
                uint256 unusedReward = multiplier.mul(govBrincPerBlock);
                treasuryRewardBalance = treasuryRewardBalance.add(unusedReward);
            }
        } else {
            updatePool(StakeMode.MODE1);
            updatePool(StakeMode.MODE2);
            updatePool(StakeMode.MODE3);
            updatePool(StakeMode.MODE4);
            updatePool(StakeMode.MODE5);
            updatePool(StakeMode.MODE6);
        }
        lastRewardBlock = block.number;
    }

    /**
     * @dev update a given pool. This should be done every time a deposit or withdraw is made. 
     *
     * Note Update reward variables of the given pool to be up-to-date.
     */
    /// #if_succeeds {:msg "updatePool: updates pool's information and mint's reward"}
        /// let totalSupply := getTotalSupplyOfAllPools() in
        /// let multiplier := block.number.sub(lastRewardBlock) in
        /// let govBrincReward := multiplier.mul(govBrincPerBlock).mul(poolInfo[mode].supply).mul(poolInfo[mode].weight).div(totalSupply) in
        /// (block.number > lastRewardBlock) && (poolInfo[mode].supply != 0) ==> 
        /// govBrincToken.balanceOf(address(this)) == govBrincReward && poolInfo[mode].accGovBrincPerShare == poolInfo[mode].accGovBrincPerShare.add(govBrincReward.mul(1e12).div(poolInfo[mode].supply));
    function updatePool(StakeMode mode) internal isNotPaused {
        PoolInfo storage pool = poolInfo[mode];
        if (block.number <= lastRewardBlock) {
            return;
        }
        if (pool.supply == 0) {
            return;
        }
        uint256 totalSupply = getTotalSupplyOfAllPools();
        uint256 multiplier = block.number.sub(lastRewardBlock);
        uint256 govBrincReward =
            multiplier
                .mul(govBrincPerBlock)
                .mul(pool.supply)
                .mul(pool.weight)
                .div(totalSupply);
        govBrincToken.mint(address(this), govBrincReward);
        pool.accGovBrincPerShare = pool.accGovBrincPerShare.add(
            govBrincReward.mul(1e12).div(pool.supply)
        );
    }

    /**
     * @dev a user deposits some Brinc token for a given period. The period will be determined based on the pools.
     * Every time a user deposits any stake, the pool will be updated.
     * The user will only be allowed to deposit Brinc tokens to stake if they deposit the equivalent amount in governance tokens.
     *
     * Note Deposit Brinc tokens to BrincStaking for govBrinc token allocation.
     */
    /// #if_succeeds {:msg "deposit: deposit Brinc token amount is correct"}
        /// poolInfo[_mode].brcOnly == true ==> brincToken.balanceOf(address(this)) == _amount && govBrincToken.balanceOf(address(this)) == old(govBrincToken.balanceOf(address(this)));
    /// #if_succeeds {:msg "deposit: deposit Brinc Gov token amount is correct"}
        /// poolInfo[_mode].brcOnly == false ==> brincToken.balanceOf(address(this)) == _amount && govBrincToken.balanceOf(address(this)) == _amount.mul(ratioBrcToGov).div(1e10);
    /// #if_succeeds {:msg "deposit: successful deposit should update user information correctly"}
        /// let depositNumber := getStakeCount().sub(1) in
        /// depositNumber > 0 ==>
        /// userInfo[msg.sender][depositNumber].brcStakedAmount == _amount && userInfo[msg.sender][depositNumber].blockNumber == block.number.add(poolInfo[_mode].lockBlockCount) && userInfo[msg.sender][depositNumber].rewardDebt == userInfo[msg.sender][depositNumber].brcStakedAmount.mul(poolInfo[_mode].accGovBrincPerShare).div(1e12) && userInfo[msg.sender][depositNumber].mode == _mode;
    /// #if_succeeds {:msg "deposit: pool supply is updated correctly"}
        /// let depositNumber := getStakeCount().sub(1) in
        /// depositNumber > 0 ==>
        /// poolInfo[_mode].supply == old(poolInfo[_mode].supply) + userInfo[msg.sender][depositNumber].brcStakedAmount;
    /// #if_succeeds {:msg "deposit: userInfo array should increment by one"}
        /// userInfo[msg.sender].length == old(userInfo[msg.sender].length) + 1;
    function deposit(uint256 _amount, StakeMode _mode) public {
        require(_amount > 0, "deposit: invalid amount");
        UserInfo memory user;
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_mode];
        brincToken.safeTransferFrom(msg.sender, address(this), _amount);
        user.brcStakedAmount = _amount;
        if (!pool.brcOnly) {
            govBrincToken.safeTransferFrom(
                msg.sender,
                address(this),
                _amount.mul(ratioBrcToGov).div(1e10)
            );
            user.gBrcStakedAmount = _amount.mul(ratioBrcToGov).div(1e10);
            stakedGovBrincToken.mint(msg.sender, user.gBrcStakedAmount);
        }
        user.blockNumber = block.number.add(pool.lockBlockCount);
        user.rewardDebt = user.brcStakedAmount.mul(pool.accGovBrincPerShare).div(1e12);
        user.mode = _mode;

        pool.supply = pool.supply.add(user.brcStakedAmount);
        emit Deposit(msg.sender, _amount, _mode);

        userInfo[msg.sender].push(user);
    }

    /**
     * @dev a user withdraws their Brinc token that they have staked, including their rewards.
     * Every time a user withdraws their stake, the pool will be updated.
     *
     * Note Withdraw Brinc tokens from BrincStaking.
     */
    /// #if_succeeds {:msg "withdraw: token deducted from staking contract correctly"}
        /// let depositNumber := getStakeCount().sub(1) in
        /// let _amount := userInfo[msg.sender][depositNumber].brcStakedAmount in
        /// depositNumber > 0 ==>
        /// old(brincToken.balanceOf(address(this))) == brincToken.balanceOf(address(this)) - _amount;
    /// #if_succeeds {:msg "withdraw: user's withdrawn Brinc token amount is correct"}
        /// let depositNumber := getStakeCount().sub(1) in
        /// let _amount := userInfo[msg.sender][depositNumber].brcStakedAmount in
        /// depositNumber > 0 ==>
        /// brincToken.balanceOf(msg.sender) == old(brincToken.balanceOf(msg.sender)) + _amount;
    /// #if_succeeds {:msg "withdraw: user's withdrawn Brinc Gov reward amount is correct"}
        /// let reward, complete := old(pendingRewards(msg.sender, userInfo[msg.sender].length - 1)) in
        /// govBrincToken.balanceOf(msg.sender) == reward && complete == true;
    /// #if_succeeds {:msg "withdraw: user information is updated correctly"}
        /// let depositNumber := getStakeCount().sub(1) in
        /// let _amount := userInfo[msg.sender][depositNumber].brcStakedAmount in
        /// depositNumber > 0 ==>
        /// userInfo[msg.sender][depositNumber].rewardDebt == userInfo[msg.sender][depositNumber].brcStakedAmount.mul(poolInfo[userInfo[msg.sender][depositNumber].mode].accGovBrincPerShare).div(1e12) && userInfo[msg.sender][depositNumber].mode == userInfo[msg.sender][depositNumber].mode;
    /// #if_succeeds {:msg "withdraw: pool supply is updated correctly"}
        /// let depositNumber := getStakeCount().sub(1) in
        /// depositNumber > 0 ==>
        /// poolInfo[userInfo[msg.sender][depositNumber].mode].supply == old(poolInfo[userInfo[msg.sender][depositNumber].mode].supply).sub(userInfo[msg.sender][depositNumber].brcStakedAmount);
    function withdraw(uint256 _id) public {
        require(_id < userInfo[msg.sender].length, "withdraw: invalid stake id");

        UserInfo memory user = userInfo[msg.sender][_id];
        require(user.brcStakedAmount > 0, "withdraw: nothing to withdraw");
        require(user.blockNumber <= block.number, "withdraw: stake is still locked");
        massUpdatePools();
        PoolInfo storage pool = poolInfo[user.mode];
        uint256 pending =
            user.brcStakedAmount.mul(pool.accGovBrincPerShare).div(1e12).sub(user.rewardDebt);
        safeGovBrincTransfer(msg.sender, pending + user.gBrcStakedAmount);
        stakedGovBrincToken.burnFrom(msg.sender, user.gBrcStakedAmount);
        uint256 _amount = user.brcStakedAmount;
        brincToken.safeTransfer(msg.sender, _amount);
        pool.supply = pool.supply.sub(_amount);
        emit Withdraw(msg.sender, _amount);

        _removeStake(msg.sender, _id);
    }

    /**
     * @dev a user withdraws their Brinc token that they have staked, without caring their rewards.
     * Only pool's supply will be updated.
     *
     * Note EmergencyWithdraw Brinc tokens from BrincStaking.
     */
    function emergencyWithdraw(uint256 _id) public {
        require(_id < userInfo[msg.sender].length, "emergencyWithdraw: invalid stake id");

        UserInfo storage user = userInfo[msg.sender][_id];
        require(user.brcStakedAmount > 0, "emergencyWithdraw: nothing to withdraw");
        PoolInfo storage pool = poolInfo[user.mode];
        safeGovBrincTransfer(msg.sender, user.gBrcStakedAmount);
        stakedGovBrincToken.burnFrom(msg.sender, user.gBrcStakedAmount);
        delete user.gBrcStakedAmount;
        uint256 _amount = user.brcStakedAmount;
        delete user.brcStakedAmount;
        brincToken.safeTransfer(msg.sender, _amount);
        pool.supply = pool.supply.sub(_amount);
        emit EmergencyWithdraw(msg.sender, _amount);

        _removeStake(msg.sender, _id);
    }

    function _removeStake(address _user, uint256 _id) internal {
        userInfo[_user][_id] = userInfo[_user][userInfo[_user].length - 1];
        userInfo[_user].pop();
    }

    /**
     * @dev the safe transfer of the governance token rewards to the designated adress with the specified reward. 
     * Safe govBrinc transfer function, just in case if rounding error causes pool to not have enough govBrinc tokens.
     *
     * @param _to address to send Brinc Gov token rewards to
     * @param _amount amount of Brinc Gov token rewards to send
     *
     * Note this will be only used internally inside the contract.
     */
    /// #if_succeeds {:msg "safeGovBrincTransfer: transfer of Brinc Gov token is correct - case _amount > govBrincBal"}
        /// let initGovBrincBal := old(govBrincToken.balanceOf(_to)) in
        /// let govBrincBal := old(govBrincToken.balanceOf(address(this))) in
        /// _amount > govBrincBal ==> govBrincToken.balanceOf(_to) == initGovBrincBal + govBrincBal;
    /// #if_succeeds {:msg "safeGovBrincTransfer: transfer of Brinc Gov token is correct - case _amount < govBrincBal"}
        /// let initGovBrincBal := old(govBrincToken.balanceOf(_to)) in
        /// let govBrincBal := old(govBrincToken.balanceOf(address(this))) in
        /// _amount <= govBrincBal ==> govBrincToken.balanceOf(_to) == initGovBrincBal + _amount;
    function safeGovBrincTransfer(address _to, uint256 _amount) internal {
        uint256 govBrincBal = govBrincToken.balanceOf(address(this));
        if (_amount > govBrincBal) {
            govBrincToken.transfer(_to, govBrincBal);
        } else {
            govBrincToken.transfer(_to, _amount);
        }
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
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
library SafeMathUpgradeable {
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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
        return !AddressUpgradeable.isContract(address(this));
    }
}