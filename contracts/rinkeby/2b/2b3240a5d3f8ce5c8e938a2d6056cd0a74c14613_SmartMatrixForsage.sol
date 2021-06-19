/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

pragma solidity >=0.4.23 <0.6.0;

contract SmartMatrixForsage {
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) activeX14Levels;
        
        mapping(uint8 => X14) x14Matrix;
    }
    
     struct X14 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        address[] thirdLevelReferrals;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }

    uint8 public constant LAST_LEVEL = 12;
    
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
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    event sendETHDividends_Tansfer(address indexed receiver, uint trans_Balance);
    
    
    
    constructor(address ownerAddress) public {
        levelPrice[1] = 0.025 ether;
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
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeX14Levels[i] = true;
        }
        
        userIds[1] = ownerAddress;
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) public {
        registration(0x1beE1FAD0E6Cd41e4E3CAaeF65b8a8b09f3Aa31B, referrerAddress);
        registration(0x1BEe1FaD0e6Cd41E4E3CAAef65b8a8B09f3AA31c, referrerAddress);
        
        registration(0x1beE1FaD0e6CD41e4e3CAaEf65b8a8B09F3aa31d, referrerAddress);
        registration(0x1BEE1FAD0e6cD41E4E3caaEf65B8A8b09f3AA31E, referrerAddress);
        registration(0x1BEE1fAd0e6CD41e4E3caAeF65B8a8b09F3AA31f, referrerAddress);
        registration(0x1BEe1FAD0e6cd41e4E3cAaeF65B8a8b09f3aA310, referrerAddress);
        
        registration(0x1beE1FAd0e6cD41E4e3CAaeF65b8a8b09f3aa311, referrerAddress);
        registration(0x1BEE1fAd0e6cd41e4E3CaaeF65b8a8b09f3AA312, referrerAddress);
        registration(0x1BEE1FAD0e6cd41e4E3caaeF65B8a8B09f3Aa313, referrerAddress);
        registration(0x1bEe1FaD0e6CD41E4e3CAAeF65B8A8B09F3aA314, referrerAddress);
        registration(0x1bEE1Fad0e6cD41E4E3CAaEF65b8A8b09f3AA315, referrerAddress);
        registration(0x1BeE1FAd0e6cD41E4E3CAAef65b8A8B09f3aa316, referrerAddress);
        registration(0x1BeE1FaD0e6Cd41e4E3caAEf65b8A8B09f3AA317, referrerAddress);
        registration(0x1BeE1FAd0e6cd41e4E3CaaEF65b8a8B09F3Aa318, referrerAddress);
        //registration(msg.sender, referrerAddress);
        //registration(msg.sender, referrerAddress);
        //registration(msg.sender, referrerAddress);
    }

    function registrationExt_More(address referrerAddress) public {
        registration(0x1BEe1FaD0e6cd41E4E3caAEF65B8A8b09f3AA319, referrerAddress);
        registration(0x1BEe1faD0E6Cd41E4e3cAaEF65b8A8B09f3AA32c, referrerAddress);
       
        //registration(msg.sender, referrerAddress);
        //registration(msg.sender, referrerAddress);
        //registration(msg.sender, referrerAddress);
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2 || matrix == 3, "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 3) {
            require(!users[msg.sender].activeX14Levels[level], "level already activated"); 

            if (users[msg.sender].x14Matrix[level-1].blocked) {
                users[msg.sender].x14Matrix[level-1].blocked = false;
            }

            address freeX14Referrer = findFreeX14Referrer(msg.sender, level);
            
            users[msg.sender].activeX14Levels[level] = true;
            updateX14Referrer(msg.sender, freeX14Referrer, level);
            
            emit Upgrade(msg.sender, freeX14Referrer, 3, level);
        }
        
    }    
    
    function registration(address userAddress, address referrerAddress) private {
        //require(msg.value == 0.05 ether, "registration cost 0.05");
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
        
        //users[userAddress].activeX3Levels[1] = true; 
        //users[userAddress].activeX6Levels[1] = true;
        
        users[userAddress].activeX14Levels[1] = true;
        
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address freeX14Referrer = findFreeX14Referrer(userAddress, 1);
        users[userAddress].x14Matrix[1].currentReferrer = freeX14Referrer;
        
        //updateX3Referrer(userAddress, freeX3Referrer, 1);
        //updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1);
        
        updateX14Referrer(userAddress, freeX14Referrer, 1);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
 
    function updateX14Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX14Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x14Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x14Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 3, level, uint8(users[referrerAddress].x14Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].x14Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, 3, level);
            }
            
            address ref = users[referrerAddress].x14Matrix[level].currentReferrer;            
            users[ref].x14Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].x14Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].x14Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x14Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x14Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 3, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 3, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x14Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x14Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 3, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 3, level, 4);
                }
            } else if (len == 2 && users[ref].x14Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x14Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 3, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 3, level, 6);
                }
            }
            
           
            updateX14ReferrerSecondLevel(userAddress, ref, level);
            
            
            address ref_2 = users[ref].x14Matrix[level].currentReferrer;            
            users[ref_2].x14Matrix[level].thirdLevelReferrals.push(userAddress); 
            
            uint len_2 = users[ref_2].x14Matrix[level].secondLevelReferrals.length;
            
            if ((len_2 == 4) && 
                (users[ref_2].x14Matrix[level].firstLevelReferrals[0] == ref) &&
                (users[ref_2].x14Matrix[level].firstLevelReferrals[1] == ref)) {
                if (users[ref].x14Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref_2, 3, level, 9);
                } else {
                    emit NewUserPlace(userAddress, ref_2, 3, level, 10);
                }
            } else if ((len_2 == 4) && 
                (users[ref_2].x14Matrix[level].firstLevelReferrals[2] == ref) &&
                (users[ref_2].x14Matrix[level].firstLevelReferrals[3] == ref)) {
                if (users[ref].x14Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref_2, 3, level, 13);
                } else {
                    emit NewUserPlace(userAddress, ref_2, 3, level, 14);
                }
            } else if ((len_2 == 1 || len_2 == 2) &&
                    users[ref_2].x14Matrix[level].firstLevelReferrals[0] == ref) {
                if (users[ref].x14Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref_2, 3, level, 7);
                } else {
                    emit NewUserPlace(userAddress, ref_2, 3, level, 8);
                }
            } else if ((len_2 == 3 || len_2 == 4) &&
                    users[ref_2].x14Matrix[level].firstLevelReferrals[2] == ref) {
                if (users[ref].x14Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref_2, 3, level, 11);
                } else {
                    emit NewUserPlace(userAddress, ref_2, 3, level, 12);
                }
            } else if (len_2 == 4 && users[ref_2].x14Matrix[level].firstLevelReferrals[1] == ref) {
                if (users[ref].x14Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref_2, 3, level, 9);
                } else {
                    emit NewUserPlace(userAddress, ref_2, 3, level, 10);
                }
            } else if (len_2 == 4 && users[ref_2].x14Matrix[level].firstLevelReferrals[3] == ref) {
                if (users[ref].x14Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref_2, 3, level, 13);
                } else {
                    emit NewUserPlace(userAddress, ref_2, 3, level, 14);
                }
            }
            
           
            
            return updateX14ReferrerThirdLevel(userAddress, ref_2, level);
        }
        
        else if (users[referrerAddress].x14Matrix[level].secondLevelReferrals.length < 4) {
            
            users[referrerAddress].x14Matrix[level].secondLevelReferrals.push(userAddress);
            
            address ref = users[referrerAddress].x14Matrix[level].currentReferrer;   
            
            //set current level
            //users[userAddress].x14Matrix[level].currentReferrer = referrerAddress;

            uint len = users[ref].x14Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].x14Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x14Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x14Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 3, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 3, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x14Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x14Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 3, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 3, level, 4);
                }
            } else if (len == 2 && users[ref].x14Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x14Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 3, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 3, level, 6);
                }
            }
            
           
            updateX14ReferrerSecondLevel(userAddress, ref, level);
            
            address ref_2 = users[ref].x14Matrix[level].currentReferrer;            
            users[ref_2].x14Matrix[level].thirdLevelReferrals.push(userAddress); 
            
            uint len_2 = users[ref_2].x14Matrix[level].secondLevelReferrals.length;
            
            if ((len_2 == 4) && 
                (users[ref_2].x14Matrix[level].firstLevelReferrals[0] == ref) &&
                (users[ref_2].x14Matrix[level].firstLevelReferrals[1] == ref)) {
                if (users[referrerAddress].x14Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref_2, 3, level, 9);
                } else {
                    emit NewUserPlace(userAddress, ref_2, 3, level, 10);
                }
            } else if ((len_2 == 4) && 
                (users[ref_2].x14Matrix[level].firstLevelReferrals[2] == ref) &&
                (users[ref_2].x14Matrix[level].firstLevelReferrals[3] == ref)) {
                if (users[ref].x14Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref_2, 3, level, 13);
                } else {
                    emit NewUserPlace(userAddress, ref_2, 3, level, 14);
                }
            } else if ((len_2 == 1 || len_2 == 2) &&
                    users[ref_2].x14Matrix[level].firstLevelReferrals[0] == ref) {
                if (users[ref].x14Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref_2, 3, level, 7);
                } else {
                    emit NewUserPlace(userAddress, ref_2, 3, level, 8);
                }
            } else if ((len_2 == 3 || len_2 == 4) &&
                    users[ref_2].x14Matrix[level].firstLevelReferrals[2] == ref) {
                if (users[ref].x14Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref_2, 3, level, 11);
                } else {
                    emit NewUserPlace(userAddress, ref_2, 3, level, 12);
                }
            } else if (len_2 == 4 && users[ref_2].x14Matrix[level].firstLevelReferrals[1] == ref) {
                if (users[ref].x14Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref_2, 3, level, 9);
                } else {
                    emit NewUserPlace(userAddress, ref_2, 3, level, 10);
                }
            } else if (len_2 == 4 && users[ref_2].x14Matrix[level].firstLevelReferrals[3] == ref) {
                if (users[ref].x14Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref_2, 3, level, 13);
                } else {
                    emit NewUserPlace(userAddress, ref_2, 3, level, 14);
                }
            }
         
            
            
            return updateX14ReferrerThirdLevel(userAddress, referrerAddress, level);
            
        }
     
        users[referrerAddress].x14Matrix[level].thirdLevelReferrals.push(userAddress);
        

        if (users[referrerAddress].x14Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].x14Matrix[level].secondLevelReferrals[0] == 
                users[referrerAddress].x14Matrix[level].secondLevelReferrals[1]) &&
                (users[referrerAddress].x14Matrix[level].secondLevelReferrals[0] ==
                users[referrerAddress].x14Matrix[level].closedPart)) {

                updateX14(userAddress, referrerAddress, level, true);
                return updateX14ReferrerThirdLevel(userAddress, referrerAddress, level);
            } else if ((users[referrerAddress].x14Matrix[level].secondLevelReferrals[2] == 
                users[referrerAddress].x14Matrix[level].secondLevelReferrals[3]) &&
                (users[referrerAddress].x14Matrix[level].secondLevelReferrals[2] ==
                users[referrerAddress].x14Matrix[level].closedPart)) {

                updateX14(userAddress, referrerAddress, level, true);
                return updateX14ReferrerThirdLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].x14Matrix[level].secondLevelReferrals[0] == 
                users[referrerAddress].x14Matrix[level].closedPart) {
                updateX14(userAddress, referrerAddress, level, true);
                return updateX14ReferrerThirdLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].x14Matrix[level].secondLevelReferrals[2] == 
                users[referrerAddress].x14Matrix[level].closedPart) {
                updateX14(userAddress, referrerAddress, level, true);
                return updateX14ReferrerThirdLevel(userAddress, referrerAddress, level);
            } else {
                updateX14(userAddress, referrerAddress, level, false);
                return updateX14ReferrerThirdLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].x14Matrix[level].secondLevelReferrals[1] == userAddress) {
            updateX14(userAddress, referrerAddress, level, false);
            return updateX14ReferrerThirdLevel(userAddress, referrerAddress, level);
        } else  if (users[referrerAddress].x14Matrix[level].secondLevelReferrals[3] == userAddress) {
            updateX14(userAddress, referrerAddress, level, false);
            return updateX14ReferrerThirdLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].x14Matrix[level].secondLevelReferrals[0] == userAddress) {
            updateX14(userAddress, referrerAddress, level, true);
            return updateX14ReferrerThirdLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].x14Matrix[level].secondLevelReferrals[2] == userAddress) {
            updateX14(userAddress, referrerAddress, level, true);
            return updateX14ReferrerThirdLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].x14Matrix[level].secondLevelReferrals[0]].x14Matrix[level].secondLevelReferrals.length <= 
            users[users[referrerAddress].x14Matrix[level].secondLevelReferrals[1]].x14Matrix[level].secondLevelReferrals.length) {
            updateX14(userAddress, referrerAddress, level, false);
        } else if (users[users[referrerAddress].x14Matrix[level].secondLevelReferrals[2]].x14Matrix[level].secondLevelReferrals.length <= 
            users[users[referrerAddress].x14Matrix[level].secondLevelReferrals[3]].x14Matrix[level].secondLevelReferrals.length) {
            updateX14(userAddress, referrerAddress, level, false);
        } else {
            updateX14(userAddress, referrerAddress, level, true);
        }
        
       
        updateX14ReferrerThirdLevel(userAddress, referrerAddress, level);
    }

    function updateX14(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].x14Matrix[level].firstLevelReferrals[0]].x14Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x14Matrix[level].firstLevelReferrals[0], 3, level, uint8(users[users[referrerAddress].x14Matrix[level].firstLevelReferrals[0]].x14Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].x14Matrix[level].firstLevelReferrals[0]].x14Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x14Matrix[level].currentReferrer = users[referrerAddress].x14Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x14Matrix[level].firstLevelReferrals[1]].x14Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x14Matrix[level].firstLevelReferrals[1], 3, level, uint8(users[users[referrerAddress].x14Matrix[level].firstLevelReferrals[1]].x14Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].x14Matrix[level].firstLevelReferrals[1]].x14Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x14Matrix[level].currentReferrer = users[referrerAddress].x14Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateX14ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].x14Matrix[level].secondLevelReferrals.length < 4) {
            return sendETHDividends(referrerAddress, userAddress, 3, level);
        }
    }
       
    function updateX14ReferrerThirdLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].x14Matrix[level].thirdLevelReferrals.length < 8) {
            return sendETHDividends(referrerAddress, userAddress, 3, level);
        }
        
        address[] memory x14 = users[users[referrerAddress].x14Matrix[level].currentReferrer].x14Matrix[level].secondLevelReferrals;
        
        if (x14.length == 4) {
            if (x14[0] == referrerAddress ||
                x14[1] == referrerAddress ||
                x14[2] == referrerAddress ||
                x14[3] == referrerAddress) {
                users[users[referrerAddress].x14Matrix[level].currentReferrer].x14Matrix[level].closedPart = referrerAddress;
            } else if (x14.length == 1) {
                if (x14[0] == referrerAddress) {
                    users[users[referrerAddress].x14Matrix[level].currentReferrer].x14Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].x14Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].x14Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].x14Matrix[level].thirdLevelReferrals = new address[](0);
        users[referrerAddress].x14Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeX14Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x14Matrix[level].blocked = true;
        }

        users[referrerAddress].x14Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeX14Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 3, level);
            updateX14Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 3, level);
            sendETHDividends(owner, userAddress, 3, level);
        }
    }
    
    function findFreeX14Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX14Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function usersActiveX14Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX14Levels[level];
    }

    function usersX14Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, address[] memory, bool, address) {
        return (users[userAddress].x14Matrix[level].currentReferrer,
                users[userAddress].x14Matrix[level].firstLevelReferrals,
                users[userAddress].x14Matrix[level].secondLevelReferrals,
                users[userAddress].x14Matrix[level].thirdLevelReferrals,
                users[userAddress].x14Matrix[level].blocked,
                users[userAddress].x14Matrix[level].closedPart);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
      
            while (true) {
                if (users[receiver].x14Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x14Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, level);

        if (!address(uint160(receiver)).send(levelPrice[level])) {
           // return address(uint160(receiver)).transfer(address(this).balance);
            emit sendETHDividends_Tansfer(receiver, address(this).balance);
            return;
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