/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-23
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
    function getGoods(uint x) public view returns(string[] memory, uint32[] memory)
    {
        return (name, cost);
    }
    
    function deleteGood(string memory _name) public payable
    {
        require(owner == msg.sender);
        for(uint32 i = 0; i < carts[msg.sender].goodsName.length; i++)
        {
            if(keccak256(bytes(carts[msg.sender].goodsName[i])) == keccak256(bytes(_name)))
            {
                delete carts[msg.sender].goodsName[i];
            }
        }
    }
    
    // Добавления товара в корзину - для покупателей
    function addGoodsToCart(string memory _name, uint32 _count) public payable
    {
        bool check = false;
        for(uint32 i = 0; i < carts[msg.sender].goodsName.length; i++)
        {
            if(keccak256(bytes(carts[msg.sender].goodsName[i])) == keccak256(bytes(_name)))
            {
                carts[msg.sender].goodsCount[i] += _count;
                check = true;
                break;
            }
        }
        if(check == false)
        {
            carts[msg.sender].goodsName.push(_name);
            carts[msg.sender].goodsCount.push(_count);
        }
        for(uint32 i = 0; i < carts[msg.sender].goodsName.length; i++)
        {
            for(uint32 j = 0; j < name.length; j++)
            {
                if(keccak256(bytes(carts[msg.sender].goodsName[i])) == keccak256(bytes(_name)))
                {
                    carts[msg.sender].totalCost += _count * cost[j];
                }
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
    function buy() public payable returns(bool)
    {
        if(carts[msg.sender].totalCost >= msg.value)
        {
            if(!(payable(address(this))).send(carts[msg.sender].totalCost))
            {
                // Если транзакция прошла успешно - очищаем корзину
                delete carts[msg.sender];
                return true;
            }
        return false;
        }
        return false;
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
    function withdraw(uint _amount) public returns (bool) 
    {
        // Только хозяин корзины может вызвать эту функцию
        require(owner == msg.sender);
        
        // Если у нас достаточно эфира - выполняем перевод
        if (address(this).balance >= _amount) 
        {
            if (!owner.send(_amount)) {
                return true;
            }
        }
        return false;
    }
}