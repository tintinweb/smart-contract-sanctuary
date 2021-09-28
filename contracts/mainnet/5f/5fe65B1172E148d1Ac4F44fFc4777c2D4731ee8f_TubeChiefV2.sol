pragma solidity ^0.6.12;

import './TransferHelper.sol';
import './SafeMath.sol';

contract TubeChiefV2 {
    using SafeMath for uint;

    struct PoolInfo {
        address lpTokenAddress;  // the LP token pair address
        uint rewardPerBlock;     // number of TUBE will mint per block
        uint lastDevBlockNo;     // record token mint to development last block number
        uint lastLotBlockNo;     // record token mint to lottery last block number
        uint lastStakeBlockNo;   // record token mint to staking last block number
        uint lastJackpotBlockNo; // record token mint to jackpot last block number
        uint accLpStaked;        // accumulate number of LP token user staked
        uint accLastBlockNo;     // record last pass in block number
        uint multiplier;         // reward multiplier
        uint accTokenPerShare;   // accumulated token per share
        bool locked;             // pool is locked
        bool finished;           // pool is finished. Disable stake into pool
    }

    struct UserPoolInfo {
        uint lpStaked;       // user staked LP
        uint rewardDebt;     // user debt
        uint lastClaimBlock; // last block number user retrieve reward
    }

    mapping(uint => PoolInfo) public pools; // dynamic pool container (pool ID => pool related data)
    mapping(address => uint[]) poolIdByLp;  // pool ids recorder (LP token => pool ids)

    // user pool allocate (user addr => (<pool ID> => user pool data))
    mapping(address => mapping(uint => UserPoolInfo)) public users;
    
    // allow to manage defarm operation
    mapping(address => bool) public defarm_permission;

    // allow to manage functional operation
    mapping(address => bool) public access_permission;

    address public owner;         // owner of tube chief
    address public tube;          // the TUBE token
    address public devaddr;       // development address
    address public lotaddr;       // lottery address
    address public dfstakeaddr;   // sub staking address
    address public dfjackpotaddr; // sub jackpot address
    address public treasury;      // minting purpose. treasury or TUBE token
    
    uint public poolLength; // next pool id. current length is (poolLength - 1)

    uint public FARMER    = 500000000000000000;
    uint public DEV       = 100000000000000000;
    uint public LOTTERY   = 150000000000000000;
    uint public DFSTAKE   = 25000000000000000;
    uint public DFJACKPOT = 225000000000000000;
    
    uint constant DECIMAL = 18;

    event CreatePool(address lpTokenAddress, uint rewardPerBlock, uint poolId);
    event UpdatePool(uint poolId, uint rewardPerBlock, uint multiplier, bool locked);
    event UpdateDevAddr(address devaddr);
    event UpdateLotAddr(address lotaddr);
    event UpdateDefarmAddress(address dfstakeaddr, address dfjackpotaddr);
    event UpdateAllocation(uint farmer, uint dev, uint lot, uint staking, uint jackpot);
    event UpdateDefarmPermission(address _address, bool status);
    event UpdateAccessPermission(address _address, bool status);
    event UpdateTreasury(address _address);
    event UpdatePoolFinish(uint poolId, bool finished);
    event Stake(uint poolId, uint amount);
    event Claim(uint poolId, uint amount, uint claimable);
    event TransferCompany(address old_owner, address new_owner);
    event TransferDev(uint poolId, address receiver, uint amount);
    event TransferLottery(uint poolId, address receiver, uint amount);
    event TransferStaking(uint poolId, address receiver, uint amount);
    event TransferJackpotReward(address receiver, uint amount);

    modifier onlyOwner {
        require(msg.sender == owner, 'NOT OWNER');
        _;
    }
    
    modifier hasDefarmPermission() {
        require(defarm_permission[msg.sender], 'NO DEFARM PERMISSION');
        _;
    }

    modifier hasAccessPermission() {
        require(access_permission[msg.sender], 'NO ACCESS PERMISSION');
        _;
    }

    constructor (address _tube, address _devaddr, address _lotaddr) public {
        owner   = msg.sender;
        tube    = _tube;
        devaddr = _devaddr;
        lotaddr = _lotaddr;
        defarm_permission[msg.sender] = true;
        access_permission[msg.sender] = true;
    }

    // create new pool. only owner executable
    // XX do not create twice on same LP token. reward will mess up if you do
    function createPool(address _lpTokenAddress, uint _rewardPerBlock, uint _multiplier) public hasAccessPermission {
        require(_lpTokenAddress != address(0), 'CREATE_POOL_EMPTY_ADDRESS');

        emit CreatePool(_lpTokenAddress, _rewardPerBlock, poolLength);
        pools[poolLength].lpTokenAddress     = _lpTokenAddress;
        pools[poolLength].rewardPerBlock     = _rewardPerBlock;
        pools[poolLength].multiplier         = _multiplier;
        pools[poolLength].accLastBlockNo     = block.number;
        pools[poolLength].lastDevBlockNo     = block.number;
        pools[poolLength].lastLotBlockNo     = block.number;
        pools[poolLength].lastStakeBlockNo   = block.number;
        pools[poolLength].lastJackpotBlockNo = block.number;
        poolIdByLp[_lpTokenAddress].push(poolLength);
        poolLength = poolLength.add(1);
    }

    // update pool setting, edit wisely. only owner executable
    function updatePool(uint poolId, uint _rewardPerBlock, uint _multiplier, bool _locked) public hasAccessPermission {
        _updateAccTokenPerShare(poolId);
        pools[poolId].rewardPerBlock = _rewardPerBlock;
        pools[poolId].multiplier     = _multiplier;
        pools[poolId].locked         = _locked;
        emit UpdatePool(poolId, _rewardPerBlock, _multiplier, _locked);
    }
    
    // update pool is finish. user not allow to stake into pool. only owner executable
    function updatePoolFinish(uint poolId, bool _finished) public hasAccessPermission {
        pools[poolId].finished = _finished;
        emit UpdatePoolFinish(poolId, _finished);
    }

    // update development address. only owner executable
    function updateDevAddr(address _address) public hasAccessPermission {
        devaddr = _address;
        emit UpdateDevAddr(devaddr);
    }

    // update lottery address. only owner executable
    function updateLotAddr(address _address) public hasAccessPermission {
        lotaddr = _address;
        emit UpdateLotAddr(lotaddr);
    }
    
    // update defarm addresses. only owner executable
    function updateDefarmAddress(address _dfstakeaddr, address _dfjackpotaddr) public hasAccessPermission {
        dfstakeaddr   = _dfstakeaddr;
        dfjackpotaddr = _dfjackpotaddr;
        emit UpdateDefarmAddress(dfstakeaddr, dfjackpotaddr);
    }

    // update treasury allow chief mint TUBE token. only owner executable
    function updateTreasury(address _address) public hasAccessPermission {
        treasury = _address;
        emit UpdateTreasury(_address);
    }

    // update allocation for each sector. only owner executable
    function updateAllocation(uint _farmer, uint _dev, uint _lot, uint _dfstake, uint _dfjackpot) public hasAccessPermission {
        require(_farmer.add(_dev).add(_lot).add(_dfstake).add(_dfjackpot) == 1000000000000000000, "invalid allocation");
        FARMER    = _farmer;
        DEV       = _dev;
        LOTTERY   = _lot;
        DFSTAKE   = _dfstake;
        DFJACKPOT = _dfjackpot;
        emit UpdateAllocation(_farmer, _dev, _lot, _dfstake, _dfjackpot);
    }

    // update defarm permission. only owner executable
    function updateDefarmPermission(address _address, bool status) public onlyOwner {
        defarm_permission[_address] = status;
        emit UpdateDefarmPermission(_address, status);
    }

    // update access permission. only owner executable
    function updateAccessPermission(address _address, bool status) public onlyOwner {
        access_permission[_address] = status;
        emit UpdateAccessPermission(_address, status);
    }

    // stake LP token to earn TUBE
    function stake(uint poolId, uint amount) public {
        require(pools[poolId].lpTokenAddress != address(0), 'STAKE_POOL_NOT_EXIST');
        require(pools[poolId].locked == false, 'STAKE_POOL_LOCKED');
        require(pools[poolId].finished == false, 'STAKE_POOL_FINISHED');

        claim(poolId, 0);
        TransferHelper.safeTransferFrom(pools[poolId].lpTokenAddress, msg.sender, address(this), amount);
        pools[poolId].accLpStaked = pools[poolId].accLpStaked.add(amount);
        users[msg.sender][poolId].lpStaked       = users[msg.sender][poolId].lpStaked.add(amount);
        users[msg.sender][poolId].lastClaimBlock = block.number;
        users[msg.sender][poolId].rewardDebt     = pools[poolId].accTokenPerShare.mul(users[msg.sender][poolId].lpStaked, DECIMAL);

        emit Stake(poolId, amount);
    }

    // claim TUBE token. input LP token to exit pool
    function claim(uint poolId, uint amount) public {
        require(pools[poolId].lpTokenAddress != address(0), 'CLAIM_POOL_NOT_EXIST');
        require(pools[poolId].locked == false, 'CLAIM_POOL_LOCKED');
        
        _updateAccTokenPerShare(poolId);

        uint claimable = _getRewardAmount(poolId);
        if (claimable > 0) {
            IMint(treasury).farmMint(address(this), claimable);
            TransferHelper.safeTransfer(tube, msg.sender, claimable);
            users[msg.sender][poolId].lastClaimBlock = block.number;
        }

        if (amount > 0) {
            TransferHelper.safeTransfer(pools[poolId].lpTokenAddress, msg.sender, amount);
            users[msg.sender][poolId].lpStaked = users[msg.sender][poolId].lpStaked.sub(amount);
            pools[poolId].accLpStaked = pools[poolId].accLpStaked.sub(amount);
        }

        // emit if necessary. cost saving
        if (claimable > 0 || amount > 0) {
            emit Claim(poolId, amount, claimable);
        }

        // update the user reward debt at this moment
        users[msg.sender][poolId].rewardDebt = pools[poolId].accTokenPerShare.mul(users[msg.sender][poolId].lpStaked, DECIMAL);
    }

    // get token per share with current block number
    function getAccTokenInfo(uint poolId) public view returns (uint) {
        if (pools[poolId].accLpStaked <= 0) {
            return 0;
        }

        uint reward_block = pools[poolId].rewardPerBlock;
        uint multiplier   = pools[poolId].multiplier;
        uint total_staked = pools[poolId].accLpStaked;
        uint pending      = block.number.sub(pools[poolId].accLastBlockNo);
        pending           = pending * 10**DECIMAL; // cast to "wei" unit
        uint result       = reward_block.mul(multiplier, DECIMAL).mul(pending, DECIMAL).mul(FARMER, DECIMAL);

        return result.div(total_staked, DECIMAL);
    }

    // emergency collect token from the contract. only owner executable
    function emergencyCollectToken(address token, uint amount) public onlyOwner {
        TransferHelper.safeTransfer(token, owner, amount);
    }

    // emergency collect eth from the contract. only owner executable
    function emergencyCollectEth(uint amount) public onlyOwner {
        address payable owner_address = payable(owner);
        TransferHelper.safeTransferETH(owner_address, amount);
    }

    // transfer ownership. proceed wisely. only owner executable
    function transferCompany(address new_owner) public onlyOwner {
        emit TransferCompany(owner, new_owner);
        owner = new_owner;
    }

    // transfer mintable token to development address
    function transferDev(uint poolId) public hasAccessPermission {
        uint mintable = getExMintable(poolId, keccak256("DEV"));
        require(mintable > 0, 'TRANSFER_DEV_EMPTY');
        require(devaddr != address(0), 'EMPTY DEV ADDRESS');
        IMint(treasury).farmMint(address(this), mintable);
        TransferHelper.safeTransfer(tube, devaddr, mintable);
        pools[poolId].lastDevBlockNo = block.number;
        emit TransferDev(poolId, devaddr, mintable);
    }

    // transfer mintable token to lottery address
    function transferLottery(uint poolId) public hasAccessPermission {
        uint mintable = getExMintable(poolId, keccak256("LOTTERY"));
        require(mintable > 0, 'TRANSFER_LOT_EMPTY');
        require(lotaddr != address(0), 'EMPTY LOTTERY ADDRESS');
        IMint(treasury).farmMint(address(this), mintable);
        TransferHelper.safeTransfer(tube, lotaddr, mintable);
        pools[poolId].lastLotBlockNo = block.number;
        emit TransferLottery(poolId, lotaddr, mintable);
    }
    
    // transfer mintable token to sub staking
    function transferStaking(uint poolId) public hasDefarmPermission {
        uint mintable = getExMintable(poolId, keccak256("STAKING"));
        require(dfstakeaddr != address(0), 'EMPTY DFSTAKE ADDRESS');
        
        if (mintable > 0) {
            IMint(treasury).farmMint(address(this), mintable);
            TransferHelper.safeTransfer(tube, dfstakeaddr, mintable);
            pools[poolId].lastStakeBlockNo = block.number;
            emit TransferStaking(poolId, dfstakeaddr, mintable);
        }
    }
    
    // transfer mintable token to sub jackpot
    function transferJackpotReward() public hasDefarmPermission returns (uint) {
        require(dfjackpotaddr != address(0), 'EMPTY DFJACKPOT ADDRESS');
        
        uint mintable = getJackpotReward();

        if (mintable > 0) {
            IMint(treasury).farmMint(address(this), mintable);
            TransferHelper.safeTransfer(tube, dfjackpotaddr, mintable);
            emit TransferJackpotReward(dfjackpotaddr, mintable);
        }
        
        for (uint i = 0; i <= poolLength.sub(1); i++) {
            pools[i].lastJackpotBlockNo = block.number;
        }
        
        return mintable;
    }

    // retrieve the mintable amount
    function getExMintable(uint poolId, bytes32 category) public view returns (uint) {
        uint last_block   = 0;
        uint rate         = 0;

        if (category == keccak256("DEV")) {
            last_block = pools[poolId].lastDevBlockNo;
            rate       = DEV;
        } else if (category == keccak256("LOTTERY")) {
            last_block = pools[poolId].lastLotBlockNo;
            rate       = LOTTERY;
        } else if (category == keccak256("STAKING")) {
            last_block = pools[poolId].lastStakeBlockNo;
            rate       = DFSTAKE;
        } else if (category == keccak256("JACKPOT")) {
            last_block = pools[poolId].lastJackpotBlockNo;
            rate       = DFJACKPOT;
        } else {
            last_block = 0;
            rate       = 0;
        }
        
        uint block_diff = block.number.sub(last_block);
        block_diff      = block_diff * 10**DECIMAL;

        return block_diff.mul(pools[poolId].rewardPerBlock, DECIMAL).mul(pools[poolId].multiplier, DECIMAL).mul(rate, DECIMAL);
    }
    
    // retrieve jackpot reward allocation
    function getJackpotReward() public view returns (uint) {
        uint reward = 0;
        for (uint i = 0; i <= poolLength.sub(1); i++) {
            reward = reward.add(getExMintable(i, keccak256("JACKPOT")));
        }
        return reward;
    }

    // retrieve pool ids by LP token address
    function getPidByLpToken(address _lpTokenAddress) public view returns (uint[] memory) {
        return poolIdByLp[_lpTokenAddress];
    }

    // retrieve user reward info on the pool with current block number
    function getUserReward(uint poolId) public view returns (uint, uint, uint, uint, uint) {
        uint accTokenPerShare = getAccTokenInfo(poolId);
        accTokenPerShare      = accTokenPerShare.add(pools[poolId].accTokenPerShare);
        
        uint claimable = accTokenPerShare.mul(users[msg.sender][poolId].lpStaked, DECIMAL).sub(users[msg.sender][poolId].rewardDebt);
        return (block.number, claimable, accTokenPerShare, users[msg.sender][poolId].lpStaked, users[msg.sender][poolId].rewardDebt);
    }
    
    function _updateAccTokenPerShare(uint poolId) internal {
        uint result = getAccTokenInfo(poolId);
        pools[poolId].accTokenPerShare = pools[poolId].accTokenPerShare.add(result);
        pools[poolId].accLastBlockNo   = block.number;
    }

    function _getRewardAmount(uint poolId) view internal returns (uint) {
        if (pools[poolId].accLpStaked <= 0) {
            return (0);
        }

        uint user_staked = users[msg.sender][poolId].lpStaked;
        uint user_debt   = users[msg.sender][poolId].rewardDebt;
        uint claimable   = pools[poolId].accTokenPerShare.mul(user_staked, DECIMAL).sub(user_debt);

        return (claimable);
    }

    fallback() external payable {
    }
}

interface IMint {
    function farmMint(address _address, uint amount) external;
}