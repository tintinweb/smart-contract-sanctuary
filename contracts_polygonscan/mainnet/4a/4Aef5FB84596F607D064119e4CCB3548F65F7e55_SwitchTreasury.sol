// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import './libraries/SafeMath.sol';
import './libraries/TransferHelper.sol';
import './interfaces/IWETH.sol';
import './interfaces/IERC20.sol';
import './interfaces/ISwitchTreasurySubscriber.sol';
import './interfaces/ISwitchTreasury.sol';
import './interfaces/ISwitchTicket.sol';
import './modules/Configable.sol';
import './modules/ReentrancyGuard.sol';
import './modules/Pausable.sol';
import './modules/Initializable.sol';


contract SwitchTreasury is Configable, Pausable, ReentrancyGuard, Initializable {
    using SafeMath for uint;
    string public constant name = "SwitchTreasury";
    address public weth;
    address public targetTreasury;

    // _token=>_sender=>_value
    mapping(address => mapping(address => int)) public senderBalanceOf;

    address[] public subscribes;

    event Deposited(address indexed _token, address indexed _sender, address indexed _from, uint _value);
    event Withdrawed(address indexed _token, address indexed _from, address indexed _to, uint _value);
    event AllocPointChanged(address indexed _user, uint indexed _old, uint indexed _new);
    event TargetTreasuryChanged(address indexed _user, address indexed _old, address indexed _new);

    receive() external payable {
    }

    mapping(address => bool) public applyWhiteList;
    mapping(address => bool) public whiteList;
    mapping(address => bool) public tokenExistence;
    address[] public tokens;

    uint public totalAllocPoint;
    mapping(address => uint) public allocPoint;

    struct TokenLimit {
        bool enabled;
        uint blocks;
        uint amount;
        uint lastBlock;
        uint consumption;
    }
    //key:(white user, token)
    mapping(address => mapping(address => TokenLimit)) public tokenLimits;

    modifier onlyWhite() {
        require(whiteList[msg.sender], "SwitchTreasury: FORBIDDEN");
        _;
    }

    modifier whenNotPaused() override {
        if(msg.sender != targetTreasury) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    function initialize(address _weth) external initializer {
        require(_weth != address(0), 'SwitchTreasury: ZERO_ADDRESS');
        owner = msg.sender;
        weth = _weth;
    }

    function pause() external onlyManager whenNotPaused {
        _pause();
    }

    function unpause() external onlyManager whenPaused {
        _unpause();
    }

    function applyWhite(address _user, bool _value) public onlyDev {
        applyWhiteList[_user] = _value;
    }

    function applyWhites(address[] memory _users, bool[] memory _values) external onlyDev {
        require(_users.length == _values.length, "SwitchTreasury: invalid param");
        for (uint256 i; i < _users.length; i++) {
            applyWhite(_users[i], _values[i]);
        }
    }

    function setWhite(address _user) public onlyAdmin {
        whiteList[_user] = applyWhiteList[_user];
    }

    function setWhites(address[] memory _users) external onlyAdmin {
        for (uint256 i; i < _users.length; i++) {
            setWhite(_users[i]);
        }
    }

    function setAllocPoint(address _user, uint _value) public onlyManager {
        totalAllocPoint = totalAllocPoint.sub(allocPoint[_user]).add(_value);
        emit AllocPointChanged(msg.sender, allocPoint[_user], _value);
        allocPoint[_user] = _value;
    }

    function batchSetAllocPoint(address[] memory _users, uint256[] memory _values) external onlyManager {
        require(_users.length == _values.length, 'SwitchTreasury: INVALID_PARAM');
        for (uint i; i<_users.length; i++) {
            setAllocPoint(_users[i], _values[i]);
        }
    }

    function setTokenLimit(address _user, address _token, bool _enabled, uint _blocks, uint _amount, uint _consumption) public onlyManager {
        require(_amount >= _consumption, 'SwitchTreasury: INVALID_PARAM');
        TokenLimit storage limit = tokenLimits[_user][_token];
        limit.enabled = _enabled;
        limit.blocks = _blocks;
        limit.amount = _amount;
        limit.consumption = _consumption;
    }

    function setTokenLimits(address[] memory _user, address[] memory _token, bool[] memory _enabled, uint[] memory _blocks, uint[] memory _amount, uint[] memory _consumption) external onlyManager {
        require(
            _user.length == _token.length 
            && _token.length == _enabled.length 
            && _enabled.length == _blocks.length 
            && _blocks.length == _amount.length 
            && _amount.length == _consumption.length 
            , "SwitchTreasury: INVALID_PARAM"
        );
        for (uint i; i<_user.length; i++) {
            setTokenLimit(_user[i], _token[i], _enabled[i], _blocks[i], _amount[i], _consumption[i]);
        }
    }

    function addSubscribe(address _user) external onlyDev {
        if(isSubscribe(_user) == false) {
            subscribes.push(_user);
        }
    }

    function removeSubscribe(address _user) external onlyDev {
        uint index = indexSubscribe(_user);
        if(index == subscribes.length) {
            return;
        }
        if(index < subscribes.length -1) {
            subscribes[index] = subscribes[subscribes.length-1];
        }
        subscribes.pop();
    }

    function isSubscribe(address _user) public view returns (bool) {
        for(uint i = 0;i < subscribes.length;i++) {
            if(_user == subscribes[i]) {
                return true;
            }
        }
        return false;
    }
    
    function indexSubscribe(address _user) public view returns (uint) {
        for(uint i; i< subscribes.length; i++) {
            if(subscribes[i] == _user) {
                return i;
            }
        }
        return subscribes.length;
    }
 
    function countSubscribe() public view returns (uint) {
        return subscribes.length;
    }

    function _subscribe(address _sender, address _from, address _to, address _token, uint _value) internal {
        for(uint i; i< subscribes.length; i++) {
            ISwitchTreasurySubscriber(subscribes[i]).subscribeTreasury(_sender, _from, _to, _token, _value);
        }
    }

    function countToken() public view returns (uint) {
        return tokens.length;
    }

    function mint(address _token, address _to, uint _value) external onlyWhite whenNotPaused nonReentrant returns (uint) {
        ISwitchTicket(_token).mint(_to, _value);
        senderBalanceOf[_token][msg.sender] += int(_value);
        return _value;
    }

    function burn(address _token, address _from, uint _value) external onlyWhite whenNotPaused nonReentrant returns (uint) {
        ISwitchTicket(_token).burn(_from, _value);
        senderBalanceOf[_token][msg.sender] -= int(_value);
        return _value;
    }

    function deposit(address _from, address _token, uint _value) external payable onlyWhite whenNotPaused nonReentrant returns (uint) {
        require(_value > 0, 'SwitchTreasury: ZERO');
        if (_token == address(0)) {
            _token = weth;
            require(_value == msg.value, 'SwitchTreasury: INVALID_VALUE');
            IWETH(weth).deposit{value: msg.value}();
        } else {
            require(IERC20(_token).balanceOf(_from) >= _value, 'SwitchTreasury: INSUFFICIENT_BALANCE');
            TransferHelper.safeTransferFrom(_token, _from, address(this), _value);
        }

        senderBalanceOf[_token][msg.sender] += int(_value);

        if(tokenExistence[_token] == false) {
            tokens.push(_token);
            tokenExistence[_token] = true;
        }
        
        _subscribe(msg.sender, _from, address(this), _token, _value);
        emit Deposited(_token, msg.sender, _from, _value);
        return _value;
    }

    function withdraw(bool _isETH, address _to, address _token, uint _value) external onlyWhite whenNotPaused nonReentrant returns (uint) {
        if (_token == address(0)) {
            _token = weth;
        }
        uint _amount = queryWithdraw(msg.sender, _token);
        require(_value > 0, 'SwitchTreasury: ZERO');
        require(_amount >= _value, 'SwitchTreasury: INSUFFICIENT_BALANCE');

        _updateTokenLimit(_token, _value);

        senderBalanceOf[_token][msg.sender] -= int(_value);
        
        emit Withdrawed(_token, msg.sender, _to, _value);
        if (_isETH && _token == weth) {
            uint balance = address(this).balance;
            if(balance < _value) {
                IWETH(weth).withdraw(_value.sub(balance));
            }
            TransferHelper.safeTransferETH(_to, _value);
        } else {
            TransferHelper.safeTransfer(_token, _to, _value);
        }
        _subscribe(msg.sender, address(this), _to, _token, _value);
        return _value;
    }

    function queryWithdraw(address _user, address _token) public view returns (uint) {
        if (_token == address(0)) {
            _token = weth;
        }
        uint amount = IERC20(_token).balanceOf(address(this));
        if(totalAllocPoint > 0) {
            amount = amount.mul(allocPoint[_user]).div(totalAllocPoint);
        }

        return getTokenLimit(_user, _token, amount);        
    }

    function getTokenLimit(address _user, address _token, uint _value) public view returns (uint) {
        TokenLimit memory limit = tokenLimits[_user][_token];
        if (limit.enabled == false) {
            return _value;
        }

        if(_value > limit.amount) {
            _value = limit.amount;
        }

        if (block.number.sub(limit.lastBlock) >= limit.blocks) {
            return _value;
        }

        if (limit.consumption.add(_value) > limit.amount) {
            _value = limit.amount.sub(limit.consumption);
        }
        return _value;
    }

    function _updateTokenLimit(address _token, uint _value) internal {
        TokenLimit storage limit = tokenLimits[msg.sender][_token];
        if(limit.enabled == false) {
            return;
        }
        if(block.number.sub(limit.lastBlock) > limit.blocks) {
            limit.consumption = 0;
        }
        limit.lastBlock = block.number;
        limit.consumption = limit.consumption.add(_value);
    }

    function toWETH() external onlyManager {
        uint balance = address(this).balance;
        IWETH(weth).deposit{value: balance}();
    }

    // for upgrade {
    function setTargetTreasury(address _targetTreasury) external onlyDev {
        require(_targetTreasury != address(0), 'SwitchTreasury: ZERO_ADDRESS');
        emit TargetTreasuryChanged(msg.sender, targetTreasury, _targetTreasury);
        targetTreasury = _targetTreasury;
    }

    function migrate(address _from, address _token) public onlyDev {
        uint amount = IERC20(_token).balanceOf(_from);
        if(amount > 0){
            ISwitchTreasury(_from).withdraw(false, address(this), _token, amount);
        }
    }

    function migrateList(address _from, address[] memory _tokens) external onlyDev {
        for(uint i; i<_tokens.length; i++) {
            migrate(_from, _tokens[i]);
        }
    }

    function migrateAll(address _from) external onlyDev {
        for(uint i; i<tokens.length; i++) {
            migrate(_from, tokens[i]);
        }
    }

    function changeOwnerForToken(address _token, address _user) public onlyDev {
        return ISwitchTicket(_token).changeOwner(_user);
    }

    function changeOwnerForTokens(address[] memory _tokens, address[] memory _users) external onlyDev {
        require(_tokens.length == _users.length, 'SwitchTreasury: invalid params');
        for(uint i; i<_tokens.length; i++) {
            changeOwnerForToken(_tokens[i], _users[i]);
        }
    }
    // for upgrade }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

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
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface ISwitchTreasurySubscriber {
    function subscribeTreasury(address _sender, address _from, address _to, address _token, uint _value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface ISwitchTreasury {
    function tokenBalanceOf(address _token) external returns (uint);
    function mint(address _token, address _to, uint _value) external returns (uint);
    function burn(address _token, address _from, uint _value) external returns (uint);
    function deposit(address _from, address _token, uint _value) external payable returns (uint);
    function queryWithdraw(address _user, address _token) external view returns (uint);
    function withdraw(bool _isETH, address _to, address _token, uint _value) external returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface ISwitchTicket {
    function changeOwner(address _user) external;
    function mint(address to, uint value) external returns (bool);
    function burn(address from, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

interface IConfig {
    function dev() external view returns (address);
    function admin() external view returns (address);
}

contract Configable {
    address public config;
    address public owner;

    event ConfigChanged(address indexed _user, address indexed _old, address indexed _new);
    event OwnerChanged(address indexed _user, address indexed _old, address indexed _new);
 
    function setupConfig(address _config) external onlyOwner {
        emit ConfigChanged(msg.sender, config, _config);
        config = _config;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'OWNER FORBIDDEN');
        _;
    }

    function admin() public view returns(address) {
        if(config != address(0)) {
            return IConfig(config).admin();
        }
        return owner;
    }

    function dev() public view returns(address) {
        if(config != address(0)) {
            return IConfig(config).dev();
        }
        return owner;
    }

    function changeOwner(address _user) external onlyOwner {
        require(owner != _user, 'Owner: NO CHANGE');
        emit OwnerChanged(msg.sender, owner, _user);
        owner = _user;
    }
    
    modifier onlyDev() {
        require(msg.sender == dev() || msg.sender == owner, 'dev FORBIDDEN');
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin(), 'admin FORBIDDEN');
        _;
    }
  
    modifier onlyManager() {
        require(msg.sender == dev() || msg.sender == admin() || msg.sender == owner, 'manager FORBIDDEN');
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 1;

    uint256 private _status;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused();

    bool private _paused;

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() virtual {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000000
  },
  "metadata": {
    "bytecodeHash": "none"
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}