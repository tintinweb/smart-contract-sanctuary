pragma solidity ^0.8.10;

/**
 * @title AddressArrayManagement
 * @dev AddressArrayManagement library
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
library AddressArrayManagement {
    function add(address[] storage _self, address _added) external {
        _self.push(_added);
    }

    function remove(address[] storage _self, address _removed) external {
        uint256 _arrayLength = _self.length;
        for (uint256 _i = 0; _i < _arrayLength; _i++) {
            if (_self[_i] == _removed) {
                if (_arrayLength > 1 && _i < _arrayLength - 1)
                    _self[_i] = _self[_arrayLength - 1];
                _self.pop();
                return;
            }
        }
    }
}