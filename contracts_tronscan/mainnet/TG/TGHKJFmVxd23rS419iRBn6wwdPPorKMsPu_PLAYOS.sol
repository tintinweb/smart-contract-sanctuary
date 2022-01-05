//SourceUnit: PLAYOS.sol

pragma solidity ^0.5.17; 

contract TRC20Usdt {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract PLAYOS {
    
    struct User {
        uint id;
        address upline;
        uint32 directCount;

        mapping(uint8 => bool) activeP1Boards; 

        mapping(uint8 => uint32) buyroundP1Boards; 
        mapping(uint8 => uint32) buyroundP2Boards;

        mapping(uint8 => uint32) turnP1;  
        mapping(uint8 => uint32) turnP2;

        mapping(uint8 => uint32) turnP1fromP3;  

        uint32 board1usedTurnP1;   
        uint32 board1usedTurnP2;
        
        mapping(uint8 => P1) p1Play;   

    }


    mapping (uint8 => Ticket[] ) public p2Boards; 
    mapping (uint8 => uint ) public p2BoardTicketCount; 
    mapping (uint8 => uint ) public activeTicketNo;

    
    struct Ticket {
        uint ticketNo; 
        uint userId;
        bool filled;
        }

    
    // mapping (uint => TotalUserInfo[] ) public TotalUser;

    struct TotalUserInfo {
        uint id;
        address userAddress; 
    }

    // mapping (uint8 => Ticket[] ) public p2Boards; 

    TotalUserInfo[] public totalUser;

    address usdtAddress = 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C; 
    
    
    TRC20Usdt usdt = TRC20Usdt(address(usdtAddress));

    struct P1 {
        address[] referrals;
    }

    // struct P1 {
    //     address currentUpline;
    //     address[] referrals;
    //     bool blocked;
    //     uint reinvestCount;
    // }

   
    uint8 constant LAST_BOARD = 12;
    uint8 constant TOKEN_DECIMAL = 6;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    
    uint public lastUserId = 2;
    address public owner;
    address public admin;
    address public sysadm;
    

    mapping(uint8 => uint256) public boardPrice;

    
    event Registration(address indexed user, address indexed upline, uint indexed userId, uint uplineId);
    event EarnedP1(address indexed receiver, address indexed sender, uint8 play, uint8 board, uint earnedP1);
    event EarnedP2(address indexed receiver, address indexed sender, uint8 play, uint8 board, uint earnedP2);
    event UpgradeP1(address indexed user, address indexed upline, uint8 play, uint8 board, uint sales, uint32 indexed buyroundP1P2Boards);
    event UpgradeP2(address indexed user, uint8 play, uint8 board, uint sales, uint32 indexed buyroundP1P2Boards);
    event ReinvestP1P2(address indexed user, uint8 play, uint8 board, uint8 reinvestP1P2);
    event NewUserPlace(address indexed user, address indexed upline, uint8 play, uint8 board, uint8 place);
    event P2TicketCount(uint8 board, uint number, address indexed user);
    event P2ActiveTicketNo(uint8 board, uint number, address indexed activeUser);
    event MissedUsdtReceive(address indexed receiver, address indexed from, uint8 play, uint8 board);
    event SentExtraUsdtDividends(address indexed receiver, address indexed from, uint8 play, uint8 board);
    event CanRepackage(address indexed user, uint8 play);
    event AddedP3Turns(address indexed receiver);
    event ExistingInfoAdd(address indexed userAddress, address indexed uplineAddress, uint userId, uint lastUserId);
        

    event ExistingP2TicketCount(uint8 board, uint p2BoardTicketCount, uint activeTicketNo);
    event ExistingP2TicketRow(uint userId, uint8 board, uint existingNumber);
    event ExistingP2TicketStatus(uint8 board, uint _activeTicketNo);
    
    event ExistingInfoP1TurnP1(address indexed userAddress, uint32 board1,
        uint32 board2,uint32 board3,uint32 board4,uint32 board5,uint32 board6,
        uint32 board7,uint32 board8,uint32 board9,uint32 board10,uint32 board11,
        uint32 board12);

    event ExistingInfoP1TurnP1fromP3(address indexed userAddress, uint32 board1,
        uint32 board2,uint32 board3,uint32 board4,uint32 board5,uint32 board6,
        uint32 board7,uint32 board8,uint32 board9,uint32 board10,uint32 board11,
        uint32 board12);

        
    
    event ExistingInfoP2TurnP2(address indexed userAddress, uint32 board1,
        uint32 board2,uint32 board3,uint32 board4,uint32 board5,uint32 board6,
        uint32 board7,uint32 board8,uint32 board9,uint32 board10,uint32 board11,
        uint32 board12);

    event ExistingInfoP1ActiveP1Boards(address indexed userAddress, bool board1,
        bool board2,bool board3,bool board4,bool board5,bool board6,
        bool board7,bool board8,bool board9,bool board10,bool board11,
        bool board12);

    event ExistingInfoP1BuyroundP1Boards(address indexed userAddress, uint32 board1,
        uint32 board2,uint32 board3,uint32 board4,uint32 board5,uint32 board6,
        uint32 board7,uint32 board8,uint32 board9,uint32 board10,uint32 board11,
        uint32 board12);

    event ExistingInfoP2BuyroundP2Boards(address indexed userAddress, uint32 board1,
        uint32 board2,uint32 board3,uint32 board4,uint32 board5,uint32 board6,
        uint32 board7,uint32 board8,uint32 board9,uint32 board10,uint32 board11,
        uint32 board12);

    event ExistingInfoP1Referrals(address indexed userAddress, address indexed referral1,
        address indexed referral2, uint8 board, uint referralCount);

    event ExistingInfoP1ReferralsClear(address indexed userAddress, uint8 board);

    event ExistingInfoP1Board1UsedTurnP1(address indexed userAddress, uint32 _board1usedTurnP1);

    event ExistingInfoP2Board1UsedTurnP2(address indexed userAddress, uint32 _board1usedTurnP2);

    
    


    constructor(address ownerAddress, address adminAddress) public {
        
        boardPrice[1] = 50;
        boardPrice[2] = 100;
        boardPrice[3] = 200;
        boardPrice[4] = 400;
        boardPrice[5] = 800;
        boardPrice[6] = 1600;
        boardPrice[7] = 3200;
        boardPrice[8] = 6400;
        boardPrice[9] = 12800;
        boardPrice[10] = 25600;
        boardPrice[11] = 51200;
        boardPrice[12] = 102400;
        
        
        owner = ownerAddress;
        admin = adminAddress;
        sysadm = address(0x8Cf371954EE7df79446204d3Be04C6Ed2B840145);
        
        User memory user = User({
            id: 1,
            upline: address(0),
            directCount: uint32(0),
            board1usedTurnP1:0,   
            board1usedTurnP2:0
             
        });

        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;

        // TotalUserInfo[] public totalUser;

        // struct TotalUserInfo {
        // uint id;
        // address userAddress; 
        // }

        // p2Boards[1].push(Ticket(p2BoardTicketCount[1],1,false));

        // mapping (uint8 => Ticket[] ) public p2Boards; 

        // totalUser.push(TotalUserInfo(uint id, address userAddress));

        totalUser.push(TotalUserInfo(1, ownerAddress));

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

        users[ownerAddress].activeP1Boards[7] = true;
        users[ownerAddress].turnP1[7] = 2;
        users[ownerAddress].turnP2[7] = 2;
        p2BoardTicketCount[7]=1;
        p2Boards[7].push(Ticket(p2BoardTicketCount[7],1,false));
        activeTicketNo[7]=1;

        users[ownerAddress].activeP1Boards[8] = true;
        users[ownerAddress].turnP1[8] = 2;
        users[ownerAddress].turnP2[8] = 2;
        p2BoardTicketCount[8]=1;
        p2Boards[8].push(Ticket(p2BoardTicketCount[8],1,false));
        activeTicketNo[8]=1;

        users[ownerAddress].activeP1Boards[9] = true;
        users[ownerAddress].turnP1[9] = 2;
        users[ownerAddress].turnP2[9] = 2;
        p2BoardTicketCount[9]=1;
        p2Boards[9].push(Ticket(p2BoardTicketCount[9],1,false));
        activeTicketNo[9]=1;

        users[ownerAddress].activeP1Boards[10] = true;
        users[ownerAddress].turnP1[10] = 2;
        users[ownerAddress].turnP2[10] = 2;
        p2BoardTicketCount[10]=1;
        p2Boards[10].push(Ticket(p2BoardTicketCount[10],1,false));
        activeTicketNo[10]=1;

        users[ownerAddress].activeP1Boards[11] = true;
        users[ownerAddress].turnP1[11] = 2;
        users[ownerAddress].turnP2[11] = 2;
        p2BoardTicketCount[11]=1;
        p2Boards[11].push(Ticket(p2BoardTicketCount[11],1,false));
        activeTicketNo[11]=1;

        users[ownerAddress].activeP1Boards[12] = true;
        users[ownerAddress].turnP1[12] = 2;
        users[ownerAddress].turnP2[12] = 2;
        p2BoardTicketCount[12]=1;
        p2Boards[12].push(Ticket(p2BoardTicketCount[12],1,false));
        activeTicketNo[12]=1;
        
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
                // check stillGotTurns first
                require(users[msg.sender].turnP1[board] == 0, "stillGotTurns");
                require(users[msg.sender].buyroundP1Boards[board-1]>users[msg.sender].buyroundP1Boards[board], "buyPreviousBoardFirst");


                if (board==7 && users[msg.sender].buyroundP1Boards[7]==0){
                    users[msg.sender].buyroundP1Boards[1] =1;
                    users[msg.sender].buyroundP1Boards[2] =1;
                    users[msg.sender].buyroundP1Boards[3] =1;
                    users[msg.sender].buyroundP1Boards[4] =1;
                    users[msg.sender].buyroundP1Boards[5] =1;
                    users[msg.sender].buyroundP1Boards[6] =1;
                }
                
                // if (board<=3){
                if (board<=3 || (board > 6 && board <= 9) ){
                    updateUserTurnP1Board123789(msg.sender, board);
                } else {
                    updateUserTurnP1Board456101112(msg.sender, board);
                }

                users[msg.sender].buyroundP1Boards[board] +=1;
                
                users[msg.sender].activeP1Boards[board] = true;

                uint sales = boardPrice[board];
                if (msg.sender != owner) {
                    address freeP1Upline = findFreeP1Upline(msg.sender, board);
                    // users[msg.sender].P1[board].currentUpline = freeP1Upline; // currentUpline is obsolete
                    // users[msg.sender].activeP1Boards[board] = true;
                    
                    // // findUsdtReceiverP1(address userAddress, address _from, uint8 board)
                    // (address usdtReceiver, bool __isExtraDividends) = findUsdtReceiverP1(msg.sender, msg.sender, board);

                    // if (__isExtraDividends) {
                    //     // event SentExtraUsdtDividends(address indexed receiver, address indexed from, uint8 play, uint8 board);
                    //     emit SentExtraUsdtDividends( usdtReceiver, msg.sender, 1, board);
                    // }

                    updateP1Upline(msg.sender, freeP1Upline, board);
                    // event UpgradeP1(address indexed user, address indexed upline, uint8 play, uint8 board, uint sales, uint32 indexed buyroundP1P2Boards);

                    emit UpgradeP1(msg.sender, freeP1Upline, 1, board, sales, users[msg.sender].buyroundP1Boards[board]);

                } else {
                    sendDividend(owner, 1, board);
                    emit EarnedP1(owner, msg.sender, 1, board, boardPrice[board]);
                    emit UpgradeP1(msg.sender, owner, 1, board, sales, users[msg.sender].buyroundP1Boards[board]); 
                }

            } else {
                // for P1 Board 1

                // require(users[msg.sender].turnP1[board] == 0, "stillGotTurns");
                if (users[msg.sender].buyroundP1Boards[7] ==0) {
                    
                    require(users[msg.sender].board1usedTurnP1 >=18*users[msg.sender].buyroundP1Boards[board], "notCompleteBoardsYet");
                    require(users[msg.sender].turnP1[2]==0 && users[msg.sender].turnP1[3]==0 &&
                            users[msg.sender].turnP1[4]==0 && users[msg.sender].turnP1[5]==0 &&
                            users[msg.sender].turnP1[6]==0, "stillGotTurns");
                } else if (users[msg.sender].buyroundP1Boards[7] >=1) {
                    
                    require(users[msg.sender].board1usedTurnP1 >=36*users[msg.sender].buyroundP1Boards[board], "notCompleteBoardsYet");
                    require(users[msg.sender].turnP1[2]==0 && users[msg.sender].turnP1[3]==0 &&
                            users[msg.sender].turnP1[4]==0 && users[msg.sender].turnP1[5]==0 &&
                            users[msg.sender].turnP1[6]==0 && users[msg.sender].turnP1[7]==0 &&
                            users[msg.sender].turnP1[8]==0 && users[msg.sender].turnP1[9]==0 &&
                            users[msg.sender].turnP1[10]==0 && users[msg.sender].turnP1[11]==0 &&
                            users[msg.sender].turnP1[12]==0,
                            "stillGotTurns");
                }

                
                updateUserTurnP1Board123789(msg.sender, board);

                users[msg.sender].buyroundP1Boards[board] +=1;
                users[msg.sender].activeP1Boards[board] = true;
                
                uint sales = boardPrice[board];
                
                if (msg.sender != owner) {
                    address freeP1Upline = findFreeP1Upline(msg.sender, board);

                    // // findUsdtReceiverP1(address userAddress, address _from, uint8 board)
                    // (address usdtReceiver, bool __isExtraDividends) = findUsdtReceiverP1(msg.sender, msg.sender, board);

                    // if (__isExtraDividends) {
                    //     // event SentExtraUsdtDividends(address indexed receiver, address indexed from, uint8 play, uint8 board);
                    //     emit SentExtraUsdtDividends( usdtReceiver, msg.sender, 1, board);
                    // }

                    updateP1Upline(msg.sender, freeP1Upline, board);
                    // event UpgradeP1(address indexed user, address indexed upline, uint8 play, uint8 board, uint sales, uint32 indexed buyroundP1P2Boards);

                    emit UpgradeP1(msg.sender, freeP1Upline, 1, board, sales, users[msg.sender].buyroundP1Boards[board]);

                } else {
                    sendDividend(owner, 1, board);
                    emit EarnedP1(owner, msg.sender, 1, board, boardPrice[board]);
                    emit UpgradeP1(msg.sender, owner, 1, board, sales, users[msg.sender].buyroundP1Boards[board]); 
                }
                     
            }
            
        } else {
            // P2
            if(board>=2){
                // require(users[msg.sender].buyroundP1Boards[board]>users[msg.sender].buyroundP2Boards[board],"buyP1sameBoardFirst" );
                // require(board>=2 && board <= LAST_BOARD, "invalidBoard");
                require(users[msg.sender].turnP2[board] == 0, "stillGotTurns");
                require(users[msg.sender].buyroundP1Boards[board]>0,"buyP1sameBoardFirst" );
                
                // require(users[msg.sender].buyroundP2Boards[board]==0,"buySameBoardPreviously" );
                require(users[msg.sender].buyroundP2Boards[board-1]>users[msg.sender].buyroundP2Boards[board], "buyPreviousBoardFirst");

                if (board==7 && users[msg.sender].buyroundP2Boards[7]==0){
                    users[msg.sender].buyroundP2Boards[1] =1;
                    users[msg.sender].buyroundP2Boards[2] =1;
                    users[msg.sender].buyroundP2Boards[3] =1;
                    users[msg.sender].buyroundP2Boards[4] =1;
                    users[msg.sender].buyroundP2Boards[5] =1;
                    users[msg.sender].buyroundP2Boards[6] =1;
                }
                
                updateUserTurnP2 (msg.sender, board);

                users[msg.sender].buyroundP2Boards[board] +=1;
                
                updateP2Upline(msg.sender, board);

                uint sales = boardPrice[board];
                
                emit UpgradeP2(msg.sender, 2, board, sales, users[msg.sender].buyroundP2Boards[board]);

            } 
            
            else {
                // for P2 Board 1
                // require(users[msg.sender].buyroundP1Boards[board]>users[msg.sender].buyroundP2Boards[board],"buyP1sameBoardFirst" );

                
                if (users[msg.sender].buyroundP2Boards[7] ==0) {
                    
                    require(users[msg.sender].board1usedTurnP2 >=12*users[msg.sender].buyroundP2Boards[board], "notCompleteBoardsYet");
                    require(users[msg.sender].turnP2[2]==0 && users[msg.sender].turnP2[3]==0 &&
                            users[msg.sender].turnP2[4]==0 && users[msg.sender].turnP2[5]==0 &&
                            users[msg.sender].turnP2[6]==0, "stillGotTurns");

                } else if (users[msg.sender].buyroundP2Boards[7] >=1) {
                    
                    require(users[msg.sender].board1usedTurnP2 >=24*users[msg.sender].buyroundP2Boards[board], "notCompleteBoardsYet");
                    require(users[msg.sender].turnP2[2]==0 && users[msg.sender].turnP2[3]==0 &&
                            users[msg.sender].turnP2[4]==0 && users[msg.sender].turnP2[5]==0 &&
                            users[msg.sender].turnP2[6]==0 && users[msg.sender].turnP2[7]==0 &&
                            users[msg.sender].turnP2[8]==0 && users[msg.sender].turnP2[9]==0 &&
                            users[msg.sender].turnP2[10]==0 && users[msg.sender].turnP2[11]==0 &&
                            users[msg.sender].turnP2[12]==0,"stillGotTurns");
                }

                // require(users[msg.sender].buyroundP2Boards[7] >=1 && users[msg.sender].buyroundP2Boards[board]<=1 , "notStartBoard7AndBoughtMoreThanOnce");
                
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

        users[uplineAddress].directCount++;
    
        User memory user = User({
            id: lastUserId,
            upline: uplineAddress,
            directCount: 0,
            board1usedTurnP1:0,   
            board1usedTurnP2:0
            
        });

        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;

        totalUser.push(TotalUserInfo(lastUserId, userAddress));
        
        users[userAddress].activeP1Boards[1] = true; 
        
        
        users[userAddress].turnP1[1] = 2;
        users[userAddress].turnP2[1] = 2;
        
        users[userAddress].buyroundP1Boards[1] = 1;
        
        users[userAddress].buyroundP2Boards[1] = 1;
        
        lastUserId++;

        address freeP1Upline = findFreeP1Upline(userAddress, 1);
        // // findUsdtReceiverP1(address userAddress, address _from, uint8 board)
        // (address usdtReceiver, bool __isExtraDividends) = findUsdtReceiverP1(userAddress, userAddress, 1);

        // if (__isExtraDividends) {
        //     // event SentExtraUsdtDividends(address indexed receiver, address indexed from, uint8 play, uint8 board);
        //     emit SentExtraUsdtDividends( usdtReceiver, userAddress, 1, 1);
        // }

        updateP1Upline(userAddress, freeP1Upline, 1);
        
        updateP2Upline(userAddress, 1);

        emit Registration(userAddress, uplineAddress, users[userAddress].id, users[uplineAddress].id);

    }

    
    // updateP1Upline(msg.sender, freeP1Upline, board);
    function updateP1Upline(address userAddress, address uplineAddress, uint8 board) private {

        users[uplineAddress].p1Play[board].referrals.push(userAddress);

        if (users[uplineAddress].p1Play[board].referrals.length < 3) {
            
            // Reinvest case: updateP1Upline(uplineAddress, freeUplineAddress, board);
            // For NewUserPlace, uplineAddress is not msg.sender, when reinvest,
            // and uplineAddress will take up the slot of freeUplineAddress 
            // instead of msg.sender (so it is msg.sender's uplineAddress that occupy the slot).
            // freeUplineAddress is definitely active, thus just need to check
            // if there is enough slot i.e. .length < 3

            emit NewUserPlace(userAddress, uplineAddress, 1, board, uint8(users[uplineAddress].p1Play[board].referrals.length));
            
            emit EarnedP1(uplineAddress, msg.sender, 1, board, boardPrice[board]);
            
            return sendDividend(uplineAddress, 1, board); 
        }
    
        // This is for Reinvest case, userAddress = msg.sender, uplineAddress, 
        // but the NewUserPlace = 3
        emit NewUserPlace(userAddress, uplineAddress, 1, board, 3);
        // users[uplineAddress].P1[board].reinvestCount++;
        emit ReinvestP1P2(uplineAddress, 1, board, 1);
        
        users[uplineAddress].p1Play[board].referrals = new address[](0);
 
        if (uplineAddress != owner) {
            if (users[uplineAddress].turnP1[board]>0){
                users[uplineAddress].turnP1[board] -=1;
            } else if (users[uplineAddress].turnP1fromP3[board]>0) {
                users[uplineAddress].turnP1fromP3[board] -=1;
            }
            
            if (board == 1) {
                users[uplineAddress].board1usedTurnP1 +=1;
            }

            if (users[uplineAddress].turnP1[board] == 0 && 
                users[uplineAddress].turnP1fromP3[board] == 0){
                users[uplineAddress].activeP1Boards[board] = false;
                // users[uplineAddress].P1[board].blocked = true; // blocked = true == active = false
            }

            if (users[uplineAddress].buyroundP1Boards[7] ==0) {
                if(users[uplineAddress].board1usedTurnP1 >=18*users[uplineAddress].buyroundP1Boards[board] &&
                    users[uplineAddress].turnP1[2]==0 && users[uplineAddress].turnP1[3]==0 &&
                    users[uplineAddress].turnP1[4]==0 && users[uplineAddress].turnP1[5]==0 &&
                    users[uplineAddress].turnP1[6]==0){
                        // event CanRepackage(address indexed user, uint8 play);
                        emit CanRepackage(uplineAddress, 1);
                }

            } else if (users[uplineAddress].buyroundP1Boards[7] >=1) {
                if(users[uplineAddress].board1usedTurnP1 >=36*users[uplineAddress].buyroundP1Boards[board] &&
                    users[uplineAddress].turnP1[2]==0 && users[uplineAddress].turnP1[3]==0 &&
                    users[uplineAddress].turnP1[4]==0 && users[uplineAddress].turnP1[5]==0 &&
                    users[uplineAddress].turnP1[6]==0 && users[uplineAddress].turnP1[7]==0 &&
                    users[uplineAddress].turnP1[8]==0 && users[uplineAddress].turnP1[9]==0 &&
                    users[uplineAddress].turnP1[10]==0 && users[uplineAddress].turnP1[11]==0 &&
                    users[uplineAddress].turnP1[12]==0){
                        // event CanRepackage(address indexed user, uint8 play);
                        emit CanRepackage(uplineAddress, 1);
                }
            }

            // if (users[uplineAddress].P1[board].currentUpline != freeUplineAddress) {
            //     users[uplineAddress].P1[board].currentUpline = freeUplineAddress;
            // }
            
            address freeUplineAddress = findFreeP1Upline(uplineAddress, board);

            // // findUsdtReceiverP1(address userAddress, address _from, uint8 board)
            // (address usdtReceiver, bool __isExtraDividends) = findUsdtReceiverP1(uplineAddress, uplineAddress, board);

            // if (__isExtraDividends) {
            //     // event SentExtraUsdtDividends(address indexed receiver, address indexed from, uint8 play, uint8 board);
            //     emit SentExtraUsdtDividends( usdtReceiver, uplineAddress, 1, board);
            // }

            updateP1Upline(uplineAddress, freeUplineAddress, board);
            
        } else {
            sendDividend(owner, 1, board);
            emit EarnedP1(owner, msg.sender, 1, board, boardPrice[board]); 
        }
    }


    function updateUserTurnP1Board123789 (address userAddress, uint8 board) private {
        while (board>=1) {
            
            users[userAddress].turnP1[board] += 2;
            board--;   
        }    
    }

    
    function updateUserTurnP1Board456101112 (address userAddress, uint8 board) private {
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

            if (board>=2){
                if (users[userAddress].turnP2[board-1]==0){
                    p2BoardTicketCount[board-1]++;
                    // p2Boards[board].push(Ticket(p2BoardTicketCount[board],activePlayerId,false));
                    p2Boards[board-1].push(Ticket(p2BoardTicketCount[board-1],users[userAddress].id,false));
                    emit P2TicketCount(board-1, p2BoardTicketCount[board-1], userAddress);
                }
            } 
            
            
            users[userAddress].turnP2[board] += 2;
            board--;

        }
    }

    // updateP2Upline(msg.sender, board);
    function updateP2Upline(address userAddress, uint8 board) private {
        p2BoardTicketCount[board]++;
        p2Boards[board].push(Ticket(p2BoardTicketCount[board],users[userAddress].id,false));
        activeTicketNo[board]++;

        // p2BoardTicketCount[board] ticket number for userAddress
        emit P2TicketCount(board, p2BoardTicketCount[board], userAddress); 
        
        
        // if (p2Boards[board][activeTicketNo[board]-2].filled==false){
        p2Boards[board][activeTicketNo[board]-2].filled=true;
        
        uint activePlayerId = p2Boards[board][activeTicketNo[board]-2].userId;
        sendDividend(idToAddress[activePlayerId], 2 ,board);
        // sender = userAddress
        emit EarnedP2(idToAddress[activePlayerId], userAddress,2, board, boardPrice[board]);
        emit ReinvestP1P2(idToAddress[activePlayerId], 2, board, 1);

        uint nextActivePlayerId = p2Boards[board][activeTicketNo[board]-1].userId;
        emit P2ActiveTicketNo(board, activeTicketNo[board], idToAddress[nextActivePlayerId]);
        
        if(activePlayerId!=1){
            if (users[idToAddress[activePlayerId]].turnP2[board]>0){
                users[idToAddress[activePlayerId]].turnP2[board]--;
            }
            
            if (board == 1) {
                users[idToAddress[activePlayerId]].board1usedTurnP2 +=1;
            } 

            if (users[idToAddress[activePlayerId]].buyroundP2Boards[7] ==0) {
                if(users[idToAddress[activePlayerId]].board1usedTurnP2 >=12*users[idToAddress[activePlayerId]].buyroundP2Boards[board] &&
                    users[idToAddress[activePlayerId]].turnP2[2]==0 && users[idToAddress[activePlayerId]].turnP2[3]==0 &&
                    users[idToAddress[activePlayerId]].turnP2[4]==0 && users[idToAddress[activePlayerId]].turnP2[5]==0 &&
                    users[idToAddress[activePlayerId]].turnP2[6]==0){
                        // event CanRepackage(address indexed user, uint8 play);
                        emit CanRepackage(idToAddress[activePlayerId], 2);
                }

            } else if (users[idToAddress[activePlayerId]].buyroundP2Boards[7] >=1) {
                if(users[idToAddress[activePlayerId]].board1usedTurnP2 >=24*users[idToAddress[activePlayerId]].buyroundP2Boards[board] &&
                    users[idToAddress[activePlayerId]].turnP2[2]==0 && users[idToAddress[activePlayerId]].turnP2[3]==0 &&
                    users[idToAddress[activePlayerId]].turnP2[4]==0 && users[idToAddress[activePlayerId]].turnP2[5]==0 &&
                    users[idToAddress[activePlayerId]].turnP2[6]==0 && users[idToAddress[activePlayerId]].turnP2[7]==0 &&
                    users[idToAddress[activePlayerId]].turnP2[8]==0 && users[idToAddress[activePlayerId]].turnP2[9]==0 &&
                    users[idToAddress[activePlayerId]].turnP2[10]==0 && users[idToAddress[activePlayerId]].turnP2[11]==0 &&
                    users[idToAddress[activePlayerId]].turnP2[12]==0){
                        // event CanRepackage(address indexed user, uint8 play);
                        emit CanRepackage(idToAddress[activePlayerId], 2);
                }
            }


        }
        
        if (users[idToAddress[activePlayerId]].turnP2[board]>0) {
            p2BoardTicketCount[board]++; 
            p2Boards[board].push(Ticket(p2BoardTicketCount[board],activePlayerId,false));
            emit P2TicketCount(board, p2BoardTicketCount[board], idToAddress[activePlayerId]);
        }

        // }

    }

        
    function userBoard1UsedTurnP1P2(address userAddress, uint8 play) public view returns(uint32) {
        if (play == 1) {
            return users[userAddress].board1usedTurnP1;
        } else {
            return users[userAddress].board1usedTurnP2;
        }  
    }
    
        
    function usersActiveP1Boards(address userAddress, uint8 board) public view returns(bool) {
        return users[userAddress].activeP1Boards[board];
    }

    
    function usersP1PlayReferrals(address userAddress, uint8 board) public view returns(uint, uint) {
        if(users[userAddress].p1Play[board].referrals.length ==1){
            return (users[users[userAddress].p1Play[board].referrals[0]].id,0);
        } else if (users[userAddress].p1Play[board].referrals.length ==2){
            return (users[users[userAddress].p1Play[board].referrals[0]].id,
                users[users[userAddress].p1Play[board].referrals[1]].id);
        } else {
            return (0, 0);
        }
    }

    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }


    function findFreeP1Upline(address userAddress, uint8 board) public view returns(address) {
        while (true) {
            if (users[users[userAddress].upline].activeP1Boards[board]) {
                return users[userAddress].upline;
            }
            userAddress = users[userAddress].upline;
        }
    }


    function sendDividend(address userAddress, uint8 play, uint8 board) private {
        address _from = msg.sender;

        address receiver = userAddress;

        if (play == 1) {
            // function filterMissedEndExtraP1(address receiver, uint8 board)
            (address _receiver, bool isExtraDividends) = filterMissedAndExtraP1(receiver, board);

            if (isExtraDividends) {
                    // event SentExtraUsdtDividends(address indexed receiver, address indexed from, uint8 play, uint8 board);
                    emit SentExtraUsdtDividends( _receiver, _from, play, board);
                }

            if (!usdt.transferFrom(msg.sender, receiver, (boardPrice[board])*10**uint(TOKEN_DECIMAL))) {
                usdt.transfer(owner, (usdt.balanceOf(address(this)))*10**uint(TOKEN_DECIMAL));
                return;
            }

        }
        else { // play = 2
            if (!usdt.transferFrom(msg.sender, receiver, (boardPrice[board])*10**uint(TOKEN_DECIMAL))) {
                usdt.transfer(owner, (usdt.balanceOf(address(this)))*10**uint(TOKEN_DECIMAL));
                return;
            }
        }
    }



    function filterMissedAndExtraP1(address receiver, uint8 board) private returns(address, bool) {
        // receiver is definitely users[receiver].activeP1Boards[board] = true
        // because already filtered using findFreeP1Upline
        // and receiver is definitely upline of msg.sender

        address _from = msg.sender;
        address _upline = users[msg.sender].upline;

        bool isExtraDividends; // solidity default boolean value is false

        if (msg.sender == owner){ // when owner buys board
            return (receiver, isExtraDividends);
        }

        while (true) {
            if (_upline==receiver){
                return (receiver, isExtraDividends);
            } else if (!users[_upline].activeP1Boards[board]) {
                emit MissedUsdtReceive(_upline, _from, 1, board);
                isExtraDividends = true;
                _upline = users[_upline].upline;
            } else {
                _upline = users[_upline].upline; // this is for Reinvest condition, where _upline is active
            }
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

        uint32[] memory turnP1P2 = new uint32[](12);
        
        if (p1p2play==1){
            
            turnP1P2[0]=users[userAddress].turnP1[1]+users[userAddress].turnP1fromP3[1];
            turnP1P2[1]=users[userAddress].turnP1[2]+users[userAddress].turnP1fromP3[2];
            turnP1P2[2]=users[userAddress].turnP1[3]+users[userAddress].turnP1fromP3[3];
            turnP1P2[3]=users[userAddress].turnP1[4]+users[userAddress].turnP1fromP3[4];
            turnP1P2[4]=users[userAddress].turnP1[5]+users[userAddress].turnP1fromP3[5];
            turnP1P2[5]=users[userAddress].turnP1[6]+users[userAddress].turnP1fromP3[6];
            turnP1P2[6]=users[userAddress].turnP1[7]+users[userAddress].turnP1fromP3[7];
            turnP1P2[7]=users[userAddress].turnP1[8]+users[userAddress].turnP1fromP3[8];
            turnP1P2[8]=users[userAddress].turnP1[9]+users[userAddress].turnP1fromP3[9];
            turnP1P2[9]=users[userAddress].turnP1[10]+users[userAddress].turnP1fromP3[10];
            turnP1P2[10]=users[userAddress].turnP1[11]+users[userAddress].turnP1fromP3[11];
            turnP1P2[11]=users[userAddress].turnP1[12]+users[userAddress].turnP1fromP3[12];

        } else {
            
            turnP1P2[0]=users[userAddress].turnP2[1];
            turnP1P2[1]=users[userAddress].turnP2[2];
            turnP1P2[2]=users[userAddress].turnP2[3];
            turnP1P2[3]=users[userAddress].turnP2[4];
            turnP1P2[4]=users[userAddress].turnP2[5];
            turnP1P2[5]=users[userAddress].turnP2[6];
            turnP1P2[6]=users[userAddress].turnP2[7];
            turnP1P2[7]=users[userAddress].turnP2[8];
            turnP1P2[8]=users[userAddress].turnP2[9];
            turnP1P2[9]=users[userAddress].turnP2[10];
            turnP1P2[10]=users[userAddress].turnP2[11];
            turnP1P2[11]=users[userAddress].turnP2[12];
            
        }
        return (turnP1P2);
    }


    function getUserTurnP1fromP3(address userAddress) public 
            view returns(uint32[] memory) {

        uint32[] memory turnP1P3 = new uint32[](12);
        
            turnP1P3[0]=users[userAddress].turnP1fromP3[1];
            turnP1P3[1]=users[userAddress].turnP1fromP3[2];
            turnP1P3[2]=users[userAddress].turnP1fromP3[3];
            turnP1P3[3]=users[userAddress].turnP1fromP3[4];
            turnP1P3[4]=users[userAddress].turnP1fromP3[5];
            turnP1P3[5]=users[userAddress].turnP1fromP3[6];
            turnP1P3[6]=users[userAddress].turnP1fromP3[7];
            turnP1P3[7]=users[userAddress].turnP1fromP3[8];
            turnP1P3[8]=users[userAddress].turnP1fromP3[9];
            turnP1P3[9]=users[userAddress].turnP1fromP3[10];
            turnP1P3[10]=users[userAddress].turnP1fromP3[11];
            turnP1P3[11]=users[userAddress].turnP1fromP3[12];

        return (turnP1P3);
    }

    
    function changeAdmin(address newAdminAddress) external {
        require(msg.sender==owner|| msg.sender == sysadm, "notOwnerNorSysadm");
        admin = newAdminAddress;
    }


    function changeSysadm(address newSysadmAddress) external {
        require(msg.sender==owner|| msg.sender == admin, "notOwnerNorAdmin");
        sysadm = newSysadmAddress;
    }

   
    function addP3TurnsBoard1To6(address userAddress) external {
        require(msg.sender==sysadm || msg.sender==admin , "notAdminNorSysadm");
        users[userAddress].turnP1fromP3[1] += 3;
        users[userAddress].turnP1fromP3[2] += 3;
        users[userAddress].turnP1fromP3[3] += 2;
        users[userAddress].turnP1fromP3[4] += 2;
        users[userAddress].turnP1fromP3[5] += 1;
        users[userAddress].turnP1fromP3[6] += 1;

        users[userAddress].activeP1Boards[1] = true;
        if (users[userAddress].buyroundP1Boards[2]>0){
            users[userAddress].activeP1Boards[2] = true;
        }
        if (users[userAddress].buyroundP1Boards[3]>0){
            users[userAddress].activeP1Boards[3] = true;
        }
        if (users[userAddress].buyroundP1Boards[4]>0){
            users[userAddress].activeP1Boards[4] = true;
        }
        if (users[userAddress].buyroundP1Boards[5]>0){
            users[userAddress].activeP1Boards[5] = true;
        }
        if (users[userAddress].buyroundP1Boards[6]>0){
            users[userAddress].activeP1Boards[6] = true;
        }
        
        emit AddedP3Turns(userAddress);  
    }


    function addP3TurnsBoard1To12(address userAddress) external {
        require(msg.sender==sysadm || msg.sender==admin , "notAdminNorSysadm");
        users[userAddress].turnP1fromP3[1] += 2;
        users[userAddress].turnP1fromP3[2] += 2;
        users[userAddress].turnP1fromP3[3] += 2;
        users[userAddress].turnP1fromP3[4] += 2;
        users[userAddress].turnP1fromP3[5] += 2;
        users[userAddress].turnP1fromP3[6] += 2;
        users[userAddress].turnP1fromP3[7] += 1;
        users[userAddress].turnP1fromP3[8] += 1;
        users[userAddress].turnP1fromP3[9] += 1;
        users[userAddress].turnP1fromP3[10] += 1;
        users[userAddress].turnP1fromP3[11] += 1;
        users[userAddress].turnP1fromP3[12] += 1; 

        users[userAddress].activeP1Boards[1] = true;
        if (users[userAddress].buyroundP1Boards[2]>0){
            users[userAddress].activeP1Boards[2] = true;
        }
        if (users[userAddress].buyroundP1Boards[3]>0){
            users[userAddress].activeP1Boards[3] = true;
        }
        if (users[userAddress].buyroundP1Boards[4]>0){
            users[userAddress].activeP1Boards[4] = true;
        }
        if (users[userAddress].buyroundP1Boards[5]>0){
            users[userAddress].activeP1Boards[5] = true;
        }
        if (users[userAddress].buyroundP1Boards[6]>0){
            users[userAddress].activeP1Boards[6] = true;
        }
        if (users[userAddress].buyroundP1Boards[7]>0){
            users[userAddress].activeP1Boards[7] = true;
        }
        if (users[userAddress].buyroundP1Boards[8]>0){
            users[userAddress].activeP1Boards[8] = true;
        }
        if (users[userAddress].buyroundP1Boards[9]>0){
            users[userAddress].activeP1Boards[9] = true;
        }
        if (users[userAddress].buyroundP1Boards[10]>0){
            users[userAddress].activeP1Boards[10] = true;
        }
        if (users[userAddress].buyroundP1Boards[11]>0){
            users[userAddress].activeP1Boards[11] = true;
        }
        if (users[userAddress].buyroundP1Boards[12]>0){
            users[userAddress].activeP1Boards[12] = true;
        }

        emit AddedP3Turns(userAddress);   
    }

    function existing_info_add (address userAddress, address uplineAddress, uint userId) external{
        require(msg.sender==sysadm || msg.sender==admin , "notAdminNorSysadm");

        users[uplineAddress].directCount++;

        User memory user = User({
            id: userId, // id: lastUserId,
            upline: uplineAddress,
            directCount: 0,
            board1usedTurnP1:0,   
            board1usedTurnP2:0
            
        });

        users[userAddress] = user;
        // idToAddress[lastUserId] = userAddress;
        idToAddress[userId] = userAddress;

        // totalUser.push(TotalUserInfo(lastUserId, userAddress));
        totalUser.push(TotalUserInfo(userId, userAddress));

        // users[userAddress].activeP1Boards[1] = true; ////
        
        // users[userAddress].turnP1[1] = 2; ////
        // users[userAddress].turnP2[1] = 2; ////
        
        // users[userAddress].buyroundP1Boards[1] = 1; ////
        // users[userAddress].buyroundP2Boards[1] = 1; ////
        
        lastUserId++;

        emit ExistingInfoAdd(userAddress, uplineAddress, userId, lastUserId); 
    }

    

    function existing_info_P1_turnP1 (address userAddress, uint32 board1,
        uint32 board2,uint32 board3,uint32 board4,uint32 board5,uint32 board6,
        uint32 board7,uint32 board8,uint32 board9,uint32 board10,uint32 board11,
        uint32 board12) external {
        require(msg.sender==sysadm || msg.sender==admin , "notAdminNorSysadm");

        users[userAddress].turnP1[1]=board1;
        users[userAddress].turnP1[2]=board2;
        users[userAddress].turnP1[3]=board3;
        users[userAddress].turnP1[4]=board4;
        users[userAddress].turnP1[5]=board5;
        users[userAddress].turnP1[6]=board6;
        users[userAddress].turnP1[7]=board7;
        users[userAddress].turnP1[8]=board8;
        users[userAddress].turnP1[9]=board9;
        users[userAddress].turnP1[10]=board10;
        users[userAddress].turnP1[11]=board11;
        users[userAddress].turnP1[12]=board12;

        emit ExistingInfoP1TurnP1(userAddress, board1,
        board2, board3, board4, board5, board6,
         board7, board8, board9, board10, board11, board12);
        
    }


    function existing_info_P1_turnP1fromP3 (address userAddress, uint32 board1,
        uint32 board2,uint32 board3,uint32 board4,uint32 board5,uint32 board6,
        uint32 board7,uint32 board8,uint32 board9,uint32 board10,uint32 board11,
        uint32 board12) external {
        require(msg.sender==sysadm || msg.sender==admin , "notAdminNorSysadm");

        users[userAddress].turnP1fromP3[1]=board1;
        users[userAddress].turnP1fromP3[2]=board2;
        users[userAddress].turnP1fromP3[3]=board3;
        users[userAddress].turnP1fromP3[4]=board4;
        users[userAddress].turnP1fromP3[5]=board5;
        users[userAddress].turnP1fromP3[6]=board6;
        users[userAddress].turnP1fromP3[7]=board7;
        users[userAddress].turnP1fromP3[8]=board8;
        users[userAddress].turnP1fromP3[9]=board9;
        users[userAddress].turnP1fromP3[10]=board10;
        users[userAddress].turnP1fromP3[11]=board11;
        users[userAddress].turnP1fromP3[12]=board12;

        users[userAddress].activeP1Boards[1] = true;
        if (users[userAddress].buyroundP1Boards[2]>0){
            users[userAddress].activeP1Boards[2] = true;
        }
        if (users[userAddress].buyroundP1Boards[3]>0){
            users[userAddress].activeP1Boards[3] = true;
        }
        if (users[userAddress].buyroundP1Boards[4]>0){
            users[userAddress].activeP1Boards[4] = true;
        }
        if (users[userAddress].buyroundP1Boards[5]>0){
            users[userAddress].activeP1Boards[5] = true;
        }
        if (users[userAddress].buyroundP1Boards[6]>0){
            users[userAddress].activeP1Boards[6] = true;
        }
        if (users[userAddress].buyroundP1Boards[7]>0){
            users[userAddress].activeP1Boards[7] = true;
        }
        if (users[userAddress].buyroundP1Boards[8]>0){
            users[userAddress].activeP1Boards[8] = true;
        }
        if (users[userAddress].buyroundP1Boards[9]>0){
            users[userAddress].activeP1Boards[9] = true;
        }
        if (users[userAddress].buyroundP1Boards[10]>0){
            users[userAddress].activeP1Boards[10] = true;
        }
        if (users[userAddress].buyroundP1Boards[11]>0){
            users[userAddress].activeP1Boards[11] = true;
        }
        if (users[userAddress].buyroundP1Boards[12]>0){
            users[userAddress].activeP1Boards[12] = true;
        }

        emit ExistingInfoP1TurnP1fromP3(userAddress, board1,
        board2, board3, board4, board5, board6,
         board7, board8, board9, board10, board11, board12);
        
    }




    function existing_info_P2_turnP2 (address userAddress, uint32 board1,
        uint32 board2,uint32 board3,uint32 board4,uint32 board5,uint32 board6,
        uint32 board7,uint32 board8,uint32 board9,uint32 board10,uint32 board11,
        uint32 board12) external {
        require(msg.sender==sysadm || msg.sender==admin , "notAdminNorSysadm");

        users[userAddress].turnP2[1]=board1;
        users[userAddress].turnP2[2]=board2;
        users[userAddress].turnP2[3]=board3;
        users[userAddress].turnP2[4]=board4;
        users[userAddress].turnP2[5]=board5;
        users[userAddress].turnP2[6]=board6;
        users[userAddress].turnP2[7]=board7;
        users[userAddress].turnP2[8]=board8;
        users[userAddress].turnP2[9]=board9;
        users[userAddress].turnP2[10]=board10;
        users[userAddress].turnP2[11]=board11;
        users[userAddress].turnP2[12]=board12;

        emit ExistingInfoP2TurnP2(userAddress, board1,
        board2, board3, board4, board5, board6,
         board7, board8, board9, board10, board11, board12);
        
    }




    function existing_info_P1_activeP1Boards (address userAddress) external {
        require(msg.sender==sysadm || msg.sender==admin , "notAdminNorSysadm");

        for (uint8 board=1;board<=LAST_BOARD;board++){

            if(users[userAddress].turnP1[board]>0 || users[userAddress].turnP1fromP3[board]>0){
                users[userAddress].activeP1Boards[board] = true;
            } else {
                users[userAddress].activeP1Boards[board] = false;
            }

        }

        bool board1;
        bool board2;
        bool board3;
        bool board4;
        bool board5;
        bool board6;
        bool board7;
        bool board8;
        bool board9;
        bool board10;
        bool board11;
        bool board12;

        board1=users[userAddress].activeP1Boards[1];
        board2=users[userAddress].activeP1Boards[2];
        board3=users[userAddress].activeP1Boards[3];
        board4=users[userAddress].activeP1Boards[4];
        board5=users[userAddress].activeP1Boards[5];
        board6=users[userAddress].activeP1Boards[6];
        board7=users[userAddress].activeP1Boards[7];
        board8=users[userAddress].activeP1Boards[8];
        board9=users[userAddress].activeP1Boards[9];
        board10=users[userAddress].activeP1Boards[10];
        board11=users[userAddress].activeP1Boards[11];
        board12=users[userAddress].activeP1Boards[12];

        emit ExistingInfoP1ActiveP1Boards(userAddress, board1,
        board2, board3, board4, board5, board6,
         board7, board8, board9, board10, board11, board12);
    }




    function existing_info_P1_buyroundP1Boards (address userAddress, uint32 board1,
        uint32 board2,uint32 board3,uint32 board4,uint32 board5,uint32 board6,
        uint32 board7,uint32 board8,uint32 board9,uint32 board10,uint32 board11,
        uint32 board12) external {
        require(msg.sender==sysadm || msg.sender==admin , "notAdminNorSysadm");

        users[userAddress].buyroundP1Boards[1]=board1;
        users[userAddress].buyroundP1Boards[2]=board2;
        users[userAddress].buyroundP1Boards[3]=board3;
        users[userAddress].buyroundP1Boards[4]=board4;
        users[userAddress].buyroundP1Boards[5]=board5;
        users[userAddress].buyroundP1Boards[6]=board6;
        users[userAddress].buyroundP1Boards[7]=board7;
        users[userAddress].buyroundP1Boards[8]=board8;
        users[userAddress].buyroundP1Boards[9]=board9;
        users[userAddress].buyroundP1Boards[10]=board10;
        users[userAddress].buyroundP1Boards[11]=board11;
        users[userAddress].buyroundP1Boards[12]=board12;

        emit ExistingInfoP1BuyroundP1Boards(userAddress, board1,
        board2, board3, board4, board5, board6,
         board7, board8, board9, board10, board11, board12);
        
    }


    function existing_info_P2_buyroundP2Boards (address userAddress, uint32 board1,
        uint32 board2,uint32 board3,uint32 board4,uint32 board5,uint32 board6,
        uint32 board7,uint32 board8,uint32 board9,uint32 board10,uint32 board11,
        uint32 board12) external {
        require(msg.sender==sysadm || msg.sender==admin , "notAdminNorSysadm");

        users[userAddress].buyroundP2Boards[1]=board1;
        users[userAddress].buyroundP2Boards[2]=board2;
        users[userAddress].buyroundP2Boards[3]=board3;
        users[userAddress].buyroundP2Boards[4]=board4;
        users[userAddress].buyroundP2Boards[5]=board5;
        users[userAddress].buyroundP2Boards[6]=board6;
        users[userAddress].buyroundP2Boards[7]=board7;
        users[userAddress].buyroundP2Boards[8]=board8;
        users[userAddress].buyroundP2Boards[9]=board9;
        users[userAddress].buyroundP2Boards[10]=board10;
        users[userAddress].buyroundP2Boards[11]=board11;
        users[userAddress].buyroundP2Boards[12]=board12;

        emit ExistingInfoP2BuyroundP2Boards(userAddress, board1,
        board2, board3, board4, board5, board6,
         board7, board8, board9, board10, board11, board12);
        
    }

    function existing_info_P1_referrals (address userAddress, 
        address referral1, address referral2, uint8 board) external {
        require(msg.sender==sysadm || msg.sender==admin , "notAdminNorSysadm");

        // users[uplineAddress].p1Play[board].referrals.push(userAddress);
        if (referral1 != address(0)){
            users[userAddress].p1Play[board].referrals.push(referral1);
        }

        if (referral2 != address(0)){
            users[userAddress].p1Play[board].referrals.push(referral2);
        }
        
        // users[userAddress].p1Play[board].referrals[0]
        // users[userAddress].p1Play[board].referrals[1]

        emit ExistingInfoP1Referrals(userAddress, referral1, referral2, board,
            users[userAddress].p1Play[board].referrals.length);

    }


    function existing_info_P1_referrals_clear (address userAddress, uint8 board) external {
        require(msg.sender==sysadm || msg.sender==admin , "notAdminNorSysadm");

        users[userAddress].p1Play[board].referrals= new address[](0);


        emit ExistingInfoP1ReferralsClear(userAddress, board);

    }


    
    function existing_info_P1_board1usedTurnP1 (address userAddress, 
        uint32 _board1usedTurnP1) external {
        require(msg.sender==sysadm || msg.sender==admin , "notAdminNorSysadm");

        users[userAddress].board1usedTurnP1=_board1usedTurnP1;
        
        emit ExistingInfoP1Board1UsedTurnP1(userAddress, _board1usedTurnP1);
    }


    function existing_info_P2_board1usedTurnP2 (address userAddress, 
        uint32 _board1usedTurnP2) external {
        require(msg.sender==sysadm || msg.sender==admin , "notAdminNorSysadm");

        users[userAddress].board1usedTurnP2=_board1usedTurnP2;
        
        emit ExistingInfoP2Board1UsedTurnP2(userAddress, _board1usedTurnP2);
    }


    function existing_P2_ticket_count (uint8 board, uint _p2BoardTicketCount, 
        uint _activeTicketNo) external {
        require(msg.sender==sysadm || msg.sender==admin , "notAdminNorSysadm");

        // p2BoardTicketCount[2]=1;
        // p2Boards[2].push(Ticket(p2BoardTicketCount[2],1,false));
        // activeTicketNo[2]=1;

        p2BoardTicketCount[board]=_p2BoardTicketCount;
        
        activeTicketNo[board]=_activeTicketNo;

        // event ExistingP2TicketCount(uint8 board, uint p2BoardTicketCount, uint activeTicketNo);
        emit ExistingP2TicketCount(board, _p2BoardTicketCount, _activeTicketNo);

    }

    
    function existing_P2_ticket_row (uint userId, uint8 board, uint existingNumber) external {
        require(msg.sender==sysadm || msg.sender==admin , "notAdminNorSysadm");

        // start with userId 1
        // p2Boards[board].push(Ticket(p2BoardTicketCount[board],users[userAddress].id,false));
        p2Boards[board].push(Ticket(existingNumber,userId,false));
        
        // event ExistingP2TicketRow(uint userId, uint8 board, uint existingNumber);
        emit ExistingP2TicketRow(userId, board, existingNumber);
    }


    // function existing_P2_ticket_status (uint8 board, uint number) external {
    //     require(msg.sender==sysadm || msg.sender==admin , "notAdminNorSysadm");
 
    //     //p2Boards[board][activeTicketNo[board]-2].filled=true;
    //     p2Boards[board][number].filled=true;
        
    //     emit ExistingP2TicketStatus(board, number);
    // }


    function existing_P2_ticket_status (uint8 board, uint _activeTicketNo) external {
        require(msg.sender==sysadm || msg.sender==admin , "notAdminNorSysadm");
 
        //p2Boards[board][activeTicketNo[board]-2].filled=true;
        for (uint i=0;i<=_activeTicketNo-2;i++){
            p2Boards[board][i].filled=true; 
        }
            
        emit ExistingP2TicketStatus(board, _activeTicketNo);
    }
    


    function P2_ticket_row_missed_push (uint userId, uint8 board) external {
        require(msg.sender==sysadm || msg.sender==admin , "notAdminNorSysadm");

        // p2BoardTicketCount[board]++; 
        // p2Boards[board].push(Ticket(p2BoardTicketCount[board],activePlayerId,false));
        // emit P2TicketCount(board, p2BoardTicketCount[board], idToAddress[activePlayerId]);
        
        p2BoardTicketCount[board]++; 
        p2Boards[board].push(Ticket(p2BoardTicketCount[board],userId,false));
        emit P2TicketCount(board, p2BoardTicketCount[board], idToAddress[userId]);
        
    }

    event P1P2Turn(address indexed userAddress, uint8 play, uint8 board, uint32 turn);

    function P1_turnP1 (address userAddress, uint8 board, uint32 turn) external {
        require(msg.sender==sysadm || msg.sender==admin , "notAdminNorSysadm");

        users[userAddress].turnP1[board] += turn;
        users[userAddress].activeP1Boards[board] = true;

        // event P1P2Turn(address indexed userAddress, uint8 play, uint8 board, uint32 turn);

        emit P1P2Turn(userAddress, 1, board, turn);

    }

    function P2_turnP2 (address userAddress, uint8 board, uint32 turn) external {
        require(msg.sender==sysadm || msg.sender==admin , "notAdminNorSysadm");

        if (users[userAddress].turnP2[board]==0){
            p2BoardTicketCount[board]++;
            // p2Boards[board].push(Ticket(p2BoardTicketCount[board],activePlayerId,false));
            p2Boards[board].push(Ticket(p2BoardTicketCount[board],users[userAddress].id,false));
            emit P2TicketCount(board, p2BoardTicketCount[board], userAddress);
        }

        users[userAddress].turnP2[board] += turn;

        // event P1P2Turn(address indexed userAddress, uint8 play, uint8 board, uint32 turn);

        emit P1P2Turn(userAddress, 2, board, turn);

    }

    event P3Turn(address indexed userAddress, uint8 play, uint8 board, uint32 turn);

    function P1_turnP1fromP3 (address userAddress, uint8 board, uint32 turn) external {
        require(msg.sender==sysadm || msg.sender==admin , "notAdminNorSysadm");

        users[userAddress].turnP1fromP3[board] += turn;

        if (users[userAddress].buyroundP1Boards[board]>0){
            users[userAddress].activeP1Boards[board] = true;
        }
        
        // event P3Turn(address indexed userAddress, uint8 play, uint8 board, uint32 turn);

        emit P3Turn(userAddress, 1, board, turn);

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