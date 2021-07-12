/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/utils/Address.sol

pragma solidity ^0.5.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: openzeppelin-solidity/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: contracts/AdminRole.sol

pragma solidity 0.5.12;




contract AdminRole {
    using Roles for Roles.Role;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    Roles.Role private _admins;

    constructor () internal {
        _addAdmin(msg.sender);
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "AdminRole: caller does not have the Admin role");
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    function addAdmin(address account) public onlyAdmin {
        _addAdmin(account);
    }

    function removeAdmin(address account) public onlyAdmin {
        _removeAdmin(account);
    }

    function _addAdmin(address account) internal {
        _admins.add(account);
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        _admins.remove(account);
        emit AdminRemoved(account);
    }
}

// File: contracts/Oraclize.sol

pragma solidity 0.5.12;




contract Oraclize is AdminRole {
    using SafeMath for uint256;

    mapping (address => uint) private reqc;

    mapping (address => bool) private cbAddresses;

    event DelayQuery(
        address indexed sender,
        bytes32 indexed id,
        uint256 delay,
        uint256 gasLimit
    );
    event RandomQueryGambling(
        address indexed sender,
        bytes32 indexed id,
        uint256 value,
        uint256 nBytes,
        uint256 gasLimit
    );

    event CallBackAAddressAdded(address indexed account);
    event CallBackAddressRemoved(address indexed account);

    function isCbAddress(address account) external view returns(bool) {
        return cbAddresses[account];
    }

    function addCbAddress(address account) external onlyAdmin {
        cbAddresses[account] = true;
        emit CallBackAAddressAdded(account);
    }

    function removeCbAddress(address account) external onlyAdmin {
        cbAddresses[account] = false;
        emit CallBackAddressRemoved(account);
    }

    function _delayQuery(
        uint delay,
        uint customGasLimit
    )
        internal
        returns (bytes32 id)
    {
        id = keccak256(abi.encodePacked(this, msg.sender, reqc[msg.sender]));
        reqc[msg.sender] = reqc[msg.sender].add(1);

        emit DelayQuery(
            msg.sender,
            id,
            delay,
            customGasLimit
        );
        return id;
    }

    function _randomNumberQueryGambling(
        uint256 nBytes,
        uint256 value,
        uint256 customGasLimit
    )
        internal
        returns (bytes32 id)
    {
        id = keccak256(abi.encodePacked(this, msg.sender, reqc[msg.sender]));
        reqc[msg.sender] = reqc[msg.sender].add(1);

        emit RandomQueryGambling(
            msg.sender,
            id,
            value,
            nBytes,
            customGasLimit
        );
        return id;
    }
}

// File: contracts/IOracleProvider.sol

pragma solidity 0.5.12;


interface IOracleProvider {

    enum DATASOURCE {_, RANDOM_GAMBLING, RANDOM_NON_GAMBLING, DELAY}

    function isWhitelisted(address account) external view returns(bool);

    function delayQuery(
        uint256 delay,
        uint256 gasLimit
    )
        external
        returns(bytes32);

    function randomNumberQueryGambling(
        uint256 nBytes,
        uint256 value,
        uint256 customGasLimit
    )
        external
        returns(bytes32);

    function randomNumberQueryNonGambling(
        uint256 nBytes,
        uint256 customGasLimit
    )
        external
        returns(bytes32);

    function isCbAddress(address account) external view returns(bool);

    //This is for backward compatibility with provable
    function getPrice(
        DATASOURCE datasource,
        bytes32 data
    )
        external
        view
        returns(uint256);
}

// File: contracts/OracelProvider.sol

pragma solidity 0.5.12;






contract OracleProvider is IOracleProvider, Oraclize {
    using SafeERC20 for IERC20;

    mapping(address => bool) private whitelisteds;

    struct Fee {
        bool isFixed;
        uint256 fixedFee;
        uint256 percentageFee;
        uint256 minFee;
    }

    mapping(bytes32 => Fee) private _dataSourceFees;

    bool private _paused;

    IERC20 private _weth;

    //It will be the deployer of the contract
    address private _feeWallet;

    event Whitelisted(address indexed account);
    event RemovedWhitelisted(address indexed account);
    event FundsWithdrawn(uint256 indexed amount, address indexed receiver);
    event FeeChanged(DATASOURCE indexed dataSource);
    event Paused();
    event Unpaused();

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    constructor(address weth) public {
        _weth = IERC20(weth);
        _feeWallet = msg.sender;
    }

    modifier onlyWhitelisted() {
        require(whitelisteds[msg.sender], "Not a whitelised address!!");
        _;
    }

    function getFeeWallet() external view returns(address) {
        return _feeWallet;
    }

    function addWhitelisted(address account) external onlyAdmin {
        whitelisteds[account] = true;
        emit Whitelisted(account);
    }

    function removeWhitelisted(address account) external onlyAdmin {
        whitelisteds[account] = false;
        emit RemovedWhitelisted(account);
    }

    function isWhitelisted(address account) external view returns(bool) {
        return whitelisteds[account];
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() external view returns (bool) {
        return _paused;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() external onlyAdmin whenNotPaused {
        _paused = true;
        emit Paused();
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() external onlyAdmin whenPaused {
        _paused = false;
        emit Unpaused();
    }

    function setFee(
        DATASOURCE dataSource,
        bool isFixed,
        uint256 fixedFee,
        uint256 percentageFee,
        uint256 minFee
    )
        external
        onlyAdmin
    {
        require(dataSource != DATASOURCE._, "Oracle: Invalid data source");

        _dataSourceFees[keccak256(abi.encodePacked(dataSource))] = Fee({
            isFixed: isFixed,
            fixedFee: fixedFee,
            percentageFee: percentageFee,
            minFee: minFee
        });
        emit FeeChanged(dataSource);

    }

    function delayQuery(
        uint256 delay,
        uint256 customGasLimit
    )
        external
        whenNotPaused
        onlyWhitelisted
        returns(bytes32)
    {
        uint256 rate = getPrice(DATASOURCE.DELAY, bytes32("0x"));

        if (rate > 0){
            _weth.safeTransferFrom(msg.sender, address(this), rate);
        }
        return _delayQuery(
            delay,
            customGasLimit
        );
    }

    function randomNumberQueryGambling(
        uint256 nBytes,
        uint256 value,
        uint256 customGasLimit
    )
        external
        whenNotPaused
        onlyWhitelisted
        returns(bytes32)
    {
        uint256 rate = getPrice(DATASOURCE.RANDOM_GAMBLING, bytes32(value));

        if (rate > 0){
            _weth.safeTransferFrom(msg.sender, address(this), rate);
        }

        return _randomNumberQueryGambling(
            nBytes,
            value,
            customGasLimit
        );
    }

    function randomNumberQueryNonGambling(
        uint256 nBytes,
        uint256 customGasLimit
    )
        external
        whenNotPaused
        returns(bytes32)
    {
        revert("METHOD NOT IMPLEMENTED");
        return bytes32("0x");
    }

    function withdraw() external onlyAdmin {

        uint256 amount = _weth.balanceOf(address(this));
        _weth.safeTransfer(_feeWallet, amount);
        emit FundsWithdrawn(amount, _feeWallet);
    }

    //This is for backward compatibility with provable
    function getPrice(
        DATASOURCE datasource,
        bytes32 data
    )
        public
        view
        returns(uint256)
    {
        uint256 price = 0;

        if (datasource == DATASOURCE.RANDOM_GAMBLING){
            Fee memory fee = _dataSourceFees[keccak256(abi.encodePacked(DATASOURCE.RANDOM_GAMBLING))];
            if (fee.isFixed) {
                price = fee.fixedFee;
            }
            else {
                uint256 value = uint256(data);
                uint256 tempFee = value.mul(fee.percentageFee).div(100000);
                if (tempFee > fee.minFee){
                    price = tempFee;
                }
                else {
                    price = fee.minFee;
                }
            }
        }
        return price;
    }
}