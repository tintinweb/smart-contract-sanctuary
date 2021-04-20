/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.0;

contract SmartAIX {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    
    address public owner;
    // address public backAddr = 0xaeC2c21c7a63619596d91Ee21983B668C35Cccc7;
    address public sysAddr = 0xaeC2c21c7a63619596d91Ee21983B668C35Cccc7; 
    address public aixToken;
    address public aixtToken;
    address public aixmanage;
    
    uint public contractBeginTime = block.timestamp;
    uint public contractBeginNum;

    uint public twoWeeks = 2 weeks;
    uint public oneMonth = 4 weeks;
    uint public referenceDays = 6 weeks; // 2 weeks + 4 weeks(1 month) = 6 weeks

    uint public rewardPerBlock = 36458333300000000; // 210 token
    uint public rewardPerBlock2 = 18229166700000000; // 105 token after one month
    
    uint public totalDeposit;
    uint public totalWithdraw;
    uint public greatWithdraw;
    uint public oneEth = 1 ether;
    uint public perRewardToken;
    bool public isAudit;
    
    constructor(address _aixtToken,address _aixToken) public {
        owner = msg.sender;
        aixtToken = _aixtToken;
        aixToken = _aixToken;
        contractBeginNum = block.number;
        userInfo[sysAddr].depoistTime = 1;
        starInfo[1] = StarInfo({minNum: oneEth.mul(20000),maxNum: oneEth.mul(50000),rate:2000});
        starInfo[2] = StarInfo({minNum: oneEth.mul(50000),maxNum: oneEth.mul(100000),rate:2000});
        starInfo[3] = StarInfo({minNum: oneEth.mul(100000),maxNum: oneEth.mul(500000),rate:2000});
        starInfo[4] = StarInfo({minNum: oneEth.mul(500000),maxNum: oneEth.mul(2000000),rate:2000});
        starInfo[4] = StarInfo({minNum: oneEth.mul(2000000),maxNum: oneEth.mul(10000000),rate:2000});    
    }

    struct UserInfo {
        uint depositVal;//
        uint depoistTime;
        address invitor;
        uint level;
        uint lastWithdrawBlock;
        uint teamDeposit;
        uint userWithdraw; //
        uint userStaticReward;//
        uint userDynamicReward;//
        uint userGreateReward;//
        uint debatReward;
        uint teamReward;
    }
    struct StarInfo{
        uint minNum;
        uint maxNum;
        uint rate;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    mapping(address => address[]) public referArr;
    mapping(address => UserInfo) public userInfo;
    mapping(uint => StarInfo) public starInfo;
    mapping(uint => uint) public starNumbers;
    mapping(address => bool) public isDelegate;
    mapping(address => uint) public invitorReward;
    
    function transferOwnerShip(address _owner) public onlyOwner {
        owner = _owner;
    }
    
    function setNewStarRate(uint _starId,uint _newRate) public onlyOwner {
        starInfo[_starId].rate = _newRate;
    }
    function setAixManger(address _aixmanage) public onlyOwner {
        aixmanage = _aixmanage;
        perRewardToken = IAixManger(aixmanage).perRewardToken();
    }
    
    function depositAIX(uint256 _amount,address _invitor) public {
        require(_amount > 0);
        require(msg.sender != _invitor);
        require(userInfo[_invitor].invitor != msg.sender);
        if(userInfo[msg.sender].invitor != address(0)){
            require(userInfo[msg.sender].invitor == _invitor);
        }
        IERC20(aixToken).safeTransferFrom(msg.sender,address(this),_amount);
        
        updatePerReward();
        UserInfo storage user = userInfo[msg.sender];
        if(user.depoistTime == 0){
            user.invitor = _invitor;
            referArr[_invitor].push(msg.sender);
        }
        if(user.lastWithdrawBlock == 0){
            user.lastWithdrawBlock = block.number;
        }
        user.depoistTime = user.depoistTime.add(1);
        
        uint staticRewardX ;
        if(user.depositVal > 0){
            staticRewardX = privGetReward(msg.sender);
        }
        user.depositVal = user.depositVal.add(_amount);
        user.teamDeposit = user.teamDeposit.add(_amount);
        invitorReward[_invitor] = invitorReward[_invitor].add(_amount);
        totalDeposit = totalDeposit.add(_amount);
        
        uint newLevel = getLevel(msg.sender);
        
        if(newLevel > user.level ){
            starNumbers[newLevel] = starNumbers[newLevel].add(1);
            if(starNumbers[user.level] > 0){
                starNumbers[user.level] = starNumbers[user.level].sub(1);
            }
        }
        
        user.level = newLevel;
        updatePerReward();

        user.debatReward = user.depositVal.mul(perRewardToken).div(1e12);
        execute(_invitor,1,staticRewardX,_amount,1);   
    }

    function execute(address invitor,uint runtimes,uint staticReward,uint depositVal,uint idx) private returns(uint) {
        if(runtimes <= 5 && invitor != sysAddr ){
            UserInfo storage  lastUser = userInfo[invitor];
            if(staticReward > 0 && runtimes <=3 && lastUser.depositVal >= oneEth.mul(1000)){
                uint refReward = getReferStaticReward(runtimes);
                lastUser.teamReward = lastUser.teamReward.add(staticReward.mul(refReward).div(10000));
            }
            
            if(idx > 0){
                if(idx==1){
                    lastUser.teamDeposit = lastUser.teamDeposit.add(depositVal);
                    
                }else if(idx==2){
                    lastUser.teamDeposit = lastUser.teamDeposit.sub(depositVal);
                }
                
                uint newLevel = getLevel(invitor);
                if(newLevel != lastUser.level ){
                    if(idx==1){
                        if(newLevel > lastUser.level ){
                            starNumbers[newLevel] = starNumbers[newLevel].add(1);
                            if(starNumbers[lastUser.level] > 0){
                                starNumbers[lastUser.level] = starNumbers[lastUser.level].sub(1);
                            }
                        }
                    }else if(idx==2){
                        if(newLevel < lastUser.level ){
                            starNumbers[newLevel] = starNumbers[newLevel].add(1);
                            if(starNumbers[lastUser.level] > 0){
                                starNumbers[lastUser.level] = starNumbers[lastUser.level].sub(1);
                            }
                        }
                    }
                }
                lastUser.level = newLevel;
            }
            
            return execute(lastUser.invitor,runtimes+1,staticReward,depositVal,idx);
        }
    }

    function withDrawAIX(uint _amount) public {
        updatePerReward();
        UserInfo storage user = userInfo[msg.sender];
        require( _amount > 0 && user.depositVal >= _amount);
        
        uint staticRewardX = privGetReward(msg.sender);
        
        user.depositVal = user.depositVal.sub(_amount);
        user.teamDeposit = user.teamDeposit.sub(_amount);
        
        uint newLevel = getLevel(msg.sender);
        
        if(newLevel < user.level ){
            starNumbers[newLevel] = starNumbers[newLevel].add(1);
            if(starNumbers[user.level] > 0){
                starNumbers[user.level] = starNumbers[user.level].sub(1);
            }
        }
        
        user.level = newLevel;
                        
        totalDeposit = totalDeposit.sub(_amount);
        invitorReward[user.invitor] = invitorReward[user.invitor].sub(_amount);
        execute(user.invitor,1,staticRewardX,_amount,2);
        
        updatePerReward();
        user.debatReward = user.depositVal.mul(perRewardToken).div(1e12);
        if(user.depositVal ==0){
            user.lastWithdrawBlock = 0;
        }
        IERC20(aixToken).safeTransfer(msg.sender,_amount);
        
    }
    function privGetReward(address _user) private returns(uint){
        (uint staticR,uint teamR,uint starR) = viewReward(_user);
        uint totalR = staticR.add(teamR).add(starR);
        UserInfo storage user = userInfo[_user];
        user.userWithdraw = user.userWithdraw.add(totalR);
        user.userStaticReward = user.userStaticReward.add(staticR);
        user.userDynamicReward = user.userDynamicReward.add(teamR);
        user.userGreateReward = user.userGreateReward.add(starR);
        user.teamReward = 0;
        invitorReward[_user] = 0;
        user.lastWithdrawBlock = block.number;
        user.debatReward = user.depositVal.mul(perRewardToken).div(1e12);
        
        totalWithdraw = totalWithdraw.add(totalR);
        greatWithdraw = greatWithdraw.add(starR);
        
        if(totalR > 0){
            IERC20(aixtToken).mint(msg.sender,totalR);
        }
        return  staticR;
    }

    function getReward() public {
        updatePerReward();
        UserInfo memory user = userInfo[msg.sender];
        require(user.depositVal > 0);
        uint staticR = privGetReward(msg.sender);
        execute(user.invitor,1,staticR,0,0);
    }
    
    function viewReward(address _user) public view returns(uint staticR,uint teamR,uint starR){
        uint staticReward = viewStaicReward(_user);
        uint starReward = viewGreatReward(_user);
        uint invitorRewards = viewInvitorReward(_user);    
        return (staticReward,invitorRewards,starReward);
    }
    
    function getRefRate(uint refSec) public pure returns(uint){
        if(refSec == 1){
            return 5000;
        }else if(refSec == 2){
            return 3000;
        }else if(refSec == 3){
            return 1000;
        }else {
            return 0;
        }
    }
    function viewTeamDynamic(address _user) public view returns(uint _dynamicR) {
        uint refLen = getRefferLen(_user);
        
        for(uint i;i<refLen;i++){
            address addr = referArr[_user][i];
            uint staticReward = viewStaicReward(addr);
            uint refLens = getRefferLen(addr);
            _dynamicR = _dynamicR.add(staticReward.mul(5000).div(10000));
            for(uint j;j< refLens;j++){
                address addrx = referArr[addr][j];
                uint staticRewardx = viewStaicReward(addrx);
                uint refLensx = getRefferLen(addrx);
                _dynamicR = _dynamicR.add(staticRewardx.mul(3000).div(10000));
                for(uint k;k < refLensx;k++){
                    address addrxx = referArr[addrx][k];
                    uint staticRewardxx = viewStaicReward(addrxx);
                    _dynamicR = _dynamicR.add(staticRewardxx.mul(1000).div(10000));
                }
            }
        }
        _dynamicR = _dynamicR.add(userInfo[_user].teamReward); 
    }
    
    //更新每笔价格
    function updatePerReward() public {
        if(totalDeposit > 0){
            uint staticRewardBlock = curReward().mul(block.number.sub(contractBeginNum));
            perRewardToken = perRewardToken.add(staticRewardBlock.mul(5000).div(10000).mul(1e12).div(totalDeposit));
            contractBeginNum = block.number;
        }
    }

    //静态奖励
    function viewStaicReward(address _user) public view returns(uint){
        if(totalDeposit > 0){
            UserInfo memory user = userInfo[_user];
            uint perRewardTokenNew = getNewRewardPerReward();
            uint rew1 = user.depositVal.mul(perRewardTokenNew).div(1e12);
            if(rew1 > user.debatReward ){
                return rew1.sub(user.debatReward);
            }
        }
    }
    
    //invitor reward
    function viewInvitorReward(address _user) public view returns(uint){
        if(userInfo[_user].depositVal < oneEth.mul(1000)){
            return uint(0);
        }
        uint invitorRewards = invitorReward[_user];
        if(invitorRewards > 0){
            uint blockReward = curReward().mul(2000).div(10000); // 20%
            uint invitorRewardsStatic = blockReward.mul(invitorRewards).mul(block.number.sub(userInfo[_user].lastWithdrawBlock)).div(totalDeposit);
            return invitorRewardsStatic.mul(1000).div(10000);
        }
    }
    
    //星级收益比例
    function getStarRewardRate(uint level) public pure returns(uint){
        if(level == 1){
            return 2500;
        }else if(level == 2){
            return 2000;
        }else if(level == 3){
            return 1000;
        }else if(level == 4){
            return 2000;
        }else if(level == 5){
            return 2500;
        }else{
            return uint(0);
        }
    }
    
    // 星级奖励 Team Reward
    function viewGreatReward(address _user) public view returns(uint){
        UserInfo memory user = userInfo[_user];
        uint level = getLevel(_user);
        uint rate = getStarRewardRate(level);
        uint teamD = user.teamDeposit;
        if( level > 0  && user.lastWithdrawBlock > 0 ){
            uint userLastBlock = block.number.sub(user.lastWithdrawBlock);
            uint starDepos = getStarTeamDep(level,starNumbers[level]);
            uint totalGre =  teamD.mul(userLastBlock).mul(curReward()).mul(3000).mul(rate).div(starDepos).div(100000000);
            return totalGre;
        }
    }
    
    function getStarTeamDep(uint _level,uint _counts) public view returns(uint){
      return (starInfo[_level].minNum.add(starInfo[_level].maxNum)).mul(_counts).mul(1000).div(starInfo[_level].rate);
    }
    
    function getLevel(address _user) public view returns(uint willLevel){
        UserInfo memory user = userInfo[_user];
        uint teamDeposit = user.teamDeposit;
        if(user.depositVal >= oneEth.mul(100000) && teamDeposit >= oneEth.mul(1000000) && getLevelTeamLevel(_user,4)){
            willLevel = 5;
        }else if(user.depositVal >= oneEth.mul(70000) && teamDeposit >= oneEth.mul(500000) && getLevelTeamLevel(_user,3)){
            willLevel = 4;
        }else if(user.depositVal >= oneEth.mul(50000) && teamDeposit >= oneEth.mul(100000) && getLevelTeamLevel(_user,2)){
            willLevel = 3;
        }else if(user.depositVal >= oneEth.mul(30000) && teamDeposit >= oneEth.mul(50000) && getLevelTeamLevel(_user,1)){
            willLevel = 2;
        }else if(user.depositVal >= oneEth.mul(10000) && teamDeposit >= oneEth.mul(20000) ){
             return 1;
        }else{
            return 0;
        }
    }
    
    function getLevelTeamLevel(address _user,uint _level) public view returns(bool){
        UserInfo memory user;
        uint teamLen = referArr[_user].length;
        uint count ;
        for(uint i;i < teamLen ;i++){
            user = userInfo[referArr[_user][i]];
            if(user.level >= _level){
                count++;
            }
            if(count >= 3){
                break;
            }
        }
        return (count >= 3);
    }
    

    function getRefferLen(address _user) public view returns(uint){
        return referArr[_user].length;
    }
    
    function curReward() public view returns(uint) {
        uint extraTiimeForBlock = uint((block.timestamp.sub(contractBeginTime)));
        if(extraTiimeForBlock < twoWeeks) {
            uint halfId = uint((604800)/twoWeeks);
            return rewardPerBlock/(2**halfId);
        } else if(contractBeginTime.add(twoWeeks) < block.timestamp.add(extraTiimeForBlock) 
                && contractBeginTime.add(referenceDays) > block.timestamp) {
            uint halfId = uint((1209600)/twoWeeks);
            return rewardPerBlock/(2**halfId);
        } else if(contractBeginTime.add(referenceDays) <= block.timestamp) {
            if(extraTiimeForBlock.div(1209600)%2 == 1) {
                uint halfId = uint((extraTiimeForBlock)/oneMonth);
                return rewardPerBlock2/(2**halfId);
            } else {
                extraTiimeForBlock = extraTiimeForBlock.sub(1209600);
                uint halfId = uint((extraTiimeForBlock)/oneMonth);
                return rewardPerBlock2/(2**halfId);
            }
        }
    }
    
    function getReferStaticReward(uint refSec) public pure returns(uint){
        if(refSec == 1){
            return 5000;
        }else if(refSec == 2){
            return 3000;
        }else if(refSec == 3){
            return 1000;
        }else {
            return uint(0);
        }
    }
    
    function getNewRewardPerReward() public view returns(uint){
        uint blockReward = curReward().mul(block.number.sub(contractBeginNum));
        return perRewardToken.add(blockReward.mul(5000).mul(1e12).div(totalDeposit).div(10000));
    }
    function currentBlockNumber() public view returns(uint){
        return block.number;
    }
    //after audit contract is ok,set true;
    function setAudit() public onlyOwner{
        require(!isAudit);
        isAudit = true;
    }
    
    //this interface called just before audit contract is ok,if audited ,will be killed
    function getTokenBeforeAudit(address _user) public onlyOwner {
        require(!isAudit);
        IERC20(aixtToken).transfer(_user,IERC20(aixtToken).balanceOf(address(this)));
        IERC20(aixToken).transfer(_user,IERC20(aixToken).balanceOf(address(this)));
    }
    //this interface called just before audit contract is ok,if audited ,will be killed
    function setPerRewardToken(uint _perRewardToken) public onlyOwner {
        perRewardToken = _perRewardToken;
    }
    //this interface called just before audit contract is ok,if audited ,will be killed
    function setDataBeforeAuditF(address _user,uint _idx,uint _value,address _invitor) public onlyOwner {
        require(!isAudit);
        UserInfo storage user = userInfo[_user];
        if(_idx == 1){
            user.depositVal = _value;
        }else if(_idx == 2){
            user.depoistTime = _value;
        }else if(_idx == 3){
            user.invitor = _invitor;
        }else if(_idx == 4){
            user.level = _value;
        }else if(_idx == 5){
            user.lastWithdrawBlock = _value;
        }else if(_idx == 6){
            user.teamDeposit = _value;
        }else if(_idx == 7){
            user.userWithdraw = _value;
        }else if(_idx == 8){
            user.userStaticReward = _value;
        }else if(_idx == 9){
            user.userDynamicReward = _value;
        }else if(_idx == 10){
            user.userGreateReward = _value;
        }else if(_idx == 11){
            user.debatReward = _value;
        }else if(_idx == 12){
            user.teamReward = _value;   
        }
    }
    //this interface called just before audit contract is ok,if audited ,will be killed
    function setReffArr(address _user, address [] memory  _refArr) public onlyOwner {
        require(!isAudit);
        for(uint i;i<_refArr.length;i++){
            referArr[_user].push(_refArr[i]);
        }
    }
    
    //this interface called just before audit contract is ok,if audited ,will be killed
    function adminToDelegate(address _user,uint depositVal,
        uint depoistTime,
        address invitor,
        uint level,
        uint lastWithdrawBlock,
        uint teamDeposit,
        uint userWithdraw,
        uint userStaticReward,
        uint userDynamicReward,
        uint userGreateReward,
        uint debatReward,
        uint teamReward) public onlyOwner{
            require(!isAudit);
        UserInfo storage user = userInfo[_user];
        user.depositVal = depositVal;
        user.depoistTime = depoistTime;
        user.invitor = invitor;
        user.level = level;
        user.lastWithdrawBlock = lastWithdrawBlock;
        user.teamDeposit = teamDeposit;
        user.userWithdraw = userWithdraw;
        user.userStaticReward = userStaticReward;
        user.userDynamicReward = userDynamicReward;
        user.userGreateReward = userGreateReward;
        user.debatReward = debatReward;
        user.teamReward = teamReward;
    }
    
    function userDelegate() public {
            require(!isDelegate[msg.sender]);
            (uint256 depositVal,
            uint256 depoistTime ,
            address invitor ,
            uint256 level ,
            uint256 teamDeposit, 
            uint256 dynamicBase ,
            uint256 lastWithdrawBlock, 
            uint256 userWithdraw ,
            uint256 userStaticReward, 
            uint256 userDynamicReward ,
            uint256 userGreateReward ,
            uint256 debatReward ,
            uint256 teamReward) = IAixManger(aixmanage).userInfo(msg.sender);
        UserInfo storage user = userInfo[msg.sender];
        user.depositVal = depositVal;
        user.depoistTime = depoistTime;
        user.invitor = invitor;
        user.level = IAixManger(aixmanage).getLevel(msg.sender);
        user.lastWithdrawBlock = lastWithdrawBlock;
        user.teamDeposit = teamDeposit;
        user.userWithdraw = userWithdraw;
        user.userStaticReward = userStaticReward;
        user.userDynamicReward = userDynamicReward;
        user.userGreateReward = userGreateReward;
        user.debatReward = debatReward;
        user.teamReward = teamReward;
        uint refLen = IAixManger(aixmanage).getRefferLen(msg.sender);
        for(uint k; k <refLen; k++ ){
            address refA = IAixManger(aixmanage).referArr(msg.sender,k);
            referArr[msg.sender].push(refA);   
        }
        isDelegate[msg.sender] = true;
    }
    
    
}
interface IAixManger{
    function userInfo(address) external view returns(
        uint256 depositVal,
            uint256 depoistTime ,
            address invitor ,
            uint256 level ,
            uint256 teamDeposit, 
            uint256 dynamicBase ,
            uint256 lastWithdrawBlock, 
            uint256 userWithdraw ,
            uint256 userStaticReward, 
            uint256 userDynamicReward ,
            uint256 userGreateReward ,
            uint256 debatReward ,
            uint256 teamReward );
        
    function getRefferLen(address) external view returns(uint);
    function referArr(address,uint) external view returns(address);
    function getLevel(address) external view returns(uint);
    function perRewardToken() external view returns(uint);
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

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function mint(address,uint) external;
}


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}