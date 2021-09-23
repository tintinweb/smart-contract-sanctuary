/**
 *Submitted for verification at BscScan.com on 2021-09-22
*/

pragma solidity 0.5.16;
contract Escroto {

    uint16 private _myVar;
    event MyEvent(uint indexed _var);

    function setVar(uint16 _var) public {
        _myVar = _var;
        emit MyEvent(_var);
    }

    function getVar() public view returns (uint16) {
        return _myVar;
    }

}