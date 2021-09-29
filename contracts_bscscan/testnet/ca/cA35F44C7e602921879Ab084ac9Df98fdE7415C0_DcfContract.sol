pragma solidity 0.5.10;

import "./SafeMath.sol";

contract DcfContract {
    using SafeMath for uint256;

    struct User {
        address referrerUser;
        address[] followerUsers;
        uint256 depositTime;
        uint256 totalDepositWei;
        uint256 totalReferrerWei;
        uint256 totalWithdrawWei;
        uint256 withdrawableCommissionWei;
        uint256 withdrawableRewardWei;
        uint256 withdrawableWelfareWei;
        uint256 periodReferrerTime;
        uint256 roiPercentPerMonth;
        uint256 roiTime;
        uint256 paidSpecialBonusPercent;
        bool closed;
    }

    address payable private _ownerUser;

    mapping(address => User) private _userMaps;
    uint256 private _userCount;

    uint256 private _totalDepositWei;
    uint256 private _totalWithdrawWei;

    uint256 constant private _withdrawableInTimeLockPercent = 85;
    uint256 constant private _withdrawablePercent = 95; 

    uint256[3] private _userCommissionPercents = [ 3, 2, 1 ];
    uint256 constant private _timelock = 1 days;

    uint256 constant private _minimumDepositWei = 5e6;

    uint256 constant private _drawTopSponsorRewardPeriod = 1 days;
    uint256 private _lastDrawTopSponsorRewardTime;
    
    uint256 private _topSponsorRewardWei;
    address[3] private _topDepositUsers = [ address(0), address(0), address(0)];
    address[3] private _topReferrerUsers = [ address(0), address(0), address(0)];
    uint256[3] private _topSponsorRewardPercents = [ 5, 3, 2 ];

    uint256 private _totalSpecialBonusPercent;

    constructor() public {
        _lastDrawTopSponsorRewardTime = block.timestamp;
        _ownerUser = msg.sender;
        _userMaps[_ownerUser].referrerUser = address(0);
        _userMaps[_ownerUser].depositTime = block.timestamp;
        _userMaps[_ownerUser].closed = true;
        _userCount = _userCount.add(1);
    }

    function ownerWithdraw(uint256 valueWei) public returns(bool) {
        if (msg.sender != _ownerUser) {
            revert("This is for the owner only");
        }

        if (getContractBalanceWei() < valueWei) {
            revert("Overdrawn amount");
        }

        msg.sender.transfer(valueWei);
        return true;
    }

    function getContractBalanceWei() private view returns(uint256) {
        return (address(this)).balance;
    }

    function getOwnerUser() public view returns(address) {
        return _ownerUser;
    }

    function getReferrerUser(address user) public view returns(address) {
        return _userMaps[user].referrerUser;
    }

    function getAllFollowerUsers(address user) public view returns(address[] memory) {
        return _userMaps[user].followerUsers;
    }

    function getUserInfo(address user) public view returns(uint256[] memory) {
        uint256[] memory info = new uint256[](13);

        if (isJoinedUser(user)) {
            info[0] = _userMaps[user].depositTime;
            info[1] = _userMaps[user].totalDepositWei;
            info[2] = _userMaps[user].totalReferrerWei;
            info[3] = _userMaps[user].totalWithdrawWei;
            info[4] = getUserRoiWei(user);
            info[5] = _userMaps[user].withdrawableCommissionWei;
            info[6] = _userMaps[user].withdrawableRewardWei;
            info[7] = _userMaps[user].withdrawableWelfareWei;
            info[8] = getUserSpecialBonusWei(user);
            info[9] = _userMaps[user].roiPercentPerMonth;
            info[10] = (_userMaps[user].depositTime + _timelock).subNoNegative(block.timestamp); // Time to finish time lock
            if (_userMaps[user].depositTime > 0) {
                info[11] = 1;
            } else {
                info[11] = 0;
            }
            if (_userMaps[user].closed == false) {
                info[12] = 1;
            } else {
                info[12] = 0;
            }
        } else {
            info[0] = 0;
            info[1] = 0;
            info[2] = 0;
            info[3] = 0;
            info[4] = 0;
            info[5] = 0;
            info[6] = 0;
            info[7] = 0;
            info[8] = 0;
            info[9] = 0;
            info[10] = 0;
            info[11] = 0;
            info[12] = 0;
        }

        return info;
    }

    function getSystemInfo() public view returns(uint256[] memory) {
        uint256[] memory info = new uint256[](12);
        info[0] = _userCount;
        info[1] = _totalDepositWei;
        info[2] = _totalWithdrawWei;
        info[3] = _lastDrawTopSponsorRewardTime.add(_drawTopSponsorRewardPeriod).subNoNegative(block.timestamp); // Time to next draw
        info[4] = _topSponsorRewardWei;
        info[5] = (address(this)).balance; // contract balance
        
        for (uint256 i = 0; i < 3; i++) {
            if (_topDepositUsers[i] != address(0)) {
                info[6 + i] = _userMaps[_topDepositUsers[i]].totalDepositWei;
            } else {
                info[6 + i] = 0;
            }

            if (_topReferrerUsers[i] != address(0)) {
                info[9 + i] = _userMaps[_topReferrerUsers[i]].totalReferrerWei;
            } else {
                info[9 + i] = 0;
            }
        }

        return info;
    }

    function getTopSponsorUsers() public view returns(address[] memory) {
        address[] memory users = new address[](6);

        for (uint256 i = 0; i < 3; i++) {
            users[0 + i] = _topDepositUsers[i];
            users[3 + i] = _topReferrerUsers[i];
        }

        return users;
    }

    function isJoinedUser(address user) public view returns(bool) {
        if (user == address(0)) {
            return false;
        }
        if (_userMaps[user].depositTime > 0) {
            return true;
        }
        return false;
    }

    function deposit(address referrerUser) public payable returns(bool) {
        if (isJoinedUser(referrerUser) == false) {
            revert("Referrer is unknown");
        }

        address user = msg.sender;

        if (user == _ownerUser) {
            revert("Owner user cannot deposit");
        }
        
        if (user == referrerUser) {
            revert("User and referrer can not be the same person");
        }

        if (isJoinedUser(user) == true) {
            revert("Each user can deposit only once");
        }

        uint256 depositWei = msg.value;

        if (depositWei < _minimumDepositWei) {
            revert("You have to send at least the minimum requirement amount to join");
        }

        _totalDepositWei = _totalDepositWei.add(depositWei);
        _userMaps[referrerUser].followerUsers.push(user);
        _userMaps[user].depositTime = block.timestamp;
        _userMaps[user].referrerUser = referrerUser;
        _userMaps[user].totalDepositWei = depositWei;
        _userMaps[user].periodReferrerTime = 0;
        _userMaps[user].totalReferrerWei = 0;
        _userMaps[user].totalWithdrawWei = 0;
        _userMaps[user].withdrawableCommissionWei = 0;
        _userMaps[user].withdrawableRewardWei = 0;
        _userMaps[user].withdrawableWelfareWei = 0;
        _userMaps[user].closed = false;

        _userCount = _userCount.add(1);

        setUserRoiPercentPerMonth(user, _userMaps[user].totalDepositWei);
        clearUserRoi(user);
        clearUserSpecialBonusPercent(user);
        updateUserCommission(user, depositWei);
        drawRewards();

        _topSponsorRewardWei = _topSponsorRewardWei.add(depositWei);

        if (referrerUser != _ownerUser) {
            if (_userMaps[referrerUser].periodReferrerTime < _lastDrawTopSponsorRewardTime) {
                _userMaps[referrerUser].periodReferrerTime = _lastDrawTopSponsorRewardTime;
                _userMaps[referrerUser].totalReferrerWei = depositWei;
            } else {
                _userMaps[referrerUser].totalReferrerWei = _userMaps[referrerUser].totalReferrerWei.add(depositWei);
            }

            updateTopReferrerUsers(referrerUser);
        }

        updateTopDepositUsers(user);

        return true;
    }

    function withdraw() public returns(bool) {
        address payable user = msg.sender;

        if (isJoinedUser(user) == false) {
            revert("User has not joined");
        }

        if (_userMaps[user].closed == true) {
            revert("User has been closed");
        }

        drawRewards();

        uint256 withdrawWei = 0;
        
        if (block.timestamp.subNoNegative(_userMaps[user].depositTime) < _timelock) {
            withdrawWei = _userMaps[user].totalDepositWei.percent(_withdrawableInTimeLockPercent);
        } else {
            withdrawWei = _userMaps[user].totalDepositWei.percent(_withdrawablePercent);
        }

        withdrawWei = withdrawWei.add(getUserRoiWei(user));
        withdrawWei = withdrawWei.add(_userMaps[user].withdrawableCommissionWei);
        withdrawWei = withdrawWei.add(_userMaps[user].withdrawableRewardWei);
        withdrawWei = withdrawWei.add(_userMaps[user].withdrawableWelfareWei);
        withdrawWei = withdrawWei.add(getUserSpecialBonusWei(user));

        user.transfer(withdrawWei);
        _totalWithdrawWei = _totalWithdrawWei.add(withdrawWei);
        _userMaps[user].totalWithdrawWei = _userMaps[user].totalWithdrawWei.add(withdrawWei);
        _userMaps[user].withdrawableCommissionWei = 0;
        _userMaps[user].withdrawableRewardWei = 0;
        _userMaps[user].withdrawableWelfareWei = 0;
        clearUserSpecialBonusPercent(user);
        clearUserRoi(user);
        
        removeUserFromTopDepositUsers(user);
        removeUserFromTopReferrerUsers(user);

        _userMaps[user].closed = true;

        return true;
    }

    function harvest() public returns(bool) {
        address payable user = msg.sender;

        if (isJoinedUser(msg.sender) == false) {
            revert("User has not joined");
        }

        if (_userMaps[user].closed == true) {
            revert("User has been closed");
        }

        drawRewards();

        uint256 withdrawWei = 0;
        
        withdrawWei = withdrawWei.add(getUserRoiWei(user));
        withdrawWei = withdrawWei.add(_userMaps[user].withdrawableCommissionWei);
        withdrawWei = withdrawWei.add(_userMaps[user].withdrawableRewardWei);
        withdrawWei = withdrawWei.add(_userMaps[user].withdrawableWelfareWei);
        withdrawWei = withdrawWei.add(getUserSpecialBonusWei(user));

        if (withdrawWei > 0) {
            user.transfer(withdrawWei);
            _totalWithdrawWei = _totalWithdrawWei.add(withdrawWei);
            _userMaps[user].totalWithdrawWei = _userMaps[user].totalWithdrawWei.add(withdrawWei);
            _userMaps[user].withdrawableCommissionWei = 0;
            _userMaps[user].withdrawableRewardWei = 0;
            _userMaps[user].withdrawableWelfareWei = 0;
            clearUserSpecialBonusPercent(user);
            clearUserRoi(user);
        }

        return true;
    }

    function addSpecialBonusPercent(uint256 valuePercent) public {
        if (msg.sender != _ownerUser) {
            revert("This is for the owner only");
        }

        _totalSpecialBonusPercent = _totalSpecialBonusPercent.add(valuePercent);
    }

    function addUserWelfare(address user, uint256 valueWei) public {
        if (msg.sender != _ownerUser) {
            revert("This is for the owner only");
        }

        if (!isJoinedUser(user)) {
            revert("This user is not joined");
        }

        if (_userMaps[user].closed == true) {
            revert("Not an active user");
        }

        _userMaps[user].withdrawableWelfareWei = valueWei;
    }

    function setUserRoiPercentPerMonth(address user, uint256 balanceWei) private {
        if (balanceWei < 10e8) {
            _userMaps[user].roiPercentPerMonth = 3;
        } else if (balanceWei < 50e8) {
            _userMaps[user].roiPercentPerMonth = 4;
        } else {
            _userMaps[user].roiPercentPerMonth = 5;
        }
    }

    function updateUserCommission(address user, uint256 valueWei) private {
        address referrerUser = _userMaps[user].referrerUser;

        for(uint256 i = 0; (i < _userCommissionPercents.length) && (referrerUser != _ownerUser); i++) {
            uint256 commissionWei = valueWei.percent(_userCommissionPercents[i]);
            
            if (_userMaps[user].closed == false) {
                _userMaps[referrerUser].withdrawableCommissionWei = _userMaps[referrerUser].withdrawableCommissionWei.add(commissionWei);
            }

            referrerUser = _userMaps[referrerUser].referrerUser;
        }
    }

    function drawRewards() private {
        if (block.timestamp.subNoNegative(_lastDrawTopSponsorRewardTime) >= _drawTopSponsorRewardPeriod) {
            _lastDrawTopSponsorRewardTime = block.timestamp;

            uint256 totalPayableTopDepositors = _topSponsorRewardWei;
            uint256 totalPayableTopReferrers = _topSponsorRewardWei;

            for (uint i = 0; i < _topDepositUsers.length; i++) {
                address user = _topDepositUsers[i];

                if (user != address(0)) {
                    _userMaps[user].withdrawableRewardWei = _userMaps[user].withdrawableRewardWei.add(totalPayableTopDepositors.percent(_topSponsorRewardPercents[i]));
                    _userMaps[user].totalReferrerWei = 0;
                }

                _topDepositUsers[i] = address(0);
            }
            
            for (uint i = 0; i < _topReferrerUsers.length; i++) {
                address user = _topReferrerUsers[i];

                if (user != address(0)) {
                    _userMaps[user].withdrawableRewardWei = _userMaps[user].withdrawableRewardWei.add(totalPayableTopReferrers.percent(_topSponsorRewardPercents[i]));
                    _userMaps[user].totalReferrerWei = 0;
                }

                _topReferrerUsers[i] = address(0);
            }

            _topSponsorRewardWei = 0;
        }
    }

    function updateTopDepositUsers(address user) private {
        removeUserFromTopDepositUsers(user);

        for (uint i = 0; i < _topDepositUsers.length; i++) {
            if (_topDepositUsers[i] == address(0)) {
                _topDepositUsers[i] = user;
                break;
            } else {
                if (_userMaps[user].totalDepositWei > _userMaps[_topDepositUsers[i]].totalDepositWei) {
                    shiftDownTopDepositUsers(i);
                    _topDepositUsers[i] = user;
                    break;
                }
            }
        }
    }

    function removeUserFromTopDepositUsers(address user) private {
        for (uint i = 0; i < _topDepositUsers.length; i++) {
            if (user == _topDepositUsers[i]) {
                shiftUpTopDepositUsers(i);
                break;
            }
        }
    }

    function shiftUpTopDepositUsers(uint256 index) private {
        for (uint i = index; i < _topDepositUsers.length - 1; i++) {
            _topDepositUsers[i] = _topDepositUsers[i + 1];
        }

        _topDepositUsers[_topDepositUsers.length - 1] = address(0);
    }

    function shiftDownTopDepositUsers(uint256 index) private {
        for (uint i = _topDepositUsers.length - 1; i > index; i--) {
            _topDepositUsers[i] = _topDepositUsers[i - 1];
        }

        _topDepositUsers[index] = address(0);
    }

    function updateTopReferrerUsers(address referrerUser) private {
        removeUserFromTopReferrerUsers(referrerUser);

        for (uint i = 0; i < _topReferrerUsers.length; i++) {
            if (_topReferrerUsers[i] == address(0)) {
                _topReferrerUsers[i] = referrerUser;
                break;
            } else {
                if (_userMaps[referrerUser].totalReferrerWei > _userMaps[_topReferrerUsers[i]].totalReferrerWei) {
                    shiftDownTopReferrerUsers(i);
                    _topReferrerUsers[i] = referrerUser;
                    break;
                }
            }
        }
    }

    function removeUserFromTopReferrerUsers(address user) private {
        for (uint i = 0; i < _topReferrerUsers.length; i++) {
            if (user == _topReferrerUsers[i]) {
                shiftUpTopReferrerUsers(i);
                break;
            }
        }
    }

    function shiftUpTopReferrerUsers(uint256 index) private {
        for (uint i = index; i < _topReferrerUsers.length - 1; i++) {
            _topReferrerUsers[i] = _topReferrerUsers[i + 1];
        }

        _topReferrerUsers[_topReferrerUsers.length - 1] = address(0);
        
    }

    function shiftDownTopReferrerUsers(uint256 index) private {
        for (uint i = _topReferrerUsers.length - 1; i > index; i--) {
            _topReferrerUsers[i] = _topReferrerUsers[i - 1];
        }

        _topReferrerUsers[index] = address(0);
    }

    function getUserRoiWei(address user) private view returns(uint256) {
        if (isJoinedUser(user) == false || _userMaps[user].closed == true) {
            return 0;
        }

        return _userMaps[user].totalDepositWei.mul(_userMaps[user].roiPercentPerMonth).mul(block.timestamp.subNoNegative(_userMaps[user].roiTime)).div(259200000);
    }

    function clearUserRoi(address user) private {
        _userMaps[user].roiTime = block.timestamp;
    }

    function getUserSpecialBonusWei(address user) public view returns(uint256) {
        if (isJoinedUser(user) == false || _userMaps[user].closed == true) {
            return 0;
        }

        return _userMaps[user].totalDepositWei.percent(_totalSpecialBonusPercent.subNoNegative(_userMaps[user].paidSpecialBonusPercent));
    }

    function clearUserSpecialBonusPercent(address user) private {
        _userMaps[user].paidSpecialBonusPercent = _totalSpecialBonusPercent;
    }

}