/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

pragma solidity 0.4.25;

interface IBEP20 {
  
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  

 
}

contract SuperMatrix {
    IBEP20 public BUSDaddress;
    using SafeMath for uint256;
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint256 => bool) activeX3Levels;
        mapping(uint256 => bool) activeX6Levels;
        
        mapping(uint256 => X3) x3Matrix;
        mapping(uint256 => X6) x6Matrix;
        
        
        mapping(uint256 => bool) activeX12Levels;
        mapping(uint256 => X12) x12Matrix;
       
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
        uint noOfPayment;
        address closedPart;
        uint256 lastSettledDailyGlobal;
    }
    
    
     struct X12 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        address[] thirdLevelReferrals;
        bool blocked;
        uint8 reinvestCount;
        uint noOfPayment;
    }
    
    
  
      
   
    uint8 public currentStartingLevel = 1;
    uint8 public constant LAST_LEVEL = 12;
    
    uint256 public totalWithdrawn;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;

    uint public lastUserId = 2;
    address public owner;
    mapping(uint256 => uint) public levelPrice;
   

   	
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint256 level,uint8 reinvestCount);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint256 level);
    event NewUserPlace(address indexed user, address indexed referrer,address indexed currentReferrer, uint8 matrix, uint256 level, uint256 place,uint8 reinvestcount);
    event MissedTRXReceive(address indexed receiver, address indexed from, uint8 matrix, uint256 level);
    event Withdrawn(address indexed user, uint256 amount,uint256 earnfrom);
    event EarningsMatrix(address indexed user,uint256 amount,uint8 matrix,uint256 level);
    
    constructor(address ownerAddress) public {
        
        
        levelPrice[1] = 5*1e17;
        levelPrice[2] = 1*1e18;
        levelPrice[3] = 2*1e18;
        levelPrice[4] = 4*1e18;
        levelPrice[5] = 8*1e18;
        levelPrice[6] = 16*1e18;
        levelPrice[7] = 32*1e18;
        levelPrice[8] = 64*1e18;
        levelPrice[9] = 128*1e18;
        levelPrice[10] = 256*1e18;
        levelPrice[11] = 512*1e18;
        levelPrice[12] = 1024*1e18;   

         BUSDaddress=IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); 
         owner = ownerAddress;
            users[ownerAddress].id= 1;
            users[ownerAddress].referrer=address(0);
            users[ownerAddress].partnersCount=0;
           
            
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeX3Levels[i] = true;
            users[ownerAddress].activeX6Levels[i] = true;
            users[ownerAddress].activeX12Levels[i] = true;
        
            
           
           
        }   
        
       
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
       
        registration(msg.sender, bytesToAddress(msg.data));
    }

   
   

    function registrationExt(address referrerAddress) external {
        
        registration(msg.sender, referrerAddress);
    }
    
    
    
    function buyNewLevel(uint8 matrix, uint256 level) external {
        require(BUSDaddress.transferFrom(msg.sender,address(this),levelPrice[level]),"Error in transfer");
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2 || matrix == 3, "invalid matrix");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            require(users[msg.sender].activeX3Levels[level.sub(1)], "buy previous level first");
            require(!users[msg.sender].activeX3Levels[level], "level already activated");
            

            if (users[msg.sender].x3Matrix[level.sub(1)].blocked) {
                users[msg.sender].x3Matrix[level.sub(1)].blocked = false;
            }
    
            address freeX3Referrer = findFreeX3Referrer(msg.sender, level);
            users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[msg.sender].activeX3Levels[level] = true;
            updateX3Referrer(msg.sender, freeX3Referrer, level);
            
            emit Upgrade(msg.sender, freeX3Referrer, 1, level);
        
            
        }
        else if(matrix == 2) {
            require(users[msg.sender].activeX6Levels[level.sub(1)], "buy previous level first");
            require(!users[msg.sender].activeX6Levels[level], "level already activated"); 

            if (users[msg.sender].x6Matrix[level.sub(1)].blocked) {
                users[msg.sender].x6Matrix[level.sub(1)].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(msg.sender, level);
            
            users[msg.sender].activeX6Levels[level] = true;
            updateX6Referrer(msg.sender, freeX6Referrer, level);
            
            emit Upgrade(msg.sender, freeX6Referrer, 2, level);
            
        }
        else
        {
             require(users[msg.sender].activeX12Levels[level.sub(1)], "buy previous level first");
            require(!users[msg.sender].activeX12Levels[level], "level already activated"); 

            if (users[msg.sender].x12Matrix[level.sub(1)].blocked) {
                users[msg.sender].x12Matrix[level.sub(1)].blocked = false;
            }

            address freeX12Referrer = findFreeX12Referrer(msg.sender, level);
            
            users[msg.sender].activeX12Levels[level] = true;
            updateX12Referrer(msg.sender, freeX12Referrer, level);
            
            emit Upgrade(msg.sender, freeX12Referrer, 3, level);
        }
    }    
    
   
    
    function registration(address userAddress, address referrerAddress) private {
        require(BUSDaddress.transferFrom(msg.sender,address(this),levelPrice[1]*3),"Error in transfer");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
       
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

       users[userAddress].id= lastUserId;
            users[userAddress].referrer=referrerAddress;
            users[userAddress].partnersCount=0;
       
        
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeX3Levels[1] = true; 
        users[userAddress].activeX6Levels[1] = true;
        users[userAddress].activeX12Levels[1] = true;
        
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        
        updateX3Referrer(userAddress, freeX3Referrer, 1);

        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1);

        updateX12Referrer(userAddress, findFreeX12Referrer(userAddress, 1), 1);
       
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
       
     
      
    }
    
       
    function updateX3Referrer(address userAddress, address referrerAddress, uint256 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, referrerAddress,1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length),0);
            return sendTRXDividends(referrerAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress,referrerAddress, 1, level, 3,0);
        //close matrix
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeX3Levels[level.add(1)] && level != LAST_LEVEL) {
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
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level,0);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendTRXDividends(owner, 1, level);
            users[owner].x3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level,0);
        }
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint256 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress,referrerAddress ,2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length),0);
            
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendTRXDividends(referrerAddress, 2, level);
            }
            
            address ref = users[referrerAddress].x6Matrix[level].currentReferrer;            
            users[ref].x6Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].x6Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref,ref, 2, level, 5,0);
                } else {
                    emit NewUserPlace(userAddress, ref,ref, 2, level, 6,0);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref,ref, 2, level, 3,0);
                } else {
                    emit NewUserPlace(userAddress, ref,ref, 2, level, 4,0);
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref,ref, 2, level, 5,0);
                } else {
                    emit NewUserPlace(userAddress, ref,ref, 2, level, 6,0);
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
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0],users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length),0);
            emit NewUserPlace(userAddress, referrerAddress,referrerAddress, 2, level,uint256(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length).add(2),0);
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1],users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length),0);
            emit NewUserPlace(userAddress, referrerAddress, referrerAddress,2, level, uint256(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length).add(4),0);
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint256 level) private {
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            return sendTRXDividends(referrerAddress, 2, level);
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

        users[referrerAddress].x6Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level,0);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level,0);
            sendTRXDividends(owner, 2, level);
        }
    }
    
    
       
    
        /*  12X */
    function updateX12Referrer(address userAddress, address referrerAddress, uint256 level) private {
        require(users[referrerAddress].activeX12Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x12Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x12Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, referrerAddress,3, level,1,users[referrerAddress].x12Matrix[level].reinvestCount);
            
            //set current level
            users[userAddress].x12Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
               
               return sendTRXDividends(userAddress, 3, level);
            }
            
            address ref = users[referrerAddress].x12Matrix[level].currentReferrer;            
            users[ref].x12Matrix[level].secondLevelReferrals.push(userAddress); 
            emit NewUserPlace(userAddress, referrerAddress, ref,3, level,2,users[ref].x12Matrix[level].reinvestCount);
            
            address ref1 = users[ref].x12Matrix[level].currentReferrer;            
            users[ref1].x12Matrix[level].thirdLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress,ref1, 3, level,3,users[ref1].x12Matrix[level].reinvestCount);
            
            return updateX12ReferrerSecondLevel(userAddress, ref1, level);
        }
         if (users[referrerAddress].x12Matrix[level].secondLevelReferrals.length < 4) {
        users[referrerAddress].x12Matrix[level].secondLevelReferrals.push(userAddress);
        address secondref = users[referrerAddress].x12Matrix[level].currentReferrer; 
       
        if(secondref==address(0))
        secondref=owner;
       
       
        
        if (users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[0]].x12Matrix[level].firstLevelReferrals.length < 
            2) {
            updateX12(userAddress, referrerAddress, level, false);
        } else {
            updateX12(userAddress, referrerAddress, level, true);
        }
        
        updateX12ReferrerSecondLevel(userAddress, secondref, level);
        }
        
        
        else  if (users[referrerAddress].x12Matrix[level].thirdLevelReferrals.length < 8) {
        users[referrerAddress].x12Matrix[level].thirdLevelReferrals.push(userAddress);

      if (users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[0]].x12Matrix[level].firstLevelReferrals.length<2) {
            updateX12Fromsecond(userAddress, referrerAddress, level, 0);
            
        } else if (users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[1]].x12Matrix[level].firstLevelReferrals.length<2) {
            updateX12Fromsecond(userAddress, referrerAddress, level, 1);
            
        }else if (users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[2]].x12Matrix[level].firstLevelReferrals.length<2) {
            updateX12Fromsecond(userAddress, referrerAddress, level, 2);
           
        }else if (users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[3]].x12Matrix[level].firstLevelReferrals.length<2) {
            updateX12Fromsecond(userAddress, referrerAddress, level, 3);
            
        }
        
        updateX12ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
    }

    function updateX12(address userAddress, address referrerAddress, uint256 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[0]].x12Matrix[level].firstLevelReferrals.push(userAddress);
            users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].thirdLevelReferrals.push(userAddress);
            
            
            emit NewUserPlace(userAddress,users[referrerAddress].x12Matrix[level].firstLevelReferrals[0],users[referrerAddress].x12Matrix[level].firstLevelReferrals[0], 3, level, 1,users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[0]].x12Matrix[level].reinvestCount);
            emit NewUserPlace(userAddress,users[referrerAddress].x12Matrix[level].firstLevelReferrals[0], referrerAddress,3, level, 2,users[referrerAddress].x12Matrix[level].reinvestCount);
            emit NewUserPlace(userAddress,users[referrerAddress].x12Matrix[level].firstLevelReferrals[0], users[referrerAddress].x12Matrix[level].currentReferrer,3, level, 3,users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].reinvestCount);

            users[userAddress].x12Matrix[level].currentReferrer = users[referrerAddress].x12Matrix[level].firstLevelReferrals[0];
           
        } else {
            users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[1]].x12Matrix[level].firstLevelReferrals.push(userAddress);
            users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].thirdLevelReferrals.push(userAddress);

           emit NewUserPlace(userAddress,users[referrerAddress].x12Matrix[level].firstLevelReferrals[1],users[referrerAddress].x12Matrix[level].firstLevelReferrals[1],3, level, 1,users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[1]].x12Matrix[level].reinvestCount);
            emit NewUserPlace(userAddress,users[referrerAddress].x12Matrix[level].firstLevelReferrals[1],referrerAddress, 3, level, 2,users[referrerAddress].x12Matrix[level].reinvestCount);
            emit NewUserPlace(userAddress,users[referrerAddress].x12Matrix[level].firstLevelReferrals[1],users[referrerAddress].x12Matrix[level].currentReferrer, 3, level, 3,users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].reinvestCount);

            //set current level
            users[userAddress].x12Matrix[level].currentReferrer = users[referrerAddress].x12Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateX12Fromsecond(address userAddress, address referrerAddress, uint256 level,uint pos) private {
            users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos]].x12Matrix[level].firstLevelReferrals.push(userAddress);
             users[users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos]].x12Matrix[level].currentReferrer].x12Matrix[level].secondLevelReferrals.push(userAddress);

               
            
            emit NewUserPlace(userAddress, users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos],referrerAddress, 3, level,3,users[referrerAddress].x12Matrix[level].reinvestCount); //third position
            
            emit NewUserPlace(userAddress,users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos], users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos]].x12Matrix[level].currentReferrer, 3, level,2,users[users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos]].x12Matrix[level].currentReferrer].x12Matrix[level].reinvestCount);

             emit NewUserPlace(userAddress,users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos], users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos],3, level, 1,users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos]].x12Matrix[level].reinvestCount); //first position
           //set current level
            
           //set current level
            
            users[userAddress].x12Matrix[level].currentReferrer = users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos];
           
       
    }
    
    
    
    
    function updateX12ReferrerSecondLevel(address userAddress, address referrerAddress, uint256 level) private {
        if(referrerAddress==address(0)){
            
            return sendTRXDividends(userAddress, 3, level);
        }
        if (users[referrerAddress].x12Matrix[level].thirdLevelReferrals.length < 8) {
           
          return sendTRXDividends(userAddress, 3, level);
        }
      
        
        users[referrerAddress].x12Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].x12Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].x12Matrix[level].thirdLevelReferrals = new address[](0);
        
       
        if (!users[referrerAddress].activeX12Levels[level.add(1)] && level != LAST_LEVEL) {
            users[referrerAddress].x12Matrix[level].blocked = true;
        }

        users[referrerAddress].x12Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeX12Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 3, level,users[referrerAddress].x12Matrix[level].reinvestCount);
             
                
            updateX12Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 3, level,users[referrerAddress].x12Matrix[level].reinvestCount);
            
            return sendTRXDividends(userAddress, 1, level);
        }
    }
    
    
    function findFreeX3Referrer(address userAddress, uint256 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeX6Referrer(address userAddress, uint256 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX6Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function findFreeX12Referrer(address userAddress, uint256 level) public view returns(address) {
        while (true) {
            if(users[userAddress].referrer==address(0)){
                return owner;
            }
            if (users[users[userAddress].referrer].activeX12Levels[level]) {
                
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

     function usersActiveX12Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX12Levels[level];
    }


    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked);
    }
    
    function getReferrer(address _useraddress) view external returns(address)
    {
        return users[_useraddress].referrer;
    }

    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].firstLevelReferrals,
                users[userAddress].x6Matrix[level].secondLevelReferrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].closedPart);
    }
    
    
     function usersX12Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory,address[] memory, bool) {
        return (users[userAddress].x12Matrix[level].currentReferrer,
                users[userAddress].x12Matrix[level].firstLevelReferrals,
                users[userAddress].x12Matrix[level].secondLevelReferrals,
                users[userAddress].x12Matrix[level].thirdLevelReferrals,
                users[userAddress].x12Matrix[level].blocked);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

   

    function sendTRXDividends(address userAddress, uint8 matrix, uint256 level) private {
        

       

            if(matrix == 1 || matrix==2)
            {
                require(BUSDaddress.transfer(userAddress,levelPrice[level]),"Error in transfer");
                emit EarningsMatrix(userAddress, levelPrice[level],matrix,level);
            }
            else if(matrix == 3)
            { 
                address ref=users[userAddress].x12Matrix[level].currentReferrer;
                address ref1=users[ref].x12Matrix[level].currentReferrer;
                address ref2=users[ref1].x12Matrix[level].currentReferrer;
                  users[userAddress].x12Matrix[level].noOfPayment++;
               if(ref2!=address(0)){
                   require(BUSDaddress.transfer(ref2,levelPrice[level]),"Error in transfer");
                 
                         emit EarningsMatrix(ref2, levelPrice[level],matrix,level);
               }
               else
               {
                   require(BUSDaddress.transfer(owner,levelPrice[level]),"Error in transfer");
                    emit EarningsMatrix(owner, levelPrice[level],matrix,level);
               }
                    
            }
            
        
        
    }
    
     
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
    
    
  
    function getrefferaladdress(address user) public view returns(address)
    {
        return users[user].referrer;
    }
    
    
}



library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}