// SPDX-License-Identifier: AGPL-3.0-only

/*
    TokenLaunchLocker.sol - SKALE Manager
    Copyright (C) 2019-Present SKALE Labs
    @author Dmytro Stebaiev

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.6.10;

import "./Permissions.sol";
import "./ILocker.sol";
import "./ConstantsHolder.sol";
import "./MathUtils.sol";

import "./DelegationController.sol";
import "./TimeHelpers.sol";
import "./PartialDifferences.sol";


contract TokenLaunchLocker is Permissions, ILocker {
    using MathUtils for uint;
    using PartialDifferences for PartialDifferences.Value;

    /**
     * @dev Emitted when an `amount` is unlocked.
     */
    event Unlocked(
        address holder,
        uint amount
    );

    /**
     * @dev Emitted when an `amount` is locked.
     */
    event Locked(
        address holder,
        uint amount
    );

    struct DelegatedAmountAndMonth {
        uint delegated;
        uint month;
    }

    //        holder => tokens
    mapping (address => uint) private _locked;

    //        holder => tokens
    mapping (address => PartialDifferences.Value) private _delegatedAmount;

    mapping (address => DelegatedAmountAndMonth) private _totalDelegatedAmount;

    // delegationId => tokens
    mapping (uint => uint) private _delegationAmount;

    function lock(address holder, uint amount) external allow("TokenLaunchManager") {
        _locked[holder] = _locked[holder].add(amount);

        emit Locked(holder, amount);
    }

    function handleDelegationAdd(
        address holder, uint delegationId, uint amount, uint month)
        external allow("DelegationController")
    {
        if (_locked[holder] > 0) {
            TimeHelpers timeHelpers = TimeHelpers(contractManager.getContract("TimeHelpers"));

            uint currentMonth = timeHelpers.getCurrentMonth();
            uint fromLocked = amount;
            uint locked = _locked[holder].boundedSub(_getAndUpdateDelegatedAmount(holder, currentMonth));
            if (fromLocked > locked) {
                fromLocked = locked;
            }
            if (fromLocked > 0) {
                require(_delegationAmount[delegationId] == 0, "Delegation was already added");
                _addToDelegatedAmount(holder, fromLocked, month);
                _addToTotalDelegatedAmount(holder, fromLocked, month);
                _delegationAmount[delegationId] = fromLocked;
            }
        }
    }

    function handleDelegationRemoving(
        address holder,
        uint delegationId,
        uint month)
        external allow("DelegationController")
    {
        if (_delegationAmount[delegationId] > 0) {
            if (_locked[holder] > 0) {
                _removeFromDelegatedAmount(holder, _delegationAmount[delegationId], month);
            }
            delete _delegationAmount[delegationId];
        }
    }

    function getAndUpdateLockedAmount(address wallet) external override returns (uint) {
        if (_locked[wallet] > 0) {
            DelegationController delegationController = DelegationController(
                contractManager.getContract("DelegationController"));
            TimeHelpers timeHelpers = TimeHelpers(contractManager.getContract("TimeHelpers"));
            ConstantsHolder constantsHolder = ConstantsHolder(contractManager.getContract("ConstantsHolder"));

            uint currentMonth = timeHelpers.getCurrentMonth();
            if (_totalDelegatedSatisfiesProofOfUserCondition(wallet) &&
                timeHelpers.calculateProofOfUseLockEndTime(
                    _totalDelegatedAmount[wallet].month,
                    constantsHolder.proofOfUseLockUpPeriodDays()
                ) <= now) {
                _unlock(wallet);
                return 0;
            } else {
                uint lockedByDelegationController = _getAndUpdateDelegatedAmount(wallet, currentMonth)
                    .add(delegationController.getLockedInPendingDelegations(wallet));
                if (_locked[wallet] > lockedByDelegationController) {
                    return _locked[wallet].boundedSub(lockedByDelegationController);
                } else {
                    return 0;
                }
            }
        } else {
            return 0;
        }
    }

    function getAndUpdateForbiddenForDelegationAmount(address) external override returns (uint) {
        return 0;
    }

    function initialize(address contractManagerAddress) public override initializer {
        Permissions.initialize(contractManagerAddress);
    }

    // private

    function _getAndUpdateDelegatedAmount(address holder, uint currentMonth) private returns (uint) {
        return _delegatedAmount[holder].getAndUpdateValue(currentMonth);
    }

    function _addToDelegatedAmount(address holder, uint amount, uint month) private {
        _delegatedAmount[holder].addToValue(amount, month);
    }

    function _removeFromDelegatedAmount(address holder, uint amount, uint month) private {
        _delegatedAmount[holder].subtractFromValue(amount, month);
    }

    function _addToTotalDelegatedAmount(address holder, uint amount, uint month) private {
        require(
            _totalDelegatedAmount[holder].month == 0 || _totalDelegatedAmount[holder].month <= month,
            "Can't add to total delegated in the past");

        // do not update counter if it is big enough
        // because it will override month value
        if (!_totalDelegatedSatisfiesProofOfUserCondition(holder)) {
            _totalDelegatedAmount[holder].delegated = _totalDelegatedAmount[holder].delegated.add(amount);
            _totalDelegatedAmount[holder].month = month;
        }
    }

    function _unlock(address holder) private {
        emit Unlocked(holder, _locked[holder]);
        delete _locked[holder];
        _deleteDelegatedAmount(holder);
        _deleteTotalDelegatedAmount(holder);
    }

    function _deleteDelegatedAmount(address holder) private {
        _delegatedAmount[holder].clear();
    }

    function _deleteTotalDelegatedAmount(address holder) private {
        delete _totalDelegatedAmount[holder].delegated;
        delete _totalDelegatedAmount[holder].month;
    }

    function _totalDelegatedSatisfiesProofOfUserCondition(address holder) private view returns (bool) {
        ConstantsHolder constantsHolder = ConstantsHolder(contractManager.getContract("ConstantsHolder"));

        return _totalDelegatedAmount[holder].delegated.mul(100) >=
            _locked[holder].mul(constantsHolder.proofOfUseDelegationPercentage());
    }
}