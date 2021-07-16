//SourceUnit: VTMLM(1).sol

pragma solidity 0.5.4;
contract Initializable {

  bool private initialized;
  bool private initializing;

  modifier initializer() 
  {
	  require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");
	  bool wasInitializing = initializing;
	  initializing = true;
	  initialized = true;
		_;
	  initializing = wasInitializing;
  }
  function isConstructor() private view returns (bool) 
  {
  uint256 cs;
  assembly { cs := extcodesize(address) }
  return cs == 0;
  }
  uint256[50] private __gap;

}

contract Ownable is Initializable {
  address public _owner;
  uint256 private _ownershipLocked;
  event OwnershipLocked(address lockedOwner);
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
  address indexed previousOwner,
  address indexed newOwner
	);
  function initialize(address sender) internal initializer {
   _owner = sender;
   _ownershipLocked = 0;

  }
  function ownerr() public view returns(address) {
   return _owner;

  }

  modifier onlyOwner() {
    require(isOwner());
    _;

  }

  function isOwner() public view returns(bool) {
  return msg.sender == _owner;
  }

  function transferOwnership(address newOwner) public onlyOwner {
   _transferOwnership(newOwner);

  }
  function _transferOwnership(address newOwner) internal {
    require(_ownershipLocked == 0);
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;

  }

  // Set _ownershipLocked flag to lock contract owner forever

  function lockOwnership() public onlyOwner {
    require(_ownershipLocked == 0);
    emit OwnershipLocked(_owner);
    _ownershipLocked = 1;
  }

  uint256[50] private __gap;

}

interface ITRC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender)
  external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value)
  external returns (bool);
  
  function transferFrom(address from, address to, uint256 value)
  external returns (bool);
  function burn(uint256 value)
  external returns (bool);
  event Transfer(address indexed from,address indexed to,uint256 value);
  event Approval(address indexed owner,address indexed spender,uint256 value);
}

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
   
contract VAULT_TOKEN is Ownable {
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
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX6Levels;
        mapping(uint8 => bool) activeX5Levels;
        uint256 planCount;
        mapping(uint256 => Investment) plans;
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;
        mapping(uint8 => X5) x5Matrix;
		uint256 nextBuy;
		uint256 nextSale;
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
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    
    

    uint public lastUserId = 2;
    uint public token_price = 1000;
    
    uint public  tbuy = 0;
	uint public  tsale = 0;
    uint public  vbuy = 0;
	uint public  vsale = 0;
	
	uint public  MINIMUM_BUY = 50 trx;
	uint public  MINIMUM_SALE = 50;
	
    uint public  MAXIMUM_BUY = 600 trx;
	uint public  MAXIMUM_SALE = 600;
	
	
    address public owner;
    
    mapping(uint8 => uint) public levelPrice;

  
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    
    event MissedEthReceive(address indexed receiver, address indexed _from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed _from, address indexed receiver, uint8 matrix, uint8 level);
    
    event TokenPriceHistory(uint  previous, uint indexed inc_desc, uint new_price, uint8 type_of);
    
    event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint live_rate);
    event onWithdraw(address investor, uint256 amount);
    
   //For Token Transfer
   
   ITRC20 private VAULTTOKEN; 
   event onBuy(address buyer , uint256 amount);
   mapping(address => uint256) public boughtOf;

    constructor(address ownerAddress,ITRC20 _VAULTTOKEN) public 
    {
        levelPrice[1] = 200 trx;
        levelPrice[2] = 400 trx;
        levelPrice[3] = 800 trx;
        levelPrice[4] = 1600 trx;
        levelPrice[5] = 3200 trx;
        levelPrice[6] = 6400 trx;
        levelPrice[7] = 12800 trx;
        levelPrice[8] = 25600 trx;
        levelPrice[9] = 51200 trx;
        levelPrice[10] = 102400 trx;
        levelPrice[11] = 204800 trx;
        levelPrice[12] = 409600 trx;

       
               
        owner = ownerAddress;
        
        VAULTTOKEN = _VAULTTOKEN;
        
        Ownable.initialize(msg.sender);
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            planCount: uint(0),
            nextBuy: uint(0),
            nextSale: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeX3Levels[i] = true;
            users[ownerAddress].activeX6Levels[i] = true;
            users[ownerAddress].activeX5Levels[i] = true;
        }   
    }
    
    function() external payable 
    {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

   

    function withdrawLostTRXFromBalance() public 
    {
        require(msg.sender == owner, "onlyOwner");
        msg.sender.transfer(address(this).balance);
    }


    function registrationExt(address referrerAddress) external payable 
    {
        registration(msg.sender, referrerAddress);
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        
        require(matrix == 1 || matrix == 2 || matrix == 3, "invalid matrix");
        
		uint matrixPrice=((levelPrice[level])+(levelPrice[level]*5)/100);
        if(matrix == 1 || matrix == 2 || matrix == 3)
        require(msg.value == matrixPrice, "invalid price");

        
        if(matrix == 1 || matrix == 2)
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
        
        if(matrix == 3)
        require(level >= 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1 || matrix == 2) 
        {
            require(users[msg.sender].activeX3Levels[level-1], "buy previous level first");
            require(!users[msg.sender].activeX3Levels[level], "level already activated"); 
            require(users[msg.sender].activeX6Levels[level-1], "buy previous level first");
            require(!users[msg.sender].activeX6Levels[level], "level already activated"); 

            if (users[msg.sender].x3Matrix[level-1].blocked) {
                users[msg.sender].x3Matrix[level-1].blocked = false;
            }
    
            address freeX3Referrer = findFreeX3Referrer(msg.sender, level);
            users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[msg.sender].activeX3Levels[level] = true;
            updateX3Referrer(msg.sender, freeX3Referrer, level);
            
            emit Upgrade(msg.sender, freeX3Referrer, 1, level);

    

            if (users[msg.sender].x6Matrix[level-1].blocked) {
                users[msg.sender].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(msg.sender, level);
            
            users[msg.sender].activeX6Levels[level] = true;
            updateX6Referrer(msg.sender, freeX6Referrer, level);
            
           
                    uint V4Toekn=(((levelPrice[level])-((levelPrice[level])*5)/100)*60)/100;
                    uint selfToekn=(((V4Toekn)*90/100)/token_price)*1000;
            	    VAULTTOKEN.transfer(msg.sender , (selfToekn*100));
            		emit TokenDistribution(address(this), msg.sender, selfToekn*100, token_price);
            
            
            emit Upgrade(msg.sender, freeX6Referrer, 2, level);
        }
        else
        {
            require(!users[msg.sender].activeX5Levels[level], "level already activated");  
            if(level>1)
            {
            require(users[msg.sender].activeX5Levels[level-1], "buy previous level first");
            require(!users[msg.sender].activeX5Levels[level], "level already activated");      
            

            if (users[msg.sender].x5Matrix[level-1].blocked) {
                users[msg.sender].x5Matrix[level-1].blocked = false;
            }
            }
 
            
            uint roi_trx=(levelPrice[level]*60)/100;
            uint bonus_trx=(roi_trx*200)/100;
            uint total_trx=roi_trx+bonus_trx;
            
            uint256 planCount = users[msg.sender].planCount;
            users[msg.sender].plans[planCount].planId = 1;
            users[msg.sender].plans[planCount].investmentDate = block.timestamp;
            users[msg.sender].plans[planCount].lastWithdrawalDate = block.timestamp;
            users[msg.sender].plans[planCount].investment = total_trx;
            users[msg.sender].plans[planCount].currentDividends = 0;
            users[msg.sender].plans[planCount].isExpired = false;
            users[msg.sender].planCount = users[msg.sender].planCount.add(1);
            
    
            address freeX5Referrer = findFreeX5Referrer(msg.sender, level);
            users[msg.sender].x5Matrix[level].currentReferrer = freeX5Referrer;
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

     
            require(msg.value == ((levelPrice[currentStartingLevel])+10 trx), "invalid registration cost");
       
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            planCount: 0,
            nextSale: 0,
            nextBuy: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeX3Levels[1] = true; 
        users[userAddress].activeX6Levels[1] = true;
        
        lastUserId++;
        vbuy++;
        tbuy++;
        users[referrerAddress].partnersCount++;

        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateX3Referrer(userAddress, freeX3Referrer, 1);

        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1); 
        
        uint V4Toekn=(((levelPrice[1])-((levelPrice[1])*5)/100)*60)/100;
        uint selfToekn=(((V4Toekn)*90/100)/token_price)*1000;
	    VAULTTOKEN.transfer(userAddress , (selfToekn*100));
		emit TokenDistribution(address(this), userAddress, selfToekn*100, token_price);
        
        
        if(vbuy>=8)
        {
            emit TokenPriceHistory(token_price, 10, token_price+10, 1); 
            token_price=token_price+10;
            vbuy=vbuy-8;
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
    
    
       function updateX5Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].x5Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x5Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 3, level, uint8(users[referrerAddress].x5Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 3, level);
           
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 3, level, 3);
        //close matrix
        users[referrerAddress].x5Matrix[level].referrals = new address[](0);
         if (!users[referrerAddress].activeX5Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x5Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeX5Referrer(referrerAddress,level);
            if (users[referrerAddress].x5Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].x5Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].x5Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 3, level);
            updateX5Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            //users[owner].dividends_balance=users[owner].dividends_balance.add((levelPrice[level]*40)/100);
            users[owner].x5Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 3, level);
        }
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
    
    function findFreeX5Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX5Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
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
    
    
     function usersX5Investment(address userAddress, uint8 plan) public view returns(uint256,uint256,uint256,uint256,uint256,bool) {
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
        }
        else if (matrix == 3) {
            while (true) {
                if (users[receiver].x5Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 3, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x5Matrix[level].currentReferrer;
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

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);
		
		if(matrix==1)
		{
		   
			uint uplineAmount=(((levelPrice[level])-((levelPrice[level])*5)/100)*40)/100;
			if (!address(uint160(receiver)).send(uplineAmount))
			{
           // address(uint160(owner)).send(address(this).balance);
            }
            
            if (isExtraDividends) {
                emit SentExtraEthDividends(_from, receiver, matrix, level);
            }
			
		}
		else if(matrix==2)
		{
		 
			uint V4Toekn=(((levelPrice[level])-((levelPrice[level])*5)/100)*60)/100;
			
			uint uplineToken=(((V4Toekn)*10/100)/token_price)*1000;
			

			//for Receiver Upline
			VAULTTOKEN.transfer(receiver , (uplineToken*100));			
		    emit TokenDistribution(address(this), receiver, uplineToken*100, token_price);	
			 if (isExtraDividends) {
                emit SentExtraEthDividends(_from, receiver, matrix, level);
            }
		}
		else
		{
		   
		   // users[receiver].dividends_balance=users[receiver].dividends_balance.add((levelPrice[level]*40)/100);
		    uint256 planCount = users[receiver].planCount;
            users[receiver].plans[planCount].planId = 1;
            users[receiver].plans[planCount].investmentDate = block.timestamp;
            users[receiver].plans[planCount].lastWithdrawalDate = block.timestamp;
            users[receiver].plans[planCount].investment =(levelPrice[level]*40)/100;
            users[receiver].plans[planCount].currentDividends = 0;
            users[receiver].plans[planCount].isExpired = false;
            users[receiver].planCount = users[receiver].planCount.add(1);
            
            if (isExtraDividends) {
                emit SentExtraEthDividends(_from, receiver, matrix, level);
            }
			
		}
      
    }
    
	 function buyToken(uint tokenQty) public payable {
					
				require(users[msg.sender].nextBuy<=now,'Next Buy available after 24 hours');
	            require(msg.value>=MINIMUM_BUY,"Invalid minimum quatity");
	            require(msg.value<=MAXIMUM_BUY,"Invalid maximum quatity");
	            
	            uint trx_amt=((tokenQty+(tokenQty*83)/100)*(token_price)/1000)*1000000;
	            
	            require(msg.value>=trx_amt,"Invalid buy amount");
			    users[msg.sender].nextBuy=now+(24*60*60);
				VAULTTOKEN.transfer(msg.sender , (tokenQty*100000000));
				 emit TokenDistribution(address(this), msg.sender, tokenQty*100000000, token_price);	
				// vbuy=vbuy+tokenQty;
			 //   tbuy=tbuy+tokenQty;
				// if(vbuy>=600)
    //             {
    //               emit TokenPriceHistory(token_price, 10, token_price+10, 1);  
    //               token_price=token_price+10;
    //                 vbuy=vbuy-600;
    //             }
	 }
	 
	function sellToken(address userAddress,uint tokenQty) public payable 
	{
	    require(users[msg.sender].nextSale<=now,'Next Buy available after 24 hours');
	          require(tokenQty>=MINIMUM_SALE,"Invalid minimum quatity");
	            require(tokenQty<=MAXIMUM_SALE,"Invalid maximum quatity");
	     
			uint trx_amt=((tokenQty-(tokenQty*5)/100)*(token_price)/100)*100000;
	        
			VAULTTOKEN.approve(userAddress,(tokenQty*1000000));
			VAULTTOKEN.transferFrom(userAddress ,address(this), (tokenQty*100000000));
			address(uint160(msg.sender)).send(trx_amt);
			emit TokenDistribution(userAddress,address(this), tokenQty*100000000, token_price);
			vsale=vsale+tokenQty;
			tsale=tsale+tokenQty;
			if(vsale>=2000)
            {
                //uint 
                if(token_price>1000)
                {
                emit TokenPriceHistory(token_price,10, token_price-10, 0); 
                token_price=token_price-10;
                vsale=vsale-2000;
                }
            }
              users[msg.sender].nextSale=now+(24*60*60);
	 }
	 
	
	
     function get_dividends(address _userAddress) public view returns (uint256[] memory, uint256[] memory) {
       
        uint256[] memory newDividends = new uint256[](users[_userAddress].planCount);
        uint256[] memory currentDividends = new  uint256[](users[_userAddress].planCount);
        for (uint256 i = 0; i < users[_userAddress].planCount; i++) 
        {
            require(users[_userAddress].plans[i].investmentDate != 0, "wrong investment date");
            currentDividends[i] = users[_userAddress].plans[i].currentDividends;
            if (users[_userAddress].plans[i].isExpired) 
            {
                newDividends[i] = 0;
            } 
            else 
            {
                if(true) 
                {
                    if (block.timestamp >= users[_userAddress].plans[i].investmentDate.add(100*60*60*24)) 
                    {
                        newDividends[i] = _calculateDividends(users[_userAddress].plans[i].investment, 10, users[_userAddress].plans[i].investmentDate.add(100*60*60*24), users[_userAddress].plans[i].lastWithdrawalDate, 10);
                    } 
                    else 
                    {
                        newDividends[i] = _calculateDividends(users[_userAddress].plans[i].investment, 10, block.timestamp, users[_userAddress].plans[i].lastWithdrawalDate, 10);
                    }
                } 
                else 
                {
                   // newDividends[i] = _calculateDividends(users[_userAddress].plans[i].investment, investmentPlans_[users[_userAddress].plans[i].planId].dailyInterest, block.timestamp, users[_userAddress].plans[i].lastWithdrawalDate, investmentPlans_[users[_userAddress].plans[i].planId].maxDailyInterest);
                }
            }
        }
        return
        (
         currentDividends,
         newDividends
        );
    }
	
	 
	 
    
    function _calculateDividends(uint256 _amount, uint256 _dailyInterestRate, uint256 _now, uint256 _start , uint256 _maxDailyInterest) private pure returns (uint256) {

        uint256 numberOfDays =  (_now - _start) / INTEREST_CYCLE ;
        uint256 result = 0;
        uint256 index = 0;
        if(numberOfDays > 0){
          uint256 secondsLeft = (_now - _start);
           for (index; index < numberOfDays; index++) {
               if(_dailyInterestRate + index <= _maxDailyInterest ){
                   secondsLeft -= INTEREST_CYCLE;
                     result += (_amount * (_dailyInterestRate + index) / 1000 * INTEREST_CYCLE) / (60*60*24);
               }
               else
               {
                 break;
               }
            }

            result += (_amount * (_dailyInterestRate + index) / 1000 * secondsLeft) / (60*60*24);

            return result;

        }else{
            return (_amount * _dailyInterestRate / 1000 * (_now - _start)) / (60*60*24);
        }

    }
  
    function withdraw() public payable {
        require(msg.value == 0, "withdrawal doesn't allow to transfer trx simultaneously");
        require(users[msg.sender].activeX5Levels[1], "Can not withdraw because no any investments");
        uint256 withdrawalAmount = 0;
        for (uint256 i = 0; i < users[msg.sender].planCount; i++) 
        {
            if (users[msg.sender].plans[i].isExpired) {
                continue;
            }


            bool isExpired = false;
            uint256 withdrawalDate = block.timestamp;
         
                uint256 endTime = users[msg.sender].plans[i].investmentDate.add(100*60*60*24);
                if (withdrawalDate >= endTime) {
                    withdrawalDate = endTime;
                    isExpired = true;
                }

            uint256 amount = _calculateDividends(users[msg.sender].plans[i].investment , 10 , withdrawalDate , users[msg.sender].plans[i].lastWithdrawalDate , 10);

            withdrawalAmount += amount;

            users[msg.sender].plans[i].lastWithdrawalDate = withdrawalDate;
            users[msg.sender].plans[i].isExpired = isExpired;
            users[msg.sender].plans[i].currentDividends += amount;
        }
        
         msg.sender.transfer(withdrawalAmount);
   
        emit onWithdraw(msg.sender, withdrawalAmount);
    }
        
        
        function token_setting(uint min_buy, uint max_buy, uint min_sale, uint max_sale) public payable
        {
           require(msg.sender==owner,"Only Owner");
              MINIMUM_BUY = min_buy*1 trx;
    	      MINIMUM_SALE = min_sale;
              MAXIMUM_BUY = max_buy*1 trx;
              MAXIMUM_SALE = max_sale; 
        }
        
        
          function active_level(address userAddress, uint level) public payable
        {
           require(msg.sender==owner,"Only Owner");
              for (uint8 i = 1; i <= level; i++) {
            users[userAddress].activeX3Levels[i] = true;
            users[userAddress].activeX6Levels[i] = true;
            users[userAddress].activeX5Levels[i] = true;
        } 
        }
        
        
         
		
		  
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}