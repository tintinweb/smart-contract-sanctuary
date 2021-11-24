/**
 *Submitted for verification at BscScan.com on 2021-11-24
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

contract SupeNFTJiJie is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;


    bool public paused = false;
    bool public claim_enable = false;

    IERC721 public nft_token = IERC721(0x0);
    IERC20 public tlp_token = IERC20(0x0);
    IERC20 public frog_token = IERC20(0x0);
    IERC20 public supe_token = IERC20(0x0);
    address public dev_pool = address(0x96eD0b21d024b82A430386A3A1477324f25f0143);
    address public mint_frog_pool = address(0x5A32C5132B610F2EE8467bc38cBB33Ce6B5227d0);
    uint256 public start_ts = 0;
    uint256 public round_duration = 86400;
    uint256 public open_duration = 7200;
    uint256 public nft_threshold = 0;
    uint256 public supe_threshold = 0;
    uint256 public nft_start_id = 0;
    uint256 public nft_end_id = uint256(-1);
    mapping(address => uint256) public balances;
    mapping(uint256 => PoolInfo) public pools;
    // Info of each pool.
    struct PoolInfo {
        bool created;
        bool ended;
        uint256[] attend_assets;
        uint256[] lucky_assets;
        address[] lucky_accounts;
        uint256[] tlps;
        uint256[] frogs;
        mapping(address => uint256) balances;
        mapping(uint256 => address) asset2account;
        mapping(address => mapping(uint256=>StakeInfo)) stakes;
        mapping(uint256 => mapping(address=>uint256)) wait_claimed;
        mapping(address => mapping(address=>uint256)) claimed;
        mapping(address => bool) attended;
    }
    struct StakeInfo {
        uint256 asset_id;
        uint256 rount_id;
        uint256 start_ts;
        uint256 end_ts;
    }
    
    uint256 public interval = 86400;

    event InitializeTokens(IERC721 _nftToken, IERC20 _tlp, IERC20 _frog, IERC20 _supe);
    event InitializeParams(uint256 _start_ts, uint256 _round_duration, uint256 _open_duration);
    event StakeOne(address _user, uint256 _asset_id, uint256 _start_ts, uint256 _end_ts, uint256 round_id);
    event ExitOne(address _user, uint256 _asset_id, uint256 _start_ts, uint256 _end_ts, uint256 _tlp, uint256 _frog);
    event Claimed(address _account, uint256 _tlp, uint256 _frog);
    event CreateReward(uint256 _round, uint256 _rank, address _account, uint256 _asset_id, uint256 _tlp, uint256 _frog);
    event ClaimReward(uint256 _round, address _account, uint256 _asset_id, uint256 _tlp, uint256 _frog);
    event TestReward(uint256 _attend_count, uint256 _first, uint256 _second, uint256 _third);
   
    constructor() public{}
    function() external payable{}

    function initialize(IERC721 _nftToken, IERC20 _tlp, IERC20 _frog, IERC20 _supe) external onlyFactoryOrOwner{
        nft_token = _nftToken;
        tlp_token = _tlp;
        frog_token = _frog;
        supe_token = _supe;
        emit InitializeTokens(_nftToken, _tlp, _frog, _supe);
    }
    function initialize_dev_pool(address _dev_pool, address _mint_frog_pool) external onlyFactoryOrOwner{
        dev_pool = _dev_pool;
        mint_frog_pool = _mint_frog_pool;
    }
    function initialize_params(uint256 _start_ts, uint256 _round_duration, uint256 _open_duration, uint256 _supe_threshold, uint256 _nft_threshold) external onlyFactoryOrOwner{
        start_ts = _start_ts;
        round_duration = _round_duration;
        open_duration = _open_duration;
        supe_threshold = _supe_threshold;
        nft_threshold = _nft_threshold;
        emit InitializeParams(start_ts, round_duration, open_duration);
    }
    function initialize_nft_id(uint256 _nft_start_id, uint256 _nft_end_id) external onlyFactoryOrOwner{
        nft_start_id = _nft_start_id;
        nft_end_id = _nft_end_id;
    }
    function mint_nft(uint256 _asset_id) public onlyFactoryOrOwner{
        nft_token.mintNFT(_asset_id, msg.sender);
    }
    function stake(uint256[] memory ids) public{
        for (uint256 i = 0; i < ids.length; ++i) {
            stake_one(ids[i]);
        }
    }
    function stake_one(uint256 _asset_id) public checkPaused{
        require(_asset_id >= nft_start_id && _asset_id <= nft_end_id, "asset id invalid");
        uint256 asset_type = ((_asset_id - _asset_id%100000)/100000)%1000;
        require(asset_type!=2 && asset_type!=3 && asset_type!=6 && asset_type!=8, "invalid nft type");
        require(supe_token.balanceOf(msg.sender) >= supe_threshold, "supe balance not enough");
        require(nft_token.balanceOf(msg.sender) + balances[msg.sender] >= nft_threshold, "nft balance of enough");
        require(nft_token.ownerOf(_asset_id) == msg.sender, "not asset owner");
        require(block.timestamp >= start_ts, "not start 0");
        uint256 round_id = (block.timestamp - start_ts)/round_duration;
        uint256 round_start_ts = start_ts + round_id * round_duration;
        require(block.timestamp >= round_start_ts, "not start 1");
        require(block.timestamp < round_start_ts + open_duration, "closed");
        //check created
        if(!pools[round_id].created){
            pools[round_id].created = true;
        }
        require(pools[round_id].stakes[msg.sender][_asset_id].asset_id == 0, "asset has been staked");
        nft_token.safeTransferFrom(msg.sender, dev_pool, _asset_id);
        pools[round_id].stakes[msg.sender][_asset_id] = StakeInfo({
            asset_id: _asset_id,
            rount_id: round_id,
            start_ts: block.timestamp,
            end_ts: round_start_ts + round_duration
        });
        pools[round_id].attend_assets.push(_asset_id);
        pools[round_id].asset2account[_asset_id] = msg.sender;
        pools[round_id].balances[msg.sender] = pools[round_id].balances[msg.sender].add(1);
        pools[round_id].attended[msg.sender] = true;
        balances[msg.sender] = balances[msg.sender].add(1);
        emit StakeOne(msg.sender, _asset_id, block.timestamp, round_start_ts + round_duration, round_id);
    }
    function exit(uint256[] memory ids, uint256[] memory rounds) public{
        for (uint256 i = 0; i < ids.length; ++i) {
            exit_one(rounds[i], ids[i]);
        }
    }
    function exit_one(uint256 _round_id, uint256 _asset_id) public{
        require(pools[_round_id].stakes[msg.sender][_asset_id].asset_id > 0, "asset has been exited");
        require(pools[_round_id].stakes[msg.sender][_asset_id].end_ts <= block.timestamp, "asset not end");
        if(!pools[_round_id].ended){
            _get_reward(_round_id, _asset_id);
        }
        require(pools[_round_id].ended, "not gen reward");
        nft_token.safeTransferFrom(dev_pool, msg.sender, _asset_id);
        uint256 _tlp = pools[_round_id].wait_claimed[_asset_id][address(tlp_token)];
        uint256 _frog = pools[_round_id].wait_claimed[_asset_id][address(frog_token)];
        if(_tlp > 0){
            IERC20(tlp_token).mint(msg.sender, _tlp);
            pools[_round_id].wait_claimed[_asset_id][address(tlp_token)] = 0;
            pools[_round_id].claimed[msg.sender][address(tlp_token)] = pools[_round_id].claimed[msg.sender][address(tlp_token)].add(_tlp);
        }
        if(_frog > 0){
            IERC20(frog_token).mint(msg.sender, _frog);
            if(_frog.div(10) > 0){
                IERC20(frog_token).mint(mint_frog_pool, _frog.div(10));
            }
            pools[_round_id].wait_claimed[_asset_id][address(frog_token)] = 0;
            pools[_round_id].claimed[msg.sender][address(frog_token)] = pools[_round_id].claimed[msg.sender][address(frog_token)].add(_frog);
        }
        if(balances[msg.sender] >= 1){
            balances[msg.sender] = balances[msg.sender].sub(1);
        }
        if(pools[_round_id].balances[msg.sender] >= 1){
            pools[_round_id].balances[msg.sender] = pools[_round_id].balances[msg.sender].sub(1);
        }
        emit ExitOne(msg.sender, _asset_id, pools[_round_id].stakes[msg.sender][_asset_id].start_ts, pools[_round_id].stakes[msg.sender][_asset_id].end_ts, _tlp, _frog);
        emit ClaimReward(_round_id, msg.sender, _asset_id, _tlp, _frog);
        delete(pools[_round_id].stakes[msg.sender][_asset_id]);
    }
    function _get_reward(uint256 _round_id, uint256 _asset_id) internal{
        uint256 attend_count = pools[_round_id].attend_assets.length;
        uint256 total_tlp = attend_count * 20000 * 10 ** 18;
        uint256 total_frog = attend_count * 2 * 10 ** 18;
        uint256 seed = uint256(keccak256(abi.encode(msg.sender, _round_id, _asset_id, block.timestamp, blockhash(block.number))));
        if(attend_count == 1){
            uint256 asset_id = pools[_round_id].attend_assets[0];
            address account = pools[_round_id].asset2account[asset_id];
            pools[_round_id].lucky_assets.push(asset_id);
            pools[_round_id].lucky_accounts.push(account);
            pools[_round_id].wait_claimed[_asset_id][address(tlp_token)] = pools[_round_id].wait_claimed[_asset_id][address(tlp_token)].add(total_tlp);
            pools[_round_id].wait_claimed[_asset_id][address(frog_token)] = pools[_round_id].wait_claimed[_asset_id][address(frog_token)].add(total_frog);
            pools[_round_id].tlps.push(total_tlp);
            pools[_round_id].frogs.push(total_frog);
        }else if(attend_count == 2){
            uint256 asset_id = pools[_round_id].attend_assets[seed % 2];
            address account = pools[_round_id].asset2account[asset_id];
            pools[_round_id].lucky_assets.push(asset_id);
            pools[_round_id].lucky_accounts.push(account);
            pools[_round_id].wait_claimed[_asset_id][address(tlp_token)] = pools[_round_id].wait_claimed[_asset_id][address(tlp_token)].add(total_tlp);
            pools[_round_id].wait_claimed[_asset_id][address(frog_token)] = pools[_round_id].wait_claimed[_asset_id][address(frog_token)].add(total_frog);
            pools[_round_id].tlps.push(total_tlp);
            pools[_round_id].frogs.push(total_frog);
        }else{
            uint256 first_index = seed % attend_count;
            uint256 second_index;
            uint256 third_index;
            seed = uint256(keccak256(abi.encode(msg.sender, first_index, pools[_round_id].attend_assets[first_index], _round_id + 1, _asset_id, block.timestamp, blockhash(block.number))));
            if(first_index == 0){
                second_index = first_index + 1 + seed % (attend_count - 1);
                if(second_index != attend_count -1){
                    seed = uint256(keccak256(abi.encode(msg.sender, first_index, second_index, pools[_round_id].attend_assets[first_index], pools[_round_id].attend_assets[second_index], _round_id + 2, _asset_id, block.timestamp, blockhash(block.number))));
                    third_index = second_index + 1 + seed % (attend_count - second_index - 1);
                }else{
                    seed = uint256(keccak256(abi.encode(msg.sender, first_index, second_index, pools[_round_id].attend_assets[first_index], pools[_round_id].attend_assets[second_index], _round_id + 2, _asset_id, block.timestamp, blockhash(block.number))));
                    third_index = first_index + 1 + seed % (attend_count - 2);
                }
            }else if(first_index == attend_count - 1){
                second_index = seed % (attend_count - 1);
                if(second_index != 0){
                    seed = uint256(keccak256(abi.encode(msg.sender, first_index, second_index, pools[_round_id].attend_assets[first_index], pools[_round_id].attend_assets[second_index], _round_id + 2, _asset_id, block.timestamp, blockhash(block.number))));
                    third_index = seed % (second_index);
                }else{
                    seed = uint256(keccak256(abi.encode(msg.sender, first_index, second_index, pools[_round_id].attend_assets[first_index], pools[_round_id].attend_assets[second_index], _round_id + 2, _asset_id, block.timestamp, blockhash(block.number))));
                    third_index = second_index + 1 + seed % (attend_count - 2);
                }
            }else{
                if(seed % 2 == 0){
                    second_index = seed % (first_index);
                    seed = uint256(keccak256(abi.encode(msg.sender, first_index, second_index, pools[_round_id].attend_assets[first_index], pools[_round_id].attend_assets[second_index], _round_id + 2, _asset_id, block.timestamp, blockhash(block.number))));
                    third_index = first_index + 1 + seed % (attend_count - first_index - 1);
                }else{
                    third_index = seed % (first_index);
                    seed = uint256(keccak256(abi.encode(msg.sender, first_index, third_index, pools[_round_id].attend_assets[first_index], pools[_round_id].attend_assets[third_index], _round_id + 2, _asset_id, block.timestamp, blockhash(block.number))));
                    second_index = first_index + 1 + seed % (attend_count - first_index - 1);
                }
            }
            uint256 _tlp_reward;
            uint256 _frog_reward;
            {
            uint256 first_asset_id = pools[_round_id].attend_assets[first_index];
            address first_account = pools[_round_id].asset2account[first_asset_id];
            _tlp_reward = total_tlp.mul(50).div(100);
            _frog_reward = total_frog.mul(50).div(100);
            pools[_round_id].lucky_assets.push(first_asset_id);
            pools[_round_id].lucky_accounts.push(first_account);
            pools[_round_id].wait_claimed[first_asset_id][address(tlp_token)] = pools[_round_id].wait_claimed[first_asset_id][address(tlp_token)] + _tlp_reward;
            pools[_round_id].wait_claimed[first_asset_id][address(frog_token)] = pools[_round_id].wait_claimed[first_asset_id][address(frog_token)] + _frog_reward;
            pools[_round_id].tlps.push(_tlp_reward);
            pools[_round_id].frogs.push(_frog_reward);
            }
            {
            uint256 second_asset_id = pools[_round_id].attend_assets[second_index];
            address second_account = pools[_round_id].asset2account[second_asset_id];
            _tlp_reward = total_tlp.mul(30).div(100);
            _frog_reward = total_frog.mul(30).div(100);
            pools[_round_id].lucky_assets.push(second_asset_id);
            pools[_round_id].lucky_accounts.push(second_account);
            pools[_round_id].wait_claimed[second_asset_id][address(tlp_token)] = pools[_round_id].wait_claimed[second_asset_id][address(tlp_token)] + _tlp_reward;
            pools[_round_id].wait_claimed[second_asset_id][address(frog_token)] = pools[_round_id].wait_claimed[second_asset_id][address(frog_token)] + _frog_reward;
            pools[_round_id].tlps.push(_tlp_reward);
            pools[_round_id].frogs.push(_frog_reward);
            }
            {
            uint256 third_asset_id = pools[_round_id].attend_assets[third_index];
            address third_account = pools[_round_id].asset2account[third_asset_id];
            _tlp_reward = total_tlp.mul(20).div(100);
            _frog_reward = total_frog.mul(20).div(100);
            pools[_round_id].lucky_assets.push(third_asset_id);
            pools[_round_id].lucky_accounts.push(third_account);
            pools[_round_id].wait_claimed[third_asset_id][address(tlp_token)] = pools[_round_id].wait_claimed[third_asset_id][address(tlp_token)] + _tlp_reward;
            pools[_round_id].wait_claimed[third_asset_id][address(frog_token)] = pools[_round_id].wait_claimed[third_asset_id][address(frog_token)] + _frog_reward;
            pools[_round_id].tlps.push(_tlp_reward);
            pools[_round_id].frogs.push(_frog_reward);
            }
        }
        pools[_round_id].ended = true;
    }

    function test_reward(uint256 attend_count) public onlyOwner returns (uint256, uint256, uint256){
        uint256 first_index;
        uint256 second_index;
        uint256 third_index;
        uint256 seed = uint256(keccak256(abi.encode(msg.sender, block.timestamp, blockhash(block.number))));
        if(attend_count == 1){
            first_index = 0;
        }else if(attend_count == 2){
            first_index = seed % 2;
        }else{
            first_index = seed % attend_count;
            seed = uint256(keccak256(abi.encode(msg.sender, 1, first_index, block.timestamp, blockhash(block.number))));
            if(first_index == 0){
                second_index = first_index + 1 + seed % (attend_count - 1);
                if(second_index != attend_count -1){
                    seed = uint256(keccak256(abi.encode(msg.sender, first_index, second_index, 2, block.timestamp, blockhash(block.number))));
                    third_index = second_index + 1 + seed % (attend_count - second_index - 1);
                }else{
                    seed = uint256(keccak256(abi.encode(msg.sender, first_index, second_index, 2, block.timestamp, blockhash(block.number))));
                    third_index = first_index + 1 + seed % (attend_count - 2);
                }
            }else if(first_index == attend_count - 1){
                second_index = seed % (attend_count - 1);
                if(second_index != 0){
                    seed = uint256(keccak256(abi.encode(msg.sender, first_index, second_index, 2, block.timestamp, blockhash(block.number))));
                    third_index = seed % (second_index);
                }else{
                    seed = uint256(keccak256(abi.encode(msg.sender, first_index, second_index, 2, block.timestamp, blockhash(block.number))));
                    third_index = second_index + 1 + seed % (attend_count - 2);
                }
            }else{
                if(seed % 2 == 0){
                    second_index = seed % (first_index);
                    seed = uint256(keccak256(abi.encode(msg.sender, first_index, second_index, 2, block.timestamp, blockhash(block.number))));
                    third_index = first_index + 1 + seed % (attend_count - first_index - 1);
                }else{
                    third_index = seed % (first_index);
                    seed = uint256(keccak256(abi.encode(msg.sender, first_index, third_index, 2, block.timestamp, blockhash(block.number))));
                    second_index = first_index + 1 + seed % (attend_count - first_index - 1);
                }
            }
        }
        emit TestReward(attend_count, first_index, second_index, third_index);
        return (first_index, second_index, third_index);
    }
    
    function exit_stake(uint256[] memory ids, uint256[] memory rounds) public {
        for (uint256 i = 0; i < ids.length; ++i) {
            exit_one(rounds[i], ids[i]);
            stake_one(ids[i]);
        }
    }
    function exit_stake_one(uint256 _asset_id, uint256 _round) public checkPaused{
        exit_one(_round, _asset_id);
        stake_one(_asset_id);
    }
    function pool_info(uint256 _round_id, address _account) external view returns 
        (
            bool created,
            bool ended,
            uint256 attend_asset_count,
            uint256 _balance,
            bool _attended,
            bool _1st,
            bool _2nd,
            bool _3rd
        ){
        created = pools[_round_id].created;
        ended = pools[_round_id].ended;
        attend_asset_count = pools[_round_id].attend_assets.length;
        _balance = pools[_round_id].balances[_account];
        _attended = pools[_round_id].attended[_account];
        if(pools[_round_id].lucky_accounts.length >= 1 && pools[_round_id].lucky_accounts[0] == _account){
            _1st = true;
        }
        if(pools[_round_id].lucky_accounts.length >= 2 && pools[_round_id].lucky_accounts[1] == _account){
            _2nd = true;
        }
        if(pools[_round_id].lucky_accounts.length >= 3 && pools[_round_id].lucky_accounts[2] == _account){
            _3rd = true;
        }
    }
    function pool_1st_info(uint256 _round_id) external view returns 
        (
            uint256 _1asset,
            address _1account,
            uint256 _1tlp,
            uint256 _1frog,
            bool _claimed
        ){
        if(pools[_round_id].lucky_assets.length >= 1){
            _1asset = pools[_round_id].lucky_assets[0];
            _1account = pools[_round_id].lucky_accounts[0];
            _1tlp = pools[_round_id].tlps[0];
            _1frog = pools[_round_id].frogs[0];
            if(pools[_round_id].wait_claimed[_1asset][address(tlp_token)] <= 0){
                _claimed = true;
            }
        }
    }
    function pool_2nd_info(uint256 _round_id) external view returns 
        (
            uint256 _2asset,
            address _2account,
            uint256 _2tlp,
            uint256 _2frog,
            bool _claimed
        ){
        if(pools[_round_id].lucky_assets.length >= 2){
            _2asset = pools[_round_id].lucky_assets[1];
            _2account = pools[_round_id].lucky_accounts[1];
            _2tlp = pools[_round_id].tlps[1];
            _2frog = pools[_round_id].frogs[1];
            if(pools[_round_id].wait_claimed[_2asset][address(tlp_token)] <= 0){
                _claimed = true;
            }
        }
    }
    function pool_3rd_info(uint256 _round_id) external view returns 
        (
            uint256 _3asset,
            address _3account,
            uint256 _3tlp,
            uint256 _3frog,
            bool _claimed
        ){
        if(pools[_round_id].lucky_assets.length >= 3){
            _3asset = pools[_round_id].lucky_assets[2];
            _3account = pools[_round_id].lucky_accounts[2];
            _3tlp = pools[_round_id].tlps[2];
            _3frog = pools[_round_id].frogs[2];
            if(pools[_round_id].wait_claimed[_3asset][address(tlp_token)] <= 0){
                _claimed = true;
            }
        }
    }
    function withdrawToken(address token) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
    function withdrawETH() external onlyOwner{
        _safeTransferETH(msg.sender, address(this).balance);
    }
    function _safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call.value(value)(new bytes(0));
        require(success, 'SupeNFTStakingPool Transfer: ETH_TRANSFER_FAILED');
    }
    function set_paused(bool _paused) external onlyFactoryOrOwner {
        paused = _paused;
    }
    modifier checkPaused() {
        require(!paused, "SupeNFTMintGold: paused");
        _;
    }
    function set_claim_enable(bool _claim_enable) external onlyFactoryOrOwner {
        claim_enable = _claim_enable;
    }
    modifier checkClaimEnable() {
        require(claim_enable, "SupeNFTMintGold: can not claim now");
        _;
    }
}