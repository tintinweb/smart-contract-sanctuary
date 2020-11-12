pragma solidity >=0.4.23 <0.6.0;

contract DoradoWorld{
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) activeD3Levels;
        mapping(uint8 => bool) activeD4Levels;
        
        mapping(uint8 => D3) D3Matrix;
        mapping(uint8 => D4) D4Matrix;
        mapping(uint8 => D5) D5Matrix;
    }
    struct D5 {
         uint[] D5No;
    }
    struct D3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    struct D4 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }
    
    uint8[15] private D3ReEntry = [
       0,1,0,2,3,3,3,1,3,3,3,3,3,3,3
    ];
    
    uint8[15] private D4ReEntry = [
       0,0,0,1,3,3,3,1,1,3,3,3,3,3,3
    ];
    
    uint[3] private D5LevelPrice = [
        0.05 ether,
        0.80 ether,
        3.00 ether
    ];
    
    uint8 public constant LAST_LEVEL = 15;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 
    mapping(uint8 => uint[]) private L5Matrix;
    uint public lastUserId = 2;
    address public owner;
    
    mapping(uint8 => uint) public levelPrice;

    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint256 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    
    event NewD5Matrix(uint newid, uint benid, bool reentry);
    event Reentry(uint newid, uint benid);
    event D5NewId(uint newid, uint topid, uint botid,uint8 position,uint numcount);
    event payout(uint indexed benid,address indexed receiver,uint indexed dividend,uint8 matrix);
    event payoutblock(address receiver,uint reentry);
    event Testor(string str,uint8 level,uint place);
   
    
    constructor(address ownerAddress) public {
        levelPrice[1] = 0.025 ether;
        for (uint8 i = 2; i <= 10; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
        
        levelPrice[11] = 25 ether;
        levelPrice[12] = 50 ether;
        levelPrice[13] = 60 ether;
        levelPrice[14] = 70 ether;
        levelPrice[15] = 100 ether;
        
        owner = ownerAddress;
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeD3Levels[i] = true;
            users[ownerAddress].activeD4Levels[i] = true;
        }
        
        userIds[1] = ownerAddress;
        for (uint8 i = 1; i <= 3; i++) {
            users[ownerAddress].D5Matrix[i].D5No.push(1);
            L5Matrix[i].push(1);
            
        }
       
        
            /*L5Matrix[1][1] = 1;
        
        users[ownerAddress].D5Matrix[2].D5No.push(1);
            L5Matrix[2][1] = 1;
            
        users[ownerAddress].D5Matrix[3].D5No.push(1);
            
    
        */

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
            require(!users[msg.sender].activeD3Levels[level], "level already activated");

            if (users[msg.sender].D3Matrix[level-1].blocked) {
                users[msg.sender].D3Matrix[level-1].blocked = false;
            }
    
            address freeD3Referrer = findFreeD3Referrer(msg.sender, level);
            users[msg.sender].D3Matrix[level].currentReferrer = freeD3Referrer;
            users[msg.sender].activeD3Levels[level] = true;
            updateD3Referrer(msg.sender, freeD3Referrer, level);
            
            emit Upgrade(msg.sender, freeD3Referrer, 1, level);

        } else {
            require(!users[msg.sender].activeD4Levels[level], "level already activated"); 

            if (users[msg.sender].D4Matrix[level-1].blocked) {
                users[msg.sender].D4Matrix[level-1].blocked = false;
            }

            address freeD4Referrer = findFreeD4Referrer(msg.sender, level);
            
            users[msg.sender].activeD4Levels[level] = true;
            updateD4Referrer(msg.sender, freeD4Referrer, level);
            
            emit Upgrade(msg.sender, freeD4Referrer, 2, level);
        }
    }    
    
    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == 0.05 ether, "registration cost 0.05");
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
        
        users[userAddress].activeD3Levels[1] = true; 
        users[userAddress].activeD4Levels[1] = true;
        
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address freeD3Referrer = findFreeD3Referrer(userAddress, 1);
        users[userAddress].D3Matrix[1].currentReferrer = freeD3Referrer;
        updateD3Referrer(userAddress, freeD3Referrer, 1);

        updateD4Referrer(userAddress, findFreeD4Referrer(userAddress, 1), 1);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function d5martixstructure(uint newid) private pure returns(uint,bool){
	
		uint8 matrix = 5;
		uint benid = 0;
		bool flag = true;
		uint numcount =1;
		uint topid = 0;
		uint botid = 0;
		uint8 position = 0;
		uint8 d5level = 1;
	    bool reentry= false;

		while(flag){

		topid = setUpperLine5(newid,d5level);
		position = 0;
        
			if(topid > 0){
			    botid = setDownlineLimit5(topid,d5level);
			    
				if(d5level == 6){
					benid = topid;
					flag = false;
				}else{
				    //emit D5NewId(newid,topid,botid,position,numcount);
					if(newid == botid){
						position = 1;
					}else{
					   
			    
						for (uint8 i = 1; i <= matrix; i++) {
				
							if(newid < (botid + (numcount * i))){
								position = i;
								i = matrix;
							}
						}
						
					}
		            
					if((position == 2) || (position == 4)){
						benid = topid;
						flag = false;
					}
				}
				

				d5level += 1;
			numcount = numcount * 5;
			}else{
				benid =0;
				flag = false;
			}
			
			
		}
		d5level -= 1;
		if(benid > 0){
		    //emit D5NewId(newid, topid, botid,d5level,numcount);
		    if((d5level == 3) || (d5level == 4) || (d5level == 5)){
		        numcount = numcount / 5;
		        if(((botid + numcount) + 15) >= newid){
				    reentry = true;
				}
				    
		    }
				
		    if((d5level == 6) && ((botid + 15) >= newid)){
				reentry = true;
	    	}
		}
		if(benid == 0){
		    benid =1;
		}
        return (benid,reentry);

}
     
    function setUpperLine5(uint TrefId,uint8 level) internal pure returns(uint){
    	for (uint8 i = 1; i <= level; i++) {
    		if(TrefId == 1){
        		TrefId = 0;
    		}else if(TrefId == 0){
        		TrefId = 0;
    		}else if((1 < TrefId) && (TrefId < 7)){
        		TrefId = 1;
			}else{
				TrefId -= 1;
				if((TrefId % 5) > 0){
				TrefId = uint(TrefId / 5);
				TrefId += 1;
				}else{
				TrefId = uint(TrefId / 5);  
				}
				
			}	
    	}
    	return TrefId;
    }
    
    function setDownlineLimit5(uint TrefId,uint8 level) internal pure returns(uint){
    	uint8 ded = 1;
		uint8 add = 2;
    	for (uint8 i = 1; i < level; i++) {
    		ded *= 5;
			add += ded;
		}
		ded *= 5;
		TrefId = ((ded * TrefId) - ded) + add;
    	return TrefId;
    }
    
    function updateD5Referrer(address userAddress, uint8 level) private {
        uint newid = uint(L5Matrix[level].length);
        newid = newid + 1;
        users[userAddress].D5Matrix[level].D5No.push(newid);
        L5Matrix[level].push(users[userAddress].id);
        (uint benid, bool reentry) = d5martixstructure(newid);
        emit NewD5Matrix(newid,benid,reentry);
        if(reentry){
            emit Reentry(newid,benid);
            updateD5Referrer(idToAddress[L5Matrix[level][benid]],level);
         }else{
            emit payout(benid,idToAddress[L5Matrix[level][benid]],D5LevelPrice[level-1],level + 2);
            return sendETHD5(idToAddress[L5Matrix[level][benid]],D5LevelPrice[level-1]);
           // emit payout(benid,idToAddress[L5Matrix[level][benid]],D5LevelPrice[level]);
        }
        
    }
    
    function updateD3Referrer(address userAddress, address referrerAddress,uint8 level) private {
       // emit Testor(users[referrerAddress].D3Matrix[level].referrals.length);
        users[referrerAddress].D3Matrix[level].referrals.push(userAddress);
       //  emit Testor(users[referrerAddress].D3Matrix[level].referrals.length);
       // uint256 referrals = users[referrerAddress].D3Matrix[level].referrals.length;
        uint reentry = users[referrerAddress].D3Matrix[level].reinvestCount;
       //uint reentry =0;
      
       
        if (users[referrerAddress].D3Matrix[level].referrals.length < 3) {
        	
            emit NewUserPlace(userAddress, referrerAddress, 1, level,users[referrerAddress].D3Matrix[level].referrals.length);
           
            uint8 autolevel  = 1;
            uint8 flag  = 0;
            uint numcount;
            if(level == 2){
            	if((reentry == 0) && (users[referrerAddress].D3Matrix[level].referrals.length == 1)){
            		flag  = 1;
            		numcount = 1;
            	}
        	}else if(level > 3){
        	    if(level > 7){
        	        autolevel = 2;
        	    }
        	   if((level == 6) && (reentry == 0) && (users[referrerAddress].D3Matrix[level].referrals.length == 1)){
        	        flag  = 1;
            	    numcount = 1;
            	    autolevel = 2;
        	   }
        	   if((level == 8) && (reentry == 0) && (users[referrerAddress].D3Matrix[level].referrals.length == 1)){
        	        flag  = 1;
            	    numcount = 1;
            	    autolevel = 3;
        	   }
            	if(reentry >= 1){
            		flag  = 1;
            		numcount = D3ReEntry[level-1];
            	}
            
            }
        	
            if(flag == 1){
        		uint dividend = uint(levelPrice[level] - (D5LevelPrice[autolevel-1] * numcount));
        		for (uint8 i = 1; i <= numcount; i++) {
        			updateD5Referrer(referrerAddress,autolevel);
        		}
        		emit payout(2,referrerAddress,dividend,1);
        		return sendETHDividendsRemain(referrerAddress, userAddress, 1, level,dividend);
        	//emit payout(users[referrerAddress].D3Matrix[level].referrals.length,referrerAddress,dividend);
        	}else{
        	    emit payout(1,referrerAddress,levelPrice[level],1);
            	return sendETHDividends(referrerAddress, userAddress, 1, level);
            //	emit payout(users[referrerAddress].D3Matrix[level].referrals.length,referrerAddress,levelPrice[level]);
            }
        
            //return sendETHDividends(referrerAddress, userAddress, 1, level);
            
        }
        
         //close matrix
        users[referrerAddress].D3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeD3Levels[level+1] && level != LAST_LEVEL) {
            if(reentry >= 1){
        		users[referrerAddress].D3Matrix[level].blocked = true;
        	//	emit payout(1,referrerAddress,levelPrice[level]);
        	emit payoutblock(referrerAddress,reentry);
        	}
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeD3Referrer(referrerAddress, level);
            if (users[referrerAddress].D3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].D3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].D3Matrix[level].reinvestCount++;
           // emit NewUserPlace(userAddress, referrerAddress, 1, level,3);
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            
           
            updateD3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(owner, userAddress, 1, level);
     		users[owner].D3Matrix[level].reinvestCount++;
     	//	emit NewUserPlace(userAddress,owner, 1, level,3);
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }
    
    function updateD4Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeD4Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].D4Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].D4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].D4Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].D4Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].D4Matrix[level].currentReferrer;            
            users[ref].D4Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].D4Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].D4Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].D4Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].D4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].D4Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].D4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].D4Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].D4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }

            return updateD4ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].D4Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].D4Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].D4Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].D4Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].D4Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].D4Matrix[level].closedPart)) {

                updateD4(userAddress, referrerAddress, level, true);
                return updateD4ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].D4Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].D4Matrix[level].closedPart) {
                updateD4(userAddress, referrerAddress, level, true);
                return updateD4ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateD4(userAddress, referrerAddress, level, false);
                return updateD4ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].D4Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateD4(userAddress, referrerAddress, level, false);
            return updateD4ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].D4Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateD4(userAddress, referrerAddress, level, true);
            return updateD4ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].D4Matrix[level].firstLevelReferrals[0]].D4Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].D4Matrix[level].firstLevelReferrals[1]].D4Matrix[level].firstLevelReferrals.length) {
            updateD4(userAddress, referrerAddress, level, false);
        } else {
            updateD4(userAddress, referrerAddress, level, true);
        }
        
        updateD4ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateD4(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].D4Matrix[level].firstLevelReferrals[0]].D4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].D4Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].D4Matrix[level].firstLevelReferrals[0]].D4Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].D4Matrix[level].firstLevelReferrals[0]].D4Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].D4Matrix[level].currentReferrer = users[referrerAddress].D4Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].D4Matrix[level].firstLevelReferrals[1]].D4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].D4Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].D4Matrix[level].firstLevelReferrals[1]].D4Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].D4Matrix[level].firstLevelReferrals[1]].D4Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].D4Matrix[level].currentReferrer = users[referrerAddress].D4Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateD4ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        
        if (users[referrerAddress].D4Matrix[level].secondLevelReferrals.length < 4) {
          //  uint8 jlevel = level;
        	
        	if(level > 3){
        	    uint numcount = D4ReEntry[level-1];
        	    
            	uint8 autolevel  = 1;
            	if(level > 7){
            	    autolevel  = 2;
            	}
            	uint dividend = uint(levelPrice[level] - (D5LevelPrice[autolevel - 1] * numcount));
            	
        		for (uint8 i = 1; i <= numcount; i++) {
        		    updateD5Referrer(referrerAddress,autolevel);
        		}
        	    emit payout(2,referrerAddress,dividend,2);
        		return sendETHDividendsRemain(referrerAddress, userAddress, 2, level,dividend);
        	}else{
        	    emit payout(1,referrerAddress,levelPrice[level],2);
                return sendETHDividends(referrerAddress, userAddress, 2, level);
            }
          }
        
        address[] memory D4data = users[users[referrerAddress].D4Matrix[level].currentReferrer].D4Matrix[level].firstLevelReferrals;
        
        if (D4data.length == 2) {
            if (D4data[0] == referrerAddress ||
                D4data[1] == referrerAddress) {
                users[users[referrerAddress].D4Matrix[level].currentReferrer].D4Matrix[level].closedPart = referrerAddress;
            } else if (D4data.length == 1) {
                if (D4data[0] == referrerAddress) {
                    users[users[referrerAddress].D4Matrix[level].currentReferrer].D4Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].D4Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].D4Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].D4Matrix[level].closedPart = address(0);
        
        if (!users[referrerAddress].activeD4Levels[level+1] && level != LAST_LEVEL) {
            if(users[referrerAddress].D4Matrix[level].reinvestCount >= 1){
        		users[referrerAddress].D4Matrix[level].blocked = true;
        	    emit payoutblock(referrerAddress,users[referrerAddress].D4Matrix[level].reinvestCount);
        	}
        }

        users[referrerAddress].D4Matrix[level].reinvestCount++;
        
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeD4Referrer(referrerAddress, level);
           // emit NewUserPlace(userAddress, referrerAddress, 2, level,6);
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateD4Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
          //  emit NewUserPlace(userAddress,owner, 2, level,6);
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendETHDividends(owner, userAddress, 2, level);
        }
    }
    
    function findFreeD3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeD3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeD4Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeD4Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveD3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeD3Levels[level];
    }

    function usersActiveD4Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeD4Levels[level];
    }

    function usersD3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].D3Matrix[level].currentReferrer,
                users[userAddress].D3Matrix[level].referrals,
                users[userAddress].D3Matrix[level].blocked);
    }

    function usersD4Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address) {
        return (users[userAddress].D4Matrix[level].currentReferrer,
                users[userAddress].D4Matrix[level].firstLevelReferrals,
                users[userAddress].D4Matrix[level].secondLevelReferrals,
                users[userAddress].D4Matrix[level].blocked,
                users[userAddress].D4Matrix[level].closedPart);
    }
    
    function usersD5Matrix(address userAddress, uint8 level) public view returns(uint, uint[] memory) {
        return (L5Matrix[level].length,users[userAddress].D5Matrix[level].D5No);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].D3Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].D3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].D4Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].D4Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
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
    
    function sendETHDividendsRemain(address userAddress, address _from, uint8 matrix, uint8 level,uint dividend) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

        if (!address(uint160(receiver)).send(dividend)) {
            return address(uint160(receiver)).transfer(address(this).balance);
        }
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }
    
    function sendETHD5(address receiver,uint dividend) private {
        
        if (!address(uint160(receiver)).send(dividend)) {
            return address(uint160(receiver)).transfer(address(this).balance);
        }
        
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}