pragma solidity ^0.5.8;

import './SafeMath.sol';
import './ITRC20.sol';

contract DaoStorage {
    using SafeMath for uint;
    address public addr;
    address public owner;
    uint public period;
    uint public startTime;
    uint public totleNum;
    uint public sendNum;
    ITRC20 internal _trc20;

    constructor(address owner_) public {
        owner = owner_;
        period = 3652 days;
        startTime = block.timestamp;
        sendNum = 0;
    }

    function setAddress(address addr_) public {
        require(addr == address(0) || msg.sender == owner);
        addr = addr_;
        _trc20 = ITRC20(addr_);
        totleNum = sendNum.add(_trc20.balanceOf(address(this)));
    }

    function thaw() public view returns (uint) {
        require(addr != address(0));
        uint time = block.timestamp.sub(startTime);
        if (time > period) {
            time = period;
        }
        return totleNum.mul(time).div(period).sub(sendNum);
    }

    function get() public returns (bool) {
        uint sendValue = thaw();
        sendNum = sendNum.add(sendValue);
        _trc20.transfer(owner, sendValue);
        return true;
    }
}