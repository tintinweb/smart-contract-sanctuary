pragma solidity ^0.4.25;

/**
	Telegram: https://t.me/multixpro

	Контракт Умная Очередь: возвращает 125% от вашего депозита!

	Автоматические выплаты!
	Без ошибок, дыр, автоматический - для выплат НЕ НУЖНА администрация!
	Создан и проверен профессионалами!

	1. Дождитесь старта по блоку
	2. Пошлите любую ненулевую сумму на адрес контракта
		 - сумма от 0.05 ETH до 1 ETH
		 - gas limit минимум 300 000
		 - вы встанете в очередь
	3. Немного подождите
	4. ...
	5. PROFIT! Вам пришло 125% от вашего депозита.
	6. Крайний вкладчик получает бонус в размере 3% от оборота на счет (выплаты бонусов произодятся вручную)
	7. Чтобы получить бонусный приз, крайний депозит должен продержаться 7 минут.

	Как это возможно?
	1. Первый инвестор в очереди (вы станете первым очень скоро) получает выплаты от
		 новых инвесторов до тех пор, пока не получит 125% от своего депозита
	2. Выплаты могут приходить несколькими частями или все сразу
	3. Как только вы получаете 125% от вашего депозита, вы удаляетесь из очереди
	4. Баланс этого контракта всегда равен 0, потому что все поступления сразу же
		 направляются на выплаты

		 Таким образом, последние платят первым, и инвесторы, достигшие выплат 125% от депозита,
		 удаляются из очереди, уступая место остальным

							новый инвестор   --|            совсем новый инвестор --|
								 инвестор5     |                новый инвестор      |
								 инвестор4     |     =======>      инвестор5        |
								 инвестор3     |                   инвестор4        |
				 (част. выплата) инвестор2    <|                   инвестор3        |
				(полная выплата) инвестор1   <-|                   инвестор2   <----|  (доплата до 125%)

		==> Лимиты: <==

		Профит: 125%
		Минимальный вклад: 0.05 ETH
		Максимальный вклад: 1 ETH


*/

contract Multi_X125_1eth {

//Address for promo expences
address constant private PROMO1 = 0x5Fa713836267bE36ae9664E97063667e668Eab63;
address constant private PROMO2 = 0xc2ce177F96a0fdfa3C72FD6E3a131086B38bc3Ef;
address constant private PRIZE	= 0x6E2c1214c10f72E35f005ae90b1f46c1BC5a2E80;

	uint constant public PROMO_PERCENT = 3; //Percent for promo expences
	uint constant public BONUS_PERCENT = 3; //Bonus prize
	uint constant public MULTIPLIER = 125; // Payout percentage for all participants
	uint constant public MAX_TIME = 5 minutes; //Maximum time to define the last Deposit, and the contract will be closed
	uint constant public START_BLOCK = 4388900; //Start block
	
	//The deposit structure holds all the info about the deposit made
	struct Deposit {
			address depositor;	// The depositor address
			uint deposit;		// The deposit amount
			uint payout;		// Amount already paid
	}

	struct LastDepositInfo {
        	uint128 index;
       		uint128 time;
    }

	Deposit[] public queue;  // The queue
	mapping (address => uint) public depositNumber; // investor deposit index
	uint public currentReceiverIndex; // The index of the depositor in the queue
	uint public totalInvested; // Total invested amount
	LastDepositInfo public lastDepositInfo; //The time last deposit made at

	//This function receives all the deposits stores them and make immediate payouts
	function () public payable {
			
			require(block.number >= START_BLOCK);

			if(msg.value > 0){

					require(gasleft() >= 250000); // We need gas to process queue
					require(msg.value >= 0.05 ether && msg.value <= 1 ether); // Too small and too big deposits are not accepted
					//You will become a winner if the last deposit was more than MAX_TIME ago
        			
        			require(lastDepositInfo.time <= now - MAX_TIME);

					// Add the investor into the queue
					queue.push( Deposit(msg.sender, msg.value, 0) );
					depositNumber[msg.sender] = queue.length;

					totalInvested += msg.value;

					//Send some promo to enable queue contracts to leave long-long time
					uint promo1 = msg.value*PROMO_PERCENT/100;
					PROMO1.send(promo1);
					uint promo2 = msg.value*PROMO_PERCENT/100;
					PROMO2.send(promo2);
					uint prize = msg.value*BONUS_PERCENT/100;
					PRIZE.send(prize);
					
					// Pay to first investors in line
					pay();

			}
			
	}

	// Used to pay to current investors
	// Each new transaction processes 1 - 4+ investors in the head of queue depending on balance and gas left
	function pay() internal {

			uint money = address(this).balance;

			// We will do cycle on the queue
			for (uint i = 0; i < queue.length; i++){

					uint idx = currentReceiverIndex + i;  //get the index of the currently first investor

					Deposit storage dep = queue[idx]; // get the info of the first investor

					uint totalPayout = dep.deposit * MULTIPLIER / 100;
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