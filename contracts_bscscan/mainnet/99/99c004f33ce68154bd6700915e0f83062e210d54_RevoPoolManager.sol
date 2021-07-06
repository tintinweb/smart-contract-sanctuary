/**
 *Submitted for verification at BscScan.com on 2021-07-06
*/

pragma solidity =0.8.0;

interface IRevoTokenContract{
  function balanceOf(address account) external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
}

interface IRevoStakingContract{
    struct Stake {
        uint256 stakedAmount;
        uint256 startTime;
        uint256 poolIndex;
        uint256 tierIndex;
        uint256 reward;
        uint256 harvested;
        bool withdrawStake;
    }
    
    struct Pool {
        string poolName;
        uint256 poolIndex;
        uint256 startTime;
        uint256 totalReward;
        uint256 totalStaked;
        uint256 currentReward;
        uint256 duration;
        uint256 APR;
        bool terminated;
    }
    
    function getUserStakes(address _user) external view returns (Stake[] memory);
    function getAllPools() external view returns(IRevoStakingContract.Pool[] memory);
    function performStake(uint256 _poolIndex, uint256 _revoAmount, address _wallet) external;
    function unstake(uint256 _poolIndex, address _wallet) external;
    function harvest(uint256 _poolIndex, address _wallet) external;
    function getUserPoolReward(uint256 _poolIndex, uint256 _stakeAmount, address _wallet) external view returns(uint256);
    function getHarvestable(address _wallet, uint256 _poolIndex) external view returns(uint256);
}

interface IRevoFarming{
    struct FarmingPool {
        string name;
        uint256 poolIndex;
        uint256 startTime;
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 rewardsDuration;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 totalLpStaked;
    }
    
    struct Stake {
        uint256 stakedAmount;
        uint256 poolIndex;
        uint256 harvested;
        uint256 harvestable;
    }
    
    function stake(uint256 _poolIndex, address _wallet, uint256 amount) external;
    function withdraw(uint256 _poolIndex, address _wallet, uint256 amount) external;
    function harvest(uint256 _poolIndex, address _wallet) external;
    function exit(uint256 _poolIndex, address _wallet) external;
    function earned(uint256 _poolIndex, address account) external view returns (uint256);
    function getAllPools() external view returns(FarmingPool[] memory);
    function lpAddress() external view returns(address);
    function getUserStakes(address _user) external view returns(IRevoFarming.Stake[] memory);
}

interface IPancakeContract {
    function totalSupply() external view returns (uint);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract RevoPoolManager is Ownable{
    using SafeMath for uint256;
    
    struct AbsctractPool {
        address contractAddress;
        IRevoStakingContract.Pool pool;
    }
    
    struct AbsctractFarmingPool {
        address contractAddress;
        uint256 lpReserves0;
        uint256 lpReserves1;
        uint256 lpTotalSupply;
        IRevoFarming.FarmingPool pool;
    }
    
    //Revo Token
    address public revoAddress;
    IRevoTokenContract revoToken;
    //Staking pools
    address[] public stakingPools;
    //Farming pools
    address[] public farmingPools;
    
    constructor(address _revoAddress) {
        setRevo(_revoAddress);
    }
    
    /*
    Returns the amount of Revo staked from all staking pools accross all contracts
    */
    function getRevoStakedFromStakingPools(address _wallet) public view returns(uint256) {
        uint256 revoStaked;
        for(uint256 i = 0; i < stakingPools.length; i++){
            if(stakingPools[i] != 0x0000000000000000000000000000000000000000){
                IRevoStakingContract.Stake[] memory stakes = IRevoStakingContract(stakingPools[i]).getUserStakes(_wallet);
                for(uint256 s = 0; s < stakes.length; s++){ 
                    revoStaked = revoStaked.add(!stakes[s].withdrawStake ? stakes[s].stakedAmount : 0);
                }
            }
        }
        return revoStaked;
    }
    
    /*
    Returns the amount of LP tokens staked from all farming pools
    */
    function getLPStakedFromFarmingPools(address _wallet) public view returns(uint256) {
        uint256 lpStaked;
        for(uint256 i = 0; i < farmingPools.length; i++){
            if(farmingPools[i] != 0x0000000000000000000000000000000000000000){

                IRevoFarming.Stake[] memory stakes = IRevoFarming(farmingPools[i]).getUserStakes(_wallet);
                for(uint256 s = 0; s < stakes.length; s++){ 
                    lpStaked = lpStaked.add(stakes[s].stakedAmount);
                }
            }
        }
        return lpStaked;
    }
    
    /*
    Add an address in pools array
    */
    function addPoolAddress(address _address, bool _isFarming) public onlyOwner {
        (_isFarming ? farmingPools : stakingPools).push(_address);
    }
    
    /*
    Remove an address in pools array
    */
    function removePoolAddress(address _address, bool _isFarming) public onlyOwner {
        uint256 index = 99999999;
        address[] storage addresses = (_isFarming ? farmingPools : stakingPools);
        for(uint256 i = 0; i < addresses.length; i++){
            if(addresses[i] == _address){
                index = i;
            }
        }
        if(index < 99999999){
            delete addresses[index];
        }
    }
    
    /**********************
     * Staking Proxy
     *********************/
    
    /*
    Get all staking pools accross all staking contracts
    */
    function getStakingPools() public view returns(AbsctractPool[] memory){
        uint256 size = 0;
        for(uint256 i = 0; i < stakingPools.length; i++){
            if(stakingPools[i] != 0x0000000000000000000000000000000000000000){
                size += IRevoStakingContract(stakingPools[uint(i)]).getAllPools().length;
            }
        }
        AbsctractPool[] memory pools = new AbsctractPool[](size);
        
        uint256 arrayIndex;
        for(int256 i = int(stakingPools.length) - 1; i >= 0; i--){
            if(stakingPools[uint(i)] != 0x0000000000000000000000000000000000000000){
                IRevoStakingContract stakingContract = IRevoStakingContract(stakingPools[uint(i)]);
                
                for(int256 p = int(stakingContract.getAllPools().length) - 1; p >= 0 ; p--){
                    pools[arrayIndex].contractAddress = stakingPools[uint(i)];
                    pools[arrayIndex].pool = stakingContract.getAllPools()[uint(p)];
                    
                    arrayIndex++;
                }
            }
        }
        return pools;
    }
    
    function getUserStakes(address _user) public view returns (IRevoStakingContract.Stake[] memory){
        uint256 size = 0;
        for(uint256 i = 0; i < stakingPools.length; i++){
            if(stakingPools[i] != 0x0000000000000000000000000000000000000000){
                size += IRevoStakingContract(stakingPools[uint(i)]).getUserStakes(_user).length;
            }
        }
        
        IRevoStakingContract.Stake[] memory stakes = new IRevoStakingContract.Stake[](size);
        
        uint256 arrayIndex;
        for(int256 i = int(stakingPools.length) - 1; i >= 0; i--){
            if(stakingPools[uint(i)] != 0x0000000000000000000000000000000000000000){
                IRevoStakingContract stakingContract = IRevoStakingContract(stakingPools[uint(i)]);
                
                for(int256 p = int(stakingContract.getUserStakes(_user).length) - 1; p >= 0 ; p--){
                    stakes[arrayIndex] = stakingContract.getUserStakes(_user)[uint(p)];
                    
                    arrayIndex++;
                }
            }
        }
        return stakes;
    }
    
    
    function stake(address _contractAddress, uint256 _poolIndex, uint256 _revoAmount) public{ 
        IRevoStakingContract(_contractAddress).performStake(_poolIndex, _revoAmount, msg.sender);
    }
    
    function unstake(address _contractAddress, uint256 _poolIndex) public{
        IRevoStakingContract(_contractAddress).unstake(_poolIndex, msg.sender);
    }
    
    function harvest(address _contractAddress, uint256 _poolIndex) public{
        IRevoStakingContract(_contractAddress).harvest(_poolIndex, msg.sender);
    }
    
    function getUserPoolReward(address _contractAddress, uint256 _poolIndex, uint256 _stakeAmount, address _wallet) external view returns(uint256){
        return IRevoStakingContract(_contractAddress).getUserPoolReward(_poolIndex, _stakeAmount, _wallet);
    }
    
    function getHarvestable(address[] memory _contractAddresses, address _wallet, uint256[] memory _poolIndexes) public view returns(uint256[] memory){
        uint256[] memory harvestArray = new uint256[](_poolIndexes.length);
        for(uint256 i = 0; i < _poolIndexes.length; i++){
            harvestArray[i] = IRevoStakingContract(_contractAddresses[i]).getHarvestable(_wallet, _poolIndexes[i]);
        }
        return harvestArray;
    }
    
    /**********************
    * Farming Proxy
    *********************/
    function getFarmingPools() public view returns(AbsctractFarmingPool[] memory){
        uint256 size = 0;
        for(uint256 i = 0; i < farmingPools.length; i++){
            if(farmingPools[i] != 0x0000000000000000000000000000000000000000){
                size += IRevoFarming(farmingPools[uint(i)]).getAllPools().length;
            }
        }
        AbsctractFarmingPool[] memory pools = new AbsctractFarmingPool[](size);
        uint256 arrayIndex;
        for(int256 i = int(farmingPools.length) - 1; i >= 0; i--){
            if(farmingPools[uint(i)] != 0x0000000000000000000000000000000000000000){
                IRevoFarming farmingContract = IRevoFarming(farmingPools[uint(i)]);
                
                for(int256 p = int(farmingContract.getAllPools().length) - 1; p >= 0 ; p--){
                    pools[arrayIndex].contractAddress = farmingPools[uint(i)];
                    pools[arrayIndex].pool = farmingContract.getAllPools()[uint(p)];
                    //LP token information
                    (uint112 _reserve0, uint112 _reserve1,) = IPancakeContract(farmingContract.lpAddress()).getReserves();
                    pools[arrayIndex].lpReserves0 = _reserve0;
                    pools[arrayIndex].lpReserves1 = _reserve1;
                    pools[arrayIndex].lpTotalSupply = IPancakeContract(farmingContract.lpAddress()).totalSupply();

                    arrayIndex++;
                }
            }
        }
        return pools;
    }
    
    function getUserStakesLP(address _user) public view returns (IRevoFarming.Stake[] memory){
        uint256 size = 0;
        for(uint256 i = 0; i < farmingPools.length; i++){
            if(farmingPools[i] != 0x0000000000000000000000000000000000000000){
                size += IRevoFarming(farmingPools[uint(i)]).getUserStakes(_user).length;
            }
        }
        
        IRevoFarming.Stake[] memory stakes = new IRevoFarming.Stake[](size);
        
        uint256 arrayIndex;
        for(int256 i = int(farmingPools.length) - 1; i >= 0; i--){
            if(farmingPools[uint(i)] != 0x0000000000000000000000000000000000000000){
                IRevoFarming farmingContract = IRevoFarming(farmingPools[uint(i)]);
                
                for(int256 p = int(farmingContract.getUserStakes(_user).length) - 1; p >= 0 ; p--){
                    stakes[arrayIndex] = farmingContract.getUserStakes(_user)[uint(p)];
                    
                    arrayIndex++;
                }
            }
        }
        return stakes;
    }
     
    function stakeLp(address _contractAddress, uint256 _poolIndex, uint256 _lpAmount) public{
        IRevoFarming(_contractAddress).stake(_poolIndex, msg.sender, _lpAmount);
    }
    
    function withdrawLp(address _contractAddress, uint256 _poolIndex, uint256 amount) public{
        IRevoFarming(_contractAddress).withdraw(_poolIndex, msg.sender, amount);
    }
    
    function harvestFarming(address _contractAddress, uint256 _poolIndex) public{
        IRevoFarming(_contractAddress).harvest(_poolIndex, msg.sender);
    }
    
    function exitFarming(address _contractAddress, uint256 _poolIndex) public{
        IRevoFarming(_contractAddress).exit(_poolIndex, msg.sender);
    }
    
    function getHarvestableFarming(address[] memory _contractAddresses, address _wallet, uint256[] memory _poolIndexes) public view returns(uint256[] memory){
        uint256[] memory harvestArray = new uint256[](_contractAddresses.length);
        for(uint256 i = 0; i < _contractAddresses.length; i++){
            harvestArray[i] = IRevoFarming(_contractAddresses[i]).earned(_poolIndexes[i], _wallet);
        }
        return harvestArray;
    }
    
    /*
    Set revo Address & token
    */
    function setRevo(address _revo) public onlyOwner {
        revoAddress = _revo;
        revoToken = IRevoTokenContract(revoAddress);
    }
    
    function getPools(bool _isFarming) public view returns(address[] memory) {
        return _isFarming ? farmingPools : stakingPools;
    }
}