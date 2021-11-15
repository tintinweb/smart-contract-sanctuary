// SPDX-License-Identifier: MIT
pragma solidity =0.7.3;

contract Calc {
    uint private num = 0;

    event NumberSet(address _from, uint value);

    function getNum() public view returns(uint) {
        return num;
    }

    function setNum(uint _num) public {
        num = _num;

        emit NumberSet(msg.sender, _num);
    }
}

