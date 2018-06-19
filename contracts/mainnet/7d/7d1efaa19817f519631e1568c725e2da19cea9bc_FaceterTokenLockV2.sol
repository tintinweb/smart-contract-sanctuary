pragma solidity 0.4.19;

contract ERC20Interface {
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
}

contract FaceterTokenLockV2 {
    address constant RECEIVER = 0x102aEe443704BBd96f31BcFCA9DA8E86f0128803;
    uint constant AMOUNT = 18750000 * 10**18;
    ERC20Interface constant FaceterToken = ERC20Interface(0x4695c7AC68eb86c1079c7d7D53Af2F42DB8a6799);
    uint8 public unlockStep;

    function unlock() public returns(bool) {
        uint unlockAmount = 0;
        // 1 July 2018
        if (unlockStep == 0 && now >= 1530403200) {
            unlockAmount = AMOUNT;
        // 1 October 2018
        } else if (unlockStep == 1 && now >= 1538352000) {
            unlockAmount = AMOUNT;
        // 1 January 2019
        } else if (unlockStep == 2 && now >= 1546300800) {
            unlockAmount = AMOUNT;
        // 1 April 2019
        } else if (unlockStep == 3 && now >= 1554076800) {
            unlockAmount = AMOUNT;
        // 1 July 2019
        } else if (unlockStep == 4 && now >= 1561939200) {
            unlockAmount = AMOUNT;
        // 1 October 2019
        } else if (unlockStep == 5 && now >= 1569888000) {
            unlockAmount = AMOUNT;
        // 1 January 2020
        } else if (unlockStep == 6 && now >= 1577836800) {
            unlockAmount = AMOUNT;
        // 1 April 2020
        } else if (unlockStep == 7 && now >= 1585699200) {
            unlockAmount = FaceterToken.balanceOf(this);
        }
        if (unlockAmount == 0) {
            return false;
        }
        unlockStep++;
        require(FaceterToken.transfer(RECEIVER, unlockAmount));
        return true;
    }

    function () public {
        unlock();
    }

    function recoverTokens(ERC20Interface _token) public returns(bool) {
        // Don&#39;t allow recovering Faceter Token till the end of lock.
        if (_token == FaceterToken && now < 1585699200 && unlockStep != 8) {
            return false;
        }
        return _token.transfer(RECEIVER, _token.balanceOf(this));
    }
}