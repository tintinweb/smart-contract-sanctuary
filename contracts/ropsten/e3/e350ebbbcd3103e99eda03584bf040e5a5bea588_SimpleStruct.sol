//Write your own contracts here. Currently compiles using solc v0.4.15+commit.bbb8e64f.
pragma solidity ^0.4.24;
// pragma experimental ABIEncoderV2;

contract SimpleStruct {


    // address public owner;
    byte mask_front = 0xF0; //0xF0
    byte mask_back = 0x0F;  //0x0F
    uint public currentGameId = 0;
    uint numberCount =  3;
    uint[] public testArr2;
    uint public testArr2Length = 0;
    uint private nonce = 0;

    //event
      event TaskAwardNumber(uint number, uint totalWinner, uint pricePerTicket , uint timestamp);

//   constructor() public {
//         owner = msg.sender;
//     }



    struct  Game {
        uint draw;
        uint winNumbers;
        address[] winNumbersByAddress;
        uint totalWinnerPlayer;
        uint totalTicket;
        uint totalPlayer;
        uint price;
        uint pricePerTicket;
        uint totalAmount;
        uint startDate;
        uint endDate;
    }


    struct Active {
        Ticket[] numbers;
        uint numberRecent;
        uint totalTicket;
        address user;
    }

    struct Played {
        Ticket[] numbers;
        uint numberRecent;
        uint totalTicket;
        address user;
    }

    struct Ticket {
        address user;
        uint numbers;
        uint status;
        uint game_id;
    }

    struct Luckies {
        uint game_id;
        uint totalPlayed;
        mapping(uint => Number) number;
    }

    struct Number {
        address[] user;
    }

    mapping(uint => Game ) public games;
    mapping(uint => Luckies ) public luckies;

    mapping(address => Active ) public actives;
    address[] public activeList;

    mapping(address => Played ) public playeds;
    address[] public playedList;




    function setGame() public {
        Game storage dataGame = games[currentGameId];
        dataGame.price = 10;
        dataGame.draw = currentGameId;
        dataGame.totalPlayer = 0;
        dataGame.totalAmount = 0;
        dataGame.startDate = now;
        dataGame.endDate = now;
        dataGame.winNumbers = 0;

    }

    function setLucky() public {
        Luckies storage dataLucky = luckies[currentGameId];
        dataLucky.game_id  = currentGameId;
        dataLucky.totalPlayed = 0;
    }



  function setActive(address _address , uint _numbers ) public {

        Active storage data = actives[_address];
        data.numberRecent = _numbers;

        data.numbers.push(Ticket({
            user : _address ,
            numbers : _numbers,
            game_id : currentGameId,
            status: 0
        }));

        data.totalTicket += 1;
        data.user = _address;

        /* valid activeList for references. */
        uint index_address;
        bool validIndex;
        for(uint i = 0 ; i < activeList.length ; i++){
            if(activeList[i] == _address ){
                index_address = i;
                validIndex = true;
                break;
            }else{
                validIndex = false;
            }
        }
        if(validIndex == false){
            games[currentGameId].totalPlayer += 1;
            activeList.push(_address);
        }


  }




  function resetActive() public{
        for(uint i = 0; i < activeList.length ; i++){
            delete actives[activeList[i]];
            delete activeList[i];
        }
        activeList = [msg.sender];
        currentGameId += 1;
        setGame();
  }





//   uint public lengthArrTicketActive;
//   uint public lengthArrList;
  function cloneActiveToPlayed() public {
        uint lengthArrList = activeList.length;

        for(uint i = 0;  i < activeList.length ; i++){
            Played storage newData = playeds[activeList[i]];
            newData.numberRecent =  actives[activeList[i]].numberRecent;
            newData.totalTicket +=  actives[activeList[i]].totalTicket;
            newData.user =  actives[activeList[i]].user;

            /* Push number ticket into struct of Playeds array.*/
            uint lengthArrTicketActive =  actives[activeList[i]].numbers.length;
            for(uint k = 0 ; k < actives[activeList[i]].numbers.length; k++){
                newData.numbers.push(Ticket({
                    status: actives[activeList[i]].numbers[k].status,
                    // status : 1,
                    game_id : actives[activeList[i]].numbers[k].game_id,
                    user: actives[activeList[i]].user,
                    numbers : actives[activeList[i]].numbers[k].numbers
                }));
            }

            uint index_address;
            bool validIndex;

            for(uint j = 0 ; j < playedList.length ; j++){
                if(playedList[j] == activeList[i] ){
                    index_address = i;
                    validIndex = true;
                    break;
                }else{
                    validIndex = false;
                }
            }
            if(validIndex == false){
                playedList.push(activeList[i]);
            }

        }
        // end for-loop
        resetActive();
    }



    function getWinNumberAddress(uint _gameId , uint _index ) public view returns(address _user){
        _user =  games[_gameId].winNumbersByAddress[_index];
        return _user;
    }

    function getTotalNumberPlayed(uint _gameId ,uint _number) public view returns(uint) {
      return luckies[_gameId].number[_number].user.length;
    }

    function getAddressPlayNumber(uint _gameId  , uint _number , uint _index ) public view returns(address){
      return luckies[_gameId].number[_number].user[_index];
    }

    function getPlayeds(uint _index , address _user) public view returns(uint numbers , address user , uint status , uint game_id){
            numbers = playeds[_user].numbers[_index].numbers;
            user    =  playeds[_user].numbers[_index].user;
            status  = playeds[_user].numbers[_index].status;
            game_id = playeds[_user].numbers[_index].game_id;
            return (numbers , user , status , game_id);
    }

    function getActiveListLength() public view returns(uint){
        return activeList.length;
    }



    function getActives(uint _index , address _address) public view returns(uint , uint , uint){
        return (actives[_address].numbers[_index].numbers ,  actives[_address].numbers[_index].status , actives[_address].numbers[_index].game_id);
    }



  function buyTicketTest2(bytes _number) public {


    uint[] memory arr;
     arr = new uint[](_number.length * 2);
    uint count_arr = 0;
            for(uint i = 0 ; i < _number.length ;  i++){
                    uint digit0 = uint((_number[i] & mask_front) >> 4);

                    arr[count_arr] = digit0;
                    count_arr += 1;
                    uint digit1 = uint((_number[i] & mask_back));

                    arr[count_arr] = digit1;
                    count_arr+= 1;
            }


             uint[] memory tempArr;
            if(arr.length % numberCount == 0){
                 tempArr = new uint[](arr.length);
                 tempArr = arr;
            }else{
                tempArr = new uint[](arr.length-1);
                for(i = 0 ; i < arr.length ; i++){
                    if(  i != arr.length-1 ){
                        tempArr[i] = arr[i];
                    }

                }
            }


            if(tempArr.length % numberCount != 0){
                revert();
            }

            uint[] memory tempArrFinal;
            tempArrFinal = new uint[](tempArr.length/ 3);
            uint counterArr = 0;
            uint countSelect = 1;
            uint result = 0;


            for(i = 0 ; i < tempArr.length ; i++){
                if(countSelect == 1){
                    result += arr[i] * 100;
                    countSelect += 1;
                }else if(countSelect == 2){
                    result += arr[i] * 10;
                    countSelect += 1;
                }else if(countSelect == 3 ){
                    result += arr[i];
                    if(result < 100 ){
                        revert();
                    }else{
                        tempArrFinal[counterArr] = result;
                        counterArr += 1;
                        countSelect = 1;
                        result = 0;
                    }

                }
            }


            for(uint s = 0 ; s < tempArrFinal.length ; s++  ){
                    addTicket(tempArrFinal[s], msg.sender);
            }

            testArr2 = tempArrFinal;
            testArr2Length = tempArrFinal.length;

    }

     function addTicket(uint _item,address _buyer) public {
            games[currentGameId].totalTicket += 1;
            games[currentGameId].totalAmount += 10;

            luckies[currentGameId].totalPlayed += 1;
            luckies[currentGameId].number[_item].user.push(_buyer);
            setActive(msg.sender , _item);
     }



    function randomNumber(uint8 min, uint8 max) public constant returns (uint){
        uint crypt_block = uint8(uint(sha3(block.blockhash(block.number-1), now )));
        uint crypt_num = ( now + ( ( (now + nonce) + (max + crypt_block) ) / (currentGameId + nonce) ) );
        return uint8(sha3(crypt_num))%(min+max)-min;
    }

    function LottoNumberTest() public {
        nonce++;
        uint8 activeListLength = uint8(activeList.length);
        uint resultActiveIndex = randomNumber(0 , activeListLength);
        //  random from activeList
        uint8 totalTicket = uint8(actives[activeList[resultActiveIndex]].totalTicket);
        // random ticket of player target.
        uint resultNumIndex = randomNumber(0 , totalTicket);
        uint winnerNumber =  actives[activeList[resultActiveIndex]].numbers[resultNumIndex].numbers;

        uint countPlayer = 0;
        for(uint i=0 ; i< activeListLength; i++ ){
            uint totalTicketUser =  actives[activeList[i]].totalTicket;
            for(uint j = 0 ; j <  totalTicketUser ; j++){
                 if(actives[activeList[i]].numbers[j].numbers == winnerNumber){
                     countPlayer += 1;
                     actives[activeList[i]].numbers[j].status = 2;
                    games[currentGameId].winNumbersByAddress.push(activeList[i]);
                 }else{
                     actives[activeList[i]].numbers[j].status = 1;
                 }
            }
        }

        games[currentGameId].winNumbers = winnerNumber;
        games[currentGameId].totalWinnerPlayer = countPlayer;

        uint  budget  =  (games[currentGameId].totalAmount) * 100;
        uint  denominator = 8* 10;
        uint  price80percent = (budget * denominator) *  (10**15);
        uint  tempPrice =  (price80percent / countPlayer ) / 10;
           games[currentGameId].pricePerTicket = tempPrice;
        emit TaskAwardNumber(winnerNumber , countPlayer ,tempPrice , now );

        // return (winnerNumber , countPlayer ,  tempPrice);
    }





    /*
        @budget = Total money on game_current;
        @denominator =  budget 80% for pay to winnwinNumbers
        @testResult
        https://etherconverter.online/
    */

    // uint public unit = 10 ** 18; // 10^18
    // uint public budget  = 60* 100;
    // uint public denominator = 8* 10;
    // uint public testResult = (budget * denominator) *  (10**15);
    // uint public tempPrice =  (testResult / 3) / 10;









} // end contract