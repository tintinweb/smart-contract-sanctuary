/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

pragma solidity ^0.8.0;

contract MyContract {
    int256 private _x = 10;

    function plus(int256 temp) public view returns(int256) {
        return _x + temp;
    }

    function setX(int256 x_) public {
        _x = x_;
    }

    function getX() public view returns(int256) {
        return _x;
    }
}