pragma solidity ^0.6.12;

import './TransferHelper.sol';
import './SafeMath.sol';

contract TubeChief {
    using SafeMath for uint;

    uint constant DECIMAL = 18;
    uint constant FARMER  = 750000000000000000;
    uint constant DEV     = 100000000000000000;
    uint constant LOTTERY = 150000000000000000;

    struct PoolInfo {
        address lpTokenAddress; // the LP token pair address
        uint rewardPerBlock;    // number of TUBE will mint per block
        uint lastBlockNo;       // record pool mint finish last block number
        uint lastDevBlockNo;    // record token mint to development last block number
        uint lastLotBlockNo;    // record token mint to lottery last block number
        uint accLpStaked;       // accumulate number of LP token user staked
        uint accLastBlockNo;    // record last pass in block number
        uint multiplier;        // reward multiplier
        uint accTokenPerShare;  // accumulated token per share
        bool locked;            // pool is locked
        bool finished;          // pool is stop mint token. disable deposit. only allow claim
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

    address public owner;   // owner of tube chief
    address public tube;    // the TUBE token
    address public devaddr; // development address
    address public lotaddr; // lottery address
    uint public poolLength; // next pool id. current length is (poolLength - 1)

    event CreatePool(address lpTokenAddress, uint rewardPerBlock, uint poolId);
    event UpdatePool(uint poolId, uint rewardPerBlock, uint multiplier, bool locked);
    event Claim(uint poolId, uint amount, uint claimable);
    event TransferCompany(address old_owner, address new_owner);

    modifier onlyOwner {
        require(msg.sender == owner, 'NOT OWNER');
        _;
    }

    constructor (address _tube, address _devaddr, address _lotaddr) public {
        owner   = msg.sender;
        tube    = _tube;
        devaddr = _devaddr;
        lotaddr = _lotaddr;
    }

    // create new pool. only owner executable
    // XX do not create twice on same LP token. reward will mess up if you do
    function createPool(address _lpTokenAddress, uint _rewardPerBlock, uint _multiplier) public onlyOwner {
        require(_lpTokenAddress != address(0), 'CREATE_POOL_EMPTY_ADDRESS');

        emit CreatePool(_lpTokenAddress, _rewardPerBlock, poolLength);
        pools[poolLength].lpTokenAddress = _lpTokenAddress;
        pools[poolLength].rewardPerBlock = _rewardPerBlock;
        pools[poolLength].multiplier     = _multiplier;
        pools[poolLength].accLastBlockNo = block.number;
        pools[poolLength].lastDevBlockNo = block.number;
        pools[poolLength].lastLotBlockNo = block.number;
        poolIdByLp[_lpTokenAddress].push(poolLength);
        poolLength = poolLength.add(1);
    }

    // update pool setting, edit wisely. only owner executable
    function updatePool(uint poolId, uint _rewardPerBlock, uint _multiplier, bool _locked) public onlyOwner {
        _updateAccTokenPerShare(poolId);
        pools[poolId].rewardPerBlock = _rewardPerBlock;
        pools[poolId].multiplier     = _multiplier;
        pools[poolId].locked         = _locked;
        emit UpdatePool(poolId, _rewardPerBlock, _multiplier, _locked);
    }

    // update development address. only owner executable
    function updateDevAddr(address _address) public onlyOwner {
        devaddr = _address;
    }

    // update lottery address. only owner executable
    function updateLotAddr(address _address) public onlyOwner {
        lotaddr = _address;
    }

    // set pool stop mint token. claim reward based on last block number recorded. only owner executable
    function updatePoolFinish(uint poolId, bool _finished) public onlyOwner {
        pools[poolId].finished    = _finished;
        pools[poolId].lastBlockNo = _finished ? block.number : 0;
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
    }

    // claim TUBE token. input LP token to exit pool
    function claim(uint poolId, uint amount) public {
        require(pools[poolId].lpTokenAddress != address(0), 'CLAIM_POOL_NOT_EXIST');
        require(pools[poolId].locked == false, 'CLAIM_POOL_LOCKED');
        
        _updateAccTokenPerShare(poolId);

        uint claimable = _getRewardAmount(poolId);
        if (claimable > 0) {
            ITubeToken(tube).farmMint(address(this), claimable);
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
        IERC20(token).transfer(owner, amount);
    }

    // emergency collect eth from the contract. only owner executable
    function emergencyCollectEth(uint amount) public onlyOwner {
        address payable owner_address = payable(owner);
        owner_address.send(amount);
    }

    // transfer ownership. proceed wisely. only owner executable
    function transferCompany(address new_owner) public onlyOwner {
        owner = new_owner;
        emit TransferCompany(owner, new_owner);
    }

    // transfer mintable token to development address
    function transferDev(uint poolId) public onlyOwner {
        uint mintable = getExMintable(poolId, true);
        require(mintable > 0, 'TRANSFER_DEV_EMPTY');
        ITubeToken(tube).farmMint(address(this), mintable);
        TransferHelper.safeTransfer(tube, devaddr, mintable);
        pools[poolId].lastDevBlockNo = block.number;
    }

    // transfer mintable token to lottery address
    function transferLottery(uint poolId) public onlyOwner {
        uint mintable = getExMintable(poolId, false);
        require(mintable > 0, 'TRANSFER_LOT_EMPTY');
        ITubeToken(tube).farmMint(address(this), mintable);
        TransferHelper.safeTransfer(tube, lotaddr, mintable);
        pools[poolId].lastLotBlockNo = block.number;
    }

    // retrieve the mintable amount for development or lottery
    function getExMintable(uint poolId, bool is_dev) public view returns (uint) {
        uint last_block   = 0;
        uint rate         = 0;

        if (is_dev) {
            last_block = pools[poolId].lastDevBlockNo;
            rate       = DEV;
        } else {
            last_block = pools[poolId].lastLotBlockNo;
            rate       = LOTTERY;
        }

        uint block_diff = block.number.sub(last_block);
        block_diff      = block_diff * 10**DECIMAL;

        return block_diff.mul(pools[poolId].rewardPerBlock, DECIMAL).mul(pools[poolId].multiplier, DECIMAL).mul(rate, DECIMAL);
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

interface ITubeToken {
    function farmMint(address _address, uint amount) external;
}

interface IERC20 {
    function transfer(address to, uint tokens) external returns (bool success);
}