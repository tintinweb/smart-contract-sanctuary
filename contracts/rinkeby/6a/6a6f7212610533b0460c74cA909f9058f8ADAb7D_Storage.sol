// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Storage {
    struct TokenList {
        string name;
        string data;
    }

    address private _owner;
    string private _settings;
    TokenList[] private _tokenLists;

    modifier onlyOwner() {
        require(msg.sender == _owner, 'Owner: FORBIDDEN');
        _;
    }

    constructor(address owner_) {
        _owner = owner_;
    }

    function setOwner(address owner_) external onlyOwner {
        require(owner_ != address(0), 'ZERO_ADDRESS');
        _owner = owner_;
    }

    function setSettings(string memory settings_) external onlyOwner {
        _setSettings(settings_);
    }

    function addTokenList(string memory _name, string memory _data) external onlyOwner {
        _addTokenList(_name, _data);
    }

    function addTokenLists(TokenList[] memory _lists) external onlyOwner {
        _addTokenLists(_lists);
    }

    function updateTokenList(
        string memory _oldName,
        string memory _name,
        string memory _data
    ) external onlyOwner {
        bytes memory byteOldName = bytes(_oldName);
        bytes memory byteName = bytes(_name);
        require(byteOldName.length != 0 || byteName.length != 0, 'NAMES_ARE_REQUIRED');
        for(uint x; x < _tokenLists.length; x++) {
            if (keccak256(abi.encodePacked(_tokenLists[x].name)) == keccak256(abi.encodePacked(_oldName))) {
                _tokenLists[x].name = _name;
                _tokenLists[x].data = _data;
                break;
            }
        }
    }

    function removeTokenList(string memory _name) external onlyOwner {
        bytes memory byteName = bytes(_name);
        require(byteName.length != 0, 'NO_NAME');
        bool arrayOffset;
        for(uint x; x < _tokenLists.length - 1; x++) {
            if (keccak256(abi.encodePacked(_tokenLists[x].name)) == keccak256(abi.encodePacked(_name))) {
                arrayOffset = true;
            }
            if (arrayOffset) _tokenLists[x] = _tokenLists[x + 1];
        }
        if (arrayOffset) _tokenLists.pop();
    }

    function clearTokenLists() external onlyOwner {
        delete _tokenLists;
    }

    function owner() external view returns(address) {
        return _owner;
    }

    function settings() external view returns(string memory) {
        return _settings;
    }

    function tokenList(string memory _name) external view returns(string memory _listData) {
        for(uint x; x < _tokenLists.length; x++) {
            if (keccak256(abi.encodePacked(_tokenLists[x].name)) == keccak256(abi.encodePacked(_name))) {
                return _tokenLists[x].data;
            }
        }
    }

    function tokenLists() external view returns(string[] memory) {
        string[] memory lists = new string[](_tokenLists.length);
        for(uint x; x < _tokenLists.length; x++) {
            lists[x] = _tokenLists[x].data;
        }
        return lists;
    }

    function _setSettings(string memory settings_) private {
        _settings = settings_;
    }

    function _addTokenList(string memory _name, string memory _data) private {
        bytes memory byteName = bytes(_name);
        require(byteName.length != 0, 'NO_NAME');
        bool exist;
        for(uint x; x < _tokenLists.length; x++) {
            if (keccak256(abi.encodePacked(_tokenLists[x].name)) == keccak256(abi.encodePacked(_name))) {
                _tokenLists[x].name = _name;
                _tokenLists[x].data = _data;
                exist = true;
            }
        }
        if (!exist) _tokenLists.push(TokenList({name: _name, data: _data}));
    }

    function _addTokenLists(TokenList[] memory _lists) private {
        require(_lists.length > 0, 'NO_DATA');
        for(uint x; x < _lists.length; x++) {
            _addTokenList(_lists[x].name, _lists[x].data);
        }
    }
}