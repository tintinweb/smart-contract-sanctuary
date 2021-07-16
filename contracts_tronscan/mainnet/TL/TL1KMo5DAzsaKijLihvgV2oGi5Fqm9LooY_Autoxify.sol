//SourceUnit: autoxifymainnettest (8).sol

pragma solidity 0.4.25;



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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


 contract TRC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Autoxify  {
    
    using SafeMath for uint256;
    TRC20Interface Tokenaddress;
    
    uint256 public UpgradeTokenDistributed;
    uint256 public RegistrationTokenDistributed;
   
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint256 => bool) activeX3Levels;
        mapping(uint256 => bool) activeX6Levels;
        
        mapping(uint256 => X3) x3Matrix;
        mapping(uint256 => X6) x6Matrix;
        uint256 noofreferralActivated;
        uint lasttimereferralActivated;
        bool paidbonus;
        bool oldmember;
        uint256 oldactiveslots;
    }
            
    struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct X6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;
        address closedPart;
    }
    
    
    struct currentPayment
    {
        uint userid;
        address currentPaymentAddress;
        uint level;
        uint256 noofpayments;
        uint256 totalpayment;
        bool activatorflag;
        bool upgradeflag;
        bool israplaceflag;
    }

    uint256 public idd =1;
    
    uint8 public currentStartingLevel = 1;
    uint8 public constant LAST_LEVEL = 20;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public oldIdMapping;
    uint256 public oldUseridMapping=1;
    uint256 public paymentbonusid=1;
    
    mapping(uint => mapping(uint=>currentPayment)) public currentpayment;

    uint public lastUserId = 22910;
    address public owner;
    address public oldcontractaddress;
    
    mapping(uint256 => uint) public levelPricex3;
    mapping(uint256 => uint) public levelPricex4;
    mapping(uint8 => uint) public RewardToken;

    mapping(uint256 => uint) public Currentuserids;
    
    
    
    mapping(uint256 => uint) public CurrentPaymentid;


    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId,uint activaterefferaltimestamp);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint256 level,bool reactivatorflag);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint256 level,bool reactivatorflag);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint256 level, uint256 place,bool reactivatorflag,bool recflag,bool israplace);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint256 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint256 level);
    
    event RewardBonus(address users,address refferal);
    
    constructor(address ownerAddress,address oldaddress,TRC20Interface tokenaddress) public {
        
    Tokenaddress = tokenaddress;
          levelPricex3[1] = 50 trx;
       
        for (uint256 ii = 2; ii <= LAST_LEVEL; ii++) {
            levelPricex3[ii] = levelPricex3[ii.sub(1)].mul(2);
        }
        
         levelPricex4[1] = 80 trx;
       
        for (uint256 jj = 2; jj <= LAST_LEVEL; jj++) {
            levelPricex4[jj] = levelPricex4[jj.sub(1)].mul(2);
        }
         
         
         RewardToken[1] = 0;
         RewardToken[2]= 100;
         RewardToken[3]= 200;
         RewardToken[4]= 300;
         RewardToken[5]= 400;
         RewardToken[6]= 500;
         RewardToken[7]= 750;
         RewardToken[8]= 1000;
         RewardToken[9]= 1500;
         RewardToken[10]= 2000;
         RewardToken[11]= 5000;
         RewardToken[12]= 7500;
         RewardToken[13]= 10000;
         RewardToken[14]= 15000;
         RewardToken[15]= 20000;
         RewardToken[16]= 30000;
         RewardToken[17]= 40000;
         RewardToken[18]= 50000;
         RewardToken[19]= 100000;
         RewardToken[20]= 200000;
         
        owner = ownerAddress;
        oldcontractaddress=oldaddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            noofreferralActivated : 0,
            lasttimereferralActivated : now.add(3 days),
            paidbonus:false,
            oldmember:true,
            oldactiveslots:1
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        Currentuserids[1]=Currentuserids[1].add(1);
        users[ownerAddress].activeX3Levels[1] = true;
            
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
           
            users[ownerAddress].activeX6Levels[i] = true;
            CurrentPaymentid[i] = 1;
         
        }
        
         currentPayment memory currentpay = currentPayment({
             
             userid : Currentuserids[1],
            currentPaymentAddress: owner,
         level: 1,
         noofpayments : 0,
         totalpayment : 0,
         activatorflag:false,
         upgradeflag:true,
         israplaceflag:false
        });
        currentpayment[1][Currentuserids[1]] = currentpay;
        
        
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 2, "invalid matrix");
        require(msg.value == levelPricex4[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

       
            require(users[msg.sender].activeX6Levels[level-1], "buy previous level first");
            require(!users[msg.sender].activeX6Levels[level], "level already activated"); 

            if (users[msg.sender].x6Matrix[level-1].blocked) {
                users[msg.sender].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(msg.sender, level);
            
            users[msg.sender].activeX6Levels[level] = true;
            updateX6Referrer(msg.sender, freeX6Referrer, level);
            
            safedefitokenTransferUpgrade(msg.sender,level);
            emit Upgrade(msg.sender, freeX6Referrer, 2, level,false);
        
    }    
    
    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
          uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

        
        if( migrateOldData(msg.value)){
            
            users[userAddress].lasttimereferralActivated = now.add(3 days);
            users[userAddress].oldmember=true;
            emit Registration(userAddress, users[userAddress].referrer, users[userAddress].id, users[users[userAddress].referrer].id,now.add(3 days));
        }
        else{
        require(isUserExists(referrerAddress), "referrer not exists");
        require(msg.value == 280 trx, "invalid registration cost");
        
         User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            noofreferralActivated : 0,
            lasttimereferralActivated : now.add(3 days),
            paidbonus:false,
            oldmember:false,
            oldactiveslots:1
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
       
        
        lastUserId=lastUserId.add(1);
        
        users[referrerAddress].partnersCount=users[referrerAddress].partnersCount.add(1);
           users[userAddress].activeX6Levels[1] = true;

        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1);
        
       
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id,now.add(3 days));

        }
      
         safedefitokenRegistration(msg.sender);
       
         users[userAddress].activeX3Levels[1] = true; 
     
        address freeX3Referrer = msg.sender;
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        UpdateX3(1,userAddress,false,true,false);

       
        
        
        
    }
    
    
    function UpdateX3(uint256 level,address caddress,bool activatorflag,bool upgradeflag,bool israplaceflag) private
    {
        Currentuserids[level]=Currentuserids[level].add(1);
        
       
        currentPayment memory currentpay = currentPayment({
             
             userid : users[caddress].id,
            currentPaymentAddress: caddress,
         level: level,
         noofpayments : 0,
         totalpayment : 0,
         activatorflag : activatorflag,
         upgradeflag:upgradeflag,
         israplaceflag:israplaceflag
        });
        
        currentpayment[level][Currentuserids[level]] = currentpay;
        if(Currentuserids[level]==CurrentPaymentid[level]){
           if (!address(uint160(currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress)).send(levelPricex3[level].div(2))) {
                            
                     } 
                   
        }else{
        currentpayment[level][CurrentPaymentid[level]].noofpayments=currentpayment[level][CurrentPaymentid[level]].noofpayments.add(1);
         currentPayment memory ActivePaymentUserDetails =  currentpayment[level][CurrentPaymentid[level]];
        emit NewUserPlace(caddress, ActivePaymentUserDetails.currentPaymentAddress, 1, level,ActivePaymentUserDetails.noofpayments,activatorflag,ActivePaymentUserDetails.activatorflag,israplaceflag);
        }
            
            if(users[ActivePaymentUserDetails.currentPaymentAddress].activeX3Levels[level.add(1)] == true || level==LAST_LEVEL)
            {
                if(currentpayment[level][CurrentPaymentid[level]].noofpayments == 2 && currentpayment[level][CurrentPaymentid[level]].upgradeflag && level!=LAST_LEVEL)
                {
                    currentPayment memory ActivePayment=currentpayment[level][CurrentPaymentid[level]];
                    emit Upgrade(ActivePayment.currentPaymentAddress, currentpayment[level.add(1)][CurrentPaymentid[level.add(1)]].currentPaymentAddress, 1, level.add(1),ActivePayment.activatorflag);
                    users[ActivePaymentUserDetails.currentPaymentAddress].activeX3Levels[level.add(1)]=true;
                    UpdateX3(level.add(1),currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress,currentpayment[level][CurrentPaymentid[level]].activatorflag,true,false);
                }
                 if(currentpayment[level][CurrentPaymentid[level]].noofpayments == 3)
                {
                    
                    currentpayment[level][CurrentPaymentid[level]].noofpayments = 0;
                    CurrentPaymentid[level]=CurrentPaymentid[level].add(1);
                    emit Reinvest(ActivePaymentUserDetails.currentPaymentAddress,currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress,currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress,1,level,ActivePaymentUserDetails.activatorflag);
                    
                    
                   UpdateX3(level,ActivePaymentUserDetails.currentPaymentAddress,ActivePaymentUserDetails.activatorflag,false,false);
                }
                 else{ 
                     if(level==4 && currentpayment[level][CurrentPaymentid[level]].noofpayments == 1 &&
                     !users[currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress].paidbonus && 
                     !users[currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress].oldmember &&
                     currentpayment[level][CurrentPaymentid[level]].upgradeflag==false){
                         if(oldIdMapping[paymentbonusid]!=address(0)){
                             if (address(uint160(oldIdMapping[paymentbonusid])).send(levelPricex3[level])) {
                                 users[currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress].paidbonus=true;
                                emit RewardBonus(oldIdMapping[paymentbonusid],currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress);
                                paymentbonusid=paymentbonusid.add(1);
                             } 
                         }
                          else if (!address(uint160(currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress)).send(levelPricex3[level])) {
                            
                            } 
                     }
                     else if(currentpayment[level][CurrentPaymentid[level]].upgradeflag==false){
                         
                          if (!address(uint160(currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress)).send(levelPricex3[level])) {
                                
                         }
                     }
                 }
            }
            else
            {
            if(currentpayment[level][CurrentPaymentid[level]].noofpayments == 2)
            {
                emit Upgrade(currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress, caddress, 1, level.add(1),false);
                users[ActivePaymentUserDetails.currentPaymentAddress].activeX3Levels[level.add(1)]=true;
                UpdateX3(level.add(1),currentpayment[level][CurrentPaymentid[level]].currentPaymentAddress,currentpayment[level][CurrentPaymentid[level]].activatorflag,true,false);
            }
            else
            {
                
            }
            }
           
    }
    
  
    function updateX6Referrer(address userAddress, address referrerAddress, uint256 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length),false,false,false);
            
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].x6Matrix[level].currentReferrer;            
            users[ref].x6Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].x6Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5,false,false,false);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6,false,false,false);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3,false,false,false);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4,false,false,false);
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5,false,false,false);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6,false,false,false);
                }
            }

            return updateX6ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].x6Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].x6Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].x6Matrix[level].closedPart)) {

                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].closedPart) {
                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateX6(userAddress, referrerAddress, level, false);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateX6(userAddress, referrerAddress, level, false);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length) {
            updateX6(userAddress, referrerAddress, level, false);
        } else {
            updateX6(userAddress, referrerAddress, level, true);
        }
        
        updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateX6(address userAddress, address referrerAddress, uint256 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length),false,false,false);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint256(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length).add(2),false,false,false);
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length),false,false,false);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint256(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length).add(4),false,false,false);
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint256 level) private {
        
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            return sendETHDividends(referrerAddress, userAddress, 2, level);
        }
        
        address[] memory x6 = users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].firstLevelReferrals;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].x6Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeX6Levels[level.add(1)] && level != LAST_LEVEL) {
            users[referrerAddress].x6Matrix[level].blocked = true;
        }

        users[referrerAddress].x6Matrix[level].reinvestCount=users[referrerAddress].x6Matrix[level].reinvestCount.add(1);
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level,false);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level,false);
            sendETHDividends(owner, userAddress, 2, level);
        }
    }
    
    function findFreeX3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeX6Referrer(address userAddress, uint256 level) public view returns(address) {
        while (true) {
            if(users[userAddress].referrer==address(0) || !isUserExists(users[userAddress].referrer)){
                return owner;
            }
            if (users[users[userAddress].referrer].activeX6Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }

    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }

    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked);
    }

    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].firstLevelReferrals,
                users[userAddress].x6Matrix[level].secondLevelReferrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].closedPart);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint256 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].x3Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].x6Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x6Matrix[level].currentReferrer;
                } else {
                    if(receiver==address(0) || !isUserExists(receiver)){
                        return (owner,isExtraDividends);
                    }
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint256 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

        if (!address(uint160(receiver)).send(levelPricex4[level])) {
            if(address(uint160(owner)).send(address(this).balance))
            return;
        }
        
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
    
    
     function ReferralActivator() public
     {
           address currentuser = msg.sender;
       
           uint256 noofactive = users[currentuser].noofreferralActivated;
       uint noofdays = users[currentuser].lasttimereferralActivated;
       
         require(noofactive < 3,"You have passed limit");
     require(now > noofdays,"You can activate after 3 days");
       users[currentuser].noofreferralActivated=users[currentuser].noofreferralActivated.add(1);
       if(users[currentuser].noofreferralActivated==3){
           safedefitokenTransferRA(msg.sender);
           for(uint8 k=1;k<=users[msg.sender].oldactiveslots;k++){
               safedefitokenTransferUpgrade(msg.sender,k);
           }
       }
       UpdateX3(1,currentuser,true,true,true);
    }
    
     function safedefitokenTransferRA(address to) internal {
         uint256 _amount=convertToToken(200);
        uint256 defitokentestBal = BalanceOfTokenInContract();
        if(defitokentestBal >= _amount)
       {
            if(TRC20Interface(Tokenaddress).transfer(to, _amount))
            {
                
            }
       }

    }
    
    function safedefitokenTransferUpgrade(address to, uint8 level) internal {
        uint256 defitokentestBal = BalanceOfTokenInContract();
        if(defitokentestBal >= convertToToken(RewardToken[level]) && level>1){
        if(convertToToken(101000000) > UpgradeTokenDistributed){
            if(TRC20Interface(Tokenaddress).transfer(to, convertToToken(RewardToken[level]))){
        UpgradeTokenDistributed = UpgradeTokenDistributed.add(convertToToken(RewardToken[level]));
            }
        }
        }
      
    }
    
    function BalanceOfTokenInContract()public view returns (uint256){
        return TRC20Interface(Tokenaddress).balanceOf(address(this));
    }

 function safedefitokenRegistration(address to) internal {
     uint _amount = convertToToken(100);
     uint _amount1 = convertToToken(30);
        uint256 defitokentestBal = BalanceOfTokenInContract();
        if(defitokentestBal >= _amount.add(_amount1)){
            if(lastUserId <= 300000)
            {
                if(TRC20Interface(Tokenaddress).transfer(to,_amount)) {
                RegistrationTokenDistributed = RegistrationTokenDistributed.add(_amount);
                }
                if(TRC20Interface(Tokenaddress).transfer(users[msg.sender].referrer,_amount1))
                {
                    
                }
                  
            }
        }
    }
    
    function convertToToken(uint amount) public pure returns(uint256){
        return amount.mul(1000000000000000000);
    }
    

    function migrateOldData(uint amount) private returns(bool){
    address uaddress = msg.sender;
    (users[uaddress].id,users[uaddress].referrer,users[uaddress].partnersCount) = getuserstruct(uaddress);
      if(users[uaddress].id>0){
          require(amount == 200 trx, "invalid registration cost");
        idToAddress[idd] = uaddress;
        oldIdMapping[oldUseridMapping]=msg.sender;
        oldUseridMapping=oldUseridMapping.add(1);
        users[uaddress].noofreferralActivated=0;
        migrateOldDatax6(uaddress,users[uaddress].referrer);
        return true;
      }
      else
      {
          return false;
      }
        
    }
    
    
    function migrateOldDatax6( address uaddress , address referrer) private
    {
        for(uint8 k=1;k<=20;k++)
        {
        bool ischeck = usersActiveX6Levelsold(uaddress,k);    
        
        if(ischeck)
        {
            users[uaddress].activeX6Levels[k]= ischeck;
                 users[uaddress].x6Matrix[k].currentReferrer=referrer;
                 
        }
        else
        {
            break;
        }
        }
        uint256 level=k;
        users[uaddress].oldactiveslots=level.sub(1);
        emit Upgrade(uaddress,referrer,2,level.sub(1),true);
        }
        
     
    
    
      function getuserstruct(address useraddress) private view returns(uint,address,uint)
    {
       return OldAutoxify(oldcontractaddress).users(useraddress);
    }

    function usersActiveX6Levelsold(address userAddress, uint8 level) private view returns(bool)
    {
        return OldAutoxify(oldcontractaddress).usersActiveX6Levels(userAddress,level);
    }

}




interface OldAutoxify
{
    function users(address) external view returns(uint,address,uint);
    function usersActiveX6Levels(address,uint8)external view returns(bool);
    
}