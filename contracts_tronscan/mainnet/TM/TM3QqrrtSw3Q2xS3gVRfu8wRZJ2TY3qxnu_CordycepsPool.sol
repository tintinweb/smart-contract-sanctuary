//SourceUnit: CordycepsPool.prod.sol

/***** Submitted for verification at Tronscan.org on 2020-11-5
*
*  ______     ______     ______     _____     __  __     ______     ______     ______   ______     ______   __     __   __     ______     __   __     ______     ______    
* /\  ___\   /\  __ \   /\  == \   /\  __-.  /\ \_\ \   /\  ___\   /\  ___\   /\  == \ /\  ___\   /\  ___\ /\ \   /\ "-.\ \   /\  __ \   /\ "-.\ \   /\  ___\   /\  ___\   
* \ \ \____  \ \ \/\ \  \ \  __<   \ \ \/\ \ \ \____ \  \ \ \____  \ \  __\   \ \  _-/ \ \___  \  \ \  __\ \ \ \  \ \ \-.  \  \ \  __ \  \ \ \-.  \  \ \ \____  \ \  __\   
*  \ \_____\  \ \_____\  \ \_\ \_\  \ \____-  \/\_____\  \ \_____\  \ \_____\  \ \_\    \/\_____\  \ \_\    \ \_\  \ \_\\"\_\  \ \_\ \_\  \ \_\\"\_\  \ \_____\  \ \_____\ 
*   \/_____/   \/_____/   \/_/ /_/   \/____/   \/_____/   \/_____/   \/_____/   \/_/     \/_____/   \/_/     \/_/   \/_/ \/_/   \/_/\/_/   \/_/ \/_/   \/_____/   \/_____/ 
*
*    https://cordyceps.finance
*
*    file: ./CordycepsPool.sol
*    time:  2020-9-27
*
*    Copyright (c) 2020 Cordyceps.finance 
*/  

pragma solidity ^0.5.8;

interface IERC20  {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    function ownerOf(uint256 tokenId) public view returns (address owner);
    
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
   
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}



contract Context {
    constructor () internal {}
    // solhint-disable-previous-line no-empty-blocks
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ICordyFactory{
     function getCordyceps(uint256 _tokenId) view public returns
    (
        string memory _name,
        uint256 _level,
        uint256 _birth,
        uint256 _blockNum,
        uint256 _quality,
        address _creater,
        address _owner

    );
}

// CordycepsPool
contract CordycepsPool is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    ICordyFactory cordyFactory;
    IERC20 targetToken;
    address devAddress;

    struct User{
        uint256 id;
        address addr;
        uint256 ref;
        uint256 refSum;
        uint256 bonus;
    }

    struct UserStakeInfo {
        uint256 amount;
        uint256 time;
        uint256 userRewardPerTokenPaid;
        uint256 rewards;
    }
    struct PoolToken{
        IERC20 lp;  //token or lp token
        IERC721 nft;  //nft token
        uint256 decimals;
    }

    struct PoolInfo {
        uint256 minLevel;
        uint256 initReward;
        uint256 startTime;
        uint256 duration;
        uint256 allocPoint;
        uint256 periodFinish;
        uint256 secReward;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 totalSupply;
        uint256 currentPeriod;
        uint256 closeTime;
    }

    struct ClearMiner{
        uint256 pid;
        uint256 uid;
        uint256 amount;
        uint256 time;
    }
    struct PoolRate{
        uint256 rate;
        uint256 halveRate;
        uint256 halveRange;
        uint256 halveMax;
    }
    struct PoolRateTime{
        uint256 duration;
        uint256 maxRate;
    }

    struct BonusRate{
        uint256 ref;
        uint256 dev;
        uint256 pool;
    }
    uint256 public userIndex;
    uint256 public poolIndex;
    uint256 public clearMinerIndex;
    uint256 public bonusPeriodIndex;
    BonusRate public bonusRate;
    PoolRateTime public poolRateTime;
    uint256 public bonusPool;
    uint256 public devPool;
    uint256 public poolStakeMax;

    mapping(uint256=>User) public indexToUser;
    mapping(uint256=>ClearMiner) public indexToClearMiner;
    mapping(address=>uint256) public addrToUserId;
    mapping(address=>mapping(uint256=>uint256[])) public addrPidToStakeTids;
    mapping(uint256 => mapping(address => UserStakeInfo)) public pidToUserStakeInfo;
    mapping(address => uint256[]) public addrToClearMiners;
    mapping(uint256 => PoolRate) public pidToPoolRate;
    mapping(uint256 => uint256) public pidToTotalRewards;
    
    mapping(uint256 => uint256) public bonusPoolPeriodToAmount;
    mapping(uint256 => PoolInfo) public indexToPoolInfo;
    mapping(uint256=>PoolToken) public pidToPoolToken;
    mapping(address=>mapping(uint256=>bool)) addTidToIsReady;
    constructor (address _tokenAddress,address _devAddress,address _factoryAddress) public {
        targetToken = IERC20(_tokenAddress); 
        cordyFactory=ICordyFactory(_factoryAddress);
        devAddress=_devAddress;
        bonusRate=BonusRate(1e3,3e3,6e3);
        poolRateTime=PoolRateTime(86400*5,6e3);
        poolStakeMax=10;
    }
    event PoolRewardAdded(uint256 indexed pid, uint256 reward);
    event UserAdded(uint256 indexed uid, address user);
    event PoolMinerAdded(uint256 indexed pid,uint256 indexed uid,address user);
    event PoolMinerRemoved(uint256 indexed pid,uint256 indexed uid,address user);
    event MinerCleared(uint256 indexed pid,address indexed user,uint256 amount);
    event Verified(address indexed user, uint256 indexed pid, uint256 amount);
    event Staked(address indexed user, uint256 indexed pid, uint256 indexed tid);
    event UnStaked(address indexed user, uint256 indexed pid, uint256 indexed tid);
    event Withdrawn(address indexed user, uint256 indexed pid, uint256 amount);
    event PoolRewardPaid(address indexed user, uint256 indexed pid, uint256 reward);
    event BonusPoolPeriodPaid(uint256 indexed peid, uint256 bonus);
    event UserBonusPaid(address indexed user, uint256 bonus);
    event DevBonusPaid(address indexed user, uint256 bonus);
    event PoolRateChanged(uint256 indexed pid, uint256 rate,uint256 hrate,uint256 hrange,uint256 hmax);
    event BonusRateChanged(uint256 dev,uint256 ref,uint256 pool);
    event PoolRateTimeChanged(uint256 duration,uint256 mrate);
    event PoolNFTReceived(address operator, address from, uint256 tokenId, bytes data);

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4) {
        if(!addTidToIsReady[from][tokenId]) return 0;
        emit PoolNFTReceived(operator, from, tokenId, data);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
    function addPool(address _token, uint256 _decimals, uint256 _startTime, uint256 _allocPoint,
        uint256 _initReward, uint256 _duration,uint256 _rate, uint256 _halveRate,uint256 _halveRange,uint256 _halveMax) external onlyOwner{
        poolIndex++;
        pidToPoolToken[poolIndex]=PoolToken(IERC20(_token),IERC721(address(0)),_decimals);
        _add(0,_startTime,_allocPoint,_initReward,_duration,_rate,_halveRate,_halveRange,_halveMax);
     
    }
    function addNFTPool(address _nftToken,uint256 _minLevel, uint256 _decimals, uint256 _startTime, uint256 _allocPoint,
        uint256 _initReward, uint256 _duration,uint256 _rate, uint256 _halveRate,uint256 _halveRange,uint256 _halveMax) external onlyOwner{
        poolIndex++;
        pidToPoolToken[poolIndex]=PoolToken(IERC20(address(0)),IERC721(_nftToken),_decimals);
        _add(_minLevel,_startTime,_allocPoint,_initReward,_duration,_rate,_halveRate,_halveRange,_halveMax);
     
    }
    function _add(uint256 _minLevel, uint256 _startTime, uint256 _allocPoint,
        uint256 _initReward, uint256 _duration,uint256 _rate, uint256 _halveRate,uint256 _halveRange,uint256 _halveMax) internal {
        require(_allocPoint >= _initReward, "error: allocPoint less than initReward");
        if (_halveRange > 0) {
            require(_halveRate < _halveMax, "error: halveRate must less then halveMax");
        }
        
        uint256 initReward= _initReward.mul(1e18);
        
        uint256 startTime = block.timestamp > _startTime ? block.timestamp : _startTime;
        uint256 periodFinish = startTime.add(_duration);
        uint256 closeTime = _allocPoint == _initReward ? periodFinish : 0;
   
        pidToPoolRate[poolIndex]=PoolRate(_rate,_halveRate,_halveRange,_halveMax);
        indexToPoolInfo[poolIndex] = PoolInfo({
        minLevel:_minLevel,
        initReward : initReward,
        startTime : startTime,
        duration:_duration,
        allocPoint:_allocPoint.mul(1e18),
        periodFinish : periodFinish,
        secReward : initReward.div(_duration),
        lastUpdateTime : startTime,
        rewardPerTokenStored : 0,
        totalSupply : 0,
        currentPeriod : 1,
        closeTime : closeTime
        });
      
        pidToTotalRewards[poolIndex] = initReward;
        emit PoolRewardAdded(poolIndex, initReward);
    }
 
    function register(uint256 _refId) public checkUser(msg.sender,_refId) {}
   
    function getUserBalStatus(uint256 _pid, uint256 _uid,address _account) view public returns (bool _status,uint256 _stakeAmount){
        require(poolIndex>=_pid);
        User memory user;
        if(_uid>0)user=indexToUser[_uid];
        else if(_account!=address(0))user=indexToUser[addrToUserId[_account]];
        _stakeAmount=pidToUserStakeInfo[_pid][user.addr].amount;
        if(_stakeAmount==0) _status=true;
        else _status=pidToPoolToken[_pid].lp.balanceOf(user.addr)>=_stakeAmount;
    }
    function getUserStakedTids(uint256 _pid) view public returns(uint256[] memory){
        return addrPidToStakeTids[msg.sender][_pid];
    }

    function getClearMinerIds(address _account) view public returns(uint256[] memory){
        return addrToClearMiners[_account];
    }
    

    function clearMinerByAddr(uint256 _pid, address _account) public returns (bool){
        return !_checkTokenBalance(_pid,_account);
    }

    function clearMinerById(uint256 _pid, uint256 _uid) public checkPool(_pid) {
        require(_uid>0&&userIndex>=_uid);
        address addr= indexToUser[_uid].addr;
        if(addr!=address(0)){
            uint256 amount=pidToUserStakeInfo[_pid][addr].amount;
            if(amount>0&&clearMinerByAddr(_pid,addr)){
                clearMinerIndex++;
                indexToClearMiner[clearMinerIndex]=ClearMiner(_pid,_uid,amount,now);
                addrToClearMiners[msg.sender].push(clearMinerIndex);
            }
        }
    }
   

    function setAllocPoint(uint256 _pid, uint256 _allocPoint) external onlyOwner checkPool(_pid) {
        require(_allocPoint > 0, "allocPoint error");
        indexToPoolInfo[_pid].allocPoint=_allocPoint.mul(1e18);
    }
    function setPoolStakeMax(uint256 _max) external onlyOwner{
        poolStakeMax=_max;
    }
    function setPoolRate(uint256 _pid, uint256 _rate,uint256 _halveRate,uint256 _halveRange,uint256 _halveMax) checkPool(_pid)  external onlyOwner  {
        PoolRate storage poolRate=pidToPoolRate[_pid];
        if(_rate>0) poolRate.rate=_rate;
        if(_halveRate>0) poolRate.halveRate=_halveRate;
        if(_halveRange>0) poolRate.halveRange=_halveRange;
        if(_halveMax>0) poolRate.halveMax=_halveMax;
        emit PoolRateChanged(_pid,_rate,_halveRate,_halveRange,_halveMax);
    }
    function setBonusRate(uint256 _devRate,uint256 _refRate,uint256 _poolRate) external onlyOwner  {
        if(_devRate>0) bonusRate.dev=_devRate;
        if(_refRate>0) bonusRate.ref=_refRate;
        if(_poolRate>0) bonusRate.pool=_poolRate;
        emit BonusRateChanged(_devRate,_refRate,_poolRate);
    }
    function setPoolRateTime(uint256 _duration,uint256 _maxRate) external onlyOwner  {
        if(_duration>0) poolRateTime.duration=_duration;
        if(_maxRate>0) poolRateTime.maxRate=_maxRate;
        emit PoolRateTimeChanged(_duration,_maxRate);
    }
   
    function lastTimeRewardApplicable(uint256 _ptime) public view returns (uint256) {
        return Math.min(block.timestamp, _ptime);
    }

    function rewardPerToken(uint256 _pid) public view returns (uint256) {
        PoolInfo memory pool = indexToPoolInfo[_pid];
        if (pool.totalSupply == 0) {
            return pool.rewardPerTokenStored;
        }
        return
        pool.rewardPerTokenStored.add(
            lastTimeRewardApplicable(pool.periodFinish)
            .sub(pool.lastUpdateTime)
            .mul(pool.secReward)
            .mul(10 ** pidToPoolToken[_pid].decimals)
            .div(pool.totalSupply)
        );
    }
    function _isPoolNFT(uint256 _pid) view internal returns(bool){
        return pidToPoolToken[_pid].nft!=IERC721(address(0));
    }

    function earned(uint256 _pid, address _account) view public  returns (uint256) {
        PoolInfo memory pool = indexToPoolInfo[_pid];
        UserStakeInfo memory stake = pidToUserStakeInfo[_pid][_account];
        if(stake.amount==0&&!_isPoolNFT(_pid)) return 0;
        uint256 calculatedEarned = stake.amount
        .mul(rewardPerToken(_pid).sub(stake.userRewardPerTokenPaid))
        .div(10 ** pidToPoolToken[_pid].decimals)
        .add(stake.rewards);
        if (calculatedEarned > pool.allocPoint) {
            calculatedEarned = pool.allocPoint;
        }
        uint256 poolBalance = targetToken.balanceOf(address(this));
        if (calculatedEarned > poolBalance) return poolBalance;
        return calculatedEarned;
    }

    function getPoolHarvestRate(uint256 _pid,address _account) view public returns (uint256){
        UserStakeInfo memory stake=pidToUserStakeInfo[_pid][_account];
        if(stake.time==0||(stake.amount==0&&!_isPoolNFT(_pid))) return 0;
        uint256 time=block.timestamp.sub(stake.time);
        uint256 moreRate=time>poolRateTime.duration?0:poolRateTime.maxRate.sub(time.mul(poolRateTime.maxRate.mul(1e5).div(poolRateTime.duration)).div(1e5));
        return pidToPoolRate[_pid].rate.add(moreRate);
    }
    
    function _getPoolRateRewards(uint256 _pid,address _account,uint256 _reward) internal returns(uint256 _refBonus,uint256 _devBonus,uint256 _poolBonus){
        uint256 harRate=getPoolHarvestRate(_pid,_account);
        uint256 rateReward=_reward.mul(harRate).div(1e4);
        uint256 refId=indexToUser[addrToUserId[_account]].ref;
        _refBonus=refId>0?rateReward.mul(bonusRate.ref).div(1e4):0;
        if(_refBonus>0) indexToUser[refId].bonus=indexToUser[refId].bonus.add(_refBonus);
        _devBonus=rateReward.mul(bonusRate.dev).div(1e4);
        _poolBonus=rateReward.sub(_refBonus).sub(_devBonus);
    }

    
    function verify(uint256 _pid,uint256 _refId) public checkUser(msg.sender, _refId) checkPool(_pid)  {
        _updateReward(_pid, msg.sender);
        _checkhalve(_pid);
        PoolInfo storage pool = indexToPoolInfo[_pid];
        require(pidToPoolToken[_pid].lp!=IERC20(address(0)));
        uint256 bal= pidToPoolToken[_pid].lp.balanceOf(msg.sender);
        require(bal>0, "Insufficient funds");
        UserStakeInfo storage stake = pidToUserStakeInfo[_pid][msg.sender];
        require(bal!=stake.amount, "token not need to update");
        if(stake.amount>bal){
            pool.totalSupply = pool.totalSupply.sub(stake.amount.sub(bal));
        }else{
            pool.totalSupply = pool.totalSupply.add(bal.sub(stake.amount));
        }
      
        stake.amount = bal;
        stake.time=now;
        emit Verified(msg.sender, _pid, bal);
    }

    //NFT stake 
    function stake(uint256 _pid,uint256 _tid,uint256 _refId) public checkUser(msg.sender, _refId) checkPool(_pid) {
        _updateReward(_pid, msg.sender);
        _checkhalve(_pid);
        PoolInfo storage pool = indexToPoolInfo[_pid];
        require(pidToPoolToken[_pid].nft.ownerOf(_tid)==msg.sender,"NFT owner error");
        require(addrPidToStakeTids[msg.sender][_pid].length<poolStakeMax,"NFT over maximum number");
        uint256 level;
        uint256 quality;
        (,level,,,quality,,)=cordyFactory.getCordyceps(_tid);
        require(level>=pool.minLevel,"NFT level error");
        addTidToIsReady[msg.sender][_tid]=true;
        UserStakeInfo storage stake = pidToUserStakeInfo[_pid][msg.sender];
        pool.totalSupply = pool.totalSupply.add(quality);
        stake.amount = stake.amount.add(quality);
        stake.time=now;
        pidToPoolToken[_pid].nft.safeTransferFrom(msg.sender, address(this), _tid);
        addrPidToStakeTids[msg.sender][_pid].push(_tid);
        addTidToIsReady[msg.sender][_tid]=false;
        emit Staked(msg.sender, _pid, _tid);
    }
    function unStake(uint256 _pid,uint256 _tid,uint256 _refId) public checkUser(msg.sender, _refId)  {
        _updateReward(_pid, msg.sender);
        _checkhalve(_pid);
        PoolInfo storage pool = indexToPoolInfo[_pid];
        require(pidToPoolToken[_pid].nft!=IERC721(address(0)),"NFT pool token error");
        uint256 tIndex=_arrayExist(addrPidToStakeTids[msg.sender][_pid],_tid);
        require(tIndex>0,"NFT id error");
        uint256 level;
        uint256 quality;
        (,level,,,quality,,)=cordyFactory.getCordyceps(_tid);
        require(level>0,"NFT level error");

        UserStakeInfo storage stake = pidToUserStakeInfo[_pid][msg.sender];
        pool.totalSupply = pool.totalSupply.sub(quality);
        stake.amount = stake.amount.sub(quality);
        stake.time=now;
        _arrayDelete(addrPidToStakeTids[msg.sender][_pid],tIndex-1);
        pidToPoolToken[_pid].nft.safeTransferFrom(address(this),msg.sender, _tid);
        emit UnStaked(msg.sender, _pid, _tid);
    }


    function harvest(uint256 _pid,uint256 _refId) public checkUser(msg.sender,_refId) checkPool(_pid) {
        if(!_checkTokenBalance(_pid,msg.sender)) return;
        uint256 reward=_updateReward(_pid, msg.sender);
        _checkhalve(_pid);
        if(reward<=0) return;
        uint256 refBonus;
        uint256 devBonus;
        uint256 poolBonus;
        (refBonus,devBonus,poolBonus)=_getPoolRateRewards(_pid,msg.sender,reward);
        devPool=devPool.add(devBonus);
        bonusPool=bonusPool.add(poolBonus);
        reward=reward.sub(devBonus).sub(poolBonus).sub(refBonus);
        if(reward>0){
            UserStakeInfo storage stake=pidToUserStakeInfo[_pid][msg.sender];
            stake.rewards = 0;
            stake.time=now;
            targetToken.safeTransfer(msg.sender, reward);
            emit PoolRewardPaid(msg.sender, _pid, reward);
        }
            
    }
    function withdrawBonus(uint256 _refId) public checkUser(msg.sender,_refId) {
        User storage user=indexToUser[addrToUserId[msg.sender]];
        require(user.bonus>0,"not referral Bonus");
        uint256 bon=user.bonus;
        user.bonus=0;
        targetToken.safeTransfer(msg.sender, bon);
        emit UserBonusPaid(msg.sender, bon);
    }

    //Bonus To Token Holders
    function withdrawPoolBonus(uint256 _rate,address _account) public onlyOwner{
        require(_rate>0);
        require(_account!=address(0));
        uint256 bon=bonusPool.mul(_rate).div(1e4);
        bonusPool=bonusPool.sub(bon);
        bonusPeriodIndex++;
        targetToken.safeTransfer(_account,bon);
        bonusPoolPeriodToAmount[bonusPeriodIndex]=bon;
        emit BonusPoolPeriodPaid(bonusPeriodIndex,bon);
    }
  

    function withdrawDevBonus() public onlyOwner {
        require(devAddress!=address(0));
        require(devPool>0);
        uint256 bon=devPool;
        devPool=0;
        targetToken.safeTransfer(devAddress, bon);
        emit DevBonusPaid(msg.sender, bon);
    }

    function _getMultiplier(uint256 _currentPeriod, uint256 _rate, uint256 _range, uint256 _max) pure private returns (uint256){
        if (_currentPeriod > 1 && _range > 0) {
            return Math.min(_max, _rate.add(_range));
        }
        return _rate;
    }

    function _arrayDelete(uint256[] storage _array,uint256 _index) internal returns(bool) {
        if (_index >= _array.length) return false;

        for (uint256 i = _index; i<_array.length-1; ++i){
            _array[i] = _array[i+1];
        }
        delete _array[_array.length-1];
        _array.length--;
        return true;
    }
   
    function _arrayExist(uint256[] memory _array,uint256 _val) internal returns(uint256){
        for (uint256 i = 0; i<_array.length; ++i){
            if(_val==_array[i]) return i+1;
        }
        return 0;
    }

    modifier checkUser(address _account,uint256 _refId){
        uint256 uid=addrToUserId[_account];
        if(uid==0){
            uint256 refId=0;
            User storage ref=indexToUser[_refId];
            if(ref.id>0){
                refId=ref.id;
                ref.refSum++;
            }
            userIndex++;
            indexToUser[userIndex]=User(userIndex,_account,refId,0,0);
            addrToUserId[_account]=userIndex;
            emit UserAdded(userIndex,_account);
        }
        _;
        
    }
    
     function _updateReward(uint256 _pid, address _account) internal returns(uint256){
        PoolInfo storage pool = indexToPoolInfo[_pid];
        uint256 rewardPerTokenStored = rewardPerToken(_pid);
        pool.rewardPerTokenStored = rewardPerTokenStored;
        pool.lastUpdateTime = lastTimeRewardApplicable(pool.periodFinish);
        if (_account != address(0)) {
            UserStakeInfo storage stake=pidToUserStakeInfo[_pid][_account];
            stake.rewards = earned(_pid, _account);
            stake.userRewardPerTokenPaid = rewardPerTokenStored;
            return stake.rewards;
        }
        return 0;
    }
    function _checkTokenBalance(uint256 _pid, address _account) internal returns (bool){
        if(_isPoolNFT(_pid)) return true;
        PoolInfo storage pool = indexToPoolInfo[_pid];
        uint256 bal= pidToPoolToken[_pid].lp.balanceOf(_account);
        UserStakeInfo memory stake = pidToUserStakeInfo[_pid][_account];
        if(stake.amount==0) return false;
        if(bal<stake.amount){
            pool.totalSupply = pool.totalSupply.sub(stake.amount);
            delete pidToUserStakeInfo[_pid][_account];
            emit MinerCleared(_pid,_account,stake.amount);
            return false;
        } 
        return true;
    }
    function _checkhalve(uint256 _pid) internal{
        PoolInfo storage pool = indexToPoolInfo[_pid];
        if(pool.closeTime>0&&now>=pool.closeTime) return;

        PoolRate storage poolRate=pidToPoolRate[_pid];
        if (now >= pool.periodFinish) {
            uint256 rewardMultiplier = _getMultiplier(pool.currentPeriod, poolRate.halveRate, poolRate.halveRange, poolRate.halveMax);
            uint256 currentReward = pool.initReward.mul(rewardMultiplier).div(1e4);
            uint256 totalReward = pidToTotalRewards[_pid];
            if (totalReward.add(currentReward) > pool.allocPoint) {
                currentReward = pool.allocPoint.sub(totalReward);
            }
            if (currentReward > 0) {
                pidToTotalRewards[_pid] = totalReward.add(currentReward);
                pool.currentPeriod++;
                if (pidToTotalRewards[_pid] == pool.allocPoint) {
                    pool.closeTime = block.timestamp.add(pool.duration);
                }
            }
            poolRate.halveRate = rewardMultiplier;
            pool.initReward = currentReward;
            pool.lastUpdateTime = block.timestamp;
            pool.secReward = currentReward.div(pool.duration);
            pool.periodFinish = block.timestamp.add(pool.duration);
            emit PoolRewardAdded(_pid, currentReward);
        }
    }
    modifier checkPool(uint256 _pid){
        require(_pid>0&&poolIndex >= _pid, "the pool not exist");
        PoolInfo memory pool=indexToPoolInfo[_pid];
        require(block.timestamp >= pool.startTime, "the pool has not started yet");
        require(pool.closeTime==0||pool.closeTime>block.timestamp, "the pool is over");
        _;
    }
    
}

// ******** library *********/

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        // solhint-disable-next-line avoid-call-value
        (bool success,) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: TRC20 operation did not succeed");
        }
    }
}

//math

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


// safeMath

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}