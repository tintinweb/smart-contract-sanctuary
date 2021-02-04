/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

// iERC20 Interface
interface iERC20 {
    function decimals() external returns (uint);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}

contract Faucet {

    address[] public coins;
    mapping(address => bool) public isAdded;

    constructor() {}

    function addCoin(address coin, uint amount) public {
        if(!isAdded[coin]){
            coins.push(coin);
            isAdded[coin] = true;
        }
        uint _one = 10 ** iERC20(coin).decimals();
        iERC20(coin).transferFrom(msg.sender, address(this), amount*_one);
    }

    function giveMeCoins() public {
        for(uint i = 0; i<coins.length; i++){
             uint _one = 10 ** iERC20(coins[i]).decimals();
            iERC20(coins[i]).transfer(msg.sender, 100*_one);
        }
    }

}