/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

pragma solidity 0.8.6;

contract Test {
    uint256 public num;
    constructor(
        uint256 _num
        ) {
            num = _num;
        }
    function setNum(uint256 _num) public
    {
        num = _num;
    }
    function getIncreasedNum()
    public view returns(uint256)
    {
        return num + 1;
    }
}