//SourceUnit: SafeMath.sol

pragma solidity 0.5.10;

library SafeMath {
    function percent(uint64 value, uint64 _percent) internal pure  returns(uint64) {
        return div(mul(value, _percent), 100);
    }

    function add(uint64 a, uint64 b) internal pure returns (uint64) {
        uint64 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint64 a, uint64 b) internal pure returns (uint64) {
        require(a >= b, "SafeMath: subtraction overflow");
        uint64 c = a - b;
        return c;
    }

    function subNoNegative(uint64 a, uint64 b) internal pure returns (uint64) {
        if(a < b) {
            return 0;
        }
        uint64 c = a - b;
        return c;
    }

    function mul(uint64 a, uint64 b) internal pure returns (uint64) {
        if (a == 0) {
            return 0;
        }
        uint64 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function div(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b > 0, "SafeMath: division by zero");
        uint64 c = a / b;
        return c;
    }

    function mod(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}



//SourceUnit: TdmMining.sol

pragma solidity 0.5.10;

import "./SafeMath.sol";
import "./TronDiamond.sol";

contract TdmMining {
    using SafeMath for uint64;

    uint16[3] private FREEZE_DAYS = [10, 20, 35];
    uint16[3] private FREEZE_PERCENTS = [5, 12, 25];
    uint64 constant private TIME_UNIT = 1 days;

    struct User {
        uint64[5] startFreezeTime;
        uint64[5] amountTDM;
        uint16[5] freezeDays;
        uint64 rewards;
    }

    mapping(address => User) private _userMaps;

    TronDiamondContract _tronDiamond;

    constructor(TronDiamondContract tronDiamond) public {
        _tronDiamond = tronDiamond;
    }

    function getUserInfo(address user) public view returns(uint64[] memory) {
        uint64[] memory info = new uint64[](16);

        info[ 0] = _userMaps[user].startFreezeTime[0];
        info[ 1] = _userMaps[user].amountTDM[0];
        info[ 2] = _userMaps[user].freezeDays[0];
        
        info[ 3] = _userMaps[user].startFreezeTime[1];
        info[ 4] = _userMaps[user].amountTDM[1];
        info[ 5] = _userMaps[user].freezeDays[1];
    
        info[ 6] = _userMaps[user].startFreezeTime[2];
        info[ 7] = _userMaps[user].amountTDM[2];
        info[ 8] = _userMaps[user].freezeDays[2];
    
        info[ 9] = _userMaps[user].startFreezeTime[3];
        info[10] = _userMaps[user].amountTDM[3];
        info[11] = _userMaps[user].freezeDays[3];

        info[12] = _userMaps[user].startFreezeTime[4];
        info[13] = _userMaps[user].amountTDM[4];
        info[14] = _userMaps[user].freezeDays[4];

        info[15] = _userMaps[user].rewards;

        return info;
    }

    function canFreezeTDM(uint64 amountTDM, uint16 freezeDays) public view returns(bool) {
        if(!isValidFreezeDay(freezeDays)) {
            return false;
        }

        uint256[] memory info = _tronDiamond.getUserInfo(msg.sender);

        if(info.length == 12) {
            if(info[0] == 0) {
                return false; // not join
            }

            if(info[3] < 1000000) {
                return false; // hold TDM token less than 1 TDM
            }

            if(amountTDM > uint64(info[3])) {
                return false; // Freeze too may TDM tokens
            }

            if(getFreezeTDM(msg.sender).add(amountTDM) > uint64(info[3])) {
                return false; // No more TDM tokens to be freezed
            }
        } else {
            return false;
        }

        return findEmptyFreezeSlot(msg.sender) < 5;
    }

    function freezeTDM(uint64 amountTDM, uint16 freezeDays) public returns(bool) {
        uint256[] memory info = _tronDiamond.getUserInfo(msg.sender);
        require(info.length == 12, "Cannot get information from Tron Diamond Contract");

        require(info[0] > 0, "User not joined");
        require(info[3] >= 1000000, "User hold too few TDM tokens");
        require(amountTDM <= uint64(info[3]), "Freeze too may TDM tokens");
        require(getFreezeTDM(msg.sender).add(amountTDM) <= uint64(info[3]), "No more TDM tokens to be freezed");

        require(isValidFreezeDay(freezeDays), "Invalid number of freezing days");

        require(amountTDM > 0, "Invalid amount");

        uint freezeSlotId = findEmptyFreezeSlot(msg.sender);
        require(freezeSlotId < 5, "No available freeze slot");

        _userMaps[msg.sender].startFreezeTime[freezeSlotId] = uint64(block.timestamp);
        _userMaps[msg.sender].amountTDM[freezeSlotId] = amountTDM;
        _userMaps[msg.sender].freezeDays[freezeSlotId] = freezeDays;
        _userMaps[msg.sender].rewards = _userMaps[msg.sender].rewards.add(amountTDM.percent(getFreezePercent(freezeDays)));

        return true;
    }

    function canUnfreezeTDM(uint freezeSlotId) public view returns(bool) {
        if(freezeSlotId >= 5) {
            return false;
        }

        if(_userMaps[msg.sender].startFreezeTime[freezeSlotId] == 0) {
            return false;
        }

        if(_userMaps[msg.sender].amountTDM[freezeSlotId] == 0) {
            return false;
        }

        if(_userMaps[msg.sender].freezeDays[freezeSlotId] == 0) {
            return false;
        }

        uint64 period = TIME_UNIT.mul(uint64(_userMaps[msg.sender].freezeDays[freezeSlotId]));

        if(uint64(block.timestamp) < _userMaps[msg.sender].startFreezeTime[freezeSlotId].add(period)) {
            return false;
        }

        return true;
    }

    function unfreezeTDM(uint freezeSlotId) public returns(bool) {
        require(freezeSlotId < 5, "Invalid freeze slot");
        require(_userMaps[msg.sender].startFreezeTime[freezeSlotId] > 0, "Invalid start freeze time");
        require(_userMaps[msg.sender].amountTDM[freezeSlotId] > 0, "Invalid amount TDM");
        require(_userMaps[msg.sender].freezeDays[freezeSlotId] > 0, "Invalid freeze days");

        uint64 period = TIME_UNIT.mul(uint64(_userMaps[msg.sender].freezeDays[freezeSlotId]));
        require(uint64(block.timestamp) >= _userMaps[msg.sender].startFreezeTime[freezeSlotId].add(period), "Need more freeze time");

        _userMaps[msg.sender].startFreezeTime[freezeSlotId] = 0;
        _userMaps[msg.sender].amountTDM[freezeSlotId] = 0;
        _userMaps[msg.sender].freezeDays[freezeSlotId] = 0;

        return true;
    }

    function getUnfreezeTime(address user) public view returns(uint64[] memory) {
        uint64[] memory info = new uint64[](5);

        for(uint freezeSlotId = 0; freezeSlotId < 5; freezeSlotId++) {
            uint64 period = TIME_UNIT.mul(uint64(_userMaps[msg.sender].freezeDays[freezeSlotId]));
            info[freezeSlotId] = _userMaps[user].startFreezeTime[freezeSlotId].add(period).subNoNegative(uint64(block.timestamp));
        }

        return info;
    }

    function getFreezeTDM(address user) public view returns(uint64) {
        uint64 amount = 0;

        for(uint freezeSlotId = 0; freezeSlotId < 5; freezeSlotId++) {
            if(_userMaps[user].startFreezeTime[freezeSlotId] > 0) {
                amount = amount.add(_userMaps[user].amountTDM[freezeSlotId]);
            }
        }

        return amount;
    }

    function findEmptyFreezeSlot(address user) private view returns(uint) {
        for(uint freezeSlotId = 0; freezeSlotId < 5; freezeSlotId++) {
            if(_userMaps[user].startFreezeTime[freezeSlotId] == 0) {
                return freezeSlotId;
            }
        }
        return 5;
    }

    function isValidFreezeDay(uint16 freezeDays) private view returns(bool) {
        for(uint i = 0; i < FREEZE_DAYS.length; i++) {
            if(freezeDays == FREEZE_DAYS[i]) {
                return true;
            }
        }
        return false;
    }

    function getFreezePercent(uint16 freezeDays) private view returns(uint64) {
        for(uint i = 0; i < FREEZE_DAYS.length; i++) {
            if(FREEZE_DAYS[i] == freezeDays) {
                return FREEZE_PERCENTS[i];
            }
        }
        return 0;
    }

}



//SourceUnit: TronDiamond.sol

pragma solidity 0.5.10;

contract TronDiamondContract {

    function getReferrerUser(address user) public view returns(address);

    function getAllReferrerUsers(address user) public view returns(address[] memory);

    function getAllFollowerUsers(address user) public view returns(address[] memory);

    function getUserInfo(address user) public view returns(uint256[] memory);

    function getUserCount() public view returns(uint256);

    function getTokenAddress() public view returns(address);

    function getContractBalanceSun() public view returns(uint256);

    function getTotalInvestSun() public view returns(uint256);

    function getTotalWithdrawSun() public view returns(uint256);

    function getTokenSupply() public view returns(uint256);

    function getTopSponsorRewardSun() public view returns(uint256);

    function getDividend() public view returns(uint256);

    function getRewardsSun() public view returns(uint256);

    function getTimeToNextDraw() public view returns(uint256);

    function getTopDepositUsers() public view returns(address[5] memory);

    function getTopDepositSuns() public view returns(uint256[] memory);

    function getTopReferrerUsers() public view returns(address[5] memory);

    function getTopReferrerCounts() public view returns(uint256[] memory);

    function contractBalance() public view returns(uint256);

    function getTotalToken() public view returns(uint256);

    function getSellPrice() public view returns (uint256);

    function getBuyPrice() public view returns (uint256);

    function getTokensReceived(uint256 valueBuySun) public view returns (uint256);

    function getSunReceived(uint256 amountSellToken) public view returns (uint256);
    
    function join(address referrerUser) public payable returns(bool);

    function buy() public payable returns(bool);

    function sell(uint256 amountSellToken) public returns(bool);

    function withdraw() public returns(bool);

    function isJoinedUser() public view returns(bool);
}