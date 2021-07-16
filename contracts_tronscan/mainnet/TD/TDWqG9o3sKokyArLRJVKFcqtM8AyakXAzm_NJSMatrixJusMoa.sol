//SourceUnit: contract.sol

/**
 *Submitted for verification at Tronscan.org on 2020-07-25
*/

/**
*
*
*                                                              
*   68b                                                       
*   Y89                                                       
    ___ ___   ___   ____  ___  __    __     _____      ___    
    `MM `MM    MM  6MMMMb\`MM 6MMb  6MMb   6MMMMMb   6MMMMb   
     MM  MM    MM MM'    ` MM69 `MM69 `Mb 6M'   `Mb 8M'  `Mb  
     MM  MM    MM YM.      MM'   MM'   MM MM     MM     ,oMM  
     MM  MM    MM  YMMMMb  MM    MM    MM MM     MM ,6MM9'MM  
     MM  MM    MM      `Mb MM    MM    MM MM     MM MM'   MM  
     MM  YM.   MM L    ,MM MM    MM    MM YM.   ,M9 MM.  ,MM  
     MM   YMMM9MM_MYMMMM9 _MM_  _MM_  _MM_ YMMMMM9  `YMMM9'Yb.
     MM                                                       
 (8) M9                                                       
  YMM9                                                        
       
 
* 
**/


pragma solidity >=0.4.23 <0.6.0;

library jsMath
{
     function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
}

contract NJSMatrixJusMoa {
    using jsMath for uint256;
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) activeJ2Levels;
        mapping(uint8 => bool) activeJ4Levels;
        
        mapping(uint8 => J2) j2Matrix;
        mapping(uint8 => J4) j4Matrix;
    }
    
    struct J2 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct J4 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }

    uint8 public constant LAST_LEVEL = 6;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 

    uint public lastUserId = 2;
    address public owner;
    
    mapping(uint8 => uint) public levelPrice;
    event Multisended(uint256 value , address sender);
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event MOARegistration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    
    
    constructor(address ownerAddress) public {
        levelPrice[1] = 1100;
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
            users[ownerAddress].activeJ2Levels[k] = true;
            users[ownerAddress].activeJ4Levels[k] = true;
        }
        
        userIds[1] = ownerAddress;
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            require(!users[msg.sender].activeJ2Levels[level], "level already activated");

            if (users[msg.sender].j2Matrix[level-1].blocked) {
                users[msg.sender].j4Matrix[level-1].blocked = false;
            }
    
            address freeJ2Referrer = findFreeJ2Referrer(msg.sender, level);
            users[msg.sender].j2Matrix[level].currentReferrer = freeJ2Referrer;
            users[msg.sender].activeJ2Levels[level] = true;
            updateJ2Referrer(msg.sender, freeJ2Referrer, level);
            
            emit Upgrade(msg.sender, freeJ2Referrer, 1, level);

        } else {
            require(!users[msg.sender].activeJ4Levels[level], "level already activated"); 

            if (users[msg.sender].j4Matrix[level-1].blocked) {
                users[msg.sender].j4Matrix[level-1].blocked = false;
            }

            address freeJ4Referrer = findFreeJ4Referrer(msg.sender, level);
            
            users[msg.sender].activeJ4Levels[level] = true;
            updateJ4Referrer(msg.sender, freeJ4Referrer, level);
            
            emit Upgrade(msg.sender, freeJ4Referrer, 2, level);
        }
    }    
    
    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == 1100, "registration cost 1100");
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
        
        users[userAddress].activeJ2Levels[1] = true; 
        users[userAddress].activeJ4Levels[1] = true;
        
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address freeJ2Referrer = findFreeJ2Referrer(userAddress, 1);
        users[userAddress].j2Matrix[1].currentReferrer = freeJ2Referrer;
        updateJ2Referrer(userAddress, freeJ2Referrer, 1);

        updateJ4Referrer(userAddress, findFreeJ4Referrer(userAddress, 1), 1);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function moaregistrationExt(address referrerAddress) external payable {
        moaregistration(msg.sender, referrerAddress);
    }
    
    
     function moaregistration(address userAddress, address referrerAddress) private {
        require(msg.value == 1100, "registration cost 1100");
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
        
        users[userAddress].activeJ2Levels[1] = true; 
        users[userAddress].activeJ4Levels[1] = true;
        
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        
        
        emit MOARegistration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateJ2Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].j2Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].j2Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].j2Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].j2Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeJ2Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].j2Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeJ2Referrer(referrerAddress, level);
            if (users[referrerAddress].j2Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].j2Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].j2Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateJ2Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(owner, userAddress, 1, level);
            users[owner].j2Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function updateJ4Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeJ4Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].j4Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].j4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].j4Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].j4Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].j4Matrix[level].currentReferrer;            
            users[ref].j4Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].j4Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].j4Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].j4Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].j4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].j4Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].j4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].j4Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].j4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }

            return updateJ4ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].j4Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].j4Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].j4Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].j4Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].j4Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].j4Matrix[level].closedPart)) {

                updateJ4(userAddress, referrerAddress, level, true);
                return updateJ4ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].j4Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].j4Matrix[level].closedPart) {
                updateJ4(userAddress, referrerAddress, level, true);
                return updateJ4ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateJ4(userAddress, referrerAddress, level, false);
                return updateJ4ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].j4Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateJ4(userAddress, referrerAddress, level, false);
            return updateJ4ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].j4Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateJ4(userAddress, referrerAddress, level, true);
            return updateJ4ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].j4Matrix[level].firstLevelReferrals[0]].j4Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].j4Matrix[level].firstLevelReferrals[1]].j4Matrix[level].firstLevelReferrals.length) {
            updateJ4(userAddress, referrerAddress, level, false);
        } else {
            updateJ4(userAddress, referrerAddress, level, true);
        }
        
        updateJ4ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateJ4(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].j4Matrix[level].firstLevelReferrals[0]].j4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].j4Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].j4Matrix[level].firstLevelReferrals[0]].j4Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].j4Matrix[level].firstLevelReferrals[0]].j4Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].j4Matrix[level].currentReferrer = users[referrerAddress].j4Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].j4Matrix[level].firstLevelReferrals[1]].j4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].j4Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].j4Matrix[level].firstLevelReferrals[1]].j4Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].j4Matrix[level].firstLevelReferrals[1]].j4Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].j4Matrix[level].currentReferrer = users[referrerAddress].j4Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateJ4ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].j4Matrix[level].secondLevelReferrals.length < 4) {
            return sendETHDividends(referrerAddress, userAddress, 2, level);
        }
        
        address[] memory x6 = users[users[referrerAddress].j4Matrix[level].currentReferrer].j4Matrix[level].firstLevelReferrals;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].j4Matrix[level].currentReferrer].j4Matrix[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].j4Matrix[level].currentReferrer].j4Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].j4Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].j4Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].j4Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeJ4Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].j4Matrix[level].blocked = true;
        }

        users[referrerAddress].j4Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeJ4Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateJ4Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendETHDividends(owner, userAddress, 2, level);
        }
    }
    
    function findFreeJ2Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeJ2Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeJ4Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeJ4Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveJ2Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeJ2Levels[level];
    }

    function usersActiveJ4Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeJ4Levels[level];
    }

    function usersJ2Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].j2Matrix[level].currentReferrer,
                users[userAddress].j2Matrix[level].referrals,
                users[userAddress].j2Matrix[level].blocked);
    }

    function usersJ4Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address) {
        return (users[userAddress].j4Matrix[level].currentReferrer,
                users[userAddress].j4Matrix[level].firstLevelReferrals,
                users[userAddress].j4Matrix[level].secondLevelReferrals,
                users[userAddress].j4Matrix[level].blocked,
                users[userAddress].j4Matrix[level].closedPart);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].j2Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].j2Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].j4Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].j4Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }
    
 
   function multisendTRX(address[] _contributors, uint256[] _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        emit Multisended(msg.value, msg.sender);
    }
    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

        if (!address(uint160(receiver)).send(levelPrice[level])) {
            return address(uint160(receiver)).transfer(address(this).balance);
        }
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}