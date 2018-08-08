// This software is a subject to Ambisafe License Agreement.
// No use or distribution is allowed without written permission from Ambisafe.
// https://ambisafe.com/terms.pdf

contract Ambi {
    function getNodeAddress(bytes32 _nodeName) constant returns(address);
    function hasRelation(bytes32 _nodeName, bytes32 _relation, address _to) constant returns(bool);
    function addNode(bytes32 _nodeName, address _nodeAddress) constant returns(bool);
}

contract AmbiEnabled {
    Ambi public ambiC;
    bool public isImmortal;
    bytes32 public name;

    modifier checkAccess(bytes32 _role) {
        if(address(ambiC) != 0x0 && ambiC.hasRelation(name, _role, msg.sender)){
            _
        }
    }
    
    function getAddress(bytes32 _name) constant returns (address) {
        return ambiC.getNodeAddress(_name);
    }

    function setAmbiAddress(address _ambi, bytes32 _name) returns (bool){
        if(address(ambiC) != 0x0){
            return false;
        }
        Ambi ambiContract = Ambi(_ambi);
        if(ambiContract.getNodeAddress(_name)!=address(this)) {
            if (!ambiContract.addNode(_name, address(this))){
                return false;
            }
        }
        name = _name;
        ambiC = ambiContract;
        return true;
    }

    function immortality() checkAccess("owner") returns(bool) {
        isImmortal = true;
        return true;
    }

    function remove() checkAccess("owner") returns(bool) {
        if (isImmortal) {
            return false;
        }
        selfdestruct(msg.sender);
        return true;
    }
}

library StackDepthLib {
    // This will probably work with a value of 390 but no need to cut it
    // that close in the case that the optimizer changes slightly or
    // something causing that number to rise slightly.
    uint constant GAS_PER_DEPTH = 400;

    function checkDepth(address self, uint n) constant returns(bool) {
        if (n == 0) return true;
        return self.call.gas(GAS_PER_DEPTH * n)(0x21835af6, n - 1);
    }

    function __dig(uint n) constant {
        if (n == 0) return;
        if (!address(this).delegatecall(0x21835af6, n - 1)) throw;
    }
}

contract Safe {
    // Should always be placed as first modifier!
    modifier noValue {
        if (msg.value > 0) {
            // Internal Out Of Gas/Throw: revert this transaction too;
            // Call Stack Depth Limit reached: revert this transaction too;
            // Recursive Call: safe, no any changes applied yet, we are inside of modifier.
            _safeSend(msg.sender, msg.value);
        }
        _
    }

    modifier onlyHuman {
        if (_isHuman()) {
            _
        }
    }

    modifier noCallback {
        if (!isCall) {
            _
        }
    }

    modifier immutable(address _address) {
        if (_address == 0) {
            _
        }
    }

    address stackDepthLib;
    function setupStackDepthLib(address _stackDepthLib) immutable(address(stackDepthLib)) returns(bool) {
        stackDepthLib = _stackDepthLib;
        return true;
    }

    modifier requireStackDepth(uint16 _depth) {
        if (stackDepthLib == 0x0) {
            throw;
        }
        if (_depth > 1023) {
            throw;
        }
        if (!stackDepthLib.delegatecall(0x32921690, stackDepthLib, _depth)) {
            throw;
        }
        _
    }

    // Must not be used inside the functions that have noValue() modifier!
    function _safeFalse() internal noValue() returns(bool) {
        return false;
    }

    function _safeSend(address _to, uint _value) internal {
        if (!_unsafeSend(_to, _value)) {
            throw;
        }
    }

    function _unsafeSend(address _to, uint _value) internal returns(bool) {
        return _to.call.value(_value)();
    }

    function _isContract() constant internal returns(bool) {
        return msg.sender != tx.origin;
    }

    function _isHuman() constant internal returns(bool) {
        return !_isContract();
    }

    bool private isCall = false;
    function _setupNoCallback() internal {
        isCall = true;
    }

    function _finishNoCallback() internal {
        isCall = false;
    }
}

contract RegistryICAP is AmbiEnabled, Safe {
    function decodeIndirect(bytes _bban) constant returns(string, string, string) {
        bytes memory asset = new bytes(3);
        bytes memory institution = new bytes(4);
        bytes memory client = new bytes(9);

        uint8 k = 0;

        for (uint8 i = 0; i < asset.length; i++) {
            asset[i] = _bban[k++];
        }
        for (i = 0; i < institution.length; i++) {
            institution[i] = _bban[k++];
        }
        for (i = 0; i < client.length; i++) {
            client[i] = _bban[k++];
        }
        return (string(asset), string(institution), string(client));
    }

    function parse(bytes32 _icap) constant returns(address, bytes32, bool) {
        // Should start with XE.
        if (_icap[0] != 88 || _icap[1] != 69) {
            return (0, 0, false);
        }
        // Should have 12 zero bytes at the end.
        for (uint8 j = 20; j < 32; j++) {
            if (_icap[j] != 0) {
                return (0, 0, false);
            }
        }
        bytes memory bban = new bytes(18);
        for (uint8 i = 0; i < 16; i++) {
             bban[i] = _icap[i + 4];
        }
        var (asset, institution, _) = decodeIndirect(bban);

        bytes32 assetInstitutionHash = sha3(asset, institution);

        uint8 parseChecksum = (uint8(_icap[2]) - 48) * 10 + (uint8(_icap[3]) - 48);
        uint8 calcChecksum = 98 - mod9710(prepare(bban));
        if (parseChecksum != calcChecksum) {
            return (institutions[assetInstitutionHash], assets[sha3(asset)], false);
        }
        return (institutions[assetInstitutionHash], assets[sha3(asset)], registered[assetInstitutionHash]);
    }

    function prepare(bytes _bban) constant returns(bytes) {
        for (uint8 i = 0; i < 16; i++) {
            uint8 charCode = uint8(_bban[i]);
            if (charCode >= 65 && charCode <= 90) {
                _bban[i] = byte(charCode - 65 + 10);
            }
        }
        _bban[16] = 33; // X
        _bban[17] = 14; // E
        //_bban[18] = 48; // 0
        //_bban[19] = 48; // 0
        return _bban;
    }

    function mod9710(bytes _prepared) constant returns(uint8) {
        uint m = 0;
        for (uint8 i = 0; i < 18; i++) {
            uint8 charCode = uint8(_prepared[i]);
            if (charCode >= 48) {
                m *= 10;
                m += charCode - 48; // number
                m %= 97;
            } else {
                m *= 10;
                m += charCode / 10; // part1
                m %= 97;
                m *= 10;
                m += charCode % 10; // part2
                m %= 97;
            }
        }
        m *= 10;
        //m += uint8(_prepared[18]) - 48;
        m %= 97;
        m *= 10;
        //m += uint8(_prepared[19]) - 48;
        m %= 97;
        return uint8(m);
    }

    mapping(bytes32 => bool) public registered;
    mapping(bytes32 => address) public institutions;
    mapping(bytes32 => address) public institutionOwners;
    mapping(bytes32 => bytes32) public assets;

    modifier onlyInstitutionOwner(string _institution) {
        if (msg.sender == institutionOwners[sha3(_institution)]) {
            _
        }
    }

    function changeInstitutionOwner(string _institution, address _address) noValue() onlyInstitutionOwner(_institution) returns(bool) {
        institutionOwners[sha3(_institution)] = _address;
        return true;
    }

    // web3js sendIBANTransaction interface
    function addr(bytes32 _institution) constant returns(address) {
        return institutions[sha3("ETH", _institution[0], _institution[1], _institution[2], _institution[3])];
    }

    function registerInstitution(string _institution, address _address) noValue() checkAccess("admin") returns(bool) {
        if (bytes(_institution).length != 4) {
            return false;
        }
        if (institutionOwners[sha3(_institution)] != 0) {
            return false;
        }
        institutionOwners[sha3(_institution)] = _address;
        return true;
    }

    function registerInstitutionAsset(string _asset, string _institution, address _address) noValue() onlyInstitutionOwner(_institution) returns(bool) {
        if (!registered[sha3(_asset)]) {
            return false;
        }
        bytes32 assetInstitutionHash = sha3(_asset, _institution);
        if (registered[assetInstitutionHash]) {
            return false;
        }
        registered[assetInstitutionHash] = true;
        institutions[assetInstitutionHash] = _address;
        return true;
    }

    function updateInstitutionAsset(string _asset, string _institution, address _address) noValue() onlyInstitutionOwner(_institution) returns(bool) {
        bytes32 assetInstitutionHash = sha3(_asset, _institution);
        if (!registered[assetInstitutionHash]) {
            return false;
        }
        institutions[assetInstitutionHash] = _address;
        return true;
    }

    function removeInstitutionAsset(string _asset, string _institution) noValue() onlyInstitutionOwner(_institution) returns(bool) {
        bytes32 assetInstitutionHash = sha3(_asset, _institution);
        if (!registered[assetInstitutionHash]) {
            return false;
        }
        delete registered[assetInstitutionHash];
        delete institutions[assetInstitutionHash];
        return true;
    }

    function registerAsset(string _asset, bytes32 _symbol) noValue() checkAccess("admin") returns(bool) {
        if (bytes(_asset).length != 3) {
            return false;
        }
        bytes32 asset = sha3(_asset);
        if (registered[asset]) {
            return false;
        }
        registered[asset] = true;
        assets[asset] = _symbol;
        return true;
    }
}