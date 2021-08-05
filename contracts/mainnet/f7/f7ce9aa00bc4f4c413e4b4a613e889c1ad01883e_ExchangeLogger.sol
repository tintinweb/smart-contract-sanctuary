/**
 *Submitted for verification at Etherscan.io on 2020-05-11
*/

pragma solidity ^0.6.0;

contract ExchangeLogger {
    event Swap(
        address src,
        address dest,
        uint256 amountSold,
        uint256 amountBought,
        address wrapper
    );

    function logSwap(
        address _src,
        address _dest,
        uint256 _amountSold,
        uint256 _amountBought,
        address _wrapper
    ) public {
        emit Swap(_src, _dest, _amountSold, _amountBought, _wrapper);
    }
}