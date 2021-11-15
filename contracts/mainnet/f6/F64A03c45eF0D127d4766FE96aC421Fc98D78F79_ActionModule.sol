// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../../utils/Timers.sol";
import "../ModuleBase.sol";

contract ActionModule is IModule, ModuleBase, Timers
{
    string public constant override name = type(ActionModule).name;

    // bytes32 public constant ACTION_DURATION = bytes32(uint256(keccak256("ACTION_DURATION")) - 1);
    bytes32 public constant ACTION_DURATION = 0x05f91198c37cc2578c2915e1614db3bf5c90e3387bd106bdfbb0da82514418dd;
    // bytes32 public constant ACTION_AUTH_RATIO = bytes32(uint256(keccak256("ACTION_AUTH_RATIO")) - 1);
    bytes32 public constant ACTION_AUTH_RATIO = 0x3c3813978ff64b4dbcec0d1ea3c72ec1393a708e0a785f2797bac1f61c3d7e09;

    event ActionScheduled(ShardedWallet indexed wallet, bytes32 indexed uid, bytes32 indexed id, uint256 i, address to, uint256 value, bytes data);
    event ActionExecuted(ShardedWallet indexed wallet, bytes32 indexed uid, bytes32 indexed id, uint256 i, address to, uint256 value, bytes data);
    event ActionCancelled(ShardedWallet indexed wallet, bytes32 indexed uid, bytes32 indexed id);

    modifier actionAuthorized(ShardedWallet wallet, address user)
    {
        require(wallet.balanceOf(user) >= Math.max(
            wallet.totalSupply() * wallet.governance().getConfig(address(wallet), ACTION_AUTH_RATIO) / 10**18,
            1
        ));
        _;
    }

    constructor(address walletTemplate) ModuleBase(walletTemplate) {}

    function schedule(ShardedWallet wallet, address[] memory to, uint256[] memory value, bytes[] memory data)
    public actionAuthorized(wallet, msg.sender) returns (bytes32)
    {
        require(to.length == value.length);
        require(to.length == data.length);
        bytes32 id  = keccak256(abi.encode(to, value, data));
        bytes32 uid = keccak256(abi.encode(wallet, id));

        Timers._startTimer(uid, wallet.governance().getConfig(address(wallet), ACTION_DURATION));

        for (uint256 i = 0; i < to.length; ++i) {
            emit ActionScheduled(wallet, uid, id, i, to[i], value[i], data[i]);
        }

        return id;
    }

    function execute(ShardedWallet wallet, address[] memory to, uint256[] memory value, bytes[] memory data)
    public actionAuthorized(wallet, msg.sender) returns (bool)
    {
        require(wallet.owner() == address(0)); // buyout takes over ownership
        require(to.length == value.length);
        require(to.length == data.length);
        bytes32 id  = keccak256(abi.encode(to, value, data));
        bytes32 uid = keccak256(abi.encode(wallet, id));

        Timers._resetTimer(uid);

        for (uint256 i = 0; i < to.length; ++i) {
            wallet.moduleExecute(to[i], value[i], data[i]);
            emit ActionExecuted(wallet, uid, id, i, to[i], value[i], data[i]);
        }

        return true;
    }

    function cancel(ShardedWallet wallet, bytes32 id)
    public actionAuthorized(wallet, msg.sender) returns (bool)
    {
        bytes32 uid = keccak256(abi.encode(wallet, id));

        Timers._stopTimer(uid);

        emit ActionCancelled(wallet, uid, id);

        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Timers
{
    mapping(bytes32 => uint256) private _deadlines;

    event TimerStarted(bytes32 indexed timer, uint256 deadline);
    event TimerStopped(bytes32 indexed timer);
    event TimerReset(bytes32 indexed timer);

    modifier onlyBeforeTimer(bytes32 id)
    {
        require(_beforeTimer(id), "WithTimers: onlyBeforeTimer");
        _;
    }

    modifier onlyDuringTimer(bytes32 id)
    {
        require(_duringTimer(id), "WithTimers: onlyDuringTimer");
        _;
    }

    modifier onlyAfterTimer(bytes32 id)
    {
        require(_afterTimer(id), "WithTimers: onlyAfterTimer");
        _;
    }

    function _beforeTimer(bytes32 id)
    internal view returns (bool)
    {
        return _deadlines[id] == 0;
    }

    function _duringTimer(bytes32 id)
    internal view returns (bool)
    {
        uint256 deadline = _deadlines[id];
        // solhint-disable-next-line not-rely-on-time
        return deadline != 0 && deadline > block.timestamp;
    }

    function _afterTimer(bytes32 id)
    internal view returns (bool)
    {
        uint256 deadline = _deadlines[id];
        // solhint-disable-next-line not-rely-on-time
        return deadline != 0 && deadline <= block.timestamp;
    }

    function _startTimer(bytes32 id, uint256 delay)
    internal onlyBeforeTimer(id)
    {
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + delay;
        _deadlines[id] = deadline;
        emit TimerStarted(id, deadline);
    }

    function _stopTimer(bytes32 id)
    internal onlyDuringTimer(id)
    {
        delete _deadlines[id];
        emit TimerStopped(id);
    }

    function _resetTimer(bytes32 id)
    internal onlyAfterTimer(id)
    {
        delete _deadlines[id];
        emit TimerReset(id);
    }

    function _getDeadline(bytes32 id)
    internal view returns (uint256)
    {
        return _deadlines[id];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../wallet/ShardedWallet.sol";
import "./IModule.sol";

abstract contract ModuleBase is IModule
{
    address immutable public walletTemplate;

    constructor(address walletTemplate_)
    {
        walletTemplate = walletTemplate_;
    }

    modifier onlyShardedWallet(ShardedWallet wallet)
    {
        require(isClone(walletTemplate, address(wallet)));
        _;
    }

    modifier onlyAuthorized(ShardedWallet wallet, address user)
    {
        require(wallet.governance().isAuthorized(address(wallet), user));
        _;
    }

    modifier onlyOwner(ShardedWallet wallet, address user)
    {
        require(wallet.owner() == user);
        _;
    }

    function isClone(address target, address query)
    internal view returns (bool result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
            mstore(add(clone, 0xa), targetBytes)
            mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../governance/IGovernance.sol";
import "../initializable/Ownable.sol";
import "../initializable/ERC20.sol";
import "../initializable/ERC1363.sol";

contract ShardedWallet is Ownable, ERC20, ERC1363Approve
{
    // bytes32 public constant ALLOW_GOVERNANCE_UPGRADE = bytes32(uint256(keccak256("ALLOW_GOVERNANCE_UPGRADE")) - 1);
    bytes32 public constant ALLOW_GOVERNANCE_UPGRADE = 0xedde61aea0459bc05d70dd3441790ccfb6c17980a380201b00eca6f9ef50452a;

    IGovernance public governance;
    address public artistWallet;

    event Received(address indexed sender, uint256 value, bytes data);
    event Execute(address indexed to, uint256 value, bytes data);
    event ModuleExecute(address indexed module, address indexed to, uint256 value, bytes data);
    event GovernanceUpdated(address indexed oldGovernance, address indexed newGovernance);
    event ArtistUpdated(address indexed oldArtist, address indexed newArtist);

    modifier onlyModule()
    {
        require(_isModule(msg.sender), "Access restricted to modules");
        _;
    }

    /*************************************************************************
     *                       Contructor and fallbacks                        *
     *************************************************************************/
    constructor()
    {
        governance = IGovernance(address(0xdead));
    }

    receive()
    external payable
    {
        emit Received(msg.sender, msg.value, bytes(""));
    }

    fallback()
    external payable
    {
        address module = governance.getModule(address(this), msg.sig);
        if (module != address(0) && _isModule(module))
        {
            (bool success, /*bytes memory returndata*/) = module.staticcall(msg.data);
            // returning bytes in fallback is not supported until solidity 0.8.0
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                switch success
                case 0 { revert(0, returndatasize()) }
                default { return (0, returndatasize()) }
            }
        }
        else
        {
            emit Received(msg.sender, msg.value, msg.data);
        }
    }

    /*************************************************************************
     *                            Initialization                             *
     *************************************************************************/
    function initialize(
        address         governance_,
        address         minter_,
        string calldata name_,
        string calldata symbol_,
        address         artistWallet_
    )
    external
    {
        require(address(governance) == address(0));

        governance = IGovernance(governance_);
        Ownable._setOwner(minter_);
        ERC20._initialize(name_, symbol_);
        artistWallet = artistWallet_;

        emit GovernanceUpdated(address(0), governance_);
    }

    function _isModule(address module)
    internal view returns (bool)
    {
        return governance.isModule(address(this), module);
    }

    /*************************************************************************
     *                          Owner interactions                           *
     *************************************************************************/
    function execute(address to, uint256 value, bytes calldata data)
    external onlyOwner()
    {
        Address.functionCallWithValue(to, data, value);
        emit Execute(to, value, data);
    }

    function retrieve(address newOwner)
    external
    {
        ERC20._burn(msg.sender, Math.max(ERC20.totalSupply(), 1));
        Ownable._setOwner(newOwner);
    }

    /*************************************************************************
     *                          Module interactions                          *
     *************************************************************************/
    function moduleExecute(address to, uint256 value, bytes calldata data)
    external onlyModule()
    {
        if (Address.isContract(to))
        {
            Address.functionCallWithValue(to, data, value);
        }
        else
        {
            Address.sendValue(payable(to), value);
        }
        emit ModuleExecute(msg.sender, to, value, data);
    }

    function moduleMint(address to, uint256 value)
    external onlyModule()
    {
        ERC20._mint(to, value);
    }

    function moduleBurn(address from, uint256 value)
    external onlyModule()
    {
        ERC20._burn(from, value);
    }

    function moduleTransfer(address from, address to, uint256 value)
    external onlyModule()
    {
        ERC20._transfer(from, to, value);
    }

    function moduleTransferOwnership(address to)
    external onlyModule()
    {
        Ownable._setOwner(to);
    }

    function updateGovernance(address newGovernance)
    external onlyModule()
    {
        emit GovernanceUpdated(address(governance), newGovernance);

        require(governance.getConfig(address(this), ALLOW_GOVERNANCE_UPGRADE) > 0);
        require(Address.isContract(newGovernance));
        governance = IGovernance(newGovernance);
    }

    function updateArtistWallet(address newArtistWallet)
    external onlyModule()
    {
        emit ArtistUpdated(artistWallet, newArtistWallet);

        artistWallet = newArtistWallet;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IModule
{
    function name() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly { size := extcodesize(account) }
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
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
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
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGovernance
{
    function isModule(address, address) external view returns (bool);
    function isAuthorized(address, address) external view returns (bool);
    function getModule(address, bytes4) external view returns (address);
    function getConfig(address, bytes32) external view returns (uint256);
    function getNiftexWallet() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function _setOwner(address owner_) internal {
        emit OwnershipTransferred(_owner, owner_);
        _owner = owner_;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    function _initialize(string memory name_, string memory symbol_) internal virtual {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "../interface/IERC1363.sol";
import "../interface/IERC1363Receiver.sol";
import "../interface/IERC1363Spender.sol";

abstract contract ERC1363Transfer is ERC20, IERC1363Transfer {
    function transferAndCall(address to, uint256 value) public override returns (bool) {
        return transferAndCall(to, value, bytes(""));
    }

    function transferAndCall(address to, uint256 value, bytes memory data) public override returns (bool) {
        require(transfer(to, value));
        try IERC1363Receiver(to).onTransferReceived(_msgSender(), _msgSender(), value, data) returns (bytes4 selector) {
            require(selector == IERC1363Receiver(to).onTransferReceived.selector, "ERC1363: onTransferReceived invalid result");
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("ERC1363: onTransferReceived reverted without reason");
        }
        return true;
    }

    function transferFromAndCall(address from, address to, uint256 value) public override returns (bool) {
        return transferFromAndCall(from, to, value, bytes(""));
    }

    function transferFromAndCall(address from, address to, uint256 value, bytes memory data) public override returns (bool) {
        require(transferFrom(from, to, value));
        try IERC1363Receiver(to).onTransferReceived(_msgSender(), from, value, data) returns (bytes4 selector) {
            require(selector == IERC1363Receiver(to).onTransferReceived.selector, "ERC1363: onTransferReceived invalid result");
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("ERC1363: onTransferReceived reverted without reason");
        }
        return true;
    }
}

abstract contract ERC1363Approve is ERC20, IERC1363Approve {
    function approveAndCall(address spender, uint256 value) public override returns (bool) {
        return approveAndCall(spender, value, bytes(""));
    }

    function approveAndCall(address spender, uint256 value, bytes memory data) public override returns (bool) {
        require(approve(spender, value));
        try IERC1363Spender(spender).onApprovalReceived(_msgSender(), value, data) returns (bytes4 selector) {
            require(selector == IERC1363Spender(spender).onApprovalReceived.selector, "ERC1363: onApprovalReceived invalid result");
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("ERC1363: onApprovalReceived reverted without reason");
        }
        return true;
    }
}

abstract contract ERC1363 is ERC1363Transfer, ERC1363Approve {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1363Transfer {
    /*
    * Note: the ERC-165 identifier for this interface is 0x4bbee2df.
    * 0x4bbee2df ===
    *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
    *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
    *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
    *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)'))
    */

    /**
     * @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @return true unless throwing
     */
    function transferAndCall(address to, uint256 value) external returns (bool);

    /**
     * @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `to`
     * @return true unless throwing
     */
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @notice Transfer tokens from one address to another and then call `onTransferReceived` on receiver
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @return true unless throwing
     */
    function transferFromAndCall(address from, address to, uint256 value) external returns (bool);


    /**
     * @notice Transfer tokens from one address to another and then call `onTransferReceived` on receiver
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `to`
     * @return true unless throwing
     */
    function transferFromAndCall(address from, address to, uint256 value, bytes calldata data) external returns (bool);
}

interface IERC1363Approve {
  /*
   * Note: the ERC-165 identifier for this interface is 0xfb9ec8ce.
   * 0xfb9ec8ce ===
   *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
   *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
   */
  /**
   * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
   * and then call `onApprovalReceived` on spender.
   * @param spender address The address which will spend the funds
   * @param value uint256 The amount of tokens to be spent
   */
  function approveAndCall(address spender, uint256 value) external returns (bool);

  /**
   * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
   * and then call `onApprovalReceived` on spender.
   * @param spender address The address which will spend the funds
   * @param value uint256 The amount of tokens to be spent
   * @param data bytes Additional data with no specified format, sent in call to `spender`
   */
  function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);
}

interface IERC1363 is IERC1363Transfer, IERC1363Approve {
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC1363Receiver interface
 * @dev Interface for any contract that wants to support `transferAndCall` or `transferFromAndCall`
 *  from ERC1363 token contracts.
 */
interface IERC1363Receiver {
  /*
   * Note: the ERC-165 identifier for this interface is 0x88a7ca5c.
   * 0x88a7ca5c === bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))
   */

  /**
   * @notice Handle the receipt of ERC1363 tokens
   * @dev Any ERC1363 smart contract calls this function on the recipient
   * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
   * transfer. Return of other than the magic value MUST result in the
   * transaction being reverted.
   * Note: the token contract address is always the message sender.
   * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
   * @param from address The address which are token transferred from
   * @param value uint256 The amount of tokens transferred
   * @param data bytes Additional data with no specified format
   * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))`
   *  unless throwing
   */
  function onTransferReceived(address operator, address from, uint256 value, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC1363Spender interface
 * @dev Interface for any contract that wants to support `approveAndCall`
 *  from ERC1363 token contracts.
 */
interface IERC1363Spender {
  /*
   * Note: the ERC-165 identifier for this interface is 0.8.04a2d0.
   * 0.8.04a2d0 === bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))
   */

  /**
   * @notice Handle the approval of ERC1363 tokens
   * @dev Any ERC1363 smart contract calls this function on the recipient
   * after an `approve`. This function MAY throw to revert and reject the
   * approval. Return of other than the magic value MUST result in the
   * transaction being reverted.
   * Note: the token contract address is always the message sender.
   * @param owner address The address which called `approveAndCall` function
   * @param value uint256 The amount of tokens to be spent
   * @param data bytes Additional data with no specified format
   * @return `bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))`
   *  unless throwing
   */
  function onApprovalReceived(address owner, uint256 value, bytes calldata data) external returns (bytes4);
}

