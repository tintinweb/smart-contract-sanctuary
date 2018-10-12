pragma solidity 0.4.23;

contract AssetInterface {
    function _performTransferWithReference(address _to, uint _value, string _reference, address _sender) public returns(bool);
    function _performTransferToICAPWithReference(bytes32 _icap, uint _value, string _reference, address _sender) public returns(bool);
    function _performApprove(address _spender, uint _value, address _sender) public returns(bool);
    function _performTransferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) public returns(bool);
    function _performTransferFromToICAPWithReference(address _from, bytes32 _icap, uint _value, string _reference, address _sender) public returns(bool);
    function _performGeneric(bytes, address) public payable {
        revert();
    }
}

contract ERC20Interface {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);

    function totalSupply() public view returns(uint256 supply);
    function balanceOf(address _owner) public view returns(uint256 balance);
    function transfer(address _to, uint256 _value) public returns(bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success);
    function approve(address _spender, uint256 _value) public returns(bool success);
    function allowance(address _owner, address _spender) public view returns(uint256 remaining);

    function decimals() public view returns(uint8);
}

contract AssetProxy is ERC20Interface {
    function _forwardApprove(address _spender, uint _value, address _sender) public returns(bool);
    function _forwardTransferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) public returns(bool);
    function _forwardTransferFromToICAPWithReference(address _from, bytes32 _icap, uint _value, string _reference, address _sender) public returns(bool);
}

contract Bytes32 {
    function _bytes32(string _input) internal pure returns(bytes32 result) {
        assembly {
            result := mload(add(_input, 32))
        }
    }
}

contract ReturnData {
    function _returnReturnData(bool _success) internal pure {
        assembly {
            let returndatastart := 0
            returndatacopy(returndatastart, 0, returndatasize)
            switch _success case 0 { revert(returndatastart, returndatasize) } default { return(returndatastart, returndatasize) }
        }
    }

    function _assemblyCall(address _destination, uint _value, bytes _data) internal returns(bool success) {
        assembly {
            success := call(gas, _destination, _value, add(_data, 32), mload(_data), 0, 0)
        }
    }
}

/**
 * @title EToken2 Asset implementation contract.
 *
 * Basic asset implementation contract, without any additional logic.
 * Every other asset implementation contracts should derive from this one.
 * Receives calls from the proxy, and calls back immediately without arguments modification.
 *
 * Note: all the non constant functions return false instead of throwing in case if state change
 * didn&#39;t happen yet.
 */
contract Asset is AssetInterface, Bytes32, ReturnData {
    // Assigned asset proxy contract, immutable.
    AssetProxy public proxy;

    /**
     * Only assigned proxy is allowed to call.
     */
    modifier onlyProxy() {
        if (proxy == msg.sender) {
            _;
        }
    }

    /**
     * Sets asset proxy address.
     *
     * Can be set only once.
     *
     * @param _proxy asset proxy contract address.
     *
     * @return success.
     * @dev function is final, and must not be overridden.
     */
    function init(AssetProxy _proxy) public returns(bool) {
        if (address(proxy) != 0x0) {
            return false;
        }
        proxy = _proxy;
        return true;
    }

    /**
     * Passes execution into virtual function.
     *
     * Can only be called by assigned asset proxy.
     *
     * @return success.
     * @dev function is final, and must not be overridden.
     */
    function _performTransferWithReference(address _to, uint _value, string _reference, address _sender) public onlyProxy() returns(bool) {
        if (isICAP(_to)) {
            return _transferToICAPWithReference(bytes32(_to) << 96, _value, _reference, _sender);
        }
        return _transferWithReference(_to, _value, _reference, _sender);
    }

    /**
     * Calls back without modifications.
     *
     * @return success.
     * @dev function is virtual, and meant to be overridden.
     */
    function _transferWithReference(address _to, uint _value, string _reference, address _sender) internal returns(bool) {
        return proxy._forwardTransferFromWithReference(_sender, _to, _value, _reference, _sender);
    }

    /**
     * Passes execution into virtual function.
     *
     * Can only be called by assigned asset proxy.
     *
     * @return success.
     * @dev function is final, and must not be overridden.
     */
    function _performTransferToICAPWithReference(bytes32 _icap, uint _value, string _reference, address _sender) public onlyProxy() returns(bool) {
        return _transferToICAPWithReference(_icap, _value, _reference, _sender);
    }

    /**
     * Calls back without modifications.
     *
     * @return success.
     * @dev function is virtual, and meant to be overridden.
     */
    function _transferToICAPWithReference(bytes32 _icap, uint _value, string _reference, address _sender) internal returns(bool) {
        return proxy._forwardTransferFromToICAPWithReference(_sender, _icap, _value, _reference, _sender);
    }

    /**
     * Passes execution into virtual function.
     *
     * Can only be called by assigned asset proxy.
     *
     * @return success.
     * @dev function is final, and must not be overridden.
     */
    function _performTransferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) public onlyProxy() returns(bool) {
        if (isICAP(_to)) {
            return _transferFromToICAPWithReference(_from, bytes32(_to) << 96, _value, _reference, _sender);
        }
        return _transferFromWithReference(_from, _to, _value, _reference, _sender);
    }

    /**
     * Calls back without modifications.
     *
     * @return success.
     * @dev function is virtual, and meant to be overridden.
     */
    function _transferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) internal returns(bool) {
        return proxy._forwardTransferFromWithReference(_from, _to, _value, _reference, _sender);
    }

    /**
     * Passes execution into virtual function.
     *
     * Can only be called by assigned asset proxy.
     *
     * @return success.
     * @dev function is final, and must not be overridden.
     */
    function _performTransferFromToICAPWithReference(address _from, bytes32 _icap, uint _value, string _reference, address _sender) public onlyProxy() returns(bool) {
        return _transferFromToICAPWithReference(_from, _icap, _value, _reference, _sender);
    }

    /**
     * Calls back without modifications.
     *
     * @return success.
     * @dev function is virtual, and meant to be overridden.
     */
    function _transferFromToICAPWithReference(address _from, bytes32 _icap, uint _value, string _reference, address _sender) internal returns(bool) {
        return proxy._forwardTransferFromToICAPWithReference(_from, _icap, _value, _reference, _sender);
    }

    /**
     * Passes execution into virtual function.
     *
     * Can only be called by assigned asset proxy.
     *
     * @return success.
     * @dev function is final, and must not be overridden.
     */
    function _performApprove(address _spender, uint _value, address _sender) public onlyProxy() returns(bool) {
        return _approve(_spender, _value, _sender);
    }

    /**
     * Calls back without modifications.
     *
     * @return success.
     * @dev function is virtual, and meant to be overridden.
     */
    function _approve(address _spender, uint _value, address _sender) internal returns(bool) {
        return proxy._forwardApprove(_spender, _value, _sender);
    }

    /**
     * Passes execution into virtual function.
     *
     * Can only be called by assigned asset proxy.
     *
     * @return bytes32 result.
     * @dev function is final, and must not be overridden.
     */
    function _performGeneric(bytes _data, address _sender) public payable onlyProxy() {
        _generic(_data, msg.value, _sender);
    }

    modifier onlyMe() {
        if (this == msg.sender) {
            _;
        }
    }

    // Most probably the following should never be redefined in child contracts.
    address public genericSender;
    function _generic(bytes _data, uint _value, address _msgSender) internal {
        // Restrict reentrancy.
        require(genericSender == 0x0);
        genericSender = _msgSender;
        bool success = _assemblyCall(address(this), _value, _data);
        delete genericSender;
        _returnReturnData(success);
    }

    // Decsendants should use _sender() instead of msg.sender to properly process proxied calls.
    function _sender() internal view returns(address) {
        return this == msg.sender ? genericSender : msg.sender;
    }

    // Interface functions to allow specifying ICAP addresses as strings.
    function transferToICAP(string _icap, uint _value) public returns(bool) {
        return transferToICAPWithReference(_icap, _value, &#39;&#39;);
    }

    function transferToICAPWithReference(string _icap, uint _value, string _reference) public returns(bool) {
        return _transferToICAPWithReference(_bytes32(_icap), _value, _reference, _sender());
    }

    function transferFromToICAP(address _from, string _icap, uint _value) public returns(bool) {
        return transferFromToICAPWithReference(_from, _icap, _value, &#39;&#39;);
    }

    function transferFromToICAPWithReference(address _from, string _icap, uint _value, string _reference) public returns(bool) {
        return _transferFromToICAPWithReference(_from, _bytes32(_icap), _value, _reference, _sender());
    }

    function isICAP(address _address) public pure returns(bool) {
        bytes32 a = bytes32(_address) << 96;
        if (a[0] != &#39;X&#39; || a[1] != &#39;E&#39;) {
            return false;
        }
        if (a[2] < 48 || a[2] > 57 || a[3] < 48 || a[3] > 57) {
            return false;
        }
        for (uint i = 4; i < 20; i++) {
            uint char = uint(a[i]);
            if (char < 48 || char > 90 || (char > 57 && char < 65)) {
                return false;
            }
        }
        return true;
    }
}

contract Ambi2 {
    function claimFor(address _address, address _owner) public returns(bool);
    function hasRole(address _from, bytes32 _role, address _to) public view returns(bool);
    function isOwner(address _node, address _owner) public view returns(bool);
}

contract Ambi2Enabled {
    Ambi2 ambi2;

    modifier onlyRole(bytes32 _role) {
        if (address(ambi2) != 0x0 && ambi2.hasRole(this, _role, msg.sender)) {
            _;
        }
    }

    // Perform only after claiming the node, or claim in the same tx.
    function setupAmbi2(Ambi2 _ambi2) public returns(bool) {
        if (address(ambi2) != 0x0) {
            return false;
        }

        ambi2 = _ambi2;
        return true;
    }
}

contract Ambi2EnabledFull is Ambi2Enabled {
    // Setup and claim atomically.
    function setupAmbi2(Ambi2 _ambi2) public returns(bool) {
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

contract AssetWithAmbi is Asset, Ambi2EnabledFull {
    modifier onlyRole(bytes32 _role) {
        if (address(ambi2) != 0x0 && (ambi2.hasRole(this, _role, _sender()))) {
            _;
        }
    }
}

/**
 * @title EToken2 Asset with whitelist implementation contract.
 */
contract AssetWithWhitelist is AssetWithAmbi {
    mapping(address => bool) public whitelist;
    uint public restrictionExpiraton;
    bool public restrictionRemoved;

    event Error(bytes32 _errorText);

    function allowTransferFrom(address _from) public onlyRole(&#39;admin&#39;) returns(bool) {
        whitelist[_from] = true;
        return true;
    }

    function blockTransferFrom(address _from) public onlyRole(&#39;admin&#39;) returns(bool) {
        whitelist[_from] = false;
        return true;
    }

    function transferIsAllowed(address _from) public view returns(bool) {
        return restrictionRemoved || whitelist[_from] || (now >= restrictionExpiraton);
    }

    function removeRestriction() public onlyRole(&#39;admin&#39;) returns(bool) {
        restrictionRemoved = true;
        return true;
    }

    modifier transferAllowed(address _sender) {
        if (!transferIsAllowed(_sender)) {
            emit Error(&#39;Transfer not allowed&#39;);
            return;
        }
        _;
    }

    function setExpiration(uint _time) public onlyRole(&#39;admin&#39;) returns(bool) {
        if (restrictionExpiraton != 0) {
            emit Error(&#39;Expiration time already set&#39;);
            return false;
        }
        if (_time < now) {
            emit Error(&#39;Expiration time invalid&#39;);
            return false;
        }
        restrictionExpiraton = _time;
        return true;
    }

    // Transfers
    function _transferWithReference(address _to, uint _value, string _reference, address _sender)
        transferAllowed(_sender)
        internal
        returns(bool)
    {
        return super._transferWithReference(_to, _value, _reference, _sender);
    }

    function _transferToICAPWithReference(bytes32 _icap, uint _value, string _reference, address _sender)
        transferAllowed(_sender)
        internal
        returns(bool)
    {
        return super._transferToICAPWithReference(_icap, _value, _reference, _sender);
    }

    function _transferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender)
        transferAllowed(_from)
        internal
        returns(bool)
    {
        return super._transferFromWithReference(_from, _to, _value, _reference, _sender);
    }

    function _transferFromToICAPWithReference(address _from, bytes32 _icap, uint _value, string _reference, address _sender)
        transferAllowed(_from)
        internal
        returns(bool)
    {
        return super._transferFromToICAPWithReference(_from, _icap, _value, _reference, _sender);
    }
}

/**
 * @title EToken2 Asset with per holder timelock implementation contract.
 *
 * Locks can only be set by the sender with &#39;locker&#39; role and to the
 * recepients who allowed to set locks on them.
 *
 * Once the lock is set, it cannot be changed, and all the tokens on the locked address
 * will become available when unlock date comes.
 */
contract AssetWithTimelock is AssetWithAmbi {
    mapping(address => uint) public unlockDate;

    event Error(bytes32 message);
    event TimelockAllowed(address addr);
    event Timelocked(address addr, uint unlockDate);

    function isTimelockAllowed(address _address) public view returns(bool) {
        return unlockDate[_address] > 0;
    }

    function isTimelocked(address _address) public view returns(bool) {
        return unlockDate[_address] > 1;
    }

    function isTransferAllowed(address _from) public view returns(bool) {
        return now > unlockDate[_from];
    }

    function allowTimelock() public returns(bool) {
        _allowTimelock(_sender());
        return true;
    }

    function _allowTimelock(address _address) internal {
        if (isTimelockAllowed(_address)) {
            return;
        }
        unlockDate[_address] = 1;
        emit TimelockAllowed(_address);
    }

    function () public {
        require(msg.data.length == 0);
        allowTimelock();
    }

    function transferWithLock(address _to, uint _value, uint _unlockDate) onlyRole(&#39;locker&#39;) public returns(bool) {
        address sender = _sender();
        if (_unlockDate == 0) {
            emit Error(&#39;Invalid unlock date&#39;);
            return false;
        }
        if (not(isTimelockAllowed(_to))) {
            emit Error(&#39;Timelock not allowed&#39;);
            return false;
        }
        if (not(_transferWithReference(_to, _value, &#39;Timelocked&#39;, sender))) {
            emit Error(&#39;Failed transfer with lock&#39;);
            return false;
        }
        if (not(isTimelocked(_to))) {
            unlockDate[_to] = _unlockDate;
            emit Timelocked(_to, _unlockDate);
        }
        return true;
    }

    modifier onlyUnlocked(address _from) {
        if (not(isTransferAllowed(_from))) {
            emit Error(&#39;Sender is timelocked&#39;);
            return;
        }
        _;
    }

    function not(bool _condition) internal pure returns(bool) {
        return !_condition;
    }

    // Transfers
    function _transferWithReference(address _to, uint _value, string _reference, address _sender)
        onlyUnlocked(_sender)
        internal
        returns(bool)
    {
        if (_value == 0) {
            _allowTimelock(_sender);
            return true;
        }
        return super._transferWithReference(_to, _value, _reference, _sender);
    }

    function _transferToICAPWithReference(bytes32 _icap, uint _value, string _reference, address _sender)
        onlyUnlocked(_sender)
        internal
        returns(bool)
    {
        return super._transferToICAPWithReference(_icap, _value, _reference, _sender);
    }

    function _transferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender)
        onlyUnlocked(_from)
        internal
        returns(bool)
    {
        return super._transferFromWithReference(_from, _to, _value, _reference, _sender);
    }

    function _transferFromToICAPWithReference(address _from, bytes32 _icap, uint _value, string _reference, address _sender)
        onlyUnlocked(_from)
        internal
        returns(bool)
    {
        return super._transferFromToICAPWithReference(_from, _icap, _value, _reference, _sender);
    }
}

contract AssetWithTimelockAndWhitelist is AssetWithWhitelist, AssetWithTimelock {}