pragma solidity ^0.4.25;

/**

  EN:
  Multiplier contract: returns 110-135% of each investment!

  Automatic payouts!
  No bugs, no backdoors, NO OWNER - fully automatic!
  Made and checked by professionals!

  1. Send any sum to smart contract address
     - sum from 0.01 ETH
     - min 280000 gas limit
     - you are added to a queue
  2. Wait a little bit
  3. ...
  4. PROFIT! You have got 110-135%

  How is that?
  1. The first investor in the queue (you will become the
     first in some time) receives next investments until
     it become 110-135% of his initial investment.
  2. You will receive payments in several parts or all at once.
  3. Once you receive 110-135% of your initial investment you are
     removed from the queue.
  4. You can invest an unlimited number of times without waiting for the full
     payment on deposits.


     So the last pays to the first (or to several first ones
     if the deposit big enough) and the investors paid 110-135% are removed from the queue

                new investor --|               brand new investor --|
                 investor5     |                 new investor       |
                 investor4     |     =======>      investor5        |
                 investor3     |                   investor4        |
    (part. paid) investor2    <|                   investor3        |
    (fully paid) investor1   <-|                   investor2   <----|  (pay until 110-135%)

    ==> Limits: <==

    Total invested: up to 20ETH
    Multiplier: 135%
    Maximum deposit: 1ETH

    Total invested: from 20 to 50ETH
    Multiplier: 120%
    Maximum deposit: 1.2ETH

    Total invested: from 50 to 100ETH
    Multiplier: 115%
    Maximum deposit: 1.4ETH

    Total invested: from 100 to 200ETH
    Multiplier: 112%
    Maximum deposit: 1.7ETH

    Total invested: from 200ETH
    Multiplier: 110%
    Maximum deposit: 2ETH

*/


/**

  RU:
  Контракт Умножитель: возвращает 110-135% от вашего депозита!

  Автоматические выплаты!
  Без ошибок, дыр, автоматический - для выплат НЕ НУЖНА администрация!
  Создан и проверен профессионалами!

  1. Пошлите любую ненулевую сумму на адрес контракта
     - сумма от 0.01 ETH
     - gas limit минимум 280000
     - вы встанете в очередь
  2. Немного подождите
  3. ...
  4. PROFIT! Вам пришло 110-135% от вашего депозита.

  Как это возможно?
  1. Первый инвестор в очереди (вы станете первым очень скоро) получает выплаты от
     новых инвесторов до тех пор, пока не получит 110-135% от своего депозита.
  2. Выплаты могут приходить несколькими частями или все сразу.
  3. Как только вы получаете 110-135% от вашего депозита, вы удаляетесь из очереди.
  4. Вы можете вкладывать неограниченное количество раз, не дожидаясь
     полной выплаты по депозитам.

     Таким образом, последние платят первым, и инвесторы, достигшие выплат 110-135% от депозита,
     удаляются из очереди, уступая место остальным

              новый инвестор --|            совсем новый инвестор --|
                 инвестор5     |                новый инвестор      |
                 инвестор4     |     =======>      инвестор5        |
                 инвестор3     |                   инвестор4        |
 (част. выплата) инвестор2    <|                   инвестор3        |
(полная выплата) инвестор1   <-|                   инвестор2   <----|  (доплата до 110-135%)

    ==> Лимиты: <==

    Всего инвестировано: до 20ETH
    Профит: 135%
    Максимальный вклад: 1ETH

    Всего инвестировано: от 20 до 50ETH
    Профит: 120%
    Максимальный вклад: 1.2ETH

    Всего инвестировано: от 50 до 100ETH
    Профит: 115%
    Максимальный вклад: 1.4ETH

    Всего инвестировано: от 100 до 200ETH
    Профит: 112%
    Максимальный вклад: 1.7ETH

    Всего инвестировано: более 200ETH
    Профит: 110%
    Максимальный вклад: 2ETH

*/
contract SmartEthRocket {

    uint public prizeFee = 7;
    uint public prize;
    address public lastInvestor;
    uint public lastInvestedAt;

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

    address public support = msg.sender;
    uint public amountForSupport;

    //This function receives all the deposits
    //stores them and make immediate payouts
    function () public payable {
        require(block.number >= 6654936);

        if(msg.value > 0){

            require(gasleft() >= 250000); // We need gas to process queue
            require(msg.value >= 0.01 ether && msg.value <= calcMaxDeposit()); // Too small and too big deposits are not accepted
            
            if (depositNumber[msg.sender] == 0) {
                // Add the investor into the queue
                queue.push( Deposit(msg.sender, msg.value, 0) );
                depositNumber[msg.sender] = queue.length;
            } else {
                queue[depositNumber[msg.sender] - 1].deposit += msg.value;
            }

            totalInvested += msg.value;

            // In total, no more than 5 ETH can be sent to support the project
            if (amountForSupport < 5 ether) {
                uint fee = msg.value / 10;
                amountForSupport += fee;
                support.transfer(fee);
            }
            
            prize += msg.value * prizeFee / 100;
            lastInvestor = msg.sender;
            lastInvestedAt = block.number;

            // Pay to first investors in line
            pay();

        } else if (lastInvestor == msg.sender && block.number >= lastInvestedAt + 126) {
            lastInvestor.transfer(prize);
            delete prize;
            delete lastInvestor;
        } else {
            revert();
        }
    }

    // Used to pay to current investors
    // Each new transaction processes 1 - 4+ investors in the head of queue
    // depending on balance and gas left
    function pay() internal {

        uint money = address(this).balance - prize;
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

        if (totalInvested <= 20 ether) {
            return 1 ether;
        } else if (totalInvested <= 50 ether) {
            return 1.2 ether;
        } else if (totalInvested <= 100 ether) {
            return 1.4 ether;
        } else if (totalInvested <= 200 ether) {
            return 1.7 ether;
        } else {
            return 2 ether;
        }

    }

    // How many percent for your deposit to be multiplied at now
    function calcMultiplier() public view returns (uint) {

        if (totalInvested <= 20 ether) {
            return 135;
        } else if (totalInvested <= 50 ether) {
            return 120;
        } else if (totalInvested <= 100 ether) {
            return 115;
        } else if (totalInvested <= 200 ether) {
            return 112;
        } else {
            return 110;
        }

    }

}