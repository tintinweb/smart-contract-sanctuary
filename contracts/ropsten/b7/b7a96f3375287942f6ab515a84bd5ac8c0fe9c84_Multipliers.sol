pragma solidity ^0.4.25;

/**
  Multiplier contract: returns 111%-141% of each investment!
  Automatic payouts!
  No bugs, no backdoors, NO OWNER - fully automatic!
  Made and checked by professionals!

  1. Send any sum to smart contract address
     - sum from 0.01 to 10 ETH
     - min 250000 gas limit
     - you are added to a queue
  2. Wait a little bit
  3. ...
  4. PROFIT! You have got 111-141%

  How is that?
  1. The first investor in the queue (you will become the
     first in some time) receives next investments until
     it become 111-141% of his initial investment.
  2. You will receive payments in several parts or all at once
  3. Once you receive 111-141% of your initial investment you are
     removed from the queue.
  4. You can make multiple deposits
  5. The balance of this contract should normally be 0 because
     all the money are immediately go to payouts
  6. The more deposits you make the more multiplier you get. See MULTIPLIERS var
  7. If you are the last depositor (no deposits after you in 20 mins)
     you get 2% of all the ether that were on the contract. Send 0 to withdraw it.
     Do it BEFORE NEXT RESTART!
  8. The contract automatically restarts each 24 hours at 17:00 GMT
  9. Deposits will not be accepted 20 mins before next restart. But prize can be withdrawn.


     So the last pays to the first (or to several first ones
     if the deposit big enough) and the investors paid 111-141% are removed from the queue

                new investor --|               brand new investor --|
                 investor5     |                 new investor       |
                 investor4     |     =======>      investor5        |
                 investor3     |                   investor4        |
    (part. paid) investor2    <|                   investor3        |
    (fully paid) investor1   <-|                   investor2   <----|  (pay until full %)


  Контракт Умножитель: возвращает 111%-141% от вашего депозита!
  Автоматические выплаты!
  Без ошибок, дыр, автоматический - для выплат НЕ НУЖНА администрация!
  Создан и проверен профессионалами!

  1. Пошлите любую ненулевую сумму на адрес контракта
     - сумма от 0.01 до 10 ETH
     - gas limit минимум 250000
     - вы встанете в очередь
  2. Немного подождите
  3. ...
  4. PROFIT! Вам пришло 111%-141% от вашего депозита.

  Как это возможно?
  1. Первый инвестор в очереди (вы станете первым очень скоро) получает выплаты от
     новых инвесторов до тех пор, пока не получит 111%-141% от своего депозита
  2. Выплаты могут приходить несколькими частями или все сразу
  3. Как только вы получаете 111%-141% от вашего депозита, вы удаляетесь из очереди
  4. Вы можете делать несколько депозитов сразу
  5. Баланс этого контракта должен обычно быть в районе 0, потому что все поступления
     сразу же направляются на выплаты
  6. Чем больше вы сделали депозитов, тем больший процент вы получаете на очередной депозит
     Смотрите переменную MULTIPLIERS в контракте
  7. Если вы последний вкладчик (после вас не сделан депозит в течение 20 минут), то вы можете
     забрать призовой фонд - 2% от эфира, прошедшего через контракт. Пошлите 0 на контракт
     с газом не менее 350000, чтобы его получить.
  8. Контракт автоматически стартует каждые сутки в 20:00 MSK
  9. За 20 минут до рестарта депозиты перестают приниматься. Но приз забрать можно.


     Таким образом, последние платят первым, и инвесторы, достигшие выплат 111%-141% от депозита,
     удаляются из очереди, уступая место остальным

              новый инвестор --|            совсем новый инвестор --|
                 инвестор5     |                новый инвестор      |
                 инвестор4     |     =======>      инвестор5        |
                 инвестор3     |                   инвестор4        |
 (част. выплата) инвестор2    <|                   инвестор3        |
(полная выплата) инвестор1   <-|                   инвестор2   <----|  (доплата до 111%-141%)

*/

contract Multipliers {
    //Address of old Multiplier
    address constant private FATHER = 0x7CDfA222f37f5C4CCe49b3bBFC415E8C911D1cD8;
    //Address for tech expences
    address constant private TECH = 0xDb058D036768Cfa9a94963f99161e3c94aD6f5dA;
    //Address for promo expences
    address constant private PROMO = 0xdA149b17C154e964456553C749B7B4998c152c9E;
    //Percent for first multiplier donation
    uint constant public FATHER_PERCENT = 1;
    uint constant public TECH_PERCENT = 2;
    uint constant public PROMO_PERCENT = 2;
    uint constant public PRIZE_PERCENT = 2;
    uint constant public MAX_INVESTMENT = 10 ether;
    uint constant public MIN_INVESTMENT_FOR_PRIZE = 0.05 ether;
    uint constant public MAX_IDLE_TIME = 20 minutes; //Maximum time the deposit should remain the last to receive prize

    //How many percent for your deposit to be multiplied
    //Depends on number of deposits from specified address at this stage
    //The more deposits the higher the multiplier
    uint8[] MULTIPLIERS = [
        111, //For first deposit made at this stage
        113, //For second
        117, //For third
        121, //For forth
        125, //For fifth
        130, //For sixth
        135, //For seventh
        141  //For eighth and on
    ];

    //The deposit structure holds all the info about the deposit made
    struct Deposit {
        address depositor; //The depositor address
        uint128 deposit;   //The deposit amount
        uint128 expect;    //How much we should pay out (initially it is 111%-141% of deposit)
    }

    struct DepositCount {
        int128 stage;
        uint128 count;
    }

    struct LastDepositInfo {
        uint128 index;
        uint128 time;
    }

    Deposit[] private queue;  //The queue
    uint public currentReceiverIndex = 0; //The index of the first depositor in the queue. The receiver of investments!
    uint public currentQueueSize = 0; //The current size of queue (may be less than queue.length)
    LastDepositInfo public lastDepositInfo; //The time last deposit made at

    uint public prizeAmount = 0; //Prize amount accumulated for the last depositor
    int public stage = 0; //Number of contract runs
    mapping(address => DepositCount) public depositsMade; //The number of deposits of different depositors

    //This function receives all the deposits
    //stores them and make immediate payouts
    function () public payable {
        //If money are from first multiplier, just add them to the balance
        //All these money will be distributed to current investors
        if(msg.value > 0 && msg.sender != FATHER){
            require(gasleft() >= 220000, "We require more gas!"); //We need gas to process queue
            require(msg.value <= MAX_INVESTMENT, "The investment is too much!"); //Do not allow too big investments to stabilize payouts

            checkAndUpdateStage();

            //No new deposits 20 minutes before next restart, you should withdraw the prize
            require(getStageStartTime(stage+1) >= now + MAX_IDLE_TIME);

            addDeposit(msg.sender, msg.value);

            //Pay to first investors in line
            pay();
        }else if(msg.value == 0){
            withdrawPrize();
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

                //this investor is fully paid, so remove him
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
        prizeAmount += value*(FATHER_PERCENT + PRIZE_PERCENT)/100;

        //Send small part to tech support
        uint support = value*TECH_PERCENT/100;
        TECH.send(support);
        uint adv = value*PROMO_PERCENT/100;
        PROMO.send(adv);

    }

    function checkAndUpdateStage() private{
        int _stage = getCurrentStageByTime();

        require(_stage >= stage, "We should only go forward in time");

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
        uint donation = prizeAmount*FATHER_PERCENT/(FATHER_PERCENT + PRIZE_PERCENT);
        if(donation > 10 ether) //The father contract accepts up to 10 ether
            donation = 10 ether;

        //If the .call fails then ether will just stay on the contract to be distributed to
        //the queue at the next stage
        require(gasleft() >= 300000, "We need gas for the father contract");
        FATHER.call.value(donation).gas(250000)();

        uint prize = prizeAmount - donation;
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

    //Get current depositors multiplier percent at this stage
    function getDepositorMultiplier(address depositor) public view returns (uint) {
        DepositCount storage c = depositsMade[depositor];
        uint count = 0;
        if(c.stage == getCurrentStageByTime())
            count = c.count;
        if(count < MULTIPLIERS.length)
            return MULTIPLIERS[count];

        return MULTIPLIERS[MULTIPLIERS.length - 1];
    }

    function getCurrentStageByTime() public view returns (int) {
        return int(now - 17 hours) / 1 days - 17837; //Start is 02/11/2018 20:00 GMT+3
    }

    function getStageStartTime(int _stage) public pure returns (uint) {
        return 17 hours + uint(_stage + 17837)*1 days;
    }

    function getCurrentCandidateForPrize() public view returns (address addr, int timeLeft){
        //prevent exception, just return 0 for absent candidate
        if(currentReceiverIndex <= lastDepositInfo.index && lastDepositInfo.index < currentQueueSize){
            Deposit storage d = queue[lastDepositInfo.index];
            addr = d.depositor;
            timeLeft = int(lastDepositInfo.time + MAX_IDLE_TIME) - int(now);
        }
    }

}