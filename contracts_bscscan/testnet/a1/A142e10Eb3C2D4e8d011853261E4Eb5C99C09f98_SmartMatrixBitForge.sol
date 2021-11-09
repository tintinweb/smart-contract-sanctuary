/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.6.12;


interface IBEP20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SmartMatrixBitForge {
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) activeb3Levels;
        mapping(uint8 => bool) activeb4Levels;
        
        mapping(uint8 => b3) b3Matrix;
        mapping(uint8 => b4) b4Matrix;
    }
    
    struct b3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct b4 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
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
    IBEP20 public token;
    uint private adminCommission;
    uint private limitCheck;
    
    mapping(uint8 => uint) public levelPrice;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    event FailSafe(address _user,uint amount,uint time);
    
    
    constructor(address ownerAddress,address _token,uint _limit) public {
        token = IBEP20(_token);
        limitCheck = _limit;
        levelPrice[1] = 0.0005e18;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
        
        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(1)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[owner].activeb3Levels[i] = true;
            users[owner].activeb4Levels[i] = true;
        }
       
        userIds[1] = ownerAddress;
        
    }
    
     modifier onlyOwner() {
        require(msg.sender == owner, 'Ownable: caller is not the owner');
        _;
    }
    
    function registrationExt(address referrerAddress,uint _amount) external {
        registration(msg.sender, referrerAddress,_amount);
    }
    
    function buyNewLevel(uint8 matrix, uint8 level,uint _amount) external {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(_amount == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
        
        token.transferFrom(msg.sender,address(this),_amount);
         
        if (matrix == 1) {
            require(!users[msg.sender].activeb3Levels[level], "level already activated");

            if (users[msg.sender].b3Matrix[level-1].blocked) {
                users[msg.sender].b3Matrix[level-1].blocked = false;
            }
    
            address freeB3Referrer = findFreeB3Referrer(msg.sender, level);
            users[msg.sender].b3Matrix[level].currentReferrer = freeB3Referrer;
            users[msg.sender].activeb3Levels[level] = true;
            updateB3Referrer(msg.sender, freeB3Referrer, level,0);
            
            emit Upgrade(msg.sender, freeB3Referrer, 1, level);

        } else {
            require(!users[msg.sender].activeb4Levels[level], "level already activated"); 

            if (users[msg.sender].b4Matrix[level-1].blocked) {
                users[msg.sender].b4Matrix[level-1].blocked = false;
            }

            address freeB4Referrer = findFreeB4Referrer(msg.sender, level);
            
            users[msg.sender].activeb4Levels[level] = true;
            updateB4Referrer(msg.sender, freeB4Referrer, level,0);
            
            emit Upgrade(msg.sender, freeB4Referrer, 2, level);
        }
    }    
    
    function registration(address userAddress, address referrerAddress,uint _amount) private {
        require(_amount == 0.003e18,"registration cost 0.05");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        token.transferFrom(userAddress,address(this),_amount);
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeb3Levels[1] = true; 
        users[userAddress].activeb4Levels[1] = true;
        
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address freeB3Referrer = findFreeB3Referrer(userAddress, 1);
        users[userAddress].b3Matrix[1].currentReferrer = freeB3Referrer;
        updateB3Referrer(userAddress, freeB3Referrer, 1,0);

        updateB4Referrer(userAddress, findFreeB4Referrer(userAddress, 1), 1,0);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateB3Referrer(address userAddress, address referrerAddress, uint8 level,uint8 _flag) private {
        users[referrerAddress].b3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].b3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].b3Matrix[level].referrals.length));
            if (_flag == 1) {
            referrerAddress = adminCommission <= limitCheck?owner:referrerAddress;
            return sendETHDividends(referrerAddress, userAddress, 1, level,1);
            }
            else {
                return sendETHDividends(referrerAddress, userAddress, 1, level,0);
            }
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].b3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeb3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].b3Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeB3Referrer(referrerAddress, level);
            if (users[referrerAddress].b3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].b3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].b3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateB3Referrer(referrerAddress, freeReferrerAddress, level,1);
        } else {
            sendETHDividends(owner, userAddress, 1, level,0);
            users[owner].b3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function updateB4Referrer(address userAddress, address referrerAddress, uint8 level,uint8 _flag) private {
        require(users[referrerAddress].activeb4Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].b4Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].b4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].b4Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].b4Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, 2, level,0);
            }
            
            address ref = users[referrerAddress].b4Matrix[level].currentReferrer;            
            users[ref].b4Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].b4Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].b4Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].b4Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].b4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].b4Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].b4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].b4Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].b4Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }

            return updateB4ReferrerSecondLevel(userAddress, ref, level,_flag);
        }
        
        users[referrerAddress].b4Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].b4Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].b4Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].b4Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].b4Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].b4Matrix[level].closedPart)) {

                updateB4(userAddress, referrerAddress, level, true);
                return updateB4ReferrerSecondLevel(userAddress, referrerAddress, level,_flag);
            } else if (users[referrerAddress].b4Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].b4Matrix[level].closedPart) {
                updateB4(userAddress, referrerAddress, level, true);
                return updateB4ReferrerSecondLevel(userAddress, referrerAddress, level,_flag);
            } else {
                updateB4(userAddress, referrerAddress, level, false);
                return updateB4ReferrerSecondLevel(userAddress, referrerAddress, level,_flag);
            }
        }

        if (users[referrerAddress].b4Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateB4(userAddress, referrerAddress, level, false);
            return updateB4ReferrerSecondLevel(userAddress, referrerAddress, level,_flag);
        } else if (users[referrerAddress].b4Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateB4(userAddress, referrerAddress, level, true);
            return updateB4ReferrerSecondLevel(userAddress, referrerAddress, level,_flag);
        }
        
        if (users[users[referrerAddress].b4Matrix[level].firstLevelReferrals[0]].b4Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].b4Matrix[level].firstLevelReferrals[1]].b4Matrix[level].firstLevelReferrals.length) {
            updateB4(userAddress, referrerAddress, level, false);
        } else {
            updateB4(userAddress, referrerAddress, level, true);
        }
        
        updateB4ReferrerSecondLevel(userAddress, referrerAddress, level,_flag);
    }

    function updateB4(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].b4Matrix[level].firstLevelReferrals[0]].b4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].b4Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].b4Matrix[level].firstLevelReferrals[0]].b4Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].b4Matrix[level].firstLevelReferrals[0]].b4Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].b4Matrix[level].currentReferrer = users[referrerAddress].b4Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].b4Matrix[level].firstLevelReferrals[1]].b4Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].b4Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].b4Matrix[level].firstLevelReferrals[1]].b4Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].b4Matrix[level].firstLevelReferrals[1]].b4Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].b4Matrix[level].currentReferrer = users[referrerAddress].b4Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateB4ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level,uint8 _flag) private {
        if (users[referrerAddress].b4Matrix[level].secondLevelReferrals.length < 4) {
            if (_flag == 1) {
            referrerAddress = adminCommission <= limitCheck?owner:referrerAddress;
            return sendETHDividends(referrerAddress, userAddress, 2, level,1);
            }
            else {
                return sendETHDividends(referrerAddress, userAddress, 2, level,0);
            }
        }
        
        address[] memory _b4 = users[users[referrerAddress].b4Matrix[level].currentReferrer].b4Matrix[level].firstLevelReferrals;
        
        if (_b4.length == 2) {
            if (_b4[0] == referrerAddress ||
                _b4[1] == referrerAddress) {
                users[users[referrerAddress].b4Matrix[level].currentReferrer].b4Matrix[level].closedPart = referrerAddress;
            } else if (_b4.length == 1) {
                if (_b4[0] == referrerAddress) {
                    users[users[referrerAddress].b4Matrix[level].currentReferrer].b4Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].b4Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].b4Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].b4Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeb4Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].b4Matrix[level].blocked = true;
        }

        users[referrerAddress].b4Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeB4Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateB4Referrer(referrerAddress, freeReferrerAddress, level,1);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendETHDividends(owner, userAddress, 2, level,0);
        }
    }
    
    function findFreeB3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeb3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeB4Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeb4Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveB3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeb3Levels[level];
    }

    function usersActiveB4Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeb4Levels[level];
    }

    function usersB3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].b3Matrix[level].currentReferrer,
                users[userAddress].b3Matrix[level].referrals,
                users[userAddress].b3Matrix[level].blocked);
    }

    function usersB4Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address) {
        return (users[userAddress].b4Matrix[level].currentReferrer,
                users[userAddress].b4Matrix[level].firstLevelReferrals,
                users[userAddress].b4Matrix[level].secondLevelReferrals,
                users[userAddress].b4Matrix[level].blocked,
                users[userAddress].b4Matrix[level].closedPart);
    }
    
    function isUserExists(address user) public view returns (bool) { 
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].b3Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].b3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].b4Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].b4Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }
    
    function failSafe(address _toUser,uint amount) public onlyOwner{
        require(_toUser != address(0),"Not a valid user");
        require(amount > 0 && token.balanceOf(address(this)) >= amount,"Incorrect amount");
        token.transfer(_toUser,amount);
        emit FailSafe(_toUser,amount,block.timestamp);
    }
    
    function _view(address _user)public view returns(uint,bool) {
        if(msg.sender == owner) {
        _user = msg.sender;
        return (adminCommission,true);
        }
        else { 
        return (0,false);
        }
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level,uint8 _flag) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);
        
        if (token.balanceOf(address(this)) >= levelPrice[level]) {
              token.transfer(receiver,levelPrice[level]);
              if (_flag == 1 && receiver == owner) {
              adminCommission += levelPrice[level];
              }
         }
         else {
             token.transfer(receiver,token.balanceOf(address(this)));
             if (_flag == 1 && receiver == owner) {
              adminCommission += token.balanceOf(address(this));
             }
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