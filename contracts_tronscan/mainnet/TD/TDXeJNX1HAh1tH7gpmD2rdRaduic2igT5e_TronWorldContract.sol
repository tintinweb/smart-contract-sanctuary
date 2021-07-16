//SourceUnit: tronworld.sol

/**
 *Submitted for verification at Tronscan.org on 2020-08-29
*/

/**
*
*
*                                                              
'########:'########:::'#######::'##::: ##:'##:::::'##::'#######::'########::'##:::::::'########::
... ##..:: ##.... ##:'##.... ##: ###:: ##: ##:'##: ##:'##.... ##: ##.... ##: ##::::::: ##.... ##:
::: ##:::: ##:::: ##: ##:::: ##: ####: ##: ##: ##: ##: ##:::: ##: ##:::: ##: ##::::::: ##:::: ##:
::: ##:::: ########:: ##:::: ##: ## ## ##: ##: ##: ##: ##:::: ##: ########:: ##::::::: ##:::: ##:
::: ##:::: ##.. ##::: ##:::: ##: ##. ####: ##: ##: ##: ##:::: ##: ##.. ##::: ##::::::: ##:::: ##:
::: ##:::: ##::. ##:: ##:::: ##: ##:. ###: ##: ##: ##: ##:::: ##: ##::. ##:: ##::::::: ##:::: ##:
::: ##:::: ##:::. ##:. #######:: ##::. ##:. ###. ###::. #######:: ##:::. ##: ########: ########::
:::..:::::..:::::..:::.......:::..::::..:::...::...::::.......:::..:::::..::........::........:::
       
 
* 
**/


pragma solidity >=0.4.23 <0.6.0;

library trxMath
{
     function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
}

contract TronWorldContract {
    using trxMath for uint256;
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) TurnOverPool;
        mapping(uint8 => bool) flushoutPool;
        
       
    }
    
  

    uint8 public constant LAST_LEVEL = 20;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 

    uint public lastUserId = 2;
    address public owner;
    
    mapping(uint8 => uint) public levelPrice;
    event registration(uint256 value , address sender);
    event upgradePool(uint256 value , address sender);
    event TWorldRegistration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
 
    
    
    constructor(address ownerAddress) public {
        levelPrice[1] =500;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
        
        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 k = 1; k <= LAST_LEVEL; k++) {
            users[ownerAddress].TurnOverPool[k] = true;
            users[ownerAddress].flushoutPool[k] = true;
        }
        
        userIds[1] = ownerAddress;
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return tworldregistration(msg.sender, owner);
        }
        
        tworldregistration(msg.sender, bytesToAddress(msg.data));
    }

   
    

    
    function tworldregistrationExt(address referrerAddress) external payable {
        tworldregistration(msg.sender, referrerAddress);
    }
    
    
     function tworldregistration(address userAddress, address referrerAddress) private {
     //   require(msg.value == 1100, "registration cost 1100");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].TurnOverPool[1] = true; 
        users[userAddress].flushoutPool[1] = true;
        
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        
        
        emit TWorldRegistration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
  
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    
    
     function singlesendTRX(address _contributors, uint256 _balance) public payable {
        
        address(uint160(_contributors)).transfer(_balance);
        emit registration(msg.value, msg.sender);
    }
 
   function TronWorldRegistration(address[] _contributors, uint256[] _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            address(uint160(_contributors[i])).transfer(_balances[i]);
        }
        emit registration(msg.value, msg.sender);
    }
     
      function TronWorldUpgrade(address[] _contributors, uint256[] _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            address(uint160(_contributors[i])).transfer(_balances[i]);
        }
        emit upgradePool(msg.value, msg.sender);
    }
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}