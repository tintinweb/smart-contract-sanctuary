//SourceUnit: Megatron.sol

pragma solidity 0.5.9;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Megatron {
      using SafeMath for uint256;
      address public ownerWallet;
      address public leaderPoolAddress;
      address public adminAddress;
      uint public currUserID = 0;
      uint public placeNextParent = 0;
      uint public maxDownLimit = 4;
      uint public maxDownAllChildLimit = 84;
      address public parentNewAddressNew;
      address public topaddressNew;
      address public ccc;
      address public ccc1;
      uint public ccc2;
      uint public ccc3;

      struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint virtualID;
        uint referredUsers;
        uint totalEarnedreferral;
        uint currentlevel;
        mapping(uint => uint) levelExpired;
        mapping(uint => uint) totalChildCount;
        mapping (uint => uint) recyclecount;
        address[] referral;
     }

     struct PoolUserStruct {
        bool isExist;
        uint id;
        uint payment_received;
    }

    struct SuperStruct {
        uint id;
        address[] referral;
        mapping (uint => uint) reinvestcount;
        mapping (uint => address) matrixcount;
        mapping (uint => address) matrixcount1;
        mapping (uint => address) matrixcount2;
        mapping (uint => address) matrixcount3;
        mapping (uint => address) parentmatrixAddress;
        mapping (uint => bool) matrixExist;
        mapping (uint => bool) matrixvalid;
        mapping (uint => address[]) matrixchild;
        mapping (uint => address[]) directchild;
        mapping (uint => address[]) matrixchild1;
        mapping (uint => address[]) directchild1;
        mapping (uint => address[]) matrixchild2;
        mapping (uint => address[]) directchild2;
        mapping (uint => address[]) matrixchild3;
        mapping (uint => address[]) directchild3;
    }
    mapping (uint => uint) matrixUserID;
    mapping (uint => uint) eligibleUserID;

    mapping (uint => uint) matrixUserID1;
    mapping (uint => uint) eligibleUserID1;
    mapping (uint => uint) matrixUserID2;
    mapping (uint => uint) eligibleUserID2;
    mapping (uint => uint) matrixUserID3;
    mapping (uint => uint) eligibleUserID3;

    mapping (uint => uint)  matrixNextParent1;
    mapping (uint => uint)  matrixNextParent2;
    mapping (uint => uint)  matrixNextParent3;

    mapping (uint => uint)  matrixNextParent;
    mapping (uint => uint) matrixallChildInc;

    mapping (address => SuperStruct) public matrixusers;
    mapping (uint => SuperStruct) public matrixusersID;

    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    mapping (uint => uint) public LEVEL_PRICE;

    uint REGESTRATION_FESS= 250 trx;

    uint256 directreferpercentage = 500;
    uint256 indirectreferpercentage = 50;
    uint256 leaderpoolpercentage = 100;
    uint256 globalpoolpercentage = 200;

    event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
    event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _pool, uint _time, uint _price);
    event regPoolEntry(address indexed _user,uint _level,   uint _time);
    event getPoolPayment(address indexed _user,address indexed _receiver, uint _level, uint _time, uint _price);
    event getPoolSponsorPayment(address indexed _user,address indexed _receiver, uint _level, uint _time, uint _price);
    event getReInvestPoolPayment(address indexed _user, uint _level, uint _time, uint _price);

    UserStruct[] public requests;
    uint public totalEarned = 0;

    uint public nonce = 0;
    uint public ticketcounter1 = 0;
    uint public ticketcounter2 = 0;
    uint public ticketcounter3 = 0;
    uint public ticketcounter4 = 0;
    uint public ticketcounter5 = 0;
    uint public ticketcounter6 = 0;
    uint public ticketcounter7 = 0;
    uint public ticketcounter8 = 0;
    
    struct WinnerStruct {
        uint date;
        address userId;
        uint TicketId;
        uint amount;
    }
    
    struct TicketStruct {
        address userId;
        uint TicketId;
    }

    mapping (uint => uint) public PLAN;
    mapping (uint => uint) public GAME;
    mapping (uint => uint) public PRICE;
    mapping (address => uint) public UserWinning;
    mapping (address => uint) public gameBalance;
    mapping (address => uint) public UserWinningAmount;
    mapping (uint => TicketStruct[]) public ticketlist;
    mapping (uint => WinnerStruct[]) public winnerList;
    uint[] myArray;

    constructor(address _leaderPooladdress, address _adminaddress) public {
        ownerWallet = msg.sender;
        leaderPoolAddress =_leaderPooladdress;
        adminAddress =_adminaddress;
        parentNewAddressNew= address(0);
    
        LEVEL_PRICE[1] = 250 trx;
        LEVEL_PRICE[2] = 800 trx;
        LEVEL_PRICE[3] = 2560 trx;
        LEVEL_PRICE[4] = 8192 trx;
        LEVEL_PRICE[5] = 26214.4 trx;
        LEVEL_PRICE[6] = 83886.08 trx;
        LEVEL_PRICE[7] = 268435.456 trx;

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 0,
            virtualID : 0,
            referredUsers:0,
            totalEarnedreferral:0,
            currentlevel:7,
            referral : new address[](0)
        });

        users[ownerWallet] = userStruct;
        userList[currUserID] = ownerWallet;

        GAME[1]  = 25000000;
        GAME[2]  = 50000000;
        GAME[3]  = 100000000;
        GAME[4]  = 200000000;
        GAME[5]  = 500000000;
        GAME[6]  = 1000000000;
        GAME[7]  = 2000000000;
        GAME[8]  = 5000000000;
        
        PRICE[1]  = 750000000;
        PRICE[2]  = 1500000000;
        PRICE[3]  = 3000000000;
        PRICE[4]  = 6000000000;
        PRICE[5]  = 15000000000;
        PRICE[6]  = 30000000000;
        PRICE[7]  = 60000000000;
        PRICE[8]  = 100000000000;

    }

    function buyTicketWallet(uint i, uint ticketpurchse) public {
        require(users[msg.sender].isExist, "User Not Exists");
        
        uint availablePurchase = ticketpurchse;
        
        
        uint length =ticketpurchse + ticketlist[GAME[i]].length;
        if(length > 500) {
            uint excessTicket = length-500;
            availablePurchase = ticketpurchse-excessTicket;
        }
        
        uint ticketamount = availablePurchase*GAME[i];

        
        require(gameBalance[msg.sender] >= ticketamount, 'Incorrect Amount');

        gameBalance[msg.sender] = gameBalance[msg.sender]-ticketamount;

        pushTicket(i, availablePurchase);

        
    }

    function buyTicketBoth(uint i, uint ticketpurchse,uint gamewallet,uint tronwallet) public payable  {
        require(users[msg.sender].isExist, "User Not Exists");
        
        uint availablePurchase = ticketpurchse;
        
        
        uint length =ticketpurchse + ticketlist[GAME[i]].length;
        if(length > 500) {
            uint excessTicket = length-500;
            availablePurchase = ticketpurchse-excessTicket;
        }
        
        uint ticketamount = availablePurchase*GAME[i];
        
        require(ticketamount == (gamewallet*1000000)+(tronwallet*1000000), 'Incorrect Amount');
        require(msg.value == (tronwallet*1000000), 'Incorrect tron Amount');
        require(gameBalance[msg.sender] >= (gamewallet*100000), 'Incorrect wallet Amount');

        gameBalance[msg.sender] = gameBalance[msg.sender]-(gamewallet*1000000);

        pushTicket(i, availablePurchase);

        
    }

    function buyTicketTron(uint i, uint ticketpurchse) public payable  {
        if(i!=1) {
           require(users[msg.sender].isExist, "User Not Exists"); 
        }
        
        
        uint availablePurchase = ticketpurchse;
        
        
        uint length =ticketpurchse + ticketlist[GAME[i]].length;
        if(length > 500) {
            uint excessTicket = length-500;
            availablePurchase = ticketpurchse-excessTicket;
        }
        
        uint ticketamount = availablePurchase*GAME[i];

        require(msg.value == ticketamount, 'Incorrect Amount');
        pushTicket(i, availablePurchase);
        
    }

    function pushTicket(uint i, uint availablePurchase) internal  {
        TicketStruct memory ticketStruct;
        
        uint game= GAME[i];
    
        for(uint k = 0 ; k< availablePurchase ; k++){
            if(ticketlist[game].length <= 500) {
                uint ticket = geticketcount(i);
                
                ticketStruct = TicketStruct({
                    userId: msg.sender,
                    TicketId: ticket
                });
                        
                ticketlist[game].push(ticketStruct);
            }
        }
    }
 
    function pushWinners(uint i) public  {
        require(ticketlist[GAME[i]].length == 500, 'Not Valid');
        uint game= GAME[i];
        delete winnerList[game];
        uint ticketwin = 0;
        myArray.length = 0;
         for(uint t =0 ;t< 15 ;t++) {
            uint rand = getrandom();
            bool exist = checkexist(rand);
            myArray.push(rand);
            if(!exist) {
                TicketStruct memory u = ticketlist[game][rand];
                ticketwin++;
                if(ticketwin<=10){
                    Writestruct(i, u.userId, u.TicketId);
                }
                if(i == 8 &&  ticketwin==11) {
                    WritestructSpecial(i, u.userId, u.TicketId);
                }
            }
        }
        seticketcount(i);
        delete ticketlist[game];
    }
     
    function checkexist (uint inp) public view returns(bool) {
        for(uint k = 0 ; k< myArray.length; k++){
             if(myArray[k] == inp) {
                 return true;
             }
         }
         return false;
    }
    
    function WritestructSpecial(uint i, address tempUserId, uint tempTicketid) internal  {
        WinnerStruct memory winnerStruct;
        uint priceAmount = PRICE[i].mul(10);
        uint game= GAME[i];

        winnerStruct = WinnerStruct({
            date : block.timestamp,
            userId: tempUserId,
            TicketId: tempTicketid,
            amount: priceAmount
        });

        winnerList[game].push(winnerStruct);
    
        uint contractBalance = address(this).balance;
        if (contractBalance > 0) {
            UserWinningAmount[tempUserId] = UserWinningAmount[tempUserId]+priceAmount;
            UserWinning[tempUserId] = UserWinning[tempUserId]+1;
            address payable ticketwinnerAddr = address(uint160(tempUserId));
            ticketwinnerAddr.transfer(priceAmount);
        }
    }
    
    function Writestruct(uint i, address tempUserId, uint tempTicketid) internal  {
        WinnerStruct memory winnerStruct;
        uint priceAmount = PRICE[i];
        uint game= GAME[i];
          
        winnerStruct = WinnerStruct({
            date : block.timestamp,
            userId: tempUserId,
            TicketId: tempTicketid,
            amount: priceAmount
        });

        winnerList[game].push(winnerStruct);
    
        uint contractBalance = address(this).balance;
        if (contractBalance > 0) {
            UserWinningAmount[tempUserId] = UserWinningAmount[tempUserId]+priceAmount;
            UserWinning[tempUserId] = UserWinning[tempUserId]+1;
            address payable ticketwinnerAddr = address(uint160(tempUserId));
            ticketwinnerAddr.transfer(priceAmount);
        }
    }
                
    //get Ticket count
    function getGameBalance() public view returns (uint){
        return gameBalance[msg.sender];
    }

     function ticketlistCount(uint i) public view returns (uint){
        return ticketlist[GAME[i]].length;
    }
    
    //get Ticket count
    function winnerListCount(uint i) public view returns (uint){
        return winnerList[GAME[i]].length;
    }
    
    function getUserwinningAmount() public view returns(uint) {
        return UserWinningAmount[msg.sender];
    }
    
    function getUserwinningCount() public view returns(uint) {
        return UserWinning[msg.sender];
    }

    function getTicketList(uint i) public view returns(address[500] memory tic, uint[500] memory tic1) {
        for(uint k =0 ;k< ticketlist[GAME[i]].length; k++) {
            tic[k] = ticketlist[GAME[i]][k].userId;
            tic1[k] = ticketlist[GAME[i]][k].TicketId;
        }
    }
    
    //get User Ticket List
    function getWinnerList(uint i) public view returns(uint[11] memory win, address[11] memory win1,uint[11] memory win2,uint[11] memory win3) {
        for(uint k =0 ;k< winnerList[GAME[i]].length; k++) {
           win[k] = winnerList[GAME[i]][k].date;
           win1[k] = winnerList[GAME[i]][k].userId;
           win2[k] = winnerList[GAME[i]][k].TicketId;
           win3[k] = winnerList[GAME[i]][k].amount;
        }
        return (win,  win1, win2, win3);
    }
    
    
    function getrandom() internal returns(uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(now, msg.sender, nonce))) % 500;
        randomnumber = randomnumber + 1;
        nonce++;
        return randomnumber;
    }
    
    function geticketcount(uint i) internal returns(uint) {
        if(i ==1) {
            ticketcounter1++;
            return ticketcounter1;
        } else if(i ==2) {
            ticketcounter2++;
            return ticketcounter2;
        } else if(i ==3) {
            ticketcounter3++;
            return ticketcounter3;
        } else if(i ==4) {
            ticketcounter4++;
            return ticketcounter4;
        } else  if(i ==5) {
            ticketcounter5++;
            return ticketcounter5;
        } else if(i ==6) {
            ticketcounter6++;
            return ticketcounter6;
        } else if(i ==7) {
            ticketcounter7++;
            return ticketcounter7;
        } else if(i ==8) {
            ticketcounter8++;
            return ticketcounter8;
        }
    }

    function seticketcount(uint i) internal returns(uint) {
        if(i ==1) {
            ticketcounter1 = 0 ;
            return ticketcounter1;
        } else if(i ==2) {
            ticketcounter2 = 0 ;
            return ticketcounter2;
        } else if(i ==3) {
            ticketcounter3 = 0 ;
            return ticketcounter3;
        } else if(i ==4) {
            ticketcounter4 = 0 ;
            return ticketcounter4;
        } else  if(i ==5) {
            ticketcounter5 = 0 ;
            return ticketcounter5;
        } else if(i ==6) {
            ticketcounter6 = 0 ;
            return ticketcounter6;
        } else if(i ==7) {
            ticketcounter7 = 0 ;
            return ticketcounter7;
        } else if(i ==8) {
            ticketcounter8 = 0 ;
            return ticketcounter8;
        }
    }

  function payReferral(uint level,address _useraddress) internal {
      uint levelAmount = LEVEL_PRICE[level];
        address referer;
        referer = userList[users[_useraddress].referrerID];
        uint256 referAmount = levelAmount.mul(indirectreferpercentage).div(1000);
         for (uint i = 1; i <= 4; i++) {
            if(users[referer].isExist)
            {
                if(level == 1){
                    address(uint160(referer)).transfer(referAmount);
                    users[referer].totalEarnedreferral += referAmount;
                }else{
                    sendBalance(referer,referAmount);
                }
            }
            else
            {
                if(level == 1){
                    address(uint160(ownerWallet)).transfer(referAmount);
                }else{
                    sendBalance(ownerWallet,referAmount);
                }

            }
            referer = userList[users[referer].referrerID];
          }
    }

    function safepayReferral(uint level,address _useraddress) internal {
      uint levelAmount = LEVEL_PRICE[level];
        address referer;
        referer = userList[users[_useraddress].referrerID];
        uint256 referAmount = levelAmount.mul(indirectreferpercentage).div(1000);
         for (uint i = 1; i <= 4; i++) {
            if(users[referer].isExist)
            {
                if(level == 1){
                  users[referer].totalEarnedreferral += referAmount;
                }
            }
            referer = userList[users[referer].referrerID];
          }
    }

    function activatePool(uint _referrerID) public payable {
        require(!users[msg.sender].isExist, "User Exists");
        require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referral ID');
        require(msg.value == REGESTRATION_FESS, 'Incorrect Value');
        UserStruct memory userStruct;
        currUserID++;
        uint virtualID;
        virtualID = _referrerID;
        if(users[userList[virtualID]].referral.length >= maxDownLimit) virtualID = users[findFreeReferrer(userList[virtualID])].id;
        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            virtualID : virtualID,
            referredUsers:0,
            totalEarnedreferral :0,
            currentlevel:1,
            referral : new address[](0)
        });
        for(uint r=1;r<=7;r++){
           users[msg.sender].recyclecount[r]=0;
        }
        users[msg.sender] = userStruct;
        userList[currUserID]=msg.sender;
        users[userList[virtualID]].referral.push(msg.sender);
        users[userList[users[msg.sender].referrerID]].referredUsers=users[userList[users[msg.sender].referrerID]].referredUsers+1;
        emit regLevelEvent(msg.sender, userList[_referrerID], now);
        uint256 referAmount = REGESTRATION_FESS.mul(directreferpercentage).div(1000);
        bool sent = false;
        address spreferer = userList[users[msg.sender].referrerID];
         if(users[spreferer].isExist)
            {
               sent = address(uint160(spreferer)).send(referAmount);
                if (sent)
                {
                  totalEarned += referAmount;
                  users[spreferer].totalEarnedreferral += referAmount;
                }
            }
            else
            {
                address(uint160(ownerWallet)).transfer(referAmount);
            }
         //address payable leaderPooladdr = address(uint160(leaderPoolAddress));
         uint256 leaderPoolAmount = REGESTRATION_FESS.mul(leaderpoolpercentage).div(1000);
         gameBalance[msg.sender] = leaderPoolAmount;
        //  leaderPooladdr.transfer(leaderPoolAmount);
         address virtualaddr =  userList[users[msg.sender].virtualID];
         pushCountchild(1,virtualaddr,1);
         if(users[userList[virtualID]].referral.length <= maxDownLimit.div(2)){
            address topaddress = userList[users[msg.sender].virtualID];
            payForMatrix(1,address(uint160(topaddress)));
         }
         payReferral(1,spreferer);
    }

    function safeactivatePool(uint _referrerID, address _user) external {
        require(msg.sender==adminAddress,'Permission denied');
        require(!users[_user].isExist, "User Exists");
        require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referral ID');
        UserStruct memory userStruct;
        currUserID++;
        uint virtualID;
        virtualID = _referrerID;
        if(users[userList[virtualID]].referral.length >= maxDownLimit) virtualID = users[findFreeReferrer(userList[virtualID])].id;
        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            virtualID : virtualID,
            referredUsers:0,
            totalEarnedreferral :0,
            currentlevel:1,
            referral : new address[](0)
        });
        for(uint r=1;r<=7;r++){
           users[_user].recyclecount[r]=0;
        }
        users[_user] = userStruct;
        userList[currUserID]=_user;
        users[userList[virtualID]].referral.push(_user);
        users[userList[users[_user].referrerID]].referredUsers=users[userList[users[_user].referrerID]].referredUsers+1;
        emit regLevelEvent(_user, userList[_referrerID], now);
        uint256 referAmount = REGESTRATION_FESS.mul(directreferpercentage).div(1000);
       
        address spreferer = userList[users[_user].referrerID];
         if(users[spreferer].isExist)
            {
                  totalEarned += referAmount;
                  users[spreferer].totalEarnedreferral += referAmount;
            }
         //uint256 leaderPoolAmount = REGESTRATION_FESS.mul(leaderpoolpercentage).div(1000);
         gameBalance[_user] = 100;
         address virtualaddr =  userList[users[_user].virtualID];
         pushCountchild(1,virtualaddr,1);
         if(users[userList[virtualID]].referral.length <= maxDownLimit.div(2)){
            address topaddress = userList[users[_user].virtualID];
            safepayForMatrix(1,address(uint160(topaddress)));
            users[topaddress].totalEarnedreferral += LEVEL_PRICE[1];
         }
         safepayReferral(1,spreferer);
    }


    function pushCountchild(uint _level,address user,uint increment) internal {
        uint countchild = users[user].totalChildCount[_level];
        address eligibleaddress = user;

        if(users[eligibleaddress].currentlevel == _level){
            if(countchild <= 84 && user != address(0)){

                if(countchild < 84){
                    users[user].totalChildCount[_level]++;
                    address parentAddress = userList[users[user].virtualID];
                     if(parentAddress != address(0)){
                        increment = increment+1;
                        if(increment <=3){
                            pushCountchild(_level,parentAddress,increment);
                        }
                    }

                    if(users[user].totalChildCount[_level]==84){
                        users[user].totalChildCount[_level] = 0;
                        if(eligibleaddress !=ownerWallet){

                             users[eligibleaddress].recyclecount[_level]++;
                             uint recyclecountUser = users[eligibleaddress].recyclecount[_level];
                             if(recyclecountUser == 1){
                                 reactivatePool1(_level,eligibleaddress);
                             }else if(recyclecountUser == 2){
                                 reactivatePool2(_level,eligibleaddress);
                             }else if(recyclecountUser == 3){
                                 reactivatePool3(_level,eligibleaddress);
                             }

                             uint nextlevel =  _level.add(1);
                             payforProfit(_level,eligibleaddress);
                             buyNextLevel(nextlevel,eligibleaddress);
                             matrixusers[eligibleaddress].matrixvalid[nextlevel] = true;
                             users[eligibleaddress].currentlevel = nextlevel;
                        }
                    }

                }else{

                    users[user].totalChildCount[_level] = 0;
                    if(eligibleaddress !=ownerWallet){

                         users[eligibleaddress].recyclecount[_level]++;
                         uint recyclecountUser = users[eligibleaddress].recyclecount[_level];
                         if(recyclecountUser == 1){
                             reactivatePool1(_level,eligibleaddress);
                         }else if(recyclecountUser == 2){
                             reactivatePool2(_level,eligibleaddress);
                         }else if(recyclecountUser == 3){
                             reactivatePool3(_level,eligibleaddress);
                         }

                         uint nextlevel =  _level.add(1);
                         payforProfit(_level,eligibleaddress);
                         buyNextLevel(nextlevel,eligibleaddress);
                         matrixusers[eligibleaddress].matrixvalid[nextlevel] = true;
                         users[eligibleaddress].currentlevel = nextlevel;
                    }

                }
            }

        }

    }

    function payforProfit(uint level, address profitaddr) private {

        uint levelAmount = LEVEL_PRICE[level];
        uint256 globalPoolAmount = levelAmount.mul(globalpoolpercentage).div(1000);
        uint profitPrice = globalPoolAmount * 11;
        address payable leaderPollAddr = address(uint160(profitaddr));
        leaderPollAddr.transfer(profitPrice);
        users[profitaddr].totalEarnedreferral += profitPrice;

    }

    function reactivatePool1(uint level,address user) private {
        uint levelAmount = LEVEL_PRICE[level];
        matrixUserID1[level]++;
        matrixusersID[matrixUserID1[level]].matrixcount1[level]  = user;
        address topaddress = matrixusersID[matrixNextParent1[level]].matrixcount1[level];
        address eligibleaddress = matrixusersID[eligibleUserID1[level]].matrixcount1[level];

        matrixusers[topaddress].directchild1[level].push(user);

        if(matrixusers[topaddress].directchild1[level].length <= maxDownLimit.div(2)){
            payForMatrix(level,address(uint160(topaddress)));
        }

        pushmatrixchild1(level,user,topaddress);

        if(matrixusers[eligibleaddress].matrixchild1[level].length >= maxDownAllChildLimit ){

            if(eligibleaddress !=ownerWallet){

                 users[eligibleaddress].recyclecount[level]++;
                 uint recyclecountUser = users[eligibleaddress].recyclecount[level];
                 if(recyclecountUser == 1){
                     reactivatePool1(level,eligibleaddress);
                 }else if(recyclecountUser == 2){
                     reactivatePool2(level,eligibleaddress);
                 }else if(recyclecountUser == 3){
                     reactivatePool3(level,eligibleaddress);
                 }

                 uint nextlevel =  level.add(1);
                 payforProfit(level,eligibleaddress);
                 buyNextLevel(nextlevel,eligibleaddress);
                 matrixusers[eligibleaddress].matrixvalid[nextlevel] = true;
                 users[eligibleaddress].currentlevel = nextlevel;
            }

            eligibleUserID1[level]++;
        }

        if(matrixusers[topaddress].directchild1[level].length >= maxDownLimit ){
          matrixNextParent1[level]++;
        }
        uint256 referAmount = levelAmount.mul(directreferpercentage).div(1000);
        bool sent = false;
        address payable spreferer = address(uint160(userList[users[user].referrerID]));
         if(users[spreferer].isExist)
            {
               sent = address(spreferer).send(referAmount);
                if (sent)
                {
                  totalEarned += referAmount;
                  users[spreferer].totalEarnedreferral += referAmount;
                }
            }
            else
            {
                address(uint160(ownerWallet)).transfer(referAmount);
            }
         uint256 leaderPoolAmount = levelAmount.mul(leaderpoolpercentage).div(1000);
         gameBalance[user] += leaderPoolAmount;
         //address payable leaderPollAddr = address(uint160(leaderPoolAddress));
         //leaderPollAddr.transfer(leaderPoolAmount);
         //pushCountchild(level,user);
         //placeAutopool(level,user);
         payReferral(level,spreferer);

    }

    function reactivatePool2(uint level,address user) private {
        uint levelAmount = LEVEL_PRICE[level];
        matrixUserID2[level]++;
        matrixusersID[matrixUserID2[level]].matrixcount2[level]  = user;
        address topaddress = matrixusersID[matrixNextParent2[level]].matrixcount2[level];
        address eligibleaddress = matrixusersID[eligibleUserID2[level]].matrixcount2[level];

        matrixusers[topaddress].directchild2[level].push(user);
        if(matrixusers[topaddress].directchild2[level].length <= maxDownLimit.div(2)){
            payForMatrix(level,address(uint160(topaddress)));
        }

        pushmatrixchild2(level,user,topaddress);

        if(matrixusers[eligibleaddress].matrixchild2[level].length >= maxDownAllChildLimit ){

            if(eligibleaddress !=ownerWallet){

                 users[eligibleaddress].recyclecount[level]++;
                 uint recyclecountUser = users[eligibleaddress].recyclecount[level];
                 if(recyclecountUser == 1){
                     reactivatePool1(level,eligibleaddress);
                 }else if(recyclecountUser == 2){
                     reactivatePool2(level,eligibleaddress);
                 }else if(recyclecountUser == 3){
                     reactivatePool3(level,eligibleaddress);
                 }

                 uint nextlevel =  level.add(1);
                 payforProfit(level,eligibleaddress);
                 buyNextLevel(nextlevel,eligibleaddress);
                 matrixusers[eligibleaddress].matrixvalid[nextlevel] = true;
                 users[eligibleaddress].currentlevel = nextlevel;
            }

            eligibleUserID2[level]++;
        }

        if(matrixusers[topaddress].directchild2[level].length >= maxDownLimit ){
          matrixNextParent2[level]++;
        }
        uint256 referAmount = levelAmount.mul(directreferpercentage).div(2000);
        bool sent = false;
        address payable spreferer = address(uint160(userList[users[user].referrerID]));
         if(users[spreferer].isExist)
            {
               sent = address(spreferer).send(referAmount);
                if (sent)
                {
                  totalEarned += referAmount;
                  users[spreferer].totalEarnedreferral += referAmount;
                }
            }
            else
            {
                address(uint160(ownerWallet)).transfer(referAmount);
            }
         uint256 leaderPoolAmount = levelAmount.mul(leaderpoolpercentage).div(2000);
         gameBalance[user] += leaderPoolAmount;
         //address payable leaderPollAddr = address(uint160(leaderPoolAddress));
         //leaderPollAddr.transfer(leaderPoolAmount);
         //pushCountchild(level,user);
         //placeAutopool(level,user);
         payReferral(level,spreferer);

    }

    function reactivatePool3(uint level,address user) private {
        uint levelAmount = LEVEL_PRICE[level];
        matrixUserID3[level]++;
        matrixusersID[matrixUserID3[level]].matrixcount3[level]  = user;
        address topaddress = matrixusersID[matrixNextParent3[level]].matrixcount3[level];
        address eligibleaddress = matrixusersID[eligibleUserID3[level]].matrixcount3[level];

        matrixusers[topaddress].directchild3[level].push(user);
        if(matrixusers[topaddress].directchild3[level].length <= maxDownLimit.div(2)){
            payForMatrix(level,address(uint160(topaddress)));
        }

        pushmatrixchild3(level,user,topaddress);

        if(matrixusers[eligibleaddress].matrixchild3[level].length >= maxDownAllChildLimit ){

            if(eligibleaddress !=ownerWallet){
                 uint nextlevel =  level.add(1);
                 users[eligibleaddress].recyclecount[level]++;
                 payforProfit(level,eligibleaddress);
                 matrixusers[eligibleaddress].matrixvalid[nextlevel] = true;
                 users[eligibleaddress].currentlevel = nextlevel;
            }
            eligibleUserID3[level]++;
        }

        if(matrixusers[topaddress].directchild3[level].length >= maxDownLimit ){
          matrixNextParent3[level]++;
        }
        uint256 referAmount = levelAmount.mul(directreferpercentage).div(2000);
        bool sent = false;
        address payable spreferer = address(uint160(userList[users[user].referrerID]));
         if(users[spreferer].isExist)
            {
               sent = address(spreferer).send(referAmount);
                if (sent)
                {
                  totalEarned += referAmount;
                  users[spreferer].totalEarnedreferral += referAmount;
                }
            }
            else
            {
                address(uint160(ownerWallet)).transfer(referAmount);
            }
         uint256 leaderPoolAmount = levelAmount.mul(leaderpoolpercentage).div(2000);
         gameBalance[user] += leaderPoolAmount;
         //address payable leaderPollAddr = address(uint160(leaderPoolAddress));
         //leaderPollAddr.transfer(leaderPoolAmount);
         payReferral(level,spreferer);
    }



    function pushmatrixchild(uint _level,address matrixbuyer,address parentaddress) internal {
        if(matrixusers[parentaddress].matrixchild[_level].length < 84){

         matrixusers[parentaddress].matrixchild[_level].push(matrixbuyer);
         address parentNewAddress = matrixusers[parentaddress].parentmatrixAddress[_level];
         ccc1 = parentNewAddress;
          if(parentNewAddress == ownerWallet){
              if(matrixusers[parentNewAddress].matrixchild[_level].length < 84){
                 matrixusers[parentNewAddress].matrixchild[_level].push(matrixbuyer);
              }
          }else{
              if(parentNewAddress != parentNewAddressNew){
                  pushmatrixchild(_level,matrixbuyer,parentNewAddress);
              }
          }

        }
    }

    function pushmatrixchild1(uint _level,address matrixbuyer,address parentaddress) internal {
        if(matrixusers[parentaddress].matrixchild1[_level].length < 84){
         matrixusers[parentaddress].matrixchild1[_level].push(matrixbuyer);
         address parentNewAddress = matrixusers[parentaddress].parentmatrixAddress[_level];
          if(parentNewAddress == ownerWallet){
              if(matrixusers[parentNewAddress].matrixchild1[_level].length < 84){
                 matrixusers[parentNewAddress].matrixchild1[_level].push(matrixbuyer);
              }
          }else{
              if(parentNewAddress != parentNewAddressNew){
                  pushmatrixchild1(_level,matrixbuyer,parentNewAddress);
              }
          }

        }
    }


    function pushmatrixchild2(uint _level,address matrixbuyer,address parentaddress) internal {
        if(matrixusers[parentaddress].matrixchild2[_level].length < 84){
         matrixusers[parentaddress].matrixchild2[_level].push(matrixbuyer);
         address parentNewAddress = matrixusers[parentaddress].parentmatrixAddress[_level];
          if(parentNewAddress == ownerWallet){
              if(matrixusers[parentNewAddress].matrixchild2[_level].length < 84){
                 matrixusers[parentNewAddress].matrixchild2[_level].push(matrixbuyer);
              }
          }else{
              if(parentNewAddress != parentNewAddressNew){
                  pushmatrixchild2(_level,matrixbuyer,parentNewAddress);
              }
          }

        }
    }


    function pushmatrixchild3(uint _level,address matrixbuyer,address parentaddress) internal {
        if(matrixusers[parentaddress].matrixchild3[_level].length < 84){
         matrixusers[parentaddress].matrixchild3[_level].push(matrixbuyer);
         address parentNewAddress = matrixusers[parentaddress].parentmatrixAddress[_level];
          if(parentNewAddress == ownerWallet){
              if(matrixusers[parentNewAddress].matrixchild3[_level].length < 84){
                 matrixusers[parentNewAddress].matrixchild3[_level].push(matrixbuyer);
              }
          }else{
              if(parentNewAddress != parentNewAddressNew){
                  pushmatrixchild3(_level,matrixbuyer,parentNewAddress);
              }
          }

        }
    }


    function recyclecount(address _user) public view returns(uint[7] memory recyclecount1) {
        for (uint i = 0; i<7; i++) {
            recyclecount1[i] = users[_user].recyclecount[i+1];
        }
    }


    function buyNextLevel(uint level,address user) private {
        if(level <=7){
            uint levelAmount = LEVEL_PRICE[level];
            matrixUserID[level]++;
            matrixusersID[matrixUserID[level]].matrixcount[level]  = user;
            address topaddress = matrixusersID[matrixNextParent[level]].matrixcount[level];
            address eligibleaddress = matrixusersID[eligibleUserID[level]].matrixcount[level];

            matrixusers[topaddress].directchild[level].push(user);
            if(matrixusers[topaddress].directchild[level].length <= maxDownLimit.div(2)){
                payForMatrix(level,address(uint160(topaddress)));
            }
            ccc = topaddress;
            ccc3 =2;
            pushmatrixchild(level,user,topaddress);

            if(matrixusers[eligibleaddress].matrixchild[level].length >= maxDownAllChildLimit ){
                eligibleUserID[level]++;
            }

            if(matrixusers[topaddress].directchild[level].length >= maxDownLimit ){
              matrixNextParent[level]++;
            }
            uint256 referAmount = levelAmount.mul(directreferpercentage).div(1000);
            bool sent = false;
            address payable spreferer = address(uint160(userList[users[user].referrerID]));
             if(users[spreferer].isExist)
                {
                   sent = address(spreferer).send(referAmount);
                    if (sent)
                    {
                      totalEarned += referAmount;
                      users[spreferer].totalEarnedreferral += referAmount;
                    }
                }
                else
                {
                    address(uint160(ownerWallet)).transfer(referAmount);
                }
             uint256 leaderPoolAmount = levelAmount.mul(leaderpoolpercentage).div(1000);
             gameBalance[user] += leaderPoolAmount;
             //address payable leaderPollAddr = address(uint160(leaderPoolAddress));
             //leaderPollAddr.transfer(leaderPoolAmount);
             //pushCountchild(level,user);
             //placeAutopool(level,user);
             payReferral(level,spreferer);
        }

    }

    function safepayForMatrix(uint level,address payable _user) internal {
         uint levelAmount = LEVEL_PRICE[level];
         uint256 globalPoolAmount = levelAmount.mul(globalpoolpercentage).div(1000);
         users[_user].totalEarnedreferral += globalPoolAmount;
    }

    function payForMatrix(uint level,address payable _user) internal {
         uint levelAmount = LEVEL_PRICE[level];
         uint256 globalPoolAmount = levelAmount.mul(globalpoolpercentage).div(1000);
         users[_user].totalEarnedreferral += globalPoolAmount;
         _user.transfer(globalPoolAmount);
    }

    function getTrxBalance() public view returns(uint) {
       return address(this).balance;
    }

    function sendBalance(address user,uint amount) private
    {

        if(getTrxBalance() >= amount){
            if(address(uint160(user)).send(amount)){

            }
        }
    }

     function findFreeReferrer(address _user) public view returns(address) {
        if(users[_user].referral.length < maxDownLimit) return _user;
        address[] memory referrals = new address[](500);
        referrals[0] = users[_user].referral[0];
        referrals[1] = users[_user].referral[1];
        referrals[2] = users[_user].referral[2];
        referrals[3] = users[_user].referral[3];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 500; i++) {
            if(users[referrals[i]].referral.length == maxDownLimit) {
                //if(i < 62) {
                    referrals[(i+1)*4] = users[referrals[i]].referral[0];
                    referrals[(i+1)*4+1] = users[referrals[i]].referral[1];
                    referrals[(i+1)*4+2] = users[referrals[i]].referral[2];
                    referrals[(i+1)*4+3] = users[referrals[i]].referral[3];
                //}
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }

        require(!noFreeReferrer, 'No Free Referrer');

        return freeReferrer;
    }


    function getMatrixchildcount(address _user,uint matrixlevel) public view returns(uint) {
        return matrixusers[_user].matrixchild[matrixlevel].length;
    }

    function getMatrixchildcountList(address _user,uint matrixlevel) public view returns(address[] memory) {
        return matrixusers[_user].matrixchild[matrixlevel];
    }

    function getDirectChildcountList(address _user,uint matrixlevel) public view returns(address[] memory) {
        return matrixusers[_user].directchild[matrixlevel];
    }

    function getMatrixCount(uint mcount,uint matrixlevel) public view returns(address) {
        return matrixusersID[mcount].matrixcount[matrixlevel];
    }

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }
    function getTotalcount(address _user,uint matrixlevel) public view returns(uint) {
        return users[_user].totalChildCount[matrixlevel];
    }
    function getMatrixchildcountList1(address _user,uint matrixlevel) public view returns(address[] memory) {
        return matrixusers[_user].matrixchild1[matrixlevel];
    }
    function getMatrixchildcountList2(address _user,uint matrixlevel) public view returns(address[] memory) {
        return matrixusers[_user].matrixchild2[matrixlevel];
    }
    function getMatrixchildcountList3(address _user,uint matrixlevel) public view returns(address[] memory) {
        return matrixusers[_user].matrixchild3[matrixlevel];
    }
    function getDirectChildcountList1(address _user,uint matrixlevel) public view returns(address[] memory) {
        return matrixusers[_user].directchild1[matrixlevel];
    }
    function getDirectChildcountList2(address _user,uint matrixlevel) public view returns(address[] memory) {
        return matrixusers[_user].directchild2[matrixlevel];
    }
    function getDirectChildcountList3(address _user,uint matrixlevel) public view returns(address[] memory) {
        return matrixusers[_user].directchild3[matrixlevel];
    }




     function withdrawSafe( uint _amount) external {
        require(msg.sender==ownerWallet,'Permission denied');
        if (_amount > 0) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint amtToTransfer = _amount > contractBalance ? contractBalance : _amount;
                msg.sender.transfer(amtToTransfer);
            }
        }
    }

    function safeEntry( ) external {
        require(msg.sender==ownerWallet,'Permission denied');
        for(uint m=1;m<=7;m++){
            matrixUserID[m] = 1;
            matrixUserID1[m] = 1;
            matrixUserID2[m] = 1;
            matrixUserID3[m] = 1;
            eligibleUserID[m] =1;
            matrixNextParent[m] = 1;
            matrixNextParent1[m] = 1;
            matrixNextParent2[m] = 1;
            matrixNextParent3[m] = 1;
            matrixusersID[1].matrixcount[m]  = ownerWallet;
            matrixusersID[1].matrixcount1[m]  = ownerWallet;
            matrixusersID[1].matrixcount2[m]  = ownerWallet;
            matrixusersID[1].matrixcount3[m]  = ownerWallet;
            users[ownerWallet].recyclecount[m]=0;
        }

    }
}