// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

/// @title Contract Root
contract Root is Ownable {
    using SafeMath for uint;

    enum Group { PrivateRound1, PrivateRound2, UnlockedTokenFromPR2, PublicSale, Marketing, Liquidity, Team,
        Advisor, Development}

    IERC20 public token;

    struct GroupInfo {
        uint256[] balances;
        uint256[] balancesBase;
        uint256[] percents;
        address[] addresses;
    }

    mapping(Group => GroupInfo) private groupToInfo;
    uint256 private totalGroupsBalance;

    /// @notice Time when the contract was deployed
    uint256 public deployTime;

    constructor(address _token) {
        token = IERC20(_token);
        deployTime = block.timestamp;
    }

    /// @notice Load group data to contract.
    /// @return bool True if data successfully loaded
    function loadGroupInfo(GroupInfo memory _group, Group _groupNumber) external onlyOwner returns(bool) {
        require(groupToInfo[_groupNumber].addresses.length == 0, "[E-39] - Group already loaded.");
        require(_group.addresses.length > 0, "[E-40] - Empty address array in group.");

        _updateTotalGroupBalance(_group);
        _checkTotalPercentSumInGroup(_group);

        _setupBaseBalance(_group);
        _transferTokensOnLoad(_group);

        groupToInfo[_groupNumber] = _group;

        return true;
    }

    /// @notice Write total group balance to storage. Need to calculate total groups balance
    /// @param _group Group to upload
    function _updateTotalGroupBalance(GroupInfo memory _group) private {
        uint256 _groupBalances = 0;
        for (uint256 k = 0; k < _group.balances.length; k++) {
            _groupBalances = _groupBalances.add(_group.balances[k]);
        }

        totalGroupsBalance += _groupBalances;
    }

    /// @notice Check that percent sum inside group equal to 1
    /// @param _group Group to upload
    function _checkTotalPercentSumInGroup(GroupInfo memory _group) private pure {
        uint256 _percentSum = 0;
        for (uint256 k = 0; k < _group.percents.length; k++) {
            _percentSum = _percentSum.add(_group.percents[k]);
        }
        require(_percentSum == getDecimal(), "[E-104] - Invalid percent sum in group.");
    }

    /// @notice Copy user balances to baseBalances
    /// @param _group Group to upload
    function _setupBaseBalance(GroupInfo memory _group) private pure {
        _group.balancesBase = new uint256[](_group.balances.length);

        for (uint256 k = 0; k < _group.balances.length; k++) {
            _group.balancesBase[k] = _group.balances[k];
        }
    }

    /// @notice Transfer tokens in groups where TGE is 100% and execute base input validation
    /// @param _group Group to upload
    function _transferTokensOnLoad(GroupInfo memory _group) private {
        require(_group.addresses.length == _group.balancesBase.length, "[E-50] - Address and balance length should be equal.");

        if (_group.percents[0] == getDecimal()) {
            for (uint256 k = 0; k < _group.addresses.length; k++) {
                _group.balances[k] = 0;
                token.transfer(_group.addresses[k], _group.balancesBase[k]);
            }
        }
    }

    /// @notice Transfer amount from contract to `msg.sender`
    /// @param _group Group number
    /// @param _amount Withdrawal amount
    /// @return True if withdrawal success
    function withdraw(Group _group, uint256 _amount) external returns(bool) {
        GroupInfo memory _groupInfo = groupToInfo[_group];

        uint256 _senderIndex = _getSenderIndexInGroup(_groupInfo);

        uint256 _availableToWithdraw = _getAvailableToWithdraw(_groupInfo);

        uint256 _amountToWithdraw = _amount > _availableToWithdraw ? _availableToWithdraw : _amount;
        require(_amountToWithdraw != 0, "[E-51] - Amount to withdraw is zero.");

        groupToInfo[_group].balances[_senderIndex] = (_groupInfo.balances[_senderIndex]).sub(_amountToWithdraw);

        return token.transfer(msg.sender, _amountToWithdraw);
    }

    /// @notice Function for external call. See _getWithdrawPercent
    /// @param _group Group number
    function getWithdrawPercent(Group _group) external view returns(uint256) {
        GroupInfo memory _groupInfo = groupToInfo[_group];
        return _getWithdrawPercent(_groupInfo);
    }

    /// @notice Get total percent for group depending on the number of days elapsed after contract deploy.
    /// @notice For example, percent for first 30 days - 15%, all next 30 days - 5%, return 25% after 90 days.
    /// @param _groupInfo Structure with group info
    function _getWithdrawPercent(GroupInfo memory _groupInfo) private view returns(uint256) {
        uint256 _index = 0;
        uint256 _timePerIndex = 30 days;
        uint256 _deployTime = deployTime;

        while(_deployTime + _timePerIndex * (_index + 1) <= block.timestamp) {
            _index++;
        }

        // Return 1 if last month is passed
        if (_groupInfo.percents.length - 1 <= _index) return getDecimal();

        uint256 _monthWithdrawPercent = 0;
        for (uint256 i = 0; i <= _index; i++) {
            _monthWithdrawPercent = _monthWithdrawPercent.add(_groupInfo.percents[i]);
        }

        uint256 _daysFromDeploy = (block.timestamp).sub(_deployTime).div(24 * 3600).mod(30);
        uint256 _daysWithdrawPercent = (_groupInfo.percents[_index + 1]).mul(_daysFromDeploy).div(30);

        return _monthWithdrawPercent.add(_daysWithdrawPercent);
    }

    /// @notice Function for external call. See _getWithdrawPercent.
    /// @param _group Group number
    function getAvailableToWithdraw(Group _group) external view returns(uint256) {
        GroupInfo memory _groupInfo = groupToInfo[_group];
        return _getAvailableToWithdraw(_groupInfo);
    }

    /// @param _groupInfo Structure with group info
    /// @return Amount that user can withdraw.
    function _getAvailableToWithdraw(GroupInfo memory _groupInfo) private view returns(uint256) {
        uint256 _withdrawPercent = _getWithdrawPercent(_groupInfo);
        uint256 _senderIndex = _getSenderIndexInGroup(_groupInfo);

        uint256 _availableToWithdraw = _withdrawPercent.mul(_groupInfo.balancesBase[_senderIndex]).div(getDecimal());
        uint256 _alreadyWithdraw = (_groupInfo.balancesBase[_senderIndex]).sub(_groupInfo.balances[_senderIndex]);

        return _availableToWithdraw.sub(_alreadyWithdraw);
    }

    /// @param _groupInfo Structure with group info
    /// @return Sender index that corresponds to the user balance and user balanceBase
    function _getSenderIndexInGroup(GroupInfo memory _groupInfo) private view returns(uint256) {
        bool _isAddressExistInGroup = false;
        uint256 _senderIndex = 0;

        for (uint256 i = 0; i < _groupInfo.addresses.length; i++) {
            if (_groupInfo.addresses[i] == msg.sender) {
                _isAddressExistInGroup = true;
                _senderIndex = i;
                break;
            }
        }
        require(_isAddressExistInGroup, '[E-55] - Address not found in selected group.');

        return _senderIndex;
    }

    /// @notice Decimal for contract
    function getDecimal() private pure returns (uint256) {
        return 10 ** 27;
    }
}