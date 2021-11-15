pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//CHANGE FOR BSC
//import "./libs/BEP20.sol";




// LotlToken
contract LotlToken is ERC20('Axolotl', 'LOTL') {

    address public master;

    constructor( address _master ) public { master = _master; }

    // After initial minting of ICO set to MasterChef address.
    // After it has been set it is not changeable. 
    // Owner of the Token will be the MasterChef contract and thus only the MasterChef contract is able to mint Lotl.
    // We do not see need for a community governed Token. 

    function setMaster(address _master) public {
        require(msg.sender == master, "You are not my Master.");
        master = _master;
        emit SetMasterAddress(msg.sender, _master);
    }

    event SetMasterAddress(address indexed user, address indexed newAddress);


    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public {
        require(msg.sender == master, "master: nani!?");
        _mint(_to, _amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/Constants.sol";
import "./libs/IMasterChef.sol";
import "./libs/IRewardPool.sol";
import "./LotlToken.sol";

//CHANGE FOR BSC
//import "./libs/IBEP20.sol";
//import "./libs/SafeBEP20.sol";
//import "./libs/IRewardPool.sol";



// Copied and modified from GooseDefi code:
// https://github.com/goosedefi/goose-contracts/blob/master/contracts/MasterChefV2.sol
//
// MasterChef is the master of Lotl. He can make Lotl and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a govenance smart contract once LOTL is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. Satan bless.

contract MasterChef is Ownable, ReentrancyGuard, IMasterChef, Constants {
    //using SafeBEP20 for IBEP20;
    //CHANGE FOR BSC
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;                 // How many LP tokens the user has provided.
        uint256 rewardDebt;             // Reward debt. See explanation below.
        bool    hasStaked;              // Checks if user had already staked in pool
        uint256 stakedSince;            // Weighted blocknumber since last stake.  
        uint256 rewardPoolShare;        // Share of reward pool.

        //
        // We do some fancy math here. Basically, any point in time, the amount of LOTLs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accLotlPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accLotlPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
        //
        // In addition to that we do even more fancy stuff here, to calculate the distribution of our 7 day reward pool.
        //  1. First of, we reserve 30% of all minted LOTL to our reward pool. ('lotlRewardPool')
        //  2. We send 90% of all taxes paid to our RewardPool contract.
        //  3. All fees will be swapped to BUSD and sent back to the MasterChef contract.
        //  4. 20% of that BUSD will be burned at burnTokens(amount)
        //  5. The remainder will then go into the 'busdRewardPool'.
        //  6. Then we use calculateRewardPool to calculate all rewards per share for each user and sum them up for each user across all pools he staked in.
        //  7. rewardPerShare = 1 * pool.allocPoint * timeReward * user.amount / totalAllocPoint / lpSupply
        //  8. Then to get your actual reward you need to withdraw your rewards before the next reward pool is distributed or else they will be burned.
        //  9. Rewards are paid out in the function 'withdrawRewards' and are finally calculated as follows.
        //  10. reward = totalRewardPool * user.rewardPoolShare / totalTimeAlloc 
     


                
    }

    // Info of each pool.
    struct PoolInfo {
        //CHANGE FOR BSC
        //IBEP20 lpToken;            // Address of LP token contract.
        IERC20 lpToken;             // Address of LP token contract.
        uint8 allocPoint;           // How many allocation points assigned to this pool. LOTLs to distribute per block.
        uint256 lastRewardBlock;     // Last block number that LOTLs distribution occurs.
        uint256 accLotlPerShare;     // Accumulated LOTLs per share, times 1e12. See below.
        uint16 depositFeeBP;        // Deposit fee in basis points.
        uint32 totalTimeAlloc;      // Total amount of time allocation points.
        address []poolUser;         // Addresses of all stakes in pool.
    }

    // Info for the reward pool.
    // All rewards that haven't been claimed until the next reward distribution will be burned. 
    struct Rewards {
        uint32 totalTimeAlloc;      // Total time factor for all stakes.
        uint256 amountBUSD;         // BUSD to distribute among all stakers.
        uint256 amountLOTL;         // LOTL to distribute among all stakers.
        uint256 remainingLOTL;      // Remainder of LOTL.
        address []poolUser;         // Addresses of all stakes in pool.
    }

    // Lotl to allocate to reward pool.
    uint256 pendingRewardLotl; 
    
    // Info of reward pool.
    Rewards public rewardInfo;

    // The LOTL TOKEN!
    LotlToken public lotl;

    // Dev address.
    address public devaddr;

    // RewardPool contract.
    IRewardPool public rewardPool;

    // Reward fee address.
    address public rewardAddress;

    // LOTL tokens created per block.
    uint32 public lotlPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    // Mapping 0 is reserved for the rewardPool.
    mapping(uint8 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint32 public totalAllocPoint = 0;


    event Deposit(address indexed user, uint8 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint8 indexed pid, uint256 amount);
    event WithdrawReward(address indexed user, uint256 amountLotl, uint256 amountBUSD);
    event EmergencyWithdraw(address indexed user, uint8 indexed pid, uint256 amount);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event SetRewardAddress(address indexed user, address indexed newAddress);
    event UpdateMintingRate(address indexed user, uint32 lotlPerBlock);
    
    

    constructor(
        LotlToken _lotl
    ) public {
        lotl = _lotl;
        devaddr = msg.sender;
        rewardAddress = msg.sender;
    }

    function poolLength() external view returns (uint8) {
        return uint8(poolInfo.length);
    }

    // Used to determine wether a pool has already been added.
    mapping(IERC20 => bool) public poolExistence;

    // Modifier to allow only new pools being added.
    modifier nonDuplicated(IERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // TODO TEST IF ADDING TOKENS AS POOL WORKS 
    // Add a new lp to the pool. Can only be called by the owner.

    function add(uint8 _allocPoint, IERC20 _lpToken, IERC20 _tokenA, IERC20 _tokenB, uint16 _depositFeeBP, bool _withUpdate, bool _isLPPool) public onlyOwner nonDuplicated(_lpToken) {
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");

        require (_allocPoint <= 100, "add: invalid allocation points");
        
        if (_withUpdate) {
            massUpdatePools();
        }
        if(_isLPPool)
        {
            rewardPool.addLpToken(_lpToken, _tokenA, _tokenB, _isLPPool);
        }
        else
        {
            rewardPool.addLpToken(_lpToken, _lpToken, _lpToken, _isLPPool);
        }
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolExistence[_lpToken] = true;
        PoolInfo memory poolToAdd;
        poolToAdd.lpToken = _lpToken;
        poolToAdd.allocPoint =  _allocPoint;
        poolToAdd.lastRewardBlock = block.number;
        poolToAdd.depositFeeBP =  _depositFeeBP;
        poolInfo.push(poolToAdd);
    }

    // View function to see pending LOTLs on frontend.
    function pendingLotl(uint8 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid + 1][_user];
        uint256 accLotlPerShare = pool.accLotlPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = block.number - pool.lastRewardBlock;
            uint256 lotlReward =  multiplier * lotlPerBlock * pool.allocPoint / totalAllocPoint;
            accLotlPerShare = accLotlPerShare + lotlReward * 1e12 / lpSupply;
        }
        return accLotlPerShare * user.amount / 1e12 - user.rewardDebt;
    }

    // View function to see pending rewards on frontend.
    // TODO TEST
    function pendingRewards(address _user) external view returns (uint256 _lotl, uint256 _busd) {
        UserInfo storage user = userInfo[0][_user];
        require(user.rewardPoolShare > 0, "withdraw: not good");
        if(user.rewardPoolShare > 0){
            uint256 busdPending = rewardInfo.amountBUSD * user.rewardPoolShare / rewardInfo.totalTimeAlloc / 1e12;
            uint256 lotlPending = rewardInfo.amountLOTL * user.rewardPoolShare / rewardInfo.totalTimeAlloc / 1e12;
            return (lotlPending, busdPending);
        }
        else{
            return (0,0);
        }
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint8 length = uint8(poolInfo.length);
        for (uint8 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // 28800 blocks = 1 time factor
    // TEST IF DIVIDES WITHOUT REST
    function calculateTimeRewards (uint256 _stakedSince) private returns (uint256)  {
        //return _stakedSince / 28800;
        return _stakedSince;
    } 

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint8 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = block.number - pool.lastRewardBlock;
        uint256 lotlReward = multiplier * lotlPerBlock * pool.allocPoint / totalAllocPoint;
        
        //TODO test minting 
        lotl.mint(devaddr, lotlReward / 10);
        pendingRewardLotl = pendingRewardLotl + lotlReward / 10 * 3;
        lotlReward = lotlReward - (lotlReward / 10 * 4);
        lotl.mint(address(this), lotlReward);
        pool.accLotlPerShare = pool.accLotlPerShare + lotlReward * 1e12 / lpSupply;
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for LOTL allocation.
    function deposit(uint8 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid+uint8(1)][msg.sender];
        UserInfo storage rewardUser = userInfo[0][msg.sender];
        updatePool(_pid);

        // Save last block number as staking timestamp
        if (user.stakedSince == 0 && _amount > 0)
        {
             //TODO TEST IF FIRST STACKE SETS STAKED SINCE
            user.stakedSince = block.number;
        }
        else
        {
            // Last block number scaled up to new stake
            if (user.amount > 0 && _amount > 0)
            {
                //TODO TEST HOLDING FACTOR TRANSFORMATION
                if(user.amount > _amount)
                {
                    user.stakedSince = user.stakedSince + _amount * 1e12 / user.amount * (block.number - user.stakedSince) / 1e12;
                }

                if(user.amount == _amount)
                {
                    user.stakedSince = (block.number + user.stakedSince) / 2;
                }

                if(user.amount < _amount)
                {
                    user.stakedSince = block.number - user.amount * 1e12 / _amount * (block.number - user.stakedSince) / 1e12;
                }
            }
            if (user.amount > 0) 
            {
                uint256 pending = user.amount * pool.accLotlPerShare / 1e12 - user.rewardDebt;
                if (pending > 0) 
                {
                    safeLotlTransfer(msg.sender, pending);
                }
            } 
            if (_amount > 0) 
            {
                pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
                //TODO TEST IF PUSHING WORKS
                if(!user.hasStaked)
                {
                    pool.poolUser.push(msg.sender);
                    user.hasStaked = true;

                }
                if(!rewardUser.hasStaked)
                {
                    rewardInfo.poolUser.push(msg.sender);
                    rewardUser.hasStaked = true;

                }

                if (pool.depositFeeBP > 0) 
                {
                    uint256 depositFee = _amount * pool.depositFeeBP / 10000;
                    pool.lpToken.safeTransfer(devaddr, depositFee / 10);
                    pool.lpToken.safeTransfer(rewardAddress, depositFee - depositFee / 10);
                    user.amount = user.amount + _amount - depositFee;
                } 
                else 
                {
                    user.amount = user.amount + _amount;
                }
            }
        }
        user.rewardDebt = user.amount * pool.accLotlPerShare / 1e12;
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint8 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid + 1][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount * pool.accLotlPerShare / 1e12 - user.rewardDebt;
        if (pending > 0) 
        {
            safeLotlTransfer(msg.sender, pending);
        }
        if (_amount > 0) 
        {
            user.amount = user.amount - _amount;

            //TODO TEST IF UNSTAKING RESETS stakedSince
            if(user.amount > 0)
            {
                user.stakedSince = block.number;
            }
            else 
            {
                user.stakedSince = 0;
            }
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount * pool.accLotlPerShare / 1e12;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function withdrawReward() public nonReentrant {
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.rewardPoolShare > 0, "withdraw: not good");
        uint256 busdPending = rewardInfo.amountBUSD * user.rewardPoolShare / rewardInfo.totalTimeAlloc / 1e12;
        uint256 lotlPending = rewardInfo.amountLOTL * user.rewardPoolShare / rewardInfo.totalTimeAlloc / 1e12;
        rewardInfo.remainingLOTL = rewardInfo.remainingLOTL - lotlPending;
        safeLotlTransfer(msg.sender, lotlPending);
        safeBusdTransfer(msg.sender, busdPending);
        user.rewardPoolShare = 0;
        emit WithdrawReward(msg.sender, lotlPending, busdPending);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint8 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid + 1][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe LOTL transfer function, just in case if rounding error causes pool to not have enough LOTLs.
    function safeLotlTransfer(address _to, uint256 _amount) internal {
        uint256 lotlBal = lotl.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > lotlBal) {
            transferSuccess = lotl.transfer(_to, lotlBal);
        } else {
            transferSuccess = lotl.transfer(_to, _amount);
        }
        require(transferSuccess, "safeLotlTransfer: transfer failed");
    }


    // Safe BUSD transfer function, just in case if rounding error causes pool to not have enough BUSDs.
    function safeBusdTransfer(address _to, uint256 _amount) internal {
        uint256 busdBal = IERC20(busdAddr).balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > busdBal) {
            transferSuccess = IERC20(busdAddr).transfer(_to, busdBal);
        } else {
            transferSuccess = IERC20(busdAddr).transfer(_to, _amount);
        }
        require(transferSuccess, "safeBusdTransfer: transfer failed");
    }


    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
        emit SetDevAddress(msg.sender, _devaddr);
    }

     // One time set reward address.
    function setRewardAddress(address _rewardAddress) public{
        require(msg.sender == rewardAddress, "rewards: wha?");
        rewardPool = IRewardPool(_rewardAddress);
        rewardAddress = _rewardAddress;
        emit SetRewardAddress(msg.sender, _rewardAddress);
    }

   
    // Minting rate will be adjusted every 28800*(8/MintingRate) Blocks
    function updateMintingRate() public onlyOwner {
        massUpdatePools();
        lotlPerBlock = lotlPerBlock * 1e5 / 2 / 1e5;
        emit UpdateMintingRate(msg.sender, lotlPerBlock);
    }


    // Start the Minting
    function startMinting() public onlyOwner {
        if(lotlPerBlock == 0)
        {
        lotlPerBlock = 4;
        }
    }
    

    // Calculates all rewardShares for all users that are registered as stakers. 
    /*  TODO TEST
        1. Burning works
        2. rewardPoolShare = 0 for loop
        3. totalTimeALlocation rewardPool
        4. rewardPoolShare formula correct
        5. lotl and busd reward pool correct
    */

    function calculateRewardPool() external override {
        require(msg.sender == rewardAddress, "rewards: wha?");
        uint8 length = uint8(poolInfo.length);
        uint32 rewardUserlength = uint32(rewardInfo.poolUser.length);
        rewardInfo.amountBUSD =IERC20(busdAddr).balanceOf(address(this));
        rewardInfo.amountLOTL = pendingRewardLotl + rewardInfo.remainingLOTL;
        rewardInfo.remainingLOTL = rewardInfo.amountLOTL;
        pendingRewardLotl = 0;
        rewardInfo.totalTimeAlloc = 0;
        for(uint32 i; i< rewardUserlength; i++){
            UserInfo storage user = userInfo[0][rewardInfo.poolUser[i]];
            user.rewardPoolShare = 0;
        }

        for (uint8 i=0; i < length; i++){
            PoolInfo storage pool = poolInfo[i];
            uint256 lpSupply = pool.lpToken.balanceOf(address(this));
            uint32 userLength = uint32(pool.poolUser.length);
            poolInfo[i].totalTimeAlloc = 0;
            for(uint32 j; j< userLength; j++){
                UserInfo storage user = userInfo[i+1][pool.poolUser[j]];
                if(user.stakedSince > 0){
                    UserInfo storage rewardUser = userInfo[0][poolInfo[i].poolUser[j]];
                    uint16 timeReward = uint16(calculateTimeRewards(user.stakedSince));
                    pool.totalTimeAlloc = pool.totalTimeAlloc + timeReward;
                    rewardUser.rewardPoolShare = rewardUser.rewardPoolShare + user.amount * 1e12 / totalAllocPoint * pool.allocPoint / lpSupply * timeReward;

                }
            }
            rewardInfo.totalTimeAlloc = rewardInfo.totalTimeAlloc + pool.totalTimeAlloc;
        }
    }

    function currentHoldingFactor(uint8 _pid) public view returns(uint256 holdFactor){
        UserInfo storage user = userInfo[_pid][msg.sender];
        if(user.stakedSince > 0)
        {
            return block.number - user.stakedSince;
        }
        else return 0;

    }


}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

abstract contract Constants {

    /* bsc constants
    address constant wbnbAddr = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant busdAddr = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address constant usdtAddr = 0x55d398326f99059fF775485246999027B3197955;
    address constant btcbAddr = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address constant wethAddr = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    address constant daiAddr = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;
    address constant usdcAddr = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address constant dotAddr = 0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402;
    address constant cakeAddr = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address constant gnyAddr = 0xe4A4Ad6E0B773f47D28f548742a23eFD73798332;
    address constant worldAddr = 0x31FFbe9bf84b4d9d02cd40eCcAB4Af1E2877Bbc6;
    address constant vaiAddr = 0x4bd17003473389a42daf6a0a729f6fdb328bbbd7;
    address constant bethAddr = 0x250632378e573c6be1ac2f97fcdf00515d0aa91b;
    address constant ustAddr = 0x23396cf899ca06c4472205fc903bdb4de249d6fc;
    address constant routerAddr = 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F;
    */
    // Ropsten Constants
    address constant wbnbAddr = 0x6123D16F767EB39936cDf92e17697764d13C9Dfc;
    address constant busdAddr = 0x4260E200A356bd15ed210ff4dA0D0e59bac1a38f;
    address constant routerAddr = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant burnAddr = 0x000000000000000000000000000000000000dEaD;
}

pragma solidity ^0.8.0;

interface IMasterChef{
    function calculateRewardPool() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//import "./IBEP20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardPool{
    function addLpToken(IERC20 _lpToken, IERC20 _tokenA, IERC20 _tokenB, bool _isLPToken) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor () {
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

pragma solidity ^0.8.0;

import "./IERC20.sol";
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
contract ERC20 is Context, IERC20 {
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
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
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

