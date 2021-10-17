/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-14
*/

pragma solidity 0.5.16;
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

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _factory;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FactoryTransferred(address indexed previousFactory, address indexed newFactory);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        _factory = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function factory() public view returns (address) {
        return _factory;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyFactory() {
        require(isFactory(), "Ownable: caller is not the factory");
        _;
    }

    modifier onlyFactoryOrOwner() {
        require(isFactory() || isOwner(), "Ownable: caller is not the factory");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function isFactory() public view returns (bool) {
        return _msgSender() == _factory;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function renounceFactory() public onlyFactory {
        emit FactoryTransferred(_owner, address(0));
        _factory = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function setOwnerOnce(address newOwner) public onlyFactory {
        _owner = newOwner;
    }

    function setFactory(address newFactory) public onlyOwner {
        _factory = newFactory;
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
    function mint(address account, uint amount) external;

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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}
interface IERC1155{
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}
interface IERC721{
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    function mintNFT(uint256 id, address user) external returns (uint256);

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

interface IStats {
    function incrIIStats(uint256 k, uint256 v) external returns (uint256);
    function decrIIStats(uint256 k, uint256 v) external returns (uint256);
    function incrAIStats(address k, uint256 v) external returns (uint256);
    function decrAIStats(address k, uint256 v) external returns (uint256);
    function incrAIIStats(address addr, uint256 k, uint256 v) external returns (uint256);
    function decrAIIStats(address addr, uint256 k, uint256 v) external returns (uint256);
    function incrAAIStats(address addr0, address addr1, uint256 v) external returns (uint256);
    function decrAAIStats(address addr0, address addr1, uint256 v) external returns (uint256);
    function incrIAIStats(uint256 k, address addr1, uint256 v) external returns (uint256);
    function decrIAIStats(uint256 k, address addr1, uint256 v) external returns (uint256);
    function setIAAStats(uint256 k, address addr1, address addr2) external returns (address);
    function getIIStats(uint256 k) external view returns (uint256);
    function getAIStats(address addr) external view returns (uint256);
    function getAAIStats(address addr0, address addr1) external view returns (uint256);
    function getAIIStats(address addr, uint256 k) external view returns (uint256);
    function getIAIStats(uint256 k, address addr) external view returns (uint256);
    function getIAAStats(uint256 k, address addr) external view returns (address);
    function addMinter(address _minter) external;
    function removeMinter(address _minter) external;
}

contract SupeNFTAirdrop is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    event Initialize(IERC721 _nftToken, IStats _stats, IERC20 _lion, IERC20 _supe, IERC20 _tlp);
    event InitializeParams(uint256 _t1, uint256 _t2);
    event RewardAdded(uint256 amountA, uint256 amountB, uint256 liq, uint256 reward);

    IERC20 public lion = IERC20(0x0);
    IERC20 public supe = IERC20(0x0);
    IERC20 public tlp = IERC20(0x0);

    uint256 public constant NORMAL_NFT_ID = 10000;
    uint256 public constant RARE_NFT_ID = 100000;

    uint256 public FROG_NFT_NOW_ID = 200011;
    uint256 public FROG_NFT_END_ID = 210000;

    uint256 public GAUR_NFT_NOW_ID = 100300011;
    uint256 public GAUR_NFT_END_ID = 100310000;

    uint256 public BOY_NFT_NOW_ID = 300800011;
    uint256 public BOY_NFT_END_ID = 300801000;

    uint256 public GIRL_NFT_NOW_ID = 300600011;
    uint256 public GIRL_NFT_END_ID = 300601000;

    uint256 public MAX_LION = 1 * 10**8 * 10**18;
    uint256 public NOW_LION = 0;
    uint256 public MAX_SUPE = 10000 * 10**18;
    uint256 public NOW_SUPE = 0;
    uint256 public MAX_TLP = 100 * 10**8 * 10**18;
    uint256 public NOW_TLP = 0;

    uint256 public constant STATS_TYPE_INVITE_RELATION = 5;
    uint256 public constant STATS_TYPE_INVITE_1ST_COUNT = 6;
    uint256 public constant STATS_TYPE_INVITE_2ND_COUNT = 7;
    uint256 public constant STATS_TYPE_INVITE_1ST_REWARD_AMOUNT = 8;
    uint256 public constant STATS_TYPE_INVITE_2ND_REWARD_AMOUNT = 9;
    uint256 public constant STATS_TYPE_INVITE_ZERO_REWARD_AMOUNT = 10;
    uint256 public constant STATS_TYPE_INVITE_1ST_TOTAL_REWARD = 11;
    uint256 public constant STATS_TYPE_INVITE_2ND_TOTAL_REWARD = 12;
    uint256 public constant STATS_TYPE_INVITE_ZERO_TOTAL_REWARD = 13;
    uint256 public constant STATS_TYPE_INVITE_1ST_TODAY_REWARD = 14 * 10 ** 18;
    uint256 public constant STATS_TYPE_INVITE_2ND_TODAY_REWARD = 15 * 10 ** 18;
    uint256 public constant STATS_TYPE_INVITE_ZERO_TODAY_REWARD = 16 * 10 ** 18;

    mapping (address => bool) public normalClaimed;
    mapping (address => bool) public rareClaimed;
    uint256 public normalThreshold = 3;
    uint256 public rareThreshold = 30;
    IERC721 public NFTToken = IERC721(0x0);
    IStats public stats = IStats(0x0);

    constructor() public{

    }
    function() external payable{
    }
    function initialize(IERC721 _nftToken, IStats _stats, IERC20 _lion, IERC20 _supe, IERC20 _tlp) external onlyFactoryOrOwner{
        NFTToken = _nftToken;
        stats = _stats;
        emit Initialize(_nftToken, _stats, _lion, _supe, _tlp);
    }
    function initializeParams(uint256 _normalThreshold, uint256 _rareThreshold) external onlyFactoryOrOwner{
        normalThreshold = _normalThreshold;
        rareThreshold = _rareThreshold;
        emit InitializeParams(_normalThreshold, _rareThreshold);
    }
    function initializeNFTID(uint256 _FROG_NFT_END_ID, uint256 _GAUR_NFT_END_ID, uint256 _BOY_NFT_END_ID, uint256 _GIRL_NFT_END_ID, uint256 _MAX_LION, uint256 _MAX_SUPE, uint256 _MAX_TLP) external onlyFactoryOrOwner{
        FROG_NFT_END_ID = _FROG_NFT_END_ID;
        GAUR_NFT_END_ID = _GAUR_NFT_END_ID;
        BOY_NFT_END_ID = _BOY_NFT_END_ID;
        GIRL_NFT_END_ID = _GIRL_NFT_END_ID;
        MAX_LION = _MAX_LION;
        MAX_SUPE = _MAX_SUPE;
        MAX_TLP = _MAX_TLP;
    }
    function claimNormal() public returns (bool){
        require(!_isContract(msg.sender), "NFT airdrop: call to contract");
        if(normalClaimed[msg.sender]){
            return true;
        }
        uint256 seed = uint256(msg.sender);
        uint256 nftID = 0;
        if(seed % 100 < 5){
            if(FROG_NFT_NOW_ID <= FROG_NFT_END_ID){
                nftID = FROG_NFT_NOW_ID;
                FROG_NFT_NOW_ID = FROG_NFT_NOW_ID + 1;
            }else if(GAUR_NFT_NOW_ID <= GAUR_NFT_END_ID){
                nftID = GAUR_NFT_NOW_ID;
                GAUR_NFT_NOW_ID = GAUR_NFT_NOW_ID + 1;
            }else{
                require(false, "nft claimed empty 1");
            }
            NFTToken.mintNFT(nftID, msg.sender);
            normalClaimed[msg.sender] = true;
            return true;
        }else if(seed % 100 < 10){
            if(GAUR_NFT_NOW_ID <= GAUR_NFT_END_ID){
                nftID = GAUR_NFT_NOW_ID;
                GAUR_NFT_NOW_ID = GAUR_NFT_NOW_ID + 1;
            }else if(FROG_NFT_NOW_ID <= FROG_NFT_END_ID){
                nftID = FROG_NFT_NOW_ID;
                FROG_NFT_NOW_ID = FROG_NFT_NOW_ID + 1;
            }else{
                require(false, "nft claimed empty 2");
            }
            NFTToken.mintNFT(nftID, msg.sender);
            normalClaimed[msg.sender] = true;
            return true;
        }else{
            if(stats.getIAIStats(STATS_TYPE_INVITE_1ST_COUNT, msg.sender) >= normalThreshold){
                if(seed % 2 == 0){
                    if(FROG_NFT_NOW_ID <= FROG_NFT_END_ID){
                        nftID = FROG_NFT_NOW_ID;
                        FROG_NFT_NOW_ID = FROG_NFT_NOW_ID + 1;
                    }else if(GAUR_NFT_NOW_ID <= GAUR_NFT_END_ID){
                        nftID = GAUR_NFT_NOW_ID;
                        GAUR_NFT_NOW_ID = GAUR_NFT_NOW_ID + 1;
                    }else{
                        require(false, "nft claimed empty 3");
                    }
                    NFTToken.mintNFT(nftID, msg.sender);
                }else{
                    if(GAUR_NFT_NOW_ID <= GAUR_NFT_END_ID){
                        nftID = GAUR_NFT_NOW_ID;
                        GAUR_NFT_NOW_ID = GAUR_NFT_NOW_ID + 1;
                    }else if(FROG_NFT_NOW_ID <= FROG_NFT_END_ID){
                        nftID = FROG_NFT_NOW_ID;
                        FROG_NFT_NOW_ID = FROG_NFT_NOW_ID + 1;
                    }else{
                        require(false, "nft claimed empty 4");
                    }
                    NFTToken.mintNFT(nftID, msg.sender);
                }
                normalClaimed[msg.sender] = true;
                return true;
            }
        }
        revert();
        // return false;
    }
    function claimRare() public returns (bool){
        require(!_isContract(msg.sender), "NFT airdrop: call to contract");
        if(rareClaimed[msg.sender]){
            return true;
        }
        uint256 seed = uint256(msg.sender);
        uint256 nftID = 0;
        if(stats.getIAIStats(STATS_TYPE_INVITE_1ST_COUNT, msg.sender) >= rareThreshold){
            if(seed % 2 == 0){
                if(BOY_NFT_NOW_ID <= BOY_NFT_END_ID){
                    nftID = BOY_NFT_NOW_ID;
                    BOY_NFT_NOW_ID = BOY_NFT_NOW_ID + 1;
                }else if(GIRL_NFT_NOW_ID <= GIRL_NFT_END_ID){
                    nftID = GIRL_NFT_NOW_ID;
                    GIRL_NFT_NOW_ID = GIRL_NFT_NOW_ID + 1;
                }else{
                    require(false, "nft claimed empty 5");
                }
                NFTToken.mintNFT(nftID, msg.sender);
            }else{
                if(GIRL_NFT_NOW_ID <= GIRL_NFT_END_ID){
                    nftID = GIRL_NFT_NOW_ID;
                    GIRL_NFT_NOW_ID = GIRL_NFT_NOW_ID + 1;
                }else if(BOY_NFT_NOW_ID <= BOY_NFT_END_ID){
                    nftID = BOY_NFT_NOW_ID;
                    BOY_NFT_NOW_ID = BOY_NFT_NOW_ID + 1;
                }else{
                    require(false, "nft claimed empty 6");
                }
                NFTToken.mintNFT(nftID, msg.sender);
            }
            rareClaimed[msg.sender] = true;
            return true;
        }
        revert();
        // return false;
    }
    function isClaimedNormal() public view returns (bool){
        return normalClaimed[msg.sender];
    }
    function isClaimedRare() public view returns (bool){
        return rareClaimed[msg.sender];
    }
    function getParams() public view returns (uint256, uint256){
        return (normalThreshold, rareThreshold);
    }
    function withdrawToken(address token) external onlyFactoryOrOwner {
        IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
    function withdrawETH() external onlyFactoryOrOwner{
        _safeTransferETH(msg.sender, address(this).balance);
    }
    function _safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call.value(value)(new bytes(0));
        require(success, 'GaurswapProxy Transfer: ETH_TRANSFER_FAILED');
    }
    function _isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function setInvitedBy(address invitedBy) public{
        if(invitedBy == address(0x0)){
            return;
        }
        if(invitedBy == msg.sender){
            return;
        }
        if(stats.getIAAStats(STATS_TYPE_INVITE_RELATION, msg.sender) != address(0x0)){
            return;
        }
        if(stats.getIAAStats(STATS_TYPE_INVITE_RELATION, invitedBy) == msg.sender){
            return;
        }
        stats.setIAAStats(STATS_TYPE_INVITE_RELATION, msg.sender, invitedBy);
        stats.incrIAIStats(STATS_TYPE_INVITE_1ST_COUNT, invitedBy, 1);
        uint256 user1STCount = stats.getIAIStats(STATS_TYPE_INVITE_1ST_COUNT, msg.sender);
        if(user1STCount > 0){
            stats.incrIAIStats(STATS_TYPE_INVITE_2ND_COUNT, invitedBy, user1STCount);
        }
        address topInviter = stats.getIAAStats(STATS_TYPE_INVITE_RELATION, invitedBy);
        if(topInviter != address(0x0)){
            stats.incrIAIStats(STATS_TYPE_INVITE_2ND_COUNT, topInviter, 1);
        }
        uint256 seed = uint256(msg.sender);
        if(seed % 3 == 0){
            //lion
            uint256 amount = 100 * 10**18;
            if(NOW_LION >= MAX_LION){
                return;
            }
            lion.safeTransfer(msg.sender, amount);
            NOW_LION = NOW_LION + amount;
        }else if(seed % 3 == 1){
            //supe
            uint256 amount = 1 * 10**16;
            if(NOW_SUPE >= MAX_SUPE){
                return;
            }
            supe.safeTransfer(msg.sender, 1 * 10**16);
            NOW_SUPE = NOW_SUPE + amount;
        }else{
            //tlp
            uint256 amount = 10000 * 10**18;
            if(NOW_TLP >= MAX_TLP){
                return;
            }
            tlp.safeTransfer(msg.sender, 10000 * 10**18);
            NOW_TLP = NOW_TLP + amount;
        }
    }
}