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

/**
 * @title Events History universal contract.
 *
 * Contract serves as an Events storage and version history for a particular contract type.
 * Events appear on this contract address but their definitions provided by other contracts/libraries.
 * Version info is provided for historical and informational purposes.
 *
 * Note: all the non constant functions return false instead of throwing in case if state change
 * didn&#39;t happen yet.
 */
contract EventsHistory is AmbiEnabled, Safe {
    // Event emitter signature to address with Event definiton mapping.
    mapping(bytes4 => address) public emitters;

    // Calling contract address to version mapping.
    mapping(address => uint) public versions;

    // Version to info mapping.
    mapping(uint => VersionInfo) public versionInfo;

    // Latest verion number.
    uint public latestVersion;

    struct VersionInfo {
        uint block;        // Block number in which version has been introduced.
        address by;        // Contract owner address who added version.
        address caller;    // Address of this version calling contract.
        string name;       // Version name, informative.
        string changelog;  // Version changelog, informative.
    }

    /**
     * Assign emitter address to a specified emit function signature.
     *
     * Can be set only once for each signature, and only by contract owner.
     * Caller contract should be sure that emitter for a particular signature will never change.
     *
     * @param _eventSignature signature of the event emitting function.
     * @param _emitter address with Event definition.
     *
     * @return success.
     */
    function addEmitter(bytes4 _eventSignature, address _emitter) noValue() checkAccess("admin") returns(bool) {
        if (emitters[_eventSignature] != 0x0) {
            return false;
        }
        emitters[_eventSignature] = _emitter;
        return true;
    }

    /**
     * Introduce new caller contract version specifing version information.
     *
     * Can be set only once for each caller, and only by contract owner.
     * Name and changelog should not be empty.
     *
     * @param _caller address of the new caller.
     * @param _name version name.
     * @param _changelog version changelog.
     *
     * @return success.
     */
    function addVersion(address _caller, string _name, string _changelog) noValue() checkAccess("admin") returns(bool) {
        if (versions[_caller] != 0) {
            return false;
        }
        if (bytes(_name).length == 0) {
            return false;
        }
        if (bytes(_changelog).length == 0) {
            return false;
        }
        uint version = ++latestVersion;
        versions[_caller] = version;
        versionInfo[version] = VersionInfo(block.number, msg.sender, _caller, _name, _changelog);
        return true;
    }

    /**
     * Event emitting fallback.
     *
     * Can be and only called caller with assigned version.
     * Resolves msg.sig to an emitter address, and calls it to emit an event.
     *
     * Throws if emit function signature is not registered, or call failed.
     */
    function () noValue() {
        if (versions[msg.sender] == 0) {
            return;
        }
        // Internal Out Of Gas/Throw: revert this transaction too;
        // Call Stack Depth Limit reached: revert this transaction too;
        // Recursive Call: safe, all changes already made.
        if (!emitters[msg.sig].delegatecall(msg.data)) {
            throw;
        }
    }
}