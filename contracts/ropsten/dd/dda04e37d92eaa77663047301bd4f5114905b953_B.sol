pragma solidity ^0.6.8;
import 'a.sol';

contract B {
    using SafeMath for uint256;

    uint256 count = 0;
    constructor() public {
        count += 1;
    }
}