//SourceUnit: DAPPMLM_Tron.sol

pragma solidity 0.5.9;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}


contract TRC20 {
    function mint(address reciever, uint value) public returns(bool);
}

contract DAPPM {
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX6Levels;
        mapping(uint8 => bool) activeX30Levels;
        
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;
        mapping(uint8 => X30) x30Matrix;
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
    
    struct X30 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        address[] thirdLevelReferrals;
        address[] fourthLevelReferrals;
        uint availReInvestBalance;
        bool blocked;
        uint reinvestCount;
        address closedPart;
    }

    uint8 public constant LAST_LEVEL = 15;
    TRC20 Token;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint8 => uint) public levelPrice;
    mapping(uint => uint) public levelTokens;
    using SafeMath for uint256;

    uint public lastUserId = 2;
    uint public tokenPerTrx = 1 * (10 **18); // 1 Tokens per Trx Decimal - 18
    uint public adminFee = 10 trx;
    uint public tokenDistLimit = 25000;
    address public owner;
    address public commissionAddress;
    bool public lockStatus;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId, uint time);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level, uint time);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint time);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place, uint time);
    event MissedTrxReceive(address indexed receiver, address indexed _from, uint8 matrix, uint8 level, uint time);
    event RecievedTrx(address indexed receiver, address indexed _from, uint8 matrix, uint8 level, uint amount, uint time);
    event SentExtraTrxDividends(address indexed _from, address indexed receiver, uint8 matrix, uint8 level,  uint amount, uint time);
    event RecievedAdminCommission(address indexed _from, uint commissionAmount, uint8 matrix, uint8 level, uint time);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    } 
    
    modifier isLock() {
        require(lockStatus == false, "Contract Locked");
        _;
    } 
    
    constructor(address ownerAddress, address _token, address _commissionAddress) public {
        levelPrice[1] = 100 trx;
        levelTokens[1] = (tokenPerTrx * levelPrice[1])/ 1 trx;
        
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
            levelTokens[i] = (tokenPerTrx * levelPrice[i])/ 1 trx;
        }
        
        owner = ownerAddress;
        Token = TRC20(_token);
        commissionAddress = _commissionAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeX3Levels[i] = true;
            users[ownerAddress].activeX6Levels[i] = true;
            users[ownerAddress].activeX30Levels[i] = true;
        }
        
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }
    
    function registrationExt(address referrerAddress) external isLock payable {
        registration(msg.sender, referrerAddress);
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external isLock  payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2 || matrix == 3, "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
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
            
            emit Upgrade(msg.sender, freeX3Referrer, 1, level, now);

        } 
        else if(matrix == 2) {
            require(!users[msg.sender].activeX6Levels[level], "level already activated"); 

            if (users[msg.sender].x6Matrix[level-1].blocked) {
                users[msg.sender].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(msg.sender, level);
            
            users[msg.sender].activeX6Levels[level] = true;
            updateX6Referrer(msg.sender, freeX6Referrer, level);
            
            emit Upgrade(msg.sender, freeX6Referrer, 2, level, now);
        } 
        else {
            
            require(!users[msg.sender].activeX30Levels[level], "level already activated"); 

            if (users[msg.sender].x30Matrix[level-1].blocked) {
                users[msg.sender].x30Matrix[level-1].blocked = false;
            }
            
            address ref = users[msg.sender].referrer;
            address freeX30Referrer = findFreeX30Referrer(ref, level);
            users[msg.sender].activeX30Levels[level] = true;
            updateX30Referrer(msg.sender, freeX30Referrer, level);
            emit Upgrade(msg.sender, freeX30Referrer, 3, level, now);
            
        }
        
    }    
    
    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == levelPrice[1] * 3 , "insufficient balance"); // Price of X3, X4 and X30 
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
        users[userAddress].activeX3Levels[1] = true; 
        users[userAddress].activeX6Levels[1] = true;
        users[userAddress].activeX30Levels[1] = true;
        lastUserId++;
        users[referrerAddress].partnersCount++;

        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateX3Referrer(userAddress, freeX3Referrer, 1);
        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1);
        updateX30Referrer(userAddress, referrerAddress, 1);
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id, now);
    }
    
    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length), now);
            return sendTrxDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3, now);
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
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level, now);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendTrxDividends(owner, userAddress, 1, level);
            users[owner].x3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level, now);
        }
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length), now);
            
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendTrxDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].x6Matrix[level].currentReferrer;            
            users[ref].x6Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].x6Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5, now);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6, now);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3, now);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4, now);
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5, now);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6, now);
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
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length), now);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length), now);
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length), now);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length), now);
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            return sendTrxDividends(referrerAddress, userAddress, 2, level);
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

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level, now);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level, now);
            sendTrxDividends(owner, userAddress, 2, level);
        }
    }
    
    function updateX30Referrer(address userAddress, address referrerAddress, uint8 level) private {
        
        address firstLine;
        address secondLine;
        address thirdLine;
        address fourthLine;
        
        if(users[referrerAddress].x30Matrix[level].firstLevelReferrals.length < 2) {
            firstLine = _findX30Referrer(1,level,referrerAddress);
            secondLine = users[firstLine].x30Matrix[level].currentReferrer;
            thirdLine = users[secondLine].x30Matrix[level].currentReferrer;
            fourthLine = users[thirdLine].x30Matrix[level].currentReferrer;
        }
        
        else if(users[referrerAddress].x30Matrix[level].secondLevelReferrals.length < 4) {
            firstLine = _findX30Referrer(2, level, referrerAddress);
            secondLine = users[firstLine].x30Matrix[level].currentReferrer;
            thirdLine = users[secondLine].x30Matrix[level].currentReferrer;
            fourthLine = users[thirdLine].x30Matrix[level].currentReferrer;
        }
        
        else if(users[referrerAddress].x30Matrix[level].thirdLevelReferrals.length < 8) {
            firstLine = _findX30Referrer(3, level, referrerAddress);
            secondLine = users[firstLine].x30Matrix[level].currentReferrer;
            thirdLine = users[secondLine].x30Matrix[level].currentReferrer;
            fourthLine = users[thirdLine].x30Matrix[level].currentReferrer;
        }
        
        else if(users[referrerAddress].x30Matrix[level].fourthLevelReferrals.length < 16) {
            firstLine = _findX30Referrer(4, level, referrerAddress);
            secondLine = users[firstLine].x30Matrix[level].currentReferrer;
            thirdLine = users[secondLine].x30Matrix[level].currentReferrer;
            fourthLine = users[thirdLine].x30Matrix[level].currentReferrer;
        }
        
        if(firstLine != address(0)) {
            users[firstLine].x30Matrix[level].firstLevelReferrals.push(userAddress);
            users[userAddress].x30Matrix[level].currentReferrer = firstLine;
            emit NewUserPlace(userAddress, firstLine, 3, level, uint8(users[firstLine].x30Matrix[level].firstLevelReferrals.length), now);
        }
            
        if(secondLine != address(0)) {
            users[secondLine].x30Matrix[level].secondLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, secondLine, 3, level, uint8(users[secondLine].x30Matrix[level].secondLevelReferrals.length + 2), now);
        }
            
        
        if(thirdLine != address(0)) {
            users[thirdLine].x30Matrix[level].thirdLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, thirdLine, 3, level, uint8(users[thirdLine].x30Matrix[level].thirdLevelReferrals.length + 6), now);
        }
            
        if(fourthLine != address(0)) {
            users[fourthLine].x30Matrix[level].fourthLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, fourthLine, 3, level, uint8(users[fourthLine].x30Matrix[level].fourthLevelReferrals.length + 14), now);
        }
            
        
        if(users[fourthLine].x30Matrix[level].fourthLevelReferrals.length <= 14) {
            
            _payForX30(1, userAddress, level, levelPrice[level]);
            
        }
        
        else if(users[fourthLine].x30Matrix[level].fourthLevelReferrals.length == 15 ||
            users[fourthLine].x30Matrix[level].fourthLevelReferrals.length == 16) { 
                
            _payForX30(2, userAddress, level, levelPrice[level]);
            
        }
        
    }
    
    function _findX30Referrer(uint _flag,uint8 _level,  address _refAddress) internal view returns(address) {
        
        if(_flag == 1) {
            
            if(users[_refAddress].x30Matrix[_level].firstLevelReferrals.length < 2) {
                _refAddress = findFreeX30Referrer(_refAddress,_level);
                return _refAddress;
            }
               
        }
        
        else if(_flag == 2) { 
            if(users[_refAddress].x30Matrix[_level].firstLevelReferrals.length == 2) {
            
                address[] memory referrals = new address[](2);
                referrals[0] = users[_refAddress].x30Matrix[_level].firstLevelReferrals[0];
                referrals[1] = users[_refAddress].x30Matrix[_level].firstLevelReferrals[1];
                
                for(uint8 r=0; r<2; r++) {
                    if(users[referrals[r]].x30Matrix[_level].firstLevelReferrals.length < 2) 
                        return (referrals[r]);
                }
            }
        }
        
        else if(_flag == 3) { 
            if(users[_refAddress].x30Matrix[_level].firstLevelReferrals.length == 2 && 
                users[_refAddress].x30Matrix[_level].secondLevelReferrals.length == 4) {
            
                address[] memory referrals = new address[](4);
                referrals[0] = users[_refAddress].x30Matrix[_level].secondLevelReferrals[0];
                referrals[1] = users[_refAddress].x30Matrix[_level].secondLevelReferrals[1];
                referrals[2] = users[_refAddress].x30Matrix[_level].secondLevelReferrals[2];
                referrals[3] = users[_refAddress].x30Matrix[_level].secondLevelReferrals[3];
                
                for(uint8 r=0; r<4; r++) {
                    if(users[referrals[r]].x30Matrix[_level].firstLevelReferrals.length < 2) 
                        return (referrals[r]);
                }
            }
            
        }
        
        else if(_flag == 4) { 
            if(users[_refAddress].x30Matrix[_level].firstLevelReferrals.length == 2 && 
                users[_refAddress].x30Matrix[_level].secondLevelReferrals.length == 4 && 
                users[_refAddress].x30Matrix[_level].thirdLevelReferrals.length == 8) {
            
                address[] memory referrals = new address[](8);
                referrals[0] = users[_refAddress].x30Matrix[_level].thirdLevelReferrals[0];
                referrals[1] = users[_refAddress].x30Matrix[_level].thirdLevelReferrals[1];
                referrals[2] = users[_refAddress].x30Matrix[_level].thirdLevelReferrals[2];
                referrals[3] = users[_refAddress].x30Matrix[_level].thirdLevelReferrals[3];
                referrals[4] = users[_refAddress].x30Matrix[_level].thirdLevelReferrals[4];
                referrals[5] = users[_refAddress].x30Matrix[_level].thirdLevelReferrals[5];
                referrals[6] = users[_refAddress].x30Matrix[_level].thirdLevelReferrals[6];
                referrals[7] = users[_refAddress].x30Matrix[_level].thirdLevelReferrals[7];
                
                for(uint8 r=0; r<8; r++) {
                    if(users[referrals[r]].x30Matrix[_level].firstLevelReferrals.length < 2) 
                        return (referrals[r]);
                }
            }
            
        }
        
    }  
    
    function _paymentX30(address _referrerAddress, address _userAddress, uint8 _level, uint _share, uint _adminFee) internal {
        
         (address receiver1, bool isExtraDividends1) = findTrxReceiver(_referrerAddress, _userAddress, 3, _level);
        
        
        if(receiver1 == address(0)) 
            receiver1 = owner;
         
        require(address(uint160(receiver1)).send(_share) && address(uint160(commissionAddress)).send(_adminFee), "Transaction Failure  1");
        emit RecievedAdminCommission(_userAddress, _adminFee, 3, _level, now);
        
        if (isExtraDividends1) {
            emit SentExtraTrxDividends(_userAddress, receiver1, 3, _level, _share, now);
        }
        
        else 
            emit RecievedTrx(_userAddress, receiver1, 3, _level, _share, now); 
    }
    
    function _payForX30(uint _flag, address _userAddress, uint8 _level, uint _amount) internal {
        address[4] memory ref; 
        
        ref[3] = users[_userAddress].x30Matrix[_level].currentReferrer;
        ref[2] = users[ref[3]].x30Matrix[_level].currentReferrer;
        ref[1] = users[ref[2]].x30Matrix[_level].currentReferrer;
        ref[0] = users[ref[1]].x30Matrix[_level].currentReferrer;
        
        uint share;
        uint adminFees;
        uint balFees; 
        
        share = (_amount.mul(20 trx)).div(100 trx);
        adminFees = (share.mul( adminFee)).div(100 trx);
        balFees =  (share.sub(adminFees));
        
       _paymentX30(ref[2], _userAddress, _level, balFees , adminFees);
        
        
        share = (_amount.mul(30 trx)).div(100 trx);
        adminFees = (share.mul( adminFee)).div(100 trx);
        balFees =  (share.sub(adminFees));
        
        _paymentX30(ref[1], _userAddress, _level,  balFees , adminFees);
        

        if(_flag == 1) {
           
            share = (_amount.mul(50 trx)).div(100 trx);
            adminFees = (share.mul( adminFee)).div(100 trx);
            balFees =  (share.sub(adminFees));
                
            _paymentX30(ref[0], _userAddress, _level, balFees, adminFees);
            
        }
        
        
        if(_flag == 2) {
            
            uint share4 = (_amount.mul(50 trx)).div(100 trx);
            
            if(ref[0] == address(0)) 
                ref[0] = owner;
                
                
            users[ref[0]].x30Matrix[_level].availReInvestBalance = users[ref[0]].x30Matrix[_level].availReInvestBalance.add(share4);
            
            
            if(ref[0] == owner) {
                 require(address(uint160(ref[0])).send(share4), "Transaction Failure  1");
                 emit RecievedTrx(_userAddress, ref[0], 3, _level, share4, now);
            }
                
                    
            if(users[ref[0]].x30Matrix[_level].availReInvestBalance == levelPrice[_level]) {
                    
                if(ref[0] != owner){
                    
                    address reInvestRef = users[ref[0]].x30Matrix[_level].currentReferrer;
                    
                    updateX30Referrer(ref[0],findFreeX30Referrer(reInvestRef, _level),_level);
                }
                    
                users[ref[0]].x30Matrix[_level].reinvestCount  = users[ref[0]].x30Matrix[_level].reinvestCount.add(1);
                
                users[ref[0]].x30Matrix[_level].availReInvestBalance  = 0;
                
                emit Reinvest(ref[0], users[ref[0]].x30Matrix[_level].currentReferrer, _userAddress, 3, _level, now);
                
                users[ref[0]].x30Matrix[_level].firstLevelReferrals = new address[](0);
                users[ref[0]].x30Matrix[_level].secondLevelReferrals = new address[](0);
                users[ref[0]].x30Matrix[_level].thirdLevelReferrals = new address[](0);
                users[ref[0]].x30Matrix[_level].fourthLevelReferrals = new address[](0);
                
                if(users[ref[0]].activeX30Levels[_level+1] == false) {
                    users[ref[0]].x30Matrix[_level].blocked = true;
                }
            
            }
            
        }
        
        if(lastUserId < tokenDistLimit)
            require(Token.mint(msg.sender,levelTokens[_level]), "Token Transaction Failure  2");
        
        
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
    
    function findFreeX30Referrer(address referrerAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[referrerAddress].activeX30Levels[level]) {
                return referrerAddress;
            }
            
            referrerAddress = users[referrerAddress].referrer;
        }
    }
        
    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }
    
    function updateLevelPrice(uint8 level, uint price) public returns(bool) {
        require(msg.sender == owner, "Only Owner");
        levelPrice[level] = price;
        return true;
    }
    
    function updateTokenLimit(uint _IDLimit) public returns(bool) {
        require(msg.sender == owner, "Only Owner");
        tokenDistLimit = _IDLimit;
        return true;
    }
    
    function updateTokenPerTrx(uint _tokenPerTrx) public returns(bool) { // input with decimal (**18)
         require(msg.sender == owner, "Only Owner");
         tokenPerTrx = _tokenPerTrx;
         return true;
    }
    
    function updateLevelTokenPrice(uint8 level, uint price) public returns(bool) {
        require(msg.sender == owner, "Only Owner");
        levelTokens[level] = price;
        return true;
    }
    
    
     function updateCommissionAddress(address _commissionAddress) public returns(bool) {
        require(msg.sender == owner, "Only Owner");
        commissionAddress = _commissionAddress;
        return true;
    }

     
    function updateFeePercentage(uint _fee) public returns(bool) { // input with 									decimal (**6)
         require(msg.sender == owner, "Only Owner");
         adminFee = _fee;
         return true;
    }



    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }
    
    function usersActiveX30Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX30Levels[level];
    }

    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory,bool) {
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
    
    function usersX30Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, address[] memory, address[] memory, bool) {
        return (users[userAddress].x30Matrix[level].currentReferrer,
                users[userAddress].x30Matrix[level].firstLevelReferrals,
                users[userAddress].x30Matrix[level].secondLevelReferrals,
                users[userAddress].x30Matrix[level].thirdLevelReferrals,
                users[userAddress].x30Matrix[level].fourthLevelReferrals,
                users[userAddress].x30Matrix[level].blocked);
    }
    
    function reinvestcount(address userAddress,uint8 matrix,uint8 level)public view returns(uint){
        if(matrix == 1)
            return users[userAddress].x3Matrix[level].reinvestCount;
        else if(matrix == 2)
          return users[userAddress].x6Matrix[level].reinvestCount;
        else if(matrix == 3)
           return users[userAddress].x30Matrix[level].reinvestCount;
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findTrxReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].x3Matrix[level].blocked) {
                    emit MissedTrxReceive(receiver, _from, 1, level, now);
                    isExtraDividends = true;
                    receiver = users[receiver].x3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
        else if(matrix == 2) {
            while (true) {
                if (users[receiver].x6Matrix[level].blocked) {
                    emit MissedTrxReceive(receiver, _from, 2, level,  now);
                    isExtraDividends = true;
                    receiver = users[receiver].x6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
        else {
            while (true) {
                if (users[receiver].x30Matrix[level].blocked) {
                    emit MissedTrxReceive(receiver, _from, 3, level, now);
                    isExtraDividends = true;
                    receiver = users[receiver].x30Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    } 

	function failSafe(address payable _toUser, uint _amount) onlyOwner external returns (bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");
        (_toUser).transfer(_amount);
        return true;
   	 } 
   
	function contractLock(bool _lockStatus) onlyOwner external returns (bool) {
     	 lockStatus = _lockStatus;
    	return true;
	} 
	
    function sendTrxDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findTrxReceiver(userAddress, _from, matrix, level);
        
        uint adminFees = (levelPrice[level].mul(adminFee)).div(100 trx);
        uint balFee = levelPrice[level].sub(adminFees);
        
        require(address(uint160(receiver)).send(balFee) && address(uint160(commissionAddress)).send(adminFees), "Transaction Failure 0");
        emit RecievedAdminCommission(userAddress, adminFee, matrix, level, now);
        
        if(lastUserId < tokenDistLimit) 
            require(Token.mint(msg.sender, levelTokens[level]), "Token Transaction Failure 1");
        
        
        if (isExtraDividends) {
            emit SentExtraTrxDividends(_from, receiver, matrix, level, balFee, now);
        }
        
        else {
            emit RecievedTrx(_from, receiver, matrix, level, balFee, now);
        }
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}