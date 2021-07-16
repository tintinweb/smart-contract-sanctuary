//SourceUnit: unixtree.sol

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
contract ownerShip    // Auction Contract Owner and OwherShip change
{
    //Global storage declaration
    address payable public ownerWallet;
    address payable public newOwner;
    //Event defined for ownership transfered
    event OwnershipTransferredEv(address indexed previousOwner, address indexed newOwner);

    //Sets owner only on first run
    constructor() public 
    {
        //Set contract owner
        ownerWallet = msg.sender;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner 
    {
        newOwner = _newOwner;
    }

    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public 
    {
        require(msg.sender == newOwner);
        emit OwnershipTransferredEv(ownerWallet, newOwner);
        ownerWallet = newOwner;
        newOwner = address(0);
    }

    //This will restrict function only for owner where attached
    modifier onlyOwner() 
    {
        require(msg.sender == ownerWallet);
        _;
    }

}


contract UNIXTREE is ownerShip {
    
    using SafeMath for uint256;

    uint public defaultRefID = 1;   //this ref ID will be used if user joins without any ref ID
    uint maxDownLimit = 3;

    uint public lastIDCount = 0;
    mapping (uint => uint[]) public testArray;
    
    uint256 constant public PROJECT_FEE = 10 trx;
	uint256 constant public ADMIN_FEE = 10;
	uint256 constant public PERCENTS_DIVIDER = 100;
    address payable public adminAddress;



    struct userInfo {
        bool joined;
        uint id;
        uint referrerID;
        uint partnerCount;
        uint originalReferrer;
        uint gainAmountCounter;
        uint investAmountCounter;
        address payable[] referral;
        mapping(uint => uint) activeX3Levels;
        mapping(uint => uint) activeX6Levels;
        mapping(uint => mapping(uint => uint)) levelRefCount;
       
        uint256 bonus;
        uint256 autopool;
        mapping(uint => X3) x6Matrix;
    }

    struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
        uint poolmember;
        uint holdAmount;
    }
    
    
    mapping(uint => uint) public priceOfLevel;

    mapping (address => userInfo) public userInfos;
    mapping (uint => address payable ) public userAddressByID;
    mapping(uint => uint) public levelPrice;
    mapping(uint => uint) public blevelPrice;
    mapping(uint => mapping(uint => address)) vId_number;
    
    mapping(uint => uint) public currentvId;
    mapping(uint => uint) public index;

    event regLevelEv(address indexed useraddress, uint userid,uint placeid,uint refferalid, address indexed refferaladdress, uint _time);
    event LevelByEv(uint userid,address indexed useraddress, uint level,uint _matrix,uint amount, uint time);    
    event paidForLevelEv(uint fromUserId, address fromAddress, uint toUserId,address toAddress, uint amount,uint level,uint matrix, uint packageAmount, uint time );
    event lostForLevelEv(address indexed _user, address indexed _referral, uint _matrix,uint _level, uint _time);
    event reInvestEv(address user,uint userid,uint amount, uint timeNow, uint _matrix, uint level);
    event FeePayed(address indexed user, uint256 totalAmount);
    event Upgrade(address indexed user, address indexed referrer, uint _matrix, uint8 _level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    
    constructor() public {
	
	
		priceOfLevel[1] = 150000000 ;
        priceOfLevel[2] = 300000000 ;
        
        levelPrice[0] = 45 trx;
        levelPrice[1] = 27 trx;
        levelPrice[2] = 27 trx;
        levelPrice[3] = 36 trx;
        
        blevelPrice[0] = 90 trx;
        blevelPrice[1] = 54 trx;
        blevelPrice[2] = 54 trx;
        blevelPrice[3] = 72 trx;
        
        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: 1,
              partnerCount:0,
            originalReferrer: 1,
            gainAmountCounter:10,
            bonus:0,
            autopool:0,
            investAmountCounter:1,
            referral: new address payable [](0)
        });
        userInfos[ownerWallet] = UserInfo;
        userAddressByID[lastIDCount] = ownerWallet;

        for(uint i = 1; i <= 2; i++) {
            vId_number[i][1]=ownerWallet;
            index[i]=1;
            currentvId[i]=1; 
            userInfos[ownerWallet].activeX3Levels[i] = 1;
            userInfos[ownerWallet].activeX6Levels[i] = 1;
        }
	}


   

    function () external payable {
        uint8 level;
        uint matrix;

        if(msg.value == priceOfLevel[1]) level = 1;
        else if(msg.value == priceOfLevel[2]) level = 2;
        

        else revert('Incorrect Value send');

        if(userInfos[msg.sender].joined) buyNewLevel(level,matrix);
        else if(level == 1) {
            uint refId = 0;
            address referrer = bytesToAddress(msg.data);

            if(userInfos[referrer].joined) refId = userInfos[referrer].id;
            else revert('Incorrect referrer');

            regUser(refId);
        }
        else revert('Please buy first level for 1000 TRX');
    }



function withdrawLostTRXFromBalance(address payable _sender) public {
        require(msg.sender == ownerWallet, "onlyOwner");
        _sender.transfer(address(this).balance);
    }
    
    
    
    
    function regUser(uint _referrerID) public payable {
        uint originalReferrer = _referrerID;
        require(!userInfos[msg.sender].joined, 'User exist');
        require(_referrerID > 0 && _referrerID <= lastIDCount, 'Incorrect referrer Id');
        require(msg.value == priceOfLevel[1].add(PROJECT_FEE), 'Incorrect Value');
        if(!(_referrerID > 0 && _referrerID <= lastIDCount)) _referrerID = defaultRefID;
        if(userInfos[userAddressByID[_referrerID]].referral.length >= maxDownLimit) _referrerID = userInfos[findFreeReferrer(userAddressByID[_referrerID])].id;
        
        ownerWallet.transfer(10 trx);
		ownerWallet.transfer(priceOfLevel[1].mul(ADMIN_FEE).div(PERCENTS_DIVIDER));
		emit FeePayed(msg.sender, priceOfLevel[1].mul(ADMIN_FEE).div(PERCENTS_DIVIDER));

        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            partnerCount:0,
            bonus:0,
            autopool:0,
            referrerID: _referrerID,
            originalReferrer: originalReferrer,
            gainAmountCounter:0,
            investAmountCounter:msg.value,            
            referral: new address payable[](0)
        });

        userInfos[msg.sender] = UserInfo;
        userAddressByID[lastIDCount] = msg.sender;

        userInfos[msg.sender].activeX3Levels[1] = 1;
        
        userInfos[userAddressByID[_referrerID]].partnerCount = userInfos[userAddressByID[_referrerID]].partnerCount+1;

        userInfos[userAddressByID[_referrerID]].referral.push(msg.sender);

        payForLevel(1, msg.sender,1);

        emit regLevelEv(msg.sender,lastIDCount,_referrerID, originalReferrer, userAddressByID[originalReferrer],now );
    }

    function buyNewLevel(uint8 _level, uint _matrix) public payable {
        require(userInfos[msg.sender].joined, 'User not exist'); 
        require(_level == 1 || _level == 2, 'Incorrect level');
        require(_matrix == 1 || _matrix == 2, 'Incorrect matrix');
        
       
            require(msg.value == priceOfLevel[_level].add(PROJECT_FEE), 'Incorrect Value');
            
           
	
            
            if(_matrix ==1)
            {
               if(_level >1)
                {
                    require(userInfos[msg.sender].activeX3Levels[1] ==1, "buy previous level first");
                         
                         
                         userInfos[msg.sender].activeX3Levels[_level] = 1;
                }
            }
            else
            {
                if(_level >1)
                {
                    require(userInfos[msg.sender].activeX6Levels[_level-1]==1, "buy previous level first"); 
                       
                }                     
                       
                       userInfos[msg.sender].activeX6Levels[_level] = 1;
               
                
            }

            

          
        
        userInfos[msg.sender].investAmountCounter += msg.value;
        payForLevel(_level, msg.sender,_matrix);
        emit LevelByEv(userInfos[msg.sender].id, msg.sender, _level,_matrix,priceOfLevel[_level], now);
    }
    

    function payForLevel(uint8 _level, address  _user, uint _matrix) internal {

        uint payPrice = priceOfLevel[_level];
        address payable orRef = userAddressByID[userInfos[_user].originalReferrer];
          
          if(_matrix == 1)
          {
            splitForStack(_user,payPrice, _level, _matrix);
          }
          else
          {
              uint256 newIndex=index[_level]+1;
                vId_number[_level][newIndex]= _user;
                index[_level]=newIndex;
                
                address freeX3Referrer = findFreeX3Referrer(_level);
                userInfos[_user].x6Matrix[_level].currentReferrer = freeX3Referrer;
                userInfos[_user].activeX6Levels[_level] = 1;
                updateX3Referrer(_user, freeX3Referrer, _level);
                emit Upgrade(_user, freeX3Referrer, _matrix, _level);
                
          }
    }
    
      function updateX3Referrer(address userAddress, address referrerAddress, uint8 _level) private {
                userInfos[referrerAddress].x6Matrix[_level].referrals.push(userAddress);
                
                
        
                    if (userInfos[referrerAddress].x6Matrix[_level].referrals.length <= 3) {
                        for(uint i=0; i <=3; i++)
                        {
                            
                             if (userInfos[referrerAddress].x6Matrix[_level].referrals.length == 3) {
                                    
                                      currentvId[_level]=currentvId[_level]+1; 
                                      //close matrix
                                    userInfos[referrerAddress].x6Matrix[_level].referrals = new address[](0);
                                }
                                
                                 
                           
                            userInfos[referrerAddress].x6Matrix[_level].poolmember++;
                            
                            emit NewUserPlace(userAddress, referrerAddress, 2, _level, uint8(userInfos[referrerAddress].x6Matrix[_level].referrals.length));
                            
                            if(userInfos[referrerAddress].x6Matrix[_level].poolmember >116)
                            {
                                userInfos[referrerAddress].x6Matrix[_level].holdAmount=userInfos[referrerAddress].x6Matrix[_level].holdAmount+levelPrice[i];
                                
                            }
                            else
                            {
                               if(_level == 1) 
                               {
                                   if (!address(uint160(referrerAddress)).send(levelPrice[i])) {
                                       
                                       
                                           userInfos[ownerWallet].autopool = userInfos[ownerWallet].autopool.add(levelPrice[i]);
                                            address(uint160(ownerWallet)).send(levelPrice[i]);
                                       
                                   }
                               }
                               else
                               {
                                   if (!address(uint160(referrerAddress)).send(blevelPrice[i])) {
                                       
                                       
                                           userInfos[ownerWallet].autopool = userInfos[ownerWallet].autopool.add(blevelPrice[i]);
                                            address(uint160(ownerWallet)).send(blevelPrice[i]);
                                       
                                   }
                               }
                            }
						if(userInfos[referrerAddress].x6Matrix[_level].poolmember >= 120)
                            {
                                 emit NewUserPlace(userAddress, referrerAddress, 1, _level, 3);
                    
                
                                        //create new one by recursion
                                        if (referrerAddress != ownerWallet) {
                                            //check referrer active level
                                               
                                                
                                                address freeReferrerAddress = userInfos[referrerAddress].x6Matrix[_level].currentReferrer;
                                                
                                                    //userInfos[referrerAddress].x6Matrix[_level].currentReferrer = freeReferrerAddress;
                                                    userInfos[referrerAddress].x6Matrix[_level].holdAmount=0;
                                                    userInfos[referrerAddress].x6Matrix[_level].poolmember=0;
                                                    uint256 newIndex=index[_level]+1;
                                        			   vId_number[_level][newIndex]=referrerAddress;
                                        			   index[_level]=newIndex;   
                                                    
                                                    userInfos[referrerAddress].x6Matrix[_level].reinvestCount++;
                                                    emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, _level);
                                                    
                                                    if(address(userInfos[referrerAddress].x6Matrix[_level].currentReferrer) != address(0))
                                                    
                                                        
                                                    updateX3Referrer(referrerAddress, freeReferrerAddress, _level);
                                                    
                                            
                                    
                                            
                                        } else {
                                            userInfos[ownerWallet].x6Matrix[_level].poolmember=0;
                                            userInfos[ownerWallet].x6Matrix[_level].holdAmount=0;
                                            sendETHDividends(ownerWallet, userAddress, 1, _level);
                                            userInfos[ownerWallet].x6Matrix[_level].reinvestCount++;
                                             emit Reinvest(ownerWallet, address(0), userAddress, 1, _level);
                                        }
                            }
               
                            
                              
                            referrerAddress=userInfos[referrerAddress].x6Matrix[_level].currentReferrer;
                            
                            if(address(referrerAddress)==address(0))
                              i=3;
                           
                        }
                        
                    }
                    
                   
                
               
               
        
               
            
        
    }
    
    
    function usersx6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool,uint256,uint256,uint256) {
        return (userInfos[userAddress].x6Matrix[level].currentReferrer,
                userInfos[userAddress].x6Matrix[level].referrals,
                userInfos[userAddress].x6Matrix[level].blocked,
                userInfos[userAddress].x6Matrix[level].reinvestCount,
                userInfos[userAddress].x6Matrix[level].poolmember,
                userInfos[userAddress].x6Matrix[level].holdAmount
                );
    }
    
    
    function findFreeX3Referrer(uint level) public view returns(address) {
        uint id=currentvId[level];
            return vId_number[level][id];
    }
    
    
   function updateFreeX3Referrer(uint level) private
    {
        
       while (true) {
           uint256 id=currentvId[level];
        if (userInfos[vId_number[level][id]].x6Matrix[level].reinvestCount==0) {
            return ;//
        }
        else
        {
          currentvId[level]=currentvId[level]+1;  
        }
       }
    }
    
    function findFreeX3Referrer2(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (userInfos[userInfos[userAddress].x6Matrix[level].currentReferrer].activeX6Levels[level] == 1) {
                return userInfos[userAddress].x6Matrix[level].currentReferrer;
            }
            
            userAddress = userInfos[userAddress].x6Matrix[level].currentReferrer;
        }
    }

  function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 2) {
            while (true) {
                if (userInfos[receiver].x6Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = userInfos[receiver].x6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } 
        
    }
    
function sendETHDividends(address userAddress, address _from, uint8 _matrix, uint8 _level) public {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, _matrix, _level);
        
        
        if(_level == 1)
        {
            if (!address(uint160(receiver)).send(levelPrice[_level])) {
                address(uint160(ownerWallet)).send(address(this).balance);
                return;
            }
        }
        else if(_level ==2)
        {
            if (!address(uint160(receiver)).send(blevelPrice[_level])) {
                address(uint160(ownerWallet)).send(address(this).balance);
                return;
            }
        }
        
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, _matrix, _level);
        }
    }
    
    function splitForStack(address _user, uint payPrice, uint _level, uint _matrix) internal returns(bool)
    {
        address payable usrAddress = userAddressByID[userInfos[_user].referrerID];
        uint i;
        uint j;
       
        for(i=0;i<100;i++)
        {
           
           
                if(j == 10 ) break;
                if(userInfos[usrAddress].activeX3Levels[_level] > 0  || userInfos[usrAddress].id == 1 )
                {
                    
                    if(j ==0 && _level==1)
                    {
                        payPrice=45 trx;
                    }
                    else if(j ==1 && _level==1)
                    {
                        payPrice=27 trx;
                    }
                    else if(j ==2 && _level==1)
                    {
                        payPrice=18 trx;
                    }
                    else if(j ==3 && _level==1)
                    {
                        payPrice=9 trx;
                    }
                    else if(j ==4 && _level==1)
                    {
                        payPrice=9 trx;
                    }
                    else if(j ==5 && _level==1)
                    {
                        payPrice=4.5 trx;
                    }
                    else if(j ==6 && _level==1)
                    {
                        payPrice=4.5 trx;
                    }
                    else if(j ==7 && _level==1)
                    {
                        payPrice=4.5 trx;
                    }
                    else if(j ==8 && _level==1)
                    {
                        payPrice=4.5 trx;
                    }
                    else if(j ==9 && _level==1)
                    {
                        payPrice=9 trx;
                    }
                    
                    
                    else if(j ==0 && _level==2)
                    {
                        payPrice=100 trx;
                    }
                    else if(j ==1 && _level==2)
                    {
                        payPrice=60 trx;
                    }
                    else if(j ==2 && _level==2)
                    {
                        payPrice=40 trx;
                    }
                    else if(j ==3 && _level==2)
                    {
                        payPrice=40 trx;
                    }
                    else if(j ==4 && _level==2)
                    {
                        payPrice=10 trx;
                    }
                    else if(j ==5 && _level==2)
                    {
                        payPrice=10 trx;
                    }
                    else if(j ==6 && _level==2)
                    {
                        payPrice=10 trx;
                    }
                    else if(j ==7 && _level==2)
                    {
                        payPrice=10 trx;
                    }
                    else if(j ==8 && _level==2)
                    {
                        payPrice=10 trx;
                    }
                    else if(j ==9 && _level==2)
                    {
                        payPrice=20 trx;
                    }
                   
                  
                    
                    
                    if(userInfos[usrAddress].gainAmountCounter < userInfos[usrAddress].investAmountCounter * 10 || _level == 2)
                    {
                       
                       
                          usrAddress.transfer(payPrice);
                            userInfos[usrAddress].gainAmountCounter += payPrice;
                           
                       //userInfos[usrAddress].levelRefCount[_level][j] = userInfos[usrAddress].levelRefCount[_level][j] +1;
						userInfos[usrAddress].bonus = userInfos[usrAddress].bonus.add(payPrice);
						
                        emit paidForLevelEv(userInfos[_user].id,_user,userInfos[usrAddress].id, usrAddress, payPrice, j,_matrix, priceOfLevel[_level], now);
                    }
                    else
                    {
                        
                         
                        userAddressByID[1].transfer(payPrice);
                     
                        //userInfos[userAddressByID[1]].levelRefCount[_level][j] = userInfos[userAddressByID[1]].levelRefCount[_level][j] +1;
						userInfos[userAddressByID[1]].bonus = userInfos[userAddressByID[1]].bonus.add(payPrice);
						
                        
                          
                        emit paidForLevelEv(userInfos[_user].id,_user,userInfos[userAddressByID[1]].id, userAddressByID[1], payPrice,j,_matrix, priceOfLevel[_level], now);
                    }
                    j++;
                }
                else
                {
                    emit lostForLevelEv(usrAddress,_user,_matrix, _level, now);
                }
                usrAddress = userAddressByID[userInfos[usrAddress].referrerID]; 
          
        }           
    }

    function findNextEligible(address payable orRef,uint _level) public view returns(address payable)
    {
        address payable rightAddress;
        for(uint i=0;i<100;i++)
        {
            orRef = userAddressByID[userInfos[orRef].originalReferrer];
            if(userInfos[orRef].activeX3Levels[_level] > 0)
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

        address[] memory referrals = new address[](3);
        referrals[0] = userInfos[_user].referral[0];
        referrals[1] = userInfos[_user].referral[1];
        referrals[2] = userInfos[_user].referral[2];
        address found = searchForFirst(referrals);
        if(found == address(0)) found = searchForSecond(referrals);
        if(found == address(0)) found = searchForThird(referrals);
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

    function searchForThird(address[] memory _user) internal view returns (address)
    {
        address freeReferrer;
        for(uint i = 0; i < _user.length; i++) {
            if(userInfos[_user[i]].referral.length == 2) {
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
        address[] memory referrals = new address[](88572);
        referrals[0] = userInfos[_user].referral[0];
        referrals[1] = userInfos[_user].referral[1];
        referrals[2] = userInfos[_user].referral[2];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 88572; i++) {
            if(userInfos[referrals[i]].referral.length == maxDownLimit) {
                if(i < 29523) {
                    referrals[(i+1)*3] = userInfos[referrals[i]].referral[0];
                    referrals[(i+1)*3+1] = userInfos[referrals[i]].referral[1];
                    referrals[(i+1)*3+2] = userInfos[referrals[i]].referral[2];
                    referrals[(i+1)*3+3] = userInfos[referrals[i]].referral[3];
                    referrals[(i+1)*3+4] = userInfos[referrals[i]].referral[4];
                    referrals[(i+1)*3+5] = userInfos[referrals[i]].referral[5];
                    referrals[(i+1)*3+6] = userInfos[referrals[i]].referral[6];
                    referrals[(i+1)*3+7] = userInfos[referrals[i]].referral[7];
                    referrals[(i+1)*3+8] = userInfos[referrals[i]].referral[8];
                    referrals[(i+1)*3+9] = userInfos[referrals[i]].referral[9];
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

    function viewUserReferral(address _user) public view returns(address payable[] memory) {
        return userInfos[_user].referral;
    }
    
    
    
    
    function getUserDownlineCount(address userAddress, uint level) public view returns(uint256[] memory) {
		uint256[] memory levelRefCountss = new uint256[](10);
		for(uint8 j=0; j<=9; j++)
		{
		  levelRefCountss[j]  =userInfos[userAddress].levelRefCount[level][j];
		}
		return (levelRefCountss);
	}
    
    function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return userInfos[userAddress].bonus;
	}

    function viewUseractiveX3Levels(address _user, uint _level) public view returns(uint) {
        return userInfos[_user].activeX3Levels[_level];
    }
    
    function usersactiveX6Levels(address userAddress, uint8 level) public view returns(uint) {
        return userInfos[userAddress].activeX6Levels[level];
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

function isUserExists(address user) public view returns (bool) {
        return userInfos[user].joined;
    }
    
function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
        
    function changeDefaultRefID(uint newDefaultRefID) onlyOwner public returns(string memory){
        //this ref ID will be assigned to user who joins without any referral ID.
        defaultRefID = newDefaultRefID;
        return("Default Ref ID updated successfully");
    }
}