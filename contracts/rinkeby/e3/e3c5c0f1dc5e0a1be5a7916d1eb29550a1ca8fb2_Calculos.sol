/**
 *Submitted for verification at Etherscan.io on 2021-10-17
*/

pragma solidity >=0.4.4 <0.7.0;

library Operaciones {
    function division(uint256 _i, uint256 _j) public pure returns (uint256) {
        require(_j > 0, "We cannot divide against zero");
        return _i / _j;
    }
}

contract Calculos {
    using Operaciones for uint256; // for uint means that the library will be used for uint data type. We can put `*` to make it available for all data types

    function calculo(uint256 _a, uint256 _b) public pure returns (uint256) {
        uint256 q = _a.division(_b);
        return (q);
    }
}