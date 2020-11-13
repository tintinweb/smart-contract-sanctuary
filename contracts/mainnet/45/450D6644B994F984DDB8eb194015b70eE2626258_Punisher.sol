// SPDX-License-Identifier: AGPL-3.0-only

/*
    Punisher.sol - SKALE Manager
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

import "./ValidatorService.sol";
import "./DelegationController.sol";

/**
 * @title Punisher
 * @dev This contract handles all slashing and forgiving operations.
 */
contract Punisher is Permissions, ILocker {

    //        holder => tokens
    mapping (address => uint) private _locked;

    /**
     * @dev Emitted upon slashing condition.
     */
    event Slash(
        uint validatorId,
        uint amount
    );

    /**
     * @dev Emitted upon forgive condition.
     */
    event Forgive(
        address wallet,
        uint amount
    );

    /**
     * @dev Allows SkaleDKG contract to execute slashing on a validator and
     * validator's delegations by an `amount` of tokens.
     * 
     * Emits a {Slash} event.
     * 
     * Requirements:
     * 
     * - Validator must exist.
     */
    function slash(uint validatorId, uint amount) external allow("SkaleDKG") {
        ValidatorService validatorService = ValidatorService(contractManager.getContract("ValidatorService"));
        DelegationController delegationController = DelegationController(
            contractManager.getContract("DelegationController"));

        require(validatorService.validatorExists(validatorId), "Validator does not exist");

        delegationController.confiscate(validatorId, amount);

        emit Slash(validatorId, amount);
    }

    /**
     * @dev Allows the Admin to forgive a slashing condition.
     * 
     * Emits a {Forgive} event.
     * 
     * Requirements:
     * 
     * - All slashes must have been processed.
     */
    function forgive(address holder, uint amount) external onlyAdmin {
        DelegationController delegationController = DelegationController(
            contractManager.getContract("DelegationController"));

        require(!delegationController.hasUnprocessedSlashes(holder), "Not all slashes were calculated");

        if (amount > _locked[holder]) {
            delete _locked[holder];
        } else {
            _locked[holder] = _locked[holder].sub(amount);
        }

        emit Forgive(holder, amount);
    }

    /**
     * @dev See {ILocker-getAndUpdateLockedAmount}.
     */
    function getAndUpdateLockedAmount(address wallet) external override returns (uint) {
        return _getAndUpdateLockedAmount(wallet);
    }

    /**
     * @dev See {ILocker-getAndUpdateForbiddenForDelegationAmount}.
     */
    function getAndUpdateForbiddenForDelegationAmount(address wallet) external override returns (uint) {
        return _getAndUpdateLockedAmount(wallet);
    }

    /**
     * @dev Allows DelegationController contract to execute slashing of
     * delegations.
     */
    function handleSlash(address holder, uint amount) external allow("DelegationController") {
        _locked[holder] = _locked[holder].add(amount);
    }

    function initialize(address contractManagerAddress) public override initializer {
        Permissions.initialize(contractManagerAddress);
    }

    // private

    /**
     * @dev See {ILocker-getAndUpdateLockedAmount}.
     */
    function _getAndUpdateLockedAmount(address wallet) private returns (uint) {
        DelegationController delegationController = DelegationController(
            contractManager.getContract("DelegationController"));

        delegationController.processAllSlashes(wallet);
        return _locked[wallet];
    }

}