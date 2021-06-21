/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

pragma solidity 0.8.0;
 
// контракт описывает товар
contract Good
{
    address goodAddress = address(this);
    address owner;
    string name;
    uint32 cost;
    // Конструктор принимает два параметра - наименование и цену
    constructor(string memory _name, uint32 _cost)
    {
        owner = msg.sender;
        name = _name;
        cost = _cost;
    }
    // Геттеры
    function getName() public view returns(string memory)
    {
        return name;
    }
    function getCost() public view returns(uint32)
    {
        return cost;
    }
    function getGoodAddresses() public view returns(address)
    {
        return goodAddress;
    }
    // Сеттер
    function setCost(uint32 _cost) public payable
    {
        require(owner == msg.sender);
        cost = _cost;
    }
}
// Контракт магазин
contract Shop
{
    // Содержит в себе динамический массив АДРЕСОВ контрктов товаров
    address[] goods;
    
    // И адрес создателя магазина
    address owner;
    constructor()
    {
        owner = msg.sender;
    }
    
    // Добавляем новый товар
    function addGoods(string memory _name, uint32 _cost) public payable
    {
        require(owner == msg.sender);
        goods.push(address(new Good(_name, _cost)));
    }
    
    // Возвращает информацию о конкретном товаре по индексу товара
    function getGood(uint _index) public view returns(address, string memory, uint32)
    {
        return (goods[_index], Good(goods[_index]).getName(), Good(goods[_index]).getCost());
    }
    
    // Возвращаем список товаров в виде трёх массивов
    function getGoods(uint _index) public view returns(string[] memory, uint32[] memory, address[] memory)
    {
        string[] memory names = new string[](goods.length);
        uint32[] memory costs = new uint32[](goods.length);
        address[] memory addresses = new address [](goods.length);
        for(uint16 i; i < goods.length; i++)
        {
            names[i] = Good(goods[i]).getName();
            costs[i] = Good(goods[i]).getCost();
            addresses[i] = Good(goods[i]).getGoodAddresses();
        }
        return (names, costs, addresses);
    }
    
}