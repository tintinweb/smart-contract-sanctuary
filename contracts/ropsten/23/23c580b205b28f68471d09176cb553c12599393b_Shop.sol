/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

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

     function getCart(uint x) public view returns(string[] memory, uint32[] memory, uint128)
    {
        return (carts[msg.sender].goodsName, carts[msg.sender].goodsCount, carts[msg.sender].totalCost);
    }

    function buy() public payable returns(bool)
    {
        if(carts[msg.sender].totalCost >= msg.value)
        {
            if(!(payable(address(this))).send(carts[msg.sender].totalCost))
            {
                
                delete carts[msg.sender];
                return true;
            }
        return false;
        }
        return false;
    }
    

    function getBalance() public view returns(uint)
    {
        
        require(owner == msg.sender);
        return address(this).balance;
    }
    

    function withdraw(uint _amount) public returns (bool) 
    {

        require(owner == msg.sender);
        

        if (address(this).balance >= _amount) 
        {
            if (!owner.send(_amount)) {
                return true;
            }
        }
        return false;
    }
}