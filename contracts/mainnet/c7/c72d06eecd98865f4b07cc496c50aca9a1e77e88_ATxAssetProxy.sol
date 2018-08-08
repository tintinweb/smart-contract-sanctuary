pragma solidity ^0.4.18;

/**
 * @title Owned contract with safe ownership pass.
 *
 * Note: all the non constant functions return false instead of throwing in case if state change
 * didn&#39;t happen yet.
 */
contract Owned {
    /**
     * Contract owner address
     */
    address public contractOwner;

    /**
     * Contract owner address
     */
    address public pendingContractOwner;

    function Owned() {
        contractOwner = msg.sender;
    }

    /**
    * @dev Owner check modifier
    */
    modifier onlyContractOwner() {
        if (contractOwner == msg.sender) {
            _;
        }
    }

    /**
     * @dev Destroy contract and scrub a data
     * @notice Only owner can call it
     */
    function destroy() onlyContractOwner {
        suicide(msg.sender);
    }

    /**
     * Prepares ownership pass.
     *
     * Can only be called by current owner.
     *
     * @param _to address of the next owner. 0x0 is not allowed.
     *
     * @return success.
     */
    function changeContractOwnership(address _to) onlyContractOwner() returns(bool) {
        if (_to  == 0x0) {
            return false;
        }

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

contract ERC20Interface {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);
    string public symbol;

    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}

/**
 * @title Generic owned destroyable contract
 */
contract Object is Owned {
    /**
    *  Common result code. Means everything is fine.
    */
    uint constant OK = 1;
    uint constant OWNED_ACCESS_DENIED_ONLY_CONTRACT_OWNER = 8;

    function withdrawnTokens(address[] tokens, address _to) onlyContractOwner returns(uint) {
        for(uint i=0;i<tokens.length;i++) {
            address token = tokens[i];
            uint balance = ERC20Interface(token).balanceOf(this);
            if(balance != 0)
                ERC20Interface(token).transfer(_to,balance);
        }
        return OK;
    }

    function checkOnlyContractOwner() internal constant returns(uint) {
        if (contractOwner == msg.sender) {
            return OK;
        }

        return OWNED_ACCESS_DENIED_ONLY_CONTRACT_OWNER;
    }
}

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/// @title Provides possibility manage holders? country limits and limits for holders.
contract DataControllerInterface {

    /// @notice Checks user is holder.
    /// @param _address - checking address.
    /// @return `true` if _address is registered holder, `false` otherwise.
    function isHolderAddress(address _address) public view returns (bool);

    function allowance(address _user) public view returns (uint);

    function changeAllowance(address _holder, uint _value) public returns (uint);
}

/// @title ServiceController
///
/// Base implementation
/// Serves for managing service instances
contract ServiceControllerInterface {

    /// @notice Check target address is service
    /// @param _address target address
    /// @return `true` when an address is a service, `false` otherwise
    function isService(address _address) public view returns (bool);
}

contract ATxAssetInterface {

    DataControllerInterface public dataController;
    ServiceControllerInterface public serviceController;

    function __transferWithReference(address _to, uint _value, string _reference, address _sender) public returns (bool);
    function __transferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) public returns (bool);
    function __approve(address _spender, uint _value, address _sender) public returns (bool);
    function __process(bytes /*_data*/, address /*_sender*/) payable public {
        revert();
    }
}

/// @title ServiceAllowance.
///
/// Provides a way to delegate operation allowance decision to a service contract
contract ServiceAllowance {
    function isTransferAllowed(address _from, address _to, address _sender, address _token, uint _value) public view returns (bool);
}


contract ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);
    string public symbol;

    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}


contract Platform {
    mapping(bytes32 => address) public proxies;
    function name(bytes32 _symbol) public view returns (string);
    function setProxy(address _address, bytes32 _symbol) public returns (uint errorCode);
    function isOwner(address _owner, bytes32 _symbol) public view returns (bool);
    function totalSupply(bytes32 _symbol) public view returns (uint);
    function balanceOf(address _holder, bytes32 _symbol) public view returns (uint);
    function allowance(address _from, address _spender, bytes32 _symbol) public view returns (uint);
    function baseUnit(bytes32 _symbol) public view returns (uint8);
    function proxyTransferWithReference(address _to, uint _value, bytes32 _symbol, string _reference, address _sender) public returns (uint errorCode);
    function proxyTransferFromWithReference(address _from, address _to, uint _value, bytes32 _symbol, string _reference, address _sender) public returns (uint errorCode);
    function proxyApprove(address _spender, uint _value, bytes32 _symbol, address _sender) public returns (uint errorCode);
    function issueAsset(bytes32 _symbol, uint _value, string _name, string _description, uint8 _baseUnit, bool _isReissuable) public returns (uint errorCode);
    function reissueAsset(bytes32 _symbol, uint _value) public returns (uint errorCode);
    function revokeAsset(bytes32 _symbol, uint _value) public returns (uint errorCode);
    function isReissuable(bytes32 _symbol) public view returns (bool);
    function changeOwnership(bytes32 _symbol, address _newOwner) public returns (uint errorCode);
}

contract ATxAssetProxy is ERC20, Object, ServiceAllowance {

    using SafeMath for uint;

    /**
     * Indicates an upgrade freeze-time start, and the next asset implementation contract.
     */
    event UpgradeProposal(address newVersion);

    // Current asset implementation contract address.
    address latestVersion;

    // Assigned platform, immutable.
    Platform public platform;

    // Assigned symbol, immutable.
    bytes32 public smbl;

    // Assigned name, immutable.
    string public name;

    /**
     * Only platform is allowed to call.
     */
    modifier onlyPlatform() {
        if (msg.sender == address(platform)) {
            _;
        }
    }

    /**
     * Only current asset owner is allowed to call.
     */
    modifier onlyAssetOwner() {
        if (platform.isOwner(msg.sender, smbl)) {
            _;
        }
    }

    /**
     * Only asset implementation contract assigned to sender is allowed to call.
     */
    modifier onlyAccess(address _sender) {
        if (getLatestVersion() == msg.sender) {
            _;
        }
    }

    /**
     * Resolves asset implementation contract for the caller and forwards there transaction data,
     * along with the value. This allows for proxy interface growth.
     */
    function() public payable {
        _getAsset().__process.value(msg.value)(msg.data, msg.sender);
    }

    /**
     * Sets platform address, assigns symbol and name.
     *
     * Can be set only once.
     *
     * @param _platform platform contract address.
     * @param _symbol assigned symbol.
     * @param _name assigned name.
     *
     * @return success.
     */
    function init(Platform _platform, string _symbol, string _name) public returns (bool) {
        if (address(platform) != 0x0) {
            return false;
        }
        platform = _platform;
        symbol = _symbol;
        smbl = stringToBytes32(_symbol);
        name = _name;
        return true;
    }

    /**
     * Returns asset total supply.
     *
     * @return asset total supply.
     */
    function totalSupply() public view returns (uint) {
        return platform.totalSupply(smbl);
    }

    /**
     * Returns asset balance for a particular holder.
     *
     * @param _owner holder address.
     *
     * @return holder balance.
     */
    function balanceOf(address _owner) public view returns (uint) {
        return platform.balanceOf(_owner, smbl);
    }

    /**
     * Returns asset allowance from one holder to another.
     *
     * @param _from holder that allowed spending.
     * @param _spender holder that is allowed to spend.
     *
     * @return holder to spender allowance.
     */
    function allowance(address _from, address _spender) public view returns (uint) {
        return platform.allowance(_from, _spender, smbl);
    }

    /**
     * Returns asset decimals.
     *
     * @return asset decimals.
     */
    function decimals() public view returns (uint8) {
        return platform.baseUnit(smbl);
    }

    /**
     * Transfers asset balance from the caller to specified receiver.
     *
     * @param _to holder address to give to.
     * @param _value amount to transfer.
     *
     * @return success.
     */
    function transfer(address _to, uint _value) public returns (bool) {
        if (_to != 0x0) {
            return _transferWithReference(_to, _value, "");
        }
        else {
            return false;
        }
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
    function transferWithReference(address _to, uint _value, string _reference) public returns (bool) {
        if (_to != 0x0) {
            return _transferWithReference(_to, _value, _reference);
        }
        else {
            return false;
        }
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
    function __transferWithReference(address _to, uint _value, string _reference, address _sender) public onlyAccess(_sender) returns (bool) {
        return platform.proxyTransferWithReference(_to, _value, smbl, _reference, _sender) == OK;
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
    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        if (_to != 0x0) {
            return _getAsset().__transferFromWithReference(_from, _to, _value, "", msg.sender);
        }
        else {
            return false;
        }
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
    function __transferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) public onlyAccess(_sender) returns (bool) {
        return platform.proxyTransferFromWithReference(_from, _to, _value, smbl, _reference, _sender) == OK;
    }

    /**
     * Sets asset spending allowance for a specified spender.
     *
     * @param _spender holder address to set allowance to.
     * @param _value amount to allow.
     *
     * @return success.
     */
    function approve(address _spender, uint _value) public returns (bool) {
        if (_spender != 0x0) {
            return _getAsset().__approve(_spender, _value, msg.sender);
        }
        else {
            return false;
        }
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
    function __approve(address _spender, uint _value, address _sender) public onlyAccess(_sender) returns (bool) {
        return platform.proxyApprove(_spender, _value, smbl, _sender) == OK;
    }

    /**
     * Emits ERC20 Transfer event on this contract.
     *
     * Can only be, and, called by assigned platform when asset transfer happens.
     */
    function emitTransfer(address _from, address _to, uint _value) public onlyPlatform() {
        Transfer(_from, _to, _value);
    }

    /**
     * Emits ERC20 Approval event on this contract.
     *
     * Can only be, and, called by assigned platform when asset allowance set happens.
     */
    function emitApprove(address _from, address _spender, uint _value) public onlyPlatform() {
        Approval(_from, _spender, _value);
    }

    /**
     * Returns current asset implementation contract address.
     *
     * @return asset implementation contract address.
     */
    function getLatestVersion() public view returns (address) {
        return latestVersion;
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
    function proposeUpgrade(address _newVersion) public onlyAssetOwner returns (bool) {
        // New version address should be other than 0x0.
        if (_newVersion == 0x0) {
            return false;
        }
        
        latestVersion = _newVersion;

        UpgradeProposal(_newVersion); 
        return true;
    }

    function isTransferAllowed(address, address, address, address, uint) public view returns (bool) {
        return true;
    }

    /**
     * Returns asset implementation contract for current caller.
     *
     * @return asset implementation contract.
     */
    function _getAsset() internal view returns (ATxAssetInterface) {
        return ATxAssetInterface(getLatestVersion());
    }

    /**
     * Resolves asset implementation contract for the caller and forwards there arguments along with
     * the caller address.
     *
     * @return success.
     */
    function _transferWithReference(address _to, uint _value, string _reference) internal returns (bool) {
        return _getAsset().__transferWithReference(_to, _value, _reference, msg.sender);
    }

    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }
}