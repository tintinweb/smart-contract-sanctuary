pragma solidity 0.4.18;

contract ataka{
     address dc=0x767b132a4c1aa4947307eac3075b3f325f24c1c6;
    function setA_Signature() public returns(bool success){
        require(dc.call(bytes4(keccak256("BuyToyMoney()"))));
        return true;
    }
}