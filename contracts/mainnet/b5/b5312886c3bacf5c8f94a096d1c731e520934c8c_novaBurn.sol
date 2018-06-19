pragma solidity ^0.4.10;

// NovaExchange Balance Burn

contract novaBurn   {
    
address[] addresses;
uint256[] balances;

function novaBurn()    {

addresses=[0x8bb1597ab90b1c2d6ba1b6ce0f7abc8b83383d21];

balances=[3101719659689180000000000];

elixor elixorContract=elixor(0x898bf39cd67658bd63577fb00a2a3571daecbc53);
elixorContract.removeAmountForAddresses(balances,addresses);

}
}

contract elixor  {

function removeAmountForAddresses(uint256[] amounts,address[] addressesToRemoveFrom) public;

}