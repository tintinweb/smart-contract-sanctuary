pragma solidity 0.6.12;


import "IERC20.sol";
import "SafeERC20.sol";
import "EnumerableSet.sol";
import "SafeMath.sol";
import "Ownable.sol";
import "DPCToken.sol";


interface IMigrator {
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // Migrator must have allowance access to UniswapV2 LP tokens.
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

// Master Farming. He can make DPC and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once DPC is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract Farming is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 paidPerShare; //Paid DPC per share
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of DPCs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accDPCPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens or Harvest DPC to a pool. Here's what happens:
        //   1. The pool's `accDPCPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. DPCs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that DPCs allocation occurs.
        uint256 accDPCPerShare;  // Accumulated DPCs per share, times 1e18. See below.
    }

    struct Plan {
        uint256 startBlock;       //When the allocation plan starts
        uint256 endBlock;         //When the allocation plan ends
        uint256 rewardPerBlock;   //How many DPCs would be minted per mined block
    }


    // Airdrop address.
    address public airdropAddress;
    // Seed address.
    address public seedAddress;
    // Team address.
    address public teamAddress;
    // DNode address.
    address public dNodeAddress;

    // The DPC TOKEN!
    DPCToken public DPC;
    // Migrator
    IMigrator public migrator;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each allocation plan.
    Plan[] public plans;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when DPC mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        DPCToken _DPC,
        uint256 _startBlock
    ) public {
        DPC = _DPC;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getUserInfo(uint256 _pid, address _address) public view returns(uint256){
        return userInfo[_pid][_address].amount;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accDPCPerShare: 0
        }));
    }

    // Add allocation plan, Can onlybe calledd by the owner
    function addPlan(uint256 _startBlock,uint256 _endBlock, uint256 _rewardPerBlock) public onlyOwner {
        plans.push(Plan({
            startBlock: _startBlock,
            endBlock: _endBlock,
            rewardPerBlock: _rewardPerBlock
        }));
    }

    // Update the given pool's DPC allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Update the allocation plan, Can only be called by the owner
    function setPlan(uint256 _pid, uint256 _startBlock,uint256 _endBlock,uint256 _rewardPerBlock) public onlyOwner {
        plans[_pid].startBlock = _startBlock;
        plans[_pid].endBlock = _endBlock;
        plans[_pid].rewardPerBlock = _rewardPerBlock;
    }

    //Calculate the Accumulated DPC reward from indicated block according to allocation plan
    function getAccRewardFromBlock(uint256 _from)  public view returns (uint256) {
        uint256 accReward = 0;
        for(uint i = 0; i<plans.length; i++){
            if(_from > plans[i].endBlock){
                accReward = accReward.add(plans[i].rewardPerBlock.mul(plans[i].endBlock.sub(plans[i].startBlock)));
            }
            if( _from >= plans[i].startBlock &&  _from <= plans[i].endBlock){
                accReward = accReward.add(plans[i].rewardPerBlock.mul(_from.sub(plans[i].startBlock)));
            }
        }
        return accReward;
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigrator _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    // View function to see pending DPCs on frontend.
    function pendingDPC(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accDPCPerShare = pool.accDPCPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 accReward = getAccRewardFromBlock(block.number).sub(getAccRewardFromBlock(pool.lastRewardBlock));
            uint256 DPCReward = accReward.mul(pool.allocPoint).div(totalAllocPoint);
            accDPCPerShare = accDPCPerShare.add(DPCReward.mul(1e18).div(lpSupply));
        }
        return user.amount.mul(accDPCPerShare.sub(user.paidPerShare)).div(1e18);
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
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 accReward = getAccRewardFromBlock(block.number).sub(getAccRewardFromBlock(pool.lastRewardBlock));
        uint256 DPCReward = accReward.mul(pool.allocPoint).div(totalAllocPoint);
        DPC.mint(address(this), DPCReward);
        DPC.mint(airdropAddress, DPCReward.mul(5).div(50));
        DPC.mint(teamAddress, DPCReward.mul(15).div(50));
        DPC.mint(seedAddress, DPCReward.mul(5).div(50));
        DPC.mint(dNodeAddress, DPCReward.mul(15).div(50));
        pool.accDPCPerShare = pool.accDPCPerShare.add(DPCReward.mul(1e18).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to Farming for DPC allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        require(block.number >=startBlock,"farming not started yet");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending = pendingDPC(_pid,msg.sender);
            if(pending > 0) {
                safeDPCTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
            user.paidPerShare = pool.accDPCPerShare;
        }
        user.rewardDebt = user.amount.mul(pool.accDPCPerShare).div(1e18);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from Farming pool.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = pendingDPC(_pid,msg.sender);
        if(pending > 0) {
            safeDPCTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            user.paidPerShare = pool.accDPCPerShare;
        }
        user.rewardDebt = user.amount.mul(pool.accDPCPerShare).div(1e18);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Harvest DPC from the pool
    function harvest(uint _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 pending = pendingDPC(_pid,msg.sender);
        require(pending > 0, "harvest: no DPC to harvest");
        updatePool(_pid);
        safeDPCTransfer(msg.sender, pending);
        user.paidPerShare = pool.accDPCPerShare;
        user.rewardDebt = user.rewardDebt.add(pending);
        emit Harvest(msg.sender, _pid, pending);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe DPC transfer function, just in case if rounding error causes pool to not have enough DPCs.
    function safeDPCTransfer(address _to, uint256 _amount) internal {
        uint256 DPCBal = DPC.balanceOf(address(this));
        if (_amount > DPCBal) {
            DPC.transfer(_to, DPCBal);
        } else {
            DPC.transfer(_to, _amount);
        }
    }

    // Update Airdrop address.
    function setAirdropAddress(address _address)  public onlyOwner {
        airdropAddress = _address;
    }
    // Update Team address.
    function setTeamAddress(address _address)  public onlyOwner {
        teamAddress = _address;
    }
    // Update Seed address.
    function setSeedAddress(address _address)  public onlyOwner {
        seedAddress = _address;
    }
    // Update DNode address.
    function setDNodeAddress(address _address)  public onlyOwner {
        dNodeAddress = _address;
    }

    // Transfer ownership of DPC token contract
    function transferDPCOwnership(address _owner) public onlyOwner {
        DPC.transferOwnership(_owner);
    }

    // Fetch DPC amount via uniswap LP token
    function getDPCAmount(uint256 _pid, uint256 _amount) public view returns (uint256){
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 lpDPCBalance = DPC.balanceOf(address(lpToken));
        uint256 lpTotalSupply = lpToken.totalSupply();

        if(_amount >= lpTotalSupply){
            return lpDPCBalance;
        }
        return _amount.mul(lpDPCBalance).div(lpTotalSupply);
    }

    //get LP token
    function  getLPToken(uint256 _pid) public view returns(address){
        return  address(poolInfo[_pid].lpToken);
    }

    //get LP token balance
    function  getLPBlance(uint256 _pid, address _address) public view returns(uint256){
        return  userInfo[_pid][_address].amount;
    }
}
