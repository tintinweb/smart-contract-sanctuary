/**
 *Submitted for verification at BscScan.com on 2021-12-29
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-07
*/

pragma solidity 0.8.0;
// SPDX-License-Identifier: Unlicensed

interface IBEP20 {

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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function _initialize () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

contract RewardPool is Ownable, Initializable {
    using SafeMath for uint;
    
    event rewardWithdrawal( address indexed _holder, uint _amount, uint _time);
    event rewardsReceived( uint _amount, uint _time);
    
    struct CycleSruct {
        uint _cycleCollected;
        uint _currentTotalSupply;
        uint _cycleEndedTimeStamp;
        bool _isCycleActive;
    }
    
    struct holderStruct{
        uint _currentDXBBalance;
        uint _timestamp;
        uint lastUpdatedCycle;
        uint _lastestCycle;
        uint _lastWithdrawnCycle;
        mapping(uint => holderRewardStruct) isEnableForRewards;
        mapping(uint => holdercycleTrackStruct) _cycleTrack;
    }
    
    struct holdercycleTrackStruct{
        uint _fromCycle;
        uint _toCycle;
        uint _pastBalance;
        uint _currentCycleBalance;
    }
    
    struct holderRewardStruct {
        bool isEnableToClaim;
        uint disabledTimeStamp;
    }
    
    uint public currCycle;
    uint public previousBalance;
    uint public estimatedLoop;
    uint public maxCycleReward;
    uint public emergencyWithdrawalPeriod;
    
    IBEP20 public DXB;
    
    mapping(uint => CycleSruct) public cycles;
    mapping(address => holderStruct) public holderWallet;
    mapping(address => bool) public authenticate;
    
    receive() external payable onlyAuth() {
    }
    
    modifier onlyAuth(){
        require(authenticate[_msgSender()]);
        _;
    }
    
    function initialize() external payable initializer {
        _initialize();
        
        currCycle = 1;
        cycles[currCycle]._cycleCollected = msg.value;
        previousBalance = 0;
        estimatedLoop = 30;
        maxCycleReward = 50e18;
        emergencyWithdrawalPeriod = block.timestamp;
    }
    
     /** 
     * @dev Calls updatedDXB() function to set tokens .
     * @param _DXB DXB token.
     * @return bool
     */
    function updatedDXB( IBEP20 _DXB) public onlyOwner returns (bool) {
        require(address(_DXB) != address(0), "TeamVault :: updatedDXB : DXB address is already set");
        DXB = _DXB;
        return true;
    }
    
    function updateEstimatedLoop(uint _eLoop) public onlyOwner returns (bool) {
        estimatedLoop = _eLoop;
        return true;
    }
    
    function updateMaxCycleReward( uint _maxCycleReward) public onlyOwner returns (bool) {
        maxCycleReward = _maxCycleReward;
        return true;
    }
    
    /** 
     * @dev Calls updateAuth() function to set authentication.
     * @param _auth authentication address.
     * @param _status true to enable.
     */
    function updateAuth(address _auth, bool _status) public onlyOwner { authenticate[_auth] = _status; }
    
    /** 
     * @dev Calls updatePool() function to update pool.
     * @return bool
     */
    function updatePool(uint _amount) external onlyAuth() returns (bool) {
        require(_amount > 0, "RewardPool :: updatePool : _amount must not be zero");
            uint _availableBal = _amount;
            
            if(cycles[currCycle]._cycleCollected.add(_availableBal) > maxCycleReward){
                uint _currentPool = uint(maxCycleReward).sub(cycles[currCycle]._cycleCollected);
                uint _liquidityToNextPool = _availableBal.sub(_currentPool);
                
                cycles[currCycle]._cycleCollected = cycles[currCycle]._cycleCollected.add(_currentPool);
                cycles[currCycle]._cycleEndedTimeStamp = block.timestamp;
                
                uint _newCycles = _liquidityToNextPool.div(maxCycleReward);
                
                if(_newCycles > 0){
                    for(uint i=1;i<=_newCycles;i++){
                        _createNewCycle(maxCycleReward);
                        
                        if(cycles[currCycle]._cycleCollected >= maxCycleReward) cycles[currCycle]._cycleEndedTimeStamp = block.timestamp;
                    }
                    _liquidityToNextPool = _liquidityToNextPool.sub(uint(maxCycleReward).mul(_newCycles));
                }
                
                if(_liquidityToNextPool > 0) _createNewCycle(_liquidityToNextPool);
            }
            else{
                cycles[currCycle]._cycleCollected = cycles[currCycle]._cycleCollected.add(_availableBal);
                if((cycles[currCycle]._currentTotalSupply == 0)) _updateCycleInfo(currCycle); 
            }
            
        emit rewardsReceived( _amount, block.timestamp);
        return true;
    }
    
    function _createNewCycle( uint _amount) private {
        currCycle = currCycle.add(1);
        cycles[currCycle]._cycleCollected = cycles[currCycle]._cycleCollected.add(_amount);
        _updateCycleInfo( currCycle);
    }
    
    function _updateCycleInfo( uint _cycle) private returns (bool) {
        cycles[_cycle]._isCycleActive = true;
        cycles[_cycle]._currentTotalSupply = DXB.totalSupply();
        return true;
    }
    
    /** 
     * @dev Calls _calculateReward() function to calculate reward.
     * @param _currentPerShare current reward per share
     * @param _cycleDXBBalance balance of DXB
     * @return uint
     */
    function _calculateReward( uint _currentPerShare, uint _cycleDXBBalance) public pure returns (uint) {
        uint rewardBNB = _currentPerShare.mul(_cycleDXBBalance).div(1e12);
        return rewardBNB.div(1e18);
    }
    
    /** 
     * @dev Calls _getSharePerValue() function to value for a share.
     * @param cycle cycles
     * @return uint
     */
    function _getSharePerValue(uint cycle) public view returns (uint) {
        return (cycles[cycle]._cycleCollected.mul(1e12)).mul(1e18).div(cycles[cycle]._currentTotalSupply);
    }
    
     /** 
     * @dev Calls viewClaimReward() function to view claims to withdraw.
     * @param _holder holder address
     * @return uint
     */
    function viewClaimReward( address _holder) external view returns (uint) {
        uint _cyclesUntill;
        uint totalCycleCount;
        uint _totalReward;
        
        if(holderWallet[_holder]._lastWithdrawnCycle < holderWallet[_holder]._lastestCycle){
            _cyclesUntill =  (holderWallet[_holder]._lastWithdrawnCycle.add(estimatedLoop) > holderWallet[_holder]._lastestCycle) ? holderWallet[_holder]._lastestCycle : holderWallet[_holder]._lastWithdrawnCycle.add(estimatedLoop);            
            for(uint i=holderWallet[_holder]._lastWithdrawnCycle.add(1);i<=_cyclesUntill;i++){
                uint _startCycle = (holderWallet[_holder]._cycleTrack[i]._fromCycle == 0) ? 1 : holderWallet[_holder]._cycleTrack[i]._fromCycle;
                uint _toCycle = holderWallet[_holder]._cycleTrack[i]._toCycle;
                
                if(totalCycleCount.add(_toCycle.sub(_startCycle.sub(1))) > estimatedLoop){
                   return _totalReward;     
                }
                
                for(uint j=_startCycle;j<_toCycle;j++){
                     if(j==0)
                        continue;
                    
                    if(holderWallet[_holder].isEnableForRewards[j].isEnableToClaim){
                        if(holderWallet[_holder].isEnableForRewards[j].disabledTimeStamp < cycles[j]._cycleEndedTimeStamp){
                            if(cycles[j]._cycleEndedTimeStamp.sub(holderWallet[_holder].isEnableForRewards[j].disabledTimeStamp) < 7 days)
                                continue;
                        }
                        else{
                             continue;
                        }
                    }
                        
                    uint _cyclePerShare = _getSharePerValue(j);
                    uint _cyclebalance = holderWallet[_holder]._cycleTrack[i]._pastBalance;
                    if(j == _toCycle.sub(uint(1))) _cyclebalance = holderWallet[_holder]._cycleTrack[i]._currentCycleBalance;
                    _totalReward = _totalReward.add(_calculateReward( _cyclePerShare, _cyclebalance));
                    
                }
                totalCycleCount = totalCycleCount.add(_toCycle);
            }
            
           
        }
        
        if(totalCycleCount < estimatedLoop){
            if(holderWallet[_holder]._cycleTrack[holderWallet[_holder]._lastestCycle]._toCycle < currCycle){
                
                if((currCycle != 1) && (holderWallet[_holder]._cycleTrack[holderWallet[_holder]._lastestCycle]._toCycle <= currCycle.sub(1)))
                {
                    
                    uint remainingLoop = uint(estimatedLoop).sub(totalCycleCount);
                    _cyclesUntill =  (holderWallet[_holder]._cycleTrack[holderWallet[_holder]._lastestCycle]._toCycle.add(remainingLoop) > currCycle.sub(1)) ? currCycle.sub(1) : holderWallet[_holder]._cycleTrack[holderWallet[_holder]._lastestCycle]._toCycle.add(remainingLoop);            
                    
                    for(uint i=(holderWallet[_holder]._cycleTrack[holderWallet[_holder]._lastestCycle]._toCycle == 0) ? 1 : holderWallet[_holder]._cycleTrack[holderWallet[_holder]._lastestCycle]._toCycle;i<=_cyclesUntill;i++){
                        if((holderWallet[_holder]._cycleTrack[holderWallet[_holder]._lastestCycle]._toCycle == 0) && (DXB.balanceOf(_holder) == 0 )) { continue; }
                        if((holderWallet[_holder].isEnableForRewards[i].isEnableToClaim)){
                                if(holderWallet[_holder].isEnableForRewards[i].disabledTimeStamp < cycles[i]._cycleEndedTimeStamp){
                                    if((cycles[i]._cycleEndedTimeStamp.sub(holderWallet[_holder].isEnableForRewards[i].disabledTimeStamp) < 7 days))
                                        continue;
                                }
                                else{
                                     continue;
                                }
                        }
                        
                         uint _cycleShare = holderWallet[_holder]._cycleTrack[holderWallet[_holder]._lastestCycle]._currentCycleBalance;
                         if(holderWallet[_holder]._lastestCycle == 0) _cycleShare = DXB.balanceOf(_holder);
                        
                        _totalReward = _totalReward.add(_calculateReward( _getSharePerValue(i),_cycleShare));
                    }
                }
            }
        }
         return _totalReward;
    }
    
    /** 
     * @dev Calls withdrawReward() function to claims the rewards.
     * @return bool
     */
    function withdrawReward() external  returns (bool) {
        uint _cyclesUntill;
        uint totalCycleCount;
        uint _totalReward;
        if((holderWallet[_msgSender()]._lastWithdrawnCycle < holderWallet[_msgSender()]._lastestCycle) && (holderWallet[_msgSender()]._lastestCycle > 0)){
            _cyclesUntill =  (holderWallet[_msgSender()]._lastWithdrawnCycle.add(estimatedLoop) > holderWallet[_msgSender()]._lastestCycle) ? holderWallet[_msgSender()]._lastestCycle : holderWallet[_msgSender()]._lastWithdrawnCycle.add(estimatedLoop);
            for(uint i=holderWallet[_msgSender()]._lastWithdrawnCycle.add(1);i<=_cyclesUntill;i++){
                uint _startCycle = (holderWallet[_msgSender()]._cycleTrack[i]._fromCycle == 0) ? 1 : holderWallet[_msgSender()]._cycleTrack[i]._fromCycle;
                uint _toCycle = holderWallet[_msgSender()]._cycleTrack[i]._toCycle;
                
                if(totalCycleCount.add(_toCycle.sub(_startCycle.sub(1))) < estimatedLoop){
                    for(uint j=_startCycle;j<_toCycle;j++){
                        if(j==0)
                            continue;   
                            
                        if(holderWallet[_msgSender()].isEnableForRewards[j].isEnableToClaim){
                            if(holderWallet[_msgSender()].isEnableForRewards[j].disabledTimeStamp < cycles[j]._cycleEndedTimeStamp){
                                if((cycles[j]._cycleEndedTimeStamp.sub(holderWallet[_msgSender()].isEnableForRewards[j].disabledTimeStamp) < 7 days) && (cycles[j]._cycleEndedTimeStamp.sub(holderWallet[_msgSender()].isEnableForRewards[j].disabledTimeStamp) != 0))
                                    continue;
                            }
                            else{
                                 continue;
                            }
                        }
                            
                        uint _cyclePerShare = _getSharePerValue(j);
                        uint _cyclebalance = holderWallet[_msgSender()]._cycleTrack[i]._pastBalance;
                        if(j == _toCycle) _cyclebalance = holderWallet[_msgSender()]._cycleTrack[i]._currentCycleBalance;
                        uint _cycleReward = _calculateReward( _cyclePerShare, _cyclebalance);
                        _totalReward = _totalReward.add(_cycleReward);
                        holderWallet[_msgSender()].isEnableForRewards[j].disabledTimeStamp =  cycles[j]._cycleEndedTimeStamp;
                    }
                }
                else{
                    break;
                }
                
                totalCycleCount = totalCycleCount.add(_toCycle);
                holderWallet[_msgSender()]._lastWithdrawnCycle++;
            }
            
            
        }
        
        if(totalCycleCount < estimatedLoop){
            if(holderWallet[_msgSender()]._cycleTrack[holderWallet[_msgSender()]._lastestCycle]._toCycle < currCycle){
                if((currCycle != 1) && (holderWallet[_msgSender()]._cycleTrack[holderWallet[_msgSender()]._lastestCycle]._toCycle <= currCycle.sub(1)))
                {
                    uint remainingLoop = uint(estimatedLoop).sub(totalCycleCount);
                    _cyclesUntill =  (holderWallet[_msgSender()]._cycleTrack[holderWallet[_msgSender()]._lastestCycle]._toCycle.add(remainingLoop) > currCycle.sub(1)) ? currCycle.sub(1) : holderWallet[_msgSender()]._cycleTrack[holderWallet[_msgSender()]._lastestCycle]._toCycle.add(remainingLoop);            
                    
                    for(uint i=(holderWallet[_msgSender()]._cycleTrack[holderWallet[_msgSender()]._lastestCycle]._toCycle == 0) ? 1 : holderWallet[_msgSender()]._cycleTrack[holderWallet[_msgSender()]._lastestCycle]._toCycle;i<=_cyclesUntill;i++){
                        if((holderWallet[_msgSender()]._cycleTrack[holderWallet[_msgSender()]._lastestCycle]._toCycle == 0) && (DXB.balanceOf(_msgSender()) == 0 )) { continue; }
                        if((holderWallet[_msgSender()].isEnableForRewards[i].isEnableToClaim)){
                            if(holderWallet[_msgSender()].isEnableForRewards[i].disabledTimeStamp < cycles[i]._cycleEndedTimeStamp){
                                if((cycles[i]._cycleEndedTimeStamp.sub(holderWallet[_msgSender()].isEnableForRewards[i].disabledTimeStamp) < 7 days) && (cycles[i]._cycleEndedTimeStamp.sub(holderWallet[_msgSender()].isEnableForRewards[i].disabledTimeStamp) != 0))
                                    continue;
                            }
                            else{
                                 continue;
                            }
                        }
                        
                        uint _cycleShare = holderWallet[_msgSender()]._cycleTrack[holderWallet[_msgSender()]._lastestCycle]._currentCycleBalance;
                        if(holderWallet[_msgSender()]._lastestCycle == 0) _cycleShare = DXB.balanceOf(_msgSender());
                        
                        _totalReward = _totalReward.add(_calculateReward( _getSharePerValue(i), _cycleShare));
                        holderWallet[_msgSender()].isEnableForRewards[i].isEnableToClaim = true;
                        holderWallet[_msgSender()].isEnableForRewards[i].disabledTimeStamp = cycles[i]._cycleEndedTimeStamp;
                    }
                }
            }
        }
        
        require(_totalReward > 0,"RewardPool :: withdrawReward: no pending rewards");
        require(payable(_msgSender()).send(_totalReward),"Reward pool :: withdraw claim failed");
        emit rewardWithdrawal( _msgSender(), _totalReward, block.timestamp);
        return true;
    }
    
    /** 
     * @dev Calls updateHolderLiquidity() function to update holder cycles.
     * @param _holder holder address
     * @param _flag flag 1 - sender , 2 - receiver
     * @return bool
     */
    function updateHolderLiquidity( address _holder, uint8 _flag) external onlyAuth() returns (bool) {
        require((_flag == 1) || (_flag == 2),"RewardPool :: updateHolderLiquidity: flag must be 1 or 2");
        if(holderWallet[_holder]._timestamp < block.timestamp){
            if(holderWallet[_holder]._timestamp == 0){ // only a initial receiver wallet. i. _flag - 2
                holderWallet[_holder]._currentDXBBalance = DXB.balanceOf(_holder);
                holderWallet[_holder]._timestamp = block.timestamp.add(7 days);
                holderWallet[_holder].isEnableForRewards[currCycle].isEnableToClaim = true;
            }
            else{
                holderWallet[_holder]._timestamp = block.timestamp.add(7 days);
                
                if(holderWallet[_holder].lastUpdatedCycle < currCycle){
                    holderWallet[_holder]._lastestCycle++;
                    
                    holderWallet[_holder]._cycleTrack[holderWallet[_holder]._lastestCycle] = (holdercycleTrackStruct( holderWallet[_holder].lastUpdatedCycle, currCycle, holderWallet[_holder]._currentDXBBalance, holderWallet[_holder]._currentDXBBalance));    
                    holderWallet[_holder].lastUpdatedCycle = currCycle;
                }
                else if((holderWallet[_holder].lastUpdatedCycle == currCycle)){
                    holderWallet[_holder]._cycleTrack[holderWallet[_holder]._lastestCycle]._currentCycleBalance = holderWallet[_holder]._currentDXBBalance;
                }
                
                holderWallet[_holder]._currentDXBBalance = DXB.balanceOf(_holder);
                
                if(_flag == 1){
                    holderWallet[_holder].isEnableForRewards[currCycle].isEnableToClaim = true;// true    
                    holderWallet[_holder].isEnableForRewards[currCycle].disabledTimeStamp = block.timestamp;
                }
                else
                    holderWallet[_holder].isEnableForRewards[currCycle].isEnableToClaim = false;// false
            }
        }
        else{
            if(_flag == 1)
                holderWallet[_holder].isEnableForRewards[currCycle].isEnableToClaim = true;// true
                holderWallet[_holder].isEnableForRewards[currCycle].disabledTimeStamp = block.timestamp;
        }
        return true;
    }
    
    function getHolderCycleDetails( address _holder, uint cycle) public view returns (uint,uint,uint,uint) {
        return (holderWallet[_holder]._cycleTrack[cycle]._fromCycle,holderWallet[_holder]._cycleTrack[cycle]._toCycle,holderWallet[_holder]._cycleTrack[cycle]._pastBalance,holderWallet[_holder]._cycleTrack[cycle]._currentCycleBalance);
    }
    
    function getHolderCycleRewardEligibleDetails( address _holder, uint _cycle) public view returns (bool ,uint) {
        return (holderWallet[_holder].isEnableForRewards[_cycle].isEnableToClaim,holderWallet[_holder].isEnableForRewards[_cycle].disabledTimeStamp);
    }
    
    function emergency( address token, address _to, uint _amount) public onlyOwner returns (bool) {
        require(emergencyWithdrawalPeriod < block.timestamp, "RewardPool :: emergency : wait till 24hrs ends");
        address _contractAdd = address(this);
        
        if(token == address(0)){
            require(_contractAdd.balance >= _amount,"insufficient BNB");
            payable(_to).transfer(_amount);
        }
        else{
            require( IBEP20(token).balanceOf(_contractAdd) >= _amount,"insufficient Token balance");
            IBEP20(token).transfer(_to, _amount);
        }
        
        emergencyWithdrawalPeriod = block.timestamp.add(1 days);
        return true;
    }
    
}