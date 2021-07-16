//SourceUnit: DEZLink.sol

pragma solidity >=0.4.23 <0.6.0;

contract DEZLink {
    uint  sponsorFee = 20;
    uint  guaranteeFee = 10;
    uint  jackpotFee = 1;
    uint  multitierFee = 19;
    uint  crowdFee = 50;
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        uint totalEarning;
        uint totalSelfBusiness;
        uint regDate;
        uint currentLevel;
        mapping(uint8 => bool) activeX48Levels;
        mapping(uint8 => X4)  x4Matrix;
       
    }
    
    struct X4 {
        address currentReferrer;
        address[] referrals;
        bool isActive;
        bool blocked;
        uint totalSpillId;
        uint upgradeDate;
        uint requestId;
        bool upSpilled;
    }
    

    uint8 public constant LAST_LEVEL = 17;
    uint public lastUserId = 2;
    uint public lastRequestId = 17;
    address public owner;
    address  _jackpotAddress;
    address _multitierAddress;
    address _guaranteeAddress;
    address _stackAddress;
    
    mapping(address => User) public users;
    mapping(uint => address) public lastRequest;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(uint256 => uint) public levelPrice;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId, address uplineId, uint regDate);
    event Upgrade(address indexed user, address indexed referrer,  uint8 level, uint udate);
    
    constructor(address ownerAddress, address jackpotAddress, address multitierAddress, address guaranteeAddress, address stackAddress) public {
        levelPrice[1] = 1000 trx;
        levelPrice[2] = 1000 trx;
        levelPrice[3] = 1500 trx;
        levelPrice[4] = 3000 trx;
        levelPrice[5] = 4500 trx;
        levelPrice[6] = 9000 trx;
        levelPrice[7] = 13500 trx;
        levelPrice[8] = 27000 trx;
        levelPrice[9] = 40000 trx;
        
        levelPrice[10] = 80000 trx;
        levelPrice[11] = 120000 trx;
        levelPrice[12] = 240000 trx;
        levelPrice[13] = 360000 trx;
        levelPrice[14] = 700000 trx;
        levelPrice[15] = 1000000 trx;
        levelPrice[16] = 2000000 trx;
        levelPrice[17] = 3000000 trx;

        owner = ownerAddress;
        _guaranteeAddress = guaranteeAddress;
        _jackpotAddress = jackpotAddress;
        _multitierAddress = multitierAddress;
        _stackAddress = stackAddress;
         User memory user = User({
            id: 1,
            referrer: address(uint160(0x0000000000000000000000000000)),
            partnersCount: uint(0),
            totalEarning: uint(0),
            totalSelfBusiness: uint(0),
            regDate: now,
            currentLevel: 0
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        userIds[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeX48Levels[i] = true;
            users[ownerAddress].currentLevel = i;
            users[ownerAddress].x4Matrix[i].requestId = i;
            lastRequest[i] = ownerAddress;
            users[ownerAddress].x4Matrix[i].upgradeDate = now;
            users[ownerAddress].x4Matrix[i].isActive = true;
        }
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, idToAddress[1]);
    }

    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
   
    function registration(address userAddress, address referrerAddress) private {
        uint256 stackPrice = (levelPrice[1] * 1) / 100;
        uint256 _levelPrice = levelPrice[1] + stackPrice;
        
        require(msg.value == _levelPrice, "registration cost 1010 trx");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            totalEarning: uint(0),
            totalSelfBusiness: uint(0),
            regDate: now,
            currentLevel: 1
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeX48Levels[1] = true; 
       users[referrerAddress].totalSelfBusiness = users[referrerAddress].totalSelfBusiness + levelPrice[1];
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        lastRequestId++;
        lastRequest[lastRequestId] = userAddress;
        users[referrerAddress].partnersCount++;
        address freePlacement = findPlacement(referrerAddress, 1);
        users[userAddress].x4Matrix[1].currentReferrer = freePlacement;
        users[userAddress].x4Matrix[1].upgradeDate = now;
        users[userAddress].x4Matrix[1].isActive = true;
        users[userAddress].x4Matrix[1].requestId = lastRequestId;
        users[freePlacement].x4Matrix[1].referrals.push(userAddress);
        if(users[userAddress].referrer != freePlacement)
        {
           users[freePlacement].x4Matrix[1].totalSpillId = users[freePlacement].x4Matrix[1].totalSpillId + 1;
        }
        payForLevel(1,userAddress,freePlacement);
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id, freePlacement, now);
        //emit Upgrade(userAddress, freePlacement, 1, now);
        
        
    }
    function buyNewLevel( uint8 level) external payable {
        uint256 stackPrice = (levelPrice[level] * 1) / 100;
        uint256 _levelPrice = levelPrice[level] + stackPrice;
         
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(_levelPrice >  1 && msg.value == _levelPrice, "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
        require(!users[msg.sender].activeX48Levels[level], "level already activated");
        require(users[msg.sender].activeX48Levels[level-1], "Buy previous level first.");
        
        address freeReferrer = findSponsorOfLevel(msg.sender, level);
        address freePlacement  = findPlacement(freeReferrer, level);
        lastRequestId++;
        lastRequest[lastRequestId] = msg.sender;
        users[msg.sender].x4Matrix[level].isActive = true;
            users[msg.sender].x4Matrix[level].currentReferrer = freePlacement;
            users[msg.sender].x4Matrix[level].upgradeDate = now;
            users[msg.sender].x4Matrix[level].isActive = true;
            users[msg.sender].x4Matrix[level].requestId = lastRequestId;
            users[freePlacement].x4Matrix[level].referrals.push(msg.sender);
            if(users[msg.sender].referrer != freePlacement)
            {
               users[freePlacement].x4Matrix[level].totalSpillId = users[freePlacement].x4Matrix[level].totalSpillId + 1;
            }
        users[msg.sender].activeX48Levels[level] = true; 
        users[msg.sender].currentLevel = level;
        users[users[msg.sender].referrer].totalSelfBusiness = users[users[msg.sender].referrer].totalSelfBusiness + levelPrice[level];
        
        payForLevel(level,msg.sender,freePlacement);
        
        emit Upgrade(msg.sender, freePlacement, level, now);
        
    }
    
    function payForLevel(uint8 level, address userAddress,address freePlacement ) internal {
        address _sponsorAddress = users[userAddress].referrer;
        uint256 stackPrice = (levelPrice[level] * 1) / 100;
        uint256 _crowdPrice = (levelPrice[level] * crowdFee) / 100;
        uint256 _sponsorPrice = (levelPrice[level] * sponsorFee) / 100;
        uint256 _guaranteePrice = (levelPrice[level] * guaranteeFee) / 100;
        uint256 _jackpotPrice = (levelPrice[level] * jackpotFee) / 100;
        uint256 _multitierPrice = (levelPrice[level] * multitierFee) / 100;
        
        uint256 _total;
        _total = _sponsorPrice + _guaranteePrice + _jackpotPrice + _multitierPrice + _crowdPrice;
        
        require(levelPrice[level] == _total, "Cost overflow");
        require(isUserExists(_sponsorAddress), "Sponsor is not exists. Register first.");
        require(isUserExists(freePlacement), "UplineId is not exists. Register first.");
        
        require((stackPrice > 0 && _sponsorPrice > 0 && _guaranteePrice > 0 && _jackpotPrice > 0 && _crowdPrice > 0 && _multitierPrice > 0), "Transaction Failure with stack zero");
            require((address(uint160(_stackAddress)).send(stackPrice)) && 
                    (address(uint160(freePlacement)).send(_crowdPrice)) &&
                    (address(uint160(_sponsorAddress)).send(_sponsorPrice)) && 
                    (address(uint160(_guaranteeAddress)).send(_guaranteePrice)) && 
                    (address(uint160(_jackpotAddress)).send(_jackpotPrice)) && 
                    (address(uint160(_multitierAddress)).send(_multitierPrice)) , "Transaction Failure");
        
        users[_sponsorAddress].totalEarning = users[_sponsorAddress].totalEarning + _sponsorPrice;
        users[freePlacement].totalEarning = users[freePlacement].totalEarning + _crowdPrice;
        
    }
    
   
    function findSponsorOfLevel(address userAddress, uint8 level) internal returns(address) {
	    address sponsorId = users[userAddress].referrer;
	    if (users[sponsorId].activeX48Levels[level]) {
	        users[userAddress].x4Matrix[level].upSpilled = true;
            return sponsorId; 
        }
	    else if (users[users[sponsorId].referrer].activeX48Levels[level]) {
	        users[userAddress].x4Matrix[level].upSpilled = false;
	        return users[sponsorId].referrer;
        }
        else {
            users[userAddress].x4Matrix[level].upSpilled = false;
            return userIds[1];  
        }
    }
    function findFreeX2Placement(address uplineId, uint8 level) internal  returns(address) 
    {
        if(isUserExists(uplineId))
        {
            address referralsId;
            if(users[uplineId].x4Matrix[level].referrals.length > 0)
            {
                for (uint k=0; k < users[uplineId].x4Matrix[level].referrals.length; k++) 
                {
                    referralsId = users[uplineId].x4Matrix[level].referrals[k];
                    if(users[referralsId].x4Matrix[level].referrals.length == 0)
                    {
                        return referralsId;
                    }
                    else 
                    {
                        if(users[referralsId].x4Matrix[level].referrals.length == 2)
                        {
                            users[referralsId].x4Matrix[level].blocked = true;
                        }
                        else
                        {
                            return referralsId;
                        }
                    }
                }
                return users[uplineId].x4Matrix[level].referrals[0];
            }
            else{
                return uplineId;
            }
        }
    }
    function findFreeX4Placement(address uplineId, uint8 level) internal  returns(address) 
    {
        if(isUserExists(uplineId))
        {
            address referralsId;
            if(users[uplineId].x4Matrix[level].referrals.length > 0)
            {
                for (uint k=0; k < users[uplineId].x4Matrix[level].referrals.length; k++) 
                {
                    referralsId = users[uplineId].x4Matrix[level].referrals[k];
                    if(users[referralsId].x4Matrix[level].referrals.length == 0)
                    {
                        return referralsId;
                    }
                    else 
                    {
                        if(users[referralsId].x4Matrix[level].referrals.length == 4)
                        {
                            users[referralsId].x4Matrix[level].blocked = true;
                        }
                        else
                        {
                            if(users[msg.sender].referrer == referralsId || users[referralsId].x4Matrix[level].totalSpillId < 3)
                            {
                                return referralsId;
                            }
                        }
                    }
                }
                return users[uplineId].x4Matrix[level].referrals[0];
            }
            else{
                return uplineId;
            }
        }
    }
    function findFreeX8Placement(address uplineId, uint8 level) internal  returns(address) 
    {
        if(isUserExists(uplineId))
        {
            address referralsId;
            if(users[uplineId].x4Matrix[level].referrals.length > 0)
            {
                for (uint k=0; k < users[uplineId].x4Matrix[level].referrals.length; k++) 
                {
                    referralsId = users[uplineId].x4Matrix[level].referrals[k];
                    if(users[referralsId].x4Matrix[level].referrals.length == 0)
                    {
                        return referralsId;
                    }
                    else 
                    {
                        if(users[referralsId].x4Matrix[level].referrals.length == 8)
                        {
                            users[referralsId].x4Matrix[level].blocked = true;
                        }
                        else
                        {
                            if(users[msg.sender].referrer == referralsId || users[referralsId].x4Matrix[level].totalSpillId < 5)
                            {
                                return referralsId;
                            }
                        }
                    }
                }
                return users[uplineId].x4Matrix[level].referrals[0];
            }
            else{
                return uplineId;
            }
        }
    }
    function findPlacement(address sponsorId, uint8 level) internal  returns(address) 
    {
        require(isUserExists(sponsorId), "Sponsor is not exists.");
        if(isUserExists(sponsorId))
        {
            address sponsorLoopId = sponsorId;
            uint len = 0;
            uint _totalSpill = 0;
            if(level == 1)
            {
               while(true)
               { 
        	        len = users[sponsorLoopId].x4Matrix[level].referrals.length;
        	        if(len == 0)
        	        {
        	            return sponsorLoopId;
        	        }
                    else if (len < 2 && len > 0) {
                        _totalSpill = users[sponsorLoopId].x4Matrix[level].totalSpillId;
                        if(users[msg.sender].referrer == sponsorLoopId)
            			{
            			        return sponsorLoopId;
            			 }
            			 else{
            			   return sponsorLoopId;
            			 }
                    }
        	        else
        	        {
        	            users[sponsorLoopId].x4Matrix[level].blocked = true;
            		   		
        	        }
        	      sponsorLoopId = findFreeX2Placement(sponsorLoopId, level);
                }
            }
            else if(level == 2 || level == 4 || level == 6 || level == 8 || level == 10 || level == 12 || level == 14 || level == 16)
            {
        	   while(true)
               {  
        	        len = users[sponsorLoopId].x4Matrix[level].referrals.length;
        	        if(len == 0)
        	        {
        	            return sponsorLoopId;
        	        }
                    else if (len < 4 && len > 0) {
                        _totalSpill = users[sponsorLoopId].x4Matrix[level].totalSpillId;
                        if(users[msg.sender].referrer == sponsorLoopId)
            			{
            			        return sponsorLoopId;
            			 }
            			 else{
            			   if( _totalSpill < 3)
            			   {
            			      return sponsorLoopId;
            			   }
            			 }
                    }
        	        else
        	        {
        	            users[sponsorLoopId].x4Matrix[level].blocked = true;
            		   		
        	        }
        	    sponsorLoopId = findFreeX4Placement(sponsorLoopId, level);
                }
            }
            else
            {
        	   while(true)
               { 
        	        len = users[sponsorLoopId].x4Matrix[level].referrals.length;
        	        if(len == 0)
        	        {
        	            return sponsorLoopId;
        	        }
                    else if (len < 8 && len > 0) {
                        _totalSpill = users[sponsorLoopId].x4Matrix[level].totalSpillId;
                        if(users[msg.sender].referrer == sponsorLoopId)
            			{
            			        return sponsorLoopId;
            			 }
            			 else{
            			   if( _totalSpill < 5)
            			   {
            			      return sponsorLoopId;
            			   }
            			 }
                    }
        	        else
        	        {
        	            users[sponsorLoopId].x4Matrix[level].blocked = true;
            		   		
        	        }
        	      sponsorLoopId = findFreeX8Placement(sponsorLoopId, level);
                }
            }
        }
        else{
            return userIds[1];
        }
    }
    
   
    // All External Function
   function getMatrix(address _userAddress, uint8 level) public view returns(address upline,uint totalSpilled,address[] memory referrals,bool isBlocked,bool isActive, uint upgradeDate, uint requestID, bool upSpilled) {
        X4 memory x44 = users[_userAddress].x4Matrix[level];
         return (x44.currentReferrer, x44.totalSpillId,x44.referrals, x44.blocked,x44.isActive, x44.upgradeDate, x44.requestId, x44.upSpilled);
    }
   
    // View Direct referral
    
     function viewUserSponsor(address _userAddress) public view returns (address) {
        return users[_userAddress].referrer;
    }
    
    // View Upline referral
    
     function viewUserUpline(address _userAddress, uint8 level) public view returns (address) {
        return users[_userAddress].x4Matrix[level].currentReferrer;
        
   }
    // View Downline referral
    
    function viewUserDownline(address _userAddress, uint8 level) public view returns (address[] memory) {
        return users[_userAddress].x4Matrix[level].referrals;
    }
    
    // fallback
   
}