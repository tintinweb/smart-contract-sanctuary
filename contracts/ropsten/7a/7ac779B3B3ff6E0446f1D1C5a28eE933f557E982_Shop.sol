/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract Shop
{
    address payable owner;
    
    string[] name;
    uint32[] cost;
    address[] adresses;

    struct cart
    {
        uint128 totalCost;
        string[] goodsName;
        uint32[] goodsCount;
    }

    mapping(address => cart) carts;
    

    constructor()
    {
        owner = payable(msg.sender);
    }

    function addGoods(string memory _name, uint32 _cost) public payable
    {
        require(owner == msg.sender);
        name.push(_name);
        cost.push(_cost);
    }

    function getGoods(uint x) public view returns(string[] memory, uint32[] memory)
    {
        return (name, cost);
    }

    function addGoodsToCart(string memory _name, uint32 _count) public payable
    {
        bool flag = false;
        for(uint i = 0; i < adresses.length; ++i){
            if(adresses[i] == msg.sender){
                flag = true;
                break;
            }
        }
        if(flag){
            for(uint i = 0; i < name.length; ++i){
                if(keccak256(bytes(name[i])) == keccak256(bytes(_name))){
                    carts[msg.sender].goodsCount.push(_count);
                    carts[msg.sender].goodsName.push(_name);
                    carts[msg.sender].totalCost += _count * cost[i];
                    break;
                }
            }
        }
    }

    function getCart(uint x) public view  returns(string[] memory, uint32[] memory, uint128)
    {
        return (carts[msg.sender].goodsName, carts[msg.sender].goodsCount, carts[msg.sender].totalCost);
    }
    

    function buy() public payable returns(bool)
    {
        if(!owner.send(carts[msg.sender].totalCost))
        {
            return false;
        }
        delete carts[msg.sender];
        return true;
    }

    function getBalance() public view returns(uint)
    {
        return owner.balance;
    }
    
    function deleteProduct(string memory _name) public payable {
        require(owner == msg.sender);
        for(uint i = 0; i < name.length; ++i){
            if(keccak256(bytes(name[i])) == keccak256(bytes(_name))){
                for(uint j = 0; j < adresses.length; ++j){
                    for(uint x = 0; x < carts[adresses[j]].goodsName.length; ++x){
                        if(keccak256(bytes(carts[adresses[j]].goodsName[x])) == keccak256(bytes(_name))){
                            carts[adresses[j]].totalCost -= carts[adresses[j]].goodsCount[x] * cost[i];
                            delete carts[adresses[j]].goodsName[x];
                            delete carts[adresses[j]].goodsCount[x];
                        }
                    }
                }
                delete name[i];
                delete cost[i];
                break;
            }
        }
    }
    
    function deleteProductFromCart(string memory _name) public payable {
        uint128 sumx = 0;
        for(uint i = 0; i < name.length; ++i){
            if(keccak256(bytes(name[i])) == keccak256(bytes(_name))){
                sumx = cost[i];
                break;
            }
        }
        for(uint x = 0; x < carts[msg.sender].goodsName.length; ++x){
            if(keccak256(bytes(carts[msg.sender].goodsName[x])) == keccak256(bytes(_name))){
                carts[msg.sender].totalCost -= carts[msg.sender].goodsCount[x] * sumx;
                delete carts[msg.sender].goodsName[x];
                delete carts[msg.sender].goodsCount[x];
            }
         }
    }

    function withdraw(uint _amount) public returns (bool) 
    {
        if(!owner.send(_amount))
        {
            return false;
        }
        return true;
    }
}