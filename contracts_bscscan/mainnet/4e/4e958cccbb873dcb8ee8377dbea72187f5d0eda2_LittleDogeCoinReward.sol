// SPDX-License-Identifier: No License
pragma solidity >=0.8.7;
/**
 * LittleDogeCoin Reward smart contract is automated rewarding system.
 * Rewards goes to team, marketing, development and eco-system growth.
 * 
 */
import "./IMineable.sol";
import "./Authorization.sol";
import "./IBEP20.sol";
import "./SafeMath.sol";
import "./Address.sol";
contract LittleDogeCoinReward is IMineable, Authorization{
    using SafeMath for uint256;
    mapping(address => Reseller) private _resellers;
    uint public _totalResellers = 0;
    uint public _totalMiners = 0;
    mapping(address => Miner) private _miners;
    uint256 public _maxHashRate = 1209600000000; //14M token per day;
    uint256 public _currentRewardHashRate;
    uint256 public _currentAllocatedHashRate;
    bool public _minedTokenEnable = true;
    address public _littleDogeCoin;
    // destination of minted tokens;
    address public _rewardSourceAddress;
    struct Miner{
        uint256 hashRate;
        uint startTime;
        uint expiry;
        bool exist;
        string membershipMeta;
        address reseller;
        address member;
        bool autoClaimLock;
    }
    
    struct Reseller{
        bool exist;
        uint startTime;
        uint expiry;
        uint totalCustomers;
        uint256 allocatedHashRate;
        uint256 usedHashRate;
        uint256 maxHashRatePerAddress;
        address[] members;
        address merchantContract;
    }
    constructor(){}
    
    modifier onlyReseller() {
        require(_resellers[msg.sender].exist, "LittleDogeCoinReward: caller is not a reseller");
        _;
    }
    
    modifier onlyMiner() {
        require(_miners[msg.sender].exist, "LittleDogeCoinReward: caller is not a miner");
        _;
    }
    
    // sets minted token wallet address;
    function setRewardSourceAddress(address rewardSourceAddress)public onlyOwner{
        _rewardSourceAddress = rewardSourceAddress;
    }
    function setLittleDogeAddress(address littleDogeCoinAddress) public onlyAdmin{
        _littleDogeCoin = littleDogeCoinAddress;
    }
    
    function setResellerContract(address resellerAddress, address contractAddress) internal returns (uint code){
        _resellers[resellerAddress].merchantContract = contractAddress;
        return 0;
    }
    
    function addUpdateReseller(address resellerAddress, uint256 allocatedHashRate, uint256 maxHashRatePerAddress, uint expiry) internal returns(uint code){
        require(expiry > 0, "LittleDogeCoinReward: expiry too low");
        _resellers[resellerAddress].startTime = _resellers[resellerAddress].startTime == 0 ? block.timestamp: _resellers[resellerAddress].startTime;
        _resellers[resellerAddress].maxHashRatePerAddress = maxHashRatePerAddress;
        _resellers[resellerAddress].expiry = block.timestamp.add(expiry);
        if(_resellers[resellerAddress].exist == false){
            _totalResellers += 1;
            _resellers[resellerAddress].exist = true;
            _resellers[resellerAddress].allocatedHashRate = allocatedHashRate;
            _currentAllocatedHashRate += allocatedHashRate;
        }else{
            _currentAllocatedHashRate=_currentAllocatedHashRate.sub(_resellers[resellerAddress].allocatedHashRate,"LittleDogeCoinReward: allocatedHashRate calculation error");
            _resellers[resellerAddress].allocatedHashRate = allocatedHashRate;
            _currentAllocatedHashRate += allocatedHashRate;
        }
        require(_currentAllocatedHashRate <= _maxHashRate,"");
        return 0;
    }
    
    function getResellerInfo(address resellerAddress) public view returns(uint256 allocatedHashRate, uint256 maxHashRatePerAddress, uint startTime, uint256 usedHashRate, uint expiry, bool expired){
        return (_resellers[resellerAddress].allocatedHashRate, _resellers[resellerAddress].maxHashRatePerAddress, _resellers[resellerAddress].startTime, _resellers[resellerAddress].usedHashRate, _resellers[resellerAddress].expiry, _resellers[resellerAddress].expiry < block.timestamp);
    }
    
    function getMinerInfo(address minerAddress) public view returns(uint startTime, uint expiry, uint hashRate, address reseller, uint256 claimables, bool expired){
        return(_miners[minerAddress].startTime, _miners[minerAddress].expiry, _miners[minerAddress].hashRate, _miners[minerAddress].reseller, claimable(minerAddress), _miners[minerAddress].expiry < block.timestamp);
    }
    
    function getHashRatePerToken(uint tokenPerBlock)public pure returns (uint hashRate){
        return tokenPerBlock.mul(86400);//0.000086400
    }
    
    function addUpdateMiner(address minerAddress, address resellerAddress, uint256 hashRate, uint expiry) internal returns(uint code){
        require(_miners[minerAddress].exist == false || _miners[minerAddress].exist == true && _miners[minerAddress].reseller ==resellerAddress,"LilDOGE::miner can only buy in one reseller");
        require(expiry > 0,"LittleDogeCoinReward:: duration too low");
        require(hashRate > 0,"LittleDogeCoinReward:: hashRate too low");
        require(_resellers[resellerAddress].maxHashRatePerAddress >= hashRate,"LittleDogeCoinReward:: hashRate too high");
        require(_resellers[resellerAddress].expiry >= block.timestamp,"LittleDogeCoinReward:: reseller account already expired");
        if(isMiner(minerAddress)){
            rewardMinerToken(minerAddress);
        }
        
        if(_miners[minerAddress].exist == false) {
            _totalMiners += 1;
            _miners[minerAddress].exist = true;
            _resellers[resellerAddress].members.push(minerAddress);
        }
        _miners[minerAddress].startTime = block.timestamp;
        _miners[minerAddress].expiry = block.timestamp.add(expiry);
        _miners[minerAddress].hashRate = hashRate;
        _miners[minerAddress].reseller = resellerAddress;
        _currentRewardHashRate += hashRate;
        _resellers[resellerAddress].usedHashRate+=hashRate;
        return 0;
    }
    
    function setupReseller(address resellerAddress, uint256 allocatedHashRate, uint256 maxHashRatePerAddress, uint expiry) public override onlyAuthorizedContract returns(uint code){
        return addUpdateReseller(resellerAddress, allocatedHashRate, maxHashRatePerAddress, expiry);
    }
    
    function addReseller(address resellerAddress, uint256 allocatedHashRate, uint256 maxHashRatePerAddress, uint expiry) public onlyAdmin returns(uint code){
        addUpdateReseller(resellerAddress, allocatedHashRate, maxHashRatePerAddress, expiry);
        return 0;
    }
    
    function updateReseller(address resellerAddress, uint256 allocatedHashRate, uint256 maxHashRatePerAddress, uint expiry) public onlyAdmin returns(uint code){
        addUpdateReseller(resellerAddress, allocatedHashRate, maxHashRatePerAddress, expiry);
        return 0;
    }

    function setupMiner(address minerAddress, address resellerAddress, uint256 hashRate, uint duration) external override onlyAuthorizedContract returns(uint code){
        return addUpdateMiner(minerAddress, resellerAddress, hashRate, duration);
    }
    
    function addMiner(address minerAddress, address resellerAddress, uint256 hashRate, uint duration) external onlyReseller returns(uint code){
        return addUpdateMiner(minerAddress, resellerAddress, hashRate, duration);
    }
    
    function claimable(address minerAddress) public view returns (uint256 claimables){
        uint totalBlocks =0;
        if(_miners[minerAddress].expiry > block.timestamp){
            totalBlocks = block.timestamp.sub(_miners[minerAddress].startTime, "LittleDogeCoinReward: error calculating totalBlock");
        }else if(_miners[msg.sender].hashRate > 0 && _miners[minerAddress].expiry < block.timestamp){
            totalBlocks = _miners[msg.sender].expiry.sub(_miners[minerAddress].startTime, "LittleDogeCoinReward: error calculating totalBlock for expired");
        }else{
            return 0;
        }
        return _miners[minerAddress].hashRate.mul(totalBlocks);
    }
    
    function claim(address minerAddress) internal onlyMiner returns (uint256 claimables){
        uint256 cl = claimable(minerAddress);
        if(_miners[minerAddress].expiry > block.timestamp){
            _miners[minerAddress].startTime = block.timestamp;
        }else if(_miners[minerAddress].hashRate > 0 && _miners[minerAddress].expiry < block.timestamp){
            _currentRewardHashRate -= _miners[minerAddress].hashRate;
            _resellers[_miners[minerAddress].reseller].usedHashRate -= _miners[minerAddress].hashRate;
            _miners[minerAddress].hashRate = 0;
        }
        return cl;
    }
    
    function isReseller(address resellerAddress) public view returns (bool){
        return _resellers[resellerAddress].exist;
    }
    
    function isMiner(address minerAddress) public view returns (bool){
        return _miners[minerAddress].exist;
    }
    
    function rewardMinerToken(address minerAddress)internal onlyMiner {
        IBEP20(_littleDogeCoin).transferFrom(_rewardSourceAddress, minerAddress, claim(minerAddress));
    }
    
    function claimRewardTokens()public onlyMiner{
        rewardMinerToken(msg.sender);
    }
}