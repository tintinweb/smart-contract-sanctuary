//SourceUnit: contract.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


contract PandasMatrix {

    struct Player {
        uint id;
        address referrer;
        uint patners;
        
        mapping(uint8 => bool) activeP4Levels;
        mapping(uint8 => bool) activeP5Levels;
        
        mapping(uint8 => P4) p4Matrix;
        mapping(uint8 => P5) p5Matrix;
    }
    
    struct P4 {
        address firstReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct P5 {
        address currentReferrer;
        address[] p5referrals;
        bool blocked;
        uint reinvestCount;
        address closedPart;
    }

    uint128 public constant SLOT_FINAL_LEVEL = 15;
    
    mapping(address => Player) public players;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances;
    mapping(address => uint) public totalP4ReferalsReturns;
    mapping(address => uint) public totalP5ReferalsReturns;
    mapping(address => address[]) public userReferals;
    //address[] public spillReceivers;

    mapping(uint => address[]) public roundSpillReceivers;

    uint public lastUserId = 2;
    address public owner;
    
    mapping(uint8 => uint) public levelPrice;

    mapping (uint8 => mapping (uint8 => uint)) matrixLevelPrice;
    mapping (uint => uint) public roundGlobalSpills;

    uint public gsRound;

    mapping(uint => uint) public roundStartTime;
    //uint256 public globalSpills;
    
    //Events
    event AmountSent(uint amount, address indexed sender);
    event SignUp(address indexed player, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed player, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed player, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed players, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedTronReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraTronDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);

    constructor(address ownerAddress) {


        matrixLevelPrice[1][1] = 60 trx;
        matrixLevelPrice[1][2] = 120 trx;
        matrixLevelPrice[1][3] = 200 trx;
        matrixLevelPrice[1][4] = 400 trx;
        matrixLevelPrice[1][5] = 500 trx;
        matrixLevelPrice[1][6] = 700 trx;
        matrixLevelPrice[1][7] = 1000 trx;
        matrixLevelPrice[1][8] = 1500 trx;
        matrixLevelPrice[1][9] = 2000 trx;
        matrixLevelPrice[1][10] = 3000 trx;
        matrixLevelPrice[1][11] = 4000 trx;
        matrixLevelPrice[1][12] = 7000 trx;
        matrixLevelPrice[1][13] = 8000 trx;
        matrixLevelPrice[1][14] = 10000 trx;
        matrixLevelPrice[1][14] = 12000 trx;

        matrixLevelPrice[2][1] = 50 trx;
        matrixLevelPrice[2][2] = 80 trx;
        matrixLevelPrice[2][3] = 100 trx;
        matrixLevelPrice[2][4] = 200 trx;
        matrixLevelPrice[2][5] = 300 trx;
        matrixLevelPrice[2][6] = 500 trx;
        matrixLevelPrice[2][7] = 800 trx;
        matrixLevelPrice[2][8] = 1000 trx;
        matrixLevelPrice[2][9] = 1500 trx;
        matrixLevelPrice[2][10] = 2000 trx;
        matrixLevelPrice[2][11] = 3000 trx;
        matrixLevelPrice[2][12] = 5000 trx;
        matrixLevelPrice[2][13] = 6000 trx;
        matrixLevelPrice[2][14] = 800 trx;
        matrixLevelPrice[2][15] = 10000 trx;

        gsRound = 1;

        roundStartTime[gsRound] = block.timestamp;

        owner = ownerAddress;
        
        players[ownerAddress].id = 1;
        players[ownerAddress].referrer = address(0);
        players[ownerAddress].patners = uint(0);
        
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= SLOT_FINAL_LEVEL; i++) {
            players[ownerAddress].activeP4Levels[i] = true;
            players[ownerAddress].activeP5Levels[i] = true;
        }
        userIds[1] = ownerAddress;
    }
    
    
    function registration(address userAddress, address referrerAddress) private {
        require(!isPlatformUser(userAddress), "user exists");
        require(isPlatformUser(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        
        players[userAddress].id = lastUserId;
        players[userAddress].referrer = referrerAddress;
        players[userAddress].patners = 0;
        
        idToAddress[lastUserId] = userAddress;
        
        players[userAddress].referrer = referrerAddress;
        
        players[userAddress].activeP4Levels[1] = true; 
        players[userAddress].activeP5Levels[1] = true;
        
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        players[referrerAddress].patners++;

        address freep4Referrer = players[userAddress].referrer;
        players[userAddress].p4Matrix[1].firstReferrer = freep4Referrer;
        roundGlobalSpills[gsRound] += (matrixLevelPrice[1][1] + matrixLevelPrice[2][1])/10;
        
        
        updatep4Referrer(userAddress, freep4Referrer, 1);

        updatep5Referrer(userAddress, players[userAddress].referrer, 1);
        payable(owner).transfer(((matrixLevelPrice[1][1] + matrixLevelPrice[2][1]) *2)/10);
        if(players[msg.sender].referrer != owner) {
            payable(upLineUpLine(msg.sender)).transfer((matrixLevelPrice[1][1] + matrixLevelPrice[2][1])/10);
        } else {
            roundGlobalSpills[gsRound] += (matrixLevelPrice[1][1] + matrixLevelPrice[2][1])/10;
        }
        userReferals[referrerAddress].push(msg.sender);
        
        emit SignUp(userAddress, referrerAddress, players[userAddress].id, players[referrerAddress].id);
    }

    fallback() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }
    
    receive() external payable {
        emit AmountSent(msg.value, msg.sender);
    }

    function getregamount() public view returns(uint) {
        return matrixLevelPrice[1][1] + matrixLevelPrice[2][1];
    }

    function registrationExt(address referrerAddress) external payable {
        require(msg.value >= getregamount());
        registration(msg.sender, referrerAddress);
        totalP4ReferalsReturns[referrerAddress] += ((matrixLevelPrice[1][1]*6) /10);
        totalP5ReferalsReturns[referrerAddress] += ((matrixLevelPrice[2][1]*6) /10);
    }


    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        require(isPlatformUser(msg.sender), "register first");
        require(matrix == 1 || matrix == 2, "invalid choice");
        require(msg.value >= matrixLevelPrice[matrix][level]);
        require(level > 1 && level <= SLOT_FINAL_LEVEL, "invalid level");
        require(players[msg.sender].activeP4Levels[level - 1] == true, "first activate the previous level");

        if (matrix == 1) {
            require(!players[msg.sender].activeP4Levels[level], "already active");

            if (players[msg.sender].p4Matrix[level-1].blocked) {
                players[msg.sender].p4Matrix[level-1].blocked = false;
            }
    
            address freep4Referrer = players[msg.sender].referrer;
            players[msg.sender].p4Matrix[level].firstReferrer = freep4Referrer;
            players[msg.sender].activeP4Levels[level] = true;
            totalP4ReferalsReturns[players[msg.sender].referrer] += matrixLevelPrice[matrix][level] *6 /10;
            updatep4Referrer(msg.sender, freep4Referrer, level);
            
            emit Upgrade(msg.sender, freep4Referrer, 1, level);

        } else {
            require(!players[msg.sender].activeP5Levels[level], "already active"); 

            if (players[msg.sender].p5Matrix[level-1].blocked) {
                players[msg.sender].p5Matrix[level-1].blocked = false;
            }

            address freep5Referrer = players[msg.sender].referrer;
            
            players[msg.sender].activeP5Levels[level] = true;
            totalP5ReferalsReturns[players[msg.sender].referrer] += matrixLevelPrice[matrix][level]*6/10;
            updatep5Referrer(msg.sender, freep5Referrer, level);
            
            emit Upgrade(msg.sender, freep5Referrer, 2, level);
        }
        roundGlobalSpills[gsRound] += (matrixLevelPrice[matrix][level]/10);
        if (level >= 3){
            roundSpillReceivers[gsRound].push(msg.sender);
        }
        payable(owner).transfer((matrixLevelPrice[matrix][level] * 2)/10);
        if(players[msg.sender].referrer != owner) {
            payable(upLineUpLine(msg.sender)).transfer((matrixLevelPrice[matrix][level])/10);
        } else {
            roundGlobalSpills[gsRound] += (matrixLevelPrice[matrix][level])/10;
        }
    }

    function upLineUpLine(address playerAdd) private view returns(address) {
        address upline = players[playerAdd].referrer;
        return players[upline].referrer;
        
    }

    function updatep4Referrer(address userAddress, address referrerAddress, uint8 level) private {
        players[referrerAddress].p4Matrix[level].referrals.push(userAddress);

        if (players[referrerAddress].p4Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(players[referrerAddress].p4Matrix[level].referrals.length));
            return sendTrnReturns(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        players[referrerAddress].p4Matrix[level].referrals = new address[](0);
        if (!players[referrerAddress].activeP4Levels[level+1] && level != SLOT_FINAL_LEVEL) {
            players[referrerAddress].p4Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = players[userAddress].referrer;
            if (players[referrerAddress].p4Matrix[level].firstReferrer != freeReferrerAddress) {
                players[referrerAddress].p4Matrix[level].firstReferrer = freeReferrerAddress;
            }
            
            players[referrerAddress].p4Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updatep4Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendTrnReturns(owner, userAddress, 1, level);
            players[owner].p4Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function updatep5Referrer(address userAddress, address referrerAddress, uint8 level) private {
        players[referrerAddress].p5Matrix[level].p5referrals.push(userAddress);

        if (players[referrerAddress].p5Matrix[level].p5referrals.length <= 4) {
            sendTrnReturns(referrerAddress, userAddress, 2, level);
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(players[referrerAddress].p4Matrix[level].referrals.length));
            
        }
        if (players[referrerAddress].p5Matrix[level].p5referrals.length == 5) {
            sendTrnReturns(players[referrerAddress].referrer, userAddress, 2, level);
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(players[referrerAddress].p4Matrix[level].referrals.length));
        }
        if (players[referrerAddress].p5Matrix[level].p5referrals.length == 6) {
            sendTrnReturns(players[players[referrerAddress].referrer].referrer, userAddress, 2, level);
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(players[referrerAddress].p4Matrix[level].referrals.length));
        }
        
        
        emit NewUserPlace(userAddress, referrerAddress, 2, level, 6);
        //close matrix
        players[referrerAddress].p5Matrix[level].p5referrals = new address[](0);
        if (!players[referrerAddress].activeP5Levels[level+1] && level != SLOT_FINAL_LEVEL) {
            players[referrerAddress].p5Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = players[userAddress].referrer;
            if (players[referrerAddress].p5Matrix[level].currentReferrer != freeReferrerAddress) {
                players[referrerAddress].p5Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            players[referrerAddress].p5Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updatep5Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendTrnReturns(owner, userAddress, 1, level);
            players[owner].p5Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }
    /*

    function findFreep4Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (players[players[userAddress].referrer].activeP4Levels[level]) {
                return players[userAddress].referrer;
            }
            
            userAddress = players[userAddress].referrer;
        }
        return userAddress;
    }

    function findFreep5Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (players[players[userAddress].referrer].activeP5Levels[level]) {
                return players[userAddress].referrer;
            }
            
            userAddress = players[userAddress].referrer;
        }
        return userAddress;
    }
    */
    
    function giveSpills() public {
        require(msg.sender == owner);
        require(block .timestamp >= roundStartTime[gsRound] + 172800); //ensures that it can ony be called 48 hours after last call
        for (uint i = 0; i < roundSpillReceivers[gsRound].length; i++) {
            payable(roundSpillReceivers[gsRound][i]).transfer(roundGlobalSpills[gsRound]/roundSpillReceivers[gsRound].length);
        }
        gsRound ++;
        roundStartTime[gsRound] = block.timestamp;
    }

/*    function seekTronReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (players[receiver].p4Matrix[level].blocked) {
                    emit MissedTronReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = players[receiver].p4Matrix[level].firstReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (players[receiver].p5Matrix[level].blocked) {
                    emit MissedTronReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = players[receiver].p5Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
        return(receiver, isExtraDividends);
    }
    */

    function sendTrnReturns(address userAddress, address _from, uint8 matrix, uint8 level) private {
        //(address receiver, bool isExtraDividends) = seekTronReceiver(userAddress, _from, matrix, level);
        address receiver = players[userAddress].referrer;

    //****************************************************************************************///
        payable(address(uint160(receiver))).transfer((matrixLevelPrice[matrix][level] *6) /10);
        
        balances[receiver] += ((matrixLevelPrice[matrix][level] *6) /10 ) ;
        
        emit SentExtraTronDividends(_from, receiver, matrix, level);
    }
    
    function getNumberOfP4Referers(address player, uint8 level) public view returns(uint) {
        return players[player].p4Matrix[level].referrals.length;
    }

    function getNumberOfP5Referers(address player, uint8 level) public view returns(uint) {
        return players[player].p5Matrix[level].p5referrals.length;
    }


    function playersActivep4Levels(address userAddress, uint8 level) public view returns(bool) {
        return players[userAddress].activeP4Levels[level];
    }

    function playersActivep5Levels(address userAddress, uint8 level) public view returns(bool) {
        return players[userAddress].activeP5Levels[level];
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function playersp4Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (players[userAddress].p4Matrix[level].firstReferrer,
                players[userAddress].p4Matrix[level].referrals,
                players[userAddress].p4Matrix[level].blocked);
    }

    function playersp5Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool, address) {
        return (players[userAddress].p5Matrix[level].currentReferrer,
                players[userAddress].p5Matrix[level].p5referrals,
                players[userAddress].p5Matrix[level].blocked,
                players[userAddress].p5Matrix[level].closedPart);
    }
    
    //checks if the user already exists
    function isPlatformUser(address player) public view returns (bool) {
        return (players[player].id != 0);
    }

}