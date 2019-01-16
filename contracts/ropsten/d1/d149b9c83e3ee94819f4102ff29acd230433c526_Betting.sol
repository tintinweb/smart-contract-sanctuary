pragma solidity ^0.4.20;
// Победа зенита [Зенит-Спартак 25/01/2019 18:00	Кубок Матч Премьер]
// There are two command 1(Зенит) abd 2(Спартак)
// Win - win command Зенит(1)
// Lose - lose command Спартак(2)
//
//

contract Betting {
   string public contractInfo = "Победа зенита [Зенит-Спартак 25/01/2019 18:00	Кубок Матч Премьер]";
   uint256 constant MinBet = 1;

   address public owner;
   uint256 public minimumBet;
   uint256 public totalBetsOne;
   uint256 public totalBetsTwo;

   address[] public players;
   struct Player {
      uint256 amountBet;
      uint16 teamSelected;
    }
   // Адресс персоны <=> информация пользователя
   mapping(address => Player) public playerInfo;
   function() public payable {}
   function Betting() public {
       owner = msg.sender;
       minimumBet = MinBet;
     }
    
    function kill() public {
          if(msg.sender == owner) selfdestruct(owner);
      }
       
    function checkPlayerExists(address player) public constant returns(bool){
          for(uint256 i = 0; i < players.length; i++){
             if(players[i] == player) return true;
          }
          return false;
        }

    function description() public view returns(string){
        return contractInfo;
    }
    
    
    function get_win_coefs() public view returns(uint256){
        if (totalBetsOne == 0){
            return 1;
        }
        else{
            return (totalBetsTwo/totalBetsOne+1);
        }
    }
    
    function get_lose_coefs() public view returns(uint256){
        if (totalBetsTwo == 0){
            return 1;
        }
        else{
            return (totalBetsOne/totalBetsTwo+1);
        }
    }
    
    function bet_win() public payable {
          //Нельзя два раза сделать ставку
          require(!checkPlayerExists(msg.sender));
          //Ставка больше минимального порога
          require(msg.value >= minimumBet);
          //Ставим минимальную ставку
          playerInfo[msg.sender].amountBet = msg.value;
          playerInfo[msg.sender].teamSelected = 1;
          //Добавляем адресс в базу
          players.push(msg.sender);
          //Увеличиваем финальное число поставивших на победу первого
          totalBetsOne += msg.value;
        }
    
    function bet_luse() public payable {
          require(!checkPlayerExists(msg.sender));
          require(msg.value >= minimumBet);
          playerInfo[msg.sender].amountBet = msg.value;
          playerInfo[msg.sender].teamSelected = 2;
          players.push(msg.sender);
          totalBetsTwo += msg.value;
        }
        
        
    
        
    function distributePrizes(uint16 teamWinner) public {
        // Только владелец котнракта может слать результат
        // Считаем что оракл максимально честный
        // (невозможно) В дальнейшем, для полной прозрачности это может быть автоматическая проверка с сайта
        //              На require может стоять только проверка времени, после чего автоматически анализируется
        //              независимый источник, например сайт FIFA
        
        require(msg.sender == owner);
          //Максимальное количество адрессов, будем считать 1000 нам хватит
          address[1000] memory winners;
          uint256 count = 0; // Размер массива выигравших
          uint256 LoserBet = 0;  // Все ставки проигравших
          uint256 WinnerBet = 0; // Все ставки победителей
    
          // Проверка всех победителей
          for(uint256 i = 0; i < players.length; i++){
             address playerAddress = players[i];
             if(playerInfo[playerAddress].teamSelected == teamWinner){
                winners[count] = playerAddress;
                count++;
             }
          }
          // Проверка всех проигравших
          if ( teamWinner == 1){
             LoserBet = totalBetsTwo;
             WinnerBet = totalBetsOne;
          }
          else{
              LoserBet = totalBetsOne;
              WinnerBet = totalBetsTwo;
          }
          // Переведем всем победтелям деньги
          for(uint256 j = 0; j < count; j++){
             // Проверяем побдность пользователя
             if(winners[j] != address(0))
                address add = winners[j];
                uint256 bet = playerInfo[add].amountBet;
                //Переводим деньги
                winners[j].transfer(    (bet*(10000+(LoserBet*10000/WinnerBet)))/10000 );
          }
          delete playerInfo[playerAddress]; // Удалим всех игроков
          players.length = 0; 
          LoserBet = 0; //Обнулим ставки
          WinnerBet = 0;
          totalBetsOne = 0;
          totalBetsTwo = 0;
        }
        
    function TotalWin() public view returns(uint256){
           return totalBetsOne;
        }
    function TotalLose() public view returns(uint256){
           return totalBetsTwo;
        }
}