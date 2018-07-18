// This software is a subject to Ambisafe License Agreement.
// No use or distribution is allowed without written permission from Ambisafe.
// https://ambisafe.com/terms.pdf

pragma solidity 0.4.8;

contract Ambi2 {
    function claimFor(address _address, address _owner) returns(bool);
    function hasRole(address _from, bytes32 _role, address _to) constant returns(bool);
    function isOwner(address _node, address _owner) constant returns(bool);
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

contract RegistryICAPInterface {
    function parse(bytes32 _icap) constant returns(address, bytes32, bool);
    function institutions(bytes32 _institution) constant returns(address);
}

contract Cosigner {
    function consumeOperation(bytes32 _opHash, uint _required) returns(bool);
}

contract Emitter {
    function emitTransfer(address _from, address _to, bytes32 _symbol, uint _value, string _reference);
    function emitTransferToICAP(address _from, address _to, bytes32 _icap, uint _value, string _reference);
    function emitIssue(bytes32 _symbol, uint _value, address _by);
    function emitRevoke(bytes32 _symbol, uint _value, address _by);
    function emitOwnershipChange(address _from, address _to, bytes32 _symbol);
    function emitApprove(address _from, address _spender, bytes32 _symbol, uint _value);
    function emitRecovery(address _from, address _to, address _by);
    function emitError(bytes32 _message);
    function emitChange(bytes32 _symbol);
}

contract Proxy {
    function emitTransfer(address _from, address _to, uint _value);
    function emitApprove(address _from, address _spender, uint _value);
}

/**
 * @title EToken2.
 *
 * The official Ambisafe assets platform powering all kinds of tokens.
 * EToken2 uses EventsHistory contract to keep events, so that in case it needs to be redeployed
 * at some point, all the events keep appearing at the same place.
 *
 * Every asset is meant to be used through a proxy contract. Only one proxy contract have access
 * rights for a particular asset.
 *
 * Features: assets issuance, transfers, allowances, supply adjustments, lost wallet access recovery.
 *           cosignature check, ICAP.
 *
 * Note: all the non constant functions return false instead of throwing in case if state change
 * didn&#39;t happen yet.
 */
contract EToken2 is Ambi2EnabledFull {
    mapping(bytes32 => bool) switches;

    function isEnabled(bytes32 _switch) constant returns(bool) {
        return switches[_switch];
    }

    function enableSwitch(bytes32 _switch) onlyRole(&#39;issuance&#39;) returns(bool) {
        switches[_switch] = true;
        return true;
    }

    modifier checkEnabledSwitch(bytes32 _switch) {
        if (!isEnabled(_switch)) {
            _error(&#39;Feature is disabled&#39;);
        } else {
            _;
        }
    }

    enum Features { Issue, TransferWithReference, Revoke, ChangeOwnership, Allowances, ICAP }

    // Structure of a particular asset.
    struct Asset {
        uint owner;                       // Asset&#39;s owner id.
        uint totalSupply;                 // Asset&#39;s total supply.
        string name;                      // Asset&#39;s name, for information purposes.
        string description;               // Asset&#39;s description, for information purposes.
        bool isReissuable;                // Indicates if asset have dynamic of fixed supply.
        uint8 baseUnit;                   // Proposed number of decimals.
        bool isLocked;                    // Are changes still allowed.
        mapping(uint => Wallet) wallets;  // Holders wallets.
    }

    // Structure of an asset holder wallet for particular asset.
    struct Wallet {
        uint balance;
        mapping(uint => uint) allowance;
    }

    // Structure of an asset holder.
    struct Holder {
        address addr;                    // Current address of the holder.
        Cosigner cosigner;               // Cosigner contract for 2FA and recovery.
        mapping(address => bool) trust;  // Addresses that are trusted with recovery proocedure.
    }

    // Iterable mapping pattern is used for holders.
    uint public holdersCount;
    mapping(uint => Holder) public holders;

    // This is an access address mapping. Many addresses may have access to a single holder.
    mapping(address => uint) holderIndex;

    // Asset symbol to asset mapping.
    mapping(bytes32 => Asset) public assets;

    // Asset symbol to asset proxy mapping.
    mapping(bytes32 => address) public proxies;

    // ICAP registry contract.
    RegistryICAPInterface public registryICAP;

    // Should use interface of the emitter, but address of events history.
    Emitter public eventsHistory;

    /**
     * Emits Error event with specified error message.
     *
     * Should only be used if no state changes happened.
     *
     * @param _message error message.
     */
    function _error(bytes32 _message) internal {
        eventsHistory.emitError(_message);
    }

    /**
     * Sets EventsHstory contract address.
     *
     * Can be set only once, and only by contract owner.
     *
     * @param _eventsHistory EventsHistory contract address.
     *
     * @return success.
     */
    function setupEventsHistory(Emitter _eventsHistory) onlyRole(&#39;setup&#39;) returns(bool) {
        if (address(eventsHistory) != 0) {
            return false;
        }
        eventsHistory = _eventsHistory;
        return true;
    }

    /**
     * Sets RegistryICAP contract address.
     *
     * Can be set only once, and only by contract owner.
     *
     * @param _registryICAP RegistryICAP contract address.
     *
     * @return success.
     */
    function setupRegistryICAP(RegistryICAPInterface _registryICAP) onlyRole(&#39;setup&#39;) returns(bool) {
        if (address(registryICAP) != 0) {
            return false;
        }
        registryICAP = _registryICAP;
        return true;
    }

    /**
     * Emits Error if called not by asset owner.
     */
    modifier onlyOwner(bytes32 _symbol) {
        if (_isSignedOwner(_symbol)) {
            _;
        } else {
            _error(&#39;Only owner: access denied&#39;);
        }
    }

    /**
     * Emits Error if called not by asset proxy.
     */
    modifier onlyProxy(bytes32 _symbol) {
        if (_isProxy(_symbol)) {
            _;
        } else {
            _error(&#39;Only proxy: access denied&#39;);
        }
    }

    /**
     * Emits Error if _from doesn&#39;t trust _to.
     */
    modifier checkTrust(address _from, address _to) {
        if (isTrusted(_from, _to)) {
            _;
        } else {
            _error(&#39;Only trusted: access denied&#39;);
        }
    }

    function _isSignedOwner(bytes32 _symbol) internal checkSigned(getHolderId(msg.sender), 1) returns(bool) {
        return isOwner(msg.sender, _symbol);
    }

    /**
     * Check asset existance.
     *
     * @param _symbol asset symbol.
     *
     * @return asset existance.
     */
    function isCreated(bytes32 _symbol) constant returns(bool) {
        return assets[_symbol].owner != 0;
    }

    function isLocked(bytes32 _symbol) constant returns(bool) {
        return assets[_symbol].isLocked;
    }

    /**
     * Returns asset decimals.
     *
     * @param _symbol asset symbol.
     *
     * @return asset decimals.
     */
    function baseUnit(bytes32 _symbol) constant returns(uint8) {
        return assets[_symbol].baseUnit;
    }

    /**
     * Returns asset name.
     *
     * @param _symbol asset symbol.
     *
     * @return asset name.
     */
    function name(bytes32 _symbol) constant returns(string) {
        return assets[_symbol].name;
    }

    /**
     * Returns asset description.
     *
     * @param _symbol asset symbol.
     *
     * @return asset description.
     */
    function description(bytes32 _symbol) constant returns(string) {
        return assets[_symbol].description;
    }

    /**
     * Returns asset reissuability.
     *
     * @param _symbol asset symbol.
     *
     * @return asset reissuability.
     */
    function isReissuable(bytes32 _symbol) constant returns(bool) {
        return assets[_symbol].isReissuable;
    }

    /**
     * Returns asset owner address.
     *
     * @param _symbol asset symbol.
     *
     * @return asset owner address.
     */
    function owner(bytes32 _symbol) constant returns(address) {
        return holders[assets[_symbol].owner].addr;
    }

    /**
     * Check if specified address has asset owner rights.
     *
     * @param _owner address to check.
     * @param _symbol asset symbol.
     *
     * @return owner rights availability.
     */
    function isOwner(address _owner, bytes32 _symbol) constant returns(bool) {
        return isCreated(_symbol) && (assets[_symbol].owner == getHolderId(_owner));
    }

    /**
     * Returns asset total supply.
     *
     * @param _symbol asset symbol.
     *
     * @return asset total supply.
     */
    function totalSupply(bytes32 _symbol) constant returns(uint) {
        return assets[_symbol].totalSupply;
    }

    /**
     * Returns asset balance for current address of a particular holder.
     *
     * @param _holder holder address.
     * @param _symbol asset symbol.
     *
     * @return holder balance.
     */
    function balanceOf(address _holder, bytes32 _symbol) constant returns(uint) {
        uint holderId = getHolderId(_holder);
        return holders[holderId].addr == _holder ? _balanceOf(holderId, _symbol) : 0;
    }

    /**
     * Returns asset balance for a particular holder id.
     *
     * @param _holderId holder id.
     * @param _symbol asset symbol.
     *
     * @return holder balance.
     */
    function _balanceOf(uint _holderId, bytes32 _symbol) constant internal returns(uint) {
        return assets[_symbol].wallets[_holderId].balance;
    }

    /**
     * Returns current address for a particular holder id.
     *
     * @param _holderId holder id.
     *
     * @return holder address.
     */
    function _address(uint _holderId) constant internal returns(address) {
        return holders[_holderId].addr;
    }

    function _isProxy(bytes32 _symbol) constant internal returns(bool) {
        return proxies[_symbol] == msg.sender;
    }

    /**
     * Sets Proxy contract address for a particular asset.
     *
     * Can be set only once for each asset, and only by contract owner.
     *
     * @param _address Proxy contract address.
     * @param _symbol asset symbol.
     *
     * @return success.
     */
    function setProxy(address _address, bytes32 _symbol) onlyOwner(_symbol) returns(bool) {
        if (proxies[_symbol] != 0x0 && assets[_symbol].isLocked) {
            return false;
        }
        proxies[_symbol] = _address;
        return true;
    }

    /**
     * Transfers asset balance between holders wallets.
     *
     * @param _fromId holder id to take from.
     * @param _toId holder id to give to.
     * @param _value amount to transfer.
     * @param _symbol asset symbol.
     */
    function _transferDirect(uint _fromId, uint _toId, uint _value, bytes32 _symbol) internal {
        assets[_symbol].wallets[_fromId].balance -= _value;
        assets[_symbol].wallets[_toId].balance += _value;
    }

    /**
     * Transfers asset balance between holders wallets.
     *
     * Performs sanity checks and takes care of allowances adjustment.
     *
     * @param _fromId holder id to take from.
     * @param _toId holder id to give to.
     * @param _value amount to transfer.
     * @param _symbol asset symbol.
     * @param _reference transfer comment to be included in a Transfer event.
     * @param _senderId transfer initiator holder id.
     *
     * @return success.
     */
    function _transfer(uint _fromId, uint _toId, uint _value, bytes32 _symbol, string _reference, uint _senderId) internal checkSigned(_senderId, 1) returns(bool) {
        // Should not allow to send to oneself.
        if (_fromId == _toId) {
            _error(&#39;Cannot send to oneself&#39;);
            return false;
        }
        // Should have positive value.
        if (_value == 0) {
            _error(&#39;Cannot send 0 value&#39;);
            return false;
        }
        // Should have enough balance.
        if (_balanceOf(_fromId, _symbol) < _value) {
            _error(&#39;Insufficient balance&#39;);
            return false;
        }
        // Should allow references.
        if (bytes(_reference).length > 0 && !isEnabled(sha3(_symbol, Features.TransferWithReference))) {
            _error(&#39;References feature is disabled&#39;);
            return false;
        }
        // Should have enough allowance.
        if (_fromId != _senderId && _allowance(_fromId, _senderId, _symbol) < _value) {
            _error(&#39;Not enough allowance&#39;);
            return false;
        }
        // Adjust allowance.
        if (_fromId != _senderId) {
            assets[_symbol].wallets[_fromId].allowance[_senderId] -= _value;
        }
        _transferDirect(_fromId, _toId, _value, _symbol);
        // Internal Out Of Gas/Throw: revert this transaction too;
        // Recursive Call: safe, all changes already made.
        eventsHistory.emitTransfer(_address(_fromId), _address(_toId), _symbol, _value, _reference);
        _proxyTransferEvent(_fromId, _toId, _value, _symbol);
        return true;
    }

    // Feature and proxy checks done internally due to unknown symbol when the function is called.
    function _transferToICAP(uint _fromId, bytes32 _icap, uint _value, string _reference, uint _senderId) internal returns(bool) {
        var (to, symbol, success) = registryICAP.parse(_icap);
        if (!success) {
            _error(&#39;ICAP is not registered&#39;);
            return false;
        }
        if (!isEnabled(sha3(symbol, Features.ICAP))) {
            _error(&#39;ICAP feature is disabled&#39;);
            return false;
        }
        if (!_isProxy(symbol)) {
            _error(&#39;Only proxy: access denied&#39;);
            return false;
        }
        uint toId = _createHolderId(to);
        if (!_transfer(_fromId, toId, _value, symbol, _reference, _senderId)) {
            return false;
        }
        // Internal Out Of Gas/Throw: revert this transaction too;
        // Recursive Call: safe, all changes already made.
        eventsHistory.emitTransferToICAP(_address(_fromId), _address(toId), _icap, _value, _reference);
        return true;
    }

    function proxyTransferFromToICAPWithReference(address _from, bytes32 _icap, uint _value, string _reference, address _sender) returns(bool) {
        return _transferToICAP(getHolderId(_from), _icap, _value, _reference, getHolderId(_sender));
    }

    /**
     * Ask asset Proxy contract to emit ERC20 compliant Transfer event.
     *
     * @param _fromId holder id to take from.
     * @param _toId holder id to give to.
     * @param _value amount to transfer.
     * @param _symbol asset symbol.
     */
    function _proxyTransferEvent(uint _fromId, uint _toId, uint _value, bytes32 _symbol) internal {
        if (proxies[_symbol] != 0x0) {
            // Internal Out Of Gas/Throw: revert this transaction too;
            // Recursive Call: safe, all changes already made.
            Proxy(proxies[_symbol]).emitTransfer(_address(_fromId), _address(_toId), _value);
        }
    }

    /**
     * Returns holder id for the specified address.
     *
     * @param _holder holder address.
     *
     * @return holder id.
     */
    function getHolderId(address _holder) constant returns(uint) {
        return holderIndex[_holder];
    }

    /**
     * Returns holder id for the specified address, creates it if needed.
     *
     * @param _holder holder address.
     *
     * @return holder id.
     */
    function _createHolderId(address _holder) internal returns(uint) {
        uint holderId = holderIndex[_holder];
        if (holderId == 0) {
            holderId = ++holdersCount;
            holders[holderId].addr = _holder;
            holderIndex[_holder] = holderId;
        }
        return holderId;
    }

    /**
     * Issues new asset token on the platform.
     *
     * Tokens issued with this call go straight to contract owner.
     * Each symbol can be issued only once, and only by contract owner.
     *
     * _isReissuable is included in checkEnabledSwitch because it should be
     * explicitly allowed before issuing new asset.
     *
     * @param _symbol asset symbol.
     * @param _value amount of tokens to issue immediately.
     * @param _name name of the asset.
     * @param _description description for the asset.
     * @param _baseUnit number of decimals.
     * @param _isReissuable dynamic or fixed supply.
     *
     * @return success.
     */
    function issueAsset(bytes32 _symbol, uint _value, string _name, string _description, uint8 _baseUnit, bool _isReissuable) checkEnabledSwitch(sha3(_symbol, _isReissuable, Features.Issue)) returns(bool) {
        // Should have positive value if supply is going to be fixed.
        if (_value == 0 && !_isReissuable) {
            _error(&#39;Cannot issue 0 value fixed asset&#39;);
            return false;
        }
        // Should not be issued yet.
        if (isCreated(_symbol)) {
            _error(&#39;Asset already issued&#39;);
            return false;
        }
        uint holderId = _createHolderId(msg.sender);

        assets[_symbol] = Asset(holderId, _value, _name, _description, _isReissuable, _baseUnit, false);
        assets[_symbol].wallets[holderId].balance = _value;
        // Internal Out Of Gas/Throw: revert this transaction too;
        // Recursive Call: safe, all changes already made.
        eventsHistory.emitIssue(_symbol, _value, _address(holderId));
        return true;
    }

    function changeAsset(bytes32 _symbol, string _name, string _description, uint8 _baseUnit) onlyOwner(_symbol) returns(bool) {
        if (isLocked(_symbol)) {
            _error(&#39;Asset is locked&#39;);
            return false;
        }
        assets[_symbol].name = _name;
        assets[_symbol].description = _description;
        assets[_symbol].baseUnit = _baseUnit;
        eventsHistory.emitChange(_symbol);
        return true;
    }

    function lockAsset(bytes32 _symbol) onlyOwner(_symbol) returns(bool) {
        if (isLocked(_symbol)) {
            _error(&#39;Asset is locked&#39;);
            return false;
        }
        assets[_symbol].isLocked = true;
        return true;
    }

    /**
     * Issues additional asset tokens if the asset have dynamic supply.
     *
     * Tokens issued with this call go straight to asset owner.
     * Can only be called by asset owner.
     *
     * @param _symbol asset symbol.
     * @param _value amount of additional tokens to issue.
     *
     * @return success.
     */
    function reissueAsset(bytes32 _symbol, uint _value) onlyOwner(_symbol) returns(bool) {
        // Should have positive value.
        if (_value == 0) {
            _error(&#39;Cannot reissue 0 value&#39;);
            return false;
        }
        Asset asset = assets[_symbol];
        // Should have dynamic supply.
        if (!asset.isReissuable) {
            _error(&#39;Cannot reissue fixed asset&#39;);
            return false;
        }
        // Resulting total supply should not overflow.
        if (asset.totalSupply + _value < asset.totalSupply) {
            _error(&#39;Total supply overflow&#39;);
            return false;
        }
        uint holderId = getHolderId(msg.sender);
        asset.wallets[holderId].balance += _value;
        asset.totalSupply += _value;
        // Internal Out Of Gas/Throw: revert this transaction too;
        // Recursive Call: safe, all changes already made.
        eventsHistory.emitIssue(_symbol, _value, _address(holderId));
        _proxyTransferEvent(0, holderId, _value, _symbol);
        return true;
    }

    /**
     * Destroys specified amount of senders asset tokens.
     *
     * @param _symbol asset symbol.
     * @param _value amount of tokens to destroy.
     *
     * @return success.
     */
    function revokeAsset(bytes32 _symbol, uint _value) checkEnabledSwitch(sha3(_symbol, Features.Revoke)) checkSigned(getHolderId(msg.sender), 1) returns(bool) {
        // Should have positive value.
        if (_value == 0) {
            _error(&#39;Cannot revoke 0 value&#39;);
            return false;
        }
        Asset asset = assets[_symbol];
        uint holderId = getHolderId(msg.sender);
        // Should have enough tokens.
        if (asset.wallets[holderId].balance < _value) {
            _error(&#39;Not enough tokens to revoke&#39;);
            return false;
        }
        asset.wallets[holderId].balance -= _value;
        asset.totalSupply -= _value;
        // Internal Out Of Gas/Throw: revert this transaction too;
        // Recursive Call: safe, all changes already made.
        eventsHistory.emitRevoke(_symbol, _value, _address(holderId));
        _proxyTransferEvent(holderId, 0, _value, _symbol);
        return true;
    }

    /**
     * Passes asset ownership to specified address.
     *
     * Only ownership is changed, balances are not touched.
     * Can only be called by asset owner.
     *
     * @param _symbol asset symbol.
     * @param _newOwner address to become a new owner.
     *
     * @return success.
     */
    function changeOwnership(bytes32 _symbol, address _newOwner) checkEnabledSwitch(sha3(_symbol, Features.ChangeOwnership)) onlyOwner(_symbol) returns(bool) {
        Asset asset = assets[_symbol];
        uint newOwnerId = _createHolderId(_newOwner);
        // Should pass ownership to another holder.
        if (asset.owner == newOwnerId) {
            _error(&#39;Cannot pass ownership to oneself&#39;);
            return false;
        }
        address oldOwner = _address(asset.owner);
        asset.owner = newOwnerId;
        // Internal Out Of Gas/Throw: revert this transaction too;
        // Recursive Call: safe, all changes already made.
        eventsHistory.emitOwnershipChange(oldOwner, _address(newOwnerId), _symbol);
        return true;
    }

    function setCosignerAddress(Cosigner _cosigner) checkSigned(_createHolderId(msg.sender), 1) returns(bool) {
        if (!_checkSigned(_cosigner, getHolderId(msg.sender), 1)) {
            _error(&#39;Invalid cosigner&#39;);
            return false;
        }
        holders[_createHolderId(msg.sender)].cosigner = _cosigner;
        return true;
    }

    function isCosignerSet(uint _holderId) constant returns(bool) {
        return address(holders[_holderId].cosigner) != 0x0;
    }

    function _checkSigned(Cosigner _cosigner, uint _holderId, uint _required) internal returns(bool) {
        return _cosigner.consumeOperation(sha3(msg.data, _holderId), _required);
    }

    modifier checkSigned(uint _holderId, uint _required) {
        if (!isCosignerSet(_holderId) || _checkSigned(holders[_holderId].cosigner, _holderId, _required)) {
            _;
        } else {
            _error(&#39;Cosigner: access denied&#39;);
        }
    }

    /**
     * Check if specified holder trusts an address with recovery procedure.
     *
     * @param _from truster.
     * @param _to trustee.
     *
     * @return trust existance.
     */
    function isTrusted(address _from, address _to) constant returns(bool) {
        return holders[getHolderId(_from)].trust[_to];
    }

    /**
     * Trust an address to perform recovery procedure for the caller.
     *
     * @param _to trustee.
     *
     * @return success.
     */
    function trust(address _to) returns(bool) {
        uint fromId = _createHolderId(msg.sender);
        // Should trust to another address.
        if (fromId == getHolderId(_to)) {
            _error(&#39;Cannot trust to oneself&#39;);
            return false;
        }
        // Should trust to yet untrusted.
        if (isTrusted(msg.sender, _to)) {
            _error(&#39;Already trusted&#39;);
            return false;
        }
        holders[fromId].trust[_to] = true;
        return true;
    }

    /**
     * Revoke trust to perform recovery procedure from an address.
     *
     * @param _to trustee.
     *
     * @return success.
     */
    function distrust(address _to) checkTrust(msg.sender, _to) returns(bool) {
        holders[getHolderId(msg.sender)].trust[_to] = false;
        return true;
    }

    /**
     * Perform recovery procedure.
     *
     * This function logic is actually more of an grantAccess(uint _holderId, address _to).
     * It grants another address access to recovery subject wallets.
     * Can only be called by trustee of recovery subject.
     * If cosigning is enabled, should have atleast 2 confirmations.
     *
     * @dev Deprecated. Backward compatibility.
     *
     * @param _from holder address to recover from.
     * @param _to address to grant access to.
     *
     * @return success.
     */
    function recover(address _from, address _to) checkTrust(_from, msg.sender) returns(bool) {
        return _grantAccess(getHolderId(_from), _to);
    }

    /**
     * Perform recovery procedure.
     *
     * This function logic is actually more of an grantAccess(uint _holderId, address _to).
     * It grants another address access to subject holder wallets.
     * Can only be called if pre-confirmed by atleast 2 cosign oracles.
     *
     * @param _from holder address to recover from.
     * @param _to address to grant access to.
     *
     * @return success.
     */
    function grantAccess(address _from, address _to) returns(bool) {
        if (!isCosignerSet(getHolderId(_from))) {
            _error(&#39;Cosigner not set&#39;);
            return false;
        }
        return _grantAccess(getHolderId(_from), _to);
    }

    function _grantAccess(uint _fromId, address _to) internal checkSigned(_fromId, 2) returns(bool) {
        // Should recover to previously unused address.
        if (getHolderId(_to) != 0) {
            _error(&#39;Should recover to new address&#39;);
            return false;
        }
        // We take current holder address because it might not equal _from.
        // It is possible to recover from any old holder address, but event should have the current one.
        address from = holders[_fromId].addr;
        holders[_fromId].addr = _to;
        holderIndex[_to] = _fromId;
        // Internal Out Of Gas/Throw: revert this transaction too;
        // Recursive Call: safe, all changes already made.
        eventsHistory.emitRecovery(from, _to, msg.sender);
        return true;
    }

    /**
     * Sets asset spending allowance for a specified spender.
     *
     * Note: to revoke allowance, one needs to set allowance to 0.
     *
     * @param _spenderId holder id to set allowance for.
     * @param _value amount to allow.
     * @param _symbol asset symbol.
     * @param _senderId approve initiator holder id.
     *
     * @return success.
     */
    function _approve(uint _spenderId, uint _value, bytes32 _symbol, uint _senderId) internal checkEnabledSwitch(sha3(_symbol, Features.Allowances)) checkSigned(_senderId, 1) returns(bool) {
        // Asset should exist.
        if (!isCreated(_symbol)) {
            _error(&#39;Asset is not issued&#39;);
            return false;
        }
        // Should allow to another holder.
        if (_senderId == _spenderId) {
            _error(&#39;Cannot approve to oneself&#39;);
            return false;
        }
        assets[_symbol].wallets[_senderId].allowance[_spenderId] = _value;
        // Internal Out Of Gas/Throw: revert this transaction too;
        // Recursive Call: safe, all changes already made.
        eventsHistory.emitApprove(_address(_senderId), _address(_spenderId), _symbol, _value);
        if (proxies[_symbol] != 0x0) {
            // Internal Out Of Gas/Throw: revert this transaction too;
            // Recursive Call: safe, all changes already made.
            Proxy(proxies[_symbol]).emitApprove(_address(_senderId), _address(_spenderId), _value);
        }
        return true;
    }

    /**
     * Sets asset spending allowance for a specified spender.
     *
     * Can only be called by asset proxy.
     *
     * @param _spender holder address to set allowance to.
     * @param _value amount to allow.
     * @param _symbol asset symbol.
     * @param _sender approve initiator address.
     *
     * @return success.
     */
    function proxyApprove(address _spender, uint _value, bytes32 _symbol, address _sender) onlyProxy(_symbol) returns(bool) {
        return _approve(_createHolderId(_spender), _value, _symbol, _createHolderId(_sender));
    }

    /**
     * Returns asset allowance from one holder to another.
     *
     * @param _from holder that allowed spending.
     * @param _spender holder that is allowed to spend.
     * @param _symbol asset symbol.
     *
     * @return holder to spender allowance.
     */
    function allowance(address _from, address _spender, bytes32 _symbol) constant returns(uint) {
        return _allowance(getHolderId(_from), getHolderId(_spender), _symbol);
    }

    /**
     * Returns asset allowance from one holder to another.
     *
     * @param _fromId holder id that allowed spending.
     * @param _toId holder id that is allowed to spend.
     * @param _symbol asset symbol.
     *
     * @return holder to spender allowance.
     */
    function _allowance(uint _fromId, uint _toId, bytes32 _symbol) constant internal returns(uint) {
        return assets[_symbol].wallets[_fromId].allowance[_toId];
    }

    /**
     * Prforms allowance transfer of asset balance between holders wallets.
     *
     * Can only be called by asset proxy.
     *
     * @param _from holder address to take from.
     * @param _to holder address to give to.
     * @param _value amount to transfer.
     * @param _symbol asset symbol.
     * @param _reference transfer comment to be included in a Transfer event.
     * @param _sender allowance transfer initiator address.
     *
     * @return success.
     */
    function proxyTransferFromWithReference(address _from, address _to, uint _value, bytes32 _symbol, string _reference, address _sender) onlyProxy(_symbol) returns(bool) {
        return _transfer(getHolderId(_from), _createHolderId(_to), _value, _symbol, _reference, getHolderId(_sender));
    }
}