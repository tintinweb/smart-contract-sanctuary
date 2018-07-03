pragma solidity ^0.4.23;

contract BetWorldCup2018 {
  
  address public owner;
  
  struct Bets{
    uint par1;  //participate first ID
    uint par2;  //participate second ID
    uint closeTIMESTAMP; // close date
    uint8 winner; // 1 => par1: 2 => par2: 0 => draw: 4 => not yet play    
    bool isAvailable; // closed: false opened: true
    string description;
  }
  
  struct UserBets{
    address user_address;
    uint amount;  
    uint bet_id;
    uint8 winner; // 1 => par1: 2 => par2: 3 => draw
    uint betTIMESTAMP; 
    bool isWon; 
  }
 
  Bets[] public bets;
  mapping (uint => string) public disableBets;
  mapping (uint => string) participate;
  mapping (uint => UserBets[]) public campaigns;
  mapping(uint => mapping(uint => uint)) public betAmountOf; // bet_ID, winner_TYPE, total_amount
  mapping(uint => mapping(address => uint)) public betUserAmountOf; // bet_ID, user_address, amount
  mapping(uint => mapping(address => uint)) public betUserWonAmountOf; // bet_ID, user_address, amount
  mapping(uint => mapping(address => uint)) public betUserOf; // bet_ID, user_address, winner
  
  uint private small_profit = 0;

    constructor() public {
     owner = msg.sender;
        participate[1] = &quot;Russia&quot;;
        participate[2] = &quot;Germany&quot;;
        participate[3] = &quot;Brazil&quot;;
        participate[4] = &quot;Portugal&quot;;
        participate[5] = &quot;France&quot;;
        participate[6] = &quot;Uruguay&quot;;
        participate[7] = &quot;Argentina&quot;;
        participate[8] = &quot;England&quot;;
        participate[9] = &quot;Spain&quot;;
        participate[10] = &quot;Mexico&quot;;
        participate[11] = &quot;Belgium&quot;;
        participate[12] = &quot;Colombia&quot;;
        participate[13] = &quot;Croatia&quot;;
        participate[14] = &quot;Sweden&quot;;
        participate[15] = &quot;Egypt&quot;;
        participate[16] = &quot;Poland&quot;;
        participate[17] = &quot;Australia&quot;;
        participate[18] = &quot;Senegal&quot;;
        participate[19] = &quot;Iran&quot;;
        participate[20] = &quot;Japan&quot;;
        participate[21] = &quot;South Korea&quot;;
        participate[22] = &quot;Saudi Arabia&quot;;
        participate[23] = &quot;Nigeria&quot;;
        participate[24] = &quot;Costa Rica&quot;;
        participate[25] = &quot;Iceland&quot;;
        participate[26] = &quot;Serbia&quot;;
        participate[27] = &quot;Panama&quot;;
        participate[28] = &quot;Switzerland&quot;;
        participate[29] = &quot;Denmark&quot;;
        participate[30] = &quot;Tunisia&quot;;
        participate[31] = &quot;Morocco&quot;;
        participate[32] = &quot;Peru&quot;;
     
 
    }
    
  function () public payable {
  
  }
  
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    //winner: 1 => par1: 2 => par2: 3 => draw
    function takeBet(uint bet_id, uint8 winner) public payable {
        require(msg.value > 0);
        require(bets[bet_id].closeTIMESTAMP > now);
        require(bets[bet_id].isAvailable == true);
        
        //userbets.push(UserBets(msg.sender, msg.value, bet_id, winner, now, false));
        campaigns[bet_id].push(UserBets(msg.sender, msg.value, bet_id, winner, now, false));
        betAmountOf[bet_id][winner] += msg.value;
        betUserOf[bet_id][msg.sender] = winner;
        betUserAmountOf[bet_id][msg.sender] += msg.value;
    }

    function createBet(uint par1, uint par2, uint closeTIMESTAMP, bool isAvailable, string desc) external onlyOwner{
        bets.push(Bets(par1, par2, closeTIMESTAMP, 4, isAvailable, desc)); 
    }
    
    function agreeBetWinner (uint bet_id, uint8 winner) external onlyOwner{        
        
        require(bets[bet_id].isAvailable == true);
        require(winner >= 1);
        require(winner <= 3);
        //require(bets[bet_id].closeTIMESTAMP < now);
        bets[bet_id].winner = winner;        
        sendWinnerPriceToAll(bet_id, winner);
    }
    
    function getCampaignLength(uint id) external view returns (uint) {
        return  campaigns[id].length;
    }

    function getTotalAmountOf(uint bet_id) external view returns (uint) {
        return (betAmountOf[bet_id][0] + betAmountOf[bet_id][1] + betAmountOf[bet_id][2]);
    }
    
    
    function sendWinnerPriceToAll(uint bet_id, uint8 winner) internal returns (bool) {
        uint total_amount = betAmountOf[bet_id][0] + betAmountOf[bet_id][1] + betAmountOf[bet_id][2];
        uint winner_precent = total_amount/betAmountOf[bet_id][winner] * 95/100;
        small_profit += total_amount * 5/100;
         for (uint i = 0; i < campaigns[bet_id].length; i++){
            if(campaigns[bet_id][i].winner == winner) {
                uint winner_price = campaigns[bet_id][i].amount*winner_precent;
                campaigns[bet_id][i].user_address.transfer(winner_price);   
                betUserWonAmountOf[bet_id][campaigns[bet_id][i].user_address] = winner_price;
            }
           
         }
            emit Won(bet_id, winner);
        return true;
    }
    
    function getBet(uint bet_id) external view returns (uint, uint, uint, uint8, bool, string){
        return (bets[bet_id].par1, bets[bet_id].par2, bets[bet_id].closeTIMESTAMP,
        bets[bet_id].winner, bets[bet_id].isAvailable, bets[bet_id].description);
    }
    function setDisableBet(uint bet_id) external onlyOwner{
      disableBets[bet_id]=&#39;disable&#39;;
    }
    function getDisableBet(uint bet_id) external view returns (string) {
        return disableBets[bet_id];
    }
     function getBetName(uint bet_id) external view returns (string, string){
        return (participate[bets[bet_id].par1] ,participate[bets[bet_id].par2]);
    }
    
    function getBetLength() external view returns(uint){
         return bets.length;
    }
    
    function getUserBet(uint bet_id, uint user_bet)external view returns (address, uint, uint, uint8, uint, bool){
        return (campaigns[bet_id][user_bet].user_address, campaigns[bet_id][user_bet].amount, campaigns[bet_id][user_bet].bet_id,
        campaigns[bet_id][user_bet].winner, campaigns[bet_id][user_bet].betTIMESTAMP, campaigns[bet_id][user_bet].isWon);
    }
    
    function getUserBetsLength(uint bet_id)external view returns(uint){
         return campaigns[bet_id].length;
    }
    
    function getUserBetOf(uint bet_id, address user_address)external view returns(uint){
         return betUserOf[bet_id][user_address];
    }
    
    function getBetAmountOf(uint bet_id, uint winner) external view returns(uint){
         return betAmountOf[bet_id][winner];
    }
    
    function getParticipateName(uint par_id) external view returns(string){
         return participate[par_id];
    }
    
    function showSmallProfit() external view onlyOwner returns(uint) {
        return small_profit;
    }
    function withdraw() external onlyOwner {
        owner.transfer(small_profit);
        small_profit = 0;
    }
    
    event Won(uint indexed bet_id, uint8 winner);
    
}