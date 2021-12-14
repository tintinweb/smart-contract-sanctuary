/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

pragma solidity 0.8.8;

contract Counter1 {

    // 无符号整形Public变量保存计数数量
    uint256 public count = 0;

    // 增加计数器数量的函数
    function plusone() public {
        count += 1;
    }

    // 非必要的getter函数，用于获取计数值
    function getCount() public view returns (uint256) {
        return count;
    }

}