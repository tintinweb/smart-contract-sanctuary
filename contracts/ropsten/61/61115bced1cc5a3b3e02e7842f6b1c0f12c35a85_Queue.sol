pragma solidity ^0.4.25;

/**

  EN:

  Web: http://www.queuesmart.today
  Telegram: https://t.me/queuesmart

  Queue contract: returns 120% of each investment!

  Automatic payouts!
  No bugs, no backdoors, NO OWNER - fully automatic!
  Made and checked by professionals!

  1. Send any sum to smart contract address
     - sum from 0.07 ETH
     - min 350 000 gas limit
     - you are added to a queue
  2. Wait a little bit
  3. ...
  4. PROFIT! You have got 120%

  How is that?
  1. The first investor in the queue (you will become the
     first in some time) receives next investments until
     it become 120% of his initial investment.
  2. You will receive payments in several parts or all at once
  3. Once you receive 120% of your initial investment you are
     removed from the queue.
  4. The balance of this contract should normally be 0 because
     all the money are immediately go to payouts


     So the last pays to the first (or to several first ones
     if the deposit big enough) and the investors paid 105-130% are removed from the queue

                new investor --|               brand new investor --|
                 investor5     |                 new investor       |
                 investor4     |     =======>      investor5        |
                 investor3     |                   investor4        |
    (part. paid) investor2    <|                   investor3        |
    (fully paid) investor1   <-|                   investor2   <----|  (pay until 120%)

    ==> Limits: <==

    Multiplier: 120%
    Minimum deposit: 0.07ETH
    Maximum deposit: 7ETH
*/


/**

  RU:

  Web: http://www.queuesmart.today
  Telegram: https://t.me/queuesmarten

  Контракт Умная Очередь: возвращает 120% от вашего депозита!

  Автоматические выплаты!
  Без ошибок, дыр, автоматический - для выплат НЕ НУЖНА администрация!
  Создан и проверен профессионалами!

  1. Пошлите любую ненулевую сумму на адрес контракта
     - сумма от 0.07 ETH
     - gas limit минимум 350 000
     - вы встанете в очередь
  2. Немного подождите
  3. ...
  4. PROFIT! Вам пришло 120% от вашего депозита.

  Как это возможно?
  1. Первый инвестор в очереди (вы станете первым очень скоро) получает выплаты от
     новых инвесторов до тех пор, пока не получит 120% от своего депозита
  2. Выплаты могут приходить несколькими частями или все сразу
  3. Как только вы получаете 120% от вашего депозита, вы удаляетесь из очереди
  4. Баланс этого контракта должен обычно быть в районе 0, потому что все поступления
     сразу же направляются на выплаты

     Таким образом, последние платят первым, и инвесторы, достигшие выплат 120% от депозита,
     удаляются из очереди, уступая место остальным

              новый инвестор --|            совсем новый инвестор --|
                 инвестор5     |                новый инвестор      |
                 инвестор4     |     =======>      инвестор5        |
                 инвестор3     |                   инвестор4        |
 (част. выплата) инвестор2    <|                   инвестор3        |
(полная выплата) инвестор1   <-|                   инвестор2   <----|  (доплата до 120%)

    ==> Лимиты: <==

    Профит: 120%
    Минимальный вклад: 0.07 ETH
    Максимальный вклад: 7 ETH


*/
contract Queue {

	//Address for promo expences
    address constant private PROMO1 = 0x0569E1777f2a7247D27375DB1c6c2AF9CE9a9C15;
	address constant private PROMO2 = 0xF892380E9880Ad0843bB9600D060BA744365EaDf;
	address constant private PROMO3	= 0x35aAF2c74F173173d28d1A7ce9d255f639ac1625;
	address constant private PRIZE	= 0xa93E50526B63760ccB5fAD6F5107FA70d36ABC8b;
	
	//Percent for promo expences
    uint constant public PROMO_PERCENT = 2;
    
    //Bonus prize
    uint constant public BONUS_PERCENT = 3;
		
    //The deposit structure holds all the info about the deposit made
    struct Deposit {
        address depositor; // The depositor address
        uint deposit;   // The deposit amount
        uint payout; // Amount already paid
    }

    Deposit[] public queue;  // The queue
    mapping (address => uint) public depositNumber; // investor deposit index
    uint public currentReceiverIndex; // The index of the depositor in the queue
    uint public totalInvested; // Total invested amount

    //This function receives all the deposits
    //stores them and make immediate payouts
    function () public payable {
        
        require(block.number >= 211);

        if(msg.value > 0){

            require(gasleft() >= 250000); // We need gas to process queue
            require(msg.value >= 0.07 ether && msg.value <= 7 ether); // Too small and too big deposits are not accepted
            
            // Add the investor into the queue
            queue.push( Deposit(msg.sender, msg.value, 0) );
            depositNumber[msg.sender] = queue.length;

            totalInvested += msg.value;

            //Send some promo to enable queue contracts to leave long-long time
            uint promo1 = msg.value*PROMO_PERCENT/100;
            PROMO1.send(promo1);
			uint promo2 = msg.value*PROMO_PERCENT/100;
            PROMO2.send(promo2);
			uint promo3 = msg.value*PROMO_PERCENT/100;
            PROMO3.send(promo3);
            uint prize = msg.value*BONUS_PERCENT/100;
            PRIZE.send(prize);
            
            // Pay to first investors in line
            pay();

        }
    }

    // Used to pay to current investors
    // Each new transaction processes 1 - 4+ investors in the head of queue
    // depending on balance and gas left
    function pay() internal {

        uint money = address(this).balance;
        uint multiplier = 120;

        // We will do cycle on the queue
        for (uint i = 0; i < queue.length; i++){

            uint idx = currentReceiverIndex + i;  //get the index of the currently first investor

            Deposit storage dep = queue[idx]; // get the info of the first investor

            uint totalPayout = dep.deposit * multiplier / 100;
            uint leftPayout;

            if (totalPayout > dep.payout) {
                leftPayout = totalPayout - dep.payout;
            }

            if (money >= leftPayout) { //If we have enough money on the contract to fully pay to investor

                if (leftPayout > 0) {
                    dep.depositor.send(leftPayout); // Send money to him
                    money -= leftPayout;
                }

                // this investor is fully paid, so remove him
                depositNumber[dep.depositor] = 0;
                delete queue[idx];

            } else{

                // Here we don&#39;t have enough money so partially pay to investor
                dep.depositor.send(money); // Send to him everything we have
                dep.payout += money;       // Update the payout amount
                break;                     // Exit cycle

            }

            if (gasleft() <= 55000) {         // Check the gas left. If it is low, exit the cycle
                break;                       // The next investor will process the line further
            }
        }

        currentReceiverIndex += i; //Update the index of the current first investor
    }
    
    //Returns your position in queue
    function getDepositsCount(address depositor) public view returns (uint) {
        uint c = 0;
        for(uint i=currentReceiverIndex; i<queue.length; ++i){
            if(queue[i].depositor == depositor)
                c++;
        }
        return c;
    }

    // Get current queue size
    function getQueueLength() public view returns (uint) {
        return queue.length - currentReceiverIndex;
    }

}