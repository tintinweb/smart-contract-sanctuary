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
        mapping(uint8 => uint32) turnP2fromP3;


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


                if (board==7){
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
                } else if (users[msg.sender].buyroundP1Boards[7] >=1) {
                    require(users[msg.sender].board1usedTurnP1 >=36*users[msg.sender].buyroundP1Boards[board], "notCompleteBoardsYet");
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
            if(board>=2){
                require(users[msg.sender].buyroundP1Boards[board]>0,"buyP1sameBoardFirst" );
                // check stillGotTurns first
                require(users[msg.sender].turnP2[board] == 0, "stillGotTurns");
                require(users[msg.sender].buyroundP2Boards[board-1]>users[msg.sender].buyroundP2Boards[board], "buyPreviousBoardFirst");

                if (board==7){
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

            } else {
                // for P2 Board 1

                // require(users[msg.sender].turnP2[board] == 0, "stillGotTurns");
                if (users[msg.sender].buyroundP2Boards[7] ==0) {
                    require(users[msg.sender].board1usedTurnP2 >=12*users[msg.sender].buyroundP2Boards[board], "notCompleteBoardsYet");
                } else if (users[msg.sender].buyroundP2Boards[7] >=1) {
                    require(users[msg.sender].board1usedTurnP2 >=24*users[msg.sender].buyroundP2Boards[board], "notCompleteBoardsYet");
                }

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

        
        if (users[uplineAddress].turnP1[board] == 0 && 
            users[uplineAddress].turnP1fromP3[board] == 0){
            users[uplineAddress].activeP1Boards[board] = false;
            // users[uplineAddress].P1[board].blocked = true; // blocked = true == active = false
            }
        
        if (uplineAddress != owner) {
            if (users[uplineAddress].turnP1[board]>0){
                users[uplineAddress].turnP1[board] -=1;
            } else if (users[uplineAddress].turnP1fromP3[board]>0) {
                users[uplineAddress].turnP1fromP3[board] -=1;
            }
            
            if (board == 1) {
                users[uplineAddress].board1usedTurnP1 +=1;
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
        
        
        if (p2Boards[board][activeTicketNo[board]-2].filled==false){
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
                    } else if (users[idToAddress[activePlayerId]].turnP2fromP3[board]>0){
                        users[idToAddress[activePlayerId]].turnP2fromP3[board]--;
                    }
                    
                    if (board == 1) {
                        users[idToAddress[activePlayerId]].board1usedTurnP1 +=1;
                    } 
                }
            
            if (users[idToAddress[activePlayerId]].turnP2[board]>0) {
                p2BoardTicketCount[board]++; 
                p2Boards[board].push(Ticket(p2BoardTicketCount[board],activePlayerId,false));
                emit P2TicketCount(board, p2BoardTicketCount[board], idToAddress[activePlayerId]);
            }
        }

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
        } else {
            return (users[users[userAddress].p1Play[board].referrals[0]].id,
                users[users[userAddress].p1Play[board].referrals[1]].id);
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

            if (!usdt.transferFrom(msg.sender, receiver, (boardPrice[board])*10**uint(TOKEN_DECIMAL))) {
                usdt.transfer(owner, (usdt.balanceOf(address(this)))*10**uint(TOKEN_DECIMAL));

                if (isExtraDividends) {
                    // event SentExtraUsdtDividends(address indexed receiver, address indexed from, uint8 play, uint8 board);
                    emit SentExtraUsdtDividends( _receiver, _from, play, board);
                }

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


    // function findUsdtReceiverP1(address userAddress, address _from, uint8 board) private returns(address, bool) {
    //     address receiver = users[userAddress].upline;
    //     bool isExtraDividends;
    //     while (true) {
    //         if (!users[receiver].activeP1Boards[board]) {
    //             // event MissedUsdtReceive(address indexed receiver, address indexed from, uint8 play, uint8 board);
    //             emit MissedUsdtReceive(receiver, _from, 1, board);
    //             isExtraDividends = true;
    //             // receiver = findFreeP1Upline(receiver,  board);
    //             receiver = users[receiver].upline;
    //         } else {
    //             return (receiver, isExtraDividends); // solidity default boolean value is false
    //         }
    //     }
    // }

    // // findMissedUsdtDividend, only for P1, redundant due to findUsdtReceiverP1
    // function findMissedUsdtDividend(address userAddress, address from, uint8 board) internal returns(bool) {
    //     while (true) {
    //         // if (users[users[userAddress].upline].activeP1Boards[board]) {
    //         if (users[users[userAddress].upline].activeP1Boards[board]) {
    //             return true;
    //         }

    //         // event MissedUsdtReceive(address indexed receiver, address indexed from, uint8 play, uint8 board);
    //         // emit MissedUsdtReceive(userAddress, from, 1, board);
    //         emit MissedUsdtReceive(users[userAddress].upline, from, 1, board);
    //         userAddress = users[userAddress].upline; 
    //     }
    // }

        
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
            
            turnP1P2[0]=users[userAddress].turnP2[1]+users[userAddress].turnP2fromP3[1];
            turnP1P2[1]=users[userAddress].turnP2[2]+users[userAddress].turnP2fromP3[2];
            turnP1P2[2]=users[userAddress].turnP2[3]+users[userAddress].turnP2fromP3[3];
            turnP1P2[3]=users[userAddress].turnP2[4]+users[userAddress].turnP2fromP3[4];
            turnP1P2[4]=users[userAddress].turnP2[5]+users[userAddress].turnP2fromP3[5];
            turnP1P2[5]=users[userAddress].turnP2[6]+users[userAddress].turnP2fromP3[6];
            turnP1P2[6]=users[userAddress].turnP2[7]+users[userAddress].turnP2fromP3[7];
            turnP1P2[7]=users[userAddress].turnP2[8]+users[userAddress].turnP2fromP3[8];
            turnP1P2[8]=users[userAddress].turnP2[9]+users[userAddress].turnP2fromP3[9];
            turnP1P2[9]=users[userAddress].turnP2[10]+users[userAddress].turnP2fromP3[10];
            turnP1P2[10]=users[userAddress].turnP2[11]+users[userAddress].turnP2fromP3[11];
            turnP1P2[11]=users[userAddress].turnP2[12]+users[userAddress].turnP2fromP3[12];
            
        }
        return (turnP1P2);
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

        users[userAddress].turnP2fromP3[1] += 1;
        users[userAddress].turnP2fromP3[2] += 1;
        users[userAddress].turnP2fromP3[3] += 1;
        users[userAddress].turnP2fromP3[4] += 1;
        users[userAddress].turnP2fromP3[5] += 1;
        users[userAddress].turnP2fromP3[6] += 1;   
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

        users[userAddress].turnP2fromP3[1] += 1;
        users[userAddress].turnP2fromP3[2] += 1;
        users[userAddress].turnP2fromP3[3] += 1;
        users[userAddress].turnP2fromP3[4] += 1;
        users[userAddress].turnP2fromP3[5] += 1;
        users[userAddress].turnP2fromP3[6] += 1;
        users[userAddress].turnP2fromP3[7] += 1;
        users[userAddress].turnP2fromP3[8] += 1;
        users[userAddress].turnP2fromP3[9] += 1;
        users[userAddress].turnP2fromP3[10] += 1;
        users[userAddress].turnP2fromP3[11] += 1;
        users[userAddress].turnP2fromP3[12] += 1;   
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