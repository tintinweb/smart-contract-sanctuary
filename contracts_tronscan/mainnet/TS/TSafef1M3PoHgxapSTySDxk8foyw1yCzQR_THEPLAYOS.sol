//SourceUnit: THEPLAYOS.sol

pragma solidity 0.5.17;

contract TRC20Usdt {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract THEPLAYOS {
    
    struct User {
        uint id;
        address upline;
        uint32 directCount;

        mapping(uint8 => bool) activeP1Boards; 

        mapping(uint8 => uint32) buyroundP1Boards; 
        mapping(uint8 => uint32) buyroundP2Boards;

        mapping(uint8 => uint32) turnP1;  
        mapping(uint8 => uint32) turnP2; 
        
        mapping(uint8 => P1) p1Play;   

        uint16 userCountryId;
        uint16 userClanId;
    }

    mapping (uint8 => Ticket[] ) public p2Boards; 
    mapping (uint8 => uint ) public p2BoardTicketCount; 
    mapping (uint8 => uint ) public activeTicketNo;

    struct Ticket {
        uint ticketNo; 
        uint userId;
        bool filled;
        }

    struct Country {
        string countryName; 
        uint16 countryId;
        uint16 clanCount;
        mapping(uint16 => string) clan; 
        mapping(uint16 => address) clanMaster; 
    }

    mapping(uint16 => Country) public countryList;
    uint16 public countryCount = 1;
    address usdtAddress = 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C;
    TRC20Usdt usdt = TRC20Usdt(address(usdtAddress));

    struct P1 {
        address[] referrals;
    }

    uint8 constant LAST_BOARD = 6;
    uint8 constant TOKEN_DECIMAL = 6;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    
    uint public lastUserId = 2;
    address public owner;
    address public admin;
    address public sysadm;

    mapping(uint8 => uint256) public boardPrice;
    
    event Registration(address indexed user, address indexed upline, uint indexed userId, uint uplineId, uint16 userCountryId, uint16 userClanId);
    event EarnedP1(address indexed receiver, address indexed sender, uint8 play, uint8 board, uint earnedP1);
    event EarnedP2(address indexed receiver, uint8 play, uint8 board, uint earnedP2);
    event UpgradeP1(address indexed user, address indexed upline, uint8 play, uint8 board, uint sales, uint32 indexed buyroundP1P2Boards);
    event UpgradeP2(address indexed user, uint8 play, uint8 board, uint sales, uint32 indexed buyroundP1P2Boards);
    event ReinvestP1P2(address indexed user, uint8 play, uint8 board, uint8 reinvestP1P2);
    event NewUserPlace(address indexed user, address indexed upline, uint8 play, uint8 board, uint8 place);
    event P2TicketCount(uint8 board, uint number, address indexed user);
    event P2ActiveTicketNo(uint8 board, uint number, address indexed activeUser);

    constructor(address ownerAddress, address adminAddress) public {
        
        boardPrice[1] = 50;
        boardPrice[2] = 100;
        boardPrice[3] = 200;
        boardPrice[4] = 400;
        boardPrice[5] = 800;
        boardPrice[6] = 1600;
        
        owner = ownerAddress;
        admin = adminAddress;
        sysadm = address(0x8Cf371954EE7df79446204d3Be04C6Ed2B840145);
        
        User memory user = User({
            id: 1,
            upline: address(0),
            directCount: uint32(0),
            userClanId:uint16(0), 
            userCountryId:uint16(0) 
        });

        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;

        users[ownerAddress].activeP1Boards[1] = true;
        users[ownerAddress].turnP1[1] = 2;
        users[ownerAddress].turnP2[1] = 2;
        p2BoardTicketCount[1]=1;
        p2Boards[1].push(Ticket(p2BoardTicketCount[1],1,false));
        activeTicketNo[1]=1;

        users[ownerAddress].activeP1Boards[2] = true;
        users[ownerAddress].turnP1[2] = 2;
        users[ownerAddress].turnP2[2] = 2;
        p2BoardTicketCount[2]=1;
        p2Boards[2].push(Ticket(p2BoardTicketCount[2],1,false));
        activeTicketNo[2]=1;

        users[ownerAddress].activeP1Boards[3] = true;
        users[ownerAddress].turnP1[3] = 2;
        users[ownerAddress].turnP2[3] = 2;
        p2BoardTicketCount[3]=1;
        p2Boards[3].push(Ticket(p2BoardTicketCount[3],1,false));
        activeTicketNo[3]=1;

        users[ownerAddress].activeP1Boards[4] = true;
        users[ownerAddress].turnP1[4] = 2;
        users[ownerAddress].turnP2[4] = 2;
        p2BoardTicketCount[4]=1;
        p2Boards[4].push(Ticket(p2BoardTicketCount[4],1,false));
        activeTicketNo[4]=1;

        users[ownerAddress].activeP1Boards[5] = true;
        users[ownerAddress].turnP1[5] = 2;
        users[ownerAddress].turnP2[5] = 2;
        p2BoardTicketCount[5]=1;
        p2Boards[5].push(Ticket(p2BoardTicketCount[5],1,false));
        activeTicketNo[5]=1;

        users[ownerAddress].activeP1Boards[6] = true;
        users[ownerAddress].turnP1[6] = 2;
        users[ownerAddress].turnP2[6] = 2;
        p2BoardTicketCount[6]=1;
        p2Boards[6].push(Ticket(p2BoardTicketCount[6],1,false));
        activeTicketNo[6]=1;

        users[ownerAddress].buyroundP1Boards[1] = 1; 
        users[ownerAddress].buyroundP2Boards[1] = 1;    
    
    }


    function() external {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        registration(msg.sender, bytesToAddress(msg.data));
    }

    
    function registrationUser(address uplineAddress) external {
        registration(msg.sender, uplineAddress);
    }
    
    
    function purchaseNewBoard(uint8 play, uint8 board) external {
        require(isUserExists(msg.sender), "userDoesNotExistRegisterFirst");
        require(usdt.allowance(msg.sender, address(this)) >= (boardPrice[board])*10**uint(TOKEN_DECIMAL), "invalidPrice");
        require(play == 1 || play == 2, "invalidPlay");
        require(board >= 1 && board <= LAST_BOARD, "invalidBoard");

        if (play == 1) {
            if(board>=2){
                require(users[msg.sender].buyroundP1Boards[board-1]>users[msg.sender].buyroundP1Boards[board], "buyPreviousBoardFirst");
                require(users[msg.sender].turnP1[board] == 0, "stillGotTurns");
                
                if (board<=3){
                    updateUserTurnP1Board123(msg.sender, board);
                } else {
                    updateUserTurnP1Board456(msg.sender, board);
                }

                users[msg.sender].buyroundP1Boards[board] +=1;
                users[msg.sender].activeP1Boards[board] = true;

                uint sales = boardPrice[board];

                address freeP1Upline = findFreeP1Upline(msg.sender, board); 
                
                updateP1Upline(msg.sender, freeP1Upline, board);
                
                emit UpgradeP1(msg.sender, freeP1Upline, 1, board, sales, users[msg.sender].buyroundP1Boards[board]);

            } else {
                // for P1 Board 1
                require(users[msg.sender].turnP1[board] == 0, "stillGotTurns");
                updateUserTurnP1Board123(msg.sender, board);
                users[msg.sender].buyroundP1Boards[board] +=1;
                users[msg.sender].activeP1Boards[board] = true;
                
            
                uint sales = boardPrice[board];
                
                address freeP1Upline = findFreeP1Upline(msg.sender, board);
                updateP1Upline(msg.sender, freeP1Upline, board);
                
                emit UpgradeP1(msg.sender, freeP1Upline, 1, board, sales, users[msg.sender].buyroundP1Boards[board]);
                  
            }
            
        } else {
            if(board>=2){
                require(users[msg.sender].buyroundP1Boards[board]>0,"buyP1sameBoardFirst" );
                require(users[msg.sender].buyroundP2Boards[board-1]>users[msg.sender].buyroundP2Boards[board], "buyPreviousBoardFirst");
                require(users[msg.sender].turnP2[board] == 0, "stillGotTurns");
                

                updateUserTurnP2 (msg.sender, board);
                users[msg.sender].buyroundP2Boards[board] +=1;
                
                updateP2Upline(msg.sender, board);

                uint sales = boardPrice[board];
                
                emit UpgradeP2(msg.sender, 2, board, sales, users[msg.sender].buyroundP2Boards[board]);

            } else {
                // for P2 Board 1
                require(users[msg.sender].turnP2[board] == 0, "stillGotTurns");
                updateUserTurnP2 (msg.sender, board);
                users[msg.sender].buyroundP2Boards[board] +=1;
                
                updateP2Upline(msg.sender, board);

                uint sales = boardPrice[board];
                
                emit UpgradeP2(msg.sender, 2, board, sales, users[msg.sender].buyroundP2Boards[board]);
            }
        }
    }

     
    function registration(address userAddress, address uplineAddress) private {
        require(usdt.allowance(msg.sender, address(this)) >= 2*(boardPrice[1])*10**uint(TOKEN_DECIMAL), "invalidPrice"); 
        require(!isUserExists(userAddress), "userExists");
        require(isUserExists(uplineAddress), "uplineNotExists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannotBeAContract");

        (uint16 userCountryId, uint16 userClanId) =  findUserCountryIdClanId(uplineAddress);

        users[uplineAddress].directCount++;
    
        User memory user = User({
            id: lastUserId,
            upline: uplineAddress,
            directCount: 0,
            userCountryId: userCountryId,
            userClanId: userClanId
        });

        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].activeP1Boards[1] = true; 
        
        users[userAddress].turnP1[1] = 2; 
        users[userAddress].turnP2[1] = 2;
        users[userAddress].buyroundP1Boards[1] = 1;
        users[userAddress].buyroundP1Boards[2] = 0;
        users[userAddress].buyroundP1Boards[3] = 0;
        users[userAddress].buyroundP1Boards[4] = 0;
        users[userAddress].buyroundP1Boards[5] = 0;
        users[userAddress].buyroundP1Boards[6] = 0;
        
        users[userAddress].buyroundP2Boards[1] = 1;
        users[userAddress].buyroundP2Boards[2] = 0;
        users[userAddress].buyroundP2Boards[3] = 0;
        users[userAddress].buyroundP2Boards[4] = 0;
        users[userAddress].buyroundP2Boards[5] = 0;
        users[userAddress].buyroundP2Boards[6] = 0;
        
        lastUserId++;

        address freeP1Upline = findFreeP1Upline(userAddress, 1);
      
        updateP1Upline(userAddress, freeP1Upline, 1);

        updateP2Upline(userAddress, 1);

        emit Registration(userAddress, uplineAddress, users[userAddress].id, users[uplineAddress].id, userCountryId, userClanId);
        
    }


    function findUserCountryIdClanId(address uplineAddress) private view returns(uint16, uint16){
        uint16 userCountryId =  users[uplineAddress].userCountryId;
        uint16 userClanId =  users[uplineAddress].userClanId;
        return (userCountryId, userClanId);
    }


    function updateP1Upline(address userAddress, address uplineAddress, uint8 board) private {
        users[uplineAddress].p1Play[board].referrals.push(userAddress);
        
        if (users[uplineAddress].p1Play[board].referrals.length < 3) {
            emit NewUserPlace(userAddress, uplineAddress, 1, board, uint8(users[uplineAddress].p1Play[board].referrals.length));
            
            emit EarnedP1(uplineAddress, msg.sender, 1, board, boardPrice[board]);

            return sendDividend(uplineAddress, board); 
        }
        
        emit NewUserPlace(userAddress, uplineAddress, 1, board, 3);
        
        users[uplineAddress].p1Play[board].referrals = new address[](0);

        if(uplineAddress != owner) {
            users[uplineAddress].turnP1[board] -=1;
            emit ReinvestP1P2(uplineAddress, 1, board, 1);
            
        }
        
        if (users[uplineAddress].turnP1[board] == 0){
            users[uplineAddress].activeP1Boards[board] = false;
            }
        
        if (uplineAddress != owner) {
            address freeUplineAddress = findFreeP1Upline(uplineAddress, board);
            updateP1Upline(uplineAddress, freeUplineAddress, board);
            
        } else {
            sendDividend(owner, board);
            emit EarnedP1(owner, msg.sender, 1, board, boardPrice[board]); 
        }
    }

    
    function updateUserTurnP1Board123 (address userAddress, uint8 board) private {
        while (board>=1) {
            users[userAddress].turnP1[board] += 2;
            board--;   
        }    
    }

    
    function updateUserTurnP1Board456 (address userAddress, uint8 board) private {
        for (uint8 j=1;j<=board;j++){
            if(j==board){
                users[userAddress].turnP1[board] += 2;
                break;
            }
            users[userAddress].turnP1[j] += 4; 
        }
    }


    function updateUserTurnP2 (address userAddress, uint8 board) private {
        while (board>=1) {
            users[userAddress].turnP2[board] += 2;
            board--;
        }
    }

    
    function updateP2Upline(address userAddress, uint8 board) private {
        p2BoardTicketCount[board]++;
        p2Boards[board].push(Ticket(p2BoardTicketCount[board],users[userAddress].id,false));
        activeTicketNo[board]++;

        emit P2TicketCount(board, p2BoardTicketCount[board], userAddress);
        
        
        if (p2Boards[board][activeTicketNo[board]-2].filled==false){
            p2Boards[board][activeTicketNo[board]-2].filled=true;
            

            uint activePlayerId = p2Boards[board][activeTicketNo[board]-2].userId;
            sendDividend(idToAddress[activePlayerId], board);
            emit EarnedP2(idToAddress[activePlayerId], 2, board, boardPrice[board]);
            emit ReinvestP1P2(idToAddress[activePlayerId], 2, board, 1);

            uint nextActivePlayerId = p2Boards[board][activeTicketNo[board]-1].userId;
            emit P2ActiveTicketNo(board, activeTicketNo[board], idToAddress[nextActivePlayerId]);
            
            if(activePlayerId!=1){
                    users[idToAddress[activePlayerId]].turnP2[board]--; 
                }
            
            if (users[idToAddress[activePlayerId]].turnP2[board]>0) {
                p2BoardTicketCount[board]++; 
                p2Boards[board].push(Ticket(p2BoardTicketCount[board],activePlayerId,false));
                emit P2TicketCount(board, p2BoardTicketCount[board], idToAddress[activePlayerId]);
            }
        }

    }

    

    
    function findFreeP1Upline(address userAddress, uint8 board) public view returns(address) {
        while (true) {
            if (users[users[userAddress].upline].activeP1Boards[board]) {
                return users[userAddress].upline;
            }
            userAddress = users[userAddress].upline;
        }
    }
    
        
    function usersActiveP1Boards(address userAddress, uint8 board) public view returns(bool) {
        return users[userAddress].activeP1Boards[board];
    }

    
    function usersP1PlayReferrals(address userAddress, uint8 board) public view returns(uint, uint) {
        if(users[userAddress].p1Play[board].referrals.length ==1){
            return (users[users[userAddress].p1Play[board].referrals[0]].id,0);
        } else {
            return (users[users[userAddress].p1Play[board].referrals[0]].id,
                users[users[userAddress].p1Play[board].referrals[1]].id);
        } 
    }

    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    
    function sendDividend(address userAddress, uint8 board) private {
        address receiver = userAddress;
        if (!usdt.transferFrom(msg.sender, receiver, (boardPrice[board])*10**uint(TOKEN_DECIMAL))) {
            usdt.transfer(owner, (usdt.balanceOf(address(this)))*10**uint(TOKEN_DECIMAL));
            return;
        }
    }

        
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }


    function withdrawLostFromBalance() public {
       require(msg.sender == owner, "onlyOwner");
       usdt.transfer(owner, usdt.balanceOf(address(this)));
    }
    

    function getUserIdUplineIdAndDirectCount(address userAddress) public view returns(uint, 
        address,uint, uint32){
        uint id = users[userAddress].id;
        address upline= users[userAddress].upline;
        uint uplineId = users[upline].id;
        uint32 directCount= users[userAddress].directCount;
        return (id,upline,uplineId,directCount);
    }


    function getUserTurnP1P2(address userAddress, uint8 p1p2play) public 
            view returns(uint32[] memory) {

        uint32[] memory turnP1P2 = new uint32[](6);
        
        if (p1p2play==1){
            
            turnP1P2[0]=users[userAddress].turnP1[1];
            turnP1P2[1]=users[userAddress].turnP1[2];
            turnP1P2[2]=users[userAddress].turnP1[3];
            turnP1P2[3]=users[userAddress].turnP1[4];
            turnP1P2[4]=users[userAddress].turnP1[5];
            turnP1P2[5]=users[userAddress].turnP1[6];

        } else {
            
            turnP1P2[0]=users[userAddress].turnP2[1];
            turnP1P2[1]=users[userAddress].turnP2[2];
            turnP1P2[2]=users[userAddress].turnP2[3];
            turnP1P2[3]=users[userAddress].turnP2[4];
            turnP1P2[4]=users[userAddress].turnP2[5];
            turnP1P2[5]=users[userAddress].turnP2[6];
        }
        return (turnP1P2);
    }

    
    function addCountryAndFirstClan(string calldata countryName, string calldata clanName, address clanMaster) external { 
        require(msg.sender==owner || msg.sender==admin || msg.sender == sysadm, "notOwnerNorAdminNorSysadm");
        
        Country memory country = Country({
            countryName: countryName,
            countryId: countryCount,
            clanCount:1
        });

        countryList[countryCount] = country;
        countryList[countryCount].clan[1]=clanName;
        countryList[countryCount].clanMaster[1]=clanMaster;

        countryCount++;
    }


    function assignCountryId(address userAddress, uint16 userCountryId)external {
        require(msg.sender==owner || msg.sender==admin || msg.sender==sysadm, "notOwnerNorAdminNorSysadm");
        users[userAddress].userCountryId=userCountryId;
    }


    function assignClanId(address userAddress, uint16 userClanId)external {
        require(msg.sender==owner || msg.sender==admin || msg.sender == sysadm, "notOwnerNorAdminNorSysadm");
        users[userAddress].userClanId=userClanId;
    }


    function addClan(uint16 countryId, string calldata clanName, address clanMaster) external { 
        require(msg.sender==owner || msg.sender==admin || msg.sender == sysadm, "notOwnerNorAdminNorSysadm");
        
        countryList[countryId].clanCount++;
        uint16 clanCounter = countryList[countryId].clanCount;
        countryList[countryId].clan[clanCounter]=clanName;
        countryList[countryId].clanMaster[clanCounter] = clanMaster;
    }


    function changeAdmin(address newAdminAddress) external {
        require(msg.sender==owner|| msg.sender == sysadm, "notOwnerNorSysadm");
        admin = newAdminAddress;
    }


    function changeSysadm(address newSysadmAddress) external {
        require(msg.sender==owner|| msg.sender == admin, "notOwnerNorAdmin");
        sysadm = newSysadmAddress;
    }

   
    function addP3Turns(address userAddress) external {
        require(msg.sender==sysadm || msg.sender==admin , "notAdminNorSysadm");
        users[userAddress].turnP1[1] += 3;
        users[userAddress].turnP1[2] += 3;
        users[userAddress].turnP1[3] += 2;
        users[userAddress].turnP1[4] += 2;
        users[userAddress].turnP1[5] += 1;
        users[userAddress].turnP1[6] += 1;

        users[userAddress].turnP2[1] += 1;
        users[userAddress].turnP2[2] += 1;
        users[userAddress].turnP2[3] += 1;
        users[userAddress].turnP2[4] += 1;
        users[userAddress].turnP2[5] += 1;
        users[userAddress].turnP2[6] += 1;   
    }

    
    function getCountryClanAndMaster(uint16 countryId, uint16 clanId) public view returns (string memory, address) {
        string memory clan = countryList[countryId].clan[clanId];
        address clanMaster = countryList[countryId].clanMaster[clanId];
        return (clan, clanMaster);
    }


    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
    
}