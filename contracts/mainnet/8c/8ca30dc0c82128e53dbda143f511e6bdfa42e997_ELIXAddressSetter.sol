pragma solidity ^0.4.10;

contract ELIXAddressSetter {

function ELIXAddressSetter() {
    address ELIXAddress=0xc8c6a31a4a806d3710a7b38b7b296d2fabccdba8;
    address EXORAddress=0x898bF39cd67658bd63577fB00A2A3571dAecbC53;
    elixor elixorContract=elixor(EXORAddress);
    elixorContract.setELIXAddress(ELIXAddress);
}

}

contract elixor {
    function setELIXAddress(address elixirAdress) public;
}