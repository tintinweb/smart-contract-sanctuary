/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

pragma solidity >=0.4.0 <0.8.0;



contract TestNet {

// 	using SafeMath for uint256;
// //	BNBTest token;
	
	address public owner;
	address  public maintenance_wallet;
	address  public Ranks_wallet;
	address  public provision_wallet;
	address  public promotion_wallet;
	uint256 public ranksCount;
	uint256 public provisionCount;
	uint256 public promotionCount;
	uint256 constant public INVEST_MIN_AMOUNT = 30e18 ;
	uint256 public BASE_PERCENT = 5;
	uint256[15] public MATCHING_PERCENTS = [200,100,100,100,50,50,50,50,50,50,50,50,60,70,80];
	uint256[15] public UNIlevelAmount = [30e18,100e18,100e18,200e18,500e18,1000e18,1500e18,2000e18,3000e18,3000e18,3000e18,3000e18,3000e18,3000e18,3000e18];
    uint256[15] public UNIlevelTeamAmount = [200e18,500e18,1000e18,1500e18,2000e18,3000e18,3000e18,3000e18,3000e18,3000e18,3000e18,3000e18,3000e18,3000e18,30000e18];
    uint256[15] public rankBonus = [0,0,0,0,0,500e18,1000e18,1500e18,2000e18,3000e18,5000e18,10000e18,12000e18,15000e18,20000e18];
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint256 public totalreinvested;
	
	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}
	
	struct User {
		Deposit[] deposits;
		uint256 referrals;
		uint256 checkpoint;
		address referrer;
		address[] referralsList;
		uint256 refBonus;
		uint256 UniLevelBonus;
		uint256 reinvestwallet;
		uint256 withdrawRef;
		uint256 lastinvestment;
		uint256 totalStructure; 
		uint256 structureAmount;
		bool investor;
	}


	  function payoutToWallet(address payable _user, uint256 _amount) public
    {
        _user.transfer(_amount);
    }
    
        function join_newmember(address _upline) public payable {
        // require(msg.value > 1.0 trx);
        //  if(users[_upline].deposit_time > 0) {
            
        // }
    }
  
}