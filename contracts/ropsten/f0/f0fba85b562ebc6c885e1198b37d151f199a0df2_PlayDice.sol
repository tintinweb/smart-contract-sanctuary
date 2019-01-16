pragma solidity ^0.4.17;

contract PlayDice {

    struct RoomData{
        uint playerNum;
        uint roomMoney;//加入这个房间要付的单价（创建房间时候制定的那个数字）。总价直接看每个玩家的信息加起来
        uint playerEnterdCount;//用这个记录当前已经add了多少user了
        uint [6] rollNumList;
        address [6] addressList;
        uint [6] winMoneyList;
    }

    mapping (uint => RoomData) public allRoomsMap;//用来把roomID和room信息连起来
    uint maxRoomID=0;//每次ROOMID就靠它记录了，合约初始化的时候赋值为0，每次创建房间+1，作为房间ID。
    uint [] public unfinishedRoomID;//记录所有未完成房间的ID
    uint [] public hotWinRoomID;//记录hotwin的房间ID
    uint [] public finishedRoomID;//记录所有完成了的房间ID
    uint [] public winnerMoney;//记录前4名赢得最多的钱，用于比较
    address owner;
    uint commission = 0;
    // uint commissionProportion = 0+ufixed(.3); //不能定义小数 ？

    mapping (address => uint) playerRollNum;

    event sendData( );
    event LogSentRoomData(uint maxRoomID, uint playerNum, uint roomMoney, uint playerEnterdCount, uint [6] rollNumList, address [6] addressList, uint [6] winMoneyList);
    event LogSentLists(uint[] unfinishedRoomID,uint[] hotWinRoomID,uint[] finishedRoomID,uint[] winnerMoney);

    function PlayDice() {
         maxRoomID=0;
         owner = msg.sender;
    }

    // get commission money
    function getContractMoney(){
        if(msg.sender == owner){
            msg.sender.transfer( commission );
        }
    }

    //kill self
    function killContract() {
        if(msg.sender == owner){
            selfdestruct( owner );
        }
    }

    //返回20个没有完成的房间列表的id就可以了，从startID开始数20个
    function getUnfinishedRoomIDs(uint startID) public view returns(uint[20])
    {
        uint [20] backUnfinishedRoomIDs;
        for (uint i=startID-1; i<unfinishedRoomID.length; i++){
            backUnfinishedRoomIDs[i] = unfinishedRoomID[i];
        }

        LogSentRoomData( maxRoomID,  allRoomsMap[maxRoomID].playerNum,  allRoomsMap[maxRoomID].roomMoney,  allRoomsMap[maxRoomID].playerEnterdCount,  allRoomsMap[maxRoomID].rollNumList, allRoomsMap[maxRoomID].addressList,  allRoomsMap[maxRoomID].winMoneyList);
        LogSentLists(unfinishedRoomID,hotWinRoomID,finishedRoomID,winnerMoney);

        return backUnfinishedRoomIDs;
    }

    //返回20个已经完成的房间列表的id就可以了，从startID开始数20个
    function getFinishedRoomIDs(uint startID) public view returns(uint[20])
    {
        uint [20] backFinishedRoomIDs;
        for (uint i=0; i<finishedRoomID.length; i++){
            backFinishedRoomIDs[i] = finishedRoomID[i];
        }

        LogSentRoomData( maxRoomID,  allRoomsMap[maxRoomID].playerNum,  allRoomsMap[maxRoomID].roomMoney,  allRoomsMap[maxRoomID].playerEnterdCount,  allRoomsMap[maxRoomID].rollNumList, allRoomsMap[maxRoomID].addressList,  allRoomsMap[maxRoomID].winMoneyList);
        LogSentLists(unfinishedRoomID,hotWinRoomID,finishedRoomID,winnerMoney);
        
        return backFinishedRoomIDs;
    }

    //参上楼上
    function getHotWinRoomIDs() public view returns(uint[4])
    {
        uint [4] backHotWinRoomId;
        for (uint i=0; i<hotWinRoomID.length; i++){
            backHotWinRoomId[i] = hotWinRoomID[i];
        }
        return backHotWinRoomId;
    }

    //这个函数用来获取单个房间的信息，无论这个房间是在等待玩家、已经ROLL过了等待该取钱的人取钱还是什么，都通过这个来取。
    function getRoomData(uint roomID) public view returns(
        uint playerNum,
        uint roomMoney,
        uint playerEnterdCount,
        uint[6] playerRollNumList,
        address[6] playerAddressList,
        uint[6] winMoneyList
        )
    {
        // uint commissionProportion=1;
        // //  var co = 0.5;
        //  commissionProportion = commissionProportion /4;
        //玩家结构体里的三个数据，用三个list返回。从map里把这room的信息索引出来就可以了。
        LogSentRoomData( maxRoomID,  allRoomsMap[maxRoomID].playerNum,  allRoomsMap[maxRoomID].roomMoney,  allRoomsMap[maxRoomID].playerEnterdCount,  allRoomsMap[maxRoomID].rollNumList, allRoomsMap[maxRoomID].addressList,  allRoomsMap[maxRoomID].winMoneyList);
        LogSentLists(unfinishedRoomID,hotWinRoomID,finishedRoomID,winnerMoney);
        return ( allRoomsMap[roomID].playerNum,allRoomsMap[roomID].roomMoney,allRoomsMap[roomID].playerEnterdCount,allRoomsMap[roomID].rollNumList, allRoomsMap[roomID].addressList,allRoomsMap[roomID].winMoneyList  );

    }

    //这个函数创造房间，
    function createRoom( uint playerNum ) public payable returns(uint){
        //1、maxRoomID加一，暂时就让它的ID自增长，这样简单不出毛病。
        //2、创建RoomData结构体，特别注意单价一定要赋值，后面好判断
        //3、把它扔到unfinishedRoomID里
        //4、把它扔到allRoomsMap
        //5、返回新创建的这个room的ID。
        
        maxRoomID++;
        uint [6] memory rollNumList;
        rollNumList[0] = 0;
        address [6] memory addressList;
        addressList[0]=msg.sender;
        uint [6] memory winMoneyList;
        winMoneyList[0]=0;

        allRoomsMap[maxRoomID] = RoomData(playerNum, msg.value, 1, rollNumList, addressList, winMoneyList);
        unfinishedRoomID.push(maxRoomID);

        LogSentRoomData( maxRoomID,  allRoomsMap[maxRoomID].playerNum,  allRoomsMap[maxRoomID].roomMoney,  allRoomsMap[maxRoomID].playerEnterdCount,  allRoomsMap[maxRoomID].rollNumList, allRoomsMap[maxRoomID].addressList,  allRoomsMap[maxRoomID].winMoneyList);
        LogSentLists(unfinishedRoomID,hotWinRoomID,finishedRoomID,winnerMoney);
        
        return maxRoomID;

    }

    //这个函数加入房间
    function joinRoom(uint roomID) public payable{
        //1、取到这个ROOM的信息，判断它是不是满员的状态，如果满员了就算了
        //2、判断玩家给的钱和房间标榜的单价roomMoney对不对，不对就算了
        //3、都正确了把玩家加进去，不需要返回什么
        //4、加进去如果人齐了就ROLL。人不齐就算了
        //5、ROLL完了就广播下，触发完成赌博的event通知前端刷新房间信息。
        uint playerEnterdCount = allRoomsMap[roomID].playerEnterdCount;
        if ( playerEnterdCount < allRoomsMap[roomID].playerNum  ){
        LogSentRoomData( maxRoomID,  allRoomsMap[maxRoomID].playerNum,  allRoomsMap[maxRoomID].roomMoney,  allRoomsMap[maxRoomID].playerEnterdCount,  allRoomsMap[maxRoomID].rollNumList, allRoomsMap[maxRoomID].addressList,  allRoomsMap[maxRoomID].winMoneyList);
            if( msg.value == allRoomsMap[roomID].roomMoney ){
        LogSentLists(unfinishedRoomID,hotWinRoomID,finishedRoomID,winnerMoney);
                allRoomsMap[roomID].rollNumList[ playerEnterdCount ] = 0;
                allRoomsMap[roomID].addressList[ playerEnterdCount ] = msg.sender;
                allRoomsMap[roomID].winMoneyList[ playerEnterdCount ] = 0;
                allRoomsMap[roomID].playerEnterdCount++;

                if( allRoomsMap[roomID].playerEnterdCount == allRoomsMap[roomID].playerNum ){
                    roll(roomID);
                }

            }
        }

        
        
    }

    //这个函数来roll，暂时就让第二个玩家赢
    function roll(uint roomID) private {
        //1、把它从unfinished list中取走
        //2、随机数字，给每个玩家的rollNum赋值。先假随机，赋值1、2、3这么走
        //3、看着大小给每个玩家的winMoney赋值，赢家很多钱，输家是0
        //4、比对下看看能不能加到hotwinList
        //5、把它加到finishedRoomID

        uint maxNum=0;
        uint i=0;
        uint j=0;
        for ( i=0; i<allRoomsMap[roomID].playerEnterdCount; i++ ){

            address playAdd= allRoomsMap[roomID].addressList[i];

            //rollStart
            playerRollNum[playAdd] = i+1;
            allRoomsMap[roomID].rollNumList[i] = i+1;

            if (i == 1 || i == 2){
                playerRollNum[playAdd] = 6; 
                allRoomsMap[roomID].rollNumList[i] = 6; 
            }
            //rollEnd 

            if ( allRoomsMap[roomID].rollNumList[i] > maxNum ){
                maxNum = allRoomsMap[roomID].rollNumList[i];
            }

        }

        //算出谁是赢家
        address [] winnerAdd;
        for ( i=0; i<allRoomsMap[roomID].playerEnterdCount; i++ ){
            address player = allRoomsMap[roomID].addressList[i];
            if ( playerRollNum[player] == maxNum){
                winnerAdd.push( player );
            }
        }

        uint winnerM;
        for ( i=0; i<allRoomsMap[roomID].playerEnterdCount; i++ ){
            winnerM +=  allRoomsMap[roomID].roomMoney;
            allRoomsMap[roomID].winMoneyList[i] = 0;
        }
        
        //赢家数组分钱
        winnerM = winnerM / winnerAdd.length;
        for (i=0; i<allRoomsMap[roomID].playerEnterdCount; i++ ){
            for (j=0; j<winnerAdd.length; j++ ){
                if( allRoomsMap[roomID].addressList[i]==winnerAdd[j] ){
                    allRoomsMap[roomID].winMoneyList[i] = winnerM;
                }else{
                    allRoomsMap[roomID].winMoneyList[i] = 0;
                }
            }
        }

        if( hotWinRoomID.length < 4 ){
            hotWinRoomID.push(roomID);
            winnerMoney.push(winnerM);
        }else{
            if( winnerMoney[3] < winnerM ){
                hotWinRoomID[3]=roomID;
                winnerMoney[3]=winnerM;
            }
        }

        //冒泡，算出赢钱最多的房间的前4个
        uint len = hotWinRoomID.length;
        uint dRoomId;
        uint dWinnerM;

        for(i=0; i<len; i++){ 
            for(j=0; j<len; j++){ 
                uint acount1= winnerMoney[i];
                uint acount2 = winnerMoney[j];
                if( acount1 < acount2 ){ 

                    // sendData( roomId, playerNum, userArr, hasPlayer, this.balance, status );
                    dWinnerM = winnerMoney[j]; 
                    winnerMoney[j] = winnerMoney[i]; 
                    winnerMoney[i] = dWinnerM;

                    dRoomId = hotWinRoomID[j]; 
                    hotWinRoomID[j] = hotWinRoomID[i]; 
                    hotWinRoomID[i] = dRoomId;

                } 
            } 
        }

        // 此处直接delete会使数组留空位, 故先将后面的往前移，删除最后一个
        for( i=0; i<unfinishedRoomID.length; i++ ){
            if ( unfinishedRoomID[i] == roomID  ){
                break;
            }
        }

        if (i != unfinishedRoomID.length-1 ){
            for ( i; i<unfinishedRoomID.length-1; i++ ){
                unfinishedRoomID[i] = unfinishedRoomID[i+1];
            }
        }
        delete unfinishedRoomID[unfinishedRoomID.length-1];
        unfinishedRoomID.length--;

        finishedRoomID.push(roomID);

        LogSentRoomData( maxRoomID,  allRoomsMap[maxRoomID].playerNum,  allRoomsMap[maxRoomID].roomMoney,  allRoomsMap[maxRoomID].playerEnterdCount,  allRoomsMap[maxRoomID].rollNumList, allRoomsMap[maxRoomID].addressList,  allRoomsMap[maxRoomID].winMoneyList);
        LogSentLists(unfinishedRoomID,hotWinRoomID,finishedRoomID,winnerMoney);
        
    }


    //这个函数把赢得的钱取走
    function getMoney(uint roomID) payable returns (bool) {
        //1、从map中取到这个room的信息
        //2、看看这个玩家的winMoney是不是0，是0就呵呵哒
        //3、先把winMoney赋值为0，再transfer钱。因为transfer太花时间了，害怕用户利用这个时间的漏洞做攻击。

        uint i=0;
        uint amount;
        for(i; i<allRoomsMap[roomID].addressList.length; i++){
            if(msg.sender == allRoomsMap[roomID].addressList[i]){
                amount= allRoomsMap[roomID].winMoneyList[i];
                allRoomsMap[roomID].winMoneyList[i] = 0;
                break;
            }
        }

        address myAddress = this;
        
        if (amount > 0 && myAddress.balance > amount ) {
            msg.sender.transfer(amount);
        }

        return true;

    }

    //没有其它接口了，把上面的接口填充完收工。
}