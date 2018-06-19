pragma solidity ^0.4.11;

// File: contracts/CAVAssetInterface.sol

contract CAVAssetInterface {
    function __transferWithReference(address _to, uint _value, string _reference, address _sender) returns(bool);
    function __transferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) returns(bool);
    function __approve(address _spender, uint _value, address _sender) returns(bool);
    function __process(bytes _data, address _sender) payable {
        revert();
    }
}

// File: contracts/CAVAssetProxyInterface.sol

contract CAVAssetProxy {
    address public platform;
    bytes32 public smbl;
    function __transferWithReference(address _to, uint _value, string _reference, address _sender) returns(bool);
    function __transferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) returns(bool);
    function __approve(address _spender, uint _value, address _sender) returns(bool);
    function getLatestVersion() returns(address);
    function init(address _CAVPlatform, string _symbol, string _name);
    function proposeUpgrade(address _newVersion) returns (bool);
}

// File: contracts/CAVPlatformInterface.sol

contract CAVPlatform {
    mapping(bytes32 => address) public proxies;
    function symbols(uint _idx) public constant returns (bytes32);
    function symbolsCount() public constant returns (uint);

    function name(bytes32 _symbol) returns(string);
    function setProxy(address _address, bytes32 _symbol) returns(uint errorCode);
    function isCreated(bytes32 _symbol) constant returns(bool);
    function isOwner(address _owner, bytes32 _symbol) returns(bool);
    function owner(bytes32 _symbol) constant returns(address);
    function totalSupply(bytes32 _symbol) returns(uint);
    function balanceOf(address _holder, bytes32 _symbol) returns(uint);
    function allowance(address _from, address _spender, bytes32 _symbol) returns(uint);
    function baseUnit(bytes32 _symbol) returns(uint8);
    function proxyTransferWithReference(address _to, uint _value, bytes32 _symbol, string _reference, address _sender) returns(uint errorCode);
    function proxyTransferFromWithReference(address _from, address _to, uint _value, bytes32 _symbol, string _reference, address _sender) returns(uint errorCode);
    function proxyApprove(address _spender, uint _value, bytes32 _symbol, address _sender) returns(uint errorCode);
    function issueAsset(bytes32 _symbol, uint _value, string _name, string _description, uint8 _baseUnit, bool _isReissuable) returns(uint errorCode);
    function issueAsset(bytes32 _symbol, uint _value, string _name, string _description, uint8 _baseUnit, bool _isReissuable, address _account) returns(uint errorCode);
    function reissueAsset(bytes32 _symbol, uint _value) returns(uint errorCode);
    function revokeAsset(bytes32 _symbol, uint _value) returns(uint errorCode);
    function isReissuable(bytes32 _symbol) returns(bool);
    function changeOwnership(bytes32 _symbol, address _newOwner) returns(uint errorCode);
    function hasAssetRights(address _owner, bytes32 _symbol) public view returns (bool);
}

// File: contracts/CAVAsset.sol

/**
 * @title CAV Asset implementation contract.
 *
 * Basic asset implementation contract, without any additional logic.
 * Every other asset implementation contracts should derive from this one.
 * Receives calls from the proxy, and calls back immediatly without arguments modification.
 *
 * Note: all the non constant functions return false instead of throwing in case if state change
 * didn&#39;t happen yet.
 */
contract CAVAsset is CAVAssetInterface {

    // Assigned asset proxy contract, immutable.
    CAVAssetProxy public proxy;

    // banned addresses
    mapping (address => bool) public blacklist;

    // stops asset transfers
    bool public paused = false;

    /**
     * Only assigned proxy is allowed to call.
     */
    modifier onlyProxy() {
        if (proxy == msg.sender) {
            _;
        }
    }
    
    modifier onlyNotPaused(address sender) {
        if (!paused || isAuthorized(sender)) {
            _;
        }
    }

    modifier onlyAcceptable(address _address) {
        if (!blacklist[_address]) {
            _;
        }
    }

    /**
    *  Only assets&#39;s admins are allowed to execute
    */
    modifier onlyAuthorized() {
        if (isAuthorized(msg.sender)) {
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
    function init(CAVAssetProxy _proxy) returns(bool) {
        if (address(proxy) != 0x0) {
            return false;
        }
        proxy = _proxy;
        return true;
    }

    function isAuthorized(address sender) public view returns (bool) {
        CAVPlatform platform = CAVPlatform(proxy.platform());
        return platform.hasAssetRights(sender, proxy.smbl());
    }

    /**
    *  @dev Lifts the ban on transfers for given addresses
    */
    function restrict(address [] _restricted) external onlyAuthorized returns (bool) {
        for (uint i = 0; i < _restricted.length; i++) {
            blacklist[_restricted[i]] = true;
        }
        return true;
    }

    /**
    *  @dev Revokes the ban on transfers for given addresses
    */
    function unrestrict(address [] _unrestricted) external onlyAuthorized returns (bool) {
        for (uint i = 0; i < _unrestricted.length; i++) {
            delete blacklist[_unrestricted[i]];
        }
        return true;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    * Only admin is allowed to execute this method.
    */
    function pause() external onlyAuthorized returns (bool) {
        paused = true;
        return true;
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    * Only admin is allowed to execute this method.
    */
    function unpause() external onlyAuthorized returns (bool) {
        paused = false;
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
    function __transferWithReference(address _to, uint _value, string _reference, address _sender) onlyProxy() returns(bool) {
        return _transferWithReference(_to, _value, _reference, _sender);
    }

    /**
     * Calls back without modifications if an asset is not stopped.
     * Checks whether _from/_sender are not in blacklist.
     *
     * @return success.
     * @dev function is virtual, and meant to be overridden.
     */
    function _transferWithReference(address _to, uint _value, string _reference, address _sender)
    internal
    onlyNotPaused(_sender)
    onlyAcceptable(_to)
    onlyAcceptable(_sender)
    returns(bool)
    {
        return proxy.__transferWithReference(_to, _value, _reference, _sender);
    }

    /**
     * Passes execution into virtual function.
     *
     * Can only be called by assigned asset proxy.
     *
     * @return success.
     * @dev function is final, and must not be overridden.
     */
    function __transferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) onlyProxy() returns(bool) {
        return _transferFromWithReference(_from, _to, _value, _reference, _sender);
    }

    /**
     * Calls back without modifications if an asset is not stopped.
     * Checks whether _from/_sender are not in blacklist.
     *
     * @return success.
     * @dev function is virtual, and meant to be overridden.
     */
    function _transferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender)
    internal
    onlyNotPaused(_sender)
    onlyAcceptable(_from)
    onlyAcceptable(_to)
    onlyAcceptable(_sender)
    returns(bool)
    {
        return proxy.__transferFromWithReference(_from, _to, _value, _reference, _sender);
    }

    /**
     * Passes execution into virtual function.
     *
     * Can only be called by assigned asset proxy.
     *
     * @return success.
     * @dev function is final, and must not be overridden.
     */
    function __approve(address _spender, uint _value, address _sender) onlyProxy() returns(bool) {
        return _approve(_spender, _value, _sender);
    }

    /**
     * Calls back without modifications.
     *
     * @return success.
     * @dev function is virtual, and meant to be overridden.
     */
    function _approve(address _spender, uint _value, address _sender)
    internal
    onlyAcceptable(_spender)
    onlyAcceptable(_sender)
    returns(bool)
    {
        return proxy.__approve(_spender, _value, _sender);
    }
}