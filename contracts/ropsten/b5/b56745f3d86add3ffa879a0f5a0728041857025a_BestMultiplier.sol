pragma solidity ^0.4.25;

/**
  Multiplier contract: returns 121% of each investment!
  Automatic payouts!
  No bugs, no backdoors, NO OWNER - fully automatic!
  Made and checked by professionals!

  1. Send any sum to smart contract address
     - sum from 0.01 to 10 ETH
     - min 250000 gas limit
     - you are added to a queue
  2. Wait a little bit
  3. ...
  4. PROFIT! You have got 121%

  How is that?
  1. The first investor in the queue (you will become the
     first in some time) receives next investments until
     it become 121% of his initial investment.
  2. You will receive payments in several parts or all at once
  3. Once you receive 121% of your initial investment you are
     removed from the queue.
  4. You can make multiple deposits
  5. The balance of this contract should normally be 0 because
     all the money are immediately go to payouts


     So the last pays to the first (or to several first ones
     if the deposit big enough) and the investors paid 121% are removed from the queue

                new investor --|               brand new investor --|
                 investor5     |                 new investor       |
                 investor4     |     =======>      investor5        |
                 investor3     |                   investor4        |
    (part. paid) investor2    <|                   investor3        |
    (fully paid) investor1   <-|                   investor2   <----|  (pay until 121%)


  Контракт Умножитель: возвращает 121% от вашего депозита!
  Автоматические выплаты!
  Без ошибок, дыр, автоматический - для выплат НЕ НУЖНА администрация!
  Создан и проверен профессионалами!

  1. Пошлите любую ненулевую сумму на адрес контракта
     - сумма от 0.01 до 10 ETH
     - gas limit минимум 250000
     - вы встанете в очередь
  2. Немного подождите
  3. ...
  4. PROFIT! Вам пришло 121% от вашего депозита.

  Как это возможно?
  1. Первый инвестор в очереди (вы станете первым очень скоро) получает выплаты от
     новых инвесторов до тех пор, пока не получит 121% от своего депозита
  2. Выплаты могут приходить несколькими частями или все сразу
  3. Как только вы получаете 121% от вашего депозита, вы удаляетесь из очереди
  4. Вы можете делать несколько депозитов сразу
  5. Баланс этого контракта должен обычно быть в районе 0, потому что все поступления
     сразу же направляются на выплаты

     Таким образом, последние платят первым, и инвесторы, достигшие выплат 121% от депозита,
     удаляются из очереди, уступая место остальным

              новый инвестор --|            совсем новый инвестор --|
                 инвестор5     |                новый инвестор      |
                 инвестор4     |     =======>      инвестор5        |
                 инвестор3     |                   инвестор4        |
 (част. выплата) инвестор2    <|                   инвестор3        |
(полная выплата) инвестор1   <-|                   инвестор2   <----|  (доплата до 121%)

*/

contract BestMultiplier {
    //Address for reclame expences
    address constant private Reclame = 0x39D080403562770754d2fA41225b33CaEE85fdDd;
    //Percent for reclame expences
    uint constant public Reclame_PERCENT = 3; 
    //3 for advertizing
    address constant private Admin = 0x0eDd0c239Ef99A285ddCa25EC340064232aD985e;
    // Address for admin expences
    uint constant public Admin_PERCENT = 1;
    // 1 for techsupport
    address constant private BMG = 0xc42F87a2E51577d56D64BF7Aa8eE3A26F3ffE8cF;
    // Address for BestMoneyGroup
    uint constant public BMG_PERCENT = 2;
    // 2 for BMG
    uint constant public Refferal_PERCENT = 10;
    // 10 for Refferal
    //How many percent for your deposit to be multiplied
    uint constant public MULTIPLIER = 121;

    //The deposit structure holds all the info about the deposit made
    struct Deposit {
        address depositor; //The depositor address
        uint128 deposit;   //The deposit amount
        uint128 expect;    //How much we should pay out (initially it is 121% of deposit)
    }

    Deposit[] private queue;  //The queue
    uint public currentReceiverIndex = 0; //The index of the first depositor in the queue. The receiver of investments!

    //This function receives all the deposits
    //stores them and make immediate payouts
    function () public payable {
        require(tx.gasprice <= 50000000000 wei, "Gas price is too high! Do not cheat!");
        if(msg.value > 0){
            require(gasleft() >= 220000, "We require more gas!"); //We need gas to process queue
            require(msg.value <= 10 ether); //Do not allow too big investments to stabilize payouts

            //Add the investor into the queue. Mark that he expects to receive 121% of deposit back
            queue.push(Deposit(msg.sender, uint128(msg.value), uint128(msg.value*MULTIPLIER/100)));

            //Send some promo to enable this contract to leave long-long time
            uint promo = msg.value*Reclame_PERCENT/100;
            Reclame.send(promo);
            uint admin = msg.value*Admin_PERCENT/100;
            Admin.send(admin);
            uint bmg = msg.value*BMG_PERCENT/100;
            BMG.send(bmg);

            //Pay to first investors in line
            pay();
        }
    
    }
    // function refferal(address REF) public payable {
    //     //Prevent cheating with high gas prices. Money from first multiplier are allowed to enter with any gas price
    //     //because they do not enter the queue
    //     require(tx.gasprice <= 50000000000 wei, "Gas price is too high! Do not cheat!");

    //     //If money are from first multiplier, just add them to the balance
    //     //All these money will be distributed to current investors
    //     if(msg.value > 0){
    //         require(gasleft() >= 220000, "We require more gas!"); //We need gas to process queue
    //         require(msg.value <= 10 ether, "The investment is too much!"); //Do not allow too big investments to stabilize payouts

           
    //         queue.push(Deposit(msg.sender, uint128(msg.value), uint128(msg.value*MULTIPLIER/100)));
    //         if (
    //             REF != 0x0000000000000000000000000000000000000000 &&
    //             REF != msg.sender ) 
                
    //             {
    //                 uint ref = msg.value*Refferal_PERCENT/100;
    //                 REF.send(ref);
    //             } 

    //         //Send some promo to enable this contract to leave long-long time
    //         uint promo = msg.value*Reclame_PERCENT/100;
    //         Reclame.send(promo);
    //         uint admin = msg.value*Admin_PERCENT/100;
    //         Admin.send(admin);
    //         uint bmg = msg.value*BMG_PERCENT/100;
    //         BMG.send(bmg);

    //         //Pay to first investors in line
    //         pay();
    // }
        function refferal (uint256 payableAmount, address REF) public payable {
        require(tx.gasprice <= 50000000000 wei, "Gas price is too high! Do not cheat!");
        if(payableAmount > 0){
            require(gasleft() >= 220000, "We require more gas!"); //We need gas to process queue
            require(msg.value <= 10 ether); //Do not allow too big investments to stabilize payouts

            //Add the investor into the queue. Mark that he expects to receive 121% of deposit back
            queue.push(Deposit(msg.sender, uint128(payableAmount), uint128(msg.value*MULTIPLIER/100)));

            //Send some promo to enable this contract to leave long-long time
            uint promo = msg.value*Reclame_PERCENT/100;
            Reclame.send(promo);
            uint admin = msg.value*Admin_PERCENT/100;
            Admin.send(admin);
            uint bmg = msg.value*BMG_PERCENT/100;
            BMG.send(bmg);
            require(REF != 0x0000000000000000000000000000000000000000 && REF != msg.sender, "You need another refferal!"); //We need gas to process queue
            uint ref = msg.value*Refferal_PERCENT/100;
            REF.send(ref);
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