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
        emit LogAdd(msg.sender, 1, &quot;Successfully Added!&quot;);
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
        require(_isAdmin(), &quot;Restricted Access!&quot;);
        require(_isAccepted(_address), &quot;Not allowed address!&quot;);
        require(!_isListed(_address), &quot;Address already exists!&quot;);
        _admin = _address;
        _listed[_getIndex(msg.sender)] = _address;
        emit LogUpdate(msg.sender, _address, 1, &quot;Address updated!&quot;);
        return true;
    }
    function _addToList(address[] _address) public returns(bool) {
        require(_isAdmin(), &quot;Restricted Access!&quot;);
        uint _b = 0;
        while (_b < _address.length) {
            if (!_isAccepted(_address[_b])) {
                emit LogAdd(_address[_b], _b + 1, &quot;Not allowed address!&quot;);
            } else {
                if (_isListed(_address[_b])) {
                    emit LogAdd(_address[_b], _b + 1, &quot;Address already exists!&quot;);
                } else {
                    _listed.push(_address[_b]);
                    emit LogAdd(_address[_b], _b + 1, &quot;Address added!&quot;);
                }
            }
            _b++;
        }
        return true;
    }
    function _updateList(address[] _address, address[] _newAddress) public returns(bool) {
        require(_isAdmin(), &quot;Restricted Access!&quot;);
        require(_address.length == _newAddress.length, &quot;Failed! address length NOT EQUAL new address length&quot;);
        require(_newAddress.length <= _listed.length, &quot;Failed! address length MORE THAN exist length&quot;);
        uint _d = 0;
        while (_d < _address.length) {
            if (_isListed(_address[_d])) {
                if (_isAccepted(_newAddress[_d])) {
                    if (_isListed(_newAddress[_d])) {
                        emit LogUpdate(_address[_d], _newAddress[_d], _d + 1, &quot;Failed! New address already exists!&quot;);
                    } else {
                        if (_address[_d] == _admin) {
                            emit LogUpdate(_address[_d], _newAddress[_d], _d + 1, &quot;Failed! Cannot replace this address&quot;);
                        } else {
                            _listed[_getIndex(_address[_d])] = _newAddress[_d];
                            emit LogUpdate(_address[_d], _newAddress[_d], _d + 1, &quot;Address updated!&quot;);
                        }
                    }
                } else {
                    emit LogUpdate(_address[_d], _newAddress[_d], _d + 1, &quot;Failed! New address not allowed!&quot;);
                }
            } else {
                emit LogUpdate(_address[_d], _newAddress[_d], _d + 1, &quot;Failed! Address not exists&quot;);
            }
            _d++;
        }
        return true;
    }
    function _removeFromList(address[] _address) public returns(bool) {
        require(_isAdmin(), &quot;Restricted Access!&quot;);
        require(_address.length <= _listed.length, &quot;Failed! address length MORE THAN exists length&quot;);
        uint _e = 0;
        uint _fise = 0;
        delete(_existsAddress);
        while (_e < _address.length) {
            if (!_isListed(_address[_e])) {
                emit LogRemove(_address[_e], _e + 1, &quot;Failed! Address not exists&quot;);
            } else {
                if (!_isAccepted(_address[_e])) {
                    emit LogRemove(_address[_e], _e + 1, &quot;Failed! Address not exists&quot;);
                } else {
                    if (_address[_e] == _admin) {
                        emit LogRemove(_address[_e], _e + 1, &quot;Cannot remove this address!&quot;);
                    } else {
                        _listed[_getIndex(_address[_e])] = address(0);
                        emit LogRemove(_address[_e], _e + 1, &quot;Address Removed&quot;);
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
        require(_isAdmin(), &quot;Restricted Access!&quot;);
        delete(_existsAddress);
        uint _g = 0;
        while (_g < _listed.length) {
            if (_listed[_g] != _admin) emit LogRemove(_listed[_g], _g + 1, &quot;Address Removed!&quot;);
            _g++;
        }
        delete(_listed);
        _listed.push(_admin);
        emit LogAdd(_admin, _g + 1, &quot;Address Added!&quot;);
        return true;
    }
    function () public payable {
        revert(&quot;Rejected! Without call any function will always ignored&quot;);
    }
}