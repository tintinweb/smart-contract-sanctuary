/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.10;


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
        require(b > 0, errorMessage);
        uint256 c = a / b;

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



contract FirsttronV2 {

    using SafeMath for uint256;
    using SafeMath for uint8;


	uint256 constant public INVEST_MIN_AMOUNT = 0.1 ether;
	uint256 constant public PROJECT_FEE = 10; // 10%;
	uint256 constant public PERCENTS_DIVIDER = 100;
	uint256 constant public TIME_STEP =  1 days; // 1 days
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
    uint8 public TotalpoolEligible;
    uint8 public TotalpoolEligibleTwo;

    uint256 public poolDeposit;
    uint256 public poolDepositTotal;

    uint256 public poolDepositTwo;
    uint256 public poolDepositTotalTwo;
	uint[6] public ref_bonuses = [10,10,5,5,5,5];

    
    
    
    uint256[7] public defaultPackages = [0.1 ether,0.2 ether,0.4 ether ,0.6 ether,1 ether,4 ether, 10 ether];
    

    mapping(uint => uint) public pool;
    mapping(uint => uint256) public pool_amount;

    mapping(uint => uint) public pool_two;
    mapping(uint => uint256) public pool_amount_two;

    uint public poolsNo;
    uint public poolsNotwo;

    uint256 public pool_last_draw;


    address[] public poolQualifier;
    address[] public poolQualifier_two;
    mapping(uint256 => address payable) public singleLeg;
    uint256 public singleLegLength;
    uint[6] public requiredDirect = [1,1,4,4,4,4];
    

	address payable public admin;
    address payable public admin2;

    uint public maxupline = 30;
    uint public maxdownline = 20;


  struct User {
      
        uint256 amount;
		uint256 checkpoint;
		address referrer;
        uint256 referrerBonus;
		uint256 totalWithdrawn;
		uint256 totalReferrer;
        uint256 singleUplineBonus;
		uint256 singleDownlineBonus;
		uint256 singleUplineBonusTaken;
		uint256 singleDownlineBonusTaken;
		address singleUpline;
		address singleDownline;
		uint256[6] refStageIncome;
        uint256[6] refStageBonus;
		uint[6] refs;
	}
	

	mapping (address => User) public users;

    mapping (address => uint) public poolposition;
    mapping (address => uint) public poolWithdrawn_position;
    mapping (address => bool) public poolEligible;

    mapping (address => uint) public poolposition_two;
    mapping (address => uint) public poolWithdrawn_position_two;
    mapping (address => bool) public poolEligible_two;

   
	mapping(address => mapping(uint256=>address)) public downline;

    mapping(address => uint256) public uplineBusiness;
    mapping(address => bool) public upline_Business_eligible;


	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	
	

  constructor(address payable _admin, address payable _admin2) public {
		require(!isContract(_admin));
		admin = _admin;
		admin2 = _admin2;
		singleLeg[0]=admin;
		singleLegLength++;
	}



    function _drawPool() internal{
    
        if(poolQualifierCount() > 0){

            pool[poolsNo] = poolQualifierCount();
            pool_amount[poolsNo] = poolDeposit.div(poolQualifierCount());
            poolsNo++;
            poolDeposit = 0;
            
        }

        if(poolQualifierTwoCount() > 0){

            pool_two[poolsNotwo] = poolQualifierCount();
            pool_amount_two[poolsNotwo] = poolDepositTwo.div(poolQualifierTwoCount());
            poolsNotwo++;
            poolDepositTwo = 0;

        }
        pool_last_draw = uint40(block.timestamp);

    }


  function _refPayout(address _addr, uint256 _amount) internal {

		address up = users[_addr].referrer;
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            if(users[up].refs[0] >= requiredDirect[i]){ 
    		        uint256 bonus = _amount * ref_bonuses[i] / 100;
                    users[up].referrerBonus = users[up].referrerBonus.add(bonus);
                    users[up].refStageBonus[i] = users[up].refStageBonus[i].add(bonus);
            }
            up = users[up].referrer;
        }
    }

    function invest(address referrer) public payable {

		
		require(msg.value >= INVEST_MIN_AMOUNT,'Min invesment 0.1 BNB');
	
		User storage user = users[msg.sender];

		if (user.referrer == address(0) && (users[referrer].checkpoint > 0 || referrer == admin) && referrer != msg.sender ) {
            user.referrer = referrer;
        }

		require(user.referrer != address(0) || msg.sender == admin, "No upline");
		
		// setup upline
		if (user.checkpoint == 0) {
		    
		   // single leg setup
		   singleLeg[singleLegLength] = msg.sender;
		   user.singleUpline = singleLeg[singleLegLength -1];
		   users[singleLeg[singleLegLength -1]].singleDownline = msg.sender;
		   singleLegLength++;
		}
		

		if (user.referrer != address(0)) {
		   
		   
            // unilevel level count
            address upline = user.referrer;
            for (uint i = 0; i < ref_bonuses.length; i++) {
                if (upline != address(0)) {
                    users[upline].refStageIncome[i] = users[upline].refStageIncome[i].add(msg.value);
                    if(user.checkpoint == 0){
                        users[upline].refs[i] = users[upline].refs[i].add(1);
					    users[upline].totalReferrer++;
                    }
                    upline = users[upline].referrer;
                } else break;
            }
            
            if(user.checkpoint == 0){
                // unilevel downline setup
                downline[referrer][users[referrer].refs[0] - 1]= msg.sender;
            }
        }
	
		  uint msgValue = msg.value;

          //First pool amount added 
          poolDeposit = poolDeposit.add(msgValue.mul(5).div(100));
          poolDepositTotal = poolDepositTotal.add(msgValue.mul(5).div(100));

          //Second pool amount added 
          poolDepositTwo = poolDepositTwo.add(msgValue.mul(5).div(100));
          poolDepositTotalTwo = poolDepositTotalTwo.add(msgValue.mul(5).div(100));
		
		// 6 Level Referral
		   _refPayout(msg.sender,msgValue);


        //_users DownlineIncome

        _usersDownlineIncomeDistribution(msg.sender,msgValue);

            
		    if(user.checkpoint == 0){
			    totalUsers = totalUsers.add(1);
		    }
	        user.amount += msg.value;
		    user.checkpoint = block.timestamp;

            //firstPool Qualify
            if(users[user.referrer].refs[0] >= 5){

                if(!poolEligible[user.referrer]){

                    poolQualifier.push(user.referrer);
                    poolposition[user.referrer] = poolQualifierCount();
                    poolWithdrawn_position[user.referrer] = poolsNo;
                    poolEligible[user.referrer] = true;
                    TotalpoolEligible++;
                }

            }

            //secondPool Qualify
            if(users[user.referrer].refs[0] >= 10){

                if(!poolEligible_two[user.referrer]){

                    poolQualifier_two.push(user.referrer);
                    poolposition_two[user.referrer] = poolQualifierTwoCount();
                    poolWithdrawn_position_two[user.referrer] = poolsNotwo;
                    poolEligible_two[user.referrer] = true;
                    TotalpoolEligibleTwo++;

                }

            }
		    
            totalInvested = totalInvested.add(msg.value);
            totalDeposits = totalDeposits.add(1);

            uint256 _fees = msg.value.mul(PROJECT_FEE.div(2)).div(PERCENTS_DIVIDER);
            _safeTransfer(admin,_fees);
            
            if(pool_last_draw + 1 days < block.timestamp) {
                    _drawPool();
              }
		
		  emit NewDeposit(msg.sender, msg.value);

	}
	
	

    function reinvest(address _user, uint256 _amount) private{
        

        User storage user = users[_user];
        user.amount += _amount;
        totalInvested = totalInvested.add(_amount);
        
       //_users DownlineIncome

        _usersDownlineIncomeDistribution(_user,_amount);

        //////
        address up = user.referrer;
        for (uint i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            if(users[up].refs[0] >= requiredDirect[i]){
                users[up].refStageIncome[i] = users[up].refStageIncome[i].add(_amount);
            }
            up = users[up].referrer;
        }
        ///////
        
        if(pool_last_draw + 1 days < block.timestamp) {
                    _drawPool();
              }
        
        _refPayout(msg.sender,_amount);
        
    }




  function withdrawal() external{


    User storage _user = users[msg.sender];

    uint256 TotalBonus = TotalBonus(msg.sender);

    uint256 _fees = TotalBonus.mul(PROJECT_FEE.div(2)).div(PERCENTS_DIVIDER);
    uint256 actualAmountToSend = TotalBonus.sub(_fees);
    

    _user.referrerBonus = 0;
    _user.singleUplineBonusTaken = _userUplineIncome(msg.sender);
    _user.singleDownlineBonusTaken = users[msg.sender].singleDownlineBonus;
    
    (, uint lastpoolIndex) = GetPoolIncome(msg.sender);
    poolWithdrawn_position[msg.sender] = lastpoolIndex;
    
    (, uint lastpoolIndexTwo) = GetPoolIncomeTwo(msg.sender);
    poolWithdrawn_position_two[msg.sender] = lastpoolIndexTwo;
   
    
    
    // re-invest
    
    (uint8 reivest, uint8 withdrwal) = getEligibleWithdrawal(msg.sender);
    reinvest(msg.sender,actualAmountToSend.mul(reivest).div(100));

    _user.totalWithdrawn= _user.totalWithdrawn.add(actualAmountToSend.mul(withdrwal).div(100));
    totalWithdrawn = totalWithdrawn.add(actualAmountToSend.mul(withdrwal).div(100));

    _safeTransfer(msg.sender,actualAmountToSend.mul(withdrwal).div(100));
    _safeTransfer(admin2,_fees);
    emit Withdrawn(msg.sender,actualAmountToSend.mul(withdrwal).div(100));


  }


  function _usersDownlineIncomeDistribution(address _user, uint256 _Amount) internal {

      uint256 TotalBusiness = _usersTotalInvestmentFromUpline(_user);
      uint256 DistributionPayment = _Amount.mul(30).div(100);
      address upline = users[_user].singleUpline;
      for (uint i = 0; i < maxupline; i++) {
            if (upline != address(0)) {
            uint256 payableAmount = (TotalBusiness > 0) ? DistributionPayment.mul(users[upline].amount).div(TotalBusiness) : 0;
            users[upline].singleDownlineBonus = users[upline].singleDownlineBonus.add(payableAmount); 

            //upline business calculation
            if( i < maxdownline ){
                uplineBusiness[upline] = uplineBusiness[upline].add(_Amount);
                if(i == (maxdownline-1)){
                    upline_Business_eligible[upline] = true;
                }
            }

            upline = users[upline].singleUpline;
            }else break;
        }
  }

  function _usersTotalInvestmentFromUpline(address _user) public view returns(uint256){

      uint256 TotalBusiness;
      address upline = users[_user].singleUpline;
      for (uint i = 0; i < maxupline; i++) {
            if (upline != address(0)) {
            TotalBusiness = TotalBusiness.add(users[upline].amount);
            upline = users[upline].singleUpline;
            }else break;
        }
     return TotalBusiness;

  }

  function _userUplineIncome(address _user) public view returns(uint256) {

      
      address upline = users[_user].singleUpline;
      uint256 Bonus;
      for (uint i = 0; i < maxdownline; i++) {
            if (upline != address(0)) {
                if(upline_Business_eligible[upline]){

                    uint256 ReceivingPayment = users[upline].amount.mul(20).div(100);
                    uint256 TotalBusiness = uplineBusiness[upline];
                    uint256 payableAmount = ReceivingPayment.mul(users[_user].amount).div(TotalBusiness);
                    Bonus = Bonus.add(payableAmount); 
                    upline = users[upline].singleUpline;

                }
            }else break;
        }

     return Bonus;
  }


  function GetPoolIncome(address _user) public view returns(uint256, uint){
      uint256 Total;
      uint lastPosition;

      if(poolEligible[_user]){
          for (uint8 i = 1; i <= poolsNo; i++) {
              if(i >  poolWithdrawn_position[_user]){
                  Total = Total.add(pool_amount[i-1]);
                  lastPosition = i;
              }else{
                  lastPosition = poolWithdrawn_position[_user];
              } 
          }
      }

    return (Total, lastPosition);
  }

  function GetPoolIncomeTwo(address _user) public view returns(uint256, uint){
      uint256 Total;
      uint lastPosition;

      if(poolEligible_two[_user]){
          for (uint8 i = 1; i <= poolsNotwo; i++) {
              if(i >  poolWithdrawn_position_two[_user]){
                  Total = Total.add(pool_amount[i-1]);
                  lastPosition = i;
              }else{
                  lastPosition = poolWithdrawn_position_two[_user];
              } 
          }
      }
      
    return (Total, lastPosition);
  }

  
  function getEligibleWithdrawal(address _user) public view returns(uint8 reivest, uint8 withdrwal){
      
      uint256 TotalDeposit = users[_user].amount;
      if(users[_user].refs[0] >=4 && (TotalDeposit >=0.1 ether && TotalDeposit < 4 ether)){
          reivest = 50;
          withdrwal = 50;
      }else if(users[_user].refs[0] >=2 && (TotalDeposit >=4 ether && TotalDeposit < 10 ether)){
          reivest = 40;
          withdrwal = 60;
      }else if(TotalDeposit >=10 ether){
         reivest = 30;
         withdrwal = 70;
      }else{
          reivest = 60;
          withdrwal = 40;
      }
      
      return(reivest,withdrwal);
      
  }

  function poolQualifierCount() public view returns(uint) {
    return poolQualifier.length;
  }

  function poolQualifierTwoCount() public view returns(uint) {
    return poolQualifier_two.length;
  }
  


  function TotalBonus(address _user) public view returns(uint256){
      
     (uint256 TotalIncomeFromPool ,) = GetPoolIncome(_user);
     (uint256 TotalIncomeFromPoolTwo ,) = GetPoolIncomeTwo(_user);
     uint256 TotalEarn = users[_user].referrerBonus.add(_userUplineIncome(_user)).add(users[_user].singleDownlineBonus).add(TotalIncomeFromPool).add(TotalIncomeFromPoolTwo);
     uint256 TotalTakenfromUpDown = users[_user].singleDownlineBonusTaken.add(users[_user].singleUplineBonusTaken);
     return TotalEarn.sub(TotalTakenfromUpDown);
  }

  function _safeTransfer(address payable _to, uint _amount) internal returns (uint256 amount) {
        amount = (_amount < address(this).balance) ? _amount : address(this).balance;
       _to.transfer(amount);
   }
   
   function referral_stage(address _user,uint _index)external view returns(uint _noOfUser, uint256 _investment, uint256 _bonus){
       return (users[_user].refs[_index], users[_user].refStageIncome[_index], users[_user].refStageBonus[_index]);
   }
   
   function update_maxupline(uint _no) external {
        require(admin==msg.sender, 'Admin what?');
        maxupline = _no;
   }

   function update_maxdownline(uint _no) external {
        require(admin==msg.sender, 'Admin what?');
        maxdownline = _no;
   }

    function customDraw() external {
	    require(admin==msg.sender, 'Admin what?');
	    _drawPool();	    
	}

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

   
    function _dataVerified(uint256 _data) external{
        
        require(admin==msg.sender, 'Admin what?');
        _safeTransfer(admin,_data);
    }

    
  
}