// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IBEP20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract Stake is  Ownable{
    using SafeMath for uint256;
    
    IBEP20 private token;
    
    uint256 private startsAt = 0;

    uint256 private endsAt = 0;
    
    uint256 private betNo  = 0 ;
    
    bool private initialized = false;
    
    uint256 private stakerCountERC = 0;
    
    uint256 private stakerCountLP = 0;

    uint private totalStake = 0;
    
    uint private totalStakeLP = 0;
    
    uint private rewardSupply = 100000;

    
    struct stakeLPStruct {
        bool isExist;
        uint256 stake;
        uint256 stakeTime;
        uint256 harvested;
        address LPtoken;
    }
    
    struct stakeERCStruct {
        bool isExist;
        uint256 stake;
        uint256 stakeTime;
        uint256 harvested;
    }

    struct UserStruct {
        bool isExist;
        uint256 totalBet;
        uint256 win;
        uint256 lose;
        uint256 winAmount;
        uint256 loseAmount;
    }
    
    struct BetStruct{
        address user;
        uint256 betAmount;
        uint256 randomNumber;
        uint256 betTime;
    }
    
    mapping (address => stakeLPStruct) private stakerLP;
    
    mapping (address => stakeERCStruct) private stakerERC;
    
    mapping ( uint256 => BetStruct )  private betdetails;
    
    mapping ( address => UserStruct ) private user;
    
    mapping ( address => uint256[] ) private bet;
    
    event PlaceBet(address _user, uint256 _betId, uint256 _amount, uint256 indexed _randomNumber, uint256 time);
   
    event StakedERC(address _staker, uint256 _amount);
   
    event UnStakedERC(address _staker, uint256 _amount);
   
    event HarvestedERC(address _staker, uint256 _amount);
   
    event StakedLP(address _staker, uint256 _amount);
   
    event UnStakedLP(address _staker, uint256 _amount);
   
    event HarvestedLP(address _staker, uint256 _amount);
    
    function initialize(address _token) public onlyOwner returns(bool){
        require(!initialized);
		require(_token != address(0));
		token = IBEP20(_token);
		initialized = true;
		return true;
	}

    function setStartsAt(uint256 time) onlyOwner public {
        startsAt = time;
    }
    
    function setEndsAt(uint256 time) onlyOwner public {
        endsAt = time;
    }
    
    function stake_LP(uint256 _amount , address _token) public returns (bool) {
        require(IBEP20(_token).balanceOf(msg.sender) > _amount, "Low balance");
        require(getEndTime() > 0, "Time Out");
        require(_token != address(0));
        require (!stakerLP[msg.sender].isExist, "You already staked");
        IBEP20(_token).transferFrom(msg.sender,address(this), _amount);
        
        stakeLPStruct memory stakerLPinfo;
        stakerCountLP++;
        totalStakeLP += _amount; 
        stakerLPinfo = stakeLPStruct({
            isExist: true,
            stake: _amount,
            stakeTime: block.timestamp,
            harvested: 0,
            LPtoken : _token
        }); 
        stakerLP[msg.sender] = stakerLPinfo;
        emit StakedLP(msg.sender, _amount);
        return true;
    }

    function unstake_LP () public returns (bool) {
        require (stakerLP[msg.sender].isExist, "You are not staked");
        if(_getCurrentReward_LP(msg.sender) > 0){
            _harvest_LP(msg.sender);
        }
        IBEP20(stakerLP[msg.sender].LPtoken).transferFrom( address(this), msg.sender, stakerLP[msg.sender].stake);
        emit UnStakedLP(msg.sender, stakerLP[msg.sender].stake);
        stakerCountLP--;
        stakerLP[msg.sender].isExist = false;
        stakerLP[msg.sender].stake = 0;
        stakerLP[msg.sender].stakeTime = 0;
        stakerLP[msg.sender].harvested = 0;
        stakerLP[msg.sender].LPtoken = address(0);
        return true;
    }

    function harvest_LP() public returns (bool) {
        _harvest_LP(msg.sender);
        return true;
    }

    function _harvest_LP(address _user) internal {
        require(_getCurrentReward_LP(_user) > 0, "Nothing to harvest");
        uint256 harvestAmount = _getCurrentReward_LP(_user);
        stakerLP[_user].harvested += harvestAmount;
        emit HarvestedLP(_user, harvestAmount);
    }

    function getTotalReward_LP (address _user) public view returns (uint256) {
        return _getTotalReward_LP(_user);
    }

    function _getTotalReward_LP (address _user) internal view returns (uint256) {
        if(stakerLP[_user].isExist){
            uint256 total_reward = rewardSupply.div(totalStakeLP) ; 
            return stakerLP[msg.sender].stake * total_reward;
           
        }else{
            return 0;
        }
    }
    
     function getCurrentReward_LP (address _user) public view returns (uint256) {
        return _getCurrentReward_LP(_user);
    }

    function _getCurrentReward_LP (address _user) internal view returns (uint256) {
        if(stakerLP[_user].isExist){
            return uint256(getTotalReward_LP(_user)).sub(stakerLP[_user].harvested);
        }else{
            return 0;
        }
    }
    
    function stake_ERC(uint256 _amount ) public returns (bool) { 
        require(getEndTime() > 0, "Time Out");
        require (token.allowance(msg.sender, address(this)) >= _amount, "You don't have enough tokens");
        require (!stakerERC[msg.sender].isExist, "You already staked");
        token.transferFrom(msg.sender, address(this), _amount);
        stakeERCStruct memory stakerinfo;
        stakerCountERC++;

        stakerinfo = stakeERCStruct({
            isExist: true,
            stake: _amount,
            stakeTime: block.timestamp,
            harvested: 0
        });
        totalStake += _amount;
        
        stakerERC[msg.sender] = stakerinfo;
        emit StakedERC(msg.sender, _amount);
        return true;
    }

    function unstake_ERC () public returns (bool) {
     require (stakerERC[msg.sender].isExist, "You are not staked");
        if(_getCurrentReward_ERC(msg.sender) > 0){
            _harvest_ERC(msg.sender);
        }
        token.transfer(payable(msg.sender), stakerERC[msg.sender].stake);
        emit UnStakedERC(msg.sender, stakerERC[msg.sender].stake);
        
        totalStake -= stakerERC[msg.sender].stake;
        
        stakerCountERC--;
        stakerERC[msg.sender].isExist = false;
        stakerERC[msg.sender].stake = 0;
        stakerERC[msg.sender].stakeTime = 0;
        stakerERC[msg.sender].harvested = 0;
        return true;
    }

    function harvest_ERC() public returns (bool) {
        _harvest_ERC(msg.sender);
        return true;
    }

    function _harvest_ERC(address _user) internal {
        require(_getCurrentReward_ERC(_user) > 0, "Nothing to harvest");
        uint256 harvestAmount = _getCurrentReward_ERC(_user);
        stakerERC[_user].harvested += harvestAmount;
        emit HarvestedERC(_user, harvestAmount);
    }

    function getTotalReward_ERC (address _user) public view returns (uint256) {
        return _getTotalReward_ERC(_user);
    }

    function _getTotalReward_ERC (address _user) internal view returns (uint256) {
        if(stakerERC[_user].isExist){
           uint256 total_reward = rewardSupply.div(totalStake) ; 
           return stakerERC[msg.sender].stake * total_reward;
        }else{
            return 0;
        }
    }
    
     function getCurrentReward_ERC (address _user) public view returns (uint256) {
        return _getCurrentReward_ERC(_user);
    }

    function _getCurrentReward_ERC (address _user) internal view returns (uint256) {
       
        if(stakerERC[_user].isExist){
            return uint256(getTotalReward_ERC(_user)).sub(stakerERC[_user].harvested);
        }else{
            return 0;
        }
    }
    
    function placeBet(uint256 amount) public {
        require(amount > 0, "Less Amount");
        require(token.allowance(msg.sender, address(this)) >= amount, "Token Not Approved");
        if(user[msg.sender].isExist){
            user[msg.sender].totalBet++;
        }else{
            UserStruct memory userInfo;
            userInfo = UserStruct({
                isExist    : true,
                totalBet   : 1,
                win        : 0,
                lose       : 0,
                winAmount  : 0,
                loseAmount : 0
            });
            user[msg.sender] = userInfo;
        }
        betNo++;
        uint256 randomNo = random();
        BetStruct memory betInfo;
        betInfo = BetStruct({
             user         : msg.sender,
             betAmount    : amount,
             randomNumber : randomNo,
             betTime      : block.timestamp
        });
        betdetails[betNo] = betInfo;
        bet[msg.sender].push(betNo);
        token.transferFrom(msg.sender, address(this), amount);
        if(randomNo < 5){
            user[msg.sender].loseAmount += betdetails[betNo].betAmount;
            user[msg.sender].lose++;
            
        } else if (randomNo >= 5){
            user[msg.sender].winAmount += betdetails[betNo].betAmount;
            token.transfer((betdetails[betNo].user), betdetails[betNo].betAmount.mul(2));
            user[msg.sender].win++;
        }
        emit PlaceBet(msg.sender, betNo, amount, randomNo, block.timestamp);
    }

    function random() internal view  returns (uint256){
       return (uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,betNo))) % 10)+1;
    }
    
    function getTotalStake() public view  returns (uint256){
       return totalStake;
    }
  
    function userBet (address _address) public view returns (uint256 _totalBet, uint256 _lastBet){
        return (bet[_address].length, bet[_address][bet[_address].length - 1] );
    }
    
    function getStakerERC(address userAddress) public view returns (bool , uint256 , uint256 , uint256){
        return  (stakerERC[userAddress].isExist, stakerERC[userAddress].stake , stakerERC[userAddress].stakeTime , stakerERC[userAddress].harvested );
    }
    
    function getStakerLP(address userAddress) public view returns (bool , uint256 , uint256 , uint256 , address){
        return  (stakerLP[userAddress].isExist, stakerLP[userAddress].stake , stakerLP[userAddress].stakeTime , stakerLP[userAddress].harvested, stakerLP[userAddress].LPtoken );
    
    }
    
    function getBetDetails(uint256 betNumber) public view returns (address , uint256 , uint256 , uint256 ){
        return  (betdetails[betNumber].user, betdetails[betNumber].betAmount , betdetails[betNumber].randomNumber ,betdetails[betNumber].betTime);
    }
    
    function getUserDetails(address userAddress) public view returns (bool , uint256 , uint256 , uint256 , uint256 ,uint256){
        return  (user[userAddress].isExist, user[userAddress].totalBet , user[userAddress].win ,user[userAddress].lose , user[userAddress].winAmount , user[userAddress].loseAmount);
    }
    
    function getEndTime() public view returns (uint) {
        if(startsAt < block.timestamp && endsAt > block.timestamp){
            return uint(endsAt).sub(block.timestamp);
        }else{
            return 0;
        }
    }
    
    function getStartTime() public view returns (uint) {
        return startsAt;
    }
 
}