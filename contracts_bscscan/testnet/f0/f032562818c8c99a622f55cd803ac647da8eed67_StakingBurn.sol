/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

pragma solidity ^0.5.17;

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

contract Ownable {
    address private owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() public {
        owner = msg.sender;
    }

    function CurrentOwner() public view returns (address){
        return owner;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256);
}

contract StakingBurn is Ownable {

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    using SafeMath for uint256;
    //
    mapping(address => uint) public nonces;
    address public stakingToken = 0x822f521B028556C5C5689fE460ec8089c7661403;
    address public deadAddress = 0x29112919ae9301A630Efff02683d3A8B3e25Fc0b;
    address signAddress = 0x8885e3e0E93A9EE004fDccb9cfd485F5010ee0b5;

    uint256 public totalSupply;

    mapping(address => uint256) public deposits;


    event Staked(address indexed user, uint256 amount, uint256 time);
    event UpdateSignAddress(address indexed old, address indexed signAddress);

    function deposit(uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        require(amount > 0, ' Cannot stake 0');
        permit(msg.sender, amount, address(this), deadline, v, r, s);
        safeTransferFrom(stakingToken, msg.sender, deadAddress, amount);
        deposits[msg.sender] = deposits[msg.sender].add(amount);
        totalSupply = totalSupply.add(amount);
        emit Staked(msg.sender, amount, now);
    }


    function permit(address spender, uint256 amount, address _target, uint256 deadline, uint8 v, bytes32 r, bytes32 s) private {
        require(block.timestamp <= deadline, "EXPIRED");
        uint256 tempNonce = nonces[spender];
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(spender, amount, _target, deadline, tempNonce))));
        address recoveredAddress = ecrecover(message, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == signAddress, 'INVALID_SIGNATURE');
        nonces[spender]++;
    }


    function setSignAddress(address _newSign) public onlyOwner {
        emit UpdateSignAddress(signAddress, _newSign);
        signAddress = _newSign;
    }

    //------------------------------------
    address constant public recAddress = 0x34F2b52004Da2De138B9960796cc67E04fE94709;
    address constant public rewardToken = 0x311a89293fB2934dDa07B93a513348e4Af487D65;
    uint256[]   public amountArr = [1000e8, 1101.59e8, 1203.18e8, 1304.77e8, 1406.36e8, 1507.95e8, 1609.54e8, 1711.13e8, 1812.72e8, 1914.31e8, 2015.9e8, 2117.49e8, 2219.08e8, 2320.67e8, 2422.26e8, 2523.85e8, 2625.44e8, 2727.03e8, 2828.62e8, 2930.21e8, 3031.8e8, 3133.39e8, 3234.98e8, 3336.57e8, 3438.16e8, 3539.75e8, 3641.34e8, 3742.93e8, 3844.52e8, 3946.11e8, 4047.7e8, 4149.29e8, 4250.88e8, 4352.47e8, 4454.06e8, 4555.65e8];
    uint256   public startTime = 1636531200;
    uint256 public lastTime = startTime;
    uint256 constant public oneDayTimestamp = 60*10;
    uint256 constant public totalMonthCount = 36;
    uint256 constant public totalDayCount = totalMonthCount * 30;

    event AllocateTokens(uint256 amount, uint256 _time);

    constructor() public {
        startTime = 1639711800;
        lastTime = 1639711800;
    }

    //根据时间，计算当前在第几个月
    function getPeriod(uint256 _time) public view returns (uint256){
        uint256 per = _time.sub(startTime).div(oneDayTimestamp * 30);
        uint256 rem = _time.sub(startTime).mod(oneDayTimestamp * 30);
        if (rem == 0) {
            if (per == 0) {
                return 1;
            }
            if (per >= totalMonthCount) {
                return totalMonthCount;
            }
            return per;
        } else {
            if (per >= totalMonthCount) {
                return totalMonthCount;
            } else {
                return per + 1;}
        }
    }

    function getPeriodTimestamp(uint256 _period) public view returns (uint256){
        uint n = 1;
        if (_period <= 1) {
            n = 1;
        } else if (_period >= totalMonthCount) {
            return startTime.add(totalDayCount.mul(oneDayTimestamp));
        } else {
            n = _period;
        }
        return startTime.add(oneDayTimestamp.mul(30).mul(n));
    }
    
    function getPeriodReward(uint256 _period)public view returns(uint256){
        return amountArr[_period.sub(1)];
    }
    
    function getAmount(uint start, uint last) public view returns (uint256, uint256){
        require(start <= last, "s>l");
        if (now.sub(start) < oneDayTimestamp) {
            return (0, last);
        }
        //当前最后有多少天
        uint day = now.sub(last).div(oneDayTimestamp);
        uint amount = 0;
        //
        uint256 curPer = getPeriod(now);
        uint256 lastPer = getPeriod(lastTime);

        if (curPer != lastPer) {

            uint256 tempIndex = lastPer;
            for (; tempIndex <= curPer; tempIndex++) {
                //遍历过去的周期
                if (tempIndex == lastPer) {
                    //相同，需要计算剩余多少天， 当前周期的最后一天-当前最后更新的时间的天数
                    uint day0 = getPeriodTimestamp(tempIndex).sub(last).div(oneDayTimestamp);
                    amount = amount.add(getPeriodReward(tempIndex).mul(day0));
                } else if (tempIndex == curPer) {
                    //当前时间到上一个回合的结束时间
                    uint day1 = now.sub(getPeriodTimestamp(tempIndex - 1)).div(oneDayTimestamp);
                    amount = amount.add(getPeriodReward(tempIndex).mul(day1));
                } else {
                    //中途的固定产30天
                    amount = amount.add(getPeriodReward(tempIndex).mul(30));
                }

            }
        } else {
            //同一个周期，直接用day计算
            amount = getPeriodReward(curPer).mul(day);
        }
        uint newTime = day.mul(oneDayTimestamp).add(last);
        return (amount, newTime);
    }


    function allocateTokens() public {

        (uint256 amount, uint256 curTime) = getAmount(startTime, lastTime);
        if (amount > 0) {
            lastTime = curTime;
            uint256 curBalance = IERC20(rewardToken).balanceOf(address(this));
            if (amount > curBalance) {
                amount = curBalance;
            }
            safeTransfer(rewardToken, recAddress, amount);
            emit AllocateTokens(amount, now);
        }
    }

}