pragma solidity ^0.4.25;

contract FastGameMultiplier {

    //адрес поддержки
    address public support;

    //Проценты
	uint constant public PRIZE_PERCENT = 3;
    uint constant public SUPPORT_PERCENT = 2;
    
    //ограничения депозита
    uint constant public MAX_INVESTMENT =  0.3 ether;
    uint constant public MIN_INVESTMENT = 0.01 ether;
    uint constant public MIN_INVESTMENT_FOR_PRIZE = 0.02 ether;
    uint constant public GAS_PRICE_MAX = 25; // maximum gas price for contribution transactions
    uint constant public MAX_IDLE_TIME = 3 minutes; //время ожидания до забора приза //Maximum time the deposit should remain the last to receive prize

    //успешность игры, минимальное количество участников
    uint constant public SIZE_TO_SAVE_INVEST = 5;
    uint constant public TIME_TO_SAVE_INVEST = 2 minutes;
    
    //сетка процентов для вложения в одном старте, старт каждый час (тестово)
    uint8[] MULTIPLIERS = [
        115, //первый
        120, //второй
        125 //третий
    ];

    //описание депозита
    struct Deposit {
        address depositor; //Адрес депозита
        uint128 deposit;   //Сумма депозита 
        uint128 expect;    //Сколько выплатить по депозиту (115%-125%)
    }

   //Описание номера очереди и номер депозита в очереди
    struct DepositCount {
        int128 stage;
        uint128 count;
    }

	//Описание последнего и предпоследнего депозита 
    struct LastDepositInfo {
        uint128 index;
        uint128 time;
    }

    Deposit[] private queue;  //The queue

    uint public currentReceiverIndex = 0; //Индекс первого инвестора The index of the first depositor in the queue. The receiver of investments!
    uint public currentQueueSize = 0; //Размер очереди The current size of queue (may be less than queue.length)
    LastDepositInfo public lastDepositInfoForPrize; //Последний депозит для Джека The time last deposit made at
    LastDepositInfo public previosDepositInfoForPrize; //Предпоследний депозит для Джека The time last deposit made at

    uint public prizeAmount = 0; //Сумма приза оставшаяся с прошлого запуска
    uint public prizeStageAmount = 0; //Сумма приза Prize в текущем запуске amount accumulated for the last depositor
    int public stage = 0; //Количество стартов Number of contract runs
    uint128 public lastDepositTime = 0; //Время последнего депозита
    
    mapping(address => DepositCount) public depositsMade; //The number of deposits of different depositors

    constructor() public {
        support = msg.sender; 
        proceedToNewStage(getCurrentStageByTime() + 1);
    }
    
    //This function receives all the deposits
    //stores them and make immediate payouts
    function () public payable {
        require(tx.gasprice <= GAS_PRICE_MAX * 1000000000);
        require(gasleft() >= 250000, "We require more gas!"); //условие ограничения газа

        if(msg.value > 0){
            require(msg.value >= MIN_INVESTMENT && msg.value <= MAX_INVESTMENT); //Условие  депозита
            require(lastDepositInfoForPrize.time <= now + MAX_IDLE_TIME); 

            checkAndUpdateStage();

            require(getNextStageStartTime() >= now + MAX_IDLE_TIME + 2 minutes);//5 //нельзя инвестировать за MAX_IDLE_TIME до следующего старта

            //Pay to first investors in line
            if(currentQueueSize < SIZE_TO_SAVE_INVEST){ //страховка от плохого старта
                
                addDeposit(msg.sender, msg.value);
                
            } else {
                
                addDeposit(msg.sender, msg.value);
                pay(); 
                
            }
            
        } else if(msg.value == 0 && currentQueueSize > SIZE_TO_SAVE_INVEST){
            
            withdrawPrize(); //выплата приза
            
        } else if(msg.value == 0){
            
            require(currentQueueSize <= SIZE_TO_SAVE_INVEST); //Для возврата должно быть менее, либо равно SIZE_TO_SAVE_INVEST игроков
            require(lastDepositTime > 0 && (now - lastDepositTime) >= TIME_TO_SAVE_INVEST); //Для возврата должно пройти время TIME_TO_SAVE_INVEST
            
            returnPays(); //Вернуть все депозиты
            
        } 
    }

    //Used to pay to current investors
    function pay() private {
        //Try to send all the money on contract to the first investors in line
        uint balance = address(this).balance;
        uint128 money = 0;
        
        if(balance > prizeStageAmount) //The opposite is impossible, however the check will not do any harm
            money = uint128(balance - prizeStageAmount);

        //Send small part to tech support
        uint128 moneyS = uint128(money*SUPPORT_PERCENT/100);
        support.send(moneyS);
        money -= moneyS;
        
        //We will do cycle on the queue
        for(uint i=currentReceiverIndex; i<currentQueueSize; i++){

            Deposit storage dep = queue[i]; //get the info of the first investor

            if(money >= dep.expect){  //If we have enough money on the contract to fully pay to investor
                    
                dep.depositor.send(dep.expect); 
                money -= dep.expect;          
                
                //После выплаты депозиты + процента удаляется из очереди this investor is fully paid, so remove him
                delete queue[i];
            
                
            }else{
                //Here we don&#39;t have enough money so partially pay to investor

                dep.depositor.send(money);      //Send to him everything we have
                money -= dep.expect;            //update money left

                break;                     //Exit cycle
            }

            if(gasleft() <= 50000)         //Check the gas left. If it is low, exit the cycle
                break;                     //The next investor will process the line further
        }

        currentReceiverIndex = i; //Update the index of the current first investor
    }
    
    function returnPays() private {
        //Try to send all the money on contract to the first investors in line
        uint balance = address(this).balance;
        uint128 money = 0;
        
        if(balance > prizeAmount) //The opposite is impossible, however the check will not do any harm
            money = uint128(balance - prizeAmount);
        
        //We will do cycle on the queue
        for(uint i=currentReceiverIndex; i<currentQueueSize; i++){

            Deposit storage dep = queue[i]; //get the info of the first investor

                dep.depositor.send(dep.deposit); //Игра не состоялась, возврат
                money -= dep.deposit;            
                
                //После выплаты депозиты + процента удаляется из очереди this investor is fully paid, so remove him
                delete queue[i];

        }

        prizeStageAmount = 0; //Вернули деньги, джека текущей очереди нет.
        proceedToNewStage(getCurrentStageByTime() + 1);
    }

    function addDeposit(address depositor, uint value) private {
        //Count the number of the deposit at this stage
        DepositCount storage c = depositsMade[depositor];
        if(c.stage != stage){
            c.stage = int128(stage);
            c.count = 0;
        }

        //Участие в игре за джекпот только минимальном депозите MIN_INVESTMENT_FOR_PRIZE
        if(value >= MIN_INVESTMENT_FOR_PRIZE){
            previosDepositInfoForPrize = lastDepositInfoForPrize;
            lastDepositInfoForPrize = LastDepositInfo(uint128(currentQueueSize), uint128(now));
        }

        //Compute the multiplier percent for this depositor
        uint multiplier = getDepositorMultiplier(depositor);
        
        push(depositor, value, value*multiplier/100);

        //Increment number of deposits the depositors made this round
        c.count++;

        lastDepositTime = uint128(now);
        
        //Save money for prize
        prizeStageAmount += value*PRIZE_PERCENT/100;
    }

    function checkAndUpdateStage() private {
        int _stage = getCurrentStageByTime();

        require(_stage >= stage); //старт еще не произошел

        if(_stage != stage){
            proceedToNewStage(_stage);
        }
    }

    function proceedToNewStage(int _stage) private {
        //Старт новой игры
        stage = _stage;
        currentQueueSize = 0; 
        currentReceiverIndex = 0;
        lastDepositTime = 0;
        prizeAmount += prizeStageAmount; 
        prizeStageAmount = 0;
        delete queue;
        delete previosDepositInfoForPrize;
        delete lastDepositInfoForPrize;
    }

    //отправка приза
    function withdrawPrize() private {
        //You can withdraw prize only if the last deposit was more than MAX_IDLE_TIME ago
        require(lastDepositInfoForPrize.time > 0 && lastDepositInfoForPrize.time <= now - MAX_IDLE_TIME, "The last depositor is not confirmed yet");
        //Last depositor will receive prize only if it has not been fully paid
        require(currentReceiverIndex <= lastDepositInfoForPrize.index, "The last depositor should still be in queue");

        uint balance = address(this).balance;

        //Send donation to the first multiplier for it to spin faster
        //It already contains all the sum, so we must split for father and last depositor only
        //If the .call fails then ether will just stay on the contract to be distributed to
        //the queue at the next stage

        uint prize = balance;
        if(previosDepositInfoForPrize.time > 0 && previosDepositInfoForPrize.index > 0){
            uint prizePrevios = prize*10/100;
            queue[previosDepositInfoForPrize.index].depositor.transfer(prizePrevios);
            prize -= prizePrevios;
        }

        queue[lastDepositInfoForPrize.index].depositor.send(prize);
        
        proceedToNewStage(getCurrentStageByTime() + 1);
    }

    //Добавить выплату в очередь
    function push(address depositor, uint deposit, uint expect) private {
        //Add the investor into the queue
        Deposit memory dep = Deposit(depositor, uint128(deposit), uint128(expect));
        assert(currentQueueSize <= queue.length); //Assert queue size is not corrupted
        if(queue.length == currentQueueSize)
            queue.push(dep);
        else
            queue[currentQueueSize] = dep;

        currentQueueSize++;
    }

    //Информация о депозите
    function getDeposit(uint idx) public view returns (address depositor, uint deposit, uint expect){
        Deposit storage dep = queue[idx];
        return (dep.depositor, dep.deposit, dep.expect);
    }

    //Количество депозитов внесенное игроком
    function getDepositsCount(address depositor) public view returns (uint) {
        uint c = 0;
        for(uint i=currentReceiverIndex; i<currentQueueSize; ++i){
            if(queue[i].depositor == depositor)
                c++;
        }
        return c;
    }

    //Количество участников игры
    function getQueueLength() public view returns (uint) {
        return currentQueueSize - currentReceiverIndex;
    }

    //Номер вклада в текущей очереди
    function getDepositorMultiplier(address depositor) public view returns (uint) {
        DepositCount storage c = depositsMade[depositor];
        uint count = 0;
        if(c.stage == getCurrentStageByTime())
            count = c.count;
        if(count < MULTIPLIERS.length)
            return MULTIPLIERS[count];

        return MULTIPLIERS[MULTIPLIERS.length - 1];
    }

    // Текущий этап игры
    function getCurrentStageByTime() public view returns (int) {
        return int(now - 17846 * 86400 - 17 * 3600) / (15 * 60);
    }

    // Время начала следующей игры
    function getNextStageStartTime() public view returns (uint) {
        return 17846 * 86400 + 17 * 3600 + uint((getCurrentStageByTime() + 1) * 15 * 60);
    }

    //Информация об кандидате на приз
    function getCurrentCandidateForPrize() public view returns (address addr, int timeLeft){
        if(currentReceiverIndex <= lastDepositInfoForPrize.index && lastDepositInfoForPrize.index < currentQueueSize){
            Deposit storage d = queue[lastDepositInfoForPrize.index];
            addr = d.depositor;
            timeLeft = int(lastDepositInfoForPrize.time + MAX_IDLE_TIME) - int(now);
        }
    }
}