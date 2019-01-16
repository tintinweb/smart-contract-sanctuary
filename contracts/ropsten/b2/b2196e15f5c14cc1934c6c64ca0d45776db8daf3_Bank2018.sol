pragma solidity ^0.4.25;
/* 
              version:0.4.25+commit.59dbf8f1.Emscripten.clang
              
    Этот контракт (Bank2018) является очень долго живущей пирамидой!!!
    Цель этой пирамиды, помощь в поддержке бизнеса. Не рекомендую пользоваться данной пирамидой людям
    с образованием ниже среднего !!! Денег из воздуха не бывает! Получаемый с пирамиды доход получается
    посредством рискового актива и не очень подходит для мелкого вкладчика. Сильному же инвестору обеспечит 
    подстраховку убывающих активов и стабильную поддержку.Так же рекомендую разбивать актив частями - что
    минимизирует потерю при утрате доступа к кошельку. Эта пирамида на много честнее и выгоднее любого 
    банка и страховой компании. Вложив сюда средства, вы сделаете себе подушку безопасности.
    
    Теперь основная работа ;
    
    Переведите на смарт контракт ETH и вам будут начислятся % каждые 16 секунд. Получать свои дивиденды можно 
    буквально сразу но, учитывая стоимость транзакции не имеет смысла выводить менее 0.01 ETH.
    Выплаты будут происходить до тех пор, пока на балансе контракта есть ETH.
    Выплачиваемые проценты зависят от общего баланса контракта 
    до 100   ETH баланс контракта  1.0% от суммы инвестирования за период создания блокчейном 6500 блоков = в сутках 6100 блоков.
    от 100   ETH баланс контракта  1.1% от суммы инвестирования за период создания блокчейном 6500 блоков = в сутках 6100 блоков.
    от 300   ETH баланс контракта  1.2% от суммы инвестирования за период создания блокчейном 6500 блоков = в сутках 6100 блоков.
    от 500   ETH баланс контракта  1.3% от суммы инвестирования за период создания блокчейном 6500 блоков = в сутках 6100 блоков.
    от 1000  ETH баланс контракта  1.4% от суммы инвестирования за период создания блокчейном 6500 блоков = в сутках 6100 блоков.
    от 3000  ETH баланс контракта  1.5% от суммы инвестирования за период создания блокчейном 6500 блоков = в сутках 6100 блоков.
    от 5000  ETH баланс контракта  1.1% от суммы инвестирования за период создания блокчейном 6500 блоков = в сутках 6100 блоков.
    от 7000  ETH баланс контракта  1.6% от суммы инвестирования за период создания блокчейном 6500 блоков = в сутках 6100 блоков.
    от 10000 ETH баланс контракта  1.0% от суммы инвестирования за период создания блокчейном 6500 блоков = в сутках 6100 блоков.
    Для примера - Если баланс контракта 1000 ETH и вы инвестировали 100 eth то выплаты составят 1.4 eth каждые 25ч. 30м.
    Есть реферальная программа дающая вознаграждение в размере 2% от суммы депозита. Вкладчику необходимо указать ваш кошелёк
    в транзакции во вкладке DATA.
    Если во вкладке DATA не указан реферал то, данное вознаграждение получу я. Более нет в контракте отчислений !!!
    Владелец у контракта отсутствует и вмешаться в его работу нет возможности.
    
    Machine translation
    
   This contract is a very long living pyramid!!!
 The purpose of this pyramid is to help support business. I do not recommend to use this pyramid people
 with lower secondary education !!! Money from the air does not happen! The income received from the pyramid is obtained
 through a risky asset and not very suitable for a small depositor. Strong same investor will provide 
 insurance of decreasing assets and stable support.So I recommend to split the asset in portions that
 minimizes the loss of access to the wallet. This pyramid is much more honest and profitable than any 
 Bank and insurance company. By investing here, you will make yourself a safety cushion.
    For example - If the balance of the contract ETH 1000 and you invested 100 eth payments will be 1.4 eth every 25ч. 30m.
    
 There is a referral program giving a reward of 2% of the Deposit amount. The depositor must specify your wallet
 in the transaction in the DATA tab.
 If the tab DATA is not specified in the referral, the reward I get. No longer in contract assignments !!!
 The owner of the contract is absent and there is no opportunity to interfere in his work.
 
*/

contract Bank2018 {

    mapping (address => uint256) public invested;
    mapping (address => uint256) public atBlock;
    address defaultReferrer = 0x9D0947D762CD03Be136faF02ab31D9BED491153f;
    uint refPercent = 2;
    uint refBack = 2;
    // Расчет доли прибыли в зависимости от баланса 
    // Возвращает процент умноженный на 10
    // Calculation of the percentage of profit depending on the balance sheet
    // Returns the percentage times 10
    function calculateProfitPercent(uint bal) private pure returns (uint)
    {
        if (bal >= 1e22) { // balance >= 10000 ETH
            return 10;
        }
        if (bal >= 7e21) { // balance >= 7000 ETH
            return 16;
        }
        if (bal >= 5e21) { // balance >= 5000 ETH
            return 11;
        }
        if (bal >= 3e21) { // balance >= 3000 ETH
            return 15;
        }
        if (bal >= 1e21) { // balance >= 1000 ETH
            return 14;
        }
        if (bal >= 5e20) { // balance >= 500 ETH
            return 13;
        }
        if (bal >= 3e20) { // balance >= 300 ETH
            return 12;
        }
        if (bal >= 1e20) { // balance >= 100 ETH
            return 11;
        } else {
            return 10;
        }
    }

    // Конвертация байтов в адрес
    // convert bytes to eth address 
    function bytesToAddress(bytes bys) private pure returns (address addr)
    {
        assembly
        {
            addr := mload(add(bys, 20))
        }
    }
    
    // Передача рефбека по умолчанию и реферера в процентах от инвестированного
    // Transfer default refback and referrer percents of invested
    function transferRefPercents(uint value, address sender) private {
        if (msg.data.length != 0) {
            address referrer = bytesToAddress(msg.data);
            if(referrer != sender) {
                sender.transfer(value * refBack / 100);
                referrer.transfer(value * refPercent / 100);
            } else {
                defaultReferrer.transfer(value * refPercent / 100);
            }
        } else {
            defaultReferrer.transfer(value * refPercent / 100);
        }
    }
    
    
    
    
    // Расчёт прибыли как таковой:
    // сумма = (сумма инвестиций) * ((процент * 10)/ 1000) * (блоки с прошлой сделки) / 6500
    // процент умножается на 10 что бы избавиться от дробных процентов, а затем делится на 1000 вместо 100
    // 6500-это среднее количество блоков производимых Eth блокчейном в сутки 

    // calculate profit amount as such:
    // amount = (amount invested) * ((percent * 10)/ 1000) * (blocks since last transaction) / 6500
    // percent is multiplied by 10 to calculate fractional percentages and then divided by 1000 instead of 100
    // 6500 is an average block count per day produced by Ethereum blockchain
    function () external payable {
        if (invested[msg.sender] != 0) 
        {
            
            uint thisBalance = address(this).balance;
            uint amount = invested[msg.sender] * calculateProfitPercent(thisBalance) / 1000 * (block.number - atBlock[msg.sender]) / 6500;

            address sender = msg.sender;
            sender.transfer(amount);
        }
        
    // Если внесены деньги то, проверяется рефбэк
    // If the money is deposited, the Refback is checked
        if (msg.value > 0)
        {
            transferRefPercents(msg.value, msg.sender);
        }
         // Если внесены деньги то, проверяется рефбэк
    // If the money is deposited, the Refback is checked   
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += (msg.value);
    }
}