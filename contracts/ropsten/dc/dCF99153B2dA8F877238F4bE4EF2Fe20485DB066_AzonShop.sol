/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: GPL-3.0
//Устанавливаем версии компилятора
pragma solidity =0.8.0;
contract AzonGood
{
    string name;
    uint32 price;
    address immutable address1;
    address immutable owner ;
    constructor(string memory _name, uint32 _price)
        {
            name = _name;
            price = _price;
            address1 = address(this);
            owner = msg.sender;
        }
    function getPrice() public view returns(uint32)
        {
            return price;
        }
    function getAdds() public view returns(address)
        {
            return address1;
        }
    function getName() public view returns(string memory)
        {
            return name;
        }
    function setPrice(uint32 _price) public payable
        {
            require(owner == msg.sender);
            price = _price;
        }
}
contract AzonShop
{
        address[] goods;
        address immutable owner;
        uint32 cash = 0;
        constructor()
        {
            owner = msg.sender;
        }
        function addGood(string memory _name, uint32 _price) public payable
        {
            require(msg.sender == owner);
            goods.push(address(new AzonGood(_name, _price)));
        }
        function getGoods() public view returns(string [] memory, uint32[] memory, address[] memory)
        {
            string[] memory names = new string[](goods.length);
            uint32[] memory prices = new uint32[](goods.length);
            for(uint i = 0; i <goods.length; i++)
            {
                names[i] = AzonGood(goods[i]).getName();
                prices[i] = AzonGood(goods[i]).getPrice();
            }
            return (names,prices,goods);
        }
        function buy(address _azonCart) public payable
        {
           
           cash+=AzonCart(_azonCart).buy(msg.sender);
        }
}
contract AzonCart
{
    address owner;
    mapping(address => uint16) cart;
    uint32 deposit = 0;
    uint32 sum = 0;
    constructor(uint32 _deposit)
    {
        deposit = _deposit;
        owner = msg.sender;
    }
    function addGoodToCart (address _goodAddress, uint16 _goodCount) public payable
    {
        require(msg.sender == owner);
        cart[_goodAddress] = _goodCount;
        sum += AzonGood(_goodAddress).getPrice()* _goodCount;
    }
    function buy(address _buyer) public payable returns(uint32)
    {
        if( _buyer == owner && deposit >= sum)
        {
            
            uint32 cash = sum;
            deposit -= sum;
            sum = 0;
            return cash;
        }
        else
        {
            return 0;
        }
    }
}