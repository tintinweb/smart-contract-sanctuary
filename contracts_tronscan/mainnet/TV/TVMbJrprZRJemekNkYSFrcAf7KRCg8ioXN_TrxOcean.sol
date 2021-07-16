//SourceUnit: trxocean.sol


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


contract TrxOcean is ownerShip {
    
    using SafeMath for uint256;

    uint public defaultRefID = 1;   //this ref ID will be used if user joins without any ref ID
    uint maxDownLimit = 5;

    uint public lastIDCount = 0;
   
    
	uint256 constant public PERCENTS_DIVIDER = 100;
    address payable public adminAddress;



    struct userInfo {
        bool joined;
        uint id;
        uint referrerID;
        uint bonus;
        uint partnerCount;
        uint originalReferrer;
        uint gainAmountCounter;
        uint investAmountCounter;
        address payable[] referral;
        mapping(uint => uint) activeX5Levels;
        mapping(uint => X5) x5Matrix;
        
        mapping(uint => uint) activeX3Levels;
        mapping(uint => X3) x3Matrix;
    }

     struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct X5 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        
    }
    
    
   uint8 public constant LAST_LEVEL = 11;

    mapping (address => userInfo) public userInfos;
    mapping (uint => address payable ) public userAddressByID;
    mapping(uint => uint) public AClevelPrice;
    mapping(uint => uint) public levelPrice;
    mapping(uint => uint) public blevelPrice;
    mapping(uint => uint) public alevelPrice;
    mapping(uint => uint) public currentvId;
    mapping(uint => uint) public index;

    event regLevelEv(address indexed useraddress, uint userid,uint placeid,uint refferalid, address indexed refferaladdress, uint _time);
    event LevelByEv(uint userid,address indexed useraddress, uint level,uint _matrix,uint amount, uint time);    
    event paidForLevelEv(uint fromUserId, address fromAddress, uint toUserId,address toAddress, uint amount,uint level,uint matrix, uint packageAmount, uint time );
    event lostForLevelEv(address indexed _user, address indexed _referral,uint amount,uint level, uint _matrix,uint _packageAmount, uint _time);
    event reInvestEv(address user,uint userid,uint amount, uint timeNow, uint _matrix, uint level);
    event FeePayed(address indexed user, uint256 totalAmount);
    event Upgrade(address indexed user, address indexed referrer, uint _matrix, uint8 _level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place, uint amount);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    
    constructor() public {
	
	    AClevelPrice[1]   =  101 trx;
        AClevelPrice[2]   =  201 trx;
        AClevelPrice[3]   =  401 trx;
        AClevelPrice[4]   =  810 trx;
        AClevelPrice[5]   =  1620 trx;
        AClevelPrice[6]   =  3220 trx;
        AClevelPrice[7]   =  6440 trx;
        AClevelPrice[8]   =  15000 trx;
        AClevelPrice[9]   =  30000 trx;
        AClevelPrice[10]  =  60000 trx;
        AClevelPrice[11]  =  120000 trx;
        
		levelPrice[1]   =  50 trx;
        levelPrice[2]   =  100 trx;
        levelPrice[3]   =  200 trx;
        levelPrice[4]   =  400 trx;
        levelPrice[5]   =  800 trx;
        levelPrice[6]   =  1600 trx;
        levelPrice[7]   =  3200 trx;
        levelPrice[8]   =  6500 trx;
        levelPrice[9]   =  12500 trx;
        levelPrice[10]  =  25000 trx;
        levelPrice[11]  =  50000 trx;
        
		blevelPrice[1]   =  5 trx;
        blevelPrice[2]   =  10 trx;
        blevelPrice[3]   =  20 trx;
        blevelPrice[4]   =  40 trx;
        blevelPrice[5]   =  80 trx;
        blevelPrice[6]   =  160 trx;
        blevelPrice[7]   =  320 trx;
        blevelPrice[8]   =  650 trx;
        blevelPrice[9]   =  1250 trx;
        blevelPrice[10]  =  2500 trx;
        blevelPrice[11]  =  5000 trx;
		
		alevelPrice[1]   =  1 trx;
        alevelPrice[2]   =  1 trx;
        alevelPrice[3]   =  1 trx;
        alevelPrice[4]   =  10 trx;
        alevelPrice[5]   =  20 trx;
        alevelPrice[6]   =  20 trx;
        alevelPrice[7]   =  40 trx;
        alevelPrice[8]   =  2000 trx;
        alevelPrice[9]   =  5000 trx;
        alevelPrice[10]  =  10000 trx;
        alevelPrice[11]  =  20000 trx;
        
        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: 1,
            bonus:0,
            partnerCount:0,
            originalReferrer: 1,
            gainAmountCounter:10,
            investAmountCounter:1,
            referral: new address payable [](0)
        });
        userInfos[ownerWallet] = UserInfo;
        userAddressByID[lastIDCount] = ownerWallet;

        for(uint i = 1; i <= 11; i++) {
            
            index[i]=1;
            userInfos[ownerWallet].activeX3Levels[i] = 1;
            userInfos[ownerWallet].activeX5Levels[i] = 1;
            
        }
	}


   

    function () external payable {
        uint8 level;
        //uint matrix;

        if(msg.value == AClevelPrice[1]) level = 1;
        else if(msg.value == AClevelPrice[2]) level = 2;
        else if(msg.value == AClevelPrice[3]) level = 3;
        else if(msg.value == AClevelPrice[4]) level = 4;
        else if(msg.value == AClevelPrice[5]) level = 5;
        else if(msg.value == AClevelPrice[6]) level = 6;
        else if(msg.value == AClevelPrice[7]) level = 7;
        else if(msg.value == AClevelPrice[8]) level = 8;
        else if(msg.value == AClevelPrice[9]) level = 9;
        else if(msg.value == AClevelPrice[10]) level = 10;
        else if(msg.value == AClevelPrice[11]) level = 11;
        

        else revert('Incorrect Value send');

        if(level == 1) {
            uint refId = 0;
            address referrer = bytesToAddress(msg.data);

            if(userInfos[referrer].joined) refId = userInfos[referrer].id;
            else revert('Incorrect referrer');

            regUser(refId);
        }
        else revert('Please buy first level for 101 TRX');
    }



function withdrawLostTRXFromBalance(address payable _sender) public {
        require(msg.sender == ownerWallet, "onlyOwner");
        _sender.transfer(address(this).balance);
    }
    
  function buyNewLevel(uint8 matrix, uint8 level) external payable {
       
        require(isUserExists(msg.sender), "user is not exists.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(msg.value == AClevelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
        require(userInfos[msg.sender].activeX5Levels[level] ==0, "already activated");
        require(userInfos[msg.sender].activeX5Levels[level-1] == 1 || userInfos[msg.sender].activeX5Levels[level-1] == 1, "Activate privious level first");
            
            
            userInfos[msg.sender].activeX3Levels[level] = 1;
            
            
            address freeX3Referrer = findFreeX3Referrer(msg.sender, level);
            userInfos[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;
            updateX3Referrer(msg.sender, freeX3Referrer, level);
            emit Upgrade(msg.sender, freeX3Referrer, 1, level);
            
            ownerWallet.transfer(alevelPrice[level]);
            
            userInfos[msg.sender].activeX5Levels[level] = 1;
			payForLevel(level, msg.sender,2);
            emit Upgrade(msg.sender, userAddressByID[userInfos[msg.sender].referrerID], 2, level);
       
    }
    
    
    function regUser(uint _referrerID) public payable {
        uint originalReferrer = _referrerID;
        require(!userInfos[msg.sender].joined, 'User exist');
        require(_referrerID > 0 && _referrerID <= lastIDCount, 'Incorrect referrer Id');
        require(msg.value == AClevelPrice[1], 'Incorrect Value');
        address userAddress=msg.sender;
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        
        if(!(_referrerID > 0 && _referrerID <= lastIDCount)) _referrerID = defaultRefID;
        if(userInfos[userAddressByID[_referrerID]].referral.length >= maxDownLimit) 
        _referrerID = userInfos[findFreeReferrer(userAddressByID[_referrerID])].id;
        
        ownerWallet.transfer(alevelPrice[1]);
		

        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            partnerCount:0,
            bonus:0,
            
            referrerID: _referrerID,
            originalReferrer: originalReferrer,
            gainAmountCounter:0,
            investAmountCounter:msg.value,            
            referral: new address payable[](0)
        });

        userInfos[msg.sender] = UserInfo;
        userAddressByID[lastIDCount] = msg.sender;

        userInfos[msg.sender].activeX3Levels[1] = 1;
        userInfos[msg.sender].activeX5Levels[1] = 1;
        
        address freeX3Referrer = findFreeX3Referrer(msg.sender, 1);
        userInfos[msg.sender].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateX3Referrer(msg.sender, freeX3Referrer, 1);
        
        
        userInfos[userAddressByID[_referrerID]].partnerCount = userInfos[userAddressByID[_referrerID]].partnerCount+1;

        userInfos[userAddressByID[_referrerID]].referral.push(msg.sender);

        payForLevel(1, msg.sender,2);

        emit regLevelEv(msg.sender,lastIDCount,_referrerID, originalReferrer, userAddressByID[originalReferrer],now );
    }

    
     function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        userInfos[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (userInfos[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(userInfos[referrerAddress].x3Matrix[level].referrals.length),levelPrice[level]);
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3,levelPrice[level]);
        //close matrix
        userInfos[referrerAddress].x3Matrix[level].referrals = new address[](0);
        // if (userInfos[referrerAddress].activeX3Levels[level+1] >0 && level != LAST_LEVEL) {
        //     userInfos[referrerAddress].x3Matrix[level].blocked = true;
        // }

        //create new one by recursion
        if (referrerAddress != ownerWallet) {
            //check referrer active level
            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level);
            if (userInfos[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {
                userInfos[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            userInfos[referrerAddress].x3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(ownerWallet, userAddress, 1, level);
            userInfos[ownerWallet].x3Matrix[level].reinvestCount++;
            emit Reinvest(ownerWallet, address(0), userAddress, 1, level);
        }
    }
    
    function findEthReceiver(address userAddress, address _from, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        
            while (true) {
                if (userInfos[receiver].activeX3Levels[level] == 0) {
                    emit MissedEthReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = userInfos[receiver].x3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
         
    }
    
    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, level);
        
       
        
        if (!address(uint160(receiver)).send(levelPrice[level]))
        {
            return address(uint160(ownerWallet)).transfer(address(this).balance);
        }
        
        if (isExtraDividends) 
        {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
        
    }

    function payForLevel(uint8 _level, address  _user, uint _matrix) internal {

        uint payPrice = blevelPrice[_level];
        //address orRef = userAddressByID[userInfos[_user].originalReferrer];
          
          
            splitForStack(_user,payPrice, _level, _matrix);
          
    }
    
    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool, uint) {
        return (userInfos[userAddress].x3Matrix[level].currentReferrer,
                userInfos[userAddress].x3Matrix[level].referrals,
                userInfos[userAddress].x3Matrix[level].blocked,
				userInfos[userAddress].x3Matrix[level].reinvestCount);
    } 
    
    
    function usersx5Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (userInfos[userAddress].x5Matrix[level].currentReferrer,
                userInfos[userAddress].x5Matrix[level].referrals,
                userInfos[userAddress].x5Matrix[level].blocked
                
                
                );
    }
    
    

  

    
    function splitForStack(address _user, uint payPrice, uint _level, uint _matrix) internal returns(bool)
    {
        address payable usrAddress = userAddressByID[userInfos[_user].referrerID];
        uint i;
        uint j;
       
        for(i=0;i<100;i++)
        {
           
           
                if(j == 10 ) break;
                if(userInfos[usrAddress].activeX5Levels[_level] > 0  || userInfos[usrAddress].id == 1 )
                {
                       
                       
                          usrAddress.transfer(payPrice);
                            userInfos[usrAddress].gainAmountCounter += payPrice;
                           
                      
						userInfos[usrAddress].bonus = userInfos[usrAddress].bonus.add(payPrice);
						
                        emit paidForLevelEv(userInfos[_user].id,_user,userInfos[usrAddress].id, usrAddress, payPrice, j,_matrix, _level, now);
                    
                    j++;
                }
                else
                {
                    
                    emit lostForLevelEv(usrAddress,_user,payPrice, j,_matrix, _level, now);
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

        address[] memory referrals = new address[](5);
        referrals[0] = userInfos[_user].referral[0];
        referrals[1] = userInfos[_user].referral[1];
        referrals[2] = userInfos[_user].referral[2];
		referrals[3] = userInfos[_user].referral[3];
		referrals[4] = userInfos[_user].referral[4];
        address found = searchForFirst(referrals);
        if(found == address(0)) found = searchForSecond(referrals);
        if(found == address(0)) found = searchForThird(referrals);
		if(found == address(0)) found = searchForFourth(referrals);
		if(found == address(0)) found = searchForFifth(referrals);
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
	
	function searchForFourth(address[] memory _user) internal view returns (address)
    {
        address freeReferrer;
        for(uint i = 0; i < _user.length; i++) {
            if(userInfos[_user[i]].referral.length == 3) {
                freeReferrer = _user[i];
                break;
            }
        }
        return freeReferrer;        
    }
	
	function searchForFifth(address[] memory _user) internal view returns (address)
    {
        address freeReferrer;
        for(uint i = 0; i < _user.length; i++) {
            if(userInfos[_user[i]].referral.length == 4) {
                freeReferrer = _user[i];
                break;
            }
        }
        return freeReferrer;        
    }
    
    function findFreeX3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            
            if (userInfos[userAddressByID[userInfos[userAddress].originalReferrer]].activeX3Levels[level] == 1) {
                return userAddressByID[userInfos[userAddress].originalReferrer];
            }
            
            userAddress = userAddressByID[userInfos[userAddress].originalReferrer];
        }
    }

    function findFreeReferrer(address _user) public view returns(address) {
        if(userInfos[_user].referral.length < maxDownLimit) return _user;
        address found = findFreeReferrer1(_user);
        if(found != address(0)) return found;
        address[] memory referrals = new address[](12207030);
        referrals[0] = userInfos[_user].referral[0];
        referrals[1] = userInfos[_user].referral[1];
        referrals[2] = userInfos[_user].referral[2];
		referrals[3] = userInfos[_user].referral[3];
		referrals[4] = userInfos[_user].referral[4];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 12207030; i++) {
            if(userInfos[referrals[i]].referral.length == maxDownLimit) {
                if(i < 29523) {
                    referrals[(i+1)*5] = userInfos[referrals[i]].referral[0];
                    referrals[(i+1)*5+1] = userInfos[referrals[i]].referral[1];
                    referrals[(i+1)*5+2] = userInfos[referrals[i]].referral[2];
                    referrals[(i+1)*5+3] = userInfos[referrals[i]].referral[3];
                    referrals[(i+1)*5+4] = userInfos[referrals[i]].referral[4];
                    referrals[(i+1)*5+5] = userInfos[referrals[i]].referral[5];
                    referrals[(i+1)*5+6] = userInfos[referrals[i]].referral[6];
                    referrals[(i+1)*5+7] = userInfos[referrals[i]].referral[7];
                    referrals[(i+1)*5+8] = userInfos[referrals[i]].referral[8];
                    referrals[(i+1)*5+9] = userInfos[referrals[i]].referral[9];
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
   

    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(uint) {
        return userInfos[userAddress].activeX3Levels[level];
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
    
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
        
   
}