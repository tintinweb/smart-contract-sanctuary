/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// SPDX-License-Identifier: MIT
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@                       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@                                 @@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@                                       @@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@,                                          @@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@,                                        %(@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@                                       @ @@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@/             ,@@@@,                  @@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@.           @@@@@@@@                 @, @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@              @@@@                @@  @@@@@@@@@     #@@@@@@@@@@@@@@@@@@
// @@@@@@@                                 @@  &@@@%                  &@@@@@@@@@@@
// @@@@@@@                               @@   @@@@%             ,@@@@@   @@@@@@@@@
// @@@@@@%                             @@@  @@@@@@@@#             @@       @@@@@@@
// @@@@@@%                           @@@*  ,@@@@@@@@@                       *@@@@@
// @@@@@@@                         @@@@@@@    @@@@@@@@                    *@@@@@@@
// @@@@@@@                          @@@@@@@@@   @@@@@@@@               *@@@@@@@@@@
// @@@@@@@@                            @@@@@@@@#  #@@@@@@         *@@@@@@@@@@@@@@@
// @@@@@@@@@                             &@@@@@@@@   @@@@@.    #@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@                               &@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@,                                 @@@@@@@( @@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@                                   (@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@*                                     *@@@#@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@                                     @@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash =
        0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
        target.call{value: weiValue}(data);
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

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        uint256 newAllowance =
        token.allowance(address(this), spender).add(value);
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
        uint256 newAllowance =
        token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
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

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata =
        address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional

            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

contract FomoFarming is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Pool {
        IERC20 token;
        uint256 balance;
        uint256 lastBlock;
        uint256 share;
        uint256 accPerShare;
    }

    struct User {
        uint256 balance;
        uint256 date;
        uint256 rewards;
        uint256 loss;
        uint256 collected;
    }

    Pool[] public pools;
    mapping(uint256 => mapping(address => User)) public users;
    uint256 public startBlockNumber;
    uint256 public endBlockNumber;
    uint256 public tokensPerBlock;
    uint256 public totalShare;
    uint256 public paperPool = 0;
    IERC20 paperToken;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        IERC20 _paperToken,
        uint256 _startBlockNumber,
        uint256 _endBlockNumber,
        uint256 _tokensPerBlock
    ) public {
        paperToken = _paperToken;
        startBlockNumber = _startBlockNumber;
        endBlockNumber = _endBlockNumber;
        tokensPerBlock = _tokensPerBlock;
    }

    function deposit(uint8 _pid, uint256 _amount) public {
        Pool storage pool = pools[_pid];
        User storage user = users[_pid][msg.sender];
        require(
            pool.token.balanceOf(msg.sender) >= _amount,
            "You don't have enough tokens"
        );
        pool.accPerShare = getAccPerShare(_pid);
        pool.lastBlock = getLastBlockNumber();
        pool.token.safeTransferFrom(msg.sender, address(this), _amount);
        makeHarvest(_pid);
        pool.balance = pool.balance.add(_amount);
        user.balance = user.balance.add(_amount);
        user.loss = user.balance.mul(pool.accPerShare).div(1e12);
        user.date = block.timestamp;
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint8 _pid) public {
        Pool storage pool = pools[_pid];
        User storage user = users[_pid][msg.sender];
        require(user.balance > 0, "You don't have any tokens");
        pool.accPerShare = getAccPerShare(_pid);
        pool.lastBlock = getLastBlockNumber();
        pool.token.safeTransfer(msg.sender, user.balance);
        makeHarvest(_pid);
        pool.balance = pool.balance.sub(user.balance);
        if (pool.balance > 0 && user.rewards > user.collected) {
            // accPerShare += (rewards - collected) / balance
            pool.accPerShare = pool.accPerShare.add(
                user.rewards.sub(user.collected).mul(1e12).div(pool.balance)
            );
        }
        emit Withdraw(msg.sender, _pid, user.balance);
        delete users[_pid][msg.sender];
    }

    function harvest(uint256 _pid) public {
        Pool storage pool = pools[_pid];
        User storage user = users[_pid][msg.sender];
        require(makeHarvest(_pid) > 0, "You dont have any rewards");

        pool.accPerShare = getAccPerShare(_pid);
        pool.lastBlock = getLastBlockNumber();
        user.loss = user.balance.mul(pool.accPerShare).div(1e12);
    }

    function makeHarvest(uint256 _pid) internal returns (uint256) {
        User storage user = users[_pid][msg.sender];

        uint256 pending = getPending(_pid, msg.sender);
        if (!(pending > 0 || user.rewards > 0)) {
            return 0;
        }
        user.rewards = user.rewards.add(pending);

        uint256 reward = calcReward(user.rewards, user.date);

        if (!(reward > 0) || reward < user.collected) {
            return 0;
        }
        reward = reward.sub(user.collected);
        paperToken.safeTransfer(msg.sender, reward);
        user.collected = user.collected.add(reward);
        emit Harvest(msg.sender, _pid, reward);
        return reward;
    }

    function getLastBlockNumber() public view returns (uint256) {
        if (block.number < startBlockNumber) {
            return startBlockNumber;
        }
        if (block.number > endBlockNumber) {
            return endBlockNumber;
        }
        return block.number;
    }

    function getAccPerShare(uint256 _pid) public view returns (uint256) {
        Pool storage pool = pools[_pid];
        uint256 blockNumber = getLastBlockNumber();
        if (blockNumber == startBlockNumber || !(pool.balance > 0)) {
            return 0;
        }
        // poolAccPershare + (blockNumber - poolLastBlock) * tokensPerBlock * poolShare / (totalShare * poolBalance)
        return
        pool.accPerShare.add(
            blockNumber
            .sub(pool.lastBlock)
            .mul(tokensPerBlock)
            .mul(1e12)
            .mul(pool.share)
            .div(totalShare)
            .div(pool.balance)
        );
    }

    function getPending(uint256 _pid, address _user)
    public
    view
    returns (uint256)
    {
        User storage user = users[_pid][_user];
        uint256 pending = user.balance.mul(getAccPerShare(_pid)).div(1e12);
        if (pending > user.loss) {
            return pending.sub(user.loss);
        }
        return 0;
    }

    function getReward(uint256 _pid, address _user)
    public
    view
    returns (uint256)
    {
        User storage user = users[_pid][_user];
        uint256 pending = getPending(_pid, _user);
        if (!(pending > 0 || user.rewards > 0)) {
            return 0;
        }
        uint256 reward = calcReward(user.rewards.add(pending), user.date);
        if (user.collected > reward) {
            return 0;
        }
        return reward.sub(user.collected);
    }

    function calcReward(uint256 amount, uint256 date)
    internal
    view
    returns (uint256)
    {
        uint256 hodl = block.timestamp - date;
        if (hodl < 2 weeks) {
            return 0;
        }
        if (hodl < 4 weeks) {
            return amount.mul(25).div(100);
        }
        if (hodl < 6 weeks) {
            return amount.mul(50).div(100);
        }
        if (hodl < 8 weeks) {
            return amount.mul(75).div(100);
        }
        return amount;
    }

    function getUser(uint256 _pid, address _user)
    public
    view
    returns (
        uint256 balance,
        uint256 claimable,
        uint256 pending,
        uint256 lockDate,
        uint256 unlockDate,
        uint256 poolBalance,
        uint256 poolShare,
        uint256 totalShares,
        uint256 nextUnlock
    )
    {
        User storage user = users[_pid][_user];
        balance = user.balance;
        pending = user.rewards.add(getPending(_pid, _user)).sub(user.collected);
        claimable = getReward(_pid, _user);
        lockDate = user.date;
        unlockDate = user.date > 0 ? user.date + 8 weeks : 0;
        poolBalance = pools[_pid].balance;
        poolShare = pools[_pid].share;
        totalShares = totalShare;
        nextUnlock = 0;
        uint256 nextReward = calcReward(pending, lockDate - 2 weeks);
        if (nextReward > claimable) {
            nextUnlock = nextReward.sub(claimable);
        }
    }

    function safeRewardTransfer(address _user, uint256 _amount) internal {
        uint256 balance =
        paperToken.balanceOf(address(this)).sub(pools[paperPool].balance);
        if (_amount > balance) {
            paperToken.transfer(_user, balance);
        } else {
            paperToken.transfer(_user, _amount);
        }
    }

    function addPool(
        IERC20 _token,
        uint256 _share,
        bool _massUpdate
    ) public onlyOwner {
        if (_massUpdate) {
            massUpdate();
        }
        totalShare = totalShare.add(_share);
        uint256 blockNumber = getLastBlockNumber();
        pools.push(
            Pool({
                token: _token,
                balance: 0,
                lastBlock: blockNumber,
                share: _share,
                accPerShare: 0
            })
        );
    }

    function updatePool(
        uint256 _pid,
        uint256 _share,
        bool _massUpdate
    ) public onlyOwner {
        if (_massUpdate) {
            massUpdate();
        }
        totalShare = totalShare.sub(pools[_pid].share).add(_share);
        pools[_pid].share = _share;
    }

    function setEndBlock(uint256 _endBlock) public onlyOwner {
        endBlockNumber = _endBlock;
    }

    function setTokensPerBlock(uint256 _tokensPerBlock) public onlyOwner {
        massUpdate();
        tokensPerBlock = _tokensPerBlock;
    }

    function setPeperPool(uint256 _pid) public onlyOwner {
        require(_pid < pools.length, "Wrong pid");
        paperPool = _pid;
    }

    function withdrawUnusedPaper() public onlyOwner {
        uint256 amount =
        paperToken.balanceOf(address(this)).sub(pools[paperPool].balance);
        if (amount > 0) {
            paperToken.transfer(msg.sender, amount);
        }
    }

    function massUpdate() public onlyOwner {
        uint256 length = pools.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            Pool storage pool = pools[pid];
            pool.accPerShare = getAccPerShare(pid);
            pool.lastBlock = getLastBlockNumber();
        }
    }
}