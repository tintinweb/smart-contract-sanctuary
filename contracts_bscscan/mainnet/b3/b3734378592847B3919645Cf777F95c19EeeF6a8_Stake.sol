/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
    // silence state mutability warning without generating bytecode - 
    //see https://github.com/ethereum/solidity/issues/2691
        this; 
        return msg.data;
    }
}

// File: contracts/Roles.sol

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
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
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: contracts/PauserRole.sol

contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    function initPauserRole() internal {
        _addPauser(_msgSender());
    }

    constructor() {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(
            isPauser(_msgSender()),
            "PauserRole: caller does not have the Pauser role"
        );
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

// File: contracts/Pausable.sol

contract Pausable is Context, PauserRole {
    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: contracts/WhitelistAdminRole.sol

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    function initWhiteListAdmin() internal {
        _addWhitelistAdmin(_msgSender());
    }

    constructor() {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(
            isWhitelistAdmin(_msgSender()),
            "WhitelistAdminRole: caller does not have the WhitelistAdmin role"
        );
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

// File: contracts/SafeMath.sol

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath#mul: OVERFLOW");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath#sub: UNDERFLOW");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath#add: OVERFLOW");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
        return a % b;
    }
}

// File: contracts/Address.sol

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks
     * -effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html
     * ?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: contracts/IERC20.sol

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
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/SafeERC20.sol

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File: contracts/Wrap.sol

contract Wrap {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public token;

    constructor(IERC20 _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => uint256[]) public fixedBalances;
    mapping(address => uint256[]) public releaseTime;
    mapping(address => uint256) public fixedStakeLength;

    event WithdrawnFixedStake(address indexed user, uint256 amount);

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    function fixedStake(uint256 _day, uint256 _amount) public virtual {
        fixedBalances[msg.sender].push(_amount);
        uint256 time = block.timestamp + _day * 1 days;
        releaseTime[msg.sender].push(time);
        fixedStakeLength[msg.sender] += 1;
        _totalSupply = _totalSupply.add(_amount);
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function _rescueScore(address account) internal {
        uint256 amount = _balances[account];

        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        IERC20(token).safeTransfer(account, amount);
    }

    function withdrawFixedStake(uint256 _index) public virtual {
        require(fixedBalances[msg.sender].length >= _index, "No Record Found");
        require(fixedBalances[msg.sender][_index] != 0, "No Balance To Break");
        require(
            releaseTime[msg.sender][_index] <= block.timestamp,
            "Time isn't up"
        );

        _totalSupply = _totalSupply.sub(fixedBalances[msg.sender][_index]);
        IERC20(token).safeTransfer(
            msg.sender,
            fixedBalances[msg.sender][_index]
        );
        emit WithdrawnFixedStake(msg.sender, fixedBalances[msg.sender][_index]);
        removeBalance(_index);
        removeReleaseTime(_index);
        fixedStakeLength[msg.sender] -= 1;
    }

    function removeBalance(uint256 index) internal {
        // Move the last element into the place to delete
        fixedBalances[msg.sender][index] = fixedBalances[msg.sender][
            fixedBalances[msg.sender].length - 1
        ];
        // Remove the last element
        fixedBalances[msg.sender].pop();
    }

    function removeReleaseTime(uint256 index) internal {
        // Move the last element into the place to delete
        releaseTime[msg.sender][index] = releaseTime[msg.sender][
            releaseTime[msg.sender].length - 1
        ];
        // Remove the last element
        releaseTime[msg.sender].pop();
    }
}

// File: contracts/MyIERC721.sol

interface MyIERC721 {
    /**
     * @dev Mints the 721 Contract
     */
    function mint(address _to) external;
}

// File: contracts/ERC721TokenReceiver.sol

/**
 * @dev ERC-721 interface for accepting safe transfers.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721TokenReceiver {
    /**
     * @dev Handle the receipt of a NFT. The ERC721 smart contract calls this function on the
     * recipient after a `transfer`. This function MAY throw to revert and reject the transfer. Return
     * of other than the magic value MUST result in the transaction being reverted.
     * Returns `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` unless throwing.
     * @notice The contract address is always the message sender. A wallet/broker/auction application
     * MUST implement the wallet interface if it will accept safe transfers.
     * @param _operator The address which called `safeTransferFrom` function.
     * @param _from The address which previously owned the token.
     * @param _tokenId The NFT identifier which is being transferred.
     * @param _data Additional data with no specified format.
     * @return Returns `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     */
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

// File: contracts/Stake.sol

contract Stake is Wrap, Pausable, WhitelistAdminRole {
    struct Card {
        uint256 points;
        uint256 releaseTime;
        address erc721;
        uint256 supply;
    }

    using SafeMath for uint256;

    mapping(address => mapping(uint256 => Card)) public cards;

    mapping(address => uint256) public points;
    mapping(address => uint256) public lastUpdateTime;
    uint256 public rewardRate = 86400;
    uint256 public periodStart;
    uint256 public minStake;
    uint256 public maxStake;
    uint256 public minStakeFixed;
    uint256 public maxStakeFixed;
    address public controller;
    bool public constructed = false;
    address public rescuer;
    uint256 public spentScore;
    uint256 public maxDay;

    event Staked(address indexed user, uint256 amount);
    event FixedStaked(
        address indexed user,
        uint256 indexed amount,
        uint256 indexed day
    );
    event Withdrawn(address indexed user, uint256 amount);
    event RescueRedeemed(address indexed user, uint256 amount);
    event Removed(
        address indexed erc1155,
        uint256 indexed card,
        address indexed recipient,
        uint256 amount
    );
    event Redeemed(
        address indexed user,
        address indexed erc1155,
        uint256 indexed id,
        uint256 amount
    );

    modifier updateReward(address account) {
        if (account != address(0)) {
            points[account] = earned(account);
            lastUpdateTime[account] = block.timestamp;
        }
        _;
    }

    constructor(
        uint256 _periodStart,
        uint256 _minStake,
        uint256 _maxStake,
        uint256 _minStakeFixed,
        uint256 _maxStakeFixed,
        uint256 _maxDay,
        address _controller,
        IERC20 _tokenAddress
    ) Wrap(_tokenAddress) {
        require(
            _minStake >= 0 && _maxStake > 0 && _maxStake >= _minStake,
            "Problem with min and max stake setup"
        );
        require(
            address(_controller) != address(0),
            "controller can't be zero address"
        );
        constructed = true;
        periodStart = _periodStart;
        minStake = _minStake;
        maxStake = _maxStake;
        minStakeFixed = _minStakeFixed;
        maxStakeFixed = _maxStakeFixed;
        controller = _controller;
        rescuer = _controller;
        maxDay = _maxDay;
        // 		super.initWhiteListAdmin();
    }

    /**
     * @dev Sets the Earned Reward Rate of the user.
     */

    function setRewardRate(uint256 _rewardRate) external onlyWhitelistAdmin {
        require(_rewardRate > 0, "Reward rate too low");
        rewardRate = _rewardRate;
    }

    /**
     * @dev Sets the Max Day to stake for Fixed Staking.
     */

    function setMaxDay(uint256 _day) external onlyWhitelistAdmin {
        require(_day > 0, "Maximum Day can't be zero");
        maxDay = _day;
    }

    /**
     * @dev Sets the Minimum and Maximum amount to be staked in Flexi Stake.
     */

    function setMinMaxStake(uint256 _minStake, uint256 _maxStake)
        external
        onlyWhitelistAdmin
    {
        require(
            _minStake > 0 && _maxStake > 0 && _maxStake >= _minStake,
            "Problem with min and max stake setup"
        );
        minStake = _minStake;
        maxStake = _maxStake;
    }

    /**
     * @dev Sets the Minimum and Maximum amount to be staked in Fixed Stake.
     */

    function setMinMaxStakeFixed(uint256 _minStakeFixed, uint256 _maxStakeFixed)
        external
        onlyWhitelistAdmin
    {
        require(
            _minStakeFixed > 0 &&
                _maxStakeFixed > 0 &&
                _maxStakeFixed >= _minStakeFixed,
            "Problem with min and max stake Fixed setup"
        );
        minStakeFixed = _minStakeFixed;
        maxStakeFixed = _maxStakeFixed;
    }

    /**
     * @dev Sets the Rescuer address.
     */

    function setRescuer(address _rescuer) external onlyWhitelistAdmin {
        require(
            address(_rescuer) != address(0),
            "controller can't be zero address"
        );
        rescuer = _rescuer;
    }

    /**
     * @dev Returns the earned points by address.
     */

    function earned(address account) public view returns (uint256) {
        return points[account].add(getCurrPoints(account));
    }

    /**
     * @dev Calculates the earned points.
     */

    function getCurrPoints(address account) internal view returns (uint256) {
        uint256 blockTime = block.timestamp;
        return
            blockTime.sub(lastUpdateTime[account]).mul(balanceOf(account)).div(
                rewardRate
            );
    }

    /**
     * @dev Stake function to transfer token from user to contract.
     */

    function stake(uint256 amount)
        public
        override
        updateReward(msg.sender)
        whenNotPaused()
    {
        require(block.timestamp >= periodStart, "Pool not open");
        require(
            amount.add(balanceOf(msg.sender)) >= minStake,
            "Too few deposit"
        );
        require(
            amount.add(balanceOf(msg.sender)) <= maxStake,
            "Deposit limit reached"
        );

        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    /**
     * @dev fiexedStake function to transfer token from user to contract which locks for a particular period.
     */

    function fixedStake(uint256 _day, uint256 _amount)
        public
        override
        whenNotPaused()
    {
        require(block.timestamp >= periodStart, "Pool not open");
        require(_day > 0, "Can't stake for Zero days");
        require(_day <= maxDay, "Stake Day Limit Exceeded");
        require(_amount >= minStakeFixed, "Too few deposit");
        require(_amount <= maxStakeFixed, "Deposit limit reached");
        points[msg.sender] = points[msg.sender].add(_day.mul(_amount));
        super.fixedStake(_day, _amount);

        emit FixedStaked(msg.sender, _amount, _day);
    }

    /**
     * @dev withdraw flexi staked amount of sender.
     */

    function withdraw(uint256 amount)
        public
        override
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot withdraw 0");

        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @dev withdraw Fixed staked amount of sender.
     */

    function withdrawFixedStake(uint256 index) public override {
        super.withdrawFixedStake(index);
    }

    /**
     * @dev withdraw all flexi staked amount of the sender.
     */

    function exit() external {
        withdraw(balanceOf(msg.sender));
    }

    /**
     * @dev rescuer withdraw flexi staked amount of the user.
     */

    function rescueScore(address account)
        external
        updateReward(account)
        returns (uint256)
    {
        require(msg.sender == rescuer, "!rescuer");
        uint256 earnedPoints = points[account];
        spentScore = spentScore.add(earnedPoints);
        points[account] = 0;

        if (balanceOf(account) > 0) {
            _rescueScore(account);
        }

        emit RescueRedeemed(account, earnedPoints);
        return earnedPoints;
    }

    /**
     * @dev Add NFT to the contract.
     */

    function addNfts(
        uint256 _points,
        uint256 _releaseTime,
        address _erc721Address,
        uint256 _tokenId,
        uint256 _cardAmount
    ) external onlyWhitelistAdmin returns (uint256) {
        require(_tokenId > 0, "Invalid token id");
        require(_cardAmount > 0, "Invalid card amount");
        Card storage c = cards[_erc721Address][_tokenId];
        c.points = _points;
        c.releaseTime = _releaseTime;
        c.erc721 = _erc721Address;
        c.supply = _cardAmount;
        return _tokenId;
    }

    /**
     * @dev Minting the 721 to the sender address and reducing the points.
     */

    function redeem(address _erc721Address, uint256 id)
        external
        updateReward(msg.sender)
    {
        require(cards[_erc721Address][id].points != 0, "Card not found");
        require(
            block.timestamp >= cards[_erc721Address][id].releaseTime,
            "Card not released"
        );
        require(
            points[msg.sender] >= cards[_erc721Address][id].points,
            "Redemption exceeds point balance"
        );

        points[msg.sender] = points[msg.sender].sub(
            cards[_erc721Address][id].points
        );
        spentScore = spentScore.add(cards[_erc721Address][id].points);

        MyIERC721(cards[_erc721Address][id].erc721).mint(msg.sender);

        emit Redeemed(
            msg.sender,
            cards[_erc721Address][id].erc721,
            id,
            cards[_erc721Address][id].points
        );
    }
}