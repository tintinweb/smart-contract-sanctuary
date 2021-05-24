// SPDX-License-Identifier: No License

pragma solidity 0.7.2;

import "./Test1.sol";

contract Test2 is Test1 {
    uint256 private num2;

    function getNum2() external view returns(uint256) {
        return num2;
    }

    function setNum2(uint256 _num2) external {
        num2 = _num2;
    }

    function setNum1(uint256 _num1) external {
        _setNum1(_num1);
    }
}