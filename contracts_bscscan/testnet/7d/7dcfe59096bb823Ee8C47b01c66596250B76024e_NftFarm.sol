// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IAttr.sol";
import "./IERC721.sol";

contract NftFarm is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        NftInfo[] nfts;
    }

    // Info of each pool.
    struct PoolInfo {
        uint256 campId;
        uint256 allocPoint;       // How many allocation points assigned to this pool. SUSHIs to distribute per block.
        uint256 amount;           // User deposit amount
        uint256 lastRewardBlock;  // Last block number that SUSHIs distribution occurs.
        uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
    }

    // Address of LP token contract.
    IERC721 public lpToken;           
    // The SUSHI TOKEN!
    IERC20 public sushi;
    // Dev address.
    address public devaddr;
    // Block number when bonus SUSHI period ends.
    uint256 public bonusEndBlock;
    // SUSHI tokens created per block.
    uint256 public sushiPerBlock;
    // Bonus muliplier for early sushi makers.
    uint256 public constant BONUS_MULTIPLIER = 5;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when SUSHI mining starts.
    uint256 public startBlock;
    mapping(address=> uint256) public userNftCounts;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Mint(address indexed to, uint256 amount, uint256 devamount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    function initialize(
        IERC20 _sushi,
        IERC721 _lptoken,
        address _devaddr,
        uint256 _sushiPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public initializer {
        Ownable.__Ownable_init();
        sushi = _sushi;
        devaddr = _devaddr;
        sushiPerBlock = _sushiPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
        lpToken = _lptoken;
    }
    
    function getUserInfo(uint256 poolId, address addr)public view returns(uint256, uint256, NftInfo[] memory){
        UserInfo memory user = userInfo[poolId][addr];
        return (user.amount, user.rewardDebt, user.nfts);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function updateLpToken(IERC721 token) public {
        require(msg.sender == owner() || msg.sender == devaddr, "!dev addr");
        lpToken = token;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, bool _withUpdate, uint256 _campId) public {
        require(msg.sender == owner() || msg.sender == devaddr, "!dev addr");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            campId: _campId,
            allocPoint: _allocPoint,
            amount: 0,
            lastRewardBlock: lastRewardBlock,
            accSushiPerShare: 0
        }));
    }

    // Update the given pool's SUSHI allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public {
        require(msg.sender == owner() || msg.sender == devaddr, "!dev addr");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                _to.sub(bonusEndBlock)
            );
        }
    }

    // View function to see pending SUSHIs on frontend.
    function pendingSushi(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSushiPerShare = pool.accSushiPerShare;
        uint256 lpSupply = pool.amount;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 sushiReward = multiplier.mul(sushiPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accSushiPerShare = accSushiPerShare.add(sushiReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accSushiPerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 lpSupply = pool.amount;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 sushiReward = multiplier.mul(sushiPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        if (block.number > bonusEndBlock) {
            mint(devaddr, sushiReward, sushiReward.div(100));
        }

        pool.accSushiPerShare = pool.accSushiPerShare.add(sushiReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    IAttr public NftAttr;

    function updateNftAttr(IAttr newNftAttr) public {
        require(msg.sender == owner() || msg.sender == devaddr, "!dev addr");
        NftAttr = newNftAttr;
    }

    uint maxNftsLength = 5;
    function setMaxLength(uint length) public onlyOwner {
        maxNftsLength = length;
    }

    function claim(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accSushiPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                pending = pending.mul(user.amount).div(user.amount);
                safeSushiTransfer(msg.sender, pending);
            }
        }
    }

    function bulkClaim() public {
        for(uint i = 0;i < poolInfo.length; i++) {
            PoolInfo storage pool = poolInfo[i];
            UserInfo storage user = userInfo[i][msg.sender];
            updatePool(i);
            if (user.amount > 0) {
                uint256 pending = user.amount.mul(pool.accSushiPerShare).div(1e12).sub(user.rewardDebt);
                if(pending > 0) {
                    pending = pending.mul(user.amount).div(user.amount);
                    safeSushiTransfer(msg.sender, pending);
                }
            }
        }
            
    }

    // Deposit LP tokens to MasterChef for SUSHI allocation.
    function deposit(uint256 _pid, uint256 tokenId) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        NftInfo memory info = NftAttr.getNftInfoMap(tokenId);
        require(info.campId == pool.campId, "nft camp id not equal pool camp id !");
        require(user.nfts.length <= maxNftsLength, "Has reached the upper limit");

        uint256 _amount = info.cp;

        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accSushiPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                pending = pending.mul(user.amount).div(user.amount);
                safeSushiTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            lpToken.transferFrom(address(msg.sender), address(this), tokenId);
        }

        if(_amount > 0) {
            pool.amount = pool.amount.add(_amount);
            user.amount = user.amount.add(_amount);
            user.nfts.push(info);
            userNftCounts[msg.sender]++;
        }
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 tokenId) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        NftInfo memory nft; 
        uint8 index;
        for (uint8 i ; i<user.nfts.length; i++){
            nft = user.nfts[i];
            if(nft.tokenId == tokenId){
                index = i;
                break;
            }   
        }
        require(nft.tokenId == tokenId, "withdraw: not good");
        uint256 _amount = nft.cp;

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accSushiPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            pending = pending.mul(user.amount).div(user.amount);
            safeSushiTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.amount = pool.amount.sub(_amount);
            lpToken.transferFrom(address(this), address(msg.sender), tokenId);
        }
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);


        uint256 lastTokenIndex = user.nfts.length - 1;
        NftInfo memory _nft = user.nfts[lastTokenIndex];
        user.nfts[index] = _nft;
        user.nfts.pop(); 
        userNftCounts[msg.sender]--;

        emit Withdraw(msg.sender, _pid, _amount);
    }

     // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid, uint256 tokenId) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        NftInfo memory nft; 
        uint8 index;
        for (uint8 i ; i<user.nfts.length; i++){
            nft = user.nfts[i];
            if(nft.tokenId == tokenId){
                index = i;
                break;
            }   
        }
        require(nft.tokenId == tokenId, "withdraw: not good");
        uint256 _amount = nft.cp;
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.amount = pool.amount.sub(_amount);
            lpToken.transferFrom(address(this), address(msg.sender), tokenId);
        }
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);

        uint256 lastTokenIndex = user.nfts.length - 1;
        NftInfo memory _nft = user.nfts[lastTokenIndex];
        user.nfts[index] = _nft;
        user.nfts.pop(); 

        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    }

    // Safe sushi transfer function, just in case if rounding error causes pool to not have enough SUSHIs.
    function safeSushiTransfer(address _to, uint256 _amount) internal {
        uint256 sushiBal = sushi.balanceOf(address(this));
        if (_amount > sushiBal) {
            sushi.transfer(_to, sushiBal);
        } else {
            sushi.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    
    function mint(address devto, uint256 rewardAmount, uint256 devRewardAmount) internal {
        if (rewardAmount == 0) {
            emit Mint(devto, 0, 0);
            return;
        }

        require(sushi.transfer(devto, devRewardAmount), '!sushi transfer of pool failed');
        emit Mint(devto, rewardAmount, devRewardAmount);
    }
    
    // get user deposited nft info
    function getAllFarmingNFT(address addr) public view returns (NftInfo[] memory) {
        uint16 count = 0;
        NftInfo[] memory ret = new NftInfo[](userNftCounts[addr]);
        for(uint8 i = 0; i < poolInfo.length; i++) {
            UserInfo memory user = userInfo[i][addr];
            for(uint8 j = 0; j < user.nfts.length; j++) {
                ret[count] = user.nfts[i];
            }
        }
        return ret;
    }
    
    // function getAllUserCards(address addr) public returns (NftInfo[] memory) {
    //     uint256 total = lpToken.balanceOf(addr) + userNftCounts[addr];
    //     NftInfo[] memory ret = new NftInfo[](total);
    //     NftInfo[] memory arr1 = getAllFarmingNFT(addr);
    //     uint256[] memory userTokenIds = lpToken.tokenOfOwnerGet(addr);
        
    // }
}