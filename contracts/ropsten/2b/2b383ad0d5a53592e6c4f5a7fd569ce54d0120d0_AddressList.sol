pragma solidity ^0.4.24;
contract AddressList {
    address _admin;
    address[] _listed;
    address[] _existsAddress;
    event LogAdd(address indexed _address, uint _operationIndex, string _details);
    event LogUpdate(address indexed _address, address indexed _newAddress, uint _operationIndex, string _details);
    event LogRemove(address indexed _address, uint _operationIndex, string _details);
    constructor () public {
        _admin = msg.sender;
        _listed.push(msg.sender);
        emit LogAdd(msg.sender, 1, "Successfully Added!");
    }
    function _isAdmin() internal view returns(bool) {
        return (msg.sender == _admin);
    }
    function _isListed(address _address) internal view returns(bool) {
        uint _a = 0;
        bool _rtn = false;
        while (_a < _listed.length) {
            if (_listed[_a] == _address) {
                break;
                _rtn = true;
            }
            _a++;
        }
        return _rtn;
    }
    function _isAccepted(address _address) internal view returns(bool) {
        if (_address == address(0)) {
            return false;
        } else {
            if (_address == address(this)) {
                return false;
            } else {
                return true;
            }
        }
    }
    function _getIndex(address _address) internal view returns(uint) {
        uint _c = 0;
        while (_c < _listed.length) {
            if (_listed[_c] == _address) {
                break;
            }
            _c++;
        }
        return _c;
    }
    function _getList() public view returns(address[]) {
        return _listed;
    }
    function _changeAdmin(address _address) public returns(bool) {
        require(_isAdmin(), "Restricted Access!");
        require(_isAccepted(_address), "Not allowed address!");
        require(!_isListed(_address), "Address already exists!");
        _admin = _address;
        _listed[_getIndex(msg.sender)] = _address;
        emit LogUpdate(msg.sender, _address, 1, "Address updated!");
        return true;
    }
    function _addToList(address[] _address) public returns(bool) {
        require(_isAdmin(), "Restricted Access!");
        uint _b = 0;
        while (_b < _address.length) {
            if (!_isAccepted(_address[_b])) {
                emit LogAdd(_address[_b], _b + 1, "Not allowed address!");
            } else {
                if (_isListed(_address[_b])) {
                    emit LogAdd(_address[_b], _b + 1, "Address already exists!");
                } else {
                    _listed.push(_address[_b]);
                    emit LogAdd(_address[_b], _b + 1, "Address added!");
                }
            }
            _b++;
        }
        return true;
    }
    function _updateList(address[] _address, address[] _newAddress) public returns(bool) {
        require(_isAdmin(), "Restricted Access!");
        require(_address.length == _newAddress.length, "Failed! address length NOT EQUAL new address length");
        require(_newAddress.length <= _listed.length, "Failed! address length MORE THAN exist length");
        uint _d = 0;
        while (_d < _address.length) {
            if (_isListed(_address[_d])) {
                if (_isAccepted(_newAddress[_d])) {
                    if (_isListed(_newAddress[_d])) {
                        emit LogUpdate(_address[_d], _newAddress[_d], _d + 1, "Failed! New address already exists!");
                    } else {
                        if (_address[_d] == _admin) {
                            emit LogUpdate(_address[_d], _newAddress[_d], _d + 1, "Failed! Cannot replace this address");
                        } else {
                            _listed[_getIndex(_address[_d])] = _newAddress[_d];
                            emit LogUpdate(_address[_d], _newAddress[_d], _d + 1, "Address updated!");
                        }
                    }
                } else {
                    emit LogUpdate(_address[_d], _newAddress[_d], _d + 1, "Failed! New address not allowed!");
                }
            } else {
                emit LogUpdate(_address[_d], _newAddress[_d], _d + 1, "Failed! Address not exists");
            }
            _d++;
        }
        return true;
    }
    function _removeFromList(address[] _address) public returns(bool) {
        require(_isAdmin(), "Restricted Access!");
        require(_address.length <= _listed.length, "Failed! address length MORE THAN exists length");
        uint _e = 0;
        uint _fise = 0;
        delete(_existsAddress);
        while (_e < _address.length) {
            if (!_isListed(_address[_e])) {
                emit LogRemove(_address[_e], _e + 1, "Failed! Address not exists");
            } else {
                if (!_isAccepted(_address[_e])) {
                    emit LogRemove(_address[_e], _e + 1, "Failed! Address not exists");
                } else {
                    if (_address[_e] == _admin) {
                        emit LogRemove(_address[_e], _e + 1, "Cannot remove this address!");
                    } else {
                        _listed[_getIndex(_address[_e])] = address(0);
                        emit LogRemove(_address[_e], _e + 1, "Address Removed");
                    }
                }
            }
            _e++;
        }
        while (_fise < _listed.length) {
            if (_listed[_fise] != address(0)) _existsAddress.push(_listed[_fise]);
            _fise++;
        }
        delete(_listed);
        _listed = _existsAddress;
        return true;
    }
    function _resetList() public returns(bool) {
        require(_isAdmin(), "Restricted Access!");
        delete(_existsAddress);
        uint _g = 0;
        while (_g < _listed.length) {
            if (_listed[_g] != _admin) emit LogRemove(_listed[_g], _g + 1, "Address Removed!");
            _g++;
        }
        delete(_listed);
        _listed.push(_admin);
        emit LogAdd(_admin, _g + 1, "Address Added!");
        return true;
    }
    function () public payable {
        revert("Rejected! Without call any function will always ignored");
    }
}