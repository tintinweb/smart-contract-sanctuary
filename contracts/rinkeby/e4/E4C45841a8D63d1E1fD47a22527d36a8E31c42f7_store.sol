/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;


contract product{
    string private name;
    uint32 private price;
    address private immutable thisContract = address(this);
    address private immutable owner;
    
    constructor(string memory _name, uint32 _price){
        name = _name;
        price = _price;
        owner = msg.sender;
    }
    
    function getName() public view returns(string memory){
        return name;
    }
    
    function getPrice() public view returns(uint32){
        return price;
    }
    
    function getAdress() public view returns(address){
        return thisContract;
    }
    
    function setPrice(uint32 _price) public payable{
        require(owner == msg.sender);
        price = _price;
    }
}

contract store{
    address[] private products;
    address[] private baskets;
    string[] private sp1;
    uint32[] private sp2;
    address private immutable owner;
    uint72 private proceeds = 0;
    
    constructor(){
        owner = msg.sender;
    }
    
    function addProduct(string memory _name, uint32 _price) public payable{
        require(owner == msg.sender);
        products.push(address(new product(_name, _price)));
        sp1.push(_name);
        sp2.push(_price);
    }
    
    function showProducts() public view returns(string[] memory, uint32[] memory, address[] memory, uint72){
        return (sp1, sp2, products, proceeds);
    }
    
    function getProductsAdress() external view returns(address[] memory){
        return products;
    }
    
    function addProfit(uint64 _x, address adrs) external payable{
        for(uint i = 0; i < baskets.length; ++i){
            if(baskets[i] == adrs){
                proceeds += _x;
                break;
            }
        }
    }
    
    function addBasket(address _x) external payable{
        basket(_x);
        baskets.push(_x);
    }
}

contract basket{
    address private immutable owner;
    address private immutable magazin;
    mapping(address => uint32) private productsToBuy;
    address[] private productsAdress;
    uint64 private deposit;
    uint64 private sumx = 0;
    address[] private sp;
    
    constructor(uint64 _deposit, address _magazin){
        owner = msg.sender;
        deposit = _deposit;
        magazin = _magazin;
    }
    
    function addProduct(address prdct, uint32 quantity) public payable{
        require(owner == msg.sender);
        productsToBuy[prdct] = quantity;
        store(magazin).addBasket(address(this));
        productsAdress.push(prdct);
    }
    
    function buy() public payable{
        require(owner == msg.sender);
        sumx = 0;
        sp = store(magazin).getProductsAdress();
        bool flag = false;
        for(uint i = 0; i < productsAdress.length; ++i){
            flag = false;
            for(uint j = 0; j < sp.length; ++j){
                if(productsAdress[i] == sp[j]){
                    flag = true;
                }
            }
            if(flag){
                sumx += product(productsAdress[i]).getPrice() * productsToBuy[productsAdress[i]];
            }
        }
        if(deposit >= sumx){
            deposit -= sumx;
            store(magazin).addProfit(sumx, address(this));
        }
    }
}