pragma solidity ^0.4.25;

/**
  
  EN:
  
  Multiplier contract: returns 120% of each investment!
  
  Automatic payouts!
  No bugs, no backdoors, NO OWNER - fully automatic!
  Made and checked by professionals!

  1. Send any sum to smart contract address
     - sum 0.1
     - min 250000 gas limit
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
  4. You can make multiple deposits
  5. The balance of this contract should normally be 0 because
     all the money are immediately go to payouts


     So the last pays to the first (or to several first ones
     if the deposit big enough) and the investors paid 130% are removed from the queue

                new investor --|               brand new investor --|
                 investor5     |                 new investor       |
                 investor4     |     =======>      investor5        |
                 investor3     |                   investor4        |
    (part. paid) investor2    <|                   investor3        |
    (fully paid) investor1   <-|                   investor2   <----|  (pay until 130%)

*/


/**

  RU:    

  Контракт Умножитель: возвращает 120% от вашего депозита!
  
  Автоматические выплаты, каждый пятый в !
  Без ошибок, дыр, автоматический - для выплат НЕ НУЖНА администрация!
  Создан и проверен профессионалами!

  1. Пошлите любую фиксированную сумму на адрес контракта 
     - сумма 0.1 ETH
     - gas limit минимум 250000
     - вы встанете в очередь
  2. Немного подождите
  3. ...
  4. PROFIT! Вам пришло 120% от вашего депозита.

  Как это возможно?
  1. Первый инвестор в очереди (вы станете первым очень скоро) получает выплаты от
     новых инвесторов до тех пор, пока не получит 120% от своего депозита
  2. Выплаты могут приходить несколькими частями или все сразу
  3. Как только вы получаете 120% от вашего депозита, вы удаляетесь из очереди
  4. Вы можете делать несколько депозитов сразу
  5. Баланс этого контракта должен обычно быть в районе 0, потому что все поступления
     сразу же направляются на выплаты

     Таким образом, последние платят первым, и инвесторы, достигшие выплат 130% от депозита,
     удаляются из очереди, уступая место остальным

              новый инвестор --|            совсем новый инвестор --|
                 инвестор5     |                новый инвестор      |
                 инвестор4     |     =======>      инвестор5        |
                 инвестор3     |                   инвестор4        |
 (част. выплата) инвестор2    <|                   инвестор3        |
(полная выплата) инвестор1   <-|                   инвестор2   <----|  (доплата до 130%)

*/

contract FastBetMultiplier {

    // address of the technical support of the project
    address public support;

    // How many percent for your deposit to be multiplied
    uint constant public MULTIPLIER = 120;

    //The deposit structure holds all the info about the deposit made
    struct Deposit {
        address depositor; //The depositor address
        uint128 deposit;   //The deposit amount
        uint128 expect;    //How much we should pay out (initially it is 130% of deposit)
    }

    Deposit[] private queue;  //The queue
    uint public currentReceiverIndex = 0; //The index of the first depositor in the queue. The receiver of investments!

    mapping (address => bool) public notSupport; // The list of users allowed and forbidden to send 0.5% for support

    constructor() public {
        support = msg.sender; // project support
    }

    //This function receives all the deposits
    //stores them and make immediate payouts
    function () public payable {
        
        // You can not send 0.5% to support the project. To disable this feature, send 0.0000001 ether
        if (msg.value == 0.0000001 ether) {
            notSupport[msg.sender] = true;
            return;
        }
        
        if(msg.value > 0){
            require(gasleft() >= 220000, "We require more gas!"); //We need gas to process queue
            require(msg.value != 0.1 ether); // Too small deposits are not accepted

            //Add the investor into the queue. Mark that he expects to receive 130% of deposit back
            queue.push(Deposit(msg.sender, uint128(msg.value), uint128(msg.value*MULTIPLIER/100)));

            // Send 0.5% for support project if you agree to this
            if (!notSupport[msg.sender]) {
                 support.transfer(msg.value * 5 / 1000); // 0.5%
            }
            
            //Pay to first investors in line
            pay();
        }
    }

    //Used to pay to current investors
    //Each new transaction processes 1 - 4+ investors in the head of queue 
    //depending on balance and gas left
    function pay() private {
        //Try to send all the money on contract to the first investors in line
        uint128 money = uint128(address(this).balance);

        //We will do cycle on the queue
        for(uint i=0; i<queue.length; i++){

            uint idx = currentReceiverIndex + i;  //get the index of the currently first investor

            Deposit storage dep = queue[idx]; //get the info of the first investor

            if(money >= dep.expect){  //If we have enough money on the contract to fully pay to investor
                dep.depositor.send(dep.expect); //Send money to him
                money -= dep.expect;            //update money left

                //this investor is fully paid, so remove him
                delete queue[idx];
            }else{
                //Here we don&#39;t have enough money so partially pay to investor
                dep.depositor.send(money); //Send to him everything we have
                dep.expect -= money;       //Update the expected amount
                break;                     //Exit cycle
            }

            if(gasleft() <= 50000)         //Check the gas left. If it is low, exit the cycle
                break;                     //The next investor will process the line further
        }

        currentReceiverIndex += i; //Update the index of the current first investor
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
        for(uint i=currentReceiverIndex; i<queue.length; ++i){
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
            for(uint i=currentReceiverIndex; i<queue.length; ++i){
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
        return queue.length - currentReceiverIndex;
    }

}