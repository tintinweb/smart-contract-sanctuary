//SourceUnit: tron_bsc.sol

pragma solidity ^0.5.9;

contract TRON_BSC {
    
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
    uint8 public constant LAST_LEVEL = 12;
    
    uint8 public current_upline = 1;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;

    uint public lastUserId = 2;
    
    uint public x3vId = 2;
    
    mapping(uint8 => mapping(uint256 => address)) public x3vId_number;
    mapping(uint8 => uint256) public x3CurrentvId;
    mapping(uint8 => uint256) public x3Index;
    
    uint public clubvId = 2;
    
    mapping(uint8 => mapping(uint256 => address)) public clubvId_number;
    mapping(uint8 => uint256) public clubCurrentvId;
    mapping(uint8 => uint256) public clubIndex;
    
    
    uint public sClubvId = 2;
    
    mapping(uint8 => mapping(uint256 => address)) public sClubvId_number;
    mapping(uint8 => uint256) public sClubCurrentvId;
    mapping(uint8 => uint256) public sClubIndex;
    
    address public owner;
    
    mapping(uint8 => uint) public levelPrice;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    event UserIncome(address indexed user, address indexed _from, uint8 matrix, uint8 level, uint income);
    
    constructor(address ownerAddress) public {
        levelPrice[1]  = 50 trx;
        levelPrice[2]  = 100 trx;
        levelPrice[3]  = 200 trx;
        levelPrice[4]  = 400 trx;
        levelPrice[5]  = 800 trx;
        levelPrice[6]  = 1600 trx;
        levelPrice[7]  = 3200 trx;
        levelPrice[8]  = 6400 trx;
        levelPrice[9]  = 12800 trx;
        levelPrice[10] = 25600 trx;
        levelPrice[11] = 51200 trx;
        levelPrice[12] = 102400 trx;

    
        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            downlineNumber: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;

        for (uint8 i = 1; i <= LAST_LEVEL; i++) 
        {
            x3vId_number[i][1]=ownerAddress;
            x3Index[i]=1;
            x3CurrentvId[i]=1;
            
            clubvId_number[i][1]=ownerAddress;
            clubIndex[i]=1;
            clubCurrentvId[i]=1;
            
            sClubvId_number[i][1]=ownerAddress;
            sClubIndex[i]=1;
            sClubCurrentvId[i]=1;
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
        require(msg.value == levelPrice[level] , "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) 
        {
            require(users[msg.sender].activeX3Levels[level-1], "buy previous level first");
            require(!users[msg.sender].activeX3Levels[level], "level already activated");
            

            if (users[msg.sender].x3Matrix[level-1].blocked) {
                users[msg.sender].x3Matrix[level-1].blocked = false;
            }
    
            address freeX3Referrer = findFreeX3Referrer(msg.sender, level);
            users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[msg.sender].activeX3Levels[level] = true;
             if(users[msg.sender].partnersCount>=5)
             {
               addToClub(msg.sender, 1, level);  
             }
              if(users[msg.sender].partnersCount>=20)
             {
               addToClub(msg.sender, 2, level);  
             }
             
            updateX3Referrer(msg.sender, freeX3Referrer, level);
             uint ded=(levelPrice[level]*10)/100;
            sendClubIncome(msg.sender, 2, level,ded);
            emit Upgrade(msg.sender, freeX3Referrer, 1, level);
        }
        else 
        {
            require(users[msg.sender].activeX6Levels[level-1], "buy previous level first");
            require(!users[msg.sender].activeX6Levels[level], "level already activated"); 
            require(users[msg.sender].partnersCount>1, "Two Direct Needed"); 

            if (users[msg.sender].x6Matrix[level-1].blocked) {
                users[msg.sender].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(level);
            
            users[msg.sender].activeX6Levels[level] = true;
            
            updateX6Referrer(msg.sender, freeX6Referrer, level);
             uint ded=(levelPrice[level]*10)/100;
            sendClubIncome(msg.sender, 2, level,ded);
            emit Upgrade(msg.sender, freeX6Referrer, 2, level);
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
        require(msg.value == levelPrice[currentStartingLevel]*2, "invalid registration cost");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            downlineNumber: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        uint256 newIndex=x3Index[1]+1;
        x3vId_number[1][newIndex]=userAddress;
        x3Index[1]=newIndex;
                   
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeX3Levels[1] = true; 
        users[userAddress].activeX6Levels[1] = true;
        
        lastUserId++;
        x3vId++;
        users[referrerAddress].selfReferral[users[referrerAddress].partnersCount]=userAddress;
        users[referrerAddress].partnersCount++;
        if(users[referrerAddress].partnersCount==5 && referrerAddress!=owner)
        {
            uint8 actlevel=1;
            while(users[referrerAddress].activeX3Levels[actlevel] && actlevel<13)
            {
                addToClub(referrerAddress, 1, actlevel); 
                actlevel++;
            }
        }
        
        
        if(users[referrerAddress].partnersCount==20 && referrerAddress!=owner)
        {
            uint8 actlevel=1;
            while(users[referrerAddress].activeX3Levels[actlevel] && actlevel<13)
            {
                addToClub(referrerAddress, 2, actlevel); 
                actlevel++;
            }
        }

        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateX3Referrer(userAddress, freeX3Referrer, 1);

        updateX6Referrer(userAddress, findFreeX6Referrer(1), 1);
            uint ded=(levelPrice[1]*2*10)/100;
            sendClubIncome(userAddress, 2, 1,ded);
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        if(referrerAddress==owner)
        {
             users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
             emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
              if(users[referrerAddress].x3Matrix[level].referrals.length==4)
                {
                    if(users[referrerAddress].downlineNumber==users[referrerAddress].partnersCount)
                    {
                       users[referrerAddress].downlineNumber=0; 
                    }
                    address downline=get_downline_address(referrerAddress,level);
                    return updateX3Referrer(userAddress, downline, level);
              }
              else if(users[referrerAddress].x3Matrix[level].referrals.length==5)
                {
                  
                        emit Reinvest(referrerAddress, referrerAddress, userAddress, 1, level);
                        uint ded=0;
                        uint amount=0;
                     
                        ded=(levelPrice[level]*10)/100;   
                        amount=(levelPrice[level])-ded;
                                            
                      sendClubIncome(referrerAddress, 1, level,amount);
                       users[referrerAddress].x3Matrix[level].referrals = new address[](0);  
                       return; 
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
                   return updateX3Referrer(userAddress, users[referrerAddress].referrer, level);
          }
          
              else if(users[referrerAddress].x3Matrix[level].referrals.length==3)
              {
                    users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
                    emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
                    if(users[referrerAddress].downlineNumber==users[referrerAddress].partnersCount)
                    {
                       users[referrerAddress].downlineNumber=0; 
                    }
                    address downline=get_downline_address(referrerAddress,level);
                    return updateX3Referrer(userAddress, downline, level);
              }
          
              else
              {
                    if(users[referrerAddress].partnersCount>1)
                    {
                      users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
                      emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length)); 
                      emit Reinvest(referrerAddress, referrerAddress, userAddress, 1, level);
                      uint ded=0;
                      uint amount=0;
                     
                        ded=(levelPrice[level]*10)/100;   
                        amount=(levelPrice[level])-ded;
                                            
                      sendClubIncome(referrerAddress, 1, level,amount);
                      users[referrerAddress].x3Matrix[level].referrals = new address[](0);
                      return;
                    }
                    else
                    {
                     return updateX3Referrer(userAddress, owner, level);
                    }
                  
              }
         
        }
    }

     function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private 
    {
        users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
        if(level>1)
        {
           uint256 newIndex=x3Index[level]+1;
                   x3vId_number[level][newIndex]=userAddress;
                   x3Index[level]=newIndex;
        }

        if (users[referrerAddress].x6Matrix[level].referrals.length < 2) 
        {
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 2, level);
        }
        
        x3CurrentvId[level]=x3CurrentvId[level]+1;  //  After completion of two members
        
        emit NewUserPlace(userAddress, referrerAddress, 2, level, 2);
        //close matrix
        users[referrerAddress].x6Matrix[level].referrals = new address[](0);
        
            address freeReferrerAddress = findFreeX6Referrer(level);
             
            users[referrerAddress].x6Matrix[level].currentReferrer = freeReferrerAddress;

            uint256 newIndex=x3Index[level]+1;
            x3vId_number[level][newIndex]=referrerAddress;
            x3Index[level]=newIndex;
           
          
            users[referrerAddress].x6Matrix[level].reinvestCount++;  
            
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            if(address(freeReferrerAddress) != address(0))
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);  
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
        //(address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);
        address receiver=userAddress;
        bool isExtraDividends=false;
            uint ded=(levelPrice[level]*10)/100;
            uint income=(levelPrice[level]-ded);
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
             return owner;
         }
       }
    }
    
    
    
    function addToClub(address userAddress, uint8 matrix, uint8 level) private returns(bool)
    {
        if(matrix==1)
        {
            if(clubvId_number[level][clubIndex[level]]!=userAddress)
            {
            uint256 newIndex=clubIndex[level]+1;
            clubvId_number[level][newIndex]=userAddress;
            clubIndex[level]=newIndex;
            return true;
            }
        }
        else
        {  
            if(sClubvId_number[level][sClubIndex[level]]!=userAddress)
            {
            uint256 newIndex=sClubIndex[level]+1;
            sClubvId_number[level][newIndex]=userAddress;
            sClubIndex[level]=newIndex;
            return true;
            }
        }
        return false;
    }
    
    function qualify_to_club(address userAddress, uint8 club, uint8 level) public returns(bool)
    {
        require(msg.sender==owner,"onlyOwner");
        if(club==1)
        {
            if(clubvId_number[level][clubIndex[level]]!=userAddress)
            {
            uint256 newIndex=clubIndex[level]+1;
            clubvId_number[level][newIndex]=userAddress;
            clubIndex[level]=newIndex;
            return true;
            }
        }
        else
        {  
            if(sClubvId_number[level][sClubIndex[level]]!=userAddress)
            {
            uint256 newIndex=sClubIndex[level]+1;
            sClubvId_number[level][newIndex]=userAddress;
            sClubIndex[level]=newIndex;
            return true;
            }
        }
        return false;
    }
    

    
    
    
     function AbuyNewLevel(address _user, uint8 matrix, uint8 level) public {
          require(msg.sender==owner,"Only Owner");
        require(isUserExists(_user), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) 
        {
            require(users[_user].activeX3Levels[level-1], "buy previous level first");
            require(!users[_user].activeX3Levels[level], "level already activated");
            

    
            address freeX3Referrer = findFreeX3Referrer(_user, level);
            users[_user].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[_user].activeX3Levels[level] = true;
            
             
            AupdateX3Referrer(_user, freeX3Referrer, level);
            
            emit Upgrade(_user, freeX3Referrer, 1, level);
        }
        else 
        {
            require(users[_user].activeX6Levels[level-1], "buy previous level first");
            require(!users[_user].activeX6Levels[level], "level already activated"); 


            address freeX6Referrer = findFreeX6Referrer(level);
            
            users[_user].activeX6Levels[level] = true;
            
            AupdateX6Referrer(_user, freeX6Referrer, level);
           
            emit Upgrade(_user, freeX6Referrer, 2, level);
        }
    } 
    
    
      
    
    function AupdateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        if(referrerAddress==owner)
        {
             users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
             emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
              if(users[referrerAddress].x3Matrix[level].referrals.length==4)
                {
                    if(users[referrerAddress].downlineNumber==users[referrerAddress].partnersCount)
                    {
                       users[referrerAddress].downlineNumber=0; 
                    }
                    address downline=get_downline_address(referrerAddress,level);
                    return AupdateX3Referrer(userAddress, downline, level);
              }
              else if(users[referrerAddress].x3Matrix[level].referrals.length==5)
                {
                  
                        emit Reinvest(referrerAddress, referrerAddress, userAddress, 1, level);
                        uint ded=0;
                        uint amount=0;
                     
                        ded=(levelPrice[level]*10)/100;   
                        amount=(levelPrice[level])-ded;
                                            
                      //sendClubIncome(referrerAddress, 1, level,amount);
                       users[referrerAddress].x3Matrix[level].referrals = new address[](0);  
                       return; 
             }
              else
                {
             return;
             }
        }
        else
        {
              if(users[referrerAddress].x3Matrix[level].referrals.length<2) 
              {
                    users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
                    emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
                    return;
          }
              
              else if(users[referrerAddress].x3Matrix[level].referrals.length==2)
              {
                    users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
                    emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
                   return AupdateX3Referrer(userAddress, users[referrerAddress].referrer, level);
          }
          
              else if(users[referrerAddress].x3Matrix[level].referrals.length==3)
              {
                    users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
                    emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
                    if(users[referrerAddress].downlineNumber==users[referrerAddress].partnersCount)
                    {
                       users[referrerAddress].downlineNumber=0; 
                    }
                    address downline=get_downline_address(referrerAddress,level);
                    return AupdateX3Referrer(userAddress, downline, level);
              }
          
              else
              {
                    if(users[referrerAddress].partnersCount>1)
                    {
                      users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
                      emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length)); 
                      emit Reinvest(referrerAddress, referrerAddress, userAddress, 1, level);
                      uint ded=0;
                      uint amount=0;
                     
                        ded=(levelPrice[level]*10)/100;   
                        amount=(levelPrice[level])-ded;
                                            
                      //sendClubIncome(referrerAddress, 1, level,amount);
                      users[referrerAddress].x3Matrix[level].referrals = new address[](0);
                      return;
                    }
                    else
                    {
                     return AupdateX3Referrer(userAddress, owner, level);
                    }
                  
              }
         
        }
    }
    
    
        
    function AupdateX6Referrer(address userAddress, address referrerAddress, uint8 level) private 
    {
        users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
        if(level>1)
        {
           uint256 newIndex=x3Index[level]+1;
                   x3vId_number[level][newIndex]=userAddress;
                   x3Index[level]=newIndex;
        }

        if (users[referrerAddress].x6Matrix[level].referrals.length < 2) 
        {
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
            return;
        }
        
        x3CurrentvId[level]=x3CurrentvId[level]+1;  //  After completion of two members
        
        emit NewUserPlace(userAddress, referrerAddress, 2, level, 2);
        //close matrix
        users[referrerAddress].x6Matrix[level].referrals = new address[](0);
        
            address freeReferrerAddress = findFreeX6Referrer(level);
             
            users[referrerAddress].x6Matrix[level].currentReferrer = freeReferrerAddress;

            uint256 newIndex=x3Index[level]+1;
            x3vId_number[level][newIndex]=referrerAddress;
            x3Index[level]=newIndex;
           
          
            users[referrerAddress].x6Matrix[level].reinvestCount++;  
            
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            if(address(freeReferrerAddress) != address(0))
            AupdateX6Referrer(referrerAddress, freeReferrerAddress, level);  
    }
        
        
    
    
      function sendClubIncome(address _from, uint8 matrix, uint8 level, uint amount) private 
      {
          if(matrix==1)
          {
             uint index=clubCurrentvId[level];
             address  userAddress=clubvId_number[level][index];
             address(uint160(userAddress)).send(amount);
             if(addToClub(userAddress, matrix, level))
             clubCurrentvId[level]=clubCurrentvId[level]+1;
             emit UserIncome(userAddress, _from, matrix, level, amount);
          }
          else
          {
             uint index=sClubCurrentvId[level];
             address  userAddress=sClubvId_number[level][index];
             address(uint160(userAddress)).send(amount);
             if(addToClub(userAddress, matrix, level))
             sClubCurrentvId[level]=sClubCurrentvId[level]+1;
             emit UserIncome(userAddress, _from, matrix, level, amount);    
          }
      }
    
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}