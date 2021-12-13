/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
   */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
   */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
   */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token name.
  */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
   */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor ()  {}

    function _msgSender() internal view returns (address payable) {
        return payable (msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
   */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
   */
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
        (bool success,) = recipient.call{value : amount}("");
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
        target.call{value : weiValue}(data);
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

interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

contract WORMTOKEN is Context, IERC20, Ownable {
    using Address for address;
    using SafeMath for uint256;

    mapping(uint => uint) public lastUpdate;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(uint => uint) public levelUpTokens;
    mapping (uint => uint) public legendaryTimestamp;
    uint deployedTime = 1639094400; //epoch time deployed at 10th Dec 2021 ETC
    uint[] public legendaryArray;
    uint public timeInSecsInADay = 24*60*60;
    uint public burnAmount = 600;
    uint public Nlvl1 = 80;
    uint public Nlvl2 = 122;
    uint public Nlvl3 = 1222;
    uint public Nlvl4 = 12222;
    uint public Nlvl5 = 122222;
    uint public Llvl1 = 800;
    uint public Llvl2 = 1220;
    uint public Llvl3 = 12220;
    uint public Llvl4 = 122220;
    uint public Llvl5 = 1222220;

    event mintOverflown (uint amountGiven, uint notgiven, string message);

    uint private maxSupply = 10000000 * (10 ** 18); // 10 million Breath tokens
    uint256 private _totalSupply;
    uint8 public _decimals;
    string public _symbol;
    string public _name;
    IERC721 private nft;
    uint public _status;
    uint private constant _NOT_ENTERED = 1;
    uint private constant _ENTERED = 2;


    constructor()  {
        _name = "WORM TOKEN";
        _symbol = "$WORM";
        _decimals = 18;
        _totalSupply = 0;
    }

    function setLegendaryTimestamp (uint tokenId, uint _timeInUnix) external onlyOwner {
        legendaryTimestamp[tokenId] = _timeInUnix;
    }

    function pushLLegendary(uint tokenId) external onlyOwner {
        legendaryArray.push(tokenId);
    }

    function setPriceOfNLvl1(uint _amount) external onlyOwner {
        Nlvl1 = _amount;
    }

    function setPriceOfNLvl2(uint _amount) external onlyOwner {
        Nlvl2 = _amount;
    }

    function setPriceOfNLvl3(uint _amount) external onlyOwner {
        Nlvl3 = _amount;
    }

    function setPriceOfNLvl4(uint _amount) external onlyOwner {
        Nlvl4 = _amount;
    }

    function setPriceOfNLvl5(uint _amount) external onlyOwner {
        Nlvl5 = _amount;
    }

    function setNFTTokenAddress(address tokenAddress) external onlyOwner {
        nft = IERC721(tokenAddress);
    }

    /**
     * @dev Returns the bep token owner.
   */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token decimals.
   */
    function decimals() external override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
   */
    function symbol() external override view returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Returns the token name.
  */
    function name() external override view returns (string memory) {
        return _name;
    }

    /**
     * @dev See {ERC20-totalSupply}.
   */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {ERC20-balanceOf}.
   */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function setMaxSupply(uint newMaxSupply) external onlyOwner{
        maxSupply = newMaxSupply;
    }


    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {ERC20-allowance}.
   */
    function allowance(address owner, address spender) external override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {ERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {ERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {ERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {ERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Burn `amount` tokens and decreasing the total supply.
   */
    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   *
   * - `to` cannot be the zero address.
   */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve fromm the zero address");
        require(spender != address(0), "ERC20: approvee to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    function modifytimeInSec(uint _timeInSec) external onlyOwner {
        timeInSecsInADay = _timeInSec;
    }

    function inLegendary (uint tokenId) internal view returns (bool){
        for (uint i=0;i<legendaryArray.length;i++) {
            if (legendaryArray[i] == tokenId) {
                return true;
            }
        }
        return false;
    }

    function mintToOwner (uint _amount) external onlyOwner {
        _mint(msg.sender,_amount);
    }

    function levelUp (uint tokenId) external {
        require (levelUpTokens[tokenId]<4,"Max level reached");
        if (inLegendary(tokenId) == false) {
            if (levelUpTokens[tokenId]==0) {
                require (balanceOf(msg.sender)>= (burnAmount)*10**_decimals);
                burn((burnAmount)*10**_decimals);
                levelUpTokens[tokenId] = levelUpTokens[tokenId]++;
            }
            else if (levelUpTokens[tokenId]==1) {
                require (balanceOf(msg.sender)>= (burnAmount+200)*10**_decimals);
                burn((burnAmount+200)*10**_decimals);
                levelUpTokens[tokenId] = levelUpTokens[tokenId]++;
            }
            else if (levelUpTokens[tokenId]==2) {
                require (balanceOf(msg.sender)>= (burnAmount+400)*10**_decimals);
                burn((burnAmount+400)*10**_decimals);
                levelUpTokens[tokenId] = levelUpTokens[tokenId]++;
            }
            else if (levelUpTokens[tokenId]==3) {
                require (balanceOf(msg.sender)>= (burnAmount+600)*10**_decimals);
                burn((burnAmount+600)*10**_decimals);
                levelUpTokens[tokenId] = levelUpTokens[tokenId]++;
            }
        } else {
            if (levelUpTokens[tokenId]==0) {
                require (balanceOf(msg.sender)>= 1000*10**_decimals);
                burn((burnAmount+400)*10**_decimals);
                levelUpTokens[tokenId] = levelUpTokens[tokenId]++;
            }
            else if (levelUpTokens[tokenId]==1) {
                require (balanceOf(msg.sender)>= 2000*10**_decimals);
                burn((burnAmount+1400)*10**_decimals);
                levelUpTokens[tokenId] = levelUpTokens[tokenId]++;
            }
            else if (levelUpTokens[tokenId]==2) {
                require (balanceOf(msg.sender)>= 3000*10**_decimals);
                burn((burnAmount+2400)*10**_decimals);
                levelUpTokens[tokenId] = levelUpTokens[tokenId]++;
            }
            else if (levelUpTokens[tokenId]==3) {
                require (balanceOf(msg.sender)>= 4000*10**_decimals);
                burn((burnAmount+3400)*10**_decimals);
                levelUpTokens[tokenId] = levelUpTokens[tokenId]++;
            }
        }
    }

    function claimLegendary (uint tokenId) external  {
        require (nft.ownerOf(tokenId)== msg.sender, "Sender not the owner");
        bool isThere = inLegendary(tokenId);
        require (isThere == true, "The token is not legendary array. Please ask the moderator to add your token if its legit");
        require (legendaryTimestamp[tokenId] > 0, "The timestamp of the token is not yet set. Please ask the moderator to set the token timestmap if its legit");
        uint today_count = block.timestamp / timeInSecsInADay;
        uint daysElapsed = today_count - legendaryTimestamp[tokenId];
        uint _amount= getPendingTokensForLegendary(tokenId, daysElapsed);
        require (_amount > 0,"NO positive number of $BREATH tokens are available to mint");
        _mint(msg.sender, _amount);
    }

    function getPendingTokensForLegendary (uint tokenId, uint todayCount) internal view returns (uint) {
        uint value;
        if (levelUpTokens[tokenId] == 0) {
            return todayCount*Llvl1;
        }
        else if (levelUpTokens[tokenId] == 1) {
            return todayCount*Llvl2;
        }
        else if (levelUpTokens[tokenId] == 2) {
            return todayCount*Llvl3;
        }
        else if (levelUpTokens[tokenId] == 3) {
            return todayCount*Llvl4;
        }
        else if (levelUpTokens[tokenId] == 4) {
            return todayCount*Llvl5;
        }
        else {
            return 0;
        }
    }

    function claimToken(uint[] memory tokenIds) external  {

        uint amount = 0;
        uint today_count = block.timestamp / timeInSecsInADay;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (nft.ownerOf(tokenIds[i]) == msg.sender && inLegendary(tokenIds[i]) == false) {
                uint tokenAccumulation = getPendingReward(tokenIds[i],today_count);
                if (tokenAccumulation > 0) {
                    if (maxSupply < _totalSupply + amount + tokenAccumulation) {
                        emit mintOverflown(amount, tokenAccumulation, "Minting Limit Reached");
                        break;
                    }
                    amount += tokenAccumulation;
                    lastUpdate[tokenIds[i]] = today_count;
                }
            }
        }
        require (amount > 0,"NO positive number of $BREATH tokens are available to mint");
        _mint(msg.sender, amount);
    }

    function getPendingReward(uint tokenId, uint todayCount) internal view  returns (uint){
        uint wormsPerDay;
        uint fisherManlevel;
        fisherManlevel = levelUpTokens[tokenId];
        if (lastUpdate[tokenId] == 0) {

            if (fisherManlevel == 0){
                uint daysPassedSinceNFTMinted = block.timestamp - deployedTime;
                daysPassedSinceNFTMinted = (daysPassedSinceNFTMinted / timeInSecsInADay);
                return (daysPassedSinceNFTMinted * Nlvl1 * (10 ** _decimals));
            }
            else if(fisherManlevel ==1){
                uint daysPassedSinceNFTMinted = block.timestamp - deployedTime;
                daysPassedSinceNFTMinted = (daysPassedSinceNFTMinted / timeInSecsInADay);
                return (daysPassedSinceNFTMinted * Nlvl2 * (10 ** _decimals));
            }
            else if(fisherManlevel ==2){
                uint daysPassedSinceNFTMinted = block.timestamp - deployedTime;
                daysPassedSinceNFTMinted = (daysPassedSinceNFTMinted / timeInSecsInADay);
                return (daysPassedSinceNFTMinted * Nlvl3 * (10 ** _decimals));
            }
            else if (fisherManlevel ==3){
                uint daysPassedSinceNFTMinted = block.timestamp - deployedTime;
                daysPassedSinceNFTMinted = (daysPassedSinceNFTMinted / timeInSecsInADay);
                return (daysPassedSinceNFTMinted * Nlvl4 * (10 ** _decimals));
            }
            else if (fisherManlevel ==4) {
                uint daysPassedSinceNFTMinted = block.timestamp - deployedTime;
                daysPassedSinceNFTMinted = (daysPassedSinceNFTMinted / timeInSecsInADay);
                return (daysPassedSinceNFTMinted * Nlvl5 * (10 ** _decimals));
            }
            else {
                return 0;
            }
        } else {
            if (todayCount - lastUpdate[tokenId] >= 1) {
                uint daysElapsedSinceLastUpdate = todayCount - lastUpdate[tokenId];
                if (fisherManlevel == 0) {
                    return daysElapsedSinceLastUpdate * (Nlvl1 * (10 ** _decimals));
                }
                else if (fisherManlevel == 1) {
                    return daysElapsedSinceLastUpdate * (Nlvl2 * (10 ** _decimals));
                }
                else if (fisherManlevel == 2) {
                    return daysElapsedSinceLastUpdate * (Nlvl3 * (10 ** _decimals));
                }
                else if (fisherManlevel == 3) {
                    return daysElapsedSinceLastUpdate * (Nlvl4 * (10 ** _decimals));
                }
                else if (fisherManlevel == 4) {
                    return daysElapsedSinceLastUpdate * (Nlvl5 * (10 ** _decimals));
                }
                else  {
                    return 0;
                }
            } else {
                return 0;
            }
        }
    }
}