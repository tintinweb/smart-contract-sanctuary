pragma solidity ^0.5.0;

contract SafeMath {
    function safeMul(uint a, uint b) internal pure returns(uint) {
        uint c = a * b;
        assertion(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns(uint) {
        assertion(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        assertion(c >= a && c >= b);
        return c;
    }

    function safeDiv(uint a, uint b) internal pure returns(uint) {
        require(b != 0, 'Divide by zero');

        return a / b;
    }

    function safeCeil(uint a, uint b) internal pure returns (uint) {
        require(b > 0);

        uint v = a / b;

        if(v * b == a) return v;

        return v + 1;  // b cannot be 1, so v <= a / 2
    }

    function assertion(bool flag) internal pure {
        if (!flag) revert('Assertion fail.');
    }
}
