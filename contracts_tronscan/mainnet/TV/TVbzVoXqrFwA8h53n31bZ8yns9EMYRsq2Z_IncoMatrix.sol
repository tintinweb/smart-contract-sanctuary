//SourceUnit: incomatrixmain.sol

pragma solidity 0.4.25;



contract IncoMatrix {
    using SafeMath for uint256;
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint256 => bool) activeX3Levels;
        mapping(uint256 => bool) activeX6Levels;
        
        mapping(uint256 => X3) x3Matrix;
        mapping(uint256 => X6) x6Matrix;
        
        
        mapping(uint256 => bool) activeX3AutoLevels;
        mapping(uint256 => bool) activeX6AutoLevels;
        
        mapping(uint256 => X3) x3AutoMatrix;
        mapping(uint256 => X6) x6AutoMatrix;
        
    }
    
    struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
        uint noOfPayment;
        uint256 lastSettledDailyGlobal;
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
    
     struct DailyData{
       uint totalInvestedamount;
       uint investedTillDate;
       uint roundId;
       uint endTime;
      uint noofUsers;
     }
     
    
    bool public openPublicRegistration;
     mapping(uint=>uint) public todaysInvestmentX3;
      mapping(uint=>uint) public todaysInvestmentX4;
      mapping(uint=>uint) public iGlobalAmountX3;
      mapping(uint=>uint) public iGlobalAmountX4;
      mapping(uint=>uint) public noofUserstodayX3;
      mapping(uint=>uint) public noofUserstodayX4;
      
      uint public todaysInvestment=0;
      uint public iGlobalAmount=0;
      
      address roundStarter;
      uint dailyDividendTime=24 hours;
      uint256 public Max_Limit_Global_Withdrawal=5; 
      
       
    
    mapping(uint => mapping(uint=>DailyData)) public GlobalDailyDataListX3;
    mapping(uint => mapping(uint=>DailyData)) public GlobalDailyDataListX4;
    
    
    uint8 public currentStartingLevel = 1;
    uint8 public constant LAST_LEVEL = 16;
    
    uint256 public totalWithdrawn;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;

    uint public lastUserId = 2;
    address public owner;
    mapping(uint256 => uint) public levelPrice;
    uint public dailyDividendRoundid=1;
    address public iInvest;

   	
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint256 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint256 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint256 level, uint256 place);
    event MissedTRXReceive(address indexed receiver, address indexed from, uint8 matrix, uint256 level);
    event Withdrawn(address indexed user, uint256 amount,uint256 earnfrom);
    event EarningsMatrix(address indexed user,uint256 amount,uint8 matrix,uint256 level);
    
    constructor(address ownerAddress,address _roundStarter) public {
        
        levelPrice[1] = 25 trx;
        levelPrice[2] = 50 trx;
        levelPrice[3] = 100 trx;
        levelPrice[4] = 150 trx;
        levelPrice[5] = 200 trx;
        levelPrice[6] = 250 trx;
        levelPrice[7] = 300 trx;
        levelPrice[8] = 500 trx;
        levelPrice[9] = 1000 trx;
        levelPrice[10] = 1500 trx;
        levelPrice[11] = 2000 trx;
        levelPrice[12] = 3000 trx;
        levelPrice[13] = 6000 trx;
        levelPrice[14] = 9000 trx;
        levelPrice[15] = 12000 trx;
        levelPrice[16] = 15000 trx;

         
        owner = ownerAddress;
        roundStarter=_roundStarter;
        
        
        
            users[ownerAddress].id= 1;
            users[ownerAddress].referrer=address(0);
            users[ownerAddress].partnersCount=0;
           
            
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeX3Levels[i] = true;
            users[ownerAddress].activeX6Levels[i] = true;
            
             users[ownerAddress].activeX3AutoLevels[i] = true;
            users[ownerAddress].activeX6AutoLevels[i] = true;
            
             GlobalDailyDataListX4[i][dailyDividendRoundid].endTime=now;
            GlobalDailyDataListX3[i][dailyDividendRoundid].endTime=now;
            
             noofUserstodayX3[i]=noofUserstodayX3[i].add(1);
              noofUserstodayX4[i]=noofUserstodayX4[i].add(1);
              
               users[ownerAddress].x3Matrix[i].lastSettledDailyGlobal=dailyDividendRoundid;
            users[ownerAddress].x6Matrix[i].lastSettledDailyGlobal=dailyDividendRoundid;
        }   
        
       
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        require(openPublicRegistration,"Registration not started yet");
        registration(msg.sender, bytesToAddress(msg.data));
    }

   
    function setiInvestContract(address _iInvest) public{
        require(msg.sender==owner,"Only owner can update this");
        iInvest=_iInvest;
    }
    
    function preRegistrationExt(address userAddress, address referrerAddress) public payable
    {
        require(!openPublicRegistration,"Normal mode started");
        require(msg.sender==owner);
        registration(userAddress,referrerAddress);
    }
    
    function setContractFlag() public 
    {
        require(msg.sender==owner);
        openPublicRegistration=true;
    }
   

    function registrationExt(address referrerAddress) external payable {
        require(openPublicRegistration,"Registration not started yet");
        registration(msg.sender, referrerAddress);
    }
    
    
    
    function buyNewLevel(uint8 matrix, uint256 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
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
            users[msg.sender].x3Matrix[level].lastSettledDailyGlobal=dailyDividendRoundid;
            noofUserstodayX3[level]=noofUserstodayX3[level].add(1);
            
        } else {
            require(users[msg.sender].activeX6Levels[level.sub(1)], "buy previous level first");
            require(!users[msg.sender].activeX6Levels[level], "level already activated"); 

            if (users[msg.sender].x6Matrix[level.sub(1)].blocked) {
                users[msg.sender].x6Matrix[level.sub(1)].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(msg.sender, level);
            
            users[msg.sender].activeX6Levels[level] = true;
            updateX6Referrer(msg.sender, freeX6Referrer, level);
            
            emit Upgrade(msg.sender, freeX6Referrer, 2, level);
            users[msg.sender].x6Matrix[level].lastSettledDailyGlobal=dailyDividendRoundid;
            noofUserstodayX4[level]=noofUserstodayX4[level].add(1);
        }
    }    
    
   
    
    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        require(iInvest!=address(0),"Iinvest contract not updated");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

       
            require(msg.value == levelPrice[currentStartingLevel].mul(3), "invalid registration cost");
       
       users[userAddress].id= lastUserId;
            users[userAddress].referrer=referrerAddress;
            users[userAddress].partnersCount=0;
        users[userAddress].x6Matrix[1].lastSettledDailyGlobal=dailyDividendRoundid;
        users[userAddress].x3Matrix[1].lastSettledDailyGlobal=dailyDividendRoundid;
       noofUserstodayX3[1]=noofUserstodayX3[1].add(1);
         noofUserstodayX4[1]=noofUserstodayX4[1].add(1);
        
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeX3Levels[1] = true; 
        users[userAddress].activeX6Levels[1] = true;
        
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateX3Referrer(userAddress, freeX3Referrer, 1);

        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1);

       
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
       
      address(iInvest).transfer(25 trx);
      IinvestContract(iInvest).registration(userAddress,referrerAddress);
      
    }
    
    
    function updateX3Referrer(address userAddress, address referrerAddress, uint256 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return sendTRXDividends(referrerAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
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
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendTRXDividends(owner, 1, level);
            users[owner].x3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint256 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            
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
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level,uint256(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length).add(2));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint256(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length).add(4));
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

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendTRXDividends(owner, 2, level);
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
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

   

    function sendTRXDividends(address userAddress, uint8 matrix, uint256 level) private {
        

        uint256 _80per =  levelPrice[level].mul(80).div(100);
        uint256 _20per =  levelPrice[level].mul(20).div(100);

        
        if(userAddress!=owner)
        {
            
            if(matrix == 1)
            {
                 todaysInvestmentX3[level] = todaysInvestmentX3[level].add(_20per);
                iGlobalAmountX3[level] = iGlobalAmountX3[level].add(_20per);
                
                users[userAddress].x3Matrix[level].noOfPayment++;
                if(users[userAddress].x3Matrix[level].noOfPayment == 3 && level==1)
                {
                    
                    X3AutoUpgrade(userAddress,level);
                }
                else
                {
                    if (address(uint160(userAddress)).send(_80per)) {
                         emit EarningsMatrix(userAddress,_80per,matrix,level);
                     }
                     else
                    {
                         return address(uint160(userAddress)).transfer(address(this).balance);
                    }
                }
               
            }
            else if(matrix == 2){
                todaysInvestmentX4[level] = todaysInvestmentX4[level].add(_20per);
                iGlobalAmountX4[level] = iGlobalAmountX4[level].add(_20per);
                
                users[userAddress].x6Matrix[level].noOfPayment++;
                 if(users[userAddress].x6Matrix[level].noOfPayment == 4 && level==1)
                {
                    X6AutoUpgrade(userAddress,level);
                }
                else{
                 if (address(uint160(userAddress)).send(_80per)) {
                         emit EarningsMatrix(userAddress,_80per,matrix,level);
                     }
                     else
                    {
                         return address(uint160(userAddress)).transfer(address(this).balance);
                    }
                }
                
            }
            
        }
        else
        {
            if (address(uint160(owner)).send(_80per)) {
                         emit EarningsMatrix(owner,_80per,matrix,level);
                     }
               if(matrix == 1)
            {
                 todaysInvestmentX3[level] = todaysInvestmentX3[level].add(_20per);
                iGlobalAmountX3[level] = iGlobalAmountX3[level].add(_20per);
            }
            else{
                 todaysInvestmentX4[level] = todaysInvestmentX4[level].add(_20per);
                iGlobalAmountX4[level] = iGlobalAmountX4[level].add(_20per);
            }
                     
        }
         
         todaysInvestment=todaysInvestment.add(_20per);
         iGlobalAmount=iGlobalAmount.add(_20per);
            
        
    }
    
     function sendTRXDividendsAuto(address userAddress, uint8 matrix, uint256 level) private {
         uint256 _80per =  levelPrice[level].mul(80).div(100);
        
        
             if(userAddress!=owner)
        {
            
            if(matrix == 4)
            {
                users[userAddress].x3AutoMatrix[level].noOfPayment++;
                if(users[userAddress].x3AutoMatrix[level].noOfPayment <= 2 && !users[userAddress].activeX3AutoLevels[level+1] && level!=LAST_LEVEL)
                {
                    if(users[userAddress].x3AutoMatrix[level].noOfPayment==2 ){
                    X3AutoUpgrade(userAddress,level.add(1));
                    }
                    
                }
                else
                {
                    if (address(uint160(userAddress)).send(_80per)) {
                         emit EarningsMatrix(userAddress,_80per,matrix,level);
                     }
                     else
                    {
                         return address(uint160(userAddress)).transfer(address(this).balance);
                    }
                }
            }
            else if(matrix == 5){
                users[userAddress].x6AutoMatrix[level].noOfPayment++;
                 if(users[userAddress].x6AutoMatrix[level].noOfPayment <= 2 && !users[userAddress].activeX6AutoLevels[level.add(1)]  && level!=LAST_LEVEL)
                {
                    if(users[userAddress].x6AutoMatrix[level].noOfPayment==2){
                    X6AutoUpgrade(userAddress,level.add(1));
                    }
                    else if(users[userAddress].x6AutoMatrix[level].noOfPayment==3){
                        if (address(uint160(userAddress)).send(_80per)) {
                         emit EarningsMatrix(userAddress,_80per,matrix,level);
                         }
                    }
                }
                else{
                 if (address(uint160(userAddress)).send(_80per)) {
                         emit EarningsMatrix(userAddress,_80per,matrix,level);
                     }
                     else
                    {
                         return address(uint160(userAddress)).transfer(address(this).balance);
                    }
                }
            }
            
        }
        else
        {
            if (address(uint160(owner)).send(_80per)) {
                         emit EarningsMatrix(owner,_80per,matrix,level);
                     }
        }
               
     }
     
     
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
    
    
    /*****************************X3Auto****************************************/
    
    
     function X3AutoUpgrade(address user,uint256 level) private
    {
         if (users[user].x3AutoMatrix[level.sub(1)].blocked) {
                users[user].x3AutoMatrix[level.sub(1)].blocked = false;
            }
    
            address freeX3Referrer = findFreeX3AutoReferrer(user, level);
            users[user].x3AutoMatrix[level].currentReferrer = freeX3Referrer;
            users[user].activeX3AutoLevels[level] = true;
            updateX3AutoReferrer(user, freeX3Referrer, level);
            
            emit Upgrade(user, freeX3Referrer, 4, level);
    }
    
    
     function updateX3AutoReferrer(address userAddress, address referrerAddress, uint256 level) private {
        users[referrerAddress].x3AutoMatrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3AutoMatrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 4, level, uint8(users[referrerAddress].x3AutoMatrix[level].referrals.length));
            return sendTRXDividendsAuto(referrerAddress, 4, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 4, level, 3);
        //close matrix
        users[referrerAddress].x3AutoMatrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeX3AutoLevels[level.add(1)] && level != LAST_LEVEL) {
            users[referrerAddress].x3AutoMatrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeX3AutoReferrer(referrerAddress, level);
            if (users[referrerAddress].x3AutoMatrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].x3AutoMatrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].x3AutoMatrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 4, level);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendTRXDividendsAuto(owner, 4, level);
            users[owner].x3AutoMatrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 4, level);
        }
    }
    
    
      function findFreeX3AutoReferrer(address userAddress, uint256 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3AutoLevels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
   
   
    function usersActiveX3AutoLevels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3AutoLevels[level];
    }

 /*****************************X6Auto****************************************/
 
  function X6AutoUpgrade(address user,uint256 level) private
    {
        if (users[user].x6AutoMatrix[level.sub(1)].blocked) {
                users[user].x6AutoMatrix[level.sub(1)].blocked = false;
            }

            address freeX6Referrer = findFreeX6AutoReferrer(user, level);
            
            users[user].activeX6AutoLevels[level] = true;
            updateX6AutoReferrer(user, freeX6Referrer, level);
            
            emit Upgrade(user, freeX6Referrer, 5, level);
    }
    
 function updateX6AutoReferrer(address userAddress, address referrerAddress, uint256 level) private {
        require(users[referrerAddress].activeX6AutoLevels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 5, level, uint8(users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].x6AutoMatrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendTRXDividendsAuto(referrerAddress, 5, level);
            }
            
            address ref = users[referrerAddress].x6AutoMatrix[level].currentReferrer;            
            users[ref].x6AutoMatrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].x6AutoMatrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].x6AutoMatrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x6AutoMatrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 5, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 5, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x6AutoMatrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 5, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 5, level, 4);
                }
            } else if (len == 2 && users[ref].x6AutoMatrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 5, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 5, level, 6);
                }
            }

            return updateX6AutoReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].x6AutoMatrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].x6AutoMatrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].x6AutoMatrix[level].closedPart)) {

                updateX6Auto(userAddress, referrerAddress, level, true);
                return updateX6AutoReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6AutoMatrix[level].closedPart) {
                updateX6Auto(userAddress, referrerAddress, level, true);
                return updateX6AutoReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateX6Auto(userAddress, referrerAddress, level, false);
                return updateX6AutoReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals[1] == userAddress) {
            updateX6Auto(userAddress, referrerAddress, level, false);
            return updateX6AutoReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals[0] == userAddress) {
            updateX6Auto(userAddress, referrerAddress, level, true);
            return updateX6AutoReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals[0]].x6AutoMatrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals[1]].x6AutoMatrix[level].firstLevelReferrals.length) {
            updateX6Auto(userAddress, referrerAddress, level, false);
        } else {
            updateX6Auto(userAddress, referrerAddress, level, true);
        }
        
        updateX6AutoReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateX6Auto(address userAddress, address referrerAddress, uint256 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals[0]].x6AutoMatrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals[0], 5, level, uint8(users[users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals[0]].x6AutoMatrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 5, level,uint256(users[users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals[0]].x6AutoMatrix[level].firstLevelReferrals.length).add(2));
            //set current level
            users[userAddress].x6AutoMatrix[level].currentReferrer = users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals[1]].x6AutoMatrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals[1], 5, level, uint8(users[users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals[1]].x6AutoMatrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 5, level, uint256(users[users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals[1]].x6AutoMatrix[level].firstLevelReferrals.length).add(4));
            //set current level
            users[userAddress].x6AutoMatrix[level].currentReferrer = users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateX6AutoReferrerSecondLevel(address userAddress, address referrerAddress, uint256 level) private {
        if (users[referrerAddress].x6AutoMatrix[level].secondLevelReferrals.length < 4) {
            return sendTRXDividendsAuto(referrerAddress, 5, level);
        }
        
        address[] memory x6 = users[users[referrerAddress].x6AutoMatrix[level].currentReferrer].x6AutoMatrix[level].firstLevelReferrals;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].x6AutoMatrix[level].currentReferrer].x6AutoMatrix[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].x6AutoMatrix[level].currentReferrer].x6AutoMatrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].x6AutoMatrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].x6AutoMatrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].x6AutoMatrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeX6AutoLevels[level.add(1)] && level != LAST_LEVEL) {
            users[referrerAddress].x6AutoMatrix[level].blocked = true;
        }

        users[referrerAddress].x6AutoMatrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeX6AutoReferrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 5, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 5, level);
            sendTRXDividendsAuto(owner, 5, level);
        }
    }
    
    function findFreeX6AutoReferrer(address userAddress, uint256 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX6AutoLevels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }

function usersActiveX6AutoLevels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6AutoLevels[level];
    }
    
    
    function usersX6AutoMatrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address) {
        return (users[userAddress].x6AutoMatrix[level].currentReferrer,
                users[userAddress].x6AutoMatrix[level].firstLevelReferrals,
                users[userAddress].x6AutoMatrix[level].secondLevelReferrals,
                users[userAddress].x6AutoMatrix[level].blocked,
                users[userAddress].x6AutoMatrix[level].closedPart);
    }
    
    
    function getrefferaladdress(address user) public view returns(address)
    {
        return users[user].referrer;
    }
    
    
    
    
	/****** IGlobal ************/
	function setMax_Limit_Global_Withdrawal(uint256 maxdays)public{
	    require(msg.sender==owner,"Only owner can update this");
	    Max_Limit_Global_Withdrawal=maxdays;
	}
	
	function getProfit(address _addr) public view returns (uint) {
        User storage player = users[_addr];
        uint profit=0;
        
            for(uint8 j=1;j<=16;j++){
              if(!player.activeX3Levels[j] && !player.activeX6Levels[j]){
                  break;
              }
             
                for(uint i=player.x3Matrix[j].lastSettledDailyGlobal;i<dailyDividendRoundid && i<player.x3Matrix[j].lastSettledDailyGlobal.add(Max_Limit_Global_Withdrawal) && player.activeX3Levels[j];i++)
                {
                    if(GlobalDailyDataListX3[j][i].totalInvestedamount>0 && GlobalDailyDataListX3[j][i].noofUsers>0){
                        profit=profit.add(GlobalDailyDataListX3[j][i].totalInvestedamount.div(GlobalDailyDataListX3[j][i].noofUsers));
                    }
                }
                for(uint k=player.x6Matrix[j].lastSettledDailyGlobal;k<dailyDividendRoundid  && k<player.x6Matrix[j].lastSettledDailyGlobal.add(Max_Limit_Global_Withdrawal) && player.activeX6Levels[j];k++)
                {
                    if(GlobalDailyDataListX4[j][k].totalInvestedamount>0 && GlobalDailyDataListX4[j][k].noofUsers>0){
                        profit=profit.add(GlobalDailyDataListX4[j][k].totalInvestedamount.div(GlobalDailyDataListX4[j][k].noofUsers));
                    }
                }
            }
        
       
        
        return profit;
    }
    
     function setDailyRound() public
    {
         require(msg.sender == roundStarter,"Oops you can't start the next round");
         for(uint8 i=1;i<=16;i++){
            if(now>GlobalDailyDataListX3[i][dailyDividendRoundid].endTime){
                
            GlobalDailyDataListX3[i][dailyDividendRoundid].totalInvestedamount=todaysInvestmentX3[i];
           
            GlobalDailyDataListX3[i][dailyDividendRoundid].investedTillDate=iGlobalAmountX3[i];
            GlobalDailyDataListX3[i][dailyDividendRoundid].roundId=dailyDividendRoundid;
            GlobalDailyDataListX3[i][dailyDividendRoundid].noofUsers=noofUserstodayX3[i];
            //noofUserstoday=0;
             
            //5%poolinvestment Totalinvestmenttilldate
            todaysInvestmentX3[i]=0;
            
           
            /********* X4 ************/
        GlobalDailyDataListX4[i][dailyDividendRoundid].totalInvestedamount=todaysInvestmentX4[i];
       
        GlobalDailyDataListX4[i][dailyDividendRoundid].investedTillDate=iGlobalAmountX4[i];
        GlobalDailyDataListX4[i][dailyDividendRoundid].roundId=dailyDividendRoundid;
        GlobalDailyDataListX4[i][dailyDividendRoundid].noofUsers=noofUserstodayX4[i];
        //noofUserstoday=0;
         
        //5%poolinvestment Totalinvestmenttilldate
        todaysInvestmentX4[i]=0;
        
        
         GlobalDailyDataListX3[i][dailyDividendRoundid.add(1)].endTime=now.add(dailyDividendTime);
            GlobalDailyDataListX3[i][dailyDividendRoundid.add(1)].roundId=dailyDividendRoundid;
            
            
        GlobalDailyDataListX4[i][dailyDividendRoundid.add(1)].endTime=now.add(dailyDividendTime);
        GlobalDailyDataListX4[i][dailyDividendRoundid.add(1)].roundId=dailyDividendRoundid;
        todaysInvestment=0;
        
        }
     }
     dailyDividendRoundid++;
    }
    
    
     function collect() public {
        User storage player = users[msg.sender];
        uint profit=0;
        
           for(uint8 j=1;j<=16;j++){
               if(!users[msg.sender].activeX3Levels[j] && !users[msg.sender].activeX6Levels[j]){
                   break;
               }
                for(uint i=player.x3Matrix[j].lastSettledDailyGlobal;i<dailyDividendRoundid && i<player.x3Matrix[j].lastSettledDailyGlobal.add(Max_Limit_Global_Withdrawal) && users[msg.sender].activeX3Levels[j];i++)
                {
                    if(GlobalDailyDataListX3[j][i].totalInvestedamount>0   && GlobalDailyDataListX3[j][i].noofUsers>0){
                        profit=profit.add(GlobalDailyDataListX3[j][i].totalInvestedamount/GlobalDailyDataListX3[j][i].noofUsers);
                    }
                }
                for(uint k=player.x6Matrix[j].lastSettledDailyGlobal;k<dailyDividendRoundid  && k<player.x6Matrix[j].lastSettledDailyGlobal.add(Max_Limit_Global_Withdrawal) && player.activeX6Levels[j];k++)
                {
                    if(GlobalDailyDataListX4[j][k].totalInvestedamount>0 && GlobalDailyDataListX4[j][k].noofUsers>0){
                        profit=profit.add(GlobalDailyDataListX4[j][k].totalInvestedamount.div(GlobalDailyDataListX4[j][k].noofUsers));
                    }
                }
                
                users[msg.sender].x3Matrix[j].lastSettledDailyGlobal=i;
                users[msg.sender].x6Matrix[j].lastSettledDailyGlobal=k;
            }
        
        
      //  require(profit>0,"Amount is not Withdrawable");
        msg.sender.transfer(profit);
        	emit Withdrawn(msg.sender, profit,2);
      }
    
  function getGlobal() public view returns(uint256,uint256,uint256){
      return (todaysInvestment,noofUserstodayX3[1],iGlobalAmount);
  }
    
     function changeRoundStarter(address _user) public
    {
        require(msg.sender == owner,"Oops you can't start the next round");
        require(_user!=address(0x0),"Invalid address");
        roundStarter=_user;
    }
    
    
    
    /******************************/
}


interface IinvestContract{
    function registration(address userAddress,address referrer) external payable;
    function getReferrer(address _useraddress) external view returns(address);
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