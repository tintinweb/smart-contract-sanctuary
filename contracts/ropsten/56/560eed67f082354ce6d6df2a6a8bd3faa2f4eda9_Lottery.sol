pragma solidity ^0.4.18;

contract Lottery {

    address[] public players;

    struct Winner {
        address holderAddress;
        uint totalprize;
        bool isWithdrawn;
    }
    
    //Which round won in, has the prize been withdrawn
    mapping(uint => Winner[]) roundWinnerMapping;
     
    // Total balance of the smart contract
    uint public contractBalance = 0;

    // When the lottery started
    uint public lotteryStart;
    
    //Charity Address
    address charityAddress = 0xdd870fa1b7c4700f2bd7f44238821c26f7392148;
    
    //Current week
    uint currentWeek = 0;

    // Duration the lottery will be active for
    uint public lotteryDuration;
    
    //Duration of Submission
    uint public submissionDuration;

    //Lottery is over
    bool public lotteryIsOver;

    //Total Eth that has been won
    uint public totalAward;

    //Event for when tickets are bought
    event TicketsBought(address indexed _from, uint _quantity);
    
    //Event for declaring the winner
    event AwardWinnings(address _to, uint _winnings);

    //Check stages of lottery
    
    modifier purchaseStage() {
        require(now>lotteryStart + submissionDuration && now<lotteryStart + lotteryDuration);
        _;
    }
    
    modifier submissionStage() {
        require(now>lotteryStart && now<lotteryStart + submissionDuration);
        _;
    }

    modifier lotteryFinished() {
        require(now> lotteryStart + lotteryDuration);
        _;
    }


    function Lottery() {
        lotteryStart = now;
        lotteryDuration = 7200 minutes;
        submissionDuration = 1440 minutes;
    }

    //Fallback
    function () payable {
    }
    
    //create random 
    function random(uint p) private view returns (uint) {
        return uint(sha3(block.difficulty, now))%p;
    }
    
    //create random differently for debugging purposes
    function random2(uint p, uint other) private view returns (uint) {
        return uint(sha3(block.difficulty, now, other ))%p;
    }
    
    
    uint numberOfTickets = 0;
    struct Ticket{
        uint x;
    }
    mapping(address => Ticket[]) userTicketMapping;
   
    mapping(uint => address) ticketIdUserMapping;
    
    //Add ticket to the the mapping
    function addTicket(address id, uint _x) public {
        userTicketMapping[id].push(Ticket(_x));
        //ticketIdUserMapping[_x]=msg.sender;
    }
    
    function addTicket2(address id, uint _x) public {
        ticketIdUserMapping[_x]=msg.sender;
    }

    //Get the tickets of users
    function getTicket(address id, uint index) public returns(uint){
        return userTicketMapping[id][index].x;
    }
    
    function getOwnerOfTicket(uint Index) public returns(address){
        return ticketIdUserMapping[Index];
    }
    
    //All bought tickets
    uint[] boughtTicketList;
    
    function checkIfExists(uint ticketId,uint[] myArray, uint arrayLength) public returns(bool){
        for(uint i=0; i<arrayLength; i++){
            if(myArray[i]==ticketId)
                return true;
        }
    }
    
    //Test to see bought tickets
    function getBoughtTicketList() public view returns(uint[]){
        return boughtTicketList;
    }
    
    //Buy ticket
    function buyTicket() public payable returns(bool){
        require(msg.value == 2000000000000000000);
        require(numberOfTickets<=100000);
        
        do{
           uint ticketId = random(99999);
        }while(checkIfExists(ticketId,boughtTicketList,numberOfTickets));
        
        addTicket(msg.sender,ticketId);
        addTicket2(msg.sender,ticketId);
        players.push(msg.sender);
        numberOfTickets++;
        boughtTicketList.push(ticketId);
        contractBalance += 2000000000000000000;
        TicketsBought(msg.sender, ticketId);
        return true;
    }

    //uint[] winnerTicketList;
    mapping(uint => uint) public winnerTicketList;
    
    //Winner indexes are chosen. For debugging purposes, open the comments.
    function generateWinners() public {// returns (winnerTicketList)
        uint tempTicketId = 0;
        //winnerTicketList=new uint[](21);
        winnerTicketList[0]=0;
        for(uint i=1;i<21;i++){
            if(i==1){
                uint randNum = random2(numberOfTickets,i);
                winnerTicketList[1] = randNum;
            }
            else {
               // do{
                    tempTicketId = random2(numberOfTickets,i);
               // }while(checkIfExists(tempTicketId,winnerTicketList,i));
                winnerTicketList[i-1] = tempTicketId;
            }
        }
        
         winnerTicketList[21]= random(10000);
         winnerTicketList[22]= random(1000);
         winnerTicketList[23]= random(100);

    }
    
    uint CountEtherWinning40 = 0;
    uint CountEtherWinning10 = 0;
    uint CountEtherWinning4 = 0;
    
    
    //Calculate total award
    function totalAwardCalculation(){
        uint localNumberOfTickets = numberOfTickets;
        for (uint i=0; i<localNumberOfTickets; i++){
            if(winnerTicketList[21]==(boughtTicketList[i]%10000)){
                CountEtherWinning40 += 1;
            }
            if(winnerTicketList[22]==(boughtTicketList[i]%1000)){
                CountEtherWinning10 += 1;
            }
            if(winnerTicketList[23]==(boughtTicketList[i]%100)){
                CountEtherWinning4 += 1;
            }
        }
        totalAward = 63500000000000000000000 + CountEtherWinning40*40000000000000000000 + CountEtherWinning10*10000000000000000000 + CountEtherWinning4*4000000000000000000;
    }
    
    //will we reveal due to sufficient funds
    function isRoundAwarded() public returns(bool){
        if(totalAward>contractBalance)
            return false;
        else
            return true;
    }
    
    //get ticket award from index
    function getTicketPrizeFromIndex(uint Index) public returns(uint){
        if(Index==1){
            return 50000;
        }
        else if(Index==2){
            return 10000;
        }
        else if(Index==3 || Index==4){
            return 400;
        }
        else if(Index>4 && Index<16){
            return 200;
        }
        else if(Index>15 && Index<21){
            return 100;
        }
        else if (Index==21){
            return 40;
        }
        else if (Index==22){
            return 10;
        }
        else if (Index==23){
            return 4;
        }
    }
    
    //calculate total charity prize
    function totalCharityPrize() public returns (uint){
        return 2*numberOfTickets - totalAward;
    }
    
    //sending charity prize after calculation
    function sendCharityPrizeToCharityAddress(uint charityprize) private returns (bool){
        charityAddress.send(charityprize);
        return true;
    }
    
    
    //Send etrhers to refund user
    function sendEthersToRefundAddress(address add) public returns (bool){
        add.send(2000000000000000000);
        return true;
    }
    
    //Send ethers to winner address
    function sendEthersToWinnerAddress(address ad,uint ticketholderweek) public returns (bool){
        require(ticketholderweek==currentWeek);
        Winner[] temparray = roundWinnerMapping[currentWeek];
        uint totalBalanceOfUser;
        uint tempArrayLength = temparray.length;
        for(uint i=0; i<tempArrayLength; i++){
            if(temparray[i].holderAddress==ad){
                totalBalanceOfUser+=temparray[i].totalprize;
                temparray[i].isWithdrawn=true;
            }
            
        }
        
        ad.send(totalBalanceOfUser);
        return true;
    }
    
    //Getting winner ticket list
    function getElementOfWinnerTicketList(uint x) public returns (uint){
       return winnerTicketList[x];
        
    }
    
    //Bought Ticket List
    function getElementOfBoughtTicketList(uint x) public returns (uint){
       return boughtTicketList[x];
    }
    
    //Announce winners & distribute the correct winnings to each winner. If not, refund.
    function awardWinnings() public returns (bool success) {
        for(uint i=1; i<3; i++){//returns all winning tickets
        uint temp = winnerTicketList[i];
        uint temp2 = boughtTicketList[temp];
           address addressWinner = getOwnerOfTicket(temp2);
            uint prizewWonInThisRound = getTicketPrizeFromIndex(i);
            roundWinnerMapping[currentWeek].push(Winner(addressWinner,prizewWonInThisRound,false));
        }
        totalAwardCalculation();
        if(!isRoundAwarded()){
            // refund values
            uint tempPlayerLength = players.length;
            for(uint j = 0; j<tempPlayerLength; j++){
                sendEthersToRefundAddress(players[j]);
            }
        }
        else{
        //    totalCharityPrize is sent.
        sendCharityPrizeToCharityAddress(totalCharityPrize());
        
        
        }
        return true;
    }
}