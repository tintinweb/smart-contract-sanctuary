// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IBEP20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./BEP20.sol";

contract BookieToken is BEP20, Ownable {
    uint256 private  _totalSupply = 50000000 * 10 ** 8;
    address private  minter ;

    constructor (string memory name, string memory symbol) BEP20(name, symbol) {
        _mint(msg.sender, _totalSupply);
    }
    
    function burn(uint256 amount) external  {
        _burn(msg.sender, amount);
    }

    function mint(address reciever, uint256 amount) external  {
        require(msg.sender == minter, "Unauthorized");
         _mint(reciever, amount);
    }

    function set_minter( address reciever) external onlyOwner {
        minter = reciever;
    }
      
}

contract Stake is  Ownable{
    using SafeMath for uint256;
    
    BookieToken private token;

    IBEP20 private LPtoken;
    
    uint256 private startsAt = 0;

    uint256 private endsAt = 0;
    
    uint256 private betNo  = 0 ;
    
    bool private initialized = false;

    bool private initializedLP = false;
    
    uint256 private stakerCountERC = 0;
    
    uint256 private stakerCountLP = 0;

    uint256 private totalStakeERC = 0;
    
    uint256 private totalStakeLP = 0;
    
    uint256 private rewardSupply = 100000;

    struct stakeLP {
        bool isExist;
        uint256 stake;
        uint256 stakeTime;
        uint256 harvested;
    }
    
    struct stakeERC {
        bool isExist;
        uint256 stake;
        uint256 stakeTime;
        uint256 harvested;
    }

    struct userDetail {
        bool isExist;
        uint256 totalBet;
        uint256 win;
        uint256 lose;
        uint256 winAmount;
        uint256 loseAmount;
    }
    
    struct betDetail{
        address user;
        uint256 betAmount;
        uint256 randomNumber;
        uint256 betTime;
    }
    
    mapping (address => stakeLP) private stakerLP;
    
    mapping (address => stakeERC) private stakerERC;
    
    mapping ( uint256 => betDetail )  private betdetails;
    
    mapping ( address => userDetail ) private user;
    
    mapping ( address => uint256[] ) private bet;
    
    event PlaceBet(address _user, uint256 _betId, uint256 _amount, uint256  _randomNumber, uint256 _time);
   
    event StakedERC(address _staker, uint256 _amount , uint256 _time);
   
    event UnStakedERC(address _staker, uint256 _amount , uint256 _time);
   
    event HarvestedERC(address _staker, uint256 _amount , uint256 _time);
   
    event StakedLP(address _staker, uint256 _amount , uint256 _time);
   
    event UnStakedLP(address _staker, uint256 _amount , uint256 _time);
   
    event HarvestedLP(address _staker, uint256 _amount , uint256 _time);
    
    function initialize(address _token) public onlyOwner returns(bool){
        require(!initialized);
		require(_token != address(0));
		token = BookieToken(_token);
		initialized = true;
		return true;
	}
	
    function LPinitialize(address _token) public onlyOwner returns(bool){
        require(!initializedLP);
		require(_token != address(0));
		LPtoken = IBEP20(_token);
        initializedLP = true;
		return true;
	}

    function setStartsAt(uint256 _time) onlyOwner public returns (bool){
        startsAt = _time;
        return true;
    }
    
    function setEndsAt(uint256 _time) onlyOwner public  returns (bool){
        endsAt = _time;
        return true;
    }
    
    function stake_LP(uint256 _amount ) public returns (bool) {
        require (_amount > 0, "Invalid amount");
        require (LPtoken.allowance(msg.sender, address(this)) >= _amount, "Token not approved");
        require(getEndTime() > 0, "Time Out");
        require (!stakerLP[msg.sender].isExist, "You already staked");
        LPtoken.transferFrom(msg.sender,address(this), _amount);
        stakeLP memory stakerLPinfo;
        stakerCountLP++;
        totalStakeLP += _amount; 
        stakerLPinfo = stakeLP({
            isExist: true,
            stake: _amount,
            stakeTime: block.timestamp,
            harvested: 0
        }); 
        stakerLP[msg.sender] = stakerLPinfo;
        emit StakedLP(msg.sender, _amount , block.timestamp);
        return true;
    }

    function unstake_LP () public returns (bool) {
        require (stakerLP[msg.sender].isExist, "You are not staked");
        if(getCurrentReward_LP(msg.sender) > 0){
            _harvest_LP(msg.sender);
        }
        token.transfer(msg.sender, stakerLP[msg.sender].stake);
        stakerCountLP--;
        totalStakeLP -= stakerLP[msg.sender].stake;
        stakerLP[msg.sender].isExist = false;
        stakerLP[msg.sender].stake = 0;
        stakerLP[msg.sender].stakeTime = 0;
        stakerLP[msg.sender].harvested = 0;
        emit UnStakedLP(msg.sender, stakerLP[msg.sender].stake ,block.timestamp);
        return true;
    }

    function harvest_LP() public returns (bool) {
        _harvest_LP(msg.sender);
        return true;
    }

    function _harvest_LP(address _user) internal {
        require(getCurrentReward_LP(_user) > 0, "Nothing to harvest");
        uint256 harvestAmount = getCurrentReward_LP(_user);
        token.mint(_user, harvestAmount);
        stakerLP[_user].harvested += harvestAmount;
        emit HarvestedLP(_user, harvestAmount ,block.timestamp);
    }

    function getTotalReward_LP (address _user) public view returns (uint256) {
        if(stakerLP[_user].isExist){
            return uint256(block.timestamp).sub(stakerLP[_user].stakeTime).mul(stakerLP[_user].stake).mul(rewardSupply).div(totalStakeLP).div(1 days);
        }else{
            return 0;
        }
    }

    function getCurrentReward_LP (address _user) public view returns (uint256) {
        if(stakerLP[_user].isExist){
            return (getTotalReward_LP(_user)).sub(stakerLP[_user].harvested);
        }else{
            return 0;
        }
    }
    
    function stake_ERC(uint256 _amount ) public returns (bool) { 
        require (_amount > 0, "Invalid amount");
        require(getEndTime() > 0, "Time Out");
        require (token.allowance(msg.sender, address(this)) >= _amount, "Token not approved");
        require (!stakerERC[msg.sender].isExist, "You already staked");
        token.transferFrom(msg.sender, address(this), _amount);
        stakeERC memory stakerinfo;
        stakerCountERC++;

        stakerinfo = stakeERC({
            isExist: true,
            stake: _amount,
            stakeTime: block.timestamp,
            harvested: 0
        });
        totalStakeERC += _amount;
        
        stakerERC[msg.sender] = stakerinfo;
        emit StakedERC(msg.sender, _amount ,block.timestamp);
        return true;
    }

    function unstake_ERC() public returns (bool) {
        require (stakerERC[msg.sender].isExist, "You are not staked");
        if(getCurrentReward_ERC(msg.sender) > 0){
            _harvest_ERC(msg.sender); 
        }
        token.transfer(msg.sender, stakerERC[msg.sender].stake);
        emit UnStakedERC(msg.sender, stakerERC[msg.sender].stake ,block.timestamp);
        totalStakeERC -= stakerERC[msg.sender].stake;
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
        require(getCurrentReward_ERC(_user) > 0, "Nothing to harvest");
        uint256 harvestAmount = getCurrentReward_ERC(_user);
        token.mint(_user, harvestAmount);
        stakerERC[_user].harvested += harvestAmount;
        emit HarvestedERC(_user, harvestAmount ,block.timestamp);
    }

    function getTotalReward_ERC(address _user) public view returns (uint256) {
        if(stakerERC[_user].isExist){
        return uint256(block.timestamp).sub(stakerERC[_user].stakeTime).mul(stakerERC[_user].stake).mul(rewardSupply).div(totalStakeERC).div(1 days);
        }else{
            return 0;
        }
    }
    
    function getCurrentReward_ERC(address _user) public view returns (uint256) {
        if(stakerERC[_user].isExist){
            return (getTotalReward_ERC(_user)).sub(stakerERC[_user].harvested);
        }else{
            return 0;
        }
    }
    
    function placeBet(uint256 _amount) public returns (bool){
        require(_amount > 0, "Less Amount");
        require(token.allowance(msg.sender, address(this)) >= _amount, "Token Not Approved");
        if(user[msg.sender].isExist){
            user[msg.sender].totalBet++;
        }else{
            userDetail memory userInfo;
            userInfo = userDetail({
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
        betDetail memory betInfo;
        betInfo = betDetail({
             user         : msg.sender,
             betAmount    : _amount,
             randomNumber : randomNo,
             betTime      : block.timestamp
        });
        betdetails[betNo] = betInfo;
        bet[msg.sender].push(betNo);
        token.transferFrom(msg.sender, address(this), _amount);
        if(randomNo < 5){
            user[msg.sender].loseAmount += _amount;
            user[msg.sender].lose++;
            
        } else if (randomNo >= 5){
            user[msg.sender].winAmount += _amount.mul(2);
            token.transfer(msg.sender, _amount.mul(2));
            user[msg.sender].win++;
        }
        emit PlaceBet(msg.sender, betNo, _amount, randomNo, block.timestamp);
        return true;
    }

    function random() internal view  returns (uint256){
       return (uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,betNo))) % 10)+1;
    }
    
    function getTotalStakeERC() public view  returns (uint256){
       return totalStakeERC;
    }
    
    function getTotalStakeLP() public view  returns (uint256){
       return totalStakeLP;
    }
  
    function userBet (address _address) public view returns (uint256 _totalBet, uint256 _lastBet){
        return (bet[_address].length, bet[_address][bet[_address].length - 1] );
    }
    
    function getStakerERC(address _userAddress) public view returns (bool , uint256 , uint256 , uint256){
        return  (stakerERC[_userAddress].isExist, stakerERC[_userAddress].stake , stakerERC[_userAddress].stakeTime , stakerERC[_userAddress].harvested );
    }
    
    function getStakerLP(address _userAddress) public view returns (bool , uint256 , uint256 , uint256 ){
        return  (stakerLP[_userAddress].isExist, stakerLP[_userAddress].stake , stakerLP[_userAddress].stakeTime , stakerLP[_userAddress].harvested);
    
    }
    
    function getBetDetails(uint256 _betNumber) public view returns (address , uint256 , uint256 , uint256 ){
        return  (betdetails[_betNumber].user, betdetails[_betNumber].betAmount , betdetails[_betNumber].randomNumber ,betdetails[_betNumber].betTime);
    }
    
    function getUserDetails(address _userAddress) public view returns (bool , uint256 , uint256 , uint256 , uint256 ,uint256){
        return  (user[_userAddress].isExist, user[_userAddress].totalBet , user[_userAddress].win ,user[_userAddress].lose , user[_userAddress].winAmount , user[_userAddress].loseAmount);
    }
    
    function getEndTime() public view returns (uint) {
        if(startsAt < block.timestamp && endsAt > block.timestamp){
            return (endsAt).sub(block.timestamp);
        }else{
            return 0;
        }
    }
    
    function getStartTime() public view returns (uint) {
        return startsAt;
    }
 
}