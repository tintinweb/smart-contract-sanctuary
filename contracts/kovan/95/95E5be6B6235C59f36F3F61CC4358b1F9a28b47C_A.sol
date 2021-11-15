// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
contract A{
    uint256 public value;
    function setValue(uint256 _value) public virtual{
        value=_value;
    }
}

contract V2 is A{
    function setValue(uint256 _value)public override{
        value=_value+900;
    }
}

