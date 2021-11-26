/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

pragma solidity 0.6.12;

interface IEventListener {
    event onNumberChanged(uint number);
    function changeNumber(uint number) external;
}

contract EventListener is IEventListener {
    function changeNumber(uint number) override external {
        emit onNumberChanged(number);
    }
}