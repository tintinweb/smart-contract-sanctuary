// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;
import "./IMineable.sol";
import "./Authorization.sol";
import "./IBEP20.sol";
import "./Gateway.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./LilDOGE.sol";
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
    LittleDogeCoin public _littleDogeCoin;
    // destination of minted tokens;
    address public _mintAddress;
    struct Miner{
        uint256 hashRate;
        uint startBlock;
        uint blockExpiry;
        bool exist;
        string membershipMeta;
        address reseller;
        address member;
        bool autoClaimLock;
    }
    
    struct Reseller{
        bool exist;
        uint startBlock;
        uint blockExpiry;
        uint totalCustomers;
        uint256 allocatedHashRate;
        uint256 usedHashRate;
        uint256 maxHashRatePerAddress;
        address[] members;
        address merchantContract;
    }
    constructor(){}
    
    modifier onlyReseller() {
        require(_resellers[msg.sender].exist, "Mineable: caller is not a reseller");
        _;
    }
    
    modifier onlyMiner() {
        require(_miners[msg.sender].exist, "Mineable: caller is not a miner");
        _;
    }
    
    // sets minted token wallet address;
    function setMintAddress(address mintAddress)public onlyOwner{
        _mintAddress = mintAddress;
    }
    function setLittleDogeAddress(address littleDogeCoinAddress) public onlyAdmin{
        _littleDogeCoin = LittleDogeCoin(littleDogeCoinAddress);
    }
    
    function setResellerContract(address resellerAddress, address contractAddress) internal returns (uint code){
        _resellers[resellerAddress].merchantContract = contractAddress;
        return 0;
    }
    
    function addUpdateReseller(address resellerAddress, uint256 allocatedHashRate, uint256 maxHashRatePerAddress, uint blockExpiry) internal returns(uint code){
        require(blockExpiry > 0, "Mineable: blockExpiry too low");
        _resellers[resellerAddress].startBlock = _resellers[resellerAddress].startBlock == 0 ? block.number: _resellers[resellerAddress].startBlock;
        _resellers[resellerAddress].maxHashRatePerAddress = maxHashRatePerAddress;
        _resellers[resellerAddress].blockExpiry = block.number.add(blockExpiry);
        if(_resellers[resellerAddress].exist == false){
            _totalResellers += 1;
            _resellers[resellerAddress].exist = true;
            _resellers[resellerAddress].allocatedHashRate = allocatedHashRate;
            _currentAllocatedHashRate += allocatedHashRate;
        }else{
            _currentAllocatedHashRate=_currentAllocatedHashRate.sub(_resellers[resellerAddress].allocatedHashRate,"Mineable: allocatedHashRate calculation error");
            _resellers[resellerAddress].allocatedHashRate = allocatedHashRate;
            _currentAllocatedHashRate += allocatedHashRate;
        }
        require(_currentAllocatedHashRate <= _maxHashRate,"");
        return 0;
    }
    
    function getResellerInfo(address resellerAddress) public view returns(uint256 allocatedHashRate, uint256 maxHashRatePerAddress, uint startBlock, uint256 usedHashRate, uint expiry, bool expired){
        return (_resellers[resellerAddress].allocatedHashRate, _resellers[resellerAddress].maxHashRatePerAddress, _resellers[resellerAddress].startBlock, _resellers[resellerAddress].usedHashRate, _resellers[resellerAddress].blockExpiry, _resellers[resellerAddress].blockExpiry < block.number);
    }
    
    function getMinerInfo(address minerAddress) public view returns(uint startBlock, uint blockExpiry, uint hashRate, address reseller, uint256 claimables, bool expired){
        return(_miners[minerAddress].startBlock, _miners[minerAddress].blockExpiry, _miners[minerAddress].hashRate, _miners[minerAddress].reseller, claimable(minerAddress), _miners[minerAddress].blockExpiry < block.number);
    }
    
    function getHashRatePerToken(uint tokenPerBlock)public pure returns (uint hashRate){
        return tokenPerBlock.mul(86400);//0.000086400
    }
    
    function addUpdateMiner(address minerAddress, address resellerAddress, uint256 hashRate, uint blockExpiry) internal returns(uint code){
        require(_miners[minerAddress].exist == false || _miners[minerAddress].exist == true && _miners[minerAddress].reseller ==resellerAddress,"LilDOGE::miner can only buy in one reseller");
        require(blockExpiry > 0,"Mineable:: duration too low");
        require(hashRate > 0,"Mineable:: hashRate too low");
        require(_resellers[resellerAddress].maxHashRatePerAddress >= hashRate,"LilDOGE:: hashRate too high");
        require(_resellers[resellerAddress].blockExpiry >= block.number,"LilDOGE:: reseller account already expired");
        if(isMiner(minerAddress)){
            rewardMinerToken(minerAddress);
        }
        
        if(_miners[minerAddress].exist == false) {
            _totalMiners += 1;
            _miners[minerAddress].exist = true;
            _resellers[resellerAddress].members.push(minerAddress);
        }
        _miners[minerAddress].startBlock = block.number;
        _miners[minerAddress].blockExpiry = block.number.add(blockExpiry);
        _miners[minerAddress].hashRate = hashRate;
        _miners[minerAddress].reseller = resellerAddress;
        _currentRewardHashRate += hashRate;
        _resellers[resellerAddress].usedHashRate+=hashRate;
        _littleDogeCoin.setMintingRate(_currentRewardHashRate);
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
        if(_miners[minerAddress].blockExpiry > block.number){
            totalBlocks = block.number.sub(_miners[minerAddress].startBlock, "Mineable: error calculating totalBlock");
        }else if(_miners[msg.sender].hashRate > 0 && _miners[minerAddress].blockExpiry < block.number){
            totalBlocks = _miners[msg.sender].blockExpiry.sub(_miners[minerAddress].startBlock, "Mineable: error calculating totalBlock for expired");
        }else{
            return 0;
        }
        return _miners[minerAddress].hashRate.mul(totalBlocks);
    }
    
    function claim(address minerAddress) internal returns (uint256 claimables){
        uint256 cl = claimable(minerAddress);
        if(_miners[minerAddress].blockExpiry > block.number){
            _miners[minerAddress].startBlock = block.number;
        }else if(_miners[minerAddress].hashRate > 0 && _miners[minerAddress].blockExpiry < block.number){
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
    
    function rewardMinerToken(address minerAddress)internal {
        _littleDogeCoin.transferFrom(_mintAddress, minerAddress, claim(minerAddress));
    }
    
    function claimMinedToken()public onlyMiner{
        rewardMinerToken(msg.sender);
    }
}