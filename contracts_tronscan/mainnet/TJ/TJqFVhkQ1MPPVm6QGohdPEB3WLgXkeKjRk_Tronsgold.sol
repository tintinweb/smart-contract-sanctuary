//SourceUnit: tronsgold(2).sol


pragma solidity 0.5.9;

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


// Owner Handler
contract ownerShip    
{
    //Global storage declaration
    address payable public ownerWallet;

    //Sets owner only on first run
    constructor() public 
    {
        //Set contract owner
        ownerWallet = msg.sender;
    }

    //This will restrict function only for owner where attached
    modifier onlyOwner() 
    {
        require(msg.sender == ownerWallet);
        _;
    }

}


contract Tronsgold is ownerShip {
    using SafeMath for uint256;
    uint public defaultRefID = 1;  //this ref ID will be used if user joins without any ref ID
    uint maxDownLimit = 2;
    uint public lastIDCount = 0;
	uint256 constant public PERCENTS_DIVIDER = 100;
    address payable public adminAddress;
    mapping(uint256 => uint256) levelRefCount;
    mapping(uint256 => uint256) levelRefGlobalCount;
    address[] userList;
    address[] userFastMatrixList;

    struct userInfo {
        bool joined;
        uint id;
        uint referrerID;
        uint bonus;
        uint partnerCount;
        uint originalReferrer;
        uint gainAmountCounter;
        uint booster_income;
        uint superfast_income;
        uint total_deposits;
        uint global_deposits;
        uint investAmountCounter;
        address payable[] referral;
        mapping(uint => uint) activeX5Levels;
        mapping(uint => uint) activeX3Levels;
		mapping(uint256 => uint256) uplineIncomeCount;
        mapping(uint => X5) x5Matrix;
        mapping(uint => X3) x3Matrix;
    }
    
    struct X5 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
    }
    
    struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        
    }
    
    uint8 public constant LAST_LEVEL = 10;
    mapping (address => userInfo) public userInfos;
    mapping (uint => address payable ) public userAddressByID;
 
    
    mapping(uint => uint) public levelPrice;
    mapping(uint => uint) public blevelPrice;
     mapping(uint => uint) public cappingPrice;
    mapping(uint => uint) public currentvId;
    mapping(uint => mapping(uint => address)) vId_number;   
    mapping(uint => uint) public index;

    event regLevelEv(address indexed useraddress, uint userid,uint placeid,uint refferalid, address indexed refferaladdress, uint _time);
    event LevelByEv(uint userid,address indexed useraddress, uint level,uint amount, uint time);    
    event paidForLevelEv(uint fromUserId, address fromAddress, uint toUserId,address toAddress, uint amount,uint level,uint packageAmount, uint time,string income_type );
    event lostForLevelEv(address indexed _user, address indexed _referral,uint amount,uint level, uint _packageAmount, uint _time,string income_type);
   
     event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place, uint amount);
    event Upgrade(address indexed user, address indexed referrer, uint8 _level, uint matrix);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount,uint256 level, string income_type);
    event Booster(address indexed addr, uint256 amount,uint matrix,string income_type);
    
    constructor() public {
		levelPrice[1]   =  200 trx;
        levelPrice[2]   =  250 trx;
        levelPrice[3]   =  500 trx;
        levelPrice[4]   =  1000 trx;
        levelPrice[5]   =  2000 trx;
        levelPrice[6]   =  4000 trx;
        levelPrice[7]   =  8000 trx;
        levelPrice[8]   =  16000 trx;
        levelPrice[9]   =  32000 trx;
        levelPrice[10]  =  64000 trx;
        
        blevelPrice[1]   =  2500 trx;
        blevelPrice[2]   =  5000 trx;
        blevelPrice[3]   =  10000 trx;
        blevelPrice[4]   =  20000 trx;
        blevelPrice[5]   =  50000 trx;
        blevelPrice[6]   =  100000 trx;
        blevelPrice[7]   =  200000 trx;
        blevelPrice[8]   =  500000 trx;
        blevelPrice[9]   =  1000000 trx;
        blevelPrice[10]  =  2500000 trx;
		
		cappingPrice[1]   =  0 trx;
        cappingPrice[2]   =  700 trx;
        cappingPrice[3]   =  2800 trx;
        cappingPrice[4]   =  11200 trx;
        cappingPrice[5]   =  44800 trx;
        cappingPrice[6]   =  179200 trx;
        cappingPrice[7]   =  716800 trx;
        cappingPrice[8]   =  2867200 trx;
        cappingPrice[9]   =  11468800 trx;
        cappingPrice[10]  =  458752000 trx;
        
        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: 1,
            booster_income: 0,
            total_deposits: 0,
            superfast_income: 0,
            global_deposits: 0,
            bonus:0,
            partnerCount:0,
            originalReferrer: 1,
            gainAmountCounter:10,
            investAmountCounter:1,
            referral: new address payable [](0)
        });
        userInfos[ownerWallet] = UserInfo;
        userAddressByID[lastIDCount] = ownerWallet;
         

        for(uint i = 1; i <= 10; i++) {
            vId_number[i][1]=ownerWallet;
            index[i]=1;
            currentvId[i]=1; 
            userInfos[ownerWallet].activeX5Levels[i] = 1;
            userInfos[ownerWallet].activeX3Levels[i] = 1;
            
        }
	}

    function () external payable {
        uint8 level;

        if(msg.value == levelPrice[1]) level = 1;
        else if(msg.value == levelPrice[2]) level = 2;
        else if(msg.value == levelPrice[3]) level = 3;
        else if(msg.value == levelPrice[4]) level = 4;
        else if(msg.value == levelPrice[5]) level = 5;
        else if(msg.value == levelPrice[6]) level = 6;
        else if(msg.value == levelPrice[7]) level = 7;
        else if(msg.value == levelPrice[8]) level = 8;
        else if(msg.value == levelPrice[9]) level = 9;
        else if(msg.value == levelPrice[10]) level = 10;

        else revert('Incorrect Value send');

        if(level == 1) {
            uint refId = 0;
            address referrer = bytesToAddress(msg.data);

            if(userInfos[referrer].joined) refId = userInfos[referrer].id;
            else revert('Incorrect referrer');

            regUser(refId);
        }
        else revert('Please buy first level for 200 TRX');
    }



function withdrawLostTRXFromBalance(address payable _sender) public {
        require(msg.sender == ownerWallet, "onlyOwner");
        _sender.transfer(address(this).balance);
    }
    
  function buyNewLevel(uint matrix, uint8 level) external payable {
       
        require(isUserExists(msg.sender), "user is not exists.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        
        if(matrix == 1)
        {
            require(userInfos[msg.sender].activeX5Levels[level-1] == 1, "Activate privious level first");
            require(userInfos[msg.sender].activeX5Levels[level] == 0, "already activated");
            require(level > 1 && level <= LAST_LEVEL, "invalid level");
            require(msg.value == levelPrice[level], "invalid price");
            levelRefCount[level] = levelRefCount[level].add(1);
               if(level == 5)
               {
                   userList.push(msg.sender);
               }
               
                uint256 admin_amount= (levelPrice[level]*5)/100;
	        	ownerWallet.transfer(admin_amount);
		        uint256 net_amount=levelPrice[level]-admin_amount;
		
            userInfos[msg.sender].activeX5Levels[level] = 1;
            userInfos[msg.sender].total_deposits +=levelPrice[level];
            payForLevel(level, msg.sender,matrix,net_amount);
        }
        else if(matrix == 2)
        {
            require(level > 0 && level <= LAST_LEVEL, "invalid level");
            require(msg.value == blevelPrice[level], "invalid price");
            require(userInfos[msg.sender].partnerCount >=2, "Complete 2 direct for this level");
			require(userInfos[msg.sender].activeX5Levels[level] ==1, "Buy same slot of matrix first");
            require(userInfos[msg.sender].activeX3Levels[level] ==0, "already activated");
            if(level >1)
            {
                require(userInfos[msg.sender].activeX3Levels[level-1] == 1, "Activate privious level first");
                
            }
            
            uint256 admin_amount= (blevelPrice[level]*5)/100;
	        ownerWallet.transfer(admin_amount);
		    uint256 net_amount=blevelPrice[level]-admin_amount;
		        
            levelRefGlobalCount[level] = levelRefGlobalCount[level].add(1);
            userInfos[msg.sender].activeX3Levels[level] = 1;
            userInfos[msg.sender].global_deposits +=blevelPrice[level];
            
            uint256 newIndex=index[level]+1;
                vId_number[level][newIndex]= msg.sender;
                index[level]=newIndex;
                
                address freeX33Referrer = findFreeX33Referrer(level);
                userInfos[msg.sender].x3Matrix[level].currentReferrer = freeX33Referrer;
                userInfos[msg.sender].activeX3Levels[level] = 1;
                updateX3Referrer(msg.sender, freeX33Referrer, level,net_amount);
                
                // super fast matrix Income
                uint fast_matrix=fast_matrix_member(1);
                if(level ==1)
                {
                    userFastMatrixList.push(msg.sender);
                }
       
                if(fast_matrix >0)
                {
                    uint fast_matrix_income=(net_amount*20)/100;
                    uint per_member_fast=fast_matrix_income/fast_matrix;
                    booster_income_distribution(per_member_fast,matrix);
                }
                
        }
		
        emit Upgrade(msg.sender, userAddressByID[userInfos[msg.sender].referrerID],level,matrix);
       
    }
    
    
    function regUser(uint _referrerID) public payable {
        uint originalReferrer = _referrerID;
        require(!userInfos[msg.sender].joined, 'User exist');
        require(_referrerID > 0 && _referrerID <= lastIDCount, 'Incorrect referrer Id');
        require(msg.value == levelPrice[1], 'Incorrect Value');
        require(userInfos[msg.sender].activeX5Levels[1] == 0, "already activated");
        address userAddress=msg.sender;
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        
        if(!(_referrerID > 0 && _referrerID <= lastIDCount)) _referrerID = defaultRefID;
        if(userInfos[userAddressByID[_referrerID]].referral.length >= maxDownLimit) 
        _referrerID = userInfos[findFreeReferrer(userAddressByID[_referrerID])].id;
        
        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            partnerCount:0,
            booster_income:0,
            total_deposits:0,
            superfast_income:0,
            global_deposits:0,
            bonus:0,
            referrerID: _referrerID,
            originalReferrer: originalReferrer,
            gainAmountCounter:0,
            investAmountCounter:msg.value,            
            referral: new address payable[](0)
        });

        userInfos[msg.sender] = UserInfo;
        userAddressByID[lastIDCount] = msg.sender;
        
        userInfos[msg.sender].activeX5Levels[1] = 1;
        levelRefCount[1] = levelRefCount[1].add(1);
        userInfos[msg.sender].total_deposits +=levelPrice[1]; 
        
        
		uint256 net_amount=levelPrice[1];
        
        
        uint directAmt=(net_amount*70)/100;
        userAddressByID[originalReferrer].transfer(directAmt);
        emit DirectPayout(userAddressByID[originalReferrer], msg.sender, directAmt,1,'Direct Income');
        
        userInfos[userAddressByID[_referrerID]].partnerCount = userInfos[userAddressByID[_referrerID]].partnerCount+1;

        userInfos[userAddressByID[_referrerID]].referral.push(msg.sender);

        payForLevel(1, msg.sender,1, net_amount);
        emit regLevelEv(msg.sender,lastIDCount,_referrerID, originalReferrer, userAddressByID[originalReferrer],now );
    }  

    function payForLevel(uint8 _level, address  _user, uint matrix,uint net_amount) internal {
            uint payPrice = net_amount;
            if(_level == 1)
            {
                splitForStack(_user,payPrice, _level);
            }
            else
            {
                upgrade_income(_user,_level, matrix, net_amount);
            }
    }
    
    
    function usersx5Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (userInfos[userAddress].x5Matrix[level].currentReferrer,
                userInfos[userAddress].x5Matrix[level].referrals,
                userInfos[userAddress].x5Matrix[level].blocked
                );
            }
    
    function upgrade_income(address user, uint level, uint matrix, uint net_amount) internal returns(bool)
    {
		 uint256 placement_upline = (net_amount*70)/100;
        address freeX5Referrer = findFreeX5PromoterReferrer(user,level);
        uint256	to_payout = cappingPrice[level] - userInfos[freeX5Referrer].uplineIncomeCount[level-1]; 
		
		if(freeX5Referrer == ownerWallet)
		{
			address(uint160(freeX5Referrer)).transfer(placement_upline);
			userInfos[freeX5Referrer].uplineIncomeCount[level-1] +=placement_upline;
			 emit DirectPayout(freeX5Referrer, user, placement_upline,level,'Upline Income');
		}
		else
		{
			if(placement_upline <= to_payout) 
			{
			address(uint160(freeX5Referrer)).transfer(placement_upline);
			userInfos[freeX5Referrer].uplineIncomeCount[level-1] +=placement_upline;
			 emit DirectPayout(freeX5Referrer, user, placement_upline,level,'Upline Income');
			}
			else
			{
			   address(uint160(freeX5Referrer)).transfer(to_payout);
				userInfos[freeX5Referrer].uplineIncomeCount[level-1] +=to_payout;
				emit DirectPayout(freeX5Referrer, user, to_payout,level,'Upline Income'); 
			}
		}
        
        uint sponsor = (net_amount*15)/100;
        address freeX5ReferrerS = userAddressByID[userInfos[user].originalReferrer];
        address(uint160(freeX5ReferrerS)).transfer(sponsor);
        emit DirectPayout(freeX5ReferrerS, user, sponsor,level,'Direct Upgrade Income');
        
        uint booster=booster_member(5);
       uint booster_income=(net_amount*15)/100;
        if(booster >0)
        {
            uint per_member_booster=booster_income/booster;
            booster_income_distribution(per_member_booster,matrix);
        }
        else
        {
            ownerWallet.transfer(booster_income);
        }
        
    }
    
    
  function booster_income_distribution(uint booster_income, uint matrix) private {

         string memory  income_type;
       
       if(matrix == 1)
       {
        income_type='Booster Income';
        for(uint8 i = 0; i < userList.length; i++) {
            if(userList[i] == address(0)) break;

            uint256 win = booster_income;
			if(userInfos[userList[i]].booster_income < userInfos[userList[i]].total_deposits) 
			{
				uint256	to_payout = userInfos[userList[i]].total_deposits - userInfos[userList[i]].booster_income;
								
					if(win <= to_payout) 
					{
						userInfos[userList[i]].booster_income += win;
						address(uint160(userList[i])).transfer(win);
						emit Booster(userList[i], win,matrix,income_type);
					}
					else{
						userInfos[userList[i]].booster_income += to_payout;
						address(uint160(userList[i])).transfer(to_payout);
						emit Booster(userList[i], to_payout,matrix,income_type);
					}

            
			}
        }
       }
       else
       {
           income_type='SuperFast Matrix Income';
           for(uint8 i = 0; i < userFastMatrixList.length; i++) {
            if(userFastMatrixList[i] == address(0)) break;

            uint256 win = booster_income;
			if(userInfos[userFastMatrixList[i]].superfast_income < userInfos[userFastMatrixList[i]].global_deposits) 
			{
				uint256	to_payout = userInfos[userFastMatrixList[i]].global_deposits - userInfos[userFastMatrixList[i]].superfast_income;
								
					if(win <= to_payout) 
					{
						userInfos[userFastMatrixList[i]].superfast_income += win;
						address(uint160(userFastMatrixList[i])).transfer(win);
						emit Booster(userFastMatrixList[i], win,matrix,income_type);
					}
					else{
						userInfos[userFastMatrixList[i]].superfast_income += to_payout;
						address(uint160(userFastMatrixList[i])).transfer(to_payout);
						emit Booster(userFastMatrixList[i], to_payout,matrix,income_type);
					}

            
			}
        }
       }
        
        
       
    }
    
    function splitForStack(address _user, uint payPrice, uint _level) internal returns(bool)
    {
        address payable usrAddress = userAddressByID[userInfos[_user].referrerID];
        uint i;
        uint j;
        string memory  income_type;
       
             income_type='Level Income';
        
        
        for(i=0;i<100;i++)
        {
           
           
                if(j == 10 ) break;
                if(userInfos[usrAddress].activeX5Levels[_level] > 0  || userInfos[usrAddress].id == 1 )
                {
                        if(i== 0)
                         {
                              payPrice=0 trx;
                         }
                         else if(i== 1)
                         {
                              payPrice=20 trx;
                         }
                         else if(i== 2)
                         {
                             payPrice=10 trx;
                         }
                         else if(i== 3)
                         {
                             payPrice=6 trx;
                         }
                        
                         else if(i== 4 || i== 5 || i== 6 || i== 7 || i== 8 || i== 9)
                         {
                            payPrice=4 trx;
                         }
                    
                       
                            usrAddress.transfer(payPrice);
                            userInfos[usrAddress].gainAmountCounter += payPrice;
                           
                      
						userInfos[usrAddress].bonus = userInfos[usrAddress].bonus.add(payPrice);
						
                        emit paidForLevelEv(userInfos[_user].id,_user,userInfos[usrAddress].id, usrAddress, payPrice, j,_level,now,income_type);
                    
                    j++;
                }
                else
                {
                    
                    emit lostForLevelEv(usrAddress,_user,payPrice, j,_level, now, income_type);
                }
                usrAddress = userAddressByID[userInfos[usrAddress].referrerID]; 
          
        }           
    }
    
     function updateX3Referrer(address userAddress, address referrerAddress, uint8 _level, uint net_amount) private {
                userInfos[referrerAddress].x3Matrix[_level].referrals.push(userAddress);
        
                    if (userInfos[referrerAddress].x3Matrix[_level].referrals.length <= 3) {
                      
                             if (userInfos[referrerAddress].x3Matrix[_level].referrals.length == 3) {
                                      currentvId[_level]=currentvId[_level]+1;
                                }
                            
                            
                            uint remove=(net_amount*20)/100;
                            uint exact_income=net_amount-remove;
                              
                           if (!address(uint160(referrerAddress)).send(exact_income)) {
                                           
                                 address(uint160(ownerWallet)).transfer(exact_income);
                                       
                           }
                               
                             emit NewUserPlace(userAddress, referrerAddress, 2, _level, uint8(userInfos[referrerAddress].x3Matrix[_level].referrals.length),exact_income);
                             
                            referrerAddress=userInfos[referrerAddress].x3Matrix[_level].currentReferrer;
                           
                        }
                        
                    }
    
    
    function findFreeX33Referrer(uint level) public view returns(address) {
        uint id=currentvId[level];
        return vId_number[level][id];
    }
    
    function booster_member(uint level) public view returns(uint256) {
	
		return levelRefCount[level];
	}
	
	function fast_matrix_member(uint level) public view returns(uint256) {
	
		return levelRefGlobalCount[level];
	}
    
    function findFreeX5PromoterReferrer(address userAddress, uint256 level) public view returns(address) {
      
        uint256 i =1;
       
        while (i < level)
        {
                    
            userAddress = userAddressByID[userInfos[userAddress].referrerID];
             i = i+1;
        }
        while(true)
        {
            if(userAddress != ownerWallet)
            {
                if (userInfos[userAddressByID[userInfos[userAddress].referrerID]].activeX5Levels[level] == 1 && userInfos[userAddressByID[userInfos[userAddress].referrerID]].uplineIncomeCount[level-1] < cappingPrice[level]) 
                {
					return userAddressByID[userInfos[userAddress].referrerID];
                }
            }
            else
            {
                if (userInfos[userAddressByID[userInfos[userAddress].referrerID]].activeX5Levels[level] == 1) 
                {
					return userAddressByID[userInfos[userAddress].referrerID];
                }
                
            }
            userAddress = userAddressByID[userInfos[userAddress].referrerID];
        }        
    }
    
    
    
    

    function findNextEligible(address payable orRef,uint _level) public view returns(address payable)
    {
        address payable rightAddress;
        for(uint i=0;i<100;i++)
        {
            orRef = userAddressByID[userInfos[orRef].originalReferrer];
            if(userInfos[orRef].activeX5Levels[_level] > 0)
            {
                rightAddress = orRef;
                break;
            }
        }
        if(rightAddress == address(0)) rightAddress = userAddressByID[1];
        return rightAddress;
    }


    function findFreeReferrer1(address _user) public view returns(address) {
        if(userInfos[_user].referral.length < maxDownLimit) return _user;

        address[] memory referrals = new address[](2);
        referrals[0] = userInfos[_user].referral[0];
        referrals[1] = userInfos[_user].referral[1];
        
        address found = searchForFirst(referrals);
        if(found == address(0)) found = searchForSecond(referrals);
       
        return found;
    }

    function searchForFirst(address[] memory _user) internal view returns (address)
    {
        address freeReferrer;
        for(uint i = 0; i < _user.length; i++) {
            if(userInfos[_user[i]].referral.length == 0) {
                freeReferrer = _user[i];
                break;
            }
        }
        return freeReferrer;       
    }

    function searchForSecond(address[] memory _user) internal view returns (address)
    {
        address freeReferrer;
        for(uint i = 0; i < _user.length; i++) {
            if(userInfos[_user[i]].referral.length == 1) {
                freeReferrer = _user[i];
                break;
            }
        }
        return freeReferrer;       
    }

    function findFreeReferrer(address _user) public view returns(address) {
        if(userInfos[_user].referral.length < maxDownLimit) return _user;
        address found = findFreeReferrer1(_user);
        if(found != address(0)) return found;
        address[] memory referrals = new address[](3000);
        referrals[0] = userInfos[_user].referral[0];
        referrals[1] = userInfos[_user].referral[1];
       

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 3000; i++) {
            if(userInfos[referrals[i]].referral.length == maxDownLimit) {
                if(i < 3000) {
                    referrals[(i+1)*2] = userInfos[referrals[i]].referral[0];
                    referrals[(i+1)*2+1] = userInfos[referrals[i]].referral[1];
                    referrals[(i+1)*2+2] = userInfos[referrals[i]].referral[2];
                    referrals[(i+1)*2+3] = userInfos[referrals[i]].referral[3];
                    referrals[(i+1)*2+4] = userInfos[referrals[i]].referral[4];
                    referrals[(i+1)*2+5] = userInfos[referrals[i]].referral[5];
                    referrals[(i+1)*2+6] = userInfos[referrals[i]].referral[6];
                    referrals[(i+1)*2+7] = userInfos[referrals[i]].referral[7];
                    referrals[(i+1)*2+8] = userInfos[referrals[i]].referral[8];
                    referrals[(i+1)*2+9] = userInfos[referrals[i]].referral[9];
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }

        require(!noFreeReferrer, 'No Free Referrer');

        return freeReferrer;
    }

	function getUserUplineIncome(address userAddress) public view returns(uint256[] memory) {
		uint256[] memory levelRefCountss = new uint256[](10);
		for(uint8 j=0; j<=9; j++)
		{
		  levelRefCountss[j]  =userInfos[userAddress].uplineIncomeCount[j];
		}
		return (levelRefCountss);
	}
	
    function viewUserReferral(address _user) public view returns(address payable[] memory) {
        return userInfos[_user].referral;
    }
    
    function viewUseractiveX3Levels(address _user, uint _level) public view returns(uint) {
        return userInfos[_user].activeX3Levels[_level];
    }
    
     function viewUseractiveX5Levels(address _user, uint _level) public view returns(uint) {
        return userInfos[_user].activeX5Levels[_level];
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function isUserExists(address user) public view returns (bool) {
        return userInfos[user].joined;
    }
    
    function isContract(address addr) internal view returns (bool)
	 {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    
     function active_level(address userAddress) public payable
     {
          require(msg.sender == ownerWallet, "onlyOwner");
            for (uint8 i = 1; i <= 10; i++)
			{
				userInfos[userAddress].activeX5Levels[i+1] = 1;
				if(i == 5)
				   {
					   userList.push(userAddress);
				   }
			} 
        }
		
		function active_matrixlevel(address userAddress) public payable
     {
          require(msg.sender == ownerWallet, "onlyOwner");
            for (uint8 i = 1; i <= 10; i++)
			{
				if(i ==1)
				{
					userFastMatrixList.push(userAddress);
				}
				userInfos[userAddress].activeX3Levels[i] = 1;
			} 
        }
   
}