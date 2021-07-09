/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

// File: node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol

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

// File: node_modules\@openzeppelin\contracts\token\ERC20\extensions\IERC20Metadata.sol


pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: node_modules\@openzeppelin\contracts\utils\Context.sol



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

// File: @openzeppelin\contracts\token\ERC20\ERC20.sol

pragma solidity ^0.8.0;




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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
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

// File: @openzeppelin\contracts\utils\Address.sol



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

// File: @openzeppelin\contracts\security\ReentrancyGuard.sol



pragma solidity ^0.8.0;

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
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

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

// File: @openzeppelin\contracts\access\Ownable.sol



pragma solidity ^0.8.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts\IStaking.sol


pragma solidity ^0.8.0;

interface IStaking {
    function getStakedAmount() external view returns(uint256);
    function getAccountInfo(address staker) external view returns (uint256, uint256, uint256);
}

// File: contracts\LessLibrary.sol


pragma solidity ^0.8.0;



contract LessLibrary is Ownable {
    PresaleInfo[] private presaleAddresses; // track all presales created

    uint256 private minInvestorBalance = 1000 * 1e18;
    uint256 private votingTime = 3 days; //tthree days
    //uint256 private votingTime = 300;
    uint256 private minStakeTime = 1 days; //one day
    uint256 private minUnstakeTime = 6 days; //six days

    address private factoryAddress;

    uint256 private minVoterBalance = 500 * 1e18; // minimum number of  tokens to hold to vote
    uint256 private minCreatorStakedBalance = 8000 * 1e18; // minimum number of tokens to hold to launch rocket

    uint8 private feePercent = 2;
    uint32 private usdtFee = 1 * 1e6;

    address private uniswapRouter; // uniswapV2 Router
    address private tether = address(0x110a13FC3efE6A245B50102D2d79B3E76125Ae83);

    address payable private lessVault;
    address private devAddress;
    IStaking public safeStakingPool;

    mapping(address => bool) private isPresale;

    struct PresaleInfo {
        bytes32 title;
        address presaleAddress;
        string description;
        bool isCertified;
    }

    modifier onlyDev() {
        require(owner() == msg.sender || msg.sender == devAddress, "onlyDev");
        _;
    }

    modifier onlyPresale() {
        require(isPresale[msg.sender], "Not presale");
        _;
    }

    modifier onlyFactory() {
        require(factoryAddress == msg.sender, "onlyFactory");
        _;
    }

    constructor(address _dev, address payable _vault, address _uniswapRouter, address _tether) {
        require(_dev != address(0));
        require(_vault != address(0));
        devAddress = _dev;
        lessVault = _vault;
        uniswapRouter = _uniswapRouter;
        tether = _tether;
    }

    function setFactoryAddress(address _factory) external onlyDev {
        require(_factory != address(0));
        factoryAddress = _factory;
    }

    function setUsdtFee(uint32 _newAmount) external onlyDev {
        require(_newAmount > 0, "Wrong parameter");
        usdtFee = _newAmount;
    }

    function getUsdtFee() external view onlyFactory returns(uint256, address) {
        return (usdtFee, tether);
    }

    function setTetherAddress(address _newAddress) external onlyDev {
        require(_newAddress != address(0), "wrong parameter");
        tether = _newAddress;
    }

    function setMinStakeTime(uint256 _new) external onlyDev {
        minStakeTime = _new;
    }

    function setMinUnstakeTime(uint256 _new) external onlyDev {
        minUnstakeTime = _new;
    }

    function addPresaleAddress(address _presale, bytes32 _title, string memory _description, bool _type)
        external
        onlyFactory
        returns (uint256)
    {
        presaleAddresses.push(PresaleInfo(_title, _presale, _description, _type));
        isPresale[_presale] = true;
        //uint256 _id = presaleAddresses.length - 1;
        //forAllPoolsSearch[_id] = PresaleInfo(_title, _presale, _description, _type);
        return presaleAddresses.length - 1;
    }

    function getPresalesCount() external view returns (uint256) {
        return presaleAddresses.length;
    }

    function getPresaleAddress(uint256 id) external view returns (address) {
        return presaleAddresses[id].presaleAddress;
    }

    function setPresaleAddress(uint256 id, address _newAddress)
        external
        onlyDev
    {
        presaleAddresses[id].presaleAddress = _newAddress;
    }

    function changeDev(address _newDev) external onlyDev {
        require(_newDev != address(0), "Wrong new address");
        devAddress = _newDev;
    }

    function setVotingTime(uint256 _newVotingTime) external onlyDev {
        require(_newVotingTime > 0, "Wrong new time");
        votingTime = _newVotingTime;
    }

    function setStakingAddress(address _staking) external onlyDev {
        require(_staking != address(0));
        safeStakingPool = IStaking(_staking);
    }

    function getVotingTime() public view returns(uint256){
        return votingTime;
    }

    function getMinInvestorBalance() external view returns (uint256) {
        return minInvestorBalance;
    }

    function getMinUnstakeTime() external view returns (uint256) {
        return minUnstakeTime;
    }

    function getDev() external view onlyFactory returns (address) {
        return devAddress;
    }

    function getMinVoterBalance() external view returns (uint256) {
        return minVoterBalance;
    }

    function getMinYesVotesThreshold() external view returns (uint256) {
        uint256 stakedAmount = safeStakingPool.getStakedAmount();
        return stakedAmount / 10;
    }

    function getFactoryAddress() external view returns (address) {
        return factoryAddress;
    }

    function getMinCreatorStakedBalance() external view returns (uint256) {
        return minCreatorStakedBalance;
    }

    function getStakedSafeBalance(address sender)
        public
        view
        returns (uint256)
    {
        uint256 balance;
        uint256 lastStakedTimestamp;
        (balance, lastStakedTimestamp, ) = safeStakingPool.getAccountInfo(
            address(sender)
        );

        if (lastStakedTimestamp + minStakeTime <= block.timestamp) {
            return balance;
        }
        return 0;
    }

    function getUniswapRouter() external view returns (address) {
        return uniswapRouter;
    }

    function setUniswapRouter(address _uniswapRouter) external onlyDev {
        uniswapRouter = _uniswapRouter;
    }

    function calculateFee(uint256 amount) external view onlyPresale returns(uint256){
        return amount * feePercent / 100;
    }

    function getVaultAddress() external view onlyPresale returns(address payable){
        return lessVault;
    }

    function getArrForSearch() external view returns(PresaleInfo[] memory) {
        return presaleAddresses;
    }
}

// File: contracts\Staking.sol


pragma solidity ^0.8.0;





contract Staking is ReentrancyGuard {
    using Address for address;

    IERC20 public safeToken;
    LessLibrary public safeLibrary;
    uint256 private totalStakedAmount;

    event Staked(address indexed from, uint256 amount);
    event Unstaked(address indexed from, uint256 amount);

    struct AccountInfo {
        uint256 balance;
        uint256 lastStakedTimestamp;
        uint256 lastUnstakedTimestamp;
    }
    mapping(address => AccountInfo) public accountInfos;
    modifier onlyDev() {
        require(
            msg.sender == safeLibrary.getFactoryAddress() ||
                msg.sender == safeLibrary.owner() ||
                msg.sender == safeLibrary.getDev(),
            "Only Dev"
        );
        _;
    }

    constructor(address _safeToken, address _safeLibrary) {
        safeToken = IERC20(_safeToken);
        safeLibrary = LessLibrary(_safeLibrary);
    }

    function stake(uint256 _amount) public nonReentrant {
        require(_amount > 0, "Invalid amount");
        require(safeToken.balanceOf(msg.sender) >= _amount, "Invalid balance");

        AccountInfo storage account = accountInfos[msg.sender];
        safeToken.transferFrom(msg.sender, address(this), _amount);
        account.balance = account.balance + _amount;
        totalStakedAmount += _amount;

        if (account.lastUnstakedTimestamp == 0) {
            account.lastUnstakedTimestamp = block.timestamp;
        }
        account.lastStakedTimestamp = block.timestamp;
        emit Staked(msg.sender, _amount);
    }

    function unstake(uint256 _amount) external nonReentrant {
        AccountInfo storage account = accountInfos[msg.sender];
        uint256 minUnstakeTime = safeLibrary.getMinUnstakeTime();

        require(
            !address(msg.sender).isContract(),
            "Please use your individual account"
        );

        require(account.balance > 0, "Nothing to unstake");
        require(_amount > 0, "Invalid amount");
        /*require(
            minUnstakeTime == 0 ||
                (account.lastUnstakedTimestamp + minUnstakeTime <=
                    block.timestamp),
            "Invalid Unstake Time"
        );*/
        if (account.balance < _amount) {
            _amount = account.balance;
        }
        account.balance = account.balance - _amount;
        totalStakedAmount -= _amount;
        uint256 feeAmount = 0;
        if(account.lastUnstakedTimestamp + minUnstakeTime <= block.timestamp) {
            feeAmount = _amount / 100;
            _amount = _amount - feeAmount;

        }
        account.lastUnstakedTimestamp = block.timestamp;

        if (account.balance == 0) {
            account.lastStakedTimestamp = 0;
            account.lastUnstakedTimestamp = 0;
        }
        if (feeAmount != 0){
            safeToken.transfer(safeLibrary.owner(), feeAmount);
        }
        safeToken.transfer(msg.sender, _amount);
        emit Unstaked(msg.sender, _amount);
    }

    function setLibraryAddress(address _newInfo) external onlyDev {
        safeLibrary = LessLibrary(_newInfo);
    }

    function getStakedAmount() external view returns(uint256) {
        return totalStakedAmount;
    }
}

// File: @openzeppelin\contracts\utils\cryptography\ECDSA.sol


pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// File: contracts\interface.sol


pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (
        uint amountA, 
        uint amountB, 
        uint liquidity
    );

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (
        uint amountToken, 
        uint amountETH, 
        uint liquidity
    );

    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IUniswapV2Factory02 {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function approve(address guy, uint wad) external returns (bool);
}

interface IPresaleFactory {
    function isSigner(address _address) external view returns (bool);
}

// File: contracts\PresalePublic.sol

pragma solidity ^0.8.0;






contract PresalePublic is ReentrancyGuard {
    uint256 public id;

    address payable public factoryAddress;
    address public platformOwner;
    LessLibrary public lessLib;

    PresaleInfo public generalInfo;
    PresaleUniswapInfo public uniswapInfo;
    PresaleStringInfo public stringInfo;
    IntermediateVariables public intermediate;

    bool private initiate;
    bool private withdrawedFunds;
    address private lpAddress;
    uint256 private lpAmount;
    address private devAddress;
    uint256 private tokenMagnitude;
    address private tokenAddress;
    address private WETHAddress;
    address private bnbAddress = address(0);

    //constants for unique signatures
    uint32 private tier12Investconst = 120006;
    uint32 private tier35Investconst = 3453014;
    uint32 private tier12Registerconst = 126660;
    uint32 private tier35Registerconst = 462104;
    uint32 private lotteryConst = 135384;
    uint32 private votingConst = 203833;

    mapping(address => uint256) public voters;
    mapping(address => bool) public claimed; // if true, it means investor already claimed the tokens or got a refund
    mapping(address => Investment) public investments; // total wei invested per address
    
    mapping(address => bool) public whitelist; //for tiers 3-5

    mapping(address => bool) public whitelistTierOne;
    mapping(address => bool) public whitelistTierTwo;
    address[] public whitelistTierOneArr;
    address[] public whitelistTierTwoArr;
    mapping(bytes32 => bool) public usedSignature;

    TicketsInfo[] public tickets;

    struct TicketsInfo {
        address user;
        uint256 ticketAmount;
    }

    struct PresaleInfo {
        address payable creator;
        IERC20 token;
        uint256 tokenPriceInWei;
        uint256 hardCapInWei;
        uint256 softCapInWei;
        uint256 tokensForSaleLeft;
        uint256 tokensForLiquidityLeft;
        uint256 openTimeVoting;
        uint256 closeTimeVoting;
        uint256 openTimePresale;
        uint256 closeTimePresale;
        uint256 collectedFee;
    }

    struct IntermediateVariables {
        bool cancelled;
        bool liquidityAdded;
        uint256 beginingAmount;
        uint256 raisedAmount;
        uint256 participants;
        uint256 yesVotes;
        uint256 noVotes;
    }

    struct PresaleUniswapInfo {
        uint256 listingPriceInWei;
        uint256 lpTokensLockDurationInDays;
        uint8 liquidityPercentageAllocation;
        uint256 liquidityAllocationTime;
        uint256 unlockTime;
    }

    struct PresaleStringInfo {
        bytes32 saleTitle;
        bytes32 linkTelegram;
        bytes32 linkGithub;
        bytes32 linkTwitter;
        bytes32 linkWebsite;
        string linkLogo;
        string description;
        string whitepaper;
    }

    struct Investment {
        uint256 amountEth;
        uint256 amountTokens;
    }

    modifier onlyFabric() {
        require(factoryAddress == msg.sender);
        _;
    }

    modifier onlyPlatformOwner() {
        require(platformOwner == msg.sender);
        _;
    }

    modifier onlyPresaleCreator() {
        require(msg.sender == generalInfo.creator);
        _;
    }

    modifier onlyOwners() {
        require(
            msg.sender == generalInfo.creator || msg.sender == platformOwner,
            "Only for owners"
        );
        _;
    }

    modifier notCreator() {
        require(msg.sender != generalInfo.creator, "No permition");
        _;
    }

    modifier liquidityAdded() {
        require(intermediate.liquidityAdded, "Add liquidity");
        _;
    }

    modifier onlyWhenOpenVoting() {
        require(block.timestamp <= generalInfo.closeTimeVoting, "Voting closed");
        _;
    }

    modifier onlyWhenOpenPresale() {
        uint256 nowTime = block.timestamp;
        require(
            nowTime >= generalInfo.openTimePresale &&
                nowTime <= generalInfo.closeTimePresale, "No presale open"
        );
        _;
    }

    modifier presaleIsNotCancelled() {
        require(!intermediate.cancelled);
        _;
    }

    modifier votesPassed() {
        require(
            intermediate.yesVotes >= intermediate.noVotes &&
                intermediate.yesVotes >= lessLib.getMinYesVotesThreshold() && block.timestamp >= generalInfo.closeTimeVoting,
            "Votes not passed"
        );
        _;
    }

    modifier openRegister() {
        require(block.timestamp >= generalInfo.openTimePresale - 86400 && block.timestamp < generalInfo.openTimePresale, "Not registration time");
        _;
    }

    modifier inWhitelist() {
        require(whitelist[msg.sender], "not in whitelist");
        _;
    }

    modifier inWhitelistTierOneTwo() {
        require(whitelistTierOne[msg.sender] || whitelistTierTwo[msg.sender], "not in whitelist");
        _;
    }

    constructor(
        address payable _factory,
        address _library,
        address _platformOwner,
        address _devAddress,
        address _tokenAddress,
        address _WETHAddress
    )  {
        require(_factory != address(0));
        require(_library != address(0));
        require(_platformOwner != address(0));
        require(_devAddress != address(0));
        lessLib = LessLibrary(_library);
        factoryAddress = _factory;
        platformOwner = _platformOwner;
        devAddress = _devAddress;
        tokenAddress = _tokenAddress;
        WETHAddress = _WETHAddress;
        //generalInfo.closeTimeVoting = block.timestamp + lessLib.getVotingTime();
    }

    function init(
        address[2] memory _creatorToken,
        uint256[9] memory _priceTokensForSaleLiquiditySoftHardOpenOpenCloseFee
    ) external onlyFabric {
        require(
            _creatorToken[0] != address(0) && _creatorToken[1] != address(0),
            "Wrong addresses"
        );
        require(!initiate, "Function can work only once");
        require(
            _priceTokensForSaleLiquiditySoftHardOpenOpenCloseFee[0] > 0,
            "Price should be more then zero"
        );
        require(
            _priceTokensForSaleLiquiditySoftHardOpenOpenCloseFee[6] > 0 &&
                _priceTokensForSaleLiquiditySoftHardOpenOpenCloseFee[7] > 0 &&
                _priceTokensForSaleLiquiditySoftHardOpenOpenCloseFee[6] <
                _priceTokensForSaleLiquiditySoftHardOpenOpenCloseFee[7],
            "Wrong time presale interval"
        );
        require(
            _priceTokensForSaleLiquiditySoftHardOpenOpenCloseFee[3] > 0 &&
                _priceTokensForSaleLiquiditySoftHardOpenOpenCloseFee[4] > 0,
            "Wron soft or hard cup values"
        );
        require(_priceTokensForSaleLiquiditySoftHardOpenOpenCloseFee[5] >= block.timestamp + 86400, "Wrong open voting time");
        uint256 closeVoting = _priceTokensForSaleLiquiditySoftHardOpenOpenCloseFee[5] + lessLib.getVotingTime();
        require(
            _priceTokensForSaleLiquiditySoftHardOpenOpenCloseFee[6] >= closeVoting,
            "Voting and investment should not overlap"
        );
        require(
            _priceTokensForSaleLiquiditySoftHardOpenOpenCloseFee[1] != 0 &&
                _priceTokensForSaleLiquiditySoftHardOpenOpenCloseFee[2] != 0,
            "Not null tokens amount"
        );
        require(_priceTokensForSaleLiquiditySoftHardOpenOpenCloseFee[8]>0, "No fee");
        generalInfo = PresaleInfo(
            payable(_creatorToken[0]),
            IERC20(_creatorToken[1]),
            _priceTokensForSaleLiquiditySoftHardOpenOpenCloseFee[0],
            _priceTokensForSaleLiquiditySoftHardOpenOpenCloseFee[4],
            _priceTokensForSaleLiquiditySoftHardOpenOpenCloseFee[3],
            _priceTokensForSaleLiquiditySoftHardOpenOpenCloseFee[1],
            _priceTokensForSaleLiquiditySoftHardOpenOpenCloseFee[2],
            _priceTokensForSaleLiquiditySoftHardOpenOpenCloseFee[5],
            closeVoting,
            _priceTokensForSaleLiquiditySoftHardOpenOpenCloseFee[6],
            _priceTokensForSaleLiquiditySoftHardOpenOpenCloseFee[7],
            _priceTokensForSaleLiquiditySoftHardOpenOpenCloseFee[8]
        );

        uint256 tokenDecimals = ERC20(_creatorToken[1]).decimals();
        tokenMagnitude = uint256(10)**uint256(tokenDecimals);
        intermediate.beginingAmount = _priceTokensForSaleLiquiditySoftHardOpenOpenCloseFee[1];
        initiate = true;
    }

    function setUniswapInfo(
        uint256 price,
        uint256 duration,
        uint8 percent,
        uint256 allocationTime
    ) external onlyFabric {
        require(
            price != 0 &&
                percent != 0 &&
                allocationTime > generalInfo.closeTimePresale,
            "Wrong arguments"
        );
        require(duration >= 30, "Duration should be >= 30 days");
        uniswapInfo = PresaleUniswapInfo(
            price,
            duration,
            percent,
            allocationTime,
            0
        );
    }

    function setStringInfo(
        bytes32 _saleTitle,
        bytes32 _linkTelegram,
        bytes32 _linkGithub,
        bytes32 _linkTwitter,
        bytes32 _linkWebsite,
        string calldata _linkLogo,
        string calldata _description,
        string calldata _whitepaper
    ) external onlyFabric {
        stringInfo = PresaleStringInfo(
            _saleTitle,
            _linkTelegram,
            _linkGithub,
            _linkTwitter,
            _linkWebsite,
            _linkLogo,
            _description,
            _whitepaper
        );
    }

    function isWhitelisting() public view returns(bool) {
        return block.timestamp <= generalInfo.openTimePresale;
    }

    function getWhitelistTierOneLength() 
        public
        view
    returns (uint256) {
        return whitelistTierOneArr.length;     
    }

    function getWhitelistTierTwoLength() 
        public
        view
    returns (uint256) {
        return whitelistTierTwoArr.length;     
    }

    function registerTierOneTwo(uint256 _tokenAmount, bytes memory _signature) external openRegister {
        require(!usedSignature[keccak256(_signature)]);
        require(
            _verifySigner(abi.encodePacked(_tokenAmount, msg.sender, address(this), tier12Registerconst), _signature),
            "Register: invalid signature"
        );
        tickets.push(TicketsInfo(msg.sender, _tokenAmount/500));
        if (_tokenAmount >= 1000 * tokenMagnitude &&  _tokenAmount < 5000 * tokenMagnitude) {
            require(!whitelistTierOne[msg.sender], "You're already in whitelist");
            whitelistTierOne[msg.sender] = true;
            whitelistTierOneArr.push(msg.sender);
        } else if (_tokenAmount >= 5000 * tokenMagnitude) {
            require(!whitelistTierTwo[msg.sender], "You're already in whitelist");
            whitelistTierTwo[msg.sender] = true;
            whitelistTierTwoArr.push(msg.sender);
        }
        usedSignature[keccak256(_signature)] = true;
    }

    function register(uint256 _tokenAmount, bytes memory _signature) external openRegister {
        require(!usedSignature[keccak256(_signature)]);
        require(
            _verifySigner(abi.encodePacked(_tokenAmount, msg.sender, address(this), tier35Registerconst), _signature),
            "Register: invalid signature"
        );
        require(!whitelist[msg.sender], "You're in whitelist");
        whitelist[msg.sender] = true;
        usedSignature[keccak256(_signature)] = true;
    }

    function vote(bool _yes, uint256 _stakingAmount, bytes memory _signature) external onlyWhenOpenVoting presaleIsNotCancelled notCreator{
        require(_verifySigner(abi.encodePacked(_stakingAmount, msg.sender, address(this), votingConst), _signature));
        uint256 safeBalance = _stakingAmount;

        require(
            safeBalance >= lessLib.getMinVoterBalance(),
            "Not enough Less to vote"
        );
        require(voters[msg.sender] == 0, "Vote already casted");

        voters[msg.sender] = safeBalance;
        if (_yes) {
            intermediate.yesVotes = intermediate.yesVotes + safeBalance;
        } else {
            intermediate.noVotes = intermediate.noVotes + safeBalance;
        }
    }

    
    function _isLotteryWinner(uint256 _tokenAmount, bytes memory _signature) 
    public 
    view
    returns(bool) 
    {
        return _verifySigner(abi.encodePacked(_tokenAmount, msg.sender, address(this), lotteryConst), _signature);
    }

    // _tokenAmount only for non bnb tokens
    function invest(uint256 _tokenAmount, bytes memory _signature, uint256 _stakedAmount, bool _isTierOneTwo)
        public
        payable
        presaleIsNotCancelled
        onlyWhenOpenPresale
        votesPassed
        nonReentrant
        notCreator
    {
        require(!usedSignature[keccak256(_signature)]);
        if (_isTierOneTwo) {
            require(_verifySigner(abi.encodePacked(_stakedAmount, msg.sender, address(this), tier12Investconst), _signature));
            require(_isLotteryWinner(_stakedAmount, _signature), "Invest: you aren't a lottery winner");
        } else {
            require(_verifySigner(abi.encodePacked(_stakedAmount, msg.sender, address(this), tier35Investconst), _signature));
        }

        uint256 amount;
        if (tokenAddress == bnbAddress) {
            amount = msg.value;
        } else {
            amount = _tokenAmount;
        }

        address sender = msg.sender;
        uint256 tokensLeft;
        uint256 nowTime = block.timestamp;
        string memory err = "You have no invest permition";
        if(nowTime < generalInfo.openTimePresale + 3600){
            require(_stakedAmount >= 200000*tokenMagnitude, err);
            tokensLeft = intermediate.beginingAmount * 30 / 100;
        }
        else if(nowTime < generalInfo.openTimePresale + 5400){
            require(_stakedAmount < 200000*tokenMagnitude && _stakedAmount >= 50000*tokenMagnitude, err);
            tokensLeft = (intermediate.beginingAmount - generalInfo.tokensForSaleLeft) + (intermediate.beginingAmount * 20 / 100);
        }
        else if(nowTime < generalInfo.openTimePresale + 6300){
            require(_stakedAmount < 50000*tokenMagnitude && _stakedAmount >= 20000*tokenMagnitude, err);
            tokensLeft = (intermediate.beginingAmount - generalInfo.tokensForSaleLeft) + (intermediate.beginingAmount * 15 / 100);
        }
        else if(nowTime < generalInfo.openTimePresale + 6900){
            require(_stakedAmount < 20000*tokenMagnitude && _stakedAmount >= 5000*tokenMagnitude, err);
            tokensLeft = (intermediate.beginingAmount - generalInfo.tokensForSaleLeft) + (intermediate.beginingAmount * 25 / 100);
        }
        else {
            tokensLeft = generalInfo.tokensForSaleLeft;
        }
        uint256 reservedTokens = getTokenAmount(amount);
        //tokensLeft = generalInfo.tokensForSaleLeft;
        require(
            intermediate.raisedAmount < generalInfo.hardCapInWei,
            "Hard cap reached"
        );
        require(tokensLeft >= reservedTokens, "Not enough tokens left");
        require(amount > 0, "Not null invest, please");
        uint256 safeBalance = _stakedAmount;
        /*require(
            msg.value <=
                (tokensLeft * generalInfo.tokenPriceInWei) / tokenMagnitude,
            "Not enough tokens left"
        );*/
        uint256 totalInvestmentInWei =
            investments[sender].amountEth + amount;
        /*require(
            totalInvestmentInWei >= minInvestInWei ||
                raisedAmount >= hardCap - 1 ether,
            "Min investment not reached"
        );
        require(
            maxInvestInWei == 0 || totalInvestmentInWei <= maxInvestInWei,
            "Max investment reached"
        );*/

        uint256 minInvestorBalance = lessLib.getMinInvestorBalance();
        require(
            minInvestorBalance == 0 || safeBalance >= minInvestorBalance,
            "Stake LessTokens"
        );

        if (investments[sender].amountEth == 0) {
            intermediate.participants += 1;
        }

        intermediate.raisedAmount += amount;
        investments[sender].amountEth = totalInvestmentInWei;
        investments[sender].amountTokens += reservedTokens;
        generalInfo.tokensForSaleLeft = tokensLeft - reservedTokens;

        usedSignature[keccak256(_signature)] = true;
    }

    function withdrawInvestment(address payable to, uint256 amount)
        external
        votesPassed
        nonReentrant
    {
        require(
            block.timestamp >= generalInfo.openTimePresale,
            "Not yet opened"
        );
        require(
            investments[msg.sender].amountEth != 0,
            "You are not an invesor"
        );
        require(
            investments[msg.sender].amountEth >= amount,
            "You have not invest so much"
        );
        require(amount > 0, "Enter not zero amount");
        if (!intermediate.cancelled) {
            require(
                intermediate.raisedAmount < generalInfo.softCapInWei,
                "Couldn't withdraw investments after softCap collection"
            );
        }
        require(to != address(0), "Enter not a zero address");
        if (investments[msg.sender].amountEth - amount == 0) {
            intermediate.participants -= 1;
        }
        to.transfer(amount);
        uint256 reservedTokens = getTokenAmount(amount);
        intermediate.raisedAmount -= amount;
        investments[msg.sender].amountEth -= amount;
        investments[msg.sender].amountTokens -= reservedTokens;
        generalInfo.tokensForSaleLeft += reservedTokens;
    }

    function claimTokens() external nonReentrant liquidityAdded {
        require(
            block.timestamp >= generalInfo.closeTimePresale,
            "Wait presale close time"
        );
        require(
            investments[msg.sender].amountEth != 0,
            "You are not an invesor"
        );
        require(
            !claimed[msg.sender],
            "You've already claimed your tokens"
        );
        claimed[msg.sender] = true; // make sure this goes first before transfer to prevent reentrancy
        generalInfo.token.transfer(
            msg.sender,
            investments[msg.sender].amountTokens
        );
    }

    function addLiquidity() external presaleIsNotCancelled nonReentrant {
        require(msg.sender == devAddress, "Function is only for backend");
        require(
            uniswapInfo.liquidityAllocationTime <= block.timestamp,
            "Too early to adding liquidity"
        );

        require(
            block.timestamp >= generalInfo.closeTimePresale,
            "Wait for presale closing"
        );
        require(
            !intermediate.liquidityAdded,
            "Liquidity has been already added"
        );
        uint256 raisedAmount = intermediate.raisedAmount;
        if (raisedAmount == 0) {
            intermediate.liquidityAdded = true;
            return;
        }

        uint256 liqPoolEthAmount =
            (raisedAmount * uniswapInfo.liquidityPercentageAllocation) / 100;
        uint256 liqPoolTokenAmount =
            (liqPoolEthAmount * tokenMagnitude) / uniswapInfo.listingPriceInWei;

        require(
            generalInfo.tokensForLiquidityLeft >= liqPoolTokenAmount,
            "Error liquidity"
        );

        IUniswapV2Router02 uniswapRouter =
            IUniswapV2Router02(address(lessLib.getUniswapRouter()));

        IERC20 token = generalInfo.token;

        token.approve(address(uniswapRouter), liqPoolTokenAmount);

        IWETH wETH = IWETH(WETHAddress);
        wETH.deposit{value: liqPoolEthAmount}();

        wETH.approve(WETHAddress, liqPoolEthAmount);

        (, , lpAmount) = uniswapRouter.addLiquidity(
            address(token),
            WETHAddress,
            liqPoolTokenAmount,
            liqPoolEthAmount,
            0,
            0,
            payable(address(this)),
            block.timestamp + 15 minutes
        );

        //require(lpAmount != 0, "lpAmount not null");

        IUniswapV2Factory02 uniswapFactory =
            IUniswapV2Factory02(uniswapRouter.factory());
        lpAddress = uniswapFactory.getPair(
            uniswapRouter.WETH(),
            address(token)
        );

        generalInfo.tokensForLiquidityLeft -= liqPoolTokenAmount;
        intermediate.liquidityAdded = true;
        uniswapInfo.unlockTime =
            block.timestamp +
            (uniswapInfo.lpTokensLockDurationInDays * 24 * 60 * 60);
    }

    function collectFundsRaised()
        external
        presaleIsNotCancelled
        nonReentrant
        onlyPresaleCreator
        liquidityAdded
    {
        require(!withdrawedFunds, "Function works only once");
        uint256 collectedBalance = payable(address(this)).balance;
        if (collectedBalance > 0) {
            uint256 fee = lessLib.calculateFee(collectedBalance);
            lessLib.getVaultAddress().transfer(fee);
            generalInfo.creator.transfer(payable(address(this)).balance - generalInfo.collectedFee);
        }
        _withdrawUnsoldTokens();
        withdrawedFunds = true;
    }

    function refundLpTokens()
        external
        presaleIsNotCancelled
        nonReentrant
        onlyPresaleCreator
        liquidityAdded
    {
        require(lpAmount != 0, "LP Tokens has been already claimed");
        require(block.timestamp >= uniswapInfo.unlockTime, "Too early");
        require(
            IERC20(lpAddress).transfer(generalInfo.creator, lpAmount),
            "Couldn't get your tokens"
        );
        lpAmount = 0;
    }

    /*function getUnsoldTokens()
        external
        presaleIsNotCancelled
        nonReentrant
        liquidityAdded
        onlyOwners
    {
        uint256 unsoldTokensAmount =
            generalInfo.tokensForSaleLeft + generalInfo.tokensForLiquidityLeft;
        if (unsoldTokensAmount > 0) {
            generalInfo.token.transfer(generalInfo.creator, unsoldTokensAmount);
        }
    }*/

    function collectFee() external nonReentrant {
        require(generalInfo.collectedFee != 0, "Fee has already withdrawn");
        if (intermediate.yesVotes >= intermediate.noVotes &&
                intermediate.yesVotes >= lessLib.getMinYesVotesThreshold() && block.timestamp >= generalInfo.closeTimeVoting && !intermediate.cancelled) {
                    payable(platformOwner).transfer(generalInfo.collectedFee);
                }
        else {
            payable(generalInfo.creator).transfer(generalInfo.collectedFee);
            intermediate.cancelled = true;
        }
        //payable(platformOwner).transfer(generalInfo.collectedFee);
        generalInfo.collectedFee = 0;
    }

    function changeCloseTimeVoting(uint256 _newCloseTime)
        external
        presaleIsNotCancelled
        onlyOwners
    {
        uint256 openTimePresale = generalInfo.openTimePresale;
        require(
            block.timestamp < openTimePresale,
            "Presale has already beginning"
        );
        require(
            _newCloseTime <= openTimePresale,
            "Voting and investment should not overlap"
        );
        generalInfo.closeTimeVoting = _newCloseTime;
    }

    function changePresaleTime(uint256 _newOpenTime, uint256 _newCloseTime)
        external
        presaleIsNotCancelled
        onlyOwners
    {
        require(
            block.timestamp < generalInfo.openTimePresale,
            "Presale has already beginning"
        );
        require(
            generalInfo.closeTimeVoting < _newOpenTime,
            "Wrong new open presale time"
        );
        require(_newCloseTime > _newOpenTime, "Wrong new parameters");
        require(
            _newCloseTime < uniswapInfo.liquidityAllocationTime,
            "Wrong new close presale time"
        );
        generalInfo.openTimePresale = _newOpenTime;
        generalInfo.closeTimePresale = _newCloseTime;
    }

    function cancelPresale() external presaleIsNotCancelled onlyOwners {
        _withdrawUnsoldTokens();
        intermediate.cancelled = true;
    }

    function getPresaleId() external view returns (uint256) {
        return id;
    }

    function setPresaleId(uint256 _id) external onlyFabric {
        if(id != 0)
        {
            require(id != _id, "Wrong parameter");
        }
        id = _id;
    }

    function getMyVote() external view returns(uint256) {
        return voters[msg.sender];
    }

    function getGenInfo() external view returns(uint256,uint256,uint256) {
        return (generalInfo.tokensForSaleLeft, generalInfo.tokensForLiquidityLeft, generalInfo.collectedFee);
    }

    function getTokenAmount(uint256 _weiAmount)
        internal
        view
        returns (uint256)
    {
        /*uint256 amount = lessLib.getStakedSafeBalance(msg.sender);
        uint256 discount = 0;
        uint256 pricePerToken = generalInfo.tokenPriceInWei;
        if (amount < 15000) {
            return (_weiAmount * tokenMagnitude) / pricePerToken;
        } else if (amount >= 15000 && amount < 75000) {
            return (_weiAmount * tokenMagnitude) / pricePerToken;
        } else if (amount >= 75000 && amount < 150000) {
            discount = (pricePerToken * 5) / 100;
            return (_weiAmount * tokenMagnitude) / (pricePerToken - discount);
        } else if (amount >= 150000 && amount < 325000) {
            discount = (pricePerToken * 7) / 100;
            return (_weiAmount * tokenMagnitude) / (pricePerToken - discount);
        } else if (amount >= 700000) {
            discount = pricePerToken / 10;
            return (_weiAmount * tokenMagnitude) / (pricePerToken - discount);
        }

        return 0;*/

        return (_weiAmount * tokenMagnitude) / generalInfo.tokenPriceInWei;
    }

    function _withdrawUnsoldTokens() internal {
        uint256 unsoldTokensAmount =
            generalInfo.tokensForSaleLeft + generalInfo.tokensForLiquidityLeft;
        if (unsoldTokensAmount > 0) {
            generalInfo.token.transfer(generalInfo.creator, unsoldTokensAmount);
        }
    }

    function _verifySigner(bytes memory data, bytes memory signature)
        public
        view
        returns (bool)
    {
        IPresaleFactory presaleFactory = IPresaleFactory(factoryAddress);
        address messageSigner =
            ECDSA.recover(keccak256(data), signature);
        require(
            presaleFactory.isSigner(messageSigner),
            "Signer is not authorised"
        );
        return true;
    }
}

// File: contracts\PresaleFactory.sol


pragma solidity ^0.8.0;



//import "./PresaleCertified.sol";


contract PresaleFactory {
    event PublicPresaleCreated(
        uint256 presaleId,
        address creator,
        address presaleAddress,
        address tokenAddress,
        uint256 timeForLiquidity
    );
    event CertifiedAutoPresaleCreated(
        uint256 presaleId,
        address creator,
        address tokenAddress,
        uint256 timeForLiquidity
    );
    event CertifiedPresaleCreated(
        uint256 presaleId,
        address creator,
        address tokenAddress
    );
    event Received(address indexed from, uint256 amount);

    LessLibrary public immutable safeLibrary;
    ERC20 public token;
    Staking public safeStakingPool;
    PresalePublic presalePublic;
    //mapping(address => uint256) public lastClaimedTimestamp;
    address public owner;
    mapping (address => bool) private signers; //adresses that can call sign functions 

    constructor(
        address _bscsInfoAddress,
        address _bscsToken,
        address _safeStakingPool
    ) {
        safeLibrary = LessLibrary(_bscsInfoAddress);
        token = ERC20(_bscsToken);
        safeStakingPool = Staking(_safeStakingPool);
        owner = msg.sender;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }


    struct PresaleInfo {
        address tokenAddress;
        uint256 tokenPriceInWei;
        uint256 hardCapInWei;
        uint256 softCapInWei;
        uint256 openVotingTime;
        uint256 openTime;
        uint256 closeTime;
        uint256 _tokenAmount;
        bytes _signature;
        address WETHAddress;
        /*bool liquidity;
        bool automatically;
        bool whitelisted;
        address[] whitelist;
        bool vesting;*/
    }

    struct CertifiedAddition {
        bool liquidity;
        bool automatically;
        bool vesting;
        bool whitelisted;
        address[] whitelist;
    }

    struct PresalePancakeSwapInfo {
        uint256 listingPriceInWei;
        uint256 lpTokensLockDurationInDays;
        uint8 liquidityPercentageAllocation;
        uint256 liquidityAllocationTime;
    }

    struct PresaleStringInfo {
        bytes32 saleTitle;
        bytes32 linkTelegram;
        bytes32 linkGithub;
        bytes32 linkTwitter;
        bytes32 linkWebsite;
        string linkLogo;
        string description;
        string whitepaper;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyDev {
        require(msg.sender == owner || safeLibrary.getDev() == msg.sender);
        _;
    }

    function createPresalePublic(
        PresaleInfo calldata _info,
        PresalePancakeSwapInfo calldata _cakeInfo,
        PresaleStringInfo calldata _stringInfo
    ) external payable returns (uint256 presaleId) {
        /*require(
            _info.presaleType == 0,
            "Use other function for other presale type"
        );*/
        
        require(presalePublic._verifySigner(abi.encodePacked(address(token), msg.sender, _info._tokenAmount), _info._signature),
                "PresaleFactory: invalid signature");
        //timing check
        require(
                _info.openTime > block.timestamp &&
                _info.openVotingTime + safeLibrary.getVotingTime() + 86400 <= _info.openTime &&
                _info.openTime < _info.closeTime &&
                _info.closeTime < _cakeInfo.liquidityAllocationTime,
            "Wrong timing"
        );
        require(
            _info.tokenPriceInWei > 0 &&
                _info.softCapInWei > 0 &&
                _info.hardCapInWei > 0 &&
                _info.hardCapInWei >= _info.softCapInWei,
            "Wrong parameters"
        );
        uint256 stakedBalance = safeLibrary.getStakedSafeBalance(msg.sender);
        require(
            stakedBalance >= safeLibrary.getMinCreatorStakedBalance(),
            "Stake LESS"
        );

        ERC20 _token = ERC20(_info.tokenAddress);
        PresalePublic presale =
            new PresalePublic(
                payable(address(this)),
                address(safeLibrary),
                safeLibrary.owner(),
                safeLibrary.getDev(),
                address(0),
                _info.WETHAddress
            );

        //uint256 fee;
        uint256 fee = 5 * 10**17;
        /*{
            IUniswapV2Router02 uniswap =
                IUniswapV2Router02(safeLibrary.getUniswapRouter());
            (uint256 feeFromLib, address tether) = safeLibrary.getUsdtFee();
            address[] memory path = new address[](2);
            path[0] = uniswap.WETH();
            path[1] = tether;
            uint256[] memory usdtFee = uniswap.getAmountsIn(feeFromLib, path);
            require(msg.value >= usdtFee[0], "Too low msg.value");
            fee = usdtFee[0];
        }*/
        require(msg.value >= fee && fee > 0, "Not enough ETH");

        uint256 maxLiqPoolTokenAmount =
            ((_info.hardCapInWei *
                _cakeInfo.liquidityPercentageAllocation *
                (uint256(10)**uint256(token.decimals()))) /
                (_cakeInfo.listingPriceInWei * 100));

        uint256 maxTokensToBeSold =
            (((_info.hardCapInWei * 110) / 100) *
                (uint256(10)**uint256(token.decimals()))) /
                _info.tokenPriceInWei;
        uint256 requiredTokenAmount = maxLiqPoolTokenAmount + maxTokensToBeSold;
        require(
            maxLiqPoolTokenAmount > 0 && maxTokensToBeSold > 0,
            "Wrong parameters"
        );
        _token.transferFrom(msg.sender, address(presale), requiredTokenAmount);
        payable(address(presale)).transfer(fee);

        //initialize
        initializePresalePublic(
            presale,
            [maxTokensToBeSold,
            maxLiqPoolTokenAmount,
            fee],
            _info,
            _cakeInfo,
            _stringInfo
        );

        presaleId = safeLibrary.addPresaleAddress(address(presale), _stringInfo.saleTitle, _stringInfo.description, false);
        presale.setPresaleId(presaleId);
        emit PublicPresaleCreated(
            presaleId,
            msg.sender,
            address(presale),
            _info.tokenAddress,
            _cakeInfo.liquidityAllocationTime
        );
    }

    /*function createPresaleCertified(
        PresaleInfo calldata _info,
        PresalePancakeSwapInfo calldata _cakeInfo,
        PresaleStringInfo calldata _stringInfo
    ) external {
        require(
            _info.presaleType == 1,
            "Use other function for other presale type"
        );
        uint256 stakedBalance = safeLibrary.getStakedSafeBalance(msg.sender);
        require(
            stakedBalance >= safeLibrary.getMinCreatorStakedBalance(),
            "Stake LESS"
        );

        ERC20 _token = ERC20(_info.tokenAddress);
        PresaleCertified presale =
            new PresaleCertified(
                address(this),
                address(safeLibrary),
                safeLibrary.owner(),
                safeLibrary.getDev()
            );

        uint256 maxTokensToBeSold =
            (((_info.hardCapInWei * 110) / 100) *
                (uint256(10)**uint256(token.decimals()))) /
                _info.tokenPriceInWei;
        uint256 maxLiqPoolTokenAmount;
        uint256 requiredTokenAmount;
        if (_info.liquidity) {
            maxLiqPoolTokenAmount =
                ((_info.hardCapInWei *
                    _cakeInfo.liquidityPercentageAllocation *
                    (uint256(10)**uint256(token.decimals()))) /
                    _cakeInfo.listingPriceInWei) * 100;
            require(
                maxLiqPoolTokenAmount > 0 && maxTokensToBeSold > 0,
                "Wrong parameters"
            );
            requiredTokenAmount = maxLiqPoolTokenAmount + maxTokensToBeSold;
        } else {
            requiredTokenAmount = maxTokensToBeSold;
            require(requiredTokenAmount > 0, "Wrong parameters");
        }
        _token.transferFrom(msg.sender, address(presale), requiredTokenAmount);

        initializePresaleCertified(
            presale,
            maxTokensToBeSold,
            maxLiqPoolTokenAmount,
            _info,
            _cakeInfo,
            _stringInfo
        );

        uint256 presaleId = safeLibrary.addPresaleAddress(address(presale));
        presale.setPresaleId(presaleId);
        if (_info.liquidity && _info.automatically) {
            emit CertifiedAutoPresaleCreated(presaleId, msg.sender, _info.tokenAddress, _cakeInfo.liquidityAllocationTime);
        } else {
            emit CertifiedPresaleCreated(presaleId, msg.sender, _info.tokenAddress);
        }
    }*/

    function isSigner(address _address)
        public
        view
    returns (bool) {
        return signers[_address];
    }

    function addOrRemoveSigner(address _address, bool _canSign)
        public
        onlyDev
    {
        signers[_address] = _canSign;
    }

    function initializePresalePublic(
        PresalePublic _presale,
        uint256[3] memory _tokensForSaleLiquidityFee,
        PresaleInfo calldata _info,
        PresalePancakeSwapInfo calldata _cakeInfo,
        PresaleStringInfo calldata _stringInfo
    ) internal {
        _presale.init(
            [msg.sender, _info.tokenAddress],
            [
                _info.tokenPriceInWei,
                _tokensForSaleLiquidityFee[0],
                _tokensForSaleLiquidityFee[1],
                _info.softCapInWei,
                _info.hardCapInWei,
                _info.openVotingTime,
                _info.openTime,
                _info.closeTime,
                _tokensForSaleLiquidityFee[2]
            ]
        );
        _presale.setUniswapInfo(
            _cakeInfo.listingPriceInWei,
            _cakeInfo.lpTokensLockDurationInDays,
            _cakeInfo.liquidityPercentageAllocation,
            _cakeInfo.liquidityAllocationTime
        );
        _presale.setStringInfo(
            _stringInfo.saleTitle,
            _stringInfo.linkTelegram,
            _stringInfo.linkGithub,
            _stringInfo.linkTwitter,
            _stringInfo.linkWebsite,
            _stringInfo.linkLogo,
            _stringInfo.description,
            _stringInfo.whitepaper
        );
    }

    /*function initializePresaleCertified(
        PresaleCertified _presale,
        uint256 _tokensForSale,
        uint256 _tokensForLiquidity,
        PresaleInfo calldata _info,
        PresalePancakeSwapInfo calldata _cakeInfo,
        PresaleStringInfo calldata _stringInfo
    ) internal {
        _presale.init(
            [msg.sender,
            _info.tokenAddress],
            [_info.tokenPriceInWei,
            _tokensForSale,
            _tokensForLiquidity,
            _info.softCapInWei,
            _info.hardCapInWei],
            _cakeInfo.liquidityPercentageAllocation,
            [_cakeInfo.listingPriceInWei,
            _cakeInfo.lpTokensLockDurationInDays,
            _cakeInfo.liquidityAllocationTime,
            _info.openTime,
            _info.closeTime],
            _info.whitelist,
            [_info.whitelisted,
            _info.liquidity,
            _info.automatically]
        );
        _presale.setStringInfo(
            _stringInfo.saleTitle,
            _stringInfo.linkTelegram,
            _stringInfo.linkGithub,
            _stringInfo.linkTwitter,
            _stringInfo.linkWebsite,
            _stringInfo.linkLogo,
            _stringInfo.description,
            _stringInfo.whitepaper
        );
    }*/

    /*function claimHodlerFund() external {
        require(address(this).balance > 0);
        require(
            lastClaimedTimestamp[msg.sender] + safeLibrary.getMinClaimTime() <=
                block.timestamp,
            "Do not qualify"
        );

        uint256 totalHodlerBalance =
            safeLibrary.getStakedSafeBalance(msg.sender);

        require(
            totalHodlerBalance >= safeLibrary.getMinRewardQualifyBal() &&
                totalHodlerBalance <= safeLibrary.getMaxRewardQualifyBal(),
            "Do not qualifY"
        );
        lastClaimedTimestamp[msg.sender] = block.timestamp;
        msg.sender.transfer(
            totalHodlerBalance.mul(address(this).balance).div(
                token.totalSupply()
            )
        );
    }*/

    function migrateTo(address payable _newFactory) external onlyDev {
        _newFactory.transfer(address(this).balance);
    }
}