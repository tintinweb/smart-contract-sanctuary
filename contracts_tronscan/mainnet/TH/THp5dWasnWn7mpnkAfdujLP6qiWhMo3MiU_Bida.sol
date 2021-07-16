//SourceUnit: bida.sol

pragma solidity >=0.4.23 <0.6.0;

interface IToken {
	//function transfer(address _to, uint256 _value) external returns (bool);
    //function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function transfer(address _to, uint256 _value) external;
    function transferFrom(address _from, address _to, uint256 _value) external;
}

contract Bida {
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
		uint totem;
		uint lpToken;
		uint lpTmp;
		uint lpCount;
		
		uint lastRefId;
		
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX6Levels;
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;
		
		mapping(uint => address) Refs;
    }
    
    struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct X6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;
        address closedPart;
    }

    uint8 public constant LAST_LEVEL = 15;
	uint8 public constant LAST_TOTEM = 15;
	
	uint8 public constant decimalsUsdt = 6;
	uint8 public constant decimalsBgd = 18;
	IToken public usdt;
	IToken public bgd;

	address public teamAddr;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
	
	mapping(address => uint) public balances_x3;
	mapping(address => uint) public balances_x6;
    mapping(address => uint) public balances_refer;

    uint public lastUserId = 2;
    address public owner;
    
    mapping(uint8 => uint) public levelPrice;
	mapping(uint8 => uint) public totemPrice;
	
	uint public lpBalance;
	uint public lpReward;
	uint public totalReceived;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedUsdtReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraUsdtDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
	
    
    constructor(address ownerAddress, address usdtAddress, address bgdAddress, address teamAddress) public {
		levelPrice[1] = 5;
		levelPrice[2] = 10;
		levelPrice[3] = 15;
		levelPrice[4] = 20;
		levelPrice[5] = 25;
		levelPrice[6] = 30;
		levelPrice[7] = 35;
		levelPrice[8] = 40;
		levelPrice[9] = 45;
		levelPrice[10] = 50;
		levelPrice[11] = 55;
		levelPrice[12] = 60;
		levelPrice[13] = 65;
		levelPrice[14] = 70;
		levelPrice[15] = 75;
		
		totemPrice[1] = 1000;
		totemPrice[2] = 1000;
		totemPrice[3] = 1000;
		totemPrice[4] = 1000;
		totemPrice[5] = 1000;
		totemPrice[6] = 1000;
		totemPrice[7] = 1000;
		totemPrice[8] = 1000;
		totemPrice[9] = 1000;
		totemPrice[10] = 1000;
		totemPrice[11] = 1000;
		totemPrice[12] = 1000;
		totemPrice[13] = 1000;
		totemPrice[14] = 1000;
		totemPrice[15] = 1000;
		
		usdt = IToken(usdtAddress);
		bgd = IToken(bgdAddress);

		teamAddr = teamAddress;
		
        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
			totem: uint8(0),
			lpToken: uint(0),
			lpTmp: uint(0),
			lpCount: uint(0),
			lastRefId: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 j = 1; j <= LAST_LEVEL; j++) {
            users[ownerAddress].activeX3Levels[j] = true;
            users[ownerAddress].activeX6Levels[j] = true;
        }
        
        userIds[1] = ownerAddress;
    }

    function registrationExt(address referrerAddress) external {
        registration(msg.sender, referrerAddress);
    }
	
	function buyTotem(uint8 totem) external {
		require(totem >= 1 && totem <= LAST_TOTEM, "invalid totem");
		require(users[msg.sender].totem == totem - 1, "invalid totem");
        bgd.transferFrom(msg.sender, address(this), uint(totemPrice[totem]) * (10 ** uint(decimalsBgd)));
		users[msg.sender].totem = uint(totem);
	}
    
    function buyNewLevel(uint8 matrix, uint8 level) external {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        //require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
		
        if (matrix == 1) {
            require(!users[msg.sender].activeX3Levels[level], "level already activated");

            if (users[msg.sender].x3Matrix[level-1].blocked) {
                users[msg.sender].x3Matrix[level-1].blocked = false;
            }
    
            address freeX3Referrer = findFreeX3Referrer(msg.sender, level);
            users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[msg.sender].activeX3Levels[level] = true;
            updateX3Referrer(msg.sender, freeX3Referrer, level);
            
            emit Upgrade(msg.sender, freeX3Referrer, 1, level);

        } else {
            require(!users[msg.sender].activeX6Levels[level], "level already activated"); 

            if (users[msg.sender].x6Matrix[level-1].blocked) {
                users[msg.sender].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(msg.sender, level);
            
            users[msg.sender].activeX6Levels[level] = true;
            updateX6Referrer(msg.sender, freeX6Referrer, level);
            
            emit Upgrade(msg.sender, freeX6Referrer, 2, level);
        }
    }    
	
	function withdraw() external {
		require(lpReward > 0 && users[msg.sender].lpToken > 0 && users[msg.sender].lpToken <= lpBalance);
		uint reward = lpReward * users[msg.sender].lpToken / lpBalance;
		//bool succ = usdt.transfer(msg.sender, reward);
        usdt.transfer(msg.sender, reward);
		//require(succ, "withdraw failed.");
		lpReward -= reward;
		lpBalance -= users[msg.sender].lpToken;
		users[msg.sender].lpToken = 0;
		users[msg.sender].lpCount = 0;
		users[msg.sender].lpTmp = 0;
	}
    
    function withdrawX3() external {
        require(balances_x3[msg.sender] > 0, "no enough");
        usdt.transfer(msg.sender, balances_x3[msg.sender]);
        balances_x3[msg.sender] = 0;
    }

    function withdrawX6() external {
        require(balances_x6[msg.sender] > 0, "no enough");
        usdt.transfer(msg.sender, balances_x6[msg.sender]);
        balances_x6[msg.sender] = 0;
    }

    function withdrawRefer() external {
        require(balances_refer[msg.sender] > 0, "no enough");
        usdt.transfer(msg.sender, balances_refer[msg.sender]);
        balances_refer[msg.sender] = 0;
    }

    function registration(address userAddress, address referrerAddress) private {
        //require(msg.value == 0.05 trx, "registration cost 0.05");
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
			totem: uint8(0),
			lpToken: uint(0),
			lpTmp: uint(0),
			lpCount: uint(0),
			lastRefId: uint(0)
        });
		
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeX3Levels[1] = true; 
        users[userAddress].activeX6Levels[1] = true;
        
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;
		
		users[referrerAddress].lastRefId++;
		users[referrerAddress].Refs[users[referrerAddress].lastRefId] = userAddress;

        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateX3Referrer(userAddress, freeX3Referrer, 1);

        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1);
        
		updateLpCount(userAddress);
		
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
	
	function updateLpCount(address userAddress) private {
		if(users[userAddress].referrer != address(0)) {
			users[users[userAddress].referrer].lpCount++;
			if(users[users[userAddress].referrer].lpCount >= 15 && users[users[userAddress].referrer].totem >= 10) {
				if(users[users[userAddress].referrer].lpTmp > 0) {
					users[users[userAddress].referrer].lpToken += users[users[userAddress].referrer].lpTmp;
					lpBalance += users[users[userAddress].referrer].lpTmp;
					users[users[userAddress].referrer].lpTmp = 0;
				}
			}
			
			if(users[users[userAddress].referrer].referrer != address(0)) {
				users[users[users[userAddress].referrer].referrer].lpCount++;
				if(users[users[users[userAddress].referrer].referrer].lpCount >= 15 && users[users[users[userAddress].referrer].referrer].totem >= 10) {
					if(users[users[users[userAddress].referrer].referrer].lpTmp > 0) {
						users[users[users[userAddress].referrer].referrer].lpToken += users[users[users[userAddress].referrer].referrer].lpTmp;
						lpBalance += users[users[users[userAddress].referrer].referrer].lpTmp;
						users[users[users[userAddress].referrer].referrer].lpTmp = 0;
					}
				}
				
				if(users[users[users[userAddress].referrer].referrer].referrer != address(0)) {
					users[users[users[users[userAddress].referrer].referrer].referrer].lpCount++;
					if(users[users[users[users[userAddress].referrer].referrer].referrer].lpCount >= 15 && users[users[users[users[userAddress].referrer].referrer].referrer].totem >= 10) {
						if(users[users[users[users[userAddress].referrer].referrer].referrer].lpTmp > 0) {
							users[users[users[users[userAddress].referrer].referrer].referrer].lpToken += users[users[users[users[userAddress].referrer].referrer].referrer].lpTmp;
							lpBalance += users[users[users[users[userAddress].referrer].referrer].referrer].lpTmp;
							users[users[users[users[userAddress].referrer].referrer].referrer].lpTmp = 0;
						}
					}
				}
			}
		}
	}
    
    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return sendUSDTDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeX3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x3Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level);
            if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].x3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendUSDTDividends(owner, userAddress, 1, level);
            users[owner].x3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendUSDTDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].x6Matrix[level].currentReferrer;            
            users[ref].x6Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].x6Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }

            return updateX6ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].x6Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].x6Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].x6Matrix[level].closedPart)) {

                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].closedPart) {
                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateX6(userAddress, referrerAddress, level, false);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateX6(userAddress, referrerAddress, level, false);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length) {
            updateX6(userAddress, referrerAddress, level, false);
        } else {
            updateX6(userAddress, referrerAddress, level, true);
        }
        
        updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            return sendUSDTDividends(referrerAddress, userAddress, 2, level);
        }
        
        address[] memory x6 = users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].firstLevelReferrals;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].x6Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeX6Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x6Matrix[level].blocked = true;
        }

        users[referrerAddress].x6Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendUSDTDividends(owner, userAddress, 2, level);
        }
    }
    
    function findFreeX3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeX6Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX6Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }

    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }

    function usersTeam(address userAddress) public view returns(uint, uint, uint) {
        return (lpReward, users[userAddress].lpToken, lpBalance);
    }

    function usersEarn(address userAddress) public view returns(uint, uint, uint, uint) {
        return (balances_x3[userAddress], balances_x6[userAddress], balances_refer[userAddress], users[userAddress].totem);
    }

    function usersActive(address userAddress, uint8 level) public view returns(uint, uint, uint, uint, uint, uint) {
        uint active = 0;
        if(users[userAddress].activeX3Levels[level] && users[userAddress].activeX6Levels[level]) {
            active = 3;
        } else if(users[userAddress].activeX3Levels[level] && !users[userAddress].activeX6Levels[level]) {
            active = 2;
        } else if(!users[userAddress].activeX3Levels[level] && users[userAddress].activeX6Levels[level]) {
            active = 1;
        } else {
            active = 0;
        }
        return (active, users[userAddress].x3Matrix[level].referrals.length, users[userAddress].x3Matrix[level].reinvestCount,
            users[userAddress].x6Matrix[level].firstLevelReferrals.length, users[userAddress].x6Matrix[level].secondLevelReferrals.length,
            users[userAddress].x6Matrix[level].reinvestCount);
    }

    function userRefId(address userAddress) public view returns(uint) {
        return users[userAddress].lastRefId;
    }

    function userRefAddr(address userAddress, uint start) public view returns(address, address, address, address, address, address) {
        return (users[userAddress].Refs[start], users[userAddress].Refs[start + 1], users[userAddress].Refs[start + 2],
            users[userAddress].Refs[start + 3], users[userAddress].Refs[start + 4], users[userAddress].Refs[start + 5]);
    }


    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked);
    }

    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].firstLevelReferrals,
                users[userAddress].x6Matrix[level].secondLevelReferrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].closedPart);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
	
	function userTotem(address user) public view returns (uint) {
		return users[user].totem;
	}
	
	function statistic() public view returns (uint, uint, uint) {
		return (lastUserId, totalReceived, lpReward);
	}
	
    function findUsdtReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].x3Matrix[level].blocked) {
                    emit MissedUsdtReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].x6Matrix[level].blocked) {
                    emit MissedUsdtReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendUSDTDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findUsdtReceiver(userAddress, _from, matrix, level);

		uint total = uint(levelPrice[level]) * (10 ** uint(decimalsUsdt));
		totalReceived += total;
		
		//uint _pools = total * 5 / 100;
		uint _dividends = total * (60 + users[receiver].totem) / 100;
		
		uint used = 0;

        usdt.transferFrom(msg.sender, teamAddr, total * (10 + (15 - users[receiver].totem) / 2) / 100);
        used += (total * (10 + (15 - users[receiver].totem) / 2) / 100);

        usdt.transferFrom(msg.sender, address(this), total - used);

        if(matrix == 1) {
            balances_x3[receiver] += _dividends;
        } else if(matrix == 2) {
            balances_x6[receiver] += _dividends;
        }
		used += _dividends;
		
		used += sendReferrer(msg.sender, total);
		if(total > used) {

			lpReward += (total - used);
		}
        
        if (isExtraDividends) {
            emit SentExtraUsdtDividends(_from, receiver, matrix, level);
        }
    }
	
	function sendReferrer(address _from, uint total) private returns(uint used) {
		used = 0;
		if(users[_from].referrer != address(0)) {

            balances_refer[users[_from].referrer] += total * 5 / 100;

			used += total * 5 / 100;
			if(users[users[_from].referrer].lpCount >= 15 && users[users[_from].referrer].totem >= 10) {
				users[users[_from].referrer].lpToken += total * 20 / 100; 
				lpBalance += total * 20 / 100;
			} else {
				users[users[_from].referrer].lpTmp += total * 20 / 100; 
			}
			
			if(users[users[_from].referrer].referrer != address(0)) {
                balances_refer[users[users[_from].referrer].referrer] += total * 3 / 100;

				used += total * 3 / 100;
				if(users[users[users[_from].referrer].referrer].lpCount >= 15 && users[users[users[_from].referrer].referrer].totem >= 10) {
					users[users[users[_from].referrer].referrer].lpToken += total * 30 / 100; 
					lpBalance += total * 30 / 100;
				} else {
					users[users[users[_from].referrer].referrer].lpTmp += total * 30 / 100; 
				}
				
				if(users[users[users[_from].referrer].referrer].referrer != address(0)) {
                    balances_refer[users[users[users[_from].referrer].referrer].referrer] += total * 2 / 100;

					used += total * 2 / 100;
					if(users[users[users[users[_from].referrer].referrer].referrer].lpCount >= 15 && users[users[users[users[_from].referrer].referrer].referrer].totem >= 10) {
						users[users[users[users[_from].referrer].referrer].referrer].lpToken += total * 50 / 100; 
						lpBalance += total * 50 / 100;
					} else {
						users[users[users[users[_from].referrer].referrer].referrer].lpTmp += total * 50 / 100; 
					}
				}
			}
		}
	}
}