/**
Сумма всех процентов = 2% фиксированный + Динамический процент от баланса контракта + Индивидуальный процент с суммы вклада.
Примеры:
Если вы внесли 1 ETH и баланс контракта 10 ETH, то Ваш суммарный процент = 2.009166666 %
Если вы внесли 10 ETH и баланс контракта 250 ETH, то Ваш суммарный процент = 2.19166666 %
Если вы внесли 15 ETH и баланс контракта 1200 ETH, то Ваш суммарный процент = 2,83755 %
Если вы внесли 20 ETH и баланс контракта 3777 ETH, то Ваш суммарный процент = 4.568 %

Чем больше вклад и собранные инвестиции, тем больше Ваш процент.
 */
 
pragma solidity ^0.4.25;
contract NOTBAD_DynamicS {
    mapping (address => uint256) public invested;
    mapping (address => uint256) public atBlock;
    function () external payable
    {
        if (invested[msg.sender] != 0) {
            // Выплата = 2% фиксированный + (баланс контракта в момент запроса выплаты / 1500) + (сумма инвестиции / 400 ) / 100 * (номер блока вЫхода - номер блока вхОда) / средняя сумма блоков в сутки. 
            uint256 amount = invested[msg.sender] * ( 2 + ((address(this).balance / 1500) + (invested[msg.sender] / 400))) / 100 * (block.number - atBlock[msg.sender]) / 6000;
            msg.sender.transfer(amount);
        }
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
}