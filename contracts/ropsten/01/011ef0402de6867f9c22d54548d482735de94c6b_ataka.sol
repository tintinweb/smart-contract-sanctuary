pragma solidity 0.4.18;
contract ataka{
    address wad=0x767b132a4c1aa4947307eac3075b3f325f24c1c6;
  function lanch_atak() public{
 wad.call(bytes4(keccak256("BuyToyMoney.value(0.1)")));
  }  
}