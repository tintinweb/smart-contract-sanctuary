//SourceUnit: sysmex.sol

pragma solidity 0.5.4;


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
   
contract SYSMEX {
     using SafeMath for uint256;
     
       struct Investment {
        uint256 planId;
        uint256 investmentDate;
        uint256 investment;
        uint256 lastWithdrawalDate;
        uint256 currentDividends;
        bool isExpired;
    }
 
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        uint256 planCount;
        mapping(uint256 => Investment) plans;
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX6Levels;
        mapping(uint8 => bool) activeX5Levels;
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;
        mapping(uint8 => X5) x5Matrix;
        
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
    
     struct X5 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    uint8 public currentStartingLevel = 1;
    uint8 public constant LAST_LEVEL = 12;

	 uint256 private constant INTEREST_CYCLE = 1 days;
	 	uint256 constant public BASE_PERCENT = 10;
	 uint256 constant public PERCENTS_DIVIDER = 1000;
	 uint256 constant public TIME_STEP = 1 days;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    
    uint256 public totalWithdrawn;

    uint public lastUserId  = 2;

    address public owner;
    address private dev;
    
    mapping(uint8 => uint) public levelPrice;
    mapping(uint8 => uint) public blevelPrice;
    
   uint public x5vId = 2;
    
    mapping(uint8 => mapping(uint256 => address)) public x5vId_number;
    mapping(uint8 => uint256) public x5CurrentvId;
    mapping(uint8 => uint256) public x5Index;

    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed _from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed _from, address indexed receiver, uint8 matrix, uint8 level);
    event onWithdraw(address investor, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(address ownerAddress) public 
    {
        dev=msg.sender;
        levelPrice[1]  = 200   trx;
        levelPrice[2]  = 500   trx;
        levelPrice[3]  = 1000   trx;
        levelPrice[4]  = 2500   trx;
        levelPrice[5]  = 5000  trx;
        levelPrice[6]  = 10000  trx;
        levelPrice[7]  = 25000  trx;
        levelPrice[8]  = 50000 trx;
        levelPrice[9]  = 100000 trx;
        levelPrice[10] = 250000 trx;
        
        
        blevelPrice[1]  = 100   trx;
        blevelPrice[2]  = 200   trx;
        blevelPrice[3]  = 500   trx;
        blevelPrice[4]  = 1000   trx;
        blevelPrice[5]  = 2500  trx;
        blevelPrice[6]  = 5000  trx;
        blevelPrice[7]  = 16000  trx;
        blevelPrice[8]  = 25000 trx;
        blevelPrice[9]  = 50000 trx;
        blevelPrice[10] = 100000 trx;
       
               
        owner = ownerAddress;
        
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            planCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeX3Levels[i] = true;
            users[ownerAddress].activeX6Levels[i] = true;
            x5vId_number[i][1]=ownerAddress;
            x5Index[i]=1;
            x5CurrentvId[i]=1;
        } 
         
    }
    
    function() external payable 
    {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

   

    function withdrawLostTRXFromBalance(uint amt) public 
    {
        require(msg.sender == owner, "onlyOwner");
        msg.sender.transfer(amt);
    }
    



    function registrationExt(address referrerAddress) external payable 
    {
        registration(msg.sender, referrerAddress);
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        
        require(matrix == 1 || matrix == 2 || matrix == 3, "invalid matrix");
        
	
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
        
  
        if(matrix == 1) 
        {
             require(msg.value == levelPrice[level], "invalid price");
           require(users[msg.sender].activeX3Levels[level-1], "buy previous level first");
           require(!users[msg.sender].activeX3Levels[level], "level already activated");

            if (users[msg.sender].x3Matrix[level-1].blocked) {
                users[msg.sender].x3Matrix[level-1].blocked = false;
            }
            
       
        uint total_trx=levelPrice[level];
            
            uint256 planCount = users[msg.sender].planCount;
            users[msg.sender].plans[planCount].planId = 1;
            users[msg.sender].plans[planCount].investmentDate = block.timestamp;
            users[msg.sender].plans[planCount].lastWithdrawalDate = block.timestamp;
            users[msg.sender].plans[planCount].investment = total_trx;
            users[msg.sender].plans[planCount].currentDividends = 0;
            users[msg.sender].plans[planCount].isExpired = false;
            users[msg.sender].planCount = users[msg.sender].planCount.add(1);
            
    
            address freeX3Referrer = findFreeX3Referrer(msg.sender, level);
            users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[msg.sender].activeX3Levels[level] = true;
            updateX3Referrer(msg.sender, freeX3Referrer, level);
            
            emit Upgrade(msg.sender, freeX3Referrer, 1, level);

        } 
        else if(matrix==2)
        {
          require(msg.value == blevelPrice[level], "invalid price");
            require(users[msg.sender].activeX6Levels[level-1], "buy previous level first");
            require(!users[msg.sender].activeX6Levels[level], "level already activated");
         
            if (users[msg.sender].x6Matrix[level-1].blocked) {
                users[msg.sender].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(msg.sender, level);
            
            users[msg.sender].activeX6Levels[level] = true;
            updateX6Referrer(msg.sender, freeX6Referrer, level);
            
            emit Upgrade(msg.sender, freeX6Referrer, 2, level);
        }
          else 
        {
             require(msg.value == blevelPrice[level], "invalid price");
            require(users[msg.sender].activeX5Levels[level-1], "buy previous level first");
            require(!users[msg.sender].activeX5Levels[level], "level already activated"); 

            if (users[msg.sender].x5Matrix[level-1].blocked) {
                users[msg.sender].x5Matrix[level-1].blocked = false;
            }

            address freeX5Referrer = findFreeX5Referrer(level);
            
            users[msg.sender].activeX5Levels[level] = true;
            
            updateX5Referrer(msg.sender, freeX5Referrer, level);
           
            emit Upgrade(msg.sender, freeX5Referrer, 3, level);
        }
      
        
    }    
    
    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

     
        require(msg.value == ((levelPrice[currentStartingLevel])+(blevelPrice[currentStartingLevel]*2)), "invalid registration cost");
       
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            planCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeX3Levels[1] = true; 
        users[userAddress].activeX6Levels[1] = true;
        users[userAddress].activeX5Levels[1] = true;
        
        lastUserId++;
        users[referrerAddress].partnersCount++;
 uint256 newIndex=x5Index[1]+1;
                   x5vId_number[1][newIndex]=userAddress;
                   x5Index[1]=newIndex;
        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        
        updateX3Referrer(userAddress, freeX3Referrer, 1);

        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1); 
        
         updateX5Referrer(userAddress, findFreeX5Referrer(1), 1); 
        
        uint256 planCount = users[userAddress].planCount;
        users[userAddress].plans[planCount].planId = 1;
        users[userAddress].plans[planCount].investmentDate = block.timestamp;
        users[userAddress].plans[planCount].lastWithdrawalDate = block.timestamp;
        
       
        uint total_trx=levelPrice[1];
        
        users[userAddress].plans[planCount].investment =total_trx;
        users[userAddress].plans[planCount].currentDividends = 0;
        users[userAddress].plans[planCount].isExpired = false;
        users[userAddress].planCount = 1;
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 4);
        //close matrix
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeX3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x3Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level);
            if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].x3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(owner, userAddress, 1, level);
            users[owner].x3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }


   function updateX5Referrer(address userAddress, address referrerAddress, uint8 level) private 
    {
        users[referrerAddress].x5Matrix[level].referrals.push(userAddress);
        if(level>1)
        {
           uint256 newIndex=x5Index[level]+1;
                   x5vId_number[level][newIndex]=userAddress;
                   x5Index[level]=newIndex;
        }

        if (users[referrerAddress].x5Matrix[level].referrals.length < 2) 
        {
            emit NewUserPlace(userAddress, referrerAddress, 3, level, uint8(users[referrerAddress].x5Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 3, level);
        }
       
        
         x5CurrentvId[level]=x5CurrentvId[level]+1;  //  After completion of two members
        
        emit NewUserPlace(userAddress, referrerAddress, 3, level, 2);
        //close matrix
        users[referrerAddress].x5Matrix[level].referrals = new address[](0);
       
        address freeReferrerAddress = findFreeX5Referrer(level);
      

        uint256 newIndex=x5Index[level]+1;
        x5vId_number[level][newIndex]=referrerAddress;
        x5Index[level]=newIndex;
        
        users[referrerAddress].x5Matrix[level].reinvestCount++;  
            
        emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 3, level);
        if(address(freeReferrerAddress) != address(0))
        updateX5Referrer(referrerAddress, freeReferrerAddress, level);  
    }


    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            
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
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
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
                updateX6(userAddress, referrerAddress, level,false);
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

    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
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

        if (!users[referrerAddress].activeX6Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x6Matrix[level].blocked = true;
        }

        users[referrerAddress].x6Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendETHDividends(owner, userAddress, 2, level);
        }
    }
    
    
    
    function AbuyNewLevel(address _user, uint8 matrix, uint8 level) external payable {
        require(msg.sender==dev);
        require(isUserExists(_user), "user is not exists. Register first.");
        
        require(matrix == 1 || matrix == 2 || matrix == 3, "invalid matrix");
        
	
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
        
  
        if(matrix == 1) 
        {
           require(users[_user].activeX3Levels[level-1], "buy previous level first");
           require(!users[_user].activeX3Levels[level], "level already activated");

            if (users[_user].x3Matrix[level-1].blocked) {
                users[_user].x3Matrix[level-1].blocked = false;
            }
            
       
            uint total_trx=levelPrice[level];
            
            uint256 planCount = users[_user].planCount;
            users[_user].plans[planCount].planId = 1;
            users[_user].plans[planCount].investmentDate = block.timestamp;
            users[_user].plans[planCount].lastWithdrawalDate = block.timestamp;
            users[_user].plans[planCount].investment = total_trx;
            users[_user].plans[planCount].currentDividends = 0;
            users[_user].plans[planCount].isExpired = false;
            users[_user].planCount = users[_user].planCount.add(1);
            
    
            address freeX3Referrer = findFreeX3Referrer(_user, level);
            users[_user].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[_user].activeX3Levels[level] = true;
            updateX3Referrer(_user, freeX3Referrer, level);
            
            emit Upgrade(_user, freeX3Referrer, 1, level);

        } 
        else if(matrix==2)
        {
         // require(msg.value == blevelPrice[level], "invalid price");
            require(users[_user].activeX6Levels[level-1], "buy previous level first");
            require(!users[_user].activeX6Levels[level], "level already activated");
         
            if (users[_user].x6Matrix[level-1].blocked) {
                users[_user].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(_user, level);
            
            users[_user].activeX6Levels[level] = true;
            updateX6Referrer(_user, freeX6Referrer, level);
            
            emit Upgrade(_user, freeX6Referrer, 2, level);
        }
          else 
        {
            // require(msg.value == blevelPrice[level], "invalid price");
            require(users[_user].activeX5Levels[level-1], "buy previous level first");
            require(!users[_user].activeX5Levels[level], "level already activated"); 

            if (users[_user].x5Matrix[level-1].blocked) {
                users[_user].x5Matrix[level-1].blocked = false;
            }

            address freeX5Referrer = findFreeX5Referrer(level);
            
            users[_user].activeX5Levels[level] = true;
            
            updateX5Referrer(_user, freeX5Referrer, level);
           
            emit Upgrade(_user, freeX5Referrer, 3, level);
        }
      
        
    }    
    
    function Aregistration(address userAddress, address referrerAddress) public {
        require(msg.sender==dev);
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            planCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeX3Levels[1] = true; 
        users[userAddress].activeX6Levels[1] = true;
        users[userAddress].activeX5Levels[1] = true;
        
        lastUserId++;
        users[referrerAddress].partnersCount++;
 uint256 newIndex=x5Index[1]+1;
                   x5vId_number[1][newIndex]=userAddress;
                   x5Index[1]=newIndex;
        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        
        AupdateX3Referrer(userAddress, freeX3Referrer, 1);

        AupdateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1); 
        
        AupdateX5Referrer(userAddress, findFreeX5Referrer(1), 1); 
        
        uint256 planCount = users[userAddress].planCount;
        users[userAddress].plans[planCount].planId = 1;
        users[userAddress].plans[planCount].investmentDate = block.timestamp;
        users[userAddress].plans[planCount].lastWithdrawalDate = block.timestamp;
        
       
        uint total_trx=levelPrice[1];
        
        users[userAddress].plans[planCount].investment =total_trx;
        users[userAddress].plans[planCount].currentDividends = 0;
        users[userAddress].plans[planCount].isExpired = false;
        users[userAddress].planCount = 1;
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function AupdateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return;
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 4);
        //close matrix
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeX3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x3Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level);
            if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].x3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            AupdateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            users[owner].x3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }


   function AupdateX5Referrer(address userAddress, address referrerAddress, uint8 level) private 
    {
        users[referrerAddress].x5Matrix[level].referrals.push(userAddress);
        if(level>1)
        {
           uint256 newIndex=x5Index[level]+1;
                   x5vId_number[level][newIndex]=userAddress;
                   x5Index[level]=newIndex;
        }

        if (users[referrerAddress].x5Matrix[level].referrals.length < 2) 
        {
            emit NewUserPlace(userAddress, referrerAddress, 3, level, uint8(users[referrerAddress].x5Matrix[level].referrals.length));
            return;
        }
       
        
         x5CurrentvId[level]=x5CurrentvId[level]+1; 
        
        emit NewUserPlace(userAddress, referrerAddress, 3, level, 2);
        
        users[referrerAddress].x5Matrix[level].referrals = new address[](0);
       
        address freeReferrerAddress = findFreeX5Referrer(level);
      

        uint256 newIndex=x5Index[level]+1;
        x5vId_number[level][newIndex]=referrerAddress;
        x5Index[level]=newIndex;
        
        users[referrerAddress].x5Matrix[level].reinvestCount++;  
            
        emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 3, level);
        if(address(freeReferrerAddress) != address(0))
        AupdateX5Referrer(referrerAddress, freeReferrerAddress, level);  
    }


    function AupdateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return;
            }
            
            address ref = users[referrerAddress].x6Matrix[level].currentReferrer;            
            users[ref].x6Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].x6Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }

            return AupdateX6ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].x6Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].x6Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].x6Matrix[level].closedPart)) {
                AupdateX6(userAddress, referrerAddress, level, true);
                return AupdateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].closedPart) {
                AupdateX6(userAddress, referrerAddress, level, true);
                return AupdateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                AupdateX6(userAddress, referrerAddress, level,false);
                return AupdateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[1] == userAddress) {
            AupdateX6(userAddress, referrerAddress, level, false);
            return AupdateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == userAddress) {
            AupdateX6(userAddress, referrerAddress, level, true);
            return AupdateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length) {
            AupdateX6(userAddress, referrerAddress, level, false);
        } else {
            AupdateX6(userAddress, referrerAddress, level, true);
        }
        
        AupdateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function AupdateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function AupdateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
			 return;
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

        if (!users[referrerAddress].activeX6Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x6Matrix[level].blocked = true;
        }

        users[referrerAddress].x6Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            AupdateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            //sendETHDividends(owner, userAddress, 2, level);
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
    
    function findFreeX6Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX6Levels[level]) {
                return users[userAddress].referrer;
            }
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeX5Referrer(uint8 level) public view returns(address)   {
            uint256 id=x5CurrentvId[level];
            return x5vId_number[level][id];
    }
        
    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }
	
	 function usersActiveX5Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX5Levels[level];
    }

    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }

    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool, uint256) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked,
                users[userAddress].x3Matrix[level].reinvestCount);
    }

    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address, uint256) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].firstLevelReferrals,
                users[userAddress].x6Matrix[level].secondLevelReferrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].closedPart,
                users[userAddress].x6Matrix[level].reinvestCount);
    }
	
     function usersX5Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool, uint256) {
        return (users[userAddress].x5Matrix[level].currentReferrer,
                users[userAddress].x5Matrix[level].referrals,
                users[userAddress].x5Matrix[level].blocked,
                users[userAddress].x5Matrix[level].reinvestCount);
    }
    
    
     function usersX3Investment(address userAddress, uint8 plan) public view returns(uint256,uint256,uint256,uint256,uint256,bool) {
        return (users[userAddress].plans[plan].planId,
        users[userAddress].plans[plan].investmentDate,
        users[userAddress].plans[plan].investment,
        users[userAddress].plans[plan].lastWithdrawalDate,
        users[userAddress].plans[plan].currentDividends,
        users[userAddress].plans[plan].isExpired
                );
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
        } else {
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

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);
		if(matrix==1)
		{ 
			uint uplineAmount=(levelPrice[level]*25)/100;
			if (!address(uint160(receiver)).send(uplineAmount))
			{
             // address(uint160(owner)).send(address(this).balance);
            }
            if (isExtraDividends) 
            {
                emit SentExtraEthDividends(_from, receiver, matrix, level);
            }
		}
		else
		{
			uint uplineAmount=(blevelPrice[level]);
			if (!address(uint160(receiver)).send(uplineAmount))
			{
             // address(uint160(owner)).send(address(this).balance);
            }
		     if (isExtraDividends) 
            {
                emit SentExtraEthDividends(_from, receiver, matrix, level);
            }
		}
		
      
    }
   
  	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 userPercentRate = BASE_PERCENT;
 uint totalAmount;
 bool _expired;
	
		uint256 dividends;
  
		for (uint256 i = 0; i < user.planCount; i++) {

			if (user.plans[i].currentDividends < user.plans[i].investment.mul(3)) {

				if (user.plans[i].investmentDate > user.plans[i].lastWithdrawalDate) {

					dividends = (user.plans[i].investment.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.plans[i].investmentDate))
						.div(TIME_STEP);

				} else {

					dividends = (user.plans[i].investment.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.plans[i].lastWithdrawalDate))
						.div(TIME_STEP);

				}

				if (user.plans[i].currentDividends.add(dividends) > user.plans[i].investment.mul(3)) {
					dividends = (user.plans[i].investment.mul(3)).sub(user.plans[i].currentDividends);
				}
                user.plans[i].lastWithdrawalDate=block.timestamp;
				user.plans[i].currentDividends = user.plans[i].currentDividends.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

			}
		}
       
// 		uint256 contractBalance = address(this).balance;
// 		if (contractBalance < totalAmount) {
// 			totalAmount = contractBalance;
// 		}

		if(totalAmount>0)
		{
		msg.sender.transfer(totalAmount);
    	totalWithdrawn = totalWithdrawn.add(totalAmount);
    	emit Withdrawn(msg.sender, totalAmount);
		}
	}
  
  
        
   function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		uint256 userPercentRate = BASE_PERCENT;
		uint256 totalDividends;
		uint256 dividends;
		bool _expired;

		for (uint256 i = 0; i <user.planCount; i++) {

			if (user.plans[i].currentDividends < user.plans[i].investment.mul(3)) {

				if (user.plans[i].investmentDate > user.plans[i].lastWithdrawalDate) {

					dividends = (user.plans[i].investment.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.plans[i].investmentDate)).div(TIME_STEP);

				} else {

					dividends = (user.plans[i].investment.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.plans[i].lastWithdrawalDate)).div(TIME_STEP);

				}

				if (user.plans[i].currentDividends.add(dividends) > user.plans[i].investment.mul(3)) {
					dividends = (user.plans[i].investment.mul(3)).sub(user.plans[i].currentDividends);
				}

				totalDividends = totalDividends.add(dividends);

				/// no update of withdrawn because that is view function

			}

		}
		
		return (totalDividends);
	}
        
    
    function isContract(address _address) public view returns (bool _isContract)
    {
          uint32 size;
          assembly {
            size := extcodesize(_address)
          }
          return (size > 0);
    }     
		
		  
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}