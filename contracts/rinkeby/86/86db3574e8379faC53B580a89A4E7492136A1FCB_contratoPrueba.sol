/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

pragma solidity >=0.7.0 <0.9.0;

contract contratoPrueba{
    uint256 monto;
    constructor(){
        monto = 20;
    }
    function setterCustom(uint256 _monto) public{
        monto = _monto;
    }
    function getterCustom() view public returns(uint256 _monto){
      _monto = monto;
    }
}