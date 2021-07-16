//SourceUnit: TATM_Staking&Rewards_v3.sol

pragma solidity >=0.4.23 <0.6.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface TokenContract {
   function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external  view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external  returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}

contract  TATM_Staking{
   using SafeMath for uint256;
   address owner;
   address tokenContract;

   address tokenContractAddress;

   mapping(address => uint256) joined;
   mapping(address => uint256) timeToUnfreeze;
   mapping(address => uint256) totalStaked;
   uint256 public freezeTimer = 2629743;  // Epoch counter for 30 days
   uint256 public interest = 1;  
   uint256 public minutesElapse = 5*60*24; // production 60 * 24
   mapping(address => uint256) withdrawable;
   mapping(address => uint256) withdrawn;

   event Staked(address addr, uint256 amount, uint256 stakingTime);
   event UnStaked(address addr, uint256 amount, uint256 unstakingTime);
   event Withdraw(address addr, uint256 amount);

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    constructor(address _tokenContractAddress) public {
        tokenContractAddress = _tokenContractAddress;
        owner = msg.sender;
    }

    function stake(uint256 value) public returns(bool success) {
        address self = address(this);
        if (totalStaked[msg.sender] > 0){
           if (claimStakingReward()){
               withdrawable[msg.sender] = 0;
           }
       }
        TokenContract tokencontract = TokenContract(tokenContractAddress);
        // requires approving before in ui.
        totalStaked[msg.sender] = totalStaked[msg.sender].add(value);
        joined[msg.sender] = block.timestamp;
        timeToUnfreeze[msg.sender] = block.timestamp.add(freezeTimer);

        tokencontract.transferFrom(msg.sender,self,value);

        emit Staked(msg.sender,value,block.timestamp);
        return true;
    }

    function unStake() public returns(bool success){
        if(timeDone(msg.sender)){
		if (claimStakingReward()){
               withdrawable[msg.sender] = 0;
           }
        require(totalStaked[msg.sender] > 0);
        TokenContract tokencontract = TokenContract(tokenContractAddress);
        tokencontract.transfer(msg.sender,totalStaked[msg.sender]);
        totalStaked[msg.sender] = 0;
        return true;
        }
    }

    function timeDone(address addr) public view returns(bool success){
         require(timeToUnfreeze[addr]>0);
         if(block.timestamp>timeToUnfreeze[addr])
            return true;
         else
            return false;
     }

     function joinedTime(address addr) public view returns(uint256 time){
         require(joined[addr]>0);
         return joined[addr];
     }

     function timeRemaining(address addr) public view returns(uint256 time){
         require(timeToUnfreeze[addr]>0);
         return timeToUnfreeze[addr].sub(block.timestamp);
     }

     function claimStakingReward() public returns(bool success){
        require(totalStaked[msg.sender] > 0);
        require(joined[msg.sender] > 0);
        uint256 balance = getBalance(msg.sender);
        if (balance > 0){
            withdrawable[msg.sender] = withdrawable[msg.sender].add(balance);
            withdrawn[msg.sender] = withdrawn[msg.sender].add(balance);
            TokenContract tokencontract = TokenContract(tokenContractAddress);
            tokencontract.transfer(msg.sender,balance);
			emit Withdraw(msg.sender, balance);
            return true;
        }
         else {
            return false;
        }
     }

     function getBalance(address addr) public view returns (uint256) {
        if(joined[addr]>0)
        {
            uint256 minutesCount = now.sub(joined[addr]).div(1 minutes); // how many hours since joined
            uint256 percent = totalStaked[addr].mul(interest).div(100); // how much to return, step = 3 is 3% return
            uint256 difference = percent.mul(minutesCount).div(minutesElapse); //  minuteselapse control the time for example 1 day to receive above interest
            uint256 balance = difference.sub(withdrawable[addr]); // calculate how much can withdraw now

            return balance;
        }else{
            return 0;
        }
    }

    function checkTATMRewards() public view returns (uint256) {
        return getBalance(msg.sender);
    }

    function rewardsWithdrawn(address staker) public view returns (uint256) {
        return withdrawn[staker];
    }

    function checkInvestments(address addr) public view returns (uint256) {
        return totalStaked[addr];
    }
	
	function takeTATM(uint256 value) onlyOwner public returns(bool success){
			TokenContract tokencontract = TokenContract(tokenContractAddress);
			tokencontract.transfer(msg.sender,value);
			return true;
	}
	
    function changeInterest(uint256 _newInterest) public onlyOwner {
        require(_newInterest > 0, "should be a valid interest");
        interest = _newInterest;
    }

    function changeFreezeTime(uint256 _newFreezeTimer) public onlyOwner {
        require(_newFreezeTimer > 0, "should be a valid free time amount");
        freezeTimer = _newFreezeTimer;
    }

    function changeDaysElapsed(uint256 _newDaysElapsed) public onlyOwner {
        require(_newDaysElapsed > 0, "should be a valid days");
        minutesElapse = _newDaysElapsed;
    }
}