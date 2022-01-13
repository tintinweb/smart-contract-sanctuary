pragma solidity ^0.8.10;

import "../commons/Types.sol";

/**
 * @title TemplateSetLibrary
 * @dev A library to handle template changes/updates.
 * @author Federico Luzzi <[email protected]>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
library TemplateSetLibrary {
    error ZeroAddressTemplate();
    error InvalidDescription();
    error TemplateAlreadyAdded();
    error NonExistentTemplate();
    error NoKeyForTemplate();
    error NotAnUpgrade();
    error InvalidIndices();

    function contains(EnumerableTemplateSet storage _self, address _template)
        public
        view
        returns (bool)
    {
        return _template != address(0) && _self.map[_template].exists;
    }

    function get(EnumerableTemplateSet storage _self, address _template)
        public
        view
        returns (Template memory)
    {
        if (!contains(_self, _template)) revert NonExistentTemplate();
        return _self.map[_template];
    }

    function add(
        EnumerableTemplateSet storage _self,
        address _template,
        string calldata _description
    ) public {
        if (_template == address(0)) revert ZeroAddressTemplate();
        if (bytes(_description).length == 0) revert InvalidDescription();
        if (_self.map[_template].exists) revert TemplateAlreadyAdded();
        _self.map[_template] = Template({
            description: _description,
            verified: false,
            exists: true
        });
        _self.keys.push(_template);
    }

    function remove(EnumerableTemplateSet storage _self, address _template)
        public
    {
        if (!_self.map[_template].exists) revert NonExistentTemplate();
        delete _self.map[_template];
        uint256 _keysLength = _self.keys.length;
        for (uint256 _i = 0; _i < _keysLength; _i++)
            if (_self.keys[_i] == _template) {
                _self.keys[_i] = _self.keys[_keysLength - 1];
                _self.keys.pop();
                return;
            }
        revert NoKeyForTemplate();
    }

    function upgrade(
        EnumerableTemplateSet storage _self,
        address _template,
        address _newTemplate,
        string calldata _newDescription
    ) external {
        if (_newTemplate == address(0)) revert ZeroAddressTemplate();
        if (bytes(_newDescription).length == 0) revert InvalidDescription();
        if (_template == _newTemplate) revert NotAnUpgrade();
        Template storage _templateFromStorage = _self.map[_template];
        if (!_templateFromStorage.exists) revert NonExistentTemplate();
        if (
            keccak256(bytes(_templateFromStorage.description)) ==
            keccak256(bytes(_newDescription))
        ) revert InvalidDescription();
        remove(_self, _template);
        add(_self, _newTemplate, _newDescription);
    }

    function verify(EnumerableTemplateSet storage _self, address _template)
        external
    {
        if (!contains(_self, _template)) revert NonExistentTemplate();
        _self.map[_template].verified = true;
    }

    function size(EnumerableTemplateSet storage _self)
        external
        view
        returns (uint256)
    {
        return _self.keys.length;
    }

    function enumerate(
        EnumerableTemplateSet storage _self,
        uint256 _fromIndex,
        uint256 _toIndex
    ) external view returns (Template[] memory) {
        if (_toIndex > _self.keys.length - 1 || _fromIndex > _toIndex)
            revert InvalidIndices();
        uint256 _range = _toIndex - _fromIndex;
        Template[] memory _templates = new Template[](_range - 1);
        for (uint256 _i = 0; _i < _range; _i++) {
            _templates[_i] = _self.map[_self.keys[_fromIndex + _i]];
        }
        return _templates;
    }
}

pragma solidity ^0.8.10;

/**
 * @title Common types
 * @dev Common types
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

struct Collateral {
    address token;
    uint256 amount;
}

struct Oracle {
    address addrezz;
    uint256 lowerBound;
    uint256 higherBound;
    uint256 weight;
}

struct OracleCreationData {
    address template;
    bytes initializationData;
    uint256 jobFunding;
}

struct KpiTokenCreationOracle {
    address template;
    uint256 lowerBound;
    uint256 higherBound;
    uint256 jobFunding;
    uint256 weight;
    bytes initializationData;
}

struct FinalizableOracle {
    uint256 lowerBound;
    uint256 higherBound;
    uint256 finalProgress;
    uint256 weight;
    bool finalized;
}

struct Template {
    string description;
    bool verified;
    bool exists;
}

struct EnumerableTemplateSet {
    mapping(address => Template) map;
    address[] keys;
}