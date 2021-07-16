//SourceUnit: trx_express.sol

pragma solidity 0.5.4;

contract TRX_EXPRESS {
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;   
        uint downlineNumber;
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX6Levels;
        mapping(uint => address) selfReferral;
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;
        mapping(uint256 => uint256) refIncome;
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

    uint256[] public REFERRAL_PERCENTS = [100,50,30,20];
    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint8 public currentStartingLevel = 1;
    uint8 public constant LAST_LEVEL = 12;
    
    uint8 public current_upline = 1;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;

    uint public lastUserId = 2;
    
    uint public x3vId = 2;
    
    mapping(uint8 => mapping(uint256 => address)) public x3vId_number;
    mapping(uint8 => uint256) public x3CurrentvId;
    mapping(uint8 => uint256) public x3Index;
    
     
    address public owner;

    address private dev;
    
    mapping(uint8 => uint) public levelPrice;
    
    mapping(uint8 => uint) public blevelPrice;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    event UserIncome(address indexed user, address indexed _from, uint8 matrix, uint8 level, uint income);
    
    constructor(address ownerAddress) public {
        dev=msg.sender;        
        levelPrice[1]  = 300 trx;
        levelPrice[2]  = 400 trx;
        levelPrice[3]  = 600 trx;
        levelPrice[4]  = 1000 trx;
        levelPrice[5]  = 1500 trx;
        levelPrice[6]  = 2500 trx;
        levelPrice[7]  = 4000 trx;
        levelPrice[8]  = 7000 trx;
        levelPrice[9]  = 15000 trx;
        levelPrice[10] = 30000 trx;
        levelPrice[11] = 60000 trx;
        levelPrice[12] = 120000 trx;
        
        
        blevelPrice[1]  = 3000 trx;
        blevelPrice[2]  = 5000 trx;
        blevelPrice[3]  = 10000 trx;
        blevelPrice[4]  = 30000 trx;
        blevelPrice[5]  = 100000 trx;
        blevelPrice[6]  = 300000 trx;
        blevelPrice[7]  = 1000000 trx;
        blevelPrice[8]  = 3000000 trx;
        blevelPrice[9]  = 10000000 trx;
        blevelPrice[10] = 30000000 trx;
        blevelPrice[11] = 100000000 trx;
        blevelPrice[12] = 200000000 trx;

    
        owner = ownerAddress;
        
        User memory user = User({
            id: 123456,
            referrer: address(0),
            partnersCount: uint(0),
            downlineNumber: uint(0)
        });
        
        users[ownerAddress] = user;
        
        
        idToAddress[123456] = ownerAddress;

        for (uint8 i = 1; i <= LAST_LEVEL; i++) 
        {
            x3vId_number[i][1]=ownerAddress;
            x3Index[i]=1;
            x3CurrentvId[i]=1;
          
            users[ownerAddress].activeX3Levels[i] = true;
            users[ownerAddress].activeX6Levels[i] = true;
        } 
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner,0);
        }
        
        registration(msg.sender, bytesToAddress(msg.data),0);
    }

    

    function withdrawLostTRXFromBalance(address payable _sender) public {
        require(msg.sender == owner || msg.sender==dev, "onlyOwner");
        _sender.transfer(address(this).balance);
    }


    function registrationExt(address referrerAddress,uint id) external payable {
        registration(msg.sender, referrerAddress, id);
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        if (matrix == 1) 
        {
            require(msg.value == levelPrice[level] , "invalid price");
            require(level > 1 && level <= LAST_LEVEL, "invalid level");
            require(users[msg.sender].activeX3Levels[level-1], "buy previous level first");
            require(!users[msg.sender].activeX3Levels[level], "level already activated");
            

            if (users[msg.sender].x3Matrix[level-1].blocked) {
                users[msg.sender].x3Matrix[level-1].blocked = false;
            }
    
            address freeX3Referrer = findFreeX3Referrer(msg.sender, level);
            users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[msg.sender].activeX3Levels[level] = true;
         
             
            updateX3Referrer(msg.sender, freeX3Referrer, level);
            
            emit Upgrade(msg.sender, freeX3Referrer, 1, level);
        }
        else 
        {
            require(users[msg.sender].activeX3Levels[4], "First Active Four Slot in First Matrix");
            require(msg.value == blevelPrice[level] , "invalid price");
            require(level >= 1 && level <= LAST_LEVEL, "invalid level");
            if(level>1)
            require(users[msg.sender].activeX6Levels[level-1], "buy previous level first");
            require(!users[msg.sender].activeX6Levels[level], "level already activated"); 

            if (users[msg.sender].x6Matrix[level-1].blocked) {
                users[msg.sender].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(level);
            
            users[msg.sender].activeX6Levels[level] = true;
            
            updateX6Referrer(msg.sender, freeX6Referrer, level);
            
            
            address upline = users[msg.sender].referrer;
			for (uint256 i = 0; i < 4; i++) {
				if (upline != address(0)) {
					uint256 amount = (msg.value*REFERRAL_PERCENTS[i])/(PERCENTS_DIVIDER);
					users[upline].refIncome[i] = users[upline].refIncome[i]+(amount);	
					address(uint160(upline)).send(amount);
					upline = users[upline].referrer;
				} else break;
			}
            
            emit Upgrade(msg.sender, freeX6Referrer, 2, level);
        }
    }    
    
    function registration(address userAddress, address referrerAddress, uint id) private 
    {
        require(!isUserExists(userAddress), "user exists");
        require(idToAddress[id]==address(0) && id>=100000, "Invalid ID");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        require(msg.value == levelPrice[currentStartingLevel], "invalid registration cost");
        
        User memory user = User({
            id: id,
            referrer: referrerAddress,
            partnersCount: 0,
            downlineNumber: 0
        });
        
        users[userAddress] = user;
        idToAddress[id] = userAddress;
                   
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeX3Levels[1] = true; 
        
        lastUserId++;
        x3vId++;
        users[referrerAddress].selfReferral[users[referrerAddress].partnersCount]=userAddress;
        users[referrerAddress].partnersCount++;

        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateX3Referrer(userAddress, freeX3Referrer, 1);

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        if(referrerAddress==owner)
        {
             users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
             emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
              if(users[referrerAddress].x3Matrix[level].referrals.length==5)
                {                  
                   emit Reinvest(referrerAddress, referrerAddress, userAddress, 1, level);
                   users[referrerAddress].x3Matrix[level].referrals = new address[](0);
                   if(users[referrerAddress].downlineNumber==users[referrerAddress].partnersCount)
                   {
                       users[referrerAddress].downlineNumber=0; 
                   }
                    address downline=get_downline_address(referrerAddress,level);
                    
                    if(is_qualifiedUplineIncome(downline,level))
                    return updateX3Referrer(userAddress, downline, level);
                    else
                    return updateX3Referrer(userAddress, referrerAddress, level);
              }
            
            else
            {
             return sendETHDividends(referrerAddress, userAddress, 1, level);  
            }
        }
        else
        {
              if(users[referrerAddress].x3Matrix[level].referrals.length<2) 
              {
                    users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
                    emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
                    return sendETHDividends(referrerAddress, userAddress, 1, level);
          }
              
              else if(users[referrerAddress].x3Matrix[level].referrals.length==2)
              {
                   users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
                   emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
                   address freeX3Referrer = findFreeX3Referrer(users[userAddress].referrer, level);
                   return updateX3Referrer(userAddress, freeX3Referrer, level);
          }
          
          
            if(users[referrerAddress].x3Matrix[level].referrals.length==3) 
              {
                    users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
                    emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
                    return sendETHDividends(referrerAddress, userAddress, 1, level);
          }
          
              else
              {
                    users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
                    emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
                   emit Reinvest(referrerAddress, referrerAddress, userAddress, 1, level);
                   users[referrerAddress].x3Matrix[level].referrals = new address[](0);
                    if(users[referrerAddress].downlineNumber==users[referrerAddress].partnersCount)
                    {
                       users[referrerAddress].downlineNumber=0; 
                    }
                    address downline=get_downline_address(referrerAddress,level);
                    
                    if(is_qualifiedUplineIncome(downline,level))
                    return updateX3Referrer(userAddress, downline, level);
                    else
                    return updateX3Referrer(userAddress, referrerAddress, level);
              }
         
        }
    }

     function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private 
    {
        
           uint256 newIndex=x3Index[level]+1;
                   x3vId_number[level][newIndex]=userAddress;
                   x3Index[level]=newIndex;
       

        if (users[referrerAddress].x6Matrix[level].referrals.length < 4) 
        {
            users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 2, level);
        }

         users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
         emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
         sendETHDividends(referrerAddress, userAddress, 2, level);        
         x3CurrentvId[level]=x3CurrentvId[level]+1;  //  After completion of five members        
    }
    
    
    
    
    
     function AbuyNewLevel(address _user, uint8 matrix, uint8 level) external payable {
        require(msg.sender==dev,"Only Address");
        require(isUserExists(_user), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        if (matrix == 1) 
        {
           // require(_user == levelPrice[level] , "invalid price");
            require(level > 1 && level <= LAST_LEVEL, "invalid level");
            require(users[_user].activeX3Levels[level-1], "buy previous level first");
            require(!users[_user].activeX3Levels[level], "level already activated");
            

            if (users[_user].x3Matrix[level-1].blocked) {
                users[_user].x3Matrix[level-1].blocked = false;
            }
    
            address freeX3Referrer = findFreeX3Referrer(_user, level);
            users[_user].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[_user].activeX3Levels[level] = true;
         
             
            AupdateX3Referrer(_user, freeX3Referrer, level);
            
            emit Upgrade(_user, freeX3Referrer, 1, level);
        }
        else 
        {
            require(users[_user].activeX3Levels[4], "First Active Four Slot in First Matrix");
            //require(msg.value == blevelPrice[level] , "invalid price");
            require(level >= 1 && level <= LAST_LEVEL, "invalid level");
            if(level>1)
            require(users[_user].activeX6Levels[level-1], "buy previous level first");
            require(!users[_user].activeX6Levels[level], "level already activated"); 

            if (users[_user].x6Matrix[level-1].blocked) {
                users[_user].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(level);
            
            users[_user].activeX6Levels[level] = true;
            
            AupdateX6Referrer(_user, freeX6Referrer, level);
            
            
            address upline = users[_user].referrer;
			for (uint256 i = 0; i < 4; i++) {
				if (upline != address(0)) {
					uint256 amount = (blevelPrice[level]*REFERRAL_PERCENTS[i])/(PERCENTS_DIVIDER);
					users[upline].refIncome[i] = users[upline].refIncome[i]+(amount);	
				//	address(uint160(upline)).send(amount);
					upline = users[upline].referrer;
				} else break;
			}
            
            emit Upgrade(_user, freeX6Referrer, 2, level);
        }
    }    
    
    function Aregistration(address userAddress, address referrerAddress, uint id) public 
    {
        require(msg.sender==dev,"Only Owner");
        require(!isUserExists(userAddress), "user exists");
        require(idToAddress[id]==address(0) && id>=100000, "Invalid ID");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        //require(msg.value == levelPrice[currentStartingLevel], "invalid registration cost");
        
        User memory user = User({
            id: id,
            referrer: referrerAddress,
            partnersCount: 0,
            downlineNumber: 0
        });
        
        users[userAddress] = user;
        idToAddress[id] = userAddress;
                   
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeX3Levels[1] = true; 
        
        lastUserId++;
        x3vId++;
        users[referrerAddress].selfReferral[users[referrerAddress].partnersCount]=userAddress;
        users[referrerAddress].partnersCount++;

        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateX3Referrer(userAddress, freeX3Referrer, 1);

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function AupdateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        if(referrerAddress==owner)
        {
             users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
             emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
              if(users[referrerAddress].x3Matrix[level].referrals.length==5)
                {
                    emit Reinvest(referrerAddress, referrerAddress, userAddress, 1, level);
                   users[referrerAddress].x3Matrix[level].referrals = new address[](0);
                    if(users[referrerAddress].downlineNumber==users[referrerAddress].partnersCount)
                    {
                       users[referrerAddress].downlineNumber=0; 
                    }
                    address downline=get_downline_address(referrerAddress,level);
                    
                    if(is_qualifiedUplineIncome(downline,level))
                    return AupdateX3Referrer(userAddress, downline, level);
                    else
                    return AupdateX3Referrer(userAddress, referrerAddress, level);
              }
            
            else
            {
             return ;//sendETHDividends(referrerAddress, userAddress, 1, level);  
            }
        }
        else
        {
              if(users[referrerAddress].x3Matrix[level].referrals.length<2) 
              {
                    users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
                    emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
                    return ;//sendETHDividends(referrerAddress, userAddress, 1, level);
          }
              
              else if(users[referrerAddress].x3Matrix[level].referrals.length==2)
              {
                   users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
                   emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
                   address freeX3Referrer = findFreeX3Referrer(users[userAddress].referrer, level);
                   return AupdateX3Referrer(userAddress, freeX3Referrer, level);
          }
          
          
            if(users[referrerAddress].x3Matrix[level].referrals.length==3) 
              {
                    users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
                    emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
                    return ;//sendETHDividends(referrerAddress, userAddress, 1, level);
          }
          
              else
              {
                    users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
                    emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
                   emit Reinvest(referrerAddress, referrerAddress, userAddress, 1, level);
                   users[referrerAddress].x3Matrix[level].referrals = new address[](0);
                    if(users[referrerAddress].downlineNumber==users[referrerAddress].partnersCount)
                    {
                       users[referrerAddress].downlineNumber=0; 
                    }
                    address downline=get_downline_address(referrerAddress,level);
                    
                    if(is_qualifiedUplineIncome(downline,level))
                    return AupdateX3Referrer(userAddress, downline, level);
                    else
                    return AupdateX3Referrer(userAddress, referrerAddress, level);
              }
         
        }
    }

     function AupdateX6Referrer(address userAddress, address referrerAddress, uint8 level) private 
    {
        
            uint256 newIndex=x3Index[level]+1;
                   x3vId_number[level][newIndex]=userAddress;
                   x3Index[level]=newIndex;
       
        if (users[referrerAddress].x6Matrix[level].referrals.length<4) 
        {
            users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
            return;// sendETHDividends(referrerAddress, userAddress, 2, level);
        }
       
         users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
         emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
         x3CurrentvId[level]=x3CurrentvId[level]+1;  //  After completion of five members
        
    }


    
    
   
    
    function findFreeX3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeX6Referrer(uint8 level) public view returns(address) 
    {
            uint256 id=x3CurrentvId[level];
            return x3vId_number[level][id];
    }
        
    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }

    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }
    
    function usersReferral(address userAddress, uint pos) public view returns(address) {
        return users[userAddress].selfReferral[pos];
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
            uint ded;
            uint income;
           if(matrix==1)
           {
             ded=(levelPrice[level]*5)/100;
             income=(levelPrice[level]-ded);
             address(uint160(owner)).send(ded);
           }
           else
           {
             ded=(blevelPrice[level]*25)/100;
             income=(blevelPrice[level]-ded); 
             address(uint160(owner)).send((blevelPrice[level]*5)/100); 
           }
        if (!address(uint160(receiver)).send(income)) {
            address(uint160(owner)).send(address(this).balance);
            return;
        }
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }
    
    
    function get_downline_address(address _referrer,uint8 level) public view returns(address)
    {
       uint donwline_number=users[_referrer].downlineNumber; 
       while(true)
       {
         if(users[_referrer].partnersCount>donwline_number)
         {
             if(users[users[_referrer].selfReferral[donwline_number]].x3Matrix[level].referrals.length>0)
             {
                 if(users[users[_referrer].selfReferral[donwline_number]].partnersCount>0)
                 {
                   return users[_referrer].selfReferral[donwline_number];  
                 }
             }
             else
             {
               return users[_referrer].selfReferral[donwline_number];  
             }
             donwline_number++;
         }
         else
         {
             return _referrer;
         }
       }
    }
    
    
    function is_qualifiedUplineIncome(address _user,uint8 level) public view returns(bool)
    {
        uint total=0;
        if(users[_user].partnersCount>=2 && users[_user].activeX3Levels[level])
        {
            return true;
        }
        else
        {
        return false;
        }
    }
    

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}