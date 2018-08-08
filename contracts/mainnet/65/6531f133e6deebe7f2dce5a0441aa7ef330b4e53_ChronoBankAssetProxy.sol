pragma solidity ^0.4.4;

contract Owned {
    address public contractOwner;
    address public pendingContractOwner;

    function Owned() {
        contractOwner = msg.sender;
    }

    modifier onlyContractOwner() {
        if (contractOwner == msg.sender) {
            _;
        }
    }

    /**
     * Prepares ownership pass.
     *
     * Can only be called by current owner.
     *
     * @param _to address of the next owner.
     *
     * @return success.
     */
    function changeContractOwnership(address _to) onlyContractOwner() returns(bool) {
        pendingContractOwner = _to;
        return true;
    }

    /**
     * Finalize ownership pass.
     *
     * Can only be called by pending owner.
     *
     * @return success.
     */
    function claimContractOwnership() returns(bool) {
        if (pendingContractOwner != msg.sender) {
            return false;
        }
        contractOwner = pendingContractOwner;
        delete pendingContractOwner;
        return true;
    }
}


contract Emitter {
    function emitTransfer(address _from, address _to, bytes32 _symbol, uint _value, string _reference);
    function emitIssue(bytes32 _symbol, uint _value, address _by);
    function emitRevoke(bytes32 _symbol, uint _value, address _by);
    function emitOwnershipChange(address _from, address _to, bytes32 _symbol);
    function emitApprove(address _from, address _spender, bytes32 _symbol, uint _value);
    function emitRecovery(address _from, address _to, address _by);
    function emitError(bytes32 _message);
}

contract Proxy {
    function emitTransfer(address _from, address _to, uint _value);
    function emitApprove(address _from, address _spender, uint _value);
}

/**
 * @title ChronoBank Platform.
 *
 * The official ChronoBank assets platform powering TIME and LHT tokens, and possibly
 * other unknown tokens needed later.
 * Platform uses EventsHistory contract to keep events, so that in case it needs to be redeployed
 * at some point, all the events keep appearing at the same place.
 *
 * Every asset is meant to be used through a proxy contract. Only one proxy contract have access
 * rights for a particular asset.
 *
 * Features: transfers, allowances, supply adjustments, lost wallet access recovery.
 *
 * Note: all the non constant functions return false instead of throwing in case if state change
 * didn&#39;t happen yet.
 */
contract ChronoBankPlatform is Owned {
    // Structure of a particular asset.
    struct Asset {
        uint owner;                       // Asset&#39;s owner id.
        uint totalSupply;                 // Asset&#39;s total supply.
        string name;                      // Asset&#39;s name, for information purposes.
        string description;               // Asset&#39;s description, for information purposes.
        bool isReissuable;                // Indicates if asset have dynamic of fixed supply.
        uint8 baseUnit;                   // Proposed number of decimals.
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
    function setupEventsHistory(address _eventsHistory) onlyContractOwner() returns(bool) {
        if (address(eventsHistory) != 0) {
            return false;
        }
        eventsHistory = Emitter(_eventsHistory);
        return true;
    }

    /**
     * Emits Error if called not by asset owner.
     */
    modifier onlyOwner(bytes32 _symbol) {
        if (isOwner(msg.sender, _symbol)) {
            _;
        } else {
            _error("Only owner: access denied");
        }
    }

    /**
     * Emits Error if called not by asset proxy.
     */
    modifier onlyProxy(bytes32 _symbol) {
        if (proxies[_symbol] == msg.sender) {
            _;
        } else {
            _error("Only proxy: access denied");
        }
    }

    /**
     * Emits Error if _from doesn&#39;t trust _to.
     */
    modifier checkTrust(address _from, address _to) {
        if (isTrusted(_from, _to)) {
            _;
        } else {
            _error("Only trusted: access denied");
        }
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
     * Returns asset balance for a particular holder.
     *
     * @param _holder holder address.
     * @param _symbol asset symbol.
     *
     * @return holder balance.
     */
    function balanceOf(address _holder, bytes32 _symbol) constant returns(uint) {
        return _balanceOf(getHolderId(_holder), _symbol);
    }

    /**
     * Returns asset balance for a particular holder id.
     *
     * @param _holderId holder id.
     * @param _symbol asset symbol.
     *
     * @return holder balance.
     */
    function _balanceOf(uint _holderId, bytes32 _symbol) constant returns(uint) {
        return assets[_symbol].wallets[_holderId].balance;
    }

    /**
     * Returns current address for a particular holder id.
     *
     * @param _holderId holder id.
     *
     * @return holder address.
     */
    function _address(uint _holderId) constant returns(address) {
        return holders[_holderId].addr;
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
    function setProxy(address _address, bytes32 _symbol) onlyContractOwner() returns(bool) {
        if (proxies[_symbol] != 0x0) {
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
    function _transfer(uint _fromId, uint _toId, uint _value, bytes32 _symbol, string _reference, uint _senderId) internal returns(bool) {
        // Should not allow to send to oneself.
        if (_fromId == _toId) {
            _error("Cannot send to oneself");
            return false;
        }
        // Should have positive value.
        if (_value == 0) {
            _error("Cannot send 0 value");
            return false;
        }
        // Should have enough balance.
        if (_balanceOf(_fromId, _symbol) < _value) {
            _error("Insufficient balance");
            return false;
        }
        // Should have enough allowance.
        if (_fromId != _senderId && _allowance(_fromId, _senderId, _symbol) < _value) {
            _error("Not enough allowance");
            return false;
        }
        _transferDirect(_fromId, _toId, _value, _symbol);
        // Adjust allowance.
        if (_fromId != _senderId) {
            assets[_symbol].wallets[_fromId].allowance[_senderId] -= _value;
        }
        // Internal Out Of Gas/Throw: revert this transaction too;
        // Call Stack Depth Limit reached: n/a after HF 4;
        // Recursive Call: safe, all changes already made.
        eventsHistory.emitTransfer(_address(_fromId), _address(_toId), _symbol, _value, _reference);
        _proxyTransferEvent(_fromId, _toId, _value, _symbol);
        return true;
    }

    /**
     * Transfers asset balance between holders wallets.
     *
     * Can only be called by asset proxy.
     *
     * @param _to holder address to give to.
     * @param _value amount to transfer.
     * @param _symbol asset symbol.
     * @param _reference transfer comment to be included in a Transfer event.
     * @param _sender transfer initiator address.
     *
     * @return success.
     */
    function proxyTransferWithReference(address _to, uint _value, bytes32 _symbol, string _reference, address _sender) onlyProxy(_symbol) returns(bool) {
        return _transfer(getHolderId(_sender), _createHolderId(_to), _value, _symbol, _reference, getHolderId(_sender));
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
            // Call Stack Depth Limit reached: n/a after HF 4;
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
     * @param _symbol asset symbol.
     * @param _value amount of tokens to issue immediately.
     * @param _name name of the asset.
     * @param _description description for the asset.
     * @param _baseUnit number of decimals.
     * @param _isReissuable dynamic or fixed supply.
     *
     * @return success.
     */
    function issueAsset(bytes32 _symbol, uint _value, string _name, string _description, uint8 _baseUnit, bool _isReissuable) onlyContractOwner() returns(bool) {
        // Should have positive value if supply is going to be fixed.
        if (_value == 0 && !_isReissuable) {
            _error("Cannot issue 0 value fixed asset");
            return false;
        }
        // Should not be issued yet.
        if (isCreated(_symbol)) {
            _error("Asset already issued");
            return false;
        }
        uint holderId = _createHolderId(msg.sender);

        assets[_symbol] = Asset(holderId, _value, _name, _description, _isReissuable, _baseUnit);
        assets[_symbol].wallets[holderId].balance = _value;
        // Internal Out Of Gas/Throw: revert this transaction too;
        // Call Stack Depth Limit reached: n/a after HF 4;
        // Recursive Call: safe, all changes already made.
        eventsHistory.emitIssue(_symbol, _value, _address(holderId));
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
            _error("Cannot reissue 0 value");
            return false;
        }
        Asset asset = assets[_symbol];
        // Should have dynamic supply.
        if (!asset.isReissuable) {
            _error("Cannot reissue fixed asset");
            return false;
        }
        // Resulting total supply should not overflow.
        if (asset.totalSupply + _value < asset.totalSupply) {
            _error("Total supply overflow");
            return false;
        }
        uint holderId = getHolderId(msg.sender);
        asset.wallets[holderId].balance += _value;
        asset.totalSupply += _value;
        // Internal Out Of Gas/Throw: revert this transaction too;
        // Call Stack Depth Limit reached: n/a after HF 4;
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
    function revokeAsset(bytes32 _symbol, uint _value) returns(bool) {
        // Should have positive value.
        if (_value == 0) {
            _error("Cannot revoke 0 value");
            return false;
        }
        Asset asset = assets[_symbol];
        uint holderId = getHolderId(msg.sender);
        // Should have enough tokens.
        if (asset.wallets[holderId].balance < _value) {
            _error("Not enough tokens to revoke");
            return false;
        }
        asset.wallets[holderId].balance -= _value;
        asset.totalSupply -= _value;
        // Internal Out Of Gas/Throw: revert this transaction too;
        // Call Stack Depth Limit reached: n/a after HF 4;
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
    function changeOwnership(bytes32 _symbol, address _newOwner) onlyOwner(_symbol) returns(bool) {
        Asset asset = assets[_symbol];
        uint newOwnerId = _createHolderId(_newOwner);
        // Should pass ownership to another holder.
        if (asset.owner == newOwnerId) {
            _error("Cannot pass ownership to oneself");
            return false;
        }
        address oldOwner = _address(asset.owner);
        asset.owner = newOwnerId;
        // Internal Out Of Gas/Throw: revert this transaction too;
        // Call Stack Depth Limit reached: n/a after HF 4;
        // Recursive Call: safe, all changes already made.
        eventsHistory.emitOwnershipChange(oldOwner, _address(newOwnerId), _symbol);
        return true;
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
            _error("Cannot trust to oneself");
            return false;
        }
        // Should trust to yet untrusted.
        if (isTrusted(msg.sender, _to)) {
            _error("Already trusted");
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
     * This function logic is actually more of an addAccess(uint _holderId, address _to).
     * It grants another address access to recovery subject wallets.
     * Can only be called by trustee of recovery subject.
     *
     * @param _from holder address to recover from.
     * @param _to address to grant access to.
     *
     * @return success.
     */
    function recover(address _from, address _to) checkTrust(_from, msg.sender) returns(bool) {
        // Should recover to previously unused address.
        if (getHolderId(_to) != 0) {
            _error("Should recover to new address");
            return false;
        }
        // We take current holder address because it might not equal _from.
        // It is possible to recover from any old holder address, but event should have the current one.
        address from = holders[getHolderId(_from)].addr;
        holders[getHolderId(_from)].addr = _to;
        holderIndex[_to] = getHolderId(_from);
        // Internal Out Of Gas/Throw: revert this transaction too;
        // Call Stack Depth Limit reached: revert this transaction too;
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
    function _approve(uint _spenderId, uint _value, bytes32 _symbol, uint _senderId) internal returns(bool) {
        // Asset should exist.
        if (!isCreated(_symbol)) {
            _error("Asset is not issued");
            return false;
        }
        // Should allow to another holder.
        if (_senderId == _spenderId) {
            _error("Cannot approve to oneself");
            return false;
        }
        assets[_symbol].wallets[_senderId].allowance[_spenderId] = _value;
        // Internal Out Of Gas/Throw: revert this transaction too;
        // Call Stack Depth Limit reached: revert this transaction too;
        // Recursive Call: safe, all changes already made.
        eventsHistory.emitApprove(_address(_senderId), _address(_spenderId), _symbol, _value);
        if (proxies[_symbol] != 0x0) {
            // Internal Out Of Gas/Throw: revert this transaction too;
            // Call Stack Depth Limit reached: n/a after HF 4;
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

contract ChronoBankAsset {
    function __transferWithReference(address _to, uint _value, string _reference, address _sender) returns(bool);
    function __transferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) returns(bool);
    function __approve(address _spender, uint _value, address _sender) returns(bool);
    function __process(bytes _data, address _sender) payable {
        throw;
    }
}

contract ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);

    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}

contract ChronoBankAssetProxy is ERC20 {
    // Assigned platform, immutable.
    ChronoBankPlatform public chronoBankPlatform;

    // Assigned symbol, immutable.
    bytes32 smbl;

    // Assigned name, immutable.
    string public name;

    string public symbol;

    /**
     * Sets platform address, assigns symbol and name.
     *
     * Can be set only once.
     *
     * @param _chronoBankPlatform platform contract address.
     * @param _symbol assigned symbol.
     * @param _name assigned name.
     *
     * @return success.
     */
    function init(ChronoBankPlatform _chronoBankPlatform, string _symbol, string _name) returns(bool) {
        if (address(chronoBankPlatform) != 0x0) {
            return false;
        }
        chronoBankPlatform = _chronoBankPlatform;
        symbol = _symbol;
        smbl = stringToBytes32(_symbol);
        name = _name;
        return true;
    }

function stringToBytes32(string memory source) returns (bytes32 result) {
    assembly {
        result := mload(add(source, 32))
    }
}

    /**
     * Only platform is allowed to call.
     */
    modifier onlyChronoBankPlatform() {
        if (msg.sender == address(chronoBankPlatform)) {
            _;
        }
    }

    /**
     * Only current asset owner is allowed to call.
     */
    modifier onlyAssetOwner() {
        if (chronoBankPlatform.isOwner(msg.sender, smbl)) {
            _;
        }
    }

    /**
     * Returns asset implementation contract for current caller.
     *
     * @return asset implementation contract.
     */
    function _getAsset() internal returns(ChronoBankAsset) {
        return ChronoBankAsset(getVersionFor(msg.sender));
    }

    /**
     * Returns asset total supply.
     *
     * @return asset total supply.
     */
    function totalSupply() constant returns(uint) {
        return chronoBankPlatform.totalSupply(smbl);
    }

    /**
     * Returns asset balance for a particular holder.
     *
     * @param _owner holder address.
     *
     * @return holder balance.
     */
    function balanceOf(address _owner) constant returns(uint) {
        return chronoBankPlatform.balanceOf(_owner, smbl);
    }

    /**
     * Returns asset allowance from one holder to another.
     *
     * @param _from holder that allowed spending.
     * @param _spender holder that is allowed to spend.
     *
     * @return holder to spender allowance.
     */
    function allowance(address _from, address _spender) constant returns(uint) {
        return chronoBankPlatform.allowance(_from, _spender, smbl);
    }

    /**
     * Returns asset decimals.
     *
     * @return asset decimals.
     */
    function decimals() constant returns(uint8) {
        return chronoBankPlatform.baseUnit(smbl);
    }

    /**
     * Transfers asset balance from the caller to specified receiver.
     *
     * @param _to holder address to give to.
     * @param _value amount to transfer.
     *
     * @return success.
     */
    function transfer(address _to, uint _value) returns(bool) {
        return _transferWithReference(_to, _value, "");
    }

    /**
     * Transfers asset balance from the caller to specified receiver adding specified comment.
     *
     * @param _to holder address to give to.
     * @param _value amount to transfer.
     * @param _reference transfer comment to be included in a platform&#39;s Transfer event.
     *
     * @return success.
     */
    function transferWithReference(address _to, uint _value, string _reference) returns(bool) {
        return _transferWithReference(_to, _value, _reference);
    }

    /**
     * Resolves asset implementation contract for the caller and forwards there arguments along with
     * the caller address.
     *
     * @return success.
     */
    function _transferWithReference(address _to, uint _value, string _reference) internal returns(bool) {
        return _getAsset().__transferWithReference(_to, _value, _reference, msg.sender);
    }

    /**
     * Performs transfer call on the platform by the name of specified sender.
     *
     * Can only be called by asset implementation contract assigned to sender.
     *
     * @param _to holder address to give to.
     * @param _value amount to transfer.
     * @param _reference transfer comment to be included in a platform&#39;s Transfer event.
     * @param _sender initial caller.
     *
     * @return success.
     */
    function __transferWithReference(address _to, uint _value, string _reference, address _sender) onlyAccess(_sender) returns(bool) {
        return chronoBankPlatform.proxyTransferWithReference(_to, _value, smbl, _reference, _sender);
    }

    /**
     * Prforms allowance transfer of asset balance between holders.
     *
     * @param _from holder address to take from.
     * @param _to holder address to give to.
     * @param _value amount to transfer.
     *
     * @return success.
     */
    function transferFrom(address _from, address _to, uint _value) returns(bool) {
        return _transferFromWithReference(_from, _to, _value, "");
    }

    /**
     * Prforms allowance transfer of asset balance between holders adding specified comment.
     *
     * @param _from holder address to take from.
     * @param _to holder address to give to.
     * @param _value amount to transfer.
     * @param _reference transfer comment to be included in a platform&#39;s Transfer event.
     *
     * @return success.
     */
    function transferFromWithReference(address _from, address _to, uint _value, string _reference) returns(bool) {
        return _transferFromWithReference(_from, _to, _value, _reference);
    }

    /**
     * Resolves asset implementation contract for the caller and forwards there arguments along with
     * the caller address.
     *
     * @return success.
     */
    function _transferFromWithReference(address _from, address _to, uint _value, string _reference) internal returns(bool) {
        return _getAsset().__transferFromWithReference(_from, _to, _value, _reference, msg.sender);
    }

    /**
     * Performs allowance transfer call on the platform by the name of specified sender.
     *
     * Can only be called by asset implementation contract assigned to sender.
     *
     * @param _from holder address to take from.
     * @param _to holder address to give to.
     * @param _value amount to transfer.
     * @param _reference transfer comment to be included in a platform&#39;s Transfer event.
     * @param _sender initial caller.
     *
     * @return success.
     */
    function __transferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) onlyAccess(_sender) returns(bool) {
        return chronoBankPlatform.proxyTransferFromWithReference(_from, _to, _value, smbl, _reference, _sender);
    }

    /**
     * Sets asset spending allowance for a specified spender.
     *
     * @param _spender holder address to set allowance to.
     * @param _value amount to allow.
     *
     * @return success.
     */
    function approve(address _spender, uint _value) returns(bool) {
        return _approve(_spender, _value);
    }

    /**
     * Resolves asset implementation contract for the caller and forwards there arguments along with
     * the caller address.
     *
     * @return success.
     */
    function _approve(address _spender, uint _value) internal returns(bool) {
        return _getAsset().__approve(_spender, _value, msg.sender);
    }

    /**
     * Performs allowance setting call on the platform by the name of specified sender.
     *
     * Can only be called by asset implementation contract assigned to sender.
     *
     * @param _spender holder address to set allowance to.
     * @param _value amount to allow.
     * @param _sender initial caller.
     *
     * @return success.
     */
    function __approve(address _spender, uint _value, address _sender) onlyAccess(_sender) returns(bool) {
        return chronoBankPlatform.proxyApprove(_spender, _value, smbl, _sender);
    }

    /**
     * Emits ERC20 Transfer event on this contract.
     *
     * Can only be, and, called by assigned platform when asset transfer happens.
     */
    function emitTransfer(address _from, address _to, uint _value) onlyChronoBankPlatform() {
        Transfer(_from, _to, _value);
    }

    /**
     * Emits ERC20 Approval event on this contract.
     *
     * Can only be, and, called by assigned platform when asset allowance set happens.
     */
    function emitApprove(address _from, address _spender, uint _value) onlyChronoBankPlatform() {
        Approval(_from, _spender, _value);
    }

    /**
     * Resolves asset implementation contract for the caller and forwards there transaction data,
     * along with the value. This allows for proxy interface growth.
     */
    function () payable {
        _getAsset().__process.value(msg.value)(msg.data, msg.sender);
    }

    /**
     * Indicates an upgrade freeze-time start, and the next asset implementation contract.
     */
    event UpgradeProposal(address newVersion);

    // Current asset implementation contract address.
    address latestVersion;

    // Proposed next asset implementation contract address.
    address pendingVersion;

    // Upgrade freeze-time start.
    uint pendingVersionTimestamp;

    // Timespan for users to review the new implementation and make decision.
    uint constant UPGRADE_FREEZE_TIME = 3 days;

    // Asset implementation contract address that user decided to stick with.
    // 0x0 means that user uses latest version.
    mapping(address => address) userOptOutVersion;

    /**
     * Only asset implementation contract assigned to sender is allowed to call.
     */
    modifier onlyAccess(address _sender) {
        if (getVersionFor(_sender) == msg.sender) {
            _;
        }
    }

    /**
     * Returns asset implementation contract address assigned to sender.
     *
     * @param _sender sender address.
     *
     * @return asset implementation contract address.
     */
    function getVersionFor(address _sender) constant returns(address) {
        return userOptOutVersion[_sender] == 0 ? latestVersion : userOptOutVersion[_sender];
    }

    /**
     * Returns current asset implementation contract address.
     *
     * @return asset implementation contract address.
     */
    function getLatestVersion() constant returns(address) {
        return latestVersion;
    }

    /**
     * Returns proposed next asset implementation contract address.
     *
     * @return asset implementation contract address.
     */
    function getPendingVersion() constant returns(address) {
        return pendingVersion;
    }

    /**
     * Returns upgrade freeze-time start.
     *
     * @return freeze-time start.
     */
    function getPendingVersionTimestamp() constant returns(uint) {
        return pendingVersionTimestamp;
    }

    /**
     * Propose next asset implementation contract address.
     *
     * Can only be called by current asset owner.
     *
     * Note: freeze-time should not be applied for the initial setup.
     *
     * @param _newVersion asset implementation contract address.
     *
     * @return success.
     */
    function proposeUpgrade(address _newVersion) onlyAssetOwner() returns(bool) {
        // Should not already be in the upgrading process.
        if (pendingVersion != 0x0) {
            return false;
        }
        // New version address should be other than 0x0.
        if (_newVersion == 0x0) {
            return false;
        }
        // Don&#39;t apply freeze-time for the initial setup.
        if (latestVersion == 0x0) {
            latestVersion = _newVersion;
            return true;
        }
        pendingVersion = _newVersion;
        pendingVersionTimestamp = now;
        UpgradeProposal(_newVersion);
        return true;
    }

    /**
     * Cancel the pending upgrade process.
     *
     * Can only be called by current asset owner.
     *
     * @return success.
     */
    function purgeUpgrade() onlyAssetOwner() returns(bool) {
        if (pendingVersion == 0x0) {
            return false;
        }
        delete pendingVersion;
        delete pendingVersionTimestamp;
        return true;
    }

    /**
     * Finalize an upgrade process setting new asset implementation contract address.
     *
     * Can only be called after an upgrade freeze-time.
     *
     * @return success.
     */
    function commitUpgrade() returns(bool) {
        if (pendingVersion == 0x0) {
            return false;
        }
        if (pendingVersionTimestamp + UPGRADE_FREEZE_TIME > now) {
            return false;
        }
        latestVersion = pendingVersion;
        delete pendingVersion;
        delete pendingVersionTimestamp;
        return true;
    }

    /**
     * Disagree with proposed upgrade, and stick with current asset implementation
     * until further explicit agreement to upgrade.
     *
     * @return success.
     */
    function optOut() returns(bool) {
        if (userOptOutVersion[msg.sender] != 0x0) {
            return false;
        }
        userOptOutVersion[msg.sender] = latestVersion;
        return true;
    }

    /**
     * Implicitly agree to upgrade to current and future asset implementation upgrades,
     * until further explicit disagreement.
     *
     * @return success.
     */
    function optIn() returns(bool) {
        delete userOptOutVersion[msg.sender];
        return true;
    }
}