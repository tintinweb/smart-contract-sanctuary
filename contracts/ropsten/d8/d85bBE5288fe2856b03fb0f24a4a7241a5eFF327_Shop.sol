/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

// Контракт магазин
contract Shop
{
    // Здесь будет адрес владельца контракта
    // Для защиты от попыток сторонними людьми менять состояние магазина
    address payable owner;
    address payable shop;

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
        shop = payable(address(this));
    }
    
    
    
        
    //Проверяет, что операцию выполняет владелец
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    //Проверяет, что операцию выполняет покупатель
    modifier onlyCustomer(){
        require(msg.sender != owner);
        _;
    }
    
    
    
    //возвращает индекс элемента по имене
    function getIndexByName(string memory good_name) public view returns(uint256){
        for(uint256 i = 0; i < name.length; i++){
            if(keccak256(bytes(name[i])) == keccak256(bytes(good_name))){
                return i;
            }
        }
    }
    
    
    
    // Функция добавления товара
    // Только владелец магазина может добавлять товар!
    function addGoods(string memory good_name, uint32 good_cost) onlyOwner public payable
    {
        name.push(good_name);
        cost.push(good_cost);
    }
    // Функция выводит список товаров в магазине - доступна всем
    function getGoods() public view returns(string[] memory)
    {
        return name;
    }
    
    // Добавления товара в корзину - для покупателей
    // Эта функция должна сразу рассчитывать новое значение totalCost при добавлении товара
    function addGoodsToCart(string memory good_name, uint32 good_count) public payable
    {
        carts[msg.sender].goodsName.push(good_name);
        carts[msg.sender].goodsCount.push(good_count);
        carts[msg.sender].totalCost += cost[getIndexByName(good_name)] * uint128(good_count);
    }
    // Вывести корзину
    function getCart() public view  returns(string[] memory, uint32[] memory, uint128)
    {
        address sender = msg.sender;
        string[] memory good_names = carts[sender].goodsName;
        uint32[] memory good_counts = carts[sender].goodsCount;
        uint128 user_totalCost = carts[sender].totalCost;
        return (good_names, good_counts, user_totalCost);
    }
    
    // Покупка товара
    // При вызове этой функции необходимо перевести эфир
    // Эфир переводится с адреса покупателя на адрес магазина
    // После покупки, корзина этого покупателя удаляется
    function buy() public payable returns(bool)
    {
        if(msg.value < carts[msg.sender].totalCost){
            return false;
        }
        shop.send(carts[msg.sender].totalCost);
        payable(msg.sender).transfer(msg.value - carts[msg.sender].totalCost);
        delete carts[msg.sender];
        return true;
    }
    
    // Функция возвращает количество эфира на счёте магазина
    // Должна быть доступна только владельцу магазина
    function getBalance() onlyOwner public view returns(uint)
    {
        return (shop).balance;
    }
    
    // Функция вывода определённого количества эфира на адрес хозяина магазина
    function withdraw(uint _amount) onlyOwner public payable returns (bool) 
    {   
        if(!payable(owner).send(_amount))
        {
            return false;
        }
        return true;
    }
}