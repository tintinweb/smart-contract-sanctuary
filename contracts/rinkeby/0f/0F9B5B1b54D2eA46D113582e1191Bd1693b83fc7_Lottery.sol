/**
 *Submitted for verification at Etherscan.io on 2021-12-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Lottery {

    address public owner;
    uint private startTime;
    uint public endTime;
    uint private duration = 5 minutes ;
    uint constant TicketPrice = 0.01 ether ;
    uint public RoundId = 0;
    uint public TotalJP2 = 0 ;
    uint public TotalJP1 = 0 ;
    uint public TicketID = 0;
    uint public TotalTicket = 0 ;
    
    string [] private hesoTk = ["A","B","C","D"];
    uint [] private numberArray = [0,1,2,3,4,5,6,7,8,9];
    
    struct Round {
        uint id;
        uint [3] number ;
        string coefficient ;
        uint total;
        }
    
    struct Ticket{
        uint id ;
        uint [3] number ;
        string coefficient ;
        uint roundID ;
        address player ;
        uint price ;
        string win ;
        uint prize ;
    }
    
    Round [] public rounds;
    Ticket [] public tickets ;
    

    event Timer(uint startRound , uint endRound);
    event newTicket(uint id ,uint [3] number,string coefficient ,uint roundID , address player, uint price ) ;
    event newRound(uint id,uint [3] ramdom ,string coefficient , uint total);
    event totalMoney(address player,uint tongve,uint tongtien);
    event Win(uint id,address player,string win , uint prize) ;
    
    constructor () {
        owner = msg.sender;
        _startNewRound();
    }
    
    // Xác định chủ tạo nên smart contract .
    modifier onlyOwner {
        require(
            msg.sender == owner,"Only owner can call this function."
        );
        _;
    }
        // Hàm bắt đầu 1 vòng sổ xố
    function _startNewRound() private {
        require(block.timestamp > endTime,"Thoi gian chua het ko the bat dau");
        if (block.timestamp >  endTime) {
            RoundId++;
            startTime =  block.timestamp ;
            endTime = startTime + duration ;
        emit Timer(startTime, endTime);
        }
    }
    
        // Hàm mua 1 vé sô : nhập 1 mảng 3 chữ số khác nhau 0 - 10 .
    function buyTicket(uint[3] memory numbers) public payable{
        
      
        require (numbers.length == 3 , "can nhap du 3 so");
        require ( numbers[0] >= 0 && numbers[0] <=9 ,  ' 0 - 9 ' ) ;
        require ( numbers[1] != numbers[0] && numbers[1] != numbers[2] && numbers[0] != numbers[2],  ' Nhap 3 so khac nhau');
        
        TicketID ++ ;

        string memory heso ="";
        
        heso = hesoTk[getRamdomCoefficient(TicketID)];
        
        
        Ticket memory ticket = Ticket(TicketID, numbers,heso, RoundId,msg.sender,TicketPrice,'none',0);
        
        tickets.push(ticket);
    
        emit newTicket(TicketID,numbers,heso ,RoundId,msg.sender,TicketPrice) ;
        
        TotalJP2 += TicketPrice ;
        TotalTicket += 1;
        
    }
    
    // Hàm mua số lượng vé số : nhập số lượng vé số cân mua .
    function buyMutilTickets(uint quantity) public payable {
    
             
         uint[3] memory numbers ;
        
         for(uint n  = 1 ; n <= quantity ; n++){
             
            uint indexN1 = getRamdomArray(n);
                   
            numbers[0] = numberArray[indexN1];
                
            removeArray(indexN1) ;
    
            uint indexN2= getRamdomArray(n);
             
            numbers[1] = numberArray[indexN2] ;
            
            removeArray(indexN2) ;
                
            uint indexN3= getRamdomArray(n);
                 
            numbers[2] = numberArray[indexN3] ;
            
            TicketID ++ ;

            string memory heso ="";
        
            heso = hesoTk[getRamdomCoefficient(TicketID)];
        
            Ticket memory ticket = Ticket(TicketID,numbers,heso ,RoundId,msg.sender,TicketPrice,'none',0);
            
            tickets.push(ticket);
            
            numberArray = [0,1,2,3,4,5,6,7,8,9];
            
            
        }
        
        emit totalMoney(msg.sender,quantity,quantity*TicketPrice);
        TotalJP2 += quantity * TicketPrice ;
        TotalTicket += quantity;
    }
    
    
    // Hàm quay số : quay ra kết qua của 1 round .
    function dial() public  {
        
        uint hoahongadmin = TotalJP2 * 2 / 10 ;
        
        payable(owner).transfer(hoahongadmin) ;
            
        TotalJP2 = TotalJP2 - hoahongadmin ;
        
         for(uint i = 0 ; i < rounds.length; i++){
            require(rounds[i].id != RoundId , "Chi qua so 1 lan moi round");
         }
        
        uint [3] memory numbers ;
           
    
        uint indexN1 = getRamdomArray(RoundId);
               
        numbers[0] = numberArray[indexN1];
            
        removeArray(indexN1) ;

        uint indexN2= getRamdomArray(RoundId);
         
        numbers[1] = numberArray[indexN2] ;
        
        removeArray(indexN2) ;
            
        uint indexN3= getRamdomArray(RoundId);
             
        numbers[2] = numberArray[indexN3] ;
            
        numberArray = [0,1,2,3,4,5,6,7,8,9];

        string memory heso ="";
        
        heso = hesoTk[getRamdomCoefficient(RoundId)];
            
        Round memory round  = Round(RoundId,numbers,heso,TotalJP2) ;
         
        rounds.push(round);
         
        _pickWinner();
  
    }
    
    // Hàm kiểm tra người trúng thưởng và gửi tiền vào address người trúng .
    function _pickWinner() private{
            
        Round memory winner = rounds[RoundId-1];

        uint countJackpots2 = 0 ;
        uint countJackpots1 = 0 ;
        
        for(uint n = 0 ; n < tickets.length; n++){
         uint count =0;
            if(winner.id == tickets[n].roundID){
                for(uint i =0 ; i < winner.number.length ;i++){
                    for(uint j = 0 ; j < tickets[n].number.length; j++){
                        if(tickets[n].number[j] == winner.number[i])
                            count +=1 ;
                    }
                }
                
            if(count == 2 ){
              tickets[n].win = 'Consolation' ;
            }

            else  if(count == 3){
                 tickets[n].win = 'Jackpots2'; 
                 countJackpots2 += 1 ;
             }

            else if(count == 3 && keccak256(abi.encodePacked(tickets[n].coefficient)) == keccak256(abi.encodePacked(winner.coefficient))){ 
                tickets[n].win = 'Jackpots1';
                countJackpots1 +=1 ;
            }
            
            else{
                 tickets[n].win = 'false' ;
            }


            if(keccak256(abi.encodePacked(tickets[n].win)) == keccak256(abi.encodePacked("Consolation"))){

              payable(tickets[n].player).transfer( 0.02 ether) ;
              tickets[n].prize = 0.02 ether ;
            
              TotalJP2 = TotalJP2 - 0.02 ether ;
              
              emit  Win(tickets[n].id ,tickets[n].player, tickets[n].win ,tickets[n].prize);
            }
        }
            

    }

        for(uint m = 0 ; m < tickets.length; m++){

            if(countJackpots2 == 0){
                countJackpots2 +=1; // fix err chia cho 0
                TotalJP1 = TotalJP1 + TotalJP2  ;
                TotalJP2 = 0 ;
            }

            if(countJackpots1 == 0){
                countJackpots1 +=1; // fix err chia cho 0
            }

            if(winner.id == tickets[m].roundID){
    
                uint jackpot2 = TotalJP2 / countJackpots2  ;
                if(keccak256(abi.encodePacked(tickets[m].win)) == keccak256(abi.encodePacked("Jackpots2"))){
                    tickets[m].prize = jackpot2 ;
                    payable(tickets[m].player).transfer(jackpot2);
                    TotalJP2 = TotalJP2 - jackpot2 ;
                    emit  Win(tickets[m].id ,tickets[m].player, tickets[m].win ,tickets[m].prize);
                        
                }
            
                uint jackpot1 = TotalJP1 / countJackpots1  ;
                if(keccak256(abi.encodePacked(tickets[m].win)) == keccak256(abi.encodePacked("Jackpots1"))){

                    if(TotalJP2 > 4 ether){
                        tickets[m].prize = jackpot1 ;
                        payable(tickets[m].player).transfer(jackpot1);
                        TotalJP1 = TotalJP1 - jackpot1 ;
                        emit  Win(tickets[m].id ,tickets[m].player, tickets[m].win ,tickets[m].prize);
                    }
                    
                    else {
                        tickets[m].prize = 3 ether ;
                        payable(tickets[m].player).transfer(3 ether);
                        TotalJP1 = TotalJP1 - jackpot1 ;
                        emit  Win(tickets[m].id ,tickets[m].player, tickets[m].win ,tickets[m].prize);
                    }
                        
                }
            }
        }



        TotalTicket = 0 ;
        
        _startNewRound();
}
    
    
    // Xem dãy số của Vé theo ID .
    // function getNumberTicketByID (uint id) public view returns (uint[3] memory) {
        
    //     for(uint i = 0 ; i < tickets.length;i++){
    //         if(id == tickets[i].id){
    //             return tickets[i].number;
    //         }
    //     }
        
    // }
    
     // Xem dãy số của Round theo ID .
    // function getNumberRoundByID (uint id) public view returns (uint[3] memory) {
        
    //     for(uint i = 0 ; i < rounds.length;i++){
    //         if(id == rounds[i].id){
    //             return rounds[i].number;
    //         }
    //     }
        
    // }
    
    // Lấy mảng Round từ ID cao đến ID thấp
    function getRound() public view returns(Round [] memory){
        Round [] memory arrayR  ;
        arrayR = rounds;
        Round  memory temp ;
        
        for(uint i = 0 ; i < arrayR.length ; i++){
           for (uint j = i + 1; j < arrayR.length; j++) {
                if (arrayR[i].id < arrayR[j].id) {
                    
                    temp = arrayR[i];
                    arrayR[i] =  arrayR[j];
                     arrayR[j] = temp;
                }
             }
        
        }
        
        return arrayR ;
    }
    
    // Lấy mảng Ticket từ ID cao đến ID thấp
    function getTicket() public view returns(Ticket [] memory) {
        Ticket [] memory arrayTk  ;
        arrayTk = tickets;
        Ticket  memory temp ;
        
        for(uint i = 0 ; i < arrayTk.length ; i++){
           for (uint j = i + 1; j < arrayTk.length; j++) {
                if (arrayTk[i].id < arrayTk[j].id) {
                    
                     temp = arrayTk[i];
                     arrayTk[i] =  arrayTk[j];
                     arrayTk[j] = temp;
                }
             }
        
        }
        
        return arrayTk ;
    }
    
    
    // Hàm xóa 1 phần tử trong mảng numberArray
    function removeArray(uint _index) public {
        require(_index < numberArray.length, "index out of bound");

        for (uint i = _index; i < numberArray.length - 1; i++) {
            numberArray[i] = numberArray[i + 1];
        }
        numberArray.pop();
    }
    
    // Hàm ramdom mảng numberArray
    function getRamdomArray(uint _index) public view returns(uint256){
        
       uint256 ramdom =  uint256(keccak256(abi.encodePacked(block.timestamp + _index))) % numberArray.length;
            
       return ramdom ;
               
    }

    function getRamdomCoefficient(uint _index) public view returns(uint256){
        
       uint256 ramdom =  uint256(keccak256(abi.encodePacked(block.timestamp + _index))) % hesoTk.length;
            
       return ramdom ;
               
    }
    
    
    
    // Xem số dư của smart contract
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    
 //=======================================================================================//

    // Phần 2 Mini Game    
    uint public gameID= 0 ;
     struct Game {
        uint id ;
        uint amout ;
        address player ;
        uint sochon ;
        uint ramdom ;
        string kq;
    }

    struct Ve {
        uint ve  ;
    }

    event Result(uint256 id, string winAmount);
    event transferFree(address _from , address _to , uint quantilyFreeTicket);

    mapping (uint => Game) public games ;
    mapping (address => Ve) public  ves ;

    // Hàm game búa ,kéo , bao => người chơi chọn 
    function GameMini1 (uint chon ) public payable {
        gameID = gameID +1 ;

        uint ramdom = getRamdom(gameID);

        games[gameID] = Game(gameID, msg.value, msg.sender , chon , ramdom , "");

        kq (msg.sender);
    }
    // 0 : bua , 1 : keo , 2 : bao
    function kq (address player) private{

       Ve storage tk = ves[player];

       Game storage game = games[gameID];

       if(game.sochon == game.ramdom){
            game.kq = "DRAW" ; 
            payable(game.player).transfer(game.amout);
       }

       else  if(game.sochon == 0  && game.ramdom == 1 || game.sochon == 1 && game.ramdom == 2 || game.sochon == 2  && game.ramdom == 0 ){
           game.kq = "WIN" ;
           payable(game.player).transfer(game.amout);
           tk.ve += 1 ;
       }

       else {
           game.kq = "LOSE" ;
       }

       emit Result( gameID, game.kq);
    }

    // Hàm ramdom GameMini
    function getRamdom(uint _index) public view returns(uint256){
        
       uint256 ramdom =  uint256(keccak256(abi.encodePacked(block.timestamp + _index))) % 3;
            
       return ramdom ;
               
    }

    // Hàm mua 1 vé sô : nhập 1 mảng 3 chữ số khác nhau 0 - 9 bằng phiếu gameMini .
    function buyTicketGame(uint[3] memory numbers) public {
        
        Ve storage tk = ves[msg.sender];

        require(tk.ve > 0 , "Ban ko du ve de mua");
      
        require (numbers.length == 3 , "can nhap du 3 so");
        require ( numbers[0] >= 0 && numbers[0] <=9 ,  ' 0 - 9 ' ) ;
        require ( numbers[1] != numbers[0] && numbers[1] != numbers[2] && numbers[0] != numbers[2],  ' Nhap 3 so khac nhau');

        tk.ve -=1 ;
        
        TicketID ++ ;

        string memory heso ="";
        
        heso = hesoTk[getRamdomCoefficient(TicketID)];
        
        Ticket memory ticket = Ticket(TicketID, numbers,heso, RoundId,msg.sender,TicketPrice,'none',0);
        
        tickets.push(ticket);


        TotalJP2 += TicketPrice ;
        TotalTicket += 1;
        
    }

    function transferFreeTicket(address _from , address _to , uint quantilyFreeTicket) public {

        Ve storage tkFrom = ves[_from];

        require(tkFrom.ve >= quantilyFreeTicket , "Ban ko du ve");
        tkFrom.ve = tkFrom.ve - quantilyFreeTicket ;

        Ve storage tkTo = ves[_to];

        tkTo.ve = tkTo.ve + quantilyFreeTicket ;

        emit transferFree( _from ,  _to ,  quantilyFreeTicket);

    }
    
}