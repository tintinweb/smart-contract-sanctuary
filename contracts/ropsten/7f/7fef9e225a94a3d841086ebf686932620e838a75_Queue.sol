pragma solidity ^0.4.25;

/**

  EN:

  Web: http://www.queuesmart.today
  Telegram: https://t.me/queuesmart

  Queue contract: returns 110-130% of each investment!

  Automatic payouts!
  No bugs, no backdoors, NO OWNER - fully automatic!
  Made and checked by professionals!

  1. Send any sum to smart contract address
     - sum from 0.15 ETH
     - min 300000 gas limit
     - you are added to a queue
  2. Wait a little bit
  3. ...
  4. PROFIT! You have got 110-130%

  How is that?
  1. The first investor in the queue (you will become the
     first in some time) receives next investments until
     it become 110-130% of his initial investment.
  2. You will receive payments in several parts or all at once
  3. Once you receive 110-130% of your initial investment you are
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
    (fully paid) investor1   <-|                   investor2   <----|  (pay until 110-130%)

    ==> Limits: <==

    Total invested: up to 50ETH
    Multiplier: 110%
    Maximum deposit: 1.5ETH

    Total invested: from 50 to 150ETH
    Multiplier: 111-116%
    Maximum deposit: 3ETH

    Total invested: from 150 to 300ETH
    Multiplier: 117-123%
    Maximum deposit: 5ETH

    Total invested: from 300 to 500ETH
    Multiplier: 124-129%
    Maximum deposit: 7ETH

    Total invested: from 500ETH
    Multiplier: 130%
    Maximum deposit: 10ETH

*/


/**

  RU:

  Web: http://www.queuesmart.today
  Telegram: https://t.me/queuesmart

  Контракт Умная Очередь: возвращает 110-130% от вашего депозита!

  Автоматические выплаты!
  Без ошибок, дыр, автоматический - для выплат НЕ НУЖНА администрация!
  Создан и проверен профессионалами!

  1. Пошлите любую ненулевую сумму на адрес контракта
     - сумма от 0.15 ETH
     - gas limit минимум 300000
     - вы встанете в очередь
  2. Немного подождите
  3. ...
  4. PROFIT! Вам пришло 110-130% от вашего депозита.

  Как это возможно?
  1. Первый инвестор в очереди (вы станете первым очень скоро) получает выплаты от
     новых инвесторов до тех пор, пока не получит 110-130% от своего депозита
  2. Выплаты могут приходить несколькими частями или все сразу
  3. Как только вы получаете 110-130% от вашего депозита, вы удаляетесь из очереди
  4. Баланс этого контракта должен обычно быть в районе 0, потому что все поступления
     сразу же направляются на выплаты

     Таким образом, последние платят первым, и инвесторы, достигшие выплат 110-130% от депозита,
     удаляются из очереди, уступая место остальным

              новый инвестор --|            совсем новый инвестор --|
                 инвестор5     |                новый инвестор      |
                 инвестор4     |     =======>      инвестор5        |
                 инвестор3     |                   инвестор4        |
 (част. выплата) инвестор2    <|                   инвестор3        |
(полная выплата) инвестор1   <-|                   инвестор2   <----|  (доплата до 110-130%)

    ==> Лимиты: <==

    Всего инвестировано: до 50ETH
    Профит: 110%
    Максимальный вклад: 1.5ETH

    Всего инвестировано: от 50 до 150ETH
    Профит: 111-116%
    Максимальный вклад: 3ETH

    Всего инвестировано: от 150 до 300ETH
    Профит: 117-123%
    Максимальный вклад: 5ETH

    Всего инвестировано: от 300 до 500ETH
    Профит: 124-129%
    Максимальный вклад: 7ETH

    Всего инвестировано: более 500ETH
    Профит: 130%
    Максимальный вклад: 10ETH

*/
contract Queue {

	//Address for promo expences
    address constant private PROMO1 = 0x0569E1777f2a7247D27375DB1c6c2AF9CE9a9C15;
	address constant private PROMO2 = 0xF892380E9880Ad0843bB9600D060BA744365EaDf;
	address constant private PROMO3	= 0x35aAF2c74F173173d28d1A7ce9d255f639ac1625;
	address constant private PRIZE	= 0xa93E50526B63760ccB5fAD6F5107FA70d36ABC8b;
	
	//Percent for promo expences
    uint constant public PROMO_PERCENT = 2;
		
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

        if(msg.value > 0){

            require(gasleft() >= 300000); // We need gas to process queue
            require(msg.value >= 0.15 ether && msg.value <= calcMaxDeposit()); // Too small and too big deposits are not accepted
            
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
            uint prize = msg.value*1/100;
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
        uint multiplier = calcMultiplier();

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

    // Get current queue size
    function getQueueLength() public view returns (uint) {
        return queue.length - currentReceiverIndex;
    }

    // Get max deposit for your investment
    function calcMaxDeposit() public view returns (uint) {

        if (totalInvested <= 50 ether) {
            return 1.5 ether;
        } else if (totalInvested <= 150 ether) {
            return 3 ether;
        } else if (totalInvested <= 300 ether) {
            return 5 ether;
        } else if (totalInvested <= 500 ether) {
            return 7 ether;
        } else {
            return 10 ether;
        }

    }

    // How many percent for your deposit to be multiplied at now
    function calcMultiplier() public view returns (uint) {

        if (totalInvested <= 50 ether) {
            return 110;
        } else if (totalInvested <= 100 ether) {
            return 111;
        } else if (totalInvested <= 150 ether) {
            return 116;
        } else if (totalInvested <= 200 ether) {
            return 117;
		} else if (totalInvested <= 250 ether) {
            return 120;
		} else if (totalInvested <= 300 ether) {
            return 123;
		} else if (totalInvested <= 350 ether) {
            return 127;
		} else if (totalInvested <= 500 ether) {
            return 129;
        } else {
            return 130;
        }

    }

}