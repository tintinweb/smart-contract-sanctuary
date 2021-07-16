//SourceUnit: LionsShareTron_OFFICIAL.sol


pragma solidity 0.4.25;

contract LionsShareTron_OFFICIAL {
    

    //User details
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) activeM1Levels;
        mapping(uint8 => bool) activeM2Levels;
        
        mapping(uint8 => M1) m1Matrix;
        mapping(uint8 => M2) m2Matrix;

        uint256 dividendReceived;
    }
    
    // X3 matrix
    struct M1 {
        address Senior;
        address[] Juniors;
        bool blocked;
        uint reinvestCount;
    }
    

    //X4 matrix
    struct M2 {
        address Senior;
        address[] firstLevelJuniors;
        address[] secondLevelJuniors;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }

    uint8 public constant LAST_LEVEL = 15;
    
    mapping(address => User) public users;
    mapping(uint => address) public userIds; 

    uint public lastUserId = 4;
    address public owner;
    
    //declare prices for each levels
    mapping(uint8 => uint) public levelPrice;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed Senior, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    
    
    constructor(address ownerAddress, address ID2, address ID3) public {
        //sets first level price
        levelPrice[1] = 100 trx;

        //sets all other levels price by doubling first level prive
        levelPrice[2] = 200 trx;
        levelPrice[3] = 400 trx;
        levelPrice[4] = 600 trx;
        levelPrice[5] = 1000 trx;
        levelPrice[6] = 1500 trx;
        levelPrice[7] = 2000 trx;
        levelPrice[8] = 3000 trx;
        levelPrice[9] = 4000 trx;
        levelPrice[10] = 5000 trx;
        levelPrice[11] = 6000 trx;
        levelPrice[12] = 7000 trx;
	levelPrice[13] = 8000 trx;
	levelPrice[14] = 10000 trx;
	levelPrice[15] = 15000 trx;
        

        //sets owner address 
        owner = ownerAddress;
        

        //Declare first user from struct
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: 2,
            dividendReceived:0
        });
        
        User memory two = User({
            id: 2,
            referrer: ownerAddress,
            partnersCount: uint(0),
            dividendReceived:0
        });
        
        User memory three = User({
            id: 3,
            referrer: ownerAddress,
            partnersCount: uint(0),
            dividendReceived:0
        });
        
        // add first user to users mapping (address to User struct mapping)
        users[ownerAddress] = user;
        users[ID2] = two;
        users[ID3] = three;

        
        
        users[ownerAddress].m1Matrix[1].Juniors.push(ID2);
        users[ownerAddress].m1Matrix[1].Juniors.push(ID3);
        
        users[ownerAddress].m2Matrix[1].firstLevelJuniors.push(ID2);
        users[ownerAddress].m2Matrix[1].firstLevelJuniors.push(ID3);
        
        users[ID2].m1Matrix[1].Senior = ownerAddress;
        users[ID3].m1Matrix[1].Senior = ownerAddress;

        // activeX3Levels is mapping in Users struct (integer to bool)  users is mapping (address to User struct)
        // activate all the levels for x3 and x4 for first user
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeM1Levels[i] = true;
            users[ownerAddress].activeM2Levels[i] = true;
            
            users[ID2].activeM1Levels[i] = true;
            users[ID2].activeM2Levels[i] = true;
            
            users[ID3].activeM1Levels[i] = true;
            users[ID3].activeM2Levels[i] = true;
        }
        
        // userIds is mapping from integer to address
        userIds[1] = ownerAddress;
        userIds[2] = ID2;
        userIds[3] = ID3;
    }


    
    
    function registerFirsttime() public payable returns(bool) {
        registration(msg.sender, owner);
        return true;
    }


    //registration with referral address
    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }
    

    //buy level function payament
    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        //isUserExists is function at line 407 checks if user exists
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        // levelPrice is mapping from integer(level) to integer(price) at line 51
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            require(!users[msg.sender].activeM1Levels[level], "level already activated");

            if (users[msg.sender].m1Matrix[level-1].blocked) {
                users[msg.sender].m1Matrix[level-1].blocked = false;
            }
    
            address m1referrer = findm1referrer(msg.sender, level);
            //X3 matrix is mapping from integer to X3 struct
            users[msg.sender].m1Matrix[level].Senior = m1referrer;
            users[msg.sender].activeM1Levels[level] = true;
            updateM1referrer(msg.sender, m1referrer, level);
            
            emit Upgrade(msg.sender, m1referrer, 1, level);

        } else {
            require(!users[msg.sender].activeM2Levels[level], "level already activated"); 

            if (users[msg.sender].m2Matrix[level-1].blocked) {
                users[msg.sender].m2Matrix[level-1].blocked = false;
            }

            address m2referrer = findm2referrer(msg.sender, level);
            
            users[msg.sender].activeM2Levels[level] = true;
            updateM2referrer(msg.sender, m2referrer, level);
            
            emit Upgrade(msg.sender, m2referrer, 2, level);
        }
    }

    function findm1referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            // activeM1Levels is mapping integer to bool
            // if referrer is already there for User return referrer address
            if (users[users[userAddress].referrer].activeM1Levels[level]) {
                return users[userAddress].referrer;
            }
            
            // else set userAddress as referrer address in User struct
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findm2referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeM2Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveM1Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeM1Levels[level];
    }

    function usersActiveM2Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeM2Levels[level];
    }

    function usersM1Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool, uint) {
        return (users[userAddress].m1Matrix[level].Senior,
                users[userAddress].m1Matrix[level].Juniors,
                users[userAddress].m1Matrix[level].blocked,
                users[userAddress].m1Matrix[level].reinvestCount);
    }

    function usersM2Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, uint) {
        return (users[userAddress].m2Matrix[level].Senior,
                users[userAddress].m2Matrix[level].firstLevelJuniors,
                users[userAddress].m2Matrix[level].secondLevelJuniors,
                users[userAddress].m2Matrix[level].blocked,
                users[userAddress].m2Matrix[level].reinvestCount);
    }
    
    // checks if user exists from users mapping(address to User struct) and id property of User struct
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }    
    
    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == 200 trx, "registration cost 200 trx");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer does not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            dividendReceived:0
        });
        
        users[userAddress] = user;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeM1Levels[1] = true; 
        users[userAddress].activeM2Levels[1] = true;
        
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address m1referrer = findm1referrer(userAddress, 1);
        users[userAddress].m1Matrix[1].Senior = m1referrer;
        updateM1referrer(userAddress, m1referrer, 1);

        updateM2referrer(userAddress, findm2referrer(userAddress, 1), 1);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    

    function updateM1referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].m1Matrix[level].Juniors.push(userAddress);

        if (users[referrerAddress].m1Matrix[level].Juniors.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].m1Matrix[level].Juniors.length));
            //sendETHDividends is function accepts arguments (useraddress, _from , matrix, level)
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].m1Matrix[level].Juniors = new address[](0);
        if (!users[referrerAddress].activeM1Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].m1Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findm1referrer(referrerAddress, level);
            if (users[referrerAddress].m1Matrix[level].Senior != freeReferrerAddress) {
                users[referrerAddress].m1Matrix[level].Senior = freeReferrerAddress;
            }
            
            users[referrerAddress].m1Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateM1referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(owner, userAddress, 1, level);
            users[owner].m1Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function updateM2referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeM2Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].m2Matrix[level].firstLevelJuniors.length < 2) {
            users[referrerAddress].m2Matrix[level].firstLevelJuniors.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].m2Matrix[level].firstLevelJuniors.length));
            
            //set current level
            users[userAddress].m2Matrix[level].Senior = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].m2Matrix[level].Senior;            
            users[ref].m2Matrix[level].secondLevelJuniors.push(userAddress); 
            
            uint len = users[ref].m2Matrix[level].firstLevelJuniors.length;
            
            if ((len == 2) && 
                (users[ref].m2Matrix[level].firstLevelJuniors[0] == referrerAddress) &&
                (users[ref].m2Matrix[level].firstLevelJuniors[1] == referrerAddress)) {
                if (users[referrerAddress].m2Matrix[level].firstLevelJuniors.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].m2Matrix[level].firstLevelJuniors[0] == referrerAddress) {
                if (users[referrerAddress].m2Matrix[level].firstLevelJuniors.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].m2Matrix[level].firstLevelJuniors[1] == referrerAddress) {
                if (users[referrerAddress].m2Matrix[level].firstLevelJuniors.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }

            return updateM2referrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].m2Matrix[level].secondLevelJuniors.push(userAddress);

        if (users[referrerAddress].m2Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].m2Matrix[level].firstLevelJuniors[0] == 
                users[referrerAddress].m2Matrix[level].firstLevelJuniors[1]) &&
                (users[referrerAddress].m2Matrix[level].firstLevelJuniors[0] ==
                users[referrerAddress].m2Matrix[level].closedPart)) {

                updateX6(userAddress, referrerAddress, level, true);
                return updateM2referrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].m2Matrix[level].firstLevelJuniors[0] == 
                users[referrerAddress].m2Matrix[level].closedPart) {
                updateX6(userAddress, referrerAddress, level, true);
                return updateM2referrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateX6(userAddress, referrerAddress, level, false);
                return updateM2referrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].m2Matrix[level].firstLevelJuniors[1] == userAddress) {
            updateX6(userAddress, referrerAddress, level, false);
            return updateM2referrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].m2Matrix[level].firstLevelJuniors[0] == userAddress) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateM2referrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].m2Matrix[level].firstLevelJuniors[0]].m2Matrix[level].firstLevelJuniors.length <= 
            users[users[referrerAddress].m2Matrix[level].firstLevelJuniors[1]].m2Matrix[level].firstLevelJuniors.length) {
            updateX6(userAddress, referrerAddress, level, false);
        } else {
            updateX6(userAddress, referrerAddress, level, true);
        }
        
        updateM2referrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].m2Matrix[level].firstLevelJuniors[0]].m2Matrix[level].firstLevelJuniors.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].m2Matrix[level].firstLevelJuniors[0], 2, level, uint8(users[users[referrerAddress].m2Matrix[level].firstLevelJuniors[0]].m2Matrix[level].firstLevelJuniors.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].m2Matrix[level].firstLevelJuniors[0]].m2Matrix[level].firstLevelJuniors.length));
            //set current level
            users[userAddress].m2Matrix[level].Senior = users[referrerAddress].m2Matrix[level].firstLevelJuniors[0];
        } else {
            users[users[referrerAddress].m2Matrix[level].firstLevelJuniors[1]].m2Matrix[level].firstLevelJuniors.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].m2Matrix[level].firstLevelJuniors[1], 2, level, uint8(users[users[referrerAddress].m2Matrix[level].firstLevelJuniors[1]].m2Matrix[level].firstLevelJuniors.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].m2Matrix[level].firstLevelJuniors[1]].m2Matrix[level].firstLevelJuniors.length));
            //set current level
            users[userAddress].m2Matrix[level].Senior = users[referrerAddress].m2Matrix[level].firstLevelJuniors[1];
        }
    }
    
    function updateM2referrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].m2Matrix[level].secondLevelJuniors.length < 4) {
            return sendETHDividends(referrerAddress, userAddress, 2, level);
        }
        
        address[] memory x6 = users[users[referrerAddress].m2Matrix[level].Senior].m2Matrix[level].firstLevelJuniors;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].m2Matrix[level].Senior].m2Matrix[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].m2Matrix[level].Senior].m2Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].m2Matrix[level].firstLevelJuniors = new address[](0);
        users[referrerAddress].m2Matrix[level].secondLevelJuniors = new address[](0);
        users[referrerAddress].m2Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeM2Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].m2Matrix[level].blocked = true;
        }

        users[referrerAddress].m2Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findm2referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateM2referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendETHDividends(owner, userAddress, 2, level);
        }
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].m1Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].m1Matrix[level].Senior;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].m2Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].m2Matrix[level].Senior;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

        if (!address(uint160(receiver)).send(levelPrice[level])) {
            users[receiver].dividendReceived = users[receiver].dividendReceived + address(this).balance;
            return address(uint160(receiver)).transfer(address(this).balance);
        }
        users[receiver].dividendReceived = users[receiver].dividendReceived + levelPrice[level];
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }
    
}