/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

// Контракт магазин
contract Shop
{
    // Здесь будет адрес владельца контракта
    // Для защиты от попыток сторонними людьми менять состояние магазина
    address payable owner;
    
    // Товары
    string[] names;
    uint32[] costs;
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
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
    constructor() {
        owner = payable(msg.sender);
    }
    
    // Функция добавления товара
    // Только владелец магазина может добавлять товар!
    function addGoods(string memory _name, uint32 _cost) public onlyOwner payable {
        names.push(_name);
        costs.push(_cost);
    }
    
    // Функция выводит список товаров в магазине - доступна всем
    function getGoods() public view returns(string[] memory, uint32[] memory){
        return (names, costs);
    }
    
    function getCost(string memory _name) internal view returns(uint128) {
        bytes memory name = bytes(_name);
        for (uint i = 0; i < names.length; ++i)
            if (bytes(names[i]).length == name.length)
                if(keccak256(bytes(names[i])) == keccak256(name))
                    return costs[i];
    }
    
    function is_in_cart(string memory _name, cart memory c) internal pure returns(bool) {
        bytes memory name = bytes(_name);
        for (uint i = 0; i < c.goodsName.length; ++i)
            if (bytes(c.goodsName[i]).length == name.length)
                if(keccak256(bytes(c.goodsName[i])) == keccak256(name))
                    return true;
        return false;
    }
    
    function get_index(string memory _name, cart memory c) internal pure returns(uint) {
        bytes memory name = bytes(_name);
        for (uint i = 0; i < c.goodsName.length; ++i)
            if (bytes(c.goodsName[i]).length == name.length)
                if(keccak256(bytes(c.goodsName[i])) == keccak256(name))
                    return i;
    }
    
    // Добавления товара в корзину - для покупателей
    // Эта функция должна сразу рассчитывать новое значение totalCost при добавлении товара
    function addGoodsToCart(string memory _name) public payable {
        carts[msg.sender].totalCost += getCost(_name);
        bool res = is_in_cart(_name, carts[msg.sender]);
        if (res == false) {
            carts[msg.sender].goodsName.push(_name);
            carts[msg.sender].goodsCount.push(1);
        } else {
            uint index = get_index(_name, carts[msg.sender]);
            carts[msg.sender].goodsCount[index] += 1;
        }
        
    }
    
    // Вывести корзину
    function getCart() public view  returns(string[] memory, uint32[] memory, uint128) {
        cart memory c = carts[msg.sender];
        return (c.goodsName, c.goodsCount, c.totalCost);
    }
    
    // Покупка товара
    // При вызове этой функции необходимо перевести эфир
    // Эфир переводится с адреса покупателя на адрес магазина
    // После покупки, корзина этого покупателя удаляется
    function buy() public payable returns(bool) {
        require(msg.value >= carts[msg.sender].totalCost, "Not enough value");
        delete carts[msg.sender];
        bool res = payable(msg.sender).send(msg.value - carts[msg.sender].totalCost);
        return res;
    }
    
    // Функция возвращает количество эфира на счёте магазина
    // Должна быть доступна только владельцу магазина
    function getBalance() public onlyOwner view returns(uint) {
        return address(this).balance;
    }
    
    // Функция вывода определённого количества эфира на адрес хозяина магазина
    function withdraw(uint _amount) public payable onlyOwner returns (bool) {
        return owner.send(_amount);
    }
}