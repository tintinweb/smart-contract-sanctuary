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
        
    }
    // Словарь с корзинами покупателей. Каждый покупатель идентифицируется по  своему адресу
    mapping(address => cart) carts;
    
    // Конструктор - запоминает адрес владельца магазина
    constructor()
    {
        owner = payable(msg.sender);
        
    }
    
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }
    modifier notOwner {
        require(msg.sender != owner);
        _;
    }
    
    // Функция добавления товара
    // Только владелец магазина может добавлять товар!
    function addGoods(string memory _newGood, uint32 _newGoodsPrice) public ownerOnly payable
    {
        name.push(_newGood);
        cost.push(_newGoodsPrice);
    }
    // Функция выводит список товаров в магазине - доступна всем
    function getGoods() public view returns(string[] memory)
    {
        return carts[msg.sender].goodsName;
    }
    
    // Добавления товара в корзину - для покупателей
    // Эта функция должна сразу рассчитывать новое значение totalCost при добавлении товара
    function addGoodsToCart(string memory _good) public notOwner payable
    {
        for (uint i = 0; i < name.length; i++) {
            if (keccak256(bytes(name[i])) == keccak256(bytes(_good))) {
                carts[msg.sender].totalCost += cost[i];
                carts[msg.sender].goodsName.push(_good);
            }
        }
    }
    // Вывести корзину
    function getCart() public view  returns(string[] memory, uint128)
    {
        return (carts[msg.sender].goodsName, carts[msg.sender].totalCost);
    }
    
    // Покупка товара
    // При вызове этой функции необходимо перевести эфир
    // Эфир переводится с адреса покупателя на адрес магазина
    // После покупки, корзина этого покупателя удаляется
    function buy() public notOwner payable 
    {
        require(msg.value >= carts[msg.sender].totalCost);
       payable(msg.sender).transfer(msg.value - carts[msg.sender].totalCost);
    }
    
    // Функция возвращает количество эфира на счёте магазина
    // Должна быть доступна только владельцу магазина
    function getBalance() public ownerOnly view returns(uint)
    {
        return address(this).balance;
    }
    
    // Функция вывода определённого количества эфира на адрес хозяина магазина
    function withdraw(uint256 _amount) public returns (bool) 
    {
        
        owner.transfer(_amount);
        return true;
    }
}