//SourceUnit: pin.sol

pragma solidity >=0.5.0 <0.8.0;

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
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
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
    function sub(uint a, uint b) internal pure returns (uint) {
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
     */
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

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
    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
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
    function div(uint a, uint b) internal pure returns (uint) {
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
     */
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;
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
    function mod(uint a, uint b) internal pure returns (uint) {
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
     */
    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function cbrt(uint n) internal pure returns (uint) {

        if (n == 0) {
            return 0;
        }

       uint[12] memory divisor = [
           uint(1000000),   uint(100000),   uint(10000),    uint(1000),
           uint(100),       uint(10),       uint(9),        uint(7),
           uint(5),         uint(3),        uint(2),        uint(1)
       ];

       uint[12] memory cube_root = [
           uint(100.000000 * 1e6), uint(46.415888  * 1e6), uint(21.544347  * 1e6),
           uint(10.000000  * 1e6), uint(4.641589   * 1e6), uint(2.154434   * 1e6),
           uint(2.080083   * 1e6), uint(1.912931   * 1e6), uint(1.709975   * 1e6),
           uint(1.442249   * 1e6), uint(1.259921   * 1e6), uint(1.000000   * 1e6)
       ];

       uint a = n;
       uint r = 1;

       for ( uint j = 0; j < divisor.length; ) {
           if ( a >= divisor[j] ) {
               r = (r * cube_root[j]) / 1e6;
               a /= divisor[j];
           } else if ( a <= 1) {
               break;
           } else {
               j++;
           }
       }

       return r;

   }
}


interface KDemocracyContract {

}

interface iERC777_1 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function increaseAllowance(address spender, uint addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    /// ERC777 appending new api
    function granularity() external view returns (uint);
    function defaultOperators() external view returns (address[] memory);

    function addDefaultOperators(address owner) external returns (bool);
    function removeDefaultOperators(address owner) external returns (bool);

    function isOperatorFor(address operator, address holder) external view returns (bool);
    function authorizeOperator(address operator) external;
    function revokeOperator(address operator) external;

    function send(address to, uint amount, bytes calldata data) external;
    function operatorSend(address from, address to, uint amount, bytes calldata data, bytes calldata operatorData) external;

    function burn(uint amount, bytes calldata data) external;
    function operatorBurn(address from, uint amount, bytes calldata data, bytes calldata operatorData) external;

    event Sent(address indexed operator, address indexed from, address indexed to, uint amount, bytes data, bytes operatorData);
    event Minted(address indexed operator, address indexed to, uint amount, bytes data, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint amount, bytes data, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed holder);
    event RevokedOperator(address indexed operator, address indexed holder);
}

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  constructor() public {
    owner = msg.sender;
  }

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}

contract KTimeController {

    uint public offsetTime;

    function timestemp() external view returns (uint) {
        return now + offsetTime;
    }

    function increaseTime(uint t) external {
        offsetTime += t;
    }
}

interface KDemocracyIsProposerInterface {

    function shouldProposal(address proposer) external view returns (bool);

    function isProposer(address proposer) external view returns (bool);

    function proposerWeight(address proposer) external view returns (uint);
}

contract KOwnerable {

    address[] internal _authAddress;

    address[] public KContractOwners;

    bool private _call_locked;

    KDemocracyContract internal democracyDelegate;

    constructor() public {
        KContractOwners.push(msg.sender);
        _authAddress.push(msg.sender);
    }

    function KSetDemocracyDelegate(KDemocracyContract contractAddress) external KOwnerOnly {
        democracyDelegate = contractAddress;
    }

    function KAuthAddresses() external view returns (address[] memory) {
        return _authAddress;
    }

    function KAddAuthAddress(address auther) external KOwnerOnly {
        _authAddress.push(auther);
    }

    function KDelAuthAddress(address auther) external KOwnerOnly {
        for (uint i = 0; i < _authAddress.length; i++) {
            if (_authAddress[i] == auther) {
                for (uint j = 0; j < _authAddress.length - 1; j++) {
                    _authAddress[j] = _authAddress[j+1];
                }
                delete _authAddress[_authAddress.length - 1];
                _authAddress.pop();
                return ;
            }
        }
    }

    modifier KOwnerOnly() {
        bool exist = false;
        for ( uint i = 0; i < KContractOwners.length; i++ ) {
            if ( KContractOwners[i] == msg.sender ) {
                exist = true;
                break;
            }
        }
        require(exist, 'NotAuther'); _;
    }

    modifier KDemocracyOnly() {
        bool exist = false;
        for ( uint i = 0; i < KContractOwners.length; i++ ) {
            if ( KContractOwners[i] == msg.sender ) {
                exist = true;
                break;
            }
        }
        require( exist || msg.sender == address(democracyDelegate), 'NotAuther'); _;
    }

    modifier KOwnerOnlyAPI() {
        bool exist = false;
        for ( uint i = 0; i < KContractOwners.length; i++ ) {
            if ( KContractOwners[i] == msg.sender ) {
                exist = true;
                break;
            }
        }
        require(exist, 'NotAuther'); _;
    }

    modifier KRejectContractCall() {
        uint256 size;
        address payable safeAddr = msg.sender;
        assembly {size := extcodesize(safeAddr)}
        require( size == 0, "Sender Is Contract" );
        _;
    }

    modifier KDAODefense() {
        require(!_call_locked, "DAO_Warning");
        _call_locked = true;
        _;
        _call_locked = false;
    }

    modifier KDelegateMethod() {
        bool exist = false;
        for (uint i = 0; i < _authAddress.length; i++) {
            if ( _authAddress[i] == msg.sender ) {
                exist = true;
                break;
            }
        }
        require(exist, "PermissionDeny"); _;
    }

    function uint2str(uint i) internal pure returns (string memory c) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            bstr[k--] = byte( uint8(48 + i % 10) );
            i /= 10;
        }
        c = string(bstr);
    }
}

contract KPausable is KOwnerable {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool public paused;

    /**
     * @dev Initialize the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier KWhenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier KWhenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function Pause() public KOwnerOnly {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function Unpause() public KOwnerOnly {
        paused = false;
        emit Unpaused(msg.sender);
    }
}

contract KDebug is KPausable {

    KTimeController internal debugTimeController;

    function timestempZero() internal view returns (uint) {
        return timestemp() / 1 days * 1 days;
    }

    // function timestemp() internal view returns (uint) {
    //     if ( debugTimeController != KTimeController(0) ) {
    //         return debugTimeController.timestemp();
    //     } else {
    //         return now;
    //     }
    // }

    // function KSetDebugTimeController(address tc) external KOwnerOnly {
    //     debugTimeController = KTimeController(tc);
    // }

    function timestemp() internal view returns (uint) {
        return now;
    }
}

contract KStorage is KDebug {

    address public KImplementAddress;

    function SetKImplementAddress(address impl) external KDemocracyOnly {
        KImplementAddress = impl;
    }

    function () external {
        address impl_address = KImplementAddress;
        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(sub(gas(), 10000), impl_address, 0x0, calldatasize(), 0, 0)
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }
}


contract KStoragePayable is KDebug {

    address public KImplementAddress;

    function SetKImplementAddress(address impl) external KDemocracyOnly {
        KImplementAddress = impl;
    }

    function () external payable {
        address impl_address = KImplementAddress;
        assembly {

            if eq(calldatasize(), 0) {
                return(0, 0)
            }

            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(gas(), impl_address, 0x0, calldatasize(), 0, 0)
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }
}


contract ERC777_1TokenTemplate is iERC777_1, KPausable {

    using SafeMath for uint;

    address[] internal _defaultOperators;

    mapping (address => uint) internal _balances;
    mapping (address => mapping(address => uint)) internal _allowances;
    mapping (address => mapping(address => bool)) internal _authorized;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    uint public granularity = 1;


    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint _totalSupply
    ) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;

        _balances[address(this)] = _totalSupply - 1050000e6;
        _balances[msg.sender] = 1050000e6;
        _defaultOperators.push(msg.sender);
    }

    function balanceOf(address account) external view returns (uint) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external view returns (uint) {
        return _allowances[owner][spender];
    }

    function transfer(address recipient, uint amount) external KWhenNotPaused returns (bool) {
        _send(msg.sender, recipient, amount, "", msg.sender, "");
        return true;
    }

    function approve(address spender, uint value) external KWhenNotPaused returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) external KWhenNotPaused returns (bool) {
        require(amount <= _allowances[sender][msg.sender]);
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
        _send(sender, recipient, amount, "", msg.sender, "");
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) external KWhenNotPaused returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) external KWhenNotPaused returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /// ERC777 Methods Override
    function addDefaultOperators(address owner) external KOwnerOnly returns (bool) {
        _defaultOperators.push(owner);
    }

    function removeDefaultOperators(address owner) external KOwnerOnly returns (bool) {
        for (uint i = 0; i < _defaultOperators.length; i++) {
            if ( _defaultOperators[i] == owner ) {
                for (uint j = i; j < _defaultOperators.length - 1; j++) {
                    _defaultOperators[j] = _defaultOperators[j+1];
                }
                delete _defaultOperators[_defaultOperators.length - 1];
                _defaultOperators.length --;
                return true;
            }
        }
        return false;
    }

    function defaultOperators() external view returns (address[] memory) {
        return _defaultOperators;
    }

    function authorizeOperator(address _operator) external {
        require(_operator != msg.sender);
        _authorized[_operator][msg.sender] = true;
        emit AuthorizedOperator(_operator, msg.sender);
    }

    function revokeOperator(address _operator) external {
        require(_operator != msg.sender);
        _authorized[_operator][msg.sender] = false;
        emit RevokedOperator(_operator, msg.sender);
    }

    function send(address _to, uint _amount, bytes calldata _userData) external {
        _send(msg.sender, _to, _amount, _userData, msg.sender, "");
    }

    function isOperatorFor(address _operator, address _tokenHolder) public view returns (bool) {
        for (uint i = 0; i < _defaultOperators.length; i++) {
            if ( _defaultOperators[i] == _operator )  {
                return true;
            }
        }
        return _operator == _tokenHolder || _authorized[_operator][_tokenHolder];
    }

    function operatorSend(address _from, address _to, uint _amount, bytes calldata _userData, bytes calldata _operatorData) external {
        require( isOperatorFor(msg.sender, _from), "NotAuthorized" );
        _send(_from, _to, _amount, _userData, msg.sender, _operatorData);
    }

    function mint(address _tokenHolder, uint _amount, bytes calldata _operatorData) external KOwnerOnly {
        totalSupply = totalSupply.add(_amount);
        _balances[_tokenHolder] = _balances[_tokenHolder].add(_amount);
        emit Minted(msg.sender, _tokenHolder, _amount, "", _operatorData);
    }

    function burn(uint _amount, bytes calldata _data) external {
        _send(msg.sender, address(0x0), _amount, _data, msg.sender, "");
    }

    function operatorBurn(
        address _from,
        uint _amount,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external {
        require(isOperatorFor(msg.sender, _from), "NotAuthorized");

        if ( totalSupply <= 10000000e6 ) {
            _send(_from, KContractOwners[0], _amount, _data, msg.sender, _operatorData);
        } else {
            _send(_from, address(0x0), _amount, _data, msg.sender, _operatorData);
        }
    }

    function _send(
        address _from,
        address _to,
        uint _amount,
        bytes memory _userData,
        address _operator,
        bytes memory _operatorData
    ) internal {

        require(_balances[_from] >= _amount,"send,amount_lock"); // ensure enough funds

        _balances[_from] = _balances[_from].sub(_amount);
        _balances[_to] = _balances[_to].add(_amount);

        if ( _to == address(0) ) {
            totalSupply -= _amount;
            emit Burned(_operator, _from, _amount, _userData, _operatorData);
        } else {
            emit Sent(_operator, _from, _to, _amount, _userData, _operatorData);
        }

        emit Transfer(_from, _to, _amount);
    }

    function _approve(address owner, address spender, uint value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}

contract PinToken is ERC777_1TokenTemplate("PinSwap","PIN",6,21000000000000){

}