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
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    
    function addGoods(string memory _name, uint32 _cost) onlyOwner public payable
    {
        name.push(_name);
        cost.push(_cost);
    }
    
    function addGoodsToCart(string memory _name, uint32 _count) public payable
    {
        bool check = false;
        for(uint32 i = 0; i < carts[msg.sender].goodsName.length; i++)
        {
            if(keccak256(bytes(carts[msg.sender].goodsName[i])) == keccak256(bytes(_name)))
            {
                carts[msg.sender].goodsCount[i] += _count;
                check = true;
                break;
            }
        }
        
        if(check == false)
        {
            carts[msg.sender].goodsName.push(_name);
            carts[msg.sender].goodsCount.push(_count);
        }
        
        for(uint32 i = 0; i < carts[msg.sender].goodsName.length; i++)
        {
            for(uint32 j = 0; j < name.length; j++)
            {
                if(keccak256(bytes(carts[msg.sender].goodsName[i])) == keccak256(bytes(_name)))
                {
                    carts[msg.sender].totalCost += _count * cost[j];
                }
            }
        }
    }
    
    function getBalance() onlyOwner public view returns(uint)
    {
        return address(this).balance;
    }
    
    function withdraw(uint _amount) onlyOwner public returns (bool) 
    {
        if (address(this).balance >= _amount) 
        {
            if (!owner.send(_amount)) {
                return true;
            }
        }
        return false;
    }
    
    function getGoods(bool _show) public view returns(string[] memory, uint32[] memory)
    {
        if (_show)
            return (name, cost);
    }
    
    function getCart(bool _show) public view  returns(string[] memory, uint32[] memory, uint128)
    {
        if (_show)
            return (carts[msg.sender].goodsName, carts[msg.sender].goodsCount, carts[msg.sender].totalCost);
    }
    
    function buy() public payable returns(string memory)
    {
        if(carts[msg.sender].totalCost >= msg.value)
        {
            if(!(payable(address(this))).send(carts[msg.sender].totalCost))
            {
                delete carts[msg.sender];
                return "It's yours my friend! As long as you have enough ether!";
            }
            return "Im sorry Link, I cant give credit! Come back when you a little, MMMMMM, richer!";
        }
        return "Im sorry Link, I cant give credit! Come back when you a little, MMMMMM, richer!";
    }
}