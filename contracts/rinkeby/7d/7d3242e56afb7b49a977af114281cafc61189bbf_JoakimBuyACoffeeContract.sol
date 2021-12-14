/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract JoakimBuyACoffeeContract{

    struct coffee{
        string TypeOfCoffee;
        uint256 priceCoffee;
        bool estadoPagado;
    }

    mapping(uint => coffee) coffees;

    function createCoffee(uint256 idCoffee, string memory _nameCoffee, uint256 _priceCoffee) public{
        coffee storage newCoffee = coffees[idCoffee];
        newCoffee.TypeOfCoffee = _nameCoffee;
        newCoffee.priceCoffee = _priceCoffee;
        newCoffee.estadoPagado = false;
    }

    function buyCoffee(uint256 idCoffee) payable public{
        require(msg.value == coffees[idCoffee].priceCoffee, "Error: La cantidad no es igual al precio"); // Validamos ETH enviados por el pagador
        coffees[idCoffee].estadoPagado = true;
        payable(msg.sender).transfer(msg.value); //Sender = direccion pagador
    }

    function getEstadoPagado(uint256 idCoffee) public view returns(coffee memory infoCoffee){
        infoCoffee = coffees[idCoffee];
        return infoCoffee;
    }


}