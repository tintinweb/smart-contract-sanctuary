/**
 *Submitted for verification at BscScan.com on 2021-09-24
*/

pragma solidity 0.5.16;
contract Escroto {

    uint16 private _myVar;
    bytes32 public txt;
    uint16 public num;
    
    event MyEvent(uint indexed _var);

	constructor(bytes32 _txt, uint16 _num) public {
		txt = _txt;
		num = _num;
	}

    function setVar(uint16 _var) public {
        _myVar = _var;
        emit MyEvent(_var);
    }

    function getVar() public view returns (uint16) {
        return _myVar;
    }

}