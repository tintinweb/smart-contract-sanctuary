pragma solidity ^0.4.10;

// NovaExchange Balance Recovery, last email accepted

contract balancesImporter1   {

address[] public addresses1;
uint256[] public balances1;

function balancesImporter1()    {

addresses1=[
0xb536f3a01458a62B49aB7a85FA8cd95e1bA19f56
];

balances1=[
28911051359610000000000
];

elixor elixorContract=elixor(0x898bf39cd67658bd63577fb00a2a3571daecbc53);
elixorContract.importAmountForAddresses(balances1,addresses1);

}
}

contract elixor  {

function importAmountForAddresses(uint256[] amounts,address[] addressesToAddTo);

}