pragma solidity ^0.8.10;

import "../commons/Types.sol";

error NonExistentCredit();
error InvalidNewCredits();
error InvalidOldCredit();
error NotEnoughCredit();

/**
 * @title CreditManagement
 * @dev CreditManagement library
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
library CreditManagement {
    function getOrAdd(Credit[] storage _credits, address _token)
        private
        returns (Credit storage)
    {
        for (uint256 _i = 0; _i < _credits.length; _i++) {
            Credit storage _credit = _credits[_i];
            if (_credit.token == _token) return _credit;
        }
        Credit storage _newCredit = _credits.push();
        _newCredit.token = _token;
        return _newCredit;
    }

    function get(Credit[] storage _self, address _token)
        public
        view
        returns (Credit storage, uint256 _index)
    {
        for (uint256 _i = 0; _i < _self.length; _i++) {
            Credit storage _credit = _self[_i];
            if (_credit.token == _token) return (_credit, _i);
        }
        revert NonExistentCredit();
    }

    function add(
        Credit[] storage _self,
        address _token,
        uint256 _amount,
        bool _locked
    ) external {
        Credit storage _credit = getOrAdd(_self, _token);
        _credit.amount += _amount;
        if (_locked) _credit.locked += _amount;
    }

    function remove(
        Credit[] storage _self,
        address _token,
        uint256 _amount,
        bool _consumeLocked
    ) external {
        (Credit storage _credit, uint256 _index) = get(_self, _token);
        if (!_consumeLocked && _credit.amount - _credit.locked < _amount)
            revert NotEnoughCredit();
        _credit.amount -= _amount;
        uint256 _lockedCredit = _credit.locked;
        if (_consumeLocked && _lockedCredit > 0)
            _credit.locked -= _lockedCredit > _amount ? _amount : _lockedCredit;
        uint256 _selfLength = _self.length;
        if (_credit.amount == 0) {
            if (_selfLength > 1 && _index < _selfLength - 1)
                _self[_index] = _self[_selfLength - 1];
            _self.pop();
        }
    }

    function migrate(Credit[] storage _self, Credit[] storage _newCredits)
        external
    {
        if (_self.length == 0) return; // nothing to migrate
        if (_newCredits.length > 0) revert InvalidNewCredits();
        for (uint256 _i = 0; _i < _self.length; _i++) {
            Credit storage _oldCredit = _self[_i];
            if (_oldCredit.token == address(0)) revert InvalidOldCredit();
            if (_oldCredit.amount == 0) continue; // not migrating empty credits
            _newCredits.push(_oldCredit);
        }
    }
}

pragma solidity ^0.8.10;

/**
 * @title Types
 * @dev Struct type definitions
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */

struct Worker {
    bool disallowed;
    uint256 bonded;
    uint256 earned;
    uint256 bonding;
    uint256 bondingTimestamp;
    uint256 unbonding;
    uint256 unbondingTimestamp;
    uint256 activationTimestamp;
    uint256 worksCompleted;
}

struct Credit {
    address token;
    uint256 amount;
    uint256 locked;
}

struct Job {
    address owner;
    string contentHash;
    Credit[] credits;
}

struct JobWithAddress {
    address addrezz;
    address owner;
    string contentHash;
    Credit[] credits;
}