pragma solidity ^0.4.25;

contract FastMultipliers {

    //адрес поддержки
    address public support;

    constructor() public {
        support = msg.sender; // project support
    }

    //Проценты
	uint constant public prize_percent = 4;
    uint constant public support_percent = 1;
    
   
//максимальные и минимальный депозит
    uint constant public MAX_INVESTMENT = 3 ether;
    uint constant public MIN_INVESTMENT_FOR_PRIZE = 0.05 ether;

//время ожидания до забора приза
    uint constant public MAX_IDLE_TIME = 1 minutes; //Maximum time the deposit should remain the last to receive prize

//сетка процентов для вложения в одном старте, старт каждый час (тестово)
    uint8[] MULTIPLIERS = [
        115, //первый
        120, //второй
        125 //третий
    ];

  //описание депозита
    struct Deposit {
        address depositor; //адрес депозита
        uint128 deposit;   //Сумма депозита 
        uint128 expect;    //Сколько выплатить по депозиту (115%-125%)
    }

   //описание номера очереди и номер депозита в очереди
    struct DepositCount {
        int128 stage;
        uint128 count;
    }

	//описание последнего депозита 
    struct LastDepositInfo {
        uint128 index;
        uint128 time;
    }

    Deposit[] private queue;  //The queue

    uint public currentReceiverIndex = 0; //Индекс первого инвестора The index of the first depositor in the queue. The receiver of investments!
    uint public currentQueueSize = 0; //Размер очереди The current size of queue (may be less than queue.length)
    LastDepositInfo public lastDepositInfo; //Время последнего депозита The time last deposit made at

    uint public prizeAmount = 0; //Сумма приза Prize amount accumulated for the last depositor
    int public stage = 0; //Количество стартов Number of contract runs
    mapping(address => DepositCount) public depositsMade; //The number of deposits of different depositors

    //This function receives all the deposits
    //stores them and make immediate payouts
    function () public payable {
        //If money are from first multiplier, just add them to the balance
        //All these money will be distributed to current investors
        if(msg.value > 0){
            require(gasleft() >= 250000, "We require more gas!"); //условие ограничения газа
            require(msg.value <= MAX_INVESTMENT, "The investment is too much!"); //Условие максимального депозита
            //require(lastDepositInfo.time <= now - MAX_IDLE_TIME, "Has winner");
            
            checkAndUpdateStage();

            //No new deposits 20 minutes before next restart, you should withdraw the prize
            require(getStageStartTime(stage) <= now - MAX_IDLE_TIME); //нельзя инвестировать если время старта позже - MAX_IDLE_TIME

            addDeposit(msg.sender, msg.value);

            //Pay to first investors in line
            pay(); //выплата 

        }else if(msg.value == 0){
            withdrawPrize(); //выплата приза
        }
    }

    //Used to pay to current investors
    //Each new transaction processes 1 - 4+ investors in the head of queue
    //depending on balance and gas left
    function pay() private {
        //Try to send all the money on contract to the first investors in line
        uint balance = address(this).balance;
        uint128 money = 0;
        if(balance > prizeAmount) //The opposite is impossible, however the check will not do any harm
            money = uint128(balance - prizeAmount);

        //We will do cycle on the queue
        for(uint i=currentReceiverIndex; i<currentQueueSize; i++){

            Deposit storage dep = queue[i]; //get the info of the first investor

            if(money >= dep.expect){  //If we have enough money on the contract to fully pay to investor
                dep.depositor.send(dep.expect); //Send money to him
                money -= dep.expect;            //update money left

                //После выплаты депозиты + процента удаляется из очереди this investor is fully paid, so remove him
                delete queue[i];
            }else{
                //Here we don&#39;t have enough money so partially pay to investor
                dep.depositor.send(money); //Send to him everything we have
                dep.expect -= money;       //Update the expected amount
                break;                     //Exit cycle
            }

            if(gasleft() <= 50000)         //Check the gas left. If it is low, exit the cycle
                break;                     //The next investor will process the line further
        }

        currentReceiverIndex = i; //Update the index of the current first investor
    }

    function addDeposit(address depositor, uint value) private {
        //Count the number of the deposit at this stage
        DepositCount storage c = depositsMade[depositor];
        if(c.stage != stage){
            c.stage = int128(stage);
            c.count = 0;
        }

        //If you are applying for the prize you should invest more than minimal amount
        //Otherwize it doesn&#39;t count
        if(value >= MIN_INVESTMENT_FOR_PRIZE) 
            lastDepositInfo = LastDepositInfo(uint128(currentQueueSize), uint128(now));

        //Compute the multiplier percent for this depositor
        uint multiplier = getDepositorMultiplier(depositor);
        //Add the investor into the queue. Mark that he expects to receive 111%-141% of deposit back
        push(depositor, value, value*multiplier/100);

        //Increment number of deposits the depositors made this round
        c.count++;

        //Save money for prize and father multiplier
        prizeAmount += value*prize_percent/100;

        //Send small part to tech support
        support.send(value*support_percent/100);
    }

    function checkAndUpdateStage() private{
        int _stage = getCurrentStageByTime();

        require(_stage >= stage, "We should only go forward in time"); //должны находиться в текущей очереди

        if(_stage != stage){
            proceedToNewStage(_stage);
        }
    }

    function proceedToNewStage(int _stage) private {
        //Clean queue info
        //The prize amount on the balance is left the same if not withdrawn
        stage = _stage;
        currentQueueSize = 0; //Instead of deleting queue just reset its length (gas economy)
        currentReceiverIndex = 0;
        delete lastDepositInfo;
    }

//отправка приза
    function withdrawPrize() private {
        //You can withdraw prize only if the last deposit was more than MAX_IDLE_TIME ago
        require(lastDepositInfo.time > 0 && lastDepositInfo.time <= now - MAX_IDLE_TIME, "The last depositor is not confirmed yet");
        //Last depositor will receive prize only if it has not been fully paid
        require(currentReceiverIndex <= lastDepositInfo.index, "The last depositor should still be in queue");

        uint balance = address(this).balance;
            if(prizeAmount > balance) //Impossible but better check it
                prizeAmount = balance;

        //Send donation to the first multiplier for it to spin faster
        //It already contains all the sum, so we must split for father and last depositor only

        //If the .call fails then ether will just stay on the contract to be distributed to
        //the queue at the next stage

        uint prize = prizeAmount;
        queue[lastDepositInfo.index].depositor.send(prize);

        prizeAmount = 0;
        proceedToNewStage(stage + 1);
    }

    //Pushes investor to the queue
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

    //Get the deposit info by its index
    //You can get deposit index from
    function getDeposit(uint idx) public view returns (address depositor, uint deposit, uint expect){
        Deposit storage dep = queue[idx];
        return (dep.depositor, dep.deposit, dep.expect);
    }

    //Get the count of deposits of specific investor
    function getDepositsCount(address depositor) public view returns (uint) {
        uint c = 0;
        for(uint i=currentReceiverIndex; i<currentQueueSize; ++i){
            if(queue[i].depositor == depositor)
                c++;
        }
        return c;
    }

    //Get all deposits (index, deposit, expect) of a specific investor
    function getDeposits(address depositor) public view returns (uint[] idxs, uint128[] deposits, uint128[] expects) {
        uint c = getDepositsCount(depositor);

        idxs = new uint[](c);
        deposits = new uint128[](c);
        expects = new uint128[](c);

        if(c > 0) {
            uint j = 0;
            for(uint i=currentReceiverIndex; i<currentQueueSize; ++i){
                Deposit storage dep = queue[i];
                if(dep.depositor == depositor){
                    idxs[j] = i;
                    deposits[j] = dep.deposit;
                    expects[j] = dep.expect;
                    j++;
                }
            }
        }
    }

    //Get current queue size
    function getQueueLength() public view returns (uint) {
        return currentQueueSize - currentReceiverIndex;
    }

    //Номер вкалада в текущей очереди
    function getDepositorMultiplier(address depositor) public view returns (uint) {
        DepositCount storage c = depositsMade[depositor];
        uint count = 0;
        if(c.stage == getCurrentStageByTime())
            count = c.count;
        if(count < MULTIPLIERS.length)
            return MULTIPLIERS[count];

        return MULTIPLIERS[MULTIPLIERS.length - 1];
    }

    //очередь по текщему времени
    function getCurrentStageByTime() public view returns (int) {
        return int(now/ 5 minutes - 18 hours) - 17840*1 days;
    }

    //начало следующей очереди
    function getStageStartTime(int _stage) public pure returns (uint) {
        return 18 hours + 17840*1 days + uint(_stage + 1)*5 minutes;
    }

    function getCurrentCandidateForPrize() public view returns (address addr, int timeLeft){
        //Кандидат на получение приза
        if(currentReceiverIndex <= lastDepositInfo.index && lastDepositInfo.index < currentQueueSize){
            Deposit storage d = queue[lastDepositInfo.index];
            addr = d.depositor;
            timeLeft = int(lastDepositInfo.time + MAX_IDLE_TIME) - int(now);
        }
    }

}