//SourceUnit: tronsmart.sol

 /*

████████╗██████╗  ██████╗ ███╗   ██╗███████╗███╗   ███╗ █████╗ ██████╗ ████████╗
╚══██╔══╝██╔══██╗██╔═══██╗████╗  ██║██╔════╝████╗ ████║██╔══██╗██╔══██╗╚══██╔══╝
   ██║   ██████╔╝██║   ██║██╔██╗ ██║███████╗██╔████╔██║███████║██████╔╝   ██║   
   ██║   ██╔══██╗██║   ██║██║╚██╗██║╚════██║██║╚██╔╝██║██╔══██║██╔══██╗   ██║   
   ██║   ██║  ██║╚██████╔╝██║ ╚████║███████║██║ ╚═╝ ██║██║  ██║██║  ██║   ██║   
   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   
                                                                                
www.tronsmart.io
*/
 

pragma solidity >=0.4.23 <0.6.0;



contract TronSmart {

    

    struct User {

        uint id;

        address referrer;

        uint partnersCount;

        uint X3MaxLevel;

        uint X6MaxLevel;

        uint X3Income;
        uint X3X6Income;
        uint X3reinvestCount;
        uint X6reinvestCount;
        bool incomeBonusEarned;
        uint X6Income; 
        uint x3x6reinvestCount;

        

        mapping(uint8 => bool) activeX3Levels;

        mapping(uint8 => bool) activeX6Levels;

        

        mapping(uint8 => X3) X3Matrix;

        mapping(uint8 => X6) X6Matrix;

    }

    

    struct X3 {

        address currentReferrer;

        address[] referrals;

        bool blocked;

        uint reinvestCount;
        
        uint directSales;

    }

    

    struct X6 {

        address currentReferrer;

        address[] firstLevelReferrals;

        address[] secondLevelReferrals;

        bool blocked;

        uint reinvestCount;
        
        uint directSales;

        address closedPart;

    }



    uint8 public constant LAST_LEVEL = 12;

    

    mapping(address => User) public users;

    mapping(uint => address) public idToAddress;

    mapping(uint => address) public userIds;

    mapping(address => uint) public balances; 



    uint public lastUserId = 2;

    uint public totalearnedtrx = 0 trx;

    address public owner;

    

    mapping(uint8 => uint) public levelPrice;

    

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);

    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);

    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);

    event CyclesReachedForBonus(address indexed user);

    event IncomeReachedForBonus(address indexed user);

    event LevelReachedForBonus(address indexed user);

    event NewUserPlace(address indexed user,uint indexed userId, address indexed referrer,uint referrerId, uint8 matrix, uint8 level, uint8 place);

    event MissedTronReceive(address indexed receiver,uint receiverId, address indexed from,uint indexed fromId, uint8 matrix, uint8 level);

    event SentDividends(address indexed from,uint indexed fromId, address indexed receiver,uint receiverId, uint8 matrix, uint8 level, bool isExtra);

    

    constructor(address ownerAddress) public {

        levelPrice[1] = 50 trx;

        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }

        

        owner = ownerAddress;

        

        User memory user = User({

            id: 1,

            referrer: address(0),

            partnersCount: uint(0),

            X3MaxLevel:uint(0),

            X6MaxLevel:uint(0),

            X3Income:uint8(0),
            X3reinvestCount:uint(0),
            X6reinvestCount:uint(0),
            X3X6Income:uint8(0),
            incomeBonusEarned:false,
            X6Income:uint8(0),
            x3x6reinvestCount:uint8(0)

        });

        

        users[ownerAddress] = user;

        idToAddress[1] = ownerAddress;

        

        for (uint8 i = 1; i <= LAST_LEVEL; i++) {

            users[ownerAddress].activeX3Levels[i] = true;

            users[ownerAddress].activeX6Levels[i] = true;

        }

        users[ownerAddress].X3MaxLevel = 12;

        users[ownerAddress].X6MaxLevel = 12;

        userIds[1] = ownerAddress;

    }

    

    function() external payable {

        if(msg.data.length == 0) {

            return registration(msg.sender, owner);

        }

        

        registration(msg.sender, bytesToAddress(msg.data));

    }

function withdrawLostTRXFromBalance() public 
{
require(msg.sender == owner, "onlyOwner"); 
address(uint160(owner)).transfer(address(this).balance);
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

            require(!users[msg.sender].activeX3Levels[level], "level already activated");

            require(users[msg.sender].activeX3Levels[level - 1], "previous level should be activated");



            if (users[msg.sender].X3Matrix[level-1].blocked) {

                users[msg.sender].X3Matrix[level-1].blocked = false;

            }

    

            address freeX3Referrer = findFreeX3Referrer(msg.sender, level);

            users[msg.sender].X3MaxLevel = level;

            users[msg.sender].X3Matrix[level].currentReferrer = freeX3Referrer;

            users[msg.sender].activeX3Levels[level] = true;

            updateX3Referrer(msg.sender, freeX3Referrer, level);

             totalearnedtrx = totalearnedtrx+levelPrice[level];

            emit Upgrade(msg.sender, freeX3Referrer, 1, level);
            if(level == 12){
                emit LevelReachedForBonus(msg.sender);
            }

        } else {

            require(!users[msg.sender].activeX6Levels[level], "level already activated"); 

            require(users[msg.sender].activeX6Levels[level - 1], "previous level should be activated"); 



            if (users[msg.sender].X6Matrix[level-1].blocked) {

                users[msg.sender].X6Matrix[level-1].blocked = false;

            }



            address freeX6Referrer = findFreeX6Referrer(msg.sender, level);

            users[msg.sender].X6MaxLevel = level;

            users[msg.sender].activeX6Levels[level] = true;

            updateX6Referrer(msg.sender, freeX6Referrer, level);

            

        

          totalearnedtrx = totalearnedtrx+levelPrice[level];

            emit Upgrade(msg.sender, freeX6Referrer, 2, level);
            
            if(level == 12){
                emit LevelReachedForBonus(msg.sender);
            }

        }

    }    

    

    function registration(address userAddress, address referrerAddress) private {

        require(msg.value == 100 trx, "registration cost 100");

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

            X3MaxLevel:1,

            X6MaxLevel:1,

            X3Income:0 trx,
            X3reinvestCount:0,
            X6reinvestCount:0,
            X3X6Income:0 trx,
            X6Income:0 trx,
            incomeBonusEarned: false,
            x3x6reinvestCount:0

        });

        

        users[userAddress] = user;

        idToAddress[lastUserId] = userAddress;

        

        users[userAddress].referrer = referrerAddress;

        

        users[userAddress].activeX3Levels[1] = true; 

        users[userAddress].activeX6Levels[1] = true;

        

        

        userIds[lastUserId] = userAddress;

        lastUserId++;

         totalearnedtrx = totalearnedtrx+100 trx;

        users[referrerAddress].partnersCount++;



        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);

        users[userAddress].X3Matrix[1].currentReferrer = freeX3Referrer;

        updateX3Referrer(userAddress, freeX3Referrer, 1);



        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1);

        

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);

    }

    

    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {

        users[referrerAddress].X3Matrix[level].referrals.push(userAddress);



        if (users[referrerAddress].X3Matrix[level].referrals.length < 3) {

            emit NewUserPlace(userAddress,users[userAddress].id, referrerAddress, users[referrerAddress].id, 1, level, uint8(users[referrerAddress].X3Matrix[level].referrals.length));
            users[referrerAddress].X3Matrix[level].directSales++;
            return sendTronDividends(referrerAddress, userAddress, 1, level);

        }

        

        emit NewUserPlace(userAddress,users[userAddress].id, referrerAddress,users[referrerAddress].id, 1, level, 3);
        users[referrerAddress].X3Matrix[level].directSales++;
        
        //close matrix

        users[referrerAddress].X3Matrix[level].referrals = new address[](0);

        if (!users[referrerAddress].activeX3Levels[level+1] && level != LAST_LEVEL) {

            users[referrerAddress].X3Matrix[level].blocked = true;

        }



        //create new one by recursion

        if (referrerAddress != owner) {

            //check referrer active level

            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level);

            if (users[referrerAddress].X3Matrix[level].currentReferrer != freeReferrerAddress) {

                users[referrerAddress].X3Matrix[level].currentReferrer = freeReferrerAddress;

            }

            

            users[referrerAddress].X3Matrix[level].reinvestCount++;
            users[referrerAddress].X3reinvestCount++;
            users[referrerAddress].x3x6reinvestCount++;
            

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);

            updateX3Referrer(referrerAddress, freeReferrerAddress, level);

        } else {

            sendTronDividends(owner, userAddress, 1, level);

            users[owner].X3Matrix[level].reinvestCount++;
            users[referrerAddress].X3reinvestCount++;
            users[referrerAddress].x3x6reinvestCount++;

            emit Reinvest(owner, address(0), userAddress, 1, level);

        }
        if(users[referrerAddress].X3reinvestCount >= 50 && users[referrerAddress].X3reinvestCount <= 60){
            emit CyclesReachedForBonus(referrerAddress);
        }

    }



    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {

        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");

        

        if (users[referrerAddress].X6Matrix[level].firstLevelReferrals.length < 2) {

            users[referrerAddress].X6Matrix[level].firstLevelReferrals.push(userAddress);

            emit NewUserPlace(userAddress,users[userAddress].id, referrerAddress,users[referrerAddress].id, 2, level, uint8(users[referrerAddress].X6Matrix[level].firstLevelReferrals.length));
             users[referrerAddress].X6Matrix[level].directSales++;
            

            //set current level

            users[userAddress].X6Matrix[level].currentReferrer = referrerAddress;



            if (referrerAddress == owner) {

                return sendTronDividends(referrerAddress, userAddress, 2, level);

            }

            

            address ref = users[referrerAddress].X6Matrix[level].currentReferrer;            

            users[ref].X6Matrix[level].secondLevelReferrals.push(userAddress); 

            

            uint len = users[ref].X6Matrix[level].firstLevelReferrals.length;

            

            if ((len == 2) && 

                (users[ref].X6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&

                (users[ref].X6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {

                if (users[referrerAddress].X6Matrix[level].firstLevelReferrals.length == 1) {

                    emit NewUserPlace(userAddress,users[userAddress].id, ref,users[ref].id, 2, level, 5);
                     users[ref].X6Matrix[level].directSales++;

                } else {

                    emit NewUserPlace(userAddress,users[userAddress].id,ref,users[ref].id, 2, level, 6);
                     users[ref].X6Matrix[level].directSales++;

                }

            }  else if ((len == 1 || len == 2) &&

                    users[ref].X6Matrix[level].firstLevelReferrals[0] == referrerAddress) {

                if (users[referrerAddress].X6Matrix[level].firstLevelReferrals.length == 1) {

                    emit NewUserPlace(userAddress,users[userAddress].id, ref,users[ref].id, 2, level, 3);
                     users[ref].X6Matrix[level].directSales++;

                } else {

                    emit NewUserPlace(userAddress,users[userAddress].id, ref,users[ref].id, 2, level, 4);
                    users[ref].X6Matrix[level].directSales++;
                }

            } else if (len == 2 && users[ref].X6Matrix[level].firstLevelReferrals[1] == referrerAddress) {

                if (users[referrerAddress].X6Matrix[level].firstLevelReferrals.length == 1) {

                    emit NewUserPlace(userAddress,users[userAddress].id, ref,users[ref].id, 2, level, 5);
                     users[ref].X6Matrix[level].directSales++;

                } else {

                    emit NewUserPlace(userAddress,users[userAddress].id, ref,users[ref].id, 2, level, 6);
                    users[ref].X6Matrix[level].directSales++;
                }

            }
            


            return updateX6ReferrerSecondLevel(userAddress, ref, level);

        }

        

        users[referrerAddress].X6Matrix[level].secondLevelReferrals.push(userAddress);



        if (users[referrerAddress].X6Matrix[level].closedPart != address(0)) {

            if ((users[referrerAddress].X6Matrix[level].firstLevelReferrals[0] == 

                users[referrerAddress].X6Matrix[level].firstLevelReferrals[1]) &&

                (users[referrerAddress].X6Matrix[level].firstLevelReferrals[0] ==

                users[referrerAddress].X6Matrix[level].closedPart)) {



                updateX6(userAddress, referrerAddress, level, true);

                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);

            } else if (users[referrerAddress].X6Matrix[level].firstLevelReferrals[0] == 

                users[referrerAddress].X6Matrix[level].closedPart) {

                updateX6(userAddress, referrerAddress, level, true);

                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);

            } else {

                updateX6(userAddress, referrerAddress, level, false);

                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);

            }

        }



        if (users[referrerAddress].X6Matrix[level].firstLevelReferrals[1] == userAddress) {

            updateX6(userAddress, referrerAddress, level, false);

            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);

        } else if (users[referrerAddress].X6Matrix[level].firstLevelReferrals[0] == userAddress) {

            updateX6(userAddress, referrerAddress, level, true);

            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);

        }

        

        if (users[users[referrerAddress].X6Matrix[level].firstLevelReferrals[0]].X6Matrix[level].firstLevelReferrals.length <= 

            users[users[referrerAddress].X6Matrix[level].firstLevelReferrals[1]].X6Matrix[level].firstLevelReferrals.length) {

            updateX6(userAddress, referrerAddress, level, false);

        } else {

            updateX6(userAddress, referrerAddress, level, true);

        }

        

        updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);

    }



    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {

        if (!x2) {

            users[users[referrerAddress].X6Matrix[level].firstLevelReferrals[0]].X6Matrix[level].firstLevelReferrals.push(userAddress);

            emit NewUserPlace(userAddress,users[userAddress].id, users[referrerAddress].X6Matrix[level].firstLevelReferrals[0],users[users[referrerAddress].X6Matrix[level].firstLevelReferrals[0]].id, 2, level, uint8(users[users[referrerAddress].X6Matrix[level].firstLevelReferrals[0]].X6Matrix[level].firstLevelReferrals.length));
             users[users[referrerAddress].X6Matrix[level].firstLevelReferrals[0]].X6Matrix[level].directSales++;
            emit NewUserPlace(userAddress,users[userAddress].id, referrerAddress,users[referrerAddress].id, 2, level, 2 + uint8(users[users[referrerAddress].X6Matrix[level].firstLevelReferrals[0]].X6Matrix[level].firstLevelReferrals.length));
            users[referrerAddress].X6Matrix[level].directSales++;
            //set current level

            users[userAddress].X6Matrix[level].currentReferrer = users[referrerAddress].X6Matrix[level].firstLevelReferrals[0];

        } else {

            users[users[referrerAddress].X6Matrix[level].firstLevelReferrals[1]].X6Matrix[level].firstLevelReferrals.push(userAddress);

            emit NewUserPlace(userAddress,users[userAddress].id, users[referrerAddress].X6Matrix[level].firstLevelReferrals[1],users[users[referrerAddress].X6Matrix[level].firstLevelReferrals[1]].id, 2, level, uint8(users[users[referrerAddress].X6Matrix[level].firstLevelReferrals[1]].X6Matrix[level].firstLevelReferrals.length));
            users[users[referrerAddress].X6Matrix[level].firstLevelReferrals[1]].X6Matrix[level].directSales++;
            emit NewUserPlace(userAddress,users[userAddress].id, referrerAddress,users[referrerAddress].id, 2, level, 4 + uint8(users[users[referrerAddress].X6Matrix[level].firstLevelReferrals[1]].X6Matrix[level].firstLevelReferrals.length));
            users[referrerAddress].X6Matrix[level].directSales++;
            //set current level

            users[userAddress].X6Matrix[level].currentReferrer = users[referrerAddress].X6Matrix[level].firstLevelReferrals[1];

        }

    }

    

    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {

        if (users[referrerAddress].X6Matrix[level].secondLevelReferrals.length < 4) {

            return sendTronDividends(referrerAddress, userAddress, 2, level);

        }

        

        address[] memory X6 = users[users[referrerAddress].X6Matrix[level].currentReferrer].X6Matrix[level].firstLevelReferrals;

        

        if (X6.length == 2) {

            if (X6[0] == referrerAddress ||

                X6[1] == referrerAddress) {

                users[users[referrerAddress].X6Matrix[level].currentReferrer].X6Matrix[level].closedPart = referrerAddress;

            } else if (X6.length == 1) {

                if (X6[0] == referrerAddress) {

                    users[users[referrerAddress].X6Matrix[level].currentReferrer].X6Matrix[level].closedPart = referrerAddress;

                }

            }

        }

        

        users[referrerAddress].X6Matrix[level].firstLevelReferrals = new address[](0);

        users[referrerAddress].X6Matrix[level].secondLevelReferrals = new address[](0);

        users[referrerAddress].X6Matrix[level].closedPart = address(0);



        if (!users[referrerAddress].activeX6Levels[level+1] && level != LAST_LEVEL) {

            users[referrerAddress].X6Matrix[level].blocked = true;

        }



        users[referrerAddress].X6Matrix[level].reinvestCount++;
        users[referrerAddress].X6reinvestCount++;
            users[referrerAddress].x3x6reinvestCount++;
        

        if (referrerAddress != owner) {

            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);



            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);

            updateX6Referrer(referrerAddress, freeReferrerAddress, level);

        } else {

            emit Reinvest(owner, address(0), userAddress, 2, level);

            sendTronDividends(owner, userAddress, 2, level);

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



    function get3XMatrix(address userAddress, uint8 level) public view returns(address, address[] memory, uint, uint, bool) {

        return (users[userAddress].X3Matrix[level].currentReferrer,

                users[userAddress].X3Matrix[level].referrals,

                users[userAddress].X3Matrix[level].reinvestCount,
                
                users[userAddress].X3Matrix[level].directSales,

                users[userAddress].X3Matrix[level].blocked);

    }



    function getX6Matrix(address userAddress, uint8 level) public view returns(address[] memory, address[] memory, bool, uint, uint, address) {

        return (users[userAddress].X6Matrix[level].firstLevelReferrals,

                users[userAddress].X6Matrix[level].secondLevelReferrals,

                users[userAddress].X6Matrix[level].blocked,
                
                users[userAddress].X6Matrix[level].directSales,
                
                users[userAddress].X6Matrix[level].reinvestCount,

                users[userAddress].X6Matrix[level].closedPart);

    }

    

    function isUserExists(address user) public view returns (bool) {

        return (users[user].id != 0);

    }



    function findTronReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {

        address receiver = userAddress;

        bool isExtraDividends;

        if (matrix == 1) {

            while (true) {

                if (users[receiver].X3Matrix[level].blocked) {

                    emit MissedTronReceive(receiver,users[receiver].id, _from,users[_from].id, 1, level);

                    isExtraDividends = true;

                    receiver = users[receiver].X3Matrix[level].currentReferrer;

                } else {

                    return (receiver, isExtraDividends);

                }

            }

        } else {

            while (true) {

                if (users[receiver].X6Matrix[level].blocked) {

                    emit MissedTronReceive(receiver,users[receiver].id, _from,users[_from].id, 2, level);

                    isExtraDividends = true;

                    receiver = users[receiver].X6Matrix[level].currentReferrer;

                } else {

                    return (receiver, isExtraDividends);

                }

            }

        }

    }



    function sendTronDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {

        (address receiver, bool isExtraDividends) = findTronReceiver(userAddress, _from, matrix, level);



if(matrix==1)

{    

           

        users[userAddress].X3Income +=levelPrice[level] ;
        
        users[userAddress].X3X6Income += levelPrice[level];

}

else if(matrix==2)

{

 

        users[userAddress].X6Income +=levelPrice[level] ; 
        
        users[userAddress].X3X6Income += levelPrice[level];

}
if(users[userAddress].X3X6Income >= 250000 trx){
    if(!users[userAddress].incomeBonusEarned){
        emit IncomeReachedForBonus(userAddress);
        users[userAddress].incomeBonusEarned = true;
    }
    
}


        if (!address(uint160(receiver)).send(levelPrice[level])) {

            return address(uint160(receiver)).transfer(address(this).balance);

        }

       

        emit SentDividends(_from,users[_from].id, receiver,users[receiver].id, matrix, level, isExtraDividends);

    }

    

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {

        assembly {

            addr := mload(add(bys, 20))

        }

    }

    function safeWithdraw(uint _amount) external {
        require(msg.sender==owner,'Permission denied');
        if (_amount > 0) {
            uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint amtToTransfer = _amount > contractBalance ? contractBalance : _amount;
                msg.sender.transfer(amtToTransfer);
            }
        }
    }

}