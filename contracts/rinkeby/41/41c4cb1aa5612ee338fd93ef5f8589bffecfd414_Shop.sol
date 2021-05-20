/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
 
// Контракт описывает товар
contract Good
{
    // Здесь будет адрес владельца контракта
    // Для защиты от попыток сторонними людьми менять цены на товары
    address owner;
    
    // Это характеристики товара
    address goodAddress = address(this);
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
        // Происходит проверка, что именно владелец контракта вносит изменения
        require(owner == msg.sender);
        cost = _cost;
    }
}
 
// Контракт корзина
contract Cart
{
    // Здесь будет адрес владельца контракта
    // Для защиты от попыток сторонними людьми менять состояние корзины
    address owner;
 
    // Сама корзина, на этот раз реализованна как динамический массив структур
    struct cartStruct
    {
        address goodAddress;
        uint32 goodCount;
    }
    cartStruct[] cart;
    
    // Стоимость товаров в корзине
    uint32 summa = 0;
    
    constructor(address _owner)
    {
        owner = _owner;
    }
    
    // Добавление товара в корзину
    function addGood(address _goodAddress, uint32 _goodCount) public payable
    {
        // Только хозяин корзины может вносить изменения
        require(owner == msg.sender);
        
        // Добвляем новую структуру в массив и инициализируем значениями её поля
        cart.push();
        cart[cart.length - 1].goodAddress = _goodAddress;
        cart[cart.length - 1].goodCount = _goodCount;
        
        // Добавляем в сумму стоимость этого товара
        summa += Good(_goodAddress).getCost() * _goodCount;
    }
    
    // Вывести стоимость товаров в корзине
    function getSumma()public view returns(uint)
    {
        // Только хозяин корзины может посмотреть эти значения
        require(owner == msg.sender);
        return summa;
    }
    
    // Два следующих метода нужны для оплаты корзины в магазине
    // Хозяин корзины отправляет в метод магазина buy() адрес своей корзины
    // А этот метод должен проверить, что имеет дело с реальным хозяином магазина
    // И узнать, что у него достаточно денег для покупки
    
    // Проверяем, что это действительно хозяин корзины
    function getOwner(address _owner) external view returns(bool)
    {
        require(owner == _owner);
        return true;
    }
    
    // Получаем сумму за товары в корзине
    function getSumma(address _owner) external view returns(uint)
    {
        // Только хозяин корзины может посмотреть эти значения
        require(owner == _owner);
        return summa;
    }
    
    // Очищаем корзину
    function clearCart(address _owner) external payable
    {
        require(owner == _owner);
        delete cart;
        summa = 0;
    }
}
// Контракт магазин
contract Shop
{
    // Здесь будет адрес владельца контракта
    // Для защиты от попыток сторонними людьми менять состояние магазина
    address owner;
    
    // Адресс контракта для приём оплаты за покупки
    address payable shopAddress = payable(address(this));
    
    // Содержит в себе динамический массив АДРЕСОВ контрктов товаров
    address[] goods;
    
    // Содержит в себе динамический массив АДРЕСОВ контрактов корзин
    address[] carts;
    constructor()
    {
        owner = msg.sender;
    }
    
    // Добавляем новый товар
    function addGoods(string memory _name, uint32 _cost) public payable
    {
        // Только хоязин магазина может добавлять товар
        require(owner == msg.sender);
        goods.push(address(new Good(_name, _cost)));
    }
    
    // Возвращаем список товаров в виде трёх массивов
    function getGoods() public view returns(string[] memory, uint32[] memory, address[] memory)
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
    
    function getCash() public view returns(uint)
    {
        // Только хозяин корзины может посмотреть эти значения
        require(owner == msg.sender);
        return shopAddress.balance;
    }
    
    // Создаём новую корзину
    function newCart() public payable
    {
        carts.push(address(new Cart(msg.sender)));
    }
    // Метод для получения денег за покупку
    function buy(address _cart) public payable returns(bool)
    {
        // Проверяем, что этот метод вызван хозяином корзины
        // Проверяем, что он прислал достаточно эфира, чтобы оплатить товары в корзине
        require(Cart(_cart).getOwner(msg.sender) && msg.value >= Cart(_cart).getSumma(msg.sender));
        
        // Если всё хорошо - проводим транзакцию
        if(!payable(shopAddress).send(msg.value))
        {
            // Если транзакция прошла успешно - очищаем корзину
            Cart(_cart).clearCart(msg.sender);
            return true;
        }
        return false;
    }
    
    // Функция вывода определённого количества эфира на аккаунт хозяина магазина
    function withdraw(uint amount) public returns (bool) 
    {
        // Только хозяин корзины может вызвать этот метод
        require(owner == msg.sender);
        
        // Если у нас достаточно эфира - выполняем перевод
        if (address(this).balance >= amount) 
        {
            if (!payable(msg.sender).send(amount)) {
                return true;
            }
        }
        return false;
    }
}