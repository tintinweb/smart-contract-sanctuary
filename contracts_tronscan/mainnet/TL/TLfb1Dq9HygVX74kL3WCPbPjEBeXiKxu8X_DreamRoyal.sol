//SourceUnit: dreamroyal.sol

pragma solidity 0.5.10;
/*
  https://dreamroyal.org/
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

contract DreamRoyal is Owner {
    struct User {
        uint id;
        address payable referrer;
        uint256 partnersCount;
        mapping(uint256 => bool) activeMatrix;
    }
    struct AutoUser {
        address payable upline;
        address[] referrals;
    }
	address payable public owner;
	mapping(address => User) public users;
	event Upline(address indexed addr, address indexed upline);
	uint256 remainingbonus=0;
	mapping(uint256 => uint256) public autopool_bonuses;
    mapping(address =>mapping(uint256 => AutoUser)) public autousers;
    mapping(uint256 => uint256) public pool_user;
    mapping(uint256 => mapping(uint256 => address)) public autopool_useraddress;
    mapping(uint => address) public idToAddress;
    address payable public platform_fee;
    uint256[] public REFERRAL_PERCENTS = [250,20,20,20,20,20,10,10,10,10,10,5,5,5,5,5,15,15,15,15,15];
    uint256[] public index = [0,2,4,8,16,32,64];
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event levelBonus(address indexed receiver, address indexed _from, uint _amount, uint8 level);
	event Upgrade(address indexed user, address indexed referrer, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 level, uint8 place);
	constructor() public {
        owner=msg.sender;
        User memory user = User({
            id: 918273,
            referrer: address(0),
            partnersCount: uint(0)
        });
        users[owner] = user;
        platform_fee = 0xc2976A4245Dc1975C3C6603341DCB8458FB54b19;
        idToAddress[918273] = owner;
        for (uint8 i = 1; i <= 6; i++) 
        {
          autopool_useraddress[1][i]=owner;
          pool_user[i]=1;
          users[owner].activeMatrix[i] = true;
        }
		
        autopool_bonuses[1]=125*1e6;//125
        autopool_bonuses[2]=1875*1e5;//187.5
        autopool_bonuses[3]=900*1e6;//900
        autopool_bonuses[4]=6480*1e6;//6480
        autopool_bonuses[5]=55296*1e6;//55296
        autopool_bonuses[6]=4423689*1e6;//442368
        
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
    function registrationFor(address userAddress,address payable referrerAddress,uint id) external onlyOwner {
        registrationFree(userAddress, referrerAddress, id);
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
        require(msg.value == 550*1e6, "invalid registration cost");
        
        User memory user = User({
            id: id,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[id] = userAddress;
                   
        users[userAddress].referrer = referrerAddress;
       
        users[referrerAddress].partnersCount++;
        uint ded=50*1e6;
        platform_fee.transfer(ded);
        if(users[referrerAddress].partnersCount==2)
        {
		    referrerAddress.transfer(REFERRAL_PERCENTS[0]*1e6);
            _setAutoPool(referrerAddress,2);
        }
        else if(users[referrerAddress].partnersCount>2)
        {
		    referrerAddress.transfer(REFERRAL_PERCENTS[0]*1e6);
            emit levelBonus(referrerAddress,userAddress,REFERRAL_PERCENTS[0]*1e6,1);
            remainingbonus=0;
           _refPayout(referrerAddress);
        }
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
       
        users[referrerAddress].partnersCount++;
        
        if(users[referrerAddress].partnersCount==2)
        {
            _setAutoPoolFree(referrerAddress,2);
        }
        else if(users[referrerAddress].partnersCount>2)
        {
            emit levelBonus(referrerAddress,userAddress,REFERRAL_PERCENTS[0]*1e6,1);
           _refPayoutFree(referrerAddress);
        }
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function _refPayout(address _addr) private {
        address payable up = users[_addr].referrer;
		uint256 bonus=0;
		remainingbonus=250*1e6;
        for(uint8 i = 1; i < REFERRAL_PERCENTS.length; i++) {
            if(up == address(0)) break;
            bonus=REFERRAL_PERCENTS[i]*1e6;
            remainingbonus=remainingbonus-bonus;
            if(users[up].activeMatrix[2])
            {
               up.transfer(bonus);  
               emit levelBonus(up,_addr,bonus,(i+1));
            }
            else
            {
                platform_fee.transfer(bonus);//goto deduction wallet
            }
            up = users[up].referrer;
        }
        if(remainingbonus>0)
        {
            platform_fee.transfer(remainingbonus);//goto deduction wallet
        }
    }
    function _refPayoutFree(address _addr) private {
        address payable up = users[_addr].referrer;
		uint256 bonus=0;
        for(uint8 i = 1; i < REFERRAL_PERCENTS.length; i++) {
            if(up == address(0)) break;
                bonus=REFERRAL_PERCENTS[i]*1e6;
                emit levelBonus(up,_addr,bonus,(i+1));
            up = users[up].referrer;
        }
    }
    
    function _setAutoPool(address _addr,uint8 _level) private {
        if(autousers[_addr][_level].upline == address(0) && !users[_addr].activeMatrix[_level] && _level<7) {
            uint256 totalteam=(pool_user[_level]-(pool_user[_level]%index[_level]==0?1: pool_user[_level]%index[_level]))/index[_level]+1;
            autousers[_addr][_level].upline=address(uint160(autopool_useraddress[totalteam][_level]));
            pool_user[_level]+=1;
            autopool_useraddress[pool_user[_level]][_level]=_addr;
            users[_addr].activeMatrix[_level]=true;
            emit Upgrade(_addr,autousers[_addr][_level].upline,_level);
            _autoPool(_addr,_level);
        }
    }
    function _autoPool(address _addr,uint8 _level) private {
        address payable up =autousers[_addr][_level].upline;
        autousers[up][_level].referrals.push(_addr);
        emit NewUserPlace(_addr, up, _level,uint8(autousers[up][_level].referrals.length));
        up.transfer(autopool_bonuses[_level]);
        if(autousers[up][_level].referrals.length==index[_level])
        {
           _setAutoPool(up,(_level+1));
        }
    }
    
    function _setAutoPoolFree(address _addr,uint8 _level) private {
        if(autousers[_addr][_level].upline == address(0) && !users[_addr].activeMatrix[_level] && _level<7) {
            uint256 totalteam=(pool_user[_level]-(pool_user[_level]%index[_level]==0?1: pool_user[_level]%index[_level]))/index[_level]+1;
            autousers[_addr][_level].upline=address(uint160(autopool_useraddress[totalteam][_level]));
            pool_user[_level]+=1;
            autopool_useraddress[pool_user[_level]][_level]=_addr;
            users[_addr].activeMatrix[_level]=true;
            emit Upgrade(_addr,autousers[_addr][_level].upline,_level);
            _autoPoolFree(_addr,_level);
        }
    }
    function _autoPoolFree(address _addr,uint8 _level) private {
        address payable up =autousers[_addr][_level].upline;
        autousers[up][_level].referrals.push(_addr);
        emit NewUserPlace(_addr, up, _level,uint8(autousers[up][_level].referrals.length));
        if(autousers[up][_level].referrals.length==index[_level])
        {
           _setAutoPool(up,(_level+1));
        }
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    function setWithdrawFee(address payable _platform_fee) public {
        if (msg.sender != owner) {revert("Access Denied");}
		platform_fee=_platform_fee;
    }
}