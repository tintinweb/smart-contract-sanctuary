/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

// Контракт магазин
contract Shop
{
    // Здесь будет адрес владельца контракта
    // Для защиты от попыток сторонними людьми менять состояние магазина
    address payable owner;

    // Товары
    string[] name;
    uint32[] cost;
    
    // Структура - корзина покупателя
    struct cart
    {
        // Общая сумма товаров в корзине
        uint128 totalCost;
        // Массив товаров
        string[] goodsName;
        // Количетсов товара каждого наименования
        uint32[] goodsCount;
    }
    // Словарь с корзинами покупателей. Каждый покупатель идентифицируется по  своему адресу
    mapping(address => cart) carts;
    
    // Конструктор - запоминает адрес владельца магазина
    constructor()
    {
        owner = payable(msg.sender);
    }
    
    // Функция добавления товара
    // Только владелец магазина может добавлять товар!
    function addGoods(string memory _name, uint32 _cost) public payable
    {
        // Только хозяин корзины может вызвать эту функцию
        require(owner == msg.sender);
        name.push(_name);
        cost.push(_cost);
    }
    // Функция выводит список товаров в магазине - доступна всем
    function getGoods() public view returns(string[] memory, uint32[] memory)
    {
        return (name, cost);
    }
    
    // Добавления товара в корзину - для покупателей
    function addGoodsToCart(string memory _name, uint32 _count) public payable
    {
        carts[msg.sender].goodsName.push(_name);
        carts[msg.sender].goodsCount.push(_count);
        for(uint i = 0; i < name.length; i++)
        {
            if(keccak256(bytes(name[i])) == keccak256(bytes(_name)))
            {
                carts[msg.sender].totalCost += _count * cost[i];
            }
        }
    }
    
    // Вывести корзину
    function getCart() public view  returns(string[] memory, uint32[] memory, uint128)
    {
        return (carts[msg.sender].goodsName, carts[msg.sender].goodsCount, carts[msg.sender].totalCost);
    }
    
    // Покупка товара
    // При вызове этой функции необходимо перевести эфир
    // Эфир переводится с адреса покупателя на адрес магазина
    // После покупки, корзина этого покупателя удаляется
    function buy() public payable returns(string memory)
    {
        require(msg.value >= carts[msg.sender].totalCost);
        // Если передано больше денег, чем надо, контракт возвращаем сдачу
        if(msg.value > uint( carts[msg.sender].totalCost))
        {
            
            payable(msg.sender).transfer(msg.value - uint( carts[msg.sender].totalCost));
        }
        // Если транзакция прошла успешно - очищаем корзину
        delete carts[msg.sender];
        return "Sold!";
    }
    
    // Функцмя возвращает количество эфира на счёте магазина
    // Должна быть доступна только владельцу магазина
    function getBalance() public view returns(uint)
    {
        // Только хозяин корзины может вызвать эту функцию
        require(owner == msg.sender);
        return address(this).balance;
    }
    
    // Функция вывода определённого количества эфира на адрес хозяина магазина
    function withdraw(uint _amount) public returns (string memory) 
    {
        // Только хозяин корзины может вызвать эту функцию
        // И если у нас достаточно эфира - выполняем перевод
        require(owner == msg.sender && address(this).balance >= _amount);
        owner.transfer(_amount);
        return "Funds withdrawn successfully";
    }
}