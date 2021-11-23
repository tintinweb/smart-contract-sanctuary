// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./FixedBunker.sol";

/// @title FixedBunkersFactory
/// @author Andrew FU
contract FixedBunkersFactory {
    
    address private _owner;
    uint256 public BunkersLength;
    mapping (uint256 => address) public IdToBunker;

    constructor() {
    	_owner = msg.sender;
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == _owner, "Only Owner can call this function");
        require(newOwner != address(0), 'New owner is the zero address');
        _owner = newOwner;
    }

    function createBunker (uint256 _id, uint256[1] memory _uints, address[2] memory _addrs, string memory _name, string memory _symbol, uint8 _decimals) external returns(address) {
        require(msg.sender == _owner, "Only Owner can call this function");
        FixedBunker newBunker = new FixedBunker();
        newBunker.initialize(_uints, _addrs, _name, _symbol, _decimals);
        if (IdToBunker[_id] != address(0)) {
            BunkersLength++;
        }
        IdToBunker[_id] = address(newBunker);
        return address(newBunker);
    }

    function delBunker (uint256 _id) external returns(bool) {
        require(msg.sender == _owner, "Only Owner can call this function");
        BunkersLength = BunkersLength - 1;
        delete IdToBunker[_id];
        return true;
    }

    function setTagBunkers (uint256[] memory _ids, bool _tag) external returns(bool) {
        require(msg.sender == _owner, "Only Owner can call this function");
        for (uint i = 0; i < _ids.length; i++) {
            FixedBunker bunker = FixedBunker(IdToBunker[_ids[i]]);
            bunker.setTag(_tag);
        }
        return true;
    }

    function setConfigBunker (uint256 _id, address[1] memory _config, address[] memory _rtokens, address _dofin, uint256[2] memory _deposit_limit) external returns(bool) {
        require(msg.sender == _owner, "Only Owner can call this function");
        FixedBunker bunker = FixedBunker(IdToBunker[_id]);
        bunker.setConfig(_config, _rtokens, _dofin, _deposit_limit);
        return true;
    }

}