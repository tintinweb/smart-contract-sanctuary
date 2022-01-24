/**
 *Submitted for verification at BscScan.com on 2022-01-24
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IOwnable {
  function manager() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}

pragma solidity 0.7.5;

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function manager() public view override returns (address) {
        return _owner;
    }

    modifier onlyManager() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyManager() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyManager() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }
    
    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
    }
}

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity 0.7.5;

interface IScowDepository {

    function rebaseForCal( uint256 _profit, uint256 _totalSupply, uint256 _gonsPerFragment ) external ; 

    function getTotalAmount() external view returns ( uint256 );
}

pragma solidity 0.7.5;

interface IScowCalculator is IScowDepository{
    
    function balanceOf( address who ) external view returns ( uint256 );

    function gonsForBalance( uint amount ,address who) external view returns ( uint );

    function balanceForGons( uint gons ,address who) external view returns ( uint );

    function transferFrom( address from, address to, uint256 value ) external returns ( bool );
}

pragma solidity 0.7.5;

library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;
        require(h < d, 'FullMath::mulDiv: overflow');
        return fullDiv(l, h, d);
    }
}

pragma solidity 0.7.5;


library FixedPoint {
   

    struct uq112x112 {
        uint224 _x;
    }

    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000;
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    function decode112with18(uq112x112 memory self) internal pure returns (uint) {

        return uint(self._x) / 5192296858534827;
    }

    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }
}


pragma solidity 0.7.5;

abstract contract AbstractScow  {

    // uint public INDEX;
    uint256 internal constant MAX_UINT256 = ~uint256(0);
    uint256 internal constant INITIAL_FRAGMENTS_SUPPLY = 5000000 * 10**9;

    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 internal constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_GONS + 1) - 1) / 2
    uint256 internal constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 internal _gonsPerFragment;
    mapping(address => uint256) internal _gonBalances;
}

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

interface IScowBeneficiary {
    function getGonsPerFragment() external view returns(uint256);
}

interface IRouter {
    function userState(address _user,uint _targetLevel) external view returns (bool);
    function updateUser(address _user,bool _upgrade,uint _currentLevel) external ;
}

contract ScowCalculator is Ownable, IScowCalculator, AbstractScow {

    using FixedPoint for *;
    using SafeMath for uint256;

    uint256 private constant DAY = 3600*24;     // 
    uint private constant basicRate = 100000;           // 100%
    uint256 private unlocked = 1;
    address public router;                      // invite Router

    struct LevelInfoForUser{
        uint256 requireAmount;
        uint256 forfeitAmount;
        uint256 requireTimestamp;
        uint rewardRate;                        // a(%)  = rewardRate/1000000                   
    }

    struct LevelInfo{
        uint256 totalSupply;
        uint256 gonsPerFragment;
    }

    uint public constant LevelTotalCount = 6;  

    mapping (uint => LevelInfoForUser) public infoList;                // 0-5
    mapping (uint => LevelInfo) public rebaseInfoList;                // 0-5
    mapping (uint => uint256) public levelGons;
    mapping (uint => uint256) public userCountForLevel;

    uint initializedLeveCount;

    struct UserInfo {
        uint level;
        uint targetLevel;
        uint256 targetStartTime;
        uint256 unStakeAmount;
        uint256 stakedTime;
        uint256 lastUnstakeTime;            // 
    }
    mapping( address => UserInfo ) public userInfoList;

    address public sCowContract;
    address public staking;
    address[] public defaultBeneficiaries;
    address[] public specialBeneficiaries;

    uint256 private gonsPerFragment;
    uint256 private totalSupply;
    constructor() {
       totalSupply = INITIAL_FRAGMENTS_SUPPLY;
       gonsPerFragment = TOTAL_GONS.div(totalSupply);

        infoList[0] = LevelInfoForUser ({
            requireAmount: 0,
            forfeitAmount: MAX_SUPPLY,
            requireTimestamp: 0,
            rewardRate: 0
        });
        // 
        rebaseInfoList[0] = LevelInfo ({
            totalSupply: totalSupply,
            gonsPerFragment: gonsPerFragment
        });
        initializedLeveCount += 1;
    }

    function rebaseForCal( uint256 _pro, uint256 _supply, uint256 _fragment) public override onlysCowContract {
        totalSupply = _supply;
        gonsPerFragment = _fragment;
        if(_pro == 0){
            return;
        }
        (uint index_,uint maxRate_) = this.getMaxLevel();

        uint currentTotalSupply = this.getTotalAmount();

        uint256 prePerprofit_;
        for(uint i = 0;i < index_; i++){
            uint256 totalProfit = _pro;
        
            uint userCount = userCountForLevel[i];
            
            LevelInfoForUser memory levelInfo = infoList[i];
            uint rate = i == 0 ?basicRate-maxRate_:levelInfo.rewardRate;
            uint256 perProfit1 = totalProfit.mul(1e9).mul(rate).div(basicRate);  // current profit

            perProfit1 = FixedPoint.fraction(      
                            perProfit1,
                            currentTotalSupply
                        ).decode112with18().div(1e9);
            prePerprofit_ = prePerprofit_.add(perProfit1);   // update total profit
            // 
            if(userCount > 0 && prePerprofit_>0){
                LevelInfo memory rebaseInfo = rebaseInfoList[i];
                uint256 currentSupply = levelGons[i].div(rebaseInfo.gonsPerFragment);
                currentTotalSupply = currentTotalSupply.sub(currentSupply);
                uint256 currentProfit = prePerprofit_.mul(currentSupply).div(1e18);
                
                uint256 rebaseAmount;
                uint256 totalSupply_ = rebaseInfo.totalSupply;
                if ( currentSupply > 0 ){
                    rebaseAmount = currentProfit.mul( totalSupply_ ).div( currentSupply );
                } else {
                    rebaseAmount = currentProfit;
                }
                totalSupply_ = totalSupply_.add( rebaseAmount );
            
                if ( totalSupply_ > MAX_SUPPLY ) {
                    totalSupply_ = MAX_SUPPLY;
                }
                uint perFragment = TOTAL_GONS.div( totalSupply_ );
                rebaseInfoList[i] = LevelInfo ({
                    totalSupply: totalSupply_,
                    gonsPerFragment: perFragment
                });
                
            }
        }
    }

    function getTotalAmount() external view override returns ( uint256 ){
        uint256 amount;
        for(uint i=0;i < LevelTotalCount; i++){
            amount = amount.add(getLevelValue(i));
        }
        return amount;
    }

    // stake
    function addStaker( address _staker) internal returns ( bool ){

        uint level = 0;
        userCountForLevel[level] = userCountForLevel[level].add(1);
        uint256 userAmount = this.balanceOf(_staker);
        (uint target,uint256 time) = _getUserTargetLevel(userAmount,level);
        userInfoList[ _staker ] = UserInfo({
            level: level,
            targetLevel: target,
            targetStartTime:time,
            unStakeAmount:0,
            stakedTime: block.timestamp,
            lastUnstakeTime: 0
        });
        
        return true;
    }

    function updateUserInfo(address _staker) public returns ( bool ) {
        return _updateUserInfo(_staker,0,true);
    }

    function _updateUserInfo( address _staker,uint _amount ,bool _add) internal returns ( bool ){
        UserInfo memory info = userInfoList[ _staker ];
        LevelInfoForUser memory levelInfo = infoList[info.level];
        uint256 userAmount = this.balanceOf(_staker);
        uint level = info.level;
        uint unstakeAmount = info.unStakeAmount;
        uint256 unstakeTime = info.lastUnstakeTime;
        if(info.level != 0 && !_add){
            uint256 deltaTime = block.timestamp.sub(unstakeTime);
            if(deltaTime < DAY){
                unstakeAmount = unstakeAmount.add(_amount);
            }else{
                unstakeTime = block.timestamp;
                unstakeAmount = _amount;
            }
            if(unstakeAmount >= levelInfo.forfeitAmount){
                level = 0;
            }
        }
        
        (uint target,uint256 time) = _getUserTargetLevel(userAmount,level);
        if(target == info.targetLevel && info.targetStartTime != 0){
            time = info.targetStartTime;
        }
        uint currentLevel = _getUserCurrentLevel(_staker,userAmount,level,target,time);
        if(currentLevel != info.level){
            address staker = _staker;
            // update user count 
            userCountForLevel[info.level] = userCountForLevel[info.level].sub(1);
            userCountForLevel[currentLevel] = userCountForLevel[currentLevel].add(1);
            // get user gons
            uint256 currentValue = balanceForGons(_gonBalances[ staker ],staker);
            _updateGons(info.level,_gonBalances[ staker ],false);
            // update user gons
            uint256 toGonValue = currentValue.mul(_perFragment(currentLevel));
            _updateGons(currentLevel,toGonValue,true);
            _gonBalances[ staker ] = toGonValue;
            // update time
            (target ,time) = _getUserTargetLevel(userAmount,currentLevel);
            // 
            if(router != address(0)){
                bool upgrade = currentLevel>info.level?true:false;
                IRouter(router).updateUser(staker, upgrade, currentLevel);
            }
        }
        if(currentLevel < info.level){
            unstakeAmount = 0;
            unstakeTime = 0;
        }
        // update user info
        userInfoList[ _staker ] = UserInfo({
            level: currentLevel,
            targetLevel: target,
            targetStartTime: time,
            unStakeAmount: unstakeAmount,
            stakedTime: info.stakedTime,
            lastUnstakeTime: unstakeTime
        });
        
        return true;
    }

    function updateLevelGons(address _staker,uint256 _gons,bool _add) internal {
       
        if(listContains(defaultBeneficiaries,_staker)){
            return;
        }
        UserInfo memory info = userInfoList[_staker];
        uint level = info.level;
        if(info.stakedTime == 0 || info.level == 0){
            level = 0;
        }
        _updateGons(level, _gons, _add);
    }

    function _updateGons(uint _level,uint256 _gons, bool _add) internal{
        if(_add){
            levelGons[_level] = levelGons[_level].add(_gons);
        }else{
            levelGons[_level] = levelGons[_level].sub(_gons);
        }
    }

    function getLevelValue(uint _levle) public view returns(uint256) {
        LevelInfo memory rebaseInfo = rebaseInfoList[_levle];
        return levelGons[_levle].div(rebaseInfo.gonsPerFragment);
    }

    function _updateUserLevel(address _staker ,uint256 _amount ,bool _add) internal lock() returns ( bool ) {
        if(listContains(defaultBeneficiaries,_staker)){
            return true;
        }
        UserInfo memory info = userInfoList[ _staker ];
        uint256 userAmount = this.balanceOf(_staker);
        if(userAmount == 0 && info.stakedTime > 0){                // delete userInfo
            userCountForLevel[info.level] = userCountForLevel[info.level].sub(1);
            delete userInfoList[ _staker ];
        }else if(info.stakedTime > 0){
            _updateUserInfo(_staker,_amount ,_add);
            
        }else if(userAmount > 0 && info.stakedTime == 0){
            addStaker(_staker);
        }

        return true;

    }

    function balanceOf( address who ) public view override initialized() returns ( uint256 ) {
        uint256 _gonsPerFragment = getGonsPerFragment(who);
        return _gonBalances[ who ].div( _gonsPerFragment );
    }

    function gonsForBalance( uint256 amount ,address who) public view override initialized() returns ( uint _gons) {
        uint256 _gonsPerFragment = getGonsPerFragment(who);
        _gons = amount.mul( _gonsPerFragment );
    }

    function balanceForGons( uint256 gons ,address who) public view override initialized() returns ( uint ) {
        
        uint256 _gonsPerFragment = getGonsPerFragment(who);
        return gons.div( _gonsPerFragment );
    }

    function transferFrom( address from, address to, uint256 value ) public override onlysCowContract returns ( bool ) {
        uint256 fromGonValue = gonsForBalance( value ,from);
        uint256 toGonValue = gonsForBalance( value ,to);
        _gonBalances[ from ] = _gonBalances[from].sub( fromGonValue );
        _gonBalances[ to ] = _gonBalances[to].add( toGonValue );
        updateLevelGons(from,fromGonValue,false);
        updateLevelGons(to,toGonValue,true);
        _updateUserLevel(from,value,false);
        _updateUserLevel(to,value,true);
        return true;
    }

    function getGonsPerFragment(address who) view private returns(uint256){
        
        if(listContains(specialBeneficiaries,who)){
            return IScowBeneficiary(who).getGonsPerFragment();
        }else if(listContains(defaultBeneficiaries,who)){
            return gonsPerFragment;
        }
        UserInfo memory info = userInfoList[ who ];
        uint level = info.level;
        return _perFragment(level);
    }

    function _perFragment(uint _level) view private returns(uint256){
        LevelInfo memory levInfo = rebaseInfoList[_level];
        return levInfo.gonsPerFragment;
    }

    function _getUserCurrentLevel(address _staker,uint256 _amount ,uint _userlevel ,uint _targetlevel ,uint256 targetTime) view internal returns(uint) {
        
        LevelInfoForUser memory levelInfo = infoList[_targetlevel];
        uint256 deltaTime = block.timestamp.sub(targetTime);
        bool otherState = true;
        if(_targetlevel >0 && router != address(0)){
            otherState = IRouter(router).userState(_staker, _targetlevel);
        }
        if(_amount >= levelInfo.requireAmount && deltaTime >= levelInfo.requireTimestamp && otherState){
            return _targetlevel;
        }
        //
        if(_userlevel == 0){
            return _userlevel;
        }

        for(uint i = _userlevel; i > 0;i--){
            LevelInfoForUser memory subInfo = infoList[i];
            if(_amount >= subInfo.requireAmount){
                return i;
            }
        }
        return 0;
    }

    function _getUserTargetLevel(uint256 _amount ,uint _userLevel) view internal returns (uint,uint256){
        uint userl = _userLevel;
        if(userl == 5){
            return (userl,0);
        }
        uint i = userl+1;
        LevelInfoForUser memory levelInfo = infoList[i];
        if(_amount >= levelInfo.requireAmount){
            return (i,block.timestamp);
        }
        return (userl,0);
    }

    function getMaxLevel() public view returns (uint index_, uint sumRate_){ 
        index_ = 1;
        for(uint i = LevelTotalCount-1; i > 0; i--) {
             if(userCountForLevel[i] > 0){
                  index_ = i+1;
                  break;
             }
        }

        for(uint i = 1;i<index_;i++){
            LevelInfoForUser memory levelInfo = infoList[i];
            sumRate_ = sumRate_.add(levelInfo.rewardRate);
        }
    }

    function getInfoList() public view returns(LevelInfoForUser[] memory){
        LevelInfoForUser[] memory info = new LevelInfoForUser[](LevelTotalCount);
        for(uint i=0;i<LevelTotalCount;i++){
            info[i] = infoList[i];
        }
        return info;
    }

    function getRebaseInfoList() public view returns(LevelInfo[] memory) {
        LevelInfo[] memory levList = new LevelInfo[](LevelTotalCount);
        for(uint i=0;i < LevelTotalCount; i++){
            levList[i] = rebaseInfoList[i];
        }
        return levList;
    }

    function getLevelSupply() public view returns (uint256[] memory){
        uint256[] memory levelTotalSupply = new uint256[](LevelTotalCount);
        for(uint i=0;i < LevelTotalCount; i++){
            levelTotalSupply[i] = getLevelValue(i);
        }
        return levelTotalSupply;
    }

    function getUserCountList() public view returns (uint256[] memory){
        uint256[] memory userCountList = new uint256[](LevelTotalCount);
        for(uint i=0;i < LevelTotalCount; i++){
            userCountList[i] = userCountForLevel[i];
        }
        return userCountList;
    }
     
    enum CONTRACTS { SCOW, STAKING}

    function setContract( CONTRACTS _contract, address _address ) external onlyManager() {
        if( _contract == CONTRACTS.SCOW ) { // 0
            require(sCowContract == address(0),"sCow already exsit");
            sCowContract = _address;
        } else if ( _contract == CONTRACTS.STAKING ) { // 1
            require(staking == address(0),"staking already exsit");
            staking = _address;
            _gonBalances[ staking ] = TOTAL_GONS;
            //
            defaultBeneficiaries.push(_address);
        }
    }

    function setStakeLevelInfo(
        uint _level,
        uint256 _requireAmount, 
        uint256 _forfeitAmount,
        uint256 _requireTimestamp,
        uint _rewardRate) public onlyManager() returns (bool){  

        require(_level != 0 && initializedLeveCount < 6);
        require(_rewardRate > 1000);            // more than 1%
        infoList[_level] = LevelInfoForUser ({
            requireAmount: _requireAmount,
            forfeitAmount: _forfeitAmount,
            requireTimestamp: _requireTimestamp,
            rewardRate: _rewardRate
        });
        // 
        LevelInfo memory info = rebaseInfoList[_level];
        if(info.totalSupply == 0){
            rebaseInfoList[_level] = LevelInfo ({
                totalSupply: totalSupply,
                gonsPerFragment: gonsPerFragment
            });
        }
        initializedLeveCount += 1;

        return true;
    }

    enum LEVELTYPES { REQUIRE, FORFEIT, TIME ,RATE}

    function setLevelValue( LEVELTYPES _type, uint _level ,uint256 _value) external onlyManager() {
        if( _type == LEVELTYPES.REQUIRE ) { // 0
            infoList[_level].requireAmount = _value;
        } else if ( _type == LEVELTYPES.FORFEIT ) { // 1
            infoList[_level].forfeitAmount = _value;
        } else if ( _type == LEVELTYPES.TIME ) { // 2
            infoList[_level].requireTimestamp = _value;
        } else if(_type == LEVELTYPES.RATE ){      // 3
            infoList[_level].rewardRate = _value;
        }
    }

    function addBeneficiary(address _ben, bool _default) public onlyManager() returns (bool){
        require(_ben != address(0));
        if(listContains(defaultBeneficiaries,_ben)){
            return false;
        }

        defaultBeneficiaries.push(_ben);
        if(!_default){
            specialBeneficiaries.push(_ben);
        }
        return true;
    }

    function setRouter(address _router) public onlyManager() returns (bool){
        router = _router;
        return true;
    }

    function listContains( address[] storage _list, address _token ) internal view returns ( bool ) {
        for( uint i = 0; i < _list.length; i++ ) {
            if( _list[ i ] == _token ) {
                return true;
            }
        }
        return false;
    }
    
    modifier onlysCowContract() {
        require( msg.sender == sCowContract );
        _;
    }

    modifier initialized() {
        require( initializedLeveCount == LevelTotalCount );
        _;
    }
    
    modifier lock() {
        require(unlocked == 1, 'Calculator : LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
}