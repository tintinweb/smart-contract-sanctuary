/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity >=0.8.0;

contract AzonGood
{
    string name;
    uint16 price;
    address owner;
    
    constructor(string memory _name, uint16 _price){
        name = _name;
        price = _price;
        owner = msg.sender;
    }
    
    function getName() public view returns(string memory){
        return name;
    }
    
    function setName(string memory _name) public payable{
        require(owner == msg.sender);
        name = _name;
    }
    
    function getPrice() public view returns(uint16){
        return price;
    }
    
    function setPrice(uint16 _price) public payable{
        require(owner == msg.sender);
        price = _price;
    }
    
    function getAddress() public view returns(address){
        return msg.sender;
    }
}


contract Shop{
    address[] goods;
    address owner;
    
    constructor(){owner = msg.sender;}
    
    function addGood(string memory name, uint16 price) public payable{
        require(owner == msg.sender);
        goods.push(address(new AzonGood(name, price)));
    }

    function getGoods() public view returns(string[] memory, uint16[] memory, address[] memory){
        string[] memory names = new string[](goods.length);
        uint16[] memory prices = new uint16[](goods.length);
    
        for(uint i = 0; i < goods.length; i++){
            names[i] = AzonGood(goods[i]).getName();
            prices[i] = AzonGood(goods[i]).getPrice();
        }

        return (names, prices, goods);
    }
}