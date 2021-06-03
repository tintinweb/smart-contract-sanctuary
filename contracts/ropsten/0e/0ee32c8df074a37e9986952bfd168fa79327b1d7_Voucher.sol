/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

contract Voucher {
    
    mapping (address => uint) public balances;
    
    constructor () {
        balances[0xab9fd352c1E5b7DD2434B044380BC843552D619a] = 10;
        balances[0xDB1003206DE6596d9fDE3Dae28f54AdCEd2D5378] = 10;
        balances[0x0835f29F4E39DEE36B63a991F460d056eF67B896] = 10;
        balances[0xd5908d1882D995643304EC5F7c2c799C72d20541] = 10;
        balances[0x576b874d46f38Ae27c45e5E6776872A12408696D] = 10;
        balances[0x8C49F759673895d5C59786899EDD6DB5673eEE4c] = 10;
        balances[0xe94681f6488B42e24110C66C5DefD16084ea4db1] = 10;
        balances[0x4086BC07f32CEcD3Ace35aD00d4aca556EAd2E83] = 10;
        balances[0x576b874d46f38Ae27c45e5E6776872A12408696D] = 10;
        balances[0xf633743481244bA38d921C0b541ACf895499404a] = 10;
        balances[0xA65F9FdB3f50968a514Df7da430eD9f859B47Cad] = 10;
        balances[0x99F310B5038Fd53A0c5d0C9937dF7D36a4D43FD4] = 10;
        balances[0x723d6CE98DfE4a92E9643eB1cDf95142904B6cB4] = 10;
        balances[0xD9916Aa8ac8a2c6262b87E4614D733fCdb87a216] = 10;
        balances[0xca3a8a73A06333C6A18b7957Ac26c262C948afE8] = 10;
    }
    
    function transfer(address destinatario, uint amount) public {
        require(balances[msg.sender] >= amount, "Fondi insufficienti");
        balances[msg.sender] -= amount;
        balances[destinatario] += amount;
    }
    
}