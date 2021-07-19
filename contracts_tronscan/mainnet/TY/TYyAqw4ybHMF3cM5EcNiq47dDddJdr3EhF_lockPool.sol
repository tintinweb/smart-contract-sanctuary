//SourceUnit: lockPool.sol

pragma solidity ^0.5.10;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


contract lockPool {
    using SafeMath for uint256;

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    address public tokenAddr = 0xbadA2C95D64b2876CFCe1D9aC8803aB99295f250;
    address public recAddr = 0x82f8b5F062178C86B4c5A9Dea23D2633b80b1a47;
    uint256 public dayAmountOut;
    uint256 public totalAmount = 105000e8;//10.5
    uint256 public baseTime = 1625068800;//2021.7.1 0.0.0
    uint256 public MONTHS = 60;
    uint256 public ONE_MONTH = 60 * 60 * 24 * 30;
    uint256 public lastTime;
    uint256 public endTime;
    uint256 public receivedAmount;

    event Release(address operator, uint256 amount, uint256 time);

    constructor () public {
        lastTime = baseTime;
        endTime = lastTime.add(ONE_MONTH.mul(MONTHS));
        dayAmountOut = totalAmount.div(MONTHS);
    }

    function release() public {
        (uint amount,uint newTime) = getAmount();
        if (amount > 0) {
            safeTransfer(tokenAddr, recAddr, amount);
            receivedAmount = receivedAmount.add(amount);
            lastTime = newTime;
            emit Release(msg.sender, amount, now);
        }

    }
    //amount/lastBaseTime
    function getAmount() public view returns (uint256, uint256){
        if (now < baseTime) {
            return (0, baseTime);
        }
        uint256 tempTime = now;
        if (tempTime > endTime) {
            tempTime = endTime;
        }
        uint passDay = tempTime.sub(lastTime).div(ONE_MONTH);
        uint newTime = lastTime.add(passDay.mul(ONE_MONTH));

        return (passDay.mul(dayAmountOut), newTime);
    }


    function getInfo() public view returns (uint256, uint256, uint256, uint256){
        (uint amount,) = getAmount();
        return (receivedAmount, amount, lastTime, totalAmount);
    }

    function getPassDay(uint256 _time) public view returns (uint256){
        if (_time <= baseTime) {
            return 0;
        }
        return _time.sub(baseTime).div(ONE_MONTH);
    }


}