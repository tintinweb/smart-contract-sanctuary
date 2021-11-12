// SPDX-License-Identifier: MIT
/*
http://kangoo.group/
*/
pragma solidity 0.7.6;

import "./lib/IBEP20.sol";
import "./lib/SafeMath.sol";
import "./lib/TransferHelper.sol";
import "./KangarooStake.sol";
import "./KangarooToken.sol";
import "./lib/IPancakeRouter02.sol";
import './lib/IPancakeFactory.sol';
import './lib/IPancakePair.sol';

pragma experimental ABIEncoderV2;

contract KangarooMatrix {


    using SafeMath for uint256;
    using TransferHelper for IBEP20;
    
    struct User {
        uint32 referrerID;
        uint32 partnersCount;
        
        uint8 activeX3Levels;
        uint8 activeX6Levels;
        uint8 maxAvailableLevel;
        address userAddress;
        uint256 lastActivity;
        bool refBlocked;
       
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;
    }
    
    struct StaticUser {
        uint32 referrerID;
        uint32 partnersCount;
        
        uint8 activeX3Levels;
        uint8 activeX6Levels;
        uint8 maxAvailableLevel;
        address userAddress;
        uint256 lastActivity;
        bool refBlocked;
    }


    struct X3 {
        bool blocked;
        uint32 currentReferrerID;
        uint32[] referralsID; 
        uint32 reinvestCount;
    }
    
    struct X6 {
        bool blocked;
        uint32 currentReferrerID;
        uint32[] firstLevelReferralsID;
        uint32[] secondLevelReferralsID;
        uint32 reinvestCount;

        uint32 closedPart;
    }

    struct X6_2 {
        uint32 currentReferrerID;
        uint32[] firstLevelReferralsID;
        uint32[] secondLevelReferralsID;
        bool blocked;
        uint32 closedPart;
        uint32 reinvestCount;
    }

    struct MaxL{
        address user;
        uint8 level;
    }
  
    
    mapping(uint32 => User) public users;
    mapping(address => uint32) public AddressToId;

    uint32 public lastUserId = 2;
    address immutable public matrixesRoot;
    address immutable public distrContrAddress;
    address public levelsAdmin;
    bool public openSalePeriod=false;
    
    KangarooStake immutable public stakePool;
    IBEP20 public matrixesToken;
    IBEP20 immutable public openSaleToken;
    IPancakePair immutable public pancakePair;
    uint8 public constant LAST_LEVEL = 21;
    uint256 public matrixesTokenRate=1e18;
    mapping(uint8 => uint256) public levelPrice;
    uint256 constant public startTimestamp =1633731502;
    uint256 immutable public periodDuration; //86400 * 30 = 2592000 seconds
    

    modifier onlyRoot() {
        require(msg.sender==matrixesRoot);
        _;
    }
    modifier onlyLevelsAdmin() {
        require(msg.sender==levelsAdmin);
        _;
    }

    event Registration(address user, address referrer, uint32 userId, uint32 referrerId,uint8 matrix);
    event Reinvest(uint32 userID, uint32 currentReferrerID, uint32 callerID, uint8 matrix, uint8 level);
    event Upgrade(uint32 userId, uint32 referrerId, uint8 matrix, uint8 level);
    event NewUserPlace(uint32 userId, uint32 referrerId, uint8 matrix, uint8 level, uint8 place);
    event MissedReceive(uint32 receiverID, uint32 fromID, uint8 matrix, uint8 level);
    event SentExtraDividends(uint32 fromID, uint32 receiverID, uint256 amount, uint8 matrix, uint8 level);
    event SentDividends(uint32 fromID, uint32 receiverID, uint256 amount, uint8 matrix, uint8 level);
    event OpenSale(address _matrixToken);
    event RefBlocked(uint32 userID,bool status);
    
    constructor(KangarooStake _stakePool,
                address _matrixesRoot,
                address _distrContrAddress,
                address _levelsAdmin,
                uint256 _periodDuration) {
        
        levelPrice[1]=15;
        levelPrice[2]=23;
        levelPrice[3]=34;
        levelPrice[4]=51;
        levelPrice[5]=76;
        levelPrice[6]=114;
        levelPrice[7]=171;
        levelPrice[8]=257;
        levelPrice[9]=385;
        levelPrice[10]=577;
        levelPrice[11]=865;
        levelPrice[12]=1300;
        levelPrice[13]=1950;
        levelPrice[14]=2920;
        levelPrice[15]=4380;
        levelPrice[16]=6570;
        levelPrice[17]=9855;
        levelPrice[18]=14780;
        levelPrice[19]=22170;
        levelPrice[20]=33255;
        levelPrice[21]=49880;

        periodDuration=_periodDuration;


        matrixesRoot = _matrixesRoot;
        openSaleToken=_stakePool.rooToken(); //IBEP20(_openSaleToken);
        matrixesToken=_stakePool.usdtToken(); //IBEP20(_matrixesToken);
        pancakePair=IPancakePair(_stakePool.PancakePairAddress());
        distrContrAddress=_distrContrAddress;
        stakePool=_stakePool;
        levelsAdmin=_levelsAdmin;

        users[1].activeX3Levels=LAST_LEVEL;
        users[1].activeX6Levels=LAST_LEVEL;
        users[1].userAddress=_matrixesRoot;
        AddressToId[_matrixesRoot]=1;

    }

    function setAdmin(address _levelsAdmin) external onlyRoot {
        levelsAdmin=_levelsAdmin;
    }

    function setRefBlocked(uint32 _userID,bool _status) external onlyLevelsAdmin {
        require(
            _userID>0 
            && isUserExists(users[_userID].userAddress), "user not exists"
        );
        users[_userID].refBlocked=_status;

        emit RefBlocked(_userID,_status);
    }

    function switchToOpenSale() external onlyRoot {   
        require(KangarooToken(address(openSaleToken)).startOpenSale(),"cant start OpenSale period");
        require(stakePool.startOpenSale(),"StakePool:cant start OpenSale period");
        matrixesToken=openSaleToken;
        openSalePeriod=true;
        emit OpenSale(address(openSaleToken));
    }


    function _updateMatrixesTokenRate() internal {
        
        if(openSalePeriod){
            (uint112 reserves0, uint112 reserves1,) = pancakePair.getReserves();
            (uint112 reserveIn, uint112 reserveOut) = pancakePair.token0() == address(openSaleToken) ? (reserves0, reserves1) : (reserves1, reserves0);
        
            if (reserveIn > 0 && reserveOut > 0 && 1e18 < reserveOut){
                uint256 numerator = uint256(1e18).mul(10000).mul(reserveIn);
                uint256 denominator = uint256(reserveOut).sub(1e18).mul(9975);
                matrixesTokenRate = numerator.div(denominator).add(1);
            }
        }

    }

    function setMaxLevel(MaxL[] calldata mlArray) external onlyLevelsAdmin {
        
        require(mlArray.length<11, "maximum mlArray size must be 10");

        for (uint256 i = 0; i < mlArray.length; i++) {
            uint8 level=mlArray[i].level;
            require(level > 6 && level <= LAST_LEVEL, "invalid level");
            uint32 userID=AddressToId[mlArray[i].user];
            require(userID>0, "user is not exists.");
            users[userID].maxAvailableLevel=level;
        }     
        
    }

    
    
    function buyNewLevel(uint8 matrix, uint8 level) external {

        uint32 userID=AddressToId[msg.sender];
        require(userID>0 && users[userID].activeX3Levels>=1 && users[userID].activeX6Levels>=1 , "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
        require(users[userID].maxAvailableLevel>=level,"this level not available");

        uint256 regPayAmount=getLevelPrice(level);
        require(
            matrixesToken.allowance(address(msg.sender), address(this)) >=
                regPayAmount,
            "Increase the allowance first,call the approve method"
        );

        matrixesToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            regPayAmount
        );


        if (matrix == 1) {
            require(users[userID].activeX3Levels == (level-1) 
            && users[userID].activeX6Levels == (level-1), "wrong next X3 level");
            

            if (users[userID].x3Matrix[level-1].blocked) {
                users[userID].x3Matrix[level-1].blocked = false;
            }
    
            uint32 freeX3ReferrerID = findFreeX3Referrer(userID, level);
            users[userID].x3Matrix[level].currentReferrerID = freeX3ReferrerID;
            users[userID].activeX3Levels = level;
            updateX3Referrer(userID, freeX3ReferrerID, level);
            
            emit Upgrade(userID, freeX3ReferrerID, matrix, level);

        } else {
            require(users[userID].activeX3Levels == level 
            && users[userID].activeX6Levels == (level-1), "wrong next X6 level"); 

            if (users[userID].x6Matrix[level-1].blocked) {
                users[userID].x6Matrix[level-1].blocked = false;
            }

            uint32 freeX6ReferrerID = findFreeX6Referrer(userID, level);
            
            users[userID].activeX6Levels = level;
            updateX6Referrer(userID, freeX6ReferrerID, level);
            
            emit Upgrade(userID, freeX6ReferrerID, matrix, level);
        }
        _updateMatrixesTokenRate();
    } 

    function getLevelPrice(uint8 level) public view returns(uint256) {
        
        if(level<1 || level > LAST_LEVEL){
            return 0;
        }
        return levelPrice[level].mul(matrixesTokenRate);
    }  
    
    function registrationX3(uint32 referrerID) external {
        address userAddress=msg.sender;
        require(!isUserExists(userAddress), "user already exists");
        require(
            referrerID>0 
            && isUserExists(users[referrerID].userAddress), "referrer not exists"
        );
        require(users[referrerID].refBlocked==false, "this referrer is blocked");
        require(
            users[referrerID].activeX6Levels>0, "referrer without X6 registration"
        );
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0 && userAddress == tx.origin, "cannot be a contract");

        uint256 regPayAmount=getLevelPrice(1);
              
        require(
            matrixesToken.allowance(address(userAddress), address(this)) >=
                regPayAmount,
            "Increase the allowance first,call the approve method"
        );

        matrixesToken.safeTransferFrom(
            userAddress,
            address(this),
            regPayAmount
        );


        uint32 userID=lastUserId;
        lastUserId++;       
        
        
        users[userID].referrerID=referrerID;
        users[userID].activeX3Levels=1;
        users[userID].userAddress=userAddress;
        users[userID].maxAvailableLevel=6;
        

        AddressToId[userAddress]=userID;
        users[userID].x3Matrix[1].currentReferrerID = referrerID;
        updateX3Referrer(userID, referrerID, 1);

        _updateMatrixesTokenRate();
       
        emit Registration(userAddress, users[referrerID].userAddress, userID, referrerID,1);
    }

    function registrationX6() external {

        uint32 userID=AddressToId[msg.sender];
        require(userID>0 && users[userID].activeX3Levels==1,"activate the X3 first");
        require(users[userID].activeX6Levels==0,"X6 already activated");
        
        uint256 regPayAmount=getLevelPrice(1);
              
        require(
            matrixesToken.allowance(address(msg.sender), address(this)) >=
                regPayAmount,
            "Increase the allowance first,call the approve method"
        );

        matrixesToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            regPayAmount
        );

        uint32 referrerID=users[userID].referrerID;
        uint256 lastActivity=getCurrentPeriod();
        users[userID].lastActivity=lastActivity;
        users[userID].activeX6Levels=1;
        users[referrerID].partnersCount++;
        users[referrerID].lastActivity=lastActivity;
        
        updateX6Referrer(userID, referrerID, 1);
        

        require(stakePool.createUser(msg.sender),"cant create User");
        _updateMatrixesTokenRate();
       
        emit Registration(msg.sender, users[referrerID].userAddress, userID, referrerID,2);
    }

    function migrationsMatrix6(address oldMatrix,uint32 id,uint8 level) public view returns(X6 memory) {
        X6_2 memory x6_2MATRIX;
        X6 memory MATRIX;
        bool success;
        bytes memory data;

        (success, data) = oldMatrix.staticcall(abi.encodeWithSignature("usersX6Matrix(uint32,uint8)",id,level));
        require(success && data.length != 0 ,"oldMatrix staticcall usersX6Matrix FAILED");
        //x6_2MATRIX=abi.decode(data, (uint32, uint32[], uint32[], bool, uint32, uint32));
        assembly{
            x6_2MATRIX:=add(data, 32)
        }
        //assembly{
            //mstore(x6_2MATRIX,add(data,0x20))
        //}
        MATRIX.currentReferrerID=x6_2MATRIX.currentReferrerID;
        MATRIX.firstLevelReferralsID=x6_2MATRIX.firstLevelReferralsID;
        MATRIX.secondLevelReferralsID=x6_2MATRIX.secondLevelReferralsID;
        MATRIX.blocked=x6_2MATRIX.blocked;
        MATRIX.closedPart=x6_2MATRIX.closedPart;
        MATRIX.reinvestCount=x6_2MATRIX.reinvestCount;
        return MATRIX;
    }

    function migrationsMatrix62(address oldMatrix,uint32 id,uint8 level) public view returns(bytes memory) {

        (bool success, ) = oldMatrix.staticcall(abi.encodeWithSignature("usersX6Matrix(uint32,uint8)",id,level));
        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())
            switch success
                case 0 {
                    revert(free_mem_ptr, returndatasize())
                }
                default {
                    return(free_mem_ptr, returndatasize())
                }
        }
    }

    function migrationsMatrix63(address oldMatrix,uint32 id,uint8 level) public view returns(uint32, uint32[] memory, uint32[] memory, bool, uint32, uint32) {

        (bool success,bytes memory data) = oldMatrix.staticcall(abi.encodeWithSignature("usersX6Matrix(uint32,uint8)",id,level));
        return abi.decode(data, (uint32, uint32[], uint32[], bool, uint32, uint32));
    }

    


    function migrationsUser(address oldMatrix,uint32 id) external returns(bool){
        //(bool success, bytes memory data) = oldMatrix.staticcall(abi.encodeWithSignature("lastUserId()"));
        //require(success && data.length != 0 ,"oldMatrix staticcall lastUserId FAILED");
        //uint32 oldlastUserId=abi.decode(data, (uint32));
        //require(lastUserId<oldlastUserId,"");
        (bool success, bytes memory data) = oldMatrix.staticcall(abi.encodeWithSignature("users(uint32)",id));
        require(success && data.length != 0 ,"oldMatrix staticcall users FAILED");
        StaticUser memory static_user;
        User storage user=users[id];
        assembly{
            static_user:=add(data, 32)
        }
            
        user.referrerID=static_user.referrerID;
        user.partnersCount=static_user.partnersCount;
        user.activeX3Levels=static_user.activeX3Levels;
        user.activeX6Levels=static_user.activeX6Levels;
        user.maxAvailableLevel=static_user.maxAvailableLevel;
        user.userAddress=static_user.userAddress;
        user.lastActivity=static_user.lastActivity;
        user.refBlocked=static_user.refBlocked;

        for(uint8 level=1;level<=static_user.activeX3Levels;level++){
            (success, data) = oldMatrix.staticcall(abi.encodeWithSignature("usersX3Matrix(uint32,uint8)",id,level));
            require(success && data.length != 0 ,"oldMatrix staticcall usersX3Matrix FAILED");

            (user.x3Matrix[level].currentReferrerID,
            user.x3Matrix[level].referralsID,
            user.x3Matrix[level].blocked,
            user.x3Matrix[level].reinvestCount)=abi.decode(data, (uint32, uint32[], bool, uint32));
        }

        return true;

        //lastUserId++;
        
    }
    
    function updateX3Referrer(uint32 userID, uint32 referrerID,  uint8 level) private {
        users[referrerID].x3Matrix[level].referralsID.push(userID);

        if (users[referrerID].x3Matrix[level].referralsID.length < 3) {
            emit NewUserPlace(userID, referrerID, 1, level, uint8(users[referrerID].x3Matrix[level].referralsID.length));
            return sendDividends(referrerID, userID, 1, level);
        }
        
        emit NewUserPlace(userID, referrerID, 1, level, 3);
        //close matrix
        users[referrerID].x3Matrix[level].referralsID = new uint32[](0);
        if (users[referrerID].activeX3Levels <= level && level != LAST_LEVEL) {
            users[referrerID].x3Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerID > 1) {
            //check referrer active level
            uint32 freeReferrerID = findFreeX3Referrer(referrerID, level);
            if (users[referrerID].x3Matrix[level].currentReferrerID != freeReferrerID) {
                users[referrerID].x3Matrix[level].currentReferrerID = freeReferrerID;
            }
            
            users[referrerID].x3Matrix[level].reinvestCount++;
            emit Reinvest(referrerID, freeReferrerID, userID, 1, level);
            updateX3Referrer(referrerID, freeReferrerID, level);
        } else {
            sendDividends(1, userID, 1, level);
            users[1].x3Matrix[level].reinvestCount++;
            emit Reinvest(1, 0, userID, 1, level);
        }
    }

    function updateX6Referrer(uint32 userID, uint32 referrerID, uint8 level) private {
        require(users[referrerID].activeX6Levels>=level, "500. Referrer level is inactive");
        
        if (users[referrerID].x6Matrix[level].firstLevelReferralsID.length < 2) {
            users[referrerID].x6Matrix[level].firstLevelReferralsID.push(userID);
            emit NewUserPlace(userID, referrerID, 2, level, uint8(users[referrerID].x6Matrix[level].firstLevelReferralsID.length));
            
            //set current level
            users[userID].x6Matrix[level].currentReferrerID = referrerID;

            if (referrerID > 1) {            
            
                uint32 ref = users[referrerID].x6Matrix[level].currentReferrerID;            
                users[ref].x6Matrix[level].secondLevelReferralsID.push(userID); 
            
                uint256 len = users[ref].x6Matrix[level].firstLevelReferralsID.length;
            
                if ((len == 2) && 
                    (users[ref].x6Matrix[level].firstLevelReferralsID[0] == referrerID) &&
                    (users[ref].x6Matrix[level].firstLevelReferralsID[1] == referrerID)) {
                    if (users[referrerID].x6Matrix[level].firstLevelReferralsID.length == 1) {
                        emit NewUserPlace(userID, ref, 2, level, 5);
                    } else {
                        emit NewUserPlace(userID, ref, 2, level, 6);
                    }
                }  else if ((len == 1 || len == 2) &&
                        users[ref].x6Matrix[level].firstLevelReferralsID[0] == referrerID) {
                    if (users[referrerID].x6Matrix[level].firstLevelReferralsID.length == 1) {
                        emit NewUserPlace(userID, ref, 2, level, 3);
                    } else {
                        emit NewUserPlace(userID, ref, 2, level, 4);
                    }
                } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferralsID[1] == referrerID) {
                    if (users[referrerID].x6Matrix[level].firstLevelReferralsID.length == 1) {
                        emit NewUserPlace(userID, ref, 2, level, 5);
                    } else {
                        emit NewUserPlace(userID, ref, 2, level, 6);
                    }
                }

                return updateX6ReferrerSecondLevel(userID, ref, level);
            }else{
                return sendDividends(1, userID, 2, level);
            }
        }
        
        users[referrerID].x6Matrix[level].secondLevelReferralsID.push(userID);

        if (users[referrerID].x6Matrix[level].closedPart != 0) {
            if (users[referrerID].x6Matrix[level].firstLevelReferralsID[0] == users[referrerID].x6Matrix[level].closedPart) {

                updateX6(userID, referrerID, level, true);
                return updateX6ReferrerSecondLevel(userID, referrerID, level);

            } else {
                updateX6(userID, referrerID, level, false);
                return updateX6ReferrerSecondLevel(userID, referrerID, level);
            }
        }

        if (users[referrerID].x6Matrix[level].firstLevelReferralsID[1] == userID) {
            updateX6(userID, referrerID, level, false);
            return updateX6ReferrerSecondLevel(userID, referrerID, level);
        } else if (users[referrerID].x6Matrix[level].firstLevelReferralsID[0] == userID) {
            updateX6(userID, referrerID, level, true);
            return updateX6ReferrerSecondLevel(userID, referrerID, level);
        }
        
        if (users[users[referrerID].x6Matrix[level].firstLevelReferralsID[0]].x6Matrix[level].firstLevelReferralsID.length <= 
            users[users[referrerID].x6Matrix[level].firstLevelReferralsID[1]].x6Matrix[level].firstLevelReferralsID.length) {
            updateX6(userID, referrerID, level, false);
        } else {
            updateX6(userID, referrerID, level, true);
        }
        
        updateX6ReferrerSecondLevel(userID, referrerID, level);
    }

    function updateX6(uint32 userID, uint32 referrerID, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerID].x6Matrix[level].firstLevelReferralsID[0]].x6Matrix[level].firstLevelReferralsID.push(userID);
            emit NewUserPlace(userID, users[referrerID].x6Matrix[level].firstLevelReferralsID[0], 2, level, uint8(users[users[referrerID].x6Matrix[level].firstLevelReferralsID[0]].x6Matrix[level].firstLevelReferralsID.length));
            emit NewUserPlace(userID, referrerID, 2, level, 2 + uint8(users[users[referrerID].x6Matrix[level].firstLevelReferralsID[0]].x6Matrix[level].firstLevelReferralsID.length));
            //set current level
            users[userID].x6Matrix[level].currentReferrerID = users[referrerID].x6Matrix[level].firstLevelReferralsID[0];
        } else {
            users[users[referrerID].x6Matrix[level].firstLevelReferralsID[1]].x6Matrix[level].firstLevelReferralsID.push(userID);
            emit NewUserPlace(userID, users[referrerID].x6Matrix[level].firstLevelReferralsID[1], 2, level, uint8(users[users[referrerID].x6Matrix[level].firstLevelReferralsID[1]].x6Matrix[level].firstLevelReferralsID.length));
            emit NewUserPlace(userID, referrerID, 2, level, 4 + uint8(users[users[referrerID].x6Matrix[level].firstLevelReferralsID[1]].x6Matrix[level].firstLevelReferralsID.length));
            //set current level
            users[userID].x6Matrix[level].currentReferrerID = users[referrerID].x6Matrix[level].firstLevelReferralsID[1];
        }
    }
    
    function updateX6ReferrerSecondLevel(uint32 userID, uint32 referrerID, uint8 level) private {
        if (users[referrerID].x6Matrix[level].secondLevelReferralsID.length < 4) {
            return sendDividends(referrerID, userID, 2, level);
        }
        
        uint32[] memory x6 = users[users[referrerID].x6Matrix[level].currentReferrerID].x6Matrix[level].firstLevelReferralsID;
        
        if (x6.length == 2) {
            if (x6[0] == referrerID ||
                x6[1] == referrerID) {
                users[users[referrerID].x6Matrix[level].currentReferrerID].x6Matrix[level].closedPart = referrerID;
            } else if (x6.length == 1) {
                if (x6[0] == referrerID) {
                    users[users[referrerID].x6Matrix[level].currentReferrerID].x6Matrix[level].closedPart = referrerID;
                }
            }
        }
        
        users[referrerID].x6Matrix[level].firstLevelReferralsID = new uint32[](0);
        users[referrerID].x6Matrix[level].secondLevelReferralsID = new uint32[](0);
        users[referrerID].x6Matrix[level].closedPart = 0;

        if (users[referrerID].activeX6Levels <= level && level != LAST_LEVEL) {
            users[referrerID].x6Matrix[level].blocked = true;
        }
      
        
        if (referrerID > 1) {
            users[referrerID].x6Matrix[level].reinvestCount++;
            uint32 freeReferrerID = findFreeX6Referrer(referrerID, level);

            emit Reinvest(referrerID, freeReferrerID, userID, 2, level);
            updateX6Referrer(referrerID, freeReferrerID, level);
        } else {
            users[1].x6Matrix[level].reinvestCount++;
            emit Reinvest(1, 0, userID, 2, level);
            sendDividends(1, userID, 2, level);
        }
    }
    
    function findFreeX3Referrer(uint32 userID, uint8 level) public view returns(uint32) {
        
        if(userID<lastUserId && level<=LAST_LEVEL){
            while (true) {
                if (users[users[userID].referrerID].activeX3Levels>=level && isActive(users[userID].referrerID)) {
                    return users[userID].referrerID;
                }
            
                userID = users[userID].referrerID;
            }
        }
        return 1;
       
    }
    
    function findFreeX6Referrer(uint32 userID, uint8 level) public view returns(uint32) {
        
        if(userID<lastUserId && level<=LAST_LEVEL){
            while (true) {
                if (users[users[userID].referrerID].activeX6Levels>=level && isActive(users[userID].referrerID) ) {
                    return users[userID].referrerID;
                }
            
                userID = users[userID].referrerID;
            }
        }
        return 1;
    }
        
    function usersActiveX3Levels(uint32 userID, uint8 level) external view returns(bool) {
        if(userID<lastUserId && level<=LAST_LEVEL){
            return users[userID].activeX3Levels>=level;
        }
        return false;       
    }

    function usersActiveX6Levels(uint32 userID, uint8 level) external view returns(bool) {
        if(userID<lastUserId && level<=LAST_LEVEL){
            return users[userID].activeX6Levels>=level;
        }
        return false; 
    }

    function usersX3Matrix(uint32 userID, uint8 level) external view returns(uint32, uint32[] memory, bool, uint32) {
        require(userID<lastUserId && level<=LAST_LEVEL,"wrong arguments");
        return (users[userID].x3Matrix[level].currentReferrerID,
                users[userID].x3Matrix[level].referralsID,
                users[userID].x3Matrix[level].blocked,users[userID].x3Matrix[level].reinvestCount);
    }

    function usersX6Matrix(uint32 userID, uint8 level) external view returns(uint32, uint32[] memory, uint32[] memory, bool, uint32, uint32) {
        require(userID<lastUserId && level<=LAST_LEVEL,"wrong arguments");
        return (users[userID].x6Matrix[level].currentReferrerID,
                users[userID].x6Matrix[level].firstLevelReferralsID,
                users[userID].x6Matrix[level].secondLevelReferralsID,
                users[userID].x6Matrix[level].blocked,
                users[userID].x6Matrix[level].closedPart,
                users[userID].x6Matrix[level].reinvestCount);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (AddressToId[user] != 0);
    }

    function getCurrentPeriod() public view returns (uint256) {
        return block.timestamp.sub(startTimestamp).div(periodDuration);
    }

    function isActive(uint32 _userID) public view returns (bool) {
       uint256 period=getCurrentPeriod();
       return (period.sub(users[_userID].lastActivity)<=1 || _userID==1);
    }

    function findReceiver(uint32 userID, uint32 _fromID, uint8 matrix, uint8 level) private returns(uint32, bool) {
        uint32 receiver = userID;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].x3Matrix[level].blocked || isActive(receiver)==false) {
                    emit MissedReceive(receiver, _fromID, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x3Matrix[level].currentReferrerID;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].x6Matrix[level].blocked || isActive(receiver)==false) {
                    emit MissedReceive(receiver, _fromID, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x6Matrix[level].currentReferrerID;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
        return (1, true);
    }

    function sendDividends(uint32 userID, uint32 _fromID, uint8 matrix, uint8 level) private {

        (uint32 receiverID, bool isExtraDividends) = findReceiver(userID, _fromID, matrix, level);
        if(receiverID<1){receiverID=1;}

        
        uint256 amount=getLevelPrice(level);
        uint256 amount20=amount.div(5);
        uint256 amount80=amount.sub(amount20); 
        matrixesToken.safeTransfer(
            users[receiverID].userAddress,
            amount80
        );
        
        matrixesToken.safeTransfer(
            distrContrAddress,
            amount20
        );
        
         
              
        if (isExtraDividends) {
            emit SentExtraDividends(_fromID, receiverID, amount80, matrix, level);
        }else{
            emit SentDividends(_fromID, receiverID, amount80, matrix, level);
        }
    } 
    
}

// SPDX-License-Identifier: UNLICENSED
/*
http://kangoo.group/
*/
pragma solidity 0.7.6;

import "./lib/IBEP20.sol";
import "./lib/SafeMath.sol";
import "./lib/TransferHelper.sol";
import "./lib/Ownable.sol";
import "./lib/IPancakeRouter02.sol";
import './lib/IPancakeFactory.sol';

pragma experimental ABIEncoderV2;

contract KangarooStake is Ownable{
    using SafeMath for uint256;
    using TransferHelper for IBEP20;

    
    IBEP20 immutable public lpKangarooToken;
    IBEP20 immutable public rooToken;
    IBEP20 immutable public usdtToken;
    address immutable public poolInitiator;
    address immutable public pancakeRouter;// 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public PancakePairAddress;
    address[] public tokenPath;
    bool public openSale=false;

    struct UserInfo {
        uint256 depositTimestamp;
        uint256 sharesAmount;
        uint256 initialDepositAmount;
    }

    struct PoolInfo {
        uint256 freezingPeriod;
        uint256 currentRewardPerShare;
        uint256 sharesTotal;
        mapping(address => UserInfo) usersInfo;
    }


    PoolInfo[3] private pool;
    mapping(address => bool) public isUserExists;
    
    modifier notForPoolInitiator() {
        require(msg.sender!=poolInitiator,"not for pool initiator");
        _;
    }

    modifier poolExist(uint256 _id) {
        require(_id >= 0 && _id<3, "bad pool id");
        _;
    }

    event Stake(uint256 poolId, address user, uint256 amount);
    event PoolCharged(uint256 amount);
    event UnStake(uint256 poolId, address user, uint256 amount);
    event Dividends(uint256 poolId, address user, uint256 amount);

    constructor(address _pancakeRouter,
        address _rooToken,
        address _usdtToken,
        address _poolInitiator,
        uint256[] memory _freezingPeriod
    ) {
        tokenPath=[_usdtToken,_rooToken];
        rooToken=IBEP20(_rooToken);
        usdtToken=IBEP20(_usdtToken);
        poolInitiator=_poolInitiator;
        pancakeRouter=_pancakeRouter;
        PancakePairAddress=IPancakeFactory(IPancakeRouter02(_pancakeRouter).factory()).getPair(_usdtToken,_rooToken);
        require(PancakePairAddress != address(0), "create Pancake pair first");
        lpKangarooToken=IBEP20(PancakePairAddress);
         
        for(uint256 i=0;i<3;i++){
            pool[i].freezingPeriod=_freezingPeriod[i];
            pool[i].usersInfo[_poolInitiator].depositTimestamp = block.timestamp;
            pool[i].usersInfo[_poolInitiator].sharesAmount = 1e12;
            pool[i].usersInfo[_poolInitiator].initialDepositAmount = 0;
        }
        pool[2].sharesTotal = 1e12;
        pool[1].sharesTotal = 2e12;
        pool[0].sharesTotal = 3e12;

    }

    function firstStaking(address _user,uint256 _amount) external {
        require(msg.sender==poolInitiator,"can only be called by the pool initiator");
        require(
            isUserExists[_user],
            "user is not exists. Register first."
        );
        require(
            usdtToken.allowance(_user, address(this)) >=_amount,
            "Increase the allowance first,call the usdt-approve method "
        );

        usdtToken.safeTransferFrom(
            _user,
            address(this),
            _amount
        );

        uint256 token0amount=usdtToken.balanceOf(address(this)).div(2);

        usdtToken.safeIncreaseAllowance(pancakeRouter, token0amount);

        uint256[] memory amounts=IPancakeRouter02(pancakeRouter)
            .swapExactTokensForTokens(
            token0amount,
            0,
            tokenPath,
            address(this),
            block.timestamp + 60
        );

        uint256 token0Amt = usdtToken.balanceOf(address(this));
        uint256 token1Amt = amounts[amounts.length - 1];//rooToken.balanceOf(address(this));

        usdtToken.safeIncreaseAllowance(
            pancakeRouter,
            token0Amt
        );
        rooToken.safeIncreaseAllowance(
            pancakeRouter,
            token1Amt
        );


        (,, uint256 liquidity)=IPancakeRouter02(pancakeRouter).addLiquidity(
            tokenPath[0],
            tokenPath[1],
            token0Amt,
            token1Amt,
            0,
            0,
            address(this),
            block.timestamp + 60
        );

        UserInfo storage user = pool[2].usersInfo[_user];
        

        user.depositTimestamp = block.timestamp;
        user.sharesAmount = user.sharesAmount.add(liquidity);
        user.initialDepositAmount = user.sharesAmount.mul(pool[2].currentRewardPerShare).div(1e12);

        for(uint256 i=0;i<3;i++){
            pool[i].sharesTotal = pool[i].sharesTotal.add(liquidity);
        }

        emit Stake(2, _user, liquidity);

    }


    function createUser(address userAddress) external onlyOwner returns (bool){
        isUserExists[userAddress]=true;
        return(true);
    }

    function startOpenSale() external onlyOwner returns(bool) {
        openSale=true;
        return(openSale);
    }

    function chargePool(uint256 amount) external returns (bool){
        
        require(amount>100,"charged amount is too small");

        rooToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            amount
        );
        
        uint256 chargedAmount50=amount.div(2);
        uint256 chargedAmount20=amount.div(5);
        uint256 chargedAmount30=amount.sub(chargedAmount50.add(chargedAmount20));
            
        pool[2].currentRewardPerShare=pool[2].currentRewardPerShare
        .add(chargedAmount20.mul(1e12).div(pool[2].sharesTotal))
        .add(chargedAmount30.mul(1e12).div(pool[1].sharesTotal))
        .add(chargedAmount50.mul(1e12).div(pool[0].sharesTotal));

        pool[1].currentRewardPerShare=pool[1].currentRewardPerShare
        .add(chargedAmount30.mul(1e12).div(pool[1].sharesTotal))
        .add(chargedAmount50.mul(1e12).div(pool[0].sharesTotal));

        pool[0].currentRewardPerShare=pool[0].currentRewardPerShare
        .add(chargedAmount50.mul(1e12).div(pool[0].sharesTotal));

        emit PoolCharged(amount);
        return(true);
    }

    function dividendsTransfer(uint256 _id, address _to, uint256 _amount) internal {
        
        require(openSale,"not available before the OpenSale started");

        uint256 max=rooToken.balanceOf(address(this));
        if (_amount > max) {
            _amount=max;
        }

        pool[_id].usersInfo[_to].initialDepositAmount = pool[_id].usersInfo[_to].sharesAmount
        .mul(pool[_id].currentRewardPerShare)
        .div(1e12);

        rooToken.safeTransfer(_to, _amount);
        emit Dividends(_id, _to, _amount);
    }

    

    function stake(uint256 _id, uint256 _amount) external notForPoolInitiator poolExist(_id){
        require(
            isUserExists[msg.sender],
            "user is not exists. Register first."
        );
        require(_amount > 0, "amount must be greater than 0");
        
        
        require(
            lpKangarooToken.allowance(address(msg.sender), address(this)) >=
                _amount,
            "Increase the allowance first,call the approve method"
        );

        UserInfo storage user = pool[_id].usersInfo[msg.sender];

        if (user.sharesAmount > 0) {
            uint256 dividends = calculateDividends(_id,msg.sender);
            if (dividends > 0) {
                dividendsTransfer(_id, msg.sender, dividends);
            }
        }
        
        lpKangarooToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        user.depositTimestamp = block.timestamp;
        user.sharesAmount = user.sharesAmount.add(_amount);
        user.initialDepositAmount = user.sharesAmount.mul(pool[_id].currentRewardPerShare).div(1e12);
        for(uint256 i=0;i<=_id;i++){
            pool[i].sharesTotal = pool[i].sharesTotal.add(_amount);
        }
        emit Stake(_id, msg.sender, _amount);
      
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _id) external notForPoolInitiator poolExist(_id){
        
        UserInfo storage user = pool[_id].usersInfo[msg.sender];
        uint256 unstaked_shares = user.sharesAmount;
        require(
            unstaked_shares > 0,
            "you do not have staked tokens, stake first"
        );
        require(isTokensFrozen(_id, msg.sender) == false, "tokens are frozen");
        user.sharesAmount = 0;
        user.initialDepositAmount = 0;

        for(uint256 i=0;i<=_id;i++){
            pool[i].sharesTotal = pool[i].sharesTotal.sub(unstaked_shares);
        }
        lpKangarooToken.safeTransfer(msg.sender, unstaked_shares);
        emit UnStake(_id, msg.sender, unstaked_shares);
    }

    function unstake(uint256 _id, uint256 _amount) external notForPoolInitiator poolExist(_id){
        
        UserInfo storage user = pool[_id].usersInfo[msg.sender];

        require(
            _amount > 0 && _amount<=user.sharesAmount,"bad _amount"
        );
        require(isTokensFrozen(_id, msg.sender) == false, "tokens are frozen");

        uint256 dividends = calculateDividends(_id, msg.sender);
        if (dividends > 0) {
            dividendsTransfer(_id, msg.sender, dividends);
        }
        user.sharesAmount=user.sharesAmount.sub(_amount);
        user.initialDepositAmount = user.sharesAmount.mul(pool[_id].currentRewardPerShare).div(1e12);
        for(uint256 i=0;i<=_id;i++){
            pool[i].sharesTotal = pool[i].sharesTotal.sub(_amount);
        }
        
        lpKangarooToken.safeTransfer(msg.sender, _amount);

        emit UnStake(_id, msg.sender, _amount);
    }

    function getDividends(uint256 _id) external poolExist(_id){
        require(
            pool[_id].usersInfo[msg.sender].sharesAmount > 0,
            "you do not have staked tokens, stake first"
        );
        uint256 dividends = calculateDividends(_id, msg.sender);
        if (dividends > 0) {
            dividendsTransfer(_id, msg.sender, dividends);
        }
    }

    function calculateDividends(uint256 _id, address userAddress)
        public
        view
        returns (uint256)
    {
        return pool[_id].usersInfo[userAddress].sharesAmount
        .mul(pool[_id].currentRewardPerShare)
        .div(1e12)
        .sub(pool[_id].usersInfo[userAddress].initialDepositAmount);
    }

    function isTokensFrozen(uint256 _id, address userAddress) public view returns (bool) {
        return (pool[_id].freezingPeriod >(block.timestamp.sub(pool[_id].usersInfo[userAddress].depositTimestamp)));
    }

    function getPoolSharesTotal(uint256 _id)
        external
        view
        returns (uint256)
    {
        return pool[_id].sharesTotal;
    }

    function getUser(uint256 _id,address userAddress)
        external
        view
        returns (UserInfo memory)
    {
        return pool[_id].usersInfo[userAddress];
    }

}

// SPDX-License-Identifier: MIT
/*
http://kangoo.group/
*/
pragma solidity 0.7.6;

import "./lib/BEP20.sol";
import "./lib/SafeMath.sol";

contract KangarooToken is BEP20 {
    using SafeMath for uint256;
    uint256 constant public MaxSupply = 21000000*1e18;
    address immutable public matrixesRoot;
    bool public openSale=false;
    mapping(address => bool) private whitelistBeforeOpenSale;


    event Burned(uint256 burnAmount);

    constructor(address _matrixesRoot) BEP20("KangarooToken", "ROO", 18) {
        matrixesRoot=_matrixesRoot;
        whitelistBeforeOpenSale[_matrixesRoot]=true;
        //_mint(_matrixesRoot, MaxSupply);
        _mint(msg.sender, MaxSupply);//test only
    }

    function transfer(address recipient, uint256 amount) public override(BEP20) returns (bool){
        require(openSale==true || whitelistBeforeOpenSale[recipient],
        "token purchase is not available during the liquidity creation period");
        return BEP20.transfer(recipient, amount);
    }

    function setWhitelistAddress(address _whitelistAddress) external onlyOwner {
        whitelistBeforeOpenSale[_whitelistAddress]=true;
    }

    function startOpenSale() external onlyOwner returns(bool) {
        openSale=true;
        return(openSale);
    }
    
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        emit Burned(amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.4 <0.8.0;

import "./Context.sol";
import "./IBEP20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }
    /**
   * @dev Returns the bep token owner.
   */
    function getOwner() public view virtual override returns (address) {
        return owner();
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {BEP20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IBEP20-balanceOf} and {IBEP20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IBEP20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IBEP20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IBEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IBEP20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IBEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IBEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
   * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
   * from the caller's allowance.
   *
   * See {_burn} and {_approve}.
   */
    function _burnFrom(address account, uint256 amount) internal {
     _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.4 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.4 <0.8.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.4 <0.8.0;
// "SPDX-License-Identifier: Apache License 2.0"

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.4 <0.8.0;

/**
 * Copyright (c) 2016-2019 zOS Global Limited
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.4 <0.8.0;
import "./IBEP20.sol";
import "./SafeMath.sol";

library TransferHelper {
    using SafeMath for uint256;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            address(token).call(
                abi.encodeWithSelector(token.transfer.selector, to, value)
            );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            address(token).call(
                abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
            );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TRANSFER_FROM_FAILED"
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);

        (bool success, bytes memory data) =
            address(token).call(
                abi.encodeWithSelector(token.approve.selector,spender,newAllowance)
            );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "INCREASE_ALLOWANCE_FAILED"
        );     
    }
}