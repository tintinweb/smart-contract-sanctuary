/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract algo_naif {

    struct Pixel {
        address payable owner;
        uint price;
    }
    
    Pixel[1000][1000] public pixels;
    mapping(address => uint) pendingReturns;
    
    function buyRectangle(uint x0, uint y0, uint x1, uint y1, uint newprice) external payable {
        uint price = 0;
        for(uint x = x0; x < 1 + x1; x++){
            for(uint y = y0; y < 1 + y1; y++){
                Pixel storage px = pixels[x][y];
                pendingReturns[px.owner] += px.price;
                price += px.price;
                px.owner = payable(msg.sender);
                px.price = newprice;
            }
        }
        require(price <= msg.value, "fonds insuffisants");
        pendingReturns[msg.sender] += msg.value - price;
    }
    
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

}