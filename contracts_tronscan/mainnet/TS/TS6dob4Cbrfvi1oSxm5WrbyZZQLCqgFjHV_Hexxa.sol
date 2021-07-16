//SourceUnit: Hexxa.sol

/**
**/


pragma solidity >=0.4.23 <0.6.0;

contract Hexxa  {
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        bool part;
        bool owner;

        mapping(uint8 => bool) activeM3Levels;
        mapping(uint8 => bool) activeM4Levels;
        mapping(uint8 => bool) activeM9Levels;

        mapping(uint8 => bool) activeA3Levels;
        mapping(uint8 => bool) activeA4Levels;
        mapping(uint8 => bool) activeA9Levels;
        
        mapping(uint8 => M3) m3Matrix;
        mapping(uint8 => M4) m4Matrix;
        mapping(uint8 => M9) m9Matrix;

        mapping(uint8 => M3) a3Matrix;
        mapping(uint8 => M4) a4Matrix;
        mapping(uint8 => M9) a9Matrix;
    }
    
    struct M3 {
        address currentReferrer;
        address[] referrals;
        uint reinvestCount;
    }
    
    struct M4 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        uint reinvestCount;

        address closedPart;
    }

    struct M9 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        uint reinvestCount;

        address closedPart1;
        address closedPart2;
        address closedPart3;
    }

    uint8 public constant LAST_LEVEL = 15;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 

    uint public lastUserId = 2;
    address public owner;
    
    mapping(uint8 => uint) public levelPrice;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedTronReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraTronDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    
    address[] public owners;
    uint private ownersPay = 0;

    
    constructor() public {
        levelPrice[1] = 125000000;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
        address ownerAddress = msg.sender;
        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            part: false,
            owner: false
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeM3Levels[i] = true;
            users[ownerAddress].activeM4Levels[i] = true;
            users[ownerAddress].activeM9Levels[i] = true;

            users[ownerAddress].activeA3Levels[i] = true;
            users[ownerAddress].activeA4Levels[i] = true;
            users[ownerAddress].activeA9Levels[i] = true;

            emit NewUserPlace(owner, address(0), 1, i, 1);
            emit NewUserPlace(owner, address(0), 2, i, 1);
            emit NewUserPlace(owner, address(0), 3, i, 1);
            emit NewUserPlace(owner, address(0), 4, i, 1);
            emit NewUserPlace(owner, address(0), 5, i, 1);
            emit NewUserPlace(owner, address(0), 6, i, 1);

        }
        
        userIds[1] = ownerAddress;
    }
    
    function() external payable {
        
    }
    function addBalance() external payable {
        require(msg.sender == owner, "not owner");
    }
    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }
    function transformToOwner(address _address) external {
        require(msg.sender == owner, "invalid price");
        require(isUserExists(_address), "user not exists");
        users[_address].owner = true;
    }
    function transformToUser(address _address) external {
        require(msg.sender == owner, "invalid price");
        require(isUserExists(_address), "user not exists");
        users[_address].owner = false;
    }
    function loadUsers() external {
        require(msg.sender == owner, "invalid price");
        registrationPart(address(0),owner, 4, 1,true,false);
        
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            buyNewLevelPart(idToAddress[lastUserId-1],1,i);
            buyNewLevelPart(idToAddress[lastUserId-1],2,i);
            buyNewLevelPart(idToAddress[lastUserId-1],3,i);
        }
    }
    function loadUsersOwners(address _address) external {
        require(msg.sender == owner, "invalid price");
        registrationPart(address(0), _address, 4, 1,true,false);
        
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            buyNewLevelPart(idToAddress[lastUserId-1],1,i);
            buyNewLevelPart(idToAddress[lastUserId-1],2,i);
            buyNewLevelPart(idToAddress[lastUserId-1],3,i);
        }
    }
    function upgradeUsersOwners(address _address, uint8 _level) external {
        require(msg.sender == owner, "invalid price");
        
        buyNewLevelPart(_address,1,_level);
        buyNewLevelPart(_address,2,_level);
        buyNewLevelPart(_address,3,_level);

    }
    function changePrice(uint newprice) external {
        require(msg.sender == owner, "invalid price");
        levelPrice[1] = newprice;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
    }
    function registrationMigration(address userAddress, address referrerAddress, uint matrix, uint8 slot, bool part, bool _owner) external {
        require(msg.sender == owner, "invalid price");
        registrationPart(userAddress, referrerAddress, matrix, slot, part, _owner);
       
    }
    function registrationPart( address userAddress, address referrerAddress, uint matrix, uint8 slot, bool part, bool _owner) private {
        require(isUserExists(referrerAddress), "referrer not exists");

        if(userAddress == address(0)) {
            userAddress = address(lastUserId);
        }                      
        /*while(isUserExists(userAddress)) {
          userAddress = address(bytes20(sha256(abi.encodePacked('block.timestamp'))));
        }*/
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            part: part,
            owner: _owner
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeM3Levels[1] = true; 
        users[userAddress].activeM4Levels[1] = true;
        users[userAddress].activeM9Levels[1] = true;
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;
        
        if(matrix == 1) {
            updateM3Referrer(userAddress, referrerAddress, slot);
        }
        if(matrix == 2) {
            updateM4Referrer(userAddress, referrerAddress, slot);
        }
        if(matrix == 3) {
            updateM9Referrer(userAddress, referrerAddress, slot);
        }
        if(matrix == 4) {
            updateM3Referrer(userAddress, referrerAddress, slot);
            updateM4Referrer(userAddress, referrerAddress, slot);
            updateM9Referrer(userAddress, referrerAddress, slot);
        }
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    function buyNewLevelnMigration(address user, uint8 matrix, uint8 level) external {
        require(msg.sender == owner, "invalid price");
        buyNewLevelPart(user,matrix,level);
    }
    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2 || matrix == 3, "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            require(!users[msg.sender].activeM3Levels[level], "level already activated");
    
            address freeM3Referrer = findFreeM3Referrer(msg.sender, level);
            users[msg.sender].m3Matrix[level].currentReferrer = freeM3Referrer;
            users[msg.sender].activeM3Levels[level] = true;
            updateM3Referrer(msg.sender, freeM3Referrer, level);
            
            emit Upgrade(msg.sender, freeM3Referrer, 1, level);

        } else if(matrix == 2) {
            require(!users[msg.sender].activeM4Levels[level], "level already activated"); 

            address freeM4Referrer = findFreeM4Referrer(msg.sender, level);
            
            users[msg.sender].activeM4Levels[level] = true;
            updateM4Referrer(msg.sender, freeM4Referrer, level);
            
            emit Upgrade(msg.sender, freeM4Referrer, 2, level);
        } else {
            require(!users[msg.sender].activeM9Levels[level], "level already activated"); 

            address freeM9Referrer = findFreeM9Referrer(msg.sender, level);
            
            users[msg.sender].activeM9Levels[level] = true;
            updateM9Referrer(msg.sender, freeM9Referrer, level);
            
            emit Upgrade(msg.sender, freeM9Referrer, 3, level);
        }
    }
    function buyNewLevelPart(address user, uint8 matrix, uint8 level) private {
        require(isUserExists(user), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2 || matrix == 3, "invalid matrix");
        require(msg.sender == owner, "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            require(!users[user].activeM3Levels[level], "level already activated");
    
            address freeM3Referrer = findFreeM3Referrer(user, level);
            users[user].m3Matrix[level].currentReferrer = freeM3Referrer;
            users[user].activeM3Levels[level] = true;
            updateM3Referrer(user, freeM3Referrer, level);
            
            emit Upgrade(user, freeM3Referrer, 1, level);

        } else if(matrix == 2) {
            require(!users[user].activeM4Levels[level], "level already activated"); 

            address freeM4Referrer = findFreeM4Referrer(user, level);
            
            users[user].activeM4Levels[level] = true;
            updateM4Referrer(user, freeM4Referrer, level);
            
            emit Upgrade(user, freeM4Referrer, 2, level);
        } else {
            require(!users[user].activeM9Levels[level], "level already activated"); 

            address freeM9Referrer = findFreeM9Referrer(user, level);
            
            users[user].activeM9Levels[level] = true;
            updateM9Referrer(user, freeM9Referrer, level);
            
            emit Upgrade(user, freeM9Referrer, 3, level);
        }
    }
    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == (levelPrice[1]*3), "registration cost 375");
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
            partnersCount: 0,
            part: false,
            owner: false
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeM3Levels[1] = true; 
        users[userAddress].activeM4Levels[1] = true;
        users[userAddress].activeM9Levels[1] = true;
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address freeM3Referrer = findFreeM3Referrer(userAddress, 1);
        users[userAddress].m3Matrix[1].currentReferrer = freeM3Referrer;
        updateM3Referrer(userAddress, freeM3Referrer, 1);

        updateM4Referrer(userAddress, findFreeM4Referrer(userAddress, 1), 1);

        updateM9Referrer(userAddress, findFreeM9Referrer(userAddress, 1), 1);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    

    function updateM3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].m3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].m3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].m3Matrix[level].referrals.length));
            if( owner != referrerAddress 
                && level == 1 
                && users[referrerAddress].m3Matrix[level].referrals.length == 1 
                && users[referrerAddress].m3Matrix[level].reinvestCount == 0) {
                users[referrerAddress].activeA3Levels[1] = true; 
                return updateA3Referrer(referrerAddress, findFreeA3Referrer(referrerAddress, 1),1);
            } else {
                return sendTronDividends(referrerAddress, userAddress, 1, level);
            }
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].m3Matrix[level].referrals = new address[](0);
       

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeM3Referrer(referrerAddress, level);
            if (users[referrerAddress].m3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].m3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].m3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateM3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendTronDividends(owner, userAddress, 1, level);
            users[owner].m3Matrix[level].reinvestCount++;
            emit NewUserPlace(owner, address(0), 1, level, 1);
            
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }
    function findFreeM3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeM3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    function usersActiveM3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeM3Levels[level];
    }
    function usersM3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory) {
        return (users[userAddress].m3Matrix[level].currentReferrer,
                users[userAddress].m3Matrix[level].referrals);
    }

    function updateM4Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeM4Levels[level], "500. Referrer level is inactive");
        
        //padre menos de 2 en su primer nivel
        if (users[referrerAddress].m4Matrix[level].firstLevelReferrals.length < 2) {
            //añadimos el usuario al primer nivel del padre
            users[referrerAddress].m4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].m4Matrix[level].firstLevelReferrals.length));
            
            //set current level
            //le indicamos el padre en la matriz del usuario
            users[userAddress].m4Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendTronDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].m4Matrix[level].currentReferrer;            
            users[ref].m4Matrix[level].secondLevelReferrals.push(userAddress); 
            
            // numero de usuarios en el primer nivel del padre del padre
            uint len = users[ref].m4Matrix[level].firstLevelReferrals.length;
            
            // si el padre esta dos veces en el primer nivel del padre del padre... implica que la pos 3 y 4 ya están rellenadas
            // con lo que solo puede ocupar la 5 y la 6
            if ((len == 2) && 
                (users[ref].m4Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].m4Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                // si el padre ya tiene uno (el actual) tiene que ir en pos 5 sino en la 6
                if (users[referrerAddress].m4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  
            // si el padre está en la primera posicion del padre del padre pos 3 o 4
            else if ((len == 1 || len == 2) &&
                    users[ref].m4Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].m4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } 
            // si el padre está en la primera posicion del padre del padre pos 5 o 6
            else if (len == 2 && users[ref].m4Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].m4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }
            
            return updateM4ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].m4Matrix[level].secondLevelReferrals.push(userAddress);
        
        // miramos en que rama tiene que caer en función del closedpart que indica que una matriz ya ha ciclado
        if (users[referrerAddress].m4Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].m4Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].m4Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].m4Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].m4Matrix[level].closedPart)) {
                //updateamos el padre directo del usuario en su primer nivel, el padre del usuario y emitimos todos los eventos
                updateM4(userAddress, referrerAddress, level, true);
                return updateM4ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].m4Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].m4Matrix[level].closedPart) {
                //updateamos el padre directo del usuario en su primer nivel, el padre del usuario y emitimos todos los eventos
                updateM4(userAddress, referrerAddress, level, true);
                return updateM4ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                //updateamos el padre directo del usuario en su primer nivel, el padre del usuario y emitimos todos los eventos
                updateM4(userAddress, referrerAddress, level, false);
                return updateM4ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        //si el usuario está en el primer nivel del padre hay que colocarlo en la otra rama
        if (users[referrerAddress].m4Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateM4(userAddress, referrerAddress, level, false);
            return updateM4ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].m4Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateM4(userAddress, referrerAddress, level, true);
            return updateM4ReferrerSecondLevel(userAddress, referrerAddress, level);
        }

        if (users[users[referrerAddress].m4Matrix[level].firstLevelReferrals[0]].m4Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].m4Matrix[level].firstLevelReferrals[1]].m4Matrix[level].firstLevelReferrals.length) {
            updateM4(userAddress, referrerAddress, level, false);
        } else {
            updateM4(userAddress, referrerAddress, level, true);
        }
        
        updateM4ReferrerSecondLevel(userAddress, referrerAddress, level);
    }
    function updateM4(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].m4Matrix[level].firstLevelReferrals[0]].m4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].m4Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].m4Matrix[level].firstLevelReferrals[0]].m4Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].m4Matrix[level].firstLevelReferrals[0]].m4Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].m4Matrix[level].currentReferrer = users[referrerAddress].m4Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].m4Matrix[level].firstLevelReferrals[1]].m4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].m4Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].m4Matrix[level].firstLevelReferrals[1]].m4Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].m4Matrix[level].firstLevelReferrals[1]].m4Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].m4Matrix[level].currentReferrer = users[referrerAddress].m4Matrix[level].firstLevelReferrals[1];
        }
    }
    function updateM4ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].m4Matrix[level].secondLevelReferrals.length < 4) {
            if(owner != referrerAddress 
                && level == 1 && users[referrerAddress].m4Matrix[level].secondLevelReferrals.length == 1 
                && users[referrerAddress].m4Matrix[level].reinvestCount == 0) {
                users[referrerAddress].activeA4Levels[1] = true; 
                return updateA4Referrer(referrerAddress,findFreeA4Referrer(referrerAddress, 1),1);
            } else {
                return sendTronDividends(referrerAddress, userAddress, 2, level);
            }
        }

        //primer nivel de la matriz del padre del padre del padre 
        address[] memory a4 = users[users[referrerAddress].m4Matrix[level].currentReferrer].m4Matrix[level].firstLevelReferrals;
        
        if (a4.length == 2) {
            if (a4[0] == referrerAddress ||
                a4[1] == referrerAddress) {
                users[users[referrerAddress].m4Matrix[level].currentReferrer].m4Matrix[level].closedPart = referrerAddress;
            } else if (a4.length == 1) {
                if (a4[0] == referrerAddress) {
                    users[users[referrerAddress].m4Matrix[level].currentReferrer].m4Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        // Reseteamos matriz
        users[referrerAddress].m4Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].m4Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].m4Matrix[level].closedPart = address(0);

        //aumenta numero de ciclos del padre del padre
        users[referrerAddress].m4Matrix[level].reinvestCount++;
        

        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeM4Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateM4Referrer(referrerAddress, freeReferrerAddress, level);
            if(users[referrerAddress].owner) {
                registrationPart(address(0),referrerAddress,2,level,true,false);
                registrationPart(address(0),referrerAddress,2,level,true,false);
            }
        } else {
            registrationPart(address(0),owner,2,level,true,false);
            registrationPart(address(0),owner,2,level,true,false);
            emit NewUserPlace(owner, address(0), 2, level, 1);
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendTronDividends(owner, userAddress, 2, level);
        }
    }
    function findFreeM4Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeM4Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    function usersActiveM4Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeM4Levels[level];
    }
    function usersM4Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, address) {
        return (users[userAddress].m4Matrix[level].currentReferrer,
                users[userAddress].m4Matrix[level].firstLevelReferrals,
                users[userAddress].m4Matrix[level].secondLevelReferrals,
                users[userAddress].m4Matrix[level].closedPart);
    }

    function updateM9Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeM9Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].m9Matrix[level].firstLevelReferrals.length < 3) {
            users[referrerAddress].m9Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 3, level, uint8(users[referrerAddress].m9Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].m9Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendTronDividends(referrerAddress, userAddress, 3, level);
            }
            
            address ref = users[referrerAddress].m9Matrix[level].currentReferrer;            
            users[ref].m9Matrix[level].secondLevelReferrals.push(userAddress); 
            
            
            // primer nivel del padre del padre
            // child 1 = child 2 = child 3 = user => 10 11 12 

            if (
                users[ref].m9Matrix[level].firstLevelReferrals.length == 3
                &&
                users[ref].m9Matrix[level].firstLevelReferrals[0] == users[ref].m9Matrix[level].firstLevelReferrals[1]
                && users[ref].m9Matrix[level].firstLevelReferrals[2] == users[ref].m9Matrix[level].firstLevelReferrals[1]
                && users[ref].m9Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                    if (users[referrerAddress].m9Matrix[level].firstLevelReferrals.length == 1) {
                        emit NewUserPlace(userAddress, ref, 3, level, 10);
                    } else if (users[referrerAddress].m9Matrix[level].firstLevelReferrals.length == 2) {
                        emit NewUserPlace(userAddress, ref, 3, level, 11);
                    } else {
                        emit NewUserPlace(userAddress, ref, 3, level, 12);
                    }
                } 
            // child 1 = child 2 = user => 7 8 9
            else if (
                users[ref].m9Matrix[level].firstLevelReferrals.length >= 2
                &&
                users[ref].m9Matrix[level].firstLevelReferrals[0] == users[ref].m9Matrix[level].firstLevelReferrals[1]
                && users[ref].m9Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                    if (users[referrerAddress].m9Matrix[level].firstLevelReferrals.length == 1) {
                        emit NewUserPlace(userAddress, ref, 3, level, 7);
                    } else if (users[referrerAddress].m9Matrix[level].firstLevelReferrals.length == 2) {
                        emit NewUserPlace(userAddress, ref, 3, level, 8);
                    } else {
                        emit NewUserPlace(userAddress, ref, 3, level, 9);
                    }
                } 
            // child 1 = child 3 = user => 10 11 12 
            else if (
                users[ref].m9Matrix[level].firstLevelReferrals.length == 3
                &&
                users[ref].m9Matrix[level].firstLevelReferrals[0] == users[ref].m9Matrix[level].firstLevelReferrals[2]
                && users[ref].m9Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                    if (users[referrerAddress].m9Matrix[level].firstLevelReferrals.length == 1) {
                        emit NewUserPlace(userAddress, ref, 3, level, 10);
                    } else if (users[referrerAddress].m9Matrix[level].firstLevelReferrals.length == 2) {
                        emit NewUserPlace(userAddress, ref, 3, level, 11);
                    } else {
                        emit NewUserPlace(userAddress, ref, 3, level, 12);
                    }
                }
            // child 2 = child 3 = user => 10 11 12 
            else if (
                users[ref].m9Matrix[level].firstLevelReferrals.length == 3
                &&
                users[ref].m9Matrix[level].firstLevelReferrals[1] == users[ref].m9Matrix[level].firstLevelReferrals[2]
                && users[ref].m9Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                    if (users[referrerAddress].m9Matrix[level].firstLevelReferrals.length == 1) {
                        emit NewUserPlace(userAddress, ref, 3, level, 10);
                    } else if (users[referrerAddress].m9Matrix[level].firstLevelReferrals.length == 2) {
                        emit NewUserPlace(userAddress, ref, 3, level, 11);
                    } else {
                        emit NewUserPlace(userAddress, ref, 3, level, 12);
                    }
                }
            // child 1 = user => 4 5 6
            else if (users[ref].m9Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                    if (users[referrerAddress].m9Matrix[level].firstLevelReferrals.length == 1) {
                        emit NewUserPlace(userAddress, ref, 3, level, 4);
                    } else if (users[referrerAddress].m9Matrix[level].firstLevelReferrals.length == 2) {
                        emit NewUserPlace(userAddress, ref, 3, level, 5);
                    } else {
                        emit NewUserPlace(userAddress, ref, 3, level, 6);
                    }
                }
            // child 2 = user => 7 8 9
            else if (
                users[ref].m9Matrix[level].firstLevelReferrals.length >= 2
                &&
                users[ref].m9Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                    if (users[referrerAddress].m9Matrix[level].firstLevelReferrals.length == 1) {
                        emit NewUserPlace(userAddress, ref, 3, level, 7);
                    } else if (users[referrerAddress].m9Matrix[level].firstLevelReferrals.length == 2) {
                        emit NewUserPlace(userAddress, ref, 3, level, 8);
                    } else {
                        emit NewUserPlace(userAddress, ref, 3, level, 9);
                    }
                } 
            // child 3 = user => 10 11 12
            else if (
                users[ref].m9Matrix[level].firstLevelReferrals.length == 3
                &&
                users[ref].m9Matrix[level].firstLevelReferrals[2] == referrerAddress) {
                    if (users[referrerAddress].m9Matrix[level].firstLevelReferrals.length == 1) {
                        emit NewUserPlace(userAddress, ref, 3, level, 10);
                    } else if (users[referrerAddress].m9Matrix[level].firstLevelReferrals.length == 2) {
                        emit NewUserPlace(userAddress, ref, 3, level, 11);
                    } else {
                        emit NewUserPlace(userAddress, ref, 3, level, 12);
                    }
                }
            
            return updateM9ReferrerSecondLevel(userAddress, ref, level);
        }
        //derrame

        users[referrerAddress].m9Matrix[level].secondLevelReferrals.push(userAddress);
        uint rama1 = users[users[referrerAddress].m9Matrix[level].firstLevelReferrals[0]].m9Matrix[level].firstLevelReferrals.length;
        if(users[referrerAddress].m9Matrix[level].closedPart1 != address(0)) {
            rama1 = 3;
        }
        uint rama2 = users[users[referrerAddress].m9Matrix[level].firstLevelReferrals[1]].m9Matrix[level].firstLevelReferrals.length;
        if(users[referrerAddress].m9Matrix[level].closedPart2 != address(0)) {
            rama2 = 3;
        }
        uint rama3 = users[users[referrerAddress].m9Matrix[level].firstLevelReferrals[2]].m9Matrix[level].firstLevelReferrals.length;
        if(users[referrerAddress].m9Matrix[level].closedPart3 != address(0)) {
            rama3 = 3;
        }             
        // rama1 <= rama2 
            // rama1 <= rama3 - rama1
            // sino rama3
        // sino 
            // rama2 <= rama3 - rama2
            // sino rama3
        

        if(rama1<=rama2) {
            if(rama1<=rama3) {
                updateM9(userAddress, referrerAddress, level, 1);
            } else {
                updateM9(userAddress, referrerAddress, level, 3);
            }
        } else {
            if(rama2<=rama3) {
                updateM9(userAddress, referrerAddress, level, 2);
            } else {
                updateM9(userAddress, referrerAddress, level, 3);
            }
        }

        updateM9ReferrerSecondLevel(userAddress, referrerAddress, level);
    }
    function findFreeM9Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeM9Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    function updateM9(address userAddress, address referrerAddress, uint8 level, uint x2) private {
        if (x2 == 1) {
            users[users[referrerAddress].m9Matrix[level].firstLevelReferrals[0]].m9Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].m9Matrix[level].firstLevelReferrals[0], 3, level, uint8(users[users[referrerAddress].m9Matrix[level].firstLevelReferrals[0]].m9Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 3, level, 3 + uint8(users[users[referrerAddress].m9Matrix[level].firstLevelReferrals[0]].m9Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].m9Matrix[level].currentReferrer = users[referrerAddress].m9Matrix[level].firstLevelReferrals[0];
        } else if (x2 == 2) {
            users[users[referrerAddress].m9Matrix[level].firstLevelReferrals[1]].m9Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].m9Matrix[level].firstLevelReferrals[1], 3, level, uint8(users[users[referrerAddress].m9Matrix[level].firstLevelReferrals[1]].m9Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 3, level, 6 + uint8(users[users[referrerAddress].m9Matrix[level].firstLevelReferrals[1]].m9Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].m9Matrix[level].currentReferrer = users[referrerAddress].m9Matrix[level].firstLevelReferrals[1];
        } else {
            
            users[users[referrerAddress].m9Matrix[level].firstLevelReferrals[2]].m9Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].m9Matrix[level].firstLevelReferrals[2], 3, level, uint8(users[users[referrerAddress].m9Matrix[level].firstLevelReferrals[2]].m4Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 3, level, 9 + uint8(users[users[referrerAddress].m9Matrix[level].firstLevelReferrals[2]].m9Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].m9Matrix[level].currentReferrer = users[referrerAddress].m9Matrix[level].firstLevelReferrals[2];
        }
    }
    function updateM9ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].m9Matrix[level].secondLevelReferrals.length < 9) {
            if(owner != referrerAddress 
                && level == 1 
                && users[referrerAddress].m9Matrix[level].secondLevelReferrals.length == 1 
                && users[referrerAddress].m9Matrix[level].reinvestCount == 0) {
                    users[referrerAddress].activeA9Levels[1] = true; 
                    return updateA9Referrer(referrerAddress,findFreeA9Referrer(referrerAddress, 1),1);
            } else {
                return sendTronDividends(referrerAddress, userAddress, 3, level);
            }
        }
        
        address[] memory a9 = users[users[referrerAddress].m9Matrix[level].currentReferrer].m9Matrix[level].firstLevelReferrals;
        
        if (a9.length >= 1) {
            if(a9[0] == referrerAddress) {
                users[users[referrerAddress].m9Matrix[level].currentReferrer].m9Matrix[level].closedPart1 = referrerAddress;
            }
            if (a9.length >= 2) {
                if(a9[1] == referrerAddress) {
                    users[users[referrerAddress].m9Matrix[level].currentReferrer].m9Matrix[level].closedPart2 = referrerAddress;
                }
                if (a9.length >= 3) {
                    if(a9[2] == referrerAddress) {
                        users[users[referrerAddress].m9Matrix[level].currentReferrer].m9Matrix[level].closedPart3 = referrerAddress;
                    }
                }

            }
        }
        
        users[referrerAddress].m9Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].m9Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].m9Matrix[level].closedPart1 = address(0);
        users[referrerAddress].m9Matrix[level].closedPart2 = address(0);
        users[referrerAddress].m9Matrix[level].closedPart3 = address(0);


        users[referrerAddress].m9Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeM9Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 3, level);
            updateM9Referrer(referrerAddress, freeReferrerAddress, level);
            if(users[referrerAddress].owner) {
                registrationPart(address(0),referrerAddress,3,level,true,false);
                registrationPart(address(0),referrerAddress,3,level,true,false);
                registrationPart(address(0),referrerAddress,3,level,true,false);
            }
        } else {
            registrationPart(address(0),owner,3,level,true,false);
            registrationPart(address(0),owner,3,level,true,false);
            registrationPart(address(0),owner,3,level,true,false);

            emit NewUserPlace(owner, address(0), 3, level, 1);
            emit Reinvest(owner, address(0), userAddress, 3, level);
            sendTronDividends(owner, userAddress, 3, level);
        }
    }
    function usersActiveM9Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeM9Levels[level];
    }
    function usersM9Matrix(address userAddress, uint8 level) 
        public view returns(address, address[] memory, address[] memory, address, address, address) {
        return (users[userAddress].m9Matrix[level].currentReferrer,
                users[userAddress].m9Matrix[level].firstLevelReferrals,
                users[userAddress].m9Matrix[level].secondLevelReferrals,
                users[userAddress].m9Matrix[level].closedPart1,
                users[userAddress].m9Matrix[level].closedPart2,
                users[userAddress].m9Matrix[level].closedPart3);
    }

    //autos
    function updateA3Referrer(address userAddress, address referrerAddress, uint8 level) internal {
        users[referrerAddress].a3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].a3Matrix[level].referrals.length < 3) {
            //primer ciclo
            emit NewUserPlace(userAddress, referrerAddress, 4, level, uint8(users[referrerAddress].a3Matrix[level].referrals.length));
            if(users[referrerAddress].a3Matrix[level].reinvestCount == 0 && owner != referrerAddress && level != LAST_LEVEL ) {
                // primer posicion primer ciclo se almacena en el contrato
                if(users[referrerAddress].a3Matrix[level].referrals.length == 1) {
                    return;
                }
                

                // segundo pago primer ciclo activo el siguiente slot
                if(users[referrerAddress].a3Matrix[level].referrals.length == 2 ) {
                    users[referrerAddress].activeA3Levels[level+1] = true; 
                    return updateA3Referrer(referrerAddress, findFreeA3Referrer(referrerAddress, level+1),level+1);
                }
            }

            // primera y segunda posicion del segundo ciclo en adelante
            return sendTronDividends(referrerAddress, userAddress, 4, level);
        }
        
        // tercer pago cobra padre en cualquier ciclo
        
        emit NewUserPlace(userAddress, referrerAddress, 4, level, 3);
        //close matrix
        users[referrerAddress].a3Matrix[level].referrals = new address[](0);
       

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeA3Referrer(referrerAddress, level);
            if (users[referrerAddress].a3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].a3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].a3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 4, level);
            updateA3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendTronDividends(owner, userAddress, 4, level);
            users[owner].a3Matrix[level].reinvestCount++;
            
            emit NewUserPlace(owner, address(0), 4, level, 1);
            emit Reinvest(owner, address(0), userAddress, 4, level);
        }
    }
    function findFreeA3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeA3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function usersActiveA3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeA3Levels[level];
    }
    function usersA3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory) {
        return (users[userAddress].a3Matrix[level].currentReferrer,
                users[userAddress].a3Matrix[level].referrals);
    }

    function updateA4Referrer(address userAddress, address referrerAddress, uint8 level) internal {
        require(users[referrerAddress].activeA4Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].a4Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].a4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 5, level, uint8(users[referrerAddress].a4Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].a4Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendTronDividends(referrerAddress, userAddress, 5, level);
            }
            
            address ref = users[referrerAddress].a4Matrix[level].currentReferrer;            
            users[ref].a4Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].a4Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].a4Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].a4Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].a4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 5, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 5, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].a4Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].a4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 5, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 5, level, 4);
                }
            } else if (len == 2 && users[ref].a4Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].a4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 5, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 5, level, 6);
                }
            }

            return updateA4ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].a4Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].a4Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].a4Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].a4Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].a4Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].a4Matrix[level].closedPart)) {

                updateA4(userAddress, referrerAddress, level, true);
                return updateA4ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].a4Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].a4Matrix[level].closedPart) {
                updateA4(userAddress, referrerAddress, level, true);
                return updateA4ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateA4(userAddress, referrerAddress, level, false);
                return updateA4ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].a4Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateA4(userAddress, referrerAddress, level, false);
            return updateA4ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].a4Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateA4(userAddress, referrerAddress, level, true);
            return updateA4ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].a4Matrix[level].firstLevelReferrals[0]].a4Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].a4Matrix[level].firstLevelReferrals[1]].a4Matrix[level].firstLevelReferrals.length) {
            updateA4(userAddress, referrerAddress, level, false);
        } else {
            updateA4(userAddress, referrerAddress, level, true);
        }
        
        updateA4ReferrerSecondLevel(userAddress, referrerAddress, level);
    }
    function updateA4(address userAddress, address referrerAddress, uint8 level, bool x2) internal {
        if (!x2) {
            users[users[referrerAddress].a4Matrix[level].firstLevelReferrals[0]].a4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].a4Matrix[level].firstLevelReferrals[0], 5, level, uint8(users[users[referrerAddress].a4Matrix[level].firstLevelReferrals[0]].a4Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 5, level, 2 + uint8(users[users[referrerAddress].a4Matrix[level].firstLevelReferrals[0]].a4Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].a4Matrix[level].currentReferrer = users[referrerAddress].a4Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].a4Matrix[level].firstLevelReferrals[1]].a4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].a4Matrix[level].firstLevelReferrals[1], 5, level, uint8(users[users[referrerAddress].a4Matrix[level].firstLevelReferrals[1]].a4Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 5, level, 4 + uint8(users[users[referrerAddress].a4Matrix[level].firstLevelReferrals[1]].a4Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].a4Matrix[level].currentReferrer = users[referrerAddress].a4Matrix[level].firstLevelReferrals[1];
        }
    }
    function updateA4ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) internal {
        if (users[referrerAddress].a4Matrix[level].secondLevelReferrals.length < 4) {
            if(users[referrerAddress].a4Matrix[level].reinvestCount == 0 
                    && owner != referrerAddress  
                    && level != LAST_LEVEL ) {
                // primer posicion primer ciclo se almacena en el contrato
                if(users[referrerAddress].a4Matrix[level].secondLevelReferrals.length == 1) {
                    return;
                }

                // segundo pago primer ciclo activo el siguiente slot
                if(users[referrerAddress].a4Matrix[level].secondLevelReferrals.length == 2) {
                    users[referrerAddress].activeA4Levels[level+1] = true; 
                    return updateA4Referrer(referrerAddress, findFreeA4Referrer(referrerAddress, level+1),level+1);
                }
            }

            // primera y segunda posicion del segundo ciclo en adelante cobra y la tercera de cualquier ciclo
            return sendTronDividends(referrerAddress, userAddress, 5, level);
        }
        // cuarto pago cobra padre en cualquier ciclo
        //primer nivel de la matriz del padre del padre del padre 
        address[] memory a4 = users[users[referrerAddress].a4Matrix[level].currentReferrer].a4Matrix[level].firstLevelReferrals;
        
        if (a4.length == 2) {
            if (a4[0] == referrerAddress ||
                a4[1] == referrerAddress) {
                users[users[referrerAddress].a4Matrix[level].currentReferrer].a4Matrix[level].closedPart = referrerAddress;
            } else if (a4.length == 1) {
                if (a4[0] == referrerAddress) {
                    users[users[referrerAddress].a4Matrix[level].currentReferrer].a4Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        // Reseteamos matriz
        users[referrerAddress].a4Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].a4Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].a4Matrix[level].closedPart = address(0);

        //aumenta numero de ciclos del padre del padre
        users[referrerAddress].a4Matrix[level].reinvestCount++;
        

        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeA4Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 5, level);
            updateA4Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 5, level);
            emit NewUserPlace(owner, address(0), 5, level, 1);
            sendTronDividends(owner, userAddress, 5, level);
        }
    }
    function findFreeA4Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeA4Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    function usersActiveA4Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeA4Levels[level];
    }
    function usersA4Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, address) {
        return (users[userAddress].a4Matrix[level].currentReferrer,
                users[userAddress].a4Matrix[level].firstLevelReferrals,
                users[userAddress].a4Matrix[level].secondLevelReferrals,
                users[userAddress].a4Matrix[level].closedPart);
    }

    function updateA9Referrer(address userAddress, address referrerAddress, uint8 level) internal {
        require(users[referrerAddress].activeA9Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].a9Matrix[level].firstLevelReferrals.length < 3) {
            users[referrerAddress].a9Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 6, level, uint8(users[referrerAddress].a9Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].a9Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendTronDividends(referrerAddress, userAddress, 6, level);
            }
            
            address ref = users[referrerAddress].a9Matrix[level].currentReferrer;            
            users[ref].a9Matrix[level].secondLevelReferrals.push(userAddress); 
            
            
            // primer nivel del padre del padre
            // child 1 = child 2 = child 3 = user => 10 11 12 
            if (
                users[ref].a9Matrix[level].firstLevelReferrals.length == 3
                &&
                users[ref].a9Matrix[level].firstLevelReferrals[0] == users[ref].a9Matrix[level].firstLevelReferrals[1]
                && users[ref].a9Matrix[level].firstLevelReferrals[2] == users[ref].a9Matrix[level].firstLevelReferrals[1]
                && users[ref].a9Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                    if (users[referrerAddress].a9Matrix[level].firstLevelReferrals.length == 1) {
                        emit NewUserPlace(userAddress, ref, 6, level, 10);
                    } else if (users[referrerAddress].a9Matrix[level].firstLevelReferrals.length == 2) {
                        emit NewUserPlace(userAddress, ref, 6, level, 11);
                    } else {
                        emit NewUserPlace(userAddress, ref, 6, level, 12);
                    }
                } 
            // child 1 = child 2 = user => 7 8 9
            else if (
                users[ref].a9Matrix[level].firstLevelReferrals.length >= 2
                &&
                users[ref].a9Matrix[level].firstLevelReferrals[0] == users[ref].a9Matrix[level].firstLevelReferrals[1]
                && users[ref].a9Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                    if (users[referrerAddress].a9Matrix[level].firstLevelReferrals.length == 1) {
                        emit NewUserPlace(userAddress, ref, 6, level, 7);
                    } else if (users[referrerAddress].a9Matrix[level].firstLevelReferrals.length == 2) {
                        emit NewUserPlace(userAddress, ref, 6, level, 8);
                    } else {
                        emit NewUserPlace(userAddress, ref, 6, level, 9);
                    }
                } 
            // child 1 = child 3 = user => 10 11 12 
            else if (
                users[ref].a9Matrix[level].firstLevelReferrals.length == 3
                &&
                users[ref].a9Matrix[level].firstLevelReferrals[0] == users[ref].a9Matrix[level].firstLevelReferrals[2]
                && users[ref].a9Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                    if (users[referrerAddress].a9Matrix[level].firstLevelReferrals.length == 1) {
                        emit NewUserPlace(userAddress, ref, 6, level, 10);
                    } else if (users[referrerAddress].a9Matrix[level].firstLevelReferrals.length == 2) {
                        emit NewUserPlace(userAddress, ref, 6, level, 11);
                    } else {
                        emit NewUserPlace(userAddress, ref, 6, level, 12);
                    }
                }
            // child 2 = child 3 = user => 10 11 12 
            else if (
                users[ref].a9Matrix[level].firstLevelReferrals.length == 3
                &&
                users[ref].a9Matrix[level].firstLevelReferrals[1] == users[ref].a9Matrix[level].firstLevelReferrals[2]
                && users[ref].a9Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                    if (users[referrerAddress].a9Matrix[level].firstLevelReferrals.length == 1) {
                        emit NewUserPlace(userAddress, ref, 6, level, 10);
                    } else if (users[referrerAddress].a9Matrix[level].firstLevelReferrals.length == 2) {
                        emit NewUserPlace(userAddress, ref, 6, level, 11);
                    } else {
                        emit NewUserPlace(userAddress, ref, 6, level, 12);
                    }
                }
            // child 1 = user => 4 5 6
            else if (users[ref].a9Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                    if (users[referrerAddress].a9Matrix[level].firstLevelReferrals.length == 1) {
                        emit NewUserPlace(userAddress, ref, 6, level, 4);
                    } else if (users[referrerAddress].a9Matrix[level].firstLevelReferrals.length == 2) {
                        emit NewUserPlace(userAddress, ref, 6, level, 5);
                    } else {
                        emit NewUserPlace(userAddress, ref, 6, level, 6);
                    }
                }
            // child 2 = user => 7 8 9
            else if (
                users[ref].a9Matrix[level].firstLevelReferrals.length >= 2
                &&
                users[ref].a9Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                    if (users[referrerAddress].a9Matrix[level].firstLevelReferrals.length == 1) {
                        emit NewUserPlace(userAddress, ref, 6, level, 7);
                    } else if (users[referrerAddress].a9Matrix[level].firstLevelReferrals.length == 2) {
                        emit NewUserPlace(userAddress, ref, 6, level, 8);
                    } else {
                        emit NewUserPlace(userAddress, ref, 6, level, 9);
                    }
                } 
            // child 3 = user => 10 11 12
            else if (
                users[ref].a9Matrix[level].firstLevelReferrals.length == 3
                &&
                users[ref].a9Matrix[level].firstLevelReferrals[2] == referrerAddress) {
                    if (users[referrerAddress].a9Matrix[level].firstLevelReferrals.length == 1) {
                        emit NewUserPlace(userAddress, ref, 6, level, 10);
                    } else if (users[referrerAddress].a9Matrix[level].firstLevelReferrals.length == 2) {
                        emit NewUserPlace(userAddress, ref, 6, level, 11);
                    } else {
                        emit NewUserPlace(userAddress, ref, 6, level, 12);
                    }
                }

            return updateA9ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].a9Matrix[level].secondLevelReferrals.push(userAddress);
        uint rama1 = users[users[referrerAddress].a9Matrix[level].firstLevelReferrals[0]].a9Matrix[level].firstLevelReferrals.length;
        if(users[referrerAddress].a9Matrix[level].closedPart1 != address(0)) {
            rama1 = 3;
        }
        uint rama2 = users[users[referrerAddress].a9Matrix[level].firstLevelReferrals[1]].a9Matrix[level].firstLevelReferrals.length;
        if(users[referrerAddress].a9Matrix[level].closedPart2 != address(0)) {
            rama2 = 3;
        }
        uint rama3 = users[users[referrerAddress].a9Matrix[level].firstLevelReferrals[2]].a9Matrix[level].firstLevelReferrals.length;
        if(users[referrerAddress].a9Matrix[level].closedPart3 != address(0)) {
            rama3 = 3;
        }

        if(rama1<=rama2) {
            if(rama1<=rama3) {
                updateA9(userAddress, referrerAddress, level, 1);
            } else {
                updateA9(userAddress, referrerAddress, level, 3);
            }
        } else {
            if(rama2<=rama3) {
                updateA9(userAddress, referrerAddress, level, 2);
            } else {
                updateA9(userAddress, referrerAddress, level, 3);
            }
        }
        
        updateA9ReferrerSecondLevel(userAddress, referrerAddress, level);
    }
    function findFreeA9Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeA9Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    function updateA9(address userAddress, address referrerAddress, uint8 level, uint x2) internal {
        if (x2 == 1) {
            users[users[referrerAddress].a9Matrix[level].firstLevelReferrals[0]].a9Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].a9Matrix[level].firstLevelReferrals[0], 6, level, uint8(users[users[referrerAddress].a9Matrix[level].firstLevelReferrals[0]].m4Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 6, level, 3 + uint8(users[users[referrerAddress].a9Matrix[level].firstLevelReferrals[0]].a9Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].a9Matrix[level].currentReferrer = users[referrerAddress].a9Matrix[level].firstLevelReferrals[0];
        } else if (x2 == 2) {
            users[users[referrerAddress].a9Matrix[level].firstLevelReferrals[1]].a9Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].a9Matrix[level].firstLevelReferrals[1], 6, level, uint8(users[users[referrerAddress].a9Matrix[level].firstLevelReferrals[1]].m4Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 6, level, 6 + uint8(users[users[referrerAddress].a9Matrix[level].firstLevelReferrals[1]].a9Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].a9Matrix[level].currentReferrer = users[referrerAddress].a9Matrix[level].firstLevelReferrals[1];
        } else {
            users[users[referrerAddress].a9Matrix[level].firstLevelReferrals[2]].a9Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].a9Matrix[level].firstLevelReferrals[2], 6, level, uint8(users[users[referrerAddress].a9Matrix[level].firstLevelReferrals[2]].m4Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 6, level, 9 + uint8(users[users[referrerAddress].a9Matrix[level].firstLevelReferrals[2]].a9Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].a9Matrix[level].currentReferrer = users[referrerAddress].a9Matrix[level].firstLevelReferrals[2];
        }
    }
    function updateA9ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) internal {
        if (users[referrerAddress].a9Matrix[level].secondLevelReferrals.length < 9) {
            if(users[referrerAddress].a9Matrix[level].reinvestCount == 0 
                && owner != referrerAddress  
                && level != LAST_LEVEL ) {
                // primer posicion primer ciclo se almacena en el contrato
                if(users[referrerAddress].a9Matrix[level].secondLevelReferrals.length == 1) {
                    return;
                }

                // segundo pago primer ciclo activo el siguiente slot
                if(users[referrerAddress].a9Matrix[level].secondLevelReferrals.length == 2) {
                    users[referrerAddress].activeA9Levels[level+1] = true; 
                    return updateA9Referrer(referrerAddress, findFreeA9Referrer(referrerAddress, level+1),level+1);
                }
            }

            // primera y segunda posicion del segundo ciclo en adelante cobra y el resto de posiciones de cualquier ciclo
            return sendTronDividends(referrerAddress, userAddress, 6, level);
        }
        // noveno pago cobra padre en cualquier ciclo
        
        address[] memory a9 = users[users[referrerAddress].a9Matrix[level].currentReferrer].a9Matrix[level].firstLevelReferrals;
        
        if (a9.length >= 1) {
            if(a9[0] == referrerAddress) {
                users[users[referrerAddress].a9Matrix[level].currentReferrer].a9Matrix[level].closedPart1 = referrerAddress;
            }
            if (a9.length >= 2) {
                if(a9[1] == referrerAddress) {
                    users[users[referrerAddress].a9Matrix[level].currentReferrer].a9Matrix[level].closedPart2 = referrerAddress;
                }
                if (a9.length >= 3) {
                    if(a9[2] == referrerAddress) {
                        users[users[referrerAddress].a9Matrix[level].currentReferrer].a9Matrix[level].closedPart3 = referrerAddress;
                    }
                }

            }
        }
        
        users[referrerAddress].a9Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].a9Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].a9Matrix[level].closedPart1 = address(0);
        users[referrerAddress].a9Matrix[level].closedPart2 = address(0);
        users[referrerAddress].a9Matrix[level].closedPart3 = address(0);


        users[referrerAddress].a9Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeA9Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 6, level);
            updateA9Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 6, level);
            emit NewUserPlace(owner, address(0), 6, level, 1);
            sendTronDividends(owner, userAddress, 6, level);
        }
    }
    function usersActiveA9Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeA9Levels[level];
    }
    function usersA9Matrix(address userAddress, uint8 level) 
        public view returns(address, address[] memory, address[] memory, address, address, address) {
        return (users[userAddress].a9Matrix[level].currentReferrer,
                users[userAddress].a9Matrix[level].firstLevelReferrals,
                users[userAddress].a9Matrix[level].secondLevelReferrals,
                users[userAddress].a9Matrix[level].closedPart1,
                users[userAddress].a9Matrix[level].closedPart2,
                users[userAddress].a9Matrix[level].closedPart3);
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function sendTronDividends(address userAddress, address _from, uint8 matrix, uint8 level) internal {
        //(address receiver, bool isExtraDividends) = findTronReceiver(userAddress, _from, matrix, level);

        if(users[_from].part) {
            return;
        }

        if(users[_from].owner) {
            return;
        }

        address receiver = userAddress;
        if(users[userAddress].part) {
            receiver = getOwner();
        } 

        if (!address(uint160(receiver)).send(levelPrice[level])) {
            //return address(uint160(receiver)).transfer(address(this).balance);
        }

        emit SentExtraTronDividends(_from, receiver, matrix, level);
        
    }
    function fallback(uint amount)  public {
        require(msg.sender == owner, "no owner");
        msg.sender.send(amount);
    }
    function addOwner(address _owner) public {
        require(msg.sender == owner, "no owner");
        owners.push(_owner);
    }
    function removeOwner(uint _ownerint) public {
        require(msg.sender == owner, "no owner");
        delete owners[_ownerint];
    }
    function getOwner() private returns  (address addr) {
        if(owners.length > 0) {
            ownersPay++;
            if(ownersPay >= owners.length) ownersPay = 0;
            return owners[ownersPay];
        } else {
            return owner;
        }
    }
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}