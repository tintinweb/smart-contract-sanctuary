//SourceUnit: cryptotejaslive.sol

pragma solidity 0.5.10;

/**
*
* 
*Publish Date:12th Sep 2021
* 
*Final Publish Date:12th Sep 2021
* 
*Coding Level: High
* 
*CRYPTO TEJAS TRX COMMUNITY
*
* 
**/

contract CRYPTO_TEJAS_COMMUNITY {
    
     struct User {
        uint id;
        address referrer;
        mapping(uint8 => bool) activeMatrixLevels;
        mapping(uint8 => bool) globalMatrixactiveLevels;
        mapping(uint8 => bool) poolMatrixactiveLevels;
    }
    
    uint public constant RegistrationTRX = 100;
    
    uint8 public constant LAST_LEVEL_MATRIX = 6;
    uint8 public constant LAST_LEVEL_GLOBALMATRIX = 8;
    uint8 public constant LAST_LEVEL_POOLMATRIX = 8;
    
    
    mapping(address => User) public users;
    
    mapping(uint8 => uint) public matrixPrice;
    
    mapping(uint8 => uint) public globalMatrixPrice;
    
    mapping(uint8 => uint) public poolMatrixPrice;

    uint public lastUserId = 1;
    
    address public owner;
    
    event Upgradematrix(address indexed user);
    
    event UpgradeGlobalmatrix(address indexed user);
    
    event UpgradePoolmatrix(address indexed user);

    event Registration(address indexed user, address indexed referrer);
    
    event WithdrawTron();

    constructor(address ownerAddress) public {
        
        matrixPrice[1] = 100;
        matrixPrice[2] = 250;
        matrixPrice[3] = 1000;
        matrixPrice[4] = 4000;
        matrixPrice[5] = 15000;
        matrixPrice[6] = 30000;

        globalMatrixPrice[1] = 150;
        globalMatrixPrice[2] = 450;
        globalMatrixPrice[3] = 1350;
        globalMatrixPrice[4] = 4050;
        globalMatrixPrice[5] = 12150;
        globalMatrixPrice[6] = 36450;
        globalMatrixPrice[7] = 109350;
        globalMatrixPrice[8] = 328050;
        
        
        poolMatrixPrice[1] = 100;
        poolMatrixPrice[2] = 400;
        poolMatrixPrice[3] = 1600;
        poolMatrixPrice[4] = 6400;
        poolMatrixPrice[5] = 25600;
        poolMatrixPrice[6] = 102400;
        poolMatrixPrice[7] = 409600;
        poolMatrixPrice[8] = 1638400;


        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0)
        });
        
        for (uint8 i = 0; i <= LAST_LEVEL_MATRIX; i++) {
            users[ownerAddress].activeMatrixLevels[i] = true;
        } 
        
        for (uint8 i = 0; i <= LAST_LEVEL_GLOBALMATRIX; i++) {
            users[ownerAddress].globalMatrixactiveLevels[i] = true;
        } 
        
        for (uint8 i = 0; i <= LAST_LEVEL_POOLMATRIX; i++) {
            users[ownerAddress].poolMatrixactiveLevels[i] = true;
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
        
        require(!users[msg.sender].activeMatrixLevels[level], "You Have Already Upgraded");
        
        require(level >= 1 && level <= LAST_LEVEL_MATRIX, "Invalid Level");
        
        if(level>1)
        {
            require(users[msg.sender].activeMatrixLevels[level-1], "Buy Previous Level First");
        }
        
        require(msg.value == matrixPrice[level]*1000000 , "Invalid Level Price");
        
        users[msg.sender].activeMatrixLevels[level] = true;
       
        upgradeLevel(msg.sender);
            
        emit Upgradematrix(msg.sender);
            
    } 
    
    
    function buyGlobalMatrixNewLevel(uint8 level) external payable {
            
        require(isUserExists(msg.sender), "User Not Exists. Need To Register First.");
        
        require(!users[msg.sender].globalMatrixactiveLevels[level], "You Have Already Upgraded");
        
        require(level >= 1 && level <= LAST_LEVEL_GLOBALMATRIX, "Invalid Level");
        
        if(level>1)
        {
         require(users[msg.sender].globalMatrixactiveLevels[level-1], "Buy Previous Level First");
        }
        
        require(msg.value == globalMatrixPrice[level]*1000000 , "Invalid Level Price");
        
        users[msg.sender].globalMatrixactiveLevels[level] = true;
       
        upgradeGlobalMatrixPackage(msg.sender);
            
        emit UpgradeGlobalmatrix(msg.sender);
            
    }
    
    
    function buyPoolLevel(uint8 level) external payable {
            
        require(isUserExists(msg.sender), "User Not Exists. Need To Register First.");
        
        require(!users[msg.sender].poolMatrixactiveLevels[level], "You Have Already Upgraded");
        
        require(level >= 1 && level <= LAST_LEVEL_POOLMATRIX, "Invalid Level");
        
        if(level>1)
        {
         require(users[msg.sender].poolMatrixactiveLevels[level-1], "Buy Previous Level First");
        }
        
        require(msg.value == poolMatrixPrice[level]*1000000 , "Invalid Level Price");
        
        users[msg.sender].poolMatrixactiveLevels[level] = true;
       
        upgradePoolMatrixPackage(msg.sender);
            
        emit UpgradePoolmatrix(msg.sender);
            
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
        
        lastUserId++;

        sendTRXDividends();
        
        emit Registration(userAddress, referrerAddress);
    }
    
    function upgradeLevel(address userAddress) private {
        sendTRXDividends();
    }
    
    function upgradeGlobalMatrixPackage(address userAddress) private {
        sendTRXDividends();
    }
    
    function upgradePoolMatrixPackage(address userAddress) private {
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