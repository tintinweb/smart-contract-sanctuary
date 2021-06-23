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
        // Количество товара каждого наименования
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
        require(owner == msg.sender);
        name.push(_name);
        cost.push(_cost);
    }
    
    // Функция выводит список товаров в магазине - доступна всем
    // uint x нужно, чтобы на Etherscan нормально вывелись массивы. Если у функции не будет аргумента - не будет кнопки Query - а значит не будет нормального вывода `\:)/` 
    function getGoods(uint x) public view returns(string[] memory, uint32[] memory)
    {
        return(name, cost);
    }
    
    // Добавления товара в корзину - для покупателей
    // Эта функция должна сразу рассчитывать новое значение totalCost при добавлении товара
    function addGoodsToCart(string memory goodName, uint32 goodCount) public payable
    {
        bool check = false;
        for(uint32 i = 0; i < carts[msg.sender].goodsName.length; i++){
            if(keccak256(bytes(carts[msg.sender].goodsName[i])) == keccak256(bytes(goodName))){
                carts[msg.sender].goodsCount[i] += goodCount;
                check = true;
                break;
            }
        }
        
        if(check == false){
            carts[msg.sender].goodsName.push(goodName);
            carts[msg.sender].goodsCount.push(goodCount);
        }
        
        for(uint32 i = 0; i < carts[msg.sender].goodsName.length; i++)
        {
            if(keccak256(bytes(carts[msg.sender].goodsName[i])) == keccak256(bytes(goodName)))
            {
                carts[msg.sender].totalCost += goodCount * cost[i];
            }
        }
    }
    
    // Вывести корзину
    // uint x нужно, чтобы на Etherscan нормально вывелись массивы. Если у функции не будет аргумента - не будет кнопки Query - а значит не будет нормального вывода `\:)/` 
    function getCart(uint x) public view  returns(string[] memory, uint32[] memory, uint128)
    {
        return(carts[msg.sender].goodsName, carts[msg.sender].goodsCount, carts[msg.sender].totalCost);
    }
    
    // Покупка товара
    // При вызове этой функции необходимо перевести эфир
    // Эфир переводится с адреса покупателя на адрес магазина
    // После покупки, корзина этого покупателя удаляется
    function buy() public payable returns(bool)
    {
        if(carts[msg.sender].totalCost <= msg.value){
            if(!(payable(address(this))).send(carts[msg.sender].totalCost)){
                delete carts[msg.sender];
                return true;
            }
            return false;
        }
        return false;
    }
    
    // Функция возвращает количество эфира на счёте магазина
    // Должна быть доступна только владельцу магазина
    function getBalance() public view returns(uint)
    {
        require(owner == msg.sender);
        return address(this).balance;
    }
    
    // Функция вывода определённого количества эфира на адрес хозяина магазина
    function withdraw(uint _amount) public returns (bool) 
    {
        require(owner == msg.sender);
        if(address(this).balance >= _amount){
            if(!owner.send(_amount)){
                return true;
            }
        }
        return false;
    }
}