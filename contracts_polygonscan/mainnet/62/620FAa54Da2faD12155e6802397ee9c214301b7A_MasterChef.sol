// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";
import "./DragonTreasure.sol";

// MasterChef is the master of Egg. He can make Egg and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once EGG is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of EGGs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accEggPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accEggPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. EGGs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that EGGs distribution occurs.
        uint256 accEggPerShare;   // Accumulated EGGs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
    }

    struct UserAmountInfo {
        address user;
        uint256 amount;
    }
    
    // The EGG TOKEN!
    DragonTreasure public dtrs;
    // Dev address.
    address public devaddr;
    // EGG tokens created per block.
    uint256 public eggPerBlock;
    // Bonus muliplier for early egg makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;
    // Treasure Deposit Fee address
    address public treasureFeeAddress;
    // Treasure Raid Deposit Fee in basic points. This will be applied to depositFee of each pool.
    uint256 public depositFeeGP;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when EGG mining starts.
    uint256 public startBlock;
    
    // TreasureRaid: info of the amount of each user
    UserAmountInfo[] private usersAmount;
    // TreasureRaid: store the association between users and indexes of UserAmountInfo array
    mapping (address => uint256[]) private indexesUsersAmount;
    // TreasureRaid: store the size of UserAmountInfo array
    uint256 public userAmountLength = 0;   

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        DragonTreasure _dtrs,
        address _devaddr,
        address _feeAddress,
        uint256 _eggPerBlock,
        uint256 _startBlock,
        uint256 _depositFeeGP
    ) public {
        dtrs = _dtrs;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        eggPerBlock = _eggPerBlock;
        startBlock = _startBlock;
        depositFeeGP = _depositFeeGP;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(treasureFeeAddress != address(0), "add: first of all you must to set a treasureFeeAddress");
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accEggPerShare: 0,
            depositFeeBP: _depositFeeBP
        }));

        // TreasureRaid: approve to the treasureFeeAddress to the created pool lpToken
        _lpToken.safeApprove(treasureFeeAddress, uint256(-1));
    }

    // Update the given pool's EGG allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending EGGs on frontend.
    function pendingEgg(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accEggPerShare = pool.accEggPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 eggReward = multiplier.mul(eggPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accEggPerShare = accEggPerShare.add(eggReward.mul(1e12).div(lpSupply));
        }
        uint256 pendingEggAmount = user.amount.mul(accEggPerShare).div(1e12).sub(user.rewardDebt);
        if(_user == treasureFeeAddress){
            pendingEggAmount = 0;
        }
        return pendingEggAmount;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 eggReward = multiplier.mul(eggPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        dtrs.mint(devaddr, eggReward.div(10));
        dtrs.mint(address(this), eggReward);
        pool.accEggPerShare = pool.accEggPerShare.add(eggReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accEggPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeEggTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            // TreasureRaid: call to function for add the needed information
            addUsersAmount(msg.sender, _amount);

            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if(pool.depositFeeBP > 0){
                uint256 depositFeeInitial = _amount.mul(pool.depositFeeBP).div(10000);
                uint256 depositFeeTreasure = depositFeeInitial.mul(depositFeeGP).div(10000);
                uint256 depositFee = depositFeeInitial.sub(depositFeeTreasure);
                
                // TreasureRaid: Send the Treasure Raid Fee to the Treasure Raid user
                depositTreasure(_pid, depositFeeTreasure);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFeeInitial);
            }else{
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accEggPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // TreasureRaid: add info about the user and the amount deposited by the user in the corresponding vars
    function addUsersAmount(address _user, uint256 _amount) internal {
        uint256 finalAmount = _amount;

        if(userAmountLength > 0){
            uint256 actualAmount = usersAmount[userAmountLength-1].amount;
            finalAmount = finalAmount.add(actualAmount);
        }

        usersAmount.push(UserAmountInfo({
            user: _user,
            amount: finalAmount
        }));

        indexesUsersAmount[_user].push(userAmountLength);
        userAmountLength++;
    }

    // TreasureRaid: Deposit Treasure Raid fee assigned to treasureFeeAddress user
    function depositTreasure(uint256 _pid, uint256 _amount) internal {
        UserInfo storage userTreasure = userInfo[_pid][treasureFeeAddress];
        if(_amount > 0) {
            userTreasure.amount = userTreasure.amount.add(_amount);
        }
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        require(user.amount >= _amount, "withdraw: not good");
        require(msg.sender != treasureFeeAddress, "withdraw: feeAddress can't claim rewards");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accEggPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeEggTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accEggPerShare).div(1e12);

        // TreasureRaid: call to function for remove the needed information
        deleteUsersAmount(msg.sender);

        emit Withdraw(msg.sender, _pid, _amount);
    }

    // TreasureRaid: update and remove info about the user in the corresponding vars
    function deleteUsersAmount(address _user) internal {
        if(userAmountLength > 1){
            uint256[] memory actualIndexes = indexesUsersAmount[_user];
            uint256 iteratorNumber = 0;
            uint256 randomNumber = getRandomNumber(0, iteratorNumber);

            while(checkIndexExcluded(actualIndexes, randomNumber) == true){
                randomNumber = getRandomNumber(randomNumber, iteratorNumber);
                iteratorNumber++;
            }

            address newUser = usersAmount[randomNumber].user;
            for (uint256 i = 0; i < actualIndexes.length; ++i) {
                indexesUsersAmount[newUser].push(actualIndexes[i]);
                usersAmount[actualIndexes[i]].user = newUser;
            }
        }else{
            delete usersAmount[userAmountLength];
            userAmountLength--;
        }

        delete indexesUsersAmount[_user];
    }

    // TreasureRaid: generate random number between 0 and the last index of usersAmount
    function getRandomNumber(uint256 previousRandom, uint256 iteratorNumber) internal view returns (uint256){
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, userAmountLength, previousRandom, iteratorNumber)));
        random = random.mod(userAmountLength);

        return random;
    }

    // TreasureRaid: check if the random number entered as parameter belongs to the deleted user
    function checkIndexExcluded(uint256[] memory excludedIndexes, uint256 randomNumber) internal pure returns (bool){
        bool exists = false;

        for (uint256 i = 0; i < excludedIndexes.length; ++i) {
            if(randomNumber == excludedIndexes[i] && exists == false){
                exists = true;
            }
        }
        return exists;
    }

    // TreasureRaid: check user amount on all pools (to get info about treasureFeeAddress)
    function userTotalAmount(address _user) public view returns (uint256){
        uint256 totalAmount = 0;
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            UserInfo storage user = userInfo[pid][_user];
            totalAmount = totalAmount.add(user.amount);
        }
        return totalAmount;
    }

    // TreasureRaid: check user amount on one pool (to get info about treasureFeeAddress)
    function userPoolAmount(uint256 _pid, address _user) public view returns (uint256){
        UserInfo storage user = userInfo[_pid][_user];
        return user.amount;
    }

    // TreasureRaid: get the amount stored in the usersAmount array by index
    function getUserAmount(uint256 _index) public view returns (uint256){
        uint256 _amount = usersAmount[_index].amount;
        return _amount;
    }

    // TreasureRaid: get the user address in the usersAmount array by index
    function getUserAddress(uint256 _index) public view returns (address){
        address _address = usersAmount[_index].user;
        return _address;
    }

    // TreasureRaid: get lptoken of a pool 
    function getLpToken(uint256 _pid) public view returns (address){
        PoolInfo storage pool = poolInfo[_pid];
        return address(pool.lpToken);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(msg.sender != treasureFeeAddress, "emergencyWithdraw: feeAddress can't claim rewards");

        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        // TreasureRaid: call to function for remove the needed information
        deleteUsersAmount(msg.sender);
        
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // TreasureRaid: reset Treasure Raid fee assigned to treasureFeeAddress user
    function resetTreasure(uint256 _pid) public {
        require(msg.sender == treasureFeeAddress, "resetTreasure: only treasureFeeAddress can do this");

        UserInfo storage userTreasure = userInfo[_pid][treasureFeeAddress];
        userTreasure.amount = 0;
    }

    // Safe dtrs transfer function, just in case if rounding error causes pool to not have enough dtrs.
    function safeEggTransfer(address _to, uint256 _amount) internal {
        uint256 eggBal = dtrs.balanceOf(address(this));
        if (_amount > eggBal) {
            dtrs.transfer(_to, eggBal);
        } else {
            dtrs.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    function setFeeAddress(address _feeAddress) public{
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
    }

    // Set the address of the Treasure Raid smart contract.
    function setTreasureFeeAddress(address _treasureFeeAddress) public onlyOwner {
        require(treasureFeeAddress == address(0), "setTreasureFeeAddress: you can only set once treasureFeeAddress");
        treasureFeeAddress = _treasureFeeAddress;
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _eggPerBlock) public onlyOwner {
        massUpdatePools();
        eggPerBlock = _eggPerBlock;
    }

}