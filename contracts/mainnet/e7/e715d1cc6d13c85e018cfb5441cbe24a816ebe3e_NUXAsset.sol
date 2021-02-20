/**
 *Submitted for verification at Etherscan.io on 2021-02-20
*/

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts\AssetInterface.sol

pragma solidity 0.5.8;


contract AssetInterface {
    function _performTransferWithReference(
        address _to,
        uint _value,
        string memory _reference,
        address _sender)
    public returns(bool);

    function _performTransferToICAPWithReference(
        bytes32 _icap,
        uint _value,
        string memory _reference,
        address _sender)
    public returns(bool);

    function _performApprove(address _spender, uint _value, address _sender)
    public returns(bool);

    function _performTransferFromWithReference(
        address _from,
        address _to,
        uint _value,
        string memory _reference,
        address _sender)
    public returns(bool);

    function _performTransferFromToICAPWithReference(
        address _from,
        bytes32 _icap,
        uint _value,
        string memory _reference,
        address _sender)
    public returns(bool);

    function _performGeneric(bytes memory, address) public payable {
        revert();
    }
}

// File: contracts\ERC20Interface.sol

pragma solidity 0.5.8;


contract ERC20Interface {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);

    function totalSupply() public view returns(uint256 supply);
    function balanceOf(address _owner) public view returns(uint256 balance);
    // solhint-disable-next-line no-simple-event-func-name
    function transfer(address _to, uint256 _value) public returns(bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success);
    function approve(address _spender, uint256 _value) public returns(bool success);
    function allowance(address _owner, address _spender) public view returns(uint256 remaining);

    // function symbol() constant returns(string);
    function decimals() public view returns(uint8);
    // function name() constant returns(string);
}

// File: contracts\AssetProxyInterface.sol

pragma solidity 0.5.8;



contract AssetProxyInterface is ERC20Interface {
    function _forwardApprove(address _spender, uint _value, address _sender)
    public returns(bool);

    function _forwardTransferFromWithReference(
        address _from,
        address _to,
        uint _value,
        string memory _reference,
        address _sender)
    public returns(bool);

    function _forwardTransferFromToICAPWithReference(
        address _from,
        bytes32 _icap,
        uint _value,
        string memory _reference,
        address _sender)
    public returns(bool);

    function recoverTokens(ERC20Interface _asset, address _receiver, uint _value)
    public returns(bool);

    function etoken2() external view returns(address); // To be replaced by the implicit getter;

    // To be replaced by the implicit getter;
    function etoken2Symbol() external view returns(bytes32);
}

// File: @orderbook\smart-contracts-common\contracts\Bytes32.sol

pragma solidity 0.5.8;


contract Bytes32 {
    function _bytes32(string memory _input) internal pure returns(bytes32 result) {
        assembly {
            result := mload(add(_input, 32))
        }
    }
}

// File: @orderbook\smart-contracts-common\contracts\ReturnData.sol

pragma solidity 0.5.8;


contract ReturnData {
    function _returnReturnData(bool _success) internal pure {
        assembly {
            let returndatastart := 0
            returndatacopy(returndatastart, 0, returndatasize)
            switch _success case 0 { revert(returndatastart, returndatasize) }
                default { return(returndatastart, returndatasize) }
        }
    }

    function _assemblyCall(address _destination, uint _value, bytes memory _data)
    internal returns(bool success) {
        assembly {
            success := call(gas, _destination, _value, add(_data, 32), mload(_data), 0, 0)
        }
    }
}

// File: contracts\Asset.sol

pragma solidity 0.5.8;






/**
 * @title EToken2 Asset implementation contract.
 *
 * Basic asset implementation contract, without any additional logic.
 * Every other asset implementation contracts should derive from this one.
 * Receives calls from the proxy, and calls back immediately without arguments modification.
 *
 * Note: all the non constant functions return false instead of throwing in case if state change
 * didn't happen yet.
 */
contract Asset is AssetInterface, Bytes32, ReturnData {
    // Assigned asset proxy contract, immutable.
    AssetProxyInterface public proxy;

    /**
     * Only assigned proxy is allowed to call.
     */
    modifier onlyProxy() {
        if (address(proxy) == msg.sender) {
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
    function init(AssetProxyInterface _proxy) public returns(bool) {
        if (address(proxy) != address(0)) {
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
    function _performTransferWithReference(
        address _to,
        uint _value,
        string memory _reference,
        address _sender)
    public onlyProxy() returns(bool) {
        if (isICAP(_to)) {
            return _transferToICAPWithReference(
                bytes20(_to), _value, _reference, _sender);
        }
        return _transferWithReference(_to, _value, _reference, _sender);
    }

    /**
     * Calls back without modifications.
     *
     * @return success.
     * @dev function is virtual, and meant to be overridden.
     */
    function _transferWithReference(
        address _to,
        uint _value,
        string memory _reference,
        address _sender)
    internal returns(bool) {
        return proxy._forwardTransferFromWithReference(
            _sender, _to, _value, _reference, _sender);
    }

    /**
     * Passes execution into virtual function.
     *
     * Can only be called by assigned asset proxy.
     *
     * @return success.
     * @dev function is final, and must not be overridden.
     */
    function _performTransferToICAPWithReference(
        bytes32 _icap,
        uint _value,
        string memory _reference,
        address _sender)
    public onlyProxy() returns(bool) {
        return _transferToICAPWithReference(_icap, _value, _reference, _sender);
    }

    /**
     * Calls back without modifications.
     *
     * @return success.
     * @dev function is virtual, and meant to be overridden.
     */
    function _transferToICAPWithReference(
        bytes32 _icap,
        uint _value,
        string memory _reference,
        address _sender)
    internal returns(bool) {
        return proxy._forwardTransferFromToICAPWithReference(
            _sender, _icap, _value, _reference, _sender);
    }

    /**
     * Passes execution into virtual function.
     *
     * Can only be called by assigned asset proxy.
     *
     * @return success.
     * @dev function is final, and must not be overridden.
     */
    function _performTransferFromWithReference(
        address _from,
        address _to,
        uint _value,
        string memory _reference,
        address _sender)
    public onlyProxy() returns(bool) {
        if (isICAP(_to)) {
            return _transferFromToICAPWithReference(
                _from, bytes20(_to), _value, _reference, _sender);
        }
        return _transferFromWithReference(_from, _to, _value, _reference, _sender);
    }

    /**
     * Calls back without modifications.
     *
     * @return success.
     * @dev function is virtual, and meant to be overridden.
     */
    function _transferFromWithReference(
        address _from,
        address _to,
        uint _value,
        string memory _reference,
        address _sender)
    internal returns(bool) {
        return proxy._forwardTransferFromWithReference(
            _from, _to, _value, _reference, _sender);
    }

    /**
     * Passes execution into virtual function.
     *
     * Can only be called by assigned asset proxy.
     *
     * @return success.
     * @dev function is final, and must not be overridden.
     */
    function _performTransferFromToICAPWithReference(
        address _from,
        bytes32 _icap,
        uint _value,
        string memory _reference,
        address _sender)
    public onlyProxy() returns(bool) {
        return _transferFromToICAPWithReference(
            _from, _icap, _value, _reference, _sender);
    }

    /**
     * Calls back without modifications.
     *
     * @return success.
     * @dev function is virtual, and meant to be overridden.
     */
    function _transferFromToICAPWithReference(
        address _from,
        bytes32 _icap,
        uint _value,
        string memory _reference,
        address _sender)
    internal returns(bool) {
        return proxy._forwardTransferFromToICAPWithReference(
            _from, _icap, _value, _reference, _sender);
    }

    /**
     * Passes execution into virtual function.
     *
     * Can only be called by assigned asset proxy.
     *
     * @return success.
     * @dev function is final, and must not be overridden.
     */
    function _performApprove(address _spender, uint _value, address _sender)
    public onlyProxy() returns(bool) {
        return _approve(_spender, _value, _sender);
    }

    /**
     * Calls back without modifications.
     *
     * @return success.
     * @dev function is virtual, and meant to be overridden.
     */
    function _approve(address _spender, uint _value, address _sender)
    internal returns(bool) {
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
    function _performGeneric(bytes memory _data, address _sender)
    public payable onlyProxy() {
        _generic(_data, msg.value, _sender);
    }

    modifier onlyMe() {
        if (address(this) == msg.sender) {
            _;
        }
    }

    // Most probably the following should never be redefined in child contracts.
    address public genericSender;

    function _generic(bytes memory _data, uint _value, address _msgSender) internal {
        // Restrict reentrancy.
        require(genericSender == address(0));
        genericSender = _msgSender;
        bool success = _assemblyCall(address(this), _value, _data);
        delete genericSender;
        _returnReturnData(success);
    }

    // Decsendants should use _sender() instead of msg.sender to properly process proxied calls.
    function _sender() internal view returns(address) {
        return address(this) == msg.sender ? genericSender : msg.sender;
    }

    // Interface functions to allow specifying ICAP addresses as strings.
    function transferToICAP(string memory _icap, uint _value) public returns(bool) {
        return transferToICAPWithReference(_icap, _value, '');
    }

    function transferToICAPWithReference(string memory _icap, uint _value, string memory _reference)
    public returns(bool) {
        return _transferToICAPWithReference(
            _bytes32(_icap), _value, _reference, _sender());
    }

    function transferFromToICAP(address _from, string memory _icap, uint _value)
    public returns(bool) {
        return transferFromToICAPWithReference(_from, _icap, _value, '');
    }

    function transferFromToICAPWithReference(
        address _from,
        string memory _icap,
        uint _value,
        string memory _reference)
    public returns(bool) {
        return _transferFromToICAPWithReference(
            _from, _bytes32(_icap), _value, _reference, _sender());
    }

    function isICAP(address _address) public pure returns(bool) {
        bytes20 a = bytes20(_address);
        if (a[0] != 'X' || a[1] != 'E') {
            return false;
        }
        if (uint8(a[2]) < 48 || uint8(a[2]) > 57 || uint8(a[3]) < 48 || uint8(a[3]) > 57) {
            return false;
        }
        for (uint i = 4; i < 20; i++) {
            uint char = uint8(a[i]);
            if (char < 48 || char > 90 || (char > 57 && char < 65)) {
                return false;
            }
        }
        return true;
    }
}

// File: contracts\Ambi2Enabled.sol

pragma solidity 0.5.8;


contract Ambi2 {
    function claimFor(address _address, address _owner) public returns(bool);
    function hasRole(address _from, bytes32 _role, address _to) public view returns(bool);
    function isOwner(address _node, address _owner) public view returns(bool);
}


contract Ambi2Enabled {
    Ambi2 public ambi2;

    modifier onlyRole(bytes32 _role) {
        if (address(ambi2) != address(0) && ambi2.hasRole(address(this), _role, msg.sender)) {
            _;
        }
    }

    // Perform only after claiming the node, or claim in the same tx.
    function setupAmbi2(Ambi2 _ambi2) public returns(bool) {
        if (address(ambi2) != address(0)) {
            return false;
        }

        ambi2 = _ambi2;
        return true;
    }
}

// File: contracts\Ambi2EnabledFull.sol

pragma solidity 0.5.8;



contract Ambi2EnabledFull is Ambi2Enabled {
    // Setup and claim atomically.
    function setupAmbi2(Ambi2 _ambi2) public returns(bool) {
        if (address(ambi2) != address(0)) {
            return false;
        }
        if (!_ambi2.claimFor(address(this), msg.sender) &&
            !_ambi2.isOwner(address(this), msg.sender)) {
            return false;
        }

        ambi2 = _ambi2;
        return true;
    }
}

// File: contracts\AssetWithAmbi.sol

pragma solidity 0.5.8;




contract AssetWithAmbi is Asset, Ambi2EnabledFull {
    modifier onlyRole(bytes32 _role) {
        if (address(ambi2) != address(0) && (ambi2.hasRole(address(this), _role, _sender()))) {
            _;
        }
    }
}

// File: contracts\AssetWithWhitelist.sol

pragma solidity 0.5.8;



interface INUXAsset {
    function availableBalanceOf(address _holder) external view returns(uint);
    function scheduleReleaseStart() external;
    function transferLock(address _to, uint _value) external;
}

contract NUXConstants {
    uint constant NUX = 10**18;
}

contract Readable {
    function since(uint _timestamp) internal view returns(uint) {
        if (not(passed(_timestamp))) {
            return 0;
        }
        return block.timestamp - _timestamp;
    }

    function passed(uint _timestamp) internal view returns(bool) {
        return _timestamp < block.timestamp;
    }

    function not(bool _condition) internal pure returns(bool) {
        return !_condition;
    }
}

library ExtraMath {
    function toUInt64(uint _a) internal pure returns(uint64) {
        require(_a <= uint64(-1), 'uint64 overflow');
        return uint64(_a);
    }

    function toUInt128(uint _a) internal pure returns(uint128) {
        require(_a <= uint128(-1), 'uint128 overflow');
        return uint128(_a);
    }
}

contract EToken2Interface {
    function revokeAsset(bytes32 _symbol, uint _value) public returns(bool);
}

contract NUXAsset is AssetWithAmbi, NUXConstants, Readable {
    using SafeMath for uint;
    using ExtraMath for uint;

    uint public constant PRESALE_RELEASE_PERIOD = 760 days; // ~25 months
    uint64 constant UNSET = uint64(-1);

    struct ReleaseConfig {
        uint64 preSale;
        uint64 publicSale;
        uint64 publicSaleReleasePeriod;
    }

    ReleaseConfig private _releaseConfig = ReleaseConfig(UNSET, UNSET, UNSET);
    
    struct Lock {
        uint128 preSale;
        uint128 publicSale;
    }

    mapping(address => Lock) private _locked;

    event PreSaleLockTransfer(address _from, address _to, uint _value);
    event PublicSaleLockTransfer(address _from, address _to, uint _value);
    event PreSaleReleaseScheduled(uint _releaseStart);
    event PublicSaleReleaseScheduled(uint _releaseStart, uint _releasePeriod);
    event Unlocked(address _holder);

    modifier onlyRole(bytes32 _role) {
        require(address(ambi2) != address(0) && (ambi2.hasRole(address(this), _role, _sender())),
            'Access denied');
        _;
    }

    modifier validateAvailableBalance(address _sender, uint _value) {
        require(availableBalanceOf(_sender) >= _value, 'Insufficient available balance');
        _;
    }

    modifier validateAllowance(address _from, address _spender, uint _value) {
        require(proxy.allowance(_from, _spender) >= _value, 'Insufficient allowance');
        _;
    }

    function _migrate(address _holder, uint _lock) private {
        uint128 preSale = uint128(_lock >> 128);
        uint128 publicSale = uint128(_lock);
        _locked[_holder] = Lock(preSale, publicSale);
        if (preSale > 0) {
            emit PreSaleLockTransfer(address(0), _holder, preSale);
        }
        if (publicSale > 0) {
            emit PublicSaleLockTransfer(address(0), _holder, publicSale);
        }
    }

    function migrate(address[] calldata _holders, uint[] calldata _locks) external onlyRole('admin') {
        require(not(passed(_releaseConfig.preSale)), 'Migration finished');
        uint len = _holders.length;
        require(len == _locks.length, 'Length mismatch');
        for (uint i = 0; i < len; i++) {
            _migrate(_holders[i], _locks[i]);
        }
    }

    function releaseConfig() public view returns(uint, uint, uint) {
        ReleaseConfig memory config = _releaseConfig;
        return (config.preSale, config.publicSale, config.publicSaleReleasePeriod);
    }

    function locked(address _holder) public view returns(uint, uint) {
        Lock memory lock = _locked[_holder];
        return (lock.preSale, lock.publicSale);
    }

    function _calcualteLocked(uint _lock, uint _releaseStart, uint _releasePeriod) private view returns(uint) {
        uint released = (_lock.mul(since(_releaseStart))) / _releasePeriod;
        if (_lock <= released) {
            return 0;
        }
        return _lock - released;
    }

    function availableBalanceOf(address _holder) public view returns(uint) {
        uint totalBalance = proxy.balanceOf(_holder);
        uint preSaleLock;
        uint publicSaleLock;
        (preSaleLock, publicSaleLock) = locked(_holder);
        uint preSaleReleaseStart;
        uint publicSaleReleaseStart;
        uint publicSaleReleasePeriod;
        (preSaleReleaseStart, publicSaleReleaseStart, publicSaleReleasePeriod) = releaseConfig();
        preSaleLock = _calcualteLocked(preSaleLock, preSaleReleaseStart, PRESALE_RELEASE_PERIOD);
        publicSaleLock = _calcualteLocked(publicSaleLock, publicSaleReleaseStart, publicSaleReleasePeriod);
        uint stillLocked = preSaleLock.add(publicSaleLock);
        if (totalBalance <= stillLocked) {
            return 0;
        }
        return totalBalance - stillLocked;
    }

    function preSaleScheduleReleaseStart(uint _releaseStart) public onlyRole('admin') {
        require(_releaseConfig.preSale == UNSET, 'Already scheduled');
        uint64 releaseStart = _releaseStart.toUInt64();
        _releaseConfig.preSale = releaseStart;
        emit PreSaleReleaseScheduled(releaseStart);
    }

    function publicSaleScheduleReleaseStart(uint _releaseStart, uint _releasePeriod) public onlyRole('admin') {
        require(_releaseConfig.publicSale == UNSET, 'Already scheduled');
        require(_releaseConfig.publicSaleReleasePeriod == UNSET, 'Already scheduled');
        _releaseConfig.publicSale = _releaseStart.toUInt64();
        _releaseConfig.publicSaleReleasePeriod = _releasePeriod.toUInt64();
        emit PublicSaleReleaseScheduled(_releaseStart, _releasePeriod);
    }

    function preSaleTransferLock(address _to, uint _value) public onlyRole('distributor') {
        address _from = _sender();
        uint preSaleLock;
        uint publicSaleLock;
        (preSaleLock, publicSaleLock) = locked(_from);
        require(preSaleLock >= _value, 'Not enough locked');
        require(proxy.balanceOf(_from) >= publicSaleLock.add(preSaleLock), 'Cannot transfer released');
        _locked[_from].preSale = (preSaleLock - _value).toUInt128();
        if (_to == address(0)) {
            _burn(_from, _value);
        } else {
            _locked[_to].preSale = uint(_locked[_to].preSale).add(_value).toUInt128();
            require(super._transferWithReference(_to, _value, '', _from), 'Transfer failed');
        }
        emit PreSaleLockTransfer(_from, _to, _value);
    }

    function publicSaleTransferLock(address _to, uint _value) public onlyRole('distributor') {
        address _from = _sender();
        uint preSaleLock;
        uint publicSaleLock;
        (preSaleLock, publicSaleLock) = locked(_from);
        require(publicSaleLock >= _value, 'Not enough locked');
        require(proxy.balanceOf(_from) >= publicSaleLock.add(preSaleLock), 'Cannot transfer released');
        _locked[_from].publicSale = (publicSaleLock - _value).toUInt128();
        if (_to == address(0)) {
            _burn(_from, _value);
        } else {
            _locked[_to].publicSale = uint(_locked[_to].publicSale).add(_value).toUInt128();
            require(super._transferWithReference(_to, _value, '', _from), 'Transfer failed');
        }
        emit PublicSaleLockTransfer(_from, _to, _value);
    }

    function unlock(address _holder) public onlyRole('unlocker') {
        delete _locked[_holder];
        emit Unlocked(_holder);
    }

    function preSaleTransferLockFrom(address _from, address _to, uint _value)
    public
    onlyRole('distributor')
    validateAllowance(_from, _sender(), _value) {
        uint preSaleLock;
        uint publicSaleLock;
        (preSaleLock, publicSaleLock) = locked(_from);
        require(preSaleLock >= _value, 'Not enough locked');
        require(proxy.balanceOf(_from) >= publicSaleLock.add(preSaleLock), 'Cannot transfer released');
        _locked[_from].preSale = (preSaleLock - _value).toUInt128();
        _locked[_to].preSale = uint(_locked[_to].preSale).add(_value).toUInt128();
        require(super._transferFromWithReference(_from, _to, _value, '', _sender()), 'Transfer failed');
        emit PreSaleLockTransfer(_from, _to, _value);
    }

    function publicSaleTransferLockFrom(address _from, address _to, uint _value)
    public
    onlyRole('distributor')
    validateAllowance(_from, _sender(), _value) {
        uint preSaleLock;
        uint publicSaleLock;
        (preSaleLock, publicSaleLock) = locked(_from);
        require(publicSaleLock >= _value, 'Not enough locked');
        require(proxy.balanceOf(_from) >= publicSaleLock.add(preSaleLock), 'Cannot transfer released');
        _locked[_from].publicSale = (publicSaleLock - _value).toUInt128();
        _locked[_to].publicSale = uint(_locked[_to].publicSale).add(_value).toUInt128();
        require(super._transferFromWithReference(_from, _to, _value, '', _sender()), 'Transfer failed');
        emit PublicSaleLockTransfer(_from, _to, _value);
    }

    function _burn(address _from, uint _value) private {
        require(super._transferWithReference(address(this), _value, '', _from), 'Burn transfer failed');
        require(EToken2Interface(proxy.etoken2()).revokeAsset(proxy.etoken2Symbol(), _value), 'Burn failed');
    }

    function _transferWithReference(
        address _to,
        uint _value,
        string memory _reference,
        address _sender)
    internal validateAvailableBalance(_sender, _value) returns(bool) {
        return super._transferWithReference(_to, _value, _reference, _sender);
    }

    function _transferFromWithReference(
        address _from,
        address _to,
        uint _value,
        string memory _reference,
        address _sender)
    internal
    validateAvailableBalance(_from, _value)
    validateAllowance(_from, _sender, _value)
    returns(bool) {
        return super._transferFromWithReference(_from, _to, _value, _reference, _sender);
    }

    function _transferToICAPWithReference(
        bytes32 _icap,
        uint _value,
        string memory _reference,
        address _sender)
    internal validateAvailableBalance(_sender, _value) returns(bool) {
        return super._transferToICAPWithReference(_icap, _value, _reference, _sender);
    }

    function _transferFromToICAPWithReference(
        address _from,
        bytes32 _icap,
        uint _value,
        string memory _reference,
        address _sender)
    internal
    validateAvailableBalance(_from, _value)
    validateAllowance(_from, _sender, _value)
    returns(bool) {
        return super._transferFromToICAPWithReference(_from, _icap, _value, _reference, _sender);
    }
}