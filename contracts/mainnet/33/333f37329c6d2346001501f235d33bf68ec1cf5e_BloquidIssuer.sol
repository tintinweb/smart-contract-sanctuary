pragma solidity ^0.4.11;

contract Ambi2 {
    function hasRole(address, bytes32, address) constant returns(bool);
    function claimFor(address, address) returns(bool);
    function isOwner(address, address) constant returns(bool);
}

contract Ambi2Enabled {
    Ambi2 ambi2;

    modifier onlyRole(bytes32 _role) {
        if (address(ambi2) != 0x0 && ambi2.hasRole(this, _role, msg.sender)) {
            _;
        }
    }

    // Perform only after claiming the node, or claim in the same tx.
    function setupAmbi2(Ambi2 _ambi2) returns(bool) {
        if (address(ambi2) != 0x0) {
            return false;
        }

        ambi2 = _ambi2;
        return true;
    }
}

contract Ambi2EnabledFull is Ambi2Enabled {
    // Setup and claim atomically.
    function setupAmbi2(Ambi2 _ambi2) returns(bool) {
        if (address(ambi2) != 0x0) {
            return false;
        }
        if (!_ambi2.claimFor(this, msg.sender) && !_ambi2.isOwner(this, msg.sender)) {
            return false;
        }

        ambi2 = _ambi2;
        return true;
    }
}

contract EToken2Interface {
    function reissueAsset(bytes32 _symbol, uint _value) returns(bool);
    function changeOwnership(bytes32 _symbol, address _newOwner) returns(bool);
}

contract AssetProxy {
    EToken2Interface public etoken2;
    bytes32 public etoken2Symbol;
    function transferWithReference(address _to, uint _value, string _reference) returns (bool);
}

contract BloquidIssuer is Ambi2EnabledFull {

    AssetProxy public assetProxy;

    function setupAssetProxy(AssetProxy _assetProxy) onlyRole("__root__") returns(bool) {
        if ((address(assetProxy) != 0x0) || (address(_assetProxy) == 0x0)) {
            return false;
        }
        assetProxy = _assetProxy;
        return true;
    }

    function issueTokens(uint _value, string _regNumber) onlyRole("issuer") returns(bool) {
        bytes32 symbol = assetProxy.etoken2Symbol();
        EToken2Interface etoken2 = assetProxy.etoken2();
        if (!etoken2.reissueAsset(symbol, _value)) {
            return false;
        }
        if (!assetProxy.transferWithReference(msg.sender, _value, _regNumber)) {
            throw;
        }
        return true;
    }

    function changeAssetOwner(address _newOwner) onlyRole("__root__") returns(bool) {
        if (_newOwner == 0x0) {
            return false;
        }
        bytes32 symbol = assetProxy.etoken2Symbol();
        EToken2Interface etoken2 = assetProxy.etoken2();
        if (!etoken2.changeOwnership(symbol, _newOwner)) {
            return false;
        }
        return true;
    }

}